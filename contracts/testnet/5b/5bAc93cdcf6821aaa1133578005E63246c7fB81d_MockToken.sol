// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract MockToken is ERC20, Ownable {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 10**(6 + decimals()));
    }

    function mint(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }
}