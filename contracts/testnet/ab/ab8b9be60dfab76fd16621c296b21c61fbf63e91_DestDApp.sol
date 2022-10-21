// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {OwnerIsCreator} from "./Access/OwnerIsCreator.sol";
import {IERC20} from "./Interfaces/IERC20.sol";
import {CCIPRouterInterface} from "./Interfaces/CCIPRouterInterface.sol";
import {CCIPReceiverInterface} from "./Interfaces/CCIPReceiverInterface.sol";
import {LinkTokenInterface} from "./Interfaces/LinkTokenInterface.sol";

contract DestDApp is CCIPReceiverInterface, OwnerIsCreator {
    event SentMessage(string msg);
    event ReceiveMessage(string msg);

    CCIPReceiverInterface internal s_receivingRouter;
    CCIPRouterInterface internal s_sendingRouter;
    LinkTokenInterface public s_link;
    address public s_subscriptionManager;

    // The chain ID of the counterpart ping pong contract
    uint256 public s_counterpartChainId;
    // The contract address of the counterpart ping pong contract
    address public s_counterpartAddress;

    // Pause ping-ponging
    bool public s_isPaused;

    constructor(
        CCIPReceiverInterface receivingRouter,
        CCIPRouterInterface sendingRouter,
        address link
    ) {
        s_receivingRouter = receivingRouter;
        s_sendingRouter = sendingRouter;
        s_link = LinkTokenInterface(link);
        s_isPaused = false;
    }

    function setCounterpart(
        uint256 counterpartChainId,
        address counterpartAddress
    ) external onlyOwner {
        s_counterpartChainId = counterpartChainId;
        s_counterpartAddress = counterpartAddress;
    }

    function SendMessage(string memory _data) public {
        bytes memory data = abi.encode(_data);
        CCIPRouterInterface.Message memory message = CCIPRouterInterface
            .Message({
                receiver: abi.encode(s_counterpartAddress),
                data: data,
                tokens: new IERC20[](0),
                amounts: new uint256[](0),
                gasLimit: 200_000
            });
        s_sendingRouter.ccipSend(s_counterpartChainId, message);
        emit SentMessage(_data);
    }

    function ccipReceive(ReceivedMessage memory message)
        external
        override
        onlyRouter
    {
        string memory _data = abi.decode(message.data, (string));
        emit ReceiveMessage(_data);
    }

    /////////////////////////////////////////////////////////////////////
    // Plumbing
    /////////////////////////////////////////////////////////////////////

    function setRouters(
        CCIPReceiverInterface receivingRouter,
        CCIPRouterInterface sendingRouter
    ) external onlyOwner {
        s_receivingRouter = receivingRouter;
        s_sendingRouter = sendingRouter;
    }

    function getRouters()
        external
        view
        returns (CCIPReceiverInterface, CCIPRouterInterface)
    {
        return (s_receivingRouter, s_sendingRouter);
    }

    function setubscriptionManager(address subscriptionManager)
        external
        onlyOwner
    {
        s_subscriptionManager = subscriptionManager;
    }

    function getSubscriptionManager() external view returns (address) {
        //return owner();
        //return address(0x208743cfdcEaA6D03bDC9E0d075B98B8CcFAED37);
        //return address(this);
        return s_subscriptionManager;
    }

    function setPaused(bool isPaused) external onlyOwner {
        s_isPaused = isPaused;
    }

    error InvalidRouter(address router);

    /**
     * @dev only calls from the set router are accepted.
     */
    modifier onlyRouter() {
        if (msg.sender != address(s_receivingRouter))
            revert InvalidRouter(msg.sender);
        _;
    }

    receive() external payable {
        // React to receiving ether
    }
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
pragma solidity ^0.8.15;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
pragma solidity ^0.8.15;

import {IERC20} from "./IERC20.sol";

interface CCIPRouterInterface {
    struct Message {
        bytes receiver;
        bytes data;
        IERC20[] tokens;
        uint256[] amounts;
        uint256 gasLimit;
    }

    function ccipSend(uint256 destinationChainId, Message memory message)
        external
        returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC20} from "./IERC20.sol";

interface CCIPReceiverInterface {
    struct ReceivedMessage {
        uint256 sourceChainId;
        bytes sender;
        bytes data;
        IERC20[] tokens;
        uint256[] amounts;
    }

    function ccipReceive(ReceivedMessage memory message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
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