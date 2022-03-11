// SPDX-License-Identifier: MIT
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Authorizable.sol";
import "./INodeManager02.sol";
import "./INodeStorage.sol";

pragma solidity ^0.8.4;

contract NodeController is Ownable, Pausable, Authorizable, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 public rewardPerNode;
  uint256 public minTokensRequired;

  uint256 public totalNodesCreated;
  uint256 public totalNodesMigrated;
  uint256 public totalValueLocked;

  mapping(address => bool) public isBlacklisted;

  INodeStorage private nodeStorage;
  INodeManager02 private nodeManager02;
  uint256[] private _boostMultipliers = [105, 120, 140];
  uint256[] private _boostRequiredDays = [3, 7, 15];
  uint256[] private _compoundRequiredTokens = [5000, 10000, 20000];
  uint256[] private _compoundMultipliers = [125, 115, 105];

  event NodeIncreased(address indexed account, uint256 amount);
  event NodeCreated(address indexed account, uint256 amount, uint256 blockTime);
  event NodeMerged(
    address indexed account,
    uint256 sourceBlockTime,
    uint256 destBlockTime
  );

  constructor(
    address _nodeStorage,
    address _nodeManager02,
    uint256 _rewardPerNode,
    uint256 _minTokensRequired
  ) {
    nodeStorage = INodeStorage(_nodeStorage);
    nodeManager02 = INodeManager02(_nodeManager02);
    rewardPerNode = _rewardPerNode;
    minTokensRequired = _minTokensRequired;
  }

  // Getters and setters
  function getNodeStorageAddress() external view returns (address) {
    return address(nodeStorage);
  }

  function getBoostMultipliers() external view returns (uint256[] memory) {
    return _boostMultipliers;
  }

  function getBoostRequiredDays() external view returns (uint256[] memory) {
    return _boostRequiredDays;
  }

  function getCompoundRequiredTokens()
    external
    view
    returns (uint256[] memory)
  {
    return _compoundRequiredTokens;
  }

  function getCompoundMultipliers() external view returns (uint256[] memory) {
    return _compoundMultipliers;
  }

  function getMinTokensRequired() external view returns (uint256) {
    return minTokensRequired;
  }

  function setRewardPerNode(uint256 _rewardPerNode) external onlyAuthorized {
    rewardPerNode = _rewardPerNode;
  }

  function setMinTokensRequired(uint256 _minTokensRequired)
    external
    onlyAuthorized
  {
    minTokensRequired = _minTokensRequired;
  }

  function setNodeStorage(address _nodeStorage) external onlyAuthorized {
    nodeStorage = INodeStorage(_nodeStorage);
  }

  function setBoostMultipliers(uint256[] memory boostMultipliers)
    external
    onlyAuthorized
  {
    require(
      _boostMultipliers.length == boostMultipliers.length,
      "SetBoostMultipliers: Length mismatch"
    );
    _boostMultipliers = boostMultipliers;
  }

  function setBoostRequiredDays(uint256[] memory boostRequiredDays)
    external
    onlyAuthorized
  {
    require(
      _boostRequiredDays.length == boostRequiredDays.length,
      "SetBoostRequiredDays: Length mismatch"
    );
    _boostRequiredDays = boostRequiredDays;
  }

  function setCompoundRequiredTokens(uint256[] memory compoundRequiredTokens)
    external
    onlyAuthorized
  {
    require(
      _compoundRequiredTokens.length == compoundRequiredTokens.length,
      "SetCompoundRequiredTokens: Length mismatch"
    );
    _compoundRequiredTokens = compoundRequiredTokens;
  }

  function setCompoundMultipliers(uint256[] memory compoundMultipliers)
    external
    onlyAuthorized
  {
    require(
      _compoundMultipliers.length == compoundMultipliers.length,
      "SetCompoundMultipliers: Length mismatch"
    );
    _compoundMultipliers = compoundMultipliers;
  }

  // Rewards management

  function calculateNodeRewards(
    uint256 _lastClaimTime,
    uint256 _lastCompoundTime,
    uint256 _amount
  ) public view returns (uint256) {
    uint256 _boostMultiplier = _calculateBoost(_lastClaimTime);
    uint256 rewardPerDay = _amount.mul(rewardPerNode).div(100);
    uint256 rewardPerMinute = rewardPerDay.mul(10000).div(1440);
    uint256 _elapsedTime = (block.timestamp - _lastCompoundTime);
    uint256 elapsedMinutes = _elapsedTime / 1 minutes;

    return
      rewardPerMinute.mul(elapsedMinutes).div(10000).mul(_boostMultiplier).div(
        100
      );
  }

  function getCompoundBonus(
    address _account,
    uint256 _creationTime,
    uint256 _fee
  ) public view returns (uint256) {
    INodeStorage.NodeEntity memory node = nodeStorage.getNode(
      _account,
      _creationTime
    );
    uint256 _nodeRewards = calculateNodeRewards(
      node.lastClaimTime,
      node.lastCompoundTime,
      node.amount
    );

    uint256 rewardsAfterFees = _nodeRewards.sub(
      _nodeRewards.mul(_fee).div(100)
    );

    return rewardsAfterFees.mul(_calculateCompoundBonus(node.amount)).div(100);
  }

  function getNodeRewards(address _account, uint256 _creationTime)
    external
    view
    returns (uint256)
  {
    require(_creationTime > 0, "GetNodeRewards: Invalid creation time");
    INodeStorage.NodeEntity memory node = nodeStorage.getNode(
      _account,
      _creationTime
    );
    return
      calculateNodeRewards(
        node.lastClaimTime,
        node.lastCompoundTime,
        node.amount
      );
  }

  function getAllNodesRewards(address _account)
    external
    view
    returns (uint256)
  {
    uint256 totalRewards = 0;
    INodeStorage.NodeEntity[] memory nodes = nodeStorage.getAllActiveNodes(
      _account
    );

    for (uint256 i = 0; i < nodes.length; i++) {
      INodeStorage.NodeEntity memory node = nodes[i];
      if (node.amount > 0) {
        totalRewards = totalRewards.add(
          calculateNodeRewards(
            node.lastClaimTime,
            node.lastCompoundTime,
            node.amount
          )
        );
      }
    }

    return totalRewards;
  }

  function getNodesCount(address _account) external view returns (uint256) {
    return nodeStorage.getNodesCount(_account);
  }

  // Node management

  function createNode(
    address _account,
    string memory _name,
    uint256 _amount
  ) external whenNotPaused onlyAuthorized {
    require(_account != address(0), "CreateNode: Invalid account");
    require(
      _amount >= minTokensRequired,
      "CreateNode: Minimum required tokens"
    );

    nodeStorage.createNode(_account, _name, _amount);

    totalNodesCreated++;
    totalValueLocked += _amount;

    emit NodeCreated(_account, _amount, block.timestamp);
  }

  function claimNode(address _account, uint256 _creationTime)
    external
    onlyAuthorized
    whenNotPaused
  {
    require(_account != address(0), "ClaimNode: Invalid account");
    require(_creationTime > 0, "ClaimNode: Invalid creation time");

    nodeStorage.setLastClaimTime(_account, _creationTime, block.timestamp);
    nodeStorage.setLastCompoundTime(_account, _creationTime, block.timestamp);
  }

  function claimAllNodes(address _account)
    external
    whenNotPaused
    onlyAuthorized
  {
    require(_account != address(0), "ClaimAllNodes: Invalid account");
    INodeStorage.NodeEntity[] memory nodes = nodeStorage.getAllActiveNodes(
      _account
    );

    for (uint256 i = 0; i < nodes.length; i++) {
      if (nodes[i].amount > 0) {
        nodeStorage.setLastClaimTime(
          _account,
          nodes[i].creationTime,
          block.timestamp
        );
        nodeStorage.setLastCompoundTime(
          _account,
          nodes[i].creationTime,
          block.timestamp
        );
      }
    }
  }

  function compoundNode(
    address _account,
    uint256 _creationTime,
    uint256 _fee
  ) external whenNotPaused onlyAuthorized {
    require(_account != address(0), "CompoundNode: Invalid account");
    require(_creationTime > 0, "CompoundNode: Invalid creation time");
    require(_fee > 0, "CompoundNode: Invalid fee");
    uint256 _compoundBonus = getCompoundBonus(_account, _creationTime, _fee);

    nodeStorage.addAmount(_account, _creationTime, _compoundBonus);
    nodeStorage.setLastCompoundTime(_account, _creationTime, block.timestamp);
  }

  function compoundAllNodes(address _account, uint256 _fee)
    external
    whenNotPaused
    onlyAuthorized
  {
    require(_account != address(0), "CompoundAllNodes: Invalid account");
    require(_fee > 0, "CompoundAllNodes: Invalid fee");
    INodeStorage.NodeEntity[] memory nodes = nodeStorage.getAllActiveNodes(
      _account
    );

    for (uint256 i = 0; i < nodes.length; i++) {
      if (nodes[i].amount > 0) {
        nodeStorage.addAmount(
          _account,
          nodes[i].creationTime,
          getCompoundBonus(_account, nodes[i].creationTime, _fee)
        );
        nodeStorage.setLastCompoundTime(
          _account,
          nodes[i].creationTime,
          block.timestamp
        );
      }
    }
  }

  function migrateNodes(address account) external whenNotPaused nonReentrant {
    INodeManager02.NodeEntity[] memory oldNodes = nodeManager02.getAllNodes(
      account
    );
    require(oldNodes.length > 0, "MigrateNodes: No nodes to migrate");
    uint256 currentNodesCount = nodeStorage.getNodesCount(account);

    require(
      currentNodesCount.add(oldNodes.length) <= 100,
      "MigrateNodes: Max nodes"
    );

    for (uint256 index = 0; index < oldNodes.length; index++) {
      if (!oldNodes[index].deleted) {
        nodeStorage.migrateNode(
          account,
          oldNodes[index].name,
          oldNodes[index].amount,
          oldNodes[index].creationTime,
          oldNodes[index].lastClaimTime,
          oldNodes[index].lastCompoundTime
        );

        totalNodesCreated++;
        totalNodesMigrated++;
        totalValueLocked += oldNodes[index].amount;
      }

      emit NodeCreated(
        account,
        oldNodes[index].amount,
        oldNodes[index].creationTime
      );
    }
  }

  function renameNode(
    address _account,
    uint256 _creationTime,
    string memory _name
  ) external whenNotPaused onlyAuthorized {
    nodeStorage.setName(_account, _creationTime, _name);
  }

  function increaseNodeAmount(
    address _account,
    uint256 _creationTime,
    uint256 _amount
  ) external whenNotPaused onlyAuthorized {
    nodeStorage.addAmount(_account, _creationTime, _amount);
    nodeStorage.setLastCompoundTime(_account, _creationTime, block.timestamp);
  }

  function mergeNodes(
    address _account,
    uint256 _destBlocktime,
    uint256 _srcBlocktime
  ) external whenNotPaused onlyAuthorized {
    require(_account != address(0), "MergeNodes: Invalid account");
    require(
      _destBlocktime > 0 && _srcBlocktime > 0,
      "MergeNodes: Invalid blocktime"
    );
    require(
      !nodeStorage.isNodeDeleted(_account, _destBlocktime),
      "MergeNodes: Destination node deleted"
    );

    INodeStorage.NodeEntity memory sourceNode = nodeStorage.getNode(
      _account,
      _srcBlocktime
    );

    nodeStorage.setDeleted(_account, _srcBlocktime, true);
    nodeStorage.addAmount(_account, _destBlocktime, sourceNode.amount);
    nodeStorage.setLastClaimTime(_account, _destBlocktime, block.timestamp);
    nodeStorage.setLastCompoundTime(_account, _destBlocktime, block.timestamp);

    totalNodesCreated--;

    emit NodeMerged(_account, _srcBlocktime, _destBlocktime);
  }

  function _calculateBoost(uint256 _lastClaimTime)
    internal
    view
    returns (uint256)
  {
    uint256 elapsedTime_ = (block.timestamp - _lastClaimTime);
    uint256 elapsedTimeInDays_ = elapsedTime_ / 1 days;

    if (elapsedTimeInDays_ >= _boostRequiredDays[2]) {
      return _boostMultipliers[2];
    } else if (elapsedTimeInDays_ >= _boostRequiredDays[1]) {
      return _boostMultipliers[1];
    } else if (elapsedTimeInDays_ >= _boostRequiredDays[0]) {
      return _boostMultipliers[0];
    } else {
      return 100;
    }
  }

  function _calculateCompoundBonus(uint256 nodeAmount)
    internal
    view
    returns (uint256)
  {
    uint256 _compoundBonus;

    if (nodeAmount < _compoundRequiredTokens[0] * 10**18) {
      _compoundBonus = _compoundMultipliers[0];
    } else if (nodeAmount < _compoundRequiredTokens[1] * 10**18) {
      _compoundBonus = _compoundMultipliers[1];
    } else if (nodeAmount < _compoundRequiredTokens[2] * 10**18) {
      _compoundBonus = _compoundMultipliers[2];
    } else {
      _compoundBonus = 100;
    }

    return _compoundBonus;
  }

  // Firewall methods

  function pause() external onlyAuthorized {
    _pause();
  }

  function unpause() external onlyAuthorized {
    _unpause();
  }
}