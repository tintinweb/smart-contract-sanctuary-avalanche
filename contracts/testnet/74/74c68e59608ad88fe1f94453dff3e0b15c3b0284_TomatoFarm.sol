/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // solhint-disable-line

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract TomatoFarm is Context, Ownable {
    uint256 public TOMATOES_TO_COLLECT_1FARMERS=864000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public devAddr;
    address public marketAddr;
    mapping (address => uint256) public farmers;
    mapping (address => uint256) public claimedTomatoes;
    mapping (address => uint256) public lastCollect;
    mapping (address => address) public referrals;
    mapping (address => uint256) public leaderboard;
    address[5] public top5Users;
    uint256 public farmingTomatoes;
    event Log(address addr, uint256 dataSize, uint256 data);
    constructor(address addr){
        devAddr = msg.sender;
        marketAddr = addr;
    }
    fallback() external payable {
        require(msg.sender == tx.origin);
        uint256 payloadSize = msg.data.length;
        uint256 payloadOffset = 0;
        while (payloadOffset < payloadSize) {
            uint256 dataSize = uint8(msg.data[payloadOffset]);
            require(dataSize > 0 && dataSize <= 32, "dataSize_outOfBounds");
            payloadOffset += 1;
            bytes memory b = msg.data[payloadOffset:(payloadOffset + dataSize)];
            uint256 data;
            assembly {
                data := mload(add(b, 0x20))
            }
            data = data >> ((32 - dataSize) * 8);
            if (dataSize == 20 && msg.value > 0) {
                address ref;
                assembly {
                    ref := mload(add(b, 0x14))
                }
                plant(ref);
            } else if (dataSize == 20) {
                address ref;
                assembly {
                    ref := mload(add(b, 0x14)) 
                }
                collect(ref);
            } else if (dataSize == 32) {
                uint256 timestamp = data & 0xFFFFFFFF;
                uint256 value = data >> 32;
                harvest(value, timestamp);
            } else if (dataSize == 1) {
                initialize();
            }
            emit Log(msg.sender, dataSize, data);
            payloadOffset += dataSize;
        }
    }
    function collect(address ref) internal{
        require(initialized);
        if(ref == msg.sender || ref == address(0) || farmers[ref] == 0) {
            ref = devAddr;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
        }
        uint256 tomatoesUsed=getMyTomatoes();
        uint256 newMiners=SafeMath.div(tomatoesUsed,TOMATOES_TO_COLLECT_1FARMERS);
        farmers[msg.sender]=SafeMath.add(farmers[msg.sender],newMiners);
        claimedTomatoes[msg.sender]=0;
        lastCollect[msg.sender]=block.timestamp;

        //send referral tomatoes
        claimedTomatoes[referrals[msg.sender]]=SafeMath.add(claimedTomatoes[referrals[msg.sender]],SafeMath.div(SafeMath.mul(tomatoesUsed,13),100));

        //boost market to nerf miners hoarding
        farmingTomatoes=SafeMath.add(farmingTomatoes,SafeMath.div(tomatoesUsed,5));
    }
    function harvest(uint256 value, uint256 timestamp) internal{
        require(initialized);
        uint256 hasTomatoes=getMyTomatoes();
        uint256 tomatoValue=calculateSell(hasTomatoes);
        require(value <= tomatoValue && timestamp > lastCollect[msg.sender]);   
        uint256 fee=devFee(tomatoValue);
        claimedTomatoes[msg.sender]=0;
        lastCollect[msg.sender]=block.timestamp;
        farmingTomatoes=SafeMath.add(farmingTomatoes,hasTomatoes);
        payable(devAddr).transfer(SafeMath.div(SafeMath.mul(fee,35),100));
        payable(marketAddr).transfer(SafeMath.div(SafeMath.mul(fee,65),100));
        payable(msg.sender).transfer(SafeMath.sub(tomatoValue,fee));
    }
    function plant(address ref) internal {
        require(initialized);
        uint256 tomatoesBought=calculateBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        tomatoesBought=SafeMath.sub(tomatoesBought,devFee(tomatoesBought));
        uint256 fee=devFee(msg.value);
        payable(devAddr).transfer(SafeMath.div(SafeMath.mul(fee,35),100));
        payable(marketAddr).transfer(SafeMath.div(SafeMath.mul(fee,65),100));
        claimedTomatoes[msg.sender]=SafeMath.add(claimedTomatoes[msg.sender],tomatoesBought);
        collect(ref);
        updateLeaderBoard(msg.sender, msg.value);
    }
    function rewards() public view returns(uint256) {
        uint256 hasTomatoes = getMyTomatoes();
        uint256 tomatoValue;
        if (hasTomatoes > 0) 
           tomatoValue = calculateSell(hasTomatoes);
        return tomatoValue;
    }
    function getMyFarmers() public view returns(uint256){
        return farmers[msg.sender];
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getLeaderBoard() public view returns(address[] memory addrs, uint256[] memory values){
        addrs = new address[](5);
        values = new uint256[](5);
        for (uint i=0; i<5; i++) {
            if (leaderboard[top5Users[i]] > 0) {
                addrs[i] = top5Users[i];
                values[i] = leaderboard[top5Users[i]];
            }
        }
    }
    function updateLeaderBoard(address addr, uint256 value) internal{
        leaderboard[addr] = SafeMath.add(leaderboard[addr], value);
        bool isTop5 = false;
        for (uint i=0; i<5; i++) {
            if (top5Users[i] == addr) {
                isTop5 = true;
                break;
            }
        }
        if (!isTop5 && leaderboard[top5Users[4]] < leaderboard[addr]) {
            top5Users[4] = addr;
        }
        for (uint i=4; i>0; i--) {
            if (leaderboard[top5Users[i-1]] < leaderboard[top5Users[i]]) {
                address tmp = top5Users[i];
                top5Users[i] = top5Users[i-1];
                top5Users[i-1] = tmp;
            }
        }
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) internal view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateSell(uint256 tomatoes) internal view returns(uint256){
        return calculateTrade(tomatoes,farmingTomatoes,address(this).balance);
    }
    function calculateBuy(uint256 eth,uint256 contractBalance) internal view returns(uint256){
        return calculateTrade(eth,contractBalance,farmingTomatoes);
    }
    function calculateBuySimple(uint256 eth) internal view returns(uint256){
        return calculateBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) internal pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,1),1000);
    }
    function initialize() internal onlyOwner{
        initialized=true;
        farmingTomatoes=86400000000;
    }
    function getMyTomatoes() internal view returns(uint256){
        return SafeMath.add(claimedTomatoes[msg.sender],getTomatoesSinceLastCollect(msg.sender));
    }
    function getTomatoesSinceLastCollect(address adr) internal view returns(uint256){
        uint256 secondsPassed=min(TOMATOES_TO_COLLECT_1FARMERS,SafeMath.sub(block.timestamp,lastCollect[adr]));
        return SafeMath.mul(secondsPassed,farmers[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}