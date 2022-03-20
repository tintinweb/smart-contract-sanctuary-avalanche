// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./Proxiable.sol";

/**
  * Do not modify this contract
 */
contract PriceOracleV3 is Proxiable {

	address _lastContributor;
	address _owner;
	uint256 _price;
	uint256 _lastUpdated;

	modifier onlyOwner() {
		require(msg.sender == _owner, "Only owner is allowed to perform this action");
		_;
	}

	function setPrice(uint256 price) public {
		_price = price;
		_lastContributor = msg.sender;
		_lastUpdated = block.timestamp;
	}

	function updateCode(address newCode) onlyOwner public {
		updateCodeAddress(newCode);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	function price() public view returns (uint256) {
		return _price;
	}

}