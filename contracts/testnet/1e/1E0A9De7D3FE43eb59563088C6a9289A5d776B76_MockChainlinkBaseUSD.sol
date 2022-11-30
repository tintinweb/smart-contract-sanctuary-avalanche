// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// EACAggregatorProxy is (AggregatorProxy is AggregatorV2V3Interface)
contract MockChainlinkBaseUSD {
    uint8 public _decimals;
    AggregatorV3Interface public _usdAggregator;
    uint8 public _usdDecimals;

    constructor(
        uint8 decimals_,
        AggregatorV3Interface usdAggregator_
    ) {
        _decimals = decimals_;
        _usdAggregator = usdAggregator_;
    }

    // V3
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function usdDecimals() external view returns (uint8) {
        return _usdDecimals;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        int256 _price;
        (
            roundId,
            _price,
            startedAt,
            updatedAt,
            answeredInRound
        ) = _usdAggregator.latestRoundData();
        answer = int256(10**(_decimals + _usdAggregator.decimals())) / _price;
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