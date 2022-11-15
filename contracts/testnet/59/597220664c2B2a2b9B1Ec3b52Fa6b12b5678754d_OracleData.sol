// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./AggregatorV3Interface.sol";

contract OracleData {
  AggregatorV3Interface internal priceFeed;

  int256 storedPrice;

  constructor() {
    priceFeed = AggregatorV3Interface(
      0x7b219F57a8e9C7303204Af681e9fA69d17ef626f
    );
    storedPrice = getLatestPrice();
  }

  function getLatestPrice() public view returns (int256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return price;
  }

  function hasPriceIncreased() external view returns (bool) {
    int256 currentPrice = getLatestPrice();
    return currentPrice > storedPrice;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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