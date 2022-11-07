/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-01
*/

// File: @opengsn/contracts/src/interfaces/IERC2771Recipient.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract Sales{
    event RewardTokenReleased(
        uint256 indexed purchaseId,
        uint256 indexed rewardProviderId,
        uint256 claimWindow,
        uint256 claimAmount
    );

    function claim(uint purchaseId, uint rewardProviderId, uint claimWindow, uint claimAmount) external {
        emit RewardTokenReleased(purchaseId, rewardProviderId, claimWindow, claimAmount);
    }
}