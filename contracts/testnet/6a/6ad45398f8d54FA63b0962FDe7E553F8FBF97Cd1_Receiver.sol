// contracts/Client.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Client {
  struct EVMTokenAmount {
    address token; // token address on the local chain
    uint256 amount;
  }  

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source
    uint64 sourceChainId;
    bytes sender; // abi.decode(sender) if coming from an EVM chain
    bytes data; // payload sent in original message
    EVMTokenAmount[] tokenAmounts;
  }

  // If extraArgs is empty bytes, the default is 
  // 200k gas limit and strict = false. 
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload 
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // extraArgs will evolve to support new features
  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit; // ATTENTION!!! MAX GAS LIMIT 4M FOR ALPHA TESTING
    bool strict; // See strict sequencing details below. 
  }
  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Client} from "./Client.sol";

/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {

  /// @notice Router calls this to deliver a message.
  /// If this reverts, any token transfers also revert. The message
  /// will move to a FAILED state and become available for manual execution
  /// as a retry. Fees already paid are NOT currently refunded (may change). 
  /// @param message CCIP Message
  /// @dev Note ensure you check the msg.sender is the router
  function ccipReceive(Client.Any2EVMMessage calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC165 {
  // @dev Should indicate whether the contract implements IAny2EVMMessageReceiver
  // e.g. return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId
  // This allows CCIP to check if ccipReceive is available before calling it. 
  // If this returns false or reverts, only tokens are transferred to the receiver.
  // If this returns true, tokens are transferred and ccipReceive is called atomically.
  // Additionally, if the receiver address does not have code associated with 
  // it at the time of execution (EXTCODESIZE returns 0), only tokens will be transferred. 
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Client library above
import {Client} from "./Client.sol";

interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destinationChainId);
  /// @dev Sender is not whitelisted
  error SenderNotAllowed(address sender);
  error InsufficientFeeTokenAmount();
  /// @dev Sent msg.value with a non-empty feeToken
  error InvalidMsgValue();

  /// @notice Checks if the given chain ID is supported for sending/receiving.
  /// @param chainId The chain to check
  /// @return supported is true if it is supported, false if not
  function isChainSupported(uint64 chainId) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain id.
  /// @param chainId The chainId.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(uint64 chainId) external view returns (address[] memory tokens);

  /// @param destinationChainId The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns execution fee for the specified message
  /// delivery to destination chain
  /// @dev returns 0 fee on invalid message.
  function getFee(uint64 destinationChainId, Client.EVM2AnyMessage memory message)
  external
  view
  returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainId The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  function ccipSend(uint64 destinationChainId, Client.EVM2AnyMessage calldata message)
  external
  payable
  returns (bytes32 messageId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IRouterClient} from "./IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "./IAny2EVMMessageReceiver.sol";

import {Client} from "./Client.sol";

import {IERC165} from "./IERC165.sol";
import {IERC20} from "./IERC20.sol";

contract Receiver is IAny2EVMMessageReceiver, IERC165 {

  function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
    return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }

  function ccipReceive(Client.Any2EVMMessage calldata message) external override {
    // Implement your message receiving logic here
    // ...
  }
}