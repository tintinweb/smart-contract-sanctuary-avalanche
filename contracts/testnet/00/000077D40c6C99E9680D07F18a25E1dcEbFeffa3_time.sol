/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract time  {
    uint256 public startDay;
    constructor(){
        startDay = block.timestamp/86400;
    }
    function getTime() public view returns(uint256){
        return block.timestamp;
    }
    function getDay() public view returns(uint256){
        return block.timestamp/86400;
    }
    function today() public view returns(uint256){
        return getDay() - startDay + 1;
    }
}