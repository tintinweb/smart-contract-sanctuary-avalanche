// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRoyaltyFeeRegistry} from "./interfaces/IRoyaltyFeeRegistry.sol";

/**
 * @title RoyaltyFeeRegistry
 * @notice Handles collections fee to be distributed in NFT sales 
 */
contract RoyaltyFeeRegistry is IRoyaltyFeeRegistry, Ownable {

    struct RoyaltyFeeInfo {
        address setter;
        address receiver;
        uint256 fee;
    }

    uint256 public royaltyFeeLimit;

    mapping(address => RoyaltyFeeInfo) private _collectionRoyaltyFeeInfo;

    event NewRoyaltyFeeLimit(uint256 royaltyFeeLimit);
    event RoyaltyFeeUpdate(address indexed collection, address indexed setter, address indexed receiver, uint256 fee);

    /**
     *
     * @param _royaltyFeeLimit declare fee limit 100 = 1%  read more at : https://en.wikipedia.org/wiki/Basis_point
     */
    constructor(uint256 _royaltyFeeLimit) {
        require(_royaltyFeeLimit <= 9500, "RoyaltyFeeRegistry: Fee too high, must be lower than 9500 equivalent to (95%)");
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice Updates royalty info for an NFT collection
     */
    function updateRoyaltyInfoForCollection(address collection, address setter, address receiver, uint256 fee) external override onlyOwner{
        require(fee <= royaltyFeeLimit, "RoyaltyFeeRegistry: Fee is too high");
        _collectionRoyaltyFeeInfo[collection] = RoyaltyFeeInfo({setter:setter, receiver: receiver, fee: fee });

        emit RoyaltyFeeUpdate(collection, setter, receiver, fee);
    }

    /**
     *
     * @param _royaltyFeeLimit update royalty fee limit for all collections 100 = 1%
     * @notice Updates the royalty fee limit
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external override onlyOwner{
        require(_royaltyFeeLimit <= 9500, "RoyaltyFeeRegistry: Fee too high, must be lower than 9500 equivalent to (95%)");
        royaltyFeeLimit = _royaltyFeeLimit;

        emit NewRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param salePrice the transfer value
     * @notice finds the royalty receiever and royalty amount in wei 
     * @return (address, uint256)
     */    
    function royaltyInfo(address collection, uint256 salePrice) external view override returns (address, uint256){
        return (_collectionRoyaltyFeeInfo[collection].receiver, (salePrice * _collectionRoyaltyFeeInfo[collection].fee) / 10000);
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @notice returns the collection Royalty Info (setter, receiver, fee) 
     * @return (address, address, uint256)
     */    
    function collectionRoyaltyFeeInfo(address collection)external view override returns (address, address, uint256) {
        return (_collectionRoyaltyFeeInfo[collection].setter, _collectionRoyaltyFeeInfo[collection].receiver, _collectionRoyaltyFeeInfo[collection].fee);
    }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeRegistry {

    function updateRoyaltyInfoForCollection(address collection, address setter, address receiver, uint256 fee) external;

    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function royaltyInfo(address collection, uint256 salePrice) external view returns (address, uint256);

    function collectionRoyaltyFeeInfo(address collection) external view returns (address, address, uint256);
    
}