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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISalvorMini is IERC721 {
    function getRarityLevel(uint256 _tokenId) external view returns (uint256);
    function burn(uint256 _tokenId) external;
    function mint(address _receiver, uint256 _rarityLevel) external returns (uint256);
    function totalSupply() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../SalvorMini/ISalvorMini.sol";

/**
* @title VeArt
* @notice the users can simply stake and withdraw their NFTs for a specific period and earn rewards if it does not sell.
*/
contract VeArt is ERC721HolderUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // Struct to store information about User's burned Salvor Mini NFTs
    struct UserSalvorMiniBoostInfo {
        // Total number of burned Salvor Mini NFTs
        uint256 totalBurnedSalvorMiniCount;
        // Total rarity level of burned Salvor Mini NFTs
        uint256 totalRarityLevel;
    }

    // Struct to store information about a user
    struct UserInfo {
        // Amount of ART staked by the user
        uint256 amount;
        // Time of the last VeART claim, or the time of the first deposit if the user has not claimed yet
        uint256 lastRelease;
        uint256 rewardDebt;
        uint256 artRewardDebt;
        uint256 failedArtBalance;
        uint256 failedBalance;
    }

    struct DQPool {
        uint256 multiplier;
        uint256 endedAt;
        uint256 withdrawDuration;
    }

    struct DQPoolItem {
        address owner;
        uint256 endedAt;
    }

    // Struct to store information about a user
    struct UserSalvorInfo {
        // Amount of Salvor staked by the user
        uint256 amount;
        uint256 rewardDebt;
    }

    // allows the whitelisted contracts.
    EnumerableSetUpgradeable.AddressSet private _whitelistedPlatforms;

    // The constant "WAD" represents the precision level for fixed point arithmetic, set to 10^18 for 18 decimal places precision.
    uint256 public constant WAD = 10**18;

    // Multiplier used to calculate the rarity level of Salvor Mini NFTs
    uint256 public rarityLevelMultiplier;

    // Total amount of ART staked by all users  
    uint256 public totalStakedARTAmount;

    // Contract representing the ART token
    IERC20Upgradeable public art;

    // Contract representing the Salvor Mini collection
    ISalvorMini public salvorMiniCollection;

    // max veART to staked art ratio
    // Note if user has 10 art staked, they can only have a max of 10 * maxCap veART in balance
    uint256 public maxCap;

    // the rate of veART generated per second, per art staked
    uint256 public veARTgenerationRate;

    // the rate at which rewards in ART are generated
    uint256 public rewardARTGenerationRate;

    // user info mapping
    mapping(address => UserInfo) public users;

    // Stores information about a user's Salvor Mini boost
    mapping(address => UserSalvorMiniBoostInfo) public userSalvorMiniBoostInfos;

    // Balance of rewards at the last reward distribution
    uint256 public lastRewardBalance;
    // Accumulated rewards per share
    uint256 public accRewardPerShare;
    // Accumulated ART rewards per share
    uint256 public accARTPerShare;
    // Timestamp of the last reward distribution
    uint256 public lastRewardTimestamp;
    // Precision used for ART reward calculations
    uint256 public ACC_ART_REWARD_PRECISION;
    // Precision used for reward per share calculations
    uint256 public ACC_REWARD_PER_SHARE_PRECISION;


    // Balances of each address
    mapping(address => uint256) private _balances;
    // Allowances granted by each address to other addresses
	mapping(address => mapping(address => uint256)) private _allowances;
    // Total supply of the token
    uint256 private _totalSupply;
    // Name of the token
	string private _name;
    // Symbol of the token
	string private _symbol;

    mapping(address => uint256) public boostDuration;
    mapping(address => uint256) public earnedTotalBoost;
    uint256 public boostFee;
    mapping(address => uint256) public dqBoostDuration;
    mapping(address => mapping(uint256 => uint256)) public dqRarityLevels;
    mapping(address => mapping(uint256 => uint256)) public dqRarityPrices;
    mapping(address => DQPool) public dqPools;
    mapping(address => mapping(uint256 => DQPoolItem)) public dqPoolItems;
    address public admin;
    uint256 public totalSalvorSupply;
    uint256 public accSalvorRewardPerShare;
    mapping(address => UserSalvorInfo) public salvorUsers;
    mapping(uint256 => address) public salvorOwners;
    ISalvorMini public salvorCollection;
    uint256 public depositSalvorFee;

    event Deposit(address indexed user, uint256 amount);
    event DepositART(address indexed user, uint256 amount);
    event DepositSalvor(address indexed user, uint256 indexed tokenId);
    event WithdrawSalvor(address indexed user, uint256 indexed tokenId);
    event WithdrawART(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 amount);
    event ClaimSalvorReward(address indexed user, uint256 amount);
    event ClaimARTReward(address indexed user, uint256 amount);
    event ClaimedVeART(address indexed user, uint256 indexed amount);
    event MaxCapUpdated(uint256 cap);
    event ArtGenerationRateUpdated(uint256 rate);
    event Burn(address indexed account, uint256 value);
	event Mint(address indexed beneficiary, uint256 value);
    event BurnSalvorMini(address indexed user, uint256 indexed tokenId, uint256 rarityLevel);
    event WhitelistAdded(address indexed platform);
    event WhitelistRemoved(address indexed platform);
    event BoostFeeSet(uint256 boostFee);
    event DqStake(address indexed user, address indexed collection, uint256 indexed tokenId, uint256 endedAt);
    event DqWithdraw(address indexed user, address indexed collection, uint256 indexed tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IERC20Upgradeable _art) public initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC721Holder_init_unchained();
        _name = "SalvorVeArt";
		_symbol = "veART";
        veARTgenerationRate = 6415343915343;
        rewardARTGenerationRate = 77160493827160000;
        rarityLevelMultiplier = 1;
        maxCap = 100;
        art = _art;
        ACC_REWARD_PER_SHARE_PRECISION = 1e24;
        ACC_ART_REWARD_PRECISION = 1e18;
    }
    receive() external payable {}

    /**
     * @dev pause contract, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause contract, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    /**
    * @notice  allows the owner to add a contract address to the whitelist.
    * @param _whitelist The address of the contract.
    */
    function addPlatform(address _whitelist) external onlyOwner {
        require(!_whitelistedPlatforms.contains(_whitelist), "Error: already whitelisted");
        _whitelistedPlatforms.add(_whitelist);
        emit WhitelistAdded(_whitelist);
    }

    /**
    * @notice allows the owner to remove a contract address to restrict.
    * @param _whitelist The address of the contract.
    */
    function removePlatform(address _whitelist) external onlyOwner {
        require(_whitelistedPlatforms.contains(_whitelist), "Error: not whitelisted");
        _whitelistedPlatforms.remove(_whitelist);
        emit WhitelistRemoved(_whitelist);
    }

    /**
    * Sets the address of the Salvor Mini contract
    */
    function setSalvorAddress(address _salvorCollection) external onlyOwner {
        salvorCollection = ISalvorMini(_salvorCollection);
    }

    function setDQRarityLevels(address _collection, uint256[] calldata _tokenIds, uint256[] calldata _rarityLevels) external {
        require(msg.sender == owner() || msg.sender == admin, "caller is not authorized");
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            dqRarityLevels[_collection][_tokenIds[i]] = _rarityLevels[i];
        }
    }

    function setDQRarityPrices(address _collection, uint256[] calldata _rarityLevels, uint256[] calldata _prices) external onlyOwner {
        uint256 len = _rarityLevels.length;
        for (uint256 i; i < len; ++i) {
            dqRarityPrices[_collection][_rarityLevels[i]] = _prices[i];
        }
    }

    /**
	* @notice sets maxCap
    * @param _maxCap the new max ratio
    */
    function setMaxCap(uint256 _maxCap) external onlyOwner {
        maxCap = _maxCap;
        emit MaxCapUpdated(_maxCap);
    }

    /**
    * @notice Sets the reward ART generation rate
    * @param _rewardARTGenerationRate reward ART generation rate
    */
    function setARTGenerationRate(uint256 _rewardARTGenerationRate) external onlyOwner {
        _updateARTReward();
        rewardARTGenerationRate = _rewardARTGenerationRate;
        emit ArtGenerationRateUpdated(_rewardARTGenerationRate);
    }

    function setBoostFee(uint256 _boostFee) external onlyOwner {
        boostFee = _boostFee;
        emit BoostFeeSet(_boostFee);
    }

    function setDepositSalvorFee(uint256 _depositSalvorFee) external onlyOwner {
        depositSalvorFee = _depositSalvorFee;
    }

    function setDQConfiguration(address _collection, uint256 _duration, uint256 _withdrawDuration, uint256 _multiplier) external onlyOwner {
        dqPools[_collection].endedAt = block.timestamp + _duration;
        dqPools[_collection].multiplier = _multiplier;
        dqPools[_collection].withdrawDuration = _withdrawDuration;
    }

    /**
    * @notice Gets the balance of the contract
    */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
    * @notice Gets the boosted generation rate for a user
    * @param _addr The address of the user
    */
    function getBoostedGenerationRate(address _addr) external view returns (uint256) {
        if ((users[_addr].lastRelease + boostDuration[_addr]) > block.timestamp) {
            if ((users[_addr].lastRelease + dqBoostDuration[_addr]) > block.timestamp) {
                return veARTgenerationRate * 5;
            } else {
                return veARTgenerationRate * 4;
            }
        } else {
            if ((users[_addr].lastRelease + dqBoostDuration[_addr]) > block.timestamp) {
                return veARTgenerationRate * 2;
            } else {
                return veARTgenerationRate;
            }
        }
    }

    /**
    * @notice Allows a user to deposit ART tokens to earn rewards in veART
    * @param _amount The amount of ART tokens to be deposited
    */
    function depositART(uint256 _amount) external nonReentrant whenNotPaused {
        // ensures that the call is not made from a smart contract, unless it is on the whitelist.
        _assertNotContract(msg.sender);

        require(_amount > 0, "Error: Deposit amount must be greater than zero");
        require(art.balanceOf(msg.sender) >= _amount, "Error: Insufficient balance to deposit the specified amount");

        if (users[msg.sender].amount > 0) {
            // if user exists, first, claim his veART
            _harvestVeART(msg.sender);
            // then, increment his holdings
            users[msg.sender].amount += _amount;
        } else {
            // add new user to mapping
            users[msg.sender].lastRelease = block.timestamp;
            users[msg.sender].amount = _amount;
        }
        totalStakedARTAmount += _amount;

        emit DepositART(msg.sender, _amount);
        // Request art from user
        art.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
    * @notice Burns a salvormini NFT to boost VeART generation rate for the sender.
    * @param _tokenId The unique identifier of the SalvorMini NFT being burned.
    */
    function burnSalvorMiniToBoostVeART(uint256 _tokenId) external payable whenNotPaused nonReentrant {
        // ensures that the call is not made from a smart contract, unless it is on the whitelist.
        _assertNotContract(msg.sender);
        require(salvorMiniCollection.ownerOf(_tokenId) == msg.sender, "The provided NFT does not belong to the sender");

        uint256 secondsElapsed = block.timestamp - users[msg.sender].lastRelease;

        if (secondsElapsed < boostDuration[msg.sender]) {
            require(msg.value >= boostFee, "insufficient payment");
        }

        _harvestVeART(msg.sender);

        salvorMiniCollection.burn(_tokenId);

        uint256 rarityLevel = salvorMiniCollection.getRarityLevel(_tokenId);
        boostDuration[msg.sender] += rarityLevel * 3600;
        emit BurnSalvorMini(msg.sender, _tokenId, rarityLevel);
    }

    function stakeDqItems(address _collection, uint256[] calldata _tokenIds) external payable whenNotPaused nonReentrant {
        // ensures that the call is not made from a smart contract, unless it is on the whitelist.
        _assertNotContract(msg.sender);
        uint256 len = _tokenIds.length;
        uint256 price;
        require(block.timestamp < dqPools[_collection].endedAt, "The boosting pool has expired, and NFT staking is no longer allowed.");
        for (uint256 i; i < len; ++i) {
            price += dqRarityPrices[_collection][dqRarityLevels[_collection][_tokenIds[i]]];
        }
        require(msg.value >= ((100 * price * balanceOf(msg.sender)) / _totalSupply), "Insufficient payment provided for staking the NFT(s).");

        _harvestVeART(msg.sender);

        for (uint256 i; i < len; ++i) {
            require(ISalvorMini(_collection).ownerOf(_tokenIds[i]) == msg.sender, "The provided NFT does not belong to the sender");
            ISalvorMini(_collection).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            dqBoostDuration[msg.sender] += dqRarityLevels[_collection][_tokenIds[i]] * dqPools[_collection].multiplier * 1800;
            dqPoolItems[_collection][_tokenIds[i]].owner = msg.sender;
            dqPoolItems[_collection][_tokenIds[i]].endedAt = block.timestamp + dqPools[_collection].withdrawDuration;
            emit DqStake(msg.sender, _collection, _tokenIds[i], dqPoolItems[_collection][_tokenIds[i]].endedAt);
        }
    }

    function withdrawDqItems(address _collection, uint256[] calldata _tokenIds) external whenNotPaused nonReentrant {
        _assertNotContract(msg.sender);
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(dqPoolItems[_collection][_tokenIds[i]].owner == msg.sender, "The provided NFT does not belong to the sender");
            require(dqPoolItems[_collection][_tokenIds[i]].endedAt <= block.timestamp, "The provided NFT has not yet expired, and cannot be withdrawn from the boosting pool.");

            ISalvorMini(_collection).safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
            delete dqPoolItems[_collection][_tokenIds[i]];
            emit DqWithdraw(msg.sender, _collection, _tokenIds[i]);
        }
    }

    /**
    * @notice Withdraws all the ART deposit by the caller
    */
    function withdrawAllART() external nonReentrant whenNotPaused {
        require(users[msg.sender].amount > 0, "Error: amount to withdraw cannot be zero");
        require(salvorUsers[msg.sender].amount == 0, "Error: Complete the withdrawal process for your salvor NFTs before proceeding.");
        _withdrawART(msg.sender, users[msg.sender].amount);
    }

    /**
    * @dev Allows the contract owner to withdraw all ART tokens from a specific user's account in case of an emergency.
    * @param _receiver The address of the user whose ART tokens will be withdrawn.
    */
    function emergencyWithdrawAllART(address _receiver) external onlyOwner {
        require(users[_receiver].amount > 0, "Error: amount to withdraw cannot be zero");
        require(salvorUsers[msg.sender].amount == 0, "Error: Complete the withdrawal process for your salvor NFTs before proceeding.");
        _withdrawART(_receiver, users[_receiver].amount);
    }

    /**
    * @notice Allows a user to withdraw a specified amount of ART
    * @param _amount The amount of ART to withdraw
    */
    function withdrawART(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Error: amount to withdraw cannot be zero");
        require(users[msg.sender].amount >= _amount, "Error: not enough balance");
        require(salvorUsers[msg.sender].amount == 0, "Error: Complete the withdrawal process for your salvor NFTs before proceeding.");
        _withdrawART(msg.sender, _amount);
    }

    /**
    * @notice Harvests VeART rewards for the user
    * @param _receiver The address of the receiver
    */
    function harvestVeART(address _receiver) external nonReentrant whenNotPaused {
        require(users[_receiver].amount > 0, "Error: user has no stake");
        _harvestVeART(_receiver);
    }

    function withdrawSalvors(uint256[] calldata _tokenIds) external nonReentrant whenNotPaused {
        // ensures that the call is not made from a smart contract, unless it is on the whitelist.
        _assertNotContract(msg.sender);
        _withdrawSalvors(msg.sender, _tokenIds);
    }

    function emergencyWithdrawSalvors(address _receiver, uint256[] calldata _tokenIds) external onlyOwner {
        _withdrawSalvors(_receiver, _tokenIds);
    }

    /**
    * @notice This function allows the user to claim the rewards earned by their VeART holdings.
    * The rewards are calculated based on the current rewards per share and the user's VeART balance.
    * The user's reward debt is also updated to the latest rewards earned.
    * @param _receiver The address of the receiver
    */
    function _claimAllEarnings(address _receiver) internal {
        uint256 userVeARTBalance = balanceOf(_receiver);
        _updateReward();
        _updateARTReward();

        UserInfo memory user = users[_receiver];
        uint256 _pending = ((userVeARTBalance * accRewardPerShare) / ACC_REWARD_PER_SHARE_PRECISION) - user.rewardDebt;

        uint256 _pendingARTReward = ((userVeARTBalance * accARTPerShare) / ACC_ART_REWARD_PRECISION) - user.artRewardDebt;

        uint256 _pendingSalvorReward = ((salvorUsers[_receiver].amount * accSalvorRewardPerShare) / ACC_REWARD_PER_SHARE_PRECISION) - salvorUsers[_receiver].rewardDebt;

        uint256 failedBalance = users[_receiver].failedBalance;

        if (_pending > 0 || failedBalance > 0) {
            users[_receiver].rewardDebt = (userVeARTBalance * accRewardPerShare) / ACC_REWARD_PER_SHARE_PRECISION;
            emit ClaimReward(_receiver, _pending);
            _claimEarnings(_receiver, _pending);
        }
        if (_pendingSalvorReward > 0) {
            salvorUsers[_receiver].rewardDebt = (salvorUsers[_receiver].amount * accSalvorRewardPerShare) / ACC_REWARD_PER_SHARE_PRECISION;
            emit ClaimSalvorReward(_receiver, _pendingSalvorReward);
            _claimEarnings(_receiver, _pendingSalvorReward);
        }
        if (_pendingARTReward > 0) {
            users[_receiver].artRewardDebt = (userVeARTBalance * accARTPerShare) / ACC_ART_REWARD_PRECISION;
            emit ClaimARTReward(_receiver, _pendingARTReward);
            _claimARTEarnings(_receiver, _pendingARTReward);
        }
    }

    /**
    * @notice This function allows the user to claim the rewards earned by their VeART holdings.
    * The rewards are calculated based on the current rewards per share and the user's VeART balance.
    * The user's reward debt is also updated to the latest rewards earned.
    * @param _receiver The address of the receiver
    */
    function claimEarnings(address _receiver) external nonReentrant whenNotPaused {
        _claimAllEarnings(_receiver);
    }

    /**
    * @notice View function to see pending reward token
    * @param _user The address of the user
    * @return `_user`'s pending reward token
    */
    function pendingRewards(address _user) external view returns (uint256) {
        UserInfo memory user = users[_user];
        uint256 _totalVeART = _totalSupply;
        uint256 _accRewardTokenPerShare = accRewardPerShare;
        uint256 _rewardBalance = address(this).balance;

        if (_rewardBalance != lastRewardBalance && _totalVeART != 0) {
            uint256 _accruedReward = _rewardBalance - lastRewardBalance;
            if (totalSalvorSupply > 0) {
                uint256 artRewardPart = ((_accruedReward) * 8) / 10;
                _accRewardTokenPerShare += ((artRewardPart * ACC_REWARD_PER_SHARE_PRECISION) / _totalVeART);
            } else {
                _accRewardTokenPerShare += ((_accruedReward * ACC_REWARD_PER_SHARE_PRECISION) / _totalVeART);
            }
        }

        uint256 currentBalance = balanceOf(_user);
        return ((currentBalance * _accRewardTokenPerShare) / ACC_REWARD_PER_SHARE_PRECISION) - user.rewardDebt;
    }

    /**
    * @notice View function to see pending reward token
    * @param _user The address of the user
    * @return `_user`'s pending reward token
    */
    function pendingSalvorRewards(address _user) external view returns (uint256) {
        UserSalvorInfo memory user = salvorUsers[_user];
        uint256 _accRewardTokenPerShare = accSalvorRewardPerShare;
        uint256 _rewardBalance = address(this).balance;

        if (_rewardBalance != lastRewardBalance && totalSalvorSupply != 0) {
            uint256 _accruedReward = _rewardBalance - lastRewardBalance;
            uint256 artRewardPart = ((_accruedReward) * 8) / 10;
            uint256 salvorRewardPart = _accruedReward - artRewardPart;

            _accRewardTokenPerShare += ((salvorRewardPart * ACC_REWARD_PER_SHARE_PRECISION) / totalSalvorSupply);
        }
        return ((user.amount * _accRewardTokenPerShare) / ACC_REWARD_PER_SHARE_PRECISION) - user.rewardDebt;
    }

    /**
    * @notice Calculates and returns the pending art rewards for a specific user.
    * @param _user the address of the user
    */
    function pendingARTRewards(address _user) external view returns (uint256) {
        UserInfo memory user = users[_user];
        uint256 _userVeART = balanceOf(_user);
        uint256 _totalVeART = _totalSupply;
        if (_userVeART > 0) {
            uint256 secondsElapsed = block.timestamp - lastRewardTimestamp;
            uint256 artReward = secondsElapsed * rewardARTGenerationRate;
            uint256 _accARTPerShare = accARTPerShare + ((artReward * ACC_ART_REWARD_PRECISION) / _totalVeART);
            return ((_userVeART * _accARTPerShare) / ACC_ART_REWARD_PRECISION) - user.artRewardDebt;
        }
        return 0;
    }

    /**
    * @notice Calculate the amount of veART that can be claimed by user
    * @param _addr The address of the user
    * @return amount of veART that can be claimed by user
    */
    function claimableVeART(address _addr) public view returns (uint256) {
        UserInfo storage user = users[_addr];

        // get seconds elapsed since last claim
        uint256 secondsElapsed = block.timestamp - user.lastRelease;

        // calculate pending amount
        // Math.mwmul used to multiply wad numbers

        uint256 pending = _wmul(user.amount, secondsElapsed * veARTgenerationRate);
        if (secondsElapsed > boostDuration[_addr]) {
            pending += _wmul(user.amount, boostDuration[_addr] * veARTgenerationRate * 3);
        } else {
            pending += _wmul(user.amount, secondsElapsed * veARTgenerationRate * 3);
        }

        if (secondsElapsed > dqBoostDuration[_addr]) {
            pending += _wmul(user.amount, dqBoostDuration[_addr] * veARTgenerationRate * 1);
        } else {
            pending += _wmul(user.amount, secondsElapsed * veARTgenerationRate * 1);
        }

        // get user's veART balance
        uint256 userVeARTBalance = balanceOf(_addr);



        // user vePTP balance cannot go above user.amount * maxCap
        uint256 maxVeARTCap = user.amount * maxCap;

        // first, check that user hasn't reached the max limit yet
        if (userVeARTBalance < maxVeARTCap) {
            // then, check if pending amount will make user balance overpass maximum amount
            if ((userVeARTBalance + pending) > maxVeARTCap) {
                return maxVeARTCap - userVeARTBalance;
            } else {
                return pending;
            }
        }
        return 0;
    }

        /**
	 * @notice Returns the name of the token.
     */
	function name() public view returns (string memory) {
		return _name;
	}

	/**
	 * @notice Returns the symbol of the token, usually a shorter version of the name.
     */
	function symbol() public view returns (string memory) {
		return _symbol;
	}

    /**
	* @notice See {IERC20-totalSupply}.
    */
	function totalSupply() external view returns (uint256) {
		return _totalSupply;
	}

	/**
	* @notice See {IERC20-balanceOf}.
    */
	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	/**
	* @notice Returns the number of decimals used to get its user representation.
    */
	function decimals() public pure returns (uint8) {
		return 18;
	}

    function _withdrawART(address _receiver, uint256 _amount) internal {
        UserInfo memory user = users[_receiver];
        // Reset the user's last release timestamp
        users[_receiver].lastRelease = block.timestamp;

        // Update the user's ART balance by subtracting the withdrawn amount
        users[_receiver].amount = user.amount - _amount;
        // Update the total staked ART amount
        totalStakedARTAmount -= _amount;

        // Calculate the user's VEART balance that must be burned
        uint256 userVeARTBalance = balanceOf(_receiver);

        if (userVeARTBalance > 0) {
            // Update the rewards
            _updateReward();
            _updateARTReward();

            // Calculate the pending rewards and ART rewards
            uint256 _pending = ((userVeARTBalance * accRewardPerShare) / ACC_REWARD_PER_SHARE_PRECISION) - user.rewardDebt;

            uint256 _pendingARTReward = ((userVeARTBalance * accARTPerShare) / ACC_ART_REWARD_PRECISION) - user.artRewardDebt;

            // Reset the user's reward and ART reward debts
            users[_receiver].rewardDebt = 0;
            users[_receiver].artRewardDebt = 0;

            // Claim the rewards and ART rewards if there is a pending amount
            if (_pending > 0) {
                emit ClaimReward(_receiver, _pending);
                _claimEarnings(_receiver, _pending);
            }
            if (_pendingARTReward > 0) {
                emit ClaimARTReward(_receiver, _pendingARTReward);
                _claimARTEarnings(_receiver, _pendingARTReward);
            }

            // Burn the user's VEART balance
            _burn(_receiver, userVeARTBalance);
        }

        emit WithdrawART(_receiver, _amount);
        // Send the withdrawn ART back to the user
        art.safeTransfer(_receiver, _amount);
    }

    /**
    * @notice Update reward variables
    */
    function _updateReward() internal {
        uint256 _totalVeART = _totalSupply;
        uint256 _rewardBalance = address(this).balance;

        if (_rewardBalance == lastRewardBalance || _totalVeART == 0) {
            return;
        }

        uint256 _accruedReward = _rewardBalance - lastRewardBalance;

        if (totalSalvorSupply > 0) {
            uint256 artPartReward = ((_accruedReward * 8) / 10);
            uint256 salvorPartReward = _accruedReward - artPartReward;
            accRewardPerShare += ((artPartReward * ACC_REWARD_PER_SHARE_PRECISION) / _totalVeART);
            accSalvorRewardPerShare += ((salvorPartReward * ACC_REWARD_PER_SHARE_PRECISION) / totalSalvorSupply);
        } else {
            accRewardPerShare += ((_accruedReward * ACC_REWARD_PER_SHARE_PRECISION) / _totalVeART);
        }

        lastRewardBalance = _rewardBalance;
    }

    function resetSalvorParams() external {
        accSalvorRewardPerShare = 0;
    }

    /**
    * @notice Updates the accARTPerShare and lastRewardTimestamp value, which is used to calculate the rewards
    * users will earn when they harvest in the future.
    */
    function _updateARTReward() internal {
        uint256 _totalVeART = _totalSupply;
        if (block.timestamp > lastRewardTimestamp && _totalVeART > 0) {

            uint256 secondsElapsed = block.timestamp - lastRewardTimestamp;
            uint256 artReward = secondsElapsed * rewardARTGenerationRate;
            accARTPerShare += ((artReward * ACC_ART_REWARD_PRECISION) / _totalVeART);
        }
        lastRewardTimestamp = block.timestamp;
    }

    /**
    * This internal function _harvestVeART is used to allow the users to claim the VeART they are entitled to.
    * It calculates the amount of VeART that can be claimed based on the user's stake, updates the user's
    * last release time, deposits the VeART to the user's account, and mints new VeART tokens.
    *
    * @param _addr address of the user claiming VeART
    */
    function _harvestVeART(address _addr) internal {
        uint256 amount = claimableVeART(_addr);
        uint256 timeElapsed = block.timestamp - users[_addr].lastRelease;
        if (timeElapsed > boostDuration[_addr]) {
            boostDuration[_addr] = 0;
        } else {
            boostDuration[_addr] -= timeElapsed;
        }

        if (timeElapsed > dqBoostDuration[_addr]) {
            dqBoostDuration[_addr] = 0;
        } else {
            dqBoostDuration[_addr] -= timeElapsed;
        }

        // Update the user's last release time
        users[_addr].lastRelease = block.timestamp;

        // If the amount of VeART that can be claimed is greater than 0
        if (amount > 0) {
            // deposit the VeART to the user's account
            _depositVeART(_addr, amount);
            // mint new VeART tokens
            _mint(_addr, amount);
            emit ClaimedVeART(_addr, amount);
        }
    }

    function _depositVeART(address _user, uint256 _amount) internal {
        UserInfo memory user = users[_user];

        // Calculate the new balance after the deposit
        uint256 _previousAmount = balanceOf(_user);
        uint256 _newAmount = _previousAmount + _amount;

        // Update the reward variables
        _updateReward();
        _updateARTReward();

        // Calculate the reward debt for the new balance
        uint256 _previousRewardDebt = user.rewardDebt;
        users[_user].rewardDebt = (_newAmount * accRewardPerShare) / ACC_REWARD_PER_SHARE_PRECISION;

        // Calculate the art reward debt for the new balance
        uint256 _previousARTRewardDebt = user.artRewardDebt;
        users[_user].artRewardDebt = (_newAmount * accARTPerShare) / ACC_ART_REWARD_PRECISION;

        // If the user had a non-zero balance before the deposit
        if (_previousAmount != 0) {
            // Calculate the pending reward for the previous balance
            uint256 _pending = ((_previousAmount * accRewardPerShare) / ACC_REWARD_PER_SHARE_PRECISION) - _previousRewardDebt;

            // If there is a pending reward, claim it
            if (_pending != 0) {
                emit ClaimReward(_user, _pending);
                _claimEarnings(_user, _pending);
            }

            // Calculate the pending art reward for the previous balance
            uint256 _pendingARTReward = ((_previousAmount * accARTPerShare) / ACC_ART_REWARD_PRECISION) - _previousARTRewardDebt;
            // If there is a pending art reward, claim it
            if (_pendingARTReward != 0) {
                emit ClaimARTReward(_user, _pending);
                _claimARTEarnings(_user, _pendingARTReward);
            }
        }

        emit Deposit(_user, _amount);
    }

    function depositSalvors(uint256[] calldata _tokenIds) external payable nonReentrant whenNotPaused {
        uint256 len = _tokenIds.length;
        require(len <= 100, "exceeded the limits");
        require(balanceOf(msg.sender) * 200 >= _totalSupply, "Insufficient power balance.");
        // ensures that the call is not made from a smart contract, unless it is on the whitelist.
        _assertNotContract(msg.sender);
        uint256 totalSalvorAmount;
        for (uint256 i; i < len; ++i) {
            require(salvorCollection.ownerOf(_tokenIds[i]) == msg.sender, "The provided NFT does not belong to the sender");
            emit DepositSalvor(msg.sender, _tokenIds[i]);
            salvorCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
            salvorOwners[_tokenIds[i]] = msg.sender;
            totalSalvorAmount += dqRarityLevels[address(salvorCollection)][_tokenIds[i]];
        }
        if (balanceOf(msg.sender) * 100 <= _totalSupply) {
            require(msg.value >= (depositSalvorFee * len), "Insufficient payment provided to deposit.");
        } else {
            require(msg.value >= ((depositSalvorFee * len) / ((
                100 * balanceOf(msg.sender)) / _totalSupply)), "Insufficient payment provided to deposit.");
        }

        UserSalvorInfo memory user = salvorUsers[msg.sender];

        // Calculate the new balance after the deposit
        uint256 _previousAmount = user.amount;
        uint256 _newAmount = _previousAmount + totalSalvorAmount;

        // Update the reward variables
        _updateReward();


        // Calculate the reward debt for the new balance
        uint256 _previousRewardDebt = user.rewardDebt;
        salvorUsers[msg.sender].rewardDebt = (_newAmount * accSalvorRewardPerShare) / ACC_REWARD_PER_SHARE_PRECISION;


        // If the user had a non-zero balance before the deposit
        if (_previousAmount != 0) {
            // Calculate the pending reward for the previous balance
            uint256 _pending = ((_previousAmount * accSalvorRewardPerShare) / ACC_REWARD_PER_SHARE_PRECISION) - _previousRewardDebt;

            // If there is a pending reward, claim it
            if (_pending != 0) {
                emit ClaimSalvorReward(msg.sender, _pending);
                _claimEarnings(msg.sender, _pending);
            }
        }
        salvorUsers[msg.sender].amount += totalSalvorAmount;
        totalSalvorSupply += totalSalvorAmount;
    }

    function _withdrawSalvors(address _receiver, uint256[] memory _tokenIds) internal {
        uint256 len = _tokenIds.length;
        UserSalvorInfo memory user = salvorUsers[_receiver];
        uint256 totalSalvorAmount;
        for (uint256 i; i < len; ++i) {
            require(salvorOwners[_tokenIds[i]] == _receiver, "The provided NFT does not belong to the sender");
            emit WithdrawSalvor(_receiver, _tokenIds[i]);
            salvorCollection.transferFrom(address(this), _receiver, _tokenIds[i]);
            totalSalvorAmount += dqRarityLevels[address(salvorCollection)][_tokenIds[i]];
            delete salvorOwners[_tokenIds[i]];
        }

        // Calculate the new balance after the deposit
        uint256 _previousAmount = user.amount;
        uint256 _newAmount = _previousAmount - totalSalvorAmount;

        // Update the reward variables
        _updateReward();

        uint256 _previousRewardDebt = user.rewardDebt;
        salvorUsers[_receiver].rewardDebt = (_newAmount * accSalvorRewardPerShare) / ACC_REWARD_PER_SHARE_PRECISION;

        uint256 _pending = ((_previousAmount * accSalvorRewardPerShare) / ACC_REWARD_PER_SHARE_PRECISION) - _previousRewardDebt;

        // If there is a pending reward, claim it
        if (_pending != 0) {
            emit ClaimSalvorReward(_receiver, _pending);
            _claimEarnings(_receiver, _pending);
        }

        salvorUsers[_receiver].amount -= totalSalvorAmount;
        totalSalvorSupply -= totalSalvorAmount;
    }

    /**
    * @notice Transfers a specified amount of Ethers from the contract to a user.
    * @dev If the specified amount is greater than the contract's Ether balance,
    * the remaining balance will be stored as failedBalance for the user, to be sent in future transactions.
    * @param _receiver The address of the recipient of the ART tokens.
    * @param _amount The amount of Ethers to be transferred.
    */
    function _claimEarnings(address _receiver, uint256 _amount) internal {
        address payable to = payable(_receiver);

        // get the current balance of the reward contract
        uint256 _rewardBalance = address(this).balance;
        _amount += users[_receiver].failedBalance;

        // check if the amount to be claimed is greater than the reward balance
        if (_amount > _rewardBalance) {
            // if yes, deduct the entire reward balance from the lastRewardBalance and transfer it to the user
            lastRewardBalance -= _rewardBalance;

            users[_receiver].failedBalance = _amount - _rewardBalance;

            if (_rewardBalance > 0) {
                (bool success, ) = to.call{value: _rewardBalance}("");
                require(success, "claim earning is failed");
            }
        } else {
            // if not, deduct the amount to be claimed from the lastRewardBalance and transfer it to the user
            lastRewardBalance -= _amount;
            users[_receiver].failedBalance = 0;
            (bool success, ) = to.call{value: _amount}("");
            require(success, "claim earning is failed");
        }
    }

    /**
    * @notice Transfers a specified amount of ART tokens from the contract to a user.
    * @dev If the specified amount is greater than the contract's ART balance,
    * the remaining balance will be stored as failedArtBalance for the user, to be sent in future transactions.
    * @param _receiver The address of the recipient of the ART tokens.
    * @param _amount The amount of ART tokens to be transferred.
    */
    function _claimARTEarnings(address _receiver, uint256 _amount) internal {
        uint256 _totalBalance = art.balanceOf(address(this)) - totalStakedARTAmount;
        _amount += users[_receiver].failedArtBalance;
        if (_amount > _totalBalance) {
            users[_receiver].failedArtBalance = _amount - _totalBalance;
            if (_totalBalance > 0) {
                art.safeTransfer(_receiver, _totalBalance);
            }
        } else {
            users[_receiver].failedArtBalance = 0;
            art.safeTransfer(_receiver, _amount);
        }
    }

    /**
    * @notice This function asserts that the address provided in the parameter is not a smart contract. 
    * If it is a smart contract, it verifies that it is included in the list of approved platforms.
    * @param _addr the address to be checked
    */
    function _assertNotContract(address _addr) private view {
        if (_addr != tx.origin) {
            require(_whitelistedPlatforms.contains(_addr), 'Error: Unauthorized smart contract access');
        }
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
	function _mint(address account, uint256 amount) internal {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply += amount;
		_balances[account] += amount;
		emit Mint(account, amount);

		_afterTokenOperation(account, _balances[account]);
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
	function _burn(address account, uint256 amount) internal {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		uint256 accountBalance = _balances[account];
		require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
		unchecked {
			_balances[account] = accountBalance - amount;
		}
		_totalSupply -= amount;

		emit Burn(account, amount);

		_afterTokenOperation(account, _balances[account]);
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
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal {}

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
	function _afterTokenOperation(address account, uint256 newBalance) internal {}

    /**
    * performs a rounded multiplication of two uint256 values `x` and `y` 
    * by first multiplying them and then adding `WAD / 2` to the result before dividing by `WAD`.
    * The `WAD` constant is used as a divisor to control the precision of the result. 
    * The final result is rounded to the nearest integer towards zero,
    * if the result is exactly halfway between two integers it will be rounded to the nearest integer towards zero.
    */
    function _wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }
}