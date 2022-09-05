/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

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
/////////////////////////////////////////////
contract DataFeeder {

    AggregatorV3Interface private constant AVAX = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD); // Chainlink Data Feeds

    function avaxPrice() public view returns(int256, uint) { // AVAX - Testnet(Fuji) - Chainlink Data Feed
        (,int price,,,) = AVAX.latestRoundData();

        return (price, AVAX.decimals());
    }

}