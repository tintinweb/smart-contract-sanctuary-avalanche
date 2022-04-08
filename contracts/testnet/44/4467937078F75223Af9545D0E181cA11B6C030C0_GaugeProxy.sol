/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-07
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


// File contracts/libraries/Strategist.sol

pragma solidity 0.8.9;

contract Strategist {
    /// @notice strategist address for the strategist contract
    address public strategist;
    address public pendingStrategist;

    /// @notice modifier to allow for easy gov only control over a function
    modifier onlyStrategist() {
        require(msg.sender == strategist, "unauthorized sender (strategist)");
        _;
    }

    /// @notice Allows strategist to change strategist (for future upgradability)
    /// @param _strategist new strategist address to set
    function setStrategist(address _strategist) external onlyStrategist {
        pendingStrategist = _strategist;
    }

    /// @notice Allows pendingStrategist to accept their role as strategist
    function acceptStrategist() external {
        require(
            msg.sender == pendingStrategist,
            "unauthorized sender (pendingStrategist)"
        );
        strategist = pendingStrategist;
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
    //uint256 private AprDenominator = 1 days;  // Timeframe it takes for the user to accrue X tokens

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
        totalTokensLocked -= fundsToClaim;
        totalTokensAccrued -= locks[userAddr].accruedTokens;

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


// File contracts/VestingStake.sol

pragma solidity 0.8.9;

/// @title A vesting style staking contract with extendable linear decay
/// @author Auroter
/// @notice Allows you to lock tokens in exchange for governance tokens
/// @notice Locks can be extended or deposited into
/// @notice Maximum deposit duration is two years (104 weeks)
/// @dev Simply call stake(...) to create initial lock or extend one that already exists for the user




contract VestingStake is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Info pertaining to staking contract
    address public stakedToken; // An ERC20 Token to be staked (i.e. Axial)
    string public name; // New asset after staking (i.e. sAxial)
    string public symbol; // New asset symbol after staking (i.e. sAXIAL)
    uint256 private interpolationGranularity = 1e18; // Note: ERC20.decimals() is for display and does not affect arithmetic!

    // Info pertaining to users
    address[] private users; // An array containing all user addresses
    mapping(address => LockVe) private locks; // A mapping of each users lock
    mapping(address => uint256) private lockedFunds; // A mapping of each users total deposited funds
    mapping(address => uint256) private deferredFunds; // A mapping of vested funds the user wishes to leave unclaimed

    // Lock structure, only one of these is allowed per user
    // A DELTA can be derived as the degree of interpolation between the start/end block:
    // Delta = (end - now) / end - start
    // This can be used to determine how much of our staked token is unlocked:
    // currentAmountLocked = startingAmountLocked - (delta * startingAmountLocked)
    struct LockVe {
        uint256 startBlockTime;
        uint256 endBlockTime;
        uint256 startingAmountLocked;
        bool initialized;
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

    /// @notice Emitted when a user stakes for the first time
    /// @param user Address of the user who staked
    /// @param amount Quantity of tokens staked
    /// @param duration Length in seconds of stake
    event userStaked(address indexed user, uint256 amount, uint256 duration);

    /// @notice Emitted when a user extends and/or deposits into their existing stake
    /// @param user Address of the user who staked
    /// @param amount New total quantity of tokens in stake
    /// @param duration New total length of stake
    event userExtended(address indexed user, uint256 amount, uint256 duration);

    /// @notice Emitted when a user claims outstanding vested balance
    /// @param user Address of the user who claimed
    /// @param amount Quantity of tokens claimed
    event userClaimed(address indexed user, uint256 amount);

    /// @notice Calculate the number of vested tokens a user has not claimed
    /// @param _userAddr Address of any user to view the number of vested tokens they have not yet claimed
    /// @return Quantity of tokens which have vested but are unclaimed by the specified user
    function getUnclaimed(address _userAddr) public view returns (uint256) {
        uint256 totalFundsDeposited = lockedFunds[_userAddr] + deferredFunds[_userAddr];
        uint256 currentBalance = getBalance(_userAddr);
        uint256 fundsToClaim = totalFundsDeposited - currentBalance;
        return fundsToClaim;
    }

    /// @notice Calculate the number of tokens a user still has locked
    /// @param _userAddr Address of any user to view the number of tokens they still have locked
    /// @return Quantity of tokens the user has locked
    function getBalance(address _userAddr) public view returns (uint256) {
        LockVe memory usersLock = locks[_userAddr];

        uint256 currentTimestamp = block.timestamp;
        uint256 balance = 0;

        if (usersLock.endBlockTime > currentTimestamp) {
            uint256 granularDelta = ((usersLock.endBlockTime - currentTimestamp) * interpolationGranularity) / (usersLock.endBlockTime - usersLock.startBlockTime);
            balance += (usersLock.startingAmountLocked * granularDelta) / interpolationGranularity;
        }
        return balance;
    }

    /// @notice This is an overload for getPower so that users can see the 'token' in their wallets
    function balanceOf(address _account) external view returns (uint256) {
        return getPower(_account);
    }

    /// @notice Calculate the number of governance tokens currently allocated to a user by this contract
    /// @param _userAddr Address of any user to view the number of governance tokens currently awarded to them
    /// @return Quantity of governance tokens allocated to the user
    function getPower(address _userAddr) public view returns (uint256) {
        LockVe memory usersLock = locks[_userAddr];

        uint256 currentTimestamp = block.timestamp;
        uint256 power = 0;

        if (usersLock.endBlockTime > currentTimestamp) {
            // let delta = elapsed / totalLocktinme
            // let startingPower = duration / 2 years
            // let power = delta * startingPower
            uint256 startingAmountAwarded = ((usersLock.endBlockTime - usersLock.startBlockTime) * usersLock.startingAmountLocked) / 104 weeks;
            uint256 granularDelta = ((usersLock.endBlockTime - currentTimestamp) * interpolationGranularity) / (usersLock.endBlockTime - usersLock.startBlockTime);
            power += (startingAmountAwarded * granularDelta) / interpolationGranularity;
        }
        return power;
    }

    /// @notice Retrieve a list of all users who have ever staked
    /// @return An array of addresses of all users who have ever staked
    function getAllUsers() public view returns (address[] memory) {
        return users;
    }

    /// @notice Check if a user has ever created a Lock in this contract
    /// @param _userAddr Address of any user to check
    /// @dev This may be used by the web application to determine if the UI says "Create Lock" or "Add to Lock"
    /// @return True if the user has ever created a lock
    function isUserLocked(address _userAddr) public view returns (bool) {
        LockVe memory usersLock = locks[_userAddr];
        return usersLock.initialized;
    }

    /// @notice View a users Lock
    /// @param _userAddr Address of any user to view all Locks they have ever created
    /// @dev This may be used by the web application for graphical illustration purposes
    /// @return Users Lock in the format of the LockVe struct
    function getLock(address _userAddr) public view returns (LockVe memory) {
        return locks[_userAddr];
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

    /// @notice Transfers vested tokens back to their original owner
    /// @notice It is up to the user to invoke this manually
    /// @dev This will need to be called by the web application via a button or some other means
    function claimMyFunds() external nonReentrant {
        address userAddr = msg.sender;
        uint256 totalFundsDeposited = lockedFunds[userAddr] + deferredFunds[userAddr];
        uint256 currentBalance = getBalance(userAddr);
        uint256 fundsToClaim = totalFundsDeposited - currentBalance;

        IERC20(stakedToken).safeTransfer(userAddr, fundsToClaim);

        lockedFunds[userAddr] = currentBalance;
        deferredFunds[userAddr] = 0;

        emit userClaimed(userAddr, fundsToClaim);
    }

    /// @notice Create/extend the duration of the invoking users lock and/or deposit additional tokens into it
    /// @param _duration Number of seconds the invoking user will extend their lock for
    /// @param _amount Number of additional tokens to deposit into the lock
    /// @param _deferUnclaimed If True, leaves any unclaimed vested balance in the staking contract
    function stake(uint256 _duration, uint256 _amount, bool _deferUnclaimed) public nonReentrant {
        require(_duration > 0 || _amount > 0, "null");

        // Retrieve lock the user may have already created
        address userAddr = msg.sender;
        LockVe memory usersLock = locks[userAddr];

        uint256 oldDurationRemaining = 0;

        // Keep track of new user or pre-existing lockout period
        if (!usersLock.initialized) {
            users.push(userAddr);
        } else if (block.timestamp < usersLock.endBlockTime) {
            oldDurationRemaining = usersLock.endBlockTime - block.timestamp;
        }

        require (oldDurationRemaining + _duration <= 104 weeks, ">2 years");

        // Receive the users tokens
        require(IERC20(stakedToken).balanceOf(userAddr) >= _amount, "!balance");
        require(IERC20(stakedToken).allowance(userAddr, address(this)) >= _amount, "!approved");
        IERC20(stakedToken).safeTransferFrom(userAddr,  address(this), _amount);

        // Account for balance / unclaimed funds
        uint256 totalFundsDeposited = lockedFunds[userAddr];
        uint256 oldBalance = getBalance(userAddr);
        uint256 fundsUnclaimed = totalFundsDeposited - oldBalance;
        if (!_deferUnclaimed) {
            fundsUnclaimed += deferredFunds[userAddr];
            IERC20(stakedToken).safeTransfer(userAddr, fundsUnclaimed);
            deferredFunds[userAddr] = 0;
            emit userClaimed(userAddr, fundsUnclaimed);
        } else {
            deferredFunds[userAddr] += fundsUnclaimed;
        }
        uint256 newTotalDeposit = oldBalance + _amount;

        // Update balance
        lockedFunds[userAddr] = newTotalDeposit;

        // Fill out updated LockVe struct
        LockVe memory newLock;
        newLock.startBlockTime = block.timestamp;
        newLock.endBlockTime = newLock.startBlockTime + _duration + oldDurationRemaining;
        newLock.startingAmountLocked = newTotalDeposit;
        newLock.initialized = true;
        locks[userAddr] = newLock;

        // Events
        if (oldDurationRemaining == 0) {
            emit userStaked(userAddr, newTotalDeposit, newLock.endBlockTime - newLock.startBlockTime);
        } else {
            emit userExtended(userAddr, newTotalDeposit, newLock.endBlockTime - newLock.startBlockTime);
        }
    }
}


// File contracts/interfaces/IMasterChefAxialV3.sol

pragma solidity 0.8.9;

/// @title Master Chef V3(MCAV3) interface
/// @notice Interface for the MCAV3 contract that will control minting of AXIAL via MCAV2
interface IMasterChefAxialV3 {
    /// @notice Deposit LP tokens to MCAV3 for AXIAL allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    /// @notice Withdraw LP tokens from MCAV3
    function withdraw(uint256 pid, uint256 amount) external;

    /// @notice Get the pool user info for the address provided
    function userInfo(uint256 pid, address owner)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/AxialDummyToken.sol

pragma solidity 0.8.9;


contract AxialDummyToken is ERC20("AxialDummyToken", "AXD") {
    using SafeMath for uint256;

    constructor() {
        _mint(msg.sender, 1e18);
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


// File contracts/Gauge.sol

pragma solidity 0.8.9;







contract Gauge is ProtocolGovernance, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ==================== External Dependencies ==================== //

    /// @notice the Axial token contract
    IERC20 public constant AXIAL =
        IERC20(0xcF8419A615c57511807236751c0AF38Db4ba3351);

    /// @notice token to allow boosting rewards - VEAXIAL
    AccruingStake public immutable VEAXIAL;

    /// @notice token to be staked in return for rewards
    IERC20 public immutable poolToken;

    // ==================== Events ==================== //

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward, address token);
    event RewardAdded(uint256 reward, address token);

    // ==================== State Variables ==================== //

    /// @dev tokens to be distributed as a reward to stakers
    address[] public rewardTokens;
    /// @dev contract responsible for distributing rewards (should be Gauge Proxy)
    address public gaugeProxy;
    uint256 public constant DURATION = 7 days;

    uint256 public periodFinish = 0;
    /// @dev token => rate
    mapping(address => uint256) public rewardRates;
    mapping(address => uint256) public rewardPerTokenStored;

    uint256 public lastUpdateTime;

    /// @dev user => token => amount
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenPaid;
    /// @dev user => token => amount
    mapping(address => mapping(address => uint256)) public rewards;

    uint256 private _totalSupply;
    uint256 public derivedSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public derivedBalances;

    // ==================== Modifiers ==================== //

    modifier updateReward(address account) {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            rewardPerTokenStored[rewardTokens[i]] = rewardPerToken(i);
            lastUpdateTime = lastTimeRewardApplicable();
            if (account != address(0)) {
                rewards[account][rewardTokens[i]] = earned(account, i);
                userRewardPerTokenPaid[account][
                    rewardTokens[i]
                ] = rewardPerTokenStored[rewardTokens[i]];
            }
        }
        _;
        if (account != address(0)) {
            kick(account);
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
    }

    // ==================== Reward Token Logic ==================== //

    /// @notice adding a reward token to our array
    /// @param tokenAddress Reward token to be added to our rewardTokens array
    function addRewardToken(address tokenAddress)
        public
        onlyGovernance
        validAddress(tokenAddress)
    {
        // adding a new reward token to the array
        rewardTokens.push(tokenAddress);
        rewardRates[tokenAddress] = 0;
    }

    /// @notice returns the amount of reward tokens for the gauge
    function getNumRewardTokens() public view returns (uint256) {
        return rewardTokens.length;
    }

    /// @notice return how many of our reward tokens is the user receiving per lp token
    /// @dev (e.g. how many teddy or axial is received per AC4D token)
    function rewardPerToken(uint256 tokenIndex) public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored[rewardTokens[tokenIndex]];
        }

        // rPTS + (lTRA - lUT * rR * 1e18 / dS)
        return rewardPerTokenStored[rewardTokens[tokenIndex]].add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRates[rewardTokens[tokenIndex]]).mul(1e18).div(derivedSupply));
    }

    /// @notice getting the reward to be received for each reward's respective staking period
    function getRewardForDuration(uint256 tokenIndex)
        external
        view
        returns (uint256)
    {
        return rewardRates[rewardTokens[tokenIndex]].mul(DURATION);
    }

    /// @notice gets the amount of reward tokens that the user has earned
    function earned(address account, uint256 tokenIndex)
        public
        view
        returns (uint256)
    {
        // x = dB * ( rPT - uRPTP ) / 1e18 + r 
        return derivedBalances[account].mul(rewardPerToken(tokenIndex).sub(userRewardPerTokenPaid[account][rewardTokens[tokenIndex]])).div(1e18).add(rewards[account][rewardTokens[tokenIndex]]);
    }

    /// @notice This function is to allow us to update the gaugeProxy without resetting the old gauges.
    /// @dev this changes where it is receiving the axial tokens, as well as changes the governance
    function changeDistribution(address _distribution) external onlyGovernance {
        gaugeProxy = _distribution;
    }

    /// @notice total supply of our lp tokens in the gauge (e.g. AC4D tokens present)
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice balance of lp tokens that user has in the gauge (e.g. amount of AC4D a user has)
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @notice returns boost factor for specified account
    function derivedBalance(address account) public view returns (uint256) {
        uint256 _userBalanceInGauge = _balances[account];

        // If the user has no tokens in the gauge, return 0
        if (_userBalanceInGauge == 0) {
            return 0;
        }

        uint256 usersVeAxialBalance = VEAXIAL.getAccrued(account); // get the veAxial balance of the account
        uint256 totalVeAxial = VEAXIAL.getTotalAccrued(); // get the total veAxial

        uint256 _adjusted;
        if (totalVeAxial != 0) {
            _adjusted = (_totalSupply.mul(usersVeAxialBalance).div(totalVeAxial));
        }

        return (_userBalanceInGauge + _adjusted) / _userBalanceInGauge;
    }

    function kick(address account) public {
        uint256 _derivedBalance = derivedBalances[account];
        derivedSupply = derivedSupply.sub(_derivedBalance);
        _derivedBalance = derivedBalance(account);
        derivedBalances[account] = _derivedBalance;
        derivedSupply = derivedSupply.add(_derivedBalance);
    }

    /// @notice internal deposit function
    function _deposit(uint256 amount, address account)
        internal
        nonReentrant
        updateReward(account)
    {
        require(amount > 0, "Cannot stake 0");
        poolToken.safeTransferFrom(account, address(this), amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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
        updateReward(msg.sender)
    {
        poolToken.safeTransfer(msg.sender, amount);
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice withdraws all pool tokens from the gauge
    function withdrawAll() external {
        _withdraw(_balances[msg.sender]);
    }

    /// @notice withdraw specified amount of tokens from the message senders balance
    function withdraw(uint256 amount) external {
        _withdraw(amount);
    }

    /// @notice get reward tokens from gauge
    function getReward(uint256 tokenIndex)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        uint256 reward = rewards[msg.sender][rewardTokens[tokenIndex]];
        if (reward > 0) {
            IERC20(rewardTokens[tokenIndex]).safeTransfer(msg.sender, reward);
            rewards[msg.sender][rewardTokens[tokenIndex]] = 0;
            emit RewardPaid(msg.sender, reward, rewardTokens[tokenIndex]);
        }
    }

    /// @notice withdraw deposited pool tokens and claim reward tokens
    function exit() external {
        _withdraw(_balances[msg.sender]);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            getReward(i);
        }
    }

    function notifyReward(uint256 reward, uint256 tokenIndex)
        external
        updateReward(address(0))
    {
        IERC20(rewardTokens[tokenIndex]).safeTransferFrom(
            gaugeProxy,
            address(this),
            reward
        );
        if (block.timestamp >= periodFinish) {
            rewardRates[rewardTokens[tokenIndex]] = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(
                rewardRates[rewardTokens[tokenIndex]]
            );
            rewardRates[rewardTokens[tokenIndex]] = reward.add(leftover).div(
                DURATION
            );
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(rewardTokens[tokenIndex]).balanceOf(
            address(this)
        );
        require(
            rewardRates[rewardTokens[tokenIndex]] <= balance.div(DURATION),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward, rewardTokens[tokenIndex]);
    }

    /// @notice only called by the GaugeProxy and so only deals in the native token
    function notifyRewardAmount(uint256 reward)
        external
        onlyDistribution
        updateReward(address(0))
    {
        IERC20(rewardTokens[0]).safeTransferFrom(
            gaugeProxy,
            address(this),
            reward
        );
        if (block.timestamp >= periodFinish) {
            rewardRates[rewardTokens[0]] = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRates[rewardTokens[0]]);
            rewardRates[rewardTokens[0]] = reward.add(leftover).div(DURATION);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(rewardTokens[0]).balanceOf(address(this));
        require(
            rewardRates[rewardTokens[0]] <= balance.div(DURATION),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward, rewardTokens[0]);
    }
}


// File contracts/GaugeProxy.sol

pragma solidity 0.8.9;










contract GaugeProxy is ProtocolGovernance {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ==================== External Dependencies ==================== //

    /// @notice Master Chef Axial V3 contract
    IMasterChefAxialV3 public constant MCAV3 =
        //IMasterChefAxialV3(0x958C0d0baA8F220846d3966742D4Fb5edc5493D3);
        IMasterChefAxialV3(0x35225E5a6309a4823f900EeC047699ecFbE8d341);

    /// @notice token for voting on Axial distribution to pools - SAXIAL
    VestingStake public immutable sAxial;

    /// @notice the Axial token contraxt
    IERC20 public immutable Axial;

    /// @notice dummy token required for masterchef deposits and withdrawals
    IERC20 public immutable axialDummyToken;

    /// @notice token to allow boosting rewards - VEAXIAL
    /// @dev This could be an address instead, as we do not use it other than passing the address to the Gauge constructor
    AccruingStake public immutable veAxial;

    // ==================== Token Voting Storage ==================== //

    /// @notice max time allowed to pass before distribution (6 hours)
    uint256 public constant DISTRIBUTION_DEADLINE = 21600;

    uint256 public constant UINT256_MAX = 2**256-1;
    uint256 public pid = UINT256_MAX;
    uint256 public totalWeight;
    uint256 private lockedTotalWeight;
    uint256 private lockedBalance;
    uint256 private locktime;

    address[] internal _tokens;

    /// @dev token -> gauge
    mapping(address => address) public gauges;
    /// @dev token => gauge
    mapping(address => address) public deprecated;
    /// @dev token => weight
    mapping(address => uint256) public weights;
    /// @dev token => weight
    mapping(address => uint256) private lockedWeights;
    /// @dev msg.sender => token => votes
    mapping(address => mapping(address => uint256)) public votes;
    /// @dev msg.sender => token
    mapping(address => address[]) public tokenVote;
    /// @dev msg.sender => total voting weight of user
    mapping(address => uint256) public usedWeights;
    mapping(address => bool) public deployers;

    constructor(
        address _governance,
        address _axial,
        address _saxial,
        address _veaxial
    ) {
        governance = _governance;
        Axial = IERC20(_axial);
        sAxial = VestingStake(_saxial);
        veAxial = AccruingStake(_veaxial);
        axialDummyToken = new AxialDummyToken();
    }

    // ==================== Admin functions ==================== //

    /// @notice adds the specified address to the list of deployers
    /// @dev deployers can call distribute function
    function addDeployer(address _deployer) external onlyGovernance {
        deployers[_deployer] = true;
    }

    /// @notice removes the specified address from the list of deployers
    function removeDeployer(address _deployer) external onlyGovernance {
        deployers[_deployer] = false;
    }

    // ==================== Modifiers ==================== //

    /// @notice modifier to restrict functinos to governance or strategist roles
    modifier onlyBenevolent() {
        require(msg.sender == governance, "unauthorized sender");
        _;
    }

    // ==================== View functions ==================== //

    /// @notice returns the list of tokens that are currently being voted on
    function tokens() external view returns (address[] memory) {
        return _tokens;
    }

    /// @notice returns the gauge for the specifi(AccruingStake)
    function getGauge(address _token) external view returns (address) {
        return gauges[_token];
    }

    /// @notice returns the number of tokens currently being voted on
    function length() external view returns (uint256) {
        return _tokens.length;
    }

    // ==================== Voting Logic ==================== //

    /// @notice Vote with SAXIAL on a gauge, removing any previous votes
    /// @param _tokenVote: the array of tokens which will recieve tokens
    /// @param _weights: the weights to associate with the tokens listed in _tokenVote
    function vote(address[] calldata _tokenVote, uint256[] calldata _weights)
        external
    {
        require(
            _tokenVote.length == _weights.length,
            "weight/tokenvote length mismatch"
        );
        _vote(msg.sender, _tokenVote, _weights);
    }

    /// @notice internal voting function
    function _vote(
        address _owner,
        address[] memory _tokenVote,
        uint256[] memory _weights
    ) internal {
        // reset votes of the owner
        _reset(_owner);
        uint256 _tokenCnt = _tokenVote.length;
        uint256 _weight = sAxial.getPower(_owner);
        uint256 _totalVoteWeight = 0;
        uint256 _usedWeight = 0;

        for (uint256 i = 0; i < _tokenCnt; i++) {
            _totalVoteWeight = _totalVoteWeight.add(_weights[i]);
        }

        for (uint256 i = 0; i < _tokenCnt; i++) {
            address _token = _tokenVote[i];
            address _gauge = gauges[_token];
            // Calculate quantity of users SAXIAL to allocate for the gauge
            uint256 _tokenWeight = _weights[i].mul(_weight).div(
                _totalVoteWeight
            );

            if (_gauge != address(0x0)) {
                _usedWeight = _usedWeight.add(_tokenWeight);
                totalWeight = totalWeight.add(_tokenWeight);
                weights[_token] = weights[_token].add(_tokenWeight);
                tokenVote[_owner].push(_token);
                votes[_owner][_token] = _tokenWeight;
            }
        }
        usedWeights[_owner] = _usedWeight;
    }

    /// @notice Reset votes of msg.sender to 0
    function reset() external {
        _reset(msg.sender);
    }

    /// @notice Internal function to reset votes of the specified address to 0
    /// @param _owner address of owner of votes to be reset
    function _reset(address _owner) internal {
        // Get all tokens that the owner has voted on
        address[] storage _tokenVote = tokenVote[_owner];
        uint256 _tokenVoteCnt = _tokenVote.length;

        for (uint256 i = 0; i < _tokenVoteCnt; i++) {
            address _token = _tokenVote[i];
            // Get the amount of SAXIAL this user allocated for this specific token
            uint256 _votes = votes[_owner][_token];

            if (_votes > 0) {
                totalWeight = totalWeight.sub(_votes);
                weights[_token] = weights[_token].sub(_votes);

                votes[_owner][_token] = 0;
            }
        }

        delete tokenVote[_owner];
    }

    /// @notice Adjust _owner's votes according to latest _owner's SAXIAL balance
    function poke(address _owner) public {
        address[] memory _tokenVote = tokenVote[_owner];
        uint256 _tokenCnt = _tokenVote.length;
        uint256[] memory _weights = new uint256[](_tokenCnt);

        for (uint256 i = 0; i < _tokenCnt; i++) {
            _weights[i] = votes[_owner][_tokenVote[i]];
        }

        // _weights no longer total 100 like with the front-end
        // But we will minimize gas by not converting
        _vote(_owner, _tokenVote, _weights);
    }

    // ==================== Gauge Logic ==================== //

    /// @notice Add new token gauge
    function addGauge(address _token) external onlyBenevolent {
        require(gauges[_token] == address(0x0), "exists");
        gauges[_token] = address(
            new Gauge(_token, governance, address(veAxial))
        );
        _tokens.push(_token);
    }

    /// @notice Deprecate existing gauge
    function deprecateGauge(address _token) external onlyBenevolent {
        require(gauges[_token] != address(0x0), "does not exist");
        deprecated[_token] = gauges[_token];
        delete gauges[_token];
    }

    /// @notice Bring Deprecated gauge back into use
    function renewGauge(address _token) external onlyBenevolent {
        require(gauges[_token] == address(0x0), "exists");
        require(deprecated[_token] != address(0x0), "not deprecated");
        gauges[_token] = deprecated[_token];
        delete deprecated[_token];
    }

    /// @notice Add existing gauge
    function migrateGauge(address _gauge, address _token)
        external
        onlyBenevolent
    {
        require(gauges[_token] == address(0x0), "exists");
        gauges[_token] = _gauge;
        _tokens.push(_token);
    }

    // ==================== MCAV3 Logic ==================== //

    /// @notice Sets MCAV3 PID
    function setPID(uint256 _pid) external onlyGovernance {
        require(pid == UINT256_MAX, "pid has already been set");
        require(_pid < UINT256_MAX, "invalid pid");
        pid = _pid;
    }

    /// @notice Deposits Axial dummy token into MCAV3
    function deposit() public {
        require(pid < UINT256_MAX, "pid not initialized");
        uint256 _balance = axialDummyToken.balanceOf(address(this));
        axialDummyToken.safeApprove(address(MCAV3), 0);
        axialDummyToken.safeApprove(address(MCAV3), _balance);
        MCAV3.deposit(pid, _balance);
    }

    /// @notice Collects AXIAL from MCAV3 for distribution
    function collect() public {
        (uint256 _locked, ) = MCAV3.userInfo(pid, address(this));
        MCAV3.withdraw(pid, _locked);
        deposit();
    }

    // ==================== Distribution Logic ==================== //

    /// @notice collect AXIAL and update lock information
    function preDistribute() external {
        require(
            deployers[msg.sender] || msg.sender == governance,
            "unauthorized sender"
        );
        lockedTotalWeight = totalWeight;
        for (uint256 i = 0; i < _tokens.length; i++) {
            lockedWeights[_tokens[i]] = weights[_tokens[i]];
        }
        collect();
        lockedBalance = Axial.balanceOf(address(this));
        locktime = block.timestamp;
    }

    /// @notice Distribute tokens to gauges
    function distribute(uint256 _start, uint256 _end) external {
        require(
            deployers[msg.sender] || msg.sender == governance,
            "unauthorized sender"
        );
        require(_start < _end, "bad _start");
        require(_end <= _tokens.length, "bad _end");
        require(
            locktime + DISTRIBUTION_DEADLINE >= block.timestamp,
            "lock expired"
        );
        if (lockedBalance > 0 && lockedTotalWeight > 0) {
            for (uint256 i = _start; i < _end; i++) {
                address _token = _tokens[i];
                address _gauge = gauges[_token];
                uint256 _reward = lockedBalance.mul(lockedWeights[_token]).div(
                    totalWeight
                );
                if (_reward > 0) {
                    Axial.safeApprove(_gauge, 0);
                    Axial.safeApprove(_gauge, _reward);
                    Gauge(_gauge).notifyRewardAmount(_reward);
                }
            }
        }
    }
}