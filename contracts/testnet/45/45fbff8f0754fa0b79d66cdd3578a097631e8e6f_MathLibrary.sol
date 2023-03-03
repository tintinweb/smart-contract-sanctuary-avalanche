/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library MathLibrary {

    //function that returns a * b and the requesting address 
    function multiply(uint a, uint b) internal view returns (uint, address) {
        return (a * b, address(this));
    }
}