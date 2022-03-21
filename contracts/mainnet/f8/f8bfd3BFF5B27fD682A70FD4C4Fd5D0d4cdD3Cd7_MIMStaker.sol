/**
 *Submitted for verification at snowtrace.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT 
 
pragma solidity >=0.4.22 <0.9.0;

contract MIMStaker {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 10 ether;
	uint256[] public REFERRAL_PERCENTS = [40, 20, 10];
	uint256 constant public PROJECT_FEE1 = 130;
    uint256 constant public PROJECT_FEE2 = 110;
    uint256 constant public PROJECT_FEE3 = 90;
	uint256 constant public PERCENT_STEP = 3;
	uint256 constant public WITHDRAW_FEE = 100; //In base point
	uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;

    address constant public token = 0x130966628846BFd36ff31a822705796e8cb8C18D;

	uint256 public totalStaked;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;
	address commissionWallet1;
    address commissionWallet2;
    address commissionWallet3;
    address commissionWallet4;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address wallet1, address wallet2, address wallet3, address wallet4, uint256 startDate) {
		require(!isContract(wallet1) && !isContract(wallet2) && !isContract(wallet3) && !isContract(wallet4));
		require(startDate > 0);
		commissionWallet1 = wallet1;
        commissionWallet2 = wallet2;
        commissionWallet3 = wallet3;
        commissionWallet4 = wallet4;
		startUNIX = startDate;

        plans.push(Plan(14, 140));
        plans.push(Plan(21, 210));
        plans.push(Plan(28, 280));
        plans.push(Plan(14, 140));
        plans.push(Plan(21, 210));
        plans.push(Plan(28, 280));
	}

	function invest(address referrer, uint256 investedAmount, uint8 plan) public {
		require(startUNIX < block.timestamp, "contract hasn`t started yet");
		require(investedAmount >= INVEST_MIN_AMOUNT,"too small");
        require(plan < 6, "Invalid plan");

        ERC20(token).transferFrom(msg.sender, address(this), investedAmount);

        uint256 fee = 0;

        if ( plan == 0 || plan == 3 ) {
            fee = investedAmount.mul(PROJECT_FEE1).div(PERCENTS_DIVIDER);
        } else if ( plan == 1 || plan == 4 ) {
            fee = investedAmount.mul(PROJECT_FEE2).div(PERCENTS_DIVIDER);
        } else if (plan == 2 || plan == 5 ) {
            fee = investedAmount.mul(PROJECT_FEE3).div(PERCENTS_DIVIDER);
        }
        
        ERC20(token).transfer(commissionWallet1, fee.div(4));
        ERC20(token).transfer(commissionWallet2, fee.div(4));
        ERC20(token).transfer(commissionWallet3, fee.div(4));
        ERC20(token).transfer(commissionWallet4, fee.div(4));

		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = investedAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, investedAmount);
		user.deposits.push(Deposit(plan, percent, investedAmount, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(investedAmount);
		emit NewDeposit(msg.sender, plan, percent, investedAmount, profit, block.timestamp, finish);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);
		uint256 fees = totalAmount.mul(WITHDRAW_FEE).div(10000);
        
		totalAmount = totalAmount.sub(fees);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = getContractBalance();
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		
        ERC20(token).transfer(msg.sender, totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

	function getContractBalance() public view returns (uint256) {
		return ERC20(token).balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		} else {
			return plans[plan].percent;
		}
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);

		if (plan < 3) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 6) {
			for (uint256 i = 0; i < plans[plan].time; i++) {
				profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
			}
		}

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 3) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}
				} else if (block.timestamp > user.deposits[i].finish) {
					totalAmount = totalAmount.add(user.deposits[i].profit);
				}
			}
		}

		return totalAmount;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

interface ERC20 {
 
     /// @param _owner The address from which the balance will be retrieved
     /// @return balance the balance
     function balanceOf(address _owner) external view returns (uint256 balance);
 
     /// @notice send `_value` token to `_to` from `msg.sender`
     /// @param _to The address of the recipient
     /// @param _value The amount of token to be transferred
     /// @return success Whether the transfer was successful or not
     function transfer(address _to, uint256 _value)  external returns (bool success);
 
     /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     /// @param _from The address of the sender
     /// @param _to The address of the recipient
     /// @param _value The amount of token to be transferred
     /// @return success Whether the transfer was successful or not
     function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
 
     /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
     /// @param _spender The address of the account able to transfer the tokens
     /// @param _value The amount of wei to be approved for transfer
     /// @return success Whether the approval was successful or not
     function approve(address _spender  , uint256 _value) external returns (bool success);
 
     /// @param _owner The address of the account owning tokens
     /// @param _spender The address of the account able to transfer the tokens
     /// @return remaining Amount of remaining tokens allowed to spent
     function allowance(address _owner, address _spender) external view returns (uint256 remaining);
 
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }