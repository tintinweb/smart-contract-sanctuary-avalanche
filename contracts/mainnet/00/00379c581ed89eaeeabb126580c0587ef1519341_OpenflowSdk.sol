// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
import {ISettlement} from "../interfaces/ISettlement.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {OrderDelegator} from "./OrderDelegator.sol";

contract OpenflowSdk is OrderDelegator {
    /// @notice Initialize SDK.
    /// @dev Can only be initialized once.
    /// @dev SDK is automatically initialized during instance creation.
    function initialize(
        address settlement,
        address _manager,
        address _sender,
        address _recipient
    ) external {
        _initialize(settlement, _manager, _sender, _recipient);
    }

    /*******************************************************
     * Order creation
     *******************************************************/
    /// @notice Fully configurable swap
    /// @param payload Complete swap payload
    /// @dev If not all options are set in payload defaults will be used
    /// @return orderUid UID of the order
    function submitOrder(
        ISettlement.Payload memory payload
    ) external returns (bytes memory orderUid) {
        orderUid = _submitOrder(payload);
    }

    /// @notice Simple swap alias
    /// @param fromToken Token to swap from
    /// @param toToken Token to swap to
    /// @return orderUid UID of the order
    function swap(
        address fromToken,
        address toToken
    ) public returns (bytes memory orderUid) {
        ISettlement.Payload memory payload;
        payload.fromToken = fromToken;
        payload.toToken = toToken;
        orderUid = _submitOrder(payload);
    }

    /// @notice Sell as price of fromToken goes up
    /// TODO: Implement
    /// @param fromToken Token to swap from
    /// @param toToken Token to swap to
    /// @return orderUid UID of the order
    function incrementalSwap(
        address fromToken,
        address toToken,
        uint256 targetPrice,
        uint256 stopLossPrice,
        uint256 steps
    ) public returns (bytes memory orderUid) {}

    /// @notice Sell as price of fromToken goes up
    /// TODO: Implement
    /// @param fromToken Token to swap from
    /// @param toToken Token to swap to
    /// @return orderUid UID of the order
    function dcaSwap(
        address fromToken,
        address toToken,
        uint256 targetPrice,
        uint256 stopLossPrice,
        uint256 steps
    ) public returns (bytes memory orderUid) {}

    /// @notice Alias to sell token only after a certain time
    /// @param fromToken Token to swap from
    /// @param toToken Token to swap to
    /// @param validFrom Unix timestamp from which to start the auction
    /// @return orderUid UID of the order
    function gatSwap(
        address fromToken,
        address toToken,
        uint32 validFrom
    ) public returns (bytes memory orderUid) {
        ISettlement.Payload memory payload;
        payload.fromToken = fromToken;
        payload.toToken = toToken;
        payload.validFrom = validFrom;
        orderUid = _submitOrder(payload);
    }

    /// @notice Alias to sell token only if a certain condition is met
    /// @param fromToken Token to swap from
    /// @param toToken Token to swap to
    /// @param fromToken Token to swap from
    /// @param condition Condition which must be met for a swap to succeed
    /// @return orderUid UID of the order
    function conditionalSwap(
        address fromToken,
        address toToken,
        ISettlement.Condition memory condition
    ) public returns (bytes memory orderUid) {
        ISettlement.Payload memory payload;
        payload.fromToken = fromToken;
        payload.toToken = toToken;
        // payload.condition = condition;
        orderUid = _submitOrder(payload);
    }

    /// @notice Internal swap method
    /// @dev Responsible for authentication and default param selection
    /// @param payload Order payload
    /// @return orderUid UID of the order
    function _submitOrder(
        ISettlement.Payload memory payload
    ) internal auth returns (bytes memory orderUid) {
        if (payload.recipient == address(0)) {
            payload.recipient = options.recipient;
        }
        if (payload.fromAmount == 0) {
            payload.fromAmount = IERC20(payload.fromToken).balanceOf(
                options.sender
            );
        }

        // payload.hooks.preHooks = _appendTransferToPreswapHooks(
        //     payload.hooks.preHooks,
        //     payload.fromToken,
        //     payload.fromAmount
        // );
        payload.sender = address(this);
        if (payload.toAmount == 0) {
            try
                IOracle(options.oracle).calculateEquivalentAmountAfterSlippage(
                    payload.fromToken,
                    payload.toToken,
                    payload.fromAmount,
                    options.slippageBips
                )
            returns (uint256 toAmount) {
                payload.toAmount = toAmount;
            } catch {
                if (options.requireOracle) {
                    revert("Oracle is not able to find an appropriate price");
                }
            }
        }
        if (payload.validFrom == 0) {
            payload.validFrom = uint32(block.timestamp);
        }
        if (payload.validTo == 0) {
            uint256 auctionDuration = options.auctionDuration;
            payload.validTo = uint32(payload.validFrom + auctionDuration);
        }
        if (payload.driver == address(0)) {
            payload.driver = options.driver;
        }
        payload.scheme = ISettlement.Scheme.PreSign;
        orderUid = ISettlement(_settlement).submitOrder(payload);
    }

    /*******************************************************
     * Order Invalidation
     *******************************************************/
    function invalidateOrder(bytes memory orderUid) external onlyManager {
        ISettlement(_settlement).invalidateOrder(orderUid);
    }

    function invalidateAllOrders() external onlyManager {
        ISettlement(_settlement).invalidateAllOrders();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISettlement {
    enum Scheme {
        Eip712,
        EthSign,
        Eip1271,
        PreSign
    }

    struct Order {
        bytes signature;
        bytes multisigSignature;
        bytes data;
        Payload payload;
    }

    struct Payload {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address sender;
        address recipient;
        uint32 validFrom;
        uint32 validTo;
        address driver;
        Scheme scheme;
        Condition condition;
        Condition[] conditions;
        // Hooks hooks;
    }

    struct Interaction {
        address target;
        bytes data;
        uint256 value;
    }

    struct Hooks {
        Interaction[] preHooks;
        Interaction[] postHooks;
    }

    struct Condition {
        address target;
        bytes data;
    }

    function checkNSignatures(
        address driver,
        bytes32 digest,
        bytes memory signatures,
        uint256 requiredSignatures
    ) external view;

    function executeOrder(Order memory) external;

    function buildDigest(Payload memory) external view returns (bytes32 digest);

    function recoverSigner(
        Scheme scheme,
        bytes32 digest,
        bytes memory signature
    ) external view returns (address signatory);

    function executionProxy() external view returns (address executionProxy);

    function defaultDriver() external view returns (address driver);

    function defaultOracle() external view returns (address driver);

    function digestApproved(
        address signatory,
        bytes32 digest
    ) external view returns (bool approved);

    function submitOrder(
        ISettlement.Payload memory payload
    ) external returns (bytes memory orderUid);

    function invalidateOrder(bytes memory orderUid) external;

    function invalidateAllOrders() external;
}

interface ISolver {
    function hook(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function approve(address, uint256) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IOracle {
    function calculateEquivalentAmountAfterSlippage(
        address _fromToken,
        address _toToken,
        uint256 _amountIn,
        uint256 _slippageBips
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
import {SdkStorage} from "./SdkStorage.sol";
import {ISettlement} from "../interfaces/ISettlement.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract OrderDelegator is SdkStorage {
    /// @notice Transfer funds from authenticated sender to settlement.
    /// @dev This function is only callable when sent as a pre-swap hook from
    /// executionProxy, where sender is authenticated with signature
    /// verification in settlement.
    function transferToSettlement(
        address sender,
        address fromToken,
        uint256 fromAmount
    ) external {
        require(msg.sender == _executionProxy, "Only execution proxy");
        address signatory;
        assembly {
            signatory := shr(96, calldataload(sub(calldatasize(), 20)))
        }
        require(
            signatory == address(this),
            "Transfer must be initiated from SDK"
        );
        IERC20(fromToken).transferFrom(sender, _settlement, fromAmount);
    }

    function _appendTransferToPreswapHooks(
        ISettlement.Interaction[] memory existingHooks,
        address fromToken,
        uint256 fromAmount
    ) internal view returns (ISettlement.Interaction[] memory appendedHooks) {
        bytes memory transferToSettlementData = abi.encodeWithSignature(
            "transferToSettlement(address,address,uint256)",
            options.sender,
            fromToken,
            fromAmount
        );
        appendedHooks = new ISettlement.Interaction[](existingHooks.length + 1);
        for (
            uint256 preswapHookIdx;
            preswapHookIdx < existingHooks.length;
            preswapHookIdx++
        ) {
            appendedHooks[preswapHookIdx] = existingHooks[preswapHookIdx];
        }
        appendedHooks[existingHooks.length] = ISettlement.Interaction({
            target: address(this),
            data: transferToSettlementData,
            value: 0
        });
        return appendedHooks;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
import {ISettlement} from "../interfaces/ISettlement.sol";
import "../interfaces/IOpenflow.sol";

contract SdkStorage {
    IOpenflowSdk.Options public options;
    address internal _settlement;
    address internal _executionProxy;

    function _initialize(
        address settlement,
        address _manager,
        address _sender,
        address _recipient
    ) internal {
        require(_settlement == address(0), "Already initialized");
        _settlement = settlement;
        _executionProxy = ISettlement(settlement).executionProxy();
        options.driver = ISettlement(settlement).defaultDriver();
        options.oracle = ISettlement(settlement).defaultOracle();
        options.slippageBips = 150;
        options.manager = _manager;
        options.sender = _sender;
        options.recipient = _recipient;
    }

    function setOptions(
        IOpenflowSdk.Options memory _options
    ) public onlyManager {
        options = _options;
    }

    modifier onlyManager() {
        require(
            msg.sender == options.manager,
            "Only the swap manager can call this function."
        );
        _;
    }

    modifier auth() {
        require(
            msg.sender == options.sender ||
                (options.managerCanSwap && msg.sender == options.manager),
            "Only the swap manager or sender can call this function."
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOpenflowSdk {
    struct Options {
        /// @dev Driver is responsible for authenticating quote selection.
        /// If no driver is set anyone with the signature will be allowed
        /// to execute the signed payload. Driver is user-configurable
        /// which means the end user does not have to trust Openflow driver
        /// multisig. If the user desires, the user can run their own
        /// decentralized multisig driver.
        address driver;
        /// @dev Oracle is responsible for determining minimum amount out for an order.
        /// If no oracle is provided the default Openflow oracle will be used.
        address oracle;
        /// @dev If true calls will revert if oracle is not able to find an appropriate price.
        bool requireOracle;
        /// @dev Acceptable slippage threshold denoted in BIPs.
        uint256 slippageBips;
        /// @dev Maximum duration for auction. The order is invalid after the auction ends.
        uint256 auctionDuration;
        /// @dev Manager is responsible for managing SDK options.
        address manager;
        /// @dev If true manager is allowed to perform swaps on behalf of the
        /// instance initiator (sender).
        bool managerCanSwap;
        /// @dev When a swap is executed, transfer funds from sender to Settlement
        /// via SDK instance. Sender must allow the SDK instance to spend fromToken
        address sender;
        /// @dev Funds will be sent to recipient after swap.
        address recipient;
    }

    function swap(
        address fromToken,
        address toToken
    ) external returns (bytes memory orderUid);

    function options() external view returns (Options memory options);

    function setOptions(Options memory options) external;

    function initialize(
        address settlement,
        address manager,
        address sender,
        address recipient
    ) external;

    function updateSdkVersion() external;

    function updateSdkVersion(uint256 version) external;
}

interface IOpenflowFactory {
    function newSdkInstance() external returns (IOpenflowSdk sdkInstance);

    function newSdkInstance(
        address manager
    ) external returns (IOpenflowSdk sdkInstance);

    function newSdkInstance(
        address manager,
        address sender,
        address recipient
    ) external returns (IOpenflowSdk sdkInstance);

    function implementationByVersion(
        uint256 version
    ) external view returns (address implementation);

    function currentVersion() external view returns (uint256 version);
}