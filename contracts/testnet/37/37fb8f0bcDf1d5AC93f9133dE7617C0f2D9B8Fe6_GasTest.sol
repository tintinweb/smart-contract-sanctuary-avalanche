/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract GasTest {

    mapping(uint256 => uint256) public map;
    uint256 public max_value = 0;
    
    constructor() public {
        for (uint256 i = 0; i < 20; i++) {
            map[i] = i;
        }
        max_value = 20;
    }

    function test(uint256 x) public {
        for (uint256 i = 0; i < max_value; i++) {
            if (map[i] > 0 && i != x) {
                map[x] += 1;
                map[i] -= 1;
            }
        }
    }
    
    function test1(uint256 i, uint256 x) public {
        if (map[i] > 0 && i != x) {
            map[x] += 1;
            map[i] -= 1;
        }
    }
    
    function test3(uint256 i, uint256 j, uint256 k, uint256 x) public {
        if (map[i] > 0 && i != x) {
            map[x] += 1;
            map[i] -= 1;
        }

        if (map[j] > 0 && j != x) {
            map[x] += 1;
            map[j] -= 1;
        }

        if (map[k] > 0 && k != x) {
            map[x] += 1;
            map[k] -= 1;
        }
    }

    function add_new(uint256 n, uint256 value) public {
        for (uint256 i = max_value; i < max_value + n; i++) {
            map[i] = value;
        }
        max_value = max_value + n;
    }

}