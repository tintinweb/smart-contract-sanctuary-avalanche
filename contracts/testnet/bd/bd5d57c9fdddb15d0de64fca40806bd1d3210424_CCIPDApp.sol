// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {OwnerIsCreator} from "../access/OwnerIsCreator.sol";
// solhint-disable-next-line chainlink-solidity/explicit-imports
import "./CCIPReceiver.sol";

import {IERC20} from "../vendor/IERC20.sol";
import {Client} from "../models/Client.sol";
import {IRouterClient} from "../interfaces/router/IRouterClient.sol";

/// @title PingPongDemo - A simple ping-pong contract for demonstrating cross-chain communication
contract CCIPDApp is CCIPReceiver, OwnerIsCreator {
    event SentMessage(string msg, bytes32 messageId);
    event ReceiveMessage(string msg, bytes32 messageId);

    // The chain ID of the counterpart ping pong contract
    uint64 private s_counterpartChainId;
    // The contract address of the counterpart ping pong contract
    address private s_counterpartAddress;

    address s_router;

    constructor(address router) CCIPReceiver(router) {
        s_router = router;
    }

    function setCounterpart(
        uint64 counterpartChainId,
        address counterpartAddress
    ) external onlyOwner {
        s_counterpartChainId = counterpartChainId;
        s_counterpartAddress = counterpartAddress;
    }

    function fundContractWithUserTokens(Client.EVMTokenAmount[] memory _tokenAndAmount) internal {
        // transfer tokens from user to DApp
        for (uint256 i = 0; i < _tokenAndAmount.length; ++i) {
            IERC20 token = IERC20(_tokenAndAmount[i].token);
            uint256 amount = _tokenAndAmount[i].amount;
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            IERC20(token).approve(address(s_router), amount);
        }
    }

    function SendMessageWithERC(
        string memory _data,
        Client.EVMTokenAmount[] memory _tokenAndAmount,
        address _feeToken
    ) external {
        if (_tokenAndAmount.length == 0) {
            _tokenAndAmount = new Client.EVMTokenAmount[](0);
        }
        fundContractWithUserTokens(_tokenAndAmount);

        bytes memory data = abi.encode(_data);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_counterpartAddress),
            data: data,
            tokenAmounts: _tokenAndAmount,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})),
            feeToken: address(_feeToken)
        });

        // transfer fees from user to DApp
        uint256 fee = IRouterClient(getRouter()).getFee(s_counterpartChainId, message);
        IERC20(_feeToken).transferFrom(msg.sender, address(this), fee);

        bytes32 messageId = IRouterClient(getRouter()).ccipSend(s_counterpartChainId, message);
        emit SentMessage(_data, messageId);
    }

    function SendMessageWithNative(
        string memory _data,
        Client.EVMTokenAmount[] memory _tokenAndAmount
    ) external payable {
        if (_tokenAndAmount.length == 0) {
            _tokenAndAmount = new Client.EVMTokenAmount[](0);
        }
        fundContractWithUserTokens(_tokenAndAmount);

        bytes memory data = abi.encode(_data);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_counterpartAddress),
            data: data,
            tokenAmounts: _tokenAndAmount,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})),
            feeToken: address(0)
        });

        // transfer fees from user to DApp
        uint256 fee = IRouterClient(getRouter()).getFee(s_counterpartChainId, message);
        bytes32 messageId = IRouterClient(getRouter()).ccipSend{value: fee}(s_counterpartChainId, message);

        // refund unused fee back to user
        refund(fee);
        emit SentMessage(_data, messageId);
    }

    function refund(uint256 fee) internal {
        address payable receiver = payable(msg.sender);
        receiver.transfer(msg.value-fee);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        string memory _data = abi.decode(message.data, (string));
        emit ReceiveMessage(_data, message.messageId);
    }

    /**
     * @notice Fund this contract with configured feeToken and approve tokens to the router
     * @dev Requires prior approval from the msg.sender
     * @param amount The amount of feeToken to be funded
     */
    function fund(uint256 amount, address s_feeToken) external {
        IERC20(s_feeToken).transferFrom(msg.sender, address(this), amount);
        IERC20(s_feeToken).approve(address(getRouter()), amount);
    }

    function approveRouter(uint256 amount, address s_feeToken) external {
        IERC20(s_feeToken).approve(address(getRouter()), amount);
    }

    function getCounterpartChainId() external view returns (uint64) {
        return s_counterpartChainId;
    }

    function setCounterpartChainId(uint64 chainId) external onlyOwner {
        s_counterpartChainId = chainId;
    }

    function getCounterpartAddress() external view returns (address) {
        return s_counterpartAddress;
    }

    function setCounterpartAddress(address addr) external onlyOwner {
        s_counterpartAddress = addr;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ConfirmedOwner} from "./ConfirmedOwner.sol";

/**
 * @title The OwnerIsCreator contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract OwnerIsCreator is ConfirmedOwner {
    constructor() ConfirmedOwner(msg.sender) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IAny2EVMMessageReceiver} from "../interfaces/router/IAny2EVMMessageReceiver.sol";
import {IERC165} from "../vendor/IERC165.sol";

import {Client} from "../models/Client.sol";

/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
abstract contract CCIPReceiver is IAny2EVMMessageReceiver, IERC165 {
    address private immutable i_router;

    constructor(address router) {
        if (router == address(0)) revert InvalidRouter(address(0));
        i_router = router;
    }

    /**
     * @notice IERC165 supports an interfaceId
   * @param interfaceId The interfaceId to check
   * @return true if the interfaceId is supported
   */
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /// @inheritdoc IAny2EVMMessageReceiver
    function ccipReceive(Client.Any2EVMMessage calldata message) external override onlyRouter {
        _ccipReceive(message);
    }

    /**
     * @notice Override this function in your implementation.
   * @param message Any2EVMMessage
   */
    function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual;

    /////////////////////////////////////////////////////////////////////
    // Plumbing
    /////////////////////////////////////////////////////////////////////

    /**
     * @notice Return the current router
   * @return i_router address
   */
    function getRouter() public view returns (address) {
        return address(i_router);
    }

    error InvalidRouter(address router);

    /**
     * @dev only calls from the set router are accepted.
   */
    modifier onlyRouter() {
        if (msg.sender != address(i_router)) revert InvalidRouter(msg.sender);
        _;
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// End consumer library.
library Client {
    struct EVMTokenAmount {
        address token;
        uint256 amount;
    }

    struct Any2EVMMessage {
        bytes32 messageId;
        uint64 sourceChainId;
        bytes sender;
        bytes data;
        EVMTokenAmount[] destTokenAmounts;
    }

    struct EVM2AnyMessage {
        bytes receiver;
        bytes data;
        EVMTokenAmount[] tokenAmounts;
        address feeToken;
        bytes extraArgs;
    }

    // bytes4(keccak256("CCIP EVMExtraArgsV1"));
    bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
    struct EVMExtraArgsV1 {
        uint256 gasLimit;
        bool strict;
    }

    function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
        return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../../models/Client.sol";

interface IRouterClient {
    error UnsupportedDestinationChain(uint64 destinationChainId);
    error SenderNotAllowed(address sender);
    error InsufficientFeeTokenAmount();
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
    /// @return fee returns guaranteed execution fee for the specified message
    /// delivery to destination chain
    /// @dev returns 0 fee on invalid message.
    function getFee(uint64 destinationChainId, Client.EVM2AnyMessage memory message) external view returns (uint256 fee);

    /// @notice Request a message to be sent to the destination chain
    /// @param destinationChainId The destination chain ID
    /// @param message The cross-chain CCIP message including data and/or tokens
    /// @return The message ID
    /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
    /// the overpayment with no refund.
    function ccipSend(uint64 destinationChainId, Client.EVM2AnyMessage calldata message)
    external
    payable
    returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
    constructor(address newOwner)
        ConfirmedOwnerWithProposal(newOwner, address(0))
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../../models/Client.sol";

/**
 * @notice Application contracts that intend to receive messages from
 * the router should implement this interface.
 */
interface IAny2EVMMessageReceiver {
    /**
     * @notice Called by the Router to deliver a message
   * @param message CCIP Message
   */
    function ccipReceive(Client.Any2EVMMessage calldata message) external;
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
pragma solidity ^0.8.0;

import "./OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
    address private s_owner;
    address private s_pendingOwner;

    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor(address newOwner, address pendingOwner) {
        require(newOwner != address(0), "Cannot set owner to zero");

        s_owner = newOwner;
        if (pendingOwner != address(0)) {
            _transferOwnership(pendingOwner);
        }
    }

    /**
     * @notice Allows an owner to begin transferring ownership to a new address,
     * pending.
     */
    function transferOwnership(address to) public override onlyOwner {
        _transferOwnership(to);
    }

    /**
     * @notice Allows an ownership transfer to be completed by the recipient.
     */
    function acceptOwnership() external override {
        require(msg.sender == s_pendingOwner, "Must be proposed owner");

        address oldOwner = s_owner;
        s_owner = msg.sender;
        s_pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    /**
     * @notice Get the current owner
     */
    function owner() public view override returns (address) {
        return s_owner;
    }

    /**
     * @notice validate, transfer ownership, and emit relevant events
     */
    function _transferOwnership(address to) private {
        require(to != msg.sender, "Cannot transfer to self");

        s_pendingOwner = to;

        emit OwnershipTransferRequested(s_owner, to);
    }

    /**
     * @notice validate access
     */
    function _validateOwnership() internal view {
        require(msg.sender == s_owner, "Only callable by owner");
    }

    /**
     * @notice Reverts if called by anyone other than the contract owner.
     */
    modifier onlyOwner() {
        _validateOwnership();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
    function owner() external returns (address);

    function transferOwnership(address recipient) external;

    function acceptOwnership() external;
}