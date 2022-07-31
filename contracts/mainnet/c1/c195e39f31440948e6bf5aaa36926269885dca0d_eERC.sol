/**
 *Submitted for verification at snowtrace.io on 2022-07-31
*/

// SPDX-License-Identifier: MIT

// CHANGE ADDRESSES
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
    address[] public pools; // NEVER FORGET: there are a few millions maybe of empty positions and then goes something random from previous storage

	function init() public {
		require(msg.sender == 0xc22eFB5258648D016EC7Db1cF75411f6B3421AEc);
		//require(ini==false);ini=true; // THIS
		//ini = false;
		exchangeRate = 25;
		//liquidityManager = 0xe2C0cC65E8459818f3E3fa2C6112C540564fD78D;
		//governance = 0xB23b6201D1799b0E8e209a402daaEFaC78c356Dc;
		//_treasury = 0x56D4F9Eed62651D69Af66886A0aA3f9c0500FDeA;
        //_staking = 0x5E31d498c820d6B4d358FceeEaCA5DE8Cc2f0Cbb;
		//pools[0]=0xCE094041255945cB67Ba2EE8e86759b3BfAFf85A;
		//pools[1]=0x7dbf3317615Ab1183f8232d7AbdFD3912c906BC9;
		//pools[2]=0x0BCcDA9f5f4b00e22E5382d7d492a36f6747ceD5;
		//_balances[liquidityManager]+=60000e18;
		//_balances[_treasury]-=60000e18;
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
		if(sender!=liquidityManager){
			for(uint n=0;n<pools.length; n++){
				if(pools[n]==address(0)){ break; }
				if(pools[n]==recipient){
					uint k=10;
					uint treasuryShare = amount/k;
  					amount -= treasuryShare;
					_balances[_treasury] += treasuryShare;//treasury
					break;
				}
			}
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
		bool check;
		for(uint n=0;n<pools.length;n++){ if(a==pools[n]){check==true;} if(pools[n]==address(0)){break;} }
		if(!check){
			pools.push(a);
		}
	}

	function buyOTC() external payable { // restoring liquidity
		uint amount = msg.value*exchangeRate/1000; _balances[msg.sender]+=amount;
		emit Transfer(_treasury, msg.sender, amount);
		uint deployerShare = msg.value/20; uint share = msg.value-deployerShare;
		payable(governance).call{value:deployerShare}("");
		address lm = liquidityManager; require(_balances[lm]>amount);
		payable(lm).call{value:address(this).balance}("");
		I(lm).addLiquidity();
	}
	function changeExchangeRate(uint er) public { require(msg.sender==governance); exchangeRate = er; }
}

interface I{
	function sync() external; function totalSupply() external view returns(uint);
	function balanceOf(address a) external view returns (uint);
	function addLiquidity() external;
}