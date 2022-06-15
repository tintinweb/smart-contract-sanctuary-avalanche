// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IRoyaltyFeeRegistry} from "./interfaces/IRoyaltyFeeRegistry.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";

/**
 *
 * @title RoyaltyFeeSetter
 * @notice Controlls collections fee in the royalty fee registry.
 */
contract RoyaltyFeeSetter is Ownable {
    
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd; // ERC721
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26; // ERC1155 
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a; // ERC2981

    address public immutable royaltyFeeRegistry;


    constructor(address _royaltyFeeRegistry) {
        royaltyFeeRegistry = _royaltyFeeRegistry;
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice Updates royalty info for an NFT collection, can only be called by this contract owner
     */
    function updateRoyaltyInfoForCollection(address collection, address setter, address receiver, uint256 fee) external onlyOwner {
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }


    /**
     *
     * @param _owner address of the new contract owner 
     * @notice Updates the owner of RoyaltyFeeRegistry Contract
     */
    function updateOwnerOfRoyaltyFeeRegistry(address _owner) external onlyOwner {
        IOwnable(royaltyFeeRegistry).transferOwnership(_owner);
    }

    /**
     *
     * @param _royaltyFeeLimit new fee limit according to basis_points
     * @notice Updates the fee limit in the RoyaltyFeeRegistry Contract
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external onlyOwner {
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     *
     * @param collection address of the NFT Collection
     * @notice chekcs royalty info for collections
     * @return the setter if exists
     * 0 = current setter
     * 1 = Contracts supports eip2981 no setter in registry
     * 2 = setter is the contract owner
     * 3 = setter is the contract admin
     * 4 = setter cannot be set in any method (use updateRoyaltyInfoForCollection in this case)
     */
    function checkForCollectionSetter(address collection) external view returns (address, uint8) {
        (address currentSetter, , ) = IRoyaltyFeeRegistry(royaltyFeeRegistry).collectionRoyaltyFeeInfo(collection);

        if (currentSetter != address(0)) {
            return (currentSetter, 0);
        }

        try IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981) returns (bool interfaceSupport) {
            if (interfaceSupport) {
                return (address(0), 1);
            }
        } catch {}

        try IOwnable(collection).owner() returns (address setter) {
            return (setter, 2);
        } catch {
            try IOwnable(collection).admin() returns (address setter) {
                return (setter, 3);
            } catch {
                return (address(0), 4);
            }
        }
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice Updates royalty info for an NFT collection, can only be called by collection contract setter
     */
    function updateRoyaltyInfoForCollectionIfSetter(address collection, address setter, address receiver, uint256 fee) external {
        (address _setter, , ) = IRoyaltyFeeRegistry(royaltyFeeRegistry).collectionRoyaltyFeeInfo(collection);
        require(msg.sender == _setter, "RoyaltyFeeSetter: message sender is not the collection setter");
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice Updates royalty info for an NFT collection, can only be called by collection contract admin
     */
    function updateRoyaltyInfoForCollectionIfAdmin(address collection, address setter, address receiver, uint256 fee) external {
        require(!IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981), "RoyaltyFeeSetter: Royalty already set, must not support ERC2981");
        require(msg.sender == IOwnable(collection).admin(), "RoyaltyFeeSetter: message sender is not the collection admin");
        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(collection, setter, receiver, fee);
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice Updates royalty info for an NFT collection, can only be called by collection contract owner
     */
    function updateRoyaltyInfoForCollectionIfOwner(address collection, address setter, address receiver, uint256 fee) external {
        require(!IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981), "RoyaltyFeeSetter: Royalty already set, must not support ERC2981");
        require(msg.sender == IOwnable(collection).owner(), "RoyaltyFeeSetter: message sender is not the collection owner");
        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(collection, setter, receiver, fee);
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice called in updateRoyaltyInfoForCollectionIfOwner && updateRoyaltyInfoForCollectionIfAdmin to check if the collection supports ERC721 | ERC115 && new setter
     */
    function _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(address collection, address setter, address receiver, uint256 fee) internal {
        (address currentSetter, , ) = IRoyaltyFeeRegistry(royaltyFeeRegistry).collectionRoyaltyFeeInfo(collection);
        require(currentSetter == address(0), "RoyaltyFeeSetter: Setter Already set, update using updateRoyaltyInfoForCollectionIfSetter() instead");
        require( (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) || IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
            "RoyaltyFeeSetter: Contract is not ERC721 || ERC1155");
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeRegistry {

    function updateRoyaltyInfoForCollection(address collection, address setter, address receiver, uint256 fee) external;

    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function royaltyInfo(address collection, uint256 salePrice) external view returns (address, uint256);

    function collectionRoyaltyFeeInfo(address collection) external view returns (address, address, uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);

    function admin() external view returns (address);
}