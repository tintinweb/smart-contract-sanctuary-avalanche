// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @notice Mock for some methods of UniswapV2Pair
///         https://docs.uniswap.org/protocol/V2/reference/smart-contracts/pair
///         We need only methods required by DebtsManager
contract MockUniswapV2Pair {
    address internal _token0;
    address internal _token1;
    uint112 internal _reserve0;
    uint112 internal _reserve1;

    constructor(
        address token0_,
        address token1_,
        uint112 reserve0,
        uint112 reserve1
    ) {
        _token0 = token0_;
        _token1 = token1_;
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function token0() external view returns (address) {
        return _token0;
    }

    function token1() external view returns (address) {
        return _token1;
    }

    function getReserves() external view returns (
    uint112 reserve0
    , uint112 reserve1
    , uint32 blockTimestampLast
    ) {
        return (_reserve0, _reserve1, 0);
    }
}