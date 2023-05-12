/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-11
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract FlagStorage {
    bytes32 public flag;
    bool public stored;
    event Stored(bool status);
    function storeFlag(string calldata _flag) external {
        require(!stored, "Flag Already stored");
        flag = keccak256(abi.encodePacked(_flag));
        stored = true;
        emit Stored(stored);
    }
}