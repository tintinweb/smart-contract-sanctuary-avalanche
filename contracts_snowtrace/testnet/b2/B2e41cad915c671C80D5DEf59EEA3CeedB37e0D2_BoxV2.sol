// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract BoxV2 {
  uint public value;

  function inc() external {
    value += 1;
  }
}