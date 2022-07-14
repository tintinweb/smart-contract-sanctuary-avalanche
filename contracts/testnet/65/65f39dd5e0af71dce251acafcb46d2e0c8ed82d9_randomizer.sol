/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

contract randomizer{

    function randomSeed(uint256 _seed) view external returns (uint256){

        return uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 4),
                    tx.origin,
                    blockhash(block.number - 2),
                    blockhash(block.number - 3),
                    blockhash(block.number - 1),
                    _seed,
                    block.timestamp
                )
            )
        );

    }

}