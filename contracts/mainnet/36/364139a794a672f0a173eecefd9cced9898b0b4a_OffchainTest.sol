/**
 *Submitted for verification at snowtrace.io on 2023-07-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract OffchainTest {
    uint256 a;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function stateChange() external {
        a++;
    }

    function stateChangePermission() external {
        a++;
        require(msg.sender == owner, "Only owner");
    }
}