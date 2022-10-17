// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {OwnerIsCreator} from "./Access/OwnerIsCreator.sol";
import {IERC20} from "./Interfaces/IERC20.sol";
import {SubscriptionInterface, SubscriptionManagerInterface} from "./Interfaces/SubscriptionInterface.sol";
import {CCIPRouterInterface} from "./Interfaces/CCIPRouterInterface.sol";
import {CCIPReceiverInterface} from "./Interfaces/CCIPReceiverInterface.sol";

contract PingPongDemo is CCIPReceiverInterface, OwnerIsCreator {
    event Ping(uint256 pingPongCount);
    event Pong(uint256 pingPongCount);

    CCIPReceiverInterface internal s_receivingRouter;
    CCIPRouterInterface internal s_sendingRouter;

    // The chain ID of the counterpart ping pong contract
    uint256 public s_counterpartChainId;
    // The contract address of the counterpart ping pong contract
    address public s_counterpartAddress;

    // Pause ping-ponging
    bool public s_isPaused;

    constructor(
        CCIPReceiverInterface receivingRouter,
        CCIPRouterInterface sendingRouter
    ) {
        s_receivingRouter = receivingRouter;
        s_sendingRouter = sendingRouter;
        s_isPaused = false;
    }

    function setCounterpart(
        uint256 counterpartChainId,
        address counterpartAddress
    ) external onlyOwner {
        s_counterpartChainId = counterpartChainId;
        s_counterpartAddress = counterpartAddress;
    }

    function startPingPong() external onlyOwner {
        s_isPaused = false;
        _respond(1);
    }

    function _respond(uint256 pingPongCount) private {
        if (pingPongCount & 1 == 1) {
            emit Ping(pingPongCount);
        } else {
            emit Pong(pingPongCount);
        }

        bytes memory data = abi.encode(pingPongCount);
        CCIPRouterInterface.Message memory message = CCIPRouterInterface
            .Message({
                receiver: abi.encode(s_counterpartAddress),
                data: data,
                tokens: new IERC20[](0),
                amounts: new uint256[](0),
                gasLimit: 200_000
            });
        s_sendingRouter.ccipSend(s_counterpartChainId, message);
    }

    function ccipReceive(ReceivedMessage memory message)
        external
        override
        onlyRouter
    {
        uint256 pingPongCount = abi.decode(message.data, (uint256));
        if (!s_isPaused) {
            _respond(pingPongCount + 1);
        }
    }

    function createSubscription() public {
        address[] memory senders = new address[](1);
        senders[0] = owner();
        //s_destFeeToken.approve(address(router), funding);
        uint256 SUBSCRIPTION_BALANCE = 1e18;

        SubscriptionInterface(address(s_receivingRouter)).createSubscription(
            SubscriptionInterface.OffRampSubscription({
                senders: senders,
                receiver: SubscriptionManagerInterface(
                    address(s_receivingRouter)
                ),
                strictSequencing: false,
                balance: SUBSCRIPTION_BALANCE
            })
        );
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

    function getSubscriptionManager() external view returns (address) {
        return owner();
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

import {SubscriptionManagerInterface} from "./SubscriptionManagerInterface.sol";

interface SubscriptionInterface {
    error SubscriptionAlreadyExists();
    error DelayNotPassedYet(uint256 allowedBy);
    error AddressMismatch(address expected, address got);
    error AmountMismatch(uint256 expected, uint256 got);
    error BalanceTooLow();
    error SubscriptionNotFound(address receiver);
    error InvalidManager();
    error FundingAmountNotPositive();

    struct OffRampSubscription {
        address[] senders;
        SubscriptionManagerInterface receiver;
        bool strictSequencing;
        uint256 balance;
    }

    /**
     * @notice Gets the subscription corresponding to the given receiver
     * @param receiver The receiver for which to get the subscription
     * @return The subscription belonging to the receiver
     */
    function getSubscription(address receiver)
        external
        view
        returns (OffRampSubscription memory);

    /**
     * @notice Creates a new subscription if one doesn't already exist for the
     *          given receiver
     * @param subscription The OffRampSubscription to be created
     */
    function createSubscription(OffRampSubscription memory subscription)
        external;

    /**
     * @notice Increases the balance of an existing subscription. The tokens
     *          need to be approved before making this call.
     * @param receiver Indicated which subscription to fund
     * @param amount The amount to fund the subscription
     */
    function fundSubscription(address receiver, uint256 amount) external;

    /**
     * @notice Indicates the desire to change the senders property on an
     *          existing subscription. This process can be completed after
     *          a set delay by calling `setSubscriptionSenders`. Calling
     *          this function again overwrites any existing prepared senders.
     * @param receiver Indicated which subscription to modify
     * @param newSenders The new sender addresses
     */
    function prepareSetSubscriptionSenders(
        address receiver,
        address[] memory newSenders
    ) external;

    /**
     * @notice Finalizes a call to prepareSetSubscriptionSenders and actually
     *          modify the subscription.
     * @param receiver Indicated which subscription to modify
     * @param newSenders The new sender addresses, these are checked against the
     *          addresses previously given in the prepare step.
     */
    function setSubscriptionSenders(
        address receiver,
        address[] memory newSenders
    ) external;

    /**
     * @notice Indicates the desire to withdrawal funds from a subscription
     *        This process can be completed after a set delay by calling
     *        `withdrawal`. Calling this function again overwrites any existing
     *        prepared withdrawal.
     * @param receiver Indicated which subscription to withdrawal from
     * @param amount The amount to withdrawal
     */
    function prepareWithdrawal(address receiver, uint256 amount) external;

    /**
     * @notice Completes the withdrawal previously initiated by calling
     *          `prepareWithdrawal`. This will send the token to the
     *          sender of this transaction.
     * @param receiver Indicated which subscription to withdrawal from
     * @param amount The amount to withdrawal
     */
    function withdrawal(address receiver, uint256 amount) external;
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

interface SubscriptionManagerInterface {
    /**
     * @notice Gets the subscription manager who is allowed to create/update
     * the subscription for this receiver contract.
     * @return the current subscription manager.
     */
    function getSubscriptionManager() external view returns (address);
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