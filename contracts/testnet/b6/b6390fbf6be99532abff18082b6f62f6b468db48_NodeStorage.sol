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