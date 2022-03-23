/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-22
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/interfaces/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/interfaces/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


// File contracts/marketplace/NFTSwapOfferManager.sol

// License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract NFTSwapOfferManager {
    enum Status {
        ACTIVE,
        CANCELLED,
        SETTLED
    }

    struct NFTSwapOffer {
        uint256 index;
        uint256 timestamp;
        uint256 tokenId;
        uint256[] tokenIds;
        uint256 expiry;
        uint256 ended;

        address offeree;
        address receiver;

        Status status;
    }
 
    IERC721 public nft;
    uint256 public volume;
    uint256 public nftSwapOfferCounter;

    constructor (address _nft) {
        nft = IERC721(_nft);
    }

    /**
     * Indexers
     */
     
    // offers are one indexed
    mapping(uint256 => uint256[]) public nftSwapOfferIndicesByTokenId;
    mapping(address => uint256[]) public nftSwapOfferIndicesByAddress;
    mapping(uint256 => NFTSwapOffer) private _nftSwapOffersByIndex;  

    // stupid compiler bug/decision doesn't show arrays in structs retrieved from mappings
    function nftSwapOffersByIndex(uint256 _index) external view returns (NFTSwapOffer memory) {
        return _nftSwapOffersByIndex[_index];
    }

    function nftSwapOffersByTokenId(uint256 _tokenId, uint256 _index) external view returns (NFTSwapOffer memory) {
        return _nftSwapOffersByIndex[nftSwapOfferIndicesByTokenId[_tokenId][_index]];
    }

    function nftSwapOffersByAddress(address _address, uint256 _index) external view returns (NFTSwapOffer memory) {
        return _nftSwapOffersByIndex[nftSwapOfferIndicesByAddress[_address][_index]];
    }

    function nftSwapOffersByTokenIdLength(uint256 _tokenId) external view returns (uint256) {
        return nftSwapOfferIndicesByTokenId[_tokenId].length;
    }

    function nftSwapOffersByAddress(address _address) external view returns (uint256) {
        return nftSwapOfferIndicesByAddress[_address].length;
    }

    /**
     * Modifiers
     */
    
    modifier validNFTSwapOffer(NFTSwapOffer memory _nftSwapOffer) {
        require(_nftSwapOffer.offeree != address(0), "NFTSwapOffer: Null address offeree");
        _;
    }

    modifier hasStatus(NFTSwapOffer memory _nftSwapOffer, Status _status) {
        require(_nftSwapOffer.status == _status, "NFTSwapOffer: Incorrect status");
        _;
    }

    modifier notExpired(NFTSwapOffer memory _nftSwapOffer) {
        require(block.timestamp < _nftSwapOffer.expiry, "NFTSwapOffer: Expired");
        _;
    }

    modifier validExpiry(uint256 _expiry) {
        require(block.timestamp < _expiry, "NFTSwapOffer: Invalid expiry");
        _;
    }

    modifier approvedFor(uint256 _tokenId) {
        require(nft.getApproved(_tokenId) == address(this), "NFTSwapOffer: TokenID not approved");
        _;
    }

    /**
     * Internal
     */

    function _settleNFTSwapOffer(
        NFTSwapOffer memory _nftSwapOffer,
        address _receiver) internal
        validNFTSwapOffer(_nftSwapOffer)
        hasStatus(_nftSwapOffer, Status.ACTIVE)
        notExpired(_nftSwapOffer)
        approvedFor(_nftSwapOffer.tokenId)
    {
        uint256 _index = _nftSwapOffer.index;
        _nftSwapOffersByIndex[_index].status = Status.SETTLED;
        _nftSwapOffersByIndex[_index].receiver = _receiver;
        _nftSwapOffersByIndex[_index].ended = block.timestamp;

        uint256[] memory _tokenIds = _nftSwapOffer.tokenIds; 
        uint256 _tokenIdsLength = _tokenIds.length;
        volume += _tokenIdsLength;

        emit NFTSwapOfferSettled(_index, _nftSwapOffer.tokenId, _nftSwapOffer.offeree, _nftSwapOffer.tokenIds, _receiver);

        for (uint i = 0; i < _tokenIdsLength; i++) {
            nft.safeTransferFrom(address(this), _receiver, _tokenIds[i]);
        }

        nft.safeTransferFrom(_receiver, _nftSwapOffer.offeree, _nftSwapOffer.tokenId);
    }

    function _cancelNFTSwapOffer(
        NFTSwapOffer memory _nftSwapOffer,
        address _sender) internal
        validNFTSwapOffer(_nftSwapOffer)
        hasStatus(_nftSwapOffer, Status.ACTIVE)
    {
        require(_sender == _nftSwapOffer.offeree, "NFTSwapOffer: Only offeree");

        uint256 _index = _nftSwapOffer.index;
        _nftSwapOffersByIndex[_index].status = Status.CANCELLED;
        _nftSwapOffersByIndex[_index].ended = block.timestamp;

        emit NFTSwapOfferCancelled(_index, _nftSwapOffer.tokenId, _nftSwapOffer.offeree, _nftSwapOffer.tokenIds);

        uint256[] memory _tokenIds = _nftSwapOffer.tokenIds;
        uint256 _tokenIdsLength = _tokenIds.length;

        for (uint i = 0; i < _tokenIdsLength; i++) {
            nft.safeTransferFrom(address(this), _nftSwapOffer.offeree, _tokenIds[i]);
        }
    }

    /**
     * Offering
     */
    
    function createNFTSwapOffer(
        uint256 _tokenId,
        uint256[] memory _tokenIds,
        uint256 _expiry) external
        validExpiry(_expiry)
    {
        nftSwapOfferCounter++;

        NFTSwapOffer memory _nftSwapOffer = NFTSwapOffer(
            nftSwapOfferCounter,
            block.timestamp,
            _tokenId,
            _tokenIds,
            _expiry,
            0,
            msg.sender,
            address(0),
            Status.ACTIVE
        );

        _nftSwapOffersByIndex[nftSwapOfferCounter] = _nftSwapOffer;
        nftSwapOfferIndicesByTokenId[_tokenId].push(nftSwapOfferCounter);
        nftSwapOfferIndicesByAddress[msg.sender].push(nftSwapOfferCounter);

        emit NewNFTSwapOffer(nftSwapOfferCounter, _tokenId, msg.sender, _tokenIds, _expiry);

        for (uint i = 0; i < _tokenIds.length; i++) {
            require(nft.getApproved(_tokenIds[i]) == address(this), "NFTSwapOffer: TokenID not approved");
            nft.transferFrom(msg.sender, address(this), _tokenIds[i]);
        }
    }

    /**
     * Settlement
     */
    
    function settleNFTSwapOffer(uint256 _nftSwapOfferIndex) external {
        NFTSwapOffer memory _nftSwapOffer = _nftSwapOffersByIndex[_nftSwapOfferIndex];
        _settleNFTSwapOffer(_nftSwapOffer, msg.sender);
    }

    function cancelNFTSwapOffer(uint256 _offerIndex) external {
        NFTSwapOffer memory _nftSwapOffer = _nftSwapOffersByIndex[_offerIndex];
        _cancelNFTSwapOffer(_nftSwapOffer, msg.sender);
    }

    event NFTSwapOfferCancelled(uint256 indexed index, uint256 indexed tokenId, address indexed offeree, uint256[] tokenIds);
    event NFTSwapOfferSettled(uint256 indexed index, uint256 indexed tokenId, address offeree, uint256[] tokenIds, address indexed receiver);
    event NewNFTSwapOffer(uint256 indexed index, uint256 indexed tokenId, address indexed offeree, uint256[] tokenIds, uint256 expiry);
}