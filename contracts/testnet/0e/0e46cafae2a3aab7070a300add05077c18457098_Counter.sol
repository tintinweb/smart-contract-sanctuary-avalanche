// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

contract Counter {
    uint256 public count;

    function increment(uint256 value) external {
        count += value;
    }
}