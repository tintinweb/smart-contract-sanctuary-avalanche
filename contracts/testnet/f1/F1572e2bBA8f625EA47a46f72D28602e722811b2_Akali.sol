/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract Akali {

    //Variable
    uint public totalSupply = 10000 * 10 ** 18;
    string public name = "AkaliToken2";
    string public symbol ="AKT2";
    uint public decimals = 18;


    //Maping

    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public allowance;

    //Events
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    constructor(){

        balances[msg.sender] = totalSupply;
    }

    //Functions

    function balanceOf(address owner) public view returns (uint){
        return balances[owner];
    }

    function transfer(address to, uint amount) public returns (bool){
        require(balances[msg.sender]>= amount,"Balance to Low");
        balances[to] += amount;
        balances[msg.sender]-= amount;
        emit Transfer(msg.sender, to,amount);
        return true;
    }

    function transferFrom(address from, address to,uint amount) public returns (bool){
        require(balanceOf(from)>=amount,"Balance to low");
        require ( allowance[from][msg.sender] >= amount,"Balance to Low");
        balances[to] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
        
    }

    function approve(address spender, uint amount) public returns (bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}