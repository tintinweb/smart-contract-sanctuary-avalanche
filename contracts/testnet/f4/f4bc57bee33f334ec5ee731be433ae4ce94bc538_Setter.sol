/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16.0;

contract Setter {
    uint public senseOfLive = 42;

    function doubleSenseOfLive() external view returns (uint) {
        return senseOfLive * 2;
    }

    function setSenseOfLive(uint newSenseOfLive) external {
        senseOfLive = newSenseOfLive;
    }
}