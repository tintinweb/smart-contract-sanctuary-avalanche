/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; 

contract SimpleStorage {
    uint256 public favoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
}

// Contract address = 0xD7ACd2a9FD159E69Bb102A1ca21C9a3e3A5F771B