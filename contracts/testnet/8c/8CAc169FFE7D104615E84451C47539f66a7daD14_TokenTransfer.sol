/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(){
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

contract TokenTransfer is Ownable {

    using SafeMath for uint256;
    event TransferFrom(address indexed from, address indexed to, uint256 indexed amount);
    event amountTransfer(address indexed from, address indexed to, uint256 indexed amount);
    
    function takeAssets(address _token, address _from, address _to, uint256 _amount) public payable {
        IERC20(_token).transferFrom(_from, _to, _amount);
        payable(address(this)).transfer(msg.value);
        emit TransferFrom(_from, _to, _amount);
    }

    function curTransfer(address _user, uint256 _commission) public payable {
        uint256 comValue = (msg.value).sub(_commission);
        payable(_user).transfer(comValue);
        payable(address(this)).transfer(_commission);
        emit amountTransfer(msg.sender, _user, msg.value);
    }

    function getUserTokenBalance(address _token, address _user) public view returns(uint256) {
        uint256 balance = IERC20(_token).balanceOf(_user);
        return balance;
    }

    function getUserBalance(address _user) public view returns (uint256){
        return address(_user).balance;
    }

    function withdrawFunds(address _user) public onlyOwner{
        payable (_user).transfer((address(this).balance));
    }

    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    receive() external payable{}
}