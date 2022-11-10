// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract VaultConfig {
  address WETH = 0x8Ec45CDab62959Ae5477Db0b22bF03358634d22c; // WETH on Fuji
  address WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c; // WAVAX on Fuji
  address manager = 0x862AB0357ae4100a212174fFd528E316Ab276E48;
  address treasury = 0x25C3839Df50f3f1D140D3717aF4b62245C70c36d;
  address oraclePairAddress = 0xCfA3adbdc9e1A6623a2A5b83334a5046DCcC898B; // WETH-USDC Joe
  uint256 targetDelta = 1e18;
  uint256 targetLeverage = 3e18;
  uint256 tokenADebtRatio = 750_000_000_000_000_000;
  uint256 tokenBDebtRatio = 250_000_000_000_000_000;
  uint256 rebalanceToleranceBps = 10e18;


  function getWrappedNativeAddr() external view returns (address) {
      return WETH;
  }

  function getManagerAddress() external view returns (address) {
      return manager;
  }

  // /// @dev Return if the caller is exempted from fee.
  // function feeExemptedCallers(address _caller) external returns (bool) {
  //     return true;
  // }

  /// @dev Return management fee treasury
  function managementFeeTreasury() external view returns (address) {
      return treasury;
  }

  /// @dev Return the withdrawl fee treasury.
  function withdrawalFeeTreasury() external view returns (address) {
      return treasury;
  }

  /// @dev Return management fee per sec.
  function managementFeePerSec() external view returns (uint256) {
      return 0;
  }

  /// @dev Get withdrawal fee.
  function withdrawalFeeBps() external returns (uint256) {
      return 0;
  }

  function getTargetDelta() external view returns (uint256) {
      return targetDelta;
  }

  function getTargetLeverage() external view returns (uint256) {
      return targetLeverage;
  }

  function getTokenADebtRatio() external view returns (uint256) {
      return tokenADebtRatio;
  }

  function getTokenBDebtRatio() external view returns (uint256) {
      return tokenBDebtRatio;
  }

  function getRebalanceToleranceBps() external view returns (uint256) {
      return rebalanceToleranceBps;
  }

  function getPairAddress() external view returns (address) {
    return oraclePairAddress;
  }
}