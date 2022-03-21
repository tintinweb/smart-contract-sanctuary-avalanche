/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-20
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
/**
 *Submitted for verification at snowtrace.io on 2022-02-19
*/

// File: IterableMapping.sol


pragma solidity ^0.8.0;


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


// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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


// File: NodeManager.sol

pragma solidity ^0.8.0;



contract NodeManager is Ownable, Pausable {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    //`amount` is the value that was added into the node on creation. should be equal to nodePrice 
    struct NodeEntity {
        uint creationTime;
        uint lastClaimTime;
        uint256 nodeValue;
        uint256 rewardsAvailable;
        address createdBy;
    }

    IterableMapping.Map private nodeOwners;
    IterableMapping.Map private nodeGivers;

    mapping(address => NodeEntity []) private _nodesOfUser;

    address public token;
    uint8 public rewardPerNode;
    uint256 public nodePrice;

    uint256 public totalNodesCreated = 0;
    uint256 public totalStaked = 0;
    uint256 public totalClaimed = 0;

    uint16[] private _boostMultipliers = [1200, 150, 130];
    uint16[] private _boostRequiredDays = [6, 90, 365];

    event NodeCreated(
        uint256 indexed amount,
        address indexed account,
        uint indexed blockTime
    );
    event NodeCreatedPlus(
        uint256 indexed amount,
        uint256 newNodeValue,
        address indexed account,
        uint indexed blockTime
    );

    modifier onlyGuard() {
        // console.log("onlyGuard() - owner: %s, sender %s", owner(), _msgSender());
        require(owner() == _msgSender() || token == _msgSender(), "NOT_GUARD");
        _;
    }

    modifier onlyNodeOwner(address account) {
        require(isNodeOwner(account), "NOT_OWNER");
        _;
    }

    constructor(
        uint8 _rewardPerNode,
        uint256 _nodePrice
    ) {
        rewardPerNode = _rewardPerNode;
        nodePrice = _nodePrice;
    }




    // function _getNodeWithCreationTime(
    //     NodeEntity storage nodes,
    //     uint256 _creationTime
    // ) private view returns (NodeEntity storage) {
    //     uint256 numberOfNodes = nodes.length;
    //     require(
    //         isNodeOwner(account); > 0,
    //         "CASHOUT ERROR: You don't have nodes to cash-out"
    //     );
    //     bool found = false;
    //     console.log("Num nodes: %s, creationTime %s", numberOfNodes, _creationTime);
    //     int256 index = _binarySearch(nodes, 0, numberOfNodes, _creationTime);
    //     uint256 validIndex;
    //     if (index >= 0) {
    //         found = true;
    //         validIndex = uint256(index);
    //     }
    //     console.log("Node found? %s", found);
    //     require(found, "NODE SEARCH: No NODE Found with this blocktime");
    //     return nodes[validIndex];
    // }

    // function _binarySearch(
    //     NodeEntity[] memory arr,
    //     uint256 low,
    //     uint256 high,
    //     uint256 x
    // ) private view returns (int256) {
    //     if (high >= low) {
    //         uint256 mid = (high + low).div(2);
    //         if (arr[mid].creationTime == x) {
    //             return int256(mid);
    //         } else if (arr[mid].creationTime > x) {
    //             return _binarySearch(arr, low, mid - 1, x);
    //         } else {
    //             return _binarySearch(arr, mid + 1, high, x);
    //         }
    //     } else {
    //         return -1;
    //     }
    // }

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
        // console.log("Rewards %s", ((rewardPerDay.mul(10000).div(1440) * (elapsedTime_ / 1 minutes)) / 10000) * boostMultiplier);
        //Return rewards/min * elapsedTime in min
        return ((rewardPerDay.mul(10000).div(1440) * (elapsedTime_ / 1 minutes)) / 10000) * boostMultiplier;
    }

    function _calculateBoost(uint elapsedTime_) internal view returns (uint256) {
        uint256 elapsedTimeInDays_ = elapsedTime_ / 1 days;

        if (elapsedTimeInDays_ <= _boostRequiredDays[0]) {
            return _boostMultipliers[0];
        } else if (elapsedTimeInDays_ <= _boostRequiredDays[1]) {
            return _boostMultipliers[1];
        } else if (elapsedTimeInDays_ <= _boostRequiredDays[2]) {
            return _boostMultipliers[2];
        } else {
            return 100;
        }
    }

    // External methods

    //Requires that the first node created it for another address.
    //Only then can the caller create a node for themself.
    function createNode(address account, address receiver, uint256 nodeValue_, bool withRewards) 
    external whenNotPaused {
        if (account == receiver) {
            require(isNodeOwner(account), "Cannot create nodes for self");
        }
        
        //If it is the first node, then create a new node object. Otherwise add to the 
        //existing node's value
        if (!isNodeOwner(account)){
            // console.log("createNode() - Creating node for non-owner");
            _nodesOfUser[receiver].push(
                NodeEntity({
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp,
                    rewardsAvailable: 0,
                    nodeValue: nodeValue_,
                    createdBy: account
                })
            );
            uint256 nodeGiverCount = nodeGivers.get(account);
            nodeOwners.set(receiver, 1);
            nodeGivers.set(account, nodeGiverCount + 1);

            emit NodeCreated(nodeValue_, receiver, block.timestamp);

        } else {
            // console.log("createNode() - Updating node for existing owner");

            require(
            nodeValue_ % nodePrice == 0,
            "Invalid node value. Must be in increments of nodePrice (20)"
            );
            NodeEntity storage node = _nodesOfUser[receiver][0];

            //calc rewards before changing total nodeValue
            uint256 rewardsCalculated = _calculateNodeRewards(node.lastClaimTime, node.nodeValue);
            // console.log("createNode() - Pending rewards are %s", rewardsCalculated);
            // console.log("createNode() - Previous claim time %s", node.lastClaimTime);

            node.lastClaimTime = block.timestamp;
            // console.log("createNode() - Updated claim time %s", node.lastClaimTime);

            //Assign rewards to rewardsAvailable
            // console.log("createNode() - Previous rewardsAvailable  %s", node.rewardsAvailable);

            node.rewardsAvailable += rewardsCalculated;
            // console.log("createNode() - Updated rewardsAvailable  %s", node.rewardsAvailable);


            //"Create" a new node by add the equivalent value to the nodeValue
            //If we "created" 4 nodes, then the total nodeValue would be 40 (if nodePrice == 10)
            // console.log("createNode() - Previous nodeValue  %s", node.nodeValue);

            node.nodeValue += nodeValue_;
            // console.log("createNode() - Updated nodeValue  %s", node.nodeValue);

            if(withRewards){
                node.rewardsAvailable -= nodePrice;
                // console.log("createNode() - Updated rewardsAvailable (after creation) %s", node.rewardsAvailable);

            }

            emit NodeCreatedPlus(nodeValue_, node.nodeValue, receiver, block.timestamp);

        }
        totalNodesCreated++;
        totalStaked += nodeValue_;
    }



    function getAllNodesRewards(address account)
        external
        view
        onlyNodeOwner(account)
        returns (uint256)
    {
        NodeEntity storage node = _nodesOfUser[account][0];
        // uint256 nodesCount = nodes.length;
        // console.log("getAllNodesRewards() - Node count %s", nodesCount);
        // require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        // uint256 rewardsTotal = 0;
        // // uint256 pending = _calculateNodeRewards(nodes[0].lastClaimTime, nodes[0].nodeValue);
        // // console.log("getAllNodesRewards() - pending rewards %s", pending);
        // uint256 rewardsTotal = nodes[0].rewardsAvailable;
        return node.rewardsAvailable;
    }

    function cashoutNodeReward(address account)
        external
        onlyNodeOwner(account)
        whenNotPaused
    {
        // console.log("cashoutNodeReward() - _msgSender: %s, account: %s, txOrigin", _msgSender(), account, tx.origin);

        //only this flimsy check is what allows this function to work.
        // for some reason when it is called from the Heart contract, it has a different sender.
        // We are just checking if the person sending the request is the same as the account they 
        // are trying to cashout
        if(account == tx.origin){
            // console.log("cashoutNodeReward() - Contract paused? %s", paused());
            require(
                isNodeOwner(account), "CASHOUT ERROR: You don't have nodes to cash-out"
            );
            NodeEntity storage node = _nodesOfUser[account][0];
            node.rewardsAvailable = 0;
            node.lastClaimTime = block.timestamp;
        }
        
    }

    function getFirstNodeValue(address account)
        external
        view
        onlyNodeOwner(account)
        returns (uint256 nodeValue)
    {
        NodeEntity memory node = _nodesOfUser[account][0];
        return node.nodeValue;
    }

    function getNodesLastClaimTime(address account)
        public
        view
        onlyNodeOwner(account)
        returns (string memory)
    {
        NodeEntity memory node = _nodesOfUser[account][0];
        string memory _lastClaimTimes = _uint2str(node.lastClaimTime);
        string memory separator = "#";

        _lastClaimTimes = string(
            abi.encodePacked(
                _lastClaimTimes,
                separator,
                _uint2str(node.lastClaimTime)
            )
        );
        
        return _lastClaimTimes;
    }

    function updateToken(address newToken) external onlyOwner {
        token = newToken;
    }

    function updateReward(uint8 newVal) external onlyOwner {
        rewardPerNode = newVal;
    }

    function updateNodePrice(uint256 newNodePrice) external onlyOwner {
        nodePrice = newNodePrice;
    }

    function updateBoostMultipliers(uint8[] calldata newVal) external onlyOwner {
        require(newVal.length == 3, "Wrong length");
        _boostMultipliers = newVal;
    }

    function updateBoostRequiredDays(uint16[] calldata newVal) external onlyOwner {
        require(newVal.length == 3, "Wrong length");
        _boostRequiredDays = newVal;
    }

    function getNodePrice() public view returns (uint256) {
        return nodePrice;
    }

    function getNodeNumberOf(address account) external view returns (uint256) {
        if (isNodeOwner(account)){
            NodeEntity memory node = _nodesOfUser[account][0];
            uint256 numOfNodes = node.nodeValue / nodePrice;
            return numOfNodes;
        } else {
            return 0;
        }
    }

    function getNumberOfNodesDonated(address account) external view returns (uint256) {
        return nodeGivers.get(account);
    }

    function isNodeOwner(address account) public view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function getAllNodes(address account) external view returns (NodeEntity memory) {
        return _nodesOfUser[account][0];
    }

    function getAllNodesCount(address account) external view onlyNodeOwner(account) returns (uint256)  {
        NodeEntity memory node = _nodesOfUser[account][0];
        uint256 count = node.nodeValue/nodePrice;
        return count;
    }


    function getIndexOfKey(address account) external view onlyOwner returns (int256) {
        require(account != address(0));
        return nodeOwners.getIndexOfKey(account);
    }

    // function _getNodeNumberOf(address account) public view returns (uint256) {
    //     return nodeOwners.get(account);
    // }

    function burn(uint256 index) external onlyOwner {
        require(index < nodeOwners.size());
        nodeOwners.remove(nodeOwners.getKeyAtIndex(index));
    }

   




// One node instead of many nodes
// The concept stays the same for the users on the FE. In the BE the node value just continues increasing.
// Value increments are done is chunks of 10 (same as buying a new node for `nodePrice`)
// Node reward calculation is done based on (time elapsed * rewardPer<TIME>). 
// rewardPer<TIME> will be based on "1 node" therefore 10 tokens/nodeValue.
// so (time elapsed * rewardPer<TIME>) * nodeValue/10 would be the calculation for the rewards for the given node

// Before new value is added to the node we call a new function `updateNodeRewardCalc` which will calculate the current node rewards
// and store them in the rewardsAvailable var. Then it will update the lastCalculationTime on the node and change the nodeValue to the new nodeValue_

// When claiming/creatingNodeWithReward, the `updateNodeRewardCalc` func will be called to store the pending rewards in rewardsAvailable.
// The rewards claimed/used will be deducted from the rewardsAvailable total.

// When fetchings rewards available, we will also call updateNodeRewardCalc to calculate how many rewards are available and then store them
// in the rewardsAvailable var.





    //Not used

    

    

     // function updateNodeRewardCal(address account) external onlyOwner {
    //     this.getNodeReward();
    // }

    //function getNodesNames(address account)
    //     public
    //     view
    //     onlyNodeOwner(account)
    //     returns (string memory)
    // {
    //     NodeEntity[] memory nodes = _nodesOfUser[account];
    //     uint256 nodesCount = nodes.length;
    //     NodeEntity memory _node;
    //     string memory names = nodes[0].name;
    //     string memory separator = "#";
    //     for (uint256 i = 1; i < nodesCount; i++) {
    //         _node = nodes[i];
    //         names = string(abi.encodePacked(names, separator, _node.name));
    //     }
    //     return names;
    // }

    //function getNodesCreationTime(address account)
    // external
    // view
    // returns (string memory)
    // {
    //     require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
    //     NodeEntity[] memory nodes = _nodesOfUser[account];
    //     uint256 nodesCount = nodes.length;
    //     NodeEntity memory _node;
    //     string memory _creationTimes = _uint2str(nodes[0].creationTime);
    //     string memory separator = "#";

    //     for (uint256 i = 1; i < nodesCount; i++) {
    //         _node = nodes[i];

    //         _creationTimes = string(
    //             abi.encodePacked(
    //                 _creationTimes,
    //                 separator,
    //                 _uint2str(_node.creationTime)
    //             )
    //         );
    //     }
    //     return _creationTimes;
    // }

        // function getNodesCreationTime(address account)
    //     public
    //     view
    //     onlyNodeOwner(account)
    //     returns (string memory)
    // {
    //     NodeEntity[] memory nodes = _nodesOfUser[account];
    //     uint256 nodesCount = nodes.length;
    //     NodeEntity memory _node;
    //     string memory _creationTimes = _uint2str(nodes[0].creationTime);
    //     string memory separator = "#";

    //     for (uint256 i = 1; i < nodesCount; i++) {
    //         _node = nodes[i];

    //         _creationTimes = string(
    //             abi.encodePacked(
    //                 _creationTimes,
    //                 separator,
    //                 _uint2str(_node.creationTime)
    //             )
    //         );
    //     }
    //     return _creationTimes;
    // }


    // function _updateNodeRewardCalc(address account, uint256 _creationTime)
    //     external
    //     view
    // {
    //     require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    //     NodeEntity[] storage nodes = _nodesOfUser[account];
    //     require(
    //         nodes.length > 0,
    //         "NODE REWARD ERROR: Can't get rewards on 0 nodes"
    //     );
    //     NodeEntity storage node = _getNodeWithCreationTime(nodes, _creationTime);
    //     console.log("Getting rewards for the following node %s", node.creationTime);

    //     uint256 rewardsCalculated = _calculateNodeRewards(node.lastClaimTime, node.nodeValue);
    //     node.lastClaimTime = block.timestamp;
    //     node.rewardsAvailable += rewardsCalculated;
    // }

    //function shaveNodes(address account, uint256 numNodes) public onlyNodeOwner(account) returns (uint256)
    // {
        // NodeEntity[] storage _nodes = _nodesOfUser[_msgSender().address];
        // NodeEntity storage node = _getNodeWithCreationTime(_nodes, _creationTime);
        // uint256 amountToShave = numNodes * nodePrice;
        // require (node.pendingRewards >= amountToShave, "Not enough rewards to shave");
        // node.pendingRewards -= numNodes * nodePrice;
// ------------
        // NodeEntity[] storage nodes = _nodesOfUser[account];
        // uint256 nodesCount = nodes.length;

        // uint256 rewardPerDay = nodePrice.mul(rewardPerNode).div(100);
        // console.log("Rewards per day %s", rewardPerDay);
        // uint256 rewardsPerMin = ((rewardPerDay.mul(10*18).div(1440)));
        // console.log("Rewards per min %s", rewardsPerMin);


        // uint256 minutesToReachNodePrice = nodePrice / rewardsPerMin;
        // uint256 minutesToShaveOffEachNode = minutesToReachNodePrice / nodesCount;


        //  //set the timestamp of each node to reflect the nodePrice amount of tokens has been claimed
        // require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        // NodeEntity storage _node;
        // for (uint256 i = 0; i < nodesCount; i++) {
        //     _node = nodes[i];
        //     uint256 _shaveTimestamp = _node.lastClaimTime + minutesToShaveOffEachNode;
        //     _node.lastClaimTime = _shaveTimestamp;
        // }

        // return this.getAllNodesRewards(account);


             // 
        
        
    // function compoundNodeReward(address account, uint256 _creationTime, uint256 nodeValue_)
    //     external
    //     onlyGuard
    //     onlyNodeOwner(account)
    //     whenNotPaused
    // {
    //     require(_creationTime > 0, "NODE: CREATETIME must be higher than zero");
    //     NodeEntity[] storage nodes = _nodesOfUser[account];
    //     require(
    //         nodes.length > 0,
    //         "CASHOUT ERROR: You don't have nodes to cash-out"
    //     );
    //     require(
    //         nodeValue_ % nodePrice == 0,
    //         "Invalid node value. Must be in increments of nodePrice (10)"
    //     );
    //     NodeEntity storage node = _getNodeWithCreationTime(nodes, _creationTime);

    //     node.nodeValue += nodeValue_;
    //     node.lastClaimTime = block.timestamp;
        

    //     emit NodeCreatedPlus(nodeValue_, node.nodeValue, _msgSender(), block.timestamp);
    //     totalNodesCreated++;
    //     totalStaked += nodeValue_;

    
    // }

    // }
}