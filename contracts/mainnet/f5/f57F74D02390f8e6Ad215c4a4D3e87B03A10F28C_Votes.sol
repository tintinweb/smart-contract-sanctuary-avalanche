/**
 *Submitted for verification at snowtrace.io on 2022-06-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Votes {
    struct Vote {
        bytes32 id;
        bytes32 issueId;
        uint points;
        uint timestamp;
    }

    mapping(address => Vote) public votes;

    event CastVote(address from);

    function castVote(bytes32 id, bytes32 issueId, uint points, uint timestamp) public {
        votes[msg.sender] = Vote(id, issueId, points, timestamp);
        emit CastVote(msg.sender);
    }
}