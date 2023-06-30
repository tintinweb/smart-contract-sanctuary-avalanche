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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./TokensInterface.sol";

/**
 * @title A hybrid ERC20/ERC1155 contract for NFTs supporting content enhancement and the SCI fungible token
 * @author ScieNFT Ltd.
 */
contract Tokens is
    IERC20,
    IERC20Metadata,
    IERC1155,
    IERC1155MetadataURI,
    AccessControl,
    TokensInterface
{
    /// @dev We implement the ERC1155 interface for NFTs, with SCI as a special case (token ID = 0).
    /// We additionally implement the ERC20 interface for the SCI token.

    // Mapping from token ID to the account balances map (ERC1155)
    mapping(uint64 => mapping(address => uint256)) private _balances;

    // Mapping from account to the operator approvals map (ERC1155)
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /// @dev We are implementing the ERC20 interface for SCI tokens
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply = 0;
    string private _name = "ScieNFT Utility Token";
    string private _symbol = "SCI";

    /// @dev Deploys this contract, assign roles or changes contract addresses (always 0x0)
    bytes32 public constant CEO_ROLE = AccessControl.DEFAULT_ADMIN_ROLE;
    /// @dev Withdraws minting and auction fees, sets minting and auction fees, withdraws collected fees
    bytes32 public constant CFO_ROLE = keccak256("TOKENS_CFO");
    /// @dev Set errata or blocklist flag on any NFT, mints NFTs with no fees and arbitrary data
    bytes32 public constant SUPERADMIN_ROLE = keccak256("TOKENS_SUPERADMIN");
    /// @dev Service role for marketplaces
    bytes32 public constant MARKETPLACE_ROLE = keccak256("TOKENS_MARKETPLACE");
    /// @dev Service role for a contract where NFTs can be staked by a cross chain bridge
    bytes32 public constant BRIDGE_ROLE = keccak256("TOKENS_BRIDGE");

    /// @dev Index of the SCI fungible token
    uint8 public constant SCI = 0;
    /// @dev NFTs are indexed as [FIRST_NFT...]
    uint8 public constant FIRST_NFT = 1;

    /// @dev The UNSET_FULL_BENEFIT_FLAG if true, the next marketplace transfer will clear FULL_BENEFIT_FLAG
    uint8 public constant UNSET_FULL_BENEFIT_FLAG = 1 << 0;
    /// @dev The FULL_BENEFIT_FLAG sets the marketplace royalty to 100%
    uint8 public constant FULL_BENEFIT_FLAG = 1 << 1;
    /// @dev The BLOCKLIST_FLAG marks an NFT as retracted on scienft.com
    uint8 public constant BLOCKLIST_FLAG = 1 << 2;
    /// @dev The BRIDGED_FLAG marks an NFT as staked to a bridge contract
    uint8 public constant BRIDGED_FLAG = 1 << 3;

    /// @dev Each NFT stores two linked lists of "ContentNodes" with IPFS addresses as key values
    /// Each mapping key is calculated as keccak256(tokenId, content hash, content type)
    mapping(bytes32 => TokensInterface.ContentNode) public contentNodes;

    /// @dev This contract introduces the "ScienceNFT": a record of scientific work on the blockchain
    /// Each mapping key is a token ID for an NFT
    mapping(uint64 => TokensInterface.ScienceNFT) public scienceNFTs;

    /// @dev NFTs are mapped starting from uint64(FIRST_NFT) to make room for fungible tokens
    uint64 private _nextNftId;

    /// @dev Fee charged to mint an NFT or to append a ContentNode, in native gas tokens / gwei
    uint256 public mintingFee;

    /// @dev Proof-of-Work Mining Support
    uint256 public miningFee;
    uint32 public miningIntervalSeconds;
    uint8 public difficulty;
    uint256 public lastMiningTimestamp = 0;
    bytes32 public lastMiningSolution = keccak256("SCIENFT");
    uint8 public miningGeneration = 0;
    uint256 public miningCount = 1;
    // set by contructor
    uint256 public minimumMiningYield;
    uint256 public miningYield;
    uint256 public maxTotalSupply;

    /// @dev The Owner controls transfers and may append content to the owner's content list
    /// Each mapping key is a token ID for an NFT
    mapping(uint64 => address) public ownerOf;

    /// @dev The Admin can set the FULL_BENEFIT_FLAG or BLOCKLIST_FLAG, can change the Beneficiary and Admin,
    ///      and may append content to the admin's content list
    /// Each mapping key is a token ID for an NFT
    mapping(uint64 => address) public adminOf;

    /// @dev The Beneficiary collects royalties for marketplace contract transfers
    /// Each mapping key is a token ID for an NFT
    mapping(uint64 => address) public beneficiaryOf;

    /**
     * @dev Constructor for the Token contract
     * @param uri_ ERC1155 metadata uri. See https://eips.ethereum.org/EIPS/eip-1155#metadata
     */
    constructor(
        string memory uri_,
        uint256 initialMiningYield,
        uint256 minimumMiningYield_,
        uint256 miningFee_,
        uint8 difficulty_,
        uint32 miningIntervalSeconds_,
        uint256 maxTotalSupply_,
        uint256 mintingFee_
    ) {
        // AccessControl limits grantRole() to the DEFAULT_ADMIN_ROLE = 0x0.
        // We want our CEO to be able to change the other assigned roles, so
        // we must either make the CEO_ROLE = 0x0 or call `_setRoleAdmin()` for
        // each other permissioned contract role.

        // _grantRole doesn't require the caller to already be an admin
        AccessControl._grantRole(CEO_ROLE, address(msg.sender));

        _setURI(uri_);

        miningYield = initialMiningYield;
        minimumMiningYield = minimumMiningYield_;
        miningFee = miningFee_;
        difficulty = difficulty_;
        miningIntervalSeconds = miningIntervalSeconds_;
        maxTotalSupply = maxTotalSupply_;

        mintingFee = mintingFee_;

        _nextNftId = uint64(FIRST_NFT);
    }

    /**
     * @dev ERC165 implementation
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC20).interfaceId;
    }

    /**
     * @dev Emit the NFTUpdated event
     * @param tokenId ERC1155 token index
     */
    function emitNFTUpdated(uint64 tokenId) internal {
        emit TokensInterface.NFTUpdated(
            tokenId,
            scienceNFTs[tokenId].status,
            ownerOf[tokenId],
            adminOf[tokenId],
            beneficiaryOf[tokenId]
        );
    }

    /**
     * @dev Transfer token
     * @param from Sender address
     * @param to Receiver address
     * @param id ERC1155 token index
     * @param amount Amount to transfer
     * @param data data bytes (ignored)
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not token owner or approved"
        );
        uint64 tokenId = uint64(id);
        if (tokenId >= uint64(FIRST_NFT)) {
            require(isMinted(tokenId), "Invalid NFT");
            require(!isBridged(tokenId), "NFT is bridged");
            ownerOf[tokenId] = to;
        }
        // -- WARNING --
        // This function allows arbitrary code execution, opening us to possible reentrancy attacks
        _safeTransferFrom(from, to, tokenId, amount, data);

        if (tokenId >= uint64(FIRST_NFT)) {
            emitNFTUpdated(tokenId);
        }
    }

    /**
     * @dev Batch transfer tokens
     * @param from Sender address
     * @param to Receiver address
     * @param ids List of ERC1155 token indexes
     * @param amounts List of amounts to transfer
     * @param data data bytes (ignored)
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not token owner or approved"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            uint64 tokenId = uint64(ids[i]);
            if (tokenId >= uint64(FIRST_NFT)) {
                require(isMinted(tokenId), "Invalid NFT");
                require(!isBridged(tokenId), "NFT is bridged");
                ownerOf[tokenId] = to;
            }
        }

        // -- WARNING --
        // This function allows arbitrary code execution, opening us to possible reentrancy attacks
        _safeBatchTransferFrom(from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            uint64 tokenId = uint64(ids[i]);
            if (tokenId >= uint64(FIRST_NFT)) {
                emitNFTUpdated(tokenId);
            }
        }
    }

    /**
     * @dev Return true if NFT token has been minted
     * @param tokenId ERC1155 token index
     */
    function isMinted(uint64 tokenId) public view returns (bool) {
        return tokenId >= uint64(FIRST_NFT) && tokenId < _nextNftId;
    }

    /**
     * @dev Return true if BLOCKLIST_FLAG is true ("NFT has been blocklisted from ScieNFT.")
     * @param tokenId ERC1155 token index
     */
    function isBlocklisted(uint64 tokenId) external view returns (bool) {
        return (scienceNFTs[tokenId].status & uint192(BLOCKLIST_FLAG)) != 0;
    }

    /**
     * @dev Return true if FULL_BENEFIT_FLAG is true ("NFT royalty is 100% of sale price.")
     * @param tokenId ERC1155 token index
     */
    function isFullBenefit(uint64 tokenId) external view returns (bool) {
        return (scienceNFTs[tokenId].status & uint192(FULL_BENEFIT_FLAG)) != 0;
    }

    /**
     * @dev Return true if UNSET_FULL_BENEFIT_FLAG is true
     *      ("FULL_BENEFIT_FLAG will be unset on next marketplace transfer.")
     * @param tokenId ERC1155 token index
     */
    function willUnsetFullBenefit(uint64 tokenId) external view returns (bool) {
        return
            (scienceNFTs[tokenId].status & uint192(UNSET_FULL_BENEFIT_FLAG)) !=
            0;
    }

    /**
     * @dev Return true if BRIDGED_FLAG is true ("NFT is locked in a bridge contract.")
     * @param tokenId ERC1155 token index
     */
    function isBridged(uint64 tokenId) public view returns (bool) {
        return (scienceNFTs[tokenId].status & uint192(BRIDGED_FLAG)) != 0;
    }

    /**
     * @dev Returns true when "solution" is a valid mining answer
     * @param solution the solution to the hash difficulty puzzle
     */
    function isCorrect(bytes32 solution) public view returns (bool) {
        if (difficulty == 0) {
            return true;
        }
        uint256 x = uint256(
            keccak256(abi.encodePacked(lastMiningSolution, solution))
        );
        uint8 n = difficulty;
        for (uint8 i = 255; i >= 0; i--) {
            if (x & (1 << i) == 0) {
                n -= 1;
                if (n == 0) {
                    return true;
                }
            } else {
                break;
            }
        }
        return false;
    }

    /**
     * @dev Mine ScieNFT Utility Tokens
     * @param solution the solution to the hash difficulty puzzle
     * @param to address that will receive the mined SCI tokens
     */
    function mineSCI(bytes32 solution, address to) external payable {
        require(msg.value == miningFee, "Wrong mining fee");
        require(_totalSupply < maxTotalSupply, "Maximum supply has been mined");
        require(isCorrect(solution), "Wrong solution");

        // lastMiningTimestamp is only ever 0 or block.timestamp, so this is safe
        uint256 delta = block.timestamp - lastMiningTimestamp;

        require(
            delta > miningIntervalSeconds,
            "Mining interval has not elapsed"
        );

        uint256 yield = miningYield;

        lastMiningSolution = solution;
        lastMiningTimestamp = block.timestamp;
        _totalSupply += yield;
        miningCount -= 1;
        if (miningCount == 0) {
            miningGeneration += 1;
            miningCount = uint256(1) << miningGeneration;
            miningYield = yield >> 2;
            // enforce minimum miningYield
            if (miningYield < minimumMiningYield) {
                miningYield = minimumMiningYield;
            }
        }

        _mint(to, uint256(SCI), yield, bytes(""));
    }

    /**
     * @dev Add a new NFT to the database (internal use only)
     * @param contentHash The first CIDv1 sha256 hex hash value for the NFT, to be added as the head of the admin content list.
     * @param createdAt Publication priority timestamp uint64 (set from block.timestamp in mintNFT)
     * @param status Full status bits
     * @param owner Address of token owner
     * @param admin Address of token admin
     * @param beneficiary Address of token beneficiary
     */
    function createNFT(
        bytes32 contentHash,
        uint64 createdAt,
        uint192 status,
        address owner,
        address admin,
        address beneficiary
    ) internal {
        require(contentHash != 0x0, "Invalid content");

        uint64 tokenId = _nextNftId;

        // create the new NFT record
        ScienceNFT storage newNFT = scienceNFTs[tokenId];
        newNFT.adminHash = contentHash;
        newNFT.createdAt = createdAt;
        newNFT.status = status;

        ownerOf[tokenId] = owner;
        adminOf[tokenId] = admin;
        beneficiaryOf[tokenId] = beneficiary;

        _mint(owner, tokenId, 1, bytes(""));

        _nextNftId++;

        emitNFTUpdated(tokenId);
        emit TokensInterface.AdminContentNodeCreated(
            tokenId,
            newNFT.adminHash,
            0x0
        );
    }

    /**
     * @dev Mint a new non-fungible token (from any adddress)
     * @param contentHash The first CIDv1 sha256 hex hash value for the NFT, to be added as the head of the admin content list.
     * @param status Full status bits
     * @param owner Address of token owner
     * @param admin Address of token admin
     * @param beneficiary Address of token beneficiary
     */
    function mintNFT(
        bytes32 contentHash,
        uint192 status,
        address owner,
        address admin,
        address beneficiary
    ) public payable {
        require(msg.value == mintingFee, "Wrong minting fee");
        uint64 createdAt = uint64(block.timestamp);

        createNFT(contentHash, createdAt, status, owner, admin, beneficiary);
    }

    /**
     * @dev Mint a new non-fungible token with default values (from any adddress)
     * @param contentHash The first CIDv1 sha256 hex hash value for the NFT, to be added as the head of the admin content list.
     */
    function mintNFT(bytes32 contentHash) external payable {
        require(msg.value == mintingFee, "Wrong minting fee");
        uint192 status = uint192(UNSET_FULL_BENEFIT_FLAG | FULL_BENEFIT_FLAG);
        uint64 createdAt = uint64(block.timestamp);

        createNFT(
            contentHash,
            createdAt,
            status,
            msg.sender,
            msg.sender,
            msg.sender
        );
    }

    /**
     * @dev Mint NFT with arbitrary parameters and no minting fee (from SUPERADMIN_ROLE)
     * @param contentHash The first CIDv1 sha256 hex hash value for the NFT, to be added as the head of the admin content list.
     * @param createdAt Publication priority timestamp uint64 (set from block.timestamp in mintNFT)
     * @param status Full status bits
     * @param owner Address of token owner
     * @param admin Address of token admin
     * @param beneficiary Address of token beneficiary
     */
    function superadminMintNFT(
        bytes32 contentHash,
        uint64 createdAt,
        uint192 status,
        address owner,
        address admin,
        address beneficiary
    ) external {
        require(hasRole(SUPERADMIN_ROLE, msg.sender), "Only SUPERADMIN");

        createNFT(contentHash, createdAt, status, owner, admin, beneficiary);
    }

    /**
     * @dev Return the key value where a contentHash entry is stored in the mapping
     * @param tokenId ERC1155 token index
     * @param contentHash The target IPFS hex hash value to find in the indicated list
     * @param contentType The content list of interest (ADMIN or OWNER)
     *
     * exposing this function makes it easier to do list traversal as a client
     */
    function getContentNodeKey(
        uint64 tokenId,
        bytes32 contentHash,
        ContentType contentType
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, contentHash, contentType));
    }

    /**
     * @dev Return the previous and next IPFS hash in a content list (or 0x0 if at the head/tail)
     * @param tokenId ERC1155 token index
     * @param contentHash The target IPFS hex hash value to find in the indicated list
     * @param contentType The content list of interest (ADMIN or OWNER)
     *
     * If `currentData` does not match any known IPFS content for the provided NFT/list we reject as invalid.
     */
    function getAdjacentContent(
        uint64 tokenId,
        bytes32 contentHash,
        TokensInterface.ContentType contentType
    ) public view returns (bytes32 prevContentHash, bytes32 nextContentHash) {
        require(isMinted(tokenId), "Invalid NFT");
        require(contentHash != 0x0, "Invalid content");

        // start at the head of the list
        prevContentHash = 0x0;

        // note enter into the list from adminHash, branching on contentType in the key
        bytes32 currentContentHash = scienceNFTs[tokenId].adminHash;
        bytes32 nextKey = getContentNodeKey(
            tokenId,
            currentContentHash,
            contentType
        );
        nextContentHash = contentNodes[nextKey].contentHash; // 0x0 if curr is the last IPFS hash value

        // force prev to 0x0 for the special case of an empty owner content list
        if (contentType == ContentType.OWNER) {
            currentContentHash = 0x0;
        }
        // traverse to the tail of the list
        bool found = contentHash == currentContentHash;

        while (!found && nextContentHash != 0x0) {
            prevContentHash = currentContentHash;
            currentContentHash = nextContentHash;

            nextKey = getContentNodeKey(
                tokenId,
                currentContentHash,
                contentType
            );
            nextContentHash = contentNodes[nextKey].contentHash; // 0x0 when at the tail

            found = contentHash == currentContentHash;
        }

        // check if we found currentData or not
        require(found, "Content not found");

        return (prevContentHash, nextContentHash);
    }

    /**
     * @dev Append a new content node to an NFT (internal use only)
     * @param tokenId ERC1155 token index
     * @param contentHash The new CIDv1 sha256 hex hash value to append to the NFT
     * @param contentType The content list of interest (ADMIN or OWNER)
     * @param createdAt Publication priority timestamp uint64 (set from block.timestamp in mintNFT)
     */
    function appendNewContent(
        uint64 tokenId,
        bytes32 contentHash,
        TokensInterface.ContentType contentType,
        uint64 createdAt
    ) internal {
        require(isMinted(tokenId), "Invalid NFT");
        require(contentHash != 0x0, "Invalid content");

        // start at the head of the list
        bytes32 prevContentHash = 0x0;

        // note enter into the list from adminHash, branching on contentType in the key
        bytes32 currentContentHash = scienceNFTs[tokenId].adminHash;
        bytes32 nextKey = getContentNodeKey(
            tokenId,
            currentContentHash,
            contentType
        );
        bytes32 nextContentHash = contentNodes[nextKey].contentHash; // 0x0 if curr is the last IPFS hash value

        // refuse to append identical content records to an NFT
        require(contentHash != currentContentHash, "Duplicate content");

        // force prev to 0x0 for the special case of an empty owner content list
        if (contentType == ContentType.OWNER) {
            currentContentHash = 0x0;
        }

        // traverse to the tail of the list
        while (nextContentHash != 0x0) {
            currentContentHash = nextContentHash;

            require(contentHash != currentContentHash, "Duplicate content");
            nextKey = getContentNodeKey(
                tokenId,
                currentContentHash,
                contentType
            );
            nextContentHash = contentNodes[nextKey].contentHash; // 0x0 when at the tail
        }

        // we will append a new value after currentContentHash, so it will be the prev
        prevContentHash = currentContentHash;

        // append the new content at the tail
        // note this is a little tricky because we are using `n-1` ContentNodes to represent the list of
        // `n` IPFS hex hash values. After traversing the list above, nextKey contains the "pointer" to
        // the memory location where the new IPFS hex hash value should be appended
        ContentNode storage newLastNode = contentNodes[nextKey]; // newLastNode is a new entry in the mapping!
        newLastNode.tokenId = tokenId;
        newLastNode.contentHash = contentHash;
        newLastNode.createdAt = createdAt;

        if (contentType == ContentType.OWNER) {
            emit TokensInterface.OwnerContentNodeCreated(
                newLastNode.tokenId,
                newLastNode.contentHash,
                prevContentHash
            );
        } else {
            // contentType = ContentType.ADMIN
            emit TokensInterface.AdminContentNodeCreated(
                newLastNode.tokenId,
                newLastNode.contentHash,
                prevContentHash
            );
        }
    }

    /**
     * @dev Append new content to an NFT (from any address)
     * @param tokenId ERC1155 token index
     * @param contentHash The target IPFS hex hash value to find in the indicated list
     * @param contentType The content list of interest (ADMIN or OWNER)
     */
    function appendContent(
        uint64 tokenId,
        bytes32 contentHash,
        TokensInterface.ContentType contentType
    ) public payable {
        require(isMinted(tokenId), "Invalid NFT");
        require(msg.value == mintingFee, "Wrong minting fee");
        require(!isBridged(tokenId), "NFT is bridged");
        if (contentType == ContentType.OWNER) {
            require(balanceOf(msg.sender, tokenId) > 0, "Only OWNER");
        } else {
            // contentType = ContentType.ADMIN
            require(msg.sender == adminOf[tokenId], "Only ADMIN");
        }
        appendNewContent(
            tokenId,
            contentHash,
            contentType,
            uint64(block.timestamp)
        );
    }

    /**
     * @dev Append new content to an NFT with no fees (as SUPERADMIN_ROLE)
     * @param tokenId ERC1155 token index
     * @param contentHash The target IPFS hex hash value to find in the indicated list
     * @param contentType The content list of interest (ADMIN or OWNER)
     * @param createdAt Publication priority timestamp uint64
     */
    function superadminAppendContent(
        uint64 tokenId,
        bytes32 contentHash,
        TokensInterface.ContentType contentType,
        uint64 createdAt
    ) public {
        require(isMinted(tokenId), "Invalid NFT");
        require(hasRole(SUPERADMIN_ROLE, msg.sender), "Only SUPERADMIN");
        require(!isBridged(tokenId), "NFT is bridged");
        appendNewContent(tokenId, contentHash, contentType, createdAt);
    }

    /**
     * @dev Set minting fee from CFO_ROLE (in gas token to avoid needing extra permissions)
     * @param newMintingFee New minting fee amount
     */
    function setMintingFee(uint256 newMintingFee) external {
        require(hasRole(CFO_ROLE, msg.sender), "Only CFO");
        mintingFee = newMintingFee;
        emit TokensInterface.MintingFeeSet(mintingFee);
    }

    /**
     * @dev Set mining fee from CFO_ROLE (in gas token to avoid needing extra permissions)
     * @param newMiningFee New minting fee amount
     */
    function setMiningFee(uint256 newMiningFee) external {
        require(hasRole(CFO_ROLE, msg.sender), "Only CFO");
        miningFee = newMiningFee;
        emit TokensInterface.MiningFeeSet(miningFee);
    }

    /**
     * @dev Set mining difficulty
     * @param newDifficulty number of leading hash zeros
     */
    function setDifficulty(uint8 newDifficulty) external {
        require(hasRole(CFO_ROLE, msg.sender), "Only CFO");
        difficulty = newDifficulty;
        emit TokensInterface.DifficultySet(difficulty);
    }

    /**
     * @dev Set mining interval in seconds
     * @param newInterval seconds that must elapse between mining calls
     */
    function setMiningInterval(uint32 newInterval) external {
        require(hasRole(CFO_ROLE, msg.sender), "Only CFO");
        miningIntervalSeconds = newInterval;
        emit TokensInterface.MiningIntervalSet(miningIntervalSeconds);
    }

    /**
     * @dev Withdraw collected fees from CFO_ROLE
     * @param to address that receives fees
     * @param value amount to send
     */
    function withdraw(address payable to, uint256 value) external {
        require(hasRole(CFO_ROLE, msg.sender), "Only CFO");
        require(address(this).balance >= value, "Value exceeds balance");
        to.transfer(value);
    }

    /**
     * @dev Withdraw SCI sent to contract address in error (as CFO_ROLE)
     * @param to address that receives fees
     * @param value amount to send
     *
     * It is impossible to send an NFT to the contract because it will be
     * rejected in fallback after the transfer acceptance check fails, however
     * SCI can be sent to the contract using the ERC20 mechanism
     */
    function withdrawSCI(address to, uint256 value) external {
        require(hasRole(CFO_ROLE, msg.sender), "Only CFO");
        require(balanceOf(address(this)) >= value, "Value exceeds balance");
        this.transfer(to, value);
    }

    /**
     * @dev Change admin of an NFT, from adminOf[tokenId]
     * @param tokenId ID of an NFT
     * @param newAdmin Address of new admin
     */
    function setAdmin(uint64 tokenId, address newAdmin) external {
        require(isMinted(tokenId), "Invalid NFT");
        require(msg.sender == adminOf[tokenId], "Only ADMIN");
        require(!isBridged(tokenId), "NFT is bridged");

        adminOf[tokenId] = newAdmin;

        emitNFTUpdated(tokenId);
    }

    /**
     * @dev Change beneficiary of an NFT, from adminOf[tokenId]
     * @param tokenId ID of an NFT
     * @param newBeneficiary Address of new beneficiary
     */
    function setBeneficiary(uint64 tokenId, address newBeneficiary) external {
        require(isMinted(tokenId), "Invalid NFT");
        require(msg.sender == adminOf[tokenId], "Only ADMIN");
        require(!isBridged(tokenId), "NFT is bridged");

        beneficiaryOf[tokenId] = newBeneficiary;

        emitNFTUpdated(tokenId);
    }

    /**
     * @dev Set the full status bits for an NFT, from SUPERADMIN_ROLE
     * @param tokenId ID of an NFT
     * @param newStatus new status bits
     */
    function setStatus(uint64 tokenId, uint192 newStatus) external {
        require(isMinted(tokenId), "Invalid NFT");
        require(hasRole(SUPERADMIN_ROLE, msg.sender), "Only SUPERADMIN");
        require(!isBridged(tokenId), "NFT is bridged");

        scienceNFTs[tokenId].status = newStatus;

        emitNFTUpdated(tokenId);
    }

    /**
     * @dev Block an NFT from ScieNFT platforms, from SUPERADMIN_ROLE
     * @param tokenId ID of an NFT
     * @param value new BLOCKLIST_FLAG value
     */
    function blocklist(uint64 tokenId, bool value) external {
        require(isMinted(tokenId), "Invalid NFT");
        require(hasRole(SUPERADMIN_ROLE, msg.sender), "Only SUPERADMIN");
        require(!isBridged(tokenId), "NFT is bridged");

        if (value) scienceNFTs[tokenId].status |= uint192(BLOCKLIST_FLAG);
        else scienceNFTs[tokenId].status &= ~(uint192(BLOCKLIST_FLAG));

        emitNFTUpdated(tokenId);
    }

    /**
     * @dev Set full benefit flag, as the NFT owner
     * @param tokenId ID of an NFT
     * @param value new FULL_BENEFIT_FLAG value
     */
    function setFullBenefitFlag(uint64 tokenId, bool value) external {
        require(isMinted(tokenId), "Invalid NFT");
        require(balanceOf(msg.sender, tokenId) > 0, "Only OWNER");
        require(!isBridged(tokenId), "NFT is bridged");

        if (value) scienceNFTs[tokenId].status |= uint192(FULL_BENEFIT_FLAG);
        else scienceNFTs[tokenId].status &= ~(uint192(FULL_BENEFIT_FLAG));

        emitNFTUpdated(tokenId);
    }

    /**
     * @dev Allows a marketplace to set flags and trigger an event
     * @param tokenId ID of an NFT
     * @param soldAt epoch timestamp to report as the time of sale
     * @param buyer buyer
     * @param price the price buyer paid
     * @param seller seller
     * @param beneficiary address paid the royalty
     * @param royalty the royalty paid
     */
    function reportMarketplaceSale(
        uint64 tokenId,
        uint64 soldAt,
        address buyer,
        uint256 price,
        address seller,
        address beneficiary,
        uint256 royalty
    ) external {
        require(hasRole(MARKETPLACE_ROLE, msg.sender), "Only MARKETPLACE");
        // remove FULL_BENEFIT_FLAG on marketplace transfers if the UNSET_FULL_BENEFIT_FLAG is true
        if (
            (scienceNFTs[tokenId].status & uint192(UNSET_FULL_BENEFIT_FLAG)) !=
            0
        ) {
            scienceNFTs[tokenId].status &= ~(
                uint192((FULL_BENEFIT_FLAG | UNSET_FULL_BENEFIT_FLAG))
            );
            emitNFTUpdated(tokenId);
        }
        emit TokensInterface.MarketplaceSale(
            tokenId,
            soldAt,
            buyer,
            price,
            seller,
            beneficiary,
            royalty
        );
    }

    /**
     * @dev Marks an NFT as moved to a different contract, from OWNER
     * @param tokenId ID of an NFT
     * @param bridge the bridge address
     * This is called by the BRIDGE after it has received the staked NFT
     */
    function withdrawFromContract(uint64 tokenId, address bridge) external {
        require(isMinted(tokenId), "Invalid NFT");
        require(!isBridged(tokenId), "NFT is bridged");
        require(balanceOf(msg.sender, tokenId) > 0, "Only OWNER");
        require(hasRole(BRIDGE_ROLE, bridge), "Invalid BRIDGE");

        safeTransferFrom(msg.sender, bridge, tokenId, 1, "");
        scienceNFTs[tokenId].status |= uint192(BRIDGED_FLAG);

        emitNFTUpdated(tokenId);
    }

    /**
     * @dev Restores an NFT that was marked as bridged with its latest data, from BRIDGE_ROLE
     * @param tokenId ID of an NFT
     * @param status Status info as uint192
     * @param owner Address of token owner
     * @param admin Address of token admin
     * @param beneficiary Address of token beneficiary
     *
     * This is called by the BRIDGE after it has sent the NFT back to its owner
     */
    function restoreToContract(
        uint64 tokenId,
        uint192 status,
        address owner,
        address admin,
        address beneficiary
    ) external {
        require(isMinted(tokenId), "Invalid NFT");
        require(isBridged(tokenId), "NFT is not bridged");
        require(hasRole(BRIDGE_ROLE, msg.sender), "Only BRIDGE");
        require(
            owner != address(0),
            "Invalid OWNER: transfer to the zero address"
        );

        ScienceNFT storage restoredNFT = scienceNFTs[tokenId];

        restoredNFT.status = status & ~(uint192(BRIDGED_FLAG));
        ownerOf[tokenId] = owner;
        adminOf[tokenId] = admin;
        beneficiaryOf[tokenId] = beneficiary;

        safeTransferFrom(msg.sender, owner, tokenId, 1, "");

        emitNFTUpdated(tokenId);
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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return balanceOf(account, uint256(SCI));
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
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
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = msg.sender;
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
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Moves `amount` of SCI tokens from `from` to `to`.
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
        uint256 fromBalance = balanceOf(from);
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
            _balances[uint64(SCI)][from] = fromBalance - amount;
        }
        _balances[uint64(SCI)][to] += amount;

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Destroys `amount` SCI tokens for msg.sender, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - sender cannot be the zero address.
     * - sender must have at least `amount` tokens.
     */
    function burn(uint256 amount) external {
        uint256 accountBalance = balanceOf(msg.sender);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _totalSupply -= amount;
            _balances[uint64(SCI)][msg.sender] = accountBalance - amount;
        }
        emit Transfer(msg.sender, address(0), amount);
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
    function uri(uint256) public view virtual returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256) {
        require(
            account != address(0),
            "ERC1155: address zero is not a valid owner"
        );
        return _balances[uint64(id)][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev batch version of setApprovalForAll
     */
    function setApprovalForAllBatch(
        address[] memory operators,
        bool[] memory approvals
    ) public virtual {
        require(
            operators.length == approvals.length,
            "operators and approvals length mismatch"
        );
        for (uint256 i = 0; i < approvals.length; ++i) {
            _setApprovalForAll(msg.sender, operators[i], approvals[i]);
        }
    }

    /**
     * @dev batch version of isApprovedForAll
     */
    function isApprovedForAllBatch(
        address[] memory accounts,
        address[] memory operators
    ) public view virtual returns (bool[] memory) {
        require(
            accounts.length == operators.length,
            "accounts and operators length mismatch"
        );
        bool[] memory approvals = new bool[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            approvals[i] = isApprovedForAll(accounts[i], operators[i]);
        }
        return approvals;
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

        address operator = msg.sender;

        uint256 fromBalance = _balances[uint64(id)][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[uint64(id)][from] = fromBalance - amount;
        }
        _balances[uint64(id)][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        // -- WARNING --
        // This function allows arbitrary code execution, opening us to possible reentrancy attacks
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
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[uint64(id)][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[uint64(id)][from] = fromBalance - amount;
            }
            _balances[uint64(id)][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        // -- WARNING --
        // note This function allows arbitrary code execution, opening us to possible reentrancy attacks
        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
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

        address operator = msg.sender;

        _balances[uint64(id)][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        // -- WARNING --
        // This function allows arbitrary code execution, opening us to possible reentrancy attacks
        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
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

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        // this check is openzeppelin's Address "isContract()"
        if (to.code.length > 0) {
            try
                // -- WARNING --
                // This function allows arbitrary code execution, opening us to possible reentrancy attacks
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
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
        // this check is openzeppelin's Address "isContract()"
        if (to.code.length > 0) {
            try
                // -- WARNING --
                // This function allows arbitrary code execution, opening us to possible reentrancy attacks
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    /**
     * @dev reject gas tokens
     */
    receive() external payable {
        revert("receive() reverts");
    }

    /**
     * @dev refuse unknown calls
     */
    fallback() external {
        revert("fallback() reverts");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface TokensInterface {
    /**
     * @dev An onchain data record for scientific work
     * @param adminHash An IPFS sha256 hex hash value that links to a JSON file providing
     *                     (e.g. title, summary, authorship, files, checksums, etc.)
     *
     * If the NFT contains more than one IPFS hex hash link, then `content` is additionally a key
     * value into the mapping that stores ContentNodes. One way to think about this is that we implicitly have:
     *
     *     *nextOwnerHash = map key @ keccak256(tokenId, ownerHash, ContentType.OWNER)
     *     *nextAdminHash = map key @ keccak256(tokenId, adminHash, ContentType.ADMIN)
     *
     * available in the ScienceNFT struct (and similar implicit pointers in any ContentNode).
     *
     * Because ownerHash is always empty in a new NFT, we make a special key to access the head of
     * the ownerContent list = keccak256(tokenId, adminHash, ContentType.OWNER)
     *
     * @param createdAt Unix epoch timestamp recording the priority date for the NFT
     * @param status Efficient storage of flag bits and other information
     */
    struct ScienceNFT {
        bytes32 adminHash;
        uint64 createdAt;
        uint192 status;
    }

    /**
     * @dev A node used with a linked list of IPFS hex hashes that is storage-efficient in hashtable memory
     *      ContentNodes are stored using a mapping where the key encodes the equivalent of the "next" pointer value.
     *
     * keccak256(tokenId, scienceNFTs[tokenId].(content hash), ContentType enum) --> ContentNode
     *
     * Note that while we're using a linked list structure, it's not a traditional singly-linked list
     * where each node explicitly stores the address of the next node. The first IPFS value (head) is stored in a ScienceNFT struct.
     * If an IPFS hex hash value is the tail of the list, there is no matching key value in the hashtable (i.e., being the
     * tail of the list is signified by a missing entry in the mapping). The next value's address is calculated when needed,
     * and the value itself appears as the `contentHash` stored at the key's location in the map
     *
     * The key formula is needed to allow NFTs to store duplicate content. However we do not allow the same content hash to appear
     * twice within a single NFT content list.
     *
     * @param contentHash A CIDv1 IPFS sha256 hex hash.
     *                    We are at the tail of the list when there is no entry in the mapping for a key built from the hash
     * @param createdAt Unix epoch timestamp recording the priority date for the content (i.e. key value)
     * @param tokenId The token that owns this node (allows us to look up Admin and Owner addresses for permission checks)
     *                - If tokenId is zero, then no node exists in the mapping for the provided key value
     *                - By returning to the ScienceNFT record and traversing lists, we can find `next` and `prev` hash values
     */
    struct ContentNode {
        bytes32 contentHash;
        uint64 createdAt;
        uint64 tokenId;
    }

    /**
     * @dev We will indicate which list is of interest with an enum
     * @note Adding fields to this enum will break things
     **/
    enum ContentType {
        OWNER,
        ADMIN
    }

    // Events
    event MintingFeeSet(uint256 mintingFee);
    event MiningFeeSet(uint256 miningFee);
    event DifficultySet(uint8 difficulty);
    event MiningIntervalSet(uint32 interval);
    event NFTUpdated(
        uint64 indexed tokenId,
        uint192 status,
        address indexed owner,
        address admin,
        address indexed beneficiary
    );
    event AdminContentNodeCreated(
        uint64 indexed tokenId,
        bytes32 indexed data,
        bytes32 indexed prev
    );
    event OwnerContentNodeCreated(
        uint64 indexed tokenId,
        bytes32 indexed data,
        bytes32 indexed prev
    );
    event MarketplaceSale(
        uint64 indexed tokenId,
        uint64 soldAt,
        address indexed buyer,
        uint256 price,
        address seller,
        address indexed beneficiary,
        uint256 royalty
    );

    // NFT Database Management
    function mintNFT(bytes32 data) external payable;

    function mintNFT(
        bytes32 data,
        uint192 status,
        address owner,
        address admin,
        address beneficiary
    ) external payable;

    function superadminMintNFT(
        bytes32 data,
        uint64 createdAt,
        uint192 status,
        address owner,
        address admin,
        address beneficiary
    ) external;

    function setAdmin(uint64 tokenId, address newAdmin) external;

    function setBeneficiary(uint64 tokenId, address newBeneficiary) external;

    function reportMarketplaceSale(
        uint64 tokenId,
        uint64 soldAt,
        address buyer,
        uint256 price,
        address seller,
        address beneficiary,
        uint256 royalty
    ) external;

    // NFT Content Management
    function appendContent(
        uint64 tokenId,
        bytes32 contentHash,
        ContentType contentType
    ) external payable;

    function superadminAppendContent(
        uint64 tokenId,
        bytes32 contentHash,
        ContentType contentType,
        uint64 createdAt
    ) external;

    // NFT Database and Content Queries
    function isMinted(uint64 tokenId) external view returns (bool);

    function getContentNodeKey(
        uint64 tokenId,
        bytes32 contentHash,
        ContentType contentType
    ) external pure returns (bytes32);

    function getAdjacentContent(
        uint64 tokenId,
        bytes32 contentHash,
        ContentType contentType
    ) external view returns (bytes32 prevContentHash, bytes32 nextContentHash);

    // NFT Status Bit Queries
    function isBlocklisted(uint64 tokenId) external view returns (bool);

    function isFullBenefit(uint64 tokenId) external view returns (bool);

    function willUnsetFullBenefit(uint64 tokenId) external view returns (bool);

    function isBridged(uint64 tokenId) external view returns (bool);

    // NFT Status Bit Control

    function blocklist(uint64 tokenId, bool value) external;

    function setFullBenefitFlag(uint64 tokenId, bool value) external;

    function setStatus(uint64 tokenId, uint192 newStatus) external;

    // Transfer of NFTs to and from bridge contracts.
    function withdrawFromContract(uint64 tokenId, address bridge) external;

    function restoreToContract(
        uint64 tokenId,
        uint192 status,
        address owner,
        address admin,
        address beneficiary
    ) external;

    // Mining SCI tokens
    function setMiningInterval(uint32 newIntervalSeconds) external;

    function setDifficulty(uint8 newDifficulty) external;

    function isCorrect(bytes32 solution) external view returns (bool);

    function mineSCI(bytes32 solution, address to) external payable;

    // Destroying SCI Tokens
    function burn(uint256 amount) external;

    // Fee Management
    /**
     * @dev Fees are paid in gas tokens / gwei
     */
    function setMintingFee(uint256 newMintingFee) external;

    function setMiningFee(uint256 newMiningFee) external;

    function withdraw(address payable to, uint256 value) external;

    function withdrawSCI(address to, uint256 value) external;
}