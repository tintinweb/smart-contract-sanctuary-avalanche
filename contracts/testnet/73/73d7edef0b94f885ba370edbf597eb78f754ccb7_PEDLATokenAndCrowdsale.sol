/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-28
*/

pragma solidity ^0.4.24;

//import "token.sol";

contract erc20interface{
  
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 
}


contract PEDLATokenAndCrowdsale  {

    mapping (address => uint) public balances;
    address tokenFundsAddress;
    address beneficiary;
    
    
    uint amountRaised;
    uint constant private TOKEN_PRICE_IN_WEI = 1 * 333000000000000000 wei;
    uint constant private Total_price_in_wei = 1 * 1 ether;

  uint sales = 55;
  uint commissionNumerator = 100;
  uint commissionDenominator = 1000;
  uint afterCommission = commissionNumerator * sales / commissionDenominator;
  uint bp = 1000;


    event TransferPEDLA(address indexed from, address indexed to, uint value);
    event FundsRaised(address indexed from, uint fundsReceivedInWei, uint tokensIssued);
    event ETHFundsWithdrawn(address indexed recipient, uint fundsWithdrawnInWei);

           
    
    
    constructor(uint initialSupply) public {
        balances[msg.sender] = initialSupply;
        tokenFundsAddress = msg.sender;
        beneficiary = tokenFundsAddress;
    }
    
    

      
      function sendTokens(address receiver, uint amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit TransferPEDLA(msg.sender, receiver, amount);
    }
    
      
      /*function getBalance(address addr) public view returns (uint) {
        return balances[addr];
    }*/

      
      function buyTokensWithEther() public payable {
        uint numTokens = msg.value / TOKEN_PRICE_IN_WEI;
        balances[tokenFundsAddress] -= numTokens;
        balances[msg.sender] += numTokens;
        amountRaised += msg.value / Total_price_in_wei;
        emit FundsRaised(msg.sender, msg.value, numTokens);
    }
    
      
      function withdrawRaisedFunds() public {
        if (msg.sender != beneficiary)
            return;
            beneficiary.transfer(amountRaised);
            emit ETHFundsWithdrawn(beneficiary, amountRaised);
        
    }
    
      function myAddress() public constant returns (address){
        address myAdr = msg.sender;
        return myAdr;
    }
    
      function myBalance() public constant returns (uint){
        return (balances[msg.sender]);
    }
    
    
     function totalFunds() public constant returns (uint){
        return amountRaised;
    }
    
     function Percentage() public view returns (uint128){
        return uint128(int256(amountRaised) * int256(100) / int256(bp));
       // return uint128(amountRaised) * uint128(bp) / uint128(10000);
  }
}