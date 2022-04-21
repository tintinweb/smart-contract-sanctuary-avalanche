/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.2;
interface IERC20 {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
interface Masterchef {
  function deposit(uint256 _pid, uint256 _amount,address _depositer) external;
}
interface IPangolinRouter {
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
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
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
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
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
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract stakeFund{
    IPangolinRouter public router;
    IERC20 public tokenAddress;
    IERC20 public lpToken;
    address public WETH;
    IERC20 public USDT;
    Masterchef public masterchef;


    constructor(
    address _tokenAddress,
    address _router,
    address _usdt,
    address _lpToken
    )public{
    router = IPangolinRouter(_router);
    tokenAddress = IERC20(_tokenAddress);
    USDT=IERC20(_usdt);
    lpToken=IERC20(_lpToken);

     WETH = router.WAVAX();
    }
    //deposited USDT will be converted to lp tokens and will be deposited
    function convertUsdtToLp(uint256 _amount) external {
    require(_amount>0,"USDT value should be greater than 0");
    USDT.transferFrom(msg.sender,address(this),_amount);
     uint256 half = _amount/2;
    USDT.approve(address(router),_amount);
    swapTokenToTOKEN(half,address(tokenAddress));
    uint256 tokenAmount = tokenAddress.balanceOf(address(this));
    tokenAddress.approve(address(router), tokenAmount);
    addLD(half, tokenAmount);
    lpToken.transfer(msg.sender,lpToken.balanceOf(address(this)));

  }
 function swapTokenToTOKEN(uint256 amount, address _tokenAddress) internal {
    // SWAP split % of ETH input to token
    address[] memory path = new address[](3);
    path[0] = address(USDT);
    path[1]=WETH;
    path[2] = _tokenAddress;
    

    router.swapExactTokensForTokens(
      amount,
      1,
      path,
      address(this),
      block.timestamp + 15 minutes
    );
  }
    function addLD(uint256 _USDTAmount, uint256 _tokenAmount) internal {
     // add the liquidity
     router.addLiquidity(
       address(USDT),
       address(tokenAddress),
       _USDTAmount,
       _tokenAmount,
       0, // slippage is unavoidable
       0, // slippage is unavoidable
       address(this),
       block.timestamp + 15 minutes
     );
  }
}

//tokenAdress
//0xb4a4Bbe0Dbdf623a6558a9eb47345A20AB3F6E40
//router
//0x2D99ABD9008Dc933ff5c0CD271B88309593aB921
//USDT
//0xD7F03FB7BD5e533E0c68A7903f89BD2828A34141
//LP token
//0x8e72707EA4EE227A10C651be69A61409186e8534

contract stakefundlp{
    IPangolinRouter public router;
    IERC20 public tokenAddress;
    IERC20 public lpToken;
    address public WETH;
    IERC20 public USDT;
    Masterchef public masterchef;


    constructor(
    address _tokenAddress,
    address _router,
    address _usdt,
    address _lpToken
    )public{
    router = IPangolinRouter(_router);
    tokenAddress = IERC20(_tokenAddress);
    USDT=IERC20(_usdt);
    lpToken=IERC20(_lpToken);

     WETH = router.WAVAX();
    }
    
    //deposited USDT will be converted to lp tokens and will be deposited
   function convertLptToUsdt(uint256 _amount) external {
    require(_amount>0,"Lp value should be greater than 0");
    lpToken.transferFrom(msg.sender,address(this),_amount);
     uint256 half = _amount/2;
    lpToken.approve(address(tokenAddress),_amount);
    swapTOKENToToken(half,address(USDT));
    uint256 tokenAmount = USDT.balanceOf(address(this));
    USDT.approve(address(router), tokenAmount);
    addLD(half, tokenAmount);
    USDT.transfer(msg.sender,USDT.balanceOf(address(this)));

  }
 function swapTOKENToToken(uint256 amount, address _tokenAddress) internal {
    // SWAP split % of ETH input to token
    address[] memory path = new address[](3);
    path[0] = address(USDT);
    path[1]=WETH;
    path[2] = _tokenAddress;
    

    router.swapExactTokensForTokens(
      amount,
      1,
      path,
      address(this),
      block.timestamp + 15 minutes
    );
  }
    function addLD(uint256 _USDTAmount, uint256 _tokenAmount) internal {
     // add the liquidity
     router.addLiquidity(
       address(USDT),
       address(tokenAddress),
       _USDTAmount,
       _tokenAmount,
       0, // slippage is unavoidable
       0, // slippage is unavoidable
       address(this),
       block.timestamp + 15 minutes
     );
  }
}

//tokenAdress0xD7F03FB7BD5e533E0c68A7903f89BD2828A34141
//0xb4a4Bbe0Dbdf623a6558a9eb47345A20AB3F6E40
//router
//0x2D99ABD9008Dc933ff5c0CD271B88309593aB921
//USDT
//0xD7F03FB7BD5e533E0c68A7903f89BD2828A34141
//LP token
//0x8e72707EA4EE227A10C651be69A61409186e8534