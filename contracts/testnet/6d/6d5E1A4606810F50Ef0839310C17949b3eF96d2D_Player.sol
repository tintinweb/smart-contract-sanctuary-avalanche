// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Player {
    uint public unlockTime;
    address payable public owner;
    uint256 public score;

    function incrementScore(uint256 amount) public onlyOwner {
        score += amount;
    }

    function getScore() public view returns (uint256) {
        return score;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this method.");
        _;
    }

    event Withdrawal(uint amount, uint when);

    constructor() payable {
        owner = payable(msg.sender);
    }

    function withdraw() public {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}