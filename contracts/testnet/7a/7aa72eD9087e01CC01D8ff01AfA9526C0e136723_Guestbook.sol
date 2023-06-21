// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

struct Message {
    address sender;
    uint256 sentTime;
    string message;
}

contract Guestbook {
    Message[] public messages;
    uint256 public messageCount;
    event MessageSend(address sender, uint256 sentTime, string content);

    function send(string memory message) public {
        messages.push(
            Message({
                sender: msg.sender,
                sentTime: block.timestamp,
                message: message
            })
        );
        messageCount += 1;
        emit MessageSend(msg.sender, block.timestamp, message);
    }
}