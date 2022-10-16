/**
 *Submitted for verification at snowtrace.io on 2022-10-16
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

interface IXGrape {
    function sell(uint256 amount) external returns (uint256);
}

interface IVault is IERC20 {
    function withdrawAll() external;
}

contract ReverseZapper {

    // constants
    IVault public constant Underlying = IVault(0x0dA1DC567D81925cFf22Df74C6b9e294E9E1c3A5);
    IUniswapV2Router02 public constant router = IUniswapV2Router02(0xC7f372c62238f6a5b79136A9e5D16A2FD7A3f0F5);
    address public constant LP = 0x9076C15D7b2297723ecEAC17419D506AE320CbF1;
    address public constant MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public constant GRAPE = 0x5541D83EFaD1f281571B343977648B75d95cdAC2;
    address public constant XGRAPE = 0x95CED7c63eA990588F3fd01cdDe25247D04b8D98;

    receive() external payable {}

    function unzap(uint256 amountxGrape, address tokenToReceive, uint256 minOut) external {
        require(
            amountxGrape > 0,
            'Zero Amount'
        );
        require(
            IERC20(XGRAPE).allowance(msg.sender, address(this)) >= amountxGrape,
            'Insufficient Allowance'
        );
        require(
            tokenToReceive == LP || tokenToReceive == MIM || tokenToReceive == GRAPE || tokenToReceive == address(Underlying),
            'Invalid Token To Receive'
        );
        require(
            IERC20(XGRAPE).transferFrom(msg.sender, address(this), amountxGrape),
            'ERR Transfer From'
        );

        // sell XGRAPE
        IXGrape(XGRAPE).sell(IERC20(XGRAPE).balanceOf(address(this)));

        // if underlying, send tokens
        if (tokenToReceive == address(Underlying)) {
            Underlying.transfer(msg.sender, Underlying.balanceOf(address(this)));
            return;
        }

        // withdraw LP
        Underlying.withdrawAll();
        uint256 lpBalance = IERC20(LP).balanceOf(address(this));

        // if underlying is LP, send LP
        if (tokenToReceive == LP) {
            IERC20(LP).transfer(msg.sender, lpBalance);
            return;
        }

        // break LP into two tokens
        IERC20(LP).approve(address(router), lpBalance);
        router.removeLiquidity(GRAPE, MIM, lpBalance, 0, 0, address(this), block.timestamp + 1000);

        if (tokenToReceive == MIM) {
            
            // swap all grape for mim
            uint256 swapAmount = IERC20(GRAPE).balanceOf(address(this));

            // approve of swap
            IERC20(GRAPE).approve(address(router), swapAmount);

            // Swap Path
            address[] memory path = new address[](2);
            path[0] = GRAPE;
            path[1] = MIM;

            // Swap The Tokens
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount, 0, path, address(this), block.timestamp + 10
            );

        } else {

            // swap all mim for grape
            uint256 swapAmount = IERC20(MIM).balanceOf(address(this));

            // approve of swap
            IERC20(MIM).approve(address(router), swapAmount);

            // Swap Path
            address[] memory path = new address[](2);
            path[0] = MIM;
            path[1] = GRAPE;

            // Swap The Tokens
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount, 0, path, address(this), block.timestamp + 10
            );
        }

        uint amountToSend = IERC20(tokenToReceive).balanceOf(address(this));
        require(
            amountToSend >= minOut,
            'Min Out'
        );

        IERC20(tokenToReceive).transfer(
            msg.sender,
            amountToSend
        );
    }
}