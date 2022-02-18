//SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IComptroller.sol';
import './IQiToken.sol';

contract YieldFarmer {
  IComptroller comptroller;
  IQiToken qiToken;
  IERC20 underlying;
  uint collateralFactor;

  constructor(
    address _comptroller,
    address _qiToken,
    address _underlying,
    uint256 _collateralFactor
  ) {
    comptroller = IComptroller(_comptroller);
    qiToken = IQiToken(_qiToken);
    underlying = IERC20(_underlying);
    address[] memory qiTokens = new address[](1);
    qiTokens[0] = _qiToken; 
    comptroller.enterMarkets(qiTokens);
    collateralFactor = _collateralFactor;
  }

  function openPosition(uint initialAmount) external {
    uint nextCollateralAmount = initialAmount;
    for(uint i = 0; i < 5; i++) {
      nextCollateralAmount = _supplyAndBorrow(nextCollateralAmount);
    }
  }

  function _supplyAndBorrow(uint collateralAmount) internal returns(uint) {
    underlying.approve(address(qiToken), collateralAmount);
    qiToken.mint(collateralAmount);
    uint borrowAmount = (collateralAmount * collateralFactor) / 100;
    qiToken.borrow(borrowAmount);
    return borrowAmount;
  }

  function closePosition() external {
    uint balanceBorrow = qiToken.borrowBalanceCurrent(address(this));
    underlying.approve(address(qiToken), balanceBorrow);
    qiToken.repayBorrow(balanceBorrow);
    uint balancecDai = qiToken.balanceOf(address(this));
    qiToken.redeem(balancecDai);
  }

  function borrowBalance() external returns (uint256) {
    return qiToken.borrowBalanceCurrent(msg.sender);
  }

  function balanceOf() external view returns (uint256) {
    return qiToken.balanceOf(msg.sender);
  }

  function balanceOfUnderlying() external view returns (uint256) {
    return qiToken.balanceOfUnderlying(msg.sender);
  }

  function rates() external view returns (uint256, uint256) {
    return (
      qiToken.supplyRatePerTimestamp(),      
      qiToken.borrowRatePerTimestamp()
    );
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IComptroller {
  function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IQiToken {
  function mint(uint mintAmount) external returns (uint);
  function redeem(uint redeemTokens) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function borrowBalanceCurrent(address account) external returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function balanceOfUnderlying(address owner) external view returns (uint);
  function borrowRatePerTimestamp() external view returns (uint);
  function supplyRatePerTimestamp() external view returns (uint);
  function exchangeRateCurrent() external returns (uint);
}