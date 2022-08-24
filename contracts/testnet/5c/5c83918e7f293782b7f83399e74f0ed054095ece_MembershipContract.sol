/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MembershipContract {
  address contractManager;
  uint256 expireAfter = 2592000; // 1 day = 86400 seconds => 30 days = 2592000 seconds. 
  //can directly use uint256 expireAfter = 30 days; instead but I'll go that way!

  struct MembershipFormat {
    string username;
    address memberAddress;
    uint256 creationDate;
    uint256 expirationDate;
   // don't need this, to check. (Skipping unnecessary loads)
   // bool isMembershipExpired;
  }
  constructor(address _manager) { 
    contractManager = _manager;  
  }
  mapping(address => MembershipFormat) private MembershipByAddress; //using address as unique identifier

  modifier onlyManager() {
    require(msg.sender == contractManager,
      "REVERTED: Not allowed!");
    _;
  }
  event membershipGranted(address to);
  event usernameUpdated(address Of, string oldName, string newName);
  event membershipDeleted(address Of);
  event membershipRenewed(address Of);
  event contractManagerChanged(address from, address to);
  
  //grant membership to more than one user
  
  function _grantMemberships(address[] memory _uaddr) external onlyManager {
    for (uint i = 0; i < _uaddr.length; i++) {
      grantMembership(_uaddr[i]); //you gotta get a bunch of TRUEEEEEE😂
    }
  }

  //function to grant membership to one user!
  //for simplicity and gas optimization, this function takes only the member address - members can set their username later!

  function grantMembership(address _member) public onlyManager returns (bool) {
    require(_member != address(0), "Not a valid account");
    MembershipFormat storage m = MembershipByAddress[_member];
    require(m.creationDate == 0, "Member already exist!");
    //assign _creationDate to current block's timestamp
    uint256 _creationDate = block.timestamp;
    uint256 _expirationDate = _creationDate + expireAfter;
    //for simplicity of contract manager and gas optimization, assigning username to Member -> Members are able to change it via changeUsername();
    m.username = "Member";
    m.memberAddress = _member;
    m.creationDate = _creationDate;
    m.expirationDate = _expirationDate;
    emit membershipGranted(_member);
    //returning true to avoid spammy outputs
    return true;
  }
  function currentExpireLimitInDays() public view returns (uint) {
  return expireAfter/86400; 
  }
  function isExpired(address _addd) external view returns (bool) {
    MembershipFormat storage _mem = MembershipByAddress[_addd];
    require(_mem.creationDate != 0, "Membership doesn't exist!");
    if ((block.timestamp - _mem.creationDate) >= _mem.expirationDate) {
      return true;
    } else {
      return false;
    }
  }
  function changeUsername(address ad, string memory _newName) public returns (bool) {
    MembershipFormat storage m = MembershipByAddress[ad];
    require(m.creationDate != 0, "HALT: Member doesn't exist!");
    require((block.timestamp - m.creationDate) < m.expirationDate,
      "Your membership have been expired!");
    emit usernameUpdated(ad, m.username, _newName);
    m.username = _newName;
    return true;
  }

  function getMembership(address _mem) public view returns (MembershipFormat memory) {
    MembershipFormat storage memship = MembershipByAddress[_mem];
    require(memship.creationDate != 0, "HALT: Member doesn't exist!");
    require((block.timestamp - memship.creationDate) < memship.expirationDate, "Your membership have been expired");
    return memship;
  }
  
  //delete multiple memberships
  function _deleteMemberships(address[] memory addres) external onlyManager {
  for (uint i = 0; i < addres.length; i++) {
  deleteMembership(addres[i]); //No please don't spam 'true'😂
  } 
 }
  
//delete single membership
  function deleteMembership(address toDelete) public onlyManager returns(bool) {
    MembershipFormat storage _mem = MembershipByAddress[toDelete];
    require(_mem.creationDate != 0, "HALT: Member doesn't exist!");
    //assigning default values, not keeping the old ones since it is "DELETING"
    _mem.username = "";
    _mem.memberAddress = 0x000000000000000000000000000000000000dEaD;
    _mem.creationDate = 0;
    _mem.expirationDate = 0;
    emit membershipDeleted(toDelete);
    return true;
  }

  function renewMembership(address memAddress) external onlyManager returns(bool) {
    MembershipFormat storage m = MembershipByAddress[memAddress];
    //can remove this line if users are able to renew before expiry
    require(m.creationDate != 0, "HALT: Membership doesn't exist!");
    require((block.timestamp - m.creationDate) > m.expirationDate, "Membership is still active!");
    m.creationDate = block.timestamp;
    m.expirationDate = block.timestamp + expireAfter;
    emit membershipRenewed(memAddress);
    return true;
  }
  //_num should be integer representing days (1,2,3 etc)
  function updateExpireAfter(uint256 _num) external onlyManager returns (bool) {
    expireAfter = (_num*86400);
    return true;
  }
  function changeManager(address to) external onlyManager returns (bool) {
    emit contractManagerChanged(contractManager, to);
    contractManager = to;
    return true;
  }
}