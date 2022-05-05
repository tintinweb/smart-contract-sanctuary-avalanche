/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-04
*/

pragma solidity ^0.6.0;

contract MeetingRoom {

    enum Statuses { Vacant, Occupied}
    Statuses currentStatus;
    address payable public owner;

    event Occupy(address _occupant, uint _value);


    constructor() public {
        owner = msg.sender;
        currentStatus = Statuses.Vacant;
    }

    modifier onlyWhileVacant {
        require(currentStatus == Statuses.Vacant, "Meeting room is currently occupied.");
        _;
    }

    modifier costs(uint _amount) {
        require(msg.value >= _amount, "Not enough Ether to complete the booking.");
        _;
    }

    receive() external payable onlyWhileVacant costs(2 ether) {
        currentStatus = Statuses.Occupied;
        owner.transfer(msg.value);
        emit Occupy(msg.sender, msg.value);
    }

}