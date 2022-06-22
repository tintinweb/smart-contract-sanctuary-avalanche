/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-22
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract KGT {
    string public constant name = "KushG";
    string public constant symbol = "KG";
    uint256 public constant decimals = 18;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 totalSupply_;
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

   constructor(uint256 total)  {
    totalSupply_ = total* 10 **decimals;
    balances[msg.sender] = totalSupply_;
    // transfer(msg.sender, totalSupply_);
    }
    function totalSupply() public view returns (uint256) {
    return totalSupply_;
    }
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
    function transfer(address receiver, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[msg.sender],"unsuccessful");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    function approve(address delegate, uint256 numTokens) public  returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }
    function transferFrom(address owner, address buyer, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    function mint(uint256 amount) public   {
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalSupply_ = totalSupply_.add(amount);

    }

    function burn(uint256 amount) public  {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);

    }
}
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}