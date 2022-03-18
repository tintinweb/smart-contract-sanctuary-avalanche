// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Hello {
    
    mapping (address => uint256) public aaa;

    constructor() public {
        
    }

    function setVal() public {
        aaa[msg.sender] = 10;
    }

    function getVal() public view returns (uint256) {
        return aaa[msg.sender];
    }

    
}