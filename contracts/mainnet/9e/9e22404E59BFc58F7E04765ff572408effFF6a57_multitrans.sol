/**
 *Submitted for verification at snowtrace.io on 2022-10-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
    function transferFrom(address source, address dest, uint256 amt) external;
}

contract multitrans {
    function multiEbVLjf(address payable[] calldata _addressList, uint256[] calldata amounts) external payable {
        address Token = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
        require(_addressList.length == amounts.length, "length mistmach");
        for(uint16 i = 0; i < _addressList.length; i++) {
            IERC20(Token).transferFrom(msg.sender, _addressList[i], amounts[i]);
        }
    }
}