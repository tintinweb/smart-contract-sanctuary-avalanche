/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-03
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}


// File contracts/Vesting.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Safe as much as Switzerland Banks
contract Vesting {
  // this state variable should be constant in the main network
  IERC20 public immutable TOKEN;

  // custom errors, better than `require`
  error AlreadyVested();
  error DoesNotVested();
  error TransferFromFailed();
  error TransferFailed();
  error CanNotClaim(uint256 currentTime, uint256 startTime);

  struct Vest {
    uint256 startTime;
    uint256 amount;
  }

  mapping(address => Vest) public vestings;

  constructor(address _tokenAddress) {
    TOKEN = IERC20(_tokenAddress);
  }

  // user have to call this function for vesting
  function vest(uint256 _amount) external {
    // this contract doesn't support multiple
    // vestings for an address (this wasn't requested).
    // because of that, if the caller already
    // has a vesting, revert
    if(vestings[msg.sender].startTime != 0)
      revert AlreadyVested();

    // take tokens from the user
    bool success = TOKEN.transferFrom(msg.sender, address(this), _amount);
    if(!success)
      revert TransferFromFailed();

    // increase the balance
    vestings[msg.sender] = Vest({
      startTime: block.timestamp,
      amount: _amount
    });
  }

  function claim() external {
    // prevent multiple SLOAD operations
    Vest memory currentVest = vestings[msg.sender];

    // don't allow for zero token transfers
    if(currentVest.startTime == 0)
      revert DoesNotVested();

    // i didn't create a variable for the vesting 
    // time (again, this wasn't requested)
    if(currentVest.startTime + 1 hours > block.timestamp)
      revert CanNotClaim(block.timestamp, currentVest.startTime);

    // clear records
    delete vestings[msg.sender];

    bool success = TOKEN.transfer(msg.sender, currentVest.amount);
    if(!success)
      revert TransferFailed();
  }
}