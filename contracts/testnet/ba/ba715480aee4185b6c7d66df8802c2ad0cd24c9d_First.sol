/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract First {
    address payable public me;

    constructor() payable {
        me = payable(msg.sender);
    }

    function changeOwner(address payable _newMe) public {
        require(msg.sender == me, "Only the current owner can change the payout address");
        me = _newMe;
    }

    function payMe() public {
        me.transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

}