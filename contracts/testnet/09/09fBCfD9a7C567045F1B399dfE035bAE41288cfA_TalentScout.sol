/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-07
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/access/IAccessControl.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

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

// File: @openzeppelin/contracts/access/AccessControl.sol

// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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

// File: contracts/talentscout.sol

// SPDX-License-Identifier: None
pragma solidity 0.8.0;





interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);
}

interface ITalentStaking {

    function voting() external;

}

interface IVoting{

}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IPangolinPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface ITalentScoutAutoLiquidator {
    function addAutoLiquidity(uint256 _amount) external;
    function autoBuybackAndBurn(uint256 _amount) external;
}

interface IReflectionDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function depositRewardAmount(uint256 _amount) external;
}

contract TalentScout is IERC20, AccessControl, Ownable {
    using SafeMath for uint256;

    ITalentStaking public talentStaking;

    IVoting public voting;

    AggregatorV3Interface internal priceFeed;

    uint256 public constant MAX = type(uint256).max;

    // TODO: Change for mainnet
    IERC20 public USDT = IERC20(0x53CDA8410970c9786c9e6C7fb5BEb23dd6E88b8b);
    // TODO: Change for mainnet
    IWAVAX public WAVAX;

    // address public WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    address VoteStakingContract;

    string constant _name = "Talent Scout Token";
    string constant _symbol = "Scout";
    uint8 constant _decimals = 18;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    uint256 _totalSupply = 10_000_000_000_000 * (10**_decimals);
    uint256 public presaleSupply = 100_000_000_000 * (10**_decimals);
    uint256 public idoSupply = 75_000_000_000 * (10**_decimals);
    uint256 public initialLiquidity = 5_550_000_000_000 * (10**_decimals);
    uint256 public initialBurn = 4_000_000_000_000 * (10**_decimals);
    uint256 public founderSupply = 350_000_000_000 * (10**_decimals);

    // Taxes
    uint256 public taxAmount = 1200;

    uint256 public reflectionTax = 6500;
    uint256 public talentAwardTax = 2000;
    uint256 public voterRewardTax = 1000;
    uint256 public lpTax = 200;
    uint256 public adminTax = 200;
    uint256 public buyBackTax = 100;
    uint256 public feeDenominator = 10000;

    mapping(address => bool) isFeeExempt;
    mapping (address => bool) isReflectionExempt;

    // Tax Receivers
    address public talentAwardsFeeReceiver;
    address public voterRewardsFeeReceiver;
    address public adminAddress; // This address will receive admin tax amount and auto liquidity
    ITalentScoutAutoLiquidator public autoLiquidator;
    IReflectionDistributor public reflectionDistributor;

    uint256 totalPaidReflectionsInUSD = 0;

    uint256 public swapThreshold = _totalSupply / 2000; // 0.005%
    bool public inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    uint256 collectedReflectionFeeAmount = 0;
    uint256 collectedAwardFeeAmount = 0;

    IDEXRouter public router;
    address public pair;

    // Presale locking mechanism
    bytes32 public constant CROWDSALE_ROLE =
        0x0000000000000000000000000000000000000000000000000000000000000001;

    struct Locks {
        uint256 locked;
        uint256 releaseTime;
        bool released;
    }
    mapping(address => Locks[]) _locks;

    uint256 public totalPresaleLockedAmount = 0;

    mapping (address => bool) public buyBackers;

    event Bought(address account, uint256 amount);
    event Locked(address account, uint256 amount);
    event Released(address account, uint256 amount);

    constructor(
        address _dexRouter, 
        address _talentAwardsFeeReceiver,
        address _voterRewardsFeeReceiver,
        address _adminAddress)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        router = IDEXRouter(_dexRouter);
        WAVAX = IWAVAX(router.WAVAX());

        // LP pair to buy/sell
        pair = IDEXFactory(router.factory()).createPair(address(WAVAX), address(this));

        // TODO: Update for Mainnet
        priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);

        // Setup addresses
        talentAwardsFeeReceiver = _talentAwardsFeeReceiver;
        voterRewardsFeeReceiver = _voterRewardsFeeReceiver;
        adminAddress = _adminAddress;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[talentAwardsFeeReceiver] = true;
        isFeeExempt[voterRewardsFeeReceiver] = true;
        isFeeExempt[adminAddress] = true;
        buyBackers[msg.sender] = true;
        isReflectionExempt[pair] = true;
        isReflectionExempt[address(this)] = true;
        isReflectionExempt[DEAD] = true;
        isReflectionExempt[talentAwardsFeeReceiver] = true;
        isReflectionExempt[voterRewardsFeeReceiver] = true;
        isReflectionExempt[adminAddress] = true;
        isReflectionExempt[msg.sender] = true;

        _allowances[address(this)][_dexRouter] = MAX;
        _allowances[address(this)][address(pair)] = MAX;

        // // Mint supplies
        // // Locked in Liquidity
        _mint(address(this), initialLiquidity);

        // Initial Burn
        _mint(address(this), initialBurn);
        _burn(address(this), initialBurn);

        // // Founder / Team
        _mint(adminAddress, founderSupply);

        // // IDO & Presale
        _mint(address(this), idoSupply);
        _mint(address(this), presaleSupply);
    }
    
    function addInitialLiquidity() public payable onlyOwner {
        // add the liquidity
        router.addLiquidityAVAX{value: msg.value}(
            address(this),
            initialLiquidity,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            adminAddress,
            block.timestamp
        );
    }

    modifier onlyBuyBacker() { require(buyBackers[msg.sender] == true, "Burn: Not allowed"); _; }

    receive() external payable {}

    function totalSupply() external override view returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function balanceOf(address account) public override view returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external override view returns (uint256) { return _allowances[holder][spender]; }

    function distributeReflectionAmount() public onlyOwner {
        // uint256 distributedAmount = 0;

        // for(uint i = 0; i < talentStaking.length; i++) {
        //     (uint256 reflectionAmount, uint256 usdtAmount) = userReflectionRewards(holders[i]);
        //     USDT.transferFrom(address(this), holders[i], usdtAmount);
        //     totalPaidReflectionsInUSD = totalPaidReflectionsInUSD.add(usdtAmount);
        //     distributedAmount = distributedAmount.add(reflectionAmount);
        // }
        // collectedReflectionFeeAmount = collectedReflectionFeeAmount.sub(distributedAmount);
    }

    function distributeTalentAwardAmount() public onlyOwner {
    //     uint256 distributedAmount = 0;

    //     address[] storage stakers = talentStaking.stakers();

    //     // uint256 reward = votingToken.balanceOf(address(talentStaking)); // accumulated votes 

    //    for(uint i = 0; i < stakers.length; i++) {
    //         // (uint256 talentAwardAmount, uint256 usdtAmount) = userTalentAwards(stakers[i]);
    //         // USDT.transferFrom(address(this), stakers[i], usdtAmount);
    //         // totalPaidReflectionsInUSD = totalPaidReflectionsInUSD.add(usdtAmount);
    //         // distributedAmount = distributedAmount.add(talentAwardAmount);
    //    }

    //     collectedAwardFeeAmount = collectedAwardFeeAmount.sub(distributedAmount);
    }


    function userReflectionRewards(address _holder) public view returns(uint256, uint256) {
        uint256 userBalance = balanceOf(_holder);
        uint256 circulatingSupply = getCirculatingSupply();
        uint256 holderShare = (userBalance.div(circulatingSupply)).mul(100);
        uint256 reflectionAmount = collectedReflectionFeeAmount.mul(holderShare).div(100);
        uint256 amountInUSDT = getCurrentPrice().mul(reflectionAmount);
        return (reflectionAmount, amountInUSDT);
    }

    function userTalentAwardRewards(address _holder) public view returns(uint256, uint256) {
        uint256 userBalance = balanceOf(_holder);
        uint256 circulatingSupply = getCirculatingSupply();
        uint256 holderShare = (userBalance.div(circulatingSupply)).mul(100);
        uint256 awardAmount = collectedAwardFeeAmount.mul(holderShare).div(100);
        uint256 amountInUSDT = getCurrentPrice().mul(awardAmount);
        return (awardAmount, amountInUSDT);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, MAX);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance.sub(amount);
            _balances[ZERO] = _balances[ZERO].add(amount);
        }
        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public onlyBuyBacker {
        _burn(msg.sender, amount);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != MAX){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        require(balanceOf(sender) >= amount, "Insufficient Balance");
        if (inSwap || !shouldTakeFee(sender)) { 
            return _basicTransfer(sender, recipient, amount); 
        }
        
        uint256 feeAmount = amount.mul(taxAmount).div(feeDenominator);
        uint256 amountReceived = amount.sub(feeAmount);
        takeFee(feeAmount, msg.sender);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);
        
        if(!isReflectionExempt[sender]) { 
            try reflectionDistributor.setShare(sender, _balances[sender]) {} catch {} 
        }
        if(!isReflectionExempt[recipient]) { 
            try reflectionDistributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        if(!isReflectionExempt[sender]) { 
            try reflectionDistributor.setShare(sender, _balances[sender]) {} catch {} 
        }
        if(!isReflectionExempt[recipient]) { 
            try reflectionDistributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) public view returns (bool) {
        return !isFeeExempt[sender];
    }
    
    function takeFee(uint256 amount, address _sender) internal {
        // Reflection Fee
        uint256 reflectionFeeAmount = amount.mul(reflectionTax).div(feeDenominator);
        _basicTransfer(_sender, address(reflectionDistributor), reflectionFeeAmount);
        reflectionDistributor.depositRewardAmount(reflectionFeeAmount);

        // Talent Awards Fee
        uint256 talentAwardFeeAmount = amount.mul(talentAwardTax).div(feeDenominator);
        collectedAwardFeeAmount = collectedAwardFeeAmount.add(talentAwardFeeAmount);
        _basicTransfer(_sender, talentAwardsFeeReceiver, talentAwardFeeAmount);

        // Voter Rewards Fee
        uint256 voterRewardFeeAmount = amount.mul(voterRewardTax).div(feeDenominator);
        _basicTransfer(_sender, voterRewardsFeeReceiver, voterRewardFeeAmount);

        // Auto Liquidity Fee
        uint256 lpFeeAmount = amount.mul(lpTax).div(feeDenominator);
        _autoLiquify(lpFeeAmount);

        // Admin Fee
        uint256 adminFeeAmount = amount.mul(adminTax).div(feeDenominator);
        _basicTransfer(_sender, adminAddress, adminFeeAmount);

        // Buyback and burn Fee
        uint256 buybackFeeAmount = amount.mul(buyBackTax).div(feeDenominator);
        _autoBuybackAndBurn(buybackFeeAmount);
    }

    function _autoLiquify(uint256 liquidityFeeAmount) internal swapping {
        _basicTransfer(msg.sender, address(autoLiquidator), liquidityFeeAmount);
        autoLiquidator.addAutoLiquidity(liquidityFeeAmount);
    }

    function _autoBuybackAndBurn(uint256 buybackFeeAmount) internal swapping {
        autoLiquidator.autoBuybackAndBurn(buybackFeeAmount);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(0), '!nonzero');
        isFeeExempt[holder] = exempt;
    }

    function setFeeReceivers(
        address  _talentAwardsFeeReceiver,
        address  _voterRewardsFeeReceiver,
        address  _adminAddress
    ) external onlyOwner {
        require(_talentAwardsFeeReceiver != address(0), '!nonzero');
        require(_voterRewardsFeeReceiver != address(0), '!nonzero');
        require(_adminAddress != address(0), '!nonzero');
        talentAwardsFeeReceiver = _talentAwardsFeeReceiver;
        voterRewardsFeeReceiver = _voterRewardsFeeReceiver;
        adminAddress = _adminAddress;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(ZERO)).sub(balanceOf(DEAD));
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getCurrentPrice() public view returns (uint256) {
        (uint112 balance1, uint112 balance0, ) = IPangolinPair(pair).getReserves();
        if (balance1 == 0) {
            return 0;
        }
        uint256 ratio = uint256(balance0).div(balance1); // token price in WAVAX
        uint256 priceInDollars = ratio.mul(getPrice());
        return priceInDollars;
    }

    function setAutoLiquidator(address _autoLiquidator) public onlyOwner {
        require(_autoLiquidator != address(0), '!nonzero');
        if (address(autoLiquidator) != address(0)) {
            isFeeExempt[address(autoLiquidator)] = false;
            buyBackers[address(autoLiquidator)] = false;
        }
        autoLiquidator = ITalentScoutAutoLiquidator(_autoLiquidator);
        isFeeExempt[_autoLiquidator] = true;
        buyBackers[_autoLiquidator] = true;
        isReflectionExempt[_autoLiquidator] = true;
    }

    function setReflectionDistributor(address _distributor) public onlyOwner {
        require(_distributor != address(0), '!nonzero');
        if (address(reflectionDistributor) != address(0)) {
            isFeeExempt[address(reflectionDistributor)] = false;
            isReflectionExempt[address(reflectionDistributor)] = false;
        }
        reflectionDistributor = IReflectionDistributor(_distributor);
        isFeeExempt[_distributor] = true;
        isReflectionExempt[_distributor] = true;
    }

    function setReflectionExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair, 'Invalid address');
        isReflectionExempt[holder] = exempt;
        if(exempt) { 
            reflectionDistributor.setShare(holder, 0);
        } else {
            reflectionDistributor.setShare(holder, _balances[holder]);
        }
    }

    function setBuyBacker(address _address, bool isBuyBacker) public onlyOwner {
        require(_address != address(0), '!nonzero');
        buyBackers[_address] = isBuyBacker;
    }

    function setFees(
        uint256 _taxAmount
    ) external onlyOwner {
        require(_taxAmount > 0, "!nonnegative");
        require(_taxAmount < 1500, "!toohigh");
        taxAmount = _taxAmount;
    }

    /**
     * Lock the provided amount of Scout for "_relative_releaseTime" seconds starting from now
     * NOTE: This method is capped
     * NOTE: time definition in the locks is relative!
     */
    function insertPresaleLock(
        address account,
        uint256 _amount,
        uint256 _relative_releaseTime
    ) public onlyRole(CROWDSALE_ROLE) {
        require(
            totalPresaleLockedAmount + _amount <= presaleSupply,
            "Unable to lock the defined amount, cap exceeded"
        );
        Locks memory lock_ = Locks({
            locked: _amount,
            releaseTime: block.timestamp + _relative_releaseTime,
            released: false
        });
        _locks[account].push(lock_);

        totalPresaleLockedAmount += _amount;

        emit Locked(account, _amount);
    }

    /**
     * Retrieve the locks state for the account
     */
    function locksOf(address account) public view returns (Locks[] memory) {
        return _locks[account];
    }

    /**
     * Get the number of locks for an account
     */
    function getLockNumber(address account) public view returns (uint256) {
        return _locks[account].length;
    }

    /**
     * Release the amount of locked presale amount
     */
    function releasePresaleAmount(uint256 lock_id) public {
        require(
            _locks[msg.sender].length > 0,
            "No locks found for your account"
        );
        require(
            _locks[msg.sender].length - 1 >= lock_id,
            "Lock index too high"
        );
        require(!_locks[msg.sender][lock_id].released, "Lock already released");
        require(
            block.timestamp > _locks[msg.sender][lock_id].releaseTime,
            "Lock not yet ready to be released"
        );

        // refresh the amount of tokens locked
        totalPresaleLockedAmount -= _locks[msg.sender][lock_id].locked;

        // mark the lock as realeased
        _locks[msg.sender][lock_id].released = true;

        // transfer the tokens to the sender
        _basicTransfer(address(this), msg.sender, _locks[msg.sender][lock_id].locked);
        emit Released(msg.sender, _locks[msg.sender][lock_id].locked);
    }

    /**
     * Destory the remaining presale supply
     */
    function destroyPresale(uint256 amount) public onlyRole(CROWDSALE_ROLE) {
        _burn(address(this), amount);
    }
}