// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./HashBoxFactory.sol";

/**
 * @title Hash Box Beta
 * @dev Store contacts and make transfers
 */
contract HashBoxBeta {
    uint256 private _ipfsCount;
    uint256 private _totalContacts;
    uint256 private _securityTimelock;
    uint256 private _lastTimelockUpdate;
    HashBoxFactory private _factory;
    uint public ipfsCount = 0;
    string public boxName = "Hash Box 01";
    
    struct Contact {
        string name;
        address wallet;
        uint256 dateAdded;
    }

     struct box {
        string BoxName;
        cid[] cidList;
    }


    struct cid {
       string  _ipfsHash;
       string  _title;
    }
    
    
    struct Ipfs {
        uint id;
        string hash;
        string title;
        address author;
                }

    event IpfsUploaded(
    uint id,
    string hash,
    string title,
    address author
                     );


    // Array of Contact structs (contacts in address book)
    Contact[] private contacts;

    // Mapping to retrieve Array index from address or name
    mapping(address => uint256) private addressToIndex;
    mapping(string => uint256) private nameToIndex;
    mapping(uint => Ipfs) public _ipfs;
    mapping(address => box) boxList;


    // Address of the contract owner => TODO: does this need to be public?
    address public owner;

    constructor(address _boxOwner) {
        owner = _boxOwner;
        _ipfsCount = 0;
        _totalContacts = 0;
        _securityTimelock = 90; // in seconds
        _lastTimelockUpdate = block.timestamp;
        _factory = HashBoxFactory(msg.sender);
    }

    // MODIFIERS

    // Only the owner of the contract may call
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner may call this function"
        );
        _;
    }



    // Only permitted after x time (z.B. new contacts can't be paid for at least this amount of time)
    modifier timelockElapsed() {
        require(
            block.timestamp >= _lastTimelockUpdate + _securityTimelock,
            "You must wait for the security timelock to elapse before this is permitted"
        );
        _;
    }

    // Hash Box Functions
    
     function uploadIpfs(string memory _ipfsHash, string memory _title) public {
     require(bytes(_ipfsHash).length > 0);
     require(bytes(_title).length > 0);
        require(msg.sender!=address(0));
        ipfsCount ++;
        _ipfs[ipfsCount] = Ipfs(ipfsCount, _ipfsHash, _title, msg.sender);
        _uploadIpfs(msg.sender, _ipfsHash, _title);
    // Trigger =upload event
        emit IpfsUploaded(ipfsCount, _ipfsHash, _title, msg.sender);
                  }


        // upload helper function
        

    function _uploadIpfs(address me,string memory _ipfsHash, string memory _title) internal {
        cid memory newCid = cid(_ipfsHash, _title);
        boxList[me].cidList.push(newCid);
                                                                                                }


        // fetch cid list array
    function getMyCidList() external view returns(cid[] memory) {
        return boxList[msg.sender].cidList;
                                                                    }




    // CONTACT MANAGEMENT

     function addContact(string calldata _name, address _address)
        public
        onlyOwner
    {
        Contact memory person = Contact(_name, _address, block.timestamp);
        contacts.push(person);
        addressToIndex[_address] = _totalContacts;
        nameToIndex[_name] = _totalContacts;
        _totalContacts++;
    }

   // find and remove a contact via their name
    function removeContactByName(string calldata name) public onlyOwner {
        uint256 removeIndex = nameToIndex[name];
        require(removeIndex < _totalContacts, "Index is out of range");
        contacts[removeIndex] = contacts[contacts.length - 1];
        nameToIndex[contacts[contacts.length - 1].name] = removeIndex;
        delete nameToIndex[name];
        contacts.pop();
        _totalContacts--;
    }

     // Get all contact data for this AddressBook
    function readAllContacts()
        public
        view
        onlyOwner
        returns (Contact[] memory)
    {
        Contact[] memory result = new Contact[](_totalContacts);
        for (uint256 i = 0; i < _totalContacts; i++) {
            result[i] = contacts[i];
        }
        return result;
    }

    function readTotalContacts()
        public
        view
        onlyOwner
        returns (uint256 totalContacts)
    {
        totalContacts = _totalContacts;
        return totalContacts;
    }

 

    function readSecurityTimelock()
        public
        view
        onlyOwner
        returns (uint256 securityTimelock)
    {
        securityTimelock = _securityTimelock;
        return securityTimelock;
    }

    function readLastTimelockUpdate()
        public
        view
        onlyOwner
        returns (uint256 lastTimelockUpdate)
    {
        lastTimelockUpdate = _lastTimelockUpdate;
        return lastTimelockUpdate;
    }

    // UPDATE VARIABLE FUNCTIONS

    // Update this user's personal timelock
    function updateTimelock(uint256 duration) public onlyOwner timelockElapsed {
        _securityTimelock = duration;
        _lastTimelockUpdate = block.timestamp;
    }

   
    // Transfer ETH to a contact
    // Transfer ETH to a contact
    function payContactByName(string calldata name, uint256 sendValue)
        public
        payable
        onlyOwner
    {
        Contact memory recipient = contacts[nameToIndex[name]];
        require(
            block.timestamp >= recipient.dateAdded + _securityTimelock,
            "This contact was added too recently"
        );
        (bool sent, ) = recipient.wallet.call{value: sendValue}("");
        require(sent, "Failed to send Ether");
    }

    // Leaving these two functions in in case of accidental transfer of money into contract
    function checkBalance() public view onlyOwner returns (uint256 amount) {
        amount = address(this).balance;
        return amount;
    }

    function withdraw() public onlyOwner {
        uint256 amount = checkBalance();
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "There was a problem while withdrawing");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./HashBoxBeta.sol";

/**
 * @title Address Book Factory
 * @dev Create an address book to store contacts and make transfers
 */
contract HashBoxFactory {



    string public contractName = "Hash Box Factory";

    struct user {
        string name;
        string userData;
        address contractAddress;
    }   

    
 
    address public owner;
    mapping(address => HashBoxBeta) private cidBox;
    mapping(address => user) userList;

    constructor() {
        owner = msg.sender;
      
    }

    // MODIFIERS

    // Only the owner of the contract may call
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner may call this function"
        );
        _;
    }

    // ADDRESS BOOK MANAGEMENT

    // Return this user's Address Book contract address
    function fetchHashBox() public view returns (HashBoxBeta userData) {
        userData = cidBox[msg.sender];
        return userData;
    }

    // Create a new HashBoxBeta struct for this user
    function createHashBox()
        public
        payable
        returns (address contractAddress)
    {
        require(checkUserExists(msg.sender), "Register username first!");
        HashBoxBeta newBox = new HashBoxBeta(msg.sender);
        cidBox[msg.sender] = newBox;
        contractAddress = address(newBox);
        return contractAddress;
    }

    ///

    function checkUserExists(address pubkey) public view returns(bool) {
        return bytes(userList[pubkey].name).length > 0;
    }

    // Registers the caller(msg.sender) to our app with a non-empty username
    function createAccount(string calldata name) external {
        require(checkUserExists(msg.sender)==false, "User already exists!");
        require(bytes(name).length>0, "Username cannot be empty!"); 
        userList[msg.sender].name = name;
    }

    // Returns the default name provided by an user
    function getUsername(address pubkey) external view returns(string memory) {
        require(checkUserExists(pubkey), "User is not registered!");
        return userList[pubkey].name;
    }

     

    // UPDATE VARIABLE FUNCTIONS

    // Update the price to open an account here
  
    // PAYMENT FUNCTIONS

    function checkBalance() public view onlyOwner returns (uint256 amount) {
        amount = address(this).balance;
        return amount;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: checkBalance()}("");
        require(sent, "There was a problem while withdrawing");
    }



}