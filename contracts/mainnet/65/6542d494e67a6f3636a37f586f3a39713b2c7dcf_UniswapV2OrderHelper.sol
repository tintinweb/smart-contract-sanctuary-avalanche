/**
 *Submitted for verification at snowtrace.io on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*******************************************************
 *                      Interfaces
 *******************************************************/
interface IUniswapV2Router {
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint validTo
    ) external;
}

interface IERC20 {
    function transferFrom(address, address, uint256) external;

    function approve(address, uint256) external;
}

/*******************************************************
 *                 Uniswap v2 Order Helper
 *******************************************************/
contract UniswapV2OrderHelper {
    /*******************************************************
     *                       Quotes
     *******************************************************/
    function getAmountOutFromRouter(
        address wNativeAddress,
        address routerAddress,
        uint256 amountIn,
        address token0Address,
        address token1Address
    ) public view returns (uint256 amountOut, address[] memory path) {
        IUniswapV2Router router = IUniswapV2Router(routerAddress);
        bool inputTokenIsWNative = token0Address == wNativeAddress ||
            token1Address == wNativeAddress;
        if (inputTokenIsWNative) {
            // path = [token0, weth] or [weth, token1]
            path = new address[](2);
            path[0] = token0Address;
            path[1] = token1Address;
        } else {
            // path = [token0, weth, token1]
            path = new address[](3);
            path[0] = token0Address;
            path[1] = wNativeAddress;
            path[2] = token1Address;
        }
        try router.getAmountsOut(amountIn, path) returns (
            uint256[] memory amountsOut
        ) {
            amountOut = amountsOut[amountsOut.length - 1];
        } catch {
            amountOut = 0;
        }
        return (amountOut, path);
    }

    /*******************************************************
     *                      Execution
     *******************************************************/
    // Can be gas optimized to use pairs directly without router
    function executeOrder(
        IUniswapV2Router router,
        address[] memory path,
        uint256 fromAmount,
        uint256 toAmount
    ) external {
        IERC20 fromToken = IERC20(path[0]);
        fromToken.transferFrom(msg.sender, address(this), fromAmount);
        fromToken.approve(address(router), type(uint256).max); // Max approve to save gas --this contract should never hold tokens
        router.swapExactTokensForTokens(
            fromAmount,
            toAmount,
            path,
            msg.sender,
            block.timestamp
        );
    }
}