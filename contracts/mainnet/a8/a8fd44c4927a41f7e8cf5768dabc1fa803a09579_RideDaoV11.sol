// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ride.sol";
import "./USDC.sol";

// RideDao V1.1
contract RideDaoV11 {
  uint public totalNodes;
  address [] public rideNodesAddresses;

  Ride public rideAddress;
  USDC public usdcAddress;
  address private owner;
  uint public rideInterestRatePercent;

  struct Account {
    bool exists;
    uint nanoCount;
    uint miniCount;
    uint kiloCount;
    uint megaCount;
    uint gigaCount;
    uint interestAccumulated;
  }

  mapping(address => Account) public accounts;

  // 0.5%, 0.6%, 0.7%, 0.8%, 1% /day
  uint [] public nodeMultiplers = [1, 10, 70, 160, 1000];

  constructor(Ride _rideAddress, USDC _usdcAddress) {
    owner = msg.sender;
    rideAddress = _rideAddress;
    usdcAddress = _usdcAddress;
    rideInterestRatePercent = 1 * 10;
  }

  function setupAccountForMigration(address _address, uint _nanoCount, uint _miniCount, uint _kiloCount, uint _megaCount, uint _gigaCount, uint _interestAccumulated) public {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'Only owner can create a node.');

    if(!accounts[_address].exists){
      Account memory account = Account(true, _nanoCount, _miniCount, _kiloCount, _megaCount, _gigaCount, _interestAccumulated);
      rideNodesAddresses.push(_address);
      totalNodes += _nanoCount + _miniCount + _kiloCount + _megaCount + _gigaCount;
      accounts[_address] = account;
    }
  }

  function setNewNodeMultiplers(uint _nodeType, uint _nodeMultiplier) public {
    require(msg.sender == owner, 'Only owner can change node multipliers.');
    nodeMultiplers[_nodeType] = _nodeMultiplier;
  }

  // totalNodes getter
  function getTotalNodes() public view returns(uint) {
    return totalNodes;
  }

  // rideNodesAddresses getters
  function getAccountsLength() public view returns(uint) {
    return rideNodesAddresses.length;
  }

  function getAccountsAddressForIndex(uint _index) public view returns(address) {
    return rideNodesAddresses[_index];
  }

  // accounts getter
  function getAccount(address _address) public view returns(uint, uint, uint, uint, uint, uint) {
    Account memory acc = accounts[_address];
    return(acc.nanoCount, acc.miniCount, acc.kiloCount, acc.megaCount, acc.gigaCount, acc.interestAccumulated);
  }

  function mintNode(address _address, uint _rideAmount, uint _usdcAmount, uint _nodeType) public {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == _address, 'Only user can create a node.');
    require(_nodeType >= 0 && _nodeType <= 4, 'Invalid node type');

    Account memory account;

    if(accounts[_address].exists){
      account = accounts[_address];
    }
    else{
      account = Account(true, 0, 0, 0, 0, 0, 0);
      rideNodesAddresses.push(_address);
    }

    if(_nodeType == 0){
      require(_rideAmount >= 25 * 10 ** 18, 'You must provide at least 25 RIDES for the LP token');
      require(_usdcAmount >= 25 * 10 ** 6, 'You must provide at least 25 USDC for the LP token');
      account.nanoCount++;
    }
    else if(_nodeType == 1){
      require(_rideAmount >= 100 * 10 ** 18, 'You must provide at least 100 RIDES for the LP token');
      require(_usdcAmount >= 100 * 10 ** 6, 'You must provide at least 100 USDC for the LP token');
      account.miniCount++;
    }
    else if(_nodeType == 2){
      require(_rideAmount >= 500 * 10 ** 18, 'You must provide at least 500 RIDES for the LP token');
      require(_usdcAmount >= 500 * 10 ** 6, 'You must provide at least 500 USDC for the LP token');
      account.kiloCount++;
    }
    else if(_nodeType == 3){
      require(_rideAmount >= 1000 * 10 ** 18, 'You must provide at least 1000 RIDES for the LP token');
      require(_usdcAmount >= 1000 * 10 ** 6, 'You must provide at least 1000 USDC for the LP token');
      account.megaCount++;
    }
    else if(_nodeType == 4){
      require(_rideAmount >= 5000 * 10 ** 18, 'You must provide at least 5000 RIDES for the LP token');
      require(_usdcAmount >= 5000 * 10 ** 6, 'You must provide at least 5000 USDC for the LP token');
      account.gigaCount++;
    }
    totalNodes++;
    accounts[_address] = account;

    rideAddress.transferFrom(_address, address(this), _rideAmount);
    usdcAddress.transferFrom(_address, address(this), _usdcAmount);
  }

  function withdrawInterest(address _to) public {
    require(_to != address(0), "_to is address 0");
    require(msg.sender == _to, 'Only user can widthraw its own funds.');
    require(accounts[_to].interestAccumulated > 0, 'Interest accumulated must be greater than zero.');

    uint amount = accounts[_to].interestAccumulated;
    accounts[_to].interestAccumulated = 0;

    rideAddress.transfer(_to, amount);
  }

  // _indexTo not included
  function payInterest(uint _indexFrom, uint _indexTo) public {
    require(msg.sender == owner, 'You must be the owner to run this.');

    uint i;

    if(_indexTo == 1){
        _indexTo = getAccountsLength();
    }

    for(i = _indexFrom; i < _indexTo; i++){
      address a = rideNodesAddresses[i];
      Account memory acc = accounts[a];
      uint interestAccumulated;

      // add rideInterestRatePercent/100 RIDES per node that address has
      interestAccumulated = (acc.nanoCount * nodeMultiplers[0] * rideInterestRatePercent * 10 ** 18) / 100;
      interestAccumulated += (acc.miniCount * nodeMultiplers[1] * rideInterestRatePercent * 10 ** 18) / 100;
      interestAccumulated += (acc.kiloCount * nodeMultiplers[2] * rideInterestRatePercent * 10 ** 18) / 100;
      interestAccumulated += (acc.megaCount * nodeMultiplers[3] * rideInterestRatePercent * 10 ** 18) / 100;
      interestAccumulated += (acc.gigaCount * nodeMultiplers[4] * rideInterestRatePercent * 10 ** 18) / 100;

      acc.interestAccumulated += interestAccumulated;

      accounts[a] = acc;
    }
  }

  // runs daily at 2AM
  function balancePool() public {
    require(msg.sender == owner, 'You must be the owner to run this.');

    uint poolAmount = rideAddress.balanceOf(address(this)) / 10 ** 18;
    uint runwayInDays = poolAmount/((totalNodes * rideInterestRatePercent * nodeMultiplers[4]) / 100);
    if(runwayInDays > 900){
      uint newTotalTokens = (365 * rideInterestRatePercent * totalNodes * nodeMultiplers[4]) / 100; // 365 is the desired runway
      uint amountToBurn = poolAmount - newTotalTokens;
      rideAddress.burn(amountToBurn * 10 ** 18);
    }
    else if(runwayInDays < 360){
      uint newTotalTokens = (365 * rideInterestRatePercent * totalNodes * nodeMultiplers[4]) / 100; // 365 is the desired runway
      uint amountToMint = newTotalTokens - poolAmount;
      rideAddress.mint(amountToMint * 10 ** 18);
    }
  }

  function changeInterestRate(uint _newRate) public {
    require(msg.sender == owner, 'You must be the owner to run this.');
    rideInterestRatePercent = _newRate;
  }

  function setRideAddress(Ride _newRides) public {
    require(msg.sender == owner, 'You must be the owner to run this.');
    rideAddress = _newRides;
  }

  function transferRide(address _address, uint amount) public {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'You must be the owner to run this.');
    rideAddress.transfer(_address, amount);
  }

  function transferUSDC(address _address, uint amount) public {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'You must be the owner to run this.');
    usdcAddress.transfer(_address, amount);
  }

  function awardNode(address _address, uint _nodeType) public {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'You must be the owner to run this.');

    Account memory account;

    if(accounts[_address].exists){
      account = accounts[_address];
    }
    else{
      account = Account(true, 0, 0, 0, 0, 0, 0);
      rideNodesAddresses.push(_address);
    }

    if(_nodeType == 0){
      account.nanoCount++;
    }
    else if(_nodeType == 1){
      account.miniCount++;
    }
    else if(_nodeType == 2){
      account.kiloCount++;
    }
    else if(_nodeType == 3){
      account.megaCount++;
    }
    else if(_nodeType == 4){
      account.gigaCount++;
    }
    totalNodes++;
    accounts[_address] = account;
  }
}