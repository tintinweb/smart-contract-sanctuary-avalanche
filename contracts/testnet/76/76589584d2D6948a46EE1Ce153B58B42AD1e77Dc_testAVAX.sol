// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;
pragma abicoder v2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function WETH9() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

interface IStargateReceiver {
    function sgReceive(
        uint16 _srcChainId,              // the remote chainId sending the tokens
        bytes memory _srcAddress,        // the remote Bridge address
        uint256 _nonce,                  
        address _token,                  // the token contract on the local chain
        uint256 amountLD,                // the qty of local _token contract tokens  
        bytes memory payload
    ) external;
}

contract testAVAX {
    address public routerAVAX = 0x13093E05Eb890dfA6DacecBdE51d24DabAb2Faa1;
    address public ammRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public OUT_TO_NATIVE = 0x0000000000000000000000000000000000000000;
    
    event ReceivedOnDestination (address _token, uint amountLD);

    function swapNativeForNative(
        uint16 dstChainId,                      // Stargate/LayerZero chainId
        address bridgeToken,                    // the address of the native ERC20 to swap() - *must* be the token for the poolId
        uint16 srcPoolId,                       // stargate poolId - *must* be the poolId for the bridgeToken asset
        uint16 dstPoolId,                       // stargate destination poolId
        uint nativeAmountIn,                    // exact amount of native token coming in on source
        address to,                             // the address to send the destination tokens to
        uint amountOutMin,                      // minimum amount of stargatePoolId token to get out of amm router
        uint amountOutMinSg,                    // minimum amount of stargatePoolId token to get out on destination chain
        uint amountOutMinDest,                  // minimum amount of native token to receive on destination
        uint deadline,                          // overall deadline
        address destStargateComposed            // destination contract. it must implement sgReceive()
    ) external payable {

        require(nativeAmountIn > 0, "nativeAmountIn must be greater than 0");
        require((msg.value - nativeAmountIn) > 0, "stargate requires fee to pay crosschain message");

        uint bridgeAmount;
        // using the amm router, swap native into the Stargate pool token, sending the output token to this contract
        {
            // create path[] for amm swap
            address[] memory path = new address[](2);
            path[0] = IUniswapV2Router02(ammRouter).WETH();    // native IN requires that we specify the WETH in path[0]
            path[1] = bridgeToken;                             // the bridge token,

            uint[] memory amounts = IUniswapV2Router02(ammRouter).swapExactETHForTokens{value:nativeAmountIn}(
                amountOutMin,
                path,
                address(this),
                deadline
            );

            bridgeAmount = amounts[1];
            require(bridgeAmount > 0, 'error: ammRouter gave us 0 tokens to swap() with stargate');

            // this contract needs to approve the stargateRouter to spend its path[1] token!
            IERC20(bridgeToken).approve(address(routerAVAX), bridgeAmount);
        }

        // encode payload data to send to destination contract, which it will handle with sgReceive()
        bytes memory data;
        {
            data = abi.encode(OUT_TO_NATIVE, deadline, amountOutMinDest, to);
        }

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(routerAVAX).swap{value:msg.value - nativeAmountIn}(
            dstChainId,                                     // the destination chain id
            srcPoolId,                                      // the source Stargate poolId
            dstPoolId,                                      // the destination Stargate poolId
            payable(msg.sender),                            // refund adddress. if msg.sender pays too much gas, return extra eth
            bridgeAmount,                                   // total tokens to send to destination chain
            amountOutMinSg,                                 // minimum
            IStargateRouter.lzTxObj(500000, 0, "0x"),       // 500,000 for the sgReceive()
            abi.encodePacked(destStargateComposed),         // destination address, the sgReceive() implementer
            data                                            // bytes payload
        );
    }

//     function sendAVAXtoMATIC (address bridgeToken, uint nativeAmountIn, uint16 dstChainId, uint srcPoolId,
//     uint dstPoolId, uint amountOutMin, uint256 amountOutMinSg, address to,               
//     uint amountOutMinDest, uint deadline, address destStargateComposed) external payable {

//     uint bridgeAmount;

//     address[] memory path = new address[](2);
//     path[0] = IUniswapV2Router02(ammRouter).WETH();    // native IN requires that we specify the WETH in path[0]
//     path[1] = bridgeToken;                             // the bridge token,

//     uint[] memory amounts = IUniswapV2Router02(ammRouter).swapExactETHForTokens{value:nativeAmountIn}(
//         amountOutMin,
//         path,
//         address(this),
//         deadline
//     );

//     bridgeAmount = amounts[1];
//     require(bridgeAmount > 0, 'error: ammRouter gave us 0 tokens to swap() with stargate');

//     // this contract needs to approve the stargateRouter to spend its path[1] token!
//     IERC20(bridgeToken).approve(address(routerAVAX), bridgeAmount);


//     // encode payload data to send to destination contract, which it will handle with sgReceive()
//     bytes memory data;
// {
//     data = abi.encode(OUT_TO_NATIVE, deadline, amountOutMinDest, to);
// }
//         IStargateRouter(routerAVAX).swap{value:msg.value - nativeAmountIn}(
//         dstChainId,                               // the destination chain id
//         srcPoolId,                                // the source Stargate poolId
//         dstPoolId,                                // the destination Stargate poolId
//         payable(msg.sender),                      // refund adddress. if msg.sender pays too much gas, return extra eth
//         bridgeAmount,                             // total tokens to send to destination chain
//         amountOutMinSg,                           // minimum
//         IStargateRouter.lzTxObj(500000, 0, "0x"), // 500,000 for the sgReceive()
//         abi.encodePacked(destStargateComposed),   // destination address, the sgReceive() implementer
//         data                                      // bytes payload
// );
//     }
}