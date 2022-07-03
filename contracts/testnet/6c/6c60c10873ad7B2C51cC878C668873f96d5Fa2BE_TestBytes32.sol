/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract TestBytes32 {

    bytes32[] array;

    function setBytes32(bytes32[] memory _array) external {
        array = _array;
    }
    

    function setBytes32() external view returns (bytes32[] memory)  {
        return array;
    }

}