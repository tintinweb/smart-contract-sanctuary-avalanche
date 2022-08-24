/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-23
*/

pragma solidity ^0.8.9;

contract MembershipContract {
address contractManager;
uint256 expireAfter = 30 days;
uint256 id;

struct MembershipFormat {
string username;
address memberAddress;
uint256 creationDate;
uint256 expirationDate;
}
constructor(address _manager) {
contractManager = _manager;
}
mapping(address => MembershipFormat) public MembershipByAddress; //using address as unique identifier

modifier checkIfExpired(address addr) {
MembershipFormat storage m = MembershipByAddress[addr];

require((block.timestamp - m.creationDate) >= m.expirationDate,
"Your membership have been expired!");
_;
}
modifier onlyManager() {
require(msg.sender == contractManager,
"REVERTED: Not allowed!");
_;
}
event membershipGranted();
event usernameUpdated();
event membershipDeleted();
event membershipRenewed();

//grant membership to more than one user
function _grantMemberships(address[] memory _uaddr) private onlyManager {
for (uint i = 0; i < _uaddr.length; i++) {
_grantMembership(_uaddr[i]);
}
}

//function to grant membership to one user!
//for simplicity and gas optimization, this function takes only the member address - members can change their username later!

function _grantMembership(address _member) private onlyManager {
MembershipFormat storage m = MembershipByAddress[_member];
require(m.creationDate == 0, "Member already exist!");
//assign _creationDate to current timestamp
uint256 _creationDate = block.timestamp;
uint256 _expirationDate = _creationDate + expireAfter;
id += 1; //not an unique identifier, just to give each member a unique username until they choose to change! (Member #1, Member #2 etc)
   m.username = "Member #";
   m.memberAddress = _member;
   m.creationDate = _creationDate;
   m.expirationDate = _expirationDate;
    emit membershipGranted();
}

function changeUsername(string memory _name) public {
MembershipFormat storage m = MembershipByAddress[msg.sender];
require(m.creationDate != 0, "HALT: Member doesn't exist!");
require((block.timestamp - m.creationDate) >= m.expirationDate,
"Your membership have been expired!");
m.username = _name;
}

function getMembership(address _mem) public view returns (MembershipFormat memory) {
MembershipFormat storage memship = MembershipByAddress[_mem];
require(memship.creationDate != 0, "HALT: Member doesn't exist!");
return memship;
}

function deleteMembership(address toDelete) private onlyManager {
MembershipFormat storage _mem = MembershipByAddress[toDelete];
require(_mem.creationDate != 0, "HALT: Member doesn't exist!");
emit membershipDeleted();
}

function renewMembership(address memAddress) private onlyManager {
MembershipFormat storage m = MembershipByAddress[memAddress];
require((block.timestamp - m.creationDate) >= m.expirationDate, "Membership is still active!");
m.creationDate = block.timestamp;
m.expirationDate = block.timestamp + expireAfter;
emit membershipRenewed();
}
}