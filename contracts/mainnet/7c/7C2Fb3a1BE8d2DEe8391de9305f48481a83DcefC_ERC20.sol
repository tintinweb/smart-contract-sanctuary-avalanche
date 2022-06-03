// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20Metadata.sol";

contract ERC20 is IERC20Metadata {

  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint private _totalSupply;
  address public contractOwner;
  mapping(address=>uint) private balance;
  mapping(address=>mapping(address=>uint)) private allowanceAmount;  // allowanceAmount[owner][spender] = amount possible

  constructor (string memory name, string memory symbol, uint8 decimals, uint totalSupply) 
  {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    _totalSupply = totalSupply;  
    contractOwner = msg.sender;  
    balance[contractOwner] = totalSupply;
  }

  function name() external view returns (string memory)
  {
    return _name;
  }

  function symbol() external view returns (string memory)
  {
    return _symbol;
  }

  function decimals() external view returns (uint8){
    return _decimals;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return balance[account];
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    _transfer(msg.sender, to, amount);
    return true;
  }

  function allowance(address owner, address spender) external view returns (uint256) {    
    require(owner!=address(0), "invalid owner");
    require(spender!=address(0), "invalid spender");
    return allowanceAmount[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    require(spender!=address(0), "invalid spender");
    allowanceAmount[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool) {
    
    require(allowanceAmount[from][msg.sender] >= amount, "exceed the amount allowed");
    _transfer(from, to, amount);
    allowanceAmount[from][msg.sender] -= amount;   

    return true;
  }

  function _transfer(address from, address to, uint amount) internal 
  {
    require(from!=address(0), "invalid sender");
    require(to!=address(0), "invalid receiver");
    require(balance[from] >= amount, "not enough money from the owner");

    balance[from] -= amount;
    balance[to] += amount;  // Hope no overflow here! Should depend on the designer

    emit Transfer(from, to, amount);
  }

  fallback () external payable 
  {
    revert("No money here");
  }
}

pragma solidity ^0.8.11;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.11;

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