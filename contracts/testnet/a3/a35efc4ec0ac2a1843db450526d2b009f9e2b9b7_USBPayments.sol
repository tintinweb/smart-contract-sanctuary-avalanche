/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


struct Package {
    bool active;
    string name;
    uint256 subscriptionTime;
    uint256 price;
    uint256 DBCPackageId;
}

struct Subscription {
    uint256 currentPackageId;
    uint256 endTimestamp;
}

struct Payment {
    address user;
    uint256 packageId;
    uint256 paymentValue;
}


contract USBPayments is Ownable {

    address public tokenAddress;

    bool public isActive = false;
    address payable public paymentAddress;

    //Stores subscription packages, identified by package id
    mapping(uint256 => Package) public packages;
    uint256 public packageCount;

    //Stores all payments, identified by payment id
    mapping(uint256 => Payment) public payments;
    uint256 public paymentsCount;
    
    //Stores subscriptions per user address
    mapping(address => Subscription) public subscriptions;

    event USBPurchase(address buyer, uint256 packageId, uint256 paymentId, uint256 amountPaid, uint256 newFinishTimestamp);

    constructor(address payable _paymentAddress, address _tokenAddress) {
        require(_paymentAddress != address(0), "Payment address can't be 0");
        require(_tokenAddress != address(0), "Token address can't be 0");

        paymentAddress = _paymentAddress;
        tokenAddress = _tokenAddress;
    }

    /// @notice Admin function - allows contract owner to update the address of the token used for all future payments
    /// @param _tokenAddress New token address (address)
    function setPaymentTokenAddress(address _tokenAddress) public onlyOwner {
        require(tokenAddress != _tokenAddress, "No change");
        tokenAddress = _tokenAddress;
    }

    /// @notice Admin function - allows contract owner to update the payment address (it will receive all payments going through this contract)
    /// @param _paymentAddress New payment address (address)
    function setPaymentAddress(address payable _paymentAddress) public onlyOwner {
        require(paymentAddress != _paymentAddress, "No change");
        paymentAddress = _paymentAddress;
    }

    /// @notice Admin function - allows contract owner to create a new package - it becomes active by default
    /// @param _name New "name" value (string)
    /// @param _subscriptionTime New "name" value (uint256)
    /// @param _price New "price" value (uint256)
    function addPackage(string memory _name, uint256 _subscriptionTime, uint256 _price, uint256 _DBCPackageId) public onlyOwner {
        require(_subscriptionTime > 0, "Subscription time must be more than 0");

        packages[packageCount] = Package(true, _name, _subscriptionTime, _price, _DBCPackageId);
        packageCount++;
    }

    /// @notice Admin function - allows contract owner to update params of a specific package
    /// @param packageId The id of the subscription package to be updated
    /// @param _active New "active" value (bool)
    /// @param _name New "name" value (string)
    /// @param _subscriptionTime New "name" value (uint256)
    /// @param _price New "price" value (uint256)
    function updatePackage(uint256 packageId, bool _active, string memory _name, uint256 _subscriptionTime, uint256 _price) public onlyOwner {
        require(packageId < packageCount, "This package doesn't exist");
        packages[packageId].active = _active;
        packages[packageId].name = _name;
        packages[packageId].subscriptionTime = _subscriptionTime;
        packages[packageId].price = _price;

    }

    /// @notice Admin function - enables or disables a package. Disabled packages cannot be purchased
    /// @param packageId The id of the subscription package to be updated (uint256)
    /// @param _active New "active" value (bool)
    function setPackageActive(uint256 packageId, bool _active) public onlyOwner {
        require(packageId < packageCount, "This package doesn't exist");
        require(_active != packages[packageId].active, "No change");

        packages[packageId].active = _active;
    }

    /// @notice Admin function - allows the contract owner to enable or disable the purchase function for all packages
    /// @param _active New "active" value (bool)
    function setActive(bool _active) public onlyOwner {
        require(_active != isActive, "No change");

        isActive = _active;
    }

    /// @notice Purchase a subscription package
    /// @param packageId The id of the subscription package that the user is buying (uint256)
    /// @return Transaction success (bool)
    function purchase(uint256 packageId) public returns(bool) {
        require(isActive == true, "Payments are currently disabed");
        require(packageId < packageCount, "This package doesn't exist");
        require(packages[packageId].active == true, "This package is currently disabled");
        require(IERC20(tokenAddress).transferFrom(msg.sender, paymentAddress, packages[packageId].price), "Token transfer failed");

        subscriptions[msg.sender].currentPackageId = packageId;

        uint256 currentEndTimestamp = subscriptions[msg.sender].endTimestamp;
        if(currentEndTimestamp == 0) {
            currentEndTimestamp = block.timestamp;
        }

        subscriptions[msg.sender].endTimestamp = currentEndTimestamp + packages[packageId].subscriptionTime;

        uint256 paymentId = paymentsCount;
        payments[paymentId] = Payment(msg.sender, packageId, packages[packageId].price);
        paymentsCount++;

        emit USBPurchase(msg.sender, packageId, paymentId, packages[packageId].price, subscriptions[msg.sender].endTimestamp);

        return true;
    }

    
    /// @notice Check if user's subscription is active at the moment of calling this function
    /// @param userAddress The address of a user account to check (address)
    /// @return is the subscription active? (bool)
    function userSubscriptionActive(address userAddress) public view returns(bool) {
        if(subscriptions[userAddress].endTimestamp >= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

}