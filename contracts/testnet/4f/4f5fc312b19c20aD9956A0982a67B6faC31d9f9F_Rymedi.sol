// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;
import "./Proxiable.sol";
import "./AccessControl.sol";
import "./LibraryLock.sol";
// import "hardhat/console.sol";

/**
 * @title Rymedi logic contract for Data storage
 * @author Mayank Saxena (@forkblocks)
 * @notice Use this contract to wite data to Proxy contract
 */
contract Rymedi is Proxiable, AccessControl, LibraryLock {
    /// @dev variables
    mapping(bytes32 => bytes32) records;
    mapping(bytes32 => bytes32) deletedRecords;
    bytes32[] recordKeyList;
    bytes32[] deletedRecordKeys;
    string[] roles;

    /// @dev Owner - DEFAULT_ADMIN_ROLE + user roles
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant SENDER = keccak256("SENDER");

    /// @dev events
    event AddRecord(bytes32 indexed key, bytes32 indexed value);
    event RemoveRecord(bytes32 indexed key, bytes32 indexed value);

    // ========================================= Manage Rymedi Data =======================================================================

    /*
     * we will calculate the sha3 of the rymediInitialize() and we will pass the hash while deploying the proxy contract.
     * This is like our constructor function.
     * We are telling our proxy contract to call this function as contructor.
     */
    function rymediInitialize() public {
        require(!initialized, "Already initalized");
        initialize();
        roles.push("DEFAULT_ADMIN_ROLE");
        roles.push("ADMIN");
        roles.push("SENDER");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(SENDER, ADMIN);
    }

    /**
     * @notice Push single record - Only SENDER
     * @param key bytes32 - sha256 hash
     * @param value bytes32 - sha256 hash
     */
    function addRecord(
        bytes32 key,
        bytes32 value
    ) public onlyRole(SENDER) delegatedOnly returns (bool) {
        require(records[key] == 0, "Record's Key already exist");
        records[key] = value;
        recordKeyList.push(key);
        emit AddRecord(key, value);
        return true;
    }

    /**
     * @notice Push multiple records in  single transaction - Only SENDER
     * @param keys bytes32 - sha256 hash
     * @param values bytes32 - sha256 hash
     */
    function addBulkRecords(
        bytes32[] memory keys,
        bytes32[] memory values
    ) public onlyRole(SENDER) delegatedOnly returns (bool) {
        require(
            keys.length == values.length,
            "Lengths of keys and values arrays do not match"
        );
        for (uint i = 0; i < keys.length; i++) {
            require(records[keys[i]] == 0, "Record's Key already exist");
            records[keys[i]] = values[i];
            recordKeyList.push(keys[i]);
            emit AddRecord(keys[i], values[i]);
        }
        return true;
    }

    /**
     * @notice Delete records against keys
     * @param key bytes32 - sha256 hash
     * @dev Delete keys are stored and emitted via events
     */
    function removeRecord(
        bytes32 key
    ) public onlyAdministrators delegatedOnly returns (bool) {
        bytes32 value = records[key];
        deletedRecordKeys.push(key);
        deletedRecords[key] = records[key];
        records[key] = 0;
        emit RemoveRecord(key, value);
        return true;
    }

    /**
     * @notice Updates the address of Logic contract inside Proxy
     * @param newLogicAddress address
     * @dev Only Owner - Used to update the implemented logic
     */
    function updateCode(
        address newLogicAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) delegatedOnly {
        updateCodeAddress(newLogicAddress, msg.sender);
    }

    // =========================================  Getter functions ========================================================================

    /**
     * @notice Fetch value against key from Records
     * @param key bytes32 - sha256 hash
     */
    function getRecord(bytes32 key) public view returns (bytes32) {
        return records[key];
    }

    /**
     * @notice Fetch record count stats
     * @return totalKeyCount Total count of pushed records
     * @return deletedKeyCount Number of deleted keys
     * @return activeRecordsCount Number of Keys with Value
     */
    function recordCount()
        public
        view
        returns (
            uint totalKeyCount,
            uint deletedKeyCount,
            uint activeRecordsCount
        )
    {
        return (
            recordKeyList.length,
            deletedRecordKeys.length,
            recordKeyList.length - deletedRecordKeys.length
        );
    }

    /**
     * @notice List all role types
     */
    function rolesList() public view returns (string[] memory) {
        return roles;
    }

    /**
     * @notice List all keys pushed
     */
    function getRecordKeyList() public view returns (bytes32[] memory) {
        return recordKeyList;
    }

    /**
     * @notice Fetch key against Index
     * @param index uint
     */
    function getKeyAgainstIndex(uint index) public view returns (bytes32) {
        return recordKeyList[index];
    }

    /**
     * @notice List all deleted keys
     */
    function getDeletedRecordKeys() public view returns (bytes32[] memory) {
        return deletedRecordKeys;
    }

    /**
     * @notice Get deleted Ket against Index
     * @param index uint
     */
    function getDeletedKeyAgainstIndex(
        uint index
    ) public view returns (bytes32) {
        return deletedRecordKeys[index];
    }

    // ========================================= Modifiers ================================================================================

    /**
     * @notice Modifier - Implement either Owner or Admin
     */
    modifier onlyAdministrators() {
        require(
            isOwner(msg.sender) || isAdmin(msg.sender),
            "Restricted to Administrators."
        );
        _;
    }

    // ========================================= Access-Control ===========================================================================

    /**
     * @notice Verify if parameter account is Owner/DEFAULT_ADMIN_ROLE
     * @param account address
     */
    function isOwner(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @notice Verify if parameter account is ADMIN
     * @param account address
     */
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN, account);
    }

    /**
     * @notice Verify if parameter account is SENDER
     * @param account address
     */
    function isSender(address account) public view virtual returns (bool) {
        return hasRole(SENDER, account);
    }

    /**
     * @notice Set role as SENDER
     * @param account address
     * @dev Only administrators allowed to add senders
     */
    function setSender(
        address account
    ) public virtual onlyAdministrators delegatedOnly {
        grantRole(SENDER, account);
    }

    /**
     * @notice Set role as ADMIN for the account
     * @param account address
     * @dev Only Owner allowed to add new Admins
     */
    function setAdmin(
        address account
    ) public onlyRole(DEFAULT_ADMIN_ROLE) delegatedOnly {
        grantRole(ADMIN, account);
    }

    /**
     * @notice Remove key from ADMIN access
     * @param account address
     * @dev Only Owner allowed to add new Admins
     */
    function revokeAdmin(
        address account
    ) public onlyRole(DEFAULT_ADMIN_ROLE) delegatedOnly {
        revokeRole(ADMIN, account);
    }

    /**
     * @notice Remove key from SENDER access
     * @param account address
     * @dev Only Administrators allowed to revoke senders access
     */
    function revokeSender(
        address account
    ) public onlyAdministrators delegatedOnly {
        revokeRole(SENDER, account);
    }

    /**
     * @notice Transfer contract Ownership
     * @param account address
     * @dev Remove and transfer OWNER/DEFAULT_ADMIN_ROLE role to account
     */
    function transferOwnership(
        address account
    ) public onlyRole(DEFAULT_ADMIN_ROLE) delegatedOnly {
        grantRole(DEFAULT_ADMIN_ROLE, account);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    // ====================================================================================================================================
}