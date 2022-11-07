/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BuyContract {
    address public bank;
    address public owner;

    constructor (address _owner) payable {
        bank = msg.sender;
        owner = _owner;
    }
}
contract Factory {
    BuyContract[] public accounts;
    function createAccount(address _owner) external payable {
        BuyContract account = new BuyContract{value: 111}(_owner);
        accounts.push(account);
    }
}