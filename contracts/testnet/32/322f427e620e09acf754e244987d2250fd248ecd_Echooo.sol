/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Echooo {    
    event Message(address indexed recieverId, string message);
    event Communication(string comm);

    function logMessage(address recieverId_, string calldata message_) external {
        emit Message(recieverId_, message_);
    }

    function logCommunication(string calldata comm_) external {
        emit Communication(comm_);
    }
}