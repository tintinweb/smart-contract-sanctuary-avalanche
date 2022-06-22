/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-22
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

contract Axelar_Transfer {

    address constant wavax = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

    event AxelarTransfer(string _dest_address, address _deposit_address, uint256 _amount);

    function setTransfer(string memory _dest_address, address _deposit_address, uint256 _amount) public {

        require(IERC20(wavax).balanceOf(msg.sender)>=_amount, "Not Enough Tokens");
        require(IERC20(wavax).allowance(msg.sender, address(this))>=_amount, "Not Enough Allowance");

        IERC20(wavax).transferFrom(msg.sender, _deposit_address, _amount);
        emit AxelarTransfer(_dest_address, _deposit_address, _amount);
    }
}