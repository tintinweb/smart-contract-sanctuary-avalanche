/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

contract Test3 {

    string public ownerName;
    address immutable public ownerAddress;
    uint immutable public time;

    constructor() {
        ownerAddress = msg.sender;
        time = block.timestamp;
    }

}