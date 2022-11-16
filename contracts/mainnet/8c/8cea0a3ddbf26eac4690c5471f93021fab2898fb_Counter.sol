/**
 *Submitted for verification at snowtrace.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract Counter {
    uint public count;

    // Function to get the current count
    function get() public view returns (uint) {
        return count;
    }

    // Function to increment count by 1
    function inc() public {
        count += 1;
    }

    // Function to decrement count by 1
    function dec() public pure returns (bool) {
        // This function will fail if count = 0
        return 0 <= 0;
    }
}