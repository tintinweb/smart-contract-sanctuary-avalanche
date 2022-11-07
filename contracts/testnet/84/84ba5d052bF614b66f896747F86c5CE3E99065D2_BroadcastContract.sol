/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-03
*/

// File: Contracts/Broadcast.sol


pragma solidity ^0.8.17;


contract BroadcastContract {

    event Broadcast(address indexed _user, string _message, uint _timestamp);

    function broadcast(string memory _message) external {
        emit Broadcast(msg.sender, _message, block.timestamp);
    }
}