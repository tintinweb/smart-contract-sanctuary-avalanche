// SPDX-License-Identifier: UNLICENSED
// Last deployed from commit: c5c938a0524b45376dd482cd5c8fb83fa94c2fcc;
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * LinearIndex
 * The contract contains logic for time-based index recalculation with minimal memory footprint.
 * It could be used as a base building block for any index-based entities like deposits and loans.
 * The index is updated on a linear basis to the compounding happens when a user decide to accumulate the interests
 * @dev updatedRate the value of updated rate
 **/
contract LinearIndex is Ownable {

    uint256 private constant SECONDS_IN_YEAR = 365 days;
    uint256 private constant BASE_RATE = 1e18;

    uint256 public start = block.timestamp;

    uint256 public index = BASE_RATE;
    uint256 public indexUpdateTime = start;

    mapping(uint256 => uint256) prevIndex;
    mapping(address => uint256) userUpdateTime;

    uint256 public rate;

    constructor(address owner_) {
        if (address(owner_) != address(0)) {
            transferOwnership(owner_);
        }
    }

    /* ========== SETTERS ========== */

    /**
     * Sets the new rate
     * Before the new rate is set, the index is updated accumulating interest
     * @dev updatedRate the value of updated rate
   **/
    function setRate(uint256 _rate) public onlyOwner {
        updateIndex();
        rate = _rate;
        emit RateUpdated(rate);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * Updates user index
     * It persists the update time and the update index time->index mapping
     * @dev user address of the index owner
   **/
    function updateUser(address user) public onlyOwner {
        userUpdateTime[user] = block.timestamp;
        prevIndex[block.timestamp] = getIndex();
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * Gets current value of the linear index
     * It recalculates the value on-demand without updating the storage
     **/
    function getIndex() public view returns (uint256) {
        uint256 period = block.timestamp - indexUpdateTime;
        if (period > 0) {
            return index * getLinearFactor(period) / 1e27;
        } else {
            return index;
        }
    }

    /**
     * Gets the user value recalculated to the current index
     * It recalculates the value on-demand without updating the storage
     * Ray operations round up the result, but it is only an issue for very small values (with an order of magnitude
     * of 1 Wei)
     **/
    function getIndexedValue(uint256 value, address user) public view returns (uint256) {
        uint256 userTime = userUpdateTime[user];
        uint256 prevUserIndex = userTime == 0 ? BASE_RATE : prevIndex[userTime];

        return value * getIndex() / prevUserIndex;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function updateIndex() internal {
        prevIndex[indexUpdateTime] = index;

        index = getIndex();
        indexUpdateTime = block.timestamp;
    }

    /**
     * Returns a linear factor in Ray
     **/
    function getLinearFactor(uint256 period) virtual internal view returns (uint256) {
        return rate * period * 1e9 / SECONDS_IN_YEAR + 1e27;
    }

    /* ========== EVENTS ========== */

    /**
     * @dev updatedRate the value of updated rate
   **/
    event RateUpdated(uint256 updatedRate);
}

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