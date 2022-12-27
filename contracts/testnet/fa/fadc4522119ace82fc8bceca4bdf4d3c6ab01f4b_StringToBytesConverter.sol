/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;


contract StringToBytesConverter {
    function stringToBytes(string calldata str) public pure returns (bytes memory) {
        return abi.encodePacked(str);
    }
}