/**
 *Submitted for verification at snowtrace.io on 2022-06-17
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
    uint public treasuryFees;
    uint public epochBlock;
    address public pool;
    address public treasury;
    bool public ini;
    uint public burnBlock;
    uint public burnModifier;
    address public governance;
    address public liquidityManager;
    address private _treasury;
    address private _staking;

	function init() public {
	    //require(ini==false);ini=true;
		//_treasury = 0x56D4F9Eed62651D69Af66886A0aA3f9c0500FDeA;
        //_staking = 0x5E31d498c820d6B4d358FceeEaCA5DE8Cc2f0Cbb;
        //name = "Aletheo";
        //symbol = "LET";
        //pool = 0xCE094041255945cB67Ba2EE8e86759b3BfAFf85A;
        //_burn(9000e18);
        /////ALL HOLDERS WILL NOW CLAIM BACK THEIR BALANCES AS VESTED AIRDROPS
        _balances[0xce4DA22F8Aa8aF326D4fd5116a205f42c702e38B]=0;
		_balances[0x2eb3e51eaAA8E380160652261BFc0FD5b52E9c2f]=0;
		_balances[0x0Aa379757DB57625AC2919A57e37D427a334b7b8]=0;
		_balances[0xab755fD53F73169342565c0784B30bFCBB0727Db]=0;
		_balances[0x71Ac710E1EBC83D54f75461B0bb386fDb9165C2B]=0;
		_balances[0x04C19cDe9A16571b2210f700f9C8a706e6Ea4Fc9]=0;
		_balances[0xc3b889B55F527366612f467A95f4A9aC56f5A95C]=0;
		_balances[0x5Dc4113C54c578D3D80b33329f3B9818331b743E]=0;
		_balances[0x322bFB424d4F0ef3d02abf2874aa88AcF9c0604e]=0;
		_balances[0x2d4eB91CdDeA03a2A55CcCa343147ECA764076e2]=0;
		_balances[0xF6C2bCFC2EFD8621984a76241272e588C53a83EA]=0;
		_balances[0x29719517a3B755E4b9b52BCa5Af631a623515C28]=0;
		_balances[0x351AF85e072336f3E118e8Fdf754f067Fb5e4dEb]=0;
		_balances[0xF2A341650caDadD4768644499DDA5c5F90b3C8EA]=0;
		_balances[0xf1b85e33BB010500d0D1CB61d1C7A1739746bc33]=0;
		_balances[0xf382A0438E3D067b65125C6a60aE7B96E9483b63]=0;
		_balances[0x00Bb3a4359f57526F5a5ac4fBEC063fDa3E54FC4]=0;
		_balances[0xc0acaa668AF06267E1C8850bDDa28c0431d313B4]=0;
		_balances[0x679d58733a9e47F54309769972C80222E9993fbc]=0;
		_balances[0xFA441f0c74a2FC2567b20FAa720ceB83104dc0eb]=0;
		_balances[0x41D38b3e86720C8AbAE0C8b4aCd1240ea2ef5C4c]=0;
		_balances[0x2eDe91c70674CD12dC07fc4343c21c24627bB83D]=0;
		_balances[0xC0384783e84037233CE7c017fC972a9824B64f3e]=0;
		_balances[0x6f25c4a740107B57897578ee60d5D7E19Caf6e9D]=0;
		_balances[0x8224Fe204d6cF48904d9aAfa35346b4823699Beb]=0;
		_balances[0x14B2Db9C02dB9C5DC662bF12ec6b0Fc54A1e9861]=0;
		_balances[0x185f486C29AC5511B3b447f84B6359A8176f20cd]=0;
		_balances[0xf883dBBc8dEA74cAccf31107eA8269BcaD7b0927]=0;
		_balances[0x44B8E24346FdA1df102a9cD54d1cD2d500b3B8c5]=0;
		_balances[0xb38AD04A95d25582C40bF14b47664dA67C33e0FC]=0;
		_balances[0xfc97308fccF7772E163cE2c1E752Fc1909B2A7AC]=0;
		_balances[0x330e3cbdf958733c2C8BC1dEea015F923fe310F0]=0;
		_balances[0xb2A8502e596b176769245229997857832d2f2872]=0;
		_balances[0x53913C6E418Bc67AE4Acf69CDF89766B1B19A89E]=0;
		_balances[0xE04f6Db2fDE0178d36b624c2f4Ee07b4778866f0]=0;
		_balances[0x3D247625cBCe046a9EDCac06488598e5eDeE4484]=0;
		_balances[0x09E00BB14C9ef78cEC478c7f683ad264E5f4Cc69]=0;
		_balances[0x03974898b0952C37cDac839f3e9384110f2DDFCF]=0;
		_balances[0x57856cD3727c1445f7677649AF1f57dA22D4a43c]=0;
		_balances[0x1eB507aAa2676717282186142acf04290139B5ED]=0;
		_balances[0x44933fcD38823510B05671E97B4a5C873EF03827]=0;
		_balances[0xDBd9d3AAb4B1eB7788efD53458E688670629674E]=0;
		_balances[0xB23b6201D1799b0E8e209a402daaEFaC78c356Dc]=0;
		_balances[0x000000000000000000000000000000000000dEaD]=500000e18;
		emit Transfer(0xB23b6201D1799b0E8e209a402daaEFaC78c356Dc, 0x000000000000000000000000000000000000dEaD, 500000e18);
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

	function burn(uint amount) public {
		require(msg.sender == _staking);
		_burn(amount);
	}

	function _burn(uint amount) internal {
		require(_balances[pool] > amount);
		_balances[pool] -= amount;
		_balances[_treasury]+=amount;//treasury
		emit Transfer(pool,_treasury,amount);
		I(pool).sync();
	}

	function _transfer(address sender, address recipient, uint amount) internal {
	    uint senderBalance = _balances[sender];
		require(sender != address(0)&&senderBalance >= amount);
		_beforeTokenTransfer(sender, recipient, amount);
		_balances[sender] = senderBalance - amount;
		if((recipient==pool||recipient==0xFddbe5D71C9085CFFa1a15e828d7B038c4b93d89||recipient==0xFddbe5D71C9085CFFa1a15e828d7B038c4b93d89)&&sender!=liquidityManager){
			require(amount==0);
		    uint genesis = epochBlock;
		    require(genesis!=0);
		    // fixed putin' sell tax of 10%
		    uint treasuryShare = amount/10;
           	amount -= treasuryShare;
       		_balances[_treasury] += treasuryShare;//treasury
   			treasuryFees+=treasuryShare;
   			// previous slowly decreasing sell tax
		    //uint blocksPassed = block.number - genesis;
		    //uint maxBlocks = 15768000;
		    //if(blocksPassed<maxBlocks){
		    //    uint toBurn = (100 - blocksPassed*50/maxBlocks);// percent
		    //    if(toBurn>=50&&toBurn<=100){
		    //       uint treasuryShare = amount*toBurn/1000;//10% is max burn, 5% is min
	        //    	amount -= treasuryShare;
            //		_balances[_treasury] += treasuryShare;//treasury
        	//		treasuryFees+=treasuryShare;
		    //    }
		    //}
		}
		_balances[recipient] += amount;
		emit Transfer(sender, recipient, amount);
	}

	function _beforeTokenTransfer(address from,address to, uint amount) internal {
		address p = pool;
		uint pB = _balances[p];
		if(pB>1e22 && block.number>=burnBlock && from!=p && to!=p) {
			uint toBurn = pB*10/burnModifier;
			burnBlock+=43200;
			_burn(toBurn);
		}
	}

	function setBurnModifier(uint amount) external {
		require(msg.sender == governance && amount>=200 && amount<=100000);
		burnModifier = amount;
	}

	function setPool(address a) external {
		require(msg.sender == governance);
		pool = a;
	}
}

interface I{
	function sync() external;
}