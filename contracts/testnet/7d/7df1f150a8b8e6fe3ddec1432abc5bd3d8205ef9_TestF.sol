// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";

contract TestF is Context, Ownable {
    using SafeMath for uint256;

    uint256 constant public CRONIUM_PER_STARSHIP = 14400000; // 6 % a day, i.e. 1/0.06 days = 86400/0.06 = 1440000
    uint256 constant private PSN = 10000;
    uint256 constant private PSNH = 5000;
    uint256 constant public councilFee = 10; // 10%

    mapping (address => uint256) public starships; // basis for display: 6 decimal places
    mapping (address => uint256) public claimedCronium; // basis for display: 6 decimal places
    mapping (address => uint256) public lastConstruct;
    mapping (address => address) public referrals;
    uint256 public marketCronium; // basis for display: 6 decimal places

    mapping (address => bool) public whitelisters;

    address payable public treasuryWallet;
    address payable public devWallet1;
    address payable public devWallet2;

    uint256 public whitelistUNIX;
    uint256 public publicUNIX;
    uint256 public nextInterventionUNIX;
    uint256 public interventionStep = 180; // 14 days
    
    constructor(address _treasuryWallet, address _devWallet1, address _devWallet2, uint256 _whitelistUNIX, uint256 _whitelistLength) {
        treasuryWallet = payable(_treasuryWallet);
        devWallet1 = payable(_devWallet1);
        devWallet2 = payable(_devWallet2);
        
        whitelistUNIX = _whitelistUNIX;
        publicUNIX = SafeMath.add(whitelistUNIX, _whitelistLength);
        nextInterventionUNIX = SafeMath.add(publicUNIX, interventionStep);

        seedWhitelist();
    }
    
    function constructStarships(address ref) public checkLaunchTime {        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 croniumUsed = getMyCronium(msg.sender);
        uint256 newStarships = SafeMath.div(croniumUsed,CRONIUM_PER_STARSHIP);
        starships[msg.sender] = SafeMath.add(starships[msg.sender],newStarships);
        claimedCronium[msg.sender] = 0;
        lastConstruct[msg.sender] = block.timestamp;
        
        //send referral cronium
        claimedCronium[referrals[msg.sender]] = SafeMath.add(claimedCronium[referrals[msg.sender]],SafeMath.div(croniumUsed,8));
        
        //boost market to nerf miners hoarding
        marketCronium=SafeMath.add(marketCronium, croniumUsed.mul(15).div(100));
    }
    
    function sellCronium() public checkLaunchTime {
        uint256 hasCronium = getMyCronium(msg.sender);
        uint256 croniumValue = calculateCroniumSell(hasCronium);
        uint256 fee = getCouncilFee(croniumValue);
        claimedCronium[msg.sender] = 0;
        lastConstruct[msg.sender] = block.timestamp;
        marketCronium = SafeMath.add(marketCronium,hasCronium);

        treasuryWallet.transfer(fee.mul(2).div(10));
        devWallet1.transfer(fee.mul(4).div(10));
        devWallet2.transfer(fee.mul(4).div(10));
        
        payable (msg.sender).transfer(SafeMath.sub(croniumValue,fee));
    }
    
    function buyCronium(address ref) public payable checkLaunchTime {
        uint256 croniumBought = calculateCroniumBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        croniumBought = SafeMath.sub(croniumBought,getCouncilFee(croniumBought));
        uint256 fee = getCouncilFee(msg.value);
        
        treasuryWallet.transfer(fee.mul(2).div(10));
        devWallet1.transfer(fee.mul(4).div(10));
        devWallet2.transfer(fee.mul(4).div(10));
        
        claimedCronium[msg.sender] = SafeMath.add(claimedCronium[msg.sender],croniumBought).mul(getProgressiveMultiplier()).div(10000);
        constructStarships(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateCroniumSell(uint256 cronium) public view returns(uint256) {
        return calculateTrade(cronium,marketCronium,address(this).balance);
    }
    
    function calculateCroniumBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketCronium);
    }
    
    function calculateCroniumBuySimple(uint256 eth) public view returns(uint256) {
        return calculateCroniumBuy(eth,address(this).balance);
    }
    
    function getCouncilFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,councilFee),100);
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketCronium == 0, "Bad init: already initialized");
        require(msg.value == 10000 ether, "Bad init: amount of CRO");
        marketCronium = CRONIUM_PER_STARSHIP.mul(100000);
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyStarships(address adr) public view returns(uint256) {
        return starships[adr];
    }
    
    function getMyCronium(address adr) public view returns(uint256) {
        return SafeMath.add(claimedCronium[adr],getCroniumSinceLastConstruct(adr));
    }
    
    function getCroniumSinceLastConstruct(address adr) public view returns(uint256) {
        uint256 secondsPassed=SafeMath.sub(block.timestamp,lastConstruct[adr]);
        return SafeMath.mul(secondsPassed,starships[adr]);
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
            marketCronium = marketCronium.mul(11).div(10);
        }
        if(interventionType == 2) { // burn (in very expansionary market)
            marketCronium = marketCronium.mul(9).div(10);
        }
    }

    function whitelistAdd(address adr) public onlyOwner {
        whitelisters[adr] = true;
    }

    function whitelistRemove(address adr) public onlyOwner {
        whitelisters[adr] = false;
    }

    function seedWhitelist() internal {
        whitelistAdd(address(0x4A3DA87af1832c680E4BF601AE155B47cDBD43A4));
        whitelistAdd(address(0x69bbBfDE43c49fc50f5647223dA5ef4756D78659));
    }
}