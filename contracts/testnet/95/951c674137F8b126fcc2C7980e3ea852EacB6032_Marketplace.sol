/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Marketplace is Ownable {
    IERC20 public baseToken;

    struct Order {
        uint256 id;
        address maker;
        address taker;
        address reserved;
        IERC721 nftContract;
        uint256 tokenId;
        uint256 askPrice;
        uint256 listingTime;
        uint256 expirationTime;
        bytes32 orderHash;
    }
    
    Order[] private order;

    mapping(IERC721 => bool) public approvedNFT;

    address private feeRecipient;
    uint256 private fee;
    uint256 private immutable denominator = 1000;

    event OrderCreated(uint256 orderId, IERC721 nftContract, uint256 tokenId, uint256 askPrice, uint256 expirationTime);
    event TradeExecuted(uint256 orderId, address taker);
    event OrderCancelled(uint256 orderId);


    constructor() {
        // init
        order.push(Order({
            id: 0,
            maker: address(0),
            taker: address(0),
            reserved: address(0),
            nftContract: IERC721(address(0)),
            tokenId: 0,
            askPrice: 0,
            listingTime: 0,
            expirationTime: 0,
            orderHash: 0
        }));
    }

    /// @dev View Functions

    function getExistingOrderId(IERC721 _nftContract, uint256 _tokenId) public view returns (uint256 orderId) {
        for (uint256 i; i < order.length; i++) {
            if (order[i].nftContract == _nftContract && order[i].tokenId == _tokenId && order[i].expirationTime >= block.timestamp && order[i].taker == address(0)) {
                orderId = order[i].id;
            }
        }
    }

    function getExistingOrdersByNFTContract(IERC721 _nftContract) external view returns (uint256[] memory orderIds) {
        uint256 counter;
        for (uint256 i; i < order.length; i++) {
            if (order[i].nftContract == _nftContract && order[i].expirationTime >= block.timestamp && order[i].taker == address(0)) {
                counter ++;
            }
        }
        orderIds = new uint256[](counter);
        uint256 counter2;
        for (uint256 x; x < order.length; x++) {
            if (order[x].nftContract == _nftContract && order[x].expirationTime >= block.timestamp && order[x].taker == address(0)) {
                orderIds[counter2] = x;
                counter2 ++;
            }
        }
    }

    function getOrderInfo(uint256 orderId) external view returns (address maker, address taker, address reserved, IERC721 nftContract, uint256 tokenId, uint256 askPrice, uint256 listingTime, uint256 expirationTime) {
        Order memory _order = order[orderId];
        return(
            _order.maker,
            _order.taker,
            _order.reserved,
            _order.nftContract,
            _order.tokenId,
            _order.askPrice,
            _order.listingTime,
            _order.expirationTime
        );
    }

    /// @dev Public Functions

    function placeOrder(IERC721 _nftContract, uint256 _tokenId, uint256 _length, uint256 _askPrice, address _reserved) external {
        uint256 _expirationTime = _placeOrder(_msgSender(), _nftContract, _tokenId, _length, _reserved, _askPrice);
        emit OrderCreated(order.length - 1, _nftContract, _tokenId, _askPrice, _expirationTime);
    }

    function placeMultipleOrders(IERC721[] calldata _nftContracts, uint256[] calldata _tokenIds, uint256[] calldata _lengths, uint256[] calldata _askPrices, address[] calldata _reserves) external {
        require(_nftContracts.length == _tokenIds.length && _nftContracts.length == _lengths.length && _nftContracts.length == _askPrices.length && _nftContracts.length == _reserves.length, "Marketplace: Lengths mismatch");
        uint256 _expirationTime;
        for (uint256 i; i < _nftContracts.length; i++) {
            _expirationTime = _placeOrder(_msgSender(), _nftContracts[i], _tokenIds[i], _lengths[i], _reserves[i], _askPrices[i]);
            emit OrderCreated(order.length - 1, _nftContracts[i], _tokenIds[i], _askPrices[i], _expirationTime);
        }
    }

    function buyById(uint256 orderId) external {
        _buy(orderId, _msgSender());
        emit TradeExecuted(orderId, _msgSender());
    }

    function buyByContractAndTokenId(IERC721 _nftContract, uint256 _tokenId) external {
        uint256 _orderId = getExistingOrderId(_nftContract, _tokenId);
        if (_orderId != 0) {
            _buy(_orderId, _msgSender());
            emit TradeExecuted(_orderId, _msgSender());
        } else {
            revert("Marketplace: Invalid parameters");
        }
    }

    function cancelListingById(uint256 orderId) external {
        _cancelOrder(orderId, _msgSender());
        emit OrderCancelled(orderId);
    }

    function cancelListingByContractAndTokenId(IERC721 _nftContract, uint256 _tokenId) external {
        uint256 _orderId = getExistingOrderId(_nftContract, _tokenId);
        if (_orderId != 0) {
            _cancelOrder(_orderId, _msgSender());
            emit OrderCancelled(_orderId);
        } else {
            revert("Marketplace: Invalid parameters");
        }
    }

    /// @dev OnlyOwner Functions

    function addNFTContractToApproved(IERC721 _contract) external onlyOwner {
        approvedNFT[_contract] = true;
    }

    function removeNFTContractFromApproved(IERC721 _contract) external onlyOwner {
        approvedNFT[_contract] = false;
    }

    function changeFeeRecipient(address _newRecipient) external onlyOwner {
        feeRecipient = _newRecipient;
    }

    function changeFee(uint256 _newFee) external onlyOwner {
        fee = _newFee;
    }

    function changeBaseToken(IERC20 _token) external onlyOwner {
        baseToken = _token;
    }

    /// @dev Internal Functions

    function _buy(uint256 _orderId, address buyer) internal {
        if (order[_orderId].expirationTime != 0) {
            require(order[_orderId].expirationTime >= block.timestamp, "Marketplace: Order expired");
        }
        require(order[_orderId].taker == address(0) , "Marketplace: Order already executed");
        require(order[_orderId].nftContract.ownerOf(order[_orderId].tokenId) == order[_orderId].maker, "Marketplace: Token Unavailable");
        require(order[_orderId].nftContract.getApproved(order[_orderId].tokenId) == address(this) || order[_orderId].nftContract.isApprovedForAll(order[_orderId].maker, address(this)), "Marketplace: Token Unavailable");
        if (order[_orderId].reserved != address(0)) {
            require(order[_orderId].reserved == buyer, "Marketplace: Order reserved for specific buyer");
        }
        if (fee > 0) {
            uint256 feeAmount = order[_orderId].askPrice * fee / denominator;
            uint256 tradeAmount = order[_orderId].askPrice - feeAmount;
            baseToken.transferFrom(buyer, order[_orderId].maker, tradeAmount);
            baseToken.transferFrom(buyer, feeRecipient, feeAmount);
        } else {
            baseToken.transferFrom(buyer, order[_orderId].maker, order[_orderId].askPrice);
        }

        order[_orderId].taker = buyer;
        order[_orderId].expirationTime = block.timestamp;
        order[_orderId].nftContract.safeTransferFrom(order[_orderId].maker, order[_orderId].taker, order[_orderId].tokenId);
    }

    function _placeOrder(address _maker, IERC721 _nftContract, uint256 _tokenId, uint256 _length, address _reserved, uint256 _askPrice) internal returns (uint256 _expirationTime) {
        require(approvedNFT[_nftContract], "Marketplace: This NFT Contract is not supported");
        require(_nftContract.ownerOf(_tokenId) == _msgSender(), "Marketplace: Caller is not the owner nor approved");
        require(_nftContract.getApproved(_tokenId) == address(this) || _nftContract.isApprovedForAll(_msgSender(), address(this)), "Marketplace: not approved");
        bytes32 orderHash_ = keccak256(abi.encodePacked(_nftContract, _tokenId, _maker));
        if (_length != 0) {
            _expirationTime = block.timestamp + _length;
        }
        order.push(Order({
            id: order.length,
            maker: _maker,
            taker: address(0),
            reserved: _reserved,
            nftContract: _nftContract,
            tokenId: _tokenId,
            askPrice: _askPrice,
            listingTime: block.timestamp,
            expirationTime: _expirationTime,
            orderHash: orderHash_
        }));
    }

    function _cancelOrder(uint256 _orderId, address user) internal {
        require(user == order[_orderId].maker, "Marketplace: Invalid Sender");
        require(order[_orderId].expirationTime >= block.timestamp, "Marketplace: Order Expired");
        require(order[_orderId].taker == address(0), "Marketplace: Order Executed");
        order[_orderId].expirationTime = block.timestamp - 1;
    }
    
}