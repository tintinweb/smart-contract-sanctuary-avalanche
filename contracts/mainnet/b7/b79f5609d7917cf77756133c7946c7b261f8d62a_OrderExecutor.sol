// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ISettlement} from "../interfaces/ISettlement.sol";
import {IERC20} from "../interfaces/IERC20.sol";

/// @title Order Executor
/// @notice Generic order executor
/// @dev Settlement is agnostic to who executes each order. This contract is
/// just an example of a generic order executor. Though this contract can be used for
/// order submission actual implementation is left to the solver
/// @dev This is a generic sample order executor that supports:
/// - Generic target/calldata execution flow in hook
///   - The expectation is that at the end of the target calldata call
///     this contract will end up with all swapped tokens
///   - At this point the hook must send all agreed upon funds to the order recipient
/// - Custom solver pre-swap and post-swap hooks
///   - Allows the solver to perform custom setup/teardown logic, such as sweeping
///     solver fee after a swap
///
contract OrderExecutor {
    ISettlement public settlement;

    struct Data {
        IERC20 fromToken;
        IERC20 toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address recipient;
        address target;
        bytes payload;
    }

    struct Interaction {
        address target;
        bytes data;
        uint256 value;
    }

    constructor(address _settlement) {
        settlement = ISettlement(_settlement);
    }

    function executeOrder(ISettlement.Order calldata order) public {
        settlement.executeOrder(order);
    }

    // function executeOrder(
    //     ISettlement.Order calldata order,
    //     ISettlement.Interaction[][2] memory interactions
    // ) public {
    //     // Before swap hook
    //     _executeInteractions(interactions[0]);

    //     // Execute swap
    //     settlement.executeOrder(order);

    //     // After swap hook
    //     _executeInteractions(interactions[1]);
    // }

    function hook(bytes memory orderData) external {
        require(msg.sender == address(settlement), "Only settlement");
        Data memory executorData = abi.decode(orderData, (Data));
        executorData.fromToken.approve(executorData.target, type(uint256).max); // Max approve to save gas --this contract should not hold tokens
        (bool success, ) = executorData.target.call(executorData.payload);
        require(success, "Execution hook failed");
        executorData.toToken.transfer(
            executorData.recipient,
            executorData.toAmount
        );
    }

    // Solver hooks
    function _executeInteractions(
        ISettlement.Interaction[] memory interactions
    ) internal {
        for (uint256 i; i < interactions.length; i++) {
            ISettlement.Interaction memory interaction = interactions[i];
            (bool success, ) = interaction.target.call{
                value: interaction.value
            }(interaction.data);
            require(success, "Order executor interaction failed");
        }
    }

    function sweep(IERC20 token, address recipient) external {
        token.transfer(recipient, token.balanceOf(address(this)));
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