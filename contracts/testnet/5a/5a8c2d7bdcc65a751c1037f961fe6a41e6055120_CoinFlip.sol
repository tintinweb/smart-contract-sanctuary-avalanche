/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-01
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/CoinFlip.sol


pragma solidity ^0.8.7;



/**
 * @title CoinFlip
 * @author Sambit Sargam
 * @notice Coin flip game contract. The user can bet 0 or 1 for heads and tails
 * if the users guesses correctly, they receive double their wager amount
 */
 
contract CoinFlip is Ownable {
    /* events */
    event Withdraw(address owner, uint256 amount);
    event Winner(address player, uint256 amount);
    event Loser(address player, uint256 amount);

    /*
     *  User calls flip with either 1 or 0 as their bet and sends
     *  the funds to wadger, if they win they recive double the bet amount
     */
    function flip(uint256 bet) public payable {
        // The sender must wager more than 0 AVAX
        require(msg.value > 0, "You must wager more than 0 AVAX");
        // The wager amount cannot be more than the balance of the contract
        require(
            msg.value <= address(this).balance - msg.value,
            "Game balance is too low, try betting less AVAX"
        );
        // The sender must bet 0 or 1 (heads or tails)
        require(bet == 0 || bet == 1, "You must guess 0 or 1");

        // If the user chooses correctly they won, otherwise they lost
        if (bet == random()) {
            // Transfer the winner double the amount of their wager
            (bool sent, ) = msg.sender.call{value: msg.value * 2}("");
            require(sent, "Failed to send AVAX");
            // Emit the event that they won
            emit Winner(msg.sender, msg.value);
        } else {
            // Emit the event that they lost, the wager will stay in the contract balance
            emit Loser(msg.sender, msg.value);
        }
    }

    /* Generate a "random" number of 0 or 1 (this is not truly random nor secure)*/
    function random() internal view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % 2;
    }

    /* Withdraw AVAX from this contract, only the owner of the contract can call this */
    function withdrawLYXt() external onlyOwner {
        uint256 balance = getBalance();
        // Send the owner who called the function the amount
        (bool sent, ) = owner().call{value: balance}("");
        require(sent, "Failed to send AVAX");
        // Emit the withdraw event
        emit Withdraw(owner(), balance);
    }

    /* Return the balance stored in the contract */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to receive LYXt. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}