//@dev SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IERC20.sol";
import "./Ownable.sol";

contract Nine2Five is Context, Ownable {
    uint256 public constant min = 1 ether;
    uint256 public constant max = 1000000000 ether;

    uint256 public tot_taken = 0;
    uint256 revenue = 0;
    uint256 divisor = 2;

    //@devroi is 2% each 8 hours but only from Mon to Fri 9am-5pm
    uint256 roi = 10;
    uint256 public n_users = 0;
    uint256 public ref_fee = 4;

    address public teamwallet;
    address public multisig;
    address public mkt;

    IERC20 private BusdInterface;
    address public tokenAdress;
    bool private firstwithdraw;

    uint256 public lastwithdraw;

    uint256 MONDAY_START = 1683504000;  //@devthis is used to calculate each day of the week, always change this value to any Monday 0.00
    uint256 PLATFORM_START = 1683536400; //@devdate of launch Mon May 8 9 am UTC
    uint256 private constant SECONDS_IN_DAY = 86400;
    uint256 private constant SECONDS_IN_HOUR = 3600;
    uint256 private constant ELIGIBLE_MINUTES_PER_DAY = 480;

    //bonuses
    uint256 WORK_PERC = 3;
    uint256 COMP_PERC = 3;


    //@devteam fees
    struct WalletInfo {
        address wallet;
        uint256 percentage;
    }

    struct refferal_system {
        address ref_address;
        uint256 reward;
    }

    struct user_investment_details {
        address user_address;
        uint256 invested;
        uint256 ROI;
        bool hasinvested;
    }

    struct claimDaily {
        address user_address;
        uint256 startTime;
        uint256 deadline;
    }

    struct userTotalWithdraw {
        address user_address;
        uint256 amount;
    }

    mapping(address => refferal_system) public refferal;
    mapping(address => user_investment_details) public investments;
    mapping(address => claimDaily) public claimTime;
    mapping(address => userTotalWithdraw) public totalWithdraw;

    WalletInfo[] public wallets;

    event Deposit(address indexed user, address indexed ref, uint256 amount);
    event Compound(address indexed user, uint256 amount);
    event Workhard(address indexed user, uint256 amount);
    event Ownerwithdraw(address indexed user, uint256 amount);

    constructor(address _teamwallet, address _mkt, address _dev) {
        teamwallet = _teamwallet;
        multisig = teamwallet;
        wallets.push(WalletInfo({wallet: _teamwallet, percentage: 400}));
        wallets.push(WalletInfo({wallet: _mkt, percentage:50}));
        wallets.push(WalletInfo({wallet: _mkt, percentage: 60}));
        wallets.push(WalletInfo({wallet: _mkt, percentage: 100}));
        wallets.push(WalletInfo({wallet: _mkt, percentage: 125}));
        wallets.push(WalletInfo({wallet: _mkt, percentage: 50}));
        wallets.push(WalletInfo({wallet: _mkt, percentage:65}));
        wallets.push(WalletInfo({wallet: _dev, percentage: 150}));

        //tokenAdress = 0x25C7c87B42ec086b01528eE72465F1e3c49B7B9D; //@devtestnet
        tokenAdress = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7; //@devmainnet using testnet for testing
        BusdInterface = IERC20(tokenAdress);
    }

    //@dev invest function
    function deposit(address _ref, uint256 _amount) public {
        require(PLATFORM_START <= block.timestamp && !isContract(msg.sender));
        require(_amount >= min && _amount <= max, "Cannot Deposit");
        uint256 userLastInvestment = investments[msg.sender].invested;

        //@dev claim before reinvesting
        if (userLastInvestment != 0) {
            Claim(msg.sender);
        } else {
            n_users++;
        }

        //@dev setup new claiming time
        UpdateTime(msg.sender);
        uint256 total_contract = _amount;
        BusdInterface.transferFrom(msg.sender, address(this), total_contract);
        uint256 total_fee = distributeFees(_amount);

        //@dev Adjust the contract's balance after fee distribution
        total_contract -= total_fee;

        uint256 ref_fee_add = refFee(_amount);
        if (_ref != address(0) && _ref != msg.sender) {
            uint256 ref_last_balance = refferal[_ref].reward;
            uint256 totalRefFee = ref_fee_add + ref_last_balance;
            refferal[_ref] = refferal_system(_ref, totalRefFee);
        }

        uint256 userCurrentInvestment = _amount - total_fee;
        uint256 totalInvestment = userLastInvestment + userCurrentInvestment;
        investments[msg.sender] = user_investment_details(
            msg.sender,
            totalInvestment,
            roi,
            true
        );

        emit Deposit(msg.sender, _ref, _amount);
    }

    function UpdateTime(address _user) internal {
        uint256 claimTimeStart = block.timestamp;
        uint256 claimTimeEnd = block.timestamp + 7 days;
        claimTime[_user] = claimDaily(_user, claimTimeStart, claimTimeEnd);
    }

    function compound() public {
        require(PLATFORM_START <= block.timestamp);
        require(investments[msg.sender].hasinvested == true);
        require(
            claimTime[msg.sender].deadline - 5 days <= block.timestamp,
            "You cant compound before 48 hours"
        );

        uint256 aval_withdraw = userReward(msg.sender);
        UpdateTime(msg.sender);

        //@dev investment details
        uint256 userLastInvestment = investments[msg.sender].invested;
        uint256 userCurrentInvestment = aval_withdraw;
        uint256 totalInvestment = userLastInvestment + userCurrentInvestment;
        investments[msg.sender] = user_investment_details(
            msg.sender,
            totalInvestment,
            roi + COMP_PERC,
            true
        );

        emit Compound(msg.sender, aval_withdraw);
    }

    function workharder() public {
        require(PLATFORM_START <= block.timestamp);
        require(investments[msg.sender].hasinvested == true);
        require(
            claimTime[msg.sender].deadline - 3 days <= block.timestamp,
            "You cant compound before 24 hours"
        );

        uint256 half_amount = userReward(msg.sender) / 2;
        UpdateTime(msg.sender);

        //@dev investment details
        uint256 userLastInvestment = investments[msg.sender].invested;
        uint256 userCurrentInvestment = half_amount;
        uint256 totalInvestment = userLastInvestment + userCurrentInvestment;

        //@dev roi is set to roi + .3%
        investments[msg.sender] = user_investment_details(
            msg.sender,
            totalInvestment,
            roi + WORK_PERC,
            true
        );

        BusdInterface.transfer(msg.sender, half_amount);
        emit Workhard(msg.sender, half_amount);
    }

    function claimDailyRewards() public {
        require(PLATFORM_START <= block.timestamp);
        require(
            investments[msg.sender].hasinvested == true &&
                totalWithdraw[msg.sender].amount <=
                investments[msg.sender].invested * 3
        );
        //@dev Users can claim only after 1 day
        require(
            claimTime[msg.sender].deadline - 6 days <= block.timestamp,
            "You cant claim before 24 hours"
        );
        Claim(msg.sender);
    }

    //@dev claim internal so Deposit can claim before redepositing
    function Claim(address _user) internal {
        uint256 rewards = userReward(_user);
        uint256 untilnow = totalWithdraw[_user].amount + rewards;
        totalWithdraw[_user] = userTotalWithdraw(_user, untilnow);
        uint256 claimTimeStart = block.timestamp;
        uint256 claimTimeEnd = claimTimeStart + 7 days;
        claimTime[_user] = claimDaily(_user, claimTimeStart, claimTimeEnd);
        investments[_user].ROI = 20;
        BusdInterface.transfer(_user, rewards);
    }

    function Ref_Withdraw() external {
        require(PLATFORM_START <= block.timestamp);
        require(
            investments[msg.sender].hasinvested == true &&
                totalWithdraw[msg.sender].amount <=
                investments[msg.sender].invested * 3
        );

        uint256 value = refferal[msg.sender].reward;
        uint256 untilnow = totalWithdraw[msg.sender].amount + value;
        //@devref count in the x3 invest limit
        totalWithdraw[msg.sender] = userTotalWithdraw(msg.sender, untilnow);
        //@devtax 30% for withdrawals from refs
        BusdInterface.transfer(msg.sender, (value / 100) * 70);
        refferal[msg.sender] = refferal_system(msg.sender, 0);
    }

    function Ref_Compound() external {
        require(PLATFORM_START <= block.timestamp);
        require(investments[msg.sender].hasinvested == true);
        uint256 value = refferal[msg.sender].reward;
        refferal[msg.sender] = refferal_system(msg.sender, 0);

        uint256 userLastInvestment = investments[msg.sender].invested;
        uint256 totalInvestment = userLastInvestment + value;
        investments[msg.sender] = user_investment_details(
            msg.sender,
            totalInvestment,
            roi,
            true
        );
    }

    //@devRewards functions to accumulate only during specific hours
    function userReward(address _userAddress) public view returns (uint256) {
        uint256 userInvestment = investments[_userAddress].invested;
        //@devuser roi is mul by 5 working days
        uint256 userweeklyroi = investments[_userAddress].ROI * 5;
        //@dev 2% of the user's investment during eligible hours and days, 2% daily ROI is 10% from Monday to friday
        // div100 is used to get the %, div10 accounts for the extra digit in ROI == /1000
        uint256 userWeeklyReturn = ((userInvestment * userweeklyroi) / 1000);

        uint256 claimStartTime = claimTime[_userAddress].startTime;
        uint256 claimDeadline = claimTime[_userAddress].deadline;

        uint256 currentTime = block.timestamp;
        uint256 totalEligibleMinutesInWeek = 5 * (17 - 9) * 60; //@dev 5 days * 8 hours * 60 minutes

        //@dev If the current time is before the claim start time, the user has no rewards yet
        if (currentTime < claimStartTime) {
            return 0;
        } else if (currentTime > claimDeadline) {
            return userWeeklyReturn; //@dev this excludes non working day which is why weekly roi is mul by 5 and not 7
        } else {
            uint256 effectiveClaimEndTime = currentTime < claimDeadline
                ? currentTime
                : claimDeadline;
            uint256 userEligibleMinutes = countEligibleMinutes(
                claimStartTime,
                effectiveClaimEndTime
            );
            uint256 userRewards = (userWeeklyReturn * userEligibleMinutes) /
                totalEligibleMinutesInWeek;
            return userRewards;
        }
    }

    function countEligibleMinutes(
        uint256 startTimestamp,
        uint256 endTimestamp
    ) public view returns (uint256) {
        uint256 eligibleMinutes = 0;

        uint256 startDay = (startTimestamp - MONDAY_START) / SECONDS_IN_DAY;
        uint256 endDay = (endTimestamp - MONDAY_START) / SECONDS_IN_DAY;

        for (uint256 day = startDay; day <= endDay; day++) {
            uint256 dayStartTimestamp = MONDAY_START + day * SECONDS_IN_DAY;

            uint256 dayEligibleStart = dayStartTimestamp + 9 * 3600; //@dev 9 AM
            uint256 dayEligibleEnd = dayStartTimestamp + 17 * 3600; //@dev 5 PM

            if (startTimestamp > dayEligibleStart) {
                dayEligibleStart = startTimestamp;
            }

            if (endTimestamp < dayEligibleEnd) {
                dayEligibleEnd = endTimestamp;
            }

            if (
                isEligibleTime(dayEligibleStart) &&
                dayEligibleEnd > dayEligibleStart
            ) {
                eligibleMinutes += (dayEligibleEnd - dayEligibleStart) / 60;
            }
        }

        return eligibleMinutes;
    }

    function isEligibleTime(uint256 timestamp) public view returns (bool) {
        uint256 daysSinceFirstMonday = (timestamp - MONDAY_START) /
            SECONDS_IN_DAY;
        uint256 dayOfWeek = (daysSinceFirstMonday % 7) + 1;

        //@dev Check if the current day is between Monday (1) and Friday (5)
        if (dayOfWeek >= 1 && dayOfWeek <= 5) {
            uint256 secondsIntoDay = timestamp % SECONDS_IN_DAY;
            uint256 minutesIntoDay = secondsIntoDay / 60;
            uint256 hourOfDay = minutesIntoDay / 60;

            //@dev Check if the current hour is between 9 and 17 (5 PM)
            return hourOfDay >= 9 && hourOfDay < 17;
        } else {
            return false;
        }
    }

    function Teamwithdraw(address _tosend) external {
        require(msg.sender == multisig, "sender must be multisig");
        uint256 _current = BusdInterface.balanceOf(address(this));
        uint256 _towithdraw;
        if (firstwithdraw == false) {
            _towithdraw = (_current * 70) / 100;
            firstwithdraw = true;
            lastwithdraw = block.timestamp;
        } else {
            require(block.timestamp >= lastwithdraw + 7 days);
            _towithdraw = _current / divisor;
        }
        BusdInterface.transfer(_tosend, _towithdraw);
        tot_taken += _towithdraw;
        emit Ownerwithdraw(multisig, _towithdraw);
    }

    //@devuseful to dispaly balance without accounting for withdrawals and revenues
    function depositrevenue(uint256 amount) external {
        require(msg.sender == wallets[0].wallet, "sender must be team");
        BusdInterface.transferFrom(msg.sender, address(this), amount);
        revenue += amount;
        //@devtot taken cannot be negative
        if (amount < tot_taken) {
            tot_taken -= amount;
        } else {
            tot_taken = 0;
        }
    }

    function changeComp_Work(uint256 _comp , uint256 _work) external {
        require(msg.sender == wallets[0].wallet, "sender must be team");
        require(_comp <= 10 && _work <= 10, "max is 1%");
        WORK_PERC = _work;
        COMP_PERC = _comp;
    }

    function change_reffees(uint256 _fee) external {
        require(msg.sender == wallets[0].wallet, "sender must be team");
        require(_fee <= 5, "max is 5%");
        ref_fee = _fee;
    }

    function changeMulti(address _multisig) external {
        require(msg.sender == multisig, "sender must be multisig");
        multisig = _multisig;
    }

    

    //@dev Update wallet addresses
    function updateWalletAddresses(
        address newTeamWallet,
        address newMkt,
        address newMkt2,
        address newMkt3,
        address newMkt4,
        address newMkt5,
        address newMkt6
    ) external {
        require(
            msg.sender == wallets[0].wallet,
            "Caller needs to be teamwallet"
        );

        wallets[0].wallet = newTeamWallet;
        wallets[1].wallet = newMkt;
        wallets[2].wallet = newMkt2;
        wallets[3].wallet = newMkt3;
        wallets[4].wallet = newMkt4;
        wallets[5].wallet = newMkt5;
        wallets[6].wallet = newMkt6;
    }

    //@dev Update wallet addresses
    function updateWDev(
        address newDev
    ) external {
        require(
            msg.sender == wallets[7].wallet,
            "Caller needs to be teamwallet"
        );

        wallets[7].wallet = newDev;
    }

    //@dev Update wallet percentages
    function updateWalletPercentages(
        uint256 newTeamWalletPercentage,
        uint256 newMktPercentage,
        uint256 newMkt2Percentage,
        uint256 newMkt3Percentage,
        uint256 newMkt4Percentage,
        uint256 newMkt5Percentage,
        uint256 newMkt6Percentage
    ) external {
        require(
            msg.sender == wallets[0].wallet,
            "Caller needs to be teamwallet"
        );

        uint256 currentTotalPercentage = getCurrentTotalPercentage();
        uint256 newTotalPercentage = newTeamWalletPercentage +
            newMktPercentage +
            newMkt2Percentage +
            newMkt3Percentage +
            newMkt4Percentage +
            newMkt5Percentage +
            newMkt6Percentage;

        require(
            newTotalPercentage == currentTotalPercentage,
            "Total percentage cannot exceed the current total percentage"
        );

        wallets[0].percentage = newTeamWalletPercentage;
        wallets[1].percentage = newMktPercentage;
        wallets[2].percentage = newMkt2Percentage;
        wallets[3].percentage = newMkt3Percentage;
        wallets[4].percentage = newMkt4Percentage;
        wallets[5].percentage = newMkt5Percentage;
        wallets[6].percentage = newMkt6Percentage;
    }

    //@dev Function to get the current total percentage
    function getCurrentTotalPercentage() public view returns (uint256) {
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            totalPercentage += wallets[i].percentage;
        }
        return totalPercentage;
    }

    //@dev Function to handle fee distribution
    function distributeFees(uint256 _amount) internal returns (uint256) {
        uint256 total_fee = 0;

        for (uint256 i = 0; i < wallets.length; i++) {
            uint256 wallet_fee = (_amount * wallets[i].percentage) / 10000;
            total_fee += wallet_fee;
            BusdInterface.transfer(wallets[i].wallet, wallet_fee);
        }

        return total_fee;
    }

    function changeRoi(uint256 _roi) external {
        require(msg.sender == wallets[0].wallet, "sender must be teamwallet");
        require(_roi >= 5 && _roi <= 30, "only 0.5 to 3% daily");
        roi = _roi;
    }

    function incrementWeektoCalc(uint256 _weeks) external {
        require(msg.sender == wallets[0].wallet, "sender must be teamwallet");
        require(_weeks > 0 && _weeks <= 10, "max 10 weeks allowed");
        require(MONDAY_START + (7 days * _weeks) < block.timestamp, "cannot be in the future");
        MONDAY_START += 7 days * _weeks;
    }

    function changeDivisor(uint256 _divisor) external {
        require(
            msg.sender == multisig && _divisor >= 2,
            "sender must be multisig"
        );
        divisor = _divisor;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function Users() public view returns (uint256) {
        return n_users;
    }

    function checkAlready() public view returns (bool) {
        address _address = msg.sender;
        if (investments[_address].user_address == _address) {
            return true;
        } else {
            return false;
        }
    }

    function theoffice() public view returns (uint256 _timenow, bool _isopen) {
        uint256 timenow = block.timestamp;
        bool isopen = isEligibleTime(timenow);
        return (timenow, isopen);
    }

    function refFee(uint256 _amount) public view returns (uint256) {
        return (_amount * ref_fee) / 100;
    }

    function getBalance() public view returns (uint256) {
        uint256 totbalance = BusdInterface.balanceOf(address(this)) + tot_taken;
        return totbalance;
    }


    function getRevenue() public view returns (uint256) {
        return revenue;
    }

}