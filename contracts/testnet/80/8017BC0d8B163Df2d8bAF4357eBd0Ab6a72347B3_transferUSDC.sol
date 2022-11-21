/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface USDC {

    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract transferUSDC {
    USDC public USDc;
    address owner;
    mapping(address => uint) public stakingBalance;

    constructor() {
        USDc = USDC(0x3E937B4881CBd500d05EeDAB7BA203f2b7B3f74f);
        owner = msg.sender;
    }
    function depositTokens(uint $USDC) public {

        // amount should be > 0

        // transfer USDC to this contract
        USDc.transferFrom(msg.sender, address(this), $USDC);
        
        // update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + $USDC;
    }
    // Unstaking Tokens (Withdraw)
    function withdrawalTokens() public {
        uint balance = stakingBalance[msg.sender];

        // balance should be > 0
        require (balance > 0, "staking balance cannot be 0");

        // Transfer USDC tokens to the users wallet
        USDc.transfer(msg.sender, balance);

        // reset balance to 0
        stakingBalance[msg.sender] = 0;
    }
}