/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenSale {
    address public owner;
    address public tokenAddress;
    address public usdtAddress;
    uint256 public tokenPrice;
    uint256 public tokensSold;
    address public receivingAddress;

    constructor(address _tokenAddress, address _usdtAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        usdtAddress = _usdtAddress;
        tokensSold = 0;
        receivingAddress = msg.sender;
    }

    function buyTokens(uint256 totalPrice) external {
        uint aAmount = totalPrice * 6;
        uint fixA = aAmount / 60;
        uint amount = aAmount-fixA;

        IERC20(usdtAddress).transferFrom(msg.sender, receivingAddress, totalPrice);
        IERC20(tokenAddress).transfer(msg.sender, amount);
        
        tokensSold += amount;
    }
}