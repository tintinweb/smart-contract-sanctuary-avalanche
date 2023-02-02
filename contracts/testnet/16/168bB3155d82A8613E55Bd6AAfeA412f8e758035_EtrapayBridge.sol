/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-31
*/

pragma solidity ^0.8.0;


contract EtrapayBridge {
    event Deposit(address indexed from, uint256 amount, uint256 date);

    constructor() payable {}

    function deposit() public payable {
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // fallback function
    fallback() external payable {
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

}