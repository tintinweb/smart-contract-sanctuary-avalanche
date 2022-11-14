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

        //all the tokens
        //MU ecosystem tokens
        tokens["MU"] = 0xD036414fa2BCBb802691491E323BFf1348C5F4Ba;

        //Stable Coins
        tokens["USDC.e"] = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
        tokens["USDC"] = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
        tokens["USDT"] = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
        tokens["USDT.e"] = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
        tokens["DAI.e"] = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
        tokens["MIM"] = 0x130966628846BFd36ff31a822705796e8cb8C18D;
        tokens["BUSD"] = 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39;

        //exotic coins

        //all the possible routes
        //USDC.e routes with MU
        routes["MU-USDC.e"] = [tokens["MU"],tokens["USDC.e"]];
        routes["USDC.e-MU"] = [tokens["USDC.e"], tokens["MU"]];
        //USDC routes with MU
        routes["USDC-MU"] = [tokens["USDC"], tokens["MU"]];
        routes["MU-USDC"] = [tokens["MU"], tokens["USDC"]];
        //USDT routes with MU
        routes["MU-USDT"] = [tokens["MU"], tokens["USDT"]];
        routes["USDT-MU"] = [tokens["USDT"], tokens["MU"]];
        //USDT.e routes with MU
        routes["MU-USDT.e"] = [tokens["MU"], tokens["USDT.e"]];
        routes["USDT.e-MU"] = [tokens["USDT.e"], tokens["MU"]];
        //DAI.e routes with MU
        routes["MU-DAI.e"] = [tokens["MU"], tokens["DAI.e"]];
        routes["DAI.e-MU"] = [tokens["DAI.e"], tokens["MU"]];
        //MIM routes with MU
        routes["MU-MIM"] = [tokens["MU"], tokens["MIM"]];
        routes["MIM-MU"] = [tokens["MIM"], tokens["MU"]];
        //BUSD routes with MU
        routes["MU-BUSD"] = [tokens["MU"], tokens["BUSD"]];
        routes["BUSD-MU"] = [tokens["BUSD"], tokens["MU"]];

        // blank route routes[""] = [tokens[""], tokens[""]];

        
    }

    function approve_router(string calldata _token, uint256 _amount) public {
        IERC20(tokens[_token]).approve(routers["Pangolin"], _amount);
        IERC20(tokens[_token]).approve(routers["TraderJoe"], _amount);
        IERC20(tokens[_token]).approve(routers["SushiSwap"], _amount);
    }

    function swap_exact_in(string calldata _router, string calldata _route, uint256 _amount) public{
            uint deadline = block.timestamp + 300;
            Router(routers[_router]).swapExactTokensForTokens(_amount, 1000000, routes[_route], address(this), deadline);
    }

     function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256[] memory amountOutMins = Router(router).getAmountsOut(_amount, path);
		return amountOutMins[path.length -1];
	}


    function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {
		IERC20(_tokenIn).approve(router, _amount);
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint deadline = block.timestamp + 300;
		Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
	}

    function dualDexTrade(string calldata _router1, string calldata _router2, string calldata _token1, string calldata _token2, uint256 _amount) public {
        uint startBalance = IERC20(tokens[_token1]).balanceOf(address(this));
        uint token2InitialBalance = IERC20(tokens[_token2]).balanceOf(address(this));
        swap(routers[_router1],tokens[_token1], tokens[_token2],_amount);
        uint token2Balance = IERC20(tokens[_token2]).balanceOf(address(this));
        uint tradeableAmount = token2Balance - token2InitialBalance;
        swap(routers[_router2],tokens[_token2], tokens[_token1],tradeableAmount);
        uint endBalance = IERC20(tokens[_token1]).balanceOf(address(this));
        require(endBalance > startBalance, "Trade Reverted, No Profit Made");
  }

    function estimateDualDexTrade(string calldata _router1, string calldata _router2, string calldata _token1, string calldata _token2, uint256 _amount) external view returns (uint256) {
		uint256 amtBack1 = getAmountOutMin(routers[_router1], tokens[_token1], tokens[_token2], _amount);
		uint256 amtBack2 = getAmountOutMin(routers[_router2], tokens[_token2], tokens[_token1], amtBack1);
		return amtBack2;
	}

    function recoverTokens(address tokenAddress) public {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(ME, token.balanceOf(address(this)));
	}

    

}