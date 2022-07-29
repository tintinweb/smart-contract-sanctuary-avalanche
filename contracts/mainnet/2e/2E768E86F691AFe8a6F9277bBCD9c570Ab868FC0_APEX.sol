/**
 *Submitted for verification at snowtrace.io on 2022-07-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0, "toInt256Safe: B LESS THAN ZERO");
        return b;
    }
}

pragma solidity ^0.8.0;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(
            c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256),
            "mul: A B C combi values invalid with MIN_INT256"
        );
        require((b == 0) || (c / b == a), "mul: A B C combi values invalid");
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256, "div: b == 1 OR A == MIN_INT256");

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            (b >= 0 && c <= a) || (b < 0 && c > a),
            "sub: A B C combi values invalid"
        );
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            (b >= 0 && c >= a) || (b < 0 && c < a),
            "add: A B C combi values invalid"
        );
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256, "abs: A EQUAL MIN INT256");
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0, "toUint256Safe: A LESS THAN ZERO");
        return uint256(a);
    }
}

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

library Strings {
    function indexOf(string memory _base, string memory _value, uint _offset) internal pure returns (int) {
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

// OpenZeppelin Contracts v4.3.2 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
        functionCallWithValue(
            target,
            data,
            value,
            "Address: low-level call with value failed"
        );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
    {
        return
        functionStaticCall(
            target,
            data,
            "Address: low-level static call failed"
        );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
        return
        functionDelegateCall(
            target,
            data,
            "Address: low-level delegate call failed"
        );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountAVAX,
        uint256 liquidity
    );

}


// pragma solidity >=0.6.2;

interface IJoeRouter02 is IJoeRouter01 {
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IJoeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// OpenZeppelin Contracts v4.3.2 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        //unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(
            oldAllowance >= value,
            "SafeERC20: decreased allowance below zero"
        );
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
        //}
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract NODERewardManagement {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;
    using Strings for string;

    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 mainteneanceTime; // when the mainteneance was paid last time
        uint256 insuranceTime; // when the insurance was paid last time
        uint256 rewardAvailable;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) private _nodesOfUser;

    uint256 public nodePrice;
    uint256 public rewardPerNode;
    uint256 public claimTime;

    address public gateKeeper;
    address public token;

    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;

    uint256 public maxNodesPerWallet = 100;

    uint256 public mainteneancePeriod = 30 days;
    uint256 public insurancePeriod = 30 days;
    uint256 public gracePeriod = 30 days;

    constructor(
        uint256 _nodePrice,
        uint256 _rewardPerNode,
        uint256 _claimTime,
        address _gateKeeper,
        address _token
    ) {
        nodePrice = _nodePrice;
        rewardPerNode = _rewardPerNode;
        claimTime = _claimTime;
        gateKeeper = _gateKeeper;
        token = _token;
    }

    modifier onlySentry() {
        require(msg.sender == token || msg.sender == gateKeeper, "NOT AUTHORIZED");
        _;
    }

    function setMaxNodesPerWallet(uint256 _max) external onlySentry {
        maxNodesPerWallet = _max;
    }

    function setToken (address token_) external onlySentry {
        token = token_;
    }

    function _updateMainteneancePeriod(uint256 value) external onlySentry {
        mainteneancePeriod = value;
    }

    function _updateInsurancePeriod(uint256 value) external onlySentry {
        insurancePeriod = value;
    }

    function _updateGracePeriod(uint256 value) external onlySentry {
        gracePeriod = value;
    }

    function createNode(address account, string memory nodeName) external onlySentry {
        require(_nodesOfUser[account].length < maxNodesPerWallet, "You reached Max Nodes limit!");

        require(nodeName.indexOf("#", 0) == -1, "# is not allowed!");
        require(!_existsNodeWithCreatime(account, block.timestamp), "You have already a node with the current timestamp!");

        _nodesOfUser[account].push(
            NodeEntity({
                name: nodeName,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                mainteneanceTime: block.timestamp,
                insuranceTime: 0,
                rewardAvailable: 0
            })
        );
        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
    }

    function changeNodeName(address account, string memory nodeName, uint256 _creationTime) external onlySentry {
        require(
            bytes(nodeName).length > 3 && bytes(nodeName).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );

        require(nodeName.indexOf("#", 0) == -1, "# is not allowed!");

        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to rename"
        );
        (,uint256 index) = _getNodeWithCreatime(nodes, _creationTime);

        nodes[index].name = nodeName;

    }

    function createNodeWithTimestamp(address account, string memory nodeName, uint256 timestamp) external onlySentry {
        require(_nodesOfUser[account].length < maxNodesPerWallet, "You reached Max Nodes limit!");
        
        require(
            bytes(nodeName).length > 3 && bytes(nodeName).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );

        require(nodeName.indexOf("#", 0) == -1, "# is not allowed!");
        require(!_existsNodeWithCreatime(account, timestamp), "You have already a node with the current timestamp!");

        _nodesOfUser[account].push(
            NodeEntity({
                name: nodeName,
                creationTime: timestamp,
                lastClaimTime: timestamp,
                mainteneanceTime: timestamp,
                insuranceTime: 0,
                rewardAvailable: 0
            })
        );
        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
    }

    function isNameAvailable(address account, string memory nodeName) private view returns (bool) {
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

    function _existsNodeWithCreatime(address account, uint256 _creationTime) private view returns (bool) {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;

        if(numberOfNodes == 0) return false;

        if(nodes[numberOfNodes - 1].creationTime >= _creationTime) return true;

        return false;
    }

    function _getNodeWithCreatime(NodeEntity[] storage nodes, uint256 _creationTime) private view returns (NodeEntity storage, uint256) {
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

    function binary_search(NodeEntity[] memory arr, uint256 low, uint256 high, uint256 x) private view returns (int256) {
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

    function _calculateReward(NodeEntity memory node) private view returns (uint256) {
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

    function _calculateRewardWithFixedTimestamp(NodeEntity memory node, uint256 timestamp) private view returns (uint256) {
        uint256 lastClaim = node.lastClaimTime;
        uint256 claims = 0;

        if (lastClaim == 0) {
            claims = claims.add(1);
            lastClaim = node.creationTime;
        }

        uint256 currentTime = timestamp;
        uint256 _claims = (currentTime.sub(lastClaim)).div(claimTime);
        claims = claims.add(_claims);

        return rewardPerNode.mul(claims);
    }

    function _cashoutNodeReward(address account, uint256 _creationTime) external onlySentry returns (uint256) {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        (NodeEntity storage node, uint256 index) = _getNodeWithCreatime(nodes, _creationTime);

        uint256 rewardNode;

        if(block.timestamp < node.mainteneanceTime + mainteneancePeriod) {
            rewardNode = _calculateReward(node) + node.rewardAvailable;

            nodes[index].lastClaimTime = block.timestamp;
            nodes[index].rewardAvailable = 0;
        } else {

            if(nodes[index].lastClaimTime > nodes[index].mainteneanceTime + mainteneancePeriod) {
                rewardNode = 0;

                nodes[index].lastClaimTime = block.timestamp;
                nodes[index].rewardAvailable = 0;
            } else {
                rewardNode = _calculateRewardWithFixedTimestamp(nodes[index], nodes[index].mainteneanceTime + mainteneancePeriod).add(nodes[index].rewardAvailable);

                nodes[index].rewardAvailable = 0;
                nodes[index].lastClaimTime = block.timestamp;
            }

        }

        totalRewardStaked += rewardNode;

        return rewardNode;
    }

    function _cashoutAllNodesReward(address account) external onlySentry returns (uint256) {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        uint256 rewardsTotal = 0;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        for (uint256 i = 0; i < nodesCount; i++) {

            if(block.timestamp < nodes[i].mainteneanceTime + mainteneancePeriod) {
                rewardsTotal += _calculateReward(nodes[i]).add(
                    nodes[i].rewardAvailable
                );
                nodes[i].lastClaimTime = block.timestamp;
                nodes[i].rewardAvailable = 0;
            } else {

                if(nodes[i].lastClaimTime > nodes[i].mainteneanceTime + mainteneancePeriod) {
                    rewardsTotal += 0;

                    nodes[i].lastClaimTime = block.timestamp;
                    nodes[i].rewardAvailable = 0;
                } else {
                    rewardsTotal += _calculateRewardWithFixedTimestamp(nodes[i], nodes[i].mainteneanceTime + mainteneancePeriod).add(nodes[i].rewardAvailable);

                    nodes[i].rewardAvailable = 0;
                    nodes[i].lastClaimTime = block.timestamp;
                }

            }

        }

        totalRewardStaked += rewardsTotal;
        return rewardsTotal;
    }

    function _payInsurance(address account, uint256 _creationTime) external onlySentry {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to pay insurance of"
        );
        (,uint256 index) = _getNodeWithCreatime(nodes, _creationTime);

        if(block.timestamp > nodes[index].mainteneanceTime + mainteneancePeriod + gracePeriod) {
            return;
        }

        if(block.timestamp < nodes[index].insuranceTime + insurancePeriod) {
            nodes[index].insuranceTime += insurancePeriod;
        } else {
            nodes[index].insuranceTime = block.timestamp;
        }

    }

    function _payInsuranceAll(address account) external onlySentry {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to pay insurance of"
        );

        for (uint256 i = 0; i < numberOfNodes; i++) {

            if(block.timestamp > nodes[i].mainteneanceTime + mainteneancePeriod + gracePeriod) {
                continue;
            }

            if(block.timestamp < nodes[i].insuranceTime + insurancePeriod) {
                nodes[i].insuranceTime += insurancePeriod;
            } else {
                nodes[i].insuranceTime = block.timestamp;
            }

        }

    }

    function _payMainteneance(address account, uint256 _creationTime) external onlySentry {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to pay mainteneance of"
        );
        (,uint256 index) = _getNodeWithCreatime(nodes, _creationTime);

        if(block.timestamp > nodes[index].mainteneanceTime + mainteneancePeriod + gracePeriod) {
            return;
        }

        if(block.timestamp < nodes[index].mainteneanceTime + mainteneancePeriod) {
            nodes[index].mainteneanceTime += mainteneancePeriod;
        } else {

            if(nodes[index].lastClaimTime > nodes[index].mainteneanceTime + mainteneancePeriod) {
                nodes[index].mainteneanceTime = block.timestamp;
                nodes[index].lastClaimTime = block.timestamp;
                nodes[index].rewardAvailable = 0;
            } else {
                nodes[index].rewardAvailable = _calculateRewardWithFixedTimestamp(nodes[index], nodes[index].mainteneanceTime + mainteneancePeriod).add(nodes[index].rewardAvailable);
                nodes[index].mainteneanceTime = block.timestamp;
                nodes[index].lastClaimTime = block.timestamp;
            }

        }

    }

    function _payMainteneanceAll(address account) external onlySentry {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to pay mainteneance of"
        );

        for (uint256 i = 0; i < numberOfNodes; i++) {

            if(block.timestamp > nodes[i].mainteneanceTime + mainteneancePeriod + gracePeriod) {
                continue;
            }

            if(block.timestamp < nodes[i].mainteneanceTime + mainteneancePeriod) {
                nodes[i].mainteneanceTime += mainteneancePeriod;
            } else {
                if(nodes[i].lastClaimTime > nodes[i].mainteneanceTime + mainteneancePeriod) {
                    nodes[i].mainteneanceTime = block.timestamp;
                    nodes[i].lastClaimTime = block.timestamp;
                    nodes[i].rewardAvailable = 0;
                } else {
                    nodes[i].rewardAvailable = _calculateRewardWithFixedTimestamp(nodes[i], nodes[i].mainteneanceTime + mainteneancePeriod).add(nodes[i].rewardAvailable);
                    nodes[i].mainteneanceTime = block.timestamp;
                    nodes[i].lastClaimTime = block.timestamp;
                }
            }

        }

    }

    function claimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimTime <= block.timestamp;
    }

    function _getRewardAmountOf(address account) external view returns (uint256) {
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

    function _getValidRewardAmountOf(address account) external view returns (uint256) {
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            if(block.timestamp < nodes[i].mainteneanceTime + mainteneancePeriod) {
                rewardCount += _calculateReward(nodes[i]).add(
                    nodes[i].rewardAvailable
                );
            } else {
                if(nodes[i].lastClaimTime > nodes[i].mainteneanceTime + mainteneancePeriod) {
                    rewardCount += 0;
                } else {
                    rewardCount += _calculateRewardWithFixedTimestamp(nodes[i], nodes[i].mainteneanceTime + mainteneancePeriod).add(nodes[i].rewardAvailable);
                }
            }
        }

        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 _creationTime) public view returns (uint256) {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        (NodeEntity storage node, ) = _getNodeWithCreatime(
            nodes,
            _creationTime
        );
        uint256 rewardNode = _calculateReward(node).add(node.rewardAvailable);
        return rewardNode;
    }

    function _getValidRewardAmountOf(address account, uint256 _creationTime) public view returns (uint256) {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        (NodeEntity storage node, ) = _getNodeWithCreatime(
            nodes,
            _creationTime
        );

        uint256 rewardNode;

        if(block.timestamp < node.mainteneanceTime + mainteneancePeriod) {  
            rewardNode = _calculateReward(node).add(node.rewardAvailable);
        } else {

            if(node.lastClaimTime > node.mainteneanceTime + mainteneancePeriod) {
                rewardNode = 0;
            } else {
                rewardNode = _calculateRewardWithFixedTimestamp(node, node.mainteneanceTime + mainteneancePeriod).add(node.rewardAvailable);
            }

        }

        return rewardNode;
    }

    function _getMaintainableNodeNumberOf(address account) external view returns (uint256) {

        uint256 nodesCount;
        uint256 validNodesCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            if(block.timestamp < nodes[i].mainteneanceTime + mainteneancePeriod + gracePeriod) {
                validNodesCount++;
            }
        }

        return validNodesCount;

    }

    function _getValidNodeNumberOf(address account) external view returns (uint256) {

        uint256 nodesCount;
        uint256 validNodesCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            if(block.timestamp < nodes[i].mainteneanceTime + mainteneancePeriod) {
                if(_calculateReward(nodes[i]).add(nodes[i].rewardAvailable) > 0) {
                    validNodesCount++;
                }
            } else {
                if(nodes[i].lastClaimTime > nodes[i].mainteneanceTime + mainteneancePeriod) {
                } else {
                    if(_calculateRewardWithFixedTimestamp(nodes[i], nodes[i].mainteneanceTime + mainteneancePeriod).add(nodes[i].rewardAvailable) > 0) {
                        validNodesCount++;
                    } 
                }
            }
        }

        return validNodesCount;

    }

    function _getNodesNames(address account) external view returns (string memory) {
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

    function _getNodesCreationTime(address account) external view returns (string memory) {
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

    function _getNodesRewardAvailable(address account) external view returns (string memory) {
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

    function _getNodesValidRewardAvailable(address account) external view returns (string memory) {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(_getValidRewardAmountOf(account,nodes[0].creationTime));
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(_getValidRewardAmountOf(account,_node.creationTime))
                )
            );
        }
        return _rewardsAvailable;
    }

    function _getNodesLastClaimTime(address account) external view returns (string memory) {
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

    function _getNodesMainteneanceTime(address account) external view returns (string memory) {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _mainteneanceTimes = uint2str(nodes[0].mainteneanceTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _mainteneanceTimes = string(
                abi.encodePacked(
                    _mainteneanceTimes,
                    separator,
                    uint2str(_node.mainteneanceTime)
                )
            );
        }
        return _mainteneanceTimes;
    }

    function _getNodesInsuranceTime(address account) external view returns (string memory) {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _insuranceTimes = uint2str(nodes[0].insuranceTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _insuranceTimes = string(
                abi.encodePacked(
                    _insuranceTimes,
                    separator,
                    uint2str(_node.insuranceTime)
                )
            );
        }
        return _insuranceTimes;
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

pragma solidity ^0.8.0;

contract APEX is IERC20, Ownable {
    using SafeMath for uint256;

    NODERewardManagement public nodeRewardManager;

    
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "Apex";
    string private _symbol = "APEX";

    IJoeRouter02 public uniswapV2Router;

    address public receiptAddress;
    address public usdcAddress = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    address public uniswapV2Pair;
    address public treasuryPool;
    address public claimPool;
    address public distributionPool;
    address public mainteneancePool;
    address public insurancePool;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public rewardsFee;
    uint256 public liquidityPoolFee;
    uint256 public treasuryFee;
    uint256 public totalFees;

    uint256 public cashoutFee;

    bool private swapping = false;
    bool private swapLiquify = true;
    uint256 public swapTokensAmount;
    bool public isTradingEnabled = false;
    mapping (address => bool) public isFeeExempt;

    uint256 public claimTax = 50000000000000000; // AVAX
    uint256 public mainteneanceTax = 35000000; // USDC
    uint256 public insuranceTax = 3000000; // USDC

    uint256 public maxClaimableNodes = 4;
    bool public sellProtection = true;

    uint256 public sellFee = 30;
    uint256 public feeDenominator = 100;

    uint256 public maxTxnAmount = 100000000000000000000;

    mapping (address => bool) public isTxLimitExempt;
    mapping(address => bool) public isExcludedFromClaim;
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) public claimedNodes;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event Cashout(
        address indexed account,
        uint256 amount,
        uint256 indexed blockTime
    );

    event Compound(
        address indexed account
    );

    constructor(
        address _treasuryPool,
        address _distributionPool,
        address _claimPool,
        address _mainteneancePool,
        address _insurancePool,
        address _receiptAddress,
        uint256[] memory fees,
        uint256 swapAmount,
        address uniV2Router
    ) {

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[msg.sender] = true;

        treasuryPool = _treasuryPool;
        distributionPool = _distributionPool;
        claimPool = _claimPool;
        mainteneancePool = _mainteneancePool;
        insurancePool = _insurancePool;
        receiptAddress = _receiptAddress;

        require(treasuryPool != address(0) && distributionPool != address(0) && receiptAddress != address(0), "TREASURY, REWARD & RECEIPT ADDRESS CANNOT BE ZERO");

        require(uniV2Router != address(0), "ROUTER CANNOT BE ZERO");
        IJoeRouter02 _uniswapV2Router = IJoeRouter02(uniV2Router);

        address _uniswapV2Pair = IJoeFactory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WAVAX());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        require(
            fees[0] != 0 && fees[1] != 0 && fees[2] != 0,
            "CONSTR: Fees equal 0"
        );
        treasuryFee = fees[0];
        rewardsFee = fees[1];
        liquidityPoolFee = fees[2];
        cashoutFee = fees[3];

        totalFees = rewardsFee.add(liquidityPoolFee).add(treasuryFee);

        _mint(msg.sender, 1_200_000 * 10**18);

        require(totalSupply() == 1_200_000 * 10**18, "CONSTR: totalSupply is different!");
        require(swapAmount > 0, "CONSTR: Swap amount incorrect");
        swapTokensAmount = swapAmount;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function setNodeManagement(address nodeManagement) external onlyOwner {
        nodeRewardManager = NODERewardManagement(nodeManagement);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "TKN: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IJoeRouter02(newAddress);
        address _uniswapV2Pair = IJoeFactory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WAVAX());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateMaxClaimableNodes(uint256 newVal) external onlyOwner {
        maxClaimableNodes = newVal;
    }

    function updateClaimInfo(address payable wall, uint256 value) external onlyOwner {
        claimPool = wall;
        claimTax = value;
    }

    function updateTreasuryInfo(address payable wall) external onlyOwner {
        treasuryPool = wall;
    }

    function updateMainteneanceInfo(address payable wall, uint256 value) external onlyOwner {
        mainteneancePool = wall;
        mainteneanceTax = value;
    }

    function updateInsuranceInfo(address payable wall, uint256 value) external onlyOwner {
        insurancePool = wall;
        insuranceTax = value;
    }

    function updateRewardsInfo(address payable wall) external onlyOwner {
        distributionPool = wall;
    }

    function updateUSDCAddress(address token) external onlyOwner {
        usdcAddress = token;
    }

    function updateSellProtection(bool status) external onlyOwner {
        sellProtection = status;
    }

    function updateMaxTxnAmount(uint256 maxBuy) public onlyOwner {
        maxTxnAmount = maxBuy;
    }


    function updatePeriods(uint256 mainteneancePeriod, uint256 gracePeriod, uint256 insurancePeriod) external onlyOwner {
        nodeRewardManager._updateMainteneancePeriod(mainteneancePeriod);
        nodeRewardManager._updateGracePeriod(gracePeriod);
        nodeRewardManager._updateInsurancePeriod(insurancePeriod);
    }
    
    function updateFees(uint256 _rewardsFee, uint256 _liquidityFee, uint256 _treasuryFee, uint256 _cashoutFee) external onlyOwner {
        rewardsFee = _rewardsFee;
        liquidityPoolFee = _liquidityFee;
        treasuryFee = _treasuryFee;
        cashoutFee = _cashoutFee;
        totalFees = rewardsFee.add(liquidityPoolFee).add(treasuryFee);
    }

    function updateIsTradingEnabled(bool newVal) external onlyOwner {
        isTradingEnabled = newVal;
    }

    function setReceiptAddress(address _receipt) external onlyOwner {
        receiptAddress = _receipt;
    }

    function updateSellFee(uint256 _sellFee, uint256 _feeDenominator) external onlyOwner {
        sellFee = _sellFee;
        feeDenominator = _feeDenominator;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "TKN: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistMalicious(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TKN: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {        
        require(
            !_isBlacklisted[sender] && !_isBlacklisted[recipient],
            "Blacklisted address"
        );

        if (!isFeeExempt[sender]) {
            require(isTradingEnabled, "TRADING_DISABLED");
        }
        
        if(swapping){ return _basicTransfer(sender, recipient, amount); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient, amount) ? takeFee(sender, recipient, amount) : amount;

        uint256 feeAmount = amount - amountReceived;

        if (feeAmount > 0) {
            if(swapLiquify){ 
                swapping = true;
                
                swapAndSendToFee(treasuryPool, feeAmount);

                swapping = false;
            }
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address recipient, uint256 amount) internal view returns (bool) {

        address routerAddress = address(uniswapV2Router);
        bool isSell = automatedMarketMakerPairs[recipient] || recipient == routerAddress;
        bool isBuy = automatedMarketMakerPairs[sender] || sender == routerAddress;

        if(isSell) {

            if(sellProtection && !isFeeExempt[sender]) require(nodeRewardManager._getNodeNumberOf(sender) > 0, "You don't own any node!");

            return !isFeeExempt[sender] && !isFeeExempt[recipient];
        } else if(isBuy) {
            require(
                amount <= maxTxnAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], 
                "Transfer amount exceeds the maxTxAmount."
            );
            return false;
        } else {
            return false;
        }

    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(sellFee).div(feeDenominator);

        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        (bool success, ) = destination.call{value: newBalance}("");
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WAVAX();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityAVAX{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            treasuryPool,
            block.timestamp
        );
    }

    function createNodeWithTokens(string memory nodeName) public {
        require(
            bytes(nodeName).length > 3 && bytes(nodeName).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );
        address sender = _msgSender();
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "NODE CREATION: Blacklisted address");
        require(
            sender != treasuryPool && sender != distributionPool,
            "NODE CREATION: treasury and rewardsPool cannot create node"
        );
        uint256 nodePrice = nodeRewardManager.nodePrice();
        require(
            balanceOf(sender) >= nodePrice,
            "NODE CREATION: Balance too low for creation."
        );
        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (
            swapAmountOk &&
            swapLiquify &&
            !swapping &&
            sender != owner() &&
            !automatedMarketMakerPairs[sender]
        ) {
            swapping = true;

            uint256 treasuryTokens = contractTokenBalance.mul(treasuryFee).div(100);

            swapAndSendToFee(treasuryPool, treasuryTokens);

            uint256 rewardsPoolTokens = contractTokenBalance
            .mul(rewardsFee)
            .div(100);

            _basicTransfer(
                address(this),
                distributionPool,
                rewardsPoolTokens
            );

            uint256 swapTokens = contractTokenBalance.mul(liquidityPoolFee).div(
                100
            );

            swapAndLiquify(swapTokens);

            swapping = false;
        }
        _basicTransfer(sender, address(this), nodePrice);
        nodeRewardManager.createNode(sender, nodeName);
    }

    function changeNodeName(string memory nodeName, uint256 creationTime) public {
        address sender = _msgSender();

        nodeRewardManager.changeNodeName(sender, nodeName, creationTime);
    }

    receive() external payable {}

    function compound(string memory nodeName) public payable {
        address sender = _msgSender();

        require(
            sender != address(0),
            "MANIA COMPOUND:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA COMPOUND: Blacklisted address");
        require(
            sender != treasuryPool && sender != distributionPool,
            "MANIA COMPOUND: treasury and rewardsPool cannot compound rewards"
        );
        uint256 rewardAmount = nodeRewardManager._getValidRewardAmountOf(sender);

        uint256 nodePrice = nodeRewardManager.nodePrice();

        require(
            rewardAmount >= nodePrice,
            "MANIA COMPOUND: You don't have enough reward to compound"
        );

        uint256 compoundedNodesAmount = rewardAmount / nodePrice;

        _basicTransfer(distributionPool, sender, rewardAmount - nodePrice * compoundedNodesAmount);
        nodeRewardManager._cashoutAllNodesReward(sender);
    
        _basicTransfer(distributionPool, address(this), nodePrice * compoundedNodesAmount);

        for(uint i = 0; i < compoundedNodesAmount; i++) {
            nodeRewardManager.createNodeWithTimestamp(sender, nodeName, block.timestamp + i);
        }

        emit Cashout(sender, rewardAmount - nodePrice * compoundedNodesAmount, 0);
        emit Compound(sender);
    }

    function claimNodes(string memory nodeName, uint256 amount) public {
        require(claimedNodes[msg.sender] + amount <= maxClaimableNodes || isExcludedFromClaim[msg.sender], "Max claimable nodes reached!");

        claimedNodes[msg.sender] += amount;

        require(IERC20(receiptAddress).balanceOf(msg.sender) >= amount, "You have not enough receipt tokens!");
        require(IERC20(receiptAddress).allowance(msg.sender, address(this)) >= amount, "You have not approved receipt token yet!");

        IERC20(receiptAddress).transferFrom(msg.sender, deadWallet, amount);

        for(uint i = 0; i < amount; i++) {
            nodeRewardManager.createNodeWithTimestamp(msg.sender, nodeName, block.timestamp + i);
        } 
    }

    function payInsurance(uint256 _creationTime) public payable {

        if(insuranceTax > 0) {

            require(IERC20(usdcAddress).balanceOf(msg.sender) >= insuranceTax, "You have not enough USDC to pay tax!");
            require(IERC20(usdcAddress).allowance(msg.sender, address(this)) >= insuranceTax, "You have not approved USDC yet!");
            IERC20(usdcAddress).transferFrom(msg.sender, insurancePool, insuranceTax);

        }

        address sender = _msgSender();

        nodeRewardManager._payInsurance(sender, _creationTime); 
    }

    function payInsuranceAll() public payable {
        address sender = _msgSender();

        if(insuranceTax > 0) {

            uint256 nodesNumber = nodeRewardManager._getMaintainableNodeNumberOf(sender);

            require(IERC20(usdcAddress).balanceOf(msg.sender) >= insuranceTax * nodesNumber, "You have not enough USDC to pay tax!");
            require(IERC20(usdcAddress).allowance(msg.sender, address(this)) >= insuranceTax * nodesNumber, "You have not approved USDC yet!");
            IERC20(usdcAddress).transferFrom(msg.sender, insurancePool, insuranceTax * nodesNumber);

        }

        nodeRewardManager._payInsuranceAll(sender); 
    }

    function payMainteneance(uint256 _creationTime) public payable {

        if(mainteneanceTax > 0) {

            require(IERC20(usdcAddress).balanceOf(msg.sender) >= mainteneanceTax, "You have not enough USDC to pay tax!");
            require(IERC20(usdcAddress).allowance(msg.sender, address(this)) >= mainteneanceTax, "You have not approved USDC yet!");
            IERC20(usdcAddress).transferFrom(msg.sender, mainteneancePool, mainteneanceTax);

        }

        address sender = _msgSender();

        nodeRewardManager._payMainteneance(sender, _creationTime); 
    }

    function payMainteneanceAll() public payable {
        address sender = _msgSender();

        if(mainteneanceTax > 0) {

            uint256 nodesNumber = nodeRewardManager._getMaintainableNodeNumberOf(sender);

            require(IERC20(usdcAddress).balanceOf(msg.sender) >= mainteneanceTax * nodesNumber, "You have not enough USDC to pay tax!");
            require(IERC20(usdcAddress).allowance(msg.sender, address(this)) >= mainteneanceTax * nodesNumber, "You have not approved USDC yet!");
            IERC20(usdcAddress).transferFrom(msg.sender, mainteneancePool, mainteneanceTax * nodesNumber);

        }

        nodeRewardManager._payMainteneanceAll(sender); 
    }

    function cashoutReward(uint256 blocktime) public payable {
        require(msg.value == claimTax, "You have to pay the claim tax!");
        if(msg.value > 0) claimPool.call{value: msg.value}("");
        address sender = _msgSender();
        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != treasuryPool && sender != distributionPool,
            "CSHT: treasury and rewardsPool cannot cashout rewards"
        );
        uint256 rewardAmount = nodeRewardManager._getValidRewardAmountOf(
            sender,
            blocktime
        );
        require(
            rewardAmount > 0,
            "CSHT: You don't have enough reward to cash out"
        );

        if (swapLiquify) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount.mul(cashoutFee).div(100);
                _basicTransfer(distributionPool, address(this), feeAmount);
                swapAndSendToFee(treasuryPool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }

        _basicTransfer(distributionPool, sender, rewardAmount);
        nodeRewardManager._cashoutNodeReward(sender, blocktime);

        emit Cashout(sender, rewardAmount, blocktime);
    }

    function cashoutAll() public payable {
        address sender = _msgSender();

        require(msg.value == claimTax * nodeRewardManager._getValidNodeNumberOf(sender), "You have to pay the claim tax!");
        if(msg.value > 0) claimPool.call{value: msg.value}("");

        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != treasuryPool && sender != distributionPool,
            "MANIA CSHT: treasury and rewardsPool cannot cashout rewards"
        );
        uint256 rewardAmount = nodeRewardManager._getValidRewardAmountOf(sender);

        require(
            rewardAmount > 0,
            "MANIA CSHT: You don't have enough reward to cash out"
        );
        if (swapLiquify) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount.mul(cashoutFee).div(100);
                _basicTransfer(distributionPool, address(this), feeAmount);
                swapAndSendToFee(treasuryPool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }
        _basicTransfer(distributionPool, sender, rewardAmount);
        nodeRewardManager._cashoutAllNodesReward(sender);
    
        emit Cashout(sender, rewardAmount, 0);
    }

    function Sweep(uint amount) public onlyOwner {
        if (amount > address(this).balance) amount = address(this).balance;
        (bool success, ) = owner().call{value: amount}("");
    }

    function changeSwapLiquify(bool newVal) public onlyOwner {
        swapLiquify = newVal;
    }

    function changeNodePrice(uint256 newNodePrice) public onlyOwner {
        nodeRewardManager._changeNodePrice(newNodePrice);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsExcludedFromClaim(address holder, bool exempt) external onlyOwner {
        isExcludedFromClaim[holder] = exempt;
    }

    function changeRewardPerNode(uint256 newPrice) public onlyOwner {
        nodeRewardManager._changeRewardPerNode(newPrice);
    }

    function changeClaimTime(uint256 newTime) public onlyOwner {
        nodeRewardManager._changeClaimTime(newTime);
    }

    function getNodeNumberOf(address account) public view returns (uint256) {
        return nodeRewardManager._getNodeNumberOf(account);
    }

    function getMaintainableNodeNumberOf(address account) public view returns (uint256) {
        return nodeRewardManager._getMaintainableNodeNumberOf(account);
    }

    function getValidNodeNumberOf(address account) public view returns (uint256) {
        return nodeRewardManager._getValidNodeNumberOf(account);
    }

    function getValidRewardAmount() public view returns (uint256) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getValidRewardAmountOf(_msgSender());
    }

    function getNodesNames() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getNodesNames(_msgSender());
    }

    function getNodesCreatime() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getNodesCreationTime(_msgSender());
    }

    function getNodesValidRewards() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getNodesValidRewardAvailable(_msgSender());
    }

    function getNodesMainteneanceTime() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getNodesMainteneanceTime(_msgSender());
    }

    function getNodesInsuranceTime() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getNodesInsuranceTime(_msgSender());
    }

    function getNodesLastClaims() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getNodesLastClaimTime(_msgSender());
    }
}