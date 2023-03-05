/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
 
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


interface IERC20 {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burn(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint amount) external returns (bool);
}

interface ILaunchpadSale {
    function transferOwnership(address newOwner) external;
    function getOwner() external view returns(address);
    function getHardcap() external view returns(uint256);
    function getTokenRatePerEth() external view returns(uint256);
    function getPoolPercent() external view returns(uint256);
    function getTokenDecimals() external view returns(uint256);
    function getTokenAddress() external view returns(address);
    function getListRate() external view returns(uint256);
}

interface IUniswapV2Router {

     function factory() external pure returns (address);
     function WAVAX() external pure returns (address);

     function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);


    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


contract LaunchpadUserContractCreator is Owned , ReentrancyGuard{

    using SafeMath for uint256;
 
    mapping(address => uint256[]) private userCreatedContractList;
    mapping(uint256 => address) public createdPools;
    mapping(address => uint256) public userCreatePoolCount;

    mapping(address => bool) public isPair;
    
    address public bankAddress;

    uint256 public createPrice = 0.01 ether;
    uint256 public createStandartTokenPrice = 1 ether;
    uint256 public poolID = 0;
    uint256 public PacketID = 0;


    struct SalePackets{
        uint256 price;
        uint256 count;
    }

    mapping(uint256 => SalePackets) public Packets;

    //events
    event CreatePresale(address indexed _creator, address _launchAddr);
    

    constructor() public {
         bankAddress = msg.sender;
    }

    function addPacket(uint256 price , uint256 count) external nonReentrant onlyOwner{
        Packets[PacketID] = SalePackets(price,count);
        PacketID++;
    }

    function createToken(string memory name , string memory symbol , uint8 decimal , uint256 totalSupply) public payable returns(address){
        require(msg.value==createStandartTokenPrice,"False Balance");
        uint256 supply = totalSupply * 10 ** uint256(decimal);
        LaunchStandartToken standartToken = new LaunchStandartToken(msg.sender,name,symbol,decimal,supply);
        standartToken.transferOwnership(msg.sender);
        payable(bankAddress).transfer(msg.value);
        return address(standartToken);
    }

    function buyPacket(uint256 _packetID) external payable{

        uint256 packetPrice = Packets[_packetID].price;
        require(msg.value == packetPrice,"package price does not match.");
        uint256 packetCount = Packets[_packetID].count;
        userCreatePoolCount[msg.sender].add(packetCount);
        payable(bankAddress).transfer(msg.value);
    }

    function createPresale(
        address _token,
        string memory _tokenimageURL,
        string memory _websiteURL,
        uint256 _tokenDecimals,
        uint256 _tokenRatePerEth,
        uint256 _minEthLimit,
        uint256 _maxEthLimit,
        uint256 _StartDate,
        uint256 _EndDate,
        uint256 _HardCap,
        uint256 _Softcap,
        uint256 _poolPercent,
        uint256 _listRate,
        bool _isPrivate
    ) external payable {
  
        uint256 userPoolCount = userCreatePoolCount[msg.sender];
        address token = _token;
        string memory image = _tokenimageURL;
        string memory weburl = _websiteURL;
        
        if(userPoolCount>0){
            require(msg.value == 0 ,"You don't need to send money. because you bought a pack");
            userCreatePoolCount[msg.sender].sub(1);
        }else{
            require(msg.value == createPrice,"Invalid fee");
        }

         uint256[] memory _intArgs = new uint256[](10);
        
         _intArgs[0] = _tokenDecimals;
         _intArgs[1] = _tokenRatePerEth;
         _intArgs[2] = _minEthLimit;
         _intArgs[3] = _maxEthLimit;
         _intArgs[4] = _StartDate;
         _intArgs[5] = _EndDate;
         _intArgs[6] = _HardCap;
         _intArgs[7] = _Softcap;
         _intArgs[8] = _poolPercent;
         _intArgs[9] = _listRate;

         LaunchpadSale launchpad = new LaunchpadSale(token, _intArgs, bankAddress, image, weburl, _isPrivate);

         createdPools[poolID] = address(launchpad);
         userCreatedContractList[msg.sender].push(poolID);
        
         ILaunchpadSale(address(launchpad)).transferOwnership(msg.sender);
         poolID++;

         isPair[address(launchpad)] = true;
         
         payable(bankAddress).transfer(msg.value);

         emit CreatePresale(msg.sender,address(launchpad));
    }


    function setCreatePrice(uint256 _price) external onlyOwner{
        createPrice = _price;
    }

    function setBankAddress(address _bank) external onlyOwner{
        bankAddress = _bank;
    }

    function getuserCreatedContractList(address _wallet) public view returns (uint256[] memory){
        return userCreatedContractList[_wallet];
    }
}

contract LaunchpadSale is Owned,ReentrancyGuard {
    using SafeMath for uint256;

    address private constant FACTORY = 0xF5c7d9733e5f53abCC1695820c4818C59B457C2C;
    address private constant ROUTER = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;
     
    //@dev ERC20 token address and decimals
    address public tokenAddress;
    uint256 public tokenDecimals;
    uint256 public totalSolded = 0;
    
    //@dev amount of tokens per ether 100 indicates 1 token per eth
    uint256 public tokenRatePerEth;
    //@dev decimal for tokenRatePerEth,
    //2 means if you want 100 tokens per eth then set the rate as 100 + number of rateDecimals i.e => 10000
    uint256 public rateDecimals = 0;
    
    //@dev max and min token buy limit per account
    uint256 public minEthLimit;
    uint256 public maxEthLimit;

    uint256 public StartDate;
    uint256 public EndDate;

    uint256 public HardCap;
    uint256 public Softcap;

    uint256 public poolPercent;
    uint256 public listRate;
    uint256 public commisionPercent = 3;

    string public image;
    string public weburl;

    bool public AutoOrManuelLiq; // true => auto , false => manuel 
    bool public burnOrRefund; // true => burn , false => refund

    struct VestingPlan{
       uint256 totalBalance;
       uint256 aviableBalance;
       uint256 timeStage;
    }

    bool public needStageActive = true;

    bool public isPrivate;
    bool public isPoolClosed = false;

    mapping(address => bool) public Whitelist;

    mapping(address=>VestingPlan) public vestingBalance;

    // Withdraw Times
    uint256[] public WestingWithdrawDate;

    // Vesting Percents
    uint256[] public WestingPercents;
      
    mapping(address => uint256) public usersInvestments;
    mapping(address => uint256) public userbnbBalance;

    address public bankAddr;
    address public pairAddr;

    IUniswapV2Router router = IUniswapV2Router(ROUTER);
    IUniswapV2Factory factory = IUniswapV2Factory(FACTORY);

    // events
     event TokenNeedStageEvent(address indexed _creator, address _launchAddr , uint256 _amount);
    
    constructor(
         address _token,
         uint256[] memory _intargs,
         address _bankAddr,
         string memory _image,
         string memory _weburl,
         bool _isPrivate
          
    ) public {
         tokenAddress = _token;
         tokenDecimals = _intargs[0];
         tokenRatePerEth = _intargs[1];
         minEthLimit = _intargs[2];
         maxEthLimit = _intargs[3];
         StartDate = _intargs[4];
         EndDate = _intargs[5];
         HardCap = _intargs[6];
         Softcap = _intargs[7];
         listRate = _intargs[9];
         isPrivate = _isPrivate;
         poolPercent = _intargs[8];
         bankAddr = _bankAddr;
         image = _image;
         weburl = _weburl;

        require(poolPercent >= 40 && poolPercent<=90 ,"The percentage can be between 40 and 90 percent.");
        require(Softcap >=  ((HardCap / 2)) ,"Softcap must be equal to or greater than half of the hardcap.");
        require(HardCap > Softcap ,"Softcap cannot be greater than hardcap.");
        require(minEthLimit < maxEthLimit,"The minimum purchase must be less than the maximum purchase.");
        require(StartDate<EndDate,"The start time cannot be greater than the end time.");
    }


    function getInfo() public view returns(uint256[] memory, bool[] memory, address, string memory,string memory,string memory,string memory) {
        
        // The stack deep error was fixed in this way.

        uint256[] memory intArgs = new uint256[](12);
        intArgs[0] = decimal();
        intArgs[1] = HardCap;
        intArgs[2] = Softcap;
        intArgs[3] = maxEthLimit;
        intArgs[4] = minEthLimit;
        intArgs[5] = StartDate;
        intArgs[6] = EndDate;
        intArgs[7] = poolPercent;
        intArgs[8] = listRate;
        intArgs[9] = tokenRatePerEth;
        intArgs[10] = needTokenBalance();
        intArgs[11] = totalSolded;

        bool[] memory boolArgs = new bool[](3);
        boolArgs[0] = isPrivate;

        if(WestingPercents.length == 0 && needStageActive == true){
            boolArgs[1] = false;
        }else{
            boolArgs[1] = true;
        }

        boolArgs[2] = needStageActive;

        string memory poolStatus;

        if(totalSolded >= (HardCap*1e18)){
            poolStatus = "ended";
         }else{
             if(block.timestamp>StartDate && block.timestamp<EndDate){
            poolStatus = "active";
            }else if(block.timestamp<StartDate){
                poolStatus = "upcoming";
            }else if(EndDate < block.timestamp){
                if(totalSolded < (Softcap*1e18)){
                    poolStatus = "refunded";
                }else{
                    poolStatus = "ended";
                }
            }
         }        
  
        string memory name = name();
        string memory symbol = symbol();
        string memory Tokenimage = image;
        address tokenaddr = tokenAddress;

        return(intArgs,boolArgs,tokenaddr,poolStatus,name,symbol,Tokenimage);
    }

    function name() public view returns(string memory){
        return IERC20(tokenAddress).name();
    }

    function symbol() public view returns(string memory){
        return IERC20(tokenAddress).symbol();
    }

     function decimal() public view returns(uint8){
        return IERC20(tokenAddress).decimals();
    }

    function totalSupply() public view returns(uint256){
        return IERC20(tokenAddress).totalSupply();
    }
  
    function addForWhitelistAddress(address _address) external onlyOwner {
        require(isPrivate,"This pool is open to everyone");
        Whitelist[_address] = true;
    }

    function addForWhitelistAddressMulti(address[] memory _address) external onlyOwner {
        require(isPrivate,"This pool is open to everyone");
        for(uint256 a = 0; a < _address.length; a++){
            Whitelist[_address[a]] = true;
        }
    }

    function refundBNB() external nonReentrant{
       require(block.timestamp > EndDate && totalSolded < Softcap ,"");
       uint256 userbalance = userbnbBalance[msg.sender];
       require(userbalance>0 ,"balance must be greater than 0");
       userbnbBalance[msg.sender] = 0;
       payable(msg.sender).transfer(userbalance);
       
    }

    function closePool() external onlyOwner{

        if((HardCap * 1e18) != totalSolded){
            require(block.timestamp>EndDate,"The sale is not over.");
        }
         require(isPoolClosed == false ,"Pool is Closed");
         require(totalSolded > (Softcap * 1e18) , "The sale is not considered valid because it did not pass the softcapt.");
        
         uint256 Totalbalance = address(this).balance;
         uint256 liqBalance = (Totalbalance*poolPercent) / 100;
         uint256 commisionBalance = (Totalbalance*commisionPercent) / 100;
         uint256 availableBalance = Totalbalance.sub(liqBalance).sub(commisionBalance);

         uint256 liqtokenAmount = getTokensPerEthList(liqBalance);

         uint256 aviableToken = IERC20(tokenAddress).balanceOf(address(this)).sub(liqtokenAmount).sub(getTokensPerEth(totalSolded));

        if(AutoOrManuelLiq){
            IERC20(tokenAddress).approve(address(ROUTER), liqtokenAmount);
            router.addLiquidityAVAX{value: liqBalance}(
                tokenAddress,
                liqtokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner,
                block.timestamp
            );

              payable(owner).transfer(availableBalance);
              payable(bankAddr).transfer(commisionBalance);
        }else{
            IERC20(tokenAddress).transfer(owner, liqtokenAmount);
            payable(owner).transfer(liqBalance.add(availableBalance));
            payable(bankAddr).transfer(commisionBalance);
        }

         if(aviableToken != 0){
             if(burnOrRefund){
                IERC20(tokenAddress).transfer(0x000000000000000000000000000000000000dEaD,aviableToken);
             }else{
                IERC20(tokenAddress).transfer(owner,aviableToken);
             }
         }
        
         isPoolClosed = true;
    }

    function setWithdrawSettings(uint256[] memory _times ,  uint256[] memory _percents) external {
            require(_times.length == _percents.length, "The number of days and percentages must be equal");

            delete WestingWithdrawDate;
            delete WestingPercents;

            uint256 percentTotal;
            for(uint256 a = 0; a < _percents.length; a++){
                percentTotal = percentTotal + _percents[a];
                WestingWithdrawDate.push(_times[a]);
                WestingPercents.push(_percents[a]);
            }
            require(percentTotal == 100 ,"Percent should be 100");
    }


    function buyToken() public payable{
        
        require(
                usersInvestments[msg.sender].add(msg.value) <= maxEthLimit
                && usersInvestments[msg.sender].add(msg.value) >= minEthLimit,
                "Installment Invalid."
            );
        require(block.timestamp > StartDate && block.timestamp < EndDate , "The purchase cannot be made because the sale period has expired.");
        require(totalSolded.add(msg.value) <= (HardCap*1e18), "The sale is complete.");

        if(isPrivate){
            require(Whitelist[msg.sender],"You cannot participate in the private sale");
        }

        //@dev calculate the amount of tokens to transfer for the given Bnb
         uint256 tokenAmount = getTokensPerEth(msg.value);

          vestingBalance[msg.sender].totalBalance = vestingBalance[msg.sender].totalBalance + tokenAmount;
          vestingBalance[msg.sender].aviableBalance = vestingBalance[msg.sender].aviableBalance + tokenAmount;
          userbnbBalance[msg.sender] = userbnbBalance[msg.sender].add(msg.value);
          totalSolded = totalSolded + msg.value;
    }


    function withdrawToken() public {
        require(block.timestamp>EndDate,"You cannot withdraw because the sale period has not expired.");
        require(vestingBalance[msg.sender].aviableBalance > 0, "You do not have any tokens to withdraw.");
        require(vestingBalance[msg.sender].timeStage <= WestingWithdrawDate.length ,"All stages have been completed.");

        uint256 userAmount = vestingBalance[msg.sender].totalBalance;
        require(block.timestamp>WithdrawVestingTime(vestingBalance[msg.sender].timeStage),"It's not time to withdraw");
        uint256 withdrawAmount = (userAmount * WithdrawVestingPercent(vestingBalance[msg.sender].timeStage)) / 100;
        vestingBalance[msg.sender].aviableBalance = vestingBalance[msg.sender].aviableBalance - withdrawAmount;
        vestingBalance[msg.sender].timeStage = vestingBalance[msg.sender].timeStage + 1;
        if(vestingBalance[msg.sender].timeStage == WestingWithdrawDate.length){
            vestingBalance[msg.sender].aviableBalance = 0;
        }
        
        require(IERC20(tokenAddress).transfer(msg.sender, withdrawAmount), "Insufficient balance of this contract!");
    }

    function needTokenBalance() public view returns(uint256){
        return sendToTokenNeed(tokenRatePerEth,HardCap,poolPercent,tokenDecimals,listRate);
    }

    function tokenNeedStage(bool _autoOrmanuel, bool _burnOrRefund) external onlyOwner{

         require(needStageActive,"you have done this.");
         uint256 needToken = sendToTokenNeed(tokenRatePerEth,HardCap,poolPercent,tokenDecimals,listRate);

         IERC20(tokenAddress).transferFrom(msg.sender, address(this), needToken);

         AutoOrManuelLiq = _autoOrmanuel;
         burnOrRefund = _burnOrRefund;

         if(_autoOrmanuel){
             if(factory.getPair(tokenAddress,router.WAVAX()) == address(0) ){
                 pairAddr = factory.createPair(tokenAddress, router.WAVAX());
             }else{
                 pairAddr = factory.getPair(tokenAddress,router.WAVAX());
             }
         }

         needStageActive = false;

         emit TokenNeedStageEvent(msg.sender,address(this), needToken);
     }

     function setTokenIcon(string memory _iconURL) external onlyOwner {
         image = _iconURL;
     }

     function setWeburlIcon(string memory _weburl) external onlyOwner {
         weburl = _weburl;
     }

    function WithdrawVestingTime(uint256 _stage) public view returns(uint256){
        require(_stage>=0 && _stage<=WestingWithdrawDate.length,"Error");
        return WestingWithdrawDate[_stage];
    }

    function getWestingWithdrawDate() public view returns( uint256 [] memory){
         return WestingWithdrawDate;
    }   

    function getWestingPercents() public view returns( uint256 [] memory){
         return WestingPercents;
    }

    // internal functions

    function sendToTokenNeed(uint256 _tokenRatePerEth, uint256 _HardCap, uint256 _poolPercent, uint256 _decimal, uint256 _listRate) internal pure returns (uint256) {
         uint256 hardCap = _HardCap* 1e18;
         uint256 needSoldToken = (hardCap * _tokenRatePerEth);
         uint256 needPool = ((hardCap * _poolPercent / 100) * _listRate);
         uint256 TotalToken = needSoldToken + needPool;
         return TotalToken;
     }

    function WithdrawVestingPercent(uint256 _stage) internal view returns(uint256){
        require(_stage>=0 && _stage<=WestingPercents.length,"Error");
           return WestingPercents[_stage];
    }
    
    function getTokensPerEth(uint256 amount) internal view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }

    function getTokensPerEthList(uint256 amount) internal view returns(uint256) {
        return amount.mul(listRate).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }
}



interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract Context {
 
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

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

library SafeMath {
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
 
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }
 
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract LaunchStandartToken is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(address _owner,string memory name, string memory symbol, uint8 decimal , uint256 totalSupply) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimal;
    _totalSupply = totalSupply;
    _balances[_owner] = _totalSupply;

    emit Transfer(address(0), _owner, _totalSupply);
  }

  function getOwner() external override view returns (address) {
    return owner();
  }

  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  function name() external override view returns (string memory) {
    return _name;
  }

  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}