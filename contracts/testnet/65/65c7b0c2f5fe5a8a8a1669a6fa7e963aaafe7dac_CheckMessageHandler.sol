/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-06
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

contract CheckMessageHandler {

    event MessageHandlerChecked(uint32 sourceDomain, bytes32 sender, bytes messageBody);

    function handleReceiveMessage(
        uint32 sourceDomain,
        bytes32 sender,
        bytes calldata messageBody
    ) external returns (bool) {
        emit MessageHandlerChecked(sourceDomain, sender, messageBody);

        return true;
    }    

}