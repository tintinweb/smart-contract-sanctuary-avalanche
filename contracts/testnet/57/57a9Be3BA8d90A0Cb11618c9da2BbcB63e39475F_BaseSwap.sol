/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-19
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// File: https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/traderjoe/interfaces/IJoeRouter01.sol



pragma solidity >=0.6.2;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// File: https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/traderjoe/interfaces/IJoeRouter02.sol



pragma solidity >=0.6.2;


interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/myflashbot/BaseSwap.sol

pragma solidity ^0.8.0;



contract BaseSwap {
  address internal constant TRADEJOE_ROUTER_ADDRESS = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4 ;
  address internal constant PAGOLINA_ROUTER_ADDRESS = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106 ;
  address internal constant tokenUSDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

  IJoeRouter02  public tradejoeRouter = IJoeRouter02 (TRADEJOE_ROUTER_ADDRESS);
  IJoeRouter02  public pagolinaRouter = IJoeRouter02 (PAGOLINA_ROUTER_ADDRESS);

  constructor() {
  }

  function convertAVAXToUSDTInTradejoe(uint USDTAmount) public payable {
    
    tradejoeRouter.swapAVAXForExactTokens(USDTAmount, getPathForAVAXToUSDT(), address(this), block.timestamp + 150);
    
    // refund leftover AVAX to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }
  
  function convertUSDTToAVAXInTradejoe(uint USDTAmount) public payable {
    IERC20(tokenUSDT).approve(TRADEJOE_ROUTER_ADDRESS, USDTAmount);
    tradejoeRouter.swapExactTokensForAVAX(USDTAmount, 0, getPathForUSDTToAVAX(), address(this), block.timestamp + 150);
  }

  function getEstimatedAVAXforUSDTInTradejoe(uint USDTAmount) public view returns (uint[] memory) {
    return tradejoeRouter.getAmountsIn(USDTAmount, getPathForAVAXToUSDT());
  }

  function getEstimatedUSDTforAVAXInTradejoe(uint AVAXAmount) public view returns (uint[] memory) {
    return tradejoeRouter.getAmountsIn(AVAXAmount, getPathForUSDTToAVAX());
  }

  // ---------------------------------------------------------------------------------------

  function convertAVAXToUSDTInPagolina(uint USDTAmount) public payable { pagolinaRouter.swapAVAXForExactTokens{ value: msg.value }(USDTAmount, getPathForAVAXToUSDT(), address(this), block.timestamp + 150);

    // refund leftover AVAX to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }
  
  function convertUSDTToAVAXInPagolina(uint USDTAmount) public payable {
    IERC20(tokenUSDT).approve(PAGOLINA_ROUTER_ADDRESS, USDTAmount);
    pagolinaRouter.swapExactTokensForAVAX(USDTAmount, 0, getPathForUSDTToAVAX(), address(this), block.timestamp + 150);
  }

  function getEstimatedAVAXforUSDTInPagolina(uint USDTAmount) public view returns (uint[] memory) {
    return pagolinaRouter.getAmountsIn(USDTAmount, getPathForAVAXToUSDT());
  }

  function getEstimatedUSDTforAVAXInPagolina(uint AVAXAmount) public view returns (uint[] memory) {
    return pagolinaRouter.getAmountsIn(AVAXAmount, getPathForUSDTToAVAX());
  }

  function getPathForAVAXToUSDT() public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = pagolinaRouter.WAVAX();
    path[1] = tokenUSDT;
    return path;
  }

  function getPathForUSDTToAVAX() public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = tokenUSDT;
    path[1] = pagolinaRouter.WAVAX();
    return path;
  }
}