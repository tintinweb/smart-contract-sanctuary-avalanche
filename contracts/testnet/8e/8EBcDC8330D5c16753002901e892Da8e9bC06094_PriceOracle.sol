// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./Proxiable.sol";

/**
  * Do not modify this contract
 */
contract PriceOracle is Proxiable {

	address _owner;
	address _operator;
	uint256 _price;

	function constructor1() public {
		require(_owner == address(0), "Already initalized");
		_owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == _owner, "Only owner is allowed to perform this action");
		_;
	}

	modifier onlyOperator() {
		require(msg.sender == _operator, "Only operator is allowed to perform this action");
		_;
	}

	function setOperator(address newOperator) public onlyOwner {
		_operator = newOperator;
	}

	function setPrice(uint256 price) public onlyOperator {
		_price = price;
	}

	function updateCode(address newCode) onlyOwner public {
		updateCodeAddress(newCode);
	}

	function operator() public view returns (address) {
		return _operator;
	}

	function owner() public view returns (address) {
		return _owner;
	}

	function price() public view returns (uint256) {
		return _price;
	}

}