/**
 *Submitted for verification at snowtrace.io on 2022-05-01
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

contract BreedingSeed{
    function getSeed(uint256 tokenId) external view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        // solhint-disable-next-line
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number-1),
                        tokenId
                    )
                )
            );
    }

}