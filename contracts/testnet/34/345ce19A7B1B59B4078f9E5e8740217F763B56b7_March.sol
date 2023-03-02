/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-01
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

contract March {

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }
}