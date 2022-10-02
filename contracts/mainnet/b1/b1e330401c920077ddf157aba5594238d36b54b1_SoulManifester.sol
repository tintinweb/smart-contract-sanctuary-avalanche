/**
 *Submitted for verification at snowtrace.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/access/IAccessControl.sol
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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: contracts/libraries/SafeERC20.sol

pragma solidity >=0.8.0;

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
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// File: contracts/interfaces/IToken.sol

pragma solidity >=0.8.0;

// interface used for interacting with SOUL & SEANCE
interface IToken {
    function mint(address to, uint amount) external;
    function burn(address from, uint amount) external;
    function safeSoulTransfer(address to, uint amount) external;
    function balanceOf(address account) external returns (uint balance);
}

// File: contracts/rewards/SoulManifester.sol

pragma solidity >=0.8.0;

// manifester of new souls
contract SoulManifester is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // user info
    struct Users {
        uint amount;            // deposited amount.
        uint rewardDebt;        // reward debt (see: pendingSoul).
        uint withdrawalTime;    // last withdrawal time.
        uint depositTime;       // first deposit time.
        uint timeDelta;         // seconds accounted for in fee calculation.
        uint deltaDays;         // days accounted for in fee calculation

        // the following occurs when a user +/- tokens to a pool:
        //   1. pool: `accSoulPerShare` and `lastRewardTime` update.
        //   2. user: receives pending reward.
        //   3. user: `amount` updates (+/-).
        //   4. user: `rewardDebt` updates (+/-).
        //   5. user: [if] first-timer, 
            // [then] `depositTime` updates,
            // [else] `withdrawalTime` updates.
    }

    // pool info
    struct Pools {
        IERC20 lpToken;       // lp token contract.
        uint allocPoint;      // allocation points, which determines SOUL distribution per second.
        uint lastRewardTime;  // latest SOUL distribution in the pool.
        uint accSoulPerShare; // accumulated SOUL per share (times 1e12).
        uint feeDays;         // days during which a fee applies (aka startRate or feeDuration).
    }

    // team addresses
    address private team; // receives 1/8 soul supply
    address public dao; // recieves 1/8 soul supply

    // soul & seance addresses
    address private soulAddress;
    address private seanceAddress;

    // tokens: soul & seance
    IToken public soul;
    IToken public seance;

    // rewarder variables: used to calculate share of overall emissions.
    uint public totalWeight;
    uint public weight;

    // global daily SOUL
    uint private globalDailySoul = 250_000;

    // local daily SOUL
    uint public dailySoul; // = weight * globalDailySoul * 1e18;

    // rewards per second for this rewarder
    uint public soulPerSecond; // = dailySoul / 86_400;

    // marks the beginning of soul rewards.
    uint public startTime;

    // total allocation points: must be the sum of all allocation points
    uint public totalAllocPoint;
    
    // limits the maximum days to wait for a fee-less withdrawal.
    uint public immutable maxFeeDays = toWei(100);

    // emergency state
    bool private isEmergency;

    // activation state
    bool private isActivated;

    // pool info
    Pools[] public poolInfo;

    // user info
    mapping (uint => mapping (address => Users)) public userInfo;

    // divine roles
    bytes32 public isis; // soul summoning goddess of magic
    bytes32 public maat; // goddess of cosmic order

    // restricts: function to the council of the role passed as an object to obey (role)
    modifier obey(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    // controls: emergencyWithdrawals.
    modifier emergencyActive {
        require(isEmergency, 'emergency mode is not active.');
        _;
    }

    // proxy for pausing contract.
    modifier isActive {
        require(isActivated, 'contract is currently paused');
        _;
    }

    // validates: pool exists
    modifier validatePoolByPid(uint pid) {
        require(pid < poolInfo.length, 'pool does not exist');
        _;
    }

    /*/ events /*/
    event Deposit(address indexed user, uint indexed pid, uint amount, uint timestamp);
    event Withdraw(address indexed user, uint indexed pid, uint amount, uint feeAmount, uint timestamp);
    event Initialized(uint weight, uint timestamp);
    event PoolAdded(uint pid, uint allocPoint, IERC20 lpToken, uint totalAllocPoint);
    event PoolSet(uint pid, uint allocPoint, uint totalAllocPoint, uint absDelta, uint timestamp);
    event WeightUpdated(uint weight, uint totalWeight);
    event RewardsUpdated(uint dailySoul, uint soulPerSecond);
    event FeeDaysUpdated(uint pid, uint feeDays);
    event AccountsUpdated(address dao, address team);
    event TokensUpdated(address soul, address seance);
    event DepositRevised(uint pid, address account, uint timestamp);
    event EmergencyWithdraw(address indexed user, uint indexed pid, uint amount, uint timestamp);

    // channels: power to the divine goddesses isis & ma'at
    constructor() {
        // sets: user addresses
        team = 0x221cAc060A2257C8F77B6eb1b03e36ea85A1675A;
        dao = 0xf551D88fE8fae7a97292d28876A0cdD49dC373fa;

        // sets: roles
        isis = keccak256("isis"); // goddess of magic (who creates pools)
        maat = keccak256("maat"); // goddess of cosmic order (who allocates emissions)

        // divines: role admins
        _divinationCeremony(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE, msg.sender);
        _divinationCeremony(isis, isis, msg.sender); // isis role created -- supreme divined admin
        _divinationCeremony(maat, isis, msg.sender); // maat role created -- isis divined admin

        // sets: `startTime`
        startTime = block.timestamp;

        // sets: `soul` & `seance`
        setTokens(0x11d6DD25c1695764e64F439E32cc7746f3945543, 0x97Ee3C9Cf4E5DE384f95e595a8F327e65265cC4E);
    
        // sets: `weight`, `totalWeight`, `dailySoul` & `soulPerSecond`
        updateWeight(1, 1_000);

        // adds: staking pool (allocation: 1,000 & withdrawFee: 0).
        poolInfo.push(Pools({
            lpToken: IERC20(0x11d6DD25c1695764e64F439E32cc7746f3945543),
            allocPoint: 1_000,
            lastRewardTime: block.timestamp,
            accSoulPerShare: 0,
            feeDays: 0
        }));

        // sets: total allocation point.
        totalAllocPoint += 1_000;
        
    } 

    // divines: `role` to recipient.
    function _divinationCeremony(bytes32 _role, bytes32 _adminRole, address _account) internal returns (bool) {
        _setupRole(_role, _account);
        _setRoleAdmin(_role, _adminRole);
        return true;
    }

    // validates: pool uniqueness to eliminate duplication risk (internal view)
    function checkPoolDuplicate(IERC20 _token) internal view {
        uint length = poolInfo.length;

        for (uint pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].lpToken != _token, 'duplicated pool');
        }
    }

    // enables: panic button (ma'at)
    function toggleEmergency(bool enabled) external obey(maat) {
        isEmergency = enabled;
    }

    // toggles: pause state (isis)
    function toggleActive(bool enabled) external obey(isis) {
        isActivated = enabled;
    }

    // returns: amount of pools
    function poolLength() external view returns (uint) { return poolInfo.length; }

    // add: new pool created by the soul summoning goddess whose power transcends all (isis)
    function addPool(uint _allocPoint, IERC20 _lpToken, bool _withUpdate, uint _feeDays) external obey(isis) { 
            checkPoolDuplicate(_lpToken);
            require(_feeDays <= maxFeeDays, 'feeDays may not exceed the maximum of 100 days');

            _addPool(_allocPoint, _lpToken, _withUpdate, _feeDays);
    }

    // add: pool
    function _addPool(uint _allocPoint, IERC20 _lpToken, bool _withUpdate, uint _feeDays) internal {
        if (_withUpdate) { massUpdatePools(); }

        totalAllocPoint += _allocPoint;

        poolInfo.push(
        Pools({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardTime: block.timestamp > startTime ? block.timestamp : startTime,
            accSoulPerShare: 0,
            feeDays: toWei(_feeDays)
        }));
        
        uint pid = poolInfo.length;

        emit PoolAdded(pid, _allocPoint, _lpToken, totalAllocPoint);
    }

    // updates: allocation points (ma'at)
    function setPool(
        uint pid, 
        uint _allocPoint, 
        uint _feeDays, 
        bool withUpdate
    ) external isActive validatePoolByPid(pid) obey(maat) {
        // gets: pool data (stored for updates).
            Pools storage pool = poolInfo[pid];
            // [if] withUpdate, [then] execute mass pool update.
            if (withUpdate) { massUpdatePools(); }
                        
            // checks: an update is being executed.
            require(pool.allocPoint != _allocPoint || pool.feeDays != _feeDays, 'no change requested.');
            
            // checks: fee is below maximum
            require(_feeDays <= maxFeeDays, 'fee days exceeds max');

            // identifies: treatment of new allocation.
            bool isIncrease = _allocPoint > pool.allocPoint;
            
            // calculates: | delta | for global allocation;
            uint absDelta 
                = isIncrease 
                    ? _allocPoint - pool.allocPoint
                    : pool.allocPoint - _allocPoint;

            // sets: new `pool.allocPoint`
            pool.allocPoint = _allocPoint;

            // sets: new `pool.feeDays`
            pool.feeDays = _feeDays;

            // updates: `totalAllocPoint`
            isIncrease 
                ? totalAllocPoint += absDelta
                : totalAllocPoint -= absDelta;

        emit PoolSet(pid, _allocPoint, totalAllocPoint, absDelta, block.timestamp);
    }

    // safety: in case of errors.
    function setTotalAllocPoint(uint _totalAllocPoint) external obey(isis) {
        totalAllocPoint = _totalAllocPoint;
    }

    // returns: user delta is the time since user either last withdrew OR first deposited OR 0.
	function getUserDelta(uint pid, address account) public view returns (uint timeDelta) {
        // gets: stored `user` data (for a given pid).
        Users storage user = userInfo[pid][account];

        // [if] has never withdrawn & has deposited, [then] returns: `timeDelta` as the seconds since first `depositTime`.
        if (user.withdrawalTime == 0 && user.depositTime > 0) { return timeDelta = block.timestamp - user.depositTime; }
            // [else if] `user` has withdrawn, [then] returns: `timeDelta` as the time since the last withdrawal.
            else if(user.withdrawalTime > 0) { return timeDelta = block.timestamp - user.withdrawalTime; }
                // [else] returns: `timeDelta` as 0, since the user has never deposited.
                else return timeDelta = 0;
	}

    // returns: multiplier during a period.
    function getMultiplier(uint from, uint to) public pure returns (uint) {
        return to - from;
    }
    
    // returns: multiplier during a period.
    function getMaxFee(address account, uint pid) public view returns (uint maxFee) {
        // gets: stored `user` data (`pid`).
        Users storage user = userInfo[pid][account];

        // gets: stored `user` staked `amount` (`pid`).
        uint stakedBal = user.amount;

        // gets: `timeDelta` as the time since last withdrawal or first deposit (`pid`, `account`).
        uint timeDelta = getUserDelta(pid, account);

        // gets: `deltaDays` from the `timeDelta` of the specified `account` (`pid`).
        uint deltaDays = getDeltaDays(timeDelta);

        // calculates: withdrawable amount (`pid`, `deltaDays`, `stakedBal`).
        (, uint withdrawableAmount) = getWithdrawable(pid, deltaDays, stakedBal); 

        // calculates: `maxFee` as the `amount` requested minus `withdrawableAmount`.
        maxFee = stakedBal - withdrawableAmount;

        return maxFee;
 
    }

    // gets: days based off a given timeDelta (seconds).
    function getDeltaDays(uint timeDelta) public pure returns (uint deltaDays) {
        deltaDays = timeDelta < 1 days ? 0 : timeDelta / 1 days;
        return deltaDays;     
    }

    // returns: fee rate for a given pid and timeDelta.
    function getFeeRate(uint pid, uint deltaDays) public view returns (uint feeRate) {
        // calculates: rateDecayed (converts to wei).
        uint rateDecayed = toWei(deltaDays);

        // gets: info & feeDays (pool)
        Pools storage pool = poolInfo[pid];
        uint feeDays = pool.feeDays; 

        // [if] more time has elapsed than wait period
        if (rateDecayed >= feeDays) {
            // [then] set feeRate to 0.
            feeRate = 0;
        } else { // [else] reduce feeDays by the rateDecayed.
            feeRate = feeDays - rateDecayed;
        }

        return feeRate;
    }

    // returns: feeAmount and with withdrawableAmount for a given pid and amount
    function getWithdrawable(uint pid, uint deltaDays, uint amount) public view returns (uint _feeAmount, uint _withdrawable) {
        // gets: feeRate
        uint feeRate = fromWei(getFeeRate(pid, deltaDays));
        // gets: feeAmount
        uint feeAmount = (amount * feeRate) / 100;
        // calculates: withdrawable amount
        uint withdrawable = amount - feeAmount;

        return (feeAmount, withdrawable);
    }

    // view: pending soul rewards
    function pendingSoul(uint pid, address account) external view returns (uint pendingAmount) {
        // gets: pool and user data
        Pools storage pool = poolInfo[pid];
        Users storage user = userInfo[pid][account];

        // gets: `accSoulPerShare` & `lpSupply` (pool)
        uint accSoulPerShare = pool.accSoulPerShare;
        uint lpSupply = pool.lpToken.balanceOf(address(this));

        // [if] holds deposits & rewards issued at least once (pool)
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            // gets: multiplier from the time since now and last time rewards issued (pool)
            uint multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            // get: reward as the product of the elapsed emissions and the share of soul rewards (pool)
            uint soulReward = multiplier * soulPerSecond * pool.allocPoint / totalAllocPoint;
            // adds: product of soulReward and 1e12
            accSoulPerShare = accSoulPerShare + soulReward * 1e12 / lpSupply;
        }
        // returns: rewardShare for user minus the amount paid out (user)
        return user.amount * accSoulPerShare / 1e12 - user.rewardDebt;
    }

    // updates: rewards for all pools (public)
    function massUpdatePools() public {
        uint length = poolInfo.length;
        for (uint pid = 0; pid < length; ++pid) { updatePool(pid); }
    }

    // rewards: accounts for a given pool id
    function updatePool(uint pid) public validatePoolByPid(pid) {
        Pools storage pool = poolInfo[pid];

        if (block.timestamp <= pool.lastRewardTime) { return; }
        uint lpSupply = pool.lpToken.balanceOf(address(this));

        // [if] first staker in pool, [then] set lastRewardTime to meow.
        if (lpSupply == 0) { pool.lastRewardTime = block.timestamp; return; }

        // gets: multiplier from time elasped since pool began issuing rewards.
        uint multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint soulReward = multiplier * soulPerSecond * pool.allocPoint / totalAllocPoint;
        // gets: divi
        uint divi = soulReward * 1e12 / 8e12;   // 12.5% rewards
        
        soul.mint(team, divi);
        soul.mint(dao, divi);
        soul.mint(address(seance), soulReward); // prevents reward errors

        pool.accSoulPerShare = pool.accSoulPerShare + (soulReward * 1e12 / lpSupply);
        pool.lastRewardTime = block.timestamp;
    }

    // harvests: pending rewards for a given pid.
    function harvest(uint pid) public {
        if (pid == 0) { enterStaking(0); }
        else { deposit(pid, 0); }
    }
    
    // harvest: all pools in a single transaction.
    function harvestAll(uint[] calldata pids) external {
        for (uint i = 0; i < pids.length; ++i) {
            harvest(pids[i]);
        }
    }

    // harvest: all pools in a single transaction.
    function harvestAll() external {
        for (uint pid = 0; pid < poolInfo.length; ++pid) {
        // gets senders pending rewards (where staked)
        Users storage user = userInfo[pid][msg.sender];
            if (user.amount > 0) { harvest(pid); }
        }
    }

    // deposit: lp tokens (lp owner)
    function deposit(uint pid, uint amount) public nonReentrant isActive validatePoolByPid(pid) {
        require (pid != 0, 'deposit SOUL by staking (enterStaking)');
        
        // gets: stored data for pool and user.
        Pools storage pool = poolInfo[pid];
        Users storage user = userInfo[pid][msg.sender];

        updatePool(pid);

        // [if] already deposited (user)
        if (user.amount > 0) {
            // [then] gets: pendingReward.
        uint pendingReward = user.amount * pool.accSoulPerShare / 1e12 - user.rewardDebt;
                // [if] rewards pending, [then] transfer to user.
                if(pendingReward > 0) { 
                    safeSoulTransfer(msg.sender, pendingReward);
                }
        }

        // [if] depositing more
        if (amount > 0) {
            // [then] transfer lpToken from user to contract
            pool.lpToken.transferFrom(address(msg.sender), address(this), amount);
            // [then] increment deposit amount (user).
            user.amount += amount;
        }

        // updates: reward debt (user).
        user.rewardDebt = user.amount * pool.accSoulPerShare / 1e12;

        // [if] first time depositing (user)
        if (user.depositTime == 0) {
            // [then] update depositTime
            user.depositTime = block.timestamp;
        }
        
        emit Deposit(msg.sender, pid, amount, block.timestamp);
    }

    // withdraw: lp tokens (external farmers)
    function withdraw(uint pid, uint amount) external nonReentrant isActive validatePoolByPid(pid) {
        require (pid != 0, 'withdraw SOUL by unstaking (leaveStaking)');
        require(amount > 0, 'cannot withdraw zero');

        Pools storage pool = poolInfo[pid];
        Users storage user = userInfo[pid][msg.sender];

        require(user.amount >= amount, 'withdrawal exceeds deposit');
        updatePool(pid);

        // gets: pending rewards as determined by pendingSoul.
        uint pendingReward = user.amount * pool.accSoulPerShare / 1e12 - user.rewardDebt;
        // [if] rewards are pending, [then] send rewards to user.
        if(pendingReward > 0) { safeSoulTransfer(msg.sender, pendingReward); }

        // gets: timeDelta as the time since last withdrawal.
        uint timeDelta = getUserDelta(pid, msg.sender);

        // gets: deltaDays as days passed using timeDelta.
        uint deltaDays = getDeltaDays(timeDelta);

        // updates: deposit, timeDelta, & deltaDays (user)
        user.amount -= amount;
        user.timeDelta = timeDelta;
        user.deltaDays = deltaDays;

        // calculates: withdrawable amount (pid, deltaDays, amount).
        (, uint withdrawableAmount) = getWithdrawable(pid, deltaDays, amount); 

        // calculates: `feeAmount` as the `amount` requested minus `withdrawableAmount`.
        uint feeAmount = amount - withdrawableAmount;

        // transfers: `feeAmount` --> DAO.
        pool.lpToken.transfer(address(dao), feeAmount);
        // transfers: withdrawableAmount amount --> user.
        pool.lpToken.transfer(address(msg.sender), withdrawableAmount);

        // updates: rewardDebt and withdrawalTime (user)
        user.rewardDebt = user.amount * pool.accSoulPerShare / 1e12;
        user.withdrawalTime = block.timestamp;

        emit Withdraw(msg.sender, pid, amount, feeAmount, block.timestamp);
    }

    // enables: withdrawal without caring about rewards (for example, when rewards end).
    function emergencyWithdraw(uint pid) external nonReentrant emergencyActive {
        // gets: pool & user data (to update later).
        Pools storage pool = poolInfo[pid];
        Users storage user = userInfo[pid][msg.sender];

        // [if] removing from staking
        if (pid == 0) {
            // [then] require SEANCE balance covers request (user).
            require(seance.balanceOf(msg.sender) >= user.amount, 'insufficient SEANCE to cover SOUL withdrawal request');
            // [then] burn seance from sender.
            seance.burn(msg.sender, user.amount); 
        }

        // transfers: lpToken to the user.
        pool.lpToken.safeTransfer(msg.sender, user.amount);

        // eliminates: user deposit `amount` & `rewardDebt`.
        user.amount = 0;
        user.rewardDebt = 0;

        // updates: user `withdrawTime`.
        user.withdrawalTime = block.timestamp;

        emit EmergencyWithdraw(msg.sender, pid, user.amount, user.withdrawalTime);
    }

    // stakes: soul into summoner.
    function enterStaking(uint amount) public nonReentrant isActive {
        Pools storage pool = poolInfo[0];
        Users storage user = userInfo[0][msg.sender];

        updatePool(0);

        // [if] already staked (user)
        if (user.amount > 0) {
            // [then] get: pending rewards.
            uint pendingReward = user.amount * pool.accSoulPerShare / 1e12 - user.rewardDebt;
            // [then] send: pending rewards.
            safeSoulTransfer(msg.sender, pendingReward);
        }
        
        // [if] staking (ø harvest)
        if (amount > 0) {
            // [then] transfer: `amount` of SOUL from user to contract.
            pool.lpToken.transferFrom(msg.sender, address(this), amount);
            // [then] increase: stored deposit amount (user).
            user.amount += amount;
        }

        // [if] first deposit, [then] set depositTime to meow (user).
        if (user.depositTime == 0) { user.depositTime = block.timestamp; }

        // updates: reward debt (user)
        user.rewardDebt = user.amount * pool.accSoulPerShare / 1e12;

        // mints & sends: requested `amount` of SEANCE to sender as a receipt.
        if (amount > 0) { seance.mint(msg.sender, amount); }

        emit Deposit(msg.sender, 0, amount, block.timestamp);
    }

    // unstake: your soul (external staker)
    function leaveStaking(uint amount) external nonReentrant isActive {
        Pools storage pool = poolInfo[0];
        Users storage user = userInfo[0][msg.sender];

        // checks: sufficient balance to cover request (user).
        require(user.amount >= amount, 'requested withdrawal exceeds staked balance');
        updatePool(0);

        // gets: pending staking pool rewards (user).
        uint pendingReward = user.amount * pool.accSoulPerShare / 1e12 - user.rewardDebt;

        // [if] sender has pending rewards, [then] transfer rewards to sender.
        if (pendingReward > 0) { safeSoulTransfer(msg.sender, pendingReward); }

        // [if] withdrawing from stake.
        if (amount > 0) {
            // [then] decrease: stored deposit by withdrawal amount.
            user.amount = user.amount - amount;
            // [then] burn: SEANCE in the specified `amount` (user).
            seance.burn(msg.sender, amount);
            // [then] update: reward debt (user).
            user.rewardDebt = user.amount * pool.accSoulPerShare / 1e12;
            // [then] update: withdrawal time (user).
            user.withdrawalTime = block.timestamp;
            // [then] transfer: requested SOUL (user).
            pool.lpToken.transfer(address(msg.sender), amount);
        }

        emit Withdraw(msg.sender, 0, amount, 0, block.timestamp);
    }
    
    // transfer: seance (only if there is sufficient coverage for payout).
    function safeSoulTransfer(address account, uint amount) internal {
        require(soul.balanceOf(seanceAddress) >= amount, 'insufficient coverage for requested SOUL from SEANCE');
        seance.safeSoulTransfer(account, amount);
    }

    // update: weight (ma'at)
    function updateWeight(uint _weight, uint _totalWeight) public obey(maat) {
        require(weight != _weight || totalWeight != _totalWeight, 'must include a new value');
        require(_totalWeight >= _weight, 'weight cannot exceed totalWeight');

        weight = _weight;     
        totalWeight = _totalWeight;

        updateRewards(_weight, _totalWeight);

        emit WeightUpdated(_weight, _totalWeight);
    }

    // update: rewards
    function updateRewards(uint _weight, uint _totalWeight) internal {
        uint share = toWei(_weight) / _totalWeight; // share of total emissions for rewarder (rewarder % total emissions)
        
        // sets: `dailySoul` = share (%) x globalDailySoul (soul emissions constant)
        dailySoul = share * globalDailySoul;

        // sets: `soulPerSecond` as `dailySoul` expressed per second (1 days = 86,400 secs).
        soulPerSecond = dailySoul / 1 days;

        emit RewardsUpdated(dailySoul, soulPerSecond);
    }

    // updates: feeDays (ma'at)
    function updateFeeDays(uint pid, uint _daysRequested) external obey(maat) {
        Pools storage pool = poolInfo[pid];
        
        // converts: requested days (toWei).
        uint _feeDays = toWei(_daysRequested);

        // gets: current fee days & ensures distinction (pool)
        uint feeDays = pool.feeDays;
        require(feeDays != _feeDays, 'no change requested');
        
        // limits: feeDays by maxFeeDays
        require(feeDays <= maxFeeDays, 'exceeds allowable feeDays');
        
        // updates: fee days (pool)
        pool.feeDays = _feeDays;
        
        emit FeeDaysUpdated(pid, _feeDays);
    }

    // updates: dao & team addresses (isis)
    function updateAccounts(address _dao, address _team) public obey(isis) {
        require(dao != _dao || team != _team, 'no change requested');
        dao = _dao;
        team = _team;

        emit AccountsUpdated(dao, team);
    }

    // updates: soul & seance addresses (isis)
    function setTokens(address _soulAddress, address _seanceAddress) public obey(isis) {
        require(soulAddress != _soulAddress || seanceAddress != _seanceAddress, 'no change requested');
        soulAddress = _soulAddress;
        seanceAddress = _seanceAddress;

        soul = IToken(_soulAddress);
        seance = IToken(_seanceAddress);

        emit TokensUpdated(_soulAddress, _seanceAddress);
    }

    // helper functions to convert to wei and 1/100th
    function toWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }
}