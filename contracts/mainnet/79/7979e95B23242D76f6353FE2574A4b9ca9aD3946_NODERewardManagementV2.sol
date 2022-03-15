// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/IVesting.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NODERewardManagementV2 is Ownable {
    using Strings for uint256;

    address[] public Admins;
    mapping(address => bool) public AdminByAddr;
    IVesting vesting;

    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardAvailable;
    }

    mapping(address => uint256[]) public NodeIDsByUser;
    mapping(uint256 => NodeEntity) public NodesByID;
    mapping(string => bool) public NodeNames;

    uint256 public nodePrice;
    uint256 public rewardPerNode;
    address public token;
    uint256 public totalNodesCreated;
    uint256 public totalRewardStaked;
    uint256 public claimTime;
    uint256 public rewardsPerMinute;
    bool public cashoutEnabled;
    bool public autoDistri = true;          // for parity with existing token contract calls
    uint256 public gasForDistribution;      // for parity with existing token contract calls
    uint256 public lastDistributionCount;   // for parity with existing token contract calls

    constructor(uint256 _nodePrice, uint256 _rewardPerNode, uint256 _claimTime) {
        nodePrice = _nodePrice;
        rewardsPerMinute =  _rewardPerNode / (24 * 60);
        rewardPerNode = _rewardPerNode;
        claimTime = _claimTime;
        Admins.push(msg.sender);
        AdminByAddr[msg.sender] = true;
    }

    /**************/
    /*   VIEWS    */
    /**************/

    function isNodeClaimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimTime <= block.timestamp;
    }

    function _getRewardAmountOfNode(address account, uint256 nodeIndex) external view nodeOwner(account) returns(uint256) {
        require(NodeIDsByUser[account].length > nodeIndex, "INVALID_INDEX");
        return _availableClaimableAmount(NodesByID[NodeIDsByUser[account][nodeIndex]].lastClaimTime) + 
                NodesByID[NodeIDsByUser[account][nodeIndex]].rewardAvailable;
    }

    function _getRewardAvailable(address account, uint256 nodeIndex) external view nodeOwner(account) returns(uint256) {
        require(NodeIDsByUser[account].length > nodeIndex, "INVALID_INDEX");
        return NodesByID[NodeIDsByUser[account][nodeIndex]].rewardAvailable;
    }

    function _getAvailableClaimAmount(address account, uint256 nodeIndex) external view nodeOwner(account) returns(uint256) {
        require(NodeIDsByUser[account].length > nodeIndex, "INVALID_INDEX");
        return _availableClaimableAmount(NodesByID[NodeIDsByUser[account][nodeIndex]].lastClaimTime);
    }

    function _getRewardAmountOf(address account) external view nodeOwner(account) returns(uint256) {
        uint256 rewardCount;
        for (uint256 x; x < NodeIDsByUser[account].length; x++) {
            rewardCount += _availableClaimableAmount(NodesByID[NodeIDsByUser[account][x]].lastClaimTime) + 
                NodesByID[NodeIDsByUser[account][x]].rewardAvailable;
        }
        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 _creationTime) external view nodeOwner(account) returns(uint256) {
        require(_creationTime > 0, "CREATIONTIME_IS_ZERO");
        require(NodeIDsByUser[account].length > 0, "NO_NODES_FOR_CASHOUT");
        NodeEntity memory node = _getNodeWithCreationTime(account, _creationTime);
        return _availableClaimableAmount(node.lastClaimTime) + node.rewardAvailable;
    }

    function _getNodesRewardAvailable(address account) external view nodeOwner(account) returns(string memory) {
        NodeEntity memory node = NodesByID[NodeIDsByUser[account][0]];
        string memory _rewardsAvailable = uint2str(_availableClaimableAmount(node.lastClaimTime) + node.rewardAvailable);
        for(uint256 x = 1; x < NodeIDsByUser[account].length; x++) {
            node = NodesByID[NodeIDsByUser[account][x]];
            _rewardsAvailable = string(abi.encodePacked(_rewardsAvailable, "#", 
                uint2str(_availableClaimableAmount(node.lastClaimTime) + node.rewardAvailable)));
        }
        return _rewardsAvailable;
    }

    function _getNodesPendingClaimableAmount(address account) external view nodeOwner(account) returns(string memory) {
        string memory pendingClaimableAmount = uint2str(_pendingClaimableAmount(NodesByID[NodeIDsByUser[account][0]].lastClaimTime));
        for (uint256 x = 1; x < NodeIDsByUser[account].length; x++) {
            pendingClaimableAmount = string(abi.encodePacked(pendingClaimableAmount,"#", 
                uint2str(_pendingClaimableAmount(NodesByID[NodeIDsByUser[account][x]].lastClaimTime))));
        }
        return pendingClaimableAmount;
    }

    function _getNodeRewardAmountOf(address account, uint256 creationTime) external view returns (uint256) {
        return _getNodeWithCreationTime(account, creationTime).rewardAvailable;
    }

    function _getNodesNames(address account) external view nodeOwner(account) returns(string memory) {
        string memory names = NodesByID[NodeIDsByUser[account][0]].name;
        for(uint256 x = 1; x < NodeIDsByUser[account].length; x++) {
            names = string(abi.encodePacked(names, "#", NodesByID[NodeIDsByUser[account][x]].name));
        }
        return names;
    }

    function _getNodesCreationTime(address account) external view nodeOwner(account) returns(string memory) {
        string memory creationTimes = uint2str(NodesByID[NodeIDsByUser[account][0]].creationTime);
        for(uint256 x = 1; x < NodeIDsByUser[account].length; x++) {
            creationTimes = string(abi.encodePacked(creationTimes, "#", 
                uint2str(NodesByID[NodeIDsByUser[account][x]].creationTime)));
        }
        return creationTimes;
    }

    function _getNodesLastClaimTime(address account) external view nodeOwner(account) returns(string memory) {
        string memory _lastClaimTimes = uint2str(NodesByID[NodeIDsByUser[account][0]].lastClaimTime);
        for(uint256 x = 1; x < NodeIDsByUser[account].length; x++) {
            _lastClaimTimes = string(abi.encodePacked(_lastClaimTimes, "#", 
                uint2str(NodesByID[NodeIDsByUser[account][x]].lastClaimTime)));
        }        
        return _lastClaimTimes;
    }

    function _getNodeNumberOf(address account) external view returns(uint256) {
        return NodeIDsByUser[account].length;
    }

    function _isNodeOwner(address account) external view returns(bool) {
        return NodeIDsByUser[account].length > 0;
    }

    function _distributeRewards() external view onlyAdmin returns(uint256, uint256, uint256) {
        return (0,0,0);
    }

    /**************/
    /*   MUTATIVE    */
    /**************/

    function createNode(address account, string memory nodeName) external onlyAdmin {
        NodesByID[totalNodesCreated] = NodeEntity({
                name: _getAvailableName(nodeName),
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                rewardAvailable: 0
            });
        NodeIDsByUser[account].push(totalNodesCreated);
        totalNodesCreated++;
    }

    function createNodes(address[] calldata accounts, string[] calldata nodeNames) external onlyAdmin {
        require(accounts.length == nodeNames.length, "INCONSISTENT_LENGTH");
        for(uint256 x; x < accounts.length; x++) {
            NodesByID[totalNodesCreated] = NodeEntity({
                    name: _getAvailableName(nodeNames[x]),
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp,
                    rewardAvailable: 0
                });
            NodeIDsByUser[accounts[x]].push(totalNodesCreated);            
            totalNodesCreated++;
        }
    }    

    function createNodesForAccount(address account, string[] calldata nodeNames) external onlyAdmin {
        for(uint256 x; x < nodeNames.length; x++) {
            NodesByID[totalNodesCreated] = NodeEntity({
                    name: _getAvailableName(nodeNames[x]),
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp,
                    rewardAvailable: 0
                });
            NodeIDsByUser[account].push(totalNodesCreated);   
            totalNodesCreated++;
        }
    }    

    function _cashoutNodeReward(address account, uint256 _creationTime) external onlyAdmin nodeOwner(account) returns(uint256) {
        require(cashoutEnabled, "CASHOUT_DISABLED");
        require(_creationTime > 0, "CREATIONTIME_IS_ZERO");
        NodeEntity storage node = _getNodeWithCreationTime(account, _creationTime);
        require(isNodeClaimable(node), "TOO_EARLY_TO_CLAIM");
        uint256 rewardNode = _availableClaimableAmount(node.lastClaimTime) + node.rewardAvailable;
        node.rewardAvailable = 0;
        node.lastClaimTime = block.timestamp;
        if (vesting.isBeneficiary(account) && vesting.accruedBalanceOf(account) > 0) {
            vesting.claim(account);
        }
        return rewardNode; 
    }    

    function _cashoutAllNodesReward(address account) external onlyAdmin nodeOwner(account) returns(uint256) {
        uint256 rewardsTotal;
        for (uint256 x; x < NodeIDsByUser[account].length; x++) {
            NodeEntity storage _node = NodesByID[NodeIDsByUser[account][x]];
            rewardsTotal += _availableClaimableAmount(_node.lastClaimTime) + _node.rewardAvailable;
            _node.rewardAvailable = 0;
            _node.lastClaimTime = block.timestamp;
        }
        if (vesting.isBeneficiary(account) && vesting.accruedBalanceOf(account) > 0) {
            vesting.claim(account);
        }        
        return rewardsTotal;
    }

    function _transferNode(address from, address to, string memory nodeName) external returns (bool) {
        uint256 index = uint(int(-1));
        for(uint256 x = 1; x < NodeIDsByUser[from].length; x++) {
            if (keccak256(bytes(NodesByID[NodeIDsByUser[from][x]].name)) == keccak256(bytes(nodeName))) {
                index = x;
                break;
            }            
        }        
        require(index != uint(int(-1)), "NODE_!EXISTS");
        // push ID into receiver
        NodeIDsByUser[to].push(NodeIDsByUser[from][index]);
        // swap ID with last item for sender
        NodeIDsByUser[from][index] = NodeIDsByUser[from][NodeIDsByUser[from].length - 1];
        // remove last ID from sender
        NodeIDsByUser[from].pop();
        return true;        
    }     

    function setToken (address token_) external onlyAdmin {
        token = token_;
    }

    function setVesting(address vesting_) external onlyAdmin {
        vesting = IVesting(vesting_);
    }

    function _changeRewardsPerMinute(uint256 newPrice) external onlyAdmin {
        rewardsPerMinute = newPrice;
    }     

    function toggleCashoutEnabled() external onlyAdmin {
        cashoutEnabled = !cashoutEnabled;
    }

    function _changeNodePrice(uint256 newNodePrice) external onlyAdmin {
        nodePrice = newNodePrice;
    }

    function _changeClaimTime(uint256 newTime) external onlyAdmin {
        claimTime = newTime;
    }    

    function _changeRewardPerNode(uint256 newPrice) external onlyAdmin {
        rewardsPerMinute = newPrice / (24 * 60);
    }  

    function _changeAutoDistri(bool newMode) external onlyAdmin {}      

    function _changeGasDistri(uint256 newGasDistri) external onlyAdmin {}    

    /**************/
    /*  PRIVATE   */
    /**************/

    function _pendingClaimableAmount(uint256 nodeLastClaimTime) private view returns (uint256 availableRewards) {
        uint256 timePassed = block.timestamp - nodeLastClaimTime;
        return timePassed / claimTime < 1 
            ? timePassed * rewardsPerMinute / claimTime 
            : 0;
    }

    function _availableClaimableAmount(uint256 nodeLastClaimTime) private view returns (uint256 availableRewards) {
        return ((block.timestamp - nodeLastClaimTime) / claimTime) * rewardsPerMinute;
    }      

    function _getAvailableName(string memory nodeName) private returns(string memory) {
        string memory newNodeName = nodeName;
        uint256 x;
        while(NodeNames[newNodeName]) {
            newNodeName = string(abi.encodePacked(nodeName, x.toString()));
            x++;
        }
        NodeNames[newNodeName] = true;             
        return newNodeName;
    }

    function _getNodeWithCreationTime(address account, uint256 creationTime) private view returns (NodeEntity storage) {
        uint256 nodeId;
        bool found;
        for(uint256 x; x < NodeIDsByUser[account].length; x++) {
            if (NodesByID[NodeIDsByUser[account][x]].creationTime == creationTime) {
                nodeId = NodeIDsByUser[account][x];
                found = true;
                break;
            }
        }
        require(found, "NO_NODE_WITH_BLOCKTIME");
        return NodesByID[nodeId];
    }

    function _getNodeWithCreatime(NodeEntity[] storage nodes, uint256 _creationTime) private view returns (NodeEntity storage) {
        require(nodes.length > 0, "NO_NODES_FOR_CASHOUT");
        bool found;
        int256 index = _binarysearch(nodes, 0, nodes.length, _creationTime);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NO_NODE_WITH_BLOCKTIME");
        return nodes[validIndex];
    }

    function _binarysearch(NodeEntity[] memory arr, uint256 low, uint256 high, uint256 x) private view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low) / (2);
            if (arr[mid].creationTime == x) {
                return int256(mid);
            } else if (arr[mid].creationTime > x) {
                return _binarysearch(arr, low, mid - 1, x);
            } else {
                return _binarysearch(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) return "0";
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

    function setAdmins(address[] memory _Admins) external onlyAdmin {
        _setAdmins(_Admins);
    }

    function _setAdmins(address[] memory _Admins) internal {
        for (uint256 i; i < Admins.length; i++) {
            AdminByAddr[Admins[i]] = false;
        }

        for (uint256 j; j < _Admins.length; j++) {
            AdminByAddr[_Admins[j]] = true;
        }
        Admins = _Admins;
        emit SetAdmins(_Admins);
    }

    function getAdmins() external view returns (address[] memory) {
        return Admins;
    }      

    modifier onlyAdmin() {
        require(msg.sender == token || AdminByAddr[msg.sender] == true || msg.sender == owner(), "Fuck off");
        _;
    }

    modifier nodeOwner(address account) {
        require(NodeIDsByUser[account].length > 0, "NOT_NODE_OWNER");
        _;
    }

    event SetAdmins(address[] Admins);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVesting {

    function claim(address _address) external;
    function accruedBalanceOf(address beneficiaryAddress) external view returns (uint256);
    function isBeneficiary(address beneficiaryAddress) external view returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}