// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

// EACAggregatorProxy is (AggregatorProxy is AggregatorV2V3Interface)
contract MockChainlinkBaseUSD {
    uint8 internal _decimals;
    AggregatorV2V3Interface internal _usdAggregator;
    uint8 internal _usdDecimals;

    constructor(
        uint8 decimals_,
        AggregatorV2V3Interface usdAggregator_,
        uint8 usdDecimals_
    ) {
        _decimals = decimals_;
        _usdAggregator = usdAggregator_;
        _usdDecimals = usdDecimals_;
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
        answer = int256(10**(_decimals + _usdDecimals)) / _price;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}