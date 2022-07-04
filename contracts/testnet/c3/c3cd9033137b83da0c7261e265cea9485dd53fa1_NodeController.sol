/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-03
*/

// SPDX-License-Identifier: (Unlicense)
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
pragma solidity ^0.8.0;
interface INodeManager02 {
  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 lastCompoundTime;
    uint256 amount;
    bool deleted;
  }
  function getMinPrice() external view returns (uint256);
  function createNode(
    address account,
    string memory nodeName,
    uint256 amount
  ) external;
  function getNodeReward(address account, uint256 _creationTime)
    external
    view
    returns (uint256);
  function getAllNodesRewards(address account) external view returns (uint256);
  function cashoutNodeReward(address account, uint256 _creationTime) external;
  function cashoutAllNodesRewards(address account) external;
  function compoundNodeReward(
    address account,
    uint256 creationTime,
    uint256 rewardAmount
  ) external;
  function compoundAllNodesRewards(address account) external;
  function getAllNodes(address account)
    external
    view
    returns (NodeEntity[] memory);
  function renameNode(
    address account,
    string memory _newName,
    uint256 _creationTime
  ) external;
  function mergeNodes(
    address account,
    uint256 _creationTime1,
    uint256 _creationTime2
  ) external;
  function increaseNodeAmount(
    address account,
    uint256 _creationTime,
    uint256 _amount
  ) external;
  function migrateNodes(address account) external;
}
pragma solidity ^0.8.4;
abstract contract Authorizable {
  mapping(address => bool) private _authorizedAddresses;
  constructor() {
    _authorizedAddresses[msg.sender] = true;
  }
  modifier onlyAuthorized() {
    require(_authorizedAddresses[msg.sender], "Not authorized");
    _;
  }
  function setAuthorizedAddress(address _address, bool _value)
    public
    virtual
    onlyAuthorized
  {
    _authorizedAddresses[_address] = _value;
  }
  function isAuthorized(address _address) public view returns (bool) {
    return _authorizedAddresses[_address];
  }
}
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
pragma solidity ^0.8.0;
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.
    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
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
pragma solidity ^0.8.0;
interface INodeStorage {
  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 lastCompoundTime;
    uint256 amount;
    bool deleted;
  }
  function createNode(
    address _account,
    string memory _name,
    uint256 _amount
  ) external returns (bool);
  function migrateNode(
    address _account,
    string memory _name,
    uint256 _amount,
    uint256 _creationTime,
    uint256 _lastClaimTime,
    uint256 _lastCompoundTime
  ) external returns (bool);
  function setName(
    address _account,
    uint256 _creationTime,
    string memory _name
  ) external returns (bool);
  function setLastClaimTime(
    address _account,
    uint256 _creationTime,
    uint256 _timestamp
  ) external returns (bool);
  function setLastCompoundTime(
    address _account,
    uint256 _creationTime,
    uint256 _timestamp
  ) external returns (bool);
  function addAmount(
    address _account,
    uint256 _creationTime,
    uint256 _amount
  ) external returns (bool);
  function setDeleted(
    address _account,
    uint256 _creationTime,
    bool _isDeleted
  ) external returns (bool);
  function getNode(address _account, uint256 _creationTime)
    external
    view
    returns (NodeEntity memory);
  function getAllNodes(address _account)
    external
    view
    returns (NodeEntity[] memory);
  function getAllActiveNodes(address _account)
    external
    view
    returns (NodeEntity[] memory);
  function getAllDeletedNodes(address _account)
    external
    view
    returns (NodeEntity[] memory);
  function getNodesCount(address _account) external view returns (uint256);
  function isNodeDeleted(address _account, uint256 _creationTime)
    external
    view
    returns (bool);
}
pragma solidity ^0.8.4;
contract NodeController is Ownable, Pausable, Authorizable, ReentrancyGuard {
  using SafeMath for uint256;
  uint256 public rewardPerNode;
  uint256 public minTokensRequired;
  uint256 public totalNodesCreated;
  uint256 public totalNodesMigrated;
  uint256 public totalValueLocked;
  mapping(address => bool) public isBlacklisted;
  INodeStorage private nodeStorage;
  INodeManager02 private nodeManager02;
  uint256[] private _boostMultipliers = [105, 120, 140];
  uint256[] private _boostRequiredDays = [3, 7, 15];
  uint256[] private _compoundRequiredTokens = [5000, 10000, 20000];
  uint256[] private _compoundMultipliers = [125, 115, 105];
  event NodeIncreased(address indexed account, uint256 amount);
  event NodeCreated(address indexed account, uint256 amount, uint256 blockTime);
  event NodeMerged(
    address indexed account,
    uint256 sourceBlockTime,
    uint256 destBlockTime
  );
  constructor(
    address _nodeStorage,
    address _nodeManager02,
    uint256 _rewardPerNode,
    uint256 _minTokensRequired
  ) {
    nodeStorage = INodeStorage(_nodeStorage);
    nodeManager02 = INodeManager02(_nodeManager02);
    rewardPerNode = _rewardPerNode;
    minTokensRequired = _minTokensRequired;
  }
  // Getters and setters
  function getNodeStorageAddress() external view returns (address) {
    return address(nodeStorage);
  }
  function getBoostMultipliers() external view returns (uint256[] memory) {
    return _boostMultipliers;
  }
  function getBoostRequiredDays() external view returns (uint256[] memory) {
    return _boostRequiredDays;
  }
  function getCompoundRequiredTokens()
    external
    view
    returns (uint256[] memory)
  {
    return _compoundRequiredTokens;
  }
  function getCompoundMultipliers() external view returns (uint256[] memory) {
    return _compoundMultipliers;
  }
  function getMinTokensRequired() external view returns (uint256) {
    return minTokensRequired;
  }
  function setRewardPerNode(uint256 _rewardPerNode) external onlyAuthorized {
    rewardPerNode = _rewardPerNode;
  }
  function setMinTokensRequired(uint256 _minTokensRequired)
    external
    onlyAuthorized
  {
    minTokensRequired = _minTokensRequired;
  }
  function setNodeStorage(address _nodeStorage) external onlyAuthorized {
    nodeStorage = INodeStorage(_nodeStorage);
  }
  function setBoostMultipliers(uint256[] memory boostMultipliers)
    external
    onlyAuthorized
  {
    require(
      _boostMultipliers.length == boostMultipliers.length,
      "SetBoostMultipliers: Length mismatch"
    );
    _boostMultipliers = boostMultipliers;
  }
  function setBoostRequiredDays(uint256[] memory boostRequiredDays)
    external
    onlyAuthorized
  {
    require(
      _boostRequiredDays.length == boostRequiredDays.length,
      "SetBoostRequiredDays: Length mismatch"
    );
    _boostRequiredDays = boostRequiredDays;
  }
  function setCompoundRequiredTokens(uint256[] memory compoundRequiredTokens)
    external
    onlyAuthorized
  {
    require(
      _compoundRequiredTokens.length == compoundRequiredTokens.length,
      "SetCompoundRequiredTokens: Length mismatch"
    );
    _compoundRequiredTokens = compoundRequiredTokens;
  }
  function setCompoundMultipliers(uint256[] memory compoundMultipliers)
    external
    onlyAuthorized
  {
    require(
      _compoundMultipliers.length == compoundMultipliers.length,
      "SetCompoundMultipliers: Length mismatch"
    );
    _compoundMultipliers = compoundMultipliers;
  }
  // Rewards management
  function calculateNodeRewards(
    uint256 _lastClaimTime,
    uint256 _lastCompoundTime,
    uint256 _amount
  ) public view returns (uint256) {
    uint256 _boostMultiplier = _calculateBoost(_lastClaimTime);
    uint256 rewardPerDay = _amount.mul(rewardPerNode).div(100);
    uint256 rewardPerMinute = rewardPerDay.mul(10000).div(1440);
    uint256 _elapsedTime = (block.timestamp - _lastCompoundTime);
    uint256 elapsedMinutes = _elapsedTime / 1 minutes;
    return
      rewardPerMinute.mul(elapsedMinutes).div(10000).mul(_boostMultiplier).div(
        100
      );
  }
  function getCompoundBonus(
    address _account,
    uint256 _creationTime,
    uint256 _fee
  ) public view returns (uint256) {
    INodeStorage.NodeEntity memory node = nodeStorage.getNode(
      _account,
      _creationTime
    );
    uint256 _nodeRewards = calculateNodeRewards(
      node.lastClaimTime,
      node.lastCompoundTime,
      node.amount
    );
    uint256 rewardsAfterFees = _nodeRewards.sub(
      _nodeRewards.mul(_fee).div(100)
    );
    return rewardsAfterFees.mul(_calculateCompoundBonus(node.amount)).div(100);
  }
  function getNodeRewards(address _account, uint256 _creationTime)
    external
    view
    returns (uint256)
  {
    require(_creationTime > 0, "GetNodeRewards: Invalid creation time");
    INodeStorage.NodeEntity memory node = nodeStorage.getNode(
      _account,
      _creationTime
    );
    return
      calculateNodeRewards(
        node.lastClaimTime,
        node.lastCompoundTime,
        node.amount
      );
  }
  function getAllNodesRewards(address _account)
    external
    view
    returns (uint256)
  {
    uint256 totalRewards = 0;
    INodeStorage.NodeEntity[] memory nodes = nodeStorage.getAllActiveNodes(
      _account
    );
    for (uint256 i = 0; i < nodes.length; i++) {
      INodeStorage.NodeEntity memory node = nodes[i];
      if (node.amount > 0) {
        totalRewards = totalRewards.add(
          calculateNodeRewards(
            node.lastClaimTime,
            node.lastCompoundTime,
            node.amount
          )
        );
      }
    }
    return totalRewards;
  }
  function getNodesCount(address _account) external view returns (uint256) {
    return nodeStorage.getNodesCount(_account);
  }
  // Node management
  function createNode(
    address _account,
    string memory _name,
    uint256 _amount
  ) external whenNotPaused onlyAuthorized {
    require(_account != address(0), "CreateNode: Invalid account");
    require(
      _amount >= minTokensRequired,
      "CreateNode: Minimum required tokens"
    );
    nodeStorage.createNode(_account, _name, _amount);
    totalNodesCreated++;
    totalValueLocked += _amount;
    emit NodeCreated(_account, _amount, block.timestamp);
  }
  function claimNode(address _account, uint256 _creationTime)
    external
    onlyAuthorized
    whenNotPaused
  {
    require(_account != address(0), "ClaimNode: Invalid account");
    require(_creationTime > 0, "ClaimNode: Invalid creation time");
    nodeStorage.setLastClaimTime(_account, _creationTime, block.timestamp);
    nodeStorage.setLastCompoundTime(_account, _creationTime, block.timestamp);
  }
  function claimAllNodes(address _account)
    external
    whenNotPaused
    onlyAuthorized
  {
    require(_account != address(0), "ClaimAllNodes: Invalid account");
    INodeStorage.NodeEntity[] memory nodes = nodeStorage.getAllActiveNodes(
      _account
    );
    for (uint256 i = 0; i < nodes.length; i++) {
      if (nodes[i].amount > 0) {
        nodeStorage.setLastClaimTime(
          _account,
          nodes[i].creationTime,
          block.timestamp
        );
        nodeStorage.setLastCompoundTime(
          _account,
          nodes[i].creationTime,
          block.timestamp
        );
      }
    }
  }
  function compoundNode(
    address _account,
    uint256 _creationTime,
    uint256 _fee
  ) external whenNotPaused onlyAuthorized {
    require(_account != address(0), "CompoundNode: Invalid account");
    require(_creationTime > 0, "CompoundNode: Invalid creation time");
    require(_fee > 0, "CompoundNode: Invalid fee");
    uint256 _compoundBonus = getCompoundBonus(_account, _creationTime, _fee);
    nodeStorage.addAmount(_account, _creationTime, _compoundBonus);
    nodeStorage.setLastCompoundTime(_account, _creationTime, block.timestamp);
  }
  function compoundAllNodes(address _account, uint256 _fee)
    external
    whenNotPaused
    onlyAuthorized
  {
    require(_account != address(0), "CompoundAllNodes: Invalid account");
    require(_fee > 0, "CompoundAllNodes: Invalid fee");
    INodeStorage.NodeEntity[] memory nodes = nodeStorage.getAllActiveNodes(
      _account
    );
    for (uint256 i = 0; i < nodes.length; i++) {
      if (nodes[i].amount > 0) {
        nodeStorage.addAmount(
          _account,
          nodes[i].creationTime,
          getCompoundBonus(_account, nodes[i].creationTime, _fee)
        );
        nodeStorage.setLastCompoundTime(
          _account,
          nodes[i].creationTime,
          block.timestamp
        );
      }
    }
  }
  function migrateNodes(address account) external whenNotPaused nonReentrant {
    INodeManager02.NodeEntity[] memory oldNodes = nodeManager02.getAllNodes(
      account
    );
    require(oldNodes.length > 0, "MigrateNodes: No nodes to migrate");
    uint256 currentNodesCount = nodeStorage.getNodesCount(account);
    require(
      currentNodesCount.add(oldNodes.length) <= 100,
      "MigrateNodes: Max nodes"
    );
    for (uint256 index = 0; index < oldNodes.length; index++) {
      if (!oldNodes[index].deleted) {
        nodeStorage.migrateNode(
          account,
          oldNodes[index].name,
          oldNodes[index].amount,
          oldNodes[index].creationTime,
          oldNodes[index].lastClaimTime,
          oldNodes[index].lastCompoundTime
        );
        totalNodesCreated++;
        totalNodesMigrated++;
        totalValueLocked += oldNodes[index].amount;
      }
      emit NodeCreated(
        account,
        oldNodes[index].amount,
        oldNodes[index].creationTime
      );
    }
  }
  function renameNode(
    address _account,
    uint256 _creationTime,
    string memory _name
  ) external whenNotPaused onlyAuthorized {
    nodeStorage.setName(_account, _creationTime, _name);
  }
  function increaseNodeAmount(
    address _account,
    uint256 _creationTime,
    uint256 _amount
  ) external whenNotPaused onlyAuthorized {
    nodeStorage.addAmount(_account, _creationTime, _amount);
    nodeStorage.setLastCompoundTime(_account, _creationTime, block.timestamp);
  }
  function mergeNodes(
    address _account,
    uint256 _destBlocktime,
    uint256 _srcBlocktime
  ) external whenNotPaused onlyAuthorized {
    require(_account != address(0), "MergeNodes: Invalid account");
    require(
      _destBlocktime > 0 && _srcBlocktime > 0,
      "MergeNodes: Invalid blocktime"
    );
    require(
      !nodeStorage.isNodeDeleted(_account, _destBlocktime),
      "MergeNodes: Destination node deleted"
    );
    INodeStorage.NodeEntity memory sourceNode = nodeStorage.getNode(
      _account,
      _srcBlocktime
    );
    nodeStorage.setDeleted(_account, _srcBlocktime, true);
    nodeStorage.addAmount(_account, _destBlocktime, sourceNode.amount);
    nodeStorage.setLastClaimTime(_account, _destBlocktime, block.timestamp);
    nodeStorage.setLastCompoundTime(_account, _destBlocktime, block.timestamp);
    totalNodesCreated--;
    emit NodeMerged(_account, _srcBlocktime, _destBlocktime);
  }
  function _calculateBoost(uint256 _lastClaimTime)
    internal
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
  function _calculateCompoundBonus(uint256 nodeAmount)
    internal
    view
    returns (uint256)
  {
    uint256 _compoundBonus;
    if (nodeAmount < _compoundRequiredTokens[0] * 10**18) {
      _compoundBonus = _compoundMultipliers[0];
    } else if (nodeAmount < _compoundRequiredTokens[1] * 10**18) {
      _compoundBonus = _compoundMultipliers[1];
    } else if (nodeAmount < _compoundRequiredTokens[2] * 10**18) {
      _compoundBonus = _compoundMultipliers[2];
    } else {
      _compoundBonus = 100;
    }
    return _compoundBonus;
  }
  // Firewall methods
  function pause() external onlyAuthorized {
    _pause();
  }
  function unpause() external onlyAuthorized {
    _unpause();
  }
}