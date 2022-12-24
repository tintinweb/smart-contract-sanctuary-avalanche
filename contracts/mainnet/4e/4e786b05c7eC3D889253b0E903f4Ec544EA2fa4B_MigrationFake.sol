// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MigrationFake {
  mapping(address => bool) public rewardsMigrated;
  mapping(address => bool) public thorMigrated;
  mapping(address => bool) public odinMigrated;
  mapping(address => bool) public freyasMigrated;
  mapping(address => uint256) public totalThors;
  mapping(address => uint256) public totalOdins;

  function migrateRewards(
    uint256[] memory  _tierRewards,   // taxed Rewards
    uint256 _requestTime,
    uint256 _requestType,
    bytes calldata signature
  ) external {
    require(_requestType == 8, 'requestType');
    require(!rewardsMigrated[msg.sender], 'rewards migrated');

    rewardsMigrated[msg.sender] = true;
  }

  function migrateNodes(
    string[] memory _namesOdins,
    uint256[] memory _dueDatesOdins,
    string[] memory _namesThors,
    uint256[] memory _dueDatesThors,
    uint256 _requestTime,
    uint256 _requestType,
    uint256 _totalThor,
    uint256 _totalOdin,
    bytes calldata signature
  ) external {
    require(rewardsMigrated[msg.sender], 'rewards not migrated');
    require(_namesOdins.length + _namesThors.length <= 50, 'Max Nodes');
    require(_requestType == 9, 'requestType'); //nodes

    if (_namesThors.length > 0){
      require(!thorMigrated[msg.sender], 'nodes migrated');
      require(totalThors[msg.sender] + _namesThors.length <= _totalThor, "wrong number of thors");

      totalThors[msg.sender] += _namesThors.length;
      if (totalThors[msg.sender] == _totalThor){
        thorMigrated[msg.sender] = true;
      }
    }

    if (_namesOdins.length > 0) {
      require(!odinMigrated[msg.sender], 'nodes migrated');
      require(totalOdins[msg.sender] + _namesOdins.length <= _totalOdin, "wrong number of odins");

      totalOdins[msg.sender] += _namesOdins.length;
      if (totalOdins[msg.sender] == _totalOdin){
        odinMigrated[msg.sender] = true;
      }
    }
  }

  function convertFreyasAndHeimdalls(
    uint256 freyas,
    uint256 heimdalls,
    uint256 _requestTime,
    uint256 _requestType,
    bytes calldata signature
  ) external {
    require(rewardsMigrated[msg.sender], 'rewards not migrated');

    require(_requestType == 10, 'requestType'); //Odin
    require(!freyasMigrated[msg.sender], 'nodes migrated');
    freyasMigrated[msg.sender] = true;
  }

  function resetMigration() external {
    rewardsMigrated[msg.sender] = false;
    thorMigrated[msg.sender] = false;
    odinMigrated[msg.sender] = false;
    freyasMigrated[msg.sender] = false;
    totalThors[msg.sender] = 0;
    totalOdins[msg.sender] = 0;
  }
}