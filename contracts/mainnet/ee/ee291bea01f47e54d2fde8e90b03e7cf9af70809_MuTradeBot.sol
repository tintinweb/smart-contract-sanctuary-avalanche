/**
 *Submitted for verification at snowtrace.io on 2022-11-14
*/

// File: MuTradeBot.sol


pragma solidity ^0.8.4;



interface IERC20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

interface Router {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
  function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
}

contract MuTradeBot{
    mapping (string => address) public routers;
    mapping (string => address[]) public routes;
    mapping (string => address) public tokens;

    address  public ME;

    constructor(){
        ME = 0x800287F40737f11DB275005c576bbb16D452B41f;
        routers["Pangolin"] = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
        routers["TraderJoe"] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        routers["SushiSwap"] = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

        tokens["MU"] = 0xD036414fa2BCBb802691491E323BFf1348C5F4Ba;
        tokens["USDC.e"] = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

        routes["MU-USDC.e"] = [tokens["MU"],tokens["USDC.e"]];
        routes["USDC.e-MU"] = [tokens["USDC.e"], tokens["MU"]];

        
    }


    function swap(uint256 _amount) public{
            IERC20(tokens["USDC.e"]).approve(routers["Pangolin"], _amount);
            uint deadline = block.timestamp + 300;
            Router(routers["Pangolin"]).swapExactTokensForTokens(_amount, 10000000000000000, routes["USDC.e-MU"], address(this), deadline);
    }

    function recoverTokens(address tokenAddress) public {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(ME, token.balanceOf(address(this)));
	}

    

}