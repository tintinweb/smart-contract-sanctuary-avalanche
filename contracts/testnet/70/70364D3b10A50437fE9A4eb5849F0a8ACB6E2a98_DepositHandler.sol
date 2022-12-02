// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../bank/FundReceiver.sol";
import "../event/EventEmitter.sol";
import "../feature/FeatureUtils.sol";

import "../market/Market.sol";
import "../market/MarketStore.sol";
import "../market/MarketToken.sol";

import "../deposit/Deposit.sol";
import "../deposit/DepositStore.sol";
import "../deposit/DepositUtils.sol";
import "../oracle/Oracle.sol";
import "../oracle/OracleModule.sol";

contract DepositHandler is ReentrancyGuard, FundReceiver, OracleModule {
    DataStore public immutable dataStore;
    EventEmitter public immutable eventEmitter;
    DepositStore public immutable depositStore;
    MarketStore public immutable marketStore;
    Oracle public immutable oracle;
    FeeReceiver public immutable feeReceiver;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
        EventEmitter _eventEmitter,
        DepositStore _depositStore,
        MarketStore _marketStore,
        Oracle _oracle,
        FeeReceiver _feeReceiver
    ) FundReceiver(_roleStore) {
        dataStore = _dataStore;
        eventEmitter = _eventEmitter;
        depositStore = _depositStore;
        marketStore = _marketStore;
        oracle = _oracle;
        feeReceiver = _feeReceiver;
    }

    receive() external payable {}

    function createDeposit(
        address account,
        DepositUtils.CreateDepositParams calldata params
    ) external nonReentrant onlyController returns (bytes32) {
        FeatureUtils.validateFeature(dataStore, Keys.createDepositFeatureKey(address(this)));

        return DepositUtils.createDeposit(
            dataStore,
            eventEmitter,
            depositStore,
            marketStore,
            account,
            params
        );
    }

    function executeDeposit(
        bytes32 key,
        OracleUtils.SetPricesParams calldata oracleParams
    ) external nonReentrant onlyOrderKeeper {
        uint256 startingGas = gasleft();

        try this._executeDeposit(
            key,
            oracleParams,
            msg.sender,
            startingGas
        ) {
        } catch Error(string memory reason) {
            // revert instead of cancel if the reason for failure is due to oracle params
            if (keccak256(abi.encode(reason)) == Keys.ORACLE_ERROR_KEY) {
                revert(reason);
            }

            DepositUtils.cancelDeposit(
                dataStore,
                eventEmitter,
                depositStore,
                marketStore,
                key,
                msg.sender,
                startingGas
            );
        } catch {
            DepositUtils.cancelDeposit(
                dataStore,
                eventEmitter,
                depositStore,
                marketStore,
                key,
                msg.sender,
                startingGas
            );
        }
    }

    function _executeDeposit(
        bytes32 key,
        OracleUtils.SetPricesParams memory oracleParams,
        address keeper,
        uint256 startingGas
    ) external
        onlySelf
        withOraclePrices(oracle, dataStore, eventEmitter, oracleParams)
    {
        FeatureUtils.validateFeature(dataStore, Keys.executeDepositFeatureKey(address(this)));

        uint256[] memory oracleBlockNumbers = OracleUtils.getUncompactedOracleBlockNumbers(
            oracleParams.compactedOracleBlockNumbers,
            oracleParams.tokens.length
        );

        DepositUtils.ExecuteDepositParams memory params = DepositUtils.ExecuteDepositParams(
            dataStore,
            eventEmitter,
            depositStore,
            marketStore,
            oracle,
            feeReceiver,
            key,
            oracleBlockNumbers,
            keeper,
            startingGas
        );

        DepositUtils.executeDeposit(params);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";

contract FundReceiver is RoleModule {
    constructor(RoleStore _roleStore) RoleModule(_roleStore) {}

    // users may incorrectly send the native token into the contract, allow it to be recovered
    function recoverWnt(address payable receiver, uint256 amount) external onlyController {
        receiver.transfer(amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Market.sol";
import "../role/RoleModule.sol";

contract MarketStore is RoleModule {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;
    using Market for Market.Props;

    mapping(address => Market.Props) internal markets;
    EnumerableSet.AddressSet internal marketTokens;

    constructor(RoleStore _roleStore) RoleModule(_roleStore) {}

    function set(address marketToken, Market.Props memory market) external onlyController {
        markets[marketToken] = market;
        marketTokens.add(marketToken);
    }

    function remove(address marketToken) external onlyController {
        delete markets[marketToken];
        marketTokens.remove(marketToken);
    }

    function contains(address marketToken) external view returns (bool) {
        return marketTokens.contains(marketToken);
    }

    function get(address marketToken) external view returns (Market.Props memory) {
        return markets[marketToken];
    }

    function getMarketCount() external view returns (uint256) {
        return marketTokens.length();
    }

    function getMarketKeys(uint256 start, uint256 end) external view returns (address[] memory) {
        return marketTokens.valuesAt(start, end);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../order/Order.sol";
import "../deposit/Deposit.sol";
import "../pricing/SwapPricingUtils.sol";
import "../pricing/PositionPricingUtils.sol";

contract EventEmitter is RoleModule {
    event PositionIncrease(
        bytes32 key,
        address indexed account,
        address indexed market,
        address collateralToken,
        bool isLong,
        uint256 executionPrice,
        uint256 sizeDeltaInUsd,
        int256 collateralDeltaAmount
    );
    event PositionDecrease(
        bytes32 key,
        address indexed account,
        address indexed market,
        address collateralToken,
        bool isLong,
        uint256 executionPrice,
        uint256 sizeDeltaInUsd,
        int256 collateralDeltaAmount,
        int256 positionPnlUsd,
        int256 pnlAmountForPool,
        int256 remainingCollateralAmount,
        uint256 outputAmount
    );
    // PositionLiquidated?

    event DepositCreated(bytes32 key, Deposit.Props deposit);
    event DepositExecuted(bytes32 key);
    event DepositCancelled(bytes32 key);

    event WithdrawalCreated(bytes32 key, Withdrawal.Props withdrawal);
    event WithdrawalExecuted(bytes32 key);
    event WithdrawalCancelled(bytes32 key);

    event OrderCreated(bytes32 key, Order.Props order);
    event OrderUpdated(
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 triggerPrice,
        uint256 acceptablePrice
    );
    event OrderCancelled(bytes32 key, string reason);
    event OrderExecuted(bytes32 key);
    event OrderFrozen(bytes32 key, string reason);
    // event OrderCallback();

    // event SetPricePrecision

    event SwapFeesCollected(bytes32 action, SwapPricingUtils.SwapFees fees);
    event PositionFeesCollected(bool isIncrease, PositionPricingUtils.PositionFees fees);

    event PoolAmountUpdated(address market, address token, int256 delta, uint256 nextValue);
    event SwapImpactPoolAmountUpdated(address market, address token, int256 delta, uint256 nextValue);
    event PositionImpactPoolAmountUpdated(address market, int256 delta, uint256 nextValue);
    event OpenInterestUpdated(address market, address collateralToken, bool isLong, int256 delta, uint256 nextValue);
    event OpenInterestInTokensUpdated(address market, address collateralToken, bool isLong, int256 delta, uint256 nextValue);
    event ClaimableFundingUpdated(address market, address token, address account, uint256 delta, uint256 nextValue);
    event FundingFeesClaimed(address market, address token, address account, address receiver, uint256 amount);
    event AdlStateUpdated(int256 pnlToPoolFactor, uint256 maxPnlFactor, bool shouldEnableAdl);
    event TraderReferralDiscountApplied(address trader, address token, uint256 amount);
    event AffiliateRewardEarned(address market, address token, address affiliate, address trader, uint256 amount);
    event AffiliateRewardClaimed(address market, address token, address account, address receiver, uint256 amount);

    event InsufficientFundingFeePayment(uint256 fundingFeeAmount, uint256 collateralAmount);

    event CollateralSumDelta(
        address market,
        address collateralToken,
        bool isLong,
        int256 collateralDeltaAmount
    );

    event OraclePriceUpdated(address token, uint256 minPrice, uint256 maxPrice, bool isPrimary, bool isPriceFeed);

    constructor(RoleStore _roleStore) RoleModule(_roleStore) {}

    function emitPoolAmountUpdated(address market, address token, int256 delta, uint256 nextValue) external onlyController {
        emit PoolAmountUpdated(market, token, delta, nextValue);
    }

    function emitSwapImpactPoolAmountUpdated(address market, address token, int256 delta, uint256 nextValue) external onlyController {
        emit SwapImpactPoolAmountUpdated(market, token, delta, nextValue);
    }

    function emitPositionImpactPoolAmountUpdated(address market, int256 delta, uint256 nextValue) external onlyController {
        emit PositionImpactPoolAmountUpdated(market, delta, nextValue);
    }

    function emitOpenInterestUpdated(address market, address collateralToken, bool isLong, int256 delta, uint256 nextValue) external onlyController {
        emit OpenInterestUpdated(market, collateralToken, isLong, delta, nextValue);
    }

    function emitOpenInterestInTokensUpdated(address market, address collateralToken, bool isLong, int256 delta, uint256 nextValue) external onlyController {
        emit OpenInterestInTokensUpdated(market, collateralToken, isLong, delta, nextValue);
    }

    function emitClaimableFundingUpdated(address market, address token, address account, uint256 delta, uint256 nextValue) external onlyController {
        emit ClaimableFundingUpdated(market, token, account, delta, nextValue);
    }

    function emitFundingFeesClaimed(address market, address token, address account, address receiver, uint256 amount) external onlyController {
        emit FundingFeesClaimed(market, token, account, receiver, amount);
    }

    function emitAdlStateUpdated(int256 pnlToPoolFactor, uint256 maxPnlFactor, bool shouldEnableAdl) external onlyController {
        emit AdlStateUpdated(pnlToPoolFactor, maxPnlFactor, shouldEnableAdl);
    }

    function emitTraderReferralDiscountApplied(address trader, address token, uint256 amount) external onlyController {
        emit TraderReferralDiscountApplied(trader, token, amount);
    }

    function emitAffiliateRewardEarned(address market, address token, address affiliate, address trader, uint256 amount) external onlyController {
        emit AffiliateRewardEarned(market, token, affiliate, trader, amount);
    }

    function emitAffiliateRewardClaimed(address market, address token, address account, address receiver, uint256 amount) external onlyController {
        emit AffiliateRewardClaimed(market, token, account, receiver, amount);
    }

    function emitCollateralSumDelta(
        address market,
        address collateralToken,
        bool isLong,
        int256 collateralDeltaAmount
    ) external onlyController {
        emit CollateralSumDelta(market, collateralToken, isLong, collateralDeltaAmount);
    }

    function emitOrderCreated(bytes32 key, Order.Props memory order) external onlyController {
        emit OrderCreated(key, order);
    }

    function emitOrderExecuted(bytes32 key) external onlyController {
        emit OrderExecuted(key);
    }

    function emitOrderUpdated(
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 triggerPrice,
        uint256 acceptablePrice
    ) external onlyController {
        emit OrderUpdated(key, sizeDeltaUsd, triggerPrice, acceptablePrice);
    }

    function emitOrderCancelled(bytes32 key, string memory reason) external onlyController {
        emit OrderCancelled(key, reason);
    }

    function emitOrderFrozen(bytes32 key, string memory reason) external onlyController {
        emit OrderFrozen(key, reason);
    }

    function emitDepositCreated(bytes32 key, Deposit.Props memory deposit) external onlyController {
        emit DepositCreated(key, deposit);
    }

    function emitDepositExecuted(bytes32 key) external onlyController {
        emit DepositExecuted(key);
    }

    function emitDepositCancelled(bytes32 key) external onlyController {
        emit DepositCancelled(key);
    }

    function emitWithdrawalCreated(bytes32 key, Withdrawal.Props memory withdrawal) external onlyController {
        emit WithdrawalCreated(key, withdrawal);
    }

    function emitWithdrawalExecuted(bytes32 key) external onlyController {
        emit WithdrawalExecuted(key);
    }

    function emitWithdrawalCancelled(bytes32 key) external onlyController {
        emit WithdrawalCancelled(key);
    }

    function emitSwapFeesCollected(bytes32 action, SwapPricingUtils.SwapFees calldata fees) external onlyController {
        emit SwapFeesCollected(action, fees);
    }

    function emitPositionFeesCollected(bool isIncrease, PositionPricingUtils.PositionFees calldata fees) external onlyController {
        emit PositionFeesCollected(isIncrease, fees);
    }

    function emitOraclePriceUpdated(address token, uint256 minPrice, uint256 maxPrice, bool isPrimary, bool isPriceFeed) external onlyController {
        emit OraclePriceUpdated(token, minPrice, maxPrice, isPrimary, isPriceFeed);
    }

    function emitPositionIncrease(
        bytes32 key,
        address account,
        address market,
        address collateralToken,
        bool isLong,
        uint256 executionPrice,
        uint256 sizeDeltaUsd,
        int256 collateralDeltaAmount
    ) external onlyController {
        emit PositionIncrease(
            key,
            account,
            market,
            collateralToken,
            isLong,
            executionPrice,
            sizeDeltaUsd,
            collateralDeltaAmount
        );
    }

    function emitPositionDecrease(
        bytes32 key,
        address account,
        address market,
        address collateralToken,
        bool isLong,
        uint256 executionPrice,
        uint256 sizeDeltaUsd,
        int256 collateralDeltaAmount,
        int256 positionPnlUsd,
        int256 pnlAmountForPool,
        int256 remainingCollateralAmount,
        uint256 outputAmount
    ) external onlyController {
        emit PositionDecrease(
            key,
            account,
            market,
            collateralToken,
            isLong,
            executionPrice,
            sizeDeltaUsd,
            collateralDeltaAmount,
            positionPnlUsd,
            pnlAmountForPool,
            remainingCollateralAmount,
            outputAmount
        );
    }

    function emitInsufficientFundingFeePayment(uint256 fundingFeeAmount, uint256 collateralAmount) external onlyController {
        emit InsufficientFundingFeePayment(fundingFeeAmount, collateralAmount);
    }

    function log1(bytes32 topic1, bytes memory data) external onlyController {
        uint256 len = data.length;
        assembly {
            log1(add(data, 32), len, topic1)
        }
    }

    function log2(bytes32 topic1, bytes32 topic2, bytes memory data) external onlyController {
        uint256 len = data.length;
        assembly {
            log2(add(data, 32), len, topic1, topic2)
        }
    }

    function log3(bytes32 topic1, bytes32 topic2, bytes32 topic3, bytes memory data) external onlyController {
        uint256 len = data.length;
        assembly {
            log3(add(data, 32), len, topic1, topic2, topic3)
        }
    }

    function log4(bytes32 topic1, bytes32 topic2, bytes32 topic3, bytes32 topic4, bytes memory data) external onlyController {
        uint256 len = data.length;
        assembly {
            log4(add(data, 32), len, topic1, topic2, topic3, topic4)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../data/DataStore.sol";
import "../data/Keys.sol";

library FeatureUtils {
    error BlockedFeature(bytes32 key);

    function isFeatureBlocked(DataStore dataStore, bytes32 key) internal view returns (bool) {
        return dataStore.getBool(key);
    }

    function validateFeature(DataStore dataStore, bytes32 key) internal view {
        if (isFeatureBlocked(dataStore, key)) {
            revert BlockedFeature(key);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Market {
    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
        bytes data;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Deposit {
    struct Props {
        address account;
        address receiver;
        address callbackContract;
        address market;
        uint256 longTokenAmount;
        uint256 shortTokenAmount;
        uint256 minMarketTokens;
        uint256 updatedAtBlock;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
        bytes data;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../bank/Bank.sol";

contract MarketToken is ERC20, Bank {
    constructor(RoleStore _roleStore) ERC20("GMX Market", "GM") Bank(_roleStore) {
    }

    function mint(address account, uint256 amount) external onlyController {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyController {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../bank/StrictBank.sol";
import "./Deposit.sol";

contract DepositStore is StrictBank {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableValues for EnumerableSet.Bytes32Set;

    mapping(bytes32 => Deposit.Props) internal deposits;
    EnumerableSet.Bytes32Set internal depositKeys;

    constructor(RoleStore _roleStore) StrictBank(_roleStore) {}

    function set(bytes32 key, Deposit.Props memory deposit) external onlyController {
        deposits[key] = deposit;
        depositKeys.add(key);
    }

    function remove(bytes32 key) external onlyController {
        delete deposits[key];
        depositKeys.remove(key);
    }

    function get(bytes32 key) external view returns (Deposit.Props memory) {
        return deposits[key];
    }

    function getDepositCount() external view returns (uint256) {
        return depositKeys.length();
    }

    function getDepositKeys(uint256 start, uint256 end) external view returns (bytes32[] memory) {
        return depositKeys.valuesAt(start, end);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Oracle.sol";
import "../event/EventEmitter.sol";

contract OracleModule {
    event OracleError(string reason);

    // care should be taken to avoid re-entrancy while using this call
    // since re-entrancy could allow functions to be called with prices
    // meant for a different type of transaction
    // the tempTokens.length check in oracle.setPrices should help
    // mitigate this
    modifier withOraclePrices(
        Oracle oracle,
        DataStore dataStore,
        EventEmitter eventEmitter,
        OracleUtils.SetPricesParams memory params
    ) {
        try oracle.setPrices(dataStore, eventEmitter, params) {
        } catch Error(string memory reason) {
            emit OracleError(reason);
            revert(Keys.ORACLE_ERROR);
        }
        _;
        oracle.clearTempPrices();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../data/DataStore.sol";
import "../event/EventEmitter.sol";

import "./DepositStore.sol";
import "../market/MarketStore.sol";

import "../nonce/NonceUtils.sol";
import "../pricing/SwapPricingUtils.sol";
import "../oracle/Oracle.sol";
import "../oracle/OracleUtils.sol";

import "../gas/GasUtils.sol";
import "../wrap/WrapUtils.sol";
import "../callback/CallbackUtils.sol";

import "../utils/Array.sol";
import "../utils/Null.sol";

library DepositUtils {
    using SafeCast for uint256;
    using SafeCast for int256;
    using Array for uint256[];

    using Price for Price.Props;

    struct CreateDepositParams {
        address receiver;
        address callbackContract;
        address market;
        uint256 minMarketTokens;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct ExecuteDepositParams {
        DataStore dataStore;
        EventEmitter eventEmitter;
        DepositStore depositStore;
        MarketStore marketStore;
        Oracle oracle;
        FeeReceiver feeReceiver;
        bytes32 key;
        uint256[] oracleBlockNumbers;
        address keeper;
        uint256 startingGas;
    }

    struct _ExecuteDepositParams {
        Market.Props market;
        address account;
        address receiver;
        address tokenIn;
        address tokenOut;
        Price.Props tokenInPrice;
        Price.Props tokenOutPrice;
        uint256 amount;
        int256 priceImpactUsd;
    }

    error MinMarketTokens(uint256 received, uint256 expected);

    function createDeposit(
        DataStore dataStore,
        EventEmitter eventEmitter,
        DepositStore depositStore,
        MarketStore marketStore,
        address account,
        CreateDepositParams memory params
    ) internal returns (bytes32) {
        Market.Props memory market = marketStore.get(params.market);
        MarketUtils.validateNonEmptyMarket(market);

        uint256 longTokenAmount = depositStore.recordTransferIn(market.longToken);
        uint256 shortTokenAmount = depositStore.recordTransferIn(market.shortToken);

        address wnt = WrapUtils.wnt(dataStore);

        if (market.longToken == wnt) {
            longTokenAmount -= params.executionFee;
        } else if (market.shortToken == wnt) {
            shortTokenAmount -= params.executionFee;
        } else {
            uint256 wntAmount = depositStore.recordTransferIn(wnt);
            require(wntAmount == params.executionFee, "DepositUtils: invalid wntAmount");
        }

        Deposit.Props memory deposit = Deposit.Props(
            account,
            params.receiver,
            params.callbackContract,
            market.marketToken,
            longTokenAmount,
            shortTokenAmount,
            params.minMarketTokens,
            Chain.currentBlockNumber(),
            params.shouldUnwrapNativeToken,
            params.executionFee,
            params.callbackGasLimit,
            Null.BYTES
        );

        uint256 estimatedGasLimit = GasUtils.estimateExecuteDepositGasLimit(dataStore, deposit);
        GasUtils.validateExecutionFee(dataStore, estimatedGasLimit, params.executionFee);

        bytes32 key = NonceUtils.getNextKey(dataStore);

        depositStore.set(key, deposit);

        eventEmitter.emitDepositCreated(key, deposit);

        return key;
    }

    function executeDeposit(ExecuteDepositParams memory params) internal {
        Deposit.Props memory deposit = params.depositStore.get(params.key);
        require(deposit.account != address(0), "DepositUtils: empty deposit");

        if (!params.oracleBlockNumbers.areEqualTo(deposit.updatedAtBlock)) {
            revert(Keys.ORACLE_ERROR);
        }

        CallbackUtils.beforeDepositExecution(params.key, deposit);

        Market.Props memory market = params.marketStore.get(deposit.market);

        Price.Props memory longTokenPrice = params.oracle.getPrimaryPrice(market.longToken);
        Price.Props memory shortTokenPrice = params.oracle.getPrimaryPrice(market.shortToken);

        uint256 longTokenUsd = deposit.longTokenAmount * longTokenPrice.midPrice();
        uint256 shortTokenUsd = deposit.shortTokenAmount * shortTokenPrice.midPrice();

        uint256 receivedMarketTokens;

        int256 priceImpactUsd = SwapPricingUtils.getPriceImpactUsd(
            SwapPricingUtils.GetPriceImpactUsdParams(
                params.dataStore,
                market.marketToken,
                market.longToken,
                market.shortToken,
                longTokenPrice.midPrice(),
                shortTokenPrice.midPrice(),
                (deposit.longTokenAmount * longTokenPrice.midPrice()).toInt256(),
                (deposit.shortTokenAmount * shortTokenPrice.midPrice()).toInt256()
            )
        );

        // since tokens were recorded as transferred in during the createDeposit step
        // to save gas costs we assume that _transferOut should always correctly transfer the tokens
        // to the marketToken
        // it is possible for a token to return true even if the transfer is not entirely fulfilled
        // this should still work unless the token has custom behavior that conditionally blocks transfers
        // even if the sender has sufficient balance
        // this will not work correctly for tokens with a burn mechanism, those need to be separately handled
        if (deposit.longTokenAmount > 0) {
            params.depositStore.transferOut(market.longToken, deposit.longTokenAmount, market.marketToken);

            _ExecuteDepositParams memory _params = _ExecuteDepositParams(
                market,
                deposit.account,
                deposit.receiver,
                market.longToken,
                market.shortToken,
                longTokenPrice,
                shortTokenPrice,
                deposit.longTokenAmount,
                priceImpactUsd * longTokenUsd.toInt256() / (longTokenUsd + shortTokenUsd).toInt256()
            );

            receivedMarketTokens += _executeDeposit(params, _params);
        }

        if (deposit.shortTokenAmount > 0) {
            params.depositStore.transferOut(market.shortToken, deposit.shortTokenAmount, market.marketToken);

            _ExecuteDepositParams memory _params = _ExecuteDepositParams(
                market,
                deposit.account,
                deposit.receiver,
                market.shortToken,
                market.longToken,
                shortTokenPrice,
                longTokenPrice,
                deposit.shortTokenAmount,
                priceImpactUsd * shortTokenUsd.toInt256() / (longTokenUsd + shortTokenUsd).toInt256()
            );

            receivedMarketTokens += _executeDeposit(params, _params);
        }

        if (receivedMarketTokens < deposit.minMarketTokens) {
            revert MinMarketTokens(receivedMarketTokens, deposit.minMarketTokens);
        }

        params.depositStore.remove(params.key);

        params.eventEmitter.emitDepositExecuted(params.key);

        CallbackUtils.afterDepositExecution(params.key, deposit);

        GasUtils.payExecutionFee(
            params.dataStore,
            params.depositStore,
            deposit.executionFee,
            params.startingGas,
            params.keeper,
            deposit.account
        );
    }

    function cancelDeposit(
        DataStore dataStore,
        EventEmitter eventEmitter,
        DepositStore depositStore,
        MarketStore marketStore,
        bytes32 key,
        address keeper,
        uint256 startingGas
    ) internal {
        Deposit.Props memory deposit = depositStore.get(key);
        require(deposit.account != address(0), "DepositUtils: empty deposit");

        Market.Props memory market = marketStore.get(deposit.market);
        if (deposit.longTokenAmount > 0) {
            depositStore.transferOut(
                WrapUtils.wnt(dataStore),
                market.longToken,
                deposit.longTokenAmount,
                deposit.account,
                deposit.shouldUnwrapNativeToken
            );
        }

        if (deposit.shortTokenAmount > 0) {
            depositStore.transferOut(
                WrapUtils.wnt(dataStore),
                market.shortToken,
                deposit.shortTokenAmount,
                deposit.account,
                deposit.shouldUnwrapNativeToken
            );
        }

        depositStore.remove(key);

        eventEmitter.emitDepositCancelled(key);

        CallbackUtils.afterDepositCancellation(key, deposit);

        GasUtils.payExecutionFee(
            dataStore,
            depositStore,
            deposit.executionFee,
            startingGas,
            keeper,
            deposit.account
        );
    }

    function _executeDeposit(ExecuteDepositParams memory params, _ExecuteDepositParams memory _params) internal returns (uint256) {
        SwapPricingUtils.SwapFees memory fees = SwapPricingUtils.getSwapFees(
            params.dataStore,
            _params.market.marketToken,
            _params.amount,
            Keys.FEE_RECEIVER_DEPOSIT_FACTOR
        );

        PricingUtils.transferFees(
            params.feeReceiver,
            _params.market.marketToken,
            _params.tokenIn,
            fees.feeReceiverAmount,
            FeeUtils.DEPOSIT_FEE
        );

        params.eventEmitter.emitSwapFeesCollected(keccak256(abi.encode("deposit")), fees);

        return _processDeposit(params, _params, fees.amountAfterFees, fees.feesForPool);
    }

    function _processDeposit(
        ExecuteDepositParams memory params,
        _ExecuteDepositParams memory _params,
        uint256 amountAfterFees,
        uint256 feesForPool
    ) internal returns (uint256) {
        uint256 mintAmount;

        uint256 poolValue = MarketUtils.getPoolValue(
            params.dataStore,
            _params.market,
            _params.tokenIn == _params.market.longToken ? _params.tokenInPrice : _params.tokenOutPrice,
            _params.tokenIn == _params.market.shortToken ? _params.tokenInPrice : _params.tokenOutPrice,
            params.oracle.getPrimaryPrice(_params.market.indexToken),
            true
        );
        uint256 supply = MarketUtils.getMarketTokenSupply(MarketToken(payable(_params.market.marketToken)));

        if (_params.priceImpactUsd > 0) {
            // when there is a positive price impact factor,
            // tokens from the swap impact pool are used to mint additional market tokens for the user
            // for example, if 50,000 USDC is deposited and there is a positive price impact
            // an additional 0.005 ETH may be used to mint market tokens
            // the swap impact pool is decreased by the used amount
            //
            // priceImpactUsd is calculated based on pricing assuming only depositAmount of tokenIn
            // was added to the pool
            // since impactAmount of tokenOut is added to the pool here, the calculation of
            // the tokenInPrice would not be entirely accurate
            int256 positiveImpactAmount = MarketUtils.applySwapImpactWithCap(
                params.dataStore,
                params.eventEmitter,
                _params.market.marketToken,
                _params.tokenOut,
                _params.tokenOutPrice,
                _params.priceImpactUsd
            );

            // calculate the usd amount using positiveImpactAmount since it may
            // be capped by the max available amount in the impact pool
            mintAmount += MarketUtils.usdToMarketTokenAmount(
                positiveImpactAmount.toUint256() * _params.tokenOutPrice.min,
                poolValue,
                supply
            );

            // deposit the token out, that was withdrawn from the impact pool, to mint market tokens
            MarketUtils.applyDeltaToPoolAmount(
                params.dataStore,
                params.eventEmitter,
                _params.market.marketToken,
                _params.tokenOut,
                positiveImpactAmount
            );
        } else {
            // when there is a negative price impact factor,
            // less of the deposit amount is used to mint market tokens
            // for example, if 10 ETH is deposited and there is a negative price impact
            // only 9.995 ETH may be used to mint market tokens
            // the remaining 0.005 ETH will be stored in the swap impact pool
            int256 negativeImpactAmount = MarketUtils.applySwapImpactWithCap(
                params.dataStore,
                params.eventEmitter,
                _params.market.marketToken,
                _params.tokenIn,
                _params.tokenInPrice,
                _params.priceImpactUsd
            );
            amountAfterFees -= (-negativeImpactAmount).toUint256();
        }

        mintAmount += MarketUtils.usdToMarketTokenAmount(
            amountAfterFees * _params.tokenInPrice.min,
            poolValue,
            supply
        );

        MarketUtils.applyDeltaToPoolAmount(
            params.dataStore,
            params.eventEmitter,
            _params.market.marketToken,
            _params.tokenIn,
            (amountAfterFees + feesForPool).toInt256()
        );

        MarketToken(payable(_params.market.marketToken)).mint(_params.receiver, mintAmount);

        return mintAmount;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../role/RoleModule.sol";

import "./OracleStore.sol";
import "./OracleUtils.sol";
import "./IPriceFeed.sol";
import "../price/Price.sol";

import "../chain/Chain.sol";
import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../event/EventEmitter.sol";

import "../utils/Bits.sol";
import "../utils/Array.sol";
import "../utils/Precision.sol";

contract Oracle is RoleModule {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;
    using Price for Price.Props;

    struct _SetPricesCache {
        uint256 minBlockConfirmations;
        uint256 prevOracleBlockNumber;
        uint256 oracleBlockNumber;
        bytes32 blockHash;
        address token;
        uint256 precision;
        bytes32 tokenOracleType;
        uint256 priceIndex;
        uint256 signatureIndex;
        uint256 maxBlockAge;
        uint256[] minPrices;
        uint256[] maxPrices;
    }

    bytes32 public immutable SALT;

    uint256 public constant SIGNER_INDEX_LENGTH = 16;
    // subtract 1 as the first slot is used to store number of signers
    uint256 public constant MAX_SIGNERS = 256 / SIGNER_INDEX_LENGTH - 1;
    // signer indexes are recorded in a signerIndexFlags uint256 value to check for uniqueness
    uint256 public constant MAX_SIGNER_INDEX = 256;

    OracleStore public oracleStore;

    // tempTokens stores the tokens with prices that have been set
    // this is used in clearTempPrices to help ensure that all token prices
    // set in setPrices are cleared after use
    EnumerableSet.AddressSet internal tempTokens;
    // prices for the same token can be sent multiple times in one txn
    // the prices can be for different block numbers
    // the first occurrence of the token's price will be stored in primaryPrices
    // the second occurrence will be stored in secondaryPrices
    mapping(address => Price.Props) public primaryPrices;
    mapping(address => Price.Props) public secondaryPrices;
    // customPrices can be used to store custom price values
    // these prices will be cleared in clearTempPrices
    mapping(address => Price.Props) public customPrices;

    error EmptyTokens();
    error InvalidBlockNumber(uint256 blockNumber);
    error MaxBlockAgeExceeded(uint256 blockNumber);
    error MinOracleSigners(uint256 oracleSigners, uint256 minOracleSigners);
    error MaxOracleSigners(uint256 oracleSigners, uint256 maxOracleSigners);
    error BlockNumbersNotSorted(uint256 oracleBlockNumber, uint256 prevOracleBlockNumber);
    error MinPricesNotSorted(address token, uint256 price, uint256 prevPrice);
    error MaxPricesNotSorted(address token, uint256 price, uint256 prevPrice);
    error EmptyPriceFeedMultiplier(address token);
    error EmptyFeedPrice(address token);
    error InvalidSignature(address recoveredSigner, address expectedSigner);
    error MaxSignerIndex(uint256 signerIndex, uint256 maxSignerIndex);
    error DuplicateSigner(uint256 signerIndex);
    error EmptyPrice(address token);
    error EmptyPrimaryPrice(address token);
    error EmptySecondaryPrice(address token);
    error EmptyLatestPrice(address token);
    error EmptyCustomPrice(address token);

    constructor(
        RoleStore _roleStore,
        OracleStore _oracleStore
    ) RoleModule(_roleStore) {
        oracleStore = _oracleStore;

        // sign prices with only the chainid and oracle name so that there is
        // less config required in the oracle nodes
        SALT = keccak256(abi.encode(block.chainid, "xget-oracle-v1"));
    }

    function setPrices(
        DataStore dataStore,
        EventEmitter eventEmitter,
        OracleUtils.SetPricesParams memory params
    ) external onlyController {
        require(tempTokens.length() == 0, "Oracle: tempTokens not cleared");

        if (params.tokens.length == 0) { revert EmptyTokens(); }

        // first 16 bits of signer info contains the number of signers
        address[] memory signers = new address[](params.signerInfo & Bits.BITMASK_16);

        if (signers.length < dataStore.getUint(Keys.MIN_ORACLE_SIGNERS)) {
            revert MinOracleSigners(signers.length, dataStore.getUint(Keys.MIN_ORACLE_SIGNERS));
        }

        if (signers.length > MAX_SIGNERS) {
            revert MaxOracleSigners(signers.length, MAX_SIGNERS);
        }

        uint256 signerIndexFlags;

        for (uint256 i = 0; i < signers.length; i++) {
            uint256 signerIndex = params.signerInfo >> (16 + 16 * i) & Bits.BITMASK_16;

            if (signerIndex >= MAX_SIGNER_INDEX) {
                revert MaxSignerIndex(signerIndex, MAX_SIGNER_INDEX);
            }

            uint256 signerIndexBit = 1 << signerIndex;

            if (signerIndexFlags & signerIndexBit != 0) {
                revert DuplicateSigner(signerIndex);
            }

            signerIndexFlags = signerIndexFlags | signerIndexBit;

            signers[i] = oracleStore.getSigner(signerIndex);
        }

        _setPrices(
            dataStore,
            eventEmitter,
            signers,
            params
        );

        _setPricesFromPriceFeeds(dataStore, eventEmitter, params.priceFeedTokens);
    }

    function setSecondaryPrice(address token, Price.Props memory price) external onlyController {
        secondaryPrices[token] = price;
    }

    function setCustomPrice(address token, Price.Props memory price) external onlyController {
        customPrices[token] = price;
    }

    function clearTempPrices() external onlyController {
        uint256 length = tempTokens.length();
        for (uint256 i = 0; i < length; i++) {
            address token = tempTokens.at(0);
            delete primaryPrices[token];
            delete secondaryPrices[token];
            delete customPrices[token];
            tempTokens.remove(token);
        }
    }

    function getTempTokensCount() external view returns (uint256) {
        return tempTokens.length();
    }

    function getTempTokens(uint256 start, uint256 end) external view returns (address[] memory) {
        return tempTokens.valuesAt(start, end);
    }

    function getPrimaryPrice(address token) external view returns (Price.Props memory) {
        Price.Props memory price = primaryPrices[token];
        if (price.isEmpty()) { revert EmptyPrimaryPrice(token); }
        return price;
    }

    function getSecondaryPrice(address token) external view returns (Price.Props memory) {
        Price.Props memory price = secondaryPrices[token];
        if (price.isEmpty()) { revert EmptySecondaryPrice(token); }
        return price;
    }

    function getLatestPrice(address token) external view returns (Price.Props memory) {
        Price.Props memory primaryPrice = primaryPrices[token];
        Price.Props memory secondaryPrice = secondaryPrices[token];

        if (!secondaryPrice.isEmpty()) {
            return secondaryPrice;
        }

        if (!primaryPrice.isEmpty()) {
            return primaryPrice;
        }

        revert EmptyLatestPrice(token);
    }

    function getCustomPrice(address token) external view returns (Price.Props memory) {
        Price.Props memory price = customPrices[token];
        if (price.isEmpty()) { revert EmptyCustomPrice(token); }
        return price;
    }

    function getPriceFeed(DataStore dataStore, address token) public view returns (IPriceFeed) {
        address priceFeedAddress = dataStore.getAddress(Keys.priceFeedKey(token));
        require(priceFeedAddress != address(0), "Oracle: invalid price feed");

        return IPriceFeed(priceFeedAddress);
    }

    function getStablePrice(DataStore dataStore, address token) public view returns (uint256) {
        return dataStore.getUint(Keys.stablePriceKey(token));
    }

    // return the multiplier value to convert the external price feed price to the price of 1 unit of the token
    // represented with 30 decimals
    // for example, if USDC has 6 decimals and a price of 1 USD, one unit of USDC would have a price of
    // 1 / (10 ^ 6) * (10 ^ 30) => 1 * (10 ^ 24)
    // if the external price feed has 8 decimals, the price feed price would be 1 * (10 ^ 8)
    // in this case the priceFeedMultiplier should be 10 ^ 46
    // the conversion of the price feed price would be 1 * (10 ^ 8) * (10 ^ 46) / (10 ^ 30) => 1 * (10 ^ 24)
    // formula for decimals for price feed multiplier: 60 - (external price feed decimals) - (token decimals)
    function getPriceFeedMultiplier(DataStore dataStore, address token) public view returns (uint256) {
        uint256 multiplier = dataStore.getUint(Keys.priceFeedMultiplierKey(token));

        if (multiplier == 0) {
            revert EmptyPriceFeedMultiplier(token);
        }

        return multiplier;
    }

    function _setPrices(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address[] memory signers,
        OracleUtils.SetPricesParams memory params
    ) internal {
        _SetPricesCache memory cache;
        cache.minBlockConfirmations = dataStore.getUint(Keys.MIN_ORACLE_BLOCK_CONFIRMATIONS);
        cache.maxBlockAge = dataStore.getUint(Keys.MAX_ORACLE_BLOCK_AGE);

        for (uint256 i = 0; i < params.tokens.length; i++) {
            cache.oracleBlockNumber = OracleUtils.getUncompactedOracleBlockNumber(params.compactedOracleBlockNumbers, i);

            if (cache.oracleBlockNumber > Chain.currentBlockNumber()) {
                revert InvalidBlockNumber(cache.oracleBlockNumber);
            }

            if (cache.oracleBlockNumber + cache.maxBlockAge < Chain.currentBlockNumber()) {
                revert MaxBlockAgeExceeded(cache.oracleBlockNumber);
            }

            // block numbers must be in ascending order
            if (cache.oracleBlockNumber < cache.prevOracleBlockNumber) {
                revert BlockNumbersNotSorted(cache.oracleBlockNumber, cache.prevOracleBlockNumber);
            }
            cache.prevOracleBlockNumber = cache.oracleBlockNumber;

            cache.blockHash = bytes32(0);
            if (Chain.currentBlockNumber() - cache.oracleBlockNumber <= cache.minBlockConfirmations) {
                cache.blockHash = Chain.getBlockHash(cache.oracleBlockNumber);
            }

            cache.token = params.tokens[i];
            cache.precision = OracleUtils.getUncompactedPrecision(params.compactedDecimals, i);
            cache.tokenOracleType = dataStore.getData(Keys.oracleTypeKey(cache.token));

            cache.minPrices = new uint256[](signers.length);
            cache.maxPrices = new uint256[](signers.length);

            for (uint256 j = 0; j < signers.length; j++) {
                cache.priceIndex = i * signers.length + j;
                cache.minPrices[j] = OracleUtils.getUncompactedPrice(params.compactedMinPrices, cache.priceIndex);
                cache.maxPrices[j] = OracleUtils.getUncompactedPrice(params.compactedMaxPrices, cache.priceIndex);

                if (j == 0) { continue; }

                // validate that minPrices are sorted in ascending order
                if (cache.minPrices[j - 1] > cache.minPrices[j]) {
                    revert MinPricesNotSorted(cache.token, cache.minPrices[j], cache.minPrices[j - 1]);
                }

                // validate that maxPrices are sorted in ascending order
                if (cache.maxPrices[j - 1] > cache.maxPrices[j]) {
                    revert MaxPricesNotSorted(cache.token, cache.maxPrices[j], cache.maxPrices[j - 1]);
                }
            }

            for (uint256 j = 0; j < signers.length; j++) {
                cache.signatureIndex = i * signers.length + j;
                uint256 minPriceIndex = OracleUtils.getUncompactedPriceIndex(params.compactedMinPricesIndexes, cache.signatureIndex);
                uint256 maxPriceIndex = OracleUtils.getUncompactedPriceIndex(params.compactedMaxPricesIndexes, cache.signatureIndex);

                _validateSigner(
                    cache.oracleBlockNumber,
                    cache.blockHash,
                    cache.token,
                    cache.tokenOracleType,
                    cache.precision,
                    cache.minPrices[minPriceIndex],
                    cache.maxPrices[maxPriceIndex],
                    params.signatures[cache.signatureIndex],
                    signers[j]
                );
            }

            uint256 medianMinPrice = Array.getMedian(cache.minPrices) * cache.precision;
            uint256 medianMaxPrice = Array.getMedian(cache.maxPrices) * cache.precision;

            if (medianMinPrice == 0 || medianMaxPrice == 0) {
                revert EmptyPrice(cache.token);
            }

            if (primaryPrices[cache.token].isEmpty()) {
                eventEmitter.emitOraclePriceUpdated(cache.token, medianMinPrice, medianMaxPrice, true, false);

                primaryPrices[cache.token] = Price.Props(
                    medianMinPrice,
                    medianMaxPrice
                );
            } else {
                eventEmitter.emitOraclePriceUpdated(cache.token, medianMinPrice, medianMaxPrice, false, false);

                secondaryPrices[cache.token] = Price.Props(
                    medianMinPrice,
                    medianMaxPrice
                );
            }

            tempTokens.add(cache.token);
        }
    }

    // set prices using Chainlink price feeds to save costs for tokens with stable prices
    function _setPricesFromPriceFeeds(DataStore dataStore, EventEmitter eventEmitter, address[] memory priceFeedTokens) internal {
        for (uint256 i = 0; i < priceFeedTokens.length; i++) {
            address token = priceFeedTokens[i];

            require(primaryPrices[token].isEmpty(), "Oracle: price already set");

            IPriceFeed priceFeed = getPriceFeed(dataStore, token);

            (
                /* uint80 roundID */,
                int256 _price,
                /* uint256 startedAt */,
                /* uint256 timeStamp */,
                /* uint80 answeredInRound */
            ) = priceFeed.latestRoundData();

            uint256 price = SafeCast.toUint256(_price);
            uint256 precision = getPriceFeedMultiplier(dataStore, token);

            price = price * precision / Precision.FLOAT_PRECISION;

            if (price == 0) {
                revert EmptyFeedPrice(token);
            }

            uint256 stablePrice = getStablePrice(dataStore, token);

            Price.Props memory priceProps;

            if (stablePrice > 0) {
                priceProps = Price.Props(
                    price < stablePrice ? price : stablePrice,
                    price < stablePrice ? stablePrice : price
                );
            } else {
                priceProps = Price.Props(
                    price,
                    price
                );
            }

            primaryPrices[token] = priceProps;

            tempTokens.add(token);

            eventEmitter.emitOraclePriceUpdated(token, priceProps.min, priceProps.max, true, true);
        }
    }

    function _validateSigner(
        uint256 oracleBlockNumber,
        bytes32 blockHash,
        address token,
        bytes32 tokenOracleType,
        uint256 precision,
        uint256 minPrice,
        uint256 maxPrice,
        bytes memory signature,
        address expectedSigner
    ) internal view {
        bytes32 digest = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encode(
                SALT,
                oracleBlockNumber,
                blockHash,
                token,
                tokenOracleType,
                precision,
                minPrice,
                maxPrice
            ))
        );

        address recoveredSigner = ECDSA.recover(digest, signature);
        if (recoveredSigner != expectedSigner) {
            revert InvalidSignature(recoveredSigner, expectedSigner);
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./RoleStore.sol";
import "./Role.sol";
import "../gov/Governable.sol";

contract RoleModule is Governable {
    RoleStore public immutable roleStore;

    constructor(RoleStore _roleStore) {
        roleStore = _roleStore;
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert Unauthorized(msg.sender, "SELF");
        }
        _;
    }

    modifier onlyController() {
        _validateRole(Role.CONTROLLER, "CONTROLLER");
        _;
    }

    modifier onlyRouterPlugin() {
        _validateRole(Role.ROUTER_PLUGIN, "ROUTER_PLUGIN");
        _;
    }

    modifier onlyMarketKeeper() {
        _validateRole(Role.MARKET_KEEPER, "MARKET_KEEPER");
        _;
    }

    modifier onlyOrderKeeper() {
        _validateRole(Role.ORDER_KEEPER, "ORDER_KEEPER");
        _;
    }

    modifier onlyPricingKeeper() {
        _validateRole(Role.PRICING_KEEPER, "PRICING_KEEPER");
        _;
    }

    modifier onlyLiquidationKeeper() {
        _validateRole(Role.LIQUIDATION_KEEPER, "LIQUIDATION_KEEPER");
        _;
    }

    modifier onlyAdlKeeper() {
        _validateRole(Role.ADL_KEEPER, "ADL_KEEPER");
        _;
    }

    function _validateRole(bytes32 role, string memory roleName) internal view {
        if (!roleStore.hasRole(msg.sender, role)) {
            revert Unauthorized(msg.sender, roleName);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Role {
    bytes32 public constant CONTROLLER = keccak256(abi.encode("CONTROLLER"));
    bytes32 public constant ROUTER_PLUGIN = keccak256(abi.encode("ROUTER_PLUGIN"));
    bytes32 public constant MARKET_KEEPER = keccak256(abi.encode("MARKET_KEEPER"));
    bytes32 public constant ORDER_KEEPER = keccak256(abi.encode("ORDER_KEEPER"));
    bytes32 public constant FROZEN_ORDER_KEEPER = keccak256(abi.encode("FROZEN_ORDER_KEEPER"));
    bytes32 public constant PRICING_KEEPER = keccak256(abi.encode("PRICING_KEEPER"));
    bytes32 public constant LIQUIDATION_KEEPER = keccak256(abi.encode("LIQUIDATION_KEEPER"));
    bytes32 public constant ADL_KEEPER = keccak256(abi.encode("ADL_KEEPER"));
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/EnumerableValues.sol";
import "../gov/Governable.sol";

contract RoleStore is Governable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableValues for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set internal roles;
    mapping(bytes32 => EnumerableSet.AddressSet) internal roleMembers;
    // checking if an account has a role is a frequently used function
    // roleCache helps to save gas by offering a more efficient lookup
    // vs calling roleMembers[key].contains(account)
    mapping(address => mapping (bytes32 => bool)) roleCache;

    function grantRole(address account, bytes32 key) external onlyGov {
        roles.add(key);
        roleMembers[key].add(account);
        roleCache[account][key] = true;
    }

    function revokeRole(address account, bytes32 key) external onlyGov {
        roleMembers[key].remove(account);
        roleCache[account][key] = false;
    }

    function hasRole(address account, bytes32 key) external view returns (bool) {
        return roleCache[account][key];
    }

    function getRoleCount() external view returns (uint256) {
        return roles.length();
    }

    function getRoles(uint256 start, uint256 end) external view returns (bytes32[] memory) {
        return roles.valuesAt(start, end);
    }

    function getRoleMemberCount(bytes32 key) external view returns (uint256) {
        return roleMembers[key].length();
    }

    function getRoleMembers(bytes32 key, uint256 start, uint256 end) external view returns (address[] memory) {
        return roleMembers[key].valuesAt(start, end);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

contract Governable {
    address public gov;

    event SetGov(address prevGov, address nextGov);

    error Unauthorized(address msgSender, string role);

    constructor() {
        _setGov(msg.sender);
    }

    modifier onlyGov() {
        if (msg.sender != gov) {
            revert Unauthorized(msg.sender, "GOV");
        }
        _;
    }

    function setGov(address _gov) external onlyGov {
        _setGov(_gov);
    }

    function _setGov(address _gov) internal {
        address prevGov = gov;
        gov = _gov;

        emit SetGov(prevGov, _gov);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library EnumerableValues {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    function valuesAt(EnumerableSet.Bytes32Set storage set, uint256 start, uint256 end) internal view returns (bytes32[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        bytes32[] memory items = new bytes32[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    function valuesAt(EnumerableSet.AddressSet storage set, uint256 start, uint256 end) internal view returns (address[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        address[] memory items = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    function valuesAt(EnumerableSet.UintSet storage set, uint256 start, uint256 end) internal view returns (uint256[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        uint256[] memory items = new uint256[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../market/MarketUtils.sol";

import "../utils/Precision.sol";
import "../utils/Calc.sol";

import "./PricingUtils.sol";

import "../referral/IReferralStorage.sol";
import "../referral/ReferralUtils.sol";

library PositionPricingUtils {
    using SafeCast for uint256;
    using SafeCast for int256;

    struct GetPriceImpactUsdParams {
        DataStore dataStore;
        address market;
        address longToken;
        address shortToken;
        int256 usdDelta;
        bool isLong;
    }

    struct OpenInterestParams {
        uint256 longOpenInterest;
        uint256 shortOpenInterest;
        uint256 nextLongOpenInterest;
        uint256 nextShortOpenInterest;
    }

    struct PositionFees {
        address affiliate;
        uint256 traderDiscountAmount;
        uint256 affiliateRewardAmount;
        uint256 feeReceiverAmount;
        uint256 feesForPool;
        uint256 positionFeeAmountForPool;
        uint256 positionFeeAmount;
        uint256 fundingFeeAmount;
        int256 latestLongTokenFundingAmountPerSize;
        int256 latestShortTokenFundingAmountPerSize;
        int256 longTokenFundingFeeAmount;
        int256 shortTokenFundingFeeAmount;
        uint256 borrowingFeeAmount;
        uint256 totalNetCostAmount;
        uint256 totalNetCostUsd;
        bool hasPendingLongTokenFundingFee;
        bool hasPendingShortTokenFundingFee;
    }

    struct _GetPositionFeesAfterReferralCache {
        address affiliate;
        uint256 totalRebateFactor;
        uint256 traderDiscountFactor;
        uint256 feeFactor;
        uint256 positionFeeAmount;
        uint256 totalRebateAmount;
        uint256 traderDiscountAmount;
        uint256 affiliateRewardAmount;
        uint256 protocolFeeAmount;
        uint256 feeReceiverFactor;
        uint256 feeReceiverAmount;
        uint256 positionFeeAmountForPool;
    }

    function getPriceImpactAmount(
        uint256 size,
        uint256 executionPrice,
        uint256 latestPrice,
        bool isLong,
        bool isIncrease
    ) internal pure returns (int256) {
        // increase order:
        //     - long: price impact is size * (latestPrice - executionPrice) / latestPrice
        //             when executionPrice is smaller than latestPrice there is a positive price impact
        //     - short: price impact is size * (executionPrice - latestPrice) / latestPrice
        //              when executionPrice is larger than latestPrice there is a positive price impact
        // decrease order:
        //     - long: price impact is size * (executionPrice - latestPrice) / latestPrice
        //             when executionPrice is larger than latestPrice there is a positive price impact
        //     - short: price impact is size * (latestPrice - executionPrice) / latestPrice
        //              when executionPrice is smaller than latestPrice there is a positive price impact
        int256 priceDiff = latestPrice.toInt256() - executionPrice.toInt256();
        bool shouldFlipPriceDiff = isIncrease ? !isLong : isLong;
        if (shouldFlipPriceDiff) { priceDiff = -priceDiff; }

        int256 priceImpactUsd = size.toInt256() * priceDiff / latestPrice.toInt256();

        // round positive price impact up, this will be deducted from the position impact pool
        if (priceImpactUsd > 0) {
            return Calc.roundUpDivision(priceImpactUsd, latestPrice);
        }

        // round negative price impact down, this will be stored in the position impact pool
        return priceImpactUsd / latestPrice.toInt256();
    }

    function getPriceImpactUsd(GetPriceImpactUsdParams memory params) internal view returns (int256) {
        OpenInterestParams memory openInterestParams = getNextOpenInterest(params);

        int256 priceImpactUsd = _getPriceImpactUsd(params.dataStore, params.market, openInterestParams);

        return priceImpactUsd;
    }

    function _getPriceImpactUsd(DataStore dataStore, address market, OpenInterestParams memory openInterestParams) internal view returns (int256) {
        uint256 initialDiffUsd = Calc.diff(openInterestParams.longOpenInterest, openInterestParams.shortOpenInterest);
        uint256 nextDiffUsd = Calc.diff(openInterestParams.nextLongOpenInterest, openInterestParams.nextShortOpenInterest);

        // check whether an improvement in balance comes from causing the balance to switch sides
        // for example, if there is $2000 of ETH and $1000 of USDC in the pool
        // adding $1999 USDC into the pool will reduce absolute balance from $1000 to $999 but it does not
        // help rebalance the pool much, the isSameSideRebalance value helps avoid gaming using this case
        bool isSameSideRebalance = openInterestParams.longOpenInterest <= openInterestParams.shortOpenInterest == openInterestParams.nextLongOpenInterest <= openInterestParams.nextShortOpenInterest;
        uint256 impactExponentFactor = dataStore.getUint(Keys.positionImpactExponentFactorKey(market));

        if (isSameSideRebalance) {
            bool hasPositiveImpact = nextDiffUsd < initialDiffUsd;
            uint256 impactFactor = dataStore.getUint(Keys.positionImpactFactorKey(market, hasPositiveImpact));

            return PricingUtils.getPriceImpactUsdForSameSideRebalance(
                initialDiffUsd,
                nextDiffUsd,
                hasPositiveImpact,
                impactFactor,
                impactExponentFactor
            );
        } else {
            uint256 positiveImpactFactor = dataStore.getUint(Keys.positionImpactFactorKey(market, true));
            uint256 negativeImpactFactor = dataStore.getUint(Keys.positionImpactFactorKey(market, false));

            return PricingUtils.getPriceImpactUsdForCrossoverRebalance(
                initialDiffUsd,
                nextDiffUsd,
                positiveImpactFactor,
                negativeImpactFactor,
                impactExponentFactor
            );
        }
    }

    function getNextOpenInterest(
        GetPriceImpactUsdParams memory params
    ) internal view returns (OpenInterestParams memory) {
        uint256 longOpenInterest = MarketUtils.getOpenInterest(
            params.dataStore,
            params.market,
            params.longToken,
            params.shortToken,
            true);

        uint256 shortOpenInterest = MarketUtils.getOpenInterest(
            params.dataStore,
            params.market,
            params.longToken,
            params.shortToken,
            false
        );

        uint256 nextLongOpenInterest;
        uint256 nextShortOpenInterest;

        if (params.isLong) {
            nextLongOpenInterest = Calc.sum(longOpenInterest, params.usdDelta);
        } else {
            nextShortOpenInterest = Calc.sum(shortOpenInterest, params.usdDelta);
        }

        OpenInterestParams memory openInterestParams = OpenInterestParams(
            longOpenInterest,
            shortOpenInterest,
            nextLongOpenInterest,
            nextShortOpenInterest
        );

        return openInterestParams;
    }

    function transferPositionFees(
        FeeReceiver feeReceiver,
        MarketToken marketToken,
        Position.Props memory position,
        bytes32 feeType,
        PositionFees memory fees
    ) internal returns (PositionFees memory) {
        if (fees.feeReceiverAmount > 0) {
            marketToken.transferOut(position.collateralToken, fees.feeReceiverAmount, address(feeReceiver));
            feeReceiver.notifyFeeReceived(feeType, position.collateralToken, fees.feeReceiverAmount);
        }

        return fees;
    }

    function getPositionFees(
        DataStore dataStore,
        IReferralStorage referralStorage,
        Position.Props memory position,
        Price.Props memory collateralTokenPrice,
        address longToken,
        address shortToken,
        uint256 sizeDeltaUsd
    ) internal view returns (PositionFees memory) {
        PositionFees memory fees;

        (
            fees.affiliate,
            fees.traderDiscountAmount,
            fees.affiliateRewardAmount,
            fees.feeReceiverAmount,
            fees.positionFeeAmountForPool
        ) = getPositionFeesAfterReferral(
            dataStore,
            referralStorage,
            collateralTokenPrice,
            position.account,
            position.market,
            sizeDeltaUsd
        );

        fees.borrowingFeeAmount = MarketUtils.getBorrowingFees(dataStore, position) / collateralTokenPrice.min;

        fees.feesForPool = fees.positionFeeAmountForPool + fees.borrowingFeeAmount;

        fees.latestLongTokenFundingAmountPerSize = MarketUtils.getFundingAmountPerSize(dataStore, position.market, longToken, position.isLong);
        fees.latestShortTokenFundingAmountPerSize = MarketUtils.getFundingAmountPerSize(dataStore, position.market, shortToken, position.isLong);

        (fees.hasPendingLongTokenFundingFee, fees.longTokenFundingFeeAmount) = MarketUtils.getFundingFeeAmount(fees.latestLongTokenFundingAmountPerSize, position.longTokenFundingAmountPerSize, position.sizeInUsd);
        (fees.hasPendingShortTokenFundingFee, fees.shortTokenFundingFeeAmount) = MarketUtils.getFundingFeeAmount(fees.latestShortTokenFundingAmountPerSize, position.shortTokenFundingAmountPerSize, position.sizeInUsd);

        if (position.collateralToken == longToken && fees.longTokenFundingFeeAmount > 0) {
            fees.fundingFeeAmount = fees.longTokenFundingFeeAmount.toUint256();
        }
        if (position.collateralToken == shortToken && fees.shortTokenFundingFeeAmount > 0) {
            fees.fundingFeeAmount = fees.shortTokenFundingFeeAmount.toUint256();
        }

        fees.totalNetCostAmount = fees.affiliateRewardAmount + fees.feeReceiverAmount + fees.positionFeeAmountForPool + fees.fundingFeeAmount + fees.borrowingFeeAmount;
        fees.totalNetCostUsd = fees.totalNetCostAmount * collateralTokenPrice.max;

        return fees;
    }

    function getPositionFeesAfterReferral(
        DataStore dataStore,
        IReferralStorage referralStorage,
        Price.Props memory collateralTokenPrice,
        address account,
        address market,
        uint256 sizeDeltaUsd
    ) internal view returns (address, uint256, uint256, uint256, uint256) {
        _GetPositionFeesAfterReferralCache memory cache;

        (cache.affiliate, cache.totalRebateFactor, cache.traderDiscountFactor) = ReferralUtils.getReferralInfo(referralStorage, account);

        cache.feeFactor = dataStore.getUint(Keys.positionFeeFactorKey(market));
        cache.positionFeeAmount = Precision.applyFactor(sizeDeltaUsd, cache.feeFactor) / collateralTokenPrice.min;

        cache.totalRebateAmount = Precision.applyFactor(cache.positionFeeAmount, cache.totalRebateFactor);
        cache.traderDiscountAmount = Precision.applyFactor(cache.totalRebateAmount, cache.traderDiscountFactor);
        cache.affiliateRewardAmount = cache.totalRebateAmount - cache.traderDiscountAmount;

        cache.protocolFeeAmount = cache.positionFeeAmount - cache.totalRebateAmount;

        cache.feeReceiverFactor = dataStore.getUint(Keys.FEE_RECEIVER_POSITION_FACTOR);

        cache.feeReceiverAmount = Precision.applyFactor(cache.protocolFeeAmount, cache.feeReceiverFactor);
        cache.positionFeeAmountForPool = cache.protocolFeeAmount - cache.feeReceiverAmount;

        return (cache.affiliate, cache.traderDiscountAmount, cache.affiliateRewardAmount, cache.feeReceiverAmount, cache.positionFeeAmountForPool);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../market/MarketUtils.sol";

import "../utils/Precision.sol";
import "../utils/Calc.sol";

import "./PricingUtils.sol";

library SwapPricingUtils {
    using SafeCast for uint256;
    using SafeCast for int256;

    struct GetPriceImpactUsdParams {
        DataStore dataStore;
        address market;
        address tokenA;
        address tokenB;
        uint256 priceForTokenA;
        uint256 priceForTokenB;
        int256 usdDeltaForTokenA;
        int256 usdDeltaForTokenB;
    }

    struct PoolParams {
        uint256 poolUsdForTokenA;
        uint256 poolUsdForTokenB;
        uint256 nextPoolUsdForTokenA;
        uint256 nextPoolUsdForTokenB;
    }

    struct SwapFees {
        uint256 feeReceiverAmount;
        uint256 feesForPool;
        uint256 amountAfterFees;
        uint256 amountForPool;
    }

    // note that there will be some difference between the pool amounts used for
    // calculating the price impact and fees vs the actual pool amounts after the
    // swap is done, since the pool amounts will be increased / decreased by an amount
    // after factoring in the calculated price impact and fees
    //
    // since the calculations are based on the real-time prices values of the tokens
    // if a token price increases, the pool will incentivise swapping out more of that token
    // this is useful if prices are ranging, if prices are strongly directional, the pool may
    // be selling tokens as the token price increases
    //
    // returns (priceImpactUsd)
    function getPriceImpactUsd(GetPriceImpactUsdParams memory params) internal view returns (int256) {
        PoolParams memory poolParams = getNextPoolAmountsUsd(params);

        int256 priceImpactUsd = _getPriceImpactUsd(params.dataStore, params.market, poolParams);

        return priceImpactUsd;
    }

    function _getPriceImpactUsd(DataStore dataStore, address market, PoolParams memory poolParams) internal view returns (int256) {
        uint256 initialDiffUsd = Calc.diff(poolParams.poolUsdForTokenA, poolParams.poolUsdForTokenB);
        uint256 nextDiffUsd = Calc.diff(poolParams.nextPoolUsdForTokenA, poolParams.nextPoolUsdForTokenB);

        // check whether an improvement in balance comes from causing the balance to switch sides
        // for example, if there is $2000 of ETH and $1000 of USDC in the pool
        // adding $1999 USDC into the pool will reduce absolute balance from $1000 to $999 but it does not
        // help rebalance the pool much, the isSameSideRebalance value helps avoid gaming using this case
        bool isSameSideRebalance = poolParams.poolUsdForTokenA <= poolParams.poolUsdForTokenB == poolParams.nextPoolUsdForTokenA <= poolParams.nextPoolUsdForTokenB;
        uint256 impactExponentFactor = dataStore.getUint(Keys.swapImpactExponentFactorKey(market));

        if (isSameSideRebalance) {
            bool hasPositiveImpact = nextDiffUsd < initialDiffUsd;
            uint256 impactFactor = dataStore.getUint(Keys.swapImpactFactorKey(market, hasPositiveImpact));

            return PricingUtils.getPriceImpactUsdForSameSideRebalance(
                initialDiffUsd,
                nextDiffUsd,
                hasPositiveImpact,
                impactFactor,
                impactExponentFactor
            );
        } else {
            uint256 positiveImpactFactor = dataStore.getUint(Keys.swapImpactFactorKey(market, true));
            uint256 negativeImpactFactor = dataStore.getUint(Keys.swapImpactFactorKey(market, false));

            return PricingUtils.getPriceImpactUsdForCrossoverRebalance(
                initialDiffUsd,
                nextDiffUsd,
                positiveImpactFactor,
                negativeImpactFactor,
                impactExponentFactor
            );
        }
    }

    function getNextPoolAmountsUsd(
        GetPriceImpactUsdParams memory params
    ) internal view returns (PoolParams memory) {
        uint256 poolAmountForTokenA = MarketUtils.getPoolAmount(params.dataStore, params.market, params.tokenA);
        uint256 poolAmountForTokenB = MarketUtils.getPoolAmount(params.dataStore, params.market, params.tokenB);

        uint256 poolUsdForTokenA = poolAmountForTokenA * params.priceForTokenA;
        uint256 poolUsdForTokenB = poolAmountForTokenB * params.priceForTokenB;

        uint256 nextPoolUsdForTokenA = Calc.sum(poolUsdForTokenA, params.usdDeltaForTokenA);
        uint256 nextPoolUsdForTokenB = Calc.sum(poolUsdForTokenB, params.usdDeltaForTokenB);

        PoolParams memory poolParams = PoolParams(
            poolUsdForTokenA,
            poolUsdForTokenB,
            nextPoolUsdForTokenA,
            nextPoolUsdForTokenB
        );

        return poolParams;
    }

    function getSwapFees(
        DataStore dataStore,
        address marketToken,
        uint256 amount,
        bytes32 feeReceiverFactorKey
    ) internal view returns (SwapFees memory) {
        SwapFees memory fees;

        uint256 feeFactor = dataStore.getUint(Keys.swapFeeFactorKey(marketToken));
        uint256 feeReceiverFactor = dataStore.getUint(feeReceiverFactorKey);

        uint256 feeAmount = Precision.applyFactor(amount, feeFactor);

        fees.feeReceiverAmount = Precision.applyFactor(feeAmount, feeReceiverFactor);
        fees.feesForPool = feeAmount - fees.feeReceiverAmount;
        fees.amountAfterFees = amount - feeAmount;

        return fees;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../chain/Chain.sol";

library Order {
    using Order for Props;

    enum OrderType {
        // for LimitIncrease, LimitDecrease, StopLossDecrease orders, two prices for the
        // index token need to be recorded in the oracle
        // the price with the smaller block number is stored as the primary price while the price with the
        // larger block number is stored as the secondary price
        // the triggerPrice must be validated to be between the primary price and secondary price
        // LimitDecrease and StopLossDecrease are reduce-only orders

        // MarketSwap: swap token A to token B at the current market price
        // the order will be cancelled if the minOutputAmount cannot be fulfilled
        MarketSwap,
        // LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
        LimitSwap,
        // MarketIncrease: increase position at the current market price
        // the order will be cancelled if the position cannot be increased at the acceptablePrice
        MarketIncrease,
        // LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitIncrease,
        // MarketDecrease: decrease position at the curent market price
        // the order will be cancelled if the position cannot be decreased at the acceptablePrice
        MarketDecrease,
        // LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitDecrease,
        // StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        StopLossDecrease,
        // Liquidation: allows liquidation of positions if the criteria for liquidation are met
        Liquidation
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address market;
         // for increase positions initialCollateralToken is the token sent in by the user
         // the token will be swapped through the specified swapPath, before position increase
         // for decrease position initialCollateralToken is the collateral token of the position
         // any withdrawn collateral will be swapped through the specified swapPath, after position decrease
        address initialCollateralToken;
        address[] swapPath; // list of markets to swap collateral through
    }

    struct Numbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    struct Flags {
        OrderType orderType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }

    // there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // we use sub-structs here to avoid the issue
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
        bytes data;
    }

    function account(Props memory props) internal pure returns (address) {
        return props.addresses.account;
    }

    function receiver(Props memory props) internal pure returns (address) {
        return props.addresses.receiver;
    }

    function callbackContract(Props memory props) internal pure returns (address) {
        return props.addresses.callbackContract;
    }

    function market(Props memory props) internal pure returns (address) {
        return props.addresses.market;
    }

    function initialCollateralToken(Props memory props) internal pure returns (address) {
        return props.addresses.initialCollateralToken;
    }

    function swapPath(Props memory props) internal pure returns (address[] memory) {
        return props.addresses.swapPath;
    }

    function sizeDeltaUsd(Props memory props) internal pure returns (uint256) {
        return props.numbers.sizeDeltaUsd;
    }

    function initialCollateralDeltaAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.initialCollateralDeltaAmount;
    }

    function triggerPrice(Props memory props) internal pure returns (uint256) {
        return props.numbers.triggerPrice;
    }

    function acceptablePrice(Props memory props) internal pure returns (uint256) {
        return props.numbers.acceptablePrice;
    }

    function executionFee(Props memory props) internal pure returns (uint256) {
        return props.numbers.executionFee;
    }

    function callbackGasLimit(Props memory props) internal pure returns (uint256) {
        return props.numbers.callbackGasLimit;
    }

    function minOutputAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.minOutputAmount;
    }

    function updatedAtBlock(Props memory props) internal pure returns (uint256) {
        return props.numbers.updatedAtBlock;
    }

    function orderType(Props memory props) internal pure returns (OrderType) {
        return props.flags.orderType;
    }

    function isLong(Props memory props) internal pure returns (bool) {
        return props.flags.isLong;
    }

    function shouldUnwrapNativeToken(Props memory props) internal pure returns (bool) {
        return props.flags.shouldUnwrapNativeToken;
    }

    function isFrozen(Props memory props) internal pure returns (bool) {
        return props.flags.isFrozen;
    }

    function setAccount(Props memory props, address _value) internal pure {
        props.addresses.account = _value;
    }

    function setReceiver(Props memory props, address _value) internal pure {
        props.addresses.receiver = _value;
    }

    function setCallbackContract(Props memory props, address _value) internal pure {
        props.addresses.callbackContract = _value;
    }

    function setMarket(Props memory props, address _value) internal pure {
        props.addresses.market = _value;
    }

    function setInitialCollateralToken(Props memory props, address _value) internal pure {
        props.addresses.initialCollateralToken = _value;
    }

    function setSwapPath(Props memory props, address[] memory _value) internal pure {
        props.addresses.swapPath = _value;
    }

    function setSizeDeltaUsd(Props memory props, uint256 _value) internal pure {
        props.numbers.sizeDeltaUsd = _value;
    }

    function setInitialCollateralDeltaAmount(Props memory props, uint256 _value) internal pure {
        props.numbers.initialCollateralDeltaAmount = _value;
    }

    function setTriggerPrice(Props memory props, uint256 _value) internal pure {
        props.numbers.triggerPrice = _value;
    }

    function setAcceptablePrice(Props memory props, uint256 _value) internal pure {
        props.numbers.acceptablePrice = _value;
    }

    function setExecutionFee(Props memory props, uint256 _value) internal pure {
        props.numbers.executionFee = _value;
    }

    function setCallbackGasLimit(Props memory props, uint256 _value) internal pure {
        props.numbers.callbackGasLimit = _value;
    }

    function setMinOutputAmount(Props memory props, uint256 _value) internal pure {
        props.numbers.minOutputAmount = _value;
    }

    function setUpdatedAtBlock(Props memory props, uint256 _value) internal pure {
        props.numbers.updatedAtBlock = _value;
    }

    function setOrderType(Props memory props, OrderType _value) internal pure {
        props.flags.orderType = _value;
    }

    function setIsLong(Props memory props, bool _value) internal pure {
        props.flags.isLong = _value;
    }

    function setShouldUnwrapNativeToken(Props memory props, bool _value) internal pure {
        props.flags.shouldUnwrapNativeToken = _value;
    }

    function setIsFrozen(Props memory props, bool _value) internal pure {
        props.flags.isFrozen = _value;
    }

    function touch(Props memory props) internal view {
        props.setUpdatedAtBlock(Chain.currentBlockNumber());
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library Calc {
    using SignedMath for int256;
    using SafeCast for uint256;

    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    function roundUpDivision(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    function roundUpDivision(int256 a, uint256 b) internal pure returns (int256) {
        if (a < 0) {
            return (a - b.toInt256() + 1) / b.toInt256();
        }

        return (a + b.toInt256() - 1) / b.toInt256();
    }

    function sum(uint256 a, int256 b) internal pure returns (uint256) {
        if (b > 0) {
            return a + b.abs();
        }

        return a - b.abs();
    }

    function sum(int256 a, uint256 b) internal pure returns (int256) {
        return a + b.toInt256();
    }

    function toSigned(uint256 a, bool isPositive) internal pure returns (int256) {
        if (isPositive) {
            return a.toInt256();
        } else {
            return -a.toInt256();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library Precision {
    using SafeCast for uint256;

    uint256 public constant FLOAT_PRECISION = 10 ** 30;
    uint256 public constant WEI_PRECISION = 10 ** 18;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant FLOAT_TO_WEI_DIVISOR = 10 ** 12;

    function applyFactor(uint256 amount, uint256 factor) internal pure returns (uint256) {
        return amount * factor / FLOAT_PRECISION;
    }

    function applyFactor(uint256 amount, int256 factor) internal pure returns (int256) {
        return amount.toInt256() * factor / FLOAT_PRECISION.toInt256();
    }

    function floatToWei(uint256 amount) internal pure returns (uint256) {
        return amount / FLOAT_TO_WEI_DIVISOR;
    }

    function weiToFloat(uint256 amount) internal pure returns (uint256) {
        return amount * FLOAT_TO_WEI_DIVISOR;
    }

    function basisPointsToFloat(uint256 basisPoints) internal pure returns (uint256) {
        return basisPoints * FLOAT_PRECISION / BASIS_POINTS_DIVISOR;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ReferralTier.sol";

interface IReferralStorage {
    function codeOwners(bytes32 _code) external view returns (address);
    function traderReferralCodes(address _account) external view returns (bytes32);
    function referrerDiscountShares(address _account) external view returns (uint256);
    function referrerTiers(address _account) external view returns (uint256);
    function getTraderReferralInfo(address _account) external view returns (bytes32, address);
    function setTraderReferralCode(address _account, bytes32 _code) external;
    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external;
    function setReferrerTier(address _referrer, uint256 _tierId) external;
    function govSetCodeOwner(bytes32 _code, address _newAccount) external;

    function tiers(uint256 _tierLevel) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../data/DataStore.sol";
import "../event/EventEmitter.sol";
import "../bank/StrictBank.sol";

import "../deposit/Deposit.sol";
import "../deposit/DepositStore.sol";
import "../withdrawal/Withdrawal.sol";

import "../market/Market.sol";
import "../market/MarketToken.sol";
import "../market/MarketStore.sol";
import "../position/Position.sol";
import "../position/PositionStore.sol";
import "../order/Order.sol";

import "../oracle/Oracle.sol";
import "../price/Price.sol";

import "../fee/FeeReceiver.sol";
import "../fee/FeeUtils.sol";

import "../utils/Calc.sol";
import "../utils/Precision.sol";

library MarketUtils {
    using SafeCast for int256;
    using SafeCast for uint256;

    using Deposit for Deposit.Props;
    using Market for Market.Props;
    using Position for Position.Props;
    using Order for Order.Props;
    using Price for Price.Props;

    struct MarketPrices {
        Price.Props indexTokenPrice;
        Price.Props longTokenPrice;
        Price.Props shortTokenPrice;
    }

    struct _GetNextFundingAmountPerSizeCache {
        uint256 longOpenInterestWithLongCollateral;
        uint256 longOpenInterestWithShortCollateral;
        uint256 shortOpenInterestWithLongCollateral;
        uint256 shortOpenInterestWithShortCollateral;

        uint256 longOpenInterest;
        uint256 shortOpenInterest;

        int256 longCollateralFundingPerSizeForLongs;
        int256 longCollateralFundingPerSizeForShorts;
        int256 shortCollateralFundingPerSizeForLongs;
        int256 shortCollateralFundingPerSizeForShorts;

        uint256 durationInSeconds;
        uint256 fundingFactor;

        uint256 diffUsd;
        uint256 totalOpenInterest;
        uint256 fundingUsd;

        uint256 fundingUsdForLongCollateral;
        uint256 fundingUsdForShortCollateral;

        uint256 fundingAmountPerSizeForLongCollateralForLongs;
        uint256 fundingAmountPerSizeForShortCollateralForLongs;
        uint256 fundingAmountPerSizeForLongCollateralForShorts;
        uint256 fundingAmountPerSizeForShortCollateralForShorts;
    }

    error EmptyMarket();
    error InsufficientPoolAmount(uint256 poolAmount, uint256 amount);
    error InsufficientReserve(uint256 reservedUsd, uint256 maxReservedUsd);

    function getMarketTokenPrice(
        DataStore dataStore,
        Market.Props memory market,
        Price.Props memory longTokenPrice,
        Price.Props memory shortTokenPrice,
        Price.Props memory indexTokenPrice,
        bool maximize
    ) internal view returns (uint256) {
        uint256 poolValue = getPoolValue(dataStore, market, longTokenPrice, shortTokenPrice, indexTokenPrice, maximize);
        if (poolValue == 0) { return 0; }

        uint256 supply = getMarketTokenSupply(MarketToken(payable(market.marketToken)));

        // it may be possible for supply to be zero here
        return poolValue * Precision.WEI_PRECISION / supply;
    }

    function getMarketTokenSupply(MarketToken marketToken) internal view returns (uint256) {
        return marketToken.totalSupply();
    }

    function getOutputToken(address inputToken, Market.Props memory market) internal pure returns (address) {
        if (inputToken == market.longToken) {
            return market.shortToken;
        }
        if (inputToken == market.shortToken) {
            return market.longToken;
        }

        revert("MarketUtils: invalid inputToken");
    }

    function getCachedTokenPrice(address token, Market.Props memory market, MarketPrices memory prices) internal pure returns (Price.Props memory) {
        if (token == market.longToken) {
            return prices.longTokenPrice;
        }
        if (token == market.shortToken) {
            return prices.shortTokenPrice;
        }
        if (token == market.indexToken) {
            return prices.indexTokenPrice;
        }

        revert("MarketUtils: invalid token");
    }

    // the secondary price for market.indexToken is overwritten for certain order
    // types, use this value instead of the primary price for positions
    function getMarketPricesForPosition(Market.Props memory market, Oracle oracle) internal view returns (MarketPrices memory) {
        return MarketPrices(
            oracle.getLatestPrice(market.indexToken),
            oracle.getLatestPrice(market.longToken),
            oracle.getLatestPrice(market.shortToken)
        );
    }

    function getPoolUsdWithoutPnl(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong
    ) internal view returns (uint256) {
        address token = isLong ? market.longToken : market.shortToken;
        uint256 poolAmount = getPoolAmount(dataStore, market.marketToken, token);
        uint256 tokenPrice = isLong ? prices.longTokenPrice.min : prices.shortTokenPrice.min;
        return poolAmount * tokenPrice;
    }

    // the value of a market's liquidity pool is the worth of the liquidity provider tokens in the pool - pending trader pnl
    // we use the token index prices to calculate this and ignore price impact since if all positions were closed the
    // net price impact should be zero
    // when minting liquidity provider tokens, the price impact of the token in should be considered
    // when redeeming liquidity provider tokens, the price impact of the token out should be considered
    function getPoolValue(
        DataStore dataStore,
        Market.Props memory market,
        Price.Props memory longTokenPrice,
        Price.Props memory shortTokenPrice,
        Price.Props memory indexTokenPrice,
        bool maximize
    ) internal view returns (uint256) {
        uint256 longTokenAmount = getPoolAmount(dataStore, market.marketToken, market.longToken);
        uint256 shortTokenAmount = getPoolAmount(dataStore, market.marketToken, market.shortToken);

        uint256 value;

        value = longTokenAmount * longTokenPrice.pickPrice(maximize);
        value += shortTokenAmount * shortTokenPrice.pickPrice(maximize);

        value += getTotalBorrowingFees(dataStore, market.marketToken, market.longToken, market.shortToken, true);
        value += getTotalBorrowingFees(dataStore, market.marketToken, market.longToken, market.shortToken, false);

        uint256 impactPoolAmount = getPositionImpactPoolAmount(dataStore, market.marketToken);
        value += impactPoolAmount * indexTokenPrice.pickPrice(maximize);

        // !maximize should be used for net pnl as a larger pnl leads to a smaller pool value
        // and a smaller pnl leads to a larger pool value
        int256 pnl = getNetPnl(dataStore, market.marketToken, market.longToken, market.shortToken, indexTokenPrice, !maximize);

        return Calc.sum(value, -pnl);
    }

    function getNetPnl(
        DataStore dataStore,
        address market,
        address longToken,
        address shortToken,
        Price.Props memory indexTokenPrice,
        bool maximize
    ) internal view returns (int256) {
        int256 longPnl = getPnl(dataStore, market, longToken, shortToken, indexTokenPrice, true, maximize);
        int256 shortPnl = getPnl(dataStore, market, longToken, shortToken, indexTokenPrice, false, maximize);

        return longPnl + shortPnl;
    }

    function getPnl(
        DataStore dataStore,
        address market,
        address longToken,
        address shortToken,
        Price.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) internal view returns (int256) {
        int256 openInterest = getOpenInterest(dataStore, market, longToken, shortToken, isLong).toInt256();
        uint256 openInterestInTokens = getOpenInterestInTokens(dataStore, market, longToken, shortToken, isLong);
        if (openInterest == 0 || openInterestInTokens == 0) {
            return 0;
        }

        uint256 price = indexTokenPrice.pickPriceForPnl(isLong, maximize);

        // openInterest is the cost of all positions, openInterestValue is the current worth of all positions
        int256 openInterestValue = (openInterestInTokens * price).toInt256();
        int256 pnl = isLong ? openInterestValue - openInterest : openInterest - openInterestValue;

        return pnl;
    }

    function getPoolAmount(DataStore dataStore, address market, address token) internal view returns (uint256) {
        return dataStore.getUint(Keys.poolAmountKey(market, token));
    }

    function incrementClaimableFundingAmount(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        address account,
        uint256 delta
    ) internal {
        uint256 nextValue = dataStore.incrementUint(
            Keys.claimableFundingAmountKey(market, token, account),
            delta
        );

        eventEmitter.emitClaimableFundingUpdated(market, token, account, delta, nextValue);
    }

    function claimFundingFees(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        address account,
        address receiver
    ) internal {
        bytes32 key = Keys.claimableFundingAmountKey(market, token, account);

        uint256 claimableAmount = dataStore.getUint(key);
        dataStore.setUint(key, 0);

        MarketToken(payable(market)).transferOut(
            token,
            claimableAmount,
            receiver
        );

        eventEmitter.emitFundingFeesClaimed(
            market,
            token,
            account,
            receiver,
            claimableAmount
        );
    }

    function applyDeltaToPoolAmount(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        int256 delta
    ) internal {
        uint256 nextValue = dataStore.applyDeltaToUint(
            Keys.poolAmountKey(market, token),
            delta
        );

        eventEmitter.emitPoolAmountUpdated(market, token, delta, nextValue);
    }

    function getCappedPositionImpactUsd(
        DataStore dataStore,
        address market,
        Price.Props memory tokenPrice,
        int256 priceImpactUsd
    ) internal view returns (int256) {
        if (priceImpactUsd < 0) {
            return priceImpactUsd;
        }

        uint256 impactPoolAmount = getPositionImpactPoolAmount(dataStore, market);
        int256 maxPositiveImpactUsd = (impactPoolAmount * tokenPrice.min).toInt256();

        if (priceImpactUsd > maxPositiveImpactUsd) {
            priceImpactUsd = maxPositiveImpactUsd;
        }

        return priceImpactUsd;
    }

    function getPositionImpactPoolAmount(DataStore dataStore, address market) internal view returns (uint256) {
        return dataStore.getUint(Keys.positionImpactPoolAmountKey(market));
    }

    function getSwapImpactPoolAmount(DataStore dataStore, address market, address token) internal view returns (uint256) {
        return dataStore.getUint(Keys.swapImpactPoolAmountKey(market, token));
    }

    function applyDeltaToSwapImpactPool(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        int256 delta
    ) internal {
        uint256 nextValue = dataStore.applyDeltaToUint(
            Keys.swapImpactPoolAmountKey(market, token),
            delta
        );

        eventEmitter.emitSwapImpactPoolAmountUpdated(market, token, delta, nextValue);
    }

    function applyDeltaToPositionImpactPool(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        int256 delta
    ) internal {
        uint256 nextValue = dataStore.applyDeltaToUint(
            Keys.positionImpactPoolAmountKey(market),
            delta,
            true
        );

        eventEmitter.emitPositionImpactPoolAmountUpdated(market, delta, nextValue);
    }

    function applyDeltaToOpenInterest(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        int256 delta
    ) internal {
        uint256 nextValue = dataStore.applyDeltaToUint(
            Keys.openInterestKey(market, collateralToken, isLong),
            delta
        );

        eventEmitter.emitOpenInterestUpdated(market, collateralToken, isLong, delta, nextValue);
    }

    function applyDeltaToOpenInterestInTokens(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        int256 delta
    ) internal {
        uint256 nextValue = dataStore.applyDeltaToUint(
            Keys.openInterestInTokensKey(market, collateralToken, isLong),
            delta
        );

        eventEmitter.emitOpenInterestInTokensUpdated(market, collateralToken, isLong, delta, nextValue);
    }

    function applyDeltaToCollateralSum(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        int256 collateralDeltaAmount
    ) internal {
        dataStore.applyDeltaToUint(
            Keys.collateralSumKey(market, collateralToken, isLong),
            collateralDeltaAmount
        );

        eventEmitter.emitCollateralSumDelta(market, collateralToken, isLong, collateralDeltaAmount);
    }

    function updateFundingAmountPerSize(
        DataStore dataStore,
        MarketPrices memory prices,
        address market,
        address longToken,
        address shortToken
    ) internal {
        (
            int256 longCollateralFundingPerSizeForLongs,
            int256 longCollateralFundingPerSizeForShorts,
            int256 shortCollateralFundingPerSizeForLongs,
            int256 shortCollateralFundingPerSizeForShorts
        ) = getNextFundingAmountPerSize(dataStore, prices, market, longToken, shortToken);

        setFundingAmountPerSize(dataStore, market, longToken, true, longCollateralFundingPerSizeForLongs);
        setFundingAmountPerSize(dataStore, market, longToken, false, longCollateralFundingPerSizeForShorts);
        setFundingAmountPerSize(dataStore, market, shortToken, true, shortCollateralFundingPerSizeForLongs);
        setFundingAmountPerSize(dataStore, market, shortToken, false, shortCollateralFundingPerSizeForShorts);

        dataStore.setUint(Keys.fundingUpdatedAtKey(market), block.timestamp);
    }

    function getNextFundingAmountPerSize(
        DataStore dataStore,
        MarketPrices memory prices,
        address market,
        address longToken,
        address shortToken
    ) internal view returns (int256, int256, int256, int256) {
        _GetNextFundingAmountPerSizeCache memory cache;
        cache.longOpenInterestWithLongCollateral = getOpenInterest(dataStore, market, longToken, true);
        cache.longOpenInterestWithShortCollateral = getOpenInterest(dataStore, market, shortToken, true);
        cache.shortOpenInterestWithLongCollateral = getOpenInterest(dataStore, market, longToken, false);
        cache.shortOpenInterestWithShortCollateral = getOpenInterest(dataStore, market, shortToken, false);

        cache.longOpenInterest = cache.longOpenInterestWithLongCollateral + cache.longOpenInterestWithShortCollateral;
        cache.shortOpenInterest = cache.shortOpenInterestWithLongCollateral + cache.shortOpenInterestWithShortCollateral;

        cache.longCollateralFundingPerSizeForLongs = getFundingAmountPerSize(dataStore, market, longToken, true);
        cache.longCollateralFundingPerSizeForShorts = getFundingAmountPerSize(dataStore, market, longToken, false);
        cache.shortCollateralFundingPerSizeForLongs = getFundingAmountPerSize(dataStore, market, shortToken, true);
        cache.shortCollateralFundingPerSizeForShorts = getFundingAmountPerSize(dataStore, market, shortToken, false);

        if (cache.longOpenInterest == 0 || cache.shortOpenInterest == 0) {
            return (
                cache.longCollateralFundingPerSizeForLongs,
                cache.longCollateralFundingPerSizeForShorts,
                cache.shortCollateralFundingPerSizeForLongs,
                cache.shortCollateralFundingPerSizeForShorts
            );
        }

        cache.durationInSeconds = getSecondsSinceFundingUpdated(dataStore, market);
        cache.fundingFactor = getFundingFactor(dataStore, market);

        cache.diffUsd = Calc.diff(cache.longOpenInterest, cache.shortOpenInterest);
        cache.totalOpenInterest = cache.longOpenInterest + cache.shortOpenInterest;
        cache.fundingUsd = (cache.fundingFactor * cache.diffUsd * cache.durationInSeconds) / cache.totalOpenInterest;

        if (cache.longOpenInterest > cache.shortOpenInterest) {
            cache.fundingUsdForLongCollateral = cache.fundingUsd * cache.longOpenInterestWithLongCollateral / cache.longOpenInterest;
            cache.fundingUsdForShortCollateral = cache.fundingUsd * cache.longOpenInterestWithShortCollateral / cache.longOpenInterest;
        } else {
            cache.fundingUsdForLongCollateral = cache.fundingUsd * cache.shortOpenInterestWithLongCollateral / cache.shortOpenInterest;
            cache.fundingUsdForShortCollateral = cache.fundingUsd * cache.shortOpenInterestWithShortCollateral / cache.shortOpenInterest;
        }

        // use Precision.FLOAT_PRECISION here because fundingUsdForLongCollateral or fundingUsdForShortCollateral divided by longTokenPrice
        // will give an amount in number of tokens which may be quite a small value and could become zero after being divided by longOpenInterest
        // the result will be the amount in number of tokens multiplied by Precision.FLOAT_PRECISION per 1 USD of size
        cache.fundingAmountPerSizeForLongCollateralForLongs = getPerSizeValue(cache.fundingUsdForLongCollateral / prices.longTokenPrice.max, cache.longOpenInterest);
        cache.fundingAmountPerSizeForShortCollateralForLongs = getPerSizeValue(cache.fundingUsdForShortCollateral / prices.shortTokenPrice.max, cache.longOpenInterest);
        cache.fundingAmountPerSizeForLongCollateralForShorts = getPerSizeValue(cache.fundingUsdForLongCollateral / prices.longTokenPrice.max, cache.shortOpenInterest);
        cache.fundingAmountPerSizeForShortCollateralForShorts = getPerSizeValue(cache.fundingUsdForShortCollateral / prices.shortTokenPrice.max, cache.shortOpenInterest);

        if (cache.longOpenInterest > cache.shortOpenInterest) {
            // longs pay shorts
            cache.longCollateralFundingPerSizeForLongs += cache.fundingAmountPerSizeForLongCollateralForLongs.toInt256();
            cache.shortCollateralFundingPerSizeForLongs += cache.fundingAmountPerSizeForShortCollateralForLongs.toInt256();
            cache.shortCollateralFundingPerSizeForLongs -= cache.fundingAmountPerSizeForLongCollateralForShorts.toInt256();
            cache.shortCollateralFundingPerSizeForShorts -= cache.fundingAmountPerSizeForShortCollateralForShorts.toInt256();
        } else {
            // shorts pay longs
            cache.longCollateralFundingPerSizeForLongs -= cache.fundingAmountPerSizeForLongCollateralForLongs.toInt256();
            cache.shortCollateralFundingPerSizeForLongs -= cache.fundingAmountPerSizeForShortCollateralForLongs.toInt256();
            cache.shortCollateralFundingPerSizeForLongs += cache.fundingAmountPerSizeForLongCollateralForShorts.toInt256();
            cache.shortCollateralFundingPerSizeForShorts += cache.fundingAmountPerSizeForShortCollateralForShorts.toInt256();
        }

        return (
            cache.longCollateralFundingPerSizeForLongs,
            cache.longCollateralFundingPerSizeForShorts,
            cache.shortCollateralFundingPerSizeForLongs,
            cache.shortCollateralFundingPerSizeForShorts
        );
    }

    function updateCumulativeBorrowingFactor(
        DataStore dataStore,
        address market,
        address longToken,
        address shortToken,
        MarketPrices memory prices,
        bool isLong
    ) internal {
        uint256 borrowingFactor = getNextCumulativeBorrowingFactor(dataStore, market, longToken, shortToken, prices, isLong);
        setCumulativeBorrowingFactor(dataStore, market, isLong, borrowingFactor);
        dataStore.setUint(Keys.cumulativeBorrowingFactorUpdatedAtKey(market, isLong), block.timestamp);
    }

    function getPerSizeValue(uint256 amount, uint256 totalSize) internal pure returns (uint256) {
        return (amount * Precision.FLOAT_PRECISION) / (totalSize / Precision.FLOAT_PRECISION);
    }

    function getPnlToPoolFactor(
        DataStore dataStore,
        MarketStore marketStore,
        Oracle oracle,
        address market,
        bool isLong,
        bool maximize
    ) internal view returns (int256) {
        Market.Props memory _market = marketStore.get(market);
        MarketUtils.MarketPrices memory prices = MarketUtils.MarketPrices(
            oracle.getPrimaryPrice(_market.indexToken),
            oracle.getPrimaryPrice(_market.longToken),
            oracle.getPrimaryPrice(_market.shortToken)
        );

        return getPnlToPoolFactor(dataStore, _market, prices, isLong, maximize);
    }

    // return factor for (pnl of positions) / (long or short pool value)
    function getPnlToPoolFactor(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong,
        bool maximize
    ) internal view returns (int256) {
        uint256 poolUsd = getPoolUsdWithoutPnl(dataStore, market, prices, isLong);

        int256 pnl = getPnl(
            dataStore,
            market.marketToken,
            market.longToken,
            market.shortToken,
            prices.indexTokenPrice,
            isLong,
            maximize
        );

        return pnl * Precision.FLOAT_PRECISION.toInt256() / poolUsd.toInt256();
    }

    function validateReserve(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong
    ) internal view {
        uint256 poolUsd = getPoolUsdWithoutPnl(dataStore, market, prices, isLong);

        uint256 reserveFactor = getReserveFactor(dataStore, market.marketToken, isLong);
        uint256 maxReservedUsd = Precision.applyFactor(poolUsd, reserveFactor);

        uint256 reservedUsd;
        if (isLong) {
            // for longs calculate the reserved USD based on the open interest and current indexTokenPrice
            // this works well for e.g. an ETH / USD market with long collateral token as WETH
            // the available amount to be reserved would scale with the price of ETH
            // this also works for e.g. a SOL / USD market with long collateral token as WETH
            // if the price of SOL increases more than the price of ETH, additional amounts would be
            // automatically reserved
            uint256 openInterestInTokens = getOpenInterestInTokens(dataStore, market.marketToken, market.longToken, market.shortToken, isLong);
            reservedUsd = openInterestInTokens * prices.indexTokenPrice.max;
        } else {
            // for shorts use the open interest as the reserved USD value
            // this works well for e.g. an ETH / USD market with short collateral token as USDC
            // the available amount to be reserved would not change with the price of ETH
            reservedUsd = getOpenInterest(dataStore, market.marketToken, market.longToken, market.shortToken, isLong);
        }

        if (reservedUsd > maxReservedUsd) {
            revert InsufficientReserve(reservedUsd, maxReservedUsd);
        }
    }

    function applySwapImpactWithCap(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        Price.Props memory tokenPrice,
        int256 priceImpactUsd
    ) internal returns (int256) {
        // positive impact: minimize impactAmount, use tokenPrice.max
        // negative impact: maximize impactAmount, use tokenPrice.min
        uint256 price = priceImpactUsd > 0 ? tokenPrice.max : tokenPrice.min;

        int256 impactAmount;

        if (priceImpactUsd > 0) {
            // round positive impactAmount down, this will be deducted from the swap impact pool for the user
            impactAmount = priceImpactUsd / price.toInt256();

            int256 maxImpactAmount = getSwapImpactPoolAmount(dataStore, market, token).toInt256();
            if (impactAmount > maxImpactAmount) {
                impactAmount = maxImpactAmount;
            }
        } else {
            // round negative impactAmount up, this will be deducted from the user
            impactAmount = Calc.roundUpDivision(priceImpactUsd, price);
        }

        // if there is a positive impact, the impact pool amount should be reduced
        // if there is a negative impact, the impact pool amount should be increased
        applyDeltaToSwapImpactPool(
            dataStore,
            eventEmitter,
            market,
            token,
            -impactAmount
        );

        return impactAmount;
    }

    // return hasPendingFundingFee because it may be possible for there to be a funding fee but it is too small and the fundingFeeAmount is zero
    // in which case the position's fundingAmountPerSize should not be updated, otherwise a user could avoid paying funding fees by continually
    // updating the position before the funding fee becomes large enough to be chargeable
    // returns (hasPendingFundingFee, fundingFeeAmount)
    function getFundingFeeAmount(
        int256 latestFundingAmountPerSize,
        int256 positionFundingAmountPerSize,
        uint256 positionSizeInUsd
    ) internal pure returns (bool, int256) {
        // the position is just being opened, so there are no funding fees
        if (positionFundingAmountPerSize == 0) {
            return (false, 0);
        }

        int256 diff = (latestFundingAmountPerSize - positionFundingAmountPerSize);
        int256 amount = diff * (positionSizeInUsd.toInt256() / Precision.FLOAT_PRECISION.toInt256()) / Precision.FLOAT_PRECISION.toInt256();

        return (amount == 0, amount);
    }

    function getBorrowingFees(DataStore dataStore, Position.Props memory position) internal view returns (uint256) {
        uint256 cumulativeBorrowingFactor = getCumulativeBorrowingFactor(dataStore, position.market, position.isLong);
        uint256 diffFactor = cumulativeBorrowingFactor - position.borrowingFactor;
        return Precision.applyFactor(position.sizeInUsd, diffFactor);
    }

    function getOpenInterest(
        DataStore dataStore,
        address market,
        address longToken,
        address shortToken,
        bool isLong
    ) internal view returns (uint256) {
        uint256 openInterestUsingLongTokenAsCollateral = getOpenInterest(dataStore, market, longToken, isLong);
        uint256 openInterestUsingShortTokenAsCollateral = getOpenInterest(dataStore, market, shortToken, isLong);

        return openInterestUsingLongTokenAsCollateral + openInterestUsingShortTokenAsCollateral;
    }

    function getOpenInterest(
        DataStore dataStore,
        address market,
        address collateralToken,
        bool isLong
    ) internal view returns (uint256) {
        return dataStore.getUint(Keys.openInterestKey(market, collateralToken, isLong));
    }

    function getOpenInterestInTokens(
        DataStore dataStore,
        address market,
        address longToken,
        address shortToken,
        bool isLong
    ) internal view returns (uint256) {
        uint256 openInterestUsingLongTokenAsCollateral = getOpenInterestInTokens(dataStore, market, longToken, isLong);
        uint256 openInterestUsingShortTokenAsCollateral = getOpenInterestInTokens(dataStore, market, shortToken, isLong);

        return openInterestUsingLongTokenAsCollateral + openInterestUsingShortTokenAsCollateral;
    }

    function getOpenInterestInTokens(
        DataStore dataStore,
        address market,
        address collateralToken,
        bool isLong
    ) internal view returns (uint256) {
        return dataStore.getUint(Keys.openInterestInTokensKey(market, collateralToken, isLong));
    }

    // getOpenInterestInTokens * tokenPrice would not reflect pending positive pnl
    // from short positions, getOpenInterestWithPnl should be used if that info is needed
    function getOpenInterestWithPnl(
        DataStore dataStore,
        address market,
        address longToken,
        address shortToken,
        Price.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) internal view returns (uint256) {
        uint256 openInterest = getOpenInterest(dataStore, market, longToken, shortToken, isLong);
        int256 pnl = getPnl(dataStore, market, longToken, shortToken, indexTokenPrice, isLong, maximize);
        return Calc.sum(openInterest, pnl);
    }

    function getCollateralSum(DataStore dataStore, address market, address collateralToken,  bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.collateralSumKey(market, collateralToken, isLong));
    }

    function getReserveFactor(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.reserveFactorKey(market, isLong));
    }

    function getMaxPnlFactor(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.maxPnlFactorKey(market, isLong));
    }

    function getMaxPnlFactorForWithdrawals(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.maxPnlFactorForWithdrawalsKey(market, isLong));
    }

    function getFundingFactor(DataStore dataStore, address market) internal view returns (uint256) {
        return dataStore.getUint(Keys.fundingFactorKey(market));
    }

    function getFundingAmountPerSize(DataStore dataStore, address market, address collateralToken, bool isLong) internal view returns (int256) {
        return dataStore.getInt(Keys.fundingAmountPerSizeKey(market, collateralToken, isLong));
    }

    function setFundingAmountPerSize(DataStore dataStore, address market, address collateralToken, bool isLong, int256 value) internal returns (int256) {
        return dataStore.setInt(Keys.fundingAmountPerSizeKey(market, collateralToken, isLong), value);
    }

    function getSecondsSinceFundingUpdated(DataStore dataStore, address market) internal view returns (uint256) {
        uint256 updatedAt = dataStore.getUint(Keys.fundingUpdatedAtKey(market));
        if (updatedAt == 0) { return 0; }
        return block.timestamp - updatedAt;
    }

    function getBorrowingFactor(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.borrowingFactorKey(market, isLong));
    }

    function getCumulativeBorrowingFactor(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.cumulativeBorrowingFactorKey(market, isLong));
    }

    function setCumulativeBorrowingFactor(DataStore dataStore, address market, bool isLong, uint256 value) internal {
        dataStore.setUint(Keys.cumulativeBorrowingFactorKey(market, isLong), value);
    }

    function getCumulativeBorrowingFactorUpdatedAt(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.cumulativeBorrowingFactorUpdatedAtKey(market, isLong));
    }

    function getSecondsSinceCumulativeBorrowingFactorUpdated(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        uint256 updatedAt = getCumulativeBorrowingFactorUpdatedAt(dataStore, market, isLong);
        if (updatedAt == 0) { return 0; }
        return block.timestamp - updatedAt;
    }

    function updateTotalBorrowing(
        DataStore dataStore,
        address market,
        bool isLong,
        uint256 prevPositionSizeInUsd,
        uint256 prevPositionBorrowingFactor,
        uint256 nextPositionSizeInUsd,
        uint256 nextPositionBorrowingFactor
    ) internal {
        uint256 totalBorrowing = getNextTotalBorrowing(
            dataStore,
            market,
            isLong,
            prevPositionSizeInUsd,
            prevPositionBorrowingFactor,
            nextPositionSizeInUsd,
            nextPositionBorrowingFactor
        );

        setTotalBorrowing(dataStore, market, isLong, totalBorrowing);
    }

    function getNextTotalBorrowing(
        DataStore dataStore,
        address market,
        bool isLong,
        uint256 prevPositionSizeInUsd,
        uint256 prevPositionBorrowingFactor,
        uint256 nextPositionSizeInUsd,
        uint256 nextPositionBorrowingFactor
    ) internal view returns (uint256) {
        uint256 totalBorrowing = getTotalBorrowing(dataStore, market, isLong);
        totalBorrowing -= prevPositionSizeInUsd * prevPositionBorrowingFactor;
        totalBorrowing += nextPositionSizeInUsd * nextPositionBorrowingFactor;

        return totalBorrowing;
    }

    function getNextCumulativeBorrowingFactor(
        DataStore dataStore,
        address market,
        address longToken,
        address shortToken,
        MarketPrices memory prices,
        bool isLong
    ) internal view returns (uint256) {
        uint256 durationInSeconds = getSecondsSinceCumulativeBorrowingFactorUpdated(dataStore, market, isLong);
        uint256 borrowingFactor = getBorrowingFactor(dataStore, market, isLong);

        uint256 openInterestWithPnl = getOpenInterestWithPnl(dataStore, market, longToken, shortToken, prices.indexTokenPrice, isLong, true);

        uint256 poolAmount = getPoolAmount(dataStore, market, isLong ? longToken : shortToken);
        uint256 poolTokenPrice = isLong ? prices.longTokenPrice.min : prices.shortTokenPrice.min;
        uint256 poolUsd = poolAmount * poolTokenPrice;

        uint256 adjustedFactor = durationInSeconds * borrowingFactor * openInterestWithPnl / poolUsd;
        uint256 cumulativeBorrowingFactor = getCumulativeBorrowingFactor(dataStore, market, isLong);

        return cumulativeBorrowingFactor + adjustedFactor;
    }

    function getTotalBorrowingFees(DataStore dataStore, address market, address longToken, address shortToken, bool isLong) internal view returns (uint256) {
        uint256 openInterest = getOpenInterest(dataStore, market, longToken, shortToken, isLong);
        uint256 cumulativeBorrowingFactor = getCumulativeBorrowingFactor(dataStore, market, isLong);
        uint256 totalBorrowing = getTotalBorrowing(dataStore, market, isLong);
        return openInterest * cumulativeBorrowingFactor - totalBorrowing;
    }

    // sum of position.borrowingFactor * position.size for all positions of the market
    // if borrowing APR is 1000% for 100 years, the cumulativeBorrowingFactor could be as high as 100 * 1000 * (10 ** 30)
    // since position.size is a USD value with 30 decimals, under this scenario, there may be overflow issues
    // if open interest exceeds (2 ** 256) / (10 ** 30) / (100 * 1000 * (10 ** 30)) => 1,157,920,900,000 USD
    function getTotalBorrowing(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.totalBorrowingKey(market, isLong));
    }

    function setTotalBorrowing(DataStore dataStore, address market, bool isLong, uint256 value) internal returns (uint256) {
        return dataStore.setUint(Keys.totalBorrowingKey(market, isLong), value);
    }

    function usdToMarketTokenAmount(
        uint256 usdValue,
        uint256 poolValue,
        uint256 supply
    ) internal pure returns (uint256) {
        if (supply == 0 || poolValue == 0) {
            return Precision.floatToWei(usdValue);
        }

        // round market tokens down
        return supply * usdValue / poolValue;
    }

    function marketTokenAmountToUsd(
        uint256 marketTokenAmount,
        uint256 poolValue,
        uint256 supply
    ) internal pure returns (uint256) {
        if (supply == 0 || poolValue == 0) {
            return 0;
        }

        return marketTokenAmount * poolValue / supply;
    }

    function validateNonEmptyMarket(Market.Props memory market) internal pure {
        if (market.marketToken == address(0)) {
            revert EmptyMarket();
        }
    }

    function getMarkets(MarketStore marketStore, address[] memory swapPath) internal view returns (Market.Props[] memory) {
        Market.Props[] memory markets = new Market.Props[](swapPath.length);

        for (uint256 i = 0; i < swapPath.length; i++) {
            Market.Props memory market = marketStore.get(swapPath[i]);
            validateNonEmptyMarket(market);
            markets[i] = market;
        }

        return markets;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../data/DataStore.sol";
import "../data/Keys.sol";

import "../event/EventEmitter.sol";
import "../market/MarketToken.sol";

import "./IReferralStorage.sol";
import "./ReferralTier.sol";

import "../utils/Precision.sol";

library ReferralUtils {
    function setTraderReferralCode(
        IReferralStorage referralStorage,
        address account,
        bytes32 referralCode
    ) internal {
        if (referralCode == bytes32(0)) {
            return;
        }

        referralStorage.setTraderReferralCode(account, referralCode);
    }

    function incrementAffiliateReward(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        address affiliate,
        address trader,
        uint256 delta
    ) internal {
        if (delta == 0) {
            return;
        }

        dataStore.incrementUint(Keys.affiliateRewardKey(market, token, affiliate), delta);
        eventEmitter.emitAffiliateRewardEarned(market, token, affiliate, trader, delta);
    }

    function getReferralInfo(
        IReferralStorage referralStorage,
        address trader
    ) internal view returns (address, uint256, uint256) {
        bytes32 code = referralStorage.traderReferralCodes(trader);
        address affiliate;
        uint256 totalRebate;
        uint256 discountShare;

        if (code != bytes32(0)) {
            affiliate = referralStorage.codeOwners(code);
            uint256 referralTierLevel = referralStorage.referrerTiers(affiliate);
            (totalRebate, discountShare) = referralStorage.tiers(referralTierLevel);

            uint256 customDiscountShare = referralStorage.referrerDiscountShares(affiliate);
            if (customDiscountShare != 0) {
                discountShare = customDiscountShare;
            }
        }

        return (
            affiliate,
            Precision.basisPointsToFloat(totalRebate),
            Precision.basisPointsToFloat(discountShare)
        );
    }

    function claimAffiliateReward(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        address account,
        address receiver
    ) internal {
        bytes32 key = Keys.affiliateRewardKey(market, token, account);

        uint256 rewardAmount = dataStore.getUint(key);
        dataStore.setUint(key, 0);

        MarketToken(payable(market)).transferOut(
            token,
            rewardAmount,
            receiver
        );

        eventEmitter.emitAffiliateRewardClaimed(
            market,
            token,
            account,
            receiver,
            rewardAmount
        );
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "prb-math/contracts/PRBMathUD60x18.sol";

import "../utils/Calc.sol";
import "../utils/Precision.sol";
import "../market/MarketUtils.sol";
import "../fee/FeeReceiver.sol";

library PricingUtils {
    function getPriceImpactUsdForSameSideRebalance(
        uint256 initialDiffUsd,
        uint256 nextDiffUsd,
        bool hasPositiveImpact,
        uint256 impactFactor,
        uint256 impactExponentFactor
    ) internal pure returns (int256) {
        uint256 deltaDiffUsd = Calc.diff(
            applyImpactFactor(initialDiffUsd, impactFactor, impactExponentFactor),
            applyImpactFactor(nextDiffUsd, impactFactor, impactExponentFactor)
        );

        int256 priceImpactUsd = Calc.toSigned(deltaDiffUsd, hasPositiveImpact);

        return priceImpactUsd;
    }

    function getPriceImpactUsdForCrossoverRebalance(
        uint256 initialDiffUsd,
        uint256 nextDiffUsd,
        uint256 positiveImpactFactor,
        uint256 negativeImpactFactor,
        uint256 impactExponentFactor
    ) internal pure returns (int256) {
        uint256 positiveImpactUsd = applyImpactFactor(initialDiffUsd, positiveImpactFactor, impactExponentFactor);
        uint256 negativeImpactUsd = applyImpactFactor(nextDiffUsd, negativeImpactFactor, impactExponentFactor);
        uint256 deltaDiffUsd = Calc.diff(positiveImpactUsd, negativeImpactUsd);

        int256 priceImpactUsd = Calc.toSigned(deltaDiffUsd, positiveImpactUsd > negativeImpactUsd);

        return priceImpactUsd;
    }

    function applyImpactFactor(
        uint256 diffUsd,
        uint256 impactFactor,
        uint256 impactExponentFactor
    ) internal pure returns (uint256) {
        // `PRBMathUD60x18.pow` doesn't work for `x` less than one
        if (diffUsd < Precision.FLOAT_PRECISION) {
            return 0;
        }

        // `PRBMathUD60x18.pow` accepts 2 fixed point numbers 60x18
        // we need to convert float (30 decimals) to 60x18 (18 decimals) and then back to 30 decimals
        uint256 adjustedDiffUsd = PRBMathUD60x18.pow(
            Precision.floatToWei(diffUsd),
            Precision.floatToWei(impactExponentFactor)
        );
        adjustedDiffUsd = Precision.weiToFloat(adjustedDiffUsd);

        // we divide by 2 here to more easily translate liquidity into the appropriate impactFactor values
        // for example, if the impactExponentFactor is 2 and we want to have an impact of 0.1% for $2 million of difference
        // we can set the impactFactor to be 0.1% / $2 million
        return Precision.applyFactor(adjustedDiffUsd, impactFactor) / 2;
    }

    function transferFees(
        FeeReceiver feeReceiver,
        address marketToken,
        address token,
        uint256 feeReceiverAmount,
        bytes32 feeType
    ) internal {
        if (feeReceiverAmount > 0) {
            MarketToken(payable(marketToken)).transferOut(token, feeReceiverAmount, address(feeReceiver));
            feeReceiver.notifyFeeReceived(feeType, token, feeReceiverAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
     * - input must fit into 8 bits
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
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library ReferralTier {
    struct Props {
        uint256 totalRebate;
        uint256 discountShare;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../utils/Calc.sol";

contract DataStore is RoleModule {
    using SafeCast for int256;

    mapping(bytes32 => uint256) public uintValues;
    mapping(bytes32 => int256) public intValues;
    mapping(bytes32 => address) public addressValues;
    mapping(bytes32 => bool) public boolValues;
    mapping(bytes32 => string) public stringValues;
    mapping(bytes32 => bytes32) public dataValues;

    constructor(RoleStore _roleStore) RoleModule(_roleStore) {}

    function getUint(bytes32 key) external view returns (uint256) {
        return uintValues[key];
    }

    function setUint(bytes32 key, uint256 value) external onlyController returns (uint256) {
        uintValues[key] = value;
        return value;
    }

    function applyDeltaToUint(bytes32 key, int256 value) external onlyController returns (uint256) {
        uint256 nextUint = Calc.sum(uintValues[key], value);
        uintValues[key] = nextUint;
        return nextUint;
    }

    function applyDeltaToUint(bytes32 key, int256 value, bool ensurePositiveValue) external onlyController returns (uint256) {
        uint256 uintValue = uintValues[key];
        if (ensurePositiveValue && value < 0 && (-value).toUint256() > uintValue) {
            uintValues[key] = 0;
            return 0;
        }

        uint256 nextUint = Calc.sum(uintValue, value);
        uintValues[key] = nextUint;
        return nextUint;
    }

    function incrementUint(bytes32 key, uint256 value) external onlyController returns (uint256) {
        uint256 nextUint = uintValues[key] + value;
        uintValues[key] = nextUint;
        return nextUint;
    }

    function decrementUint(bytes32 key, uint256 value) external onlyController returns (uint256) {
        uint256 nextUint = uintValues[key] - value;
        uintValues[key] = nextUint;
        return nextUint;
    }

    function getInt(bytes32 key) external view returns (int256) {
        return intValues[key];
    }

    function setInt(bytes32 key, int256 value) external onlyController returns (int256) {
        intValues[key] = value;
        return value;
    }

    function applyDeltaToInt(bytes32 key, int256 value) external onlyController returns (int256) {
        int256 nextInt = intValues[key] + value;
        intValues[key] = nextInt;
        return nextInt;
    }

    function incrementInt(bytes32 key, int256 value) external onlyController returns (int256) {
        int256 nextInt = intValues[key] + value;
        intValues[key] = nextInt;
        return nextInt;
    }

    function decrementInt(bytes32 key, int256 value) external onlyController returns (int256) {
        int256 nextInt = intValues[key] - value;
        intValues[key] = nextInt;
        return nextInt;
    }

    function getAddress(bytes32 key) external view returns (address) {
        return addressValues[key];
    }

    function setAddress(bytes32 key, address value) external onlyController returns (address) {
        addressValues[key] = value;
        return value;
    }

    function getBool(bytes32 key) external view returns (bool) {
        return boolValues[key];
    }

    function setBool(bytes32 key, bool value) external onlyController returns (bool) {
        boolValues[key] = value;
        return value;
    }

    function getString(bytes32 key) external view returns (string memory) {
        return stringValues[key];
    }

    function setString(bytes32 key, string memory value) external onlyController returns (string memory) {
        stringValues[key] = value;
        return value;
    }

    function getData(bytes32 key) external view returns (bytes32) {
        return dataValues[key];
    }

    function setData(bytes32 key, bytes32 value) external onlyController returns (bytes32) {
        dataValues[key] = value;
        return value;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../wrap/IWNT.sol";
import "./Bank.sol";

contract StrictBank is Bank {
    using SafeERC20 for IERC20;

    // used to record token balances to evaluate amounts transferred in
    mapping (address => uint256) public tokenBalances;

    constructor(RoleStore _roleStore) Bank(_roleStore) {}

    function recordTransferIn(address token) external onlyController returns (uint256) {
        return _recordTransferIn(token);
    }

    function _recordTransferIn(address token) internal returns (uint256) {
        uint256 prevBalance = tokenBalances[token];
        uint256 nextBalance = IERC20(token).balanceOf(address(this));
        tokenBalances[token] = nextBalance;

        return nextBalance - prevBalance;
    }

    function _afterTransferOut(address token) internal override {
        tokenBalances[token] = IERC20(token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Price {
    struct Props {
        uint256 min;
        uint256 max;
    }

    function isEmpty(Props memory props) internal pure returns (bool) {
        return props.min == 0 || props.max == 0;
    }

    function midPrice(Props memory props) internal pure returns (uint256) {
        return (props.max + props.min) / 2;
    }

    function pickPrice(Props memory props, bool maximize) internal pure returns (uint256) {
        return maximize ? props.max : props.min;
    }

    function pickPriceForPnl(Props memory props, bool isLong, bool maximize) internal pure returns (uint256) {
        // for long positions, pick the larger price to maximize pnl
        // for short positions, pick the smaller price to maximize pnl
        if (isLong) {
            return maximize ? props.max : props.min;
        }

        return maximize ? props.min : props.max;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// since the withdrawal store should be replaceable without requiring a migration
// use normal attributes instead of props mapping like in positions
library Withdrawal {
    struct Props {
        address account;
        address receiver;
        address callbackContract;
        address market;
        uint256 marketTokensLongAmount;
        uint256 marketTokensShortAmount;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        uint256 updatedAtBlock;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
        bytes data;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library FeeUtils {
    bytes32 public constant DEPOSIT_FEE = keccak256(abi.encode("DEPOSIT_FEE"));
    bytes32 public constant WITHDRAWAL_FEE = keccak256(abi.encode("WITHDRAWAL_FEE"));
    bytes32 public constant SWAP_FEE = keccak256(abi.encode("SWAP_FEE"));
    bytes32 public constant POSITION_FEE = keccak256(abi.encode("POSITION_FEE"));
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

contract FeeReceiver {
    event FeeReceived(bytes32 key, address token, uint256 amount);

    function notifyFeeReceived(bytes32 key, address token, uint256 amount) external {
        emit FeeReceived(key, token, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// borrowing fees for position require only a borrowingFactor to track
// an example on how this works is if the global cumulativeBorrowingFactor is 10020%
// a position would be opened with borrowingFactor as 10020%
// after some time, if the cumulativeBorrowingFactor is updated to 10025% the position would
// owe 5% of the position size as borrowing fees
// the total pending borrowing fees of all positions is factored into the calculation of the pool value for LPs
// when a position is increased or decreased, the pending borrowing fees for the position is deducted from the position's
// collateral and transferred into the LP pool
//
// the same borrowing fee factor tracking cannot be applied for funding fees as those calculations consider pending funding fees
// based on the fiat value of the position sizes
//
// for example, if the price of the longToken is $2000 and a long position owes $200 in funding fees, the opposing short position
// claims the funding fees of 0.1 longToken ($200), if the price of the longToken changes to $4000 later, the long position would
// only owe 0.05 longToken ($200)
// this would result in differences between the amounts deducted and amounts paid out, for this reason, the actual token amounts
// to be deducted and to be paid out need to be tracked instead
//
// for funding fees, there are four values to consider:
// 1. long positions with market.longToken as collateral
// 2. long positions with market.shortToken as collateral
// 3. short positions with market.longToken as collateral
// 4. short positions with market.shortToken as collateral
library Position {
    struct Props {
        address account;
        address market;
        address collateralToken;
        bool isLong;
        uint256 sizeInUsd;
        uint256 sizeInTokens;
        uint256 collateralAmount;
        uint256 borrowingFactor;
        int256 longTokenFundingAmountPerSize;
        int256 shortTokenFundingAmountPerSize;
        uint256 increasedAtBlock;
        uint256 decreasedAtBlock;
        bytes data;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Position.sol";
import "../role/RoleModule.sol";

contract PositionStore is RoleModule {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableValues for EnumerableSet.Bytes32Set;

    mapping(bytes32 => Position.Props) internal positions;
    EnumerableSet.Bytes32Set internal positionKeys;
    mapping(address => EnumerableSet.Bytes32Set) internal accountPositionKeys;

    constructor(RoleStore _roleStore) RoleModule(_roleStore) {}

    function set(bytes32 key, address account, Position.Props memory position) external onlyController {
        positions[key] = position;
        accountPositionKeys[account].add(key);
        positionKeys.add(key);
    }

    function remove(bytes32 key, address account) external onlyController {
        delete positions[key];
        accountPositionKeys[account].remove(key);
        positionKeys.remove(key);
    }

    function get(bytes32 key) external view returns (Position.Props memory) {
        return positions[key];
    }

    function getPositionCount() external view returns (uint256) {
        return positionKeys.length();
    }

    function getPositionKeys(uint256 start, uint256 end) external view returns (bytes32[] memory) {
        return positionKeys.valuesAt(start, end);
    }

    function getAccountPositionCount(address account) external view returns (uint256) {
        return accountPositionKeys[account].length();
    }

    function getAccountPositionKeys(address account, uint256 start, uint256 end) external view returns (bytes32[] memory) {
        return accountPositionKeys[account].valuesAt(start, end);
    }

    function contains(bytes32 key) public view returns (bool) {
        return positionKeys.contains(key);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../wrap/IWNT.sol";
import "./FundReceiver.sol";

contract Bank is FundReceiver {
    using SafeERC20 for IERC20;

    constructor(RoleStore _roleStore) FundReceiver(_roleStore) {}

    receive() external payable {}

    function transferOut(address token, uint256 amount, address receiver) external onlyController {
        _transferOut(token, amount, receiver);
    }

    function transferOut(
        address wnt,
        address token,
        uint256 amount,
        address receiver,
        bool shouldUnwrapNativeToken
    ) external onlyController {
        if (token == wnt && shouldUnwrapNativeToken) {
            _transferOutNativeToken(token, amount, receiver);
        } else {
            _transferOut(token, amount, receiver);
        }
    }

    function _transferOut(address token, uint256 amount, address receiver) internal {
        require(receiver != address(this), "Bank: invalid receiver");

        IERC20(token).safeTransfer(receiver, amount);

        _afterTransferOut(token);
    }

    function _transferOutNativeToken(address token, uint256 amount, address receiver) internal {
        require(receiver != address(this), "Bank: invalid receiver");

        IWNT(token).withdraw(amount);
        payable(receiver).transfer(amount);

        _afterTransferOut(token);
    }

    function _afterTransferOut(address /* token */) internal virtual {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IWNT {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ArbSys.sol";

library Chain {
    uint256 constant public ARBITRUM_CHAIN_ID = 42161;
    uint256 constant public ARBITRUM_RINKEBY_CHAIN_ID = 421611;

    ArbSys constant public arbSys = ArbSys(address(100));

    function currentBlockNumber() internal view returns (uint256) {
        if (block.chainid == ARBITRUM_CHAIN_ID || block.chainid == ARBITRUM_RINKEBY_CHAIN_ID) {
            return arbSys.arbBlockNumber();
        }

        return block.number;
    }

    function getBlockHash(uint256 blockNumber) internal view returns (bytes32) {
        if (block.chainid == ARBITRUM_CHAIN_ID || block.chainid == ARBITRUM_RINKEBY_CHAIN_ID) {
            return arbSys.arbBlockHash(blockNumber);
        }

        return blockhash(blockNumber);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ArbSys {
    function arbBlockNumber() external view returns (uint256);
    function arbBlockHash(uint256 blockNumber) external view returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../utils/Array.sol";
import "../utils/Bits.sol";

library OracleUtils {
    struct SetPricesParams {
        uint256 signerInfo;
        address[] tokens;
        uint256[] compactedOracleBlockNumbers;
        uint256[] compactedDecimals;
        uint256[] compactedMinPrices;
        uint256[] compactedMinPricesIndexes;
        uint256[] compactedMaxPrices;
        uint256[] compactedMaxPricesIndexes;
        bytes[] signatures;
        address[] priceFeedTokens;
    }

    // compacted prices have a length of 32 bits
    uint256 public constant COMPACTED_PRICE_BIT_LENGTH = 32;
    uint256 public constant COMPACTED_PRICE_BITMASK = Bits.BITMASK_32;

    // compacted precisions have a length of 8 bits
    uint256 public constant COMPACTED_PRECISION_BIT_LENGTH = 8;
    uint256 public constant COMPACTED_PRECISION_BITMASK = Bits.BITMASK_8;

    // compacted block numbers have a length of 64 bits
    uint256 public constant COMPACTED_BLOCK_NUMBER_BIT_LENGTH = 64;
    uint256 public constant COMPACTED_BLOCK_NUMBER_BITMASK = Bits.BITMASK_64;

    // compacted price indexes have a length of 8 bits
    uint256 public constant COMPACTED_PRICE_INDEX_BIT_LENGTH = 8;
    uint256 public constant COMPACTED_PRICE_INDEX_BITMASK = Bits.BITMASK_8;

    error EmptyCompactedPrice(uint256 index);
    error EmptyCompactedBlockNumber(uint256 index);

    function getUncompactedPrice(uint256[] memory compactedPrices, uint256 index) internal pure returns (uint256) {
        uint256 price = Array.getUncompactedValue(
            compactedPrices,
            index,
            COMPACTED_PRICE_BIT_LENGTH,
            COMPACTED_PRICE_BITMASK
        );

        if (price == 0) { revert EmptyCompactedPrice(index); }

        return price;
    }

    // covert compactedDecimals into precision values
    function getUncompactedPrecision(uint256[] memory compactedDecimals, uint256 index) internal pure returns (uint256) {
        uint256 precision = Array.getUncompactedValue(
            compactedDecimals,
            index,
            COMPACTED_PRECISION_BIT_LENGTH,
            COMPACTED_PRECISION_BITMASK
        );

        return 10 ** precision;
    }


    function getUncompactedPriceIndex(uint256[] memory compactedPriceIndexes, uint256 index) internal pure returns (uint256) {
        uint256 priceIndex = Array.getUncompactedValue(
            compactedPriceIndexes,
            index,
            COMPACTED_PRICE_INDEX_BIT_LENGTH,
            COMPACTED_PRICE_INDEX_BITMASK
        );

        return priceIndex;

    }

    function getUncompactedOracleBlockNumbers(uint256[] memory compactedOracleBlockNumbers, uint256 length) internal pure returns (uint256[] memory) {
        uint256[] memory blockNumbers = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            blockNumbers[i] = getUncompactedOracleBlockNumber(compactedOracleBlockNumbers, i);
        }

        return blockNumbers;
    }

    function getUncompactedOracleBlockNumber(uint256[] memory compactedOracleBlockNumbers, uint256 index) internal pure returns (uint256) {
        uint256 blockNumber = Array.getUncompactedValue(
            compactedOracleBlockNumbers,
            index,
            COMPACTED_BLOCK_NUMBER_BIT_LENGTH,
            COMPACTED_BLOCK_NUMBER_BITMASK
        );

        if (blockNumber == 0) { revert EmptyCompactedBlockNumber(index); }

        return blockNumber;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceFeed {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Keys {
    bytes32 public constant WNT = keccak256(abi.encode("WNT"));
    bytes32 public constant NONCE = keccak256(abi.encode("NONCE"));

    bytes32 public constant CREATE_DEPOSIT_FEATURE = keccak256(abi.encode("CREATE_DEPOSIT_FEATURE"));
    bytes32 public constant EXECUTE_DEPOSIT_FEATURE = keccak256(abi.encode("EXECUTE_DEPOSIT_FEATURE"));

    bytes32 public constant CREATE_WITHDRAWAL_FEATURE = keccak256(abi.encode("CREATE_WITHDRAWAL_FEATURE"));
    bytes32 public constant EXECUTE_WITHDRAWAL_FEATURE = keccak256(abi.encode("EXECUTE_WITHDRAWAL_FEATURE"));

    bytes32 public constant CREATE_ORDER_FEATURE = keccak256(abi.encode("CREATE_ORDER_FEATURE"));
    bytes32 public constant EXECUTE_ORDER_FEATURE = keccak256(abi.encode("EXECUTE_ORDER_FEATURE"));
    bytes32 public constant EXECUTE_ADL_FEATURE = keccak256(abi.encode("EXECUTE_ADL_FEATURE"));
    bytes32 public constant UPDATE_ORDER_FEATURE = keccak256(abi.encode("UPDATE_ORDER_FEATURE"));
    bytes32 public constant CANCEL_ORDER_FEATURE = keccak256(abi.encode("CANCEL_ORDER_FEATURE"));

    // the minimum required oracle signers for an observation
    bytes32 public constant MIN_ORACLE_SIGNERS = keccak256(abi.encode("MIN_ORACLE_SIGNERS"));
    // the minimum block confirmations before blockhash can be excluded for oracle signature validation
    bytes32 public constant MIN_ORACLE_BLOCK_CONFIRMATIONS = keccak256(abi.encode("MIN_ORACLE_BLOCK_CONFIRMATIONS"));
    // the maximum block age usable for oracle prices
    bytes32 public constant MAX_ORACLE_BLOCK_AGE = keccak256(abi.encode("MAX_ORACLE_BLOCK_AGE"));
    // the percentage amount of fees to be received for deposits
    bytes32 public constant FEE_RECEIVER_DEPOSIT_FACTOR = keccak256(abi.encode("FEE_RECEIVER_DEPOSIT_FACTOR"));
    // the percentage amount of fees to be received for withdrawals
    bytes32 public constant FEE_RECEIVER_WITHDRAWAL_FACTOR = keccak256(abi.encode("FEE_RECEIVER_WITHDRAWAL_FACTOR"));
    // the percentage amount of fees to be received for swaps
    bytes32 public constant FEE_RECEIVER_SWAP_FACTOR = keccak256(abi.encode("FEE_RECEIVER_SWAP_FACTOR"));
    // the percentage amount of fees to be received for positions
    bytes32 public constant FEE_RECEIVER_POSITION_FACTOR = keccak256(abi.encode("FEE_RECEIVER_POSITION_FACTOR"));

    bytes32 public constant ESTIMATED_FEE_BASE_GAS_LIMIT = keccak256(abi.encode("ESTIMATED_FEE_BASE_GAS_LIMIT"));
    bytes32 public constant ESTIMATED_FEE_MULTIPLIER_FACTOR = keccak256(abi.encode("ESTIMATED_FEE_MULTIPLIER_FACTOR"));

    bytes32 public constant EXECUTION_FEE_BASE_GAS_LIMIT = keccak256(abi.encode("EXECUTION_FEE_BASE_GAS_LIMIT"));
    bytes32 public constant EXECUTION_FEE_MULTIPLIER_FACTOR = keccak256(abi.encode("EXECUTION_FEE_MULTIPLIER_FACTOR"));

    bytes32 public constant DEPOSIT_GAS_LIMIT = keccak256(abi.encode("DEPOSIT_GAS_LIMIT"));
    bytes32 public constant WITHDRAWAL_GAS_LIMIT = keccak256(abi.encode("WITHDRAWAL_GAS_LIMIT"));
    bytes32 public constant SINGLE_SWAP_GAS_LIMIT = keccak256(abi.encode("SINGLE_SWAP_GAS_LIMIT"));
    bytes32 public constant INCREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("INCREASE_ORDER_GAS_LIMIT"));
    bytes32 public constant DECREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("DECREASE_ORDER_GAS_LIMIT"));
    bytes32 public constant SWAP_ORDER_GAS_LIMIT = keccak256(abi.encode("SWAP_ORDER_GAS_LIMIT"));
    bytes32 public constant CANCELLATION_GAS_LIMIT = keccak256(abi.encode("CANCELLATION_GAS_LIMIT"));

    bytes32 public constant MAX_LEVERAGE = keccak256(abi.encode("MAX_LEVERAGE"));
    bytes32 public constant MIN_COLLATERAL_USD = keccak256(abi.encode("MIN_COLLATERAL_USD"));

    bytes32 public constant POSITION_IMPACT_FACTOR = keccak256(abi.encode("POSITION_IMPACT_FACTOR"));
    bytes32 public constant POSITION_IMPACT_EXPONENT_FACTOR = keccak256(abi.encode("POSITION_IMPACT_EXPONENT_FACTOR"));
    bytes32 public constant POSITION_FEE_FACTOR = keccak256(abi.encode("POSITION_FEE_FACTOR"));
    bytes32 public constant SWAP_IMPACT_FACTOR = keccak256(abi.encode("SWAP_IMPACT_FACTOR"));
    bytes32 public constant SWAP_IMPACT_EXPONENT_FACTOR = keccak256(abi.encode("SWAP_IMPACT_EXPONENT_FACTOR"));
    bytes32 public constant SWAP_FEE_FACTOR = keccak256(abi.encode("SWAP_FEE_FACTOR"));
    bytes32 public constant ORACLE_TYPE = keccak256(abi.encode("ORACLE_TYPE"));
    bytes32 public constant OPEN_INTEREST = keccak256(abi.encode("OPEN_INTEREST"));
    bytes32 public constant OPEN_INTEREST_IN_TOKENS = keccak256(abi.encode("OPEN_INTEREST_IN_TOKENS"));
    bytes32 public constant COLLATERAL_SUM = keccak256(abi.encode("COLLATERAL_SUM"));
    bytes32 public constant POOL_AMOUNT = keccak256(abi.encode("POOL_AMOUNT"));
    bytes32 public constant POSITION_IMPACT_POOL_AMOUNT = keccak256(abi.encode("POSITION_IMPACT_POOL_AMOUNT"));
    bytes32 public constant SWAP_IMPACT_POOL_AMOUNT = keccak256(abi.encode("SWAP_IMPACT_POOL_AMOUNT"));
    bytes32 public constant PRICE_FEED = keccak256(abi.encode("PRICE_FEED"));
    bytes32 public constant PRICE_FEED_MULTIPLIER = keccak256(abi.encode("PRICE_FEED_MULTIPLIER"));
    bytes32 public constant STABLE_PRICE = keccak256(abi.encode("STABLE_PRICE"));
    bytes32 public constant RESERVE_FACTOR = keccak256(abi.encode("RESERVE_FACTOR"));
    bytes32 public constant MAX_PNL_FACTOR = keccak256(abi.encode("MAX_PNL_FACTOR"));
    bytes32 public constant MAX_PNL_FACTOR_FOR_WITHDRAWALS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS"));
    bytes32 public constant LATEST_ADL_BLOCK = keccak256(abi.encode("LATEST_ADL_BLOCK"));
    bytes32 public constant IS_ADL_ENABLED = keccak256(abi.encode("IS_ADL_ENABLED"));
    bytes32 public constant FUNDING_FACTOR = keccak256(abi.encode("FUNDING_FACTOR"));
    bytes32 public constant FUNDING_AMOUNT_PER_SIZE = keccak256(abi.encode("FUNDING_AMOUNT_PER_SIZE"));
    bytes32 public constant FUNDING_UPDATED_AT = keccak256(abi.encode("FUNDING_UPDATED_AT"));
    bytes32 public constant CLAIMABLE_FUNDING_AMOUNT = keccak256(abi.encode("CLAIMABLE_FUNDING_AMOUNT"));
    bytes32 public constant BORROWING_FACTOR = keccak256(abi.encode("BORROWING_FACTOR"));
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR = keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR"));
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR_UPDATED_AT = keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR_UPDATED_AT"));
    bytes32 public constant TOTAL_BORROWING = keccak256(abi.encode("TOTAL_BORROWING"));
    bytes32 public constant AFFILIATE_REWARD = keccak256(abi.encode("AFFILIATE_REWARD"));

    string public constant ORACLE_ERROR = "ORACLE_ERROR";
    bytes32 public constant ORACLE_ERROR_KEY = keccak256(abi.encode(ORACLE_ERROR));

    string public constant EMPTY_POSITION_ERROR = "EMPTY_POSITION_ERROR";
    bytes32 public constant EMPTY_POSITION_ERROR_KEY = keccak256(abi.encode(EMPTY_POSITION_ERROR));

    string public constant FROZEN_ORDER_ERROR = "FROZEN_ORDER_ERROR";
    bytes32 public constant FROZEN_ORDER_ERROR_KEY = keccak256(abi.encode(FROZEN_ORDER_ERROR));

    string public constant UNACCEPTABLE_PRICE_ERROR = "UNACCEPTABLE_PRICE_ERROR";
    bytes32 public constant UNACCEPTABLE_PRICE_ERROR_KEY = keccak256(abi.encode(UNACCEPTABLE_PRICE_ERROR));

    function depositGasLimitKey(bool singleToken) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            DEPOSIT_GAS_LIMIT,
            singleToken
        ));
    }

    function withdrawalGasLimitKey(bool singleToken) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            WITHDRAWAL_GAS_LIMIT,
            singleToken
        ));
    }

    function singleSwapGasLimitKey() internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SINGLE_SWAP_GAS_LIMIT
        ));
    }

    function increaseOrderGasLimitKey() internal pure returns (bytes32) {
        return keccak256(abi.encode(
            INCREASE_ORDER_GAS_LIMIT
        ));
    }

    function decreaseOrderGasLimitKey() internal pure returns (bytes32) {
        return keccak256(abi.encode(
            DECREASE_ORDER_GAS_LIMIT
        ));
    }

    function swapOrderGasLimitKey() internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_ORDER_GAS_LIMIT
        ));
    }

    function createDepositFeatureKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_DEPOSIT_FEATURE,
            module
        ));
    }

    function executeDepositFeatureKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_DEPOSIT_FEATURE,
            module
        ));
    }

    function createWithdrawalFeatureKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_WITHDRAWAL_FEATURE,
            module
        ));
    }

    function executeWithdrawalFeatureKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_WITHDRAWAL_FEATURE,
            module
        ));
    }

    function createOrderFeatureKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_ORDER_FEATURE,
            module,
            orderType
        ));
    }

    function executeOrderFeatureKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_ORDER_FEATURE,
            module,
            orderType
        ));
    }

    function executeAdlFeatureKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_ADL_FEATURE,
            module,
            orderType
        ));
    }

    function updateOrderFeatureKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            UPDATE_ORDER_FEATURE,
            module,
            orderType
        ));
    }

    function cancelOrderFeatureKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_ORDER_FEATURE,
            module,
            orderType
        ));
    }

    function positionImpactFactorKey(address market, bool isPositive) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_FACTOR,
            market,
            isPositive
        ));
   }

    function positionImpactExponentFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_EXPONENT_FACTOR,
            market
        ));
}

    function positionFeeFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_FEE_FACTOR,
            market
        ));
    }

    function swapImpactFactorKey(address market, bool isPositive) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_FACTOR,
            market,
            isPositive
        ));
    }

    function swapImpactExponentFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_EXPONENT_FACTOR,
            market
        ));
    }


    function swapFeeFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_FEE_FACTOR,
            market
        ));
    }

    function oracleTypeKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORACLE_TYPE,
            token
        ));
    }

    // market open interest
    function openInterestKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPEN_INTEREST,
            market,
            collateralToken,
            isLong
        ));
    }

    // market open interest in tokens
    function openInterestInTokensKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPEN_INTEREST_IN_TOKENS,
            market,
            collateralToken,
            isLong
        ));
    }

    // total collateral of positions
    function collateralSumKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            COLLATERAL_SUM,
            market,
            collateralToken,
            isLong
        ));
    }

    // amount of tokens in market pool
    function poolAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POOL_AMOUNT,
            market,
            token
        ));
    }

    // amount of tokens in position impact pool
    function positionImpactPoolAmountKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_POOL_AMOUNT,
            market
        ));
    }

    // amount of tokens in swap impact pool
    function swapImpactPoolAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_POOL_AMOUNT,
            market,
            token
        ));
    }

    function reserveFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            RESERVE_FACTOR,
            market,
            isLong
        ));
    }

    function maxPnlFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_PNL_FACTOR,
            market,
            isLong
        ));
    }

    function maxPnlFactorForWithdrawalsKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_PNL_FACTOR_FOR_WITHDRAWALS,
            market,
            isLong
        ));
    }

    function latestAdlBlockKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            LATEST_ADL_BLOCK,
            market,
            isLong
        ));
    }

    function isAdlEnabledKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            IS_ADL_ENABLED,
            market,
            isLong
        ));
    }

    function fundingFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_FACTOR,
            market
        ));
    }

    function fundingAmountPerSizeKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_AMOUNT_PER_SIZE,
            market,
            collateralToken,
            isLong
        ));
    }

    function fundingUpdatedAtKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_UPDATED_AT,
            market
        ));
    }

    function claimableFundingAmountKey(address market, address token, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_FUNDING_AMOUNT,
            market,
            token,
            account
        ));
    }

    function borrowingFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            BORROWING_FACTOR,
            market,
            isLong
        ));
    }

    function cumulativeBorrowingFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CUMULATIVE_BORROWING_FACTOR,
            market,
            isLong
        ));
    }

    function cumulativeBorrowingFactorUpdatedAtKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CUMULATIVE_BORROWING_FACTOR_UPDATED_AT,
            market,
            isLong
        ));
    }

    function totalBorrowingKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            TOTAL_BORROWING,
            market,
            isLong
        ));
    }

    function affiliateRewardKey(address market, address token, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            AFFILIATE_REWARD,
            market,
            token,
            account
        ));
    }

    function priceFeedKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PRICE_FEED,
            token
        ));
    }

    function priceFeedMultiplierKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PRICE_FEED_MULTIPLIER,
            token
        ));
    }

    function stablePriceKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            STABLE_PRICE,
            token
        ));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library Array {
    using SafeCast for int256;

    function get(bytes32[] memory arr, uint256 index) internal pure returns (bytes32) {
        if (index < arr.length) {
            return arr[index];
        }

        return bytes32(0);
    }

    function createCopy(bytes32[] memory arr, uint256 index, bytes32 value) internal pure returns (bytes32[] memory) {
        if (index < arr.length) {
            arr[index] = value;
            return arr;
        }

        bytes32[] memory newArr = createResized(arr, index + 1);
        newArr[index] = value;

        return newArr;
    }

    function createResized(bytes32[] memory arr, uint256 length) internal pure returns (bytes32[] memory) {
        if (length <= arr.length) {
            return arr;
        }

        bytes32[] memory newArr = new bytes32[](length);

        for (uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }

        return newArr;
    }

    function areEqualTo(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] != value) {
                return false;
            }
        }

        return true;
    }

    function areGreaterThan(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] <= value) {
                return false;
            }
        }

        return true;
    }

    function getMedian(uint256[] memory arr) internal pure returns (uint256) {
        if (arr.length % 2 == 1) {
            return arr[arr.length / 2];
        }

        return (arr[arr.length / 2] + arr[arr.length / 2 - 1]) / 2;
    }

    function getUncompactedValue(
        uint256[] memory compactedValues,
        uint256 index,
        uint256 compactedValueBitLength,
        uint256 bitmask
    ) internal pure returns (uint256) {
        uint256 compactedValuesPerSlot = 256 / compactedValueBitLength;

        uint256 slotIndex = index / compactedValuesPerSlot;
        uint256 slotBits = compactedValues[slotIndex];
        uint256 offset = (index - slotIndex * compactedValuesPerSlot) * compactedValueBitLength;

        uint256 value = (slotBits >> offset) & bitmask;

        return value;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Bits {
    // uint256(~0) is 256 bits of 1s
    // shift the 1s by (256 - 8) to get (256 - 8) 0s followed by 8 1s
    uint256 constant public BITMASK_8 = ~uint256(0) >> (256 - 8);
    // shift the 1s by (256 - 16) to get (256 - 16) 0s followed by 16 1s
    uint256 constant public BITMASK_16 = ~uint256(0) >> (256 - 16);
    // shift the 1s by (256 - 32) to get (256 - 32) 0s followed by 32 1s
    uint256 constant public BITMASK_32 = ~uint256(0) >> (256 - 32);
    // shift the 1s by (256 - 64) to get (256 - 64) 0s followed by 64 1s
    uint256 constant public BITMASK_64 = ~uint256(0) >> (256 - 64);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";

contract OracleStore is RoleModule {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;

    event SignerAdded(address signer);
    event SignerRemoved(address signer);

    EnumerableSet.AddressSet internal signers;

    constructor(RoleStore _roleStore) RoleModule(_roleStore) {}

    function addSigner(address account) external onlyController {
        signers.add(account);
        emit SignerAdded(account);
    }

    function removeSigner(address account) external onlyController {
        signers.remove(account);
        emit SignerRemoved(account);
    }

    function getSignerCount() external view returns (uint256) {
        return signers.length();
    }

    function getSigner(uint256 index) external view returns (address) {
        return signers.at(index);
    }

    function getSigners(uint256 start, uint256 end) external view returns (address[] memory) {
        return signers.valuesAt(start, end);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "./IWNT.sol";

library WrapUtils {
    using SafeERC20 for IERC20;

    function wnt(DataStore dataStore) internal view returns (address) {
        return dataStore.getAddress(Keys.WNT);
    }

    function sendWnt(DataStore dataStore, address receiver) internal returns (uint256) {
        if (msg.value == 0) { return 0; }

        address _wnt = wnt(dataStore);
        IWNT(_wnt).deposit{value: msg.value}();
        IERC20(_wnt).safeTransfer(address(receiver), msg.value);

        return msg.value;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../data/DataStore.sol";
import "../data/Keys.sol";

library NonceUtils {
    function getCurrentNonce(DataStore dataStore) internal view returns (uint256) {
        return dataStore.getUint(Keys.NONCE);
    }

    function incrementNonce(DataStore dataStore) internal returns (uint256) {
        return dataStore.incrementUint(Keys.NONCE, 1);
    }

    // position keys are bytes32 values based on a hash of the position account,
    // market, collateral token and whether the position is long / short
    // see PositionUtils for more details
    // return bytes32 here as well instead of uint256 so that all keys have the
    // same bytes32 type
    function getNextKey(DataStore dataStore) internal returns (bytes32) {
        uint256 nonce = incrementNonce(dataStore);
        bytes32 key = keccak256(abi.encode(nonce));

        return key;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../utils/Precision.sol";

import "../deposit/Deposit.sol";
import "../withdrawal/Withdrawal.sol";
import "../order/Order.sol";
import "../order/OrderBaseUtils.sol";

import "../bank/StrictBank.sol";
import "../wrap/WrapUtils.sol";
import "../wrap/IWNT.sol";

library GasUtils {
    using Order for Order.Props;

    event KeeperExecutionFee(address keeper, uint256 amount);
    event UserRefundFee(address keeper, uint256 amount, bool success);

    error InsufficientExecutionFee(uint256 minExecutionFee, uint256 executionFee);

    function payExecutionFee(
        DataStore dataStore,
        StrictBank bank,
        uint256 executionFee,
        uint256 startingGas,
        address keeper,
        address user
    ) external {
        address wnt = WrapUtils.wnt(dataStore);
        bank.transferOut(wnt, executionFee, address(this));
        IWNT(wnt).withdraw(executionFee);

        uint256 gasUsed = startingGas - gasleft();
        uint256 executionFeeForKeeper = adjustGasLimit(dataStore, gasUsed) * tx.gasprice;

        if (executionFeeForKeeper > executionFee) {
            executionFeeForKeeper = executionFee;
        }

        payable(keeper).transfer(executionFeeForKeeper);
        emit KeeperExecutionFee(keeper, executionFeeForKeeper);

        uint256 refundFeeForUser = executionFee - executionFeeForKeeper;
        if (refundFeeForUser == 0) {
            return;
        }

        // it is possible to force a transaction to fail by having the user
        // be a contract and modifying the receive function
        // this can cause front-running issues, due to that `send` is used instead
        //  of `transfer` so that the transaction will not revert
        bool success = payable(user).send(refundFeeForUser);
        emit UserRefundFee(user, refundFeeForUser, success);
    }

    function validateExecutionFee(DataStore dataStore, uint256 estimatedGasLimit, uint256 executionFee) internal view {
        uint256 gasLimit = adjustGasLimitForEstimate(dataStore, estimatedGasLimit);
        uint256 minExecutionFee = gasLimit * tx.gasprice;
        if (executionFee < minExecutionFee) {
            revert InsufficientExecutionFee(minExecutionFee, executionFee);
        }
    }

    function adjustGasLimit(DataStore dataStore, uint256 estimatedGasLimit) internal view returns (uint256) {
        uint256 baseGasLimit = dataStore.getUint(Keys.EXECUTION_FEE_BASE_GAS_LIMIT);
        uint256 multiplierFactor = dataStore.getUint(Keys.EXECUTION_FEE_MULTIPLIER_FACTOR);
        uint256 gasLimit = baseGasLimit + Precision.applyFactor(estimatedGasLimit, multiplierFactor);
        return gasLimit;
    }

    function adjustGasLimitForEstimate(DataStore dataStore, uint256 estimatedGasLimit) internal view returns (uint256) {
        uint256 baseGasLimit = dataStore.getUint(Keys.ESTIMATED_FEE_BASE_GAS_LIMIT);
        uint256 multiplierFactor = dataStore.getUint(Keys.ESTIMATED_FEE_MULTIPLIER_FACTOR);
        uint256 gasLimit = baseGasLimit + Precision.applyFactor(estimatedGasLimit, multiplierFactor);
        return gasLimit;
    }

    function estimateExecuteDepositGasLimit(DataStore dataStore, Deposit.Props memory deposit) internal view returns (uint256) {
        if (deposit.longTokenAmount == 0 || deposit.shortTokenAmount == 0) {
            return dataStore.getUint(Keys.depositGasLimitKey(true)) + deposit.callbackGasLimit;
        }

        return dataStore.getUint(Keys.depositGasLimitKey(false)) + deposit.callbackGasLimit;
    }

    function estimateExecuteWithdrawalGasLimit(DataStore dataStore, Withdrawal.Props memory withdrawal) internal view returns (uint256) {
        if (withdrawal.marketTokensLongAmount == 0 || withdrawal.marketTokensShortAmount == 0) {
            return dataStore.getUint(Keys.withdrawalGasLimitKey(true)) + withdrawal.callbackGasLimit;
        }

        return dataStore.getUint(Keys.withdrawalGasLimitKey(false)) + withdrawal.callbackGasLimit;
    }

    function estimateExecuteOrderGasLimit(DataStore dataStore, Order.Props memory order) internal view returns (uint256) {
        if (OrderBaseUtils.isIncreaseOrder(order.orderType())) {
            return estimateExecuteIncreaseOrderGasLimit(dataStore, order);
        }

        if (OrderBaseUtils.isDecreaseOrder(order.orderType())) {
            return estimateExecuteDecreaseOrderGasLimit(dataStore, order);
        }

        if (OrderBaseUtils.isSwapOrder(order.orderType())) {
            return estimateExecuteSwapOrderGasLimit(dataStore, order);
        }

        OrderBaseUtils.revertUnsupportedOrderType();
    }

    function estimateExecuteIncreaseOrderGasLimit(DataStore dataStore, Order.Props memory order) internal view returns (uint256) {
        uint256 gasPerSwap = dataStore.getUint(Keys.singleSwapGasLimitKey());
        return dataStore.getUint(Keys.increaseOrderGasLimitKey()) + gasPerSwap * order.swapPath().length + order.callbackGasLimit();
    }

    function estimateExecuteDecreaseOrderGasLimit(DataStore dataStore, Order.Props memory order) internal view returns (uint256) {
        uint256 gasPerSwap = dataStore.getUint(Keys.singleSwapGasLimitKey());
        return dataStore.getUint(Keys.decreaseOrderGasLimitKey()) + gasPerSwap * order.swapPath().length + order.callbackGasLimit();
    }

    function estimateExecuteSwapOrderGasLimit(DataStore dataStore, Order.Props memory order) internal view returns (uint256) {
        uint256 gasPerSwap = dataStore.getUint(Keys.singleSwapGasLimitKey());
        return dataStore.getUint(Keys.swapOrderGasLimitKey()) + gasPerSwap * order.swapPath().length + order.callbackGasLimit();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import "./IOrderCallbackReceiver.sol";
import "./IDepositCallbackReceiver.sol";
import "./IWithdrawalCallbackReceiver.sol";

// half of the callbackGasLimit value is forwarded per call since
// both before and after functions would be called
library CallbackUtils {
    using Address for address;
    using Deposit for Deposit.Props;
    using Withdrawal for Withdrawal.Props;
    using Order for Order.Props;

    function beforeDepositExecution(bytes32 key, Deposit.Props memory deposit) internal {
        if (!isValidCallbackContract(deposit.callbackContract)) { return; }

        try IDepositCallbackReceiver(deposit.callbackContract).beforeDepositExecution{ gas: deposit.callbackGasLimit / 2 }(key, deposit) {
        } catch {}
    }

    function afterDepositExecution(bytes32 key, Deposit.Props memory deposit) internal {
        if (!isValidCallbackContract(deposit.callbackContract)) { return; }

        try IDepositCallbackReceiver(deposit.callbackContract).afterDepositExecution{ gas: deposit.callbackGasLimit / 2 }(key, deposit) {
        } catch {}
    }

    function afterDepositCancellation(bytes32 key, Deposit.Props memory deposit) internal {
        if (!isValidCallbackContract(deposit.callbackContract)) { return; }

        try IDepositCallbackReceiver(deposit.callbackContract).afterDepositCancellation{ gas: deposit.callbackGasLimit / 2 }(key, deposit) {
        } catch {}
    }

    function beforeWithdrawalExecution(bytes32 key, Withdrawal.Props memory withdrawal) internal {
        if (!isValidCallbackContract(withdrawal.callbackContract)) { return; }

        try IWithdrawalCallbackReceiver(withdrawal.callbackContract).beforeWithdrawalExecution{ gas: withdrawal.callbackGasLimit / 2 }(key, withdrawal) {
        } catch {}
    }

    function afterWithdrawalExecution(bytes32 key, Withdrawal.Props memory withdrawal) internal {
        if (!isValidCallbackContract(withdrawal.callbackContract)) { return; }

        try IWithdrawalCallbackReceiver(withdrawal.callbackContract).afterWithdrawalExecution{ gas: withdrawal.callbackGasLimit / 2 }(key, withdrawal) {
        } catch {}
    }

    function afterWithdrawalCancellation(bytes32 key, Withdrawal.Props memory withdrawal) internal {
        if (!isValidCallbackContract(withdrawal.callbackContract)) { return; }

        try IWithdrawalCallbackReceiver(withdrawal.callbackContract).afterWithdrawalCancellation{ gas: withdrawal.callbackGasLimit / 2 }(key, withdrawal) {
        } catch {}
    }

    function beforeOrderExecution(bytes32 key, Order.Props memory order) internal {
        if (!isValidCallbackContract(order.callbackContract())) { return; }

        try IOrderCallbackReceiver(order.callbackContract()).beforeOrderExecution{ gas: order.callbackGasLimit() / 2 }(key, order) {
        } catch {}
    }

    function afterOrderExecution(bytes32 key, Order.Props memory order) internal {
        if (!isValidCallbackContract(order.callbackContract())) { return; }

        try IOrderCallbackReceiver(order.callbackContract()).afterOrderExecution{ gas: order.callbackGasLimit() / 2 }(key, order) {
        } catch {}
    }

    function afterOrderCancellation(bytes32 key, Order.Props memory order) internal {
        if (!isValidCallbackContract(order.callbackContract())) { return; }

        try IOrderCallbackReceiver(order.callbackContract()).afterOrderCancellation{ gas: order.callbackGasLimit() / 2 }(key, order) {
        } catch {}
    }

    function afterOrderFrozen(bytes32 key, Order.Props memory order) internal {
        if (!isValidCallbackContract(order.callbackContract())) { return; }

        try IOrderCallbackReceiver(order.callbackContract()).afterOrderFrozen{ gas: order.callbackGasLimit() / 2 }(key, order) {
        } catch {}
    }

    function isValidCallbackContract(address callbackContract) internal view returns (bool) {
        if (callbackContract == address(0)) { return false; }
        if (!callbackContract.isContract()) { return false; }

        return true;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Null {
    bytes public constant BYTES = "";
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Order.sol";
import "../market/Market.sol";

import "../data/DataStore.sol";
import "../event/EventEmitter.sol";

import "../order/OrderStore.sol";
import "../position/PositionStore.sol";

import "../oracle/Oracle.sol";

// OrderUtils has the function executeOrder, which uses IncreaseOrderUtils, DecreaseOrderUtils, SwapOrderUtils
// those libraries need some common functions contained here
library OrderBaseUtils {
    using Order for Order.Props;
    using Price for Price.Props;

    struct CreateOrderParams {
        address receiver;
        address callbackContract;
        address market;
        address initialCollateralToken;
        address[] swapPath;

        uint256 sizeDeltaUsd;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;

        Order.OrderType orderType;
        bool isLong;
        bool shouldUnwrapNativeToken;
    }

    struct ExecuteOrderParams {
        bytes32 key;
        Order.Props order;
        Market.Props[] swapPathMarkets;
        DataStore dataStore;
        EventEmitter eventEmitter;
        OrderStore orderStore;
        PositionStore positionStore;
        Oracle oracle;
        FeeReceiver feeReceiver;
        IReferralStorage referralStorage;
        uint256[] oracleBlockNumbers;
        Market.Props market;
        address keeper;
        uint256 startingGas;
        bytes32 positionKey;
    }

    error EmptyOrder();
    error UnsupportedOrderType();

    function isMarketOrder(Order.OrderType orderType) internal pure returns (bool) {
        return orderType == Order.OrderType.MarketSwap ||
               orderType == Order.OrderType.MarketIncrease ||
               orderType == Order.OrderType.MarketDecrease ||
               orderType == Order.OrderType.Liquidation;
    }

    function isLimitOrder(Order.OrderType orderType) internal pure returns (bool) {
        return orderType == Order.OrderType.LimitSwap ||
               orderType == Order.OrderType.LimitIncrease ||
               orderType == Order.OrderType.LimitDecrease;
    }

    function isSwapOrder(Order.OrderType orderType) internal pure returns (bool) {
        return orderType == Order.OrderType.MarketSwap ||
               orderType == Order.OrderType.LimitSwap;
    }

    function isPositionOrder(Order.OrderType orderType) internal pure returns (bool) {
        return orderType == Order.OrderType.MarketIncrease ||
               orderType == Order.OrderType.LimitIncrease;
    }

    function isIncreaseOrder(Order.OrderType orderType) internal pure returns (bool) {
        return orderType == Order.OrderType.MarketIncrease ||
               orderType == Order.OrderType.LimitIncrease;
    }

    function isDecreaseOrder(Order.OrderType orderType) internal pure returns (bool) {
        return orderType == Order.OrderType.MarketDecrease ||
               orderType == Order.OrderType.LimitDecrease ||
               orderType == Order.OrderType.StopLossDecrease ||
               orderType == Order.OrderType.Liquidation;
    }

    function isLiquidationOrder(Order.OrderType orderType) internal pure returns (bool) {
        return orderType == Order.OrderType.Liquidation;
    }

    // for market orders, set the min and max values of the customPrice to either
    // secondaryPrice.min or secondaryPrice.max depending on whether the order
    // is an increase or decrease and whether it is for a long or short
    //
    // customPrice.min and customPrice.max will be equal in this case
    // this is because in getExecutionPrice the function will try to use the closest price which can fulfill
    // the order, if customPrice.min is set to secondaryPrice.min and customPrice.max is set to secondaryPrice.max
    // getExecutionPrice will pick a better price than what should be possible
    //
    // for limit / stop-loss orders, the min and max value will be set to the triggerPrice
    // and latest secondaryPrice value, this represents the price that the user desired the order
    // to be fulfilled at and the best oracle price that the order could be fulfilled at
    //
    // getExecutionPrice handles the logic for selecting the execution price to use
    function setExactOrderPrice(
        Oracle oracle,
        address indexToken,
        Order.OrderType orderType,
        uint256 triggerPrice,
        bool isLong
    ) internal {
        if (isSwapOrder(orderType)) {
            return;
        }

        bool isIncrease = isIncreaseOrder(orderType);
        // increase order:
        //     - long: use the larger price
        //     - short: use the smaller price
        // decrease order:
        //     - long: use the smaller price
        //     - short: use the larger price
        bool shouldUseMaxPrice = isIncrease ? isLong : !isLong;

        // set secondary price to primary price since increase / decrease positions use the secondary price for index token values
        if (orderType == Order.OrderType.MarketIncrease ||
            orderType == Order.OrderType.MarketDecrease ||
            orderType == Order.OrderType.Liquidation) {

            Price.Props memory price = oracle.getPrimaryPrice(indexToken);

            oracle.setCustomPrice(indexToken, Price.Props(
                price.pickPrice(shouldUseMaxPrice),
                price.pickPrice(shouldUseMaxPrice)
            ));

            return;
        }

        if (orderType == Order.OrderType.LimitIncrease ||
            orderType == Order.OrderType.LimitDecrease ||
            orderType == Order.OrderType.StopLossDecrease
        ) {
            uint256 primaryPrice = oracle.getPrimaryPrice(indexToken).pickPrice(shouldUseMaxPrice);
            uint256 secondaryPrice = oracle.getSecondaryPrice(indexToken).pickPrice(shouldUseMaxPrice);

            // increase order:
            //     - long: validate descending price
            //     - short: validate ascending price
            // decrease order:
            //     - long: validate ascending price
            //     - short: validate descending price
            bool shouldValidateAscendingPrice = isIncrease ? !isLong : isLong;

            if (shouldValidateAscendingPrice) {
                // check that the earlier price (primaryPrice) is smaller than the triggerPrice
                // and that the later price (secondaryPrice) is larger than the triggerPrice
                bool ok = primaryPrice <= triggerPrice && triggerPrice <= secondaryPrice;
                if (!ok) { revert(Keys.ORACLE_ERROR); }

                oracle.setCustomPrice(indexToken, Price.Props(
                    triggerPrice, // min price that order can be executed with
                    secondaryPrice // max price that order can be executed with
                ));
            } else {
                // check that the earlier price (primaryPrice) is larger than the triggerPrice
                // and that the later price (secondaryPrice) is smaller than the triggerPrice
                bool ok = primaryPrice >= triggerPrice && triggerPrice >= secondaryPrice;
                if (!ok) { revert(Keys.ORACLE_ERROR); }

                oracle.setCustomPrice(indexToken, Price.Props(
                    secondaryPrice, // min price that order can be executed with
                    triggerPrice // max price that order can be executed with
                ));
            }

            return;
        }

        revertUnsupportedOrderType();
    }

    // see setExactOrderPrice for information on the customPrice values
    //
    // for limit / stop-loss orders, the triggerPrice is returned here if it can
    // fulfill the acceptablePrice after factoring in price impact
    //
    // if the triggerPrice cannot fulfill the acceptablePrice, check if the acceptablePrice
    // can be fulfilled using the best oracle price after factoring in price impact
    // if it can be fulfilled, fulfill the order at the acceptablePrice
    function getExecutionPrice(
        Price.Props memory customPrice,
        uint256 sizeDeltaUsd,
        int256 priceImpactUsd,
        uint256 acceptablePrice,
        bool isLong,
        bool isIncrease
    ) internal pure returns (uint256) {
        // increase order:
        //     - long: use the larger price
        //     - short: use the smaller price
        // decrease order:
        //     - long: use the smaller price
        //     - short: use the larger price
        bool shouldUseMaxPrice = isIncrease ? isLong : !isLong;

        // should price be smaller than acceptablePrice
        // increase order:
        //     - long: price should be smaller than acceptablePrice
        //     - short: price should be larger than acceptablePrice
        // decrease order:
        //     - long: price should be larger than acceptablePrice
        //     - short: price should be smaller than acceptablePrice
        bool shouldPriceBeSmaller = isIncrease ? isLong : !isLong;

        // for market orders, customPrice.min and customPrice.max should be equal, see setExactOrderPrice for more info
        // for limit orders, customPrice contains the triggerPrice and the best oracle
        // price, we first attempt to fulfill the order using the triggerPrice
        uint256 price = customPrice.pickPrice(shouldUseMaxPrice);

        // increase order:
        //     - long: lower price for positive impact, higher price for negative impact
        //     - short: higher price for positive impact, lower price for negative impact
        // decrease order:
        //     - long: higher price for positive impact, lower price for negative impact
        //     - short: lower price for positive impact, higher price for negative impact
        bool shouldFlipPriceImpactUsd = isIncrease ? isLong : !isLong;
        int256 priceImpactUsdForPriceAdjustment = shouldFlipPriceImpactUsd ? -priceImpactUsd : priceImpactUsd;

        // adjust price by price impact
        price = price * Calc.sum(sizeDeltaUsd, priceImpactUsdForPriceAdjustment) / sizeDeltaUsd;

        if (shouldPriceBeSmaller && price <= acceptablePrice) {
            return price;
        }

        if (!shouldPriceBeSmaller && price >= acceptablePrice) {
            return price;
        }

        // if the order could not be fulfilled using the triggerPrice
        // check if the best oracle price can fulfill the order
        price = customPrice.pickPrice(!shouldUseMaxPrice);

        // adjust price by price impact
        price = price * Calc.sum(sizeDeltaUsd, priceImpactUsdForPriceAdjustment) / sizeDeltaUsd;

        if (shouldPriceBeSmaller && price <= acceptablePrice) {
            return acceptablePrice;
        }

        if (!shouldPriceBeSmaller && price >= acceptablePrice) {
            return acceptablePrice;
        }

        revert(Keys.UNACCEPTABLE_PRICE_ERROR);
    }

    function validateNonEmptyOrder(Order.Props memory order) internal pure {
        if (order.account() == address(0)) {
            revert EmptyOrder();
        }
    }

    function revertUnsupportedOrderType() internal pure {
        revert UnsupportedOrderType();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Order.sol";
import "../role/RoleModule.sol";
import "../bank/StrictBank.sol";

contract OrderStore is StrictBank {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableValues for EnumerableSet.Bytes32Set;
    using Order for Order.Props;

    mapping(bytes32 => Order.Props) public orders;
    EnumerableSet.Bytes32Set internal orderKeys;
    mapping(address => EnumerableSet.Bytes32Set) internal accountOrderKeys;

    constructor(RoleStore _roleStore) StrictBank(_roleStore) {}

    function set(bytes32 key, Order.Props memory order) external onlyController {
        orders[key] = order;
        accountOrderKeys[order.account()].add(key);
        orderKeys.add(key);
    }

    function remove(bytes32 key, address account) external onlyController {
        delete orders[key];
        accountOrderKeys[account].remove(key);
        orderKeys.remove(key);
    }

    function get(bytes32 key) external view returns (Order.Props memory) {
        return orders[key];
    }

    function getOrderCount() external view returns (uint256) {
        return orderKeys.length();
    }

    function getOrderKeys(uint256 start, uint256 end) external view returns (bytes32[] memory) {
        return orderKeys.valuesAt(start, end);
    }

    function getAccountOrderCount(address account) external view returns (uint256) {
        return accountOrderKeys[account].length();
    }

    function getAccountOrderKeys(address account, uint256 start, uint256 end) external view returns (bytes32[] memory) {
        return accountOrderKeys[account].valuesAt(start, end);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../order/Order.sol";

interface IOrderCallbackReceiver {
    function beforeOrderExecution(bytes32 key, Order.Props memory order) external;
    function afterOrderExecution(bytes32 key, Order.Props memory order) external;
    function afterOrderCancellation(bytes32 key, Order.Props memory order) external;
    function afterOrderFrozen(bytes32 key, Order.Props memory order) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../deposit/Deposit.sol";

interface IDepositCallbackReceiver {
    function beforeDepositExecution(bytes32 key, Deposit.Props memory deposit) external;
    function afterDepositExecution(bytes32 key, Deposit.Props memory deposit) external;
    function afterDepositCancellation(bytes32 key, Deposit.Props memory deposit) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../withdrawal/Withdrawal.sol";

interface IWithdrawalCallbackReceiver {
    function beforeWithdrawalExecution(bytes32 key, Withdrawal.Props memory withdrawal) external;
    function afterWithdrawalExecution(bytes32 key, Withdrawal.Props memory withdrawal) external;
    function afterWithdrawalCancellation(bytes32 key, Withdrawal.Props memory withdrawal) external;
}