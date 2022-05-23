/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract GasTest {

    mapping(uint256 => uint256) public map;
    uint256 public max_value = 0;
    uint256 public updated = 0;
    
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
    
    function test3(uint256[] calldata idx, uint256 x) public {
        for (uint256 j = 0; j < idx.length; j++) {
            uint256 i = idx[j];
            if (map[i] > 0 && i != x) {
                map[x] += 1;
                map[i] -= 1;
            }
        }
    }
    
    function test4(uint256 i, uint256 k) public {
        for (uint256 j = 0; j < k; j++) {
            if (map[i] < map[i + 1] * 1) {
                if (map[i] * map[i] < map[i + 1] * map[i + 1] * 1) {
                    updated += 1;
                    map[i + 10] += 1;
                    map[i + 11] -= 1;
                }
            }
        }
    }

    function add_new(uint256 n, uint256 value) public {
        for (uint256 i = max_value; i < max_value + n; i++) {
            map[i] = value;
        }
        max_value = max_value + n;
    }

}