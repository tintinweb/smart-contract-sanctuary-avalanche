// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Controllable.sol";

contract Glow is ERC20, Controllable {

	mapping(address => uint256) public lastTransfer;

	constructor() ERC20("Glowing Flower", "GLOW") {}

	/**
	* Mints $GLOW to a recipient
	* @param to the recipient of the $GLOW
	* @param amount the amount of $GLOW to mint
	*/
	function mint(address to, uint256 amount) external onlyController {
		_mint(to, amount);
	}

	/**
	* Burns $GLOW from a holder
	* @param from the holder of the $GLOW
	* @param amount the amount of $GLOW to burn
	*/
	function burn(address from, uint256 amount) external onlyController {
		_burn(from, amount);
	}

	function _beforeTokenTransfer(
		address from,
        address to,
        uint256 amount
    ) internal override {
		if (amount > 0 && to != address(0)) {
			lastTransfer[from] = block.timestamp;
		}
    }
}