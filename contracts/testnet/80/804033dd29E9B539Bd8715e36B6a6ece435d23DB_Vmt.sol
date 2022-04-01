/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract Vmt {
    event Message(address indexed from, address indexed to, string message);

    function sendMessage1(address _to, string memory _message) external payable {
        address payable to = payable(_to);
        _to.call{value: msg.value/2}("test1");
    }

    function sendMessage2(address _to, string memory _message) external {
        emit Message(msg.sender, _to, _message);
    }
}