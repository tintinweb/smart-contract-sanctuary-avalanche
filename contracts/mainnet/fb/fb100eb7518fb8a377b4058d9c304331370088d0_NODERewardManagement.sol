/**
 *Submitted for verification at snowtrace.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract NODERewardManagement {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    struct NodeEntity {
        string name;
        uint kind;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 lastAvailabe;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) private _nodesOfUser;

    uint256[3] public prices;
    uint256[3] public rewards;
    uint256[4] public slideTax;
    uint256[4] public slideTaxDay;

    address public gateKeeper;
    address public token;

    uint256 public totalNodesCreated = 0;
    uint256[3] public totalNodesCreatedKind = [0, 0, 0];

    constructor(
        uint256[3] memory _prices, 
        uint256[3] memory _rewards, 
        uint256[4] memory _slideTax, 
        uint256[4] memory _slideTaxDay
    ) {
        prices = _prices;
        rewards = _rewards;
        slideTax = _slideTax;
        slideTaxDay = _slideTaxDay;
        gateKeeper = msg.sender;
    }

    modifier onlySentry() {
        require(msg.sender == token || msg.sender == gateKeeper, "Fuck off");
        _;
    }

    function setToken(address token_) external onlySentry {
        token = token_;
    }

    function createNode(address account, string memory nodeName, uint kind)
        external
        onlySentry
    {
        require(
            isNameAvailable(account, nodeName),
            "CREATE NODE: Name not available"
        );

        _nodesOfUser[account].push(
            NodeEntity({
                name: nodeName,
                kind: kind,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                lastAvailabe: 0
            })
        );

        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
        totalNodesCreatedKind[kind] = totalNodesCreatedKind[kind].add(1);
    }

    function isNameAvailable(address account, string memory nodeName)
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

    function _burn(uint256 index) internal {
        require(index < nodeOwners.size());
        nodeOwners.remove(nodeOwners.getKeyAtIndex(index));
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
        int256 index = binary_search(nodes, 0, numberOfNodes, _creationTime);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function binary_search(
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
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }

    function _cashoutAllNodesReward(address account, uint256 amount, bool takeTax)
        external
        onlySentry
        returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;

        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");

        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        uint256 nodeReward = 0;

        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            nodeReward = (block.timestamp.sub(_node.lastClaimTime)).div(86400).mul(rewards[_node.kind]).add(_node.lastAvailabe);

            if (takeTax) {
                uint tax = _calcSlideTax(_node);
                nodeReward = nodeReward.mul(100-tax).div(100);
            }

            if((amount > 0 && rewardsTotal.add(nodeReward) <= amount) || amount == 0) {
                rewardsTotal = rewardsTotal.add(nodeReward);
                _node.lastAvailabe = 0;
                nodes[i].lastClaimTime = block.timestamp;
            }
            else if(amount > 0 && rewardsTotal.add(nodeReward) > amount) {
                _node.lastAvailabe = rewardsTotal.add(nodeReward).sub(amount);
                nodes[i].lastClaimTime = block.timestamp;
                break;
            }
        }

        return rewardsTotal;
    }
    
    function _cashoutAllNodesRewardKind(address account, uint256 amount, uint kind, bool takeTax)
        external
        onlySentry
        returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;

        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");

        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        uint256 nodeReward = 0;

        for (uint256 i = 0; i < nodesCount; i++) {
            if(nodes[i].kind != kind)
                continue;

            _node = nodes[i];
            nodeReward = (block.timestamp.sub(_node.lastClaimTime)).div(86400).mul(rewards[_node.kind]).add(_node.lastAvailabe);

            if (takeTax) {
                uint tax = _calcSlideTax(_node);
                nodeReward = nodeReward.mul(100-tax).div(100);
            }

            if((amount > 0 && rewardsTotal.add(nodeReward) <= amount) || amount == 0) {
                rewardsTotal = rewardsTotal.add(nodeReward);
                _node.lastAvailabe = 0;
                nodes[i].lastClaimTime = block.timestamp;
            }
            else if(amount > 0 && rewardsTotal.add(nodeReward) > amount) {
                _node.lastAvailabe = rewardsTotal.add(nodeReward).sub(amount);
                nodes[i].lastClaimTime = block.timestamp;
                break;
            }
        }

        return rewardsTotal;
    }

    function _cashoutNodeReward(address account, uint256 _creationTime, bool takeTax)
        external
        onlySentry
        returns (uint256)
    {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");

        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;

        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );

        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 rewardNode = (block.timestamp.sub(node.lastClaimTime)).div(86400).mul(
            rewards[node.kind]
        ).add(node.lastAvailabe);

        if(takeTax) {
            uint tax = _calcSlideTax(node);
            rewardNode = rewardNode.mul(100-tax).div(100);
        }

        node.lastAvailabe = 0;
        node.lastClaimTime = block.timestamp;

        return rewardNode;
    }

    function _getRewardAmountOf(address account, bool takeTax)
        external
        view
        returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            uint256 _rewardAmount = (block.timestamp.sub(nodes[i].lastClaimTime)).div(86400).mul(rewards[nodes[i].kind]).add(nodes[i].lastAvailabe);

            if (takeTax) {
                uint tax = _calcSlideTax(nodes[i]);
                _rewardAmount = _rewardAmount.mul(100-tax).div(100);
            }

            rewardCount = rewardCount.add(_rewardAmount);
        }

        return rewardCount;
    }

    function _getRewardAmountOfKind(address account, uint kind, bool takeTax)
        external
        view
        returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            if(nodes[i].kind != kind)
                continue;

            uint256 _rewardAmount = (block.timestamp.sub(nodes[i].lastClaimTime)).div(86400).mul(rewards[nodes[i].kind]).add(nodes[i].lastAvailabe);

            if (takeTax) {
                uint tax = _calcSlideTax(nodes[i]);
                _rewardAmount = _rewardAmount.mul(100-tax).div(100);
            }

            rewardCount = rewardCount.add(_rewardAmount);
        }

        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 _creationTime, bool takeTax)
        external
        view
        returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");

        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;

        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );

        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 rewardNode = (block.timestamp.sub(node.lastClaimTime)).div(86400).mul(
            rewards[node.kind]
        ).add(node.lastAvailabe);

        if (takeTax) {
            uint tax = _calcSlideTax(node);
            rewardNode = rewardNode.mul(100-tax).div(100);
        }

        return rewardNode;
    }

    function _getNodeNumberOfKind(address account, uint kind) external view returns (uint256)
    {
        require(isNodeOwner(account), "GET NODE NUMBER: NO NODE OWNER");

        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;

        uint256 count = 0;

        for (uint256 i = 0; i < nodesCount; i++) {
            if(nodes[i].kind == kind)
                count = count.add(1);
        }

        return count;
    }

    function _getNodesNames(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET NAMES: NO NODE OWNER");

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

    function _getNodesNamesKind(address account, uint256 id)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET NAMES: NO NODE OWNER");

        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory names;
        string memory separator = "#";
        uint256 index;

        for (uint256 i = 0; i < nodesCount; i++) {
            if(nodes[i].kind == id) {
                names = nodes[i].name;
                index = i;
                break;
            }
        }

        for (uint256 i = index + 1; i < nodesCount; i++) {
            if(nodes[i].kind == id) {
                _node = nodes[i];
                names = string(abi.encodePacked(names, separator, _node.name));
            }
        }

        return names;
    }

    function _getNodesCreationTimeKind(address account, uint256 id)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");

        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _creationTimes;
        string memory separator = "#";
        uint256 index;

        for (uint256 i = 0; i < nodesCount; i++) {
            if(nodes[i].kind == id) {
                _creationTimes = uint2str(nodes[i].creationTime);
                index = i;
                break;
            }
        }

        for (uint256 i = index + 1; i < nodesCount; i++) {
            if(nodes[i].kind == id) {
                _node = nodes[i];

                _creationTimes = string(
                    abi.encodePacked(
                        _creationTimes,
                        separator,
                        uint2str(_node.creationTime)
                    )
                );  
            }
        }
        return _creationTimes;
    }

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");

        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _creationTimes = uint2str(nodes[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    uint2str(_node.creationTime)
                )
            );
        }
        return _creationTimes;
    }

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");

        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        uint256 reward = ((block.timestamp.sub(nodes[0].lastClaimTime)).div(86400).mul
            (rewards[nodes[0].kind])).add(nodes[0].lastAvailabe);
        string memory _rewardsAvailable = uint2str(reward);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            reward = (block.timestamp.sub(_node.lastClaimTime)).div(86400).mul(
                rewards[_node.kind]
            ).add(_node.lastAvailabe);
            _rewardsAvailable = string(
                abi.encodePacked(_rewardsAvailable, separator, uint2str(reward))
            );
        }

        return _rewardsAvailable;
    }

    function _getNodesRewardAvailableKind(address account, uint256 id)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");

        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        uint256 reward;
        string memory _rewardsAvailable;
        string memory separator = "#";
        uint256 index;

        for (uint256 i = 0; i < nodesCount; i++) {
            if(nodes[i].kind == id) {
                reward = ((block.timestamp.sub(nodes[i].lastClaimTime)).div(86400).mul(rewards[nodes[i].kind])).add(nodes[i].lastAvailabe);
                _rewardsAvailable = uint2str(reward);
                index = i;
                break;
            }
        }

        for (uint256 i = index + 1; i < nodesCount; i++) {
            if(nodes[i].kind == id) {
                _node = nodes[i];
                reward = (block.timestamp.sub(_node.lastClaimTime)).div(86400).mul(
                    rewards[_node.kind]
                ).add(_node.lastAvailabe);
                _rewardsAvailable = string(
                    abi.encodePacked(_rewardsAvailable, separator, uint2str(reward))
                );
            }
        }

        return _rewardsAvailable;
    }

    function _getNodesLastClaimTimeKind(address account, uint256 id)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "LAST CLAIME TIME: NO NODE OWNER");

        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _lastClaimTimes;
        string memory separator = "#";
        uint256 index;

        for (uint256 i = 0; i < nodesCount; i++) {
            if(nodes[i].kind == id) {
                _lastClaimTimes = uint2str(nodes[i].lastClaimTime);
                index = i;
                break;
            }
        }

        for (uint256 i = index + 1; i < nodesCount; i++) {
            if(nodes[i].kind == id) {
                _node = nodes[i];

                _lastClaimTimes = string(
                    abi.encodePacked(
                        _lastClaimTimes,
                        separator,
                        uint2str(_node.lastClaimTime)
                    )
                );
            }
        }
        return _lastClaimTimes;
    }

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "LAST CLAIME TIME: NO NODE OWNER");

        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _lastClaimTimes = uint2str(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    uint2str(_node.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function uint2str(uint256 _i)
        internal
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

    function _calcSlideTax(NodeEntity memory node) internal view returns (uint) {
        uint tax = 0;
        uint256 passedDays = (block.timestamp.sub(node.creationTime)).div(86400);

        if(passedDays <= slideTaxDay[1]){
            tax = slideTax[0];
        } else if(passedDays > slideTaxDay[1] && passedDays <= slideTaxDay[2]) {
            tax = slideTax[1];
        } else if(passedDays > slideTaxDay[2] && passedDays <= slideTaxDay[3]) {
            tax = slideTax[2];
        } else if(passedDays > slideTaxDay[3]) {
            tax = slideTax[3];
        }
        
        return tax;
    }

    function _changeNodePrice(uint256[3] memory newNodePrice) external onlySentry {
        prices = newNodePrice;
    }

    function _changeRewardPerNode(uint256[3] memory newReward) external onlySentry {
        rewards = newReward;
    }

    function _changeSlideTax(uint256[4] memory _newSlideTax) external onlySentry {
        slideTax = _newSlideTax;
    }

    function _changeSlideTaxDay(uint256[4] memory _newSlideTaxDay) external onlySentry {
        slideTaxDay = _newSlideTaxDay;
    }

    function _getNodeNumberOf(address account) external view returns (uint256) {
        return nodeOwners.get(account);
    }

    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }
}