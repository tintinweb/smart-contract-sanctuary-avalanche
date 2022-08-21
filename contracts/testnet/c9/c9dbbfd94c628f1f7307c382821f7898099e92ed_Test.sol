/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

contract Test {

    mapping (address => uint) private data;

    function set(uint _number) external {
        data[msg.sender] = _number;
    }

    function get() external view returns(uint) {
        return data[msg.sender];
    } 

}