// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";

contract CronosCash is Context, Ownable {
    using SafeMath for uint256;

    uint256 constant public TIME_PER_KEEPER = 14400000; // 6 % a day, i.e. 1/0.06 days = 86400/0.06 = 1440000
    uint256 constant private PSN = 10000;
    uint256 constant private PSNH = 5000;
    uint256 constant public councilFee = 3; // 3%

    mapping (address => uint256) public keepers; // basis for display: 6 decimal places
    mapping (address => uint256) public claimedTime; // basis for display: 6 decimal places
    mapping (address => uint256) public lastConstruct;
    mapping (address => address) public referrals;
    uint256 public marketTime; // basis for display: 6 decimal places

    mapping (address => bool) public whitelisters;

    address payable public treasuryWallet;
    address payable public marketingWallet;
    address payable public devWallet2;

    uint256 public whitelistUNIX;
    uint256 public publicUNIX;
    uint256 public nextInterventionUNIX;
    uint256 public interventionStep = 180; // 14 days
    
    constructor(address _treasuryWallet, address _marketingWallet, address _devWallet2, uint256 _whitelistUNIX, uint256 _whitelistLength) {
        treasuryWallet = payable(_treasuryWallet);
        marketingWallet = payable(_marketingWallet);
        devWallet2 = payable(_devWallet2);
        
        whitelistUNIX = _whitelistUNIX;
        publicUNIX = SafeMath.add(whitelistUNIX, _whitelistLength);
        nextInterventionUNIX = SafeMath.add(publicUNIX, interventionStep);

        seedWhitelist();
    }
    
    function constructKeepers(address ref) public checkLaunchTime {        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 timeUsed = getMyTime(msg.sender);
        uint256 newKeepers = SafeMath.div(timeUsed,TIME_PER_KEEPER);
        keepers[msg.sender] = SafeMath.add(keepers[msg.sender],newKeepers);
        claimedTime[msg.sender] = 0;
        lastConstruct[msg.sender] = block.timestamp;
        
        //send referral time
        claimedTime[referrals[msg.sender]] = SafeMath.add(claimedTime[referrals[msg.sender]],SafeMath.div(timeUsed,8));
        
        //boost market to nerf miners hoarding
        marketTime=SafeMath.add(marketTime, timeUsed.mul(15).div(100));
    }
    
    function sellTime() public checkLaunchTime {
        uint256 hasTime = getMyTime(msg.sender);
        uint256 timeValue = calculateTimeSell(hasTime);
        uint256 fee = getCouncilFee(timeValue);
        claimedTime[msg.sender] = 0;
        lastConstruct[msg.sender] = block.timestamp;
        marketTime = SafeMath.add(marketTime,hasTime);

        treasuryWallet.transfer(fee.mul(1).div(10));
        marketingWallet.transfer(fee.mul(1).div(10));
        devWallet2.transfer(fee.mul(1).div(10));
        
        payable (msg.sender).transfer(SafeMath.sub(timeValue,fee));
    }
    
    function buyTime(address ref) public payable checkLaunchTime {
        uint256 timeBought = calculateTimeBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        timeBought = SafeMath.sub(timeBought,getCouncilFee(timeBought));
        uint256 fee = getCouncilFee(msg.value);
        
        treasuryWallet.transfer(fee.mul(1).div(10));
        marketingWallet.transfer(fee.mul(1).div(10));
        devWallet2.transfer(fee.mul(1).div(10));
        
        claimedTime[msg.sender] = SafeMath.add(claimedTime[msg.sender],timeBought).mul(getProgressiveMultiplier()).div(10000);
        constructKeepers(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateTimeSell(uint256 time) public view returns(uint256) {
        return calculateTrade(time,marketTime,address(this).balance);
    }
    
    function calculateTimeBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketTime);
    }
    
    function calculateTimeBuySimple(uint256 eth) public view returns(uint256) {
        return calculateTimeBuy(eth,address(this).balance);
    }
    
    function getCouncilFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,councilFee),100);
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketTime == 0, "Bad init: already initialized");
        require(msg.value == 1 ether, "Bad init: amount of CRO");
        marketTime = TIME_PER_KEEPER.mul(100000);
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyKeepers(address adr) public view returns(uint256) {
        return keepers[adr];
    }
    
    function getMyTime(address adr) public view returns(uint256) {
        return SafeMath.add(claimedTime[adr],getTimeSinceLastConstruct(adr));
    }
    
    function getTimeSinceLastConstruct(address adr) public view returns(uint256) {
        uint256 secondsPassed=SafeMath.sub(block.timestamp,lastConstruct[adr]);
        return SafeMath.mul(secondsPassed,keepers[adr]);
    }


    modifier checkLaunchTime() {
        require(block.timestamp >= whitelistUNIX, "Protocol not launched yet!");
        if(block.timestamp < publicUNIX) {
            require(whitelisters[msg.sender], "Wallet not whitelisted for early launch!");
        }
        _;
    }

    function getProgressiveMultiplier() public view returns(uint256) {
        uint256 x = block.timestamp;
        if(x <= publicUNIX) {
            return 10000;
        }
        x = x.sub(publicUNIX).mul(10000).div(6); // should be +1/6% after first month to become 7%
        return x.div(30).div(86400).add(10000);
    }

    function councilIntervention(uint256 interventionType) public onlyOwner {
        require(block.timestamp >= nextInterventionUNIX, "Cannot intervene yet!");
        require(interventionType <= 2, "Unrecognized type of intervention.");
        nextInterventionUNIX = SafeMath.add(block.timestamp, interventionStep);

        // interventionType == 0: waive (in balanced market)
        if(interventionType == 1) { // boost for new entrants (in recessionary market)
            marketTime = marketTime.mul(11).div(10);
        }
        if(interventionType == 2) { // burn (in very expansionary market)
            marketTime = marketTime.mul(9).div(10);
        }
    }

    function whitelistAdd(address adr) public onlyOwner {
        whitelisters[adr] = true;
    }

    function whitelistRemove(address adr) public onlyOwner {
        whitelisters[adr] = false;
    }

    function seedWhitelist() internal {
        whitelistAdd(address(0x513CDC7297659e71845F76E7119566A957767c8F));
        whitelistAdd(address(0x69bbBfDE43c49fc50f5647223dA5ef4756D78659));
    }
}