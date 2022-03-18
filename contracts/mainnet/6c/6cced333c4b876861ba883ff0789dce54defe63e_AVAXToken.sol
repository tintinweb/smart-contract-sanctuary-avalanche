/**
 *Submitted for verification at snowtrace.io on 2022-03-17
*/

// File: contracts/ANTC.sol

pragma solidity 0.5.16;

interface AVAX {
  
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
    this; 
    return msg.data;
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
    require(b > 0, errorMessage);
    uint256 c = a / b;
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


contract Ownable is Context {
  address payable   _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    address payable msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view  returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
  

  
  /*function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }*/

  
  function transferOwnership(address payable newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  
  function _transferOwnership(address payable newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract AVAXToken is Context, AVAX, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor() public {
    _name = "Ant Network";
    _symbol = "ANTc";
    _decimals = 18;
    _totalSupply = 100000000*10**18;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  
  function getOwner() external view returns (address) {
    return owner();
  }

 
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

 
  function name() external view returns (string memory) {return _name;}

  function totalSupply() external view returns (uint256) {return _totalSupply;}

  function balanceOf(address account) external view returns (uint256) {return _balances[account];}
  

  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

 
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()]
    .sub(amount, "AVAX: transfer amount exceeds allowance"));
    return true;
  }

 
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender]
    .sub(subtractedValue, "AVAX: decreased allowance below zero"));
    return true;
  }

 
  function mint(uint256 _amountMint) public onlyOwner returns (bool) {
    _amountMint = _amountMint*10**18;
    _mint(_msgSender(), _amountMint);
    return true;
  }

  
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "AVAX: transfer from the zero address");
    require(recipient != address(0), "AVAX: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "AVAX: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

 
  function _mint(address account, uint256 _amountMint) internal {
    require(account != address(0), "AVAX: mint to the zero address");

    _totalSupply = _totalSupply.add(_amountMint);
    _balances[account] = _balances[account].add(_amountMint);
    emit Transfer(address(0), account, _amountMint);
  }

  
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "approve from the zero address");
    require(spender != address(0), "approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

 
  
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }


  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount,"AVAX: burn amount exceeds allowance"));
  }
  


    event TokenBurn(address indexed from, uint256 amount);
    
    function burnToken(uint256 amountBurn) external {
        
        address from = msg.sender;
        require(amountBurn>0);
        require(_balances[from]>amountBurn,"Insufficient coin count");
        
        _balances[from]=  _balances[from]-amountBurn;
        _totalSupply = _totalSupply - amountBurn;
        emit TokenBurn(from,amountBurn);
        
    }
  
    event WithdrawRequest(address indexed from, address indexed to, uint256 value,string userID,uint time);
    
    mapping (address => string) private _addressToUserID;
    mapping (string => uint256) private _stringToBalances;
    
    //uint amount  =  1*10**18;
    uint limit = 20000;
    uint transactionFee=1000000000000000;

   
    function withdrawRequest(uint withdrawAmounts, string calldata _userID,uint time) external payable{
        
        require(msg.value >transactionFee,"Transaction Fee Very Low");
        require(withdrawAmounts < limit,"Withdraw Limit Exceeded");
        require(msg.sender != address(0), "sender is the zero address");

        string memory userID = _userID;
        
        address recipient = msg.sender;
        uint amountToSend = withdrawAmounts*10**18;
        
        _balances[_owner] = _balances[_owner].sub(amountToSend, "transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amountToSend);

        _addressToUserID[recipient] = userID;

        emit Transfer(_owner, recipient, amountToSend);
        emit WithdrawRequest(_owner,recipient,amountToSend,userID,time);
           
    }
  
    function getUserIDfromAddress(address account) external view returns (string memory) {return _addressToUserID[account];}

  
    function setWithdrawLimit(uint _newLimit) public onlyOwner{
      limit = _newLimit;
    }
    
    
    function getWithdrawLimit()  external view returns (uint) {
        return limit;
    }
    

    
    function getTransactionFee()  external  view returns (uint) {
        return transactionFee;
    }
   
    function setTransactionFee(uint _newFee) public onlyOwner {
      transactionFee = _newFee;
    }
 
    function withdraw()  external onlyOwner {
        address(_owner).transfer(address(this).balance);
    }
 
 
  
    function getMsgSender() external view returns (address) {
       
        return address(msg.sender);
    
    }

 
  
    function getBalanceContract() external view returns (uint) {
       
        return address(this).balance;
    
    }

    uint totalStake = 1000000 * 10 **18;
    uint currentStake = 0;
    uint maxCurrentStake = 10000000*10**18;
    uint minStake = 1000 * 10 ** 18;
    uint maxStake = 50000 * 10 ** 18;
    uint256 stakeRate = 1000;
   
    uint stakeTransactionFee = 500000000000000;

    mapping(uint256 => address) private timeToAddress;
    mapping(uint256 => string ) private timeToID;     
    mapping(uint256 => uint256 ) private timeToStake;  
    mapping(uint256 => uint256 ) private timeToStakeRate; 

    event Staked(address indexed from, uint256 value, uint256 timestamp, string ID, uint stakeRate);
    
    function addStake(uint256 _amountStake,string calldata ID)  external payable returns (bool)  {
      address from = msg.sender;
      uint256 timestamp = block.timestamp;
      uint256 amountStake = _amountStake * 10**18;

      require(StakeStatus==true,"Stake Off");
      require(_balances[from] >= amountStake, "Insufficient Coin Count");
      require(currentStake<= maxCurrentStake,"Maximum current stake exceeded");
      require(msg.value >=stakeTransactionFee,"Transaction Fee Very Low");
      require(amountStake >= minStake, "Amount Stake Low");
      require(amountStake<=maxStake, "Stakes Limit Exceeded");
     
      //Current Staking Update
      currentStake += amountStake;

    
      timeToAddress[timestamp]=from;
      timeToID[timestamp] = ID;
      timeToStake[timestamp] = amountStake;
      timeToStakeRate[timestamp] = stakeRate;

      _balances[from]=  _balances[from] - amountStake;
      _totalSupply = _totalSupply - amountStake;

      emit Staked(from,amountStake,timestamp,ID,stakeRate);
      emit Transfer(from, address(0), amountStake);

      return true;
     }


    event Claim(address indexed from, uint256 amount, uint256 timestamp,string ID, uint256 nowTime ,uint256 diffTime,uint256 mod,uint division);
   

    
    function claim(uint256 _timestamp,string calldata  ID) external payable returns (bool)  {
      
      address from = msg.sender;
      require(msg.value >=(stakeTransactionFee),"Transaction Fee Very Low");
      require(timeToAddress[_timestamp]==from,"Address did not match Time");
      require (keccak256(abi.encodePacked(timeToID[_timestamp])) == keccak256(abi.encodePacked(ID)),"ID did not match Time");
 
      uint256 fromStake =  timeToStake[_timestamp];
      uint256 stakeRateFromTime = timeToStakeRate [_timestamp];

      uint256 nowTime = block.timestamp;
      uint256 diffTime = nowTime - _timestamp;
      uint256 oneDay =24*60*60;
      uint256 mod = diffTime% oneDay;
      diffTime -= mod;

      uint division = diffTime/oneDay;
    
      uint256 claimFromStake = (fromStake/stakeRateFromTime)*(division);
      _balances[from]=  _balances[from] + claimFromStake + fromStake;
       _totalSupply = _totalSupply + claimFromStake +fromStake;

      //Reset Process
      timeToStake[_timestamp] = 0;

      //Current Staking Update
      currentStake -= fromStake;

      emit Transfer(address(0), from, claimFromStake+fromStake);
      emit Claim(from,claimFromStake+fromStake,_timestamp,ID,   nowTime,diffTime,mod,division);
       
      return true;
    }

    
    function getStakeRateFromTime(uint _timestamp)  external  view returns (uint256) {
        return timeToStakeRate[_timestamp];
    }

    

    function getStakeRate()  external  view returns (uint) {
        return stakeRate;
    }
   
    function setStakeRate(uint _newRate) public onlyOwner {
        stakeRate = _newRate;
    }

  
    function getUserStakeStatus(uint _timestamp) external view returns (uint) {
      return timeToStake[_timestamp];
    }



    function getStakeTransactionFee()  external  view returns (uint) {
        return stakeTransactionFee;
    }
   
    function setStakeTransactionFee(uint _newFee) public onlyOwner {
        stakeTransactionFee = _newFee;
    }



    function getMaxStake()  external  view returns (uint) {
        return maxStake;
    }
   
    function setMaxStake(uint _maxStake) public onlyOwner {
        maxStake = _maxStake*10**18;
    }



    function getCurrentStake()  external  view returns (uint) {
        return currentStake;
    }
   
    function setMaxCurrentStake(uint _maxCurrentStake) public onlyOwner {
        maxCurrentStake = _maxCurrentStake*10**18;
    }

    function getMaxCurrentStake()  external  view returns (uint) {
        return maxCurrentStake;
    }


    bool StakeStatus = true;
    //- Stake Status Change
    function StakeStatusChange(bool _state) public onlyOwner returns(bool) {
        if (StakeStatus == _state) revert("Stake Status No Change!");
        StakeStatus = _state;
        return true;
    }

    function getStakeStatus()  external  view returns (bool) {
        return StakeStatus;
    }



    function transferFromTo(address _from, address _to , uint _amounts) public onlyOwner returns (bool){
        require(_from != address(0), "AVAX: zero address");
        require(_to != address(0), "AVAX: zero address");
        require(_amounts > 0 , "AVAX: amounts zero");
        require( _balances[_from]>0,"AVAX: transfer amount exceeds balance");
        uint amounts = _amounts*10**18;

        _balances[_from] = _balances[_from].sub(amounts, "AVAX: transfer amount exceeds balance");
        _balances[_to] = _balances[_to].add(amounts);
        emit Transfer(_from, _to, amounts);
    }
 
    event TransferUser(address indexed _owner, address indexed to, uint256 value,string userID,uint time);
  


    function tranferToUser (address _to , uint _amounts,string memory  _userID,uint time) public onlyOwner returns (bool){
      
        require(_to != address(0), "AVAX: zero address");
        require(_amounts > 0 , "AVAX: amounts zero");
        require( _balances[_owner]>0,"AVAX: transfer amount exceeds balance");
        uint amounts = _amounts*10**18;

         _balances[_owner] = _balances[_owner].sub(amounts, "AVAX: transfer amount exceeds balance");
         _balances[_to] = _balances[_to].add(amounts);
         emit TransferUser(_owner, _to, amounts,_userID,time);
         emit Transfer(_owner, _to, amounts);

    }
 

}