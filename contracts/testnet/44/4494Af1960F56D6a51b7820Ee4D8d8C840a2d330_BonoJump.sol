// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract BonoJump {

  string public challengeId;
  address public requestor;
  bool private initialized;
  uint256 public consecutiveSaves;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  function initialize(string memory _challengeId, address _requestor)
        external
    {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        challengeId = _challengeId;
        requestor = _requestor;
    }


  function SavePenalty(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 bonoJump = blockValue / FACTOR;
    bool ballDirection = bonoJump == 1 ? true : false;

    if (ballDirection == _guess) {
      consecutiveSaves++;
      return true;
    } else {
      consecutiveSaves = 0;
      return false;
    }
  }

    //For VERIFIER contract
  function verify() external view returns(bool) {
      return consecutiveSaves==5;
  } 
}