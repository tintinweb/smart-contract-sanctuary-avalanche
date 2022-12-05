// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract WFUSD is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("WFDCToken", "WFUSD") {}
//    constructor() ERC20({name_: "WFDCToken", symbol_: "WFUSD"}) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}