/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool); 

}

contract TokenSale {
    address public owner;
    address public tokenAddress;
    address public usdtAddress;
    uint256 public tokenPrice;
    uint256 public tokensSold;
    address public receivingAddress;
    mapping(address => bool) public whitelist;

    constructor(address _tokenAddress, address _usdtAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        usdtAddress = _usdtAddress;
        tokensSold = 0;
        receivingAddress = msg.sender;
    }

    function buyTokens(uint256 totalPrice) external {
    require(whitelist[msg.sender], "Not whitelisted"); // Check if the buyer is whitelisted
    require(totalPrice >= 50 && totalPrice <= 2000, "Invalid totalPrice"); // Check if totalPrice is within the allowed range

    uint256 aAmount = totalPrice * 6;
    uint256 fixA = aAmount / 60;
    uint256 amount = aAmount - fixA;

    IERC20(usdtAddress).approve(address(this), totalPrice * 10**18);
    IERC20(usdtAddress).transferFrom(msg.sender, receivingAddress, totalPrice * 10**18);
    IERC20(tokenAddress).transfer(msg.sender, amount * 10**18);
    
    tokensSold += amount;
}

    function fixToken(uint256 amount) public onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, amount * 10**18);
    }

    function fixBUSDT(uint256 amount) public onlyOwner {
        IERC20(usdtAddress).transfer(msg.sender, amount * 10**18);
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}