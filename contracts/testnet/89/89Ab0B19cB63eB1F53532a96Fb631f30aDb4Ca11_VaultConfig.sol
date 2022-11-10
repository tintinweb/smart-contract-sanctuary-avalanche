// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract VaultConfig {
  address tokenA;
  address manager;
  address treasury;
  address oraclePairAddress;
  uint256 targetDelta;
  uint256 targetLeverage;
  uint256 tokenADebtRatio;
  uint256 tokenBDebtRatio;
  uint256 rebalanceToleranceBps;

  constructor(
    address _tokenA,
    address _manager,
    address _treasury,
    address _oraclePairAddress,
    uint256 _targetDelta,
    uint256 _targetLeverage,
    uint256 _tokenADebtRatio,
    uint256 _tokenBDebtRatio,
    uint256 _rebalanceToleranceBps
  ) {
    tokenA = _tokenA;
    manager = _manager;
    treasury = _treasury;
    oraclePairAddress = _oraclePairAddress;
    targetDelta = _targetDelta;
    targetLeverage = _targetLeverage;
    tokenADebtRatio = _tokenADebtRatio;
    tokenBDebtRatio = _tokenBDebtRatio;
    rebalanceToleranceBps = _rebalanceToleranceBps;
  }

  function changeManager(address _manager) external {
      manager = _manager;
  }

  function getWrappedNativeAddr() external view returns (address) {
      return tokenA;
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