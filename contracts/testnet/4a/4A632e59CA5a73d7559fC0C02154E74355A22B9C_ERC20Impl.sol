//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./Interfaces/IERC20.sol";

contract ERC20Impl is IERC20 {
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    bool initialized;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    modifier initializer() {
        require(!initialized, "ERC20:: initializer: initialize filed");
        _;
        initialized = true;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) external initializer {
        name = _name;
        symbol = _symbol;
        _mint(msg.sender, _totalSupply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "ERC20:: transfer: not correct address");
        require(balanceOf[msg.sender] >= amount, "ERC20:: transfer: insufficient funds");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(from != address(0) && to != address(0), "ERC20:: transferFrom: not correct addresses");
        require(balanceOf[from] >= amount, "ERC20:: transferFrom: insufficient funds");
        require(allowance[from][msg.sender] >= amount, "ERC20:: transferFrom: insufficient allowenced funds");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Approval(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "ERC20:: approve: approve failed");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ERC20:: _mint: _mint failed");
        totalSupply = amount;
        balanceOf[to] = amount;
        emit Transfer(address(0), msg.sender, amount);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address from, address to, uint256 value);

    event Approval(address owner, address spender, uint256 value);
}