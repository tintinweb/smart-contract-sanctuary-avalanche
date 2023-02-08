/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

contract Messenger {
    string last_msg = '';

    event Log(address indexed sender, string ev_msg);

    constructor () {}

    function sendMessage(string memory message) public {
        last_msg = message;

        emit Log(msg.sender, message);
    }

    function getMessage() public view returns (string memory) {
        return last_msg;
    }
}