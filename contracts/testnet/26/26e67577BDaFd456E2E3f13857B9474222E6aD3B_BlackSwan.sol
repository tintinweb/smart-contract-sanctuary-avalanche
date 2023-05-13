/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-12
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

contract BlackSwan is IERC20 {
    string public constant name = "BlackSwan";
    string public constant symbol = "BLKSWN";
    uint8 public constant decimals = 18;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant INITIAL_SUPPLY = 1000000 * 10**uint256(decimals); // 1,000,000 tokens

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 private totalSupply_;
    
    constructor() {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balances[msg.sender], "ERC20: insufficient balance");

        uint256 taxAmount = amount * 2 / 100; // 2% sales tax
        uint256 transferAmount = amount - taxAmount;

        balances[msg.sender] -= amount;
        balances[recipient] += transferAmount;
        balances[address(this)] += taxAmount;

        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, address(this), taxAmount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balances[sender], "ERC20: insufficient balance");
        require(amount <= allowances[sender][msg.sender], "ERC20: insufficient allowance");

        uint256 taxAmount = amount * 2 / 100; // 2% sales tax
        uint256 transferAmount = amount - taxAmount;

        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        balances[address(this)] += taxAmount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, address(this), taxAmount);
        return true;
    }
}