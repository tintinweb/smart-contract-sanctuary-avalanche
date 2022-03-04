/**
 *Submitted for verification at snowtrace.io on 2022-03-04
*/

/**
 *Submitted for verification at snowtrace.io on 2022-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;require(c >= a, "SafeMath: addition overflow");return c;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return sub(a, b, "SafeMath: subtraction overflow");}
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {require(b <= a, errorMessage);uint256 c = a - b;return c;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;}uint256 c = a * b;require(c / a == b, "SafeMath: multiplication overflow");return c;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return div(a, b, "SafeMath: division by zero");}
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {require(b > 0, errorMessage);uint256 c = a / b;return c;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return mod(a, b, "SafeMath: modulo by zero");}
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {require(b != 0, errorMessage);return a % b;}
}

library Strings {
    function _indexOf(string memory _base, string memory _value, uint _offset) internal pure returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }
        return -1;
    }
    function length(string memory _base)
        internal
        pure
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    function split(string memory _base, string memory _value) internal pure returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);

        uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == - 1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
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

    function get(Map storage map, address key) public view returns (uint256) {return map.values[key];}

    function getIndexOfKey(Map storage map, address key) public view returns (int256) {
        if (!map.inserted[key]) {return -1;}
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index) public view returns (address) {return map.keys[index];}

    function size(Map storage map) public view returns (uint256) {return map.keys.length;}

    function set(Map storage map,address key,uint256 val) public {
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
        if (!map.inserted[key]) {return;}

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

interface IZeusNodeManagerV1 {
    function nodePrice() external returns (uint256);
    function rewardPerNode() external returns (uint256);
    function claimTime() external returns (uint256);

    function gateKeeper() external returns (address);
    function token() external returns (address);
 
    function totalNodesCreated() external returns (uint256);
    function totalRewardStaked() external returns (uint256);

    function _getNodesNames (address account) external view returns (string memory);
    function _getNodesCreationTime (address account) external view returns (string memory);
    function _getNodesLastClaimTime (address account) external view returns (string memory);

    function _getRewardAmountOf (address account) external view returns (uint256);

    function _getNodeNumberOf (address account) external view returns (uint256);
    function _isNodeOwner (address account) external view returns (bool);
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





contract Migrator{
    using Strings for string;
    address internal migrator;
    bool initialized;
    function init0() public {
        require(initialized==false,"ALREADY INITIALIZED");
        migrator = msg.sender;
    }
    mapping(address => mapping(uint256 => bool)) public migrated;
    uint256 migrationTimeStamp;
    uint256 migrationBlockNumber;
    IZeus public Zeus;
    IZeusNodeManagerV1 public NodeManagerV1 = IZeusNodeManagerV1(0xe59A026E63625C791024514a86A3742c6F30f4EA);

    function st2num(string memory numString) internal pure returns(uint) {
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint jval = uval - uint(0x30);   
            val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }

    function indexOf(string memory _base, string memory _value, uint256 _offset) internal pure returns (uint256) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);
        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return uint256(i);
            }
        }
        return 0;
    }

    function splitWithDelimiter(string memory str) internal pure returns(string[] memory){
        string[] memory split = str.split("#");
        return split;
    }

}

contract NodeManagerV2 is Migrator{
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardAvailable;
    }

    IterableMapping.Map private nodeOwners;    
    mapping(address => NodeEntity[]) public _nodesOfUser;

    uint256 public nodePrice;
    uint256 public rewardPerNode;
    uint256 public claimTime;

    address public gateKeeper;
    address public token;
    
    uint256 public totalNodesCreated;
    uint256 public totalRewardStaked;

    
    function init() public {
        require(!initialized,"ALREADY INITIALIZED");
        init0();
        initialized = true;
        
        nodePrice       = NodeManagerV1.nodePrice();

        //rewardPerNode   = NodeManagerV1.rewardPerNode();
        rewardPerNode   = 5787037037037;

        //claimTime       = NodeManagerV1.claimTime();
        claimTime       = 1;

        gateKeeper      = NodeManagerV1.gateKeeper();
        token           = NodeManagerV1.token();
        Zeus            = IZeus(token);

        totalNodesCreated = NodeManagerV1.totalNodesCreated();
        totalRewardStaked = NodeManagerV1.totalRewardStaked();        
    }
    
    // this can be done if the main Zeus contract ownership
    // is temporarily transferred to this contract
    function finalizeMigration() public onlySentry {

        // change the settings on the NodeManagerV1 contract.
        // set the node price on the V1 contract to the max, so no one buys a node from it.
        Zeus.changeNodePrice(type(uint256).max);
        Zeus.changeRewardPerNode(0);
        Zeus.changeClaimTime(type(uint256).max);

        // get the current values for nodesCreated and rewardsStaked
        totalNodesCreated = Zeus.getTotalCreatedNodes();
        totalRewardStaked = Zeus.getTotalStakedReward();

        // set the manager tho this address
        Zeus.setNodeManagement(address(this));
        // check to make sure the address was set
        require(Zeus.nodeRewardManager()==address(this),"UPDATING NODE MANAGER FAILED!");

        // set the owner back to the original owner
        Zeus.transferOwnership(gateKeeper);
        // check to make sure the address was set
        require(Zeus.owner()==0xb223D4E661ecF6ced8BB6c99edB87B3331cbd7E3,"UPDATING OWNER FAILED!");

        migrationTimeStamp = block.timestamp;
        migrationBlockNumber = block.number;
    }

    
    function setNodeManagerV1(address addr) public onlySentry{
        NodeManagerV1 = IZeusNodeManagerV1(addr);
    }

    function transferZeusOwnership(address addr) public onlySentry {
         Zeus.transferOwnership(addr);
    }

    function setGateKeeper(address addr) public onlySentry {
        gateKeeper = addr;
    }

    modifier onlySentry() {require(msg.sender == token || msg.sender == gateKeeper || msg.sender == migrator, "NodeManagerV2: NOT AUTHORIZED");_;}

    // if anyone runs into a gas error, we can manually change the total number of migrated nodes on an individual basis.
    function migrate_admin_manually(address addr,uint256 fromNodeIndex, uint256 toNodeIndex) public onlySentry {migrate_(addr, fromNodeIndex, toNodeIndex, 999);}

    function migrate_0_admin(address addr) public onlySentry {migrate_(addr, 0,  49, 0);}
    function migrate_1_admin(address addr) public onlySentry {migrate_(addr, 50, 99, 1);}

    function migrate_0() public {migrate_(msg.sender,  0, 49, 0);}
    function migrate_1() public {migrate_(msg.sender, 50, 99, 1);}

    function migrate_(address addr, uint256 fromNodeIndex, uint256 toNodeIndex, uint256 migrationNumber) internal {
        require(NodeManagerV1._isNodeOwner(addr)            ,"NodeManagerV2: NOT A NODE OWNER");
        if(migrationNumber!=999){
            require(migrated[addr][migrationNumber]==false  ,"NodeManagerV2: ALREADY MIGRATED");
        }
//        require(NodeManagerV1._getRewardAmountOf(addr)==0   ,"NodeManagerV2: CLAIM REWARDS BEFORE MIGRATING");
        uint256 holdersMaxNodeIndex = NodeManagerV1._getNodeNumberOf(addr)-1;
        require(holdersMaxNodeIndex >= fromNodeIndex        ,"NodeManagerV2: NOT ENOUGH NODES TO MIGRATE THIS TEIR");

        if(migrationNumber==1){
            require (migrated[addr][0]                      , "NodeManagerV2: MUST DO THE FIRST MIGRATION FIRST");
        }

        if(holdersMaxNodeIndex<toNodeIndex){toNodeIndex = holdersMaxNodeIndex;}
        migrated[addr][migrationNumber]=true;

        string[] memory nodesNames = splitWithDelimiter(NodeManagerV1._getNodesNames(addr));        
        string[] memory nodesCreationTime = splitWithDelimiter(NodeManagerV1._getNodesCreationTime(addr));

        uint256 lastClaimTime_ = migrationTimeStamp==0 ? block.timestamp : migrationTimeStamp;

        for(uint256 i=fromNodeIndex;i<toNodeIndex+1;i++){
            _nodesOfUser[addr].push(
                NodeEntity({
                    name: nodesNames[i],
                    creationTime: st2num(nodesCreationTime[i]),
                    lastClaimTime: lastClaimTime_,
                    rewardAvailable: 0
                })
            );
        }
        nodeOwners.set(addr, _nodesOfUser[addr].length);
    }

    function setToken(address token_) external onlySentry {
        Zeus = IZeus(token_);
        token = token_;
    }

    function _createNode(address account, string memory nodeName) internal {
        _nodesOfUser[account].push(
            NodeEntity({
                name: nodeName,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                rewardAvailable: 0
            })
        );
        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
    }

    function createNode(address account, string memory nodeName)
        external
        onlySentry
    {
        _createNode(account, nodeName);
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
    ) private view returns (NodeEntity storage, uint256) {
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
        return (nodes[validIndex], validIndex);
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

    function _calculateReward(NodeEntity memory node)
        private
        view
        returns (uint256)
    {
        uint256 lastClaim = node.lastClaimTime;
        uint256 claims = 0;

        if (lastClaim == 0) {
            claims = claims.add(1);
            lastClaim = node.creationTime;
        }

        uint256 currentTime = block.timestamp;
        uint256 _claims = (currentTime.sub(lastClaim)).div(claimTime);
        claims = claims.add(_claims);

        return rewardPerNode.mul(claims);
    }

    function _cashoutNodeReward(address account, uint256 _creationTime)
        external
        onlySentry
        returns (uint256)
    {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;

        if (numberOfNodes == 0) {
            return 0;
        }

        (NodeEntity storage node, uint256 index) = _getNodeWithCreatime(
            nodes,
            _creationTime
        );
        uint256 rewardNode = _calculateReward(node) + node.rewardAvailable;
        nodes[index].lastClaimTime = block.timestamp;
        nodes[index].rewardAvailable = 0;

        return rewardNode;
    }

    function _cashoutAllNodesReward(address account)
        external
        onlySentry
        returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            rewardsTotal += _calculateReward(nodes[i]).add(
                nodes[i].rewardAvailable
            );
            nodes[i].lastClaimTime = block.timestamp;
            nodes[i].rewardAvailable = 0;
        }
        return rewardsTotal;
    }

    function claimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimTime <= block.timestamp;
    }

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256)
    {
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            rewardCount += _calculateReward(nodes[i]).add(
                nodes[i].rewardAvailable
            );
        }
        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 _creationTime)
        public
        view
        returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        (NodeEntity storage node, ) = _getNodeWithCreatime(
            nodes,
            _creationTime
        );
        uint256 rewardNode = _calculateReward(node).add(node.rewardAvailable);
        return rewardNode;
    }

    function _getNodeRewardAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256)
    {
        (NodeEntity memory _node, ) = _getNodeWithCreatime(
            _nodesOfUser[account],
            creationTime
        );

        return _node.rewardAvailable.add(_calculateReward(_node));
    }

    function _getNodesNames(address account)
        external
        view
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

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory)
    {
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
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(_getRewardAmountOf(account,nodes[0].creationTime));
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(_getRewardAmountOf(account,_node.creationTime))
                )
            );
        }
        return _rewardsAvailable;
    }

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory)
    {
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

    function _changeNodePrice(uint256 newNodePrice) external onlySentry {
        nodePrice = newNodePrice;
    }

    function _changeRewardPerNode(uint256 newPrice) external onlySentry {
        rewardPerNode = newPrice;
    }

    function _changeClaimTime(uint256 newTime) external onlySentry {
        claimTime = newTime;
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return nodeOwners.get(account);
    }

    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }

}