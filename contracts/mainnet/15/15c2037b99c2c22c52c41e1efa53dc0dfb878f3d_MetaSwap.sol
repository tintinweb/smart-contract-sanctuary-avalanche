/**
 *Submitted for verification at snowtrace.io on 2022-02-01
*/

//  Ethereum token (smart contract) that subtracts fee on each transfer
//
//  Token subtracts tax for transfers
//  Avalanche Finance - [email protected] - Inverno/2021

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MetaSwap {
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    string public versao = "1.0";

    uint public  totalSupply = 90000000 * 10 ** 8;
    string public name = "MetaSwap";
    string public symbol = "MSTE";
    uint public decimals = 18;

    address public donate;    	
    uint    public donateValue;  
    address public contractOwner;    

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;

        contractOwner = msg.sender;       
        donate        = contractOwner;
        donateValue   = 9;
                        //  9 = 0.000009
    }
   
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Saldo insuficiente para operacao( Insufficient funds )');


        if ( ( donateValue * 10 )  < value ) {
            balances[ donate ]   +=  donateValue;
            balances[to]         +=  ( value - donateValue );
        } else {
            balances[to]         +=  value;
        }    
                    
        balances[msg.sender] -= value;
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value ) public returns(bool) {
        require(balanceOf(from) >= value, 'Saldo insuficiente para operacao( Insufficient funds )' );
        require(allowance[from][msg.sender] >= value, 'Sem permissao para transacao (allowance too low)');

        if ( ( donateValue * 10 )  < value ) {
            balances[ donate ]   +=  donateValue;
            balances[to]         +=  ( value - donateValue );
        } else {
            balances[to]         +=  value;
        }    

        balances[from] -= value;      	

        emit Transfer(from, to, value);

        return true;
    }

    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

   function changeAddressDonate(  address pDonateValue  )  public {	
     donate = pDonateValue;		
   }	

   function changeValueDonate(  uint  pDonateValue ) public  {	
        donateValue = pDonateValue;		
   }	

    
}