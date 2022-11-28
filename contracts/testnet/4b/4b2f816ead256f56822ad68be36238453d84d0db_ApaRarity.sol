// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ApaRarity {
    mapping (uint => uint) tokenRarity;
    mapping (uint => bytes32) tokenRarityGroup;

    function setRarity(uint rarity, uint tokenId) public {
        tokenRarity[tokenId] = rarity;
    }

    constructor() {}

    function setRarityMultiple(uint[]  calldata rarity, uint[] calldata tokenIds) public {
        uint len = rarity.length;
        for(uint i; i < len;) {
            tokenRarity[tokenIds[i]] = rarity[i];
            unchecked {
                ++i;
            }
        }
    }

    function getRarity(uint tokenId) public view returns (uint) {
        uint groupNumber = tokenId / 32;
        uint bytenumber = tokenId % 32;
        bytes32 x =  tokenRarityGroup[groupNumber];
        uint rarity = uint8(x[bytenumber]);
        return rarity;
    }

    function setRarityBytes(uint groupNumber, bytes32 rarityBytes) external {
        tokenRarityGroup[groupNumber] = rarityBytes;
    }

    function setRarityBytesBatch(uint[] calldata groupNumbers, bytes32[] calldata rarityBytes) external {
        uint len = groupNumbers.length;
        for(uint i; i < len;) {
            tokenRarityGroup[groupNumbers[i]] = rarityBytes[i];
            unchecked {
                ++i;
            }
        }
    }

}