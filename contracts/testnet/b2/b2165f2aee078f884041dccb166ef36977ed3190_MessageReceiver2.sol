/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

interface IReceiver {
    function receiveMessage(bytes calldata message, bytes calldata signature)
        external
        returns (bool success);
}

contract MessageReceiver2 {
    function receive2(
        IReceiver transmitter,
        bytes calldata message1,
        bytes calldata signature1,
        bytes calldata message2,
        bytes calldata signature2
    ) external {
        bool success1 = transmitter.receiveMessage(message1, signature1);
        bool success2 = transmitter.receiveMessage(message2, signature2);
        require(success1 && success2);
    }    
}