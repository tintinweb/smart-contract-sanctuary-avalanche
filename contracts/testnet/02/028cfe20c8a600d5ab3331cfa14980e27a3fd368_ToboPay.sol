/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-13
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ToboPay {
	using SafeMath for uint256;

	/** default percentages **/
	uint256 public PROJECT_FEE = 25; // 2.5%
	uint256 public MKT_BUYBACK_FEE = 25; // 2.5%
	uint256 public SUSTAINABILITY_TAX = 100; // 10% withdraw tax
    //uint256 public LEADERS_POOL = 100; // 10% @ 2% each leader
    uint256 public OWNER_FEE = 100; // 10%
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

    /* 35% total referral bonus upto 15th level **/
    uint8[] REFERRAL_BONUSES = [20, 4, 3, 2, 1];

	/* whale control features. **/
	uint256 public CUTOFF_STEP = 24 * 60 * 60; // 24 hours
	uint256 public WITHDRAW_COOLDOWN = 168 * 60 * 60; //  7 days
	uint256 public COMPOUND_COOLDOWN = 120 * 60 * 60; // 5 days
    uint256 public REINVEST_BONUS = 0;
	uint256 public MAX_WITHDRAW = 10 ether; // 10 BNB
	uint256 public WALLET_LIMIT = 5 ether;  // 5 BNB

        /** deposits after this timestamp gets additional percentages **/
        uint256 public PERCENTAGE_BONUS_STARTTIME = 0;
	    uint256 public PERCENTAGE_BONUS_PLAN_1 = 0;
        uint256 public PERCENTAGE_BONUS_PLAN_2 = 0;
        uint256 public PERCENTAGE_BONUS_PLAN_3 = 0;
        uint256 public PERCENTAGE_BONUS_PLAN_4 = 0;

        /* project statistics **/
	uint256 public totalInvested;
	uint256 public totalReInvested;
	uint256 public totalRefBonus;
	uint256 public totalInvestorCount;

    struct Plan {
        uint256 time;
        uint256 percent;
        uint256 mininvest;
        uint256 maxinvest;

        /** plan statistics **/
        uint256 planTotalInvestorCount;
        uint256 planTotalInvestments;
        uint256 planTotalReInvestorCount;
        uint256 planTotalReInvestments;
        
        bool planActivated;
    }
    
	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
		bool reinvested;
	}
    
    Plan[] internal plans;

	struct User {
		Deposit[] deposits;
		mapping (uint8 => uint256) checkpoints; /** a checkpoint for each plan **/
		uint256 cutoff;
		uint256 totalInvested;
		address referrer;
		uint256 referralsCount;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
		uint256 reinvested;
		uint256 totalDepositAmount;
	}

	mapping (address => User) internal users;

    address payable public dev1 = payable(0xCCa04B7AcDdf2c1Cb9d24374406739718730F494);
    address payable public mktAndBuyBack = payable(0xCCa04B7AcDdf2c1Cb9d24374406739718730F494);
    address payable public ProjectOwner1 = payable(0xCCa04B7AcDdf2c1Cb9d24374406739718730F494);
    address payable public ProjectOwner2 = payable(0xCCa04B7AcDdf2c1Cb9d24374406739718730F494);
    //address payable public ProjectOwner3 = payable(0xCCa04B7AcDdf2c1Cb9d24374406739718730F494);
    address payable public leadersPool = payable(0xCCa04B7AcDdf2c1Cb9d24374406739718730F494);
	address payable public owner;
    uint public startTime = 1679153400; // Saturday, 18 March 2023 15:30:00 UTC https://www.unixtimestamp.com/
	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event ReinvestedDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

    event IndirectRefBonus(address indexed referrer, address indexed referral, uint8 level, uint256 amount);
    // new added line
    event PlanUpdated(uint256 indexed planIndex, uint256 oldDuration, uint256 oldInterestRate, uint256 newInterestRate);

    modifier onlyOwner {
        require(msg.sender == owner , "not the owner");
     _;
    }

    constructor() {
        owner = payable(msg.sender);
        dev1 = payable(msg.sender);

        plans.push(Plan(10, 130,  0.05 ether, 0.2 ether, 0, 0, 0, 0, true)); // 13% daily for 10 days
        plans.push(Plan(10, 150,  0.25 ether, 0.5 ether, 0, 0, 0, 0, true)); // 15% daily for 10 days
        plans.push(Plan( 10, 180,  0.6 ether, 1 ether, 0, 0, 0, 0, true)); // 18% daily for 10 days
	}


    //function setDailyInterestRate(uint256 planIndex, uint256 newInterestRate) public {
        //require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        //require(planIndex < plans.length, "Invalid plan index");
        //plans[planIndex].percent = newInterestRate;
    //}

    //function setPlanDuration(uint256 planIndex, uint256 newDuration) public {
        //require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        //require(planIndex < plans.length, "Invalid plan index");
        //plans[planIndex].time = newDuration;
    //}

    function setDailyInterestRate(uint256 planIndex, uint256 newInterestRate) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(planIndex < plans.length, "Invalid plan index");
        uint256 oldInterestRate = plans[planIndex].percent;
        plans[planIndex].percent = newInterestRate;
        emit PlanUpdated(planIndex, plans[planIndex].time, oldInterestRate, newInterestRate);
    }

    function setPlanDuration(uint256 planIndex, uint256 newDuration) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(planIndex < plans.length, "Invalid plan index");
        uint256 oldDuration = plans[planIndex].time;
        plans[planIndex].time = newDuration;
        emit PlanUpdated(planIndex, oldDuration, plans[planIndex].percent, plans[planIndex].percent);
    }


    function setDev1(address payable _newAddress) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(_newAddress != address(0), "Invalid address");
        dev1 = _newAddress;
    }

    function setmktAndBuyBack(address payable _newAddress) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(_newAddress != address(0), "Invalid address");
        mktAndBuyBack = _newAddress;
    }

    function setProjectOwner1(address payable _newAddress) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(_newAddress != address(0), "Invalid address");
        ProjectOwner1 = _newAddress;
    }

    function setProjectOwner2(address payable _newAddress) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(_newAddress != address(0), "Invalid address");
        ProjectOwner2 = _newAddress;
    }

    //function setProjectOwner3(address payable _newAddress) public {
        //require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        //require(_newAddress != address(0), "Invalid address");
        //ProjectOwner3 = _newAddress;
    //}

    function setleadersPool(address payable _newAddress) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(_newAddress != address(0), "Invalid address");
        leadersPool = _newAddress;
    }

    function setProjectFee(uint256 newFee) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(newFee <= 1000, "Project fee percent must be less than or equal to 100%");
        PROJECT_FEE = newFee;
    }

    function setMktgBuyBackFee(uint256 newFee) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(newFee <= 1000, "Project fee percent must be less than or equal to 100%");
        MKT_BUYBACK_FEE = newFee;
    }

    function setSustainabilityTax(uint256 newFee) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(newFee <= 1000, "Project fee percent must be less than or equal to 100%");
        SUSTAINABILITY_TAX = newFee;
    }

    //function setLeadersPoolFee(uint256 newFee) public {
        //require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        //require(newFee <= 1000, "Project fee percent must be less than or equal to 100%");
        //LEADERS_POOL = newFee;
    //}

    function setOwnersFee(uint256 newFee) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(newFee <= 1000, "Project fee percent must be less than or equal to 100%");
        OWNER_FEE = newFee;
    }


    function Clear() public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        uint256 assetBalance;
        address self = address(this);
        assetBalance = self.balance;
        payable(msg.sender).transfer(assetBalance);
    }

    function withdraw(uint256 amount) public {
        require(msg.sender == owner || msg.sender == dev1, "Only owner and dev can call this function");
        require(amount <= address(this).balance, "Insufficient funds");
        payable(msg.sender).transfer(amount);
    }


    function invest(address referrer, uint8 plan) public payable {
        require(block.timestamp > startTime, "Investment not allowed at this time");
        require(plan < plans.length, "Invalid Plan.");
        require(msg.value >= plans[plan].mininvest, "Less than minimum amount required for the selected Plan.");
        require(msg.value <= plans[plan].maxinvest, "More than maximum amount required for the selected Plan.");
        require(plans[plan].planActivated, "Plan selected is disabled");
        require(getUserActiveProjectInvestments(msg.sender).add(msg.value) <= WALLET_LIMIT, "Max wallet deposit limit reached.");

        /** fees **/
        emit FeePayed(msg.sender, payFees(msg.value));

        User storage user = users[msg.sender];
        uint256 bonus = 0;

        // Check for referrer and calculate referral bonus
        if (user.referrer == address(0) && referrer != msg.sender) {
            if (users[referrer].deposits.length > 0) {
                user.referrer = referrer;
            }
        }
        if (user.referrer != address(0)) {
            address upline = user.referrer;

            for (uint8 i = 0; i < REFERRAL_BONUSES.length; i++) {
                if (upline == address(0)) {
                    break;
                }

                uint256 amount = msg.value.mul(REFERRAL_BONUSES[i]).div(100);

                users[upline].bonus = users[upline].bonus.add(amount);
                users[upline].totalBonus = users[upline].totalBonus.add(amount);

                bonus = bonus.add(amount);

                //emit RefBonus(upline, msg.sender, i+1, amount);
                emit RefBonus(upline, msg.sender, amount);


                upline = users[upline].referrer;
            }
        }

        // Update user's deposits and statistics
        user.deposits.push(Deposit(plan, msg.value, block.timestamp, false));
        user.totalInvested = user.totalInvested.add(msg.value);
        totalInvested = totalInvested.add(msg.value);
        totalRefBonus = totalRefBonus.add(bonus);
        totalInvestorCount = totalInvestorCount.add(1);
        plans[plan].planTotalInvestorCount = plans[plan].planTotalInvestorCount.add(1);
        plans[plan].planTotalInvestments = plans[plan].planTotalInvestments.add(msg.value);

        emit NewDeposit(msg.sender, plan, msg.value);
    }


	function withdraw() public {
		require(block.timestamp > startTime);
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;

		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

        for(uint8 i = 0; i < plans.length; i++){

            if(user.checkpoints[i].add(WITHDRAW_COOLDOWN) > block.timestamp){
               revert("Withdrawals can only be made after withdraw cooldown.");
            }

		    user.checkpoints[i] = block.timestamp; /** global withdraw will reset checkpoints on all plans **/
        }

        /** Excess dividends are sent back to the user's account available for the next withdrawal. **/
        if(totalAmount > MAX_WITHDRAW) {
            user.bonus = totalAmount.sub(MAX_WITHDRAW);
            totalAmount = MAX_WITHDRAW;
        }

        totalAmount = totalAmount.sub(totalAmount.mul(SUSTAINABILITY_TAX).div(PERCENTS_DIVIDER)); /* 10% of withdrawable amount goes back to the contract. */
        user.cutoff = block.timestamp.add(CUTOFF_STEP); /** global withdraw will also reset CUTOFF **/
		user.withdrawn = user.withdrawn.add(totalAmount);
        payable(address(msg.sender)).transfer(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}
	
	function payFees(uint256 amounterc) internal returns(uint256) {
		uint256 fee = amounterc.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 marketing = amounterc.mul(MKT_BUYBACK_FEE).div(PERCENTS_DIVIDER);
        //uint256 leaderspool = amounterc.mul(LEADERS_POOL).div(PERCENTS_DIVIDER);
        uint256 ownerfee = amounterc.mul(OWNER_FEE).div(PERCENTS_DIVIDER);
		dev1.transfer(fee);
        mktAndBuyBack.transfer(marketing);
        //leadersPool.transfer(leaderspool);
        ProjectOwner1.transfer(ownerfee);
        ProjectOwner2.transfer(ownerfee);
        //ProjectOwner3.transfer(ownerfee);
        return fee.add(marketing);
    }

	function getUserDividends(address userAddress, int8 plan) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		uint256 endPoint = block.timestamp < user.cutoff ? block.timestamp : user.cutoff;

		for (uint256 i = 0; i < user.deposits.length; i++) {
		    if(plan > -1){
		        if(user.deposits[i].plan != uint8(plan)){
		            continue;
		        }
		    }
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
			/** check if plan is not yet finished. **/
			if (user.checkpoints[user.deposits[i].plan] < finish) {

			    uint256 percent = plans[user.deposits[i].plan].percent;
			    if(user.deposits[i].start >= PERCENTAGE_BONUS_STARTTIME){
                    if(user.deposits[i].plan == 0){
                        percent = percent.add(PERCENTAGE_BONUS_PLAN_1);
                    }else if(user.deposits[i].plan == 1){
                        percent = percent.add(PERCENTAGE_BONUS_PLAN_2);
                    }else if(user.deposits[i].plan == 2){
                        percent = percent.add(PERCENTAGE_BONUS_PLAN_3);
                    }else if(user.deposits[i].plan == 3){
                        percent = percent.add(PERCENTAGE_BONUS_PLAN_4);
                    }
			    }

				uint256 share = user.deposits[i].amount.mul(percent).div(PERCENTS_DIVIDER);

				uint256 from = user.deposits[i].start > user.checkpoints[user.deposits[i].plan] ? user.deposits[i].start : user.checkpoints[user.deposits[i].plan];
				/** uint256 to = finish < block.timestamp ? finish : block.timestamp; **/
				uint256 to = finish < endPoint ? finish : endPoint;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}
    
	function getUserActiveProjectInvestments(address userAddress) public view returns (uint256){
	    uint256 totalAmount;

		/** get total active investments in all plans. **/
        for(uint8 i = 0; i < plans.length; i++){
              totalAmount = totalAmount.add(getUserActiveInvestments(userAddress, i));  
        }
        
	    return totalAmount;
	}

	function getUserActiveInvestments(address userAddress, uint8 plan) public view returns (uint256){
	    User storage user = users[userAddress];
	    uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {

	        if(user.deposits[i].plan != uint8(plan)){
	            continue;
	        }

			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
			if (user.checkpoints[uint8(plan)] < finish) {
			    /** sum of all unfinished deposits from plan **/
				totalAmount = totalAmount.add(user.deposits[i].amount);
			}
		}
	    return totalAmount;
	}


	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent, uint256 minimumInvestment, uint256 maximumInvestment,
	  uint256 planTotalInvestorCount, uint256 planTotalInvestments , uint256 planTotalReInvestorCount, uint256 planTotalReInvestments, bool planActivated) {
		time = plans[plan].time;
		percent = plans[plan].percent;
		minimumInvestment = plans[plan].mininvest;
		maximumInvestment = plans[plan].maxinvest;
		planTotalInvestorCount = plans[plan].planTotalInvestorCount;
		planTotalInvestments = plans[plan].planTotalInvestments;
		planTotalReInvestorCount = plans[plan].planTotalReInvestorCount;
		planTotalReInvestments = plans[plan].planTotalReInvestments;
		planActivated = plans[plan].planActivated;
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
	    return getUserDividends(userAddress, -1);
	}

	function getUserCutoff(address userAddress) public view returns (uint256) {
      return users[userAddress].cutoff;
    }

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress, uint8 plan) public view returns(uint256) {
		return users[userAddress].checkpoints[plan];
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

    function getUserTotalReferrals(address userAddress) public view returns (uint256){
        return users[userAddress].referralsCount;
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

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish, bool reinvested) {
	    User storage user = users[userAddress];
		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
		reinvested = user.deposits[index].reinvested;
	}

    function getSiteInfo() public view returns (uint256 _totalInvested, uint256 _totalBonus) {
        return (totalInvested, totalRefBonus);
    }

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
	}

	/** Get Block Timestamp **/
	function getBlockTimeStamp() public view returns (uint256) {
	    return block.timestamp;
	}

	/** Get Plans Length **/
	function getPlansLength() public view returns (uint256) {
	    return plans.length;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}