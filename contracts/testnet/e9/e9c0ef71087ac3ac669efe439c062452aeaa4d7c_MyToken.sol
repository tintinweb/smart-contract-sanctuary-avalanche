/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

  function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
        
        emit Transfer(from, to, amount);
    }
  
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _balances[account] += amount;
   
        emit Transfer(address(0), account, amount);
    }
}

contract MyToken is ERC20("MyToken","MET"){
    function mint() public{
        _mint(msg.sender, 1000);
    }

    function balance() public view returns(uint256){
        return balanceOf(msg.sender);
    }
}