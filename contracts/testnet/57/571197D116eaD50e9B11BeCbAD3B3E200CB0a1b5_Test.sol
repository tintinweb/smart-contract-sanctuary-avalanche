/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

contract Test {

    string public ownerName;
    address immutable public ownerAddress;

    constructor(string memory _name) {
        ownerName = _name;
        ownerAddress = msg.sender;
    }

    function changeName(string calldata _newName) external {
        require(msg.sender == ownerAddress, "only owner have access sir!");

        ownerName = _newName;
    }

}