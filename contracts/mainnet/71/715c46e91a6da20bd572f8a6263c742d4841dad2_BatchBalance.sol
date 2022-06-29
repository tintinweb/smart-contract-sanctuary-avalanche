/**
 *Submitted for verification at snowtrace.io on 2022-06-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

interface IERC20 {
    function balanceOf(address user) external view returns (uint256);
}

contract BatchBalance{
    function balancesOf(IERC20 token, address[] calldata addresses) external view returns (uint256[] memory balances) {
        uint256 len = addresses.length;
        balances = new uint256[](len);

        for (uint256 i; i < len; i++) {
            balances[i] = token.balanceOf(addresses[i]);
        }
    }
}