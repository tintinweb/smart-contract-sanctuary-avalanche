/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface ChainlinkPriceFeed {
    function latestAnswer() external view returns(uint256);
    function decimals() external view returns(uint256);
}

contract FakeGmxVault {
    uint256 public constant PRICE_PRECISION = 10**30;

    address public constant ethAddress = 0x4f5003fd2234Df46FB2eE1531C89b8bdcc372255;
    address public constant btcAddress = 0x385104afA0BfdAc5A2BcE2E3fae97e96D1CB9160;

    address public constant chainlinkEthPriceFeed = 0x86d67c3D38D2bCeE722E601025C25a575021c6EA;
    address public constant chainlinkBtcPriceFeed = 0x31CF013A08c6Ac228C94551d535d5BAfE19c602a;

    address public owner;

    mapping(address => uint256) public tokenPrices;
    mapping(address => address) public priceFeeds;

    modifier onlyOwner {
        require(msg.sender == owner, "Sender is not contract owner.");
        _;
    }

    constructor() {
        owner = msg.sender;

        priceFeeds[ethAddress] = chainlinkEthPriceFeed;
        priceFeeds[btcAddress] = chainlinkBtcPriceFeed;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setPriceFeed(address _token, address _priceFeed) external onlyOwner {
        priceFeeds[_token] = _priceFeed;
    }

    function setTokenPrice(address _token, uint256 _price) external onlyOwner {
        tokenPrices[_token] = _price;
    }

    function getMaxPrice(address _token) external view returns(uint256) {
        if (tokenPrices[_token] == 0) {
            return (ChainlinkPriceFeed(priceFeeds[_token]).latestAnswer() * PRICE_PRECISION / 10**ChainlinkPriceFeed(priceFeeds[_token]).decimals()) + (100 * PRICE_PRECISION);
        } else {
            return tokenPrices[_token] + (100 * PRICE_PRECISION);
        }
    }

    function getMinPrice(address _token) external view returns(uint256) {
        if (tokenPrices[_token] == 0) {
            return (ChainlinkPriceFeed(priceFeeds[_token]).latestAnswer() * PRICE_PRECISION / 10**ChainlinkPriceFeed(priceFeeds[_token]).decimals()) - (100 * PRICE_PRECISION);
        } else {
            return tokenPrices[_token] - (100 * PRICE_PRECISION);
        }
    }
}