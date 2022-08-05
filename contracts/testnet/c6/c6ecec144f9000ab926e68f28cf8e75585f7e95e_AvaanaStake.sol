/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;


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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only Owner!");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

 

interface AvaanaToken {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract AvaanaStake is Owned{
    using SafeMath for uint256;
    
    address public stakeToken;
    uint256 public totalStakedToken;
    uint256 public stakeholdernumber = 1;
    uint256 public dayPerReward = 1;
    uint256 public decimal = 18;

    uint256 public tier1 = 10000 * (10**decimal);
    uint256 public tier2 = 15000 * (10**decimal);
    uint256 public tier3 = 25000 * (10**decimal);
    uint256 public tier4 = 50000 * (10**decimal);
    uint256 public tier5 = 100000 * (10**decimal);

    event StartStake(uint256 _amount , uint256 _endDate);

     
    constructor(address _contractaddr) public {
        stakeToken = _contractaddr;
    }

     struct StakeDetail{
         uint256 amount;
         uint256 startDate;
         uint256 endDate;
     }

     mapping(address => StakeDetail) public stakeInfo;

     function startStake(uint256 _amount , uint256 _endDate) public {
         require(_amount>0,"Amount should be must be greater than 0");
         require(_endDate < 10000000000);
         require(_endDate > block.timestamp + 7 days,"Staking starts from 7 days minimum");
         stakeInfo[msg.sender] = StakeDetail(_amount,block.timestamp,_endDate);
         require(AvaanaToken(stakeToken).transferFrom(msg.sender,address(this),_amount));
         stakeholdernumber++;
         totalStakedToken = totalStakedToken + _amount;
     }

     function addStakeBalance(uint256 _amount) public{
         require(_amount>0,"Amount should be must be greater than 0");
         require(stakeInfo[msg.sender].amount>0,"You did not initiate a stake. start staking first.");
         stakeInfo[msg.sender].amount = stakeInfo[msg.sender].amount + _amount;
         require(AvaanaToken(stakeToken).transferFrom(msg.sender,address(this),_amount));
         totalStakedToken = totalStakedToken + _amount;
     }

     function userTierLevel(address _wallet) public view returns(uint256){

       uint256 userBalance = stakeInfo[_wallet].amount;
       uint256 endDate = stakeInfo[_wallet].endDate;
       if(block.timestamp<endDate)
       {
          if(userBalance > tier1 && userBalance < tier2){
            return 1;
          }
          else if(userBalance > tier2 && userBalance < tier3){
            return 2;
          }
          else if(userBalance > tier3 && userBalance < tier4){
            return 3;
          }
          else if(userBalance > tier5){
            return 4;
          }
          else{
            return 0;
          }
       }
       else{
         return 0;
       }
     }




     function withdrawToken() public {
         require(block.timestamp > stakeInfo[msg.sender].endDate,"withdraw time is not close");
         uint256 userAmount = stakeInfo[msg.sender].amount;
         require(userAmount>0,"This user has no tokens for staking");
         
         uint256 apy = calculateAPYPercent(stakeInfo[msg.sender].startDate,stakeInfo[msg.sender].endDate);
         uint256 rewardAmount = (userAmount * apy) / (100 * 10**decimal);
         uint256 totalAmount = userAmount + rewardAmount;
         totalStakedToken = totalStakedToken - userAmount; 
         stakeholdernumber--; 
         require(AvaanaToken(stakeToken).transfer(msg.sender,totalAmount)); 
         stakeInfo[msg.sender].amount = 0;
     }


     function calculateAPYPercent(uint256 _startTimeDate , uint256 _endTimeDate) public view returns(uint256) {
            uint256 day = (_endTimeDate - _startTimeDate) / 60 / 60 / 24;
            uint256 constPercent = (100 * (10**18) / stakeholdernumber) * dayPerReward;
            uint256 percent = (day * constPercent) / 100;
            return percent;
     }
}