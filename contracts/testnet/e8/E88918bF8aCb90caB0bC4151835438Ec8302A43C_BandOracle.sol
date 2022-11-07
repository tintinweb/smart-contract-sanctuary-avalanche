// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IStdReference.sol";

contract BandOracle {
  IStdReference public bandOracle;

  constructor(IStdReference _bandOracle) {
    bandOracle = _bandOracle;
  }

  /**
    * Get single asset price from Band Oracle
    * @param _asset    Symbol of asset; i.e. AVAX, ETH, etc
    * @param _quote   Symbol of price quote; i.e. USD
    * @return _price    Asset price in quote, expressed in 1e18
  */
  function getPrice(string memory _asset, string memory _quote)
    external
    view
    returns (uint256 _price)
  {
    uint256 price;

    IStdReference.ReferenceData memory data = bandOracle.getReferenceData(
      _asset,
      _quote
    );
    price = data.rate;

    return price;
  }

  /**
    * Get multiple assets prices from Band Oracle
    * @param _assets    Array of symbols of crypto
    * @param _quotes    Array of symbol of price quote strings
    * @return prices    Assets price
  */
  function getMultiplePrices(
    string[] memory _assets,
    string[] memory _quotes
  ) external view returns (uint256[] memory) {
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