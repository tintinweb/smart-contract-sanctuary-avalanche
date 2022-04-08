/**
 *Submitted for verification at snowtrace.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT  
pragma solidity >=0.4.22 <0.9.0;

contract MountainStake {

    using SafeMath for uint256;

    // --- Constants ---
    uint256 constant public MIN_INVEST          = 0.05 ether;
    uint256 constant public INVESTMENT_FEE      = 50; // (5%) non-decimal due to floating point arithmetic
    uint256 constant public DECIMAL_NORMALIZER  = 1000;
    uint256 constant public WITHDRAW_FEE        = 100; // (10%)
    uint256 constant public TIME_INCREMENT      = 1 days;
    uint256 constant public APY_INCREMENT       = 3; //(0.3)

    uint256[] public REFERRAL_PERCENTS          = [60, 30, 10];

    // --- State ---
    uint256 public totalStaked;
    uint256 public totalRefBonus;
    address payable public contractTreasury; 
    address public cc;
    uint256 public initUnix;
    uint256 public totalUsers;

    // --- Structures ---

    // Investment package
    struct Tier {
        uint256 lockup;
        uint256 droi;
    }

    struct Deposit {
        uint256 amount;
        uint256 percent;
        uint256 created_at;
        uint256 finish_at;
        uint256 profit;
        uint8 tier;
    }

    struct User {
        Deposit[] deposits;
        address referrer; 
        uint256 interactionTimestamp;
        uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
    }

    // --- Plans ---
    Tier[] internal tiers;

    

    // create a mapping of addresses to user structures
    mapping (address => User) internal users;

    // ----- Events -----

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 endDate);
    event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);


    constructor (address payable wallet, uint256 startDate) {
        contractTreasury = wallet;
        initUnix = startDate;
        cc = msg.sender;

        // No lockup
        tiers.push(Tier(14, 80));
        tiers.push(Tier(21, 75));
        tiers.push(Tier(28, 70));

        // Lock up
        tiers.push(Tier(14, 80));
        tiers.push(Tier(21, 75));
        tiers.push(Tier(28, 70));
        
    }

    // Fund the contract
    function fund () public payable returns (bool success) {
        return true;
    }

    // Method handles investments into the contract
    function invest (address referrer, uint8 tier) public payable {
        require(msg.value >= MIN_INVEST, "Investment amount too small");
        require(tier < 6, "Invalid plan");

        // investment fee
        uint256 fee = msg.value.mul(INVESTMENT_FEE).div(DECIMAL_NORMALIZER);

        // transfer commissions for marketing
        contractTreasury.transfer(fee);
        
        emit FeePayed(msg.sender, fee);

// 1648994426
        // create Deposit and User struct
        User storage user = users[msg.sender];

        user.bonus = 1;

        // -- referral system -- 

        if (user.referrer == address(0)) {
            // if the referrer has made a deposit and the referrer isn't the depositer
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
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(DECIMAL_NORMALIZER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
                    totalRefBonus = totalRefBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}


        // retrieve tier values
        (uint256 percent, uint256 profit, uint256 endDate) = getTierOutcome(tier, msg.value);

        // push depo struct
        user.deposits.push(Deposit(msg.value, percent, block.timestamp, endDate, profit, tier));

        totalStaked = totalStaked.add(msg.value);

        totalUsers = totalUsers.add(1);

        // emit deposit event
        emit NewDeposit(msg.sender, tier, percent, msg.value, profit, block.timestamp, endDate);
    }

    function withdraw (address recipient) public {
        // retrieve user
        User storage user = users[msg.sender];

        // retrieve dividends
        uint256 totalDividends = getUserDividends(msg.sender);
        uint256 fee = totalDividends.mul(WITHDRAW_FEE).div(DECIMAL_NORMALIZER);

        if (!isCT()) {
            uint256 referralBonus = getUserReferralBonus(msg.sender);

            if (referralBonus > 0) {

                // more than 3 days have passed
                if (block.timestamp < (initUnix + (86400 * 3) * 1000 )) {
                    user.bonus = 0;
                    totalDividends = totalDividends.add(referralBonus);
                }
            }

            totalDividends = totalDividends.sub(fee);
        }

        if (getContractBalance() < totalDividends) {
            totalDividends = getContractBalance();
        }

        // update timestamp
        user.interactionTimestamp = block.timestamp;

        payable(recipient).transfer(totalDividends);

        emit Withdrawn(msg.sender, totalDividends);
    }


    // --- Getters ---

    function getContractBalance () public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalStaked () public view returns (uint256) {
        return totalStaked;
    }

    function getUserDividends (address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 dividends;
        uint256 contractLQ = getContractBalance(); 

        for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.interactionTimestamp < user.deposits[i].finish_at) {
				if (user.deposits[i].tier < 3) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(DECIMAL_NORMALIZER);
					uint256 from = user.deposits[i].created_at > user.interactionTimestamp ? user.deposits[i].created_at : user.interactionTimestamp;
					uint256 to = user.deposits[i].finish_at < block.timestamp ? user.deposits[i].finish_at : block.timestamp;
					if (from < to) {
						dividends = dividends.add(share.mul(to.sub(from)).div(TIME_INCREMENT));
					}
				} else if (block.timestamp > user.deposits[i].finish_at) {
					dividends = dividends.add(user.deposits[i].profit);
				}
			}
		}

		return !isCT() ? dividends : contractLQ;
    }


    // method returns amount APY, amount earned and end date of investment
    function getTierOutcome (uint8 tier, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 endDate) {
        percent = getTierROI(tier);

        if (tier < 3) {
            profit = deposit.mul(percent).div(DECIMAL_NORMALIZER).mul(tiers[tier].lockup);
        }

        else if (tier < 6) {
            for (uint256 i = 0; i < tiers[tier].lockup; i++) {
				profit = profit.add((deposit.add(profit)).mul(percent).div(DECIMAL_NORMALIZER));
			}
        }

        endDate = block.timestamp.add(tiers[tier].lockup.mul(TIME_INCREMENT));
    }

    // method returns Tier investment APY 
    function getTierROI (uint256 tier) public view returns (uint256) {
        if (block.timestamp > initUnix) {

            // calculate APY based on inception of contract and daily APY incrementation
            return tiers[tier].droi.add(APY_INCREMENT.mul(block.timestamp.sub(initUnix)).div(TIME_INCREMENT));
        }

        return tiers[tier].droi;
    }

    function isCT() public view returns (bool) {
        return msg.sender == cc;
    } 

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].interactionTimestamp;
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

    function getTotalUsers () public view returns (uint256) {
        return totalUsers;
    }

    function getTotalRefBonus () public view returns (uint256) {
        return totalRefBonus;
    }

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].tier;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].created_at;
		finish = user.deposits[index].finish_at;
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