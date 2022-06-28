/**
 *Submitted for verification at snowtrace.io on 2022-06-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Votes {
    struct Vote {
        bytes32 id;
        bytes32 initiative;
        uint points;
        uint timestamp;
    }

    struct LimitVoteMonthly {
        uint firstTimeInMonth;
        uint voteCountInMonth;
    }

    uint castVotePrice = 0.01 ether;
    uint limitVoteByMonth = 9998;
    address payable sender;
    mapping(address => Vote) public votes;
    mapping(address => LimitVoteMonthly) public limit;

    constructor() {
        sender = payable(msg.sender);
    }

    function daysOfDiference() private view returns(int) {
        if (limit[sender].firstTimeInMonth != 0) {
            return (int)(block.timestamp - limit[msg.sender].firstTimeInMonth) / 60 / 60 / 24;
        }
        return -1;
    }

    function castVote(bytes32 id, bytes32 initiative, uint points) public payable {
        require(msg.value >= castVotePrice, "Minimum value is 0.01");

        int days_count = daysOfDiference();
        LimitVoteMonthly memory count;
        
        if (days_count >= 0 && days_count <= 30) {
            require(limit[msg.sender].voteCountInMonth < limitVoteByMonth, "Monlty vote limit exceded");
            count = LimitVoteMonthly(limit[msg.sender].firstTimeInMonth, limit[msg.sender].voteCountInMonth + 1);
        } else {
            count = LimitVoteMonthly(block.timestamp, 1);
        }

        (bool success,) = sender.call{value: castVotePrice}("");
        require(success, "Failed to send money");

        votes[msg.sender] = Vote(id, initiative, points, block.timestamp);
        limit[msg.sender] = count;
    }
}