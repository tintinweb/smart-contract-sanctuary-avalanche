// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Item.sol";
import "./Order.sol";
import "./Counters.sol";

contract ItemManager is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private itemIndex;
    enum ItemState {
        Created,
        Sold,
        Delivered,
        Cancelled
    }
    struct S_Item {
        Item _item;
        Order _order;
        ItemManager.ItemState _state;
    }
    mapping(uint256 => S_Item) public items;

    event ItemStateChanged(uint256 indexed itemIndex, uint8 state);

    modifier itemFound(uint256 _itemIndex) {
        require(
            _itemIndex < itemIndex.current(),
            "ItemManager: item not found!"
        );
        _;
    }

    modifier onlyItemOwner(uint256 _itemIndex) {
        require(
            items[_itemIndex]._item.owner() == _msgSender(),
            "ItemManager: caller is not the Item owner"
        );
        _;
    }

    // 0x3031303230333034000000000000000000000000000000000000000000000000
    // 0x4d741b6f1eb29cb2a9b9911c82f56fa8d73b04959d3d9d222895df6c0b28aa15
    
    function createItem(
        string memory _name,
        string memory _specifications,
        bytes32 _rawDataHash,
        uint256 _price
    ) public {
        uint256 curentItemIndex = itemIndex.current();
        Item item = new Item(
            this,
            _msgSender(),
            _name,
            _specifications,
            _rawDataHash,
            _price,
            curentItemIndex
        );
        S_Item storage s_item = items[curentItemIndex];
        s_item._item = item;
        s_item._state = ItemState.Created;
        emit ItemStateChanged(curentItemIndex, uint8(s_item._state));
        itemIndex.increment();
    }

    function triggerDelivered(uint256 _itemIndex) public itemFound(_itemIndex) {
        require(
            items[_itemIndex]._state == ItemState.Sold,
            "ItemManager: this item has not been purchased"
        );
        require(
            address(items[_itemIndex]._order) == _msgSender(),
            "ItemManager: this function must be call from Order contract"
        );
        items[_itemIndex]._item.transferOwnership(items[_itemIndex]._order.purchaser(), address(items[_itemIndex]._order));
        items[_itemIndex]._state = ItemState.Delivered;
        emit ItemStateChanged(_itemIndex, uint8(items[_itemIndex]._state));
    }

    function triggerPayment(
        uint256 _itemIndex,
        address _purchaser,
        address _owner
    ) public payable itemFound(_itemIndex) {
        S_Item storage s_item = items[_itemIndex];
        require(
            _msgSender() == address(s_item._item),
            "ItemManager: this function must be call from Item contract"
        );
        require(
            s_item._state == ItemState.Created,
            "ItemManager: this item is further on chain"
        );
        Order order = new Order{value: msg.value}(
            _purchaser,
            _owner,
            s_item._item
        );
        s_item._order = order;
        s_item._state = ItemState.Sold;
        emit ItemStateChanged(_itemIndex, uint8(s_item._state));
    }

    function triggerResale(uint256 _itemIndex, uint256 _price)
        public
        itemFound(_itemIndex)
        onlyItemOwner(_itemIndex)
    {
        S_Item storage s_item = items[_itemIndex];
        require(
            s_item._state == ItemState.Delivered || s_item._state == ItemState.Cancelled,
            'ItemManager: This item state must be "Delivered" or "Cancelled" to make for resale!'
        );
        s_item._item.changePrice(_price);
        s_item._state = ItemState.Created;
        emit ItemStateChanged(_itemIndex, uint8(s_item._state));
    }

    function triggerCancel(uint256 _itemIndex)
        public
        itemFound(_itemIndex)
    {
        S_Item storage s_item = items[_itemIndex];
        require(
            address(items[_itemIndex]._order) == _msgSender(),
            "ItemManager: this function must be call from Order contract"
        );
        require(
            s_item._state == ItemState.Sold,
            "ItemManager: this item is further on chain"
        );
        s_item._item.changePrice(0);
        s_item._state = ItemState.Cancelled;
        emit ItemStateChanged(_itemIndex, uint8(s_item._state));
    }

    function currentItemIndex() public view returns (uint256) {
        return itemIndex.current();
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Timers.sol)

pragma solidity ^0.8.11;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.11;

import "./Context.sol";

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
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Context.sol";
import "./Timers.sol";
import "./Item.sol";
import "./ItemManager.sol";

contract Order is Context {
    using Timers for Timers.Timestamp;

    Timers.Timestamp private _timer;
    // address public shipper;
    address public purchaser;
    address public seller;
    Item public itemContract;
    Order.OrderState public state;

    enum OrderState {
        Placed,
        Confirmed,
        Shipping,
        Received,
        Cancelled
    }

    event OrderStateChanged(address sender, uint8 state, uint64 deadline);

    constructor(
        address _purchaser,
        address _seller,
        Item _itemContract
    ) payable {
        // 24 hours equal to 86400 seconds
        uint64 deadline = uint64(block.timestamp + 86400);
        _timer.setDeadline(deadline);
        purchaser = _purchaser;
        seller = _seller;
        itemContract = _itemContract;
        state = OrderState.Placed;
        emit OrderStateChanged(_msgSender(), uint8(state), deadline);
    }

    modifier onlySeller() {
        require(seller == _msgSender(), "Order: caller is not the seller");
        _;
    }

    modifier onlyPurchaser() {
        require(
            purchaser == _msgSender(),
            "Order: caller is not the purchaser"
        );
        _;
    }

    // modifier onlyShipper() {
    //     require(shipper == _msgSender(), "Order: caller is not the purchaser");
    //     _;
    // }

    modifier isPending() {
        require(_timer.isPending(), "Order: transaction is expired");
        _;
    }

    function triggerConfirm() public onlySeller isPending {
        require(
            state == OrderState.Placed,
            'Order: state must be "Placed" to trigger confirm'
        );
        // 48 hours equal to 172800 seconds
        uint64 deadline = uint64(block.timestamp + 172800);
        _timer.setDeadline(deadline);
        state = OrderState.Confirmed;
        emit OrderStateChanged(_msgSender(), uint8(state), deadline);
    }

    function triggerShipping()
        public
        // onlyShipper
        onlySeller
        isPending
    {
        require(
            state == OrderState.Confirmed,
            'Order: state must be "Confirmed" to trigger shipping'
        );
        // 7 days equal to 604800 seconds
        uint64 deadline = uint64(block.timestamp + 604800);
        _timer.setDeadline(deadline);
        state = OrderState.Shipping;
        emit OrderStateChanged(_msgSender(), uint8(state), deadline);
    }

    function triggerReceived() public onlyPurchaser isPending {
        require(
            state == OrderState.Shipping,
            'Order: state must be "Shipping" to Received'
        );
        _timer.reset();

        itemContract.parentContract().triggerDelivered(itemContract.indexInParentContract());
        payable(seller).transfer(address(this).balance);
        state = OrderState.Received;
        emit OrderStateChanged(_msgSender(), uint8(state), 0);
    }

    function triggerCancel() public onlyPurchaser {
        require(
            state == OrderState.Placed || _timer.isExpired(),
            "Order: transaction is pending or delivered, can not cancel now"
        );
        _timer.reset();
        state = OrderState.Cancelled;
        itemContract.parentContract().triggerCancel(itemContract.indexInParentContract());
        payable(purchaser).transfer(address(this).balance);
        emit OrderStateChanged(_msgSender(), uint8(state), 0);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getDeadline() public view returns (uint64) {
        return _timer.getDeadline();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Context.sol";
import "./ItemManager.sol";

contract Item is Context {
    ItemManager public parentContract;
    address public owner;
    bytes32 public rawDataHash;
    string public name;
    string public specifications;
    uint256 public indexInParentContract;
    uint256 public price;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        address recipt
    );

    constructor(
        ItemManager _parentContract,
        address _owner,
        string memory _name,
        string memory _specifications,
        bytes32 _rawDataHash,
        uint256 _price,
        uint256 _indexInParentContract
    ) {
        parentContract = _parentContract;
        owner = _owner;
        name = _name;
        specifications = _specifications;
        rawDataHash = _rawDataHash;
        price = _price;
        indexInParentContract = _indexInParentContract;
    }

    function changePrice(uint256 _newPrice) public {
        require(
            owner == _msgSender() || address(parentContract) == _msgSender(),
            "Item: caller is not the owner or parent contract"
        );
        price = _newPrice;
    }

    function giveOwnershipTo(address _newOwner) public {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        require(price == 0, "Item: this Item is for sale");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner, address(0));
    }

    function transferOwnership(address _newOwner, address _recipt) public {
        require(
            address(parentContract) == _msgSender(),
            "Item: caller is not the owner or parent contract"
        );
        address oldOwner = owner;
        owner = _newOwner;
        price = 0;
        emit OwnershipTransferred(oldOwner, _newOwner, _recipt);
    }

    receive() external payable {
        require(price > 0, "Item: this Item is not for sale");
        require(price == msg.value, "Item: only full payments accepted");
        parentContract.triggerPayment{value: msg.value}(
            indexInParentContract,
            _msgSender(),
            owner
        );
    }

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.11;

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

    // function decrement(Counter storage counter) internal {
    //     uint256 value = counter._value;
    //     require(value > 0, "Counter: decrement overflow");
    //     unchecked {
    //         counter._value = value - 1;
    //     }
    // }

    // function reset(Counter storage counter) internal {
    //     counter._value = 0;
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.11;

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