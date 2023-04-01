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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./utils/TokenUtils.sol";
import "./interfaces/IHexOneBootstrap.sol";
import "./interfaces/IHexOneStaking.sol";
import "./interfaces/IHexOnePriceFeed.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IHEXIT.sol";
import "./interfaces/IHexToken.sol";
import "./interfaces/IToken.sol";

/// @notice For sacrifice and airdrop
contract HexOneBootstrap is OwnableUpgradeable, IHexOneBootstrap {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    /// @notice Percent of HEXIT token for sacrifice distribution.
    uint16 public rateForSacrifice;

    /// @notice Percent of HEXIT token for airdrop.
    uint16 public rateForAirdrop;

    /// @notice Distibution rate.
    ///         This percent of HEXIT token goes to middle contract
    ///         for distribute $HEX1 token to sacrifice participants.
    uint16 public sacrificeDistRate;

    /// @notice Percent for will be used for liquidity.
    uint16 public sacrificeLiquidityRate;

    /// @notice Percent for users who has t-shares by staking hex.
    uint16 public airdropDistRateForHexHolder;

    /// @notice Percent for users who has $HEXIT by sacrifice.
    uint16 public airdropDistRateForHEXITHolder;

    /// @notice Percent that will be used for daily airdrop.
    uint16 public distRateForDailyAirdrop; // 50%

    /// @notice Percent that will be supplied daily.
    uint16 public supplyCropRateForSacrifice; // 4.7%

    /// @notice HEXIT token rate will be generated additionally for Staking.
    uint16 public additionalRateForStaking;

    /// @notice HEXIT token rate will be generated addtionally for Team.
    uint16 public additionalRateForTeam;

    /// @notice Allowed token info.
    mapping(address => Token) public allowedTokens;

    /// @notice total sacrificed weight info by daily.
    mapping(uint256 => uint256) public totalSacrificeWeight;

    mapping(uint256 => mapping(address => uint256))
        public totalSacrificeTokenAmount;

    //! For Sacrifice
    /// @notice weight that user sacrificed by daily.
    mapping(uint256 => mapping(address => uint256)) public sacrificeUserWeight;

    /// @notice received HEXIT token amount info per user.
    mapping(address => uint256) public userRewardsForSacrifice;

    /// @notice sacrifice indexes that user sacrificed
    mapping(address => EnumerableSet.UintSet) private userSacrificedIds;

    mapping(address => uint256) public userSacrificedUSD;

    mapping(uint256 => SacrificeInfo) public sacrificeInfos;

    //! For Airdrop
    /// @notice dayIndex that a wallet requested airdrop.
    /// @dev request dayIndex starts from 1.
    mapping(address => RequestAirdrop) public requestAirdropInfo;

    /// @notice Requested amount by daily.
    mapping(uint256 => uint256) public requestedAmountInfo;

    IUniswapV2Router02 public dexRouter;
    address public hexOnePriceFeed;
    address public hexitToken;
    address public hexToken;
    address public pairToken;
    address public escrowCA;
    address public stakingContract;
    address public teamWallet;

    uint256 public sacrificeInitialSupply;
    uint256 public sacrificeStartTime;
    uint256 public sacrificeEndTime;
    uint256 public airdropStartTime;
    uint256 public airdropEndTime;
    uint256 public airdropHEXITAmount;
    uint256 public override HEXITAmountForSacrifice;
    uint256 public sacrificeId;
    uint256 public airdropId;

    uint16 public FIXED_POINT;
    bool private amountUpdated;

    EnumerableSet.AddressSet private sacrificeParticipants;
    EnumerableSet.AddressSet private airdropRequestors;

    modifier whenSacrificeDuration() {
        uint256 curTimestamp = block.timestamp;
        require(
            curTimestamp >= sacrificeStartTime &&
                curTimestamp <= sacrificeEndTime,
            "not sacrifice duration"
        );
        _;
    }

    modifier whenAirdropDuration() {
        uint256 curTimestamp = block.timestamp;
        require(
            curTimestamp >= airdropStartTime && curTimestamp <= airdropEndTime,
            "not airdrop duration"
        );
        _;
    }

    modifier onlyAllowedToken(address _token) {
        /// address(0) is native token.
        require(allowedTokens[_token].enable, "not allowed token");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(Param memory _param) public initializer {
        FIXED_POINT = 1000;
        distRateForDailyAirdrop = 500; // 50%
        supplyCropRateForSacrifice = 47; // 4.7%
        sacrificeInitialSupply = 5_555_555 * 1e18;
        additionalRateForStaking = 330; // 33%
        additionalRateForTeam = 500; // 50%

        require(
            _param.hexOnePriceFeed != address(0),
            "zero hexOnePriceFeed address"
        );
        hexOnePriceFeed = _param.hexOnePriceFeed;

        require(
            _param.sacrificeStartTime > block.timestamp,
            "sacrifice: before current time"
        );
        require(_param.sacrificeDuration > 0, "sacrfice: zero duration days");
        sacrificeStartTime = _param.sacrificeStartTime;
        sacrificeEndTime =
            _param.sacrificeStartTime +
            _param.sacrificeDuration *
            1 days;

        require(
            _param.airdropStartTime > sacrificeEndTime,
            "airdrop: before sacrifice"
        );
        require(_param.airdropDuration > 0, "airdrop: zero duration days");
        airdropStartTime = _param.airdropStartTime;
        airdropEndTime =
            _param.airdropStartTime +
            _param.airdropDuration *
            1 days;

        require(_param.dexRouter != address(0), "zero dexRouter address");
        dexRouter = IUniswapV2Router02(_param.dexRouter);

        require(_param.hexToken != address(0), "zero hexToken address");
        require(_param.pairToken != address(0), "zero pairToken address");
        require(_param.hexitToken != address(0), "zero hexit token address");
        hexToken = _param.hexToken;
        pairToken = _param.pairToken;
        hexitToken = _param.hexitToken;

        require(
            _param.rateForSacrifice + _param.rateForAirdrop == FIXED_POINT,
            "distRate: invalid rate"
        );
        rateForSacrifice = _param.rateForSacrifice;
        rateForAirdrop = _param.rateForAirdrop;

        require(
            _param.sacrificeDistRate + _param.sacrificeLiquidityRate ==
                FIXED_POINT,
            "sacrificeRate: invalid rate"
        );
        sacrificeDistRate = _param.sacrificeDistRate;
        sacrificeLiquidityRate = _param.sacrificeLiquidityRate;

        require(
            _param.airdropDistRateForHexHolder +
                _param.airdropDistRateForHEXITHolder ==
                FIXED_POINT,
            "airdropRate: invalid rate"
        );
        airdropDistRateForHexHolder = _param.airdropDistRateForHexHolder;
        airdropDistRateForHEXITHolder = _param.airdropDistRateForHEXITHolder;

        require(
            _param.stakingContract != address(0),
            "zero staking contract address"
        );
        require(_param.teamWallet != address(0), "zero team wallet address");
        stakingContract = _param.stakingContract;
        teamWallet = _param.teamWallet;

        sacrificeId = 1;
        airdropId = 1;

        _distributeHEXITAmount();

        __Ownable_init();
    }

    /// @inheritdoc IHexOneSacrifice
    function afterSacrificeDuration() external view override returns (bool) {
        return block.timestamp > sacrificeEndTime;
    }

    /// @inheritdoc IHexOneBootstrap
    function setEscrowContract(address _escrowCA) external override onlyOwner {
        require(_escrowCA != address(0), "zero escrow contract address");
        escrowCA = _escrowCA;
    }

    /// @inheritdoc IHexOneBootstrap
    function setPriceFeedCA(address _priceFeed) external override onlyOwner {
        require(_priceFeed != address(0), "zero priceFeed contract address");
        hexOnePriceFeed = _priceFeed;
    }

    /// @inheritdoc IHexOneSacrifice
    function isSacrificeParticipant(
        address _user
    ) external view returns (bool) {
        return sacrificeParticipants.contains(_user);
    }

    /// @inheritdoc IHexOneAirdrop
    function getAirdropRequestors() external view returns (address[] memory) {
        return airdropRequestors.values();
    }

    /// @inheritdoc IHexOneSacrifice
    function getSacrificeParticipants()
        external
        view
        returns (address[] memory)
    {
        return sacrificeParticipants.values();
    }

    /// @inheritdoc IHexOneBootstrap
    function setAllowedTokens(
        address[] memory _tokens,
        bool _enable
    ) external override onlyOwner {
        uint256 length = _tokens.length;
        require(length > 0, "invalid length");

        for (uint256 i = 0; i < length; i++) {
            address token = _tokens[i];
            allowedTokens[token].enable = true;
            allowedTokens[token].decimals = TokenUtils.expectDecimals(token);
        }
        emit AllowedTokensSet(_tokens, _enable);
    }

    /// @inheritdoc IHexOneBootstrap
    function setTokenWeight(
        address[] memory _tokens,
        uint16[] memory _weights
    ) external override onlyOwner {
        uint256 length = _tokens.length;
        require(length > 0, "invalid length");
        require(block.timestamp < sacrificeStartTime, "too late to set");

        for (uint256 i = 0; i < length; i++) {
            address token = _tokens[i];
            uint16 weight = _weights[i];
            require(weight >= FIXED_POINT, "invalid weight");
            allowedTokens[token].weight = weight;
        }
        emit TokenWeightSet(_tokens, _weights);
    }

    //! Sacrifice Logic
    /// @inheritdoc IHexOneSacrifice
    function getAmountForSacrifice(
        uint256 _dayIndex
    ) public view override returns (uint256) {
        uint256 todayIndex = getCurrentSacrificeDay();
        require(_dayIndex <= todayIndex, "invalid day index");

        return _calcSupplyAmountForSacrifice(_dayIndex);
    }

    /// @inheritdoc IHexOneSacrifice
    function getCurrentSacrificeDay() public view override returns (uint256) {
        if (block.timestamp <= sacrificeStartTime) {
            return 0;
        }
        uint256 elapsedTime = block.timestamp - sacrificeStartTime;
        return elapsedTime / 1 days + 1;
    }

    /// @inheritdoc IHexOneSacrifice
    function sacrificeToken(
        address _token,
        uint256 _amount
    ) external whenSacrificeDuration onlyAllowedToken(_token) {
        address sender = msg.sender;
        require(sender != address(0), "zero caller address");
        require(_token != address(0), "zero token address");
        require(_amount > 0, "zero amount");

        IERC20(_token).safeTransferFrom(sender, address(this), _amount);
        _updateSacrificeInfo(sender, _token, _amount);
    }

    /// @inheritdoc IHexOneSacrifice
    function getUserSacrificeInfo(
        address _user
    ) external view override returns (SacrificeInfo[] memory) {
        uint256[] memory ids = userSacrificedIds[_user].values();
        uint256 length = ids.length;

        SacrificeInfo[] memory info = new SacrificeInfo[](length);
        for (uint256 i = 0; i < ids.length; i++) {
            info[i] = sacrificeInfos[ids[i]];
            info[i].day = sacrificeInfos[ids[i]].day + 1;
        }

        return info;
    }

    /// @inheritdoc IHexOneSacrifice
    function claimRewardsForSacrifice(uint256 _sacrificeId) external override {
        address sender = msg.sender;
        SacrificeInfo storage info = sacrificeInfos[_sacrificeId];
        uint256 curDay = getCurrentSacrificeDay();
        require(
            userSacrificedIds[sender].contains(_sacrificeId),
            "invalid sacrificeId"
        );
        require(!info.claimed, "already claimed");
        require(info.day < curDay, "sacrifice duration");

        info.claimed = true;

        uint256 dayIndex = info.day;
        uint256 totalWeight = totalSacrificeWeight[dayIndex];
        uint256 userWeight = info.sacrificedWeight;
        uint256 supplyAmount = _calcSupplyAmountForSacrifice(dayIndex);
        uint256 rewardsAmount = ((supplyAmount * userWeight) / totalWeight);

        uint256 sacrificeRewardsAmount = (rewardsAmount * rateForSacrifice) /
            FIXED_POINT;
        userRewardsForSacrifice[sender] += sacrificeRewardsAmount;
        IHEXIT(hexitToken).mintToken(sacrificeRewardsAmount, sender);

        emit RewardsDistributed();
    }

    //! Airdrop logic
    /// @inheritdoc IHexOneAirdrop
    function getCurrentAirdropDay() public view override returns (uint256) {
        return (block.timestamp - airdropStartTime) / 1 days;
    }

    function getAirdropSupplyAmount(
        uint256 _dayIndex
    ) external view override returns (uint256) {
        uint256 curDay = getCurrentAirdropDay();
        require(_dayIndex <= curDay, "invalid dayIndex");
        return _calcAmountForAirdrop(_dayIndex);
    }

    /// @inheritdoc IHexOneAirdrop
    function getCurrentAirdropInfo(
        address _user
    ) external view override returns (AirdropPoolInfo memory) {
        uint256 curDay = getCurrentAirdropDay();
        uint256 curPoolAmount = requestedAmountInfo[curDay];
        uint256 sacrificeAmount = userSacrificedUSD[_user];
        uint256 shareAmount = _getTotalShareUSD(_user);
        uint256 userWeight = (sacrificeAmount * airdropDistRateForHEXITHolder) /
            FIXED_POINT +
            (shareAmount * airdropDistRateForHexHolder) /
            FIXED_POINT;
        uint16 shareOfPool = uint16(
            (userWeight * FIXED_POINT) / (curPoolAmount + userWeight)
        );
        return
            AirdropPoolInfo({
                sacrificedAmount: sacrificeAmount,
                stakingShareAmount: shareAmount,
                curAirdropDay: curDay + 1,
                curDayPoolAmount: curPoolAmount + userWeight,
                curDaySupplyHEXIT: _calcAmountForAirdrop(curDay),
                sacrificeDistRate: airdropDistRateForHEXITHolder,
                stakingDistRate: airdropDistRateForHexHolder,
                shareOfPool: shareOfPool
            });
    }

    /// @inheritdoc IHexOneAirdrop
    function requestAirdrop() external override whenAirdropDuration {
        address sender = msg.sender;
        RequestAirdrop storage userInfo = requestAirdropInfo[sender];
        require(sender != address(0), "zero caller address");
        require(userInfo.airdropId == 0, "already requested");

        userInfo.airdropId = (airdropId++);
        userInfo.requestedDay = getCurrentAirdropDay();
        userInfo.sacrificeUSD = userSacrificedUSD[sender];
        userInfo.sacrificeMultiplier = airdropDistRateForHexHolder;
        userInfo.hexShares = _getTotalShareUSD(sender);
        userInfo.hexShareMultiplier = airdropDistRateForHEXITHolder;
        userInfo.totalUSD =
            (userInfo.sacrificeUSD * userInfo.sacrificeMultiplier) /
            FIXED_POINT +
            (userInfo.hexShares * userInfo.hexShareMultiplier) /
            FIXED_POINT;
        require(userInfo.totalUSD > 0, "not have eligible assets for airdrop");
        userInfo.claimedAmount = 0;
        requestedAmountInfo[userInfo.requestedDay] += userInfo.totalUSD;
        airdropRequestors.add(sender);
    }

    /// @inheritdoc IHexOneAirdrop
    function claimAirdrop() external override {
        address sender = msg.sender;
        RequestAirdrop storage userInfo = requestAirdropInfo[sender];

        uint256 dayIndex = userInfo.requestedDay;
        uint256 curDay = getCurrentAirdropDay();
        require(sender != address(0), "zero caller address");
        require(userInfo.airdropId > 0, "not requested");
        require(!userInfo.claimed, "already claimed");
        require(curDay > dayIndex, "too soon");

        uint256 rewardsAmount = _calcUserRewardsForAirdrop(sender, dayIndex);
        if (rewardsAmount > 0) {
            IHEXIT(hexitToken).mintToken(rewardsAmount, sender);
        }
        userInfo.claimedAmount = rewardsAmount;
        userInfo.claimed = true;
        airdropRequestors.remove(sender);
    }

    /// @inheritdoc IHexOneAirdrop
    function getAirdropClaimHistory(
        address _user
    ) external view override returns (AirdropClaimHistory memory) {
        AirdropClaimHistory memory history;
        RequestAirdrop memory info = requestAirdropInfo[_user];
        if (!info.claimed) {
            return history;
        }

        uint256 dayIndex = info.requestedDay;
        history = AirdropClaimHistory({
            airdropId: info.airdropId,
            requestedDay: dayIndex,
            sacrificeUSD: info.sacrificeUSD,
            sacrificeMultiplier: info.sacrificeMultiplier,
            hexShares: info.hexShares,
            hexShareMultiplier: info.hexShareMultiplier,
            totalUSD: info.totalUSD,
            dailySupplyAmount: _calcAmountForAirdrop(dayIndex),
            claimedAmount: info.claimedAmount,
            shareOfPool: uint16(
                (info.totalUSD * FIXED_POINT) / requestedAmountInfo[dayIndex]
            )
        });

        return history;
    }

    /// @inheritdoc IHexOneBootstrap
    function generateAdditionalTokens() external onlyOwner {
        require(block.timestamp > airdropEndTime, "before airdrop ends");
        uint256 totalAmount = airdropHEXITAmount + HEXITAmountForSacrifice;
        uint256 amountForStaking = (totalAmount * additionalRateForStaking) /
            FIXED_POINT;
        uint256 amountForTeam = (totalAmount * additionalRateForTeam) /
            FIXED_POINT;

        IHEXIT(hexitToken).mintToken(amountForStaking, address(this));
        IHEXIT(hexitToken).approve(stakingContract, amountForStaking);
        IHEXIT(hexitToken).mintToken(amountForTeam, teamWallet);

        IHexOneStaking(stakingContract).purchaseHexit(amountForStaking);
    }

    /// @inheritdoc IHexOneBootstrap
    function withdrawToken(address _token) external override onlyOwner {
        require(block.timestamp > sacrificeEndTime, "sacrifice duration");

        uint256 balance = 0;
        if (_token == address(0)) {
            balance = address(this).balance;
            require(balance > 0, "zero balance");
            (bool sent, ) = (owner()).call{value: balance}("");
            require(sent, "sending ETH failed");
        } else {
            balance = IERC20(_token).balanceOf(address(this));
            require(balance > 0, "zero balance");
            IERC20(_token).safeTransfer(owner(), balance);
        }

        emit Withdrawed(_token, balance);
    }

    receive()
        external
        payable
        whenSacrificeDuration
        onlyAllowedToken(address(0))
    {
        _updateSacrificeInfo(msg.sender, address(0), msg.value);
    }

    function _updateSacrificeInfo(
        address _participant,
        address _token,
        uint256 _amount
    ) internal {
        uint256 usdValue = IHexOnePriceFeed(hexOnePriceFeed).getBaseTokenPrice(
            _token,
            _amount
        );
        (uint256 dayIndex, ) = _getSupplyAmountForSacrificeToday();

        uint16 weight = allowedTokens[_token].weight == 0
            ? FIXED_POINT
            : allowedTokens[_token].weight;
        uint256 sacrificeWeight = (usdValue * weight) / FIXED_POINT;
        totalSacrificeWeight[dayIndex] += sacrificeWeight;
        totalSacrificeTokenAmount[dayIndex][_token] += _amount;
        sacrificeUserWeight[dayIndex][_participant] += sacrificeWeight;
        userSacrificedUSD[_participant] += usdValue;

        if (!sacrificeParticipants.contains(_participant)) {
            sacrificeParticipants.add(_participant);
        }

        sacrificeInfos[sacrificeId] = SacrificeInfo(
            sacrificeId,
            dayIndex,
            getAmountForSacrifice(dayIndex),
            _amount,
            sacrificeWeight,
            usdValue,
            _token,
            IToken(_token).symbol(),
            weight,
            false
        );
        userSacrificedIds[_participant].add(sacrificeId++);

        _processSacrifice(_token, _amount);
    }

    function _getTotalShareUSD(address _user) internal view returns (uint256) {
        uint256 stakeCount = IHexToken(hexToken).stakeCount(_user);
        if (stakeCount == 0) return 0;

        uint256 shares = 0; // decimals = 12
        for (uint256 i = 0; i < stakeCount; i++) {
            IHexToken.StakeStore memory stakeStore = IHexToken(hexToken)
                .stakeLists(_user, i);
            shares += stakeStore.stakeShares;
        }

        IHexToken.GlobalsStore memory globals = IHexToken(hexToken).globals();
        uint256 shareRate = uint256(globals.shareRate); // decimals = 1
        uint256 hexAmount = uint256((shares * shareRate) / 10 ** 5);

        return IHexOnePriceFeed(hexOnePriceFeed).getHexTokenPrice(hexAmount);
    }

    function _getSupplyAmountForSacrificeToday()
        internal
        view
        returns (uint256 day, uint256 supplyAmount)
    {
        uint256 elapsedTime = block.timestamp - sacrificeStartTime;
        uint256 dayIndex = elapsedTime / 1 days;
        supplyAmount = _calcSupplyAmountForSacrifice(dayIndex);

        return (dayIndex, 0);
    }

    function _calcSupplyAmountForSacrifice(
        uint256 _dayIndex
    ) internal view returns (uint256) {
        uint256 supplyAmount = sacrificeInitialSupply;
        for (uint256 i = 0; i < _dayIndex; i++) {
            supplyAmount =
                (supplyAmount * (FIXED_POINT - supplyCropRateForSacrifice)) /
                FIXED_POINT;
        }

        return supplyAmount;
    }

    function _calcAmountForAirdrop(
        uint256 _dayIndex
    ) internal view returns (uint256) {
        uint256 airdropAmount = airdropHEXITAmount;
        for (uint256 i = 0; i <= _dayIndex; i++) {
            airdropAmount =
                (airdropAmount * distRateForDailyAirdrop) /
                FIXED_POINT;
        }
        return airdropAmount;
    }

    function _processSacrifice(address _token, uint256 _amount) internal {
        uint256 amountForDistribution = (_amount * sacrificeDistRate) /
            FIXED_POINT;
        uint256 amountForLiquidity = _amount - amountForDistribution;

        /// distribution
        _swapToken(_token, hexToken, escrowCA, amountForDistribution);

        /// liquidity
        uint256 swapAmountForLiquidity = amountForLiquidity / 2;
        _swapToken(_token, hexToken, address(this), swapAmountForLiquidity);
        _swapToken(_token, pairToken, address(this), swapAmountForLiquidity);
        uint256 pairTokenBalance = IERC20(pairToken).balanceOf(address(this));
        uint256 hexTokenBalance = IERC20(hexToken).balanceOf(address(this));
        if (pairTokenBalance > 0 && hexTokenBalance > 0) {
            IERC20(pairToken).approve(address(dexRouter), pairTokenBalance);
            IERC20(hexToken).approve(address(dexRouter), hexTokenBalance);
            dexRouter.addLiquidity(
                pairToken,
                hexToken,
                pairTokenBalance,
                hexTokenBalance,
                0,
                0,
                address(this),
                block.timestamp
            );
        }
    }

    /// @notice Swap sacrifice token to hex/pair token.
    /// @param _token The address of sacrifice token.
    /// @param _targetToken The address of token to be swapped to.
    /// @param _recipient The address of recipient.
    /// @param _amount The amount of sacrifice token.
    function _swapToken(
        address _token,
        address _targetToken,
        address _recipient,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;

        address[] memory path = new address[](2);
        if (_token != _targetToken) {
            path[0] = _token == address(0) ? dexRouter.WAVAX() : _token;
            path[1] = _targetToken;

            if (_token == address(0)) {
                dexRouter.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
                    value: _amount
                }(0, path, _recipient, block.timestamp);
            } else {
                IERC20(_token).approve(address(dexRouter), _amount);
                dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amount,
                    0,
                    path,
                    _recipient,
                    block.timestamp
                );
            }
        } else {
            IERC20(_targetToken).safeTransfer(_recipient, _amount);
        }
    }

    function _calcUserRewardsForAirdrop(
        address _user,
        uint256 _dayIndex
    ) internal view returns (uint256) {
        RequestAirdrop memory userInfo = requestAirdropInfo[_user];
        uint256 totalAmount = requestedAmountInfo[_dayIndex];
        uint256 supplyAmount = _calcAmountForAirdrop(_dayIndex);

        return (supplyAmount * userInfo.totalUSD) / totalAmount;
    }

    function _distributeHEXITAmount() internal {
        uint256 sacrificeDuration = sacrificeEndTime - sacrificeStartTime;
        sacrificeDuration = sacrificeDuration / 1 days;
        for (uint256 i = 0; i < sacrificeDuration; i++) {
            uint256 supplyAmount = _calcSupplyAmountForSacrifice(i);
            uint256 sacrificeRewardsAmount = (supplyAmount * rateForSacrifice) /
                FIXED_POINT;
            uint256 airdropAmount = supplyAmount - sacrificeRewardsAmount;
            airdropHEXITAmount += airdropAmount;
            HEXITAmountForSacrifice += sacrificeRewardsAmount;
        }
    }

    uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHEXIT is IERC20 {
    /// @notice Mint $HEXIT token to recipient.
    /// @dev Only HexOneProtocol can call this function.
    /// @param _amount The amount of $HEXIT to mint.
    /// @param _recipient The address of recipient.
    function mintToken(uint256 _amount, address _recipient) external;

    /// @notice Set admin address. HexBootstrap is admin.
    /// @dev This function can be called by only owner.
    /// @param _bootstrap The address of HexBootstrap.
    function setBootstrap(address _bootstrap) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IHexOneAirdrop {
    struct RequestAirdrop {
        uint256 airdropId;
        uint256 requestedDay;
        uint256 sacrificeUSD;
        uint256 sacrificeMultiplier;
        uint256 hexShares;
        uint256 hexShareMultiplier;
        uint256 totalUSD;
        uint256 claimedAmount;
        bool claimed;
    }

    struct AirdropClaimHistory {
        uint256 airdropId;
        uint256 requestedDay;
        uint256 sacrificeUSD;
        uint256 sacrificeMultiplier;
        uint256 hexShares;
        uint256 hexShareMultiplier;
        uint256 totalUSD;
        uint256 dailySupplyAmount;
        uint256 claimedAmount;
        uint16 shareOfPool;
    }

    struct AirdropPoolInfo {
        uint256 sacrificedAmount;
        uint256 stakingShareAmount;
        uint256 curAirdropDay;
        uint256 curDayPoolAmount;
        uint256 curDaySupplyHEXIT;
        uint16 sacrificeDistRate;
        uint16 stakingDistRate;
        uint16 shareOfPool;
    }

    /// @notice Get left airdrop requestors.
    function getAirdropRequestors() external view returns (address[] memory);

    /// @notice Get airdrop claim history
    function getAirdropClaimHistory(
        address _user
    ) external view returns (AirdropClaimHistory memory);

    /// @notice Get current airdrop day index.
    function getCurrentAirdropDay() external view returns (uint256);

    /// @notice
    function getCurrentAirdropInfo(
        address _user
    ) external view returns (AirdropPoolInfo memory);

    /// @notice Request airdrop.
    /// @dev It can be called in airdrop duration and
    ///      each person can call this function only one time.
    function requestAirdrop() external;

    /// @notice Claim HEXIT token as airdrop.
    /// @dev If users have requests that didn't claim yet, they can request claim.
    function claimAirdrop() external;

    /// @notice Get HEXIT supply amount for airdrop by dayIndex.
    function getAirdropSupplyAmount(
        uint256 _dayIndex
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./IHexOneSacrifice.sol";
import "./IHexOneAirdrop.sol";

interface IHexOneBootstrap is IHexOneSacrifice, IHexOneAirdrop {
    struct Token {
        uint16 weight;
        uint8 decimals;
        bool enable;
    }

    struct Param {
        address hexOnePriceFeed;
        address dexRouter;
        address hexToken;
        address pairToken;
        address hexitToken;
        address stakingContract;
        address teamWallet;
        uint256 sacrificeStartTime;
        uint256 airdropStartTime;
        uint16 sacrificeDuration;
        uint16 airdropDuration;
        // rate information
        uint16 rateForSacrifice;
        uint16 rateForAirdrop;
        uint16 sacrificeDistRate;
        uint16 sacrificeLiquidityRate;
        uint16 airdropDistRateForHexHolder;
        uint16 airdropDistRateForHEXITHolder;
    }

    /// @notice Set escrow contract address.
    /// @dev Only owner can call this function.
    function setEscrowContract(address _escrowCA) external;

    /// @notice Set hexOnePriceFeed contract address.
    /// @dev Only owner can call this function.
    /// @param _priceFeed The address of hexOnePriceFeed contract.
    function setPriceFeedCA(address _priceFeed) external;

    /// @notice Add/Remove allowed tokens for sacrifice.
    /// @dev Only owner can call this function.
    /// @param _tokens The address of tokens.
    /// @param _enable Add/Remove = true/false.
    function setAllowedTokens(address[] memory _tokens, bool _enable) external;

    /// @notice Set tokens weight.
    /// @dev Only owner can call this function.
    ///      Can't be modified after sacrifice started.
    /// @param _tokens The address of tokens.
    /// @param _weights The weight of tokens.
    function setTokenWeight(
        address[] memory _tokens,
        uint16[] memory _weights
    ) external;

    /// @notice Generate additional HEXIT tokens and send it to staking contract and team wallet.
    /// @dev it can be called by only owner and also only after airdrop ends.
    function generateAdditionalTokens() external;

    /// @notice Withdraw token to owner address.
    /// @dev This can be called by only owner and also when only after sacrifice finished.
    function withdrawToken(address _token) external;

    // function getAirdropClaimHistory() external view returns ()

    event AllowedTokensSet(address[] tokens, bool enable);

    event TokenWeightSet(address[] tokens, uint16[] weights);

    event Withdrawed(address token, uint256 amount);

    event RewardsDistributed();
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IHexOnePriceFeed {
    function setPriceFeed(address _baseToken, address _priceFeed) external;

    function setMultiPriceFeed(
        address[] memory _baseTokens,
        address[] memory _priceFeed
    ) external;

    function getBaseTokenPrice(
        address _baseToken,
        uint256 _amount
    ) external view returns (uint256);

    function getHexTokenPrice(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IHexOneSacrifice {
    struct SacrificeInfo {
        uint256 sacrificeId;
        uint256 day;
        uint256 supplyAmount;
        uint256 sacrificedAmount;
        uint256 sacrificedWeight;
        uint256 usdValue;
        address sacrificeToken;
        string sacrificeTokenSymbol;
        uint16 multiplier;
        bool claimed;
    }

    /// @notice Check if now is after sacrificeEndTime.
    function afterSacrificeDuration() external view returns (bool);

    /// @notice minted HEXIT amount for sacrifice.
    function HEXITAmountForSacrifice()
        external
        view
        returns (uint256 HEXITAmountForSacrifice);

    /// @notice received HEXIT token amount of _user for sacrifice.
    function userRewardsForSacrifice(
        address _user
    ) external view returns (uint256);

    /// @notice Check if user is sacrifice participant.
    function isSacrificeParticipant(address _user) external view returns (bool);

    function getUserSacrificeInfo(
        address _user
    ) external view returns (SacrificeInfo[] memory);

    /// @notice Get sacrifice participants.
    function getSacrificeParticipants()
        external
        view
        returns (address[] memory);

    /// @notice Get HEXIT amount for sacrifice by day index.
    function getAmountForSacrifice(
        uint256 _dayIndex
    ) external view returns (uint256);

    /// @notice Get current sacrifice day index.
    function getCurrentSacrificeDay() external view returns (uint256);

    /// @notice Attend to sacrifice.
    /// @dev Anyone can attend to this but should do this with allowed token.
    function sacrificeToken(address _token, uint256 _amount) external;

    /// @notice Claim HEXIT as rewards for sacrifice.
    function claimRewardsForSacrifice(uint256 _sacrificeId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IHexOneStaking {
    struct DistTokenWeight {
        uint16 hexDistRate;
        uint16 hexitDistRate;
    }

    struct StakingInfo {
        uint256 stakedTime;
        uint256 claimedHexAmount;
        uint256 claimedHexitAmount;
        uint256 stakedAmount;
        uint256 hexShareAmount;
        uint256 hexitShareAmount;
        address stakedToken;
        address staker;
    }

    struct RewardsPool {
        uint256 hexPool;
        uint256 hexitPool;
        uint256 distributedHex;
        uint256 distributedHexit;
    }

    struct UserStakingStatus {
        address token;
        uint256 stakedAmount;
        uint256 earnedHexAmount;
        uint256 earnedHexitAmount;
        uint256 claimableHexAmount;
        uint256 claimableHexitAmount;
        uint256 stakedTime;
        uint256 totalLockedUSD;
        uint256 totalLockedAmount;
        uint16 shareOfPool;
        uint16 hexAPR;
        uint16 hexitAPR;
        uint16 hexMultiplier;
        uint16 hexitMultiplier;
    }

    function purchaseHex(uint256 _amount) external;

    function purchaseHexit(uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IHexToken {
    struct GlobalsStore {
        // 1
        uint72 lockedHeartsTotal;
        uint72 nextStakeSharesTotal;
        uint40 shareRate;
        uint72 stakePenaltyTotal;
        // 2
        uint16 dailyDataCount;
        uint72 stakeSharesTotal;
        uint40 latestStakeId;
        uint128 claimStats;
    }

    struct StakeStore {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;
    }

    function globals() external view returns (GlobalsStore memory);

    /**
     * @dev PUBLIC FACING: Open a stake.
     * @param newStakedHearts Number of Hearts to stake
     * @param newStakedDays Number of days to stake
     */
    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external;

    /**
     * @dev PUBLIC FACING: Closes a stake. The order of the stake list can change so
     * a stake id is used to reject stale indexes.
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;

    /**
     * @dev PUBLIC FACING: Return the current stake count for a staker address
     * @param stakerAddr Address of staker
     */
    function stakeCount(address stakerAddr)
        external
        view
        returns (uint256);

    function stakeLists(address stakerAddr, uint256 stakeIndex) external view returns (StakeStore memory);

    function currentDay() external view returns (uint256);

    function dailyData(uint256 dayIndex) external view returns (
        uint72 dayPayoutTotal,
        uint72 dayStakeSharesTotal,
        uint56 dayUnclaimedSatoshisTotal
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountAVAX, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

library TokenUtils {
    /// @notice An error used to indicate that a call to an ERC20 contract failed.
    ///
    /// @param target  The target address.
    /// @param success If the call to the token was a success.
    /// @param data    The resulting data from the call. This is error data when the call was not a success. Otherwise,
    ///                this is malformed data when the call was a success.
    error ERC20CallFailed(address target, bool success, bytes data);

    /// @dev A safe function to get the decimals of an ERC20 token.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token The target token.
    ///
    /// @return The amount of decimals of the token.
    function expectDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        if (!success || data.length < 32) {
            revert ERC20CallFailed(token, success, data);
        }

        return abi.decode(data, (uint8));
    }
   
}