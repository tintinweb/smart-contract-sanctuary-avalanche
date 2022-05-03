/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-02
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File contracts/libraries/ProtocolGovernance.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ProtocolGovernance {
    /// @notice address of the governance contract
    address public governance;
    address public pendingGovernance;

    /// @notice modifier to allow for easy gov only control over a function
    modifier onlyGovernance() {
        require(msg.sender == governance, "unauthorized sender (governance");
        _;
    }

    /// @notice Allows governance to change governance (for future upgradability)
    /// @param _governance new governance address to set
    function setGovernance(address _governance) external onlyGovernance {
        pendingGovernance = _governance;
    }

    /// @notice Allows pendingGovernance to accept their role as governance (protection pattern)
    function acceptGovernance() external {
        require(
            msg.sender == pendingGovernance,
            "acceptGovernance: !pendingGov"
        );
        governance = pendingGovernance;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/AccruingStake.sol

pragma solidity 0.8.9;

/// @title A staking contract which accrues over time based on the amount staked
/// @author Auroter
/// @notice Allows you to lock tokens in exchange for distribution tokens
/// @notice Locks can be deposited into or closed
/// @dev Simply call stake(...) to deposit tokens
/// @dev Call getAccrued(user) / getTotalAccrued() = users share




contract AccruingStake is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Info pertaining to staking contract
    address public stakedToken; // An ERC20 Token to be staked (i.e. Axial)
    string public name; // New asset after staking (i.e. veAxial)
    string public symbol; // New asset symbol after staking (i.e. veAXIAL)

    // Info pertaining to users
    uint256 private totalTokensLocked; // Total balance of tokens users have locked
    uint256 private totalTokensAccrued; // Total balance of accrued tokens currently awarded to users
    uint256 private lastUserIndexUpdated; // Index of the user whose accrual was most recently updated
    uint256 private timeStamp; // Last time Total Accrual was updated
    address[] private users; // An array containing all user addresses
    mapping(address => AccrueVe) private locks; // A mapping of each users tokens staked

    struct AccrueVe {
        uint256 accruedTokens; // Quantity of tokens awarded to the user at time of Timestamp
        uint256 stakedTokens; // Quantity of tokens the user has staked
        uint256 timeStamp; // Last time the accrual was updated
        uint256 userIndex; // Index of user, used to manage iteration
        bool initialized; // True if the user is staked
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
        stakedToken = _stakedToken;
        name = _name;
        symbol = _symbol;
    }

    /// @notice Emitted when a user creates a new stake
    /// @param user Address of the user who staked
    /// @param amount Quantity of tokens deposited
    event userStaked(address indexed user, uint256 amount);

    /// @notice Emitted when a user adds to their stake
    /// @param user Address of the user who staked
    /// @param amount Quantity of tokens deposited
    event userRestaked(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws their funds
    /// @param user Address of the user who withdrew
    /// @param amount Quantity of tokens withdrawn
    /// @param accrued Quantity of accrued tokens lost
    event userWithdrew(address indexed user, uint256 amount, uint256 accrued);

    /// @notice Get the number of tokens a user currently has staked
    /// @param _userAddr Address of any user to view the number of vested tokens they have not yet claimed
    /// @return Quantity of tokens which a user currently has staked
    function getStaked(address _userAddr) public view returns (uint256) {
        return locks[_userAddr].stakedTokens;
    }

    /// @notice Get the total number of tokens a user has accrued
    /// @param _userAddr Address of any user to view the number of vested tokens they have not yet claimed
    /// @return Quantity of tokens which a user has accrued over time
    /// @dev Use this function to get the numerator for a users share of the rewards pool
    function getAccrued(address _userAddr) public view returns (uint256) {
        //return Locks[_userAddr].AccruedTokens;
        return locks[_userAddr].accruedTokens + (locks[_userAddr].stakedTokens * (block.timestamp - locks[_userAddr].timeStamp));
    }

    /// @notice Get the total number of tokens accrued via this contract
    /// @return Quantity of all tokens awarded by this contract
    /// @dev Use this function to get the denominator for a users share of the rewards pool
    function getTotalAccrued() public view returns (uint256) {
        return totalTokensAccrued + (totalTokensLocked * (block.timestamp - timeStamp));
    }

    /// @notice Retrieve a list of all users who have ever staked
    /// @return An array of addresses of all users who have ever staked
    function getAllUsers() public view returns (address[] memory) {
        return users;
    }

    // Accrual is tokens locked * seconds
    /// @notice Update the accrual for a specific user
    /// @param _userAddr address of user to update
    /// @dev This synchronizes a users accrual when their deposit amount changes
    function _updateUsersAccrual(address _userAddr) private {
        AccrueVe storage lock = locks[_userAddr];
        uint256 blockTimestamp = block.timestamp;

        uint256 accrual = (blockTimestamp - lock.timeStamp) * lock.stakedTokens;

        lock.timeStamp = blockTimestamp;
        lock.accruedTokens += accrual;
    }

    /// @notice Update the total accrual for all users
    /// @dev This updates the value used as the denominator for a users accrual share
    /// @dev This must always be called before changing the amount of tokens deposited in this contract
    function _updateTotalAccrual() private {
        uint256 currentTime = block.timestamp;
        uint256 delta = currentTime - timeStamp;
        totalTokensAccrued += totalTokensLocked * delta;
        timeStamp = currentTime;
    }

    /// @notice Allow owner to reclaim tokens not matching the deposit token
    /// @notice Some users may have accidentally sent these to the contract
    /// @param _token Address of the non-deposit token
    /// @dev Always ensure the _token is legitimate before calling this
    /// @dev A bad token can mimic safetransfer or balanceof with a nocive function
    function ownerRemoveNonDepositToken(address _token) public nonReentrant onlyOwner {
        require(_token != stakedToken, "!invalid");
        uint256 balanceOfToken = IERC20(_token).balanceOf(address(this));
        require(balanceOfToken > 0, "!balance");
        IERC20(_token).safeTransfer(owner(), balanceOfToken);
    }

    /// @notice Transfers deposited tokens back to their original owner
    /// @notice This will reset the users accrual!
    /// @dev This could be called by the web application via a button or some other means
    function withdrawMyFunds() external nonReentrant {
        address userAddr = msg.sender;
        uint256 fundsToClaim = locks[userAddr].stakedTokens;

        require(fundsToClaim > 0, "!funds");
        IERC20(stakedToken).safeTransfer(userAddr, fundsToClaim);

        // decrement totals
        _updateTotalAccrual();
        uint256 tokensAccrued = getAccrued(userAddr);
        totalTokensLocked -= fundsToClaim;
        totalTokensAccrued -= tokensAccrued;

        // Broadcast withdrawal
        emit userWithdrew(userAddr, fundsToClaim, locks[userAddr].accruedTokens);

        locks[userAddr].stakedTokens = 0;
        locks[userAddr].accruedTokens = 0;
        locks[userAddr].initialized = false;

        // Fairly efficient way of removing user from list
        uint256 lastUsersIndex = users.length - 1;
        uint256 myIndex = locks[userAddr].userIndex;
        locks[users[lastUsersIndex]].userIndex = myIndex;
        users[myIndex] = users[lastUsersIndex];
        users.pop();
    }

    /// @notice Deposit tokens into the contract, adjusting accrual rate
    /// @param _amount Number of tokens to deposit
    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "!amount");

        address userAddr = msg.sender;

        // Receive the users tokens
        require(IERC20(stakedToken).balanceOf(userAddr) >= _amount, "!balance");
        require(IERC20(stakedToken).allowance(userAddr, address(this)) >= _amount, "!approved");
        IERC20(stakedToken).safeTransferFrom(userAddr, address(this), _amount);

        _updateTotalAccrual();
        totalTokensLocked += _amount;

        // Keep track of new users
        if (!locks[userAddr].initialized) {
            users.push(userAddr);
            locks[userAddr].initialized = true;
            locks[userAddr].timeStamp = block.timestamp; // begin accrual from time of initial deposit
            locks[userAddr].userIndex = users.length - 1;
            emit userStaked(userAddr, _amount);
        } else {
            _updateUsersAccrual(userAddr); // balance ledger before accrual rate is increased
            emit userRestaked(userAddr, _amount);
        }

        // Update balance
        locks[userAddr].stakedTokens += _amount;
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

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


// File contracts/Gauge.sol

pragma solidity 0.8.9;







contract Gauge is ProtocolGovernance, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ==================== External Dependencies ==================== //

    /// The Axial token contract
    IERC20 public constant AXIAL = IERC20(0xcF8419A615c57511807236751c0AF38Db4ba3351);

    /// Token to allow boosting partner token rewards - VEAXIAL
    AccruingStake public immutable VEAXIAL;

    /// Token to be staked in return for primary rewards
    IERC20 public immutable poolToken;

    // ==================== Events ==================== //

    /// @notice emitted when a user stakes
    /// @param user The address of the user who staked
    /// @param amount the quantity of tokens the user staked
    event Staked(address indexed user, uint256 amount);

    /// @notice emitted when a user withdraws
    /// @param user The address of the user who withdrew
    /// @param amount The quantity of tokens the user withdrew
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice emitted when a reward is claimed by a user
    /// @param user The address of the user who claimed the reward
    /// @param reward The quantity of tokens the user claimed
    /// @param token The address of the token the user claimed
    event RewardPaid(address indexed user, uint256 reward, address token);

    /// @notice emitted when the primary reward or partner rewards are added to the gauge
    /// @param reward the quantity of tokens added
    /// @param token the address of the reward token
    event RewardAdded(uint256 reward, address token);

    // ==================== State Variables ==================== //

    /// tokens to be distributed as a reward to stakers, 0 is primary reward and 1-... are partner rewards
    address[] public rewardTokens;

    /// contract responsible for distributing primary rewards (should be Gauge Proxy)
    address public gaugeProxy;

    /// Distribution interval for primary reward token
    uint256 public constant PRIMARY_REWARD_DURATION = 7 days;
    mapping(address => uint256) partnerRewardDurations;

    /// Used to keep track of reward token intervals
    // token => time
    mapping (address => uint256) public periodFinish;
    mapping (address => uint256) public lastUpdateTime;

    /// Rewards per second for each reward token
    mapping (address => uint256) public rewardRates;

    // token => amount
    mapping (address => uint256) public rewardPerTokenStored;

    /// @dev user => reward token => amount
    mapping(address => mapping (address => uint256)) public userRewardPerTokenPaid;

    /// @dev user => reward token => amount
    mapping(address => mapping (address => uint256)) public rewards;

    /// total supply of the primary reward token and partner reward tokens
    uint256 private _totalLPTokenSupply;

    uint256 totalBoost; // The sum of all users boost factors!

    /// user => LP token balance
    mapping(address => uint256) private _lpTokenBalances;

    /// user => boost factor
    mapping(address => uint256) public boostFactors;

    /// PARTNER STUFF:

    /// partner reward token => partner, used to determine permission for setting reward rates
    mapping(address => address) public tokenPartners;

    // ==================== Modifiers ==================== //

    // Affects all rewards
    modifier updateRewards(address account) {
        for (uint256 i = 0; i < rewardTokens.length; ++i) { // For each reward token
            address token = rewardTokens[i];
            rewardPerTokenStored[token] = rewardPerToken(token); // Update total rewards available for token
            lastUpdateTime[token] = lastTimeRewardApplicable(token);
            if (account != address(0)) {
                rewards[account][token] = earned(account, token); // Update users allocation out of total rewards for token
                userRewardPerTokenPaid[account][token] = rewardPerTokenStored[token]; // Keep track of what we have allocated so far for the user
            }
        }
        _; // execute function this modifier is attached to
        if (account != address(0)) {
            updateTotalBoostFactor(account); // update the total boost factor based on the users current status
        }
    }

    // Affects only one reward
    modifier updateReward(address account, uint256 tokenIndex) {
        require(tokenIndex < rewardTokens.length, "Invalid token index");
        address token = rewardTokens[tokenIndex];
        rewardPerTokenStored[token] = rewardPerToken(token);
        lastUpdateTime[token] = lastTimeRewardApplicable(token);
        if (account != address(0)) {
            rewards[account][token] = earned(account, token);
            userRewardPerTokenPaid[account][token] = rewardPerTokenStored[token];
        }
        _;
        if (account != address(0)) {
            updateTotalBoostFactor(account);
        }
    }

    modifier onlyDistribution() {
        require(msg.sender == gaugeProxy, "Gauge: not distribution contract");
        _;
    }

    modifier validAddress(address _rewardToken) {
        require(Address.isContract(_rewardToken), "Gauge: not a contract");
        _;
    }

    constructor(
        address _token,
        address _governance,
        address _veaxial
    ) {
        poolToken = IERC20(_token);
        gaugeProxy = msg.sender;
        governance = _governance;
        VEAXIAL = AccruingStake(_veaxial);
        rewardTokens.push(address(AXIAL));
    }

    // ==================== Reward Token Logic ==================== //

    /// @notice adding a reward token to our array
    /// @param tokenAddress Reward token to be added to our rewardTokens array
    /// @param partnerAddress Address of partner who has permission to set the token reward rate
    function addRewardToken(address tokenAddress, address partnerAddress)
        public
        onlyGovernance
        validAddress(tokenAddress)
    {
        require(tokenPartners[tokenAddress] == address(0), "Token already in use");
        tokenPartners[tokenAddress] = partnerAddress; // certify partner with the authority to provide rewards for the token
        rewardTokens.push(tokenAddress); // add token to our list of reward token addresses
    }

    /// @notice returns the amount of reward tokens for the gauge
    function getNumRewardTokens() public view returns (uint256) {
        return rewardTokens.length;
    }

    function partnerDepositRewardTokens(address tokenAddress, uint256 amount, uint256 rewardPerSec) external updateRewards(address(0)) {
        require(tokenPartners[tokenAddress] == msg.sender, "You do not have the right.");
        require (rewardPerSec != 0, "Cannot set reward rate to 0");
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

        // Get balance in case there was some pending balance
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        uint duration = balance / rewardPerSec;

        lastUpdateTime[tokenAddress] = block.timestamp;
        periodFinish[tokenAddress] = block.timestamp.add(duration);
        rewardRates[tokenAddress] = rewardPerSec; // Just set the reward rate even if there is still pending balance
        emit RewardAdded(amount, tokenAddress);
    }

    /// @notice return how many of our reward tokens is the user receiving per lp token at the current point in time
    /// @dev (e.g. how many teddy or axial is received per AC4D token)
    function rewardPerToken(address token) public view returns (uint256) {
        if (_totalLPTokenSupply == 0 || totalBoost == 0) {
            return rewardPerTokenStored[token];
        }
        // x = rPTS + (lTRA - lUT) * rR * 1e18 / tB
        return rewardPerTokenStored[token] + 
        ((lastTimeRewardApplicable(token) - lastUpdateTime[token]) * rewardRates[token] * 1e18 /
        totalBoost);
    }

    /// @notice getting the reward to be received for primary tokens respective staking period
    function getRewardForDuration() external view returns (uint256)
    {
        address token = rewardTokens[0];
        return rewardRates[token].mul(PRIMARY_REWARD_DURATION);
    }

    /// @notice gets the amount of reward tokens that the user has earned
    function earned(address account, address token)
        public
        view
        returns (uint256)
    {
        // x = (bF * ( rPT - uRPTP ) / 1e18 ) + r
        return (boostFactors[account] * (rewardPerToken(token) - userRewardPerTokenPaid[account][token]) / 1e18) + rewards[account][token];
    }

    /// @notice This function is to allow us to update the gaugeProxy without resetting the old gauges.
    /// @dev this changes where it is receiving the axial tokens, as well as changes the governance
    function changeDistribution(address _distribution) external onlyGovernance {
        gaugeProxy = _distribution;
    }

    /// @notice total supply of our lp tokens in the gauge (e.g. AC4D tokens present)
    function totalSupply() external view returns (uint256) {
        return _totalLPTokenSupply;
    }

    /// @notice balance of lp tokens that user has in the gauge (e.g. amount of AC4D a user has)
    function balanceOf(address account) external view returns (uint256) {
        return _lpTokenBalances[account];
    }

    function lastTimeRewardApplicable(address token) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish[token]);
    }

    // returns the users share of the total LP supply * 1e18
    function userShare(address account) external view returns (uint256) {
        if (_totalLPTokenSupply == 0) return 0;
        return _lpTokenBalances[account] * 1e18 / _totalLPTokenSupply;
    }

    /// @notice returns boost factor for specified account
    function boostFactor(address account) public view returns (uint256) {
        uint256 _userBalanceInGauge = _lpTokenBalances[account];

        // Save some gas if this function is entered early
        if (_userBalanceInGauge == 0) {
            return 0;
        }

        // user / total = share
        uint256 usersVeAxialBalance = VEAXIAL.getAccrued(account);
        uint256 totalVeAxial = VEAXIAL.getTotalAccrued();

        // Don't divide by zero!
        uint256 denominator = _totalLPTokenSupply + totalVeAxial;
        if (denominator == 0) return 0;

        // Add users veAxial share to pool share ratio
        // If numerator and denominator are multiplicative, users will be punished for their relative veAxial balance
        uint256 numerator = (_lpTokenBalances[account] + usersVeAxialBalance) * 1e18;
        return numerator / denominator;
    }

    function updateTotalBoostFactor(address account) public {
        totalBoost -= boostFactors[account]; // Subtract users boost factor from total
        boostFactors[account] = boostFactor(account); // Update users boost factor
        totalBoost += boostFactors[account]; // Add new boost factor to total
    }

    /// @notice internal deposit function
    function _deposit(uint256 amount, address account)
        internal
        nonReentrant
        updateRewards(account)
    {
        require(amount > 0, "Cannot stake 0");
        poolToken.safeTransferFrom(account, address(this), amount);
        _totalLPTokenSupply = _totalLPTokenSupply.add(amount);
        _lpTokenBalances[account] = _lpTokenBalances[account].add(amount);
        emit Staked(account, amount);
    }

    /// @notice deposits all pool tokens to the gauge
    function depositAll() external {
        _deposit(poolToken.balanceOf(msg.sender), msg.sender);
    }

    /// @notice deposits specified amount of tokens into the gauge from msg.sender
    function deposit(uint256 amount) external {
        _deposit(amount, msg.sender);
    }

    /// @notice deposit specified amount of tokens into the gauge on behalf of specified account
    /// @param amount amount of tokens to be deposited
    /// @param account account to deposit from
    function depositFor(uint256 amount, address account) external {
        require(account != address(this), "!account"); // prevent inflation
        _deposit(amount, account);
    }

    /// @notice internal withdraw function
    function _withdraw(uint256 amount)
        internal
        nonReentrant
        updateRewards(msg.sender)
    {
        poolToken.safeTransfer(msg.sender, amount);
        require(amount > 0, "Cannot withdraw 0");
        _totalLPTokenSupply = _totalLPTokenSupply.sub(amount);
        _lpTokenBalances[msg.sender] = _lpTokenBalances[msg.sender].sub(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice withdraws all pool tokens from the gauge
    function withdrawAll() external {
        _withdraw(_lpTokenBalances[msg.sender]);
    }

    /// @notice withdraw specified amount of primary pool tokens from the message senders balance
    function withdraw(uint256 amount) external {
        _withdraw(amount);
    }

    /// @notice get reward tokens from gauge
    function getReward(uint256 tokenIndex)
        public
        nonReentrant
        updateReward(msg.sender, tokenIndex)
    {
        address token = rewardTokens[tokenIndex];
        require(token != address(0), "Reward token does not exist");
        uint256 reward = rewards[msg.sender][token];
        if (reward > 0) {
            IERC20(token).safeTransfer(msg.sender, reward);
            rewards[msg.sender][token] = 0;
            emit RewardPaid(msg.sender, reward, token);
        }
    }

    /// @notice claims specific reward indices
    function getRewards(uint256[] calldata tokenIndices) public {
        for (uint256 i = 0; i < tokenIndices.length; ++i) {
            getReward(tokenIndices[i]);
        }
    }

    // /// @notice claims all rewards
    function getAllRewards() public {
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            getReward(i);
        }
    }

    /// @notice withdraw deposited pool tokens and claim reward tokens
    function exit() external {
        _withdraw(_lpTokenBalances[msg.sender]);
        getAllRewards();
    }

    /// @notice only called by the GaugeProxy and so only deals in the native token
    function notifyRewardAmount(uint256 reward)
        external
        onlyDistribution
        updateRewards(address(0))
    {
        address token = rewardTokens[0];
        IERC20(token).safeTransferFrom(
            gaugeProxy,
            address(this),
            reward
        );
        rewardRates[token] = reward.div(PRIMARY_REWARD_DURATION);

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(
            rewardRates[token] <= balance.div(PRIMARY_REWARD_DURATION),
            "Provided reward too high"
        );

        lastUpdateTime[token] = block.timestamp;
        periodFinish[token] = block.timestamp.add(PRIMARY_REWARD_DURATION);
        emit RewardAdded(reward, token);
    }
}