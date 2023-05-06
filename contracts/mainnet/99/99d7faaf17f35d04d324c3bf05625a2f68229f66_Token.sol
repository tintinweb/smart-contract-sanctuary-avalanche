/**
 *Submitted for verification at snowtrace.io on 2023-05-06
*/

pragma solidity ^0.8.2;

// SPDX-License-Identifier: MIT

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 69420000000000 * 10 ** 18;
    string public name = "Red Pepe";
    string public symbol = "RPEPE";
    uint public decimals = 18;

    uint public taxRate = 150; // equivalent to 1.5 percent tax with two decimal precision
    uint public burnRate = 0;
    address public taxReceiver = 0xb26c36fC8aCF5f34055669C4BB9CF7A73397577e;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Burn(address indexed burner, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function balanceOf(address account) public view returns(uint) {
        return balances[account];
    }

    function setBurnRate(uint _burnRate) public onlyOwner {
        burnRate = _burnRate;
    }

    function setTaxRate(uint _taxRate) public onlyOwner {
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyOwner {
        require(_taxReceiver != address(0), "Tax receiver cannot be the zero address");
        taxReceiver = _taxReceiver;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        require(to != address(0), "transfer: cannot send to zero address");
        uint tax = value * taxRate / 10000;
        uint burn = value * burnRate / 10000;
        balances[to] += value - tax - burn;
        balances[msg.sender] -= value;
        balances[taxReceiver] += tax;
        totalSupply -= burn;
        emit Transfer(msg.sender, to, value - tax - burn);
        emit Transfer(msg.sender, taxReceiver, tax);
        emit Transfer(msg.sender, address(0), burn);
        if (burn > 0) {
            emit Burn(msg.sender, burn);
        }
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        require(to != address(0), "transferFrom: cannot send to zero address");
        uint tax = value * taxRate / 10000;
        uint burn = value * burnRate / 10000;
        balances[to] += value - tax - burn;
        balances[from] -= value;
        allowance[from][msg.sender] -= value;
        balances[taxReceiver] += tax;
        totalSupply -= burn;
        emit Transfer(from, to, value - tax - burn);
        emit Transfer(from, taxReceiver, tax);
        emit Transfer(from, address(0), burn);
        if (burn > 0) {
            emit Burn(from, burn);
        }
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        require(allowance[msg.sender][spender] == 0 || value == 0, "approve: current allowance must be 0 or new value must be 0");
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}