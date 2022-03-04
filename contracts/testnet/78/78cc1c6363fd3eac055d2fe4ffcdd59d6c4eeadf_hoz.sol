/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-04
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
 
contract hoz {
    uint256 private value;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}