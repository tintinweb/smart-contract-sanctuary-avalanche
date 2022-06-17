/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract XanFlag {
    uint256 private password;
    address public winer;

    constructor (uint256 password_) {
        password = password_;
    }

    function guess(uint256 _password) external {
        require(_password == password, "Wrong password!");
        winer = msg.sender;
    }
}