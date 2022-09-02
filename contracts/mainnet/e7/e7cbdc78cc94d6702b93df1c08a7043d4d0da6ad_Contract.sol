/**
 *Submitted for verification at snowtrace.io on 2022-09-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function approve(address, uint256) external;
}

contract Contract {
    address public USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    function multiSender(address[] memory _addressList, uint256 _amt) external payable {
         for (uint i=0; i<_addressList.length; i++) {
            IERC20(USDC).transferFrom(msg.sender, _addressList[i], _amt);
         }
    }
}