/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FeeCollector {
    address public immutable owner;
    uint256 public balance;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        balance += msg.value;
    }

    function withdraw(uint256 amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw!");
        require(amount <= balance, "Insufficient funds!");
        destAddr.transfer(amount);
        balance -= amount;
    }
}