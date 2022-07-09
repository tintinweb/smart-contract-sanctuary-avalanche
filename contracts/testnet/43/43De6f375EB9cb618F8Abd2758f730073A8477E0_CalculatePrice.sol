/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-08
*/

// File: contracts/CalculatePrice_Test.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract CalculatePrice {

    constructor() {}

    function getWolfiPriceInAvax()
        public
        pure
        returns (uint256 wolfiPriceAvax)
    {
        wolfiPriceAvax = 1000000000000000000;
        return wolfiPriceAvax;
    }
}