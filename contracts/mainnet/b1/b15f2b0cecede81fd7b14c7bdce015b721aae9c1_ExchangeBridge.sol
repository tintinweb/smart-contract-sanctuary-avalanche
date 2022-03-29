/**
 *Submitted for verification at snowtrace.io on 2022-03-29
*/

// File: contracts/extensions/AccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity 0.7.5;

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
abstract contract AccessControl {
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct RoleData {
        mapping(address => bool) members;
    }

    mapping(bytes32 => RoleData) private _roles;

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
        _checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
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
                string("access denied")
                //     abi.encodePacked(
                //         "AccessControl: account ",
                //         Strings.toHexString(uint160(account), 20),
                //         " is missing role ",
                //         Strings.toHexString(uint256(role), 32)
                //     )
                // )
            );
        }
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
    function grantRole(bytes32 role, address account) public virtual onlyRole(ADMIN_ROLE) {
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
    function revokeRole(bytes32 role, address account) public virtual onlyRole(ADMIN_ROLE)  {
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
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
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
        }
    }
}

// File: interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity 0.7.5;

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

    function permit(address owner, address spender, uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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
    function mint(address account, uint rawAmount) external;
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

// File: libraries/math/LowGasSafeMath.sol



pragma solidity 0.7.5;

library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "add uint256 overflow");
    }

    function add32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x + y) >= x, "add32 uint32 overflow");
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub uint256 overflow");
    }

    function sub32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x - y) <= x, "sub32 uint32 overflow");
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y, "mul uint256 overflow");
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0), "add int256 overflow");
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0), "sub int256 overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "division by 0");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
// File: contracts/core/ExchangeBridge.sol



/* *********************************
 * Owned and operated by MaxDeFi at defiprizes.com
 * ********************************* */

pragma solidity 0.7.5;




interface JoeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// ExchangeBridge is used to ensure contracts can still exchange tokens if the exchange changes their LPs or router address
contract ExchangeBridge is AccessControl {
    using LowGasSafeMath for uint256;

    JoeRouter public traderJoeRouter;
    address public joeFactory = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10;
    address public constant wavax = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    mapping(address => mapping(address => address[])) public paths;

    constructor(
        address _traderJoeRouter
    ) {
        _setupRole(ADMIN_ROLE, msg.sender);
        traderJoeRouter = JoeRouter(_traderJoeRouter);
    }

    function setTraderJoeRouter(address _traderJoeRouter) external onlyRole(ADMIN_ROLE) {
        traderJoeRouter = JoeRouter(_traderJoeRouter);
    }

    function setJoeFactory(address _joeFactory) external onlyRole(ADMIN_ROLE) {
        joeFactory = _joeFactory;
    }

    // allow router to take tokens
    function approveToken(address token, uint256 allowance) external onlyRole(ADMIN_ROLE) {
        IERC20(token).approve(address(traderJoeRouter), allowance);
    }

    // this contract should have tokens sent to it before calling 
    function exchangeExactTokensForTokens(uint256 amount, address sourceToken, address targetToken) external {
        // swap for whatever, deadline is n/a so deadline is block.number
        traderJoeRouter.swapExactTokensForTokens(amount, 0, getPath(sourceToken, targetToken), msg.sender, block.number);
    }

    // this contract should have tokens sent to it before calling 
    function exchangeExactTokensForAVAX(uint256 amount, address sourceToken) external {
        traderJoeRouter.swapExactTokensForAVAX(amount, 0, getPath(sourceToken, wavax), msg.sender, block.number);
    }

    function getPath(address sourceToken, address targetToken) public view returns(address[] memory) {
        address[] storage result = paths[sourceToken][targetToken];
        if (result.length != 0) {
            return result;
        }
        address[] memory pathDefault = new address[](2);
        pathDefault[0] = sourceToken;
        pathDefault[1] = targetToken;
        return pathDefault;
    }

    function setPath(address sourceToken, address targetToken, address[] calldata path) external onlyRole(ADMIN_ROLE) {
        paths[sourceToken][targetToken] = path;
    }
}