// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './utils/AddressQueue.sol';
import './utils/SafeMath.sol';

// import 'hardhat/console.sol';

contract Fund is Ownable {
    using AddressQueue for AddressQueue.Ordered;
    using SafeMath for uint256;

    uint256 private constant MINUTE = 60;
    uint256 private constant HOUR = 60 * MINUTE;
    uint256 private constant DAY = 24 * HOUR;
    uint256 public constant StakingPeriod = 7 * DAY;

    bool public Allowed = false;
    uint256 public TicketPrice;
    uint256 public MaxTokenAmount;
    address public FeeWallet;
    uint256 public Fee;

    uint256 public PacPerTicket;
    IERC20 public PacToken;

    struct UserStats {
        uint256 ownedTicketsAmount;
        uint256 onSell;
        uint256 onBuy;
    }

    struct WalletStats {
        address addr;
        uint256 ticketsBought;
        address[] participants;
    }

    mapping(uint16 => mapping(address => UserStats)) userStats;
    mapping(uint16 => AddressQueue.Ordered) OrderOnSell;
    mapping(uint16 => AddressQueue.Ordered) OrderOnBuy;

    WalletStats[] public tokenHolders;

    constructor(
        uint256 _MaxTokenAmount,
        uint256 _TicketPrice,
        address _FeeWallet,
        uint256 _Fee,
        address[] memory _TokenHolders,
        address _PacToken,
        uint256 _PacPerTicket
    ) {
        MaxTokenAmount = _MaxTokenAmount;
        TicketPrice = _TicketPrice;
        FeeWallet = _FeeWallet;
        Fee = _Fee; // divides by 100

        PacToken = IERC20(_PacToken);
        PacPerTicket = _PacPerTicket;

        for (uint16 i; i < _TokenHolders.length; ++i) {
            OrderOnSell[i].initialize();
            OrderOnBuy[i].initialize();
        }

        for (uint16 i; i < _TokenHolders.length; ++i) {
            tokenHolders.push(WalletStats(_TokenHolders[i], 0, new address[](0)));
        }
    }

    modifier correctId(uint16 id) {
        require(id < tokenHolders.length, 'Id is not correct');
        _;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        WalletStats[] storage tokenHolders_ = tokenHolders;
        for (uint16 i; i < tokenHolders_.length; ++i) {
            if (msg.sender == tokenHolders_[i].addr) {
                // distribution...
                uint256 perOneTicket = msg.value / tokenHolders_[i].ticketsBought;

                for (uint256 j; j < tokenHolders_[i].participants.length; ++j) {
                    address userAddr = tokenHolders_[i].participants[j];
                    UserStats memory user = userStats[i][userAddr];

                    // send Ether to users
                    (bool sentUser, ) = payable(userAddr).call{
                        value: (perOneTicket * user.ownedTicketsAmount * (100 - Fee)) /
                            100
                    }('');
                    require(sentUser, 'Failed to send Ether to user');

                    // send PAC to users if got enough
                    if (
                        PacToken.balanceOf(address(this)) >=
                        PacPerTicket * user.ownedTicketsAmount
                    ) {
                        PacToken.transfer(
                            userAddr,
                            PacPerTicket * user.ownedTicketsAmount
                        );
                    }
                }

                (bool sentFee, ) = payable(FeeWallet).call{
                    value: (msg.value * Fee) / 100
                }('');
                require(sentFee, 'Failed to send Ether to fee wallet');

                return;
            }
        }
    }

    function buyTickets(uint16 id) external payable correctId(id) {
        if (msg.value < TicketPrice) revert('Not enough tokens');
        UserStats storage senderStats = userStats[id][msg.sender];

        //case there are Order from other users
        if (OrderOnSell[id].length() > 0) {
            address seller = OrderOnSell[id].dequeue();
            UserStats storage sellerStats = userStats[id][seller];

            ++senderStats.ownedTicketsAmount;
            addParticipant(id, msg.sender);

            --sellerStats.ownedTicketsAmount;
            --sellerStats.onSell;
            removeParticipant(id, seller);

            (bool sent, ) = payable(seller).call{value: TicketPrice}('');
            require(sent, 'Failed to send Ether');
        }
        // case no Order left, but current wallet can sell needed amount of tickets
        else if ((tokenHolders[id].ticketsBought + 1) * TicketPrice <= MaxTokenAmount) {
            (bool sent, ) = payable(tokenHolders[id].addr).call{value: TicketPrice}('');
            require(sent, 'Failed to send Ether');

            ++senderStats.ownedTicketsAmount;
            ++tokenHolders[id].ticketsBought;
            addParticipant(id, msg.sender);
        }
        // case no Order and contract got no ability to sell tickets
        else {
            OrderOnBuy[id].enqueue(msg.sender);
            ++senderStats.onBuy;
        }
    }

    function sellTickets(uint16 id) external correctId(id) {
        UserStats storage senderStats = userStats[id][msg.sender];
        if (senderStats.onSell == senderStats.ownedTicketsAmount) return;
        if (senderStats.ownedTicketsAmount == 0) return;

        // case there are some customers who wants to buy tickets
        if (OrderOnBuy[id].length() > 0) {
            address buyer = OrderOnBuy[id].dequeue();
            UserStats storage buyerStats = userStats[id][buyer];

            --senderStats.ownedTicketsAmount;
            removeParticipant(id, msg.sender);

            ++buyerStats.ownedTicketsAmount;
            --buyerStats.onBuy;
            addParticipant(id, buyer);

            (bool sentCustomer, ) = payable(msg.sender).call{value: TicketPrice}('');
            require(sentCustomer, 'Failed to send Ether');
        } else {
            OrderOnSell[id].enqueue(msg.sender);
            ++senderStats.onSell;
        }
    }

    function cancelBuy(uint16 id, uint256 amount) external correctId(id) {
        UserStats storage senderStats = userStats[id][msg.sender];
        if (senderStats.onBuy < amount || senderStats.onBuy == 0) return;
        if (address(this).balance < amount * TicketPrice) return;

        uint256 currentIndex;
        for (uint256 i; i < amount; ++i) {
            for (uint256 j; j < OrderOnBuy[id].length(); ++j) {
                address user = OrderOnBuy[id].dequeue();
                if (user == msg.sender) {
                    --senderStats.onBuy;
                    break;
                }
                OrderOnBuy[id].enqueue(user);
                ++currentIndex;
            }
        }
        for (currentIndex; currentIndex < OrderOnBuy[id].length(); ++currentIndex) {
            address user = OrderOnBuy[id].dequeue();
            OrderOnBuy[id].enqueue(user);
        }

        (bool sent, ) = payable(msg.sender).call{value: amount * TicketPrice}('');
        require(sent, 'Failed to send Ether');
    }

    function cancelSell(uint16 id, uint256 amount) external correctId(id) {
        UserStats storage senderStats = userStats[id][msg.sender];
        if (senderStats.onSell < amount || senderStats.onSell == 0) return;

        uint256 currentIndex;
        for (uint256 i; i < amount; ++i) {
            for (uint256 j; j < OrderOnSell[id].length(); ++j) {
                address user = OrderOnSell[id].dequeue();
                if (user == msg.sender) {
                    --senderStats.onSell;
                    break;
                }
                OrderOnSell[id].enqueue(user);
                ++currentIndex;
            }
        }
        for (currentIndex; currentIndex < OrderOnSell[id].length(); ++currentIndex) {
            address user = OrderOnSell[id].dequeue();
            OrderOnSell[id].enqueue(user);
        }
    }

    // -_-_-_-_-_-_-_-_ Participants -_-_-_-_-_-_-_-_

    /**
     * @param id - wallet identifier
     * @param user - current user
     * @param result - 0 if user GOT tickets and IN array;
     *                 1 if user GOT NO tickets and IN array;
     *                 2 if user GOT tickets and NOT IN array;
     *                 3 if user GOT NO tickets and NOT IN array;
     */
    function check(uint16 id, address user)
        internal
        view
        returns (uint8 result, uint256 i)
    {
        address[] memory participants = tokenHolders[id].participants;

        bool userFound = false;
        bool userGotTickets = false;
        for (; i < participants.length; ++i) {
            if (participants[i] == user) {
                userFound = true;
                break;
            }
        }

        if (userStats[id][user].ownedTicketsAmount > 0) userGotTickets = true;

        if (userGotTickets && userFound) result = 0;
        if (!userGotTickets && userFound) result = 1;
        if (userGotTickets && !userFound) result = 2;
        if (!userGotTickets && !userFound) result = 3;
    }

    function addParticipant(uint16 id, address user) internal {
        address[] storage participants = tokenHolders[id].participants;
        (uint8 result, ) = check(id, user);

        // add if only user got tickets and no such user in array
        if (result == 2) participants.push(user);
    }

    function removeParticipant(uint16 id, address user) internal {
        address[] storage participants = tokenHolders[id].participants;
        (uint8 result, uint256 i) = check(id, user);

        // add if only user got no tickets and still in array
        if (result == 1) {
            participants[i] = participants[participants.length - 1];
            participants.pop();
        }
    }

    // -_-_-_-_-_-_-_-_ Getters -_-_-_-_-_-_-_-_

    function getUser(address user, uint16 id)
        external
        view
        correctId(id)
        returns (UserStats memory)
    {
        return userStats[id][user];
    }

    function getWallets() external view returns (WalletStats[] memory) {
        return tokenHolders;
    }

    function plannedReward(uint16 id, address user)
        external
        view
        correctId(id)
        returns (uint256)
    {
        return 26 * userStats[id][user].ownedTicketsAmount;
    }

    function getLenOnSell(uint16 id) external view correctId(id) returns (uint256) {
        return OrderOnSell[id].length();
    }

    function getLenOnBuy(uint16 id) external view correctId(id) returns (uint256) {
        return OrderOnBuy[id].length();
    }

    // -_-_-_-_-_-_-_-_ Unstake Logic -_-_-_-_-_-_-_-_

    function unstakeAll(uint16 id) external correctId(id) {
        if (
            address(this).balance <
            userStats[id][msg.sender].ownedTicketsAmount * TicketPrice ||
            userStats[id][msg.sender].ownedTicketsAmount == 0 ||
            !Allowed
        ) return;

        bool sent = payable(msg.sender).send(
            userStats[id][msg.sender].ownedTicketsAmount * TicketPrice
        );
        require(sent, 'Failed to send Ether');
    }

    // -_-_-_-_-_-_-_-_ Owner Logic -_-_-_-_-_-_-_-_

    function setWalletStats(
        uint16 id,
        uint256 _ticketsBought,
        address[] memory _participants
    ) external onlyOwner {
        tokenHolders[id].ticketsBought = _ticketsBought;
        tokenHolders[id].participants = _participants;
    }

    function setUserStats(
        uint16 id,
        address user,
        uint256 _ownedTicketsAmount
    ) external onlyOwner {
        userStats[id][user].ownedTicketsAmount = _ownedTicketsAmount;
    }

    function withdrawOcta() external onlyOwner {
        if (address(this).balance == 0) return;
        (bool sent, ) = payable(owner()).call{value: address(this).balance}('');
        require(sent, 'Failed to send Ether');
    }

    function withdrawPac() external onlyOwner {
        PacToken.transfer(owner(), PacToken.balanceOf(address(this)));
    }

    function toggleUnstake() external onlyOwner {
        Allowed = !Allowed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Queue
 * @author Erick Dagenais (https://github.com/edag94)
 * @dev Implementation of the queue user structure, providing a library with struct definition for queue storage in consuming contracts.
 */
library AddressQueue {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Queue type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.
    // Based off the pattern used in https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol[EnumerableSet.sol] by OpenZeppelin

    struct QueueStorage {
        mapping(uint256 => address) _user;
        uint256 _first;
        uint256 _last;
    }

    modifier isNotEmpty(QueueStorage storage queue) {
        require(!_isEmpty(queue), 'Queue is empty.');
        _;
    }

    /**
     * @dev Sets the queue's initial state, with a queue size of 0.
     * @param queue QueueStorage struct from contract.
     */
    function _initialize(QueueStorage storage queue) private {
        queue._first = 1;
        queue._last = 0;
    }

    /**
     * @dev Gets the number of elements in the queue. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _length(QueueStorage storage queue) private view returns (uint256) {
        if (queue._last < queue._first || (queue._last == 0 && queue._first == 0)) {
            return 0;
        }
        return queue._last - queue._first + 1;
    }

    /**
     * @dev
     * @param queue Ordered struct from contract.
     */
    function _lastIndex(QueueStorage storage queue) private view returns (uint256) {
        return queue._last;
    }

    /**
     * @dev
     * @param queue Ordered struct from contract.
     */
    function _firstIndex(QueueStorage storage queue) private view returns (uint256) {
        return queue._first;
    }

    /**
     * @dev Returns if queue is empty. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _isEmpty(QueueStorage storage queue) private view returns (bool) {
        return _length(queue) == 0;
    }

    /**
     * @dev Adds an element to the back of the queue. O(1)
     * @param queue QueueStorage struct from contract.
     * @param user seller / buyer
     */
    function _enqueue(QueueStorage storage queue, address user) private {
        queue._user[++queue._last] = user;
    }

    /**
     * @dev Removes an element from the front of the queue and returns it. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _dequeue(QueueStorage storage queue)
        private
        isNotEmpty(queue)
        returns (address user)
    {
        user = queue._user[queue._first];
        delete queue._user[queue._first++];
    }

    /**
     * @dev Returns the user from the front of the queue, without removing it. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _peek(QueueStorage storage queue)
        private
        view
        isNotEmpty(queue)
        returns (address user)
    {
        return queue._user[queue._first];
    }

    function _peekLast(QueueStorage storage queue)
        private
        view
        isNotEmpty(queue)
        returns (address user)
    {
        return queue._user[queue._last];
    }

    // Ordered

    struct Ordered {
        QueueStorage _inner;
    }

    /**
     * @dev Sets the queue's initial state, with a queue size of 0.
     * @param queue Ordered struct from contract.
     */
    function initialize(Ordered storage queue) internal {
        _initialize(queue._inner);
    }

    /**
     * @dev Gets the number of elements in the queue. O(1)
     * @param queue Ordered struct from contract.
     */
    function length(Ordered storage queue) internal view returns (uint256) {
        return _length(queue._inner);
    }

    /**
     * @dev
     * @param queue Ordered struct from contract.
     */
    function lastIndex(Ordered storage queue) internal view returns (uint256) {
        return _lastIndex(queue._inner);
    }

    /**
     * @dev
     * @param queue Ordered struct from contract.
     */
    function firstIndex(Ordered storage queue) internal view returns (uint256) {
        return _firstIndex(queue._inner);
    }

    /**
     * @dev Returns if queue is empty. O(1)
     * @param queue Ordered struct from contract.
     */
    function isEmpty(Ordered storage queue) internal view returns (bool) {
        return _isEmpty(queue._inner);
    }

    /**
     * @dev Adds an element to the back of the queue. O(1)
     * @param queue Ordered struct from contract.
     * @param user - signers address.
     */
    function enqueue(Ordered storage queue, address user) internal {
        _enqueue(queue._inner, user);
    }

    /**
     * @dev Removes an element from the front of the queue and returns it. O(1)
     * @param queue Ordered struct from contract.
     */
    function dequeue(Ordered storage queue) internal returns (address user) {
        return _dequeue(queue._inner);
    }

    /**
     * @dev Returns the user from the front of the queue, without removing it. O(1)
     * @param queue Ordered struct from contract.
     */
    function peek(Ordered storage queue) internal view returns (address user) {
        return _peek(queue._inner);
    }

    /**
     * @dev Returns the user from the back of the queue. O(1)
     * @param queue Ordered struct from contract.
     */
    function peekLast(Ordered storage queue) internal view returns (address user) {
        return _peekLast(queue._inner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        return c;
    }
}