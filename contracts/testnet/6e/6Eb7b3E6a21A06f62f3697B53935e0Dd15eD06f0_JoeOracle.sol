// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IJoePair.sol";
import "../interfaces/IJoeRouter02.sol";

contract JoeOracle {
  IJoeRouter02 public router;

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  constructor(IJoeRouter02 _router) {
    router = _router;
  }

  /**
    * Get token B amounts out with token A amounts in via swap liquidity pool
    * @param _amountIn Amount of token A in, expressed in token A's decimals
    * @param _tokenA Token A address
    * @param _tokenB Token B address
    * @param _pair LP token address
    * @return amountOut Amount of token B to be received, expressed in token B's decimals
  */
  function getAmountsOut(
    uint256 _amountIn,
    address _tokenA,
    address _tokenB,
    address _pair
  ) public view returns (uint256) {
    require(_pair != address(0), "invalid pool");
    require(
      _tokenA == IJoePair(_pair).token0() || _tokenA == IJoePair(_pair).token1(),
      "invalid token in pool"
    );
    require(
      _tokenB == IJoePair(_pair).token0() || _tokenB == IJoePair(_pair).token1(),
      "invalid token in pool"
    );

    address[] memory path = new address[](2);
    path[0] = _tokenA;
    path[1] = _tokenB;

    return IJoeRouter02(router).getAmountsOut(_amountIn, path)[1];
  }

  /**
    * Get token A amounts in with token B amounts out via swap liquidity pool
    * @param _amountOut Amount of token B out, expressed in token B's decimals
    * @param _tokenA Token A address
    * @param _tokenB Token B address
    * @param _pair LP token address
    * @return amountIn Amount of token A to be swapped, expressed in token B's decimals
  */
  function getAmountsIn(
    uint256 _amountOut,
    address _tokenA,
    address _tokenB,
    address _pair
  ) public view returns (uint256) {
    require(_pair != address(0), "invalid pool");
    require(
      _tokenA == IJoePair(_pair).token0() || _tokenA == IJoePair(_pair).token1(),
      "invalid token in pool"
    );
    require(
      _tokenB == IJoePair(_pair).token0() || _tokenB == IJoePair(_pair).token1(),
      "invalid token in pool"
    );

    address[] memory path = new address[](2);
    path[0] = _tokenA;
    path[1] = _tokenB;

    return IJoeRouter02(router).getAmountsIn(_amountOut, path)[0];
  }

  /**
    * Get token A and token B's respective reserves in an amount of LP token
    * @param _amount Amount of LP token, expressed in 1e18
    * @param _tokenA Token A address
    * @param _tokenB Token B address
    * @param _pair LP token address
    * @return (reserveA, reserveB) Reserve amount of Token A and B respectively, in 1e18
  */
  function getLpTokenReserves(
    uint256 _amount,
    address _tokenA,
    address _tokenB,
    address _pair
  ) public view returns (uint256, uint256) {
    require(_pair != address(0), "invalid pool");
    require(
      _tokenA == IJoePair(_pair).token0() || _tokenA == IJoePair(_pair).token1(),
      "invalid token in pool"
    );
    require(
      _tokenB == IJoePair(_pair).token0() || _tokenB == IJoePair(_pair).token1(),
      "invalid token in pool"
    );

    uint256 reserveA;
    uint256 reserveB;

    (uint256 reserve0, uint256 reserve1, ) = IJoePair(_pair).getReserves();
    uint256 totalSupply = IJoePair(_pair).totalSupply();

    if (_tokenA == IJoePair(_pair).token0() && _tokenB == IJoePair(_pair).token1()) {
      reserveA = reserve0;
      reserveB = reserve1;
    } else {
      reserveA = reserve1;
      reserveB = reserve0;
    }

    reserveA = _amount * SAFE_MULTIPLIER / totalSupply * reserveA
                       / SAFE_MULTIPLIER / (10**IERC20(_tokenA).decimals());
    reserveB = _amount * SAFE_MULTIPLIER / totalSupply * reserveB
                       / SAFE_MULTIPLIER / (10**IERC20(_tokenB).decimals());

    return (reserveA, reserveB);
  }

  /**
    * Get token A and token B's LP token value
    * @param _amount Amount of LP token, expressed in 1e18
    * @param _tokenA Token A address
    * @param _tokenB Token B address
    * @param _pair LP token address
    * @return (tokenAValue, tokenBValue, lpTokenValue) Value of respective tokens; expressed in 1e6
  */
  function getLpTokenValue(
    uint256 _amount,
    address _tokenA,
    address _tokenB,
    address _pair
  ) public view returns (uint256, uint256, uint256) {
    uint256 tokenAValue = 0;
    uint256 tokenBValue = 0;
    uint256 lpTokenValue = 0;

    (uint256 reserveA, uint256 reserveB) = getLpTokenReserves(_amount, _tokenA, _tokenB, _pair);

    // Assume tokenA is volatile and tokenB is stablecoin for now

    // Getting tokenA value via mock data for now
    // uint256 tokenAValue = reserveA * _mockTokenAPrice;

    // Getting tokenA value via AMM -- this takes into account slippage and fees
    tokenAValue = getAmountsOut(reserveA, _tokenA, _tokenB, _pair);

    // Getting tokenA value via external price oracle
    // ...

    // Getting tokenB value via external price oracle
    // ...
    // Just assume reserveB is stablecoin for now
    tokenBValue = reserveB;

    lpTokenValue = tokenAValue + tokenBValue;

    return (tokenAValue, tokenBValue, lpTokenValue);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

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
     * @dev Returns the amount of tokens owned by `accoungit t`.
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

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IJoeRouter01.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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