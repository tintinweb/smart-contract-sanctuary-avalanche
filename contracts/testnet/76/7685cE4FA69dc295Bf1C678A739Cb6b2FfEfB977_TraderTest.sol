/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Quote {
    address[] route;
    address[] pairs;
    uint256[] binSteps;
    uint256[] amounts;
    uint256[] virtualAmountsWithoutSlippage;
    uint256[] fees;
}

interface ILBQuoter {
    function findBestPathFromAmountIn(
        address[] calldata _route,
        uint256 _amountIn
    ) external view returns (Quote memory quote);
}

contract TraderTest {

    function getQuote(address token0, address token1, uint256 _amountIn) external view returns (Quote memory quote) {
        address[] memory _route;
        _route[0] = token0;
        _route[1] = token1;

        ILBQuoter(0x0C926BF1E71725eD68AE3041775e9Ba29142dca9).findBestPathFromAmountIn(_route, _amountIn);

        return quote;
    }
}