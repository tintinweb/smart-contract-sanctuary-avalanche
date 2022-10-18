/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-17
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  function performUpkeep(bytes calldata performData) external;
}

contract KeeperArcticChainlinkWrapper is KeeperCompatibleInterface {
  KeeperCompatibleInterface keeper;
  address owner;

  constructor() {
    owner = msg.sender;
  }

  function setKeeper(KeeperCompatibleInterface _keeper) public {
      keeper = _keeper;
  }

  function checkUpkeep(bytes calldata input) external override returns (bool upkeepNeeded, bytes memory performData) {
    return keeper.checkUpkeep(input);
  }

  function performUpkeep(bytes calldata dataForUpkeep) external override {
    keeper.performUpkeep(dataForUpkeep);
  }
}