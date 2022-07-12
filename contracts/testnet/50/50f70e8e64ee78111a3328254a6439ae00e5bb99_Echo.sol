/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Echo {    
    event Message(address indexed reciever, string message);
    event Identity(string indexed communicationAddress);

    function logMessage(address reciever_, string memory message_) external {
        emit Message(reciever_, message_);
    }

    function logIdentity(string memory communicationAddress_) external {
        emit Identity(communicationAddress_);
    }
}