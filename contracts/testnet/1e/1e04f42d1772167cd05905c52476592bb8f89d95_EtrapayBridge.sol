/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-31
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-30
*/

// SPDX License Identifier: MIT

pragma solidity ^0.8.0;


contract EtrapayBridge {
    event Deposit(address indexed from, uint256 amount, uint256 date);
    address constant public EtraAddress = 0x1C39E9982CF6d443BFA17c7D17Ca534469fC5982;
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

    function EtraWithdraw(uint256 _amount) public payable {
        require(msg.sender == EtraAddress);
        (bool sent, bytes memory data) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

}