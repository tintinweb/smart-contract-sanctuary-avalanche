/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-05
*/

// contracts/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
 

contract hozv2  {
    uint256 private value;
	uint256 private lastStoreTime;
	//uint256 public timenow= block.timestamp;
 
 
	
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
		lastStoreTime=block.timestamp;
        emit ValueChanged(newValue);
    }
    
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
    
    // Increments the stored value by 1
    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }
	
	function autoincrement() public {
       if (block.timestamp > lastStoreTime+5) {
		value = value + 1;
		emit ValueChanged(value);
		}
        
    }
	
}