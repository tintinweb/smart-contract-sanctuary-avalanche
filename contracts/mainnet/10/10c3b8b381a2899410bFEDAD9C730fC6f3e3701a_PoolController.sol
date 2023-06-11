// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPoolListings.sol";
import "./IPoolBids.sol";

contract PoolController is Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _poolIds;
  Counters.Counter private _listingIds;

  struct Pool {
    uint256 id;
    address collectionAddress;
    uint256 weight;
    uint256 maxEntries;
    bool active;
  }

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

  Pool[] private _pools;
  Pool[] private _activePools;
  Pool[] private _inactivePools;

  mapping (uint256 => uint256) private _poolFloors;
  mapping (uint256 => uint256) private _poolCeilings;

  address public _poolListingsContract;
  address public _poolBidsContract;

  mapping (address => uint256) private _poolIdsByAddress;
  mapping (uint256 => Pool) private _poolsById;

  uint256 public _window;

  constructor() {
    _window = 8000; // to be divided by 10,000
  }

  function add(address collectionAddress, uint256 weight, uint256 maxEntries) public onlyOwner {
    require(_poolIdsByAddress[collectionAddress] == 0, "A pool for that collection already exists.");
    _poolIds.increment();
    Pool memory pool = Pool(_poolIds.current(), collectionAddress, weight, maxEntries, true);
    _poolsById[_poolIds.current()] = pool;
    _poolIdsByAddress[collectionAddress] = _poolIds.current();
    _pools.push(pool);
    _activePools.push(pool);
  }

  function all() public view returns (Pool[] memory) {
    return _pools;
  }

  function active() public view returns (Pool[] memory) {
    return _activePools;
  }

  function inactive() public view returns (Pool[] memory) {
    return _inactivePools;
  }

  function find(uint256 id) public view returns (Pool memory) {
    return _poolsById[id];
  }

  function lookupPoolId(address collectionAddress) public view returns (uint256) {
    return _poolIdsByAddress[collectionAddress];
  }

  function sortListingPrices(uint256 poolId) public {
    IPoolListings poolListings = IPoolListings(_poolListingsContract);
    poolListings.sortPrices(poolId);
  }

  function priceExistsInPool(uint256 poolId, uint256 price) public view returns (bool) {
    IPoolListings poolListings = IPoolListings(_poolListingsContract);
    return poolListings.priceExistsInPool(poolId, price);
  }

  function bidExistsInPool(uint256 poolId, uint256 amount) public view returns (bool) {
    IPoolBids poolBids = IPoolBids(_poolBidsContract);
    return poolBids.existsInPool(poolId, amount);
  }

  function listingsInPoolForAccount(uint256 poolId, address account) public view returns (IPoolListings.Listing[] memory) {
    IPoolListings poolListings = IPoolListings(_poolListingsContract);
    return poolListings.inPoolForAccount(poolId, account);
  }

  function bidsInPoolForAccount(uint256 poolId, address account) public view returns (IPoolBids.Bid[] memory) {
    IPoolBids poolBids = IPoolBids(_poolBidsContract);
    return poolBids.inPoolForAccount(poolId, account);
  }

  function floor(uint256 poolId) public view returns (uint256) {
    return _poolFloors[poolId];
  }

  function ceiling(uint256 poolId) public view returns (uint256) {
    return _poolCeilings[poolId];
  }

  function list(uint256 poolId, ListingData[] memory listingsData) public {
    require(listingsData.length <= 10, "Exceeds maximum listings per transaction.");
    IPoolListings poolListings = IPoolListings(_poolListingsContract);

    uint256 currentFloor = _poolFloors[poolId];

    Pool memory pool = _poolsById[poolId];
    
    for (uint i = 0; i < listingsData.length; i++) {
      uint256 maxPrice = _poolFloors[poolId] + ((_poolFloors[poolId] * (10000 - _window)) / 10000);
      if (maxPrice > 0) { // will be 0 when no floor
        require(listingsData[i].newPrice <= maxPrice, "Price is too high.");
      }
      poolListings.create(poolId, pool.collectionAddress, msg.sender, listingsData[i].tokenId, listingsData[i].newPrice, pool.maxEntries);
    }

    poolListings.sortPrices(poolId);
    _poolFloors[poolId] = listingPrices(poolId)[0];

    if (_poolFloors[poolId] != currentFloor) {
      emit FloorChange(poolId, _poolFloors[poolId]);
    }
  }

  function bid(uint256 poolId, uint256[] memory prices) public {
    IPoolBids poolBids = IPoolBids(_poolBidsContract);
    Pool memory pool = _poolsById[poolId];
    for (uint i = 0; i < prices.length; i++) {
      uint256 minBid = (_poolCeilings[poolId] * _window) / 10000;
      require(prices[i] >= minBid, "Bid is too low.");
      poolBids.create(poolId, pool.collectionAddress, msg.sender, prices[i], pool.maxEntries);
    }

    poolBids.sortAmounts(poolId);
    _poolCeilings[poolId] = bidAmounts(poolId)[bidAmounts(poolId).length -1];
  }

  function acceptBids(uint256 poolId, BidFulfillment[] memory fulfillments) public {
    IPoolBids poolBids = IPoolBids(_poolBidsContract);
    for (uint i = 0; i < fulfillments.length; i++) {
      poolBids.accept(poolId, fulfillments[i].bidId, _poolsById[poolId].collectionAddress, fulfillments[i].tokenId, msg.sender);
    }

    if (poolBids.all(poolId).length > 0) {
      poolBids.sortAmounts(poolId);
      _poolCeilings[poolId] = bidAmounts(poolId)[bidAmounts(poolId).length -1];
    } else {
      _poolCeilings[poolId] = 0;
    }
  }

  function bids(uint256 poolId) public view returns (IPoolBids.Bid[] memory) {
    IPoolBids poolBids = IPoolBids(_poolBidsContract);
    return poolBids.all(poolId);
  }

  function bidAmounts(uint256 poolId) public view returns (uint256[] memory) {
    IPoolBids poolBids = IPoolBids(_poolBidsContract);
    return poolBids.amounts(poolId);
  }

  function findBidById(uint256 poolId, uint256 bidId) public view returns (IPoolBids.Bid memory) {
    IPoolBids poolBids = IPoolBids(_poolBidsContract);
    return poolBids.find(poolId, bidId);
  }

  function reducePrices(uint256 poolId, ListingData[] memory listingsData) public {
    uint256 currentFloor = _poolFloors[poolId];

    IPoolListings poolListings = IPoolListings(_poolListingsContract);
    for (uint i = 0; i < listingsData.length; i++) {
      require(listingsData[i].newPrice < listingsData[i].oldPrice, "Price must be lower.");
      uint256 maxPrice = _poolFloors[poolId] + ((_poolFloors[poolId] * (10000 - _window)) / 10000);
      require(listingsData[i].newPrice <= maxPrice, "Price is too high.");
      poolListings.reducePrice(poolId,  listingsData[i].oldPrice, listingsData[i].newPrice, msg.sender);
    }

    poolListings.sortPrices(poolId);
    _poolFloors[poolId] = listingPrices(poolId)[0];

    if (_poolFloors[poolId] != currentFloor) {
      emit FloorChange(poolId, _poolFloors[poolId]);
    }
  }

  function delist(uint256 poolId, uint256[] memory listingIds) public {
    IPoolListings poolListings = IPoolListings(_poolListingsContract);
    for (uint i = 0; i < listingIds.length; i++) {
      poolListings.destroy(poolId, listingIds[i], msg.sender);
    }

    if (poolListings.all(poolId).length > 0) {
      poolListings.sortPrices(poolId);
      _poolFloors[poolId] = listingPrices(poolId)[0];
    } else {
      _poolFloors[poolId] = 0;
    }
  }

  function cancelBids(uint256 poolId, uint256[] memory bidIds) public {
    uint256 currentFloor = _poolFloors[poolId];

    IPoolBids poolBids = IPoolBids(_poolBidsContract);
    for (uint i = 0; i < bidIds.length; i++) {
      poolBids.destroy(poolId, bidIds[i], msg.sender);
    }

    if (poolBids.all(poolId).length > 0) {
      poolBids.sortAmounts(poolId);
      _poolCeilings[poolId] = bidAmounts(poolId)[bidAmounts(poolId).length -1];
    } else {
      _poolCeilings[poolId] = 0;
    }

    if (_poolFloors[poolId] != currentFloor) {
      emit FloorChange(poolId, _poolFloors[poolId]);
    }
  }

  function raiseBids(uint256 poolId, BidData[] memory bidsData) public {
    IPoolBids poolBids = IPoolBids(_poolBidsContract);
    for (uint i = 0; i < bidsData.length; i++) {
      uint256 minBid = (_poolCeilings[poolId] * _window) / 10000;
      require(bidsData[i].newPrice > bidsData[i].oldPrice, "New bid must be higher.");
      require(bidsData[i].newPrice >= minBid, "Bid is too low.");
      poolBids.raiseBid(poolId, bidsData[i].oldPrice, bidsData[i].newPrice, msg.sender);
    }

    poolBids.sortAmounts(poolId);
    _poolCeilings[poolId] = bidAmounts(poolId)[bidAmounts(poolId).length -1];
  }

  // todo: non-reentrant
  function purchase(uint256 poolId, uint256[] memory listingIds) public payable {
    uint256 currentFloor = _poolFloors[poolId];

    IPoolListings poolListings = IPoolListings(_poolListingsContract);

    for (uint i = 0; i < listingIds.length; i++) {
      IPoolListings.Listing memory listing = poolListings.find(poolId, listingIds[i]);      
      poolListings.fulfill{value: listing.price}(poolId, listingIds[i], msg.sender);
    }

    if (poolListings.all(poolId).length > 0) {
      poolListings.sortPrices(poolId);
      _poolFloors[poolId] = listingPrices(poolId)[0];
    } else {
      _poolFloors[poolId] = 0;
    }

    if (_poolFloors[poolId] != currentFloor) {
      emit FloorChange(poolId, _poolFloors[poolId]);
    }
  }

  function cubicSpace(uint256 poolId) public view returns (uint256) {
    IPoolListings poolListings = IPoolListings(_poolListingsContract);
    return poolListings.cubicSpace(poolId);
  }

  function bidSpace(uint256 poolId) public view returns (uint256) {
    IPoolBids poolBids = IPoolBids(_poolBidsContract);
    return poolBids.cubicSpace(poolId);
  }

  function listings(uint256 poolId) public view returns (IPoolListings.Listing[] memory) {
    IPoolListings poolListings = IPoolListings(_poolListingsContract);
    return poolListings.all(poolId);
  }

  function listingPrices(uint256 poolId) public view returns (uint256[] memory) {
    IPoolListings poolListings = IPoolListings(_poolListingsContract);
    return poolListings.prices(poolId);
  }

  // question: does the order of the pools matter at all?
  // ===> if so, we need to update all items after the deactivated, not just switch with the last
  function deactivate(uint256 id) public onlyOwner {
    Pool storage pool = _poolsById[id];
    pool.active = false;

    for (uint i = 0; i < _activePools.length; i++) {
      if (_activePools[i].id == id) {
        Pool memory toRemove = _activePools[i];
        _activePools[i] = _activePools[_activePools.length - 1];
        _activePools[_activePools.length - 1] = toRemove;
      }
    }

    _inactivePools.push(pool);
    _activePools.pop();
  }

  // question: does the order of the pools matter at all?
  // ===> if so, we need to update all items after the deactivated, not just switch with the last
  function activate(uint256 id) public onlyOwner {
    Pool storage pool = _poolsById[id];
    pool.active = true;

    for (uint i = 0; i < _inactivePools.length; i++) {
      if (_inactivePools[i].id == id) {
        Pool memory toRemove = _inactivePools[i];
        _inactivePools[i] = _inactivePools[_inactivePools.length - 1];
        _inactivePools[_inactivePools.length - 1] = toRemove;
      }
    }

    _activePools.push(pool);
    _inactivePools.pop();
  }

  function setWeight(uint256 id, uint256 weight) public onlyOwner {
    Pool storage pool = _poolsById[id];
    pool.weight = weight;
  }

  function setListingsAddress(address poolListingsContract_) public onlyOwner {
    _poolListingsContract = poolListingsContract_;
  }

  function setBidsAddress(address poolBidsContract_) public onlyOwner {
    _poolBidsContract = poolBidsContract_;
  }

  function setWindow(uint256 window_) public onlyOwner {
    _window = window_;
  }
}

/*

TODO

EST: 4 hours
- finish/fix delist
---> simplify the logic a bit
- build out the ability to buy listings
- ability to make Bids
- ability to cancel Bids
- ability to accept Bids

EST: 3 hours
- add methods to randomly pick pool, side, winner
- hook up chainlink

*/

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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