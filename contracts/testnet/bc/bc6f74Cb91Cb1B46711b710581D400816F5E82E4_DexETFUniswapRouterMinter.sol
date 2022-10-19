// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IIndexPool.sol";
import "../lib/TransferHelper.sol";
import "../lib/UniswapV2Library.sol";

contract DexETFUniswapRouterMinter {
  address public immutable factory;
  address public immutable weth;
  address public multisig;
  uint256 public fee;

  function getMaxAmountForJoin(
    address tokenIn,
    address[] memory intermediaries,
    address indexPool,
    uint256 poolAmountOut
  ) external view returns (uint256 amountInMax) {
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(
      tokens.length == intermediaries.length,
      "DexETF: Invalid arrays length"
    );
    uint256 ratio = poolAmountOut / IERC20(indexPool).totalSupply();
    address[] memory path = new address[](3);
    path[0] = tokenIn;
    for (uint256 i = 0; i < tokens.length; i++) {
      (uint256[] memory amounts,) = _getSwapAmountsForJoin(
        indexPool,
        intermediaries[i],
        tokens[i],
        path,
        ratio
      );
      amountInMax = amountInMax + amounts[0];
    }
    amountInMax = amountInMax + amountInMax * fee / 10000;
  }

  constructor(address factory_, address weth_, address multisig_, uint256 fee_) {
    address zero = address(0);
    require(factory_ != zero, "DexETF: Factory is zero address");
    require(weth_ != zero, "DexETF: WETH is zero address");
    require(multisig_ != zero, "DexETF: Multisig is zero address");
    require(fee_ < 10000, "DexETF: Fee overflow");
    factory = factory_;
    weth = weth_;
    multisig = multisig_;
    fee = fee_;
  }

  receive() external payable {
    require(msg.sender == weth, "DexETF: Received ether");
  }

  function updateFee(uint256 fee_) external {
    require(msg.sender == multisig, "DexETF: Only multisig can update fee");
    require(fee_ < 10000, "DexETF: Fee overflow");
    fee = fee_;
  }

  function updateMultisig(address multisig_) external {
    require(msg.sender == multisig, "DexETF: Only multisig can update fee");
    require(multisig_ != address(0), "DexETF: Multisig is zero address");
    multisig = multisig_;
  }

  function swapTokensForAllTokensAndMintExact(
    address tokenIn,
    uint256 amountInMax,
    address[] memory intermediaries,
    address indexPool,
    uint256 poolAmountOut
  ) external returns (uint256 amountInTotal) {
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(
      tokens.length == intermediaries.length,
      "DexETF: Invalid arrays length"
    );
    uint256[] memory amountsToPool = new uint256[](tokens.length);
    uint256 ratio = poolAmountOut / IERC20(indexPool).totalSupply();
    address[] memory path = new address[](3);
    path[0] = tokenIn;
    (amountInMax, amountInTotal) = _collectFee(tokenIn, amountInMax, false);
    for (uint256 i = 0; i < tokens.length; i++) {
      (uint256[] memory amounts, bool swap) = _getSwapAmountsForJoin(
        indexPool,
        intermediaries[i],
        tokens[i],
        path,
        ratio
      );
      amountInMax = amountInMax - amounts[0];
      TransferHelper.safeTransferFrom(
        path[0],
        msg.sender,
        swap ? UniswapV2Library.pairFor(factory, path[0], path[1]) : address(this),
        amounts[0]
      );
      if (swap) _swap(amounts, path);
      uint256 amountToPool = amounts[amounts.length - 1];
      amountsToPool[i] = amountToPool;
      amountInTotal = amountInTotal + amounts[0];
      TransferHelper.safeApprove(tokens[i], indexPool, amountToPool);
    }
    IIndexPool(indexPool).joinPool(poolAmountOut, amountsToPool);
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
  }

  function swapETHForAllTokensAndMintExact(
    address indexPool,
    address[] memory intermediaries,
    uint256 poolAmountOut
  ) external payable returns (uint256 amountInTotal) {
    uint256 amountInMax = msg.value;
    IWETH(weth).deposit{value: msg.value}();
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(
      tokens.length == intermediaries.length,
      "DexETF: Invalid arrays length"
    );
    uint256[] memory amountsToPool = new uint256[](tokens.length);
    uint256 ratio = poolAmountOut / IERC20(indexPool).totalSupply();
    address[] memory path = new address[](3);
    path[0] = weth;
    (amountInMax, amountInTotal) = _collectFee(weth, amountInMax, true);
    for (uint256 i = 0; i < tokens.length; i++) {
      (uint256[] memory amounts, bool swap) = _getSwapAmountsForJoin(
        indexPool,
        intermediaries[i],
        tokens[i],
        path,
        ratio
      );
      amountInMax = amountInMax - amounts[0];
      if (swap) {
        require(
          IWETH(weth).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]),
          "DexETF: Wrapped transfer fail"
        );
        _swap(amounts, path);
      }
      uint256 amountToPool = amounts[amounts.length - 1];
      amountsToPool[i] = amountToPool;
      amountInTotal = amountInTotal + amounts[0];
      TransferHelper.safeApprove(tokens[i], indexPool, amountToPool);
    }
    IIndexPool(indexPool).joinPool(poolAmountOut, amountsToPool);
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
    if (msg.value > amountInTotal) {
      uint256 remainder = msg.value - amountInTotal;
      IWETH(weth).withdraw(remainder);
      TransferHelper.safeTransferETH(msg.sender, remainder);
    }
  }

  function _swap(uint256[] memory amounts, address[] memory path) internal {
    for (uint256 i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, address token1) = UniswapV2Library.sortTokens(input, output);
      uint256 amountOut = amounts[i + 1];
      (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : address(this);
      IUniswapV2Pair(UniswapV2Library.calculatePair(factory, token0, token1)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  function _getSwapAmountsForJoin(
    address indexPool,
    address intermediate,
    address poolToken,
    address[] memory path,
    uint256 poolRatio
  ) internal view returns (uint256[] memory amounts, bool swap) {
    if (intermediate == address(0)) {
      assembly { mstore(path, 2) }
      path[1] = poolToken;
    } else {
      assembly { mstore(path, 3) }
      path[1] = intermediate;
      path[2] = poolToken;
    }
    uint256 usedBalance = IIndexPool(indexPool).getUsedBalance(poolToken);
    uint256 amountToPool = poolRatio * usedBalance;
    if (path[0] == poolToken) {
      amounts = new uint256[](1);
      amounts[0] = amountToPool;
      return (amounts, swap);
    }
    amounts = UniswapV2Library.getAmountsIn(factory, amountToPool, path);
    swap = true;
  }

  function _collectFee(
    address tokenIn,
    uint256 amountInMax,
    bool isWeth
  ) private returns (uint256 newAmountInMax, uint256 feeAmount) {
    feeAmount = amountInMax * fee / 10000;
    if (isWeth) {
      TransferHelper.safeTransfer(tokenIn, multisig, feeAmount);
    } else {
      TransferHelper.safeTransferFrom(tokenIn, msg.sender, multisig, feeAmount);
    }
    newAmountInMax = SafeMath.sub(amountInMax, feeAmount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";

library UniswapV2Library {
    using SafeMath for uint256;
    function calculatePair(
        address factory,
        address token0,
        address token1
    ) internal view returns (address pair) {
        IUniswapV2Factory _factory = IUniswapV2Factory(factory);
        pair = _factory.getPair(token0, token1);
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        uint256 temp = uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            );
        pair = address(uint160(temp));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IUniswapV2Pair {
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
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
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

interface IIndexPool {
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

  function isBound(address token) external view returns (bool);
  function getNumTokens() external view returns (uint256);
  function getCurrentTokens() external view returns (address[] memory tokens);
  function getTokenRecord(address token) external view returns (Record memory record);
  function getBalance(address token) external view returns (uint256);
  function getMinimumBalance(address token) external view returns (uint256);
  function getUsedBalance(address token) external view returns (uint256);

  function initialize(address[] memory tokens, uint256[] memory balances, address tokenProvider) external;
  function setMaxPoolTokens(uint256 maxPoolTokens) external;
  function setExitFeeRecipient(address _exitFeeRecipient) external;
  function setMinimumBalance(address token, uint256 minimumBalance) external;
  function joinPool(uint256 poolAmountOut, uint256[] memory maxAmountsIn) external;
  function exitPool(uint256 poolAmountIn, uint256[] memory minAmountsOut) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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