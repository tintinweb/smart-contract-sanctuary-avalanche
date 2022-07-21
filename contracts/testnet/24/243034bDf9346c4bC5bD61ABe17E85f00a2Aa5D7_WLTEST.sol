// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WLTEST {
    mapping(address => uint256) public map;

    function batchAdd(address[] calldata addresses, uint256 amount) public {
        for (uint256 i = 0; i < addresses.length; i++) {
            map[addresses[i]] = amount;
        }
    }
}