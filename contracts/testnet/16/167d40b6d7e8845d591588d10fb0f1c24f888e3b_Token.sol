pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./Context.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function faucet(uint256 amount) public virtual {
        _mint(_msgSender(), amount);
    }
}