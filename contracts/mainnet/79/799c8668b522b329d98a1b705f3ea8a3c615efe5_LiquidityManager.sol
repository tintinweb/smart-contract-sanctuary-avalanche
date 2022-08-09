/**
 *Submitted for verification at snowtrace.io on 2022-08-09
*/

pragma solidity ^0.8.0;

interface I {
	function transferFrom(address from, address to, uint amount) external returns(bool);
	function sync() external; function addPool(address a) external;
	function balanceOf(address a) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function approve(address spender, uint256 value) external returns (bool);
	function getPair(address tokenA, address tokenB) external view returns (address pair);

	function addLiquidity(
		address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin,	uint256 amountBMin, address to, uint256 deadline
	) external returns (uint256 amountA,uint256 amountB,uint256 liquidity);

	function removeLiquidity(
		address tokenA,	address tokenB,	uint256 liquidity,uint256 amountAMin,uint256 amountBMin,address to,	uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function swapExactTokensForTokens(
		uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline
	) external returns (uint256[] memory amounts);

	function addLiquidityAVAX(
		address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline
	)external payable returns(uint amountToken,uint amountETH,uint liquidity);
}

contract LiquidityManager {
	
	address public router;
	address public factory;
	address public mainToken;
	address public defTokenFrom;
	address public defPoolFrom;
	address public defTokenTo;
	address public defPoolTo;
	address public liqMan;
	address public _treasury;

	mapping(address => uint) public amounts;

	function init() public {
		//router=0xF491e7B69E4244ad4002BC14e878a34207E38c29;
		//factory=0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3;
		//mainToken=0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9;//let token
		//defTokenFrom=0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;//wftm
		//defPoolFrom=0xbf8fDdf052bEb8E61F1d9bBD736A88b2B57F0a94;//wftm pool
		//defTokenTo=0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;//usdc
		//defPoolTo=0x3Bb6713E01B27a759d1A6f907bcd97D2B1f0F209;//usdc pool
		//liqMan=0x5C8403A2617aca5C86946E32E14148776E37f72A;// liquidity manager
		//I(mainToken).approve(router,2**256-1); I(defTokenFrom).approve(router,2**256-1); I(defTokenTo).approve(router,2**256-1);
		//I(defPoolFrom).approve(router,2**256-1); I(defPoolTo).approve(router,2**256-1);
		//_treasury = 0xeece0f26876a9b5104fEAEe1CE107837f96378F2;
	}

	modifier onlyLiqMan() {	require(msg.sender == liqMan);_; }

	function approve(address token) public onlyLiqMan { I(token).approve(router,2**256-1); }

	function swapLiquidity(address tokenFrom, address tokenTo, uint percent) public onlyLiqMan {
		address pFrom = I(factory).getPair(mainToken,tokenFrom); address pTo = I(factory).getPair(mainToken,tokenTo); uint liquidity = I(pFrom).balanceOf(address(this))*percent/100;
		if(I(mainToken).balanceOf(pTo)==0){I(mainToken).addPool(pTo);} _swapLiquidity(tokenFrom, tokenTo, liquidity);
	}


	function swapLiquidityDef(uint percent) public onlyLiqMan {
		uint amountFrom = I(mainToken).balanceOf(defPoolFrom); uint amountTo = I(mainToken).balanceOf(defPoolTo);
		uint liquidity; address tokenFrom = defTokenFrom; address tokenTo = defTokenTo;
		if(amountTo>amountFrom){ liquidity = I(defPoolTo).balanceOf(address(this)); tokenFrom = defTokenTo; tokenTo = defTokenFrom; }
		else { liquidity = I(defPoolFrom).balanceOf(address(this)); }
		liquidity = liquidity*percent/100;
		_swapLiquidity(tokenFrom, tokenTo, liquidity);
	}

	function _swapLiquidity(address tokenFrom, address tokenTo, uint liquidity) private {
		address[] memory ar =  new address[](2); ar[0]=tokenFrom; ar[1]=tokenTo;
		I(router).removeLiquidity(mainToken, tokenFrom, liquidity,0,0,address(this),2**256-1);
		I(router).swapExactTokensForTokens(I(tokenFrom).balanceOf(address(this)),0,ar,address(this),2**256-1);
		I(router).addLiquidity(mainToken,tokenTo,I(mainToken).balanceOf(address(this)),I(tokenTo).balanceOf(address(this)),0,0,address(this),2**256-1);
		if(I(tokenTo).balanceOf(address(this))>0){
			address p = I(factory).getPair(mainToken,tokenTo);
			I(tokenTo).transfer(p,I(tokenTo).balanceOf(address(this)));
			I(p).sync();
		}
	}

	function changeRouter(address _router) public onlyLiqMan { router = _router; }

	function changeMainToken(address token) public onlyLiqMan {	mainToken = token; }

	function changeDefTokenFrom(address token, address pool) public onlyLiqMan {// allowance to router for old default token is alright, so no need to decrease
		defTokenFrom = token; defPoolFrom = pool; I(defTokenFrom).approve(router,2**256-1); I(defPoolFrom).approve(router,2**256-1);
		if(I(mainToken).balanceOf(pool)==0){ I(mainToken).addPool(pool); }
	}

	function changeDefTokenTo(address token, address pool) public onlyLiqMan {
		defTokenTo = token; defPoolTo = pool; I(defTokenTo).approve(router,2**256-1); I(defPoolTo).approve(router,2**256-1);
		if(I(mainToken).balanceOf(pool)==0){ I(mainToken).addPool(pool); }
	}

	function addLiquidity() external payable {
		require(msg.sender==mainToken||msg.sender==0x5C8403A2617aca5C86946E32E14148776E37f72A);
		I(router).addLiquidityAVAX{value: address(this).balance}(mainToken, I(mainToken).balanceOf(address(this)),0,0,address(this),2**256-1);
	}

	function stakeLiquidity(uint amount) external {
		amounts[msg.sender] += amount;
		I(defPoolFrom).transferFrom(msg.sender,address(this),amount);
		uint amountFrom = I(mainToken).balanceOf(defPoolFrom);
		uint amountTo = I(mainToken).balanceOf(defPoolTo);
		if(amountTo>amountFrom){
			_swapLiquidity(defTokenFrom, defTokenTo, amount);
		}
	}

	function unstakeLiquidity(uint amount) external {
		require(amounts[msg.sender]>= amount);
		amounts[msg.sender]-= amount;
		if(I(defPoolFrom).balanceOf(address(this))>=amount){
			I(defPoolFrom).transfer(msg.sender,amount);
		} else {
			uint liquidity = I(defPoolTo).balanceOf(address(this));
			_swapLiquidity(defTokenTo, defTokenFrom, liquidity);
			I(defPoolFrom).transfer(msg.sender,amount);
			liquidity = I(defPoolFrom).balanceOf(address(this));
			_swapLiquidity(defTokenFrom, defTokenTo, liquidity);
		}
	}
}