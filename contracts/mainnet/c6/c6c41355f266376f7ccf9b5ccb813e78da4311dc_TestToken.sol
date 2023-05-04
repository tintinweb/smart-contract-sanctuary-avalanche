/**
 *Submitted for verification at snowtrace.io on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestToken {
    string public name = "Test";
    string public symbol = "TST";
    uint256 public totalSupply = 1000000000; // 1 billion tokens
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}