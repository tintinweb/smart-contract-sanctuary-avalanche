/**
 *Submitted for verification at snowtrace.io on 2022-03-07
*/

/**
 *Submitted for verification at snowtrace.io on 2022-02-27
 */

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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
  function transferFrom(
    address sender,
    address recipient,
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

library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{ value: value }(new bytes(0));
    require(success, "TransferHelper: ETH_TRANSFER_FAILED");
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: Zap.sol

contract Zap is Ownable {
  /* ========== STATE VARIABLES ========== */

  address private WNATIVE = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

  mapping(address => mapping(address => address)) private tokenBridgeForRouter;

  mapping(address => bool) public useNativeRouter;

  /* ========== External Functions ========== */

  receive() external payable {}

  function zapIn(
    address _to,
    address routerAddr,
    address _recipient
  ) external payable {
    // from Native to an LP token through the specified router
    _swapNativeToLP(_to, msg.value, _recipient, routerAddr);
  }

  function estimateZapIn(
    address _LP,
    address _router,
    uint256 _amt
  ) public view returns (uint256, uint256) {
    uint256 zapAmt = _amt / 2;

    IUniswapV2Pair pair = IUniswapV2Pair(_LP);
    address token0 = pair.token0();
    address token1 = pair.token1();

    if (token0 == WNATIVE || token1 == WNATIVE) {
      address token = token0 == WNATIVE ? token1 : token0;
      uint256 tokenAmt = _estimateSwap(WNATIVE, zapAmt, token, _router);
      if (token0 == WNATIVE) {
        return (zapAmt, tokenAmt);
      } else {
        return (tokenAmt, zapAmt);
      }
    } else {
      uint256 token0Amt = _estimateSwap(WNATIVE, zapAmt, token0, _router);
      uint256 token1Amt = _estimateSwap(WNATIVE, zapAmt, token1, _router);

      return (token0Amt, token1Amt);
    }
  }

  function swapToNative(
    address _from,
    uint256 amount,
    address routerAddr,
    address _recipient
  ) external {
    IERC20(_from).transferFrom(msg.sender, address(this), amount);
    _approveTokenIfNeeded(_from, routerAddr);
    _swapTokenForNative(_from, amount, _recipient, routerAddr);
  }

  /* ========== Private Functions ========== */

  function _approveTokenIfNeeded(address token, address router) private {
    if (IERC20(token).allowance(address(this), router) == 0) {
      IERC20(token).approve(router, type(uint256).max);
    }
  }

  function _swapNativeToLP(
    address _LP,
    uint256 amount,
    address recipient,
    address routerAddress
  ) private returns (uint256) {
    // LP
    IUniswapV2Pair pair = IUniswapV2Pair(_LP);
    address token0 = pair.token0();
    address token1 = pair.token1();
    uint256 liquidity;
    if (token0 == WNATIVE || token1 == WNATIVE) {
      address token = token0 == WNATIVE ? token1 : token0;
      (, , liquidity) = _swapHalfNativeAndProvide(token, amount, routerAddress, recipient);
    } else {
      (, , liquidity) = _swapNativeToEqualTokensAndProvide(token0, token1, amount, routerAddress, recipient);
    }
    return liquidity;
  }

  function _swapHalfNativeAndProvide(
    address token,
    uint256 amount,
    address routerAddress,
    address recipient
  )
    private
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 swapValue = amount / 2;
    uint256 tokenAmount = _swapNativeForToken(token, swapValue, address(this), routerAddress);
    _approveTokenIfNeeded(token, routerAddress);
    if (useNativeRouter[routerAddress]) {
      IJoeRouter01 router = IJoeRouter01(routerAddress);
      return
        router.addLiquidityAVAX{ value: (amount - swapValue) }(token, tokenAmount, 0, 0, recipient, block.timestamp);
    } else {
      IJoeRouter01 router = IJoeRouter01(routerAddress);
      return
        router.addLiquidityAVAX{ value: (amount - swapValue) }(token, tokenAmount, 0, 0, recipient, block.timestamp);
    }
  }

  function _swapNativeToEqualTokensAndProvide(
    address token0,
    address token1,
    uint256 amount,
    address routerAddress,
    address recipient
  )
    private
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 swapValue = amount / 2;
    uint256 token0Amount = _swapNativeForToken(token0, swapValue, address(this), routerAddress);
    uint256 token1Amount = _swapNativeForToken(token1, amount - swapValue, address(this), routerAddress);
    _approveTokenIfNeeded(token0, routerAddress);
    _approveTokenIfNeeded(token1, routerAddress);
    IJoeRouter01 router = IJoeRouter01(routerAddress);
    return router.addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, recipient, block.timestamp);
  }

  function _swapNativeForToken(
    address token,
    uint256 value,
    address recipient,
    address routerAddr
  ) private returns (uint256) {
    address[] memory path;
    IJoeRouter01 router = IJoeRouter01(routerAddr);

    if (tokenBridgeForRouter[token][routerAddr] != address(0)) {
      path = new address[](3);
      path[0] = WNATIVE;
      path[1] = tokenBridgeForRouter[token][routerAddr];
      path[2] = token;
    } else {
      path = new address[](2);
      path[0] = WNATIVE;
      path[1] = token;
    }

    uint256[] memory amounts = router.swapExactAVAXForTokens{ value: value }(0, path, recipient, block.timestamp);
    return amounts[amounts.length - 1];
  }

  function _swapTokenForNative(
    address token,
    uint256 amount,
    address recipient,
    address routerAddr
  ) private returns (uint256) {
    address[] memory path;
    IJoeRouter01 router = IJoeRouter01(routerAddr);

    if (tokenBridgeForRouter[token][routerAddr] != address(0)) {
      path = new address[](3);
      path[0] = token;
      path[1] = tokenBridgeForRouter[token][routerAddr];
      path[2] = router.WAVAX();
    } else {
      path = new address[](2);
      path[0] = token;
      path[1] = router.WAVAX();
    }

    uint256[] memory amounts = router.swapExactTokensForAVAX(amount, 0, path, recipient, block.timestamp);
    return amounts[amounts.length - 1];
  }

  function _estimateSwap(
    address _from,
    uint256 amount,
    address _to,
    address routerAddr
  ) private view returns (uint256) {
    IJoeRouter01 router = IJoeRouter01(routerAddr);

    address fromBridge = tokenBridgeForRouter[_from][routerAddr];
    address toBridge = tokenBridgeForRouter[_to][routerAddr];

    address[] memory path;

    if (fromBridge != address(0) && toBridge != address(0)) {
      if (fromBridge != toBridge) {
        path = new address[](5);
        path[0] = _from;
        path[1] = fromBridge;
        path[2] = WNATIVE;
        path[3] = toBridge;
        path[4] = _to;
      } else {
        path = new address[](3);
        path[0] = _from;
        path[1] = fromBridge;
        path[2] = _to;
      }
    } else if (fromBridge != address(0)) {
      if (_to == WNATIVE) {
        path = new address[](3);
        path[0] = _from;
        path[1] = fromBridge;
        path[2] = WNATIVE;
      } else {
        path = new address[](4);
        path[0] = _from;
        path[1] = fromBridge;
        path[2] = WNATIVE;
        path[3] = _to;
      }
    } else if (toBridge != address(0)) {
      path = new address[](4);
      path[0] = _from;
      path[1] = WNATIVE;
      path[2] = toBridge;
      path[3] = _to;
    } else if (_from == WNATIVE || _to == WNATIVE) {
      path = new address[](2);
      path[0] = _from;
      path[1] = _to;
    } else {
      // Go through WNative
      path = new address[](3);
      path[0] = _from;
      path[1] = WNATIVE;
      path[2] = _to;
    }

    uint256[] memory amounts = router.getAmountsOut(amount, path);
    return amounts[amounts.length - 1];
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setTokenBridgeForRouter(
    address token,
    address router,
    address bridgeToken
  ) external onlyOwner {
    tokenBridgeForRouter[token][router] = bridgeToken;
  }

  function withdraw(address token) external onlyOwner {
    if (token == address(0)) {
      payable(owner()).transfer(address(this).balance);
      return;
    }

    IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
  }

  function setUseNativeRouter(address router) external onlyOwner {
    useNativeRouter[router] = true;
  }
}