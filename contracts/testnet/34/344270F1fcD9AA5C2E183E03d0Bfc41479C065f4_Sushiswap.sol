/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ISushiswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Sushiswap {
    address private constant SushiSwapRouter =
        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address private constant WAVAX = 0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3;
    address private constant USDC = 0x5425890298aed601595a70AB815c96711a31Bc65;

    function sushi_swap(
        address _tokenIn,
        address _tokenOut,
        address _to,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external {
        IERC20(_tokenIn).approve(SushiSwapRouter, _amountIn);
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

        address[] memory path;

        if (_tokenIn == WAVAX || _tokenOut == WAVAX) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WAVAX;
            path[2] = _tokenOut;
        }

        ISushiswapV2Router(SushiSwapRouter).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }
}