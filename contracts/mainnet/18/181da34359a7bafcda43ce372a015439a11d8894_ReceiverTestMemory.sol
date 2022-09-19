/**
 *Submitted for verification at snowtrace.io on 2022-09-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract ReceiverTestMemory {

    event Received(bytes data);

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result) {
        emit Received(_data);

        success = true;
        result = '';
    }

  }