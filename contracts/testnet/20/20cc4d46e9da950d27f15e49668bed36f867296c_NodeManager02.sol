// SPDX-License-Identifier: MIT
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./INodeManager.sol";

pragma solidity ^0.8.4;

contract NodeManager02 is Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint256;

  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 lastCompoundTime;
    uint256 amount;
    bool deleted;
  }

  address public token;
  uint256 public rewardPerNode;
  uint256 public minPrice;

  uint256 public totalNodesCreated = 0;
  uint256 public totalStaked = 0;

  uint256[] private _boostMultipliers = [105, 120, 140];
  uint256[] private _boostRequiredDays = [3, 7, 15];
  INodeManager private nodeManager01;

  mapping(address => bool) public isAuthorizedAddress;
  mapping(address => NodeEntity[]) private _nodesOfUser;
  mapping(address => bool) private migratedWallets;

  event NodeIncreased(address indexed account, uint256 indexed amount);
  event NodeRenamed(address indexed account, string newName);
  event NodeCreated(
    address indexed account,
    uint256 indexed amount,
    uint256 indexed blockTime
  );
  event NodeMerged(
    address indexed account,
    uint256 indexed sourceBlockTime,
    uint256 indexed destBlockTime
  );

  modifier onlyAuthorized() {
    require(isAuthorizedAddress[_msgSender()], "UNAUTHORIZED");
    _;
  }

  constructor(
    uint256 _rewardPerNode,
    uint256 _minPrice,
    address _nodeManager01
  ) {
    rewardPerNode = _rewardPerNode;
    minPrice = _minPrice;

    isAuthorizedAddress[_msgSender()] = true;

    nodeManager01 = INodeManager(_nodeManager01);
  }

  // Private methods

  function _isNameAvailable(address account, string memory nodeName)
    private
    view
    returns (bool)
  {
    NodeEntity[] memory nodes = _nodesOfUser[account];
    for (uint256 i = 0; i < nodes.length; i++) {
      if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
        return false;
      }
    }
    return true;
  }

  function _getNodeWithCreatime(
    NodeEntity[] storage nodes,
    uint256 _creationTime
  ) private view returns (NodeEntity storage) {
    uint256 numberOfNodes = nodes.length;
    require(
      numberOfNodes > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    bool found = false;
    int256 index = _binarySearch(nodes, 0, numberOfNodes, _creationTime);
    uint256 validIndex;
    if (index >= 0) {
      found = true;
      validIndex = uint256(index);
    }
    require(found, "NODE SEARCH: No NODE Found with this blocktime");
    return nodes[validIndex];
  }

  function _binarySearch(
    NodeEntity[] memory arr,
    uint256 low,
    uint256 high,
    uint256 x
  ) private view returns (int256) {
    if (high >= low) {
      uint256 mid = (high + low).div(2);
      if (arr[mid].creationTime == x) {
        return int256(mid);
      } else if (arr[mid].creationTime > x) {
        return _binarySearch(arr, low, mid - 1, x);
      } else {
        return _binarySearch(arr, mid + 1, high, x);
      }
    } else {
      return -1;
    }
  }

  function _uint2str(uint256 _i)
    private
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function _calculateNodeRewards(
    uint256 _lastClaimTime,
    uint256 _lastCompoundTime,
    uint256 amount_
  ) public view returns (uint256) {
    uint256 elapsedTime_ = (block.timestamp - _lastCompoundTime);
    uint256 _boostMultiplier = _calculateBoost(_lastClaimTime);
    uint256 rewardPerDay = amount_.mul(rewardPerNode).div(100);
    uint256 elapsedMinutes = elapsedTime_ / 1 minutes;
    uint256 rewardPerMinute = rewardPerDay.mul(10000).div(1440);

    return
      rewardPerMinute.mul(elapsedMinutes).div(10000).mul(_boostMultiplier).div(
        100
      );
  }

  function _calculateBoost(uint256 _lastClaimTime)
    public
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

  // External methods

  function createNode(
    address account,
    string memory nodeName,
    uint256 amount_
  ) external onlyAuthorized whenNotPaused {
    require(_isNameAvailable(account, nodeName), "Name not available");
    NodeEntity[] storage _nodes = _nodesOfUser[account];
    require(_nodes.length <= 100, "Max nodes exceeded");
    _nodes.push(
      NodeEntity({
        name: nodeName,
        creationTime: block.timestamp,
        lastClaimTime: block.timestamp,
        lastCompoundTime: block.timestamp,
        amount: amount_,
        deleted: false
      })
    );

    totalNodesCreated++;
    totalStaked += amount_;

    emit NodeCreated(account, amount_, block.timestamp);
  }

  function cashoutNodeReward(address account, uint256 _creationTime)
    external
    onlyAuthorized
    whenNotPaused
  {
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.lastClaimTime = block.timestamp;
    node.lastCompoundTime = block.timestamp;
  }

  function compoundNodeReward(
    address account,
    uint256 _creationTime,
    uint256 rewardAmount_
  ) external onlyAuthorized whenNotPaused {
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.amount += rewardAmount_;
    node.lastCompoundTime = block.timestamp;
  }

  function cashoutAllNodesRewards(address account)
    external
    onlyAuthorized
    whenNotPaused
  {
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity storage _node;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      if (!_node.deleted) {
        _node.lastClaimTime = block.timestamp;
        _node.lastCompoundTime = block.timestamp;
      }
    }
  }

  function compoundAllNodesRewards(address account)
    external
    onlyAuthorized
    whenNotPaused
  {
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity storage _node;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      if (!_node.deleted) {
        uint256 rewardAmount = getNodeReward(account, _node.creationTime);
        _node.amount += rewardAmount;
        _node.lastCompoundTime = block.timestamp;
      }
    }
  }

  function renameNode(
    address account,
    string memory _newName,
    uint256 _creationTime
  ) external onlyAuthorized whenNotPaused {
    require(_isNameAvailable(account, _newName), "Name not available");
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.name = _newName;
  }

  function mergeNodes(
    address account,
    uint256 _creationTime1,
    uint256 _creationTime2
  ) external onlyAuthorized whenNotPaused {
    require(_creationTime1 > 0 && _creationTime2 > 0, "MERGE:1");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node1 = _getNodeWithCreatime(nodes, _creationTime1);
    NodeEntity storage node2 = _getNodeWithCreatime(nodes, _creationTime2);

    node1.amount += node2.amount;
    node1.lastClaimTime = block.timestamp;
    node1.lastCompoundTime = block.timestamp;

    node2.deleted = true;
    totalNodesCreated--;

    emit NodeMerged(account, _creationTime2, _creationTime1);
  }

  function increaseNodeAmount(
    address account,
    uint256 _creationTime,
    uint256 _amount
  ) external onlyAuthorized whenNotPaused {
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.amount += _amount;
    node.lastCompoundTime = block.timestamp;
  }

  function migrateNodes(address account) external whenNotPaused nonReentrant {
    require(!migratedWallets[account], "Already migrated");
    INodeManager.NodeEntity[] memory oldNodes = nodeManager01.getAllNodes(
      account
    );
    require(oldNodes.length > 0, "LENGTH");
    NodeEntity[] storage _nodes = _nodesOfUser[account];
    require(_nodes.length + oldNodes.length <= 100, "Max nodes exceeded");

    for (uint256 index = 0; index < oldNodes.length; index++) {
      _nodes.push(
        NodeEntity({
          name: oldNodes[index].name,
          creationTime: oldNodes[index].creationTime,
          lastClaimTime: oldNodes[index].lastClaimTime,
          lastCompoundTime: oldNodes[index].lastClaimTime,
          amount: oldNodes[index].amount,
          deleted: false
        })
      );

      totalNodesCreated++;
      totalStaked += oldNodes[index].amount;
      migratedWallets[account] = true;

      emit NodeCreated(account, oldNodes[index].amount, block.timestamp);
    }
  }

  // Setters & Getters

  function setToken(address newToken) external onlyOwner {
    token = newToken;
  }

  function setRewardPerNode(uint256 newVal) external onlyOwner {
    rewardPerNode = newVal;
  }

  function setMinPrice(uint256 newVal) external onlyOwner {
    minPrice = newVal;
  }

  function setBoostMultipliers(uint8[] calldata newVal) external onlyOwner {
    require(newVal.length == 3, "Wrong length");
    _boostMultipliers = newVal;
  }

  function setBoostRequiredDays(uint8[] calldata newVal) external onlyOwner {
    require(newVal.length == 3, "Wrong length");
    _boostRequiredDays = newVal;
  }

  function setAuthorized(address account, bool newVal) external onlyOwner {
    isAuthorizedAddress[account] = newVal;
  }

  function getMinPrice() external view returns (uint256) {
    return minPrice;
  }

  function getNodeNumberOf(address account) external view returns (uint256) {
    return _nodesOfUser[account].length;
  }

  function getAllNodes(address account)
    external
    view
    returns (NodeEntity[] memory)
  {
    return _nodesOfUser[account];
  }

  function getAllNodesAmount(address account) external view returns (uint256) {
    NodeEntity[] memory nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NO_NODES");
    uint256 totalAmount_ = 0;
    for (uint256 i = 0; i < nodesCount; i++) {
      if (!nodes[i].deleted) {
        totalAmount_ += nodes[i].amount;
      }
    }

    return totalAmount_;
  }

  function getNodeReward(address account, uint256 _creationTime)
    public
    view
    returns (uint256)
  {
    require(_creationTime > 0, "E:1");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(nodes.length > 0, "E:2");
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    return
      _calculateNodeRewards(
        node.lastClaimTime,
        node.lastCompoundTime,
        node.amount
      );
  }

  function getAllNodesRewards(address account) external view returns (uint256) {
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "E:1");
    NodeEntity storage _node;
    uint256 rewardsTotal = 0;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      if (!_node.deleted) {
        rewardsTotal += _calculateNodeRewards(
          _node.lastClaimTime,
          _node.lastCompoundTime,
          _node.amount
        );
      }
    }
    return rewardsTotal;
  }

  // Firewall methods

  function pause() external onlyAuthorized {
    _pause();
  }

  function unpause() external onlyAuthorized {
    _unpause();
  }
}