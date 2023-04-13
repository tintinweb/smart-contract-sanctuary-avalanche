/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RentalContract {
    struct Room {
        string contractHash;
        string invoiceHash;
        uint256 rentAmountPerMonth;
        uint256 depositAmount;
        address payable owner;
        address payable renter;
        bool signed;
        bool forRent;
    }

    uint256 public roomId;
    mapping(uint256 => Room) public rooms;

    event SetRoomForRent(uint256 _roomId);
    event RentStarted(
        uint256 _roomId,
        address renter,
        string _contractHash,
        uint256 _rentAmount,
        uint256 _deposit
    );

    event PayForRent(uint256 _roomId, string _invoiceHash, uint256 invoiceFee);
    event RentEnded(uint256 _roomId, uint256 depositAmount);
    event EndRentWithPenalty(uint256 _roomId, uint256 penaltyFee);
    event ReOpen(
        uint256 _roomId,
        uint256 _rentAmountPerMonth,
        uint256 _depositAmount
    );
    event TransferBalance(
        address payable from,
        address payable to,
        uint256 amount,
        string action
    );
    event ExtendRentalRoom(uint256 _roomId, string _contractHash);

    function setRoomForRent(
        uint256 rentAmountPerMonth,
        uint256 depositAmount
    ) public {
        rooms[roomId] = Room(
            "",
            "contract",
            rentAmountPerMonth,
            depositAmount,
            payable(msg.sender),
            payable(address(0)),
            false,
            true
        );
        emit SetRoomForRent(roomId);
        roomId++;
    }

    function extendRentalRoom(
        uint256 _roomId,
        string memory _contractHash
    ) public {
        rooms[_roomId].contractHash = _contractHash;
        emit ExtendRentalRoom(_roomId, _contractHash);
    }

    function signByRenter(
        uint256 _roomId,
        string memory _contractHash
    ) public payable {
        require(
            msg.value >=
                rooms[_roomId].rentAmountPerMonth +
                    rooms[_roomId].depositAmount,
            "!balance"
        );
        rooms[_roomId].signed = true;
        rooms[_roomId].renter = payable(msg.sender);
        rooms[_roomId].contractHash = _contractHash;
        rooms[_roomId].owner.transfer(rooms[_roomId].rentAmountPerMonth);
        emit RentStarted(
            _roomId,
            msg.sender,
            rooms[_roomId].contractHash,
            rooms[_roomId].rentAmountPerMonth,
            rooms[_roomId].depositAmount
        );
    }

    function payForRentByMonth(
        uint256 _roomId,
        string memory _invoiceHash,
        uint256 invoiceFee
    ) public payable {
        require(rooms[_roomId].forRent, "!for rent");
        require(rooms[_roomId].renter == payable(msg.sender), "!renter");
        require(msg.value >= rooms[_roomId].rentAmountPerMonth, "!balance");
        rooms[_roomId].invoiceHash = _invoiceHash;
        rooms[_roomId].owner.transfer(
            rooms[_roomId].rentAmountPerMonth + invoiceFee
        );
        emit PayForRent(
            _roomId,
            _invoiceHash,
            invoiceFee + rooms[_roomId].rentAmountPerMonth
        );
    }

    function endRent(uint256 _roomId) public {
        require(rooms[_roomId].forRent, "!for rent");
        require(rooms[_roomId].owner == payable(msg.sender), "!owner");
        rooms[_roomId].renter.transfer(rooms[_roomId].depositAmount);
        emit RentEnded(_roomId, rooms[_roomId].depositAmount);
        rooms[_roomId] = Room(
            "",
            "",
            0,
            0,
            payable(rooms[_roomId].owner),
            payable(address(0)),
            false,
            false
        );
    }

    function endRentWithPenalty(
        uint256 _roomId,
        uint256 penaltyFee
    ) public payable {
        require(rooms[_roomId].forRent, "!for rent");
        require(rooms[_roomId].renter == payable(msg.sender), "!owner");
        rooms[_roomId].owner.transfer(
            rooms[_roomId].depositAmount + penaltyFee
        );
        emit RentEnded(_roomId, rooms[_roomId].depositAmount + penaltyFee);
        rooms[_roomId] = Room(
            "",
            "",
            0,
            0,
            payable(rooms[_roomId].owner),
            payable(address(0)),
            false,
            false
        );
    }

    function reOpenRoomForRent(
        uint256 _roomId,
        uint256 rentAmountPerMonth,
        uint256 depositAmount
    ) public {
        require(rooms[_roomId].owner == payable(msg.sender), "!owner");
        rooms[_roomId] = Room(
            "",
            "",
            rentAmountPerMonth,
            depositAmount,
            payable(msg.sender),
            payable(address(0)),
            false,
            true
        );
        emit ReOpen(_roomId, rentAmountPerMonth, depositAmount);
    }

    function transferBalance(
        address payable from,
        address payable to,
        uint256 amount,
        string memory action
    ) public payable {
        require(from != to, "!not transfer for selt");
        require(msg.value >= amount, "!not enough balance");
        to.transfer(amount);
        emit TransferBalance(from, to, amount, action);
    }
}