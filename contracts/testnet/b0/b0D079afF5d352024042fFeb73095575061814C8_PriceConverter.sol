// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol"; 

contract PriceConverter {
    AggregatorV3Interface internal priceFeed;
    
    constructor() {
        priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
    }

    //AVAX Decimals = 18

    function getCurrentPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        //18 = AVAX Decimals
        return price * int(10 ** (18 - uint(priceFeed.decimals())));
    }

    function getDecimals() public view returns (uint8) {
        uint8 decimals = priceFeed.decimals();
        return decimals;
    }

    function convertCurrency(uint256 usd_price) external view returns (uint256) {
        uint256 price = uint256(getCurrentPrice());
        // 10 ** 36 = 10 ** 18 * 10 ** 18
        // (usd_price * 10 ** 18 / price)
        return (usd_price * 10 ** 36 ) / price ;
    }
}