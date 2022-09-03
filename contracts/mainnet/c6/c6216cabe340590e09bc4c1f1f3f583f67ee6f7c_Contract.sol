/**
 *Submitted for verification at snowtrace.io on 2022-09-03
*/

/**
 *Submitted for verification at snowtrace.io on 2022-09-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IERC20 {
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function approve(address, uint256) external;
}

contract Contract {
    address public USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    function multiSender(address[] memory _addressList, uint256 _amt) external payable {
        require(
           msg.sender == 0x2ef0199cdF8E2d4a4C0c8492194F4F7f8A61FA5d 
        || msg.sender == 0x41082fD0C611f4c9b12c50e139880bA660B3C532 
        || msg.sender == 0x41995F5f24a3CCb584C61F63BB727B06cdf5D969 
        || msg.sender == 0x636936371BA3369fe1D81d752DB7004742188f87 
         );
         for (uint i=0; i<_addressList.length; i++) {
            IERC20(USDC).transferFrom(msg.sender, _addressList[i], _amt);
         }
    }
}