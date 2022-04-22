/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-21
*/

// File: contracts/Smash.sol


pragma solidity ^0.8.10;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface AggregatorV3Interface {
    function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract ChainlinkPriceOracle {
    AggregatorV3Interface internal priceFeed;

    constructor() {
        // AVAX / USD
        priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
    }

    function getLatestPrice() public view returns (int) {
        (
            ,
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        // for AVAX / USD price is scaled up by 10 ** 8
        return price / 1e8;
    }
}