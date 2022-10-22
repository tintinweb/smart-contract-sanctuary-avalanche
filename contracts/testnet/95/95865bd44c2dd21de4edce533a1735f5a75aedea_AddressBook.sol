/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-21
*/

/*
 * SPDX-License-Identitifer: GPL-3.0-or-later
 */

pragma solidity 0.4.24;


/**
 * @title AddressBook App
 * @author Autark
 * @dev Defines an address book (registry) that allows the
 * association of an ethereum address with an IPFS CID pointing to JSON content
 */
 
contract AddressBook {
    address public owner;
    uint public x = 10;
    bool public locked;

    constructor() {
        // Set the transaction sender as the owner of the contract.
        owner = msg.sender;
    }

    // Modifier to check that the caller is the owner of
    // the contract.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    // Modifiers can take inputs. This modifier checks that the
    // address passed in is not the zero address.
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }
    /// Hardcoded constants to save gas
    /// bytes32 public constant ADD_ENTRY_ROLE = keccak256("ADD_ENTRY_ROLE");
    bytes32 public constant ADD_ENTRY_ROLE = 0x3078653262433430396664633444306341363163633736373044383736344533;
    /// bytes32 public constant REMOVE_ENTRY_ROLE = keccak256("REMOVE_ENTRY_ROLE");
    bytes32 public constant REMOVE_ENTRY_ROLE = 0x4bf67e2ff5501162fc2ee020c851b17118c126a125e7f189b1c10056a35a8ed1;
    /// bytes32 public constant UPDATE_ENTRY_ROLE = keccak256("UPDATE_ENTRY_ROLE");
    bytes32 public constant UPDATE_ENTRY_ROLE = 0x6838798f8ade371d93fbc95e535888e5fdc0abba71f87ab7320dd9c8220b4da0;

    /// Error string constants
    string private constant ERROR_NOT_FOUND = "ENTRY_DOES_NOT_EXIST";
    string private constant ERROR_EXISTS = "ENTRY_ALREADY_EXISTS";
    string private constant ERROR_CID_MALFORMED = "CID_MALFORMED";
    string private constant ERROR_CID_LENGTH = "CID_LENGTH_INCORRECT";
    string private constant ERROR_NO_CID = "CID_DOES_NOT_MATCH";

    struct Entry {
        string data;
        uint256 index;
    }

    /// The entries in the registry
    mapping(address => Entry) public entries;

    /// Array-like struct to access all addresses
    mapping(uint256 => address) public entryArr;
    uint256 public entryArrLength;

    /// Events
    event EntryAdded(address addr); /// Fired when an entry is added to the registry
    event EntryRemoved(address addr); /// Fired when an entry is removed from the registry
    event EntryUpdated(address addr); /// Fired when an entry is updated with a new CID.

    /**
     * @dev Guard to check existence of address in the registry
     * @param _addr The address to enforce its existence in the registry
     */
    modifier entryExists(address _addr) {
        require(isEntryAdded(_addr), ERROR_NOT_FOUND);
        _;
    }



    /**
     * @dev Guard to ensure the CID is 46 chars long according to base58 encoding
     * @param _cid The IPFS hash of the entry to add to the registry
     */
    modifier cidIsValid(string _cid) {
        bytes memory cidBytes = bytes(_cid);
        require(cidBytes[0] == "Q" && cidBytes[1] == "m", ERROR_CID_MALFORMED);
        require(cidBytes.length == 46, ERROR_CID_LENGTH);
        _;
    }

    /**
     * @notice Initialize AddressBook app
     * @dev Initializes the app, this is the Daoxy custom constructor
    //  */
    // function initialize() external onlyInit {
    //     initialized();
    // } // Bu fonksiyona bak

    /**
     * @notice Add `_addr` to the registry with metadata `_cid`
     * @dev CIDs must be base58-encoded in order to work with this function
     * @param _addr The Ethereum address of the entry to add to the registry
     * @param _cid The IPFS hash of the entry to add to the registry
     */
    function addEntry(address _addr, string _cid) external cidIsValid(_cid)  onlyOwner{
        require(bytes(entries[_addr].data).length == 0, ERROR_EXISTS);
        // This is auth-guarded, so it'll overflow well after the app becomes unusable
        // due to the quantity of entries
        uint256 entryIndex = entryArrLength++;
        entryArr[entryIndex] = _addr;
        entries[_addr] = Entry(_cid, entryIndex);
        emit EntryAdded(_addr);
    }


    /**
     * @notice Remove `_addr` from the registry with metadata `_cid`
     * @dev this function only supports CIDs that are base58-encoded
     * @param _addr The Ethereum address of the entry to remove from the registry
     * @param _cid The IPFS hash of the entry to remove from the registry; used only for radspec here
     */
     // Remove Entry Role'ü kaldırdım.
    function removeEntry(address _addr, string _cid) external entryExists(_addr) onlyOwner {
        require(keccak256(bytes(_cid)) == keccak256(bytes(entries[_addr].data)), ERROR_NO_CID);
        uint256 rowToDelete = entries[_addr].index;
        if (entryArrLength != 1) {
            address entryToMove = entryArr[entryArrLength - 1];
            entryArr[rowToDelete] = entryToMove;
            entries[entryToMove].index = rowToDelete;
        }
        delete entries[_addr];
        // Doesn't require underflow checking because entry existence is verified
        entryArrLength--;
        emit EntryRemoved(_addr);
    }

    /**
     * @notice Update `_addr` from current metadata `_oldCid` to new metadata `_newCid`
     * @dev this function only supports CIDs that are base58-encoded
     * @param _addr The Ethereum address of the entry to update
     * @param _oldCid The current IPFS hash containing the metadata of the entry
     * @param _newCid The new IPFS hash containing the metadata of the entry
     */
    function updateEntry(
        address _addr,
        string _oldCid,
        string _newCid
    ) external onlyOwner entryExists(_addr) cidIsValid(_newCid)
    {
        require(keccak256(bytes(_oldCid)) == keccak256(bytes(entries[_addr].data)), ERROR_NO_CID);
        entries[_addr].data = _newCid;
        emit EntryUpdated(_addr);
    }

    /**
     * @notice Get data associated to entry `_addr` from the registry.
     * @dev getter for the entries mapping to IPFS data
     * @param _addr The Ethereum address of the entry to get
     * @return contentId pointing to the IPFS structured content object for the entry
     */
    function getEntry(address _addr) external view returns (string contentId) {
        contentId = entries[_addr].data;
    }

    /**
     * @notice Get index associated to entry `_addr` from the registry.
     * @dev getter for the entries mapping for an index in entryArr
     * @param _addr The Ethereum address of the entry to get
     * @return contentId pointing to the IPFS structured content object for the entry
     */
    function getEntryIndex(address _addr) external view entryExists(_addr) returns (uint256 index) {
        index = entries[_addr].index;
    }

    /**
     * @notice Checks if `_entry` exists in the registry
     * @param _entry the Ethereum address to check
     * @return _repoId Id for entry in entryArr
     */
    function isEntryAdded(address _entry) public view returns (bool isAdded) {
        if (entryArrLength == 0) {
            return false;
        }

        if (entries[_entry].index >= entryArrLength) {
            return false;
        }

        return (entryArr[entries[_entry].index] == _entry);
    }
}