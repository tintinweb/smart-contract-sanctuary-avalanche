// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "./2_Owner.sol";


/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract G4_Jackpot is Owner {

    uint public receiverPercentage = 51;
    bool public open = true;

    mapping (address => uint) public jackpotReceiversVotes;
    uint public totalVotes;

    struct Sender {
        bytes32 senderName;
        uint amount;
    }
    mapping(address => Sender) private _jackpotSenders;
    address[] public jackpotSenderAddresses;

    function countSenders() public view returns(uint) {
        return jackpotSenderAddresses.length;
    }

    function seeSenderName(address senderAddress) isOwner public view returns(bytes32) {
        return _jackpotSenders[senderAddress].senderName;
    }

    function seeSenderAmount(address senderAddress) public view returns(uint) {
        return _jackpotSenders[senderAddress].amount;
    }

    function participate(bytes32 senderName) public payable {
        require(open, "The jackpot is closed");
        require(msg.value > 0, "You must send some money");

        if (_jackpotSenders[msg.sender].amount == 0) {
            _jackpotSenders[msg.sender].amount = 0;
            jackpotSenderAddresses.push(msg.sender);
        }
        _jackpotSenders[msg.sender].amount += msg.value;
        _jackpotSenders[msg.sender].senderName = senderName;
    }

    function close() isOwner public {
        open = false;
    }
}