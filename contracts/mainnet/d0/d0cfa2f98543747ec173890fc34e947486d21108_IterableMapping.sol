/**
 *Submitted for verification at snowtrace.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Node {
    struct NodeFee {
        uint256 fee;
        uint256 lastPaidDate;
        uint256 lastPaidFee;
    }

    struct NodeBoosterRecord {
        uint256 winstar;
        uint256 luckyYard;
        uint256 royalFox;
        uint256 sparkTouch;
    }

    struct NodeEntity {
        string name; // Node name
        uint256 creationTime; // Node creation time
        uint256 lastClaimTime; // Node last claim time
        uint256 rewardAvailable; // Node reward available
        uint256 isolationPeriod; // Node isolation period
        uint256 claimTax; // Node claim tax
        uint256 claimedReward; // Node claimed reward
        NodeFee monthlyFee; // Node monthly fee
        NodeBoosterRecord boosterInfo; // Node booster info
    }
}

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

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

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/access/AccessControl.sol

// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        virtual
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
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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

contract ContexiaNode is Node, AccessControl {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    AggregatorV3Interface public priceFeed;
    IterableMapping.Map private nodeOwners;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant NODE_BOOSTER_ROLE = keccak256("NODE_BOOSTER_ROLE");

    // =========================== State Variable =================================
    mapping(address => NodeEntity[]) private _nodesOfUser;
    mapping(address => uint256) public _totalNodesCompounded;

    uint256 public constant PERCENT_DENOMINATOR = 1000;
    uint256 public feeDueDays = 30 days;
    uint256 public perNodeBoosterLimit = 1;
    uint256 public nodePrice;
    uint256 public rewardPerNode;
    uint256 public isolationPeriod;
    uint256 public nodeMaintenanceFee;
    uint256 public claimTax;
    uint256 public rewardStartTime;
    uint256 public totalNodesCreated;
    bool public isLaunched;

    event NodeCreated(address indexed _user, uint256 indexed _nodesAmount);

    event CashoutReward(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _time
    );

    constructor(
        uint256 _nodePrice,
        uint256 _rewardPerNode,
        uint256 _claimTax,
        uint256 _isolationPeriod,
        uint256 _nodeMaintenanceFee,
        address _priceFeed,
        address _nodePurchaser
    ) {
        nodePrice = _nodePrice;
        rewardPerNode = _rewardPerNode;
        claimTax = _claimTax;
        isolationPeriod = _isolationPeriod;
        nodeMaintenanceFee = _nodeMaintenanceFee;
        priceFeed = AggregatorV3Interface(_priceFeed);
        rewardStartTime = block.timestamp + 60 days;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, _nodePurchaser);
    }

    modifier isRole(bytes32 role) {
        require(hasRole(role, msg.sender), "Unauthorized access");
        _;
    }

    // -----------------------------Public Functions---------------------------------

    function createNode(address account, string memory nodeName)
        public
        isRole(MINTER_ROLE)
    {
        NodeFee memory _nodeFee = NodeFee(
            nodeMaintenanceFee,
            block.timestamp,
            0
        );
        NodeBoosterRecord memory _boosterInfo = NodeBoosterRecord(0, 0, 0, 0);

        _nodesOfUser[account].push(
            NodeEntity({
                name: nodeName,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                rewardAvailable: rewardPerNode,
                isolationPeriod: isolationPeriod,
                claimTax: claimTax,
                claimedReward: 0,
                monthlyFee: _nodeFee,
                boosterInfo: _boosterInfo
            })
        );
        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;

        emit NodeCreated(account, nodePrice);
    }

    function _cashoutNodeReward(address account, uint256 _creationTime)
        external
        isRole(MINTER_ROLE)
        returns (uint256)
    {
        require(
            _creationTime > 0,
            "CASHOUT: Creation Time must be greater than 0"
        );
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(numberOfNodes > 0, "CASHOUT: You don't have nodes to cash-out");
        NodeEntity storage node = _getNodeWithCreatime(account, _creationTime);
        require(
            claimable(node),
            "CASHOUT: Wait for isolation period to complete."
        );
        require(
            isFeePaid(node.monthlyFee),
            "CASHOUT: Maintenance fee not paid."
        );

        uint256 rewardNode = getAvailableNodeReward(node, block.timestamp);
        node.claimedReward += rewardNode;
        node.lastClaimTime = block.timestamp;

        emit CashoutReward(account, rewardNode, block.timestamp);
        return rewardNode;
    }

    function _cashoutAllNodesReward(address account)
        external
        isRole(MINTER_ROLE)
        returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i; i < nodesCount; i++) {
            _node = nodes[i];
            require(
                claimable(_node),
                "NODE: Wait for isolation period to complete."
            );
            require(
                isFeePaid(_node.monthlyFee),
                "NODE CASHOUT: Maintenance fee not paid."
            );
            uint256 _availableReward = getAvailableNodeReward(
                _node,
                block.timestamp
            );
            rewardsTotal += _availableReward;
            _node.claimedReward += _availableReward;
            _node.lastClaimTime = block.timestamp;
        }

        emit CashoutReward(account, rewardsTotal, block.timestamp);
        return rewardsTotal;
    }

    function updateProductionRate(
        address _user,
        uint256 _nodeIndex,
        uint256 _productionRatePer
    ) external isRole(NODE_BOOSTER_ROLE) {
        NodeEntity storage node = _nodesOfUser[_user][_nodeIndex];
        require(
            node.boosterInfo.winstar < perNodeBoosterLimit,
            "NODE: Already Boosted"
        );

        node.boosterInfo.winstar += 1;
        node.rewardAvailable = node.rewardAvailable.add(
            node.rewardAvailable.mul(_productionRatePer).div(
                PERCENT_DENOMINATOR
            )
        );
    }

    function updateNodeClaimTax(
        address _user,
        uint256 _nodeIndex,
        uint256 _taxPer
    ) external isRole(NODE_BOOSTER_ROLE) {
        NodeEntity storage node = _nodesOfUser[_user][_nodeIndex];
        require(
            node.boosterInfo.luckyYard < perNodeBoosterLimit,
            "NODE: Already Boosted"
        );

        node.boosterInfo.luckyYard += 1;
        node.claimTax = node.claimTax.sub(
            node.claimTax.mul(_taxPer).div(PERCENT_DENOMINATOR)
        );
    }

    function updateMonthlyFee(
        address _user,
        uint256 _nodeIndex,
        uint256 _updatedFee
    ) external isRole(NODE_BOOSTER_ROLE) {
        NodeEntity storage node = _nodesOfUser[_user][_nodeIndex];
        require(
            node.boosterInfo.royalFox < perNodeBoosterLimit,
            "NODE: Already Boosted"
        );

        node.boosterInfo.royalFox += 1;
        node.monthlyFee.fee = _updatedFee;
    }

    function updateIsolationPeriod(
        address _user,
        uint256 _nodeIndex,
        uint256 _days
    ) external isRole(NODE_BOOSTER_ROLE) {
        NodeEntity storage node = _nodesOfUser[_user][_nodeIndex];
        require(
            node.boosterInfo.sparkTouch < perNodeBoosterLimit,
            "NODE: Already Boosted"
        );

        node.boosterInfo.sparkTouch += 1;
        node.isolationPeriod = node.isolationPeriod.sub(_days);
    }

    function payNodeMaintenanceFee(
        address account,
        uint256 _creationTime,
        uint256 _fee
    ) external isRole(MINTER_ROLE) {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(numberOfNodes > 0, "NODE: You don't have any nodes");
        NodeEntity storage node = _getNodeWithCreatime(account, _creationTime);
        NodeFee storage nodeFee = node.monthlyFee;
        require(
            nodeFee.lastPaidDate != 0 &&
                block.timestamp >= (nodeFee.lastPaidDate + feeDueDays),
            "PAYFEE: fee already paid"
        );
        (uint256 duration, uint256 feeAmount) = calculateNodeFee(nodeFee);
        require(_fee >= usdToAvax(feeAmount), "PAYFEE: Not enough to pay fee");
        nodeFee.lastPaidDate += duration.mul(feeDueDays);
        nodeFee.lastPaidFee = _fee;
    }

    /**
     * @notice Compounds all pending CON into new NODEs!
     */
    function compoundAll(address _account)
        external
        isRole(MINTER_ROLE)
        returns (uint256, uint256)
    {
        (, uint256 totalRewards) = _getRewardAmountOf(_account);
        uint256 nodesCount = totalRewards / nodePrice;
        require(nodesCount > 0, "You dont have enough pending CON");
        return _compound(_account, nodesCount);
    }

    // -----------------------------Internal's Functions---------------------------------

    /**
     * @notice Compounds CON
     */
    function _compound(address _account, uint256 _amount)
        internal
        returns (uint256, uint256)
    {
        uint256 totalCost = _amount * nodePrice;

        // Keep track of the CON that we've internally claimed
        uint256 takenCON = 0;

        // For each NODE that msg.sender owns, drain their pending CON amounts
        // until we have enough CON to cover the totalCost
        uint256 balance = _getNodeNumberOf(_account);
        for (uint256 i = 0; i < balance; ++i) {
            // Break when we've taken enough CON
            if (takenCON >= totalCost) {
                break;
            }
            // Get the pending CON
            uint256 tokenPendingCON = getRewardForCompounding(_account, i);

            takenCON += tokenPendingCON;
            incrementCompoundNode(_account);
        }

        // If the taken con isn't above the total cost for this transaction, then entirely revert
        require(takenCON >= totalCost, "You dont have enough pending MEAD");

        // For each, mint a new NODE
        for (uint256 i = 0; i < _amount; ++i) {
            createNode(_account, "COMPOUNDED");
        }

        return (totalCost, takenCON - totalCost);
    }

    function binary_search(
        NodeEntity[] memory arr,
        uint256 low,
        uint256 high,
        uint256 x
    ) private view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low).div(2);
            if (arr[mid].creationTime == x) {
                return int256(mid);
            } else if (arr[mid].creationTime > x) {
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }

    function _getNodeWithCreatime(address _user, uint256 _creationTime)
        private
        view
        returns (NodeEntity storage)
    {
        NodeEntity[] storage nodes = _nodesOfUser[_user];
        uint256 index = getNodeIndexByCreationTime(_user, _creationTime);
        return nodes[index];
    }

    function claimable(NodeEntity memory node) private view returns (bool) {
        return block.timestamp >= node.lastClaimTime + node.isolationPeriod;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    // -----------------------------View Functions---------------------------------

    function getNodeInfo(address _user, uint256 _creationTime)
        public
        view
        returns (
            uint256 _currentReward,
            uint256 _lastClaimTime,
            uint256 _isolationPeriod,
            uint256 _claimTax,
            uint256 _monthlyFee
        )
    {
        NodeEntity memory node = _getNodeWithCreatime(_user, _creationTime);
        return (
            node.rewardAvailable,
            node.lastClaimTime,
            node.isolationPeriod,
            node.claimTax,
            node.monthlyFee.fee
        );
    }

    function getNodeIndexByCreationTime(address _user, uint256 _blockTime)
        public
        view
        returns (uint256 validIndex)
    {
        NodeEntity[] storage nodes = _nodesOfUser[_user];
        uint256 numberOfNodes = nodes.length;
        require(numberOfNodes > 0, "GET_NODE: You don't have nodes");
        int256 index = binary_search(nodes, 0, numberOfNodes, _blockTime);
        require(index >= 0, "NODE_SEARCH: No NODE Found with this blocktime");
        validIndex = uint256(index);
    }

    function getAvailableNodeReward(NodeEntity memory node, uint256 _timestamp)
        public
        view
        returns (uint256 availableReward)
    {
        uint256 duration;
        if (block.timestamp < rewardStartTime) {
            duration = 0;
        } else if (node.lastClaimTime > rewardStartTime) {
            duration = _timestamp - node.lastClaimTime;
        } else {
            duration = _timestamp - rewardStartTime;
        }
        availableReward = duration.mul(node.rewardAvailable);
    }

    function getNodePayableFee(address account, uint256 _creationTime)
        external
        view
        returns (uint256 _feeAmount)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(numberOfNodes > 0, "NODE: You don't have any nodes");
        NodeEntity storage node = _getNodeWithCreatime(account, _creationTime);
        NodeFee storage nodeFee = node.monthlyFee;

        (, uint256 feeAmount) = calculateNodeFee(nodeFee);
        return usdToAvax(feeAmount.mul(10**priceFeed.decimals()));
    }

    function calculateNodeFee(NodeFee memory nodeFee)
        public
        view
        returns (uint256 duration, uint256 _fee)
    {
        duration = (
            block.timestamp.sub(nodeFee.lastPaidDate, "Subtraction Overflow")
        ).div(feeDueDays, "Division Overflow");
        _fee = nodeFee.fee * duration;
    }

    function getDueFeeInfo(address account, uint256 _creationTime)
        public
        view
        returns (uint256 dueDate, uint256 lastPaidFee)
    {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(numberOfNodes > 0, "NODE: You don't have any nodes");
        NodeEntity storage node = _getNodeWithCreatime(account, _creationTime);
        NodeFee storage nodeFee = node.monthlyFee;

        return ((nodeFee.lastPaidDate + feeDueDays), nodeFee.lastPaidFee);
    }

    function _getRewardAmountOf(address account)
        public
        view
        returns (uint256 nodesTax, uint256 rewardCount)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            nodesTax += nodes[i].monthlyFee.fee;
            rewardCount += getAvailableNodeReward(nodes[i], block.timestamp);
        }
    }

    function _getRewardAmountOf(address account, uint256 _creationTime)
        public
        view
        returns (uint256 nodeTax, uint256 nodeReward)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(account, _creationTime);
        nodeTax = node.monthlyFee.fee;
        nodeReward = getAvailableNodeReward(node, block.timestamp);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function usdToAvax(uint256 usd) public view returns (uint256) {
        return usd.mul(1e18).div(getLatestPrice());
    }

    function _getNodesNames(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET NAMES: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory names = nodes[0].name;
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            names = string(abi.encodePacked(names, separator, _node.name));
        }
        return names;
    }

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _creationTimes = uint2str(nodes[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    uint2str(_node.creationTime)
                )
            );
        }
        return _creationTimes;
    }

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(
            getAvailableNodeReward(nodes[0], block.timestamp)
        );
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(getAvailableNodeReward(_node, block.timestamp))
                )
            );
        }
        return _rewardsAvailable;
    }

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "LAST CLAIME TIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _lastClaimTimes = uint2str(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    uint2str(_node.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function getUserCompoundedNodesCount(address _account)
        external
        view
        returns (string memory)
    {
        return uint2str(_totalNodesCompounded[_account]);
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return nodeOwners.get(account);
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }

    function isFeePaid(NodeFee memory _nodeMaintenanceFee)
        public
        view
        returns (bool)
    {
        return (_nodeMaintenanceFee.fee == 0 ||
            block.timestamp < (_nodeMaintenanceFee.lastPaidDate + feeDueDays));
    }

    // -----------------------------Owner's Functions---------------------------------

    function setNodeMaintenanceFees(uint256 _nodeMaintenanceFee)
        external
        isRole(OWNER_ROLE)
    {
        nodeMaintenanceFee = _nodeMaintenanceFee;
    }

    function getRewardForCompounding(address _account, uint256 _nodeCount)
        public
        isRole(MINTER_ROLE)
        returns (uint256)
    {
        require(isNodeOwner(_account), "GET REWARD OF: NO NODE OWNER");
        uint256 _totalReward = 0;

        NodeEntity storage node = _nodesOfUser[_account][_nodeCount];

        uint256 _nodeReward = getAvailableNodeReward(node, block.timestamp);
        node.claimedReward += _nodeReward;
        node.lastClaimTime = block.timestamp;
        _totalReward += _nodeReward;

        return _nodeReward;
    }

    function incrementCompoundNode(address _account)
        public
        isRole(MINTER_ROLE)
    {
        _totalNodesCompounded[_account] += 1;
    }

    function updatePriceFee(AggregatorV3Interface _feed)
        external
        isRole(OWNER_ROLE)
    {
        priceFeed = _feed;
    }

    function _changeNodePrice(uint256 newNodePrice)
        external
        isRole(OWNER_ROLE)
    {
        nodePrice = newNodePrice;
    }

    function _changeRewardPerNode(uint256 newPrice)
        external
        isRole(OWNER_ROLE)
    {
        rewardPerNode = newPrice;
    }

    function _changeClaimTime(uint256 newTime) external isRole(OWNER_ROLE) {
        isolationPeriod = newTime;
    }

    function changeFeeDueDays(uint256 _days) external isRole(OWNER_ROLE) {
        feeDueDays = _days;
    }

    function launchReward() external isRole(OWNER_ROLE) {
        require(!isLaunched, "NODE: ALREADY LAUNCHED");
        rewardStartTime = block.timestamp;
        isLaunched = true;
    }

    function updateClaimTax(uint256 _tax) external isRole(OWNER_ROLE) {
        claimTax = _tax;
    }

    function setPerNodeBoosterLimit(uint256 _limit)
        external
        isRole(OWNER_ROLE)
    {
        perNodeBoosterLimit = _limit;
    }
}