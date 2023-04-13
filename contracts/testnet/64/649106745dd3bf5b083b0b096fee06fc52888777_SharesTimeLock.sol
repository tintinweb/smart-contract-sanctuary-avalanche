// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

pragma solidity 0.8.16;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

interface IERC20MintableBurnable is IERC20 {
    function mint(address from, uint256 quantity) external;
    function burn(address from, uint256 quantity) external;
    function burn(uint256 quantity) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
pragma abicoder v2;

import {OwnableUpgradeable as Ownable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import "@interfaces/IERC20MintableBurnable.sol";

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
        require((z = x + y) >= x, errorMessage);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
        require((z = x - y) <= x, errorMessage);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y, errorMessage);
    }
}

library TransferHelper {
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}

contract SharesTimeLock is Ownable {
    using LowGasSafeMath for uint256;
    using TransferHelper for address;

    address public depositToken;

    IERC20MintableBurnable public rewardsToken;

    // min amount in
    uint32 public minLockDuration;

    uint32 public maxLockDuration;

    uint256 public minLockAmount;

    uint256 private constant AVG_SECONDS_MONTH = 2628000;

    bool public emergencyUnlockTriggered;

    /**
     * Mapping of coefficient for the staking curve
     * y=x/k*log(x)
     * where `x` is the staking time
     * and `k` is a constant 56.0268900276223
     * the period of staking here is calculated in months.
     */
    uint256[37] public maxRatioArray;

    event MinLockAmountChanged(uint256 newLockAmount);
    event WhitelistedChanged(address indexed user, bool indexed whitelisted);
    event Deposited(uint256 indexed lockId, uint256 amount, uint32 lockDuration, address indexed owner);
    event Withdrawn(uint256 indexed lockId, uint256 amount, address indexed owner);
    event Ejected(uint256 indexed lockId, uint256 amount, address indexed owner);
    event BoostedToMax(uint256 indexed oldLockId, uint256 indexed newLockId, uint256 amount, address indexed owner);
    event EjectBufferUpdated(uint256 newEjectBuffer);

    struct Lock {
        uint256 amount;
        uint32 lockedAt;
        uint32 lockDuration;
    }

    struct StakingData {
        uint256 totalStaked;
        uint256 veTokenTotalSupply;
        uint256 accountVeTokenBalance;
        uint256 accountWithdrawableRewards;
        uint256 accountWithdrawnRewards;
        uint256 accountDepositTokenBalance;
        uint256 accountDepositTokenAllowance;
        Lock[] accountLocks;
    }

    mapping(address => Lock[]) public locksOf;

    mapping(address => bool) public whitelisted;

    uint256 public ejectBuffer;

    /**
     *  NEW STORAGE HERE
     */
    bool public migrationEnabled;
    address public migrator;

    function getLocksOfLength(address account) external view returns (uint256) {
        return locksOf[account].length;
    }

    function getLocks(address account) external view returns (Lock[] memory) {
        return locksOf[account];
    }
    /**
     * @dev Returns the rewards multiplier for `duration` expressed as a fraction of 1e18.
     */

    function getRewardsMultiplier(uint32 duration) public view returns (uint256 multiplier) {
        require(
            duration >= minLockDuration && duration <= maxLockDuration, "getRewardsMultiplier: Duration not correct"
        );
        uint256 month = uint256(duration) / secondsPerMonth();
        multiplier = maxRatioArray[month];
        return multiplier;
    }

    function initialize(
        address depositToken_,
        IERC20MintableBurnable rewardsToken_,
        uint32 minLockDuration_,
        uint32 maxLockDuration_,
        uint256 minLockAmount_
    ) public initializer {
        __Ownable_init();

        rewardsToken = rewardsToken_;
        depositToken = depositToken_;
        require(minLockDuration_ < maxLockDuration_, "min>=max");
        minLockDuration = minLockDuration_;
        maxLockDuration = maxLockDuration_;
        minLockAmount = minLockAmount_;
        ejectBuffer = 7 days;

        maxRatioArray = [
            1,
            2,
            3,
            4,
            5,
            6,
            83333333333300000, // 6
            105586554548800000, // 7
            128950935744800000, // 8
            153286798191400000, // 9
            178485723463700000, // 10
            204461099502300000, // 11
            231142134539100000, // 12
            258469880674300000, // 13
            286394488282000000, // 14
            314873248847800000, // 15
            343869161986300000, // 16
            373349862059400000, // 17
            403286798191400000, // 18
            433654597035900000, // 19
            464430560048100000, // 20
            495594261536300000, // 21
            527127223437300000, // 22
            559012649336100000, // 23
            591235204823000000, // 24
            623780834516600000, // 25
            656636608405400000, // 26
            689790591861100000, // 27
            723231734933100000, // 28
            756949777475800000, // 29
            790935167376600000, // 30
            825178989697100000, // 31
            859672904965600000, // 32
            894409095191000000, // 33
            929380216424000000, // 34
            964579356905500000, // 35
            1000000000000000000 // 36
        ];
    }

    function depositByMonths(uint256 amount, uint256 months, address receiver) external {
        // only allow whitelisted contracts or EOAS
        require(tx.origin == _msgSender() || whitelisted[_msgSender()], "Not EOA or whitelisted");
        // only allow whitelisted addresses to deposit to another address
        require(
            _msgSender() == receiver || whitelisted[_msgSender()],
            "Only whitelised address can deposit to another address"
        );
        uint32 duration = uint32(months.mul(secondsPerMonth()));
        deposit(amount, duration, receiver);
    }

    function deposit(uint256 amount, uint32 duration, address receiver) internal {
        require(amount >= minLockAmount, "Deposit: amount too small");
        require(!emergencyUnlockTriggered, "Deposit: deposits locked");
        depositToken.safeTransferFrom(_msgSender(), address(this), amount);
        uint256 multiplier = getRewardsMultiplier(duration);
        uint256 rewardShares = amount.mul(multiplier) / 1e18;
        rewardsToken.mint(receiver, rewardShares);
        locksOf[receiver].push(Lock({amount: amount, lockedAt: uint32(block.timestamp), lockDuration: duration}));
        emit Deposited(locksOf[receiver].length - 1, amount, duration, receiver);
    }

    function withdraw(uint256 lockId) external {
        Lock memory lock = locksOf[_msgSender()][lockId];
        uint256 unlockAt = lock.lockedAt + lock.lockDuration;
        require(
            block.timestamp > unlockAt || emergencyUnlockTriggered,
            "Withdraw: lock not expired and timelock not in emergency mode"
        );
        delete locksOf[_msgSender()][lockId];
        uint256 multiplier = getRewardsMultiplier(lock.lockDuration);
        uint256 rewardShares = lock.amount.mul(multiplier) / 1e18;
        rewardsToken.burn(_msgSender(), rewardShares);

        depositToken.safeTransfer(_msgSender(), lock.amount);
        emit Withdrawn(lockId, lock.amount, _msgSender());
    }

    function boostToMax(uint256 lockId) external {
        require(!emergencyUnlockTriggered, "BoostToMax: emergency unlock triggered");

        Lock memory lock = locksOf[_msgSender()][lockId];
        delete locksOf[_msgSender()][lockId];
        uint256 multiplier = getRewardsMultiplier(lock.lockDuration);
        uint256 rewardShares = lock.amount.mul(multiplier) / 1e18;
        require(rewardsToken.balanceOf(_msgSender()) >= rewardShares, "boostToMax: Wrong shares number");

        uint256 newMultiplier = getRewardsMultiplier(maxLockDuration);
        uint256 newRewardShares = lock.amount.mul(newMultiplier) / 1e18;
        rewardsToken.mint(_msgSender(), newRewardShares.sub(rewardShares));
        locksOf[_msgSender()].push(
            Lock({amount: lock.amount, lockedAt: uint32(block.timestamp), lockDuration: maxLockDuration})
        );

        emit BoostedToMax(lockId, locksOf[_msgSender()].length - 1, lock.amount, _msgSender());
    }

    // Eject expired locks
    function eject(address[] memory lockAccounts, uint256[] memory lockIds) external {
        require(lockAccounts.length == lockIds.length, "Array length mismatch");

        for (uint256 i = 0; i < lockIds.length; i++) {
            //skip if lockId is invalid
            if (locksOf[lockAccounts[i]].length - 1 < lockIds[i]) {
                continue;
            }

            Lock memory lock = locksOf[lockAccounts[i]][lockIds[i]];
            //skip if lock not expired or locked amount is zero
            if (lock.lockedAt + lock.lockDuration + ejectBuffer > block.timestamp || lock.amount == 0) {
                continue;
            }

            delete locksOf[lockAccounts[i]][lockIds[i]];
            uint256 multiplier = getRewardsMultiplier(lock.lockDuration);
            uint256 rewardShares = lock.amount.mul(multiplier) / 1e18;
            rewardsToken.burn(lockAccounts[i], rewardShares);

            depositToken.safeTransfer(lockAccounts[i], lock.amount);

            emit Ejected(lockIds[i], lock.amount, lockAccounts[i]);
        }
    }

    /**
     * Setters
     */

    function setMigratoor(address migrator_) external onlyOwner {
        migrator = migrator_;
    }

    function setMigrationON() external onlyOwner {
        migrationEnabled = true;
    }

    function setMigrationOFF() external onlyOwner {
        migrationEnabled = false;
    }

    function setMinLockAmount(uint256 minLockAmount_) external onlyOwner {
        minLockAmount = minLockAmount_;
        emit MinLockAmountChanged(minLockAmount_);
    }

    function setWhitelisted(address user, bool isWhitelisted) external onlyOwner {
        whitelisted[user] = isWhitelisted;
        emit WhitelistedChanged(user, isWhitelisted);
    }

    function triggerEmergencyUnlock() external onlyOwner {
        require(!emergencyUnlockTriggered, "TriggerEmergencyUnlock: already triggered");
        emergencyUnlockTriggered = true;
    }

    function setEjectBuffer(uint256 buffer) external onlyOwner {
        ejectBuffer = buffer;
        emit EjectBufferUpdated(buffer);
    }

    /**
     * Getters
     */

    function getStakingData(address account) external view returns (StakingData memory data) {
        data.totalStaked = IERC20(depositToken).balanceOf(address(this));
        data.veTokenTotalSupply = rewardsToken.totalSupply();
        data.accountVeTokenBalance = rewardsToken.balanceOf(account);
        data.accountDepositTokenBalance = IERC20(depositToken).balanceOf(account);
        data.accountDepositTokenAllowance = IERC20(depositToken).allowance(account, address(this));

        data.accountLocks = new Lock[](locksOf[account].length);

        for (uint256 i = 0; i < locksOf[account].length; i++) {
            data.accountLocks[i] = locksOf[account][i];
        }
    }

    // Used to overwrite in testing situations
    function secondsPerMonth() internal view virtual returns (uint256) {
        return AVG_SECONDS_MONTH;
    }

    function canEject(address account, uint256 lockId) external view returns (bool) {
        //cannot eject non existing locks
        if (locksOf[account].length - 1 < lockId) {
            return false;
        }

        Lock memory lock = locksOf[account][lockId];

        // if lock is already removed it cannot be ejected
        if (lock.lockedAt == 0) {
            return false;
        }

        return lock.lockedAt + lock.lockDuration + ejectBuffer <= block.timestamp;
    }

    function lockExpired(address staker, uint256 lockId) public view returns (bool) {
        return uint256(locksOf[staker][lockId].lockedAt + locksOf[staker][lockId].lockDuration) <= block.timestamp;
    }

    /// @dev overloaded to allow passing the lock if available
    function lockExpired(Lock memory lock) public view returns (bool) {
        return uint256(lock.lockedAt + lock.lockDuration) <= block.timestamp;
    }

    /**
     * @notice migrates a single lockId for the passed staker.
     *         Dough is transferred to the migrator and veDOUGH is burned.
     */
    function migrate(address staker, uint256 lockId) external {
        require(migrationEnabled, "SharesTimeLock: !migrationEnabled");
        require(_msgSender() == migrator, "SharesTimeLock: Not Migrator");

        Lock memory lock = locksOf[staker][lockId];

        require(uint256(lock.lockedAt + lock.lockDuration) > block.timestamp, "SharesTimeLock: Lock expired");
        require(lock.amount > 0, "SharesTimeLock: nothing to migrate");

        delete locksOf[staker][lockId];

        uint256 multiplier = getRewardsMultiplier(lock.lockDuration);
        uint256 rewardShares = lock.amount.mul(multiplier) / 1e18;
        rewardsToken.burn(staker, rewardShares);

        IERC20(depositToken).transfer(migrator, lock.amount);
    }

    /**
     * @notice migrates multiple staking positions as determined by the passed lockIds
     * @param lockIds an array of lock indexes to migrate for the current staker, should be sorted in ascending order.
     * @dev you can pass any array of Ids and the contract will migrate them if they are not expired for that staker
     *      however it is advised that the array is sorted.
     *      Specifically, If LockId `0` is to be migrated, it should be the first element of the lockIds array.
     */
    function migrateMany(address staker, uint256[] calldata lockIds) external returns (uint256) {
        require(migrationEnabled, "SharesTimeLock: !migrationEnabled");
        require(_msgSender() == migrator, "SharesTimeLock: Not Migrator");
        uint256 amountToMigrate = 0;
        uint256 amountToBurn = 0;

        for (uint256 i = 0; i < lockIds.length; i++) {
            // accessing lockId zero in any place other than the first array element
            // could be due to accessing array elements that were initialized at zero and not updated with real data
            // we therefore break the loop to be safe and rely on the caller to properly sort the array if migrating lockId == 0
            if (i > 0 && lockIds[i] == 0) break;

            Lock memory lock = locksOf[staker][lockIds[i]];

            if (lock.amount == 0) continue;

            require(uint256(lock.lockedAt + lock.lockDuration) > block.timestamp, "SharesTimeLock: Lock expired");

            uint256 multiplier = getRewardsMultiplier(lock.lockDuration);
            uint256 rewardShares = lock.amount.mul(multiplier) / 1e18;

            delete locksOf[staker][lockIds[i]];
            amountToMigrate += lock.amount;
            amountToBurn += rewardShares;
        }

        require(amountToBurn > 0, "Nothing to Burn");
        rewardsToken.burn(staker, amountToBurn);
        IERC20(depositToken).transfer(migrator, amountToMigrate);
        return amountToMigrate;
    }
}