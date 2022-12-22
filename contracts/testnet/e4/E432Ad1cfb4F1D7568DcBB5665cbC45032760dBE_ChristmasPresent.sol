/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ChristmasPresent {
    // Set the unlock time to Christmas 2022 (Paris time)
    uint256 public unlockTime = 1671922800;

    address payable public owner;

    event Withdrawal(uint amount, uint when);

    constructor() payable {
        require(
            block.timestamp < unlockTime,
            "Contract should be deployed before Christmas"
        );

        owner = payable(msg.sender);
    }

    function withdraw() public {
        require(
            block.timestamp >= unlockTime,
            "You can't open your present before Christmas"
        );
        require(
            msg.sender == owner,
            "You aren't the recipient of this present"
        );

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}