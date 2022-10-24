// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import './Election.sol';

contract MainContract {
  uint public electionId = 0;
  mapping (uint => address) public elections;

  event EventSuccess(uint electionId,address electionAddress);

  
  function createElection (string[] memory _nda, string[] memory _candidates) public {
    Election election = new Election(_nda, _candidates);
    address electionAddress = address(election);

    emit EventSuccess(electionId, electionAddress);
    elections[electionId] = electionAddress;

    electionId++;

  }


}