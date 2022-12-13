/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract timestamp {
    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}