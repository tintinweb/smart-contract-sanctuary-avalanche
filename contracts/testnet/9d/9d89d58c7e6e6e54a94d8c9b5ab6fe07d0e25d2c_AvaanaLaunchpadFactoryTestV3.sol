/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-08
*/

// SPDX-License-Identifier: UNLICENSED
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


contract AvaanaIDOContract is Owned {
    using SafeMath for uint256;
    
    bool public isPresaleOpen;
    
    //@dev ERC20 token address and decimals
    address public tokenAddress;
    uint256 public tokenDecimals;
    uint256 public totalSolded = 0;
    uint256 public endDate;
    
    //@dev amount of tokens per ether 100 indicates 1 token per eth
    uint256 public tokenRatePerEth;
    //@dev decimal for tokenRatePerEth,
    //2 means if you want 100 tokens per eth then set the rate as 100 + number of rateDecimals i.e => 10000
    uint256 public rateDecimals = 0;
    
    //@dev max and min token buy limit per account
    uint256 public minEthLimit;
    uint256 public maxEthLimit;
    
    mapping(address => uint256) public usersInvestments;
    
    address public recipient;
   
    constructor(address _token, uint256 _tokenDecimals, uint256 _minEthLimit, uint256 _maxEthLimit, uint256 _tokenRatePerEth, uint256 _endDate, address _recipient) public {
        tokenAddress = _token;
        tokenDecimals = _tokenDecimals;
        minEthLimit = _minEthLimit;
        maxEthLimit = _maxEthLimit;
        tokenRatePerEth = _tokenRatePerEth;
        endDate = _endDate;
        recipient = _recipient;
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
    
    function closePrsale() external onlyOwner {
        require(isPresaleOpen, "Presale is not open yet.");
        isPresaleOpen = false;
    }
    
    function setTokenDecimals(uint256 decimals) external onlyOwner {
       tokenDecimals = decimals;
    }
    
    function setMinEthLimit(uint256 amount) external onlyOwner {
        minEthLimit = amount;    
    }
    
    function setMaxEthLimit(uint256 amount) external onlyOwner {
        maxEthLimit = amount;    
    }
    
    function setTokenRatePerEth(uint256 rate) external onlyOwner {
        tokenRatePerEth = rate;
    }

    function setEndDate(uint256 _endDate) external onlyOwner {
        endDate = _endDate;
    }
    
    function setRateDecimals(uint256 decimals) external onlyOwner {
        rateDecimals = decimals;
    }
    
    function buyToken() public payable {
        require(isPresaleOpen, "Presale is not open.");
        require(
                usersInvestments[msg.sender].add(msg.value) <= maxEthLimit
                && usersInvestments[msg.sender].add(msg.value) >= minEthLimit,
                "Installment Invalid."
            );
        
        //@dev calculate the amount of tokens to transfer for the given eth
        uint256 tokenAmount = getTokensPerEth(msg.value);
        
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);
        require(IToken(tokenAddress).transfer(msg.sender, tokenAmount), "Insufficient balance of presale contract!");
        totalSolded = totalSolded + msg.value;

        //@dev send received funds to the owner
         payable(recipient).transfer(msg.value);

    }
    
    function getTokensPerEth(uint256 amount) internal view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }
    
    function burnUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot burn tokens untitl the presale is closed.");
        
        IToken(tokenAddress).burn(IToken(tokenAddress).balanceOf(address(this)));
    }
    
    function getUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        IToken(tokenAddress).transfer(owner, IToken(tokenAddress).balanceOf(address(this)) );
    }
}

interface IAvaanaIDOContract {
        function startPresale() external;
        function closePrsale() external;
        function setTokenDecimals(uint256 _decimal) external;
        function setMinEthLimit(uint256 amount) external;
        function setMaxEthLimit(uint256 amount) external;
        function setTokenRatePerEth(uint256 rate) external;
        function setRateDecimals(uint256 decimals) external;
        function setEndDate(uint256 _endDate) external;
    }

contract AvaanaLaunchpadFactoryTestV3 is Owned{
    
    struct IDOinfo{
        address TokenContract;
        uint256 TokenDecimal;
        uint256 minEthLimit;
        uint256 maxEthLimit;
        uint256 endDate;
        uint256 ratePerETH;
        address recipient;
    }

    mapping(address => IDOinfo) public IdoInformations;
    mapping(uint256 => address) public IdoAddressList;
    uint256 public idoID = 0;
    
    constructor() public {}

    function CreateIDO(address _token, uint256 _tokenDecimals, uint256 _minEthLimit, uint256 _maxEthLimit, uint256 _tokenRatePerEth, uint256 _endDate , address _recipient) public {
            AvaanaIDOContract IDO = new AvaanaIDOContract(_token,_tokenDecimals,_minEthLimit,_maxEthLimit, _tokenRatePerEth, _endDate,_recipient);
            IdoInformations[address(IDO)] = IDOinfo(_token,_tokenDecimals,_minEthLimit,_maxEthLimit,_endDate,_tokenRatePerEth,_recipient);
            IdoAddressList[idoID] = address(IDO);
            idoID++;
     } 

     function PresaleStart(address contractAddr) public onlyOwner{
         IAvaanaIDOContract(contractAddr).startPresale();
     }

     function PresaleClose(address contractAddr) public onlyOwner{
         IAvaanaIDOContract(contractAddr).closePrsale();
     }

     function setTokenDecimals(address contractAddr , uint256 _decimal) public onlyOwner{
         IdoInformations[contractAddr].TokenDecimal=_decimal;
         IAvaanaIDOContract(contractAddr).setTokenDecimals(_decimal);
     }

     function setMinEthLimit(address contractAddr , uint256 _amount) public onlyOwner{
         IdoInformations[contractAddr].minEthLimit=_amount;
         IAvaanaIDOContract(contractAddr).setMinEthLimit(_amount);
     }

     function setMaxEthLimit(address contractAddr , uint256 _amount) public onlyOwner{
         IdoInformations[contractAddr].maxEthLimit=_amount;
         IAvaanaIDOContract(contractAddr).setMaxEthLimit(_amount);
     }

     function setTokenRatePerEth(address contractAddr , uint256 _rate) public onlyOwner{
         IdoInformations[contractAddr].ratePerETH=_rate;
         IAvaanaIDOContract(contractAddr).setTokenRatePerEth(_rate);
     }

     function setRateDecimals(address contractAddr , uint256 _decimals) public onlyOwner{
         IAvaanaIDOContract(contractAddr).setRateDecimals(_decimals);
     }

     function setEndDate(address contractAddr , uint256 _endDate) public onlyOwner{
         IAvaanaIDOContract(contractAddr).setEndDate(_endDate);
     }     
}