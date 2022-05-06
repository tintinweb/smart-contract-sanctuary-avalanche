/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-05
*/

/**
 *Submitted for verification at snowtrace.io on 2022-03-04
 */

/**
 *Submitted for verification at snowtrace.io on 2022-03-04
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Strings {
    function _indexOf(
        string memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int256(i);
            }
        }
        return -1;
    }

    function length(string memory _base) internal pure returns (uint256) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr)
    {
        bytes memory _baseBytes = bytes(_base);

        uint256 _offset = 0;
        uint256 _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) break;
            else {
                _splitsCount++;
                _offset = uint256(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int256(_baseBytes.length);
            }

            string memory _tmp = new string(uint256(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint256 j = 0;
            for (uint256 i = _offset; i < uint256(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint256(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
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

interface IZeusNodeManager {
    function nodePrice() external returns (uint256);

    function rewardPerNode() external view returns (uint256);

    function claimTime() external returns (uint256);

    function gateKeeper() external returns (address);

    function token() external returns (address);

    function totalNodesCreated() external view returns (uint256);

    function totalRewardStaked() external returns (uint256);

    function _getNodesNames(address account)
        external
        view
        returns (string memory);

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory);

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory);

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256);

    function _getNodeNumberOf(address account) external view returns (uint256);

    function _isNodeOwner(address account) external view returns (bool);

    function createNode(
        address account,
        string memory nodeName,
        address referred_by,
        uint32 nodeType,
        uint256 total
    ) external;

    function _cashoutNodeReward(address account, uint256 _creationTime)
        external
        returns (uint256, uint256);

    function _getNodeRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _cashoutAllNodesReward(address account)
        external
        returns (uint256, uint256);

    function _getRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _cashoutAllNodesByTypeReward(address account, uint32 nodeType)
        external
        returns (uint256, uint256);

    function getReferralBonus(address account) external view returns (uint256);

    function getReferrals(address referred_by)
        external
        view
        returns (address[] memory);

    function withdrawReferralBonus(address account) external returns (uint256);

    function getNodePriceByType(uint32 nodeType)
        external
        view
        returns (uint256);

    function getNodeRewardByType(uint32 nodeType)
        external
        view
        returns (uint256);
    function _getTotalUserNodes(address account) external view returns (uint256);
}

interface IZeus {
    function owner() external view returns (address);

    function transferOwnership(address addr) external;

    function nodeRewardManager() external view returns (address);

    function setNodeManagement(address nodeManagement) external;

    // functions to update the managementV1 contract, before we switch it out with the main contract
    function changeNodePrice(uint256 newNodePrice) external;

    function changeRewardPerNode(uint256 newPrice) external;

    function changeClaimTime(uint256 newTime) external;

    function getTotalCreatedNodes() external returns (uint256);

    function getTotalStakedReward() external returns (uint256);
}

contract Migrator {
    using Strings for string;
    address internal migrator;
    bool initialized;

    IZeus public Zeus;
    IZeusNodeManager public NodeManagerV1 =
        IZeusNodeManager(0xe59A026E63625C791024514a86A3742c6F30f4EA);

    function st2num(string memory numString) internal pure returns (uint256) {
        uint256 val = 0;
        bytes memory stringBytes = bytes(numString);
        for (uint256 i = 0; i < stringBytes.length; i++) {
            uint256 exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint256 jval = uval - uint256(0x30);
            val += (uint256(jval) * (10**(exp - 1)));
        }
        return val;
    }

    function splitWithDelimiter(string memory str)
        internal
        pure
        returns (string[] memory)
    {
        string[] memory split = str.split("#");
        return split;
    }
}

interface IMasterOfCoin {
    function getDueDate(string memory nodeId) external view returns (uint256);
}

contract ZeusNodeManagerBridge is Migrator {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;
    IMasterOfCoin public masterOfCoin;
    uint256 size = 4;
    string public bridgeName = "ZEUS";

    address public gateKeeper = 0xa85c464C91a80903F4149911CCA8F47BC78411Dc; //change gatekeeper to deployer address
    address public token; //set the zeus contract here

    uint256[4] public limits = [604800, 1728000, 3456000, 3456000]; //days converted to seconds
    uint256[4] public taxes = [75, 45, 20, 10];

    function setNodeManagerV1(address addr) public onlySentry {
        NodeManagerV1 = IZeusNodeManager(addr);
    }

    function updateLimit(uint256[4] memory _limits, uint256[4] memory _taxes)
        external
        onlySentry
    {
        require(_limits.length == _taxes.length, "arrays must be equal");
        require(limits.length == 4, "array length must be equal 4");
        limits = _limits;
        taxes = _taxes;
    }

    function getNodePriceByType(uint32 nodeType)
        external
        view
        onlySentry
        returns (uint256)
    {
        return NodeManagerV1.getNodePriceByType(nodeType);
    }

    function getNodeRewardByType(uint32 nodeType)
        external
        view
        onlySentry
        returns (uint256)
    {
        return NodeManagerV1.getNodeRewardByType(nodeType);
    }

    modifier onlySentry() {
        require(
            msg.sender == token ||
                msg.sender == gateKeeper ||
                msg.sender == migrator,
            "NodeManagerV2: NOT AUTHORIZED"
        );
        _;
    }

    function setToken(address token_) external onlySentry {
        Zeus = IZeus(token_);
        token = token_;
    }

    function createNode(
        address account,
        string memory nodeName,
        address referred_by,
        uint32 nodeType,
        uint256 total
    ) external onlySentry {
        NodeManagerV1.createNode(
            account,
            nodeName,
            referred_by,
            nodeType,
            total
        );
    }

    function getLastCreationTime(address account) external view returns(string memory){
         string[] memory creationTimes = splitWithDelimiter(
            NodeManagerV1._getNodesCreationTime(account)
        );
        return creationTimes[creationTimes.length - 1];
    }

    function _cashoutNodeReward(address account, uint256 _creationTime)
        public
        onlySentry
        returns (uint256, uint256)
    {
        uint256 dueDate = _getNodeDueDate(account, _creationTime);
        if (block.timestamp > dueDate) {
            return (0, 0);
        }
        uint256 fee = 0;
        (uint256 nodeReward, ) = NodeManagerV1._cashoutNodeReward(
            account,
            _creationTime
        );

        string[] memory creationTimes = splitWithDelimiter(
            NodeManagerV1._getNodesCreationTime(account)
        );
        string[] memory lastClaimTimes = splitWithDelimiter(
            NodeManagerV1._getNodesCreationTime(account)
        );
        string memory lastClaimTime;
        for (uint256 i = 0; i < creationTimes.length; i++) {
            if (st2num(creationTimes[i]) == _creationTime) {
                lastClaimTime = lastClaimTimes[i];
                break;
            }
        }
        if (block.timestamp - st2num(lastClaimTime) <= limits[0]) {
            fee += nodeReward.mul(taxes[0]).div(100);
        }
        if (
            block.timestamp - st2num(lastClaimTime) > limits[0] &&
            block.timestamp - st2num(lastClaimTime) <= limits[1]
        ) {
            fee += nodeReward.mul(taxes[1]).div(100);
        }
        if (
            block.timestamp - st2num(lastClaimTime) > limits[1] &&
            block.timestamp - st2num(lastClaimTime) <= limits[2]
        ) {
            fee += nodeReward.mul(taxes[2]).div(100);
        }
        if (block.timestamp - st2num(lastClaimTime) > limits[3]) {
            fee += nodeReward.mul(taxes[3]).div(100);
        }

        return (nodeReward, fee);
    }

    function _cashoutAllNodesReward(address account)
        public
        onlySentry
        returns (uint256, uint256)
    {
        string[] memory creationTimes = splitWithDelimiter(
            NodeManagerV1._getNodesCreationTime(account)
        );
        string[] memory lastClaimTimes = splitWithDelimiter(
            NodeManagerV1._getNodesCreationTime(account)
        );
        uint256 nodesCount = creationTimes.length;
        uint256 fee = 0;
        // bool isDefector = false;
        uint256 rewardsTotal = 0;

        for (uint256 i = 0; i < nodesCount; i++) {
            uint256 nodeReward = _getRewardAmountOf(
                account,
                st2num(creationTimes[i])
            );
            if (nodeReward > 0) {
                if (block.timestamp - st2num(lastClaimTimes[i]) <= limits[0]) {
                    fee += nodeReward.mul(taxes[0]).div(100);
                }
                if (
                    block.timestamp - st2num(lastClaimTimes[i]) > limits[0] &&
                    block.timestamp - st2num(lastClaimTimes[i]) <= limits[1]
                ) {
                    fee += nodeReward.mul(taxes[1]).div(100);
                }
                if (
                    block.timestamp - st2num(lastClaimTimes[i]) > limits[1] &&
                    block.timestamp - st2num(lastClaimTimes[i]) <= limits[2]
                ) {
                    fee += nodeReward.mul(taxes[2]).div(100);
                }
                if (block.timestamp - st2num(lastClaimTimes[i]) > limits[3]) {
                    fee += nodeReward.mul(taxes[3]).div(100);
                }
                rewardsTotal += nodeReward;
            }
        }
        NodeManagerV1._cashoutAllNodesReward(account);
        return (rewardsTotal, fee);
    }

    function _getRewardAmountOf(address account) public view returns (uint256) {
        uint256 rewardCount = 0;
        string[] memory creationTimes = splitWithDelimiter(
            NodeManagerV1._getNodesCreationTime(account)
        );
        uint256 nodesCount = creationTimes.length;
        for (uint256 i = 0; i < nodesCount; i++) {
            rewardCount += _getRewardAmountOf(
                account,
                st2num(creationTimes[i])
            );
        }

        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 _creationTime)
        public
        view
        returns (uint256)
    {
        uint256 dueDate = _getNodeDueDate(account, _creationTime);
        if (block.timestamp > dueDate) {
            return 0;
        }
        return NodeManagerV1._getRewardAmountOf(account, _creationTime);
    }

    function _getNodeRewardAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256)
    {
        return NodeManagerV1._getNodeRewardAmountOf(account, creationTime);
    }

    function _getNodeId(address account, uint256 creationTime)
        internal
        view
        returns (string memory)
    {
        uint256 acountToNum = uint256(uint160(account));
        string memory nodeId = string(
            abi.encodePacked(
                bridgeName, "_",
                Strings.toString(acountToNum),
                "_",
                Strings.toString(creationTime)
            )
        );

        return nodeId;
    }

    function getNodeId(address account) external pure returns (string memory) {
        uint256 acountToNum = uint256(uint160(account));
        string memory nodeId = string(
            abi.encodePacked(Strings.toString(acountToNum))
        );

        return nodeId;
    }

    function _getNodeDueDate(address account, uint256 creationTime)
        public
        view
        returns (uint256)
    {
        string memory nodeId = _getNodeId(account, creationTime);
        return masterOfCoin.getDueDate(nodeId);
    }

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory)
    {
        string[] memory creationTimes = splitWithDelimiter(
            NodeManagerV1._getNodesCreationTime(account)
        );
        uint256 nodesCount = creationTimes.length;
        string memory _rewardsAvailable = uint2str(
            _getRewardAmountOf(account, st2num(creationTimes[0]))
        );
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(
                        _getRewardAmountOf(account, st2num(creationTimes[i]))
                    )
                )
            );
        }
        return _rewardsAvailable;
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

    function getReferrals(address referred_by)
        external
        view
        onlySentry
        returns (address[] memory)
    {
        return NodeManagerV1.getReferrals(referred_by);
    }

    function getReferralBonus(address account)
        external
        view
        onlySentry
        returns (uint256)
    {
        return NodeManagerV1.getReferralBonus(account);
    }

    function withdrawReferralBonus(address account)
        external
        onlySentry
        returns (uint256)
    {
        return NodeManagerV1.withdrawReferralBonus(account);
    }

    function setMasterOfCoin(address _master) external onlySentry {
        masterOfCoin = IMasterOfCoin(_master);
    }
    function _getNodeNumberOf(address account) public view returns (uint256) {
        return NodeManagerV1._getNodeNumberOf(account);
    }
    
    function totalNodesCreated() public view returns (uint256) {
        return NodeManagerV1.totalNodesCreated();
    }
    function _getTotalUserNodes(address account) public view returns (uint256) {
        return NodeManagerV1._getTotalUserNodes(account);
    }

    function _getNodesLastClaimTime(address account) public view returns (string memory) {
        return NodeManagerV1._getNodesLastClaimTime(account);
    }
    function rewardPerNode() public view returns (uint256) {
        return NodeManagerV1.rewardPerNode();
    }
    function _getNodesNames(address account) public view returns (string memory) {
        return NodeManagerV1._getNodesNames(account);
    }
    function _getNodesCreationTime(address account) public view returns (string memory) {
        return NodeManagerV1._getNodesCreationTime(account);
    }
}