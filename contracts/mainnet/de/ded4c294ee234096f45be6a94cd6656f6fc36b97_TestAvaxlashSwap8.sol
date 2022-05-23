/**
 *Submitted for verification at snowtrace.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPangolinERC20 {
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
}

interface IUniswapV2Router {
  function getAmountsOut(uint amountIn, address[] memory path)
    external
    view
    returns (uint[] memory amounts);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForAVAX(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactAVAXForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
}

interface IUniswapV2Pair {
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

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}

interface IPangolinCallee {
  function pangolinCall(
    address sender,
    uint amount0,
    uint amount1,
    bytes calldata data
  ) external;
}

contract TestAvaxlashSwap8 is IPangolinCallee {
  // Uniswap V2 router
  // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  address private constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
  // Uniswap V2 factory
  address private constant FACTORY = 0xefa94DE7a4656D787667C749f7E1223D71E9FD88;

  address private constant PANGOLIN_ROUTER = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;

  address private constant JOE_ROUTER = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;

  event Log(string message, uint val);
  address private immutable owner;

  constructor() public payable {
    owner = msg.sender;
  }

  receive() external payable {
  }

  function getAmountOutMin(
    address _tokenIn,
    address _tokenOut,
    uint _amountIn,
    address ROUTER
    ) internal view returns (uint) {
        address[] memory path;
        if (_tokenIn == WAVAX || _tokenOut == WAVAX) {
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;                
        } else {
        path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WAVAX;
        path[2] = _tokenOut;
        }

        uint[] memory amountOutMins = IUniswapV2Router(ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }


  function swap(
    string memory _routerAddress,  
    address _tokenIn,
    address _tokenOut,
    uint _amountIn
    ) internal {
        address ROUTER;
        if (keccak256(abi.encodePacked(_routerAddress)) == keccak256(abi.encodePacked("pangolin"))) {
            ROUTER = PANGOLIN_ROUTER;
        } else {
            ROUTER = JOE_ROUTER;
        }

        uint _amountOutMin = getAmountOutMin(_tokenIn, _tokenOut, _amountIn, ROUTER);

        IPangolinERC20(_tokenIn).approve(ROUTER, _amountIn);

        address[] memory path;
        if (_tokenIn == WAVAX || _tokenOut == WAVAX) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WAVAX;
            path[2] = _tokenOut;
        }

        IUniswapV2Router(ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

  modifier onlyOwner() {
    require (msg.sender == owner);
    _;
    }
  
  function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IPangolinERC20 tokenContract = IPangolinERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }



  function testFlashSwap(address _tokenBorrow, uint _amount, address _arbtoken, address _intermediary,
  string memory _option) external payable {
    address pair = IUniswapV2Factory(FACTORY).getPair(_tokenBorrow, WAVAX);
    require(pair != address(0), "!pair");

    address token0 = IUniswapV2Pair(pair).token0();
    address token1 = IUniswapV2Pair(pair).token1();
    uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
    uint amount1Out = _tokenBorrow == token1 ? _amount : 0;

    // need to pass some data to trigger uniswapV2Call
    bytes memory data = abi.encode(_tokenBorrow, _amount, _arbtoken, _intermediary,_option);
    emit Log("Attempting swap now", 6);

    IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
  }

  // called by pair contract
  function pangolinCall(
    address _sender,
    uint _amount0,
    uint _amount1,
    bytes calldata _data
  ) external override {
    address token0 = IUniswapV2Pair(msg.sender).token0();
    address token1 = IUniswapV2Pair(msg.sender).token1();
    address pair = IUniswapV2Factory(FACTORY).getPair(token0, token1);
    require(msg.sender == pair, "!pair");
    require(_sender == address(this), "!sender");

    (address tokenBorrow, uint amount, address arbtoken, address intermediary, string memory option) = abi.decode(_data, (address, uint, address, address, string));

    // about 0.3%
    uint fee = ((amount * 3) / 997) + 1;
    uint amountToRepay = amount + fee;
    emit Log("Attempting swap now", 7);

    if (keccak256(abi.encodePacked(option)) == keccak256(abi.encodePacked("PangolinFirst"))) {
        swap("pangolin", tokenBorrow, intermediary, amount);
        uint amount2 = IPangolinERC20(intermediary).balanceOf(address(this));
        swap("pangolin", intermediary, arbtoken, amount2);
        uint amount3 = IPangolinERC20(arbtoken).balanceOf(address(this));
        swap("joe", arbtoken, tokenBorrow, amount3); 
    } else {
        swap("joe", tokenBorrow, intermediary, amount);
        uint amount2 = IPangolinERC20(arbtoken).balanceOf(address(this));
        swap("joe",  intermediary, arbtoken, amount2);
        uint amount3 = IPangolinERC20(intermediary).balanceOf(address(this));
        swap("joe", arbtoken, tokenBorrow, amount3);
    }

    emit Log("amount", amount);
    emit Log("amount0", _amount0);
    emit Log("amount1", _amount1);
    emit Log("fee", fee);
    emit Log("amount to repay", amountToRepay);

    IPangolinERC20(tokenBorrow).transfer(pair, amountToRepay);
  }
}