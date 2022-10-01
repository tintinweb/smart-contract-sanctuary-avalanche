/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-30
*/

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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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

// File: contracts/Pool.sol


pragma solidity ^0.8;



contract Pool is Ownable, AccessControl {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct DailyPool {
        uint inTime;
        uint totalAmount;
    }
    DailyPool[] public dailyPool;

    function removePoolRecord(uint startTime, uint endTime) public onlyRole(ADMIN_ROLE) {
        uint startIndex = 0;
        uint endIndex = 0;
        bool isFirst = true;

        for (uint i=0; i < dailyPool.length; i++) {
            if (dailyPool[i].inTime >= startTime && dailyPool[i].inTime <= endTime ) {
                if (isFirst) {
                    startIndex = i;
                    isFirst = false;
                }
                endIndex = i;
            }
        }

        uint indexDifference = endIndex - startIndex;
        if (indexDifference == 0) {
            for (uint i = startIndex; i<dailyPool.length-1; i++){
                dailyPool[i] = dailyPool[i+1];
            }
            delete dailyPool[dailyPool.length-1];
            dailyPool.pop();
        } else {
            for (uint i = startIndex; i<dailyPool.length-indexDifference-1; i++){
                dailyPool[i] = dailyPool[i+indexDifference+1];
            }
            for (uint i = 0; i < indexDifference+1; i++) {
                delete dailyPool[dailyPool.length-1];
                dailyPool.pop();
            }
        }
    }

    function addNewPool() external payable onlyRole(ADMIN_ROLE) {
        DailyPool memory newPool = DailyPool(block.timestamp, msg.value);
        dailyPool.push(newPool);
    }

    function getEntirePool() public view returns (DailyPool[] memory ) {
        return dailyPool;
    }
}
// File: contracts/Staking.sol


pragma solidity ^0.8;




contract StakingRewards is Ownable, AccessControl, Pool {

    event StakeReward(address owner, uint _stakeID, uint256 _finalInterest, uint recordTime);
    event AddStake(address owner, uint _stakeID, uint256 amount, uint recordTime);

    event WithdrawalReward(address owner, uint _stakeID, uint withdrawAmount, uint recordTime);
    event WithdrawalPrincipal(address owner, uint _stakeID, uint withdrawAmount, uint recordTime);

    struct StakeMeta {
        uint period; // 1, 3, 6, 12 days / months
        uint rewardRate; // 1666666667 => 1666666667 /1e10 =   
        uint penalty;  // 30 => 30%
    }

    struct DailyInterest {
        uint currentDate;
        uint rewardAmount;
        uint rewardIndex;
        bool isTaken;
        uint withdrawDate;
    }

    struct StakeRecord {
        StakeMeta stakeMeta;
        uint stakeID;
        uint stakeAmount;
        uint userProportion; // // e.g. 2500000000 =>  2500000000 / 1e10 = 0.25 => 25%
        uint stakeStartDate;
        address owner;
        DailyInterest[] dailyInterest;
        uint withdrawDate;
        bool isWithdraw;
        bool isExist;
    }

    struct StakeAddress {
        address owner;
        uint stakeID;
    }

    StakeAddress[] public stakeAddressList;
    uint[] removeIndex;

    StakeMeta[] public stakeOption;
    StakeMeta stakeMetaRc;
    mapping(address => uint[]) public stakeAddressIndex;
    mapping(address => mapping(uint => StakeRecord)) public stakeRecord;

    // IN MINUTES - FOR DEBUG ONLY
    uint private _oneDay = 60 * 5;
    // uint private _oneDay = 60 * 60;

    constructor(uint[] memory stakePeriod, uint[] memory rewardRate, uint[] memory penalty) {
        require(stakePeriod.length == rewardRate.length, "Not enough info");
        require(stakePeriod.length == penalty.length, "Not enough info");
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint i=0; i<stakePeriod.length; i++) {
            stakeMetaRc = StakeMeta({
                period: stakePeriod[i],
                rewardRate: rewardRate[i],
                penalty: penalty[i]
            });
            stakeOption.push(stakeMetaRc);
        }
    }

    function addAdmin(address account) public virtual onlyRole(ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, account);
    }

    function remove(uint index) private {
        if (index >= stakeAddressList.length) return; 
        delete stakeRecord[stakeAddressList[index].owner][stakeAddressList[index].stakeID];
    }

    function addStakeRecord (uint period) external payable {
        require(msg.value > 0, "The Stake amount cannot be 0");
        StakeMeta memory targetStakeMeta;
        bool isFound = false;
        for (uint i=0; i<stakeOption.length; i++) {
            if (period == stakeOption[i].period) {
                targetStakeMeta = stakeOption[i];
                isFound = true;
            }
        }

        require(isFound, "Wrong Period chosen, only 2, 4, 6, 8 days");

        uint userStakeRecordIndex = stakeAddressIndex[msg.sender].length;

        StakeRecord storage newStakeRecord = stakeRecord[msg.sender][userStakeRecordIndex];

        newStakeRecord.stakeMeta = targetStakeMeta;
        newStakeRecord.stakeID = userStakeRecordIndex;
        newStakeRecord.stakeAmount = msg.value;
        newStakeRecord.stakeStartDate = block.timestamp;
        newStakeRecord.owner = msg.sender;
        newStakeRecord.isWithdraw = false;
        newStakeRecord.isExist = true;
        stakeAddressIndex[msg.sender].push(stakeAddressIndex[msg.sender].length);
        StakeAddress memory _stakeAddress = StakeAddress(msg.sender, userStakeRecordIndex);
        stakeAddressList.push(_stakeAddress);
        emit AddStake(msg.sender, userStakeRecordIndex, msg.value, block.timestamp);
    }

    function calculateStakingReward(uint startTime, address[] memory owner, uint[] memory _stakeID, uint[] memory _rewardAmount) public onlyRole(ADMIN_ROLE) {
        require(owner.length == _stakeID.length, "The number of owner and the number of stakeID should be equal");
        require(owner.length == _rewardAmount.length, "The number of owner and the number of user proportion should be equal");

        // Calculate the final interest rate & user reward
        for (uint i=0; i<owner.length; i++) {
            DailyInterest memory _dailyInterest = DailyInterest(startTime, _rewardAmount[i], stakeRecord[owner[i]][_stakeID[i]].dailyInterest.length, false, 0);
                stakeRecord[owner[i]][_stakeID[i]].dailyInterest.push(_dailyInterest);
                emit StakeReward(stakeRecord[owner[i]][_stakeID[i]].owner, _stakeID[i], _rewardAmount[i], block.timestamp);
        }
    }

    function withdrawInterest (uint _stakeID) public payable {
        require(stakeRecord[msg.sender][_stakeID].isExist, "There is not stake record with this stake id");
        uint selectedReward = 0;
        for (uint i=0; i < stakeRecord[msg.sender][_stakeID].dailyInterest.length; i++) {
            if (!stakeRecord[msg.sender][_stakeID].dailyInterest[i].isTaken) {
                selectedReward += stakeRecord[msg.sender][_stakeID].dailyInterest[i].rewardAmount;
                stakeRecord[msg.sender][_stakeID].dailyInterest[i].withdrawDate = block.timestamp;
                stakeRecord[msg.sender][_stakeID].dailyInterest[i].isTaken = true;
            }
        }
        require(selectedReward > 0, "There is no interest can be retrieved");
        payable(stakeRecord[msg.sender][_stakeID].owner).transfer(selectedReward);
        emit WithdrawalReward(msg.sender, _stakeID, selectedReward, block.timestamp);
    }
    function withdrawPrincipal (uint _stakeID) public payable {
        require(stakeRecord[msg.sender][_stakeID].isExist, "There is not stake record with this stake id");
        require(!stakeRecord[msg.sender][_stakeID].isWithdraw, "This prinical has been withdrawed");
        require(stakeRecord[msg.sender][_stakeID].owner == msg.sender, "This stake record is NOT belongs to this address");
        uint _removeIndex = 0;
        for (uint i=0; i<stakeAddressList.length; i++) {
            if (stakeAddressList[i].stakeID == _stakeID && stakeAddressList[i].owner == msg.sender) _removeIndex = i; 
        }
        withdrawPrincipalFunc(msg.sender, _stakeID, _removeIndex);
        
    }

    function adminWithdrawPrincipal(uint _startIndex, uint _totalNumber) public payable onlyRole(ADMIN_ROLE) {
        for(uint i=_startIndex; i<_startIndex + _totalNumber; i++) {
            withdrawPrincipalFunc(stakeAddressList[i].owner, stakeAddressList[i].stakeID, i);
        }
    }

    function withdrawPrincipalFunc(address _owner, uint _stakeID, uint _removeIndex) private {
        uint _stakeAmount = stakeRecord[_owner][_stakeID].stakeAmount;
        if (_stakeAmount > 0) {
            if ((block.timestamp - stakeRecord[_owner][_stakeID].stakeStartDate) / _oneDay < (stakeRecord[_owner][_stakeID].stakeMeta.period * 12) ) {
                _stakeAmount = _stakeAmount * (100 - stakeRecord[_owner][_stakeID].stakeMeta.penalty ) / 100;
            }

            uint selectedReward = 0;
            for (uint j=0; j < stakeRecord[_owner][_stakeID].dailyInterest.length; j++) {
                if (!stakeRecord[_owner][_stakeID].dailyInterest[j].isTaken) {
                    selectedReward += stakeRecord[_owner][_stakeID].dailyInterest[j].rewardAmount;
                    stakeRecord[_owner][_stakeID].dailyInterest[j].withdrawDate = block.timestamp;
                    stakeRecord[_owner][_stakeID].dailyInterest[j].isTaken = true;
                    emit WithdrawalReward(_owner, _stakeID, stakeRecord[_owner][_stakeID].dailyInterest[j].rewardAmount, block.timestamp);
                }
            }
            if (selectedReward > 0) {
                payable(stakeRecord[_owner][_stakeID].owner).transfer(selectedReward);
            }
            payable(stakeRecord[_owner][_stakeID].owner).transfer(_stakeAmount);
            stakeRecord[_owner][_stakeID].isWithdraw = true;
            emit WithdrawalPrincipal(_owner, _stakeID, _stakeAmount, block.timestamp);
            remove(_removeIndex);
        }
    }

    function getFullStakeRecord(uint _startIndex, uint _totalNumber) public view returns (StakeRecord[] memory) {
        StakeRecord[] memory _stakeRecordList = new StakeRecord[](_totalNumber);
        for (uint i=_startIndex; i<_startIndex + _totalNumber ; i++) {
            _stakeRecordList[i-_startIndex] = stakeRecord[stakeAddressList[i].owner][stakeAddressList[i].stakeID];
        }
        return _stakeRecordList;
    }

    function getFullStakeRecordLength() public view returns (uint) {
        return stakeAddressList.length;
    }
    function getFullStakeRecordByaddress(address owner) public view returns (StakeRecord[] memory) {
        StakeRecord[] memory _stakeRecordList = new StakeRecord[](stakeAddressIndex[owner].length);
        for (uint i=0; i<stakeAddressIndex[owner].length; i++) {
            _stakeRecordList[i] = stakeRecord[owner][stakeAddressIndex[owner][i]];
        }
        return _stakeRecordList;
    }
    function getStakeRecordLength(address owner) public view returns (uint) {
        return stakeAddressIndex[owner].length;
    }
    function getDailyInterestArray(address owner, uint stakeIndex) public view returns (DailyInterest[] memory) {
        return stakeRecord[owner][stakeIndex].dailyInterest;
    }
    function getDailyInterest(address owner, uint stakeIndex, uint dailyInterestIndex) public view returns (DailyInterest memory) {
        return stakeRecord[owner][stakeIndex].dailyInterest[dailyInterestIndex];
    }
    function getStakeOption() public view returns (StakeMeta[] memory) {
        return stakeOption;
    }
}