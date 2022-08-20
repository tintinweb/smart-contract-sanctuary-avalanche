/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Message {
    address owner = 0xe5f986237e28C22e1fcf984fB84cE33f37f1656c;
    struct Messages {
        uint256 Id;
        string message;
        string attachment;
        string[] allSender;
        string[] allReciver;
        string sender;
        string reciver;
        bool isSpam;
        uint256 timeStamp;
    }

    Messages[] internal messages;

    event MessageStored(uint256 id, bool isStored);

    function storeMessage(
        string memory message,
        string memory attachment,
        string memory sender,
        string memory reciver,
        bool isSpam
    ) external {
        require(owner == msg.sender, "only owner can call this function ");
        require(bytes(message).length > 0, "Message is empty ");
        require(bytes(sender).length > 0, "sender is empty ");
        require(bytes(reciver).length > 0, "reciver is empty ");
        Messages memory tempmsg;
        tempmsg.Id = messages.length;
        tempmsg.message = message;
        tempmsg.attachment = attachment;
        tempmsg.sender = sender;
        tempmsg.reciver = reciver;
        tempmsg.isSpam = isSpam;
        tempmsg.timeStamp = block.timestamp;
        messages.push(tempmsg);
        messages[messages.length - 1].allSender.push(sender);
        messages[messages.length - 1].allReciver.push(reciver);
        emit MessageStored(messages.length, true);
    }

    function forwordMessage(
        string memory sender,
        string memory reciver,
        uint256 id
    ) external {
        require(owner == msg.sender, "only owner can call this function ");
        messages[id].sender = sender;
        messages[id].reciver = reciver;
        messages[id].allSender.push(sender);
        messages[id].allReciver.push(reciver);
        if (messages[id].allSender.length == 10) {
            messages[id].isSpam = true;
        }
    }

    function getAllSenders(uint256 id)
        external
        view
        returns (string[] memory allSender, uint256 totalSender)
    {
        string[] memory _messages = new string[](messages[id].allSender.length);
        for (uint256 i = 0; i < messages[id].allSender.length; i++) {
            _messages[i] = messages[id].allSender[i];
        }
        return (_messages, messages[id].allSender.length);
    }

    function getTotalLength() external view returns (uint256) {
        return messages.length;
    }

    function getMessageById(uint256 _id)
        external
        view
        returns (
            uint256 Id,
            string memory message,
            string memory attachment,
            string memory sender,
            string memory reciver,
            bool isSpam,
            uint256 timeStamp
        )
    {
        uint256 _Id = messages[_id].Id;
        string memory _message = messages[_id].message;
        string memory _attachment = messages[_id].attachment;
        string memory _sender = messages[_id].sender;
        string memory _reciver = messages[_id].reciver;
        bool _isSpam = messages[_id].isSpam;
        uint256 _timeStamp = messages[_id].timeStamp;
        return (
            _Id,
            _message,
            _attachment,
            _sender,
            _reciver,
            _isSpam,
            _timeStamp
        );
    }
}