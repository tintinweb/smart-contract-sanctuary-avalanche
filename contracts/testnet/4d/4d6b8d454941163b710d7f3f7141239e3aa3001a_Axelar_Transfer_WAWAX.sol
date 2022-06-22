/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-22
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

contract Axelar_Transfer_WAWAX {

    address constant token = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

    function execTransfer(address _deposit_address, uint256 _amount) public {

        require(IERC20(token).balanceOf(msg.sender)>=_amount, "Not Enough Tokens");
        require(IERC20(token).allowance(msg.sender, address(this))>=_amount, "Not Enough Allowance");

        IERC20(token).transferFrom(msg.sender, _deposit_address, _amount);
    }
}