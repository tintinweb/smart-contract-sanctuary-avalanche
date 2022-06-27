/**
 *Submitted for verification at snowtrace.io on 2022-06-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DgkoQral{

    address payable public owner;
    uint public constant duration = 365 days;
    uint public immutable end;
 
    
    constructor(){
        owner = payable(msg.sender);
        end = block.timestamp + duration;
    }

    receive() external payable{ }

    modifier ownerOnly(){
        require(msg.sender == owner,"Not owner");
        _;
    }

    function yeniQral(address _newOwner) external ownerOnly{
        require(_newOwner != address(0),"Invalid address");
        owner = payable(_newOwner);
    }

    function paraVerrrr(uint _amount)external ownerOnly{
        require(block.timestamp >= end, "Not yet");
        payable(msg.sender).transfer(_amount);
    }

    function parayiGosterrrr()external view returns(uint){
        return address(this).balance;
    }
}