// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract TRSR is ERC20, Ownable {

    uint256 public MAXIMUM_GLOBAL_TOKEN = 10000000000 ether; // 100 000 000 000 $TRSR
    uint public BURN_GLOBAL_TOKEN = 0;

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;

    constructor() ERC20("TRSR", "TRSR") {
        _mint(msg.sender,50000000 ether);
    }

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        BURN_GLOBAL_TOKEN += amount;
        _burn(from, amount);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function getMaximunGlobalToken() external view returns(uint total) {
        return MAXIMUM_GLOBAL_TOKEN;
    }

    function approve( address owner,address spender,uint256 amount) public
    {
        require(controllers[msg.sender], "Only controllers approve");
        _approve(owner,spender,amount);
    }
}