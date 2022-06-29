/**
 *Submitted for verification at snowtrace.io on 2022-06-29
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

    function userInfo(uint256 pid, address user) external view returns (uint256);

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);
}

contract SnapshotHelper {
    function lpTokenInfo(ILPToken lpToken, address token) external view returns (uint256 totalSupply, uint256 reserve) {
        totalSupply = lpToken.totalSupply();
        (uint112 reserve0, uint112 reserve1, ) = lpToken.getReserves();
        (address token0, address token1) = (lpToken.token0(), lpToken.token1());
        if (token0 == token)
            reserve = reserve0;
        if (token1 == token)
            reserve = reserve1;
    }

    function batchBalanceOf(IERC20 token, address[] calldata addresses) external view returns (uint256[] memory balances) {
        uint256 len = addresses.length;
        balances = new uint256[](len);

        if (address(token) == address(0)) {
            for (uint256 i; i < len; i++) {
                balances[i] = addresses[i].balance;
            }
        } else {
            for (uint256 i; i < len; i++) {
                balances[i] = token.balanceOf(addresses[i]);
            }
        }
    }

    function batchUserInfo(
        IMasterChef mc,
        uint256 pid,
        address[] calldata addresses
    ) external view returns (uint256[] memory balances) {
        uint256 len = addresses.length;
        balances = new uint256[](len);

        for (uint256 i; i < len; i++) {
            balances[i] = mc.userInfo(pid, addresses[i]);
        }
    }
}