// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.19;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * IMPORTANT: This contract does not include public pause and unpause functions. In
 * addition to inheriting this contract, you must define both functions, invoking the
 * {Pausable-_pause} and {Pausable-_unpause} internal functions, with appropriate
 * access control, e.g. using {AccessControl} or {Ownable}. Not doing so will
 * make the contract unpausable.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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

//  SPDX-License-Identifier: un-licence
pragma solidity 0.8.19;
import "../NFTwhitelist/IAkruNFTWhitelist.sol";
/// @title To issue the security tokens, A unique certificate will be generated
/// @author AKRU's Dev team
contract CertificateController {
    // If set to 'true', the certificate control is activated
    bool _certificateControllerActivated;
    IAkruNFTWhitelist _iwhitelist;

    // Address used by off-chain controller service to sign certificate
    mapping(address => bool) public _certificateSigners;

    // A nonce used to ensure a certificate can be used only once
    mapping(address => uint256) public checkNonce;
    /**
     * @dev Modifier to protect methods with certificate control
     */
    modifier onlyAKRUAdmin()  {
        require(_iwhitelist.isOwner(msg.sender) ||
          _iwhitelist.isAdmin(msg.sender) ||
          _iwhitelist.isSubSuperAdmin(msg.sender)
          , "Only admin is allowed");
        _;
    }

     /**
     * @dev Modifier to protect methods with certificate control
     */
    modifier isValidCertificate(bytes memory data) {
        if (
            _certificateControllerActivated &&
            (_iwhitelist.isWhitelistedUser(msg.sender) > 132)
        ) {
            require(_checkCert(data), "54"); // 0x54	transfers halted (contract paused)

            checkNonce[msg.sender] += 1; // Increment sender check nonce
            //   emit Checked(msg.sender);
        }
        _;
    }
    constructor(address _certificateSigner, bool activated,IAkruNFTWhitelist whitelist) {
        _certificateSigners[_certificateSigner] = true;
        _certificateControllerActivated = activated;
        _iwhitelist = whitelist;
    }

   
    /**
     * @dev Set signer authorization for operator.
     * @param operator Address to add/remove as a certificate signer.
     * @param authorized 'true' if operator shall be accepted as certificate signer, 'false' if not.
     */
    function setCertificateSigner(
        address operator,
        bool authorized
    ) public onlyAKRUAdmin {
        require(operator != address(0)); // Action Blocked - Not a valid address
        _certificateSigners[operator] = authorized;
    }

    /**
       * @dev Get activation status of certificate controller.
       * @return check if certificateControllerActivated
       */
      function certificateControllerActivated() external view returns (bool) {
        return _certificateControllerActivated;
    }

    /**
     * @dev Activate/disactivate certificate controller.
     * @param activated 'true', if the certificate control shall be activated, 'false' if not.
     */
    function setCertificateControllerActivated(
        bool activated
    ) public onlyAKRUAdmin {
        _certificateControllerActivated = activated;
    }

    /**
     * @dev Checks if a certificate is correct
     * @param data Certificate to control
     */
    function _checkCert(bytes memory data) internal view returns (bool) {
        uint256 nonce = checkNonce[msg.sender];

        uint256 e;
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract certificate information and expiration time from payload
        assembly {
            // Retrieve expirationTime & ECDSA elements from certificate which is a 97 or 98 long bytes
            // Certificate encoding format is: <expirationTime (32 bytes)>@<r (32 bytes)>@<s (32 bytes)>@<v (1 byte)>
            e := mload(add(data, 0x20))
            r := mload(add(data, 0x40))
            s := mload(add(data, 0x60))
            v := byte(0, mload(add(data, 0x80)))
        }

        // Certificate should not be expired
        if (uint256(e) < block.timestamp) {
            return false;
        }

        if (v < 27) {
            v += 27;
        }

        // Perform ecrecover to ensure message information corresponds to certificate
        if (v == 27 || v == 28) {
            // Extract functionId, to address and amount from msg.data
            bytes memory msgData = msg.data;
            bytes4 funcId;
            address to;
            bytes32 amount;

            assembly {
                funcId := mload(add(msgData, 32))
                amount := mload(add(msgData, 68))
                to := mload(add(msgData, 36))
            }
            // Pack and hash
            bytes32 _hash = keccak256(
                abi.encodePacked(
                    address(this),
                    funcId,
                    to,
                    uint256(amount),
                    nonce
                )
            );

            // compute signer
            address _signer = ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
                ),
                v,
                r,
                s
            );
            // Check if certificate match expected transactions parameters
            if (_certificateSigners[_signer]) {
                return true;
            }
        }
        return false;
    }
      /**
     * @dev toggleCertificateController activate/deactivate Certificate Controller
     * @param isActive true/false
     */
    function toggleCertificateController(bool isActive) public onlyAKRUAdmin {
        _certificateControllerActivated = isActive;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IMarginLoan {
    /**
     * LoanStatus : it will have only follwoing three values.
     */
    enum LoanStatus {NOTFOUND, PENDING, ACTIVE, COMPLETE, REJECT, CANCEL, PLEDGE}
    /**
     * MarginLoan: This struct will Provide the required field of Loan record
     */
    struct MarginLoan {
        address user;
        address bank;
        uint256 loanAmount;
        uint256 interestRate;
        LoanStatus status;
        address tokenAddress;
        uint256 createdAt;
        uint256 installmentAmount;
        uint256 loanLimit;      //maximum loan limit a user can avail against tokens
        uint256 loanPercentage;
        uint256 noOfTokens;
    }

    /**
     * LoanRequest: This event will triggered when ever their is request for loan
     */
    event LoanRequest(
        address user,
        address bank,
        uint256 loanAmount,
        uint256 interestRate,
        LoanStatus status,
        address tokenAddress,
        uint256 createdAt,
        uint256 installmentAmount,
        uint256 id,
        uint256 loanPercentage,
        uint256 noOfTokens
    );
    event UpdateLoan(address user, uint256 id, LoanStatus status);
    event PledgeToken(address user, address _token,uint256 noOfToekns,  LoanStatus status);

    /**
     * called when user request loan from bank
     *
     */
    function requestLoan(
        address _bank,
        uint256 _loanAmount,
        uint256 _interestRate,
        address _tokenAddress,
        uint256 createdAt,
        uint256 installmentAmount,
        uint256 _loanPercentage,
        uint256 noOfTokens
    ) external;

    /**
     * this function would return user margin with erc1400 address
     */
    function getLoan(address _user, address tokenAddress)
        external
        view
        returns (uint256,uint256);
    function getPledgedLoan(address _user, address tokenAddress, address _bank)
        external
        view
        returns (uint256,uint256, uint256,  uint256);

    /**
     * only user with a rule of bank can approve loan
     */
     function completeLoan(address _user, uint256 _id)
        external
        returns (bool);
     function pledgeLoanToken(address _user,address _tokenAddress, address _bank)
        external
        returns (bool);

    /**
     *getLoanStatus: thsi function return loan status of address provided
     */
    function getLoanStatus(
        address _user,
        uint256 _id
    ) external view returns (uint256);

    /**
     * only user with a rule of bank can reject loan
     */
    function cancelLoan(uint256 _id) external returns (bool);

    /**
     * get t0tal of margin loan array of address
     */
    function getTotalLoans(address _user) external view returns (uint256);

    /**
     * get total number of  loan on a signle erc1400 token
     */

    function getTotalLoanOfToken(
        address _user,
        address _token
    )
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );
    
    function getTotalLoanOfPledgedToken(address _user, address _token, address _bank)
        external 
        view
          returns (
            address[] memory banks,
            uint256[] memory loanAmounts,
            uint256[] memory interestRates
          
        );

   function getTotalNoOfTokens(address _user, address _token)
        external
        view
        returns (uint256[] memory,uint256[] memory);

  function getTotalNoOfPledgeTokens(address _user, address _token, address _bank)
        external
        view
        returns (uint256[] memory ids, uint256[] memory loans, uint256[] memory interest);
        
    function updateLoan(
        address user,
        uint256 id,
        uint256 amountPayed,
        uint256 caller
    ) external;

    function updatePledgeLoan(
        address user,
        uint256 id,
        uint256 amountPayed,
        uint256 tokensSold,
        uint256 caller
    ) external;
   function getLoanLimit(address user, address tokenAddress, uint256 loanPercentage) view external returns (uint256) ;
   function getRemainingLoanLimit( address user,address tokenAddress, uint256 loanPercentage) view external returns ( uint256);

    function addBlockedUser(address user) external ;
    
    function removeBlockedUser(address user) external;

    function isBlockedUser(address user) external view  returns(bool);

    function payPledgeLoan(address user,address tokenAddress, address bank)
        external
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IwhitelistNFT.sol";
// import "hardhat/console.sol";
/**
 * @title AkruAdminWhitelist
 * @author Umar Mubeen
 * @dev AkruAdminWhitelist to whitlist of AKRU's users
 */
contract AkruNFTAdminWhitelist is
    Ownable
{  
    IwhitelistNFT public NFT; //ERC721 being used in whitelisting
    address public superAdmin;
    address feeAddress;
    bool public accreditationCheck = true;
    address[] public userList;
    //store the prefix of NFT id associated with each role
    mapping(ROLES => uint256) public roleIdPrefix;
    //store the each role struct against id
    mapping(address => uint256) userNftIds; //added mapping
    mapping(address => ROLES) userRoleIndex; //added mapping
    mapping(ROLES => string) userRoleNames; //added mapping

    mapping(address => WhitelistInfo) whitelistUsers;
    mapping(ROLES => uint256) userWhitelistNumber; //added mapping


      /**
     * @dev enum of different roles
     */
    enum ROLES {
        unRegister,
        superAdmin,
        subSuperAdmin,
        admin,
        manager,
        mediaManager,
        propertyOwner,
        propertyAccount,
        propertyManager,
        serviceProvider,
        subServiceProvider,
        bank,
        user_USA, //12
        user_Foreign //13
    }
    /**
    *@dev it takes NFT address and then mint nft to create super admin 
        add and entry to roleInfo mapping. 
    */
    constructor(address nftAddress) {
        NFT =IwhitelistNFT(nftAddress);
        superAdmin = _msgSender();
        initializeRoleIdPrefix();
        whitelistUsers[msg.sender] = WhitelistInfo({
            valid: true,
            taxWithholding: 0,
            wallet: msg.sender,
            kycVerified: true,
            accredationExpiry: 0,
            accredationVerified: true,
            role: ROLES.superAdmin,
            userRoleId: 11,
            isPremium: false
        });
        userRoleIndex[msg.sender] = ROLES.superAdmin;
    }
    struct WhitelistInfo {
        bool valid;
        bool kycVerified;
        bool accredationVerified;
        uint256 accredationExpiry;
        uint256 taxWithholding;
        ROLES role;
        uint256 userRoleId;
        bool isPremium;
        address wallet; // Moved to the end
    }
    event AddWhitelistRole(address user,uint256 nftId,ROLES role,address caller);
    event AddSuperAdmin(address sender,address superAdmin, uint256 nftId, uint256 roleInfoId);
    event SetRoleIdPrefix(ROLES role, uint256 prefix);
    event UpdateAccreditationCheck(bool status, address caller);
    event RemoveWhitelistedRole(address user, ROLES role, uint256 roleInfoId);
    event AddFeeAddress(address feeAddress, address sender);
    /**
     * @dev method works as modifier to allow only super admin
     */
    function onlySuperAdmin() internal view {
        require(
            userRoleIndex[_msgSender()] == ROLES.superAdmin ,
            "W8"
        );
    }
    /**
     * @dev method works as modifier to allow only superAdmin & sub-superAdmin
     */
    function onlySuperAndSubSuperAdmin() internal view {
        bool isSuperAdminRange = userRoleIndex[_msgSender()] == ROLES.superAdmin; 
        bool isSubSuperAdminRange =  userRoleIndex[_msgSender()] == ROLES.subSuperAdmin;
        require(
            (isSuperAdminRange || isSubSuperAdminRange),
            "W9"
        );
    }
    /**
     * @dev method works as modifier to allow only superAdmin, sub-superAdmin and admin
     */
    function onlyAdmin() internal view {
        bool isSuperAdminRange = userRoleIndex[_msgSender()] == ROLES.superAdmin; 
        bool isSubSuperAdminRange =  userRoleIndex[_msgSender()] == ROLES.subSuperAdmin;
        bool isAdminRange = userRoleIndex[_msgSender()] == ROLES.admin;
        // checkAdminRole(_msgSender(), ROLES.admin);
        require(
            (isSuperAdminRange || isSubSuperAdminRange || isAdminRange),
            "W10"
        );
    }
    /**
        * @dev method works as modifier to allow only 
         superAdmin, sub-superAdmin,admin and manager 
    */
    function onlyManager() internal view {
        bool isSuperAdminRange = userRoleIndex[_msgSender()] == ROLES.superAdmin; 
        bool isSubSuperAdminRange =  userRoleIndex[_msgSender()] == ROLES.subSuperAdmin;
        bool isAdminRange = userRoleIndex[_msgSender()] == ROLES.admin;
        bool isManagerRange = userRoleIndex[_msgSender()] == ROLES.manager;

        require(
            (isSuperAdminRange ||
                isSubSuperAdminRange ||
                isAdminRange ||
                isManagerRange),
            "W11"
        );
    }

    /**
        * @dev method works as modifier to allow only 
            superAdmin, sub-superAdmin,admin and media-manager
    */
    function onlyMediaManager() internal view {
        bool isSuperAdminRange = userRoleIndex[_msgSender()] == ROLES.superAdmin; 
        bool isSubSuperAdminRange =  userRoleIndex[_msgSender()] == ROLES.subSuperAdmin;
        bool isAdminRange = userRoleIndex[_msgSender()] == ROLES.admin;
        bool isMediaMan = userRoleIndex[_msgSender()] == ROLES.mediaManager;
        require(
            (isSuperAdminRange ||
                isSubSuperAdminRange ||
                isAdminRange ||
                isMediaMan),
            "W12"
        );
    }
    /**
     *@dev it only allow user with specific role to add other roles.
     *@param user user address to assign role
     *@param nftId to be associated with role.
     *@param role that willbe assigned.
     */
    function addManageralRole(address user, uint256 nftId, ROLES role) public {
        if (role == ROLES.subSuperAdmin) {
            onlySuperAdmin();
        }
        if (role == ROLES.admin) {
            onlySuperAndSubSuperAdmin();
        }
        if (
            role == ROLES.manager ||
            role == ROLES.mediaManager ||
            role == ROLES.bank ||
            role == ROLES.propertyAccount ||
            role == ROLES.propertyOwner ||
            role == ROLES.propertyManager ||
            role == ROLES.serviceProvider ||
            role == ROLES.subServiceProvider
        ) {
            onlyAdmin();
        }
        require(role != ROLES.superAdmin, "W13");
        require(!whitelistUsers[user].valid, "W1");
        uint256 roleToId = getIdPrefix(nftId);
        require(roleIdPrefix[role] == roleToId, "W2");
        require(nftId > 10, "W14");
        whitelistUsers[user] = WhitelistInfo({
            valid: true,
            taxWithholding: 0,
            wallet: user,
            kycVerified: true,
            accredationExpiry: 0,
            accredationVerified: true,
            role: role,
            userRoleId: nftId,
            isPremium: false
        });
        userNftIds[user] = nftId; // storing nft id against the user in mapping
        userRoleIndex[user] = role; //storing role in a mapping
        NFT.mintToken(user, nftId);
        emit AddWhitelistRole(user, nftId, role,_msgSender());
    }
    /**
     *@dev it only allow super admin to remove roles.
     *@param user that need to be removed from role.
     *@param role that will be removed.
     */
    function removeManageralRole(address user, ROLES role) public {
        require(role != ROLES.superAdmin,"W15" );
        if (      
            role == ROLES.subSuperAdmin ||
            role == ROLES.admin
        ) {
            onlySuperAdmin();
        }
        if (
            role == ROLES.manager ||
            role == ROLES.mediaManager ||
            role == ROLES.bank ||
            role == ROLES.propertyAccount ||
            role == ROLES.propertyOwner ||
            role == ROLES.propertyManager ||
            role == ROLES.serviceProvider ||
            role == ROLES.subServiceProvider
        ) {
            onlyAdmin();
        }
        require(userRoleIndex[user] == role, "W4");
        uint256 nftIds =userNftIds[user];//change
        NFT.burnToken(nftIds);
        delete whitelistUsers[user];
        delete userRoleIndex[user];
        emit RemoveWhitelistedRole(user, role, nftIds);
    }
    /**
     *@dev add the super admin role , 
        this method willbe called just after deployment of the whitelisting smart contract
     */
    function renounceSuperAdmin(address newSuperAdmin) external {
        onlySuperAdmin();
        require(NFT.ownerOf(11) == msg.sender,"W7");
         NFT.transferOwnerShip(_msgSender(), newSuperAdmin, 11);
         whitelistUsers[newSuperAdmin] = WhitelistInfo({
            valid: true,
            taxWithholding: 0,
            wallet: newSuperAdmin,
            kycVerified: true,
            accredationExpiry: 0,
            accredationVerified: true,
            role: ROLES.superAdmin,
            userRoleId: 11,
            isPremium: false
        });
        emit AddSuperAdmin(_msgSender(), newSuperAdmin, 11, 11);
    }
    /**
     * @dev Update Accredential Status
     * @param status true/false
     */
    function updateAccreditationCheck(bool status) public {
        onlyManager();
        accreditationCheck = status;
        emit UpdateAccreditationCheck(status, _msgSender());
    }

    /**
     * @dev whitelist the feeAddress in AKRU
     * @param _feeAddress address of new fee address
     */
    function addFeeAddress(address _feeAddress) public {
        onlySuperAndSubSuperAdmin();
        feeAddress = _feeAddress;
        emit AddFeeAddress(_feeAddress, msg.sender);
    }
    /**
     * @dev return the feeAddress in AKRU
     * @return feeAddress
     */
    function getFeeAddress() public view returns (address) {
        return feeAddress;
    }
    /**
     * @dev return the status of admin in AKRU
     * @param calle address of admin
     * @return true/false
     */
    function isAdmin(address calle) public view returns (bool) {
        // return userRoleIndex[calle] == ROLES.admin;
        bool isSuperAdminRange = userRoleIndex[calle] == ROLES.superAdmin; 
        bool isSubSuperAdminRange =  userRoleIndex[calle] == ROLES.subSuperAdmin;
        bool isAdminRange = userRoleIndex[calle] == ROLES.admin;
        if(isSuperAdminRange || isSubSuperAdminRange || isAdminRange){
            return true;
        }else{
            return false;
        }
    }
    /**
     * @dev return the status of super admin in AKRU
     * @param calle address of super admin
     * @return true/false
     */
    function isSuperAdmin(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.superAdmin;
    }
    /**
     * @dev return the status of sub super admin in AKRU
     * @param calle address of sub super admin
     * @return true/false
     */
    function isSubSuperAdmin(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.subSuperAdmin;
    }
    /**
     * @dev return the status of bank in AKRU
     * @param calle address of bank
     * @return true/false
     */
    function isBank(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.bank;
    }
    /**
     * @dev return the status of property owner in AKRU
     * @param calle address of property owner
     * @return true/false
     */
    function isOwner(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.propertyOwner;
    }
    /**
     * @dev return the status of manager in AKRU
     * @param calle address of manager
     * @return true/false
     */
    function isManager(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.manager;
    }
        /**
     * @dev check the media manager role
     * @param calle  Address of manager
     * @return role status
     */
    function isMediaManager(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.mediaManager;
    }
    /**
     * @dev set the nft ID prefix (2 digits) for specific role.
     * @param IdPrefix nft id prefix value
     * @param role associated role with nft id prefix.
     */
    function setRoleIdPrefix(ROLES role, uint256 IdPrefix) internal {
        roleIdPrefix[role] = IdPrefix;
        emit SetRoleIdPrefix(role, IdPrefix);
    }

    /**
     * @dev return the NFTId prefix of given role
     * @param role to check prefix.
     */
    function getRoleIdPrefix(ROLES role) public view returns (uint256) {
        return roleIdPrefix[role];
    }
    /**
     * @dev it returs the first 2 digit of NFT id.
     * @param id nft id to get first 2 digits
     */
    function getIdPrefix(uint id) internal pure returns (uint) {
        uint divisor = 1;
        while (id / divisor >= 100) {
            divisor *= 10;
        }
        uint result = id / divisor;
        return result % 100;
    }
    /**
     * @dev it initializes and associate the each role with specific ID prefix.
     */
    function initializeRoleIdPrefix() internal {
        setRoleIdPrefix(ROLES.superAdmin, 11);
        setRoleIdPrefix(ROLES.subSuperAdmin, 12);
        setRoleIdPrefix(ROLES.admin, 13);
        setRoleIdPrefix(ROLES.manager, 14);
        setRoleIdPrefix(ROLES.mediaManager, 15);
        setRoleIdPrefix(ROLES.bank, 16);
        setRoleIdPrefix(ROLES.propertyAccount, 17);
        setRoleIdPrefix(ROLES.propertyOwner, 18);
        setRoleIdPrefix(ROLES.propertyManager, 19);
        setRoleIdPrefix(ROLES.user_USA, 21);
        setRoleIdPrefix(ROLES.user_Foreign, 22);
        setRoleIdPrefix(ROLES.serviceProvider, 23);
        setRoleIdPrefix(ROLES.subServiceProvider, 24);
        /// Setting Each role with specific code for users
        userWhitelistNumber[ROLES.superAdmin] = 100;
        userWhitelistNumber[ROLES.subSuperAdmin] = 101;
        userWhitelistNumber[ROLES.admin] = 112;
        userWhitelistNumber[ROLES.manager] = 120;
        userWhitelistNumber[ROLES.mediaManager] = 125;
        userWhitelistNumber[ROLES.propertyAccount] = 132;
        userWhitelistNumber[ROLES.bank] = 130;
        userWhitelistNumber[ROLES.propertyOwner] = 140;
        userWhitelistNumber[ROLES.propertyManager] = 135;
        userWhitelistNumber[ROLES.user_USA] = 200;
        userWhitelistNumber[ROLES.user_Foreign] = 200;
        userWhitelistNumber[ROLES.serviceProvider] = 200;
        userWhitelistNumber[ROLES.subServiceProvider] = 200;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "./AkruNFTAdminWhitelist.sol";
/**
 * @title AkruWhitelist
 * @dev AkruWhitelist to whitlist of AKRU's users
 */
contract AkruNFTWhitelist is AkruNFTAdminWhitelist {
    mapping(string => bool) symbolsDef;
     constructor(address nftAddress) AkruNFTAdminWhitelist(nftAddress) {}
    event RemoveWhitelistedUser(address user, ROLES role, uint256 roleInfoId);
    event AddWhitelistUser(address user,ROLES role,uint256 userId,uint256 accreditationExpire,bool isAccredated,bool isKycVerified);
    event UpdateAccredationWhitelistedUser(address user, uint256 accredation);
    event UpdateTaxWhitelistedUser(address user, uint256 taxWithholding);
    event UpdateUserAccredationStatus(address caller, address user, bool status);
    event UpdateUserType(address caller, address user, bool status);
    event SetRoleNames(address user, ROLES _value, string _name);
    event setWhitelistUserNumber(ROLES _value, uint256 _num);
    event SetWhitelistNumber(address sender,ROLES value, uint256 roleNum);
    event RemoveWhitelistNumber(address caller, ROLES value);

    /**
     * @dev whitelist the user with specfic KYC and accredation verified check and time in AKRU
     * @param _wallet  Address of new user
     * @param _kycVerified is kyc true/false
     * @param _accredationVerified is accredation true/false
     * @param _accredationExpiry accredation expiry date in unix time
     */
    function addWhitelistUser(
        address _wallet,
        bool _kycVerified,
        bool _accredationVerified,
        uint256 _accredationExpiry,
        ROLES role,
        uint256 nftId
    ) public {
        onlyManager();
        require(!whitelistUsers[_wallet].valid, "W1");
        uint256 roleToId = getIdPrefix(nftId);
        require(roleIdPrefix[role] == roleToId, "W2");
        require(
            roleToId > 14,
            "W3"
        );
        NFT.mintToken(_wallet, nftId);
        userList.push(_wallet);
        whitelistUsers[_wallet] = WhitelistInfo({
            valid: true,
            taxWithholding: 0,
            wallet: _wallet,
            kycVerified: _kycVerified,
            accredationExpiry: _accredationExpiry,
            accredationVerified: _accredationVerified,
            role: role,
            userRoleId: nftId,
            isPremium: false
        });
        userNftIds[_wallet] = nftId; // storing nft id against the user in mapping
        userRoleIndex[_wallet] = role; //storing role in a mapping
        emit AddWhitelistUser(
            _wallet,
            role,
            nftId,
            _accredationExpiry,
            _accredationVerified,
            _kycVerified
        );
    }
    /**
     * @dev get the user with specfic KYC and accredation verified check and time in AKRU
     * @param _wallet  Address of  user
     * @return _wallet  Address of  user
     * @return _kycVerified is kyc true/false
     * @return _accredationVerified is accredation true/false
     * @return _accredationExpiry accredation expiry date in unix time
     */
    function getWhitelistedUser(
        address _wallet)
        public
        view
        returns (address, bool, bool, uint256, ROLES, uint256, uint256, bool)
       {
        WhitelistInfo memory u = whitelistUsers[_wallet];
        return (
            u.wallet,
            u.kycVerified,
            u.accredationExpiry >= block.timestamp,
            u.accredationExpiry,
            u.role,
            u.taxWithholding,
            u.userRoleId,
            u.valid
        );
    }
    /**
     * @dev remove the whitelisted user , burn nft and update structs
     * @param user  Address of user being removed
     * @param role role that need to be removed.
     */
    function removeWhitelistedUser(address user, ROLES role) public {
        onlyManager();
        require(userRoleIndex[user] == role, "W4");
        uint256 nftIds = userNftIds[user];
        delete whitelistUsers[user];
        delete userRoleIndex[user];
        NFT.burnToken(nftIds);
        emit RemoveWhitelistedUser(user, role, nftIds);
    }
    /**
     * @dev update the user with specfic accredation expiry date in AKRU
     * @param _wallet  Address of user
     * @param  _accredationExpiry accredation expiry date in unix time
     */
    function updateAccredationWhitelistedUser(
        address _wallet,
        uint256 _accredationExpiry
      ) public {
        onlyManager();
        require(_accredationExpiry >= block.timestamp,"W5");
        WhitelistInfo storage u = whitelistUsers[_wallet];
        u.accredationExpiry = _accredationExpiry;
        u.accredationVerified = true;
        emit UpdateAccredationWhitelistedUser(_wallet, _accredationExpiry);
    }
    /**
     * @dev update the user with new tax holding in AKRU
     * @param _wallet  Address of user
     * @param  _taxWithholding  new taxWithholding
     */
    function updateTaxWhitelistedUser(
        address _wallet,
        uint256 _taxWithholding
    ) public {
        onlyAdmin();
        WhitelistInfo storage u = whitelistUsers[_wallet];
        u.taxWithholding = _taxWithholding;
        emit UpdateTaxWhitelistedUser(_wallet, _taxWithholding);
    }

    /**
     * @dev Symbols Deployed Add to Contract
     * @param _symbols string of new symbol added in AKRU
     */
    function addSymbols(string calldata _symbols) external returns (bool) {
        if (symbolsDef[_symbols] == true) return false;
        else {
            symbolsDef[_symbols] = true;
            return true;
        }
    }
    /**
     * @dev removed Symbol from Contract
     * @param _symbols string of already added symbol in AKRU
     */
    function removeSymbols(string calldata _symbols) external returns (bool) {
        onlyManager();
        if (symbolsDef[_symbols] == true) symbolsDef[_symbols] = false;
        return true;
    }
    /**
     * @dev returns the status of kyc of user.
     * @param user address to verify the KYC.
     */
    function isKYCverfied(address user) public view returns (bool) {
        WhitelistInfo memory info = whitelistUsers[user];
        return info.kycVerified;
    }
    /**
     *
     * @dev Update User Type to Premium
     * @param user address of User whose want to update as premium
     * @param status it will update of status premium of user
     */
    function updateUserType(address user, bool status) public {
        onlyManager();
        require(whitelistUsers[user].valid, "W6");
        whitelistUsers[user].isPremium = status;
        emit UpdateUserType(msg.sender, user, status);
    }
    /**
     * @dev returns the status of accredation of user.
     * @param user address to verify the accredation.
     */
    function isAccreditationVerfied(address user) public view returns (bool) {
        WhitelistInfo memory info = whitelistUsers[user];
        return info.accredationExpiry > block.timestamp;
    }
    /**
     * @dev return the status of USA user in AKRU
     * @param user address of sub super admin
     * @return true/false
     */
    function isUserUSA(address user) public view returns (bool) {
        if (userRoleIndex[user] == ROLES.user_USA) {
            if (accreditationCheck) {
                return
                    whitelistUsers[user].accredationExpiry >= block.timestamp;
            } else return true;
        }else{
            return false;
        }
    }
    /**
     * @dev return the status of Foreign user in AKRU
     * @param user address of sub super admin
     * @return true/false
     */
    function isUserForeign(address user) public view returns (bool) {
        return userRoleIndex[user] == ROLES.user_Foreign;
    }
    /**
     * @dev return the type of the user
     * @param caller address of the user
     */
    function isPremiumUser(address caller) public view returns (bool success) {
        return whitelistUsers[caller].isPremium;
    }
    /**
     * @dev return white listed user information
     * @param user address of the user
     */
    function getWhitelistInfo(
        address user
    )
        public
        view
        returns (
            bool valid,
            address wallet,
            bool kycVerified,
            bool accredationVerified,
            uint256 accredationExpiry,
            uint256 taxWithholding,
            ROLES role,
            uint256 userRoleId
        )
    {
        WhitelistInfo memory info = whitelistUsers[user];
        return (
            info.valid,
            info.wallet,
            info.kycVerified,
            info.accredationVerified,
            info.accredationExpiry,
            info.taxWithholding,
            info.role,
            info.userRoleId
        );
    }
    /**
     * @dev return the role and role id hold by the given user
     * @param _userAddress address of the user.
     * function optimised to removed redandant if else statements
     */
    function isWhitelistedUser(
        address _userAddress
    ) public view returns (uint256) {
        if (whitelistUsers[_userAddress].valid) {
            ROLES roleIndex = userRoleIndex[_userAddress];
            return userWhitelistNumber[roleIndex];
        } else {
            return 400;
        }
    }
    /**
     * @dev return the role and role id hold by the given user
     * @param userAddress address of the user.
     * function optimised to remove redundant if else statements
     */
    function getUserRole(
        address userAddress
    ) public view returns (string memory roleName, ROLES value) {
        ROLES roleIs = userRoleIndex[userAddress];
        return (userRoleNames[roleIs], roleIs);
    }
    /**
     * @dev set the role number in mapping against the role id
     * @param value role id  
     * @param roleNum role number of whitelist user

     */
    function setWhitelistNumber(ROLES value, uint256 roleNum) external {
        onlyAdmin();
        userWhitelistNumber[value] = roleNum;
        emit SetWhitelistNumber(msg.sender,value, roleNum);
    }
    /**
     * 
     * @dev Remove code against role from whitelisting
     * @param value Role that passeed to removed 
     */
    function removeWhitelistNumber(ROLES value) external{
        onlyAdmin();
        require(userWhitelistNumber[value] != 0,"There is No any role exist");
        delete userWhitelistNumber[value];
        emit RemoveWhitelistNumber(msg.sender, value);
        
    }
    /**
     * @dev set the role name in mapping against the role id
     * @param name name of user role. 
     * @param value index of ROLES enum.

     */

    function setRoleName(ROLES value, string memory name) external {
        onlyAdmin();
        userRoleNames[value] = name;
        emit SetRoleNames(msg.sender,value, name);
    }
    /**
     * @dev destroy the whitelist contract
     */
    function closeTokenismWhitelist() public {
        onlySuperAdmin();
        selfdestruct(payable(msg.sender));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/**
 * @title IAkruNFTAdminWhitelist
 */
interface IAkruNFTWhitelist {
    /**
     * @dev enum of different roles
     */

     /**
      * @dev Code of Whitelisting according to there Reverted Reason
      * 
      * W1: User is Already Whitelisited
      * W2: Role is not exist or mismatch role that you want to assign with NFTs
      * W3: User-Whitelist: Manager Couldn't Add higher roles
      * W4: Not Specified Role by removing NFT this role is not assign to this user
      * W5: NFT-Whitelist: Accredation Expiry time is before current time
      * W6: Not a Valid User
      * W7: Caller Should be super Admin for renounce Super Admin
      * W8: Admin-Whitelist: Only super admin is allowed
      * W9: Admin-Whitelist: Only super OR Sub-super admins are authorized
      * W10: Admin-Whitelist: Only admin is allowed
      * W11: Admin-Whitelist: Only Manager is allowed
      * W12: Admin-Whitelist: Only Media Manager is allowed
      * W13: Whitelisting: SuperAdmin can not added
      * W14: Length of NFT should be greater than or equal to 2
      * W15: Whitelisting: SuperAdmin Not Removed
      * 
      * 
      * 
      * 
      * 
      *   superAdmin = 100;
      * subSuperAdmin = 101;
      * admin = 112;
      * manager = 120;
      * mediaManager = 125
      * propertyAccount = 132
      * bank = 130;
      * propertyOwner = 140
      * propertyManager = 135
      * user_USA = 200
      * user_Foreign = 200
      * 
        userWhitelistNumber[ROLES.user_USA] = 200;
        userWhitelistNumber[ROLES.user_Foreign] = 200;
        userWhitelistNumber[ROLES.serviceProvider] = 200;
        userWhitelistNumber[ROLES.subServiceProvider] = 200;
      */
    enum ROLES {
        unRegister,//0
        superAdmin,//1
        subSuperAdmin,//2
        admin,//3
        manager,//4
        mediaManager,//5
        propertyOwner,//6
        propertyAccount,//7
        propertyManager,//8
        serviceProvider,//9
        subServiceProvider,//10
        bank,//11
        user_USA,//12
        user_Foreign //13
    }

    function addWhitelistRole(address user, uint256 NFTId, ROLES role) external;
    function removeWhitelistedRole(address user, ROLES role) external;
    function addSuperAdmin() external;
    function updateAccreditationCheck(bool status) external;
    function isMediadManager(address _wallet) external view returns (bool);
    function addFeeAddress(address _feeAddress) external;
    function getFeeAddress() external view returns (address);
    function isAdmin(address _calle) external view returns (bool);
    function isSuperAdmin(address _calle) external view returns (bool);
    function isSubSuperAdmin(address _calle) external view returns (bool);
    function isBank(address _calle) external view returns (bool);
    function isOwner(address _calle) external view returns (bool);
    function isManager(address _calle) external view returns (bool);
    function getRoleInfo(uint256 id)external view returns (uint256 roleId,ROLES roleName,uint256 NFTID,address userAddress,uint256 idPrefix,bool valid);
    function checkUserRole(address userAddress, ROLES role) external view returns (bool);
    function setRoleIdPrefix(ROLES role, uint256 IdPrefix) external;
    function getRoleIdPrefix(ROLES role) external view returns (uint256);
    function addWhitelistUser(address _wallet,bool _kycVerified,bool _accredationVerified,uint256 _accredationExpiry,ROLES role,uint256 NFTId) external;
    function getWhitelistedUser(address _wallet)external view returns (address, bool, bool, uint256, ROLES, uint256, uint256, bool);
    function removeWhitelistedUser(address user, ROLES role) external;
    function updateKycWhitelistedUser(address _wallet,bool _kycVerified) external;
    function updateUserAccredationStatus(address _wallet,bool AccredationStatus) external;
    function updateAccredationWhitelistedUser(address _wallet, uint256 _accredationExpiry) external;
    function updateTaxWhitelistedUser(address _wallet,uint256 _taxWithholding) external;
    function addSymbols(string calldata _symbols) external returns (bool);
    function removeSymbols(string calldata _symbols) external returns (bool);
    function isKYCverfied(address user) external view returns (bool);
    function isAccreditationVerfied(address user) external view returns (bool);
    function isAccredatitationExpired(address user) external view returns (bool);
    function isUserUSA(address user) external view returns (bool);
    function isUserForeign(address user) external view returns (bool);
    function isPremiumUser(address caller) external view returns (bool);
    // function userType(address _caller) external view returns (bool);
    function getWhitelistInfo(address user)external view returns (bool valid,address wallet,bool kycVerified,bool accredationVerified,uint256 accredationExpiry,uint256 taxWithholding,ROLES role,uint256 userRoleId);
    function getUserRole(address _userAddress) external view returns (string memory, ROLES);
    function closeTokenismWhitelist() external;
    function isWhitelistedUser(address _userAddress) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IwhitelistNFT {
    event IssueToken(address user, uint256  tokenId, address caller);
    event TokenBurn(uint256 tokenId, address caller, bool status);
    event TokenBurnerAdded(address user, address caller, bool status);
    event TokenMinterAdded(address user, address caller, bool status);
    event TokenMinterRemoved(address user, address caller, bool status);
    event TokenBurnerRemoved(address user,  address caller, bool status);
    event OwnerTokenIds(address  user, uint256[] tokenIds);
    event AdminUpdated(address oldAdmin,address newAdmin, bool status);
    
    function mintToken(address user,uint256 tokenId) external returns (uint256);
    function burnToken(uint256 tokenId) external;
    function addTokenMinter(address minter) external;
    function removeTokenMinter(address minter) external;
    function addTokenBurner(address burner) external;
    function removeTokenBurner(address burner) external;
    function hasMinterRole(address user) external view returns (bool);
    function hasBurnerRole(address user) external view returns (bool);
    function getOwnedTokenIds(address user) external view returns (uint256[] memory);
    function getAdmin()external view returns (address);
    function updateAdmin(address newAdmin) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function transferOwnerShip(address from,address to, uint256 tokenId) external;
    

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../token/SecurityToken-US/ERC20/IERC1400RawERC20.sol"; // This is to use transfer function
import "../../NFTwhitelist/IAkruNFTWhitelist.sol";
import ".././ISTO.sol";
// import "hardhat/console.sol";

//

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC1400RawERC20;
    // The Stable Coin
    IERC20 private _stableCoin;
    // The token being sold
    IERC1400RawERC20 public _token;

    // Address where funds are collected
    address private _wallet;
    // address private _feeAddress;
    // uint256 private _feePercent;
    // bool _feeStatus = false;
    uint256 internal _rate = 1000000000000000000000;

    // Whitelisting Address
    IAkruNFTWhitelist public whitelist;
    // Amount of wei raised
    uint256 internal _weiRaised; 
    address public STONonUSAddress;
    event TokensPurchased(address indexed purchaser,address indexed beneficiary,uint256 value,uint256 amount);
    /**
     * @param __rate Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param __token Address of the token being sold
     */
    constructor(
        uint256 __rate,
        IERC1400RawERC20 __token,
        IERC20 __stableCoin,
        IAkruNFTWhitelist _whitelist
    ) {
        require(__rate > 0, "STO44");
        require(address(__token) != address(0),"STO45");
        _rate = __rate;
        _token = __token;
        _wallet = address(0);
        _stableCoin = __stableCoin;
        whitelist = _whitelist;
    }
    /**
     * @dev Event Emits when someone write on BC
     */
    event ChangeStableCoinAddress(address sender,address oldStableCoin,address newStableCoin);
    event ChangeERC1400Address(address sender, address oldToken, address newToken);
    
    modifier onlyAdmin() virtual {
        require(whitelist.isWhitelistedUser(msg.sender) < 132, "STO0");
        _;
    }
    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    function stableCoin() public view returns (IERC20) {
        return _stableCoin;
    }
    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC1400RawERC20) {
        return _token;
    }
    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address) {
        return _wallet;
    }
    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view virtual returns (uint256) {
        return _rate;
    }
    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function tokenFallback(
        address beneficiary,
        uint256 stableCoins,
        bytes memory data
    ) public nonReentrant returns (bool success) {
       require(whitelist.isUserUSA(beneficiary),"STO50");
        uint256 targetTokens = stableCoins / _rate;
        _preValidatePurchase(beneficiary, stableCoins, targetTokens);
        uint256 tokens = _getTokenAmount(stableCoins);
        _weiRaised = _weiRaised + stableCoins;
        _processPurchase(beneficiary, tokens,data);
        emit TokensPurchased(_msgSender(), beneficiary, stableCoins, tokens);
        _processTransfer(beneficiary, stableCoins); // Manual Withdrawal and save Investor history for refund
        _updatePurchasingState(beneficiary, stableCoins);
        _postValidatePurchase(beneficiary, stableCoins);
        return true;
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised() + (weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     * @param targetTokens Value in wei involved in the purchase
     */
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount,
        uint256 targetTokens
    ) internal view virtual {
        require(
            beneficiary != address(0),
            "STO46"
        );
        require(weiAmount != 0, "STO47");
        require(targetTokens != 0, "STO48");

        this; // silence state mutability warning without generating bytecode -
        //see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(
        address beneficiary,
        uint256 weiAmount
    ) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount,bytes memory data) internal virtual {
        _token.transferWithData(beneficiary, tokenAmount,data);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(
        address beneficiary,
        uint256 tokenAmount,
        bytes memory data
    ) internal virtual {
        _deliverTokens(beneficiary, tokenAmount, data);
        
    }
    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(
        address beneficiary,
        uint256 weiAmount
    ) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }
    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(
        uint256 weiAmount
    ) internal view virtual returns (uint256) {
        return weiAmount * _rate;
    }

    /**
     * @dev Send Stable Coin the receiver address
     * @param stableAmount is the amount of stable coin deposited by investor
     * @param receiver  Address receiving the tokens
     */
    function _forwardTokens(address receiver, uint256 stableAmount) internal {
        bool isTransfer = _stableCoin.transfer(receiver, stableAmount);
        require(isTransfer);
    }

    /**
     * @dev Executed when a investment made needs to be transfered or stored
     * @param stableAmount Number of tokens to be purchased
     */
    function _processTransfer(
        address,
        uint256 stableAmount
    ) internal virtual {
        _forwardTokens(_wallet, stableAmount);
    }

    // Change Stable Coin Contract Address in STO
    function changeSTableCoinAddress(IERC20 stableCoin_) public onlyAdmin {
        _stableCoin = stableCoin_;
        emit ChangeStableCoinAddress(msg.sender,address(_stableCoin), address(stableCoin_) );
    }

    // Change ERC1400 Token Contract Address in STO
    function changeERC1400Address(IERC1400RawERC20 erc1400) public onlyAdmin {
        _token = erc1400;
        emit ChangeERC1400Address(msg.sender, address(_token), address(erc1400));
    }

 
    /**   
    Change rate/Price of per Token in STO
     */
    function changeSTORate(uint256 newRate) internal returns (uint256) {
        _rate = newRate;
        return _rate;
    }
     /**   
    Update mirror STO address
     */
    function updateNonUSSTOAddress(address _STONonUS) internal returns (bool) {
        STONonUSAddress = _STONonUS;
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../validation/TimedCrowdsale.sol";

/**
 * @title FinalizableCrowdsale
 * @dev Extension of TimedCrowdsale with a one-off finalization action, where one
 * can do extra work after finishing.
 */
abstract contract FinalizableCrowdsale is TimedCrowdsale {
    bool private _finalized;

    event CrowdsaleFinalized();

    constructor() {
        _finalized = false;
    }

    /**
     * @return true if the crowdsale is finalized, false otherwise.
     */
    function finalized() public view returns (bool) {
        return _finalized;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */


    function finalize() public onlyAdmin{
        require(!_finalized, "STO19");
        require(hasClosed(), "STO20");
        _finalized = true;
        emit CrowdsaleFinalized();
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super._finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function _finalization(
        uint256[] memory _noOfTokens,
        address[] memory _propertyOwners,
        bytes[] memory _certificates
    ) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }
}

// // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../validation/TimedCrowdsale.sol";
import "../../../token/SecurityToken-US/ERC20/IERC1400RawERC20.sol";
import "./RefundableCrowdsale.sol";

abstract contract PostGoalCrowdsale is TimedCrowdsale, RefundableCrowdsale {
    // to store balances of beneficiaries
    mapping(address => uint256) private _balances;
    // maintain list of total beneficiaries
    address[] public totalCrowdSaleCustomers;
    __unstable__TokenVault public _vault;

    constructor() {
        _vault = new __unstable__TokenVault();
    }

    /**
     * @dev Withdraw tokens only after crowdsale ends.
     * @param beneficiary is address of withdraw tokens to
     */
    function withdrawTokens(address beneficiary) public {
        require(goalReached(), "STO21");
        uint256 amount = _balances[beneficiary];
        require(
            amount > 0,
            "STO22"
        );
        _balances[beneficiary] = 0;
        _vault.transfer(token(), beneficiary, amount);
    }

    /**
     * @dev Withdraw tokens only after crowdsale ends.
     */
    function withdrawAllTokens() public {
        require(goalReached(), "STO21");
        for(uint8 i = 0 ; i < totalCrowdSaleCustomers.length ; i++){
        uint256 amount = _balances[totalCrowdSaleCustomers[i]];
        if(amount > 0)
        { 
        _balances[totalCrowdSaleCustomers[i]] = 0;
        _vault.transfer(token(), totalCrowdSaleCustomers[i], amount);
        }
        }
    }

    /**
     * @return the balance of an account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Executed when a investment made needs to be transfered or stored
     * @param stableAmount Number of tokens to be purchased
     */
    function _processTransfer(
        address /*investor*/,
        uint256 stableAmount
    ) internal virtual override(Crowdsale, RefundableCrowdsale) {}

    /**
         * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
         * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
         * `_deliverTokens` was called later).
         * @param beneficiary Token purchaser
         * @param tokenAmount Amount of tokens purchased
     */
    function _processPurchase(
        address beneficiary,
        uint256 tokenAmount,
        bytes memory data
    ) internal virtual override {
        if (_balances[beneficiary] == 0) {
            _balances[beneficiary] = _balances[beneficiary] + (tokenAmount);
            _deliverTokens(address(_vault), tokenAmount, data);
            totalCrowdSaleCustomers.push(beneficiary);
        } else {
            _balances[beneficiary] = _balances[beneficiary] + (tokenAmount);
            _deliverTokens(address(_vault), tokenAmount, data);
        }
    }
    
}

/**
 * @title __unstable__TokenVault
 * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
 * This contract is an internal helper for PostGoalCrowdsale, and should not be used outside of this context.
 */
// solhint-disable-next-line contract-name-camelcase
contract __unstable__TokenVault is Secondary {
    function transfer(
        IERC1400RawERC20 token,
        address to,
        uint256 amount
    ) public onlyPrimary {
        bool isTransfer = token.transfer(to, amount);
        require(isTransfer);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../../token/SecurityToken-US/ERC20/IERC1400RawERC20.sol"; // This is to use transfer function
//
import "./FinalizableCrowdsale.sol";

contract Secondary {
    address private _primary;

    event PrimaryTransferred(address recipient);

    /**
     * @dev Sets the primary account to the one that is creating the Secondary contract.
     */
    constructor() {
        _primary = msg.sender;
        emit PrimaryTransferred(_primary);
    }

    /**
     * @dev Reverts if called from any account other than the primary.
     */
    modifier onlyPrimary() {
        require(msg.sender == _primary);
        _;
    }

    /**
     * @return the address of the primary.
     */
    function primary() public view returns (address) {
        return _primary;
    }

    /**
     * @dev Transfers contract to a new primary.
     * @param recipient The address of new primary.
     */
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0));
        _primary = recipient;
        emit PrimaryTransferred(_primary);
    }
}

/**
 * @title RefundableCrowdsale
 * @dev Extension of `FinalizableCrowdsale` contract that adds a funding goal, and the possibility of users
 * getting a refund if goal is not met.
 *
 * Deprecated, use `RefundablePostDeliveryCrowdsale` instead. Note that if you allow tokens to be traded before the goal
 * is met, then an attack is possible in which the attacker purchases tokens from the crowdsale and when they sees that
 * the goal is unlikely to be met, they sell their tokens (possibly at a discount). The attacker will be refunded when
 * the crowdsale is finalized, and the users that purchased from them will be left with worthless tokens.
 */
abstract contract RefundableCrowdsale is FinalizableCrowdsale {
    // minimum amount of funds to be raised in weis
    uint256 private _goal;
    IERC1400RawERC20 private _securityToken;
    mapping(address => uint256) private __balances;
    // refund store used to hold funds while crowdsale is running
    __unstable__StableStore public _goalStore;

    /**
     * @param __goal Funding goal
     */
    constructor(uint256 __goal)  {
        require(__goal > 0, "STO23");
        _goalStore = new __unstable__StableStore();
        _goal = __goal;
        _securityToken = IERC1400RawERC20(address(token()));
    }

    /**
     * @return the refund balance of an account.
     */
    function refundAmount(address account) public view returns (uint256) {
        require(!goalReached(), "STO24");
        return __balances[account];
    }

    /**
     * @return minimum amount of funds to be raised in wei.
     */
    function goal() public view returns (uint256) {
        return _goal;
    }
    /**
     * @dev Investors can claim refunds here if crowdsale is unsuccessful.
     * @param refundee Whose refund will be claimed.
     */
    function claimRefund(address refundee) public {
        require(finalized(), "STO25");
        require(!goalReached(), "STO24");

        uint256 amount = __balances[refundee];
        require(
            amount > 0,
            "STO26"
        );

        __balances[refundee] = 0;
        _goalStore.transfer(stableCoin(), refundee, amount);
    }

    /**
     * @dev Checks whether funding goal was reached.
     * @return Whether funding goal was reached
     */
    function goalReached() public view returns (bool) {
        return _securityToken.totalSupply() >= _goal;
    }

    /**
     * @dev Escrow finalization task, called when finalize() is called.
     */
    function withdrawStable() public {
        require(goalReached(), "STO27");
        uint256 allStableCoin = stableCoin().balanceOf(address(_goalStore));
        address[] memory owners = _securityToken.propertyOwners();
        uint256[] memory shares = _securityToken.shares();
        uint256 length = shares.length;
        uint256 shareStableCoin;
        for (uint256 i = 0; i < length; ) {
            shareStableCoin = (allStableCoin * shares[i]) / 10000;
            _goalStore.transfer(stableCoin(), owners[i], shareStableCoin);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Determines how TKUSD is stored/forwarded on purchases.
     * @param stableAmount Number of tokens to be purchased
     * @param investor     Investor address who sent that money
     */
    function _processTransfer(
        address investor,
        uint256 stableAmount
    ) internal virtual override {
        __balances[investor] = __balances[investor] + (stableAmount);
        _forwardTokens(address(_goalStore), stableAmount);
    }
 /**
     * @dev Determines how TKUSD is stored/forwarded on purchases.
     * @param stableAmount Number of tokens to be purchased
     * @param investor     Investor address who sent that money
     */
    function _processTransferM(
        address investor,
        uint256 stableAmount
    ) internal   {
        __balances[investor] = __balances[investor] + (stableAmount);
        // _forwardTokens(address(_goalStore), stableAmount);
    }

    //change goal
    function changeGoal(uint256 newGoal_) internal returns (uint256) {
        _goal = newGoal_;
        return _goal;
    }
}
/**
 * @title __unstable__StableStore
 * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
 * This contract is an internal helper for PostGoalCrowdsale, and should not be used outside of this context.
 */
contract __unstable__StableStore is Secondary {
    function transfer(
        IERC20 token,
        address to,
        uint256 amount
    ) public onlyPrimary {
        bool isTransfer = token.transfer(to, amount);
        require(isTransfer);
    }

    function tokenFallback(
        address /*_from*/,
        uint256 /*_value*/,
        bytes memory
    ) public pure returns (bool success) {
        return true;
    }

    // Increase Goal By Admin
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../../token/SecurityToken-US/ERC20/IERC1400RawERC20.sol";
import "../Crowdsale.sol";

/**
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting.
 */

abstract contract MintedCrowdsale is Crowdsale {
    /**
     * @dev Overrides delivery by minting tokens upon purchase.
     * @param beneficiary Token purchaser
     * @param tokenAmount Number of tokens to be minted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount,bytes memory certificate) 
        override(Crowdsale)  virtual internal {
        require(
            IERC1400RawERC20(address(token())).issue(
                beneficiary,
                tokenAmount,
                certificate
            ),
            "STO29"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../../token/SecurityToken-US/ERC20/IERC1400RawERC20.sol"; // This is to use transfer function
import "../Crowdsale.sol";

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
abstract contract CappedCrowdsale is Crowdsale {
    uint256 private _cap;
    uint256 internal _debtTokens;
    IERC1400RawERC20 private _securityToken;

    /**
     * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
     * @param __cap Max amount of wei to be contributed
     */
    constructor(uint256 __cap)  {
        require(__cap > 0, "STO33");
        _cap = __cap;
        _securityToken = IERC1400RawERC20(address(token()));
    }
   /**
    * @dev Add Events
    */
   event AddDebtToken(address sender,uint256 debtTokens);
    /**
     * @return the cap of the crowdsale.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return _securityToken.totalSupply() >= _cap;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount,
        uint256 targetTokens
    ) internal view virtual override {
        
        super._preValidatePurchase(beneficiary, weiAmount, targetTokens);
        require((_securityToken.totalSupply() + (targetTokens) + (_debtTokens)) <= _cap, 
        "STO34"
        );
    }

    /**
     * @dev this will keep track of debt tokens
     * @param debtTokens value of debt tokens locked
     */
    function addDebtTokens(uint256 debtTokens) public onlyAdmin {
        _debtTokens = debtTokens;
        emit AddDebtToken(msg.sender, debtTokens);
    }

    /**
     * @dev this will keep track of debt tokens
     * @param debtTokens value of debt tokens locked
     */
    function _updateDebtTokens(uint256 debtTokens) internal {
        _debtTokens = debtTokens;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../Crowdsale.sol";

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedCrowdsale is Crowdsale {
    uint256 private _openingTime;
    uint256 private _closingTime;
    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event TimedCrowdsaleExtended(
        uint256 prevClosingTime,
        uint256 newClosingTime
    );

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "STO40");
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param __openingTime Crowdsale opening time
     * @param __closingTime Crowdsale closing time
     */
    constructor(uint256 __openingTime, uint256 __closingTime) {
        // solhint-disable-next-line not-rely-on-time
        require(
            __openingTime >= block.timestamp,
            "STO36"
        );
        // solhint-disable-next-line max-line-length
        require(
            __closingTime > __openingTime,
            "STO37"
        );
        _openingTime = __openingTime;
        _closingTime = __closingTime;
    }

    //Modifier for only Tokenism Admin Can
    modifier onlyAdmin() override(Crowdsale) virtual{
        require(whitelist.isWhitelistedUser(_msgSender()) < 132, "STO0");
        _;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return
            block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount,
        uint256 targetTokens
    ) internal view virtual override onlyWhileOpen {
        super._preValidatePurchase(beneficiary, weiAmount, targetTokens);
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function extendTime(uint256 newClosingTime) public onlyAdmin {
        // require(!hasClosed(), "STO38");
        // solhint-disable-next-line max-line-length
        require(
            newClosingTime > block.timestamp,
            "STO39"
        );
        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import "../token/SecurityToken-US/ERC20/IERC1400RawERC20.sol";
/**
 * @title STO Interface
 * @dev STO logic
 */
interface ISTO{
   function rate() external view returns (uint256);
    function token() external view returns (IERC1400RawERC20);
    function reserveWallet() external view returns (address);
    function callPostGoalProcessPurchase(address beneficiary, uint256 tokenAmount,  bytes memory data)  external returns (bool);
    function updateGoal(uint256 newGoal) external returns (uint256);
    function increaseSTORate(uint256 rate) external returns (uint256);
    function finalize() external ;
    function extendTime(uint256 newClosingTime) external ;
    function STONonUSAddress() external view;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../NFTwhitelist/IAkruNFTWhitelist.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./crowdsale/Crowdsale.sol";
import "./crowdsale/emission/MintedCrowdsale.sol";
import "./crowdsale/validation/CappedCrowdsale.sol";
import "./crowdsale/validation/TimedCrowdsale.sol";
import "./crowdsale/distribution/PostGoalCrowdsale.sol";
import "./crowdsale/distribution/RefundableCrowdsale.sol";
import "./ISTO.sol";
 /**
  * Code Detail used in require statment of STO
     * STO0: Only admin is allowed
     * STO1: Only deployed by admin Or manager of Tokenism
     * STO2: Issue in eth Rate
     * STO3: Property value must be divisble by Rate
     * STO4: Goal cannot be greater than Cap
     * STO5: Only SuperAdmin is allowed
     * STO6: STO is Already Closed
     * STO7: Investment is less than Minimum Invest Limit
     * STO8: Invest amount must be multiple of _rate
     * STO9: You have need to Upgrade Premium Account
     * STO10: Cap already reached
     * STO11: Please Provide correct rate
     * STO12: New rate should not be equal to existing rate
     * STO13: Contract address cannot update Goal
     * STO14: Goal is reached
     * STO15: Provide goal greater that zero
     * STO16: Tokens minted must be less than New Goal
     * STO17: New goal should not be equal to existing goal
     * STO18: Goal cannot be greater than Cap
     * STO19: FinalizableCrowdsale: already finalized
     * STO20: FinalizableCrowdsale: not closed
     * STO21: PostGoalCrowdsale: Goal not reached
     * STO22: PostGoalCrowdsale: beneficiary is not due any tokens
     * STO23: RefundableCrowdsale: goal is 0
     * STO24: RefundableCrowdsale: goal reached
     * STO25: RefundableCrowdsale: not finalized
     * STO26: RefundableCrowdsale: refundee is not due any tokens
     * STO27: RefundableCrowdsale: goal not reached
     * STO28: AllowanceCrowdsale: token wallet is the zero address
     * STO29: MintedCrowdsale: minting failed
     * STO30: IncreasingPriceCrowdsale: final rate is 0
     * STO31: IncreasingPriceCrowdsale: initial rate is not greater than final rate
     * STO32: IncreasingPriceCrowdsale: rate() called
     * STO33: CappedCrowdsale: cap is 0
     * STO34: CappedCrowdsale: cap exceeded
     * STO35: IndividuallyCappedCrowdsale: beneficiary's cap exceeded
     * STO36: TimedCrowdsale: opening time is before current time
     * STO37: TimedCrowdsale: opening time is not before closing time
     * STO38: TimedCrowdsale: already closed
     * STO39: TimedCrowdsale: new closing time is before current time
     * STO40: TimedCrowdsale: not open
     * STO41: WhitelistCrowdsale: beneficiary doesn't have the Whitelisted role
     * STO42: capPercent should be from 0 to 100
     * STO43: capPercent should be the same as previous
     * STO44: Crowdsale: rate is 0
     * STO45: Crowdsale: token is the zero address
     * STO46: Crowdsale: beneficiary is the zero address
     * STO47: Crowdsale: weiAmount is 0
     * STO48: Crowdsale: targetTokens is 0
     * STO50: Crowdsale: Only US investor can invest
     * STO51: New Rate should be have ratio same as before
     * STO52: Price should be properly Divisible in US and Non US 
  */
contract STO_US is
    Crowdsale,
    MintedCrowdsale,
    CappedCrowdsale,
    TimedCrowdsale,
    RefundableCrowdsale,
    PostGoalCrowdsale
{
    // Track investor contributions
    mapping(address => uint256)  contributions;
    // Crowdsale Stages
    enum CrowdsaleStage {
        PreICO,
        ICO
    }
    CrowdsaleStage public stage = CrowdsaleStage.PreICO;
    uint256 public propertyValue;
    uint256 internal initialRate;
    uint256 public debtTokens;
    uint256 public developerToken;
    uint256 public capPercent = 20;
    constructor(
        uint256 __rate,
        IERC1400RawERC20 __token, // Property Token
        IERC20 __stableCoin, // Stable Coin
        IAkruNFTWhitelist __whitelist, // Whitelist Contract
        uint256 __propertyValue,
        uint256 __cap,
        uint256 __goal,
        uint256 __debtTokens,
        uint256 __developerToken,
        uint256 __openingTime,
        uint256 __closingTime
    )
        Crowdsale(__rate, __token, __stableCoin, __whitelist)
        CappedCrowdsale(__cap)
        TimedCrowdsale(__openingTime, __closingTime)
        RefundableCrowdsale(__goal)
    {
        require(
            __whitelist.isWhitelistedUser(msg.sender) < 132,
            "STO1"
        );
        require(
            __propertyValue % (__rate / 1 ether) == 0,
            "STO3"
        );
        require(__goal <= __cap, "STO4");
        developerToken = __developerToken;
        propertyValue = __propertyValue;
        debtTokens = __debtTokens;
        super._updateDebtTokens(__debtTokens);
        initialRate = __rate;
    }
   /**
    * 
    * @dev Events that Triggering in STO
    */
   event UpdateCapPercent(address sender,uint256 newCapPercent, uint256 oldCapPercent);
   event ChangeWhitelist(address sender, address newWhitelist, address oldWhitelist);
   event IncreaseSTORate(address sender, uint256 rate);
   event SetNewNonUSSTOAddress(address sender, address NonUSSTOAddress);
   event UpdateGoal(address sender,uint256 newGoal,uint256 oldGoal);
    /**
     * 
     * @dev Modifiers to check before Executing
     */
    modifier onlyAdmin() override(Crowdsale ,TimedCrowdsale){
        require(Crowdsale.whitelist.isWhitelistedUser(msg.sender) < 132, "STO0");
        _;
    }
    modifier onlySuperAdmin() {
        require(
            whitelist.isSuperAdmin(_msgSender()),
            "STO5"
        );
        _;
    }
    /**
        * @dev capPercent is the amount in which normal user can buy
        * @param newCapPercent new cap percent
    */
    function updateCapPercent(uint256 newCapPercent)
    public 
    onlyAdmin
    {
        require(newCapPercent>=0 && newCapPercent<=100,"STO42");
        require(newCapPercent != capPercent,"STO43");
        emit UpdateCapPercent(msg.sender, newCapPercent,capPercent);
        capPercent = newCapPercent;
    } 
    // /**
    //  * @dev Returns the amount contributed so far by a sepecific user.
    //  * @param beneficiary Address of contributor
    //  * @return User contribution so far
    //  */
    // function getUserContribution(
    //     address beneficiary
    // ) public view returns (uint256) {
    //     return contributions[beneficiary];
    // }
    /**
     * @dev Determines Number of the tokens
     * @param _weiAmount amount in the wei
     */
    function _getTokenAmount(
        uint256 _weiAmount
    ) internal view override returns (uint256) {
        return _weiAmount / _rate;
    }
    /**
     * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
     * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
     * `_deliverTokens` was called later).
     * @param _beneficiary Token purchaser
     * @param _weiAmount Amount of wei
     * @param _targetTokens Amount of tokens to be purchase
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _targetTokens
    )
        internal
        view
        virtual
        override(CappedCrowdsale, TimedCrowdsale, Crowdsale)
    {
        require(
            _weiAmount >= _rate,
            "STO7"
        );
        require(
            (_weiAmount - (_rate * (_targetTokens))) % (_rate) == 0,
            "STO8"
        );
        if (
            (contributions[_beneficiary] + (_weiAmount)) / (1 ether) >
            basicCap()
        ) {
            require(
                whitelist.isPremiumUser(_beneficiary),
                "STO9"
            );
        }
        super._preValidatePurchase(_beneficiary, _weiAmount, _targetTokens);
    }
    /**
     * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
     * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
     * `_deliverTokens` was called later).
     * @param _beneficiary Token purchaser
     * @param _tokenAmount Amount of tokens purchased
     */
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount,
        bytes memory _data
    ) internal override(PostGoalCrowdsale, Crowdsale) {
         ISTO stoNonUS = ISTO(STONonUSAddress);
        address reserveWalletNonUS = IERC1400RawERC20(address(stoNonUS.token())).reserveWallet();
       if (stage == CrowdsaleStage.ICO)
        {
            _deliverTokens(_beneficiary, _tokenAmount, _data);
            uint256 totalTokens = _tokenAmount * (rate()/stoNonUS.rate());
             IERC1400RawERC20(address(stoNonUS.token())).issue(reserveWalletNonUS,totalTokens,"0x00");
        }
        else {
             super._processPurchase(_beneficiary, _tokenAmount, _data);
             uint256 totalTokens = _tokenAmount * (rate()/stoNonUS.rate());
             stoNonUS.callPostGoalProcessPurchase( reserveWalletNonUS,  totalTokens, "0x00");
        }
    }
    /**
     * @dev If goal is Reached then change to ICO Stage
     * etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount
    ) internal override {
        contributions[_beneficiary] +=  (_weiAmount);
        if (isOpen() && goalReached() && stage == CrowdsaleStage.PreICO)
            stage = CrowdsaleStage.ICO;
        super._updatePurchasingState(_beneficiary, _weiAmount);
    }
    /**
     * @dev Determines how TKUSD is stored/forwarded on purchases.
     * @param stableAmount Number of tokens to be purchased
     * @param investor     Investor address who sent that money
     */
    function _processTransfer(
        address investor,
        uint256 stableAmount
    ) internal override(Crowdsale, RefundableCrowdsale, PostGoalCrowdsale) {
        if (stage == CrowdsaleStage.ICO) {
            address[] memory owners = _token.propertyOwners();
            uint256[] memory shares = _token.shares();
            uint256 length = shares.length;
            uint256 shareStableCoin;
            for (uint256 i = 0; i < length; ) {
                shareStableCoin = (stableAmount * shares[i]) / 10000;
                _forwardTokens(owners[i], shareStableCoin);
                unchecked {
                    i++;
                }
            }
        } else {
            super._processTransfer(investor, stableAmount);
            RefundableCrowdsale._processTransfer(investor, stableAmount);
        }
    }
    /**
     * @dev Update the whitelist address.
     * @param whitelist address of the new whitelist
     */
    function changeWhitelist(
        IAkruNFTWhitelist whitelist
    ) public onlyAdmin returns (bool) {
        emit ChangeWhitelist(msg.sender, address(whitelist), address(whitelist));
        whitelist = whitelist;
        return true;
    }
    function _deliverTokens(address beneficiary, uint256 tokenAmount,bytes memory _data) 
      internal override(Crowdsale , MintedCrowdsale) {
      super._deliverTokens(beneficiary , tokenAmount,_data);
    }
    /**
     * @dev Get Basic Cap For User Contribution
     */
    function basicCap() public view returns (uint256) {
        return ((propertyValue * (capPercent) )/ (100 * 1 ether));
    }
    /**
     * @dev Increase STO Rate
     * @param rate new rate of the STO
     */
    function increaseSTORate(uint256 rate) public returns (uint256) {
        require(!capReached(), "STO10");
        require(
            (whitelist.isSuperAdmin(_msgSender()) || whitelist.isAdmin(_msgSender())),
            "STO5"
        );
        require(rate > 0, "STO11");
        require(rate != _rate, "STO12");
        uint256 tokenMultiple = _rate/ISTO(STONonUSAddress).rate();
        uint256 nonUSRate = rate/tokenMultiple;
        require(rate/nonUSRate == tokenMultiple,"STO51");
        require(rate % nonUSRate == 0, "STO52");
        // uint256 totalSold = _token.totalSupply();
        // uint256 remainingToken = cap() - totalSold;
        // uint256 newPValue = (totalSold * _rate/1 ether) + (remainingToken * (rate/1 ether));
        // propertyValue = newPValue;
        ISTO(STONonUSAddress).increaseSTORate(nonUSRate);
        _rate = rate;
        emit IncreaseSTORate(msg.sender, rate);
        return super.changeSTORate(rate);
    }
    /**
     * @dev change goal of the STO
     * @param newGoal new goal of the STO
     */
    function updateGoal(uint256 newGoal) external returns (uint256) {
        require((whitelist.isSuperAdmin(_msgSender()) || whitelist.isSubSuperAdmin(_msgSender())), "STO5" );
        require(!goalReached(), "STO14");
        require(newGoal > 0, "STO15");
        require((newGoal != goal()), "STO17");
        require(newGoal <= cap(), "STO18");
        emit UpdateGoal(msg.sender,newGoal,goal());
        uint256 newNonUSGoal = newGoal * rate()/ISTO(STONonUSAddress).rate();
        ISTO(STONonUSAddress).updateGoal(newNonUSGoal);
        return changeGoal(newGoal);
    }
    /**
     * @dev Get Remaining unsold Tokens of the STO
     */
    function getRemainingTokens()
        public
        view
        returns (uint256 _remainingTokens)
    {
        IERC1400RawERC20 _securityToken = IERC1400RawERC20(address(token()));
        uint256 _alreadyMinted = _securityToken.totalSupply();
        uint256 _finalTotalSupply = (propertyValue / (initialRate)) -
            (debtTokens);
        _remainingTokens = _finalTotalSupply - _alreadyMinted;
        return _remainingTokens;
    }
     /**
     * @dev Set address for Non US STO
     */
    function setNonUSSTOAddress(address nonUsSTO) public onlyAdmin returns(bool success)
    {   
        require(!goalReached(), "STO14");
        require(!hasClosed(),"STO6");
        emit SetNewNonUSSTOAddress(msg.sender, nonUsSTO);
        return super.updateNonUSSTOAddress(nonUsSTO);
    }
    /**
     * @dev callPostGoalProcessPurchase
     */
    function callPostGoalProcessPurchase( address beneficiary, uint256 tokenAmount,  bytes memory data)  external onlyAdmin returns (bool) {
         super._processPurchase(beneficiary, tokenAmount, data);
         return true;
    }
     /**
     * @dev finalize both STO US & Non-US
     */
    function dataMigerate(address beneficiary, uint256 tokenAmount, bytes memory data) external onlyAdmin returns (bool) {
        super._processPurchase(beneficiary,tokenAmount, data);
        ISTO stoNonUS = ISTO(STONonUSAddress);
        address reserveWalletNonUS = IERC1400RawERC20(address(stoNonUS.token())).reserveWallet();
        uint256 totalTokens = tokenAmount * (rate()/stoNonUS.rate());
        stoNonUS.callPostGoalProcessPurchase( reserveWalletNonUS,  totalTokens, "0x00");
        uint256 stableAmount = tokenAmount * rate();
        RefundableCrowdsale._processTransferM(beneficiary, stableAmount);   
        _updatePurchasingState(beneficiary,stableAmount);    
        return true;     
    }
    function finalizeSTO() external onlyAdmin {
         finalize();
         ISTO(STONonUSAddress).finalize();
    }
    /**
     * @dev ExtendTimeo both STO US & Non-US
     */
    function extendTimeSTO(uint256 newClosingTime) public onlyAdmin{
         extendTime(newClosingTime);
         ISTO(STONonUSAddress).extendTime(newClosingTime);
    }
    /**
     * @dev Destruct STO Contract Address
     */
    function closeSTO() public onlySuperAdmin {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../../NFTwhitelist/IAkruNFTWhitelist.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../MarginLoan/IMarginLoan.sol";
import "./IERC1400Raw.sol";
/**
 * @title ERC1400RawERC20
 * @dev ERC1400Raw with ERC20 retrocompatibility
 *  @author AKRU's Dev team
 */
contract ERC1400Dividends {
    IAkruNFTWhitelist whitelist_;
    IMarginLoan marginLoan_;
    IERC1400Raw ierc1400raw;
    address[]  investors;
    mapping(address => bool) dividends; 
    mapping (address => uint256)  exchangeBalance;

    constructor(IAkruNFTWhitelist whitelist, IMarginLoan _IMarginLoan , IERC1400Raw ierc1400raw_) {
        whitelist_ = whitelist;
        marginLoan_ = _IMarginLoan;
        ierc1400raw = ierc1400raw_;
    }

    // Event Emit when Dividend distribute
    event DstributeDividends(
        address _token,
        address from,
        address to,
        uint256 userDividents,
        string message
    );
    // Only Transfer on Tokenism Plateform
    modifier onlyAdmin() virtual {
        require(whitelist_.isWhitelistedUser(msg.sender) < 132, "ST0");
        _;
    }
    modifier onlyPropertyOwner(){
        require(whitelist_.isOwner(msg.sender) ||  whitelist_.isAdmin(msg.sender), 
                "ST18");
        _;
    }
    /**
     * @dev add the investor
     * @param investor address of the investor
     * @return status
     */
    function addInvestor(address investor)
        internal
        onlyAdmin
        returns (bool)
    {
        if (!Address.isContract(investor)) {
            if (!dividends[investor]) {
                dividends[investor] = true;
                investors.push(investor);
            }
        }
        return true;
    }
    /**
     * @dev set the exchange according to the distribution
     * @param investor address of the investor
     * @param balance no of token to distribute
     * @return status
     */
    function addFromExchangeDistribution(address investor, uint256 balance)
        public
        onlyAdmin
        returns (bool)
    {
        if (!Address.isContract(investor)) {
            exchangeBalance[investor] =
                exchangeBalance[investor] +
                (balance);
        }
        return true;
    }
    /**
     * @dev update the exchange according to the distribution
     * @param _investor address of the investor
     * @param _balance no of token to distribute
     * @return status
     */
    function updateFromExchangeDistribution(address _investor, uint256 _balance)
        public
        onlyAdmin
        returns (bool)
    {
        if (!Address.isContract(_investor)) {
            exchangeBalance[_investor] = exchangeBalance[_investor] - _balance;
        }
        return true;
    }
    /**
     * @dev set the exchange according to the distribution
     * @param _token address of property token to distribute
     * @param _dividends address of the investor
     * @param totalSupply max no. of token minted
     */
    function distributeDividends(
        address _token,
        uint256 _dividends,
        uint256 totalSupply
    ) public onlyPropertyOwner {
        bool isTransfer;
        uint256 userValue;
        require(
            investors.length > 0,
            "ST19"
        );
        require(IERC20(_token).balanceOf(msg.sender) >= _dividends , "ST20");
        for (uint256 i = 0; i < investors.length; i++) {
            uint256 value = ierc1400raw.balanceOf(investors[i]);
            value = value + (exchangeBalance[investors[i]]);
            if (value >= 1) {
                userValue = (_dividends * (value)) / (totalSupply);
                if(userValue >= 1){
                    isTransfer = IERC20(_token).transferFrom(msg.sender, investors[i], userValue); 
                    emit DstributeDividends(
                        address(ierc1400raw),
                        msg.sender, 
                        investors[i],
                        userValue,
                        "Dividends transfered"
                    );
                }
            }
            unchecked {
                i++;
            }
        }
    }
    /**
     * @dev get no of the investor
     * @return investors investors array
     */
    function getInvestors() public view returns (address[] memory) {
        return investors;
    }

    /**
     * @dev set new margin loan contract address
     * @param _ImarginLoan new address of margin loan
     */
    function newMarginLoanContract(IMarginLoan _ImarginLoan) public onlyAdmin{
        require(Address.isContract(address(_ImarginLoan)),"ST21");
      marginLoan_ = _ImarginLoan;
    }
         /**
     * @dev get alldata of the user on whick distribution taken place
     * @return _investors array of investors
     * @return _balances array of their balances
     */
function getAllData() public view onlyAdmin returns(address[] memory _investors, uint256[] memory _balances) {
    uint256[] memory balances = new uint256[](investors.length);
    for (uint8 i = 0; i < investors.length; i++) {
    balances[i] = exchangeBalance[investors[i]];
    }  
    return (investors , balances);        
} 
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC1820/ERC1820Client.sol";
import "../ERC1820/ERC1820Implementer.sol";
import "../../../NFTwhitelist/IAkruNFTWhitelist.sol";
import "../../../CertificateController/CertificateController.sol";
import "../../../MarginLoan/IMarginLoan.sol";
import "./IERC1400Raw.sol";
import "./IERC1400TokensSender.sol";
import "./IERC1400TokensValidator.sol";
import "./IERC1400TokensRecipient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ERC1400Dividends.sol";

/**
 * @title ERC1400RawERC20
 * @dev ERC1400Raw with ERC20 retrocompatibility
 * @author AKRU's Dev team
 */
contract ERC1400Raw is
    IERC1400Raw,
    Ownable,
    ERC1820Client,
    ERC1820Implementer,
    CertificateController,
    ERC1400Dividends
{
    string internal constant ERC1400_TOKENS_SENDER = "ERC1400TokensSender";
    string internal constant ERC1400_TOKENS_VALIDATOR = "ERC1400TokensValidator";
    string internal constant ERC1400_TOKENS_RECIPIENT = "ERC1400TokensRecipient";
    string internal name_;
    string internal _symbol;
    uint256 internal _granularity;
    uint256 internal _totalSupply;
    uint256 public _cap; 
    // uint8 _capCounter; 
    bool internal _migrated;
    mapping(address => uint256) internal _balances;
    // Maitain list of all stack holder
    address[] public tokenHolders;
    mapping(address => uint8) public isAddressExist;
    // Cap for User investment Basic and Premium User
    uint8 basicPercentage = 20;
    /******************** Mappings related to operator **************************/
    // Mapping from (operator, tokenHolder) to authorized status. [TOKEN-HOLDER-SPECIFIC]
    mapping(address => mapping(address => bool)) internal _authorizedOperator;
    // Array of controllers. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
    address[] internal _controllers;
    // Mapping from operator to controller status. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
    mapping(address => bool) internal _isController;

    /**
     * @dev Modifier to make a function callable only when the contract is not migrated.
     */
    modifier whenNotMigrated() {
        require(!_migrated, "A8");
        _;
    }

    /**
     * [ERC1400Raw CONSTRUCTOR]
     * @dev Initialize ERC1400Raw and CertificateController parameters + register
     * the contract implementation in ERC1820Registry.
     * @param name__ Name of the token.
     * @param __symbol Symbol of the token.
     * @param __granularity Granularity of the token.
     * @param __controllers Array of initial controllers.
     * @param certificateSigner Address of the off-chain service which signs the
     * conditional ownership certificates required for token transfers, issuance,
     * redemption (Cf. CertificateController.sol).
     * @param certificateActivated If set to 'true', the certificate controller
     * is activated at contract creation.
     */
    constructor(
        string memory name__,
        string memory __symbol,
        uint256 __granularity,
        address[] memory __controllers,
        address certificateSigner,
        bool certificateActivated,
        IAkruNFTWhitelist whitelist,
        IMarginLoan _IMarginLoan
        // uint256 cap_
    )
        CertificateController(
            certificateSigner,
            certificateActivated,
            whitelist
        )
        ERC1400Dividends(whitelist, _IMarginLoan, IERC1400Raw(address(this)))
    {
        whitelist_ = whitelist;
        require(
            // whitelist_.isManager(msg.sender) || whitelist.isAdmin(msg.sender),
            whitelist_.isWhitelistedUser(msg.sender) <= 125,
            "ST9"
        );
        require(
            whitelist.addSymbols(__symbol),
            "ST10"
        );
        // Constructor Blocked - Token granularity can not be lower than 1
        require(__granularity >= 1, "ST11"); 
        name_ = name__;
        _symbol = __symbol;
        _totalSupply = 0;
        _granularity = __granularity;
        _setControllers(__controllers);
        // _cap = cap_;
    }

    modifier onlyAdmin() virtual override(ERC1400Dividends) {
        require(whitelist_.isWhitelistedUser(msg.sender) < 132, "Only admin is allowed");
        _;
    }

    // Only Transfer on Tokenism Plateform
    modifier onlyTokenism(address _sender, address _receiver) virtual  {
        uint256 codeS = whitelist_.isWhitelistedUser(_sender);
        uint256 codeR = whitelist_.isWhitelistedUser(_receiver);
        require(
                codeS < 120 ||
                codeR < 120,
            "ST1"
        );
        _;
    }

    modifier onlyAKRUAuthorization(address _sender, address _receiver) virtual {
        uint256 codeS = whitelist_.isWhitelistedUser(_sender);
        uint256 codeR = whitelist_.isWhitelistedUser(_receiver);
        require(
                (codeS < 201 && (codeR < 121 || codeR == 140)), 
            "ST12"
        );
        _;
    }

    /********************** ERC1400Raw EXTERNAL FUNCTIONS ***************************/

    /**
     * [ERC1400Raw INTERFACE (1/13)]
     * @dev Get the name of the token, e.g., "MyToken".
     * @return Name of the token.
     */
    function name() external view override returns (string memory) {
        return name_;
    }

    /**
     * [ERC1400Raw INTERFACE (2/13)]
     * @dev Get the symbol of the token, e.g., "MYT".
     * @return Symbol of the token.
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * [ERC1400Raw INTERFACE (3/13)]
     * @dev Get the total number of issued tokens.
     * @return Total supply of tokens currently in circulation.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * [ERC1400Raw INTERFACE (4/13)]
     * @dev Get the balance of the account with address 'tokenHolder'.
     * @param tokenHolder Address for which the balance is returned.
     * @return Amount of token held by 'tokenHolder' in the token contract.
     */
    function balanceOf(
        address tokenHolder
    ) public view virtual override returns (uint256) {
        return _balances[tokenHolder];
    }

    /**
     * [ERC1400Raw INTERFACE (5/13)]
     * @dev Get the smallest part of the token that’s not divisible.
     * @return The smallest non-divisible part of the token.
     */
    function granularity() public view override returns (uint256) {
        return _granularity;
    }

    /**
     * [ERC1400Raw INTERFACE (6/13)]
     * @dev Get the list of controllers as defined by the token contract.
     * @return List of addresses of all the controllers.
     */
    function controllers() external view override returns (address[] memory) {
        return _controllers;
    }

    /**
     * [ERC1400Raw INTERFACE (7/13)]
     * @dev Set a third party operator address as an operator of 'msg.sender' to transfer
     * and redeem tokens on its behalf.
     * @param operator Address to set as an operator for 'msg.sender'.
     */
    function authorizeOperator(
        address operator
    ) external override onlyAKRUAuthorization(msg.sender, operator) {
        require(operator != msg.sender);
        _authorizedOperator[operator][msg.sender] = true;
        emit AuthorizedOperator(operator, msg.sender);
    }

    /**
     * [ERC1400Raw INTERFACE (8/13)]
     * @dev Remove the right of the operator address to be an operator for 'msg.sender'
     * and to transfer and redeem tokens on its behalf.
     * @param operator Address to rescind as an operator for 'msg.sender'.
     */
    function revokeOperator(
        address operator
    ) external override onlyAKRUAuthorization(msg.sender, operator) {
        require(operator != msg.sender);
        _authorizedOperator[operator][msg.sender] = false;
        emit RevokedOperator(operator, msg.sender);
    }

    /**
     * [ERC1400Raw INTERFACE (9/13)]
     * @dev Indicate whether the operator address is an operator of the tokenHolder address.
     * @param operator Address which may be an operator of tokenHolder.
     * @param tokenHolder Address of a token holder which may have the operator address as an operator.
     * @return 'true' if operator is an operator of 'tokenHolder' and 'false' otherwise.
     */
    function isOperator(
        address operator,
        address tokenHolder
    ) external view override returns (bool) {
        return _isOperator(operator, tokenHolder);
    }

    /**
     * [ERC1400Raw INTERFACE (10/13)]
     * @dev Transfer the amount of tokens from the address 'msg.sender' to the address 'to'.
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer, by the token holder.
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function transferWithData(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyTokenism(msg.sender, to) override isValidCertificate(data) {
        _callPreTransferHooks("", msg.sender, msg.sender, to, value, data, "");
        _transferWithData(msg.sender, msg.sender, to, value, data, "");
        _callPostTransferHooks("", msg.sender, msg.sender, to, value, data, "");
    }

    /**
     * [ERC1400Raw INTERFACE (11/13)]
     * @dev Transfer the amount of tokens on behalf of the address 'from' to the address 'to'.
     * @param from Token holder (or 'address(0)' to set from to 'msg.sender').
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer, and intended for the token holder ('from').
     * @param operatorData Information attached to the transfer by the operator.
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function transferFromWithData(
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external onlyTokenism(msg.sender, to) isValidCertificate(operatorData)  override{
        require(_isOperator(msg.sender, from), "ST7"); 

        _callPreTransferHooks(
            "",
            msg.sender,
            from,
            to,
            value,
            data,
            operatorData
        );

        _transferWithData(msg.sender, from, to, value, data, operatorData);

        _callPostTransferHooks(
            "",
            msg.sender,
            from,
            to,
            value,
            data,
            operatorData
        );
        addInvestor(to);
    }

    /**
     * [ERC1400Raw INTERFACE (12/13)]
     * @dev Redeem the amount of tokens from the address 'msg.sender'.
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption, by the token holder.
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function redeem(
        uint256 value,
        bytes calldata data
    )
        external
        override
       onlyTokenism(msg.sender, msg.sender)
        isValidCertificate(data)
    {
        _callPreTransferHooks(
            "",
            msg.sender,
            msg.sender,
            address(0),
            value,
            data,
            ""
        );
        _redeem(msg.sender, msg.sender, value, data, "");
    }
    /**
     * [ERC1400Raw INTERFACE (13/13)]
     * @dev Redeem the amount of tokens on behalf of the address from.
     * @param from Token holder whose tokens will be redeemed (or address(0) to set from to msg.sender).
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption.
     * @param operatorData Information attached to the redemption, by the operator.
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function redeemFrom(
        address from,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) public override onlyTokenism(msg.sender, from) isValidCertificate(operatorData) {
        require((_isOperator(msg.sender, from) || (whitelist_.isWhitelistedUser(msg.sender) < 102)), "ST7"); 
        _callPreTransferHooks(
            "",
            msg.sender,
            from,
            address(0),
            value,
            data,
            operatorData
        );
        _redeem(msg.sender, from, value, data, operatorData);
    }

    /********************** ERC1400Raw INTERNAL FUNCTIONS ***************************/
    /**
     * [INTERNAL]
     * @dev Indicate whether the operator address is an operator of the tokenHolder address.
     * @param operator Address which may be an operator of 'tokenHolder'.
     * @param tokenHolder Address of a token holder which may have the 'operator' address as an operator.
     * @return 'true' if 'operator' is an operator of 'tokenHolder' and 'false' otherwise.
     */
    function _isOperator(
        address operator,
        address tokenHolder
    ) internal view returns (bool) {
        return (operator == tokenHolder ||
            _authorizedOperator[operator][tokenHolder] ||
            (_isController[operator]));
    }

    /**
     * [INTERNAL]
     * @dev Perform the transfer of tokens.
     * @param operator The address performing the transfer.
     * @param from Token holder.
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer.
     * @param operatorData Information attached to the transfer by the operator (if any)..
     */
    function _transferWithData(
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal whenNotMigrated virtual{
        require(to != address(0), "ST6"); 
        require(_balances[from] >= value, "ST4"); 
        uint256 whitelistStatus = whitelist_.isWhitelistedUser(to);
        require(whitelistStatus <= 200, "ST14");
        _balances[from] = _balances[from] - (value);
        _balances[to] = _balances[to] + (value);
        if (isAddressExist[to] != 1 && !Address.isContract(to)) {
            tokenHolders.push(to);
            isAddressExist[to] = 1;
            addInvestor(to);
        }
        emit TransferWithData(operator, from, to, value, data, operatorData);
    }

    /**
     * [INTERNAL]
     * @dev Perform the token redemption.
     * @param operator The address performing the redemption.
     * @param from Token holder whose tokens will be redeemed.
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption.
     * @param operatorData Information attached to the redemption, by the operator (if any).
     */
    function _redeem(
        address operator,
        address from,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal whenNotMigrated virtual  {
        require(from != address(0), "ST5"); 
        require(_balances[from] >= value, "ST4"); 
        _balances[from] = _balances[from] - (value);
        _totalSupply = _totalSupply - (value);
        emit Redeemed(operator, from, value, data, operatorData);
    }

    /**
     * [INTERNAL]
     * @dev Check for 'ERC1400TokensSender' hook on the sender + check for 'ERC1400TokensValidator' on the token
     * contract address and call them.
     * @param partition Name of the partition (bytes32 to be left empty for ERC1400Raw transfer).
     * @param operator Address which triggered the balance decrease (through transfer or redemption).
     * @param from Token holder.
     * @param to Token recipient for a transfer and 0x for a redemption.
     * @param value Number of tokens the token holder balance is decreased by.
     * @param data Extra information.
     * @param operatorData Extra information, attached by the operator (if any).
     */
    function _callPreTransferHooks(
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal {
        address senderImplementation;
        senderImplementation = interfaceAddr(from, ERC1400_TOKENS_SENDER);
        if (senderImplementation != address(0)) {
            IERC1400TokensSender(senderImplementation).tokensToTransfer(
                msg.sig,
                partition,
                operator,
                from,
                to,
                value,
                data,
                operatorData
            );
        }
        address validatorImplementation;
        validatorImplementation = interfaceAddr(
            address(this),
            ERC1400_TOKENS_VALIDATOR
        );
        if (validatorImplementation != address(0)) {
            IERC1400TokensValidator(validatorImplementation).tokensToValidate(
                msg.sig,
                partition,
                operator,
                from,
                to,
                value,
                data,
                operatorData
            );
        }
    }

    /**
     * [INTERNAL]
     * @dev Check for 'ERC1400TokensRecipient' hook on the recipient and call it.
     * @param partition Name of the partition (bytes32 to be left empty for ERC1400Raw transfer).
     * @param operator Address which triggered the balance increase (through transfer or issuance).
     * @param from Token holder for a transfer and 0x for an issuance.
     * @param to Token recipient.
     * @param value Number of tokens the recipient balance is increased by.
     * @param data Extra information, intended for the token holder ('from').
     * @param operatorData Extra information attached by the operator (if any).
     */
    function _callPostTransferHooks(
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal {
        address recipientImplementation;
        recipientImplementation = interfaceAddr(to, ERC1400_TOKENS_RECIPIENT);

        if (recipientImplementation != address(0)) {
            IERC1400TokensRecipient(recipientImplementation).tokensReceived(
                msg.sig,
                partition,
                operator,
                from,
                to,
                value,
                data,
                operatorData
            );
        }
    }

    /**
     * [INTERNAL]
     * @dev Perform the issuance of tokens.
     * @param operator Address which triggered the issuance.
     * @param to Token recipient.
     * @param value Number of tokens issued.
     * @param data Information attached to the issuance, and intended for the recipient (to).
     * @param operatorData Information attached to the issuance by the operator (if any).
     */
    function _issue(
        address operator,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal whenNotMigrated virtual {
        require(to != address(0), "ST6"); 
        uint256 whitelistStatus = whitelist_.isWhitelistedUser(to);
        // if (_balances[to] + (value) > basicCap()) {
        //     require(
        //         whitelist_.userType(to),
        //         "ST13"
        //     );
        // }
        if (isAddressExist[to] != 1) {
            require(
                tokenHolders.length < 1975,
                "ST15"
            );
            tokenHolders.push(to);
            isAddressExist[to] = 1;
        }
        require(whitelistStatus <= 200, "ST14");
        _totalSupply = _totalSupply + (value);
        _balances[to] = _balances[to] + (value);
        addInvestor(to);
        emit Issued(operator, to, value, data, operatorData);
    }

    /********************** ERC1400Raw OPTIONAL FUNCTIONS ***************************/

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Set validator contract address.
     * The validator contract needs to verify "ERC1400TokensValidator" interface.
     * Once setup, the validator will be called everytime a transfer is executed.
     * @param validatorAddress Address of the validator contract.
     * @param interfaceLabel Interface label of hook contract.
     */
    function _setHookContract(
        address validatorAddress,
        string memory interfaceLabel
    ) internal {
        ERC1820Client.setInterfaceImplementation(
            interfaceLabel,
            validatorAddress
        );
    }

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Set list of token controllers.
     * @param operators Controller addresses.
     */
    function _setControllers(address[] memory operators) internal {
        for (uint256 i = 0; i < _controllers.length; i++) {
            _isController[_controllers[i]] = false;
        }
        for (uint256 j = 0; j < operators.length; j++) {
            _isController[operators[j]] = true;
        }
        _controllers = operators;
    }
    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev change whitelist address
     * @param whitelist new whitelist address.
     */
    function changeWhitelist(IAkruNFTWhitelist whitelist)
        public
        onlyAdmin
        returns (bool)
    {
        whitelist_ = whitelist;
        return true; 
    }

    function getAllTokenHolders()
        public
        view
        returns (address[] memory)
    {
        require(whitelist_.isAdmin(msg.sender), "ST0");
        return tokenHolders;
    }
    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev set property cap 
     * @param propertyCap new property Cap.
     */
    function cap(uint256 propertyCap) public onlyAdmin {   
        // require(whitelist_.isWhitelistedUser(msg.sender) <= 201,"ST0");
        // require(
        //     _capCounter == 0,
        //     "ST16"
        // );
        require(propertyCap > 0, "ST17");
        _cap = propertyCap;
        // _capCounter++;
        emit CapSet(msg.sender, tx.origin, propertyCap, address(this));
    }
    /**
     * @dev get basic cap
     * @return calculated cap
     */
    function basicCap() public view returns (uint256) {
        return ((_cap * (basicPercentage)) / (100));
    }

    
     /**
     * @dev get all Users with there balance
     * @return  all Users with there balance
     */
    function getStoredAllData()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        require(whitelist_.isAdmin(msg.sender), "ST0");
        uint256 size = tokenHolders.length;
        uint256[] memory balanceOfUsers = new uint256[](size);
        uint256 j;
        for (j = 0; j < size; j++) {
            balanceOfUsers[j] = _balances[tokenHolders[j]];
        }
        return (tokenHolders, balanceOfUsers);
    }
    
    /**
     * @dev to add token for distribution from exchange  
     * @param investor address of user
     * @param balance balance of user
     * @return  function call
     */
    function addFromExchangeRaw1400(address investor , uint256 balance) public  override onlyAdmin returns (bool){
       return addFromExchangeDistribution(investor, balance);
    }

    /**
     * @dev to update token for distribution from exchange  
     * @param _investor address of user
     * @param _balance balance of user
     * @return  function call
     */
    function updateFromExchangeRaw1400(address _investor , uint256 _balance) public override onlyAdmin returns (bool){
      return updateFromExchangeDistribution(_investor, _balance);
    }
     /**
     * @dev get whitelisted ERC1400 Address 
     * @return  address of whitlisting
     */
    function getERC1400WhitelistAddress() public view returns (address){
       return address(whitelist_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./ERC1400Raw.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../../utils/Roles.sol";

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor() {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @title ERC1400RawIssuable
 * @dev ERC1400Raw issuance logic
 */
abstract contract ERC1400RawIssuable is ERC1400Raw, MinterRole {
    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Issue the amout of tokens for the recipient 'to'.
     * @param to Token recipient.
     * @param value Number of tokens issued.
     * @param data Information attached to the issuance, by the token holder.
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     * @return A boolean that indicates if the operation was successful.
     */
    function issue(
        address to,
        uint256 value,
        bytes calldata data
    ) public isValidCertificate(data) onlyAdmin returns (bool) {
        _issue(msg.sender, to, value, data, "");

        _callPostTransferHooks("", msg.sender, address(0), to, value, data, "");

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title IERC1400Raw token standard
 * @dev ERC1400Raw interface
 */
interface IERC1400Raw {
    function name() external view returns (string memory); // 1/13

    function symbol() external view returns (string memory); // 2/13

    function totalSupply() external view returns (uint256); // 3/13

    function balanceOf(address owner) external view returns (uint256); // 4/13

    function granularity() external view returns (uint256); // 5/13

    function controllers() external view returns (address[] memory); // 6/13

    function authorizeOperator(address operator) external; // 7/13

    function revokeOperator(address operator) external; // 8/13

    function isOperator(
        address operator,
        address tokenHolder
    ) external view returns (bool); // 9/13

    function transferWithData(
        address to,
        uint256 value,
        bytes calldata data
    ) external; // 10/13

    function transferFromWithData(
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external; // 11/13

    function redeem(uint256 value, bytes calldata data) external; // 12/13

    function redeemFrom(
        address from,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external; // 13/13

    function addFromExchangeRaw1400(
        address investor,
        uint256 balance
    ) external returns (bool);

    function updateFromExchangeRaw1400(
        address _investor,
        uint256 _balance
    ) external returns (bool);

    event TransferWithData(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data,
        bytes operatorData
    );
    event Issued(
        address indexed operator,
        address indexed to,
        uint256 value,
        bytes data,
        bytes operatorData
    );
    event Redeemed(
        address indexed operator,
        address indexed from,
        uint256 value,
        bytes data,
        bytes operatorData
    );
    event AuthorizedOperator(
        address indexed operator,
        address indexed tokenHolder
    );
    event RevokedOperator(
        address indexed operator,
        address indexed tokenHolder
    );
    event CapSet(address _sender,address _orgin, uint256 propertyCap, address _stContract);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title IERC1400TokensRecipient
 * @dev ERC1400TokensRecipient interface
 */
interface IERC1400TokensRecipient {
    function canReceive(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns (bool);

    function tokensReceived(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title IERC1400TokensSender
 * @dev ERC1400TokensSender interface
 */
interface IERC1400TokensSender {
    function canTransfer(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns (bool);

    function tokensToTransfer(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title IERC1400TokensValidator
 * @dev ERC1400TokensValidator interface
 */
interface IERC1400TokensValidator {
    function canValidate(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns (bool);

    function tokensToValidate(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ERC1820Registry {
    function setInterfaceImplementer(
        address _addr,
        bytes32 _interfaceHash,
        address _implementer
    ) external;

    function getInterfaceImplementer(
        address _addr,
        bytes32 _interfaceHash
    ) external view returns (address);

    function setManager(address _addr, address _newManager) external;

    function getManager(address _addr) external view returns (address);
}

/// Base client to interact with the registry.
contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY =
        ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(
        string memory interfaceLabel,
        address implementation
    ) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(
            address(this),
            interfaceHash,
            implementation
        );
    }

    function interfaceAddr(
        address addr,
        string memory interfaceLabel
    ) internal view returns (address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address newManager) internal {
        ERC1820REGISTRY.setManager(address(this), newManager);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract ERC1820Implementer {
    bytes32 constant ERC1820_ACCEPT_MAGIC =
        keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

    mapping(bytes32 => bool) internal _interfaceHashes;

    // Comments to avoid compilation warnings for unused variables.
    function canImplementInterfaceForAddress(
        bytes32 interfaceHash,
        address /*addr*/
    ) external view returns (bytes32) {
        if (_interfaceHashes[interfaceHash]) {
            return ERC1820_ACCEPT_MAGIC;
        } else {
            return "";
        }
    }

    function _setInterface(string memory interfaceLabel) internal {
        _interfaceHashes[keccak256(abi.encodePacked(interfaceLabel))] = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../ERC1400Raw/ERC1400RawIssuable.sol";
import "../../../NFTwhitelist/IAkruNFTWhitelist.sol";
import "../../../MarginLoan/IMarginLoan.sol";

/**
 * @title ERC1400RawERC20
 * @dev ERC1400Raw with ERC20 retrocompatibility
 * @author AKRU's Dev team
 */
contract ERC1400RawERC20 is IERC20, ERC1400RawIssuable {
    string internal constant ERC20_INTERFACE_NAME = "ERC20Token";
    address[] private _propertyOwners;
    address public reserveWallet;
    IMarginLoan _IMarginLoan;
    mapping(address => mapping(address => uint256)) internal _allowed;
    mapping(address => uint256) private ownerToShares;
    event ShareAdded(uint256[] shares, address[] indexed owners);
    event bulkTokenMinted(address[] indexed ownersAddresses, uint256[] amount);

    /**
     * [ERC1400RawERC20 CONSTRUCTOR]
     * @dev Initialize ERC1400RawERC20 and CertificateController parameters + register
     * the contract implementation in ERC1820Registry.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param granularity Granularity of the token.
     * @param controllers Array of initial controllers.
     * @param certificateSigner Address of the off-chain service which signs the
     * conditional ownership certificates required for token transfers, issuance,
     * redemption (Cf. CertificateController.sol).
     * @param certificateActivated If set to 'true', the certificate controller
     * is activated at contract creation.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 granularity,
        address[] memory controllers,
        address certificateSigner,
        bool certificateActivated,
        IAkruNFTWhitelist whitelist,
        IMarginLoan __IMarginLoan,
        address _reserveWallet,
        uint256[] memory ownerShares,
        address[] memory owners
    )
        ERC1400Raw(
            name,
            symbol,
            granularity,
            controllers,
            certificateSigner,
            certificateActivated,
            whitelist,
            __IMarginLoan
            // cap_
        )
    {
        ERC1820Client.setInterfaceImplementation(
            ERC20_INTERFACE_NAME,
            address(this)
        );
        ERC1820Implementer._setInterface(ERC20_INTERFACE_NAME); // For migration
        whitelist_ = whitelist;
        reserveWallet = _reserveWallet;
        require(
            ownerShares.length == owners.length,
            "ST3"
        );
        uint256 total;
        uint256 length = ownerShares.length;
        for(uint256 i = 0; i < length; ){
            ownerToShares[owners[i]] =  ownerShares[i];
            _propertyOwners.push(owners[i]);
            total +=  ownerShares[i];
            unchecked {
                i++;
            }
        }
        require(total == 10000,"ST10");
    }

    modifier onlyAdmin() override(ERC1400Raw) {
        require(whitelist_.isWhitelistedUser(msg.sender) < 132, "ST0");
        _;
    }

    // Only Transfer on Tokenism Plateform
    modifier onlyTokenism(address _sender, address _receiver) override {
        uint256 codeS = whitelist_.isWhitelistedUser(_sender);
        uint256 codeR = whitelist_.isWhitelistedUser(_receiver);
        require(codeS < 120 || codeR < 120, "ST1");
        _;
    }

    // function setDevTokens(uint256 _devToken) external onlyAdmin{
    //     devToken = _devToken;
    // }

    /**
     * [OVERRIDES ERC1400Raw METHOD]
     * @dev Perform the transfer of tokens.
     * @param operator The address performing the transfer.
     * @param from Token holder.
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer.
     * @param operatorData Information attached to the transfer by the operator (if any).
     */
    function _transferWithData(
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal override {
        ERC1400Raw._transferWithData(
            operator,
            from,
            to,
            value,
            data,
            operatorData
        );
        emit Transfer(from, to, value);
    }

    /**
     * [OVERRIDES ERC1400Raw METHOD]
     * @dev Perform the token redemption.
     * @param operator The address performing the redemption.
     * @param from Token holder whose tokens will be redeemed.
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption.
     * @param operatorData Information attached to the redemption by the operator (if any).
     */
    function _redeem(
        address operator,
        address from,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal override {
        ERC1400Raw._redeem(operator, from, value, data, operatorData);

        emit Transfer(from, address(0), value); // ERC20 backwards compatibility
    }

    /**
     * [OVERRIDES ERC1400Raw totalSupply ]
     */
    function totalSupply()
        public
        view
        override(ERC1400Raw, IERC20)
        returns (uint256)
    {
        return ERC1400Raw.totalSupply();
    }

    /**
     * [OVERRIDES ERC1400Raw balanceOf ]
     */
    function balanceOf(
        address account
    ) public view override(ERC1400Raw, IERC20) returns (uint256) {
        return ERC1400Raw.balanceOf(account);
    }

    /**
     * [OVERRIDES ERC1400Raw METHOD]
     * @dev Perform the issuance of tokens.
     * @param operator Address which triggered the issuance.
     * @param to Token recipient.
     * @param value Number of tokens issued.
     * @param data Information attached to the issuance.
     * @param operatorData Information attached to the issued by the operator (if any).
     */
    function _issue(
        address operator,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal override {
        ERC1400Raw._issue(operator, to, value, data, operatorData);

        emit Transfer(address(0), to, value); // ERC20 backwards compatibility
    }

    /**
     * [OVERRIDES ERC1400Raw METHOD]
     * @dev Get the number of decimals of the token.
     * @return The number of decimals of the token. For Backwards compatibility, decimals are forced to 18 in ERC1400Raw.
     */
    function decimals() external pure returns (uint8) {
        return 0;
    }

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Check the amount of tokens that an owner allowed to a spender.
     * @param owner_ address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address owner_,
        address spender
    ) external view override returns (uint256) {
        return _allowed[owner_][spender];
    }

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of 'msg.sender'.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean that indicates if the operation was successful.
     */
    function approve(
        address spender,
        uint256 value
    ) external override returns (bool) {
        require(spender != address(0), "ST5"); // Approval Blocked - Spender not eligible
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Transfer token for a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transfer(
        address to,
        uint256 value
    ) external override onlyTokenism(msg.sender, to) returns (bool) {
        _callPreTransferHooks("", msg.sender, msg.sender, to, value, "", "");
        _transferWithData(msg.sender, msg.sender, to, value, "", "");
        _callPostTransferHooks("", msg.sender, msg.sender, to, value, "", "");
        return true;
    }

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Transfer tokens from one address to another.
     * @param from The address which you want to transfer tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override onlyTokenism(msg.sender, to) returns (bool) {
        require(
            _isOperator(msg.sender, from) ||
                (value <= _allowed[from][msg.sender]),
            "ST7"
        );
        if (_allowed[from][msg.sender] >= value) {
            _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;
        } else {
            _allowed[from][msg.sender] = 0;
        }
        _callPreTransferHooks("", msg.sender, from, to, value, "", "");
        _transferWithData(msg.sender, from, to, value, "", "");
        _callPostTransferHooks("", msg.sender, from, to, value, "", "");
        return true;
    }

    /************************** ERC1400RawERC20 OPTIONAL FUNCTIONS *******************************/

    /**
     * [NOT MANDATORY FOR ERC1400RawERC20 STANDARD]
     * @dev Set validator contract address.
     * The validator contract needs to verify "ERC1400TokensValidator" interface.
     * Once setup, the validator will be called everytime a transfer is executed.
     * @param validatorAddress Address of the validator contract.
     * @param interfaceLabel Interface label of hook contract.
     */
    function setHookContract(
        address validatorAddress,
        string calldata interfaceLabel
    ) external onlyAdmin {
        ERC1400Raw._setHookContract(validatorAddress, interfaceLabel);
    }

    /************************** REQUIRED FOR MIGRATION FEATURE *******************************/

    /**
     * [NOT MANDATORY FOR ERC1400RawERC20 STANDARD][OVERRIDES ERC1400 METHOD]
     * @dev Migrate contract.
     *
     * ===> CAUTION: DEFINITIVE ACTION
     *
     * This function shall be called once a new version of the smart contract has been created.
     * Once this function is called:
     *  - The address of the new smart contract is set in ERC1820 registry
     *  - If the choice is definitive, the current smart contract is turned off and can never be used again
     *
     * @param newContractAddress Address of the new version of the smart contract.
     * @param definitive If set to 'true' the contract is turned off definitely.
     */
    function migrate(
        address newContractAddress,
        bool definitive
    ) external onlyAdmin {
        ERC1820Client.setInterfaceImplementation(
            ERC20_INTERFACE_NAME,
            newContractAddress
        );
        if (definitive) {
            _migrated = true;
        }
    }

    /**
     * [NOT MANDATORY FOR ERC1400RawERC20 STANDARD]USED FOR DISTRIBUTION MODULE]
     *
     * ===> CAUTION: DEFINITIVE ACTION
     *
     * Once this function is called:
     *
     * @param investor_ Address of the Investor.
     * @param balance_ Balance of token listed on exchange.
     */
    function addFromExchange(
        address investor_,
        uint256 balance_
    ) public returns (bool) {
        return ERC1400Raw.addFromExchangeRaw1400(investor_, balance_);
    }

    /**
     * [NOT MANDATORY FOR ERC1400RawERC20 STANDARD]USED FOR DISTRIBUTION MODULE]
     *
     * ===> CAUTION: DEFINITIVE ACTION
     *
     * Once this function is called:
     *
     * @param investor_ Address of the Investor.
     * @param balance_ Balance of token listed on exchange.
     */
    function updateFromExchange(
        address investor_,
        uint256 balance_
    ) public onlyAdmin returns (bool) {
        return ERC1400Raw.updateFromExchangeRaw1400(investor_, balance_);
    }

    /**
     * @dev close the ERC1400 smart contract
     */
    // function closeERC1400() public {
    //     require(whitelist_.isSuperAdmin(msg.sender), "ST2");
    //     selfdestruct(payable(msg.sender)); // `admin` is the admin address
    // }

    /**
     * @dev check if property owner exist in the property
     * @param addr address of the user
     */
    function isPropertyOwnerExist(
        address addr
    ) public view returns (bool isOwnerExist) {
        for (uint256 i = 0; i < _propertyOwners.length; ) {
            if (_propertyOwners[i] == addr) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev bulk mint of tokens to property owners exist in the property
     * @param to array of addresses of the owners
     * @param amount array of amount to be minted
     * @param cert array of certificate
     */
    function bulkMint(
        address[] calldata to,
        uint256[] calldata amount,
        bytes calldata cert
    ) external {
        require(whitelist_.isSuperAdmin(msg.sender), "ST2");

        for (uint256 i = 0; i < to.length; ) {
            issue(to[i], amount[i], cert);
            unchecked {
                i++;
            }
        }
        emit bulkTokenMinted(to, amount);
    }

    /**
     * @dev  add share percentages to property owners exist in the property
     * @param ownerShares array of shares of the owners
     * @param owners array of addresses of the owners
     */
    function addPropertyOwnersShares(
        uint256[] calldata ownerShares,
        address[] calldata owners
    ) external onlyAdmin {
        require(ownerShares.length == owners.length, "ST3");
        uint256 total;
        uint256 length = ownerShares.length;
        if(_propertyOwners.length>0){
            delete _propertyOwners;
         }
        for (uint256 i = 0; i < length; ) {
            ownerToShares[owners[i]] = ownerShares[i];
            _propertyOwners.push(owners[i]);
            total += ownerShares[i];
            unchecked {
                i++;
            }
        }
        require(total == 10000, "ST10");
        emit ShareAdded(ownerShares, owners);
    }

    /**
     * @dev get all property owner of the property
     * @return _propertyOwners
     */
    function propertyOwners() external view returns (address[] memory) {
        return _propertyOwners;
    }

    /**
     * @dev get all property owner shares of the property
     * @return _shares
     */
    function shares() external view returns (uint256[] memory) {
        uint256[] memory _shares = new uint256[](_propertyOwners.length);
        uint256 i=0;
        for ( i; i < _propertyOwners.length; ) {
            _shares[i] = ownerToShares[_propertyOwners[i]];
            unchecked {
                i++;
            }
        }
        return _shares;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title ERC1400RawERC20
 * @dev ERC1400Raw with ERC20 retrocompatibility
 *  @author AKRU's Dev team
 */
interface IERC1400RawERC20  { 
  /**
     * ST0: Only admin is allowed
     * ST1: StableCoin: Cannot send tokens outside Tokenism
     * ST2: Only SuperAdmin is allowed
     * ST3: Invalid shares array provided
     * ST4: Transfer Blocked - Sender balance insufficient
     * ST5: Transfer Blocked - Sender not eligible
     * ST6: Transfer Blocked - Receiver not eligible
     * ST7: Transfer Blocked - Identity restriction
     * ST8: Percentages sum should be 100
     * ST9: Only deployed by admin Or manager of Tokenism
     * ST10: Token Already exist with this Name
     * ST11: Token granularity can not be lower than 1
     * ST12: Security Token: Cannot send tokens outside AKRU
     * ST13: Upgrade Yourself to Premium Account for more Buy
     * ST14: Whitelisting Failed
     * ST15: There is no space to new Investor
     * ST16: Only STO deployer set Cap ERC11400 Value and Once a time
     * ST17: Cap must be greater than 0
     * ST18: Only Owner or Admin is allowed to send
     * ST19: There is no any Investor to distribute dividends
     * ST20: You did not have this much AKUSD
     * ST21: Not a contract address
  
  */
 event TransferWithData(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 value,
    bytes data,
    bytes operatorData
  );
  event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
  event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);
  /**
     * [ERC1400Raw INTERFACE (1/13)]
     * @dev Get the name of the token, e.g., "MyToken".
     * @return Name of the token.
     */
  function name() external view returns (string memory); // 1/13
  /**
     * [ERC1400Raw INTERFACE (2/13)]
     * @dev Get the symbol of the token, e.g., "MYT".
     * @return Symbol of the token.
     */
  function symbol() external view returns (string memory); // 2/13
 /**
     * [ERC1400Raw INTERFACE (3/13)]
     * @dev Get the total number of issued tokens.
     * @return Total supply of tokens currently in circulation.
     */
  function totalSupply() external view returns (uint256); // 3/13
   /**
     * [ERC1400Raw INTERFACE (4/13)]
     * @dev Get the balance of the account with address 'tokenHolder'.
     * @param tokenHolder Address for which the balance is returned.
     * @return Amount of token held by 'tokenHolder' in the token contract.
     */
  function balanceOf(address tokenHolder) external view returns (uint256); // 4/13
  /**
     * [ERC1400Raw INTERFACE (5/13)]
     * @dev Get the smallest part of the token that’s not divisible.
     * @return The smallest non-divisible part of the token.
     */
  function granularity() external view returns (uint256); // 5/13
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function transfer(address to, uint256 value) external  returns (bool);
  function transferFrom(address from, address to, uint256 value)external returns (bool);
  /**
     * [ERC1400Raw INTERFACE (6/13)]
     * @dev Get the list of controllers as defined by the token contract.
     * @return List of addresses of all the controllers.
     */
  function controllers() external view returns (address[] memory); // 6/13
  function transferOwnership(address payable newOwner) external; 
   /**
     * [ERC1400Raw INTERFACE (7/13)]
     * @dev Set a third party operator address as an operator of 'msg.sender' to transfer
     * and redeem tokens on its behalf.
     * @param operator Address to set as an operator for 'msg.sender'.
     */
  function authorizeOperator(address operator) external; // 7/13
   /**
     * [ERC1400Raw INTERFACE (8/13)]
     * @dev Remove the right of the operator address to be an operator for 'msg.sender'
     * and to transfer and redeem tokens on its behalf.
     * @param operator Address to rescind as an operator for 'msg.sender'.
     */
  function revokeOperator(address operator) external; // 8/13
  /**
     * [ERC1400Raw INTERFACE (9/13)]
     * @dev Indicate whether the operator address is an operator of the tokenHolder address.
     * @param operator Address which may be an operator of tokenHolder.
     * @param tokenHolder Address of a token holder which may have the operator address as an operator.
     * @return 'true' if operator is an operator of 'tokenHolder' and 'false' otherwise.
     */
  function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13
  /**
     * [ERC1400Raw INTERFACE (10/13)]
     * @dev Transfer the amount of tokens from the address 'msg.sender' to the address 'to'.
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer, by the token holder.
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
  function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
   /**
     * [ERC1400Raw INTERFACE (11/13)]
     * @dev Transfer the amount of tokens on behalf of the address 'from' to the address 'to'.
     * @param from Token holder (or 'address(0)' to set from to 'msg.sender').
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer, and intended for the token holder ('from').
     * @param operatorData Information attached to the transfer by the operator. 
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
  function transferFromWithData(address from, 
                                address to, 
                                uint256 value, 
                                bytes calldata data, 
                                bytes calldata operatorData) external; // 11/13
   /**
     * [ERC1400Raw INTERFACE (12/13)]
     * @dev Redeem the amount of tokens from the address 'msg.sender'.
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption, by the token holder. 
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
  function redeem(uint256 value, bytes calldata data) external; // 12/13
  /**
     * [ERC1400Raw INTERFACE (13/13)]
     * @dev Redeem the amount of tokens on behalf of the address from.
     * @param from Token holder whose tokens will be redeemed (or address(0) to set from to msg.sender).
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption.
     * @param operatorData Information attached to the redemption, by the operator. 
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
  function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13
   /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev set property cap 
     * @param propertyCap new property Cap.
     */
  function cap(uint256 propertyCap) external;
  /**
     * @dev get basic cap
     * @return calculated cap
     */
  function basicCap() external view returns (uint256);
  /**
     * @dev get all Users with there balance
     * @return  all Users with there balance
     */
//   function getStoredAllData(address adminAddress) external view returns (address[] memory, uint256[] memory);

    // function distributeDividends(address _token, uint256 _dividends) external;
 /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Issue the amout of tokens for the recipient 'to'.
     * @param to Token recipient.
     * @param value Number of tokens issued.
     * @param data Information attached to the issuance, by the token holder. 
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     * @return A boolean that indicates if the operation was successful.
     */
function issue(address to, uint256 value, bytes calldata data) external  returns (bool);
/**
     * [NOT MANDATORY FOR ERC1400RawERC20 STANDARD][OVERRIDES ERC1400 METHOD]
     * @dev Migrate contract.
     *
     * ===> CAUTION: DEFINITIVE ACTION
     *
     * This function shall be called once a new version of the smart contract has been created.
     * Once this function is called:
     *  - The address of the new smart contract is set in ERC1820 registry
     *  - If the choice is definitive, the current smart contract is turned off and can never be used again
     *
     * @param newContractAddress Address of the new version of the smart contract.
     * @param definitive If set to 'true' the contract is turned off definitely.
     */
function migrate(address newContractAddress, bool definitive)external;
/**
  * @dev close the ERC1400 smart contract
  */
function closeERC1400() external;
/**
     * [NOT MANDATORY FOR ERC1400RawERC20 STANDARD]USED FOR DISTRIBUTION MODULE]
     *
     * ===> CAUTION: DEFINITIVE ACTION
     *
     * Once this function is called:
     *
     * @param _investor Address of the Investor.
     * @param _balance Balance of token listed on exchange.
     */
function addFromExchange(address _investor , uint256 _balance) external returns(bool);
/**
     * [NOT MANDATORY FOR ERC1400RawERC20 STANDARD]USED FOR DISTRIBUTION MODULE]
     *
     * ===> CAUTION: DEFINITIVE ACTION
     *
     * Once this function is called:
     *
     * @param _investor Address of the Investor.
     * @param _balance Balance of token listed on exchange.
     */
function updateFromExchange(address _investor , uint256 _balance) external returns (bool);
  /**
         * @dev get all property owner of the property
         * @return _propertyOwners
    */
function propertyOwners() external view returns (address[] memory);
 /**
     * @dev get all property owner shares of the property
     * @return _shares
     */
function shares() external view returns (uint256[] memory);
/**
     * @dev check if property owner exist in the property
     * @param _addr address of the user
     */
function isPropertyOwnerExist(address _addr) external view returns(bool isOwnerExist);
 /**
     * @dev toggleCertificateController activate/deactivate Certificate Controller
     * @param _isActive true/false
     */
function toggleCertificateController(bool _isActive) external;
/**
     * @dev bulk mint of tokens to property owners exist in the property
     * @param to array of addresses of the owners
     * @param amount array of amount to be minted
     * @param cert array of certificate
     */
function bulkMint(address[] calldata to,uint256[] calldata amount,bytes calldata cert) external;
   /**
     * @dev  add share percentages to property owners exist in the property
     * @param _shares array of shares of the owners
     * @param _owners array of addresses of the owners
     */
function addPropertyOwnersShares(uint256[] calldata _shares,address[] calldata _owners) external;
 /**
     * @dev to add token for distribution from exchange  
     * @param _investor address of user
     * @param _balance balance of user
     * @return  function call
     */
    function addFromExchangeRaw1400(address _investor , uint256 _balance) external returns (bool);
    /**
     * @dev to update token for distribution from exchange  
     * @param _investor address of user
     * @param _balance balance of user
     * @return  function call
     */
    function updateFromExchangeRaw1400(address _investor , uint256 _balance) external returns (bool);
    /**
     * @dev get whitelisted ERC1400 Address 
     * @return  address of whitlisting
     */
    function getERC1400WhitelistAddress() external view returns (address);
    function reserveWallet() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(
        Role storage role,
        address account
    ) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}