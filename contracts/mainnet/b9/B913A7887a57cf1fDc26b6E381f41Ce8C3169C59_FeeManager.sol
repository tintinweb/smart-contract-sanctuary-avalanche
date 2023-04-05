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
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";

contract FeeManager is IFeeManager, Ownable {
    uint32 public constant percentageMultiplier = 100;
    uint32 public platformFee;

    mapping(address => AdaptiveFee) public collectionToAdaptiveFee;

    event AdaptiveFeeUpdated(address collection, uint32 rate, uint8 feeType);

    struct AdaptiveFee {
        address secondaryAddress;
        uint32 rate;
        uint8 feeType; // 1 is discount, 2 is fee sharing
    }

    constructor() {
        platformFee = 500; // 5%
    }

    // --------- OWNER FUNCTIONS ---------
    // 0 - 10000
    function setPlatformFee(uint32 _fee) external onlyOwner {
        platformFee = _fee;
    }

    // 0 - 10000
    function setDiscount(address collection, uint32 rate) external onlyOwner {
        collectionToAdaptiveFee[collection] = AdaptiveFee({
            secondaryAddress: address(0),
            rate: rate,
            feeType: 1
        });
        emit AdaptiveFeeUpdated(collection, rate, 1);
    }

    // 0 - 10000
    function setFeeSharing(address collection, uint32 rate, address feeReceiver) external onlyOwner {
        collectionToAdaptiveFee[collection] = AdaptiveFee({
            secondaryAddress: feeReceiver,
            rate: rate,
            feeType: 2
        });
        emit AdaptiveFeeUpdated(collection, rate, 1);
    }
    // --------- OWNER FUNCTIONS ---------

    function getFeeDetails(address collection, address user) external view returns(uint32, uint32, uint8, address) {
        AdaptiveFee memory adaptiveFee = collectionToAdaptiveFee[collection];
        if (adaptiveFee.rate == 0) {
            return (platformFee, 0, 0, address(0));
        }
        unchecked {
            uint32 platformDiscount = (platformFee * adaptiveFee.rate) / (100 * percentageMultiplier);
            uint32 newPlatformFee = platformFee - platformDiscount;
            return (newPlatformFee, platformDiscount, adaptiveFee.feeType, adaptiveFee.secondaryAddress);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFeeManager {
    function getFeeDetails(address collection, address user) external view returns(uint32, uint32, uint8, address);
}