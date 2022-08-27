/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

contract RandomNumberTest {
    // uint256 randomSeed;

    // function setRandomSeed(uint256 _seed) external {
    //     randomSeed = _seed;
    // }

    function _getRandomNumbers(uint256 start, uint256 ranEnd, uint256 randomSeed) external view returns(uint256) {
        uint256 tempNumber = uint256(keccak256(abi.encode(randomSeed, start, block.timestamp))) % ranEnd + 1;
        return tempNumber;
    }
}