// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// External Imports
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH9} from "../../../external/IWETH9.sol";
import {IGMXVault} from "../../../external/gmx/IGMXVault.sol";
import {IFastPriceFeed} from "../../../external/gmx/IFastPriceFeed.sol";
import {IVaultPriceFeed} from "../../../external/gmx/IVaultPriceFeed.sol";

/// Internal Imports
import {CustomReentrancyGuard} from "../../../utils/CustomReentrancyGuard.sol";
import {TraderJoeLPAdapter} from "../../adapters/TraderJoeLPAdapter.sol";
import {ISPToken} from "../../../interfaces/ISPToken.sol";
import {IGMXFEYProduct} from "../../../interfaces/IGMXFEYProduct.sol";
import {IStructPriceOracle} from "../../../interfaces/IStructPriceOracle.sol";
import {IDistributionManager} from "../../../interfaces/IDistributionManager.sol";

import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {Helpers} from "../../libraries/helpers/Helpers.sol";
import {Constants} from "../../libraries/helpers/Constants.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {Validation} from "../../libraries/logic/Validation.sol";
import {GACManaged} from "../../common/GACManaged.sol";
import {IGAC} from "../../../interfaces/IGAC.sol";
import {WadMath} from "../../../utils/WadMath.sol";
import {IGMXYieldSource} from "../../../interfaces/IGMXYieldSource.sol";

/**
 * @title Fixed and Enhanced Yield GMX Product contract
 * @notice Main point of interaction with the FEY product contract
 * - Users can:
 *   # Deposit
 *   # Withdraw
 *   # Claim Excess
 *
 * @author Struct Finance
 */
contract FEYGMXProduct is IGMXFEYProduct, CustomReentrancyGuard, GACManaged, TraderJoeLPAdapter {
    using SafeERC20 for IERC20Metadata;
    using WadMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    IGMXVault public constant VAULT = IGMXVault(0x9ab2De34A33fB459b538c43f251eB825645e8595);
    IVaultPriceFeed public constant VAULT_PRICE_FEED = IVaultPriceFeed(0x27e99387af40e5CA9CE21418552f15F02C8C57E7);
    IFastPriceFeed public constant FAST_PRICE_FEED = IFastPriceFeed(0xE547CaDbe081749e5b3DC53CB792DfaEA2D02fD2);

    /// @dev Helps to identify the current state of the product
    DataTypes.State internal currentState;

    /// @dev Configuration for the current product
    DataTypes.ProductConfig internal productConfig;

    /// @dev Address of the Native token
    address payable public nativeToken;

    /// @dev Address of the Product Factory contract
    address public productFactory;

    /// @dev Initializer flag
    bool private isInitialized;

    /// @dev Total Fee Senior
    uint256 public feeTotalSr;

    /// @dev Total Fee Junior
    uint256 public feeTotalJr;

    /// @dev DistributionManager Interface
    IDistributionManager private distributionManager;

    /// @dev StructPriceOracle Interface
    IStructPriceOracle private structPriceOracle;

    /// @dev The address of the Struct SP Token
    ISPToken public spToken;

    /// @dev The address of the GMXYieldSource contract
    IGMXYieldSource public yieldSource;

    /// @dev Tranche id => user address => deposits
    mapping(DataTypes.Tranche => mapping(address => DataTypes.Investor)) internal investors;

    /// @dev Contains the info specific to senior and junior tranches
    mapping(DataTypes.Tranche => DataTypes.TrancheInfo) internal trancheInfo;

    /// @dev Contains the specifications of senior and junior tranches
    mapping(DataTypes.Tranche => DataTypes.TrancheConfig) internal trancheConfig;

    /// @dev Swap paths
    address[] internal seniorToNative;
    address[] internal juniorToNative;

    uint256 internal _srDecimals;
    uint256 internal _jrDecimals;

    /**
     * @notice Initializes the Product based on the given parameters
     * @dev It should be called only once
     * @param _initConfig Configuration of the tranches and product config
     * @param _structPriceOracle The address of the struct price oracle
     * @param _spToken Address of the Struct SP Token
     * @param _globalAccessControl Address of the StructGAC contract
     * @param _distributionManager Address of the distribution manager contract
     * @param _yieldSource Address of the YieldSource contract
     */
    function initialize(
        DataTypes.InitConfigParam calldata _initConfig,
        IStructPriceOracle _structPriceOracle,
        ISPToken _spToken,
        IGAC _globalAccessControl,
        IDistributionManager _distributionManager,
        address _yieldSource,
        address payable _nativeToken
    ) external override {
        require(!isInitialized, Errors.ACE_INITIALIZER);
        __GACManaged_init(_globalAccessControl);

        productFactory = _msgSender();

        trancheConfig[DataTypes.Tranche.Senior] = _initConfig.configTrancheSr;
        trancheConfig[DataTypes.Tranche.Junior] = _initConfig.configTrancheJr;
        productConfig = _initConfig.productConfig;
        nativeToken = _nativeToken;

        structPriceOracle = _structPriceOracle;
        distributionManager = _distributionManager;
        spToken = _spToken;
        yieldSource = IGMXYieldSource(_yieldSource);

        slippage = Constants.DEFAULT_SLIPPAGE;
        _srDecimals = _initConfig.configTrancheSr.decimals;
        _jrDecimals = _initConfig.configTrancheJr.decimals;

        /// @dev Construct swap path array
        address[] memory _seniorToNative = new address[](2);
        _seniorToNative[0] = address(_initConfig.configTrancheSr.tokenAddress);
        _seniorToNative[1] = nativeToken;
        seniorToNative = _seniorToNative;

        address[] memory _juniorToNative = new address[](2);
        _juniorToNative[0] = address(_initConfig.configTrancheJr.tokenAddress);
        _juniorToNative[1] = nativeToken;
        juniorToNative = _juniorToNative;

        isInitialized = true;
    }

    /**
     * @notice Allows users to deposit their funds into the tranche.
     * @dev Assets will be held by the contract until the predetermined investment start time.
     * @param _tranche The tranche into which the assets should be deposited
     * @param _amount The amount of tokens that needs to be deposited into the tranche
     */
    function deposit(DataTypes.Tranche _tranche, uint256 _amount) external payable override nonReentrant gacPausable {
        _deposit(_tranche, _amount, _msgSender());
    }

    /**
     * @notice Allows users to deposit their funds into the tranche.
     * @dev Assets will be held by the contract until the predetermined investment start time.
     * @param _tranche The tranche into which the assets should be deposited
     * @param _amount The amount of tokens that needs to be deposited into the tranche
     * @param _onBehalfOf The address of the beneficiary wallet that should recieve StructSPToken
     */
    function depositFor(DataTypes.Tranche _tranche, uint256 _amount, address _onBehalfOf)
        external
        payable
        override
        nonReentrant
        gacPausable
        onlyRole(FACTORY)
    {
        _deposit(_tranche, _amount, _onBehalfOf);
    }

    /**
     * @notice Method will deposit the funds into the relevant LP.
     * @dev The method will keep track of the total amount that was deposited into each tranche.
     * @dev Swaps will be made to balance out both the sides before adding liquidity
     */
    function invest() external override nonReentrant gacPausable {
        uint256 _srTotal = trancheInfo[DataTypes.Tranche.Senior].tokensDeposited;
        uint256 _jrTotal = trancheInfo[DataTypes.Tranche.Junior].tokensDeposited;
        Validation.validateInvest(
            productConfig.startTimeTranche,
            currentState,
            trancheConfig[DataTypes.Tranche.Senior].capacity,
            trancheConfig[DataTypes.Tranche.Junior].capacity,
            _srTotal,
            _jrTotal
        );

        if (_srTotal == 0 || _jrTotal == 0) {
            trancheInfo[DataTypes.Tranche.Senior].tokensExcess = _srTotal;
            trancheInfo[DataTypes.Tranche.Junior].tokensExcess = _jrTotal;
            trancheInfo[DataTypes.Tranche.Senior].tokensInvestable = 0;
            trancheInfo[DataTypes.Tranche.Junior].tokensInvestable = 0;
            // TODO: Add a new State?
            currentState = DataTypes.State.WITHDRAWN;
            /// @dev Events to transition product state in the subgraph
            emit Invested(0, 0, 0, 0);
            emit StatusUpdated(DataTypes.State.WITHDRAWN);
            emit RemovedFundsFromLP(0, 0, _msgSender());
            return;
        }

        uint256 _jrToSrRate;
        uint256 _srToJrRate;

        /// If both the tranches are using the same token, then the rate will be 1:1
        if (
            trancheConfig[DataTypes.Tranche.Senior].tokenAddress == trancheConfig[DataTypes.Tranche.Junior].tokenAddress
        ) {
            _jrToSrRate = Constants.WAD;
            _srToJrRate = _jrToSrRate;
        } else {
            /// If the tranches are using different tokens, the rate will be calculated
            /// using the ratio of the min prices of the tokens in the vault
            _jrToSrRate = getTokenRate(DataTypes.Tranche.Senior);
            _srToJrRate = getTokenRate(DataTypes.Tranche.Junior);
        }

        uint256 _investedSr;
        uint256 _investedJr;

        /// Check if total deposits in the junior tranche are within the notional value limits,
        /// i.e. the min and max allowable delta between the two tranches, by comparing it with
        /// the min and max allowable value of the senior tranche in terms of junior tokens.
        /// If so, there will be no excess

        uint256 notionalMinJr = productConfig.leverageThresholdMax * _srTotal.wadMul(_jrToSrRate);
        uint256 notionalMaxJr = productConfig.leverageThresholdMin * _srTotal.wadMul(_jrToSrRate);

        if (
            (_jrTotal * Constants.DECIMAL_FACTOR >= notionalMinJr)
                && (_jrTotal * Constants.DECIMAL_FACTOR <= notionalMaxJr)
        ) {
            trancheInfo[DataTypes.Tranche.Junior].tokensInvestable = _jrTotal;
            trancheInfo[DataTypes.Tranche.Senior].tokensInvestable = _srTotal;
            (_investedSr, _investedJr) = _depositToLP(_srTotal, _jrTotal);
        } else if (
            /// Check if the value in the junior tranche is below the notional minimum limit (much less than value in senior tranche)
            /// If so, calculate the amount of excess senior tranche tokens and update state variables
            _jrTotal * Constants.DECIMAL_FACTOR < (notionalMinJr)
        ) {
            uint256 _investableSrTokens =
                (_jrTotal.wadMul(_srToJrRate) * Constants.DECIMAL_FACTOR) / (productConfig.leverageThresholdMax);

            trancheInfo[DataTypes.Tranche.Senior].tokensInvestable = _investableSrTokens;
            trancheInfo[DataTypes.Tranche.Junior].tokensInvestable = _jrTotal;
            trancheInfo[DataTypes.Tranche.Senior].tokensExcess = _srTotal - _investableSrTokens;
            (_investedSr, _investedJr) = _depositToLP(_investableSrTokens, _jrTotal);
        } else {
            /// Else, value in the junior tranche is above the notional maximum limit (much greater than value in senior tranche)
            /// Calculate the amount of excess junior tranche tokens and update state variables
            uint256 _investableJrTokens = notionalMaxJr / Constants.DECIMAL_FACTOR;

            trancheInfo[DataTypes.Tranche.Junior].tokensInvestable = _investableJrTokens;
            trancheInfo[DataTypes.Tranche.Senior].tokensInvestable = _srTotal;
            trancheInfo[DataTypes.Tranche.Junior].tokensExcess = _jrTotal - _investableJrTokens;
            (_investedSr, _investedJr) = _depositToLP(_srTotal, _investableJrTokens);
        }

        /// Update the final amount of tokens invested into each tranche
        trancheInfo[DataTypes.Tranche.Senior].tokensInvested = _investedSr;
        trancheInfo[DataTypes.Tranche.Junior].tokensInvested = _investedJr;

        emit Invested(
            _investedSr,
            _investedJr,
            trancheInfo[DataTypes.Tranche.Senior].tokensInvestable,
            trancheInfo[DataTypes.Tranche.Junior].tokensInvestable
        );
    }

    /**
     * @notice Allows users to claim any excess tokens, and returns their corresponding amount of tokens in return for their SP tokens.
     * @param _tranche The tranche from which the excess tokens to be claimed
     */
    function claimExcess(DataTypes.Tranche _tranche) external override nonReentrant gacPausable {
        (uint256 _userInvested, uint256 _excess) =
            Validation.validateClaimExcess(currentState, investors[_tranche][_msgSender()], trancheInfo[_tranche]);
        _claimExcess(_tranche, _userInvested, _excess);
    }

    /**
     * @notice Allows a user to withdraw the investment from the product once the tranche is matured
     * @param _tranche The tranche id from which the investment should be withdrawn
     */
    function withdraw(DataTypes.Tranche _tranche) external override nonReentrant gacPausable {
        Validation.validateWithdrawal(
            currentState,
            spToken,
            trancheConfig[_tranche].spTokenId,
            investors[_tranche][_msgSender()],
            trancheInfo[_tranche].tokensInvestable
        );
        _calculateUserShareAndTransfer(_tranche);
    }

    /**
     * @notice Allows a user to claim excess and/or withdraw the investment from the product
     * @param _tranche The tranche id from which the excess should be claimed or the investment withdrawn
     */
    function claimExcessAndWithdraw(DataTypes.Tranche _tranche) external override nonReentrant gacPausable {
        require(currentState != DataTypes.State.OPEN, Errors.VE_INVALID_STATE);
        bool hasExcessOrWithdrawal;
        (uint256 _userInvested, uint256 _excess) =
            Helpers.getInvestedAndExcess(investors[_tranche][_msgSender()], trancheInfo[_tranche].tokensInvestable);

        if (_excess > 0 && !investors[_tranche][_msgSender()].claimed) {
            _claimExcess(_tranche, _userInvested, _excess);
            hasExcessOrWithdrawal = true;
        }

        if (
            spToken.balanceOf(_msgSender(), trancheConfig[_tranche].spTokenId) > 0
                && currentState == DataTypes.State.WITHDRAWN
        ) {
            _calculateUserShareAndTransfer(_tranche);
            hasExcessOrWithdrawal = true;
        }
        require(hasExcessOrWithdrawal, Errors.VE_NO_WITHDRAW_OR_EXCESS);
    }

    /**
     * @notice Used to update the slippage
     * @param _newSlippage The new slippage value to be updated
     */
    function setSlippage(uint256 _newSlippage) external onlyRole(GOVERNANCE) {
        require(_newSlippage < Constants.MAX_SLIPPAGE, Errors.VE_INVALID_SLIPPAGE);
        slippage = _newSlippage;
    }

    /**
     * @notice Used to withdraw any funds thats left in the contract
     * @dev It can be called only by the Governance, after 3 weeks from the tranche end time.
     * @param _token The address of the token to be withdrawn
     * @param _recipient The address of the recipient who receives the tokens
     */
    function rescueTokens(IERC20Metadata _token, address _recipient) external onlyRole(GOVERNANCE) {
        require(block.timestamp >= productConfig.endTimeTranche + 3 weeks, Errors.VE_CANNOT_WITHDRAW_YET);
        _token.safeTransfer(_recipient, Helpers._getTokenBalance(_token, address(this)));
    }

    /**
     * @notice used to find the user investment and excess for the given tranche if any
     * @param _tranche id of the senior/junior tranche
     * @param _investor address of the investor
     * @return userInvested - the share of the user invested that accounts for total investment to the pool
     * @return excess - the share of the user's deposit that was not invested into the pool
     */
    function getUserInvestmentAndExcess(DataTypes.Tranche _tranche, address _investor)
        external
        view
        override
        returns (uint256, uint256)
    {
        if (currentState == DataTypes.State.OPEN) {
            return (0, 0);
        }
        (uint256 userInvested, uint256 excess) =
            Helpers.getInvestedAndExcess(investors[_tranche][_investor], trancheInfo[_tranche].tokensInvestable);

        return (userInvested, excess);
    }

    /**
     * @notice Used to get the total amount of tokens deposited by the user into a given tranche
     * @param _tranche id of the senior/junior tranche
     * @param _investor address of the investor
     * @return userDeposited the total amount of tokens deposited by the user into a given tranche
     */
    function getUserTotalDeposited(DataTypes.Tranche _tranche, address _investor) external view returns (uint256) {
        uint256 length = investors[_tranche][_investor].userSums.length;
        return investors[_tranche][_investor].userSums[length - 1];
    }

    /**
     * @notice Used to get the details of the investor for the given tranche
     * @param _tranche ID of the tranche
     * @param _user Address of the user
     * @return The investor info
     */
    function getInvestorDetails(DataTypes.Tranche _tranche, address _user)
        external
        view
        override
        returns (DataTypes.Investor memory)
    {
        return investors[_tranche][_user];
    }

    /**
     * @notice Used to get the current status of the Product
     * @return The current state of the product
     */
    function getCurrentState() external view override returns (DataTypes.State) {
        return currentState;
    }

    /**
     * @notice Used to get the details of the given tranche
     * @param _tranche ID of the tranche
     * @return Tranche info for the given tranche
     */
    function getTrancheInfo(DataTypes.Tranche _tranche) external view override returns (DataTypes.TrancheInfo memory) {
        return trancheInfo[_tranche];
    }

    /**
     * @notice Used to get the config of the given tranche
     * @param _tranche ID of the tranche
     * @return Tranche config for the given tranche
     */
    function getTrancheConfig(DataTypes.Tranche _tranche)
        external
        view
        override
        returns (DataTypes.TrancheConfig memory)
    {
        return trancheConfig[_tranche];
    }

    /**
     * @notice Used to get the configuration of the product
     */
    function getProductConfig() external view returns (DataTypes.ProductConfig memory) {
        return productConfig;
    }

    /**
     * @notice Returns the rate of the tranche token
     * @param _tranche The tranche id for which the token rate should be fetched.
     * @return uint256 - GMX rate of the given _tranche token against the other tranche token
     */
    function getTokenRate(DataTypes.Tranche _tranche) public view returns (uint256) {
        (bool _isPriceValidSr, uint256 _priceTokenSr) =
            _getTokenPrice(address(trancheConfig[DataTypes.Tranche.Senior].tokenAddress));
        require(_isPriceValidSr, Errors.PFE_INVALID_SR_PRICE);
        _priceTokenSr = _priceTokenSr / Constants.GMX_PRICE_DIVISOR;

        (bool _isPriceValidJr, uint256 _priceTokenJr) =
            _getTokenPrice(address(trancheConfig[DataTypes.Tranche.Junior].tokenAddress));
        require(_isPriceValidJr, Errors.PFE_INVALID_JR_PRICE);
        _priceTokenJr = _priceTokenJr / Constants.GMX_PRICE_DIVISOR;

        if (_tranche == DataTypes.Tranche.Senior) {
            return _priceTokenSr.mulDiv(Constants.WAD, _priceTokenJr);
        } else {
            return _priceTokenJr.mulDiv(Constants.WAD, _priceTokenSr);
        }
    }

    function _getTokenPrice(address _token) private view returns (bool, uint256) {
        bool _isPriceValid = true;
        uint256 _fastPrice = FAST_PRICE_FEED.prices(_token);
        uint256 _primaryPrice = VAULT_PRICE_FEED.getLatestPrimaryPrice(_token);
        // Chainlink price is in 8 decimals while _fastPrice is 30 decimals
        uint256 _priceDecimals = VAULT_PRICE_FEED.priceDecimals(_token);
        _primaryPrice = _primaryPrice * 10 ** (30 - _priceDecimals);
        /// _fastPrice does not exist for USDC
        if (_fastPrice == 0) {
            /// check that the the fast price feed does not have a price for this token
            (, uint256 _lastUpdateTime,,) = FAST_PRICE_FEED.getPriceData(_token);
            if (_lastUpdateTime != 0) {
                _isPriceValid = false;
            }
            return (_isPriceValid, _primaryPrice);
        }
        /// check that the price deviation is within the allowed range
        uint256 _diffBasisPoints;
        /// set _priceDivisor to the larger of the two prices
        uint256 _priceDivisor;
        if (_primaryPrice > _fastPrice) {
            _diffBasisPoints = _primaryPrice - _fastPrice;
            _priceDivisor = _primaryPrice;
        } else {
            _diffBasisPoints = _fastPrice - _primaryPrice;
            _priceDivisor = _fastPrice;
        }

        _diffBasisPoints = _diffBasisPoints.mulDiv(BASIS_POINTS_DIVISOR, _priceDivisor);
        if (_diffBasisPoints > Constants.MAX_DEVIATION / 100) {
            _isPriceValid = false;
        }

        return (_isPriceValid, _primaryPrice);
    }

    /**
     * @notice Deposits the `_amount` to the given `tranche`
     * @param _tranche Senior/Junior Tranche
     * @param _amount The Amount of tokens to be deposited
     * @param _investor The Address under which the deposit has to be recorded
     */
    function _deposit(DataTypes.Tranche _tranche, uint256 _amount, address _investor) internal {
        Validation.validateDeposit(
            productConfig.startTimeTranche,
            trancheConfig[_tranche].capacity,
            productConfig.startTimeDeposit,
            trancheInfo[_tranche].tokensDeposited,
            _amount,
            trancheConfig[_tranche].decimals
        );
        if (msg.value != 0) {
            require(
                address(trancheConfig[_tranche].tokenAddress) == nativeToken, Errors.VE_INVALID_NATIVE_TOKEN_DEPOSIT
            );
            Helpers._wrapAVAXForDeposit(_amount, nativeToken);
            investors[_tranche][_investor].depositedNative = true;
        }
        uint256 _totalDeposited = Helpers._depositToTranche(
            trancheInfo[_tranche],
            trancheConfig[_tranche],
            _amount,
            _investor,
            _msgSender(),
            spToken,
            investors[_tranche][_investor]
        );
        emit Deposited(_tranche, _amount, _investor, _totalDeposited);
    }

    /**
     * @notice Adds liquidity to the AMM pool
     * @param _tokensInvestableSr Senior tokens eligible for investment to the pool
     * @param _tokensInvestableJr Junior tokens eligible for investment to the pool
     * @return _seniorTokensSupplied Senior tranche tokens invested
     * @return _juniorTokensSupplied Junior tranche tokens invested
     */
    function _depositToLP(uint256 _tokensInvestableSr, uint256 _tokensInvestableJr)
        private
        returns (uint256 _seniorTokensSupplied, uint256 _juniorTokensSupplied)
    {
        currentState = DataTypes.State.INVESTED;
        emit StatusUpdated(DataTypes.State.INVESTED);

        uint256 _tokensInvestableSrInTokenDecimals = Helpers.weiToTokenDecimals(_srDecimals, _tokensInvestableSr);
        uint256 _tokensInvestableJrInTokenDecimals = Helpers.weiToTokenDecimals(_jrDecimals, _tokensInvestableJr);

        /// Increase allowance
        trancheConfig[DataTypes.Tranche.Senior].tokenAddress.safeIncreaseAllowance(
            address(yieldSource), _tokensInvestableSrInTokenDecimals
        );
        trancheConfig[DataTypes.Tranche.Junior].tokenAddress.safeIncreaseAllowance(
            address(yieldSource), _tokensInvestableJrInTokenDecimals
        );
        (_seniorTokensSupplied, _juniorTokensSupplied) =
            yieldSource.supplyTokens(_tokensInvestableSrInTokenDecimals, _tokensInvestableJrInTokenDecimals);
    }

    /**
     * @notice Method withdraws the product's investments from the LP and charges and sends fees to the Distribution Manager.
     */
    function removeFundsFromLP() external override nonReentrant gacPausable {
        Validation.validateRemoveFunds(productConfig.endTimeTranche, currentState);

        currentState = DataTypes.State.WITHDRAWN;

        uint256 _trancheDuration = productConfig.endTimeTranche - productConfig.startTimeTranche;

        /// Calculate the amount of senior tokens the senior tranche investors expect at maturity
        /// The simplified formula is: (tokensInvestable * (1 + fixedRate * trancheDuration / 1 year))
        uint256 _srFrFactor = (
            trancheInfo[DataTypes.Tranche.Senior].tokensInvestable * Constants.YEAR_IN_SECONDS
                + trancheInfo[DataTypes.Tranche.Senior].tokensInvestable * productConfig.fixedRate * _trancheDuration
                    / Constants.DECIMAL_FACTOR
        ) / Constants.YEAR_IN_SECONDS;

        /// pass the srFrFactor to the yieldSource to calculate the amount of tokens to redeem for each tranche
        /// unlike TJ product contract, the GMX product contract allocates the tokens to the tranches during redemption
        (uint256 _receivedSr, uint256 _receivedJr) = yieldSource.redeemTokens(_srFrFactor);

        _receivedSr = Helpers.tokenDecimalsToWei(_srDecimals, _receivedSr);
        _receivedJr = Helpers.tokenDecimalsToWei(_jrDecimals, _receivedJr);

        trancheInfo[DataTypes.Tranche.Senior].tokensReceivedFromLP = _receivedSr;
        trancheInfo[DataTypes.Tranche.Junior].tokensReceivedFromLP = _receivedJr;

        _chargeFee(_receivedSr, _receivedJr);

        /// Capture tokens at maturity
        trancheInfo[DataTypes.Tranche.Senior].tokensAtMaturity = _receivedSr - feeTotalSr;
        trancheInfo[DataTypes.Tranche.Junior].tokensAtMaturity = _receivedJr - feeTotalJr;

        emit StatusUpdated(DataTypes.State.WITHDRAWN);

        emit RemovedFundsFromLP(
            trancheInfo[DataTypes.Tranche.Senior].tokensAtMaturity,
            trancheInfo[DataTypes.Tranche.Junior].tokensAtMaturity,
            _msgSender()
        );
    }

    /**
     * @notice Used to transfer fee when the product is matured
     * @param _receivedSr Senior tokens received from pool
     * @param _receivedJr Junior tokens received from pool
     */
    function _chargeFee(uint256 _receivedSr, uint256 _receivedJr) private {
        DataTypes.TrancheInfo storage _trancheInfoSr = trancheInfo[DataTypes.Tranche.Senior];
        DataTypes.TrancheInfo storage _trancheInfoJr = trancheInfo[DataTypes.Tranche.Junior];

        (feeTotalSr, feeTotalJr) = Helpers.calculateFees(
            _trancheInfoSr.tokensInvestable, _receivedSr, _trancheInfoJr.tokensInvestable, _receivedJr, productConfig
        );
        if (feeTotalSr > 0 || feeTotalJr > 0) {
            /// Get nativeToken balance of receiver before sending it fees
            uint256 _receiverNativeBalanceBefore =
                Helpers._getTokenBalance(IERC20Metadata(nativeToken), address(distributionManager));

            Helpers.swapAndSendFeeToReceiver(
                joeRouter, feeTotalSr, feeTotalJr, seniorToNative, juniorToNative, address(distributionManager)
            );

            /// Get nativeToken balance of receiver after sending it fees
            uint256 _receiverNativeBalanceAfter =
                Helpers._getTokenBalance(IERC20Metadata(nativeToken), address(distributionManager));
            /// Set the difference as the _feeToQueue
            uint256 _feeToQueue = _receiverNativeBalanceAfter - _receiverNativeBalanceBefore;

            distributionManager.queueFees(_feeToQueue);
        }
    }

    /**
     * @notice Calculate the user share from the matured tranche token and transfer to them.
     * @param _tranche The tranche id (senior/junior)
     */
    function _calculateUserShareAndTransfer(DataTypes.Tranche _tranche) internal {
        DataTypes.TrancheInfo storage _trancheInfo = trancheInfo[_tranche];
        DataTypes.TrancheConfig storage _trancheConfig = trancheConfig[_tranche];
        uint256 _userSpTokenBalance = spToken.balanceOf(_msgSender(), _trancheConfig.spTokenId);
        uint256 _userShare = (_trancheInfo.tokensAtMaturity * _userSpTokenBalance) / _trancheInfo.tokensInvestable;

        spToken.burn(_msgSender(), _trancheConfig.spTokenId, _userSpTokenBalance);
        _transferTokens(_trancheConfig, _tranche, _userShare);

        emit Withdrawn(_tranche, _userShare, _msgSender());
    }

    /**
     * @notice Allows users to claim any excess tokens, and returns their corresponding amount of tokens in return for their SP tokens.
     * @param _tranche The tranche id (senior/junior)
     * @param _userInvested The amount the user has invested
     * @param _excess The excess amount the user can claim
     */
    function _claimExcess(DataTypes.Tranche _tranche, uint256 _userInvested, uint256 _excess) private {
        DataTypes.TrancheConfig storage _trancheConfig = trancheConfig[_tranche];

        trancheInfo[_tranche].tokensExcess -= _excess;
        investors[_tranche][_msgSender()].claimed = true;
        spToken.burn(_msgSender(), _trancheConfig.spTokenId, _excess);
        _transferTokens(_trancheConfig, _tranche, _excess);

        emit ExcessClaimed(_tranche, _trancheConfig.spTokenId, _userInvested, _excess, _msgSender());
    }

    /**
     * @notice Transfers either ERC20 or native token to the depositor
     * @param _trancheConfig the configuration of the tranche
     * @param _tranche The tranche id (senior/junior)
     * @param _amount The amount to transfer to the user
     */
    function _transferTokens(
        DataTypes.TrancheConfig storage _trancheConfig,
        DataTypes.Tranche _tranche,
        uint256 _amount
    ) private {
        // if user deposited AVAX to product, unwrap wAVAX and transfer AVAX
        if (investors[_tranche][_msgSender()].depositedNative) {
            IWETH9(nativeToken).withdraw(_amount);
            (bool sent,) = _msgSender().call{value: _amount}("");
            require(sent, Errors.AVAX_TRANSFER_FAILED);
        } else {
            _trancheConfig.tokenAddress.safeTransfer(
                _msgSender(), Helpers.weiToTokenDecimals(_trancheConfig.decimals, _amount)
            );
        }
    }

    /// @notice To receive native token transfers
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.11;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

interface IGMXVault {
    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function whitelistedTokens(address _token) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IFastPriceFeed {
    function prices(address _token) external view returns (uint256);

    function maxCumulativeDeltaDiffs(address _token) external view returns (uint256);

    function getPriceData(address _token) external view returns (uint256, uint256, uint256, uint256);

    function lastUpdatedAt() external view returns (uint256);

    function lastUpdatedBlock() external view returns (uint256);

    function setSigner(address _account, bool _isActive) external;

    function setUpdater(address _account, bool _isActive) external;

    function setPriceDuration(uint256 _priceDuration) external;

    function setMaxPriceUpdateDelay(uint256 _maxPriceUpdateDelay) external;

    function setSpreadBasisPointsIfInactive(uint256 _spreadBasisPointsIfInactive) external;

    function setSpreadBasisPointsIfChainError(uint256 _spreadBasisPointsIfChainError) external;

    function setMinBlockInterval(uint256 _minBlockInterval) external;

    function setIsSpreadEnabled(bool _isSpreadEnabled) external;

    function setMaxDeviationBasisPoints(uint256 _maxDeviationBasisPoints) external;

    function setMaxCumulativeDeltaDiffs(address[] memory _tokens, uint256[] memory _maxCumulativeDeltaDiffs) external;

    function setPriceDataInterval(uint256 _priceDataInterval) external;

    function setVaultPriceFeed(address _vaultPriceFeed) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IVaultPriceFeed {
    function priceDecimals(address _token) external view returns (uint256);

    function adjustmentBasisPoints(address _token) external view returns (uint256);

    function isAdjustmentAdditive(address _token) external view returns (bool);

    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;

    function setUseV2Pricing(bool _useV2Pricing) external;

    function setIsAmmEnabled(bool _isEnabled) external;

    function setIsSecondaryPriceEnabled(bool _isEnabled) external;

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;

    function setPriceSampleSpace(uint256 _priceSampleSpace) external;

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;

    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing)
        external
        view
        returns (uint256);

    function getAmmPrice(address _token) external view returns (uint256);

    function getLatestPrimaryPrice(address _token) external view returns (uint256);

    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);

    function setTokenConfig(address _token, address _priceFeed, uint256 _priceDecimals, bool _isStrictStable)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// @notice Gas & bytecode optimized reentrancy protection for smart contracts.
/// @author Struct Finance
/// @author Modified from Solmate to make it compatible with OZ Clones (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract CustomReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        _nonReentrant();
        _;

        reentrancyStatus = 1;
    }

    function _nonReentrant() private {
        require(reentrancyStatus < 2, "REENTRANCY");

        reentrancyStatus = 2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// External Imports
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Internal Imports
import {IJoeRouter} from "../../external/traderjoe/IJoeRouter.sol";
import {IJoeFactory} from "../../external/traderjoe/IJoeFactory.sol";
import {IMasterChef} from "../../external/traderjoe/IMasterChef.sol";

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Helpers} from "../libraries/helpers/Helpers.sol";
import {Constants} from "../libraries/helpers/Constants.sol";

/**
 * @title TraderJoeLpAdapter
 * @notice Implements the logic for interacting with the Liquidity pools of TraderJoe
 *
 * @author Struct Finance
 *
 */
abstract contract TraderJoeLPAdapter {
    using SafeERC20 for IERC20Metadata;

    /// @dev The slippage amount
    uint256 public slippage;

    /// @dev Address of the Senior tranche token
    IERC20Metadata public trancheTokenSr;

    /// @dev Address of the Junior tranche token
    IERC20Metadata public trancheTokenJr;

    /// @dev Address of the JoeRouter contract
    IJoeRouter public immutable joeRouter = IJoeRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

    /// @dev Address of the MasterChef contract
    IMasterChef public immutable masterChef = IMasterChef(0x4483f0b6e2F5486D06958C20f8C39A7aBe87bf8F);

    /*////////////////////////////////////////////////////////////*/
    /*                      INTERNAL METHODS                      */
    /*////////////////////////////////////////////////////////////*/

    /**
     * @notice Used to swap tokens
     * @param amtIn Amount in
     * @param amtOutMin Minimum amount expected
     * @param _path The swap path
     * @return _amtTokensReceived Tokens received after swap
     */
    function _swapExact(uint256 amtIn, uint256 amtOutMin, address[] memory _path)
        internal
        returns (uint256 _amtTokensReceived)
    {
        uint256 _amtIn = (amtIn * 10 ** IERC20Metadata(_path[0]).decimals()) / Constants.WAD;
        uint256 _amtOutMin = (amtOutMin * 10 ** IERC20Metadata(_path[_path.length - 1]).decimals()) / Constants.WAD;
        IERC20Metadata(_path[0]).safeIncreaseAllowance(address(joeRouter), amtIn);
        _amtTokensReceived = joeRouter.swapExactTokensForTokens(
            _amtIn, _amtOutMin, _path, address(this), block.timestamp
        )[_path.length - 1];
    }

    /*////////////////////////////////////////////////////////////*/
    /*                           VIEWS                            */
    /*////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the LP Token address of the given pair
     * @return _lpTokenAddress Address of the LP token
     */
    function _getLpToken() private view returns (address _lpTokenAddress) {
        _lpTokenAddress = IJoeFactory(joeRouter.factory()).getPair(address(trancheTokenSr), address(trancheTokenJr));
    }

    function getLpToken() public view returns (address) {
        return _getLpToken();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// External imports
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ISPToken is IERC1155 {
    /// @notice mints the given erc1155 token id to the given address
    /// @param to the recipient of the token
    /// @param id the id of the ERC1155 token to be minted
    /// @param amount amount of tokens to be minted
    /// @param data optional field to execute other methods after tokens are minted
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    /// @notice burns the erc1155 tokens
    /// @param from the address of the token owner
    /// @param id the id of the token to be burnt
    /// @param amount the amount of tokens to be burnt
    function burn(address from, uint256 id, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// Internal Imports
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import "./ISPToken.sol";
import "./IDistributionManager.sol";
import "./IGAC.sol";

import "./IStructPriceOracle.sol";

/**
 * @title The Interim GMX FEYProduct Interface
 * @author Struct Finance
 * @dev This is a temporary interface while we add functionality to the GMX product contract
 * @dev Once the contract is finished, we will use IFEYProduct
 *
 */
interface IGMXFEYProduct {
    /// @dev Emitted the total amount deposited and the user address whenever deposited to a tranche
    event Deposited(
        DataTypes.Tranche _tranche,
        uint256 _trancheDepositedAmount,
        address indexed _user,
        uint256 _trancheDepositedTotal
    );

    /// @dev Emitted the total amount of senior and junior tokens at maturity along with the fee
    event RemovedFundsFromLP(uint256 _srTokensReceived, uint256 _jrTokensReceived, address indexed _user);

    /// @dev Emitted when the product invests the funds to the liquidity pool
    event Invested(
        uint256 _trancheTokensInvestedSenior,
        uint256 _trancheTokensInvestedJunior,
        uint256 _trancheTokensInvestableSenior,
        uint256 _trancheTokensInvestableJunior
    );

    /// @dev Emitted when the performance fee is sent to the feeReceiver
    event PerformanceFeeSent(DataTypes.Tranche _tranche, uint256 _tokensSent);

    /// @dev Emitted when the management fee is sent to the feeReceiver
    event ManagementFeeSent(DataTypes.Tranche _tranche, uint256 _tokensSent);

    /// @dev Emitted when there is a status update
    event StatusUpdated(DataTypes.State status);

    /// @dev Emitted when the tranche is created
    event TrancheCreated(DataTypes.Tranche trancheType, address indexed tokenAddress, uint256 trancheCapacityMax);

    /// @dev Emitted when the user claims the excess tokens
    event ExcessClaimed(
        DataTypes.Tranche _tranche,
        uint256 _spTokenId,
        uint256 _userInvested,
        uint256 _excessAmount,
        address indexed _user
    );

    /// @dev Emitted when the user withdraws from the pool
    event Withdrawn(DataTypes.Tranche _tranche, uint256 _amount, address indexed _user);

    function initialize(
        DataTypes.InitConfigParam memory _initConfig,
        IStructPriceOracle _structPriceOracle,
        ISPToken _spToken,
        IGAC _globalAccessControl,
        IDistributionManager _distributionManager,
        address _yieldSource,
        address payable _nativeToken
    ) external;

    function deposit(DataTypes.Tranche _tranche, uint256 _amount) external payable;

    function depositFor(DataTypes.Tranche _tranche, uint256 _amount, address _onBehalfOf) external payable;

    function invest() external;

    function removeFundsFromLP() external;

    function claimExcessAndWithdraw(DataTypes.Tranche _tranche) external;

    function claimExcess(DataTypes.Tranche _tranche) external;

    function withdraw(DataTypes.Tranche _tranche) external;

    function getProductConfig() external view returns (DataTypes.ProductConfig memory);

    function getTrancheConfig(DataTypes.Tranche _tranche) external view returns (DataTypes.TrancheConfig memory);

    function getTrancheInfo(DataTypes.Tranche _tranche) external view returns (DataTypes.TrancheInfo memory);

    function getUserInvestmentAndExcess(DataTypes.Tranche _tranche, address _invested)
        external
        view
        returns (uint256, uint256);

    function getUserTotalDeposited(DataTypes.Tranche _tranche, address _investor) external view returns (uint256);

    function getCurrentState() external view returns (DataTypes.State);

    function getInvestorDetails(DataTypes.Tranche _tranche, address _user)
        external
        view
        returns (DataTypes.Investor memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @title The StructPriceOracle interface
 * @notice Interface for the Struct price oracle.
 *
 */
interface IStructPriceOracle {
    ///@dev returns the asset price in USD
    ///@param asset the address of the asset
    ///@return the USD price of the asset
    function getAssetPrice(address asset) external view returns (uint256);

    ///@dev returns the asset prices in USD
    ///@param assets the addresses array of the assets
    ///@return the USD prices of the asset
    function getAssetsPrices(address[] memory assets) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IDistributionManager {
    struct RecipientData {
        address destination;
        uint256 allocationPoints;
        uint256 allocationFee;
    }

    function queueFees(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// External Imports
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// Internal Imports
import "../../../external/traderjoe/IJoeRouter.sol";
import "../../../external/traderjoe/IJoePair.sol";
import "../../../external/traderjoe/IMasterChef.sol";

library DataTypes {
    /// @notice It contains the details of the tranche
    struct TrancheInfo {
        /// Actual deposits of the users (aggregate) that are being queued
        uint256 tokensDeposited;
        /// Number of tokens that are eligible for investment into a pool per tranche
        uint256 tokensInvestable;
        /// Tokens that cannot be tokensInvested
        uint256 tokensExcess;
        /// Tokens invested into AMM
        uint256 tokensInvested;
        /// Tracks the tokens available on maturity
        uint256 tokensAtMaturity;
        /// Tracks the tokens received from the AMM's liquidity pool
        uint256 tokensReceivedFromLP;
    }

    /// @notice It contains the configuration of the tranche
    /// @dev It is populated during product creation
    struct TrancheConfig {
        /// Contract address of the tranche token
        IERC20Metadata tokenAddress;
        /// Tranche Token decimals
        uint256 decimals;
        /// Token ID of StructSP tokens for the tranche
        uint256 spTokenId;
        /// Maximum tokens that can be deposited
        uint256 capacity;
    }

    /// @notice It contains the general configuration of the product
    /// @dev It is populated during product creation
    struct ProductConfig {
        /// ID of the pool (for recompunding)
        uint256 poolId;
        /// Interest rate
        uint256 fixedRate;
        /// The timestamp after which users can deposit tokens into the tranches.
        uint256 startTimeDeposit;
        /// The start timestamp of the tranche.
        uint256 startTimeTranche;
        /// The end timestamp of the tranche (Maturity).
        uint256 endTimeTranche;
        ///  The minimum ratio required for deposit to be tokensInvested
        uint256 leverageThresholdMin;
        ///  The maximum ratio required for deposit to be tokensInvested
        uint256 leverageThresholdMax;
        /// The management fee %
        uint256 managementFee;
        /// The performance fee %
        uint256 performanceFee;
    }

    /// @notice It contains the properties of the product configuration set by the user
    /// @dev The properties are reassigned to ProductConfig during product creation
    struct ProductConfigUserInput {
        /// Interest rate
        uint256 fixedRate;
        /// The start timestamp of the tranche.
        uint256 startTimeTranche;
        /// The end timestamp of the tranche (Maturity).
        uint256 endTimeTranche;
        ///  The minimum ratio required for deposit to be tokensInvested
        uint256 leverageThresholdMin;
        ///  The maximum ratio required for deposit to be tokensInvested
        uint256 leverageThresholdMax;
    }

    /**
     * @notice
     *  OPEN - Product contract has been created, and still open for deposits
     *  INVESTED - Funds has been deposited into LP
     *  WITHDRAWN -  Funds have been withdrawn from LP
     */
    enum State {
        OPEN,
        INVESTED,
        WITHDRAWN
    }

    enum Tranche {
        Senior,
        Junior
    }

    /// @notice Struct used to store the details of the investor
    /// @dev Inspired by Ondo Finance
    struct Investor {
        uint256[] userSums;
        uint256[] depositSums;
        uint256 spTokensStaked;
        bool claimed;
        bool depositedNative;
    }

    /// @notice Struct of arrays containing all the routes for swap
    struct SwapPath {
        address[] seniorToJunior;
        address[] juniorToSenior;
        address[] nativeToSenior;
        address[] nativeToJunior;
        address[] seniorToNative;
        address[] juniorToNative;
        address[] reward1ToNative;
        address[] reward2ToNative;
    }

    /// @notice It contains all the contract addresses for interaction
    struct Addresses {
        IERC20Metadata nativeToken;
        IERC20Metadata reward1;
        IERC20Metadata reward2;
        IJoePair lpToken;
        IMasterChef masterChef;
        IJoeRouter router;
    }

    // amount: amount of Struct tokens that are currently locked
    // end: epoch time that the lock expires (doesn't seem to be in epoch units, but the time of the final epoch)
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    // Contains tranche config to prevent stack too deep
    struct InitConfigParam {
        DataTypes.TrancheConfig configTrancheSr;
        DataTypes.TrancheConfig configTrancheJr;
        DataTypes.ProductConfig productConfig;
    }

    /// @notice The struct contains the product info for the FEYGMXProducts
    /// @custom: tokenA Address of the tokenA
    /// @custom: tokenB Address of tokenB
    /// @custom: tokenADecimals Decimals of tokenA
    /// @custom: tokenBDecimals Decimals of tokenB
    /// @custom: fsGLPReceived The amount of fsGLPReceived
    /// @custom: shares The shares of the product
    /// @custom: sameToken Whether the tokens are the same
    struct FEYGMXProductInfo {
        address tokenA;
        uint8 tokenADecimals;
        address tokenB;
        uint8 tokenBDecimals;
        uint256 fsGLPReceived;
        uint256 shares;
        bool sameToken;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// External Imports
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Internal Imports
import {IJoeRouter} from "../../../external/traderjoe/IJoeRouter.sol";
import {IWETH9} from "../../../external/IWETH9.sol";

import {IStructPriceOracle} from "../../../interfaces/IStructPriceOracle.sol";
import {ISPToken} from "../../../interfaces/ISPToken.sol";

import {DataTypes} from "../types/DataTypes.sol";
import {Constants} from "./Constants.sol";
import {Errors} from "./Errors.sol";
import {JoeLibrary} from "./JoeLibraryModified.sol";

/**
 * @title Helpers library
 * @notice Collection of helper functions
 * @author Struct Finance
 */
library Helpers {
    using Arrays for uint256[];
    using SafeERC20 for IERC20Metadata;

    /// @dev Emits when the performance fee is sent to the feeReceiver
    event PerformanceFeeSent(DataTypes.Tranche _tranche, uint256 _tokensSent);

    /// @dev Emits when the management fee is sent to the feeReceiver
    event ManagementFeeSent(DataTypes.Tranche _tranche, uint256 _tokensSent);

    /// @dev Emits the total fees charged for each tranche
    event FeeCharged(uint256 feeTotalSr, uint256 feeTotalJr);

    /**
     * @dev Given the total amount invested, we want to find
     *   out how many of this investor's deposits were actually
     *   used. Use findUpperBound on the prefixSum to find the point
     *   where total deposits were accepted. For example, if $2000 was
     *   deposited by all investors and $1000 was invested, then some
     *   position in the prefixSum splits the array into deposits that
     *   got in, and deposits that didn't get in. That same position
     *   maps to userSums. This is the user's deposits that got
     *   in. Since we are keeping track of the sums, we know at that
     *   position the total deposits for a user was $15, even if it was
     *   15 $1 deposits. And we know the amount that didn't get in is
     *   the last value in userSum - the amount that got it.
     *
     * @param investor A specific investor
     * @param invested The total amount invested
     */
    function getInvestedAndExcess(DataTypes.Investor storage investor, uint256 invested)
        external
        view
        returns (uint256 userInvested, uint256 excess)
    {
        uint256[] storage prefixSums_ = investor.depositSums;
        uint256 length = prefixSums_.length;
        if (length == 0) {
            // There were no deposits. Return 0, 0.
            return (userInvested, excess);
        }
        uint256 leastUpperBound = prefixSums_.findUpperBound(invested);
        if (length == leastUpperBound) {
            // All deposits got in, no excess. Return total deposits, 0
            userInvested = investor.userSums[length - 1];
            return (userInvested, excess);
        }
        uint256 prefixSum = prefixSums_[leastUpperBound];
        if (prefixSum == invested) {
            // Not all deposits got in, but there are no partial deposits
            userInvested = investor.userSums[leastUpperBound];
        } else {
            // Let's say some of my deposits got in. The last deposit,
            // however, was $100 and only $30 got in. Need to split that
            // deposit so $30 got in, $70 is excess.
            userInvested = leastUpperBound > 0 ? investor.userSums[leastUpperBound - 1] : 0;
            uint256 depositAmount = investor.userSums[leastUpperBound] - userInvested;
            if (prefixSum - depositAmount < invested) {
                userInvested += (depositAmount + invested - prefixSum);
                excess = investor.userSums[length - 1] - userInvested;
            }
        }
        excess = investor.userSums[length - 1] - userInvested;
    }

    /**
     * @notice This methods calculates the relative percentage difference.
     * @param _rate1 Rate from the AMM
     * @param _rate2 Rate from the Chainlink price feed
     * @return A flag that states whether the given rates lies within the `MAX_DEVIATION`
     */
    function _isWithinBound(uint256 _rate1, uint256 _rate2) private pure returns (bool) {
        uint256 _relativeChangePct;
        if (_rate1 > _rate2) {
            _relativeChangePct = ((_rate1 - _rate2) * Constants.DECIMAL_FACTOR * Constants.WAD) / _rate2;
        } else {
            _relativeChangePct = ((_rate2 - _rate1) * Constants.DECIMAL_FACTOR * Constants.WAD) / _rate1;
        }
        return _relativeChangePct <= Constants.MAX_DEVIATION * Constants.WAD ? true : false;
    }

    /**
     * @notice Used to calculate fees to be sent to the receiver once the funds are withdrawn from LP
     * @param _tokensInvestableSr The total amount of Senior tranche tokens that were eligible for investment
     * @param _tokensAtMaturitySr The total amount of Senior tranche tokens withdrawn after maturity
     * @param _tokensInvestableJr The total amount of Junior tranche tokens that were eligible for investment
     * @param _tokensAtMaturityJr The total amount of Junior tranche tokens withdrawn after maturity
     * @param _productConfig The configuration/specs of the product
     * @return _srFeeTotal The total fee charged as senior tranche tokens
     * @return _jrFeeTotal The total fee charged as junior tranche tokens
     */
    function calculateFees(
        uint256 _tokensInvestableSr,
        uint256 _tokensAtMaturitySr,
        uint256 _tokensInvestableJr,
        uint256 _tokensAtMaturityJr,
        DataTypes.ProductConfig storage _productConfig
    ) external returns (uint256, uint256) {
        uint256 feeTotalJr;
        uint256 feeTotalSr;

        /// Performance Fee
        if (_productConfig.performanceFee > 0) {
            if (_tokensAtMaturitySr > _tokensInvestableSr) {
                uint256 _srPerfFee = (_productConfig.performanceFee * (_tokensAtMaturitySr - _tokensInvestableSr))
                    / Constants.DECIMAL_FACTOR;
                feeTotalSr += _srPerfFee;
                emit PerformanceFeeSent(DataTypes.Tranche.Senior, _srPerfFee);
            }

            if (_tokensAtMaturityJr > _tokensInvestableJr) {
                uint256 _jrPerfFee = (_productConfig.performanceFee * (_tokensAtMaturityJr - _tokensInvestableJr))
                    / Constants.DECIMAL_FACTOR;
                feeTotalJr += _jrPerfFee;
                emit PerformanceFeeSent(DataTypes.Tranche.Junior, _jrPerfFee);
            }
        }

        emit FeeCharged(feeTotalSr, feeTotalJr);
        return (feeTotalSr, feeTotalJr);
    }

    /**
     * @dev Sends the specified % of the fee to the recipient
     * @param _joeRouter Interface for the joeRouter contract
     * @param _feeTotalSr Total fees accumulated from the senior tranche
     * @param _feeTotalJr Total fees accumulated from the junior tranche
     * @param _seniorToNative Swap path array for the senior to native token
     * @param _juniorToNative Swap path array for the junior to native token
     * @param _feeReceiver Address of the fee receiver (distribution manager)
     */
    function swapAndSendFeeToReceiver(
        IJoeRouter _joeRouter,
        uint256 _feeTotalSr,
        uint256 _feeTotalJr,
        address[] calldata _seniorToNative,
        address[] calldata _juniorToNative,
        address _feeReceiver
    ) external {
        address _nativeToken = _seniorToNative[_seniorToNative.length - 1];

        if (_feeTotalSr > 0) {
            _sendReceiverFee(_joeRouter, _feeTotalSr, _seniorToNative, _feeReceiver, _nativeToken);
        }

        if (_feeTotalJr > 0) {
            _sendReceiverFee(_joeRouter, _feeTotalJr, _juniorToNative, _feeReceiver, _nativeToken);
        }
    }

    /**
     * @notice Send the receiver fee.
     * @param _joeRouter Interface for the joeRouter contract
     * @param _feeTotal Total fees accumulated by product
     * @param _path Swap path
     * @param _feeReceiver Address of the fee receiver (distribution manager)
     * @param _nativeToken Address of the native token (WAVAX)
     */
    function _sendReceiverFee(
        IJoeRouter _joeRouter,
        uint256 _feeTotal,
        address[] calldata _path,
        address _feeReceiver,
        address _nativeToken
    ) private {
        if (_path[0] == _nativeToken) {
            IERC20Metadata(_nativeToken).safeTransfer(_feeReceiver, _feeTotal);
        } else {
            uint256 _amountIn = weiToTokenDecimals(IERC20Metadata(_path[0]).decimals(), _feeTotal);
            IERC20Metadata(_path[0]).safeIncreaseAllowance(address(_joeRouter), _amountIn);
            _joeRouter.swapExactTokensForTokens(_amountIn, 0, _path, _feeReceiver, block.timestamp);
        }
    }

    /**
     * @notice Converts AVAX to wAVAX for deposit
     * @param _depositAmount The amount the user wishes to deposit in AVAX
     * @param wAVAX The address of the native tokens
     */
    function _wrapAVAXForDeposit(uint256 _depositAmount, address payable wAVAX) external {
        require(_depositAmount == msg.value, Errors.VE_INVALID_INPUT_AMOUNT);
        IWETH9(payable(address(wAVAX))).deposit{value: _depositAmount}();
    }

    /**
     * @notice Deposits the given amount of tokens to the specified tranche
     * @param _trancheInfo Tranche info struct of the tranche into which the user's funds are being deposited
     * @param _trancheConfig Tranche config struct of the tranche into which the user's funds are being deposited
     * @param _amount The deposit amount
     * @param _investorAddress The address of the depositor
     * @param spToken Address of the StructSP token
     * @param _investor The investor struct to record `userSums` and `depositSums`
     * @return _newTotal The total deposits in the tranche after the current deposit by investor
     */
    function _depositToTranche(
        DataTypes.TrancheInfo storage _trancheInfo,
        DataTypes.TrancheConfig storage _trancheConfig,
        uint256 _amount,
        address _investorAddress,
        address _callerAddress,
        ISPToken spToken,
        DataTypes.Investor storage _investor
    ) external returns (uint256) {
        if (!_investor.depositedNative) {
            uint256 tokenBalanceBefore = _trancheConfig.tokenAddress.balanceOf(address(this));
            _trancheConfig.tokenAddress.safeTransferFrom(_callerAddress, address(this), _amount);
            _amount = _trancheConfig.tokenAddress.balanceOf(address(this)) - tokenBalanceBefore;
        }

        _amount = tokenDecimalsToWei(_trancheConfig.decimals, _amount);

        uint256 _newTotal = _trancheInfo.tokensDeposited + _amount;
        _trancheInfo.tokensDeposited = _newTotal;
        if (_investor.userSums.length == 0) {
            _investor.userSums.push(_amount);
        } else {
            _investor.userSums.push(_amount + _investor.userSums[_investor.userSums.length - 1]);
        }

        _investor.depositSums.push(_newTotal);

        spToken.mint(_investorAddress, _trancheConfig.spTokenId, _amount, "0x0");

        return _newTotal;
    }

    /**
     * @notice Returns the price of the given asset
     * @param _structPriceOracle The oracle address of Struct price feed
     * @param _asset The address of the asset
     */
    function getAssetPrice(IStructPriceOracle _structPriceOracle, address _asset) public view returns (uint256) {
        return _structPriceOracle.getAssetPrice(_asset);
    }

    /**
     * @notice Validates and returns the exchange rate for the given assets from the chainlink oracle and AMM.
     * @dev This is required to prevent oracle manipulation attacks.
     * @param _structPriceOracle The oracle address of Struct price feed
     * @param _asset1 The address of the asset 1
     * @param _asset1 The address of the asset 2
     * @param _path The path to get the exchange rate from the AMM (LP)
     * @param _router The address of the AMM's Router contract
     */
    function getTrancheTokenRate(
        IStructPriceOracle _structPriceOracle,
        address _asset1,
        address _asset2,
        address[] storage _path,
        IJoeRouter _router
    ) external view returns (bool, uint256, uint256, uint256) {
        uint256 _priceAsset1 = getAssetPrice(_structPriceOracle, _asset1);
        uint256 _priceAsset2 = getAssetPrice(_structPriceOracle, _asset2);

        /// Calculate the exchange rate using the prices from StructPriceOracle (Chainlink price feed)
        uint256 _chainlinkRate = (_priceAsset1 * 10 ** 18) / _priceAsset2;

        /// Calculate the exchange rate using the Router
        uint256 _ammRate = tokenDecimalsToWei(
            IERC20Metadata(_asset2).decimals(),
            JoeLibrary.getQuote(_router.factory(), 10 ** IERC20Metadata(_asset1).decimals(), _path)[_path.length - 1]
        );

        /// Check if the relative price diff % is within the MAX_DEVIATION
        /// if yes, return the exchange rate and chainlink price along with a flag
        /// if not, return the price and rate as 0 along with false flag
        return _isWithinBound(_chainlinkRate, _ammRate)
            ? (true, _ammRate, _priceAsset1, _priceAsset2)
            : (false, 0, _priceAsset1, _priceAsset2);
    }

    /**
     * @notice Converts the passed value from `WEI` to token decimals
     * @param _decimals Number of decimals the target token has (Is dynamic)
     * @param _amount Amount that has to be converted from the current token decimals to 18 decimals
     */
    function tokenDecimalsToWei(uint256 _decimals, uint256 _amount) public pure returns (uint256) {
        return (_amount * Constants.WAD) / 10 ** _decimals;
    }

    /**
     * @notice Converts the passed value from token decimals to `WEI`
     * @param _decimals Number of decimals the target token has (Is dynamic)
     * @param _amount Amount that has to be converted from 18 decimals to the current token decimals
     */
    function weiToTokenDecimals(uint256 _decimals, uint256 _amount) public pure returns (uint256) {
        return (_amount * 10 ** _decimals) / Constants.WAD;
    }

    function _getTokenBalance(IERC20Metadata _token, address _account) internal view returns (uint256 _balance) {
        _balance = _token.balanceOf(_account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title Constants library
 *
 * @author Struct Finance
 */
library Constants {
    /// @dev All the percentage values are 6 decimals so it is used to perform the calculation.
    uint256 public constant DECIMAL_FACTOR = 10 ** 6;

    /// @dev Used in calculations
    uint256 public constant WAD = 10 ** 18;
    uint256 public constant DAYS_IN_YEAR = 365;
    uint256 public constant YEAR_IN_SECONDS = 31536000;

    ///@dev The price maximum deviation allowed between struct price oracle and the AMM
    uint256 public constant MAX_DEVIATION = 50000; //5%

    /// @dev Slippage settings
    uint256 public constant DEFAULT_SLIPPAGE = 30000; //3%
    uint256 public constant MAX_SLIPPAGE = 500000; //50%

    /// @dev GMX prices are scaled to 10**30. This is required to descale them to 10**18
    uint256 public constant GMX_PRICE_DIVISOR = 10 ** 12;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title Errors library [Inspired from AAVE ;)]
 * @notice Defines the error messages emitted by the different contracts of the Struct Finance protocol
 * @dev Error messages prefix glossary:
 *  - VE = Validation Error
 *  - PFE = Price feed Error
 *  - AE = Address Error
 *  - PE = Path Error
 *  - ACE = Access Control Error
 *
 * @author Struct Finance
 */
library Errors {
    string public constant AE_NATIVE_TOKEN = "1";
    /// "Invalid native token address"
    string public constant AE_REWARD1 = "2";
    /// "Invalid Reward 1 token address"
    string public constant AE_REWARD2 = "3";
    /// "Invalid Reward 2 token address"
    string public constant AE_ROUTER = "4";
    /// "Invalid Router token address"
    string public constant PE_SR_TO_JR_1 = "5";
    /// "Invalid Senior token address in Senior to Junior Path"
    string public constant PE_SR_TO_JR_2 = "6";
    /// "Invalid Junior token address in Senior to Junior Path"
    string public constant PE_JR_TO_SR_1 = "7";
    /// "Invalid Junior token address in Junior to Senior Path"
    string public constant PE_JR_TO_SR_2 = "8";
    /// "Invalid Senior token address in Junior to Junior Path"
    string public constant PE_NATIVE_TO_SR_1 = "9";
    /// "Invalid Native token address in Native to Senior Path"
    string public constant PE_NATIVE_TO_SR_2 = "10";
    /// "Invalid Senior token address in Native to Senior Path"
    string public constant PE_NATIVE_TO_JR_1 = "11";
    /// "Invalid Native token address in Native to Junior Path"
    string public constant PE_NATIVE_TO_JR_2 = "12"; //// "Invalid Junior token address in Native to Junior Path"
    string public constant PE_REWARD1_TO_NATIVE_1 = "13";
    /// "Invalid Reward1 token address in Reward1 to Native Path"
    string public constant PE_REWARD1_TO_NATIVE_2 = "14";
    /// "Invalid Native token address in Reward1 to Native Path"
    string public constant PE_REWARD2_TO_NATIVE_1 = "15";
    /// "Invalid Reward2 token address in Reward2 to Native Path"
    string public constant PE_REWARD2_TO_NATIVE_2 = "16";
    /// "Invalid Native token address in Reward2 to Native Path"
    string public constant VE_DEPOSITS_CLOSED = "17"; // `Deposits are closed`
    string public constant VE_DEPOSITS_NOT_STARTED = "18"; // `Deposits are not started yet`
    string public constant VE_AMOUNT_EXCEEDS_CAP = "19"; // `Trying to deposit more than the max capacity of the tranche`
    string public constant VE_INSUFFICIENT_BAL = "20"; // `Insufficient token balance`
    string public constant VE_INSUFFICIENT_ALLOWANCE = "21"; // `Insufficent token allowance`
    string public constant VE_INVALID_STATE = "22";
    /// "Invalid current state for the operation"
    string public constant VE_TRANCHE_NOT_STARTED = "23";
    /// "Tranche is not started yet to add LP"
    string public constant VE_NOT_MATURED = "24";
    /// "Tranche is not matured for removing liquidity from LP"
    string public constant PFE_INVALID_SR_PRICE = "25";
    /// "Senior tranche token price fluctuation is higher or the price is invalid"
    string public constant PFE_INVALID_JR_PRICE = "26";
    /// "Junior tranche token price fluctuation is higher or the price is invalid"
    string public constant VE_ALREADY_CLAIMED = "27";
    /// "Already claimed the excess tokens"
    string public constant VE_NO_EXCESS = "28";
    /// "No excess tokens to claim"
    string public constant ACE_INVALID_ACCESS = "29";
    /// "The caller is not allowed"
    string public constant ACE_HASH_MISMATCH = "30";
    /// "Role string and role do not match"
    string public constant ACE_GLOBAL_PAUSED = "31";
    /// "Interactions paused - protocol-level"
    string public constant ACE_LOCAL_PAUSED = "32";
    /// "Interactions paused - contract-level"
    string public constant ACE_INITIALIZER = "33";
    /// "Contract is initialized more than once"
    string public constant VE_ALREADY_WITHDRAWN = "34";
    /// "User has already withdrawn funds from the tranche"
    string public constant VE_CANNOT_WITHDRAW_YET = "35";
    /// "Cannot withdraw less than 3 weeks from tranche end time"
    string public constant VE_INVALID_LENGTH = "36";
    /// "Invalid swap path length"
    string public constant VE_NOT_CLAIMED_YET = "37";
    /// "The excess are not claimed to withdraw from tranche"
    string public constant VE_NO_FARM = "38";
    /// "There is no farm for the yield farming"

    string public constant VE_INVALID_ALLOCATION = "100";

    /// "Allocation cannot be zero"
    string public constant VE_INVALID_DISTRIBUTION_TOKEN = "101";
    /// "Invalid Struct token distribution amount"
    string public constant VE_DISTRIBUTION_NOT_STARTED = "103";
    /// "Distribution not started"
    string public constant VE_INVALID_INDEX = "105";
    /// "Invalid index"
    string public constant VE_NO_RECIPIENTS = "106";
    /// "Must have recipients to distribute to"
    string public constant VE_INVALID_REWARD_RATE = "107";
    /// "Reward rate too high"
    string public constant AE_ZERO_ADDRESS = "108";
    /// "Address cannot be a zero address"
    string public constant VE_NO_WITHDRAW_OR_EXCESS = "109";
    /// User must have an excess and/or withdrawal to claim
    string public constant VE_INVALID_DISTRIBUTION_FEE = "110";
    /// "Invalid native token distribution amount"

    string public constant VE_INVALID_TRANCHE_CAP = "200";

    /// "Invalid min capacity for the given tranche"
    string public constant VE_INVALID_STATUS = "202";
    /// "Invalid status arg. The status should be either 1 or 2"
    string public constant VE_INVALID_POOL = "203";
    /// "Pool doesn't exist"
    string public constant VE_TRANCHE_CAPS_EXCEEDS_DEVIATION = "204";
    /// "Tranche caps exceed MAX_DEVIATION"
    string public constant VE_TOKEN_INACTIVE = "205";
    /// "Token is not active"
    string public constant VE_EXCEEDS_TRANCHE_MAXCAP = "206";
    /// "Given tranche capacity is more than the allowed max cap"
    string public constant VE_BELOW_TRANCHE_MINCAP = "207";
    ///  "Given tranche capacity is less than the allowed min cap"
    string public constant VE_INVALID_RATE = "209";
    ///  "Fixed rate is more than the threshold or equal to zero"
    string public constant VE_INVALID_DEPOSIT_START_TIME = "210";
    ///  "Deposit start time is not a future timestamp"
    string public constant VE_INVALID_TRANCHE_START_TIME = "211";
    ///  "Tranche start time is not greater than the deposit start time"
    string public constant VE_INVALID_TRANCHE_END_TIME = "212";
    ///  "Tranche end time is not greater than the tranche start time"
    string public constant VE_INVALID_TRANCHE_DURATION = "213";
    ///  "Tranche duration is not greater than the minimum duration specified"
    string public constant VE_INVALID_LEV_MIN = "214";
    ///  "Invalid Leverage threshold min"
    string public constant VE_INVALID_LEV_MAX = "215";
    ///  "Invalid Leverage threshold max"
    string public constant VE_INVALID_FARM = "217";
    ///  "Invalid Farm (PoolId)"
    string public constant VE_INVALID_SLIPPAGE = "218";
    ///  "Slippage exceeds limit"
    string public constant VE_LEV_MAX_GT_LEV_MIN = "219";
    ///  "Invalid leverage threshold limits (levMax must be > levMax)"
    string public constant VE_INVALID_TRANSFER_AMOUNT = "220";
    ///  "Amount received is less than mentioned"
    string public constant VE_MIN_DEPOSIT_VALUE = "221";
    ///  "Minimum deposit value is not > 0 and < trancheCapacityUSD"
    string public constant VE_INVALID_YS_INPUTS = "222";
    ///  "Length of LP tokens array and yield sources array are not the same"
    string public constant VE_INVALID_INPUT_AMOUNT = "223";
    /// "Input amount is not equal to msg.value"
    string public constant VE_INVALID_TOKEN = "224";
    /// "Token cannot be zero address"
    string public constant VE_INVALID_YS_ADDRESS = "225";
    ///  "LP token and yield source cannot be zero addresses"
    string public constant VE_INVALID_ZERO_ADDRESS = "226"; // New address cannot be set to zero address
    string public constant VE_INVALID_ZERO_VALUE = "227"; // New value cannot be set to zero
    string public constant VE_INVALID_LEV_THRESH_MAX = "228"; // New leverageThresholdMaxCap value cannot be greater than leverageThresholdMinCap
    string public constant VE_INVALID_LEV_THRESH_MIN = "229"; // // New leverageThresholdMinCap value cannot be less than leverageThresholdMaxCap
    string public constant AVAX_TRANSFER_FAILED = "230";
    /// "Failed to transfer AVAX"
    string public constant VE_YIELD_SOURCE_ALREADY_SET = "231";
    /// "Yield source already set on Factory"
    string public constant VE_INVALID_TRANCHE_DURATION_MAX = "232";
    ///  "Tranche duration max is lesser than tranche duration min"
    string public constant VE_INVALID_NATIVE_TOKEN_DEPOSIT = "233";
    /// "Native token deposit is not allowed for non-wAVAX tranches"
    string public constant VE_INVALID_TRANCHE_DURATION_MIN = "234";
    ///  "Tranche duration min is greater than tranche duration max"
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// External Imports
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// Internal Imports
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";
import {Helpers} from "../helpers/Helpers.sol";

/**
 * @title Validation library
 * @author Struct Finance
 */
library Validation {
    /**
     * @notice Used to validate the swap paths
     * @param _swapPath The struct of swap paths to validate
     * @param _addresses The address struct
     * @param _isDualReward Specifies if the farm has dual rewards
     * @param _tokenSr The address of the senior tranche token
     * @param _tokenJr  The address of the junior tranche token
     */
    function validatePaths(
        DataTypes.SwapPath memory _swapPath,
        DataTypes.Addresses memory _addresses,
        address _tokenSr,
        address _tokenJr,
        bool _isDualReward
    ) external pure {
        /// @dev `seniorToJunior` and  `juniorToSenior` paths should always be length 2 (pool should always exist)
        require(address(_swapPath.seniorToJunior[0]) == _tokenSr, Errors.PE_SR_TO_JR_1);
        require(address(_swapPath.seniorToJunior[1]) == _tokenJr, Errors.PE_SR_TO_JR_2);
        require(_swapPath.seniorToJunior.length == 2, Errors.VE_INVALID_LENGTH);
        require(address(_swapPath.juniorToSenior[0]) == _tokenJr, Errors.PE_JR_TO_SR_1);
        require(address(_swapPath.juniorToSenior[1]) == _tokenSr, Errors.PE_JR_TO_SR_2);
        require(_swapPath.juniorToSenior.length == 2, Errors.VE_INVALID_LENGTH);

        /// @dev All the other paths can have 1 hop at max
        require(address(_swapPath.nativeToSenior[0]) == address(_addresses.nativeToken), Errors.PE_NATIVE_TO_SR_1);
        require(
            address(_swapPath.nativeToSenior[_swapPath.nativeToSenior.length - 1]) == _tokenSr, Errors.PE_NATIVE_TO_SR_2
        );

        require(_swapPath.nativeToSenior.length < 4, Errors.VE_INVALID_LENGTH);

        require(_swapPath.nativeToJunior[0] == address(_addresses.nativeToken), Errors.PE_NATIVE_TO_JR_1);
        require(_swapPath.nativeToJunior[_swapPath.nativeToJunior.length - 1] == _tokenJr, Errors.PE_NATIVE_TO_JR_2);
        require(_swapPath.nativeToJunior.length < 4, Errors.VE_INVALID_LENGTH);

        require(address(_swapPath.reward1ToNative[0]) == address(_addresses.reward1), Errors.PE_REWARD1_TO_NATIVE_1);

        require(
            address(_swapPath.reward1ToNative[_swapPath.reward1ToNative.length - 1]) == address(_addresses.nativeToken),
            Errors.PE_REWARD1_TO_NATIVE_2
        );
        require(_swapPath.reward1ToNative.length < 4, Errors.VE_INVALID_LENGTH);

        if (_isDualReward) {
            require(address(_swapPath.reward2ToNative[0]) == address(_addresses.reward2), Errors.PE_REWARD2_TO_NATIVE_1);

            require(
                address(_swapPath.reward2ToNative[_swapPath.reward2ToNative.length - 1])
                    == address(_addresses.nativeToken),
                Errors.PE_REWARD2_TO_NATIVE_2
            );
            require(_swapPath.reward2ToNative.length < 4, Errors.VE_INVALID_LENGTH);
        }
    }

    /**
     * @notice Used to validate the deposits
     * @param _trancheStartTime The start time of the tranche
     * @param _trancheCapacity The max capacity of the tranche
     * @param _depositStartTime The start time of the deposits
     * @param _depositsTotal Total deposits so far into the pool
     * @param _amount  The amount of tokens to be deposited
     * @param _decimals The decimal of the token to be deposited
     */
    function validateDeposit(
        uint256 _trancheStartTime,
        uint256 _trancheCapacity,
        uint256 _depositStartTime,
        uint256 _depositsTotal,
        uint256 _amount,
        uint256 _decimals
    ) external view {
        require(block.timestamp >= _depositStartTime, Errors.VE_DEPOSITS_NOT_STARTED);

        require(block.timestamp < _trancheStartTime, Errors.VE_DEPOSITS_CLOSED);
        require(
            Helpers.tokenDecimalsToWei(_decimals, _amount) + _depositsTotal <= _trancheCapacity,
            Errors.VE_AMOUNT_EXCEEDS_CAP
        );
    }

    /**
     * @notice Used to validate the invest method
     * @param _trancheStartTime The start time of the tranche
     * @param _currentState The current state of the contract
     * @param _trancheCapSr The capacity of the senior tranche
     * @param _trancheCapJr The capacity of the junior tranche
     * @param _tokensDepositedSr The tokens deposited so far to the senior tranche
     * @param _tokensDepositedJr The tokens deposited so far to the junior tranche
     */
    function validateInvest(
        uint256 _trancheStartTime,
        DataTypes.State _currentState,
        uint256 _trancheCapSr,
        uint256 _trancheCapJr,
        uint256 _tokensDepositedSr,
        uint256 _tokensDepositedJr
    ) external view {
        /// Tokens can be invested to the LP before `trancheStartTime`  if the tranches are full
        require(
            (_trancheCapSr == _tokensDepositedSr && _trancheCapJr == _tokensDepositedJr)
                || block.timestamp >= _trancheStartTime,
            Errors.VE_TRANCHE_NOT_STARTED
        );
        require(_currentState == DataTypes.State.OPEN, Errors.VE_INVALID_STATE);
    }

    /**
     * @notice Used to validate the `removeFunds()` method
     *
     * @param _trancheEndTime The end time of the tranche
     * @param _currentState The current state of the contract
     */
    function validateRemoveFunds(uint256 _trancheEndTime, DataTypes.State _currentState) external view {
        require(_currentState == DataTypes.State.INVESTED, Errors.VE_INVALID_STATE);
        require(block.timestamp >= _trancheEndTime, Errors.VE_NOT_MATURED);
    }

    /**
     * @notice Used to validate the `claimExcess()` method
     * @param _investor The address of the investor who calls the method
     * @param _trancheInfo The info of the tranche
     * @param _currentState The current state of the product contract
     */
    function validateClaimExcess(
        DataTypes.State _currentState,
        DataTypes.Investor storage _investor,
        DataTypes.TrancheInfo memory _trancheInfo
    ) external view returns (uint256 _userInvested, uint256 _excess) {
        require(_currentState != DataTypes.State.OPEN, Errors.VE_INVALID_STATE);
        require(!_investor.claimed, Errors.VE_ALREADY_CLAIMED);

        (_userInvested, _excess) = Helpers.getInvestedAndExcess(_investor, _trancheInfo.tokensInvestable);
        require(_excess > 0, Errors.VE_NO_EXCESS);
    }

    /**
     * @notice Used to validate the `withdraw()` method
     * @param _currentState The current state of the product
     * @param _spToken The StructSPToken
     * @param _spTokenId The StructSPTokenId for the tranche
     * @param _investor The investor struct to calculate tokens excess
     * @param _tokensInvestable The total tokens that were eligible for investment from the tranche
     */
    function validateWithdrawal(
        DataTypes.State _currentState,
        IERC1155 _spToken,
        uint256 _spTokenId,
        DataTypes.Investor storage _investor,
        uint256 _tokensInvestable
    ) external view {
        require(_currentState == DataTypes.State.WITHDRAWN, Errors.VE_INVALID_STATE);
        require(_spToken.balanceOf(msg.sender, _spTokenId) > 0, Errors.VE_INSUFFICIENT_BAL);
        (, uint256 _excess) = Helpers.getInvestedAndExcess(_investor, _tokensInvestable);

        /// The user should claim the excess before withdrawing from the tranche
        require(_excess == 0 || _investor.claimed, Errors.VE_NOT_CLAIMED_YET);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// External Imports
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

/// Internal Imports
import "../../interfaces/IGAC.sol";

import {Errors} from "../libraries/helpers/Errors.sol";

/**
 * @title Global Access Control Managed - Base Class
 * @notice Allows inheriting contracts to leverage global access control permissions conveniently, as well as granting contract-specific pausing functionality
 * @dev Inspired from https://github.com/Citadel-DAO/citadel-contracts
 */
contract GACManaged is Pausable {
    IGAC public gac;

    bytes32 internal constant PAUSER = keccak256("PAUSER");
    bytes32 internal constant WHITELISTED = keccak256("WHITELISTED");
    bytes32 internal constant KEEPER = keccak256("KEEPER");
    bytes32 internal constant GOVERNANCE = keccak256("GOVERNANCE");
    bytes32 internal constant MINTER = keccak256("MINTER");
    bytes32 internal constant PRODUCT = keccak256("PRODUCT");
    bytes32 internal constant DISTRIBUTION_MANAGER = keccak256("DISTRIBUTION_MANAGER");
    bytes32 internal constant FACTORY = keccak256("FACTORY");

    /// @dev Initializer
    uint8 private isInitialized;

    /*////////////////////////////////////////////////////////////*/
    /*                           MODIFIERS                        */
    /*////////////////////////////////////////////////////////////*/

    /**
     * @dev only holders of the given role on the GAC can access the methods with this modifier
     * @param role The role that msgSender will be checked against
     */
    modifier onlyRole(bytes32 role) {
        require(gac.hasRole(role, _msgSender()), Errors.ACE_INVALID_ACCESS);
        _;
    }

    function _gacPausable() private view {
        require(!gac.paused(), Errors.ACE_GLOBAL_PAUSED);
        require(!paused(), Errors.ACE_LOCAL_PAUSED);
    }

    /// @dev can be pausable by GAC or local flag
    modifier gacPausable() {
        _gacPausable();
        _;
    }

    /*////////////////////////////////////////////////////////////*/
    /*                           INITIALIZER                      */
    /*////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializer
     * @param _globalAccessControl global access control which is pinged to allow / deny access to permissioned calls by role
     */
    function __GACManaged_init(IGAC _globalAccessControl) public {
        require(isInitialized == 0, Errors.ACE_INITIALIZER);
        isInitialized = 1;
        gac = _globalAccessControl;
    }

    /*////////////////////////////////////////////////////////////*/
    /*                      RESTRICTED ACTIONS                    */
    /*////////////////////////////////////////////////////////////*/

    /// @dev Used to pause certain actions in the contract
    function pause() public onlyRole(PAUSER) {
        _pause();
    }

    /// @dev Used to unpause if paused
    function unpause() public onlyRole(PAUSER) {
        _unpause();
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title The GlobalAccessControl interface
 * @author Struct Finance
 *
 */

interface IGAC {
    /// @notice Used to unpause the contracts globally if it's paused
    function unpause() external;

    /// @notice Used to pause the contracts globally if it's paused
    function pause() external;

    /// @notice Used to grant a specific role to an address
    /// @param role The role to be granted
    /// @param account The address to which the role should be granted
    function grantRole(bytes32 role, address account) external;

    /// @notice Used to validate whether the given address has a specific role
    /// @param role The role to check
    /// @param account The address which should be validated
    /// @return A boolean flag that indicates whether the given address has the required role
    function hasRole(bytes32 role, address account) external view returns (bool);

    /// @notice Used to check if the contracts are paused globally
    /// @return A boolean flag that indicates whether the contracts are paused or not.
    function paused() external view returns (bool);

    /// @notice Used to fetch the roles array `KEEPER_WHITELISTED`
    /// @return An array with the `KEEPER` and `WHITELISTED` roles
    function keeperWhitelistedRoles() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Modified from Solmate:v6 (https://github.com/transmissions11/solmate/blob/a9e3ea26a2dc73bfa87f0cb189687d029028e0c5/src/utils/FixedPointMathLib.sol)
library WadMath {
    error DivideByZero();

    error Overflow();

    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function wadMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) { revert(0, 0) }

            z := div(z, WAD)
        }
    }

    function wadDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Store x * WAD in z for now.
            z := mul(x, WAD)

            // Equivalent to require(y != 0 && (x == 0 || (x * WAD) / x == WAD))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), WAD)))) { revert(0, 0) }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev See https://2π.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            if (denominator == 0) {
                revert DivideByZero();
            }
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        if (denominator <= prod1) {
            if (denominator == 0) {
                revert DivideByZero();
            }
            revert Overflow();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/// @title GMX Yield Source Interface
/// @notice  Defines the functions specific to the GMX yield source contract
interface IGMXYieldSource {
    /// @dev Generic errors

    /// If zero address is passed as an arg
    error ZeroAddress();

    /// Already initialized\
    error Initialized();

    /// No shares for the product yet
    error NoShares(address _product);

    /// _sharesToTokens returns zero during redeem
    error ZeroShares();

    /// Products can supply tokens only once
    error AlreadySupplied();

    /// The expected reward amount is more than the actual rewards added
    error InsufficientRewards(uint256 _actualRewardAmount, uint256 _expectedRewardAmount);

    /// @notice Emitted whenever the tokens are supplied (Buying GLP)
    /// @param amountAIn Amount of tokens A supplied to the LP
    /// @param amountBIn Amount of tokens B supplied to the LP
    /// @param glpReceived GLP Tokens received from the LP in return
    event TokensSupplied(uint256 amountAIn, uint256 amountBIn, uint256 glpReceived);

    /// @notice Emitted whenever the tokens are redeemed from the GLP pool
    /// @param amountARedeemed Amount of tokens A supplied to the LP
    /// @param amountBRedeemed Amount of tokens B supplied to the LP
    event TokensRedeemed(uint256 amountARedeemed, uint256 amountBRedeemed);

    /// @notice Emitted whenever the rewards are harvested and recompounded
    event RewardsRecompounded();

    /// @notice Emitted when additional rewards are added
    /// @param productAddress Address of the product contract
    event RewardsAdded(address indexed productAddress);

    function setFEYGMXProductInfo(address _productAddress, DataTypes.FEYGMXProductInfo memory _productInfo) external;

    /// @notice Supplies liquidity to the GLP index (Buying GLP)
    /// @param amountAIn The amount of token A to be supplied.
    /// @param amountBIn The amount of token B to be supplied.
    /// @return _amountAInWei The amount of token A actually supplied to GLP
    /// @return _amountBInWei The amount of token B actually supplied to GLP
    function supplyTokens(uint256 amountAIn, uint256 amountBIn)
        external
        returns (uint256 _amountAInWei, uint256 _amountBInWei);

    /// @notice Redeems tokens from the GLP index. (Selling GLP)
    /// @dev The redeemed tokens will be directly sent to the product contract triggering the call
    /// @param _expectedTokenAAmount The amount of token A expected to be redeemed
    /// @return The amount of token A received from the GLP
    /// @return The amount of token B received from the GLP

    function redeemTokens(uint256 _expectedTokenAAmount) external returns (uint256, uint256);

    /// @notice Re-compounds rewards
    function recompoundRewards() external;

    function getFEYGMXProductInfo(address _productAddress) external view returns (DataTypes.FEYGMXProductInfo memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

interface IJoeRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountAVAX, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function factory() external pure returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IJoeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IMasterChef {
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. JOE to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that JOE distribution occurs.
        uint256 accJoePerShare; // Accumulated JOE per share, times 1e12. See below.
    }

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256, address, string memory, uint256);

    function poolLength() external view returns (uint256);

    function rewarderBonusTokenInfo(uint256 _pid) external view returns (address, string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IJoePair is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function getReserves() external view returns (uint112, uint112, uint32);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./StorageSlot.sol";
import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using StorageSlot for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../../../external/traderjoe/IJoePair.sol";

/// @dev Copied and modified from the joe-core repo.
/// https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/traderjoe/libraries/JoeLibrary.sol
library JoeLibrary {
    using SafeMathJoe for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "JoeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "JoeLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"0bbca9af0511ad1a1da383135cf3a8d2ac620e549ef9f6ae3a4c33c2fed0af91" // init code fuji
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IJoePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "JoeLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "JoeLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    /// Performs chained quote calculations on any number of pairs
    function getQuote(address factory, uint256 amountIn, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "JoeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            /// Use `quote` instead of `getAmountOut` to get the price without fee
            amounts[i + 1] = quote(amounts[i], reserveIn, reserveOut);
        }
    }
}

library SafeMathJoe {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
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