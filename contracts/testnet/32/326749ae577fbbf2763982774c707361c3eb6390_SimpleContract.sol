/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SimpleContract {
    address public owner;
    uint public foo;

    constructor(address _owner, uint _foo) payable {
        owner = _owner;
        foo = _foo;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}