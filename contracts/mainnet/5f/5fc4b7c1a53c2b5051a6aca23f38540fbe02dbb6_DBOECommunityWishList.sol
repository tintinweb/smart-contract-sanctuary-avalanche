/**
 *Submitted for verification at snowtrace.io on 2023-05-31
*/

// Sources flattened with hardhat v2.11.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/DBOECommunityWishList.sol


pragma solidity >= 0.8.11;

contract DBOECommunityWishList is Ownable {
    
    struct OneWish {
        bytes32 coin;        
        bytes32 coinLink;
        bool callPut;
        uint256 strike;
        uint256 condStrike;
        uint256 expiryUtc;

        uint256 noOfVotes;
        uint256 inTimeUtc;                
        uint256 expiryTimeUtc;        
        bytes32 status;
        bool invalid;          
    }
    
    mapping(uint256 => OneWish) public wishMap;        
    uint256 public runningWishIdx = 0;    
   
    // total token, token left, max slot, slot left, min order size, price per token, price scale
    function dashboard() external view returns (OneWish[] memory) {
        OneWish[] memory wishes = new OneWish[](runningWishIdx);
        for(uint idx = 0; idx < runningWishIdx; idx++) {
            wishes[idx] = wishMap[idx];
        }
        return wishes;
    }

    function addWish(bytes32 coin, bytes32 coinlink, bool callPut, uint256 strike, uint256 condStrike, uint256 expiryUtc, uint256 timeoutSec) public {
        wishMap[runningWishIdx] = OneWish(coin, coinlink, callPut, strike, condStrike, expiryUtc, 1, block.timestamp, block.timestamp + timeoutSec, stringToBytes32("Open"), false);
        runningWishIdx += 1;
    }

    function vote(uint256 _wishId) public {
        require(_wishId < runningWishIdx, "Nonexisted");                
        OneWish memory oneWish = wishMap[_wishId];
        require(!oneWish.invalid, "Invalid Wish"); 
        require(block.timestamp <= oneWish.expiryTimeUtc, "Expired wish");        
        oneWish.noOfVotes += 1;            
    }
     
    function revokeWish(uint256 _wishId) public onlyOwner {       
        require(_wishId <= runningWishIdx, "Nonexisted"); 
        wishMap[_wishId].invalid = true;        
    }

    function updateWish(uint256 _wishId, bytes32 status) public onlyOwner {       
        require(_wishId <= runningWishIdx, "Nonexisted"); 
        wishMap[_wishId].status = status;        
    }          

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
  }
}