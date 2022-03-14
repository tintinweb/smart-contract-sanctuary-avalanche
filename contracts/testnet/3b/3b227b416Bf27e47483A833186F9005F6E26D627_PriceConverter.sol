/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
pragma solidity ^0.8.7;

//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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

contract PriceConverter {
    AggregatorV3Interface internal priceFeed;
    
    /**
     * Network: Avalance C-Chain
     * Aggregator: AVAX/USD
     * Address: 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD
     */

    constructor() {
        priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
    }

    /**
     * Returns the latest price
     */
    function getCurrentPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        //Real Price = price / 10^8;
        return price;
    }

    function convertCurrency(int256 usd_price)
        public
        view
        returns(int256)
    {
        //Real USD Price = usd_price / 10^10;
        return usd_price * 10 ** 18 / getCurrentPrice(); 
    }
}