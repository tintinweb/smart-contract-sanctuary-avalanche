/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SimpleToken is IBEP20 {
    string private constant _name = "Simple Token";
    string private constant _symbol = "ST";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;
    address private _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private _feeWallet;
    uint256 private _transferFeePercent;
    
    constructor() {
        _owner = msg.sender;
        _totalSupply = 1000000 * 10**_decimals; // Initial supply of 1,000,000 tokens
        _balances[_owner] = _totalSupply;
        _feeWallet = _owner; // Fee wallet set as the contract deployer initially
        _transferFeePercent = 2; // 2% transfer fee initially
        emit Transfer(address(0), _owner, _totalSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }
    
    function name() external pure returns (string memory) {
        return _name;
    }
    
    function symbol() external pure returns (string memory) {
        return _symbol;
    }
    
    function decimals() external pure returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
    
    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Mint to the zero address");
        
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function setTransferFeePercent(uint256 feePercent) external onlyOwner {
        require(feePercent <= 100, "Fee percent must be between 0 and 100");
        _transferFeePercent = feePercent;
    }
    
    function setFeeWallet(address feeWallet) external onlyOwner {
        require(feeWallet != address(0), "Fee wallet cannot be the zero address");
        _feeWallet = feeWallet;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "Insufficient balance");

        uint256 transferFee = (amount * _transferFeePercent) / 100;
        uint256 transferAmount = amount - transferFee;
        
        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[_feeWallet] += transferFee;
        
        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _feeWallet, transferFee);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}