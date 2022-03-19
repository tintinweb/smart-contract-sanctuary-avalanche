/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-19
*/

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

// File: .deps/PriceFeed.sol


pragma solidity ^0.8.7;


contract PriceFeed {
    AggregatorV3Interface internal avaxUsdFeed;

    constructor() {
        avaxUsdFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
    }

    function getAvaxUsdPrice() public view returns (int) {
        (
        /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = avaxUsdFeed.latestRoundData();

        return price;
    }
}