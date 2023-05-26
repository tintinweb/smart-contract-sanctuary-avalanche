/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;


contract FavNumber {

    struct User {
        string name;
        uint favNumber;
    }

    mapping (address => User) public users;

    event NewNumber(address from, uint number);

    function setFavNumber(uint _number) public {
        users[msg.sender].favNumber = _number;

        emit NewNumber(msg.sender, _number);
    }
    

}