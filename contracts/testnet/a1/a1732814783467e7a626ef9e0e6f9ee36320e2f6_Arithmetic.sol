/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Arithmetic {
    uint x;

    function add(uint num) external {
        x += num;
    }
}