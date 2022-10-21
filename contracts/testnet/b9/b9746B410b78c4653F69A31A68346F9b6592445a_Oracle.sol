// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IStdReference.sol";

contract Oracle {
    AggregatorV3Interface public chainLinkAggregator;
    IStdReference public bandOracle;

    // struct ChainLinkPriceFeed {
    //     AggregatorV3Interface oracle;
    //     string token;
    // }

    // mapping(address => ChainLinkPriceFeed) public chainLinkPriceFeeds;

    constructor(
        AggregatorV3Interface _chainLinkAggregator,
        IStdReference _bandOracle
    ) {
        chainLinkAggregator = _chainLinkAggregator;
        bandOracle = _bandOracle;
    }

    function getPriceFromChainLink() external view returns (int256) {
        int256 price;

        (, price, , , ) = chainLinkAggregator.latestRoundData();

        return price;
    }

    function getPriceFromTellor(string memory _assets)
        external
        view
        returns (uint256)
    {
        IStdReference.ReferenceData memory data = bandOracle.getReferenceData(
            _assets,
            "USD"
        );
        return data.rate;
    }

    function getMultiplePrices(string[] memory _assets, string[] memory _quotes)
        public
        view
        returns (uint256[] memory)
    {
        require(
            _assets.length == _quotes.length,
            "Input length for assets and quotes arrays do not match"
        );

        IStdReference.ReferenceData[] memory data = bandOracle
            .getReferenceDataBulk(_assets, _quotes);

        uint256[] memory prices = new uint256[](_assets.length);

        for (uint256 i = 0; i < data.length; i++) {
            prices[i] = data[i].rate;
        }

        return prices;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStdReference {
    // https://docs.bandchain.org/band-standard-dataset/using-band-dataset/using-band-dataset-evm.html
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(
        string[] memory _bases,
        string[] memory _quotes
    ) external view returns (ReferenceData[] memory);
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