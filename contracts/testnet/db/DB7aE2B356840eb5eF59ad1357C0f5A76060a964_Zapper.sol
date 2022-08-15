/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-14
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
    function WAVAX() external pure returns (address);

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

contract Zapper {

    IVault public immutable Underlying;
    IUniswapV2Router02 public immutable router;

    address public immutable XGRAPE;
    address public immutable LP;
    address public immutable MIM;
    address public immutable GRAPE;

    constructor(address XGRAPE_, address Underlying_, address router_, address LP_, address MIM_, address GRAPE_) {
        XGRAPE = XGRAPE_;
        Underlying = IVault(Underlying_);
        router = IUniswapV2Router02(router_);
        LP = LP_;
        MIM = MIM_;
        GRAPE = GRAPE_;
    }

    receive() external payable {
        
        // convert AVAX into underlying
        _convertTokenToUnderlying(address(0));

        // transfer AVAX back to XGRAPE
        Underlying.transfer(XGRAPE, Underlying.balanceOf(address(this)));

        // refund dust
        _refundDust(msg.sender);
    }

    function zapWithAvax(uint256 minOut) external payable {

        // convert token to Underlying
        _convertTokenToUnderlying(address(0));
        
        // require minOut
        uint256 bal = Underlying.balanceOf(address(this));
        require(
            bal >= minOut,
            'Min LP Out'
        );

        // approve Miner for balance
        Underlying.approve(XGRAPE, bal);

        // deposit for sender
        IXGrape(XGRAPE).mintWithBacking(bal, msg.sender);

        // refund dust
        _refundDust(msg.sender);
    }

    function zap(address token_, uint256 amount, uint256 minOut) external {

        // transfer in `amount` of `token`
        _transferIn(token_, amount);

        if (token_ == LP) {
            // convert LP into underlying
            _depositIntoVault();
        } else {
            // convert token to Underlying
            _convertTokenToUnderlying(token_);
        }
        
        // require minOut
        uint256 bal = Underlying.balanceOf(address(this));
        require(
            bal >= minOut,
            'Min LP Out'
        );

        // approve Miner for balance
        Underlying.approve(XGRAPE, bal);

        // deposit for sender
        IXGrape(XGRAPE).mintWithBacking(bal, msg.sender);

        // refund dust
        _refundDust(msg.sender);
    }

    function _convertTokenIntoTokensForLP(address token_) internal {

        // balance of token
        uint256 amount = token_ == address(0) ? address(this).balance : IERC20(token_).balanceOf(address(this));
        require(
            amount > 1,
            'Amount Too Low'
        );

        if ( token_ == MIM || token_ == GRAPE ) {
            
            // swap half token_ for other token
            uint256 amountToSwap = amount / 2;
            
            // approve of swap
            IERC20(token_).approve(address(router), amountToSwap);

            // token we are swapping for
            address swapToToken = token_ == MIM ? GRAPE : MIM;

            // Swap Path
            address[] memory path = new address[](2);
            path[0] = token_;
            path[1] = swapToToken;

            // Swap The Tokens
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountToSwap, 0, path, address(this), block.timestamp + 10
            );

            // gas savings
            delete path;

        } else if (token_ == address(0)) {

            // Swap Path WETH -> MIM
            address[] memory path = new address[](2);
            path[0] = router.WAVAX();
            path[1] = MIM;

            // swap balance into MIM, then swap MIM into Grape
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: amount
            }(0, path, address(this), block.timestamp + 10);

            // clear memory
            delete path;

            // swap MIM into GRAPE
            _convertTokenIntoTokensForLP(MIM);

        } else {
            
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

            // swap MIM into GRAPE
            _convertTokenIntoTokensForLP(MIM);
        }
    }

    function _convertTokenToUnderlying(address token_) internal {

        // convert token to LP token
        _convertTokenIntoTokensForLP(token_);

        // pair liquidity
        _pairLiquidity();

        // deposit liquidity token into vault
        _depositIntoVault();
    }

    function _depositIntoVault() internal {
        // stake all LP balance Into Vault
        uint256 bal = IERC20(LP).balanceOf(address(this));
        IERC20(LP).approve(address(Underlying), bal);
        Underlying.deposit(bal);
    }

    function _pairLiquidity() internal {

        // fetch balances
        uint256 bal0 = IERC20(MIM).balanceOf(address(this));
        uint256 bal1 = IERC20(GRAPE).balanceOf(address(this));

        // approve tokens
        IERC20(MIM).approve(address(router), bal0);
        IERC20(GRAPE).approve(address(router), bal1);

        // add liquidity
        router.addLiquidity(
            MIM, 
            GRAPE, 
            bal0,
            bal1,
            0,
            0,
            address(this),
            block.timestamp + 10
        );
    }

    function _refundDust(address recipient) internal {
        
        // refund dust
        uint bal0 = IERC20(MIM).balanceOf(address(this));
        uint bal1 = IERC20(GRAPE).balanceOf(address(this));
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