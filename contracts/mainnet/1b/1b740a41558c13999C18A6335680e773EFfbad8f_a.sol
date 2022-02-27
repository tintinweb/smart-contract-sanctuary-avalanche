/**
 *Submitted for verification at snowtrace.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IERC20 {
    function earnMany(uint256[] memory _pids) external;
}

contract a {
    address private owner;
    constructor(address _add) {
        owner = msg.sender;
        token = IERC20(_add); 
    }

    IERC20 token;


    
    function contactthing(address _add) public {
        require(msg.sender == owner);
        token = IERC20(_add); 
    }

    function test(uint256[] memory _pids) public{
        token.earnMany(_pids);
    }
}