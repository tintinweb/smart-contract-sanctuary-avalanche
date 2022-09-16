// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import { IClearingHouse, IMarginAccount, IAMM, IHubbleViewer, IOracle } from "./Interfaces.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract LiquidationPriceViewer {
    using SafeCast for uint256;
    using SafeCast for int256;

    struct LiquidationPriceData {
        int256 coefficient;
        uint initialPrice;
    }

    int256 constant PRECISION_INT = 1e6;
    uint256 constant PRECISION_UINT = 1e6;

    uint constant VUSD_IDX = 0;
    uint constant WAVAX_IDX = 1;

    IClearingHouse public immutable clearingHouse;
    IMarginAccount public immutable marginAccount;
    IHubbleViewer public immutable hubbleViewer;
    IOracle public immutable oracle;


    constructor(
        IHubbleViewer _hubbleViewer
    ) {
        hubbleViewer = _hubbleViewer;
        clearingHouse = IClearingHouse(hubbleViewer.clearingHouse());
        marginAccount = IMarginAccount(hubbleViewer.marginAccount());
        oracle = marginAccount.oracle();
    }

    /**
    * Get final margin fraction and liquidation price if user longs/shorts baseAssetQuantity
    * @param idx AMM Index
    * @param baseAssetQuantity Positive if long, negative if short, scaled 18 decimals
    * @return expectedMarginFraction Resultant Margin fraction when the trade is executed
    * @return quoteAssetQuantity USD rate for the trade
    * @return liquidationPrice Mark Price at which trader will be liquidated
    */
    function getTakerExpectedMFAndLiquidationPrice(address trader, uint idx, int256 baseAssetQuantity)
        external
        view
        returns (int256 expectedMarginFraction, uint256 quoteAssetQuantity, uint256 liquidationPrice)
    {
        IAMM amm = clearingHouse.amms(idx);
        // get quoteAsset required to swap baseAssetQuantity
        quoteAssetQuantity = hubbleViewer.getQuote(baseAssetQuantity, idx);

        // get market specific position info
        (int256 takerPosSize,,,) = amm.positions(trader);
        // get total notionalPosition and margin (including unrealizedPnL and funding)
        // using IClearingHouse.Mode.Min_Allowable_Margin here to calculate correct newNotional
        (uint256 notionalPosition, int256 margin) = clearingHouse.getNotionalPositionAndMargin(trader, true /* includeFundingPayments */, IClearingHouse.Mode.Min_Allowable_Margin);

        {
            uint takerNowNotional = amm.getCloseQuote(takerPosSize);
            takerPosSize += baseAssetQuantity;
            uint takerUpdatedNotional = amm.getCloseQuote(takerPosSize);
            // Calculate new total notionalPosition
            notionalPosition = notionalPosition + takerUpdatedNotional - takerNowNotional;

            margin -= _calculateTradeFee(quoteAssetQuantity).toInt256();
            expectedMarginFraction = _getMarginFraction(margin, notionalPosition);
        }
        liquidationPrice = _getTakerLiquidationPrice(trader, amm, notionalPosition, takerPosSize, margin);
    }

    /**
    * Get final margin fraction and liquidation price if user add/remove liquidity
    * @param idx AMM Index
    * @param vUSD vUSD amount to be added/removed in the pool (in 6 decimals)
    * @param isRemove true is liquidity is being removed, false if added
    * @return expectedMarginFraction Resultant Margin fraction after the tx
    * @return liquidationPriceData data required to calculate maker liquidation price
    */
    function getMakerExpectedMFAndLiquidationPrice(address trader, uint idx, uint vUSD, bool isRemove)
        external
        view
        returns (int256 expectedMarginFraction, LiquidationPriceData memory liquidationPriceData)
    {
        // get total notionalPosition and margin (including unrealizedPnL and funding)
        (uint256 notionalPosition, int256 margin) = clearingHouse.getNotionalPositionAndMargin(trader, true /* includeFundingPayments */, IClearingHouse.Mode.Min_Allowable_Margin);

        IAMM amm = clearingHouse.amms(idx);

        // get taker info
        (int256 takerPosSize,,,) = amm.positions(trader);
        uint takerNotional = amm.getCloseQuote(takerPosSize);

        // get maker info
        IAMM.Maker memory maker = amm.makers(trader);

        {
            // calculate total value of deposited liquidity after the tx
            if (isRemove) {
                (,uint dToken) = hubbleViewer.getMakerQuote(idx, vUSD, false /* isBase */, false /* deposit */);
                maker.vUSD = maker.vUSD * (maker.dToken - dToken) / maker.dToken;
                maker.vAsset = maker.vAsset * (maker.dToken - dToken) / maker.dToken;
            } else {
                maker.vUSD += vUSD;
                if (amm.ammState() == IAMM.AMMState.Active) {
                    (uint vAsset,) = hubbleViewer.getMakerQuote(idx, vUSD, false /* isBase */, true /* deposit */);
                    maker.vAsset += vAsset;
                }
            }
        }

        {
            // calculate effective notionalPosition
            (int256 makerPosSize,,) = hubbleViewer.getMakerPositionAndUnrealizedPnl(trader, idx);
            uint totalPosNotional = amm.getCloseQuote(makerPosSize + takerPosSize);
            notionalPosition += _max(2 * maker.vUSD + takerNotional, totalPosNotional);
        }

        {
            (uint nowNotional,,,) = amm.getNotionalPositionAndUnrealizedPnl(trader);
            notionalPosition -= nowNotional;
        }

        expectedMarginFraction = _getMarginFraction(margin, notionalPosition);
        // approximating price at the time of add/remove as y / x
        if (maker.vAsset != 0) {
            (,int256 takerPnl) = amm.getTakerNotionalPositionAndUnrealizedPnl(trader);
            liquidationPriceData = LiquidationPriceData({
                coefficient: _getMakerLiquidationPrice(trader, notionalPosition, 2 * maker.vUSD.toInt256(), takerPnl),
                initialPrice: maker.vUSD * 1e18 / maker.vAsset
            });
        }
    }

    function getTakerLiquidationPrice(address trader, uint idx) external view returns (uint liquidationPrice) {
        IAMM amm = clearingHouse.amms(idx);
        (int256 takerPosSize,,,) = amm.positions(trader);
        // using IClearingHouse.Mode.Maintenance_Margin to get liquidation mode notional
        (uint256 notionalPosition, int256 margin) = clearingHouse.getNotionalPositionAndMargin(trader, true, IClearingHouse.Mode.Maintenance_Margin);
        liquidationPrice = _getTakerLiquidationPrice(trader, amm, notionalPosition, takerPosSize, margin);
    }

    function getMakerLiquidationPrice(address trader, uint idx) external view returns (LiquidationPriceData memory liquidationPriceData) {
        IAMM amm = clearingHouse.amms(idx);
        IAMM.Maker memory maker = amm.makers(trader);
        (,int256 takerPnl) = amm.getTakerNotionalPositionAndUnrealizedPnl(trader);
        (uint256 notionalPosition,) = clearingHouse.getNotionalPositionAndMargin(trader, true, IClearingHouse.Mode.Maintenance_Margin);
        if (maker.vAsset != 0) {
            liquidationPriceData =  LiquidationPriceData({
                coefficient: _getMakerLiquidationPrice(trader, notionalPosition, 2 * maker.vUSD.toInt256(), takerPnl),
                initialPrice: maker.vUSD * 1e18 / maker.vAsset
            });
        }
    }

   /**
    * @notice get taker liquidation price, while ignoring future maker PnL (but factors in maker's notional)
    * margin + (liqPrice - indexPrice) * avax + takerPnl = MM * notionalPosition - (1) where,
    * notionalPosition = takerNotional (at liquidation) + makerNotional
    * takerPnl = (liqPrice - indexPrice) * size - (2), where size is with sign
    * margin = weightedCollateral + unrealizedPnl - pendingFunding
    * avax = avaxBalance * weight

    * For long,
    * notionalPosition = nowNotional + (liqPrice - indexPrice) * size - (3)
    * substitute (2) and (3) in (1),
    * liqPrice = indexPrice + (MM * nowNotional - margin) / (avax + (1 - MM) * size)

    * For short,
    * notionalPosition = nowNotional - (liqPrice - indexPrice) * size - (4)
    * substitute (2) and (4) in (1),
    * liqPrice = indexPrice + (MM * nowNotional - margin) / (avax + (1 + MM) * size)
    */
    function _getTakerLiquidationPrice(
        address trader,
        IAMM amm,
        uint nowNotional,
        int256 takerPosSize,
        int256 margin
    )
        internal
        view
        returns(uint256 /* liquidationPrice */)
    {
        if (takerPosSize == 0) {
            return 0;
        }

        int256 avax = marginAccount.margin(WAVAX_IDX, trader);
        avax = avax * (marginAccount.supportedAssets())[WAVAX_IDX].weight.toInt256() / PRECISION_INT;
        int256 MM = clearingHouse.maintenanceMargin();
        int256 indexPrice = oracle.getUnderlyingPrice(amm.underlyingAsset());

        int256 multiplier = takerPosSize > 0 ? (PRECISION_INT - MM) : (PRECISION_INT + MM);
        // assumption : position size and avax have same precision
        multiplier = multiplier * takerPosSize / PRECISION_INT + avax;
        int256 liquidationPrice = indexPrice + (nowNotional.toInt256() * MM / PRECISION_INT - margin) * 1e18 / multiplier;

        // negative liquidation price is possible when margin is too high
        return liquidationPrice >= 0 ? liquidationPrice.toUint256() : 0;
    }


    /**
    * @notice get maker liquidation price
    * @dev assumes constant collateral value, constant taker pnl and notional
    * P1 - initialPrice, P2 - liquidationPrice
    * https://medium.com/auditless/how-to-calculate-impermanent-loss-full-derivation-803e8b2497b7
    * Impermanent Loss (IL) =  2 * sqrt(k) / (k + 1) - 1 - (1), where k = P2 / P1
    * makerPnl = IL * makerNotional - (2)
    * assuming maker notional will be constant = 2 * maker.vAsset and constant taker PNL at current price

    * margin + makerPnl = MM * totalNotional - (3)
    * substitute (1) and (2) in (3)
    * margin + (2 * sqrt(k) / (k + 1) - 1) * makerNotional = MM * totalNotional - (4)
    * assuming constant margin here or else equation (4) will become a degree 4 polynomial
    * let x^2 = k and coefficient b = 2 * makerNotional / (MM * totalNotional + makerNotional - margin)
    * equation (4) can be simplified as,
    * x^2 - b * x + 1 = 0 - (5)
    * longLiqPrice = x1^2 * P1, shortLiqPrice = x2^2 * P1, where x1 and x2 are roots of equation (5)
    */
    function _getMakerLiquidationPrice(
        address trader,
        uint totalNotional,
        int256 makerNotional,
        int256 takerPnl
    )
        internal
        view
        returns(int256 /* coefficient */)
    {
        // factor in taker position pnl at current price
        int256 margin = marginAccount.getNormalizedMargin(trader) + takerPnl - clearingHouse.getTotalFunding(trader);
        int256 MM = clearingHouse.maintenanceMargin();

        return 2 * makerNotional * PRECISION_INT / (MM * totalNotional.toInt256() / PRECISION_INT + makerNotional - margin);
    }

    // Internal

    function _calculateTradeFee(uint quoteAsset) internal view returns (uint) {
        return quoteAsset * clearingHouse.tradeFee() / PRECISION_UINT;
    }

    // Pure

    function _getMarginFraction(int256 accountValue, uint notionalPosition) private pure returns(int256) {
        if (notionalPosition == 0) {
            return type(int256).max;
        }
        return accountValue * PRECISION_INT / notionalPosition.toInt256();
    }

    function _abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    function _max(uint x, uint y) private pure returns (uint) {
        return x >= y ? x : y;
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