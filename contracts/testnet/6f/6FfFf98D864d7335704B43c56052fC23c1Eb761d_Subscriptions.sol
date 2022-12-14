/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract Subscriptions is Ownable {
  struct Product {
    uint256 billingAmount;
    uint256 billingInterval;
    uint256 trialPeriod; // days
    address beneficiar;
    bool archived;
  }

  struct Subscription {
    address wallet;
    uint256 createdAt;
    bytes32 productId;
    uint256 billedAt;
    uint256 finished;
  }

  mapping (bytes32 => Product) public products;
  mapping (bytes32 => Subscription) public subscriptions;

  mapping (address => mapping (bytes32 => bytes32)) private subscriptionTree; // wallet => productId => subscriptionId

  event ProductCreated(bytes32 id);
  event SubscriptionCreated(bytes32 id);

  error AlreadySubscribed(address wallet, bytes32 productId);

  /* 0xa798caeb */
  function createProduct(bytes32 id, uint256 billingAmount, uint256 billingInterval, uint256 trialPeriod, address beneficiar) external {
    // TODO validate period
    // TODO validate if wallet is eligible to create this
    Product memory product = Product({
      billingAmount: billingAmount,
      billingInterval: billingInterval,
      trialPeriod: trialPeriod,
      beneficiar: beneficiar,
      archived: false
    });
    products[id] = product;
    emit ProductCreated(id);
  }

  /* 0x0f574ba7 */
  function subscribe(bytes32 id, bytes32 productId) external {
    if (subscriptionTree[msg.sender][productId] != bytes32(0)) {
      revert AlreadySubscribed(msg.sender, productId);
    }
    Subscription memory subscription = Subscription({
      wallet: msg.sender,
      productId: productId,
      createdAt: block.timestamp,
      billedAt: 0,
      finished: 0
    });
    subscriptionTree[msg.sender][productId] = id;
    subscriptions[id] = subscription;
    emit SubscriptionCreated(id);
  }

}