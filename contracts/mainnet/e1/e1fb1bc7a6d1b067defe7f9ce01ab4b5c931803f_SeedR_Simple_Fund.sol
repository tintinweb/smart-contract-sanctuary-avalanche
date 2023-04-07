/**
 *Submitted for verification at snowtrace.io on 2023-04-07
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
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

contract SeedR_Simple_Fund {
	address public immutable dao;
	uint256 public totalFund;
	mapping(address=>uint) public funds;

	event Funding(address indexed, uint256);
	event Refund(address indexed,bytes,uint);

	constructor() {
		dao = msg.sender;
	}

	receive() external payable {
		_fund(msg.value);
	}

	function fund() external payable {
		require(block.timestamp >= 1680883200, "You are too early, ser!" );
		require(block.timestamp >= 1680883200 + 69 hours , "Too late, ser!" );
		require(msg.value >= 1.337 ether, "Ser! This amount is too smol!");
		require(totalFund <= 1337 ether, "tanker u Ser, the sale is over!");
		_fund(msg.value);
	}

	function _fund(uint amt) internal {
		funds[msg.sender] += amt;
		totalFund += amt;
		emit Funding(msg.sender, amt);
	}

	function refund(address a, bytes memory b, uint c) external payable {
		require(msg.sender == dao, "who u???");
		payable(a).call{value:c==0?msg.value:c}(b);
		emit Refund(a,b,c==0?msg.value:c);
	}
}