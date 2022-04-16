/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Compras {
    uint public value = 1.5 ether;

    function setValue(uint256 _newCost) public {
        value = _newCost * 1 wei; }

    function getValue() public view returns (uint256) {
        return value; }

    function Purchase() public payable {
        require(msg.value >= value, "Incorrect Cost");
        value = msg.value; 
    }
}