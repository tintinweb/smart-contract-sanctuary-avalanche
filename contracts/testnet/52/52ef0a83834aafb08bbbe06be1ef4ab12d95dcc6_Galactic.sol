/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract Galactic {
    // name it: spaceship generated?
    // todo: earth address for some reason is hashed
    event NonceGenerated(
        string indexed earthAddress, address indexed moonAddress, uint256 indexed fare);

    // todo: use bytes
    function generateNonce(string memory earthAddress) public {
        // todo validate length of earthAddress, maybe even pass min length as a parameter
        // also pass the symbol as a parameter?

        // todo simulating randomness here, but in reality this should be done via
        // chainlink VRF
        uint randomFee = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        // this is max + min and min. todo: parameterize
        randomFee = (randomFee % 100000) + 10;
        emit NonceGenerated(earthAddress, msg.sender, randomFee);
    }
}