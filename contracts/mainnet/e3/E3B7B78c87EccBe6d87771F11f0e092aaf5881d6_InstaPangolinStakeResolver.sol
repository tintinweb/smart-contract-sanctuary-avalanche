// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "./interfaces.sol";

contract Resolver {
    address public constant miniChefV2Addr = 0x1f806f7C8dED893fd3caE279191ad7Aa3798E928;
    IMiniChefV2 public constant miniChefV2 = IMiniChefV2(miniChefV2Addr);

    /// @notice Explain to an end user what this does
    /// @param lpAddress address of lp Token
    /// @param pid id of lp Token in MiniChefV2
    /// @param stakedAmount total amount of lp token deposited in stake by address in MiniChefV2
    /// @param pendingReward amount of rewards to claim
    /// @param totalStaked total of staked lp Token in MiniChefV2
    struct LPStakeData {
        address lpAddress;
        uint256 stakedAmount;
        uint256 pendingReward;
        uint256 totalStaked;
    }
    /// @notice Explain to an end user what this does
    /// @param stakedAmount total amount of PNG deposited in stake by address
    /// @param pendingReward amount of rewards to claim
    /// @param rewardToken address of reward token
    /// @param totalStaked total of PNG staked in contract
    struct PNGStakeData {
        uint256 stakedAmount;
        uint256 pendingReward;
        address rewardToken;
        uint256 totalStaked;
    }

    /// @notice Get Data of stake lp token
    /// @param account address of account
    /// @param pid id of lp Token in MiniChefV2
    /// @return lpStakeData struct of type LPStakeData
    function getLPStakeData(address account, uint256 pid) public view returns (LPStakeData memory lpStakeData) {
        IERC20 lpToken = miniChefV2.lpToken(pid);
        IMiniChefV2.UserInfo memory userInfo = miniChefV2.userInfo(pid, account);
        lpStakeData = LPStakeData(
            address(lpToken),
            userInfo.amount,
            miniChefV2.pendingReward(pid, account),
            lpToken.balanceOf(miniChefV2Addr)
        );
    }

    /// @notice Get pid of lpToken address
    /// @param lpTokenAddr address of lpToken
    /// @return pid id of lp Token in MiniChefV2
    /// @return success true if is added in MiniChefV2 else false
    /// @dev success == false, is invalid lp token
    function getPIDbyLPAddress(address lpTokenAddr) public view returns (uint256 pid, bool success) {
        bool added = miniChefV2.addedTokens(lpTokenAddr);
        pid = 0;
        success = false;
        if (!added) {
            return (pid, success);
        }
        for (uint256 index = 0; index < miniChefV2.poolLength(); index++) {
            if (address(miniChefV2.lpToken(index)) == lpTokenAddr) {
                pid = index;
                success = true;
                return (pid, success);
            }
        }
        return (pid, success);
    }

    /// @notice Get Data of stake PNG stake
    /// @param account address of account
    /// @param contractAddr address of staking contract
    /// @return pngStakeData struct of type LPStakeData
    function getPNGStakeData(address account, address contractAddr)
        public
        view
        returns (PNGStakeData memory pngStakeData)
    {
        IStakingRewards stakingContact = IStakingRewards(contractAddr);
        pngStakeData = PNGStakeData(
            stakingContact.balanceOf(account),
            stakingContact.rewards(account),
            stakingContact.rewardsToken(),
            stakingContact.totalSupply()
        );
    }
}

contract InstaPangolinStakeResolver is Resolver {
    string public constant name = "Pangolin-Stake-Resolver-v1";
}