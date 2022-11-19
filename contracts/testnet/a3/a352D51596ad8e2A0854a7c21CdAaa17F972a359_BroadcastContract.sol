/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-19
*/

// File: Contracts/Broadcast.sol


pragma solidity ^0.8.17;


contract BroadcastContract {

    event Broadcast(address indexed _user, string _message);
    event ReplyBroadcast(address indexed _user, uint _messageId, string _message);

    function broadcast(string memory _message) external {
      emit Broadcast(msg.sender, _message);
    }

    function reply(string memory _message, uint _messageId) external {
      emit ReplyBroadcast(msg.sender, _messageId, _message);
    }
}