/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

contract MiroTierProxy {
  uint256 public constant BRONZE_TIER = 0;
  uint256 public constant SILVER_TIER = 1;
  uint256 public constant GOLD_TIER = 2;

  address public proxyAdmin;

  // since this is a mapping and bronze tier is set to 0 in original
  // miro contracts, every user will start from bronze regardless to their staked amounts
  mapping(address => uint256) public userTiers;

  event TierSetted(address user, uint256 tier);
  event ProxyAdminUpdated(address newProxyAdmin);

  constructor() {
    proxyAdmin = msg.sender;
  }

  function getTier(address user) external view returns (uint256 tier) {
    return userTiers[user];
  }

  function setTier(address user, uint256 tier) external {
    require(user != address(0), "Zero address");
    require(msg.sender == proxyAdmin, "Only proxy admin");
    require(
      tier == BRONZE_TIER || tier == SILVER_TIER || tier == GOLD_TIER,
      "Invalid Tier"
    );

    userTiers[user] = tier;

    emit TierSetted(user, tier);
  }

  function setProxyAdmin(address newProxyAdmin) external {
    require(newProxyAdmin != address(0), "Zero address");
    require(msg.sender == proxyAdmin, "Only proxy admin");

    proxyAdmin = newProxyAdmin;

    emit ProxyAdminUpdated(newProxyAdmin);
  }
}