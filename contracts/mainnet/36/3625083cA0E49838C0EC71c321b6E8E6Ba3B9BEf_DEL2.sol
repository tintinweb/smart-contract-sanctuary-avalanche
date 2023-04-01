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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DEL2 is Ownable {
    uint public constant ticketPrice = 1 * 10**18;
    uint public constant maxTicketPerBuyer = 1000;
    uint public constant maxTicketCount = 100000000000000;
    uint public constant potPercentage = 85;
    uint public constant housePercentage = 15;
    uint public constant duration = 12 hours;

    uint public pot;
    uint public ticketCount;
    uint public startTime;
    uint public endTime;
    address[] public players;
    mapping(address => uint) public ticketCounts;

    IERC20 public avax;

    event TicketBought(address indexed player, uint ticketCount);
    event endGame(address indexed winner, uint pot);

    constructor(IERC20 _avax) {
        avax = _avax;
    }

    function buyTickets(uint256 _ticketCount) public {

        require(_ticketCount > 0, "Ticket count must be greater than 0");
        require(_ticketCount <= maxTicketPerBuyer, "Ticket count exceeds maximum per buyer");
        require(ticketCount + _ticketCount <= maxTicketCount, "Ticket count exceeds maximum");

        uint totalPrice = ticketPrice * _ticketCount;
        require(avax.allowance(msg.sender, address(this)) >= totalPrice, "Not enough allowance");
        require(avax.balanceOf(msg.sender) >= totalPrice, "Not enough balance");

        avax.transferFrom(msg.sender, address(this), totalPrice);

        if (ticketCounts[msg.sender] == 0) {
            players.push(msg.sender);
        }
        ticketCounts[msg.sender] += _ticketCount;
        ticketCount += _ticketCount;
        pot += totalPrice;

        emit TicketBought(msg.sender, _ticketCount);

        if (startTime == 0) {
            startTime = block.timestamp;
            endTime = startTime + duration;
        }
    }

    function withdraw() public {
        require(hasEnded(), "Game has not ended");
        require(ticketCounts[msg.sender] > 0, "Player did not participate in game");
        require(isWinner(msg.sender), "Player did not win");

        uint payout = pot * potPercentage / 100;
        pot = 0;
        ticketCount = 0;
        startTime = 0;
        endTime = 0;

        uint balance = avax.balanceOf(address(this));
        uint houseCut = balance * housePercentage / 100;
        uint playerPayout = payout + (balance - houseCut);
        avax.transfer(msg.sender, playerPayout);

        emit endGame(msg.sender, payout);
    }

    function hasEnded() public view returns(bool) {
        return startTime > 0 && block.timestamp >= endTime;
    }

    function isWinner(address _player) public view returns (bool) {
        if (!hasEnded()) {
            return false;
        }
        uint winningTicket = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length))) % ticketCount + 1;
        address winner = players[0];
        uint currentTicket = ticketCounts[winner];
        for (uint i = 1; i < players.length; i++) {
            address player = players[i];
            uint playerTicketCount = ticketCounts[player];
            if (currentTicket < winningTicket && currentTicket + playerTicketCount >= winningTicket) {
                winner = player;
            }
            currentTicket += playerTicketCount;
        }
        return winner == _player;
    }
}