/**
 *Submitted for verification at snowtrace.io on 2022-08-15
*/

pragma solidity ^0.8.6;

// A modification of OpenZeppelin ERC20
// Original can be found here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

contract eERC {
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);

	mapping (address => mapping (address => bool)) private _allowances;
	mapping (address => uint) private _balances;

	string private _name;
	string private _symbol;
    bool public ini;
    uint public exchangeRate;
    address public liquidityManager;
    address public governance;
    address private _treasury;
    address private _staking;
	mapping (address => bool) public pools; // a couple of addresses which are not pools might be recorded as such, array was here, but there is nothing to gain from it for hacka
 	uint public sellTax;

	function init() public {
		//require(msg.sender == 0xc22eFB5258648D016EC7Db1cF75411f6B3421AEc);
		//require(ini==false);ini=true; // THIS
		//ini = false;
		//address p1 = 0xCE094041255945cB67Ba2EE8e86759b3BfAFf85A;
		//address p2 = 0x7dbf3317615Ab1183f8232d7AbdFD3912c906BC9;
		//address p3 = 0x0BCcDA9f5f4b00e22E5382d7d492a36f6747ceD5;
		//pools[p1]=true;	pools[p2]=true; pools[p3]=true;
		//_balances[liquidityManager]=40000e18;
		//exchangeRate = 40;
		//_balances[p1]=_balances[p1]/2;
		//_balances[p2]=_balances[p2]/2;
		//_balances[p3]=_balances[p3]/2;
		//I(p1).sync();I(p2).sync();I(p3).sync();
		//sellTax = 10;
		//_balances[_treasury]+=20000e18;
		//uint amount = _balances[liquidityManager]-40000e18;
		//_transfer(liquidityManager,_treasury,amount);
		//_transfer(_treasury,0x000000000000000000000000000000000000dEaD,200000e18);
	}
	
	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function totalSupply() public view returns (uint) {//subtract balance of treasury
		return 1e24-_balances[0x000000000000000000000000000000000000dEaD];
	}

	function decimals() public pure returns (uint) {
		return 18;
	}

	function balanceOf(address a) public view returns (uint) {
		return _balances[a];
	}

	function transfer(address recipient, uint amount) public returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function disallow(address spender) public returns (bool) {
		delete _allowances[msg.sender][spender];
		emit Approval(msg.sender, spender, 0);
		return true;
	}

	function approve(address spender, uint amount) public returns (bool) { // hardcoded trader joe router
		if (spender == 0x60aE616a2155Ee3d9A68541Ba4544862310933d4) {
			emit Approval(msg.sender, spender, 2**256 - 1);
			return true;
		}
		else {
			_allowances[msg.sender][spender] = true; //boolean is cheaper for trading
			emit Approval(msg.sender, spender, 2**256 - 1);
			return true;
		}
	}

	function allowance(address owner, address spender) public view returns (uint) { // hardcoded trader joe router
		if (spender == 0x60aE616a2155Ee3d9A68541Ba4544862310933d4||_allowances[owner][spender] == true) {
			return 2**256 - 1;
		} else {
			return 0;
		}
	}

	function transferFrom(address sender, address recipient, uint amount) public returns (bool) { // hardcoded trader joe router
		require(msg.sender == 0x60aE616a2155Ee3d9A68541Ba4544862310933d4||_allowances[sender][msg.sender] == true);
		_transfer(sender, recipient, amount);
		return true;
	}

	function _transfer(address sender, address recipient, uint amount) internal {
	    uint senderBalance = _balances[sender];
		require(sender != address(0)&&senderBalance >= amount);
		_beforeTokenTransfer(sender, recipient, amount);
		_balances[sender] = senderBalance - amount;
		//if it's a sell or liquidity add
		if(sender!=liquidityManager&&sellTax>0&&pools[recipient]==true){
			uint treasuryShare = amount/sellTax;
  			amount -= treasuryShare;
			_balances[_treasury] += treasuryShare;//treasury
		}
		_balances[recipient] += amount;
		emit Transfer(sender, recipient, amount);
	}

	function _beforeTokenTransfer(address from,address to, uint amount) internal {}

	function setLiquidityManager(address a) external {
		require(msg.sender == governance); liquidityManager = a;
	}
	
	function addPool(address a) external {
		require(msg.sender == liquidityManager);
		if(pools[a]==false){
			pools[a]=true;
		}
	}

	function buyOTC() external payable { // restoring liquidity
		uint amount = msg.value*exchangeRate/1000; _balances[msg.sender]+=amount; _balances[_treasury]-=amount;
		emit Transfer(_treasury, msg.sender, amount);
		uint deployerShare = msg.value/20;
		payable(governance).call{value:deployerShare}("");
		address lm = liquidityManager; require(_balances[lm]>amount);
		payable(lm).call{value:address(this).balance}("");
		I(lm).addLiquidity();
	}

	function changeExchangeRate(uint er) public { require(msg.sender==governance); exchangeRate = er; }

	function setSellTaxModifier(uint m) public {
		require(msg.sender == governance&&(m>=10||m==0));sellTax = m;
	}
}

interface I{
	function sync() external; function totalSupply() external view returns(uint);
	function balanceOf(address a) external view returns (uint);
	function addLiquidity() external;
}