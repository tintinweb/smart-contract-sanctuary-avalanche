/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract KeyVal{
     string[] private key_val_pairs;
    
    function save(string memory _value) public{
            key_val_pairs.push(_value);
    }

    function get_pairs() public view returns(string [] memory){
            return key_val_pairs;
    }
}