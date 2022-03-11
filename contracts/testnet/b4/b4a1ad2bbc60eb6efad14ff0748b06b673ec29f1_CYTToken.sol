// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Capped.sol";
import "./Ownable.sol";



contract CYTToken is
    ERC20Capped,
    Ownable
    {

    constructor(uint256 cap)
        ERC20("CoinYouTrust", "CYT")
        ERC20Capped(cap)
    {
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address account, uint256 amount) public onlyOwner
    {
        _mint(account, amount);
    }
}