/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

contract Person {
    address payable public owner;

    constructor() { 
        owner = payable(msg.sender); 
    }

    function greetings() public pure returns (string memory) {
        return "Hello";
    }

    function kill() public {
        if (msg.sender == owner) selfdestruct(owner);
    }
}