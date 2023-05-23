// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;
import "./Proxiable.sol";
import "./AccessControl.sol";
import "./LibraryLock.sol";

/**
 * @title Rymedi logic contract for Data storage
 * @author Mayank Saxena (@forkblocks)
 * @notice Use this contract to wite data to Proxy contract
 */
contract Rymedi is Proxiable, AccessControl, LibraryLock {
    /// @dev variables
    string public name;
    uint public totalKeyCount;
    uint public deletedKeyCount;
    mapping(bytes32 => string) records;
    mapping(bytes32 => string) deletedRecords;
    string[] roles;

    /// @dev Owner - DEFAULT_ADMIN_ROLE + user roles
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant SENDER = keccak256("SENDER");

    /// @dev events
    event AddRecord(bytes32 indexed key, string value);
    event RemoveRecord(bytes32 indexed key, string value);

    // ========================================= Manage Rymedi Data =======================================================================

    /**
     * Constructor function called from Proxy contract
     * @param _name  string - contract name or description
     */
    function rymediInitialize(string memory _name) public {
        require(!initialized, "Already initalized");
        initialize();
        name = _name;
        roles.push("DEFAULT_ADMIN_ROLE");
        roles.push("ADMIN");
        roles.push("SENDER");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(SENDER, ADMIN);
    }

    /**
     * @notice Push single record - Only SENDER
     * @param _key bytes32 - sha256 hash
     * @param _value string - stringified object
     */
    function addRecord(
        bytes32 _key,
        string memory _value
    ) public onlyRole(SENDER) delegatedOnly {
        _addRecord(_key, _value);
    }

    /**
     * @notice Push multiple records in  single transaction - Only SENDER
     * @param _keys bytes32 - sha256 hash
     * @param _values string - stringified object
     */
    function addBulkRecords(
        bytes32[] memory _keys,
        string[] memory _values
    ) public onlyRole(SENDER) delegatedOnly {
        require(
            _keys.length == _values.length,
            "Lengths of keys and values arrays do not match"
        );
        for (uint i = 0; i < _keys.length; i++) {
            _addRecord(_keys[i], _values[i]);
        }
    }

    /**
     * @notice Push single record - Only SENDER
     * @param _key bytes32 - sha256 hash
     * @param _value string - stringified object
     */
    function _addRecord(
        bytes32 _key,
        string memory _value
    ) internal onlyRole(SENDER) delegatedOnly returns (bool) {
        require(getLength(records[_key]) == 0, "Record's Key already exist");
        require(getLength(_value) != 0, "Empty value rejected");
        records[_key] = _value;
        totalKeyCount++;
        emit AddRecord(_key, _value);
        return true;
    }

    /**
     * @notice Delete records against keys
     * @param _key bytes32 - sha256 hash
     * @dev Delete keys are stored and emitted via events
     */
    function removeRecord(
        bytes32 _key
    ) public onlyAdministrators delegatedOnly returns (bool) {
        require(
            getLength(records[_key]) != 0,
            "Remove Record failed - No record found against this key"
        );
        string memory value = records[_key];
        records[_key] = "";
        deletedKeyCount++;
        emit RemoveRecord(_key, value);
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

    // =========================================  Pure functions ==========================================================================

    /**
     * @notice Fetch length of String
     * @param _value string
     */
    function getLength(string memory _value) internal pure returns (uint) {
        return bytes(_value).length;
    }

    // =========================================  Getter functions ========================================================================

    /**
     * @notice Fetch value against key from Records
     * @param _key bytes32 - sha256 hash
     */
    function getRecord(bytes32 _key) public view returns (string memory) {
        return records[_key];
    }

    /**
     * @notice Fetch record count stats
     * @return totalKeyCount Total count of pushed records
     * @return deletedKeyCount Number of deleted keys
     * @return activeRecordsCount Number of Keys with Value
     */
    function recordCount() public view returns (uint, uint, uint) {
        return (
            totalKeyCount,
            deletedKeyCount,
            totalKeyCount - deletedKeyCount
        );
    }

    /**
     * @notice List all role types
     */
    function rolesList() public view returns (string[] memory) {
        return roles;
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
     * @notice Verify if parameter account is ADMIN
     * @param _account address
     */
    function isAdmin(address _account) public view virtual returns (bool) {
        return hasRole(ADMIN, _account);
    }

    /**
     * @notice Verify if parameter account is Owner/DEFAULT_ADMIN_ROLE
     * @param _account address
     */
    function isOwner(address _account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /**
     * @notice Set role as ADMIN for the account
     * @param _account address
     * @dev Only Owner allowed to add new Admins
     */
    function setAdmin(
        address _account
    ) public onlyRole(DEFAULT_ADMIN_ROLE) delegatedOnly {
        grantRole(ADMIN, _account);
    }

    /**
     * @notice Transfer contract Ownership
     * @param _account address
     * @dev Remove and transfer OWNER/DEFAULT_ADMIN_ROLE role to account
     */
    function transferOwnership(
        address _account
    ) public onlyRole(DEFAULT_ADMIN_ROLE) delegatedOnly {
        grantRole(DEFAULT_ADMIN_ROLE, _account);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Verify if parameter account is SENDER
     * @param _account address
     */
    function isSender(address _account) public view virtual returns (bool) {
        return hasRole(SENDER, _account);
    }

    /**
     * @notice Set role as SENDER
     * @param _account address
     * @dev Only administrators allowed to add senders
     */
    function setSender(
        address _account
    ) public virtual onlyAdministrators delegatedOnly {
        grantRole(SENDER, _account);
    }

    /**
     * @notice Remove key from ADMIN access
     * @param _account address
     * @dev Only Owner allowed to add new Admins
     */
    function revokeAdmin(
        address _account
    ) public onlyRole(DEFAULT_ADMIN_ROLE) delegatedOnly {
        revokeRole(ADMIN, _account);
    }

    /**
     * @notice Remove key from SENDER access
     * @param _account address
     * @dev Only Administrators allowed to revoke senders access
     */
    function revokeSender(
        address _account
    ) public onlyRole(ADMIN) delegatedOnly {
        revokeRole(SENDER, _account);
    }

    // ====================================================================================================================================
}