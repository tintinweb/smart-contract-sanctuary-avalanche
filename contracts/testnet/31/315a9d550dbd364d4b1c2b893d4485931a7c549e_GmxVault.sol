/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract GmxVault {
    uint256 constant PRICE_PRECISION = 10**30;

    address constant ethAddress = 0x4f5003fd2234Df46FB2eE1531C89b8bdcc372255;
    address constant btcAddress = 0x385104afA0BfdAc5A2BcE2E3fae97e96D1CB9160;

    mapping(address => uint256) _tokenPrices;

    constructor() {
        _tokenPrices[btcAddress] = 30000 * PRICE_PRECISION;
        _tokenPrices[ethAddress] = 2000 * PRICE_PRECISION;
    }

    function getMaxPrice(address _token) external view returns(uint256) {
        return _tokenPrices[_token] + (10*PRICE_PRECISION);
    }

    function getMinPrice(address _token) external view returns(uint256) {
        return _tokenPrices[_token] - (10*PRICE_PRECISION);
    }
}