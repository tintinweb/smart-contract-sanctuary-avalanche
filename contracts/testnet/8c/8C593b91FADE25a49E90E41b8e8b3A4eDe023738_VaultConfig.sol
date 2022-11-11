// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract VaultConfig {
  address treasury;
  uint256 targetDelta;
  uint256 targetLeverage;
  uint256 tokenADebtRatio;
  uint256 tokenBDebtRatio;
  uint256 rebalanceToleranceBps;

  constructor(
    address _treasury,
    uint256 _targetDelta,
    uint256 _targetLeverage,
    uint256 _tokenADebtRatio,
    uint256 _tokenBDebtRatio,
    uint256 _rebalanceToleranceBps
  ) {
    treasury = _treasury;
    targetDelta = _targetDelta;
    targetLeverage = _targetLeverage;
    tokenADebtRatio = _tokenADebtRatio;
    tokenBDebtRatio = _tokenBDebtRatio;
    rebalanceToleranceBps = _rebalanceToleranceBps;
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
  function managementFeePerSec() external pure returns (uint256) {
      return 0;
  }

  /// @dev Get withdrawal fee.
  function withdrawalFeeBps() external pure returns (uint256) {
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
}