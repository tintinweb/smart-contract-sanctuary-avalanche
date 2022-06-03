// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

contract ERC20 is IERC20, IERC20Metadata {
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  mapping(address => uint256) private ownership;
  mapping(address => mapping(address => uint256)) private allowances;

  constructor(
    uint256 initialSupply,
    string memory inputName,
    string memory inputSymbol,
    uint8 inputDecimals
  ) {
    _totalSupply = initialSupply;
    ownership[msg.sender] = initialSupply;
    _name = inputName;
    _symbol = inputSymbol;
    _decimals = inputDecimals;
  }

  //view functions

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return ownership[account];
  }

  function allowance(address owner, address spender) external view returns (uint256) {
    return allowances[owner][spender];
  }

  //utility functions

  function transfer(address to, uint256 amount) external returns (bool) {
    require(ownership[msg.sender] >= amount, "Insufficient funds");
    require(to != address(0), "Sending to 0 address");
    ownership[msg.sender] -= amount;
    ownership[to] += amount;
    emit Transfer(msg.sender, to, amount);
    return true;
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    require(spender != address(0), "Spender cannot be 0 address");
    allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool) {
    require(allowances[from][msg.sender] >= amount, "Receiver not approved");
    require(ownership[from] >= amount, "Insufficient balance");
    require(to != address(0), "Cannot transfer to 0 address");
    require(from != address(0), "Cannot transfer from 0 address");
    ownership[from] -= amount;
    ownership[to] += amount;
    allowances[from][msg.sender] -= amount;
    emit Transfer(from, to, amount);
    return true;
  }

  function mint(address to, uint256 amount) public {
    ownership[to] += amount;
    _totalSupply += amount;
  }

  function burn(address from, uint256 amount) public {
    ownership[from] -= amount;
    _totalSupply -= amount;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}