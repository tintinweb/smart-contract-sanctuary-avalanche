// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Secret {
    address public owner;
    string private password;

    constructor(string memory _password) {
        owner = msg.sender;
        password = _password;
    }

    function Password() public view returns (string memory) {
        require(msg.sender == owner, "! owner");
        return password;
    }
}