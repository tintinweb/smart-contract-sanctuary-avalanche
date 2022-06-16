/**
 *Submitted for verification at snowtrace.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


interface ICLAggregator {
    function latestAnswer() external view returns (int256);
}

interface IsAVAXWithRate {
    /**
     * @return The amount of AVAX that corresponds to `shareAmount` token shares.
     */
    function getPooledAvaxByShares(uint256 shareAmount)
        external
        view
        returns (uint256);
}

contract sAVAXOracleAdapter is ICLAggregator {
    IsAVAXWithRate public constant SAVAX =
        IsAVAXWithRate(0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE);
    ICLAggregator public constant AVAX_USD_FEED =
        ICLAggregator(0x0A77230d17318075983913bC2145DB16C7366156);

    /**
     * @notice Returns the price of sAVAX, from the AVAX/USD * AVAX/sAVAX exchange rate
     * @dev Important to highlight that this is not prone to manipulation, because
     * sAVAX manages its exchange rate in a "static" way, without dynamically checking
     * for AVAX staked in the contract.
     * - If the price AVAX/USD would be 0, this will also return 0 (this should never happen)
     * - We also assume that the exchange rate of 1 sAVAX can't be more than the limit of uint256 -> int256 cast
     *   given the close correlation between AVAX and sAVAX
     * @return int256 The price, in AaveOracle compatible units
     */
    function latestAnswer() external view returns (int256) {
        return
            (AVAX_USD_FEED.latestAnswer() *
                int256(SAVAX.getPooledAvaxByShares(1 ether))) / 1 ether;
    }
}