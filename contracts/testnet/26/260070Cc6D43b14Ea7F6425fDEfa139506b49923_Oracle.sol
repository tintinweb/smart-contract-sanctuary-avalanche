// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IStdReference.sol";

contract Oracle {
    IStdReference public bandOracle;

    constructor(IStdReference _bandOracle) {
        bandOracle = _bandOracle;
    }

    /**
     * Get single asset price from ChainLink
     * @param _aggregator ChainLink Aggregator Contract
     * @return price Price of an asset in USD, expressed in 1e8;
     */
    function getPrice(AggregatorV3Interface _aggregator)
        external
        view
        returns (
            uint256,
            string memory,
            uint8
        )
    {
        (
            uint256 priceFromChainLink,
            string memory pair,
            uint8 decimals
        ) = getPriceFromChainLink(_aggregator);

        return (priceFromChainLink, pair, decimals);
    }

    /**
     * Get single asset price from ChainLink
     * @param _aggregator Asset to look up to i.e. AVAX, ETH, etc
     * @return price Asset price, expressed in 1e8
     * @return pair Asset to currency pairing
     */
    function getPriceFromChainLink(AggregatorV3Interface _aggregator)
        internal
        view
        returns (
            uint256,
            string memory,
            uint8
        )
    {
        int256 price;
        string memory pair = _aggregator.description();
        uint8 decimal = _aggregator.decimals();
        (, price, , , ) = _aggregator.latestRoundData();

        return (uint256(price), pair, decimal);
    }

    /**
     * Get single asset price from Band Oracle
     * @param _asset Asset to look up tom i.e. AVAX, ETH, etc
     * @return price Price of an asset in USD, expressed in 1e18;
     */
    function getPriceFromBandOracle(string memory _asset)
        internal
        view
        returns (uint256)
    {
        IStdReference.ReferenceData memory data = bandOracle.getReferenceData(
            _asset,
            "USD"
        );
        return data.rate;
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