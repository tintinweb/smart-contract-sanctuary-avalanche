/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function whitelist(address addrs) external returns(bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Presale{
    using SafeMath for uint256;
    IERC20 Token;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */

     uint256 presalePrice = 6050000000000000 ;
     uint256 ListingPrice = 30250000000000000;
     address payable owner;

     address [] AddWhitelist;
     


    constructor (IERC20 _Token) 
    {     
         Token = _Token;
    }

        modifier onlyowner() {
        require(owner == msg.sender, 'not whitelisted');
        _;
    }


    function calculateSplash(uint256 amount) public view returns(uint256) 
    {
        return (presalePrice.mul(amount));
    }

    function Buy() public payable 
    {
        require(Token.whitelist(msg.sender), "You are not Whitelist" );
        require(msg.value == 0.00605 ether, "please enter value");
        uint256 amount = calculateSplash(msg.value);
        Token.transfer(msg.sender,amount);
    }


    function addaddressWhitelist() public payable
    {
        require(msg.value == 0.03025 ether, "please enter value");
        AddWhitelist.push(msg.sender);
    }



        function Check_WhitelistAccounts() public view returns(address [] memory ) 
    {
        return AddWhitelist;
    }

        function checkContractBalance() public view returns(uint256) 
    {
        return address(this).balance;
    }

        function WithdrawAVAX(uint256 amount) public payable onlyowner
    {
        owner.transfer(amount);
    }

            function WithdrawSplash(uint256 amount) public payable onlyowner
    {
        Token.transfer(msg.sender ,amount);
    }
    
}