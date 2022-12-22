// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract {

    event Checked(address user, uint256 amount);
    function checkIn(uint256 amount) public payable {
        emit Checked(msg.sender, amount);
    }
}