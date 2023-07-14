/**
 *Submitted for verification at snowtrace.io on 2023-07-14
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IRateProvider {
	function getRate() external view returns (uint256);
}

interface IggAVAX {
	function convertToAssets(uint256 shares) external view returns (uint256);
}

/**
 * @title Wrapped stETH Rate Provider
 * @notice Returns the value of wstETH in terms of stETH
 */
contract GGAVAXRateProvider is IRateProvider {
	IggAVAX public immutable ggAVAX;

	constructor(address addr) {
		ggAVAX = IggAVAX(addr);
	}

	/**
	 * @return the value of wstETH in terms of stETH
	 */
	function getRate() external view override returns (uint256) {
		return ggAVAX.convertToAssets(1e18);
	}
}