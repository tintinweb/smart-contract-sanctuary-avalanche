// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

// Ahbap Avalanche C-chain address.
// See https://twitter.com/ahbap/status/1622963311514996739?s=20&t=-cK1P2pUhc-FtTQUWW1Lew
address payable constant AHBAP_AVALANCHE = payable(
    0x868D27c361682462536DfE361f2e20B3A6f4dDD8
);

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;
}

// The top 8 tokens on Avalanche by market cap according to snowtrace.io
IERC20 constant USDTe = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
IERC20 constant USDT = IERC20(0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7);
IERC20 constant USDCe = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
IERC20 constant USDC = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
IERC20 constant BUSDe = IERC20(0x19860CCB0A68fd4213aB9D8266F7bBf05A8dDe98);
IERC20 constant BUSD = IERC20(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
IERC20 constant SHIBe = IERC20(0x02D980A0D7AF3fb7Cf7Df8cB35d9eDBCF355f665);
IERC20 constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

/**
 * Sends all AVAX and ERC-20 tokens sent to this address to `AHBAP_AVALANCHE`.
 */
contract AhbapRelayer {
    receive() external payable {}

    /**
     * Transfers the entire native token balance to `AHBAP_AVALANCHE`.
     */
    function sweepNativeToken() external {
        AHBAP_AVALANCHE.transfer(address(this).balance);
    }

    /**
     * Transfers the entire balance of a select list of tokens to
     * AHBAP_AVALANCHE.
     *
     * The list is obtained by sorting the tokens by market cap on snowtrace.io
     * and taking the top 8.
     *
     * For other tokens use `sweepMultiERC20()` or `sweepSingleERC20()` methods.
     */
    function sweepCommonERC20() external {
        USDTe.transfer(AHBAP_AVALANCHE, USDTe.balanceOf(address(this)));
        USDT.transfer(AHBAP_AVALANCHE, USDT.balanceOf(address(this)));
        USDCe.transfer(AHBAP_AVALANCHE, USDCe.balanceOf(address(this)));
        USDC.transfer(AHBAP_AVALANCHE, USDC.balanceOf(address(this)));
        BUSDe.transfer(AHBAP_AVALANCHE, BUSDe.balanceOf(address(this)));
        BUSD.transfer(AHBAP_AVALANCHE, BUSD.balanceOf(address(this)));
        SHIBe.transfer(AHBAP_AVALANCHE, SHIBe.balanceOf(address(this)));
        WAVAX.transfer(AHBAP_AVALANCHE, WAVAX.balanceOf(address(this)));
    }

    /**
     * Transfers the entire balance of the given 5 tokens to
     * `AHBAP_AVALANCHE`.
     *
     * If you have fewer than 5 tokens, pad the remainder with, say, WAVAX so
     * the transaction doesn't revert.
     *
     * @param tokens A list of ERC20 contract addresses whose balance wil be
     *               sent to `AHBAP_AVALANCHE`.
     */
    function sweepMultiERC20(IERC20[5] calldata tokens) external {
        tokens[0].transfer(AHBAP_AVALANCHE, tokens[0].balanceOf(address(this)));
        tokens[1].transfer(AHBAP_AVALANCHE, tokens[1].balanceOf(address(this)));
        tokens[2].transfer(AHBAP_AVALANCHE, tokens[2].balanceOf(address(this)));
        tokens[3].transfer(AHBAP_AVALANCHE, tokens[3].balanceOf(address(this)));
        tokens[4].transfer(AHBAP_AVALANCHE, tokens[4].balanceOf(address(this)));
    }

    /**
     * Transfers the entire balance of the given token to `AHBAP_AVALANCE`.
     *
     * @param token Contract addres of the token to move
     */
    function sweepSingleERC20(IERC20 token) external {
        token.transfer(AHBAP_AVALANCHE, token.balanceOf(address(this)));
    }

    function sweepNFT(IERC721 nft, uint256 tokenId) external {
        nft.transferFrom(address(this), AHBAP_AVALANCHE, tokenId);
    }
}