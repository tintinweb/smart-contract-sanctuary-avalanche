// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IETFToken.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../lib/TransferHelper.sol";
import "../lib/BNum.sol";

contract ETFZapper is BNum {
    using SafeERC20 for IERC20;
    IUniswapV2Factory public factory;
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
        factory = IUniswapV2Factory(factory_);
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

            // IERC20(tokens[i]).approve(ETFToken, amountsToPool[i]);
        }
        emit JoinSingle(poolAmountOut, amountsToPool);
        // IETFToken(ETFToken).joinPool(poolAmountOut, amountsToPool);
        // IERC20(ETFToken).transfer(msg.sender, poolAmountOut);
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
        
        IERC20(tokenOut).transfer(msg.sender, amountOutTotal);
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
        IERC20(ETFToken).transferFrom(
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
    ) private returns (uint256 amountOutTotal) {// todo
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
                IERC20(token).approve(address(router), balance);
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
        // for (uint256 i = 1; i < path.length; i++) {
        //     address pair = factory.getPair(path[i], path[i - 1]);
        //     IERC20(path[i - 1]).approve(pair, amountIn);
        // }

        IERC20(path[0]).approve(address(router), amountIn);
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

pragma solidity 0.8.13;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    
    function pairCodeHash() external pure returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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