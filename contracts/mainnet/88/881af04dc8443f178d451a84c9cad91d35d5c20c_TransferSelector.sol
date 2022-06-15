// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ITransferSelector} from "./interfaces/ITransferSelector.sol";

contract TransferSelector is ITransferSelector, Ownable {

    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd; //ERC721
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26; // ERC1155
    address public immutable TRANSFER_MANAGER_ERC721;
    address public immutable TRANSFER_MANAGER_ERC1155;
    // used for sepecial collections that do not implement ERC721 || ERC1155 standards
    mapping(address => address) public transferManagerSelectorForCollection; 

    event CollectionTransferManagerAdded(address indexed collection, address indexed transferManager);
    event CollectionTransferManagerRemoved(address indexed collection);

    constructor(address _transferManagerERC721, address _transferManagerERC1155) {
        TRANSFER_MANAGER_ERC721 = _transferManagerERC721;
        TRANSFER_MANAGER_ERC1155 = _transferManagerERC1155;
    }

    /**
     *
     * @param collection contract address of the NFT collection
     * @param transferManager contract address of the costume transfer manager
     * @notice adds a new transfer manager to handle special cases
     */
    function addTransferManager(address collection, address transferManager) external onlyOwner{
        require(collection != address(0), "TransferSelector: Collection can not be null");
        require(transferManager != address(0), "TransferSelector: Transfer manager can not be null");
        transferManagerSelectorForCollection[collection] = transferManager;
        emit CollectionTransferManagerAdded(collection, transferManager);
    }

    /**
     *
     * @param collection contract address of the NFT collection
     * @notice removes the costume transfer manager if exists
     */
    function removeTransferManager (address collection) external onlyOwner{
        require(transferManagerSelectorForCollection[collection] != address(0), "TransferSelector: Transfer manager for this collection does not exist" );
        transferManagerSelectorForCollection[collection] = address(0);
        emit CollectionTransferManagerRemoved(collection);
    }

    /**
     *
     * @param collection contract address of the NFT collection
     * @notice returns the transfer manager of the collection ERC721 || ERC1155 || costume transfer manager
     */
    function checkTransferManagerForToken(address collection) external view override returns (address transferManager) {
        transferManager = transferManagerSelectorForCollection[collection];
        if(transferManager == address(0)){
            if(IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)){
                return TRANSFER_MANAGER_ERC721;
            }
            else if(IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)){
                return TRANSFER_MANAGER_ERC1155;
            }
        }
        return transferManager;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferSelector {
    function checkTransferManagerForToken(address collection) external view returns (address);
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