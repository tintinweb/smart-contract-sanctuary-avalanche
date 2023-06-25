// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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

// SPDX-License-Identifier: GPL-3.0
// solhint-disable no-empty-blocks
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {XPower} from "./XPower.sol";
import {SovMigratable} from "./base/Migratable.sol";
import {Constants} from "./libs/Constants.sol";

/**
 * Abstract base class for the APower aTHOR, aLOKI and aODIN tokens, where only
 * the owner of the contract i.e the MoeTreasury is entitled to mint them.
 */
abstract contract APower is ERC20, ERC20Burnable, SovMigratable, Ownable {
    /** (burnable) proof-of-work tokens */
    XPower private _moe;

    /** @param symbol short token symbol */
    /** @param moeLink address of XPower tokens */
    /** @param sovBase address of old contract */
    /** @param deadlineIn seconds to end-of-migration */
    constructor(
        string memory symbol,
        address moeLink,
        address[] memory sovBase,
        uint256 deadlineIn
    )
        // ERC20 constructor: name, symbol
        ERC20("APower", symbol)
        // Migratable: XPower, old APower & rel. deadline [seconds]
        SovMigratable(moeLink, sovBase, deadlineIn)
    {
        _moe = XPower(moeLink);
    }

    /** @return number of decimals of representation */
    function decimals() public view virtual override returns (uint8) {
        return _moe.decimals();
    }

    /** mint amount of tokens for beneficiary (after wrapping XPower) */
    function mint(address to, uint256 amount) external onlyOwner {
        assert(_moe.transferFrom(owner(), (address)(this), _wrapped(amount)));
        _mint(to, amount);
    }

    /** @return wrapped XPower maintaining collateralization (if possible) */
    function _wrapped(uint256 amount) private view returns (uint256) {
        uint256 balance = _moe.balanceOf((address)(this));
        uint256 supply = amount + this.totalSupply();
        if (supply > balance) {
            uint256 treasury = _moe.balanceOf(owner());
            return Math.min(treasury, supply - balance);
        }
        return 0;
    }

    /** burn amount of tokens from caller (and then unwrap XPower) */
    function burn(uint256 amount) public override {
        super.burn(amount);
        _moe.transfer(msg.sender, _unwrapped(amount));
    }

    /**
     * burn amount of tokens from account, deducting from the caller's
     * allowance (and then unwrap XPower)
     */
    function burnFrom(address account, uint256 amount) public override {
        super.burnFrom(account, amount);
        _moe.transfer(account, _unwrapped(amount));
    }

    /** @return unwrapped XPower proportional to burned APower amount */
    function _unwrapped(uint256 amount) private view returns (uint256) {
        uint256 balance = _moe.balanceOf((address)(this));
        uint256 supply = amount + this.totalSupply();
        if (supply > 0) {
            return (amount * balance) / supply;
        }
        return 0;
    }

    /** @return collateralization ratio with 1'000'000 ~ 100% */
    function collateralization() external view returns (uint256) {
        uint256 balance = _moe.balanceOf((address)(this));
        uint256 supply = this.totalSupply();
        if (supply > 0) {
            return (1e6 * balance) / supply;
        }
        return 0;
    }

    /** @return prefix of token */
    function prefix() external view returns (uint256) {
        return _moe.prefix();
    }
}

contract APowerThor is APower {
    /** @param moeLink address of XPower tokens */
    /** @param sovBase address of old contract */
    /** @param deadlineIn seconds to end-of-migration */
    constructor(
        address moeLink,
        address[] memory sovBase,
        uint256 deadlineIn
    ) APower("aTHOR", moeLink, sovBase, deadlineIn) {}
}

contract APowerLoki is APower {
    /** @param moeLink address of XPower tokens */
    /** @param sovBase address of old contract */
    /** @param deadlineIn seconds to end-of-migration */
    constructor(
        address moeLink,
        address[] memory sovBase,
        uint256 deadlineIn
    ) APower("aLOKI", moeLink, sovBase, deadlineIn) {}
}

contract APowerOdin is APower {
    /** @param moeLink address of XPower tokens */
    /** @param sovBase address of old contract */
    /** @param deadlineIn seconds to end-of-migration */
    constructor(
        address moeLink,
        address[] memory sovBase,
        uint256 deadlineIn
    ) APower("aODIN", moeLink, sovBase, deadlineIn) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * Allows tracking of fees using cumulative moving-averages:
 * >
 * > avg[n+1] = (fee[n+1] + n*avg[n]) / (n+1)
 * >
 */
abstract contract FeeTracker {
    /** cumulative moving-averages: gas & gas-price */
    uint256[2] private _average;

    /** gas & gas-price tracker */
    modifier tracked() {
        uint256 gas = gasleft();
        _;
        _update(gas - gasleft(), tx.gasprice);
    }

    /** update averages over gas & gas-price */
    function _update(uint256 gasValue, uint256 gasPrice) private {
        uint256 value = _average[0];
        if (value > 0) {
            _average[0] = (gasValue + value * 0xf) >> 4;
        } else {
            _average[0] = (gasValue);
        }
        uint256 price = _average[1];
        if (price > 0) {
            _average[1] = (gasPrice + price * 0xf) >> 4;
        } else {
            _average[1] = (gasPrice);
        }
    }

    /** @return fee-estimate and averages over gas & gas-price */
    function _fees(uint256 add, uint256 mul, uint256 div) internal view returns (uint256[] memory) {
        uint256[] memory array = new uint256[](3);
        uint256 gasPrice = _average[1];
        array[2] = gasPrice;
        uint256 gasValue = _average[0];
        array[1] = gasValue;
        uint256 feeValue = gasPrice * gasValue;
        array[0] = ((feeValue + add) * mul) / div;
        return array;
    }
}

// SPDX-License-Identifier: GPL-3.0
// solhint-disable not-rely-on-time
pragma solidity ^0.8.0;

import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Supervised, MoeMigratableSupervised, SovMigratableSupervised} from "./Supervised.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * Allows migration of tokens from an old contract upto a certain deadline.
 * Further, it is possible to close down the migration window earlier than
 * the specified deadline.
 */
abstract contract Migratable is ERC20, ERC20Burnable, Supervised {
    /** burnable ERC20 tokens */
    ERC20Burnable[] private _base;
    /** base address to index map */
    mapping(address => uint) private _index;
    /** timestamp of immigration deadline */
    uint256 private _deadlineBy;
    /** flag to seal immigration */
    bool[] private _sealed;
    /** number of immigrated tokens */
    uint256 private _migrated;

    /** @param base addresses of old contracts */
    /** @param deadlineIn seconds to end-of-migration */
    constructor(address[] memory base, uint256 deadlineIn) {
        _deadlineBy = block.timestamp + deadlineIn;
        _base = new ERC20Burnable[](base.length);
        _sealed = new bool[](base.length);
        for (uint256 i = 0; i < base.length; i++) {
            _base[i] = ERC20Burnable(base[i]);
            _index[base[i]] = i;
        }
    }

    /** @return index of base address */
    function oldIndexOf(address base) external view returns (uint256) {
        return _index[base];
    }

    /** migrate amount of ERC20 tokens */
    function migrate(uint256 amount, uint256[] memory index) external returns (uint256) {
        return _migrateFrom(msg.sender, amount, index);
    }

    /** migrate amount of ERC20 tokens */
    function migrateFrom(address account, uint256 amount, uint256[] memory index) external returns (uint256) {
        return _migrateFrom(account, amount, index);
    }

    /** migrate amount of ERC20 tokens */
    function _migrateFrom(address account, uint256 amount, uint256[] memory index) internal virtual returns (uint256) {
        uint256 minAmount = Math.min(amount, _base[index[0]].balanceOf(account));
        uint256 newAmount = _premigrate(account, minAmount, index[0]);
        _mint(account, newAmount);
        return newAmount;
    }

    /** migrate amount of ERC20 tokens */
    function _premigrate(address account, uint256 amount, uint256 index) internal returns (uint256) {
        require(!_sealed[index], "migration sealed");
        uint256 timestamp = block.timestamp;
        require(_deadlineBy >= timestamp, "deadline passed");
        _base[index].burnFrom(account, amount);
        assert(amount > 0 || amount == 0);
        uint256 newAmount = newUnits(amount, index);
        _migrated += newAmount;
        return newAmount;
    }

    /** @return forward converted new amount w.r.t. decimals */
    function newUnits(uint256 oldAmount, uint256 index) public view returns (uint256) {
        if (decimals() >= _base[index].decimals()) {
            return oldAmount * (10 ** (decimals() - _base[index].decimals()));
        } else {
            return oldAmount / (10 ** (_base[index].decimals() - decimals()));
        }
    }

    /** @return backward converted old amount w.r.t. decimals */
    function oldUnits(uint256 newAmount, uint256 index) public view returns (uint256) {
        if (decimals() >= _base[index].decimals()) {
            return newAmount / (10 ** (decimals() - _base[index].decimals()));
        } else {
            return newAmount * (10 ** (_base[index].decimals() - decimals()));
        }
    }

    /** @return number of migrated tokens */
    function migrated() public view returns (uint256) {
        return _migrated;
    }

    /** seal immigration */
    function _seal(uint256 index) internal {
        _sealed[index] = true;
    }

    /** seal-all immigration */
    function _sealAll() internal {
        for (uint256 i = 0; i < _sealed.length; i++) {
            _sealed[i] = true;
        }
    }

    /** @return seal flags (of all bases) */
    function seals() public view returns (bool[] memory) {
        return _sealed;
    }

    /** @return true if this contract implements the interface defined by interface-id */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

/**
 * Allows migration of MOE tokens from an old contract upto a certain deadline.
 */
abstract contract MoeMigratable is Migratable, MoeMigratableSupervised {
    /** seal migration */
    function seal(uint256 index) external onlyRole(MOE_SEAL_ROLE) {
        _seal(index);
    }

    /** seal-all migration */
    function sealAll() external onlyRole(MOE_SEAL_ROLE) {
        _sealAll();
    }

    /** @return true if this contract implements the interface defined by interface-id */
    function supportsInterface(bytes4 interfaceId) public view virtual override(Migratable, Supervised) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

/**
 * Allows migration of SOV tokens from an old contract upto a certain deadline.
 */
abstract contract SovMigratable is Migratable, SovMigratableSupervised {
    /** migratable MOE tokens */
    MoeMigratable private _moe;

    /** @param moe address of MOE tokens */
    /** @param base addresses of old contracts */
    /** @param deadlineIn seconds to end-of-migration */
    constructor(address moe, address[] memory base, uint256 deadlineIn) Migratable(base, deadlineIn) {
        _moe = MoeMigratable(moe);
    }

    /** migrate amount of SOV tokens */
    ///
    /// @dev assumes old (XPower:APower) == new (XPower:APower) w.r.t. decimals
    ///
    function _migrateFrom(address account, uint256 amount, uint256[] memory index) internal override returns (uint256) {
        uint256[] memory moeIndex = new uint256[](1);
        moeIndex[0] = index[1]; // drop sov-index
        uint256 newAmountSov = newUnits(amount, index[0]);
        uint256 migAmountSov = _premigrate(account, amount, index[0]);
        assert(migAmountSov == newAmountSov);
        uint256 newAmountMoe = moeUnits(newAmountSov);
        uint256 oldAmountMoe = _moe.oldUnits(newAmountMoe, moeIndex[0]);
        uint256 migAmountMoe = _moe.migrateFrom(account, oldAmountMoe, moeIndex);
        assert(_moe.transferFrom(account, (address)(this), migAmountMoe));
        _mint(account, newAmountSov);
        return newAmountSov;
    }

    /** @return cross-converted MOE amount w.r.t. decimals */
    function moeUnits(uint256 sovAmount) public view returns (uint256) {
        if (decimals() >= _moe.decimals()) {
            return sovAmount / (10 ** (decimals() - _moe.decimals()));
        } else {
            return sovAmount * (10 ** (_moe.decimals() - decimals()));
        }
    }

    /** @return cross-converted SOV amount w.r.t. decimals */
    function sovUnits(uint256 moeAmount) public view returns (uint256) {
        if (decimals() >= _moe.decimals()) {
            return moeAmount * (10 ** (decimals() - _moe.decimals()));
        } else {
            return moeAmount / (10 ** (_moe.decimals() - decimals()));
        }
    }

    /** seal migration */
    function seal(uint256 index) external onlyRole(SOV_SEAL_ROLE) {
        _seal(index);
    }

    /** seal-all migration */
    function sealAll() external onlyRole(SOV_SEAL_ROLE) {
        _sealAll();
    }

    /** @return true if this contract implements the interface defined by interface-id */
    function supportsInterface(bytes4 interfaceId) public view virtual override(Migratable, Supervised) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract Supervised is AccessControlEnumerable {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /** @return true if this contract implements the interface defined by interface-id */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

abstract contract XPowerSupervised is Supervised {
    /** role grants right to change treasury's share per mint */
    bytes32 public constant SHARE_ROLE = keccak256("SHARE_ROLE");
    bytes32 public constant SHARE_ADMIN_ROLE = keccak256("SHARE_ADMIN_ROLE");

    constructor() {
        _setRoleAdmin(SHARE_ROLE, SHARE_ADMIN_ROLE);
        _grantRole(SHARE_ADMIN_ROLE, msg.sender);
    }
}

abstract contract MoeTreasurySupervised is Supervised {
    /** role grants right to change APR parametrization */
    bytes32 public constant APR_ROLE = keccak256("APR_ROLE");
    bytes32 public constant APR_ADMIN_ROLE = keccak256("APR_ADMIN_ROLE");
    /** role grants right to change APR bonus parametrization */
    bytes32 public constant APR_BONUS_ROLE = keccak256("APR_BONUS_ROLE");
    bytes32 public constant APR_BONUS_ADMIN_ROLE = keccak256("APR_BONUS_ADMIN_ROLE");

    constructor() {
        _setRoleAdmin(APR_ROLE, APR_ADMIN_ROLE);
        _grantRole(APR_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(APR_BONUS_ROLE, APR_BONUS_ADMIN_ROLE);
        _grantRole(APR_BONUS_ADMIN_ROLE, msg.sender);
    }
}

abstract contract MoeMigratableSupervised is Supervised {
    /** role grants right to seal MOE migration */
    bytes32 public constant MOE_SEAL_ROLE = keccak256("MOE_SEAL_ROLE");
    bytes32 public constant MOE_SEAL_ADMIN_ROLE = keccak256("MOE_SEAL_ADMIN_ROLE");

    constructor() {
        _setRoleAdmin(MOE_SEAL_ROLE, MOE_SEAL_ADMIN_ROLE);
        _grantRole(MOE_SEAL_ADMIN_ROLE, msg.sender);
    }
}

abstract contract SovMigratableSupervised is Supervised {
    /** role grants right to seal SOV migration */
    bytes32 public constant SOV_SEAL_ROLE = keccak256("SOV_SEAL_ROLE");
    bytes32 public constant SOV_SEAL_ADMIN_ROLE = keccak256("SOV_SEAL_ADMIN_ROLE");

    constructor() {
        _setRoleAdmin(SOV_SEAL_ROLE, SOV_SEAL_ADMIN_ROLE);
        _grantRole(SOV_SEAL_ADMIN_ROLE, msg.sender);
    }
}

abstract contract NftMigratableSupervised is Supervised {
    /** role grants right to seal NFT immigration */
    bytes32 public constant NFT_SEAL_ROLE = keccak256("NFT_SEAL_ROLE");
    bytes32 public constant NFT_SEAL_ADMIN_ROLE = keccak256("NFT_SEAL_ADMIN_ROLE");
    /** role grants right to open NFT emigration */
    bytes32 public constant NFT_OPEN_ROLE = keccak256("NFT_OPEN_ROLE");
    bytes32 public constant NFT_OPEN_ADMIN_ROLE = keccak256("NFT_OPEN_ADMIN_ROLE");

    constructor() {
        _setRoleAdmin(NFT_SEAL_ROLE, NFT_SEAL_ADMIN_ROLE);
        _grantRole(NFT_SEAL_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(NFT_OPEN_ROLE, NFT_OPEN_ADMIN_ROLE);
        _grantRole(NFT_OPEN_ADMIN_ROLE, msg.sender);
    }
}

abstract contract NftRoyaltySupervised is Supervised {
    /** role grants right to set the NFT's default royalty */
    bytes32 public constant NFT_ROYALTY_ROLE = keccak256("NFT_ROYALTY_ROLE");
    bytes32 public constant NFT_ROYALTY_ADMIN_ROLE = keccak256("NFT_ROYALTY_ADMIN_ROLE");
    /** role grants right to set the NFT's default royalty beneficiary */
    bytes32 public constant NFT_ROYAL_ROLE = keccak256("NFT_ROYAL_ROLE");
    bytes32 public constant NFT_ROYAL_ADMIN_ROLE = keccak256("NFT_ROYAL_ADMIN_ROLE");

    constructor() {
        _setRoleAdmin(NFT_ROYALTY_ROLE, NFT_ROYALTY_ADMIN_ROLE);
        _grantRole(NFT_ROYALTY_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(NFT_ROYAL_ROLE, NFT_ROYAL_ADMIN_ROLE);
        _grantRole(NFT_ROYAL_ADMIN_ROLE, msg.sender);
    }
}

abstract contract URIMalleableSupervised is Supervised {
    /** role grants right to change metadata URIs */
    bytes32 public constant URI_DATA_ROLE = keccak256("URI_DATA_ROLE");
    bytes32 public constant URI_DATA_ADMIN_ROLE = keccak256("URI_DATA_ADMIN_ROLE");

    constructor() {
        _setRoleAdmin(URI_DATA_ROLE, URI_DATA_ADMIN_ROLE);
        _grantRole(URI_DATA_ADMIN_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Constants {
    /** a century in [seconds] (approximation) */
    uint256 internal constant CENTURY = 365_25 days;
    /** a year in [seconds] (approximation) */
    uint256 internal constant YEAR = CENTURY / 100;
    /** a month [seconds] (approximation) */
    uint256 internal constant MONTH = YEAR / 12;
    /** number of decimals of representation */
    uint8 internal constant DECIMALS = 18;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * Allows to integrate over an array of (stamp, value) tuples, and to take
 * the duration i.e. Δ-stamp weighted arithmetic mean of those values.
 */
library Integrator {
    struct Item {
        /** stamp of value */
        uint256 stamp;
        /** value of interest */
        uint256 value;
        /** cumulative sum over Δ-stamps × values */
        uint256 area;
        /** meta of value */
        bytes meta;
    }

    /** @return head item */
    function headOf(Item[] storage items) internal view returns (Item memory) {
        return items.length > 0 ? items[0] : Item(0, 0, 0, "");
    }

    /** @return last item */
    function lastOf(Item[] storage items) internal view returns (Item memory) {
        return items.length > 0 ? items[items.length - 1] : Item(0, 0, 0, "");
    }

    /** @return next item (for stamp, value & and) */
    function _nextOf(
        Item[] storage items,
        uint256 stamp,
        uint256 value,
        bytes memory meta
    ) private view returns (Item memory) {
        if (items.length > 0) {
            Item memory last = items[items.length - 1];
            require(stamp >= last.stamp, "invalid stamp");
            uint256 area = value * (stamp - last.stamp);
            return Item(stamp, value, last.area + area, meta);
        }
        return Item(stamp, value, 0, meta);
    }

    /** @return Δ-stamp weighted arithmetic mean of values (incl. next stamp & value) */
    function meanOf(Item[] storage items, uint256 stamp, uint256 value) internal view returns (uint256) {
        uint256 area = areaOf(items, stamp, value);
        Item memory head = headOf(items);
        if (stamp > head.stamp) {
            return area / (stamp - head.stamp);
        }
        return head.value;
    }

    /** @return area of Δ-stamps × values (incl. next stamp and value) */
    function areaOf(Item[] storage items, uint256 stamp, uint256 value) internal view returns (uint256) {
        return _nextOf(items, stamp, value, "").area;
    }

    /** append (stamp, value, meta) to items (with stamp >= last?.stamp) */
    function append(Item[] storage items, uint256 stamp, uint256 value, bytes memory meta) internal {
        items.push(_nextOf(items, stamp, value, meta));
    }

    /** append (stamp, value) to items (with stamp >= last?.stamp) */
    function append(Item[] storage items, uint256 stamp, uint256 value) internal {
        append(items, stamp, value, "");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

struct Polynomial {
    uint256[] array;
}

library Polynomials {
    /**
     * @return value evaluated with (value+[5-4])*[3/2]+[1-0]
     *
     * Evaluates a `value` using a linear function -- defined by
     * the provided polynomial coefficients.
     */
    function eval6(Polynomial memory p, uint256 value) internal pure returns (uint256) {
        uint256 delta = sub(value + p.array[5], p.array[4]);
        uint256 ratio = div(delta * p.array[3], p.array[2]);
        return sub(ratio + p.array[1], p.array[0]);
    }

    /**
     * @return value evaluated with (value+[4-3])*[2/1]+[0]
     *
     * Evaluates a `value` using a linear function -- defined by
     * the provided polynomial coefficients.
     */
    function eval5(Polynomial memory p, uint256 value) internal pure returns (uint256) {
        uint256 delta = sub(value + p.array[4], p.array[3]);
        uint256 ratio = div(delta * p.array[2], p.array[1]);
        return ratio + p.array[0];
    }

    /**
     * @return value evaluated with (value)*[3/2]+[1-0]
     *
     * Evaluates a `value` using a linear function -- defined by
     * the provided polynomial coefficients.
     */
    function eval4(Polynomial memory p, uint256 value) internal pure returns (uint256) {
        uint256 ratio = div(value * p.array[3], p.array[2]);
        return sub(ratio + p.array[1], p.array[0]);
    }

    /**
     * @return value evaluated with (value)*[2/1]+[0]
     *
     * Evaluates a `value` using a linear function -- defined by
     * the provided polynomial coefficients.
     */
    function eval3(Polynomial memory p, uint256 value) internal pure returns (uint256) {
        uint256 ratio = div(value * p.array[2], p.array[1]);
        return ratio + p.array[0];
    }

    /**
     * @return value evaluated with (value+[5-4])*[3/2]+[1-0]
     *
     * Evaluates a `value` using a linear function -- defined by
     * the provided polynomial coefficients. Negative underflows
     * are avoided by clamping at `0`. Further, division-by-zero
     * panics are prevented by clamping at `type(uint256).max`.
     */
    function eval6Clamped(Polynomial memory p, uint256 value) internal pure returns (uint256) {
        uint256 delta = subClamped(value + p.array[5], p.array[4]);
        uint256 ratio = divClamped(delta * p.array[3], p.array[2]);
        return subClamped(ratio + p.array[1], p.array[0]);
    }

    /**
     * @return value evaluated with (value+[4-3])*[2/1]+[0]
     *
     * Evaluates a `value` using a linear function -- defined by
     * the provided polynomial coefficients. And division-by-zero
     * panics are prevented by clamping at `type(uint256).max`.
     */
    function eval5Clamped(Polynomial memory p, uint256 value) internal pure returns (uint256) {
        uint256 delta = subClamped(value + p.array[4], p.array[3]);
        uint256 ratio = divClamped(delta * p.array[2], p.array[1]);
        return ratio + p.array[0];
    }

    /**
     * @return value evaluated with (value)*[3/2]+[1-0]
     *
     * Evaluates a `value` using a linear function -- defined by
     * the provided polynomial coefficients. Negative underflows
     * are avoided by clamping at `0`. Further, division-by-zero
     * panics are prevented by clamping at `type(uint256).max`.
     */
    function eval4Clamped(Polynomial memory p, uint256 value) internal pure returns (uint256) {
        uint256 ratio = divClamped(value * p.array[3], p.array[2]);
        return subClamped(ratio + p.array[1], p.array[0]);
    }

    /**
     * @return value evaluated with (value)*[2/1]+[0]
     *
     * Evaluates a `value` using a linear function -- defined by
     * the provided polynomial coefficients. And division-by-zero
     * panics are prevented by clamping at `type(uint256).max`.
     */
    function eval3Clamped(Polynomial memory p, uint256 value) internal pure returns (uint256) {
        uint256 ratio = divClamped(value * p.array[2], p.array[1]);
        return ratio + p.array[0];
    }

    function sub(uint256 lhs, uint256 rhs) private pure returns (uint256) {
        return lhs - rhs; // allow less-than-0 error
    }

    function subClamped(uint256 lhs, uint256 rhs) private pure returns (uint256) {
        return lhs > rhs ? lhs - rhs : 0; // avoid less-than-0 error
    }

    function div(uint256 lhs, uint256 rhs) private pure returns (uint256) {
        return lhs / rhs; // allow div-by-0 error
    }

    function divClamped(uint256 lhs, uint256 rhs) private pure returns (uint256) {
        return rhs > 0 ? lhs / rhs : type(uint256).max; // avoid div-by-0 error
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Constants} from "../libs/Constants.sol";

/**
 * @title Rug pull protection
 */
library Rpp {
    /** validate params: w.r.t. Polynomial.eval3 */
    function checkArray(uint256[] memory array) internal pure {
        require(array.length == 3, "invalid array.length");
        // eliminate possibility of division-by-zero
        require(array[1] > 0, "invalid array[1] == 0");
        // eliminate possibility of all-zero values
        require(array[2] > 0, "invalid array[2] == 0");
    }

    /** validate change: 0.5 <= next / last <= 2.0 or next <= unit */
    function checkValue(uint256 nextValue, uint256 lastValue) internal pure {
        if (nextValue < lastValue) {
            require(lastValue <= 2 * nextValue, "invalid change: too small");
        }
        if (nextValue > lastValue && lastValue > 0) {
            require(nextValue <= 2 * lastValue, "invalid change: too large");
        }
        if (nextValue > lastValue && lastValue == 0) {
            require(nextValue <= 10 ** Constants.DECIMALS, "invalid change: too large");
        }
    }

    /** validate change: invocation frequency at most once per month */
    function checkStamp(uint256 nextStamp, uint256 lastStamp) internal pure {
        if (lastStamp > 0) {
            require(nextStamp - lastStamp > Constants.MONTH, "invalid change: too frequent");
        }
    }

    /** validate change: invocation frequency at most once per month (if empty meta) */
    function checkStamp(uint256 nextStamp, uint256 lastStamp, bytes memory meta) internal pure {
        if (meta.length == 0) checkStamp(nextStamp, lastStamp);
    }
}

// SPDX-License-Identifier: GPL-3.0
// solhint-disable not-rely-on-time
// solhint-disable no-empty-blocks
pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import {FeeTracker} from "./base/FeeTracker.sol";
import {Migratable, MoeMigratable} from "./base/Migratable.sol";
import {Supervised, XPowerSupervised} from "./base/Supervised.sol";

import {Constants} from "./libs/Constants.sol";
import {Integrator} from "./libs/Integrator.sol";
import {Polynomials, Polynomial} from "./libs/Polynomials.sol";
import {Rpp} from "./libs/Rpp.sol";

/**
 * Abstract base class for the XPower THOR, LOKI and ODIN proof-of-work tokens.
 * It verifies, that the nonce & the block-hash do result in a positive amount,
 * (as specified by the sub-classes). After the verification, the corresponding
 * amount of tokens are minted for the beneficiary (plus the treasury).
 */
abstract contract XPower is ERC20, ERC20Burnable, MoeMigratable, FeeTracker, XPowerSupervised, Ownable {
    using Integrator for Integrator.Item[];
    using Polynomials for Polynomial;

    /** set of nonce-hashes already minted for */
    mapping(bytes32 => bool) private _hashes;
    /** map from block-hashes to timestamps */
    mapping(bytes32 => uint256) private _timestamps;
    /** map from intervals to block-hashes */
    mapping(uint256 => bytes32) private _blockHashes;

    /** @param symbol short token symbol */
    /** @param moeBase addresses of old contracts */
    /** @param deadlineIn seconds to end-of-migration */
    constructor(
        string memory symbol,
        address[] memory moeBase,
        uint256 deadlineIn
    )
        // ERC20 constructor: name, symbol
        ERC20("XPower", symbol)
        // Migratable: old contract, rel. deadline [seconds]
        Migratable(moeBase, deadlineIn)
    {}

    /** @return number of decimals of representation */
    function decimals() public view virtual override returns (uint8) {
        return Constants.DECIMALS;
    }

    /** emitted on caching most recent block-hash */
    event Init(bytes32 blockHash, uint256 timestamp);

    /** cache most recent block-hash */
    function init() external {
        uint256 interval = currentInterval();
        assert(interval > 0);
        if (uint256(_blockHashes[interval]) == 0) {
            bytes32 blockHash = blockhash(block.number - 1);
            assert(blockHash > 0);
            uint256 timestamp = block.timestamp;
            assert(timestamp > 0);
            _cache(blockHash, timestamp);
            _blockHashes[interval] = blockHash;
            emit Init(blockHash, timestamp);
        } else {
            bytes32 blockHash = _blockHashes[interval];
            uint256 timestamp = _timestamps[blockHash];
            emit Init(blockHash, timestamp);
        }
    }

    /** cache block-hash at timestamp */
    function _cache(bytes32 blockHash, uint256 timestamp) internal {
        _timestamps[blockHash] = timestamp;
    }

    /** mint tokens for to-beneficiary, block-hash & data (incl. nonce) */
    function mint(address to, bytes32 blockHash, bytes memory data) external tracked {
        // check block-hash to be in current interval
        require(recent(blockHash), "expired block-hash");
        // calculate nonce-hash & pair-index for to, block-hash & data
        (bytes32 nonceHash, bytes32 pairIndex) = hashOf(to, blockHash, data);
        require(unique(pairIndex), "duplicate nonce-hash");
        // calculate number of zeros of nonce-hash
        uint256 zeros = zerosOf(nonceHash);
        require(zeros > 0, "empty nonce-hash");
        // calculate amount of tokens of zeros
        uint256 amount = amountOf(zeros);
        // ensure unique (nonce-hash, block-hash)
        _hashes[pairIndex] = true;
        // mint for project treasury
        _mint(owner(), shareOf(amount));
        // mint for beneficiary
        _mint(to, amount);
    }

    /** @return block-hash (for interval) */
    function blockHashOf(uint256 interval) public view returns (bytes32) {
        return _blockHashes[interval];
    }

    /** @return current interval's timestamp */
    function currentInterval() public view returns (uint256) {
        return block.timestamp - (block.timestamp % (1 hours));
    }

    /** check whether block-hash has recently been cached */
    function recent(bytes32 blockHash) public view returns (bool) {
        return _timestamps[blockHash] > currentInterval();
    }

    /** @return hash of contract, to-beneficiary, block-hash & data (incl. nonce) */
    function hashOf(address to, bytes32 blockHash, bytes memory data) public view returns (bytes32, bytes32) {
        bytes32 nonceHash = keccak256(bytes.concat(bytes20(uint160(address(this)) ^ uint160(to)), blockHash, data));
        return (nonceHash, nonceHash ^ blockHash);
    }

    /** check whether (nonce-hash, block-hash) pair is unique */
    function unique(bytes32 pairIndex) public view returns (bool) {
        return !_hashes[pairIndex];
    }

    /** @return leading-zeros (for nonce-hash) */
    function zerosOf(bytes32 nonceHash) public pure returns (uint8) {
        if (nonceHash > 0) {
            return uint8(63 - (Math.log2(uint256(nonceHash)) >> 2));
        }
        return 64;
    }

    /** @return amount (for level) */
    function amountOf(uint256 level) public view virtual returns (uint256);

    /** integrator of shares: [(stamp, value)] */
    Integrator.Item[] public shares;
    /** parametrization of share: coefficients */
    uint256[] private _share;

    /** @return duration weighted mean of shares (for amount) */
    function shareOf(uint256 amount) public view returns (uint256) {
        if (shares.length == 0) {
            return shareTargetOf(amount);
        }
        uint256 stamp = block.timestamp;
        uint256 value = shareTargetOf(amountOf(1));
        uint256 point = shares.meanOf(stamp, value);
        return (point * amount) / amountOf(1);
    }

    /** @return share target (for amount) */
    function shareTargetOf(uint256 amount) public view returns (uint256) {
        return shareTargetOf(amount, getShare());
    }

    /** @return share target (for amount & parametrization) */
    function shareTargetOf(uint256 amount, uint256[] memory array) private pure returns (uint256) {
        return Polynomial(array).eval3(amount);
    }

    /** fractional treasury share: 50[%] */
    uint256 private constant SHARE_MUL = 1;
    uint256 private constant SHARE_DIV = 2;

    /** @return share parameters */
    function getShare() public view returns (uint256[] memory) {
        if (_share.length > 0) {
            return _share;
        }
        uint256[] memory array = new uint256[](3);
        array[1] = SHARE_DIV;
        array[2] = SHARE_MUL;
        return array;
    }

    /** set share parameters */
    function setShare(uint256[] memory array) public onlyRole(SHARE_ROLE) {
        Rpp.checkArray(array);
        // check share reparametrization of value
        uint256 nextValue = shareTargetOf(amountOf(1), array);
        uint256 currValue = shareTargetOf(amountOf(1));
        Rpp.checkValue(nextValue, currValue);
        // check share reparametrization of stamp
        uint256 lastStamp = shares.lastOf().stamp;
        uint256 currStamp = block.timestamp;
        Rpp.checkStamp(currStamp, lastStamp);
        // append (stamp, share-of) to integrator
        shares.append(currStamp, currValue);
        // all requirements true: use array
        _share = array;
    }

    /** @return true if this contract implements the interface defined by interface-id */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(MoeMigratable, Supervised) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /** @return prefix of token */
    function prefix() external pure virtual returns (uint256);

    /** @return fee-estimate plus averages over gas and gas-price */
    function fees() external view virtual returns (uint256[] memory);
}

/**
 * Allow mining & minting for THOR proof-of-work tokens, where the rewarded
 * amount equals to *only* |leading-zeros(nonce-hash)|.
 */
contract XPowerThor is XPower {
    /** @param moeBase addresses of old contracts */
    /** @param deadlineIn seconds to end-of-migration */
    constructor(address[] memory moeBase, uint256 deadlineIn) XPower("THOR", moeBase, deadlineIn) {}

    /** @return amount (for level) */
    function amountOf(uint256 level) public view override returns (uint256) {
        return level * 10 ** decimals();
    }

    /** @return prefix of token */
    function prefix() external pure override returns (uint256) {
        return 1;
    }

    /** @return fee-estimate plus averages over gas and gas-price */
    function fees() external view override returns (uint256[] memory) {
        return _fees(FEE_ADD, FEE_MUL, FEE_DIV);
    }

    /** fee-tracker estimate: 21_000+700+1360+1088+68*8 */
    uint256 private constant FEE_ADD = 24_692_000_000_000;
    uint256 private constant FEE_MUL = 10428468600436929;
    uint256 private constant FEE_DIV = 10000000000000000;
}

/**
 * Allow mining & minting for LOKI proof-of-work tokens, where the rewarded
 * amount equals to 2 ^ |leading-zeros(nonce-hash)| - 1.
 */
contract XPowerLoki is XPower {
    /** @param moeBase addresses of old contracts */
    /** @param deadlineIn seconds to end-of-migration */
    constructor(address[] memory moeBase, uint256 deadlineIn) XPower("LOKI", moeBase, deadlineIn) {}

    /** @return amount (for level) */
    function amountOf(uint256 level) public view override returns (uint256) {
        return (2 ** level - 1) * 10 ** decimals();
    }

    /** @return prefix of token */
    function prefix() external pure override returns (uint256) {
        return 2;
    }

    /** @return fee-estimate plus averages over gas and gas-price */
    function fees() external view override returns (uint256[] memory) {
        return _fees(FEE_ADD, FEE_MUL, FEE_DIV);
    }

    /** fee-tracker estimate: 21_000+700+1360+1088+68*8 */
    uint256 private constant FEE_ADD = 24_692_000_000_000;
    uint256 private constant FEE_MUL = 10428235353319326;
    uint256 private constant FEE_DIV = 10000000000000000;
}

/**
 * Allow mining & minting for ODIN proof-of-work tokens, where the rewarded
 * amount equals to 16 ^ |leading-zeros(nonce-hash)| - 1.
 */
contract XPowerOdin is XPower {
    /** @param moeBase addresses of old contracts */
    /** @param deadlineIn seconds to end-of-migration */
    constructor(address[] memory moeBase, uint256 deadlineIn) XPower("ODIN", moeBase, deadlineIn) {}

    /** @return amount (for level) */
    function amountOf(uint256 level) public view override returns (uint256) {
        return (16 ** level - 1) * 10 ** decimals();
    }

    /** @return prefix of token */
    function prefix() external pure override returns (uint256) {
        return 3;
    }

    /** @return fee-estimate plus averages over gas and gas-price */
    function fees() external view override returns (uint256[] memory) {
        return _fees(FEE_ADD, FEE_MUL, FEE_DIV);
    }

    /** fee-tracker estimate: 21_000+700+1360+1088+68*8 */
    uint256 private constant FEE_ADD = 24_692_000_000_000;
    uint256 private constant FEE_MUL = 10427908964095862;
    uint256 private constant FEE_DIV = 10000000000000000;
}