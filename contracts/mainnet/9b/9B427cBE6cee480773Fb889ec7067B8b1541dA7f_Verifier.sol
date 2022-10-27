// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Verifier {
    constructor(uint256 i) {
        i;
    }

    function test() external pure returns (bool) {
        return true;
    }
}