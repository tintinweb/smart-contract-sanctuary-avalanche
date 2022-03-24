/**
 *Submitted for verification at snowtrace.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;



contract FortyTwoLines{


    mapping(address => uint) balance;
    mapping(address => mapping(address => uint)) public allowances;

    uint public totalSupply = 1000000 * 10 ** 18;
    string public tokenName = "42Lines";
    string public symbol = "42L";
    uint public decimals = 18;

    event Transfer(address indexed _from, address indexed _to, uint indexed _value);
    event Approval(address indexed _owner, address indexed _spender, uint indexed _value);

    constructor (){
        balance[msg.sender] = totalSupply;
    }

    function balanceOf(address _from) public view returns(uint){
        return balance[_from]; 
    }

    function approve(address _spender, uint _value) public returns(bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;

    }

    function transfer(address _to, uint _value) public returns(bool){
        require(balanceOf(msg.sender) >= _value, "balance too low");
        balance[msg.sender] = balance[msg.sender]-=_value;
        balance[_to] = balance[_to]+=_value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transerFrom(address _from, address _to, uint _value) public returns (bool){
        require(balanceOf(_from) >= _value, "allowance too low");
        balance[_from] = balance[_from]-=_value;
        balance[_to] = balance[_to]+=_value;        
        emit Transfer(_from, _to, _value);
        return true;
    }

}