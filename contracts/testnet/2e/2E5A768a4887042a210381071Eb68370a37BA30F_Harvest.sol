// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "../libraries/SafeMath.sol";

error InfinityAllowance();
error InsufficientAllowance();
error InsufficientBalance();
error FromZeroAddress();
error ToZeroAddress();
contract Harvest {
    string constant _name = "HARVEST";
    string constant _symbol = "SEED";
    string constant _standard = "Harvest v1.0";
    uint8 constant _decimals = 18;
    uint256 constant _totalSupply = 1000000 * 10**18;
    
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Withdrawal(
         address indexed _by,
        address indexed _from,
        uint256 _value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor () {
        _balanceOf[msg.sender] = _totalSupply;
    }

    function name() external pure returns (string memory) { return _name; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function standard() external pure returns (string memory) { return _standard;}
    function decimals() external pure returns (uint8) { return _decimals; }
    function totalSupply() public pure returns (uint256) { return _totalSupply; }

    function balanceOf(address owner) public view returns (uint256 balance){
        return _balanceOf[owner];
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowance[owner][spender];
    }

     function transfer(address to, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }   

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 currentAllowance = allowance(from, spender);
        if(currentAllowance == type(uint256).max) { revert InfinityAllowance();}
        if(currentAllowance < amount) { revert InsufficientAllowance(); }
        _allowance[from][spender] = SafeMath.sub(currentAllowance, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, SafeMath.add(allowance(owner, spender), addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        if(currentAllowance < subtractedValue) { revert InsufficientAllowance();}
        unchecked {
            _approve(owner, spender, SafeMath.sub(currentAllowance, subtractedValue));
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if(from == address(0)) { revert FromZeroAddress();}
        if(to == address(0)) { revert ToZeroAddress();}

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balanceOf[from];
        if(fromBalance < amount) { revert InsufficientBalance();}

        _balanceOf[from] = SafeMath.sub(fromBalance, amount);
        _balanceOf[to] = SafeMath.add(_balanceOf[to], amount);

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);

    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if(owner == address(0)) { revert FromZeroAddress();}
        if(spender == address(0)) { revert ToZeroAddress();}

        if(amount < 0) {
            amount = 0;
        }

        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) revert();
            return c;
        }
    }

    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        unchecked {
            if (b > a) revert();
            return  a - b;
        }
    }
}