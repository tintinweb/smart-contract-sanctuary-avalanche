/**
 *Submitted for verification at snowtrace.io on 2022-08-30
*/

/**
 *Submitted for verification at snowtrace.io on 2022-08-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
library boostLib {
    using SafeMath for uint256;
    function boostPerDay(uint256 _dailyRewardsPerc) internal pure returns(uint256){
            uint256 _one_ = 1;
            uint256 one = _one_*(10**18)/1440;
	    uint256 _rewardsPerMin = doPercentage(one, _dailyRewardsPerc);
	    return _rewardsPerMin;
    }
	
    function calcReward(uint256 _rewardsPerMin,uint256 _timeStep,uint256 _timestamp, uint256 _lastClaimTime, uint256 _boost_) internal pure returns (uint256){
	    uint256 elapsed = _timestamp - _lastClaimTime;
	    (uint256 _rewardsTMul,uint256 _dayMultiple1) = getMultiple(elapsed,_timeStep,_rewardsPerMin);
	    uint256[2] memory _rewards_ = addFee(_rewardsTMul,_boost_);
	    uint256 _rewards = _rewards_[0];
	    uint256 _boost = _rewards_[1];
    	    uint256 _all  = _rewards+_boost;
    	    return _all;
    	   }
    function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
    	uint256 xx = 0;
   	if (y !=0){
   		xx = x.div((10000)/(y)).mul(100);
   	}
    	return xx;
    }
    function addFee(uint256 x,uint256 y) internal pure returns (uint256[2] memory) {
        (uint256 w, uint256 y_2) = getMultiple(y,100,x);
    	return [w,doPercentage(x,y_2)];
    }
    function getMultiple(uint256 x,uint256 y,uint256 z) internal pure returns (uint,uint256) {
    	uint256 Zero = 0;
    	if(x == Zero || y == Zero || z == Zero){
    		return(z,Zero);
    	}
    	uint i = 0;
    	uint256 w = z;
    	while(x > y){
    		i++;
    		x = x - y;
    		z += w;
    	}

    	return (z,x);
    }
    function isInList(address x, address[] memory y) internal pure returns (bool){
    	for (uint i =0; i < y.length; i++) {
            if (y[i] == x){
                return true;
            }
    	}
    	return false;
    }
}
library nebuLib {
	using SafeMath for uint256;
	function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
	    	uint256 Zero = 0;
	    	uint256 xx = Zero;
	   	if (y == Zero){
	   		return x;
	   	}else if(x == Zero){
	   		return Zero;
	   	}
	   	xx = x.div((10000)/(y)).mul(100);
	    	return xx;
	    }
}
contract math {

	using SafeMath for uint256;
	uint256 Zero = 0;
	uint256[] public NFTtiers = [Zero,uint256(1),uint256(2),uint256(3)];
	uint256[] public _boosts =[0,25,50,75];
	uint256 public time = block.timestamp;
	uint256 public lastClaimTime = time - 1 seconds;
	uint256 public cashoutFee = 10;
	uint256[] public rewards = [10,1];
    	uint256 public dailyRewardsPerc = rewards[0];
    	uint256 public rewardsPerMin = boostLib.boostPerDay(dailyRewardsPerc);
    	uint256 public timeStep = rewards[1].mul(24*60*60);
  	uint256[] public boostMultiplier = [_boosts[0],_boosts[1],_boosts[2],_boosts[3]];
  	uint256[] public boostRewardsPerMin = [boostLib.calcReward(rewardsPerMin,timeStep,time,lastClaimTime,boostMultiplier[0]),boostLib.calcReward(rewardsPerMin,timeStep,time,lastClaimTime,boostMultiplier[1]),boostLib.calcReward(rewardsPerMin,timeStep,time,lastClaimTime,boostMultiplier[2]),boostLib.calcReward(rewardsPerMin,timeStep,time,lastClaimTime,boostMultiplier[3])];
  	uint256[] public _cashoutRed = [0,0,5,10];
  	uint256[] public nftCashoutPercs = [nebuLib.doPercentage(cashoutFee,_cashoutRed[0]),nebuLib.doPercentage(cashoutFee,_cashoutRed[1]),nebuLib.doPercentage(cashoutFee,_cashoutRed[2]),nebuLib.doPercentage(cashoutFee,_cashoutRed[3])];
		function reworkit(uint256 _time) external{
			NFTtiers = [Zero,uint256(1),uint256(2),uint256(3)];
			_boosts =[0,25,50,75];
			time = block.timestamp;
			lastClaimTime = time - 1 minutes;
			cashoutFee = 10;
			rewards = [10,1];
		    	dailyRewardsPerc = rewards[0];
		    	rewardsPerMin = boostLib.boostPerDay(dailyRewardsPerc);
		    	timeStep = rewards[1].mul(_time);
		  	boostMultiplier = [_boosts[0],_boosts[1],_boosts[2],_boosts[3]];
		  	boostRewardsPerMin = [boostLib.calcReward(rewardsPerMin,timeStep,time,lastClaimTime,boostMultiplier[0]),boostLib.calcReward(rewardsPerMin,timeStep,time,lastClaimTime,boostMultiplier[1]),boostLib.calcReward(rewardsPerMin,timeStep,time,lastClaimTime,boostMultiplier[2]),boostLib.calcReward(rewardsPerMin,timeStep,time,lastClaimTime,boostMultiplier[3])];
		  	_cashoutRed = [0,0,5,10];
		  	nftCashoutPercs = [nebuLib.doPercentage(cashoutFee,_cashoutRed[0]),nebuLib.doPercentage(cashoutFee,_cashoutRed[1]),nebuLib.doPercentage(cashoutFee,_cashoutRed[2]),nebuLib.doPercentage(cashoutFee,_cashoutRed[3])];
		}

		function addressInList(address[] memory _list, address _account) internal pure returns (bool){
			for(uint i=0;i<_list.length;i++){
				if(_account == _list[i]){
					return true;
				}
			}
			return false;
		}
		function getAllMultiple(uint256 _x,uint256 _y)internal pure returns(uint256,uint256){
			uint256 Zero = 0;
			if (_y == Zero || _x == Zero || _x > _y){
				return (Zero,_y);
			}
			uint256 z = _y;
			uint256 i = 0;
			while(z >= _x){
				
				z -=_x;
				i++;
							
			}
			return (i,z);
		}
		function getDecimals(uint256 _x) internal view returns(uint){
			uint i = 0;
			while(_x != 0){
				_x = _x.div(10);
				i++;
			}
			return i;
		}
		function elimZero(uint256 _y) internal view returns(uint256){
			uint i = getDecimals(_y);
			uint dec = i;
			uint refDec = i;
			uint _n = 0;
			uint k = 0;
			while(_n ==0 && refDec!=0){
				refDec -= 1;
				_n = _y.div(10**refDec);
				k +=1;
			}
			return k;
		}
		function sendPercentage(uint256 _x,uint256 perc) internal view returns(uint256){
			uint256 exp = getDecimals(_x);
			uint256 percDec = getDecimals(perc);
			uint denom =  21-percDec;
			uint trunc = elimZero(perc);
			uint[3] memory range = [exp,denom,trunc];
			uint256 _y = _x.mul(10**range[0]);
			uint256 _z = _y.mul(perc);
			return _z.div(10**(denom+percDec));
			
		}
		function EXTsendPercentage(uint256 _x,uint256 perc) external view returns(uint256){
			uint256 exp = getDecimals(_x);
			uint256 percDec = getDecimals(perc);
			uint denom =  21-percDec;
			uint trunc = elimZero(perc);
			uint[3] memory range = [exp,denom,trunc];
			uint256 _y = _x.mul(10**range[0]);
			uint256 _z = _y.mul(perc);
			return _z.div(10**(denom+percDec));
		}
		
		function safeDivs(uint256 _x,uint256 _y) internal view returns(uint256){
			uint256 refDecOne = getDecimals(_x);
			uint256 refDecTwo = getDecimals(_y);
			uint256 newRef = _x*(10**refDecTwo);
			uint256 newDiv = newRef/_y;
			return newDiv;
			
		}
		function safeDivs2(uint256 _x,uint256 _y) external view returns(uint256){
			uint256 refDecOne = getDecimals(_x);
			uint256 refDecTwo = getDecimals(_y);
			uint256 newRef = _x*(10**refDecTwo);
			uint256 newDiv = newRef/_y*(10**refDecOne);
			return newDiv;
			
		}
		function EXTsafeDivs(uint256 _x,uint256 _y) external view returns(uint256){
			return safeDivs(_x,_y);
		}
		function getRemainder(uint256 _x,uint256 _y)internal pure returns(uint256){
			(uint256 mult,uint256 rem) =  getAllMultiple(_x,_y);
			return rem;
		}
		function getMultiple(uint256 _x,uint256 _y)internal pure returns(uint256){
			(uint256 mult,uint256 rem) = getAllMultiple(_x,_y);
			return mult;
		}
		function doMultiple(uint256 _x,uint256 _y)internal pure returns(uint256){
			uint256 Zero = 0;
			if (_y == Zero || _x == Zero || _x > _y){
				return Zero;
			}
			uint256 _z = _y;
			uint256 One = 1;
			while(_x > One){
				_z += _y;
				_x.sub(One); 		
			}
			return _z;
		}
		function otherPercentage(uint256 _x,uint256 perc) external view returns(uint256[3] memory){
			uint256 exp = getDecimals(_x);
			uint256 percDec = getDecimals(perc);
			uint denom =  21-percDec;
			uint trunc = elimZero(perc);
			uint[3] memory range = [exp,denom,trunc];
			uint256 _y = _x.mul(10**range[1]);
			uint256 _z = _y.mul(perc);
			return [range[0],_z.div(10**exp),_z];
			
		}
		function findInList(address[] memory _ls,address _account) internal pure returns(uint){
			for(uint i = 0;i<_ls.length;i++){
				if(_ls[i] == _account){
					return i;
				}
			}
		}
		function isLower(uint256 _x,uint256 _y) internal pure returns(bool){
			if(_x<_y){
				return true;
			}
			return false;
		}
		function isHigher(uint256 _x,uint256 _y) internal pure returns(bool){
			if(_x>_y){
				return true;
			}
			return false;
		}
		function isEqual(uint256 _x,uint256 _y) internal pure returns(bool){
			if(isLower(_x,_y)==false && isHigher(_x,_y) ==false){
				return true;
			}
			return false;
		}
		function getLower(uint256 _x,uint256 _y) internal pure returns(uint256){
			if(isEqual(_x,_y)==true || isLower(_x,_y) == true){
				return _x;
			}
			return _y;
		}
		function getHigher(uint256 _x,uint256 _y) internal pure returns(uint256){
			if(isEqual(_x,_y)==true || isHigher(_x,_y) == true){
				return _x;
			}
			return _y;
		}
		function safeSub(uint256 _x,uint256 _y) internal pure returns(uint256,bool){
			uint256 Zero = 0;
			if(isLower(_x,_y)==true){
				return (Zero,false);
			}
			return (_x.sub(_y),true);
		}
		function EXTsafeSub(uint256 _x,uint256 _y) external pure returns(uint256,bool){
			uint256 Zero = 0;
			if(isLower(_x,_y)==true){
				return (Zero,false);
			}
			return (_x.sub(_y),true);
		}
		function safeSubAbs(uint256 _x,uint256 _y) external pure returns(uint256){
			(uint256 _amount,bool _isTrue) = safeSub(_x,_y);
			return _amount;
		}
}