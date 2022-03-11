// SPDX-License-Identifier: MIT
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Authorizable.sol";

pragma solidity ^0.8.4;

contract NodeStorage is Ownable, Pausable, Authorizable {
  using SafeMath for uint256;

  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 lastCompoundTime;
    uint256 amount;
    bool deleted;
  }

  mapping(address => bool) public migratedWallets;
  mapping(address => NodeEntity[]) private nodeEntities;

  // Private methods

  function _isNameAvailable(address account, string memory nodeName)
    private
    view
    returns (bool)
  {
    NodeEntity[] memory nodes = nodeEntities[account];
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
      "GetNodeWithCreatime: No nodes found for this account"
    );
    bool found = false;
    int256 index = _binarySearch(nodes, 0, numberOfNodes, _creationTime);
    uint256 validIndex;
    if (index >= 0) {
      found = true;
      validIndex = uint256(index);
    }
    require(found, "GetNodeWithCreatime: Not found");
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

  function getNodeOfUser(address account, uint256 creationTime)
    internal
    view
    returns (NodeEntity storage)
  {
    NodeEntity[] storage nodes = nodeEntities[account];
    NodeEntity storage node = _getNodeWithCreatime(nodes, creationTime);

    return node;
  }

  // External Methods

  function createNode(
    address _account,
    string memory _name,
    uint256 _amount
  ) external onlyAuthorized whenNotPaused returns (bool) {
    require(_account != address(0), "CreateNode: account is not valid");
    require(_amount > 0, "CreateNode: amount is not valid");
    require(
      bytes(_name).length > 3 && bytes(_name).length < 32,
      "CreateNode: Invalid length"
    );
    require(
      _isNameAvailable(_account, _name),
      "CreateNode: Name not available"
    );

    NodeEntity[] storage _nodes = nodeEntities[_account];
    _nodes.push(
      NodeEntity({
        name: _name,
        creationTime: block.timestamp,
        lastClaimTime: block.timestamp,
        lastCompoundTime: block.timestamp,
        amount: _amount,
        deleted: false
      })
    );

    return true;
  }

  function migrateNode(
    address _account,
    string memory _name,
    uint256 _amount,
    uint256 _creationTime,
    uint256 _lastClaimTime,
    uint256 _lastCompoundTime
  ) external onlyAuthorized whenNotPaused returns (bool) {
    require(_account != address(0), "MigrateNode: account is not valid");
    require(_amount > 0, "MigrateNode: amount is not valid");
    require(_creationTime != 0, "MigrateNode: creationTime is not valid");
    require(_lastClaimTime != 0, "MigrateNode: lastClaimTime is not valid");
    require(
      _lastCompoundTime != 0,
      "MigrateNode: lastCompoundTime is not valid"
    );
    require(_isNameAvailable(_account, _name), "Migrate: Name not available");

    NodeEntity[] storage _nodes = nodeEntities[_account];
    _nodes.push(
      NodeEntity({
        name: _name,
        creationTime: _creationTime,
        lastClaimTime: _lastClaimTime,
        lastCompoundTime: _lastCompoundTime,
        amount: _amount,
        deleted: false
      })
    );

    return true;
  }

  function setName(
    address _account,
    uint256 _creationTime,
    string memory _name
  ) external onlyAuthorized whenNotPaused returns (bool) {
    require(_account != address(0), "SetName: Invalid account");
    require(_creationTime != 0, "SetName: Invalid creation time");
    require(
      bytes(_name).length > 3 && bytes(_name).length < 32,
      "SetName: Invalid length"
    );
    require(_isNameAvailable(_account, _name), "SetName: Name not available");
    NodeEntity storage node = getNodeOfUser(_account, _creationTime);
    node.name = _name;
    return true;
  }

  function setLastClaimTime(
    address _account,
    uint256 _creationTime,
    uint256 _timestamp
  ) external onlyAuthorized whenNotPaused returns (bool) {
    require(_account != address(0), "SetLastClaimTime: Invalid account");
    require(_creationTime != 0, "SetLastClaimTime: Invalid creationTime");
    require(_timestamp != 0, "SetLastClaimTime: Invalid timestamp");
    NodeEntity storage node = getNodeOfUser(_account, _creationTime);
    node.lastClaimTime = _timestamp;
    return true;
  }

  function setLastCompoundTime(
    address _account,
    uint256 _creationTime,
    uint256 _timestamp
  ) external onlyAuthorized whenNotPaused returns (bool) {
    require(_account != address(0), "SetLastCompoundTime: Invalid account");
    require(_creationTime != 0, "SetLastCompoundTime: Invalid creationTime");
    require(_timestamp != 0, "SetLastCompoundTime: Invalid timestamp");
    NodeEntity storage node = getNodeOfUser(_account, _creationTime);
    node.lastCompoundTime = _timestamp;
    return true;
  }

  function addAmount(
    address _account,
    uint256 _creationTime,
    uint256 _amount
  ) external onlyAuthorized whenNotPaused returns (bool) {
    require(_account != address(0), "AddAmount: Invalid account");
    require(_creationTime != 0, "AddAmount: Invalid creationTime");
    require(_amount > 0, "AddAmount: Invalid amount");
    NodeEntity storage node = getNodeOfUser(_account, _creationTime);
    node.amount = node.amount.add(_amount);
    return true;
  }

  function setDeleted(
    address _account,
    uint256 _creationTime,
    bool _isDeleted
  ) external onlyAuthorized whenNotPaused returns (bool) {
    require(_account != address(0), "SetDeleted: Invalid account");
    require(_creationTime != 0, "SetDeleted: Invalid creationTime");
    NodeEntity storage node = getNodeOfUser(_account, _creationTime);
    node.deleted = _isDeleted;
    return true;
  }

  function getNode(address _account, uint256 _creationTime)
    external
    view
    returns (NodeEntity memory)
  {
    NodeEntity memory node = getNodeOfUser(_account, _creationTime);
    require(!node.deleted, "GetNode: Node is deleted");
    return node;
  }

  function getAllNodes(address _account)
    external
    view
    returns (NodeEntity[] memory)
  {
    NodeEntity[] memory nodes = nodeEntities[_account];
    return nodes;
  }

  function getAllActiveNodes(address _account)
    external
    view
    returns (NodeEntity[] memory)
  {
    NodeEntity[] memory nodes = nodeEntities[_account];
    NodeEntity[] memory activeNodes = new NodeEntity[](nodes.length);
    uint256 numberOfActiveNodes = 0;
    for (uint256 i = 0; i < nodes.length; i++) {
      NodeEntity memory node = nodes[i];
      if (!node.deleted) {
        activeNodes[numberOfActiveNodes] = node;
        numberOfActiveNodes++;
      }
    }
    return activeNodes;
  }

  function getAllDeletedNodes(address _account)
    external
    view
    returns (NodeEntity[] memory)
  {
    NodeEntity[] memory nodes = nodeEntities[_account];
    NodeEntity[] memory deletedNodes = new NodeEntity[](nodes.length);
    uint256 numberOfDeletedNodes = 0;
    for (uint256 i = 0; i < nodes.length; i++) {
      if (nodes[i].deleted) {
        deletedNodes[numberOfDeletedNodes] = nodes[i];
        numberOfDeletedNodes++;
      }
    }
    return deletedNodes;
  }

  function getNodesCount(address _account) external view returns (uint256) {
    NodeEntity[] memory nodes = nodeEntities[_account];
    uint256 numberOfActiveNodes = 0;
    for (uint256 i = 0; i < nodes.length; i++) {
      if (!nodes[i].deleted) {
        numberOfActiveNodes++;
      }
    }
    return numberOfActiveNodes;
  }

  function getAllNodesAmount(address _account) external view returns (uint256) {
    NodeEntity[] memory nodes = nodeEntities[_account];
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < nodes.length; i++) {
      if (!nodes[i].deleted) {
        totalAmount = totalAmount.add(nodes[i].amount);
      }
    }

    return totalAmount;
  }

  function isNodeDeleted(address _account, uint256 _creationTime)
    external
    view
    returns (bool)
  {
    NodeEntity storage node = getNodeOfUser(_account, _creationTime);
    return node.deleted;
  }

  // Firewall methods

  function pause() external onlyAuthorized {
    _pause();
  }

  function unpause() external onlyAuthorized {
    _unpause();
  }
}