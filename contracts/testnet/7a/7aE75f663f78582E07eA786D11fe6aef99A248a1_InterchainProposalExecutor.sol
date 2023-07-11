// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { IAxelarExecutable } from '../interfaces/IAxelarExecutable.sol';

contract AxelarExecutable is IAxelarExecutable {
    IAxelarGateway public immutable gateway;

    constructor(address gateway_) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();

        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from './IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library StringToAddress {
    error InvalidAddressString();

    function toAddress(string memory addressString) internal pure returns (address) {
        bytes memory stringBytes = bytes(addressString);
        uint160 addressNumber = 0;
        uint8 stringByte;

        if (stringBytes.length != 42 || stringBytes[0] != '0' || stringBytes[1] != 'x') revert InvalidAddressString();

        for (uint256 i = 2; i < 42; ++i) {
            stringByte = uint8(stringBytes[i]);

            if ((stringByte >= 97) && (stringByte <= 102)) stringByte -= 87;
            else if ((stringByte >= 65) && (stringByte <= 70)) stringByte -= 55;
            else if ((stringByte >= 48) && (stringByte <= 57)) stringByte -= 48;
            else revert InvalidAddressString();

            addressNumber |= uint160(uint256(stringByte) << ((41 - i) << 2));
        }
        return address(addressNumber);
    }
}

library AddressToString {
    function toString(address addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(addr);
        uint256 length = addressBytes.length;
        bytes memory characters = '0123456789abcdef';
        bytes memory stringBytes = new bytes(2 + addressBytes.length * 2);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint256 i; i < length; ++i) {
            stringBytes[2 + i * 2] = characters[uint8(addressBytes[i] >> 4)];
            stringBytes[3 + i * 2] = characters[uint8(addressBytes[i] & 0x0f)];
        }
        return string(stringBytes);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.0;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { StringToAddress } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { IInterchainProposalExecutor } from './interfaces/IInterchainProposalExecutor.sol';
import { InterchainCalls } from './lib/InterchainCalls.sol';

/**
 * @title InterchainProposalExecutor
 * @dev This contract is intended to be the destination contract for `InterchainProposalSender` contract.
 * The proposal will be finally executed from this contract on the destination chain.
 *
 * The contract maintains whitelists for proposal senders and proposal callers. Proposal senders
 * are InterchainProposalSender contracts at the source chain and proposal callers are contracts
 * that call the InterchainProposalSender at the source chain.
 * For most governance system, the proposal caller should be the Timelock contract.
 *
 * This contract is abstract and some of its functions need to be implemented in a derived contract.
 */
contract InterchainProposalExecutor is IInterchainProposalExecutor, AxelarExecutable, Ownable {
    // Whitelisted proposal callers. The proposal caller is the contract that calls the `InterchainProposalSender` at the source chain.
    mapping(string => mapping(address => bool)) public whitelistedCallers;

    // Whitelisted proposal senders. The proposal sender is the `InterchainProposalSender` contract address at the source chain.
    mapping(string => mapping(address => bool)) public whitelistedSenders;

    constructor(address _gateway, address _owner) AxelarExecutable(_gateway) {
        _transferOwnership(_owner);
    }

    /**
     * @dev Executes the proposal. The source address must be a whitelisted sender.
     * @param sourceAddress The source address
     * @param payload The payload. It is ABI encoded of the caller and calls.
     * Where:
     * - `caller` is the address that calls the `InterchainProposalSender` at the source chain.
     * - `calls` is the array of `InterchainCalls.Call` to execute. Each call contains the target, value, signature and data.
     */
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        _beforeProposalExecuted(sourceChain, sourceAddress, payload);

        // Check that the source address is whitelisted
        if (!whitelistedSenders[sourceChain][StringToAddress.toAddress(sourceAddress)]) {
            revert NotWhitelistedSourceAddress();
        }

        // Decode the payload
        (address interchainProposalCaller, InterchainCalls.Call[] memory calls) = abi.decode(
            payload,
            (address, InterchainCalls.Call[])
        );

        // Check that the caller is whitelisted
        if (!whitelistedCallers[sourceChain][interchainProposalCaller]) {
            revert NotWhitelistedCaller();
        }

        // Execute the proposal with the given arguments
        _executeProposal(calls);

        _onProposalExecuted(sourceChain, sourceAddress, interchainProposalCaller, payload);

        emit ProposalExecuted(keccak256(abi.encode(sourceChain, sourceAddress, interchainProposalCaller, payload)));
    }

    /**
     * @dev Executes the proposal. Calls each target with the respective value, signature, and data.
     * @param calls The calls to execute.
     */
    function _executeProposal(InterchainCalls.Call[] memory calls) internal {
        for (uint256 i = 0; i < calls.length; i++) {
            InterchainCalls.Call memory call = calls[i];
            (bool success, bytes memory result) = call.target.call{ value: call.value }(call.callData);

            if (!success) {
                _onTargetExecutionFailed(call, result);
            } else {
                _onTargetExecuted(call, result);
            }
        }
    }

    /**
     * @dev Set the proposal caller whitelist status
     * @param sourceChain The source chain
     * @param sourceCaller The source caller
     * @param whitelisted The whitelist status
     */
    function setWhitelistedProposalCaller(
        string calldata sourceChain,
        address sourceCaller,
        bool whitelisted
    ) external override onlyOwner {
        whitelistedCallers[sourceChain][sourceCaller] = whitelisted;
        emit WhitelistedProposalCallerSet(sourceChain, sourceCaller, whitelisted);
    }

    /**
     * @dev Set the proposal sender whitelist status
     * @param sourceChain The source chain
     * @param sourceSender The source sender
     * @param whitelisted The whitelist status
     */
    function setWhitelistedProposalSender(
        string calldata sourceChain,
        address sourceSender,
        bool whitelisted
    ) external override onlyOwner {
        whitelistedSenders[sourceChain][sourceSender] = whitelisted;
        emit WhitelistedProposalSenderSet(sourceChain, sourceSender, whitelisted);
    }

    /**
     * @dev A callback function that is called before the proposal is executed.
     * This function can be used to handle the payload before the proposal is executed.
     * @param sourceChain The source chain from where the proposal was sent.
     * @param sourceAddress The source address that sent the proposal. The source address should be the `InterchainProposalSender` contract address at the source chain.
     * @param payload The payload. It is ABI encoded of the caller and calls.
     * Where:
     * - `caller` is the address that calls the `InterchainProposalSender` at the source chain.
     * - `calls` is the array of `InterchainCalls.Call` to execute. Each call contains the target, value, calldata.
     */
    function _beforeProposalExecuted(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {
        // You can add your own logic here to handle the payload before the proposal is executed.
    }

    /**
     * @dev A callback function that is called after the proposal is executed.
     * This function emits an event containing the hash of the payload to signify successful execution.
     * @param payload The payload. It is ABI encoded of the caller and calls.
     * Where:
     * - `caller` is the address that calls the `InterchainProposalSender` at the source chain.
     * - `calls` is the array of `InterchainCalls.Call` to execute. Each call contains the target, value, signature and data.
     */
    function _onProposalExecuted(
        string calldata /* sourceChain */,
        string calldata /* sourceAddress */,
        address /* caller */,
        bytes calldata payload
    ) internal virtual {
        // You can add your own logic here to handle the payload after the proposal is executed.
    }

    /**
     * @dev A callback function that is called when the execution of a target contract within a proposal fails.
     * This function will revert the transaction providing the failure reason if present in the failure data.
     * @param result The return data from the failed call to the target contract.
     */
    function _onTargetExecutionFailed(InterchainCalls.Call memory /* call */, bytes memory result) internal virtual {
        // You can add your own logic here to handle the failure of the target contract execution. The code below is just an example.
        if (result.length > 0) {
            // The failure data is a revert reason string.
            assembly {
                revert(add(32, result), mload(result))
            }
        } else {
            // There is no failure data, just revert with no reason.
            revert ProposalExecuteFailed();
        }
    }

    /**
     * @dev Called after a target is successfully executed. The derived contract should implement this function.
     * This function should do some post-execution work, such as emitting events.
     * @param call The call that has been executed.
     * @param result The result of the call.
     */
    function _onTargetExecuted(InterchainCalls.Call memory call, bytes memory result) internal virtual {
        // You can add your own logic here to handle the success of each target contract execution.
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInterchainProposalExecutor {
    // An event emitted when the proposal caller is whitelisted
    event WhitelistedProposalCallerSet(string indexed sourceChain, address indexed sourceCaller, bool whitelisted);

    // An event emitted when the proposal sender is whitelisted
    event WhitelistedProposalSenderSet(string indexed sourceChain, address indexed sourceSender, bool whitelisted);

    event ProposalExecuted(bytes32 indexed payloadHash);

    // An error emitted when the proposal execution failed
    error ProposalExecuteFailed();

    // An error emitted when the proposal caller is not whitelisted
    error NotWhitelistedCaller();

    // An error emitted when the proposal sender is not whitelisted
    error NotWhitelistedSourceAddress();

    /**
     * @notice set the whitelisted status of a proposal sender which is the `InterchainProposalSender` contract address on the source chain
     * @param sourceChain The source chain
     * @param sourceSender The source interchain sender address
     * @param whitelisted The whitelisted status
     */
    function setWhitelistedProposalSender(string calldata sourceChain, address sourceSender, bool whitelisted) external;

    /**
     * @notice set the whitelisted status of a proposal caller which normally set to the `Timelock` contract address on the source chain
     * @param sourceChain The source chain
     * @param sourceCaller The source interchain caller address
     * @param whitelisted The whitelisted status
     */
    function setWhitelistedProposalCaller(string calldata sourceChain, address sourceCaller, bool whitelisted) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library InterchainCalls {
    /**
     * @dev An interchain call to be executed at the destination chain
     * @param destinationChain destination chain
     * @param destinationContract destination contract
     * @param gas The amount of native token to transfer to the target contract as gas payment for the interchain call
     * @param calls An array of calls to be executed at the destination chain
     */
    struct InterchainCall {
        string destinationChain;
        string destinationContract;
        uint256 gas;
        Call[] calls;
    }

    /**
     * @dev A call to be executed at the destination chain
     * @param target The address of the contract to call
     * @param value The amount of native token to transfer to the target contract
     * @param callData The data to pass to the target contract
     */
    struct Call {
        address target;
        uint256 value;
        bytes callData;
    }
}