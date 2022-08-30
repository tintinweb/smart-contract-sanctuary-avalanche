//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

library Bytes32Lib {
    function len(bytes32 _string) public pure returns (uint256) {
        bytes1 empty = bytes1("");

        uint256 nonEmptyLength;

        for (uint256 index = 0; index < _string.length; index++) {
            if (_string[index] != empty) {
                nonEmptyLength++;
            }
        }

        return nonEmptyLength;
    }
}