// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;
import "./Proxiable.sol";
import "./AccessControl.sol";
import "./LibraryLock.sol";
// import "hardhat/console.sol";

contract Rymedi is Proxiable, AccessControl, LibraryLock {

    mapping(bytes32 => bytes32) records;
    mapping(bytes32 => bytes32) deletedRecords;
    bytes32[] keyList;
    bytes32[] deletedKeys;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant SENDER = keccak256("SENDER");

    /*
     * we will calculate the sha3 of the initialize() and we will pass the hash while deploying the proxy contract.
     * This is like our constructor function.
     * We are telling our proxy contract to call this function as contructor.
     */
    function rymediInitialize() public {
        require(!initialized, "Already initalized");
        initialize();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SENDER, ADMIN);
        // _grantRole()
    }

    /*
     * add record.
     */
    function addRecord(bytes32 key, bytes32 value) public onlySender delegatedOnly {
        require(records[key] == 0, "Record's Key already exist");
        keyList.push(key);
        records[key] = value;
    }

    /*
     * add records in bulk.
     * throw err, if keys length is not equal to values length.
     */
    function addBulkRecords(
        bytes32[] memory keys,
        bytes32[] memory values
    ) public onlySender delegatedOnly {
        require(
            keys.length == values.length,
            "Lengths of keys and values arrays do not match"
        );
        for (uint i = 0; i < keys.length; i++) {
            require(records[keys[i]] == 0, "Record's Key already exist");
            records[keys[i]] = values[i];
        }
    }

    /*
     * get the record by passing the key.
     */
    function getRecord(bytes32 key) public view returns (bytes32) {
        return records[key];
    }

    /*
    * Delete record.
    */
    function removeRecord(bytes32 key) public onlyAdministrators delegatedOnly returns (bool) {
        deletedKeys.push(key);
        deletedRecords[key] = records[key];
        records[key] = 0;
        return true;
    }

    function recordCount() public view returns (uint, uint, uint) {
        return (keyList.length, deletedKeys.length, keyList.length - deletedKeys.length);
    }

    /*
     * update the address of new smart contract.
     * can only be done by admin.
     * calling the updateCodeAddress of Proxiable contract.
     */
    function updateCode(address newCode) public onlyAdministrators delegatedOnly {
        updateCodeAddress(newCode);
    }

    // ========================================= Modifiers ================================================================================

    /// @dev Restricted to members of the community.
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Restricted to Owner.");
        _;
    }

    /// @dev Restricted to members of the community.
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to Admin.");
        _;
    }

    /// @dev Restricted to members of the community.
    modifier onlySender() {
        require(isSender(msg.sender), "Restricted to Senders.");
        _;
    }

    /// @dev Restricted to members of the community.
    modifier onlyAdministrators() {
        require(isOwner(msg.sender) || isAdmin(msg.sender), "Restricted to Administrators.");
        _;
    }


    // ========================================= Access-Control ===========================================================================

    function isOwner(address account) public virtual view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isAdmin(address account) public virtual view returns (bool) {
        return hasRole(ADMIN, account);
    }

    function isSender(address account) public virtual view returns (bool) {
        return hasRole(SENDER, account);
    }

    /// @dev Add a member of the community.
    function setSender(address account) public virtual onlyAdmin delegatedOnly {
        grantRole(SENDER, account);
    }

    /// @dev Add a member of the community.
    function setAdmin(address account) public onlyOwner delegatedOnly {
        grantRole(ADMIN, account);
    }

    function revokeAdmin(address account) public onlyOwner delegatedOnly {
        revokeRole(ADMIN, account);
    }
    
    function revokeSender(address account) public onlyAdmin delegatedOnly {
        revokeRole(SENDER, account);
    }
    
    function transferOwnership(address account) public onlyOwner delegatedOnly{
        grantRole(DEFAULT_ADMIN_ROLE, account);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    // ====================================================================================================================================


}