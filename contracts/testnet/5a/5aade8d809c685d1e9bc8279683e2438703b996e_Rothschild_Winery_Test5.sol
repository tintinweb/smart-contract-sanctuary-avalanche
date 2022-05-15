/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

contract Rothschild_Winery_Test5 {
    using SafeMath for uint256;

    uint256 public WINE_TO_HIRE_1MAKERS = 1080000;
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public REFERRAL = 50;
    uint256 public TAX = 10;
    uint256 public MARKET_WINE_DIVISOR = 2; // 50%
    uint256 public MARKET_WINE_DIVISOR_SELL = 1; // 100%

    uint256 public MIN_INVEST_LIMIT = 1 * 1e17; /** 0.1 AVAX  **/
    uint256 public WALLET_DEPOSIT_LIMIT = 500 * 1e18; /** 500 AVAX  **/

	uint256 public COMPOUND_BONUS = 10; /** 1% **/
	uint256 public COMPOUND_BONUS_MAX_TIMES = 7; /** 7 times **/
    uint256 public COMPOUND_STEP = 48 * 60 * 60; /** every 48 hours. **/

    uint256 public WITHDRAWAL_TAX = 990;
    uint256 public COMPOUND_FOR_NO_TAX_WITHDRAWAL = 14; // compound days, for no tax withdrawal.

    uint256 public totalStaked;
    uint256 public totalDeposits;
    uint256 public totalCompound;
    uint256 public totalRefBonus;
    uint256 public totalWithdrawn;

    uint256 public marketWine;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public contractStarted;

	uint256 public CUTOFF_STEP = 72 * 60 * 60; /** 72 hours  **/

    address public owner;
    address payable public dev1;
    address payable public dev2;
    address payable public ruby1;
    address payable public ruby2;
    address payable public mkt;

    struct User {
        uint256 initialDeposit;
        uint256 userDeposit;
        uint256 makers;
        uint256 claimedWine;
        uint256 lastCompound;
        address referrer;
        uint256 referralsCount;
        uint256 referralWineRewards;
        uint256 totalWithdrawn;
        uint256 dailyCompoundBonus;
        uint256 lastWithdrawTime;
    }

    mapping(address => User) public users;

    constructor(address payable _dev1, address payable _dev2, address payable _ruby1, address payable _ruby2, address payable _mkt) {
		require(!isContract(_dev1) && !isContract(_dev2) && !isContract(_ruby1) && !isContract(_ruby2) && !isContract(_mkt));
        owner = msg.sender;
        dev1 = _dev1;
        dev2 = _dev2;
        ruby1 = _ruby1;
        ruby2 = _ruby2;
        mkt = _mkt;
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function hatchWine(bool isCompound) public {
        User storage user = users[msg.sender];
        require(contractStarted, "Contract not started yet.");

        uint256 wineUsed = getMyWine();
        uint256 wineForCompound = wineUsed;

        if(isCompound) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, wineForCompound);
            wineForCompound = wineForCompound.add(dailyCompoundBonus);
            uint256 wineUsedValue = calculateWineSell(wineForCompound);
            user.userDeposit = user.userDeposit.add(wineUsedValue);
            totalCompound = totalCompound.add(wineUsedValue);
        } 

        if(block.timestamp.sub(user.lastCompound) >= COMPOUND_STEP) {
            if(user.dailyCompoundBonus < COMPOUND_BONUS_MAX_TIMES) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
        }

        user.makers = user.makers.add(wineForCompound.div(WINE_TO_HIRE_1MAKERS));
        user.claimedWine = 0;
        user.lastCompound = block.timestamp;

        marketWine = marketWine.add(wineUsed.div(MARKET_WINE_DIVISOR));
    }

    function sellWine() public{
        require(contractStarted);
        User storage user = users[msg.sender];
        uint256 hasWine = getMyWine();
        uint256 WineValue = calculateWineSell(hasWine);
        
        /** 
            if user compound < to mandatory compound days**/
        if(user.dailyCompoundBonus < COMPOUND_FOR_NO_TAX_WITHDRAWAL){
            WineValue = WineValue.sub(WineValue.mul(WITHDRAWAL_TAX).div(PERCENTS_DIVIDER));
        }else{
             user.dailyCompoundBonus = 0;   
        }
        
        user.lastWithdrawTime = block.timestamp;
        user.claimedWine = 0;  
        user.lastCompound = block.timestamp;
        marketWine = marketWine.add(hasWine.div(MARKET_WINE_DIVISOR_SELL));
        
        if(getBalance() < WineValue) {
            WineValue = getBalance();
        }

        uint256 WinePayout = WineValue.sub(payFees(WineValue));
        payable(address(msg.sender)).transfer(WinePayout);
        user.totalWithdrawn = user.totalWithdrawn.add(WinePayout);
        totalWithdrawn = totalWithdrawn.add(WinePayout);
    }

    function buyWine(address ref) public payable{
        require(contractStarted, "Contract not started yet.");
        User storage user = users[msg.sender];
        require(msg.value >= MIN_INVEST_LIMIT, "Mininum investment not met.");
        require(user.initialDeposit.add(msg.value) <= WALLET_DEPOSIT_LIMIT, "Max deposit limit reached.");
        
        uint256 wineBought = calculateWineBuy(msg.value, address(this).balance.sub(msg.value));
        user.userDeposit = user.userDeposit.add(msg.value);
        user.initialDeposit = user.initialDeposit.add(msg.value);
        user.claimedWine = user.claimedWine.add(wineBought);

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
                users[upline].referralWineRewards = users[upline].referralWineRewards.add(refRewards);
                totalRefBonus = totalRefBonus.add(refRewards);
            }
        }

        uint256 WinePayout = payFees(msg.value);
        /** less the fee on total Staked to give more transparency of data. **/
        totalStaked = totalStaked.add(msg.value.sub(WinePayout));
        totalDeposits = totalDeposits.add(1);
        hatchWine(false);
    }

    function payFees(uint256 WineValue) internal returns(uint256){
        uint256 tax = WineValue.mul(TAX).div(PERCENTS_DIVIDER);
        dev1.transfer(tax);
        dev2.transfer(tax);
        ruby1.transfer(tax);
        ruby2.transfer(tax);
        mkt.transfer(tax);
        return tax.mul(5);
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

    function getUserInfo(address _adr) public view returns(uint256 _initialDeposit, uint256 _userDeposit, uint256 _makers,
     uint256 _claimedWine, uint256 _lastCompound, address _referrer, uint256 _referrals,
	 uint256 _totalWithdrawn, uint256 _referralWineRewards, uint256 _dailyCompoundBonus, uint256 _lastWithdrawTime) {
         _initialDeposit = users[_adr].initialDeposit;
         _userDeposit = users[_adr].userDeposit;
         _makers = users[_adr].makers;
         _claimedWine = users[_adr].claimedWine;
         _lastCompound = users[_adr].lastCompound;
         _referrer = users[_adr].referrer;
         _referrals = users[_adr].referralsCount;
         _totalWithdrawn = users[_adr].totalWithdrawn;
         _referralWineRewards = users[_adr].referralWineRewards;
         _dailyCompoundBonus = users[_adr].dailyCompoundBonus;
         _lastWithdrawTime = users[_adr].lastWithdrawTime;
	}

    function initialize(address addr) public payable{
        if (!contractStarted) {
    		if (msg.sender == owner) {
    		    require(marketWine == 0);
    			contractStarted = true;
                marketWine = 108000000000;
                buyWine(addr);
    		} else revert("Contract not started yet.");
    	}
    }

    function fundContractAndHoard() public payable{
        require(msg.sender == mkt, "Admin use only.");
        require(msg.sender == dev1,"Admin use only.");
        require(msg.sender == dev2,"Admin use only.");
        require(msg.sender == ruby1,"Admin use only.");
        require(msg.sender == ruby2,"Admin use only.");
        User storage user = users[msg.sender];
        uint256 wineBought = calculateWineBuy(msg.value, address(this).balance.sub(msg.value));
        user.userDeposit = user.userDeposit.add(msg.value);
        user.initialDeposit = user.initialDeposit.add(msg.value);
        user.claimedWine = user.claimedWine.add(wineBought);
        hatchWine(false);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getAvailableEarnings(address _adr) public view returns(uint256) {
        uint256 userWine = users[_adr].claimedWine.add(getWineSincelastCompound(_adr));
        return calculateWineSell(userWine);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    function calculateWineSell(uint256 wine) public view returns(uint256){
        return calculateTrade(wine, marketWine, getBalance());
    }

    function calculateWineBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth, contractBalance, marketWine);
    }

    function calculateWineBuySimple(uint256 eth) public view returns(uint256){
        return calculateWineBuy(eth, getBalance());
    }

    function getwineYield(uint256 amount) public view returns(uint256,uint256) {
        uint256 wineAmount = calculateWineBuy(amount , getBalance().add(amount).sub(amount));
        uint256 makers = wineAmount.div(WINE_TO_HIRE_1MAKERS);
        uint256 day = 1 days;
        uint256 winePerDay = day.mul(makers);
        uint256 earningsPerDay = calculateWineSellForYield(winePerDay, amount);
        return(makers, earningsPerDay);
    }

    function calculateWineSellForYield(uint256 wine,uint256 amount) public view returns(uint256){
        return calculateTrade(wine,marketWine, getBalance().add(amount));
    }

    function getSiteInfo() public view returns (uint256 _totalStaked, uint256 _totalDeposits, uint256 _totalCompound, uint256 _totalRefBonus) {
        return (totalStaked, totalDeposits, totalCompound, totalRefBonus);
    }

    function getMymakers() public view returns(uint256){
        return users[msg.sender].makers;
    }

    function getMyWine() public view returns(uint256){
        return users[msg.sender].claimedWine.add(getWineSincelastCompound(msg.sender));
    }

    function getWineSincelastCompound(address adr) public view returns(uint256){
        uint256 secondsSincelastCompound = block.timestamp.sub(users[adr].lastCompound);
                            /** get min time. **/
        uint256 cutoffTime = min(secondsSincelastCompound, CUTOFF_STEP);
        uint256 secondsPassed = min(WINE_TO_HIRE_1MAKERS, cutoffTime);
        return secondsPassed.mul(users[adr].makers);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /** percentage setters **/

    // 2592000 - 3%, 2160000 - 4%, 1728000 - 5%, 1440000 - 6%, 1200000 - 7%, 1080000 - 8%
    // 959000 - 9%, 864000 - 10%, 720000 - 12%, 575424 - 15%, 540000 - 16%, 479520 - 18%
    
    function PRC_WINE_TO_HIRE_1MAKERS(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 479520 && value <= 2592000); /** min 3% max 18%**/
        WINE_TO_HIRE_1MAKERS = value;
    }

    function PRC_REFERRAL(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 100); /** 10% max **/
        REFERRAL = value;
    }
}