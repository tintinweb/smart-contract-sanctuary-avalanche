/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-29
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-28
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
 /*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }
    
    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

library SafeMathUpgradeable {
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


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract omh is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    uint256[] private schemeLevels;
    uint256 public valueAmount;
    IERC20 public omhToken;
    uint256 public rewardInterval;
    uint256 public releaseWeek;
    uint256 public totalPercentage;
    uint256 public lastReleasedTime;
    

    function initialize() public initializer {
        __Ownable_init();
        omhToken = IERC20(0x46C914D8f6b3e2044537611349b46a2ba35B8A58); //omh testnet token
        rewardInterval = 300; //reward claiming interval
    }

    receive() external payable {
      require(msg.sender == owner(), "Only owner can send fund.");
      require(block.timestamp.sub(lastReleasedTime) > rewardInterval, "current release is going on, try after sometimes.");
      uint256 oldBalance = address(this).balance.sub(msg.value);
      if(oldBalance!=0){
        payable(msg.sender).transfer(oldBalance);
      }
      releaseWeek = releaseWeek.add(1);
      valueAmount = address(this).balance;
      lastReleasedTime = block.timestamp;
      totalPercentage = 0;
      for(uint256 i = 0; i < schemeLevels.length; i++){
        schemeDetails[i].claimedCount = 0;
        totalPercentage = totalPercentage.add(schemeDetails[i].rewardPercentage);
      }
      individualMaxReward = getClaimableAmount(schemeLevels[0]);
    }

    struct UserStruct {
        string userName;
        address referrer;
        address[] referral;
        uint256 joinedTime;
        uint256[] transactions;
        uint256 lastClaimedTime;
        uint256 claimedRewards;
        bool isExist;
        bool isBlocked;
        uint256 lastClaimedWeek;
    }

    struct Transaction {
        uint256 claimedAmount;
        uint256 claimedTime;
        uint256 level;
        uint256 releasedAmount;
        uint256 releasedWeek;
        uint256 maxReward;
    }
    
    struct Scheme {
        uint256 schemeLevel;
        uint256 eligibleReferralCount;
        uint256 eligibleAmount;
        uint256 referralEligibleAmount;
        uint256 schemeLimit;
        uint256 rewardPercentage;
        uint256 claimedCount;
    }

    mapping (address => UserStruct) private userDetails;
    mapping (uint256 => Scheme) private schemeDetails;
    mapping (address => mapping(uint256 => Transaction)) private transactionDetails;

    struct TopNetworkLeader {
      address leaderAddress;
      uint256 omhBalance;
      uint256 referralCount;
      uint256 rewardClaimed;
    }

    uint256 public individualMaxReward;
    TopNetworkLeader public topNetworkLeader;
    
    function registerUser(string memory _userName, address _referrer) public{
     require(!userDetails[msg.sender].isExist,"User Already Exist.");
      _referrer = userDetails[_referrer].isExist ? _referrer : owner();
     require(userDetails[_referrer].isExist,"Referrer not found.");
     userDetails[msg.sender] = UserStruct({
      isExist : true,
      userName : _userName,
      referrer : _referrer,
      referral : new address[](0),
      joinedTime : block.timestamp,
      lastClaimedTime : block.timestamp,
      lastClaimedWeek : 0,
      claimedRewards : 0,
      transactions : new uint256[](0),
      isBlocked : false
     });
     userDetails[_referrer].referral.push(msg.sender);
   }

  function getUserLevel(address _user) public view returns (uint256){
     uint256 userLevel = 5; // last level
     uint256 userBalance = IERC20(omhToken).balanceOf(_user);
     for(uint256 i = 0; i<schemeLevels.length; i++){
      uint256 eligiblityCount = 0;
        if((userBalance >= schemeDetails[i].eligibleAmount) 
        && schemeDetails[i].claimedCount < schemeDetails[i].schemeLimit){
          for(uint256 j = 0; j<userDetails[_user].referral.length; j++){
            uint256 referralUserBalance = IERC20(omhToken).balanceOf(userDetails[_user].referral[j]);
            if((referralUserBalance >= schemeDetails[i].referralEligibleAmount)){
            eligiblityCount = eligiblityCount.add(1); 
            if(eligiblityCount >= schemeDetails[i].eligibleReferralCount){
              return i;
            }
          }
          }
        }
     }
     return userLevel;
  }


  function getClaimableAmount(uint256 _level) public view returns (uint256) {
    return (((valueAmount).mul(schemeDetails[_level].rewardPercentage)).div(totalPercentage)).div(schemeDetails[_level].schemeLimit);
  }

  function setTopNetworkLeader(address _user,uint256 _balance) private {
    topNetworkLeader.leaderAddress = _user;
    topNetworkLeader.omhBalance = _balance;
    topNetworkLeader.referralCount = userDetails[_user].referral.length;
    topNetworkLeader.rewardClaimed = userDetails[_user].claimedRewards;
  }

  function getTopNetworkLeader() public view returns (TopNetworkLeader memory) {
    return topNetworkLeader;
  }

   function claimReward() public {
     require(userDetails[msg.sender].isExist,"User not found.");
      require((userDetails[msg.sender].lastClaimedWeek != releaseWeek),"User already claimed, wait for next release.");
      //userLevel calculation
      uint256 userLevel = getUserLevel(msg.sender);
      require(!userDetails[msg.sender].isBlocked,"User is blocked.");
      //reward calculation based on level.
      uint256 calculatedAmount = getClaimableAmount(userLevel);
      require(calculatedAmount!=0,"You're not eligible to claim reward.");
      calculatedAmount = calculatedAmount > address(this).balance ? address(this).balance : calculatedAmount;
      //reward transfers
      payable(msg.sender).transfer(calculatedAmount);
      transactionDetails[msg.sender][releaseWeek] = Transaction({
        claimedAmount : calculatedAmount,
        claimedTime : block.timestamp,
        level : userLevel,
        releasedAmount : valueAmount,
        releasedWeek : releaseWeek,
        maxReward : individualMaxReward
      });
      schemeDetails[userLevel].claimedCount = schemeDetails[userLevel].claimedCount.add(1);
      userDetails[msg.sender].transactions.push(releaseWeek);
      userDetails[msg.sender].lastClaimedTime = block.timestamp;
      userDetails[msg.sender].lastClaimedWeek = releaseWeek;
      userDetails[msg.sender].claimedRewards = userDetails[msg.sender].claimedRewards.add(calculatedAmount);
      uint256 userOmhBalance = IERC20(omhToken).balanceOf(msg.sender);
      if(userLevel == schemeLevels[0] && 
      msg.sender != owner() && 
      userOmhBalance > topNetworkLeader.omhBalance){
        setTopNetworkLeader(msg.sender,userOmhBalance);
      }
    }

    function getSchemeData(uint256 _schemeLevel) public view returns (Scheme memory) {
        return schemeDetails[_schemeLevel];
    }

    function getUserInfo(address _user) public view returns (UserStruct memory) {
        return userDetails[_user];
    }

    function getSchemeLevels() public view returns (uint256[] memory) {
        return schemeLevels;
    }

    function getUserTransactions(address _user, uint256 _txId) public view returns (Transaction memory) {
        return transactionDetails[_user][_txId];
    }

//only owner
    function createSheme(
       uint256 _schemeLevel, 
       uint256 _eligibleReferralCount,
       uint256 _eligibleAmount,
       uint256 _schemeLimit,
       uint256 _rewardPercentage,
       uint256 _referralEligibleAmount ) public onlyOwner {
       schemeDetails[_schemeLevel] = Scheme({
           schemeLevel : _schemeLevel,
           eligibleReferralCount : _eligibleReferralCount,
           eligibleAmount : _eligibleAmount,
           referralEligibleAmount : _referralEligibleAmount,
           schemeLimit : _schemeLimit,
           rewardPercentage : _rewardPercentage,
           claimedCount : 0
       });
       schemeLevels.push(_schemeLevel);
   }

   function adminRegister(string memory _userName) public onlyOwner{
     require(!userDetails[msg.sender].isExist,"User Already Exist.");
     userDetails[msg.sender] = UserStruct({
      isExist : true,
      userName : _userName,
      referrer : msg.sender,
      referral : new address[](0),
      joinedTime : block.timestamp,
      lastClaimedTime : block.timestamp,
      lastClaimedWeek : 0,
      claimedRewards : 0,
      transactions : new uint256[](0),
      isBlocked : false
     });
   }

    function userSettings(address _address) public onlyOwner {
     userDetails[_address].isBlocked = !userDetails[_address].isBlocked;
   }

   function withdrawETH() public onlyOwner () {
     require(address(this).balance!=0,"No balance.");
     payable(msg.sender).transfer(address(this).balance);
   }

   function resetRelease() public onlyOwner () {
    totalPercentage = 0;
    valueAmount = address(this).balance;
    releaseWeek = 0;
   }

   function setRewardInteval(uint256 _interval) public onlyOwner {
      rewardInterval = _interval;
    }

}