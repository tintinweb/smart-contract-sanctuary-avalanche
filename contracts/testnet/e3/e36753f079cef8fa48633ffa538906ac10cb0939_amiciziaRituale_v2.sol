/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-23
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/amiciziaRituale.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;




contract amiciziaRituale_v2 is IERC721Receiver, Ownable {

    /* ========== STATE VARIABLES ========== */

    IERC721 public frenNFT;

    address public rareRewardWallet;
    address public superRareRewardWallet;
    address public specialAndLegendaryRewardWallet;

    uint256 public rareRitualisticCount = 0;
    uint256 public superRareRitualisticCount = 0;
    uint256 public specialAndLegendaryRitualisticCount = 0;
        
    uint256 public rareThreshold = 3; // 3 * (1 - 0.14) ≈ 3
    uint256 public superRareThreshold = 6; // 7 * (1 - 0.14) ≈ 6
    uint256 public specialAndLegendaryThreshold = 42; // 49 * (1-0.14) ≈ 42
    bool public ritualState = false;

    uint256[5] public rarityPoints = [1, 2, 3, 7, 49];
    mapping (uint256 => uint256) public tokenRarity;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _frenNFT) {
        frenNFT = IERC721(_frenNFT);
    }

    /* ========== RESTRICTED ========== */

    function setRitualState(bool _value) public onlyOwner {
        ritualState = _value;
    }

    function setRarity(uint256 _tokenId, uint256 _rarity) public onlyOwner {
        tokenRarity[_tokenId] = _rarity;
    }

    function setBatchRarity(uint256[] memory _tokenIds, uint256 _rarity) public onlyOwner {
        for(uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            tokenRarity[tokenId] = _rarity;
        }
    }

    function setRewardWallets(
        address _rareAddress,
        address _superRareAddress,
        address _specialAndLegendaryAddress
    ) public onlyOwner {
        rareRewardWallet = _rareAddress;
        superRareRewardWallet = _superRareAddress;
        specialAndLegendaryRewardWallet = _specialAndLegendaryAddress;
    }

    function setRitualisticCounts(
        uint256 _rareCount, //first rare tokenId -1
        uint256 _superRareCount, //first superRare tokenId -1
        uint256 _specialAndLegendaryCount //first specialAndLegendary tokenId -1
    ) public onlyOwner {
        rareRitualisticCount = _rareCount;
        superRareRitualisticCount = _superRareCount;
        specialAndLegendaryRitualisticCount = _specialAndLegendaryCount;
    }
    
    function findRewardAddress(uint[] memory tokenIds) internal view returns (address rewardAddress) {
        require (findRarityPoints(tokenIds) >= rareThreshold);
        uint256 points = findRarityPoints(tokenIds);

        if (points >= rareThreshold && points < superRareThreshold) {
            rewardAddress = rareRewardWallet;
        } else if (points >= superRareThreshold && points < specialAndLegendaryThreshold) {
            rewardAddress = superRareRewardWallet;
        } else {
            rewardAddress = specialAndLegendaryRewardWallet;
        }
    }

    /* ========== VIEWS ========== */

    function findRarityPoints(uint[] memory tokenIds) public view returns (uint256 tokensRarityPoints) {
        for (uint256 i; i <  tokenIds.length; i++) {
            uint256 tokenRarityPoint = rarityPoints[tokenRarity[tokenIds[i]]];
            tokensRarityPoints += tokenRarityPoint;
        }
    }

    function whatAmIExpectedToGet(uint[] calldata tokenIds) public view returns (string memory){
        require (findRarityPoints(tokenIds) >= rareThreshold, "You should bring more valuable frens.");
        uint256 points = findRarityPoints(tokenIds);
        return points >= rareThreshold && points < superRareThreshold ? "The ritual could summon a rare fren..."
            : points >= superRareThreshold && points < specialAndLegendaryThreshold ? "The ritual could summon a super rare fren..."
            : "The ritual could summon a special or a legendary fren...";
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function ritual(uint256[] calldata tokenIds) public {
        require(ritualState == true, "There's a time and place for everything, but not now.");
        require (tokenIds.length > 1, "You need at least two friends to show up for the ritual.");

        address rewardAddress = findRewardAddress(tokenIds);
        uint256 ritualisticCount;
        
        if (rewardAddress == rareRewardWallet) {
            rareRitualisticCount++;
            ritualisticCount = rareRitualisticCount;
        } else if (rewardAddress == superRareRewardWallet) {
            superRareRitualisticCount++;
            ritualisticCount = superRareRitualisticCount;
        } else {
            specialAndLegendaryRitualisticCount++;
            ritualisticCount = specialAndLegendaryRitualisticCount;
        }

        for (uint256 i; i < tokenIds.length; i++) {
            frenNFT.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
        frenNFT.transferFrom(rewardAddress, msg.sender, ritualisticCount);
    }

}