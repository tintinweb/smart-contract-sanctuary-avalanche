/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract GmxVault {
    address btcAddress = 0x4f5003fd2234Df46FB2eE1531C89b8bdcc372255;
    address ethAddress = 0x385104afA0BfdAc5A2BcE2E3fae97e96D1CB9160;

    mapping(address => uint256) _tokenPrices;

    constructor() {
        _tokenPrices[btcAddress] = 30000 * 10**8; // BTC
        _tokenPrices[ethAddress] = 2000 * 10**18; // ETH
    }

    function getMaxPrice(address _token) external view returns(uint256) {
        return _tokenPrices[_token] + 10;
    }

    function getMinPrice(address _token) external view returns(uint256) {
        return _tokenPrices[_token] - 10;
    }
}