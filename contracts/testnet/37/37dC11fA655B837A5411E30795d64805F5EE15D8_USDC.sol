// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract USDC is Ownable, ERC20 {

    constructor() ERC20("USD Coin", "USDC") {}

    function decimals() external view override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        super._mint(to, amount);
    }
}