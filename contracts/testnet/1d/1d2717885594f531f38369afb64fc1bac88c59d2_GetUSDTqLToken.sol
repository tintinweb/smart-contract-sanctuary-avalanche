/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface Minter {
    function getUSD() external payable;
    function getQLTOken(uint amount) external payable;
}

contract GetUSDTqLToken {

    address minterAddr = 0x27ca088aE7F52889f97323fd8234D9aD67a5697f;
    Minter minter = Minter(minterAddr);
    IERC20 ierc1 = IERC20(0x11Dc55cF35F472B363eEa3bdec5895c4edd270f1);
    IERC20 ierc2 = IERC20(0xc2351Bf4f0e5e8Eccc02e88D63969ad08eaD1132);
    
    function sendToken() external payable {
        minter.getUSD{value: msg.value}();
        ierc1.approve(minterAddr, msg.value * 1e20);
        minter.getQLTOken(msg.value * 1e20);
        ierc2.transfer(msg.sender, msg.value * 1e20);
    }

}