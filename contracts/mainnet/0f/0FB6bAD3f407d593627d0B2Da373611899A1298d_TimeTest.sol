/**
 *Submitted for verification at snowtrace.io on 2022-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TimeTest {
    function testBlockTime(uint256 sendTime, uint256 targetTime) external payable {
        if (block.timestamp < targetTime) {
            revert(string(abi.encodePacked("wanted ", targetTime, " got ", block.timestamp)));
        }
    }
}