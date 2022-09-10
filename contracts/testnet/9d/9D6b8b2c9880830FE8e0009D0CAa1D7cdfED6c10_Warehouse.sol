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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./base/Structs.sol";

contract Warehouse is Ownable {
    mapping(uint256 => Product) private _products;
    mapping(uint256 => mapping(uint256 => Variant)) private _variants;

    function updateProducts(bytes[] memory _datas) public onlyOwner {
        for (uint256 i = 0; i < _datas.length; i++) {
            (uint256 productId, uint256 variantId, uint256 priceUsd, bool enabled) = abi.decode(
                _datas[i],
                (uint256, uint256, uint256, bool)
            );
            if (variantId != 0) {
                _products[productId] = Product(priceUsd, enabled);
            } else {
                _variants[productId][variantId] = Variant(priceUsd, enabled);
            }
        }
    }

    function getPriceUsd(uint256 productId, uint256 variantId) public view returns (uint256) {
        if (_variants[productId][variantId].priceUsd > 0) {
            return _variants[productId][variantId].priceUsd;
        }
        return _products[productId].priceUsd;
    }

    function getProduct(uint256 productId) public view returns (Product memory) {
        return _products[productId];
    }

    function getVariant(uint256 productId, uint256 variantId) public view returns (Variant memory) {
        return _variants[productId][variantId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct Variant {
    uint256 priceUsd;
    bool enabled;
}

struct Product {
    uint256 priceUsd;
    bool enabled;
}

struct OrderItem {
    uint256 amount;
    uint256 productId;
    uint256 variantId;
    NFT nft;
}

struct Order {
    address user;
    OrderItem[] items;
    uint256 total;
}

struct Reward {
    uint256 amount;
    uint256 released;
    uint256 releasedTotal;
}

struct NFT {
    uint256 chainId;
    // Use string instead address to support also non EVM Blockchains
    string tokenAddress;
    uint256 tokenId;
}

struct NFTCollection {
    uint256 chainId;
    string tokenAddress;
    address owner;
}