// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@rari-capital/solmate/src/utils/SafeTransferLib.sol';
import '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';
import '@rari-capital/solmate/src/tokens/ERC20.sol';

import '../interfaces/IUSP.sol';
import '../interfaces/IPriceOracleGetter.sol';
import '../interfaces/IMasterPlatypusV4.sol';
import '../interfaces/IPool.sol';

interface LiquidationCallback {
    function callback(
        uint256 uspAmount,
        uint256 collateralAmount,
        address initiator,
        bytes calldata data
    ) external;
}

/**
 * @title PlatypusTreasure
 * @notice Platypuses can make use of their collateral to mint USP
 * @dev If the user's health factor is below 1, anyone can liquidate his/her position.
 * Protocol will charge debt interest from borrowers and protocol revenue from liquidation.
 */
contract PlatypusTreasure is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /**
     * Structs
     */

    /// @notice A struct for treasure settings
    struct MarketSetting {
        IAsset uspLp; // USP lp address of main pool
        uint32 mininumBorrowAmount; // minimum USP borrow amount in whole token. 9 digits.
        uint8 k; // param for dynamic interest rate: c^k / 100
        bool borrowPaused; // pause USP borrowing for all collaterals
        bool liquidationPaused;
        uint16 kickIncentive; // keeper incentive. USP amount in whole token.
    }

    /// @notice A struct for collateral settings
    struct CollateralSetting {
        /* storage slot (read-only) */
        // borrow, repay
        uint40 borrowCap; // USP borrow cap in whole token. 12 digits.
        uint16 collateralFactor; // collateral factor; base 10000
        uint16 borrowFee; // fees that will be charged upon minting USP (0.3% in USP); base 10000
        bool isStable; // we perform additional check to stables: borrowing USP is now allowed when it is about to depeg
        // liquidation
        uint16 liquidationThreshold; // collateral liquidation threshold (greater than `collateralFactor`); base 10000
        uint16 liquidationPenalty; // liquidation penalty for liquidators. base 10000
        uint16 auctionStep; // price of the auction decrease per `auctionStep` seconds to `auctionFactor`
        uint16 auctionFactor; // base 10000
        bool liquidationPaused;
        // others
        uint8 decimals; // cache of decimal of the collateral. also used to check if collateral exists
        bool isLp;
        // 88 bits unused
        /* storage slot */
        uint128 borrowedShare; // borrowed USP share. 20.18 fixed point integer
        /* LP infos */
        IMasterPlatypusV4 masterPlatypus; // MasterPlatypus Address
        uint8 pid; // cache of pid in the master platypus
        // uint256 uspToRaise; // USP amount that should be filled by liquidation
    }

    /// @notice A struct for users collateral position
    struct Position {
        /* storage slot */
        uint128 debtShare;
        // non-LP infos
        // don't read this storage directly, instead, read `_getCollateralAmount()`
        uint128 collateralAmount;
    }

    /// @notice A struct to preview a user's collateral position; external view-only
    struct PositionView {
        uint256 collateralAmount;
        uint256 collateralInUSD;
        uint256 borrowLimit;
        uint256 debtShare;
        uint256 debtAmount;
        bool liquidable;
    }

    struct Auction {
        // storage slot
        uint128 uspAmount; // USP to raise
        uint128 collateralAmount; // collateral that is being liquidated
        // storage slot
        ERC20 token; // address collateral
        uint48 index; // index in activeAuctions
        uint40 startTime; // starting time of the auction
        // storage slot
        address user; // liquidatee
        uint96 startPrice; // starting price of the auction. 10.18 fixed point
    }

    /**
     * Events
     */

    /// @notice Add collateral token
    event AddCollateralToken(ERC20 token);
    /// @notice Update collateral token setting
    event SetCollateralToken(ERC20 token, CollateralSetting setting);

    /// @notice An event thats emitted when fee is collected at minting, interest accrual and liquidation
    event Accrue(uint256 interest);
    /// @notice An event thats emitted when user deposits collateral
    event AddCollateral(address indexed user, ERC20 indexed token, uint256 amount);
    /// @notice An event thats emitted when user withdraws collateral
    event RemoveCollateral(address indexed user, ERC20 indexed token, uint256 amount);
    /// @notice An event thats emitted when user borrows USP
    event Borrow(address indexed user, uint256 uspAmount);
    /// @notice An event thats emitted when user repays USP
    event Repay(address indexed user, uint256 uspAmount);

    event StartAuction(uint256 id, address user, ERC20 indexed token, uint256 collateralAmount, uint256 uspAmount);
    event BuyCollateral(uint256 id, address user, ERC20 indexed token, uint256 collateralAmount, uint256 uspAmount);
    event BadDebt(uint256 id, address user, ERC20 indexed token, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error PlatypusTreasure_ZeroAddress();
    error PlatypusTreasure_InvalidMasterPlatypus();
    error PlatypusTreasure_InvalidRatio();
    error PlatypusTreasure_InvalidPid();
    error PlatypusTreasure_InvalidToken();
    error PlatypusTreasure_InvalidAmount();
    error PlatypusTreasure_MinimumBorrowAmountNotSatisfied();
    error PlatypusTreasure_ExceedCollateralFactor();
    error PlatypusTreasure_ExceedCap();
    error PlatypusTreasure_ExceedHalfRepayLimit();
    error PlatypusTreasure_NotLiquidable();
    error PlatypusTreasure_BorrowPaused();
    error PlatypusTreasure_BorrowDisallowed();
    error PlatypusTreasure_InvalidMarketSetting();

    error Liquidation_Paused();
    error Liquidation_Invalid_Auction_Id();
    error Liquidation_Exceed_Max_Price(uint256 currentPrice);
    error Liquidation_Liquidator_Should_Take_All_Collateral();

    error Uint96_Overflow();
    error Uint112_Overflow();
    error Uint128_Overflow();

    /**
     * Storage
     */
    /// @notice Platypus Treasure settings
    MarketSetting public marketSetting;
    /// @notice Collateral price oracle address (returns price in usd: 8 decimals)
    IPriceOracleGetter oracle;

    /// @notice collateral tokens in array
    ERC20[] public collateralTokens;
    /// @notice collateral settings
    mapping(ERC20 => CollateralSetting) public collateralSettings; // token => collateral setting
    /// @notice users collateral position
    mapping(ERC20 => mapping(address => Position)) internal userPositions; // collateral => user => position

    /* storage slot for _accrue() */
    /// @notice total borrowed amount accrued so far - 15.18 fixed point integer
    uint112 public totalDebtAmount;
    /// @notice total protocol fees accrued so far - 15.18 fixed point integer
    uint112 public totalFeeCollected;
    /// @notice last time of debt accrued
    uint32 public lastAccrued;

    /// @notice address that should receive liquidation fee, interest and USP minting fee
    address public feeTo;
    /// @notice total borrowed portion
    uint128 public totalDebtShare;
    /// @notice Amount of USP needed to cover debt + fees of active auctions
    uint128 public unbackedUspAmount;

    /// @notice USP token address
    IUSP public usp;
    uint48 public totalAuctions;

    /// @notice a list of active auctions
    /// @dev each slot is able to store 5 activeAuctions
    uint48[] public activeAuctions;
    mapping(uint256 => Auction) public auctions; // id => auction data

    /**
     * Constructor, Modifers, Getters and Setters
     */

    /**
     * @notice Initializer.
     * @param _usp USP token address
     * @param _oracle collateral token price oracle
     * @param _marketSetting treasure settings
     */
    function initialize(
        IUSP _usp,
        IPriceOracleGetter _oracle,
        MarketSetting calldata _marketSetting,
        address _feeTo
    ) external initializer {
        if (address(_usp) == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (address(_oracle) == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (_feeTo == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (_marketSetting.k == 0 || _marketSetting.k > 10 || address(_marketSetting.uspLp) == address(0))
            revert PlatypusTreasure_InvalidMarketSetting();

        __Ownable_init();
        __ReentrancyGuard_init_unchained();

        usp = _usp;
        oracle = _oracle;
        marketSetting = _marketSetting;
        feeTo = _feeTo;
    }

    /**
     * @notice returns the number of all collateral tokens
     * @return number of collateral tokens
     */
    function getCollateralTokens() external view returns (ERC20[] memory) {
        return collateralTokens;
    }

    /**
     * @notice returns the number of all collateral tokens
     * @return number of collateral tokens
     */
    function collateralTokensLength() external view returns (uint256) {
        return collateralTokens.length;
    }

    /**
     * @dev pause borrow
     */
    function pauseBorrow() external onlyOwner {
        marketSetting.borrowPaused = true;
    }

    /**
     * @dev unpause borrow
     */
    function unpauseBorrow() external onlyOwner {
        marketSetting.borrowPaused = false;
    }

    /**
     * @notice Update interest param k
     * @dev only owner can call this function
     */
    function setInterestParam(uint8 _k) external onlyOwner {
        if (_k == 0 || _k > 10) revert PlatypusTreasure_InvalidMarketSetting();
        marketSetting.k = _k;
    }

    function setkickIncentive(uint16 _kickIncentive) external onlyOwner {
        marketSetting.kickIncentive = _kickIncentive;
    }

    /**
     * @notice Update mininumBorrowAmount
     * @dev only owner can call this function
     */
    function setMinimumBorrowAmount(uint32 _mininumBorrowAmount) external onlyOwner {
        marketSetting.mininumBorrowAmount = _mininumBorrowAmount;
    }

    /**
     * @notice Stops `startAuction` for all collaterals
     */
    function pauseAllLiquidations() external onlyOwner {
        marketSetting.liquidationPaused = true;
    }

    /**
     * @notice Resume `startAuction` for all collaterals
     */
    function resumeAllLiquidations() external onlyOwner {
        marketSetting.liquidationPaused = false;
    }

    /**
     * @notice Stops `startAuction`
     */
    function pauseLiquidations(ERC20 _token) external onlyOwner {
        _checkCollateralExist(_token);
        collateralSettings[_token].liquidationPaused = true;
    }

    /**
     * @notice Resume `startAuction`
     */
    function resumeLiquidations(ERC20 _token) external onlyOwner {
        _checkCollateralExist(_token);
        collateralSettings[_token].liquidationPaused = false;
    }

    /**
     * @notice add or update LP collateral setting
     * @dev only owner can call this function
     * @param _token collateral token address
     * @param _borrowCap borrow cap in whole token
     * @param _collateralFactor borrow limit
     * @param _borrowFee borrow fee of USP
     * @param _liquidationThreshold liquidation threshold rate
     * @param _liquidationPenalty liquidation penalty
     * @param _masterPlatypus address of master platypus
     */
    function setLpCollateralToken(
        ERC20 _token,
        uint40 _borrowCap,
        uint16 _collateralFactor,
        uint16 _borrowFee,
        bool _isStable,
        uint16 _liquidationThreshold,
        uint16 _liquidationPenalty,
        uint16 _auctionStep,
        uint16 _auctionFactor,
        IMasterPlatypusV4 _masterPlatypus
    ) external onlyOwner {
        if (address(_token) == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (
            _collateralFactor >= 10000 ||
            _liquidationThreshold >= 10000 ||
            _liquidationPenalty >= 10000 ||
            _borrowFee >= 10000 ||
            _liquidationThreshold < _collateralFactor
        ) revert PlatypusTreasure_InvalidRatio();

        if (address(_masterPlatypus) == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (address(_masterPlatypus.platypusTreasure()) != address(this))
            revert PlatypusTreasure_InvalidMasterPlatypus();

        uint256 pid = _masterPlatypus.getPoolId(address(_token));
        if (pid > type(uint8).max) revert PlatypusTreasure_InvalidPid();

        // check if collateral exists
        bool isNewSetting = collateralSettings[_token].decimals == 0;

        // add a new collateral
        collateralSettings[_token] = CollateralSetting({
            borrowCap: _borrowCap,
            collateralFactor: _collateralFactor,
            borrowFee: _borrowFee,
            isStable: _isStable,
            liquidationThreshold: _liquidationThreshold,
            liquidationPenalty: _liquidationPenalty,
            auctionStep: _auctionStep,
            auctionFactor: _auctionFactor,
            liquidationPaused: collateralSettings[_token].liquidationPaused,
            decimals: ERC20(_token).decimals(),
            isLp: true,
            borrowedShare: collateralSettings[_token].borrowedShare,
            masterPlatypus: _masterPlatypus,
            pid: uint8(pid)
        });

        if (isNewSetting) {
            collateralTokens.push(_token);
            emit AddCollateralToken(_token);
        }
        emit SetCollateralToken(_token, collateralSettings[_token]);
    }

    /**
     * @notice add or update LP collateral setting
     * @dev only owner can call this function
     * @param _token collateral token address
     * @param _borrowCap borrow cap in whole token
     * @param _collateralFactor borrow limit
     * @param _borrowFee borrow fee of USP
     * @param _liquidationThreshold liquidation threshold rate
     * @param _liquidationPenalty liquidation penalty
     */
    function setRawCollateralToken(
        ERC20 _token,
        uint40 _borrowCap,
        uint16 _collateralFactor,
        uint16 _borrowFee,
        bool _isStable,
        uint16 _liquidationThreshold,
        uint16 _liquidationPenalty,
        uint16 _auctionStep,
        uint16 _auctionFactor
    ) external onlyOwner {
        if (address(_token) == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (
            _collateralFactor >= 10000 ||
            _liquidationThreshold >= 10000 ||
            _liquidationPenalty >= 10000 ||
            _borrowFee >= 10000 ||
            _borrowFee == 0 ||
            _liquidationThreshold < _collateralFactor
        ) revert PlatypusTreasure_InvalidRatio();

        // check if collateral exists
        bool isNewSetting = collateralSettings[_token].decimals == 0;

        // add a new collateral
        collateralSettings[_token] = CollateralSetting({
            borrowCap: _borrowCap,
            collateralFactor: _collateralFactor,
            borrowFee: _borrowFee,
            isStable: _isStable,
            liquidationThreshold: _liquidationThreshold,
            liquidationPenalty: _liquidationPenalty,
            auctionStep: _auctionStep,
            auctionFactor: _auctionFactor,
            liquidationPaused: collateralSettings[_token].liquidationPaused,
            decimals: ERC20(_token).decimals(),
            isLp: false,
            borrowedShare: collateralSettings[_token].borrowedShare,
            masterPlatypus: IMasterPlatypusV4(address(0)),
            pid: 0
        });

        if (isNewSetting) {
            collateralTokens.push(_token);
            emit AddCollateralToken(_token);
        }
        emit SetCollateralToken(_token, collateralSettings[_token]);
    }

    /**
     * Public/External Functions
     */

    /**
     * @notice collect protocol fees accrued so far
     * @dev safe from reentrancy
     */
    function collectFee() external returns (uint256 feeCollected) {
        _accrue();

        // collect protocol fees in USP
        feeCollected = totalFeeCollected;
        totalFeeCollected = 0;
        usp.mint(feeTo, feeCollected);
    }

    /**
     * @notice Add non-LP tokens as collateral, e.g PTP or AVAX
     * @dev Tokens will be stored in this contract, won't go to master platypus
     * Follows Checks-Effects-Interactions
     * @param _token address of collateral token
     * @param _amount collateral amounts to deposit
     */
    function addCollateral(ERC20 _token, uint256 _amount) public {
        CollateralSetting storage setting = collateralSettings[_token];
        // check if collateral exists and is valid
        _checkCollateralExist(_token);
        if (setting.isLp) revert PlatypusTreasure_InvalidToken();
        if (_amount == 0) revert PlatypusTreasure_InvalidAmount();

        // update collateral position
        Position storage position = userPositions[_token][msg.sender];
        position.collateralAmount += toUint128(_amount);

        emit AddCollateral(msg.sender, _token, _amount);
        ERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Remove non-LP collaterals, e.g PTP or AVAX
     * @dev Transfer collateral tokens to the user
     * Follows Checks-Effects-Interactions
     * @param _token address of collateral token
     * @param _amount collateral amounts to withdraw
     */
    function removeCollateral(ERC20 _token, uint256 _amount) public {
        CollateralSetting storage setting = collateralSettings[_token];
        // check if collateral exists and is valid
        _checkCollateralExist(_token);
        if (setting.isLp) revert PlatypusTreasure_InvalidToken();
        if (_amount == 0) revert PlatypusTreasure_InvalidAmount();

        // update collateral position
        Position storage position = userPositions[_token][msg.sender];
        if (_amount > position.collateralAmount) revert PlatypusTreasure_InvalidAmount();
        position.collateralAmount -= toUint128(_amount);

        (bool solvent, ) = _isSolvent(msg.sender, _token, true);
        if (!solvent) revert PlatypusTreasure_ExceedCollateralFactor();

        emit RemoveCollateral(msg.sender, _token, _amount);
        ERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice borrow USP
     * @dev user can call this function after depositing his/her collateral
     * Follows Checks-Effects-Interactions
     * @param _token collateral token address
     * @param _borrowAmount USP amount to borrow
     */
    function borrow(ERC20 _token, uint256 _borrowAmount) public {
        if (marketSetting.borrowPaused == true) revert PlatypusTreasure_BorrowPaused();
        if (_borrowAmount == 0) revert PlatypusTreasure_InvalidAmount();
        CollateralSetting storage setting = collateralSettings[_token];
        // check if collateral exists
        _checkCollateralExist(_token);

        _accrue();

        // calculate borrow limit in USD
        uint256 borrowLimit = _borrowLimitUSP(msg.sender, _token);
        // calculate debt amount in USP
        uint256 debtAmount = _debtAmountUSP(msg.sender, _token);

        // check if the position exceeds borrow limit
        if (debtAmount + _borrowAmount > borrowLimit) revert PlatypusTreasure_ExceedCollateralFactor();
        // check if it reaches minimum borrow amount
        if (debtAmount + _borrowAmount < uint256(marketSetting.mininumBorrowAmount) * 1e18) {
            revert PlatypusTreasure_MinimumBorrowAmountNotSatisfied();
        }
        // if the stablecoin is about to unpeg (p < 0.98), minting is disallowed
        if (setting.isStable) {
            uint256 oneUnit = 10**collateralSettings[_token].decimals;
            uint256 price = _tokenPriceUSD(_token, oneUnit);
            if (price < 98e16) {
                revert PlatypusTreasure_BorrowDisallowed();
            }
        }

        // calculate USP borrow fee
        uint256 borrowFee = (_borrowAmount * setting.borrowFee) / 10000;
        totalFeeCollected += toUint112(borrowFee);

        // update collateral position
        uint256 borrowShare = totalDebtShare == 0 ? _borrowAmount : (_borrowAmount * totalDebtShare) / totalDebtAmount;
        userPositions[_token][msg.sender].debtShare += toUint128(borrowShare);
        setting.borrowedShare += toUint128(borrowShare);
        totalDebtShare += toUint128(borrowShare);
        totalDebtAmount += toUint112(_borrowAmount);

        // check if the position exceeds borrow cap of this collateral
        uint256 totalBorrowedUSP = (uint256(setting.borrowedShare) * uint256(totalDebtAmount)) /
            uint256(totalDebtShare);
        if (totalBorrowedUSP > uint256(setting.borrowCap) * 1e18) revert PlatypusTreasure_ExceedCap();

        emit Borrow(msg.sender, _borrowAmount);
        emit Accrue(borrowFee);

        // mint USP to user
        usp.mint(msg.sender, _borrowAmount - borrowFee);
    }

    /**
     * @notice repay debt with USP. The caller is suggested to increase _repayAmount by 0.01 if
     * he wants to repay all of this USP in case interest accrus
     * @dev user can call this function after approving his/her USP amount to repay.
     * Follows Checks-Effects-Interactions
     * @param _token collateral token address
     * @param _repayAmount USP amount to repay
     * @return repayShare
     */
    function repay(ERC20 _token, uint256 _repayAmount) public nonReentrant returns (uint256) {
        CollateralSetting storage setting = collateralSettings[_token];
        // check if collateral exists
        _checkCollateralExist(_token);
        if (_repayAmount == 0) revert PlatypusTreasure_InvalidAmount();

        _accrue();

        Position storage position = userPositions[_token][msg.sender];

        // calculate debt amount in USD
        uint256 debtAmount = _debtAmountUSP(msg.sender, _token);

        uint256 repayShare;
        if (_repayAmount >= debtAmount) {
            // only pays for the debt and returns remainings
            _repayAmount = debtAmount;
            repayShare = position.debtShare;
        } else {
            repayShare = (_repayAmount * totalDebtShare) / totalDebtAmount;
        }

        // check mininumBorrowAmount
        if (
            debtAmount - _repayAmount > 0 &&
            debtAmount - _repayAmount < uint256(marketSetting.mininumBorrowAmount) * 1e18
        ) {
            revert PlatypusTreasure_MinimumBorrowAmountNotSatisfied();
        }

        // update user's collateral position
        position.debtShare -= toUint128(repayShare);

        // update total debt
        totalDebtShare -= toUint128(repayShare);
        totalDebtAmount -= toUint112(_repayAmount);
        setting.borrowedShare -= toUint128(repayShare);

        emit Repay(msg.sender, _repayAmount);

        // burn repaid USP
        usp.burnFrom(msg.sender, _repayAmount);

        return repayShare;
    }

    /**
     * Liquidation Module
     */

    /// @notice Return the number of active auctions
    function activeAuctionLength() external view returns (uint256) {
        return activeAuctions.length;
    }

    /// @notice Return the entire array of active auctions
    function getActiveAuctions() external view returns (uint48[] memory) {
        return activeAuctions;
    }

    /// @notice Burn USP to fill unbacked USP
    /// @dev Can be call by any party
    function fillUnbackedUsp(uint128 _amount) external {
        usp.burnFrom(msg.sender, _amount);
        unbackedUspAmount -= _amount;
    }

    /**
     * @notice Liquidate a position and kickstart a Dutch auction to sell collaterals for USP.
     * The entire position will be liquidated but it can be partially filled as stated in `buyCollateral()`.
     * Liquidation penalty is included in the debt amount. The starting price of the auction is read from
     * oracle and is increased percentage-wise by `buf` (withdrawal fee for LP is
     * ignored in case of flash-loan). The price decreases as a function of time defined by `calculatePrice()`.
     *
     * @dev It checks
     * - liquidation isn't paused
     * - the position is default
     * It performs several actions:
     * - (pushes the bad debt into the debt queue)
     * - initiates the auction (debt amountinclude penalty, the price)
     * - remove collateral from the position (and masterPlatypus is needed)
     * - adds the bad debt plus the liquidation penalty to accumulator
     * - sends an incentive denominated in USP to the keeper (`kickIncentive` + 0.1% of USP to raise)
     */
    function startAuction(
        address _user,
        ERC20 _token,
        address _incentiveReceiver
    ) public nonReentrant returns (uint256 auctionId) {
        /********** Checks **********/
        CollateralSetting storage collateral = collateralSettings[_token];
        if (marketSetting.liquidationPaused || collateral.liquidationPaused) revert Liquidation_Paused();

        _checkCollateralExist(_token);

        _accrue();

        uint256 debtAmount = _debtAmountUSP(_user, _token);
        bool liquidable = debtAmount > 0 && debtAmount > _liquidateLimitUSP(_user, _token);
        // TODO: Is there a need to set a global / per-collateral liquidation limit in case market depth is not enough?
        if (!liquidable) revert PlatypusTreasure_NotLiquidable();

        /********** Grab collateral from the treasure **********/

        Position storage position = userPositions[_token][_user];
        uint256 collateralAmount = _getCollateralAmount(_token, _user);
        _grabCollateral(_user, _token, collateralAmount, position.debtShare);

        /********** Initiate Auction **********/

        uint256 uspToRaise = (debtAmount * (10000 + collateral.liquidationPenalty)) / 10000;

        // incentives for kick-starting the auction = `kickIncentive` + 0.1% of USP to raise
        // Important note: the incentive + liquidation reward should remain less than the minimum
        // liquidation penalty by some margin of safety so that the system is unlikely to accrue a deficit
        uint256 incentive = marketSetting.kickIncentive * 1e18 + uspToRaise / 1000;
        unbackedUspAmount += toUint128(uspToRaise + incentive);
        // collateral.uspToRaise += uspToRaise;

        // add liquidation penalty to protocol income
        totalFeeCollected += toUint112(uspToRaise - debtAmount);

        auctionId = _initiateAuction(_user, _token, toUint128(collateralAmount), toUint128(uspToRaise));

        // mint incentive to keeper
        usp.mint(_incentiveReceiver, incentive);

        emit StartAuction(auctionId, _user, _token, collateralAmount, uspToRaise);
        emit Accrue(uspToRaise - debtAmount);
    }

    /**
     * @notice remove collateral from the position to prepare for liquidation
     */
    function _grabCollateral(
        address _user,
        ERC20 _token,
        uint256 collateralAmount,
        uint256 debtShare
    ) internal {
        CollateralSetting storage collateral = collateralSettings[_token];
        Position storage position = userPositions[_token][_user];

        if (collateral.isLp) {
            // withdraw from masterPlatypus if it is an LP token
            collateral.masterPlatypus.liquidate(collateral.pid, _user, collateralAmount);
        } else {
            position.collateralAmount -= toUint128(collateralAmount);
        }

        position.debtShare -= toUint128(debtShare);

        uint256 debtAmount = (debtShare * totalDebtAmount) / totalDebtShare;

        totalDebtShare -= toUint128(debtShare);
        totalDebtAmount -= toUint112(debtAmount);
        collateral.borrowedShare -= toUint128(debtShare);
    }

    /**
     * @dev It performs the following action
     * - increments a counter and assigns a unique numerical id to the new auction
     * - inserts the id into a list tracking active auctions
     * - creates a structure to record the parameters of the auction
     */
    function _initiateAuction(
        address _user,
        ERC20 _token,
        uint128 _collateralAmount,
        uint128 _uspAmount
    ) internal returns (uint48 id) {
        id = ++totalAuctions;
        activeAuctions.push(id);

        uint256 oneUnit = 10**collateralSettings[_token].decimals;

        // For starting price
        // collateral factor * (1 + penalty) * (1 + buffer) should be < 100% to left some profit margin for liquidator
        auctions[id] = Auction({
            collateralAmount: _collateralAmount,
            startTime: uint40(block.timestamp),
            startPrice: toUint96(_tokenPriceUSD(_token, oneUnit)),
            index: uint48(activeAuctions.length - 1),
            token: _token,
            user: _user,
            uspAmount: _uspAmount
        });
    }

    /**
     * @notice Buy collateral at the current price as given by `calculatePrice()`. Flash lending of collateral
     * is supported but `msg.sender` should have prepared USP and approved this contract `uspAmount` of USP
     * @dev Following scenarios can happen when bidding on auctions
     * - Settling all debt while buying full collateral up for sale
     * - Settling all debt while buying only a part of the collateral up for sale
     * - Settling the debt only partially while buying the full collateral up for sale (bad debt)
     * - Settling the debt only partially for a part of the collateral up for sale (partial liquidation)
     * To avoid leaving a dust amount, remaining USP debt should be greater than `mininumBorrowAmount`
     */
    function buyCollateral(
        uint256 id,
        uint256 maxCollateralAmount,
        uint256 maxPrice,
        address who,
        bytes memory data
    ) public nonReentrant returns (uint256 bidCollateralAmount, uint256 uspAmount) {
        // TODO: check if the auction need to be reset, either due to having experienced too
        // large a percentage decrease in price, or having existed for too long of a time duration

        /********** Checks **********/

        Auction memory auction = auctions[id];
        if (auction.collateralAmount == 0) revert Liquidation_Invalid_Auction_Id();

        uint256 price = calculatePrice(auction.token, auction.startPrice, block.timestamp - auction.startTime);
        if (maxPrice < price) revert Liquidation_Exceed_Max_Price(price);

        /********** Calculate repay amount **********/

        uint256 collateralToSell = auction.collateralAmount;
        uint256 uspToRaise = auction.uspAmount;
        uint256 oneUnit = 10**collateralSettings[auction.token].decimals;

        // purchase as much collateral as possible
        bidCollateralAmount = collateralToSell < maxCollateralAmount ? collateralToSell : maxCollateralAmount;
        uspAmount = (price * bidCollateralAmount) / oneUnit;

        if (uspAmount > uspToRaise) {
            // Don't collect more USP than the debt
            uspAmount = uspToRaise;
            bidCollateralAmount = (uspAmount * oneUnit) / price;
        } else if (uspAmount < uspToRaise && bidCollateralAmount < collateralToSell) {
            // Leave at least `minimumRemainingUsp` to avoid dust amount in the debt
            // minimumRemainingUsp = debt floot * (1 + liquidation penalty)
            // `x * 1e14` =  `x / 10000 * 1e14`
            uint256 minimumRemainingUsp = (marketSetting.mininumBorrowAmount *
                (uint256(10000) + collateralSettings[auction.token].liquidationPenalty)) * 1e14;
            if (uspToRaise - uspAmount < minimumRemainingUsp) {
                if (uspToRaise <= minimumRemainingUsp) revert Liquidation_Liquidator_Should_Take_All_Collateral();

                uspAmount = uspToRaise - minimumRemainingUsp;
                bidCollateralAmount = (uspAmount * oneUnit) / price;
            }
        }

        /********** Execute repay with flash lending of collateral **********/

        // send collateral to `who`
        ERC20(auction.token).safeTransfer(who, bidCollateralAmount);

        // Do external call if data is defined
        if (data.length > 0) {
            // The callee can swap collateral to USP in the callback
            // Caution: Ensure this contract isn't authorized over the callee
            LiquidationCallback(who).callback(uspAmount, bidCollateralAmount, msg.sender, data);
        }

        // get collaterals, msg.sender should approve USP spending
        usp.burnFrom(msg.sender, uspAmount);

        /********** Update states **********/

        // remaining USP to raise and remaining collateral to sell
        collateralToSell -= bidCollateralAmount;
        uspToRaise -= uspAmount;

        // remove USP out of liquidation
        // collateralSettings[auction.token].uspToRaise -= uspAmount;
        unbackedUspAmount -= toUint128(uspAmount);

        if (collateralToSell == 0) {
            if (uspToRaise > 0) {
                // Bad debt: remove remaining `uspToRaise` from collateral setting
                // Note: If there's USP left to raise, we could spread it over all borrowers
                // or use protocol fee to fill it
                // collateralSettings[auction.token].uspToRaise -= uspToRaise;
                emit BadDebt(id, auction.user, auction.token, uspToRaise);
            }
            _removeAuction(id);
        } else if (uspToRaise == 0) {
            // All USP is repaid, return remaining collateral to the user
            ERC20(auction.token).safeTransfer(auction.user, collateralToSell);
            _removeAuction(id);
        } else {
            // update storage
            auctions[id].uspAmount = uint128(uspToRaise);
            auctions[id].collateralAmount = uint128(collateralToSell);
        }

        emit BuyCollateral(id, auction.user, auction.token, bidCollateralAmount, uspAmount);
    }

    /**
     * @notice Calculate the collateral price of a liquidation given startPrice and timeElapsed.
     * Stairstep Exponential Decrease:
     * - multiply the price by `auctionFactor` for every `auctionStep` seconds pass
     */
    function calculatePrice(
        ERC20 _token,
        uint256 _startPrice,
        uint256 _timeElapsed
    ) public view returns (uint256) {
        CollateralSetting storage collateral = collateralSettings[_token];

        uint256 discountFactor = FixedPointMathLib.rpow(
            (uint256(collateral.auctionFactor) * 1e18) / 10000,
            _timeElapsed / collateral.auctionStep,
            1e18
        );

        return (discountFactor * _startPrice) / 1e18;
    }

    function _removeAuction(uint256 id) internal {
        // remove the auction from `activeAuctions` and replace it with the last auction
        uint48 lastId = activeAuctions[activeAuctions.length - 1];
        if (id != lastId) {
            uint48 indexToRemove = auctions[id].index;
            activeAuctions[indexToRemove] = lastId;
            auctions[lastId].index = indexToRemove;
        }
        activeAuctions.pop();
        delete auctions[id];
    }

    /**
     * Helper Functions
     */

    uint8 constant ACTION_ADD_COLLATERAL = 1;
    uint8 constant ACTION_REMOVE_COLLATERAL = 2;
    uint8 constant ACTION_BORROW = 3;
    uint8 constant ACTION_REPAY = 4;
    uint8 constant ACTION_START_AUCTION = 5;
    uint8 constant ACTION_BUY_COLLATERAL = 6;

    /// @notice Executes a set of actions
    /// @dev This function should not accept arbitrary call as the contract is able to liquidate LPs in MasterPlatypus
    function cook(uint8[] calldata actions, bytes[] calldata datas) external {
        for (uint256 i; i < actions.length; ++i) {
            uint8 action = actions[i];
            if (action == ACTION_ADD_COLLATERAL) {
                (ERC20 _token, uint256 _amount) = abi.decode(datas[i], (ERC20, uint256));
                addCollateral(_token, _amount);
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (ERC20 _token, uint256 _amount) = abi.decode(datas[i], (ERC20, uint256));
                removeCollateral(_token, _amount);
            } else if (action == ACTION_BORROW) {
                (ERC20 _token, uint256 _borrowAmount) = abi.decode(datas[i], (ERC20, uint256));
                borrow(_token, _borrowAmount);
            } else if (action == ACTION_REPAY) {
                (ERC20 _token, uint256 _repayAmount) = abi.decode(datas[i], (ERC20, uint256));
                repay(_token, _repayAmount);
            } else if (action == ACTION_START_AUCTION) {
                (address _user, ERC20 _token, address _incentiveReceiver) = abi.decode(
                    datas[i],
                    (address, ERC20, address)
                );
                startAuction(_user, _token, _incentiveReceiver);
            } else if (action == ACTION_BUY_COLLATERAL) {
                (uint256 id, uint256 maxCollateralAmount, uint256 maxPrice, address who, bytes memory data) = abi
                    .decode(datas[i], (uint256, uint256, uint256, address, bytes));
                buyCollateral(id, maxCollateralAmount, maxPrice, who, data);
            }
        }
    }

    /**
     * @notice returns a user's collateral position
     * @return position this includes a user's collateral, debt, liquidation data.
     */
    function positionView(address _user, ERC20 _token) external view returns (PositionView memory) {
        Position memory position = userPositions[_token][_user];

        (bool solvent, ) = _isSolvent(_user, _token, false);
        uint256 collateralAmount = _getCollateralAmount(_token, _user);

        return
            PositionView({
                collateralAmount: collateralAmount,
                collateralInUSD: _tokenPriceUSD(_token, collateralAmount),
                borrowLimit: _borrowLimitUSP(_user, _token),
                debtShare: position.debtShare,
                debtAmount: _debtAmountUSP(_user, _token),
                liquidable: !solvent
            });
    }

    /**
     * @notice return available amount to borrow for this collateral
     * @param _token collateral token address
     * @return uint256 available amount to borrow
     */
    function availableUSP(ERC20 _token) external view returns (uint256) {
        CollateralSetting storage setting = collateralSettings[_token];
        uint256 outstandingLoan = (uint256(setting.borrowedShare) * uint256(totalDebtAmount)) / uint256(totalDebtShare);
        if (uint256(setting.borrowCap) * 1e18 > outstandingLoan) {
            return uint256(setting.borrowCap) * 1e18 - outstandingLoan;
        }
        return 0;
    }

    /**
     * @notice Return the unit price of LP token
     * It should equal to the underlying token price adjusted by the exchange rate
     */
    function getLPUnitPrice(IAsset _lp) external view returns (uint256) {
        return _getLPUnitPrice(_lp);
    }

    /**
     * @notice function to check if user's collateral position is solvent
     * @dev returns (true, 0) if the token is not a valid collateral
     * @param _user address of the user
     * @param _token address of the token
     * @param _open open a position or close a position
     * @return solvent
     * @return debtAmount total debt amount including interests
     */
    function isSolvent(
        address _user,
        ERC20 _token,
        bool _open
    ) external view returns (bool solvent, uint256 debtAmount) {
        return _isSolvent(_user, _token, _open);
    }

    /**
     * Internal Functions
     */

    function _checkCollateralExist(ERC20 _token) internal view {
        if (collateralSettings[_token].decimals == 0) revert PlatypusTreasure_InvalidToken();
    }

    /**
     * @notice _accrue debt interest
     * @dev Updates the contract's state by calculating the additional interest accrued since the last time
     */
    function _accrue() internal {
        uint256 interest = _interestSinceLastAccrue();

        // set last time accrued. unsafe cast is intended
        lastAccrued = uint32(block.timestamp);

        // plus interest
        totalDebtAmount += toUint112(interest);
        totalFeeCollected += toUint112(interest);

        emit Accrue(interest);
    }

    /**
     * @notice function to check if user's collateral position is solvent
     * @dev returns (true, 0) if the token is not a valid collateral
     * @param _user address of the user
     * @param _token address of the token
     * @param _open open a position or close a position
     * @return solvent
     * @return debtAmount total debt amount including interests
     */
    function _isSolvent(
        address _user,
        ERC20 _token,
        bool _open
    ) internal view returns (bool solvent, uint256 debtAmount) {
        uint256 debtShare = userPositions[_token][_user].debtShare;

        // fast path
        if (debtShare == 0) return (true, 0);

        // totalDebtShare > 0 as debtShare is non-zero
        debtAmount = (debtShare * (totalDebtAmount + _interestSinceLastAccrue())) / totalDebtShare;
        solvent = debtAmount <= (_open ? _borrowLimitUSP(_user, _token) : _liquidateLimitUSP(_user, _token));
    }

    /**
     * @notice function that returns the collateral lp tokens deposited on master platypus
     * @param _token collateral lp address
     * @param _user user address
     * @return uint of collateral amount
     */
    function _getCollateralAmount(ERC20 _token, address _user) internal view returns (uint256) {
        CollateralSetting storage setting = collateralSettings[_token];
        if (setting.isLp) {
            return setting.masterPlatypus.getUserInfo(setting.pid, _user).amount;
        } else {
            return userPositions[_token][_user].collateralAmount;
        }
    }

    /**
     * @notice calculate additional interest accrued from last time
     * @return The interest accrued from last time
     */
    function _interestSinceLastAccrue() internal view returns (uint256) {
        // calculate elapsed time from last accrued at
        uint256 elapsedTime;
        unchecked {
            // underflow is intended
            elapsedTime = uint32(block.timestamp) - lastAccrued;
        }
        // TODO: determine if we want to make minimal interval between accrue (e.g. 1h) to save gas
        if (elapsedTime == 0) return 0;

        // calculate interest based on elapsed time and interest rate
        return (elapsedTime * totalDebtAmount * _interestRate()) / 10000 / 365 days;
    }

    /**
     * @notice Return the dynamic interest rate based on the cov ratio of USP in main pool
     * @dev interest rate = c ^ k / 100
     * @return InterestRate e.g 1500 = 15%, base 10000
     */
    function _interestRate() internal view returns (uint256) {
        IAsset uspLp = marketSetting.uspLp;
        uint256 liability = uspLp.liability();
        if (liability == 0) return 0;

        uint256 covRatio = (uspLp.cash() * 1e18) / liability;
        // Interest rate has 1e18 * 1e2 decimals => interest rate / 100 / 1e18 * 10000 => / 1e16
        uint256 interestRate = covRatio.rpow(marketSetting.k, 1e18) / 1e16;
        // cap interest rate by 1000%
        return interestRate <= 100000 ? interestRate : 100000;
    }

    /**
     * @notice External view function that returns dynamic interest rates from the cov ratio of USP in the main pool
     * @dev interest rate = c ^ k / 100
     * @return InterestRate e.g 15% = 1500, base 10000
     */
    function currentInterestRate() external view returns (uint256) {
        return _interestRate();
    }

    /**
     * @notice Return the price of LP token
     * It should equal to the underlying token price adjusted by the exchange rate
     */
    function _getLPUnitPrice(IAsset _lp) internal view returns (uint256) {
        uint256 underlyingTokenPrice = oracle.getAssetPrice(IAsset(_lp).underlyingToken());
        uint256 totalSupply = IAsset(_lp).totalSupply();

        if (totalSupply == 0) {
            return underlyingTokenPrice;
        } else {
            // Note: Withdrawal loss is not considered here. And it should not been taken into consideration for
            // liquidation criteria.
            return (underlyingTokenPrice * IAsset(_lp).liability()) / totalSupply;
        }
    }

    /**
     * @notice returns the USD amount
     * @param _token collateral token address
     * @param _amount token amount
     * @return The USD amount in 18 decimals
     */
    function _tokenPriceUSD(ERC20 _token, uint256 _amount) internal view returns (uint256) {
        CollateralSetting storage setting = collateralSettings[_token];
        uint256 unitPrice;
        if (setting.isLp) {
            unitPrice = _getLPUnitPrice(IAsset(address(_token)));
        } else {
            unitPrice = oracle.getAssetPrice(address(_token));
        }
        // Convert to 18 decimals. Price quoted in USD has 8 decimals
        return (_amount * unitPrice * 1e10) / 10**(setting.decimals);
    }

    /**
     * @notice returns the borrow limit amount in USD
     * @param _user user address
     * @param _token collateral token address
     * @return uint256 The USD amount in 18 decimals
     */
    function _borrowLimitUSP(address _user, ERC20 _token) internal view returns (uint256) {
        uint256 amount = _getCollateralAmount(_token, _user);
        uint256 totalUSD = _tokenPriceUSD(_token, amount);
        return (totalUSD * collateralSettings[_token].collateralFactor) / 10000;
    }

    /**
     * @notice returns the liquidation threshold amount in USD
     * @param _user user address
     * @param _token collateral token address
     * @return The USD amount in 18 decimals
     */
    function _liquidateLimitUSP(address _user, ERC20 _token) internal view returns (uint256) {
        uint256 amount = _getCollateralAmount(_token, _user);
        uint256 totalUSD = _tokenPriceUSD(_token, amount);
        return (totalUSD * collateralSettings[_token].liquidationThreshold) / 10000;
    }

    /**
     * @notice returns the debt amount in USD
     * @dev interest is skipped due to gas
     * @param _user user address
     * @param _token collateral token address
     * @return The USD amount in 18 decimals
     */
    function _debtAmountUSP(address _user, ERC20 _token) internal view returns (uint256) {
        if (totalDebtShare == 0) return 0;
        return
            (uint256(userPositions[_token][_user].debtShare) * (totalDebtAmount + _interestSinceLastAccrue())) /
            totalDebtShare;
    }

    function toUint96(uint256 val) internal pure returns (uint96) {
        if (val > type(uint96).max) revert Uint96_Overflow();
        return uint96(val);
    }

    function toUint112(uint256 val) internal pure returns (uint112) {
        if (val > type(uint112).max) revert Uint112_Overflow();
        return uint112(val);
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert Uint128_Overflow();
        return uint128(val);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC3156FlashLenderUpgradeable.sol';

interface IUSP is IERC20Upgradeable, IERC3156FlashLenderUpgradeable {
    function mint(address _to, uint256 _amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// Based on AAVE protocol
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/// @title IPriceOracleGetter interface
interface IPriceOracleGetter {
    /// @dev returns the asset price in ETH
    function getAssetPrice(address _asset) external view returns (uint256);

    /// @dev returns the reciprocal of asset price
    function getAssetPriceReciprocal(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IAsset.sol';
import './IBoostedMultiRewarder.sol';
import './IPlatypusTreasure.sol';

/**
 * @dev Interface of the MasterPlatypusV4
 */
interface IMasterPlatypusV4 {
    // Info of each user.
    struct UserInfo {
        // 256 bit packed
        uint128 amount; // How many LP tokens the user has provided.
        uint128 factor; // non-dialuting factor = sqrt (lpAmount * vePtp.balanceOf())
        // 256 bit packed
        uint128 rewardDebt; // Reward debt. See explanation below.
        uint128 claimablePtp;
        //
        // We do some fancy math here. Basically, any point in time, the amount of PTPs
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accPtpPerShare + user.factor * pool.accPtpPerFactorShare) / 1e12) -
        //        user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPtpPerShare`, `accPtpPerFactorShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IAsset lpToken; // Address of LP token contract.
        IBoostedMultiRewarder rewarder;
        uint128 sumOfFactors; // 20.18 fixed point. The sum of all non dialuting factors by all of the users in the pool
        uint128 accPtpPerShare; // 26.12 fixed point. Accumulated PTPs per share, times 1e12.
        uint128 accPtpPerFactorShare; // 26.12 fixed point. Accumulated ptp per factor share
    }

    function platypusTreasure() external view returns (IPlatypusTreasure);

    function getSumOfFactors(uint256) external view returns (uint256);

    function poolLength() external view returns (uint256);

    function getPoolId(address) external view returns (uint256);

    function getUserInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingPtp,
            IERC20[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusTokens
        );

    function rewarderBonusTokenInfo(uint256 _pid)
        external
        view
        returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        );

    function withdraw(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function liquidate(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external;

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function updateFactor(address _user, uint256 _newVePtpBalance) external;

    function notifyRewardAmount(address _lpToken, uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IPool {
    function assetOf(address token) external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        address to,
        uint256 deadline
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function withdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialWithdraw(address token, uint256 liquidity)
        external
        view
        returns (
            uint256 amount,
            uint256 fee,
            bool enoughCash
        );

    function quotePotentialWithdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function quoteMaxInitialAssetWithdrawable(address initialToken, address wantedToken)
        external
        view
        returns (uint256 maxInitialAssetAmount);

    function getTokenAddresses() external view returns (address[] memory);

    function addAsset(address token, address asset) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrowerUpgradeable.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLenderUpgradeable {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrowerUpgradeable receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrowerUpgradeable {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Interface of Asset
 */
interface IAsset is IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function underlyingToken() external view returns (address);

    function underlyingTokenBalance() external view returns (uint256);

    function cash() external view returns (uint256);

    function liability() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IBoostedMultiRewarder {
    function onPtpReward(
        address _user,
        uint256 _lpAmount,
        uint256 _newLpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external returns (uint256[] memory rewards);

    function onUpdateFactor(
        address _user,
        uint256 _lpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external;

    function pendingTokens(
        address _user,
        uint256 _lpAmount,
        uint256 _factor
    ) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPlatypusTreasure {
    function isSolvent(
        address _user,
        address _token,
        bool _open
    ) external view returns (bool solvent, uint256 debtAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}