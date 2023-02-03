// SPDX-License-Identifier: MIT

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {Address} from '../../@openzeppelin/contracts/utils/Address.sol';
import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  SafeERC20
} from '../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {
  AccessControlEnumerable
} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {
  ReentrancyGuard
} from '../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {SynthereumFactoryAccess} from '../common/libs/FactoryAccess.sol';
import {SynthereumInterfaces} from '../core/Constants.sol';
import {
  ICreditLineLendingTransfer
} from '../self-minting/v3/interfaces/ICreditLineLendingTransfer.sol';
import {
  ILendingCreditLineManager
} from './interfaces/ILendingCreditLineManager.sol';
import {
  ILendingCreditLineModule
} from './interfaces/ILendingCreditLineModule.sol';
import {
  ILendingCreditLineStorageManager
} from './interfaces/ILendingCreditLineStorageManager.sol';
import {ManagerDataTypes} from './ManagerDataTypes.sol';
import {InterestRateLogic} from './InterestRateLogic.sol';

contract LendingCreditLineManager is
  ILendingCreditLineManager,
  ReentrancyGuard,
  AccessControlEnumerable
{
  using Address for address;
  using SafeERC20 for IERC20;

  ISynthereumFinder immutable synthereumFinder;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  string private constant DEPOSIT_SIG =
    'deposit((bytes32,address,address,uint256,uint256,uint256,uint256,uint64,uint64),bytes,uint256)';

  string private constant WITHDRAW_SIG =
    'withdraw((bytes32,address,address,uint256,uint256,uint256,uint256,uint64,uint64),address,bytes,uint256,address)';

  string private JRTSWAP_SIG =
    'swapToJRT(address,address,address,uint256,bytes)';

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  constructor(ISynthereumFinder _finder, ManagerDataTypes.Roles memory _roles)
    nonReentrant
  {
    synthereumFinder = _finder;

    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  function deposit(
    uint256 _amount,
    uint256 _feesAmount,
    address _recipient
  )
    external
    override
    nonReentrant
    returns (uint256 newUserDeposit, uint256 newTotalDeposit)
  {
    (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo,
      ILendingCreditLineStorageManager creditLineStorageManager
    ) = _getCreditLineStorageData(msg.sender);

    ILendingCreditLineModule.ReturnValues memory res =
      _depositToLendingModule(creditLineInfo, lendingInfo, _amount);

    (newUserDeposit, newTotalDeposit) = creditLineStorageManager.updateValues(
      msg.sender,
      _recipient,
      res.tokensOut,
      res.currentBalance,
      _feesAmount,
      true
    );
  }

  function withdraw(uint256 _amount, address _recipient)
    external
    override
    nonReentrant
    returns (uint256 newUserDeposit, uint256 newTotalDeposit)
  {
    (newUserDeposit, newTotalDeposit) = _withdrawTo(
      _amount,
      _recipient,
      _recipient
    );
  }

  function withdrawTo(
    uint256 _amount,
    address _recipient,
    address _liquidator
  )
    external
    override
    nonReentrant
    returns (uint256 newUserDeposit, uint256 newTotalDeposit)
  {
    (newUserDeposit, newTotalDeposit) = _withdrawTo(
      _amount,
      _recipient,
      _liquidator
    );
  }

  function applyProtocolFees(uint256 _amount, address _recipient)
    external
    override
    nonReentrant
    returns (uint256 newUserDeposit, uint256 newTotalDeposit)
  {
    (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo,
      ILendingCreditLineStorageManager creditLineStorageManager
    ) = _getCreditLineStorageData(msg.sender);

    uint256 currentBalance =
      _getLendingCurrentBalanceInCollateral(
        msg.sender,
        creditLineInfo,
        lendingInfo
      );

    (newUserDeposit, newTotalDeposit) = creditLineStorageManager.updateValues(
      msg.sender,
      _recipient,
      0,
      currentBalance,
      _amount,
      true
    );
  }

  function batchClaimCommission(address[] calldata _creditLines)
    external
    override
    onlyMaintainer
    nonReentrant
    returns (uint256 totalClaimed)
  {
    address recipient =
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.CommissionReceiver
      );
    for (uint8 i = 0; i < _creditLines.length; i++) {
      totalClaimed += _claimCommission(_creditLines[i], recipient);
    }
  }

  function claimCommission(address _creditLine)
    public
    override
    onlyMaintainer
    nonReentrant
    returns (uint256 totalClaimed)
  {
    address recipient =
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.CommissionReceiver
      );
    totalClaimed = _claimCommission(_creditLine, recipient);
  }

  function batchClaimProtocolFees(address[] calldata _creditLines)
    external
    override
    onlyMaintainer
    nonReentrant
    returns (uint256 totalClaimed)
  {
    address recipient =
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.ProtocolReceiver
      );
    for (uint8 i = 0; i < _creditLines.length; i++) {
      totalClaimed += _claimProtocolFees(_creditLines[i], recipient);
    }
  }

  function claimProtocolFees(address _creditLines)
    external
    override
    onlyMaintainer
    nonReentrant
    returns (uint256 totalClaimed)
  {
    address recipient =
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.CommissionReceiver
      );
    totalClaimed = _claimProtocolFees(_creditLines, recipient);
  }

  function batchBuyback(
    address[] calldata _creditLines,
    address _collateralAddress,
    address _user,
    bytes calldata _swapParams
  ) external override nonReentrant returns (uint256 jrtAmount) {
    ILendingCreditLineStorageManager creditLineStorageManager =
      getStorageManager();

    // withdraw collateral and update all creditLines
    uint256 aggregatedCollateral;
    for (uint8 i = 0; i < _creditLines.length; i++) {
      address _creditLine = _creditLines[i];
      (
        ManagerDataTypes.CreditLineInfo memory creditLineInfo,
        ManagerDataTypes.LendingInfo memory lendingInfo
      ) = creditLineStorageManager.getCreditLineData(_creditLine);

      // all creditLines need to have the same collateral
      require(
        creditLineInfo.collateralToken == _collateralAddress,
        'Collateral mismatch'
      );

      uint256 collateralAmountForBuyBack =
        _getCollateralAmountForBuyBack(
          creditLineInfo,
          lendingInfo,
          creditLineStorageManager,
          _user,
          _creditLine
        );
      aggregatedCollateral += collateralAmountForBuyBack;
    }
    if (aggregatedCollateral == 0) return (0);

    // execute the buyback call with all the withdrawn collateral
    jrtAmount = _swapCollateralToJRT(
      creditLineStorageManager,
      aggregatedCollateral,
      _collateralAddress,
      _user,
      _swapParams
    );

    emit BatchBuyback(aggregatedCollateral, jrtAmount, _user);
  }

  function claimBuyBack(
    address _creditLine,
    address _collateralAddress,
    address _user,
    bytes calldata _swapParams
  ) external override nonReentrant returns (uint256 jrtAmount) {
    (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo,
      ILendingCreditLineStorageManager creditLineStorageManager
    ) = _getCreditLineStorageData(_creditLine);

    // all creditLines need to have the same collateral
    require(
      creditLineInfo.collateralToken == _collateralAddress,
      'Collateral mismatch'
    );

    uint256 collateralAmountForBuyBack =
      _getCollateralAmountForBuyBack(
        creditLineInfo,
        lendingInfo,
        creditLineStorageManager,
        _user,
        _creditLine
      );
    if (collateralAmountForBuyBack == 0) return (0);

    // execute the buyback call with all the withdrawn collateral
    jrtAmount = _swapCollateralToJRT(
      creditLineStorageManager,
      collateralAmountForBuyBack,
      _collateralAddress,
      _user,
      _swapParams
    );

    emit Buyback(collateralAmountForBuyBack, jrtAmount, _user);
  }

  // to migrate liquidity to another lending module
  function migrateLendingModule(
    string memory _newLendingID,
    address _newInterestBearingToken
  )
    external
    override
    nonReentrant
    returns (ManagerDataTypes.MigrateReturnValues memory)
  {
    (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo,
      ILendingCreditLineStorageManager creditLineStorageManager
    ) = _getCreditLineStorageData(msg.sender);

    uint256 currentBalance =
      _getLendingCurrentBalanceInCollateral(
        msg.sender,
        creditLineInfo,
        lendingInfo
      );

    creditLineStorageManager.refreshGlobalDataRate(msg.sender, currentBalance);

    (uint256 interestTokenAmount, ) =
      collateralToInterestToken(msg.sender, currentBalance);
    interestTokenAmount = ICreditLineLendingTransfer(msg.sender)
      .transferToLendingManager(interestTokenAmount);

    ILendingCreditLineModule.ReturnValues memory withdrawRes =
      _withdrawFromLendingModule(
        creditLineInfo,
        lendingInfo,
        msg.sender,
        interestTokenAmount,
        address(this)
      );

    uint256 prevDepositedCollateral = withdrawRes.tokensTransferred;
    // set new lending module and obtain new pool data

    ManagerDataTypes.LendingInfo memory newLendingInfo;
    (creditLineInfo, newLendingInfo) = creditLineStorageManager
      .migrateLendingModule(
      _newLendingID,
      msg.sender,
      _newInterestBearingToken
    );

    ILendingCreditLineModule.ReturnValues memory depositRes =
      _depositToLendingModule(
        creditLineInfo,
        newLendingInfo,
        withdrawRes.tokensTransferred
      );

    uint256 actualCollateralDeposited = depositRes.tokensTransferred;

    currentBalance = _getLendingCurrentBalanceInCollateral(
      msg.sender,
      creditLineInfo,
      newLendingInfo
    );

    creditLineStorageManager.refreshGlobalDataRate(msg.sender, currentBalance);

    return (
      ManagerDataTypes.MigrateReturnValues(
        prevDepositedCollateral,
        actualCollateralDeposited
      )
    );
  }

  function setLendingModule(
    string calldata _id,
    ManagerDataTypes.LendingInfo calldata _lendingInfo
  ) external override onlyMaintainer nonReentrant {
    ILendingCreditLineStorageManager creditLineStorageManager =
      getStorageManager();
    creditLineStorageManager.setLendingModule(_id, _lendingInfo);
  }

  function addSwapProtocol(address _swapModule)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    ILendingCreditLineStorageManager creditLineStorageManager =
      getStorageManager();
    creditLineStorageManager.addSwapProtocol(_swapModule);
  }

  function removeSwapProtocol(address _swapModule)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    ILendingCreditLineStorageManager creditLineStorageManager =
      getStorageManager();
    creditLineStorageManager.removeSwapProtocol(_swapModule);
  }

  function setSwapModule(address _collateral, address _swapModule)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    ILendingCreditLineStorageManager creditLineStorageManager =
      getStorageManager();
    creditLineStorageManager.setSwapModule(_collateral, _swapModule);
  }

  function setShares(
    address _creditLine,
    uint64 _commissionInterestShare,
    uint64 _jrtInterestShare
  ) external override onlyMaintainer nonReentrant {
    ILendingCreditLineStorageManager creditLineStorageManager =
      getStorageManager();
    creditLineStorageManager.setShares(
      _creditLine,
      _commissionInterestShare,
      _jrtInterestShare
    );
  }

  function getPendingInterest(address _creditLine, address _recipient)
    external
    view
    override
    returns (uint256 collateralInterest, uint256 buyBackInterest)
  {
    (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo,
      ILendingCreditLineStorageManager creditLineStorageManager
    ) = _getCreditLineStorageData(_creditLine);

    uint256 currentBalance =
      _getLendingCurrentBalanceInCollateral(
        _creditLine,
        creditLineInfo,
        lendingInfo
      );

    (collateralInterest, buyBackInterest) = creditLineStorageManager
      .getPendingInterest(currentBalance, _creditLine, _recipient);
  }

  function interestTokenToCollateral(
    address _creditLine,
    uint256 _interestTokenAmount
  )
    external
    view
    override
    returns (uint256 collateralAmount, address interestTokenAddr)
  {
    ILendingCreditLineStorageManager creditLineStorageManager =
      getStorageManager();
    (
      ManagerDataTypes.LendingStorage memory lendingStorage,
      ManagerDataTypes.LendingInfo memory lendingInfo
    ) = creditLineStorageManager.getLendingData(_creditLine);

    collateralAmount = ILendingCreditLineModule(lendingInfo.lendingModule)
      .interestTokenToCollateral(
      _interestTokenAmount,
      lendingStorage.collateralToken,
      lendingStorage.interestToken,
      lendingInfo.args
    );
    interestTokenAddr = lendingStorage.interestToken;
  }

  function collateralToInterestToken(
    address _creditLine,
    uint256 _collateralAmount
  )
    public
    view
    override
    returns (uint256 interestTokenAmount, address interestTokenAddr)
  {
    ILendingCreditLineStorageManager creditLineStorageManager =
      getStorageManager();
    (
      ManagerDataTypes.LendingStorage memory lendingStorage,
      ManagerDataTypes.LendingInfo memory lendingInfo
    ) = creditLineStorageManager.getLendingData(_creditLine);

    interestTokenAmount = ILendingCreditLineModule(lendingInfo.lendingModule)
      .collateralToInterestToken(
      _collateralAmount,
      lendingStorage.collateralToken,
      lendingStorage.interestToken,
      lendingInfo.args
    );

    interestTokenAddr = lendingStorage.interestToken;
  }

  function _claimCommission(address _creditLine, address _recipient)
    internal
    returns (uint256 amountClaimed)
  {
    (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo,
      ILendingCreditLineStorageManager creditLineStorageManager
    ) = _getCreditLineStorageData(_creditLine);

    uint256 currentBalance =
      _getLendingCurrentBalanceInCollateral(
        _creditLine,
        creditLineInfo,
        lendingInfo
      );

    creditLineStorageManager.refreshGlobalDataRate(_creditLine, currentBalance);

    //refresh creditLineInfo memory values
    creditLineInfo = creditLineStorageManager.getCreditLineStorage(_creditLine);

    (uint256 interestTokenAmount, ) =
      collateralToInterestToken(_creditLine, creditLineInfo.commissionInterest);

    if (interestTokenAmount == 0) {
      emit CommissionClaim(0, _recipient, creditLineInfo.collateralToken);
      return 0;
    }

    interestTokenAmount = ICreditLineLendingTransfer(_creditLine)
      .transferToLendingManager(interestTokenAmount);

    ILendingCreditLineModule.ReturnValues memory res =
      _withdrawFromLendingModule(
        creditLineInfo,
        lendingInfo,
        _creditLine,
        interestTokenAmount,
        _recipient
      );

    amountClaimed = res.tokensTransferred;

    creditLineStorageManager.decreaseCommissionInterest(
      _creditLine,
      creditLineInfo.commissionInterest
    );

    emit CommissionClaim(
      amountClaimed,
      _recipient,
      creditLineInfo.collateralToken
    );
  }

  function _claimProtocolFees(address _creditLine, address _recipient)
    internal
    returns (uint256 amountClaimed)
  {
    (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo,
      ILendingCreditLineStorageManager creditLineStorageManager
    ) = _getCreditLineStorageData(_creditLine);

    if (creditLineInfo.protocolFees == 0) {
      return (0);
    }

    (uint256 interestTokenAmount, ) =
      collateralToInterestToken(_creditLine, creditLineInfo.protocolFees);

    interestTokenAmount = ICreditLineLendingTransfer(_creditLine)
      .transferToProtocolReceiver(interestTokenAmount);

    creditLineStorageManager.decreaseProtocolFees(
      _creditLine,
      creditLineInfo.protocolFees
    );

    amountClaimed = interestTokenAmount;

    emit ProtocolFeesClaimed(
      interestTokenAmount,
      _recipient,
      creditLineInfo.interestBearingToken
    );
  }

  function _getCollateralAmountForBuyBack(
    ManagerDataTypes.CreditLineInfo memory creditLineInfo,
    ManagerDataTypes.LendingInfo memory lendingInfo,
    ILendingCreditLineStorageManager creditLineStorageManager,
    address _user,
    address _creditLine
  ) internal returns (uint256 collateralAmountForBuyBack) {
    uint256 currentBalance =
      _getLendingCurrentBalanceInCollateral(
        _creditLine,
        creditLineInfo,
        lendingInfo
      );

    creditLineStorageManager.updateValues(
      _creditLine,
      _user,
      0,
      currentBalance,
      0,
      false
    );

    ManagerDataTypes.UserInterestData memory userInterestData =
      _getUserInterestData(_creditLine, _user);

    if (userInterestData.interestsReservedForJRTBuyback == 0) return (0);

    (uint256 interestTokenAmount, ) =
      collateralToInterestToken(
        _creditLine,
        userInterestData.interestsReservedForJRTBuyback
      );

    interestTokenAmount = ICreditLineLendingTransfer(_creditLine)
      .transferToLendingManager(interestTokenAmount);

    ILendingCreditLineModule.ReturnValues memory res =
      _withdrawFromLendingModule(
        creditLineInfo,
        lendingInfo,
        _creditLine,
        interestTokenAmount,
        address(this)
      );

    creditLineStorageManager.decreaseUserInterestsForJRTBuyback(
      _creditLine,
      _user,
      userInterestData.interestsReservedForJRTBuyback
    );

    collateralAmountForBuyBack = res.tokensTransferred;
  }

  function _withdrawTo(
    uint256 _amount,
    address _recipient,
    address _receiver
  ) internal returns (uint256 newUserDeposit, uint256 newTotalDeposit) {
    (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo,
      ILendingCreditLineStorageManager creditLineStorageManager
    ) = _getCreditLineStorageData(msg.sender);

    uint256 currentBalance =
      _getLendingCurrentBalanceInCollateral(
        msg.sender,
        creditLineInfo,
        lendingInfo
      );
    (newUserDeposit, newTotalDeposit) = creditLineStorageManager.updateValues(
      msg.sender,
      _recipient,
      _amount,
      currentBalance,
      0,
      false
    );

    (uint256 withdrawAmountAToken, ) =
      collateralToInterestToken(msg.sender, _amount);

    withdrawAmountAToken = ICreditLineLendingTransfer(msg.sender)
      .transferToLendingManager(withdrawAmountAToken);

    _withdrawFromLendingModule(
      creditLineInfo,
      lendingInfo,
      msg.sender,
      withdrawAmountAToken,
      _receiver
    );
  }

  function _withdrawFromLendingModule(
    ManagerDataTypes.CreditLineInfo memory creditLineInfo,
    ManagerDataTypes.LendingInfo memory lendingInfo,
    address _creditLine,
    uint256 withdrawAmount,
    address _recipient
  ) internal returns (ILendingCreditLineModule.ReturnValues memory) {
    // delegate call withdraw from lending module
    bytes memory result =
      address(lendingInfo.lendingModule).functionDelegateCall(
        abi.encodeWithSignature(
          WITHDRAW_SIG,
          creditLineInfo,
          _creditLine,
          lendingInfo.args,
          withdrawAmount,
          _recipient
        )
      );
    return abi.decode(result, (ILendingCreditLineModule.ReturnValues));
  }

  function _depositToLendingModule(
    ManagerDataTypes.CreditLineInfo memory creditLineInfo,
    ManagerDataTypes.LendingInfo memory lendingInfo,
    uint256 depositAmount
  ) internal returns (ILendingCreditLineModule.ReturnValues memory) {
    // delegate call deposit into new module
    bytes memory result =
      address(lendingInfo.lendingModule).functionDelegateCall(
        abi.encodeWithSignature(
          DEPOSIT_SIG,
          creditLineInfo,
          lendingInfo.args,
          depositAmount
        )
      );
    return abi.decode(result, (ILendingCreditLineModule.ReturnValues));
  }

  function _swapCollateralToJRT(
    ILendingCreditLineStorageManager creditLineStorageManager,
    uint256 _amountToSellForJRT,
    address _collateralAddress,
    address _receiver,
    bytes calldata _swapParams
  ) internal returns (uint256 jrtAmount) {
    address JARVIS =
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.JarvisToken
      );

    bytes memory result =
      address(
        creditLineStorageManager.getCollateralSwapModule(_collateralAddress)
      )
        .functionDelegateCall(
        abi.encodeWithSignature(
          JRTSWAP_SIG,
          _receiver,
          _collateralAddress,
          JARVIS,
          _amountToSellForJRT,
          _swapParams
        )
      );

    jrtAmount = abi.decode(result, (uint256));
  }

  function _getLendingCurrentBalanceInCollateral(
    address _creditLine,
    ManagerDataTypes.CreditLineInfo memory creditLineInfo,
    ManagerDataTypes.LendingInfo memory lendingInfo
  ) internal view returns (uint256 currentBalance) {
    currentBalance = ILendingCreditLineModule(lendingInfo.lendingModule)
      .getCurrentBalanceInCollateral(
      _creditLine,
      creditLineInfo.interestBearingToken
    );
  }

  function _getCreditLineStorageData(address _creditLine)
    internal
    view
    returns (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo,
      ILendingCreditLineStorageManager creditLineStorageManager
    )
  {
    creditLineStorageManager = getStorageManager();
    (creditLineInfo, lendingInfo) = creditLineStorageManager.getCreditLineData(
      _creditLine
    );
  }

  function _getUserInterestData(address _creditLine, address _user)
    internal
    view
    returns (ManagerDataTypes.UserInterestData memory userInterestData)
  {
    ILendingCreditLineStorageManager creditLineStorageManager =
      getStorageManager();
    userInterestData = creditLineStorageManager.getUserInterestData(
      _creditLine,
      _user
    );
  }

  function getStorageManager()
    internal
    view
    returns (ILendingCreditLineStorageManager)
  {
    return
      ILendingCreditLineStorageManager(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.LendingCreditLineStorageManager
        )
      );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
     * by making the `nonReentrant` function external, and make it call a
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
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface ISynthereumFinder {
  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
   * @param implementationAddress address of the deployed contract that implements the interface.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the deployed contract that implements the interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumFactoryVersioning
} from '../../core/interfaces/IFactoryVersioning.sol';
import {
  SynthereumInterfaces,
  FactoryInterfaces
} from '../../core/Constants.sol';

/** @title Library to use for controlling the access of a functions from the factories
 */
library SynthereumFactoryAccess {
  /**
   *@notice Revert if caller is not a Pool factory
   * @param _finder Synthereum finder
   */
  function _onlyPoolFactory(ISynthereumFinder _finder) internal view {
    ISynthereumFactoryVersioning factoryVersioning =
      ISynthereumFactoryVersioning(
        _finder.getImplementationAddress(SynthereumInterfaces.FactoryVersioning)
      );
    uint8 numberOfPoolFactories =
      factoryVersioning.numberOfFactoryVersions(FactoryInterfaces.PoolFactory);
    require(
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfPoolFactories,
        FactoryInterfaces.PoolFactory
      ),
      'Not allowed'
    );
  }

  /**
   *@notice Revert if caller is not a CreditLine factory
   * @param _finder Synthereum finder
   */
  function _onlySelfMintingFactory(ISynthereumFinder _finder) internal view {
    ISynthereumFactoryVersioning factoryVersioning =
      ISynthereumFactoryVersioning(
        _finder.getImplementationAddress(SynthereumInterfaces.FactoryVersioning)
      );
    uint8 numberOfCreditLineFactories =
      factoryVersioning.numberOfFactoryVersions(
        FactoryInterfaces.SelfMintingFactory
      );
    require(
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfCreditLineFactories,
        FactoryInterfaces.SelfMintingFactory
      ),
      'Not allowed'
    );
  }

  /**
   * @notice Revert if caller is not a Pool factory or a Fixed rate factory
   * @param _finder Synthereum finder
   */
  function _onlyPoolFactoryOrFixedRateFactory(ISynthereumFinder _finder)
    internal
    view
  {
    ISynthereumFactoryVersioning factoryVersioning =
      ISynthereumFactoryVersioning(
        _finder.getImplementationAddress(SynthereumInterfaces.FactoryVersioning)
      );
    uint8 numberOfPoolFactories =
      factoryVersioning.numberOfFactoryVersions(FactoryInterfaces.PoolFactory);
    uint8 numberOfFixedRateFactories =
      factoryVersioning.numberOfFactoryVersions(
        FactoryInterfaces.FixedRateFactory
      );
    bool isPoolFactory =
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfPoolFactories,
        FactoryInterfaces.PoolFactory
      );
    if (isPoolFactory) {
      return;
    }
    bool isFixedRateFactory =
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfFixedRateFactories,
        FactoryInterfaces.FixedRateFactory
      );
    if (isFixedRateFactory) {
      return;
    }
    revert('Sender must be a Pool or FixedRate factory');
  }

  /**
   * @notice Check if sender is a factory
   * @param _factoryVersioning SynthereumFactoryVersioning contract
   * @param _numberOfFactories Total number of versions of a factory type
   * @param _factoryKind Type of the factory
   * @return isFactory True if sender is a factory, otherwise false
   */
  function _checkSenderIsFactory(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _numberOfFactories,
    bytes32 _factoryKind
  ) private view returns (bool isFactory) {
    uint8 counterFactory;
    for (uint8 i = 0; counterFactory < _numberOfFactories; i++) {
      try _factoryVersioning.getFactoryVersion(_factoryKind, i) returns (
        address factory
      ) {
        if (msg.sender == factory) {
          isFactory = true;
          break;
        } else {
          counterFactory++;
          if (counterFactory == _numberOfFactories) {
            isFactory = false;
          }
        }
      } catch {}
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Stores common interface names used throughout Synthereum.
 */
library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant DaoTreasure = 'DaoTreasure';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant FixedRateRegistry = 'FixedRateRegistry';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant CreditLineController = 'CreditLineController';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant TrustedForwarder = 'TrustedForwarder';
  bytes32 public constant MoneyMarketManager = 'MoneyMarketManager';
  bytes32 public constant JarvisBrrrrr = 'JarvisBrrrrr';
  bytes32 public constant PrinterProxy = 'PrinterProxy';
  bytes32 public constant LendingManager = 'LendingManager';
  bytes32 public constant LendingStorageManager = 'LendingStorageManager';
  bytes32 public constant LendingCreditLineManager = 'LendingCreditLineManager';
  bytes32 public constant LendingCreditLineStorageManager =
    'LendingCreditLineStorageManager';
  bytes32 public constant CommissionReceiver = 'CommissionReceiver';
  bytes32 public constant BuybackProgramReceiver = 'BuybackProgramReceiver';
  bytes32 public constant LendingRewardsReceiver = 'LendingRewardsReceiver';
  bytes32 public constant LiquidationRewardReceiver =
    'LiquidationRewardReceiver';
  bytes32 public constant JarvisToken = 'JarvisToken';
  bytes32 public constant ProtocolReceiver = 'ProtocolReceiver';
}

library FactoryInterfaces {
  bytes32 public constant PoolFactory = 'PoolFactory';
  bytes32 public constant SelfMintingFactory = 'SelfMintingFactory';
  bytes32 public constant FixedRateFactory = 'FixedRateFactory';
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title CreditLine interface for making creditLine lending manager interacting with the creditLine
 */
interface ICreditLineLendingTransfer {
  
   /**
   * @notice Transfer a bearing amount to the lending manager
   * @notice Only the lending manager can call the function
   * @param _bearingAmount Amount of bearing token to transfer
   * @return bearingAmountOut Real bearing amount transferred to the lending manager
   */
  function transferToLendingManager(uint256 _bearingAmount)
    external
    returns (uint256 bearingAmountOut);

  /**
   * @notice Transfer a bearing amount to the protocol receiver
   * @notice Only the lending manager can call the function
   * @param _bearingAmount Amount of bearing token to transfer
   * @return bearingAmountOut Real bearing amount transferred to the lending manager
   */
  function transferToProtocolReceiver(uint256 _bearingAmount)
    external
    returns (uint256 bearingAmountOut);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ManagerDataTypes} from '../ManagerDataTypes.sol';

interface ILendingCreditLineManager {
  event BatchBuyback(
    uint256 indexed collateralIn,
    uint256 JRTOut,
    address receiver
  );
  event Buyback(uint256 indexed collateralIn, uint256 JRTOut, address receiver);

  event ProtocolFeesClaimed(
    uint256 indexed collateralOut,
    address receiver,
    address colleteralToken
  );

  event CommissionClaim(
    uint256 indexed collateralOut,
    address receiver,
    address interestBearingToken
  );

  /**
   * @notice deposits collateral into the creditLine's associated
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _amount of collateral to deposit
   * @param _feesAmount the amount of fees apply from the deposit amount
   * @param _recipient the address that deposit the collateral
   * @return newUserDeposit new user deposited value
   * @return newTotalDeposit new total deposited value
   */
  function deposit(
    uint256 _amount,
    uint256 _feesAmount,
    address _recipient
  ) external returns (uint256 newUserDeposit, uint256 newTotalDeposit);

  /**
   * @notice withdraw collateral from the creditLine's associated
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _amount of interest tokens withdraw
   * @param _recipient the address receiving the collateral from money market
   * @return newUserDeposit new user deposited value
   * @return newTotalDeposit new total deposited value
   */
  function withdraw(uint256 _amount, address _recipient)
    external
    returns (uint256 newUserDeposit, uint256 newTotalDeposit);

  /**
   * @notice withdraw user collateral from the creditLine's associated and send it to the receiver
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _amount of interest tokens withdraw
   * @param _recipient the address that colletaral will be taken
   * @param _receiver the address receiving the collateral from money market
   * @return newUserDeposit new user deposited value
   * @return newTotalDeposit new total deposited value
   */
  function withdrawTo(
    uint256 _amount,
    address _recipient,
    address _receiver
  ) external returns (uint256 newUserDeposit, uint256 newTotalDeposit);

  /**
   * @notice withdraw collateral from the creditLine's associated
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _amount of fees to apply to the recipient
   * @param _recipient the address receiving the collateral from money market
   * @return newUserDeposit new user deposited value
   * @return newTotalDeposit new total deposited value
   */
  function applyProtocolFees(uint256 _amount, address _recipient)
    external
    returns (uint256 newUserDeposit, uint256 newTotalDeposit);

  /**
   * @notice batches calls to redeem creditLineData.jrtInterest from multiple creditLines
   * @notice and executes a swap to buy Jarvis Reward Token
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _creditLines array of creditLines address to redeem collateral from
   * @param _collateralAddress address of the creditLines collateral token (all creditLines must have the same collateral)
   * @param _recipient address that receiving the buy back tokens from his deposited
   * @param _swapParams encoded bytes necessary for the swap module
   * @return jrtAmount amount of JRT bought and transfer
   */
  function batchBuyback(
    address[] calldata _creditLines,
    address _collateralAddress,
    address _recipient,
    bytes calldata _swapParams
  ) external returns (uint256 jrtAmount);

  /**
   * @notice call to redeem creditLineData.jrtInterest from creditLine
   * @notice and executes a swap to buy Jarvis Reward Token
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _creditLine address to redeem collateral from
   * @param _collateralAddress address of the creditLines collateral token
   * @param _recipient address that receiving the buy back tokens from his deposited
   * @param _swapParams encoded bytes necessary for the swap module
   * @return jrtAmount amount of JRT bought and transfer
   */
  function claimBuyBack(
    address _creditLine,
    address _collateralAddress,
    address _recipient,
    bytes calldata _swapParams
  ) external returns (uint256 jrtAmount);

  /**
   * @notice batches calls to redeem creditLineData.commissionInterest from multiple creditLines
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _creditLines array of creditLines to redeem commissions from
   * @return totalClaimed amount of commission transfered
   */
  function batchClaimCommission(address[] calldata _creditLines)
    external
    returns (uint256 totalClaimed);

  /**
   * @notice call to redeem creditLineData.commissionInterest from a creditLine
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _creditLine address of creditLines to redeem commissions from
   * @return totalClaimed amount of commission transfered
   */
  function claimCommission(address _creditLine)
    external
    returns (uint256 totalClaimed);

  /**
   * @notice batches calls to redeem creditLineData.protocolFees from multiple creditLines
   * @dev calculates and update the state regarding the protocolFees
   * @param _creditLines array of creditLines to redeem commissions from
   * @return totalClaimed amount of protocol fees transfered
   */
  function batchClaimProtocolFees(address[] calldata _creditLines)
    external
    returns (uint256 totalClaimed);

  /**
   * @notice call to redeem creditLineData.protocolFees from a creditLine
   * @dev calculates and update the state regarding the protocolFees
   * @param _creditLine address of creditLines to redeem commissions from
   * @return totalClaimed amount of protocol fees transfered
   */
  function claimProtocolFees(address _creditLine)
    external
    returns (uint256 totalClaimed);

  /**
   * @notice sets the address of the implementation of a lending module and its extraBytes
   * @param _id associated to the lending module to be set
   * @param _lendingInfo see lendingInfo struct
   */
  function setLendingModule(
    string calldata _id,
    ManagerDataTypes.LendingInfo calldata _lendingInfo
  ) external;

  /**
   * @notice Add a swap module to the whitelist
   * @param _swapModule Swap module to add
   */
  function addSwapProtocol(address _swapModule) external;

  /**
   * @notice Remove a swap module from the whitelist
   * @param _swapModule Swap module to remove
   */
  function removeSwapProtocol(address _swapModule) external;

  /**
   * @notice sets an address as the swap module associated to a specific collateral
   * @dev the swapModule must implement the IJRTSwapModule interface
   * @param _collateral collateral address associated to the swap module
   * @param _swapModule IJRTSwapModule implementer contract
   */
  function setSwapModule(address _collateral, address _swapModule) external;

  /**
   * @notice set shares on interest generated by a creditLine collateral on the lending storage manager
   * @param _creditLine creditLine address to set shares on
   * @param _commissionInterestShare share of total interest generated assigned to the commissionner
   * @param _jrtInterestShare share of the total user's interest used to buyback jrt from an AMM
   */
  function setShares(
    address _creditLine,
    uint64 _commissionInterestShare,
    uint64 _jrtInterestShare
  ) external;

  /**
   * @notice migrates liquidity from one lending module (and money market), to a new one
   * @dev calculates and return the generated interest since last state-changing operation.
   * @dev The new lending module info must be have been previously set in the storage manager
   * @param _newLendingID id associated to the new lending module info
   * @param _newInterestBearingToken address of the interest token of the new money market
   * @return migrateReturnValues check struct
   */
  function migrateLendingModule(
    string memory _newLendingID,
    address _newInterestBearingToken
  ) external returns (ManagerDataTypes.MigrateReturnValues memory);

  /**
   * @notice returns the conversion between interest token and collateral of a specific money market
   * @param _creditLine reference creditLine to check conversion
   * @param _interestTokenAmount amount of interest token to calculate conversion on
   * @return collateralAmount amount of collateral after conversion
   * @return interestTokenAddr address of the associated interest token
   */
  function interestTokenToCollateral(
    address _creditLine,
    uint256 _interestTokenAmount
  ) external view returns (uint256 collateralAmount, address interestTokenAddr);

  /**
   * @notice returns pending collateral interest and the buyback interest of a EOA from the last update
   * @dev does not update state, buy back interest only available for user
   * @param _creditLine reference creditLine to check accumulated interest
   * @param _recipient address of the EOA to check interest
   * @return collateralInterest amount pending of collateral interest generated
   * @return buyBackInterest amount of pending buyback interest generated for the user
   */
  function getPendingInterest(address _creditLine, address _recipient)
    external
    view
    returns (uint256 collateralInterest, uint256 buyBackInterest);

  /**
   * @notice returns the conversion between collateral and interest token of a specific money market
   * @param _creditLine reference creditLine to check conversion
   * @param _collateralAmount amount of collateral to calculate conversion on
   * @return interestTokenAmount amount of interest token after conversion
   * @return interestTokenAddr address of the associated interest token
   */
  function collateralToInterestToken(
    address _creditLine,
    uint256 _collateralAmount
  )
    external
    view
    returns (uint256 interestTokenAmount, address interestTokenAddr);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ManagerDataTypes} from '../ManagerDataTypes.sol';

interface ILendingCreditLineModule {
  struct ReturnValues {
    uint256 currentBalance; //total balance before deposit/withdraw
    uint256 tokensOut; //amount of tokens received from money market (before eventual fees)
    uint256 tokensTransferred; //amount of tokens finally transfered from money market (after eventual fees)
  }

  /**
   * @notice deposits collateral into the money market
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _creditLineInfo creditLine storage information
   * @param _lendingArgs encoded args needed by the specific implementation
   * @param _amount of collateral to deposit
   * @return currentBalance check ReturnValues struct
   * @return tokensOut check ReturnValues struct
   * @return tokensTransferred check ReturnValues struct
   */
  function deposit(
    ManagerDataTypes.CreditLineInfo memory _creditLineInfo,
    bytes calldata _lendingArgs,
    uint256 _amount
  )
    external
    returns (
      uint256 currentBalance,
      uint256 tokensOut,
      uint256 tokensTransferred
    );

  /**
   * @notice withdraw collateral from the money market
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _creditLineInfo creditLine storage information
   * @param _creditLine creditLine address to calculate interest on
   * @param _lendingArgs encoded args needed by the specific implementation
   * @param _aTokensAmount of interest tokens to redeem
   * @param _recipient address receiving the collateral from money market
   * @return currentBalance check ReturnValues struct
   * @return tokensOut check ReturnValues struct
   * @return tokensTransferred check ReturnValues struct
   */
  function withdraw(
    ManagerDataTypes.CreditLineInfo memory _creditLineInfo,
    address _creditLine,
    bytes calldata _lendingArgs,
    uint256 _aTokensAmount,
    address _recipient
  )
    external
    returns (
      uint256 currentBalance,
      uint256 tokensOut,
      uint256 tokensTransferred
    );

  /**
   * @notice transfer all interest token balance from an old creditLine to a new one
   * @param _oldCreditLine Address of the old creditLine
   * @param _newCreditLine Address of the new creditLine
   * @param _collateral address of collateral token
   * @param _interestToken address of interest token
   * @param _extraArgs encoded args the ILendingModule implementer might need. see ILendingManager.LendingInfo struct
   * @return prevTotalCollateral Total collateral in the old creditLine
   * @return actualTotalCollateral Total collateral in the new creditLine
   */
  function totalTransfer(
    address _oldCreditLine,
    address _newCreditLine,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  )
    external
    returns (uint256 prevTotalCollateral, uint256 actualTotalCollateral);

  /**
   * @notice returns bearing token associated to the collateral
   * @dev does not update state
   * @param _collateral collateral address to check bearing token
   * @param _extraArgs encoded args the ILendingModule implementer might need. see ILendingManager.LendingInfo struct
   * @return token bearing token
   */
  function getInterestBearingToken(
    address _collateral,
    bytes calldata _extraArgs
  ) external view returns (address token);

  /**
   * @notice returns the conversion between collateral and interest token of a specific money market
   * @param _collateralAmount amount of collateral to calculate conversion on
   * @param _collateral address of collateral token
   * @param _interestToken address of interest token
   * @param _extraArgs encoded args the ILendingModule implementer might need. see ILendingManager.LendingInfo struct
   * @return interestTokenAmount amount of interest token after conversion
   */
  function collateralToInterestToken(
    uint256 _collateralAmount,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  ) external view returns (uint256 interestTokenAmount);

  /**
   * @notice returns the conversion between interest token and collateral of a specific money market
   * @param _interestTokenAmount amount of interest token to calculate conversion on
   * @param _collateral address of collateral token
   * @param _interestToken address of interest token
   * @param _extraArgs encoded args the ILendingModule implementer might need. see ILendingManager.LendingInfo struct
   * @return collateralAmount amount of collateral token after conversion
   */
  function interestTokenToCollateral(
    uint256 _interestTokenAmount,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  ) external view returns (uint256 collateralAmount);

  /**
   * @notice returns the total balance in collateral deposited for a specific interest token
   * @param _creditLine address of the creditLine
   * @param interestBearingToken address of collateral token
   * @return currentBalance amount of collateral token after conversion
   */
  function getCurrentBalanceInCollateral(
    address _creditLine,
    address interestBearingToken
  ) external view returns (uint256 currentBalance);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ManagerDataTypes} from '../ManagerDataTypes.sol';

interface ILendingCreditLineStorageManager {
  /**
   * @notice sets a ILendingModule implementer info
   * @param _id string identifying a specific ILendingModule implementer
   * @param _lendingInfo see lendingInfo struct
   */
  function setLendingModule(
    string calldata _id,
    ManagerDataTypes.LendingInfo calldata _lendingInfo
  ) external;

  /**
   * @notice Add a swap module to the whitelist
   * @param _swapModule Swap module to add
   */
  function addSwapProtocol(address _swapModule) external;

  /**
   * @notice Remove a swap module from the whitelist
   * @param _swapModule Swap module to remove
   */
  function removeSwapProtocol(address _swapModule) external;

  /**
   * @notice sets an address as the swap module associated to a specific collateral
   * @dev the swapModule must implement the IJRTSwapModule interface
   * @param _collateral collateral address associated to the swap module
   * @param _swapModule IJRTSwapModule implementer contract
   */
  function setSwapModule(address _collateral, address _swapModule) external;

  /**
   * @notice set shares on interest generated by a creditLine collateral on the lending storage manager
   * @param _creditLine creditLine address to set shares on
   * @param _commissionInterestShare share of total interest generated assigned to the commissioner address
   * @param _jrtInterestShare share of total user interest used to buyback jrt from an AMM
   */
  function setShares(
    address _creditLine,
    uint64 _commissionInterestShare,
    uint64 _jrtInterestShare
  ) external;

  /**
   * @notice store data for lending manager associated to a creditLine
   * @param _lendingID string identifying the associated ILendingModule implementer
   * @param _creditLine creditLine address to set info
   * @param _collateralToken collateral address of the creditLine
   * @param _interestBearingToken address of the interest token in use
   * @param _commissionInterestShare share of total interest generated assigned to the commissioner address
   * @param _jrtInterestShare share of the total user interest used to buyback jrt from an AMM
   */
  function setCreditLineInfo(
    string calldata _lendingID,
    address _creditLine,
    address _collateralToken,
    address _interestBearingToken,
    uint64 _commissionInterestShare,
    uint64 _jrtInterestShare
  ) external;

  /**
   * @notice sets new lending info on a creditLine
   * @dev used when migrating liquidity from one lending module (and money market), to a new one
   * @dev The new lending module info must be have been previously set in the storage manager
   * @param _newLendingID id associated to the new lending module info
   * @param _creditLine address of the creditLine whose associated lending module is being migrated
   * @param _newInterestBearingToken address of the interest token of the new Lending Module (can be set blank)
   * @return creditLineData with the updated state
   * @return lendingInfo of the new lending module
   */
  function migrateLendingModule(
    string calldata _newLendingID,
    address _creditLine,
    address _newInterestBearingToken
  )
    external
    returns (
      ManagerDataTypes.CreditLineInfo memory,
      ManagerDataTypes.LendingInfo memory
    );

  /**
   * @notice updates state linked to interest calculation and balances for a creditLine
   * @dev should be callable only by LendingManager
   * @param _creditLine address of the creditLine to update values
   * @param _user  address of user to update
   * @param _amount amount of colletaral to deposit/withdraw
   * @param _currentBalance amount of collateral
   * @param _protocolFees amount of protocol fees to apply (if not 0 fees apply)
   * @param _isDeposit boolean to identify if it's a deposit or withdraw as base operation
   * @return newUserDeposit new user deposited value
   * @return newTotalDeposit new total deposited value
   */
  function updateValues(
    address _creditLine,
    address _user,
    uint256 _amount,
    uint256 _currentBalance,
    uint256 _protocolFees,
    bool _isDeposit
  ) external returns (uint256 newUserDeposit, uint256 newTotalDeposit);

  /**
   * @notice refresh state for interest calculation
   * @param _creditLine address of the creditLine to update
   * @param _currentBalance amount of token in the lending module
   */
  function refreshGlobalDataRate(address _creditLine, uint256 _currentBalance)
    external;

  /**
   * @notice refresh state when commission interest are claimed
   * @param _creditLine address of the creditLine to update
   * @param _amount of token claimed
   */
  function decreaseCommissionInterest(address _creditLine, uint256 _amount)
    external;

  /**
   * @notice refresh state when protocol fees are claimed
   * @param _creditLine address of the creditLine to update
   * @param _amount of token claimed
   */
  function decreaseProtocolFees(address _creditLine, uint256 _amount) external;

  /**
   * @notice refresh state for interest calculation
   * @param _creditLine address of the creditLine to update
   * @param _user address of the user that claim
   * @param _amount amount of token claimed
   */
  function decreaseUserInterestsForJRTBuyback(
    address _creditLine,
    address _user,
    uint256 _amount
  ) external;

  /**
   * @notice calculate the current pending rewards
   * @param _currentBalance current balance deposited in the lending module
   * @param _creditLine address of the creditLine
   * @param _recipient address of the EOA
   * @return collateralInterest amount of pending collateral
   * @return buyBackInterest amount of pending collateral reserved for buy back
   */
  function getPendingInterest(
    uint256 _currentBalance,
    address _creditLine,
    address _recipient
  ) external view returns (uint256 collateralInterest, uint256 buyBackInterest);

  /**
   * @notice Returns info about a supported lending module
   * @param _id Name of the module
   * @return lendingInfo Address and bytes associated to the lending mdodule
   */
  function getLendingModule(string calldata _id)
    external
    view
    returns (ManagerDataTypes.LendingInfo memory lendingInfo);

  /**
   * @notice reads CreditLineInfo of a creditLine
   * @param _creditLine address of the creditLine to read storage
   * @return creditLineInfo creditLine struct info
   */
  function getCreditLineStorage(address _creditLine)
    external
    view
    returns (ManagerDataTypes.CreditLineInfo memory creditLineInfo);

  /**
   * @notice reads UserInterestData of a user for a specific creditLine
   * @param _creditLine address of the creditLine
   * @param _user address of the user to read storage
   * @return userInterestData UserInterestData struct info
   */
  function getUserInterestData(address _creditLine, address _user)
    external
    view
    returns (ManagerDataTypes.UserInterestData memory userInterestData);

  /**
   * @notice reads creditLineStorage and LendingInfo of a creditLine
   * @param _creditLine address of the creditLine to read storage
   * @return creditLineInfo creditLine struct info
   * @return lendingInfo information of the lending module associated with the creditLine
   */
  function getCreditLineData(address _creditLine)
    external
    view
    returns (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo
    );

  /**
   * @notice reads lendingStorage and LendingInfo of a creditLine
   * @param _creditLine address of the creditLine to read storage
   * @return lendingStorage information of the addresses of collateral and intrestToken
   * @return lendingInfo information of the lending module associated with the creditLine
   */
  function getLendingData(address _creditLine)
    external
    view
    returns (
      ManagerDataTypes.LendingStorage memory lendingStorage,
      ManagerDataTypes.LendingInfo memory lendingInfo
    );

  /**
   * @notice Return the list containing every swap module supported
   * @return List of swap modules
   */
  function getSwapModules() external view returns (address[] memory);

  /**
   * @notice reads the JRT Buyback module associated to a collateral
   * @param _collateral address of the collateral to retrieve module
   * @return swapModule address of interface implementer of the IJRTSwapModule
   */
  function getCollateralSwapModule(address _collateral)
    external
    view
    returns (address swapModule);

  /**
   * @notice reads the interest beaaring token address associated to a creditLine
   * @param _creditLine address of the creditLine to retrieve interest token
   * @return interestTokenAddr address of the interest token
   */
  function getInterestBearingToken(address _creditLine)
    external
    view
    returns (address interestTokenAddr);

  /**
   * @notice reads the shares used for splitting interests between creditLine user, user buyback and commission
   * @param _creditLine address of the creditLine to retrieve interest token
   * @return commissionInterestShare Percentage of interests claimable by the commission
   * @return jrtInterestShare Percentage of interests used for the user's buyback
   */
  function getShares(address _creditLine)
    external
    view
    returns (uint256 commissionInterestShare, uint256 jrtInterestShare);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

library ManagerDataTypes {
  struct Roles {
    address admin;
    address maintainer;
  }

  struct UserInterestData {
    uint256 accDiscountRate; // User's accDiscountRate use to calculate total user's balance
    uint256 interestsReservedForJRTBuyback; // Interest amount reserved for the JRT buy back
  }

  struct CreditLineInfo {
    bytes32 lendingModuleId; // hash of the lending module id associated with the LendingInfo the creditLine currently is using
    address collateralToken; // collateral address of the creditLine
    address interestBearingToken; // interest token address of the creditLine
    uint256 commissionInterest; // Interest amount that can be claim for the commissionner
    uint256 protocolFees; // Interest amount that can be claim for the protocol
    uint256 balanceTracker; // previous balance saved used to calculate interests token generated during the period
    uint256 accRate; // accumulative Rate used to calculate the total balance of each users
    uint64 commissionInterestShare; // percentage of interests took from new rewards
    uint64 jrtInterestShare; // percentage of interests used for splitting jrt interests and collateral for the users
  }

  struct LendingStorage {
    address collateralToken; // address of the collateral token of a creditLine
    address interestToken; // address of interest token of a creditLine
  }

  struct LendingInfo {
    address lendingModule; // address of the ILendingModule interface implementer
    bytes args; // encoded args the ILendingModule implementer might need
  }

  struct ReturnValues {
    uint256 interest; //accumulated creditLine interest since last state-changing operation;
    uint256 commissionInterest; //acccumulated dao interest since last state-changing operation;
    uint256 tokensOut; //amount of collateral used for a money market operation
    uint256 tokensTransferred; //amount of tokens finally transfered/received from money market (after eventual fees)
    uint256 prevTotalCollateral; //total collateral in the creditLine before new operation
  }

  struct MigrateReturnValues {
    uint256 prevTotalCollateral; // prevDepositedCollateral collateral deposited (without last interests) before the migration
    uint256 actualTotalCollateral; // actualCollateralDeposited collateral deposited after the migration
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {WadRayMath} from '../base/utils/WadRayMath.sol';
import {ManagerDataTypes} from './ManagerDataTypes.sol';

/**
  This library implement a decentralized accumulated interest mechanism, which calculates a global accumulated rate from anytime t0 to t1 by this formula :
  
                                new_rewards(time1)
      accRate(time0) * ( 1 +  ______________________  )
                                total_balance(time0)

  And calculate users' total balance from anytime t0 to t1 by the formula below:
  
      user_accumulated_discount_rate(time1) * accRate(time1)  
  
  Where the user accumulated discount rate is calculated as below :

                                              additional_deposited_amount
   user_accumulated_discount_rate(time0) + ( ______________________________ )
                                                accRate(time1)       
*/

library InterestRateLogic {
  using WadRayMath for uint256;

  /**
   * @notice calculate the amount of pending rewards in token and buy back the user has
   * @dev The function also return the amount of pending interest claimable for the commission
   * @param userInterestData the state of the user
   * @param creditLineInfo the state of the creditLine contract
   * @param totalDeposit the total amount depositd for users
   * @param userDeposit the total amount depositd for the user
   * @param currentBalance the current balance of rewardable token
   * @param isCallForCreditLine a boolean that flag if the function is call for the creditLine itself
   * @return deposit the amount of pending interest of the EOA
   * @return buyBack the amount of pending buyback token for the user (only applicable for user)
   */
  function _pendingInterests(
    ManagerDataTypes.UserInterestData memory userInterestData,
    ManagerDataTypes.CreditLineInfo memory creditLineInfo,
    uint256 totalDeposit,
    uint256 userDeposit,
    uint256 currentBalance,
    bool isCallForCreditLine
  ) internal pure returns (uint256 deposit, uint256 buyBack) {
    uint256 newRewards = currentBalance - creditLineInfo.balanceTracker;
    uint256 newCommissionInterests =
      newRewards.wadMul(creditLineInfo.commissionInterestShare);

    if (isCallForCreditLine) {
      if (totalDeposit == 0) return (newRewards, 0);
      return (newCommissionInterests, 0);
    }

    if (totalDeposit == 0) return (0, 0);

    (deposit, buyBack) = _calculateNewUserInterests(
      userInterestData,
      creditLineInfo,
      userDeposit,
      newRewards - newCommissionInterests
    );
  }

  /**
   * @notice Refreshes the global state and subsequently decreases the user's deposited value.
   * @dev This is an internal call and meant to be called within derivative contracts.
   * @dev User's pending rewards are withdraw in priority
   * @param userInterestData the state of the user
   * @param creditLineInfo the state of the creditLine contract
   * @param value the amount by which the deposit will be increased
   * @param userDeposit the total amount depositd for the user
   * @param totalDeposit the total amount total depositd between all users
   * @param currentBalance the current balance of rewardable token
   * @return newUserDeposit the new amount deposit by for user
   * @return newTotalDeposit the new total amount deposit between all users
   */
  function _decreaseDepositedValue(
    ManagerDataTypes.UserInterestData storage userInterestData,
    ManagerDataTypes.CreditLineInfo storage creditLineInfo,
    uint256 value,
    uint256 userDeposit,
    uint256 totalDeposit,
    uint256 currentBalance
  ) internal returns (uint256 newUserDeposit, uint256 newTotalDeposit) {
    _refreshGlobalDataRate(creditLineInfo, totalDeposit, currentBalance);

    (uint256 tokenInterest, uint256 buybackInterest) =
      _calculateNewUserInterests(
        userInterestData,
        creditLineInfo,
        userDeposit,
        0
      );

    require(
      userDeposit + tokenInterest >= value,
      'INSUFFICIENT_DEPOSIT_FOR_USER'
    );

    if (value >= tokenInterest) {
      uint256 depositWithdraw = value - tokenInterest;
      newTotalDeposit = totalDeposit - depositWithdraw;
      newUserDeposit = userDeposit - depositWithdraw;
    } else {
      uint256 depositLeftAdded = tokenInterest - value;
      newTotalDeposit = totalDeposit + depositLeftAdded;
      newUserDeposit = userDeposit + depositLeftAdded;
    }
    userInterestData.interestsReservedForJRTBuyback += buybackInterest;
    if (newUserDeposit == 0) {
      userInterestData.accDiscountRate = 0;
    } else {
      userInterestData.accDiscountRate -= value.wadToRay().rayDiv(
        creditLineInfo.accRate
      );
    }
  }

  /**
   * @notice Refreshes the global state and subsequently increases the user's deposited value.
   * @dev This is an internal call and meant to be called within derivative contracts.
   * @dev User's pending rewards are added to the user's deposit amount
   * @param userInterestData the state of the user
   * @param creditLineInfo the state of the creditLine contract
   * @param value the amount by which the deposit will be increased
   * @param userDeposit the total amount depositd for the user
   * @param totalDeposit the total amount total depositd between all users
   * @param currentBalance the current balance of rewardable token
   * @return newUserDeposit the new amount deposit by for user
   * @return newTotalDeposit the new total amount deposit between all users
   */
  function _increaseDepositedValue(
    ManagerDataTypes.UserInterestData storage userInterestData,
    ManagerDataTypes.CreditLineInfo storage creditLineInfo,
    uint256 value,
    uint256 userDeposit,
    uint256 totalDeposit,
    uint256 currentBalance
  ) internal returns (uint256 newUserDeposit, uint256 newTotalDeposit) {
    uint256 tokenInterest;
    uint256 buybackInterest;
    _refreshGlobalDataRate(creditLineInfo, totalDeposit, currentBalance);

    if (userDeposit > 0) {
      (tokenInterest, buybackInterest) = _calculateNewUserInterests(
        userInterestData,
        creditLineInfo,
        userDeposit,
        0
      );
      userInterestData.interestsReservedForJRTBuyback += buybackInterest;
    }
    newUserDeposit = userDeposit + value + tokenInterest;
    newTotalDeposit = totalDeposit + value + tokenInterest;

    userInterestData.accDiscountRate += value.wadToRay().rayDiv(
      creditLineInfo.accRate
    );
  }

  /**
   * @notice Function that calculate the new user's interest split between jrtBuyback and new token deposited
   * @param userInterestData the state of the user
   * @param creditLineInfo the state of the creditLine contract
   * @param userDeposit the total amount depositd for the user
   * @param newRewards the amount of global rewards generated during the periode that will be redistribute to users
   * @return tokenInterest the amount of new rewards allocated for user as new deposit
   * @return buybackInterest the amount of new rewards allocated for user's jrt buy back
   */
  function _calculateNewUserInterests(
    ManagerDataTypes.UserInterestData memory userInterestData,
    ManagerDataTypes.CreditLineInfo memory creditLineInfo,
    uint256 userDeposit,
    uint256 newRewards
  ) internal pure returns (uint256 tokenInterest, uint256 buybackInterest) {
    uint256 newInterestGenerated =
      _calculateNewUserTotalInterestGenerated(
        userInterestData,
        creditLineInfo,
        userDeposit,
        newRewards
      );
    buybackInterest = newInterestGenerated.wadMul(
      creditLineInfo.jrtInterestShare
    );
    tokenInterest = newInterestGenerated - buybackInterest;
  }

  /**
   * @notice Function that calculate the total interests the user received during the periode
   * @dev this function recalculate the accRate if newRewards are detected
   * @param userInterestData the state of the user
   * @param creditLineInfo the state of the creditLine contract
   * @param newRewards the amount of global rewards generated during the periode that will be redistribute to users
   * @param userDeposit the total amount depositd for the user
   * @return totalInterestGenerated the total amount of new rewards allocated for the user
   */
  function _calculateNewUserTotalInterestGenerated(
    ManagerDataTypes.UserInterestData memory userInterestData,
    ManagerDataTypes.CreditLineInfo memory creditLineInfo,
    uint256 userDeposit,
    uint256 newRewards
  ) internal pure returns (uint256 totalInterestGenerated) {
    if (userInterestData.accDiscountRate == 0) return (0);
    uint256 accRate = creditLineInfo.accRate;

    if (newRewards > 0) {
      accRate = accRate.rayMul(
        WadRayMath.RAY +
          newRewards.wadToRay().rayDiv(
            (creditLineInfo.balanceTracker -
              creditLineInfo.commissionInterest -
              creditLineInfo.protocolFees)
              .wadToRay()
          )
      );
    }

    totalInterestGenerated =
      userInterestData.accDiscountRate.rayMul(accRate).rayToWad() -
      userDeposit -
      userInterestData.interestsReservedForJRTBuyback;
  }

  /**
   * @notice Internal function that handle commission split and update accRate state
   * @param creditLineInfo the state of the creditLine contract
   * @param totalDeposit the total amount depositd for users
   * @param currentBalance the current balance of rewardable token
   */
  function _refreshGlobalDataRate(
    ManagerDataTypes.CreditLineInfo storage creditLineInfo,
    uint256 totalDeposit,
    uint256 currentBalance
  ) internal {
    uint256 newRewards = currentBalance - creditLineInfo.balanceTracker;

    if (totalDeposit == 0) {
      creditLineInfo.commissionInterest += newRewards;
      return;
    }
    uint256 newCommissionInterests =
      newRewards.wadMul(creditLineInfo.commissionInterestShare);

    creditLineInfo.accRate = creditLineInfo.accRate.rayMul(
      WadRayMath.RAY +
        (newRewards - newCommissionInterests).wadToRay().rayDiv(
          (creditLineInfo.balanceTracker -
            creditLineInfo.commissionInterest -
            creditLineInfo.protocolFees)
            .wadToRay()
        )
    );
    creditLineInfo.commissionInterest += newCommissionInterests;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
interface ISynthereumFactoryVersioning {
  /** @notice Sets a Factory
   * @param factoryType Type of factory
   * @param version Version of the factory to be set
   * @param factory The pool factory address to be set
   */
  function setFactory(
    bytes32 factoryType,
    uint8 version,
    address factory
  ) external;

  /** @notice Removes a factory
   * @param factoryType The type of factory to be removed
   * @param version Version of the factory to be removed
   */
  function removeFactory(bytes32 factoryType, uint8 version) external;

  /** @notice Gets a factory contract address
   * @param factoryType The type of factory to be checked
   * @param version Version of the factory to be checked
   * @return factory Address of the factory contract
   */
  function getFactoryVersion(bytes32 factoryType, uint8 version)
    external
    view
    returns (address factory);

  /** @notice Gets the number of factory versions for a specific type
   * @param factoryType The type of factory to be checked
   * @return numberOfVersions Total number of versions for a specific factory
   */
  function numberOfFactoryVersions(bytes32 factoryType)
    external
    view
    returns (uint8 numberOfVersions);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(
        iszero(b),
        iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))
      ) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(
        iszero(b),
        iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))
      ) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {
  EnumerableSet
} from '../../@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {
  ReentrancyGuard
} from '../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {
  ISynthereumFactoryVersioning
} from '../core/interfaces/IFactoryVersioning.sol';
import {
  ILendingCreditLineStorageManager
} from './interfaces/ILendingCreditLineStorageManager.sol';
import {
  ILendingCreditLineModule
} from './interfaces/ILendingCreditLineModule.sol';
import {ICreditLineV3} from '../self-minting/v3/interfaces/ICreditLineV3.sol';
import {SynthereumInterfaces, FactoryInterfaces} from '../core/Constants.sol';
import {WadRayMath} from '../base/utils/WadRayMath.sol';
import {PreciseUnitMath} from '../base/utils/PreciseUnitMath.sol';
import {SynthereumFactoryAccess} from '../common/libs/FactoryAccess.sol';
import {ManagerDataTypes} from './ManagerDataTypes.sol';
import {InterestRateLogic} from './InterestRateLogic.sol';

contract LendingCreditLineStorageManager is
  ILendingCreditLineStorageManager,
  ReentrancyGuard
{
  using PreciseUnitMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(bytes32 => ManagerDataTypes.LendingInfo) internal idToLendingInfo;
  EnumerableSet.AddressSet internal swapModules;
  mapping(address => address) internal collateralToSwapModule; // ie USDC -> JRTSwapUniswap address
  mapping(address => ManagerDataTypes.CreditLineInfo)
    internal creditLineStorage; // ie jEUR/USDC creditLine
  // Map of userInterestData (creditLineAddress => userAddress => userInterestData)
  mapping(address => mapping(address => ManagerDataTypes.UserInterestData))
    internal userInterestData; // ie jEUR/USDC creditLine

  ISynthereumFinder immutable synthereumFinder;

  modifier onlyLendingCreditLineManager() {
    require(
      msg.sender ==
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.LendingCreditLineManager
        ),
      'Not allowed'
    );
    _;
  }

  modifier onlyCreditLineFactory() {
    SynthereumFactoryAccess._onlySelfMintingFactory(synthereumFinder);
    _;
  }

  constructor(ISynthereumFinder _finder) {
    synthereumFinder = _finder;
  }

  function setLendingModule(
    string calldata _id,
    ManagerDataTypes.LendingInfo calldata _lendingInfo
  ) external override nonReentrant onlyLendingCreditLineManager {
    bytes32 lendingId = keccak256(abi.encode(_id));
    require(lendingId != 0x00, 'Wrong module identifier');
    idToLendingInfo[lendingId] = _lendingInfo;
  }

  function addSwapProtocol(address _swapModule)
    external
    override
    nonReentrant
    onlyLendingCreditLineManager
  {
    require(_swapModule != address(0), 'Swap module can not be 0x');
    require(swapModules.add(_swapModule), 'Swap module already supported');
  }

  function removeSwapProtocol(address _swapModule)
    external
    override
    nonReentrant
    onlyLendingCreditLineManager
  {
    require(_swapModule != address(0), 'Swap module can not be 0x');
    require(swapModules.remove(_swapModule), 'Swap module not supported');
  }

  function setSwapModule(address _collateral, address _swapModule)
    external
    override
    nonReentrant
    onlyLendingCreditLineManager
  {
    require(
      swapModules.contains(_swapModule) || _swapModule == address(0),
      'Swap module not supported'
    );
    collateralToSwapModule[_collateral] = _swapModule;
  }

  function setShares(
    address _creditLine,
    uint64 _commissionInterestShare,
    uint64 _jrtInterestShare
  ) external override nonReentrant onlyLendingCreditLineManager {
    require(
      _commissionInterestShare <= PreciseUnitMath.PRECISE_UNIT &&
        _jrtInterestShare <= PreciseUnitMath.PRECISE_UNIT,
      'Invalid share'
    );
    ManagerDataTypes.CreditLineInfo storage creditLineInfo =
      creditLineStorage[_creditLine];
    require(creditLineInfo.lendingModuleId != 0x00, 'Bad creditLine');

    creditLineInfo.commissionInterestShare = _commissionInterestShare;
    creditLineInfo.jrtInterestShare = _jrtInterestShare;
  }

  function setCreditLineInfo(
    string calldata _lendingID,
    address _creditLine,
    address _collateralToken,
    address _interestBearingToken,
    uint64 _commissionInterestShare,
    uint64 _jrtInterestShare
  ) external override nonReentrant onlyCreditLineFactory {
    require(
      _commissionInterestShare <= PreciseUnitMath.PRECISE_UNIT &&
        _jrtInterestShare <= PreciseUnitMath.PRECISE_UNIT,
      'Invalid share'
    );
    bytes32 id = keccak256(abi.encode(_lendingID));
    ManagerDataTypes.LendingInfo memory lendingInfo = idToLendingInfo[id];
    address lendingModule = lendingInfo.lendingModule;
    require(lendingModule != address(0), 'Module not supported');

    // set creditLine storage
    ManagerDataTypes.CreditLineInfo storage creditLineInfo =
      creditLineStorage[_creditLine];
    require(
      creditLineInfo.lendingModuleId == 0x00,
      'CreditLine already exists'
    );
    creditLineInfo.lendingModuleId = id;
    creditLineInfo.accRate = WadRayMath.RAY;
    creditLineInfo.collateralToken = _collateralToken;
    creditLineInfo.commissionInterestShare = _commissionInterestShare;
    creditLineInfo.jrtInterestShare = _jrtInterestShare;

    // set interest bearing token
    _setBearingToken(
      creditLineInfo,
      _collateralToken,
      lendingModule,
      lendingInfo,
      _interestBearingToken
    );
  }

  function migrateLendingModule(
    string calldata _newLendingID,
    address _creditLine,
    address _newInterestBearingToken
  )
    external
    override
    nonReentrant
    onlyLendingCreditLineManager
    returns (
      ManagerDataTypes.CreditLineInfo memory,
      ManagerDataTypes.LendingInfo memory
    )
  {
    bytes32 id = keccak256(abi.encode(_newLendingID));
    ManagerDataTypes.LendingInfo memory newLendingInfo = idToLendingInfo[id];
    require(newLendingInfo.lendingModule != address(0), 'Id not existent');

    // set lending module
    ManagerDataTypes.CreditLineInfo storage creditLineInfo =
      creditLineStorage[_creditLine];
    creditLineInfo.lendingModuleId = id;

    // set interest bearing token
    _setBearingToken(
      creditLineInfo,
      creditLineInfo.collateralToken,
      newLendingInfo.lendingModule,
      newLendingInfo,
      _newInterestBearingToken
    );

    return (creditLineInfo, newLendingInfo);
  }

  function refreshGlobalDataRate(address _creditLine, uint256 _currentBalance)
    external
    override
    nonReentrant
    onlyLendingCreditLineManager
  {
    ManagerDataTypes.CreditLineInfo storage creditLineInfo =
      creditLineStorage[_creditLine];
    require(creditLineInfo.lendingModuleId != 0x00, 'Bad creditLine');
    uint256 totalDeposited = _getTotalDepositedAmount(_creditLine);
    InterestRateLogic._refreshGlobalDataRate(
      creditLineInfo,
      totalDeposited,
      _currentBalance
    );
    creditLineInfo.balanceTracker = _currentBalance;
  }

  function decreaseCommissionInterest(address _creditLine, uint256 _amount)
    external
    override
    nonReentrant
    onlyLendingCreditLineManager
  {
    ManagerDataTypes.CreditLineInfo storage creditLineInfo =
      creditLineStorage[_creditLine];
    require(creditLineInfo.lendingModuleId != 0x00, 'Bad creditLine');
    creditLineInfo.commissionInterest -= _amount;
    creditLineInfo.balanceTracker -= _amount;
  }

  function decreaseProtocolFees(address _creditLine, uint256 _amount)
    external
    override
    nonReentrant
    onlyLendingCreditLineManager
  {
    ManagerDataTypes.CreditLineInfo storage creditLineInfo =
      creditLineStorage[_creditLine];
    require(creditLineInfo.lendingModuleId != 0x00, 'Bad creditLine');
    creditLineInfo.protocolFees -= _amount;
    creditLineInfo.balanceTracker -= _amount;
  }

  function decreaseUserInterestsForJRTBuyback(
    address _creditLine,
    address _user,
    uint256 _amount
  ) external override nonReentrant onlyLendingCreditLineManager {
    ManagerDataTypes.CreditLineInfo storage creditLineInfo =
      creditLineStorage[_creditLine];
    require(creditLineInfo.lendingModuleId != 0x00, 'Bad creditLine');
    ManagerDataTypes.UserInterestData storage userData =
      userInterestData[_creditLine][_user];
    userData.interestsReservedForJRTBuyback -= _amount;
    creditLineInfo.balanceTracker -= _amount;
  }

  function updateValues(
    address _creditLine,
    address _user,
    uint256 _amount,
    uint256 _currentBalance,
    uint256 _protocolFees,
    bool _isDeposit
  )
    external
    override
    nonReentrant
    onlyLendingCreditLineManager
    returns (uint256 newUserDeposit, uint256 newTotalDeposit)
  {
    ManagerDataTypes.CreditLineInfo storage creditLineInfo =
      creditLineStorage[_creditLine];
    require(creditLineInfo.lendingModuleId != 0x00, 'Bad creditLine');

    // fix 1wei diff
    _currentBalance = _currentBalance.max(creditLineInfo.balanceTracker);

    if (_isDeposit) {
      (newUserDeposit, newTotalDeposit) = _updateStateFromUserDeposit(
        creditLineInfo,
        _user,
        _creditLine,
        _amount,
        _protocolFees,
        _currentBalance
      );
    } else {
      (newUserDeposit, newTotalDeposit) = _updateStateFromUserWithdraw(
        creditLineInfo,
        _user,
        _creditLine,
        _amount,
        _protocolFees,
        _currentBalance
      );
    }
  }

  function _updateStateFromUserWithdraw(
    ManagerDataTypes.CreditLineInfo storage creditLineInfo,
    address user,
    address creditLine,
    uint256 withdrawAmount,
    uint256 protocolFees,
    uint256 currentBalance
  ) internal returns (uint256 newUserDeposit, uint256 newTotalDeposit) {
    ManagerDataTypes.UserInterestData storage userData =
      userInterestData[creditLine][user];
    uint256 userDeposited = _getUserDepositedAmount(creditLine, user);
    uint256 totalDeposited = _getTotalDepositedAmount(creditLine);

    (newUserDeposit, newTotalDeposit) = InterestRateLogic
      ._decreaseDepositedValue(
      userData,
      creditLineInfo,
      withdrawAmount,
      userDeposited,
      totalDeposited,
      currentBalance
    );
    creditLineInfo.balanceTracker = currentBalance - withdrawAmount;
  }

  function _updateStateFromUserDeposit(
    ManagerDataTypes.CreditLineInfo storage creditLineInfo,
    address user,
    address creditLine,
    uint256 depositAmount,
    uint256 protocolFees,
    uint256 currentBalance
  ) internal returns (uint256 newUserDeposit, uint256 newTotalDeposit) {
    ManagerDataTypes.UserInterestData storage userData =
      userInterestData[creditLine][user];
    uint256 userDeposited = _getUserDepositedAmount(creditLine, user);
    uint256 totalDeposited = _getTotalDepositedAmount(creditLine);
    if (depositAmount >= protocolFees) {
      (newUserDeposit, newTotalDeposit) = InterestRateLogic
        ._increaseDepositedValue(
        userData,
        creditLineInfo,
        depositAmount - protocolFees,
        userDeposited,
        totalDeposited,
        currentBalance
      );
    } else {
      (newUserDeposit, newTotalDeposit) = InterestRateLogic
        ._decreaseDepositedValue(
        userData,
        creditLineInfo,
        protocolFees - depositAmount,
        userDeposited,
        totalDeposited,
        currentBalance
      );
    }
    creditLineInfo.balanceTracker = currentBalance + depositAmount;
    creditLineInfo.protocolFees += protocolFees;
  }

  function getPendingInterest(
    uint256 _currentBalance,
    address _creditLine,
    address _recipient
  )
    external
    view
    override
    returns (uint256 collateralInterest, uint256 buyBackInterest)
  {
    ManagerDataTypes.CreditLineInfo memory creditLineInfo =
      creditLineStorage[_creditLine];
    require(creditLineInfo.lendingModuleId != 0x00, 'Bad creditLine');
    ManagerDataTypes.UserInterestData memory userData =
      userInterestData[_creditLine][_recipient];
    uint256 userDeposited = _getUserDepositedAmount(_creditLine, _recipient);
    uint256 totalDeposited = _getTotalDepositedAmount(_creditLine);
    _currentBalance = _currentBalance > creditLineInfo.balanceTracker
      ? _currentBalance
      : creditLineInfo.balanceTracker;
    (collateralInterest, buyBackInterest) = InterestRateLogic._pendingInterests(
      userData,
      creditLineInfo,
      totalDeposited,
      userDeposited,
      _currentBalance,
      _creditLine == _recipient
    );
  }

  function getLendingModule(string calldata _id)
    external
    view
    override
    returns (ManagerDataTypes.LendingInfo memory lendingInfo)
  {
    bytes32 lendingId = keccak256(abi.encode(_id));
    require(lendingId != 0x00, 'Wrong module identifier');
    lendingInfo = idToLendingInfo[lendingId];
    require(
      lendingInfo.lendingModule != address(0),
      'Lending module not supported'
    );
  }

  function getCreditLineData(address _creditLine)
    external
    view
    override
    returns (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo
    )
  {
    creditLineInfo = creditLineStorage[_creditLine];
    require(creditLineInfo.lendingModuleId != 0x00, 'Bad creditLine');
    lendingInfo = idToLendingInfo[creditLineInfo.lendingModuleId];
  }

  function getCreditLineStorage(address _creditLine)
    external
    view
    override
    returns (ManagerDataTypes.CreditLineInfo memory creditLineInfo)
  {
    creditLineInfo = creditLineStorage[_creditLine];
    require(creditLineInfo.lendingModuleId != 0x00, 'Bad creditLine');
  }

  function getUserInterestData(address _creditLine, address _user)
    external
    view
    override
    returns (ManagerDataTypes.UserInterestData memory userData)
  {
    userData = userInterestData[_creditLine][_user];
  }

  function getLendingData(address _creditLine)
    external
    view
    override
    returns (
      ManagerDataTypes.LendingStorage memory lendingStorage,
      ManagerDataTypes.LendingInfo memory lendingInfo
    )
  {
    ManagerDataTypes.CreditLineInfo storage creditLineInfo =
      creditLineStorage[_creditLine];
    require(creditLineInfo.lendingModuleId != 0x00, 'Bad creditLine');
    lendingStorage.collateralToken = creditLineInfo.collateralToken;
    lendingStorage.interestToken = creditLineInfo.interestBearingToken;
    lendingInfo = idToLendingInfo[creditLineInfo.lendingModuleId];
  }

  function getSwapModules() external view override returns (address[] memory) {
    uint256 numberOfModules = swapModules.length();
    address[] memory modulesList = new address[](numberOfModules);
    for (uint256 j = 0; j < numberOfModules; j++) {
      modulesList[j] = swapModules.at(j);
    }
    return modulesList;
  }

  function getCollateralSwapModule(address _collateral)
    external
    view
    override
    returns (address swapModule)
  {
    swapModule = collateralToSwapModule[_collateral];
    require(
      swapModule != address(0),
      'Swap module not added for this collateral'
    );
    require(swapModules.contains(swapModule), 'Swap module not supported');
  }

  function getInterestBearingToken(address _creditLine)
    external
    view
    override
    returns (address interestTokenAddr)
  {
    require(
      creditLineStorage[_creditLine].lendingModuleId != 0x00,
      'Bad creditLine'
    );
    interestTokenAddr = creditLineStorage[_creditLine].interestBearingToken;
  }

  function getShares(address _creditLine)
    external
    view
    override
    returns (uint256 commissionInterestShare, uint256 jrtInterestShare)
  {
    require(
      creditLineStorage[_creditLine].lendingModuleId != 0x00,
      'Bad creditLine'
    );
    commissionInterestShare = creditLineStorage[_creditLine]
      .commissionInterestShare;
    jrtInterestShare = creditLineStorage[_creditLine].jrtInterestShare;
  }

  function _getUserDepositedAmount(address _creditLine, address _user)
    internal
    view
    returns (uint256 userDeposited)
  {
    (userDeposited, ) = ICreditLineV3(_creditLine).getPositionData(_user);
  }

  function _getTotalDepositedAmount(address _creditLine)
    internal
    view
    returns (uint256 totalDeposited)
  {
    (totalDeposited, ) = ICreditLineV3(_creditLine).getGlobalPositionData();
  }

  function _setBearingToken(
    ManagerDataTypes.CreditLineInfo storage _actualCreditLineData,
    address _collateral,
    address _lendingModule,
    ManagerDataTypes.LendingInfo memory _lendingInfo,
    address _interestToken
  ) internal {
    try
      ILendingCreditLineModule(_lendingModule).getInterestBearingToken(
        _collateral,
        _lendingInfo.args
      )
    returns (address interestTokenAddr) {
      _actualCreditLineData.interestBearingToken = interestTokenAddr;
    } catch {
      require(_interestToken != address(0), 'No bearing token passed');
      _actualCreditLineData.interestBearingToken = _interestToken;
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {
  IStandardERC20,
  IERC20
} from '../../../base/interfaces/IStandardERC20.sol';
import {
  ISynthereumDeployment
} from '../../../common/interfaces/IDeployment.sol';
import {
  IEmergencyShutdown
} from '../../../common/interfaces/IEmergencyShutdown.sol';
import {ITypology} from '../../../common/interfaces/ITypology.sol';
import {
  ILendingCreditLineManager
} from '../../../lending-module/interfaces/ILendingCreditLineManager.sol';
import {
  ILendingCreditLineStorageManager
} from '../../../lending-module/interfaces/ILendingCreditLineStorageManager.sol';

interface ICreditLineV3 is
  ITypology,
  IEmergencyShutdown,
  ISynthereumDeployment
{
  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event Borrowing(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );

  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount
  );

  event EmergencyShutdown(
    address indexed caller,
    uint256 settlementPrice,
    uint256 shutdownTimestamp
  );

  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  event Liquidation(
    address indexed sponsor,
    address indexed liquidator,
    uint256 liquidatedTokens,
    uint256 liquidatedCollateral,
    uint256 collateralReward,
    uint256 liquidationTime
  );

  /**
   * @notice Transfers `collateralAmount` into the caller's position.
   * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
   * at least `collateralAmount` of collateral token
   * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
   */
  function deposit(uint256 collateralAmount) external;

  /**
   * @notice Transfers `collateralAmount` into the specified sponsor's position.
   * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
   * at least `collateralAmount` of collateralCurrency.
   * @param sponsor the sponsor to credit the deposit to.
   * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
   */
  function depositTo(address sponsor, uint256 collateralAmount) external;

  /**
   * @notice Transfers `collateralAmount` from the sponsor's position to the sponsor.
   * @dev Reverts if the withdrawal puts this position's collateralization ratio below the collateral requirement
   * @param collateralAmount is the amount of collateral to withdraw.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function withdraw(uint256 collateralAmount)
    external
    returns (uint256 amountWithdrawn);

  /**
   * @notice Pulls `collateralAmount` into the sponsor's position and mints `numTokens` of `tokenCurrency`.
   * Mints new debt tokens by creating a new position or by augmenting an existing position.
   * @dev Can only be called by a token sponsor. This contract must be approved to spend at least `collateralAmount` of
   * `collateralCurrency`.
   * @param collateralAmount is the number of collateral tokens to collateralize the position with
   * @param numTokens is the number of debt tokens to mint to sponsor.
   * @return feeAmount incurred fees in collateral token.
   */
  function borrow(uint256 collateralAmount, uint256 numTokens)
    external
    returns (uint256 feeAmount);

  /**
   * @notice Burns `numTokens` of `tokenCurrency` and sends back the proportional amount of collateral
   * @dev Can only be called by a token sponsor - This contract must be approved to spend at least `numTokens` of
   * `tokenCurrency`.
   * @param numTokens is the number of tokens to be burnt.
   * @param swapParams encoded bytes necessary for the swap module call during the claimBuyBack of lendingCreditLineManager contract
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function redeem(uint256 numTokens, bytes calldata swapParams)
    external
    returns (uint256 amountWithdrawn);

  /**
   * @notice Burns `numTokens` of `tokenCurrency` to decrease sponsors position size, without sending back collateral.
   * This is done by a sponsor to increase position CR.
   * @dev Can only be called by token sponsor. This contract must be approved to spend `numTokens` of `tokenCurrency`.
   * @param numTokens is the number of tokens to be burnt.
   */
  function repay(uint256 numTokens) external;

  /**
   * @notice Liquidate sponsor position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param sponsor Address of sponsor to be liquidated.
   * @param maxTokensToLiquidate Max number of synthetic tokens to be liquidated
   * @param swapParams encoded bytes necessary for the swap module call during the claimBuyBack of lendingCreditLineManager contract
   * @return tokensLiquidated Amount of debt tokens burned
   * @return collateralLiquidated Amount of received collateral equal to the value of tokens liquidated
   * @return collateralReward Amount of received collateral as reward for the liquidation
   */
  function liquidate(
    address sponsor,
    uint256 maxTokensToLiquidate,
    bytes calldata swapParams
  )
    external
    returns (
      uint256 tokensLiquidated,
      uint256 collateralLiquidated,
      uint256 collateralReward
    );

  /**
   * @notice When in emergency shutdown state all token holders and sponsor can redeem their tokens and
   * remaining collateral at the current price defined by the on-chain oracle
   * @dev This burns all tokens from the caller of `tokenCurrency` and sends back the resolved settlement value of
   * collateral. This contract must be approved to spend `tokenCurrency` at least up to the caller's full balance.
   * This contract must have the Burner role for the `tokenCurrency`.
   * @param sponsor Address of sponsor to redeem token.
   * @param swapParams encoded bytes necessary for the swap module call during the claimBuyBack of lendingCreditLineManager contract
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   * @return jrtBuyBackReceived The amount of JRT send to the sponsor coming from interest generated for this purpose (cf. lendingCreditLineManager)
   */
  function settleEmergencyShutdown(address sponsor, bytes calldata swapParams)
    external
    returns (uint256 amountWithdrawn, uint256 jrtBuyBackReceived);

  // /**
  //  * @notice trim any excess funds in the contract to the excessTokenBeneficiary address
  //  * @return amount the amount of tokens trimmed
  //  */
  // function trimExcess(IERC20 token) external returns (uint256 amount);

  /**
   * @notice Delete a TokenSponsor position. This function can only be called by the contract itself.
   * @param sponsor address of the TokenSponsor.
   */
  function deleteSponsorPosition(address sponsor) external;

  /**
   * @notice Returns the minimum amount of tokens a sponsor must mint
   * @return amount the value
   */
  function getMinSponsorTokens() external view returns (uint256 amount);

  /**
   * @notice Returns the percentage of protocol fee apply on borrowing
   * @return protocolFeesPercentage the percentage value
   */
  function getProtocolFeesPercentage()
    external
    view
    returns (uint64 protocolFeesPercentage);

  /**
   * @notice Returns the cap mint amount of the derivative contract
   * @return capMint cap mint amount
   */
  function getCapMintAmount() external view returns (uint256 capMint);

  /**
   * @notice Returns the liquidation rewrd percentage of the derivative contract
   * @return rewardPct liquidator reward percentage
   */
  function getLiquidationReward() external view returns (uint256 rewardPct);

  /**
   * @notice Returns the over collateralization percentage of the derivative contract
   * @return collReq percentage of overcollateralization
   */
  function getCollateralRequirement() external view returns (uint256 collReq);

  /**
   * @notice Accessor method for a sponsor's position.
   * @param sponsor address whose position data is retrieved.
   * @return collateralAmount amount of collateral of the sponsor's position.
   * @return tokensAmount amount of outstanding tokens of the sponsor's position.
   */
  function getPositionData(address sponsor)
    external
    view
    returns (uint256 collateralAmount, uint256 tokensAmount);

  /**
   * @notice Accessor method for a EOA pending interests.
   * @param eoaAddress address whose pending interests data is retrieved.
   * @return collateralAmount amount of pending interests used as collateral.
   * @return reservedForJRTBuyBack amount of pending interests reserved for buyback.
   */
  function getPendingInterest(address eoaAddress)
    external
    view
    returns (uint256 collateralAmount, uint256 reservedForJRTBuyBack);

  /**
   * @notice Accessor method for contract's global position (aggregate).
   * @return totCollateral total amount of collateral deposited by lps
   * @return totTokensOutstanding total amount of outstanding tokens.
   */
  function getGlobalPositionData()
    external
    view
    returns (uint256 totCollateral, uint256 totTokensOutstanding);

  /**
   * @notice Returns if sponsor position is overcollateralized and the percentage of coverage of the collateral according to the last price
   * @return isOverCollateralized bool that is true if position is overcollaterlized, otherwise false
   * @return collateralCoveragePercentage percentage of coverage (totalCollateralAmount / (price * tokensCollateralized))
   */
  function collateralCoverage(address sponsor)
    external
    view
    returns (bool isOverCollateralized, uint256 collateralCoveragePercentage);

  /**
   * @notice Returns liquidation price of a position
   * @param sponsor address whose liquidation price is calculated.
   * @return liquidationPrice
   */
  function liquidationPrice(address sponsor)
    external
    view
    returns (uint256 liquidationPrice);

  /**
   * @notice Get synthetic token price identifier as represented by the oracle interface
   * @return identifier Synthetic token price identifier
   */
  function priceIdentifier() external view returns (bytes32 identifier);

  /**
   * @notice Get the block number when the emergency shutdown was called
   * @return time Block time
   */
  function emergencyShutdownTime() external view returns (uint256 time);

  /**
   * @notice Get the price of synthetic token set by DVM after emergencyShutdown call
   * @return price Price of synthetic token
   */
  function emergencyShutdownPrice() external view returns (uint256 price);

  /**
   * @notice Get address and instance of the lendingManage attach to the creditLine
   * @return creditLineManager the address/instance
   */
  function lendingManager()
    external
    view
    returns (ILendingCreditLineManager creditLineManager);

  /**
   * @notice Get address and instance of the lending storage manager of creditLines
   * @return creditLineStorageManager the address/instance
   */
  function lendingStorageManager()
    external
    view
    returns (ILendingCreditLineStorageManager creditLineStorageManager);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title PreciseUnitMath
 * @author Synthereum Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision.
 *
 */
library PreciseUnitMath {
  // The number One in precise units.
  uint256 internal constant PRECISE_UNIT = 10**18;

  // Max unsigned integer value
  uint256 internal constant MAX_UINT_256 = type(uint256).max;

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnit() internal pure returns (uint256) {
    return PRECISE_UNIT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxUint256() internal pure returns (uint256) {
    return MAX_UINT_256;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b) / PRECISE_UNIT;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (((a * b) - 1) / PRECISE_UNIT) + 1;
  }

  /**
   * @dev Divides value a by value b (result is rounded down).
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * PRECISE_UNIT) / b;
  }

  /**
   * @dev Divides value a by value b (result is rounded up or away from 0).
   */
  function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Cant divide by 0');

    return a > 0 ? (((a * PRECISE_UNIT) - 1) / b) + 1 : 0;
  }

  /**
   * @dev Performs the power on a specified value, reverts on overflow.
   */
  function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
    require(a > 0, 'Value must be positive');

    uint256 result = 1;
    for (uint256 i = 0; i < pow; i++) {
      uint256 previousResult = result;

      result = previousResult * a;
    }

    return result;
  }

  /**
   * @dev The minimum of `a` and `b`.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev The maximum of `a` and `b`.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStandardERC20 is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';

/**
 * @title Interface that a pool MUST have in order to be included in the deployer
 */
interface ISynthereumDeployment {
  /**
   * @notice Get Synthereum finder of the pool/self-minting derivative
   * @return finder Returns finder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /**
   * @notice Get Synthereum version
   * @return contractVersion Returns the version of this pool/self-minting derivative
   */
  function version() external view returns (uint8 contractVersion);

  /**
   * @notice Get the collateral token of this pool/self-minting derivative
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken() external view returns (IERC20 collateralCurrency);

  /**
   * @notice Get the synthetic token associated to this pool/self-minting derivative
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  /**
   * @notice Get the synthetic token symbol associated to this pool/self-minting derivative
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IEmergencyShutdown {
  /**
   * @notice Shutdown the pool or self-minting-derivative in case of emergency
   * @notice Only Synthereum manager contract can call this function
   * @return timestamp Timestamp of emergency shutdown transaction
   * @return price Price of the pair at the moment of shutdown execution
   */
  function emergencyShutdown()
    external
    returns (uint256 timestamp, uint256 price);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ITypology {
  /**
   * @notice Return typology of the contract
   */
  function typology() external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {Address} from '../../../@openzeppelin/contracts/utils/Address.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  ILendingCreditLineModule
} from '../interfaces/ILendingCreditLineModule.sol';

import {IPool} from '../interfaces/IAaveV3.sol';
import {IRewardsController} from '../interfaces/IRewardsController.sol';
import {PreciseUnitMath} from '../../base/utils/PreciseUnitMath.sol';

import {ManagerDataTypes} from '../ManagerDataTypes.sol';

contract AaveV3CreditLineModule is ILendingCreditLineModule {
  using SafeERC20 for IERC20;

  function deposit(
    ManagerDataTypes.CreditLineInfo memory _creditLineInfo,
    bytes calldata _lendingArgs,
    uint256 _amount
  )
    external
    override
    returns (
      uint256 currentBalance,
      uint256 tokensOut,
      uint256 tokensTransferred
    )
  {
    // get the current balance of aToken
    currentBalance = getCurrentBalanceInCollateral(
      msg.sender,
      _creditLineInfo.interestBearingToken
    );
    // proxy should have received collateral from the pool
    IERC20 collateral = IERC20(_creditLineInfo.collateralToken);
    require(collateral.balanceOf(address(this)) >= _amount, 'Wrong balance');

    // aave deposit - approve
    (address moneyMarket, ) = abi.decode(_lendingArgs, (address, address));

    collateral.safeIncreaseAllowance(moneyMarket, _amount);
    IPool(moneyMarket).supply(
      address(collateral),
      _amount,
      msg.sender,
      uint16(0)
    );

    // aave tokens are usually 1:1 (but in some case there is dust-wei of rounding)
    uint256 netDeposit =
      IERC20(_creditLineInfo.interestBearingToken).balanceOf(msg.sender) -
        currentBalance;

    tokensOut = netDeposit;
    tokensTransferred = netDeposit;
  }

  function withdraw(
    ManagerDataTypes.CreditLineInfo memory _creditLineInfo,
    address _creditLine,
    bytes calldata _lendingArgs,
    uint256 _aTokensAmount,
    address _recipient
  )
    external
    override
    returns (
      uint256 currentBalance,
      uint256 tokensOut,
      uint256 tokensTransferred
    )
  {
    // proxy should have received interest tokens from the pool
    IERC20 interestToken = IERC20(_creditLineInfo.interestBearingToken);
    uint256 withdrawAmount =
      PreciseUnitMath.min(
        interestToken.balanceOf(address(this)),
        _aTokensAmount + 1
      );

    currentBalance =
      getCurrentBalanceInCollateral(
        _creditLine,
        _creditLineInfo.interestBearingToken
      ) +
      withdrawAmount;
    uint256 initialBalance =
      IERC20(_creditLineInfo.collateralToken).balanceOf(_recipient);

    // aave withdraw - approve
    (address moneyMarket, ) = abi.decode(_lendingArgs, (address, address));

    interestToken.safeIncreaseAllowance(moneyMarket, withdrawAmount);

    IPool(moneyMarket).withdraw(
      _creditLineInfo.collateralToken,
      withdrawAmount,
      _recipient
    );

    // aave tokens are usually 1:1 (but in some case there is dust-wei of rounding)
    uint256 netWithdrawal =
      IERC20(_creditLineInfo.collateralToken).balanceOf(_recipient) -
        initialBalance;

    tokensOut = _aTokensAmount;
    tokensTransferred = netWithdrawal;
  }

  function totalTransfer(
    address _oldCreditLine,
    address _newCreditLine,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  )
    external
    returns (uint256 prevTotalCollateral, uint256 actualTotalCollateral)
  {
    prevTotalCollateral = IERC20(_interestToken).balanceOf(_newCreditLine);
    actualTotalCollateral = IERC20(_interestToken).balanceOf(_newCreditLine);
  }

  function getInterestBearingToken(address _collateral, bytes calldata _args)
    external
    view
    override
    returns (address token)
  {
    (address moneyMarket, ) = abi.decode(_args, (address, address));
    token = IPool(moneyMarket).getReserveData(_collateral).aTokenAddress;
    require(token != address(0), 'Interest token not found');
  }

  function collateralToInterestToken(
    uint256 _collateralAmount,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  ) external pure override returns (uint256 interestTokenAmount) {
    interestTokenAmount = _collateralAmount;
  }

  function interestTokenToCollateral(
    uint256 _interestTokenAmount,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  ) external pure override returns (uint256 collateralAmount) {
    collateralAmount = _interestTokenAmount;
  }

  function getCurrentBalanceInCollateral(
    address _creditLine,
    address interestBearingToken
  ) public view override returns (uint256 currentBalance) {
    currentBalance = IERC20(interestBearingToken).balanceOf(_creditLine);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IPool {
  struct ReserveConfigurationMap {
    uint256 data;
  }

  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param _asset The address of the underlying asset to supply
   * @param _amount The amount to be supplied
   * @param _onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param _referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address _asset,
    uint256 _amount,
    address _onBehalfOf,
    uint16 _referralCode
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param _asset The address of the underlying asset to withdraw
   * @param _amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param _to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address _asset,
    uint256 _amount,
    address _to
  ) external returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param _asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   **/
  function getReserveData(address _asset)
    external
    view
    returns (ReserveData memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >0.8.0;

/**
 * @title IRewardsController
 * @author Aave
 * @notice Defines the basic interface for a Rewards Controller.
 */
interface IRewardsController {
  /**
   * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
   **/
  function claimAllRewards(address[] calldata assets, address to)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {Address} from '../../../@openzeppelin/contracts/utils/Address.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IJRTSwapModule} from '../interfaces/IJrtSwapModule.sol';
import {
  IUniswapV2Router02
} from '../../../@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract UniV2JRTSwapModule is IJRTSwapModule {
  using SafeERC20 for IERC20;

  struct SwapInfo {
    address routerAddress;
    address[] tokenSwapPath;
    uint256 expiration;
    uint256 minTokensOut;
  }

  function swapToJRT(
    address _recipient,
    address _collateral,
    address _jarvisToken,
    uint256 _amountIn,
    bytes calldata _params
  ) external override returns (uint256 amountOut) {
    // decode swapInfo
    SwapInfo memory swapInfo = abi.decode(_params, (SwapInfo));
    uint256 pathLength = swapInfo.tokenSwapPath.length;
    require(
      swapInfo.tokenSwapPath[pathLength - 1] == _jarvisToken,
      'Wrong token swap path'
    );

    // swap to JRT to final recipient
    IUniswapV2Router02 router = IUniswapV2Router02(swapInfo.routerAddress);

    IERC20(_collateral).safeIncreaseAllowance(address(router), _amountIn);
    amountOut = router.swapExactTokensForTokens(
      _amountIn,
      swapInfo.minTokensOut,
      swapInfo.tokenSwapPath,
      _recipient,
      swapInfo.expiration
    )[pathLength - 1];
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IJRTSwapModule {
  /**
   * @notice executes an AMM swap from collateral to JRT
   * @param _recipient address receiving JRT tokens
   * @param _collateral address of the collateral token to swap
   * @param _jarvisToken address of the jarvis token to buy
   * @param _amountIn exact amount of collateral to swap
   * @param _params extra params needed on the specific implementation (with different AMM)
   * @return amountOut amount of JRT in output
   */
  function swapToJRT(
    address _recipient,
    address _collateral,
    address _jarvisToken,
    uint256 _amountIn,
    bytes calldata _params
  ) external returns (uint256 amountOut);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {Address} from '../../../@openzeppelin/contracts/utils/Address.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ISynthereumDeployment} from '../../common/interfaces/IDeployment.sol';
import {IBalancerVault} from '../interfaces/IBalancerVault.sol';
import {IJRTSwapModule} from '../interfaces/IJrtSwapModule.sol';

contract BalancerJRTSwapModule is IJRTSwapModule {
  using SafeERC20 for IERC20;

  struct SwapInfo {
    bytes32 poolId;
    address routerAddress;
    uint256 minTokensOut; // anti slippage
    uint256 expiration;
  }

  function swapToJRT(
    address _recipient,
    address _collateral,
    address _jarvisToken,
    uint256 _amountIn,
    bytes calldata _params
  ) external override returns (uint256 amountOut) {
    // decode swapInfo
    SwapInfo memory swapInfo = abi.decode(_params, (SwapInfo));

    // build params
    IBalancerVault.SingleSwap memory singleSwap =
      IBalancerVault.SingleSwap(
        swapInfo.poolId,
        IBalancerVault.SwapKind.GIVEN_IN,
        _collateral,
        _jarvisToken,
        _amountIn,
        '0x00'
      );

    IBalancerVault.FundManagement memory funds =
      IBalancerVault.FundManagement(
        address(this),
        false,
        payable(_recipient),
        false
      );

    // swap to JRT to final recipient
    IBalancerVault router = IBalancerVault(swapInfo.routerAddress);

    IERC20(_collateral).safeIncreaseAllowance(address(router), _amountIn);
    amountOut = router.swap(
      singleSwap,
      funds,
      swapInfo.minTokensOut,
      swapInfo.expiration
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IBalancerVault {
  enum SwapKind {GIVEN_IN, GIVEN_OUT}

  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
  }

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  function swap(
    SingleSwap memory singleSwap,
    FundManagement memory funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {
  AccessControlEnumerable
} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Provides addresses of contracts implementing certain interfaces.
 */
contract SynthereumFinder is ISynthereumFinder, AccessControlEnumerable {
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => address) public interfacesImplemented;

  //----------------------------------------
  // Events
  //----------------------------------------

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructors
  //----------------------------------------

  constructor(Roles memory roles) {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, roles.admin);
    _setupRole(MAINTAINER_ROLE, roles.maintainer);
  }

  //----------------------------------------
  // External view
  //----------------------------------------

  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 of the interface name that is either changed or registered.
   * @param implementationAddress address of the implementation contract.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyMaintainer {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the defined interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}