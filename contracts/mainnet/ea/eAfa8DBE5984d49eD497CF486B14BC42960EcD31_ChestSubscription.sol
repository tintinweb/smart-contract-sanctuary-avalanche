/**
 *Submitted for verification at snowtrace.io on 2022-03-17
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
            


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



            


pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}



            


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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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



            


pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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

////import "@openzeppelin/contracts/utils/Address.sol";
////import "@openzeppelin/contracts/access/AccessControl.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/utils/Context.sol";
////import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
////import "@openzeppelin/contracts/utils/math/Math.sol";


struct UserSubscriptionInfo
{
    uint256 idx;
    uint256 subNum;
    uint256 luckyNum;
    bool isLuckyUser;
}


contract ChestSubscription is Context , AccessControl
{
    using EnumerableSet for EnumerableSet.AddressSet;

    address immutable moneyToken;
    address immutable chestToken;

    uint256 public chestPrice;
    uint256 public chestAmountPerQuota;
    uint256 public subscriptQuota;
    mapping(address=>uint256/* subscript chest quantity */) [] _subscriptChestQtys;
    mapping(address=>uint256/* luckyUsers chest quantity */) [] _luckyUsersQtys;
    mapping(address=>uint256/* whitelistUsers chest quantity */) _whitelistUsersQtys;
    mapping(address=>uint256) public _allGetChestUsersInfo;

    EnumerableSet.AddressSet [] _subscriptUsers;
    EnumerableSet.AddressSet [] _luckyUsers;
    EnumerableSet.AddressSet _whitelistUsers;
    EnumerableSet.AddressSet _allUsersOwnChest;

    uint256[] public luckyMoneyQty;

    bool public _isFirst=true;
    bool public _isEnded;
    uint256 public _curIdx;
    uint256 public whitelistAvailbleQtys;
    uint256 public luckylistAvailbleQtys;
    uint256 public surplus;

    mapping(address=>mapping(uint256=>UserSubscriptionInfo)) public _userSubscriptionHistory;

    constructor(address chestTokenAddr,address moneyTokenAddr)
    {
        chestToken=chestTokenAddr;
        moneyToken=moneyTokenAddr;
        _isEnded=true;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    //send enough chest tokens to this before calling the function
    function start(uint256 subscriptQuota_,uint256 chestAmountPerQuota_ /*default to 3*/ ,uint256 chestPrice_) external{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChestSubscription: must have admin role to start");
        require(_isEnded==true,"ChestSubscription: end the current subscription first");

        subscriptQuota=subscriptQuota_;
        chestAmountPerQuota=chestAmountPerQuota_;
        chestPrice=chestPrice_;

        _subscriptChestQtys.push();
        _luckyUsersQtys.push();

        _subscriptUsers.push();
        _luckyUsers.push();

        luckyMoneyQty.push();

        _isEnded=false;

        if (!_isFirst) {
            _curIdx++;
        } else {
            _isFirst=false;
        }
    }

    function end() external{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChestSubscription: must have admin role to end");
        _isEnded=true;
        require(IERC20(chestToken).balanceOf(address(this))>=(luckyMoneyQty[_curIdx] + whitelistAvailbleQtys), "ChestSubscription: No enough chest tokens in the contract");
        surplus = surplus + luckyMoneyQty[_curIdx]*chestPrice;
    }

    //need approve
    function putInOrder(uint256 chestQty) external{
        require(!_isEnded, "ChestSubscription: Subscription is not open");
        require(_allGetChestUsersInfo[_msgSender()]+_subscriptChestQtys[_curIdx][_msgSender()]+chestQty<=chestAmountPerQuota,"ChestSubscription: out of the max subscription amount");

        uint256 moneyAmount=chestPrice*chestQty;
        require(IERC20(moneyToken).balanceOf(_msgSender())>=moneyAmount,"ChestSubscription:No enough money tokens in your wallet");

        IERC20(moneyToken).transferFrom(_msgSender(),address(this),moneyAmount);

        _subscriptChestQtys[_curIdx][_msgSender()]+=chestQty;
        _subscriptUsers[_curIdx].add(_msgSender());

        _userSubscriptionHistory[_msgSender()][_curIdx] = UserSubscriptionInfo(_curIdx, _subscriptChestQtys[_curIdx][_msgSender()], 0, false);

    }

    function getSubAmount(address user, uint256 idx) view public returns(uint256) {
        return _subscriptChestQtys[idx][user];
    }

    function getLuckylistAmount(address user, uint256 idx) view public returns(uint256) {
        return _luckyUsersQtys[idx][user];
    }

    function getWhitelistAmount(address user) view public returns(uint256) {
        return _whitelistUsersQtys[user];
    }

    function getSubInfo() view public returns(bool, uint256) {
        return (_isEnded, _curIdx);
    }

    function withdrawForFailedUser(uint256 idx) external{
        require(_isEnded && idx == _curIdx || idx < _curIdx,"ChestSubscription: Subscription is not end");
        require(_subscriptUsers[idx].contains(_msgSender()),"ChestSubscription: You did not subscript");
        require(!isLuckyUser(_msgSender(), idx),"ChestSubscription: You are the lucky user");

        _subscriptUsers[idx].remove(_msgSender());
        uint256 chestQty=_subscriptChestQtys[idx][_msgSender()];
        uint256 moneyAmount=chestPrice*chestQty;
        delete _subscriptChestQtys[idx][_msgSender()];
        IERC20(moneyToken).transfer(_msgSender(),moneyAmount);
    }

    function isLuckyUser(address user, uint256 idx) view public returns(bool){
        return _luckyUsers[idx].contains(user);
    }

    function isWhitelistUser(address user) view public returns(bool){
        return _whitelistUsers.contains(user);
    }

    function harvestChestForLucky(uint256 idx) external {
        require(_isEnded && idx == _curIdx || idx < _curIdx,"ChestSubscription: Subscription is not end");
        require(_subscriptUsers[idx].contains(_msgSender()),"ChestSubscription: You did not subscript");
        require(isLuckyUser(_msgSender(), idx),"ChestSubscription: You are not lucky user");

        _luckyUsers[idx].remove(_msgSender());
        IERC20(chestToken).transfer(_msgSender(), _luckyUsersQtys[idx][_msgSender()]);
        _allUsersOwnChest.add(_msgSender());
        luckylistAvailbleQtys -= _luckyUsersQtys[idx][_msgSender()];
        uint256 refund=chestPrice*(_subscriptChestQtys[idx][_msgSender()]-_luckyUsersQtys[idx][_msgSender()]);
        delete _subscriptChestQtys[idx][_msgSender()];
        if (refund > 0) {
            IERC20(moneyToken).transfer(_msgSender(),refund);
        }
    }

    function collectMoney() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChestSubscription: must have admin role to update lucky list");
        require(_isEnded,"ChestSubscription: Subscription is not end");
        IERC20(moneyToken).transfer(_msgSender(), surplus);
        surplus = 0;
    }

    function collectChest(uint256 chestQty) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChestSubscription: must have admin role to update lucky list");
        require(_isEnded,"ChestSubscription: Subscription is not end");
        require(chestQty <= IERC20(chestToken).balanceOf(address(this))-luckylistAvailbleQtys-whitelistAvailbleQtys,"ChestSubscription: No enough chest tokens to collect");

        IERC20(chestToken).transfer(_msgSender(), chestQty);
    }

    function buyForWhitelist(uint256 qty) external{
        require(_allGetChestUsersInfo[_msgSender()] < chestAmountPerQuota, "ChestSubscription: No purchase quota");
        require(_whitelistUsers.contains(_msgSender()), "ChestSubscription: You are not in whitelist");
        require(_whitelistUsersQtys[_msgSender()]>=qty, "ChestSubscription: Purchase quantity exceeds the limit");

        _whitelistUsersQtys[_msgSender()] -= qty;
        uint256 moneyAmount=chestPrice*qty;
        IERC20(moneyToken).transferFrom(_msgSender(),address(this),moneyAmount);
        surplus += moneyAmount;

        IERC20(chestToken).transfer(_msgSender(), qty);
        whitelistAvailbleQtys -= qty;
        _allGetChestUsersInfo[_msgSender()] += qty;
        _allUsersOwnChest.add(_msgSender());
    }

    function getLuckyListByIndex(uint256 beginIndex, uint256 length) view public returns(address[] memory, uint256[] memory) {
        uint256 endIndex=Math.min(_luckyUsers[_curIdx].length(), beginIndex+length);

        address[] memory users = new address[](endIndex-beginIndex);
        uint256[] memory usersQtys = new uint256[](endIndex-beginIndex);
        for(uint256 i=beginIndex;i<endIndex;++i){
            users[i-beginIndex] = _luckyUsers[_curIdx].at(i);
            usersQtys[i-beginIndex] = _luckyUsersQtys[_curIdx][users[i-beginIndex]];
        }
        return (users, usersQtys);
    }

    function addToLuckyList(address[] calldata users, uint256[] calldata usersQtys) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChestSubscription: must have admin role to update lucky list");
        require(!_isEnded,"ChestSubscription: Subscription is end");

        uint256 count = 0;
        for (uint256 i=0; i<users.length; i++) {
            if (_luckyUsers[_curIdx].contains(users[i])) {
                count++;
            }
        }

        require(_luckyUsers[_curIdx].length() + users.length - count <= subscriptQuota, "ChestSubscription: Lucky list should be less total");

        for (uint256 i=0; i<users.length; i++) {
            uint256 userQty = Math.min(usersQtys[i], _subscriptChestQtys[_curIdx][users[i]]);
            if (_luckyUsers[_curIdx].contains(users[i])) {
                luckyMoneyQty[_curIdx] += (userQty - _luckyUsersQtys[_curIdx][users[i]]);
                _allGetChestUsersInfo[users[i]] += (userQty - _luckyUsersQtys[_curIdx][users[i]]);
                luckylistAvailbleQtys += (userQty - _luckyUsersQtys[_curIdx][users[i]]);
            } else {
                _luckyUsers[_curIdx].add(users[i]);
                luckyMoneyQty[_curIdx] += userQty;
                _allGetChestUsersInfo[users[i]] += userQty;
                luckylistAvailbleQtys += userQty;
            }
            _luckyUsersQtys[_curIdx][users[i]] = userQty;

            _userSubscriptionHistory[users[i]][_curIdx].isLuckyUser = true;
            _userSubscriptionHistory[users[i]][_curIdx].luckyNum = _luckyUsersQtys[_curIdx][users[i]];

        }
    }

    function removeFromLuckyList(address[] calldata users) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChestSubscription: must have admin role to update lucky list");
        require(!_isEnded,"ChestSubscription: Subscription is end");

        for (uint256 i=0; i<users.length; i++) {
            if (_luckyUsers[_curIdx].contains(users[i])) {
                _luckyUsers[_curIdx].remove(users[i]);
                luckyMoneyQty[_curIdx] -= _luckyUsersQtys[_curIdx][users[i]];
                _allGetChestUsersInfo[users[i]] -= _luckyUsersQtys[_curIdx][users[i]];
                luckylistAvailbleQtys -= _luckyUsersQtys[_curIdx][users[i]];
                delete _luckyUsersQtys[_curIdx][users[i]];

                _userSubscriptionHistory[users[i]][_curIdx].isLuckyUser = false;
                _userSubscriptionHistory[users[i]][_curIdx].luckyNum = 0;
            }
        }

    }

    function getWhitelistByIndex(uint256 beginIndex, uint256 length) view public returns(address[] memory, uint256[] memory) {
        uint256 endIndex=Math.min(_whitelistUsers.length(), beginIndex+length);

        address[] memory users = new address[](endIndex-beginIndex);
        uint256[] memory usersQtys = new uint256[](endIndex-beginIndex);
        for(uint256 i=beginIndex;i<endIndex;++i){
            users[i-beginIndex] = _whitelistUsers.at(i);
            usersQtys[i-beginIndex] = _whitelistUsersQtys[users[i-beginIndex]];
        }
        return (users, usersQtys);
    }

    function addToWhitelist(address[] calldata users, uint256[] calldata usersQtys) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChestSubscription: must have admin role to update whitelist");
        require(!_isEnded,"ChestSubscription: Subscription is end");

        for (uint256 i=0; i<users.length; i++) {
            require(_allGetChestUsersInfo[users[i]] + usersQtys[i] <= chestAmountPerQuota, "ChestSubscription: White user out of the max buy amount");
            if (_whitelistUsers.contains(users[i])) {
                whitelistAvailbleQtys += (usersQtys[i] - _whitelistUsersQtys[users[i]]);
            } else {
                _whitelistUsers.add(users[i]);
                whitelistAvailbleQtys += usersQtys[i];
            }
            _whitelistUsersQtys[users[i]] = usersQtys[i];
        }
    }

    
    function removeFromWhitelist(address[] calldata users) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChestSubscription: must have admin role to update whitelist");
        require(!_isEnded,"ChestSubscription: Subscription is end");

        for (uint256 i=0; i<users.length; i++) {
            if (_whitelistUsers.contains(users[i])) {
                _whitelistUsers.remove(users[i]);
                whitelistAvailbleQtys -= (_whitelistUsersQtys[users[i]] - _allGetChestUsersInfo[users[i]]); /// 对于已经购买用户处理
                delete _whitelistUsersQtys[users[i]];
            }
        }

    }

    function luckyListLength() view public returns(uint256){
        return _luckyUsers[_curIdx].length();
    }

    function whitelistLength() view public returns(uint256){
        return _whitelistUsers.length();
    }

    function subscriptUsersLength() view public returns(uint256){
        return _subscriptUsers[_curIdx].length();
    }

    function subscriptUsersByIndex(uint256 beginIndex,uint256 length) view public returns(address[] memory, uint256[] memory){
        uint256 endIndex=Math.min(_subscriptUsers[_curIdx].length(), beginIndex+length);

        address[] memory users = new address[](endIndex-beginIndex);
        uint256[] memory usersQtys = new uint256[](endIndex-beginIndex);
        for(uint256 i=beginIndex;i<endIndex;++i){
            users[i-beginIndex] = _subscriptUsers[_curIdx].at(i);
            usersQtys[i-beginIndex] = _subscriptChestQtys[_curIdx][users[i-beginIndex]];
        }
        return (users, usersQtys);
    }

    function getUserChestQty(address user) view public returns(uint256){
        return _allGetChestUsersInfo[user];
    }

    function getUsersOwnChestByIndex(uint256 beginIndex, uint256 length) view public returns(address[] memory, uint256[] memory){
        uint256 endIndex=Math.min(_allUsersOwnChest.length(), beginIndex+length);

        address[] memory users = new address[](endIndex-beginIndex);
        uint256[] memory usersQtys = new uint256[](endIndex-beginIndex);
        for(uint256 i = beginIndex; i < endIndex; ++i) {
            users[i-beginIndex] = _allUsersOwnChest.at(i);
            usersQtys[i-beginIndex] = _allGetChestUsersInfo[users[i-beginIndex]];
        }
        return (users, usersQtys);
    }

    function getUserSubHistoryByIndex(address user, uint256 beginIndex, uint256 endIndex) view public returns(UserSubscriptionInfo [] memory){
        UserSubscriptionInfo [] memory userHistory = new UserSubscriptionInfo [](endIndex-beginIndex+1);
        for (uint256 i = beginIndex; i <= endIndex; ++i) {
            if (_userSubscriptionHistory[user][i].subNum != 0) {
                userHistory[i] = _userSubscriptionHistory[user][i];
            }
            else {
                userHistory[i] = UserSubscriptionInfo(i, 0, 0, false);
            }
        }

        return userHistory;

    }

}