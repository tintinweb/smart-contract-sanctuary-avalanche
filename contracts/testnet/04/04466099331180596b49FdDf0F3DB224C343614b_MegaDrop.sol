/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract MegaDrop {

    string public message;

    constructor() {
        message = "Hello World";
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }
}