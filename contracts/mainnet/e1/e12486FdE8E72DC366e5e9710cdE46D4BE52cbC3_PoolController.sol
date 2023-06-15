// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IPoolListings.sol";
import "./IPoolBids.sol";
import "./IPools.sol";

contract PoolController is Ownable, ReentrancyGuard {

  struct ListingData {
    uint256 tokenId;
    uint256 oldPrice;
    uint256 newPrice;
  }

  struct BidData {
    uint256 oldPrice;
    uint256 newPrice;
  }

  struct BidFulfillment {
    uint256 bidId;
    uint256 tokenId;
  }

  event FloorChange(
    uint256 poolId,
    uint256 newPrice
  );

  event CeilingChange(
    uint256 poolId,
    uint256 newAmount
  );

  address public poolContract;
  address public poolListingsContract;
  address public poolBidsContract;

  uint256 public _window;
  bool public _active;

  constructor(address _poolContract) {
    poolContract = _poolContract;
    _window = 8000; // to be divided by 10,000 ==> bids @ -20% ceiling min; listings @ +20% floor max
    _active = true;
  }

  // POOLS

  function add(address collectionAddress, uint256 weight, uint256 maxEntries, uint256 bidsWeight, uint256 listingsWeight) public onlyOwner {
    IPools pools = IPools(poolContract);
    pools.create(collectionAddress, weight, maxEntries, bidsWeight, listingsWeight);
  }

  function deactivate(uint256 id) public onlyOwner {
    IPools pools = IPools(poolContract);
    pools.deactivate(id);
  }

  function activate(uint256 id) public onlyOwner {
    IPools pools = IPools(poolContract);
    pools.activate(id);
  }

  function setWeight(uint256 id, uint256 weight) public onlyOwner {
    IPools pools = IPools(poolContract);
    pools.setWeight(id, weight);
  }

  function setMaxEntries(uint256 id, uint256 maxEntries) public onlyOwner {
    IPools pools = IPools(poolContract);
    pools.setMaxEntries(id, maxEntries);
  }

  function setSideWeights(uint256 id, uint256 bidsWeight, uint256 listingsWeight) public onlyOwner {
    IPools pools = IPools(poolContract);
    pools.setSideWeights(id, bidsWeight, listingsWeight);
  }

  function all() public view returns (IPools.Pool[] memory) {
    IPools pools = IPools(poolContract);
    return pools.all();
  }

  function active() public view returns (IPools.Pool[] memory) {
    IPools pools = IPools(poolContract);
    return pools.active();
  }

  function inactive() public view returns (IPools.Pool[] memory) {
    IPools pools = IPools(poolContract);
    return pools.inactive();
  }

  function find(uint256 id) public view returns (IPools.Pool memory) {
    IPools pools = IPools(poolContract);
    return pools.find(id);
  }

  function lookupPoolId(address collectionAddress) public view returns (uint256) {
    IPools pools = IPools(poolContract);
    return pools.lookupPoolId(collectionAddress);
  }

  // LISTINGS

  function list(uint256 poolId, ListingData[] memory listingsData) public nonReentrant {
    require(_active, "Contract is paused.");
    require(listingsData.length <= 10, "Exceeds maximum listings per transaction.");
    IPoolListings poolListings = IPoolListings(poolListingsContract);
    IPools pools = IPools(poolContract);

    uint256 currentFloor = pools.floor(poolId);

    IPools.Pool memory pool = pools.find(poolId);
    
    for (uint i = 0; i < listingsData.length; i++) {
      if (maxPrice(poolId) > 0) { // will be 0 when no floor
        require(listingsData[i].newPrice <= maxPrice(poolId), "Price is too high.");
      }
      poolListings.create(poolId, pool.collectionAddress, msg.sender, listingsData[i].tokenId, listingsData[i].newPrice, pool.maxEntries);
    }

    handleFloorChanges(poolId, currentFloor);
  }

  function reducePrices(uint256 poolId, ListingData[] memory listingsData) public nonReentrant {
    require(_active, "Contract is paused.");

    IPools pools = IPools(poolContract);

    uint256 currentFloor = pools.floor(poolId);

    IPoolListings poolListings = IPoolListings(poolListingsContract);
    for (uint i = 0; i < listingsData.length; i++) {
      require(listingsData[i].newPrice < listingsData[i].oldPrice, "Price must be lower.");
      require(listingsData[i].newPrice <= maxPrice(poolId), "Price is too high.");
      poolListings.reducePrice(poolId,  listingsData[i].oldPrice, listingsData[i].newPrice, msg.sender);
    }

    handleFloorChanges(poolId, currentFloor);
  }

  function delist(uint256 poolId, uint256[] memory listingIds) public nonReentrant {
    IPoolListings poolListings = IPoolListings(poolListingsContract);

    IPools pools = IPools(poolContract);

    uint256 currentFloor = pools.floor(poolId);

    for (uint i = 0; i < listingIds.length; i++) {
      poolListings.destroy(poolId, listingIds[i], msg.sender);
    }

    handleFloorChanges(poolId, currentFloor);
  }

  function purchase(uint256 poolId, uint256[] memory listingIds) public payable nonReentrant {
    require(_active, "Contract is paused.");

    IPools pools = IPools(poolContract);

    uint256 currentFloor = pools.floor(poolId);

    IPoolListings poolListings = IPoolListings(poolListingsContract);
    
    uint256 total;

    for (uint i = 0; i < listingIds.length; i++) {
      IPoolListings.Listing memory listing = poolListings.find(poolId, listingIds[i]);      
      total += listing.price;
    }

    require(msg.value >= total, "Not enough AVAX sent.");

    for (uint i = 0; i < listingIds.length; i++) {
      IPoolListings.Listing memory listing = poolListings.find(poolId, listingIds[i]);      
      poolListings.fulfill{value: listing.price}(poolId, listingIds[i], msg.sender);
    }

    handleFloorChanges(poolId, currentFloor);
  }

  function listings(uint256 poolId) public view returns (IPoolListings.Listing[] memory) {
    IPoolListings poolListings = IPoolListings(poolListingsContract);
    return poolListings.all(poolId);
  }


  function findListingById(uint256 poolId, uint256 id) public view returns (IPoolListings.Listing memory) {
    IPoolListings poolListings = IPoolListings(poolListingsContract);
    return poolListings.find(poolId, id);
  }

  function findListerByPrice(uint256 poolId, uint256 price) public view returns (address) {
    IPoolListings poolListings = IPoolListings(poolListingsContract);
    return poolListings.findListerByPrice(poolId, price);
  }

  function listingPrices(uint256 poolId) public view returns (uint256[] memory) {
    IPoolListings poolListings = IPoolListings(poolListingsContract);
    return poolListings.prices(poolId);
  }

  function priceExistsInPool(uint256 poolId, uint256 price) public view returns (bool) {
    IPoolListings poolListings = IPoolListings(poolListingsContract);
    return poolListings.priceExistsInPool(poolId, price);
  }

  function listingsInPoolForAccount(uint256 poolId, address account) public view returns (IPoolListings.Listing[] memory) {
    IPoolListings poolListings = IPoolListings(poolListingsContract);
    return poolListings.inPoolForAccount(poolId, account);
  }

  function floor(uint256 poolId) public view returns (uint256) {
    IPools pools = IPools(poolContract);
    return pools.floor(poolId);
  }

  function listingSpace(uint256 poolId) public view returns (uint256) {
    IPoolListings poolListings = IPoolListings(poolListingsContract);
    return poolListings.cubicSpace(poolId);
  }

  function maxPrice(uint256 poolId) public view returns (uint256) {
    IPools pools = IPools(poolContract);
    uint256 currentFloor = pools.floor(poolId);
    return currentFloor + ((currentFloor * (10000 - _window)) / 10000);
  }

  // BIDS

  function bid(uint256 poolId, uint256[] memory prices) public nonReentrant {
    require(_active, "Contract is paused.");
    IPoolBids poolBids = IPoolBids(poolBidsContract);

    IPools pools = IPools(poolContract);
    IPools.Pool memory pool = pools.find(poolId);

    uint256 currentCeiling = pools.ceiling(poolId);

    for (uint i = 0; i < prices.length; i++) {
      require(prices[i] >= minBid(poolId), "Bid is too low.");
      poolBids.create(poolId, pool.collectionAddress, msg.sender, prices[i], pool.maxEntries);
    }

    handleCeilingChanges(poolId, currentCeiling);
  }

  function raiseBids(uint256 poolId, BidData[] memory bidsData) public nonReentrant {
    require(_active, "Contract is paused.");
    IPoolBids poolBids = IPoolBids(poolBidsContract);

    IPools pools = IPools(poolContract);

    uint256 currentCeiling = pools.ceiling(poolId);

    for (uint i = 0; i < bidsData.length; i++) {
      require(bidsData[i].newPrice > bidsData[i].oldPrice, "New bid must be higher.");
      require(bidsData[i].newPrice >= minBid(poolId), "Bid is too low.");
      poolBids.raiseBid(poolId, bidsData[i].oldPrice, bidsData[i].newPrice, msg.sender);
    }

    handleCeilingChanges(poolId, currentCeiling);
  }

  function cancelBids(uint256 poolId, uint256[] memory bidIds) public nonReentrant {
    IPools pools = IPools(poolContract);

    uint256 currentCeiling = pools.ceiling(poolId);

    IPoolBids poolBids = IPoolBids(poolBidsContract);
    for (uint i = 0; i < bidIds.length; i++) {
      poolBids.destroy(poolId, bidIds[i], msg.sender);
    }

    handleCeilingChanges(poolId, currentCeiling);
  }

  function acceptBids(uint256 poolId, BidFulfillment[] memory fulfillments) public nonReentrant {
    require(_active, "Contract is paused.");
    IPoolBids poolBids = IPoolBids(poolBidsContract);

    IPools pools = IPools(poolContract);
    IPools.Pool memory pool = pools.find(poolId);

    bool anyListed = false;

    uint256 currentCeiling = pools.ceiling(poolId);
    uint256 currentFloor = pools.floor(poolId);
    
    IERC721 collection = IERC721(pool.collectionAddress);

    for (uint i = 0; i < fulfillments.length; i++) {
      if (collection.ownerOf(fulfillments[i].tokenId) == poolListingsContract) {
        anyListed = true;
      }
      poolBids.accept(poolId, fulfillments[i].bidId, pool.collectionAddress, fulfillments[i].tokenId, msg.sender);
    }

    if (anyListed) {
      handleFloorChanges(poolId, currentFloor);
    }
    handleCeilingChanges(poolId, currentCeiling);
  }

  function bids(uint256 poolId) public view returns (IPoolBids.Bid[] memory) {
    IPoolBids poolBids = IPoolBids(poolBidsContract);
    return poolBids.all(poolId);
  }

  function findBidById(uint256 poolId, uint256 bidId) public view returns (IPoolBids.Bid memory) {
    IPoolBids poolBids = IPoolBids(poolBidsContract);
    return poolBids.find(poolId, bidId);
  }

  function findBidderByAmount(uint256 poolId, uint256 amount) public view returns (address) {
    IPoolBids poolBids = IPoolBids(poolBidsContract);
    return poolBids.findBidderByAmount(poolId, amount);
  }

  function bidAmounts(uint256 poolId) public view returns (uint256[] memory) {
    IPoolBids poolBids = IPoolBids(poolBidsContract);
    return poolBids.amounts(poolId);
  }

  function bidExistsInPool(uint256 poolId, uint256 amount) public view returns (bool) {
    IPoolBids poolBids = IPoolBids(poolBidsContract);
    return poolBids.existsInPool(poolId, amount);
  }

  function bidsInPoolForAccount(uint256 poolId, address account) public view returns (IPoolBids.Bid[] memory) {
    IPoolBids poolBids = IPoolBids(poolBidsContract);
    return poolBids.inPoolForAccount(poolId, account);
  }

  function ceiling(uint256 poolId) public view returns (uint256) {
    IPools pools = IPools(poolContract);
    return pools.ceiling(poolId);
  }

  function bidSpace(uint256 poolId) public view returns (uint256) {
    IPoolBids poolBids = IPoolBids(poolBidsContract);
    return poolBids.cubicSpace(poolId);
  }

  function minBid(uint256 poolId) public view returns (uint256) {
    IPools pools = IPools(poolContract);
    uint256 currentCeiling = pools.ceiling(poolId);
    return (currentCeiling * _window) / 10000;
  }

  // CROSSOVER

  function spread(uint256 poolId) public view returns (uint256, uint256) {
    uint256 currentFloor = floor(poolId);
    uint256 currentCeiling = ceiling(poolId);

    if (currentCeiling > currentFloor) {
      return (1, currentCeiling - currentFloor);
    } else {
      return (0, currentFloor - currentCeiling); // default: 0, listing floor above bid ceiling
    }
  }

  // FUNCTIONS FOR REWARDS

  function totalPoolWeight() public view returns (uint256) {
    IPools pools = IPools(poolContract);
    uint256 total = 0;
    IPools.Pool[] memory allPools = pools.all();
    for (uint i = 0; i < allPools.length; i++) {
      total += allPools[i].weight;
    }
    return total;
  }

  function weights() public view returns (uint256[] memory) {
    IPools pools = IPools(poolContract);
    IPools.Pool[] memory allPools = pools.all();
    
    return _weights(allPools);
  }

  function randomPool(uint256 randomness) public view returns (IPools.Pool memory) {
    IPools pools = IPools(poolContract);
    IPools.Pool[] memory allPools = pools.all();

    uint256[] memory weightedPoolIds = _weights(allPools);
    uint256 position = randomness % weightedPoolIds.length;

    return pools.find(weightedPoolIds[position]);
  }

  function randomPoolId(uint256 randomness) public view returns (uint256) {
    return randomPool(randomness).id;
  }

  // return 0 for bids, 1 for listings
  function randomPoolSide(uint256 poolId, uint256 randomness) public view returns (uint256) {
    IPools pools = IPools(poolContract);
    IPools.Pool memory pool = pools.find(poolId);

    uint256 overall = pool.bidsWeight + pool.listingsWeight;

    uint256[] memory w = new uint256[](overall);
    uint256 position = 0;

    for (uint i = 0; i < pool.bidsWeight; i++) {
      w[position] = 0;
      position++;
    }

    for (uint i = 0; i < pool.listingsWeight; i++) {
      w[position] = 1;
      position++;
    }

    uint256 index = randomness % w.length;

    return w[index];
  }

  function randomPrice(uint256 poolId, uint256 randomness) public view returns (uint256) {
    IPoolListings poolListings = IPoolListings(poolListingsContract);
    uint256 cubSpace = poolListings.cubicSpace(poolId);

    uint256 selector = randomness % cubSpace;
    uint256[] memory prices = poolListings.prices(poolId);
    uint256 acc = 0;
    uint256 price;

    for (uint i = 0; i < prices.length; i++) {
      uint256 num = i + 1;
      uint256 cubed = num * num * num;

      if (selector >= acc && selector < (cubed + acc)) {
        price = prices[prices.length - num];
        break;
      }

      acc += cubed;
    }

    return price;
  }

  function randomBid(uint256 poolId, uint256 randomness) public view returns (uint256) {
    IPoolBids poolBids = IPoolBids(poolBidsContract);
    uint256 cubSpace = poolBids.cubicSpace(poolId);

    uint256 selector = randomness % cubSpace;
    uint256[] memory amounts = poolBids.amounts(poolId);
    uint256 acc = 0;
    uint256 amount;

    for (uint i = 0; i < amounts.length; i++) {
      uint256 num = i + 1;
      uint256 cubed = num * num * num;

      if (selector >= acc && selector < (cubed + acc)) {
        amount = amounts[i];
        break;
      }

      acc += cubed;
    }

    return amount;
  }

  // PRIVATE

  function _weights(IPools.Pool[] memory pools) private view returns (uint256[] memory) {
    uint256 totalWeight = totalPoolWeight();

    uint256[] memory w = new uint256[](totalWeight);
    uint256 position = 0;

    for (uint i = 0; i < pools.length; i++) {
      for (uint j = 0; j < pools[i].weight; j++) {
        w[position] = pools[i].id;
        position++;
      }
    }

    return w;
  }

  function handleFloorChanges(uint256 poolId, uint256 currentFloor) private {
    IPools pools = IPools(poolContract);
    IPoolListings poolListings = IPoolListings(poolListingsContract);

    uint256 listingsLength = poolListings.all(poolId).length;

    if (listingsLength > 1) {
      poolListings.sortPrices(poolId);
    }

    if (listingsLength > 0) {
      pools.setFloor(poolId,listingPrices(poolId)[0]);
    } else {
      pools.setFloor(poolId,0);
    }

    if (pools.floor(poolId) != currentFloor) {
      emit FloorChange(poolId, pools.floor(poolId));
    }
  }

  function handleCeilingChanges(uint256 poolId, uint256 currentCeiling) private {
    IPools pools = IPools(poolContract);
    IPoolBids poolBids = IPoolBids(poolBidsContract);

    uint256 bidsLength = poolBids.all(poolId).length;

    if (bidsLength > 1) {
      poolBids.sortAmounts(poolId);
    }

    if (bidsLength > 0) {
      pools.setCeiling(poolId, bidAmounts(poolId)[bidAmounts(poolId).length -1]);
    } else {
      pools.setCeiling(poolId, 0);
    }

    if (pools.ceiling(poolId) != currentCeiling) {
      emit CeilingChange(poolId, pools.ceiling(poolId));
    }
  }

  // ADMIN

  function setListingsAddress(address poolListingsContract_) public onlyOwner {
    poolListingsContract = poolListingsContract_;
  }

  function setBidsAddress(address poolBidsContract_) public onlyOwner {
    poolBidsContract = poolBidsContract_;
  }

  // window: the % above/below floor/ceiling allowed
  function setWindow(uint256 window_) public onlyOwner {
    _window = window_;
  }

  function setActive(bool active_) public onlyOwner {
    _active = active_;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPools {

  struct Pool {
    uint256 id;
    address collectionAddress;
    uint256 weight;
    uint256 maxEntries;
    uint256 bidsWeight;
    uint256 listingsWeight;
    bool active;
  }

  function create(
    address collectionAddress, 
    uint256 weight, 
    uint256 maxEntries,
    uint256 bidsWeight,
    uint256 listingsWeight
  ) external;

  function activate(uint256 id) external;
  function deactivate(uint256 id) external;
  function setWeight(uint256 id, uint256 weight) external;
  function setSideWeights(uint256 id, uint256 bidsWeight, uint256 listingsWeight) external;
  function setMaxEntries(uint256 id, uint256 maxEntries) external;
  function setFloor(uint256 id, uint256 floor) external;
  function setCeiling(uint256 id, uint256 ceiling) external;

  function all() external view returns (Pool[] memory);
  function active() external view returns (Pool[] memory);
  function inactive() external view returns (Pool[] memory);
  function find(uint256 id) external view returns (Pool memory);
  function lookupPoolId(address collectionAddress) external view returns (uint256);
  function floor(uint256 id) external view returns (uint256);
  function ceiling(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPoolListings {
  struct Listing {
    uint256 id;
    uint256 poolId;
    address collectionAddress;
    address ownerAddress;
    uint256 tokenId;
    uint256 price;
    uint256 timestamp;
    bool active;
  }

  function create(
    uint256 poolId,
    address collectionAddress,
    address ownerAddress,
    uint256 tokenId,
    uint256 price,
    uint256 poolMax
  ) external;

  function reducePrice(
    uint256 poolId,
    uint256 oldPrice,
    uint256 newPrice,
    address sender
  ) external;

  function fulfill(
    uint256 poolId,
    uint256 listingId,
    address buyer
  ) external payable;

  function destroy(
    uint256 poolId,
    uint256 listingId,
    address sender
  ) external;

  function fulfillWithBid(
    uint256 poolId,
    uint256 tokenId,
    address bidder,
    address sender
  ) external;

  function sortPrices(uint256 poolId) external;

  function all(uint256 poolId) external view returns (Listing[] memory);
  function find(uint256 poolId, uint256 id) external view returns (Listing memory);
  function findListerByPrice(uint256 poolId, uint256 price) external view returns (address);
  function prices(uint256 poolId) external view returns (uint256[] memory);
  function cubicSpace(uint256 poolId) external view returns (uint256);
  function inPoolForAccount(uint256 poolId, address account) external view returns (Listing[] memory);
  function priceExistsInPool(uint256 poolId, uint256 price) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPoolBids {
  struct Bid {
    uint256 id;
    uint256 poolId;
    address collectionAddress;
    address bidderAddress;
    uint256 amount;
    uint256 timestamp;
    bool active;
  }

  function create(
    uint256 poolId,
    address collectionAddress,
    address bidderAddress,
    uint256 amount,
    uint256 poolMax
  ) external;

  function destroy(
    uint256 poolId,
    uint256 bidId,
    address sender
  ) external;

  function raiseBid(
    uint256 poolId,
    uint256 oldPrice,
    uint256 newPrice,
    address sender
  ) external;

  function accept(
    uint256 poolId,
    uint256 bidId,
    address collectionAddress,
    uint256 tokenId,
    address sender
  ) external;

  function sortAmounts(uint256 poolId) external;

  function all(uint256 poolId) external view returns (Bid[] memory);
  function find(uint256 poolId, uint256 offerId) external view returns (Bid memory);
  function findBidderByAmount(uint256 poolId, uint256 amount) external view returns (address);
  function existsInPool(uint256 poolId, uint256 amount) external view returns (bool);
  function cubicSpace(uint256 poolId) external view returns (uint256);
  function inPoolForAccount(uint256 poolId, address account) external view returns (Bid[] memory);
  function amounts(uint256 poolId) external view returns (uint256[] memory);
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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