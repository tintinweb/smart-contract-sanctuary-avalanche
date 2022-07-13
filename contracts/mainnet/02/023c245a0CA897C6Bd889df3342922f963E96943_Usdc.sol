// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Usdc is ERC20 {
    constructor() ERC20("USDC", "USDC") {}

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}