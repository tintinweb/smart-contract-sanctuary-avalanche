/**
 *Submitted for verification at snowtrace.io on 2022-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {
    function balanceOf(address user) external view returns (uint256);
}

interface IJoetroller {
    function claimReward(uint8 rewardType, address user)
        external
        returns (uint256);
}

contract LensHelper {
    IERC20 public immutable joe;
    IJoetroller public immutable joetroller;

    constructor(IERC20 _joe, IJoetroller _joetroller) {
        joe = _joe;
        joetroller = _joetroller;
    }

    function getClaimableRewards(address[] calldata accounts)
        external
        returns (uint256[] memory joeAmounts, uint256[] memory avaxAmounts)
    {
        uint256 len = accounts.length;
        address account;
        joeAmounts = new uint256[](len);
        avaxAmounts = new uint256[](len);

        for (uint256 i; i < len; i++) {
            account = accounts[i];
            uint256 joeBefore = joe.balanceOf(account);
            joetroller.claimReward(0, account);
            joeAmounts[i] = joe.balanceOf(account) - joeBefore;

            uint256 avaxBefore = account.balance;
            joetroller.claimReward(1, account);
            avaxAmounts[i] = account.balance - avaxBefore;
        }
    }
}