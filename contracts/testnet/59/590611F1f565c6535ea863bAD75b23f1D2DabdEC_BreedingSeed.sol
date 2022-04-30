/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-29
*/

// File: contracts/BreedingSeed.sol


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