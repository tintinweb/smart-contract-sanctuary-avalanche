/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-15
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// License-Identifier: MIT
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


// File contracts/marketplace/NFTSwap.sol

// License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract NFTSwap is IERC721Receiver {
    IERC721 public nft;
    address public buyer;
    uint256 public tokenIdOffer;
    mapping(uint256 => bool) public tokenIdAccept;

    bool public isFinished = false;
    
    uint256[] private _tokenIdAcceptArray;

    constructor (address _nft, address _buyer, uint256 _tokenIdOffer, uint256[] memory _tokenIdsAccept) {
        nft = IERC721(_nft);
        buyer = _buyer;
        tokenIdOffer = _tokenIdOffer;
        _tokenIdAcceptArray = _tokenIdsAccept;
        for (uint256 i = 0; i < _tokenIdsAccept.length; i++) {
            tokenIdAccept[_tokenIdsAccept[i]] = true;
        }
    }
    
    function cancelNFTSwap() external {
        require(!isFinished, "NFTSwap: Swap finished");
        require(msg.sender == buyer, "NFTSwap: Only buyer can cancel swap");

        isFinished = true;
        nft.safeTransferFrom(address(this), buyer, tokenIdOffer);

        emit NFTSwapCancelled();
    }

    function settleNFTSwap(uint256 tokenIdSettle) external {
        require(!isFinished, "NFTSwap: Swap finished");
        require(nft.getApproved(tokenIdSettle) == address(this), "NFTSwap: TokenID not approved");
        require(tokenIdAccept[tokenIdSettle], "NFTSwap: TokenID not accepted");

        isFinished = true;
        address nftOwnerSettle = nft.ownerOf(tokenIdSettle);

        // buyer (creator of contract) gets tokenIdSettle
        nft.safeTransferFrom(nftOwnerSettle, buyer, tokenIdSettle);

        // caller (seller) gets tokenIdOffer (nft in this contract)
        nft.safeTransferFrom(address(this), nftOwnerSettle, tokenIdOffer);
        emit NFTSwapSettled(nftOwnerSettle);
    }

    function tokenIdAcceptArray() external view returns (uint256[] memory) {
        return _tokenIdAcceptArray;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    event NFTSwapCancelled();
    event NFTSwapSettled(address seller);

}


// File contracts/marketplace/NFTSwapManager.sol

// License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract NFTSwapManager {
    struct NFTSwapMetadata {
        NFTSwap nftSwap;
        uint256 timestamp;
        uint256 blocknumber;
    }

    IERC721 public nft;
    uint256 public nftSwapCounter = 0;
    mapping (uint256 => NFTSwapMetadata) public nftSwaps;
    mapping (uint256 => NFTSwapMetadata[]) private _tokenIdToNftSwaps;
    mapping (address => NFTSwapMetadata[]) private _addressToNftSwaps;

    constructor (address _nft) {
        nft = IERC721(_nft);
    }

    function createNftSwap(uint256 tokenIdOffer, uint256[] calldata tokenIdsAccept) external {
        require(nft.getApproved(tokenIdOffer) == address(this), "NFTSwapManager: Token ID not approved");
        nftSwapCounter++;

        address nftOwner = nft.ownerOf(tokenIdOffer);

        // create nft swap contract
        NFTSwap nftSwap = new NFTSwap(address(nft), nftOwner, tokenIdOffer, tokenIdsAccept);
        NFTSwapMetadata memory metadata = _NFTSwapMetadata(nftSwap);

        nftSwaps[nftSwapCounter] = metadata;  // index by nftSwapCounter
        _tokenIdToNftSwaps[tokenIdOffer].push(metadata);  // index by token id
        _addressToNftSwaps[msg.sender].push(metadata);  // index by address of sender

        nft.safeTransferFrom(nftOwner, address(nftSwap), tokenIdOffer);
        
        emit NewNFTSwap(tokenIdOffer, tokenIdsAccept);
    }

    function _NFTSwapMetadata(NFTSwap _nftSwap) internal view returns(NFTSwapMetadata memory metadata) {
        metadata = NFTSwapMetadata(_nftSwap, block.timestamp, block.number);
    }

    // convinience functions because by default ethers and web3 don't handle mappings to arrays correctly
    
    function tokenIdToNftSwaps(uint256 tokenId) external view returns(NFTSwapMetadata[] memory) {
        return _tokenIdToNftSwaps[tokenId];
    }

    function addressToNftSwaps(address addr) external view returns(NFTSwapMetadata[] memory) {
        return _addressToNftSwaps[addr];
    }

    event NewNFTSwap(uint256 tokenIdOffer, uint256[] tokenIdsAccept);
}


// File contracts/marketplace/Offer.sol

// License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Offer {
    IERC721 public nft;
    address public buyer;
    address public royaltyReceiver;
    uint256 public tokenId;
    uint256 public offerAmount;

    bool public isFinished = false;

    constructor (uint256 _offerAmount, uint256 _tokenId, address _royaltyReceiver, address _buyer, address _nftAddress) {
        offerAmount = _offerAmount;
        tokenId = _tokenId;
        royaltyReceiver = _royaltyReceiver;
        buyer = _buyer;
        nft = IERC721(_nftAddress);
    }

    function cancelOffer() external {
        require(!isFinished, "Offer: Offer already ended");
        require(msg.sender == buyer, "Offer: Only buyer can cancel offer");

        isFinished = true;
        (bool sent,) = payable(buyer).call{value: address(this).balance}(""); // return funds to buyer
        require(sent, "Offer: Could not refund buyer");
        
        emit OfferCanceled();
    }

    function settleOffer() external {
        require(!isFinished, "Offer: Offer already ended");
        require(nft.getApproved(tokenId) == address(this), "Offer: TokenID not approved");

        isFinished = true;
        address nftOwner = nft.ownerOf(tokenId);
        uint256 royaltyFees = address(this).balance - offerAmount;

        nft.safeTransferFrom(nftOwner, buyer, tokenId);
        (bool sentSeller,) = payable(nftOwner).call{value: offerAmount}("");
        require(sentSeller, "Offer: Could not settle offer (could not send money to seller)");
        (bool sentRoyalty,) = payable(royaltyReceiver).call{value: royaltyFees}("");
        require(sentRoyalty, "Offer: Could not settle (could not send money to royalty reciever)");

        emit OfferSettled(nftOwner);
    }
    
    receive() external payable {}
    event OfferCanceled();
    event OfferSettled(address seller);
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
    struct OfferMetadata {
        Offer offer;
        uint256 timestamp;
        uint256 blockNumber;
    }

    uint256 public offerCounter = 0;
    address public nftAddress;
    mapping (uint256 => OfferMetadata) public offers;
    mapping (uint256 => OfferMetadata[]) private _tokenIdToOffers;
    mapping (address => OfferMetadata[]) private _addressToOffers;

    constructor (address _nftAddress) {
        nftAddress = _nftAddress;
    }

    function createOffer(uint256 offerAmount, uint256 tokenId) external payable {
        // validate message value
        require(msg.value > 0, "OfferManager: Offer must have value");
        (address royaltyReceiver, uint256 offerFee) = getOfferFee(offerAmount, tokenId);
        require(msg.value == offerAmount + offerFee, "OfferManager: Message value doesn't match offerAmount + fees");
        offerCounter++;

        Offer offer = new Offer(offerAmount, tokenId, royaltyReceiver, msg.sender, nftAddress);  // create offer contract
        OfferMetadata memory metadata = _offerMetadata(offer);

        offers[offerCounter] = metadata;  // index contract by offer id
        _tokenIdToOffers[tokenId].push(metadata); // index contract by token id
        _addressToOffers[msg.sender].push(metadata);  // index offer by address of buyer

        (bool sent,) = payable(address(offer)).call{value: msg.value}("");  // fund offer contract
        require(sent, "OfferManager: Could not send value to offer contract");
        
        emit NewOffer(offerCounter, tokenId, address(offer), msg.sender);   
    }

    // people who create offers must pay the royalty fee for transaction
    function getOfferFee(uint256 offerAmount, uint256 tokenId) public view returns(address royaltyReceiver, uint256 offerFee) {
        uint256 royaltyAmount;
        (royaltyReceiver, royaltyAmount) = IERC2981(nftAddress).royaltyInfo(tokenId, offerAmount);
        offerFee = (offerAmount * royaltyAmount) / 10000;  // 1 is 0.01 precent 
    }

    function _offerMetadata(Offer offer) internal view returns(OfferMetadata memory metadata) {
        metadata = OfferMetadata(offer, block.timestamp, block.number);
    }

    // convinience functions because by default ethers and web3 don't handle mappings to arrays correctly

    function tokenIdToOffers(uint256 tokenId) external view returns(OfferMetadata[] memory) {
        return _tokenIdToOffers[tokenId];
    }

    function addressToOffers(address addr) external view returns(OfferMetadata[] memory) {
        return _addressToOffers[addr];
    }

    event NewOffer(uint256 index, uint256 tokenId, address offer, address buyer);
}


// File contracts/marketplace/MarketplaceManager.sol

// License-Identifier: GPL-3.0
pragma solidity ^0.8.0;



// mostly an indexer contract
contract MarketplaceManager is Ownable {
    NFTSwapManager[] public nftSwapManagers;
    OfferManager[] public offerManagers;

    mapping (address => address) public nftToNFTSwapManagers;
    mapping (address => address) public nftToOfferManagers;

    function createNFTSwapManager(address nft) external onlyOwner {
        require(nftToNFTSwapManagers[nft] == address(0), "MarketplaceManager: NFTSwapManager for said NFT already exists");

        NFTSwapManager newNFTSwapManager = new NFTSwapManager(nft);
        nftSwapManagers.push(newNFTSwapManager);
        nftToNFTSwapManagers[nft] = address(newNFTSwapManager);

        emit NewNFTSwapManager(nftSwapManagers.length - 1, nft);
    }

    function createOfferManager(address nft) external onlyOwner {
        require(nftToOfferManagers[nft] == address(0), "MarketplaceManager: OfferManager for said NFT already exists");

        OfferManager newOfferManager = new OfferManager(nft);
        offerManagers.push(newOfferManager);
        nftToOfferManagers[nft] = address(newOfferManager);

        emit NewOfferManager(offerManagers.length - 1, nft);
    }

    event NewNFTSwapManager(uint256 index, address nft);
    event NewOfferManager(uint256 index, address nft);
}