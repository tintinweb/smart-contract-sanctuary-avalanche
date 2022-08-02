/**
 *Submitted for verification at snowtrace.io on 2022-08-02
*/

/**
 *Submitted for verification at snowtrace.io on 2022-08-02
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

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract LPPriceOracle {

    IUniswapV2Router02 public router = IUniswapV2Router02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant USDC  = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address public constant MIM   = 0x130966628846BFd36ff31a822705796e8cb8C18D;

    mapping ( address => bool ) public isStableAsset;

    address dataWriter;
    constructor(){
        dataWriter = msg.sender;
        isStableAsset[USDC] = true;
        isStableAsset[MIM]  = true;
    }

    function setIsStable(address stable, bool isStable) external {
        require(msg.sender == dataWriter);
        isStableAsset[stable] = isStable;
    }

    function LPStatsForToken(address token, address backing) external view returns (uint256, uint256) {
        return _lpAmountsForToken(token, backing);
    }

    function priceOf(address token, address backing) public view returns (uint256) {
        if (token == backing) {
            return 10**18;
        }
        return token == WAVAX ? priceOfWAVAX() : priceOfToken(token, backing);
    }

    /**
        Takes An Array of Addresses and returns an equal sized array of prices
        Works For BNB, Regular Tokens And Surge Tokens
     */
    function pricesOf(address[] calldata tokens) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            prices[i] = priceOf(tokens[i], WAVAX);
        }
        return prices;
    }

    function priceOfToken(address token, address backing) public view returns (uint256) {
        (uint256 p0, uint256 p1) = _lpAmountsForToken(token, backing);
        return isStableAsset[backing] ? ((p1 * 10**18 ) / p0) : ( ( p1 * priceOfToken(backing, USDC)) / p0);
    }

    function priceOfWAVAX() public view returns (uint256) {
        address LP = getPair(USDC, WAVAX);
        uint256 amt0 = IERC20(USDC).balanceOf(LP);
        uint256 amt1 = IERC20(WAVAX).balanceOf(LP);
        return ( amt0 * 10**18 / amt1);
    }

    function TVL_LP_IN_FARM(address LP, address farm) public view returns (uint256) {

        uint256 balance = IERC20(LP).balanceOf(farm);
        uint256 totalSupply = IERC20(LP).totalSupply();

        if (balance == 0 || totalSupply == 0) {
            return 0;
        }

        uint price = priceOfLP(LP);

        // multiply total LP value by ratio of Farm Holdings vs Total Supply
        return ( price * balance ) / totalSupply;
    }

    function TVL_LP(address LP) public view returns (uint256) {
        uint256 totalSupply = IERC20(LP).totalSupply();
        uint price = priceOfLP(LP);
        return ( price * totalSupply ) / 10**18;
    }

    function priceOfLP(address LP) public view returns (uint256) {

        // get balance of farm versus LP total supply
        uint256 totalSupply = IERC20(LP).totalSupply();

        if (totalSupply == 0) {
            return 0;
        }

        // fetch tokens in LP
        address token0 = IPair(LP).token0();
        address token1 = IPair(LP).token1();

        bool useUSDC0 = getPair(token0, USDC) != address(0);
        bool useUSDC1 = getPair(token1, USDC) != address(0);

        // fetch prices of tokens
        uint256 price0 = priceOf(token0, useUSDC0 ? USDC : MIM);
        uint256 price1 = priceOf(token1, useUSDC1 ? USDC : MIM);

        // fetch balance of tokens in LP
        uint256 bal0 = IERC20(token0).balanceOf(LP);
        uint256 bal1 = IERC20(token1).balanceOf(LP);

        // multiply price times balances in LP
        uint val0 = ( bal0 * price0 ) / 10**IERC20(token0).decimals();
        uint val1 = ( bal1 * price1 ) / 10**IERC20(token1).decimals();

        // add values together - value of total LP
        uint256 value = val0 + val1;

        // multiply total LP value by ratio of Farm Holdings vs Total Supply
        return ( value * 10**18 ) / totalSupply;
    }

    function _lpAmountsForToken(address token, address backing) internal view returns (uint256, uint256) {
        address LP = getPair(token, backing);
        uint256 amt0 = IERC20(token).balanceOf(LP);
        uint256 amt1 = IERC20(backing).balanceOf(LP);
        return ( amt0 / 10**IERC20(token).decimals(), amt1 / 10**IERC20(backing).decimals());
    }

    function getPair(address token0, address token1) internal view returns (address) {
        return IUniswapV2Factory(router.factory()).getPair(token0, token1);
    }

}