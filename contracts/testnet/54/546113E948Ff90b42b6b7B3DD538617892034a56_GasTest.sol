/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract GasTest {

    mapping(uint256 => uint256) public map;
    
    constructor() public {
        for (uint256 i = 0; i < 20; i++) {
            map[i] = i;
        }
    }

    function fund() public payable {
        for (uint256 i = 0; i < 20; i++) {
            map[i] = i;
        }
    }

}