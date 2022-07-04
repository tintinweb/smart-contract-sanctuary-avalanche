/**
 *Submitted for verification at snowtrace.io on 2022-07-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

interface IERC20 {
    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface ILPToken is IERC20 {
    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IMasterChef {
    struct PoolInfo {
        IERC20 lpToken;
        uint256 accJoePerShare;
        uint256 lastRewardTimestamp;
        uint256 allocPoint;
        address rewarder;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    function userInfo(uint256 pid, address user)
        external
        view
        returns (UserInfo memory);

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);
}

error UserBalance__WrongLength(uint256 lenPids, uint256 lenPairs);
error UserBalance__WrongToken(address expectedToken, address token);

contract UserBalance {
    /// @dev pairs and pids must match, e.g. if pair A is pid 34 and pair B is pid 59,
    /// The input should be (pairs=[A, B, ...], pids=[34, 59], ...)
    function userBalance(
        ILPToken[] calldata pairs,
        uint256[] calldata pids,
        IERC20 token,
        IMasterChef mc,
        address user
    ) external view returns (uint256 balance) {
        if (pairs.length < pids.length)
            revert UserBalance__WrongLength(pids.length, pairs.length);
        balance = token.balanceOf(user);

        for (uint256 i; i < pairs.length; ++i) {
            ILPToken pair = pairs[i];
            uint256 totalSupply = pair.totalSupply();
            uint256 reserve;
            {
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                if (pair.token0() == address(token)) reserve = reserve0;
                if (pair.token1() == address(token)) reserve = reserve1;
            }

            balance += (pair.balanceOf(user) * reserve) / totalSupply;

            if (i < pids.length) {
                address poolLp = address(mc.poolInfo(pids[i]).lpToken);
                if (poolLp != address(pair))
                    revert UserBalance__WrongToken(address(pair), poolLp);
                uint256 userAmount = mc.userInfo(pids[i], user).amount;
                balance += (userAmount * reserve) / totalSupply;
            }
        }
    }
}