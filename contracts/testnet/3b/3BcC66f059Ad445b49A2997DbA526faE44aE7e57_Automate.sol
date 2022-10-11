/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Automate {
    uint256 public num = 0;
    event Counted(uint256 num);
    function count() public {
        num += 1;
        emit Counted(num);
    }
}