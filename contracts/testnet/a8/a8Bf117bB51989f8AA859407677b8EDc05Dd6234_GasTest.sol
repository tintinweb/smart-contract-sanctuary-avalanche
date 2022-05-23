/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract GasTest {

    mapping(uint256 => uint256) public map;
    uint256 max_value = 0;
    
    constructor() public {
        for (uint256 i = 0; i < 20; i++) {
            map[i] = i;
        }
        max_value = 20;
    }

    function update(uint256 n) public {
        for (uint256 i = 0; i < n; i++) {
            map[i] = i;
        }
    }

    function add_new(uint256 n) public {
        for (uint256 i = max_value; i < max_value + n; i++) {
            map[i] = i;
        }
        max_value = max_value + n;
    }

}