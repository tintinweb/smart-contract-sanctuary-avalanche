/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BankingApp {
    mapping(address => uint256) private balances;
    mapping(address => bool) private isRegistered;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    function deposit() public payable {
        require(msg.value > 0, "Invalid deposit amount");
        
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
        
        if (!isRegistered[msg.sender]) {
            isRegistered[msg.sender] = true;
        }
    }
    
    function withdraw(uint256 amount) public {
        require(amount > 0, "Invalid withdrawal amount");
        require(amount <= balances[msg.sender], "Insufficient balance");
        
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        
        emit Withdrawal(msg.sender, amount);
    }
    
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }
    
    function isUserRegistered(address user) public view returns (bool) {
        return isRegistered[user];
    }
}