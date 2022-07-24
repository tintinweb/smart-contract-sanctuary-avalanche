/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Echo {    
    event MessageEvent(address indexed _receiver, string _message);
    event IdentityEvent(string _communicationAddress);

    function logMessage(address _receiver, string calldata _message) external {
        emit MessageEvent(_receiver, _message);
    }

    function logIdentity(string calldata _communicationAddress) external {
        // TODO: Add a check to ensure _communicationAddress is a public key -> check length?
        // require(_communicationAddress == "", "Echo::logIdentity: INVALID_LENGTH");
        emit IdentityEvent(_communicationAddress);
    }
}