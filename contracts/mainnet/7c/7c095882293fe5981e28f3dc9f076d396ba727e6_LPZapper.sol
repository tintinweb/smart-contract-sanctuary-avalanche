/**
 *Submitted for verification at snowtrace.io on 2022-09-14
*/

/**
 *Submitted for verification at snowtrace.io on 2022-09-14
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IXGrape {
    function mintWithBacking(uint256 numTokens, address recipient) external returns (uint256);
}

interface IVault is IERC20 {
    function deposit(uint amount) external;
}

interface IMiner {
    function depositFor(address user, address ref, uint256 amount) external;
    function token() external view returns (IERC20);
}

contract LPZapper {

    // constants
    IVault public constant Underlying = IVault(0x0dA1DC567D81925cFf22Df74C6b9e294E9E1c3A5);
    IUniswapV2Router02 public constant router = IUniswapV2Router02(0xC7f372c62238f6a5b79136A9e5D16A2FD7A3f0F5);
    address public constant LP = 0x9076C15D7b2297723ecEAC17419D506AE320CbF1;
    address public constant MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public constant GRAPE = 0x5541D83EFaD1f281571B343977648B75d95cdAC2;
    address public constant XGRAPE = 0x95CED7c63eA990588F3fd01cdDe25247D04b8D98;
    address public constant MINER = 0x73Bc9e16772aF57974eb76a1C868DD316D2C428c;
    address public constant XGRAPELP = 0xE00b91F35924832D1a7d081d4DCed55f3b80FB5C;

    receive() external payable {}



    function zap(address token_, address ref, address sender, uint256 minOut) external {
        require(
            msg.sender == MINER,
            'Only Miner Can Zap'
        );
        // convert token to Underlying
        _convertTokenToUnderlying(token_);

        // require minOut
        uint256 bal = Underlying.balanceOf(address(this));
        require(
            bal >= minOut,
            'Min LP Out'
        );

        // mint xGrape
        _mintXGrape(bal);

        // pair liquidity for xGrape - Grape
        _pairLiquidity(XGRAPE, GRAPE, address(this));

        uint256 xgrapeLP = IERC20(XGRAPELP).balanceOf(address(this));

        // approve Miner for balance
        IERC20(XGRAPELP).approve(MINER, xgrapeLP);

        // deposit for sender
        IMiner(MINER).depositFor(sender, ref, xgrapeLP);

        // refund dust
        _refundDust(sender);
    }

    function _mintXGrape(uint256 bal) internal {
        // approve Miner for balance
        Underlying.approve(XGRAPE, bal);

        // deposit for sender
        IXGrape(XGRAPE).mintWithBacking(bal, address(this));
    }

    function _convertTokenIntoTokensForLP(address token_) internal {

        if ( token_ == MIM) {

            // swap half token_ for other token
            uint256 amount = 3 * IERC20(token_).balanceOf(address(this)) / 4;
            
            // approve of swap
            IERC20(token_).approve(address(router), amount);

            // Swap Path
            address[] memory path = new address[](2);
            path[0] = token_;
            path[1] = GRAPE;

            // Swap The Tokens
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount, 0, path, address(this), block.timestamp + 10
            );

            // gas savings
            delete path;

        } else if ( token_ == GRAPE ) {
            
            // swap half token_ for other token
            uint256 amount = IERC20(token_).balanceOf(address(this)) / 4;
            
            // approve of swap
            IERC20(token_).approve(address(router), amount);

            // Swap Path
            address[] memory path = new address[](2);
            path[0] = token_;
            path[1] = MIM;

            // Swap The Tokens
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount, 0, path, address(this), block.timestamp + 10
            );

            // gas savings
            delete path;

        } else {

            // Swap Path WETH -> MIM
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = MIM;

            // swap balance into MIM, then swap MIM into Grape
            router.swapExactETHForTokens{
                value: address(this).balance / 4
            }(0, path, address(this), block.timestamp + 10);

            // swap rest of balance into GRAPE
            path[1] = GRAPE;

            // swap balance into MIM, then swap MIM into Grape
            router.swapExactETHForTokens{
                value: address(this).balance
            }(0, path, address(this), block.timestamp + 10);

            // clear memory
            delete path;
        }
    }

    function _convertTokenToUnderlying(address token_) internal {

        // convert token to LP token
        _convertTokenIntoTokensForLP(token_);

        // pair liquidity
        _pairLiquidity(MIM, GRAPE, address(this));

        // deposit liquidity token into vault
        _depositIntoVault();
    }

    function _depositIntoVault() internal {
        // stake all LP balance Into Vault
        uint256 bal = IERC20(LP).balanceOf(address(this));
        IERC20(LP).approve(address(Underlying), bal);
        Underlying.deposit(bal);
    }

    function _pairLiquidity(
        address token0,
        address token1,
        address dest
    ) internal {

        // fetch balances
        uint256 bal0 = IERC20(token0).balanceOf(address(this));
        uint256 bal1 = IERC20(token1).balanceOf(address(this));

        // approve tokens
        IERC20(token0).approve(address(router), bal0);
        IERC20(token1).approve(address(router), bal1);

        // add liquidity
        router.addLiquidity(
            token0, 
            token1, 
            bal0,
            bal1,
            0,
            0,
            dest,
            block.timestamp + 10
        );
    }

    function _refundDust(address recipient) internal {
        
        // refund dust
        uint bal0 = IERC20(MIM).balanceOf(address(this));
        uint bal1 = IERC20(GRAPE).balanceOf(address(this));
        uint bal2 = IERC20(XGRAPE).balanceOf(address(this));
        if (bal0 > 0) {
            IERC20(MIM).transfer(
                recipient,
                bal0
            );
        }
        if (bal1 > 0) {
            IERC20(GRAPE).transfer(
                recipient,
                bal1
            );
        }
        if (bal2 > 0) {
            IERC20(XGRAPE).transfer(
                recipient,
                bal2
            );
        }
    }

    function _transferIn(address token, uint256 amount) internal {
        require(
            IERC20(token).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Failure Transfer From'
        );
    }
}