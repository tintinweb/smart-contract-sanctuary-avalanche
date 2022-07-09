/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Factory { 
    // Computes the address of a newly deployed contract 
    function deploy( 
        address _owner, 
        uint _foo, 
        bytes32 _salt 
    ) public payable returns (address) { 

        // This syntax utilizes the latest approach to compute the contract address 
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2 
        return address(new SimpleContract{salt: _salt}(_owner, _foo)); 

    } 
} 

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