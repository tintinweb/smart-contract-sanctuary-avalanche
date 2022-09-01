// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/DivestStructs.sol";

contract DivestStrategyHelpers {
  constructor() {}

  /**
   * Calculates harvest details
   * Note: this scales share values up to make the division work, they need to be scaled down later.
   */
  function getHarvestDetails(
    uint256 _harvestAmount,
    uint256 _totalSupply,
    DivestStructs.Harvest[] memory _harvests
  ) external pure returns (DivestStructs.Harvest memory) {
    uint256 totalHarvested = 0;
    uint256 originalNumHarvests = _harvests.length;
    uint256 shareValue = 0;
    uint256 summedShareValue = 0;

    if (originalNumHarvests > 0 && _harvestAmount > 0 && _totalSupply > 0) {
      DivestStructs.Harvest memory previous = _harvests[
        originalNumHarvests - 1
      ];

      totalHarvested = previous.totalHarvested + _harvestAmount;

      shareValue = (_harvestAmount * 1 ether) / _totalSupply;
      summedShareValue = previous.summedShareValue + shareValue;
    }

    return
      DivestStructs.Harvest({
        totalSupply: _totalSupply,
        harvestAmount: _harvestAmount,
        totalHarvested: totalHarvested,
        shareValue: shareValue,
        summedShareValue: summedShareValue
      });
  }

  /**
   * Calculates how much is owed to a user based on owned shares and previous harvests.
   * Scale should almost always be "1 ether" and depends on how the harvests are scaled up in recordPayout
   */
  function calculatePayout(
    bool _isUserActive,
    uint256 _numShares,
    uint256 _userEntryPosition,
    uint256 _scale,
    DivestStructs.Harvest[] memory _harvests
  ) external pure returns (uint256) {
    // If there aren't any harvests, a user isn't active or the entry position > harvest len - return 0
    if (
      _harvests.length == 0 ||
      !_isUserActive ||
      _userEntryPosition > (_harvests.length - 1)
    ) {
      return 0;
    }

    // Here's where you do the maths and shit with averages
    DivestStructs.Harvest memory startHarvest = _harvests[_userEntryPosition];
    DivestStructs.Harvest memory endHarvest = _harvests[_harvests.length - 1];

    // Should be impossible, but here for safety
    if (endHarvest.summedShareValue < startHarvest.summedShareValue) {
      return 0;
    }

    uint256 summedShareValue = endHarvest.summedShareValue -
      startHarvest.summedShareValue;

    return (summedShareValue * _numShares) / _scale;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DivestStructs {
  struct Harvest {
    uint256 totalSupply;
    uint256 harvestAmount;
    uint256 totalHarvested;
    uint256 shareValue;
    uint256 summedShareValue;
  }
}