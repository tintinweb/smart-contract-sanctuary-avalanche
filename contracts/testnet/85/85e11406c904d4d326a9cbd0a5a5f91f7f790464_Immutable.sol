/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Immutable {
    // coding convention to uppercase constant variables
    address public immutable MY_ADDRESS;
    uint public immutable MY_UINT;

    constructor(uint _myUint) {
        MY_ADDRESS = msg.sender;
        MY_UINT = _myUint;
    }
}