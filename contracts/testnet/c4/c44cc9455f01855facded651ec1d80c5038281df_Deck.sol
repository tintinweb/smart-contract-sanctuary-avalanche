/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Deck {
    uint amountOut;
    struct SwapStep {
        address pool; // The pool of the step.
        bytes data; // The data to execute swap with the pool.
        address callback;
        bytes callbackData;
    }

    struct SwapPath {
        SwapStep[] steps; // Steps of the path.
        address tokenIn; // The input token of the path.
        uint amountIn; // The input token amount of the path.
    }

    function swap1(
        SwapStep memory step
    ) external payable returns (uint) {
        amountOut = 1;
       return amountOut;
    }

    function swap2(
        SwapStep[] memory steps
    ) external payable returns (uint) {
        amountOut = 2;
       return 2;
    }

    function swap3(
        SwapPath memory path
    ) external payable returns (uint) {
        amountOut = 3;
       return 3;
    }

    function swap4(
        SwapPath[] memory paths,
        uint amountOutMin,
        uint deadline
    ) external payable returns (uint) {
        amountOut = 4;
       return 4;
    }
}