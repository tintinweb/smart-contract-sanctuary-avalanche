// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import { IClearingHouse, IMarginAccount, IAMM, IVAMM, IHubbleViewer } from "./Interfaces.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract HubbleViewer is IHubbleViewer {
    using SafeCast for uint256;
    using SafeCast for int256;

    int256 constant PRECISION_INT = 1e6;
    uint256 constant PRECISION_UINT = 1e6;

    uint constant VUSD_IDX = 0;

    IClearingHouse public immutable clearingHouse;
    IMarginAccount public immutable marginAccount;

    /// @dev not actually used but helps in utils.generateConfig
    address public immutable registry;

    struct Position {
        int256 size;
        uint256 openNotional;
        int256 unrealizedPnl;
        uint256 avgOpen;
        int256 funding;
    }

    /// @dev UI Helper
    struct MarketInfo {
        address amm;
        address underlying;
    }

    constructor(
        IClearingHouse _clearingHouse,
        IMarginAccount _marginAccount,
        address _registry
    ) {
        clearingHouse = _clearingHouse;
        marginAccount = _marginAccount;
        registry = _registry;
    }

    function getMarginFractionAndMakerStatus(address[] calldata traders)
        external
        view
        returns(int256[] memory fractions, bool[] memory isMaker)
    {
        uint len = traders.length;
        fractions = new int256[](len);
        isMaker = new bool[](len);
        for (uint i; i < len; i++) {
            fractions[i] = clearingHouse.getMarginFraction(traders[i]);
            isMaker[i] = clearingHouse.isMaker(traders[i]);
        }
    }

    function marginAccountLiquidatationStatus(address[] calldata traders)
        external
        view
        returns(IMarginAccount.LiquidationStatus[] memory isLiquidatable, uint[] memory repayAmount, uint[] memory incentivePerDollar)
    {
        isLiquidatable = new IMarginAccount.LiquidationStatus[](traders.length);
        repayAmount = new uint[](traders.length);
        incentivePerDollar = new uint[](traders.length);
        for (uint i; i < traders.length; i++) {
            (isLiquidatable[i], repayAmount[i], incentivePerDollar[i]) = marginAccount.isLiquidatable(traders[i], true);
        }
    }

    /**
    * @notice Get information about all user positions
    * @param trader Trader for which information is to be obtained
    * @return positions in order of amms
    *   positions[i].size - BaseAssetQuantity amount longed (+ve) or shorted (-ve)
    *   positions[i].openNotional - $ value of position
    *   positions[i].unrealizedPnl - in dollars. +ve is profit, -ve if loss
    *   positions[i].avgOpen - Average $ value at which position was started
    */
    function userPositions(address trader) external view returns(Position[] memory positions) {
        uint l = clearingHouse.getAmmsLength();
        positions = new Position[](l);
        for (uint i; i < l; i++) {
            IAMM amm = clearingHouse.amms(i);
            (positions[i].size, positions[i].openNotional,,) = amm.positions(trader);
            if (positions[i].size == 0) {
                positions[i].unrealizedPnl = 0;
                positions[i].avgOpen = 0;
            } else {
                (,positions[i].unrealizedPnl) = amm.getTakerNotionalPositionAndUnrealizedPnl(trader);
                positions[i].avgOpen = positions[i].openNotional * 1e18 / _abs(positions[i].size).toUint256();
            }
        }
    }

    /**
    * @notice Get information about maker's all impermanent positions
    * @param maker Maker for which information is to be obtained
    * @return positions in order of amms
    *   positions[i].size - BaseAssetQuantity amount longed (+ve) or shorted (-ve)
    *   positions[i].openNotional - $ value of position
    *   positions[i].unrealizedPnl - in dollars. +ve is profit, -ve if loss
    *   positions[i].avgOpen - Average $ value at which position was started
    */
    function makerPositions(address maker) external view returns(Position[] memory positions) {
        uint l = clearingHouse.getAmmsLength();
        IAMM amm;
        positions = new Position[](l);
        for (uint i; i < l; i++) {
            amm = clearingHouse.amms(i);
            (
                positions[i].size,
                positions[i].openNotional,
                positions[i].unrealizedPnl
            ) = _getMakerPositionAndUnrealizedPnl(maker, amm);
            if (positions[i].size == 0) {
                positions[i].avgOpen = 0;
            } else {
                positions[i].avgOpen = positions[i].openNotional * 1e18 / _abs(positions[i].size).toUint256();
            }
            (,positions[i].funding,,) = amm.getPendingFundingPayment(maker);
        }
    }

    function markets() external view returns(MarketInfo[] memory _markets) {
        uint l = clearingHouse.getAmmsLength();
        _markets = new MarketInfo[](l);
        for (uint i; i < l; i++) {
            IAMM amm = clearingHouse.amms(i);
            _markets[i] = MarketInfo(address(amm), amm.underlyingAsset());
        }
    }

    /**
    * @notice get maker impermanent position and unrealizedPnl for a particular amm
    * @param _maker maker address
    * @param idx amm index
    * @return position Maker's current impermanent position
    * @return openNotional Position open notional for the current impermanent position inclusive of fee earned
    * @return unrealizedPnl PnL if maker removes liquidity and closes their impermanent position in the same amm
    */
    function getMakerPositionAndUnrealizedPnl(address _maker, uint idx)
        override
        public
        view
        returns (int256 position, uint openNotional, int256 unrealizedPnl)
    {
        return _getMakerPositionAndUnrealizedPnl(_maker, clearingHouse.amms(idx));
    }

    function _getMakerPositionAndUnrealizedPnl(address _maker, IAMM amm)
        internal
        view
        returns (int256 /* position */, uint /* openNotional */, int256 /* unrealizedPnl */)
    {
        IVAMM vamm = amm.vamm();
        IAMM.Maker memory maker = amm.makers(_maker);
        if (maker.ignition != 0) {
            maker.vUSD = maker.ignition;
            (maker.vAsset, maker.dToken) = amm.getIgnitionShare(maker.vUSD);
        }
        return vamm.get_maker_position(maker.dToken, maker.vUSD, maker.vAsset, maker.dToken);
    }

    /**
    * @notice calculate amount of quote asset required for trade
    * @param baseAssetQuantity base asset to long/short
    * @param idx amm index
    */
    function getQuote(int256 baseAssetQuantity, uint idx) public view returns(uint256 quoteAssetQuantity) {
        IAMM amm = clearingHouse.amms(idx);
        IVAMM vamm = amm.vamm();

        if (baseAssetQuantity >= 0) {
            return vamm.get_dx(0, 1, baseAssetQuantity.toUint256()) + 1;
        }
        // rounding-down while shorting is not a problem
        // because lower the min_dy, more permissible it is
        return vamm.get_dy(1, 0, (-baseAssetQuantity).toUint256());
    }

    /**
    * @notice calculate amount of base asset required for trade
    * @param quoteAssetQuantity amount of quote asset to long/short
    * @param idx amm index
    * @param isLong long - true, short - false
    */
    function getBase(uint256 quoteAssetQuantity, uint idx, bool isLong) external view returns(int256 /* baseAssetQuantity */) {
        IAMM amm = clearingHouse.amms(idx);
        IVAMM vamm = amm.vamm();

        uint256 baseAssetQuantity;
        if (isLong) {
            baseAssetQuantity = vamm.get_dy(0, 1, quoteAssetQuantity);
            return baseAssetQuantity.toInt256();
        }
        baseAssetQuantity = vamm.get_dx(1, 0, quoteAssetQuantity);
        return -(baseAssetQuantity.toInt256());
    }

    /**
    * @notice Get total liquidity deposited by maker and its current value
    * @param _maker maker for which information to be obtained
    * @return
    *   vAsset - current base asset amount of maker in the pool
    *   vUSD - current quote asset amount of maker in the pool
    *   totalDeposited - total value of initial liquidity deposited in the pool by maker
    *   dToken - maker dToken balance
    *   vAssetBalance - base token liquidity in the pool
    *   vUSDBalance - quote token liquidity in the pool
    */
    function getMakerLiquidity(address _maker, uint idx)
        external
        view
        returns (uint vAsset, uint vUSD, uint totalDeposited, uint dToken, uint unbondTime, uint unbondAmount, uint vAssetBalance, uint vUSDBalance)
    {
        IAMM amm = clearingHouse.amms(idx);
        IVAMM vamm = amm.vamm();
        IAMM.Maker memory maker = amm.makers(_maker);

        if (amm.ammState() == IAMM.AMMState.Active) {
            if (maker.ignition > 0) {
                (,dToken) = amm.getIgnitionShare(maker.ignition);
            } else {
                dToken = maker.dToken;
            }
            unbondTime = maker.unbondTime;
            unbondAmount = maker.unbondAmount;
            totalDeposited = 2 * maker.vUSD;

            vUSDBalance = vamm.balances(0);
            vAssetBalance = vamm.balances(1);
            uint totalDTokenSupply = vamm.totalSupply();
            if (totalDTokenSupply > 0) {
                vUSD = vUSDBalance * dToken / totalDTokenSupply;
                vAsset = vAssetBalance * dToken / totalDTokenSupply;
            }
        } else {
            totalDeposited = 2 * maker.ignition;
            vUSD = totalDeposited;
        }
    }

    /**
    * @notice calculate base and quote asset amount form dToken
     */
    function calcWithdrawAmounts(uint dToken, uint idx) external view returns (uint quoteAsset, uint baseAsset) {
        IAMM amm = clearingHouse.amms(idx);
        IVAMM vamm = amm.vamm();

        uint totalDTokenSupply = vamm.totalSupply();
        if (totalDTokenSupply > 0) {
            quoteAsset = vamm.balances(0) * dToken / totalDTokenSupply;
            baseAsset = vamm.balances(1) * dToken / totalDTokenSupply;
        }
    }

    /**
    * @notice Get amount of token to add/remove given the amount of other token
    * @param inputAmount quote/base asset amount to add or remove, base - 18 decimal, quote - 6 decimal
    * @param isBase true if inputAmount is base asset
    * @param deposit true -> addLiquidity, false -> removeLiquidity
    * @return fillAmount base/quote asset amount to be added/removed
    *         dToken - equivalent dToken amount
    */
    function getMakerQuote(uint idx, uint inputAmount, bool isBase, bool deposit) public view returns (uint fillAmount, uint dToken) {
        IAMM amm = clearingHouse.amms(idx);
        IVAMM vamm = amm.vamm();

        if (isBase) {
            // calculate quoteAsset amount, fillAmount = quoteAsset, inputAmount = baseAsset
            uint baseAssetBal = vamm.balances(1);
            if (baseAssetBal == 0) {
                fillAmount = inputAmount * vamm.price_scale() / 1e30;
            } else {
                fillAmount = inputAmount * vamm.balances(0) / baseAssetBal;
            }
            dToken = vamm.calc_token_amount([fillAmount, inputAmount], deposit);
        } else {
            uint bal0 = vamm.balances(0);
            // calculate quote asset amount, fillAmount = baseAsset, inputAmount = quoteAsset
            if (bal0 == 0) {
                fillAmount = inputAmount * 1e30 / vamm.price_scale();
            } else {
                fillAmount = inputAmount * vamm.balances(1) / bal0;
            }
            dToken = vamm.calc_token_amount([inputAmount, fillAmount], deposit);
        }
    }

    /**
    * @notice get user margin for all collaterals
    */
    function userInfo(address trader) external view returns(int256[] memory) {
        uint length = marginAccount.supportedAssetsLen();
        int256[] memory _margin = new int256[](length);
        // -ve funding means user received funds
        _margin[VUSD_IDX] = marginAccount.margin(VUSD_IDX, trader) - clearingHouse.getTotalFunding(trader);
        for (uint i = 1; i < length; i++) {
            _margin[i] = marginAccount.margin(i, trader);
        }
        return _margin;
    }

    /**
    * @notice get user account information
    */
    function getAccountInfo(address trader) external view returns (
        int totalCollateral,
        int256 freeMargin,
        int256 marginFraction,
        uint notionalPosition,
        int256 unrealizedPnl,
        int256 marginFractionLiquidation
    ) {
        int256 margin;
        (margin, totalCollateral) = marginAccount.weightedAndSpotCollateral(trader);
        marginFraction = clearingHouse.calcMarginFraction(trader, true, IClearingHouse.Mode.Min_Allowable_Margin);

        uint l = clearingHouse.getAmmsLength();
        bool isOverSpreadLimit = false;
        for (uint i; i < l; i++) {
            IAMM amm = clearingHouse.amms(i);
            (int size,,,) = amm.positions(trader);
            IAMM.Maker memory maker = amm.makers(trader);
            if (amm.isOverSpreadLimit() && (size != 0 || maker.dToken != 0 || maker.ignition != 0)) {
                isOverSpreadLimit = true;
            }
        }

        if (isOverSpreadLimit) {
            marginFractionLiquidation = clearingHouse.calcMarginFraction(trader, true, IClearingHouse.Mode.Maintenance_Margin);
        }

        (notionalPosition, unrealizedPnl) = clearingHouse.getTotalNotionalPositionAndUnrealizedPnl(trader, margin, IClearingHouse.Mode.Min_Allowable_Margin);
        int256 minAllowableMargin = clearingHouse.minAllowableMargin();
        int256 pendingFunding = clearingHouse.getTotalFunding(trader);
        totalCollateral -= pendingFunding;
        freeMargin = margin + unrealizedPnl - pendingFunding - notionalPosition.toInt256() * minAllowableMargin / PRECISION_INT;
    }

    /**
    * @dev Vanity function required for some analyses later
    */
    function getPendingFundings(address[] calldata traders)
        external
        view
        returns(int[][] memory takerFundings, int[][] memory makerFundings)
    {
        uint l = clearingHouse.getAmmsLength();
        uint t = traders.length;
        takerFundings = new int[][](t);
        makerFundings = new int[][](t);
        for (uint j; j < t; j++) {
            takerFundings[j] = new int[](l);
            makerFundings[j] = new int[](l);
            for (uint i; i < l; i++) {
                IAMM amm = clearingHouse.amms(i);
                (takerFundings[j][i],makerFundings[j][i],,) = amm.getPendingFundingPayment(traders[j]);
            }
        }
    }

    // Pure

    function _abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRegistry {
    function oracle() external view returns(address);
    function clearingHouse() external view returns(address);
    function vusd() external view returns(address);
    function insuranceFund() external view returns(address);
    function marginAccount() external view returns(address);
}

interface IOracle {
    function getUnderlyingPrice(address asset) external view returns(int256);
    function getUnderlyingTwapPrice(address asset, uint256 intervalInSeconds) external view returns (int256);
}

interface IClearingHouse {
    enum Mode { Maintenance_Margin, Min_Allowable_Margin }
    function openPosition(uint idx, int256 baseAssetQuantity, uint quoteAssetLimit) external;
    function closePosition(uint idx, uint quoteAssetLimit) external;
    function addLiquidity(uint idx, uint256 baseAssetQuantity, uint minDToken) external returns (uint dToken);
    function removeLiquidity(uint idx, uint256 dToken, uint minQuoteValue, uint minBaseValue) external;
    function settleFunding() external;
    function getTotalNotionalPositionAndUnrealizedPnl(address trader, int256 margin, Mode mode)
        external
        view
        returns(uint256 notionalPosition, int256 unrealizedPnl);
    function isAboveMaintenanceMargin(address trader) external view returns(bool);
    function assertMarginRequirement(address trader) external view;
    function updatePositions(address trader) external;
    function getMarginFraction(address trader) external view returns(int256);
    function getTotalFunding(address trader) external view returns(int256 totalFunding);
    function getAmmsLength() external view returns(uint);
    function amms(uint idx) external view returns(IAMM);
    function maintenanceMargin() external view returns(int256);
    function minAllowableMargin() external view returns(int256);
    function tradeFee() external view returns(uint256);
    function liquidationPenalty() external view returns(uint256);
    function getNotionalPositionAndMargin(address trader, bool includeFundingPayments, Mode mode)
        external
        view
        returns(uint256 notionalPosition, int256 margin);
    function isMaker(address trader) external view returns(bool);
    function liquidate(address trader) external;
    function liquidateMaker(address trader) external;
    function liquidateTaker(address trader) external;
    function commitLiquidity(uint idx, uint quoteAsset) external;
    function insuranceFund() external view returns(IInsuranceFund);
    function calcMarginFraction(address trader, bool includeFundingPayments, Mode mode) external view returns(int256);
}

interface ERC20Detailed {
    function decimals() external view returns (uint8);
}

interface IInsuranceFund {
    function seizeBadDebt(uint amount) external;
    function startAuction(address token) external;
    function calcVusdAmountForAuction(address token, uint amount) external view returns(uint);
    function buyCollateralFromAuction(address token, uint amount) external;
}

interface IAMM {
    struct Maker {
        uint vUSD;
        uint vAsset;
        uint dToken;
        int pos; // position
        int posAccumulator; // value of global.posAccumulator until which pos has been updated
        int lastPremiumFraction;
        int lastPremiumPerDtoken;
        uint unbondTime;
        uint unbondAmount;
        uint ignition;
    }

    struct Ignition {
        uint quoteAsset;
        uint baseAsset;
        uint dToken;
    }

    /**
    * @dev We do not deliberately have a Pause state. There is only a master-level pause at clearingHouse level
    */
    enum AMMState { Inactive, Ignition, Active }
    function ammState() external view returns(AMMState);
    function ignition() external view returns(uint quoteAsset, uint baseAsset, uint dToken);
    function getIgnitionShare(uint vUSD) external view returns (uint vAsset, uint dToken);

    function openPosition(address trader, int256 baseAssetQuantity, uint quoteAssetLimit)
        external
        returns (int realizedPnl, uint quoteAsset, bool isPositionIncreased);
    function addLiquidity(address trader, uint baseAssetQuantity, uint minDToken) external returns (uint dToken);
    function removeLiquidity(address maker, uint amount, uint minQuote, uint minBase) external returns (int /* realizedPnl */, uint /* makerOpenNotional */, int /* makerPosition */);
    function forceRemoveLiquidity(address maker) external returns (int realizedPnl, uint makerOpenNotional, int makerPosition);
    function getNotionalPositionAndUnrealizedPnl(address trader)
        external
        view
        returns(uint256 notionalPosition, int256 unrealizedPnl, int256 size, uint256 openNotional);
    function updatePosition(address trader) external returns(int256 fundingPayment);
    function liquidatePosition(address trader) external returns (int realizedPnl, int baseAsset, uint quoteAsset);
    function settleFunding() external;
    function underlyingAsset() external view returns (address);
    function positions(address trader) external view returns (int256,uint256,int256,uint256);
    function getCloseQuote(int256 baseAssetQuantity) external view returns(uint256 quoteAssetQuantity);
    function getTakerNotionalPositionAndUnrealizedPnl(address trader) external view returns(uint takerNotionalPosition, int256 unrealizedPnl);
    function getPendingFundingPayment(address trader)
        external
        view
        returns(
            int256 takerFundingPayment,
            int256 makerFundingPayment,
            int256 latestCumulativePremiumFraction,
            int256 latestPremiumPerDtoken
        );
    function getOpenNotionalWhileReducingPosition(int256 positionSize, uint256 notionalPosition, int256 unrealizedPnl, int256 baseAssetQuantity)
        external
        pure
        returns(uint256 remainOpenNotional, int realizedPnl);
    function makers(address maker) external view returns(Maker memory);
    function vamm() external view returns(IVAMM);
    function commitLiquidity(address maker, uint quoteAsset) external;
    function putAmmInIgnition() external;
    function isOverSpreadLimit() external view returns (bool);
    function getOracleBasedPnl(address trader, int256 margin, IClearingHouse.Mode mode) external view returns (uint, int256);
}

interface IMarginAccount {
    struct Collateral {
        IERC20 token;
        uint weight;
        uint8 decimals;
    }

    enum LiquidationStatus {
        IS_LIQUIDATABLE,
        OPEN_POSITIONS,
        NO_DEBT,
        ABOVE_THRESHOLD
    }

    function addMargin(uint idx, uint amount) external;
    function addMarginFor(uint idx, uint amount, address to) external;
    function removeMargin(uint idx, uint256 amount) external;
    function getSpotCollateralValue(address trader) external view returns(int256 spot);
    function weightedAndSpotCollateral(address trader) external view returns(int256, int256);
    function getNormalizedMargin(address trader) external view returns(int256);
    function realizePnL(address trader, int256 realizedPnl) external;
    function isLiquidatable(address trader, bool includeFunding) external view returns(LiquidationStatus, uint, uint);
    function supportedAssetsLen() external view returns(uint);
    function supportedAssets() external view returns (Collateral[] memory);
    function margin(uint idx, address trader) external view returns(int256);
    function transferOutVusd(address recipient, uint amount) external;
    function liquidateExactRepay(address trader, uint repay, uint idx, uint minSeizeAmount) external;
    function oracle() external view returns(IOracle);
}

interface IVAMM {
    function balances(uint256) external view returns (uint256);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dx(
        uint256 i,
        uint256 j,
        uint256 dy
    ) external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256 dy, uint256 last_price);

    function exchangeExactOut(
        uint256 i,
        uint256 j,
        uint256 dy,
        uint256 max_dx
    ) external returns (uint256 dx, uint256 last_price);

    function get_notional(uint256 makerDToken, uint256 vUSD, uint256 vAsset, int256 takerPosSize, uint256 takerOpenNotional) external view returns (uint256, int256, int256, uint256);
    function last_prices() external view returns(uint256);
    function mark_price() external view returns(uint256);
    function price_oracle() external view returns(uint256);
    function price_scale() external view returns(uint256);
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external view returns (uint256);
    function remove_liquidity(
        uint256 amount,
        uint256[2] calldata minAmounts,
        uint256 vUSD,
        uint256 vAsset,
        uint256 makerDToken,
        int256 takerPosSize,
        uint256 takerOpenNotional
    ) external returns (int256, uint256, uint256, int256, uint[2] calldata);
    function get_maker_position(uint256 amount, uint256 vUSD, uint256 vAsset, uint256 makerDToken) external view returns (int256, uint256, int256);
    function totalSupply() external view returns (uint256);
    function setinitialPrice(uint) external;
}

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IERC20FlexibleSupply is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

interface IVUSD is IERC20 {
     function mintWithReserve(address to, uint amount) external;
}

interface IUSDC is IERC20FlexibleSupply {
    function masterMinter() external view returns(address);
    function configureMinter(address minter, uint256 minterAllowedAmount) external;
}

interface IHubbleViewer {
    function getMakerPositionAndUnrealizedPnl(address _maker, uint idx)
        external
        view
        returns (int256 position, uint openNotional, int256 unrealizedPnl);
    function clearingHouse() external returns(IClearingHouse);
    function marginAccount() external returns(IMarginAccount);
    function getMakerQuote(uint idx, uint inputAmount, bool isBase, bool deposit) external view returns (uint fillAmount, uint dToken);
    function getQuote(int256 baseAssetQuantity, uint idx) external view returns(uint256 quoteAssetQuantity);
}

interface IHubbleReferral {
    function getTraderRefereeInfo(address trader) external view returns (address referrer);
}

interface IJoeRouter02 {
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
    function factory() external returns(address);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external returns (uint256[] memory amounts);
    function getAmountsOut(uint256 amountOut, address[] calldata path) external returns (uint256[] memory amounts);
}

interface IJoePair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IJoeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IWAVAX is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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