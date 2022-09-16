/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/coinOfficial/Staking.sol


pragma solidity ^0.8.15;


 
interface IERC20 {
   function transferFrom(
       address from,
       address to,
       uint256 amount
   ) external returns (bool);
   function transfer(address to, uint256 amount) external returns (bool);
   function balanceOf(
       address account
   ) external returns(uint256);
}
  
contract Staking is Ownable {
    using SafeMath for uint256;
    address immutable token;
    uint totalClaimable;
   
    struct pool {
        uint duration;
        uint apr;
        uint claimable;
    }
    mapping (uint => pool) pools;
    uint [] poolIds;
    mapping (uint=> uint) _totalStakeInLockedPool;
   //Unlock Pool named as stakingPool
    struct unLockPool{
       bool initialize;
       uint256 rewardFunds;
       uint256 members;
       address token;
   }
    unLockPool public stakingPool;
 
    struct user {
        uint investment;
        uint outcome;
        uint expiry;
    }
    mapping (address => mapping (uint => mapping (uint => user))) users;
   
    struct instance {
        uint [] enteries;
    }
 
    mapping (address => mapping (uint => instance)) instances;
 
    //User for Unlock Pool
    struct stakingUser{
       uint256 amount;
       uint256 stakingTime;
   }
   mapping(address=> mapping(uint256=>stakingUser)) public stakingUsers;
 
    event Stake(address _to, uint _poolId, uint _amount);
    event Claim(address _to, uint _poolId, uint _instanceId, uint _amount);
    //Events for UnlockPool
    event StakeInUnLock(address _to, uint _instance, uint _amount, uint256 stakingTime);
    event UnStakeFromUnlock(address _to, uint _instance,  uint _amount, uint256 unLockTime);
 
    constructor(address _token) {
        token = _token;
        poolIds = [1, 2, 3, 4];
 
        //initialize pools
        pools[1] = pool(30 days, 10, 0);
        pools[2] = pool(91 days, 15, 0);
        pools[3] = pool(182 days, 20, 0);
        pools[4] = pool(365 days, 30, 0);
    }
 
    modifier validPool(uint _poolId) {
        require(pools[_poolId].duration > 0, "invalid pool id");
        _;
    }
 
    function addPool(uint _poolId, uint _duration, uint _apr) external onlyOwner {
        require(pools[_poolId].duration == 0, "pool already exists");
        pools[_poolId] = pool(_duration, _apr, 0);
        poolIds.push(_poolId);
    }
       
    function stake(address _to, uint _poolId, uint _amount) external validPool(_poolId) returns (uint) {
        IERC20(token).transferFrom(_msgSender(), address(this), _amount);
        uint reward = (_amount * pools[_poolId].apr) / 100;
        uint _instanceId = getInstanceId(_to, _poolId);
        instances[_to][_poolId].enteries.push(_instanceId);
        users[_to][_poolId][_instanceId] = user(_amount, _amount + reward, block.timestamp + pools[_poolId].duration);
        pools[_poolId].claimable += _amount + reward;
        totalClaimable += _amount + reward;
        _totalStakeInLockedPool[_poolId] += _amount;
        emit Stake(_to, _poolId, _amount);
        return _instanceId;
    }
    function getTotalInstances(address _user, uint poolId)public view returns (uint){
        return instances[_user][poolId].enteries.length;
    }
 
    function claim(address _to, uint _poolId, uint _instanceId) external validPool(_poolId) {
        require(pools[_poolId].duration > 0, "invalid pool id" );
        require(users[_to][_poolId][_instanceId].investment > 0, "zero stake");
        require(users[_to][_poolId][_instanceId].expiry < block.timestamp, "time remaining");
        IERC20(token).transfer(_to, users[_to][_poolId][_instanceId].outcome);
        pools[_poolId].claimable -= users[_to][_poolId][_instanceId].outcome;
        totalClaimable -= users[_to][_poolId][_instanceId].outcome;
        uint investment=users[_to][_poolId][_instanceId].investment;
        _totalStakeInLockedPool[_poolId] -= investment;
        emit Claim(_to, _poolId, _instanceId, users[_to][_poolId][_instanceId].outcome);
        delete users[_to][_poolId][_instanceId];
    }
 
    function getPool(uint _poolId) public view validPool(_poolId) returns (uint, uint, uint) {
        return(pools[_poolId].duration, pools[_poolId].apr, pools[_poolId].claimable);
    }
 
    function getPoolIds() public view returns (uint[] memory) {
        return poolIds;
    }
 
    function getUserPool(address _to, uint _poolId, uint _instanceId) public view validPool(_poolId) returns (uint, uint, uint) {
        require(users[_to][_poolId][_instanceId].investment > 0, "zero stake");
        return(users[_to][_poolId][_instanceId].investment, users[_to][_poolId][_instanceId].outcome, users[_to][_poolId][_instanceId].expiry);
    }
 
    function getTotalClaimable() public view returns (uint) {
        return totalClaimable;
    }
 
    function getInstanceId(address _to, uint _poolId) internal view returns (uint) {
        return instances[_to][_poolId].enteries.length + 1;
    }
    function getTotalStakeInLockPool(uint poolId)public view returns (uint){
        return _totalStakeInLockedPool[poolId];
    }
 
    //<<<<<<..............UNLOCK POOL.............>>>>>>>>>>>>>>
   
   function initializePool(uint256 _rewardFunds,address _token) onlyOwner
   public{
       require(!stakingPool.initialize, "Pool Already initialized");
       require(IERC20(token).balanceOf(address(this)) >= _rewardFunds, "Enough Rewards are not funded to pool");
       stakingPool= unLockPool(true,_rewardFunds, 0, _token);
   }
 
   function addFundsToUnlock(uint256 _rewardFunds) onlyOwner public{
       require(stakingPool.initialize, "Pool Not initialized");
       IERC20(token).transferFrom(msg.sender, address(this), _rewardFunds);
       stakingPool.rewardFunds+=_rewardFunds;
   }
 
   function stakeInUnLock(address _from, uint256 _amount, uint _instance) public{
       require(_amount > 0 && stakingUsers[_from][_instance].amount==0, "You have Already Staked in this instance. Try Some other Instance");
       stakingUsers[_from][_instance].amount= _amount;
       stakingUsers[_from][_instance].stakingTime= block.number;
       IERC20(token).transferFrom(_from,address(this), _amount);
       stakingPool.members+=1;
       emit StakeInUnLock(_from, _instance, _amount, block.number);
   }
   function unStakeFromUnlock(uint256 _amount, uint256 _instance, address _to)public {
       require(stakingUsers[_to][_instance].amount >= _amount, "Not have enough staked amount");
       uint256 reward= calculateReward(_amount, _to, _instance);
       IERC20(token).transfer(_to, _amount.add(reward));
       if(stakingUsers[_to][_instance].amount.sub(_amount) > 0){
           stakingUsers[_to][_instance].amount-=_amount;
       }
       else{
           stakingUsers[_to][_instance].amount=0;
           stakingPool.members-=1;
           stakingPool.rewardFunds-= reward;
           delete stakingUsers[_to][_instance];
       }
       emit UnStakeFromUnlock(_to, _instance, _amount, block.number);
   }
   function calculateReward(uint256 amount, address _user, uint256 _instance) public view returns(uint256){
       require(stakingUsers[_user][_instance].amount >= amount, "Not Enough staked Amount by this user");
       uint256 membersRate= ((stakingPool.rewardFunds/stakingPool.members)*33)/100;
       uint256 duration=getMultiplier(block.number,stakingUsers[_user][_instance].stakingTime);
       uint256 TimeRate= duration.mul(33).div(100);
       uint256 reward= ((amount*33)/100) +  membersRate + TimeRate;
       return reward;
   }
 
   function getMultiplier(uint256 _from, uint256 _to) internal pure returns (uint256) {
       return _from.sub(_to).div(1e6);
   }
 
}