/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-08
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-08
*/

//sol
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
contract math {
using SafeMath for uint256;
    uint256 public one;
    uint256 public _one;
    uint256 public dailyRewardsPerc;
    uint256 public last;
    uint256 public _last;
    uint256 public timeStep;
    uint256 public lastClaimTime;
    uint256 public rewardsPerDay;
    uint256 public rewardsPerDay2;
    uint256 public rewardsTMul;
    uint256[] public dayMultiple;
    uint256[] public boostMultiplier;
    uint public dayMultiple0;
    uint256 public dayMultiple1;
    uint256 public dayMultiple_mul;
    uint256 public dayMultiple_mul1;
    uint256[] public all_new_0;
    uint256[] public all_new_1;
    uint256[] public all_new_2;
    uint256[] public all_new_3;

    constructor(
    uint256 _one,
    uint256 _last,
    uint256 dailyRewardsPerc
    ){
    one = (_one*(10**20))/24;
    dailyRewardsPerc = 10;
    last = _last * 1 hours;
    timeStep = 1 hours;
    lastClaimTime = block.timestamp - last;
    rewardsPerDay = doPercentage(one, dailyRewardsPerc);
    (rewardsTMul,dayMultiple1) = getMultiple(last,timeStep,rewardsPerDay);
    dayMultiple_mul = rewardsPerDay.mul(doFraction(dayMultiple1,timeStep));
    dayMultiple_mul1 = doPercentage(rewardsPerDay,doFraction(dayMultiple1,timeStep));
    rewardsTMul = rewardsTMul;
    boostMultiplier = [25,50,75,0];
    all_new_0 = calcReward(dailyRewardsPerc,timeStep,lastClaimTime,boostMultiplier[0]);
    all_new_1 = calcReward(dailyRewardsPerc,timeStep,lastClaimTime,boostMultiplier[1]);
    all_new_2 = calcReward(dailyRewardsPerc,timeStep,lastClaimTime,boostMultiplier[2]);
    all_new_3 = calcReward(dailyRewardsPerc,timeStep,lastClaimTime,boostMultiplier[3]);
    }

    function calcReward(uint256 _dailyRewardsPerc,uint256 _timeStep, uint256 _lastClaimTime, uint256 _boost) public view returns (uint256[3] memory){
	    uint256 elapsed = block.timestamp - _lastClaimTime;
	    uint256 _rewardsPerDay = doPercentage(one, _dailyRewardsPerc);
	    (uint256 _rewardsTMul,uint256 _dayMultiple1) = getMultiple(elapsed,_timeStep,_rewardsPerDay);
	    uint256[2] memory _rewards_ = addFee(_rewardsTMul,_boost);
	    uint256 _rewards = _rewards_[0];
	    uint256 _boost = _rewards_[1];
    	    uint256 _all  = _rewards+_boost;
    	    return [_all,_boost,_rewards];
    	   }
    function isInList(address x, address[] memory y) public view returns (bool){
    	for (uint i =0; i < y.length; i++) {
            if (y[i] == x){
                return true;
            }
    	}
    	return false;
    }
    function doFraction(uint256 x, uint256 y) public view returns (uint256) {
    	if (y !=0){
    		return x.div(y);
    		}
    	return 0;
    }
    function doPercentage(uint256 x, uint256 y) public view returns (uint256) {
    	uint256 xx = 0;
   	if (y !=0){
   		xx = x.div((10000)/(y)).mul(100);
   	}
    	return xx;
    }
    function getMultiple(uint256 x,uint256 y,uint256 z) public view returns (uint,uint256) {
    	uint i = 0;
    	uint256 w = z;
    	while(x > y){
    		i++;
    		x = x - y;
    		z += w;
    	}

    	return (z,x);
    }
    function getPercentage(uint256 x,uint256 y,uint256 z) public view returns (uint256[2] memory) {
        (uint256 w, uint256 y_2) = getMultiple(y,100,x);
    	return [w,doPercentage(x,y_2)];
    }
    function addFee(uint256 x,uint256 y) public view returns (uint256[2] memory) {
        (uint256 w, uint256 y_2) = getMultiple(y,100,x);
    	return [w,doPercentage(x,y_2)];
    }
    function takeFee(uint256 x, uint256 y) public view returns (uint256[2] memory) {
    	uint256 fee = 0;
    	if (y != 0){
    		fee = doPercentage(x,y);
    	}
    	uint256 newOg = x.sub(fee);
    	return [newOg,fee];
    }
       
    function updatedailyRewardsPerc(uint256 newVal) external{
        dailyRewardsPerc = newVal;
        rewardsPerDay = doPercentage(one, dailyRewardsPerc);
    }
    function updatelast(uint256 hour) external{
        _last = hour;
        last = _last*1 hours;
    }  
    function updateone(uint256 won) external{
        _one = won;
        one = _one*(10**18);
    }  
}