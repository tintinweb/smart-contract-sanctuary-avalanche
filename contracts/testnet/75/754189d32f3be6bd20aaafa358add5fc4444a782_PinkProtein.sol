/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-22
*/

/**
########  #### ##    ## ##    ## ########  ########   #######  ######## ######## #### ##    ## 
##     ##  ##  ###   ## ##   ##  ##     ## ##     ## ##     ##    ##    ##        ##  ###   ## 
##     ##  ##  ####  ## ##  ##   ##     ## ##     ## ##     ##    ##    ##        ##  ####  ## 
########   ##  ## ## ## #####    ########  ########  ##     ##    ##    ######    ##  ## ## ## 
##         ##  ##  #### ##  ##   ##        ##   ##   ##     ##    ##    ##        ##  ##  #### 
##         ##  ##   ### ##   ##  ##        ##    ##  ##     ##    ##    ##        ##  ##   ### 
##        #### ##    ## ##    ## ##        ##     ##  #######     ##    ######## #### ##    ##   
                                                                                       
*/
pragma solidity ^0.4.26;
contract PinkProtein{
    uint256 public PROTS_TO_HATCH_1MINERS=864000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedProts;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketProts;
    constructor() public{
        ceoAddress=msg.sender;
    }
    function hatchProts(address ref) public{
        require(initialized);
        if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = ceoAddress;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
        }
        uint256 ProtsUsed=getMyProts();
        uint256 newMiners=SafeMath.div(ProtsUsed,PROTS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedProts[msg.sender]=0;
        lastHatch[msg.sender]=now;
        claimedProts[referrals[msg.sender]]=SafeMath.add(claimedProts[referrals[msg.sender]],SafeMath.div(SafeMath.mul(ProtsUsed,10),100));
        marketProts=SafeMath.add(marketProts,SafeMath.div(ProtsUsed,5));
    }
    function sellProts() public{
        require(initialized);
        uint256 hasProts=getMyProts();
        uint256 ProtValue=calculateProtsell(hasProts);
        uint256 fee=devFee(ProtValue);
        claimedProts[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketProts=SafeMath.add(marketProts,hasProts);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(ProtValue,fee));
    }
    function buyProts(address ref) public payable{
        require(initialized);
        uint256 ProtsBought=calculateProtBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        ProtsBought=SafeMath.sub(ProtsBought,devFee(ProtsBought));
        uint256 fee=devFee(msg.value);
        ceoAddress.transfer(fee);
        claimedProts[msg.sender]=SafeMath.add(claimedProts[msg.sender],ProtsBought);
        hatchProts(ref);
    }
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateProtsell(uint256 Prots) public view returns(uint256){
        return calculateTrade(Prots,marketProts,address(this).balance);
    }
    function calculateProtBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketProts);
    }
    function calculateProtBuySimple(uint256 eth) public view returns(uint256){
        return calculateProtBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,3),100);
    }
    function seedMarket() public payable{
        require(msg.sender == ceoAddress, 'invalid call');
        require(marketProts==0);
        initialized=true;
        marketProts=86400000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMyProts() public view returns(uint256){
        return SafeMath.add(claimedProts[msg.sender],getProtsSinceLastHatch(msg.sender));
    }
    function getProtsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(PROTS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
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
}