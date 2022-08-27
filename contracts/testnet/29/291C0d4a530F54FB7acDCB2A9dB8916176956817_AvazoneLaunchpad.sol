// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./Library/SafeMath.sol";
import "./Library/Owned.sol";
import "./Library/ReentrancyGuard.sol";
import "./Interfaces/IToken.sol";
import "./Interfaces/IAvazoneStake.sol";
import "./Interfaces/IAvazoneIDOContract.sol";
import "./AvazoneIDOContract.sol";

contract AvazoneLaunchpad is Owned ,ReentrancyGuard{
    
    struct IDOinfo{
        address TokenContract;
        uint256 TokenDecimal;
        uint256 endDate;
        uint256 ratePerAvax;
        address recipient;
    }

    mapping(address => IDOinfo) public IdoInformations;
    mapping(uint256 => address) public IdoAddressList;
    mapping(address => address[]) private userJoinedIDOlist;
    mapping(address => mapping(address => bool)) public userContractBuyControl;
    address public stakeContract;

    uint256 public idoID = 0;
    
    constructor(address _stakeContract) public {
        stakeContract = _stakeContract;
    }

    function CreateIDO(address _token, uint256 _tokenDecimals, uint256 _tokenRatePerAvax, uint256 _endDate, address _recipient , uint256 _hardcap) public {
            AvazoneIDOContract IDO = new AvazoneIDOContract(
                _token,_tokenDecimals, _tokenRatePerAvax, _endDate,_recipient,address(this),stakeContract ,(_hardcap*10**18)
            );
            IdoInformations[address(IDO)] = IDOinfo(_token,_tokenDecimals,_endDate,_tokenRatePerAvax,_recipient);
            IdoAddressList[idoID] = address(IDO);
            idoID++;
     }


     function PresaleStart(address contractAddr) public onlyOwner{
         IAvazoneIDOContract(contractAddr).startPresale();
     }

     function setStakeContract(address _contract) public onlyOwner{
         require(_contract != address(0) ,"address cannot be zero address");
         stakeContract = _contract;
     }

     function PresaleClose(address contractAddr) public onlyOwner{
         IAvazoneIDOContract(contractAddr).closePrsale();
     }

     function setTokenDecimals(address contractAddr , uint256 _decimal) public onlyOwner{
         IdoInformations[contractAddr].TokenDecimal=_decimal;
         IAvazoneIDOContract(contractAddr).setTokenDecimals(_decimal);
     }


     function setTokenRatePerAvax(address contractAddr , uint256 _rate) public onlyOwner{
         IdoInformations[contractAddr].ratePerAvax=_rate;
         IAvazoneIDOContract(contractAddr).setTokenRatePerAvax(_rate);
     }

     function setRateDecimals(address contractAddr , uint256 _decimals) public onlyOwner{
         IAvazoneIDOContract(contractAddr).setRateDecimals(_decimals);
     }

     function withdrawAvax(address contractAddr) public onlyOwner{
         IAvazoneIDOContract(contractAddr).withdrawAvax();
     }

     function setWestingWithdrawDate(address contractAddr , uint256 _day1 , uint256 _day2 , uint256 _day3 , uint256 _day4) public onlyOwner{
         IAvazoneIDOContract(contractAddr).setWestingWithdrawDate(_day1, _day2,_day3,_day4);
     }

     function setEndDate(address contractAddr , uint256 _endDate) public onlyOwner{
         IAvazoneIDOContract(contractAddr).setEndDate(_endDate);
     }

     function setVestingPercent(address contractAddr , uint256 _Percent1,uint256 _Percent2,uint256 _Percent3,uint256 _Percent4) public onlyOwner{
         IAvazoneIDOContract(contractAddr).setVestingPercent(_Percent1,_Percent2,_Percent3,_Percent4);
     }

     function setLevelMultiplier(address contractAddr,uint256 _level1multiplier , uint256 _level2multiplier , uint256 _level3multiplier, uint256 _level4multiplier, uint256 _level5multiplier) public onlyOwner{
         IAvazoneIDOContract(contractAddr).setLevelMultiplier(_level1multiplier,_level2multiplier,_level3multiplier,_level4multiplier,_level5multiplier);
     }   

     function buyTokenIDO(address contractAddr) public payable{
          IAvazoneIDOContract(contractAddr).buyToken{value:msg.value}(msg.sender);

          if(userContractBuyControl[msg.sender][contractAddr] == false){
             userJoinedIDOlist[msg.sender].push(contractAddr);
          }
          userContractBuyControl[msg.sender][contractAddr] = true;
     }

     function getUserJoinedIDOLists(address _userAddress) public view returns (address[] memory IDlist){
            return userJoinedIDOlist[_userAddress];
     }
}

pragma solidity ^0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
*/

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

pragma solidity ^0.6.0;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.6.0;

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
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

pragma solidity ^0.6.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------


interface IToken {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burn(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}

pragma solidity ^0.6.0;

interface IAvazoneStake{
    function userTierLevel(address _wallet) external view returns (uint256); 
}

pragma solidity ^0.6.0;

interface IAvazoneIDOContract {
        function startPresale() external;
        function closePrsale() external;
        function setTokenDecimals(uint256 _decimal) external;
        function setTokenRatePerAvax(uint256 rate) external;
        function setRateDecimals(uint256 decimals) external;
        function setEndDate(uint256 _endDate) external;
        function buyToken(address wallet) external payable;
        function setVestingPercent(uint256 _vestingPercent1 , uint256 _vestingPercent2 , uint256 _vestingPercent3, uint256 _vestingPercent4) external;
        function setLevelMultiplier(uint256 _level1multiplier , uint256 _level2multiplier , uint256 _level3multiplier, uint256 _level4multiplier ,  uint256 _level5multiplier) external;
        function setWestingWithdrawDate(uint256 _day1, uint256 _day2, uint256 _day3 , uint256 _day4) external;
        function withdrawAvax() external;
}

pragma solidity ^0.6.0;

import "./Library/SafeMath.sol";
import "./Library/Owned.sol";
import "./Interfaces/IToken.sol";
import "./Interfaces/IAvazoneStake.sol";

contract AvazoneIDOContract is Owned {
    using SafeMath for uint256;
    
    bool public isPresaleOpen;
    
    //@dev ERC20 token address and decimals
    address public tokenAddress;
    uint256 public tokenDecimals;
    uint256 public totalSolded = 0;
    uint256 public endDate;
    address public routerAddr;
    address public stakeContract;
    uint256 public HardCap;
    
    //@dev amount of tokens per Avax 100 indicates 1 token per avax
    uint256 public tokenRatePerAvax;
    //@dev decimal for tokenRatePerAvax,
    //2 means if you want 100 tokens per avax then set the rate as 100 + number of rateDecimals i.e => 10000
    uint256 public rateDecimals = 0;

    
    address public recipient;
    bool public refundActive = false;
    uint256 public refundCommissionPercent= 5;

    mapping(address=>uint256) public userAvaxLimit;
    mapping(address=>uint256) public userAvaxBalance;

    struct VestingPlan{
       uint256 totalBalance;
       uint256 aviableBalance;
       uint256 timeStage;
    }

    mapping(address=>VestingPlan) public vestingBalance;

    uint256 Day = 1 days;

    // Withdraw Times
    uint256[] public WestingWithdrawDate = [30,60,90,120];

    // Vesting Percents
    uint256[] public WestingPercents = [25,25,25,25];

    // level multipliers
    uint256[] public LevelMultipliers = [10,25,55,45,55];

   
    constructor(address _token,
     uint256 _tokenDecimals, 
     uint256 _tokenRatePerAvax, 
     uint256 _endDate, 
     address _recipient , 
     address _routerAddr,
     address _stakeContract,
     uint256 _HardCap
     ) public {
        tokenAddress = _token;
        tokenDecimals = _tokenDecimals;
        tokenRatePerAvax = _tokenRatePerAvax;
        endDate = _endDate;
        recipient = _recipient;
        routerAddr =_routerAddr;
        stakeContract = _stakeContract;
        HardCap = _HardCap;
    }

    function name() public view returns(string memory){
        return IToken(tokenAddress).name();
    }

    function symbol() public view returns(string memory){
        return IToken(tokenAddress).symbol();
    }

     function decimal() public view returns(uint8){
        return IToken(tokenAddress).decimals();
    }

    function totalSupply() public view returns(uint256){
        return IToken(tokenAddress).totalSupply();
    }
     
    function startPresale() external onlyOwner {
        require(!isPresaleOpen, "Presale is open");
        isPresaleOpen = true;
    }

    function LevelLimit(uint256 level) public view returns (uint256){
        if(level == 0){
           return 0;
        } else if(level == 1){
            return  (HardCap * LevelMultipliers[0]) / 100;
        }
        else if(level == 2){
            return  (HardCap * LevelMultipliers[1]) / 100;
        }
        else if(level == 3){
            return  (HardCap * LevelMultipliers[2]) / 100;
        }
        else if(level == 4){
            return  (HardCap * LevelMultipliers[3]) / 100;
        }
        else if(level == 5){
            return  (HardCap * LevelMultipliers[4]) / 100;
        }
        else{
            return 0;
        }
    }
    
    
    function closePrsale() external onlyOwner {
        require(isPresaleOpen, "Presale is not open yet.");
        isPresaleOpen = false;
    }
    
    function setTokenDecimals(uint256 decimals) external onlyOwner {
       tokenDecimals = decimals;
    }

    function setVestingPercent(uint256 _vestingPercent1 , uint256 _vestingPercent2 , uint256 _vestingPercent3, uint256 _vestingPercent4) external onlyOwner {
        require(_vestingPercent1 + _vestingPercent2 + _vestingPercent3 + _vestingPercent4 == 100,"Total should be 100");
         WestingPercents[0] = _vestingPercent1;
         WestingPercents[1] = _vestingPercent2;
         WestingPercents[2] = _vestingPercent3;
         WestingPercents[3] = _vestingPercent4;
    }

     
    function setWestingWithdrawDate(uint256 _day1, uint256 _day2, uint256 _day3 , uint256 _day4) external onlyOwner{
        require(_day1<_day2 && _day2<_day3 && _day3<_day4,"Day edit error");
        WestingWithdrawDate[0] = _day1;
        WestingWithdrawDate[1] = _day2;
        WestingWithdrawDate[2] = _day3;
        WestingWithdrawDate[3] = _day4;
    }

    function setLevelMultiplier(uint256 _level1multiplier , uint256 _level2multiplier , uint256 _level3multiplier, uint256 _level4multiplier ,  uint256 _level5multiplier) external onlyOwner {
         LevelMultipliers[0] = _level1multiplier;
         LevelMultipliers[1] = _level2multiplier;
         LevelMultipliers[2] = _level3multiplier;
         LevelMultipliers[3] = _level4multiplier;
         LevelMultipliers[4] = _level5multiplier;
    }
    
    function setTokenRatePerAvax(uint256 rate) external onlyOwner {
        tokenRatePerAvax = rate;
    }

    function setEndDate(uint256 _endDate) external onlyOwner {
        endDate = _endDate;
    }
    
    function setRateDecimals(uint256 decimals) external onlyOwner {
        rateDecimals = decimals;
    }
    
    function buyToken(address wallet) public payable {
        require(msg.sender == routerAddr ,"Only Router Address!");
        require(msg.sender != address(0) ,"zero address cannot be used");
        require(isPresaleOpen, "Presale is not open.");
        require(msg.value>0,"value must be greater than 0");
        require(block.timestamp<endDate,"The purchase cannot be made because the sale period has expired.");

        uint256 userTierLevel = IAvazoneStake(stakeContract).userTierLevel(wallet);
        uint256 limit = LevelLimit(userTierLevel);
         
        require(limit>0,"You do not have the right to buy. You must be at least Level 1");
        require(userAvaxLimit[wallet]<=limit,"You cannot buy more.");

        userAvaxLimit[wallet] = userAvaxLimit[wallet] + msg.value;
        userAvaxBalance[wallet] = userAvaxBalance[wallet]+ msg.value;

        //@dev calculate the amount of tokens to transfer for the given avax
         uint256 tokenAmount = getTokensPerAvax(msg.value);

          vestingBalance[wallet].totalBalance = vestingBalance[wallet].totalBalance + tokenAmount;
          vestingBalance[wallet].aviableBalance = vestingBalance[wallet].aviableBalance + tokenAmount;
          totalSolded = totalSolded + msg.value;
    }

    function withdrawAvax() external onlyOwner{
        uint256 balance = address(this).balance;
        require(balance>0,"No avax");
        payable(recipient).transfer(balance);
    }

    function refundUserAvaxBalance() external {
        require(refundActive,"Refund Not Active");
        require(userAvaxBalance[msg.sender]>0,"You not have Avax");
        uint256 userBalance = userAvaxBalance[msg.sender];
        uint256 commision = (userBalance * refundCommissionPercent) / 100;
        uint256 sendBalance = userBalance - commision;
        payable(msg.sender).transfer(sendBalance);
        userAvaxBalance[msg.sender] = 0;
    }


    function withdrawToken() public {
        require(block.timestamp>endDate,"You cannot withdraw because the sale period has not expired.");
        require(vestingBalance[msg.sender].aviableBalance > 0, "You do not have any tokens to withdraw.");
        require(vestingBalance[msg.sender].timeStage <= 4 ,"All stages have been completed.");

        uint256 userAmount = vestingBalance[msg.sender].totalBalance;
        require(block.timestamp>WithdrawVestingTime(vestingBalance[msg.sender].timeStage),"It's not time to withdraw");
        uint256 withdrawAmount = (userAmount * WithdrawVestingPercent(vestingBalance[msg.sender].timeStage)) / 100;
        vestingBalance[msg.sender].aviableBalance = vestingBalance[msg.sender].aviableBalance - withdrawAmount;
        vestingBalance[msg.sender].timeStage = vestingBalance[msg.sender].timeStage + 1;
        if(vestingBalance[msg.sender].timeStage == 4){
            vestingBalance[msg.sender].aviableBalance = 0;
        }
        
        require(IToken(tokenAddress).transfer(msg.sender, withdrawAmount), "Insufficient balance of this contract!");
    }

    function WithdrawVestingTime(uint256 _stage) public view returns(uint256){
        require(_stage>=0 && _stage<=3,"Error");
        return endDate + (WestingWithdrawDate[_stage] * Day);
    }

    function WithdrawVestingPercent(uint256 _stage) public view returns(uint256){
        require(_stage>=0 && _stage<=3,"Error");
           return WestingPercents[_stage];
    }


    function userTimeStageTimeStamp(address _wallet) public view returns(uint256){
        return WestingWithdrawDate[vestingBalance[_wallet].timeStage];
    }

    function getTokensPerAvax(uint256 amount) internal view returns(uint256) {
        return amount.mul(tokenRatePerAvax).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }
    
    function burnUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot burn tokens untitl the presale is closed.");
        
        IToken(tokenAddress).transfer(0x000000000000000000000000000000000000dEaD,IToken(tokenAddress).balanceOf(address(this)));
    }
    
    function getUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        IToken(tokenAddress).transfer(recipient, IToken(tokenAddress).balanceOf(address(this)));
    }
}