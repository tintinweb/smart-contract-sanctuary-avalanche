/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-25
*/

pragma solidity 0.8.0;


// SPDX-License-Identifier: MIT LICENSE
interface IRandomizer {
    function getRandomAvatar() external returns (uint256);
}

contract Randomizer is IRandomizer {
    uint16[] private _buffer;

    constructor(uint16 amount) {
        for(uint16 i = 0; i < amount; i ++) {
            _buffer.push(i);
        }
    }

    function getRandomAvatar() external override returns (uint256) {
        require(_buffer.length > 0, "No NFT exist");

        uint256 randIdx;
        uint256 randNum;
        
        randIdx = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % (_buffer.length);
        randNum = _buffer[randIdx];
        _buffer[randIdx] = _buffer[_buffer.length - 1];
        _buffer.pop();

        return randNum + 1; //random number from 1 ~ 1000
    }
}