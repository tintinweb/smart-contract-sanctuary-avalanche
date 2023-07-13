/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

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


}

interface IVault is IERC20{
  function getRate() external view returns (uint256 rate);
  function getPool() external view returns (address poolAddress);
  function getPoolCollateral() external view returns (address collateral);
  function deposit(uint256 collateralAmount, address recipient)
    external
    returns (uint256 lpTokensOut);
  function withdraw(uint256 lpTokensAmount, address recipient)
    external
    returns (uint256 collateralOut);
}



interface IPool {
    struct LPInfo {
    // Actual collateral owned
    uint256 actualCollateralAmount;
    // Number of tokens collateralized
    uint256 tokensCollateralized;
    // Overcollateralization percentage
    uint256 overCollateralization;
    // Actual Lp capacity of the Lp in synth asset  (actualCollateralAmount/overCollateralization) * price - numTokens
    uint256 capacity;
    // Utilization ratio: (numTokens * price_inv * overCollateralization) / actualCollateralAmount
    uint256 utilization;
    // Collateral coverage: (actualCollateralAmount + numTokens * price_inv) / (numTokens * price_inv)
    uint256 coverage;
    // Mint shares percentage
    uint256 mintShares;
    // Redeem shares percentage
    uint256 redeemShares;
    // Interest shares percentage
    uint256 interestShares;
    // True if it's overcollateralized, otherwise false
    bool isOvercollateralized;
  }

  /**
   * @notice Returns the LP parametrs info
   * @notice Mint, redeem and intreest shares are round down (division dust not included)
   * @param _lp Address of the LP
   * @return info Info of the input LP (see LPInfo struct)
   */
  function positionLPInfo(address _lp)
    external
    view
    returns (LPInfo memory info);
}

interface IOracle {
    function updateAnswer(int256 _newPrice) external;
}

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */ 
 contract VaultChecker {

   IVault public vault;
   IERC20 public collToken;
   IPool public pool;
   IOracle public oracle;
   uint8 public tokenDecimals;

  uint256 public actSupply;
  uint256 public ratePreDep;
  uint256 public totPreCollVault;
  uint256 public totPreCollPos;
  uint256 public numTokensPre;
  uint256 public utilizationPre;
  uint256 public coveragePre;
  uint256 public lpTokenOut;
  uint256 public ratePostDep;
  uint256 public totPostCollPost;
  uint256 public totDepCollPost;
  uint256 public totPostCollPos;
  uint256 public numTokensPost;
  uint256 public utilizationPost;
  uint256 public coveragePost;
  uint256 public ratePostUpdtDep;
  uint256 public totPostUpdtCollPost;
  uint256 public totDepPostUpdtCollPost;
  uint256 public totPostUpdtCollPos;
 

constructor(IVault _vault, IOracle _oracle, uint8 _tokenDecimals) {
  vault = _vault;
  collToken = IERC20( _vault.getPoolCollateral());
  pool = IPool(_vault.getPool());
  oracle = _oracle;
  tokenDecimals = _tokenDecimals;
}

function depositCheck(uint256 amount, int256 newPrice) external {
   actSupply = vault.totalSupply();
   ratePreDep = vault.getRate();
   totPreCollVault = actSupply * ratePreDep / (10 ** (18 + (18 - tokenDecimals)));
   IPool.LPInfo memory pos = pool.positionLPInfo(address(vault));
   totPreCollPos = pos.actualCollateralAmount;
   numTokensPre = pos.tokensCollateralized;
   utilizationPre = pos.utilization;
   coveragePre = pos.coverage;
   collToken.transferFrom(msg.sender, address(this), amount);
   collToken.approve(address(vault), amount);
   lpTokenOut = vault.deposit(amount, msg.sender);
   ratePostDep = vault.getRate();
   totPostCollPost = actSupply * ratePostDep / (10 ** (18 + (18 - tokenDecimals)));
   totDepCollPost = lpTokenOut * ratePostDep / (10 ** (18 + (18 - tokenDecimals)));
   pos = pool.positionLPInfo(address(vault));
   totPostCollPos = pos.actualCollateralAmount;
   numTokensPost = pos.tokensCollateralized;
   utilizationPost = pos.utilization;
   coveragePost = pos.coverage;
   oracle.updateAnswer(newPrice);
   ratePostUpdtDep = vault.getRate();
   totPostUpdtCollPost = actSupply * ratePostUpdtDep / (10 ** (18 + (18 - tokenDecimals)));
   totDepPostUpdtCollPost = lpTokenOut * ratePostUpdtDep / (10 ** (18 + (18 - tokenDecimals)));
   pos = pool.positionLPInfo(address(vault));
   totPostUpdtCollPos = pos.actualCollateralAmount;
}
   
}