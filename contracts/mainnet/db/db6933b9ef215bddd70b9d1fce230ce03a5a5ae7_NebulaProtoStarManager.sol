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
    function calcReward(uint256 _dailyRewardsPerc,uint256 _timeStep,uint256 _timestamp, uint256 _lastClaimTime, uint256 _boost_) internal pure returns (uint256,uint256){
            uint256 _one_ = 1;
            uint256 one = _one_*(10**18)/1440;
	    uint256 elapsed = _timestamp - _lastClaimTime;
	    uint256 _rewardsPerDay = doPercentage(one, _dailyRewardsPerc);
	    (uint256 _rewardsTMul,uint256 _dayMultiple1) = getMultiple(elapsed,_timeStep,_rewardsPerDay);
	    uint256[2] memory _rewards_ = addFee(_rewardsTMul,_boost_);
	    uint256 _rewards = _rewards_[0];
	    uint256 _boost = _rewards_[1];
    	    uint256 _all  = _rewards+_boost;
    	    return (_all,_boost);
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
		function addressInList(address[] memory _list, address _account) internal pure returns (bool){
			for(uint i=0;i<_list.length;i++){
				if(_account == _list[i]){
					return true;
				}
			}
			return false;
		}
		
		function mainBalance(address _account) internal view returns (uint256){
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
}
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transferOwnership(_msgSender());
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
abstract contract feeManager is Context {
    function isInsolvent(address _account,string memory _name) external virtual view returns(bool);
    function createProtos(address _account,string memory _name) external virtual;
    function collapseProto(address _account,string memory _name) external virtual;
    function payFee() payable virtual external;
    function changeName(string memory _name,string memory new_name) external virtual;
    function viewFeeInfo(address _account,string memory _name) external virtual view returns(uint256,uint256,bool,bool,bool,bool);
    function getPeriodInfo() external  virtual returns (uint256,uint256,uint256);
    function getAccountsLength() external virtual view returns(uint256);
    function accountExists(address _account) external virtual view returns (bool);
    }
abstract contract prevNebulaProtoStarManager is Context {
    function getDeadStarsData(address _account, uint256 _x) external  virtual returns(string memory,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool);
    function protoAccountData(address _account, uint256 _x) external virtual returns(string memory,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
    function protoAccountExists(address _account) external virtual returns (bool);
    function getCollapseDate(address _account,uint256 _x) external virtual view returns(uint256);
    function getdeadStarsLength(address _account) external virtual view returns(uint256);
    function getProtoAccountsLength() external virtual view returns(uint256);
    function getProtoAddress(uint256 _x) external virtual view returns(address);
    function getProtoStarsLength(address _account) external virtual view returns(uint256);
}
abstract contract overseer is Context {
	 function getMultiplier(uint256 _x) external virtual returns(uint256);
	 function getBoostPerMin(uint256 _x) external virtual view returns(uint256);
	 function getRewardsPerMin() external virtual view returns (uint256);
	 function getCashoutRed(uint256 _x) external virtual view returns (uint256);
	 function getNftTimes(address _account, uint256 _id,uint256 _x) external virtual view returns(uint256);
	 function isStaked(address _account) internal virtual returns(bool);
	 function getNftAmount(address _account, uint256 _id) external view virtual returns(uint256);
	 function getFee() external virtual view returns(uint256);
	 function getModFee(uint256 _val) external virtual view returns(uint256);
	 function getNftPrice(uint _val) external virtual view returns(uint256);
	 function getEm() external virtual view returns (uint256);
   
} 

contract NebulaProtoStarManager is Ownable {
    string public constant name = "NebulaProtoStarManager";
    string public constant symbol = "PMGR";
    using SafeMath for uint256;
    using SafeMath for uint;
    struct PROTOstars {
	string name;
	uint256 creationTime;
	uint256 lastClaimTime;
	uint256 protoElapsed;
	uint256 rewards;
	uint256 boost;
	uint256 protoLife;
	uint256 lifeDecrease;
	uint256 collapseDate;
	bool insolvent;
    	    
    }
    struct DEADStars {
	string name;
	uint256 creationTime;
	uint256 lastClaimTime;
	uint256 protoElapsed;
	uint256 rewards;
	uint256 boost;
	uint256 collapseDate;
	bool insolvent;
	bool imploded;
    	}
    struct TIMES {
    	uint256 claimTime;
	uint256 boostRewardsMin;
	uint256 rewardsMin;
	uint256 timeBoost;
	uint256 timeRegular;
	uint256 cashoutFeeRegular;
	uint256 cashoutFee;
	uint256 lifeDecrease;
	uint256 tempRewards;
	uint256 tempBoost;
	uint256 tempTotRewards;

    }
    mapping(address => PROTOstars[]) public protostars;
    mapping(address => DEADStars[]) public deadstars;
    mapping(address => TIMES[]) public nftTimes;
    address[] public PROTOaccounts;
    address[] public PROTOtransfered;
    address[] public Managers;
    uint256[] public nftsHeld;
    uint256 public Zero = 0;
    uint256 public one = 1;
    uint256 public gas = 1*(10**17);
    uint256 public protoLife = 500 days;
    uint256 public claimFee;
    uint256 public rewardsPerMin;
    uint256[] public boostmultiplier;
    uint256[] public boostRewardsPerMin;
    uint256[] public cashoutRed;
    uint256[] public times;
    address Guard;
    bool public fees = false;
    overseer public over;
    feeManager public feeMGR;
    address public nftAddress;
    address payable public treasury;
    modifier managerOnly() {require(nebuLib.addressInList(Managers,msg.sender)== true); _;}
    modifier onlyGuard() {require(owner() == _msgSender() || Guard == _msgSender() || nebuLib.addressInList(Managers,_msgSender()) == true, "NOT_proto_GUARD");_;}
    constructor(address overseer_ ,address _feeManager, address payable _treasury ) {
    	over = overseer(overseer_);
	treasury = _treasury;
	feeMGR = feeManager(_feeManager);
	Managers.push(owner());
	rewardsPerMin = over.getRewardsPerMin();
	for(uint i=0;i<3;i++){
		boostmultiplier.push(over.getMultiplier(i));
		boostRewardsPerMin.push(over.getRewardsPerMin());	
		cashoutRed.push(over.getCashoutRed(i));
	}

    }
    
   function queryProtos(address _account) internal returns(bool){
	   PROTOstars[] storage protos = protostars[_account];
	   for(uint i=0;i<protos.length;i++){
		   PROTOstars storage proto = protos[i];
		   (uint256 nextDue,uint256 feeFroze,bool owed,bool full,bool insolvent,bool imploded) = feeMGR.viewFeeInfo(_account,proto.name);
		   if(imploded == true){
		   	collapseProto(_account,i);
		   	return false;
		   }
	  }
	  return true;

	   
   }
   function queryProtoRewards(address _account) external returns(uint256,uint256){
   	require(nebuLib.addressInList(PROTOaccounts,_account) == true,"you do not hold any active Protostars");
	while(queryProtos(_account) == false){
	   	queryProtos(_account);
	   }
	

	uint256 totalRewards;
	uint256 cashoutFee;
    	PROTOstars[] storage protos = protostars[_account];
    	TIMES[] storage times = nftTimes[_account];
    	for(uint i=0;i<protos.length;i++){
    		PROTOstars storage proto = protos[i];
		TIMES storage time = times[i];
		string memory _name = protos[i].name;
		
		if(feeMGR.isInsolvent(_account,_name) != true){
			totalRewards += time.tempTotRewards; 
			cashoutFee   += time.cashoutFee;
		}		
    	}
        return (totalRewards,cashoutFee);
   }
   function recProtoRewards(address _account) external onlyGuard{
   	PROTOstars[] storage stars = protostars[_account];
   	TIMES[] storage times = nftTimes[_account];
   	for(uint i=0;i<stars.length;i++){
	   	PROTOstars storage star = stars[i];
	   	TIMES storage time = times[i];
	   	star.lastClaimTime = star.lastClaimTime;
	   	star.protoElapsed =star.lastClaimTime - star.creationTime;
	   	star.rewards += time.tempRewards;
	   	star.lifeDecrease += time.lifeDecrease;
	   	star.boost += time.tempBoost;
	   	star.collapseDate = star.protoLife - star.lifeDecrease - star.protoElapsed;
  	}
  }
   function createBatchProto(address[] memory _accounts, string[] memory _names) external onlyGuard {
   	for(uint i=0;i<_names.length;i++){
	   	string memory _name = _names[i];
	   	for(uint j=0;i<_accounts.length;j++){
	   		address _account = _accounts[j];
	   		require(bytes(_name).length > 3 && bytes(_name).length < 32,"the Node name must be within 3 and 32 characters");
		   	require(nameExists(_account,_name) == false,"name has already been used");
		       	if (nebuLib.addressInList(PROTOaccounts,_account) == false){
			    	PROTOaccounts.push(_account);
			    }
		    	PROTOstars[] storage protos = protostars[_account];
		    	//(uint256 feePeriod,uint256 gracePeriod,uint256 protoLife) = feeMGR.getPeriodInfo();
		    	uint256 _time = block.timestamp;
		    	uint256 collapse = _time.add(protoLife);
		    	protos.push(PROTOstars({
		    	    name:_name,
		    	    creationTime:_time,
		    	    lastClaimTime:_time,
		    	    lifeDecrease:Zero,
		    	    protoElapsed:Zero,
		    	    rewards:Zero,
		    	    boost:Zero,
		    	    protoLife:protoLife,
		    	    collapseDate:collapse,
		    	    insolvent:false
		    	    }));
		    	    feeMGR.createProtos(_account,_name);
		    	  }
   		}
   	}
   
   function addProto(address _account, string memory _name) external onlyGuard  {
   	require(bytes(_name).length > 3 && bytes(_name).length < 32,"the Node name must be within 3 and 32 characters");
   	require(nameExists(_account,_name) == false,"name has already been used");
       	if (nebuLib.addressInList(PROTOaccounts,_account) == false){
	    	PROTOaccounts.push(_account);
	    }
    	PROTOstars[] storage protos = protostars[_account];
    	//(uint256 feePeriod,uint256 gracePeriod,uint256 protoLife) = feeMGR.getPeriodInfo();
    	uint256 _time = block.timestamp;
    	uint256 collapse = _time.add(protoLife);
    	protos.push(PROTOstars({
    	    name:_name,
    	    creationTime:_time,
    	    lastClaimTime:_time,
    	    lifeDecrease:Zero,
    	    protoElapsed:Zero,
    	    rewards:Zero,
    	    boost:Zero,
    	    protoLife:protoLife,
    	    collapseDate:collapse,
    	    insolvent:false
    	    }));
    	    feeMGR.createProtos(_account,_name);
    	  }
    	 
    function collapseProto(address _account, uint256 _x) internal {
    	PROTOstars[] storage protos = protostars[_account];
    	PROTOstars storage proto = protos[_x];
    	DEADStars[] storage dead = deadstars[_account];
    	(uint256 nextDue,uint256 feeFroze,bool owed,bool full,bool insolvent,bool imploded) = feeMGR.viewFeeInfo(_account,proto.name);
    	dead.push(DEADStars({
    	    name:proto.name,
    	    creationTime:proto.creationTime,
    	    lastClaimTime:proto.lastClaimTime,
    	    protoElapsed:proto.protoElapsed,
    	    rewards:proto.rewards,
	    boost:proto.boost,
	    collapseDate:proto.collapseDate,
    	    insolvent:insolvent,
    	    imploded:true

    	    }));
    	for(uint i=_x;i<protos.length;i++){
    		if(i != protos.length-1){
  			PROTOstars storage proto_bef = protos[i];
    			PROTOstars storage proto_now = protos[i+1];
    			proto_bef.name = proto_now.name;
	    	        proto_bef.creationTime = proto_now.creationTime;
	    	        proto_bef.protoElapsed = proto_now.protoElapsed;
	    	        proto_bef.collapseDate = block.timestamp;
    		}
    	}
    	protos.pop();
    	feeMGR.collapseProto(_account,proto.name);
    	}
    function transferAllProtoData(address prev) external onlyGuard() {
    		prevNebulaProtoStarManager _prev = prevNebulaProtoStarManager(prev);
    		uint256 accts = _prev.getProtoAccountsLength();
    	    	for(uint i=0;i<accts;i++){
    	    		address _account = _prev.getProtoAddress(i);
    	    		if(nebuLib.addressInList(PROTOtransfered,_account) == false){
	    	    		PROTOstars[] storage stars = protostars[_account];
	    	    		uint256 P_stars = _prev.getProtoStarsLength(_account);
	    	    		for(uint j=0;j<P_stars;j++){
		    	    		(string memory a,uint256 b,uint256 c,uint256 d,uint256 e,uint256 f,uint256 g,uint256 h,uint256 i) = _prev.protoAccountData(_account,j);
			    	    		stars.push(PROTOstars({
						    	name:a,
						    	creationTime:b,
						    	lastClaimTime:c,
						    	lifeDecrease:d,
						    	protoElapsed:e,
						    	rewards:f,
						    	boost:g,
							protoLife:h,
						    	collapseDate:i,
						    	insolvent:false
					    	    }));
			    			
		    		}
	    		}
	    	    	DEADStars[] storage dead = deadstars[_account];
	    	    	uint256 D_stars = _prev.getdeadStarsLength(_account);
	    	    	for(uint j=0;j<D_stars;j++){
	    			(string memory a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f, uint256 g, bool h,bool i) = _prev.getDeadStarsData(_account,j);
			        dead.push(DEADStars({ 

		    	        	name:a,
			        	creationTime:b,
		    	        	lastClaimTime:c,
		    	        	protoElapsed:d,
		    	        	rewards:e,
		    	        	boost:f,
		    	        	collapseDate:g,
		    	        	insolvent:h,
		    	        	imploded:i
		       	        }));
		       	}
	      		PROTOtransfered.push(_account);
	    }
	    
    }
    function nameExists(address _account, string memory _name) internal view returns(bool){
    	    	PROTOstars[] storage protos = protostars[_account];
    	    	for(uint i = 0;i<protos.length;i++) {
    			PROTOstars storage proto = protos[i];
    			string memory name = proto.name;
    			if(keccak256(bytes(name)) == keccak256(bytes(_name))){
    				return true;
    			}
    		}
    		return false;
    }
    function findFromName(address _account, string memory _name) internal view returns(uint256){
    	    	PROTOstars[] storage protos = protostars[_account];
    	    	for(uint i = 0;i<protos.length;i++) {
    			PROTOstars storage proto = protos[i];
    			if(keccak256(bytes(proto.name)) == keccak256(bytes(_name))){
    				return i;
    			}
    		}
    }
    
    function changeFeeManager(address _address) external onlyGuard {
        address _feeManager = _address;
    	feeMGR = feeManager(_feeManager); 
    }
    function changeName(string memory _name,string memory new_name) external {
    	address _account = msg.sender;
    	require(nameExists(_account,_name) == true,"name does not exists");
    	require(nebuLib.addressInList(PROTOaccounts,_account) == true,"you do not hold any Protostars Currently");
    	PROTOstars[] storage protos = protostars[_account];
    	PROTOstars storage proto = protos[findFromName(_account,_name)];
    	proto.name = new_name;
    	feeMGR.changeName(_name,new_name);
    	
    }
    function getDeadStarsData(address _account, uint256 _x) external onlyGuard() returns(string memory,uint256,uint256,uint256,uint256,uint256,bool,bool){
    		DEADStars[] storage deads = deadstars[_account];
    		DEADStars storage dead = deads[_x];
    		return (dead.name,dead.creationTime,dead.lastClaimTime,dead.rewards,dead.boost,dead.collapseDate,dead.insolvent,dead.imploded);
    }
    function protoAccountData(address _account, uint256 _x) external onlyGuard() returns(string memory,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
    		PROTOstars[] storage stars = protostars[_account];
    		PROTOstars storage star = stars[_x];
    		return (star.name,star.creationTime,star.lastClaimTime,star.protoElapsed,star.rewards,star.boost,star.protoLife,star.lifeDecrease,star.collapseDate);

    		
    	}
   
   function protoAccountExists(address _account) external returns (bool) {
    	return nebuLib.addressInList(PROTOaccounts,_account);
    }
    function getCollapseDate(address _account,string memory _name) external view returns(uint256) {
       		PROTOstars[] storage stars = protostars[_account];
    		PROTOstars storage star = stars[findFromName(_account,_name)];
    		return star.collapseDate;
    }
    function getdeadStarsLength(address _account) external view returns(uint256){
    		DEADStars[] storage deads = deadstars[_account];
        	return deads.length;
    }
    function getProtoAccountsLength() external view returns(uint256){
    	return PROTOaccounts.length;
    }
    function getProtoAddress(uint256 _x) external view returns(address){
    	return PROTOaccounts[_x];
    }
    function getProtoStarsLength(address _account) external view returns(uint256){
    	PROTOstars[] storage stars = protostars[_account];
    	return stars.length;
    }
    
    function updateTreasury(address payable _treasury) external onlyOwner() {
    	treasury = _treasury;
    }
    function updateFeeManager(address _feeManager) external onlyGuard(){
    		feeMGR = feeManager(_feeManager); 
    }
    function updateRewardsPerMin() external onlyGuard() {
    	rewardsPerMin = over.getRewardsPerMin();
	for(uint i=0;i<3;i++){
		boostRewardsPerMin[i] = over.getBoostPerMin(i);	
	}
    }
    function updateGuard(address newVal) external onlyOwner {
        Guard = newVal; //token swap address
    }
    function updateManagers(address newVal) external onlyOwner {
    	if(nebuLib.addressInList(Managers,newVal) ==false){
        	Managers.push(newVal); //token swap address
        }
    }

}