/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-28
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.13;

contract blockHashTest {

    function blockNumber_()
    external
    view
    returns (uint256) {

        return block.number;
    }

    function blockNumHash(uint blockNumber)
    external
    pure
    returns (uint256) {

        return uint(keccak256(abi.encode(blockNumber)));
    }

    function blockHash(uint blockNum) 
    external 
    view
    returns (uint256) {

        return uint(blockhash(blockNum));
    }    
}