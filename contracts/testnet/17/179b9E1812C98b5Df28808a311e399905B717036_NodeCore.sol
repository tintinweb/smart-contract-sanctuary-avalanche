//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import '../common/IERC20.sol';
import "./INodeCore.sol";
import "./IBoostNFT.sol";
// import "hardhat/console.sol";

contract NodeCore is Initializable {
  IBoostNFT public boostNFT;

  Tier[] private tierArr;
  mapping(string => uint8) public tierMap;
  uint8 public tierTotal;
  Node[] private nodesTotal;
  mapping(address => uint256[]) private nodesOfUser;
  uint32 public countTotal;
  mapping(address => uint32) public countOfUser;
  mapping(string => uint32) public countOfTier;
  uint256 public rewardsTotal;
  mapping(address => uint256) public rewardsOfUser;

  uint32 public maxCountOfUser; // 0-Infinite

  address public feeTokenAddress;
  bool public canNodeTransfer;

  address public owner;  

  mapping(address => bool) public blacklist;
  string[] private airdrops;
  mapping(string => bytes32) public merkleRoot;
  mapping(bytes32 => bool) public airdropSupplied;

  mapping(address => uint256) public unclaimed;
  address public minter;
  address public operator;
  
  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  modifier onlyOperator() {
    require(operator == msg.sender || address(this) == msg.sender, "Caller is not the operator");
    _;
  }

  function initialize() public initializer {
    owner = msg.sender;

    addTier('default', 100 ether, 0.12 ether, 1 days, 0, 0);

    maxCountOfUser = 0; // 0-Infinite
    canNodeTransfer = true;
  }

  function transferOwnership(address _owner) public onlyOwner {
    owner = _owner;
  }

  function setOperator(address _operator) public onlyOwner {
    operator = _operator;
  }

  function bindBooster(address _boostNFT) public onlyOwner {
    boostNFT = IBoostNFT(_boostNFT);
  }

  function tiers() public view returns (Tier[] memory) {
    Tier[] memory tiersActive = new Tier[](tierTotal);
    uint8 j = 0;
    for (uint8 i = 0; i < tierArr.length; i++) {
      Tier storage tier = tierArr[i];
      if (tierMap[tier.name] > 0) tiersActive[j++] = tier;
    }
    return tiersActive;
  }

  function addTier(
    string memory name,
    uint256 price,
    uint256 rewardsPerTime,
    uint32 claimInterval,
    uint256 maintenanceFee,
    uint32 maxPurchase
  ) public onlyOwner {
    require(price > 0, "Tier's price has to be positive.");
    require(rewardsPerTime > 0, "Tier's rewards has to be positive.");
    require(claimInterval > 0, "Tier's claim interval has to be positive.");
    tierArr.push(
      Tier({
	      id: uint8(tierArr.length),
        name: name,
        price: price,
        rewardsPerTime: rewardsPerTime,
        claimInterval: claimInterval,
        maintenanceFee: maintenanceFee,
        maxPurchase: maxPurchase
      })
    );
    tierMap[name] = uint8(tierArr.length);
    tierTotal++;
  }

  function updateTier(
    string memory tierName,
    string memory name,
    uint256 price,
    uint256 rewardsPerTime,
    uint32 claimInterval,
    uint256 maintenanceFee,
    uint32 maxPurchase
  ) public onlyOwner {
    uint8 tierId = tierMap[tierName];
    require(tierId > 0, "Tier's name is incorrect.");
    require(price > 0, "Tier's price has to be positive.");
    require(rewardsPerTime > 0, "Tier's rewards has to be positive.");
    Tier storage tier = tierArr[tierId - 1];
    tier.name = name;
    tier.price = price;
    tier.rewardsPerTime = rewardsPerTime;
    tier.claimInterval = claimInterval;
    tier.maintenanceFee = maintenanceFee;
    tier.maxPurchase = maxPurchase;
    tierMap[tierName] = 0;
    tierMap[name] = tierId;
  }

  function setTierId(string memory name, uint8 id) public onlyOwner {
    tierMap[name] = id;
  }

  function removeTier(string memory tierName) public onlyOwner {
    require(tierMap[tierName] > 0, 'Tier was already removed.');
    tierMap[tierName] = 0;
    tierTotal--;
  }

  function maxNodeIndex() public view returns (uint32) {
    return uint32(nodesTotal.length);
  }

  function setMaxCountOfUser(uint32 _count) public onlyOwner {
    maxCountOfUser = _count;
  }

  function tierOf(string memory _tier) public view returns (Tier memory) {
    uint8 tierId = tierMap[_tier];
    return tierArr[tierId-1];
  }

  function tierAt(uint8 _index) public view returns (Tier memory) {
    return tierArr[_index];
  }

  function reward(address _account) public onlyOperator returns (uint256) {
    uint256 claimableAmount = 0;
    Node[] memory nodes = filter(_account);
    for(uint32 i = 0;i<nodes.length;i++) {
      Node memory node = nodes[i];
      uint256 multiplier = 1 ether;
      if(address(boostNFT)!=address(0)) multiplier = boostNFT.getMultiplier(_account, node.claimedTime, block.timestamp); 
      Tier memory tier = tierArr[node.tierIndex];
      claimableAmount += uint256(block.timestamp - node.claimedTime)
        * tier.rewardsPerTime
        * multiplier
        / 1 ether
        / tier.claimInterval;
      update(node.id, _account, uint32(block.timestamp), 0);
    }
    if(claimableAmount > 0) {
      rewardsOfUser[_account] += claimableAmount;
      rewardsTotal += claimableAmount;
      unclaimed[_account] += claimableAmount;
    }
    return unclaimed[_account];
  }

  function claimable(address _account, bool _includeUnclaimed) public view returns (uint256) {
    uint256 claimableAmount = _includeUnclaimed ? unclaimed[_account] : 0;
    Node[] memory nodes = filter(_account);
    for(uint32 i = 0;i<nodes.length;i++) {
      Node memory node = nodes[i];
      uint256 multiplier = 1 ether;
      if(address(boostNFT)!=address(0)) multiplier = boostNFT.getMultiplier(_account, node.claimedTime, block.timestamp); 
      Tier memory tier = tierArr[node.tierIndex];
      claimableAmount += uint256(block.timestamp - node.claimedTime)
        * tier.rewardsPerTime
        * multiplier
        / 1 ether
        / tier.claimInterval;
    }
    return claimableAmount;
  }

  function claim(address _account) public onlyOperator returns (uint256) {
    return claim(_account, 0);
  }

  function claim(address _account, uint256 _amount) public onlyOperator returns (uint256) {
    reward(_account);
    uint256 claimableAmount = unclaimed[_account];
    require(claimableAmount > 0, 'No claimable tokens.');
    if(_amount==0) {
      unclaimed[_account] = 0;
      return claimableAmount;
    }
    require(claimableAmount >= _amount, 'Insufficient claimable tokens.');
    unclaimed[_account] -= _amount;
    return _amount;
  }

  function insert(
    string memory _tier,
    address _account,
    string memory _title,
    int32 _limitedTimeOffset
  ) public onlyOperator {
    if(maxCountOfUser > 0)
      require(countOfUser[_account]<maxCountOfUser, "Exceed of max count");
    uint8 tierId = tierMap[_tier];
    Tier storage tier = tierArr[tierId-1];
    if(tier.maxPurchase > 0)
      require(count(_account,_tier)<tier.maxPurchase, "Exceed of max count");
    uint32 nodeId = uint32(nodesTotal.length);
    nodesTotal.push(
      Node({
        id: nodeId,
        tierIndex: tierId - 1,
        title: _title,
        owner: _account,
        multiplier: 1 ether,
        createdTime: uint32(block.timestamp),
        claimedTime: uint32(block.timestamp),
        limitedTime: uint32(uint256(int(block.timestamp)+_limitedTimeOffset))
      })
    );
    uint256[] storage nodeIndice = nodesOfUser[_account];
    nodeIndice.push(nodeId + 1);
    countTotal++;
    countOfTier[_tier]++;
    countOfUser[_account]++;
  }

  function hide(uint32 _id) public onlyOperator {
    Node storage node = nodesTotal[_id];
    uint256[] storage nodeIndice = nodesOfUser[node.owner];
    for(uint32 i = 0;i<nodeIndice.length;i++) {
      if(nodeIndice[i]==node.id+1) {
        nodeIndice[i] = 0;
        break;
      }
    }
  }

  function update(
    uint32 _id,
    address _account,
    uint32 _claimedTime,
    uint32 _limitedTime
  ) public onlyOperator {
    Node storage node = nodesTotal[_id];
    if(_claimedTime>0 && node.claimedTime!=_claimedTime) node.claimedTime = _claimedTime;
    if(_limitedTime>0 && node.limitedTime!=_limitedTime) node.limitedTime = _limitedTime;
    if(_account!=address(0) && node.owner!=_account) {
      if(maxCountOfUser > 0)
        require(countOfUser[_account]<maxCountOfUser, "Exceed of max count");
      Tier storage tier = tierArr[node.tierIndex];
      if(tier.maxPurchase > 0)
        require(count(_account,tier.name)<tier.maxPurchase, "Exceed of max count");
      countOfUser[node.owner]--;
      countOfUser[_account]++;
      hide(_id);
      node.owner = _account;
      nodesOfUser[_account].push(_id + 1);
    }
  }

  function burn(uint32 _id) public onlyOperator {
    Node storage node = nodesTotal[_id];
    hide(_id);
    Tier storage tier = tierArr[node.tierIndex];
    countOfUser[node.owner]--;
    countTotal--;
    countOfTier[tier.name]--;
    node.owner = address(0);
  }

  function select(uint32 _id) public view returns (Node memory) {
    return nodesTotal[_id];
  }

  function count() public view returns (uint32) {
    return countTotal;
  }

  function count(address _account) public view returns (uint32) {
    return countOfUser[_account];
  }

  function count(string memory _tier) public view returns (uint32) {
    return countOfTier[_tier];
  }
  
  function count(address _account, string memory _tier) public view returns (uint32) {
    return count(_account, tierMap[_tier]);
  }

  function count(address _account, uint8 _tierId) public view returns (uint32) {
    uint256 total = nodesOfUser[_account].length;
    if(_account==address(0)) total = nodesTotal.length;
    uint32 length = 0;
    for(uint32 i = 0;i<total;i++) {
      uint256 index = i;
      if(_account!=address(0)) {
        if(nodesOfUser[_account][i]==0) continue;
        index = nodesOfUser[_account][i] - 1;
      }
      if(nodesTotal[index].owner!=_account) continue;
      if(_tierId!=0 && _tierId-1!=nodesTotal[index].tierIndex) continue;
      length++;
    }
    return length;
  }

  function filter(address _account) public view returns (Node[] memory) {
    return filter(_account,'',0);
  }

  function filter(address _account, string memory _tier) public view returns (Node[] memory) {
    return filter(_account,_tier,0);
  }

  function filter(address _account, string memory _tier, uint32 _count) public view returns (Node[] memory) {
    uint32 length = count(_account, _tier);
    if(length==0) return new Node[](0);
    Node[] memory nodes = new Node[](length);
    uint256 total = nodesOfUser[_account].length;
    uint8 tierId = tierMap[_tier];
    if(_account==address(0)) total = nodesTotal.length;
    uint32 j = 0;
    for(uint32 i = 0;i<total;i++) {
      uint256 index = i;
      if(_account!=address(0)) {
        if(nodesOfUser[_account][i]==0) continue;
        index = nodesOfUser[_account][i] - 1;
      }
      if(nodesTotal[index].owner!=_account) continue;
      if(tierId!=0 && tierId-1!=nodesTotal[index].tierIndex) continue;
      nodes[j++] = nodesTotal[index];
      if(_count!=0 && j==_count) break;
    }
    return nodes;
  }

  function outdated() public view returns (Node[] memory) {
    uint32 length = 0;
    uint256 total = nodesTotal.length;
    for(uint32 i = 0;i<total;i++) {
      if(nodesTotal[i].owner==address(0)) continue;
      if(nodesTotal[i].limitedTime>block.timestamp) continue;
      length++;
    }
    if(length==0) return new Node[](0);
    Node[] memory nodes = new Node[](length);
    uint32 j = 0;
    for(uint32 i = 0;i<total;i++) {
      if(nodesTotal[i].owner==address(0)) continue;
      if(nodesTotal[i].limitedTime>block.timestamp) continue;
      nodes[j++] = nodesTotal[i];
    }
    return nodes;
  }

  function withdraw(address _to) public onlyOwner {
    payable(_to).transfer(address(this).balance);
  }
  
  function withdraw(address _token, address _to) external onlyOwner() {
    IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Tier {
  uint8 id;
  string name;
  uint256 price;
  uint256 rewardsPerTime;
  uint32 claimInterval;
  uint256 maintenanceFee;
  uint32 maxPurchase;
}

struct Node {
  uint32 id;
  uint8 tierIndex;
  string title;
  address owner;
  uint32 createdTime;
  uint32 claimedTime;
  uint32 limitedTime;
  uint256 multiplier;
}

interface INodeCore {
  function insert(
    string memory _tier,
    address _account,
    string memory _title,
    int32 limitedTimeOffset
  ) external;

  function hide(uint32 _id) external;

  function burn(uint32 _id) external;

  function select(uint32 _id) external view returns (Node memory);

  function update(
    uint32 _id,
    address _account,
    uint32 _claimedTime,
    uint32 _limitedTime
  ) external;

  function count() external view returns (uint32);

  function count(address _account) external view returns (uint32);
  
  function count(string memory _tier) external view returns (uint32);
  
  function count(address _account, string memory _tier) external view returns (uint32);

  function count(address _account, uint8 _tier) external view returns (uint32);

  function filter(address _account) external view returns (Node[] memory);

  function filter(address _account, string memory _tier) external view returns (Node[] memory);

  function filter(address _account, string memory _tier, uint32 _count) external view returns (Node[] memory);

  function outdated() external view returns (Node[] memory);

  function tierOf(string memory _tier) external view returns (Tier memory);

  function tierAt(uint8 _index) external view returns (Tier memory);

  function reward(address _account) external returns (uint256);

  function claim(address _account) external returns (uint256);

  function claim(address _account, uint256 _amount) external returns (uint256);

  function claimable(address _account, bool _includeUnclaimed) external view returns (uint256);

  function rewardsTotal() external view returns (uint256);

  function rewardsOfUser(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBoostNFT {
    function getMultiplier(address, uint256, uint256) external view returns (uint256);
    function lastMultiplier(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
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