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
    uint256[] public boostMultiplier;
    uint256[] public rewards_;
    uint256 public rewards1;
    uint256 public boost1;
    uint256 public all1;
    uint256[] public rewards_2;
    uint256 public rewards2;
    uint256 public boost2;
    uint256 public all2;
    uint256[] public rewards_3;
    uint256 public rewards3;
    uint256 public boost3;
    uint256 public all3;
    uint256[] public rewards_4;
    uint256 public rewards4;
    uint256 public boost4;
    uint256 public all4;
    constructor(
    uint256 _one,
    uint256 _last,
    uint256 dailyRewardsPerc
    ){
    one = _one*(10**18);
    dailyRewardsPerc = 10;
    last = _last * 1 hours;
    timeStep = 24 hours;
    lastClaimTime = block.timestamp - last;
    rewardsPerDay = doPercentage(one, dailyRewardsPerc);
    boostMultiplier = [100,125,150,175];
    rewards_ = addFee(rewardsPerDay, boostMultiplier[0]);
    rewards1 = rewards_[0];
    boost1 = rewards_[1];
    all1  = rewards_[0]+rewards_[1];
    rewards_2 = addFee(rewardsPerDay, boostMultiplier[1]);
    rewards2 = rewards_2[0];
    boost2 = rewards_2[1];
    all2 = rewards_2[0]+rewards_2[1];
    rewards_3 = addFee(rewardsPerDay, boostMultiplier[2]);
    rewards3 = rewards_3[0];
    boost3 = rewards_3[1];
    all3  = rewards_3[0]+rewards_3[1];
    boost3 = rewards_3[1];
    rewards_4 = addFee(rewardsPerDay, boostMultiplier[3]);
    rewards4 = rewards_4[0];
    boost4 = rewards_4[1];
    all4 =  rewards_4[0]+rewards_4[1];
    }

    function isInList(address x, address[] memory y) public view returns (bool){
    	for (uint i =0; i < y.length; i++) {
            if (y[i] == x){
                return true;
            }
    	}
    	return false;
    }

    function doPercentage(uint256 x, uint256 y) public view returns (uint256) {
   	uint256 xx = x.div((10000)/(y)).mul(100);
    	return xx;
    }
    function getMultiple(uint256 x,uint256 y) public view returns (uint,uint256) {
    	uint i;
    	while(x > y){
    		x = x - y;
    		i++;
    	}
    	return (i,x);
    }
    function doPercentage2(uint256 x, uint256 y) public view returns (uint256) {
   	uint256 xx = ((x.mul(10000)).div(y)).mul(100);
    	return x;
    }
    function getPercentage(uint256 x,uint256 y) public view returns (uint256[2] memory) {
        (uint i, uint256 y_2) = getMultiple(y,100);
    	return [(x*i),doPercentage(x,y_2)];
    }
    function addFee(uint256 x,uint256 y) public view returns (uint256[2] memory) {
        (uint i, uint256 y_2) = getMultiple(y,100);
    	return [(x*i),doPercentage(x,y_2)];
    }
    function takeFee(uint256 x, uint256 y) public view returns (uint256[2] memory) {
    	uint256 fee = doPercentage2(x,y);
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