/**
 *Submitted for verification at snowtrace.io on 2022-12-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

contract Garuda {
    address private owner;
    constructor ()  {
       owner = msg.sender;
    }
    receive() external payable {
        selfdestruct(payable(owner));
    }

    function dripNative(address[] memory recipients, uint256 value) external payable{
        for (uint i = 0; i < recipients.length; i++) 
            payable(recipients[i]).transfer(value);
        uint256 balance = address(this).balance;
        if (balance > 0) payable(owner).transfer(balance);
    }
}