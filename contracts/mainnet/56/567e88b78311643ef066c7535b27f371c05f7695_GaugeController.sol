/**
 *Submitted for verification at snowtrace.io on 2022-09-19
*/

// File: contracts/interfaces/IVeERC20.sol


pragma solidity ^0.8.0;

interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}
// File: contracts/interfaces/IVeQi.sol


pragma solidity ^0.8.0;


/**
 * @dev Interface of the VeQi
 */
interface IVeQi is IVeERC20 {
    function isUser(address _addr) external view returns (bool);

    function deposit(uint256 _amount) external;

    function claim() external;

    function withdraw(uint256 _amount) external;

    function getStakedQi(address _addr) external view returns (uint256);

    function eventualTotalSupply() external view returns (uint256);

    function eventualBalanceOf(address account) external view returns (uint256);
}
// File: contracts/interfaces/IGaugeController.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface of the GaugeController
 */
interface IGaugeController {
    function getNodesRange(uint256 _from, uint256 _to) external view returns (string[] memory);
    function getNodesLength() external view returns (uint256);
    function getNodeUsersRange(string memory _nodeId, uint256 _from, uint256 _to) external view returns (address[] memory);
    function getNodeUsersLength(string memory _nodeId) external view returns (uint256);
    function getVotesRange(uint256 _from, uint256 _to) external view returns (string[] memory, uint256[] memory);
    function getVotesForNode(string memory _nodeId) external view returns (uint256);
    function voteNodes(string[] memory _nodeIds, uint256[] memory _weights) external;
    function voteNode(string memory _nodeId, uint256 _weight) external;
    function unvoteNodes(string[] memory _nodeIds, uint256[] memory _weights) external;
    function unvoteNode(string memory _nodeId, uint256 _weight) external;
    function getUserVotesLength() external view returns (uint256);
    function getUserVotesRange(uint256 _from, uint256 _to) external view returns (string[] memory, uint256[] memory);
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: contracts/GaugeController.sol


pragma solidity ^0.8.0;





/// @title GaugeController
/// @notice controls allocation gauges for liquid staking delegation
contract GaugeController is IGaugeController, Initializable, OwnableUpgradeable {

    /// @notice veQi contract
    IVeQi public veQi;

    /// @notice cumulative weight that has been allocated (in bips)
    mapping(address => uint256) public userVotedWeight;

    /// @notice nodes that a user has voted
    mapping(address => string[]) public userVotedNodes;

    /// @notice user node array lookup map
    mapping(address => mapping(string => uint256)) public userVotedNodesIndexes;

    /// @notice cumulative weight that has been allocated to a node by user (in bips)
    mapping(string => mapping(address => uint256)) public nodeUserVotedWeight;

    /// @notice users who voted for a node
    mapping(string => address[]) public nodeUsers;
    mapping(string => mapping(address => uint256)) public nodeUsersIndex;

    /// @notice nodes with vote
    string[] public nodes;
    mapping(string => uint256) public nodesIndex;

    event VoteNode(address indexed user, string nodeId, uint256 weight);
    event UnvoteNode(address indexed user, string nodeId, uint256 weight);

    function initialize(IVeQi _veQi) public initializer {
        require(address(_veQi) != address(0), "zero address");

        __Ownable_init();

        veQi = _veQi;
    }

    /// @notice votes for validator nodes
    /// @param _nodeIds list of node ids
    /// @param _weights list of weights in bips
    function voteNodes(string[] calldata _nodeIds, uint256[] calldata _weights) external override {
        require(_nodeIds.length == _weights.length, "nodeIds and weights array length mismatch");

        uint256 length = _nodeIds.length;
        for (uint256 i; i < length;) {
            voteNode(_nodeIds[i], _weights[i]);
            unchecked { ++i; }
        }
    }

    /// @notice votes for a validator node
    /// @param _nodeId node id
    /// @param _weight weight in bips
    function voteNode(string calldata _nodeId, uint256 _weight) public override {
        uint256 newTotalWeight = userVotedWeight[msg.sender] + _weight;

        require(_weight > 0, "zero vote");
        require(newTotalWeight <= 10000, "exceeded all available weight");

        userVotedWeight[msg.sender] = newTotalWeight;

        if (nodeUsers[_nodeId].length == 0) {
            nodesIndex[_nodeId] = nodes.length;
            nodes.push(_nodeId);
        }

        if (nodeUserVotedWeight[_nodeId][msg.sender] == 0) {
            nodeUsersIndex[_nodeId][msg.sender] = nodeUsers[_nodeId].length;
            nodeUsers[_nodeId].push(msg.sender);

            userVotedNodesIndexes[msg.sender][_nodeId] = userVotedNodes[msg.sender].length;
            userVotedNodes[msg.sender].push(_nodeId);
        }

        unchecked {
            nodeUserVotedWeight[_nodeId][msg.sender] = nodeUserVotedWeight[_nodeId][msg.sender] + _weight;
        }

        emit VoteNode(msg.sender, _nodeId, _weight);
    }

    /// @notice unvotes for validator nodes
    /// @param _nodeIds list of node ids
    /// @param _weights list of weights in bips
    function unvoteNodes(string[] calldata _nodeIds, uint256[] calldata _weights) external override {
        require(_nodeIds.length == _weights.length, "nodeIds and weights array length mismatch");

        uint256 length = _nodeIds.length;
        for (uint256 i; i < length;) {
            unvoteNode(_nodeIds[i], _weights[i]);
            unchecked { ++i; }
        }
    }

    /// @notice unvotes for a validator node
    /// @param _weight weight in bips
    function unvoteNode(string calldata _nodeId, uint256 _weight) public override {
        uint256 newTotalWeight = userVotedWeight[msg.sender] - _weight;
        uint256 newNodeWeight = nodeUserVotedWeight[_nodeId][msg.sender] - _weight;

        require(_weight > 0, "zero weight");
        require(newTotalWeight >= 0, "exceeded all voted weight");
        require(newNodeWeight >= 0, "exceeded node voted weight");

        userVotedWeight[msg.sender] = newTotalWeight;
        nodeUserVotedWeight[_nodeId][msg.sender] = newNodeWeight;

        if (nodeUserVotedWeight[_nodeId][msg.sender] == 0) {
            removeUserFromNodeUsers(_nodeId, msg.sender);

            if (nodeUsers[_nodeId].length == 0) {
                removeNodeFromNodes(_nodeId);
                delete nodeUsers[_nodeId];
            }

            uint256 index = userVotedNodesIndexes[msg.sender][_nodeId];
            string memory lastVotedNode = userVotedNodes[msg.sender][userVotedNodes[msg.sender].length - 1];
            userVotedNodes[msg.sender][index] = lastVotedNode;
            userVotedNodesIndexes[msg.sender][lastVotedNode] = index;

            delete userVotedNodesIndexes[msg.sender][_nodeId];
            userVotedNodes[msg.sender].pop();
        }

        emit UnvoteNode(msg.sender, _nodeId, _weight);
    }

    /// @notice removes a node from the node list
    /// @param _nodeId node to remove from list
    function removeNodeFromNodes(string calldata _nodeId) private {
        uint256 index = nodesIndex[_nodeId];

        require(keccak256(abi.encodePacked(nodes[index])) == keccak256(abi.encodePacked(_nodeId)), "incorrect removal of node from list");

        string memory last = nodes[nodes.length - 1];
        nodes[index] = last;
        nodesIndex[last] = index;

        nodes.pop();
        delete nodesIndex[_nodeId];
    }

    /// @notice removes a user from the node user list
    /// @param _user user to remove from list
    function removeUserFromNodeUsers(string calldata _nodeId, address _user) private {
        address[] storage users = nodeUsers[_nodeId];
        uint256 index = nodeUsersIndex[_nodeId][_user];

        require(users[index] == _user, "incorrect removal of user from list");

        address last = users[users.length - 1];
        users[index] = last;
        nodeUsersIndex[_nodeId][last] = index;

        users.pop();
        delete nodeUsersIndex[_nodeId][_user];
    }

    /// @notice retrieves all nodes within a range
    /// @param _from start index (starts from 0)
    /// @param _to end index (inclusive)
    function getNodesRange(uint256 _from, uint256 _to) external view override returns (string[] memory) {
        require(_from <= _to, "from index must be lesser/equal to index");
        require(_to < nodes.length, "to index exceeds total nodes");

        unchecked {
            uint256 size = _to - _from + 1;
            string[] memory nodeList = new string[](size);

            for (uint256 i = 0; i < size; ++i) {
                nodeList[i] = nodes[_from + i];
            }

            return nodeList;
        }
    }

    /// @notice retrieves number of nodes
    function getNodesLength() external view override returns (uint256) {
        return nodes.length;
    }

    /// @notice retrieves all users for a node within a range
    /// @param _from start index (starts from 0)
    /// @param _to end index (inclusive)
    function getNodeUsersRange(string memory _nodeId, uint256 _from, uint256 _to) external view override returns (address[] memory) {
        require(_from <= _to, "from index must be lesser/equal to index");
        require(_to < nodes.length, "to index exceeds total nodes");

        unchecked {
            uint256 size = _to - _from + 1;
            address[] memory userList = new address[](size);
            address[] storage allNodeUsers = nodeUsers[_nodeId];

            for (uint256 i = 0; i < size; ++i) {
                userList[i] = allNodeUsers[_from + i];
            }

            return userList;
        }
    }

    /// @notice retrieves number of users for a node
    function getNodeUsersLength(string calldata _nodeId) external view override returns (uint256) {
        return nodeUsers[_nodeId].length;
    }

    /// @notice retrieves votes over a range of nodes (includes pending veQI)
    /// @param _from start index (starts from 0)
    /// @param _to end index (inclusive)
    function getVotesRange(uint256 _from, uint256 _to) external view override returns (string[] memory, uint256[] memory) {
        require(_from <= _to, "from index must be lesser/equal to index");
        require(_to < nodes.length, "to index exceeds total nodes");

        unchecked {
            uint256 size = _to - _from + 1;
            string[] memory nodeList = new string[](size);
            uint256[] memory voteList = new uint256[](size);

            for (uint256 i; i < size; ++i) {
                uint256 nodeIndex = _from + i;
                nodeList[i] = nodes[nodeIndex];
                voteList[i] = getVotesForNode(nodes[nodeIndex]);
            }

            return (nodeList, voteList);
        }
    }

    /// @notice retrieves votes for a node (includes pending veQI)
    function getVotesForNode(string memory _nodeId) public view override returns (uint256) {
        address[] memory users = nodeUsers[_nodeId];
        uint256 nodeVotes;

        uint256 length = users.length;
        for (uint256 i; i < length;) {
            address user = users[i];

            if (veQi.getStakedQi(user) != 0) {
                uint256 userWeight = nodeUserVotedWeight[_nodeId][user];
                uint256 userVotes = userWeight * veQi.eventualBalanceOf(user) / 10_000;
                nodeVotes = nodeVotes + userVotes;
            }

            unchecked { ++i; }
        }

        return nodeVotes;
    }

    /// @notice get the number of nodes the user has voted for
    function getUserVotesLength() external view override returns (uint256) {
       return userVotedNodes[msg.sender].length;
    }

    /// @notice get a paginated list of nodes and their votes the user has voted for
    function getUserVotesRange(uint256 _from, uint256 _to) external view override returns (string[] memory, uint256[] memory) {
        require(_from <= _to, "from index must be lesser/equal to to index");
        require(_to < userVotedNodes[msg.sender].length, "to index exceeds total voted nodes");

        unchecked {
            uint256 size = _to - _from + 1;
            string[] memory nodeList = new string[](size);
            uint256[] memory voteList = new uint256[](size);

            for (uint256 i; i < size; ++i) {
                string memory nodeId = userVotedNodes[msg.sender][_from + i];
                nodeList[i] = nodeId;
                voteList[i] = nodeUserVotedWeight[nodeId][msg.sender];
            }

            return (nodeList, voteList);
        }
    }
}