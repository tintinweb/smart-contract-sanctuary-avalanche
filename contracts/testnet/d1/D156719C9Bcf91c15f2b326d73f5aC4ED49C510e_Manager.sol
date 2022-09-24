// SPDX-License-Identifier: MIT
// 0xc5295606aacd5b70f2796be497874d38318b1d3f
pragma solidity ^0.8.12;

contract Manager {
    address[] private _products;
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function getTotal() view public returns (uint256) {
        return _products.length;
    }

    function getProducts() view public returns (address[] memory) {
        return _products;
    }

    function setProducts(address addr) public returns (bool) {
        require(msg.sender == _owner , "Only owner can do this action.");
        _products.push(addr);
        return true;
    }
}