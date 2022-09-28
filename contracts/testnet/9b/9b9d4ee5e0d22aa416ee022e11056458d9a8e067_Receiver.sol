/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-27
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Receiver{

    uint256 public balance = 0; 

    receive() external payable {
        // React to receiving ether
        balance += msg.value;
    }

    
}