// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Token2 is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Token2", "T2") {
         _mint(_msgSender(), 100000000 * (10 ** uint256(decimals())));
    }

    // function mint(address to, uint256 amount) public onlyOwner {
    //     _mint(to, amount);
    // }
}