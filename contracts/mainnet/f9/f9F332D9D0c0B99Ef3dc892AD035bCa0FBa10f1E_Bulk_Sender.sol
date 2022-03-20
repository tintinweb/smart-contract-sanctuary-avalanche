/**
 *Submitted for verification at snowtrace.io on 2022-03-20
*/

//SPDX-License-Identifier: Unlicense

pragma solidity >=0.7.0 <0.9.0;

contract Bulk_Sender {

    struct Entry {
        address recipient;
        uint256 amount;
    }

    function sendToMultiple(Entry[] calldata entries) public payable {
        // 0xaddress,0.15ether
        // 0xaddress,0.15ether
        // 0xaddress,0.15ether
        for (uint256 i = 0; i < entries.length; i ++) {
            payable(entries[i].recipient).transfer(entries[i].amount);
        }
    }
}