/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-28
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-07
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-24
*/

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
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
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

interface LPToken {
    function token0()  external view returns (address);
    function approve(address to, uint256 tokens) external returns (bool success);
    function decimals() external view returns (uint256);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract LiquityLock is Owned{
     using SafeMath for uint256;
    
    struct lockerInfo{
        address LPAddress;
        uint256 amount;
        address[] lockedUsers;
        uint256 unlockOn;
        bool istoken;
    }

    mapping (uint256 => lockerInfo) public lockers;
    uint256 public fee = 300000000000000000; // 0.3
    uint256 public lockerCount = 0;
    mapping (address => bool) public lockerisExists;
    mapping (address => uint256) public LpLocker;
    struct userInfo{
        uint256 amount;
        uint256 unlockOn;
        uint256 lockOn;
        bool isVested;
        uint256 vestingInterval;
        uint256 vestingPercent;
        uint256 actualBalance;
        uint256 balanceOf;
        uint256 lastClaimed;
        uint256 initialClaim;
        address to;
        bool    istoken;
        bool emergencyWithdraw;
        address Createduser;
    }

    mapping(address => userInfo[]) public lockedUsersInfo;
    mapping(address => mapping(address => uint256)) public lockedInfoId;
     mapping(address => address[]) public userPerLockers;
    constructor () public {
    }   
    
    mapping (address => mapping(address => userInfo)) public users;
    
    event Deposit(address indexed from,uint256 indexed to,uint256 amount);
    event Withdraw(address indexed from,uint256 indexed to,uint256 amount);

    
    function deposit(address _lpaddress,uint256 _amount,uint256 _unlockOn,address _to,bool _isVested,uint256[] memory _vestingInfo,bool _istoken) public {
        if(!lockerisExists[_lpaddress])
        createLocker(_lpaddress,_istoken);
        // require(msg.value == fee,"Invalid Fee amount");
        LPToken(_lpaddress).transferFrom(msg.sender,address(this),_amount);
        // payable(owner).transfer(msg.value);
        userInfo storage user =  users[msg.sender][_lpaddress];
        lockerInfo storage locker = lockers[LpLocker[_lpaddress]];
      
        // bool isExistingUser = user.lockOn >= block.timestamp;
        bool isExistingUser = user.lockOn >= 0;


        if(!isExistingUser){
            userPerLockers[msg.sender].push(_lpaddress);
        }


        if(_amount > 0 && _unlockOn > 0){
            user.Createduser = msg.sender;
            user.amount = user.amount.add(_amount);
            user.balanceOf = user.balanceOf.add(_amount);
            user.unlockOn = block.timestamp.add(_unlockOn); // _unlockOn = number of days in seconds
            user.lockOn = block.timestamp;
            user.to = _to;
            user.istoken = _istoken;
            user.isVested = _isVested;
            if(_isVested){
            user.vestingInterval = _vestingInfo[0]; // vesting interval
            user.vestingPercent = _vestingInfo[1]; // vesting Percent
            user.actualBalance = user.actualBalance.add(_amount);
            }
            locker.amount = locker.amount.add(_amount);
            locker.lockedUsers.push(msg.sender);
            locker.unlockOn = (user.unlockOn > locker.unlockOn) ? user.unlockOn : locker.unlockOn;

            if(isExistingUser){
                lockedUsersInfo[_lpaddress][lockedInfoId[_lpaddress][msg.sender]] = user ;
               
           }else{
             // lockerbased USer ID
            lockedInfoId[_lpaddress][msg.sender] = lockedUsersInfo[_lpaddress].length;
            // entry 
            lockedUsersInfo[_lpaddress].push(user);
           }
        }
        emit Deposit(_lpaddress,LpLocker[_lpaddress],_amount);
    }

    function transferLockerOwner(address _lpaddress,address createruser,address newowner)public {
       
         userInfo storage user =  users[createruser][_lpaddress];
         bool isExistingUser = user.lockOn > 0 && user.unlockOn > block.timestamp;
         require(isExistingUser,"Invalid User");
             user.to = newowner; 
             lockedUsersInfo[_lpaddress][lockedInfoId[_lpaddress][createruser]] = user ;
        
    }

     function CheckUserData(address _lpaddress,address createruser)public view returns(userInfo memory){

          userInfo storage user =  users[createruser][_lpaddress];
          bool isExistingUser = user.lockOn > 0 && user.unlockOn > block.timestamp;
          return user;
     }

    function getLockerUsersInfo(address _lpaddress) public view returns (userInfo[] memory) {
        return lockedUsersInfo[_lpaddress];
    }
    
    function createLocker(address _lpaddress,bool _istoken) internal {
        lockers[lockerCount] = lockerInfo({
           LPAddress: _lpaddress,
           amount: 0,
           lockedUsers: new address[](0),
           unlockOn: 0,
           istoken: _istoken
        });
        LpLocker[_lpaddress] = lockerCount;
        lockerCount++;
        lockerisExists[_lpaddress] = true;
    }
    
    function getLockerId(address _lpaddress)public view returns(uint256){
        return LpLocker[_lpaddress];
    }
    
     function getLockerInfo(uint256 _id)public view returns(address[] memory){
        return lockers[_id].lockedUsers;
    }


 
     function getuserperlocker(address _useraddress)public view returns(address[] memory){
        return userPerLockers[_useraddress];
    }
    

    function withdrawFunds(address _lpaddress, address _user) public{
        userInfo storage user =  users[_user][_lpaddress];
        require(block.timestamp > user.unlockOn,"Maturity Period is still on !");
        if(user.isVested){
             VestedClaim(user,_lpaddress);
        }else{
            LPToken(_lpaddress).transfer(user.to,user.amount);
        }
        
        emit Withdraw(_lpaddress,LpLocker[_lpaddress],user.amount);
   }

   function VestedClaim(userInfo memory user,address tokenAddress) internal {
        if(user.isVested){
        require(block.timestamp > user.lastClaimed.add(user.vestingInterval),"Vesting Interval is not reached !");
        uint256 toTransfer =  user.actualBalance.mul(user.vestingPercent).div(10000);
        if(toTransfer > user.balanceOf)
            toTransfer = user.balanceOf;
        require(LPToken(tokenAddress).transfer(user.to, toTransfer), "Insufficient balance of presale contract!");
        user.balanceOf = user.balanceOf.sub(toTransfer);
        user.lastClaimed = block.timestamp;
        if(user.initialClaim <= 0)
            user.initialClaim = block.timestamp;
       }else{
        require(LPToken(tokenAddress).transfer(user.to, user.balanceOf), "Insufficient balance of presale contract!");
        user.balanceOf = 0;
        }
    }
   
    function emergencyWithdrawUser(address _lpaddress) public {
        address _user = msg.sender;
        require(lockerisExists[_lpaddress],"Locker Does'nt Exists !");
        userInfo storage user =  users[_user][_lpaddress];
        require(user.emergencyWithdraw, "Emergency Withdraw : Unsuccessful");
        LPToken(_lpaddress).transfer(_user,user.balanceOf);
    }

    function grantEmergencyWithdraw(address _lpaddress,address _user, bool _access) public onlyOwner {
         userInfo storage user =  users[_user][_lpaddress];
         user.emergencyWithdraw = _access;
    }
    
}