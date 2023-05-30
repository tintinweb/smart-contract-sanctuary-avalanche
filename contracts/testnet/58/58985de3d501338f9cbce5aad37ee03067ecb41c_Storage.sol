/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
/**
 * @title Storage Yahaya First Smart Contract
 */
contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}