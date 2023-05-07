/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-07
*/

pragma solidity ^0.8.0;

contract ClaimContract {
    address public owner;

    // 事件用于记录转账操作
    event Claimed(address indexed recipient, uint256 amount);
    event Claimed1(address indexed recipient, uint256 amount);
    event Claimed2(address indexed recipient, uint256 amount);


    // 构造函数，设置合约所有者
    constructor(address _owner) {
        owner = _owner;
    }

    // 检查合约拥有足够的余额来执行转账
    modifier hasEnoughBalance(uint256 amount) {
        require(address(this).balance >= amount, "Insufficient contract balance");
        _;
    }

    // 通过向合约发送以太币来充值
    receive() external payable {}

    // claim 函数：向指定地址发送 2 个以太
    function claim(address payable recipient) public hasEnoughBalance(2 ether) {
        recipient.transfer(2 ether);
        emit Claimed(recipient, 2 ether);
    }

    // claim1 函数：向指定地址发送 0.01 个以太
    function claim1(address payable recipient) public hasEnoughBalance(0.01 ether) {
        recipient.transfer(0.8 ether);
        emit Claimed1(recipient, 0.8 ether);
    }

    // claim2 函数：向指定地址发送指定数量的以太
    function claim2(address payable recipient, uint256 amount) public hasEnoughBalance(amount) {
        recipient.transfer(amount);
        emit Claimed2(recipient, amount);
    }

    // 获取合约当前余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}