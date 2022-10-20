// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IETFToken.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../lib/TransferHelper.sol";
import "../lib/UniswapV2Library.sol";
import "../utils/ContractGuard.sol";

contract ETFZapper is ContractGuard  {
    address public immutable factory;
    address public immutable ETFToken;
    IUniswapV2Router public immutable router;
    uint256 public immutable DECIMALS = 1e18;
    address[] private _path;

    constructor(address factory_, address router_, address ETFToken_) {
        address zero = address(0);
        require(factory_ != zero, "DexETF: Factory is zero address");
        require(router_ != zero, "DexETF: Router is zero address");
        require(ETFToken_ != zero, "DexETF: ETFToken is zero address");
        ETFToken = ETFToken_;
        factory = factory_;
        router = IUniswapV2Router(router_);
    }

    function joinMulti(
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
        uint256 ratio = poolAmountOut * DECIMALS / IERC20(ETFToken).totalSupply();
        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256[] memory amounts, bool swap, address[] memory path) = _getSwapAmountsForJoin(
                tokenIn,
                intermediaries[i],
                tokens[i],
                ratio
            );
            amountInMax = amountInMax - amounts[0];
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                swap
                    ? UniswapV2Library.pairFor(factory, path[0], path[1])
                    : address(this),
                amounts[0]
            );
            if (swap) _swap(amounts, path);
            uint256 amountToPool = amounts[amounts.length - 1];
            amountsToPool[i] = amountToPool;
            amountInTotal = amountInTotal + amounts[0];
            TransferHelper.safeApprove(tokens[i], ETFToken, amountToPool);
        }
        IETFToken(ETFToken).joinPool(poolAmountOut, amountsToPool);
        TransferHelper.safeTransfer(ETFToken, msg.sender, poolAmountOut);
    }

    function exitMulti(
        // uint256[] memory minAmountsOut, //rm
        address[] memory intermediaries,
        uint256 poolAmountIn,
        address tokenOut,
        uint256 minAmountOut
    ) external onlyOneBlock returns (uint256 amountOutTotal) {
        // todo calc minAmountsOut
        address[] memory tokens = IETFToken(ETFToken).getCurrentTokens();
        require(
            tokens.length == intermediaries.length,
            "DexETF: Invalid arrays length"
        );
        uint256[] memory minAmountsOut;
        uint256 exitFee = poolAmountIn * IETFToken(ETFToken).EXIT_FEE() / 1e18;
        uint256 ratio = (poolAmountIn - exitFee) * DECIMALS / IERC20(ETFToken).totalSupply();
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 usedBalance = IETFToken(ETFToken).getUsedBalance(tokens[i]);
            uint256 amountToPool = ratio * usedBalance / DECIMALS;
            minAmountsOut[i] = amountToPool;
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
    function getMaxAmountForJoinMulti(
        address tokenIn,
        address[] memory intermediaries,
        uint256 poolAmountOut
    ) external view returns (uint256 amountInMax) {
        address[] memory tokens = IETFToken(ETFToken).getCurrentTokens();
        require(
            tokens.length == intermediaries.length,
            "DexETF: Invalid arrays length"
        );
        uint256 ratio = poolAmountOut * DECIMALS / IERC20(ETFToken).totalSupply();
        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256[] memory amounts, , ) = _getSwapAmountsForJoin(
                tokenIn,
                intermediaries[i],
                tokens[i],
                ratio
            );
            amountInMax += 1;//amounts[0];
        }
    }

    function getMaxAmountForExitMulti(
        address tokenOut,
        address[] memory intermediaries,
        uint256 poolAmountIn
    ) external view returns (uint256 amountOutMax) {
        address[] memory tokens = IETFToken(ETFToken).getCurrentTokens();
        require(
            tokens.length == intermediaries.length,
            "DexETF: Invalid arrays length"
        );
        uint256 exitFee = poolAmountIn * IETFToken(ETFToken).EXIT_FEE() / 1e18; // todo
        uint256 pAiAfterExitFee = poolAmountIn - exitFee;
        uint256 ratio = pAiAfterExitFee * DECIMALS / IERC20(ETFToken).totalSupply();

        for (uint256 i = 0; i < tokens.length; i++) {
            // (uint256[] memory amounts, , ) = _getSwapAmountsForExit(
            //     tokens[i],
            //     intermediaries[i],
            //     tokenOut,
            //     ratio
            // );
            amountOutMax += 1;//amounts[amounts.length - 1];
        }
    }

    // internal functions
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
        address zero = address(0);
        address this_ = address(this);
        uint256 time = block.timestamp;
        for (uint256 i = 0; i < tokens.length; i++) {
            delete _path;
            address token = tokens[i];
            address intermediate = intermediaries[i];
            uint256 balance = IERC20(token).balanceOf(this_);
            if (token != tokenOut) {
                _path.push(token);
                if (intermediate != zero) _path.push(intermediate);
                _path.push(tokenOut);
                TransferHelper.safeApprove(token, address(router), balance);
                router.swapExactTokensForTokens(balance, 1, _path, this_, time);
            }
        }
        return IERC20(tokenOut).balanceOf(this_);
    }

    function _swap(uint256[] memory amounts, address[] memory path) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, address token1) = UniswapV2Library.sortTokens(
                input,
                output
            );
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint(0), amountOut)
                : (amountOut, uint(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(factory, output, path[i + 2])
                : address(this);
            IUniswapV2Pair(
                UniswapV2Library.calculatePair(factory, token0, token1)
            ).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function _getSwapAmountsForJoin(
        address tokenIn,
        address intermediate,
        address tokenOut,
        uint256 ratio
    ) internal view returns (uint256[] memory amounts, bool swap, address[] memory path) {
        uint256 usedBalance = IETFToken(ETFToken).getUsedBalance(tokenOut);
        uint256 amountToPool = ratio * usedBalance / DECIMALS;
        if (tokenIn == tokenOut) {
            amounts[0] = amountToPool;
            return (amounts, swap, path);
        }

        path[0] = tokenIn;
        if (intermediate == address(0)) {
            path[1] = tokenOut;
        } else {
            path[1] = intermediate;
            path[2] = tokenOut;
        }
        amounts = UniswapV2Library.getAmountsIn(factory, amountToPool, path);
        swap = true;
    }

    function _getSwapAmountsForExit(
        address tokenIn,
        address intermediate,
        address tokenOut,
        uint256 ratio
    ) internal view returns (uint256[] memory amounts, bool swap, address[] memory path) {
        uint256 usedBalance = IETFToken(ETFToken).getUsedBalance(tokenIn);
        uint256 amountInPool = ratio * usedBalance / DECIMALS;

        if (tokenIn == tokenOut) {
            amounts[0] = amountInPool;
            return (amounts, swap, path);
        }

        path[0] = tokenIn;
        if (intermediate == address(0)) {
            path[1] = tokenOut;
        } else {
            path[1] = intermediate;
            path[2] = tokenOut;
        }
        amounts = UniswapV2Library.getAmountsOut(factory, amountInPool, path);
        swap = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;

        _;
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
    ) internal view returns (address pair) {
        IUniswapV2Factory _factory = IUniswapV2Factory(factory);
        pair = _factory.getPair(tokenA, tokenB);
        // (address token0, address token1) = sortTokens(tokenA, tokenB);
        // uint256 temp = uint256(
        //         keccak256(
        //             abi.encodePacked(
        //                 hex"ff",
        //                 factory,
        //                 keccak256(abi.encodePacked(token0, token1)),
        //                 hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
        //             )
        //         )
        //     );
        // pair = address(uint160(temp));
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