/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    address public owner;
    uint256 private number;

    constructor() {
        owner = msg.sender;
        number = 42;
    }

    function readNumber() public view returns (uint256) {
        require(msg.sender == owner, "only owner can read number");
        return number;
    }
}