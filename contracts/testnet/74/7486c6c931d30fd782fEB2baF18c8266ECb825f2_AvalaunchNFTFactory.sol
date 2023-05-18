/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IAvalaunchNFT is IERC721Upgradeable, IERC721MetadataUpgradeable {
    function initialize(
        address _owner,
        address _royaltyReceiver,
        uint256 _collectionSize,
        uint256 _revealBatchSize,
        string calldata _collectionName,
        string calldata _collectionSymbol
    ) external;
}

error BatchReveal__InvalidInitParams();
error BatchReveal__NoBatchAvailable();

error AvalaunchNFT__InvalidRoyaltySettings();
error AvalaunchNFT__AVAXTransferFailed();
error AvalaunchNFT__CollectionSizeLimitReached();
error AvalaunchNFT__InvalidSignature();
error AvalaunchNFT__OnlyDirectCalls();
error AvalaunchNFT__InvalidNFTPrice();
error AvalaunchNFT__InvalidAddress();
error AvalaunchNFT__InvalidMessageValue();
error AvalaunchNFT__MintLimitCrossed();
error AvalaunchNFT__ArrayLengthMismatch();
error AvalaunchNFT__SaleNotStartedYet();
error AvalaunchNFT__InvalidPricing();
error AvalaunchNFT__TimestampsCrossing();
error AvalaunchNFT__InvalidCallbackGasLimit();
error AvalaunchNFT__InvalidKeyHash();
error AvalaunchNFT__ContractIsNotConsumer();
error AvalaunchNFT__BalanceEmpty();
error AvalaunchNFT__BaseURIAlreadySet();
error AvalaunchNFT__unrevealedURIAlreadySet();
error AvalaunchNFT__VRFAlreadySet();
error AvalaunchNFT__SignatureExpired();
error AvalaunchNFT__SignatureAlreadyUsed();
error AvalaunchNFT__VRFNotActive();

error AvalaunchNFTMarketplace__ZeroValue();
error AvalaunchNFTMarketplace__InvalidCaller();
error AvalaunchNFTMarketplace__InvalidMessageValue();
error AvalaunchNFTmarketplace__LowLevelCallFailed();
error AvalaunchNFTMarketplace__NoFees();
error AvalaunchNFTMarketplace__InvalidAddress();
error AvalaunchNFTMarketplace__ItemUnavailable();
error AvalaunchNFTMarketplace__AskInactive();
error AvalaunchNFTMarketplace__InvalidFeeParameters();
error AvalaunchNFTMarketplace__InvalidItemId();
error AvalaunchNFTMarketplace__InvalidBiddingParameters();
error AvalaunchNFTMarketplace__AuctionEnded();
error AvalaunchNFTMarketplace__AuctionInProgress();
error AvalaunchNFTMarketplace__ArrayLengthMismatch();
error AvalaunchNFTMarketplace__InvalidStartingPrice();
error AvalaunchNFTMarketplace__InvalidTimeExtensionPerBid();
error AvalaunchNFTMarketplace__AskAlreadyActive();
error AvalaunchNFTMarketplace__InvalidAskExpirationTime();
error AvalaunchNFTMarketplace__InvalidAmount();

error AvalaunchNFTFactory__ImplementationAlreadySet();
error AvalaunchNFTFactory__ImplementationNotSet();
error AvalaunchNFTFactory__CloneCreationFailed();
error AvalaunchNFTFactory__InitializationFailed();
error AvalaunchNFTFactory__InvalidIndexParams();

contract AvalaunchNFTFactory is Ownable {
    // Contains NFTs deployed by this factory
    mapping(address => bool) public deployedThroughFactory;
    // Expose so query can be possible only by position as well
    address[] public deployments;
    // AvalaunchNFT implementation
    address public implementation;

    // Events
    event Deployed(address addr);
    event ImplementationSet(address implementation);

    constructor(address owner) {
        transferOwnership(owner);
    }

    /**
     * @notice Function to set the latest implementation
     * @param _implementation is AvalaunchNFT contract implementation
     */
    function setImplementation(address _implementation) external onlyOwner {
        // Require that implementation is different from current one
        if (_implementation == implementation) {
            revert AvalaunchNFTFactory__ImplementationAlreadySet();
        }
        // Set new implementation
        implementation = _implementation;
        // Emit relevant event
        emit ImplementationSet(implementation);
    }

    /**
     * @notice Function to deploy new NFT instance
     * @param _royaltyReceiver is royalty receiver address
     * @param _collectionSize is number of NFT contained in this collection
     * @param _revealBatchSize is a number of NFTs contained in a single reveal batch
     * @param _collectionName is name of an NFT collection
     * @param _collectionSymbol is symbol of an NFT collection
     */
    function deploy(
        address _royaltyReceiver,
        uint256 _collectionSize,
        uint256 _revealBatchSize,
        string calldata _collectionName,
        string calldata _collectionSymbol
    ) external onlyOwner {
        // Require that implementation is set
        if (implementation == address(0)) {
            revert AvalaunchNFTFactory__ImplementationNotSet();
        }

        // Deploy clone
        address clone;
        // Inline assembly works only with local vars
        address imp = implementation;

        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, imp)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, imp), 0x5af43d82803e903d91602b57fd5bf3))
            clone := create(0, 0x09, 0x37)
        }
        // Require that clone is created
        if (clone == address(0)) {
            revert AvalaunchNFTFactory__CloneCreationFailed();
        }

        // Mark sale as created through official factory
        deployedThroughFactory[clone] = true;
        // Add sale to allSales
        deployments.push(clone);

        // Initialize instance
        IAvalaunchNFT(clone).initialize(
            owner(),
            _royaltyReceiver,
            _collectionSize,
            _revealBatchSize,
            _collectionName,
            _collectionSymbol
        );

        // Emit relevant event
        emit Deployed(clone);
    }

    /// @notice     Function to return number of pools deployed
    function deploymentsCounter() external view returns (uint) {
        return deployments.length;
    }

    /// @notice     Get most recently deployed sale
    function getLatestDeployment() external view returns (address) {
        if (deployments.length > 0) return deployments[deployments.length - 1];
        // Return zero address if no deployments were made
        return address(0);
    }

    /**
     * @notice Function to get all deployments between indexes
     * @param startIndex first margin
     * @param endIndex second margin
     */
    function getAllDeployments(uint startIndex, uint endIndex) external view returns (address[] memory) {
        // Require valid index input
        if (endIndex < startIndex || endIndex >= deployments.length) {
            revert AvalaunchNFTFactory__InvalidIndexParams();
        }
        // Create new array
        address[] memory _deployments = new address[](endIndex - startIndex + 1);
        uint index = 0;
        // Fill the array with sale addresses
        for (uint i = startIndex; i <= endIndex; i++) {
            _deployments[index] = deployments[i];
            index++;
        }
        return _deployments;
    }
}