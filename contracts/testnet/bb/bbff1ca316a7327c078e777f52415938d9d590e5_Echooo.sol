/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Echooo {    
    event Message(address indexed recieverId, string message);
    event Communication(string indexed communicationAddr);

    function logMessage(address recieverId_, string calldata message_) external {
        emit Message(recieverId_, message_);
    }

    function logCommunication(string calldata communicationAddr_) external {
        emit Communication(communicationAddr_);
    }
}