/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;


contract Smash {
    
    address owner;
    int256 public count;

    constructor(){
        owner = msg.sender;
        count = 0;
    }

    function increaseCount() public returns(int256){
        if(msg.sender == owner){
            count += 1; 
        }
        return count;
    }

    function decreaseCount() public returns(int256){
        if(msg.sender == owner){
            count -= 1; 
        }
        return count;
    }
}