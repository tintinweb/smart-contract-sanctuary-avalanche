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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice An error used to indicate that an argument passed to a function is illegal or
///         inappropriate.
///
/// @param message The error message.
error IllegalArgumentWithReason(string message);

/// @notice An error used to indicate that a function has encountered an unrecoverable state.
///
/// @param message The error message.
error IllegalStateWithReason(string message);

/// @notice An error used to indicate that an operation is unsupported.
///
/// @param message The error message.
error UnsupportedOperationWithReason(string message);

/// @notice An error used to indicate that a message sender tried to execute a privileged function.
///
/// @param message The error message.
error UnauthorizedWithReason(string message);

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./IERC20Minimal.sol";

/// @title  IERC20Burnable
/// @author Savvy DeFi
interface IERC20Burnable is IERC20Minimal {
    /// @notice Burns `amount` tokens from the balance of `msg.sender`.
    ///
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burn(uint256 amount) external returns (bool);

    /// @notice Burns `amount` tokens from `owner`'s balance.
    ///
    /// @param owner  The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burnFrom(address owner, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  IERC20Metadata
/// @author Savvy DeFi
interface IERC20Metadata {
    /// @notice Gets the name of the token.
    ///
    /// @return The name.
    function name() external view returns (string memory);

    /// @notice Gets the symbol of the token.
    ///
    /// @return The symbol.
    function symbol() external view returns (string memory);

    /// @notice Gets the number of decimals that the token has.
    ///
    /// @return The number of decimals.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  IERC20Minimal
/// @author Savvy DeFi
interface IERC20Minimal {
    /// @notice An event which is emitted when tokens are transferred between two parties.
    ///
    /// @param owner     The owner of the tokens from which the tokens were transferred.
    /// @param recipient The recipient of the tokens to which the tokens were transferred.
    /// @param amount    The amount of tokens which were transferred.
    event Transfer(address indexed owner, address indexed recipient, uint256 amount);

    /// @notice An event which is emitted when an approval is made.
    ///
    /// @param owner   The address which made the approval.
    /// @param spender The address which is allowed to transfer tokens on behalf of `owner`.
    /// @param amount  The amount of tokens that `spender` is allowed to transfer.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Gets the current total supply of tokens.
    ///
    /// @return The total supply.
    function totalSupply() external view returns (uint256);

    /// @notice Gets the balance of tokens that an account holds.
    ///
    /// @param account The account address.
    ///
    /// @return The balance of the account.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Gets the allowance that an owner has allotted for a spender.
    ///
    /// @param owner   The owner address.
    /// @param spender The spender address.
    ///
    /// @return The number of tokens that `spender` is allowed to transfer on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Transfers `amount` tokens from `msg.sender` to `recipient`.
    ///
    /// @notice Emits a {Transfer} event.
    ///
    /// @param recipient The address which will receive the tokens.
    /// @param amount    The amount of tokens to transfer.
    ///
    /// @return If the transfer was successful.
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Approves `spender` to transfer `amount` tokens on behalf of `msg.sender`.
    ///
    /// @notice Emits a {Approval} event.
    ///
    /// @param spender The address which is allowed to transfer tokens on behalf of `msg.sender`.
    /// @param amount  The amount of tokens that `spender` is allowed to transfer.
    ///
    /// @return If the approval was successful.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `owner` to `recipient` using an approval that `owner` gave to `msg.sender`.
    ///
    /// @notice Emits a {Approval} event.
    /// @notice Emits a {Transfer} event.
    ///
    /// @param owner     The address to transfer tokens from.
    /// @param recipient The address that will receive the tokens.
    /// @param amount    The amount of tokens to transfer.
    ///
    /// @return If the transfer was successful.
    function transferFrom(address owner, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./IERC20Minimal.sol";

/// @title  IERC20Mintable
/// @author Savvy DeFi
interface IERC20Mintable is IERC20Minimal {
    /// @notice Mints `amount` tokens to `recipient`.
    ///
    /// @param recipient The address which will receive the minted tokens.
    /// @param amount    The amount of tokens to mint.
    ///
    /// @return If minting the tokens was successful.
    function mint(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// @title Savvy LGE (Liquidity Generation Event)
// @author Savvy DeFi
// @dev a fair and equitable way for the community to seed liquidity for Savvy

interface ISavvyLGE {
    struct VestMode {
        // Vesting duration for each vest mode
        uint256 duration;
        // The allotment boost when participating with this vest length (e.g. 12000 = 20% boost)
        uint256 boostMultiplier;
    }

    struct UserBuyInfo {
        // Amount of depositToken deposited by the user
        uint256 deposited;
        // Allotments bought by the user
        uint256 allotments;
        // Total boost applied to user
        uint256 totalBoost;
        // The user's weighted average duration for vesting
        uint256 duration;
    }

    struct NFTCollectionInfo {
        // The allotment boost when participating with this NFT (e.g. 12000 = 20% boost)
        uint256 boostMultiplier;
        // MAX deposit that can be added for each NFT within collection
        uint256 limit;
    }

    struct NFTAllocationInfo {
        // DepositToken amount remaining for each NFT
        uint256 remaining;
        // True if the NFT has been used at all
        bool activated;
    }

    struct PreviewBuy {
        // Allotments bought during this purchase.
        uint256 allotments;
        // Vest length of this purchase.
        uint256 vestDuration;
        // Boost as a result of vest.
        uint256 vestBoost;
        // Boost as a result of NFT.
        uint256 nftBoost;
        // Account's total allotments with this purchase.
        uint256 totalAllotments;
        // Account's updated vest length with this purchase.
        uint256 totalVestDuration;
    }
    
    struct LGEDetails {
        uint256 lgeStartTimestamp;
        uint256 lgeEndTimestamp;
        uint256 vestStartTimestamp;
        VestMode[] vestModes;
        uint256[] nftBoostDecays;
        address protocolToken;
        address depositToken;
        uint256 basePricePerAllotment;
    }

    struct LGEFrontendInfo {
        uint256 totalDeposited;
        uint256 totalAllotments;
        uint256 currentNFTBoost;
        uint256 userDepositBalance;
        UserBuyInfo userBuyInfo;
    }

    // @notice Admin function to pause LGE sale.
    function pause() external;

    // @notice Admin function to unpause LGE sale.
    function unpause() external;

    
    /// @notice Get info for a given NFT collection addres.
    /// @param nftCollectionAddress The address of nft collection.
    /// @return The information of nft collection.
    function getNFTCollectionInfo(
        address nftCollectionAddress
    ) external view returns (NFTCollectionInfo memory);

    /// @notice admin function to update info for a given NFT collection address.
    /// @param nftCollectionAddress The address of NFT collection.
    /// @param boostMultiplier BoostMultiplier for NFT.
    /// @param limit The limit amount for nft collection.
    function setNFTCollectionInfo(
        address[] memory nftCollectionAddress,
        uint256[] memory boostMultiplier,
        uint256[] memory limit
    ) external;

    /// @notice Update protocol token contract address.
    /// @param protocolToken The address of protocol token.
    function setProtocolToken(address protocolToken) external;

    /// @notice Update balance of protocol token held by LGE.
    function refreshProtocolTokenBalance() external;

    /// @notice Get all vest mode info.
    /// @return Vest mode informations.
    function getVestModes() external view returns (VestMode[] memory);

    /// @notice Admin function to update all vesting modes
    /// @dev Only owner can call this function.
    /// @param vestModes The array of vest modes.
    function setVestModes(VestMode[] calldata vestModes) external;

    /// @notice Get all nft boost decays.
    /// @notice The decay is in BPS (eg. decay of 2000 or 20% means nft boost is reduced by 20%
    /// @return NFT boost decays.
    function getNFTBoostDecays() external view returns (uint256[] memory);

    /// @notice Admin function to update LGE beginning and end timestamps.
    /// @dev Only owner can call this function.
    /// @param lgeStartTimestamp The start timestamp of lge sale.
    /// @param lgeDurationDays The duration in days of lge sale.
    /// @param vestStartOffset The lag between end of lge sale and start of vesting.
    /// @param nftBoostDecays The array of nft boost decays.
    function setTimestamps(
        uint256 lgeStartTimestamp, 
        uint256 lgeDurationDays, 
        uint256 vestStartOffset,
        uint256[] calldata nftBoostDecays
    ) external;

    /// @notice Set timestamp for start of vest.
    /// @dev Only owner can call this function.
    /// @param vestStartOffset The time offset between end of LGE sale end and start of vest.
    function setVestStartOffset(uint256 vestStartOffset) external;

    /// @notice Calculate boost on allotments based on nft and vest mode.
    /// @param nftCollectionAddress The address of nft collection.
    /// @param nftId The id of nft collection.
    /// @param vestModeIndex The index of vest modes.
    /// @return remainingAmount Available deposit amount in the NFT.
    /// @return allotmentsPerDepositToken The allotment per deposit token.
    function getAllotmentsPerDepositToken(
        address nftCollectionAddress,
        uint256 nftId,
        uint256 vestModeIndex
    ) external view returns (
        uint256 remainingAmount,
        uint256 allotmentsPerDepositToken
    );

    /// @notice Gets LGE details that are unlikely to change.
    /// @dev Enables faster frontend experiences.
    /// @return lgeDetails such as start time, end time, deposit token, vest modes, decay schedule.
    function getLGEDetails() external view returns (LGEDetails memory);

    /// @notice Gets LGE progress.
    /// @dev Enables faster frontend experiences.
    /// @param account the account connected to the frontend.
    /// @param nftCollectionAddress Address of NFT to get current NFT boost.
    /// @return lgeFrontnedInfo such as total deposited, total allotments, current NFT boost.
    function getLGEFrontendInfo(
        address account,
        address nftCollectionAddress
    ) external view returns (LGEFrontendInfo memory);

    /// @notice Routing function to protect internals and simplify front end integration.
    /// @param amount The amount of depositToken to buy allotments.
    /// @param nftCollectionAddress The address of the NFT a user would like to apply for boost - 0 to use default terms
    /// @param nftId The ID of NFT within the collection
    /// @param vestModeIndex The index of vest mode selected
    function buy(
        uint256 amount,
        address nftCollectionAddress,
        uint256 nftId,
        uint256 vestModeIndex
    ) external;

    /// @notice Preview your purchase.
    /// @param amount The amount of depositToken to buy allotments.
    /// @param nftCollectionAddress The address of the NFT a user would like to apply for boost - 0 to use default terms.
    /// @param vestModeIndex The index of vest mode selected.
    /// @return preview The preview of this purchase.
    function previewBuy(
        uint256 amount,
        address nftCollectionAddress,
        uint256 vestModeIndex
    ) external view returns (PreviewBuy memory);

    // @dev Function to get user buy info data
    function getUserBuyInfo(
        address userAddress
    ) external view returns (UserBuyInfo memory);

    /// @notice Claim all pending protocol token.
    function claim() external;

    /// @notice Get pending amount of protocol token of a user.
    function getClaimable(
        address userAddress
    ) external view returns (uint256);

    /// @notice Get balance of protocol token token balance
    /// @return Balance of protocol token.
    function getBalanceProtocolToken() external view returns (uint256);

    /// @notice Withdraws protocol token balance to depositTokenWallet.
    /// @dev Only owner can call this function.
    /// @dev If call this function, contract will be paused.
    function withdrawProtocolToken() external;

    event NFTCollectionInfoUpdated(
        address[] nftCollectionAddress,
        uint256[] price,
        uint256[] limit
    );
    event ProtocolTokenWithdrawn(
        address indexed protocolToken,
        uint256 totalProtocolToken
    );
    event ProtocolTokenUpdated(
        address indexed protocolToken,
        uint256 totalProtocolToken
    );
    event TimestampsUpdated(
        uint256 lgeStartTimestamp,
        uint256 lgeEndTimestamp,
        uint256 vestStartTimestamp
    );
    event VestStartTimestampUpdated(uint256 vestStartTimestamp);
    event VestModesUpdated(uint256 numVestModes);
    event AllotmentsBought(
        address indexed userAddress,
        uint256 deposited,
        uint256 allotments
    );
    event ProtocolTokensClaimed(address indexed userAddress, uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ISavvyErrors
/// @author Savvy DeFi
///
/// @notice Specifies errors.
interface ISavvyErrors {
    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that the system did not recognize.
    ///
    /// @param token The address of the token.
    error UnsupportedToken(address token);

    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that has been disabled.
    ///
    /// @param token The address of the token.
    error TokenDisabled(address token);

    /// @notice An error which is used to indicate that an operation failed because an account became undercollateralized.
    error Undercollateralized();

    /// @notice An error which is used to indicate that an operation failed because the expected value of a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param expectedValue        The expected value measured in units of the base token.
    /// @param maximumExpectedValue The maximum expected value permitted measured in units of the base token.
    error ExpectedValueExceeded(address yieldToken, uint256 expectedValue, uint256 maximumExpectedValue);

    /// @notice An error which is used to indicate that an operation failed because the loss that a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param loss        The amount of loss measured in basis points.
    /// @param maximumLoss The maximum amount of loss permitted measured in basis points.
    error LossExceeded(address yieldToken, uint256 loss, uint256 maximumLoss);

    /// @notice An error which is used to indicate that a borrowing operation failed because the borrowing limit has been exceeded.
    ///
    /// @param amount    The amount of debt tokens that were requested to be borrowed.
    /// @param available The amount of debt tokens which are available to borrow.
    error BorrowingLimitExceeded(uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that an repay operation failed because the repay limit for an base token has been exceeded.
    ///
    /// @param baseToken The address of the base token.
    /// @param amount          The amount of base tokens that were requested to be repaid.
    /// @param available       The amount of base tokens that are available to be repaid.
    error RepayLimitExceeded(address baseToken, uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that an repay operation failed because the repayWithCollateral limit for an base token has been exceeded.
    ///
    /// @param baseToken The address of the base token.
    /// @param amount          The amount of base tokens that were requested to be repaidWithCollateral.
    /// @param available       The amount of base tokens that are available to be repaidWithCollateral.
    error RepayWithCollateralLimitExceeded(address baseToken, uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that the slippage of a wrap or unwrap operation was exceeded.
    ///
    /// @param amount           The amount of underlying or yield tokens returned by the operation.
    /// @param minimumAmountOut The minimum amount of the underlying or yield token that was expected when performing
    ///                         the operation.
    error SlippageExceeded(uint256 amount, uint256 minimumAmountOut);   
}

library Errors {
    // TokenUtils
    string internal constant ERC20CALLFAILED_EXPECTDECIMALS = "SVY101";
    string internal constant ERC20CALLFAILED_SAFEBALANCEOF = "SVY102";
    string internal constant ERC20CALLFAILED_SAFETRANSFER = "SVY103";
    string internal constant ERC20CALLFAILED_SAFEAPPROVE = "SVY104";
    string internal constant ERC20CALLFAILED_SAFETRANSFERFROM = "SVY105";
    string internal constant ERC20CALLFAILED_SAFEMINT = "SVY106";
    string internal constant ERC20CALLFAILED_SAFEBURN = "SVY107";
    string internal constant ERC20CALLFAILED_SAFEBURNFROM = "SVY108";

    // SavvyPositionManager
    string internal constant SPM_FEE_EXCEEDS_BPS = "SVY201"; // protocol fee exceeds BPS
    string internal constant SPM_ZERO_ADMIN_ADDRESS = "SVY202"; // zero pending admin address
    string internal constant SPM_UNAUTHORIZED_PENDING_ADMIN = "SVY203"; // Unauthorized pending admin
    string internal constant SPM_ZERO_SAVVY_SAGE_ADDRESS = "SVY204"; // zero savvy sage address
    string internal constant SPM_ZERO_PROTOCOL_FEE_RECEIVER_ADDRESS = "SVY205"; // zero protocol fee receiver address
    string internal constant SPM_ZERO_RECIPIENT_ADDRESS = "SVY206"; // zero recipient address
    string internal constant SPM_ZERO_TOKEN_AMOUNT = "SVY207"; // zero token amount
    string internal constant SPM_INVALID_DEBT_AMOUNT = "SVY208"; // invalid debt amount
    string internal constant SPM_ZERO_COLLATERAL_AMOUNT = "SVY209"; // zero collateral amount
    string internal constant SPM_INVALID_UNREALIZED_DEBT_AMOUNT = "SVY210"; // invalid unrealized debt amount
    string internal constant SPM_UNAUTHORIZED_ADMIN = "SVY211"; // Unauthorized admin
    string internal constant SPM_UNAUTHORIZED_REDLIST = "SVY212"; // Unauthorized redlist
    string internal constant SPM_UNAUTHORIZED_SENTINEL_OR_ADMIN = "SVY213"; // Unauthorized sentinel or admin
    string internal constant SPM_UNAUTHORIZED_KEEPER = "SVY214"; // Unauthorized keeper
    string internal constant SPM_BORROWING_LIMIT_EXCEEDED = "SVY215"; // Borrowing limit exceeded
    string internal constant SPM_INVALID_TOKEN_AMOUNT = "SVY216"; // invalid token amount
    string internal constant SPM_EXPECTED_VALUE_EXCEEDED = "SVY217"; // Expected Value exceeded
    string internal constant SPM_SLIPPAGE_EXCEEDED = "SVY218"; // Slippage exceeded
    string internal constant SPM_UNDERCOLLATERALIZED = "SVY219"; // Undercollateralized
    string internal constant SPM_UNAUTHORIZED_NOT_ALLOWLISTED = "SVY220"; // Unathorized, not allowlisted
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../base/ErrorMessages.sol";

// a library for validating conditions.

library Checker {
    /// @dev Checks an expression and reverts with an {IllegalArgument} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    /// @param message The error message to display if the check fails.
    function checkArgument(
        bool expression,
        string memory message
    ) internal pure {
        require (expression, message);
    }

    /// @dev Checks an expression and reverts with an {IllegalState} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    /// @param message The error message to display if the check fails.
    function checkState(
        bool expression,
        string memory message
    ) internal pure {
        require (expression, message);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// a library for performing various math operations

library Math {
    uint256 public constant WAD = 1e18;

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y >> 1 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) >> 1;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD >> 1)) / WAD;
    }

    function uoperation(uint256 x, uint256 y, bool addOperation) internal pure returns (uint256 z) {
        if (addOperation) {
            return uadd(x, y);
        } else {
            return usub(x, y);
        }
    }

    /// @dev Subtracts two unsigned 256 bit integers together and returns the result.
    ///
    /// @dev This operation is checked and will fail if the result overflows.
    ///
    /// @param x The first operand.
    /// @param y The second operand.
    ///
    /// @return z the result.
    function usub(uint256 x, uint256 y) internal pure returns (uint256 z) { 
        if (x < y) {
            return 0;
        }
        z = x - y; 
    }

    /// @dev Adds two unsigned 256 bit integers together and returns the result.
    ///
    /// @dev This operation is checked and will fail if the result overflows.
    ///
    /// @param x The first operand.
    /// @param y The second operand.
    ///
    /// @return z The result.
    function uadd(uint256 x, uint256 y) internal pure returns (uint256 z) { z = x + y; }

    /// @notice Return minimum uint256 value.
    /// @param x The first operand.
    /// @param y The second operand.
    /// @return z The result
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) { z = x > y ? y : x; }

    /// @notice Return maximum uint256 value.
    /// @param x The first operand.
    /// @param y The second operand.
    /// @return z The result
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) { z = x > y ? x : y; }
    /// @notice utility function to find weighted averages without any underflows or zero division problems.
    /// @dev use x to determine weights, with y being the values you're weighting
    /// @param valueToAdd new allotment amount
    /// @param currentValue current allotment amount
    /// @param weightToAdd new amount of y being added to weighted average
    /// @param currentWeight current weighted average of y
    /// @return Update duration
    function findWeightedAverage(
        uint256 valueToAdd,
        uint256 currentValue,
        uint256 weightToAdd,
        uint256 currentWeight
    ) internal pure returns (uint256) {
        uint256 totalWeight = weightToAdd + currentWeight;
        if (totalWeight == 0) {
            return 0;
        }
        uint256 totalValue = (valueToAdd * weightToAdd) + (currentValue * currentWeight);
        return totalValue / totalWeight;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../interfaces/savvy/ISavvyErrors.sol";
import "../interfaces/IERC20Burnable.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20Minimal.sol";
import "../interfaces/IERC20Mintable.sol";

/// @title  TokenUtils
/// @author Savvy DeFi
library TokenUtils  {
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

        require (success, Errors.ERC20CALLFAILED_EXPECTDECIMALS);

        return abi.decode(data, (uint8));
    }

    /// @dev Gets the balance of tokens held by an account.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token   The token to check the balance of.
    /// @param account The address of the token holder.
    ///
    /// @return The balance of the tokens held by an account.
    function safeBalanceOf(address token, address account) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, account)
        );
        require (success, Errors.ERC20CALLFAILED_SAFEBALANCEOF);
        
        return abi.decode(data, (uint256));
    }

    /// @dev Transfers tokens to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransfer(address token, address recipient, uint256 amount) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(IERC20Minimal.transfer.selector, recipient, amount)
        );

        require (success, Errors.ERC20CALLFAILED_SAFETRANSFER);
    }

    /// @dev Approves tokens for the smart contract.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an unexpected value.
    ///
    /// @param token   The token to approve.
    /// @param spender The contract to spend the tokens.
    /// @param value   The amount of tokens to approve.
    function safeApprove(address token, address spender, uint256 value) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(IERC20Minimal.approve.selector, spender, value)
        );

        require (success, Errors.ERC20CALLFAILED_SAFEAPPROVE);
    }

    /// @dev Transfer tokens from one address to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param owner     The address of the owner.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransferFrom(address token, address owner, address recipient, uint256 amount) internal returns (uint256) {
        uint256 balanceBefore = IERC20Minimal(token).balanceOf(recipient);
        (bool success, ) = token.call(
            abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, owner, recipient, amount)
        );
        uint256 balanceAfter = IERC20Minimal(token).balanceOf(recipient);

        require (success, Errors.ERC20CALLFAILED_SAFETRANSFERFROM);

        return (balanceAfter - balanceBefore);
    }

    /// @dev Mints tokens to an address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the mint fails or returns an unexpected value.
    ///
    /// @param token     The token to mint.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to mint.
    function safeMint(address token, address recipient, uint256 amount) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(IERC20Mintable.mint.selector, recipient, amount)
        );

        require (success, Errors.ERC20CALLFAILED_SAFEMINT);
    }

    /// @dev Burns tokens.
    ///
    /// Reverts with a `CallFailed` error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param amount The amount of tokens to burn.
    function safeBurn(address token, uint256 amount) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(IERC20Burnable.burn.selector, amount)
        );

        require (success, Errors.ERC20CALLFAILED_SAFEBURN);
    }

    /// @dev Burns tokens from its total supply.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param owner  The owner of the tokens.
    /// @param amount The amount of tokens to burn.
    function safeBurnFrom(address token, address owner, uint256 amount) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(IERC20Burnable.burnFrom.selector, owner, amount)
        );

        require (success, Errors.ERC20CALLFAILED_SAFEBURNFROM);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/ISavvyLGE.sol";
import "./libraries/Checker.sol";
import "./libraries/Math.sol";
import "./libraries/TokenUtils.sol";
import "./base/Errors.sol";

contract SavvyLGE is
    Ownable2Step,
    Initializable,
    Pausable,
    ReentrancyGuardUpgradeable,
    ISavvyLGE
{
    using SafeERC20 for IERC20;

    /// @dev This is constant value to calculate boostMultiplier
    uint256 public constant BASIS_POINTS = 10_000;

    /// @dev protocol token
    IERC20 public protocolToken;
    /// @dev token accepted for deposit
    IERC20 public depositToken;
    /// @dev number of decimals required to normalized depositToken to 18 decimals
    uint256 public conversionFactor;
    /// @dev base price for 1 unit ($depositToken) per allotment
    uint256 public pricePerAllotment;
    /// @dev address where funds deposited are sent
    address public depositTokenWallet;

    /// @dev amount of depositToken deposited
    uint256 public totalDeposited;
    /// @dev total allotments in existence
    uint256 public allotmentSupply;
    /// @dev initial protocol token balance in LGE
    uint256 public totalProtocolToken;

    /// @dev start time of LGE sale
    uint256 public lgeStartTimestamp;
    /// @dev end time of LGE sale
    uint256 public lgeEndTimestamp;
    /// @dev start time of vest
    uint256 public vestStartTimestamp;
    /// @dev NFT boost decay for each day of LGE sale
    uint256[] public nftBoostDecays;

    /// @dev list of vest modes with duration and boost multiplier
    VestMode[] public vestModes;
    /// @dev mapping of boosts for redlisted NFT collections
    mapping(address => NFTCollectionInfo) public nftCollectionInfos;
    /// @dev mapping of NFTs used for boosts
    mapping(address => mapping(uint256 => NFTAllocationInfo)) public nftAllocationInfos;

    /// @dev mapping of weighted average purchases for each user
    mapping(address => UserBuyInfo) public userBuyInfos;
    // @dev mapping of the amount of protocol tokens claimed so far by each user
    mapping(address => uint256) public claimed;

    modifier lgeNotEnded {
        Checker.checkState(block.timestamp <= lgeEndTimestamp, "LGE has ended");
        _;
    }

    modifier vestNotStarted {
        Checker.checkState (block.timestamp <= vestStartTimestamp, "vest has started");
        _;
    }

    /// @dev initialize LGE contract
    function initialize (
        address _protocolToken,
        address _depositToken,
        address _depositTokenWallet,
        uint256 _lgeStartTimestamp,
        uint256 _lgeDurationDays,
        uint256 _vestStartOffset,
        uint256[] calldata _nftBoostDecays,
        VestMode[] calldata _vestModes
    ) external initializer {
        _checkProtocolTokenValidation(address(_protocolToken));
        _setProtocolToken(_protocolToken);
        
        Checker.checkArgument(_depositToken != address(0), "invalid deposit token");
        depositToken = IERC20(_depositToken);
        pricePerAllotment = 10 ** TokenUtils.expectDecimals(_depositToken);
        conversionFactor = 10 ** (18 - TokenUtils.expectDecimals(_depositToken));

        Checker.checkArgument(_depositTokenWallet != address(0), "invalid depositTokenWallet address");
        depositTokenWallet = _depositTokenWallet;

        _setTimestamps(
            _lgeStartTimestamp, 
            _lgeDurationDays, 
            _vestStartOffset,
            _nftBoostDecays
        );
        _setVestModes(_vestModes);
        _transferOwnership(msg.sender);
    }

    /// @inheritdoc	ISavvyLGE
    function pause() external override onlyOwner {
        _pause();
    }

    /// @inheritdoc	ISavvyLGE
    function unpause() external override onlyOwner {
        Checker.checkState(totalProtocolToken > 0, "need to supply protocol tokens to LGE");
        _unpause();
    }

    /// @inheritdoc	ISavvyLGE
    function getNFTCollectionInfo(
        address nftCollectionAddress
    ) external view override returns (NFTCollectionInfo memory) {
        return nftCollectionInfos[nftCollectionAddress];
    }

    /// @inheritdoc	ISavvyLGE
    function setNFTCollectionInfo(
        address[] memory nftCollectionAddresses,
        uint256[] memory boostMultipliers,
        uint256[] memory limits
    ) external override onlyOwner {
        uint256 length = nftCollectionAddresses.length;
        Checker.checkArgument(length > 0, "invalid nftCollectionAddress array");
        Checker.checkArgument(
            length == boostMultipliers.length && length == limits.length,
            "mismatch array"
        );

        for (uint256 i = 0; i < length; i++) {
            address nftCollectionAddress = nftCollectionAddresses[i];
            uint256 boostMultiplier = boostMultipliers[i];
            uint256 limit = limits[i];

            Checker.checkArgument(
                nftCollectionAddress != address(0),
                "zero nftCollection address"
            );
            nftCollectionInfos[nftCollectionAddress] = NFTCollectionInfo(
                boostMultiplier,
                limit
            );
        }

        emit NFTCollectionInfoUpdated(
            nftCollectionAddresses,
            boostMultipliers,
            limits
        );
    }

    /// @inheritdoc	ISavvyLGE
    function getBalanceProtocolToken() external view override returns (uint256) {
        return protocolToken.balanceOf(address(this));
    }

    /// @inheritdoc	ISavvyLGE
    function withdrawProtocolToken() public override onlyOwner {
        _pause();
        _withdrawProtocolToken();
    }

    /// @inheritdoc	ISavvyLGE
    function setProtocolToken(address _protocolToken) external override onlyOwner {
        Checker.checkArgument(_protocolToken != address(protocolToken), "same protocol token address");
        _checkProtocolTokenValidation(_protocolToken);
        Checker.checkArgument(
            IERC20(_protocolToken).balanceOf(address(this)) > 0, 
            "need to supply protocol tokens to LGE"
        );
        withdrawProtocolToken();
        _setProtocolToken(_protocolToken);
    }

    /// @inheritdoc	ISavvyLGE
    function refreshProtocolTokenBalance() external override onlyOwner {
        Checker.checkArgument(address(protocolToken) != address(0), "protocol token not set");
        totalProtocolToken = protocolToken.balanceOf(address(this));
    }

    /// @inheritdoc	ISavvyLGE
    function getVestModes() external view override returns (VestMode[] memory) {
        return vestModes;
    }

    /// @inheritdoc	ISavvyLGE
    function setVestModes(VestMode[] calldata _vestModes) external override onlyOwner {
        _pause();
        _setVestModes(_vestModes);
    }

    /// @inheritdoc	ISavvyLGE
    function getNFTBoostDecays() external view override returns (uint256[] memory) {
        return nftBoostDecays;
    }

    /// @inheritdoc ISavvyLGE
    function getLGEDetails() external view override returns (LGEDetails memory) {
        return LGEDetails(
            lgeStartTimestamp,  // lgeStartTimestamp
            lgeEndTimestamp,    // lgeEndTimestamp
            vestStartTimestamp, // vestStartTimestamp
            vestModes,  // vestModes
            nftBoostDecays, // nftBoostDecays
            address(protocolToken), // protocolToken
            address(depositToken),  // depositToken
            pricePerAllotment   // basePricePerAllotment
        );
    }

    /// @inheritdoc ISavvyLGE
    function getLGEFrontendInfo(address account, address nftCollectionAddress) external view override returns (LGEFrontendInfo memory) {
        uint256 accountBalance = depositToken.balanceOf(account);
        uint256 normalizedAccountBalance = accountBalance * conversionFactor;

        return LGEFrontendInfo(
            totalDeposited, // totalDeposited
            allotmentSupply, // totalAllotments
            _getNFTBoost(nftCollectionAddress), // currentNFTBoost
            normalizedAccountBalance, // userDepositBalance
            userBuyInfos[account] // userBuyInfo
        );
    }

    /// @inheritdoc	ISavvyLGE
    function setTimestamps(
        uint256 _lgeStartTimestamp,
        uint256 _lgeDurationDays,
        uint256 _vestStartOffset,
        uint256[] calldata _nftBoostDecays
    ) external override onlyOwner vestNotStarted {
        _pause();
        _setTimestamps(
            _lgeStartTimestamp, 
            _lgeDurationDays, 
            _vestStartOffset,
            _nftBoostDecays
        );
    }

    /// @inheritdoc	ISavvyLGE
    function getAllotmentsPerDepositToken(
        address nftCollectionAddress,
        uint256 nftId,
        uint256 vestModeIndex
    ) public view override lgeNotEnded returns (
        uint256 remainingAmount,
        uint256 allotmentsPerDepositToken
    ) {
        require (vestModeIndex < vestModes.length, "Invalid vestModeIndex");

        NFTAllocationInfo memory nftAllocationInfo = nftAllocationInfos[nftCollectionAddress][nftId];
        remainingAmount = nftAllocationInfo.activated 
            ? nftAllocationInfo.remaining
            : nftCollectionInfos[nftCollectionAddress].limit;
        allotmentsPerDepositToken = _getAllotmentsPerDepositToken(nftCollectionAddress, vestModeIndex);
    }

    /// @inheritdoc ISavvyLGE
    function previewBuy(
        uint256 amount,
        address nftCollectionAddress,
        uint256 vestModeIndex
    ) external view returns (PreviewBuy memory) {
        uint256 allotmentsPerDepositToken  = _getAllotmentsPerDepositToken(nftCollectionAddress, vestModeIndex);
        uint256 allotments = amount * allotmentsPerDepositToken;
        VestMode memory vestMode = vestModes[vestModeIndex];

        uint256 nftBoost = _getNFTBoost(nftCollectionAddress);

        UserBuyInfo storage userBuyInfo = userBuyInfos[msg.sender];
        uint256 totalVestDuration = Math.findWeightedAverage(
            vestModes[vestModeIndex].duration,
            userBuyInfo.duration,
            allotments,
            userBuyInfo.allotments
        );

        return PreviewBuy(
            allotments,                          // allotments
            vestMode.duration,                   // vestLength
            vestMode.boostMultiplier,            // vestBoost
            nftBoost,                            // nftBoost
            userBuyInfo.allotments + allotments, // totalAllotments
            totalVestDuration                    // totalVestLength
        );
    }

    /// @inheritdoc	ISavvyLGE
    function buy(
        uint256 amount,
        address nftCollectionAddress,
        uint256 nftId,
        uint256 vestModeIndex
    ) public override whenNotPaused lgeNotEnded nonReentrant {
        Checker.checkState(block.timestamp >= lgeStartTimestamp, "lge has not begun");
        Checker.checkArgument(amount != 0, "amount is invalid");
        Checker.checkArgument(vestModeIndex < vestModes.length, "invalid vest mode index");
        if (nftCollectionAddress != address(0)) {
            Checker.checkArgument(nftCollectionInfos[nftCollectionAddress].limit != 0, "this NFT is not eligible for boost");
            Checker.checkArgument(IERC721(nftCollectionAddress).ownerOf(nftId) == msg.sender, "buyer is not the owner of this NFT");
        }
        amount = TokenUtils.safeTransferFrom(address(depositToken), msg.sender, depositTokenWallet, amount);
        _buy(amount, nftCollectionAddress, nftId, vestModeIndex);
    }

    /// @inheritdoc	ISavvyLGE
    function getUserBuyInfo(
        address userAddress
    ) external view override returns (UserBuyInfo memory) {
        return userBuyInfos[userAddress];
    }

    /// @inheritdoc	ISavvyLGE
    function claim() external override {
        uint256 owed = getClaimable(msg.sender);
        Checker.checkState(owed > 0, "no claimable amount");

        claimed[msg.sender] += owed;
        protocolToken.safeTransfer(msg.sender, owed);

        emit ProtocolTokensClaimed(msg.sender, owed);
    }

    /// @inheritdoc ISavvyLGE
    function setVestStartOffset(
        uint256 _vestStartOffset
    ) external onlyOwner override vestNotStarted {
        vestStartTimestamp = lgeEndTimestamp + _vestStartOffset;

        emit VestStartTimestampUpdated(vestStartTimestamp);
    }

    /// @inheritdoc	ISavvyLGE
    function getClaimable(
        address userAddress
    ) public view override returns (uint256) {
        Checker.checkState(block.timestamp > vestStartTimestamp, "vesting has not started");

        uint256 totalOwed = (totalProtocolToken * userBuyInfos[userAddress].allotments) / allotmentSupply;
        uint256 accruedPerSecond = totalOwed / userBuyInfos[userAddress].duration;
        uint256 secondsClaimed = claimed[userAddress] / accruedPerSecond;
        uint256 lastClaim = vestStartTimestamp + secondsClaimed;
        uint256 owed = (block.timestamp - lastClaim) * accruedPerSecond;
        if (claimed[userAddress] + owed > totalOwed) {
            owed = totalOwed - claimed[userAddress];
        }
        return owed;
    }

    /// @notice function that applies NFT and vest mode terms to the user's purchase
    /// @dev transferring user funds directly to depositTokenWallet
    /// @param deposited amount of depositTokens to buy allotments.
    /// @param nftCollectionAddress address of the NFT collection user is using
    /// @param nftId ID paired with the NFT contract
    /// @param vestModeIndex vest mode index
    function _buy(
        uint256 deposited,
        address nftCollectionAddress,
        uint256 nftId,
        uint256 vestModeIndex
    ) internal {
        uint256 allotmentsPerDepositToken  = _getAllotmentsPerDepositToken(nftCollectionAddress, vestModeIndex);
        uint256 decimals = TokenUtils.expectDecimals(address(depositToken));
        uint256 allotments = deposited * allotmentsPerDepositToken / 10**decimals;
        
        if (nftCollectionAddress != address(0)) {
            NFTAllocationInfo storage nftAllocationInfo = nftAllocationInfos[nftCollectionAddress][nftId];
            if (!nftAllocationInfo.activated) {
                _activate(nftCollectionAddress, nftId, deposited);
            } else {
                Checker.checkState(nftAllocationInfo.remaining >= deposited, "insufficient availability for nft");
                nftAllocationInfo.remaining -= deposited;
            }
        }

        _updateUserBuyInfo(deposited, allotments, vestModeIndex);
        allotmentSupply += allotments;
        totalDeposited += deposited;

        emit AllotmentsBought(msg.sender, deposited, allotments);
    }

    /// @notice calculates allotments per deposit token based on NFT and vest mode
    /// @param nftCollectionAddress address of the NFT terms user is using
    /// @param vestModeIndex vest mode index
    /// @return allotmentPerDepositToken Allotment per depositToken
    function _getAllotmentsPerDepositToken(
        address nftCollectionAddress,
        uint256 vestModeIndex
    ) internal view returns (uint256 allotmentPerDepositToken) {
        uint256 vestModeBooster = vestModes[vestModeIndex].boostMultiplier;
        allotmentPerDepositToken = pricePerAllotment * vestModeBooster / BASIS_POINTS;
        
        if (nftCollectionAddress != address(0)) {
            uint256 nftBoost = _getNFTBoost(nftCollectionAddress);
            if (nftBoost != 0) {
                allotmentPerDepositToken = allotmentPerDepositToken * nftBoost / BASIS_POINTS;
            }
        }
    }

    /// @notice Get the current NFT decay.
    /// @return decay The current NFT decay.
    function _getNFTDecay() internal view returns (uint256) {
        uint256 decay = 0;
        if (block.timestamp >= lgeStartTimestamp) {
            uint8 numberOfDays = _getLGESaleDayTerm();
            decay = nftBoostDecays[numberOfDays];
        }
        return decay;
    }

    /// @notice Get the current NFT boost with decay applied.
    /// @return nftBoost The current NFT boost.
    function _getNFTBoost(address nftCollectionAddress) internal view returns (uint256) {
        uint256 nftRawBoost = nftCollectionInfos[nftCollectionAddress].boostMultiplier;
        if (nftRawBoost == 0) {
            return 0;
        }
        uint256 decay = _getNFTDecay();
        uint256 nftBoost = nftRawBoost * (BASIS_POINTS - decay) / BASIS_POINTS;
        return nftBoost;
    }

    /// @notice Get number of days after lge sale started.
    /// @dev The index is started from 0.
    /// @return Number of days after lge started.
    function _getLGESaleDayTerm() internal view returns (uint8) {
        uint256 curTimestamp = block.timestamp;
        if (curTimestamp >= lgeEndTimestamp) {
            return uint8((lgeEndTimestamp - lgeStartTimestamp) / 1 days) - 1;
        }
        uint256 elapsedTime = curTimestamp - lgeStartTimestamp;
        return uint8(elapsedTime / 1 days);
    }

    // @dev pulls NFT state into allocation state and updates the amount to
    // ensure double spends aren't possible
    // nftCollectionAddress:: address of the NFT collection being used
    // nftId:: id of the NFT you're activating
    // amount:: amount being spent out of that NFT
    function _activate(
        address nftCollectionAddress,
        uint256 nftId,
        uint256 amount
    ) internal {
        Checker.checkArgument(amount <= nftCollectionInfos[nftCollectionAddress].limit, "deposit Token amount exceeeds nft allocation limit");
        NFTAllocationInfo storage nftAllocationInfo = nftAllocationInfos[nftCollectionAddress][nftId];
        nftAllocationInfo.remaining = nftCollectionInfos[nftCollectionAddress].limit - amount;
        nftAllocationInfo.activated = true;
    }

    // @dev updates the user's buy info, update amount of allotments with average duration
    // deposited:: amount of depositTokens deposited to get allotments.
    // allotments:: allotments being added to total - used to determine weight
    // vestModeIndex:: vest mode index
    function _updateUserBuyInfo(
        uint256 deposited,
        uint256 allotments, 
        uint256 vestModeIndex
    ) internal {
        UserBuyInfo storage userBuyInfo = userBuyInfos[msg.sender];
        userBuyInfo.duration = Math.findWeightedAverage(
            vestModes[vestModeIndex].duration,
            userBuyInfo.duration,
            allotments,
            userBuyInfo.allotments
        );
        userBuyInfo.deposited += deposited;
        userBuyInfo.allotments += allotments;
        userBuyInfo.totalBoost = userBuyInfo.allotments * BASIS_POINTS / userBuyInfo.deposited;
    }

    /// @dev withdraw all protocolToken from this contract to depositTokenWallet
    function _withdrawProtocolToken() internal {
        uint256 currentBalance = protocolToken.balanceOf(address(this));
        protocolToken.safeTransfer(depositTokenWallet, currentBalance);

        emit ProtocolTokenWithdrawn(address(protocolToken), currentBalance);
    }

    /// @dev update protocol token contract address
    function _setProtocolToken(address _protocolToken) internal {
        Checker.checkArgument(_protocolToken != address(0), "invalid protocol token address");
        IERC20 newProtocolToken = IERC20(_protocolToken);
        uint256 currentBalance = newProtocolToken.balanceOf(address(this));
        protocolToken = newProtocolToken;
        totalProtocolToken = currentBalance;

        emit ProtocolTokenUpdated(_protocolToken, currentBalance);
    }

    /// @dev admin function to update entire vesting modes
    function _setVestModes(VestMode[] memory _vestModes) internal {
        Checker.checkArgument(_vestModes.length > 0, "empty VestMode array");
        delete vestModes;
        for (uint256 i; i < _vestModes.length; i++) {
            Checker.checkArgument(_vestModes[i].boostMultiplier >= BASIS_POINTS, "invalid boost price");
            Checker.checkArgument(_vestModes[i].duration > 0, "invalid duration");
            vestModes.push(_vestModes[i]);
        }

        emit VestModesUpdated(_vestModes.length);
    }

    /// @dev admin function to update LGE lgeStartTimestamp and end timestamps
    function _setTimestamps(
        uint256 _lgeStartTimestamp, 
        uint256 _lgeDurationDays, 
        uint256 _vestStartOffset,
        uint256[] calldata _nftBoostDecays
    ) internal {
        Checker.checkArgument(_lgeStartTimestamp > block.timestamp, "LGE must start in the future");
        Checker.checkArgument(_lgeDurationDays == _nftBoostDecays.length, "NFT boost decay length mismatch");
        lgeStartTimestamp = _lgeStartTimestamp;
        lgeEndTimestamp = _lgeStartTimestamp + _lgeDurationDays * 1 days;
        vestStartTimestamp = lgeEndTimestamp + _vestStartOffset;

        delete nftBoostDecays;
        for (uint256 i; i < _nftBoostDecays.length; i++) {
            Checker.checkArgument(_nftBoostDecays[i] < BASIS_POINTS, "NFT boost decay cannot exceed 100%");
            nftBoostDecays.push(_nftBoostDecays[i]);
        }
        
        emit TimestampsUpdated(lgeStartTimestamp, lgeEndTimestamp, vestStartTimestamp);
    }

    /// @notice Check protocol token is validate.
    /// @param _protocolToken The address of protocol token to set.
    function _checkProtocolTokenValidation(
        address _protocolToken
    ) internal view {
        Checker.checkArgument(_protocolToken != address(0), "zero protocol token address");
        Checker.checkArgument(_protocolToken != address(depositToken), "protocol token is same as deposit token");
    }

    uint256[100] private __gap;
}