// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/*
 * Game 4
*/
contract BridgesOfFate is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable private token;

    uint256 public gameEnded;
    uint256 public lastUpdateTimeStamp;

    
    uint256[] private _uniqueRN;
    uint256[] private _randomSelectPlayerIndex;

    uint256 private _latestGameId;
    uint256 private _seedNumber;
    uint256 private _narrowingNumberProbility;
    uint256 private _narrowinggameRandomNumber;

    uint256 private constant TURN_PERIOD = 480;
    uint256 private constant SERIES_TWO_FEE = 0.01 ether;

    uint256 private constant _ownerRewarsdsPercent = 25;
    uint256 private constant _winnerRewarsdsPercent = 60;
    uint256 private constant _communityVaultRewarsdsPercent = 15;

    bool public _isNarrowingGameEnded;

    bytes32[] private _gameWinners;
    bytes32[] private _playerOnTile;
    bytes32[] private _selectUnholdPlayerId;
    bytes32[] private _participatePlayerList;
    bytes32[] private _selectSuccessSidePlayerId;

    // 0 =========>>>>>>>>> Owner Address
    // 1 =========>>>>>>>>> community vault Address
    address[2] private _communityOwnerWA;
    
    uint256[11] public buyBackCurve;

    struct GameStatus {
        //Game Start Time
        uint256 startAt;
        //To Handle Latest Stage
        uint256 stageNumber;
        //Last Update Number
        uint256 lastUpdationDay;
        //Balance distribution
        bool isDistribution;
    }

    struct GameItem {
        uint256 day;
        uint256 nftId;
        uint256 stage;
        uint256 startAt;
        uint256 lastJumpTime;
        uint8 nftSeriestype;
        bool ishold;
        bool feeStatus;
        bool lastJumpSide;
        address userWalletAddress;
        bytes32 playerId;
    }

    mapping(bytes32 => GameItem) public playerItem;
    mapping(uint256 => GameStatus) public gameStatusInitialized;

    mapping(uint256 => uint256) private gameRandomNumber;
    
    mapping(bytes32 => uint256) private winnerbalances;
    mapping(address => uint256) private ownerbalances;
    mapping(address => uint256) private vaultbalances;
    
    mapping(uint256 => bytes32[]) private allStagesData;
    mapping(bytes32 => bool) private overFlowPlayerStatus;
    mapping(uint256 => uint256) private titleCapacityAgainestStage; 
    mapping(uint256 => mapping(bool => uint256)) private totalNFTOnTile; 

    event Initialized(uint256 _startAt);
    event claimPlayerReward(bytes32 playerId, uint256 amount);
    event ParticipateOfPlayerInGame(bytes32 playerId, uint256 jumpAt);
    event BulkParticipateOfPlayerInGame(bytes32 playerId, uint256 jumpAt);
    event ParticipateOfPlayerInBuyBackIn(bytes32 playerId, uint256 amount);
    event EntryFee(bytes32 playerId,uint256 nftId,uint256 nftSeries,uint256 feeAmount);
    event ParticipateOfNewPlayerInLateBuyBackIn(bytes32 playerId,uint256 moveAtStage,uint256 amount);

    function initialize() public initializer {
        token = IERC20Upgradeable(0xbB7b5004e80E28Cb384EC44612a621A6a74f92b9);
         __Ownable_init();
        _communityOwnerWA[0] = owner();
        _communityOwnerWA[1] = 0xa04211f86b3a9ce3E11668daF22CB7163B5260A6;
        _narrowingNumberProbility = 15;
        gameEnded = 3;
        _seedNumber = 0;
        _latestGameId = 1;
        buyBackCurve = [0.005 ether,0.01 ether,0.02 ether,0.04 ether,0.08 ether,0.15 ether,0.3 ether,0.6 ether,1.25 ether,2.5 ether,5 ether];
        _isNarrowingGameEnded = false;
    }


    function _gameEndRules() internal view returns (bool) {
        GameStatus storage _gameStatus = gameStatusInitialized[_latestGameId];
        require((_gameStatus.startAt > 0 && block.timestamp >= _gameStatus.startAt),"Game start after intialized time.");
        if (lastUpdateTimeStamp > 0) {
            require(_dayDifferance(block.timestamp, lastUpdateTimeStamp) <=gameEnded,"Game Ended ...!");
        }
        return true;
    }

    function _narrowingGameEndRules() internal view returns (bool) {
        if ((_narrowinggameRandomNumber > 0) && (_narrowinggameRandomNumber < _narrowingNumberProbility) &&
        (_dayDifferance(block.timestamp,gameStatusInitialized[_latestGameId].startAt) > gameStatusInitialized[_latestGameId].lastUpdationDay)) {
            require(_isNarrowingGameEnded == true, "Narrowing Game Ended.");
        }
        return true;
    }

    modifier GameEndRules() {
        _gameEndRules();
        _;
    }

    modifier NarrowingGameEndRules() {
        _narrowingGameEndRules();
        _;
    }


    function _removeForList(uint index) internal {
        delete _gameWinners[index];
    }

    function _balanceOfUser(address _accountOf) internal view returns (uint256) {
        return token.balanceOf(_accountOf);
    }

    function removeSecondListItem(uint index, uint256 _stages) internal {
        bytes32[] storage _stagesData = allStagesData[_stages];
        delete _stagesData[index];
    }

    function treasuryBalance() public view returns (uint256) {
        return _balanceOfUser(address(this));
    }
 
    function _calculateBuyBackIn(uint256 _index) public view returns (uint256) {
        // GameStatus memory _gameStatus = gameStatusInitialized[_latestGameId];
        if (_index > 0) {
            if (_index <= buyBackCurve.length) {
                return buyBackCurve[_index - 1];
            }else{
                return buyBackCurve[_index - 1];
            }
        }
        return 0;
    }

    function getStagesData(uint256 _stage) public view returns (bytes32[] memory) {
        return allStagesData[_stage];
    }

    function _deletePlayerIDForSpecifyStage(uint256 _stage,bytes32 _playerId) internal {
        uint256 _index = _findIndex(_playerId, getStagesData(_stage));
        removeSecondListItem(_index, _stage);
    }

    function _checkSide(uint256 stageNumber,bool userSide) internal view returns (bool) {
        uint256 stage_randomNumber = gameRandomNumber[stageNumber];
        if ((userSide == false && stage_randomNumber < 50) || (userSide == true && stage_randomNumber >= 50)) {
            return true;
        } else {
            return false;
        }
    }

    function _findIndex(bytes32 _fa,bytes32[] memory _playerList) internal pure returns (uint index) {
        for (uint i = 0; i < _playerList.length; i++) {
            if (_playerList[i] == _fa) {
                index = i;
            }
        }
        return index;
    }

    function _dayDifferance(uint256 timeStampTo,uint256 timeStampFrom) public pure returns (uint256) {
        return (timeStampTo - timeStampFrom) / TURN_PERIOD;
    }

    function _computeNextPlayerIdForHolder(address holder,uint256 _nftId,uint8 _seriesIndex) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, _nftId, _seriesIndex));
    }

    function generateRandomArray(uint256 size, uint256 max) public  returns (uint256[] memory) {
        uint256[] memory randomArray = new uint256[](size);
        uint256 randomNumber;
        for (uint256 i = 0; i < size; i++) {
            // Comment Due to Gas issues
            randomNumber = ((_seedNumber - i)  - (((_seedNumber - i) / max) * max));
            randomArray[i] = randomNumber;
            _seedNumber = _seedNumber - 1;
        }

        return randomArray;
    }


    function generateRandomNumbersForGame(uint256 _length) internal  returns (uint8[2] memory) {
        uint8[2] memory numbers;
        uint256 generatedNumber;
        // Execute 5 times (to generate 5 numbers)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp + block.number + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.number)) +
            block.gaslimit +  ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.number)) + block.number
        )));
        for (uint256 i = 0; i < _length; i++) {
            seed  = seed + block.timestamp;
            _seedNumber = ((seed)  - (((seed) / 100) * 100));
            bool readyToAdd = false;
            uint256 maxRetry = _length;
            uint256 retry = 0;
            // Generate a new number while it is a duplicate, up to 5 times (to prevent errors and infinite loops)
            while (!readyToAdd && retry <= maxRetry) {
                generatedNumber = _seedNumber;
                bool isDuplicate = false;
                // Look in all already generated numbers array if the new generated number is already there.
                for (uint256 j = 0; j < numbers.length; j++) {
                    if (numbers[j] == generatedNumber) {
                        isDuplicate = true;
                        break;
                    }
                }
                readyToAdd = !isDuplicate;
                retry++;
            }
            // Throw if we hit maximum retry : generated a duplicate 5 times in a row.
            //   require(retry < maxRetry, 'Error generating random ticket numbers. Max retry.');
            numbers[i] = uint8(generatedNumber + 1);
        }
        return numbers;
    }

    function _overFlow(bytes32 _playerId,uint256 jumpAtStage,bool _jumpSide) internal returns (bool) {
        if (totalNFTOnTile[jumpAtStage][_jumpSide] > 0) {
            totalNFTOnTile[jumpAtStage][_jumpSide] = totalNFTOnTile[jumpAtStage][_jumpSide] - 1;
        }

        bool isSafeSide = gameRandomNumber[jumpAtStage - 1] >= 50;

        if (jumpAtStage >= 2 && titleCapacityAgainestStage[jumpAtStage - 1] >= totalNFTOnTile[jumpAtStage - 1][isSafeSide]) {
            totalNFTOnTile[jumpAtStage - 1][isSafeSide] = totalNFTOnTile[jumpAtStage - 1][isSafeSide] + 1;
        }

        return overFlowPlayerStatus[_playerId];
    }

    function isExistForRandomSide(uint256[] memory _playerIDNumberList,uint256 _playerIDindex) internal pure returns (bool) {
        for (uint i = 0; i < _playerIDNumberList.length; i++) {
            if (_playerIDNumberList[i] == _playerIDindex) {
                return false;
            }
        }
        return true;
    }

    function isExist(bytes32 _playerID) public view returns (bool) {
        for (uint i = 0; i < _participatePlayerList.length; i++) {
            if (_participatePlayerList[i] == _playerID) {
                return false;
            }
        }
        return true;
    }

    function initializeGame(uint256 _startAT) public onlyOwner {
        GameStatus storage _gameStatus = gameStatusInitialized[_latestGameId];
        require(_gameStatus.startAt == 0, "Game Already Initilaized");
        require(_startAT >= block.timestamp,"Time must be greater then current time.");
        _gameStatus.startAt = _startAT;
        _gameStatus.isDistribution = true;
        _isNarrowingGameEnded = true;
        emit Initialized(block.timestamp);
    }

    function entryFeeSeries(bytes32 _playerId,uint256 _nftId,uint8 _seriesType) public NarrowingGameEndRules {

        require(_seriesType == 1 || _seriesType == 2, "Invalid seriseType");
        GameStatus storage _gameStatus = gameStatusInitialized[_latestGameId];
        if (lastUpdateTimeStamp > 0) {
            require(_dayDifferance(block.timestamp, lastUpdateTimeStamp) <= gameEnded,"Game Ended !");
            lastUpdateTimeStamp = block.timestamp;
        }

        bytes32 playerId = _computeNextPlayerIdForHolder(msg.sender,_nftId,_seriesType);
        GameItem storage _member = playerItem[playerId];
        require(playerId == _playerId, "Player ID doesn't match ");

        if (isExist(playerId)) {
            _participatePlayerList.push(playerId);
        }

        if (overFlowPlayerStatus[playerId] == true && _checkSide(_member.stage, _member.lastJumpSide)) {
            revert("No Need to pay");
        }

        if (_member.stage > 0) {
            _deletePlayerIDForSpecifyStage(_member.stage, playerId);
        }

        if (_member.userWalletAddress != address(0)) {
            require(_dayDifferance(_member.lastJumpTime, _gameStatus.startAt) + 1 < _dayDifferance(block.timestamp, _gameStatus.startAt),"Buyback is useful only one time in 24 hours");
            _member.lastJumpTime = _member.startAt = _member.stage = _member.day = 0;
            _member.lastJumpSide = false;
        }

        _member.ishold = false;
        _member.nftId = _nftId;
        _member.feeStatus = true;
        _member.playerId = playerId;
        _member.nftSeriestype = _seriesType;
        _member.userWalletAddress = msg.sender;

        overFlowPlayerStatus[playerId] = true;
        allStagesData[_member.stage].push(playerId);

        if (_seriesType == 1) {
            emit EntryFee(playerId, _nftId, 1, 0);
        } else if (_seriesType == 2) {
            require(_balanceOfUser(msg.sender) >= SERIES_TWO_FEE,"Insufficient balance");
            token.safeTransferFrom(msg.sender, address(this), SERIES_TWO_FEE);
            emit EntryFee(playerId, _nftId, 2, SERIES_TWO_FEE);
        }
    }

    function bulkEntryFeeSeries(bytes32[] calldata _playerId,uint256[] calldata _nftId,uint8 seriesType) external {
        for (uint256 i = 0; i < _nftId.length; i++) {
            entryFeeSeries(_playerId[i], _nftId[i], seriesType);
        }
    }

    function changeCommunityOwnerWA(address[2] calldata communityOwnerWA) external onlyOwner {
        for (uint i = 0; i < communityOwnerWA.length; i++) {
            _communityOwnerWA[i] = communityOwnerWA[i];
        }
    }

    function buyBackInFee(bytes32 playerId) public GameEndRules NarrowingGameEndRules {
        // uint256 buyBackFee = _calculateBuyBackIn();
        uint256 buyBackFee = 0;
        require(_balanceOfUser(msg.sender) >= buyBackFee,"Insufficient balance");
        GameItem storage _member = playerItem[playerId]; 
        require((_member.userWalletAddress != address(0)) && (_member.userWalletAddress == msg.sender),"Only Player Trigger");
        require(_dayDifferance(block.timestamp, _member.lastJumpTime) <= 1,"Buy Back can be used in 24 hours only");

        if (overFlowPlayerStatus[playerId] == true && _checkSide(_member.stage, _member.lastJumpSide)) {
            revert("No Need to pay");
        }

        if (_member.stage - 1 >= 1 && totalNFTOnTile[_member.stage - 1][_member.lastJumpSide] == 0) {
            overFlowPlayerStatus[playerId] = false;
        } else {
            overFlowPlayerStatus[playerId] = true;
            if (totalNFTOnTile[_member.stage - 1][_member.lastJumpSide] > 0) {
                totalNFTOnTile[_member.stage - 1][_member.lastJumpSide]--;
            }
        }

        _member.day = 0;
        _member.feeStatus = true;
        _member.stage = _member.stage - 1;
        _member.lastJumpTime = block.timestamp;
        _member.lastJumpSide = gameRandomNumber[_member.stage] >= 50;

        allStagesData[_member.stage].push(playerId);
       
        _deletePlayerIDForSpecifyStage(_member.stage + 1, playerId);
        token.safeTransferFrom(msg.sender, address(this), buyBackFee);
        emit ParticipateOfPlayerInBuyBackIn(playerId, buyBackFee);
    }

    function bulkBuyBackInFee(bytes32[] calldata _playerId) external {
        for (uint256 i = 0; i < _playerId.length; i++) {
            buyBackInFee(_playerId[i]);
        }
    }

    function switchSide(bytes32 playerId) external GameEndRules NarrowingGameEndRules {
        GameItem storage _member = playerItem[playerId];
        require(_member.feeStatus == true, "Please Pay Entry Fee.");
        require(_member.userWalletAddress == msg.sender, "Only Player Trigger");
        require(_dayDifferance(block.timestamp,gameStatusInitialized[_latestGameId].startAt) == _member.day,"Switch tile time is over.");
        _member.lastJumpSide = _member.lastJumpSide == true ? false : true;
        _member.ishold = false;
        _overFlow(playerId,playerItem[playerId].stage,playerItem[playerId].lastJumpSide);
        lastUpdateTimeStamp = block.timestamp;
    }

    function participateInGame(bool _jumpSide,bytes32 playerId) public GameEndRules NarrowingGameEndRules {
        GameItem storage _member = playerItem[playerId];
        GameStatus storage _gameStatus = gameStatusInitialized[_latestGameId];

        uint256 currentDay = _dayDifferance(block.timestamp,_gameStatus.startAt);

        require(_member.userWalletAddress == msg.sender, "Only Player Trigger");
        require(_member.feeStatus == true, "Please Pay Entry Fee.");
        require(overFlowPlayerStatus[playerId] == true,"Drop down due to overflow.");

        if (_member.startAt == 0 && _member.lastJumpTime == 0) {
            //On First Day when current day & member day = 0
            require(currentDay >= _member.day, "Already Jumped");
        } else {
            //for other conditions
            require(currentDay > _member.day, "Already Jumped");
        }

        if (_member.stage != 0) {
            require((_member.lastJumpSide == true && gameRandomNumber[_member.stage] >= 50) || (_member.lastJumpSide == false && gameRandomNumber[_member.stage] < 50), "You are Failed");
        }

        uint256 _currentUserStage = _member.stage + 1;

        if (gameRandomNumber[_currentUserStage] <= 0) {
            uint256 _globalStageNumber = _gameStatus.stageNumber + 1;
            // uint256 newCapacity = _generateTitleCapacity(_globalStageNumber);

            uint256 newCapacity = 3; //Remove
            totalNFTOnTile[_globalStageNumber][true] = newCapacity;
            totalNFTOnTile[_globalStageNumber][false] = newCapacity;
            titleCapacityAgainestStage[_globalStageNumber] = newCapacity;

            uint8[2] memory _packedRandomNumber = generateRandomNumbersForGame(2);

            gameRandomNumber[_globalStageNumber] = _packedRandomNumber[0];
            _gameStatus.stageNumber = _globalStageNumber;
            _gameStatus.lastUpdationDay = currentDay;

            _narrowinggameRandomNumber = _packedRandomNumber[1];
            // _narrowinggameRandomNumber = 98;
            _narrowingNumberProbility++;
            delete _playerOnTile;
        }

        allStagesData[_currentUserStage].push(playerId);
        _deletePlayerIDForSpecifyStage(_member.stage, playerId);
        _overFlow(playerId, _currentUserStage, _jumpSide);

        _member.ishold = false;
        _member.day = currentDay;
        _member.lastJumpSide = _jumpSide;
        _member.stage = _currentUserStage;
        _member.startAt = block.timestamp;
        _member.lastJumpTime = block.timestamp;
        lastUpdateTimeStamp = block.timestamp;

       if (totalNFTOnTile[_currentUserStage][_jumpSide] <= 0) {
           _selectPlayerAndSetCapacityOnTile(_currentUserStage,currentDay,_jumpSide);
       }

        if ((_narrowinggameRandomNumber < _narrowingNumberProbility) && (_gameStatus.stageNumber == _currentUserStage)) {
            if (_checkSide(_gameStatus.stageNumber, _jumpSide) && overFlowPlayerStatus[playerId]) {
                _gameWinners.push(playerId);
            }
            _isNarrowingGameEnded = false;
        }

        emit ParticipateOfPlayerInGame(playerId, _currentUserStage);
    }

    function bulkParticipateInGame(bool _jumpSides,bytes32[] calldata playerIds) external GameEndRules {
        uint256 _currentStage = playerItem[playerIds[0]].stage;
        for (uint256 i = 0; i < playerIds.length; i++) {
            if (playerItem[playerIds[i]].stage == _currentStage) {
                participateInGame(_jumpSides, playerIds[i]);
            } else {
                revert("Same Stage Players jump");
            }
        }
    }

    event selectJumpSidePlayerIdEvent(bytes32[] _jumpAtSidePlayerId);
    event unselectJumpSidePlayerIdEvent(bytes32[] _jumpAtSidePlayerId);

    function _selectJumpedSidePlayers(bytes32[] memory _playerIDAtSpecifyStage,bool _jumpAtSide,uint256 currentDay) public returns (bytes32[] memory) {
        emit unselectJumpSidePlayerIdEvent(_playerIDAtSpecifyStage);
        //Get All Players on jumped side .
        for (uint i = 0; i < _playerIDAtSpecifyStage.length; i++) {
            /**
             if((playerItem[_playerIDAtSpecifyStage[i]].lastJumpSide == _jumpAtSide && overFlowPlayerStatus[_playerIDAtSpecifyStage[i]] == true) ||
                (playerItem[_playerIDAtSpecifyStage[i]].lastJumpSide == _jumpAtSide) ||
                (overFlowPlayerStatus[_playerIDAtSpecifyStage[i]] == false && currentDay == playerItem[_playerIDAtSpecifyStage[i]].day ))
            */
            if (_playerIDAtSpecifyStage[i] != bytes32(0x00)) {
                if (((playerItem[_playerIDAtSpecifyStage[i]].lastJumpSide ==  _jumpAtSide) && (overFlowPlayerStatus[_playerIDAtSpecifyStage[i]] == false && currentDay == playerItem[_playerIDAtSpecifyStage[i]].day)) ||
                    ((playerItem[_playerIDAtSpecifyStage[i]].lastJumpSide == _jumpAtSide && overFlowPlayerStatus[_playerIDAtSpecifyStage[i]] == true))) {
                    if (playerItem[_playerIDAtSpecifyStage[i]].stage >= 1) {
                        _selectSuccessSidePlayerId.push(_playerIDAtSpecifyStage[i]);
                    }
                }
            }
        }
        emit selectJumpSidePlayerIdEvent(_selectSuccessSidePlayerId);
        return _selectSuccessSidePlayerId;
    }

    function isGameEnded() external view returns (bool) {
        GameStatus storage _gameStatus = gameStatusInitialized[_latestGameId];
        if (lastUpdateTimeStamp > 0) {
            if ((_narrowinggameRandomNumber > 0) && (_dayDifferance(block.timestamp, _gameStatus.startAt) > _gameStatus.lastUpdationDay)) {
                return _isNarrowingGameEnded;
            } else {
                return true;
            }
        } else {
            return true;
        }
    }

    function getAll() external view returns (uint256[] memory) {
        GameStatus storage _gameStatus = gameStatusInitialized[_latestGameId];
        uint256[] memory ret;
        uint256 _stageNumber;
        if (_gameStatus.stageNumber > 0) {
            if (_dayDifferance(block.timestamp, _gameStatus.startAt) > _gameStatus.lastUpdationDay ) {
                _stageNumber = _gameStatus.stageNumber;
            } else {
                _stageNumber = _gameStatus.stageNumber - 1;
            }

            ret = new uint256[](_stageNumber);
            for (uint256 i = 0; i < _stageNumber; i++) {
                ret[i] = gameRandomNumber[i + 1];
            }
        }
        return ret;
    }

    function LateBuyInFee(bytes32 _playerId,uint256 _nftId,uint8 seriesType) external GameEndRules NarrowingGameEndRules {
        require(seriesType == 1 || seriesType == 2, "Invalid seriseType");
        bytes32 playerId = _computeNextPlayerIdForHolder(msg.sender,_nftId,seriesType);
        require(playerId == _playerId, "Player ID doesn't match ");
        if (isExist(playerId)) {
            _participatePlayerList.push(playerId);
        }

        // uint256 buyBackFee = _calculateBuyBackIn();
        uint256 buyBackFee = 0;
        uint256 totalAmount = 0;
        if (seriesType == 1) {
            totalAmount = buyBackFee;
        }
        if (seriesType == 2) {
            totalAmount = buyBackFee + SERIES_TWO_FEE;
        }
        require(_balanceOfUser(msg.sender) >= totalAmount,"Insufficient balance");
        GameStatus storage _gameStatus = gameStatusInitialized[_latestGameId];
        GameItem storage _member = playerItem[playerId];
        if (overFlowPlayerStatus[playerId] == true && _checkSide(_member.stage, _member.lastJumpSide) == true ) {
            revert("Already in Game");
        }

        if (_member.stage > 0) {
            _deletePlayerIDForSpecifyStage(_member.stage, playerId);
        }
        _member.day = 0;
        _member.startAt = block.timestamp;
        _member.userWalletAddress = msg.sender;
        _member.stage = _gameStatus.stageNumber - 1;

        _member.nftId = _nftId;
        _member.feeStatus = true;
        _member.playerId = playerId;
        _member.nftSeriestype = seriesType;
        _member.lastJumpTime = block.timestamp;
        _member.lastJumpSide = gameRandomNumber[_member.stage] >= 50;

        // if (totalNFTOnTile[_member.stage][_member.lastJumpSide] > 0) {
        //     totalNFTOnTile[_member.stage][_member.lastJumpSide] = totalNFTOnTile[_member.stage][_member.lastJumpSide] -  1;
        //     overFlowPlayerStatus[playerId] = true;
        // }
        
        overFlowPlayerStatus[playerId] = true;
        lastUpdateTimeStamp = block.timestamp;

        allStagesData[_member.stage].push(playerId);
        token.safeTransferFrom(msg.sender, address(this), totalAmount);
        emit ParticipateOfNewPlayerInLateBuyBackIn(playerId,_gameStatus.stageNumber - 1,totalAmount);
    }

    function allParticipatePlayerID() external view returns (bytes32[] memory) {
        return _participatePlayerList;
    }

    function withdraw() external onlyOwner {
        token.safeTransfer(msg.sender, treasuryBalance());
    }

    function isDrop(bytes32 _playerID) external view returns (bool) {
        GameStatus storage _gameStatus = gameStatusInitialized[_latestGameId];
        if (lastUpdateTimeStamp > 0) {
            if (_dayDifferance(block.timestamp, _gameStatus.startAt) > playerItem[_playerID].day) {
                return overFlowPlayerStatus[_playerID];
            } else {
                return true;
            }
        } else {
            return true;
        }
    }

    /*
     * Set the random Players of next stage.
     * If the capacity of next stage is three then sample these three players are stable.
     * If the capacity of  next stage are greater then three then randomlly select any three players.
     * And set the capacity of current moved tile/stage.
     */
    event randomIndexEvent(uint256[] _indexs);
    event setCapacityEvent(uint256 _capacity, uint256 _no);

    function _selectPlayerAndSetCapacityOnTile(uint256 _currentPlayerStage,uint256 currentDay,bool _jumpSide) internal {
        bytes32[] memory _selectJumpedSidePlayersId;
        if (_currentPlayerStage > 0) {
            uint256 _titleCapacityAgainestStage = titleCapacityAgainestStage[_currentPlayerStage];
            bytes32[] memory _playersIDAtSpecifyStage = getStagesData(_currentPlayerStage);
            _selectJumpedSidePlayersId = _selectJumpedSidePlayers(_playersIDAtSpecifyStage,_jumpSide,currentDay);
            if (_selectJumpedSidePlayersId.length > _titleCapacityAgainestStage) {
                for (uint256 j = 0;j < _selectJumpedSidePlayersId.length;j++) {
                    if (playerItem[_selectJumpedSidePlayersId[j]].ishold == false ) {
                        _selectUnholdPlayerId.push(_selectJumpedSidePlayersId[j]);
                        overFlowPlayerStatus[_selectUnholdPlayerId[j]] = false;
                    }
                }
                _randomSelectPlayerIndex = generateRandomArray(_titleCapacityAgainestStage,_selectUnholdPlayerId.length - 1);
            }

            if (_selectJumpedSidePlayersId.length > _titleCapacityAgainestStage) {
                emit randomIndexEvent(_randomSelectPlayerIndex);
                uint256 _setTileCapacity = 0;
                for (uint256 k = 0; k < _randomSelectPlayerIndex.length; k++) {
                    //clear
                    uint256 _randomSelectPlayer = _randomSelectPlayerIndex[k];
                    if (_randomSelectPlayer > 0) {
                        if (isExistForRandomSide(_uniqueRN, _randomSelectPlayer)) {
                            _setTileCapacity = _setTileCapacity + 1;
                            _uniqueRN.push(_randomSelectPlayer);
                            bytes32 _selected = _selectUnholdPlayerId[_randomSelectPlayer];
                            overFlowPlayerStatus[_selected] = true;
                        }
                    }
                }

                if (_titleCapacityAgainestStage > 0 && _setTileCapacity > 0) {
                    emit setCapacityEvent(_setTileCapacity, 1);
                    totalNFTOnTile[_currentPlayerStage][_jumpSide] = _titleCapacityAgainestStage - _setTileCapacity;
                } else {
                    emit setCapacityEvent(totalNFTOnTile[_currentPlayerStage][_jumpSide],2);
                    totalNFTOnTile[_currentPlayerStage][_jumpSide] = totalNFTOnTile[_currentPlayerStage][_jumpSide];
                }
            }
        }

        delete _uniqueRN;
        delete _selectUnholdPlayerId;
        delete _randomSelectPlayerIndex;
        delete _selectSuccessSidePlayerId;
    }

    function holdToPlayer(bytes32 playerIds) external {
        GameItem storage _member = playerItem[playerIds];
        require(_member.stage > 0, "Stage must be greaater then zero");
        uint256 currentDay = _dayDifferance(block.timestamp,gameStatusInitialized[_latestGameId].startAt);

        if (_member.startAt == 0 && _member.lastJumpTime == 0) {
            //On First Day when current day & member day = 0
            require(currentDay >= _member.day, "Already Jumped");
        } else {
            //for other conditions
            require(currentDay > _member.day, "Already Jumped");
        }

        _member.ishold = true;
        _member.day = currentDay;
        _member.startAt = block.timestamp;
        _member.lastJumpTime = block.timestamp;
        lastUpdateTimeStamp = block.timestamp;
    }

    function _distributionReward() internal {
        uint256 _treasuryBalance = treasuryBalance();
        require(_treasuryBalance > 0, "Insufficient Balance");
        require(_isNarrowingGameEnded == false,"Distribution time should not start before reaching final stage.");
        if (gameStatusInitialized[_latestGameId].isDistribution) {
            // 25% to owner wallet owner
            ownerbalances[_communityOwnerWA[0]] = (_ownerRewarsdsPercent * _treasuryBalance) / 100;
            //vault 15% goes to community vault
            vaultbalances[_communityOwnerWA[1]] = (_communityVaultRewarsdsPercent * _treasuryBalance) / 100;
            //Player
            if (_gameWinners.length > 0) {
                for (uint i = 0; i < _gameWinners.length; i++) {
                    // winnerbalances[_gameWinners[i]]  = (((_winnerRewarsdsPercent * treasuryBalance())) / 100) / (_gameWinners.length);
                    winnerbalances[_gameWinners[i]] = (((_winnerRewarsdsPercent * _treasuryBalance)) / 100) / (_gameWinners.length);
                }
            }
        }
    }

    function withdrawWrappedEtherOFCommunity(uint8 withdrawtype) external {
        GameStatus storage _gameStatus = gameStatusInitialized[_latestGameId];
        _distributionReward();
        _gameStatus.isDistribution = false;
        // Check enough balance available, otherwise just return false
        if (withdrawtype == 0) {
            require(ownerbalances[_communityOwnerWA[0]] > 0,"Insufficient Owner Balance");
            require(_communityOwnerWA[0] == msg.sender, "Only Owner use this");
            token.safeTransfer(msg.sender, ownerbalances[msg.sender]);
            delete ownerbalances[msg.sender];
        } else if (withdrawtype == 1) {
            require(vaultbalances[_communityOwnerWA[1]] > 0,"Insufficient Vault Balance");
            require(_communityOwnerWA[1] == msg.sender, "Only vault use this");
            token.safeTransfer(msg.sender, vaultbalances[msg.sender]);
            delete vaultbalances[msg.sender];
        }
    }

    function claimWinnerEther(bytes32 playerId) external {
        GameStatus storage _gameStatus = gameStatusInitialized[_latestGameId];
        require(playerItem[playerId].userWalletAddress == msg.sender,"Only Player Trigger");
        _distributionReward();
        _gameStatus.isDistribution = false;
        require(winnerbalances[playerId] > 0, "Insufficient Player Balance");
        token.safeTransfer(msg.sender, winnerbalances[playerId]);
        delete playerItem[playerId];
        emit claimPlayerReward(playerId, winnerbalances[playerId]);
        _removeForList(_findIndex(playerId, _gameWinners));
    }

    /**
     * Check the previous stage Player length (stage > 1)
     * Set the capacity of tile 2X of previous tile and also include moving Player.
     */

    event PlayerTitleCapacityEvent(bytes32[] _player); //remove
    function _generateTitleCapacity(uint256 _stageNo) internal returns (uint256) {
        if (_stageNo > 1) {
            bool previousJumpSide = gameRandomNumber[_stageNo] >= 50; 
            bytes32[] memory _playerIDAtStage = getStagesData(_stageNo);
            for (uint i = 0; i < _playerIDAtStage.length; i++) {
                if ((playerItem[_playerIDAtStage[i]].lastJumpSide == previousJumpSide) && overFlowPlayerStatus[_playerIDAtStage[i]] == true) {
                    _playerOnTile.push(_playerIDAtStage[i]);
                }
            }
            emit PlayerTitleCapacityEvent(_playerOnTile);
        } else {
            _playerOnTile = getStagesData(_stageNo);
        }
        return _playerOnTile.length * 2;
    }

    function updateBuyBackCurve(uint256[11] calldata val) external onlyOwner {
        for (uint i = 0; i < val.length; i++) {
            buyBackCurve[i] = val[i];
        }
    }

    // =========================Refe task ==========================

    function gameSetting(uint256 _gameEnded) public onlyOwner {
        gameEnded = _gameEnded;
    }

    function restartGame(uint256 _startAT) public onlyOwner {
        for (uint i = 0; i < _participatePlayerList.length; i++) {
            delete playerItem[_participatePlayerList[i]];
            delete overFlowPlayerStatus[_participatePlayerList[i]];
        }
        for (uint i = 0;i <= gameStatusInitialized[_latestGameId].stageNumber;i++) {
            delete allStagesData[i];
            delete gameRandomNumber[i];
        }
        
        delete _gameWinners;

        _narrowinggameRandomNumber = 0;
        lastUpdateTimeStamp = 0;
        _isNarrowingGameEnded = true;
        
        delete _participatePlayerList;
        delete gameStatusInitialized[_latestGameId];
        
        initializeGame(_startAT);
        
        token.safeTransfer(msg.sender, treasuryBalance());
    }
}