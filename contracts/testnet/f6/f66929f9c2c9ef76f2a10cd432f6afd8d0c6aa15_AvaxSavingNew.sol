/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AvaxSavingNew {
    using SafeMath for uint256;

    uint256 public constant INVEST_MIN_AMOUNT = 0.1 ether;
    uint256[] public REFERRAL_PERCENTS = [80, 50, 20];
    uint256[] public STAKE_REWARD_COMMISSION_PERCENTS = [100, 50, 20];
    uint256 public constant PROJECT_DEV = 20;
    uint256 public constant MARKETING_ALLOCATION = 20;
    uint256 public constant RESERVE_ALLOCATION = 60;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public totalStaked;

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
        mapping(uint256 => address[]) downline;
        uint256[3] levels;
        uint256 claimed;
        uint256 bonus;
        uint256 totalBonus;
    }
    mapping(address => User) internal users;

    address payable public _donator;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    event Newbie(address user);
    event NewDeposit(
        address indexed user,
        uint8 plan,
        uint256 percent,
        uint256 amount,
        uint256 profit,
        uint256 start,
        uint256 finish
    );
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event reserveFundsPaid(address indexed user, uint256 totalAmount);

    constructor(address payable wallet) {
        require(!isContract(wallet));
        _donator = wallet;

        plans.push(Plan(10, 20));
        plans.push(Plan(20, 210));
        plans.push(Plan(30, 220));
        plans.push(Plan(60, 230));
        plans.push(Plan(120, 240));
        plans.push(Plan(180, 250));
    }

    function stake(address referrer, uint8 plan) public payable {
        require(msg.value >= INVEST_MIN_AMOUNT, "min amount 0.1 AVAX");
        require(msg.sender != referrer, "cannot reffer to self");
        //Change Plan arary accordingly
        require(plan < 6, "Incorrect plan");

        uint256 fee = msg.value.mul(PROJECT_DEV + RESERVE_ALLOCATION).div(
            PERCENTS_DIVIDER
        );

        _donator.transfer(fee);
        emit reserveFundsPaid(msg.sender, fee);

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }
            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    users[upline].downline[i].push(msg.sender);
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(
                        amount
                    );
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        (uint256 percent, uint256 profit, uint256 finish) = getResult(
            plan,
            msg.value
        );
        user.deposits.push(
            Deposit(plan, percent, msg.value, profit, block.timestamp, finish)
        );

        totalStaked = totalStaked.add(msg.value);
        emit NewDeposit(
            msg.sender,
            plan,
            percent,
            msg.value,
            profit,
            block.timestamp,
            finish
        );
    }

    //Claimable Total reward
    function claimReward() public {
        User storage user = users[msg.sender];
        uint256 totalAmount = getUserStakeReward(msg.sender);
        uint256 stakeCommision = getUserStakeCommision(msg.sender);
        //new
        uint256 stakeRewardCommision = getUserStakeRewardCommision(msg.sender);

        if (stakeCommision > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(stakeCommision);
        }
        if (stakeRewardCommision > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(stakeRewardCommision);
        }

        require(totalAmount > 0, "User has no claimable rewards");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;
        user.claimed = user.claimed.add(totalAmount);

        payable(msg.sender).transfer(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function getUserStakeRewardCommision(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        uint256 totalAmount;
        for (uint256 i = 0; i < 3; i++) {
            if (users[userAddress].downline[i].length > 0) {
                for (
                    uint256 k = 0;
                    k < users[userAddress].downline[i].length;
                    k++
                ) {
                    totalAmount = totalAmount.add(
                        getUserStakeRewardCommissionFactory(
                            users[userAddress].downline[i][k]
                        ).mul(STAKE_REWARD_COMMISSION_PERCENTS[i]).div(
                                PERCENTS_DIVIDER
                            )
                    );
                }
            }
        }
        return totalAmount;
    }

    function getResult(uint8 plan, uint256 deposit)
        public
        view
        returns (
            uint256 percent,
            uint256 profit,
            uint256 finish
        )
    {
        percent = plans[plan].percent;

        profit = deposit.mul(plans[plan].percent).div(PERCENTS_DIVIDER).mul(
            plans[plan].time
        );

        finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getUserStakeReward(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                uint256 share = user
                    .deposits[i]
                    .amount
                    .mul(user.deposits[i].percent)
                    .div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint
                    ? user.deposits[i].start
                    : user.checkpoint;
                uint256 to = user.deposits[i].finish < block.timestamp
                    ? user.deposits[i].finish
                    : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount.add(
                        share.mul(to.sub(from)).div(TIME_STEP)
                    );
                }
            }
        }

        return totalAmount;
    }

    //Get Stake Reward Commission
    function getUserStakeRewardCommissionFactory(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        uint256 totalAmount;

        for (uint256 i = 0; i < 3; i++) {
            for (uint256 k = 0; k < user.downline[i].length; k++) {
                totalAmount = totalAmount.add(
                    getUserStakeReward(user.downline[i][k])
                );
            }
        }

        return totalAmount;
    }

    function getUserDownline(address userAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[userAddress].levels[0],
            users[userAddress].levels[1],
            users[userAddress].levels[2]
        );
    }

    function getUserDownlineAddress(address userAddress)
        public
        view
        returns (
            address[] memory,
            address[] memory,
            address[] memory
        )
    {
        return (
            users[userAddress].downline[0],
            users[userAddress].downline[1],
            users[userAddress].downline[2]
        );
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserStakeCommision(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserClaimable(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            getUserStakeCommision(userAddress).add(
                getUserStakeReward(userAddress)
            );
    }

    function getUserCurrentDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            if (users[userAddress].deposits[i].finish > block.timestamp) {
                amount = amount.add(users[userAddress].deposits[i].amount);
            }
        }
    }

    function getUserDepositsCount(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserClaimed(address userAddress) public view returns (uint256) {
        return users[userAddress].claimed;
    }

    function getUserBalance(address userAddress)
        public
        view
        returns (
            uint256 currentDeposits,
            uint256 claimed,
            uint256 claimable
        )
    {
        currentDeposits = getUserCurrentDeposits(userAddress);
        claimed = getUserClaimed(userAddress);
        claimable = getUserClaimable(userAddress);
    }

    function getUserAllDepositsInfo(address userAddress)
        public
        view
        returns (Deposit[] memory)
    {
        return users[userAddress].deposits;
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint8 plan,
            uint256 percent,
            uint256 amount,
            uint256 profit,
            uint256 start,
            uint256 finish
        )
    {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
    }

    function claimPromotionalReward(address payable userAddress, uint256 amount)
        external
        onlyPromotion
    {
        require(address(this).balance > 0, "Balance is Zero");
        require(amount > 0, "should be NON ZERO");
        payable(userAddress).transfer(amount);
    }

    modifier onlyPromotion() {
        require(_donator == msg.sender, "onlyPromotion");
        _;
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