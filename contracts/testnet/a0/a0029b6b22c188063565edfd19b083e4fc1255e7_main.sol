/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

interface IRandomizer {
    function randomSeed(uint256 tokenId) view external returns (uint256);
}

contract main {
    IRandomizer public randomizer;

    function setRandomizer(address _rand) external{
        randomizer = IRandomizer(_rand);
    }

    function getRandom() view external returns (uint256){
        uint256 seed;
        seed = randomizer.randomSeed(1);

        return seed;
    }
    
}