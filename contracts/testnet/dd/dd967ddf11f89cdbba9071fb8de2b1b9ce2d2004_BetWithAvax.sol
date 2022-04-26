/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BetWithAvax {
  uint8 private participantsCount = 0;
  mapping(uint => address) private participants;

  uint8 private LIMIT = 30;
  uint private PARTICIPATION_FEE = 1 ether;
  address private OWNER = 0x957A3ddE041B41a369E8Fda9e53BaC2E08E7E3dD;

  function join() public payable {
    require(msg.value >= PARTICIPATION_FEE, "You did not sent ether enought");
    participantsCount++;
    participants[participantsCount] = msg.sender;
    if( participantsCount == LIMIT ) {
      resetGame();
    }
  }

  function changeParticipationFee(uint newFee) public payable {
    require(msg.sender == OWNER, "Only owner can change fee");
    PARTICIPATION_FEE = newFee;
  }

  function changeOwner(address newOwner) public payable {
    require(msg.sender == OWNER, "Only owner can change owner");
    OWNER = newOwner;
  }

  function changeLimit(uint8 newLimit) public payable {
    require(msg.sender == OWNER, "Only owner can change limit");
    LIMIT = newLimit;
  }

  function resetGame() private {
    uint256 balance = address(this).balance;

    _withdraw(OWNER, balance / 6);

    address lucky = _getLucky();
    _withdraw(lucky, balance * 5 / 6);

    participantsCount = 0;
  }

  function getFee() public view returns (uint) {
    return PARTICIPATION_FEE;
  }

  function getCount() public view returns (uint8) {
    return participantsCount;
  }

  function getLimit() public view returns (uint8) {
    return LIMIT;
  }

  function _getLucky() private view returns (address) {
    return participants[_random()];
  }

  function _random() public view returns(uint){
    return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender))) % LIMIT;
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }
}