// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Switch {
    uint256 private lastUpdated;
    bool public state = false;

    function on() external {
        state = true;
        lastUpdated = block.timestamp;
    }

    function off() external {
        require(state == true, "Switch: already off");
        require(block.timestamp > lastUpdated + 20, "Switch: too soon");

        state = false;
    }
}