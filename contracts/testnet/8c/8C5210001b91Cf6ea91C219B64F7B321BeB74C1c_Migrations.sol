// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// contract TestCode {
//     uint256 public lockUntil;

//     constructor() {
//         lockUntil = block.timestamp + 70 days;
//     }
// }
pragma solidity >=0.7.0 <0.9.0;

contract Migrations {
    address public owner;
    uint256 public last_completed_migration;

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }

    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}