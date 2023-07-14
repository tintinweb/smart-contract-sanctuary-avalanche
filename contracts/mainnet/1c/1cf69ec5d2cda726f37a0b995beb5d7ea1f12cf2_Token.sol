/**
 *Submitted for verification at snowtrace.io on 2023-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name = "sdsdsd";
    string public symbol = "sssss";
    uint256 public decimals = 18;

    uint256 public totalSupply;
    uint256 public burnPercentage;
    uint256 public marketingPercentage;
    address public marketingWallet;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public whitelist; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    address public owner; 

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor(uint256 initialSupply, uint256 _burnPercentage, uint256 _marketingPercentage, address _marketingWallet) {
        totalSupply = initialSupply *10**18;
        burnPercentage = _burnPercentage;
        marketingPercentage = _marketingPercentage;
        marketingWallet = _marketingWallet;
        owner = msg.sender; 

       
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);

       
        whitelist[marketingWallet] = true;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance"); 

        uint256 burnAmount = 0;
        uint256 marketingAmount = 0;
        uint256 transferAmount = value;

       
        if (!whitelist[msg.sender]) {
            burnAmount = (value * burnPercentage) / 100;
            marketingAmount = (value * marketingPercentage) / 100;
            transferAmount = value - burnAmount - marketingAmount;
            totalSupply -= burnAmount;

            if (burnAmount > 0) {
                emit Burn(msg.sender, burnAmount);
                emit Transfer(msg.sender, burnAddress, burnAmount);
            }

            if (marketingAmount > 0) {
                balanceOf[marketingWallet] += marketingAmount;
                emit Transfer(msg.sender, marketingWallet, marketingAmount);
            }
        }

        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferAmount;

        emit Transfer(msg.sender, to, transferAmount);

        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}