/**
 *Submitted for verification at snowtrace.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

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

// File: docs.chain.link/samples/PriceFeeds/PriceConverter.sol


pragma solidity ^0.8.7;


contract PriceConverter {
    AggregatorV3Interface internal priceFeed;
    
    /**
     * Network: Avalance C-Chain
     * Aggregator: AVAX/USD
     * Address: 0x0A77230d17318075983913bC2145DB16C7366156
     */

    constructor() {
        priceFeed = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function convertCurrency(int256 usd_price)
        public
        view
        returns(int256)
    {
        return usd_price * 10 ** 18 / getLatestPrice();
    }
}