/**
 *Submitted for verification at snowtrace.io on 2022-04-18
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IwMEMO is IERC20 {
    function wMEMOToMEMO(uint256 amount) external view returns(uint256);
}

interface IMultiRewards {
    function balanceOf(address account) external view returns (uint256);
}

contract TimePowerAddV1 {
    IwMEMO public constant wMEMO = IwMEMO(0x0da67235dD5787D67955420C84ca1cEcd4E5Bb3b);
    IMultiRewards public constant mR = IMultiRewards(0xC172c84587bEa6d593269bFE08632bf2Da2Bc0f6);

    function name() external pure returns (string memory) { return "TIMEPOWER"; }
    function symbol() external pure returns (string memory) { return "TIMEPOWER"; }
    function decimals() external pure returns (uint8) { return 9; }
    function allowance(address, address) external pure returns (uint256) { return 0; }
    function approve(address, uint256) external pure returns (bool) { return false; }
    function transfer(address, uint256) external pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure returns (bool) { return false; }

    /// @notice Returns SUSHI voting 'powah' for `account`.
    function balanceOf(address account) external view returns (uint256 time_powah) {
        uint256 staked_balance = mR.balanceOf(account);
        time_powah =  wMEMO.wMEMOToMEMO(staked_balance);
    }
}