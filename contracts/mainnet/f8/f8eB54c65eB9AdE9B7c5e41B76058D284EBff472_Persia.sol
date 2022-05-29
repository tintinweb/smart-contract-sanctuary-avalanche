// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

/// @custom:security-contact [email protected]
contract Persia is ERC20, ERC20Burnable {
    constructor() ERC20("Persia", "PER") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}