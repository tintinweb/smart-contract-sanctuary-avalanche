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

    function WETH() external view returns (address);
}

interface IERC20 {
    function transferFrom(address, address, uint256) external;

    function approve(address, uint256) external;
}

/*******************************************************
 *                  Uniswap v2 Aggregator
 *******************************************************/
contract UniswapV2Aggregator {
    /*******************************************************
     *                       Storage
     *******************************************************/
    address public ownerAddress = msg.sender;
    mapping(address => bool) public dexExists;
    Dex[] public dexes;

    /*******************************************************
     *                       Types
     *******************************************************/
    struct Dex {
        string name;
        address factoryAddress;
        address routerAddress;
    }

    struct Quote {
        address routerAddress;
        uint256 quoteAmount;
        address[] path;
    }

    /*******************************************************
     *                    Dex management
     *******************************************************/
    function addDex(Dex memory dex) public {
        require(msg.sender == ownerAddress, "Ownable: caller is not the owner");
        require(dexExists[dex.factoryAddress] == false, "Dex exists");
        dexExists[dex.factoryAddress] = true;
        dexes.push(dex);
    }

    /*******************************************************
     *                       Quotes
     *******************************************************/
    function getAmountOutFromRouter(
        address routerAddress,
        uint256 amountIn,
        address token0Address,
        address token1Address
    ) public view returns (uint256 amountOut, address[] memory path) {
        IUniswapV2Router router = IUniswapV2Router(routerAddress);
        address wethAddress = router.WETH();
        bool inputTokenIsWeth = token0Address == wethAddress ||
            token1Address == wethAddress;
        if (inputTokenIsWeth) {
            // path = [token0, weth] or [weth, token1]
            path = new address[](2);
            path[0] = token0Address;
            path[1] = token1Address;
        } else {
            // path = [token0, weth, token1]
            path = new address[](3);
            path[0] = token0Address;
            path[1] = wethAddress;
            path[2] = token1Address;
        }
        uint256[] memory amountsOut;
        amountsOut = router.getAmountsOut(amountIn, path);
        amountOut = amountsOut[amountsOut.length - 1];
        return (amountOut, path);
    }

    function quote(
        uint256 amountIn,
        address token0Address,
        address token1Address
    ) external view returns (Quote memory bestQuote) {
        uint256 highestQuoteAmount;
        for (uint256 dexIdx; dexIdx < dexes.length; dexIdx++) {
            Dex memory dex = dexes[dexIdx];
            address routerAddress = dex.routerAddress;
            try
                this.getAmountOutFromRouter(
                    routerAddress,
                    amountIn,
                    token0Address,
                    token1Address
                )
            returns (uint256 quoteAmount, address[] memory path) {
                if (quoteAmount > highestQuoteAmount) {
                    highestQuoteAmount = quoteAmount;
                    bestQuote = Quote({
                        routerAddress: routerAddress,
                        quoteAmount: quoteAmount,
                        path: path
                    });
                }
            } catch {}
        }
        return bestQuote;
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

    /*******************************************************
     *                      Management
     *******************************************************/
    function setOwner(address _ownerAddress) public {
        require(msg.sender == ownerAddress, "Ownable: caller is not the owner");
        ownerAddress = _ownerAddress;
    }
}