//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

pragma solidity ^0.8.0;

abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

library IterableMapping {
    //Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }
    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }
    function getIndexOfKey(Map storage map, address key) public view returns (int256) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }
    function getKeyAtIndex(Map storage map, uint256 index) public view returns (address) {
        return map.keys[index];
    }
    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }
    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }
        delete map.inserted[key];
        delete map.values[key];
        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        map.keys[index] = lastKey;
        map.keys.pop();
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
library myLib {

    using SafeMath for uint256;
    function isInList(address x, address[] memory y) internal pure returns (bool){
    	for (uint i =0; i < y.length; i++) {
            if (y[i] == x){
                return true;
            }
    	}
    	return false;
    }
    function getMultiple(uint x,uint y) internal pure returns(uint){
    	uint i;
    	while(y >0){
    		y = y - x;
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
}
abstract contract overseer is Context {
	function getGreensAmount(address _account) external virtual returns(uint256[3] memory,uint256);
  	function getCurrGreens(address _account, uint i, uint k) external virtual returns(uint256,uint256) ;
}
pragma solidity ^0.8.4;
contract NodeManager is Ownable, Pausable {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;
    struct NodeEntity {
        string name;
        uint creationTime;
        uint lastClaimTime;
        uint claimed;
        uint elapsedTime;
        uint lastPaid;
        uint nextDue;
        uint nextDueElapsed;
        bool fullPay;
        bool paid;
        bool deleted;
        uint256 amount;
        uint256 allRewards;
        uint256 rewardsTemp;
        uint256 boostTemp;
        uint256 allBoost;
        uint256 boost;
        uint dailyRewards;
    }
    struct NodeTemp {
        uint256 rewards;
        uint256 boost;
        uint256 count;
        bool insolvent;
	}
    struct TotalValues {
    	uint totalNodes;
    	uint256 Rewards;
    	uint256 totalstaked;
    	uint256 totalLost;
    	uint256 totalCreated;
    	uint256 totalClaimed;
    	}
    IterableMapping.Map private nodeOwners;
    address[] private users;
    mapping(address => NodeEntity[]) private _nodesOfUser;
    mapping(address => NodeTemp) private _tempNodes;
    mapping(address => TotalValues[]) private _totalValues;
    mapping(address => bool) private isExempt;
    address public _overseer = 0xEAF3Df5f091e13EA33f5572bDF4210bD6C553e14;
    overseer _overseer_ = overseer(_overseer);
    uint256 public dailyRewardsPerc;
    uint256 public timeStep;
    address[] private Managers;
    address public feeToken;
    address public token;
    uint8 public rewardPerNode;
    uint256 public minPrice;
    uint[] public rndm_ls;
    uint public feeCap = 60 days;
    uint256 public Zero = 0;
    uint public addTime;
    uint256 public timeOff;
    uint256 public nodeFeeTime = 31 days;
    uint256 public gracePeriod = 5 days;
    bool public timer = true;
    uint256 public feeAmount;
    uint256 public nodeAmount = 10;
    event NodeCreated(uint256 indexed amount,address indexed account,uint indexed blockTime);
    modifier managerOnly(address sender) {require(myLib.isInList(sender, Managers)== true); _;}
    modifier onlyGuard() {require(owner() == _msgSender() || token == _msgSender(), "NOT_GUARD");_;}
    modifier onlyNodeOwner(address account) {require(isNodeOwner(account), "NOT_OWNER");_;}
    constructor() {nodeFeeTime = 30 days;gracePeriod = 5 days;timer = true;feeAmount = 15*(10**8);dailyRewardsPerc = 10;timeStep = 1 minutes;}
    function queryDuePayment(address _account) external view returns (uint) {
		NodeEntity[] storage nodes = _nodesOfUser[_account];
    		uint j;
    		for(uint i=0;i<nodes.length;i++){
    			if (block.timestamp >= nodes[i].nextDue  && nodes[i].deleted != true){
    				j++;
    			}
    		}
    		return j;
    	}
    function queryFuturePayment(address _account) external view returns (uint) {
		NodeEntity[] storage nodes = _nodesOfUser[_account];
    		uint j;
    		for(uint i=0;i<nodes.length;i++){
    			if (nodes[i].nextDue < (block.timestamp + feeCap)  && nodes[i].deleted != true){
    				j++;
    			}
    		}
    		return j;
    	}
    function checkInsolvent(address _account) external{
    	NodeEntity[] storage nodes = _nodesOfUser[_account];
    	for(uint i=0;i<nodes.length;i++){
    		if (timer = false) {
    			NodeEntity storage _node = nodes[i];
    			_node.nextDue = _node.nextDueElapsed + block.timestamp;
    		}else{
    			if ((nodes[i].nextDue + 5 days) < block.timestamp  && nodes[i].deleted != true) {
    			NodeEntity storage _node = nodes[i];
		        _node.name = "deleted";
		        _node.creationTime = block.timestamp;
		        _node.lastClaimTime = block.timestamp;
		        _node.elapsedTime = Zero;
		        _node.lastPaid = block.timestamp;
			_node.nextDue = block.timestamp +nodeFeeTime;
		        _node.boostTemp =  Zero;
		        _node.paid = false;
		        _node.claimed = Zero;
		        _node.deleted = true;
		        _node.allRewards = Zero;
		        _node.rewardsTemp = Zero;
		        _node.dailyRewards = Zero;
		        _node.amount = nodeAmount;
		        _node.allBoost = Zero;
		        _node.boost = Zero;
    		}
    		}
    	}
    }
    function doPayments(address _account,uint256 payments) external {
    	NodeEntity[] storage nodes = _nodesOfUser[_account];
    	for(uint i=0;i<nodes.length;i++){
    		if (block.timestamp >= nodes[i].nextDue && payments != 0 && nodes[i].deleted != true){
    			NodeEntity storage _node = nodes[i];
    			_node.nextDue += 30 days; 
    			_node.paid = true;
    			payments -= 1;
    		}
    	}
    			
    }
    function doFuturePayments(address _account,uint256 payments) external {
    	NodeEntity[] storage nodes = _nodesOfUser[_account];
    	for(uint i=0;i<nodes.length;i++){
    		if (nodes[i].nextDue < (block.timestamp + feeCap)  && payments != 0  && nodes[i].deleted != true){
    			NodeEntity storage _node = nodes[i];
    			_node.nextDue += 30 days; 
    			payments -= 1;
    		}
    	}
    			
    }
    	
    function getNodesAmount(address _account) external view returns (uint256,uint256) {
    	NodeEntity[] storage nodes = _nodesOfUser[_account];
    	uint256 length = nodes.length;
    	uint256 time = block.timestamp;
    	return (length,time);
   	}
    function getNodesRewards(address _account, uint256 _time, uint256 k,uint256 _tier,uint256 _timeBoost) external view returns (uint256,uint256) {
    	NodeEntity[] storage nodes = _nodesOfUser[_account];
    	uint256 lastClaim = nodes[k].lastClaimTime;
    	uint256 rewards;
    	uint256 rewards_;
    	uint256 rewards_boost;
    	if (nodes[k].nextDue > _time) {	
	    	if (lastClaim < _timeBoost){
	    		(rewards_,rewards_boost) = boostLib.calcReward(dailyRewardsPerc,timeStep,_timeBoost,lastClaim,0);
	    		rewards_ = rewards;
	    		lastClaim = _timeBoost;
	    	}
	    	(rewards,rewards_boost) = boostLib.calcReward(dailyRewardsPerc,timeStep,_time,lastClaim,_tier);
	}
    	return (rewards+rewards_,rewards_boost);
   }
    function cashoutNodeReward(address _account, uint256 _time, uint256 k) external onlyGuard onlyNodeOwner(_account) whenNotPaused {
        NodeEntity[] storage nodes = _nodesOfUser[_account];
        NodeEntity storage _node = nodes[k];
        _node.lastClaimTime = _time;
    }
    function process() external onlyGuard onlyNodeOwner(owner()) whenNotPaused {
       	for (uint256 i = 0; i < users.length; i++) {
       		NodeEntity[] storage nodes = _nodesOfUser[users[i]];
        	TotalValues[] storage  total =  _totalValues[users[i]];
        	TotalValues storage  _total =  total[0];
        	
	    	_total.totalNodes = Zero;
		_total.Rewards = Zero;
		_total.totalstaked = Zero;
		for (uint256 j = 0; j < nodes.length; j++) {
			NodeEntity storage _node = nodes[j];
			_total.totalNodes++;
		      	_total.Rewards += _node.dailyRewards;
			_total.totalstaked += _node.amount;
		}
	}
    }
    
function createNode(address _account, string memory nodeName) external onlyGuard whenNotPaused  {
        require( _isNameAvailable(_account, nodeName),"Name not available");
        NodeEntity[] storage _nodes = _nodesOfUser[_account];
        TotalValues[] storage total = _totalValues[_account];
        require(_nodes.length <= 100, "Max nodes exceeded");
        if (myLib.isInList(_account,users) == false){
			users.push(_account);
        		total.push(TotalValues({
				totalNodes:Zero,
			    	Rewards:Zero,
			    	totalstaked:Zero,
			    	totalLost:Zero,
			    	totalCreated:Zero,
			    	totalClaimed:Zero
		    		}));
		 }
        _nodes.push(
        	NodeEntity({
		        name: nodeName,
		        creationTime: block.timestamp,
		        lastClaimTime: block.timestamp,
		        elapsedTime:Zero,
		        lastPaid:block.timestamp,
			nextDue:block.timestamp +nodeFeeTime,
		        boostTemp: Zero,
		        nextDueElapsed:nodeFeeTime,
		        paid:true,
		        claimed:Zero,
		        fullPay : false,
		        deleted:false,
		        allRewards: Zero,
		        rewardsTemp: Zero,
		        dailyRewards:Zero,
		        amount: nodeAmount,
		        allBoost:Zero,
		        boost: Zero

                	}));
        
        nodeOwners.set(_account, _nodesOfUser[_account].length);
        emit NodeCreated(nodeAmount, _account, block.timestamp);
        total[0].totalCreated++;
        _nodes[_nodes.length].amount += nodeAmount;
    	}
    
    function _uint2str(uint256 _i) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            j++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function getNodesNames(address _account) public view onlyNodeOwner(_account) returns (string memory) {
        NodeEntity[] storage nodes = _nodesOfUser[_account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory names = nodes[0].name;
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            names = string(abi.encodePacked(names, separator, _node.name));
        }
        return names;
    }
    function _isNameAvailable(address account, string memory nodeName) private view returns (bool) {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        for (uint256 i = 0; i < nodes.length; i++) {
            if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
                return false;
            }
        }
        return true;
    } 
    function updateTimer(uint day, uint grace, bool time) external onlyOwner {
            nodeFeeTime = day * 1 days;
    	    gracePeriod = grace * 1 days;
            if (timer == false && time == true) {
                uint period = block.timestamp - timeOff;
            	for(uint256 i = 0;i<users.length;i++){
			NodeEntity[] storage nodes = _nodesOfUser[users[i]];
			for(uint256 j = 0;j<users.length;j++){
            			NodeEntity storage _node = nodes[j];
            			_node.lastPaid = _node.lastPaid + period;
            			_node.nextDueElapsed = _node.nextDue - block.timestamp; 
            			_node.nextDue =  _node.lastPaid + nodeFeeTime;
            		}
            	}
            	timeOff = Zero;
            }
            if (timer == true && time == false) {
            		timeOff = block.timestamp;
            		timer = time;
            }
       	    
            
    	}
    function updateToken(address newToken) external onlyOwner {
        token = newToken;
    }

    function updateReward(uint8 newVal) external onlyOwner {
        rewardPerNode = newVal;
    }

    function updateNodeAmount(uint256 newVal) external onlyOwner {
        nodeAmount = newVal;
    }

    //function updateNftRewardsBoostPercs(uint8[] calldata newVal) external onlyOwner {
    //    _boostRewardPerc = newVal;
   // }
    
    function getNodeNumberOf(address account) external view returns (uint256) {
        return nodeOwners.get(account);
    }

    function isNodeOwner(address account) public view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function getAllNodes(address account) external view returns (NodeEntity[] memory) {
        return _nodesOfUser[account];
    }

    function getIndexOfKey(address account) external view onlyOwner returns (int256) {
        require(account != address(0));
        return nodeOwners.getIndexOfKey(account);
    }

    function burn(uint256 index) external onlyOwner {
        require(index < nodeOwners.size());
        nodeOwners.remove(nodeOwners.getKeyAtIndex(index));
    }
}