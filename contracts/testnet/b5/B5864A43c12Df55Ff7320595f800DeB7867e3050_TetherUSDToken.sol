// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract TetherUSDToken is ERC20, Ownable {
    constructor() ERC20("TetherUSD", "USDT") {
        _mint(_msgSender(), 100000000 * (10 ** uint256(decimals())));
    }

    // function mint(address to, uint256 amount) public onlyOwner {
    //     _mint(to, amount);
    // }
}