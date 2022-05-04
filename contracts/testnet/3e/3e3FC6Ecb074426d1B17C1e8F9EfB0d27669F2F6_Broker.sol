/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Broker {
    struct Booking {
        uint256 index;
        uint256 vmTypeId;
        address miner;
        address client;
        uint256 pricePerSecond;
        string launchInfoIpfsHash;
        uint256 bookedTill;
    }
    struct VMOffer {
        uint256 index;
        address miner;
        uint256 pricePerSecond;
        uint256 initiationFee;
        uint256 machinesAvailable;
        uint256 vmTypeId;
    }

    uint256 public constant version = 1;
    address ownerAddress;

    mapping(uint256 => VMOffer) vmOffers;
    uint256 nextVmOfferId = 0;

    mapping(uint256 => Booking) bookings;
    uint256 nextBookingId = 0;

    function addOffer(
        uint256 pricePerSecond,
        uint256 initiationFee,
        uint256 vmTypeId,
        uint256 machinesAvailable
    ) public returns (uint256) {
        vmOffers[nextVmOfferId] = VMOffer(
            nextVmOfferId,
            msg.sender,
            pricePerSecond,
            initiationFee,
            machinesAvailable,
            vmTypeId
        );
        nextVmOfferId++;
        return nextVmOfferId - 1;
    }

    function updateOffer(
        uint256 offerIndex,
        uint256 pricePerSecond,
        uint256 initiationFee,
        uint256 vmTypeId,
        uint256 machinesAvailable
    ) public {
        require(
            vmOffers[offerIndex].miner == msg.sender,
            "Only the owner can remove an offer"
        );
        vmOffers[offerIndex].pricePerSecond = pricePerSecond;
        vmOffers[offerIndex].initiationFee = initiationFee;
        vmOffers[offerIndex].machinesAvailable = machinesAvailable;
        vmOffers[offerIndex].vmTypeId = vmTypeId;
    }

    function removeOffer(uint256 offerIndex) public {
        require(
            vmOffers[offerIndex].miner == msg.sender,
            "Only the owner can remove an offer"
        );
        delete vmOffers[offerIndex];
    }

    function getOffer(uint256 offerIndex)
        public
        view
        returns (
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        VMOffer memory offer = vmOffers[offerIndex];
        return (
            offer.index,
            offer.miner,
            offer.pricePerSecond,
            offer.initiationFee,
            offer.machinesAvailable,
            offer.vmTypeId,
            offer.machinesAvailable
        );
    }

    function bookVM(uint256 offerIndex, string memory launchInfo)
        public
        payable
        returns (uint256)
    {
        require(
            vmOffers[offerIndex].machinesAvailable > 0,
            "No machines available"
        );
        require(
            msg.value == vmOffers[offerIndex].initiationFee,
            "Wrong initiation fee"
        );
        Booking memory booking = Booking(
            nextBookingId,
            vmOffers[offerIndex].vmTypeId,
            vmOffers[offerIndex].miner,
            msg.sender,
            vmOffers[offerIndex].pricePerSecond,
            launchInfo,
            block.timestamp + 10 * 60
        );
        bookings[nextBookingId] = booking;
        nextBookingId++;
        return nextBookingId - 1;
    }

    function withdraw() public {
        require(ownerAddress == msg.sender, "Only the owner can withdraw");
        payable(ownerAddress).transfer(address(this).balance);
    }

    function extendBooking(uint256 bookingIndex) public payable {
        require(
            bookings[bookingIndex].bookedTill > block.timestamp,
            "Booking expired alreaduy"
        );
        bookings[bookingIndex].bookedTill +=
            (msg.value / bookings[bookingIndex].pricePerSecond) *
            1000;
    }

    // function getBooking(uint256 bookingIndex)
    //     public
    //     view
    //     returns (Booking memory booking)
    // {
    //     booking = bookings[bookingIndex];
    // }

    function findBookingsByClient(address owner)
        public
        view
        returns (Booking[] memory filteredBookings)
    {
        Booking[] memory bookingsTemp = new Booking[](nextBookingId);
        uint256 count;
        for (uint256 i = 0; i < nextBookingId; i++) {
            if (
                bookings[i].client == owner &&
                bookings[i].bookedTill > block.timestamp
            ) {
                bookingsTemp[count] = bookings[i];
                count += 1;
            }
        }

        filteredBookings = new Booking[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredBookings[i] = bookingsTemp[i];
        }
    }

    function getAvailableOffers(uint256 vmTypeId)
        public
        view
        returns (VMOffer[] memory filteredOffers)
    {
        VMOffer[] memory offersTemp = new VMOffer[](nextVmOfferId);
        uint256 count;
        for (uint256 i = 0; i < nextVmOfferId; i++) {
            if (
                vmOffers[i].vmTypeId == vmTypeId &&
                vmOffers[i].machinesAvailable > 0
            ) {
                offersTemp[count] = vmOffers[i];
                count += 1;
            }
        }

        filteredOffers = new VMOffer[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredOffers[i] = offersTemp[i];
        }
    }

    function getMinersOffers(address miner)
        public
        view
        returns (VMOffer[] memory filteredOffers)
    {
        VMOffer[] memory offersTemp = new VMOffer[](nextVmOfferId);
        uint256 count;
        for (uint256 i = 0; i < nextVmOfferId; i++) {
            if (vmOffers[i].miner == miner) {
                offersTemp[count] = vmOffers[i];
                count += 1;
            }
        }

        filteredOffers = new VMOffer[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredOffers[i] = offersTemp[i];
        }
    }

    function findBookingsForMiner(address miner)
        public
        view
        returns (Booking[] memory filteredBookings)
    {
        Booking[] memory bookingsTemp = new Booking[](nextBookingId);
        uint256 count;
        for (uint256 i = 0; i < nextBookingId; i++) {
            if (
                bookings[i].miner == miner &&
                bookings[i].bookedTill > block.timestamp
            ) {
                bookingsTemp[count] = bookings[i];
                count += 1;
            }
        }

        filteredBookings = new Booking[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredBookings[i] = bookingsTemp[i];
        }
    }

    function getBookingsLength() public view returns (uint256) {
        return nextBookingId;
    }
}