/**
 *Submitted for verification at snowtrace.io on 2023-04-13
*/

/**
 *Submitted for verification at Arbiscan on 2023-03-16
*/

/**
 *Submitted for verification at BscScan.com on 2023-01-09
*/

/**
 *Submitted for verification at FtmScan.com on 2023-01-09
*/

/*

FFFFF  TTTTTTT  M   M         GGGGG  U    U  RRRRR     U    U
FF       TTT   M M M M       G       U    U  RR   R    U    U
FFFFF    TTT   M  M  M      G  GGG   U    U  RRRRR     U    U
FF       TTT   M  M  M   O  G    G   U    U  RR R      U    U
FF       TTT   M     M       GGGGG    UUUU   RR  RRR    UUUU




						Contact us at:
			https://discord.com/invite/QpyfMarNrV
					https://t.me/FTM1337

	Community Mediums:
		https://medium.com/@ftm1337
		https://twitter.com/ftm1337

	SPDX-License-Identifier: UNLICENSED


	elSNEK.sol

	elSNEK, or le Snek🐍 is a Liquid Staking Derivate for veSNEK (Vote-Escrowed SoliSnek NFT).
	It can be minted by burning (veSNEK) veNFTs.
	elSNEK adheres to the EIP20 Standard.
	It can be staked with Guru Network to earn pure AVAX instead of multiple small tokens.
	elSNEK can be further deposited into Kompound Protocol to mint ibSNEK.
	ibSNEK is a doubly-compounding interest-bearing veRAM at its core.
	ibSNEK uses elSNEK's AVAX yield to buyback more elSNEKs from the open-market via JIT Aggregation.
	The price (in SNEK) to mint elSNEK goes up every epoch due to positive rebasing.
	This property gives ibSNEK a "hyper-compounding" double-exponential trajectory against raw SNEK tokens.
	elSNEL is the market ticker for le Snek🐍.
	Price of 1 elSNEK is independent and not affected by the price of SNEK.

*/

pragma solidity 0.8.17;

contract elSNEK {
	string public name = unicode"Le Snek. 🐍";
	string public symbol = "elSNEK";
	uint8  public decimals = 18;
	uint256  public totalSupply;
	mapping(address=>uint256) public balanceOf;
	mapping(address=>mapping(address=>uint256)) public allowance;
	address public dao;
	address public minter;
	event  Approval(address indexed o, address indexed s, uint a);
	event  Transfer(address indexed s, address indexed d, uint a);
	modifier DAO() {
		require(msg.sender==dao, "Unauthorized!");
		_;
	}
	modifier MINTERS() {
		require(msg.sender==minter, "Unauthorized!");
		_;
	}
	function approve(address s, uint a) public returns (bool) {
		allowance[msg.sender][s] = a;
		emit Approval(msg.sender, s, a);
		return true;
	}
	function transfer(address d, uint a) public returns (bool) {
		return transferFrom(msg.sender, d, a);
	}
	function transferFrom(address s, address d, uint a) public returns (bool) {
		require(balanceOf[s] >= a, "Insufficient");
		if (s != msg.sender && allowance[s][msg.sender] != type(uint256).max) {
			require(allowance[s][msg.sender] >= a, "Not allowed!");
			allowance[s][msg.sender] -= a;
		}
		balanceOf[s] -= a;
		balanceOf[d] += a;
		emit Transfer(s, d, a);
		return true;
	}
	function mint(address w, uint256 a) public MINTERS returns (bool) {
		totalSupply+=a;
		balanceOf[w]+=a;
		emit Transfer(address(0), w, a);
		return true;
	}
	function burn(uint256 a) public returns (bool) {
		require(balanceOf[msg.sender]>=a, "Insufficient");
		totalSupply-=a;
		balanceOf[msg.sender]-=a;
		emit Transfer(msg.sender, address(0), a);
		return true;
	}
	function setMinter(address m) public DAO {
		minter = m;
	}
	function setDAO(address d) public DAO {
		dao = d;
	}
	function setMeta(string memory s, string memory n) public DAO {
		name = n;
		symbol = s;
	}
	constructor() {
		dao=msg.sender;
	}
}

/*
	Community, Services & Enquiries:
		https://discord.gg/QpyfMarNrV

	Powered by Guru Network DAO ( 🦾 , 🚀 )
		Simplicity is the ultimate sophistication.
*/