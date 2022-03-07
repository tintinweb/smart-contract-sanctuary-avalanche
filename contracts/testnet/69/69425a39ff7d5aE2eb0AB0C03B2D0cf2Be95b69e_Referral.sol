/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Referral {
    address owner;


    constructor ()  
    {
        owner = msg.sender;
    }


    event onUpdateBuddy(address indexed player, address indexed referral);
    

    mapping(address => address) private buddies;
    mapping(address => address[]) private Treeofbuddies;

   

        function updateBuddy(address referral) public {

        require(referralOf(referral) != address(0) || referral == owner && referral != msg.sender ,"upline not found");
        require(referralOf(msg.sender) == address(0) ,"Already have a referral!");
        address upline = referral; 
        buddies[msg.sender] = referral;
        

        do {
               Treeofbuddies[msg.sender].push(upline);  // do while loop	
               upline = referralOf(upline);
               
            }

             while (upline != address(0));
        
        
        emit onUpdateBuddy(msg.sender, referral);
    }

    

    ///@dev Return the referral of a player
    function referralOf(address player) public view returns (address) {
        return buddies[player];
    }


        function referralOft(address player) public view returns (address [] memory) {
        return Treeofbuddies[player];
    }

}