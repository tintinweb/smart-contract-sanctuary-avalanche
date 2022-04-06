/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    struct Slot {
        address miner;
        uint256 bookedTill;
        uint256 pricePerSecond;
        uint256 initiationFee;
        bytes32 launchInfoIpfsHash;
        bool isRemoved;
    }

    event SlotUpdate(uint256 index);
    Slot[] slots;

    function addSlot(uint256 pricePerSecond, uint256 initiationFee) public {
        slots.push(
            Slot(msg.sender, 0, pricePerSecond, initiationFee, "", false)
        );
        emit SlotUpdate(slots.length - 1);
    }

    function removeSlot(uint256 index) public {
        require(slots[index].isRemoved == false, "Already removed");
        slots[index].isRemoved = true;
        emit SlotUpdate(index);
    }

    function getSlotsLength() public view returns (uint256) {
        return slots.length;
    }

    function getSlot(uint256 index)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            bytes32,
            bool
        )
    {
        Slot memory slot = slots[index];
        return (
            slot.miner,
            slot.bookedTill,
            slot.pricePerSecond,
            slot.initiationFee,
            slot.launchInfoIpfsHash,
            slot.isRemoved
        );
    }

    function bookSlot(uint256 index, bytes32 launchInfo) public payable {
        require(slots[index].isRemoved == false, "This slot is removed");
        require(
            slots[index].bookedTill < block.timestamp,
            "Slot is already booked"
        );
        require(
            msg.value == slots[index].initiationFee,
            "Wrong initiation fee"
        );
        slots[index].launchInfoIpfsHash = launchInfo;

        bool sent = payable(slots[index].miner).send(msg.value);
        require(sent, "Failed to send Ether");
        emit SlotUpdate(index);
    }

    function extendBooking(uint256 index) public payable {
        require(slots[index].isRemoved == false, "This slot is removed");
        require(
            slots[index].bookedTill > block.timestamp,
            "Slot is not booked"
        );
        slots[index].bookedTill +=
            slots[index].bookedTill +
            (1000 * msg.value) /
            slots[index].pricePerSecond;

        bool sent = payable(slots[index].miner).send(msg.value);
        require(sent, "Failed to send Ether");
        emit SlotUpdate(index);
    }
}