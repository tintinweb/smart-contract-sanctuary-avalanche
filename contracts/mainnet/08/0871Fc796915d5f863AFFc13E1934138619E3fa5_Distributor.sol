// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IDistributor.sol";
import "./IERC20.sol";

contract Distributor is IDistributor {
  uint256 internal MAX_INT = 2**256 - 1;

  address public _owner;
  address internal ADDRESS_ETH = address(0);

  mapping(address => mapping(address => uint256)) internal _balanceToken;
  mapping(address => uint256) internal _balanceETH;

  mapping(address => uint256) internal _undistributedToken;
  uint256 internal _undistributedETH;

  mapping(address => mapping(address => bool)) internal _ifTokenOwned; // for claimeverything shenanigans
  mapping(address => address[]) internal _tokensOwned;

  constructor() {
    _owner = msg.sender;
  }

  // MISC

  function addToArray(address account, address tokenAddress) internal {
    if (_ifTokenOwned[account][tokenAddress] == false) {
      _ifTokenOwned[account][tokenAddress] = true;
      _tokensOwned[account].push(tokenAddress);
    }
  }

  modifier onlyOwner() {
    require(msg.sender == _owner, "not owner :(");
    _;
  }

  modifier nonZero(address _address) {
    require(_address != address(0), "non-existent :(");
    _;
  }

  bool internal lock;

  modifier noReentrant() {
    require(!lock, "yo hackin' me or smt? :(");
    lock = true;
    _;
    lock = false;
  }

  // SCARY FUNCTIONS

  function transferOwner(address newOwner) external onlyOwner nonZero(newOwner) returns (bool) {
    _owner = newOwner;

    return true;
  }

  // VIEW-ONLY FUNCTIONS

  function balanceToken(address tokenAddress, address account)
    external
    view
    nonZero(account)
    returns (uint256)
  {
    return _balanceToken[account][tokenAddress];
  }

  function balanceETH(address account) external view nonZero(account) returns (uint256) {
    return _balanceETH[account];
  }

  function undistributedToken(address tokenAddress) external view returns (uint256) {
    return _undistributedToken[tokenAddress];
  }

  function undistributedETH() external view returns (uint256) {
    return _undistributedETH;
  }

  // DEPOSIT FUNCTIONS

  function depositToken(address tokenAddress, uint256 amount) external {
    require(
      IERC20(tokenAddress).balanceOf(msg.sender) >= amount &&
        IERC20(tokenAddress).allowance(msg.sender, address(this)) >= amount,
      "yo lyin' :("
    );

    IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
    _undistributedToken[tokenAddress] += amount;

    emit Deposited(tokenAddress, msg.sender, amount);
  }

  function depositETH() external payable {
    require(msg.value != 0, "why so cheap :(");

    _undistributedETH += msg.value;

    emit Deposited(address(0), msg.sender, msg.value);
  }

  // APPROVE FUNCTIONS

  function approveToken(
    address tokenAddress,
    address to,
    uint256 amount
  ) external onlyOwner nonZero(to) {
    require(_undistributedToken[tokenAddress] >= amount, "too poor:(");

    addToArray(to, tokenAddress);

    _balanceToken[to][tokenAddress] += amount;
    _undistributedToken[tokenAddress] -= amount;

    emit Deposited(tokenAddress, to, amount);
  }

  function approveETH(address to, uint256 amount) external onlyOwner nonZero(to) {
    require(_undistributedETH >= amount, "too poor:(");

    _balanceETH[to] += amount;
    _undistributedETH -= amount;

    emit Deposited(address(0), to, amount);
  }

  // CLAIM FUNCTIONS

  function claimToken(address tokenAddress, uint256 amount) external {
    require(_balanceToken[msg.sender][tokenAddress] >= amount, "too poor :(");

    actuallyClaimingToken(tokenAddress, msg.sender, amount);
  }

  function claimETH(uint256 amount) external {
    require(_balanceETH[msg.sender] >= amount, "too poor :(");

    actuallyClaimingETH(msg.sender, amount);
  }

  function claimAllToken(address tokenAddress) external {
    if (_balanceToken[msg.sender][tokenAddress] > 0) {
      actuallyClaimingToken(tokenAddress, msg.sender, MAX_INT);
    }
  }

  function claimAllETH() external {
    if (_balanceETH[msg.sender] > 0) {
      actuallyClaimingETH(msg.sender, MAX_INT);
    }
  }

  function claimEverything() external {
    for (uint256 i = 0; i < _tokensOwned[msg.sender].length; i++) {
      address tkAddress = _tokensOwned[msg.sender][i];
      if (_balanceToken[msg.sender][tkAddress] > 0) {
        actuallyClaimingToken(tkAddress, msg.sender, MAX_INT);
      }
    }
    if (_balanceETH[msg.sender] > 0) {
      actuallyClaimingETH(msg.sender, MAX_INT);
    }
  }

  // HELPER FUNCTIONS

  function actuallyClaimingToken(
    address tokenAddress,
    address account,
    uint256 amount
  ) internal noReentrant {
    //just for sure
    if (amount > _balanceToken[account][tokenAddress])
      amount = _balanceToken[account][tokenAddress]; // controllably unexpected

    _balanceToken[account][tokenAddress] -= amount;
    IERC20(tokenAddress).transfer(account, amount);

    emit Claimed(tokenAddress, account, amount);
  }

  function actuallyClaimingETH(address account, uint256 amount) internal noReentrant {
    if (amount > _balanceETH[account]) amount = _balanceETH[account];

    _balanceETH[account] -= amount;
    payable(account).transfer(amount);

    emit Claimed(address(0), account, amount);
  }

  // REAL MEN USES THESE

  function gamble(uint256 luckyNumber) external payable noReentrant returns (string memory) {
    if (
      uint256(
        keccak256(
          abi.encodePacked(block.timestamp, msg.sender, "dude you are totally gonna win this")
        )
      ) != luckyNumber
    ) {
      payable(_owner).transfer(msg.value);
      return "yo lost :(";
    } else {
      if (_undistributedETH < msg.value) {
        payable(msg.sender).transfer(msg.value + _undistributedETH);
        _undistributedETH = 0;
      } else {
        payable(msg.sender).transfer(msg.value * 2);
        _undistributedETH -= msg.value;
      }
      return "i lost :(";
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.11;

interface IDistributor {
  function balanceToken(address tokenAddress, address account) external view returns (uint256);

  function balanceETH(address account) external view returns (uint256);

  function undistributedToken(address tokenAddress) external view returns (uint256);

  function undistributedETH() external view returns (uint256);

  function depositToken(address tokenAddress, uint256 amount) external;

  function depositETH() external payable;

  function approveToken(
    address tokenAddress,
    address to,
    uint256 amount
  ) external;

  function approveETH(address to, uint256 amount) external;

  function claimToken(address tokenAddress, uint256 amount) external;

  function claimETH(uint256 amount) external;

  function claimAllToken(address tokenAddress) external;

  function claimAllETH() external;

  function claimEverything() external;

  event Deposited(address indexed tokenAddress, address indexed from, uint256 value);
  event Approved(address indexed tokenAddress, address indexed to, uint256 value);
  event Claimed(address indexed tokenAddress, address indexed to, uint256 value);

  function gamble(uint256 luckyNumber) external payable returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.11;

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
   * @dev Moves `amount` tokens from the caller's account to `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address to, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `from` to `to` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
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