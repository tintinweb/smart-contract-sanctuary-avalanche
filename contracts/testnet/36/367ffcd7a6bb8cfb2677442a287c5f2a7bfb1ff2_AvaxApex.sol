/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
/*
 █████  ██    ██  █████  ██   ██      █████  ██████  ███████ ██   ██ 
██   ██ ██    ██ ██   ██  ██ ██      ██   ██ ██   ██ ██       ██ ██  
███████ ██    ██ ███████   ███       ███████ ██████  █████     ███   
██   ██  ██  ██  ██   ██  ██ ██      ██   ██ ██      ██       ██ ██  
██   ██   ████   ██   ██ ██   ██     ██   ██ ██      ███████ ██   ██ 
Staking avax - AVALANCHE

*/

pragma solidity 0.8.11;

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Dev is Context{
    address private _dev;

    event DefinedDev(address indexed previousDev, address indexed newDev);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _dev = msgSender;
      emit DefinedDev(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function dev() public view returns (address) {
      return _dev;
    }

    modifier onlyDev() {
      require(_dev == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

}

contract AvaxApex is Dev {
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256[] public REFERRAL_PERCENTS = [70, 30];
    uint256 constant public PROJECT_FEE = 100;
    uint256 constant public CONTRACT_FEE = 30;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public PERCENTS_PENALTY = 100;
    uint256 constant public PERCENTS_ALLOWED_BALANCE = 250;
	uint256 constant public TIME_STEP = 1 days;
    uint256 constant public DAYS_NOT_WHALE = 2 days;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    bool public started;

	uint256 public totalInvested;
	uint256 public totalFunded;
    uint256 public totalCommisions;
    uint256 public totalUsers;
    uint256 public totalUserBlocked;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    struct BlockedState{
        uint256 date;
        uint8 times;
        bool state;
        uint256 investPenalty;
    }

    struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

    struct Referred {
		uint256 percent;
		uint256 amountPaid;
	}

    struct User {
		Deposit[] deposits;
        uint256 referralsCount;
        mapping(address => Referred) referrals;
        address[2] referral;
        uint256 checkpoint;
		uint256 bonus;
        uint256 totalBonus;
        uint256 withdrawn;
        BlockedState blocked;
	}

    //Mappings 
    mapping (address => User) internal users;
    Plan[] internal plans;
    
    address payable public commissionWallet;

    // Events for emit
    event Invest(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Funded(address indexed user, uint256 amount);
    event BlockedWhale(address indexed user);

    constructor(address payable wallet){
		commissionWallet = wallet;
        plans.push(Plan(20, 100));
		_status = _NOT_ENTERED;
	}

    function invest(address referrer, uint8 plan) public payable nonReentrant{
		if (!started) {
			if (_msgSender() == commissionWallet) {
				started = true;
			} else revert("Not started yet");
		}

        require(plan < 1, "Invalid plan");

		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
        totalCommisions = totalCommisions.add(fee);

		User storage user = users[_msgSender()];

        // Set referrer in level 1 and 2
		if (user.deposits.length == 0) {
            if(users[referrer].deposits.length > 0){
                definedReferrers(_msgSender(), referrer);
            } 
            user.checkpoint = block.timestamp;
            totalUsers++;
        }
        
        if(msg.value > user.blocked.investPenalty){
            resetBlocked(_msgSender());
        }else{
            user.blocked.investPenalty = user.blocked.investPenalty.sub(msg.value);
        }

        paidReferrers(_msgSender(), msg.value);
		user.deposits.push(Deposit(plan, msg.value, block.timestamp));
		totalInvested = totalInvested.add(msg.value);

		emit Invest(msg.sender, plan, msg.value);
	}

    function withdraw() public nonReentrant{
		User storage user = users[_msgSender()];

        require(user.checkpoint.add(TIME_STEP) <= block.timestamp, "Can only withdraw every 24 hours");
        
		uint256 totalAmount = getUserDividends(_msgSender()).add(user.bonus);
        uint256 balanceAllowed = address(this).balance.mul(PERCENTS_ALLOWED_BALANCE).div(PERCENTS_DIVIDER);
        totalAmount = totalAmount.sub(totalAmount.mul(CONTRACT_FEE).div(PERCENTS_DIVIDER));
        
        definedBLocked(user, totalAmount);

        require(!user.blocked.state, "Address is blocked");
		require(totalAmount > 0, "User has no dividends");
        require(balanceAllowed > totalAmount, "Dividends amount not allowed");

		user.checkpoint = block.timestamp;
        user.withdrawn = user.withdrawn.add(totalAmount);
        user.bonus = 0;

        payable(_msgSender()).transfer(totalAmount);

		emit Withdrawn(_msgSender(), totalAmount);
	}

    function fundContract() public payable nonReentrant {

		if (!started) {
			if (msg.sender == commissionWallet) {
				started = true;
			} else revert("Not started yet");
		}

		totalFunded = totalFunded.add(msg.value);
		emit Funded(msg.sender, msg.value);
	}

    function getUserDividends(address user_) public view returns (uint256) {
		User storage user = users[user_];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}

    /// @dev Functions that help to show info

    function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

    function getUserTotalWithdrawn(address user) public view returns (uint256) {
		return users[user].withdrawn;
	}

	function getUserCheckpoint(address user) public view returns(uint256) {
		return users[user].checkpoint;
	}

    function getUserTotalDeposits(address user) public view returns(uint256) {
        uint256 total = 0;
        for(uint256 index = 0; index < users[user].deposits.length; index++) {
            total = total.add(users[user].deposits[index].amount);
        }
        return total;
    }

	function getUserReferrer(address user) public view returns(address) {
		return users[user].referral[0];
	}

	function getUserReferralsCount(address user_) public view returns(uint256) {
		return users[user_].referralsCount;
	}

	function getUserReferralBonus(address user) public view returns(uint256) {
		return users[user].bonus;
	}

	function getUserReferralTotalBonus(address user) public view returns(uint256) {
		return users[user].totalBonus;
	}

	function getUserReferralWithdrawn(address user) public view returns(uint256) {
		return users[user].totalBonus.sub(users[user].bonus);
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

    function getUserInfoBlocked(address user_) public view returns(bool state, uint8 times, uint256 investPenalty, uint256 date) {
        BlockedState memory _blocked = users[user_].blocked;
        state = _blocked.state;
        times = _blocked.times;
        investPenalty = _blocked.investPenalty;
        date = _blocked.date;
    }

    function getUserDepositInfo(address user_, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    User storage user = users[user_];
		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
	}

    function getUserReferenceInfo(address user_, address referral_) public view returns(uint256 percent, uint256 amount) {
		percent = users[user_].referrals[referral_].percent;
		amount = users[user_].referrals[referral_].amountPaid;
    }

    function getUserInfo(address user_) public view 
        returns(uint256 checkpoint, bool blocked, uint256 numberReferral, uint256 totalBonus,uint256 totalDeposits, uint256 withdrawn, uint256 available) {
        checkpoint = getUserCheckpoint(user_);
        blocked = users[user_].blocked.state;
        numberReferral = getUserReferralsCount(user_);
        totalBonus = getUserReferralTotalBonus(user_);
        withdrawn = getUserTotalWithdrawn(user_);
        totalDeposits = getUserTotalDeposits(user_);
        available = getUserDividends(user_).add(getUserReferralBonus(user_));
    }

    /// @dev Utils and functions internal

    function definedBLocked(User storage user, uint256 amount) internal {
        if(user.blocked.times > 1){
            user.blocked.state = true;
            user.blocked.investPenalty = amount.mul(PERCENTS_PENALTY).div(PERCENTS_DIVIDER);
            totalUserBlocked++;
            if(user.blocked.date == 0){
                user.blocked.date = block.timestamp.add(DAYS_NOT_WHALE);
            }else if(user.blocked.date <= block.timestamp) {
                user.blocked.state = false;
                totalUserBlocked--;
            }
        }
    }

    function resetBlocked(address user) internal {
        users[user].blocked.state = false;
        users[user].blocked.investPenalty = 0;
        users[user].blocked.date = 0;
        users[user].blocked.times = 0;
    }

    function definedReferrers(address user_, address referrer_) internal { 
        for(uint8 index = 0; index < REFERRAL_PERCENTS.length; index++) {
            address referrer = index > 0 ? users[referrer_].referral[index.sub(1)] : referrer_;
            if(referrer != address(0)){
                users[user_].referral[index] = referrer;
                users[referrer].referrals[user_] = Referred(REFERRAL_PERCENTS[index],0);
                users[referrer].referralsCount = users[referrer].referralsCount.add(1);
            }
        }
    }

    function paidReferrers(address user_, uint256 _amount) internal {
        for(uint8 index = 0; index < REFERRAL_PERCENTS.length; index++) {
            address referrer = users[user_].referral[index];
            if(referrer != address(0)){
                uint256 amount = _amount.mul(REFERRAL_PERCENTS[index]).div(PERCENTS_DIVIDER);
                User storage user = users[referrer];
                
                user.bonus = user.bonus.add(amount);
                user.totalBonus = user.totalBonus.add(amount);
                user.referrals[user_].amountPaid = user.referrals[user_].amountPaid.add(amount);
            }else break;
        }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

}