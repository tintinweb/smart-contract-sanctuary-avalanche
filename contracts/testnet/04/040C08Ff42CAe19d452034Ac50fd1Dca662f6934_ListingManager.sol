/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-17
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


// File contracts/marketplace/ListingManager.sol

// License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract ListingManager {
    enum Status {
        ACTIVE,
        CANCELLED,
        SETTLED
    }

    struct Listing {
        uint256 index;
        uint256 tokenId;
        uint256 listingAmount;
        uint256 listingFee;
        uint256 expiry;
        uint256 ended;

        address lister;
        address buyer;
        address royaltyReceiver;

        Status status;
    }

    IERC721 public nft;
    uint256 public volume;
    uint256 public listingCounter;

    constructor (address _nft) {
        nft = IERC721(_nft);
    }

    /**
     * Indexers
     */

    // listings are one indexed
    mapping (uint256 => Listing) public listingsByIndex;
    mapping (uint256 => uint256[]) public listingIndicesByTokenId;
    mapping (address => uint256[]) public listingIndicesByAddress;

    function listingsByTokenId(uint256 _tokenId, uint256 _index) external view returns(Listing memory) {
        return listingsByIndex[listingIndicesByTokenId[_tokenId][_index]];
    }

    function listingsByAddress(address _address, uint256 _index) external view returns(Listing memory) {
        return listingsByIndex[listingIndicesByAddress[_address][_index]];
    }

    function listingsByTokenIdLength(uint256 _tokenId) external view returns(uint256) {
        return listingIndicesByTokenId[_tokenId].length;
    }

    function listingsByAddressLength(address _address) external view returns(uint256) {
        return listingIndicesByAddress[_address].length;
    }

    /**
     * Modifiers
     */
    
    modifier validListing(Listing memory _listing) {
        require(_listing.lister != address(0), "Listing: Null address lister");
        _;
    }

    modifier hasStatus(Listing memory _listing, Status _status) {
        require(_listing.status == _status, "Listing: Incorrect status");
        _;
    }

    modifier notExpired(Listing memory _listing) {
        require(block.timestamp < _listing.expiry, "Listing: Expired");
        _;
    }

    modifier validExpiry(uint256 _expiry) {
        require(block.timestamp < _expiry, "Listing: Invalid expiry");
        _;
    }

    modifier approvedFor(uint256 _tokenId) {
        require(nft.getApproved(_tokenId) == address(this), "Listing: TokenID not approved");
        _;
    }

    /**
     * Internal
     */
    
    function _settleListing(
        Listing memory _listing,
        address _buyer, 
        uint256 _messageValue) internal
        validListing(_listing)
        hasStatus(_listing, Status.ACTIVE)
        notExpired(_listing)        
    {
        require(_messageValue == _listing.listingAmount + _listing.listingFee, "Listing: Message value is not listingAmount + listingFee");

        uint256 _index = _listing.index;
        listingsByIndex[_index].status = Status.SETTLED;
        listingsByIndex[_index].buyer = _buyer;
        listingsByIndex[_index].ended = block.timestamp;
        volume += _listing.listingAmount;

        emit ListingSettled(_index, _listing.tokenId, _listing.lister, _listing.listingAmount, _buyer);

        nft.safeTransferFrom(address(this), _buyer, _listing.tokenId);
        (bool sentLister,) = payable(_listing.lister).call{value: _listing.listingAmount}("");
        require(sentLister, "Listing: Could not send lister listingAmount");
        (bool sentRoyaltyReceiver,) = payable(_listing.royaltyReceiver).call{value: _listing.listingFee}("");
        require(sentRoyaltyReceiver, "Listing: Could not send royaltyReceiver listingFee");
    }

    function _cancelListing(
        Listing memory _listing,
        address _sender) internal
        validListing(_listing)
        hasStatus(_listing, Status.ACTIVE) 
    {
        require(_sender == _listing.lister, "Listing: Only lister");

        uint256 _index = _listing.index;
        listingsByIndex[_index].status = Status.CANCELLED;
        listingsByIndex[_index].ended = block.timestamp;

        emit ListingCancelled(_index, _listing.tokenId, _listing.lister, _listing.listingAmount);

        nft.safeTransferFrom(address(this), _listing.lister, _listing.tokenId);
    }

    /**
     * Listing
     */
    
    function createListing(
        uint256 _tokenId, 
        uint256 _listingAmount, 
        uint256 _expiry) external
        validExpiry(_expiry)
        approvedFor(_tokenId) 
    {
        listingCounter++;
        (address _royaltyReceiver, uint256 _listingFee) = getListingFee(_listingAmount, _tokenId);
        address _lister = nft.ownerOf(_tokenId);

        Listing memory _listing = Listing(
            listingCounter,
            _tokenId,
            _listingAmount,
            _listingFee,
            _expiry,
            0,
            _lister,
            address(0),
            _royaltyReceiver,
            Status.ACTIVE
        );

        listingsByIndex[listingCounter] = _listing;
        listingIndicesByTokenId[_tokenId].push(listingCounter);
        listingIndicesByAddress[_lister].push(listingCounter);

        emit NewListing(listingCounter, _tokenId, _lister, _listingAmount, _expiry);

        nft.transferFrom(_lister, address(this), _tokenId); 
    }

    /**
     * Settlement
     */
    
    function settleListing(uint256 _listingIndex) external payable {
        Listing memory _listing = listingsByIndex[_listingIndex];
        _settleListing(_listing, msg.sender, msg.value);
    }

    function cancelListing(uint256 _listingIndex) external {
        Listing memory _listing = listingsByIndex[_listingIndex];
        _cancelListing(_listing, msg.sender);
    }

    /**
     * View
     */
    
    function getListingFee(uint256 _listingAmount, uint256 _tokenId) public view returns(address _royaltyReceiver, uint256 _listingFee) {
        uint256 royaltyAmount;
        (_royaltyReceiver, royaltyAmount) = IERC2981(address(nft)).royaltyInfo(_tokenId, _listingAmount);
        _listingFee = (_listingAmount * royaltyAmount) / 10000;  // 1 is 0.01 precent 
    }

    event ListingCancelled(uint256 index, uint256 tokenId, address lister, uint256 listingAmount);
    event ListingSettled(uint256 index, uint256 tokenId, address lister, uint256 listingAmount, address buyer);
    event NewListing(uint256 index, uint256 tokenId, address lister, uint256 listingAmount, uint256 expiry);
}