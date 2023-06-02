// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender], "Insufficient balance");
        require(to != address(0), "Invalid recipient");

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(value <= balances[from], "Insufficient balance");
        require(
            value <= allowances[from][msg.sender],
            "Insufficient allowance"
        );
        require(to != address(0), "Invalid recipient");

        balances[from] -= value;
        balances[to] += value;
        allowances[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Invalid spender");

        allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function mint(address account, uint256 value) public returns (bool) {
        require(account != address(0), "Invalid account");

        balances[account] += value;
        totalSupply += value;

        emit Transfer(address(0), account, value);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return allowances[owner][spender];
    }
}