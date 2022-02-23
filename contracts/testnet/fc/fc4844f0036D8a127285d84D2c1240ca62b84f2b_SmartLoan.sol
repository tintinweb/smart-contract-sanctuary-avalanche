// SPDX-License-Identifier: UNLICENSED
// Last deployed from commit: 67cff51b225826c7ef26b55bbced2c04a906fe0c;
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "redstone-evm-connector/lib/contracts/message-based/PriceAware.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/IAssetsExchange.sol";
import "./Pool.sol";
import "./SmartLoanProperties.sol";

/**
 * @title SmartLoan
 * A contract that is authorised to borrow funds using delegated credit.
 * It maintains solvency calculating the current value of assets and borrowings.
 * In case the value of assets held drops below certain level, part of the funds may be forcibly repaid.
 * It permits only a limited and safe token transfer.
 *
 */
contract SmartLoan is SmartLoanProperties, PriceAware, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using TransferHelper for address payable;
  using TransferHelper for address;

  function initialize() external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
  }

  /**
   * Override PriceAware method to consider Avalanche guaranteed block timestamp time accuracy
   **/
  function getMaxBlockTimestampDelay() public virtual override view returns (uint256) {
    return MAX_BLOCK_TIMESTAMP_DELAY;
  }

  /**
   * Override PriceAware method, addresses below belong to authorized signers of data feeds
   **/
  function isSignerAuthorized(address _receivedSigner) public override virtual view returns (bool) {
    return (_receivedSigner == getPriceProvider1()) || (_receivedSigner == getPriceProvider2());
  }

  /**
   * Funds a loan with the value attached to the transaction
   **/
  function fund() public virtual payable {
    emit Funded(msg.sender, msg.value, block.timestamp);
  }

  /**
   * This function allows selling assets without checking if the loan will remain solvent after this operation.
   * It is used as part of the sellout() function which sells part/all of assets in order to bring the loan back to solvency.
   * It is possible that multiple different assets will have to be sold and for that reason we do not use the remainsSolvent modifier.
   **/
  function sellAsset(bytes32 asset, uint256 _amount, uint256 _minAvaxOut) private {
    IERC20Metadata token = getERC20TokenInstance(asset);
    address(token).safeTransfer(address(getExchange()), _amount);
    getExchange().sellAsset(asset, _amount, _minAvaxOut);
  }

  /**
   * @dev This function uses the redstone-evm-connector
  **/
  function withdrawAsset(bytes32 asset, uint256 amount) external onlyOwner nonReentrant remainsSolvent {
    IERC20Metadata token = getERC20TokenInstance(asset);
    address(token).safeTransfer(msg.sender, amount);
  }

  /**
   * This function attempts to sell just enough asset to receive targetAvaxAmount.
   * If there is not enough asset's balance to cover the whole targetAvaxAmount then the whole asset's balance
   * is being sold.
   * It is possible that multiple different assets will have to be sold and for that reason we do not use the remainsSolvent modifier.
   **/
  function sellAssetForTargetAvax(bytes32 asset, uint256 targetAvaxAmount) private {
    IERC20Metadata token = getERC20TokenInstance(asset);
    uint256 balance = token.balanceOf(address(this));
    if (balance > 0) {
      uint256 minSaleAmount = getExchange().getMinimumERC20TokenAmountForExactAVAX(targetAvaxAmount, address(token));
      if (balance < minSaleAmount) {
        sellAsset(asset, balance, 0);
      } else {
        sellAsset(asset, minSaleAmount, targetAvaxAmount);
      }
    }
  }

  /**
   * This function attempts to repay the _repayAmount back to the pool.
   * If there is not enough AVAX balance to repay the _repayAmount then the available AVAX balance will be repaid.
   * @dev This function uses the redstone-evm-connector
   **/
  function attemptRepay(uint256 _repayAmount) internal {
    repay(Math.min(address(this).balance, _repayAmount));
  }

  function payBonus(uint256 _bonus) internal {
    payable(msg.sender).safeTransferETH(Math.min(_bonus, address(this).balance));
  }

  /**
   * This function can only be accessed by the owner and allows selling all of the assets.
   * @dev This function uses the redstone-evm-connector
   **/
  function closeLoan() external payable onlyOwner nonReentrant remainsSolvent {
    bytes32[] memory assets = getExchange().getAllAssets();
    for (uint256 i = 0; i < assets.length; i++) {
      uint256 balance = getERC20TokenInstance(assets[i]).balanceOf(address(this));
      if (balance > 0) {
        sellAsset(assets[i], balance, 0);
      }
    }

    uint256 debt = getDebt();
    require(address(this).balance >= debt, "Selling out all assets without repaying the whole debt is not allowed");
    repay(debt);
    emit LoanClosed(debt, address(this).balance, block.timestamp);

    uint256 balance = address(this).balance;
    if (balance > 0) {
      payable(msg.sender).safeTransferETH(balance);
      emit Withdrawn(msg.sender, balance, block.timestamp);
    }
  }

  /**
  * @dev This function uses the redstone-evm-connector
  **/
  function liquidateLoan(uint256 repayAmount) external payable nonReentrant successfulLiquidation {
    require(!isSolvent(), "Cannot sellout a solvent account");

    uint256 debt = getDebt();
    if (repayAmount > debt) {
      repayAmount = debt;
    }
    uint256 bonus = (repayAmount * getLiquidationBonus()) / getPercentagePrecision();
    uint256 totalRepayAmount = repayAmount + bonus;

    sellout(totalRepayAmount);
    attemptRepay(repayAmount);
    payBonus(bonus);
    emit Liquidated(msg.sender, repayAmount, bonus, getLTV(), block.timestamp);
  }

  /**
   * This function role is to sell part/all of the available assets in order to receive the targetAvaxAmount.
   *
   **/
  function sellout(uint256 targetAvaxAmount) private {
    bytes32[] memory assets = getExchange().getAllAssets();
    for (uint256 i = 0; i < assets.length; i++) {
      if (address(this).balance >= targetAvaxAmount) break;
      sellAssetForTargetAvax(assets[i], targetAvaxAmount - address(this).balance);
    }
  }

  /**
   * Withdraws an amount from the loan
   * This method could be used to cash out profits from investments
   * The loan needs to remain solvent after the withdrawal
   * @param _amount to be withdrawn
   * @dev This function uses the redstone-evm-connector
   **/
  function withdraw(uint256 _amount) public virtual onlyOwner nonReentrant remainsSolvent {
    require(address(this).balance >= _amount, "There is not enough funds to withdraw");

    payable(msg.sender).safeTransferETH(_amount);

    emit Withdrawn(msg.sender, _amount, block.timestamp);
  }

  /**
   * Invests an amount to buy an asset
   * @param _asset code of the asset
   * @param _exactERC20AmountOut exact amount of asset to buy
   * @param _maxAvaxAmountIn maximum amount of AVAX to sell
   * @dev This function uses the redstone-evm-connector
   **/
  function invest(bytes32 _asset, uint256 _exactERC20AmountOut, uint256 _maxAvaxAmountIn) external onlyOwner nonReentrant remainsSolvent {
    require(address(this).balance >= _maxAvaxAmountIn, "Not enough funds are available to invest in an asset");

    bool success = getExchange().buyAsset{value: _maxAvaxAmountIn}(_asset, _exactERC20AmountOut);
    require(success, "Investment failed");

    emit Invested(msg.sender, _asset, _exactERC20AmountOut, block.timestamp);
  }

  /**
   * Redeem an investment by selling an asset
   * @param _asset code of the asset
   * @param _exactERC20AmountIn exact amount of token to sell
   * @param _minAvaxAmountOut minimum amount of the AVAX token to buy
   * @dev This function uses the redstone-evm-connector
   **/
  function redeem(bytes32 _asset, uint256 _exactERC20AmountIn, uint256 _minAvaxAmountOut) external nonReentrant onlyOwner remainsSolvent {
    IERC20Metadata token = getERC20TokenInstance(_asset);
    address(token).safeTransfer(address(getExchange()), _exactERC20AmountIn);
    bool success = getExchange().sellAsset(_asset, _exactERC20AmountIn, _minAvaxAmountOut);
    require(success, "Redemption failed");

    emit Redeemed(msg.sender, _asset, _exactERC20AmountIn, block.timestamp);
  }

  /**
   * Borrows funds from the pool
   * @param _amount of funds to borrow
   * @dev This function uses the redstone-evm-connector
   **/
  function borrow(uint256 _amount) external onlyOwner remainsSolvent {
    getPool().borrow(_amount);

    emit Borrowed(msg.sender, _amount, block.timestamp);
  }

  /**
   * Repays funds to the pool
   * @param _amount of funds to repay
   * @dev This function uses the redstone-evm-connector
   **/
  function repay(uint256 _amount) public payable {
    if (isSolvent()) {
      require(msg.sender == owner());
    }

    _amount = Math.min(_amount, getDebt());
    require(address(this).balance >= _amount, "There is not enough funds to repay the loan");

    getPool().repay{value: _amount}();

    emit Repaid(msg.sender, _amount, block.timestamp);
  }

  receive() external payable {}

  /* ========== VIEW FUNCTIONS ========== */

  /**
   * Returns the current value of a loan in AVAX including cash and investments
   * @dev This function uses the redstone-evm-connector
   **/
  function getTotalValue() public view virtual returns (uint256) {
    uint256 total = address(this).balance;
    bytes32[] memory assets = getExchange().getAllAssets();
    uint256[] memory prices = getPricesFromMsg(assets);
    uint256 avaxPrice = prices[0];
    require(avaxPrice != 0, "Avax price returned from oracle is zero");

    for (uint256 i = 1; i < prices.length; i++) {
      require(prices[i] != 0, "Asset price returned from oracle is zero");

      bytes32 _asset = assets[i];
      IERC20Metadata token = getERC20TokenInstance(_asset);
      uint256 assetBalance = getBalance(address(this), _asset);

      total = total + (prices[i] * 10**18 * assetBalance) / (avaxPrice * 10**token.decimals());
    }

    return total;
  }

  /**
   * Returns the current balance of the asset held by a given user
   * @dev _asset the code of an asset
   * @dev _user the address of queried user
   **/
  function getBalance(address _user, bytes32 _asset) public view returns (uint256) {
    IERC20 token = IERC20(getExchange().getAssetAddress(_asset));
    return token.balanceOf(_user);
  }

  function getERC20TokenInstance(bytes32 _asset) internal view returns (IERC20Metadata) {
    address assetAddress = getExchange().getAssetAddress(_asset);
    IERC20Metadata token = IERC20Metadata(assetAddress);
    return token;
  }

  /**
   * Returns the current debt associated with the loan
   **/
  function getDebt() public view virtual returns (uint256) {
    return getPool().getBorrowed(address(this));
  }

  /**
   * LoanToValue ratio is calculated as the ratio between debt and collateral.
   * The collateral is equal to total loan value takeaway debt.
   * @dev This function uses the redstone-evm-connector
   **/
  function getLTV() public view returns (uint256) {
    uint256 debt = getDebt();
    uint256 totalValue = getTotalValue();
    if (debt == 0) {
      return 0;
    } else if (debt < totalValue) {
      return (debt * getPercentagePrecision()) / (totalValue - debt);
    } else {
      return getMaxLtv();
    }
  }

  function getFullLoanStatus() public view returns (uint256[4] memory) {
    return [getTotalValue(), getDebt(), getLTV(), isSolvent() ? uint256(1) : uint256(0)];
  }

  /**
   * Checks if the loan is solvent.
   * It means that the ratio between debt and collateral is below safe level,
   * which is parametrized by the getMaxLtv()
   * @dev This function uses the redstone-evm-connector
   **/
  function isSolvent() public view returns (bool) {
    return getLTV() < getMaxLtv();
  }

  /**
   * Returns the balances of all assets served by the price provider
   * It could be used as a helper method for UI
   **/
  function getAllAssetsBalances() public view returns (uint256[] memory) {
    bytes32[] memory assets = getExchange().getAllAssets();
    uint256[] memory balances = new uint256[](assets.length);

    for (uint256 i = 0; i < assets.length; i++) {
      balances[i] = getBalance(address(this), assets[i]);
    }

    return balances;
  }

  /**
   * Returns the prices of all assets served by the price provider
   * It could be used as a helper method for UI
   * @dev This function uses the redstone-evm-connector
   **/
  function getAllAssetsPrices() public view returns (uint256[] memory) {
    bytes32[] memory assets = getExchange().getAllAssets();

    return getPricesFromMsg(assets);
  }

  /* ========== MODIFIERS ========== */

  /**
  * @dev This modifier uses the redstone-evm-connector
  **/
  modifier remainsSolvent() {
    _;
    require(isSolvent(), "The action may cause an account to become insolvent");
  }

  /**
   * This modifier checks if the LTV is between MIN_SELLOUT_LTV and _MAX_LTV after performing the liquidateLoan() operation.
   * If the liquidateLoan() was not called by the owner then an additional check of making sure that LTV > MIN_SELLOUT_LTV is applied.
   * It protects the user from an unnecessarily costly liquidation.
   * The loan must be solvent after the liquidateLoan() operation.
   * @dev This modifier uses the redstone-evm-connector
   **/
  modifier successfulLiquidation() {
    _;
    uint256 LTV = getLTV();
    if (msg.sender != owner()) {
      require(LTV >= getMinSelloutLtv(), "This operation would result in a loan with LTV lower than Minimal Sellout LTV which would put loan's owner in a risk of an unnecessarily high loss");
    }
    require(LTV < getMaxLtv(), "This operation would not result in bringing the loan back to a solvent state");
  }

  /* ========== EVENTS ========== */

  /**
   * @dev emitted after a loan is funded
   * @param funder the address which funded the loan
   * @param amount the amount of funds
   * @param time of funding
   **/
  event Funded(address indexed funder, uint256 amount, uint256 time);

  /**
   * @dev emitted after the funds are withdrawn from the loan
   * @param owner the address which withdraws funds from the loan
   * @param amount the amount of funds withdrawn
   * @param time of the withdrawal
   **/
  event Withdrawn(address indexed owner, uint256 amount, uint256 time);

  /**
   * @dev emitted after the funds are invested into an asset
   * @param investor the address of investor making the purchase
   * @param asset bought by the investor
   * @param amount the investment
   * @param time of the investment
   **/
  event Invested(address indexed investor, bytes32 indexed asset, uint256 amount, uint256 time);

  /**
   * @dev emitted after the investment is sold
   * @param investor the address of investor selling the asset
   * @param asset sold by the investor
   * @param amount the investment
   * @param time of the redemption
   **/
  event Redeemed(address indexed investor, bytes32 indexed asset, uint256 amount, uint256 time);

  /**
   * @dev emitted when funds are borrowed from the pool
   * @param borrower the address of borrower
   * @param amount of the borrowed funds
   * @param time of the borrowing
   **/
  event Borrowed(address indexed borrower, uint256 amount, uint256 time);

  /**
   * @dev emitted when funds are repaid to the pool
   * @param borrower the address initiating repayment
   * @param amount of repaid funds
   * @param time of the repayment
   **/
  event Repaid(address indexed borrower, uint256 amount, uint256 time);

  /**
   * @dev emitted after a successful liquidation operation
   * @param liquidator the address that initiated the liquidation operation
   * @param repayAmount requested amount (AVAX) of liquidation
   * @param bonus an amount of bonus (AVAX) received by the liquidator
   * @param ltv a new LTV after the liquidation operation
   * @param time a time of the liquidation
   **/
  event Liquidated(address indexed liquidator, uint256 repayAmount, uint256 bonus, uint256 ltv, uint256 time);

  /**
   * @dev emitted after closing a loan by the owner
   * @param debtRepaid the amount of a borrowed AVAX that was repaid back to the pool
   * @param withdrawalAmount the amount of AVAX that was withdrawn by the owner after closing the loan
   * @param time a time of the loan's closure
   **/
  event LoanClosed(uint256 debtRepaid, uint256 withdrawalAmount, uint256 time);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract PriceAware {
  using ECDSA for bytes32;

  uint256 constant _MAX_DATA_TIMESTAMP_DELAY = 3 * 60; // 3 minutes
  uint256 constant _MAX_BLOCK_TIMESTAMP_DELAY = 15; // 15 seconds

  /* ========== VIRTUAL FUNCTIONS (MAY BE OVERRIDEN IN CHILD CONTRACTS) ========== */

  function getMaxDataTimestampDelay() public virtual view returns (uint256) {
    return _MAX_DATA_TIMESTAMP_DELAY;
  }

  function getMaxBlockTimestampDelay() public virtual view returns (uint256) {
    return _MAX_BLOCK_TIMESTAMP_DELAY;
  }

  function isSignerAuthorized(address _receviedSigner) public virtual view returns (bool);

  function isTimestampValid(uint256 _receivedTimestamp) public virtual view returns (bool) {
    // Getting data timestamp from future seems quite unlikely
    // But we've already spent too much time with different cases
    // Where block.timestamp was less than dataPackage.timestamp.
    // Some blockchains may case this problem as well.
    // That's why we add MAX_BLOCK_TIMESTAMP_DELAY
    // and allow data "from future" but with a small delay
    require(
      (block.timestamp + getMaxBlockTimestampDelay()) > _receivedTimestamp,
      "Data with future timestamps is not allowed");

    return block.timestamp < _receivedTimestamp
      || block.timestamp - _receivedTimestamp < getMaxDataTimestampDelay();
  }

  /* ========== FUNCTIONS WITH IMPLEMENTATION (CAN NOT BE OVERRIDEN) ========== */

  function getPriceFromMsg(bytes32 symbol) internal view returns (uint256) {bytes32[] memory symbols = new bytes32[](1); symbols[0] = symbol;
    return getPricesFromMsg(symbols)[0];
  }

  function getPricesFromMsg(bytes32[] memory symbols) internal view returns (uint256[] memory) {
    // The structure of calldata witn n - data items:
    // The data that is signed (symbols, values, timestamp) are inside the {} brackets
    // [origina_call_data| ?]{[[symbol | 32][value | 32] | n times][timestamp | 32]}[size | 1][signature | 65]

    // 1. First we extract dataSize - the number of data items (symbol,value pairs) in the message
    uint8 dataSize; //Number of data entries
    assembly {
      // Calldataload loads slots of 32 bytes
      // The last 65 bytes are for signature
      // We load the previous 32 bytes and automatically take the 2 least significant ones (casting to uint16)
      dataSize := calldataload(sub(calldatasize(), 97))
    }

    // 2. We calculate the size of signable message expressed in bytes
    // ((symbolLen(32) + valueLen(32)) * dataSize + timeStamp length
    uint16 messageLength = uint16(dataSize) * 64 + 32; //Length of data message in bytes

    // 3. We extract the signableMessage

    // (That's the high level equivalent 2k gas more expensive)
    // bytes memory rawData = msg.data.slice(msg.data.length - messageLength - 65, messageLength);

    bytes memory signableMessage;
    assembly {
      signableMessage := mload(0x40)
      mstore(signableMessage, messageLength)
      // The starting point is callDataSize minus length of data(messageLength), signature(65) and size(1) = 66
      calldatacopy(
        add(signableMessage, 0x20),
        sub(calldatasize(), add(messageLength, 66)),
        messageLength
      )
      mstore(0x40, add(signableMessage, 0x20))
    }

    // 4. We first hash the raw message and then hash it again with the prefix
    // Following the https://github.com/ethereum/eips/issues/191 standard
    bytes32 hash = keccak256(signableMessage);
    bytes32 hashWithPrefix = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );

    // 5. We extract the off-chain signature from calldata

    // (That's the high level equivalent 2k gas more expensive)
    // bytes memory signature = msg.data.slice(msg.data.length - 65, 65);
    bytes memory signature;
    assembly {
      signature := mload(0x40)
      mstore(signature, 65)
      calldatacopy(add(signature, 0x20), sub(calldatasize(), 65), 65)
      mstore(0x40, add(signature, 0x20))
    }

    // 6. We verify the off-chain signature against on-chain hashed data

    address signer = hashWithPrefix.recover(signature);
    require(isSignerAuthorized(signer), "Signer not authorized");

    // 7. We extract timestamp from callData

    uint256 dataTimestamp;
    assembly {
      // Calldataload loads slots of 32 bytes
      // The last 65 bytes are for signature + 1 for data size
      // We load the previous 32 bytes
      dataTimestamp := calldataload(sub(calldatasize(), 98))
    }

    // 8. We validate timestamp
    require(isTimestampValid(dataTimestamp), "Data timestamp is invalid");

    return _readFromCallData(symbols, uint256(dataSize), messageLength);
  }

  function _readFromCallData(bytes32[] memory symbols, uint256 dataSize, uint16 messageLength) private pure returns (uint256[] memory) {
    uint256[] memory values;
    uint256 i;
    uint256 j;
    uint256 readyAssets;
    bytes32 currentSymbol;

    // We iterate directly through call data to extract the values for symbols
    assembly {
      let start := sub(calldatasize(), add(messageLength, 66))

      values := msize()
      mstore(values, mload(symbols))
      mstore(0x40, add(add(values, 0x20), mul(mload(symbols), 0x20)))

      for { i := 0 } lt(i, dataSize) { i := add(i, 1) } {
        currentSymbol := calldataload(add(start, mul(i, 64)))

        for { j := 0 } lt(j, mload(symbols)) { j := add(j, 1) } {
          if eq(mload(add(add(symbols, 32), mul(j, 32))), currentSymbol) {
            mstore(
              add(add(values, 32), mul(j, 32)),
              calldataload(add(add(start, mul(i, 64)), 32))
            )
            readyAssets := add(readyAssets, 1)
          }

          if eq(readyAssets, mload(symbols)) {
            i := dataSize
          }
        }
      }
    }

    return (values);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: UNLICENSED
// Last deployed using commit: ;
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IAssetExchange
 * @dev Basic interface for investing into assets
 * It could be linked either to DEX or to a synthetic assets platform
 */
interface IAssetsExchange {
  /**
   * For adding supported assets
   **/
  struct Asset {
    bytes32 asset;
    address assetAddress;
  }

  /**
   * Buys selected asset with AVAX
   * @dev _asset asset code
   * @dev _exactERC20AmountOut exact amount of asset to be bought
   **/
  function buyAsset(bytes32 _asset, uint256 _exactERC20AmountOut) external payable returns (bool);

  /**
   * Sells selected asset for AVAX
   * @dev _asset asset code
   * @dev _exactERC20AmountIn amount to be bought
   * @dev _minAvaxAmountOut minimum amount of the AVAX token to be bought
   **/
  function sellAsset(bytes32 _asset, uint256 _exactERC20AmountIn, uint256 _minAvaxAmountOut) external returns (bool);

  /**
   * Returns the maximum AVAX amount that will be obtained in the event of selling _amountIn of _token ERC20 token.
   **/
  function getEstimatedAVAXFromERC20Token(uint256 _amountIn, address _token) external returns (uint256);

  /**
   * Returns the minimum token amount that is required to be sold to receive _exactAmountOut of AVAX.
   **/
  function getMinimumERC20TokenAmountForExactAVAX(uint256 _exactAmountOut, address _token) external returns (uint256);

  /**
   * Adds or updates supported assets
   * First asset must be a blockchain native currency
   * @dev _assets assets to be added or updated
   **/
  function updateAssets(Asset[] memory _assets) external;

  /**
   * Removes supported assets
   * @dev _assets assets to be removed
   **/
  function removeAssets(bytes32[] calldata _assets) external;

  /**
   * Returns all the supported assets keys
   **/
  function getAllAssets() external view returns (bytes32[] memory);

  /**
   * Returns address of an asset
   **/
  function getAssetAddress(bytes32 _asset) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
// Last deployed from commit: 67cff51b225826c7ef26b55bbced2c04a906fe0c;
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./CompoundingIndex.sol";
import "./interfaces/IRatesCalculator.sol";
import "./interfaces/IBorrowersRegistry.sol";


/**
 * @title Pool
 * @dev Contract allowing user to deposit and borrow funds from a single pot
 * Depositors are rewarded with the interest rates collected from borrowers.
 * Rates are compounded every second and getters always return the current deposit and borrowing balance.
 * The interest rates calculation is delegated to the external calculator contract.
 */
contract Pool is OwnableUpgradeable, ReentrancyGuardUpgradeable, IERC20 {
  using TransferHelper for address payable;

  uint256 public constant MAX_POOL_UTILISATION_FOR_BORROWING = 0.95e18;

  mapping(address => mapping(address => uint256)) private _allowed;
  mapping(address => uint256) private _deposited;

  mapping(address => uint256) public borrowed;

  IRatesCalculator private _ratesCalculator;
  IBorrowersRegistry private _borrowersRegistry;

  CompoundingIndex private _depositIndex;
  CompoundingIndex private _borrowIndex;

  function initialize(IRatesCalculator ratesCalculator_, IBorrowersRegistry borrowersRegistry_, CompoundingIndex depositIndex_, CompoundingIndex borrowIndex_) public initializer {
    require(AddressUpgradeable.isContract(address(borrowersRegistry_)), "Must be a contract");

    _borrowersRegistry = borrowersRegistry_;
    _ratesCalculator = ratesCalculator_;
    _depositIndex = depositIndex_;
    _borrowIndex = borrowIndex_;

    __Ownable_init();
    __ReentrancyGuard_init();
    _updateRates();
  }

  /* ========== SETTERS ========== */

  /**
   * Sets the new rate calculator.
   * The calculator is an external contract that contains the logic for calculating deposit and borrowing rates.
   * Only the owner of the Contract can execute this function.
   * @dev _ratesCalculator the address of rates calculator
   **/
  function setRatesCalculator(IRatesCalculator ratesCalculator_) external onlyOwner {
    // setting address(0) ratesCalculator_ freezes the pool
    require(AddressUpgradeable.isContract(address(ratesCalculator_)) || address(ratesCalculator_) == address(0), "Must be a contract");
    _ratesCalculator = ratesCalculator_;
    if (address(ratesCalculator_) != address(0)) {
      _updateRates();
    }
  }

  /**
   * Sets the new borrowers registry contract.
   * The borrowers registry decides if an account can borrow funds.
   * Only the owner of the Contract can execute this function.
   * @dev _borrowersRegistry the address of borrowers registry
   **/
  function setBorrowersRegistry(IBorrowersRegistry borrowersRegistry_) external onlyOwner {
    require(address(borrowersRegistry_) != address(0), "The borrowers registry cannot set to a null address");
    require(AddressUpgradeable.isContract(address(borrowersRegistry_)), "Must be a contract");

    _borrowersRegistry = borrowersRegistry_;
    emit BorrowersRegistryChanged(address(borrowersRegistry_), block.timestamp);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    require(recipient != address(0), "ERC20: cannot transfer to the zero address");
    require(recipient != address(this), "ERC20: cannot transfer to the pool address");

    _accumulateDepositInterest(msg.sender);

    require(_deposited[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");

    // (this is verified in "require" above)
    unchecked {
      _deposited[msg.sender] -= amount;
    }

    _accumulateDepositInterest(recipient);
    _deposited[recipient] += amount;

    emit Transfer(msg.sender, recipient, amount);

    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowed[owner][spender];
  }

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    require(spender != address(0), "Allowance spender cannot be a zero address");
    uint256 newAllowance = _allowed[msg.sender][spender] + addedValue;
    _allowed[msg.sender][spender] = newAllowance;

    emit Approval(msg.sender, spender, newAllowance);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    require(spender != address(0), "Allowance spender cannot be a zero address");
    uint256 currentAllowance = _allowed[msg.sender][spender];
    require(currentAllowance >= subtractedValue, "Current allowance is smaller than the subtractedValue");

    uint256 newAllowance = currentAllowance - subtractedValue;
    _allowed[msg.sender][spender] = newAllowance;

    emit Approval(msg.sender, spender, newAllowance);
    return true;
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    require(spender != address(0), "Allowance spender cannot be a zero address");
    _allowed[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    require(_allowed[sender][msg.sender] >= amount, "Not enough tokens allowed to transfer required amount");
    require(recipient != address(0), "ERC20: cannot transfer to the zero address");
    require(recipient != address(this), "ERC20: cannot transfer to the pool address");

    _accumulateDepositInterest(msg.sender);

    require(_deposited[sender] >= amount, "ERC20: transfer amount exceeds balance");

    _deposited[sender] -= amount;
    _allowed[sender][msg.sender] -= amount;

    _accumulateDepositInterest(recipient);
    _deposited[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    return true;
  }

  /**
   * Deposits the message value
   * It updates user deposited balance, total deposited and rates
   **/
  function deposit() public payable virtual nonReentrant {
    _accumulateDepositInterest(msg.sender);

    _mint(msg.sender, msg.value);
    _updateRates();

    emit Deposit(msg.sender, msg.value, block.timestamp);
  }

  /**
   * Withdraws selected amount from the user deposits
   * @dev _amount the amount to be withdrawn
   **/
  function withdraw(uint256 _amount) external nonReentrant {
    require(address(this).balance >= _amount, "There is not enough funds in the pool to fund the loan");

    _accumulateDepositInterest(msg.sender);

    _burn(msg.sender, _amount);

    payable(msg.sender).safeTransferETH(_amount);

    _updateRates();

    emit Withdrawal(msg.sender, _amount, block.timestamp);
  }

  /**
   * Borrows the specified amount
   * It updates user borrowed balance, total borrowed amount and rates
   * @dev _amount the amount to be borrowed
   **/
  function borrow(uint256 _amount) public virtual canBorrow nonReentrant {
    require(address(this).balance >= _amount);

    _accumulateBorrowingInterest(msg.sender);

    borrowed[msg.sender] += _amount;
    borrowed[address(this)] += _amount;

    payable(msg.sender).safeTransferETH(_amount);

    _updateRates();

    emit Borrowing(msg.sender, _amount, block.timestamp);
  }

  /**
   * Repays the message value
   * It updates user borrowed balance, total borrowed amount and rates
   * @dev It is only meant to be used by the SmartLoan.
   **/
  function repay() external payable nonReentrant {
    _accumulateBorrowingInterest(msg.sender);

    require(borrowed[msg.sender] >= msg.value, "You are trying to repay more that was borrowed by a user");

    borrowed[msg.sender] -= msg.value;
    borrowed[address(this)] -= msg.value;

    _updateRates();

    emit Repayment(msg.sender, msg.value, block.timestamp);
  }

  /* =========


  /**
   * Returns the current borrowed amount for the given user
   * The value includes the interest rates owned at the current moment
   * @dev _user the address of queried borrower
  **/
  function getBorrowed(address _user) public view returns (uint256) {
    return _borrowIndex.getIndexedValue(borrowed[_user], _user);
  }

  function totalSupply() public view override returns (uint256) {
    return balanceOf(address(this));
  }

  function totalBorrowed() public view returns (uint256) {
    return getBorrowed(address(this));
  }

  /**
   * Returns the current deposited amount for the given user
   * The value includes the interest rates earned at the current moment
   * @dev _user the address of queried depositor
   **/
  function balanceOf(address user) public view override returns (uint256) {
    return _depositIndex.getIndexedValue(_deposited[user], user);
  }

  /**
   * Returns the current interest rate for deposits
   **/
  function getDepositRate() public view returns (uint256) {
    return _ratesCalculator.calculateDepositRate(totalBorrowed(), totalSupply());
  }

  /**
   * Returns the current interest rate for borrowings
   **/
  function getBorrowingRate() public view returns (uint256) {
    return _ratesCalculator.calculateBorrowingRate(totalBorrowed(), totalSupply());
  }

  /**
   * Recovers the surplus funds resultant from difference between deposit and borrowing rates
   **/
  function recoverSurplus(uint256 amount, address account) public onlyOwner nonReentrant {
    uint256 surplus = address(this).balance + totalBorrowed() - totalSupply();

    require(amount <= address(this).balance, "Trying to recover more surplus funds than pool balance");
    require(amount <= surplus, "Trying to recover more funds than current surplus");

    payable(account).safeTransferETH(amount);
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: cannot mint to the zero address");

    _deposited[account] += amount;
    _deposited[address(this)] += amount;

    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(_deposited[account] >= amount, "ERC20: burn amount exceeds user balance");
    require(_deposited[address(this)] >= amount, "ERC20: burn amount exceeds current pool indexed balance");

    // verified in "require" above
    unchecked {
      _deposited[account] -= amount;
      _deposited[address(this)] -= amount;
    }

    emit Transfer(account, address(0), amount);
  }

  function _updateRates() internal {
    require(address(_ratesCalculator) != address(0), "Pool is frozen: cannot perform deposit, withdraw, borrow and repay operations");
    _depositIndex.setRate(_ratesCalculator.calculateDepositRate(totalBorrowed(), totalSupply()));
    _borrowIndex.setRate(_ratesCalculator.calculateBorrowingRate(totalBorrowed(), totalSupply()));
  }

  function _accumulateDepositInterest(address user) internal {
    uint256 depositedWithInterest = balanceOf(user);
    uint256 interest = depositedWithInterest - _deposited[user];

    _mint(user, interest);

    emit InterestCollected(user, interest, block.timestamp);

    _depositIndex.updateUser(user);
    _depositIndex.updateUser(address(this));
  }

  function _accumulateBorrowingInterest(address user) internal {
    uint256 borrowedWithInterest = getBorrowed(user);
    uint256 interest = borrowedWithInterest - borrowed[user];
    borrowed[user] = borrowedWithInterest;
    borrowed[address(this)] += interest;

    _borrowIndex.updateUser(user);
    _borrowIndex.updateUser(address(this));
  }

  /* ========== MODIFIERS ========== */

  modifier canBorrow() {
    require(address(_borrowersRegistry) != address(0), "Borrowers registry is not configured");
    require(_borrowersRegistry.canBorrow(msg.sender), "Only the accounts authorised by borrowers registry may borrow");
    require(totalSupply() != 0, "Cannot borrow from an empty pool");
    _;
    require((totalBorrowed() * 1e18) / totalSupply() <= MAX_POOL_UTILISATION_FOR_BORROWING, "The pool utilisation cannot be greater than 95%");
  }

  /* ========== EVENTS ========== */

  /**
   * @dev emitted after the user deposits funds
   * @param user the address performing the deposit
   * @param value the amount deposited
   * @param timestamp of the deposit
   **/
  event Deposit(address indexed user, uint256 value, uint256 timestamp);

  /**
   * @dev emitted after the user withdraws funds
   * @param user the address performing the withdrawal
   * @param value the amount withdrawn
   * @param timestamp of the withdrawal
   **/
  event Withdrawal(address indexed user, uint256 value, uint256 timestamp);

  /**
   * @dev emitted after the user borrows funds
   * @param user the address that borrows
   * @param value the amount borrowed
   * @param timestamp of the borrowing
   **/
  event Borrowing(address indexed user, uint256 value, uint256 timestamp);

  /**
   * @dev emitted after the user repays debt
   * @param user the address that repays
   * @param value the amount repaid
   * @param timestamp of the repayment
   **/
  event Repayment(address indexed user, uint256 value, uint256 timestamp);

  /**
   * @dev emitted after accumulating deposit interest
   * @param user the address that the deposit interest is accumulated
   * @param value the amount accumulated interest
   * @param timestamp of the interest accumulation
   **/
  event InterestCollected(address indexed user, uint256 value, uint256 timestamp);

  /**
  * @dev emitted after changing borrowers registry
  * @param registry an address of the newly set borrowers registry
  * @param timestamp of the borrowers registry change
  **/
  event BorrowersRegistryChanged(address indexed registry, uint256 timestamp);
}

// SPDX-License-Identifier: UNLICENSED
// Last deployed using commit: ;
pragma solidity ^0.8.4;

import "./interfaces/IAssetsExchange.sol";
import "./Pool.sol";

/**
 * @title SmartLoanProperties
 * A contract that holds SmartLoan related properties.
 * Every property has a virtual getter to allow overriding when upgrading a SmartLoan contract.
 *
 */
contract SmartLoanProperties {

  uint256 private constant _PERCENTAGE_PRECISION = 1000;
  // 10%
  uint256 private constant _LIQUIDATION_BONUS = 100;

  // 500%
  uint256 private constant _MAX_LTV = 5000;
  // 400%
  uint256 private constant _MIN_SELLOUT_LTV = 4000;

  address private constant _EXCHANGE_ADDRESS = 0x11FD6290AF8805b29ce6F22FC05F4Bcaa3976f3F;

  address private constant _POOL_ADDRESS = 0x1A3e6F61726556Be93BF9dCe68Bd4F42D8E9bD96;

  // redstone-evm-connector price providers
  address private constant _PRICE_PROVIDER_1 = 0x981bdA8276ae93F567922497153de7A5683708d3;

  address private constant _PRICE_PROVIDER_2 = 0x3BEFDd935b50F172e696A5187DBaCfEf0D208e48;

  // redstone-evm-connector max block.timestamp acceptable delay
  uint256 internal constant MAX_BLOCK_TIMESTAMP_DELAY = 30; // 30 seconds


  /* ========== GETTERS ========== */


  function getPercentagePrecision() public virtual view returns (uint256) {
    return _PERCENTAGE_PRECISION;
  }

  function getLiquidationBonus() public virtual view returns (uint256) {
    return _LIQUIDATION_BONUS;
  }

  function getMaxLtv() public virtual view returns (uint256) {
    return _MAX_LTV;
  }

  function getMinSelloutLtv() public virtual view returns (uint256) {
    return _MIN_SELLOUT_LTV;
  }

  function getExchange() public virtual view returns (IAssetsExchange) {
    return IAssetsExchange(_EXCHANGE_ADDRESS);
  }

  function getPool() public virtual view returns (Pool) {
    return Pool(_POOL_ADDRESS);
  }

  function getPriceProvider1() public virtual view returns (address) {
    return _PRICE_PROVIDER_1;
  }

  function getPriceProvider2() public virtual view returns (address) {
    return _PRICE_PROVIDER_2;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

// SPDX-License-Identifier: UNLICENSED
// Last deployed from commit: 67cff51b225826c7ef26b55bbced2c04a906fe0c;
pragma solidity ^0.8.4;

import "./lib/WadRayMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * CompoundingIndex
 * The contract contains logic for time-based index recalculation with minimal memory footprint.
 * It could be used as a base building block for any index-based entities like deposits and loans.
 * @dev updatedRate the value of updated rate
 **/
contract CompoundingIndex is Ownable {
  using WadRayMath for uint256;

  uint256 private constant SECONDS_IN_YEAR = 365 days;
  uint256 private constant BASE_RATE = 1e18;

  uint256 public start = block.timestamp;

  uint256 public index = BASE_RATE;
  uint256 public indexUpdateTime = start;

  mapping(uint256 => uint256) prevIndex;
  mapping(address => uint256) userUpdateTime;

  uint256 public rate;

  constructor(address owner_) {
    if (address(owner_) != address(0)) {
      transferOwnership(owner_);
    }
  }

  /* ========== SETTERS ========== */

  /**
   * Sets the new rate
   * Before the new rate is set, the index is updated accumulating interest
   * @dev updatedRate the value of updated rate
   **/
  function setRate(uint256 _rate) public onlyOwner {
    updateIndex();
    rate = _rate;
    emit RateUpdated(rate);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * Updates user index
   * It persists the update time and the update index time->index mapping
   * @dev user address of the index owner
   **/
  function updateUser(address user) public onlyOwner {
    userUpdateTime[user] = block.timestamp;
    prevIndex[block.timestamp] = getIndex();
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
   * Gets current value of the compounding index
   * It recalculates the value on-demand without updating the storage
   **/
  function getIndex() public view returns (uint256) {
    uint256 period = block.timestamp - indexUpdateTime;
    if (period > 0) {
      return index.wadToRay().rayMul(getCompoundedFactor(period)).rayToWad();
    } else {
      return index;
    }
  }

  /**
   * Gets the user value recalculated to the current index
   * It recalculates the value on-demand without updating the storage
   * Ray operations round up the result, but it is only an issue for very small values (with an order of magnitude
   * of 1 Wei)
   **/
  function getIndexedValue(uint256 value, address user) public view returns (uint256) {
    uint256 userTime = userUpdateTime[user];
    uint256 prevUserIndex = userTime == 0 ? BASE_RATE : prevIndex[userTime];

    return value.wadToRay().rayMul(getIndex().wadToRay()).rayDiv(prevUserIndex.wadToRay()).rayToWad();
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  function updateIndex() internal {
    prevIndex[indexUpdateTime] = index;

    index = getIndex();
    indexUpdateTime = block.timestamp;
  }

  /**
   * Returns compounded factor in Ray
   **/
  function getCompoundedFactor(uint256 period) internal view returns (uint256) {
    return ((rate.wadToRay() / SECONDS_IN_YEAR) + WadRayMath.ray()).rayPow(period);
  }

  /* ========== EVENTS ========== */

  /**
   * @dev updatedRate the value of updated rate
   **/
  event RateUpdated(uint256 updatedRate);
}

// SPDX-License-Identifier: UNLICENSED
// Last deployed using commit: ;
pragma solidity ^0.8.4;

/**
 * @title IRatesCalculator
 * @dev Interface defining base method for contracts implementing interest rates calculation.
 * The calculated value could be based on the relation between funds borrowed and deposited.
 */
interface IRatesCalculator {
  function calculateBorrowingRate(uint256 totalLoans, uint256 totalDeposits) external view returns (uint256);

  function calculateDepositRate(uint256 totalLoans, uint256 totalDeposits) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
// Last deployed using commit: ;
pragma solidity ^0.8.4;

/**
 * @title IBorrowersRegistry
 * Keeps a registry of created trading accounts to verify their borrowing rights
 */
interface IBorrowersRegistry {
  function canBorrow(address _account) external view returns (bool);

  function getLoanForOwner(address _owner) external view returns (address);

  function getOwnerOfLoan(address _loan) external view returns (address);
}

// SPDX-License-Identifier: AGPL3
pragma solidity ^0.8.4;

/******************
@title WadRayMath library
@author Aave
@dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
@dev https://github.com/aave/aave-protocol/blob/master/contracts/libraries/WadRayMath.sol
 */

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  function ray() internal pure returns (uint256) {
    return RAY;
  }

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    //return halfWAD.add(a.mul(b)).div(WAD);
    return (halfWAD + (a * b)) / WAD;
  }

  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;

    //return halfB.add(a.mul(WAD)).div(b);
    return (halfB + (a * WAD)) / b;
  }

  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    //return halfRAY.add(a.mul(b)).div(RAY);
    return (halfRAY + (a * b)) / RAY;
  }

  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;

    //return halfB.add(a.mul(RAY)).div(b);
    return (halfB + (a * RAY)) / b;
  }

  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;

    //return halfRatio.add(a).div(WAD_RAY_RATIO);
    return (halfRatio + a) / WAD_RAY_RATIO;
  }

  function wadToRay(uint256 a) internal pure returns (uint256) {
    //return a.mul(WAD_RAY_RATIO);
    return a * WAD_RAY_RATIO;
  }

  /**
   * @dev calculates base^exp. The code uses the ModExp precompile
   */
  //solium-disable-next-line
  function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rayMul(x, x);

      if (n % 2 != 0) {
        z = rayMul(z, x);
      }
    }
  }
}