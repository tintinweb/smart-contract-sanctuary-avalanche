/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-09
*/

pragma solidity 0.8.11;

interface IUniswapV2Router02 {
 function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract TradingTest {
  mapping (address => bool) members;
  address constant owner = 0xf4AbB0d1F4C0615aE2EC77892f895678B5B664bd;
  constructor() public{

  }

   function addMember(address _member) public {
     require(msg.sender == owner);
     members[_member] = true;
   }

   function removeMember(address _member) public {
     require(msg.sender == owner);
     members[_member] = false;
   }

  function add_coin(address router, address coin) public {
    require(msg.sender == owner);
    IERC20 token = IERC20(coin);
    token.approve(router, 2**256 - 1);
    token.approve(owner, 2**256 - 1);
  }

  function swap(address router, address in_coin, address out_coin, uint256 amount_in, uint256 min_out, uint256 deadline) public {
    require(members[msg.sender] == true);
    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(router);
    address[] memory path = new address[](2);
    path[0] = in_coin;
    path[1] = out_coin;
    uniswapRouter.swapExactTokensForTokens(amount_in, min_out, path, address(this), deadline);
  }
}