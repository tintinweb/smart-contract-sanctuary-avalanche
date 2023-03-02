// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;


contract MockPriceFeed {
	function decimals() external view returns (uint8) {
		return 8;
	}

	function latestRoundData(
	)
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
    	)
	{
		return (0,160000000000,0,0,0);
	}
}