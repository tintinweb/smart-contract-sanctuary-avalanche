/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.6.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: presale.sol


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

contract Whitelist is Owned {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'not whitelisted');
        _;
    }

    
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

  
    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }

    }

    
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

   
    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IToken {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burn(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}


contract Presale is Owned {
    AggregatorV3Interface internal priceFeed;
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    using SafeMath for uint256;
    uint256 sent_amount = 0 ;
    bool public isPresaleOpen;
    bool public isPresalePaused;
    
    //@dev ERC20 token address and decimals
    address public tokenAddress;
    uint256 public tokenDecimals = 18;
    address private dev = 0x3fDeBFFE66B9364bf011e0Ac2230c36b0699fee1;
    
    //@dev amount of tokens per ether 100 indicates 1 token per eth
    uint256 public tokenRatePerEth = 18;
    uint256 public tokenRatePerDollar = 2000000000 ; 
    //@dev decimal for tokenRatePerEth,
    //2 means if you want 100 tokens per eth then set the rate as 100 + number of rateDecimals i.e => 10000
    uint256 public rateDecimals = 1;
    uint256 private devFee = 5;
    
    //@dev max and min token buy limit per account
    uint256 public minEthLimit = 100;
    uint256 public maxEthLimit = 1000;

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'not whitelisted');
        _;
    }

    
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    
    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

  
    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    function getLatestPrice() public view returns (int) {
    (
        uint80 roundID, 
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    return price;
    }
    
    
    mapping(address => uint256) public usersInvestments;
    
    address public recipient;
   
    modifier onlyDev() {
        require(isDev(msg.sender), "!Developer"); _;
    }

    function isDev(address account) public view returns (bool) {
        return account == dev;
    }

    function newDev(address account) public onlyDev {
        dev = account;
    }

    constructor(address _token,address _recipient) public {
        tokenAddress = _token;
        recipient = _recipient;
        addAddressToWhitelist(_recipient) ;
        priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);

    }

    function setDevFee(uint256 _devFee) public onlyDev {
        devFee = _devFee;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }
    
    function startPresale() external onlyOwner {
        require(!isPresaleOpen, "Presale is open");
        
        isPresaleOpen = true;
    }

    function pausePresale() external onlyOwner{
        require(isPresaleOpen, "Presale is not open yet.");
        require(!isPresalePaused, "Presale is already paused.");
        isPresalePaused = true;
    }
    function resumePresale() external onlyOwner{
        require(isPresaleOpen, "Presale is not open yet.");
        require(isPresalePaused, "Presale is already resumed");
        isPresalePaused = false;
    }
    
    function closePresale() external onlyOwner {
        require(isPresaleOpen, "Presale is not open yet.");
        
        isPresaleOpen = false;
    }
    
    function setTokenAddress(address token) external onlyOwner {
        require(tokenAddress == address(0), "Token address is already set.");
        require(token != address(0), "Token address zero not allowed.");
        
        tokenAddress = token;
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
    
    function setRateDecimals(uint256 decimals) external onlyOwner {
        rateDecimals = decimals;
    }

    function settokensentvalue(uint256 val) public
    {
        sent_amount = val ;
    }

    function gettokensentvalue() public view returns(uint256)
    {
        return sent_amount ;
    }

    receive() external payable {
        require(isPresaleOpen, "Presale is not open.");

        uint256 avax_in_dollars = getavaxtodollars(msg.value) ;

        require(
                usersInvestments[msg.sender].add(avax_in_dollars) <= maxEthLimit
                && usersInvestments[msg.sender].add(avax_in_dollars) >= minEthLimit,
                "Installment Invalid."
            );
        require(whitelist[msg.sender] , "Address is not whitelisted" ) ;

        uint256 reth_amount = getTokensindollarPerAvax(msg.value) ;

        //@dev calculate the amount of tokens to transfer for the given eth
        // uint256 tokenAmount = getTokensPerEth(msg.value);
        
        require(IToken(tokenAddress).transfer(msg.sender, reth_amount), "Insufficient balance of presale contract!");
        
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(avax_in_dollars);
        
        uint256 avaxAmt = msg.value;
        uint256 ownerAmt = avaxAmt;
        
        this.settokensentvalue(reth_amount) ;
        
        payable(recipient).transfer(ownerAmt);
    
    }
    
    function getTokensPerEth(uint256 amount) internal view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }

    function getTokensindollarPerAvax (uint256 avax_amount) internal view returns(uint256)
    {
        uint256 avax_in_usd = uint256 (getLatestPrice()).div(10**uint256(8)) ;
        return avax_amount.mul(avax_in_usd).mul(tokenRatePerDollar);
    }

    function getavaxtodollars (uint256 avax_amount) internal view returns(uint256)
    {
        uint256 avax_in_usd = uint256 (getLatestPrice()).div(10**uint256(8)) ;
        return avax_amount.mul(avax_in_usd);
    }

    
    function burnUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot burn tokens until the presale is closed.");
        
        IToken(tokenAddress).burn(IToken(tokenAddress).balanceOf(address(this)));   
    }
    
    function getUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        
        IToken(tokenAddress).transfer(owner, IToken(tokenAddress).balanceOf(address(this)) );
    }
}