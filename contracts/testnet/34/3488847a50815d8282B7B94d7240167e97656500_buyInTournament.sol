/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-31
*/

// SPDX-License-Identifier: MT
pragma solidity ^0.8.13;

contract buyInTournament {
    mapping(address => bool) public isRegistered;
    uint public cost = 0.01 ether;

    uint public prizePool;

    function register() external payable returns(bool) {
        require(msg.value >= cost);
        return isRegistered[msg.sender] = true;
    }

    function getPrizePool() public returns(uint){
        prizePool = address(this).balance;
        return prizePool;
    }
}