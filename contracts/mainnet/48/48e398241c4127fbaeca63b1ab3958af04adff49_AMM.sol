// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Governable } from "./legos/Governable.sol";
import { ERC20Detailed, IOracle, IRegistry, IVAMM, IAMM, IClearingHouse } from "./Interfaces.sol";

contract AMM is IAMM, Governable {
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 public constant spotPriceTwapInterval = 1 hours;
    uint256 public constant fundingPeriod = 1 hours;
    int256 constant BASE_PRECISION = 1e18;

    address public immutable clearingHouse;
    uint256 public immutable unbondRoundOff;

    /* ****************** */
    /*       Storage      */
    /* ****************** */

    // System-wide config

    IOracle public oracle;

    // AMM config

    IVAMM override public vamm;
    address override public underlyingAsset;
    string public name;

    uint256 public fundingBufferPeriod;
    uint256 public nextFundingTime;
    int256 public cumulativePremiumFraction;
    int256 public cumulativePremiumPerDtoken;
    int256 public posAccumulator;

    uint256 public longOpenInterestNotional;
    uint256 public shortOpenInterestNotional;
    uint256 public maxOracleSpreadRatio; // scaled 2 decimals
    uint256 public maxLiquidationRatio; // scaled 2 decimals
    uint256 public maxLiquidationPriceSpread; // scaled 6 decimals

    enum Side { LONG, SHORT }
    struct Position {
        int256 size;
        uint256 openNotional;
        int256 lastPremiumFraction;
        uint liquidationThreshold;
    }
    mapping(address => Position) override public positions;

    mapping(address => Maker) internal _makers;
    uint256 public withdrawPeriod;
    uint256 public unbondPeriod;

    struct ReserveSnapshot {
        uint256 lastPrice;
        uint256 timestamp;
        uint256 blockNumber;
        bool isLiquidation;
    }
    ReserveSnapshot[] public reserveSnapshots;

    Ignition override public ignition;
    IAMM.AMMState override public ammState;

    /// @notice Min amount of base asset quantity to trade or add liquidity for
    uint256 public minSizeRequirement;

    struct VarGroup1 {
        uint minQuote;
        uint minBase;
        bool isLiquidation;
    }

    uint256[50] private __gap;

    /* ****************** */
    /*       Events       */
    /* ****************** */

    // Generic AMM related events
    event FundingRateUpdated(int256 premiumFraction, uint256 underlyingPrice, int256 cumulativePremiumFraction, int256 cumulativePremiumPerDtoken, int256 posAccumulator, uint256 nextFundingTime, uint256 timestamp, uint256 blockNumber);
    event FundingPaid(address indexed trader, int256 takerFundingPayment, int256 makerFundingPayment);
    event Swap(uint256 lastPrice, uint256 openInterestNotional);

    // Trader related events
    event PositionChanged(address indexed trader, int256 size, uint256 openNotional, int256 realizedPnl);
    event LiquidityAdded(address indexed trader, uint dToken, uint baseAsset, uint quoteAsset, uint timestamp);
    event LiquidityRemoved(address indexed trader, uint dToken, uint baseAsset, uint quoteAsset, int256 realizedPnl, bool isLiquidation, uint timestamp);
    event Unbonded(address indexed trader, uint256 unbondAmount, uint256 unbondTime, uint timestamp);

    /**
    * @dev This is only emitted when maker funding related events are updated.
    * These fields are: ignition,dToken,lastPremiumFraction,pos,lastPremiumPerDtoken,posAccumulator
    */
    event MakerPositionChanged(address indexed trader, Maker maker, uint timestamp);

    modifier onlyClearingHouse() {
        require(msg.sender == clearingHouse, "Only clearingHouse");
        _;
    }

    modifier onlyVamm() {
        require(msg.sender == address(vamm), "Only VAMM");
        _;
    }

    modifier whenIgnition() {
        require(ammState == AMMState.Ignition, "amm_not_ignition");
        _;
    }

    modifier whenActive() {
        require(ammState == AMMState.Active, "amm_not_active");
        _;
    }

    constructor(address _clearingHouse, uint _unbondRoundOff) {
        clearingHouse = _clearingHouse;
        unbondRoundOff = _unbondRoundOff;
    }

    function initialize(
        string memory _name,
        address _underlyingAsset,
        address _oracle,
        uint _minSizeRequirement,
        address _vamm,
        address _governance
    ) external initializer {
        name = _name;
        underlyingAsset = _underlyingAsset;
        oracle = IOracle(_oracle);
        minSizeRequirement = _minSizeRequirement;
        vamm = IVAMM(_vamm);
        _setGovernace(_governance);

        // values that most likely wouldn't need to change frequently
        fundingBufferPeriod = 15 minutes;
        withdrawPeriod = 1 days;
        maxOracleSpreadRatio = 20;
        unbondPeriod = 3 days;
        maxLiquidationRatio = 25;
        maxLiquidationPriceSpread = 1e6;
    }

    /**
    * @dev baseAssetQuantity != 0 has been validated in clearingHouse._openPosition()
    */
    function openPosition(address trader, int256 baseAssetQuantity, uint quoteAssetLimit)
        override
        external
        onlyClearingHouse
        whenActive
        returns (int realizedPnl, uint quoteAsset, bool isPositionIncreased)
    {
        Position memory position = positions[trader];
        bool isNewPosition = position.size == 0 ? true : false;
        Side side = baseAssetQuantity > 0 ? Side.LONG : Side.SHORT;
        if (isNewPosition || (position.size > 0 ? Side.LONG : Side.SHORT) == side) {
            // realizedPnl = 0;
            quoteAsset = _increasePosition(trader, baseAssetQuantity, quoteAssetLimit);
            isPositionIncreased = true;
        } else {
            (realizedPnl, quoteAsset, isPositionIncreased) = _openReversePosition(trader, baseAssetQuantity, quoteAssetLimit);
        }

        uint totalPosSize = uint(abs(positions[trader].size));
        require(totalPosSize == 0 || totalPosSize >= minSizeRequirement, "position_less_than_minSize");
        // update liquidation thereshold
        positions[trader].liquidationThreshold = Math.max(
            totalPosSize * maxLiquidationRatio / 100,
            minSizeRequirement
        );

        _emitPositionChanged(trader, realizedPnl);
    }

    function liquidatePosition(address trader)
        override
        external
        onlyClearingHouse
        returns (int realizedPnl, uint quoteAsset)
    {
        // don't need an ammState check because there should be no active positions
        Position memory position = positions[trader];
        bool isLongPosition = position.size > 0 ? true : false;
        uint pozSize = uint(abs(position.size));
        uint positionToLiquidate = Math.min(pozSize, position.liquidationThreshold);
        if (
            positionToLiquidate != pozSize
            && (positionToLiquidate * 101 / 100) >= pozSize
        ) {
            // positionToLiquidate is within 1% of the overall position, then liquidate the entire pos
            positionToLiquidate = pozSize;
        }

        // liquidation price safeguard
        // price before liquidaiton should be within X% range of last liquidation price in the same block or previous block price
        uint index = reserveSnapshots.length - 1;
        uint lastTradePrice = reserveSnapshots[index].lastPrice;
        while(reserveSnapshots[index].blockNumber == block.number && index != 0) {
            if (reserveSnapshots[index].isLiquidation) {
                lastTradePrice = reserveSnapshots[index].lastPrice;
                break;
            }
            index -= 1;
            lastTradePrice = reserveSnapshots[index].lastPrice;
        }

        uint diff = lastPrice();
        if (diff >= lastTradePrice) {
            diff -= lastTradePrice;
        } else {
            diff = lastTradePrice - diff;
        }
        require(diff <= lastTradePrice * maxLiquidationPriceSpread / 1e8, "AMM.liquidation_price_slippage");

        // liquidate position
        if (isLongPosition) {
            (realizedPnl, quoteAsset) = _reducePosition(trader, -positionToLiquidate.toInt256(), 0, true /* isLiquidation */);
        } else {
            (realizedPnl, quoteAsset) = _reducePosition(trader, positionToLiquidate.toInt256(), type(uint).max, true /* isLiquidation */);
        }
        _emitPositionChanged(trader, realizedPnl);
    }

    function updatePosition(address trader)
        override
        external
        onlyClearingHouse
        returns(int256 fundingPayment)
    {
        if (ammState != AMMState.Active) return 0;

        _setIgnitionShare(trader);
        Maker storage maker = _makers[trader];
        int256 takerFundingPayment;
        int256 makerFundingPayment;
        (
            takerFundingPayment,
            makerFundingPayment,
            maker.lastPremiumFraction,
            maker.lastPremiumPerDtoken
        ) = getPendingFundingPayment(trader);

        _emitMakerPositionChanged(trader);

        Position storage position = positions[trader];
        position.lastPremiumFraction = maker.lastPremiumFraction;

        // +: trader paid, -: trader received
        fundingPayment = takerFundingPayment + makerFundingPayment;
        if (fundingPayment < 0) {
            fundingPayment -= fundingPayment / 1e3; // receivers charged 0.1% to account for rounding-offs
        }
        if (fundingPayment != 0) {
            emit FundingPaid(trader, takerFundingPayment, makerFundingPayment);
        }
    }

    /* ****************** */
    /*       Makers       */
    /* ****************** */

    function addLiquidity(address maker, uint baseAssetQuantity, uint minDToken)
        override
        external
        onlyClearingHouse
        whenActive
        returns (uint dToken)
    {
        require(baseAssetQuantity >= minSizeRequirement, "adding_too_less");
        uint quoteAsset;
        uint baseAssetBal = vamm.balances(1);
        if (baseAssetBal == 0) {
            quoteAsset = baseAssetQuantity * vamm.price_scale() / 1e30;
        } else {
            quoteAsset = baseAssetQuantity * vamm.balances(0) / baseAssetBal;
        }

        dToken = vamm.add_liquidity([quoteAsset, baseAssetQuantity], minDToken);

        // updates
        Maker storage _maker = _makers[maker];
        if (_maker.dToken > 0) { // Maker only accumulates position when they had non-zero liquidity
            _maker.pos += (posAccumulator - _maker.posAccumulator) * _maker.dToken.toInt256() / 1e18;
        }
        _maker.vUSD += quoteAsset;
        _maker.vAsset += baseAssetQuantity;
        _maker.dToken += dToken;
        _maker.posAccumulator = posAccumulator;
        _emitMakerPositionChanged(maker);
        emit LiquidityAdded(maker, dToken, baseAssetQuantity, quoteAsset, _blockTimestamp());
    }

    /**
    * @notice Express the intention to withdraw liquidity.
    * Can only withdraw after unbondPeriod and within withdrawal period
    * All withdrawals are batched together to 00:00 GMT
    * @param dToken Amount of dToken to withdraw
    */
    function unbondLiquidity(uint dToken) external whenActive {
        address maker = msg.sender;
        // this needs to be invoked here because updatePosition is not called before unbondLiquidity
        _setIgnitionShare(maker);
        _emitMakerPositionChanged(maker); // because dToken was updated

        Maker storage _maker = _makers[maker];
        require(dToken != 0, "unbonding_0");
        require(_maker.dToken >= dToken, "unbonding_too_much");
        _maker.unbondAmount = dToken;
        _maker.unbondTime = ((_blockTimestamp() + unbondPeriod) / unbondRoundOff) * unbondRoundOff;
        emit Unbonded(maker, dToken, _maker.unbondTime, _blockTimestamp());
    }

    function forceRemoveLiquidity(address maker)
        override
        external
        onlyClearingHouse
        returns (int realizedPnl, uint makerOpenNotional, int makerPosition)
    {
        Maker storage _maker = _makers[maker];
        if (ammState == AMMState.Active) {
            // @todo partial liquidations and slippage checks
            VarGroup1 memory varGroup1 = VarGroup1(0,0,true);
            uint dToken = _maker.dToken;
            _maker.unbondAmount -= Math.min(dToken, _maker.unbondAmount);
            return _removeLiquidity(maker, dToken, varGroup1);
        }

        // ammState == AMMState.Ignition
        ignition.quoteAsset -= _makers[maker].ignition;
        _makers[maker].ignition = 0;
        _emitMakerPositionChanged(maker);
    }

    function removeLiquidity(address maker, uint amount, uint minQuote, uint minBase)
        override
        external
        onlyClearingHouse
        returns (int realizedPnl, uint makerOpenNotional, int makerPosition)
    {
        Maker storage _maker = _makers[maker];
        require(_maker.unbondAmount >= amount, "withdrawing_more_than_unbonded");
        unchecked { _maker.unbondAmount -= amount; }
        uint _now = _blockTimestamp();
        require(_now >= _maker.unbondTime, "still_unbonding");
        require(_now <= _maker.unbondTime + withdrawPeriod, "withdraw_period_over");
        // there's no need to reset the unbondTime, unbondAmount will take care of everything
        VarGroup1 memory varGroup1 = VarGroup1(minQuote, minBase, false);
        (realizedPnl, makerOpenNotional, makerPosition) = _removeLiquidity(maker, amount, varGroup1);
        if (_maker.dToken != 0) {
            // if the maker doesn't remove all their liq, ensure decent size
            require(_maker.vAsset >= minSizeRequirement, "leftover_liquidity_is_too_less");
            uint totalPosSize = uint(abs(positions[maker].size));
            require(totalPosSize == 0 || totalPosSize >= minSizeRequirement, "removing_very_small_liquidity");
        }
    }

    function _removeLiquidity(address maker, uint amount, VarGroup1 memory varGroup1)
        internal
        returns (int realizedPnl, uint makerOpenNotional, int makerPosition)
    {
        Maker storage _maker = _makers[maker];
        Position storage position = positions[maker];

        // amount <= _maker.dToken will be asserted when updating maker.dToken
        uint256 totalOpenNotional;
        uint[2] memory dBalances = [uint(0),uint(0)];
        (
            makerPosition,
            makerOpenNotional,
            totalOpenNotional,
            realizedPnl, // feeAdjustedPnl
            dBalances
        ) = vamm.remove_liquidity(
            amount,
            [varGroup1.minQuote, varGroup1.minBase],
            _maker.vUSD,
            _maker.vAsset,
            _maker.dToken,
            position.size,
            position.openNotional
        );

        // update maker info
        {
            uint diff = _maker.dToken - amount;
            if (diff == 0) {
                _maker.pos = 0;
                _maker.vAsset = 0;
                _maker.vUSD = 0;
                _maker.dToken = 0;
            } else {
                // muitiply by diff because a taker position will also be opened while removing liquidity and its funding payment is calculated seperately
                _maker.pos = _maker.pos + (posAccumulator - _maker.posAccumulator) * diff.toInt256() / 1e18;
                _maker.vAsset = _maker.vAsset * diff / _maker.dToken;
                _maker.vUSD = _maker.vUSD * diff / _maker.dToken;
                _maker.dToken = diff;
            }
            _maker.posAccumulator = posAccumulator;
        }

        // translate impermanent position to a permanent one
        {
            if (makerPosition != 0) {
                // reducing or reversing position
                if (makerPosition * position.size < 0) { // this ensures takerPosition !=0
                    realizedPnl += _getPnlWhileReducingPosition(position.size, position.openNotional, makerPosition);
                }
                position.openNotional = totalOpenNotional;
                position.size += makerPosition;

                // update liquidation thereshold
                position.liquidationThreshold = Math.max(
                    uint(abs(position.size)) * maxLiquidationRatio / 100,
                    minSizeRequirement
                );

                // update long and short open interest notional
                if (makerPosition > 0) {
                    longOpenInterestNotional += makerPosition.toUint256();
                } else {
                    shortOpenInterestNotional += (-makerPosition).toUint256();
                }

                // these events will enable the parsing logic in the indexer to work seamlessly
                emit Swap(lastPrice(), openInterestNotional());
                _emitPositionChanged(maker, realizedPnl);
            }
        }

        _emitMakerPositionChanged(maker);
        emit LiquidityRemoved(
            maker,
            amount,
            dBalances[1], // baseAsset
            dBalances[0], // quoteAsset
            realizedPnl,
            varGroup1.isLiquidation,
            _blockTimestamp()
        );
    }

    function getOpenNotionalWhileReducingPosition(
        int256 positionSize,
        uint256 newNotionalPosition,
        int256 unrealizedPnl,
        int256 baseAssetQuantity
    )
        override
        public
        pure
        returns(uint256 remainOpenNotional, int realizedPnl)
    {
        require(abs(positionSize) >= abs(baseAssetQuantity), "AMM.ONLY_REDUCE_POS");
        bool isLongPosition = positionSize > 0 ? true : false;

        realizedPnl = unrealizedPnl * abs(baseAssetQuantity) / abs(positionSize);
        int256 unrealizedPnlAfter = unrealizedPnl - realizedPnl;

        /**
        * We need to determine the openNotional value of the reduced position now.
        * We know notionalPosition and unrealizedPnlAfter (unrealizedPnl times the ratio of open position)
        * notionalPosition = notionalPosition - quoteAsset (exchangedQuoteAssetAmount)
        * calculate openNotional (it's different depends on long or short side)
        * long: unrealizedPnl = notionalPosition - openNotional => openNotional = notionalPosition - unrealizedPnl
        * short: unrealizedPnl = openNotional - notionalPosition => openNotional = notionalPosition + unrealizedPnl
        */
        if (isLongPosition) {
            /**
            * Let baseAssetQuantity = Q, position.size = size, by definition of _reducePosition, abs(size) >= abs(Q)
            * quoteAsset = notionalPosition * Q / size
            * unrealizedPnlAfter = unrealizedPnl - realizedPnl = unrealizedPnl - unrealizedPnl * Q / size
            * remainOpenNotional = notionalPosition - notionalPosition * Q / size - unrealizedPnl + unrealizedPnl * Q / size
            * => remainOpenNotional = notionalPosition(size-Q)/size - unrealizedPnl(size-Q)/size
            * => remainOpenNotional = (notionalPosition - unrealizedPnl) * (size-Q)/size
            * Since notionalPosition includes the PnL component, notionalPosition >= unrealizedPnl and size >= Q
            * Hence remainOpenNotional >= 0
            */
            remainOpenNotional = (newNotionalPosition.toInt256() - unrealizedPnlAfter).toUint256();  // will assert that remainOpenNotional >= 0
        } else {
            /**
            * Let baseAssetQuantity = Q, position.size = size, by definition of _reducePosition, abs(size) >= abs(Q)
            * quoteAsset = notionalPosition * Q / size
            * unrealizedPnlAfter = unrealizedPnl - realizedPnl = unrealizedPnl - unrealizedPnl * Q / size
            * remainOpenNotional = notionalPosition - notionalPosition * Q / size + unrealizedPnl - unrealizedPnl * Q / size
            * => remainOpenNotional = notionalPosition(size-Q)/size + unrealizedPnl(size-Q)/size
            * => remainOpenNotional = (notionalPosition + unrealizedPnl) * (size-Q)/size
            * => In AMM.sol, unrealizedPnl = position.openNotional - notionalPosition
            * => notionalPosition + unrealizedPnl >= 0
            * Hence remainOpenNotional >= 0
            */
            remainOpenNotional = (newNotionalPosition.toInt256() + unrealizedPnlAfter).toUint256();  // will assert that remainOpenNotional >= 0
        }
    }

    /**
     * @notice update funding rate
     * @dev only allow to update while reaching `nextFundingTime`
     */
    function settleFunding()
        override
        external
        onlyClearingHouse
    {
        if (
            ammState != AMMState.Active
            || _blockTimestamp() < nextFundingTime
        ) return;

        // premium = twapMarketPrice - twapIndexPrice
        // timeFraction = fundingPeriod(1 hour) / 1 day
        // premiumFraction = premium * timeFraction
        int256 underlyingPrice = getUnderlyingTwapPrice(spotPriceTwapInterval);
        int256 premium = getTwapPrice(spotPriceTwapInterval) - underlyingPrice;
        int256 premiumFraction = (premium * int256(fundingPeriod)) / 1 days;

        int256 premiumPerDtoken = posAccumulator * premiumFraction;

        // makers pay slightly more to account for rounding off
        premiumPerDtoken = (premiumPerDtoken / BASE_PRECISION) + 1;

        cumulativePremiumFraction += premiumFraction;
        cumulativePremiumPerDtoken += premiumPerDtoken;

        // Updates for next funding event
        // in order to prevent multiple funding settlement during very short time after network congestion
        uint256 minNextValidFundingTime = _blockTimestamp() + fundingBufferPeriod;

        // floor((nextFundingTime + fundingPeriod) / 3600) * 3600
        uint256 nextFundingTimeOnHourStart = ((nextFundingTime + fundingPeriod) / 1 hours) * 1 hours;

        // max(nextFundingTimeOnHourStart, minNextValidFundingTime)
        nextFundingTime = nextFundingTimeOnHourStart > minNextValidFundingTime
            ? nextFundingTimeOnHourStart
            : minNextValidFundingTime;

        _emitFundingRateUpdated(premiumFraction, underlyingPrice);
    }

    function commitLiquidity(address maker, uint quoteAsset)
        override
        external
        whenIgnition
        onlyClearingHouse
    {
        quoteAsset /= 2; // only need to track the USD side
        _makers[maker].ignition += quoteAsset;
        ignition.quoteAsset += quoteAsset;
        _emitMakerPositionChanged(maker);
    }

    function liftOff() external onlyGovernance whenIgnition {
        uint256 underlyingPrice = getUnderlyingTwapPrice(15 minutes).toUint256();
        require(underlyingPrice > 0, "amm.liftOff.underlyingPrice_not_set");
        vamm.setinitialPrice(underlyingPrice * 1e12); // vamm expects 18 decimal scale
        if (ignition.quoteAsset > 0) {
            ignition.baseAsset = ignition.quoteAsset * 1e18 / underlyingPrice;
            ignition.dToken = vamm.add_liquidity([ignition.quoteAsset, ignition.baseAsset], 0);

            // helps in the API logic
            emit LiquidityAdded(address(this), ignition.dToken, ignition.baseAsset, ignition.quoteAsset, _blockTimestamp());
        }

        ammState = AMMState.Active;
        // funding games can now begin
        nextFundingTime = ((_blockTimestamp() + fundingPeriod) / 1 hours) * 1 hours;
    }

    function _setIgnitionShare(address maker) internal {
        uint vUSD = _makers[maker].ignition;
        if (vUSD == 0) return;

        Maker storage _maker = _makers[maker];
        _maker.vUSD = vUSD;
        (_maker.vAsset, _maker.dToken) = getIgnitionShare(vUSD);
        _maker.ignition = 0;
    }

    function getIgnitionShare(uint vUSD) override public view returns (uint vAsset, uint dToken) {
        vAsset = ignition.baseAsset * vUSD / ignition.quoteAsset;
        dToken = ignition.dToken * vUSD / ignition.quoteAsset;
    }

    // View

    function getSnapshotLen() external view returns (uint256) {
        return reserveSnapshots.length;
    }

    function getUnderlyingTwapPrice(uint256 _intervalInSeconds) public view returns (int256) {
        return oracle.getUnderlyingTwapPrice(underlyingAsset, _intervalInSeconds);
    }

    function getTwapPrice(uint256 _intervalInSeconds) public view returns (int256) {
        return _calcTwap(_intervalInSeconds).toInt256();
    }

    function getNotionalPositionAndUnrealizedPnl(address trader)
        override
        external
        view
        returns(uint256 notionalPosition, int256 unrealizedPnl, int256 size, uint256 openNotional)
    {
        if (ammState == AMMState.Ignition) {
            return (_makers[trader].ignition * 2, 0, 0, 0);
        }

        uint vUSD = _makers[trader].ignition;
        uint vAsset;
        uint dToken;
        if (vUSD > 0) { // participated in ignition
            (vAsset, dToken) = getIgnitionShare(vUSD);
        } else {
            vUSD = _makers[trader].vUSD;
            vAsset = _makers[trader].vAsset;
            dToken = _makers[trader].dToken;
        }

        (notionalPosition, size, unrealizedPnl, openNotional) = vamm.get_notional(
            dToken,
            vUSD,
            vAsset,
            positions[trader].size,
            positions[trader].openNotional
        );
    }

    /**
    * @notice returns false if
    * (1-maxSpreadRatio)*indexPrice < markPrice < (1+maxSpreadRatio)*indexPrice
    * else, true
    */
    function isOverSpreadLimit() external view returns(bool) {
        if (ammState != AMMState.Active) return false;

        uint oraclePrice = uint(oracle.getUnderlyingPrice(underlyingAsset));
        uint markPrice = lastPrice();
        uint oracleSpreadRatioAbs;
        if (markPrice > oraclePrice) {
            oracleSpreadRatioAbs = markPrice - oraclePrice;
        } else {
            oracleSpreadRatioAbs = oraclePrice - markPrice;
        }
        oracleSpreadRatioAbs = oracleSpreadRatioAbs * 100 / oraclePrice;

        if (oracleSpreadRatioAbs >= maxOracleSpreadRatio) {
            return true;
        }
        return false;
    }

    /**
    * @notice returns notionalPosition and unrealizedPnl when isOverSpreadLimit()
    * calculate margin fraction using markPrice and oraclePrice
    * if mode = Maintenance_Margin, return values which have maximum margin fraction
    * if mode = min_allowable_margin, return values which have minimum margin fraction
    */
    function getOracleBasedPnl(address trader, int256 margin, IClearingHouse.Mode mode) override external view returns (uint notionalPosition, int256 unrealizedPnl) {
        Maker memory _maker = _makers[trader];
        if (ammState == AMMState.Ignition) {
            return (_maker.ignition * 2, 0);
        }

        Position memory _taker = positions[trader];
        int256 size;
        uint openNotional;
        (notionalPosition, size, unrealizedPnl, openNotional) = vamm.get_notional(
            _maker.dToken,
            _maker.vUSD,
            _maker.vAsset,
            _taker.size,
            _taker.openNotional
        );

        if (notionalPosition == 0) {
            return (0, 0);
        }

        int256 marginFraction = (margin + unrealizedPnl) * 1e6 / notionalPosition.toInt256();
        (int oracleBasedNotional, int256 oracleBasedUnrealizedPnl, int256 oracleBasedMF) = _getOracleBasedMarginFraction(
            trader,
            margin,
            openNotional,
            size
        );

        if (mode == IClearingHouse.Mode.Maintenance_Margin) {
            if (oracleBasedMF > marginFraction) {
                notionalPosition = oracleBasedNotional.toUint256();
                unrealizedPnl = oracleBasedUnrealizedPnl;
            }
        } else if (oracleBasedMF < marginFraction) { // IClearingHouse.Mode.Min_Allowable_Margin
            notionalPosition = oracleBasedNotional.toUint256();
            unrealizedPnl = oracleBasedUnrealizedPnl;
        }
    }

    function _getOracleBasedMarginFraction(address trader, int256 margin, uint256 openNotional, int256 size)
        internal
        view
        returns (int oracleBasedNotional, int256 oracleBasedUnrealizedPnl, int256 marginFraction)
    {
        int256 oraclePrice = oracle.getUnderlyingPrice(underlyingAsset);
        oracleBasedNotional = oraclePrice * abs(size) / BASE_PRECISION;
        if (size > 0) {
            oracleBasedUnrealizedPnl = oracleBasedNotional - openNotional.toInt256();
        } else if (size < 0) {
            oracleBasedUnrealizedPnl = openNotional.toInt256() - oracleBasedNotional;
        }
        // notionalPostion = max(makerDebt, makerPositionNotional) + takerPositionalNotional
        // = max(makerDebt + takerPositionNotional, makerPositionNotional + takerPositionNotional)
        int256 oracleBasedTakerNotional = oraclePrice * abs(positions[trader].size) / BASE_PRECISION;
        oracleBasedNotional = _max(2 * _makers[trader].vUSD.toInt256() + oracleBasedTakerNotional, oracleBasedNotional);
        marginFraction = (margin + oracleBasedUnrealizedPnl) * 1e6 / oracleBasedNotional;
    }

    function getPendingFundingPayment(address trader)
        override
        public
        view
        returns(
            int256 takerFundingPayment,
            int256 makerFundingPayment,
            int256 latestCumulativePremiumFraction,
            int256 latestPremiumPerDtoken
        )
    {
        Position memory taker = positions[trader];
        Maker memory maker = _makers[trader];

        // cache state variables locally for cheaper access and return values
        latestCumulativePremiumFraction = cumulativePremiumFraction;
        latestPremiumPerDtoken = cumulativePremiumPerDtoken;

        // Taker
        takerFundingPayment = (latestCumulativePremiumFraction - taker.lastPremiumFraction)
            * taker.size
            / BASE_PRECISION;

        // Maker
        uint256 dToken;
        uint vUSD = _makers[trader].ignition;
        if (vUSD > 0) {
            (,dToken) = getIgnitionShare(vUSD);
        } else {
            dToken = maker.dToken;
        }

        if (dToken > 0) {
            int256 cpf = latestCumulativePremiumFraction - maker.lastPremiumFraction;
            makerFundingPayment = (
                maker.pos * cpf +
                (
                    latestPremiumPerDtoken
                    - maker.lastPremiumPerDtoken
                    - maker.posAccumulator * cpf / BASE_PRECISION
                ) * dToken.toInt256()
            ) / BASE_PRECISION;
        }
    }

    function getCloseQuote(int256 baseAssetQuantity) override public view returns(uint256 quoteAssetQuantity) {
        if (baseAssetQuantity > 0) {
            return vamm.get_dy(1, 0, baseAssetQuantity.toUint256());
        } else if (baseAssetQuantity < 0) {
            return vamm.get_dx(0, 1, (-baseAssetQuantity).toUint256());
        }
        return 0;
    }

    function getTakerNotionalPositionAndUnrealizedPnl(address trader) override public view returns(uint takerNotionalPosition, int256 unrealizedPnl) {
        Position memory position = positions[trader];
        if (position.size > 0) {
            takerNotionalPosition = vamm.get_dy(1, 0, position.size.toUint256());
            unrealizedPnl = takerNotionalPosition.toInt256() - position.openNotional.toInt256();
        } else if (position.size < 0) {
            takerNotionalPosition = vamm.get_dx(0, 1, (-position.size).toUint256());
            unrealizedPnl = position.openNotional.toInt256() - takerNotionalPosition.toInt256();
        }
    }

    function lastPrice() public view returns(uint256) {
        return vamm.mark_price() / 1e12;
    }

    function openInterestNotional() public view returns (uint256) {
        return longOpenInterestNotional + shortOpenInterestNotional;
    }

    function makers(address maker) override external view returns(Maker memory) {
        return _makers[maker];
    }

    // internal

    /**
    * @dev Go long on an asset
    * @param baseAssetQuantity Exact base asset quantity to go long
    * @param max_dx Maximum amount of quote asset to be used while longing baseAssetQuantity. Lower means longing at a lower price (desirable).
    * @param isLiquidation true if liquidaiton else false
    * @return quoteAssetQuantity quote asset utilised. quoteAssetQuantity / baseAssetQuantity was the average rate.
      quoteAssetQuantity <= max_dx
    */
    function _long(int256 baseAssetQuantity, uint max_dx, bool isLiquidation) internal returns (uint256 quoteAssetQuantity) {
        require(baseAssetQuantity > 0, "VAMM._long: baseAssetQuantity is <= 0");

        uint _lastPrice;
        (quoteAssetQuantity, _lastPrice) = vamm.exchangeExactOut(
            0, // sell quote asset
            1, // purchase base asset
            baseAssetQuantity.toUint256(), // long exactly. Note that statement asserts that baseAssetQuantity >= 0
            max_dx
        ); // 6 decimals precision

        // longs not allowed if market price > (1 + maxOracleSpreadRatio)*index price
        uint256 oraclePrice = uint(oracle.getUnderlyingPrice(underlyingAsset));
        oraclePrice = oraclePrice * (100 + maxOracleSpreadRatio) / 100;
        if (!isLiquidation && _lastPrice > oraclePrice) {
            revert("VAMM._long: longs not allowed");
        }

        _addReserveSnapshot(_lastPrice, isLiquidation);
        // since maker position will be opposite of the trade
        posAccumulator -= baseAssetQuantity * 1e18 / vamm.totalSupply().toInt256();
        emit Swap(_lastPrice, openInterestNotional());
    }

    /**
    * @dev Go short on an asset
    * @param baseAssetQuantity Exact base asset quantity to short
    * @param min_dy Minimum amount of quote asset to be used while shorting baseAssetQuantity. Higher means shorting at a higher price (desirable).
    * @param isLiquidation true if liquidaiton else false
    * @return quoteAssetQuantity quote asset utilised. quoteAssetQuantity / baseAssetQuantity was the average short rate.
      quoteAssetQuantity >= min_dy.
    */
    function _short(int256 baseAssetQuantity, uint min_dy, bool isLiquidation) internal returns (uint256 quoteAssetQuantity) {
        require(baseAssetQuantity < 0, "VAMM._short: baseAssetQuantity is >= 0");

        uint _lastPrice;
        (quoteAssetQuantity, _lastPrice) = vamm.exchange(
            1, // sell base asset
            0, // get quote asset
            (-baseAssetQuantity).toUint256(), // short exactly. Note that statement asserts that baseAssetQuantity <= 0
            min_dy
        );

        // shorts not allowed if market price < (1 - maxOracleSpreadRatio)*index price
        uint256 oraclePrice = uint(oracle.getUnderlyingPrice(underlyingAsset));
        oraclePrice = oraclePrice * (100 - maxOracleSpreadRatio) / 100;
        if (!isLiquidation && _lastPrice < oraclePrice) {
            revert("VAMM._short: shorts not allowed");
        }
        _addReserveSnapshot(_lastPrice, isLiquidation);
        // since maker position will be opposite of the trade
        posAccumulator -= baseAssetQuantity * 1e18 / vamm.totalSupply().toInt256();
        emit Swap(_lastPrice, openInterestNotional());
    }

    function _emitPositionChanged(address trader, int256 realizedPnl) internal {
        Position memory position = positions[trader];
        emit PositionChanged(trader, position.size, position.openNotional, realizedPnl);
    }

    function _emitMakerPositionChanged(address maker) internal {
        emit MakerPositionChanged(maker, _makers[maker], _blockTimestamp());
    }

    /**
    * @dev Get PnL to be realized for the part of the position that is being closed
    *   Check takerPosition != 0 before calling
    */
    function _getPnlWhileReducingPosition(
        int256 takerPosition,
        uint takerOpenNotional,
        int256 makerPosition
    ) internal view returns (int256 pnlToBeRealized) {
        // notional of the combined new position
        uint newNotional = getCloseQuote(takerPosition + makerPosition);
        uint totalPosition = abs(makerPosition + takerPosition).toUint256();

        if (abs(takerPosition) > abs(makerPosition)) { // taker position side remains same
            uint reducedOpenNotional = takerOpenNotional * abs(makerPosition).toUint256() / abs(takerPosition).toUint256();
            uint makerNotional = newNotional * abs(makerPosition).toUint256() / totalPosition;
            pnlToBeRealized = _getPnlToBeRealized(takerPosition, makerNotional, reducedOpenNotional);
        } else { // taker position side changes
            // @todo handle case when totalPosition = 0
            uint closedPositionNotional = newNotional * abs(takerPosition).toUint256() / totalPosition;
            pnlToBeRealized = _getPnlToBeRealized(takerPosition, closedPositionNotional, takerOpenNotional);
        }
    }

    function _getPnlToBeRealized(int256 takerPosition, uint notionalPosition, uint openNotional) internal pure returns (int256 pnlToBeRealized) {
        if (takerPosition > 0) {
            pnlToBeRealized = notionalPosition.toInt256() - openNotional.toInt256();
        } else {
            pnlToBeRealized = openNotional.toInt256() - notionalPosition.toInt256();
        }
    }

    function _increasePosition(address trader, int256 baseAssetQuantity, uint quoteAssetLimit)
        internal
        returns(uint quoteAsset)
    {
        if (baseAssetQuantity > 0) { // Long - purchase baseAssetQuantity
            longOpenInterestNotional += baseAssetQuantity.toUint256();
            quoteAsset = _long(baseAssetQuantity, quoteAssetLimit, false /* isLiquidation */);
        } else { // Short - sell baseAssetQuantity
            shortOpenInterestNotional += (-baseAssetQuantity).toUint256();
            quoteAsset = _short(baseAssetQuantity, quoteAssetLimit, false /* isLiquidation */);
        }
        positions[trader].size += baseAssetQuantity; // -ve baseAssetQuantity will increase short position
        positions[trader].openNotional += quoteAsset;
    }

    function _openReversePosition(address trader, int256 baseAssetQuantity, uint quoteAssetLimit)
        internal
        returns (int realizedPnl, uint quoteAsset, bool isPositionIncreased)
    {
        Position memory position = positions[trader];
        if (abs(position.size) >= abs(baseAssetQuantity)) {
            (realizedPnl, quoteAsset) = _reducePosition(trader, baseAssetQuantity, quoteAssetLimit, false /* isLiqudation */);
        } else {
            uint closedRatio = (quoteAssetLimit * abs(position.size).toUint256()) / abs(baseAssetQuantity).toUint256();
            (realizedPnl, quoteAsset) = _reducePosition(trader, -position.size, closedRatio, false /* isLiqudation */);

            // this is required because the user might pass a very less value (slippage-prone) while shorting
            if (quoteAssetLimit >= quoteAsset) {
                quoteAssetLimit -= quoteAsset;
            }
            quoteAsset += _increasePosition(trader, baseAssetQuantity + position.size, quoteAssetLimit);
            isPositionIncreased = true;
        }
    }

    /**
    * @dev validate that baseAssetQuantity <= position.size should be performed before the call to _reducePosition
    */
    function _reducePosition(address trader, int256 baseAssetQuantity, uint quoteAssetLimit, bool isLiquidation)
        internal
        returns (int realizedPnl, uint256 quoteAsset)
    {
        (, int256 unrealizedPnl) = getTakerNotionalPositionAndUnrealizedPnl(trader);

        Position storage position = positions[trader]; // storage because there are updates at the end
        bool isLongPosition = position.size > 0 ? true : false;

        if (isLongPosition) {
            longOpenInterestNotional -= (-baseAssetQuantity).toUint256();
            quoteAsset = _short(baseAssetQuantity, quoteAssetLimit, isLiquidation);
        } else {
            shortOpenInterestNotional -= baseAssetQuantity.toUint256();
            quoteAsset = _long(baseAssetQuantity, quoteAssetLimit, isLiquidation);
        }
        uint256 notionalPosition = getCloseQuote(position.size + baseAssetQuantity);
        (position.openNotional, realizedPnl) = getOpenNotionalWhileReducingPosition(position.size, notionalPosition, unrealizedPnl, baseAssetQuantity);
        position.size += baseAssetQuantity;
    }

    function _addReserveSnapshot(uint256 price, bool isLiquidation)
        internal
    {
        uint256 currentBlock = block.number;
        uint256 blockTimestamp = _blockTimestamp();

        if (reserveSnapshots.length == 0) {
            reserveSnapshots.push(
                ReserveSnapshot(price, blockTimestamp, currentBlock, isLiquidation)
            );
            return;
        }

        ReserveSnapshot storage latestSnapshot = reserveSnapshots[reserveSnapshots.length - 1];
        // update values in snapshot if in the same block
        if (currentBlock == latestSnapshot.blockNumber) {
            latestSnapshot.lastPrice = price;
        } else {
            reserveSnapshots.push(
                ReserveSnapshot(price, blockTimestamp, currentBlock, isLiquidation)
            );
        }
    }

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _calcTwap(uint256 _intervalInSeconds)
        internal
        view
        returns (uint256)
    {
        uint256 snapshotIndex = reserveSnapshots.length - 1;
        uint256 currentPrice = reserveSnapshots[snapshotIndex].lastPrice;
        if (_intervalInSeconds == 0) {
            return currentPrice;
        }

        uint256 baseTimestamp = _blockTimestamp() - _intervalInSeconds;
        ReserveSnapshot memory currentSnapshot = reserveSnapshots[snapshotIndex];
        // return the latest snapshot price directly
        // if only one snapshot or the timestamp of latest snapshot is earlier than asking for
        if (reserveSnapshots.length == 1 || currentSnapshot.timestamp <= baseTimestamp) {
            return currentPrice;
        }

        uint256 previousTimestamp = currentSnapshot.timestamp;
        uint256 period = _blockTimestamp() - previousTimestamp;
        uint256 weightedPrice = currentPrice * period;
        while (true) {
            // if snapshot history is too short
            if (snapshotIndex == 0) {
                return weightedPrice / period;
            }

            snapshotIndex = snapshotIndex - 1;
            currentSnapshot = reserveSnapshots[snapshotIndex];
            currentPrice = reserveSnapshots[snapshotIndex].lastPrice;

            // check if current round timestamp is earlier than target timestamp
            if (currentSnapshot.timestamp <= baseTimestamp) {
                // weighted time period will be (target timestamp - previous timestamp). For example,
                // now is 1000, _interval is 100, then target timestamp is 900. If timestamp of current round is 970,
                // and timestamp of NEXT round is 880, then the weighted time period will be (970 - 900) = 70,
                // instead of (970 - 880)
                weightedPrice = weightedPrice + (currentPrice * (previousTimestamp - baseTimestamp));
                break;
            }

            uint256 timeFraction = previousTimestamp - currentSnapshot.timestamp;
            weightedPrice = weightedPrice + (currentPrice * timeFraction);
            period = period + timeFraction;
            previousTimestamp = currentSnapshot.timestamp;
        }
        return weightedPrice / _intervalInSeconds;
    }

    function _emitFundingRateUpdated(
        int256 _premiumFraction,
        int256 _underlyingPrice
    ) internal {
        emit FundingRateUpdated(
            _premiumFraction,
            _underlyingPrice.toUint256(),
            cumulativePremiumFraction,
            cumulativePremiumPerDtoken,
            posAccumulator,
            nextFundingTime,
            _blockTimestamp(),
            block.number
        );
    }

    // Pure

    function abs(int x) internal pure returns (int) {
        return x >= 0 ? x : -x;
    }

    function _max(int x, int y) private pure returns (int) {
        return x >= y ? x : y;
    }

    // Governance

    function putAmmInIgnition() external onlyClearingHouse {
        ammState = AMMState.Ignition;
    }

    function changeOracle(address _oracle) public onlyGovernance {
        oracle = IOracle(_oracle);
    }

    function setFundingBufferPeriod(uint _fundingBufferPeriod) external onlyGovernance {
        fundingBufferPeriod = _fundingBufferPeriod;
    }

    function setUnbondPeriod(uint _unbondPeriod) external onlyGovernance {
        unbondPeriod = _unbondPeriod;
    }

    function setMaxOracleSpreadRatio(uint _maxOracleSpreadRatio) external onlyGovernance {
        maxOracleSpreadRatio = _maxOracleSpreadRatio;
    }

    function setLiquidationParams (uint _maxLiquidationRatio, uint _maxLiquidationPriceSpread) external onlyGovernance {
        maxLiquidationRatio = _maxLiquidationRatio;
        maxLiquidationPriceSpread = _maxLiquidationPriceSpread;
    }

    function setMinSizeRequirement(uint _minSizeRequirement) external onlyGovernance {
        minSizeRequirement = _minSizeRequirement;
    }
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract VanillaGovernable {
    address public governance;

    modifier onlyGovernance() {
        require(msg.sender == governance, "ONLY_GOVERNANCE");
        _;
    }

    function setGovernace(address _governance) external onlyGovernance {
        _setGovernace(_governance);
    }

    function _setGovernace(address _governance) internal {
        governance = _governance;
    }
}

contract Governable is VanillaGovernable, Initializable {}

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
    function liquidatePosition(address trader) external returns (int realizedPnl, uint quoteAsset);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
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