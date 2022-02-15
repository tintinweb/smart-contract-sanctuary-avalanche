/**
 *Submitted for verification at snowtrace.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CHITSToken is IERC20 {

    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    string public ERR_INSUFF_BAL = "Insufficient balance.";
    string public ERR_INSUFF_ALL = "Insufficient allowance.";
    string public ERR_INSUFF_AMT = "Insufficient amount. Amount sent less than minimum value required for the sale.";
    string public ERR_CANNOT_BE_ZERO = "Value cannot be zero.";
    string public ERR_ALREADY_IN_HOLDER_LIST = "Already in holders list.";
    string public ERR_CANNOT_SEND_TO_ZERO_WALLET = "Cannot send to zero wallet address.";
    string public name = "CHITS Token";
    string public symbol = "CHIT";

    mapping(address => mapping(address => uint256)) public allowances; 
    mapping(address => uint256) public balances;
    mapping(address => bool) public isInHoldersList;
    address[] public holders;

    address owner;
    address zero = 0xe9745E03901d043c3Bed8CC31FA77dC631094b59;
    address dexWallet = 0x3F728642019b0b2397711F19c7ce202D1D31D009; 
    address corpAddress = 0x41829071c24D207189331F0c1B86540243f153A5; 
    address devAddress = 0x8c8F4F7eaAf3a1C4922B3cBE1Ef2520098f174ce; 
    
    uint256 public decimals = 18;
    uint256 public override totalSupply = 1000000000 * 10 ** decimals; //1B CHITS
    uint256 private constant MULTIPLIER = 1 * 10 ** 18;
    uint256 public weiRaised = 0;
    uint256 public tokensSold = 0;
    uint256 public minAmount = 5 * 10 ** 17; //0.5 wei

    
    constructor() { 
        owner = msg.sender;

        balances[zero] = totalSupply * 4000 / 10000; 
        pushAndIndex(zero);

        balances[dexWallet] = totalSupply * 2000 / 10000; 
        pushAndIndex(dexWallet);

        balances[corpAddress] = totalSupply * 2500 / 10000; 
        pushAndIndex(corpAddress);

        balances[devAddress] = totalSupply * 1500 / 10000; 
        pushAndIndex(devAddress);

    }

    function getWeiRaised() public view returns(uint256) {
        return weiRaised;
    }

    function getTokensSold() public view returns(uint256) {
        return tokensSold;
    }

    function getHolder(uint256 index) public view returns(address) {
        return holders[index];
    }

    function buyChits(address beneficiary) public payable{
        require(beneficiary != zero, ERR_CANNOT_SEND_TO_ZERO_WALLET);
        uint256 weiAmount = msg.value;

        _preValidatePurchase(beneficiary, weiAmount);

        uint256 tokensToReceive = _getTokenAmount(weiAmount);
        weiRaised += weiAmount;
        tokensSold += tokensToReceive;

        _processPurchase(beneficiary, tokensToReceive);

        emit TokenPurchase(
            msg.sender,
            beneficiary,
            weiAmount,
            tokensToReceive
        );

        _updatePurchasingState(beneficiary, weiAmount);
        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
        pure
        internal
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    function _postValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
        internal
    {
        // optional override
    }

    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        require(balanceOf(zero) >= _tokenAmount, ERR_INSUFF_BAL);
        
        balances[_beneficiary] += _tokenAmount;
        balances[zero] -= _tokenAmount;

        pushAndIndex(_beneficiary);     
           
        emit Transfer(zero, _beneficiary, _tokenAmount);
    }

    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount
    )
        internal
    {
        // optional override
    }

    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        require(_weiAmount > 0, ERR_CANNOT_BE_ZERO);
        require(_weiAmount >= minAmount, ERR_INSUFF_AMT);
        return _weiAmount * _getRate();
    }

    function _getRate() public view returns(uint256) {
        if(balanceOf(zero) > 250000000 * 10 ** decimals) { //15:25 / 600:300
            return 600;
        }
        return 300;
    }


    function _forwardFunds() internal {
        payable(zero).transfer(msg.value);
    }

    receive() external payable {
        require(msg.value >= minAmount, ERR_INSUFF_AMT);
        buyChits(msg.sender);
    }

    fallback () external payable {
        require(msg.value >= minAmount, ERR_INSUFF_AMT);
        buyChits(msg.sender);
    }
 
    function balanceOf(address _owner) public view override returns(uint) {
        return balances[_owner];
    }
          
    function transfer(address to, uint value) external override returns(bool) {
        require(to != zero, ERR_CANNOT_SEND_TO_ZERO_WALLET);
        require(balanceOf(msg.sender) >= value, ERR_INSUFF_BAL);
        require(value >= 0, ERR_INSUFF_BAL);
        
        
        balances[to] += value;
        balances[msg.sender] -= value;

        pushAndIndex(to);     
           
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public override returns(bool) {
        require(to != zero, ERR_CANNOT_SEND_TO_ZERO_WALLET);
        require(balanceOf(from) >= value, ERR_INSUFF_BAL);
        require(allowances[from][msg.sender] >= value, ERR_INSUFF_ALL);

        balances[to] += value;
        balances[from] -= value;

        pushAndIndex(to);
        
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public override returns(bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return allowances[_owner][spender];
    }
    
    function pushAndIndex(address recipient) internal {
        if(isInHoldersList[recipient]) {
            //do nothing
        } else {
            holders.push(recipient);
            isInHoldersList[recipient] = true;
        }     
        
    }
}