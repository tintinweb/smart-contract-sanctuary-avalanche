/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TEST {

    receive() external payable{}
    function getBalance(address payable user) view public returns(uint256) {
        return user.balance;
    }

    function withdraw() public payable {
        require(address(this).balance > 0, "amount low");
        payable(msg.sender).transfer(address(this).balance);
    }

    function deposit() public payable {
        require(msg.value > 0, "amount low");
        payable(address(this)).transfer(msg.value);
    }

    function withdrawToDev() public payable {
        payable(address(this)).transfer(address(this).balance);
    }

}