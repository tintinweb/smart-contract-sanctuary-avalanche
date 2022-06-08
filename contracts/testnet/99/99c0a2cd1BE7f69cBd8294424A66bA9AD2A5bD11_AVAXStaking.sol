// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IWAVAX.sol";
import "./interfaces/IAdmin.sol";
import "./interfaces/IDistribution.sol";

contract AVAXStaking is OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct StakeRecord {
        uint256 id; // Stake id, NOT UNIQUE OVER ALL USERS, unique only among user's other stakes.
        uint256 index; // Index of the StakeRecord in the user.stakeIds array.
        uint256 amount; // Stake amount
        uint256 rewardDebt; // Current reward debt.
        uint256 tokensUnlockTime; // When stake tokens will unlock
    }

    struct UserInfo {
        uint256 totalAmount; // How many LP tokens the user has provided in all his stakes.
        uint256 totalRewarded; // How many tokens user got rewarded in total
        uint256 stakesCount; // How many new deposits user made overall
        uint256[] stakeIds; // User's current (not fully withdrawn) stakes ids
        mapping(uint256 => StakeRecord) stakes; // Stake's id to the StakeRecord mapping
    }

    struct PoolInfo {
        IERC20Upgradeable depositToken; // Address of ERC20 deposit token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ERC20s to distribute per block.
        uint256 accTokenPerShare; // Accumulated ERC20s per share, times 1e36.
        uint256 totalDeposits; // Total amount of tokens deposited at the moment (staked)
        uint256 depositFeePercent; // Percent of deposit fee, must be >= depositFeePrecision / 100 and less than depositFeePrecision
        uint256 depositFeeCollected; // Amount of the deposit fee collected and ready to claim by the owner
        uint256 tokenBlockTime; // Token block time in seconds
        uint256 uniqueUsers; // How many unique users there are in the pool
    }

    // Deposit fee precision for math calculations
    uint256 public DEPOSIT_FEE_PRECISION;

    // Acc reward per share precision in ^36
    uint256 public ACC_REWARD_PER_SHARE_PRECISION;

    // WAVAX address
    IWAVAX public wavax;

    // Last reward balance of WAVAX tokens
    uint256 public lastRewardBalance;

    // The total amount of ERC20 that's paid out as reward
    uint256 public paidOut;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    event Deposit(address indexed user, uint256 indexed pid, uint256 indexed stakeIndex, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 indexed stakeIndex, uint256 withdrawAmount, uint256 rewardAmount);
    event Collect(address indexed user, uint256 indexed pid, uint256 indexed stakeIndex, uint256 amount);
    event SetDepositFee(uint256 depositFeePercent);
    event ClaimCollectedFees(uint256 amount);

    function initialize(IWAVAX _wavax, uint256 _depositFeePrecision) public initializer {
        __Ownable_init();
        __Pausable_init();

        ACC_REWARD_PER_SHARE_PRECISION = 1e36;

        require(_depositFeePrecision >= 100, "I0");
        DEPOSIT_FEE_PRECISION = _depositFeePrecision;

        require(address(_wavax) != address(0x0), "I1");
        wavax = _wavax;
    }

    /**
     * @notice Add a new pool. Can only be called by the owner.
     * @dev DO NOT add the same LP token more than once. Rewards will be messed up if you do.
     */
    function add(
        IERC20Upgradeable _depositToken,
        uint256 _allocPoint,
        uint256 _depositFeePercent,
        uint256 _tokenBlockTime,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({depositToken: _depositToken, allocPoint: _allocPoint, accTokenPerShare: 0, totalDeposits: 0, uniqueUsers: 0, depositFeePercent: _depositFeePercent, depositFeeCollected: 0, tokenBlockTime: _tokenBlockTime}));
    }

    /**
     * @notice Deposit tokens
     */
    function deposit(uint256 _pid, uint256 _amount) public whenNotPaused {
        require(_amount > 0, "D0");
        require(_pid < poolInfo.length, "D1");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 depositAmount = _amount;

        uint256 depositFee = (_amount * pool.depositFeePercent) / DEPOSIT_FEE_PRECISION;
        depositAmount = _amount - depositFee;

        pool.depositFeeCollected = pool.depositFeeCollected + depositAmount;

        // Update pool including fee for people staking
        updatePool(_pid);

        // Add deposit to total deposits
        pool.totalDeposits = pool.totalDeposits + depositAmount;

        // Increment if this is a new user of the pool
        if (user.stakesCount == 0) {
            pool.uniqueUsers = pool.uniqueUsers + 1;
        }

        // Initialize a new stake record
        uint256 stakeId = user.stakesCount;
        require(user.stakes[stakeId].id == 0, "D2");

        StakeRecord storage stake = user.stakes[stakeId];
        // Set stake id
        stake.id = stakeId;
        // Set stake index in the user.stakeIds array
        stake.index = user.stakeIds.length;
        // Add deposit to user's amount
        stake.amount = depositAmount;
        // Update user's total amount
        user.totalAmount = user.totalAmount + depositAmount;
        // Compute reward debt
        stake.rewardDebt = (stake.amount * pool.accTokenPerShare) / ACC_REWARD_PER_SHARE_PRECISION;
        // Set lockup time
        stake.tokensUnlockTime = block.timestamp + pool.tokenBlockTime;

        // Push user's stake id
        user.stakeIds.push(stakeId);
        // Increase users's overall stakes count
        user.stakesCount = user.stakesCount + 1;

        // Safe transfer deposit tokens from user
        pool.depositToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, stake.id, depositAmount);
    }

    /**
     * @notice Withdraw deposit tokens and collect staking rewards in WAVAX from pool
     */
    function withdraw(uint256 _pid, uint256 _stakeId) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        StakeRecord storage stake = user.stakes[_stakeId];
        uint256 amount = stake.amount;

        require(stake.tokensUnlockTime <= block.timestamp, "W0");
        require(amount > 0, "W1");

        // Update pool
        updatePool(_pid);

        // Compute user's pending amount
        uint256 pendingAmount = (stake.amount * pool.accTokenPerShare) / ACC_REWARD_PER_SHARE_PRECISION - stake.rewardDebt;

        // Transfer pending amount to user
        _safeTransferReward(pendingAmount);
        user.totalRewarded = user.totalRewarded + pendingAmount;
        user.totalAmount = user.totalAmount - amount;

        stake.amount = 0;
        stake.rewardDebt = (stake.amount * pool.accTokenPerShare) / ACC_REWARD_PER_SHARE_PRECISION;

        pool.depositToken.safeTransfer(address(msg.sender), amount);
        pool.totalDeposits = pool.totalDeposits - amount;

        // Clean stake data since it's always a full withdraw
        {
            uint256 lastStakeId = user.stakeIds[user.stakeIds.length - 1];

            user.stakeIds[stake.index] = lastStakeId;
            user.stakeIds.pop();
            user.stakes[lastStakeId].index = stake.index;

            delete user.stakes[stake.id];
        }

        emit Withdraw(msg.sender, _pid, _stakeId, amount, pendingAmount);
    }

    /**
     * @notice Collect staking rewards in WAVAX
     */
    function collect(uint256 _pid, uint256 _stakeId) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        StakeRecord storage stake = user.stakes[_stakeId];
        require(stake.amount > 0, "C0");

        // Update pool
        updatePool(_pid);

        // Compute user's pending amount
        uint256 pendingAmount = (stake.amount * pool.accTokenPerShare) / ACC_REWARD_PER_SHARE_PRECISION - stake.rewardDebt;

        // Transfer pending amount to user
        _safeTransferReward(pendingAmount);
        user.totalRewarded = user.totalRewarded + pendingAmount;
        stake.rewardDebt = (stake.amount * pool.accTokenPerShare) / ACC_REWARD_PER_SHARE_PRECISION;

        emit Collect(msg.sender, _pid, _stakeId, pendingAmount);
    }

    /**
     * @notice Set deposit fee for particular pool
     */
    function setDepositFee(uint256 _pid, uint256 _depositFeePercent) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        require(_depositFeePercent <= DEPOSIT_FEE_PRECISION);
        pool.depositFeePercent = _depositFeePercent;

        emit SetDepositFee(_depositFeePercent);
    }

    /**
     * @notice Claim all collected fees and send them to the recipient. Can only be called by the owner.
     *
     * @param _pid pool id
     * @param _recipient address which receives collected fees
     */
    function claimCollectedFees(uint256 _pid, address _recipient) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 amountToCollect = pool.depositFeeCollected;
        pool.depositFeeCollected = 0;

        pool.depositToken.transfer(_recipient, amountToCollect);
        emit ClaimCollectedFees(amountToCollect);
    }

    /**
     * @notice Update the given pool's ERC20 allocation point. Can only be called by the owner.
     * Always prefer to call with _withUpdate set to true.
     */
    function setAllocation(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @notice Get user's stakes count
     */
    function userStakesCount(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.stakeIds.length;
    }

    /**
     * @notice Get pool info
     */
    function getPool(uint256 _pid) public view returns (PoolInfo memory) {
        return poolInfo[_pid];
    }

    /**
     * @notice Return user's stakes array
     */
    function getUserStakes(uint256 _pid, address _user) public view returns (StakeRecord[] memory stakeArray) {
        UserInfo storage user = userInfo[_pid][_user];
        stakeArray = new StakeRecord[](user.stakeIds.length);
        for (uint256 i = 0; i < user.stakeIds.length; i++) {
            stakeArray[i] = user.stakes[user.stakeIds[i]];
        }
    }

    /**
     * @notice Return user's specific stake
     */
    function getUserStake(
        uint256 _pid,
        address _user,
        uint256 _stakeId
    ) public view returns (StakeRecord memory) {
        UserInfo storage user = userInfo[_pid][_user];
        require(user.stakes[_stakeId].id == _stakeId, "Stake with this id does not exist");
        return user.stakes[_stakeId];
    }

    /**
     * @notice Return user's stake ids array
     */
    function getUserStakeIds(uint256 _pid, address _user) public view returns (uint256[] memory) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.stakeIds;
    }

    /**
     * @notice View function to see deposited tokens for a particular user's stake.
     */
    function deposited(
        uint256 _pid,
        address _user,
        uint256 _stakeId
    ) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        StakeRecord storage stake = user.stakes[_stakeId];
        require(stake.id == _stakeId, "Stake with this id does not exist");
        return stake.amount;
    }

    // View function to see total deposited LP for a user.
    function totalDeposited(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.totalAmount;
    }

    /**
     * @notice View function to see pending rewards for a user's stake.
     */
    function pending(
        uint256 _pid,
        address _user,
        uint256 _stakeId
    ) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        StakeRecord storage stake = user.stakes[_stakeId];
        require(stake.id == _stakeId, "P0");

        uint256 depositTokenSupply = pool.totalDeposits;
        uint256 currentRewardBalance = wavax.balanceOf(address(this));

        uint256 _accTokenPerShare = pool.accTokenPerShare;

        if (currentRewardBalance != lastRewardBalance && depositTokenSupply != 0) {
            uint256 _accruedReward = currentRewardBalance - lastRewardBalance;
            _accTokenPerShare = _accTokenPerShare + (((_accruedReward * pool.allocPoint) / totalAllocPoint) * ACC_REWARD_PER_SHARE_PRECISION) / depositTokenSupply;
        }

        return (stake.amount * _accTokenPerShare) / ACC_REWARD_PER_SHARE_PRECISION - stake.rewardDebt;
    }

    /**
     * @notice Number of pools
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice Number of pools
     */
    function totalPending(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];

        uint256 pendingAmount = 0;
        for (uint256 i = 0; i < user.stakeIds.length; i++) {
            pendingAmount = pendingAmount + pending(_pid, _user, user.stakeIds[i]);
        }
        return pendingAmount;
    }

    /**
     * @notice Update reward variables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @notice Update pool rewards. Needs to be called before any deposit or withdrawal
     *
     * @param _pid pool id
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 depositTokenSupply = pool.totalDeposits;
        uint256 currentRewardBalance = wavax.balanceOf(address(this));

        if (depositTokenSupply == 0 || currentRewardBalance == lastRewardBalance) {
            return;
        }

        uint256 _accruedReward = currentRewardBalance - lastRewardBalance;

        pool.accTokenPerShare = pool.accTokenPerShare + (((_accruedReward * pool.allocPoint) / totalAllocPoint) * ACC_REWARD_PER_SHARE_PRECISION) / depositTokenSupply;

        lastRewardBalance = currentRewardBalance;
    }

    /**
     * @notice Transfer rewards and update lastRewardBalance
     *
     * @param _amount pending reward amount in WAVAX
     */
    function _safeTransferReward(uint256 _amount) internal {
        uint256 wavaxBalance = wavax.balanceOf(address(this));

        if (_amount > wavaxBalance) {
            lastRewardBalance = lastRewardBalance - wavaxBalance;
            paidOut += wavaxBalance;

            wavax.withdraw(wavaxBalance);
        } else {
            lastRewardBalance = lastRewardBalance - wavaxBalance;
            paidOut += _amount;

            wavax.withdraw(_amount);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface IAdmin {
    function isAdmin(address user) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface IDistribution {
    function mintTokens(address to, uint256 amount) external;

    function countRewardAmount(uint256 start_, uint256 end_) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface IWAVAX {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
}