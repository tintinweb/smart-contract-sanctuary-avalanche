/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-23
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/security/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/StakingVe.sol

pragma solidity 0.8.9;

/// @title A vesting style staking contract with extendable linear decay
/// @author Auroter
/// @notice Allows you to lock tokens in exchange for governance tokens
/// @notice Locks can be extended or deposited into
/// @notice Maximum deposit duration is two years (104 weeks)
/// @dev Simply call stake(...) to create initial lock or extend one that already exists for the user




//import "hardhat/console.sol";

contract StakingVe is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Info pertaining to staking contract
    address public StakedToken; // An ERC20 Token to be staked (i.e. Axial)
    string public Name; // New asset after staking (i.e. sAxial)
    string public Symbol; // New asset symbol after staking (i.e. sAXIAL)
    uint256 private InterpolationGranularity = 1e18; // Note: ERC20.decimals() is for display and does not affect arithmetic!

    // Info pertaining to users
    address[] private Users; // An array containing all user addresses
    mapping(address => LockVe) private Locks; // A mapping of each users lock
    mapping(address => uint256) private LockedFunds; // A mapping of each users total deposited funds
    mapping(address => uint256) private DeferredFunds; // A mapping of vested funds the user wishes to leave unclaimed

    // Lock structure, only one of these is allowed per user
    // A DELTA can be derived as the degree of interpolation between the start/end block:
    // Delta = (end - now) / end - start
    // This can be used to determine how much of our staked token is unlocked:
    // currentAmountLocked = startingAmountLocked - (delta * startingAmountLocked)
    struct LockVe {
        uint256 StartBlockTime;
        uint256 EndBlockTime;
        uint256 StartingAmountLocked;
        bool Initialized;
    }

    /// @notice Constructor
    /// @param _stakedToken Address of the token our users will deposit and lock in exchange for governance tokens
    /// @param _name Desired name of our governance token
    /// @param _symbol Desired symbol of our governance token
    /// @param _governance Address of wallet which will be given adminstrative access to this contract
    constructor(
        address _stakedToken,
        string memory _name,
        string memory _symbol,
        address _governance
    ) {
        transferOwnership(_governance);
        StakedToken = _stakedToken;
        Name = _name;
        Symbol = _symbol;
    }

    /// @notice Calculate the number of vested tokens a user has not claimed, see also: getMyUnclaimed()
    /// @param _userAddr Address of any user to view the number of vested tokens they have not yet claimed
    /// @return Quantity of tokens which have vested but are unclaimed by the specified user
    function getUnclaimed(address _userAddr) public view returns (uint256) {
        uint256 totalFundsDeposited = LockedFunds[_userAddr] + DeferredFunds[_userAddr];
        uint256 currentBalance = getMyBalance();
        uint256 fundsToClaim = totalFundsDeposited - currentBalance;
        return fundsToClaim;
    }

    /// @notice Calculate the number of vested tokens invoking user has not claimed, see also: getUnclaimed()
    /// @return Quantity of tokens which have vested but are unclaimed by the invoking user
    function getMyUnclaimed() public view returns (uint256) {
        address userAddr = msg.sender;
        return getUnclaimed(userAddr);
    }

    /// @notice Calculate the number of tokens a user still has locked, see also: getMyBalance()
    /// @param _userAddr Address of any user to view the number of tokens they still have locked
    /// @return Quantity of tokens the user has locked
    function getBalance(address _userAddr) public view returns (uint256) {
        LockVe memory usersLock = Locks[_userAddr];

        uint256 currentTimestamp = block.timestamp;
        uint256 balance = 0;

        if (usersLock.EndBlockTime > currentTimestamp) {
            uint256 granularDelta = ((usersLock.EndBlockTime - currentTimestamp) * InterpolationGranularity) / (usersLock.EndBlockTime - usersLock.StartBlockTime);
            balance += (usersLock.StartingAmountLocked * granularDelta) / InterpolationGranularity;
        }
        return balance;
    }

    /// @notice Calculate the number of governance tokens allocated to a user by this contract, see also: getMyPower()
    /// @param _userAddr Address of any user to view the number of governance tokens currently awarded to them
    /// @return Quantity of governance tokens allocated to the user
    function getPower(address _userAddr) public view returns (uint256) {
        LockVe memory usersLock = Locks[_userAddr];

        uint256 currentTimestamp = block.timestamp;
        uint256 power = 0;

        if (usersLock.EndBlockTime > currentTimestamp) {
            // We need to accomodate for the fact that we are dealing only in whole numbers
            // uint256 delta = (lock.EndBlockTime - currentTimestamp) / (lock.EndBlockTime - lock.StartBlockTime);
            uint256 startingAmountAwarded = ((usersLock.EndBlockTime - usersLock.StartBlockTime) * usersLock.StartingAmountLocked) / 104 weeks;
            uint256 granularDelta = ((usersLock.EndBlockTime - currentTimestamp) * InterpolationGranularity) / (usersLock.EndBlockTime - usersLock.StartBlockTime);
            power += (startingAmountAwarded * granularDelta) / InterpolationGranularity;
        }
        return power;
    }

    /// @notice Retrieve a list of all users who have ever staked
    /// @return An array of addresses of all users who have ever staked
    function getAllUsers() public view returns (address[] memory) {
        return Users;
    }

    /// @notice Check if a user has ever created a Lock in this contract
    /// @param _userAddr Address of any user to check
    /// @dev This may be used by the web application to determine if the UI says "Create Lock" or "Add to Lock"
    /// @return True if the user has ever created a lock
    function isUserLocked(address _userAddr) public view returns (bool) {
        LockVe memory usersLock = Locks[_userAddr];
        return usersLock.Initialized;
    }

    /// @notice Check if invoking user has ever created a Lock in this contract
    /// @dev This may be used by the web application to determine if the UI says "Create Lock" or "Add to Lock"
    /// @return True if invoking user has ever created a lock
    function amILocked() public view returns (bool) {
        address userAddr = msg.sender;
        return isUserLocked(userAddr);
    }

    /// @notice View a users Lock, see also GetMyLock()
    /// @param _userAddr Address of any user to view all Locks they have ever created
    /// @dev This may be used by the web application for graphical illustration purposes
    /// @return Users Lock in the format of the LockVe struct
    function getLock(address _userAddr) public view returns (LockVe memory) {
        return Locks[_userAddr];
    }

    /// @notice View the invoking users Lock, see also GetLock()
    /// @dev This may be used by the web application for graphical illustration purposes
    /// @return Invoking users Lock in the format of the LockVe struct
    function getMyLock() public view returns (LockVe memory) {
        address userAddr = msg.sender;
        return getLock(userAddr);
    }

    /// @notice View the total quantity of deposit tokens the invoking user still has locked, see also GetBalance()
    /// @dev This may be used by the web application for display purposes
    /// @return Quantity of invoking users deposit tokens which are still locked by the contract 
    function getMyBalance() public view returns (uint256) {
        address userAddr = msg.sender;
        return getBalance(userAddr);
    }

    /// @notice View the total quantity of governance tokens the user currently has awarded to them, see also GetPower()
    /// @dev This may be used by the web application for display purposes
    /// @return Quantity of invoking users governance tokens awarded by the contract
    function getMyPower() public view returns (uint256) {
        address userAddr = msg.sender;
        return getPower(userAddr);
    }

    /// @notice Transfers deposit tokens which have decayed over some portion of the lock period back to their original owner
    /// @notice It is up to the user to invoke this in order to reclaim their original deposit tokens over time
    /// @dev This will need to be called by the web application via a button or some other means
    function claimMyFunds() external nonReentrant {
        address userAddr = msg.sender;
        uint256 totalFundsDeposited = LockedFunds[userAddr] + DeferredFunds[userAddr];
        uint256 currentBalance = getMyBalance();
        uint256 fundsToClaim = totalFundsDeposited - currentBalance;

        IERC20(StakedToken).safeTransfer(userAddr, fundsToClaim);

        LockedFunds[userAddr] = currentBalance;
        DeferredFunds[userAddr] = 0;
    }

    /// @notice Create/extend the duration of the invoking users lock and/or deposit additional tokens into it
    /// @param _duration Number of seconds the invoking user will extend their lock for
    /// @param _amount Number of additional tokens to deposit into the lock
    /// @param _deferUnclaimed If True, leaves any unclaimed vested balance in the staking contract
    function stake(uint256 _duration, uint256 _amount, bool _deferUnclaimed) public nonReentrant {
        require(_duration > 0 || _amount > 0, "null");

        // Retrieve list of locks the user has already created
        address userAddr = msg.sender;
        LockVe memory usersLock = Locks[userAddr];

        uint256 oldDurationRemaining = 0;

        // Keep track of new user or pre-existing lockout period
        if (!usersLock.Initialized) {
            Users.push(userAddr);
        } else if (block.timestamp < usersLock.EndBlockTime) {
            oldDurationRemaining = usersLock.EndBlockTime - block.timestamp;
        }

        require (oldDurationRemaining + _duration <= 104 weeks, ">2 years");

        // Receive the users tokens
        require(IERC20(StakedToken).balanceOf(userAddr) >= _amount, "!balance");
        IERC20(StakedToken).safeTransferFrom(userAddr,  address(this), _amount);

        // Account for balance / unclaimed funds
        uint256 totalFundsDeposited = LockedFunds[userAddr];
        uint256 oldBalance = getBalance(userAddr);
        uint256 fundsUnclaimed = totalFundsDeposited - oldBalance;
        if (!_deferUnclaimed) {
            fundsUnclaimed += DeferredFunds[userAddr];
            IERC20(StakedToken).safeTransfer(userAddr, fundsUnclaimed);
            DeferredFunds[userAddr] = 0;
        } else {
            DeferredFunds[userAddr] += fundsUnclaimed;
        }
        uint256 newTotalDeposit = oldBalance + _amount;

        // Update balance
        LockedFunds[userAddr] = newTotalDeposit;

        // Fill out updated LockVe struct
        LockVe memory newLock;
        newLock.StartBlockTime = block.timestamp;
        newLock.EndBlockTime = newLock.StartBlockTime + _duration + oldDurationRemaining;
        newLock.StartingAmountLocked = newTotalDeposit;
        newLock.Initialized = true;
        Locks[userAddr] = newLock;
    }
}