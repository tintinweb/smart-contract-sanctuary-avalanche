/**
 *Submitted for verification at snowtrace.io on 2022-03-22
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/LockupHell.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/LockupHell.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/LockupHell.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}


/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/LockupHell.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0-only
pragma solidity >= 0.8.4 < 0.9.0;

////import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
////import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error Unauthorized();
error IndexInvalid();
error AlreadyClaimed();
error TooEarlyToClaim();
error TransferFrom();
error Transfer();

/// @title Lockup Hell.
/// @author Subgenix Research.
/// @notice This contract is used to lock users rewards for a specific amount of time.
/// @dev This contract is called from the vaultFactory to lock users rewards.
contract LockupHell is Ownable, ReentrancyGuard {

    // <--------------------------------------------------------> //
    // <------------------------ EVENTS ------------------------> //
    // <--------------------------------------------------------> // 

    /// @notice Emitted when user rewards are locked.
    /// @param user address, Owner of the rewards that are being locked up.
    /// @param shortLockupRewards uint256, short lockup period.
    /// @param longLockupRewards uint256, long lockup period.
    event RewardsLocked(address indexed user, uint256 shortLockupRewards, uint256 longLockupRewards);
    
    /// @notice Emitted when short lockup rewards are unlocked.
    /// @param user address, Owner of the rewards that are being unlocked.
    /// @param shortRewards uint256, amount of rewards unlocked.
    event UnlockShortLockup(address indexed user, uint256 shortRewards);
    
    /// @notice Emitted when long lockup rewards are unlocked.
    /// @param user address, Owner of the rewards that are being unlocked.
    /// @param longRewards uint256, amount of rewards unlocked.
    event UnlockLongLockup(address indexed user, uint256 longRewards);

    /// @notice Emitted when the owner of the contrct changes the shorter lockup time period.
    /// @param value uint32, the new value of the shorter lockup time period.
    event ShortLockupTimeChanged(uint32 value);

    /// @notice Emitted when the owner of the contrct changes the longer lockup time period.
    /// @param value uint32, the new value of the longer lockup time period.
    event LongLockupTimeChanged(uint32 value);

    /// @notice Emitted when the owner of the contract changes the % of the rewards that are
    ///         going to be locked up for a shorter period of time.
    /// @param percentage uint256, the new percentage (in thousands) of rewards that will be
    ///         locked up for a shorter period of time from now on.
    event ShortPercentageChanged(uint256 percentage);

    /// @notice Emitted when the owner of the contract changes the % of the rewards that are
    ///         going to be locked up for a longer period of time.
    /// @param percentage uint256, the new percentage (in thousands) of rewards that will be
    ///         locked up for a longer period of time from now on.
    event LongPercentageChanged(uint256 percentage);

    /// @notice Emitted when the owner changes the address of the vaultFactory variable.
    /// @param vaultAddress address, the new vault factory address.
    event VaultFactoryUpdated(address vaultAddress);

    // <--------------------------------------------------------> //
    // <----------------------- STRUCTS ------------------------> //
    // <--------------------------------------------------------> // 

    /// @notice Global rates defined by the owner of the contract.
    struct Rates {
        uint32 shortLockupTime;  // Shorter lockup period, i.e 07 days.
        uint32 longLockupTime;   // Longer lockup period, i.e 18 days.
        uint256 shortPercentage; // % of rewards locked up with a shorter period, defined in thousands i.e 18e16 = 18%.
        uint256 longPercentage;  // % of rewards locked up with a longer period, defined in thousands i.e. 12e16 = 12%.
    } 

    /// @notice Information about each `Lockup` the user has.
    struct Lockup {
        bool longRewardsCollected;    // True if user collected long rewards, false otherwise.
        bool shortRewardsCollected;   // True if user collected short rewards, false otherwise.
        uint32 longLockupUnlockDate;  // Time (in Unit time stamp) when long lockup rewards will be unlocked.
        uint32 shortLockupUnlockDate; // Time (in Unit time stamp) when short lockup rewards will be unlocked.
        uint256 longRewards;          // The amount of rewards available to the user after longLockupUnlockDate.
        uint256 shortRewards;         // The amount of rewards available to the user after shortLockupUnlockDate.
    }

    // <--------------------------------------------------------> //
    // <------------------- GLOBAL VARIABLES -------------------> //
    // <--------------------------------------------------------> // 
    
    /// @notice A mapping for each user's lockup i.e. `usersLockup[msg.sender][index]`
    ///         where the `index` refers to which lockup the user wants to look at.
    mapping(address => mapping(uint32 => Lockup)) public usersLockup;

    /// @notice A mapping for the total locked from each user.
    mapping(address => uint256) public usersTotalLocked;
    
    /// @notice A mapping to check the total of `lockup's` each user has. It can be seen like this:
    ///         `usersLockup[msg.sender][index]` where `index` <= `usersLockupLength[msg.sender]`.
    ///         Since the length of total lockups is the index of the last time the user claimed and
    ///         locked up his rewards. The index of the first lockup will be 1, not 0.
    mapping(address => uint32) public usersLockupLength;

    // Subgenix offical token, minted as a reward after each lockup.
    address internal immutable sgx;

    // vaultFactory contract address.
    address internal vaultFactory;

    // only the vaultFactory address can access function with this modifier.
    modifier onlyVaultFactory() {
        if (msg.sender != vaultFactory) { revert Unauthorized(); }
        _;
    }

    // Global rates.
    Rates public rates;
    
    constructor(address sgxAddress) {
        sgx = sgxAddress;
    }

    // <--------------------------------------------------------> //
    // <------------------ EXTERNAL FUNCTIONS ------------------> //
    // <--------------------------------------------------------> // 

    /// @notice Every time a user claim's his rewards, a portion of them are locked for a 
    ///         specific time period in this contract.
    /// @dev    Function called from the `VaultFactory` contract to lock users rewards. We use 
    ///         the 'nonReentrant' modifier from the `ReentrancyGuard` made by openZeppelin as 
    ///         an extra layer of protection against Reentrancy Attacks.
    /// @param user address, The user who's rewards are being locked.
    /// @param shortLockupRewards uint256, amount of rewards that are going to be locked up for 
    ///        a shorter period of time.
    /// @param longLockupRewards uint256, amount of rewards that are going to be locked up for 
    ///        a longer period of time.
    function lockupRewards(
        address user,
        uint256 shortLockupRewards, 
        uint256 longLockupRewards
    ) external nonReentrant onlyVaultFactory {

        // first it checks how many `lockups` the user has and sets
        // the next index to be 'length+1' and finally it updates the 
        // usersLockupLength to be 'length + 1'.
        uint32 index = usersLockupLength[user] + 1;
        usersLockupLength[user] = index;

        // Add the total value of lockup rewards to the users mapping.
        usersTotalLocked[user] += (shortLockupRewards + longLockupRewards);

        // Creates a new Lockup and add it to the new index location
        // of the usersLockup mapping.
        usersLockup[user][index] = Lockup({
                longRewardsCollected: false,
                shortRewardsCollected: false,
                longLockupUnlockDate: uint32(block.timestamp) + rates.longLockupTime,
                shortLockupUnlockDate: uint32(block.timestamp) + rates.shortLockupTime,
                longRewards: longLockupRewards,
                shortRewards: shortLockupRewards
        });

        // Transfer the rewards that are going to be locked up from the user to this
        // contract. They are placed in the end of the function after all the internal
        // work and state changes are done to avoid Reentrancy Attacks.
        bool success = IERC20(sgx).transferFrom(user, address(this), shortLockupRewards);
        if (!success) { revert TransferFrom(); }
        
        success = IERC20(sgx).transferFrom(user, address(this), longLockupRewards);
        if (!success) { revert TransferFrom(); }

        emit RewardsLocked(user, shortLockupRewards, longLockupRewards); 
    }

    /// @notice After the shorter lockup period is over, user can claim his rewards using this function.
    /// @dev Function called from the UI to allow user to claim his rewards. We use the 'nonReentrant' modifier
    ///      from the `ReentrancyGuard` made by openZeppelin as an extra layer of protection against Reentrancy Attacks.
    /// @param user address, the user who is claiming rewards. 
    /// @param index uint32, the index of the `lockup` the user is refering to.
    function claimShortLockup(address user, uint32 index) external nonReentrant {
        Lockup memory temp = usersLockup[user][index];
        
        // There are 3 requirements that must be true before the user can claim his
        // short lockup rewards:
        //
        // 1. The index of the 'lockup' the user is refering to must be a valid one.
        // 2. The `shortRewardsCollected` variable from the 'lockup' must be false, proving
        //    the user didn't collect his rewards yet.
        // 3. The block.timestamp must be greater than the short lockup period proposed
        //    when the rewards were first locked.
        //
        // If all three are true, the user can safely colect their short lockup rewards.
        if (msg.sender != user) { revert Unauthorized(); }
        if (usersLockupLength[user] < index) { revert IndexInvalid(); }
        if(temp.shortRewardsCollected) { revert AlreadyClaimed(); }
        if (block.timestamp <= temp.shortLockupUnlockDate) { revert TooEarlyToClaim(); }

        // Make a temporary copy of the user `lockup` and get the short lockup rewards amount.
        uint256 amount = temp.shortRewards;
        
        // Updates status of the shortRewardsCollected to true,
        // and changes the shortRewards to be collected to zero.
        temp.shortRewardsCollected = true;
        temp.shortRewards = 0;

        // Updates the users lockup with the one that was
        // temporarily created.
        usersLockup[user][index] = temp;

        // Takes the amount being transfered out of users total locked mapping.
        usersTotalLocked[user] -= amount;

        // Transfer the short rewards amount to user.
        bool success = IERC20(sgx).transfer(user, amount);
        if (!success) { revert Transfer(); }
        
        emit UnlockShortLockup(user, amount);
    }

    /// @notice After the longer lockup period is over, user can claim his rewards using this function.
    /// @dev Function called from the UI to allow user to claim his rewards. We use the 'nonReentrant' modifier
    ///      from the `ReentrancyGuard` made by openZeppelin as an extra layer of protection against Reentrancy Attacks.
    /// @param user address, the user who is claiming rewards.
    /// @param index uint32, he index of the `lockup` the user is refering to.
    function claimLongLockup(address user, uint32 index) external nonReentrant {
        
        // Make a temporary copy of the user `lockup` and get the long lockup rewards amount.
        Lockup memory temp = usersLockup[user][index];
        
        // There are 3 requirements that must be true before the user can claim his
        // long lockup rewards:
        //
        // 1. The index of the 'lockup' the user is refering to must be a valid one.
        // 2. The `longRewardsCollected` variable from the 'lockup' must be false, proving
        //    the user didn't collect his rewards yet.
        // 3. The block.timestamp must be greater than the long lockup period proposed
        //    when the rewards were first locked.
        //
        // If all three are true, the user can safely colect their long lockup rewards.
        if (msg.sender != user) { revert Unauthorized(); }
        if (usersLockupLength[user] < index) { revert IndexInvalid(); }
        if(temp.shortRewardsCollected) { revert AlreadyClaimed(); }
        if (block.timestamp <= temp.shortLockupUnlockDate) { revert TooEarlyToClaim(); }

        uint256 amount = temp.longRewards;
        
        // Updates status of the longRewardsCollected to true,
        // and changes the longRewards to be collected to zero.
        temp.longRewardsCollected = true;
        temp.longRewards = 0;

        // Updates the users lockup with the one that was
        // temporarily created.
        usersLockup[user][index] = temp;

        // Takes the amount being transfered out of users total locked mapping.
        usersTotalLocked[user] -= amount;

        // Transfer the long rewards amount to user.
        bool success = IERC20(sgx).transfer(user, amount);
        if (!success) { revert Transfer(); }

        emit UnlockLongLockup(user, amount);
    }

    // <--------------------------------------------------------> //
    // <-------------------- VIEW FUNCTIONS --------------------> //
    // <--------------------------------------------------------> // 

    /// @notice Allow the user to check how long `shortLockupTime` is set to.
    /// @return uint32, the value `shortLockupTime` is set to.
    function getShortLockupTime() external view returns(uint32) {
        return rates.shortLockupTime;
    }
    
    /// @notice Allow the user to check how long `longLockupTime` is set to.
    /// @return uint32, the value `longLockupTime` is set to.
    function getLongLockupTime() external view returns(uint32) { 
        return rates.longLockupTime;
    }

    /// @notice Allow the user to know what the `shortPercentage` variable is set to.
    /// @return uint32, the value the `shortPercentage` variable is set to in thousands i.e. 1200 = 12%.
    function getShortPercentage() external view returns(uint256) {
        return rates.shortPercentage;
    }

    /// @notice Allow the user to know what the `longPercentage` variable is set to.
    /// @return uint32, the value the `longPercentage` variable is set to in thousands i.e. 1800 = 12%.
    function getLongPercentage() external view returns(uint256) { 
        return rates.longPercentage;
    }

    // <--------------------------------------------------------> //
    // <---------------------- ONLY OWNER ----------------------> //
    // <--------------------------------------------------------> // 
    
    /// @notice Allows the owner of the contract to change the shorter lockup period all
    ///         users rewards are going to be locked up to.
    /// @dev Allows the owner of the contract to change the `shortLockupTime` value.
    function setShortLockupTime(uint32 value) external onlyOwner {
        rates.shortLockupTime = value;

        emit ShortLockupTimeChanged(value);
    }

    /// @notice Allows the owner of the contract to change the longer lockup period all
    ///         users rewards are going to be locked up to.    
    /// @dev Allows the owner of the contract to change the `longLockupTime` value.
    function setLongLockupTime(uint32 value) external onlyOwner { 
        rates.longLockupTime = value;

        emit LongLockupTimeChanged(value);
    }

    /// @notice Allows the owner of the contract change the % of the rewards that are
    ///         going to be locked up for a short period of time.
    /// @dev Allows the owner of the contract to change the `shortPercentage` value.    
    function setShortPercentage(uint256 percentage) external onlyOwner {
        rates.shortPercentage = percentage;

        emit ShortPercentageChanged(percentage);
    }

    /// @notice Allows the owner of the contract change the % of the rewards that are
    ///         going to be locked up for a long period of time.
    /// @dev Allows the owner of the contract to change the `long` value.
    function setLongPercentage(uint256 percentage) external onlyOwner { 
        rates.longPercentage = percentage;

        emit LongPercentageChanged(percentage);
    }

    /// @notice Updates the vaultFactory contract address.
    /// @param  vaultAddress address, vaultFactory contract address.
    function setVaultFactory(address vaultAddress) external onlyOwner {        
        vaultFactory = vaultAddress;
        emit VaultFactoryUpdated(vaultAddress);
    }
}