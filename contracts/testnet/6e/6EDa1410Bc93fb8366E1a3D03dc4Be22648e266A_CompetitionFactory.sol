/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-14
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]
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


// File @openzeppelin/contracts-upgradeable/access/[email protected]
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]
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


// File @openzeppelin/contracts/utils/introspection/[email protected]
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


// File @openzeppelin/contracts/token/ERC721/[email protected]
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File contracts/competition/IZizyCompetitionTicket.sol

pragma solidity ^0.8.9;

interface IZizyCompetitionTicket is IERC721, IERC721Enumerable {
    event DescriptionChanged(string description);
    event TicketMinted(address ticketOwner, uint256 ticketId);

    function setDescription(string memory description_) external;

    function setBaseURI(string memory baseUri_) external;

    function mint(address to_, uint256 ticketId_) external;

    function pause() external;

    function unpause() external;
}


// File contracts/competition/IZizyCompetitionStaking.sol

pragma solidity ^0.8.9;

interface IZizyCompetitionStaking {
    function getSnapshotsAverage(address account, uint256 periodId, uint256 min, uint256 max) external view returns (uint256, bool);

    function getPeriodStakeAverage(address account, uint256 periodId) external view returns (uint256, bool);

    function getPeriodSnapshotRange(uint256 periodId) external view returns (uint, uint);

    function setPeriodId(uint256 period) external returns (uint256);

    function getSnapshotId() external view returns (uint256);

    function stake(uint256 amount_) external;

    function getPeriod(uint256 periodId_) external view returns (uint, uint, uint, uint, uint16, bool);

    function unStake(uint256 amount_) external;
}


// File contracts/competition/ITicketDeployer.sol

pragma solidity ^0.8.9;

interface ITicketDeployer {
    function deploy(string memory name_, string memory symbol_, string memory description_) external returns (uint256, address);

    function getDeployedContractCount() external view returns (uint256);
}


// File contracts/competition/CompetitionFactory.sol

pragma solidity ^0.8.9;
// @dev We building sth big. Stay tuned!
contract CompetitionFactory is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event NewCompetitionPeriod(uint startTime, uint endTime, uint256 periodNumber);
    event NewCompetition(uint256 periodNumber, address ticketAddress);
    event TicketBuy(address indexed account, uint256 periodId, uint16 competitionId, uint32 indexed ticketCount);
    event TicketSend(address indexed account, uint256 periodId, uint16 competitionId, uint256 ticketId);

    // Add competition allocation limit
    struct Competition {
        IZizyCompetitionTicket ticket;
        address sellToken;
        uint ticketPrice;
        uint snapshotMin;
        uint snapshotMax;
        uint32 ticketSold;
        bool buyActive;
        bool _exist;
    }

    struct TicketBuyOptions {
        uint buyStartDate;
        uint buyEndDate;
        bool isActive;
    }

    struct CompetitionPeriod {
        uint startTime;
        uint endTime;
        uint ticketBuyStartTime;
        uint ticketBuyEndTime;
        uint16 competitionCount;
        bool _exist;
    }

    struct Tier {
        uint min;
        uint max;
        uint32 allocation;
    }

    struct Allocation {
        uint32 max;
        uint32 bought;
        bool hasAllocation;
    }

    uint256 private _currentPeriodNumber;
    uint256 private _totalCompetitionCount;
    IZizyCompetitionStaking public stakingContract;
    ITicketDeployer public ticketDeployer;

    address public paymentReceiver;
    address public ticketMinter;

    // Competition periods [periodId > CompetitionPeriod]
    mapping(uint256 => CompetitionPeriod) private _periods;

    // Competition in periods [periodId > competitionId > Competition]
    mapping(uint256 => mapping(uint16 => Competition)) private _periodCompetitions;

    // Competition tiers [keccak(periodId,competitionId) > Tier]
    mapping(bytes32 => Tier[]) private _compTiers;

    // Period ticket buy options
    mapping(uint256 => TicketBuyOptions) private _ticketBuyOptions;

    // Competition allocations [address > periodId > competitionId > Allocation]
    mapping(address => mapping(uint256 => mapping(uint16 => Allocation))) private _allocations;

    // Period participations [Account > PeriodId > Status]
    mapping(address => mapping(uint256 => bool)) private _periodParticipation;

    // Throw if any active period exist on now
    modifier whenNotActivePeriod() {
        uint256 cPeriod = _currentPeriodNumber;

        if (cPeriod == 0) {
            // Check current period end time
            require(_periods[cPeriod]._exist == false, "ZizyComp: Period exist");
            require(_periods[cPeriod].endTime < block.timestamp, "ZizyComp: Current period isn't completed");
        } else {
            // Check current period & previous period end time
            require(_periods[cPeriod]._exist == false, "ZizyComp: Period exist");
            require(_periods[cPeriod].endTime < block.timestamp, "ZizyComp: Current period isn't completed");

            require(_periods[cPeriod - 1].endTime < block.timestamp, "ZizyComp: Previous period isn't completed");
        }
        _;
    }

    // Throw if staking contract isn't defined
    modifier stakeContractIsSet {
        require(address(stakingContract) != address(0), "ZizyComp: Staking contract should be defined");
        _;
    }

    // Throw if ticket deployer contract isn't defined
    modifier ticketDeployerIsSet {
        require(address(ticketDeployer) != address(0), "ZizyComp: Ticket deployer contract should be defined");
        _;
    }

    // Throw if payment receiver address isn't defined
    modifier paymentReceiverIsSet {
        require(paymentReceiver != address(0), "Payment receiver address is not defined");
        _;
    }

    // Throw if current period isn't exist
    modifier whenCurrentPeriodExist() {
        uint256 cPeriod = _currentPeriodNumber;

        require(cPeriod > 0, "ZizyComp: There is no period exist");
        // Period index check
        require(_periods[cPeriod]._exist, "ZizyComp: There is no period exist");
        _;
    }

    // Throw if caller isn't minter
    modifier onlyMinter() {
        require(msg.sender == ticketMinter, "Only call from minter");
        _;
    }

    function initialize(address receiver_, address minter_) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        _currentPeriodNumber = 0;
        _totalCompetitionCount = 0;

        paymentReceiver = receiver_;
        ticketMinter = minter_;
    }

    // Hash of period competition
    function _competitionKey(uint256 periodId, uint16 competitionId) internal pure returns (bytes32) {
        return keccak256(abi.encode(periodId, competitionId));
    }

    // Check any account has participation on specified period
    function hasParticipation(address account_, uint256 periodId_) external view returns (bool) {
        return _periodParticipation[account_][periodId_];
    }

    // Set payment receiver address
    function setPaymentReceiver(address receiver_) external onlyOwner {
        require(receiver_ != address(0), "Payment receiver can not be zero address");
        paymentReceiver = receiver_;
    }

    // Set ticket minter address
    function setTicketMinter(address minter_) external onlyOwner {
        require(minter_ != address(0), "Minter address can not be zero");
        ticketMinter = minter_;
    }

    // Get competition allocation for account
    function getAllocation(address account, uint256 periodId, uint16 competitionId) external view returns (uint32, uint32, bool) {
        Allocation memory alloc = _allocations[account][periodId][competitionId];
        return (alloc.bought, alloc.max, alloc.hasAllocation);
    }

    // Set staking contract address
    function setStakingContract(address stakingContract_) external onlyOwner {
        require(address(stakingContract_) != address(0), "ZizyComp: Staking contract address can not be zero");
        stakingContract = IZizyCompetitionStaking(stakingContract_);
    }

    // Set ticket deployer contract address
    function setTicketDeployer(address ticketDeployer_) external onlyOwner {
        require(address(ticketDeployer_) != address(0), "ZizyComp: Ticket deployer contract address can not be zero");
        ticketDeployer = ITicketDeployer(ticketDeployer_);
    }

    // Create competition period
    function createCompetitionPeriod(uint startTime_, uint endTime_, uint ticketBuyStart_, uint ticketBuyEnd_) external whenNotActivePeriod stakeContractIsSet onlyOwner returns (uint256) {
        uint256 newPeriodNumber = (_currentPeriodNumber + 1);

        (uint256 response) = stakingContract.setPeriodId(newPeriodNumber);
        require(response == newPeriodNumber, "ZizyComp: Staking contract period can't updated");

        _periods[newPeriodNumber] = CompetitionPeriod(startTime_, endTime_, ticketBuyStart_, ticketBuyEnd_, 0, true);

        _currentPeriodNumber = newPeriodNumber;

        emit NewCompetitionPeriod(startTime_, endTime_, newPeriodNumber);

        return newPeriodNumber;
    }

    // Update period date ranges
    function updateCompetitionPeriod(uint periodId_, uint startTime_, uint endTime_, uint ticketBuyStart_, uint ticketBuyEnd_) external onlyOwner returns (bool) {
        CompetitionPeriod storage period = _periods[periodId_];
        require(period._exist == true, "There is no period exist");

        period.startTime = startTime_;
        period.endTime = endTime_;
        period.ticketBuyStartTime = ticketBuyStart_;
        period.ticketBuyEndTime = ticketBuyEnd_;

        return true;
    }

    // Create competition for current period
    function createCompetition(string memory name_, string memory symbol_, string memory description_) external whenCurrentPeriodExist ticketDeployerIsSet onlyOwner returns (address, uint256, uint16) {
        uint256 periodIndex = _currentPeriodNumber;
        CompetitionPeriod memory currentPeriod = _periods[periodIndex];

        // Deploy competition ticket contract
        (, address ticketContract) = ticketDeployer.deploy(name_, symbol_, description_);
        IZizyCompetitionTicket competition = IZizyCompetitionTicket(ticketContract);

        // Pause transfers on init
        competition.pause();

        // Add ticket NFT into the list
        _periodCompetitions[periodIndex][(currentPeriod.competitionCount + 1)] = Competition(competition, address(0), 0, 0, 0, 0, false, true);

        // Increase competition counters
        _periods[periodIndex].competitionCount++;
        _totalCompetitionCount++;

        // Emit new competition event
        emit NewCompetition(periodIndex, address(competition));

        return (address(competition), periodIndex, ((currentPeriod.competitionCount + 1)));
    }

    // Set ticket sale settings for competition
    function setCompetitionPayment(uint256 periodId, uint16 competitionId, address token, uint ticketPrice) external onlyOwner {
        require(token != address(0), "Payment token can not be zero address");
        require(ticketPrice > 0, "Ticket price can not be zero");

        Competition storage comp = _periodCompetitions[periodId][competitionId];
        comp.buyActive = true;
        comp.sellToken = token;
        comp.ticketPrice = ticketPrice;
    }

    // Set competition snapshot range
    function setCompetitionSnapshotRange(uint256 periodId, uint16 competitionId, uint min, uint max) external stakeContractIsSet onlyOwner {
        require(min <= max, "Min should be higher");
        (uint periodMin, uint periodMax) = stakingContract.getPeriodSnapshotRange(periodId);
        require(min >= periodMin && max <= periodMax, "Range should between period snapshot ranges");
        Competition storage comp = _periodCompetitions[periodId][competitionId];
        require(comp._exist == true, "There is no competition");

        comp.snapshotMin = min;
        comp.snapshotMax = max;
    }

    // Set competition tiers
    function setCompetitionTiers(uint256 periodId, uint16 competitionId, uint[] calldata mins, uint[] calldata maxs, uint32[] calldata allocs) external onlyOwner {
        uint length = mins.length;
        require(length > 1, "Tiers should be higher than 1");
        require(length == maxs.length && length == allocs.length, "Should be same length");

        bytes32 compHash = _competitionKey(periodId, competitionId);
        uint prevMax = 0;
        uint prevMin = 0;

        delete _compTiers[compHash];


        for (uint i = 0; i < length; ++i) {
            bool isFirst = (i == 0);
            bool isLast = (i == (length - 1));
            uint32 alloc = allocs[i];
            uint min = mins[i];
            uint max = (isLast ? (2 ** 256 - 1) : maxs[i]);

            if (!isFirst) {
                require(min > prevMax, "Range collision");
            }
            _compTiers[compHash].push(Tier(min, max, alloc));

            prevMin = min;
            prevMax = max;
        }
    }

    // Calculate account allocation for competition
    function calculateAllocationForCompetition(uint256 periodId, uint16 competitionId) external {
        _calculateAllocationForCompetition(msg.sender, periodId, competitionId);
    }

    // Calculate account allocation for competition internal
    function _calculateAllocationForCompetition(address account, uint256 periodId, uint16 competitionId) internal stakeContractIsSet returns (uint32, uint32) {
        Allocation memory alloc = _allocations[msg.sender][periodId][competitionId];
        require(alloc.hasAllocation == false, "Competition allocation already calculated");

        Competition memory comp = _periodCompetitions[periodId][competitionId];
        require(comp.snapshotMin > 0 && comp.snapshotMax > 0 && comp.snapshotMin <= comp.snapshotMax, "Competition snapshot ranges is not defined");
        (uint256 average, bool _calculated) = stakingContract.getSnapshotsAverage(account, periodId, comp.snapshotMin, comp.snapshotMax);

        require(_calculated == true, "Period snapshot averages does not calculated !");

        bytes32 compHash = _competitionKey(periodId, competitionId);
        Tier[] memory tiers = _compTiers[compHash];
        Tier memory tier = Tier(0, 0, 0);
        uint tierLength = tiers.length;
        require(tierLength >= 1, "Competition tiers is not defined");

        for (uint i = 0; i < tierLength; ++i) {
            tier = tiers[i];
            alloc.hasAllocation = true;

            // Break if user has lower average for lowest tier
            if (i == 0 && (average < tier.min)) {
                alloc.bought = 0;
                alloc.max = 0;

                break;
            }

            // Find user tier range
            if (average >= tier.min && average <= tier.max) {
                alloc.bought = 0;
                alloc.max = tier.allocation;
                break;
            }
        }

        _allocations[account][periodId][competitionId] = alloc;

        return (alloc.bought, alloc.max);
    }

    // Buy ticket for a competition
    function buyTicket(uint256 periodId, uint16 competitionId, uint32 ticketCount) external paymentReceiverIsSet nonReentrant {
        require(ticketCount > 0, "Requested ticket count should be higher than zero");
        Competition memory comp = _periodCompetitions[periodId][competitionId];
        require(comp.buyActive == true, "Buy ticket is not active yet");

        if (_allocations[msg.sender][periodId][competitionId].hasAllocation == false) {
            _calculateAllocationForCompetition(msg.sender, periodId, competitionId);
        }

        Allocation memory alloc = _allocations[msg.sender][periodId][competitionId];
        require(alloc.bought < alloc.max, "There is no allocation limit left");

        uint32 buyMax = (alloc.max - alloc.bought);
        require(ticketCount <= buyMax, "Max allocation limit exceeded");

        uint ts = block.timestamp;

        CompetitionPeriod memory compPeriod = _periods[periodId];
        require(ts >= compPeriod.ticketBuyStartTime && ts <= compPeriod.ticketBuyEndTime, "Period is not in buy stage");

        uint256 paymentAmount = comp.ticketPrice * ticketCount;
        IERC20Upgradeable token_ = IERC20Upgradeable(comp.sellToken);
        uint256 allowance_ = token_.allowance(msg.sender, address(this));
        require(allowance_ >= paymentAmount, "Insufficient allowance");

        token_.safeTransferFrom(msg.sender, paymentReceiver, paymentAmount);

        // Set participation state
        _periodParticipation[msg.sender][periodId] = true;
        _allocations[msg.sender][periodId][competitionId].bought += ticketCount;
        _periodCompetitions[periodId][competitionId].ticketSold += ticketCount;

        emit TicketBuy(msg.sender, periodId, competitionId, ticketCount);
    }

    // Mint & Send ticket
    function mintTicket(uint256 periodId, uint16 competitionId, address to_, uint256 ticketId_) external onlyMinter {
        Competition memory comp = _periodCompetitions[periodId][competitionId];
        require(comp._exist == true, "Competition does not exist");
        comp.ticket.mint(to_, ticketId_);
        emit TicketSend(to_, periodId, competitionId, ticketId_);
    }

    // Mint & Send ticket batch
    function mintBatchTicket(uint256 periodId, uint16 competitionId, address to_, uint256[] calldata ticketIds) external onlyMinter {
        uint length = ticketIds.length;
        require(length > 0, "Ticket ids length should be higher than zero");

        Competition memory comp = _periodCompetitions[periodId][competitionId];
        require(comp._exist == true, "Competition does not exist");

        for (uint i = 0; i < length; ++i) {
            uint256 mintTicketId = ticketIds[i];
            comp.ticket.mint(to_, mintTicketId);
            emit TicketSend(to_, periodId, competitionId, mintTicketId);
        }
    }

    // Get total period count
    function totalPeriodCount() external view returns (uint) {
        return _currentPeriodNumber;
    }

    // Get total competition count of all periods
    function totalCompetitionCount() external view returns (uint) {
        return _totalCompetitionCount;
    }

    // Get period details
    function getPeriod(uint256 periodNum) external view returns (uint, uint, uint, uint, uint16, bool) {
        CompetitionPeriod memory period = _periods[periodNum];
        return (period.startTime, period.endTime, period.ticketBuyStartTime, period.ticketBuyEndTime, period.competitionCount, period._exist);
    }

    // Get period end time
    function getPeriodEndTime(uint256 periodNum) external view returns (uint) {
        require(_periods[periodNum]._exist == true, "There is no period exist");
        return _periods[periodNum].endTime;
    }

    // Get period competition details
    function getPeriodCompetition(uint256 periodNum, uint16 competitionNum) external view returns (Competition memory) {
        return _periodCompetitions[periodNum][competitionNum];
    }

    // Get period competition count
    function getPeriodCompetitionCount(uint256 periodNum) external view returns (uint) {
        return _periods[periodNum].competitionCount;
    }

    // Get competition ticket
    function _compTicket(uint256 periodNum, uint16 competitionNum) internal view returns (address) {
        Competition memory comp = _periodCompetitions[periodNum][competitionNum];
        require(comp._exist, "ZizyComp: Competition does not exist");
        return address(comp.ticket);
    }

    // Pause competition ticket transfers
    function pauseCompetitionTransfer(uint256 periodNum, uint16 competitionNum) external onlyOwner {
        address ticketAddr = _compTicket(periodNum, competitionNum);
        IZizyCompetitionTicket(ticketAddr).pause();
    }

    // Un-pause competition ticket transfers
    function unpauseCompetitionTransfer(uint256 periodNum, uint16 competitionNum) external onlyOwner {
        address ticketAddr = _compTicket(periodNum, competitionNum);
        IZizyCompetitionTicket(ticketAddr).unpause();
    }

    // Set competition ticket baseUri
    function setCompetitionBaseURI(uint256 periodNum, uint16 competitionNum, string memory baseUri_) external onlyOwner {
        address ticketAddr = _compTicket(periodNum, competitionNum);
        IZizyCompetitionTicket(ticketAddr).setBaseURI(baseUri_);
    }

    // Set competition description
    function setCompetitionDescription(uint256 periodNum, uint16 competitionNum, string memory description_) external onlyOwner {
        address ticketAddr = _compTicket(periodNum, competitionNum);
        IZizyCompetitionTicket(ticketAddr).setDescription(description_);
    }

    // Get total supply of competition
    function totalSupplyOfCompetition(uint256 periodNum, uint16 competitionNum) external view returns (uint256) {
        address ticketAddr = _compTicket(periodNum, competitionNum);
        return IZizyCompetitionTicket(ticketAddr).totalSupply();
    }
}