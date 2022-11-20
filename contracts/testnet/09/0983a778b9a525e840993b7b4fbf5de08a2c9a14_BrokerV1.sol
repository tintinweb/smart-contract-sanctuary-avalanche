/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//TODO: optimize uint types to use less gas

contract BrokerV1 {
    struct Booking {
        uint64 index;
        uint64 vmTypeId;
        address miner;
        address user;
        uint64 pricePerSecond;
        uint256 bookedAt;
        uint256 lastPayment;
        uint64 offerIndex;
    }

    struct Offer {
        uint64 index;
        address miner;
        uint64 pricePerSecond;
        uint64 machinesAvailable;
        uint64 vmTypeId;
    }

    mapping(uint64 => Offer) offers;
    uint64 nextVmOfferId;

    mapping(uint64 => Booking) bookings;
    uint64 nextBookingId;

    mapping(address => uint256) coinBalance;
    mapping(address => uint64) userTotalPps;

    mapping(address => bytes32) minerUrls;

    IERC20 coin;

    address communityContract;
    uint64 communityFee;

    uint64 public constant SECONDS_IN_WEEK = 604800;

    event Payment(address indexed user, address indexed miner, uint256 amount);

    event Complaint(
        address indexed user,
        address indexed miner,
        uint8 indexed reason
    );

    //01_miner_url

    function SetMinerUrl(bytes32 url) public {
        minerUrls[msg.sender] = url;
    }

    function GetMinerUrl(address _user) public view returns (bytes32) {
        return minerUrls[_user];
    }

    //02_offers

    function AddOffer(
        uint64 pricePerSecond,
        uint64 vmTypeId,
        uint64 machinesAvailable
    ) public returns (uint64) {
        offers[nextVmOfferId] = Offer(
            nextVmOfferId,
            msg.sender,
            pricePerSecond,
            machinesAvailable,
            vmTypeId
        );
        nextVmOfferId++;
        return nextVmOfferId - 1;
    }

    function UpdateOffer(
        uint64 offerIndex,
        uint64 machinesAvailable,
        uint64 pps
    ) public {
        require(
            offers[offerIndex].miner == msg.sender,
            "Only the owner can update an offer"
        );
        offers[offerIndex].machinesAvailable = machinesAvailable;
        offers[offerIndex].pricePerSecond = pps;
    }

    function RemoveOffer(uint64 offerIndex) public {
        require(
            offers[offerIndex].miner == msg.sender,
            "Only the owner can remove an offer"
        );
        delete offers[offerIndex];
    }

    function GetMinersOffers(address miner)
        public
        view
        returns (Offer[] memory filteredOffers)
    {
        Offer[] memory offersTemp = new Offer[](nextVmOfferId);
        uint64 count;
        for (uint64 i = 0; i < nextVmOfferId; i++) {
            if (offers[i].miner == miner) {
                offersTemp[count] = offers[i];
                count += 1;
            }
        }

        filteredOffers = new Offer[](count);
        for (uint64 i = 0; i < count; i++) {
            filteredOffers[i] = offersTemp[i];
        }
    }

    function GetAvailableOffers()
        public
        view
        returns (Offer[] memory filteredOffers)
    {
        Offer[] memory offersTemp = new Offer[](nextVmOfferId);
        uint64 count;
        for (uint64 i = 0; i < nextVmOfferId; i++) {
            if (offers[i].machinesAvailable > 0) {
                offersTemp[count] = offers[i];
                count += 1;
            }
        }

        filteredOffers = new Offer[](count);
        for (uint64 i = 0; i < count; i++) {
            filteredOffers[i] = offersTemp[i];
        }
    }

    //03_coin

    function SetCoinAddress(IERC20 newCoinAddress) public {
        require(
            msg.sender == communityContract,
            "only community contract can set coin"
        );

        coin = newCoinAddress;
    }

    function DepositCoin(uint256 numTokens) public returns (bool) {
        require(
            coin.transferFrom(msg.sender, address(this), numTokens),
            "Failed to transfer tokens"
        );

        coinBalance[msg.sender] = coinBalance[msg.sender] + numTokens;
        return true;
    }

    function GetLockedCoinBalance(address user) private view returns (uint256) {
        return userTotalPps[user] * SECONDS_IN_WEEK;
    }

    function WithdrawCoin(uint256 amt) public returns (bool) {
        uint256 freeBalance = coinBalance[msg.sender] -
            GetLockedCoinBalance(msg.sender);

        require(freeBalance >= amt, "Not enough balance to withdraw");

        require(coin.transfer(msg.sender, amt), "ERC20 transfer failed");

        coinBalance[msg.sender] -= amt;
        return true;
    }

    function GetCoinBalance(address user)
        public
        view
        returns (uint256, uint256)
    {
        uint256 locked = GetLockedCoinBalance(user);
        return (coinBalance[user] - locked, locked);
    }

    //04_bookings

    function Book(uint64 offerIndex) public returns (uint64) {
        require(
            offers[offerIndex].machinesAvailable > 0,
            "No machines available"
        );

        uint256 willBeLocked = GetLockedCoinBalance(msg.sender) +
            offers[offerIndex].pricePerSecond *
            SECONDS_IN_WEEK;

        require(
            willBeLocked <= coinBalance[msg.sender],
            "You don't have enough balance to pay for this and all other Bookings for 7 days "
        );

        Booking memory booking = Booking(
            nextBookingId,
            offers[offerIndex].vmTypeId,
            offers[offerIndex].miner,
            msg.sender,
            offers[offerIndex].pricePerSecond,
            block.timestamp,
            block.timestamp,
            offerIndex
        );
        bookings[nextBookingId] = booking;
        nextBookingId++;

        userTotalPps[msg.sender] += offers[offerIndex].pricePerSecond;

        offers[offerIndex].machinesAvailable -= 1;

        return nextBookingId - 1;
    }

    function _executeBookingDelete(uint64 bookingId) private {
        offers[bookings[bookingId].offerIndex].machinesAvailable += 1;
        userTotalPps[bookings[bookingId].user] -= bookings[bookingId]
            .pricePerSecond;
        delete bookings[bookingId];
    }

    function Terminate(uint64 bookingId, uint8 reason) public {
        require(
            bookings[bookingId].user == msg.sender,
            "Only the user can stop a VM"
        );

        if (reason != 0) {
            emit Complaint(
                bookings[bookingId].user,
                bookings[bookingId].miner,
                reason
            );
        }

        _executeClaimPayment(bookingId);
        _executeBookingDelete(bookingId);
    }

    function ClaimPayment(uint64 bookingId) public {
        require(
            bookings[bookingId].miner == msg.sender,
            "Only the miner can claim a payment"
        );
        bool enoughMoney = _executeClaimPayment(bookingId);
        if (!enoughMoney) {
            _executeBookingDelete(bookingId);
        }
    }

    function _executeClaimPayment(uint64 bookingId) private returns (bool) {
        bool enoughMoney = true;
        uint256 timeUsed = block.timestamp - bookings[bookingId].lastPayment;

        uint256 totalPayout = timeUsed * bookings[bookingId].pricePerSecond;

        if (coinBalance[bookings[bookingId].user] < totalPayout) {
            totalPayout = coinBalance[bookings[bookingId].user];
            enoughMoney = false;
        }

        uint256 communityPayout = (totalPayout * communityFee) / (100 * 100);
        uint256 minerPayout = totalPayout - communityPayout;

        bookings[bookingId].lastPayment = block.timestamp;

        coinBalance[communityContract] += communityPayout;
        coinBalance[bookings[bookingId].miner] += minerPayout;
        coinBalance[bookings[bookingId].user] -= totalPayout;

        emit Payment(
            bookings[bookingId].user,
            bookings[bookingId].miner,
            minerPayout
        );
        return enoughMoney;
    }

    function FindBookingsByUser(address _owner)
        public
        view
        returns (Booking[] memory filteredBookings)
    {
        Booking[] memory bookingsTemp = new Booking[](nextBookingId);
        uint64 count;
        for (uint64 i = 0; i < nextBookingId; i++) {
            if (bookings[i].user == _owner) {
                bookingsTemp[count] = bookings[i];
                count += 1;
            }
        }

        filteredBookings = new Booking[](count);
        for (uint64 i = 0; i < count; i++) {
            filteredBookings[i] = bookingsTemp[i];
        }
    }

    function FindBookingsByMiner(address _miner)
        public
        view
        returns (Booking[] memory filteredBookings)
    {
        Booking[] memory bookingsTemp = new Booking[](nextBookingId);
        uint64 count;
        for (uint64 i = 0; i < nextBookingId; i++) {
            if (bookings[i].miner == _miner) {
                bookingsTemp[count] = bookings[i];
                count += 1;
            }
        }

        filteredBookings = new Booking[](count);
        for (uint64 i = 0; i < count; i++) {
            filteredBookings[i] = bookingsTemp[i];
        }
    }

    function GetBooking(uint64 index)
        public
        view
        returns (Booking memory booking)
    {
        booking = bookings[index];
    }

    //05_community

    function SetCommunityContract(address newCommunityAddress) public {
        require(
            msg.sender == communityContract,
            "only community contract can set new community contract"
        );
        communityContract = newCommunityAddress;
    }

    function SetCommunityFee(uint64 fee) public returns (bool) {
        require(
            fee < 2500,
            "community fee should be in range of 0 (0%) to 2500 (25%)"
        );
        require(
            msg.sender == communityContract,
            "only community contract can set community fee"
        );

        communityFee = fee;
        return false;
    }
}