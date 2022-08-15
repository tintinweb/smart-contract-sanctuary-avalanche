// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./lib/Babylonian.sol";
import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./utils/MyPausable.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IBoardroom.sol";
import "./glad_core/roman_nft/IPreyPredator.sol";
import "./glad_core/roman_nft/INFTPool.sol";

contract TreasuryNG is ContractGuard, MyPausable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant PERIOD = 4 hours;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    // epoch
    uint256 public startTime;
    uint256 public epoch = 0;

    enum PEG_STATUS {
        UNDERPEG,
        PEGGED,
        OVERPEG
    }

    mapping(uint256 => PEG_STATUS) public epochPegStatus;

    // exclusions from total supply
    address[] public excludedFromTotalSupply;

    // core components
    address public glad;
    address public nft;
    address public gladshare;

    address public boardroom;
    address public gladOracle;

    address public underpegPool;
    address public nftPool;

    bool public nftGladPoolEnded;

    uint256 public totalDebt;

    // price
    uint256 public gladPriceOne;
    uint256 public gladPriceCeiling;

    uint256 public seigniorageSaved;

    uint256 public lastExpansion;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxDebtRatioPercent;

    /* =================== Added variables =================== */
    uint256 public previousEpochGladPrice;
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;

    uint256 public nftRewardPercent;
    uint256 public treasuryFundPercent;

    address public daoFund;
    uint256 public daoFundSharedPercent;

    address public devFund;
    uint256 public devFundSharedPercent;

    address public teamFund;
    uint256 public teamFundPercent;

    uint256 public priceMultiplier;

    uint256[] public priceTiers;
    uint256[] public multiplierTiers;

    uint256 underpegMintPrice = 21 * 1e18;

    mapping(uint256 => uint256) underpegMintedPerEpoch;

    bool underpegStealing = true;

    uint256 underpegGeneration = 23;

    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event BoughtBonds(
        address indexed from,
        uint256 gladAmount,
        uint256 bondAmount
    );
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);
    event DebtAdded(uint256 debt);

    /* =================== Modifier =================== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller is not the operator");
        _;
    }

    modifier checkCondition() {
        require(block.timestamp >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch() {
        require(
            block.timestamp >= nextEpochPoint(),
            "Treasury: not opened yet"
        );

        _;

        epoch = epoch.add(1);
    }

    modifier checkOperator() {
        require(
            IBasisAsset(glad).operator() == address(this) &&
                IBasisAsset(nft).operator() == address(this) &&
                IBasisAsset(gladshare).operator() == address(this) &&
                Operator(boardroom).operator() == address(this),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized() {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getGladPrice() public view returns (uint256 gladPrice) {
        try IOracle(gladOracle).consult(glad, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult glad price from the oracle");
        }
    }

    function getGladUpdatedPrice() public view returns (uint256 _gladPrice) {
        try IOracle(gladOracle).twap(glad, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult glad price from the oracle");
        }
    }

    // budget
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function getRedeemableBonds()
        public
        view
        returns (uint256 _redeemableBonds)
    {
        uint256 _gladPrice = getGladPrice();
        if (_gladPrice > gladPriceCeiling) {
            uint256 _totalGlad = IERC20(glad).balanceOf(address(this));
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalGlad.mul(1e18).div(_rate);
            }
        }
    }

    function getBondPremiumRate() public view returns (uint256 _rate) {
        uint256 _gladPrice = getGladPrice();
        if (_gladPrice > gladPriceCeiling) {
            uint256 _gladPricePremiumThreshold = gladPriceOne
                .mul(premiumThreshold)
                .div(100);
            if (_gladPrice >= _gladPricePremiumThreshold) {
                //Price > 1.10
                uint256 _premiumAmount = _gladPrice
                    .sub(gladPriceOne)
                    .mul(premiumPercent)
                    .div(10000);
                _rate = gladPriceOne.add(_premiumAmount);
                if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
                    _rate = maxPremiumRate;
                }
            } else {
                // no premium bonus
                _rate = gladPriceOne;
            }
        }
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _glad,
        address _nft,
        address _gladshare,
        address _gladOracle,
        address _boardroom,
        address _underpegPool,
        address _nftPool,
        uint256 _startTime,
        address _oldTreasury
    ) public notInitialized {
        glad = _glad;
        nft = _nft;
        gladshare = _gladshare;
        gladOracle = _gladOracle;
        boardroom = _boardroom;
        startTime = _startTime;
        underpegPool = _underpegPool;
        IERC20(glad).safeApprove(underpegPool, type(uint256).max);
        nftPool = _nftPool;
        IERC20(glad).safeApprove(nftPool, type(uint256).max);

        gladPriceOne = 10**17; // This is to allow a PEG of 1 GLAD per 0.1 AVAX
        gladPriceCeiling = gladPriceOne.mul(101).div(100);

        priceMultiplier = 80; // 0.8

        // Dynamic max expansion percent
        supplyTiers = [
            0 ether,
            100000 ether,
            200000 ether,
            300000 ether,
            400000 ether,
            500000 ether
        ];
        maxExpansionTiers = [300, 350, 400, 450, 500, 600];

        maxSupplyExpansionPercent = 400; // Upto 4.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for boardroom
        maxDebtRatioPercent = 4000; // Upto 40% supply of GBOND to purchase

        nftRewardPercent = 1000; // 10% of expansion reserved for NFTPool
        teamFundPercent = 300; // 3% of expansion reserved for team
        treasuryFundPercent = 700; // 7% of expansion reserved for Treasury

        premiumThreshold = 110;
        premiumPercent = 7000;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(glad).balanceOf(address(this));

        initialized = true;
        operator = msg.sender;
        _migrate(_oldTreasury);
        _pause();
        emit Initialized(msg.sender, block.number);
    }

    function _migrate(address _oldTreasury) internal {
        TreasuryNG t = TreasuryNG(_oldTreasury);
        epoch = t.epoch();
        for (uint256 i = 0; i < epoch; i++)
            epochPegStatus[i] = t.epochPegStatus(i);
        seigniorageSaved = t.seigniorageSaved();
        lastExpansion = t.lastExpansion();
        previousEpochGladPrice = t.previousEpochGladPrice();
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setBoardroom(address _boardroom) external onlyOperator {
        boardroom = _boardroom;
    }

    function setUnderpegPool(address _underpegPool) external onlyOperator {
        if (underpegPool != address(0)) {
            IERC20(glad).safeApprove(underpegPool, 0);
        }
        underpegPool = _underpegPool;
        IERC20(glad).safeApprove(underpegPool, type(uint256).max);
    }

    function setExcludedFromTotalSupply(
        address[] memory _excludedFromTotalSupply
    ) external onlyOperator {
        excludedFromTotalSupply = _excludedFromTotalSupply;
    }

    function setGladOracle(address _gladOracle) external onlyOperator {
        gladOracle = _gladOracle;
    }

    function setGladPriceCeiling(uint256 _gladPriceCeiling)
        external
        onlyOperator
    {
        require(
            _gladPriceCeiling >= gladPriceOne &&
                _gladPriceCeiling <= gladPriceOne.mul(120).div(100),
            "out of range"
        ); // [$1.0, $1.2]
        gladPriceCeiling = _gladPriceCeiling;
    }

    function setPriceMultiplier(uint256 _priceMultiplier)
        external
        onlyOperator
    {
        require(
            _priceMultiplier > 0 && _priceMultiplier <= 100,
            "out of range"
        );
        priceMultiplier = _priceMultiplier;
    }

    function setSupplyExpansionMultiplier(
        uint256[] memory _priceTiers,
        uint256[] memory _multiplierTiers
    ) public onlyOperator {
        require(
            _priceTiers.length == _multiplierTiers.length,
            "tier length mismatch"
        );
        for (uint256 i; i < _priceTiers.length; i++) {
            require(_multiplierTiers[i] < 200, "multiplier out of range");
            if (i > 0) {
                require(
                    _priceTiers[i - 1] < _priceTiers[i],
                    "invalid order"
                );
            }
        }
        priceTiers = _priceTiers;
        multiplierTiers = _multiplierTiers;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent)
        external
        onlyOperator
    {
        require(
            _maxSupplyExpansionPercent >= 10 &&
                _maxSupplyExpansionPercent <= 1000,
            "_maxSupplyExpansionPercent: out of range"
        ); // [0.1%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setBoardroomPercents(
        uint256 _nftRewardPercent,
        uint256 _teamFundPercent,
        uint256 _treasuryFundPercent
    ) external onlyOperator {
        require(
            _nftRewardPercent + _teamFundPercent + _treasuryFundPercent <=
                10000,
            "setBoardroomPercents: out of range"
        );
        nftRewardPercent = _nftRewardPercent;
        teamFundPercent = _teamFundPercent;
        treasuryFundPercent = _treasuryFundPercent;
    }

    function setSupplyTiersEntry(uint8 _index, uint256 _value)
        external
        onlyOperator
        returns (bool)
    {
        require(_index >= 0, "Index has to be higher than 0");
        require(
            _index < supplyTiers.length,
            "Index has to be lower than count of tiers"
        );
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1]);
        }
        if (_index < supplyTiers.length - 1) {
            require(_value < supplyTiers[_index + 1]);
        }
        supplyTiers[_index] = _value;
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value)
        external
        onlyOperator
        returns (bool)
    {
        require(_index >= 0, "Index has to be higher than 0");
        require(
            _index < maxExpansionTiers.length,
            "Index has to be lower than count of tiers"
        );
        require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent)
        external
        onlyOperator
    {
        require(
            _bondDepletionFloorPercent >= 500 &&
                _bondDepletionFloorPercent <= 10000,
            "out of range"
        ); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent)
        external
        onlyOperator
    {
        require(
            _maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000,
            "out of range"
        ); // [10%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 2500, "out of range"); // <= 25%
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 500, "out of range"); // <= 5%
        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;
    }

    function setTeamFund(address _teamFund) external onlyOperator {
        require(_teamFund != address(0), "zero");
        teamFund = _teamFund;
    }

    function setMaxDiscountRate(uint256 _maxDiscountRate)
        external
        onlyOperator
    {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
        maxPremiumRate = _maxPremiumRate;
    }

    function setUnderpegMintPrice(uint256 _price) external onlyOperator {
        underpegMintPrice = _price;
    }

    function setUnderpegStealing(bool _stealing) external onlyOperator {
        underpegStealing = _stealing;
    }

    function setUnderpegGeneration(uint256 _gen) external onlyOperator {
        underpegGeneration = _gen;
    }

    function setDiscountPercent(uint256 _discountPercent)
        external
        onlyOperator
    {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumThreshold(uint256 _premiumThreshold)
        external
        onlyOperator
    {
        require(
            _premiumThreshold >= gladPriceCeiling,
            "_premiumThreshold exceeds gladPriceCeiling"
        );
        require(
            _premiumThreshold <= 150,
            "_premiumThreshold is higher than 1.5"
        );
        premiumThreshold = _premiumThreshold;
    }

    function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    function resetNFTPoolRewarding() external onlyOperator {
        nftGladPoolEnded = false;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateGladPrice() internal {
        try IOracle(gladOracle).update() {} catch {}
    }

    function getGladCirculatingSupply() public view returns (uint256) {
        IERC20 gladErc20 = IERC20(glad);
        uint256 totalSupply = gladErc20.totalSupply();
        uint256 balanceExcluded = 0;
        for (
            uint8 entryId = 0;
            entryId < excludedFromTotalSupply.length;
            ++entryId
        ) {
            balanceExcluded = balanceExcluded.add(
                gladErc20.balanceOf(excludedFromTotalSupply[entryId])
            );
        }
        return totalSupply.sub(balanceExcluded);
    }

    function mintUnderpeg(uint256 _amount, uint256 targetPrice)
        external
        onlyOneBlock
        checkCondition
        checkOperator
        whenNotPaused
    {
        require(_amount > 0, "Treasury: cannot mint zero nfts");

        uint256 gladPrice = getGladPrice();
        require(gladPrice == targetPrice, "Treasury: GLAD price moved");
        require(
            gladPrice < gladPriceOne, // price < 0.1 AVAX
            "Treasury: gladPrice not eligible for underpeg minting"
        );

        uint64 currentGeneration = IPreyPredator(nft).currentGeneration();

        uint256 _mintPrice = underpegMintPrice;
        uint256 maxEpochUnderpegMint = (lastExpansion * priceMultiplier) / underpegMintPrice;
        if (maxEpochUnderpegMint == 0) maxEpochUnderpegMint = 1;
        require(underpegMintedPerEpoch[epoch] + _amount <= maxEpochUnderpegMint, "Mint less, there are no this many underpeg tokens left for this epoch");
        underpegMintedPerEpoch[epoch] += _amount;
        uint256 _gladAmount = _mintPrice * _amount;

        IERC20(glad).safeTransferFrom(msg.sender, address(this), _gladAmount);
        IPreyPredator(nft).mintGeneric(msg.sender, _amount, _mintPrice, underpegGeneration, underpegStealing);

        _updateGladPrice();

        emit BoughtBonds(msg.sender, _gladAmount, _amount);
    }

    function getMaxEpochUnderpegMintCount() public view returns (uint256) {
        return (lastExpansion * priceMultiplier) / underpegMintPrice;
    }

    function _sendToBoardroom(uint256 _amount) internal {
        IBasisAsset(glad).mint(address(this), _amount);

        uint256 _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(glad).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);
        }

        uint256 _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
            IERC20(glad).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(block.timestamp, _devFundSharedAmount);
        }

        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount);

        IERC20(glad).safeApprove(boardroom, 0);
        IERC20(glad).safeApprove(boardroom, _amount);
        IBoardroom(boardroom).allocateSeigniorage(_amount);
        emit BoardroomFunded(block.timestamp, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint256 _gladSupply)
        internal
        returns (uint256)
    {
        for (uint256 tierId = supplyTiers.length - 1; tierId >= 0; --tierId) {
            if (_gladSupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    function _calculateSupplyExpansionMultiplier(uint256 _price)
        internal
        view
        returns (uint256)
    {
        uint256 length = multiplierTiers.length;
        if (length == 0) return 100;
        if (_price < priceTiers[0]) {
            return multiplierTiers[0];
        }
        if (_price >= priceTiers[length - 1]) {
            return multiplierTiers[length - 1];
        }
        for (uint256 i = 1; i < length; i++) {
            if (_price < priceTiers[i]) {
                return
                    multiplierTiers[i] +
                    ((multiplierTiers[i - 1] - multiplierTiers[i]) *
                        (priceTiers[i] - _price)) /
                    (priceTiers[i] - priceTiers[i - 1]);
            }
        }
    }

    function _getPegStatus(uint256 gladPrice)
        internal
        view
        returns (PEG_STATUS)
    {
        if (gladPrice < gladPriceOne) return PEG_STATUS.UNDERPEG;
        if (gladPrice > gladPriceCeiling) return PEG_STATUS.OVERPEG;
        return PEG_STATUS.PEGGED;
    }

    function addDebt(uint256 debt) external {
        require(msg.sender == underpegPool, "only unerpeg pool can call this");
        totalDebt += debt;

        emit DebtAdded(debt);
    }

    function allocateSeigniorage()
        external
        onlyOneBlock
        checkCondition
        checkEpoch
        checkOperator
        whenNotPaused
    {
        _updateGladPrice();
        previousEpochGladPrice = getGladPrice();
        uint256 gladSupply = getGladCirculatingSupply().sub(seigniorageSaved);
        if (previousEpochGladPrice > gladPriceCeiling) {
            // Expansion ($GLAD Price > 1 $MIM): there is some seigniorage to be allocated
            uint256 _percentage = previousEpochGladPrice.sub(gladPriceOne).mul(10);
            uint256 _savedForBoardroom;
            uint256 _savedForNFTPool;
            uint256 _savedForTeam;
            uint256 _savedForTreasury;
            uint256 _mse = _calculateMaxSupplyExpansionPercent(gladSupply).mul(
                1e14
            );
            uint256 expantionMultiplier = _calculateSupplyExpansionMultiplier(
                previousEpochGladPrice
            );
            _mse = _mse.mul(expantionMultiplier).div(100);
            if (_percentage > _mse) {
                _percentage = _mse;
            }
            // have not saved enough to pay debt, mint more
            uint256 _seigniorage = gladSupply.mul(_percentage).div(1e18);
            IBasisAsset(glad).mint(address(this), _seigniorage);

            _savedForBoardroom = _seigniorage
                .mul(seigniorageExpansionFloorPercent)
                .div(10000);
            if (totalDebt > 0) {
                if (totalDebt > _seigniorage - _savedForBoardroom) {
                    totalDebt -= _seigniorage - _savedForBoardroom;
                } else {
                    _savedForBoardroom = _seigniorage - totalDebt;

                    totalDebt = 0;
                }
            }

            if (!nftGladPoolEnded) {
                //_savedForNFTPool = _seigniorage.mul(nftRewardPercent).div(
                _savedForNFTPool = _savedForBoardroom.mul(nftRewardPercent).div(
                    10000
                );
                //_savedForBoardroom -= _savedForNFTPool;
            }
            if (_savedForNFTPool > 0) {
                INFTPool(nftPool).addGladReward(_savedForNFTPool);
            }
            //_savedForTeam = _seigniorage.mul(teamFundPercent).div(10000);
            _savedForTeam = _savedForBoardroom.mul(teamFundPercent).div(10000);
            if (_savedForTeam > 0) {
                IERC20(glad).safeTransfer(teamFund, _savedForTeam);
                //_savedForBoardroom -= _savedForTeam;
            }
            //_savedForTreasury = _seigniorage.mul(treasuryFundPercent).div(
            _savedForTreasury = _savedForBoardroom.mul(treasuryFundPercent).div(
                10000
            );
            //if (_savedForTreasury > 0) {
                //_savedForBoardroom -= _savedForTreasury;
            //}
            if (_savedForBoardroom > 0) {
                _sendToBoardroom(_savedForBoardroom - _savedForTreasury - _savedForTeam - _savedForNFTPool);
            }

            lastExpansion = _seigniorage;
        } else if (previousEpochGladPrice < gladPriceOne) {
            nftGladPoolEnded = true;
        }

        epochPegStatus[epoch] = _getPegStatus(previousEpochGladPrice);
        bool underpegMint;
        if (epochPegStatus[epoch] == PEG_STATUS.OVERPEG && epoch >= 2) {
            underpegMint = true;
            for (uint256 i = 1; i < 3; i++) {
                if (epochPegStatus[epoch - i] != PEG_STATUS.OVERPEG) {
                    underpegMint = false;
                    break;
                }
            }
        } else if (epochPegStatus[epoch] == PEG_STATUS.UNDERPEG && epoch >= 5) {
            underpegMint = true;
            for (uint256 i = 1; i < 6; i++) {
                if (epochPegStatus[epoch - i] != PEG_STATUS.UNDERPEG) {
                    underpegMint = false;
                    break;
                }
            }
        }
        // uint8 is too small to continue this
        //if (underpegMint) {
        //    IPreyPredator(nft).increaseGeneration();
        //}
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(glad), "glad");
        require(address(_token) != address(gladshare), "share");
        _token.safeTransfer(_to, _amount);
    }

    function boardroomSetOperator(address _operator) external onlyOperator {
        IBoardroom(boardroom).setOperator(_operator);
    }

    function boardroomSetLockUp(
        uint256 _withdrawLockupEpochs,
        uint256 _rewardLockupEpochs
    ) external onlyOperator {
        IBoardroom(boardroom).setLockUp(
            _withdrawLockupEpochs,
            _rewardLockupEpochs
        );
    }

    function boardroomAllocateSeigniorage(uint256 amount)
        external
        onlyOperator
    {
        IBoardroom(boardroom).allocateSeigniorage(amount);
    }

    function setNftPool(address _nftPool) external onlyOperator {
        if (nftPool != address(0)) {
            IERC20(glad).safeApprove(nftPool, 0);
        }
        nftPool = _nftPool;
        IERC20(glad).safeApprove(nftPool, type(uint256).max);
    }

    function burnGlad(uint256 amount) external onlyOperator {
        IBasisAsset(glad).burn(amount);
    }

    function burnGladShare(uint256 amount) external onlyOperator {
        IBasisAsset(gladshare).burn(amount);
    }

    function transferERC20(address tokenAddress, address to, uint256 amount) external onlyOperator {
        IERC20(tokenAddress).transfer(to, amount);
    }

    function approveERC20(address tokenAddress, address spender, uint256 amount) external onlyOperator {
        IERC20(tokenAddress).approve(spender, amount);
    }

    function sendValue(address target, uint256 value) external onlyOperator {
        (bool success, ) = payable(target).call{value: value}("");
        require(success == true);
    }

    function boardroomGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IBoardroom(boardroom).governanceRecoverUnsupported(
            _token,
            _amount,
            _to
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyPausable is Pausable, Ownable {
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IBoardroom {
    function balanceOf(address _member) external view returns (uint256);

    function earned(address _member) external view returns (uint256);

    function canWithdraw(address _member) external view returns (bool);

    function canClaimReward(address _member) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getGrapePrice() external view returns (uint256);

    function setOperator(address _operator) external;

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint256 _amount) external;

    function governanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IPreyPredator {
    event TokenTraitsUpdated(uint256 tokenId, PreyPredator traits);
    // struct to store each token's traits
    struct PreyPredator {
        bool isPrey;
        uint8 environment;
        uint8 body;
        uint8 armor;
        uint8 helmet;
        uint8 shoes;
        uint8 shield;
        uint8 weapon;
        uint8 item;
        uint8 alphaIndex;
        uint64 generation;
        uint8 agility;
        uint8 charisma;
        uint8 damage;
        uint8 defense;
        uint8 dexterity;
        uint8 health;
        uint8 intelligence;
        uint8 luck;
        uint8 strength;
    }

    function traitsRevealed(uint256 tokenId) external view returns (bool);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (PreyPredator memory);

    function mintUnderpeg(
        address to,
        uint256 amount,
        uint256 price
    ) external;

    function mintGeneric (
        address to,
        uint256 amount,
        uint256 price,
        uint256 generation,
        bool stealing
    ) external;

    function increaseGeneration() external;

    function currentGeneration() external view returns (uint8);

    function getGenTokens(uint8 generation) external view returns (uint256);

    function mintedPrice(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface INFTPool {
    function addGladReward(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}