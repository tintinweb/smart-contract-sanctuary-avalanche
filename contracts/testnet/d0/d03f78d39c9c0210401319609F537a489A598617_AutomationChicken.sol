/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationChicken {
  uint256 private _chicksCount;

  function addChicken() external {
    _chicksCount++;
  }

  function getChicksCount() external view returns (uint256) {
    return _chicksCount;
  }

  function shoutWithChicks() external view returns (string memory) {
    if (_chicksCount >= 10) {
      revert('they are too many of us');
    }

    return 'waargh!!';
  }
}