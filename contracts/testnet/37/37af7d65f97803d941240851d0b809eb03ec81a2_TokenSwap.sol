/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-31
*/

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

interface IminterCon {
    function getUSD() external payable;

    function getQLTOken(uint amount) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenSwap {
    IminterCon private mint;
    IERC20 usdTql;
    IERC20 qlToken;

    constructor(IminterCon _minter, IERC20 _usdtql, IERC20 _qltoken) {
        mint = _minter;
        usdTql = _usdtql;
        qlToken = _qltoken;
    }

    function getToken() external payable {
        mint.getUSD{value: msg.value}();
        usdTql.approve(address(mint), msg.value * 1e20);
        mint.getQLTOken(msg.value * 1e20);
        qlToken.transfer(msg.sender, msg.value * 1e20);
    }
}