/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

contract Test {

    address immutable public ownerAddress;
    uint immutable public timeT1;

    constructor() {
        ownerAddress = msg.sender;
        timeT1 = block.timestamp;
    }

}