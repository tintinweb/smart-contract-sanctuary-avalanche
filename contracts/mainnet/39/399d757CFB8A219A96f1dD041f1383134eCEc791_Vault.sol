// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "./IEverscale.sol";
pragma experimental ABIEncoderV2;


interface IBridge is IEverscale {
    struct Round {
        uint32 end;
        uint32 ttl;
        uint32 relays;
        uint32 requiredSignatures;
    }

    function updateMinimumRequiredSignatures(uint32 _minimumRequiredSignatures) external;
    function setConfiguration(EverscaleAddress calldata _roundRelaysConfiguration) external;
    function updateRoundTTL(uint32 _roundTTL) external;

    function isRelay(
        uint32 round,
        address candidate
    ) external view returns (bool);

    function isBanned(
        address candidate
    ) external view returns (bool);

    function isRoundRotten(
        uint32 round
    ) external view returns (bool);

    function verifySignedEverscaleEvent(
        bytes memory payload,
        bytes[] memory signatures
    ) external view returns (uint32);

    function setRoundRelays(
        bytes calldata payload,
        bytes[] calldata signatures
    ) external;

    function forceRoundRelays(
        uint160[] calldata _relays,
        uint32 roundEnd
    ) external;

    function banRelays(
        address[] calldata _relays
    ) external;

    function unbanRelays(
        address[] calldata _relays
    ) external;

    function pause() external;
    function unpause() external;

    function setRoundSubmitter(address _roundSubmitter) external;

    event EmergencyShutdown(bool active);

    event UpdateMinimumRequiredSignatures(uint32 value);
    event UpdateRoundTTL(uint32 value);
    event UpdateRoundRelaysConfiguration(EverscaleAddress configuration);
    event UpdateRoundSubmitter(address _roundSubmitter);

    event NewRound(uint32 indexed round, Round meta);
    event RoundRelay(uint32 indexed round, address indexed relay);
    event BanRelay(address indexed relay, bool status);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


interface IEverscale {
    struct EverscaleAddress {
        int128 wid;
        uint256 addr;
    }

    struct EverscaleEvent {
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        bytes eventData;
        int8 configurationWid;
        uint256 configurationAddress;
        int8 eventContractWid;
        uint256 eventContractAddress;
        address proxy;
        uint32 round;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


interface IStrategy {
    function vault() external view returns (address);
    function want() external view returns (address);
    function isActive() external view returns (bool);
    function delegatedAssets() external view returns (uint256);
    function estimatedTotalAssets() external view returns (uint256);
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss);
    function migrate(address newStrategy) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "./IVaultBasic.sol";


interface IVault is IVaultBasic {
    enum ApproveStatus { NotRequired, Required, Approved, Rejected }

    struct StrategyParams {
        uint256 performanceFee;
        uint256 activation;
        uint256 debtRatio;
        uint256 minDebtPerHarvest;
        uint256 maxDebtPerHarvest;
        uint256 lastReport;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalSkim;
        uint256 totalLoss;
        address rewardsManager;
        EverscaleAddress rewards;
    }

    struct PendingWithdrawalParams {
        uint256 amount;
        uint256 bounty;
        uint256 timestamp;
        ApproveStatus approveStatus;
    }

    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    struct WithdrawalPeriodParams {
        uint256 total;
        uint256 considered;
    }

    function initialize(
        address _token,
        address _bridge,
        address _governance,
        uint _targetDecimals,
        EverscaleAddress memory _rewards
    ) external;

    function withdrawGuardian() external view returns (address);

    function pendingWithdrawalsPerUser(address user) external view returns (uint);
    function pendingWithdrawals(
        address user,
        uint id
    ) external view returns (PendingWithdrawalParams memory);
    function pendingWithdrawalsTotal() external view returns (uint);

    function managementFee() external view returns (uint256);
    function performanceFee() external view returns (uint256);

    function strategies(
        address strategyId
    ) external view returns (StrategyParams memory);
    function withdrawalQueue() external view returns (address[20] memory);

    function withdrawLimitPerPeriod() external view returns (uint256);
    function undeclaredWithdrawLimit() external view returns (uint256);
    function withdrawalPeriods(
        uint256 withdrawalPeriodId
    ) external view returns (WithdrawalPeriodParams memory);

    function depositLimit() external view returns (uint256);
    function debtRatio() external view returns (uint256);
    function totalDebt() external view returns (uint256);
    function lastReport() external view returns (uint256);
    function lockedProfit() external view returns (uint256);
    function lockedProfitDegradation() external view returns (uint256);

    function setWithdrawGuardian(address _withdrawGuardian) external;
    function setStrategyRewards(
        address strategyId,
        EverscaleAddress memory _rewards
    ) external;
    function setLockedProfitDegradation(uint256 degradation) external;
    function setDepositLimit(uint256 limit) external;
    function setPerformanceFee(uint256 fee) external;
    function setManagementFee(uint256 fee) external;
    function setWithdrawLimitPerPeriod(uint256 _withdrawLimitPerPeriod) external;
    function setUndeclaredWithdrawLimit(uint256 _undeclaredWithdrawLimit) external;
    function setWithdrawalQueue(address[20] memory queue) external;
    function setPendingWithdrawalBounty(uint256 id, uint256 bounty) external;

    function deposit(
        EverscaleAddress memory recipient,
        uint256 amount,
        uint256 expectedMinBounty,
        PendingWithdrawalId[] memory pendingWithdrawalId
    ) external;
    function depositToFactory(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes memory level3
    ) external;

    function saveWithdraw(
        bytes memory payload,
        bytes[] memory signatures
    ) external returns (
        bool instantWithdrawal,
        PendingWithdrawalId memory pendingWithdrawalId
    );

    function saveWithdraw(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    ) external;

    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        EverscaleAddress memory recipient,
        uint bounty
    ) external;

    function withdraw(
        uint256 id,
        uint256 amountRequested,
        address recipient,
        uint256 maxLoss,
        uint bounty
    ) external returns(uint256);

    function addStrategy(
        address strategyId,
        uint256 _debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 _performanceFee
    ) external;

    function updateStrategyDebtRatio(
        address strategyId,
        uint256 _debtRatio
    )  external;

    function updateStrategyMinDebtPerHarvest(
        address strategyId,
        uint256 minDebtPerHarvest
    ) external;

    function updateStrategyMaxDebtPerHarvest(
        address strategyId,
        uint256 maxDebtPerHarvest
    ) external;

    function updateStrategyPerformanceFee(
        address strategyId,
        uint256 _performanceFee
    ) external;

    function migrateStrategy(
        address oldVersion,
        address newVersion
    ) external;

    function revokeStrategy(
        address strategyId
    ) external;
    function revokeStrategy() external;


    function totalAssets() external view returns (uint256);
    function debtOutstanding(address strategyId) external view returns (uint256);
    function debtOutstanding() external view returns (uint256);

    function creditAvailable(address strategyId) external view returns (uint256);
    function creditAvailable() external view returns (uint256);

    function availableDepositLimit() external view returns (uint256);
    function expectedReturn(address strategyId) external view returns (uint256);

    function report(
        uint256 profit,
        uint256 loss,
        uint256 _debtPayment
    ) external returns (uint256);

    function skim(address strategyId) external;
    function skimFees(bool skim_to_everscale) external;
    function fees() external view returns (uint256);

    function forceWithdraw(
        PendingWithdrawalId memory pendingWithdrawalId
    ) external;

    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalId
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId[] memory pendingWithdrawalId,
        ApproveStatus[] memory approveStatus
    ) external;


    event PendingWithdrawalUpdateBounty(address recipient, uint256 id, uint256 bounty);
    event PendingWithdrawalCancel(address recipient, uint256 id, uint256 amount);
    event PendingWithdrawalForce(address recipient, uint256 id);
    event PendingWithdrawalCreated(
        address recipient,
        uint256 id,
        uint256 amount,
        bytes32 payloadId
    );
    event PendingWithdrawalWithdraw(
        address recipient,
        uint256 id,
        uint256 requestedAmount,
        uint256 redeemedAmount
    );
    event PendingWithdrawalUpdateApproveStatus(
        address recipient,
        uint256 id,
        ApproveStatus approveStatus
    );

    event UpdateWithdrawLimitPerPeriod(uint256 withdrawLimitPerPeriod);
    event UpdateUndeclaredWithdrawLimit(uint256 undeclaredWithdrawLimit);
    event UpdateDepositLimit(uint256 depositLimit);

    event UpdatePerformanceFee(uint256 performanceFee);
    event UpdateManagementFee(uint256 managenentFee);

    event UpdateWithdrawGuardian(address withdrawGuardian);
    event UpdateWithdrawalQueue(address[20] queue);

    event StrategyUpdateDebtRatio(address indexed strategy, uint256 debtRatio);
    event StrategyUpdateMinDebtPerHarvest(address indexed strategy, uint256 minDebtPerHarvest);
    event StrategyUpdateMaxDebtPerHarvest(address indexed strategy, uint256 maxDebtPerHarvest);
    event StrategyUpdatePerformanceFee(address indexed strategy, uint256 performanceFee);
    event StrategyMigrated(address indexed oldVersion, address indexed newVersion);
    event StrategyRevoked(address indexed strategy);
    event StrategyRemovedFromQueue(address indexed strategy);
    event StrategyAddedToQueue(address indexed strategy);
    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPaid,
        uint256 totalGain,
        uint256 totalSkim,
        uint256 totalLoss,
        uint256 totalDebt,
        uint256 debtAdded,
        uint256 debtRatio
    );

    event StrategyAdded(
        address indexed strategy,
        uint256 debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 performanceFee
    );
    event StrategyUpdateRewards(
        address strategyId,
        int128 wid,
        uint256 addr
    );
    event UserDeposit(
        address sender,
        int128 recipientWid,
        uint256 recipientAddr,
        uint256 amount,
        address withdrawalRecipient,
        uint256 withdrawalId,
        uint256 bounty
    );
    event FactoryDeposit(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes1 separator,
        bytes level3
    );

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "../IEverscale.sol";


interface IVaultBasic is IEverscale {
    struct WithdrawalParams {
        EverscaleAddress sender;
        uint256 amount;
        address recipient;
        uint32 chainId;
    }

    function bridge() external view returns (address);
    function configuration() external view returns (EverscaleAddress memory);
    function withdrawalIds(bytes32) external view returns (bool);
    function rewards() external view returns (EverscaleAddress memory);

    function governance() external view returns (address);
    function guardian() external view returns (address);
    function management() external view returns (address);

    function token() external view returns (address);
    function targetDecimals() external view returns (uint256);
    function tokenDecimals() external view returns (uint256);

    function depositFee() external view returns (uint256);
    function withdrawFee() external view returns (uint256);

    function emergencyShutdown() external view returns (bool);

    function apiVersion() external view returns (string memory api_version);

    function setDepositFee(uint _depositFee) external;
    function setWithdrawFee(uint _withdrawFee) external;

    function setConfiguration(EverscaleAddress memory _configuration) external;
    function setGovernance(address _governance) external;
    function acceptGovernance() external;
    function setGuardian(address _guardian) external;
    function setManagement(address _management) external;
    function setRewards(EverscaleAddress memory _rewards) external;
    function setEmergencyShutdown(bool active) external;

    function deposit(
        EverscaleAddress memory recipient,
        uint256 amount
    ) external;

    function decodeWithdrawalEventData(
        bytes memory eventData
    ) external view returns(WithdrawalParams memory);

    function sweep(address _token) external;

    // Events
    event Deposit(
        uint256 amount,
        int128 wid,
        uint256 addr
    );

    event InstantWithdrawal(
        bytes32 payloadId,
        address recipient,
        uint256 amount
    );

    event UpdateBridge(address bridge);
    event UpdateConfiguration(int128 wid, uint256 addr);
    event UpdateTargetDecimals(uint256 targetDecimals);
    event UpdateRewards(int128 wid, uint256 addr);

    event UpdateDepositFee(uint256 fee);
    event UpdateWithdrawFee(uint256 fee);

    event UpdateGovernance(address governance);
    event UpdateManagement(address management);
    event NewPendingGovernance(address governance);
    event UpdateGuardian(address guardian);

    event EmergencyShutdown(bool active);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;


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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/Math.sol";

import "../interfaces/vault/IVault.sol";
import "../interfaces/IBridge.sol";
import "../interfaces/IStrategy.sol";

import "./VaultHelpers.sol";


string constant API_VERSION = '0.1.8';

/// @title Vault contract. Entry point for the Octus bridge cross chain token transfers.
/// @dev Fork of the Yearn Vault V2 contract, rewritten in Solidity.
/// @author https://github.com/broxus
contract Vault is IVault, VaultHelpers {
    using SafeERC20 for IERC20;

    address constant MULTIVAULT = 0x54c55369A6900731D22eACb0DF7C0253CF19dFff;

    function initialize(
        address _token,
        address _bridge,
        address _governance,
        uint _targetDecimals,
        EverscaleAddress memory _rewards
    ) external override initializer {
        bridge = _bridge;
        emit UpdateBridge(bridge);

        governance = _governance;
        emit UpdateGovernance(governance);

        rewards_ = _rewards;
        emit UpdateRewards(rewards_.wid, rewards_.addr);

        performanceFee = 0;
        emit UpdatePerformanceFee(0);

        managementFee = 0;
        emit UpdateManagementFee(0);

        withdrawFee = 0;
        emit UpdateWithdrawFee(0);

        depositFee = 0;
        emit UpdateDepositFee(0);

        token = _token;
        tokenDecimals = IERC20Metadata(token).decimals();
        targetDecimals = _targetDecimals;
    }

    /**
        @notice Vault API version. Used to track the deployed version of this contract.
        @return api_version Current API version
    */
    function apiVersion()
        external
        override
        pure
        returns (string memory api_version)
    {
        return API_VERSION;
    }

    function kill() external onlyGovernance {
        uint balance = IERC20(token).balanceOf(address(this));

        IERC20(token).safeTransfer(
            MULTIVAULT,
            balance
        );

        setEmergencyShutdown(true);
    }

    /**
        @notice Set deposit fee. Must be less than `MAX_BPS`.
        This may be called only by `governance` or `management`.
        @param _depositFee Deposit fee, must be less than `MAX_BPS / 2`.
    */
    function setDepositFee(
        uint _depositFee
    ) external override onlyGovernanceOrManagement {
        require(_depositFee <= MAX_BPS / 2);

        depositFee = _depositFee;

        emit UpdateDepositFee(depositFee);
    }

    /**
        @notice Set withdraw fee. Must be less than `MAX_BPS`.
        This may be called only by `governance` or `management`
        @param _withdrawFee Withdraw fee, must be less than `MAX_BPS / 2`.
    */
    function setWithdrawFee(
        uint _withdrawFee
    ) external override onlyGovernanceOrManagement {
        require(_withdrawFee <= MAX_BPS / 2);

        withdrawFee = _withdrawFee;

        emit UpdateWithdrawFee(withdrawFee);
    }

    /// @notice Set configuration_ address.
    /// @param _configuration The address to use for configuration_.
    function setConfiguration(
        EverscaleAddress memory _configuration
    ) external override onlyGovernance {
        configuration_ = _configuration;

        emit UpdateConfiguration(configuration_.wid, configuration_.addr);
    }

    /// @notice Nominate new address to use as a governance.
    /// The change does not go into effect immediately. This function sets a
    /// pending change, and the governance address is not updated until
    /// the proposed governance address has accepted the responsibility.
    /// This may only be called by the `governance`.
    /// @param _governance The address requested to take over Vault governance.
    function setGovernance(
        address _governance
    ) external override onlyGovernance {
        pendingGovernance = _governance;

        emit NewPendingGovernance(pendingGovernance);
    }

    /// @notice Once a new governance address has been proposed using `setGovernance`,
    /// this function may be called by the proposed address to accept the
    /// responsibility of taking over governance for this contract.
    /// This may only be called by the `pendingGovernance`.
    function acceptGovernance()
        external
        override
        onlyPendingGovernance
    {
        governance = pendingGovernance;

        emit UpdateGovernance(governance);
    }

    /// @notice Changes the management address.
    /// This may only be called by `governance`
    /// @param _management The address to use for management.
    function setManagement(
        address _management
    )
        external
        override
        onlyGovernance
    {
        management = _management;

        emit UpdateManagement(management);
    }

    /// @notice Changes the address of `guardian`.
    /// This may only be called by `governance` or `guardian`.
    /// @param _guardian The new guardian address to use.
    function setGuardian(
        address _guardian
    ) external override onlyGovernanceOrGuardian {
        guardian = _guardian;

        emit UpdateGuardian(guardian);
    }

    /// @notice Changes the address of `withdrawGuardian`.
    /// This may only be called by `governance` or `withdrawGuardian`.
    /// @param _withdrawGuardian The new withdraw guardian address to use.
    function setWithdrawGuardian(
        address _withdrawGuardian
    ) external override onlyGovernanceOrWithdrawGuardian {
        withdrawGuardian = _withdrawGuardian;

        emit UpdateWithdrawGuardian(withdrawGuardian);
    }

    /// @notice Set strategy rewards_ recipient address.
    /// This may only be called by the `governance` or strategy rewards_ manager.
    /// @param strategyId Strategy address.
    /// @param _rewards Rewards recipient.
    function setStrategyRewards(
        address strategyId,
        EverscaleAddress memory _rewards
    )
        external
        override
        onlyGovernanceOrStrategyRewardsManager(strategyId)
        strategyExists(strategyId)
    {
        _strategyRewardsUpdate(strategyId, _rewards);

        emit StrategyUpdateRewards(strategyId, _rewards.wid, _rewards.addr);
    }

    /// @notice Set address to receive rewards_ (fees, gains, etc)
    /// This may be called only by `governance`
    /// @param _rewards Rewards receiver in Everscale network
    function setRewards(
        EverscaleAddress memory _rewards
    ) external override onlyGovernance {
        rewards_ = _rewards;

        emit UpdateRewards(rewards_.wid, rewards_.addr);
    }

    /// @notice Changes the locked profit degradation
    /// @param degradation The rate of degradation in percent per second scaled to 1e18
    function setLockedProfitDegradation(
        uint256 degradation
    ) external override onlyGovernance {
        require(degradation <= DEGRADATION_COEFFICIENT);

        lockedProfitDegradation = degradation;
    }

    /// @notice Changes the maximum amount of `token` that can be deposited in this Vault
    /// Note, this is not how much may be deposited by a single depositor,
    /// but the maximum amount that may be deposited across all depositors.
    /// This may be called only by `governance`
    /// @param limit The new deposit limit to use.
    function setDepositLimit(
        uint256 limit
    ) external override onlyGovernance {
        depositLimit = limit;

        emit UpdateDepositLimit(depositLimit);
    }

    /// @notice Changes the value of `performanceFee`.
    /// Should set this value below the maximum strategist performance fee.
    /// This may only be called by `governance`.
    /// @param fee The new performance fee to use.
    function setPerformanceFee(
        uint256 fee
    ) external override onlyGovernance {
        require(fee <= MAX_BPS / 2);

        performanceFee = fee;

        emit UpdatePerformanceFee(performanceFee);
    }

    /// @notice Changes the value of `managementFee`.
    /// This may only be called by `governance`.
    /// @param fee The new management fee to use.
    function setManagementFee(
        uint256 fee
    ) external override onlyGovernance {
        require(fee <= MAX_BPS);

        managementFee = fee;

        emit UpdateManagementFee(managementFee);
    }

    /// @notice Changes the value of `withdrawLimitPerPeriod`
    /// This may only be called by `governance`
    /// @param _withdrawLimitPerPeriod The new withdraw limit per period to use.
    function setWithdrawLimitPerPeriod(
        uint256 _withdrawLimitPerPeriod
    ) external override onlyGovernance {
        withdrawLimitPerPeriod = _withdrawLimitPerPeriod;

        emit UpdateWithdrawLimitPerPeriod(withdrawLimitPerPeriod);
    }

    /// @notice Changes the value of `undeclaredWithdrawLimit`
    /// This may only be called by `governance`
    /// @param _undeclaredWithdrawLimit The new undeclared withdraw limit to use.
    function setUndeclaredWithdrawLimit(
        uint256 _undeclaredWithdrawLimit
    ) external override onlyGovernance {
        undeclaredWithdrawLimit = _undeclaredWithdrawLimit;

        emit UpdateUndeclaredWithdrawLimit(undeclaredWithdrawLimit);
    }

    /// @notice Activates or deactivates Vault emergency mode, where all Strategies go into full withdrawal.
    ///     During emergency shutdown:
    ///     - Deposits are disabled
    ///     - Withdrawals are disabled (all types of withdrawals)
    ///     - Each Strategy must pay back their debt as quickly as reasonable to minimally affect their position
    ///     - Only `governance` may undo Emergency Shutdown
    /// This may only be called by `governance` or `guardian`.
    /// @param active If `true`, the Vault goes into Emergency Shutdown. If `false`, the Vault goes back into
    ///     Normal Operation.
    function setEmergencyShutdown(
        bool active
    ) public override {
        if (active) {
            require(msg.sender == guardian || msg.sender == governance);
        } else {
            require(msg.sender == governance);
        }

        emergencyShutdown = active;

        emit EmergencyShutdown(active);
    }

    /// @notice Changes `withdrawalQueue`
    /// This may only be called by `governance`
    function setWithdrawalQueue(
        address[20] memory queue
    ) external override onlyGovernanceOrManagement {
        withdrawalQueue_ = queue;

        emit UpdateWithdrawalQueue(withdrawalQueue_);
    }

    /**
        @notice Changes pending withdrawal bounty for specific pending withdrawal
        @param id Pending withdrawal ID.
        @param bounty The new value for pending withdrawal bounty.
    */
    function setPendingWithdrawalBounty(
        uint256 id,
        uint256 bounty
    )
        public
        override
        pendingWithdrawalOpened(PendingWithdrawalId(msg.sender, id))
    {
        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(PendingWithdrawalId(msg.sender, id));

        require(bounty <= pendingWithdrawal.amount);

        _pendingWithdrawalBountyUpdate(PendingWithdrawalId(msg.sender, id), bounty);
    }

    /// @notice Returns the total quantity of all assets under control of this
    /// Vault, whether they're loaned out to a Strategy, or currently held in
    /// the Vault.
    /// @return The total assets under control of this Vault.
    function totalAssets() external view override returns (uint256) {
        return _totalAssets();
    }

    /// @notice Deposits `token` into the Vault, leads to producing corresponding token
    /// on the Everscale side.
    /// @param recipient Recipient in the Everscale network
    /// @param amount Amount of `token` to deposit
    function deposit(
        EverscaleAddress memory recipient,
        uint256 amount
    )
        public
        override
        onlyEmergencyDisabled
        respectDepositLimit(amount)
        nonReentrant
    {
        IERC20(token).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 fee = _calculateMovementFee(amount, depositFee);

        _transferToEverscale(recipient, amount - fee);

        if (fee > 0) fees += fee;

        emit UserDeposit(msg.sender, recipient.wid, recipient.addr, amount, address(0), 0, 0);
    }

    /**
        @notice Same as regular `deposit`, but fill multiple pending withdrawals.
        @param recipient Deposit recipient in the Everscale network.
        @param amount Deposit amount
        @param expectedMinBounty Expected min bounty amount, frontrun protection
        @param pendingWithdrawalIds List of pending withdrawals to close.
    */
    function deposit(
        EverscaleAddress memory recipient,
        uint256 amount,
        uint256 expectedMinBounty,
        PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external override {
        uint amountLeft = amount;
        uint amountPlusBounty = amount;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        for (uint i = 0; i < pendingWithdrawalIds.length; i++) {
            PendingWithdrawalId memory pendingWithdrawalId = pendingWithdrawalIds[i];
            PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

            require(pendingWithdrawal.amount > 0);
            require(
                pendingWithdrawal.approveStatus == ApproveStatus.NotRequired ||
                pendingWithdrawal.approveStatus == ApproveStatus.Approved
            );

            amountLeft -= pendingWithdrawal.amount;
            amountPlusBounty += pendingWithdrawal.bounty;

            _pendingWithdrawalAmountReduce(
                pendingWithdrawalId,
                pendingWithdrawal.amount
            );

            IERC20(token).safeTransfer(
                pendingWithdrawalId.recipient,
                pendingWithdrawal.amount - pendingWithdrawal.bounty
            );

            emit UserDeposit(
                msg.sender,
                recipient.wid,
                recipient.addr,
                pendingWithdrawal.amount,
                pendingWithdrawalId.recipient,
                pendingWithdrawalId.id,
                pendingWithdrawal.bounty
            );
        }

        require(amountPlusBounty - amount >= expectedMinBounty);

        uint256 fee = _calculateMovementFee(amountPlusBounty, depositFee);

        _transferToEverscale(recipient, amountPlusBounty - fee);

        if (amountLeft > 0) {
            emit UserDeposit(msg.sender, recipient.wid, recipient.addr, amountLeft, address(0), 0, 0);
        }

        if (fee > 0) fees += fee;
    }

    function depositToFactory(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes memory level3
    )
        external
        override
        onlyEmergencyDisabled
        respectDepositLimit(amount)
    {
        require(
            tokenAmount <= amount &&
            swapType < 2 &&
            user != 0 &&
            recipient != 0 &&
            creditor != 0 &&
            slippageNumerator < slippageDenominator
        );

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 fee = _calculateMovementFee(amount, depositFee);

        if (fee > 0) fees += fee;

        emit FactoryDeposit(
            uint128(convertToTargetDecimals(amount - fee)),
            wid,
            user,
            creditor,
            recipient,
            tokenAmount,
            tonAmount,
            swapType,
            slippageNumerator,
            slippageDenominator,
            0x07,
            level3
        );
    }

    /**
        @notice Save withdrawal receipt. If Vault has enough tokens and withdrawal passes the
            limits, then it's executed immediately. Otherwise it's saved as a pending withdrawal.
        @param payload Withdrawal receipt. Bytes encoded `struct EverscaleEvent`.
        @param signatures List of relay's signatures. See not on `Bridge.verifySignedEverscaleEvent`.
        @return instantWithdrawal Boolean, was withdrawal instantly filled or saved as a pending withdrawal.
        @return pendingWithdrawalId Pending withdrawal ID. `(address(0), 0)` if no pending withdrawal was created.
    */
    function saveWithdraw(
        bytes memory payload,
        bytes[] memory signatures
    )
        public
        override
        onlyEmergencyDisabled
        withdrawalNotSeenBefore(payload)
        returns (bool instantWithdrawal, PendingWithdrawalId memory pendingWithdrawalId)
    {
        require(
            IBridge(bridge).verifySignedEverscaleEvent(payload, signatures) == 0,
            "Vault: signatures verification failed"
        );

        // Decode Everscale event
        (EverscaleEvent memory _event) = abi.decode(payload, (EverscaleEvent));

        require(
            _event.configurationWid == configuration_.wid &&
            _event.configurationAddress == configuration_.addr
        );

        bytes32 payloadId = keccak256(payload);

        // Decode event data
        WithdrawalParams memory withdrawal = decodeWithdrawalEventData(_event.eventData);

        require(withdrawal.chainId == _getChainID());

        // Ensure withdrawal fee
        uint256 fee = _calculateMovementFee(withdrawal.amount, withdrawFee);

        if (fee > 0) fees += fee;

        // Consider withdrawal period limit
        WithdrawalPeriodParams memory withdrawalPeriod = _withdrawalPeriod(_event.eventTimestamp);
        _withdrawalPeriodIncreaseTotalByTimestamp(_event.eventTimestamp, withdrawal.amount);

        bool withdrawalLimitsPassed = _withdrawalPeriodCheckLimitsPassed(withdrawal.amount, withdrawalPeriod);

        // Withdrawal is less than limits and Vault's token balance is enough for instant withdrawal
        if (withdrawal.amount <= _vaultTokenBalance() && withdrawalLimitsPassed) {
            IERC20(token).safeTransfer(withdrawal.recipient, withdrawal.amount - fee);

            emit InstantWithdrawal(payloadId, withdrawal.recipient, withdrawal.amount - fee);

            return (true, PendingWithdrawalId(address(0), 0));
        }

        // Save withdrawal as a pending
        uint256 id = _pendingWithdrawalCreate(
            withdrawal.recipient,
            withdrawal.amount - fee,
            _event.eventTimestamp
        );

        emit PendingWithdrawalCreated(withdrawal.recipient, id, withdrawal.amount - fee, payloadId);

        pendingWithdrawalId = PendingWithdrawalId(withdrawal.recipient, id);

        if (!withdrawalLimitsPassed) {
            _pendingWithdrawalApproveStatusUpdate(pendingWithdrawalId, ApproveStatus.Required);
        }

        return (false, pendingWithdrawalId);
    }

    /**
        @notice Save withdrawal receipt, same as `saveWithdraw(bytes payload, bytes[] signatures)`,
            but allows to immediately set up bounty.
        @param payload Withdrawal receipt. Bytes encoded `struct EverscaleEvent`.
        @param signatures List of relay's signatures. See not on `Bridge.verifySignedEverscaleEvent`.
        @param bounty New value for pending withdrawal bounty.
    */
    function saveWithdraw(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    )
        external
        override
    {
        (
            bool instantWithdraw,
            PendingWithdrawalId memory pendingWithdrawalId
        ) = saveWithdraw(payload, signatures);

        if (!instantWithdraw && msg.sender == pendingWithdrawalId.recipient) {
            PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);
            require(bounty <= pendingWithdrawal.amount);

            _pendingWithdrawalBountyUpdate(pendingWithdrawalId, bounty);
        }
    }

    /**
        @notice Cancel pending withdrawal partially or completely.
        This may only be called by pending withdrawal recipient.
        @param id Pending withdrawal ID
        @param amount Amount to cancel, should be less or equal than pending withdrawal amount
        @param recipient Tokens recipient, in Everscale network
        @param bounty New value for bounty
    */
    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        EverscaleAddress memory recipient,
        uint bounty
    )
        external
        override
        onlyEmergencyDisabled
        pendingWithdrawalApproved(PendingWithdrawalId(msg.sender, id))
        pendingWithdrawalOpened(PendingWithdrawalId(msg.sender, id))
    {
        PendingWithdrawalId memory pendingWithdrawalId = PendingWithdrawalId(msg.sender, id);
        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        require(amount > 0 && amount <= pendingWithdrawal.amount);

        _transferToEverscale(recipient, amount);

        _pendingWithdrawalAmountReduce(pendingWithdrawalId, amount);

        emit PendingWithdrawalCancel(msg.sender, id, amount);

        setPendingWithdrawalBounty(id, bounty);
    }

    /**
        @notice Withdraws the calling account's pending withdrawal from this Vault.
        @param id Pending withdrawal ID.
        @param amountRequested Amount of tokens to be withdrawn.
        @param recipient The address to send the redeemed tokens.
        @param maxLoss The maximum acceptable loss to sustain on withdrawal.
            If a loss is specified, up to that amount of tokens may be burnt to cover losses on withdrawal.
        @param bounty New value for bounty.
        @return amountAdjusted The quantity of tokens redeemed.
    */
    function withdraw(
        uint256 id,
        uint256 amountRequested,
        address recipient,
        uint256 maxLoss,
        uint256 bounty
    )
        external
        override
        onlyEmergencyDisabled
        pendingWithdrawalOpened(PendingWithdrawalId(msg.sender, id))
        pendingWithdrawalApproved(PendingWithdrawalId(msg.sender, id))
        returns(uint256 amountAdjusted)
    {
        PendingWithdrawalId memory pendingWithdrawalId = PendingWithdrawalId(msg.sender, id);
        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        require(
            amountRequested > 0 &&
            amountRequested <= pendingWithdrawal.amount &&
            bounty <= pendingWithdrawal.amount - amountRequested
        );

        _pendingWithdrawalBountyUpdate(pendingWithdrawalId, bounty);

        amountAdjusted = amountRequested;

        if (amountAdjusted > _vaultTokenBalance()) {
            uint256 totalLoss = 0;

            for (uint i = 0; i < withdrawalQueue_.length; i++) {
                address strategyId = withdrawalQueue_[i];

                // We're done withdrawing
                if (strategyId == address(0)) break;

                uint256 vaultBalance = _vaultTokenBalance();
                uint256 amountNeeded = amountAdjusted - vaultBalance;

                // Don't withdraw more than the debt so that Strategy can still
                // continue to work based on the profits it has
                // This means that user will lose out on any profits that each
                // Strategy in the queue would return on next harvest, benefiting others
                amountNeeded = Math.min(
                    amountNeeded,
                    _strategy(strategyId).totalDebt
                );

                // Nothing to withdraw from this Strategy, try the next one
                if (amountNeeded == 0) continue;

                // Force withdraw value from each Strategy in the order set by governance
                uint256 loss = IStrategy(strategyId).withdraw(amountNeeded);
                uint256 withdrawn = _vaultTokenBalance() - vaultBalance;

                // Withdrawer incurs any losses from liquidation
                if (loss > 0) {
                    amountAdjusted -= loss;
                    totalLoss += loss;
                    _strategyReportLoss(strategyId, loss);
                }

                // Reduce the Strategy's debt by the value withdrawn ("realized returns")
                // This doesn't add to returns as it's not earned by "normal means"
                _strategyTotalDebtReduce(strategyId, withdrawn);
            }

            require(_vaultTokenBalance() >= amountAdjusted);

            // This loss protection is put in place to revert if losses from
            // withdrawing are more than what is considered acceptable.
            require(totalLoss <= maxLoss * (amountAdjusted + totalLoss) / MAX_BPS);
        }

        IERC20(token).safeTransfer(recipient, amountAdjusted);

        _pendingWithdrawalAmountReduce(pendingWithdrawalId, amountRequested);

        emit PendingWithdrawalWithdraw(
            pendingWithdrawalId.recipient,
            pendingWithdrawalId.id,
            amountRequested,
            amountAdjusted
        );

        return amountAdjusted;
    }

    /**
        @notice Add a Strategy to the Vault
        This may only be called by `governance`
        @param strategyId The address of the Strategy to add.
        @param _debtRatio The share of the total assets in the `vault that the `strategy` has access to.
        @param minDebtPerHarvest Lower limit on the increase of debt since last harvest.
        @param maxDebtPerHarvest Upper limit on the increase of debt since last harvest.
        @param _performanceFee The fee the strategist will receive based on this Vault's performance.
    */
    function addStrategy(
        address strategyId,
        uint256 _debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 _performanceFee
    )
        external
        override
        onlyGovernance
        onlyEmergencyDisabled
        strategyNotExists(strategyId)
    {
        require(strategyId != address(0));

        require(IStrategy(strategyId).vault() == address(this));
        require(IStrategy(strategyId).want() == token);

        require(debtRatio + _debtRatio <= MAX_BPS);
        require(minDebtPerHarvest <= maxDebtPerHarvest);
        require(_performanceFee <= MAX_BPS / 2);

        _strategyCreate(strategyId, StrategyParams({
            performanceFee: _performanceFee,
            activation: block.timestamp,
            debtRatio: _debtRatio,
            minDebtPerHarvest: minDebtPerHarvest,
            maxDebtPerHarvest: maxDebtPerHarvest,
            lastReport: block.timestamp,
            totalDebt: 0,
            totalGain: 0,
            totalSkim: 0,
            totalLoss: 0,
            rewardsManager: address(0),
            rewards: rewards_
        }));

        emit StrategyAdded(strategyId, _debtRatio, minDebtPerHarvest, maxDebtPerHarvest, _performanceFee);

        _debtRatioIncrease(_debtRatio);
    }

    /**
        @notice Change the quantity of assets `strategy` may manage.
        This may be called by `governance` or `management`.
        @param strategyId The Strategy to update.
        @param _debtRatio The quantity of assets `strategy` may now manage.
    */
    function updateStrategyDebtRatio(
        address strategyId,
        uint256 _debtRatio
    )
        external
        override
        onlyGovernanceOrManagement
        strategyExists(strategyId)
    {
        StrategyParams memory strategy = _strategy(strategyId);

        _debtRatioReduce(strategy.debtRatio);
        _strategyDebtRatioUpdate(strategyId, _debtRatio);
        _debtRatioIncrease(debtRatio);

        require(debtRatio <= MAX_BPS);

        emit StrategyUpdateDebtRatio(strategyId, _debtRatio);
    }

    function updateStrategyMinDebtPerHarvest(
        address strategyId,
        uint256 minDebtPerHarvest
    )
        external
        override
        onlyGovernanceOrManagement
        strategyExists(strategyId)
    {
        StrategyParams memory strategy = _strategy(strategyId);

        require(strategy.maxDebtPerHarvest >= minDebtPerHarvest);

        _strategyMinDebtPerHarvestUpdate(strategyId, minDebtPerHarvest);

        emit StrategyUpdateMinDebtPerHarvest(strategyId, minDebtPerHarvest);
    }

    function updateStrategyMaxDebtPerHarvest(
        address strategyId,
        uint256 maxDebtPerHarvest
    )
        external
        override
        onlyGovernanceOrManagement
        strategyExists(strategyId)
    {
        StrategyParams memory strategy = _strategy(strategyId);

        require(strategy.minDebtPerHarvest <= maxDebtPerHarvest);

        _strategyMaxDebtPerHarvestUpdate(strategyId, maxDebtPerHarvest);

        emit StrategyUpdateMaxDebtPerHarvest(strategyId, maxDebtPerHarvest);
    }

    function updateStrategyPerformanceFee(
        address strategyId,
        uint256 _performanceFee
    )
        external
        override
        onlyGovernance
        strategyExists(strategyId)
    {
        require(_performanceFee <= MAX_BPS / 2);

        performanceFee = _performanceFee;

        emit StrategyUpdatePerformanceFee(strategyId, _performanceFee);
    }

    function migrateStrategy(
        address oldVersion,
        address newVersion
    )
        external
        override
        onlyGovernance
        strategyExists(oldVersion)
        strategyNotExists(newVersion)
    {

    }

    function revokeStrategy(
        address strategyId
    )
        external
        override
        onlyStrategyOrGovernanceOrGuardian(strategyId)
    {
        _strategyRevoke(strategyId);

        emit StrategyRevoked(strategyId);
    }

    function revokeStrategy()
        external
        override
        onlyStrategyOrGovernanceOrGuardian(msg.sender)
    {
        _strategyRevoke(msg.sender);

        emit StrategyRevoked(msg.sender);
    }

    function debtOutstanding(
        address strategyId
    )
        external
        view
        override
        returns (uint256)
    {
        return _strategyDebtOutstanding(strategyId);
    }

    function debtOutstanding()
        external
        view
        override
        returns (uint256)
    {
        return _strategyDebtOutstanding(msg.sender);
    }

    function creditAvailable(
        address strategyId
    )
        external
        view
        override
        returns (uint256)
    {
        return _strategyCreditAvailable(strategyId);
    }

    function creditAvailable()
        external
        view
        override
        returns (uint256)
    {
        return _strategyCreditAvailable(msg.sender);
    }


    function availableDepositLimit()
        external
        view
        override
        returns (uint256)
    {
        if (depositLimit > _totalAssets()) {
            return depositLimit - _totalAssets();
        }

        return 0;
    }

    function expectedReturn(
        address strategyId
    )
        external
        override
        view
        returns (uint256)
    {
        return _strategyExpectedReturn(strategyId);
    }

    function _assessFees(
        address strategyId,
        uint256 gain
    ) internal returns (uint256) {
        StrategyParams memory strategy = _strategy(strategyId);

        // Just added, no fees to assess
        if (strategy.activation == block.timestamp) return 0;

        uint256 duration = block.timestamp - strategy.lastReport;
        require(duration > 0); // Can't call twice within the same block

        if (gain == 0) return 0; // The fees are not charged if there hasn't been any gains reported

        uint256 management_fee = (
            strategy.totalDebt - IStrategy(strategyId).delegatedAssets()
        ) * duration * managementFee / MAX_BPS / SECS_PER_YEAR;

        uint256 strategist_fee = (gain * strategy.performanceFee) / MAX_BPS;

        uint256 performance_fee = (gain * performanceFee) / MAX_BPS;

        uint256 total_fee = management_fee + strategist_fee + performance_fee;

        // Fee
        if (total_fee > gain) {
            strategist_fee = strategist_fee * gain / total_fee;
            performance_fee = performance_fee * gain / total_fee;
            management_fee = management_fee * gain / total_fee;

            total_fee = gain;
        }

        if (strategist_fee > 0) { // Strategy rewards are paid instantly
            _transferToEverscale(strategy.rewards, strategist_fee);
        }

        if (performance_fee + management_fee > 0) {
            fees += performance_fee + management_fee;
        }

        return total_fee;
    }

    /**
        @notice Reports the amount of assets the calling Strategy has free (usually in
            terms of ROI).

            The performance fee is determined here, off of the strategy's profits
            (if any), and sent to governance.

            The strategist's fee is also determined here (off of profits), to be
            handled according to the strategist on the next harvest.

            This may only be called by a Strategy managed by this Vault.
        @dev For approved strategies, this is the most efficient behavior.
            The Strategy reports back what it has free, then Vault "decides"
            whether to take some back or give it more. Note that the most it can
            take is `gain + _debtPayment`, and the most it can give is all of the
            remaining reserves. Anything outside of those bounds is abnormal behavior.

            All approved strategies must have increased diligence around
            calling this function, as abnormal behavior could become catastrophic.
        @param gain Amount Strategy has realized as a gain on it's investment since its
            last report, and is free to be given back to Vault as earnings
        @param loss Amount Strategy has realized as a loss on it's investment since its
            last report, and should be accounted for on the Vault's balance sheet.
            The loss will reduce the debtRatio. The next time the strategy will harvest,
            it will pay back the debt in an attempt to adjust to the new debt limit.
        @param _debtPayment Amount Strategy has made available to cover outstanding debt
        @return Amount of debt outstanding (if totalDebt > debtLimit or emergency shutdown).
    */
    function report(
        uint256 gain,
        uint256 loss,
        uint256 _debtPayment
    )
        external
        override
        strategyExists(msg.sender)
        returns (uint256)
    {
        if (loss > 0) _strategyReportLoss(msg.sender, loss);

        uint256 totalFees = _assessFees(msg.sender, gain);

        _strategyTotalGainIncrease(msg.sender, gain);

        // Compute the line of credit the Vault is able to offer the Strategy (if any)
        uint256 credit = _strategyCreditAvailable(msg.sender);

        // Outstanding debt the Strategy wants to take back from the Vault (if any)
        // debtOutstanding <= strategy.totalDebt
        uint256 debt = _strategyDebtOutstanding(msg.sender);
        uint256 debtPayment = Math.min(_debtPayment, debt);

        if (debtPayment > 0) {
            _strategyTotalDebtReduce(msg.sender, debtPayment);

            debt -= debtPayment;
        }

        // Update the actual debt based on the full credit we are extending to the Strategy
        // or the returns if we are taking funds back
        // NOTE: credit + self.strategies_[msg.sender].totalDebt is always < self.debtLimit
        // NOTE: At least one of `credit` or `debt` is always 0 (both can be 0)
        if (credit > 0) {
            _strategyTotalDebtIncrease(msg.sender, credit);
        }

        // Give/take balance to Strategy, based on the difference between the reported gains
        // (if any), the debt payment (if any), the credit increase we are offering (if any),
        // and the debt needed to be paid off (if any)
        // NOTE: This is just used to adjust the balance of tokens between the Strategy and
        //       the Vault based on the Strategy's debt limit (as well as the Vault's).
        uint256 totalAvailable = gain + debtPayment;

        if (totalAvailable < credit) { // credit surplus, give to Strategy
            IERC20(token).safeTransfer(msg.sender, credit - totalAvailable);
        } else if (totalAvailable > credit) { // credit deficit, take from Strategy
            IERC20(token).safeTransferFrom(msg.sender, address(this), totalAvailable - credit);
        } else {
            // don't do anything because it is balanced
        }

        // Profit is locked and gradually released per block
        // NOTE: compute current locked profit and replace with sum of current and new
        uint256 lockedProfitBeforeLoss = _calculateLockedProfit() + gain - totalFees;

        if (lockedProfitBeforeLoss > loss) {
            lockedProfit = lockedProfitBeforeLoss - loss;
        } else {
            lockedProfit = 0;
        }

        _strategyLastReportUpdate(msg.sender);

        StrategyParams memory strategy = _strategy(msg.sender);

        emit StrategyReported(
            msg.sender,
            gain,
            loss,
            debtPayment,
            strategy.totalGain,
            strategy.totalSkim,
            strategy.totalLoss,
            strategy.totalDebt,
            credit,
            strategy.debtRatio
        );

        if (strategy.debtRatio == 0 || emergencyShutdown) {
            // Take every last penny the Strategy has (Emergency Exit/revokeStrategy)
            // NOTE: This is different than `debt` in order to extract *all* of the returns
            return IStrategy(msg.sender).estimatedTotalAssets();
        } else {
            return debt;
        }
    }

    /**
        @notice Skim strategy gain to the `rewards_` address.
        This may only be called by `governance` or `management`
        @param strategyId Strategy address to skim.
    */
    function skim(
        address strategyId
    )
        external
        override
        onlyGovernanceOrManagement
        strategyExists(strategyId)
    {
        uint amount = strategies_[strategyId].totalGain - strategies_[strategyId].totalSkim;

        require(amount > 0);

        strategies_[strategyId].totalSkim += amount;

        _transferToEverscale(rewards_, amount);
    }

    /// @notice Skim Vault fees to the `rewards_` address
    /// This may only be called by `governance` or `management`
    /// @param skim_to_everscale Skim fees to Everscale or not
    function skimFees(
        bool skim_to_everscale
    ) external override onlyGovernanceOrManagement {
        require(fees > 0);

        if (skim_to_everscale) {
            _transferToEverscale(rewards_, fees);
        } else {
            IERC20(token).safeTransfer(governance, fees);
        }

        fees = 0;
    }

    /**
        @notice Removes tokens from this Vault that are not the type of token managed
            by this Vault. This may be used in case of accidentally sending the
            wrong kind of token to this Vault.

            Tokens will be sent to `governance`.

            This will fail if an attempt is made to sweep the tokens that this
            Vault manages.

            This may only be called by `governance`.
        @param _token The token to transfer out of this vault.
    */
    function sweep(
        address _token
    ) external override onlyGovernance {
        require(token != _token);

        uint256 amount = IERC20(_token).balanceOf(address(this));

        IERC20(_token).safeTransfer(governance, amount);
    }

    /**
        @notice Force user's pending withdraw. Works only if Vault has enough
            tokens on its balance.

            This may only be called by wrapper.
        @param pendingWithdrawalId Pending withdrawal ID
    */
    function forceWithdraw(
        PendingWithdrawalId memory pendingWithdrawalId
    )
        public
        override
        onlyEmergencyDisabled
        pendingWithdrawalOpened(pendingWithdrawalId)
        pendingWithdrawalApproved(pendingWithdrawalId)
    {
        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        IERC20(token).safeTransfer(pendingWithdrawalId.recipient, pendingWithdrawal.amount);

        _pendingWithdrawalAmountReduce(pendingWithdrawalId, pendingWithdrawal.amount);

        emit PendingWithdrawalForce(pendingWithdrawalId.recipient, pendingWithdrawalId.id);
    }

    /**
        @notice Multicall for `forceWithdraw`
        @param pendingWithdrawalId List of pending withdrawal IDs
    */
    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalId
    ) external override {
        for (uint i = 0; i < pendingWithdrawalId.length; i++) {
            forceWithdraw(pendingWithdrawalId[i]);
        }
    }

    /**
        @notice Set approve status for pending withdrawal.
            Pending withdrawal must be in `Required` (1) approve status, so approve status can be set only once.
            If Vault has enough tokens on its balance - withdrawal will be filled immediately.
            This may only be called by `governance` or `withdrawGuardian`.
        @param pendingWithdrawalId Pending withdrawal ID.
        @param approveStatus Approve status. Must be `Approved` (2) or `Rejected` (3).
    */
    function setPendingWithdrawalApprove(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    )
        public
        override
        onlyGovernanceOrWithdrawGuardian
        pendingWithdrawalOpened(pendingWithdrawalId)
    {
        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        require(pendingWithdrawal.approveStatus == ApproveStatus.Required);

        require(
            approveStatus == ApproveStatus.Approved ||
            approveStatus == ApproveStatus.Rejected
        );

        _pendingWithdrawalApproveStatusUpdate(pendingWithdrawalId, approveStatus);

        // Fill approved withdrawal
        if (approveStatus == ApproveStatus.Approved && pendingWithdrawal.amount <= _vaultTokenBalance()) {
            _pendingWithdrawalAmountReduce(pendingWithdrawalId, pendingWithdrawal.amount);

            IERC20(token).safeTransfer(
                pendingWithdrawalId.recipient,
                pendingWithdrawal.amount
            );

            emit PendingWithdrawalWithdraw(
                pendingWithdrawalId.recipient,
                pendingWithdrawalId.id,
                pendingWithdrawal.amount,
                pendingWithdrawal.amount
            );
        }

        // Update withdrawal period considered amount
        _withdrawalPeriodIncreaseConsideredByTimestamp(
            pendingWithdrawal.timestamp,
            pendingWithdrawal.amount
        );
    }

    /**
        @notice Multicall for `setPendingWithdrawalApprove`.
        @param pendingWithdrawalId List of pending withdrawals IDs.
        @param approveStatus List of approve statuses.
    */
    function setPendingWithdrawalApprove(
        PendingWithdrawalId[] memory pendingWithdrawalId,
        ApproveStatus[] memory approveStatus
    ) external override {
        require(pendingWithdrawalId.length == approveStatus.length);

        for (uint i = 0; i < pendingWithdrawalId.length; i++) {
            setPendingWithdrawalApprove(pendingWithdrawalId[i], approveStatus[i]);
        }
    }

    function _transferToEverscale(
        EverscaleAddress memory recipient,
        uint256 _amount
    ) internal {
        uint256 amount = convertToTargetDecimals(_amount);

        emit Deposit(amount, recipient.wid, recipient.addr);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


import "../libraries/Math.sol";
import "../interfaces/IStrategy.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./VaultStorage.sol";


abstract contract VaultHelpers is VaultStorage {
    modifier onlyGovernance() {
        require(msg.sender == governance);

        _;
    }

    modifier onlyPendingGovernance() {
        require(msg.sender == pendingGovernance);

        _;
    }

    modifier onlyStrategyOrGovernanceOrGuardian(address strategyId) {
        require(msg.sender == strategyId || msg.sender == governance || msg.sender == guardian);

        _;
    }

    modifier onlyGovernanceOrManagement() {
        require(msg.sender == governance || msg.sender == management);

        _;
    }

    modifier onlyGovernanceOrGuardian() {
        require(msg.sender == governance || msg.sender == guardian);

        _;
    }

    modifier onlyGovernanceOrWithdrawGuardian() {
        require(msg.sender == governance || msg.sender == withdrawGuardian);

        _;
    }

    modifier onlyGovernanceOrStrategyRewardsManager(address strategyId) {
        require(msg.sender == governance || msg.sender == strategies_[strategyId].rewardsManager);

        _;
    }

    modifier pendingWithdrawalOpened(
        PendingWithdrawalId memory pendingWithdrawalId
    ) {
        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        require(pendingWithdrawal.amount > 0, "Vault: pending withdrawal closed");

        _;
    }

    modifier pendingWithdrawalApproved(
        PendingWithdrawalId memory pendingWithdrawalId
    ) {
        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        require(
            pendingWithdrawal.approveStatus == ApproveStatus.NotRequired ||
            pendingWithdrawal.approveStatus == ApproveStatus.Approved,
            "Vault: pending withdrawal not approved"
        );

        _;
    }

    modifier strategyExists(address strategyId) {
        StrategyParams memory strategy = _strategy(strategyId);

        require(strategy.activation > 0, "Vault: strategy not exists");

        _;
    }

    modifier strategyNotExists(address strategyId) {
        StrategyParams memory strategy = _strategy(strategyId);

        require(strategy.activation == 0, "Vault: strategy exists");

        _;
    }

    modifier respectDepositLimit(uint amount) {
        require(
            _totalAssets() + amount <= depositLimit,
            "Vault: respect the deposit limit"
        );

        _;
    }

    modifier onlyEmergencyDisabled() {
        require(!emergencyShutdown, "Vault: emergency mode enabled");

        _;
    }

    modifier withdrawalNotSeenBefore(bytes memory payload) {
        bytes32 withdrawalId = keccak256(payload);

        require(!withdrawalIds[withdrawalId], "Vault: withdraw payload already seen");

        _;

        withdrawalIds[withdrawalId] = true;
    }

    function decodeWithdrawalEventData(
        bytes memory eventData
    ) public view override returns(WithdrawalParams memory) {
        (
            int8 sender_wid,
            uint256 sender_addr,
            uint128 amount,
            uint160 recipient,
            uint32 chainId
        ) = abi.decode(
            eventData,
            (int8, uint256, uint128, uint160, uint32)
        );

        return WithdrawalParams({
            sender: EverscaleAddress(sender_wid, sender_addr),
            amount: convertFromTargetDecimals(amount),
            recipient: address(recipient),
            chainId: chainId
        });
    }

    //8b           d8   db        88        88  88      888888888888
    //`8b         d8'  d88b       88        88  88           88
    // `8b       d8'  d8'`8b      88        88  88           88
    //  `8b     d8'  d8'  `8b     88        88  88           88
    //   `8b   d8'  d8YaaaaY8b    88        88  88           88
    //    `8b d8'  d8""""""""8b   88        88  88           88
    //     `888'  d8'        `8b  Y8a.    .a8P  88           88
    //      `8'  d8'          `8b  `"Y8888Y"'   88888888888  88
    function _vaultTokenBalance() internal view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function _debtRatioReduce(
        uint256 amount
    ) internal {
        debtRatio -= amount;
    }

    function _debtRatioIncrease(
        uint256 amount
    ) internal {
        debtRatio += amount;
    }

    function _totalAssets() internal view returns (uint256) {
        return _vaultTokenBalance() + totalDebt;
    }

    function _calculateLockedProfit() internal view returns (uint256) {
        uint256 lockedFundsRatio = (block.timestamp - lastReport) * lockedProfitDegradation;

        if (lockedFundsRatio < DEGRADATION_COEFFICIENT) {
            uint256 _lockedProfit = lockedProfit;

            return _lockedProfit - (lockedFundsRatio * _lockedProfit / DEGRADATION_COEFFICIENT);
        } else {
            return 0;
        }
    }

    function convertFromTargetDecimals(
        uint256 amount
    ) public view returns (uint256) {
        if (targetDecimals == tokenDecimals) {
            return amount;
        } else if (targetDecimals > tokenDecimals) {
            return amount / 10 ** (targetDecimals - tokenDecimals);
        } else {
            return amount * 10 ** (tokenDecimals - targetDecimals);
        }
    }

    function convertToTargetDecimals(
        uint256 amount
    ) public view returns (uint256) {
        if (targetDecimals == tokenDecimals) {
            return amount;
        } else if (targetDecimals > tokenDecimals) {
            return amount * 10 ** (targetDecimals - tokenDecimals);
        } else {
            return amount / 10 ** (tokenDecimals - targetDecimals);
        }
    }

    function _calculateMovementFee(
        uint256 amount,
        uint256 fee
    ) internal pure returns (uint256) {
        if (fee == 0) return 0;

        return amount * fee / MAX_BPS;
    }

    // ad88888ba  888888888888  88888888ba          db    888888888888  88888888888  ,ad8888ba,  8b        d8
    //d8"     "8b      88       88      "8b        d88b        88       88          d8"'    `"8b  Y8,    ,8P
    //Y8,              88       88      ,8P       d8'`8b       88       88         d8'             Y8,  ,8P
    //`Y8aaaaa,        88       88aaaaaa8P'      d8'  `8b      88       88aaaaa    88               "8aa8"
    //  `"""""8b,      88       88""""88'       d8YaaaaY8b     88       88"""""    88      88888     `88'
    //        `8b      88       88    `8b      d8""""""""8b    88       88         Y8,        88      88
    //Y8a     a8P      88       88     `8b    d8'        `8b   88       88          Y8a.    .a88      88
    // "Y88888P"       88       88      `8b  d8'          `8b  88       88888888888  `"Y88888P"       88
    function _strategy(
        address strategyId
    ) internal view returns (StrategyParams memory) {
        return strategies_[strategyId];
    }

    function _strategyCreate(
        address strategyId,
        StrategyParams memory strategyParams
    ) internal {
        strategies_[strategyId] = strategyParams;
    }

    function _strategyRewardsUpdate(
        address strategyId,
        EverscaleAddress memory _rewards
    ) internal {
        strategies_[strategyId].rewards = _rewards;
    }

    function _strategyDebtRatioUpdate(
        address strategyId,
        uint256 debtRatio
    ) internal {
        strategies_[strategyId].debtRatio = debtRatio;
    }

    function _strategyLastReportUpdate(
        address strategyId
    ) internal {
        strategies_[strategyId].lastReport = block.timestamp;
        lastReport = block.timestamp;
    }

    function _strategyTotalDebtReduce(
        address strategyId,
        uint256 debtPayment
    ) internal {
        strategies_[strategyId].totalDebt -= debtPayment;
        totalDebt -= debtPayment;
    }

    function _strategyTotalDebtIncrease(
        address strategyId,
        uint256 credit
    ) internal {
        strategies_[strategyId].totalDebt += credit;
        totalDebt += credit;
    }

    function _strategyDebtOutstanding(
        address strategyId
    ) internal view returns (uint256) {
        StrategyParams memory strategy = _strategy(strategyId);

        if (debtRatio == 0) return strategy.totalDebt;

        uint256 strategy_debtLimit = strategy.debtRatio * _totalAssets() / MAX_BPS;

        if (emergencyShutdown) {
            return strategy.totalDebt;
        } else if (strategy.totalDebt <= strategy_debtLimit) {
            return 0;
        } else {
            return strategy.totalDebt - strategy_debtLimit;
        }
    }

    function _strategyCreditAvailable(
        address strategyId
    ) internal view returns (uint256) {
        if (emergencyShutdown) return 0;

        uint256 vault_totalAssets = _totalAssets();

        // Cant extend Strategies debt until total amount of pending withdrawals is more than Vault's total assets
        if (pendingWithdrawalsTotal >= vault_totalAssets) return 0;

        uint256 vault_debtLimit = debtRatio * vault_totalAssets / MAX_BPS;
        uint256 vault_totalDebt = totalDebt;

        StrategyParams memory strategy = _strategy(strategyId);

        uint256 strategy_debtLimit = strategy.debtRatio * vault_totalAssets / MAX_BPS;

        // Exhausted credit line
        if (strategy_debtLimit <= strategy.totalDebt || vault_debtLimit <= vault_totalDebt) return 0;

        // Start with debt limit left for the Strategy
        uint256 available = strategy_debtLimit - strategy.totalDebt;

        // Adjust by the global debt limit left
        available = Math.min(available, vault_debtLimit - vault_totalDebt);

        // Can only borrow up to what the contract has in reserve
        // NOTE: Running near 100% is discouraged
        available = Math.min(available, IERC20(token).balanceOf(address(this)));

        // Adjust by min and max borrow limits (per harvest)
        // NOTE: min increase can be used to ensure that if a strategy has a minimum
        //       amount of capital needed to purchase a position, it's not given capital
        //       it can't make use of yet.
        // NOTE: max increase is used to make sure each harvest isn't bigger than what
        //       is authorized. This combined with adjusting min and max periods in
        //       `BaseStrategy` can be used to effect a "rate limit" on capital increase.
        if (available < strategy.minDebtPerHarvest) {
            return 0;
        } else {
            return Math.min(available, strategy.maxDebtPerHarvest);
        }
    }

    function _strategyTotalGainIncrease(
        address strategyId,
        uint256 amount
    ) internal {
        strategies_[strategyId].totalGain += amount;
    }

    function _strategyExpectedReturn(
        address strategyId
    ) internal view returns (uint256) {
        StrategyParams memory strategy = _strategy(strategyId);

        uint256 timeSinceLastHarvest = block.timestamp - strategy.lastReport;
        uint256 totalHarvestTime = strategy.lastReport - strategy.activation;

        if (timeSinceLastHarvest > 0 && totalHarvestTime > 0 && IStrategy(strategyId).isActive()) {
            return strategy.totalGain * timeSinceLastHarvest / totalHarvestTime;
        } else {
            return 0;
        }
    }

    function _strategyDebtRatioReduce(
        address strategyId,
        uint256 amount
    ) internal {
        strategies_[strategyId].debtRatio -= amount;
        debtRatio -= amount;
    }

    function _strategyRevoke(
        address strategyId
    ) internal {
        _strategyDebtRatioReduce(strategyId, strategies_[strategyId].debtRatio);
    }

    function _strategyMinDebtPerHarvestUpdate(
        address strategyId,
        uint256 minDebtPerHarvest
    ) internal {
        strategies_[strategyId].minDebtPerHarvest = minDebtPerHarvest;
    }

    function _strategyMaxDebtPerHarvestUpdate(
        address strategyId,
        uint256 maxDebtPerHarvest
    ) internal {
        strategies_[strategyId].maxDebtPerHarvest = maxDebtPerHarvest;
    }


    function _strategyReportLoss(
        address strategyId,
        uint256 loss
    ) internal {
        StrategyParams memory strategy = _strategy(strategyId);

        uint256 totalDebt = strategy.totalDebt;

        // Loss can only be up the amount of debt issued to strategy
        require(loss <= totalDebt);

        // Also, make sure we reduce our trust with the strategy by the amount of loss
        if (debtRatio != 0) { // if vault with single strategy that is set to EmergencyOne
            // NOTE: The context to this calculation is different than the calculation in `_reportLoss`,
            // this calculation intentionally approximates via `totalDebt` to avoid manipulable results
            // NOTE: This calculation isn't 100% precise, the adjustment is ~10%-20% more severe due to EVM math
            uint256 ratio_change = Math.min(
                loss * debtRatio / totalDebt,
                strategy.debtRatio
            );

            _strategyDebtRatioReduce(strategyId, ratio_change);
        }

        // Finally, adjust our strategy's parameters by the loss
        strategies_[strategyId].totalLoss += loss;

        _strategyTotalDebtReduce(strategyId, loss);
    }

    //88888888ba   88888888888  888b      88  88888888ba,    88  888b      88    ,ad8888ba,
    //88      "8b  88           8888b     88  88      `"8b   88  8888b     88   d8"'    `"8b
    //88      ,8P  88           88 `8b    88  88        `8b  88  88 `8b    88  d8'
    //88aaaaaa8P'  88aaaaa      88  `8b   88  88         88  88  88  `8b   88  88
    //88""""""'    88"""""      88   `8b  88  88         88  88  88   `8b  88  88      88888
    //88           88           88    `8b 88  88         8P  88  88    `8b 88  Y8,        88
    //88           88           88     `8888  88      .a8P   88  88     `8888   Y8a.    .a88
    //88           88888888888  88      `888  88888888Y"'    88  88      `888    `"Y88888P"
    function _pendingWithdrawal(
        PendingWithdrawalId memory pendingWithdrawalId
    ) internal view returns (PendingWithdrawalParams memory) {
        return pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id];
    }

    function _pendingWithdrawalCreate(
        address recipient,
        uint256 amount,
        uint256 timestamp
    ) internal returns (uint256 pendingWithdrawalId) {
        pendingWithdrawalId = pendingWithdrawalsPerUser[recipient];
        pendingWithdrawalsPerUser[recipient]++;

        pendingWithdrawals_[recipient][pendingWithdrawalId] = PendingWithdrawalParams({
            amount: amount,
            timestamp: timestamp,
            bounty: 0,
            approveStatus: ApproveStatus.NotRequired
        });

        pendingWithdrawalsTotal += amount;

        return pendingWithdrawalId;
    }

    function _pendingWithdrawalBountyUpdate(
        PendingWithdrawalId memory pendingWithdrawalId,
        uint bounty
    ) internal {
        pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].bounty = bounty;

        emit PendingWithdrawalUpdateBounty(pendingWithdrawalId.recipient, pendingWithdrawalId.id, bounty);
    }

    function _pendingWithdrawalAmountReduce(
        PendingWithdrawalId memory pendingWithdrawalId,
        uint amount
    ) internal {
        pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].amount -= amount;
        pendingWithdrawalsTotal -= amount;
    }

    function _pendingWithdrawalApproveStatusUpdate(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    ) internal {
        pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].approveStatus = approveStatus;

        emit PendingWithdrawalUpdateApproveStatus(
            pendingWithdrawalId.recipient,
            pendingWithdrawalId.id,
            approveStatus
        );
    }

    //88888888ba   88888888888  88888888ba   88    ,ad8888ba,    88888888ba,
    //88      "8b  88           88      "8b  88   d8"'    `"8b   88      `"8b
    //88      ,8P  88           88      ,8P  88  d8'        `8b  88        `8b
    //88aaaaaa8P'  88aaaaa      88aaaaaa8P'  88  88          88  88         88
    //88""""""'    88"""""      88""""88'    88  88          88  88         88
    //88           88           88    `8b    88  Y8,        ,8P  88         8P
    //88           88           88     `8b   88   Y8a.    .a8P   88      .a8P
    //88           88888888888  88      `8b  88    `"Y8888Y"'    88888888Y"'

    function _withdrawalPeriodDeriveId(
        uint256 timestamp
    ) internal pure returns (uint256) {
        return timestamp / WITHDRAW_PERIOD_DURATION_IN_SECONDS;
    }

    function _withdrawalPeriod(
        uint256 timestamp
    ) internal view returns (WithdrawalPeriodParams memory) {
        return withdrawalPeriods_[_withdrawalPeriodDeriveId(timestamp)];
    }

    function _withdrawalPeriodIncreaseTotalByTimestamp(
        uint256 timestamp,
        uint256 amount
    ) internal {
        uint withdrawalPeriodId = _withdrawalPeriodDeriveId(timestamp);

        withdrawalPeriods_[withdrawalPeriodId].total += amount;
    }

    function _withdrawalPeriodIncreaseConsideredByTimestamp(
        uint256 timestamp,
        uint256 amount
    ) internal {
        uint withdrawalPeriodId = _withdrawalPeriodDeriveId(timestamp);

        withdrawalPeriods_[withdrawalPeriodId].considered += amount;
    }

    function _withdrawalPeriodCheckLimitsPassed(
        uint amount,
        WithdrawalPeriodParams memory withdrawalPeriod
    ) internal view returns (bool) {
        return  amount < undeclaredWithdrawLimit &&
        amount + withdrawalPeriod.total - withdrawalPeriod.considered < withdrawLimitPerPeriod;
    }

    function _getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./../interfaces/vault/IVault.sol";


abstract contract VaultStorage is IVault, Initializable, ReentrancyGuard {
    uint256 constant MAX_BPS = 10_000;
    uint256 constant WITHDRAW_PERIOD_DURATION_IN_SECONDS = 60 * 60 * 24; // 24 hours
    uint256 constant SECS_PER_YEAR = 31_556_952; // 365.2425 days

    // Bridge
    // - Bridge address, used to verify relay's signatures. Read more on `saveWithdraw`
    address public override bridge;
    // - Bridge EVER-EVM event configuration
    // NOTE: Some variables have "_" postfix and not declared as a "public override"
    // Instead they have explicit corresponding getter
    // It's a compiler issue, described here - https://github.com/ethereum/solidity/issues/11826
    EverscaleAddress configuration_;

    function configuration()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return configuration_;
    }

    // - Withdrawal receipt IDs, used to prevent double spending
    mapping(bytes32 => bool) public override withdrawalIds;
    // - Rewards address in Everscale, receives fees, gains, etc
    EverscaleAddress rewards_;

    function rewards()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return rewards_;
    }

    // Pending withdrawals
    // - Counter pending withdrawals per user
    mapping(address => uint) public override pendingWithdrawalsPerUser;
    // - Pending withdrawal details
    mapping(address => mapping(uint256 => PendingWithdrawalParams)) pendingWithdrawals_;

    function pendingWithdrawals(
        address user,
        uint256 id
    ) external view override returns (PendingWithdrawalParams memory) {
        return pendingWithdrawals_[user][id];
    }

    // - Total amount of `token` in pending withdrawal status
    uint public override pendingWithdrawalsTotal;

    // Ownership
    // - Governance
    address public override governance;
    // - Pending governance, used for 2-step governance transfer
    address pendingGovernance;
    // - Guardian, responsible for security actions
    address public override guardian;
    // - Withdraw guardian, responsible for approving / rejecting some of the withdrawals
    address public override withdrawGuardian;
    // - Management, responsible for managing strategies
    address public override management;

    // Token
    // - Vault's token
    address public override token;
    // - Decimals on corresponding token in the Everscale network
    uint256 public override targetDecimals;
    // - Decimals of `token`
    uint256 public override tokenDecimals;

    // Fees
    // - Deposit fee, in BPS
    uint256 public override depositFee;
    // - Withdraw fee, in BPS
    uint256 public override withdrawFee;
    // - Management fee, in BPS
    uint256 public override managementFee;
    // - Performance fee, in BPS
    uint256 public override performanceFee;

    // Strategies
    // - Strategies registry
    mapping(address => StrategyParams) strategies_;

    function strategies(
        address strategyId
    ) external view override returns (StrategyParams memory) {
        return strategies_[strategyId];
    }

    uint256 constant DEGRADATION_COEFFICIENT = 10**18;
    // - SET_SIZE can be any number but having it in power of 2 will be more gas friendly and collision free.
    // - Make sure SET_SIZE is greater than 20
    uint256 constant SET_SIZE = 32;
    // - Ordering that `withdraw` uses to determine which strategies to pull funds from
    // Does *NOT* have to match the ordering of all the current strategies that
    //      exist, but it is recommended that it does or else withdrawal depth is
    //      limited to only those inside the queue.
    // Ordering is determined by governance, and should be balanced according
    //      to risk, slippage, and/or volatility. Can also be ordered to increase the
    //      withdrawal speed of a particular Strategy.
    // The first time a zero address is encountered, it stops withdrawing
    // Maximum amount of strategies in withdrawal queue = 20
    address[20] withdrawalQueue_;

    function withdrawalQueue() external view override returns (address[20] memory) {
        return withdrawalQueue_;
    }

    // Security
    // - Emergency shutdown, most of operations are unavailable in emergency mode
    bool public override emergencyShutdown;
    // - Withdraw limit per period
    uint256 public override withdrawLimitPerPeriod;
    // - Undeclared withdraw limit
    uint256 public override undeclaredWithdrawLimit;
    // - Withdrawal periods. Each period is `WITHDRAW_PERIOD_DURATION_IN_SECONDS` seconds long.
    // If some period has reached the `withdrawalLimitPerPeriod` - all the future
    // withdrawals in this period require manual approve, see note on `setPendingWithdrawalsApprove`
    mapping(uint256 => WithdrawalPeriodParams) withdrawalPeriods_;

    function withdrawalPeriods(
        uint256 withdrawalPeriodId
    ) external view override returns (WithdrawalPeriodParams memory) {
        return withdrawalPeriods_[withdrawalPeriodId];
    }

    // Vault
    // - Limit for `totalAssets` the Vault can hold
    uint256 public override depositLimit;
    // - Debt ratio for the Vault across al strategies (<= MAX_BPS)
    uint256 public override debtRatio;
    // - Amount of all tokens that all strategies have borrowed
    uint256 public override totalDebt;
    // - block.timestamp of last report
    uint256 public override lastReport;
    // - How much profit is locked and cant be withdrawn
    uint256 public override lockedProfit;
    // - Rate per block of degradation. DEGRADATION_COEFFICIENT is 100% per block
    uint256 public override lockedProfitDegradation;

    // STORAGE UPDATE 1
    uint256 public override fees;
}