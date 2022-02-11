/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract Purchase {
    uint public balance;
    address payable public owner;
    address payable public associate;

    constructor() payable
    {   
        balance = msg.value;
        owner = payable(msg.sender);
        associate = payable(0xBA764fae2Fa93c26fFB7475e981f580b0F74d9fa);
    }
    
    receive() payable external {
        balance += msg.value;
    }

    function refundhalfalf() external {
        uint value = balance / 2;
        owner.transfer(value);
        associate.transfer(value);
    }

}