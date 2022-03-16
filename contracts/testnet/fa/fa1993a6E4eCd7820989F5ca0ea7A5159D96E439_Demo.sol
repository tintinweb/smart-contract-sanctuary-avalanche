/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


contract Demo {
    uint256 number;

    function get() public view returns (uint256) {
        return number;
    }

    function set(uint256 _number) public {
        number = _number;
    }
}