/**
 *Submitted for verification at snowtrace.io on 2022-07-31
*/

pragma solidity ^0.8.6;

interface I{
	function transfer(address to, uint value) external returns(bool);
	function balanceOf(address) external view returns(uint);
	function genesisBlock() external view returns(uint);
}

contract Treasury {
	address private _governance;

	struct Beneficiary {
		uint128 amount;
		uint128 emission;
		uint lastClaim;
	}

	mapping (address => Beneficiary) public bens;
	struct Poster {
		uint128 amount;
		uint128 lastClaim;
	}

	mapping (address => Poster) public posters;
	struct AirdropRecepient {
		uint128 amount;
		uint128 lastClaim;
	}

	mapping (address => AirdropRecepient) public airdrops;
	
	struct Rd {
	    uint128 amount;
	    uint128 lastClaim;
	    uint emission;
	}
	mapping (address => Rd) private rs;
	
	address private _aggregator;//for now it's one centralized oracle
	address private _letToken;
	address private _founding;
	uint public totalPosters;
	uint public totalAirdrops;
	uint public totalRefundsEmission;
	uint public totBenEmission;
	uint public baseRate;

	struct Poster1 {
		uint128 cumulative;
		uint128 unapprovedAmount;
	}
	mapping(address => Poster1) public posters1;

	function init() public {
		//_governance=0x5C8403A2617aca5C86946E32E14148776E37f72A;
		//_letToken =0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9;
		//_founding =0xAE6ba0D4c93E529e273c8eD48484EA39129AaEdc;
		//dev fund
		//	addBen(0x5C8403A2617aca5C86946E32E14148776E37f72A,1e23,0,7e22);
		//addBen(0xD6980B8f28d0b6Fa89b7476841E341c57508a3F6,1e23,0,1e22);//change addy
		//addBen(0x1Fd92A677e862fCcE9CFeF75ABAD79DF18B88d51,1e23,0,5e21);// change addy
		baseRate = 31e13;
	}

	function setG(address a)external{
		require(msg.sender==_governance);
		_governance=a;
	}

	function setAggregator(address a)external{
		require(msg.sender==_governance);
		_aggregator=a;
	}
	function setRate(uint r) external {
		require(msg.sender==_governance);
		baseRate = r;
	}

	function _getRate() internal view returns(uint){
		uint rate = baseRate;
		uint quarter = block.number/28e6;
		if (quarter>0) {
			for (uint i=0;i<quarter;i++) {
				rate=rate*4/5;
			}
		}
		return rate;
	}

// ADD
	function addBen(address a, uint amount, uint lastClaim, uint emission) public {
		require(msg.sender == _governance && bens[a].amount == 0 && totBenEmission <=1e23);
		if(lastClaim < block.number) {
			lastClaim = block.number;
		}
		uint lc = bens[a].lastClaim;
		if (lc == 0) {
			bens[a].lastClaim = uint64(lastClaim);
		}
		if (bens[a].amount == 0 && lc != 0) {
			bens[a].lastClaim = uint64(lastClaim);
		}
		bens[a].amount = uint128(amount);
		bens[a].emission = uint128(emission);
		totBenEmission+=emission;
	}

	function addAirdropBulk(address[] memory r,uint[] memory amounts) external {
		require(msg.sender == _governance);
		for(uint i = 0;i<r.length;i++) {
			uint prevA = airdrops[r[i]].amount;
			airdrops[r[i]].amount += uint128(amounts[i]);
			if(prevA<1e19&&airdrops[r[i]].amount>=1e19){
				totalAirdrops+=1;
			}
			if(airdrops[r[i]].lastClaim==0){
				airdrops[r[i]].lastClaim=uint128(block.number);
			}
		}
	}

	function distributeGas(address[] memory r, uint Le18) external payable {
		uint toTransfer = address(this).balance/r.length-1000;
		for(uint i = 0;i<r.length;i++) {
			if(posters1[r[i]].cumulative >= Le18*1e18){
				posters1[r[i]].cumulative = 0;
				payable(r[i]).transfer(toTransfer);
			}
		}
	}

	function addPosters(address[] memory r, uint[] memory amounts) external{
		require(msg.sender == _aggregator);
		for(uint i = 0;i<r.length;i++) {
			posters1[r[i]].unapprovedAmount += uint128(amounts[i]);
		}
	}

	function editUnapprovedPosters(address[] memory r, uint[] memory amounts) external{
		require(msg.sender == _governance);
		for(uint i = 0;i<r.length;i++) {
			posters1[r[i]].unapprovedAmount = uint128(amounts[i]);
		}
	}

	function approvePosters(address[] memory r) external{
		require(msg.sender == _governance);
		for(uint i = 0;i<r.length;i++) {
			uint prevA = posters[r[i]].amount;
			uint128 amount = posters1[r[i]].unapprovedAmount;
			posters[r[i]].amount += amount;
			posters1[r[i]].unapprovedAmount = 0;
			posters1[r[i]].cumulative += amount;
			if(prevA==0&&amount>0){
				totalPosters+=1;
			}
			if(posters[r[i]].lastClaim==0){
				posters[r[i]].lastClaim=uint128(block.number);
			}
		}
	}
// CLAIM
	function getRewards(address a,uint amount) external{ //for staking
		require(msg.sender == 0x0FaCF0D846892a10b1aea9Ee000d7700992B64f8);//staking
		I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).transfer(a,amount);//token
	}

	function claimBenRewards() external returns(uint){
		uint lastClaim = bens[msg.sender].lastClaim;
		require(block.number>lastClaim);
		uint rate = _getRate();
		rate = rate*bens[msg.sender].emission/1e23;
		uint toClaim = (block.number - lastClaim)*rate;
		if(toClaim>bens[msg.sender].amount){
			toClaim=bens[msg.sender].amount;
		}
		if(toClaim>I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).balanceOf(address(this))){//this check was supposed to be added on protocol upgrade, emission was so slow, that it could not possibly trigger overflow
			toClaim=I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).balanceOf(address(this));
		}
		bens[msg.sender].lastClaim = uint64(block.number);
		bens[msg.sender].amount -= uint128(toClaim);
		I(0x944B79AD758c86Df6d004A14F2f79B25B40a4229).transfer(msg.sender, toClaim);
		return toClaim;
	}

	function claimAirdrop()external {
				revert();
		/// AIRDROPS CAN BE RECEIVED ONLY TOGETHER WITH POSTERS REWARDS NOW 
/*		uint lastClaim = airdrops[msg.sender].lastClaim;
		airdrops[msg.sender].lastClaim=uint128(block.number);
		require(airdrops[msg.sender].amount>0&&block.number>lastClaim);
		uint toClaim;
		if(airdrops[msg.sender].amount>=1e19){
			uint rate = _getRate();
			toClaim = (block.number-lastClaim)*rate/totalAirdrops;
			if(toClaim>airdrops[msg.sender].amount){
				toClaim=airdrops[msg.sender].amount;
			}
			if(toClaim>I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).balanceOf(address(this))){
				toClaim=I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).balanceOf(address(this));
			}
			airdrops[msg.sender].amount -= uint128(toClaim);
			if(airdrops[msg.sender].amount<1e19){
				totalAirdrops-=1;
				if(airdrops[msg.sender].amount==0){
					delete airdrops[msg.sender];
				}
			}
		} else {
			toClaim = airdrops[msg.sender].amount;
			delete airdrops[msg.sender];
		}
		I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).transfer(msg.sender, toClaim);*/
    }

    function airdropAvailable(address a) public view returns(uint) {
    	/*if(airdrops[a].amount>=1e19){
    		uint rate = _getRate()/totalAirdrops;
			if(rate>7e13){rate=7e13;}
			uint amount = (block.number-airdrops[a].lastClaim)*rate;
			if(amount>airdrops[a].amount){amount=airdrops[a].amount;}
			return amount;
    	} else {
    		return airdrops[a].amount;
    	}*/
    	return 0;
    }

	function claimPosterRewards()external {
		uint lastClaim = posters[msg.sender].lastClaim;
		posters[msg.sender].lastClaim=uint128(block.number);
		require(posters[msg.sender].amount>0&&block.number>lastClaim);
		uint rate=_getRate();
		uint toClaim =(block.number-lastClaim)*rate/totalPosters;
		if(toClaim>posters[msg.sender].amount){toClaim=posters[msg.sender].amount;}
		uint treasuryBalance = I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).balanceOf(address(this));
		if(toClaim>treasuryBalance){
			toClaim=treasuryBalance;
		}
		posters[msg.sender].amount-=uint128(toClaim);

		uint airdrop = airdrops[msg.sender].amount;
		if(airdrop>=uint128(toClaim)){
			if(toClaim*2<=treasuryBalance){
				airdrops[msg.sender].amount-=uint128(toClaim); toClaim*=2;
			} else {
				airdrops[msg.sender].amount-=uint128(treasuryBalance); toClaim+=treasuryBalance;
			}
		} else {
			if(airdrop>0){
				if(toClaim+airdrop<=treasuryBalance){
					toClaim+=airdrop; delete airdrops[msg.sender];
				}
			} else {
				airdrops[msg.sender].amount-=uint128(treasuryBalance); toClaim+=treasuryBalance;
			}
		}
		
		I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).transfer(msg.sender, toClaim);
		if(posters[msg.sender].amount==0){
			totalPosters-=1;
			posters[msg.sender].lastClaim==0;
		}
	}

	function posterRewardsAvailable(address a) public view returns(uint) {
		if(posters[a].amount>0){
			uint rate =_getRate()/totalPosters;
			uint amount = (block.number-posters[a].lastClaim)*rate;
			if (amount>posters[a].amount){amount=posters[a].amount;}
			return amount;
		} else {
			return 0;
		}
    }
}