// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract Configurable {
    /// @dev Dictionary of all global configs of the staking protocol.
    mapping(bytes32 => uint256) private _config;

    /**
     * @dev Emitted when the global config `key` has been set to `value`.
     */
    event SetGlobalConfig(bytes32 indexed key, uint256 value);

    /**
     * @notice Get the current value of the global config `key`.
     * @param key id of the configuration
     */
    function getConfig(bytes32 key) public view returns (uint256) {
        return _config[key];
    }

    /**
     * @dev Set the value of the global config `key`.
     * @param key id of the configuration
     * @param value new value of the configuration
     */
    function _setConfig(bytes32 key, uint256 value) internal {
        _config[key] = value;

        emit SetGlobalConfig(key, value);
    }

    /**
     * @dev Empty reserved space to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract StakingConstants {
    /* Access roles */

    /// @dev Owner role of the contract and admin over all existing access-roles.
    bytes32 internal constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @dev Access-role used for pausing/unpausing the contract.
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev Access-role used to finalize pools with off-chain node performances.
    bytes32 internal constant FINALIZER_ROLE = keccak256("FINALIZER_ROLE");

    /// @dev Access-role used to explicitly jail pools.
    bytes32 internal constant JAILER_ROLE = keccak256("JAILER_ROLE");

    /* Configuration keys */

    /// @dev Minimum duration of a staking epoch in seconds.
    bytes32 internal constant MIN_EPOCH_DURATION_SECS = "MIN_EPOCH_DURATION_SECS";

    /// @dev Staking APY for the capped earning stake of a pool. It represents
    /// the maximum APY a pool can produce over its entire stake.
    bytes32 internal constant POOL_EARNING_STAKE_APY = "POOL_EARNING_STAKE_APY";

    /// @dev Minimum stake to create a new pool.
    bytes32 internal constant MIN_POOL_OWNER_STAKE = "MIN_POOL_OWNER_STAKE";

    /// @dev Minimum stake to create a new delegation.
    bytes32 internal constant MIN_DELEGATOR_STAKE = "MIN_DELEGATOR_STAKE";

    /// @dev Saturation threshold for the earning stake within a pool.
    bytes32 internal constant POOL_SATURATION_CAP = "POOL_SATURATION_CAP";

    /// @dev Influence of owner's stake when computing the earning stake of a pool.
    bytes32 internal constant OWNER_STAKE_INFLUENCE_NUM = "OWNER_STAKE_INFLUENCE_NUM";
    bytes32 internal constant OWNER_STAKE_INFLUENCE_DEN = "OWNER_STAKE_INFLUENCE_DEN";

    /// @dev Locking applied to a stake withdrawal before it can be executed.
    bytes32 internal constant WITHDRAWAL_LOCK_TIME = "WITHDRAWAL_LOCK_TIME";

    /// @dev Epochs to pass before changing a pool`s commission fee again.
    bytes32 internal constant POOL_COMMISSION_FEE_COOLDOWN = "POOL_COMMISSION_FEE_COOLDOWN";

    /// @dev Fee to be paid in main token to unjail a pool.
    bytes32 internal constant POOL_UNJAILING_FEE = "POOL_UNJAILING_FEE";

    /* Constants */

    /// @dev Scaling factor for percentages of double digit precision: 22.85% is represented as 2285
    uint16 internal constant PERCENTAGE_SCALING_FACTOR = 10_000;

    /// @dev Maximum base APY granted to an owner at its pool finalization.
    uint16 internal constant MAX_OWNER_BASE_APY = 1_000;

    /// @dev Minimum pool commission fee allowed.
    uint16 internal constant MIN_POOL_COMMISSION_FEE = 200;

    /// @dev Fixed decimals enforced over all tokens supported for staking.
    uint8 internal constant STRICT_TOKEN_DECIMALS = 18;

    /// @dev Scaling factor for fractions of token amounts.
    uint256 internal constant TOKEN_FRACTION_SCALING_FACTOR = 10 ** STRICT_TOKEN_DECIMALS;

    /// @dev Number of seconds within a year.
    uint256 internal constant ONE_YEAR_SECS = 365 days;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../rewards/DelegatorRewardsAdapter.sol";

abstract contract DelegationsAdapter is DelegatorRewardsAdapter {
    /**
     * @dev Validates a set of currencies.
     * Reverts if: the supplied currencies list is empty or unsorted or contains duplicates or zero amounts.
     */
    function validateCurrencies(Currency[] memory currencies) private pure {
        require(currencies.length != 0, "E402");
        address previousCurrency;
        for (uint256 it; it < currencies.length; ++it) {
            require(currencies[it].amount != 0, "E403");
            require(address(currencies[it].erc20) > previousCurrency, "E404");
            previousCurrency = address(currencies[it].erc20);
        }
    }

    /**
     * @dev Update individual currencies within a delegation.
     * Reverts if: delegator does not have enough balance of a currency to remove from.
     * @param poolId id of the pool
     * @param delegator delegator address
     * @param currencies delta amounts of each currency
     * @param increaseBalance whether stake is added or removed
     * @return balanceChange total currency-agnostic change of delegation's balance
     */
    function _updateDelegationCurrencies(
        bytes32 poolId,
        address delegator,
        Currency[] memory currencies,
        bool increaseBalance
    ) private returns (uint256 balanceChange) {
        Delegation storage delegation = _poolsArchive[poolId].delegations[delegator];
        for (uint256 it; it < currencies.length; ++it) {
            Currency memory currency = currencies[it];
            if (increaseBalance) {
                delegation.currencies[currency.erc20] += currency.amount;
            } else {
                require(delegation.currencies[currency.erc20] >= currency.amount, "E106");
                delegation.currencies[currency.erc20] -= currency.amount;
            }
            balanceChange += currency.amount;
        }
    }

    function _updateDeferredDeposit(
        DeferredDeposit storage depositPtr,
        uint256 balanceChange,
        bool increaseBalance
    ) private returns (uint256 newBalance) {
        newBalance = increaseBalance
            ? _increaseNextBalance(depositPtr, balanceChange)
            : _decreaseNextBalance(depositPtr, balanceChange);
    }

    /**
     * @dev Update a delegation's internal balances.
     * @param poolId id of the pool
     * @param delegator delegator address
     * @param currencies delta amounts of each currency
     * @param increaseBalance whether stake is added or removed
     */
    function _updateDelegation(
        bytes32 poolId,
        address delegator,
        Currency[] memory currencies,
        bool increaseBalance
    ) private {
        // pool owner should have been set already
        assert(poolExists(poolId));

        // collect in-flight delegator rewards produced under the old balance
        _collectDelegatorRewards(delegator, poolId);

        uint256 balanceChange = _updateDelegationCurrencies(poolId, delegator, currencies, increaseBalance);

        // update the deferred balance of the delegation
        uint256 newBalance = _updateDeferredDeposit(
            _poolsArchive[poolId].delegations[delegator].deposited,
            balanceChange,
            increaseBalance
        );

        // check minimum stake is preserved in either owner or delegator scenario
        require(
            (newBalance == 0) ||
                (newBalance >= getConfig(isPoolOwner(delegator, poolId) ? MIN_POOL_OWNER_STAKE : MIN_DELEGATOR_STAKE)),
            "E103"
        );

        // update the deferred balance of the pool
        _updateDeferredDeposit(_poolsArchive[poolId].meta.deposited, balanceChange, increaseBalance);
    }

    /**
     * @dev Initialize pool's owner(create the pool) by adding its initial stake.
     * Reverts if: the pool has already been created.
     * Postcondition: pool's owner is not null and it owns non-zero stake.
     * @param poolId id of the new pool
     * @param owner owner of the new pool
     * @param currencies amounts of each currency to add as initial stake
     */
    function _initializePoolOwner(bytes32 poolId, address owner, Currency[] calldata currencies) internal {
        validateCurrencies(currencies);
        require(!poolExists(poolId), "E100");

        _poolsArchive[poolId].meta.owner = owner;
        _updateDelegation(poolId, owner, currencies, true);

        _markPoolAsCreated(poolId);

        assert(poolOperative(poolId));
    }

    /**
     * @dev Add stake to a delegation's internal balances.
     * Reverts if: the pool is not operative (has never been created or is terminated).
     * Postcondition: pool remains operative.
     * @param poolId id of the pool
     * @param delegator delegator address
     * @param currencies amounts of each currency to add
     */
    function _stake(bytes32 poolId, address delegator, Currency[] memory currencies) internal {
        validateCurrencies(currencies);
        require(poolOperative(poolId), "E104");
        // regular delegators can only stake main token
        require(
            (currencies.length == 1 && currencies[0].erc20 == rewardsToken()) || isPoolOwner(delegator, poolId),
            "E105"
        );

        _updateDelegation(poolId, delegator, currencies, true);

        assert(poolOperative(poolId));
    }

    /**
     * @dev Remove stake from a delegation's internal balances.
     * If owner removes its entire balance, the pool is terminated.
     * Reverts if: the pool has never been created.
     * Postcondition: pool still exists even if it has been terminated.
     * @param poolId id of the pool
     * @param delegator delegator address
     * @param currencies amounts of each currency to remove
     */
    function _unstake(bytes32 poolId, address delegator, Currency[] calldata currencies) internal {
        validateCurrencies(currencies);
        require(poolExists(poolId), "E115");

        bool poolOperativePreviously = poolOperative(poolId);
        _updateDelegation(poolId, delegator, currencies, false);

        if (poolOperativePreviously && !poolOperative(poolId)) {
            _markPoolAsTerminated(poolId);
        }

        assert(poolExists(poolId));
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "../epochs/StakingEpochManager.sol";

abstract contract DepositsAdapter is StakingEpochManager {
    /**
     * @dev Tokens deposit postponing updates to the next epoch relative to the one when updated.
     * If `currentEpoch` < global current epoch then the deposit was stalled for
     * some epoch(s) already and its observed balance should be `nextEpochBalance` now.
     * Invariant: `nextEpochBalance` is the actual amount of tokens attached to this deposit.
     * @param currentEpoch last epoch when updated
     * @param previousEpochBalance balance at the epoch before `currentEpoch`
     * @param currentEpochBalance balance at epoch `currentEpoch`
     * @param nextEpochBalance balance after epoch `currentEpoch`
     */
    struct DeferredDeposit {
        uint128 previousEpochBalance;
        uint128 currentEpochBalance;
        // pack `currentEpoch` and `nextEpochBalance` together as deposits are often stalled
        uint128 nextEpochBalance;
        uint64 currentEpoch;
    }

    /**
     * @dev Loads a deposit with all its postponed updates applied for current-epoch view.
     * Pass in a storage pointer rather than a memory object to ensure immutability.
     * @param depositPtr storage pointer to deposit
     */
    function _loadDeposit(DeferredDeposit storage depositPtr) internal view returns (DeferredDeposit memory) {
        DeferredDeposit memory deposit = depositPtr;
        uint64 currentEpoch = currentEpoch();
        if (deposit.currentEpoch < currentEpoch) {
            deposit.previousEpochBalance = deposit.currentEpoch < currentEpoch - 1
                ? deposit.nextEpochBalance
                : deposit.currentEpochBalance;
            deposit.currentEpochBalance = deposit.nextEpochBalance;
            deposit.currentEpoch = currentEpoch;
        }
        return deposit;
    }

    /**
     * @dev Get balance of a deposit at the previous epoch.
     * Optimized version of `_loadDeposit` for accessing `previousEpochBalance` only.
     * @param depositPtr storage pointer to deposit
     */
    function _previousEpochBalance(DeferredDeposit storage depositPtr) internal view returns (uint256) {
        uint64 currentEpoch = currentEpoch();
        uint64 depositEpoch = depositPtr.currentEpoch;
        if (depositEpoch < currentEpoch - 1) {
            return depositPtr.nextEpochBalance;
        } else if (depositEpoch < currentEpoch) {
            return depositPtr.currentEpochBalance;
        } else {
            return depositPtr.previousEpochBalance;
        }
    }

    /**
     * @dev Override a deferred deposit with another one.
     * @param depositPtr storage pointer to deposit to override
     * @param deposit deposit object to update to
     */
    function _storeDeposit(DeferredDeposit storage depositPtr, DeferredDeposit memory deposit) private {
        depositPtr.previousEpochBalance = deposit.previousEpochBalance;
        depositPtr.currentEpochBalance = deposit.currentEpochBalance;
        depositPtr.nextEpochBalance = deposit.nextEpochBalance;
        depositPtr.currentEpoch = deposit.currentEpoch;
    }

    /**
     * @dev Increments next epoch's balance.
     * @param depositPtr storage pointer to deposit to update
     * @param amount amount to increment by
     */
    function _increaseNextBalance(DeferredDeposit storage depositPtr, uint256 amount) internal returns (uint256) {
        DeferredDeposit memory deposit = _loadDeposit(depositPtr);
        deposit.nextEpochBalance += SafeCastUpgradeable.toUint128(amount);

        _storeDeposit(depositPtr, deposit);
        return deposit.nextEpochBalance;
    }

    /**
     * @dev Decrements next epoch's balance.
     * @param depositPtr storage pointer to deposit to update
     * @param amount amount to decrement by
     */
    function _decreaseNextBalance(DeferredDeposit storage depositPtr, uint256 amount) internal returns (uint256) {
        DeferredDeposit memory deposit = _loadDeposit(depositPtr);
        deposit.nextEpochBalance -= SafeCastUpgradeable.toUint128(amount);

        _storeDeposit(depositPtr, deposit);
        return deposit.nextEpochBalance;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../config/StakingConstants.sol";
import "../StakingStorage.sol";

abstract contract TransfersAdapter is StakingConstants {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Possible states of a currency token used in the staking protocol.
     */
    enum CurrencySupport {
        // is not stake nor withdraw capable
        INEXISTENT,
        // is both stake and withdraw capable
        OPERATIVE,
        // is only withdraw capable
        DEPRECATED
    }

    /// @dev Support level for ERC20 tokens.
    mapping(IERC20Upgradeable => CurrencySupport) private _currencySupport;

    /**
     * @dev Emitted when the support level of token `erc20` is set to `state`.
     */
    event SetCurrencySupport(IERC20Upgradeable indexed erc20, CurrencySupport indexed state);

    /**
     * @notice Returns the support level for a given token.
     */
    function currencySupport(IERC20Upgradeable erc20) external view returns (CurrencySupport) {
        return _currencySupport[erc20];
    }

    /**
     * @dev Configure the support level for an ERC20 token.
     * @param erc20 token address
     * @param state new support level
     */
    function _setCurrencySupport(IERC20Upgradeable erc20, CurrencySupport state) internal {
        require(IERC20MetadataUpgradeable(address(erc20)).decimals() == STRICT_TOKEN_DECIMALS, "E200");
        _currencySupport[erc20] = state;

        emit SetCurrencySupport(erc20, state);
    }

    /**
     * @dev Transfer some amount of a given token to an account.
     * Reverts if the supplied token is not withdraw-capable.
     * @param account address to transfer to
     * @param erc20 token to transfer
     * @param amount amount of tokens
     */
    function _strictTransferTo(address account, IERC20Upgradeable erc20, uint256 amount) internal {
        CurrencySupport state = _currencySupport[erc20];
        require(state == CurrencySupport.OPERATIVE || state == CurrencySupport.DEPRECATED, "E405");
        if (amount != 0) {
            erc20.safeTransfer(account, amount);
        }
    }

    /**
     * @dev Transfer some amount of a given token from an account.
     * Reverts if the supplied token is not stake-capable.
     * @param account address to transfer from
     * @param erc20 token to transfer
     * @param amount amount of tokens
     */
    function _strictTransferFrom(address account, IERC20Upgradeable erc20, uint256 amount) internal {
        CurrencySupport state = _currencySupport[erc20];
        require(state == CurrencySupport.OPERATIVE, "E406");

        uint256 previousBalance = erc20.balanceOf(address(this));
        erc20.safeTransferFrom(account, address(this), amount);

        require(erc20.balanceOf(address(this)) == previousBalance + amount, "E408");
    }

    /**
     * @dev Transfer multiple amounts of given tokens from an account.
     * @param account address to transfer from
     * @param currencies tokens to transfer and individual amounts
     */
    function _strictTransferFrom(address account, StakingStorage.Currency[] calldata currencies) internal {
        for (uint256 it; it < currencies.length; ++it) {
            _strictTransferFrom(account, currencies[it].erc20, currencies[it].amount);
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../config/Configurable.sol";
import "../config/StakingConstants.sol";

abstract contract StakingEpochManager is Initializable, Configurable, StakingConstants {
    using { MathUpgradeable.max } for uint256;

    /// @dev Index of the current staking epoch.
    uint64 private _currentEpoch;

    /// @dev Starting timestamp of the current epoch.
    uint256 private _currentEpochStartTimestamp;

    /// @dev Total duration of the previous epoch in seconds.
    uint256 private _previousEpochDuration;

    /**
     * @dev Emitted when the current epoch is ended.
     */
    event EndEpoch();

    /**
     * @dev Start the first epoch and initialize minimum epoch duration.
     */
    function __StakingEpochManager_init_unchained(uint256 minEpochDuration) internal onlyInitializing {
        _setConfig(MIN_EPOCH_DURATION_SECS, minEpochDuration);

        _currentEpochStartTimestamp = block.timestamp;
        _currentEpoch = 1;
    }

    /**
     * @notice Returns the index of the current staking epoch.
     */
    function currentEpoch() public view returns (uint64) {
        return _currentEpoch;
    }

    /**
     * @notice Returns starting timestamp of the current epoch.
     */
    function currentEpochStartTimestamp() public view returns (uint256) {
        return _currentEpochStartTimestamp;
    }

    /**
     * @notice Returns total duration of the previous epoch in seconds.
     */
    function previousEpochDuration() public view returns (uint256) {
        return _previousEpochDuration;
    }

    /**
     * @notice Returns the earliest end timestamp of the current epoch.
     */
    function getEpochEarliestEndTime() public view returns (uint256) {
        // enforce that cannot end more than one epoch per second
        return block.timestamp.max(_currentEpochStartTimestamp + getConfig(MIN_EPOCH_DURATION_SECS).max(1));
    }

    /**
     * @dev Move to the next epoch if enough time has passed.
     */
    function _endEpoch() internal {
        require(block.timestamp >= getEpochEarliestEndTime(), "E301");
        _previousEpochDuration = block.timestamp - _currentEpochStartTimestamp;
        _currentEpochStartTimestamp = block.timestamp;
        _currentEpoch++;

        emit EndEpoch();
    }

    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Finalizer.sol";

abstract contract DelegatorRewardsAdapter is Finalizer {
    /**
     * @dev Emitted when in-flight `rewards` of a delegation are collected up to the previous epoch exclusively.
     */
    event CollectDelegatorRewards(address indexed delegator, bytes32 indexed poolId, uint256 rewards);

    /**
     * @dev Get cumulative rewards produced by a pool up to the supplied epoch.
     * Expects that a pool is finalized sequentially since creation until being terminated,
     * otherwise would have to save the epoch of its last finalization.
     * @param poolId id of the pool
     * @param epoch epoch index
     */
    function _getCumulativeRewardAtEpoch(bytes32 poolId, uint256 epoch) private view returns (uint256) {
        // going backwards, check if pool has been finalized at `epoch`
        CumulativeReward memory cumulativeReward = poolCumulativeReward(poolId, epoch);
        if (cumulativeReward.finalized) {
            return cumulativeReward.value;
        }

        // else pool might have been finalized at `epoch` - 1
        cumulativeReward = poolCumulativeReward(poolId, epoch - 1);
        if (cumulativeReward.finalized) {
            return cumulativeReward.value;
        }

        // else pool might have been terminated some epochs before `epoch`
        uint256 lastFinalizationEpoch = lastCumulativeReward(poolId);
        // check that pool has been terminated indeed and this happened before `epoch`
        if (lastFinalizationEpoch != 0 && lastFinalizationEpoch < epoch) {
            cumulativeReward = poolCumulativeReward(poolId, lastFinalizationEpoch);
            if (cumulativeReward.finalized) {
                return cumulativeReward.value;
            }
        }

        // else pool has never been operative by `epoch`
        return 0;
    }

    /**
     * @dev Compute a delegation's rewards over an interval of epochs where its balance is constant.
     * @param poolId id of the pool
     * @param balanceOverInterval delegation's constant balance over the interval
     * @param beginEpoch start epoch (inclusive)
     * @param endEpoch end epoch (exclusive)
     */
    function _computeDelegatorRewardOverInterval(
        bytes32 poolId,
        uint256 balanceOverInterval,
        uint64 beginEpoch,
        uint64 endEpoch
    ) private view returns (uint256 rewards) {
        // skip computation when no rewards produced
        if (balanceOverInterval == 0 || beginEpoch == endEpoch) {
            return 0;
        }
        // sanity check interval
        assert(beginEpoch < endEpoch);

        // a delegator's rewards are proportional to its stake within the pool
        rewards = _getCumulativeRewardAtEpoch(poolId, endEpoch) - _getCumulativeRewardAtEpoch(poolId, beginEpoch);
        rewards = (rewards * balanceOverInterval) / TOKEN_FRACTION_SCALING_FACTOR;
    }

    /**
     * @dev Compute a delegation's rewards produced since last time when collected.
     * The rewards of previous epoch may not be finalized yet so they are omitted and
     * can be collected next epoch when they should be already finalized.
     * @param delegator delegator address
     * @param poolId id of the pool
     */
    function _computeDelegatorReward(address delegator, bytes32 poolId) private view returns (uint256 rewards) {
        DeferredDeposit memory delegation = _poolsArchive[poolId].delegations[delegator].deposited;
        // delegation did not exists before so it has no rewards
        if (delegation.currentEpoch == 0) {
            return 0;
        }

        uint64 currentEpoch = currentEpoch();
        if (delegation.currentEpoch == currentEpoch) {
            // certainly finalized rewards have been collected already
            return 0;
        }

        // rewards earned under `previousEpochBalance` stake but not finalized then
        rewards = _computeDelegatorRewardOverInterval(
            poolId,
            delegation.previousEpochBalance,
            delegation.currentEpoch - 1,
            delegation.currentEpoch
        );

        if (delegation.currentEpoch == currentEpoch - 1) {
            // collected only delegation's previous rewards as the following ones are not certainly finalized
            return rewards;
        }

        // rewards earned under `currentEpochBalance` stake
        rewards += _computeDelegatorRewardOverInterval(
            poolId,
            delegation.currentEpochBalance,
            delegation.currentEpoch,
            delegation.currentEpoch + 1
        );

        // rewards earned under `nextEpochBalance` stake
        rewards += _computeDelegatorRewardOverInterval(
            poolId,
            delegation.nextEpochBalance,
            delegation.currentEpoch + 1,
            // previous epoch rewards are purposely regarded as not finalized
            currentEpoch - 1
        );
    }

    /**
     * @dev Collect a delegation's in-flight rewards produced since last time when collected.
     * @param delegator delegator address
     * @param poolId id of the pool
     */
    function _collectDelegatorRewards(address delegator, bytes32 poolId) internal {
        uint256 rewards = _computeDelegatorReward(delegator, poolId);
        _unclaimedRewards[delegator] += rewards;

        // shift delegation to current epoch to mark that its rewards are collected (excepting ones from previous epoch)
        _decreaseNextBalance(_poolsArchive[poolId].delegations[delegator].deposited, 0);

        emit CollectDelegatorRewards(delegator, poolId, rewards);
    }

    /**
     * @dev Collect in-flight rewards of an account over a set of its delegations.
     * @param delegator delegator address
     * @param poolIds list of pools to collect in-flight rewards from
     */
    function _collectDelegatorRewardsMany(address delegator, bytes32[] calldata poolIds) internal {
        for (uint256 it; it < poolIds.length; ++it) {
            _collectDelegatorRewards(delegator, poolIds[it]);
        }
    }

    /**
     * @notice Compute in-flight rewards of an account over a set of its delegations.
     * @param delegator delegator address
     * @param poolIds list of pools to compute in-flight rewards from
     */
    function computeDelegatorReward(
        address delegator,
        bytes32[] calldata poolIds
    ) external view returns (uint256 rewards) {
        for (uint256 it; it < poolIds.length; ++it) {
            rewards += _computeDelegatorReward(delegator, poolIds[it]);
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../StakingStorage.sol";

abstract contract Finalizer is StakingStorage, AccessControlUpgradeable, PausableUpgradeable {
    /// @dev Cumulative reward produced by a pool up to an epoch.
    /// This is the sum of ratios of rewards to stake at each epoch since creation.
    mapping(bytes32 => mapping(uint256 => CumulativeReward)) private _poolCumulativeReward;

    /// @dev Last epoch when a pool that has been terminated is finalized.
    mapping(bytes32 => uint256) private _lastCumulativeReward;

    /// @dev Number of pools to be finalized for previous, current and next epoch.
    uint256 private _poolsToFinalizePreviousEpoch;
    uint256 private _poolsToFinalizeCurrentEpoch;
    uint256 private _poolsToFinalizeNextEpoch;

    /// @dev Total rewards collected by an account from its pools and delegations.
    mapping(address => uint256) internal _unclaimedRewards;

    struct CumulativeReward {
        bool finalized;
        uint248 value;
    }

    /**
     * @dev Emitted when `poolId` has been finalized for the previous epoch.
     */
    event FinalizedPool(
        bytes32 indexed poolId,
        uint16 performance,
        uint16 ownerBaseApy,
        CumulativeReward cumulativeReward,
        uint256 poolReward,
        uint256 baseReward
    );

    /**
     * @dev Modifier to make a function callable only when there are no outstanding
     * pool finalizations (previous epoch has been fully finalized).
     */
    modifier whenNotFinalizing() {
        require(_poolsToFinalizePreviousEpoch == 0, "E300");
        _;
    }

    /**
     * @notice Returns cumulative reward produced by a pool up to an epoch
     * and whether the pool has been finalized at that epoch.
     */
    function poolCumulativeReward(bytes32 poolId, uint256 epoch) public view returns (CumulativeReward memory) {
        return _poolCumulativeReward[poolId][epoch];
    }

    /**
     * @notice Returns last epoch when a pool that has been terminated is finalized.
     */
    function lastCumulativeReward(bytes32 poolId) public view returns (uint256) {
        return _lastCumulativeReward[poolId];
    }

    /**
     * @notice Returns number of pools to be finalized for previous, current and next epoch.
     */
    function poolsToFinalize() external view returns (uint256, uint256, uint256) {
        return (_poolsToFinalizePreviousEpoch, _poolsToFinalizeCurrentEpoch, _poolsToFinalizeNextEpoch);
    }

    /**
     * @notice Returns total rewards collected by an account.
     */
    function unclaimedRewards(address account) public view returns (uint256 rewards) {
        rewards = _unclaimedRewards[account];
        // ensure rewards accumulator never goes free by reporting less available rewards
        if (rewards != 0) {
            rewards -= 1;
        }
    }

    /**
     * @dev Add to the finalization accounting a newly created pool.
     */
    function _markPoolAsCreated(bytes32) internal {
        // pool requires finalization for next epoch onwards
        _poolsToFinalizeNextEpoch++;
    }

    /**
     * @dev Remove from the finalization accounting a pool that has been terminated.
     * Expects that the pool has not been terminated before.
     * @param poolId id of the pool
     */
    function _markPoolAsTerminated(bytes32 poolId) internal {
        // pool does not require finalization for next epoch onwards
        _poolsToFinalizeNextEpoch--;
        // remember last epoch when this pool will ever be finalized
        _lastCumulativeReward[poolId] = currentEpoch() + 1;
    }

    /**
     * @notice End the current epoch and enter its pool-finalization phase.
     */
    function endEpoch() external whenNotPaused whenNotFinalizing {
        // validate configuration before enabling pool finalizations
        require(getConfig(POOL_SATURATION_CAP) != 0, "E201");
        require(getConfig(OWNER_STAKE_INFLUENCE_DEN) != 0, "E202");

        _endEpoch();

        _poolsToFinalizePreviousEpoch = _poolsToFinalizeCurrentEpoch;
        _poolsToFinalizeCurrentEpoch = _poolsToFinalizeNextEpoch;
    }

    /**
     * @notice Finalize pools operative during the previous epoch.
     * @param poolIds list of pools to finalize
     * @param performances list of node performances
     * @param ownersBaseApy list of base APYs for their owners
     */
    function finalizePools(
        bytes32[] calldata poolIds,
        uint16[] calldata performances,
        uint16[] calldata ownersBaseApy
    ) external whenNotPaused onlyRole(FINALIZER_ROLE) {
        require(poolIds.length == performances.length && performances.length == ownersBaseApy.length, "E400");
        for (uint256 it; it < poolIds.length; ++it) {
            _finalizePool(poolIds[it], performances[it], ownersBaseApy[it]);
        }
    }

    /**
     * @dev Finalize a pool operative at the previous epoch: distribute owner`s commission and base rewards
     * and save remaining rewards to be individually claimed later by delegators.
     * Invariant: each pool will be finalized sequentially since creation until being terminated.
     * @param poolId id of the pool to finalize
     * @param performance performance of the off-chain node
     * @param ownerBaseApy base APY for its owner
     */
    function _finalizePool(bytes32 poolId, uint16 performance, uint16 ownerBaseApy) private {
        require(performance <= PERCENTAGE_SCALING_FACTOR && ownerBaseApy <= MAX_OWNER_BASE_APY, "E401");

        uint64 currentEpoch = currentEpoch();
        CumulativeReward memory cumulativeReward = poolCumulativeReward(poolId, currentEpoch);
        if (cumulativeReward.finalized) {
            // pool already finalized for the previous epoch
            return;
        }

        Pool storage poolPtr = _poolsArchive[poolId];
        uint256 totalStake = _previousEpochBalance(poolPtr.meta.deposited);
        uint256 ownerStake = _previousEpochBalance(poolPtr.delegations[poolPtr.meta.owner].deposited);
        if (ownerStake == 0) {
            // pool not operative at the previous epoch
            return;
        }

        // compute pool`s total rewards earned at previous epoch
        uint256 poolReward = computePoolEpochRewards(ownerStake, totalStake);

        // compute owner's additional rewards from its supplied base APY
        uint256 baseReward = (((ownerStake * ownerBaseApy) / PERCENTAGE_SCALING_FACTOR) * previousEpochDuration()) /
            ONE_YEAR_SECS;

        // apply jailing on all reward types
        if (poolPtr.meta.jailed) {
            poolReward = 0;
            baseReward = 0;
        }
        // apply slashing on all reward types
        poolReward = (poolReward * performance) / PERCENTAGE_SCALING_FACTOR;
        baseReward = (baseReward * performance) / PERCENTAGE_SCALING_FACTOR;

        // reserve the distributed rewards from the total rewards fund
        require(_depositedRewardsFund >= (poolReward + baseReward), "E205");
        _depositedRewardsFund -= (poolReward + baseReward);

        // compute owner's commission rewards
        uint256 commissionReward = (poolReward * poolPtr.meta.commissionFee) / PERCENTAGE_SCALING_FACTOR;

        // compute pool's cumulative reward up to this epoch
        cumulativeReward.finalized = true;
        cumulativeReward.value = poolCumulativeReward(poolId, currentEpoch - 1).value;
        cumulativeReward.value += SafeCastUpgradeable.toUint248(
            ((poolReward - commissionReward) * TOKEN_FRACTION_SCALING_FACTOR) / totalStake
        );

        // set cumulative reward at this epoch and implicitly mark the pool as finalized
        _poolCumulativeReward[poolId][currentEpoch] = cumulativeReward;

        // reward the pool owner its commission + base rewards
        _unclaimedRewards[poolPtr.meta.owner] += (baseReward + commissionReward);

        // remove this pool from the finalization accounting of previous epoch
        _poolsToFinalizePreviousEpoch -= 1;

        emit FinalizedPool(poolId, performance, ownerBaseApy, cumulativeReward, poolReward, baseReward);
    }

    /**
     * @notice Compute previous epoch rewards for a pool of the given stakes at that epoch.
     * @param ownerStake owner stake at previous epoch
     * @param totalStake total stake at previous epoch
     */
    function computePoolEpochRewards(uint256 ownerStake, uint256 totalStake) public view returns (uint256) {
        uint256 pledgeFactorNum = getConfig(OWNER_STAKE_INFLUENCE_NUM);
        uint256 pledgeFactorDen = getConfig(OWNER_STAKE_INFLUENCE_DEN);
        uint256 saturationCap = getConfig(POOL_SATURATION_CAP);

        ownerStake = MathUpgradeable.min(ownerStake, saturationCap);
        totalStake = MathUpgradeable.min(totalStake, saturationCap);

        // calculate pool stake actually earning rewards
        uint256 earningStake = (ownerStake * (saturationCap - totalStake)) / saturationCap;
        earningStake = (ownerStake * (totalStake - earningStake)) / saturationCap;
        earningStake = (earningStake * pledgeFactorNum) / pledgeFactorDen;
        earningStake += totalStake;
        earningStake = (earningStake * pledgeFactorDen) / (pledgeFactorDen + pledgeFactorNum);
        assert(earningStake <= totalStake);

        // calculate pool rewards from the configured APY and how long the previous epoch lasted
        return
            (((earningStake * getConfig(POOL_EARNING_STAKE_APY)) / PERCENTAGE_SCALING_FACTOR) *
                previousEpochDuration()) / ONE_YEAR_SECS;
    }

    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./deposits/DelegationsAdapter.sol";
import "./deposits/TransfersAdapter.sol";

contract Staking is DelegationsAdapter, TransfersAdapter {
    /**
     * @dev Emitted when `amount` of main token has been deposited to the rewards fund.
     */
    event DepositRewards(uint256 amount);

    /**
     * @dev Emitted when a new pool of id `poolId` has been created by `owner` who
     * staked `currencies` of supported tokens.
     */
    event CreateNewPool(address indexed owner, bytes32 poolId, Currency[] currencies);

    /**
     * @dev Emitted when the commission fee of `poolId` has been set to `commissionFee`.
     */
    event SetPoolCommissionFee(bytes32 indexed poolId, uint256 commissionFee);

    /**
     * @dev Emitted when `delegator` delegated `currencies` of supported tokens to `poolId`.
     */
    event Delegate(address indexed delegator, bytes32 indexed poolId, Currency[] currencies);

    /**
     * @dev Emitted when `delegator` undelegated `currencies` from `poolId`. The extracted `currencies`
     * are then used to create the singleton pending withdrawal of the delegation.
     */
    event Undelegate(address indexed delegator, bytes32 indexed poolId, Currency[] currencies);

    /**
     * @dev Emitted when `delegator` redelegated `currencies` from `poolIdFrom` to `poolIdTo`.
     */
    event Redelegate(
        address indexed delegator,
        bytes32 indexed poolIdFrom,
        bytes32 indexed poolIdTo,
        Currency[] currencies
    );

    /**
     * @dev Emitted when `delegator` cancelled its pending withdrawal on `poolId`.
     */
    event CancelPendingWithdrawal(address indexed delegator, bytes32 indexed poolId);

    /**
     * @dev Emitted when `delegator` executed its pending withdrawal on `poolId`.
     */
    event ExecutePendingWithdrawal(address indexed delegator, bytes32 indexed poolId);

    /**
     * @dev Emitted when `delegator` restaked `amount` of its rewards to `poolIdTo`.
     */
    event Restake(address indexed delegator, bytes32 indexed poolIdTo, uint256 amount);

    /**
     * @dev Emitted when `delegator` claimed `amount` of its rewards.
     */
    event Claim(address indexed delegator, uint256 amount);

    /**
     * @dev Emitted when `poolId` has been jailed.
     */
    event JailPool(bytes32 indexed poolId);

    /**
     * @dev Emitted when `poolId` has been unjailed.
     */
    event UnjailPool(bytes32 indexed poolId);

    /**
     * @notice Upgradeable initializer of contract.
     * @param protocolOwner initial protocol owner
     * @param rewardsToken_ immutable rewards token
     * @param minEpochDuration initial minimum epoch duration
     */
    function initialize(
        address protocolOwner,
        IERC20Upgradeable rewardsToken_,
        uint256 minEpochDuration
    ) public initializer {
        __StakingEpochManager_init_unchained(minEpochDuration);

        _setupRole(OWNER_ROLE, protocolOwner);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
        _setRoleAdmin(JAILER_ROLE, OWNER_ROLE);
        _setRoleAdmin(FINALIZER_ROLE, OWNER_ROLE);

        _initializeRewardsToken(rewardsToken_);

        // pause protocol until entirely configured
        _pause();
    }

    /**
     * @notice Set the version of the implementation contract.
     * @dev Called when linking a new implementation to the proxy
     * contract at `upgradeToAndCall` using the hard-coded integer version.
     */
    function upgradeVersion() external reinitializer(1) {}

    /**
     * @notice Set the value of the global config `key` as the protocol owner.
     * @dev Cannot change global configs while there are pools to be finalized.
     * @param key id of the configuration
     * @param value new value of the configuration
     */
    function setConfig(bytes32 key, uint256 value) external onlyRole(OWNER_ROLE) whenNotFinalizing {
        _setConfig(key, value);
    }

    /**
     * @notice Configure the support level for an ERC20 token as the protocol owner.
     * @param erc20 token address
     * @param state new support level
     */
    function setCurrencySupport(IERC20Upgradeable erc20, CurrencySupport state) external onlyRole(OWNER_ROLE) {
        _setCurrencySupport(erc20, state);
    }

    /**
     * @notice Pause protocol.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause protocol.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Deposit main token to the rewards fund.
     * @param amount amount to deposit
     */
    function depositRewards(uint256 amount) public whenNotPaused {
        _strictTransferFrom(_msgSender(), rewardsToken(), amount);
        _depositedRewardsFund += amount;

        emit DepositRewards(amount);
    }

    /**
     * @notice Create a new staking pool.
     * @dev Reverts if: added insufficient stake to create a pool or the pool has already been created.
     * @param nodeIndex index of the off-chain node
     * @param chainId chain id of the off-chain node
     * @param commissionFee initial commission fee of the pool
     * @param currencies amounts of each supported currency to stake
     */
    function createNewPool(
        uint64 nodeIndex,
        uint32 chainId,
        uint16 commissionFee,
        Currency[] calldata currencies
    ) external whenNotPaused {
        bytes32 poolId = bytes32(abi.encodePacked(_msgSender(), nodeIndex, chainId));

        _strictTransferFrom(_msgSender(), currencies);
        _initializePoolOwner(poolId, _msgSender(), currencies);

        emit CreateNewPool(_msgSender(), poolId, currencies);

        // emit `SetPoolCommissionFee` after the pool creation
        _setPoolCommission(poolId, commissionFee);
    }

    /**
     * @notice Set a pool's commission fee as its owner.
     * @dev Cannot set commission more often than the configured epochs cooldown.
     * @param poolId id of the pool
     * @param commissionFee new commission fee
     */
    function setPoolCommission(bytes32 poolId, uint16 commissionFee) external whenNotPaused {
        require(isPoolOwner(_msgSender(), poolId), "E101");
        require(
            currentEpoch() >= _poolsArchive[poolId].meta.commissionLastSet + getConfig(POOL_COMMISSION_FEE_COOLDOWN),
            "E102"
        );
        _setPoolCommission(poolId, commissionFee);
    }

    /**
     * @dev Set a pool's commission fee.
     * @param poolId id of the pool
     * @param commissionFee new commission fee
     */
    function _setPoolCommission(bytes32 poolId, uint16 commissionFee) private {
        require(commissionFee >= MIN_POOL_COMMISSION_FEE && commissionFee <= PERCENTAGE_SCALING_FACTOR, "E407");
        _poolsArchive[poolId].meta.commissionFee = commissionFee;
        _poolsArchive[poolId].meta.commissionLastSet = currentEpoch();

        emit SetPoolCommissionFee(poolId, commissionFee);
    }

    /**
     * @notice Delegate stake to a pool.
     * @param poolId id of the pool to delegate to
     * @param currencies amounts of each supported currency to delegate
     */
    function delegate(bytes32 poolId, Currency[] calldata currencies) external whenNotPaused {
        _strictTransferFrom(_msgSender(), currencies);
        _stake(poolId, _msgSender(), currencies);

        emit Delegate(_msgSender(), poolId, currencies);
    }

    /**
     * @notice Undelegate stake from a pool.
     * @param poolId id of the pool to undelegate from
     * @param currencies amounts of each supported currency to undelegate
     */
    function undelegate(bytes32 poolId, Currency[] calldata currencies) external whenNotPaused {
        _unstake(poolId, _msgSender(), currencies);
        _createPendingWithdrawal(poolId, _msgSender(), currencies);

        emit Undelegate(_msgSender(), poolId, currencies);
    }

    /**
     * @dev Create the pending withdrawal of a delegation and set its execution timestamp.
     * @param poolId id of the pool
     * @param delegator delegator address
     * @param currencies amounts of each currency to include into pending withdrawal
     */
    function _createPendingWithdrawal(bytes32 poolId, address delegator, Currency[] calldata currencies) private {
        PendingWithdrawal storage withdrawal = _poolsArchive[poolId].delegations[delegator].withdrawal;
        require(withdrawal.currencies.length == 0, "E110");

        for (uint256 it; it < currencies.length; ++it) {
            withdrawal.currencies.push(currencies[it]);
        }
        // start countdown when undelegated stake stops earning rewards
        withdrawal.executeTime = getEpochEarliestEndTime() + getConfig(WITHDRAWAL_LOCK_TIME);
    }

    /**
     * @notice Returns whether an account can redelegate from a given pool.
     * Pool should be either terminated or jailed.
     * Owner cannot redelegate from its own pool.
     * @param account account address
     * @param poolId id of the pool to redelegate from
     */
    function canRedelegate(address account, bytes32 poolId) public view returns (bool) {
        return (poolTerminated(poolId) || poolJailed(poolId)) && !isPoolOwner(account, poolId);
    }

    /**
     * @notice Redelegate stake from a terminated or jailed pool to another one.
     * @param poolIdFrom pool to redelegate from
     * @param poolIdTo pool to redelegate to
     * @param currencies amounts of each currency to redelegate
     */
    function redelegate(bytes32 poolIdFrom, bytes32 poolIdTo, Currency[] calldata currencies) external whenNotPaused {
        require(canRedelegate(_msgSender(), poolIdFrom), "E108");

        _unstake(poolIdFrom, _msgSender(), currencies);
        _stake(poolIdTo, _msgSender(), currencies);

        emit Redelegate(_msgSender(), poolIdFrom, poolIdTo, currencies);
    }

    /**
     * @notice Cancel a pending withdrawal and delegate its stake back to the host pool.
     * @param poolId withdrawal`s host pool
     */
    function cancelPendingWithdrawal(bytes32 poolId) external whenNotPaused {
        PendingWithdrawal storage withdrawal = _poolsArchive[poolId].delegations[_msgSender()].withdrawal;
        require(withdrawal.currencies.length != 0, "E111");

        _stake(poolId, _msgSender(), withdrawal.currencies);
        delete withdrawal.currencies;

        emit CancelPendingWithdrawal(_msgSender(), poolId);
    }

    /**
     * @notice Execute a pending withdrawal if its locking period expired and
     * transfer its stake back to the delegator.
     * @param poolId withdrawal`s host pool
     */
    function executePendingWithdrawal(bytes32 poolId) external whenNotPaused {
        PendingWithdrawal storage withdrawal = _poolsArchive[poolId].delegations[_msgSender()].withdrawal;
        require(withdrawal.currencies.length != 0, "E112");
        require(withdrawal.executeTime <= block.timestamp, "E113");

        // pool owner cannot withdraw unless unjailing its pool
        require(!(isPoolOwner(_msgSender(), poolId) && poolJailed(poolId)), "E107");

        for (uint256 it; it < withdrawal.currencies.length; ++it) {
            _strictTransferTo(_msgSender(), withdrawal.currencies[it].erc20, withdrawal.currencies[it].amount);
        }
        delete withdrawal.currencies;

        emit ExecutePendingWithdrawal(_msgSender(), poolId);
    }

    /**
     * @notice Claim rewards collected already as well as in-flight ones over a set of pools.
     * @param poolIds list of pools to collect delegator rewards from
     */
    function claim(bytes32[] calldata poolIds) external whenNotPaused {
        // collect delegator rewards for caller from the supplied pools
        _collectDelegatorRewardsMany(_msgSender(), poolIds);

        uint256 amount = unclaimedRewards(_msgSender());
        _unclaimedRewards[_msgSender()] -= amount;
        _strictTransferTo(_msgSender(), rewardsToken(), amount);

        emit Claim(_msgSender(), amount);
    }

    /**
     * @notice Restake rewards collected already as well as in-flight ones over a set of pools.
     * @param poolIds list of pools to collect delegator rewards from
     * @param poolIdTo id of the pool to restake to
     * @param amount amount to restake
     */
    function restake(bytes32[] calldata poolIds, bytes32 poolIdTo, uint256 amount) external whenNotPaused {
        // collect delegator rewards for caller from the supplied pools
        _collectDelegatorRewardsMany(_msgSender(), poolIds);

        require(unclaimedRewards(_msgSender()) >= amount, "E114");
        _unclaimedRewards[_msgSender()] -= amount;

        Currency[] memory currencies = new Currency[](1);
        currencies[0] = Currency(rewardsToken(), amount);
        _stake(poolIdTo, _msgSender(), currencies);

        emit Restake(_msgSender(), poolIdTo, amount);
    }

    /**
     * @notice Jail an existing pool.
     * @param poolId id of the pool to jail
     */
    function jail(bytes32 poolId) external whenNotPaused onlyRole(JAILER_ROLE) {
        require(poolExists(poolId), "E204");
        require(!poolJailed(poolId), "E203");

        _poolsArchive[poolId].meta.jailed = true;

        emit JailPool(poolId);
    }

    /**
     * @notice Unjail a pool by paying a fixed fee in main token.
     * @param poolId id of the pool to unjail
     */
    function unjail(bytes32 poolId) external whenNotPaused {
        require(poolJailed(poolId), "E109");

        _poolsArchive[poolId].meta.jailed = false;
        depositRewards(getConfig(POOL_UNJAILING_FEE));

        emit UnjailPool(poolId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./deposits/DepositsAdapter.sol";

abstract contract StakingStorage is DepositsAdapter {
    /**
     * @dev Staking pool global stats.
     * @param owner address of the pool owner(creator)
     * @param commissionFee share of pool`s rewards paid to its owner
     * @param commissionLastSet last epoch when the commission fee has been set
     * @param jailed whether the pool is jailed
     * @param deposited total stake on pool: pledged by owner + delegated by others
     */
    struct PoolMeta {
        address owner;
        uint16 commissionFee;
        uint64 commissionLastSet;
        bool jailed;
        DeferredDeposit deposited;
    }

    /**
     * @dev Staking pool.
     * @param meta pool metadata
     * @param delegations set of delegations indexed by delegator address
     */
    struct Pool {
        PoolMeta meta;
        mapping(address => Delegation) delegations;
    }

    /**
     * @dev Delegation.
     * @param deposited stake owned by this delegator
     * @param withdrawal singleton pending withdrawal to be executed or cancelled
     * @param currencies individual amounts of each currency making up delegator's stake
     */
    struct Delegation {
        DeferredDeposit deposited;
        PendingWithdrawal withdrawal;
        mapping(IERC20Upgradeable => uint256) currencies;
    }

    /**
     * @dev Pending withdrawal for a delegation's stake.
     * @param executeTime timestamp when this withdrawal can be executed
     * @param currencies list of amounts of each currency to be withdrawn
     */
    struct PendingWithdrawal {
        uint256 executeTime;
        Currency[] currencies;
    }

    /**
     * @dev Encapsulates an amount of a specific currency.
     * @param erc20 token address
     * @param amount amount of tokens
     */
    struct Currency {
        IERC20Upgradeable erc20;
        uint256 amount;
    }

    /// @dev Main ERC20 token being distributed as staking rewards.
    IERC20Upgradeable private _rewardsToken;

    /// @dev Remaining protocol staking rewards.
    uint256 internal _depositedRewardsFund;

    /// @dev Data of all pools by id.
    mapping(bytes32 => Pool) internal _poolsArchive;

    /**
     * @notice Returns main ERC20 token being distributed as staking rewards.
     */
    function rewardsToken() public view returns (IERC20Upgradeable) {
        return _rewardsToken;
    }

    /**
     * @notice Returns remaining protocol staking rewards.
     */
    function depositedRewardsFund() external view returns (uint256) {
        return _depositedRewardsFund;
    }

    /**
     * @notice Get metadata of a specific pool.
     */
    function poolMetadata(bytes32 poolId) public view returns (PoolMeta memory) {
        return _poolsArchive[poolId].meta;
    }

    /**
     * @notice Returns whether an account is the supplied pool`s owner.
     */
    function isPoolOwner(address account, bytes32 poolId) public view returns (bool) {
        return _poolsArchive[poolId].meta.owner == account;
    }

    /**
     * @notice Returns whether the supplied pool has been created.
     */
    function poolExists(bytes32 poolId) public view returns (bool) {
        return _poolsArchive[poolId].meta.owner != address(0);
    }

    /**
     * @notice Returns whether the supplied pool is operative and can accept delegations.
     */
    function poolOperative(bytes32 poolId) public view returns (bool) {
        Pool storage poolPtr = _poolsArchive[poolId];
        return poolExists(poolId) && poolPtr.delegations[poolPtr.meta.owner].deposited.nextEpochBalance != 0;
    }

    /**
     * @notice Returns whether the supplied pool has been terminated.
     */
    function poolTerminated(bytes32 poolId) public view returns (bool) {
        return poolExists(poolId) && !poolOperative(poolId);
    }

    /**
     * @notice Returns whether the supplied pool is jailed.
     */
    function poolJailed(bytes32 poolId) public view returns (bool) {
        return _poolsArchive[poolId].meta.jailed;
    }

    /**
     * @notice Get the current and next stake of a pool (as-is and at current-epoch view).
     * @param poolId id of the pool
     */
    function getPoolStake(bytes32 poolId) external view returns (DeferredDeposit memory, DeferredDeposit memory) {
        DeferredDeposit storage depositPtr = _poolsArchive[poolId].meta.deposited;
        return (depositPtr, _loadDeposit(depositPtr));
    }

    /**
     * @notice Get the current and next stake of a delegation (as-is and at current-epoch view).
     * @param delegator delegator address
     * @param poolId id of the pool
     */
    function getDelegatorStake(
        address delegator,
        bytes32 poolId
    ) external view returns (DeferredDeposit memory, DeferredDeposit memory) {
        DeferredDeposit storage depositPtr = _poolsArchive[poolId].delegations[delegator].deposited;
        return (depositPtr, _loadDeposit(depositPtr));
    }

    /**
     * @notice Get a delegation's balance of the supplied currency.
     * @param delegator delegator address
     * @param poolId id of the pool
     * @param erc20 token address
     */
    function getDelegatorCurrency(
        address delegator,
        bytes32 poolId,
        IERC20Upgradeable erc20
    ) external view returns (uint256) {
        return _poolsArchive[poolId].delegations[delegator].currencies[erc20];
    }

    /**
     * @notice Get the pending withdrawal of a delegation if existent.
     * @param delegator delegator address
     * @param poolId id of the pool
     */
    function getDelegatorPendingWithdrawal(
        address delegator,
        bytes32 poolId
    ) external view returns (PendingWithdrawal memory) {
        return _poolsArchive[poolId].delegations[delegator].withdrawal;
    }

    /**
     * @notice Filter from a set of pool ids the ones never used to create a pool.
     * @param poolIds set of pool ids
     */
    function filterPoolIdsIdle(bytes32[] calldata poolIds) external view returns (bytes32[] memory poolIdsIdle) {
        poolIdsIdle = new bytes32[](poolIds.length);
        uint256 count;
        for (uint256 it; it < poolIds.length; ++it) {
            if (!poolExists(poolIds[it])) {
                poolIdsIdle[count++] = poolIds[it];
            }
        }
        count = poolIds.length - count;
        assembly {
            mstore(poolIdsIdle, sub(mload(poolIdsIdle), count))
        }
    }

    /**
     * @dev Set main ERC20 token immutably.
     * @param rewardsToken_ address of main token
     */
    function _initializeRewardsToken(IERC20Upgradeable rewardsToken_) internal {
        assert(address(_rewardsToken) == address(0));
        _rewardsToken = rewardsToken_;
    }

    uint256[47] private __gap;
}