/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-13
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/MyMad.sol



pragma solidity >=0.7.0 <0.9.0;


contract MyMad {

    mapping(uint256 => uint256) public _indexer;
    uint256 public constant MAX_SUPPLY = 6666;
    uint256 public _indexerLength = MAX_SUPPLY;
    uint256 public totalSupply = 0;
    mapping(uint256 => uint256) public tokenIDMap;

    constructor() {
        for (uint256 i = 0; i < 6; i++) {
            tokenIDMap[i] = getNextImageID(i + 1);
            totalSupply++;
        }
    }

    function bok(uint256 amount, address addy, uint256 timestamp) public {
        for (uint256 i = 0; i < amount; i++) {
            enoughRandom(addy, timestamp);
        }
    }

    function enoughRandom(address addy, uint256 timestamp) internal {
        uint256 diff = 1;
        bytes32 internalHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        uint256 firstIndex =
            uint256(
                keccak256(
                    abi.encodePacked(
                        diff,
                        timestamp,
                        addy,
                        internalHash
                    )
                )
            ) % (_indexerLength);

        tokenIDMap[totalSupply] = getNextImageID(firstIndex);
        totalSupply++;
    }

    function getNextImageID(uint256 index) internal returns (uint256) {
        uint256 nextImageID = _indexer[index];

        if (nextImageID == 0) {
            nextImageID = index;
        }
        if (_indexer[_indexerLength - 1] == 0) {
            _indexer[index] = _indexerLength - 1;
        } else {
            _indexer[index] = _indexer[_indexerLength - 1];
        }
        _indexerLength -= 1;
        return nextImageID;
    }

}