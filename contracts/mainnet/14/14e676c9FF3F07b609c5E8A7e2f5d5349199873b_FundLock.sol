/**
 *Submitted for verification at snowtrace.io on 2022-04-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: github/TheGrandNobody/eternal-contracts/contracts/main/FundLock.sol


/**
 * @title FundLock contract
 * @author Nobody (me)
 * @notice The FundLock contract holds funds for a given time period. This is particularly useful for automated token vesting. 
 */
contract FundLock {

    // The Eternal Token interface
    IERC20 public immutable eternal;

    // The address of the recipient
    address public immutable recipient;

    // The maximum supply of the token
    uint256 public immutable maxSupply;
    // The total amount of tokens being vested (multiplied by 10 ** 18 for decimal-precision)
    uint256 public immutable totalAmount;
    // The factor by which to release a given number of vested tokens
    uint256 public immutable gamma;

    constructor (address _eternal, address _recipient, uint256 _totalAmount, uint256 _maxSupply, uint256 _gamma) {
        eternal = IERC20(_eternal);
        recipient = _recipient;
        totalAmount = _totalAmount * (10 ** 18);
        maxSupply = _maxSupply * (10 ** 18);
        gamma = _gamma;
    }

    /**
     * @notice View the amount of tokens available for withdrawal based on the amount the supply has decreased by
     * @return uint256 The maximum amount of tokens available to be withdrawn by investors from this contract at this time
     */
    function viewAmountAvailable() public view returns (uint256) {
        uint256 deltaSupply = maxSupply - eternal.totalSupply();
        uint256 amountAvailable = totalAmount * deltaSupply * gamma / maxSupply;
        return amountAvailable > totalAmount ? totalAmount : amountAvailable;
    }

    /**
     * @notice Withraws (part of) locked funds proportional to the deflation of the circulation supply of the token
     */
    function withdrawFunds() external {
        uint256 amountWithdrawn = totalAmount - eternal.balanceOf(address(this));
        require(eternal.transfer(recipient, viewAmountAvailable() - amountWithdrawn), "Failed to withdraw funds");
    }
}