/**
 *Submitted for verification at snowtrace.io on 2022-03-18
*/

/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

////import "./IERC165.sol";

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




/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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




/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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




/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

////import "./IAccessControl.sol";
////import "../utils/Context.sol";
////import "../utils/Strings.sol";
////import "../utils/introspection/ERC165.sol";

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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}




/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

////import "./IAccessControl.sol";

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




/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/
            

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;


interface PlayerStatusQueryInterface
{
    function stakingAmount(address stakedTokenAddr, address account, address nftAddress) view external returns(uint256);
    function rewardFoodsAmount(address stakedTokenAddr, address account, address nftAddress)view external returns(uint256);
}

contract PlayerStatusQueryMock is PlayerStatusQueryInterface
{
    constructor() {
    }

    function stakingAmount(address /*stakedTokenAddr*/,address /*account*/, address /*nftAddress*/) pure public override returns(uint256) {
        return 0;
    }

    function rewardFoodsAmount(address /*stakedTokenAddr*/,address /*account*/, address /*nftAddress*/) pure external override returns(uint256){
        return 0;
    }
}



/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/
            

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;

library MathEx
{
    function randRaw(uint256 number) public view returns(uint256) {
        if (number == 0) {
            return 0;
        }
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random % number;
    }

    function rand(uint256 number, uint256 seed) public view returns(uint256) {
        if (number == 0) {
            return 0;
        }
        uint256 random = uint256(keccak256(abi.encodePacked(seed, block.difficulty, block.timestamp)));
        return random % number;
    }

    function randEx(uint256 seed) public view returns(uint256) {
        if (seed==0){
            return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        }else{
            return uint256(keccak256(abi.encodePacked(seed,block.difficulty, block.timestamp)));
        }
    }

    function scopeRandR(uint256 beginNumber,uint256 endNumber, uint256 rnd) public pure returns(uint256){
        if (endNumber <= beginNumber) {
            return beginNumber;
        }
        return (rnd % (endNumber-beginNumber+1))+beginNumber;
    }

//            }
//        }
//
//        uint256 parityPoint=rand(totalRarityProbability,seed);
//        for (uint256 i=0;i<6;++i){
//            if (parityPoint<probabilities[i]){
//                return i;
//            }
//        }
//
//        return 0;
//    }

    function probabilisticRandom6R(uint256 [6] memory probabilities, uint256 rnd) pure public returns(uint256/**index*/){

        uint256 totalRarityProbability=0;
        for (uint256 i=0;i<6;++i){
            totalRarityProbability+=probabilities[i];
            if (i>0){
                probabilities[i]+=probabilities[i-1];
            }
        }

        uint256 parityPoint=rnd % totalRarityProbability;
        for (uint256 i=0;i<6;++i){
            if (parityPoint<probabilities[i]){
                return i;
            }
        }

        return 0;
    }


    function probabilisticRandom4R(uint256 [4] memory probabilities, uint256 rnd) pure public returns(uint256/**index*/){

        uint256 totalRarityProbability=0;
        for (uint256 i=0;i<4;++i){
            totalRarityProbability+=probabilities[i];
            if (i>0){
                probabilities[i]+=probabilities[i-1];
            }
        }

        uint256 parityPoint=rnd % totalRarityProbability;
        for (uint256 i=0;i<4;++i){
            if (parityPoint<probabilities[i]){
                return i;
            }
        }

        return 0;
    }

    function probabilisticRandom5R(uint256 [5] memory probabilities, uint256 rnd) pure public returns(uint256/**index*/){

        uint256 totalRarityProbability=0;
        for (uint256 i=0;i<5;++i){
            totalRarityProbability+=probabilities[i];
            if (i>0){
                probabilities[i]+=probabilities[i-1];
            }
        }

        uint256 parityPoint=rnd % totalRarityProbability;
        for (uint256 i=0;i<5;++i){
            if (parityPoint<probabilities[i]){
                return i;
            }
        }

        return 0;
    }

}




/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

////import "./IAccessControlEnumerable.sol";
////import "./AccessControl.sol";
////import "../utils/structs/EnumerableSet.sol";

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


/** 
 *  SourceUnit: d:\Contract2\contracts\contracts\MetaInfoDb.sol
*/


//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
////import "./MathEx.sol";
////import "./PlayerStatusQueryInterface.sol";

struct HatchCostInfo
{
    uint256 rubyCost;
    uint256 CSTCost;
}

struct FamilyDragonInfo
{
    uint256 dragonId;
    uint256 fatherDragonId;
    uint256 montherDragonId;
}

struct HeredityInfo
{
    uint256 id;  //eggNFT id , not dragonNFT Id
    FamilyDragonInfo fatherFamily;
    FamilyDragonInfo motherFamily;
}

struct Scope
{
    uint256 beginValue;
    uint256 endValue;
}


uint256 constant SUPER_CHEST=0;  //super chest and egg use
uint256 constant NORMAL_CHEST=1; //normal chest use
uint256 constant FOOD_CHEST=2;  //food chest use

uint256 constant NORMAL_RARITY = 0;
uint256 constant GOOD_RARITY = 1;
uint256 constant RARE_RARITY = 2;
uint256 constant EPIC_RARITY = 3;
uint256 constant LEGEND_RARITY = 4;
uint256 constant RARITY_MAX = 4;


uint256 constant PARTS_HEAD = 0;
uint256 constant PARTS_BODY = 1;
uint256 constant PARTS_LIMBS = 2;
uint256 constant PARTS_WINGS = 3;

uint256 constant ELEMENT_FIRE = 0x01;
uint256 constant ELEMENT_WATER = 0x02;
uint256 constant ELEMENT_LAND = 0x04;
uint256 constant ELEMENT_WIND = 0x08;
uint256 constant ELEMENT_LIGHT = 0x10;
uint256 constant ELEMENT_DARK = 0x20;

uint256 constant FRACTION_INT_BASE = 10000;

uint256 constant STAKING_NESTS_SUPPLY = 6;
uint256 constant HATCHING_NESTS_SUPPLY= 6;

uint256 constant MAX_STAKING_CST_WEIGHT_DELTA=FRACTION_INT_BASE/STAKING_NESTS_SUPPLY;
uint256 constant MAX_STAKING_CST_POWER_BYONE=4631;
uint256 constant MAX_STAKING_CST_POWER = MAX_STAKING_CST_POWER_BYONE*STAKING_NESTS_SUPPLY;

uint256 constant CLASS_NONE =0;
uint256 constant CLASS_ULTIMA = 0x01;
uint256 constant CLASS_FLASH = 0x02;
uint256 constant CLASS_OLYMPUS = 0x04;


uint256 constant DEFAULT_HATCH_TIMES = 5;

uint256 constant HATCH_MAX_TIMES =7  ;

uint256 constant DEFAULT_HATCHING_DURATION = 5 days;


interface IRandomHolder
{
    function getSeed() view external returns(uint256) ;
}


contract MetaInfoDb is AccessControlEnumerable
{
    address public CSTAddress; //CST token address
    address public rubyAddress; //RUBY token address
    address [3] public chestAddressArray; //Chest token address.0:super;1:normal;2:food

    address public dragonNFTAddr; //DragonNFT address
    address public eggNFTAddr;//EggNFT address
    address public accountInfoAddr; //AccountInfo contract

    address public CSTBonusPoolAddress;
    uint256 public CSTBonusPoolRate; //20%

    address public CSTOrganizeAddress;
    uint256 public CSTOrganizeRate; //10%

    address public CSTTeamAddress;
    uint256 public CSTTeamRate; //20%

    address public RUBYBonusPoolAddress;
    uint256 public RUBYBonusPoolRate; //20%

    address public RUBYOrganizeAddress;
    uint256 public RUBYOrganizeRate; //10%

    address public RUBYTeamAddress;
    uint256 public RUBYTeamRate; //20%

    address public USDBonusPoolAddress;
    uint256 public USDBonusPoolRate; //70%

    address public USDOrganizeAddress;
    uint256 public USDOrganizeRate; //10%

    address public USDTeamAddress;
    uint256 public USDTeamRate; //20%

    address public marketFeesReceiverAddress;

    //marketParams
    // feesRate >0 && <FRACTION_INT_BASE
    uint256 public marketFeesRate;


    uint256 [RARITY_MAX+1] [FOOD_CHEST] public rarityProbabilityFloatArray;


    Scope [RARITY_MAX+1] public stakingCSTPowerArray; 
    Scope [RARITY_MAX+1] public stakingRubyPowerArray;


    HatchCostInfo[HATCH_MAX_TIMES] public hatchCostInfos;

    uint256 public defaultHatchingDuration;

    Scope [RARITY_MAX+1] public lifeValueScopeArray;
    Scope [RARITY_MAX+1] public attackValueScopeArray;
    Scope [RARITY_MAX+1] public defenseValueScopeArray;
    Scope [RARITY_MAX+1] public speedValueScopeArray;

    mapping(uint256/** id */=>uint256 [4]) public partsLib; //index=0:head ; index=1:body ; index=2:limbs ; index=3:wings
    mapping(uint256/** id */=>uint256) public skillsLib;

    uint256 [6][2] public partsLibProb;
    uint256 [6][2] public skillsLibProb;
 
    uint256 [6] public elementProbArray;
    uint256 [6] public elementIdArray;

    uint256 [6] public elementHeredityProbArray;


    uint256 [5/**rarity */][5/**star */] [5/**rarity */] public starUpdateTable;


    uint256 [5/**rarity */] public qualityFactors;

    uint256 [RARITY_MAX+1] public outputFoodProbabilityArray;
    Scope [RARITY_MAX+1] public outputFoodScopeArray;

    address public playerStatusQueryInterface;

    uint256 [5] public rewardHatchingNestsCST;

    IRandomHolder private randomHolder;

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must have admin role.");
        _;
    }

    constructor(address CSTAddr,address rubyAddr,address [3] memory chestAddrArray,address playerStatusQueryInterface_){
        CSTAddress=CSTAddr;
        rubyAddress=rubyAddr;
        chestAddressArray=chestAddrArray;
        playerStatusQueryInterface=playerStatusQueryInterface_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        rarityProbabilityFloatArray=[
            [600,365,30,5,0],  //super chest and egg
            [684,300,15,1,0]   //normal chest
        ];

        hatchCostInfos[0]=HatchCostInfo(3200000 ether,10 gwei);
        hatchCostInfos[1]=HatchCostInfo(6400000 ether,10 gwei);
        hatchCostInfos[2]=HatchCostInfo(9600000 ether,10 gwei);
        hatchCostInfos[3]=HatchCostInfo(16000000 ether,10 gwei);
        hatchCostInfos[4]=HatchCostInfo(25600000 ether,10 gwei);
        hatchCostInfos[5]=HatchCostInfo(41600000 ether,10 gwei);
        hatchCostInfos[6]=HatchCostInfo(67200000 ether,10 gwei);

        defaultHatchingDuration=DEFAULT_HATCHING_DURATION;







        
        elementProbArray=[20,20,20,20,10,10];
        elementIdArray=[ELEMENT_FIRE, ELEMENT_WATER, ELEMENT_LAND, ELEMENT_WIND,
                        ELEMENT_LIGHT, ELEMENT_DARK];

        elementHeredityProbArray=[30,30,10,10,10,10];

        partsLib[ELEMENT_FIRE]=[9,9,9,9];
        partsLib[ELEMENT_WATER]=[9,9,9,9];
        partsLib[ELEMENT_LAND]=[9,9,9,9];
        partsLib[ELEMENT_WIND]=[9,9,9,9];
        partsLib[ELEMENT_LIGHT]=[9,9,9,9];
        partsLib[ELEMENT_DARK]=[9,9,9,9];

        partsLibProb=[
                [0, 10, 90, 0, 0, 0],
                [40, 10, 50, 0, 0, 0]
        ];

        skillsLib[ELEMENT_FIRE]=20;
        skillsLib[ELEMENT_WATER]=20;
        skillsLib[ELEMENT_LAND]=20;
        skillsLib[ELEMENT_WIND]=20;
        skillsLib[ELEMENT_LIGHT]=20;
        skillsLib[ELEMENT_DARK]=20;

        skillsLibProb=[
                [0, 10, 90, 0, 0, 0],
                [40, 10, 50, 0, 0, 0]
        ];






        qualityFactors=[0,0,1,2,3];

        marketFeesRate=425;//4.25%
        marketFeesReceiverAddress=_msgSender();

        CSTBonusPoolRate=8000; //80%
        CSTOrganizeRate=1000; //10%
        CSTTeamRate=2000; //20%
        RUBYBonusPoolRate=2000; //20%
        RUBYOrganizeRate=1000; //10%
        RUBYTeamRate=2000; //20%
        USDBonusPoolRate=7000; //70%
        USDOrganizeRate=1000; //10%
        USDTeamRate=2000; //20%

        outputFoodProbabilityArray=[790,160,40,10,0];
        outputFoodScopeArray[NORMAL_RARITY]=Scope(2000 wei,9999 wei);
        outputFoodScopeArray[GOOD_RARITY]=Scope(10000 wei , 50000 wei);
        outputFoodScopeArray[RARE_RARITY]=Scope(50001 wei , 99999 wei);
        outputFoodScopeArray[EPIC_RARITY]=Scope(100000 wei , 299999 wei);
        outputFoodScopeArray[LEGEND_RARITY]=Scope(0,0);

        rewardHatchingNestsCST=[3000 gwei, 4500 gwei, 15000 gwei, 30000 gwei, 45000 gwei];

    }

    function initAttr() external onlyAdmin {
        stakingCSTPowerArray[NORMAL_RARITY]=Scope(1,1);//1
        stakingCSTPowerArray[GOOD_RARITY]=Scope(2,9);//2~9
        stakingCSTPowerArray[RARE_RARITY]=Scope(10,19);//10~19
        stakingCSTPowerArray[EPIC_RARITY]=Scope(20,29);//20~29
        stakingCSTPowerArray[LEGEND_RARITY]=Scope(30,40);//30~40

        stakingRubyPowerArray[NORMAL_RARITY]=Scope(10,15);//10~15
        stakingRubyPowerArray[GOOD_RARITY]=Scope(16,20);//16~20
        stakingRubyPowerArray[RARE_RARITY]=Scope(21,25);//21~25
        stakingRubyPowerArray[EPIC_RARITY]=Scope(26,30);//26~30
        stakingRubyPowerArray[LEGEND_RARITY]=Scope(31,40);//31~40


        lifeValueScopeArray[NORMAL_RARITY]=Scope(540,600);
        lifeValueScopeArray[GOOD_RARITY]=Scope(810,900);
        lifeValueScopeArray[RARE_RARITY]=Scope(960,1440);
        lifeValueScopeArray[EPIC_RARITY]=Scope(1260,2340);
        lifeValueScopeArray[LEGEND_RARITY]=Scope(2350,3000);
        
        attackValueScopeArray[NORMAL_RARITY]=Scope(90,110);
        attackValueScopeArray[GOOD_RARITY]=Scope(135,165);
        attackValueScopeArray[RARE_RARITY]=Scope(160,240);
        attackValueScopeArray[EPIC_RARITY]=Scope(210,390);
        attackValueScopeArray[LEGEND_RARITY]=Scope(395,500);

        defenseValueScopeArray[NORMAL_RARITY]=Scope(72,88);
        defenseValueScopeArray[GOOD_RARITY]=Scope(108,132);
        defenseValueScopeArray[RARE_RARITY]=Scope(128,192);
        defenseValueScopeArray[EPIC_RARITY]=Scope(168,312);
        defenseValueScopeArray[LEGEND_RARITY]=Scope(320,420);

        speedValueScopeArray[NORMAL_RARITY]=Scope(9,11);
        speedValueScopeArray[GOOD_RARITY]=Scope(13,17);
        speedValueScopeArray[RARE_RARITY]=Scope(16,24);
        speedValueScopeArray[EPIC_RARITY]=Scope(21,39);
        speedValueScopeArray[LEGEND_RARITY]=Scope(40,50);
        
    }

    function initStarTable() external onlyAdmin {
        

        starUpdateTable[NORMAL_RARITY]=[
            [1,0,0,0,0],
            [1,0,0,0,0],
            [2,0,0,0,0],
            [2,0,0,0,0],
            [3,0,0,0,0]
        ];

        starUpdateTable[GOOD_RARITY]=[
            [2,0,0,0,0],
            [2,0,0,0,0],
            [2,1,0,0,0],
            [2,2,0,0,0],
            [2,3,0,0,0]
        ];

        starUpdateTable[RARE_RARITY]=[
            [3,1,0,0,0],
            [3,1,0,0,0],
            [3,2,0,0,0],
            [3,2,0,0,0],
            [3,3,0,0,0]
        ];

        starUpdateTable[EPIC_RARITY]=[
            [4,1,0,0,0],
            [4,1,0,0,0],
            [4,2,0,0,0],
            [4,2,0,0,0],
            [2,4,0,0,0]
        ];

        starUpdateTable[LEGEND_RARITY]=[
            [4,1,0,0,0],
            [4,2,0,0,0],
            [2,4,0,0,0],
            [0,6,0,0,0],
            [0,6,0,0,0]
        ];

    }

    function queryRewardHatchingNestsCST(uint256 stakingCTSAmount) view public returns(uint256){
        for (uint256 i=0;i<5;++i){
            if (stakingCTSAmount<rewardHatchingNestsCST[i]){
                return i;
            }
        }
        return 5;
    }

    function setRewardHatchingNestsCST(uint256 [5] memory nestsCSTs) external onlyAdmin {
        rewardHatchingNestsCST=nestsCSTs;
    }

    function setPlayerStatusQueryInterface(address playerStatusQueryInterface_) external onlyAdmin {
        playerStatusQueryInterface=playerStatusQueryInterface_;
    }

    function setDefaultHatchingDuration(uint256 hatchingDuration) external onlyAdmin {
        defaultHatchingDuration=hatchingDuration;
    }

    function getOutputFoodProbabilityArray() view public returns(uint256 [RARITY_MAX+1] memory){
        return outputFoodProbabilityArray;
    }

    function setOutputFoodProbabilityArray(uint256 [RARITY_MAX+1] memory outputFoodProbabilityArray_) external onlyAdmin {
        outputFoodProbabilityArray=outputFoodProbabilityArray_;
    }

    function setRandomHolderInterface(address randomHolder_) external onlyAdmin {
        randomHolder=IRandomHolder(randomHolder_);
    }

    function setMarketFeesRate(uint256 marketFeesRate_) external onlyAdmin {
        require(marketFeesRate_<FRACTION_INT_BASE,"MetaInfoDb: marketFeesRate invalid");
        marketFeesRate=marketFeesRate_;
    }

    function setMarketFeesReceiverAddress(address marketFeesReceiverAddress_) external onlyAdmin {
        marketFeesReceiverAddress=marketFeesReceiverAddress_;
    }

    function setChestTokenAddress(uint256 kind,address chestAddr) external onlyAdmin {
        require(kind < chestAddressArray.length, "MetaInfoDb: index out of bound");
        chestAddressArray[kind]=chestAddr;
    }

    function setRarityParam(uint256 kind,uint256 rarity,uint256 probabilityFloat) external onlyAdmin {
        require(rarity<=LEGEND_RARITY);
        rarityProbabilityFloatArray[kind][rarity]=probabilityFloat;
    }

    function allRarityProbabilities() view public returns(uint256 [5] memory){
        return rarityProbabilityFloatArray[0];
    }

    function allNormalChestRarityProbabilities() view public returns(uint256 [5] memory){
        return rarityProbabilityFloatArray[1];
    }

    function setHatchCostInfo(uint256 index,uint256 rubyCost,uint256 CSTCost) external onlyAdmin {
        require(index<HATCH_MAX_TIMES,"MetaInfo: index must less then HATCH_MAX_TIMES");
        hatchCostInfos[index]=HatchCostInfo(rubyCost, CSTCost);
    }

    function getElementHeredityProbArray() view public returns(uint256 [6] memory){
        return elementHeredityProbArray;
    }

    function setElementHeredityProbArray(uint256 [6] memory probs) external onlyAdmin {
        elementHeredityProbArray=probs;
    }

    function allElementProbabilities() view public returns(uint256 [6] memory){
        return elementProbArray;
    }

    function getElementId(uint256 index) view public returns(uint256){
        return elementIdArray[index];
    }

    function getPartsLibCount(uint256 elementId) view public returns(uint256 [4] memory){
        return partsLib[elementId];
    }

    function getPartsProb(uint256 index) view public returns(uint256 [6] memory){
        return partsLibProb[index];
    }

    function getSkillsProb(uint256 index) view public returns(uint256 [6] memory){
        return skillsLibProb[index];
    }

    function setCSTAddr(address addr) external onlyAdmin {
        CSTAddress = addr;
    }

    function setRubyAddr(address addr) external onlyAdmin {
        rubyAddress = addr;
    }


    function setDragonNFTAddr(address addr) external onlyAdmin {
        dragonNFTAddr = addr;
    }

    function setEggNFTAddr(address addr) external onlyAdmin {
        eggNFTAddr = addr;
    }

    function setAccountInfoAddr(address addr) external onlyAdmin {
        accountInfoAddr = addr;
    }

    function setCSTBonusPoolAddress(address addr) external onlyAdmin {
        CSTBonusPoolAddress = addr;
    }
    function setCSTBonusPoolRate(uint256 rate) external onlyAdmin {
        CSTBonusPoolRate = rate;
    }

    function setCSTOrganizeAddress(address addr) external onlyAdmin {
        CSTOrganizeAddress = addr;
    }

    function setCSTOrganizeRate(uint256 rate) external onlyAdmin {
        CSTOrganizeRate = rate;
    }

    function setCSTTeamAddress(address addr) external onlyAdmin {
        CSTTeamAddress = addr;
    }
    function setCSTTeamRate(uint256 rate) external onlyAdmin {
        CSTTeamRate = rate;
    }

    function setRUBYBonusPoolAddress(address addr) external onlyAdmin {
        RUBYBonusPoolAddress = addr;
    }
    function setRUBYBonusPoolRate(uint256 rate) external onlyAdmin {
        RUBYBonusPoolRate = rate;
    }

    function setRUBYOrganizeAddress(address addr) external onlyAdmin {
        RUBYOrganizeAddress = addr;
    }
    function setRUBYOrganizeRate(uint256 rate) external onlyAdmin {
        RUBYOrganizeRate = rate;
    }

    function setRUBYTeamAddress(address addr) external onlyAdmin {
        RUBYTeamAddress = addr;
    }
    function setRUBYTeamRate(uint256 rate) external onlyAdmin {
        RUBYTeamRate = rate;
    }

    function setUSDBonusPoolAddress(address addr) external onlyAdmin {
        USDBonusPoolAddress = addr;
    }
    function setUSDBonusPoolRate(uint256 rate) external onlyAdmin {
        USDBonusPoolRate = rate;
    }

    function setUSDOrganizeAddress(address addr) external onlyAdmin {
        USDOrganizeAddress = addr;
    }
    function setUSDOrganizeRate(uint256 rate) external onlyAdmin {
        USDOrganizeRate = rate;
    }

    function setUSDTeamAddress(address addr) external onlyAdmin {
        USDTeamAddress = addr;
    }
    function setUSDTeamRate(uint256 rate) external onlyAdmin {
        USDTeamRate = rate;
    }

    function getStarUpdateTable(uint256 rarity,uint256 star) view public returns(uint256[5] memory){
        return starUpdateTable[rarity][star];
    }

    function setStarUpdateTable(uint256 rarity, uint256 star, uint256 [RARITY_MAX+1] memory rarityTable) external onlyAdmin {
        starUpdateTable[rarity][star]=rarityTable;
    }

    function setStakingCSTPowerArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        stakingCSTPowerArray[rarity]=Scope(lower, upper);
    }

    function setStakingRubyPowerArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        stakingRubyPowerArray[rarity]=Scope(lower, upper);
    }

    function setLifeValueScopeArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        lifeValueScopeArray[rarity]=Scope(lower, upper);
    }
    
    function setAttackValueScopeArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        attackValueScopeArray[rarity]=Scope(lower, upper);
    }

    function setDefenseValueScopeArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        defenseValueScopeArray[rarity]=Scope(lower, upper);
    }

    function setSpeedValueScopeArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        speedValueScopeArray[rarity]=Scope(lower, upper);
    }

    function setElementProbArray(uint256 element, uint256 prob) external onlyAdmin {
        elementProbArray[element]=prob;
    }

    function setQualityFactors(uint256 rarity, uint256 factor) external onlyAdmin {
        qualityFactors[rarity]=factor;
    }

    function setOutputFoodScopeArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        outputFoodScopeArray[rarity]=Scope(lower, upper);
    }

    function setSkillsLib(uint256 elementId,uint256 count) external onlyAdmin {
        skillsLib[elementId]=count;
    }

    function setPartsLib(uint256 elementId,uint256 [4] memory counts) external onlyAdmin {
        partsLib[elementId]=counts;
    }

    function setPartsLibProb(uint256 index, uint256 [6] memory probs) external onlyAdmin {
        partsLibProb[index]=probs;
    }

    function setSkillsLibProb(uint256 index, uint256 [6] memory probs) external onlyAdmin {
        skillsLibProb[index]=probs;
    }



    function rand3() public view returns(uint256) {
        return MathEx.randEx(randomHolder.getSeed());
    }

    function calcRandRarity(uint256 kind) view public returns(uint256){
        return probabilisticRandom5(rarityProbabilityFloatArray[kind]);
    }

    function calcRandRarityR(uint256 kind, uint256 rnd) view public returns(uint256){
        return MathEx.probabilisticRandom5R(rarityProbabilityFloatArray[kind], rnd);
    }

    function isValidSignature(bytes32 messageHash, address publicKey, uint8 v, bytes32 r, bytes32 s) public pure returns(bool){
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address addr = ecrecover(prefixedHash, v, r, s);
        return (addr==publicKey);
    }

    function scopeRand(uint256 beginNumber,uint256 endNumber) public view returns(uint256){
        return MathEx.rand(endNumber-beginNumber+1,randomHolder.getSeed())+beginNumber;
    }


    function probabilisticRandom4(uint256 [4] memory probabilities) view public returns(uint256/**index*/){

        uint256 totalRarityProbability=0;
        for (uint256 i=0;i<4;++i){
            totalRarityProbability+=probabilities[i];
            if (i>0){
                probabilities[i]+=probabilities[i-1];
            }
        }

        uint256 parityPoint=MathEx.rand(totalRarityProbability,randomHolder.getSeed());
        for (uint256 i=0;i<4;++i){
            if (parityPoint<probabilities[i]){
                return i;
            }
        }

        return 0;
    }


    function probabilisticRandom5(uint256 [5] memory probabilities) view  public returns(uint256/**index*/){

        uint256 totalRarityProbability=0;
        for (uint256 i=0;i<5;++i){
            totalRarityProbability+=probabilities[i];
            if (i>0){
                probabilities[i]+=probabilities[i-1];
            }
        }

        uint256 parityPoint=MathEx.rand(totalRarityProbability,randomHolder.getSeed());
        for (uint256 i=0;i<5;++i){
            if (parityPoint<probabilities[i]){
                return i;
            }
        }

        return 0;
    }
}