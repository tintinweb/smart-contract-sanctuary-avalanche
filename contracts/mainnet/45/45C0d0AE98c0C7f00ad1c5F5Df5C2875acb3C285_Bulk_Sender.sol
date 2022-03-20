/**
 *Submitted for verification at snowtrace.io on 2022-03-20
*/

//SPDX-License-Identifier: Unlicense

pragma solidity >=0.7.0 <0.9.0;

contract Bulk_Sender {

    function sendToMultiple(address[] calldata recipients, uint256 amount) public payable {
        for (uint256 i = 0; i < recipients.length; i ++) {
            payable(recipients[i]).transfer(amount);
        }
    }
}