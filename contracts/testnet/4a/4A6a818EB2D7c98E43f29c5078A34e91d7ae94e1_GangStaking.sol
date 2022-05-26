/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
        keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 ammount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(this), account_, ammount_);
        _totalSupply = _totalSupply.add(ammount_);
        _balances[account_] = _balances[account_].add(ammount_);
        emit Transfer(address(this), account_, ammount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

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

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}
}

interface IERC2612Permit {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 _hash = keccak256(
            abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct)
        );

        address signer = ecrecover(_hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ZeroSwapPermit: Invalid signature"
        );

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

interface ITokenStaking {
    function startReward(uint256[] memory _tokenIDs, uint256[] memory _balances)
        external;

    function getTotalAmount(uint256 _tokenID) external view returns (uint256);

    function getTotalCoin(uint256 _tokenID) external view returns (uint256);

    function _nftTotalNum(uint256 _tokenID) external view returns (uint256);
}

contract GangStaking is AccessControl, IERC721Receiver, Pausable {
    event Attack(uint256 tokenId, uint256 targetId, uint256 timestamp);
    event BuildDefense(uint256 tokenId, uint256 timestamp);
    event GangStaked(address owner, uint256 tokenId);
    event GangUnStaked(address owner, uint256 tokenId);
    event JoinGang(address owner, uint256 tokenId);
    event LeaveGang(address owner, uint256 tokenId);

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    bytes32 public constant S_TOKEN = keccak256("S_TOKEN");
    bytes32 public constant N_TOKEN = keccak256("N_TOKEN");

    struct GangPack {
        uint256 id;
        uint256 score;
        uint256 lastTime;
        uint256 attackCount;
        uint256 defense;
        uint256 restUntil;
        uint256 nftAmount;
        uint256 drugAmount;
        uint256 cashAmount;
        uint256 attackeds;
        address owner;
        bool enabled;
        bool locked;
    }

    ITokenStaking public NFTStaking;
    ITokenStaking public CASHStaking;
    ITokenStaking public DRUGStaking;

    IERC721 public immutable Gang;
    IERC20 public immutable DRUG;

    uint256 public remainingP;
    uint256 public immutable initRebaseStartTime;
    uint256 public round;

    uint256[] public winningPercentages; // 2500 = 25%   value/10000

    uint256[] public gangs;
    // mapping from GangID sort Array (1st, 2nd, ..., last)  GangID=>place
    mapping(uint256 => uint256) public rankings;

    //GangID=>GangPack
    mapping(uint256 => GangPack) public packs;

    mapping(address => uint256) public leaderReward;
    mapping(address => uint256) public leaderPastReward;

    mapping(address => uint256) public userGang;

    constructor(
        address _Gang,
        address _DRUG,
        uint256 _initRebaseStartTime
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        Gang = IERC721(_Gang);
        DRUG = IERC20(_DRUG);
        initRebaseStartTime = _initRebaseStartTime;
        winningPercentages = [
            2500,
            1725,
            1425,
            1025,
            825,
            725,
            625,
            500,
            425,
            225
        ];
        remainingP = 96;
    }

    function stakeGang(uint256 tokenId) external whenNotPaused {
        require(Gang.ownerOf(tokenId) == msg.sender, "now owner");
        require(!packs[tokenId].enabled, "already staking");
        gangs.push(tokenId);
        packs[tokenId].id = tokenId;
        packs[tokenId].owner = msg.sender;
        packs[tokenId].enabled = true;
        Gang.transferFrom(msg.sender, address(this), tokenId);
        emit GangStaked(msg.sender, tokenId);
    }

    function lockGang(uint256 tokenId) external whenNotPaused {
        require(msg.sender == packs[tokenId].owner, "now owner");
        packs[tokenId].locked = true;
        packs[tokenId].lastTime = block.timestamp;
        emit GangStaked(msg.sender, tokenId);
    }

    function unstakeGang(uint256 tokenId) external whenNotPaused {
        require(msg.sender == packs[tokenId].owner, "now owner");
        require(
            packs[tokenId].lastTime + 1 hours >= block.timestamp, // 7 days
            "not expired"
        );
        packs[tokenId].enabled = false;
        emit GangUnStaked(msg.sender, tokenId);
        delete gangs[tokenId];
        Gang.transfer(msg.sender, tokenId);
    }

    function joinGang(uint256 tokenId, address _user)
        external
        whenNotPaused
        onlyRole(N_TOKEN)
    {
        require(userGang[_user] == 0, "userGang error");
        require(packs[tokenId].enabled, "Gang not enabled");
        userGang[_user] = tokenId;
        emit JoinGang(_user, tokenId);
    }

    function leaveGang(uint256 tokenId, address _user)
        external
        whenNotPaused
        onlyRole(N_TOKEN)
    {
        require(userGang[_user] == tokenId, "userGang error");
        userGang[_user] = 0;
        emit LeaveGang(_user, tokenId);
    }

    function sendReward() external onlyRole(S_TOKEN) {
        _sendReward();
    }

    function attack(uint256 tokenId, uint256 target) external whenNotPaused {
        require(msg.sender == packs[tokenId].owner, "now owner");
        require(packs[tokenId].enabled, "YOURE NOT A PACK LEADER");
        require(tokenId != target, "CANT ATTACK YOURSELF");
        require(packs[target].enabled, "NOT A VALID TARGET");
        require(packs[tokenId].attackCount > 0);
        require(packs[tokenId].restUntil <= block.timestamp, "too tired");
        if (packs[target].defense > 0) {
            packs[target].defense--;
        } else {
            // decrease target score
            packs[tokenId].attackeds++;
            packs[tokenId].score = packs[tokenId].score.mul(
                remainingP.div(100)
            );
        }
        packs[tokenId].attackCount--;
        packs[tokenId].restUntil = block.timestamp + 1 hours;
        emit GangStaked(msg.sender, tokenId);
        emit Attack(tokenId, target, block.timestamp);
    }

    function claimFromLeader() external whenNotPaused {
        require(leaderReward[msg.sender] > 0, "not reward");
        DRUG.safeTransfer(msg.sender, leaderReward[msg.sender]);
        leaderPastReward[msg.sender] += leaderReward[msg.sender];
        leaderReward[msg.sender] = 0;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Barn directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function _sendReward() internal returns (bool) {
        if (block.timestamp >= initRebaseStartTime + round * 1 hours) {
            //1 days
            loadScore();
            sortByScore();
            uint256[] memory _tokenIds = new uint256[](gangs.length);
            uint256[] memory _balances = new uint256[](gangs.length);
            uint256 amount = getRebaseAmount();
            uint256 totalAmount;
            uint256 start;
            for (uint256 i = 0; i < gangs.length; i++) {
                if (packs[gangs[i]].enabled && packs[gangs[i]].score > 0) {
                    uint256 gangReward = amount
                        .mul(winningPercentages[rankings[gangs[i]] - 1])
                        .div(10000);
                    if (!packs[gangs[i]].locked) {
                        leaderReward[packs[gangs[i]].owner] += gangReward.div(
                            10
                        );
                        gangReward = gangReward.mul(90).div(100);
                    }
                    totalAmount += gangReward;
                    _tokenIds[start] = gangs[i];
                    _balances[start] = gangReward.div(3);
                    start++;
                }
            }
            NFTStaking.startReward(_tokenIds, _balances);
            DRUGStaking.startReward(_tokenIds, _balances);
            CASHStaking.startReward(_tokenIds, _balances);
            sendToken(totalAmount);
            if (amount > totalAmount) {
                DRUG.burn(amount.sub(totalAmount));
            }
            round++;
            return _sendReward();
        } else {
            return true;
        }
    }

    function loadScore() internal {
        for (uint256 i = 0; i < gangs.length; i++) {
            if (round % 7 == 0) {
                packs[gangs[i]].attackeds = 0;
            }
            if (packs[gangs[i]].enabled) {
                (, , , uint256 totalScore) = getGangScore(gangs[i]);
                //add  attackCount and  defense by tokenAmount

                (uint256 CASHAmount, uint256 DRUGAmount, ) = getGangNum(
                    gangs[i]
                );

                uint256 expected = round / 7 + 1 >= 10
                    ? 240000 ether
                    : (round / 7 + 1) * 24000 ether;
                if (DRUGAmount - packs[gangs[i]].drugAmount > expected) {
                    packs[gangs[i]].attackCount++;
                }
                if (CASHAmount - packs[gangs[i]].cashAmount > expected * 2) {
                    packs[gangs[i]].defense++;
                    emit BuildDefense(gangs[i], block.timestamp);
                }
                packs[gangs[i]].drugAmount = DRUGAmount;
                packs[gangs[i]].cashAmount = CASHAmount;
                packs[gangs[i]].score = totalScore
                    .mul(remainingP**packs[gangs[i]].attackeds)
                    .div(100**packs[gangs[i]].attackeds);
                emit GangStaked(msg.sender, gangs[i]);
            }
        }
    }

    function sortByScore() internal {
        resetRankings();
        uint256 length = gangs.length;
        uint256 place;
        uint256 j;
        uint256 max;
        uint256 gang;
        uint256 current;
        // sort the packs into winning order (pack -> placement)
        for (place = 1; place <= length; place++) {
            if (packs[gangs[place - 1]].enabled) {
                max = 0;
                for (j = 0; j < length; j++) {
                    if (rankings[gangs[j]] != 0) continue;
                    current = packs[gangs[j]].score;
                    if (current >= max) {
                        max = current;
                        gang = gangs[j];
                    }
                }
                rankings[gang] = place;
            }
        }
    }

    function resetRankings() internal {
        for (uint256 i = 0; i < gangs.length; i++) {
            rankings[gangs[i]] = 0;
        }
    }

    function checkScore()
        internal
        view
        returns (
            bool n,
            bool c,
            bool d
        )
    {
        uint256 NFTScore;
        uint256 CASHScore;
        uint256 DRUGScore;
        for (uint256 i = 0; i < gangs.length; i++) {
            if (packs[gangs[i]].enabled) {
                NFTScore += NFTStaking.getTotalAmount(gangs[i]);
                CASHScore += CASHStaking.getTotalAmount(gangs[i]);
                DRUGScore += DRUGStaking.getTotalAmount(gangs[i]);
            }
        }
        n = NFTScore > 0;
        c = CASHScore > 0;
        d = DRUGScore > 0;
    }

    function sendToken(uint256 totalAmount) internal {
        (bool n, bool c, bool d) = checkScore();
        if (totalAmount > 0) {
            uint256 sendAmount = totalAmount.div(3);
            if (n) {
                DRUG.safeTransfer(address(NFTStaking), sendAmount);
            } else {
                DRUG.burn(sendAmount);
            }
            if (c) {
                DRUG.safeTransfer(address(CASHStaking), sendAmount);
            } else {
                DRUG.burn(sendAmount);
            }
            if (d) {
                DRUG.safeTransfer(address(DRUGStaking), sendAmount);
            } else {
                DRUG.burn(sendAmount);
            }
        }
    }

    /***READ */
    function verify(uint256 tokenId, address _user) public view returns (bool) {
        return packs[tokenId].enabled && userGang[_user] == tokenId;
    }

    // one day for rebaseAmount
    function getRebaseAmount() public view returns (uint256 rebaseAmount) {
        uint256 deltaTimeFromInit = block.timestamp - initRebaseStartTime;
        uint256 maxAmount = 7350000 ether;
        if (deltaTimeFromInit > (11 * 30 days)) {
            rebaseAmount = maxAmount.mul(380716660).div(1e10).div(30);
        } else if (deltaTimeFromInit > (10 * 30 days)) {
            rebaseAmount = maxAmount.mul(403000000).div(1e10).div(30);
        } else if (deltaTimeFromInit > (9 * 30 days)) {
            rebaseAmount = maxAmount.mul(429166667).div(1e10).div(30);
        } else if (deltaTimeFromInit > (8 * 30 days)) {
            rebaseAmount = maxAmount.mul(445833333).div(1e10).div(30);
        } else if (deltaTimeFromInit > (7 * 30 days)) {
            rebaseAmount = maxAmount.mul(470833333).div(1e10).div(30);
        } else if (deltaTimeFromInit > (6 * 30 days)) {
            rebaseAmount = maxAmount.mul(743750000).div(1e10).div(30);
        } else if (deltaTimeFromInit > (5 * 30 days)) {
            rebaseAmount = maxAmount.mul(793750000).div(1e10).div(30);
        } else if (deltaTimeFromInit > (4 * 30 days)) {
            rebaseAmount = maxAmount.mul(831250000).div(1e10).div(30);
        } else if (deltaTimeFromInit > (3 * 30 days)) {
            rebaseAmount = maxAmount.mul(1158333333).div(1e10).div(30);
        } else if (deltaTimeFromInit > (2 * 30 days)) {
            rebaseAmount = maxAmount.mul(1258333333).div(1e10).div(30);
        } else if (deltaTimeFromInit > (1 * 30 days)) {
            rebaseAmount = maxAmount.mul(1308333333).div(1e10).div(30);
        } else {
            rebaseAmount = maxAmount.mul(1776700000).div(1e10).div(30);
        }
    }

    function getAllPacks()
        public
        view
        returns (GangPack[] memory currentPacks)
    {
        currentPacks = new GangPack[](gangs.length);
        for (uint256 i = 0; i < gangs.length; i++) {
            (uint256 gangCASH, uint256 gangDRUG, uint256 gangNFT) = getGangNum(
                gangs[i]
            );
            (, , , uint256 totalScore) = getGangScore(gangs[i]);
            currentPacks[i] = packs[gangs[i]];
            currentPacks[i].score = totalScore
                .mul(remainingP**packs[gangs[i]].attackeds)
                .div(100**packs[gangs[i]].attackeds);
            currentPacks[i].drugAmount = gangDRUG;
            currentPacks[i].cashAmount = gangCASH;
            currentPacks[i].nftAmount = gangNFT;
        }
    }

    function getGangNum(uint256 tokenId)
        public
        view
        returns (
            uint256 dAmount,
            uint256 cAmount,
            uint256 nAmount
        )
    {
        cAmount = CASHStaking.getTotalCoin(tokenId);
        dAmount = DRUGStaking.getTotalCoin(tokenId);
        nAmount = NFTStaking._nftTotalNum(tokenId);
    }

    function getGangScore(uint256 tokenId)
        public
        view
        returns (
            uint256 CScore,
            uint256 DScore,
            uint256 NScore,
            uint256 tScore
        )
    {
        CScore = CASHStaking.getTotalAmount(tokenId);
        DScore = DRUGStaking.getTotalAmount(tokenId);
        NScore = NFTStaking.getTotalAmount(tokenId);
        tScore = CScore.add(DScore).add(NScore);
    }

    /***ADMIN */
    function setPaused(bool _p) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_p) _pause();
        else _unpause();
    }

    function setTokenStaking(
        address _NFT,
        address _CASH,
        address _DRUG
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        NFTStaking = ITokenStaking(_NFT);
        CASHStaking = ITokenStaking(_CASH);
        DRUGStaking = ITokenStaking(_DRUG);
        grantRole(S_TOKEN, _NFT);
        grantRole(S_TOKEN, _CASH);
        grantRole(S_TOKEN, _DRUG);
        grantRole(N_TOKEN, _NFT);
    }
}