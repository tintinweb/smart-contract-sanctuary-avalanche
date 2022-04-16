//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MarketplaceV5 is OwnableUpgradeable, PausableUpgradeable, ERC721Holder {
  using SafeMath for uint256;
  using AddressUpgradeable for address;

  IERC20 private _tokenContract;

  event CollectionCreated(address indexed nftContractAddress);
  event CollectionRemoved(address indexed nftContractAddress);
  event CollectionUpdated(address indexed nftContractAddress, bool active);

  event FeeCollectorCreated(
    uint indexed index,
    address wallet,
    uint256 percentage
  );

  event FeeCollectorRemoved(
    uint indexed index,
    address wallet
  );

  event ItemCreated(
    bytes32 itemId,
    uint256 indexed tokenId,
    address indexed seller,
    address nftAddress,
    uint256 price,
    uint256 expiresAt,
    SaleType saleType
  );

  event ItemCancelled(bytes32 indexed itemId, SaleStatus saleStatus, address user);
  event ItemSold(bytes32 indexed itemId, SaleStatus saleStatus, address user);
  event ItemBid(bytes32 indexed itemId, address user);
  event ItemExpired(bytes32 indexed itemId, SaleStatus saleStatus, address user);

  event SwapCreated(
    bytes32 indexed swapId,
    address fromCollection,
    uint256 fromTokenId,
    address fromUser,
    address toCollection,
    uint256 toTokenId,
    address toUser
  );

  event SwapApproved(bytes32 indexed swapId, address user);
  event SwapRejected(bytes32 indexed swapId, address user);
  event SwapCancelled(bytes32 indexed swapId, address user);
  event AuctionExpiryExecuted(bytes32 _itemId, address user);

  enum SaleType {
    Direct,
    Auction
  }

  enum SaleStatus {
    Open,
    Sold,
    Cancel,
    Reject,
    Expired
  }

  struct Bid {
    address bidder;
    uint256 price;
    uint256 createdAt;
    bool selected;
  }

  struct Item {
    address nftAddress;
    uint256 tokenId;
    uint256 price;
    address seller;
    address buyer;
    uint256 createdAt;
    uint256 expiresAt;
    uint256 topBidIndex;
    uint256 topBidPrice;
    address topBidder;
    Bid[] bids;
    SaleType saleType;
    SaleStatus saleStatus;
  }

  mapping (bytes32 => Item) private _items;

  struct AuctionExpiry {
    bytes32 itemId;
    uint expiresAt;
    bool executed;
  }

  AuctionExpiry[] private _auctionExpiry;

  struct Collection {
    bool active;
    bool royaltySupported;
    string name;
  }

  mapping (address => Collection) public collections;

  struct FeeCollector {
    address wallet;
    uint256 percentage;
  }

  FeeCollector[] private _feeCollectors;

  struct Swap {
    address fromCollection;
    uint256 fromTokenId;
    address fromUser;
    address toCollection;
    uint256 toTokenId;
    address toUser;
    uint256 createdAt;
    SaleStatus saleStatus;
  }

  mapping (bytes32 => Swap) public swaps;

  address private jobExecutor;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  address[] private _collectionIndex;
  uint256 public bidThreshold;

  /// mapping itemId => userAddress => amount
  mapping (bytes32 => mapping (address => uint256)) private _holdTokens;

  /// mapping collectionAddress => tokenId => ownerAddress
  mapping (address => mapping (uint256 => address)) private _holdNFTs;

  /// mapping saleType => percentage
  mapping (SaleType => uint256) public publicationFees;
  address private _publicationFeeWallet;

  bytes32[] private _itemIndex;
  mapping (bytes32 => Swap) private _swaps;
  bytes32[] private _swapIndex;

  /**
   * @dev Sets for token address
   * @param _tokenAddress Token address
   */
  function initialize(address _tokenAddress) public initializer {
    _transferOwnership(_msgSender());
    setTokenAddress(_tokenAddress);
    setJobExecutor(_msgSender());
    bidThreshold = 50;
  }

  /**
   * @dev Only executor
   */
  modifier onlyExecutor() {
    require(jobExecutor == _msgSender(), "Caller is not job executor");
    _;
  }

  ///--------------------------------- PUBLIC FUNCTIONS ---------------------------------

  /**
   * @dev Seller of NFT
   * @param _nftContractAddress Collection address
   * @param _tokenId Token id
   * @return address Seller address
   */
  function sellerOf(
    address _nftContractAddress,
    uint256 _tokenId
  ) public view returns(address) {
    return _holdNFTs[_nftContractAddress][_tokenId];
  }

  /**
   * @dev Auction sell
   * @param _nftContractAddress NFT contract address
   * @param _tokenId NFT token id
   * @param _price NFT initial price 
   * @param _expiresAt Expiry timestamp in UTC
   */
  function auction(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _price,
    uint256 _expiresAt
  ) public whenNotPaused {
    _isActiveCollection(_nftContractAddress);
    _createItem(_nftContractAddress, _tokenId, _price, _expiresAt, SaleType.Auction);
  }

  /**
   * @dev Direct sell
   * @param _nftContractAddress NFT contract address
   * @param _tokenId NFT token id
   * @param _price NFT price
   */
  function sell(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _price
  ) public whenNotPaused {
    _isActiveCollection(_nftContractAddress);
    _createItem(_nftContractAddress, _tokenId, _price, 0, SaleType.Direct);
  }

  /**
   * @dev Cancel market item
   * @param _itemId Item id
   */
  function cancel(bytes32 _itemId) public whenNotPaused {
    Item storage item = _items[_itemId];

    require(item.seller == _msgSender(), "Not token owner");
    require(item.bids.length == 0, "Bid exists");
    require(item.saleStatus == SaleStatus.Open, "Item is unavailable");

    /// release nft and transfer it to the seller
    IERC721 nftRegistry = IERC721(item.nftAddress);
    nftRegistry.safeTransferFrom(address(this), item.seller, item.tokenId);
    delete _holdNFTs[item.nftAddress][item.tokenId];

    item.saleStatus = SaleStatus.Cancel;

    emit ItemCancelled(_itemId, SaleStatus.Cancel, _msgSender());
  }

  /**
   * @dev Buy NFT from direct sales
   * @param _itemId Item ID
   */
  function buy(bytes32 _itemId) public whenNotPaused {
    Item storage item = _items[_itemId];

    _executePayment(_itemId, _msgSender());

    item.buyer = _msgSender();
    item.saleStatus = SaleStatus.Sold;

    IERC721(item.nftAddress).transferFrom(address(this), _msgSender(), item.tokenId);
    delete _holdNFTs[item.nftAddress][item.tokenId];

    emit ItemSold(_itemId, SaleStatus.Sold, _msgSender());
  }

  /**
   * @dev Bid to auction sales
   * @param _itemId Item ID
   */
  function bid(
    bytes32 _itemId,
    uint256 _price
  ) public whenNotPaused {
    Item storage item = _items[_itemId];

    require(_price >= (item.topBidPrice.add(item.topBidPrice.div(1000).mul(bidThreshold))), "Minimum bid price is required");
    require(_tokenContract.balanceOf(_msgSender()) >= _price, "Not enough tokens");
    require(_tokenContract.allowance(_msgSender(), address(this)) >= _price, "Not enough allowance");

    if (item.saleType == SaleType.Auction && item.saleStatus == SaleStatus.Open) {
      uint256 bidIndex = 0;

      if (item.bids.length > 0) {
        bidIndex = item.bids.length - 1;

        if (_holdTokens[_itemId][item.topBidder] > 0) {
          _releaseHoldAmount(_itemId, item.topBidder, item.topBidder, item.topBidPrice);
        }
      }
      
      item.bids.push(Bid({
        bidder: _msgSender(),
        price: _price,
        createdAt: block.timestamp,
        selected: false
      }));

      _putHoldAmount(_itemId, _msgSender(), _price);

      item.topBidIndex = bidIndex;
      item.topBidPrice = _price;
      item.topBidder = _msgSender();
      
      if (item.expiresAt.sub(600) < block.timestamp && item.expiresAt > block.timestamp) {
        item.expiresAt = item.expiresAt.add(600);
      }

      emit ItemBid(_itemId, _msgSender());
    }
  }

  /**
   * @dev Swap request
   * @param _fromCollection Collection ID
   * @param _fromTokenId Item ID
   * @param _toCollection Collection ID
   * @param _toTokenId Item ID
   */
  function swap(
    address _fromCollection,
    uint256 _fromTokenId,
    address _toCollection,
    uint256 _toTokenId
  ) public whenNotPaused {
    _isActiveCollection(_fromCollection);
    _isActiveCollection(_toCollection);

    IERC721 fromCollection = IERC721(_fromCollection);
    IERC721 toCollection = IERC721(_toCollection);

    address fromTokenOwner = fromCollection.ownerOf(_fromTokenId);
    address toTokenOwner = toCollection.ownerOf(_toTokenId);

    require(_msgSender() == fromTokenOwner, "Not token owner");
    require(
      (fromCollection.getApproved(_fromTokenId) == address(this) || fromCollection.isApprovedForAll(fromTokenOwner, address(this))) && (toCollection.getApproved(_toTokenId) == address(this) || toCollection.isApprovedForAll(toTokenOwner, address(this))),
      "The contract is not authorized"
    );

    bytes32 swapId = keccak256(
      abi.encodePacked(
        block.timestamp,
        _fromCollection,
        _fromTokenId,
        _toCollection,
        _toTokenId
      )
    );

    _swaps[swapId] = Swap({
      fromCollection: _fromCollection,
      fromTokenId: _fromTokenId,
      fromUser: fromTokenOwner,
      toCollection: _toCollection,
      toTokenId: _toTokenId,
      toUser: toTokenOwner,
      createdAt: block.timestamp,
      saleStatus: SaleStatus.Open
    });

    _swapIndex.push(swapId);

    emit SwapCreated(swapId, _fromCollection, _fromTokenId, fromTokenOwner, _toCollection, _toTokenId, toTokenOwner);
  }

  /**
   * @dev Approve swap by receiver of NFT
   * @param _swapId Swap ID
   */
  function approveSwap(bytes32 _swapId) public whenNotPaused {
    Swap storage _swap = _swaps[_swapId];

    IERC721 fromCollection = IERC721(_swap.fromCollection);
    IERC721 toCollection = IERC721(_swap.toCollection);

    require(_swap.toUser == _msgSender(), "Not token owner");
    require((fromCollection.ownerOf(_swap.fromTokenId) == _swap.fromUser) && (toCollection.ownerOf(_swap.toTokenId) == _msgSender()), "Not token owner");
    require(
      (fromCollection.getApproved(_swap.fromTokenId) == address(this) || fromCollection.isApprovedForAll(_swap.fromUser, address(this))) && (toCollection.getApproved(_swap.toTokenId) == address(this) || toCollection.isApprovedForAll(_swap.toUser, address(this))),
      "The contract is not authorized"
    );

    fromCollection.transferFrom(_swap.fromUser, _swap.toUser, _swap.fromTokenId);
    toCollection.transferFrom(_swap.toUser, _swap.fromUser, _swap.toTokenId);

    _swap.saleStatus = SaleStatus.Sold;
  }

  /**
   * @dev Reject swap by receiver of NFT
   * @param _swapId Swap ID
   */
  function rejectSwap(bytes32 _swapId) public whenNotPaused {
    Swap storage _swap = _swaps[_swapId];
    require(_swap.toUser == _msgSender(), "Not token owner");
    _swap.saleStatus = SaleStatus.Reject;

    emit SwapRejected(_swapId, _swap.toUser);
  }

  /**
   * @dev Cancel swap by owner of NFT
   * @param _swapId Swap ID
   */
  function cancelSwap(bytes32 _swapId) public whenNotPaused {
    Swap storage _swap = _swaps[_swapId];
    require(_swap.fromUser == _msgSender(), "Not token owner");
    _swap.saleStatus = SaleStatus.Cancel;

    emit SwapCancelled(_swapId, _swap.fromUser);
  }

  /**
   * @dev Get auction expiry
   * @return AuctionExpiry Array of auction expiry
   */
  function getAuctionExpiry() public view returns(AuctionExpiry[] memory) {
    AuctionExpiry[] memory auctionData = new AuctionExpiry[](_auctionExpiry.length);

    for (uint256 i = 0; i < _auctionExpiry.length; i++) {
      AuctionExpiry storage auctionExpiry = _auctionExpiry[i];
      
      if (auctionExpiry.expiresAt < block.timestamp && !auctionExpiry.executed) {
        auctionData[i] = auctionExpiry;
      }
    }

    return auctionData;
  }

  /**
   * @dev Get items with pagination supported
   * @param _startIndex Start with index number
   * @param _endIndex End with index number
   * @return uint256 Total of items
   * @return bytes32[] Array of item ids
   */
  function getItems(
    uint _startIndex,
    uint _endIndex
  ) public view returns(uint256, bytes32[] memory) {
    bytes32[] memory itemData = new bytes32[](_itemIndex.length);
    
    if (_startIndex >= _itemIndex.length) {
      _startIndex = 0;
    }

    if (_endIndex >= _itemIndex.length) {
      _endIndex = _itemIndex.length.sub(1);
    }

    for (uint i = _startIndex; i <= _endIndex; i++) {
      itemData[i] = _itemIndex[i];
    }

    return (_itemIndex.length, itemData);
  }

  /**
   * @dev Get item details
   * @param _itemId Item id
   * @return Item Item details
   */
  function getItem(bytes32 _itemId) public view returns(Item memory) {
    Item storage item = _items[_itemId];
    return item;
  }

  /**
   * @dev Get all bids of the item
   * @param _itemId Item id
   * @return Bid Array of bids
   */
  function getBids(bytes32 _itemId) public view returns(Bid[] memory) {
    Item storage item = _items[_itemId];
    Bid[] memory bidData = new Bid[](item.bids.length);

    for (uint256 i = 0; i < item.bids.length; i++) {
      Bid storage bidItem = item.bids[i];
      bidData[i] = bidItem;
    }

    return bidData;
  }

  /**
   * @dev Get bid details
   * @param _itemId Sale item id
   * @param _bidIndex Index of bid
   * @return Bid Struct of bid
   */
  function getBid(bytes32 _itemId, uint _bidIndex) public view returns(Bid memory) {
    Item storage item = _items[_itemId];
    return item.bids[_bidIndex];
  }

  /**
   * @dev Get list of swap ids
   * @param _startIndex Start with index number
   * @param _endIndex End with index number
   */
  function getSwaps(
    uint _startIndex,
    uint _endIndex
  ) public view returns(uint256, bytes32[] memory) {
    bytes32[] memory itemData = new bytes32[](_swapIndex.length);
    
    if (_startIndex >= _swapIndex.length) {
      _startIndex = 0;
    }

    if (_endIndex >= _swapIndex.length) {
      _endIndex = _swapIndex.length.sub(1);
    }

    for (uint i = _startIndex; i <= _endIndex; i++) {
      itemData[i] = _swapIndex[i];
    }

    return (_swapIndex.length, itemData);
  }

  /**
   * @dev Get swap details
   * @param _itemId Swap id
   */
  function getSwap(bytes32 _itemId) public view returns(Swap memory) {
    Swap storage item = _swaps[_itemId];
    return item;
  }

  /**
   * @dev Get royalty info
   * @param _tokenId Token id
   * @param _salePrice Token sale price
   */
  function getRoyaltyInfo(address _nftContractAddress, uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns(address receiverAddress, uint256 royaltyAmount)
  {
    return _getRoyaltyInfo(_nftContractAddress, _tokenId, _salePrice);
  }

  /**
   * @dev Tells wether royalty is supported or not
   * @param _nftContractAddress Collection address
   * @return bool
   */
  function checkRoyalties(address _nftContractAddress)
    external
    view
    returns(bool)
  {
    return _isRoyaltiesSupport(_nftContractAddress);
  }

  ///--------------------------------- ADMINISTRATION FUNCTIONS ---------------------------------

  /**
   * @dev Set ERC20 contract address
   * @param _tokenAddress ERC20 contract address
   */
  function setTokenAddress(address _tokenAddress) public onlyOwner {
    _tokenContract = IERC20(_tokenAddress);
  }

  /**
   * @dev Pause the public function
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   * @dev Unpause the public function
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   * @dev Get collections
   * @return Collection Collection array
   */
  function getCollections() public view returns(Collection[] memory) {
    Collection[] memory collectionArray = new Collection[](_collectionIndex.length);

    for (uint256 i = 0; i < _collectionIndex.length; i++) {
      Collection storage collection = collections[_collectionIndex[i]];
      collectionArray[i] = collection;
    }

    return collectionArray;
  }

  /**
   * @dev Create collection
   * @param _nftContractAddress NFT contract address for the collection
   * @param _active Active status of the collection
   */
  function createCollection(
    address _nftContractAddress,
    bool _active,
    string memory _name
  ) public onlyOwner {
    _requireERC721(_nftContractAddress);

    collections[_nftContractAddress] = Collection({
      active: _active,
      royaltySupported: _isRoyaltiesSupport(_nftContractAddress),
      name: _name
    });

    _collectionIndex.push(_nftContractAddress);
    
    emit CollectionCreated(_nftContractAddress);
  }

  /**
   * @dev Remove collection
   * @param _nftContractAddress NFT contract address for the collection
   */
  function removeCollection(address _nftContractAddress) public onlyOwner {
    delete collections[_nftContractAddress];

    for (uint i = 0; i < _collectionIndex.length; i++) {
      if (_collectionIndex[i] == _nftContractAddress) {
        _collectionIndex[i] = _collectionIndex[_collectionIndex.length - 1];
      }
    }

    _collectionIndex.pop();

    emit CollectionRemoved(_nftContractAddress);
  }

  /**
   * @dev Update collection
   * @param _nftContractAddress NFT contract address
   * @param _active Active status of the collection
   */
  function updateCollection(
    address _nftContractAddress,
    bool _active
  ) public onlyOwner {
    Collection storage collection = collections[_nftContractAddress];
    collection.active = _active;

    emit CollectionUpdated(
      _nftContractAddress,
      _active
    );
  }

  /**
   * @dev Get fee collectors
   * @return FeeCollector Array of fee collectors
   */
  function getFeeCollectors() public view onlyOwner returns(FeeCollector[] memory) {
    FeeCollector[] memory feeCollectorArray = new FeeCollector[](_feeCollectors.length);

    for (uint256 i = 0; i < _feeCollectors.length; i++) {
      FeeCollector storage feeCollector = _feeCollectors[i];
      feeCollectorArray[i] = feeCollector;
    }

    return feeCollectorArray;
  }

  /**
   * @dev Add fee collector
   * @param _wallet Wallet address
   * @param _percentage Percentage amount (dividing for 1000)
   */
  function addFeeCollector(
    address _wallet,
    uint256 _percentage
  ) public onlyOwner {
    _feeCollectors.push(FeeCollector({
      wallet: _wallet,
      percentage: _percentage
    }));

    uint index = _feeCollectors.length;

    emit FeeCollectorCreated(
      index,
      _wallet,
      _percentage
    );
  }

  /**
   * @dev Remove fee collector
   * @param _wallet FeeCollector address
   */
  function removeFeeCollector(address _wallet) public onlyOwner {
    FeeCollector memory removedFeeCollector;
    uint _index = 0;
    for (uint i = 0; i < _feeCollectors.length; i++) {
      if (_feeCollectors[i].wallet == _wallet) {
        _feeCollectors[i] = _feeCollectors[_feeCollectors.length - 1];
        _feeCollectors[_feeCollectors.length - 1] = removedFeeCollector;
        _index = i;
      }
    }

    _feeCollectors.pop();

    emit FeeCollectorRemoved(
      _index,
      _wallet
    );
  }

  /**
   * @dev Owner can transfer NFT to the user for emergency purpose
   * @param _nftContractAddress NFT contract address
   * @param _tokenId Token id
   * @param _to Receiver address
   */
  function emergencyTransferTo(
    address _nftContractAddress,
    address _to,
    uint256 _tokenId
  ) public onlyOwner {
    IERC721(_nftContractAddress).safeTransferFrom(address(this), _to, _tokenId);
  }

  /**
   * @dev Emergency cancel(de-listing) sale item by admin
   * @dev This cancellation is remove NFT from storage but still owned by this contract
   * @dev So we need to transfer out manually by calling emergencyTransferTo() function
   * @param _itemId Item id
   */
  function emergencyCancel(bytes32 _itemId) public onlyOwner {
    Item storage item = _items[_itemId];
    require(item.saleStatus == SaleStatus.Open, "Item is unavailable");
    delete _holdNFTs[item.nftAddress][item.tokenId];

    /// revoke last bid if exists
    if (item.bids.length > 0) {
      _releaseHoldAmount(_itemId, item.topBidder, item.topBidder, item.topBidPrice);
    }

    item.saleStatus = SaleStatus.Reject;

    emit ItemCancelled(_itemId, SaleStatus.Reject, _msgSender());
  }

  /**
   * @dev Set job executor
   * @param _jobExecutor Job executor address
   */
  function setJobExecutor(address _jobExecutor) public onlyOwner {
    jobExecutor = _jobExecutor;
  }
  
  /**
   * @dev Set bid threshold
   * @param _percentage Percentage
   */
  function setBidThreshold(uint256 _percentage) public onlyOwner {
    bidThreshold = _percentage;
  }

  /**
   * @dev Set publication fee
   * @param _saleType Sales type
   * @param _amount Fixed amount
   */
  function setPublicationFee(SaleType _saleType, uint256 _amount) public onlyOwner {
    publicationFees[_saleType] = _amount;
  }

  /**
   * @dev Set the address of publication fee
   * @param _wallet Wallet address
   */
  function setPublicationFeeWallet(address _wallet) public onlyOwner {
    _publicationFeeWallet = _wallet;
  }

  /**
   * @dev Get the address of publication fee
   * @return address
   */
  function getPublicationFeeWallet() public onlyOwner view returns(address) {
    return _publicationFeeWallet;
  }

  /**
   * @dev This function is used for executes all expired auctions
   * System will automatically select the highest price
   */
  function executeJob() public onlyExecutor {
    for (uint256 i = 0; i < _auctionExpiry.length; i++) {
      AuctionExpiry storage auctionExpiry = _auctionExpiry[i];
      
      if (auctionExpiry.expiresAt < block.timestamp && !auctionExpiry.executed) {
        Item storage item = _items[auctionExpiry.itemId];

        if (item.saleStatus == SaleStatus.Open) {
          if (item.bids.length > 0) {
            item.buyer = item.topBidder;
            item.price = item.topBidPrice;
            item.saleStatus = SaleStatus.Sold;
            
            _executePayment(auctionExpiry.itemId, item.buyer);
            
            IERC721(item.nftAddress).transferFrom(address(this), item.buyer, item.tokenId);
            delete _holdNFTs[item.nftAddress][item.tokenId];

            for (uint256 j = 0; j < item.bids.length; j++) {
              if (item.bids[j].price == item.topBidPrice && item.bids[j].bidder == item.topBidder) {
                item.bids[j].selected = true;
                break;
              }
            }

            emit ItemSold(auctionExpiry.itemId, SaleStatus.Sold, _msgSender());
          } else {
            item.saleStatus = SaleStatus.Expired;
            emit ItemExpired(auctionExpiry.itemId, SaleStatus.Expired, _msgSender());
          }

          emit AuctionExpiryExecuted(auctionExpiry.itemId, _msgSender());
        }
      }
    }
  }

  ///--------------------------------- INTERNAL FUNCTIONS ---------------------------------

  /**
   * @dev Hold tokens by transfer amount of the bidder to this contract
   */
  function _putHoldAmount(
    bytes32 _itemId,
    address _user,
    uint256 _amount
  ) internal {
    _holdTokens[_itemId][_user] = _holdTokens[_itemId][_user].add(_amount);
    _tokenContract.transferFrom(_user, address(this), _amount);
  }

  /**
   * @dev Sent back the held amount of the previous loser to their wallet
   * @param _itemId Item id
   * @param _user Wallet address of the user
   * @param _to Receiver wallet
   * @param _amount Amount of tokens
   */
  function _releaseHoldAmount(
    bytes32 _itemId,
    address _user,
    address _to,
    uint256 _amount
  ) internal {
    _holdTokens[_itemId][_user] = _holdTokens[_itemId][_user].sub(_amount);
    _tokenContract.transfer(_to, _amount);
  }

  function _isRoyaltiesSupport(address _nftContractAddress)
    private
    view
    returns(bool)
  {
    (bool success) = IERC2981(_nftContractAddress).supportsInterface(_INTERFACE_ID_ERC2981);
    return success;
  }

  function _getRoyaltyInfo(address _nftContractAddress, uint256 _tokenId, uint256 _salePrice)
    private
    view
    returns(address receiverAddress, uint256 royaltyAmount)
  {
    IERC2981 nftContract = IERC2981(_nftContractAddress);
    (address _royaltiesReceiver, uint256 _royalties) = nftContract.royaltyInfo(_tokenId, _salePrice);
    return(_royaltiesReceiver, _royalties);
  }

  /**
   * @dev Create sale item
   * @param _nftContractAddress Collection address
   * @param _tokenId Token id
   * @param _price Item price
   * @param _expiresAt Expiry date
   * @param _saleType Sales type
   */
  function _createItem(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _price,
    uint256 _expiresAt,
    SaleType _saleType
  )
    internal
  {
    IERC721 nftRegistry = IERC721(_nftContractAddress);
    address sender = _msgSender();
    address tokenOwner = nftRegistry.ownerOf(_tokenId);

    require(sender == tokenOwner, "Not token owner");
    require(_price > 0, "Price should be bigger than 0");
    require(
      nftRegistry.getApproved(_tokenId) == address(this) || nftRegistry.isApprovedForAll(tokenOwner, address(this)),
      "The contract is not authorized"
    );

    /// charge publication fees
    if (publicationFees[_saleType] > 0 && _publicationFeeWallet != address(0)) {
      uint256 fees = publicationFees[_saleType];
      require(_tokenContract.allowance(sender, address(this)) >= fees, "Insufficient allowance");
      _tokenContract.transferFrom(sender, _publicationFeeWallet, fees);
    }

    bytes32 itemId = keccak256(
      abi.encodePacked(
        block.timestamp,
        tokenOwner,
        _tokenId,
        _nftContractAddress,
        _price,
        _saleType
      )
    );
    
    Item storage item = _items[itemId];

    item.nftAddress = _nftContractAddress;
    item.tokenId = _tokenId;
    item.price = _price;
    item.seller = tokenOwner;
    item.createdAt = block.timestamp;
    item.expiresAt = _expiresAt;
    item.saleType = _saleType;
    item.saleStatus = SaleStatus.Open;

    if (_saleType == SaleType.Auction) {
      _auctionExpiry.push(AuctionExpiry({
        itemId: itemId,
        expiresAt: item.expiresAt,
        executed: false
      }));
    }

    /// hold nft and transfer NFT to this cointract
    nftRegistry.safeTransferFrom(tokenOwner, address(this), _tokenId);
    _holdNFTs[_nftContractAddress][_tokenId] = tokenOwner;

    _itemIndex.push(itemId);

    emit ItemCreated(itemId, _tokenId, tokenOwner, _nftContractAddress, _price, _expiresAt, _saleType);
  }

  /**
   * @dev Required ERC721 implementation
   * @param _nftContractAddress NFT contract(collection) address
   */
  function _requireERC721(address _nftContractAddress) internal view {
    require(_nftContractAddress.isContract(), "Invalid NFT Address");
    require(
      IERC721(_nftContractAddress).supportsInterface(_INTERFACE_ID_ERC721),
      "Unsupported ERC721 Interface"
    );

    bool isExists = false;

    for (uint i = 0; i < _collectionIndex.length; i++) {
      if (_collectionIndex[i] == _nftContractAddress) {
        isExists = true;
        break;
      }
    }

    require(!isExists, "Existance collection");
  }

  /**
   * @dev Check is active collection
   * @param _nftContractAddress NFT contract address
   */
  function _isActiveCollection(address _nftContractAddress) internal view {
    Collection storage collection = collections[_nftContractAddress];
    require(collection.active, "Inactive Collection");
  }

  /**
   * @dev Execute payment
   * @param _itemId Item id
   * @param _sender Sender address
   */
  function _executePayment(
    bytes32 _itemId,
    address _sender
  ) internal virtual {
    Item storage item = _items[_itemId];

    /// validate sale item
    require(item.price > 0, "Item is unavailable");

    uint256 toTransfer = item.price;
    uint256 price = item.price;

    if (item.saleType == SaleType.Auction) {
      require(_holdTokens[_itemId][_sender] >= item.price, "Not enough funds");
      
      for (uint256 i = 0; i < _feeCollectors.length; i++) {
        if (_feeCollectors[i].wallet != address(0) && _feeCollectors[i].percentage > 0) {
          uint256 fees = price.div(1000).mul(_feeCollectors[i].percentage);
          _releaseHoldAmount(_itemId, _sender, _feeCollectors[i].wallet, fees);
          toTransfer -= fees;
        }
      }

      (address royaltiesReceiver, uint256 royalty) = _getRoyaltyInfo(item.nftAddress, item.tokenId, price);

      if (royaltiesReceiver != address(0) && royalty > 0) {
        _releaseHoldAmount(_itemId, _sender, royaltiesReceiver, royalty);
        toTransfer -= royalty;
      }

      require(_tokenContract.balanceOf(address(this)) >= toTransfer, "Transfer to seller failed");
      _releaseHoldAmount(_itemId, _sender, item.seller, toTransfer);
    } else {
      require(_tokenContract.balanceOf(_sender) >= item.price, "Not enough funds");
      require(_tokenContract.allowance(_sender, address(this)) >= price, "Not enough tokens");
      
      _tokenContract.transferFrom(_sender, address(this), price);

      for (uint256 i = 0; i < _feeCollectors.length; i++) {
        if (_feeCollectors[i].wallet != address(0) && _feeCollectors[i].percentage > 0) {
          uint256 fees = price.div(1000).mul(_feeCollectors[i].percentage);
          _tokenContract.transfer(_feeCollectors[i].wallet, fees);
          toTransfer -= fees;
        }
      }

      (address royaltiesReceiver, uint256 royalty) = _getRoyaltyInfo(item.nftAddress, item.tokenId, price);

      if (royaltiesReceiver != address(0) && royalty > 0) {
        _tokenContract.transfer(royaltiesReceiver, royalty);
        toTransfer -= royalty;
      }

      require(_tokenContract.balanceOf(address(this)) >= toTransfer, "Transfer to seller failed");
      _tokenContract.transfer(item.seller, toTransfer);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}