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
        ME = 0xF243d79910cBd70a0eaF405b08E80065a67D5e14;
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
        tokens["BTC.b"] = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
        tokens["WBTC.e"] = 0x50b7545627a5162F82A992c33b87aDc75187B218;
        tokens["WETH"] = 0x8b82A291F83ca07Af22120ABa21632088fC92931;
        tokens["WETH.e"] = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
        tokens["AAVE.e"] = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;
        tokens["BNB"] = 0x264c1383EA520f73dd837F915ef3a732e204a493;
        tokens["AVAX"] = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
        tokens["WMATIC"] = 0xf2f13f0B7008ab2FA4A2418F4ccC3684E49D20Eb;
        tokens["LINK.e"] = 0x5947BB275c521040051D82396192181b413227A3;
        tokens["JOE"] = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
        tokens["PNG"] = 0x60781C2586D68229fde47564546784ab3fACA982;
        tokens["SUSHI.e"] = 0x37B608519F91f70F2EeB0e5Ed9AF4061722e4F76;
        tokens["SOL"] = 0xFE6B19286885a4F7F55AdAD09C3Cd1f906D2478F;
        tokens["GMX"] = 0x62edc0692BD897D2295872a9FFCac5425011c661;

        //blank token tokens[""] = ;

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
        //BTC.b routes with MU
        routes["BTC.b-MU"] = [tokens["BTC.b"], tokens["MU"]];
        routes["MU-BTC.b"] = [tokens["MU"], tokens["BTC.b"]];
        //WBTC.e routes with MU
        routes["WBTC.e-MU"] = [tokens["WBTC.e"], tokens["MU"]];
        routes["MU-WBTC.e"] = [tokens["MU"], tokens["WBTC.e"]];
        //WETH routes with MU
        routes["WETH-MU"] = [tokens["WETH"], tokens["MU"]];
        routes["MU-WETH"] = [tokens["MU"], tokens["WETH"]];
        //WETH.e routes with MU
        routes["WETH.e-MU"] = [tokens["WETH.e"], tokens["MU"]];
        routes["MU-WETH.e"] = [tokens["MU"], tokens["WETH.e"]];
        //AAVE.e routes with MU
        routes["AAVE.e-MU"] = [tokens["AAVE.e"], tokens["MU"]];
        routes["MU-AAVE.e"] = [tokens["MU"], tokens["AAVE.e"]];
        //BNB routes with MU
        routes["BNB-MU"] = [tokens["BNB"], tokens["MU"]];
        routes["MU-BNB"] = [tokens["MU"], tokens["BNB"]];
        //AVAX routes with MU
        routes["AVAX-MU"] = [tokens["AVAX"], tokens["MU"]];
        routes["MU-AVAX"] = [tokens["MU"], tokens["AVAX"]];
        //WMATIC routes with MU
        routes["WMATIC-MU"] = [tokens["WMATIC"], tokens["MU"]];
        routes["MU-WMATIC"] = [tokens["MU"], tokens["WMATIC"]];
        //LINK.e routes with MU
        routes["LINK.e-MU"] = [tokens["LINK.e"], tokens["MU"]];
        routes["MU-LINK.e"] = [tokens["MU"], tokens["LINK.e"]];
        //JOE routes with MU
        routes["JOE-MU"] = [tokens["JOE"], tokens["MU"]];
        routes["MU-JOE"] = [tokens["MU"], tokens["JOE"]];
        //PNG routes with MU
        routes["PNG-MU"] = [tokens["PNG"], tokens["MU"]];
        routes["MU-PNG"] = [tokens["MU"], tokens["PNG"]];
        //SUSHI.e routes with MU
        routes["SUSHI.e-MU"] = [tokens["SUSHI.e"], tokens["MU"]];
        routes["MU-SUSHI.e"] = [tokens["MU"], tokens["SUSHI.e"]];
        //GMX routes with Mu
        routes["GMX-MU"] = [tokens["GMX"], tokens["MU"]];
        routes["MU-GMX"] = [tokens["MU"], tokens["GMX"]];

        // blank route routes[""] = [tokens[""], tokens[""]];

        
    }

    function approve_router( string calldata token, uint256 _amount) public {
        //approve  token
        IERC20(tokens[token]).approve(routers["Pangolin"], _amount);
        IERC20(tokens[token]).approve(routers["TraderJoe"], _amount);
        IERC20(tokens[token]).approve(routers["SushiSwap"], _amount);
        
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

    function recoverTokens(string calldata token) public {
		IERC20(tokens[token]).transfer(ME, IERC20(tokens[token]).balanceOf(address(this)));
        
	}

    

}