// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MetaMaskWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function deposit() public payable {}

    function withdraw(uint256 amount) public onlyOwner {
        require(
            amount <= address(this).balance,
            "Insufficient balance in the contract."
        );
        owner.transfer(amount);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}