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
    function calcReward(uint256 _dailyRewardsPerc,uint256 _timeStep,uint256 _timestamp, uint256 _lastClaimTime, uint256 _boost_) internal view returns (uint256[2] memory){
            uint256 _one_ = 1;
            uint256 one = _one_*(10**18)/1440;
	    uint256 elapsed = _timestamp - _lastClaimTime;
	    uint256 _rewardsPerDay = doPercentage(one, _dailyRewardsPerc);
	    (uint256 _rewardsTMul,uint256 _dayMultiple1) = getMultiple(elapsed,_timeStep,_rewardsPerDay);
	    uint256[2] memory _rewards_ = addFee(_rewardsTMul,_boost_);
	    uint256 _rewards = _rewards_[0];
	    uint256 _boost_ = _rewards_[1];
    	    uint256 _all  = _rewards+_boost_;
    	    return [_all,_boost_];
    	   }
    function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
    	uint256 xx = 0;
   	if (y !=0){
   		xx = x.div((10000)/(y)).mul(100);
   	}
    	return xx;
    }
    function addFee(uint256 x,uint256 y) public view returns (uint256[2] memory) {
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
        bool paid;
        bool fullPay;
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
    uint256 public nodeFeeTime = 744 hours;
    uint256 public gracePeriod = 120 hours;
    bool public timer = true;
    uint256 public feeAmount;
    uint256 public nodeAmount;
    uint256[] public boostMultiplier = [25,50,75,0];
    event NodeCreated(uint256 indexed amount,address indexed account,uint indexed blockTime);
    modifier managerOnly(address sender) {require(myLib.isInList(sender, Managers)== true); _;}
    modifier onlyGuard() {require(owner() == _msgSender() || token == _msgSender(), "NOT_GUARD");_;}
    modifier onlyNodeOwner(address account) {require(isNodeOwner(account), "NOT_OWNER");_;}
    constructor(uint8 _rewardPerNode,uint256 nodeAmount) {nodeFeeTime = 30 days;gracePeriod = 5 days;timer = true;feeAmount = 15*(10**8);dailyRewardsPerc = 10;timeStep = 1 minutes;}
    function compileVars() external returns (uint256) {
       address _account = msg.sender;
    	NodeEntity[] storage nodes = _nodesOfUser[_account];
    	TotalValues[] storage _total = _totalValues[_account];
    	TotalValues storage _total_ = _total[0];
    	bool insolvent = false;
        _total_.totalNodes = Zero;
	_total_.Rewards = Zero;
    	uint256 _rewards = Zero;
    	uint256 _boostamt = Zero;
    	addTime = 0;
    	//NodeTemp storage temp = _tempNodes[_account];
    	//for (uint256 i = 0; i < tier.length; i++) {
    	//	tier[i] = tier[i].mul(5);
    	//}
    	uint256 time = block.timestamp;
	for (uint256 j = 0; j < nodes.length; j++) {
		uint256 _boost = 0;
		//if (tier[0] >= i && tier[0] != 0) {_boost = 1;}else if (tier[1] >= i && tier[1] != 0) {_boost = 2;}else if (tier[2] >= i && tier[2] != 0) {_boost = 3;}
		NodeEntity storage _node = nodes[j];
		if (timeOff != 0) {
			_node.lastPaid += block.timestamp - _node.lastPaid;
		}
		uint nextDue = _node.lastPaid + nodeFeeTime;
		bool paid = true;
		bool timeup = false;
		if (nextDue < block.timestamp && timer == true ) {
			paid = false;
			insolvent = true;
			if ((block.timestamp - _node.lastPaid) > gracePeriod){
			    delete nodes[j];
			    timeup = true;
			    require(timeup == true,"your node has been deleted due to non payment");
			}
		}
		bool full = false;
		if (paid == true){
			if (nextDue - block.timestamp > feeCap){
				full = true;
			}
		}
		uint256 lastClaim = _node.lastClaimTime;
		uint256 elapsed = time - lastClaim;
        	uint256[2] memory rew = boostLib.calcReward(dailyRewardsPerc,timeStep,time,lastClaim,boostMultiplier[0]);    //takeFee(((rewardPerDay.mul(10000).div(1440) * ((elapsed -(block.timestamp - nextDue))  / 1 minutes)) / 10000),75);
		_node.boost = boostMultiplier[0];
		_node.elapsedTime = elapsed;
		_node.boostTemp = rew[1];
		_node.rewardsTemp = rew[0];
		_node.paid = paid;
		_node.fullPay = full;
		_rewards += rew[0];
		_boostamt += rew[1];
		_total_.totalNodes++;
		_total_.Rewards += _rewards;
		}
	return _total_.Rewards;
    	//temp.rewards = _rewards;
	//temp.boost = _boostamt;
	//temp.count = nodes.length;
	//temp.insolvent = insolvent;    		  		
	}
    // Private methods
    //function getNodeReward(address _account, uint256 i) external view returns (uint256) {
    //    NodeEntity[] storage nodes = _nodesOfUser[_account];
    //    uint256 _rewards_ = nodes[i].rewardsTemp
    //    require(_rewards_ > 0, "you have no rewards to claim");
    //    return ;
    //    }
    //function getAllNodesRewards(address _account) external view returns (uint256) {
        //uint256 _rewards_ = compileVars(_account);
        //return _rewards_;
        //NodeTemp storage temp = _tempNodes[_account];
        //require(_rewards_ > 0,"you have no rewards to claim");
   // }
    function cashoutNodeReward(address _account, uint256 i) external {
        NodeEntity[] storage nodes = _nodesOfUser[_account];
        require(i > 0 && nodes.length > 0, "CASHOUT ERROR: You don't have nodes to cash-out");
        NodeEntity storage _node = nodes[i];
        require(_node.paid != false, "you must pay your node fees");
        _node.lastClaimTime = block.timestamp;
        _node.allRewards += _node.rewardsTemp;
        _node.allBoost += _node.boostTemp;
        _node.claimed += 1;
        _node.boostTemp = Zero;
        _node.rewardsTemp = Zero;
        
    }
    function cashoutAllNodesRewards(address _account) external {
        NodeTemp storage temp = _tempNodes[_account];
        require(temp.insolvent != false, "you must pay your node fees");
        require(temp.count > 0 &&  temp.rewards >0,"CASHOUT ERROR: You don't have nodes to cash-out");
        NodeEntity[] storage nodes = _nodesOfUser[_account];
        for (uint256 i = 0; i < temp.count; i++) {
            NodeEntity storage _node = nodes[i];
            _node.lastClaimTime = block.timestamp;
            _node.claimed += 1;
            _node.allRewards += _node.rewardsTemp;
            _node.allBoost += _node.boostTemp;
            _node.boostTemp = Zero;
            _node.rewardsTemp = Zero;
        }
        
    }
    function payNodeFee(address _account) internal {
    
    	NodeEntity[] storage nodes = _nodesOfUser[_account];
    	NodeEntity storage _node = nodes[returnSoonestDue(_account)];
    	_node.paid = true;
    	_node.lastPaid = _node.lastPaid + nodeFeeTime;
    	_node.nextDue = _node.lastPaid + nodeFeeTime;
    	}
    function queryPayment(address _account) internal returns(uint[2] memory){
    	NodeEntity[] storage nodes = _nodesOfUser[_account];
    	uint256 timelast;
    	uint i;
    	uint256[2] memory needs;
    	for(uint i=0;i < 12;i++){
	    	NodeEntity storage _node = nodes[i];
	    	uint next = _node.nextDue;
	    	if (block.timestamp > next){
	    		needs[0] += 1;
	    		needs[1] += 3;
	    	}
	    	if (block.timestamp >= next){
	    		uint multiple = myLib.getMultiple(nodeFeeTime , (next - block.timestamp));
	    		needs[1] = 3-multiple;
	    	}
	}
	return needs;
   }
    function returnSoonestDue(address _account) internal returns(uint ){
    	NodeEntity[] storage nodes = _nodesOfUser[_account];
    	uint lowest = 0;
    	for(uint j=0;j < nodes.length;j++) {
    		NodeEntity storage _node = nodes[j];
    		if (_node.nextDue-block.timestamp <= 60 days) {
    			if (lowest == 0){
    				lowest = _node.nextDue;
    			}
    			else if(lowest > _node.nextDue){
    				lowest = _node.nextDue;
    			}
    		}
    	}
    	return lowest;	
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
    
    function createNode(address _account, string memory nodeName) external {
        require( _isNameAvailable(_account, nodeName),"Name not available");
        NodeEntity[] storage _nodes = _nodesOfUser[_account];
        NodeTemp storage _temp = _tempNodes[_account];
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
			nextDue:nodeFeeTime,
		        boostTemp: Zero,
		        paid:true,
		        claimed:Zero,
		        fullPay : false,
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
        _nodes[0].amount += nodeAmount;
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