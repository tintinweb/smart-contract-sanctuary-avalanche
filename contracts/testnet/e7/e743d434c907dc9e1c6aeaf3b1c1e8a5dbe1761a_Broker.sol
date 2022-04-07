/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Broker {
    struct Booking {
        uint256 vmTypeId;
        address miner;
        uint256 pricePerSecond;
        bytes32 launchInfoIpfsHash;
        uint256 bookedTill;
    }
    struct VMOffer {
        address miner;
        uint256 pricePerSecond;
        uint256 initiationFee;
        uint256 machinesAvailable;
        uint256 vmTypeId;
    }

    address owneraddress;

    mapping(uint256 => VMOffer) vmOffers;
    uint256 lastVmOfferId = 0;

    mapping(uint256 => Booking) bookings;
    uint256 lastBookingId = 0;

    function addOffer(
        uint256 pricePerSecond,
        uint256 initiationFee,
        uint256 vmTypeId
    ) public {
        vmOffers[lastVmOfferId] = VMOffer(msg.sender, pricePerSecond, initiationFee, 0, vmTypeId);
        lastVmOfferId++;
    }

    function updateOffer(
        uint256 offerIndex,
        uint256 pricePerSecond,
        uint256 initiationFee,
        uint256 vmTypeId,
        uint256 machinesAvailable
    ) public {
        require(vmOffers[offerIndex].miner == msg.sender, "Only the owner can remove an offer");
        vmOffers[lastVmOfferId].pricePerSecond = pricePerSecond;
        vmOffers[lastVmOfferId].initiationFee = initiationFee;
        vmOffers[lastVmOfferId].machinesAvailable = machinesAvailable;
        vmOffers[lastVmOfferId].vmTypeId = vmTypeId;
    }

    function removeOffer(uint256 offerIndex) public {
        require(vmOffers[offerIndex].miner == msg.sender, "Only the owner can remove an offer");
        delete vmOffers[offerIndex];
    }

    function getOffersLength() public view returns (uint256) {
        return lastVmOfferId;
    }

    function getOffer(uint256 offerIndex)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        VMOffer memory offer = vmOffers[offerIndex];
        return (offer.miner, offer.pricePerSecond, offer.initiationFee, offer.machinesAvailable, offer.vmTypeId, offer.machinesAvailable);
    }

    function bookSlot(uint256 offerIndex, bytes32 launchInfo) public payable returns (uint256) {
        require(vmOffers[offerIndex].machinesAvailable > 0, "No machines available");
        require(msg.value == vmOffers[offerIndex].initiationFee, "Wrong initiation fee");
        Booking memory booking = Booking(
            vmOffers[offerIndex].vmTypeId,
            vmOffers[offerIndex].miner,
            vmOffers[offerIndex].pricePerSecond,
            launchInfo,
            block.timestamp + 10 * 60 * 1000
        );
        bookings[lastBookingId] = booking;
        lastBookingId++;
        return lastBookingId - 1;
    }

    function withdraw() public {
        require(owneraddress == msg.sender, "Only the owner can withdraw");
        payable(owneraddress).transfer(address(this).balance);
    }

    function extendBooking(uint256 bookingIndex) public payable {
        require(bookings[bookingIndex].bookedTill > block.timestamp, "Booking expired alreaduy");
        bookings[bookingIndex].bookedTill += (msg.value / bookings[bookingIndex].pricePerSecond) * 1000;
    }
}