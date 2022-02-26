//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract WBChainlinkPricefeed {
    AggregatorV3Interface internal priceFeed;

    struct PriceFeed {
        uint80 roundID;
        int256 price;
        uint256 startedAt;
        uint256 timeStamp;
        uint80 answeredInRound;
    }

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x0A77230d17318075983913bC2145DB16C7366156
        );
    }

    function getLatestPrice()
        public
        view
        returns (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        )
    {
        (
            uint80 _roundID,
            int256 _price,
            uint256 _startedAt,
            uint256 _timeStamp,
            uint80 _answeredInRound
        ) = priceFeed.latestRoundData();

        return (_roundID, _price, _startedAt, _timeStamp, _answeredInRound);
    }
}

// SPDX-License-Identifier: MIT
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