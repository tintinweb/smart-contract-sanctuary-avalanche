/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract EthBank {
    mapping(address => uint) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external payable {
        (bool sent, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(sent, "failed to send ETH");

        balances[msg.sender] = 0;
    }
}