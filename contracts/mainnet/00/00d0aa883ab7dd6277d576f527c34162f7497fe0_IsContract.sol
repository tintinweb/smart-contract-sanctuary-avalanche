/**
 *Submitted for verification at snowtrace.io on 2022-05-28
*/

// "SPDX-License-Identifier: MIT"
pragma solidity ^0.8.0;

// --- MAIN CONTRACT ---
contract IsContract {
  
    function batch_check_contract(address[] memory addresses_to_check) public view returns (bool[] memory) {
        bool[] memory is_contract = new bool[](addresses_to_check.length);
        for (uint32 u = 0; u < addresses_to_check.length; u++) {
        is_contract[u] = this.checkContract(addresses_to_check[u]);
        }
        return is_contract;
    }

    function checkContract(address addr) public view returns (bool) {
        bytes32 accountHash =  
        0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;                                                                                             
        bytes32 codehash;
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
  
}