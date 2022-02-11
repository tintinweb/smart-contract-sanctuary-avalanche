pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract aWLVR is ERC20, Ownable {
	constructor() ERC20("aWLVR ", "aWLVR ") {
		_mint(msg.sender, 100000000000 * 10**decimals());
	}

	function mint(address to, uint256 amount) public onlyOwner {
		_mint(to, amount);
	}
}