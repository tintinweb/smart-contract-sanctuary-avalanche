// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.19;

interface ILelandTrade {
    struct RarityInfo {
        uint16 rarityType;
        string rarityName;
    }

    struct CollectionInfo {
        uint16 rarityType;
        uint16 cardId;
    }

    /// @notice Set rarityType information.
    /// @dev Only owner can call this function.
    function setRarityType(
        uint16 _rarityId,
        RarityInfo memory _rarityInfo
    ) external;

    /// @notice Set RarityType information.
    /// @dev Only owner can call this function.
    function addRarityType(RarityInfo memory _rarityInfo) external;

    /// @notice Set tokenIds by the specific rarity type.
    /// @dev Only owner can call this function.
    function setTokenIdsByRarity(
        uint16 _rarityId,
        uint16[] memory _cardIds,
        uint256[] memory _tokenIds
    ) external;

    /// @notice Deposit Collection to contract.
    /// @dev Only owner can call this function.
    function depositCollection(uint256[] memory _tokenIds) external;

    /// @notice Get upgraded collection by burning collections.
    /// @dev Anyone can call this function but collectiosn rarity should be same.
    function upgradeCollection(
        uint256[] memory _tokenIds,
        bool _duplicateMode
    ) external;

    /// @notice Get certain upgraded collection by burning collections.
    /// @dev Anyone call this function but users should pick up deposited upgraded collection.
    function upgradeCollectionForCertainCollection(
        uint256[] memory _tokenIds,
        uint256[] memory _targetTokenIDs,
        bool _duplicate
    ) external;

    /// @notice Get depositedTokenIds by rarity type
    function getDepositedTokenIdsByRarity(
        uint16 _rarityId
    ) external view returns (uint256[] memory);

    event RarityTypeSet(uint16 rarityId, RarityInfo rarityInfo);

    event RarityTypeAdded(RarityInfo rarityInfo);

    event TokenIdsByRaritySet(
        uint16 rarityId,
        uint16[] cardIds,
        uint256[] tokenIds
    );

    event CollectionDeposited(uint256[] tokenIds);

    event CollectionUpgraded(uint256[] tokenIds, bool duplicateMode);

    event CollectionUpgradedWithCertainCollection(
        uint256[] tokenIds,
        uint256[] targetTokenIds,
        bool duplicateMode
    );
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/ILelandTrade.sol";

contract LelandTrade is ERC721Holder, Ownable, ILelandTrade {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint16 => RarityInfo) private rarityTypes;
    mapping(uint16 => EnumerableSet.UintSet) private depositedTokenIdsPerRarity;
    mapping(uint256 => CollectionInfo) private collectionInfo;
    mapping(uint256 => EnumerableSet.UintSet) private tokenIdsPerRarity;

    address public lelandNFT;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint16 public duplicateAmountForUpgrade;

    uint16 public differentAmountForUpgrade;

    uint16 public rarityId;

    bool public transferAllowed;

    modifier allowTransfer() {
        transferAllowed = true;
        _;
        transferAllowed = false;
    }

    constructor(
        address _lelandNFT,
        uint16 _duplicateAmountForUpgrade,
        uint16 _differentAmountForUpgrade
    ) {
        require(_lelandNFT != address(0), "zero LelandNFT address");
        require(
            _duplicateAmountForUpgrade > 0 && _differentAmountForUpgrade > 0,
            "invalid upgrade amount"
        );
        duplicateAmountForUpgrade = _duplicateAmountForUpgrade;
        differentAmountForUpgrade = _differentAmountForUpgrade;
        lelandNFT = _lelandNFT;
        rarityId = 1;
    }

    /// @inheritdoc ILelandTrade
    function addRarityType(
        RarityInfo memory _rarityInfo
    ) external override onlyOwner {
        rarityTypes[rarityId++] = _rarityInfo;
        emit RarityTypeAdded(_rarityInfo);
    }

    /// @inheritdoc ILelandTrade
    function setRarityType(
        uint16 _rarityId,
        RarityInfo memory _rarityInfo
    ) external override onlyOwner {
        require(_rarityId > 0 && _rarityId < rarityId, "invalid rarityId");
        rarityTypes[_rarityId] = _rarityInfo;

        emit RarityTypeSet(_rarityId, _rarityInfo);
    }

    /// @inheritdoc ILelandTrade
    function setTokenIdsByRarity(
        uint16 _rarityId,
        uint16[] memory _cardIds,
        uint256[] memory _tokenIds
    ) external override onlyOwner {
        require(_rarityId > 0 && _rarityId < rarityId, "invalid rarityId");
        uint256 length = _tokenIds.length;
        require(length > 0, "invalid length array");
        require(length == _cardIds.length, "mismatch length array");

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(
                !tokenIdsPerRarity[_rarityId].contains(tokenId),
                "already added"
            );
            tokenIdsPerRarity[_rarityId].add(tokenId);
            collectionInfo[tokenId] = CollectionInfo(_rarityId, _cardIds[i]);
        }

        emit TokenIdsByRaritySet(_rarityId, _cardIds, _tokenIds);
    }

    /// @inheritdoc ILelandTrade
    function depositCollection(
        uint256[] memory _tokenIds
    ) external override onlyOwner allowTransfer {
        uint256 length = _tokenIds.length;
        address sender = msg.sender;
        require(length > 0, "invalid length array");
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint16 rarity = collectionInfo[tokenId].rarityType;
            require(rarity > 0, "unregistered tokenId");
            IERC721(lelandNFT).safeTransferFrom(sender, address(this), tokenId);
            depositedTokenIdsPerRarity[rarity].add(tokenId);
        }

        emit CollectionDeposited(_tokenIds);
    }

    /// @inheritdoc ILelandTrade
    function upgradeCollectionForCertainCollection(
        uint256[] memory _tokenIds,
        uint256[] memory _targetTokenIds,
        bool _duplicateMode
    ) external override {
        (uint16 upgradeRarity, uint256 upgradeCollectionCnt) = _checkCollection(
            _tokenIds,
            _duplicateMode
        );
        uint256 length = _targetTokenIds.length;
        require(
            upgradeCollectionCnt == length,
            "invalid targetTokenIds array length"
        );

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _targetTokenIds[i];
            require(
                depositedTokenIdsPerRarity[upgradeRarity].contains(tokenId),
                "not deposited target collection"
            );
            depositedTokenIdsPerRarity[upgradeRarity].remove(tokenId);
            IERC721(lelandNFT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }

        emit CollectionUpgradedWithCertainCollection(
            _tokenIds,
            _targetTokenIds,
            _duplicateMode
        );
    }

    /// @inheritdoc ILelandTrade
    function upgradeCollection(
        uint256[] memory _tokenIds,
        bool _duplicateMode
    ) external override {
        (uint16 upgradeRarity, uint256 upgradeCollectionCnt) = _checkCollection(
            _tokenIds,
            _duplicateMode
        );

        uint256[] memory tokenIds = depositedTokenIdsPerRarity[upgradeRarity]
            .values();
        for (uint256 i = 0; i < upgradeCollectionCnt; i++) {
            uint256 tokenId = tokenIds[i];
            depositedTokenIdsPerRarity[upgradeRarity].remove(tokenId);
            IERC721(lelandNFT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }

        emit CollectionUpgraded(_tokenIds, _duplicateMode);
    }

    /// @inheritdoc ILelandTrade
    function getDepositedTokenIdsByRarity(
        uint16 _rarityId
    ) external view override returns (uint256[] memory) {
        return depositedTokenIdsPerRarity[_rarityId].values();
    }

    function _checkCollection(
        uint256[] memory _tokenIds,
        bool _duplicateMode
    ) internal returns (uint16, uint256) {
        uint256 length = _tokenIds.length;
        require(length > 0, "invalid length array");

        uint16 originRarity = collectionInfo[_tokenIds[0]].rarityType;

        require(originRarity > 0, "unregistered tokenId");
        require(originRarity < rarityId - 1, "last rare");

        uint256 upgradeCollectionCnt = length /
            (
                _duplicateMode
                    ? duplicateAmountForUpgrade
                    : differentAmountForUpgrade
            );
        require(
            depositedTokenIdsPerRarity[originRarity + 1].length() >=
                upgradeCollectionCnt,
            "not enough upgradeable collection"
        );
        require(
            (_duplicateMode && length % duplicateAmountForUpgrade == 0) ||
                (!_duplicateMode && length % differentAmountForUpgrade == 0),
            "incorrect upgrade amount"
        );
        require(upgradeCollectionCnt > 0, "not enough collection for upgrade");
        for (uint256 i = 0; i < length; i++) {
            require(
                originRarity == collectionInfo[_tokenIds[i]].rarityType,
                "rarity type should be same"
            );
        }

        if (_duplicateMode) {
            uint16 originCardId = collectionInfo[_tokenIds[0]].cardId;
            for (uint256 i = 0; i < length; i++) {
                require(
                    collectionInfo[_tokenIds[i]].cardId == originCardId,
                    "collection cardId should be same"
                );
            }
        } else {
            for (uint256 i = 0; i < length - 1; i++) {
                uint16 cardId = collectionInfo[_tokenIds[i]].cardId;
                for (uint256 j = i + 1; j < length; j++) {
                    require(
                        cardId != collectionInfo[_tokenIds[j]].cardId,
                        "collection cardId should be different"
                    );
                }
            }
        }

        for (uint256 i = 0; i < length; i++) {
            IERC721(lelandNFT).safeTransferFrom(msg.sender, DEAD, _tokenIds[i]);
        }

        return (originRarity + 1, upgradeCollectionCnt);
    }
}