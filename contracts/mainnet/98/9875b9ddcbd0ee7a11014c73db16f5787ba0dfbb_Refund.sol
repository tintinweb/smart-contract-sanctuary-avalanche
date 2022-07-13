/**
 *Submitted for verification at snowtrace.io on 2022-07-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Refund Presale
*
/******************************************************************************/

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface Presale {
    function balanceOf(address _of) external view returns (uint256);
}

contract Refund {
    Presale public constant presaleContract = Presale(0x52717F142C06A8287a1672B3189B544cAA77147e);
    IERC20 public constant USDC = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);

    mapping(address => bool) claimees;

    function claimRefund() public {
        require(claimees[msg.sender] != true, "Already claimed refund.");
        claimees[msg.sender] = true;

        uint256 balance = presaleContract.balanceOf(msg.sender);
        uint256 amountToRefund = balance * 200;

        USDC.transferFrom(0xa6c020e66e7f2A85F26c59178403F56b1dF08D98, msg.sender, amountToRefund * (1 * 10 ** 6));
    }

    function refundAmount() public view returns (uint256) {
        uint256 balance = presaleContract.balanceOf(msg.sender);
        uint256 amountToRefund = balance * 200;

        return amountToRefund;
    }
}