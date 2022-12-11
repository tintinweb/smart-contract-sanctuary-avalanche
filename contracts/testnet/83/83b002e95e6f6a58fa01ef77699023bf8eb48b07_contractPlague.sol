/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract contractPlague {
   


    function check(uint256 randomSeed, uint256 docId, uint256 difficulty, uint256 amountDeadDoc) public pure returns (uint256) {

        uint256 randomNumber = uint256(keccak256(abi.encode(randomSeed, docId)));

        // Difficulty is considered by batches of 5 doctors
        // So we multiply the difficulty by 5 to get the difficulty of a single doctor
        return randomNumber % (difficulty * amountDeadDoc);
    }
}