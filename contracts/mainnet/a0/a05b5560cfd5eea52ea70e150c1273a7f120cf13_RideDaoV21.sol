// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ride.sol";
import "./USDC.sol";

// RideDao V21
contract RideDaoV21 {
  uint public totalNodes;
  address [] public rideNodesAddresses;

  Ride public rideAddress;
  USDC public usdcAddress;
  address private owner;
  uint public rideInterestRatePercent;
  uint penaltyPercentage;
  uint penaltyTime;
  address addressToBurn;

  struct Account {
    bool exists;
    uint tuktukCount;
    uint kombiCount;
    uint fiatCount;
    uint camaroCount;
    uint lamboCount;
    uint lastClaimTime;
  }

  mapping(address => Account) public accounts;

  // 0.5%, 0.6%, 0.7%, 0.8%, 1% /day
  uint [] public nodeMultiplers = [1, 10, 70, 160, 1000];
  uint [] public nodeUSDCCost = [25, 100, 500, 1000, 5000];
  uint [] public nodeRIDESCost = [25, 100, 500, 1000, 5000];

  constructor(Ride _rideAddress, USDC _usdcAddress, address _burn) {
    owner = msg.sender;
    rideAddress = _rideAddress;
    usdcAddress = _usdcAddress;
    addressToBurn = _burn;

    rideInterestRatePercent = 10;
    penaltyPercentage = 20;
    penaltyTime = 2*86400;

  }

  function setupAccountForMigration(address _address, uint _tuktukCount, uint _kombiCount, uint _fiatCount, uint _camaroCount, uint _lamboCount, uint lastClaimTime) public {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'Only owner can migrate nodes.');
      Account memory account = Account(true, _tuktukCount, _kombiCount, _fiatCount, _camaroCount, _lamboCount, lastClaimTime);
      rideNodesAddresses.push(_address);
      totalNodes += _tuktukCount + _kombiCount + _fiatCount + _camaroCount + _lamboCount;
      accounts[_address] = account;
  }

  function setNewNodeMultiplers(uint _nodeType, uint _nodeMultiplier) public {
    require(msg.sender == owner, 'Only owner can change node multipliers.');
    nodeMultiplers[_nodeType] = _nodeMultiplier;
  }

  function setNodeCosts(uint _nodeType, uint _RIDESCost, uint _USDCCost) public {
    require(msg.sender == owner, 'Only owner can change node costs.');
    nodeUSDCCost[_nodeType] = _USDCCost;
    nodeRIDESCost[_nodeType] = _RIDESCost;
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
    return(acc.tuktukCount, acc.kombiCount, acc.fiatCount, acc.camaroCount, acc.lamboCount, acc.lastClaimTime);
  }

  // accounts getter
  function getlastClaimTime(address _address) public view returns(uint) {
    Account memory acc = accounts[_address];
    return(block.timestamp - acc.lastClaimTime);
  }

  function calculateInterestClaim(address _address) public view returns(uint) {
      Account memory acc = accounts[_address];
      uint timeElapsed = getlastClaimTime(_address);

      uint interestAccumulated;
      interestAccumulated = (acc.tuktukCount * nodeMultiplers[0] * rideInterestRatePercent * timeElapsed * 10 ** 18) / (100 * 86400);
      interestAccumulated += (acc.kombiCount * nodeMultiplers[1] * rideInterestRatePercent * timeElapsed * 10 ** 18) / (100 * 86400);
      interestAccumulated += (acc.fiatCount * nodeMultiplers[2] * rideInterestRatePercent * timeElapsed * 10 ** 18) / (100 * 86400);
      interestAccumulated += (acc.camaroCount * nodeMultiplers[3] * rideInterestRatePercent * timeElapsed * 10 ** 18) / (100 * 86400);
      interestAccumulated += (acc.lamboCount * nodeMultiplers[4] * rideInterestRatePercent * timeElapsed * 10 ** 18) / (100 * 86400);

      return(interestAccumulated);
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
      account = Account(true, 0, 0, 0, 0, 0, block.timestamp);
      rideNodesAddresses.push(_address);
    }

    if(_nodeType == 0){
      require(_rideAmount >= nodeRIDESCost[0] * 10 ** 18, 'Not enough RIDES provided for the Tuktuk node.');
      require(_usdcAmount >= nodeUSDCCost[0] * 10 ** 6, 'Not enough USDC.e provided for the Tuktuk node.');
      account.tuktukCount++;
    }
    else if(_nodeType == 1){
      require(_rideAmount >= nodeRIDESCost[1] * 10 ** 18, 'Not enough RIDES provided for the Kombi node.');
      require(_usdcAmount >= nodeUSDCCost[1] * 10 ** 6, 'Not enough USDC.e provided for the Kombi node.');
      account.kombiCount++;
    }
    else if(_nodeType == 2){
      require(_rideAmount >= nodeRIDESCost[2] * 10 ** 18, 'Not enough RIDES provided for the Fiat node.');
      require(_usdcAmount >= nodeUSDCCost[2] * 10 ** 6, 'Not enough USDC.e provided for the Fiat node.');
      account.fiatCount++;
    }
    else if(_nodeType == 3){
      require(_rideAmount >= nodeRIDESCost[3] * 10 ** 18, 'Not enough RIDES provided for the Camaro node.');
      require(_usdcAmount >= nodeUSDCCost[3] * 10 ** 6, 'Not enough USDC.e provided for the Camaro node.');
      account.camaroCount++;
    }
    else if(_nodeType == 4){
      require(_rideAmount >= nodeRIDESCost[4] * 10 ** 18, 'Not enough RIDES provided for the Lambo node.');
      require(_usdcAmount >= nodeUSDCCost[4] * 10 ** 6, 'Not enough USDC.e provided for the Lambo node.');
      account.lamboCount++;
    }
    totalNodes++;
    accounts[_address] = account;

    rideAddress.transferFrom(_address, address(this), _rideAmount);
    usdcAddress.transferFrom(_address, address(this), _usdcAmount);
  }

  function withdrawInterest(address _to) public {
    require(_to != address(0), "_to is address 0");
    require(msg.sender == _to, 'Only user can widthraw its own funds.');
    require(getlastClaimTime(_to) > 30, 'You must wait at least 30 seconds to claim your rewards again.');
    uint amount = calculateInterestClaim(_to);
    if (getlastClaimTime(_to) < penaltyTime) {
        rideAddress.transfer(addressToBurn, amount * penaltyPercentage/100);
        amount = amount * (100 - penaltyPercentage) / 100;
    }

    accounts[_to].lastClaimTime = block.timestamp;
    rideAddress.transfer(_to, amount);
    }

  function resetTimer(address _to, uint timestamp) public {
    require(msg.sender == owner, 'You must be the owner to run this.');
    accounts[_to].lastClaimTime = timestamp;
  }

  function setBurnAddress(address _burn) public {
    require(msg.sender == owner, 'You must be the owner to run this.');
    addressToBurn = _burn;
  }

  function changeInterestRate(uint _newRate) public {
    require(msg.sender == owner, 'You must be the owner to run this.');
    rideInterestRatePercent = _newRate;
  }

  function setpenaltyPercentage(uint _penaltyPercentage) public {
    require(msg.sender == owner, 'You must be the owner to run this.');
    penaltyPercentage = _penaltyPercentage;
  }
  
  function setPenalty(uint _penaltyTime) public {
    require(msg.sender == owner, 'You must be the owner to run this.');
    penaltyTime = _penaltyTime;
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
      account = Account(true, 0, 0, 0, 0, 0, block.timestamp);
      rideNodesAddresses.push(_address);
    }

    if(_nodeType == 0){
      account.tuktukCount++;
    }
    else if(_nodeType == 1){
      account.kombiCount++;
    }
    else if(_nodeType == 2){
      account.fiatCount++;
    }
    else if(_nodeType == 3){
      account.camaroCount++;
    }
    else if(_nodeType == 4){
      account.lamboCount++;
    }
    totalNodes++;
    accounts[_address] = account;
  }
}