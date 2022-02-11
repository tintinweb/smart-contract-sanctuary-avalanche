/**
 *Submitted for verification at snowtrace.io on 2022-01-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}


contract Trader {
    address public owner;
    address constant WMEMO = 0x0da67235dD5787D67955420C84ca1cEcd4E5Bb3b;
    address constant MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address constant router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    bool orderActive;
    uint256 amountIn;
    uint256 minAmountOut;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function limitOrder(uint256 _amountIn, uint256 _minAmountOut)
        external
        onlyOwner
    {
        require(!orderActive);

        amountIn = _amountIn;
        minAmountOut = _minAmountOut;
        orderActive = true;

        IERC20(WMEMO).transferFrom(msg.sender, address(this), amountIn);
    }

    function execute() external onlyOwner {
        require(orderActive);

        address[] memory path;
        path[0] = WMEMO;
        path[1] = MIM;

        uint256[] memory amounts = IRouter(router).getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= minAmountOut, "Limit not reached");

        IERC20(WMEMO).approve(router, amountIn);
        IRouter(router).swapExactTokensForTokens(
            amountIn,
            amounts[amounts.length - 1],
            path,
            owner,
            block.timestamp
        );
        orderActive = false;
        amountIn = 0;
        minAmountOut = 0;
    }

    function cancelOrder() external onlyOwner {
        require(orderActive);
        IERC20(WMEMO).transfer(msg.sender, amountIn);
        orderActive = false;
    }
}