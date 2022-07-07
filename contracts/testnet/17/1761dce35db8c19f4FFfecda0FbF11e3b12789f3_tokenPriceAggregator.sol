/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
contract tokenPriceAggregator {
    int256 public price;
    function setPrice(int256 _price) external {
        price = _price;
    }
  function decimals() external pure returns (uint8){
    return 8;
  }
  function description() external pure returns (string memory){
    return "debug price";
  }
  function version() external pure returns (uint256){
    return 1;
  }

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
    ){
        return (_roundId,price,0,0,1);
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
    ){
        return (0,price,0,0,1);
    }
}