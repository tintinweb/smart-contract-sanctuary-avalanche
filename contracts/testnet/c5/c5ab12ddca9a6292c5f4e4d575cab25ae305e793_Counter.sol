/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Counter {
    uint256 public count;   // state

    function increment() external { // function where we increment state
        count += 1;
    }

    function decrement() external { // function where we decrement state
        count -= 1;
    }
}