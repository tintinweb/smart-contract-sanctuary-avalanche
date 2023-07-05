// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrossChainMock {
    uint256 public number = 100;

    function store(uint256 _num) public returns (uint256) {
        number = _num;
        return number;
    }
}