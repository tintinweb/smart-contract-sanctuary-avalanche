/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-30
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/access/[email protected]

// uint i MIT
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


// File @openzeppelin/contracts/utils/[email protected]

// uint i MIT
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// uint i MIT
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// uint i MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/math/[email protected]

// uint i MIT
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
        // ÔåÆ `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // ÔåÆ `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
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


// File @openzeppelin/contracts/utils/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




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


// File @openzeppelin/contracts/access/[email protected]

// uint i MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/structs/[email protected]

// uint i MIT
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


// File @openzeppelin/contracts/access/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;



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


// File @openzeppelin/contracts/access/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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


// File @openzeppelin/contracts/interfaces/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


// File @openzeppelin/contracts/security/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/common/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC1155/extensions/[email protected]

// uint i MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/[email protected]

// uint i MIT
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


// File @openzeppelin/contracts/token/ERC1155/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;






/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


// File @openzeppelin/contracts/token/ERC1155/extensions/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }
}


// File @openzeppelin/contracts/token/ERC1155/extensions/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
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
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}


// File @openzeppelin/contracts/token/ERC1155/presets/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity ^0.8.0;





/**
 * @dev {ERC1155} token, including:
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
contract ERC1155PresetMinterPauser is Context, AccessControlEnumerable, ERC1155Burnable, ERC1155Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}


// File @openzeppelin/contracts/token/ERC1155/utils/[email protected]

// uint i MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}


// File @openzeppelin/contracts/token/ERC1155/utils/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// uint i MIT
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// uint i MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// uint i MIT
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// uint i MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// uint i MIT
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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// uint i MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {ERC2981-_setDefaultRoyalty}, and/or individually for
 * specific token ids via {ERC2981-_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721Royalty is ERC2981, ERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}


// File @openzeppelin/contracts/token/ERC721/utils/[email protected]

// uint i MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
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
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

// uint i MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}


// File @thetrees1529/solutils/contracts/gamefi/[email protected]

//uint i Unlicensed
pragma solidity ^0.8.0;

interface IRandom {

    function numWords() external view returns(uint32);
    function CONSUMER_ROLE() external view returns(bytes32);

    function vrfConfig() external view returns(bytes32,uint64,uint16,uint32);
    function vrfCoordinator() external view returns(VRFCoordinatorV2Interface);

    function requestRandom(uint[] calldata options) external returns(uint requestId);

}


// File @thetrees1529/solutils/contracts/gamefi/[email protected]

// uint i MIT
pragma solidity ^0.8.0;


abstract contract Nft is AccessControl, ERC721Enumerable {

    string private baseUri;

    constructor(string memory uri) {
        _setBaseURI(uri);
    }

    function supportsInterface(bytes4 interfaceId) public virtual override(AccessControl, ERC721Enumerable) view returns(bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory _newUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(_newUri);
    }

    function _setBaseURI(string memory _newUri) private {
        baseUri = _newUri;
    }

    // hooks / overrides

    function _baseURI() internal virtual override view returns(string memory) {
        return baseUri;
    }

}


// File @thetrees1529/solutils/contracts/gamefi/[email protected]

//uint i UNLICENSED
pragma solidity ^0.8.0;

library OwnerOf {
    
    function isOwnerOf(IERC721 token, address account, uint tokenId) internal view returns(bool) {
        return token.ownerOf(tokenId) == account;
    }

}


// File @thetrees1529/solutils/contracts/gamefi/[email protected]

//uint i Unlicensed
pragma solidity ^0.8.0;
interface IRandomConsumer {
    function rawFulFillRandom(uint requestId, uint result) external;
}


// File @thetrees1529/solutils/contracts/payments/[email protected]

//uint i UNLICENSED
pragma solidity ^0.8.0;
library Fees {
    struct Fee {
        uint numerator;
        uint denominator;
    }
    function feesOf(uint value, Fee storage fee) internal view returns(uint) {
        return fee.denominator > 0 ? (value * fee.numerator) / fee.denominator : 0;
    }
}


// File @thetrees1529/solutils/contracts/gamefi/[email protected]

//uint i Unlicensed
pragma solidity ^0.8.0;



abstract contract RandomConsumer is IRandomConsumer {
    IRandom public random;
    constructor(IRandom random_) {
        random = random_;
    }
    function rawFulFillRandom(uint requestId, uint result) external {
        require(msg.sender == address(random), "Not allowed.");
        _fulfillRandom(requestId, result);
    }
    function _requestRandom(uint[] memory options) internal returns(uint) {
        return random.requestRandom(options);
    }
    function _fulfillRandom(uint requestId, uint result) internal virtual;
}


// File @thetrees1529/solutils/contracts/payments/[email protected]

//uint i UNLICENSED
pragma solidity ^0.8.0;

library ERC20Payments {

    using SafeERC20 for IERC20;

    struct Payee {
        address addr;
        uint weighting;
    }

    function split(IERC20 token, uint value, Payee[] memory payees) internal {
        splitFrom(token, address(this), value, payees);
    }

    function splitFrom(IERC20 token, address from, uint value, Payee[] memory payees) internal {
        uint totalWeighting;
        for(uint i; i < payees.length; i ++) {
            totalWeighting += payees[i].weighting;
        }
        require(totalWeighting > 0, "ERC20Payments: must have at least 1 weighting.");
        for(uint i; i < payees.length; i ++) {
            Payee memory payee = payees[i];
            uint payment = (payee.weighting * value) / totalWeighting;
            _send(token,from, payee.addr, payment);
        }
    }

    function _send(IERC20 token, address from, address to, uint value) private {
        if(from == address(this)) token.safeTransfer(to,value);
        else token.safeTransferFrom(from, to, value);
    }

}


// File contracts/Token/Token.sol

//uint i UNLICENSED

pragma solidity 0.8.17;
contract Token is ERC20Burnable, AccessControl {

    uint public MAX_SUPPLY;

    struct TransferInput {
        address to;
        uint amount;
    }

    struct TransferFromInput {
        address from;
        address to;
        uint amount;
    }
    
    constructor(string memory name, string memory symbol, uint MAX_SUPPLY_) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TOKEN_MAESTRO_ROLE, msg.sender);
        MAX_SUPPLY = MAX_SUPPLY_;
    } 

    bytes32 public constant OPT_OUT_SKIP_ALLOWANCE = keccak256("OPT_OUT_SKIP_ALLOWANCE");
    bytes32 public constant TOKEN_MAESTRO_ROLE = keccak256("TOKEN_MAESTRO_ROLE");

    mapping(address => mapping(address => uint)) private _volume;

    function getVolume(address from, address to) external view returns(uint) {return _volume[from][to];}

    function mint(uint amount) external onlyRole(TOKEN_MAESTRO_ROLE) {_mint(msg.sender, amount);}

    function mintTo(address account, uint amount) external onlyRole(TOKEN_MAESTRO_ROLE) {_mint(account, amount);}

    function burnFrom(address account, uint amount) public override {
        if(_allowanceSkippable(account)) _approve(account, msg.sender, amount);
        super.burnFrom(account,amount);
    }

    function optOutSkipAllowance() external {
        _grantRole(OPT_OUT_SKIP_ALLOWANCE, msg.sender);
    }

    function optInSkipAllowance() external {
        _revokeRole(OPT_OUT_SKIP_ALLOWANCE, msg.sender);
    }

    function grantRole(bytes32 role, address account) public override {
        require(!_cannotGrantOrRevoke(role), "Cannot grant opt out skip allowance");
        super.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public override {
        require(!_cannotGrantOrRevoke(role), "Cannot revoke opt out skip allowance");
        super.revokeRole(role, account);
    }

    function _cannotGrantOrRevoke(bytes32 role) private pure returns(bool) {
        return role == OPT_OUT_SKIP_ALLOWANCE;
    }

    function transferFrom(address from, address to, uint amount) public override returns(bool) {
        if(!_allowanceSkippable(from)) return super.transferFrom(from, to, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _allowanceSkippable(address account) private view returns(bool) {
        return hasRole(TOKEN_MAESTRO_ROLE, msg.sender) && !hasRole(OPT_OUT_SKIP_ALLOWANCE, account);
    }

    function multiTransfer(TransferInput[] calldata transfers) external {
        uint len = transfers.length;
        for(uint i; i < len; i ++) {
            TransferInput calldata transfer_ = transfers[i];  
            transfer(transfer_.to, transfer_.amount);
        }
    }

    function multiTransferFrom(TransferFromInput[] calldata transferFroms) external {
        uint len = transferFroms.length;
        for(uint i; i < len; i ++) {
            TransferFromInput calldata transferFrom_ = transferFroms[i];  
            transferFrom(transferFrom_.from, transferFrom_.to, transferFrom_.amount);
        }
    }

    function _mint(address account, uint amount) internal override {
        super._mint(account,amount);
        require(totalSupply() <= MAX_SUPPLY, "Max supply reached.");
    }

    function _afterTokenTransfer(address from, address to, uint amount) internal override {
        _volume[from][to] += amount;
    }

}


// File contracts/Dependencies/EarnOld.sol

// uint i MIT
pragma solidity 0.8.17;
contract EarnOld is AccessControl {

    uint constant public EARN_SPEED_CONVERSION = 11574074074074;

    using Fees for uint;
    using ERC20Payments for IERC20;

    struct Payment {
        IERC20 token;
        uint value;
    }

    struct Substage {
        string name;
        Payment[] payments;
        uint emission;
    }

    struct Stage {
        string name;
        Substage[] substages;
    }

    struct Location {
        uint stage;
        uint substage;
    }

    struct Nfv {
        bool onStages;
        bool claimedOnce;
        uint lastClaim;
        uint pendingClaim;
        uint locked;
        uint unlocked;
        uint pendingInterest;
        uint totalInterestClaimed;
        uint totalClaimed;
        Location location;
    }

    struct NfvView {
        uint claimable;
        uint interestable;
        uint locked;
        uint unlockable;
        bool onStages;
        Location location;
        Nfv nfv;
    }

    struct ERC20Token {
        uint burned;
        uint reflected;
    }

    function getInformation(uint tokenId) external view minted(tokenId) returns(NfvView memory nfv) {
        return NfvView({
            claimable: getClaimable(tokenId),
            locked: getLocked(tokenId),
            unlockable: getUnlockable(tokenId),
            interestable: getInterest(tokenId),
            onStages: nfvInfo[tokenId].onStages,
            location: nfvInfo[tokenId].location,
            nfv: nfvInfo[tokenId]
        });
    }

    bytes32 public EARN_ROLE = keccak256("EARN_ROLE"); 

    uint public genesis;
    uint public unlockStart;
    uint public unlockEnd;
    uint public baseEarn;
    uint public mintCap;
    uint public totalMinted;
    mapping(IERC20 => ERC20Token) public tokens;
    Stage[] private _stages;
    Fees.Fee public lockRatio;
    Fees.Fee public burnRatio;
    Fees.Fee public interest;
    Token public token;
    IERC721 public nfvs;
    ERC20Payments.Payee[] private _payees;

    mapping(uint => Nfv) public nfvInfo;

    constructor(IERC721 nfvs_, Token token_, Stage[] memory stages, Fees.Fee memory lockRatio_, Fees.Fee memory burnRatio_, Fees.Fee memory interest_, uint unlockStart_, uint unlockEnd_, uint baseEarn_, uint mintCap_) {
        token = token_;
        nfvs = nfvs_;
        for(uint i; i < stages.length; i ++) {
            Stage memory stage = stages[i];
            Stage storage _stage = _stages.push();
            _stage.name = stage.name;
            for(uint j; j < stage.substages.length; j ++) {
                Substage memory substage = stage.substages[j];
                Substage storage _substage = _stage.substages.push();
                _substage.name = substage.name;
                _substage.emission = substage.emission;
                for(uint k; k < substage.payments.length; k ++) {
                    _substage.payments.push(substage.payments[k]);
                }
            }
        }
        lockRatio = lockRatio_;
        burnRatio = burnRatio_;
        interest = interest_;
        genesis = block.timestamp;
        unlockStart = unlockStart_;
        unlockEnd = unlockEnd_;
        baseEarn = baseEarn_;
        mintCap = mintCap_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setPayees(ERC20Payments.Payee[] calldata payees) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _payees;
        for(uint i; i < payees.length; i ++) {
            _payees.push(payees[i]);
        }
    }

    function setLockRatio(Fees.Fee calldata lockRatio_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockRatio = lockRatio_;
    }

    function setBurnRatio(Fees.Fee calldata burnRatio_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        burnRatio = burnRatio_;
    }

    function getPayees() external view returns(ERC20Payments.Payee[] memory) {return _payees;}

    function getStages() external view returns(Stage[] memory) {
        return _stages;
    }

    function getUnlockedClaimable(uint tokenId) public view minted(tokenId) returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint pending = _getPending(tokenId);
        return nfv.pendingClaim + (pending - pending.feesOf(lockRatio));
    }

    function getClaimable(uint tokenId) public view minted(tokenId) returns(uint) {
        return _getPending(tokenId);
    }

    function getPendingLocked(uint tokenId) public view minted(tokenId) returns(uint) {
        uint pending = _getPending(tokenId);
        return pending.feesOf(lockRatio);
    }

    function getInterest(uint tokenId) public view minted(tokenId) returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.pendingInterest + _getPendingInterest(tokenId);
    }

    function getLocked(uint tokenId) public view minted(tokenId) returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.locked - nfv.unlocked;
    }

    function unlock(uint tokenId) external onlyOwnerOf(tokenId) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint toUnlock = getUnlockable(tokenId);
        nfv.unlocked += toUnlock;
        _mintTo(msg.sender, toUnlock);
    }

    function getUnlockable(uint tokenId) public view minted(tokenId) returns(uint){
        Nfv storage nfv = nfvInfo[tokenId];
        uint totalTime = unlockEnd - unlockStart;
        uint timeElapsed; 
        if(block.timestamp >= unlockStart) timeElapsed = block.timestamp - unlockStart;
        uint timeUnlocking = timeElapsed <= totalTime ? timeElapsed : totalTime;
        uint theoreticalLocked = (nfv.locked * timeUnlocking) / totalTime;
        return theoreticalLocked - nfv.unlocked;
    }

    function claimMultiple(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            claim(tokenIds[i]);
        }
    }

    function claim(uint tokenId) public onlyOwnerOf(tokenId) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        uint pendingClaim = nfv.pendingClaim;
        nfv.totalClaimed += pendingClaim;
        delete nfv.pendingClaim;
        _mintTo(msg.sender, pendingClaim);
    }

    function claimInterestMultiple(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            claimInterest(tokenIds[i]);
        }
    }

    function claimInterest(uint tokenId) public onlyOwnerOf(tokenId) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        uint pendingInterest = nfv.pendingInterest;
        nfv.totalInterestClaimed += pendingInterest;
        delete nfv.pendingInterest;
        _mintTo(msg.sender, pendingInterest);
    }


    function upgradeMultiple(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            upgrade(tokenIds[i]);
        }
    }

    function upgrade(uint tokenId) public onlyOwnerOf(tokenId) {
        Nfv storage nfv = nfvInfo[tokenId];
        Location memory location = nfv.location;
        if(nfv.onStages) {
            Stage storage currentStage = _stages[location.stage];
            if(location.substage == currentStage.substages.length - 1) {
                require(location.stage < _stages.length - 1, "Fully upgraded.");
                location.stage ++;
                location.substage = 0;
            } else {
                location.substage ++;
            }
        }
        _setLocation(tokenId, location);
        Substage storage substage = _getSubstage(location);
        for(uint i; i < substage.payments.length; i ++) {
            _takePayment(msg.sender, substage.payments[i]);
        }
    }

    function isInLocation(uint tokenId) external view  minted(tokenId) returns(bool) {
        return nfvInfo[tokenId].onStages;
    }

    function getLocation(uint tokenId) external view minted(tokenId) returns(Location memory) {
        Nfv storage nfv = nfvInfo[tokenId];
        require(nfv.onStages, "Not in a location.");
        return nfv.location;
    } 

    function setLocation(uint tokenId, Location calldata location) external onlyRole(EARN_ROLE) {
        _setLocation(tokenId, location);
    }

    function addToLocked(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        require(!_unlockStarted(), "Unlock already started.");
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.locked += change;
    }
    
    function removeFromToLocked(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        require(!_unlockStarted(), "Unlock already started.");
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.locked -= change;
    }

    function addToClaimable(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.pendingClaim += change;
    }

    function removeFromClaimable(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.pendingClaim -= change;
    }

    function addToInterest(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.pendingInterest += change;
    }

    function removeFromInterest(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.pendingInterest -= change;
    }

    function _setLocation(uint tokenId, Location memory location) private {
        require(_isValidLocation(location), "Setting invalid location.");
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        if(!nfv.onStages) nfv.onStages = true;
        nfv.location = location;
    }

    function exitLocation(uint tokenId) external onlyRole(EARN_ROLE) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        if(nfv.onStages) {
            nfv.onStages = false;
            delete nfv.location;
        }
    }

    function _unlockStarted() private view returns(bool) {
        return block.timestamp >= unlockStart;
    }

    function _claim(uint tokenId) private {
        Nfv storage nfv = nfvInfo[tokenId];

        uint interested = _getPendingInterest(tokenId);
        uint claimed = _getPending(tokenId);
        uint locked = claimed.feesOf(lockRatio);
        uint pendingClaim = claimed - locked;

        nfv.pendingInterest += interested;
        nfv.pendingClaim += pendingClaim;
        nfv.locked += locked;
        nfv.lastClaim = block.timestamp;
        if(!nfv.claimedOnce) nfv.claimedOnce = true;
    }

    function _getPending(uint tokenId) private view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint earningSince = _claimedOrGenesis(tokenId);
        Location storage location = nfv.location;
        uint emission = nfv.onStages ? _getSubstage(location).emission : baseEarn;
        uint timeEarning = block.timestamp - earningSince;
        return timeEarning * (emission * EARN_SPEED_CONVERSION);
    }

    function _getPendingInterest(uint tokenId) private view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint timeSince = _claimedOrGenesis(tokenId);
        uint until = block.timestamp <= unlockEnd ? block.timestamp : unlockEnd;
        uint timeElapsed = until > timeSince ? until - timeSince : 0;
        return (nfv.locked * timeElapsed).feesOf(interest);
    }

    function _claimedOrGenesis(uint tokenId) private view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.claimedOnce ? nfv.lastClaim : genesis;
    }

    function _getSubstage(Location memory location) private view returns(Substage storage) {
        require(_isValidLocation(location), "Location is invalid.");
        return _stages[location.stage].substages[location.substage];
    }

    function _isValidLocation(Location memory location) private view returns(bool) {
        return location.stage < _stages.length && location.substage < _stages[location.stage].substages.length;
    }


    function _takePayment(address from, Payment storage payment) private {
        ERC20Token storage erc20Token = tokens[payment.token];
        uint total = payment.value;
        payment.token.transferFrom(from, address(this), total);

        uint attemptedBurn = total.feesOf(burnRatio);
        try Token(address(payment.token)).burn(attemptedBurn) {
            total -= attemptedBurn;
            erc20Token.burned += attemptedBurn;
        }
        catch {}

        payment.token.split(total, _payees);
        erc20Token.reflected += total;
    }

    //never needs to be used unless there is a bug.
    function withdraw(uint value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.transfer(msg.sender, value);
    }

    modifier onlyOwnerOf(uint tokenId) {
        require(OwnerOf.isOwnerOf(nfvs, msg.sender, tokenId), "Does not own NFT.");
        _;
    }

    modifier minted(uint tokenId) {
        try nfvs.ownerOf(tokenId) returns(address) {
        } catch {
            revert("Not minted.");
        }
        
        _;
    }

    function _mintTo(address addr, uint value) private {
        require(totalMinted + value <= mintCap, "Mint cap reached.");
        totalMinted += value;
        token.mintTo(addr, value);
    }


}


// File contracts/Game/Attributes.sol

// uint i MIT
pragma solidity 0.8.17;
contract Attributes is AccessControl {

    struct AttributeView {
        string statistic;
        uint256 value;
    }

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        // attribute/statistics information
        _addNewAttribute("power");
        _addNewAttribute("handling");
        _addNewAttribute("boost");
        _addNewAttribute("tires");
    }

    string[] private attributeKeys;
    mapping(uint => mapping(string => uint)) private statistics;

    function getAttributes(uint256 _tokenId) public view returns (AttributeView[] memory) {
        uint256 _statisticsCount = attributeKeys.length;
        AttributeView[] memory _stats = new AttributeView[](_statisticsCount);
        for (uint256 i = 0; i < _statisticsCount; i++) {
            uint256 _value = getAttribute(_tokenId,attributeKeys[i]);
            _stats[i] = AttributeView({
                statistic: attributeKeys[i],
                value: _value
            });
        }
        return _stats;
    }

    function getAttribute(uint _tokenId, string memory attribute) public view returns(uint) {
        (bool exists,) = _attributeExists(attribute);
        require(exists, "Attribute doesn't exist.");
        return statistics[_tokenId][attribute];
    }

    function addNewAttribute(string memory _attribute) external onlyRole(UPGRADER_ROLE) {
        _addNewAttribute(_attribute);
    }

    function removeAttribute(string memory _attribute) external onlyRole(UPGRADER_ROLE) {
        _removeAttribute(_attribute);
    }

    function deleteAttributeKeys() external onlyRole(UPGRADER_ROLE) {
        delete attributeKeys;
    }

    struct ExpMod {
        uint tokenId;
        string attribute;
        uint change;
    }

    function addExpMultiple(ExpMod[] calldata expMods) external {
        for(uint i; i < expMods.length; i ++) addExp(expMods[i].tokenId, expMods[i].attribute, expMods[i].change);
    }

    function removeExpMultiple(ExpMod[] calldata expMods) external {
        for(uint i; i < expMods.length; i ++) removeExp(expMods[i].tokenId, expMods[i].attribute, expMods[i].change);
    }

    function addExp(uint256 _tokenId, string memory _attribute, uint256 _toAdd) public onlyRole(UPGRADER_ROLE) {
        statistics[_tokenId][_attribute] += _toAdd;
    }

    function removeExp(uint tokenId, string calldata attribute, uint toRemove) public onlyRole(UPGRADER_ROLE) {
        statistics[tokenId][attribute] -= toRemove;
    }

    function attributeKeyExists(string memory _attribute) external view returns(bool exists) {
        (exists,) = _attributeExists(_attribute);
    }

    function getAttributeKeys() external view returns (string[] memory) {
        return attributeKeys;
    }

    function _addNewAttribute(string memory _attribute) private {
        (bool exists,) = _attributeExists(_attribute);
        require(!exists, "Attribute already exists.");
        attributeKeys.push(_attribute);
    }

    function _removeAttribute(string memory _attribute) private {
        (bool exists,uint at) = _attributeExists(_attribute);
        if(!exists) revert("Attribute does not exist.");
        for(uint i = at + 1; i < attributeKeys.length; i ++) {
            attributeKeys[i - 1] = attributeKeys[i];
        }
        attributeKeys.pop();
    }

    function _attributeExists(string memory attribute) private view returns(bool exists,uint at) {
        for(uint i; i < attributeKeys.length; i ++) {
            if(sha256(bytes(attribute)) == sha256(bytes(attributeKeys[i]))) return (true,i);
        }
    }

}


// File contracts/Game/Earn.sol

// uint i MIT
pragma solidity 0.8.17;
contract Earn is AccessControl {

    uint constant public EARN_SPEED_CONVERSION = 11574074074074;

    using Fees for uint;
    using ERC20Payments for IERC20;

    struct Payment {
        IERC20 token;
        uint value;
    }

    struct Substage {
        string name;
        Payment[] payments;
        uint emission;
    }

    struct Stage {
        string name;
        Substage[] substages;
    }

    struct Location {
        uint stage;
        uint substage;
    }

    struct Nfv {
        bool onStages;
        bool claimedOnce;
        uint lastClaim;
        uint pendingClaim;
        uint locked;
        uint unlocked;
        uint pendingInterest;
        uint totalInterestClaimed;
        uint totalClaimed;
        Location location;
    }

    struct NfvView {
        uint claimable;
        uint unlockedClaimable;
        uint lockedClaimable;
        uint interestable;
        uint locked;
        uint unlockable;
        bool onStages;
        Location location;
        Nfv nfv;
    }

    struct ERC20Token {
        uint burned;
        uint reflected;
    }

    function getInformation(uint tokenId) external view minted(tokenId) returns(NfvView memory nfv) {
        return NfvView({
            claimable: getClaimable(tokenId),
            unlockedClaimable: getUnlockedClaimable(tokenId),
            lockedClaimable: getPendingLocked(tokenId),
            locked: getLocked(tokenId),
            unlockable: getUnlockable(tokenId),
            interestable: getInterest(tokenId),
            onStages: nfvInfo[tokenId].onStages,
            location: nfvInfo[tokenId].location,
            nfv: nfvInfo[tokenId]
        });
    }

    bytes32 public EARN_ROLE = keccak256("EARN_ROLE"); 

    bool private _initialised;
    uint public genesis;
    uint public unlockStart;
    uint public unlockEnd;
    uint public baseEarn;
    uint public mintCap;
    uint public totalMinted;
    mapping(IERC20 => ERC20Token) public tokens;
    Stage[] private _stages;
    Fees.Fee public lockRatio;
    Fees.Fee public burnRatio;
    Fees.Fee public interest;
    Token public token;
    IERC721 public nfvs;
    ERC20Payments.Payee[] private _payees;

    mapping(uint => Nfv) public nfvInfo;

    constructor(IERC721 nfvs_, Token token_, Stage[] memory stages, Fees.Fee memory lockRatio_, Fees.Fee memory burnRatio_, Fees.Fee memory interest_, uint unlockStart_, uint unlockEnd_, uint baseEarn_, uint mintCap_) {
        token = token_;
        nfvs = nfvs_;
        _setStages(stages);
        lockRatio = lockRatio_;
        burnRatio = burnRatio_;
        interest = interest_;
        genesis = block.timestamp;
        unlockStart = unlockStart_;
        unlockEnd = unlockEnd_;
        baseEarn = baseEarn_;
        mintCap = mintCap_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //Avoid changing emissions because all pending amounts will backtrack to the new value. 
    function setStages(Stage[] calldata stages) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setStages(stages);
    }

    function setPayees(ERC20Payments.Payee[] calldata payees) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _payees;
        for(uint i; i < payees.length; i ++) {
            _payees.push(payees[i]);
        }
    }

    function setLockRatio(Fees.Fee calldata lockRatio_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockRatio = lockRatio_;
    }

    function setBurnRatio(Fees.Fee calldata burnRatio_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        burnRatio = burnRatio_;
    }

    function getPayees() external view returns(ERC20Payments.Payee[] memory) {return _payees;}

    function getStages() external view returns(Stage[] memory) {
        return _stages;
    }

    function getUnlockedClaimable(uint tokenId) public view minted(tokenId) returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint pending = _getPending(tokenId);
        return nfv.pendingClaim + (pending - pending.feesOf(lockRatio));
    }

    function getClaimable(uint tokenId) public view minted(tokenId) returns(uint) {
        return _getPending(tokenId);
    }

    function getPendingLocked(uint tokenId) public view minted(tokenId) returns(uint) {
        uint pending = _getPending(tokenId);
        return pending.feesOf(lockRatio);
    }

    function getInterest(uint tokenId) public view minted(tokenId) returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.pendingInterest + _getPendingInterest(tokenId);
    }

    function getLocked(uint tokenId) public view minted(tokenId) returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.locked - nfv.unlocked;
    }

    function unlock(uint tokenId) external onlyOwnerOf(tokenId) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint toUnlock = getUnlockable(tokenId);
        nfv.unlocked += toUnlock;
        _mintTo(msg.sender, toUnlock);
    }

    function getUnlockable(uint tokenId) public view minted(tokenId) returns(uint){
        Nfv storage nfv = nfvInfo[tokenId];
        uint totalTime = unlockEnd - unlockStart;
        uint timeElapsed; 
        if(block.timestamp >= unlockStart) timeElapsed = block.timestamp - unlockStart;
        uint timeUnlocking = timeElapsed <= totalTime ? timeElapsed : totalTime;
        uint theoreticalLocked = (nfv.locked * timeUnlocking) / totalTime;
        return theoreticalLocked - nfv.unlocked;
    }

    function claimMultiple(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            claim(tokenIds[i]);
        }
    }

    function claim(uint tokenId) public onlyOwnerOf(tokenId) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        uint pendingClaim = nfv.pendingClaim;
        nfv.totalClaimed += pendingClaim;
        delete nfv.pendingClaim;
        _mintTo(msg.sender, pendingClaim);
    }

    function claimInterestMultiple(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            claimInterest(tokenIds[i]);
        }
    }

    function claimInterest(uint tokenId) public onlyOwnerOf(tokenId) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        uint pendingInterest = nfv.pendingInterest;
        nfv.totalInterestClaimed += pendingInterest;
        delete nfv.pendingInterest;
        _mintTo(msg.sender, pendingInterest);
    }


    function upgradeMultiple(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            upgrade(tokenIds[i]);
        }
    }

    function upgrade(uint tokenId) public onlyOwnerOf(tokenId) {
        Nfv storage nfv = nfvInfo[tokenId];
        Location memory location = nfv.location;
        if(nfv.onStages) {
            Stage storage currentStage = _stages[location.stage];
            if(location.substage == currentStage.substages.length - 1) {
                require(location.stage < _stages.length - 1, "Fully upgraded.");
                location.stage ++;
                location.substage = 0;
            } else {
                location.substage ++;
            }
        }
        _setLocation(tokenId, location);
        Substage storage substage = _getSubstage(location);
        for(uint i; i < substage.payments.length; i ++) {
            _takePayment(msg.sender, substage.payments[i]);
        }
    }

    function isInLocation(uint tokenId) external view  minted(tokenId) returns(bool) {
        return nfvInfo[tokenId].onStages;
    }

    function getLocation(uint tokenId) external view minted(tokenId) returns(Location memory) {
        Nfv storage nfv = nfvInfo[tokenId];
        require(nfv.onStages, "Not in a location.");
        return nfv.location;
    } 

    function setLocation(uint tokenId, Location calldata location) external onlyRole(EARN_ROLE) {
        _setLocation(tokenId, location);
    }

    function addToLocked(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        require(!_unlockStarted(), "Unlock already started.");
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.locked += change;
    }
    
    function removeFromLocked(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        require(!_unlockStarted(), "Unlock already started.");
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.locked -= change;
    }

    function addToClaimable(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.pendingClaim += change;
    }

    function removeFromClaimable(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.pendingClaim -= change;
    }

    function addToInterest(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.pendingInterest += change;
    }

    function removeFromInterest(uint tokenId, uint change) external onlyRole(EARN_ROLE) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.pendingInterest -= change;
    }

    function _setLocation(uint tokenId, Location memory location) private {
        require(_isValidLocation(location), "Setting invalid location.");
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        if(!nfv.onStages) nfv.onStages = true;
        nfv.location = location;
    }

    function exitLocation(uint tokenId) external onlyRole(EARN_ROLE) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        if(nfv.onStages) {
            nfv.onStages = false;
            delete nfv.location;
        }
    }

    function _setStages(Stage[] memory stages) private {
        if(_initialised){
            require(stages.length == _stages.length);
            for(uint i; i < stages.length; i ++) {
                require(stages[i].substages.length == _stages[i].substages.length);
            }
            delete _stages;
            _initialised = true;
        }
        for(uint i; i < stages.length; i ++) {
            Stage memory stage = stages[i];
            Stage storage _stage = _stages.push();
            _stage.name = stage.name;
            for(uint j; j < stage.substages.length; j ++) {
                Substage memory substage = stage.substages[j];
                Substage storage _substage = _stage.substages.push();
                _substage.name = substage.name;
                _substage.emission = substage.emission;
                for(uint k; k < substage.payments.length; k ++) {
                    _substage.payments.push(substage.payments[k]);
                }
            }
        }
    }

    function _unlockStarted() private view returns(bool) {
        return block.timestamp >= unlockStart;
    }

    function _claim(uint tokenId) private {
        Nfv storage nfv = nfvInfo[tokenId];

        uint interested = _getPendingInterest(tokenId);
        uint claimed = _getPending(tokenId);
        uint locked = claimed.feesOf(lockRatio);
        uint pendingClaim = claimed - locked;

        nfv.pendingInterest += interested;
        nfv.pendingClaim += pendingClaim;
        nfv.locked += locked;
        nfv.lastClaim = block.timestamp;
        if(!nfv.claimedOnce) nfv.claimedOnce = true;
    }

    function _getPending(uint tokenId) private view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint earningSince = _claimedOrGenesis(tokenId);
        Location storage location = nfv.location;
        uint emission = nfv.onStages ? _getSubstage(location).emission : baseEarn;
        uint timeEarning = block.timestamp - earningSince;
        return timeEarning * (emission * EARN_SPEED_CONVERSION);
    }

    function _getPendingInterest(uint tokenId) private view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint timeSince = _claimedOrGenesis(tokenId);
        uint until = block.timestamp <= unlockEnd ? block.timestamp : unlockEnd;
        uint timeElapsed = until > timeSince ? until - timeSince : 0;
        return (nfv.locked * timeElapsed).feesOf(interest);
    }

    function _claimedOrGenesis(uint tokenId) private view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.claimedOnce ? nfv.lastClaim : genesis;
    }

    function _getSubstage(Location memory location) private view returns(Substage storage) {
        require(_isValidLocation(location), "Location is invalid.");
        return _stages[location.stage].substages[location.substage];
    }

    function _isValidLocation(Location memory location) private view returns(bool) {
        return location.stage < _stages.length && location.substage < _stages[location.stage].substages.length;
    }


    function _takePayment(address from, Payment storage payment) private {
        ERC20Token storage erc20Token = tokens[payment.token];
        uint total = payment.value;
        payment.token.transferFrom(from, address(this), total);

        uint attemptedBurn = total.feesOf(burnRatio);
        try Token(address(payment.token)).burn(attemptedBurn) {
            total -= attemptedBurn;
            erc20Token.burned += attemptedBurn;
        }
        catch {}

        payment.token.split(total, _payees);
        erc20Token.reflected += total;
    }

    //never needs to be used unless there is a bug.
    function withdraw(uint value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.transfer(msg.sender, value);
    }

    modifier onlyOwnerOf(uint tokenId) {
        require(OwnerOf.isOwnerOf(nfvs, msg.sender, tokenId), "Does not own NFT.");
        _;
    }

    modifier minted(uint tokenId) {
        try nfvs.ownerOf(tokenId) returns(address) {
        } catch {
            revert("Not minted.");
        }
        
        _;
    }

    function _mintTo(address addr, uint value) private {
        require(totalMinted + value <= mintCap, "Mint cap reached.");
        totalMinted += value;
        token.mintTo(addr, value);
    }


}


// File contracts/Game/extensions/IFarmWatcher.sol

// uint i MIT
pragma solidity 0.8.17;

interface IFarmWatcher {
    function deposited(address addr, uint amount) external;
    function withdrawn(address addr, uint amount) external;
    function claimed(address addr, uint amount) external;
}


// File contracts/Rewards/Vault.sol

//uint i UNLICENSED

pragma solidity 0.8.17;
contract Vault is AccessControl {
    bytes32 public VAULT_ROLE = keccak256("VAULT_ROLE");
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    function withdraw(IERC20 token, address to, uint amount) external onlyRole(VAULT_ROLE) {
        token.transfer(to, amount);
    }
}


// File contracts/Game/Farm.sol

// uint i MIT
pragma solidity 0.8.17;
contract Farm is Ownable {

    struct Account {
        uint shares;
        uint owed;
        uint debt;
    }

    uint private constant SHARE = 1e9;

    IERC20 public depositToken;
    IERC20 public rewardToken;
    Vault public vault;
    IFarmWatcher public farmWatcher;

    uint private _shareCount;
    uint private _perShare;
    uint private _debt;
    uint private _owed;

    uint public emissionRate;
    uint public startDate;
    uint private _emittingFrom;

    uint public totalDeposited;
    uint public totalWithdrawn;
    uint public totalClaimed;

    mapping(address => Account) private _accounts;

    constructor(IERC20 depositToken_, Vault vault_, IERC20 rewardToken_, IFarmWatcher farmWatcher_, uint emissionRate_, uint startDate_) {
        depositToken = depositToken_;
        vault = vault_;
        rewardToken = rewardToken_;
        emissionRate = emissionRate_;
        _setStartDate(startDate_);
        _setFarmWatcher(farmWatcher_);
    }

    function claimableOf(address addr) public view returns(uint) {
        return _claimableOf(_accounts[addr]);
    }

    function globalClaimable() external view returns(uint) {
        return (_pendingPerShare() * _shareCount) + _owed - _debt;
    }

    function currentlyDeposited() external view returns(uint) {
        return _shareCount * SHARE;
    }

    function deposit(uint amount) external {
        _update();
        Account storage account = _accounts[msg.sender];

        uint shares = amount / SHARE;
        uint debt = shares * _perShare;
        account.debt += debt;
        account.shares += shares;
        _shareCount += shares;

        totalDeposited += amount;
        _debt += debt;
        depositToken.transferFrom(msg.sender, address(this), amount);

        if(address(farmWatcher) != address(0)) farmWatcher.deposited(msg.sender, amount);
    }

    function withdraw(uint amount) external {
        _update();
        Account storage account = _accounts[msg.sender];

        uint shares = amount / SHARE;
        uint owed = shares * _perShare;
        account.owed += owed;
        account.shares -= shares;
        _shareCount -= shares;

        totalWithdrawn += amount;
        _owed += owed;
        depositToken.transfer(msg.sender, amount);

        if(address(farmWatcher) != address(0)) farmWatcher.withdrawn(msg.sender, amount);
    }

    function claim() external {
        Account storage account = _accounts[msg.sender];
        uint toClaim = _claimableOf(account);
        account.debt += toClaim;
        totalClaimed += toClaim;

        _debt += toClaim;
        vault.withdraw(rewardToken, msg.sender, toClaim);

        if(address(farmWatcher) != address(0)) farmWatcher.claimed(msg.sender, toClaim);
    }

    function setStartDate(uint newStartDate) external onlyOwner {
        require(!_isBeforeStartDate(), "Already started.");
        _setStartDate(newStartDate);
    }

    function setEmissionRate(uint newEmissionRate) external onlyOwner {
        _update();
        emissionRate = newEmissionRate;
    }

    function setFarmWatcher(IFarmWatcher newFarmWatcher) external onlyOwner {
        _setFarmWatcher(newFarmWatcher);
    }

    function _pendingPerShare() private view returns(uint) {
        if(_isBeforeStartDate()) return 0;
        return _perShare + (_shareCount > 0 ? ((block.timestamp - _emittingFrom) * emissionRate) / _shareCount : 0);
    }

    function _setFarmWatcher(IFarmWatcher newFarmWatcher) private {
        farmWatcher = newFarmWatcher;
    }

    function _isBeforeStartDate() private view returns(bool) {
        return block.timestamp < startDate;
    }

    function _setStartDate(uint newStartDate) private {
        startDate = newStartDate;
        _emittingFrom = newStartDate;
    }

    function _claimableOf(Account storage account) private view returns(uint) {
        return (account.shares * _pendingPerShare()) + account.owed - account.debt;
    }

    function _update() private {
        uint pendingPerShare = _pendingPerShare();
        if(pendingPerShare != _perShare) _perShare = pendingPerShare;
        _emittingFrom = block.timestamp;
    }

}


// File contracts/Game/FarmManager.sol

// uint i MIT
pragma solidity 0.8.17;
contract FarmManager is Ownable {

    struct FarmData {
        Farm implementation;
        IERC20 depositToken;
        IERC20 rewardToken;
        Vault vault;
        IFarmWatcher farmWatcher;
        uint emissionRate;
        uint startDate;
        uint totalDeposited;
        uint totalWithdrawn;
        uint totalClaimed;
        uint globalClaimable;
        uint currentlyDeposited;
    }

    Farm[] private _farms;

    function getFarmsData() external view returns(FarmData[] memory) {
        FarmData[] memory farmsData = new FarmData[](_farms.length);
        for(uint i = 0; i < _farms.length; i++) {
            farmsData[i] = FarmData({
                implementation: _farms[i],
                depositToken: _farms[i].depositToken(),
                rewardToken: _farms[i].rewardToken(),
                vault: _farms[i].vault(),
                farmWatcher: _farms[i].farmWatcher(),
                emissionRate: _farms[i].emissionRate(),
                startDate: _farms[i].startDate(),
                totalDeposited: _farms[i].totalDeposited(),
                totalWithdrawn: _farms[i].totalWithdrawn(),
                totalClaimed: _farms[i].totalClaimed(),
                globalClaimable: _farms[i].globalClaimable(),
                currentlyDeposited: _farms[i].currentlyDeposited()
            });
        }
        return farmsData;
    }

    function createFarm(IERC20 depositToken, Vault vault, IERC20 rewardToken, IFarmWatcher farmWatcher, uint emissionRate, uint startDate) external onlyOwner {
        Farm farm = new Farm(depositToken, vault, rewardToken, farmWatcher, emissionRate, startDate);
        _farms.push(farm);
        vault.grantRole(vault.VAULT_ROLE(), address(farm));
    }

    /*
    blocks all claims
    if you just want to pause a farm you should set the emission rate to 0 instead 
    so that people can still claim for a while before calling this function 
    */
    function removeFarm(uint i) external onlyOwner {
        _farms[i].vault().revokeRole(_farms[i].vault().VAULT_ROLE(), address(_farms[i]));
        _farms[i] = _farms[_farms.length - 1];
        _farms.pop();
    }

    function setFarmStartDate(uint i, uint newStartDate) external onlyOwner {
        _farms[i].setStartDate(newStartDate);
    }

    function setFarmEmissionRate(uint i, uint newEmissionRate) external onlyOwner {
        _farms[i].setEmissionRate(newEmissionRate);
    }

    function setFarmWatcher(uint i, IFarmWatcher newFarmWatcher) external onlyOwner {
        _farms[i].setFarmWatcher(newFarmWatcher);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// uint i MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/Nfts/Toolboxes.sol

// uint i MIT
pragma solidity 0.8.17;
contract Toolboxes is ERC1155PresetMinterPauser, RandomConsumer {

    using ERC20Payments for IERC20;

    struct Config {
        uint toolboxId;
        uint weighting;
    }

    struct Balance {
        uint toolboxId;
        uint balance;
    }

    struct StatsView {
        uint toolboxId;
        uint totalMinted;
    }

    ERC20Payments.Payee[] private _payees;
    IERC20 public token;
    Config[] private _configs;
    uint public price;
    mapping(uint => uint) private _stats;
    mapping(address => uint[]) private _history;
    
    //input to chainlink intermediary
    uint[] private _options;
    mapping(uint => address) private _requests;

    //ALWAYS HAVE PAYEES BECAUSE IF THERE ARE NONE THEN THEY WILL GET THE SHIT FOR FREE
    constructor(string memory uri, IRandom random, IERC20 token_, ERC20Payments.Payee[] memory payees, uint price_, Config[] memory configs) ERC1155PresetMinterPauser(uri) RandomConsumer(random)  {
        token = token_;
        _setPayees(payees);
        _setPrice(price_);
        _setConfigs(configs);
    }

    function getStats() external view returns(StatsView[] memory history) {
        history = new StatsView[](_configs.length);
        for(uint i; i < history.length; i ++) {
            history[i] = StatsView(_configs[i].toolboxId, _stats[_configs[i].toolboxId]);
        }
    }

    function getHistory(address addr, uint numberOf) external view returns(uint[] memory history) {
        uint[] storage _history_ = _history[addr];
        numberOf = numberOf <= _history_.length ? numberOf : _history_.length;
        history = new uint[](numberOf);
        uint start = _history_.length - numberOf;
        for(uint i = start; i < _history_.length; i ++) {
            history[i - start] = _history_[i];
        }
    }

    function purchase(uint numberOf) whenNotPaused external {
        for(uint i; i < numberOf; i ++) {
            _purchase();
        }
    }

    function getBalances(address addr) external view returns(Balance[] memory balances) {
        balances = new Balance[](_configs.length);
        for(uint i; i < balances.length; i ++) {
            balances[i] = Balance(_configs[i].toolboxId, balanceOf(addr, _configs[i].toolboxId));
        }
    }

    function _purchase() internal {
        token.splitFrom(msg.sender, price, _payees);
        _requests[_requestRandom(_options)] = msg.sender;
    }

    function setPrice(uint newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPrice(newPrice);
    }

    function setPayees(ERC20Payments.Payee[] memory payees) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPayees(payees);
    }

    function getPayees() external view returns(ERC20Payments.Payee[] memory) {return _payees;}

    function setUri(string memory newUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newUri);
    }

    function setConfigs(Config[] calldata configs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setConfigs(configs);
    }
    function _setConfigs(Config[] memory configs) private {
        delete _configs;
        delete _options;
        for(uint i; i < configs.length; i ++) {
            Config memory config = configs[i];
            _configs.push(config);
            _options.push(config.weighting);
        }
    }

    function getConfigs() external view returns(Config[] memory) {return _configs;}

    function _setPayees(ERC20Payments.Payee[] memory payees) private {
        delete _payees;
        for(uint i; i < payees.length; i ++) _payees.push(payees[i]);
    }

    function _setPrice(uint newPrice) private {
        price = newPrice;
    }

    function _fulfillRandom(uint requestId, uint result) internal override {
        address from = _requests[requestId];
        Config storage config = _configs[result];
        _stats[config.toolboxId] ++;
        _history[from].push(config.toolboxId);
        uint toolboxId = config.toolboxId;
        _mint(from, toolboxId, 1, "");
    }



}


// File contracts/Game/Mods.sol

// uint i MIT
pragma solidity 0.8.17;
contract Mods is Nft, RandomConsumer {
    using OwnerOf for IERC721;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    struct PerInput {
        uint toolboxId;
        uint per;
    }
    struct Mod {
        uint attributeId;
        uint value;
    }
    struct Option {
        uint attributeId;
        uint weighting;
    }
    struct Request {
        uint value;
        address receiver;
    }
    struct RequestInput {
        uint toolboxId;
        uint numberOf;
    }
    struct AttributeConfig {
        string name;
        uint maxPerCar;
    }
    struct RedeemInput {
        uint tokenId;
        uint modId;
    }
    struct AttributeCarView {
        string attribute;
        uint value;
    }
    mapping(address => Mod[]) private _history;
    Option[] private _options;
    uint[] private _weightings;

    Toolboxes public toolboxes;
     
    mapping(uint => uint) public perToolbox;
    mapping(uint => Request) private _requests;
    mapping(uint => Mod) private _mods;
    mapping(uint => mapping(string => uint)) private _values;
    AttributeConfig[] private _attributeConfigs;
    bytes32 public constant MODS_ROLE = keccak256("MODS_ROLE");
    IERC721 public nfvs;

    Counters.Counter private _nextTokenId;

    constructor(Toolboxes toolboxes_, IRandom random_, string memory name, string memory symbol, string memory uri, Option[] memory options, PerInput[] memory perInputs, AttributeConfig[] memory attributeConfigs, IERC721 nfvs_) ERC721(name,symbol) Nft(uri) RandomConsumer(random_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setOptions(options);
        for(uint i; i < perInputs.length; i ++) {
            _setPerToolbox(perInputs[i]);
        }
        toolboxes = toolboxes_;
        _setAttributeConfigs(attributeConfigs);
        nfvs = nfvs_;
    }

    function getHistory(address from, uint numberOf) external view returns(Mod[] memory history) {
        Mod[] storage history_ = _history[from];
        numberOf = numberOf <= history_.length ? numberOf : history_.length;
        history = new Mod[](numberOf);
        uint start = history_.length - numberOf;
        for(uint i = start; i < history_.length; i ++) {
            history[i - start] = history_[i];
        }

    }

    function getAttributeConfigs() external view returns(AttributeConfig[] memory) {
        return _attributeConfigs;
    }

    function getAttributeKeys() external view returns(string[] memory keys) {
        keys = new string[](_attributeConfigs.length);
        for(uint i; i < keys.length; i ++) {
            keys[i] = _attributeConfigs[i].name;
        }
    }

    function setAttributeConfigs(AttributeConfig[] calldata attributeConfigs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setAttributeConfigs(attributeConfigs);
    }

    function setPerToolbox(PerInput memory perInput) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPerToolbox(perInput);
    }

    function getMod(uint modId) external view returns(Mod memory) {
        require(_exists(modId), "Mod does not exist");
        return _mods[modId];
    }

    function burnToolboxes(RequestInput[] calldata requestInputs) external {
        for(uint i; i < requestInputs.length; i ++) {
            RequestInput calldata input = requestInputs[i];
            toolboxes.burn(msg.sender, input.toolboxId, input.numberOf);
            for(uint j; j < input.numberOf; j ++) {
                _requests[random.requestRandom(_weightings)] = Request(perToolbox[input.toolboxId], msg.sender);
            }
        }
    }

    function redeemMods(RedeemInput[] calldata redeemInputs) external {
        for(uint i; i < redeemInputs.length; i ++) {
            require(ownerOf(redeemInputs[i].modId) == msg.sender, "You don't own this mod.");
            require(nfvs.isOwnerOf(msg.sender, redeemInputs[i].tokenId));
            _burn(redeemInputs[i].modId);
            Mod storage mod = _mods[redeemInputs[i].modId];
            uint current = _values[redeemInputs[i].tokenId][_attributeConfigs[mod.attributeId].name];
            uint theoretical = current + mod.value;
            uint n = theoretical <= _attributeConfigs[mod.attributeId].maxPerCar ? theoretical : _attributeConfigs[mod.attributeId].maxPerCar;
            _values[redeemInputs[i].tokenId][_attributeConfigs[mod.attributeId].name] = n;
        }
    }

    function setExp(uint256 tokenId, string memory attribute, uint256 value) external onlyRole(MODS_ROLE) {
        _values[tokenId][attribute] = value;
    }

    function getExp(uint tokenId, string memory attribute) external view returns(uint) {
        return _values[tokenId][attribute];
    }

    function getAttributes(uint tokenId) external view returns(AttributeCarView[] memory result) {
        result = new AttributeCarView[](_attributeConfigs.length);
        for(uint i; i < result.length; i ++) {
            result[i] = AttributeCarView(_attributeConfigs[i].name, _values[tokenId][_attributeConfigs[i].name]);
        }
    }

    function _setAttributeConfigs(AttributeConfig[] memory attributeConfigs) private {
        delete _attributeConfigs;
        for(uint i; i < attributeConfigs.length; i ++) {
            _attributeConfigs.push(attributeConfigs[i]);
        }
    }

    function _fulfillRandom(uint requestId, uint result) internal override {
        uint tokenId = _nextTokenId.current();
        _nextTokenId.increment();

        Request storage request = _requests[requestId];
        _mint(request.receiver, tokenId);

        _mods[tokenId] = Mod(_options[result].attributeId, request.value);
        _history[request.receiver].push(Mod(_options[result].attributeId, request.value));
    }

    function _setPerToolbox(PerInput memory perInput) private {
        perToolbox[perInput.toolboxId] = perInput.per;
    }

    function _setOptions(Option[] memory options) private {
        delete _options;
        delete _weightings;
        for(uint i; i < options.length; i ++) {
            _options.push(options[i]);
            _weightings.push(options[i].weighting);
        }
    }

}


// File contracts/IGasLeech.sol

//uint i Unlicensed
pragma solidity 0.8.17;

interface IGasLeech {

    function leech() external;

}


// File contracts/GasLeecher.sol

//uint i Unlicensed
pragma solidity 0.8.17;
contract GasLeecher {
    IGasLeech public gasLeech;
    constructor(IGasLeech gasLeech_) {
        gasLeech = gasLeech_;
    }
    function _leech() internal {
        gasLeech.leech();
    }
}


// File contracts/Legacy/ILambo.sol

//uint i Unlicense
pragma solidity 0.8.17;

interface ILambo {    
    event ExperienceGranted(
        uint256 tokenId,
        string attribute,
        uint256 expAdded,
        uint256 totalExp
    );

    event NewAttributeCreated(
        string attribute,
        uint256 blockNumber,
        uint256 blockTime
    );

    event RaceWon(
        uint256 tokenId,
        uint256 raceId
    );

    event PreSaleStarted(
        uint256 blockNumber,
        uint256 blockTime
    );

    event PublicSaleStarted(
        uint256 blockNumber,
        uint256 blockTime
    );

    struct StatisticView {
        string statistic;
        uint256 value;
    }
}


// File contracts/Legacy/Lambo.sol

// uint i MIT
pragma solidity 0.8.17;
// import "hardhat/console.sol";

contract Lambos is ERC721, ERC721Enumerable, Pausable, AccessControl, ILambo {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant RACE_MANAGER_ROLE = keccak256("RACE_MANAGER_ROLE");
    Counters.Counter private tokenIdCounter;
    string private baseUri;

    bool public isPreSale;

    struct PreSaleData {
        bool isListed;
        uint8 count;
    }
    mapping (address => PreSaleData) private presaleList;

    bool public isPublicSale;
    uint256 constant public MAX_LAMBOS = 10000;
    string[] private attributeKeys;
    mapping(uint256 => mapping(string => uint256)) private statistics; // token id => attribute name => counter
    mapping(uint256 => bytes) private licensePlates;

    error SaleNotStartedYet();
    error CannotSetPublicSaleBeforePreSale();
    error LamboDoesNotExist();
    error MoreThanMintAllowance();
    error AddressNotOnPreSaleList();
    error MaxPresaleMintsHit();
    error MaxLambosAlreadyExist();
    error InsufficientFundsSent();
    error AttributeAlreadyMaxLevel(uint256 tokenId, string attribute);
    error BadLicensePlate(uint256 tokenId, string newPlate);

    constructor() ERC721("WenLambo", "LAMBO") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(RACE_MANAGER_ROLE, msg.sender);

        baseUri = "https://todo.wen.lambo/";

        // attribute/statistics information
        attributeKeys.push("power");
        attributeKeys.push("handling");
        attributeKeys.push("boost");
        attributeKeys.push("tires");

        // sales data
        isPreSale = false;
        isPublicSale = false;
    }

    // minting

    function mint(uint256 _amount) public payable {
        // revert checks
        if (!isPreSale && !isPublicSale) revert SaleNotStartedYet();
        if (totalSupply() + _amount > MAX_LAMBOS) revert MaxLambosAlreadyExist();
        if (_amount > 3) revert MoreThanMintAllowance();
        if (msg.value < (getMintPrice() * _amount)) revert InsufficientFundsSent();

        // presale rules only
        if (isPreSale && !isPublicSale) {
            if (!presaleList[msg.sender].isListed) revert AddressNotOnPreSaleList();
            if (presaleList[msg.sender].count + uint8(_amount) > 3) revert MaxPresaleMintsHit();
            presaleList[msg.sender].count += uint8(_amount);
        }

        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenId);

            // set our token attributes here
            _setBaseStatistics(_tokenId);
        }
    }

    function ownerMint(address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (totalSupply() + _amount > MAX_LAMBOS) revert MaxLambosAlreadyExist();

        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(_to, _tokenId);

            // set our token attributes here
            _setBaseStatistics(_tokenId);
        }
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // attributes

    function _setBaseStatistics(uint256 _tokenId) internal {
        statistics[_tokenId]["power"] = 0;
        statistics[_tokenId]["handling"] = 0;
        statistics[_tokenId]["boost"] = 0;
        statistics[_tokenId]["tires"] = 0;
        // added in a later phase?
        //statistics[_tokenId]["armour"] = 0;
        //statistics[_tokenId]["weapons"] = 0;
        statistics[_tokenId]["xp"] = 0;
        statistics[_tokenId]["racesTotal"] = 0;
        statistics[_tokenId]["racesWon"] = 0;
    }

    function getAttributes(uint256 _tokenId) public view returns (StatisticView[] memory) {
        if (_tokenId >= totalSupply()) revert LamboDoesNotExist();
        uint256 _statisticsCount = attributeKeys.length;
        StatisticView[] memory _stats = new StatisticView[](_statisticsCount);
        
        for (uint256 i = 0; i < _statisticsCount; i++) {
            uint256 _value = statistics[_tokenId][attributeKeys[i]];

            _stats[i] = StatisticView({
                statistic: attributeKeys[i],
                value: _value
            });
        }

        return _stats;
    }

    function addExp(uint256 _tokenId, string memory _attribute, uint256 _toAdd) external onlyRole(UPGRADER_ROLE) {
        statistics[_tokenId][_attribute] += _toAdd;

        emit ExperienceGranted(_tokenId, _attribute, _toAdd, statistics[_tokenId][_attribute]);
    }

    function finishedRace(uint256 _tokenId, uint256 _raceId, bool _won) external onlyRole(RACE_MANAGER_ROLE) {
        statistics[_tokenId]["racesTotal"] += 1;

        if (_won) {
            statistics[_tokenId]["racesWon"] += 1;
        }

        emit RaceWon(_tokenId, _raceId);
    }

    function getAttributeKeys() external view returns (string[] memory) {
        return attributeKeys;
    }

    function addNewAttribute(string memory _attribute) external onlyRole(UPGRADER_ROLE) {
        attributeKeys.push(_attribute);

        emit NewAttributeCreated(_attribute, block.number, block.timestamp);
    }

    function getLicensePlate(uint256 _tokenId) external view returns (string memory) {
        if (_tokenId > totalSupply()) {
            return "";
        }

        return string(licensePlates[_tokenId]);
    }


    function setLicensePlate(uint256 _tokenId, string memory _newPlate) external {
        if (!_isStringValid(_newPlate)) revert BadLicensePlate(_tokenId, _newPlate);

        licensePlates[_tokenId] = bytes(_newPlate);
    }

    // pausable and sale states

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function startPreSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPreSale = true;

        emit PreSaleStarted(block.number, block.timestamp);
    }

    function startPublicSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!isPreSale) revert CannotSetPublicSaleBeforePreSale();
        isPreSale = false;
        isPublicSale = true;

        emit PublicSaleStarted(block.number, block.timestamp);
    }

    function hasPresalesLeft(address _addr) external view returns (bool, uint256) {
        if (presaleList[_addr].isListed) {
            uint256 _mintCount = presaleList[_addr].count;
            return (
                _mintCount < 3,
                3 - _mintCount
            );
        } else {
            return (
                false,
                0
            );
        }
    }

    function addToPresaleList(address _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleList[_addr].count = 0;
        presaleList[_addr].isListed = true;
    }

    function addManyToPresaleList(address[] memory _addrs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _addrs.length; i++) {
            address _addr = _addrs[i];
            presaleList[_addr].count = 0;
            presaleList[_addr].isListed = true;
        }
    }

    function getMintPrice() public view returns (uint256) {
        if (isPreSale) {
            return 500 * 1e18; // 500 ONE
        } else if (!isPreSale && isPublicSale) {
            return 750 * 1e18; // 750 ONE
        } else {
            return 0;
        }
    }

    function setBaseURI(string memory _newUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseUri = _newUri;
    }

    // util
    function _isStringValid(string memory str) private pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 3 || b.length > 10) 
            return false;

        for(uint256 i; i < b.length; i++){
            bytes1 char = b[i];

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) // (space)
            )
                return false;
        }

        return true;
    }

    // hooks / overrides

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist yet");
        return string(abi.encodePacked(baseUri, tokenId.toString()));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint a)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, a);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // currency stuff
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint _balance = address(this).balance;
        payable(msg.sender).transfer(_balance);
    }

    function balance() public view returns (uint256) {
      return address(this).balance;
    }
}


// File contracts/Legacy/usercontract.sol

// uint i MIT
pragma solidity 0.8.17;
abstract contract NFT {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
}

contract LamboAvatars {
    using Counters for Counters.Counter;
    using Strings for uint256;

    NFT lamboContract;

    struct AvatarStruct {
        address user;
        string userName;
        uint256 lamboId;
        bool lamboSet;
        bool userExists;
    }

    Counters.Counter public userCounter;
    mapping(address => AvatarStruct) private avatar;
    mapping(uint256 => address) private avatarMap;

    error BadName(string userName);

    constructor(address _lamboAddress) {
        lamboContract = NFT(_lamboAddress);
    }

    function selectAvatar(uint256 _id) external {
        require(avatar[msg.sender].userExists == true, 'This user does not exist yet.');
        require(lamboContract.ownerOf(_id) == msg.sender, 'This is not your Lambo.');
        require(avatar[msg.sender].lamboId != _id, 'You already use this Lambo as avatar.');

        avatar[msg.sender].lamboId = _id;
        avatar[msg.sender].lamboSet = true;
        avatar[msg.sender].user = msg.sender;
    }

    function setUser(string memory _userName) external {
        require(!avatar[msg.sender].userExists, 'This user already exists.');
        if (!_isStringValid(_userName)) revert BadName(_userName);

        avatar[msg.sender].userName = _userName;
        avatar[msg.sender].user = msg.sender;
        avatar[msg.sender].userExists = true;

        userCounter.increment();
    }

    function removeUser() public {
        delete avatar[msg.sender];
        userCounter.decrement();
    }

    // util
    function _isStringValid(string memory str) private pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 3 || b.length > 10) 
            return false;

        for(uint256 i; i < b.length; i++){
            bytes1 char = b[i];

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) // (space)
            )
                return false;
        }

        return true;
    }

    function getAvatar(address _address) public view returns (uint256 lamboId, bool lamboSet) {
        if (lamboContract.ownerOf(avatar[_address].lamboId) == _address && avatar[_address].user == _address) {
            return (avatar[_address].lamboId, avatar[_address].lamboSet);
        } else {
            return (99999, avatar[_address].lamboSet);
        }
    }

    function getName(address _address) public view returns (string memory userName) {
        if (avatar[_address].user == _address) {
            return (avatar[_address].userName);
        } else {
            return ('');
        }
    }
}


// File contracts/Nfts/extensions/Bridgeable.sol

// uint i MIT
pragma solidity 0.8.17;
interface IBridgeable {
    function mintTokenId(address to, uint tokenId) external;
    function burnTokenId(uint tokenId) external;
}

abstract contract Bridgeable is IBridgeable, ERC165 {
    function supportsInterface(bytes4 interfaceId) public virtual override view returns(bool) {
        return interfaceId == type(IBridgeable).interfaceId || super.supportsInterface(interfaceId);
    }
}


// File contracts/Migrating/Bridge.sol

// uint i MIT
pragma solidity 0.8.17;
contract Bridge is AccessControl, ERC721Holder, Pausable {

    using Counters for Counters.Counter;

    event RequestMade(bytes32 id, Bridging bridging);
    event BridgeFulfilled(bytes32 externalId);

    struct BridgeInfo {
        bool exists;
        Bridging bridging;
    }

    struct Bridging {
        Nft nft;
        Destination dest;
    }

    struct Nft {
        IERC721 imp;
        uint tokenId;
    }

    struct Destination {
        string chain;
        address receiver;
    }

    struct DestRules {
        uint fee;
        bool permitted;
    }

    bytes32 public ESCROW_ROLE = keccak256("ESCROW_ROLE");

    string public chain;

    Counters.Counter private _nextRequestNonce;

    mapping(address => bytes32[]) public personalHistory;
    mapping(IERC721 => mapping(uint => bytes32[])) public nftHistory;
    bytes32[] public history;
    mapping(bytes32 => BridgeInfo) private _bridgings;
    mapping(bytes32 => bool) public externalCompletions;
    mapping(string => DestRules) public destRules;

    constructor(string memory chain_) {
        chain = chain_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setDestRules(string calldata chain_, DestRules calldata rules) external onlyRole(DEFAULT_ADMIN_ROLE) {destRules[chain_] = rules;}

    function personalHistoryLength(address addr) external view returns(uint) {return personalHistory[addr].length;}
    function nftHistoryLength(Nft calldata nft) external view returns(uint) {return _historyOfNft(nft).length;}
    function historyLength() external view returns(uint) {return history.length;}
    function getBridging(bytes32 id) external view returns(Bridging memory) {
        BridgeInfo storage bridgeInfo = _bridgings[id];
        require(bridgeInfo.exists, "Does not exist.");
        return bridgeInfo.bridging;
    }

    function queue(Bridging[] calldata bridgings) external payable {
        int paymentMade = int(msg.value);
        for(uint i; i < bridgings.length; i ++) {
            Bridging calldata bridging = bridgings[i];
            DestRules storage rules = destRules[bridging.dest.chain];
            require(rules.permitted, "Cannot bridge to this chain.");
            paymentMade -= int(rules.fee);
            Nft calldata nft = bridging.nft;

            (bool yes, IBridgeable bImp) = _isBridgeable(nft.imp);
            if(yes) {
                bImp.burnTokenId(nft.tokenId);
            } else nft.imp.transferFrom(msg.sender, address(this), nft.tokenId);

            bytes32 id = _getNewId();

            _bridgings[id] = BridgeInfo({
                exists: true,
                bridging: bridging
            });

            personalHistory[msg.sender].push(id);
            _historyOfNft(nft).push(id);
            history.push(id);

            emit RequestMade(id, bridging);
        }
        require(paymentMade == 0, "Incorrect payment made.");
    }

    function release(bytes32 externalId, Nft calldata nft, address to) external onlyRole(ESCROW_ROLE) {
        require(!externalCompletions[externalId], "Already fulfilled.");

        (bool yes, IBridgeable bImp) = _isBridgeable(nft.imp);
        if(yes) {
            bImp.mintTokenId(to, nft.tokenId);
        } else nft.imp.transferFrom(address(this), to, nft.tokenId);

        externalCompletions[externalId] = true;
        emit BridgeFulfilled(externalId);
    }

    function _isBridgeable(IERC721 imp) private view returns(bool, IBridgeable) {
        address addr = address(imp);
        return (IERC165(addr).supportsInterface(type(IBridgeable).interfaceId), IBridgeable(addr));
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool succ,) = msg.sender.call{value: address(this).balance}("");
        require(succ);
    }

    function _getNewId() private returns(bytes32 id) {
        uint nonce = _nextRequestNonce.current();
        _nextRequestNonce.increment();
        return sha256(abi.encode(chain, nonce));
    }

    function _historyOfNft(Nft memory nft) private view returns(bytes32[] storage) {return nftHistory[nft.imp][nft.tokenId];}

}


// File contracts/Migrating/ClaimSlash.sol

// uint i MIT
pragma solidity 0.8.17;
contract ClaimSlash is AccessControl {

    bytes32 public SLASH_ROLE = keccak256("SLASH_ROLE");

    uint public checkPoint = 0;

    Earn public target;

    uint public numerator;
    uint public denominator;
    constructor(Earn target_, uint numerator_, uint denominator_) {
        numerator = numerator_;
        denominator = denominator_;
        target = target_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SLASH_ROLE, msg.sender);
    }
    function slash(uint numberOf) external onlyRole(SLASH_ROLE) {
        uint end = checkPoint + numberOf;
        for(uint i = checkPoint; i < end; i ++) {
            uint tokenId = i;
            (,,,uint pendingClaim,,,,,,) = target.nfvInfo(tokenId);
            uint toSlash = (pendingClaim * numerator) / denominator;
            target.removeFromClaimable(tokenId, toSlash);      
        }
        checkPoint += numberOf;
    }
}


// File contracts/Migrating/EarnMigrator.sol

// uint i MIT
pragma solidity 0.8.17;
contract EarnMigrator {
    Earn public source;
    Earn public dest;
    uint public divisor;

    mapping(uint => bool) public done;

    constructor(Earn source_, Earn dest_, uint divisor_) {
        divisor = divisor_;
        source = source_;
        dest = dest_;
    }

    function migrateList(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            migrate(tokenIds[i]);
        }
    }

    function migrateRange(uint start, uint end) external {
        for(uint i; i < end-start; i ++) {
            migrate(i + start);
        }
    }

    function migrate(uint tokenId) public {
        require(!done[tokenId], "Already done.");
        done[tokenId] = true;
        uint unlockedClaimable = source.getUnlockedClaimable(tokenId) / divisor;
        uint locked = source.getLocked(tokenId) / divisor;
        uint interest = source.getInterest(tokenId) / divisor;
        if(source.isInLocation(tokenId)) {
            dest.setLocation(tokenId, source.getLocation(tokenId));
        }
        dest.addToClaimable(tokenId, unlockedClaimable);
        dest.addToLocked(tokenId, locked);
        dest.addToInterest(tokenId, interest);
    }
}


// File contracts/Migrating/EarnMigratorForLegacy.sol

// uint i MIT
pragma solidity 0.8.17;
contract EarnMigratorForLegacy {
    using Fees for uint;
    EarnOld public source;
    Earn public dest;
    uint public divisor;
    uint public CUTOFF;

    mapping(uint => bool) public done;

    constructor(EarnOld source_, Earn dest_, uint divisor_, uint CUTOFF_) {
        divisor = divisor_;
        source = source_;
        dest = dest_;
        CUTOFF = CUTOFF_;
        (uint parts,uint outOf) = source.lockRatio();
        _lock = Fees.Fee(parts,outOf);
    }

    function doneMultiple(uint[] calldata tokenIds) external view returns(bool[] memory res) {
        res = new bool[](tokenIds.length);
        for(uint i; i < tokenIds.length; i ++) {
            res[i] = done[tokenIds[i]];
        }
    }

    function migrateList(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            migrate(tokenIds[i]);
        }
    }

    function migrateRange(uint start, uint end) external {
        for(uint i; i < end-start; i ++) {
            migrate(i + start);
        }
    }

    Fees.Fee private _lock;

    function migrate(uint tokenId) public {
        require(!done[tokenId], "Cannot migrate twice.");
        require(tokenId <= CUTOFF, "Cannot migrate mints after cutoff.");
        done[tokenId] = true;

        Earn.NfvView memory destData = dest.getInformation(tokenId);
        dest.removeFromLocked(tokenId, destData.locked + destData.lockedClaimable);
        dest.removeFromClaimable(tokenId, destData.unlockedClaimable);
        dest.removeFromInterest(tokenId, destData.interestable);


        EarnOld.NfvView memory data = source.getInformation(tokenId);

        uint pendingClaim = data.claimable;
        uint pendingLocked = pendingClaim.feesOf(_lock);


        uint unlockedClaimable = (pendingClaim - pendingLocked) / divisor;
        uint locked = (data.locked + pendingLocked) / divisor;
        uint interest = data.interestable / divisor;
        if(source.isInLocation(tokenId)) {
            EarnOld.Location memory location = source.getLocation(tokenId);
            dest.setLocation(tokenId, Earn.Location(location.stage, location.substage));
        }
        dest.addToClaimable(tokenId, unlockedClaimable);
        dest.addToLocked(tokenId, locked);
        dest.addToInterest(tokenId, interest);
    }
}


// File contracts/Migrating/GarageMigrator.sol

// uint i MIT
pragma solidity 0.8.17;
contract GarageMigrator is AccessControl {

    bytes32 public MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");

    uint public checkPoint = 0;

    Earn public source;
    Earn public target;
    constructor(Earn source_, Earn target_) {
        source = source_;
        target = target_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MIGRATOR_ROLE, msg.sender);
    }
    function migrate(uint numberOf) external onlyRole(MIGRATOR_ROLE) {
        uint end = checkPoint + numberOf;
        for(uint i = checkPoint; i < end; i ++) {
            uint tokenId = i;

            Earn.NfvView memory nfv = source.getInformation(tokenId);
            if(nfv.onStages) {
                target.setLocation(tokenId, nfv.location);
            }
            
            target.addToClaimable(tokenId, nfv.claimable);
            target.addToLocked(tokenId, nfv.locked);
            target.addToInterest(tokenId, nfv.interestable);
            
        }
        checkPoint += numberOf;
    }
}


// File contracts/Migrating/HVILLEMigrator.sol

// uint i MIT
pragma solidity 0.8.17;
contract Migrator is AccessControl {
    bytes32 public MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");

    mapping(address => bool) public migrated;

    Token public token;

    Migrator[] links;

    constructor(Token token_, Migrator[] memory links_) {
        token = token_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        links = links_;
    }

    struct MigrateInput {
        address addr;
        uint amount;
    }

    function migrate(MigrateInput memory input) public onlyRole(MIGRATOR_ROLE) {
        if(migrated[input.addr] || _check(input.addr)) return;
        migrated[input.addr] = true;
        token.mintTo(input.addr, input.amount);
    }

    function _check(address addr) private view returns(bool) {
        for(uint i; i < links.length; i ++) {
            if(links[i].migrated(addr)) return true;
        }
        return false;
    }

    function migrateMultiple(MigrateInput[] calldata inputs) external {
        for(uint i; i < inputs.length; i ++) migrate(inputs[i]);
    }

}


// File contracts/Migrating/LockedBoost.sol

// uint i MIT
pragma solidity 0.8.17;
contract LockedBoost is AccessControl {

    bytes32 public SLASH_ROLE = keccak256("SLASH_ROLE");

    uint public checkPoint = 0;

    Earn public target;

    uint public numerator;
    uint public denominator;
    constructor(Earn target_, uint numerator_, uint denominator_) {
        numerator = numerator_;
        denominator = denominator_;
        target = target_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SLASH_ROLE, msg.sender);
    }
    function slash(uint numberOf) external onlyRole(SLASH_ROLE) {
        uint end = checkPoint + numberOf;
        for(uint i = checkPoint; i < end; i ++) {
            uint tokenId = i;
            (,,,uint pendingClaim,,,,,,) = target.nfvInfo(tokenId);
                uint toAdd = (pendingClaim * denominator) / numerator;
                target.addToLocked(tokenId, toAdd);    
            

        }
        checkPoint += numberOf;
    }
}


// File contracts/Migrating/TokenMerge.sol

//uint i Unlicensed
pragma solidity 0.8.17;
contract TokenMerge {
    uint public constant ONE_TOKEN = 1e18; 
    struct Option {
        Token token;
        uint perToken;
    }
    Token public newToken;
    Option[] private _options;
    constructor(Token newToken_, Option[] memory items) {
        newToken = newToken_;
        for(uint i; i < items.length; i ++) {
            _options.push(items[i]);
        }
    }
    function getOptions() external view returns(Option[] memory items) {
        return _options;
    }
    //dont convert to wei the token is assumed to be 18 decimals in the contract and only whole numbers can be input
    function merge(uint numberOfTokens, uint optionId) external {
        Option storage option = _options[optionId];
        uint toMint = _convert(_quote(numberOfTokens, option));
        uint toBurn = _convert(numberOfTokens); 
        option.token.burnFrom(msg.sender, toBurn);
        newToken.mintTo(msg.sender, toMint);
    }
    function quote(uint numberOfTokens, uint optionId) external view returns(uint) {
        return _quote(numberOfTokens, _options[optionId]);
    }
    function _quote(uint numberOfTokens, Option storage option) private view returns(uint) {
        return (numberOfTokens / option.perToken);
    }
    function _convert(uint value) private pure returns(uint) {
        return value * ONE_TOKEN;
    }

}


// File @thetrees1529/solutils/contracts/payments/[email protected]

//uint i UNLICENSED
pragma solidity ^0.8.0;
contract Payments {
    struct Payee {
        address addr;
        uint weighting;
    }
    event PayeesSet(Payee[] payees);
    event PayeesDeleted();
    Payee[] private _payees;
    uint private _totalWeighting;
    function getPayees() external virtual view returns(Payee[] memory) {
        return _payees;
    }
    function _setPayees(Payee[] memory payees) internal virtual {
        if(_payees.length > 0) _deletePayees();
        for(uint i; i < payees.length; i++) {
            Payee memory payee = payees[i];
            require(payee.weighting > 0, "All payees must have a weighting.");
            require(payee.addr != address(0), "Payee cannot be the zero address.");
            _totalWeighting += payee.weighting;
            _payees.push(payee);
        }
        emit PayeesSet(payees);
    }
    function _tryMakePayment(uint value) internal virtual {
        for(uint i; i < _payees.length; i ++) {
            Payee storage payee = _payees[i];
            uint payment = (payee.weighting * value) / _totalWeighting;
            (bool succ,) = payee.addr.call{value: payment}("");
            require(succ, "Issue with one of the payees.");
        }
    }
    function _makePayment(uint value) internal virtual {
        require(_payees.length > 0, "No payees set up.");
        _tryMakePayment(value);
    }
    function _deletePayees() internal virtual {
        delete _totalWeighting;
        delete _payees;
        emit PayeesDeleted();
    }
}


// File contracts/Nfvs/NfvBase.sol

// uint i MIT
pragma solidity 0.8.17;
// import "hardhat/console.sol";
abstract contract NfvBase is ERC721Royalty, Nft, ERC1155Holder, Pausable {

    struct Rent {
        bool inProgress;
        address owner;
        uint endsAt;
    }

    using Counters for Counters.Counter;

    bytes32 public constant RENTER_ROLE = keccak256("RENTER_ROLE");
    bytes32 public constant EQUIPPER_ROLE = keccak256("EQUIPPER_ROLE");
    Counters.Counter private tokenIdCounter;
    string private baseUri;

    string[] private attributeKeys;
    mapping(uint => Rent) private _rents;
    mapping(address => bool) public blacklisted;

    constructor() {
        
    }

    function setRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setBlacklistStatus(address addr, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklisted[addr] = status;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    //renting
    function rentTo(uint tokenId, address to, uint period) external onlyRole(RENTER_ROLE) {
        Rent storage rent = _rents[tokenId];
        require(!rent.inProgress, "Currently rented.");
        address owner = ownerOf(tokenId);
        rent.owner = owner;
        rent.endsAt = block.timestamp + period;
        _transfer(owner, to, tokenId);
        rent.inProgress = true;
    }

    function cancelRent(uint tokenId) external onlyRole(RENTER_ROLE) {
        Rent storage rent = _rents[tokenId];
        require(rent.inProgress, "Not under rent.");
        rent.endsAt = block.timestamp;
    }

    function isUnderRent(uint tokenId) external view returns(bool) {
        return _rents[tokenId].inProgress;
    }

    function rentInfo(uint tokenId) external view returns(address originalOwner, uint endsAt) {
        Rent storage rent = _rents[tokenId];
        require(rent.inProgress, "Not rented currently.");
        return (rent.owner, rent.endsAt);
    }

    function returnRented(uint tokenId) external onlyRole(RENTER_ROLE) {
        Rent storage rent = _rents[tokenId];
        require(rent.inProgress, "Rent not in progress.");
        require(block.timestamp >= rent.endsAt, "Rent period not over.");
        rent.inProgress = false;
        _transfer(ownerOf(tokenId), rent.owner, tokenId);
    }


    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }


    // hooks / overrides

    function _baseURI() internal virtual override(ERC721, Nft) view returns(string memory) {
        return super._baseURI();
    }

    function _transfer(address from, address to, uint tokenId) internal virtual whenNotPaused override {
        super._transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint batchSize)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
    {
        require(!_rents[tokenId].inProgress, "Currently rented.");
        require(!blacklisted[from] && !blacklisted[to], "Blacklisted.");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Royalty, ERC1155Receiver, Nft)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint tokenId) internal virtual override(ERC721, ERC721Royalty) {
        return super._burn(tokenId);
    }

}


// File contracts/Nfvs/Nfvs.sol

// uint i MIT
pragma solidity 0.8.17;
contract Nfvs is NfvBase {

    using Counters for Counters.Counter;

    bytes32 public MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 constant public MAX_LAMBOS = 10000;
    Counters.Counter private tokenIdCounter;

    constructor(string memory name, string memory symbol, string memory uri) ERC721(name,symbol) Nft( uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //mintTo preferred but oh well
    function mint(address to, uint numberOf) external onlyRole(MINTER_ROLE) {
        for(uint i; i < numberOf; i++) _mintOne(to);
    }

    function _mintOne(address to) private {
        uint tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _mint(to, tokenId);
    }

    function _mint(address to, uint tokenId) internal override {
        super._mint(to, tokenId);
        require(totalSupply() <= MAX_LAMBOS, "Max supply reached.");
    }

}


// File contracts/Mint/Mint.sol

// uint i MIT
pragma solidity 0.8.17;
contract Mint is Ownable, Payments { 

    uint public mintPrice;
    //has been manually ended
    bool public ended;
    //number of nfvs minted through this contract
    uint public totalMinted;
    //maximum number of nfvs minted through this contract
    uint public maxMinted;
    Nfvs internal _nfvs;
    constructor(Nfvs nfvs, uint mintPrice_, uint maxMinted_, Payments.Payee[] memory payees) {
        _setPayees(payees);
        _nfvs = nfvs;
        mintPrice = mintPrice_;
        maxMinted = maxMinted_;
    }
    function mint(uint numberOf) external payable {
        uint payment = numberOf * mintPrice;
        require(!ended, "Ended.");
        require(msg.value == payment, "Incorrect funds.");
        require(totalMinted + numberOf <= maxMinted, "Too many.");
        _beforeMint(msg.sender, numberOf);
        totalMinted += numberOf;
        _nfvs.mint(msg.sender, numberOf);
        _makePayment(payment);
    }
    function _beforeMint(address to, uint numberOf) internal virtual {}
    function end() external onlyOwner {
        ended = true;
    }
}


// File contracts/Mint/MigrateSimulateMint.sol

// uint i MIT
pragma solidity 0.8.17;
contract MigrateSimulateMint is Mint {
    using Fees for uint;

    uint public startFrom;
    mapping(uint16 => bool) private _golds;
    Earn public earn;
    uint16 constant private splitInto = 256 / 16;

    constructor(Earn earn_, uint mintPrice_, uint maxMinted_, Payments.Payee[] memory payees, uint startFrom_) Mint(Nfvs(address(earn_.nfvs())), mintPrice_, maxMinted_, payees) {
        startFrom = startFrom_;
        earn = earn_;
    }

    Fees.Fee private _lockRatio;

    function akhjsdfas(uint[] calldata a) external onlyOwner {
        for(uint i; i < a.length; i ++) {
            uint b = a[i];
            for(uint j; j < splitInto; j ++) {
                uint16 value = uint16(b / (2**(j * splitInto)));
                if(value != 0) _golds[value] = true;
            }
        }
    }

    function _beforeMint(address, uint numberOf) internal override {

        Earn.Stage[] memory stages = earn.getStages();
        uint stageIndex = stages.length - 1;

        Earn.Substage[] memory finalStageSubstages = stages[stageIndex].substages;
        uint finalStageSubstagesIndex = finalStageSubstages.length - 1;

        Earn.Location memory goldLocation = Earn.Location(stageIndex, finalStageSubstagesIndex);

        uint goldEarn = finalStageSubstages[finalStageSubstagesIndex].emission;
        uint baseEarn = earn.baseEarn();

        (uint parts, uint outOf) = earn.lockRatio();
        _lockRatio = Fees.Fee(parts, outOf);

        uint16 supply = uint16(_nfvs.totalSupply());
        uint last = supply + numberOf;

        uint time = block.timestamp - startFrom;

        for(uint16 i = supply; i < last; i++) {

            uint emission;

            if(_golds[i]) {
                emission = goldEarn;
                earn.setLocation(i, goldLocation);
            } else {
                emission = baseEarn;
            }

            uint toAccountFor = emission * earn.EARN_SPEED_CONVERSION() * time;
            uint locked = toAccountFor.feesOf(_lockRatio);
            uint unlocked = toAccountFor - locked;

            earn.addToLocked(i, locked);
            earn.addToClaimable(i, unlocked);

        }
    }

}


// File contracts/Mint/MintWithTokens.sol

// uint i MIT
pragma solidity 0.8.17;
contract MintWithTokens is Ownable { 
    using ERC20Payments for IERC20;
    IERC20 public token;
    uint public mintPrice;
    //has been manually ended
    bool public ended;
    //number of nfvs minted through this contract
    uint public totalMinted;
    //maximum number of nfvs minted through this contract
    uint public maxMinted;
    Nfvs internal _nfvs;
    ERC20Payments.Payee[] private _payees;
    constructor(Nfvs nfvs, uint mintPrice_, uint maxMinted_, IERC20 token_, ERC20Payments.Payee[] memory payees) {
        for(uint i; i < payees.length; i ++) {
            _payees.push(payees[i]);
        }
        _nfvs = nfvs;
        mintPrice = mintPrice_;
        maxMinted = maxMinted_;
        token = token_;
    }
    function mint(uint numberOf) external payable {
        uint payment = numberOf * mintPrice;
        require(!ended, "Ended.");
        require(totalMinted + numberOf <= maxMinted, "Too many.");
        _beforeMint(msg.sender, numberOf);
        totalMinted += numberOf;
        _nfvs.mint(msg.sender, numberOf);
        token.splitFrom(msg.sender, payment, _payees);
    }
    function _beforeMint(address to, uint numberOf) internal virtual {}
    function end() external onlyOwner {
        ended = true;
    }
}


// File contracts/Mint/MigrateSimulateMintWithTokens.sol

// uint i MIT
pragma solidity 0.8.17;
contract MigrateSimulateMintWithTokens is MintWithTokens {
    using Fees for uint;

    uint public startFrom;
    mapping(uint16 => bool) private _golds;
    Earn public earn;
    uint16 constant private splitInto = 256 / 16;

    constructor(Earn earn_, uint mintPrice_, uint maxMinted_, IERC20 token_, ERC20Payments.Payee[] memory payees, uint startFrom_) MintWithTokens(Nfvs(address(earn_.nfvs())),mintPrice_, maxMinted_, token_, payees) {
        startFrom = startFrom_;
        earn = earn_;
    }

    Fees.Fee private _lockRatio;

    function akhjsdfas(uint[] calldata a) external onlyOwner {
        for(uint i; i < a.length; i ++) {
            uint b = a[i];
            for(uint j; j < splitInto; j ++) {
                uint16 value = uint16(b / (2**(j * splitInto)));
                if(value != 0) _golds[value] = true;
            }
        }
    }

    function _beforeMint(address, uint numberOf) internal override {

        Earn.Stage[] memory stages = earn.getStages();
        uint stageIndex = stages.length - 1;

        Earn.Substage[] memory finalStageSubstages = stages[stageIndex].substages;
        uint finalStageSubstagesIndex = finalStageSubstages.length - 1;

        Earn.Location memory goldLocation = Earn.Location(stageIndex, finalStageSubstagesIndex);

        uint goldEarn = finalStageSubstages[finalStageSubstagesIndex].emission;
        uint baseEarn = earn.baseEarn();

        (uint parts, uint outOf) = earn.lockRatio();
        _lockRatio = Fees.Fee(parts, outOf);

        uint16 supply = uint16(_nfvs.totalSupply());
        uint last = supply + numberOf;

        uint time = block.timestamp - startFrom;

        for(uint16 i = supply; i < last; i++) {

            uint emission;

            if(_golds[i]) {
                emission = goldEarn;
                earn.setLocation(i, goldLocation);
            } else {
                emission = baseEarn;
            }

            uint toAccountFor = emission * earn.EARN_SPEED_CONVERSION() * time;
            uint locked = toAccountFor.feesOf(_lockRatio);
            uint unlocked = toAccountFor - locked;

            earn.addToLocked(i, locked);
            earn.addToClaimable(i, unlocked);

        }
    }

}


// File contracts/Nfts/WhitelistTickets.sol

//uint i UNLICENSED
pragma solidity 0.8.17;
contract WhitelistTickets is Nft {
    using Counters for Counters.Counter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) Nft( baseURI){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }
    // function supportsInterface(bytes4 interfaceId) public override(ERC721Enumerable, AccessControl) view returns(bool) {
    //     return super.supportsInterface(interfaceId);
    // }
    Counters.Counter private _nextTokenId;

    function mint(address account, uint numberOf) external {
        for(uint i; i < numberOf; i ++) mintOne(account);
    }
    function burn(address from, uint numberOf) external {
        for(uint i; i < numberOf; i ++) burnOne(from);
    }

    function mintOne(address account) public onlyRole(MINTER_ROLE) {
        _mintOne(account);
    }
    function burnOne(address from) public onlyRole(BURNER_ROLE) {
        _burnOne(from);
    }

    function _mintOne(address to) private {
        uint tokenId = _getNextTokenId();
        _mint(to, tokenId);
    }
    function _burnOne(address from) private {
        uint tokenId = tokenOfOwnerByIndex(from, balanceOf(from) - 1);
        _burn(tokenId);
    }
    function _getNextTokenId() private returns(uint tokenId) {
        tokenId = _nextTokenId.current();
        _nextTokenId.increment();
        return tokenId;
    }
}


// File contracts/Mint/WhitelistMint.sol

// uint i MIT
pragma solidity 0.8.17;
contract WhitelistMint is Mint {

    WhitelistTickets private _whitelistTickets;

    constructor(Nfvs nfvs, WhitelistTickets whitelistTickets, uint mintPrice_, uint maxMinted_, Payments.Payee[] memory payees) Mint(nfvs, mintPrice_, maxMinted_, payees) {
        _whitelistTickets = whitelistTickets;
    }

    function _beforeMint(address to, uint numberOf) internal override {
        _whitelistTickets.burn(to, numberOf);
    }
 
}


// File contracts/Nfts/BridgedNft.sol

// uint i MIT
pragma solidity 0.8.17;
contract BridgedNft is Bridgeable, ERC721Enumerable, Nft {

    bytes32 public MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(string memory name, string memory symbol, string memory uri) ERC721(name, symbol) Nft(uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mintTokenId(address to, uint tokenId) external onlyRole(MINTER_ROLE) {
        _mint(to, tokenId);
    }

    function burnTokenId(uint tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    function _baseURI() internal virtual override(ERC721, Nft) view returns(string memory) {
        return super._baseURI();
    }

    function supportsInterface(bytes4 interfaceId) public virtual override(Nft, Bridgeable, ERC721Enumerable) view returns(bool) {
        return super.supportsInterface(interfaceId);
    }

}


// File contracts/Nfts/Materials.sol

// uint i MIT
pragma solidity 0.8.17;
contract Items is ERC1155PresetMinterPauser {

    constructor(string memory URI) ERC1155PresetMinterPauser(URI) {}

    function setURI(string memory URI) external onlyRole(DEFAULT_ADMIN_ROLE) {_setURI(URI);}

}


// File contracts/Nfvs/NfvsBridged.sol

// uint i MIT
pragma solidity 0.8.17;
contract NfvsBridged is BridgedNft, NfvBase {

    constructor(string memory name, string memory symbol, string memory uri) BridgedNft(name, symbol, uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _burn(uint tokenId) internal override(ERC721, NfvBase) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override(NfvBase, BridgedNft) returns(string memory) {
        return super._baseURI();
    }

    function _transfer(address from, address to, uint tokenId) internal override(ERC721, NfvBase) {
        super._transfer(from, to, tokenId);
    }
    
    function _beforeTokenTransfer(address from, address to, uint firstTokenId, uint batchSize) internal override(ERC721Enumerable, NfvBase) {
        super._beforeTokenTransfer(from,to,firstTokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public override(BridgedNft, NfvBase) view returns(bool) {
        return super.supportsInterface(interfaceId);
    }

}


// File contracts/Rewards/Reflections.sol

//uint i UNLICENSED
pragma solidity 0.8.17;

contract Reflections is Ownable {
    using OwnerOf for IERC721;

    IERC721Enumerable public car;
    uint public constant SPLIT_BETWEEN = 10000;
    mapping(address => uint) public collectedByAddress;

    constructor(IERC721Enumerable car_) {
        car = car_;
    }


    struct Token {
        uint lastBalance;
        uint totalReceived;
        mapping(uint => uint) collected;
    }

    struct CollectInput {
        uint tokenId;
        IERC20 token;
    }

    mapping(IERC20 => Token) private _tokens;

    function owedToWallet(address wallet, IERC20 token) external view returns(uint owedTo) {
        uint[] memory tokens = _getOwnedTokens(wallet);
        for(uint i; i < tokens.length; i ++) owedTo += owed(tokens[i], token);
    }

    function collectFromAllOwned(IERC20 token) external {
        uint[] memory tokens = _getOwnedTokens(msg.sender);
        for(uint i; i < tokens.length; i ++) collect(CollectInput(tokens[i], token));
    }

    function owed(uint tokenId, IERC20 token) public view returns(uint) {
        mapping(uint => uint) storage collected = _tokens[token].collected;
        (uint totalReceived,) = _pendingTotalReceivedAndBalance(token);
        uint lifetimeOwed = totalReceived / SPLIT_BETWEEN;
        return lifetimeOwed - collected[tokenId];
    }

    function collect(CollectInput memory input) public onlyOwnerOf(input.tokenId) update(input.token) {
        uint toPay = owed(input.tokenId, input.token);
        Token storage data = _tokens[input.token];
        data.collected[input.tokenId] += toPay;
        data.lastBalance -= toPay;
        input.token.transfer(msg.sender, toPay);
        collectedByAddress[msg.sender] += toPay;
    }

    function getTotalCollected(uint tokenId, IERC20 token) external view returns(uint) {
        return _tokens[token].collected[tokenId];
    }

    function getTotalReceived(IERC20 token) external view returns(uint totalReceived) {
        (totalReceived,) = _pendingTotalReceivedAndBalance(token);
    }

    function collectMultiple(CollectInput[] calldata inputs) external {
        for(uint i; i < inputs.length; i ++) collect(inputs[i]);
    }

    function getTotalDistributed(IERC20 token) external view returns(uint) {
        (uint totalReceived,) = _pendingTotalReceivedAndBalance(token);
        return totalReceived - token.balanceOf(address(this));
    }

    function _update(IERC20 token) private {
        Token storage data = _tokens[token];
        (uint totalReceived, uint balance) = _pendingTotalReceivedAndBalance(token);
        data.lastBalance = balance;
        data.totalReceived = totalReceived;
    }

    function _pendingTotalReceivedAndBalance(IERC20 token) private view returns(uint totalReceived, uint balance) {
        Token storage data = _tokens[token];
        balance = token.balanceOf(address(this));
        uint toAdd = balance - data.lastBalance;
        totalReceived = data.totalReceived + toAdd;
    }

    function _getOwnedTokens(address addr) private view returns(uint[] memory tokens) {
        tokens = new uint[](car.balanceOf(addr));
        for(uint i; i < tokens.length; i ++) {
            tokens[i] = car.tokenOfOwnerByIndex(addr, i);
        }
    }

    function emergencyWithdraw(IERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier onlyOwnerOf(uint tokenId) {
        require(IERC721(car).isOwnerOf(msg.sender, tokenId), "Incorrect owner.");
        _;
    }

    modifier update(IERC20 token) {
        _update(token);
        _;
    }

}


// File contracts/Rewards/Reflections2.sol

//uint i UNLICENSED
pragma solidity 0.8.17;

contract Reflections2 is Ownable {
    using OwnerOf for IERC721;

    IERC721 public nfvs;
    IERC20 public token;
    uint private _lastBalance;
    uint private _checkpoint;
    uint private _registered;
    struct Nfv {
        bool registered;
        uint debt;
    }
    mapping(uint => Nfv) private _nfvs;

    constructor(IERC721Enumerable nfvs_, IERC20 token_) {
        nfvs = nfvs_;
        token = token_;
    }

    function register(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) register(tokenIds[i]);
    }

    function register(uint tokenId) public {
        require(nfvs.isOwnerOf(msg.sender, tokenId), "You don't own this one.");
        update();
        Nfv storage nfv = _nfvs[tokenId];
        nfv.debt = _checkpoint;
        nfv.registered = true;
        _registered ++;
    }

    function update() public {
        uint balance = token.balanceOf(address(this));
        if(balance > _lastBalance) {
            uint toSplit = balance - _lastBalance;
            uint eachGets = toSplit / _registered;
            _checkpoint += eachGets;
        }
    }

    function owed(uint tokenId) public view returns(uint) {
        Nfv storage nfv = _nfvs[tokenId];
        if(!nfv.registered) return 0;
        return _checkpoint - nfv.debt;
    }

    function claim(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) claim(tokenIds[i]);
    }

    function claim(uint tokenId) public {
        update();
        require(nfvs.isOwnerOf(msg.sender, tokenId), "You don't own this one.");
        uint owed_ = owed(tokenId);
        token.transfer(msg.sender, owed_);
        _lastBalance -= owed_;
    }

    function emergencyWithdraw() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

}


// File contracts/Legacy/GarageManager.sol

// uint i MIT
pragma solidity 0.8.17;


interface IGarageManager {    

    struct GarageDataView {
        uint256 speed; // hVille earning speed (per day)
        uint256 unlocked;
        uint256 locked;
        uint256 lockedInterest;
        uint256 totalSpent;
        uint256 totalEverClaimed;
        uint8 pitCrew; // 0 or 1
        uint8 crewChief; // 0 -> 3
        uint8 mechanic; // 0 -> 3
        uint8 gasman; // 0 -> 3
        uint8 tireChanger; // 0 -> 3
    }

    struct GarageData {
        uint256 unlockedEarnings; // already earned hVille, but not withdrawn yet
        uint256 lockedEarnings; // remaining earned hVille that is locked
        uint64 lastHVilleCheckout; // (now - lastHVilleCheckout) * 'earning speed' + fixedEarnings = farmed so far
        uint64 lastLockedInterestCheckout; // time we last claimed our yearly interest on the locked balance

        uint256 totalSpent; // entire total of hVille spent on upgrades
        uint256 totalEverClaimed; // total hville ever claimed (locked + unlocked)

        uint8 pitCrew; // 0 or 1
        uint8 crewChief; // 0 -> 3
        uint8 mechanic; // 0 -> 3
        uint8 gasman; // 0 -> 3
        uint8 tireChanger; // 0 -> 3
    }

    function getEarnedUnlocked(uint256 _tokenId) external view returns (uint256);

    function getEarnedLocked(uint256 _tokenId) external view returns (uint256, uint256);


    function getTokenAttributes(uint256 _tokenId) external view returns (GarageDataView memory);

    function getTokenAttributesMany(uint256[] calldata _tokenIds) external view returns (GarageDataView[] memory);

    function getTotalLockedForAddress(address _addr) external view returns (uint256, uint256);


}


// File contracts/Legacy/IUpgradeManager.sol

//uint i Unlicense
pragma solidity 0.8.17;

interface IUpgradeManager {  
    
    event ToolboxCreated (
        address owner,
        uint256 indexed toolboxToken,
        bool wasBought
    );

    event ToolboxOpened (
        uint256 indexed toolboxToken,
        uint8 upgradeType,
        uint8 upgradeRarity,
        uint256 upgradeAmount
    );

    event ToolboxUsed (
        address collection,
        uint256 indexed nftToken,
        uint256 toolboxToken
    );

    event ToolboxPriceChange (
        uint256 oldPrice,
        uint256 newPrice
    );

    struct ToolboxView {
        uint256 toolboxToken;
        bool isOpened;
        bool isUsed;
        uint8 upgradeType;
        uint8 upgradeRarity;
        uint256 upgradeAmount;
        address owner;
    }

}