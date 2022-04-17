// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Authorizable.sol";
import "./Taxable02.sol";
import "./interfaces/INodeController04.sol";
import "./interfaces/ILiquidityController.sol";
import "./interfaces/IReferralController.sol";

pragma solidity ^0.8.4;

contract VaporController04 is Pausable, Authorizable, Taxable02 {
  struct Pools {
    address team;
    address rewards;
    address tax;
  }
  Pools public pools;

  address public immutable deadWallet =
    0x000000000000000000000000000000000000dEaD;
  uint256 public totalClaimed;
  uint256 public maxNodesPerWallet = 5;

  INodeController04 private nodeController;
  ILiquidityController private liquidityController;
  IReferralController private referralController;
  IERC20 private token;

  mapping(address => bool) public isBlacklisted;

  event Cashout(address indexed account, uint256 amount, uint256[] ids);
  event Compound(address indexed account, uint256 amount, uint256[] ids);

  constructor(address[] memory _addresses, address[] memory _pools) {
    require(_addresses.length == 4, "C_1");
    nodeController = INodeController04(_addresses[0]);
    liquidityController = ILiquidityController(_addresses[1]);
    referralController = IReferralController(_addresses[2]);
    token = IERC20(_addresses[3]);

    require(_pools.length == 3, "C_2");

    pools.team = _pools[0];
    pools.rewards = _pools[1];
    pools.tax = _pools[2];
  }

  function createNodeWithTokens(
    string memory _name,
    uint256 _amount,
    address _sponsor
  ) external whenNotPaused {
    address sender = _msgSender();
    uint256 minPrice = nodeController.getMinTokensRequired();
    require(sender != address(0), "Wrong sender");
    require(!isBlacklisted[sender], "Blacklisted");
    require(token.balanceOf(sender) >= _amount, "Insufficient balance");
    require(_amount >= minPrice, "Invalid amount");
    require(nodeController.getNodesCount(sender) <= 5, "Max nodes reached");

    liquidityController.process();

    token.transferFrom(sender, address(liquidityController), _amount);
    nodeController.createNode(sender, _name, _amount);

    if (_sponsor != address(0)) {
      require(nodeController.getNodesCount(_sponsor) > 0, "Invalid sponsor");
      referralController.generateCommission(sender, _sponsor, _amount);
    }
  }

  function claim(uint256[] memory _ids, bool isAVAX)
    external
    payable
    whenNotPaused
  {
    address sender = _msgSender();
    require(sender != address(0), "Wrong sender");
    require(!isBlacklisted[sender], "Blacklisted");

    INodeController04.NodeEntity[] memory nodes = nodeController.getNodes(
      sender,
      _ids
    );

    uint256 length = nodes.length;
    require(length > 0, "Invalid ids");

    uint256 taxAmount;
    uint256 burnAmount;
    uint256 rewardsAmount;
    uint256 rewardsAfterTax;

    for (uint256 i; i < length; ++i) {
      INodeController04.NodeEntity memory node = nodes[i];
      nodeController.claimNode(sender, _ids[i]);

      (, , uint256 totalRewards) = nodeController.calculateNodeRewards(
        node.lastClaimTime,
        node.lastCompoundTime,
        node.amount
      );
      (uint256 burnTax, uint256 claimTax) = getClaimTaxes(node.amount);
      taxAmount += (claimTax * totalRewards) / 100;
      burnAmount += (burnTax * totalRewards) / 100;
      rewardsAmount += totalRewards;
    }

    if (isAVAX) {
      require(isQuoteValid(taxAmount, msg.value), "Expired quote");
      (bool success, ) = payable(pools.tax).call{ value: msg.value }("");
      require(success, "Failed to send Ether");
      rewardsAfterTax = rewardsAmount - burnAmount;
    } else {
      rewardsAfterTax = rewardsAmount - (taxAmount * 2) - burnAmount;
    }

    // burn
    token.transferFrom(pools.rewards, deadWallet, burnAmount);
    // rewards
    token.transferFrom(pools.rewards, sender, rewardsAfterTax);

    emit Cashout(sender, rewardsAfterTax, _ids);
  }

  function compound(uint256[] memory _ids) public whenNotPaused {
    address sender = _msgSender();
    require(sender != address(0), "Wrong sender");
    require(!isBlacklisted[sender], "Blacklisted");

    INodeController04.NodeEntity[] memory nodes = nodeController.getNodes(
      sender,
      _ids
    );

    uint256 length = nodes.length;
    require(length > 0, "Invalid ids");

    uint256 taxAmount;
    uint256 burnAmount;
    uint256 rewardsAmount;
    for (uint256 i = 0; i < length; ++i) {
      INodeController04.NodeEntity memory node = nodes[i];
      (uint256 burnTax, uint256 compoundTax) = getCompoundTaxes(node.amount);
      uint256 rewards = nodeController.compoundNode(
        sender,
        _ids[i],
        burnTax + compoundTax
      );
      taxAmount += (compoundTax * rewards) / 100;
      burnAmount += (burnTax * rewards) / 100;
      rewardsAmount += rewards;
    }
    // burn
    token.transferFrom(pools.rewards, deadWallet, burnAmount);
    // rewards
    uint256 rewardsAfterTax = rewardsAmount - taxAmount - burnAmount;
    token.transferFrom(
      pools.rewards,
      address(liquidityController),
      rewardsAfterTax
    );

    emit Compound(sender, rewardsAfterTax, _ids);
  }

  function renameNode(uint256 _nodeIndex, string calldata _name)
    external
    whenNotPaused
  {
    address sender = _msgSender();
    require(!isBlacklisted[sender], "Blacklisted");

    nodeController.renameNode(sender, _nodeIndex, _name);
  }

  function increaseNodeAmount(uint256 _nodeIndex, uint256 _amount)
    external
    whenNotPaused
  {
    address sender = _msgSender();
    require(!isBlacklisted[sender], "Blacklisted");
    require(token.balanceOf(sender) >= _amount, "Insufficient balance");
    token.transferFrom(sender, address(liquidityController), _amount);

    // Auto-compound node
    uint256[] memory ids = new uint256[](1);
    ids[0] = _nodeIndex;
    compound(ids);

    nodeController.increaseNodeAmount(sender, _nodeIndex, _amount);
  }

  function mergeNodes(uint256 destIndex, uint256 srcIndex)
    external
    whenNotPaused
  {
    address sender = _msgSender();
    require(!isBlacklisted[sender], "Blacklisted");
    uint256 mergeFee = getMergeTax();
    require(token.balanceOf(sender) >= mergeFee, "Insufficient balance");

    if (mergeFee > 0) {
      token.transferFrom(sender, deadWallet, mergeFee);
    }

    // Auto-compound nodes
    uint256[] memory ids = new uint256[](2);
    ids[0] = srcIndex;
    ids[1] = destIndex;
    compound(ids);

    nodeController.mergeNodes(sender, destIndex, srcIndex);
  }

  function getClaimTaxQuote(uint256[] calldata _ids)
    external
    view
    returns (uint256)
  {
    address sender = _msgSender();
    require(sender != address(0), "Invalid sender");
    require(!isBlacklisted[sender], "Blacklisted");
    INodeController04.NodeEntity[] memory nodes = nodeController.getNodes(
      sender,
      _ids
    );
    uint256 length = nodes.length;
    require(length > 0, "Invalid ids");

    uint256 taxAmount;
    for (uint256 i; i < length; ++i) {
      INodeController04.NodeEntity memory node = nodes[i];
      (, , uint256 totalRewards) = nodeController.calculateNodeRewards(
        node.lastClaimTime,
        node.lastCompoundTime,
        node.amount
      );
      (, uint256 claimTax) = getClaimTaxes(node.amount);
      taxAmount += (claimTax * totalRewards) / 100;
    }

    return getClaimQuote(taxAmount); // AVAX
  }

  // Getters and Setters
  function setNodeController(address _nodeController) external onlyAuthorized {
    nodeController = INodeController04(_nodeController);
  }

  function setMaxNodesPerWallet(uint256 _maxNodesPerWallet) external onlyOwner {
    maxNodesPerWallet = _maxNodesPerWallet;
  }

  // Firewall methods

  function pause() external onlyAuthorized {
    _pause();
  }

  function unpause() external onlyAuthorized {
    _unpause();
  }

  function blacklistAddress(address _address, bool value)
    external
    onlyAuthorized
  {
    isBlacklisted[_address] = value;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IJoePair.sol";
import "./interfaces/IJoeRouter02.sol";

pragma solidity ^0.8.4;

contract Taxable02 is Ownable {
  // REGULAR FEES
  uint256 private merge = 10 * 10**18;
  uint256 private burn = 1;
  uint256 private claim = 9;
  uint256 private quoteSlippage = 5;

  // COMPOUND TAX
  uint256[] private compoundTiers = [5000, 50000, 500000];
  uint256[][] private compoundTiersTax = [[2, 3], [2, 5], [2, 7], [2, 10]]; // [[burned, rewardPool], ...]

  // CLAIM TAX
  IJoePair private joePair;
  IJoeRouter02 private joeRouter;
  uint256[] private claimTiers = [5000, 50000, 500000];
  uint256[][] private claimTiersTax = [[1, 9], [1, 10], [1, 11], [2, 11]]; // [[burned, rewardPool], ...]

  // GETTER

  function getClaimTaxes(uint256 nodeAmount)
    internal
    view
    returns (uint256, uint256)
  {
    if (nodeAmount < claimTiers[0]) {
      return (claimTiersTax[0][0], claimTiersTax[0][1]);
    }
    if (nodeAmount < claimTiers[1]) {
      return (claimTiersTax[1][0], claimTiersTax[1][1]);
    }
    if (nodeAmount < claimTiers[2]) {
      return (claimTiersTax[2][0], claimTiersTax[2][1]);
    }

    return (claimTiersTax[3][0], claimTiersTax[3][1]);
  }

  function getCompoundTaxes(uint256 nodeAmount)
    internal
    view
    returns (uint256, uint256)
  {
    if (nodeAmount < compoundTiers[0]) {
      return (compoundTiersTax[0][0], compoundTiersTax[0][1]);
    }
    if (nodeAmount < compoundTiers[1]) {
      return (compoundTiersTax[1][0], compoundTiersTax[1][1]);
    }
    if (nodeAmount < compoundTiers[2]) {
      return (compoundTiersTax[2][0], compoundTiersTax[2][1]);
    }

    return (compoundTiersTax[3][0], compoundTiersTax[3][1]);
  }

  function getMergeTax() internal view returns (uint256) {
    return merge;
  }

  function getBurnTax() internal view returns (uint256) {
    return burn;
  }

  function getClaimQuote(uint256 amount) public view returns (uint256) {
    address[] memory addresses;
    addresses[0] = joePair.token0();
    addresses[1] = joePair.token1();
    uint256[] memory amounts = joeRouter.getAmountsOut(amount, addresses);

    return amounts[1];
  }

  function isQuoteValid(uint256 taxAmout, uint256 paidAmount)
    internal
    view
    returns (bool)
  {
    uint256 quote = getClaimQuote(taxAmout);

    return
      paidAmount >= quote ||
      quote - ((quote * quoteSlippage) / 10000) >= paidAmount;
  }

  // SETTERS

  function setClaimTax(uint256 _claim) external onlyOwner {
    require(_claim > 0, "Invalid");
    claim = _claim;
  }

  function setCompoundTaxes(
    uint256[] memory _compoundTiers,
    uint256[][] memory _compoundTiersTax
  ) external onlyOwner {
    require(
      _compoundTiers.length == 3 && _compoundTiersTax.length == 4,
      "Invalid"
    );

    compoundTiers = _compoundTiers;
    compoundTiersTax = _compoundTiersTax;
  }

  function setMergeTax(uint256 _merge) external onlyOwner {
    require(_merge > 0, "Invalid");
    merge = _merge;
  }

  function setBurnTax(uint256 _burn) external onlyOwner {
    require(_burn > 0, "Invalid");
    burn = _burn;
  }

  function setJoePair(address _pair) external onlyOwner {
    require(_pair != address(0), "Invalid");
    joePair = IJoePair(_pair);
  }

  function setJoeRouter(address _router) external onlyOwner {
    require(_router != address(0), "Invalid");
    joeRouter = IJoeRouter02(_router);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INodeController04 {
  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 lastCompoundTime;
    uint256 amount;
    bool deleted;
  }

  function getMinTokensRequired() external view returns (uint256);

  function getNodesCount(address _account) external view returns (uint256);

  function createNode(
    address _account,
    string memory _name,
    uint256 _amount
  ) external;

  function claimNode(address _account, uint256 _nodeIndex) external;

  function compoundNode(
    address _account,
    uint256 _nodeIndex,
    uint256 _fee
  ) external returns (uint256);

  function renameNode(
    address _account,
    uint256 _nodeIndex,
    string memory _name
  ) external;

  function increaseNodeAmount(
    address _account,
    uint256 _nodeIndex,
    uint256 _amount
  ) external;

  function getNodeRewards(address _account, uint256 _nodeIndex)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function getAllNodesRewards(address _account) external view returns (uint256);

  function getNode(address _account, uint256 _nodeIndex)
    external
    view
    returns (NodeEntity memory);

  function getAllNodes(address _account)
    external
    view
    returns (NodeEntity[] memory);

  function getNodes(address _account, uint256[] calldata _ids)
    external
    view
    returns (NodeEntity[] memory);

  function calculateNodeRewards(
    uint256 _lastClaimTime,
    uint256 _lastCompoundTime,
    uint256 _amount
  )
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function mergeNodes(
    address _account,
    uint256 _destIndex,
    uint256 _srcIndex
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILiquidityController {
  function process() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IReferralController {
  function generateCommission(
    address _referral,
    address _sponsor,
    uint256 _amount
  ) external;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoePair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}