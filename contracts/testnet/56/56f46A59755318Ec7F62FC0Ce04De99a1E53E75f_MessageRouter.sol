/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-28
*/

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

library MessageLib {
    struct Message {
        uint8 action;
        bytes messageBody;
    }

    struct Target {
        uint256 value;
        address target;
        bytes data;
    }

    struct Payload {
        bytes body;
        uint8 action;
    }

    struct RemoteAssetBalance {
        uint128 newBalance;
        uint128 delta;
        address asset;
    }

    struct RemoteOrderBookEmptyMessage {
        RemoteAssetBalance[] balances;
    }

    uint8 internal constant ACTION_REMOTE_VAULT_MINT = 0;
    uint8 internal constant ACTION_REMOTE_VAULT_BURN = 1;
    uint8 internal constant ACTION_REMOTE_VAULT_ESCROW = 2;
    uint8 internal constant ACTION_RESERVE_TRANSFER = 3;
}

interface BridgingExecutor {
    function getTargetExecutionData(MessageLib.Payload calldata payload)
        external
        view
        returns (MessageLib.Target[] memory targets);
}

abstract contract GasAllocationViewer {
    /// @dev Gas allocation per message
    /// Gas allocation per messages consists of three parts:
    /// 1. Fixed gas portion (i.e. For burning this would be updating accounting and sending the callback)
    /// 2. Gas per byte of message - This is for cases where we have a dynamic payload so we need to approximate the gas cost.
    /// 3. Gas per message - This is the additional gas for instance to cache a failed message on the remote chain.
    struct GasAllocation {
        uint64 fixedGas;
        uint64 gasPerByte;
        uint64 gasPerMessage;
    }

    bytes32 internal constant ZERO_GAS_ALLOCATION_HASH =
        0x46700b4d40ac5c35af2c22dda2787a91eb567b06c924a8fb8ae9a05b20c08c21;

    mapping(uint256 => mapping(uint8 => GasAllocation)) internal minGasAllocation;

    function setGasAllocation(uint256 chainId, uint8 action, GasAllocation memory gas) external virtual;

    function getGasAllocation(uint8 action, uint256 chainId) external view virtual returns (GasAllocation memory);
    function defaultGasAllocation(uint8 action) external pure virtual returns (GasAllocation memory);
}

interface ActionHandler {
    function handleAction(MessageLib.Message calldata message, bytes calldata data) external payable;
}

interface MessageRouterErrors {
    error MessageRouterBridgingImplementationNotFound(uint8 action);
    error MessageRouterActionHandlerNotFound(uint8 action);
}

contract MessageRouter is MessageRouterErrors, Owned {
    struct MessageRouterInfo {
        uint8 action;
        address actor;
    }

    /// @dev reserveAsset for the chain
    address public reserveAsset;

    /// @dev action => MessageHandler
    mapping(uint8 => address) public actionHandlers;

    /// @dev action => BridgingImplementation
    mapping(uint8 => address) internal bridgingImplementations;

    constructor(address _owner, address _reserveAsset) Owned(_owner) {
        reserveAsset = _reserveAsset;
    }

    function setReserveAsset(address _reserveAsset) external onlyOwner {
        reserveAsset = _reserveAsset;
    }

    function setBridgingImplementations(MessageRouterInfo[] calldata infos) external onlyOwner {
        for (uint256 i; i < infos.length; i++) {
            MessageRouterInfo calldata info = infos[i];
            bridgingImplementations[info.action] = info.actor;
        }
    }

    function setActionHandlers(MessageRouterInfo[] calldata infos) external onlyOwner {
        for (uint256 i; i < infos.length; i++) {
            MessageRouterInfo calldata info = infos[i];
            actionHandlers[info.action] = info.actor;
        }
    }

    /// @dev routeMessage routes the message to the correct handler,
    /// for now it have no access control for testing purposes, but in the future it will be restricted to only the bridge contract
    function routeMessage(MessageLib.Message calldata message, bytes calldata data) external payable {
        address handler = actionHandlers[message.action];
        if (handler == address(0)) {
            revert MessageRouterActionHandlerNotFound(message.action);
        }

        ActionHandler(handler).handleAction{value: address(this).balance}(message, data);
    }

    function generateTargets(MessageLib.Payload calldata payload)
        external
        view
        returns (MessageLib.Target[] memory targets)
    {
        address bridgingImplementation = getBridgingImplementation(payload.action);
        targets = BridgingExecutor(bridgingImplementation).getTargetExecutionData(payload);
    }

    function estimateFee(MessageLib.Payload calldata payload) external view returns (uint256 gasFee) {
        address bridgingImplementation = getBridgingImplementation(payload.action);
        MessageLib.Target[] memory targets = BridgingExecutor(bridgingImplementation).getTargetExecutionData(payload);
        uint256 length = targets.length;
        for (uint256 i; i < length;) {
            gasFee += targets[i].value;
            unchecked {
                i = i + 1;
            }
        }
    }

    function getBridgingImplementation(uint8 action) internal view returns (address) {
        address bridgingImplementation = bridgingImplementations[action];
        if (bridgingImplementation == address(0)) {
            revert MessageRouterBridgingImplementationNotFound(action);
        }

        return bridgingImplementation;
    }
}