// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import './interfaces/IUniswapV2Router.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IERC20.sol';

// @author Daniel Espendiller - https://github.com/Haehnchen/uniswap-arbitrage-flash-swap - espend.de
//
// e00: out of block
// e01: no profit
// e10: Requested pair is not available
// e11: token0 / token1 does not exist
// e12: src/target router empty
// e13: pancakeCall not enough tokens for buyback
// e14: pancakeCall msg.sender transfer failed
// e15: pancakeCall owner transfer failed
// e16
contract Flashswap {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function start(
        uint _maxBlockNumber,
        address _tokenBorrow, // example BUSD
        uint256 _amountTokenPay, // example: BNB => 10 * 1e18
        address _tokenPay, // our profit and what we will get; example BNB
        address _sourceRouter,
        address _targetRouter,
        address _sourceFactory
    ) external {
        require(block.number <= _maxBlockNumber, 'e00');

        // recheck for stopping and gas usage
        (int256 profit, uint256 _tokenBorrowAmount) = check(_tokenBorrow, _amountTokenPay, _tokenPay, _sourceRouter, _targetRouter);
        require(profit > 0, 'e01');

        address pairAddress = IUniswapV2Factory(_sourceFactory).getPair(_tokenBorrow, _tokenPay); // is it cheaper to compute this locally?
        require(pairAddress != address(0), 'e10');

        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();

        require(token0 != address(0) && token1 != address(0), 'e11');

        IUniswapV2Pair(pairAddress).swap(
            _tokenBorrow == token0 ? _tokenBorrowAmount : 0,
            _tokenBorrow == token1 ? _tokenBorrowAmount : 0,
            address(this),
            abi.encode(_sourceRouter, _targetRouter)
        );
    }

    function check(
        address _tokenBorrow, // example: BUSD
        uint256 _amountTokenPay, // example: BNB => 10 * 1e18
        address _tokenPay, // example: BNB
        address _sourceRouter,
        address _targetRouter
    ) public view returns(int256, uint256) {
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);
        path1[0] = path2[1] = _tokenPay;
        path1[1] = path2[0] = _tokenBorrow;

        uint256 amountOut = IUniswapV2Router(_sourceRouter).getAmountsOut(_amountTokenPay, path1)[1];
        uint256 amountRepay = IUniswapV2Router(_targetRouter).getAmountsOut(amountOut, path2)[1];

        return (
            int256(amountRepay - _amountTokenPay), // our profit or loss; example output: BNB amount
            amountOut // the amount we get from our input "_amountTokenPay"; example: BUSD amount
        );
    }

    function execute(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) internal {
        // obtain an amount of token that you exchanged
        uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;

        IUniswapV2Pair iUniswapV2Pair = IUniswapV2Pair(msg.sender);
        address token0 = iUniswapV2Pair.token0();
        address token1 = iUniswapV2Pair.token1();

        // require(token0 != address(0) && token1 != address(0), 'e16');

        // if _amount0 is zero sell token1 for token0
        // else sell token0 for token1 as a result
        address[] memory path1 = new address[](2);
        address[] memory path = new address[](2);
        path[0] = path1[1] = _amount0 == 0 ? token1 : token0; // c&p
        path[1] = path1[0] = _amount0 == 0 ? token0 : token1; // c&p

        (address sourceRouter, address targetRouter) = abi.decode(_data, (address, address));
        require(sourceRouter != address(0) && targetRouter != address(0), 'e12');

        // IERC20 token that we will sell for otherToken
        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
        token.approve(targetRouter, amountToken);

        // calculate the amount of token how much input token should be reimbursed
        uint256 amountRequired = IUniswapV2Router(sourceRouter).getAmountsIn(amountToken, path1)[0];

        // swap token and obtain equivalent otherToken amountRequired as a result
        uint256 amountReceived = IUniswapV2Router(targetRouter).swapExactTokensForTokens(
            amountToken,
            amountRequired, // we already now what we need at least for payback; get less is a fail; slippage can be done via - ((amountRequired * 19) / 981) + 1,
            path,
            address(this), // its a foreign call; from router but we need contract address also equal to "_sender"
            block.timestamp + 60
        )[1];

        // fail if we didn't get enough tokens
        require(amountReceived > amountRequired, 'e13');

        IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);

        // transfer failing already have error message
        otherToken.transfer(msg.sender, amountRequired); // send back borrow
        otherToken.transfer(owner, amountReceived - amountRequired); // our win
    }

    // pancake, pancakeV2, apeswap, kebab
    function pancakeCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    function waultSwapCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // mdex
    function swapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // pantherswap
    function pantherCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // jetswap
    function jetswapCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // cafeswap
    function cafeCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // @TODO: pending release
    function BiswapCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // @TODO: pending release
    function wardenCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);
  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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