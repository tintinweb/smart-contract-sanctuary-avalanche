// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Disperse {
	function disperseEther(address payable[] memory recipients, uint256[] memory values) external payable {
		for (uint i = 0; i < recipients.length; i++) {
			recipients[i].transfer(values[i]);
			uint256 balance = address(this).balance;
			if (balance > 0) payable(msg.sender).transfer(balance);
		}
	}

	function disperseToken(IERC20 token, address[] memory recipients, uint256[] memory values) external {
		uint256 total = 0;
		for (uint i = 0; i < recipients.length; i++) {
			total += values[i];
			require(token.transferFrom(payable(msg.sender), address(this), total));
			for (i = 0; i < recipients.length; i++) require(token.transfer(recipients[i], values[i]));
		}
	}

	function disperseTokenSimple(IERC20 token, address[] memory recipients, uint256[] memory values) external {
		for (uint i = 0; i < recipients.length; i++) {
			require(token.transferFrom(payable(msg.sender), recipients[i], values[i]));
		}
	}
}