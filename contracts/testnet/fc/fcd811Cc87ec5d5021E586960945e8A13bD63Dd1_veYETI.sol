// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IERC20.sol";
import "../Interfaces/IveYETI.sol";
import "../Dependencies/SafeMath.sol";


contract veYETI is IveYETI {
    using SafeMath for uint256;

    IERC20 yetiToken;
    uint256 _1e18 = 1e18;

    /* StakeInfo:
        -...Share is the percent of veYETI gains going to each of the pools
        -totalStake is the total amount of YETI that the user has staked
        -lastUpdate is the unix time when all the variables were last updated for the user.
         This is the last time the user called stake or unstake.
        -lastVe... is the amount of ve accumulated on an allocation as of the lastUpdate
    */
    struct StakeInfo {
        uint256 spShare;
        uint256 lpShare;
        uint256 feeShare;
        uint256 totalStake;

        uint256 lastUpdate;
        uint256 lastVeSP;
        uint256 lastVeLP;
        uint256 lastVeFee;
    }

    mapping(address => StakeInfo) stakes;
    bool initialized;

    address controllerAddress;
    uint256 accumulationRate; // veYETI accumulated per second per staked YETI

    modifier onlyController() {
        require(msg.sender == controllerAddress, "veYETI: Caller is not YetiController");
        _;
    }

    constructor(IERC20 _yeti) public {
        yetiToken = _yeti;
    }

    function initialize(address _controllerAddress, uint256 _accumulationRate) external {
        require(!initialized, "veYETI: Already set up");
        controllerAddress = _controllerAddress;
        accumulationRate = _accumulationRate;
        initialized = true;
    }


    // update the veYETI accumulation rate. Only callable by controller
    // controller calls this from behind a timelock as well.
    function updateAR(uint _newAccumulationRate) external override onlyController {
        accumulationRate = _newAccumulationRate;
    }

    
    // stake YETI and specify a new allocation of veYETI gains
    function stake(
        uint256 _amount,
        uint256 _newSPShare,
        uint256 _newLPShare,
        uint256 _newFeeShare) external {
        // check that new shares sum to 1e18 (100%)
        _requireValidShares(_newSPShare, _newLPShare, _newFeeShare);

        // pull in YETI tokens from user to stake
        require(yetiToken.transferFrom(msg.sender, address(this), _amount));

        StakeInfo memory userInfo = stakes[msg.sender];
        uint256 totalStake = userInfo.totalStake;
        uint256 lastUpdate = userInfo.lastUpdate;

        // add to total stake
        userInfo.totalStake = stakes[msg.sender].totalStake.add(_amount);

        // update shares
        userInfo.spShare = _newSPShare;
        userInfo.lpShare = _newLPShare;
        userInfo.feeShare = _newFeeShare;

        // calculate total veYETI gained since last update time
        uint256 veGrowth = totalStake.mul(accumulationRate).mul(block.timestamp.sub(lastUpdate));

        // add gains to each type of allocation proportionally
        userInfo.lastVeSP = userInfo.lastVeSP.add(veGrowth.mul(userInfo.spShare).div(_1e18));
        userInfo.lastVeLP = userInfo.lastVeLP.add(veGrowth.mul(userInfo.lpShare).div(_1e18));
        userInfo.lastVeFee = userInfo.lastVeFee.add(veGrowth.mul(userInfo.feeShare).div(_1e18));

        // set lastUpdate to current time
        userInfo.lastUpdate = block.timestamp;

        // save updates to stakes array
        stakes[msg.sender] = userInfo;
    }


    // unstake YETI and specify a new allocation of veYETI gains
    function unstake(
        uint256 _unstakeProportion,
        uint256 _newSPShare,
        uint256 _newLPShare,
        uint256 _newFeeShare) external {
        // check that new shares sum to 1e18 (100%)
        _requireValidShares(_newSPShare, _newLPShare, _newFeeShare);
        require(_unstakeProportion <= _1e18, "veYETI: Trying to unstake more than 100% of your staked YETI.");

        StakeInfo memory userInfo = stakes[msg.sender];
        uint256 totalStake = userInfo.totalStake;
        uint256 unstakeAmount = totalStake.mul(_unstakeProportion).div(_1e18);
        uint256 lastUpdate = userInfo.lastUpdate;

        // subtract from total stake
        userInfo.totalStake = stakes[msg.sender].totalStake.sub(unstakeAmount);

        // update shares
        userInfo.spShare = _newSPShare;
        userInfo.lpShare = _newLPShare;
        userInfo.feeShare = _newFeeShare;

        // calculate total veYETI gained since last update time
        uint256 veGrowth = totalStake.mul(accumulationRate).mul(block.timestamp.sub(lastUpdate));

        // add gains to each type of allocation proportionally
        userInfo.lastVeSP = userInfo.lastVeSP.add(veGrowth.mul(userInfo.spShare).div(_1e18));
        userInfo.lastVeLP = userInfo.lastVeLP.add(veGrowth.mul(userInfo.lpShare).div(_1e18));
        userInfo.lastVeFee = userInfo.lastVeFee.add(veGrowth.mul(userInfo.feeShare).div(_1e18));

        // update veYETI amounts given unstaking penalty
        uint256 postPenaltyPct = _1e18.sub(_unstakeProportion);
        userInfo.lastVeSP = userInfo.lastVeSP.mul(postPenaltyPct).div(_1e18);
        userInfo.lastVeLP = userInfo.lastVeLP.mul(postPenaltyPct).div(_1e18);
        userInfo.lastVeFee = userInfo.lastVeFee.mul(postPenaltyPct).div(_1e18);

        // set lastUpdate to current time
        userInfo.lastUpdate = block.timestamp;

        // send unstaked YETI to user
        require(yetiToken.transfer(msg.sender, unstakeAmount));

        // save updates to stakes array
        stakes[msg.sender] = userInfo;
    }
    
    
    // returns how much veYETI a user currently has on a pool.
    // _type should be 0 for SP, 1 for LP, and 2 for fee
    function getUserVeOnType(address _user, uint256 _type) external view returns (uint256) {
        StakeInfo memory userInfo = stakes[msg.sender];
        uint256 totalStake = userInfo.totalStake;
        uint256 lastUpdate = userInfo.lastUpdate;
        
        // calculate total veYETI gained since last update time
        uint256 veGrowth = totalStake.mul(accumulationRate).mul(block.timestamp.sub(lastUpdate));
        
        if (_type == 0) {
            // stability pool
            uint256 veSPGain = veGrowth.mul(userInfo.spShare).div(_1e18);
            return userInfo.lastVeSP.add(veSPGain);
        }
        if (_type == 1) {
            // curve liquidity pool
            uint256 veLPGain = veGrowth.mul(userInfo.lpShare).div(_1e18);
            return userInfo.lastVeLP.add(veLPGain);
        }
        if (_type == 2) {
            // fee reduction
            uint256 veFeeGain = veGrowth.mul(userInfo.feeShare).div(_1e18);
            return userInfo.lastVeFee.add(veFeeGain);
        }
        return 0;
    }

    
    // checks that the three inputs sum to 1e18 (100%)
    function _requireValidShares(uint256 _spShare, uint256 _lpShare, uint256 _feeShare) internal {
        require(_spShare.add(_lpShare).add(_feeShare) == _1e18, "veYETI: Shares do not sum to 1e18");
    }


}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IveYETI {
    function updateAR(uint _newAccumulationRate) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "sub overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "div by 0");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "mod by 0");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}