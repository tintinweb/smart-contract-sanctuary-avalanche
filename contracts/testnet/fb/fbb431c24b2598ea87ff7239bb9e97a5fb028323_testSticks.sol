// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./w-IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "mathFunclib.sol";

contract testSticks is ReentrancyGuard, Ownable{

    uint constant DECIMALS = 10**18; 
    uint256 constant secondsInADay = 60*60*24;

    bool public tradingEnabled = false;

    //addresses of Treasuries TODO: to hardcode
    address public scepterTreasuryAddr = 0xf9933F7BDD6B328731B9AA36Dbb50606EB635E5B;
    address public batonTreasuryAddr = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address public riskTreasuryAddr=0x9C1D441BeD46014403b5408f14223f0D2F06b143;
    address public devWalletAddr = 0x4a55c1181B4aeC55cF8e71377e8518E742F9Ae72;

    mapping(address => bool) public whiteListAddresses;
    mapping(uint256 => uint256) public taxForLocks;

    //view treasuries balances
    uint256 public sptrTreasuryBal;
    uint256 public btonTreasuryBal;

    //Time Factors
    uint256 public timeLaunched = 0;
    uint256 public daysInCalculation;

    uint256 maxWithdrawTax = 90;
    uint256 daysTax;


    address public testwallet = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;

    //WandInvestments tokens
    IERC20 public SPTR;
    IERC20 public WAND;
    IERC20 public BTON;

    IERC20 public tokenStable;

    //tokens bought/sold daily tracker mappings
    mapping(uint256 => uint256) public tokensBoughtXDays;
    mapping(uint256 => uint256) public tokensSoldXDays;
    mapping(uint256 => uint256) public circulatingSupplyXDays;
    
    struct stableTokensParams {  
        address contractAddress;  
        uint256 tokenDecimals;  
        }

    mapping (string => stableTokensParams) public stableERC20Info;

    struct lockedamounts {  
        uint256 timeUnlocked;  
        uint256 amounts;  
        }
    mapping(address => lockedamounts) public withheldWithdrawals; 
    mapping(address => uint256) public userBTONAirdropAmts;  

    //For the purpose of votes
    mapping(address => uint256) public initialTimeHeld;
    mapping(address => uint256) public timeSold;

    /**
    Events
    **/
    event sceptersBought(address indexed _from, uint256 _amount);
    event sceptersSold(address indexed _from, uint256 _amount);
    //event airdroppedUSD(address indexed _to, uint256 _amount);

    constructor() {   
        //INIT Contracts, Treasuries and ERC20 Tokens
        SPTR = IERC20(0xD8098BE05A7d32636f806660E40451ab1df3f840);
        WAND = IERC20(0xBe20CdD46F4aEE7dc9b427EA64630486e8445174);
        BTON = IERC20(0x0A0AebE2ABF81bd34d5dA7E242C0994B51fF5c1f);
        //init USDC
        stableERC20Info["USDC"].contractAddress = 0x8f2431dcb2Ad3581cb1f75FA456931e7A15C6d43;
        stableERC20Info["USDC"].tokenDecimals = 6;
        //init DAI
        stableERC20Info["DAI"].contractAddress = 0x2A4a8Ab6A0Bc0d377098F8688F77003833BC1C9d;
        stableERC20Info["DAI"].tokenDecimals = 18;
        //init FRAX
        stableERC20Info["FRAX"].contractAddress = 0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355;
        stableERC20Info["FRAX"].tokenDecimals = 18;
            
        //fix percentage
        
        for (daysTax = 0; daysTax < 10; daysTax++)
        {
            taxForLocks[daysTax] = maxWithdrawTax - (daysTax*10) ;
        }
        
        //TODO take in WandAirdrop contract
        //airdrop = WandAirdrop(airdropAddr);

        }


    //Front End User Functions
    function cashOutScepter(uint256 amountSPTRtoSell, uint256 daysChosenLocked, string memory _stableChosen) public nonReentrant{

        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        require(SPTR.balanceOf(msg.sender) >= amountSPTRtoSell, "You dont have that amount!");

        //burn wand and sptr
        WAND.burn(address(this),amountSPTRtoSell);
        SPTR.burn(msg.sender,amountSPTRtoSell);
        
        //Keeping track of tokens sold per day
        uint256 dInArray =(block.timestamp- timeLaunched)/86400; 
        tokensSoldXDays[dInArray] += amountSPTRtoSell;
        circulatingSupplyXDays[dInArray] -= amountSPTRtoSell;

        //Calculatin USD amount to user and to dev.
        uint256 usdAmt; 
        usdAmt = mathFuncs.decMul18(this.getSellPrice() , amountSPTRtoSell);
        
        //TODO: 
        if (daysChosenLocked ==0) //payout immediate.
        {
            usdAmt = mathFuncs.decMul18(usdAmt,mathFuncs.decDiv18(10,100)); //10% payout
            uint256 usdAmtTrf = usdAmt/(10**(18-stableERC20Info[_stableChosen].tokenDecimals)); //Converted to decimals
            tokenStable.transfer(msg.sender, usdAmtTrf); 
            tokenStable.transfer(devWalletAddr, mathFuncs.decMul18(usdAmtTrf,mathFuncs.decDiv18(5,100)));
            sptrTreasuryBal -= usdAmt / DECIMALS;
        }
        else { //locked TODO: Check decimals
        withheldWithdrawals[msg.sender].amounts = mathFuncs.decMul18(usdAmt,mathFuncs.decDiv18(taxForLocks[daysChosenLocked],100));
        withheldWithdrawals[msg.sender].timeUnlocked = block.timestamp + (daysChosenLocked * secondsInADay);
        sptrTreasuryBal -= usdAmt / DECIMALS;
        }
        
        // For voting system
        if (timeSold[msg.sender] ==0)
        {
            timeSold[msg.sender] = block.timestamp;
        }
        else if ((SPTR.balanceOf(msg.sender) ==0 ) && (BTON.balanceOf(msg.sender)==0))
        {
            initialTimeHeld[msg.sender] = 0;
        }
        
    }

    function cashOutBaton(uint256 amountBTONtoSell, string memory _stableChosen) public payable nonReentrant{
        require(tradingEnabled, "Disabled");
        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        require(BTON.balanceOf(msg.sender) >= amountBTONtoSell, "You dont have that amount!");

        //WAND to transfer USDC to seller

        uint256 usdAmt; 
        usdAmt = mathFuncs.decMul18(this.getBTONRedeemingPrice() , amountBTONtoSell) / (10**(18-stableERC20Info[_stableChosen].tokenDecimals));
        
        BTON.burn(msg.sender,amountBTONtoSell);

        // For voting system
        if (timeSold[msg.sender] ==0)
        {
            timeSold[msg.sender] = block.timestamp;
        }
        else if ((SPTR.balanceOf(msg.sender) ==0 ) && (BTON.balanceOf(msg.sender)==0))
        {
            initialTimeHeld[msg.sender] = 0;
        }
        
    }

    function transformScepterToBaton(uint256 amountSPTRtoSwap) public payable nonReentrant{
        require(tradingEnabled, "Disabled");
        require(SPTR.balanceOf(msg.sender) >= amountSPTRtoSwap, "You dont have that amount!");

        //uint256 sptrAmt = amountSCPtoSwap * DECIMALS;

        WAND.burn(address(this),amountSPTRtoSwap);
        SPTR.burn(msg.sender,amountSPTRtoSwap);
        BTON.mint(msg.sender,amountSPTRtoSwap);

        //Keeping track of SPTRS sold per day
        uint256 dInArray =(block.timestamp- timeLaunched)/86400; 
        tokensSoldXDays[dInArray] += amountSPTRtoSwap;
        circulatingSupplyXDays[dInArray] -= amountSPTRtoSwap;

        //Transfer 90% of value of amountSPTRtoSwap getSPTRBackingPrice() token to baton treasury
        uint256 btonTreaAmtTrf; 
        btonTreaAmtTrf = mathFuncs.decMul18(this.getSPTRBackingPrice(), amountSPTRtoSwap);
        uint256 toTrf = mathFuncs.decMul18(btonTreaAmtTrf, mathFuncs.div(9,10)) / (10**12);
        tokenStable = IERC20(stableERC20Info["USDC"].contractAddress);
        tokenStable.transfer(batonTreasuryAddr, toTrf); 
        //TODO: do i need to store wallet address here or i can get from holders listing
    }   
    
    function buyScepter(uint256 amountSPTRtoBuy, string memory _stableChosen) public nonReentrant{
        require(tradingEnabled, "Disabled");
        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        require(amountSPTRtoBuy <= 250000 * DECIMALS , "Per transaction limit");
       // require(tokenStable.balanceOf(msg.sender) > amountSCPtoBuy, "You dont have that amount!");
        //calculate amount of stables to pay
        //uint256 sptrAmt = amountSCPtoBuy * DECIMALS;
        uint256 usdAmt;
        uint256 usdAmtToPay;
        usdAmt = mathFuncs.decMul18(amountSPTRtoBuy, this.getBuyPrice());
        usdAmtToPay = usdAmt / (10**(18-stableERC20Info[_stableChosen].tokenDecimals));

        //Transfer USDC to WI from trader
        _safeTransferFrom(tokenStable, msg.sender, scepterTreasuryAddr, mathFuncs.decMul18(usdAmtToPay,mathFuncs.decDiv18(95,100)));
        _safeTransferFrom(tokenStable, msg.sender, devWalletAddr, mathFuncs.decMul18(usdAmtToPay,mathFuncs.decDiv18(5,100)));

        SPTR.mint(msg.sender, amountSPTRtoBuy);
        WAND.mint(scepterTreasuryAddr, amountSPTRtoBuy); //APPROVE SPTR TREASURY TO TRANSFER

        //Keeping track of tokens bought per day
        uint256 dInArray =(block.timestamp- timeLaunched)/86400; 
        tokensBoughtXDays[dInArray] += amountSPTRtoBuy;
        circulatingSupplyXDays[dInArray] += amountSPTRtoBuy;

        if (initialTimeHeld[msg.sender] ==0)
        {
            initialTimeHeld[msg.sender] =block.timestamp;
        }
        
        sptrTreasuryBal += mathFuncs.decMul18(usdAmt,9500000000000000000) / DECIMALS;

        emit sceptersBought(msg.sender, amountSPTRtoBuy);
    }

    function wlBuyScepter(uint256 amountSPTRtoBuy, string memory _stableChosen) public nonReentrant{
        require(tradingEnabled, "Disabled");
        require(block.timestamp > timeLaunched + 172800); //48hrs
        require(whiteListAddresses[msg.sender] , "Not Whitelisted");
        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        require(amountSPTRtoBuy <= 250000 * DECIMALS , "Per transaction limit");

        uint256 usdAmtToPay;
        
        usdAmtToPay = mathFuncs.decDiv18(amountSPTRtoBuy, (10**(18-stableERC20Info[_stableChosen].tokenDecimals)));

        //Transfer USDC to WI from trader
        _safeTransferFrom(tokenStable, msg.sender, scepterTreasuryAddr, mathFuncs.decMul18(usdAmtToPay,mathFuncs.decDiv18(95,100)));
        _safeTransferFrom(tokenStable, msg.sender, devWalletAddr, mathFuncs.decMul18(usdAmtToPay,mathFuncs.decDiv18(5,100)));

      
        SPTR.mint(msg.sender, amountSPTRtoBuy);
        WAND.mint(scepterTreasuryAddr, amountSPTRtoBuy); //APPROVE SPTR TREASURY TO TRANSFER

        sptrTreasuryBal += mathFuncs.decMul18(amountSPTRtoBuy,9500000000000000000) / DECIMALS;

        emit sceptersBought(msg.sender, amountSPTRtoBuy);
    }

    function claimLockedUSDC(address _claimant, string memory _stableChosen) public {
        require(tradingEnabled, "Disabled");
        require (block.timestamp >= withheldWithdrawals[_claimant].timeUnlocked, "Not unlocked");
        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        //function to claim the USDC locked after cashing out scepter
        uint256 claimAmts;
        claimAmts = withheldWithdrawals[_claimant].amounts;
        _safeTransferFrom(tokenStable, address(this), msg.sender, claimAmts);

    }

    //Front End Display

    function getCircSupplyXDays() external view returns (uint256){
		uint256 daySinceLaunched = (block.timestamp - timeLaunched) / 86400;
        uint256 CircSupplyXDays = 0;
        uint256 numdays = daysInCalculation/86400;
        uint256 d;
        
        if (daySinceLaunched ==0) {
            return circulatingSupplyXDays[0];
        }
        else if (daySinceLaunched < numdays)
        {
            for (d = 0; d < daySinceLaunched; d++) {
            CircSupplyXDays += circulatingSupplyXDays[d];
            }
            return CircSupplyXDays;
        }
        else{
            for (d = daySinceLaunched - numdays; d < daySinceLaunched; d++) {
            CircSupplyXDays += circulatingSupplyXDays[d];
            }
            return CircSupplyXDays;
        }

    }


    function getGrowthFactor() external view returns (uint256){
        //FORMULA: 2* (number of tokens bought over the last X days / total number of tokens existing X days ago) and capped at 0.3
        uint256 _gF;
       // uint256 xDaysCircSupply;
        //uint256 numdays = daysInCalculation/86400;
        //uint256 daySinceLaunched = (block.timestamp - timeLaunched) / 86400;
        //uint256 d;
      // xDaysCircSupply = getCircSupplyXDays(); 

       _gF = 2 * (mathFuncs.decDiv18(this.getTokensBoughtXDays(), this.getCircSupplyXDays()));
       if (_gF > 300000000000000000)
       {
           _gF = 300000000000000000;
       }
       return _gF ;
    }

    function getSellFactor() external view returns (uint256){
        //FORMULA:  2 * (number of tokens sold over the last X days / total number of tokens existing X days ago) and capped at 0.3.
        uint256 _sF; 
 
       _sF = 2 * (mathFuncs.decDiv18(this.getTokensSoldXDays(), this.getCircSupplyXDays()));
       if (_sF > 300000000000000000)
       {
           _sF = 300000000000000000;
       }
       return _sF ;
    }

    function getSPTRBackingPrice() external view returns (uint256){
        //FORMULA: Scepter Treasury in USDC divide by Total Supply of Scepters

       return mathFuncs.decDiv18(sptrTreasuryBal * DECIMALS,SPTR.totalSupply());
    }

    function getBTONBackingPrice() external view returns (uint256){
        //FORMULA: Baton Treasury in USDC divide by Total Supply of Baton

       return mathFuncs.decDiv18(btonTreasuryBal * DECIMALS, BTON.totalSupply());
    }

    function getBTONRedeemingPrice() external view returns (uint256){
        //FORMULA: 30% of Baton backing price, capped at half of scepter backing price
        if (mathFuncs.decMul18(this.getBTONBackingPrice(), mathFuncs.div(30,100)) > mathFuncs.decDiv18(this.getSPTRBackingPrice(), 2))
        {
            return mathFuncs.decDiv18(this.getSPTRBackingPrice(), 2);
        }
        else
        {
            return mathFuncs.decMul18(this.getBTONBackingPrice(), mathFuncs.div(30,100));
        }
       
    }

    function getBuyPrice() external view returns (uint256){
         //FORMULA: Backing Price * (1.2 + Growth factor)
         //Price Protocol use to sell to investors
        return mathFuncs.decMul18(this.getSPTRBackingPrice() , (1200000000000000000 + this.getGrowthFactor()));

    }

    function getSellPrice() external view returns (uint256){
        //FORMULA: Backing price * (0.9 - Sell factor) 
        //Price Protocol use to buy back from investors
        return mathFuncs.decMul18(this.getSPTRBackingPrice() , (900000000000000000 - this.getSellFactor()));
    }

    //Admin Functions

    function turnOnOffTrading(bool _bool) public onlyOwner{ 
        tradingEnabled = _bool;
    } 

    function updateSPTRTreasuryBal(uint256 _totalAmt) public { //TODO: lockdown

        sptrTreasuryBal = _totalAmt;  
    } 
    function updateBTONTreasuryBal(uint256 _totalAmt) public { //TODO: lockdown

        btonTreasuryBal = _totalAmt;  
    }     

    function Launch() public onlyOwner{
        require (timeLaunched ==0, "Already Launched");
        timeLaunched = block.timestamp;
        daysInCalculation = 5 days;

        //airdrop SPTRS to seeds
        SPTR.mint(0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 9411764706 * 10**12); //seed 1
        SPTR.mint(0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 4470588235 * 10**13); //seed 2
        SPTR.mint(0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678, 4705882353 * 10**13); //seed 3

        WAND.mint(scepterTreasuryAddr, (9411764706 * 10**12) + (4470588235 * 10**13) + (4705882353 * 10**13));
        
        tokensBoughtXDays[0] = (9411764706 * 10**12) + (4470588235 * 10**13) + (4705882353 * 10**13);
        circulatingSupplyXDays[0] = (9411764706 * 10**12) + (4470588235 * 10**13) + (4705882353 * 10**13);
        //TODO: Get the value of treasury bal for launch
        sptrTreasuryBal = 86000;
        btonTreasuryBal = 0; 

        tradingEnabled = true;

    }

    function setDaysUsedInFactors(uint256 numDays) public onlyOwner{  
        daysInCalculation = numDays * 86400;     
    }

    function testUpdatetimeLockedplus(uint256 amt) public  {
        //require(amt > withheldWithdrawals[msg.sender].amounts, "You dont have that much to withdraw!");
        /*     lockedamounts memory currentEntry;
        currentEntry.timeUnlocked = timeUnlocked;
        currentEntry.amounts = amt;
        */
    
        withheldWithdrawals[msg.sender].timeUnlocked = block.timestamp + 864000;
        withheldWithdrawals[msg.sender].amounts += amt;
    
    }
    
    function testUpdatetimeLockedminus(uint256 amt) public  {
        require(amt < withheldWithdrawals[msg.sender].amounts, "You dont have that much to withdraw!");
        /*     lockedamounts memory currentEntry;
        currentEntry.timeUnlocked = timeUnlocked;
        currentEntry.amounts = amt;
        */
        withheldWithdrawals[msg.sender].amounts -= amt;
        if (withheldWithdrawals[msg.sender].amounts ==0 ){
            delete(withheldWithdrawals[msg.sender]);
        }
    }


    function getTokensBoughtXDays() external view returns (uint256){
        uint256 boughtCount =0;
        uint256 d;
        uint256 numdays = daysInCalculation/86400;
        uint256 daySinceLaunched = (block.timestamp - timeLaunched) / 86400;

        if (daySinceLaunched == 0) {
            return tokensBoughtXDays[0];
        }
        else if (daySinceLaunched < numdays)
        {
            for (d = 0; d < daySinceLaunched; d++) {
            boughtCount += tokensBoughtXDays[d];
            }
            return boughtCount;
        }
        else{
            for (d = daySinceLaunched - numdays; d < daySinceLaunched; d++) {  //for loop example
                boughtCount += tokensBoughtXDays[d];
                }
            return boughtCount;
        }
               
    }
    function getTokensSoldXDays() external view returns (uint256){
        uint256 soldCount =0;
        uint256 d;
        uint256 numdays = daysInCalculation/86400;
        uint256 daySinceLaunched = (block.timestamp - timeLaunched) / 86400;

        if (daySinceLaunched == 0) {
            return tokensSoldXDays[0];
        }
        else if (daySinceLaunched < numdays)
        {
            for (d = 0; d < daySinceLaunched; d++) {
            soldCount += tokensSoldXDays[d];
            }
            return soldCount;
        }
        else{
            for (d = daySinceLaunched - numdays; d < daySinceLaunched; d++) {  //for loop example
                soldCount += tokensSoldXDays[d];
                }
            return soldCount;
        }

    }

    function addWhitelistee(address _addr) public onlyOwner {  
       whiteListAddresses[_addr] = true;
    }
    

    function addStable(string memory _ticker, address _addr, uint256 _dec) public onlyOwner {
    
        stableERC20Info[_ticker].contractAddress = _addr;
        stableERC20Info[_ticker].tokenDecimals = _dec;

    }
    
    function removeStable(string memory _ticker) public onlyOwner {
    
        stableERC20Info[_ticker].contractAddress = 0x0000000000000000000000000000000000000000;
    }
    
    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

} //Closing for Main Contract

/**
*
Abstract Functions
*

interface Scepter {
   
    
}
interface Wand {
    function mint(address addrTo, uint256 amount) external  ;
    //function scepterTotalSupply() public view virtual returns (uint256);
    function transferFrom(address addrTo, uint256 amount) external ;
    function burn (address addrFrom, uint256 amount) external  ;
}

interface Baton {
  
    function mint(address addrTo, uint256 amount) external  ;
}**/