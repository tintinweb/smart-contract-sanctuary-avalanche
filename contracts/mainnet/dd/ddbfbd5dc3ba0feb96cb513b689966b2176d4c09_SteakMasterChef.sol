/**
 *Submitted for verification at snowtrace.io on 2022-04-28
*/

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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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


// File @openzeppelin/contracts/utils/math/[email protected]


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


// File contracts/libraries/BoringJoeERC20.sol


pragma solidity ^0.8.0;

// solhint-disable avoid-low-level-calls

library BoringJoeERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}


// File contracts/interfaces/IBoostedMasterChefJoe.sol


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IBoostedMasterChefJoe {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. JOE to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that JOE distribution occurs.
        uint256 accJoePerShare; // Accumulated JOE per share, times 1e12. See below.
    }

    //function userInfo(uint256 _pid, address _user) external view returns (IMasterChefJoe.UserInfo memory);

    function poolInfo(uint256 pid) external view returns (IBoostedMasterChefJoe.PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function joePerSec() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function devPercent() external view returns (uint256);

    function treasuryPercent() external view returns (uint256);

    function investorPercent() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user) external view returns (
        uint256 pendingJoe, address bonusTokenAddress, string memory bonusTokenSymbol, uint256 pendingBonusToken);

    function emergencyWithdraw(uint256 _pid) external;
}


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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


// File contracts/interfaces/IVeJoeStaking.sol


pragma solidity ^0.8.0;


interface IVeJoeStaking {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function claim() external;
}


// File contracts/protocol/SteakHutVoter.sol


pragma solidity ^0.8.0;



/// @notice Key Interface between Masterchef/Zapper and Trader Joe.
/// Manages the staking / unstaking / rewards of Trader Joe.

contract SteakHutVoter is AccessControl { 
    
    // Create a new role identifier for the minter role
    bytes32 public constant ZAPPER_ROLE = keccak256("ZAPPER_ROLE");
    bytes32 public constant MASTERCHEF_ROLE = keccak256("MASTERCHEF_ROLE");

    IBoostedMasterChefJoe public constant BMCJ = IBoostedMasterChefJoe(0x4483f0b6e2F5486D06958C20f8C39A7aBe87bf8F);
    IVeJoeStaking public constant VeJoeStaking = IVeJoeStaking(0x25D85E17dD9e544F6E9F8D44F99602dbF5a97341);
    IERC20 public constant JOE = IERC20(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd);

    event Deposit(uint256 _pid, uint256 amount);
    event Withdraw(uint256 _pid, uint256 amount);
    event ClaimJoe(uint256 amount);
    event ClaimBonusToken(uint256 amount, address tokenAddress);
    event StakeJoe(uint256 amount);
    event ClaimVeJOE();
    event EmergencyWithdraw(uint256 _pid, uint256 amount);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Deposit LP tokens to BMCJ
    /// @param _lpToken The LP Token to deposit`
    /// @param _pid The index of the pool. See `poolInfo`
    /// @param _amount LP token amount to deposit
    function _deposit(IERC20 _lpToken, uint256 _pid, uint256 _amount) external {
        require(hasRole(MASTERCHEF_ROLE, msg.sender), "Caller is not masterchef");    

        //send LP token to BMCJ
        _lpToken.approve(address(BMCJ), _amount);
        //deposit to BMCJ    
        BMCJ.deposit(_pid, _amount);
        _lpToken.approve(address(BMCJ), 0);

        emit Deposit(_pid, _amount);  
    }

    /// @notice Withdraw LP tokens from BMCJ
    /// @param _pid The index of the pool. See `poolInfo`
    /// @param _amount LP token amount to withdraw
    /// @notice this is to be limited to only masterchef
    function _withdraw(IERC20 _lpToken, uint256 _pid, uint256 _amount) external {
        require(hasRole(MASTERCHEF_ROLE, msg.sender), "Caller is not masterchef");

        //return LP token from BMCJ to this voter
        BMCJ.withdraw(_pid, _amount);

        //return LP tokens to the SteakMasterChef
        _lpToken.transfer(msg.sender, _amount);

        emit Withdraw(_pid, _amount);  
    }

    /// @notice Withdraw without caring about rewards (EMERGENCY ONLY)
    /// @param _lpToken The lp token of requiring withdrawl
    /// @param _pid The index of the pool. See `poolInfo`
    /// @notice this is to be limited to only masterchef
    function _emergencyWithdraw(IERC20 _lpToken, uint256 _pid) external {
        require(hasRole(MASTERCHEF_ROLE, msg.sender), "Caller is not masterchef");

        //Emergency withdraw LP tokens to the SHMC
        BMCJ.emergencyWithdraw(_pid);

        uint256 _bal = _lpToken.balanceOf(address(this));

        //Return LP tokens to the SteakMasterChef
        _lpToken.transfer(msg.sender, _bal);

        emit EmergencyWithdraw(_pid, _bal);  
    }

    /// @notice Claims JOE Rewards from this voter
    /// @param _amount amount of Joe to Claim
    /// @notice highly sensitive limited to only SteakHut Master Chef
    function _claimJOE(uint256 _amount) external {
        require(hasRole(MASTERCHEF_ROLE, msg.sender), "Caller is not masterchef");

        require(JOE.balanceOf(address(this)) >= _amount, 'Voter: Reject, Not Enough Joe; Wait.');
        JOE.transfer(msg.sender, _amount);

        emit ClaimJoe(_amount);  
    }

    /// @notice Claims Bonus Token Rewards
    /// @param _amount amount of Bonus Token to Claim
    /// @notice highly sensitive limited to only SteakHut Master Chef
    function _claimBonusToken(uint256 _amount, address _tokenAddress) external {
        require(hasRole(MASTERCHEF_ROLE, msg.sender), "Caller is not masterchef");

        IERC20 bonusToken = IERC20(_tokenAddress);
        require(bonusToken.balanceOf(address(this)) >= _amount, 'Voter: Reject, Not Enough Bonus Tokens; Wait.');
        bonusToken.transfer(msg.sender, _amount);

        emit ClaimBonusToken(_amount, _tokenAddress);
    }

    /// @notice Deposit JOE tokens to veJOEStaking Contract
    /// @param _amount JOE token amount to deposit
    /// @notice this is to be limited to only zapper
    function _stakeJOE(uint256 _amount) external {
        require(hasRole(ZAPPER_ROLE, msg.sender), "Caller is not Zapper");

        JOE.approve(address(VeJoeStaking), _amount);
        VeJoeStaking.deposit(_amount);
        JOE.approve(address(VeJoeStaking), 0);

        emit StakeJoe(_amount);
    }

    /// @notice claim any avaliable veJOE
    /// anyone can call as will claim for voter
    function _claimVeJoe() external {
        VeJoeStaking.claim();
        
        emit ClaimVeJOE();
    }

    /**
     * @notice Open-ended execute function
     * @dev Very sensitive, restricted to owner
     * @param target address
     * @param value value to transfer
     * @param data calldata
     * @return bool success
     * @return bytes result
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory) {
        require(hasRole(MASTERCHEF_ROLE, msg.sender), "Caller is not masterchef");

        (bool success, bytes memory result) = target.call{value: value}(data);
        return (success, result);
    }
}


// File contracts/protocol/SteakMasterChef.sol


pragma solidity ^0.8.0;




contract SteakMasterChef is Ownable { 
    using SafeMath for uint;
    using SafeMath for uint256;

    /// @notice addresses for required JOE Contracts
    IBoostedMasterChefJoe public constant BMCJ = IBoostedMasterChefJoe(0x4483f0b6e2F5486D06958C20f8C39A7aBe87bf8F);
    IERC20 public constant JOE = IERC20(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd);
    
    ///@notice enable and disable the masterchef
    bool public isSteakMasterChefEnabled; 

    ///@notice the fee % that is payable from rewards to the treasury.
    ///variable from 0 to max of 20%, initial 3%.
    uint256 public poolFee = 3;
    
    ///@notice address where fees are collected to.
    address public treasuryWallet;

    ///@notice SteakHut Voter Interface
    SteakHutVoter public immutable voter; 

    /// @notice Info of each SHMC user
    /// `amount` LP token amount the user has provided
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /// @notice Info of each SteakHut MasterChef pool
    struct PoolInfo {
        IERC20 lpToken;
        //accJoePerShare is the amount of accumulated rewards
        // Accumulated JOE per share, times 1e18. See below.
        uint256 accJoePerShare; 
        // lastRewardTimestamp = last reward when paid from BJMC to SH_Voter
        uint256 lastRewardTimestamp;
        // The total LP supply of the farm
        // This is the sum of all users boosted amounts in the farm. Updated when
        // someone deposits or withdraws.
        uint256 totalLpSupply;
        //enable and disable pools as absolutely required.
        bool poolEnabled;
    }

    /// @notice Info of each SHMC pool
    PoolInfo[] public poolInfo;

    /// @notice Maps an address to a bool to assert that a token isn't added twice
    mapping(IERC20 => bool) private checkPoolDuplicate;

    /// @notice Info of each user that stakes LP tokens
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice Events
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event Add(uint256 indexed pid, IERC20 indexed lpToken);
    event SetPoolStatus(uint256 indexed pid, bool poolStatus);
    event SetSteakMasterChefEnabled(bool isEnabled);
    event SetTreasury(address treasuryAddress);
    event SetRewardFee(uint256 rewardFee);

    /// @notice contructor function for SteakMasterChef
    /// @param _isMasterChefEnabled is the masterchef enabled
    constructor(
        bool _isMasterChefEnabled, 
        SteakHutVoter _voterAddress
    ){
        isSteakMasterChefEnabled = _isMasterChefEnabled;
        voter = _voterAddress;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// @param _lpToken Address of the LP ERC-20 token.
    function add(
        IERC20 _lpToken 
    ) external onlyOwner {
        require(!checkPoolDuplicate[_lpToken], "SteakMasterChef: LP already added");
        //require(poolInfo.length <= 50, "SteakMasterChef: Too many pools");
        checkPoolDuplicate[_lpToken] = true;

        // Sanity check to ensure _lpToken is an ERC20 token
        _lpToken.balanceOf(address(this));

        //push the new pool
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                lastRewardTimestamp: uint256(block.timestamp),
                totalLpSupply: 0, 
                poolEnabled: true, 
                accJoePerShare: 0
            })
        );
        
        emit Add(poolInfo.length - 1, _lpToken);
    }

    /// @notice Returns the number of SHMC pools.
    /// @return pools The amount of pools in this farm
    function poolLength() external view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Returns the lp value of a pool
    /// @param _pid pool id of pool 
    /// @return lpValue The amount of pools in this farm
    function poolLpSupply(uint256 _pid) external view returns (uint256 lpValue) {
        PoolInfo storage pool = poolInfo[_pid];
        return(pool.totalLpSupply);
    }

    /// @notice Enable and Disable Pool Deposits
    /// @param _pid ID of the pool of interest
    /// @param _isPoolEnabled is the pool enabled?
    function setPoolStatus(uint256 _pid, bool _isPoolEnabled) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.poolEnabled = _isPoolEnabled;

        emit SetPoolStatus(_pid, _isPoolEnabled);
    }


    /// @notice Deposit LP tokens to SteakMasterChef for allocation
    /// @param _pid The index of the pool. See `poolInfo`
    /// @param _amount LP token amount to deposit
    function deposit(uint256 _pid, uint256 _amount) external {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(isSteakMasterChefEnabled, 'SteakHut MasterChef: Protocol Not Enabled');
        require(pool.poolEnabled, 'SteakHut MasterChef: Current Pool Not Enabled');
        
        uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        uint256 receivedAmount = pool.lpToken.balanceOf(address(this)).sub(balanceBefore);

        //deposits to the BMCJ contract through Voter
        _deposit(pool.lpToken, _pid, _amount);

        //claim reward if user lp balance is greater than 0.
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accJoePerShare).div(1e18).sub(
                    user.rewardDebt
                );
            _transferRewards(pending, _pid);
        }

        //update the user and pool statistics
        _updateUserAndPool(user, pool, receivedAmount, true);

        //updates users reward debt
        user.rewardDebt = user.amount.mul(pool.accJoePerShare).div(1e18);

        emit Deposit(msg.sender, _pid, receivedAmount);
    }

    /// @notice Deposit LP tokens to Voter -> BMCJ for JOE allocation
    /// @param _lpToken The LP Token to deposit`
    /// @param _pid The index of the pool. See `poolInfo`
    /// @param _amount LP token amount to deposit
    function _deposit(IERC20 _lpToken, uint256 _pid, uint256 _amount) internal {

        uint256 beforeJoe = JOE.balanceOf(address(voter));
        
        //Transfer lp tokens to voter for deposit
        _lpToken.transfer(address(voter), _amount);

        voter._deposit(_lpToken, _pid, _amount);

        uint256 afterJoe = JOE.balanceOf(address(voter));

        //update the pool accJoePerShare
        uint256 _harvestAmount = afterJoe.sub(beforeJoe);
        updatePool(_pid, _harvestAmount);
    }

    /// @notice Withdraw LP tokens from SteakMasterChef to sender
    /// @param _pid The index of the pool. See `poolInfo`
    /// @param _amount LP token amount to withdraw
    function withdraw(uint256 _pid, uint256 _amount) external {
        require(_amount >= 0, "SteakMasterChef: Withdraw cannot be < 0");
        require(isSteakMasterChefEnabled, 'SteakHut MasterChef: Protocol Not Enabled');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "SteakMasterChef: withdraw not good");
        

        //transfers lp token back to this address from voter
        _withdraw(pool.lpToken, _pid, _amount);

        //check and transfer any pending rewards.
       uint256 pending =
            user.amount.mul(pool.accJoePerShare).div(1e18).sub(
                user.rewardDebt
        );

        //Trasfer the rewards to user and take fee.
        _transferRewards(pending, _pid);

        //update the pool data
        _updateUserAndPool(user, pool, _amount, false);
        
        //updates the users rewardDebt
        user.rewardDebt = user.amount.mul(pool.accJoePerShare).div(1e18);

        //transfer token from masterchef to depositor
        pool.lpToken.transfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw LP tokens from BMCJ to SH Masterchef
    /// @param _pid The index of the pool. See `poolInfo`
    /// @param _amount LP token amount to deposit
    function _withdraw(IERC20 _lpToken, uint256 _pid, uint256 _amount) private {

        //catch the amount of Joe before and after making a call to BJMC
        uint256 beforeJoe = JOE.balanceOf(address(voter));
        
        //Return LP token to BMCJ
        voter._withdraw(_lpToken, _pid, _amount);

        uint256 afterJoe = JOE.balanceOf(address(voter));
        
        //update the pool accJoePerShare
        uint256 _harvestAmount = afterJoe.sub(beforeJoe); 
        updatePool(_pid, _harvestAmount);
    }

    /// @notice Transfers the rewards to the recipient 
    /// @param _amount The amount of rewards to pay to user
    /// @param _pid The index of the pool. See `poolInfo`
    function _transferRewards(uint256 _amount, uint256 _pid) private {
        //IERC20 JoeToken = IERC20(JOE);

        //take transaction fee from rewards, send to fee taker wallet
        uint256 transactionFee = _amount.mul(poolFee).div(100);
        uint256 userReward = _amount.sub(transactionFee);
        
        //claim the pending rewards from the voter
        voter._claimJOE(_amount);

        //transfer the rewards to user and treasury
        JOE.transfer(msg.sender, userReward);
        JOE.transfer(treasuryWallet, transactionFee);
        
        emit Claim(msg.sender, _pid, _amount);
    }


    /// @notice Updates user and pool infos
    /// @param _user The user that needs to be updated
    /// @param _pool The pool that needs to be updated
    /// @param _amount The amount that was deposited or withdrawn
    /// @param _isDeposit If the action of the user is a deposit
    function _updateUserAndPool(
        UserInfo storage _user,
        PoolInfo storage _pool,
        uint256 _amount,
        bool _isDeposit
    ) private {
        uint256 oldAmount = _user.amount;
        uint256 newAmount = _isDeposit ? oldAmount.add(_amount) : oldAmount.sub(_amount);

        //updates the user pool and pool totals
        if (_amount != 0) {
            _user.amount = newAmount;
            _pool.totalLpSupply = _isDeposit ? _pool.totalLpSupply.add(_amount) : _pool.totalLpSupply.sub(_amount);
        }
        
    }

    /// @notice Updates Pool Data Only
    /// @param _pid The id of the pool that needs to be updated
    /// @param _harvestAmount The amount of JOE harvested on each deposit / withdraw
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid, uint256 _harvestAmount) private {
        PoolInfo storage pool = poolInfo[_pid];
        
        //Check if total LP amount || _harvestAmount is 0 
        //Don't update pool as no rewards would be avaliable.
        if (pool.totalLpSupply == 0 || _harvestAmount == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        
        pool.accJoePerShare = pool.accJoePerShare.add(
            _harvestAmount.mul(1e18).div(pool.totalLpSupply)
        );

        pool.lastRewardTimestamp = block.timestamp;
    }

    /// @notice Front End Function to view users pending rewards
    /// @param _pid pool id
    /// @param _user user address to view. 
    function pendingJoe(uint256 _pid, address _user) public view returns(uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accJoePerShare = pool.accJoePerShare;
        uint256 lpSupply = pool.totalLpSupply;

        //estimates a new pool.accJoePerShare when time increased
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 _pendingJoe = pendingHerdRewards(_pid);
            accJoePerShare = pool.accJoePerShare.add(_pendingJoe.mul(1e18).div(lpSupply));
        }
        
        uint256 userReward = user.amount.mul(accJoePerShare).div(1e18).sub(user.rewardDebt);
        //return userReward subtracting any fees
        return userReward.mul(uint256(100).sub(poolFee)).div(100);

    }

    /// @notice view the users LP Pool balance
    /// @param _pid pool id
    /// @param _user user address to view.
    function fetchUserLPBal(uint256 _pid, address _user) view external returns(uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return(user.amount);
    }

    /// @notice Calculates the SteakMasterChef pending JOE rewards front facing UI method
    /// @param _pid The index of the pool. See `poolInfo`
    function pendingHerdRewards(uint256 _pid) public view returns(uint256){        
        (uint256 _pendingHerdJoe, , , ) = BMCJ.pendingTokens(_pid, address(voter));       
        return(_pendingHerdJoe);
    }

    /// @notice sets the protocol active or not
    /// @param _isEnabled Is the protocol active
    function setSteakMasterChefEnabled(bool _isEnabled) external onlyOwner {
        isSteakMasterChefEnabled = _isEnabled;

        emit SetSteakMasterChefEnabled(_isEnabled);
    }

    /// @notice sets the treasury wallet address
    /// @param _walletAddress is the nominated treasury address
    function setTreasuryAddress(address _walletAddress) external onlyOwner {
        require(_walletAddress != address(0), 'SteakMasterChef: Treasury Wallet Cannot be 0x0');
        treasuryWallet = _walletAddress;

        emit SetTreasury(_walletAddress);
    }

    /// @notice sets the fee on rewards
    /// @param _fee is the percentage fee to take on rewards
    function setRewardFee(uint256 _fee) public onlyOwner {
        require(_fee <= 20, 'Pool Fee Too High');
        poolFee = _fee;

        emit SetRewardFee(_fee);
    }

    /// @notice withdraws without caring about rewards
    /// @param _pid is the pool to withdraw from
    /// EMERGENCY ONLY. Sensitive.
    /// Restricted to only owner.
    function emergencyWithdraw(uint256 _pid) onlyOwner external {
        PoolInfo storage pool = poolInfo[_pid];

        voter._emergencyWithdraw(pool.lpToken, _pid);

        uint256 balance = IERC20(pool.lpToken).balanceOf(address(this));

        pool.lpToken.transfer(msg.sender, balance);

        emit EmergencyWithdraw(msg.sender, _pid, balance);
    }
}