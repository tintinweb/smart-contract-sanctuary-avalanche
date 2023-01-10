/**
 *Submitted for verification at snowtrace.io on 2023-01-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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

interface ISuperReveal {
    function setRevealInfo(uint256 _collectionSize, uint256 _batchSize) external;
    function getShuffledTokenId(uint256 tokenId) external view returns (uint256);
    function tokenIdAvailable(uint256 tokenId) external view returns (bool);
    function hasBatchToReveal() external view returns (uint256);
    function revealNextBatch() external;
}

interface ILaunchpeg {
    function collectionSize() external view returns (uint256);
}

// Steps:
// Set contract addresses
// ClaimWallet must approve the usage of super doge against ChadDogeLab contract
// Set vialF ids
// Call initialize
// Open lab

// Testnet: 0x7394958297bb2d4b8c4b76dd1f0811b6437f585d
contract ChadDogeLab is Ownable {
    address constant public nullAddress = 0x000000000000000000000000000000000000dEaD;

    address private revealAddress;
    address private claimWallet;
    address public superAddress;
    address constant public vialAddress = 0x72a1fc6dFd1FE8B246fcCc441f9356E2659c52a2; // TODO::: change later (test vial address)
    address constant public chadDogeAddress = 0x74D00b755b36aA87D2BFf487c2EF3B14E7c79149; // TODO::: change later (test CD)

    // Claim process variables
    Range public vialFMetadataRange;
    mapping(uint256 => uint256) public vialFIds;
    mapping(uint256 => ClaimedSuperDoge) public usedChadDoges;
    mapping(uint256 => ClaimedSuperDoge) public superTokenIdToMetadata;
    mapping(uint256 => ClaimedSuperDoge) public superMetadataToTokenId;

    BurnedVials public burnedVials;
    uint256 public unrevealedMetadataId;
    uint256 public nextTokenId = 0;
    uint256 public publicSaleStartId;
    uint256 public labOpen = 0;

    struct BurnedVials {
        uint256 n;
        uint256 f;
    }

    struct Range {
        uint256 min;
        uint256 max;
    }

    struct ClaimedSuperDoge {
        uint256 id;
        uint256 claimed;
    }

    error InvalidTokenId();
    error UnexpectedError();
    error LabNotOpen();
    error Unauthorized();

    event SuperClaimed(uint256 indexed chadDogeId, uint256 indexed vialId, uint256 indexed superId, uint256 superMetadataId);

    modifier requireLabOpen() {
        if (labOpen != 1) {
            revert LabNotOpen();
        }
        _;
    }

    constructor(uint256 _f1, uint256 _f2, uint256 _f3, uint256 _f4, uint256 _f5) {
        setFVials(_f1, _f2, _f3, _f4, _f5);
        burnedVials = BurnedVials({
            n: 0,
            f: 0
        });
    }

    function setLabOpen(uint256 _labOpen) external onlyOwner {
        labOpen = _labOpen;
    }

    // reveal address, claim wallet, super address, public sale start id (2185)
    // batch size (563), min f metadata id (3250), max f metadata id (3254)
    function initialize(address _rev, address _claimWallet,
        address _superAddress, uint256 _publicSaleStartId,
        uint256 _batchSize, uint256 _minFMetadataId,
        uint256 _maxFMetadataId, uint256 _unrevealedMetadataId) external onlyOwner {
        revealAddress = _rev;
        claimWallet = _claimWallet;
        superAddress = _superAddress;
        publicSaleStartId = _publicSaleStartId;
        uint256 revealCollectionSize = ILaunchpeg(superAddress).collectionSize() - publicSaleStartId;
        ISuperReveal(revealAddress).setRevealInfo(revealCollectionSize, _batchSize);
        vialFMetadataRange = Range({
            min: _minFMetadataId,
            max: _maxFMetadataId
        });
        unrevealedMetadataId = _unrevealedMetadataId;
    }

    function setFVials(uint256 _f1, uint256 _f2, uint256 _f3, uint256 _f4, uint256 _f5) public onlyOwner {
        vialFIds[_f1] = 1;
        vialFIds[_f2] = 1;
        vialFIds[_f3] = 1;
        vialFIds[_f4] = 1;
        vialFIds[_f5] = 1;
    }

    function claimSuper(uint256 _vialID, uint256 _chadDogeID) external requireLabOpen {
        if (IERC721(chadDogeAddress).ownerOf(_chadDogeID) != msg.sender) revert InvalidTokenId();
        if (IERC721(vialAddress).ownerOf(_vialID) != msg.sender) revert InvalidTokenId();
        if (usedChadDoges[_chadDogeID].claimed == 1) revert InvalidTokenId();

        uint256 superMetadataID;
        // Pick random super chad from ALLOCATED_FOR_VIAL_F range
        if (vialFIds[_vialID] == 1) {
            unchecked {
                burnedVials.f++;
                uint256 minFID = vialFMetadataRange.min;
                uint256 totalF = vialFMetadataRange.max - minFID;
                uint256 offset = rand(totalF);
                superMetadataID = minFID + offset;
                if (superMetadataToTokenId[superMetadataID].claimed == 1) {
                    uint256 found = 0;
                    for (uint256 i = 0; i < totalF; i++) {
                        offset = (offset + 1) % totalF;
                        superMetadataID = minFID + offset;
                        if (superMetadataToTokenId[superMetadataID].claimed == 0) {
                            found = 1;
                            break;
                        }
                    }
                    if (found == 0) {
                        revert UnexpectedError();
                    }
                }
            }
        } else {
            // 1/1 mapping
            superMetadataID = _chadDogeID;
            burnedVials.n++;
        }
        // Transfer vial to null address and transfer next super to claimer
        IERC721(vialAddress).transferFrom(msg.sender, nullAddress, _vialID);
        IERC721(superAddress).transferFrom(claimWallet, msg.sender, nextTokenId);

        // Record the claim
        superMetadataToTokenId[superMetadataID] = ClaimedSuperDoge({
            id: nextTokenId,
            claimed: 1
        });
        superTokenIdToMetadata[nextTokenId] = ClaimedSuperDoge({
            id: superMetadataID,
            claimed: 1
        });
        usedChadDoges[_chadDogeID] = ClaimedSuperDoge({
            id: nextTokenId,
            claimed: 1
        });
        emit SuperClaimed(_chadDogeID, _vialID, nextTokenId, superMetadataID);
        unchecked {
            nextTokenId++;
        }
    }

    function rand(uint256 num) private view returns (uint256) { // num 50 here would return a pseudorandom number between 0-49
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % num;
    }

    // Launchpeg - BatchReveal compatibility
    function launchpegToLastTokenReveal(address _adr) external view returns (uint256) {
        return ILaunchpeg(superAddress).collectionSize();
    }

    function getShuffledTokenId(address _baseLaunchpeg, uint256 tokenId) external view returns (uint256) {
        // launchpeg ownerOf throws error if token is not minted so this provides 2 level unrevealed protection
        if (IERC721(superAddress).ownerOf(tokenId) == claimWallet) {
            return unrevealedMetadataId;
        }
        uint256 metadataTokenId;
        // This means the token is not the part of the public sale so we have metadata mapping for it
        if (tokenId < publicSaleStartId) {
            if (superTokenIdToMetadata[tokenId].claimed == 0) {
                return unrevealedMetadataId;
            }
            metadataTokenId = superTokenIdToMetadata[tokenId].id;
        } else {
            uint256 revealTokenId = tokenId - publicSaleStartId;
            ISuperReveal reveal = ISuperReveal(revealAddress);
            if (reveal.tokenIdAvailable(revealTokenId)) {
                // public sale ids start after F vial range
                metadataTokenId = (vialFMetadataRange.max + 1) + reveal.getShuffledTokenId(revealTokenId);
            } else {
                return unrevealedMetadataId;
            }
        }
        return metadataTokenId;
    }

    function hasBatchToReveal(address _baseLaunchpeg, uint256 _totalSupply) public view returns (bool, uint256) {
        return (ISuperReveal(revealAddress).hasBatchToReveal() == 1, 0);
    }

    // Can only be called while lab is open
    function revealNextBatch(address _baseLaunchpeg, uint256 _totalSupply) external requireLabOpen returns (bool) {
        ISuperReveal(revealAddress).revealNextBatch();
        return true;
    }
}