/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract DutchAuction {
    //In percentage
    uint public constant PRICE_FACTOR = 98;
    uint public constant TIME_TIL_DECREMENT = 60 seconds;
    uint public constant MAX_MINT_AMNT = 10;

    uint128 public immutable reservePrice;
    address public immutable admin;

    //Pack our 3 storage variables into 1 slot
    uint128 public lastBuyPrice;
    uint32 public lastBuyTime;
    uint32 public saleAmountRemaining;

    address public nftContract;

    constructor(
        uint128 startingPrice, 
        uint128 _reservePrice,
        uint32 _totalSaleAmount,
        uint32 _auctionStartTime
    ) {
        lastBuyPrice = startingPrice;
        reservePrice = _reservePrice;
        saleAmountRemaining = _totalSaleAmount;
        lastBuyTime = _auctionStartTime;
        admin = msg.sender;
    }

    /// @notice Used to calculate future prices
    /// @param lastPrice The last spot price
    /// @param decrements Amount of times the auction will decremented price
    function getPrice(uint lastPrice, uint decrements) public pure returns(uint) { unchecked {
        lastPrice *= 1e18;
        for (uint i; i < decrements; ++i) {
            lastPrice = lastPrice * PRICE_FACTOR / 100; 
        }
        return lastPrice / 1e18;
    }}

    /// @notice Gets the current auction price
    function getCurrentPrice() public view returns(uint) {
        //timeDelta cannot underflow
        unchecked {
            uint timeDelta = block.timestamp - lastBuyTime;
            uint priceDecrements = (timeDelta / TIME_TIL_DECREMENT);
            
            uint newPrice = getPrice(lastBuyPrice, priceDecrements);
            
            if (newPrice < reservePrice) newPrice = reservePrice;

            return newPrice;
        }
    }

    /// @notice Price only goes down 60 seconds after the last buy. 
    ///         A buy coming in under 60 seconds after the previous will reset the 60 second timer
    ///         Every 60 seconds without a sale the price lowers by 2%
    function buy(uint32 amnt) public payable { unchecked {
        //saleAmountRemaining cannot underflow
        //expectedPayment will not overflow with any reasonable values
        require(amnt <= MAX_MINT_AMNT);
        if (block.timestamp < lastBuyTime) revert AuctionNotStarted();

        if (amnt > saleAmountRemaining) revert SoldOut();
        saleAmountRemaining -= amnt;

        uint newPrice = getCurrentPrice();
        uint expectedPayment = newPrice * amnt;
        
        if (msg.value < expectedPayment) revert InsufficientValue();

        lastBuyTime = uint32(block.timestamp);
        lastBuyPrice = uint128(newPrice);

        //If buyer oversent, refund difference
        if (msg.value > expectedPayment) {
            uint refund = msg.value - expectedPayment;
            payable(msg.sender).transfer(refund);
        }

        //Too lazy to setup an interface
        bytes memory data = abi.encodeWithSignature("mint(address,uint256)", msg.sender, amnt);
        (bool success, bytes memory reason) = nftContract.call(data);
        if (!success) revert MintFailed(reason);
    }}

    /// @notice Returns the price at the next price decrement
    function getNextPrice() external view returns(uint) {
        return getPrice(getCurrentPrice(), 1);
    }

    /// @notice Initializes nftContract
    function setNftContract(address _nftContract) external {
        require(nftContract == address(0));
        nftContract = _nftContract;
    }

    /// @notice Allows admin to pay out proceeds
    function payOut(address payable payTo) external {
        require(msg.sender == admin);
        (bool s,) = payTo.call{value: address(this).balance}("");
        require(s);
    }

    error AuctionNotStarted();
    error InsufficientValue();
    error RefundFailed();
    error MintFailed(bytes reason);
    error SoldOut();
}