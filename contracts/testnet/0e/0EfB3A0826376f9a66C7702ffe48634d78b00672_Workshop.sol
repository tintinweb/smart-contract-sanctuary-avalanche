/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-20
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

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

// File: Workshop.sol


pragma solidity ^0.8.7;


contract Workshop {
    uint256 public counter = 0;

    function getPrice(address priceFeedAgg) public view returns(int256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAgg);
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    // each month
    function payout() public {
        // transfer funds to whoever

        counter++;
    }
}