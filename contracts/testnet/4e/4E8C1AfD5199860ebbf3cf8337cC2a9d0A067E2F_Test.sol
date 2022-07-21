/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract Test {

    string public owner;

    constructor(string memory _str) {
        owner = _str;
    }

    function get(string calldata _str) external pure returns(bytes memory) {
        return abi.encode(_str);
    }

}