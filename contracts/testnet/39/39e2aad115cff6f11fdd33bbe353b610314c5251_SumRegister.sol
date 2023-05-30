/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SumRegister {
    mapping(address => uint) public sumResults;

    event Sum(address indexed user, uint num1, uint num2, uint sum);

    function registerSum(uint num1, uint num2) public returns (uint) {
        uint sum = num1 + num2;
        sumResults[msg.sender] = sum;
        emit Sum(msg.sender, num1, num2, sum);
        return sum;
    }
}