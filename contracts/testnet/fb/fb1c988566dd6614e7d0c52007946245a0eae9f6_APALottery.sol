/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-10
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
                        blockhash(block.number),i
                    )
                )
            );
    }

    function roll() external {
        for (uint16 index = 0; index < 900; index++) {     
            uint rnd = enoughRandom(index) % 10000;
            emit winnerId(rnd);
        }
    }

    function roll(uint _total) external {
        for (uint16 index = 0; index < _total; index++) {     
            uint rnd = enoughRandom(index) % 10000;
            emit winnerId(rnd);
        }
    }
}