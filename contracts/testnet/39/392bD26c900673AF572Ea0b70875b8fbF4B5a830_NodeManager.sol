//sol
/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
library boostLib {
      using SafeMath for uint256;

      
      function calcReward(uint256 _dailyRewardsPerc,uint256 _timeStep, uint256 _lastClaimTime, uint256 _boost) internal view returns (uint256[3] memory){
            uint256 _one =1;
            uint256 one = _one*(10**18)/1440;
	    uint256 elapsed = block.timestamp - _lastClaimTime;
	    uint256 _rewardsPerDay = doPercentage(one, _dailyRewardsPerc);
	    (uint256 _rewardsTMul,uint256 _dayMultiple1) = getMultiple(elapsed,_timeStep,_rewardsPerDay);
	    uint256[2] memory _rewards_ = addFee(_rewardsTMul,_boost);
	    uint256 _rewards = _rewards_[0];
	    uint256 _boost = _rewards_[1];
    	    uint256 _all  = _rewards+_boost;
    	    return [_all,_boost,_rewards];
    	   }
    	   function addFee(uint256 x,uint256 y) internal pure returns (uint256[2] memory) {
               (uint256 w, uint256 y_2) = getMultiple(y,100,x);
    	       return [w,doPercentage(x,y_2)];
           }
           function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
    		uint256 xx = 0;
   		if (y !=0){
   			xx = x.div((10000)/(y)).mul(100);
   		}
    		return xx;
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
    function getMultiple(uint x,uint y) internal pure returns (uint){
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
    function addFee(uint256 x,uint256 y) internal pure returns (uint256[2] memory) {
    uint i;
    	uint256 y_2 = y;
    	while(y >0){
    		y_2 = y_2 - 100;
    		i++;
    	}
    	return [(x*i),doPercentage(x,(y-(100*i)))];
    }
    function takeFee(uint256 x, uint256 y) internal pure returns (uint256[2] memory) {
    	uint256 fee = doPercentage(x,y);
    	uint256 newOg = x.sub(fee);
    	return [newOg,fee];
    }
    //function addFee(uint256 x, uint256 y) internal pure returns (uint256[2] memory) {
    //	uint256 fee = doPercentage(x,y);
    //	uint256 newOg = x.add(fee);
    //	return [newOg,fee];
    //}
}

// File contracts/NodeManager.sol

/*
 *
 *    Web:      https://www.vapornodes.finance/
 *    Discord:  https://discord.gg/87XUXSeenu
 *    Twitter:  https://twitter.com/VaporNodes
 *
 */



library IterableMapping {
    // Iterable mapping from address to uint;
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
pragma solidity ^0.8.0;
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
    	uint dailyRewards;
    	uint256 totalstaked;

    	uint256 totalLost;
    	uint256 totalCreated;
    	uint256 totalClaimed;
    	}
    IterableMapping.Map private nodeOwners;
    address[] private users;
    mapping(address => NodeEntity[]) private _nodesOfUser;
    mapping(address => NodeTemp) private _tempNodes;
    mapping(address => TotalValues) private _totalValues;
    mapping(address => bool) private isExempt;
    
    address[] private Managers;
    address public feeToken;
    address public token;
    uint256 public dailyRewardsPerc;
    uint256 public minPrice;
    uint[] public rndm_ls;
    uint256 public feeCap = 60 days;
    uint256 public Zero = 0;
    uint public i;
    uint public j;
    uint public addTime;
    uint256 public timeOff;
    uint256 public nodeFeeTime = 744 hours;
    uint256 public gracePeriod = 120 hours;
    bool public timer = true;
    uint256 public feeAmount;
    uint256 public nodeAmount;
    uint256[] public _boostRewardPerc = [25,50,75];
    event NodeCreated(
        uint256 indexed amount,
        address indexed account,
        uint indexed blockTime
    );
    modifier managerOnly(address sender) {
        require(myLib.isInList(sender, Managers)== true);
        _;
    }
    modifier onlyGuard() {
        require(owner() == _msgSender() || token == _msgSender(), "NOT_GUARD");
        _;
    }
    modifier onlyNodeOwner(address account) {
        require(isNodeOwner(account), "NOT_OWNER");
        _;
    }
    constructor(
        uint256 dailyRewardsPerc,
        uint256 nodeAmount
    ) {
    nodeFeeTime = 30 days;
    gracePeriod = 5 days;
    timer = true;
    feeAmount = 15*(10**8);
    }
    // Private methods
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
    	uint256[2] memory needs;
    	for(i=0;i < 12;i++){
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
    	for(j=0;j < nodes.length;j++) {
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
       	for (i = 0; i < users.length; i++) {
       		NodeEntity[] storage nodes = _nodesOfUser[users[i]];
        	TotalValues storage  _total =  _totalValues[users[i]];
	    	_total.totalNodes = Zero;
		_total.dailyRewards = Zero;
		_total.totalstaked = Zero;
		for (j = 0; j < nodes.length; j++) {
			NodeEntity storage _node = nodes[j];
			_total.totalNodes++;
		      	_total.dailyRewards += _node.dailyRewards;
			_total.totalstaked += _node.amount;
		}
	}
    }
    function processNodeNum(address _account) internal view returns (uint){
   	NodeEntity[] storage nodes = _nodesOfUser[_account];
   	uint length = nodes.length;
       	return length;
    }
    
    function compileVars(address _account) internal returns (uint256) {

		uint256[3] memory tier = [uint256(0),uint256(0),uint256(0)];
	    	NodeEntity[] storage nodes = _nodesOfUser[_account];
	    	bool insolvent = false;
		TotalValues storage _total = _totalValues[_account];
		_total.totalNodes = Zero;
		_total.dailyRewards = Zero;
	    	uint256 _rewards = Zero;
	    	uint256 _boostamt = Zero;
	    	uint8 addTime = 0;
	    	uint nodeLength = nodes.length;
	    	require(nodeLength > 0, "you dont have any nodes");
	    	uint256[100] memory tier_ls;
	    	
	    	for (i = 0; i < 101; i++) {
    			tier_ls[i] = 0;
    		}
    		
    		uint j = 0;
    		uint j_st = 0;
    		
	    	for (i = 0; i < tier[i]; i++) {
    			tier[i] = tier[i].mul(5);
    			j_st += tier[i];
    			for (i = j;j < j_st; j++) {
    				rndm_ls[j] = _boostRewardPerc[i];
    				}
    			}
    		for (i=0;i<nodeLength;i++){
			NodeEntity storage _node = nodes[i];
			
			uint256 elapsed = block.timestamp - _node.lastClaimTime;
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
				    	delete nodes[i];
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
			uint256 timeStep = 1 minutes;
			uint256[3] memory rew = boostLib.calcReward(dailyRewardsPerc,timeStep,_node.lastClaimTime,rndm_ls[i]);
			
			_node.boost = rndm_ls[i];
			_node.elapsedTime = elapsed;
			_node.boostTemp = rew[1];
			_node.rewardsTemp = rew[0];
			_node.paid = paid;
			_node.fullPay = full;
			_rewards += _node.rewardsTemp;
			_boostamt += _node.boostTemp;

			}
		return _rewards;
    	     	//temp.rewards = _rewards;
	     	//temp.boost = _boostamt;
	     	//temp.count = nodeLength;
	     	//temp.insolvent = insolvent;
	  
    	}
    	
   
    function createNode(address _account, string memory nodeName) external {
        require( _isNameAvailable(_account, nodeName),"Name not available");
        NodeEntity[] storage _nodes = _nodesOfUser[_account];
        NodeTemp storage _temp = _tempNodes[_account];
        TotalValues storage _total = _totalValues[_account];
        require(_nodes.length <= 100, "Max nodes exceeded");
          
		  
		  	
        if (myLib.isInList(_account,users) == false){
        	users.push(_account);	
		TotalValues({
			totalNodes:Zero,
			dailyRewards:Zero,
			totalstaked:Zero,
			totalLost:Zero,
			totalCreated:Zero,
			totalClaimed:Zero
			});}
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
        _total.totalCreated++;
        _nodes[0].amount += nodeAmount;
    	}
    
    function getNodeReward(address _account) external view returns (uint256) {
        TotalValues storage total = _totalValues[_account];
	return total.dailyRewards;
        }
        
    function cashoutNodeReward(address _account) external {
        TotalValues storage total = _totalValues[_account];
	total.dailyRewards = Zero;
        
    }
    function getNodesNames(address _account) public view returns (string memory) {
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
    function updateTimer(uint day, uint grace, bool time) external {
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

    function updateRewardPerc(uint256 newVal) external onlyOwner {
        dailyRewardsPerc = newVal;
    }

    function updateNodeAmount(uint256 newVal) external onlyOwner {
        nodeAmount = newVal;
    }

    function updateNftRewardsBoostPercs(uint8[] calldata newVal) external onlyOwner {
        _boostRewardPerc = newVal;
    }
    
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