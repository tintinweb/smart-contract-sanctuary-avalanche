// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor() ERC20("Trash Coin", "TC") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}