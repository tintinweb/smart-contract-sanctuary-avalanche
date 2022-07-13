/**
 *Submitted for verification at snowtrace.io on 2022-07-12
*/

pragma solidity ^0.4.24; // solhint-disable-line

contract AVAXWindmill{
    uint256 public wheat_TO_HATCH_1MINERS=864000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedwheat;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketwheat;
    constructor() public{
        ceoAddress=msg.sender;
        ceoAddress2=address(0x42242c834c5CE6b89b4c989935653ebCEE5cCa20);
    }
    function hatchwheat(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 wheatUsed=getMywheat();
        uint256 newMiners=SafeMath.div(wheatUsed,wheat_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedwheat[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral wheat
        claimedwheat[referrals[msg.sender]]=SafeMath.add(claimedwheat[referrals[msg.sender]],SafeMath.div(wheatUsed,10));
        
        //boost market to nerf miners hoarding
        marketwheat=SafeMath.add(marketwheat,SafeMath.div(wheatUsed,5));
    }
    function sellwheat() public{
        require(initialized);
        uint256 haswheat=getMywheat();
        uint256 wheatValue=calculatewheatell(haswheat);
        uint256 fee=devFee(wheatValue);
        uint256 fee2=fee/2;
        claimedwheat[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketwheat=SafeMath.add(marketwheat,haswheat);
        ceoAddress.transfer(fee2);
        ceoAddress2.transfer(fee-fee2);
        msg.sender.transfer(SafeMath.sub(wheatValue,fee));
    }
    function buywheat(address ref) public payable{
        require(initialized);
        uint256 wheatBought=calculatewheatBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        wheatBought=SafeMath.sub(wheatBought,devFee(wheatBought));
        uint256 fee=devFee(msg.value);
        uint256 fee2=fee/2;
        ceoAddress.transfer(fee2);
        ceoAddress2.transfer(fee-fee2);
        claimedwheat[msg.sender]=SafeMath.add(claimedwheat[msg.sender],wheatBought);
        hatchwheat(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculatewheatell(uint256 wheat) public view returns(uint256){
        return calculateTrade(wheat,marketwheat,address(this).balance);
    }
    function calculatewheatBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketwheat);
    }
    function calculatewheatBuySimple(uint256 eth) public view returns(uint256){
        return calculatewheatBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,10),100);
    }
    function seedMarket() public payable{
        require(marketwheat==0);
        initialized=true;
        marketwheat=86400000000;                
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMywheat() public view returns(uint256){
        return SafeMath.add(claimedwheat[msg.sender],getwheatSinceLastHatch(msg.sender));
    }
    function getwheatSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(wheat_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}