// SPDX-License-Identifier: MIT
// ####     ####     ####               ##     ##  ##    ####    ######    ####     ####    ##  ##    ####
//##  ##   ##  ##   ##  ##             ####    ##  ##   ##  ##     ##       ##     ##  ##   ### ##   ##  ##
//##       ##  ##   ##                ##  ##   ##  ##   ##         ##       ##     ##  ##   ######   ##
// ####    ##  ##   ##                ######   ##  ##   ##         ##       ##     ##  ##   ######    ####
//    ##   ##  ##   ##                ##  ##   ##  ##   ##         ##       ##     ##  ##   ## ###       ##
//##  ##   ##  ##   ##  ##            ##  ##   ##  ##   ##  ##     ##       ##     ##  ##   ##  ##   ##  ##
// ####     ####     ####             ##  ##    ####     ####      ##      ####     ####    ##  ##    ####
// by UrkelLabs 2022 v0.3

pragma solidity ^0.8.13;

import "./SafeERC20.sol";

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

contract SOCAuction {
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

    IERC721 public nft;
    IERC20 SnakeOilBucks;
    uint public nftId;

    address payable public seller;
    uint public endAt;
    uint public duration;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bids;

    constructor(
        address _nft,
        uint _nftId,
        uint _startingBid,
        uint _days
    ) {
        nft = IERC721(_nft);
        nftId = _nftId;
        SnakeOilBucks = IERC20(0x396b961098756f421B628E3180bA9dC24589250c);
        duration = _days;

        seller = payable(msg.sender);
        highestBid = _startingBid * 1000000000000000000;
    }

    function start() external {
        require(!started, "Auction already started.");
        require(msg.sender == seller, "Only the seller can start the auction.");

        nft.transferFrom(msg.sender, address(this), nftId);
        started = true;
        endAt = block.timestamp + (duration * 1 days);

        emit Start();
    }

    function bid(uint256 bidAmount) external {
        bidAmount = bidAmount * 1000000000000000000;

        require(started, "Auction has not yet started.");
        require(block.timestamp < endAt, "Auction has already ended.");
        require(bidAmount <= SnakeOilBucks.balanceOf(msg.sender));
        require(bidAmount > highestBid, "You must bid more than the highest bid.");

        SnakeOilBucks.transferFrom(msg.sender, address(this), bidAmount);
        highestBidder = msg.sender;
        highestBid = bidAmount;

        if (highestBidder != address(0)) {
            bids[highestBidder] = highestBid;
        }

        emit Bid(msg.sender, bidAmount);
    }

    function withdraw() external {
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw from auction.");
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;

        SnakeOilBucks.approve(address(this), bal);
        SnakeOilBucks.transferFrom(address(this), msg.sender, bal);

        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(started, "Auction has not yet started.");
        require(block.timestamp >= endAt, "Auction has not reached end date.");
        require(!ended, "Auction has already ended.");
        require(msg.sender == seller, "Only the seller can end the auction.");

        ended = true;
        if (highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, nftId);
            SnakeOilBucks.approve(address(this), highestBid);
            SnakeOilBucks.transferFrom(address(this), msg.sender, highestBid);
        } else {
            nft.safeTransferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}