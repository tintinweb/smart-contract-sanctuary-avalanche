/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint storedData;

    function get() external view returns (uint) {
        return storedData;
    }
    
    function set(uint x) external {
        storedData = x;
    }

    
}