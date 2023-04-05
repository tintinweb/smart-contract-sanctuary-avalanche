// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TextToken is ERC20 {
    address private owner;
    uint256 private constant TOTAL_SUPPLY = 100000000 ether; // Toplam arz 100 milyon
    
    constructor() ERC20("textToken", "TTOK") {
        owner = msg.sender;
        _mint(owner, TOTAL_SUPPLY);
    }
    
    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "Only the contract owner can mint tokens");
        _mint(to, amount);
    }
    
    function burn(uint256 amount) public {
        require(msg.sender == owner, "Only the contract owner can burn tokens");
        _burn(msg.sender, amount);
    }
}