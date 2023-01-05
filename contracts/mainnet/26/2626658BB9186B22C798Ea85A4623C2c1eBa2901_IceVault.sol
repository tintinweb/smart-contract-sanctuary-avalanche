// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/ISicleRouter02.sol";
import "./interface/ISiclePair.sol";
import "./interface/IOracleTWAP.sol";
import "./utils/Proxyable.sol";

contract IceVault is Ownable, AccessControl, Proxyable {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt; // Reward debt
        uint256 lastRewardBlock;
    }

    bool private immutable isToken0Pops;

    address public immutable pairAddress; // address of LP
    address public immutable popsToken; // address of POPS contract
    address public immutable sicleRouter02; // address of router to swap token/POP

    bool public claimDisabled;
    bool public stakingEnabled;
    bool public withdrawDisabled;

    address public oracleTWAP5d;
    address public oracleTWAP5m;
    address public stakeToken; // address of stake token contract
    address public treasury;

    uint256 public blocksPerDay = 42000;
    uint256 public endBlock; // end of the staking
    uint256 public maxStaked; // max supply of tokens in stake
    uint256 public maxStakePerUser; // max stake per user
    uint256 public minStakePerDeposit; // min stake per deposit
    uint256 public popsTokenRatioAvgLast5d; // Average of the last 5 days POP/Staking token ratio
    uint256 public rewardPerBlock; // tokens distributed per block * 1e12
    uint256 public rewardPerDay;
    uint256 public swapSafetyMargin; // 500 = 5.00%; the margin of POPS to swap to allow for slippage or price change
    uint256 public withdrawalFee; // Fees applied when withdraw. 175 = 1.75%

    uint256 public accumulatedFees; // accumulated taxes
    uint256 public totalStaked; // total tokens in stake

    address public entryToken; // user must hold entryAmount of entryToken to deposit or claim
    uint256 public entryAmount; // user must hold entryAmount of entryToken to deposit or claim

    mapping(address => UserInfo) public userInfos; // user stake

    bytes32 public constant SWAP_ROLE = keccak256("SWAP_ROLE");

    event Claim(address indexed user, uint256 indexed pending);
    event Deposit(address indexed user, uint256 indexed amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed userAmount);
    event SwapStakeToPops(
        address indexed user,
        uint256 indexed amountStakeIn,
        uint256 indexed amountPopsOutMin,
        uint256 stakeBalanceBefore,
        uint256 stakeBalanceAfter,
        uint256 popsBalanceBefore,
        uint256 popsBalanceAfter
    );
    event Withdraw(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed amountAfterFees
    );
    event WithdrawPops(
        address indexed user,
        uint256 indexed amount,
        address indexed treasury
    );

    error AddressIsZero();
    error AfterEndblock();
    error AmountInExceedsMaxSwapAmount();
    error AmountIsGreaterThanUserBalance();
    error BeforeEndblock();
    error BelowMinimumDeposit();
    error ClaimDisabled();
    error ExceedsMaxStake();
    error ExceedsMaxStakePerUser();
    error InsufficientPOPS();
    error InsufficientPOPSForSwap();
    error InsufficientStakeToken();
    error NoStake();
    error OutOfRange(string range);
    error StakingDisabled();
    error StakingStarted();
    error WithdrawDisabled();
    error EntryRequirementNotMet();
    error Unauthorized();

    modifier notZeroAddress(address _address) {
        if (_address == address(0)) revert AddressIsZero();
        _;
    }

    modifier stakingNotStarted() {
        if (totalStaked > 0) revert StakingStarted();
        _;
    }

    modifier meetsEntryRequirement() {
        if (IERC20(entryToken).balanceOf(_msgSender()) < entryAmount) revert EntryRequirementNotMet();
        _;
    }

    constructor(
        address _stakeToken,
        address _popsToken,
        address _sicleRouter02,
        address _pairAddress,
        address _entryRequirementTokenAddress,
        uint256 _rewardPerDay,
        uint256 _maxStaked,
        uint256 _minStakePerDeposit,
        uint256 _maxStakedPerUser,
        uint256 _stakeLengthInDays,
        uint256 _entryRequirementAmount

    )
        notZeroAddress(_stakeToken)
        notZeroAddress(_popsToken)
        notZeroAddress(_sicleRouter02)
        notZeroAddress(_pairAddress)
    {
        stakeToken = _stakeToken;
        popsToken = _popsToken;
        sicleRouter02 = _sicleRouter02;
        maxStaked = _maxStaked;
        minStakePerDeposit = _minStakePerDeposit;
        maxStakePerUser = _maxStakedPerUser;
        rewardPerBlock = _rewardPerDay / blocksPerDay;
        rewardPerDay = _rewardPerDay;
        entryToken = _entryRequirementTokenAddress;
        entryAmount = _entryRequirementAmount;
        
        endBlock = block.number + blocksPerDay * _stakeLengthInDays;
        setProxyState(_msgSender(), true);

        // Comment to pass the test in hardhat and Uncomment when deploy
        pairAddress = _pairAddress;
        isToken0Pops = ISiclePair(pairAddress).token0() == popsToken;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function claim() external {
        _updateOracles();
        _claim();
    }

    function deposit(uint256 amount) external meetsEntryRequirement {
        if (!stakingEnabled) revert StakingDisabled();
        if (block.number > endBlock) revert AfterEndblock();
        if (amount < minStakePerDeposit || amount == 0)
            revert BelowMinimumDeposit();

        UserInfo storage userInfo = userInfos[_msgSender()];
        uint256 userAmount = userInfo.amount;
        uint256 total = userAmount + amount;
        if (total > maxStaked) revert ExceedsMaxStake();
        if (total > maxStakePerUser) revert ExceedsMaxStakePerUser();
        IERC20(stakeToken).transferFrom(_msgSender(), address(this), amount);
        _updateOracles();

        if (userAmount > 0) _claim();

        userInfo.amount += amount;
        totalStaked += amount;
        userInfo.lastRewardBlock = block.number;

        emit Deposit(_msgSender(), amount);
    }

    // force withdraw by owner; user receives deposit, but no reward
    function emergencyWithdrawByOwner(address user) external onlyOwner {
        _updateOracles();
        UserInfo storage userInfo = userInfos[user];
        uint256 userAmount = userInfo.amount;
        if (userAmount == 0) revert NoStake();
        userInfo.amount = 0;
        totalStaked -= userAmount;

        _transferStakeTokenToUser(user, userAmount);
        emit EmergencyWithdraw(user, userAmount);
    }

    function setBlocksPerDay(
        uint256 _blocksPerDay
    ) external onlyOwner stakingNotStarted {
        if (_blocksPerDay < 1000 || _blocksPerDay > 45000)
            revert OutOfRange("1000-45000");
        blocksPerDay = _blocksPerDay;
        rewardPerBlock = rewardPerDay / blocksPerDay;
    }

    function setClaimDisabled(bool value) external onlyOwner {
        claimDisabled = value;
    }

    function setEndBlock(uint value) external onlyOwner stakingNotStarted {
        endBlock = value;
    }

    function setMaxStaked(uint256 amount) external onlyOwner {
        maxStaked = amount;
    }

    function setMaxStakePerUser(uint256 amount) external onlyOwner {
        maxStakePerUser = amount;
    }

    function setMinStakePerDeposit(uint256 amount) external onlyOwner {
        minStakePerDeposit = amount;
    }

    function setEntryRequirementAmount(uint256 amount) external onlyOwner {
        entryAmount = amount;
    }

    function setEntryRequirementToken(address addr) external onlyOwner {
        entryToken = addr;
    }

    function setOracleTWAP5d(
        address value
    ) external notZeroAddress(value) onlyOwner {
        oracleTWAP5d = value;
    }

    function setOracleTWAP5m(
        address value
    ) external notZeroAddress(value) onlyOwner {
        oracleTWAP5m = value;
    }

    function setRewardPerDay(
        uint256 value
    ) external onlyOwner stakingNotStarted {
        rewardPerDay = value;
        rewardPerBlock = rewardPerDay / blocksPerDay;
    }

    function setStakingEnabled(bool enabled) external onlyOwner {
        stakingEnabled = enabled;
    }

    function setStakingToken(
        address value
    ) external onlyOwner notZeroAddress(value) stakingNotStarted {
        stakeToken = value;
    }

    function setSwapSafetyMargin(uint256 value) external onlyOwner {
        swapSafetyMargin = value;
    }

    function setTreasury(address addr) external onlyOwner {
        treasury = addr;
    }

    function setWithdrawDisabled(bool value) external onlyOwner {
        withdrawDisabled = value;
    }

    function setWithdrawalFee(uint256 amount) external onlyOwner {
        withdrawalFee = amount;
    }

    function swapStakeToPops(
        uint256 amountStakeIn,
        uint256 amountPopsOutMin
    ) external {
        if (msg.sender != owner() && !hasRole(SWAP_ROLE, msg.sender)) revert Unauthorized();
        _swapStakeToPops(amountStakeIn, amountPopsOutMin);
    }

    function updateOracles() external {
        _updateOracles();
    }

    function withdraw(uint256 _amount) external {
        if (withdrawDisabled) revert WithdrawDisabled();
        _updateOracles();
        UserInfo storage userInfo = userInfos[_msgSender()];
        uint256 userAmount = userInfo.amount;
        if (userAmount == 0) revert NoStake();
        if (_amount > userAmount) revert AmountIsGreaterThanUserBalance();

        _claim();
        userInfo.amount -= _amount;
        totalStaked -= _amount;

        uint256 amountAfterFees = _getAmountAfterFees(_amount);
        _transferStakeTokenToUser(_msgSender(), amountAfterFees);

        emit Withdraw(_msgSender(), _amount, amountAfterFees);
    }

    function withdrawPops(uint256 amount) external onlyOwner {
        if (amount > getPopsBalance()) revert InsufficientPOPS();
        IERC20(popsToken).transfer(treasury, amount);
        emit WithdrawPops(_msgSender(), amount, treasury);
    }

    function getPending(address _user) public view returns (uint256) {
        UserInfo memory userInfo = userInfos[_user];
        uint256 userAmount = userInfo.amount;
        if (userAmount > 0 && block.number > userInfo.lastRewardBlock) {
            uint256 multiplier = _getMultiplier(
                userInfo.lastRewardBlock,
                block.number
            );
            if (multiplier == 0) return 0;
            return (userAmount * rewardPerBlock * multiplier) / 1e12;
        }
        return 0;
    }

    function getPopsBalance() public view returns (uint256) {
        return IERC20(popsToken).balanceOf(address(this));
    }

    function getTokenRatio() public view returns (uint256, uint256) {
        (uint112 _reserve0, uint112 _reserve1, ) = ISiclePair(pairAddress)
            .getReserves();
        if (isToken0Pops) {
            return (_reserve0, _reserve1);
        }
        return (_reserve1, _reserve0);
    }

    function isCurrentPopsTokenAboveAvg5d() public view returns (bool) {
        // Price of POPS token is expressed in terms of {Stake Token}/POPS (ratio)
        uint256 amount = 1e18;
        uint256 priceTWAP5d = IOracleTWAP(oracleTWAP5d).consult(
            popsToken,
            amount
        );
        uint256 priceTWAP5m = IOracleTWAP(oracleTWAP5m).consult(
            popsToken,
            amount
        );
        return priceTWAP5d <= priceTWAP5m;
    }

    function _claim() private {
        UserInfo storage userInfo = userInfos[_msgSender()];
        if (claimDisabled) revert ClaimDisabled();
        if (userInfo.amount == 0) revert NoStake();

        uint256 pending = getPending(_msgSender());
        if (pending > 0) {
            userInfo.rewardDebt += pending;
            userInfo.lastRewardBlock = block.number;
            _transferStakeTokenToUser(_msgSender(), pending);
        }
        emit Claim(_msgSender(), pending);
    }

    function _getAmountAfterFees(
        uint256 amount
    ) private returns (uint256 sTokenAmount) {
        uint256 fees = isCurrentPopsTokenAboveAvg5d() // If the price rises are because the difference between POPS's and Stake Token's reserve decrease
            ? 0
            : (amount * withdrawalFee) / 1e4;
        accumulatedFees += fees;
        sTokenAmount = amount - fees;
    }

    function _getMultiplier(uint from, uint to) private view returns (uint) {
        if (from < endBlock && to < endBlock) {
            return to - from;
        } else if (from < endBlock && to > endBlock) {
            return endBlock - from;
        }
        return 0;
    }

    function _setPopsTokenRatioAvgLast5d() private {
        popsTokenRatioAvgLast5d = IOracleTWAP(oracleTWAP5d).consult(
            stakeToken,
            1e10
        );
    }

    function _swapStakeToPops(
        uint256 amountStakeIn,
        uint256 amountPopsOutMin
    ) private {
        address[] memory path = new address[](2);
        path[0] = stakeToken;
        path[1] = popsToken;

        uint256 stakeBalance = IERC20(stakeToken).balanceOf(address(this));
        uint256 popsBalance = IERC20(stakeToken).balanceOf(address(this));
        IERC20(stakeToken).approve(sicleRouter02, amountStakeIn);
        IERC20(popsToken).approve(sicleRouter02, amountPopsOutMin);
        ISicleRouter02(sicleRouter02).swapExactTokensForTokens(
            amountStakeIn,
            amountPopsOutMin,
            path,
            address(this),
            block.timestamp + 5 minutes // deadline
        );
        emit SwapStakeToPops(
            _msgSender(),
            amountStakeIn,
            amountPopsOutMin,
            stakeBalance,
            IERC20(stakeToken).balanceOf(address(this)),
            popsBalance,
            IERC20(stakeToken).balanceOf(address(this))
        );
    }

    function _transferStakeTokenToUser(address user, uint256 amount) private {
        uint256 stakeTokenBalance = IERC20(stakeToken).balanceOf(address(this));
        if (stakeTokenBalance < amount) {
            // sell some pops to get enough stake token
            uint256 stakeTokenNeeded = amount - stakeTokenBalance;

            // add 5% to allow for slippage and/or price change from TWAP
            uint256 popsRequired = IOracleTWAP(oracleTWAP5m).consult(
                stakeToken,
                stakeTokenNeeded + ((stakeTokenNeeded * swapSafetyMargin) / 1e4)
            ); // given by oracle, returns pops amount

            if (getPopsBalance() < popsRequired)
                revert InsufficientPOPSForSwap();
            address[] memory path = new address[](2);
            path[0] = popsToken;
            path[1] = stakeToken;

            IERC20(popsToken).approve(sicleRouter02, popsRequired);
            ISicleRouter02(sicleRouter02).swapExactTokensForTokens(
                popsRequired,
                stakeTokenNeeded,
                path,
                address(this),
                block.timestamp + 5 minutes // deadline
            );
        }

        if (IERC20(stakeToken).balanceOf(address(this)) < amount)
            revert InsufficientStakeToken();

        IERC20(stakeToken).transfer(user, amount);
    }

    function _updateOracles() private {
        if (IOracleTWAP(oracleTWAP5d).update()) {
            _setPopsTokenRatioAvgLast5d();
        }
        IOracleTWAP(oracleTWAP5m).update();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

interface IOracleTWAP {
    function consult(
        address token,
        uint amountIn
    ) external view returns (uint amountOut);

    function update() external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface ISiclePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

//IUniswapV2Router01
interface ISicleRouter01 {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './ISicleRouter01.sol';

//IUniswapV2Router02
interface ISicleRouter02 is ISicleRouter01 {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Proxyable is Ownable {

    mapping(address => bool) public proxyToApproved; // proxy allowance for interaction with future contract

    modifier onlyProxy() {
        require(proxyToApproved[_msgSender()], "Only proxy");
        _;
    }

    function setProxyState(address proxyAddress, bool value) public onlyOwner {
        proxyToApproved[proxyAddress] = value;
    } 
}