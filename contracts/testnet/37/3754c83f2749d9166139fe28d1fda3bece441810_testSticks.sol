// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./w-IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract testSticks is ReentrancyGuard, Ownable{
    /*function someAction(address addr) returns(uint) {
        Callee c = Callee(addr);
        return c.getValue(100);
    }*/

    uint constant DECIMALS = 10**18;

    uint256 private backingPrice;
    uint256 private scepterBuyPrice;
    uint256 private scepterSellPrice;

    uint256 private treasuryUSDC;
    //addresses of Treasuries
    address public treasury1Addr;
    address public scepterTreasuryAddr;
    address public riskTreasuryAddr;
    address public devWalletAddr;

    //view treasuries balances
    uint256 public sptrTreasuryBal;

    //Time Factors
    uint256 public timeLaunched;
    uint256 public daysInCalculation;

    //fortest
    uint256 private ft5daybought = 100000;
    uint256 private ft5daysold = 90000;
    uint256 private double5daytokens = 600000;
   // uint256 private a = 9;
    //uint256 private bc = 10;
    int128 public res;
    address public testwallet = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;

    //Scepter public scepterToken;
    //address public usdcToken= 0x291153a24E642A16e876aB68B4516f1a8EdadDD3;
    
    //IERC20 public tSC; //SPTR, //WAND //BTON
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
    //Scepter private sptr;
    //Baton private btn;
    //Wand private wand;

    /**
    Events
    **/
    event sceptersBought(address indexed _from, uint256 _amount);
    event sceptersSold(address indexed _from, uint256 _amount);

    constructor() {   
        //INIT Contracts, Treasuries and ERC20 Tokens
        SPTR = IERC20(0x060e26006476351141C5B77fCF42Dd534a7c279a);
        WAND = IERC20(0x4506069A92686023320AE5F853555EFd6d6CcCeC);
        BTON = IERC20(0xaE126F05feab84436c8f470c44270329a3a348E5);
        //tSC = IERC20(scepterAddr);
        //init USDC
        stableERC20Info["USDC"].contractAddress = 0xe8015d99e16fe4918261C3A62582EB8AA72C590C;
        stableERC20Info["USDC"].tokenDecimals = 6;
        //init DAI
        stableERC20Info["DAI"].contractAddress = 0x2A4a8Ab6A0Bc0d377098F8688F77003833BC1C9d;
        stableERC20Info["DAI"].tokenDecimals = 18;
        //init FRAX
        stableERC20Info["FRAX"].contractAddress = 0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355;
        stableERC20Info["FRAX"].tokenDecimals = 18;

        treasury1Addr = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;

        //TODO take in WandAirdrop contract
        //airdrop = WandAirdrop(airdropAddr);

        }
        
    // Math Functions
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "uint overflow from multiplication");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "division by zero");
        uint256 c = a / b;
        return c;
    }
  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "uint underflow from subtraction");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "uint overflow from multiplication");
        return c;
    }
    
    function decMul18(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = mul(x, y);
        decProd = add(prod_xy, DECIMALS / 2) / DECIMALS;
    }

    function decDiv18(uint x, uint y) internal pure returns (uint decQuotient) {
        uint prod_xTEN18 = mul(x, DECIMALS);
        decQuotient = add(prod_xTEN18, y / 2) / y;
    }



  /* function mintScepter(uint256 amount) internal {
        
        tSC.mint(msg.sender, amount);
    } 
        function testMappings(uint256 t, uint256 _amt) public returns (uint256){
       uint256 i = (t - timeLaunched) / 86400;
        tokensBoughtXDays[i] = _amt;
        return i;
    }
    */
    //Front End User Functions
    function cashOutScepter(uint256 amountSCPtoSell, uint256 timeChosenLocked, string memory _stableChosen) public payable{
        //require(msg.sender == trader , "Not authorized");
        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        uint256 trader_tsc_balance = SPTR.balanceOf(msg.sender);
        require(trader_tsc_balance > amountSCPtoSell, "You dont have that amount!");

       /* require(
            mockUSDC.allowance(owner2, address(this)) >= amount2,
            "Token 2 allowance too low"
        );*/
            //WAND to transfer USDC to seller
        tokenStable.transfer(msg.sender, amountSCPtoSell + (1*(DECIMALS)));
            //Transfer the sold tsc to WAND
            //TODO: BURN WAND and BURN SPTR, 
        _safeTransferFrom(SPTR, msg.sender, address(this), amountSCPtoSell);
           uint256 usdcAmt; 
           usdcAmt = this.getSellPrice() * amountSCPtoSell;
        //tSC.transferFrom(msg.sender, address(this), amountSCPtoSell);
        //msg.sender.tSC.transfer(msg.sender, amountSCPtoSell + (1*(10**18)));
        //_safeTransferFrom(token2, owner2, owner1, amount2);
        //Keeping track of tokens sold per day
        uint256 dInArray =(block.timestamp- timeLaunched)/86400; 
        tokensSoldXDays[dInArray] += amountSCPtoSell;
        circulatingSupplyXDays[dInArray] -= amountSCPtoSell;
        //TODO: 
        //Step1: from timeChosenLocked, calculate days and get percentage.
        //Step2: calculate withheldWithdrawals[msg.sender].amounts
        //Step3: withheldWithdrawals[msg.sender].amounts = calculatedAmt, 
        //withheldWithdrawals[msg.sender].timeUnlocked = block.timestamp + timeChosenLocked
    }

    function transformScepterToBaton(uint256 amountSCPtoSwap) public payable{
        //require(msg.sender == trader , "Not authorized");
        uint256 trader_tsc_balance = SPTR.balanceOf(msg.sender);
        require(trader_tsc_balance > amountSCPtoSwap, "You dont have that amount!");

        //TODO: BURN WAND and BURN SPTR
        _safeTransferFrom(SPTR, msg.sender, address(this), amountSCPtoSwap);

        //Keeping track of tokens sold per day
        uint256 dInArray =(block.timestamp- timeLaunched)/86400; 
        tokensSoldXDays[dInArray] += amountSCPtoSwap;
        circulatingSupplyXDays[dInArray] -= amountSCPtoSwap;

        //TODO: Update Airdrop contract
        //airdrop.updateBtonHoldings(amountSCPtoSwap);
    }   
    
    function buyScepter(uint256 amountSCPtoBuy, string memory _stableChosen) public nonReentrant{
        //require(msg.sender == trader , "Not authorized");
        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        require(amountSCPtoBuy <= 250000 , "Per transaction limit");
        uint256 trader_usdc_balance = tokenStable.balanceOf(msg.sender);
        require(trader_usdc_balance > amountSCPtoBuy, "You dont have that amount!");
        //calculate amount of stables to pay
        
        uint256 usdAmtToPay;
        usdAmtToPay = decMul18(amountSCPtoBuy, this.getBuyPrice()) * stableERC20Info[_stableChosen].tokenDecimals;

        //Transfer USDC to WI from trader
        _safeTransferFrom(tokenStable, msg.sender, address(this), usdAmtToPay);
      
        SPTR.mint(msg.sender,amountSCPtoBuy * DECIMALS);
        WAND.mint(address(this),amountSCPtoBuy * DECIMALS); //TODO: Activate and test

        //Keeping track of tokens bought per day
        uint256 dInArray =(block.timestamp- timeLaunched)/86400; 
        tokensBoughtXDays[dInArray] += amountSCPtoBuy;
        circulatingSupplyXDays[dInArray] += amountSCPtoBuy;

        emit sceptersBought(msg.sender, amountSCPtoBuy);
    }

    function claimLockedUSDC(address _claimant, string memory _stableChosen) public {
        require (block.timestamp >= withheldWithdrawals[_claimant].timeUnlocked, "Not unlocked");
        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        //function to claim the USDC locked after cashing out scepter
        uint256 claimAmts;
        claimAmts = withheldWithdrawals[_claimant].amounts;
        _safeTransferFrom(tokenStable, address(this), msg.sender, claimAmts);

    }
    function getCircSupplyXDays() public view returns (uint256){
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

        //return CircSupplyXDays;
    }
    //Front End Display
    function getGrowthFactor() external view returns (uint256){
        //FORMULA: 2* (number of tokens bought over the last X days / total number of tokens existing X days ago) and capped at 1.2
        uint256 _gF;
       // uint256 xDaysCircSupply;
        //uint256 numdays = daysInCalculation/86400;
        //uint256 daySinceLaunched = (block.timestamp - timeLaunched) / 86400;
        //uint256 d;
      // xDaysCircSupply = getCircSupplyXDays(); 

       _gF = decDiv18(this.getTokensBoughtXDays(),getCircSupplyXDays());
       if (_gF > 300000000000000000)
       {
           _gF = 300000000000000000;
       }
       return _gF ;
    }
    function getSellFactor() external view returns (uint256){
        //FORMULA:  2 * (number of tokens sold over the last X days / total number of tokens existing X days ago) and capped at 0.3.
        uint256 _sF; 
        //uint256 xDaysCircSupply;
        //uint256 numdays = daysInCalculation/86400;
        //uint256 daySinceLaunched = (block.timestamp - timeLaunched) / 86400;
        //uint256 d;

        //xDaysCircSupply = getCircSupplyXDays(); 

       _sF = decDiv18(this.getTokensSoldXDays(),getCircSupplyXDays());
       if (_sF > 300000000000000000)
       {
           _sF = 300000000000000000;
       }
       return _sF ;
    }
    function getBackingPrice() external view returns (uint256){
        //FORMULA: Scepter Treasury in USDC divide by Total Supply of Scepters

       return decDiv18(sptrTreasuryBal * DECIMALS,SPTR.totalSupply());
    }
    function getBuyPrice() external view returns (uint256){
         //FORMULA: Backing Price * (1.2 + Growth factor)
         //Price Protocol use to sell to investors
        return decMul18(this.getBackingPrice() , (1200000000000000000 + this.getGrowthFactor()));

    }
    function getSellPrice() external view returns (uint256){
        //FORMULA: Backing price * (0.9 - Sell factor) 
        //Price Protocol use to buy back from investors
        return decMul18(this.getBackingPrice() , (900000000000000000 - this.getSellFactor()));
    }

    function updateSPTRTreasuryBal() external onlyOwner {
        tokenStable = IERC20(stableERC20Info["USDC"].contractAddress);
        //sptrTreasuryBal = tokenStable.balanceOf(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);  
    }       


    //Admin Functions

    function Launch() public onlyOwner{
        timeLaunched = block.timestamp;
        daysInCalculation = 5 days;

        //airdrop SPTRS to seeds
        SPTR.mint(0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 9411764706 * 10**12); //seed 1
        SPTR.mint(0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 4470588235 * 10**13); //seed 2
        SPTR.mint(0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678, 4705882353 * 10**13); //seed 3

        WAND.mint(address(this), (9411764706 * 10**12) + (4470588235 * 10**13) + (4705882353 * 10**13));
        
        tokensBoughtXDays[0] = (9411764706 * 10**12) + (4470588235 * 10**13) + (4705882353 * 10**13);
        circulatingSupplyXDays[0] = (9411764706 * 10**12) + (4470588235 * 10**13) + (4705882353 * 10**13);

        sptrTreasuryBal = 570000;

        
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
        uint256 boughtnum;
        uint256 d;
        uint256 numdays = daysInCalculation/86400;
        uint256 daySinceLaunched = (block.timestamp - timeLaunched) / 86400;
        if (daySinceLaunched == 0) {
        return tokensBoughtXDays[0];
        }
        for (d = daySinceLaunched - numdays; d < daySinceLaunched; d++) {  //for loop example
          boughtnum += tokensBoughtXDays[d];
            }
        
       return boughtnum;
    }
    function getTokensSoldXDays() external view returns (uint256){
        uint256 soldNum;
        uint256 d;
        uint256 numdays = daysInCalculation/86400;

        for (d = 0; d < numdays; d++) { 
          soldNum += tokensSoldXDays[d];
      }
       return soldNum;
    }


    function whitelist(address _addr) public onlyOwner {  
        //TODO: 
        
    }

    function addStable(string memory _ticker, address _addr, uint256 _dec) public onlyOwner {
    
        stableERC20Info[_ticker].contractAddress = _addr;
        stableERC20Info[_ticker].tokenDecimals = _dec;

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