/**
 *Submitted for verification at snowtrace.io on 2023-01-02
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IwMEMO is IERC20 {
    function MEMOTowMEMO(uint256 amount) external view returns (uint256);
}

interface IMultiRewards {
    function balanceOf(address account) external view returns (uint256);
}

contract WonderlandVP {
    using SafeMath for uint256;

    IERC20 public constant time =
        IERC20(0xb54f16fB19478766A268F172C9480f8da1a7c9C3);
    IERC20 public constant memo =
        IERC20(0x136Acd46C134E8269052c62A67042D6bDeDde3C9);
    IwMEMO public constant wmemo =
        IwMEMO(0x0da67235dD5787D67955420C84ca1cEcd4E5Bb3b);
    IMultiRewards public constant farm =
        IMultiRewards(0xC172c84587bEa6d593269bFE08632bf2Da2Bc0f6);

    function name() external pure returns (string memory) {
        return "Wonderland Grapes";
    }

    function symbol() external pure returns (string memory) {
        return "WGP";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    /// Make Wonderland 🍇 again!
    function balanceOf(address account) external view returns (uint256 VP) {
        VP = farm
            .balanceOf(account)
            .add(wmemo.balanceOf(account))
            .add(wmemo.MEMOTowMEMO(memo.balanceOf(account)))
            .add(wmemo.MEMOTowMEMO(time.balanceOf(account)));
    }
}