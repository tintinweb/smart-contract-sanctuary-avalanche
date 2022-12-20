/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReleaseAvax {
    


    mapping(address => bool) public owners;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Deposit(address indexed from, uint256 value);

    constructor(address f, address b, address e) {
        owners[f] = true;
        owners[b] = true;
        owners[e] = true;

    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint256 amount) public {
        require(owners[msg.sender] == true, "You are not an owner");
        payable(msg.sender).transfer(amount);
    }
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
    
}