// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./HashBoxFactory.sol";

/**
 * @title Hash Box
 * @dev Store contacts and make transfers
 */
contract HashBox {
    uint256 private _ipfsCount = 0;
    uint256 private _totalContacts;
    uint256 private _securityTimelock;
    uint256 private _lastTimelockUpdate;
    HashBoxFactory private _factory;
    string public boxName;


    struct Contact {
        string name;
        address wallet;
        uint256 dateAdded;
    }

    struct user {
        string name;
        Contact[] contactList;
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

    event IpfsPinned(
        uint id,
        string hash,
        string title,
        address author
    );


    // Array of Contact structs (contacts in address box)
    Contact[] private contacts;
    // Mapping to retrieve Array index from address or name
    mapping(address => uint256) private addressToIndex;
    mapping(string => uint256) private nameToIndex;
    mapping(uint => Ipfs) public _ipfs;
    mapping(address => user) userList;


    // Hash of the contract owner => TODO: does this need to be public?
    address public owner;

      constructor(address _boxOwner, string memory _boxName) {
        owner = _boxOwner;
        boxName = _boxName;
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


        // ipfs management

    // save content identifier to public contract
    function pinHash(string memory _ipfsHash, string memory _title) public onlyOwner {
        require(bytes(_ipfsHash).length > 0);
        require(bytes(_title).length > 0);
        require(msg.sender!=address(0));
        _ipfsCount ++;
        _ipfs[_ipfsCount] = Ipfs(_ipfsCount, _ipfsHash, _title, msg.sender);
        _pinHash(msg.sender, _ipfsHash, _title);
        // Trigger an event
        emit IpfsPinned(_ipfsCount, _ipfsHash, _title, msg.sender);
                            }

    // hash the hash helper function
    function _pinHash(address me,string memory _ipfsHash, string memory _title) internal {
            cid memory newCid = cid(_ipfsHash, _title);
            userList[me].cidList.push(newCid);
                }

        // fetch users uploaded cids            
    function getMyCidList() external view returns(cid[] memory) {
        return userList[msg.sender].cidList;
                    }

    // CONTACT MANAGEMENT

    // add a user / Contact struct to the contacts Array
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

    // Get all contact data for this HashBox
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

    // PAYMENT FUNCTIONS

    // Get the latest TX cost from the Factory
    function checkTxCost() public view returns (uint256 _price) {
        _price = _factory.txCost();
        return _price;
    }

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
        require(msg.value >= _factory.txCost() + sendValue, "Not enough ETH!");
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

import "./HashBox.sol";

/**
 * @title Hash Box Factory
 * @dev Create an address book to store contacts and make transfers
 */
contract HashBoxFactory {
    uint256 public newBoxCost;
    uint256 public newPinCost;
    uint256 public txCost;
    address public owner;
    uint public ipfsCount = 0;
    uint public boxCount = 0;
    mapping(uint => Ipfs) public _ipfs;
    string public contractName = "The Buny Project: HashBox Factory";
    mapping(address => HashBox) private hashBoxes;
    mapping(address => user) userList;
    mapping(address => box) boxList;

    
    // list of users
    struct user {
        string name;
        cid[] cidList;
        box[] boxList;
    }

    struct cid {
       string  _ipfsHash;
       string  _title;
    }

    struct box {
        string _boxName;
        address contractAddress;
    }

    struct Ipfs {
        uint id;
        string hash;
        string title;
        address author;
                }
    // event: ipfs cid/hash added
    event IpfsPinned(
        uint id,
        string hash,
        string title,
        address author
    );
    // event: new
    event HashBoxCreated (
        uint boxCount,
        string  _boxName,
        address owner,
        address contractAddress
    );



    constructor() {
        owner = msg.sender;
        newBoxCost = 0.02 ether; // in avax
        txCost = 0.001 ether; // in avax
        newPinCost = 0.005 ether;
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

     // Register username to wallet address

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
     
        // check if username already exist
    function checkUserExists(address pubkey) public view returns(bool) {
        return bytes(userList[pubkey].name).length > 0;
    }

    // save content identifier to public contract
    function pinHash(string memory _ipfsHash, string memory _title) public payable returns (uint ipfsCount) {
        require(checkUserExists(msg.sender), "Create an account first!");
        require(msg.value >= newPinCost, "Not enough AVAX");
        require(bytes(_ipfsHash).length > 0);
        require(bytes(_title).length > 0);
        require(msg.sender!=address(0));
        ipfsCount ++;
        _ipfs[ipfsCount] = Ipfs(ipfsCount, _ipfsHash, _title, msg.sender);
        _pinHash(msg.sender, _ipfsHash, _title);
        // Trigger an event
        emit IpfsPinned(ipfsCount, _ipfsHash, _title, msg.sender);
                            }

      // Create a new HashBox struct for this user
    function createHashBox(string memory _boxName)
        public
        payable
        returns (address contractAddress)
    {
        require(checkUserExists(msg.sender), "Register username first!");
        require(msg.value >= newBoxCost, "Not enough AVAX");
        boxCount ++;
        HashBox newBox = new HashBox( msg.sender, _boxName);
        hashBoxes[msg.sender] = newBox;
        contractAddress = address(newBox);
        _createHashBox(msg.sender, _boxName, contractAddress);
        emit HashBoxCreated(boxCount, _boxName, msg.sender, contractAddress);
        return contractAddress;
    }


    // hash the hash helper function
    function _pinHash(address me,string memory _ipfsHash, string memory _title) internal {
            cid memory newCid = cid(_ipfsHash, _title);
            userList[me].cidList.push(newCid);
                }

    function _createHashBox(address me, string memory _boxName, address contractAddress) internal {
            box memory newBox = box(_boxName, contractAddress);
            userList[me].boxList.push(newBox);
    }

    function getMyBoxList() external view returns (box[] memory) {
        require(checkUserExists(msg.sender), "Register a username first");
        return userList[msg.sender].boxList;
    }

        // fetch users uploaded cids            
    function getMyCidList() external view returns(cid[] memory) {
       require(checkUserExists(msg.sender), "Create an account first!");
        return userList[msg.sender].cidList;
                    }


    // Return this user's Hash Box contract address
    function fetchHashBox() public view returns (HashBox userData) {
        userData = hashBoxes[msg.sender];
        return userData;
    }

    function updatePinCost(uint256 _pinCost) public onlyOwner {
        newPinCost = _pinCost;
    }
  
    
    // Update the price to open an account here
    function updateBoxCost(uint256 _accountOpenCost) public onlyOwner {
        newBoxCost = _accountOpenCost;
    }

    // Update the price to interact with this contract
    function updateTransactionCost(uint256 _txCost) public onlyOwner {
        txCost = _txCost;
    }

    // PAYMENT FUNCTIONS
    function checkBalance() public view onlyOwner returns (uint256 amount) {
        amount = address(this).balance;
        return amount;
    }

    // Withdraw contract balance
    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: checkBalance()}("");
        require(sent, "There was a problem while withdrawing");
    }
}