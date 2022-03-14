// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol";
import "./SafeMath.sol";   

contract PriceConverter {
    AggregatorV3Interface internal priceFeed;
    
  using SafeMath for uint256;

  constructor() {
    priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
  }

    function getCurrentPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        //Real Price = price / 10^8;
        return price;
    }

    function getDecimals() public view returns (uint8) {
        uint8 decimals = priceFeed.decimals();
        return decimals;
    }

    function convertCurrency(uint256 usd_price) external view returns (uint256) {
        uint256 price = uint256(getCurrentPrice());
        uint256 amount = usd_price.mul(10 ** uint256(getDecimals())) * (10 ** 8);
        //Real Answer = Answer / 10^8;
        return amount.div(price);
    }
}