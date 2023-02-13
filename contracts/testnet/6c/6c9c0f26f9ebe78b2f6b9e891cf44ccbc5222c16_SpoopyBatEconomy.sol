/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 
{
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ISBE
{
    function buyItem (uint index) external returns (bool);
}

contract SpoopyBatEconomy is ISBE, Ownable
{
    IERC20 immutable _GOTH;
    uint256[] public _items; 

    constructor (address _goth)
    {
       _GOTH = IERC20(_goth);
       _items.push(100_000e18);
       _items.push(75_000e18);
    }

    function buyItem (uint index) public returns (bool)
    {
        require(index < _items.length, "buyItem: That item does not exist");
        require(_GOTH.allowance(msg.sender, address(this)) >= _items[index], "buyItem: GOTH allowance not high enough");
        require(_GOTH.balanceOf(msg.sender) >= _items[index], "buyItem: Not enough GOTH");
        require(_GOTH.transferFrom(msg.sender, address(this), _items[index]), "buyItem: transferFrom failed");
        return true;
    }

    function addItem (uint256 value) public onlyOwner
    {
        _items.push(value);
    }

    function changeItem (uint index, uint256 value) public onlyOwner
    {
        require(index >= _items.length, "changeItem: That item does not exist");
        _items[index] = value;
    }
}