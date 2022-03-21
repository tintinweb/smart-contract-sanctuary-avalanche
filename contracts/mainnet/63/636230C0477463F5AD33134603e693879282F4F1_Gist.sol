/**
 *Submitted for verification at snowtrace.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract Gist {
    address public firstMsgSender;
    address public secondMsgSender;

    function updateFirstMsgSender() external {
        firstMsgSender = msg.sender;
        this.updateSecondMsgSender();
    }

    function updateSecondMsgSender() external {
        secondMsgSender = msg.sender;
    }
}