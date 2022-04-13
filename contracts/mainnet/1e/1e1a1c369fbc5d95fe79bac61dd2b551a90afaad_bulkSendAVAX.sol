/**
 *Submitted for verification at snowtrace.io on 2022-04-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract bulkSendAVAX {
    function sendToUsers(address[] calldata users, uint256 userValue) payable external {
      for (uint256 i = 0; i < users.length; i++) {
        payable(users[i]).transfer(userValue);
      }
      // Transfer back any remaining balance
      payable(msg.sender).transfer(address(this).balance);
    }
}