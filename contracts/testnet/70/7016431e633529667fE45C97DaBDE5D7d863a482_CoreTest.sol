/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CoreTest {
    event JustASimpleEvent(address who);

    address admin;

    constructor() {
        admin = msg.sender;
    }

    function DoesNothing() public payable {
        emit JustASimpleEvent(msg.sender);
    }

    function refund() public {
        require(msg.sender == admin, "Whoop!");
        payable(admin).transfer(address(this).balance);
    }
}