/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



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

contract Stake {
    using SafeMath for uint;
    using SafeMath for uint256;
    address owner;
    mapping(address => mapping(uint256 =>struct_stake)) stakes;
    mapping(address => uint256) stakeCounts;
    mapping(address => uint256) perStaked;
    uint256 public totalStaked = 0;
    uint256 public totalReward = 0;
    struct struct_stake{
        uint256 amount;
        uint256 rewardAmount;
        uint withdrawableTimeStamp;
        bool withdrawed;
        bool originalWithdrawed;
    }
    uint256 secondsInDay = 1;
    // uint256 secondsInWeek = 604800;
    uint256 secondsInWeek = 5;

    constructor() {
        owner = msg.sender;
    }

    function stake(uint256 _days) payable public{
        require(_days >= 7 , "deposit days should be greater than 7 days");
        require(_days <=21, "Maximum stake period is 21 days");
        if(msg.value > 0){
            uint256 _reward = 0;
            if(_days < 14){
                _reward = _reward.add(_days.mul(62));
            }else if(_days <21){
                _reward = _reward.add(_days.mul(74));

            }else{
                 _reward = _reward.add(_days.mul(93));
 
            }
            _reward = _reward.mul(msg.value).div(1000);
            stakes[msg.sender][stakeCounts[msg.sender]] = struct_stake(
                msg.value,
                _reward,
                block.timestamp + secondsInDay*_days,
                false,
                false
            );
            stakeCounts[msg.sender]++;     
            perStaked[msg.sender] += msg.value;
            totalStaked += msg.value;       
        }
    }

    function getStaked(address user) public view returns(uint256){
        uint256 _amount = 0;
        for(uint256 i =0;i < stakeCounts[user]; i++){
            _amount += stakes[user][i].amount;
        }
        return _amount;
    }

    function getProfitAmount(address user) public view returns(uint256){
        uint256 _profits = 0;
        for(uint256 i =0;i < stakeCounts[user]; i++){
            if(stakes[user][i].withdrawed) continue;
            if(stakes[user][i].withdrawableTimeStamp > block.timestamp) continue;
            _profits = stakes[user][i].rewardAmount.add(_profits);
        }
     
        return _profits;
    }

    function getProfitAmountTotal(address user) public view returns(uint256){
        uint256 _profits = 0;
        for(uint256 i =0;i < stakeCounts[user]; i++){
            if(stakes[user][i].withdrawed) continue;
            if(stakes[user][i].withdrawableTimeStamp > block.timestamp) continue;
            _profits = stakes[user][i].rewardAmount.add(stakes[user][i].amount).add(_profits) ;
        }
     
        return _profits;
    }

    function withdrawProfit() public payable{
        uint256 _profit = getProfitAmount(msg.sender);
        require(address(this).balance >= _profit, "Can't transfer now");     
        for(uint256 i =0;i < stakeCounts[msg.sender]; i++){
            if(!stakes[msg.sender][i].withdrawed){
                perStaked[msg.sender] = perStaked[msg.sender].sub(stakes[msg.sender][i].amount);
                totalStaked = totalStaked.sub(stakes[msg.sender][i].amount);
                stakes[msg.sender][i].withdrawed = true;
            }            
        }
        (bool os, ) = payable(msg.sender).call{value: _profit}("");
        require(os);
    }

    function getPerReward(address user) public view returns (uint256){
        return getProfitAmount(user);
    }

    function getPerRewardTotal(address user) public view returns (uint256){
        return getProfitAmountTotal(user);
    }

    function getPerStaked(address user) public view returns (uint256){
        return perStaked[user];
    }
}