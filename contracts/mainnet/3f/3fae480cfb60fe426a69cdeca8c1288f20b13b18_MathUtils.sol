/**
 *Submitted for verification at snowtrace.io on 2022-02-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MathUtils {

  constructor() {}

  function xor(uint256 first, uint256 second) public pure returns(uint256) {
    return first ^ second;
  }
}