// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainLinkOracle {
  constructor() {}

  /**
    * Get single asset price from ChainLink
    * @param _aggregator ChainLink agggregator contract
    * @return price Asset price; expressed in 1e18
    */
  function getPrice(AggregatorV3Interface _aggregator)
    external
    view
    returns (uint256)
  {
    uint256 price;
    uint256 decimals;

    (, int256 answer, , , ) = _aggregator.latestRoundData();
    decimals = uint256(_aggregator.decimals());

    price = uint256(answer) * 1e18 / (10 ** decimals);

    return price;
  }
}

// SPDX-License-Identifier: MIT
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