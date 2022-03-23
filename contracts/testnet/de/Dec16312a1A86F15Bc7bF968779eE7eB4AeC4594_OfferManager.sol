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


// File contracts/marketplace/OfferManager.sol

// License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract OfferManager {
    enum Status {
        ACTIVE,
        CANCELLED,
        SETTLED
    }

    struct Offer {
        uint256 index;
        uint256 timestamp;
        uint256 tokenId;
        uint256 offerAmount;
        uint256 offerFee;
        uint256 expiry;
        uint256 ended;

        address offeree;
        address receiver;
        address royaltyReceiver;

        Status status;
    }
 
    IERC721 public nft;
    uint256 public volume;
    uint256 public offerCounter;

    constructor (address _nft) {
        nft = IERC721(_nft);
    }

    /**
     * Indexers
     */
    
    // offers are one indexed
    mapping(uint256 => Offer) public offersByIndex;
    mapping(uint256 => uint256[]) public offerIndicesByTokenId;
    mapping(address => uint256[]) public offerIndicesByAddress;

    function offersByTokenId(uint256 _tokenId, uint256 _index) external view returns (Offer memory) {
        return offersByIndex[offerIndicesByTokenId[_tokenId][_index]];
    }

    function offersByAddress(address _address, uint256 _index) external view returns (Offer memory) {
        return offersByIndex[offerIndicesByAddress[_address][_index]];
    }

    function offersByTokenIdLength(uint256 _tokenId) external view returns (uint256) {
        return offerIndicesByTokenId[_tokenId].length;
    }

    function offersByAddress(address _address) external view returns (uint256) {
        return offerIndicesByAddress[_address].length;
    }

    /**
     * Modifiers
     */
    
    modifier validOffer(Offer memory _offer) {
        require(_offer.offeree != address(0), "Offer: Null address offeree");
        _;
    }

    modifier hasStatus(Offer memory _offer, Status _status) {
        require(_offer.status == _status, "Offer: Incorrect status");
        _;
    }

    modifier notExpired(Offer memory _offer) {
        require(block.timestamp < _offer.expiry, "Offer: Expired");
        _;
    }

    modifier validExpiry(uint256 _expiry) {
        require(block.timestamp < _expiry, "Offer: Invalid expiry");
        _;
    }

    modifier approvedFor(uint256 _tokenId) {
        require(nft.getApproved(_tokenId) == address(this), "Offer: TokenID not approved");
        _;
    }

    /**
     * Internal
     */

    function _settleOffer(
        Offer memory _offer,
        address _receiver) internal
        validOffer(_offer)
        hasStatus(_offer, Status.ACTIVE)
        notExpired(_offer)
        approvedFor(_offer.tokenId)
    {
        uint256 _index = _offer.index;
        offersByIndex[_index].status = Status.SETTLED;
        offersByIndex[_index].receiver = _receiver;
        offersByIndex[_index].ended = block.timestamp;
        volume += _offer.offerAmount;

        emit OfferSettled(_index, _offer.tokenId, _offer.offeree, _offer.offerAmount, _receiver);

        nft.safeTransferFrom(_receiver, _offer.offeree, _offer.tokenId);
        (bool sentReceiver,) = payable(_receiver).call{value: _offer.offerAmount}("");
        require(sentReceiver, "Offer: Could not send receiver offerAmount");
        (bool sentRoyaltyReceiver,) = payable(_offer.royaltyReceiver).call{value: _offer.offerFee}("");
        require(sentRoyaltyReceiver, "Offer: Could not send royaltyReceiver offerFee");
    }

    function _cancelOffer(
        Offer memory _offer,
        address _sender) internal
        validOffer(_offer)
        hasStatus(_offer, Status.ACTIVE)
    {
        require(_sender == _offer.offeree, "Offer: only offeree");

        uint256 _index = _offer.index;
        offersByIndex[_index].status = Status.CANCELLED;
        offersByIndex[_index].ended = block.timestamp;

        emit OfferCancelled(_index, _offer.tokenId, _offer.offeree, _offer.offerAmount);

        (bool sentOfferee,) = payable(_offer.offeree).call{value: _offer.offerAmount + _offer.offerFee}("");
        require(sentOfferee, "Offer: Could not send offeree offerAmount + offerFee");
    }

    /**
     * Offering
     */
    
    function createOffer(
        uint256 _tokenId, 
        uint256 _offerAmount, 
        uint256 _expiry) external payable
        validExpiry(_expiry)
    {
        offerCounter++;
        (address _royaltyReceiver, uint256 _offerFee) = getOfferFee(_offerAmount, _tokenId);
        require(msg.value == _offerAmount + _offerFee, "Offer: Invalid fee");

        Offer memory _offer = Offer(
            offerCounter,
            block.timestamp,
            _tokenId,
            _offerAmount,
            _offerFee,
            _expiry,
            0,
            msg.sender,
            address(0),
            _royaltyReceiver,
            Status.ACTIVE
        );

        offersByIndex[offerCounter] = _offer;
        offerIndicesByTokenId[_tokenId].push(offerCounter);
        offerIndicesByAddress[msg.sender].push(offerCounter);

        emit NewOffer(offerCounter, _tokenId, msg.sender, _offerAmount, _expiry);
    }

    /**
     * Settlement
     */
    
    function settleOffer(uint256 _offerIndex) external {
        Offer memory _offer = offersByIndex[_offerIndex];
        _settleOffer(_offer, msg.sender);
    }

    function cancelOffer(uint256 _offerIndex) external {
        Offer memory _offer = offersByIndex[_offerIndex];
        _cancelOffer(_offer, msg.sender);
    }

    /**
     * View
     */

    function getOfferFee(uint256 _offerAmount, uint256 _tokenId) public view returns(address _royaltyReceiver, uint256 _offerFee) {
        uint256 royaltyAmount;
        (_royaltyReceiver, royaltyAmount) = IERC2981(address(nft)).royaltyInfo(_tokenId, _offerAmount);
        _offerFee = (_offerAmount * royaltyAmount) / 10000;  // 1 is 0.01 precent 
    }

    event OfferCancelled(uint256 indexed index, uint256 indexed tokenId, address indexed offeree, uint256 offerAmount);
    event OfferSettled(uint256 indexed index, uint256 indexed tokenId, address offeree, uint256 offerAmount, address indexed receiver);
    event NewOffer(uint256 indexed index, uint256 indexed tokenId, address indexed offeree, uint256 offerAmount, uint256 expiry);
}