/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-07
*/

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

// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
library nebuLib {
		using SafeMath for uint256;
		function addressInList(address[] memory _list, address _account) internal pure returns (bool){
			for(uint i=0;i<_list.length;i++){
				if(_account == _list[i]){
					return true;
				}
			}
			return false;
		}
		function mainBalance(address _account) internal returns (uint256){
			uint256 _balance = _account.balance;
			return _balance;
		}
		function getMultiple(uint256 _x,uint256 _y)internal pure returns(uint256){
			uint256 Zero = 0;
			if (_y == Zero || _x == Zero || _x > _y){
				return Zero;
			}
			uint256 z = _y;
			uint256 i = 0;
			while(z >= _x){
				z -=_x;
				i++;			
			}
			return i;
		}
		function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
		   	uint256 xx = x.div((10000)/(y*100));
		    	return xx;
		   }
		   function takeFee(uint256 x, uint256 y) internal pure returns (uint256[2] memory) {
		    	uint256 fee = doPercentage(x,y);
		    	uint256 newOg = x.sub(fee);
		    	return [newOg,fee];
		   }
		   function addFee(uint256 x, uint256 y) internal pure returns (uint256[2] memory) {
		    	uint256 fee = doPercentage(x,y);
		    	uint256 newOg = x.add(fee);
		    	return [newOg,fee];
		   }
		   function isInList(address[6] memory _list ,address[2] memory _accounts) internal pure returns(bool) {
		    	for(uint j=0;j < _accounts.length;j++){
			   	for(uint i=0;i < _list.length;i++){
			   		if (_accounts[j] == _list[i]){
			   			return true;
			   		}
			   	}
				return false;
		   	} 
		    }
}
library myLib {
   using SafeMath for uint256;
    function getBoostList(uint256[3] memory tiers,uint256[3] memory _boostMultiplier) internal pure returns (uint256[100] memory){
    	uint256[100] memory tier_ls;
    	for(uint i=0;i<100;i++){
    		tier_ls[i] = 0;
    	}
    	uint j;
    	for(uint i=0;i<tiers.length;i++){
    		tiers[i].mul(5);
    		uint j_st = j + tiers[i];
    		for(uint j=j;j<j_st;j++){
    			tier_ls[j] = _boostMultiplier[i];
    		}
    	}
    	return tier_ls;
    }
   function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
   	uint256 xx = x.div((10000)/(y*100));
    	return xx;
   }
   function takeFee(uint256 x, uint256 y) internal pure returns (uint256[2] memory) {
    	uint256 fee = doPercentage(x,y);
    	uint256 newOg = x.sub(fee);
    	return [newOg,fee];
   }
   function addFee(uint256 x, uint256 y) internal pure returns (uint256[2] memory) {
    	uint256 fee = doPercentage(x,y);
    	uint256 newOg = x.add(fee);
    	return [newOg,fee];
   }
   function isInList(address[6] memory _list ,address[2] memory _accounts) internal pure returns(bool) {
    	for(uint j=0;j < _accounts.length;j++){
	   	for(uint i=0;i < _list.length;i++){
	   		if (_accounts[j] == _list[i]){
	   			return true;
	   		}
	   	}
		return false;
   	} 
    }
}
library txnTokenLib {
	
	function isInList(address[] memory _list ,address _account) internal pure returns(bool) {
		   for(uint i=0;i < _list.length;i++){
		   	if (_account == _list[i]){
		   		return true;
		   	}
		   }
		return false;
	   	} 
	    
}
abstract contract overseer is Context {
	 function getMultiplier(uint256 _x) external virtual returns(uint256);
	 function getBoostPerMin(uint256 _x) external view virtual returns(uint256);
	 function getRewardsPerMin() external view virtual returns (uint256);
	 function getCashoutRed(uint256 _x) external view virtual returns (uint256);
	 function getNftTimes(address _account, uint256 _id,uint256 _x) external view virtual returns(uint256);
	 function isStaked(address _account) internal virtual returns(bool);
	 function getNftAmount(address _account, uint256 _id) external virtual returns(uint256);
	 function getFee() external view virtual returns(uint256);
	 function getModFee(uint256 _val) external view virtual returns(uint256);
	 function getNftPrice(uint _val) external view virtual returns(uint256);
	 function getEm() external view virtual returns (uint256);
}
contract handler is Ownable{
	using SafeMath for uint256;
	struct DROPS{
		uint256 dropped;
		uint256 claimed;
		uint256 transfered;
		uint256 preSale;
		uint256 protos;
		}
	struct ACCOUNTSTATS{
		uint256 totalProtos;
		uint256 collapsedStars;
		uint256 implodedStars;
		uint256 totalRewards;
		uint256 unclaimedRewards;
		uint256 rewardsPerMin;
		uint256 totalFeesPaid;
		uint256 futurePayments;
		uint256 feesOwed;
		uint256 totalPayable;
		uint256 nftsOwned;
		}
	
	struct PROTOBOOLS {
		bool owed;
		bool full;
		bool insolvent;
		bool imploded;
		bool collapsed;
		}
	struct PROTOSTATS{
		string name;
		uint256 creationTime;
		uint256 collapseDate;
		uint256 lifeSpan;
		uint256 totalRewards;
		uint256 unclaimedRewards;
		uint256 lastClaim;
		uint256 nextDue;
		uint256 feeFroze;
		uint256 totalPayable;


		}
	
	


	mapping(address => DROPS) public drops;
	mapping(address => ACCOUNTSTATS) public accountstats;

	mapping(address => PROTOSTATS[]) public protostats;




	mapping(address => PROTOBOOLS[]) public protobools;
	uint256 public ZERO;
	address overSeer = 0xc00E5e886e571c5451766289e3fe73BD2FfA0A5A;
	overseer over = overseer(overSeer);
	uint256 public Zero;
	uint256 protoLife = 500 days;
	address[] public Accounts;
    	address[] public Managers;
        function addressInList(address _account,address[] memory _list) internal view returns(bool){
    		for(uint i = 0;i<Accounts.length;i++){
    			if(_account == Accounts[i]){
    			return true;
    			}
    		}
    		return false;
    	}
    	function addressIfThenAdd(address _account) internal{
    		if(addressInList(_account,Accounts) == false){
    			Accounts.push(_account);
    		}
    	}
    	function stringCompare(string memory _name,string memory _compare) internal returns(bool){
    		if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(_compare))) {
    			return true;
    		}
    		return false;
    	}
    	function calculateBoosts(address _account) internal {
    		   
    		   uint256 time = block.timestamp;
		   uint256 rewPerMin = over.getRewardsPerMin();
		   uint256[3] memory NFTholds;
		   uint256 protCount = 0;
		   NFTholds = [uint256(1),uint256(3),uint256(6)];
		   for(uint i=0;i<3;i++){
		   	uint256 NFTCount;
		   	if(NFTholds[i] != 0 && NFTCount < NFTholds[i] && protCount < accountstats[_account].totalProtos){
		   		for(uint j=0;j<NFTholds[i];j++){
		   			uint256 currNFTtime = over.getNftTimes(_account,i,j);
		   			for(uint k=0;k<5;k++){
		   				if(time<protostats[_account][protCount].nextDue){
			   				uint256 lastClaim = protostats[_account][protCount].lastClaim;
			   				uint256 lapsed = time.sub(lastClaim);
			   				uint256 boostLapsed = time.sub(currNFTtime);
			   				uint256 regularRew = nebuLib.getMultiple(1 minutes,lapsed.sub(boostLapsed)).mul(rewPerMin);
			   				uint256 boostRew = nebuLib.getMultiple(1 minutes,time.sub(currNFTtime)).mul(over.getBoostPerMin(i));
			   				protostats[_account][protCount].lifeSpan += nebuLib.addFee(lapsed,over.getMultiplier(i))[0];
			   				if(protostats[_account][protCount].lifeSpan > protoLife){
			   					uint256 subtract = protoLife.sub(protostats[_account][protCount].lifeSpan);
			   					protostats[_account][protCount].unclaimedRewards = subtract.mul(nebuLib.doPercentage((regularRew+boostRew),(lapsed.div(1 minutes))));
			   					accountstats[_account].unclaimedRewards = protostats[_account][protCount].unclaimedRewards;
			   					protobools[_account][protCount].collapsed = true;
			   				}else{
			   					protostats[_account][protCount].unclaimedRewards = boostLapsed.add(regularRew);
			   					accountstats[_account].unclaimedRewards = protostats[_account][protCount].unclaimedRewards;
			   					protCount++;
			   				}
		   				}
		   			
		   			
		   			}
		   			NFTCount--;
		   		}
		   		
		   	}
		   }
	   	for(uint i=protCount;i<accountstats[_account].totalProtos;i++){
	   		if(time<protostats[_account][i].nextDue){
			   	uint256 lastClaim = protostats[_account][i].lastClaim;
				uint256 lapsed = time.sub(lastClaim);
		   		uint256 regularRew = nebuLib.getMultiple(1 minutes,lapsed).mul(rewPerMin);
		   		protostats[_account][protCount].unclaimedRewards = regularRew;
			   	accountstats[_account].unclaimedRewards = protostats[_account][protCount].unclaimedRewards;
			   	
			   	protostats[_account][protCount].lifeSpan += lapsed;
	   	}
	   
    		}
    	}
	function updatedrops(address _account,uint256 dropped,uint256 claimed,uint256 transfered,uint256 preSale,uint256 protos) external {
		drops[_account].dropped = dropped;
		drops[_account].claimed = claimed;
		drops[_account].transfered = transfered;
		drops[_account].preSale = preSale;
		drops[_account].protos = protos;
	}
	
	
	function updateprotoname(address _account,uint256 _x,string memory _name) internal{
				protostats[_account][_x].name = _name;
		}

		function updateprotolastClaim(address _account,uint256 _x,uint256 lastClaim) internal{
				protostats[_account][_x].lastClaim = lastClaim;
		}
		function updateprotocollapseDate(address _account,uint256 _x,uint256 collapseDate) internal{
				protostats[_account][_x].collapseDate = collapseDate;
		}
		function updateprotofeeFroze(address _account,uint256 _x,uint256 feeFroze) internal{
				protostats[_account][_x].feeFroze = feeFroze;
		}
		function updateprotototalPayable(address _account,uint256 _x,uint256 totalPayable) internal{
				protostats[_account][_x].totalPayable = totalPayable;
		}
		function updateprotocreationTime(address _account,uint256 _x,uint256 creationTime) internal{
				protostats[_account][_x].creationTime = creationTime;
		}
		function updateprotonextDue(address _account,uint256 _x,uint256 nextDue) internal{
				protostats[_account][_x].nextDue = nextDue;
		}
		function updateprotoowed(address _account,uint256 _x,bool owed) internal{
				protobools[_account][_x].owed = owed;
		}
		function updateprotofull(address _account,uint256 _x,bool full) internal{
				protobools[_account][_x].full = full;
		}
		function updateprotoinsolvent(address _account,uint256 _x,bool insolvent) internal{
				protobools[_account][_x].insolvent = insolvent;
		}
		function updateprotoimploded(address _account,uint256 _x,bool imploded) internal{
				protobools[_account][_x].imploded = imploded;
		}
		function updateprotocollapsed(address _account,uint256 _x,bool collapsed) internal{
				protobools[_account][_x].collapsed = collapsed;
		}
		
		

	
	
		function addprotostats(address _account,string memory name) external {
		PROTOSTATS[] storage _protostats = protostats[_account];
		_protostats.push(PROTOSTATS({
			name:name,
			creationTime:Zero,
			collapseDate:Zero,
			lifeSpan:Zero,
			totalRewards:Zero,
			unclaimedRewards:Zero,
			lastClaim:Zero,
			nextDue:Zero,
			feeFroze:Zero,
			totalPayable:Zero

	

		
		}));
	}
	function getdrops(address _account,uint256 _x) external returns(uint256,uint256,uint256,uint256,uint256){
		DROPS storage _drops = drops[_account];
		return (_drops.dropped,_drops.claimed,_drops.transfered,_drops.preSale,_drops.protos);
	}
	 
	
	
	
	
	
	
		
	function getprotostatsLength(address _account,uint256 _x) external returns(uint256){
		PROTOSTATS[] storage _protostats = protostats[_account];
		PROTOSTATS storage _protostats_ = _protostats[_x];
		return _protostats.length;
	}

	
}