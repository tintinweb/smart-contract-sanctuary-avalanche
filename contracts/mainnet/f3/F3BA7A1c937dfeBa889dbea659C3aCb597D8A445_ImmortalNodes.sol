/**
 *Submitted for verification at snowtrace.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}


abstract contract ReentrancyGuard {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

   
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns(uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}



contract ImmortalNodes is ReentrancyGuard, Context, Ownable {

    mapping (address => uint256) public _contributions;
    mapping (address => uint256) public totalContributions;
    mapping (address => uint256) public maxPurchase;
    mapping (address => uint256) public claimed;

    IERC20 public _token;
    uint256 private _tokenDecimals;
    uint256 public _rate;
    uint256 public _weiRaised;
    uint256 public endICO;
    uint256 public minPurchase;
    uint256 public maxPurchasePer;
    uint256 public hardcap;
    uint256 public purchasedTokens;
    uint256 public bnbCollected;
    uint256 timeToWait;
    

    event TokensPurchased(address  purchaser, uint256 value, uint256 amount);

    constructor (uint256 rate, IERC20 token,uint256 _timeToWait)  {
        require(rate > 0, "Pre-Sale: rate is 0");
        require(address(token) != address(0), "Pre-Sale: token is the zero address");
        
        _rate = rate;
        _token = token;
        timeToWait = _timeToWait;
    }
    
 
    
    //Start Pre-Sale
    function startICO(uint256 endDate, uint256 _minPurchase,uint256 _maxPurchase,  uint256 _hardcap) external onlyOwner icoNotActive() {
        require(endDate > block.timestamp, 'duration should be > 0');
        endICO = endDate; 
        minPurchase = _minPurchase;
        maxPurchasePer = _maxPurchase;
        hardcap = _hardcap;
        _weiRaised = 0;
    }
    
    function stopICO() external onlyOwner icoActive(){
        endICO = 0;
    }
    
    //Pre-Sale 
    function buyTokens() public payable nonReentrant icoActive{

        uint256 amount = msg.value;
        uint256 weiAmount = amount;

        payable(owner()).transfer(amount);

        uint256 tokens = _getTokenAmount(weiAmount);
        _preValidatePurchase(_msgSender(), weiAmount);
        _weiRaised = _weiRaised + weiAmount;
        bnbCollected = bnbCollected + weiAmount;
        purchasedTokens += tokens;
        totalContributions[_msgSender()] = totalContributions[_msgSender()] + weiAmount;
        _contributions[_msgSender()] = _contributions[_msgSender()] + weiAmount;
        emit TokensPurchased(_msgSender(), weiAmount, tokens);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Presale: beneficiary is the zero address");
        require(weiAmount != 0, "Presale: weiAmount is 0");
        require(weiAmount >= minPurchase, 'have to send at least: minPurchase');
        require(_weiRaised + weiAmount <= hardcap, "Exceeding hardcap");
        require(_contributions[beneficiary] + weiAmount <= maxPurchasePer, "can't buy more than: maxPurchase");
    }


    function claim() external nonReentrant{
        require(checkContribution(_msgSender()) > 0, "No tokens to claim");
        require(checkContribution(_msgSender()) <= IERC20(_token).balanceOf(address(this)), "No enough tokens in contract");
        require( block.timestamp > timeToWait, "You must wait until claim time / Launch time");
        uint256 amount = _contributions[_msgSender()];
        
        claimed[_msgSender()] = claimed[_msgSender()] + amount;
        uint256 tokenTransfer = _getTokenAmount(amount);
        require(IERC20(_token).transfer(_msgSender(), tokenTransfer));
    }

    function changeWaitTime(uint256 _timeToWait) external onlyOwner returns(bool){
        timeToWait =_timeToWait;
        return true;
    }
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount * _rate;
    }

    function _forwardFunds(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }
    
    function checkContribution(address addr) public view returns(uint256){
        uint256 tokensBought = _getTokenAmount(_contributions[addr]);
        return (tokensBought);
    }

    function checkContributionExt(address addr) external view returns(uint256){
        uint256 tokensBought = _getTokenAmount(_contributions[addr]);
        return (tokensBought);
    }

    
    function setRate(uint256 newRate) external onlyOwner icoNotActive{
        _rate = newRate;
    }
    
     function setMinPurchase(uint256 value) external onlyOwner{
        minPurchase = value;
    }

    function setMaxPurchase(uint256 value) external onlyOwner{
        maxPurchasePer = value;
    }
    
    function setHardcap(uint256 value) external onlyOwner{
        hardcap = value;
    }
    
    function takeTokens(IERC20 tokenAddress) public onlyOwner{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, "BEP-20 balance is 0");
        tokenBEP.transfer(owner(), tokenAmt);
    }
    
    modifier icoActive() {
        require(endICO > 0 && block.timestamp < endICO && _weiRaised < hardcap, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(endICO < block.timestamp, 'ICO should not be active');
        _;
    }
    
}