/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-04
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;

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

interface IERC20{

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address receiver, uint256 tokenAmount) external  returns(bool);
    function transferFrom( address tokenOwner, address recipient, uint256 tokenAmount) external returns(bool);
    function allownce( address tokenOwner, address spender) external returns(uint256);
    function approve (address spender, uint256 tokenAmount ) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 tokenAmount);
    event approval( address indexed tokenOwner, address indexed spender, uint256 tokenAmount);
}
//  transaction cost	1214256 gas
contract CYPtoken is IERC20{
    using SafeMath for uint256;

    string public constant tokenName = "Cypress";
    string public constant tokenSymbol = "CYP";
    uint8 public  constant tokenDecimal  = 18;
    uint256 public totalSupply_;
    address public owner;


    mapping(address => uint256) private balanceIS;
    mapping(address => mapping(address =>uint256 )) private allowed;


    constructor() {
    
        totalSupply_ = 10000000 ether;
        balanceIS[address(this)] = totalSupply_;
        balanceIS[msg.sender] = totalSupply_;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require( tx.origin == owner  ,"Caller isn't Owner");
        _;
    }

   // total number of token that is existing ...
    function totalSupply() external view returns(uint256) {

       return totalSupply_ ;
    }
    // check balance of any specified address.
    // uint256 will showed total amount passed by the owner of account.

    function balanceOf(address tokenOwner) public view returns(uint256) {

        return balanceIS[tokenOwner] ;
    }

    /*
    Owner transfer token to a specified address.
    amountofToken that will be transfered to specified address.
    here balanceIS(amountoftoken) that is decreasing from owner Account. 
    here balanceIS(amountoftoken) that is increasing in   receiver Account.
    */
    function transfer(address receiver, uint256 amountOfToken) public  returns(bool) {

        require (balanceIS[msg.sender] > 0 || amountOfToken < balanceIS[msg.sender], "Insufficient Balance");
        balanceIS[msg.sender] -= amountOfToken ; 
        balanceIS[receiver] += amountOfToken ;    
        emit Transfer(msg.sender, receiver, amountOfToken );
        return true;
    }

    // Owner allow amount of token to spender.

    function allownce(address tokenOwner, address spender ) public view returns(uint256 remaining) {

        return allowed [tokenOwner][spender];
    }

    // token Owner  approve/give a amount of token to spender.

    function approve(address spender, uint256 amountOfToken) public returns(bool success) {

        allowed [msg.sender][spender] = amountOfToken ;
        emit approval (msg.sender, spender, amountOfToken);
        return true;
    }

    /*
    In transferFrom  "from" is owner address, and "to" is receiver address.
    here spender spend tokens with permission of owner.
    allownces is the amount that owner give permission to spender to use .
    amount not transfered to spender account but it will be cutting from owner account.
    here condition that require balance of owner is greater than and equal to that amount that will be transfered to receiver.
    */

    function transferFrom(address from, address to, uint256 amountOfToken) public returns(bool success) {

        uint256 allownces = allowed[from][msg.sender];
        require (balanceIS[from] >= amountOfToken && allownces >= amountOfToken );
        balanceIS[from] -= amountOfToken ;
        balanceIS[to]  += amountOfToken ;
        allowed [from][msg.sender] -= amountOfToken ;
        emit Transfer (from , to, amountOfToken);
        return true;
    }
     
    function _mint(address account, uint256 amount) external {

        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply_ = totalSupply_.add(amount);
        balanceIS[account] = balanceIS[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) external {

        require(account != address(0), "ERC20: burn from the zero address");
        totalSupply_ = totalSupply_.sub(value);
        balanceIS[account] = balanceIS[account].sub(value);
        emit Transfer(account, address(0), value);
    }
}