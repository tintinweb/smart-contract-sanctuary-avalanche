// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MigrationFake {
    uint256 public counter;

    function migrate() public returns (uint256) {
        counter += 1;
        return counter;
    }
}