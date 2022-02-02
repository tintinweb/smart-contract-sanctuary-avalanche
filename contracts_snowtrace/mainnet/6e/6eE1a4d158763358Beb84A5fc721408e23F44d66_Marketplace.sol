/**
 *Submitted for verification at snowtrace.io on 2022-02-02
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// Written by: Ochoa Juan 
// Telegram: https://t.me/manu_8a

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

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

// File: newMarket.sol



pragma solidity ^0.8.0;





interface dividenToken {
    function distributeDividends() external payable;
}

contract Marketplace is Ownable, ReentrancyGuard, ERC721Holder {
    IERC721 public EarthNFT;
    address dividendTracker;
   
    uint256 public orders;    
    uint256 public itemsSold;
    uint256 public collectedFees;    
    uint256 public marketFee = 500; // 5% market fee to $1EARTH holders.

    struct Order {        
        address seller;
        uint256 tokenId;
        uint256 createdAt;
        uint256 price;        
    }  

    struct Bid {
        address bidder;
        uint256 price;
        uint256 timestamp;
    }    
    
    mapping(uint256 => Order) public orderByTokenId;    
    mapping(address => uint256[]) public ordersBySeller;
    mapping(uint256 => uint256) public ordersIndex;     
    mapping(uint256 => Bid) public bidByTokenId;     

    event OrderCreated(address indexed seller,uint256 tokenId,uint256 createdAt,uint256 priceInWei);
    event OrderUpdated(uint256 tokenId,uint256 priceInWei);    
    event OrderSuccessful(uint256 tokenId,address indexed buyer,uint256 priceInWei);
    event OrderCancelled(uint256 tokenId,address user);
    event bidReceived(uint256 tokenId,uint256 amount,address bidder,uint256 timestamp);
    event bidAccepted(uint256 tokenId,address indexed buyer,uint256 priceInWei);
    event bidCancelled(uint256 tokenId,address user);

    constructor(address _earthNFT, address _dividendTracker)  {      
        EarthNFT = IERC721(_earthNFT);
        dividendTracker = _dividendTracker;
    }

    function createOrder(uint256 _tokenId, uint256 _priceInWei) external {
        require(_priceInWei > 0, "Marketplace: Price should be bigger than 0");     

        orderByTokenId[_tokenId] = Order({           
            seller: msg.sender,           
            tokenId: _tokenId,
            createdAt: block.timestamp,
            price: _priceInWei          
        });     

        ordersIndex[_tokenId] = ordersBySeller[msg.sender].length;
        ordersBySeller[msg.sender].push(_tokenId);  

        EarthNFT.safeTransferFrom(msg.sender, address(this), _tokenId);      

        orders++;

        emit OrderCreated(msg.sender, _tokenId, block.timestamp, _priceInWei);
    }

    function cancelOrder(uint256 _tokenId) external {
        (address seller,,) = getOrderDetails(_tokenId);

        require(seller == msg.sender || msg.sender == owner(), "Marketplace: unauthorized sender");

        removeOrder(seller, _tokenId);
       
        EarthNFT.safeTransferFrom(address(this), seller, _tokenId);

        emit OrderCancelled(_tokenId, seller);
    }

    function updateOrder(uint256 _tokenId, uint256 _priceInWei) external {            
        require(orderByTokenId[_tokenId].seller == msg.sender, "Marketplace: sender not allowed");
        require(_priceInWei > 0, "Marketplace: Price should be bigger than 0");

        orderByTokenId[_tokenId].price = _priceInWei;        

        emit OrderUpdated(_tokenId, _priceInWei);
    }

    function executeOrder(uint256 _tokenId) external payable nonReentrant{
        (address seller,uint256 price,) = getOrderDetails(_tokenId);        
        
        require(msg.value == price, "Marketplace: Invalid paid value");

        uint256 fee = 0;

        if (marketFee > 0) {
            fee = (price * marketFee) / 10000;   
            collectedFees += fee;         
        }

        if (bidByTokenId[_tokenId].price > 0){
            _refundBid(bidByTokenId[_tokenId].bidder, bidByTokenId[_tokenId].price, _tokenId);
        }

        _executeOrder(_tokenId, msg.sender, seller, price - fee, fee);       
                              
        emit OrderSuccessful(_tokenId, msg.sender, price);
    }

    function placeBid(uint256 _tokenId) external payable nonReentrant{
        (address bidder,uint256 price,) = getBidDetails(_tokenId);
        
        require(price < msg.value, "Marketplace: Bid needs to be bigger than current bid");

        if(price > 0){
            _refundBid(bidder, price, _tokenId);            
        }

        bidByTokenId[_tokenId] = Bid({
            bidder: msg.sender,
            price: msg.value,
            timestamp: block.timestamp
        });

        emit bidReceived(_tokenId, msg.value, msg.sender, block.timestamp);
    }

    function cancelBid(uint256 _tokenId) external nonReentrant{
        (address bidder,uint256 price,) = getBidDetails(_tokenId);

        require(bidder == msg.sender, "Marketplace: Only bidder can cancel the bid");

        _refundBid(bidder, price, _tokenId);          
    }

    function acceptBid(uint256 _tokenId) external nonReentrant{
        (address bidder,uint256 price,) = getBidDetails(_tokenId);

        require(price > 0, "Marketplace: No bids for this item");
        require(msg.sender == orderByTokenId[_tokenId].seller, "Marketplace: Only seller can accept bid");

        uint256 fee = 0;

        if (marketFee > 0) {
            fee = (price * marketFee) / 10000;   
            collectedFees += fee;         
        }

        _executeOrder(_tokenId, bidder, msg.sender, price - fee, fee);    
        
        delete bidByTokenId[_tokenId];

        emit bidAccepted(_tokenId, msg.sender, price);
    }

    function _executeOrder(uint256 tokenId, address buyer, address seller, uint256 price, uint256 fee) internal {
        EarthNFT.safeTransferFrom(address(this), buyer, tokenId);

        payable(seller).transfer(price- fee);
      
        dividenToken(dividendTracker).distributeDividends{value:fee}();

        removeOrder(seller, tokenId);

        itemsSold++;
    }

    function _refundBid(address bidder, uint256 price, uint256 _tokenId) internal {
        delete bidByTokenId[_tokenId]; 

        payable(bidder).transfer(price);

        emit bidCancelled(_tokenId, bidder);
    }

    function removeOrder(address seller, uint256 _tokenId) internal {
        uint256 lastTokenId = ordersBySeller[seller][ordersBySeller[seller].length - 1];

        ordersBySeller[seller][ordersIndex[_tokenId]] = lastTokenId;

        ordersIndex[lastTokenId] = ordersIndex[_tokenId];

        ordersBySeller[seller].pop();

        delete orderByTokenId[_tokenId];        
    }

    function getOrderDetails(uint256 tokenId) public view returns (address seller,uint256 price,uint256 createdAt){
        seller = orderByTokenId[tokenId].seller;        
        price = orderByTokenId[tokenId].price;
        createdAt = orderByTokenId[tokenId].createdAt;
    }

    function getBidDetails(uint256 tokenId) public view returns (address bidder,uint256 price,uint256 timestamp){
        bidder = bidByTokenId[tokenId].bidder;        
        price = bidByTokenId[tokenId].price;
        timestamp = bidByTokenId[tokenId].timestamp;
    }    

    function getTokensIds(address _sellerAddress)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ordersCount = ordersBySeller[_sellerAddress].length;

        uint256[] memory tokensIds = new uint256[](ordersCount);
        for (uint256 i = 0; i < ordersCount; i++) {
            tokensIds[i] = ordersBySeller[_sellerAddress][i];
        }

        return tokensIds;
    }    

    function setMarketFee(uint256 _marketFee) external onlyOwner {
        marketFee = _marketFee;
    }

    function changeDividendContract (address _dividendTracker) external onlyOwner {
        require(_dividendTracker != address(0), "Need to set a valid address");

        dividendTracker = _dividendTracker;
    }
}