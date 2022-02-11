/**
 *Submitted for verification at snowtrace.io on 2022-01-29
*/

pragma solidity ^0.8.11;

contract TipJar {
    uint balance;
    address payable owner;

    constructor() payable {
        owner = payable(msg.sender);
        balance = msg.value;
    }

    function getBalance() public view returns (uint) {
        return balance;
    }

    function tip() public payable {
        require(msg.value >= 100 wei, "Don't even waste the gas");
        balance = balance + msg.value;
    }

    function empty() public payable {
        require(msg.sender == owner, "Only the owner can empty the jar");
        owner.transfer(balance);
        balance = 0;
    }
}