// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './CollectionPoolFactory.sol';

/**
 * @title Address Pool
 * @dev Store collections and make transfers
 */
contract CollectionPool {
  uint256 private _totalCollections;
  uint256 private _securityTimelock;
  uint256 private _lastTimelockUpdate;
  CollectionPoolFactory private _factory;

  struct Collection {
    string name;
    string symbol;
    address wallet;
    uint256 dateAdded;
  }

  // Array of Collection structs (collections in address pool)
  Collection[] private collections;

  // Mapping to retrieve Array index from address or name
  mapping(address => uint256) private addressToIndex;
  mapping(string => uint256) private nameToIndex;
  mapping(string => uint256) private symbolToIndex;
  address public owner;

  event collectionAdded(string _name, string _symbol, address _address);

  constructor(address _poolOwner) {
    owner = _poolOwner;
    _totalCollections = 0;
    _securityTimelock = 90; // in seconds
    _lastTimelockUpdate = block.timestamp;
    _factory = CollectionPoolFactory(msg.sender);
  }

  // MODIFIERS

  // Only the owner of the contract may call
  modifier onlyOwner() {
    require(msg.sender == owner, 'Only the contract owner may call this function');
    _;
  }

  // Only permitted after x time (z.B. new collections can't be paid for at least this amount of time)
  modifier timelockElapsed() {
    require(block.timestamp >= _lastTimelockUpdate + _securityTimelock, 'You must wait for the security timelock to elapse before this is permitted');
    _;
  }

  // CONTACT MANAGEMENT

  // add a user / Collection struct to the collections Array
  function addCollection(string calldata _name, string memory _symbol, address _address) public onlyOwner {
    Collection memory person = Collection(_name, _symbol, _address, block.timestamp);
    collections.push(person);
    addressToIndex[_address] = _totalCollections;
    nameToIndex[_name] = _totalCollections;
    symbolToIndex[_symbol] = _totalCollections;
    _totalCollections++;
    emit collectionAdded(_name, _symbol, _address);
  }

  // Get all contact data for this CollectionPool
  function readAllCollections() public view onlyOwner returns (Collection[] memory) {
    Collection[] memory result = new Collection[](_totalCollections);
    for (uint256 i = 0; i < _totalCollections; i++) {
      result[i] = collections[i];
    }
    return result;
  }

  function readTotalCollections() public view onlyOwner returns (uint256 totalCollections) {
    totalCollections = _totalCollections;
    return totalCollections;
  }

  function readSecurityTimelock() public view onlyOwner returns (uint256 securityTimelock) {
    securityTimelock = _securityTimelock;
    return securityTimelock;
  }

  function readLastTimelockUpdate() public view onlyOwner returns (uint256 lastTimelockUpdate) {
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

  // Leaving these two functions in in case of accidental transfer of money into contract
  function checkBalance() public view onlyOwner returns (uint256 amount) {
    amount = address(this).balance;
    return amount;
  }

  function withdraw() public onlyOwner {
    uint256 amount = checkBalance();
    (bool sent, ) = msg.sender.call{ value: amount }('');
    require(sent, 'There was a problem while withdrawing');
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './CollectionPool.sol';

contract CollectionPoolFactory {
  uint256 public accountOpenCost;
  uint256 public txCost;
  address public owner;

  mapping(address => CollectionPool) private collectionPools;

  event CollectionAdded(address contractAddress);

  constructor() {
    owner = msg.sender;
    accountOpenCost = 0.2 ether; // in ETH
    txCost = 0.001 ether; // in ETH
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'Only the contract owner may call this function');
    _;
  }

  // COLLECTION POOL MANAGEMENT

  // Return this user's COLLECTION POOL contract address
  function fetchCollectionPool() public view returns (CollectionPool userData) {
    userData = collectionPools[msg.sender];
    return userData;
  }

  // Create a new CollectionPool struct for this user
  function createCollectionPool() public payable returns (address contractAddress) {
    require(msg.value >= accountOpenCost, 'Not enough ETH');
    CollectionPool newPool = new CollectionPool(msg.sender);
    collectionPools[msg.sender] = newPool;
    contractAddress = address(newPool);
    emit CollectionAdded(contractAddress);

    return contractAddress;
  }

  // UPDATE VARIABLE FUNCTIONS

  // Update the price to open an account here
  function updateAccountOpenCost(uint256 _accountOpenCost) public onlyOwner {
    accountOpenCost = _accountOpenCost;
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

  function withdraw() public onlyOwner {
    (bool sent, ) = msg.sender.call{ value: checkBalance() }('');
    require(sent, 'There was a problem while withdrawing');
  }
}