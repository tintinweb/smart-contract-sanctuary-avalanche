/**
 *Submitted for verification at snowtrace.io on 2022-06-01
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

contract TestVotingContract {
    mapping (address => uint256) ve;

    mapping (address => uint256) previousVote;

    function vote(address account) external returns (uint256) {
        uint256 veBalance = ve[account];
        previousVote[account] = veBalance;
        return veBalance;
    }

    function setVeBalance(uint256 amount) external {
        ve[msg.sender] = amount;
    }
}