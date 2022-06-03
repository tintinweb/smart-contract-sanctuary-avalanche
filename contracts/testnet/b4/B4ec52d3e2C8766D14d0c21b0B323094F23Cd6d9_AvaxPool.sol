//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract AvaxPool is Ownable, ReentrancyGuard {
    uint256 public unclaimedRewards; // S0

    mapping(address => uint256) public deposits; // S1
    address[] internal depositors;

    mapping(address => uint256) public rewards; // S1
    

    event Deposit(address indexed depositor, uint256 amount);
    event Reward(address indexed distributor, uint256 amount);
    event Withdraw(address indexed receiver, uint256 amount);
    

    /// @notice Accepts ETH/AVAX that grows over time
    /// @dev Accepts native token (ETH/AVAX) and adds it into the pool. Saves the sender address. 
    function deposit() public payable {        
        require(msg.value > 0, "No value deposited");

        deposits[msg.sender] += msg.value;        
        depositors.push(msg.sender);

        // initialize rewards will the deposit values
        // incase no more rewards accrues, rewards[msg.sender]
        // will be return on withdraw
        rewards[msg.sender] = deposits[msg.sender];

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Lets a user withdraws funds plus rewards (if any)
    /// @dev Explain to a developer any extra details
    /// @return amount msg.sender's balance plus rewards acrued
    function withdraw() public nonReentrant returns (uint256 amount) {                
        amount = rewards[msg.sender];

        require(deposits[msg.sender] > 0, "No deposit found");
        require(address(this).balance >= amount, "Pool out of liquidity");
        
        payable(msg.sender).transfer(amount); 
        
        deposits[msg.sender] = 0;
        rewards[msg.sender] = 0;
        uint256 d;
        uint256 depositorIdx;
        for (d = 0; d < depositors.length; d++) {
            if (depositors[d] == msg.sender) {
                depositorIdx = d;
                break;
            }
        }
        removeDepositor(depositorIdx);                
    }
    
    /// @notice Allows the 'team' to send rewards
    /// @dev Explain to a developer any extra details        
    function reward() public payable onlyOwner {
        // team members are allowed to deposit and anytime
        // if they depoist before there are any depositors,
        // these funds will be locked up in `unclaimedRewards`
        // the 'team' can re-claim them later
        if (depositors.length == 0) {
            unclaimedRewards += msg.value;
        } else {
            // distribute rewards            
            uint256 d;
            for (d = 0; d < depositors.length; d++) {                
                rewards[depositors[d]] = calculateRewards(depositors[d]);
            }
        }        
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details    
    function withdrawUnclaimedRewards() public onlyOwner nonReentrant {
        payable(msg.sender).transfer(unclaimedRewards);
        unclaimedRewards = 0;
    }

    /// @dev Explain to a developer any extra details
    /// @param index that is to be deleted
    function removeDepositor(uint index) private {
        require(index < depositors.length, "Invalid depositor index");
        depositors[index] = depositors[depositors.length-1];
        depositors.pop();
    }
        
    /// @dev based on current balance, determine the `msg.sender`'s 
    /// share and returns the their rewards
    /// @param depositor address whose rewards are to be calculated
    /// @return depositorReward based on their share of liquidity
    function calculateRewards(address depositor) private view returns (uint256 depositorReward) {                
        // msg.value will be included in the contract's balance        
        uint256 depositorBalance = deposits[depositor];
        uint256 numerator = depositorBalance * (address(this).balance - unclaimedRewards);
        uint256 denominator = address(this).balance - msg.value - unclaimedRewards;
        depositorReward = numerator / denominator;                
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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