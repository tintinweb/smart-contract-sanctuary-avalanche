/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface Minter{
    function getUSD() external payable;
    function getQLTOken(uint amount) external;

}

contract myContract {

    address minterAddress = 0x27ca088aE7F52889f97323fd8234D9aD67a5697f;
    address USDTqlAddress = 0x11Dc55cF35F472B363eEa3bdec5895c4edd270f1;
    address QLTOkenAddress = 0xc2351Bf4f0e5e8Eccc02e88D63969ad08eaD1132;

    function getToken() external payable {
        Minter myMinter = Minter(minterAddress);
        IERC20 USDTql = IERC20(USDTqlAddress);
        IERC20 QLTOken = IERC20(QLTOkenAddress);

        myMinter.getUSD{value : msg.value}();
        USDTql.approve(minterAddress, msg.value * 1e20);
        myMinter.getQLTOken(msg.value * 1e20);
        QLTOken.transfer(msg.sender, msg.value * 1e20);
    }

}