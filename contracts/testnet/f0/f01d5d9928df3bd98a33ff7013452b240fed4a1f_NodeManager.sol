// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IterableMapping.sol";

pragma solidity 0.8.4;

contract NodeManager is Ownable, Pausable {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    struct NodeEntity {
        string name;
        uint creationTime;
        uint lastClaimTime;
        uint256 amount;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) private _nodesOfUser;

    address public token;
    uint8 public rewardPerNode;
    uint256 public minPrice;

    uint256 public totalNodesCreated = 0;
    uint256 public totalStaked = 0;
    uint256 public totalClaimed = 0;

    uint8[] private _boostMultipliers = [105, 120, 140];
    uint8[] private _boostRequiredDays = [3, 7, 15];

    event NodeCreated(
        uint256 indexed amount,
        address indexed account,
        uint indexed blockTime
    );

    modifier onlyGuard() {
        require(owner() == _msgSender() || token == _msgSender(), "NOT_GUARD");
        _;
    }

    modifier onlyNodeOwner(address account) {
        require(isNodeOwner(account), "NOT_OWNER");
        _;
    }

    constructor(
        uint8 _rewardPerNode,
        uint256 _minPrice
    ) {
        rewardPerNode = _rewardPerNode;
        minPrice = _minPrice;
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

    function _calculateNodeRewards(uint _lastClaimTime, uint256 amount_) private view returns (uint256 rewards) {
        uint256 elapsedTime_ = (block.timestamp - _lastClaimTime);
        uint256 boostMultiplier = _calculateBoost(elapsedTime_).div(100);
        uint256 rewardPerDay = amount_.mul(rewardPerNode).div(100);
        return ((rewardPerDay.mul(10000).div(1440) * (elapsedTime_ / 1 minutes)) / 10000) * boostMultiplier;
    }

    function _calculateBoost(uint elapsedTime_) internal view returns (uint256) {
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

    function createNode(address account, string memory nodeName, uint256 amount_) external onlyGuard whenNotPaused {
        require(
            _isNameAvailable(account, nodeName),
            "Name not available"
        );
        NodeEntity[] storage _nodes = _nodesOfUser[account];
        require(_nodes.length <= 100, "Max nodes exceeded");
        _nodes.push(
            NodeEntity({
                name: nodeName,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                amount: amount_
            })
        );
        nodeOwners.set(account, _nodesOfUser[account].length);
        emit NodeCreated(amount_, account, block.timestamp);
        totalNodesCreated++;
        totalStaked += amount_;
    }

    function getNodeReward(address account, uint256 _creationTime)
        external
        view
        returns (uint256)
    {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        require(
            nodes.length > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        return _calculateNodeRewards(node.lastClaimTime, node.amount);
    }

    function getAllNodesRewards(address account)
        external
        view
        returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            rewardsTotal += _calculateNodeRewards(_node.lastClaimTime, _node.amount);
        }
        return rewardsTotal;
    }

    function cashoutNodeReward(address account, uint256 _creationTime)
        external
        onlyGuard
        onlyNodeOwner(account)
        whenNotPaused
    {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        require(
            nodes.length > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        node.lastClaimTime = block.timestamp;
    }

    function compoundNodeReward(address account, uint256 _creationTime, uint256 rewardAmount_)
        external
        onlyGuard
        onlyNodeOwner(account)
        whenNotPaused
    {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        require(
            nodes.length > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);

        node.amount += rewardAmount_;
        node.lastClaimTime = block.timestamp;
    }

    function cashoutAllNodesRewards(address account)
        external
        onlyGuard
        onlyNodeOwner(account)
        whenNotPaused
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity storage _node;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            _node.lastClaimTime = block.timestamp;
        }
    }

    function getNodesNames(address account)
        public
        view
        onlyNodeOwner(account)
        returns (string memory)
    {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory names = nodes[0].name;
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            names = string(abi.encodePacked(names, separator, _node.name));
        }
        return names;
    }

    function getNodesCreationTime(address account)
        public
        view
        onlyNodeOwner(account)
        returns (string memory)
    {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _creationTimes = _uint2str(nodes[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    _uint2str(_node.creationTime)
                )
            );
        }
        return _creationTimes;
    }

    function getNodesLastClaimTime(address account)
        public
        view
        onlyNodeOwner(account)
        returns (string memory)
    {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _lastClaimTimes = _uint2str(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    _uint2str(_node.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function updateToken(address newToken) external onlyOwner {
        token = newToken;
    }

    function updateReward(uint8 newVal) external onlyOwner {
        rewardPerNode = newVal;
    }

    function updateMinPrice(uint256 newVal) external onlyOwner {
        minPrice = newVal;
    }

    function updateBoostMultipliers(uint8[] calldata newVal) external onlyOwner {
        require(newVal.length == 3, "Wrong length");
        _boostMultipliers = newVal;
    }

    function updateBoostRequiredDays(uint8[] calldata newVal) external onlyOwner {
        require(newVal.length == 3, "Wrong length");
        _boostRequiredDays = newVal;
    }

    function getMinPrice() external view returns (uint256) {
        return minPrice;
    }

    function getNodeNumberOf(address account) external view returns (uint256) {
        return nodeOwners.get(account);
    }

    function isNodeOwner(address account) public view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function getAllNodes(address account) external view returns (NodeEntity[] memory) {
        return _nodesOfUser[account];
    }

    function getIndexOfKey(address account) external view onlyOwner returns (int256) {
        require(account != address(0));
        return nodeOwners.getIndexOfKey(account);
    }

    function burn(uint256 index) external onlyOwner {
        require(index < nodeOwners.size());
        nodeOwners.remove(nodeOwners.getKeyAtIndex(index));
    }
}