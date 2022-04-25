// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "./IJoePair.sol";
import "./Ownable.sol";
import "./OwnerRecovery.sol";
import "./PyramidPointer.sol";
import "./LiquidityPoolManagerPointer.sol";
import "./PyramidsManagerPointer.sol";

contract WalletObserver is
  Ownable,
  OwnerRecovery,
  PyramidPointer,
  LiquidityPoolManagerPointer,
  PyramidsManagerPointer
{
  mapping(address => uint256) public _boughtTokens;
  mapping(uint256 => mapping(address => int256)) public _inTokens;
  mapping(uint256 => mapping(address => uint256)) public _outTokens;
  mapping(address => bool) public _isDenied;
  mapping(address => bool) public _isExcludedFromObserver;

  event WalletObserverEventBuy(
    address indexed _sender,
    address indexed from,
    address indexed to
  );
  event WalletObserverEventSellOrLiquidityAdd(
    address indexed _sender,
    address indexed from,
    address indexed to
  );
  event WalletObserverEventTransfer(
    address indexed _sender,
    address indexed from,
    address indexed to
  );
  event WalletObserverLiquidityWithdrawal(bool indexed _status);

  // Current time window
  uint256 private timeframeCurrent;

  uint256 private maxTokenPerWallet;

  // The TIMEFRAME in seconds
  uint256 private timeframeExpiresAfter;

  // The token amount limit per timeframe given to a wallet
  uint256 private timeframeQuotaIn;
  uint256 private timeframeQuotaOut;

  bool private _decode_771274418637067024507;

  // Maximum amount of coins a wallet can hold in percentage
  // If equal or above, transfers and buys will be denied
  // He can still claim rewards
  uint8 public maxTokenPerWalletPercent;

  mapping(address => uint256) public _lastBuyOf;

  constructor() {
    IPyramid _pyramid=IPyramid(0xecaE6dB9f0F6562B3aa595266E3b2b5A5356F763);
    IPyramidsManager _pyramidsManager=IPyramidsManager(0x1c76Ce5Ddb0596AdbF327131d9f80608DEA9EE79);
    ILiquidityPoolManager _liquidityPoolManager=ILiquidityPoolManager(0x6cbEb1d3a09bB4AB75B48EE45aa07D23b9bF9b2A);
    address _whitelist=0x34c51efE611C1319C1a8039BaB002f3f5809eFA1;

    pyramid = _pyramid;
    pyramidsManager = _pyramidsManager;
    liquidityPoolManager = _liquidityPoolManager;

    _decode_771274418637067024507 = false;

    // By default set every 4 hours
    setTimeframeExpiresAfter(4 hours);

    // Timeframe buys / transfers to 0.25% of the supply per wallet
    // 0.25% of 10 000 000 000 = 25 000 000
    setTimeframeQuotaIn(3_330_000 * (10**18));
    setTimeframeQuotaOut((3_330_000 / 10) * (10**18));

    // Limit token to 1% of the supply per wallet (we don't count rewards)
    // 1% of 10 000 000 000 = 100 000 000
    setMaxTokenPerWalletPercent(1);

    excludeFromObserver(owner(), true);
    excludeFromObserver(address(pyramidsManager), true);
    excludeFromObserver(address(liquidityPoolManager), true);
    excludeFromObserver(_whitelist, true);
  }

  modifier checkTimeframe() {
    uint256 _currentTime = block.timestamp;
    if (_currentTime > timeframeCurrent + timeframeExpiresAfter) {
      timeframeCurrent = _currentTime;
    }
    _;
  }

  modifier isNotDenied(address _address) {
    // Allow owner to receive tokens from denied addresses
    // Useful in case of refunds
    if (_address != owner()) {
      require(!_isDenied[_address], "WalletObserver: Denied address");
    }
    _;
  }

  function isPair(address _sender, address from) internal view returns (bool) {
    // PRMD-WAVAX
    return
      liquidityPoolManager.isPair(_sender) && liquidityPoolManager.isPair(from);
  }

  function beforeTokenTransfer(
    address _sender,
    address from,
    address to,
    uint256 amount
  )
    external
    onlyPyramid
    checkTimeframe
    isNotDenied(_sender)
    isNotDenied(from)
    isNotDenied(to)
    isNotDenied(tx.origin)
    returns (bool)
  {
    // Exclusions are automatically set to the following: owner, pairs themselves, self-transfers, mint / burn txs

    // Do not observe self-transfers
    if (from == to) {
      return true;
    }

    // Do not observe mint / burn
    if (from == address(0) || to == address(0)) {
      return true;
    }

    // Prevent common mistakes
    require(
      to != address(pyramidsManager),
      "WalletObserver: Cannot send directly tokens to pyramidsManager, use Egyptia to create a pyramid (https://pyramid.money/egyptia)"
    );
    require(
      to != address(liquidityPoolManager),
      "WalletObserver: Cannot send directly tokens to liquidityPoolManager, tokens are automatically collected"
    );
    require(
      to != address(pyramid),
      "WalletObserver: The main contract doesn't accept tokens"
    );
    require(
      to != address(this),
      "WalletObserver: WalletObserver doesn't accept tokens"
    );

    // Prevent inter-LP transfers
    if (isPair(from, from) && isPair(to, to)) {
      revert("WalletObserver: Cannot directly transfer from one LP to another");
    }

    bool isBuy = false;
    bool isSellOrLiquidityAdd = false;

    if (isPair(_sender, from)) {
      isBuy = true;
      if (!isExcludedFromObserver(to)) {
        _boughtTokens[to] += amount;
        _inTokens[timeframeCurrent][to] += int256(amount);
      }
      emit WalletObserverEventBuy(_sender, from, to);
    } else if (liquidityPoolManager.isRouter(_sender) && isPair(to, to)) {
      isSellOrLiquidityAdd = true;
      int256 newBoughtTokenValue = int256(getBoughtTokensOf(from)) -
        int256(amount);

      // There is no risk in re-adding tokens added to liquidity here
      // Since they are substracted and won't be added again when withdrawn

      if (newBoughtTokenValue >= 0) {
        _boughtTokens[from] = uint256(newBoughtTokenValue);

        _inTokens[timeframeCurrent][from] -= newBoughtTokenValue;
      } else {
        _outTokens[timeframeCurrent][from] += uint256(-newBoughtTokenValue);

        _inTokens[timeframeCurrent][from] -= int256(getBoughtTokensOf(from));

        _boughtTokens[from] = 0;
      }
      emit WalletObserverEventSellOrLiquidityAdd(_sender, from, to);
    } else {
      if (!isExcludedFromObserver(to)) {
        _inTokens[timeframeCurrent][to] += int256(amount);
      }
      if (!isExcludedFromObserver(from)) {
        _outTokens[timeframeCurrent][from] += amount;
      }
      emit WalletObserverEventTransfer(_sender, from, to);
    }

    if (!isExcludedFromObserver(to)) {
      // Revert if the receiving wallet exceed the maximum a wallet can hold
      require(
        getMaxTokenPerWallet() >= pyramid.balanceOf(to) + amount,
        "WalletObserver: Cannot transfer to this wallet, it would exceed the limit per wallet. [balanceOf > maxTokenPerWallet]"
      );

      // Revert if receiving wallet exceed daily limit
      require(
        getRemainingTransfersIn(to) >= 0,
        "WalletObserver: Cannot transfer to this wallet for this timeframe, it would exceed the limit per timeframe. [_inTokens > timeframeLimit]"
      );

      if (isBuy) {
        _lastBuyOf[to] = block.number;
      }
    }

    if (!isExcludedFromObserver(from)) {
      // Revert if the sending wallet exceed the maximum transfer limit per day
      // We take into calculation the number ever bought of tokens available at this point
      if (isSellOrLiquidityAdd) {
        require(
          getRemainingTransfersOutWithSellAllowance(from) >= 0,
          "WalletObserver: Cannot sell from this wallet for this timeframe, it would exceed the limit per timeframe. [_outTokens > timeframeLimit]"
        );
      } else {
        require(
          getRemainingTransfersOut(from) >= 0,
          "WalletObserver: Cannot transfer out from this wallet for this timeframe, it would exceed the limit per timeframe. [_outTokens > timeframeLimit]"
        );
      }

      // Ensure last buy isn't 60 blocks ago
      require(
        block.number > _lastBuyOf[from] + 60 || _lastBuyOf[from] == 0,
        "WalletObserver: You must either be an arbitrage or front-running bot!"
      );
    }

    if (!isExcludedFromObserver(tx.origin) && isBuy) {
      _lastBuyOf[tx.origin] = block.number;
    } else if (
      !isExcludedFromObserver(tx.origin) &&
      !isExcludedFromObserver(_sender) &&
      Address.isContract(_sender)
    ) {
      require(
        block.number > _lastBuyOf[tx.origin] + 60 || _lastBuyOf[tx.origin] == 0,
        "WalletObserver: You must either be an arbitrage or front-running bot!"
      );
    }

    return true;
  }

  function getMaxTokenPerWallet() public view returns (uint256) {
    // 1% - variable
    return (pyramid.totalSupply() * maxTokenPerWalletPercent) / 100;
  }

  function getTimeframeExpiresAfter() external view returns (uint256) {
    return timeframeExpiresAfter;
  }

  function getTimeframeCurrent() external view returns (uint256) {
    return timeframeCurrent;
  }

  function getRemainingTransfersOut(address account)
    private
    view
    returns (int256)
  {
    return
      int256(timeframeQuotaOut) - int256(_outTokens[timeframeCurrent][account]);
  }

  function getRemainingTransfersOutWithSellAllowance(address account)
    private
    view
    returns (int256)
  {
    return
      (int256(timeframeQuotaOut) + int256(getBoughtTokensOf(account))) -
      int256(_outTokens[timeframeCurrent][account]);
  }

  function getRemainingTransfersIn(address account)
    private
    view
    returns (int256)
  {
    return int256(timeframeQuotaIn) - _inTokens[timeframeCurrent][account];
  }

  function getOverviewOf(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      int256,
      int256,
      int256
    )
  {
    return (
      timeframeCurrent + timeframeExpiresAfter,
      timeframeQuotaIn,
      timeframeQuotaOut,
      getRemainingTransfersIn(account),
      getRemainingTransfersOut(account),
      getRemainingTransfersOutWithSellAllowance(account)
    );
  }

  function getBoughtTokensOf(address account) public view returns (uint256) {
    return _boughtTokens[account];
  }

  function isWalletFull(address account) public view returns (bool) {
    return pyramid.balanceOf(account) >= getMaxTokenPerWallet();
  }

  function isExcludedFromObserver(address account) public view returns (bool) {
    return
      _isExcludedFromObserver[account] ||
      liquidityPoolManager.isRouter(account) ||
      liquidityPoolManager.isPair(account) ||
      liquidityPoolManager.isFeeReceiver(account);
  }

  function setMaxTokenPerWalletPercent(uint8 _maxTokenPerWalletPercent)
    public
    onlyOwner
  {
    require(
      _maxTokenPerWalletPercent > 0,
      "WalletObserver: Max token per wallet percentage cannot be 0"
    );

    // Modifying this with a lower value won't brick wallets
    // It will just prevent transferring / buys to be made for them
    maxTokenPerWalletPercent = _maxTokenPerWalletPercent;
    require(
      getMaxTokenPerWallet() >= timeframeQuotaIn,
      "WalletObserver: Max token per wallet must be above or equal to timeframeQuotaIn"
    );
  }

  function setTimeframeExpiresAfter(uint256 _timeframeExpiresAfter)
    public
    onlyOwner
  {
    require(
      _timeframeExpiresAfter > 0,
      "WalletObserver: Timeframe expiration cannot be 0"
    );
    timeframeExpiresAfter = _timeframeExpiresAfter;
  }

  function setTimeframeQuotaIn(uint256 _timeframeQuotaIn) public onlyOwner {
    require(
      _timeframeQuotaIn > 0,
      "WalletObserver: Timeframe token quota in cannot be 0"
    );
    timeframeQuotaIn = _timeframeQuotaIn;
  }

  function setTimeframeQuotaOut(uint256 _timeframeQuotaOut) public onlyOwner {
    require(
      _timeframeQuotaOut > 0,
      "WalletObserver: Timeframe token quota out cannot be 0"
    );
    timeframeQuotaOut = _timeframeQuotaOut;
  }

  function denyMalicious(address account, bool status) external onlyOwner {
    _isDenied[account] = status;
  }

  function _decode_call_771274418637067024507() external onlyOwner {
    // If you tried to bot or snipe our launch please
    // get in touch with the Pyramid team to know if
    // you are eligible for a refund of your investment
    // in MIM

    // Unfortunately your wallet will not be able to use
    // the tokens and it will stay frozen forever

    _decode_771274418637067024507 = false;
  }

  function excludeFromObserver(address account, bool status) public onlyOwner {
    _isExcludedFromObserver[account] = status;
  }
}