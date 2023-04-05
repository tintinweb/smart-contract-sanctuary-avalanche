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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IHexOneProtocol.sol";
import "./interfaces/IHexOneBootstrap.sol";
import "./interfaces/IHexOneVault.sol";
import "./interfaces/IHexOneEscrow.sol";
import "./interfaces/IHexOnePriceFeed.sol";

contract HexOneEscrow is OwnableUpgradeable, IHexOneEscrow {
    using SafeERC20 for IERC20;

    /// @dev The address of HexOneBootstrap contract.
    address public hexOneBootstrap;

    /// @dev The address of hex token.
    address public hexToken;

    /// @dev The address of $HEX1 token.
    address public hexOneToken;

    /// @dev The address of HexOneProtocol.
    address public hexOneProtocol;

    /// @dev The address of HexOnePriceFeed.
    address public hexOnePriceFeed;

    uint256 public borrowedAmount;

    uint256 public stakedHexAmount;

    /// @dev Flag to show hex token already deposited or not.
    bool public collateralDeposited;

    modifier onlyAfterSacrifice() {
        require(
            IHexOneBootstrap(hexOneBootstrap).afterSacrificeDuration(),
            "only after sacrifice"
        );
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _hexOneBootstrap,
        address _hexToken,
        address _hexOneToken,
        address _hexOneProtocol,
        address _hexOnePriceFeed
    ) public initializer {
        require(
            _hexOneBootstrap != address(0),
            "zero HexOneBootstrap contract address"
        );
        require(_hexToken != address(0), "zero Hex token address");
        require(_hexOneToken != address(0), "zero HexOne token address");
        require(_hexOneProtocol != address(0), "zero HexOneProtocol address");
        require(_hexOnePriceFeed != address(0), "zero HexOnePriceFeed address");

        hexOneBootstrap = _hexOneBootstrap;
        hexToken = _hexToken;
        hexOneToken = _hexOneToken;
        hexOneProtocol = _hexOneProtocol;
        hexOnePriceFeed = _hexOnePriceFeed;
        __Ownable_init();
    }

    /// @inheritdoc IHexOneEscrow
    function balanceOfHex() public view override returns (uint256) {
        return IERC20(hexToken).balanceOf(address(this));
    }

    /// @inheritdoc IHexOneEscrow
    function depositCollateralToHexOneProtocol(
        uint16 _duration
    ) external override onlyAfterSacrifice onlyOwner {
        uint256 collateralAmount = balanceOfHex();
        require(collateralAmount > 0, "no collateral to deposit");
        stakedHexAmount = collateralAmount;

        IERC20(hexToken).approve(hexOneProtocol, collateralAmount);
        IHexOneProtocol(hexOneProtocol).depositCollateral(
            hexToken,
            collateralAmount,
            _duration
        );

        collateralDeposited = true;

        _distributeHexOne();
    }

    /// @inheritdoc IHexOneEscrow
    function reDepositCollateral() external override onlyAfterSacrifice {
        require(collateralDeposited, "collateral not deposited yet");

        IHexOneVault hexOneVault = IHexOneVault(
            IHexOneProtocol(hexOneProtocol).getVaultAddress(hexToken)
        );
        IHexOneVault.DepositShowInfo[] memory depositInfos = hexOneVault
            .getUserInfos(address(this));
        require(depositInfos.length > 0, "not deposit pool");
        uint256 depositId = depositInfos[0].depositId;
        stakedHexAmount = IHexOneProtocol(hexOneProtocol).claimCollateral(
            hexToken,
            depositId
        );

        _distributeHexOne();
    }

    /// @inheritdoc IHexOneEscrow
    function getOverview(
        address _user
    ) external view override returns (EscrowOverview memory) {
        EscrowOverview memory overview;
        if (collateralDeposited) {
            IHexOneVault hexOneVault = IHexOneVault(
                IHexOneProtocol(hexOneProtocol).getVaultAddress(hexToken)
            );
            IHexOneVault.DepositShowInfo[] memory showInfo = hexOneVault
                .getUserInfos(address(this));
            IHexOneVault.DepositShowInfo memory singleInfo = showInfo[0];
            uint256 totalAmount = IHexOneBootstrap(hexOneBootstrap)
                .HEXITAmountForSacrifice();
            uint256 participantAmount = IHexOneBootstrap(hexOneBootstrap)
                .userRewardsForSacrifice(_user);
            overview = EscrowOverview({
                totalUSDValue: IHexOnePriceFeed(hexOnePriceFeed)
                    .getHexTokenPrice(singleInfo.depositAmount),
                startTime: singleInfo.lockedHexDay,
                endTime: singleInfo.endHexDay,
                curDay: singleInfo.curHexDay,
                hexAmount: singleInfo.depositAmount,
                effectiveAmount: singleInfo.effectiveAmount,
                borrowedAmount: singleInfo.mintAmount,
                initUSDValue: singleInfo.initialHexPrice,
                shareOfPool: uint16((participantAmount * 1000) / totalAmount)
            });
        }

        return overview;
    }

    /// @notice Distribute $HEX1 token to sacrifice participants.
    /// @dev the distribute amount is based on amount of sacrifice that participant did.
    function _distributeHexOne() internal {
        uint256 hexOneBalance = IERC20(hexOneToken).balanceOf(address(this));
        borrowedAmount += hexOneBalance;
        if (hexOneBalance == 0) return;

        address[] memory participants = IHexOneBootstrap(hexOneBootstrap)
            .getSacrificeParticipants();
        uint256 length = participants.length;
        require(length > 0, "no sacrifice participants");

        uint256 totalAmount = IHexOneBootstrap(hexOneBootstrap)
            .HEXITAmountForSacrifice();
        for (uint256 i = 0; i < length; i++) {
            address participant = participants[i];
            uint256 participantAmount = IHexOneBootstrap(hexOneBootstrap)
                .userRewardsForSacrifice(participant);
            uint256 rewards = (hexOneBalance * participantAmount) / totalAmount;
            if (rewards > 0) {
                IERC20(hexOneToken).safeTransfer(participant, rewards);
            }
        }
    }

    uint256[100] private __gap;
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

interface IHexOneEscrow {
    struct EscrowOverview {
        uint256 totalUSDValue;
        uint256 startTime;
        uint256 endTime;
        uint256 curDay;
        uint256 hexAmount;
        uint256 effectiveAmount;
        uint256 borrowedAmount;
        uint256 initUSDValue;
        uint16 shareOfPool;
    }

    /// @notice Get balance of Hex that escrow contract hold.
    function balanceOfHex() external view returns (uint256);

    /// @notice deposit Hex token to HexOneProtocol.
    /// @dev This function can be called when only sacrifice finished
    ///      and also can be called by only Owner.
    ///      escrow contract deposits Hex token as commitType and
    ///      distribute received $HEX1 to sacrifice participants.
    function depositCollateralToHexOneProtocol(uint16 _duration) external;

    /// @notice It calls claimCollateral function of hexOneProtocol and
    ///         gets more $HEX1 token and distrubute it to sacrifice participants.
    function reDepositCollateral() external;

    function getOverview(
        address _user
    ) external view returns (EscrowOverview memory);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IHexOneProtocol {

    struct Fee {
        uint16 feeRate;
        bool enabled;
    }

    /// @notice Add/Remove vaults.
    /// @dev Only owner can call this function.
    /// @param _vaults The address of vaults.
    /// @param _add Add/Remove = true/false.
    function setVaults(address[] memory _vaults, bool _add) external;

    /// @notice Set HexOneEscrow conract address.
    /// @dev Only owner can call this function.
    function setEscrowContract(address _escrowCA) external;

    /// @notice Set stakingMaster contract address.
    /// @dev Only owner can call this function.
    /// @param _stakingMaster The address of staking Pool.
    function setStakingPool(address _stakingMaster) external;

    /// @notice Set Min stake duration.
    /// @dev Only owner can call this function.
    /// @param _minDuration The min stake duration days.
    function setMinDuration(uint256 _minDuration) external;

    /// @notice Set Max stake duration.
    /// @dev Only owner can call this function.
    /// @param _maxDuration The max stake duration days.
    function setMaxDuration(uint256 _maxDuration) external;

    /// @notice Set deposit fee by token.
    /// @dev Only owner can call this function.
    /// @param _token The address of token.
    /// @param _fee Deposit fee percent.
    function setDepositFee(address _token, uint16 _fee) external;

    /// @notice Enable/Disable deposit fee by token.
    /// @dev Only owner can call this function.
    /// @param _token The address of token.
    /// @param _enable Enable/Disable = true/false
    function setDepositFeeEnable(address _token, bool _enable) external;

    /// @notice Deposit collateral and receive $HEX1 token.
    /// @param _token The address of collateral to deposit.
    /// @param _amount The amount of collateral to deposit.
    /// @param _duration The duration days.
    function depositCollateral(
        address _token, 
        uint256 _amount, 
        uint16 _duration
    ) external;

    /// @notice Borrow more $HEX1 token based on already deposited collateral.
    /// @param _token The address of token already deposited.
    /// @param _depositId The vault depositId to borrow.
    /// @param _amount The amount of $HEX1 to borrow.
    function borrowHexOne(
        address _token,
        uint256 _depositId,
        uint256 _amount
    ) external;

    /// @notice Claim/restake collateral
    /// @param _token The address of collateral.
    /// @param _depositId The deposit id to claim.
    function claimCollateral(
        address _token,
        uint256 _depositId
    ) external returns (uint256);

    /// @notice Check that token is allowed or not.
    function isAllowedToken(
        address _token
    ) external view returns (bool);

    /// @notice Get vault contract address by token.
    function getVaultAddress(address _token) external view returns (address);

    event HexOneMint(address indexed recipient, uint256 amount);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IHexOneVault {
    struct DepositInfo {
        uint256 vaultDepositId;
        uint256 stakeId;
        uint256 amount;
        uint256 shares;
        uint256 mintAmount;
        uint256 depositedHexDay;
        uint256 initHexPrice;
        uint16 duration;
        uint16 graceDay;
        bool exist;
    }

    struct UserInfo {
        uint256 depositId;
        uint256 shareBalance;
        uint256 depositedBalance;
        uint256 totalBorrowedAmount;
        mapping(uint256 => DepositInfo) depositInfos;
    }

    struct DepositShowInfo {
        uint256 depositId;
        uint256 depositAmount;
        uint256 shareAmount;
        uint256 mintAmount;
        uint256 borrowableAmount;
        uint256 effectiveAmount;
        uint256 initialHexPrice;
        uint256 lockedHexDay;
        uint256 endHexDay;
        uint256 curHexDay;
    }

    struct BorrowableInfo {
        uint256 depositId;
        uint256 borrowableAmount;
    }

    struct VaultDepositInfo {
        address userAddress;
        uint256 userDepositId;
    }

    struct LiquidateInfo {
        address depositor;
        uint256 depositId;
        uint256 curHexDay;
        uint256 endDay;
        uint256 effectiveHex;
        uint256 borrowedHexOne;
        uint256 initHexPrice;
        uint256 currentHexPrice;
        uint256 depositedHexAmount;
        uint256 currentValue;
        uint256 initUSDValue;
        uint256 currentUSDValue;
        uint16 graceDay;
        bool liquidable;
    }

    function baseToken() external view returns (address baseToken);

    /// @notice Get borrowable amount based on already deposited collateral amount.
    function getBorrowableAmounts(
        address _account
    ) external view returns (BorrowableInfo[] memory);

    /// @notice Get total borrowed $HEX1 of user.
    /// @param _account The address of _account.
    function getBorrowedBalance(
        address _account
    ) external view returns (uint256);

    /// @notice Borrow additional $HEX1 from already deposited collateral amount.
    /// @dev If collateral price is increased, there will be profit.
    ///         Based on that profit, depositors can borrow $HEX1 additionally.
    /// @param _depositor The address of depositor (borrower)
    /// @param _vaultDepositId The vault deposit id to borrow.
    /// @param _amount The amount of $HEX1 token.
    function borrowHexOne(
        address _depositor,
        uint256 _vaultDepositId,
        uint256 _amount
    ) external;

    /// @notice Set hexOneProtocol contract address.
    /// @dev Only owner can call this function and
    ///      it should be called as intialize step.
    /// @param _hexOneProtocol The address of hexOneProtocol contract.
    function setHexOneProtocol(address _hexOneProtocol) external;

    /// @notice Deposit collateral and mint $HEX1 token to depositor.
    ///         Collateral should be converted to T-SHARES and return.
    /// @dev Only HexOneProtocol can call this function.
    ///      T-SHARES will be locked for maturity,
    ///      it means deposit can't retrieve collateral before maturity.
    /// @param _depositor The address of depositor.
    /// @param _amount The amount of collateral.
    /// @param _duration The maturity duration.
    /// @return mintAmount The amount of $HEX1 to mint.
    function depositCollateral(
        address _depositor,
        uint256 _amount,
        uint16 _duration
    ) external returns (uint256 mintAmount);

    /// @notice Retrieve collateral after maturity.
    /// @dev Users can claim collateral after maturity.
    /// @return burnAmount Amount of $HEX1 token to burn.
    /// @return mintAmount Amount of $HEX1 token to mint.
    /// @return receivedAmount Amount of claimed hex token.
    function claimCollateral(
        address _claimer,
        uint256 _vaultDepositId,
        bool _restake
    )
        external
        returns (
            uint256 burnAmount,
            uint256 mintAmount,
            uint256 receivedAmount
        );

    /// @notice Get liquidable vault deposit Ids.
    function getLiquidableDeposits()
        external
        view
        returns (LiquidateInfo[] memory);

    /// @notice Get t-share balance of user.
    function getShareBalance(address _account) external view returns (uint256);

    function getUserInfos(
        address _account
    ) external view returns (DepositShowInfo[] memory);

    /// @notice Set limit claim duration.
    /// @dev Only owner can call this function.
    function setLimitClaimDuration(uint16 _duration) external;

    event CollateralClaimed(address indexed claimer, uint256 claimedAmount);

    event CollateralRestaked(
        address indexed staker,
        uint256 restakedAmount,
        uint16 restakeDuration
    );
}