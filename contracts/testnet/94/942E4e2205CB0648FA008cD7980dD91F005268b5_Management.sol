/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

interface IManagement {

    function createNode(address account, uint256 _rewardPerDay, uint256 _claimLimit) external;

    function cashoutReward(address account, uint256 _index) external returns(uint256);

    function cashoutRewardArray(address account, uint256[] memory indexArray) external returns(uint256);

    function cashoutAllReward(address account) external returns(uint256);

    function compoundNode(address account, uint256 amount) external;

    function calculateClaimableAllReward(address account) external view returns(uint256);

    function calculateAvailableAllReward(address account) external view returns(uint256);

    function calculateAvailableReward(address account, uint256 _index) external view returns(uint256);

    function getNodeLimit() external view returns(uint256);

    function getClaimInterval() external view returns(uint256);

    function getTotalCount() external view returns(uint256);

    function getNodesCountOfUser(address account) external view returns(uint256);

    function getNodeCreateTime(address account) external view returns (string memory);

    function getNodeLastClaimTime(address account) external view returns (string memory);

    function getNoderewardPerDay(address account) external view returns (string memory);

    function getNodeAvailableReward(address account) external view returns (string memory);

    function getNodeClaimableReward(address account) external view returns (string memory);

    function getNodeClaimLimit(address account) external view returns (string memory);

    function getNodeClaimCount(address account) external view returns (string memory);
}

contract Management is IManagement, Ownable {
    using SafeMath for uint256; // ok

    mapping(address => bool) public managers; // ok

    struct NodeInfo {
        uint256 createTime;
        uint256 lastClaimTime;
        uint256 rewardedAmount;
        uint256 rewardPerDay;
        uint256 claimLimit;
        uint256 claimCount;
    } // ok

    uint256 public launchTime;

    // Protocol Stats
    uint256 public totalCount = 0; // ok
    uint256 public accumulatedTotalCount = 0;
    mapping(address => NodeInfo[]) private nodesOfUser; // ok
    mapping(address => uint256) private nodeCountOfUser; // ok

    // Protocol Parameters
    uint256 public nodeLimit = 50; // ok
    uint256 public claimInterval = 1 minutes; // ok
    uint256 public claimHours = 12;

    // Events
    event CreatedNode(address _account, uint256 _rewardPerDay, uint256 _createTime); // ok

    // Modifiers
    modifier onlyManager() {
        require(managers[msg.sender] == true, "MANAGEMENT: NOT MANAGER");
        _;
    }

    constructor (
        address[] memory _managers
    ) {
        for (uint256 i = 0; i < _managers.length; i ++) {
            managers[_managers[i]] = true;
        }
    }

    function addManager(address _manager) external onlyOwner {
        managers[_manager] = true;
    }

    function removeManager(address _manager) external onlyOwner {
        managers[_manager] = false;
    }

    function start() external onlyOwner {
        launchTime = block.timestamp;
    }

    function setNodeLimit(uint256 _limit) external onlyOwner {
        nodeLimit = _limit;
    }

    function setClaimInterval(uint256 _hours) external onlyOwner {
        claimHours = _hours;
    }

    function createNode(address account, uint256 _rewardPerDay, uint256 _claimLimit) external onlyManager {
        require(nodeCountOfUser[account] < nodeLimit, "MANAGEMENT: CREATE NODE LIMIT ERROR");

        nodesOfUser[account].push(
            NodeInfo({
                createTime: block.timestamp,
                lastClaimTime: block.timestamp,
                rewardPerDay: _rewardPerDay,
                rewardedAmount: 0,
                claimLimit: _claimLimit,
                claimCount: 0
            })
        );

        nodeCountOfUser[account] += 1;

        if (nodesOfUser[account].length > nodeCountOfUser[account]) {
            nodesOfUser[account][nodeCountOfUser[account] - 1] = nodesOfUser[account][nodesOfUser[account].length - 1];
        }

        totalCount += 1;
        accumulatedTotalCount += 1;

        emit CreatedNode(account, _rewardPerDay, block.timestamp);
    }

    function cashoutReward(address account, uint256 _index) external onlyManager returns(uint256) {
        uint256 reward;

        reward = _cashoutReward(account, _index);

        return reward;
    }

    function cashoutRewardArray(address account, uint256[] memory indexArray) external onlyManager returns(uint256) {
        require(isNodeOwner(account), "MANAGEMENT: CASHOUT NO NODE OWNER");

        uint256 totalRewards = 0;

        for (uint256 i = 0; i < indexArray.length; i ++) {
            uint256 _index = indexArray[i];

            require(nodeCountOfUser[account] >= _index, "MANAGEMENT: CASHOUT INDEX ERROR");

            totalRewards += _cashoutReward(account, _index);
        }

        return totalRewards;
    }

    function cashoutAllReward(address account) external onlyManager returns(uint256) {
        require(isNodeOwner(account), "MANAGEMENT: CASHOUT ALL NO NODE OWNER");

        uint256 nodeLength = nodeCountOfUser[account];

        uint256 totalRewards = 0;
        uint256 i = nodeLength - 1;

        while(i >= 0) {
            totalRewards += _cashoutReward(account, i);

            if (i == 0) break;
            else i --;
        }

        return totalRewards;
    }

    function compoundNode(address account, uint256 amount) external onlyManager {
        require(isNodeOwner(account), "MANAGEMENT: COMPOUND NO NODE OWNER");

        NodeInfo[] storage nodes = nodesOfUser[account];
        NodeInfo storage node;

        uint256 nodeLength = nodeCountOfUser[account];

        uint256 reward;
        uint256 startTime;
        uint256 accumulatedAmount = 0;
        uint256 i = nodeLength - 1;

        while(i >= 0) {
            node = nodes[i];

            if (node.lastClaimTime + claimHours * 1 hours > block.timestamp) continue;

            if (node.createTime < launchTime) {
                startTime = launchTime;
            } else {
                startTime = node.createTime;
            }

            reward = (block.timestamp - startTime).div(claimInterval).mul(node.rewardPerDay).sub(node.rewardedAmount);

            if (accumulatedAmount + reward < amount) {
                node.lastClaimTime = block.timestamp;
                node.rewardedAmount = node.rewardedAmount + reward;

                accumulatedAmount += reward;

                node.claimCount += 1;
            } else {
                node.lastClaimTime = block.timestamp;
                node.rewardedAmount = node.rewardedAmount + amount - accumulatedAmount;

                accumulatedAmount += amount - accumulatedAmount;
            }

            if (node.claimCount >= node.claimLimit) {
                if (i != nodeCountOfUser[account] - 1) {
                    nodes[i] = nodes[nodeCountOfUser[account] - 1];
                }
                delete nodes[nodeCountOfUser[account] - 1];

                nodeCountOfUser[account] -= 1;
            }

            if (i == 0) break;
            else i --;
        }
    }

    function calculateClaimableAllReward(address account) external view onlyManager returns(uint256) {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < nodeCountOfUser[account]; i ++) {

            totalRewards += _calculateClaimableReward(account, i);
        }

        return totalRewards;
    }

    function calculateAvailableAllReward(address account) external view onlyManager returns(uint256) {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < nodeCountOfUser[account]; i ++) {

            totalRewards += _calculateAvailableReward(account, i);
        }

        return totalRewards;
    }

    function calculateAvailableReward(address account, uint256 _index) external view onlyManager returns(uint256) {
        uint256 reward;

        reward = _calculateAvailableReward(account, _index);

        return reward;
    }

    function getNodeLimit() external view onlyManager returns(uint256) {
        return nodeLimit;
    }

    function getClaimInterval() external view onlyManager returns(uint256) {
        return claimInterval;
    }

    function getTotalCount() external view onlyManager returns(uint256) {
        return totalCount;
    }

    function getNodesCountOfUser(address account) external view onlyManager returns(uint256) {
        return nodeCountOfUser[account];
    }

    function getNodeCreateTime(address account) external view onlyManager returns (string memory) {
        require(isNodeOwner(account), "MANAGEMENT: GET CREATE TIME ERROR");

        NodeInfo[] memory nodes = nodesOfUser[account];
        NodeInfo memory node;

        uint256 nodesCount = nodeCountOfUser[account];

        string memory separator = "#";

        string memory returnValue = uint2str(nodes[0].createTime);

        for (uint256 i = 1; i < nodesCount; i++) {
            node = nodes[i];

            returnValue = string(
                abi.encodePacked(
                    returnValue,
                    separator,
                    uint2str(node.createTime)
                )
            );
        }
        return returnValue;
    }

    function getNodeLastClaimTime(address account) external view onlyManager returns (string memory) {
        require(isNodeOwner(account), "MANAGEMENT: GET LAST CLAIM TIME ERROR");

        NodeInfo[] memory nodes = nodesOfUser[account];
        NodeInfo memory node;

        uint256 nodesCount = nodeCountOfUser[account];

        string memory separator = "#";

        string memory returnValue = uint2str(nodes[0].lastClaimTime);

        for (uint256 i = 1; i < nodesCount; i++) {
            node = nodes[i];

            returnValue = string(
                abi.encodePacked(
                    returnValue,
                    separator,
                    uint2str(node.lastClaimTime)
                )
            );
        }
        return returnValue;
    }

    function getNoderewardPerDay(address account) external view onlyManager returns (string memory) {
        require(isNodeOwner(account), "MANAGEMENT: GET REWARD PER DAY ERROR");

        NodeInfo[] memory nodes = nodesOfUser[account];
        NodeInfo memory node;

        uint256 nodesCount = nodeCountOfUser[account];

        string memory separator = "#";

        string memory returnValue = uint2str(nodes[0].rewardPerDay);

        for (uint256 i = 1; i < nodesCount; i++) {
            node = nodes[i];

            returnValue = string(
                abi.encodePacked(
                    returnValue,
                    separator,
                    uint2str(node.rewardPerDay)
                )
            );
        }
        return returnValue;
    }

    function getNodeAvailableReward(address account) external view onlyManager returns (string memory) {
        require(isNodeOwner(account), "MANAGEMENT: GET AVAILABLE REWARD ERROR");

        uint256 nodesCount = nodeCountOfUser[account];

        string memory separator = "#";

        string memory returnValue = uint2str(_calculateAvailableReward(account, 0));

        for (uint256 i = 1; i < nodesCount; i++) {
            returnValue = string(
                abi.encodePacked(
                    returnValue,
                    separator,
                    uint2str(_calculateAvailableReward(account, i))
                )
            );
        }
        return returnValue;
    }

    function getNodeClaimableReward(address account) external view onlyManager returns (string memory) {
        require(isNodeOwner(account), "MANAGEMENT: GET AVAILABLE REWARD ERROR");

        NodeInfo[] memory nodes = nodesOfUser[account];
        NodeInfo memory node;

        uint256 nodesCount = nodeCountOfUser[account];

        string memory separator = "#";
        string memory returnValue;

        node = nodes[0];
        if (node.lastClaimTime + claimHours * 1 hours > block.timestamp) {
            returnValue = uint2str(0);
        } else {
            returnValue = uint2str(_calculateAvailableReward(account, 0));
        }

        for (uint256 i = 1; i < nodesCount; i++) {
            node = nodes[i];
            if (node.lastClaimTime + claimHours * 1 hours > block.timestamp) {
                returnValue = string(
                    abi.encodePacked(
                        returnValue,
                        separator,
                        uint2str(0)
                    )
                );
            } else {
                returnValue = string(
                    abi.encodePacked(
                        returnValue,
                        separator,
                        uint2str(_calculateAvailableReward(account, i))
                    )
                );
            }
        }
        return returnValue;
    }

    function getNodeClaimLimit(address account) external view onlyManager returns (string memory) {
        require(isNodeOwner(account), "MANAGEMENT: GET CLAIM LIMIT ERROR");

        NodeInfo[] memory nodes = nodesOfUser[account];
        NodeInfo memory node;

        uint256 nodesCount = nodeCountOfUser[account];

        string memory separator = "#";

        string memory returnValue = uint2str(nodes[0].claimLimit);

        for (uint256 i = 1; i < nodesCount; i++) {
            node = nodes[i];

            returnValue = string(
                abi.encodePacked(
                    returnValue,
                    separator,
                    uint2str(node.claimLimit)
                )
            );
        }
        return returnValue;
    }

    function getNodeClaimCount(address account) external view onlyManager returns (string memory) {
        require(isNodeOwner(account), "MANAGEMENT: GET CLAIM LIMIT ERROR");

        NodeInfo[] memory nodes = nodesOfUser[account];
        NodeInfo memory node;

        uint256 nodesCount = nodeCountOfUser[account];

        string memory separator = "#";

        string memory returnValue = uint2str(nodes[0].claimCount);

        for (uint256 i = 1; i < nodesCount; i++) {
            node = nodes[i];

            returnValue = string(
                abi.encodePacked(
                    returnValue,
                    separator,
                    uint2str(node.claimCount)
                )
            );
        }
        return returnValue;
    }

    function _cashoutReward(address account, uint256 _index) internal returns(uint256) {
        NodeInfo[] storage nodes = nodesOfUser[account];
        NodeInfo storage node;

        require(isNodeOwner(account), "MANAGEMENT: CASHOUT NO NODE OWNER");
        require(nodeCountOfUser[account] >= _index, "MANAGEMENT: CASHOUT INDEX ERROR");

        uint256 reward;
        uint256 startTime;

        node = nodes[_index];

        if (node.lastClaimTime + claimHours * 1 hours > block.timestamp) return 0;

        if (node.createTime < launchTime) {
            startTime = launchTime;
        } else {
            startTime = node.createTime;
        }

        reward = (block.timestamp - startTime).div(claimInterval).mul(node.rewardPerDay).sub(node.rewardedAmount);

        node.lastClaimTime = block.timestamp;
        node.rewardedAmount = node.rewardedAmount + reward;

        node.claimCount += 1;

        if (node.claimCount >= node.claimLimit) {
            if (_index != nodeCountOfUser[account] - 1) {
                nodes[_index] = nodes[nodeCountOfUser[account] - 1];
            }
            delete nodes[nodeCountOfUser[account] - 1];

            nodeCountOfUser[account] -= 1;
            totalCount -= 1;
        }

        return reward;
    }

    function isNodeOwner(address account) internal view returns(bool) {
        if (nodeCountOfUser[account] > 0) {
            return true;
        } else {
            return false;
        }
    }

    function _calculateClaimableReward(address account, uint256 _index) internal view returns(uint256) {
        NodeInfo[] storage nodes = nodesOfUser[account];
        NodeInfo storage node;

        uint256 reward = 0;

        if (!isNodeOwner(account)) {
            return reward;
        }

        node = nodes[_index];

        if (node.lastClaimTime + claimHours * 1 hours > block.timestamp) return 0;

        require(nodeCountOfUser[account] >= _index, "MANAGEMENT: CALCULATE INDEX ERROR");

        reward = (block.timestamp - node.createTime).div(claimInterval).mul(node.rewardPerDay).sub(node.rewardedAmount);

        return reward;
    }

    function _calculateAvailableReward(address account, uint256 _index) internal view returns(uint256) {
        NodeInfo[] storage nodes = nodesOfUser[account];
        NodeInfo storage node;

        uint256 reward = 0;

        if (!isNodeOwner(account)) {
            return reward;
        }

        node = nodes[_index];

        require(nodeCountOfUser[account] >= _index, "MANAGEMENT: CALCULATE INDEX ERROR");

        reward = (block.timestamp - node.createTime).div(claimInterval).mul(node.rewardPerDay).sub(node.rewardedAmount);

        return reward;
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
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
}