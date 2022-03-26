/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract DummyContract {
    function prepareDataToSign(address _identity, uint256 claimTopic, bytes memory data) public pure returns (bytes32) {
        bytes32 dataHash = keccak256(abi.encode(_identity, claimTopic, data));
        return dataHash;
    }
}