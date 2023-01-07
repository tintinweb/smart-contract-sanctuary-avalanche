/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Counter {
    uint256 public count;

    function inc() external {
        count += 1;
    }

    function dec() external {
        count -= 1;
    }
}