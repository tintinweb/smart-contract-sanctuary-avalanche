/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CTX is IERC20 {

  // Attributes. Change at your own will. THOUGH DON'T TOUCH THE "10**decimals" PART!
  string public constant name = "Cat Token";
  string public constant symbol = "CTX";
  uint8 public constant decimals = 18;
  uint256 constant _totalSupply = 1000000 * 10**decimals; //Total amount of tokens
  bool public presale;

  // Token distribution wallets. Totally change to yours.
  address private presaleWallet = 0x84b69fE9adC516bA8F70F837FE4d31e1d6727AF1;
  address private liquidityWallet = 0xFf18f2FEF3ba572cf1e85971Bb481b4FFD59a0E8;
  address private rewardWallet = 0xa853BC4B10a2A4636cf1bbFC7F5197F6CFC77522;
  address private teamWallet = 0xaDD13BEA280c86b45f7cC278cd7cf7355371DbAf;
  address private treasureWallet = 0x6C0EeeAB0c43138C563990dD7EB7D87553E386C2;

  // Owners as a mapping or only 1 owner?
  mapping(address => bool) owners;
  mapping(address => bool) whitelists;
  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowances;

  // Don't know about having bool indexed or no.
  event Whitelist(address indexed owner, address indexed whitelister, bool indexed added);
  event Ownership(address indexed owner, address indexed newOwner, bool indexed added);

  // Total amount is hard-coded at the start. Change the values to anything you want. ALSO DON'T TOUCH THE "10**decimals" PART!
  constructor() {
    owners[msg.sender] = true;
    balances[presaleWallet] = 100000 * 10**decimals;
    balances[liquidityWallet] = 300000 * 10**decimals;
    balances[rewardWallet] = 450000 * 10**decimals;
    balances[teamWallet] = 50000 * 10**decimals;
    balances[treasureWallet] = 100000 * 10**decimals;
  }

  // "require" probably doesn't need the error text in the future. (used for ease of debugging)
  modifier OnlyOwners {
    require(owners[msg.sender] == true, "You are not the owner of the token");
    _;
  }

  function totalSupply() public pure override returns (uint256) {
    return _totalSupply;
  }

  // Do you want to be able to check the balance of everyone or nah?
  function balanceOf(address _who) public view override returns (uint256) {
    return balances[_who];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(amount <= balances[msg.sender], "You do not have enough CTX");
    require(recipient != address(0), "The receiver address has to exist");

    balances[msg.sender] -= amount;
    balances[recipient] += amount;
    emit Transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return allowances[owner][spender];
  }

  //Perhaps more allowance functions? Should be fine without them, but still...
  function approve(address spender, uint256 amount) public override returns (bool) {
    allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  // "require" probably doesn't need the error text in the future. (used for ease of debugging)
  // Deduct allowance or no? Logically, yes.
  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    require(allowances[sender][msg.sender] >= amount && amount > 0, "You do not have enough CTX");
    allowances[sender][msg.sender] -= amount;
    balances[sender] -= amount;
    balances[recipient] += amount;
    return true;
  }

  function addWhitelistMember(address _who) OnlyOwners public returns (bool) {
    emit Whitelist(msg.sender, _who, true);
    whitelists[_who] = true;
    return true;
  }

  function removeWhitelistMember(address _who) OnlyOwners public returns (bool) {
    emit Whitelist(msg.sender, _who, false);
    whitelists[_who] = false;
    return true;
  }

  function checkWhitelistStatus(address _who) public view returns (bool) {
    return whitelists[_who];
  }

  function addOwner(address _who) OnlyOwners public returns (bool) {
    emit Ownership(msg.sender, _who, true);
    owners[_who] = true;
    return true;
  }

  function removeOwner(address _who) OnlyOwners public returns (bool) {
    emit Ownership(msg.sender, _who, false);
    owners[_who] = false;
    return true;
  }

  function checkOwner(address _who) public view returns (bool) {
    return owners[_who];
  }

  function PresaleStatus(bool _value) OnlyOwners public returns (bool) {
    presale = _value;
    return true;
  }
}