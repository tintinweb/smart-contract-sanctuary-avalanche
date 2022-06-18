/**
 *Submitted for verification at snowtrace.io on 2022-06-18
*/

/**
 *Submitted for verification at snowtrace.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT

// CHANGE ADDRESSES
pragma solidity ^0.8.6;
interface I {
	function balanceOf(address a) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function transferFrom(address sender,address recipient, uint amount) external returns (bool);
	function totalSupply() external view returns (uint);
	function getRewards(address a,uint rewToClaim) external;
	function burn(uint) external;
}
// this contract' beauty was butchered
contract StakingContract {
	address public _letToken;
	address public _treasury;
	uint public totalLetLocked;

	struct TokenLocker {
		uint128 amount;
		uint32 lastClaim;
		uint32 lockUpTo;
		uint32 epoch;
	}

	mapping(address => TokenLocker) private _ls;
	
    bool public ini;
    
	function init() public {
	    //require(ini==false);ini=true;
		//_letToken = 0x017fe17065B6F973F1bad851ED8c9461c0169c31;
		//_treasury = 0x56D4F9Eed62651D69Af66886A0aA3f9c0500FDeA;
		////// HAVE STAKE
		//_ls[0x9112A010a5b5d1B77a443B2D20734c221AEBBAFb].lastClaim = 10893341;
		//_ls[0x44933fcD38823510B05671E97B4a5C873EF03827].lastClaim = 11989246;
		//_ls[0xa40Fe529E8A7909F1063aD7F17dEf7B82180c9cD].lastClaim = 13917759;
		//_ls[0xFB72e56770d593B8993449287782C2E10A129E07].lastClaim = 14194887;
		//_ls[0x531f001A4d10c21cdcC7dEE8a6F25000A1c97408].lastClaim = 12337163;
		//_ls[0xD1C2fE84E8A324104D09097407c2Abdb4098F49C].lastClaim = 9716105;
		//_ls[0x2eb3e51eaAA8E380160652261BFc0FD5b52E9c2f].lastClaim = 9509111;
		//_ls[0x2E2767D02Fb0884274893eBf3282ebB9Ff77eF84].lastClaim = 10119319;
		//_ls[0x0c7e6e1a808bC718661BD54c284066df8bacbE3C].lastClaim = 9967195;
		//_ls[0x2Ed944e973A2536188bA5A8BB9C00bE28600258a].lastClaim = 12686413;
		//_ls[0x69Ee6d219F781C430Dc14953cE98080C378B2E31].lastClaim = 9303713;
		//_ls[0x1CAEE17D8Be9bb20c21C8D503f1000eAe9691250].lastClaim = 10732801;
		//_ls[0x1922bf48428aE7C646dd57Fbf9Ce04aff92CA1cB].lastClaim = 13530633;
		//_ls[0xD9882573b3cECCF633B0ac7Be7372d48fF3A8043].lastClaim = 13201639;
		//_ls[0x7a87aAf9B1dACC8F78a9E46e573c60c0974d4f5a].lastClaim = 10093948;
		//_ls[0x8879610B84998F8B564949B21eFFA51c25f92217].lastClaim = 11581259;
		//_ls[0xe6D3fa67aF9eA970251bD43019B70CEDB0aB66Af].lastClaim = 12574564;
		//_ls[0xFe4465166202C0566EF2F0FDaA048ED9e56B4d57].lastClaim = 12421596;
		//_ls[0xDa04A0A96CDd5bEC8E1c26685CdC5ef6a1F4423D].lastClaim = 12362992;
		//_ls[0x80b5F716b6EE1fD2637863d9FB8715ADb7d15Fee].lastClaim = 10053801;
		//_ls[0x9b992a24cb2b2268405250E152AEbF59B127E8bC].lastClaim = 10580353;
		//_ls[0xF79E212f89C20F8c2f0E1dc399c5dB5C03722041].lastClaim = 10413014;
		//_ls[0x1E72269DD90C0F689E38b9F6A3D045044b877105].lastClaim = 10644668;
		//_ls[0xF533C75B5B942B75236f412E2f5F6d9B92Cf1104].lastClaim = 9284436;
		//_ls[0xD6a572E411e8e56a00C7534E8b72A4a801DbF3FB].lastClaim = 12049974;
		//_ls[0xf1b85e33BB010500d0D1CB61d1C7A1739746bc33].lastClaim = 13631905;
		//_ls[0xba98011C1356AEFAe6f119690234916614C1294b].lastClaim = 9664585;
		//_ls[0x5Dc4113C54c578D3D80b33329f3B9818331b743E].lastClaim = 9832316;
		//_ls[0x9dA1A931a572776c98DC87E7d9Aa78784F875866].lastClaim = 11269357;

		/////NO ISSUE
		//_ls[0x75b815d808ff5a25477486809449e8dea21d2f84].lastClaim = ;
		//_ls[0x6857f00c6e573adee73c9874b43414d872457636].lastClaim = ;
		//_ls[0x6f1f0597b0638a560d0b849d02bc2d4a9677fcb2].lastClaim = ;
		//_ls[0xc71ceab81a7f7866313c319959c66854f5bb8fe0].lastClaim = ;
		//_ls[0x63d119a61403aa2c8ae5fb0cfcfe1f2c4dab5106].lastClaim = ;
		//_ls[0x4ec87da8a9eb1179b90d17bee3ace9fdf05030da].lastClaim = ;
		//_ls[0x4778300fb7068fac4743ad6a10880531a8308ff3].lastClaim = ;
		//_ls[0x00bb3a4359f57526f5a5ac4fbec063fda3e54fc4].lastClaim = ;
		//_ls[0x5ccb42a3367b601c77e07e0748e7d9841a79d16e].lastClaim = ;
		//_ls[0x322bfb424d4f0ef3d02abf2874aa88acf9c0604e].lastClaim = ;
		//_ls[0x48f5eb1b681d3c2856f4188ae5e5e80ef153b034].lastClaim = ;
		//_ls[0x1202ab6b35af99775a8840dc0bbbe1a4c5ba1d7d].lastClaim = ;
		//_ls[0x66d3c122b9edcaa34d0dc97ca4e1ec7152540b9e].lastClaim = ;
		//_ls[0xf8f3addb186419fdd7e6cd4f7b6c06ab3d01e92a].lastClaim = ;
		//_ls[0xc0acaa668af06267e1c8850bdda28c0431d313b4].lastClaim = ;
		//_ls[0xb088d28d9bb7ee9c4bbd0d4af99344e0bcf2a30b].lastClaim = ;
		//_ls[0xa41d7aac065afd50d908754c00281c57de02c321].lastClaim = ;
		//_ls[0x38b181353199dc5c467da121f127e8d4df5d10b2].lastClaim = ;
		//_ls[0xa719aa60d377f32a880941434721d6d7127e3e41].lastClaim = ;
		//_ls[0x876cf8dcb8262398885bb2e1fb025fb2c1756164].lastClaim = ;

		//////DONT HAVE STAKE OR API GLITCH
//		_ls[0x19c41f73416d68590e953868505f4bb8239cefb5].lastClaim = ;
//		_ls[0xae7bbe8a8c32f80128a7ef5ed113f0d34b3c1b8a].lastClaim = ;
//		_ls[0x221855a4666dd46283b594ac9177ccffdb1e5391].lastClaim = ;
//		_ls[0xaf170411eef875d792324b1deac0552bced3b780].lastClaim = ;
//
//		_ls[0x230440933312e6dcc0a09467c64977ea0519c373].lastClaim = ;
//		_ls[0x5f2e24a786257afe4ec8c23d5975f3f777a02e38].lastClaim = ;
//		_ls[0x83876609c394bb6f45e69cc470738034901a9120].lastClaim = ;
//		_ls[0xb23b6201d1799b0e8e209a402daaefac78c356dc].lastClaim = ;
//
//		_ls[0xf6bfccfd77af8372e836815892ac0d3f98a023db].lastClaim = ;
//		_ls[0x9aec2edfa7ad43cd5fadfc6f64809b04ea68693f].lastClaim = ;
//		_ls[0x69d01f1971eaabeefa4f6ec752b0b0d1edf7a702].lastClaim = ;
//		_ls[0xcbce294bf5276dfeacec88ae8ea4d13b26bfac6e].lastClaim = ;
//
//		_ls[0xf770a2d182300af9b3e764a5c03bda3b0bbacb5a].lastClaim = ;
//		_ls[0xc28b1f5692c3d02e6ab9631a8bef49a7750a9826].lastClaim = ;
//		_ls[0x03974898b0952c37cdac839f3e9384110f2ddfcf].lastClaim = ;
//		_ls[0x4e4cef2ca1684b88cd07685104a4a1a27518a0d3].lastClaim = ;
//
//		_ls[0x43dec6ea772951ce07991fe3d5820b96ef4e7ad2].lastClaim = ;
//		_ls[0x1924eb636f5b7949656bb3a089ea7715849bd724].lastClaim = ;
//		_ls[0xe2f607bf9e74edd29b09484c4d28e8c4b4d60e31].lastClaim = ;
//		_ls[0xc59ac386682a51af447da70f53f2ff815acfec9d].lastClaim = ;
//		
//		_ls[0x58eefc57febf367fa87e79171415010b6d9a8999].lastClaim = ;
//		_ls[0x9956d5fb78d190b630627cd40f9b5e93e8827ec4].lastClaim = ;
//		_ls[0xab769309ebceeda984e666ab727b36211ba02a8a].lastClaim = ;
//		_ls[0x8e856e84203286832851a22f8f23385f9f83228a].lastClaim = ;
//
//		_ls[0xbda6ede845ac18de045d5a49904972da5bf90dda].lastClaim = ;
//		_ls[0x9d48f02b6e47abdf2421eae668ad3ffcc62be823].lastClaim = ;
//		_ls[0x71b0e047a904b6b0263d76a10fd2c7698d5eafe7].lastClaim = ;
	}

	function lock25days(uint amount) public {// game theory disallows the deployer to exploit this lock, every time locker can exit before a malicious trust minimized upgrade is live
		_getLockRewards(msg.sender);
		_ls[msg.sender].lockUpTo=uint32(block.number+1e6);
		require(amount>0 && I(_letToken).balanceOf(msg.sender)>=amount);
		_ls[msg.sender].amount+=uint128(amount);
		I(_letToken).transferFrom(msg.sender,address(this),amount);
		totalLetLocked+=amount;
	}

	function getLockRewards() public returns(uint){
		return _getLockRewards(msg.sender);
	}

	function _getLockRewards(address a) internal returns(uint){
		uint toClaim=0;
		if(_ls[a].amount>0){
			toClaim = lockRewardsAvailable(a);
			I(_treasury).getRewards(a, toClaim);
			_ls[msg.sender].lockUpTo=uint32(block.number+1e6);
		}
		_ls[msg.sender].lastClaim=uint32(block.number);
		return toClaim;
	}

	function lockRewardsAvailable(address a) public view returns(uint) {
		if(_ls[a].amount>0){
			uint rate = 62e13;
			/// a cap to rewards
			uint cap = totalLetLocked*100/100000e18;
			if(cap>100){cap=100;}
			rate = rate*cap/100;
			///
			uint amount = (block.number - _ls[a].lastClaim)*_ls[a].amount*rate/totalLetLocked;
			return amount;
		} else {
			return 0;
		}
	}
// temporary unlock suspension
//	function unlock(uint amount) public {
//		require(_ls[msg.sender].amount>=amount && totalLetLocked>=amount && _ls[msg.sender].lockUpTo<block.number);
//		_getLockRewards(msg.sender);
//		_ls[msg.sender].amount-=uint128(amount);
//		I(_letToken).transfer(msg.sender,amount*19/20);
//		uint leftOver = amount - amount*19/20;
//		I(_letToken).transfer(_treasury,leftOver);//5% burn to treasury as spam protection
//		totalLetLocked-=amount;
//	}

// VIEW FUNCTIONS ==================================================
	function getVoter(address a) external view returns (uint amount,uint lockUpTo,uint lastClaim) {
		return (_ls[a].amount,_ls[a].lockUpTo,_ls[a].lastClaim);
	}
}