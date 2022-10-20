// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IETFToken.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../lib/TransferHelper.sol";
import "../lib/BNum.sol";

contract ETFZapper is BNum {
    address public factory;
    address public ETFToken;
    IUniswapV2Router public router;
    address[] private _path;

    event JoinSingle(uint256 poolAmountOut, uint256[] amountsToPool);

    constructor(address factory_, address router_, address ETFToken_) {
        address zero = address(0);
        require(factory_ != zero, "DexETF: Factory is zero address");
        require(router_ != zero, "DexETF: Router is zero address");
        require(ETFToken_ != zero, "DexETF: ETFToken is zero address");
        ETFToken = ETFToken_;
        factory = factory_;
        router = IUniswapV2Router(router_);
    }

    function setETFToken(address ETFToken_) external {
        ETFToken = ETFToken_;
    }

    function joinSingle(
        address tokenIn,
        uint256 amountInMax,
        address[] memory intermediaries,
        uint256 poolAmountOut
    ) external returns (uint256 amountInTotal) {
        address[] memory tokens = IETFToken(ETFToken).getCurrentTokens();
        require(
            tokens.length == intermediaries.length,
            "DexETF: Invalid arrays length"
        );
        uint256[] memory amountsToPool = new uint256[](tokens.length);
        uint256 ratio = bdiv(poolAmountOut, IERC20(ETFToken).totalSupply());
        for (uint256 i = 0; i < tokens.length; i++) {
            (bool swap, address[] memory path) = _getPathForSwap(
                tokenIn,
                intermediaries[i],
                tokens[i]
            );
            uint256 usedBalance = IETFToken(ETFToken).getUsedBalance(tokens[i]);
            uint256 amountOut = bmul(ratio, usedBalance);
            if (swap) {
                uint256[] memory amountsIn = router.getAmountsIn(amountOut, path);
                uint256[] memory amounts = _swap(amountsIn[0], path, address(this));
                amountsToPool[i] = amounts[amounts.length - 1];
            } else {
                amountsToPool[i] = amountOut;
            }

            TransferHelper.safeApprove(tokens[i], ETFToken, amountsToPool[i]);
        }
        emit JoinSingle(poolAmountOut, amountsToPool);
        // IETFToken(ETFToken).joinPool(poolAmountOut, amountsToPool);
        // TransferHelper.safeTransfer(ETFToken, msg.sender, poolAmountOut);
    }

    function exitSingle(
        address[] memory intermediaries,
        uint256 poolAmountIn,
        address tokenOut,
        uint256 minAmountOut
    ) external returns (uint256 amountOutTotal) {
        // todo calc minAmountsOut
        address[] memory tokens = IETFToken(ETFToken).getCurrentTokens();
        require(
            tokens.length == intermediaries.length,
            "DexETF: Invalid arrays length"
        );
        uint256[] memory minAmountsOut;
        uint256 exitFee = bmul(poolAmountIn, IETFToken(ETFToken).EXIT_FEE());
        uint256 ratio = bdiv(bsub(poolAmountIn, exitFee), IERC20(ETFToken).totalSupply());
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 usedBalance = IETFToken(ETFToken).getUsedBalance(tokens[i]);
            uint256 amountOutExit = bmul(ratio, usedBalance);
            minAmountsOut[i] = amountOutExit;
        }

        amountOutTotal = _burnForAllTokensAndSwap(
            tokenOut,
            minAmountsOut,
            intermediaries,
            poolAmountIn,
            minAmountOut
        );
        
        TransferHelper.safeTransfer(tokenOut, msg.sender, amountOutTotal);
    }

    // external functions for view
    function getMaxAmountForJoinSingle(
        address tokenIn,
        address[] memory intermediaries,
        uint256 poolAmountOut
    ) public view returns (uint256 amountInMax) {
        address[] memory tokens = IETFToken(ETFToken).getCurrentTokens();
        require(
            tokens.length == intermediaries.length,
            "DexETF: Invalid arrays length"
        );
        uint256 ratio = bdiv(poolAmountOut, IERC20(ETFToken).totalSupply());
        for (uint256 i = 0; i < tokens.length; i++) {
            (bool swap, address[] memory path) = _getPathForSwap(
                tokenIn,
                intermediaries[i],
                tokens[i]
            );
            uint256 usedBalance = IETFToken(ETFToken).getUsedBalance(tokens[i]);
            uint256 amountOut = bmul(ratio, usedBalance);
            if (swap) {
                uint256[] memory amountsIn = router.getAmountsIn(amountOut, path);
                amountInMax = badd(amountInMax, amountsIn[0]);
            } else {
                amountInMax = badd(amountInMax, amountOut);
            }
        }
    }

    function getMaxAmountForExitSingle(
        address tokenOut,
        address[] memory intermediaries,
        uint256 poolAmountIn
    ) external view returns (uint256 amountOutMax) {
        address[] memory tokens = IETFToken(ETFToken).getCurrentTokens();
        require(
            tokens.length == intermediaries.length,
            "DexETF: Invalid arrays length"
        );
        uint256[] memory minAmountsOut;
        uint256 exitFee = bmul(poolAmountIn, IETFToken(ETFToken).EXIT_FEE());
        uint256 ratio = bdiv(bsub(poolAmountIn, exitFee), IERC20(ETFToken).totalSupply());

        for (uint256 i = 0; i < tokens.length; i++) {
            (bool swap, address[] memory path) = _getPathForSwap(
                tokens[i],
                intermediaries[i],
                tokenOut
            );
            uint256 usedBalance = IETFToken(ETFToken).getUsedBalance(tokens[i]);
            uint256 amountOutExit = bmul(ratio, usedBalance);

            if (swap) {
                uint256[] memory amountsOut = router.getAmountsOut(amountOutExit, path);
                amountOutMax = badd(amountOutMax, amountsOut[amountsOut.length - 1]);
            } else {
                amountOutMax = badd(amountOutMax, amountOutExit);
            }
        }
    }

    // internal functions
    function _getPathForSwap(
        address tokenIn,
        address intermediate,
        address tokenOut
    ) internal view returns (bool swap, address[] memory path) {
        if (tokenIn == tokenOut) return (swap, path);

        if (intermediate == address(0)) {
            address[] memory _paths = new address[](2);
            _paths[0] = tokenIn;
            _paths[1] = tokenOut;
            path = _paths;
        } else {
            address[] memory _paths = new address[](3);
            _paths[0] = tokenIn;
            _paths[1] = intermediate;
            _paths[2] = tokenOut;
            path = _paths;
        }
        swap = true;

        return (swap, path);
    }

    function _burnForAllTokensAndSwap(
        address tokenOut,
        uint256[] memory minAmountsOut,
        address[] memory intermediaries,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) internal returns (uint256 amountOutTotal) {
        TransferHelper.safeTransferFrom(
            ETFToken,
            msg.sender,
            address(this),
            poolAmountIn
        );
        address[] memory tokens = IETFToken(ETFToken).getCurrentTokens();
        require(
            intermediaries.length == tokens.length &&
                minAmountsOut.length == tokens.length,
            "DexETF: Invalid arrays length"
        );
        IETFToken(ETFToken).exitPool(poolAmountIn, minAmountsOut);
        amountOutTotal = _swapTokens(tokens, intermediaries, tokenOut);
        require(
            amountOutTotal >= minAmountOut,
            "DexETF: Insufficient output amount"
        );
    }

    function _swapTokens(
        address[] memory tokens,
        address[] memory intermediaries,
        address tokenOut
    ) private returns (uint256 amountOutTotal) {
        address this_ = address(this);
        for (uint256 i = 0; i < tokens.length; i++) {
            delete _path;
            address token = tokens[i];
            address intermediate = intermediaries[i];
            uint256 balance = IERC20(token).balanceOf(this_);
            if (token != tokenOut) {
                _path.push(token);
                if (intermediate != address(0)) _path.push(intermediate);
                _path.push(tokenOut);
                TransferHelper.safeApprove(token, address(router), balance);
                router.swapExactTokensForTokens(balance, 1, _path, this_, block.timestamp);
            }
        }
        return IERC20(tokenOut).balanceOf(this_);
    }

    function _swap(
        uint256 amountIn,
        address[] memory path,
        address to
    ) internal returns (uint256[] memory amounts){
        TransferHelper.safeApprove(path[0], address(router), amountIn);
        return router.swapExactTokensForTokens(amountIn, 1, path, to, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BConst.sol";

contract BNum {
  uint256 internal constant BONE = 10**18;
  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;

  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }

  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "DexETF: Add overflow");
    return c;
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "DexETF: Sub overflow");
    return c;
  }

  function bsubSign(uint256 a, uint256 b)
    internal
    pure
    returns (uint256, bool)
  {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "DexETF: Mul overflow");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "DexETF: Mul overflow");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "DexETF: Div zero");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "DexETF: Div overflow");
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "DexETF: Div overflow");
    uint256 c2 = c1 / b;
    return c2;
  }

  function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
    uint256 z = n % 2 != 0 ? a : BONE;
    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);
      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
    require(base >= MIN_BPOW_BASE, "DexETF: Bpow base too low");
    require(base <= MAX_BPOW_BASE, "DexETF: Bpow base too high");
    uint256 whole = bfloor(exp);
    uint256 remain = bsub(exp, whole);
    uint256 wholePow = bpowi(base, btoi(whole));
    if (remain == 0) {
      return wholePow;
    }
    uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint256 base,
    uint256 exp,
    uint256 precision
  ) internal pure returns (uint256) {
    uint256 a = exp;
    (uint256 x, bool xneg) = bsubSign(base, BONE);
    uint256 term = BONE;
    uint256 sum = term;
    bool negative = false;
    for (uint256 i = 1; term >= precision; i++) {
      uint256 bigK = i * BONE;
      (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
      term = bmul(term, bmul(c, x));
      term = bdiv(term, bigK);
      if (term == 0) break;
      if (xneg) negative = !negative;
      if (cneg) negative = !negative;
      if (negative) {
        sum = bsub(sum, term);
      } else {
        sum = badd(sum, term);
      }
    }
    return sum;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BConst {
  // uint256 internal constant WEIGHT_UPDATE_DELAY = 1 hours;
  // uint256 internal constant WEIGHT_CHANGE_PCT = BONE / 100;
  // uint256 internal constant BONE = 10**18;
  // uint256 internal constant MIN_BOUND_TOKENS = 2;
  // uint256 internal constant MAX_BOUND_TOKENS = 25;
  // uint256 internal constant EXIT_FEE = 1e16;
  // uint256 internal constant MIN_WEIGHT = BONE / 8;
  // uint256 internal constant MAX_WEIGHT = BONE * 25;
  // uint256 internal constant MAX_TOTAL_WEIGHT = BONE * 26;
  // uint256 internal constant MIN_BALANCE = BONE / 10**12;
  // uint256 internal constant INIT_POOL_SUPPLY = BONE * 10;
  // uint256 internal constant MIN_BPOW_BASE = 1 wei;
  // uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  // uint256 internal constant BPOW_PRECISION = BONE / 10**10;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IUniswapV2Router {
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

    function addLiquidityAVAX(
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

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IETFToken {
    /**
     * @dev Token record data structure
     * @param bound is token bound to pool
     * @param ready has token been initialized
     * @param index index of address in tokens array
     * @param balance token balance
     */
    struct Record {
        bool bound;
        bool ready;
        uint8 index;
        uint256 balance;
    }

    function EXIT_FEE() external view returns (uint256);

    function INIT_POOL_SUPPLY() external view returns (uint256);

    function MAX_BOUND_TOKENS() external view returns (uint256);

    function MIN_BALANCE() external view returns (uint256);

    function MIN_BOUND_TOKENS() external view returns (uint256);

    function addTokenAsset(address token, uint256 minimumBalance) external;

    function exitFeeRecipient() external view returns (address);

    function exitPool(uint256 poolAmountIn, uint256[] memory minAmountsOut) external;

    function getBalance(address token) external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory currentTokens);

    function getMinimumBalance(address token) external view returns (uint256);

    function getNumTokens() external view returns (uint256);

    function getTokenRecord(address token) external view returns (Record memory record);

    function getUsedBalance(address token) external view returns (uint256);

    function initialize(
        address[] memory tokens,
        uint256[] memory balances,
        address tokenProvider
    ) external;

    function isBound(address token) external view returns (bool);

    function joinPool(uint256 poolAmountOut, uint256[] memory maxAmountsIn) external;

    function maxPoolTokens() external view returns (uint256);

    function removeTokenAsset(address token) external;

    function setExitFeeRecipient(address _exitFeeRecipient) external;

    function setMaxPoolTokens(uint256 _maxPoolTokens) external;

    function setMinimumBalance(address token, uint256 minimumBalance) external;
}

// SPDX-License-Identifier: MIT
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