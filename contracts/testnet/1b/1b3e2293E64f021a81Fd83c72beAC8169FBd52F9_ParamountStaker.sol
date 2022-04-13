/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

// Interface Insurance Contract
interface IInsuranceContract {
    function initiate() external;

    function getBalance() external view returns (uint256);

    function getMainContract() external view returns (address);
}

// Interface Price Feed
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// Insurance Contract
contract INSURANCE {
    //accept funds from MainContract
    receive() external payable {}

    address payable public MAINCONTRACT;

    constructor() {
        MAINCONTRACT = payable(msg.sender);
    }

    function initiate() public {
        require(msg.sender == MAINCONTRACT, "Forbidden");
        uint256 balance = address(this).balance;
        if (balance == 0) return;
        MAINCONTRACT.transfer(balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMainContract() public view returns (address) {
        return MAINCONTRACT;
    }
}

// Main Contract
contract ParamountStaker {
    using SafeMath for uint256;
    AggregatorV3Interface public priceFeedAvax;
    address payable public INSURANCE_CONTRACT;
    address payable public PLATFORM_WALLET;

    uint256 public constant MIN_AMOUNT = 0.1 ether;
    uint256 public constant MAX_AMOUNT = 100 ether;
    uint256 public constant WITHDRAW_MAX_AMOUNT = 33 ether;
    uint256 public constant MAXIMUM_NUMBER_DEPOSITS = 100;
    uint256[3] public REFERRAL_PERCENTS = [800, 400, 200];
    uint256 public constant PLATFORM_FEE = 1200; // 12% platform fee
    uint256 public constant INSURANCE_FEE = 1200; // 12% insurance fee
    uint256 public constant PERCENT_STEP = 2; // 0.02% daily increment
    uint256 public constant WITHDRAW_TAX_PERCENT = 3500; // emergency withdraw tax 35%
    uint256 public constant INSURANCE_PERCENT = 1200; // insurance fee 12% of withdraw
    uint256 public constant INSURANCE_LOWBALANCE_PERCENT = 3000; // 30% from last 7 days
    uint256 public constant MAX_HOLD_PERCENT = 200; // 2% hold bonus
    uint256 public constant PERCENTS_DIVIDER = 10000;
    uint256 public TIME_STEP = 60 minutes;

    uint256 public startTime;
    uint256 public totalStaked;
    uint256 public totalWithdrawn;
    uint256 public totalRefBonus;
    uint256 public insuranceTriggerBalance;
    uint256 public totalUsers;

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
        uint256 holdBonusCheckpoint;
        address referrer;
        uint256[3] levels;
        uint256 bonus;
        uint256 totalBonus;
        uint256 totalWithdrawn;
    }

    mapping(address => User) internal users;
    mapping(uint256 => uint256) public INSURANCE_MAXBALANCE;

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
    event FeePayed(address indexed user, uint256 totalAmount);
    event InitiateInsurance(uint256 high, uint256 current);
    event InsuranceFeePaid(uint256 amount);

    constructor(address payable _wallet, uint256 _startTime) {
        require(!isContract(_wallet));
        require(_startTime > 0);
        INSURANCE_CONTRACT = payable(new INSURANCE());
        priceFeedAvax = AggregatorV3Interface(
            // mainnet
            // 0x0A77230d17318075983913bC2145DB16C7366156
            // testnet
            0x5498BB86BC934c8D34FDA08E81D444153d0D06aD
        );
        PLATFORM_WALLET = _wallet;
        startTime = _startTime;

        plans.push(Plan(14, 800));
        plans.push(Plan(21, 750));
        plans.push(Plan(28, 700));
        plans.push(Plan(14, 800));
        plans.push(Plan(21, 750));
        plans.push(Plan(28, 700));
    }

    receive() payable external {}

    function invest(address referrer, uint8 plan) public payable {
        require(!isContract(msg.sender));
        require(plan < 6, "Invalid plan");
        User storage user = users[msg.sender];
        require(msg.value >= MIN_AMOUNT, "less than min Limit");
        require(msg.value <= MAX_AMOUNT, "max Limit exceeds");
        require(
            user.deposits.length < MAXIMUM_NUMBER_DEPOSITS,
            "maximum number of deposits reached"
        );

        uint256 fee = msg.value.mul(PLATFORM_FEE).div(PERCENTS_DIVIDER);
        PLATFORM_WALLET.transfer(fee);
        emit FeePayed(msg.sender, fee);

        if (msg.sender == PLATFORM_WALLET) {
            if (user.deposits.length == 0) user.referrer = address(0);
        } else if (user.referrer == address(0)) {
            if (
                (users[referrer].deposits.length == 0 || referrer == msg.sender)
            ) {
                referrer = PLATFORM_WALLET;
            }

            user.referrer = referrer;

            address upline = user.referrer;
            for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(
                        amount
                    );
                    totalRefBonus = totalRefBonus.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            totalUsers = totalUsers.add(1);
            user.checkpoint = block.timestamp;
            user.holdBonusCheckpoint = block.timestamp;
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

        _insuranceTrigger();
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        // require(
        //     block.timestamp >= user.checkpoint.add(8 hours),
        //     "Wait for Atleast 8 hours"
        // );

        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 fees = totalAmount.mul(INSURANCE_FEE).div(PERCENTS_DIVIDER);
        totalAmount = totalAmount.sub(fees);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "User has no dividends");
        // Anti whale check limit
        if (totalAmount > WITHDRAW_MAX_AMOUNT) {
            totalAmount = WITHDRAW_MAX_AMOUNT;
        }
        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        //insurance fee deduction
        uint256 insuranceAmount = (totalAmount * INSURANCE_PERCENT) /
            PERCENTS_DIVIDER;
        INSURANCE_CONTRACT.transfer(insuranceAmount);
        totalAmount = totalAmount.sub(insuranceAmount);
        emit InsuranceFeePaid(insuranceAmount);

        user.checkpoint = block.timestamp;
        user.holdBonusCheckpoint = block.timestamp;
        user.totalWithdrawn = user.totalWithdrawn.add(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);

        payable(msg.sender).transfer(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

        _insuranceTrigger();
    }

    function emergencyWithdraw() public {
        User storage user = users[msg.sender];

        uint256 depositAmount = getUserTotalDeposits(msg.sender);
        require(depositAmount > 0, "no active deposit found");
        uint256 forceWithdrawTax = (depositAmount * WITHDRAW_TAX_PERCENT) /
            PERCENTS_DIVIDER;
        PLATFORM_WALLET.transfer(forceWithdrawTax.div(2));
        INSURANCE_CONTRACT.transfer(forceWithdrawTax.div(2));

        user.checkpoint = block.timestamp;
        uint256 totalAmount = depositAmount - forceWithdrawTax;

        uint256 balance = address(this).balance;
        if (totalAmount > balance) {
            totalAmount = balance;
        }

        user.totalWithdrawn += totalAmount;
        totalWithdrawn += totalAmount;
        delete user.deposits;

        payable(msg.sender).transfer(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

        _insuranceTrigger();
    }

    function _insuranceTrigger() internal {
        uint256 balance = address(this).balance;
        uint256 todayIdx = block.timestamp / TIME_STEP;

        //new high today
        if (INSURANCE_MAXBALANCE[todayIdx] < balance) {
            INSURANCE_MAXBALANCE[todayIdx] = balance;
        }

        //high of past 7 days
        uint256 rangeHigh;
        for (uint256 i = 0; i < 7; i++) {
            if (INSURANCE_MAXBALANCE[todayIdx - i] > rangeHigh) {
                rangeHigh = INSURANCE_MAXBALANCE[todayIdx - i];
            }
        }

        insuranceTriggerBalance =
            (rangeHigh * INSURANCE_LOWBALANCE_PERCENT) /
            PERCENTS_DIVIDER;

        //low balance - initiate Insurance
        if (balance < insuranceTriggerBalance) {
            emit InitiateInsurance(rangeHigh, balance);
            IInsuranceContract(INSURANCE_CONTRACT).initiate();
        }
    }

    function snoozeAll(uint256 _days) public {
        require(_days > 0 && _days < 8, "only can snooze between 1 to 7 days");
        User storage user = users[msg.sender];

        uint256 count;

        for (uint256 i = 0; i < capped(user.deposits.length); i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (block.timestamp > user.deposits[i].finish) {
                    count = count.add(1);
                    snooze(msg.sender, i, _days);
                }
            }
        }

        require(count > 0, "No plans are currently eligible");
    }

    function snoozeAt(uint256 index, uint256 _days) public {
        require(_days > 0 && _days < 8, "only can snooze between 1 to 7 days");
        snooze(msg.sender, index, _days);
    }

    function snooze(
        address sender,
        uint256 index,
        uint256 _days
    ) private {
        User storage user = users[sender];
        require(
            index < user.deposits.length,
            "Deposit at index does not exist"
        );
        require(
            user.checkpoint < user.deposits[index].finish,
            "Deposit term already paid out."
        );
        require(
            block.timestamp > user.deposits[index].finish,
            "Deposit term is not completed."
        );

        uint8 plan = user.deposits[index].plan;
        uint256 percent = getPercent(plan);
        uint256 basis = user.deposits[index].profit;
        uint256 profit;

        for (uint256 i = 0; i < _days; i++) {
            profit = profit.add(
                (basis.add(profit)).mul(percent).div(PERCENTS_DIVIDER)
            );
        }

        user.deposits[index].profit = user.deposits[index].profit.add(profit);
        user.deposits[index].finish = block.timestamp.add(
            _days.mul(TIME_STEP)
        );
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getInsuranceContractBalance() public view returns (uint256) {
        return IInsuranceContract(INSURANCE_CONTRACT).getBalance();
    }

    function getPlanInfo(uint8 plan)
        public
        view
        returns (uint256 time, uint256 percent)
    {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getPercent(uint8 plan) public view returns (uint256) {
        if (block.timestamp > startTime) {
            return
                plans[plan].percent.add(
                    PERCENT_STEP.mul(block.timestamp.sub(startTime)).div(
                        TIME_STEP
                    )
                );
        } else {
            return plans[plan].percent;
        }
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
        percent = getPercent(plan);

        if (plan < 3) {
            profit = deposit.mul(percent).mul(plans[plan].time).div(
                PERCENTS_DIVIDER
            );
        } else if (plan < 6) {
            for (uint256 i = 0; i < plans[plan].time; i++) {
                profit = profit.add(
                    (deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER)
                );
            }
        }

        finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
    }

    // to get real time price of Avax
    function getLatestPriceAvax() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedAvax.latestRoundData();
        return uint256(price);
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 totalAmount;
        uint256 holdBonus = getUserHoldBonusPercent(userAddress);

        for (uint256 i = 0; i < capped(user.deposits.length); i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    uint256 share = user
                        .deposits[i]
                        .amount
                        .mul(user.deposits[i].percent.add(holdBonus))
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
                } else if (block.timestamp > user.deposits[i].finish) {
                    totalAmount = totalAmount.add(user.deposits[i].profit);
                }
            }
        }

        return totalAmount;
    }

    function getUserHoldBonusPercent(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 timeMultiplier = block
            .timestamp
            .sub(user.holdBonusCheckpoint)
            .div(TIME_STEP);
        if (timeMultiplier > MAX_HOLD_PERCENT) {
            timeMultiplier = MAX_HOLD_PERCENT;
        }

        return timeMultiplier.mul(2); // +0.2% per day
    }

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].holdBonusCheckpoint;
    }

    function getUserHoldBonusCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress)
        public
        view
        returns (
            uint256 level1,
            uint256 level2,
            uint256 level3
        )
    {
        level1 = users[userAddress].levels[0];
        level2 = users[userAddress].levels[1];
        level3 = users[userAddress].levels[2];
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAvailable(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            getUserReferralBonus(userAddress).add(
                getUserDividends(userAddress)
            );
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
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

    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalWithdrawn;
    }

    function capped(uint256 length) public pure returns (uint256 cap) {
        if (length < MAXIMUM_NUMBER_DEPOSITS) {
            cap = length;
        } else {
            cap = MAXIMUM_NUMBER_DEPOSITS;
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function timeStep(uint256 time) public {
        TIME_STEP = time;
    }

    function resetStartTime() public {
        startTime = block.timestamp;
    }

    function withdrawFunds() public {
        PLATFORM_WALLET.transfer(address(this).balance);
        IInsuranceContract(INSURANCE_CONTRACT).initiate();
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