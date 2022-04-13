/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract APALottery {
    event winnerId(uint id);

    function enoughRandom(uint16 i) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        // solhint-disable-next-line
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number-1),i
                    )
                )
            );
    }

    function getSeed() external {
            uint rnd = enoughRandom(42);
            emit winnerId(rnd);
        
    }

}