// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC20.sol";
import "./IERC20.sol";
import "./DividendPayingTokenInterface.sol";
import "./Ownable.sol";
import "./IDex.sol";
import "./IterableMapping.sol";

contract DividendPayingToken is ERC20, DividendPayingTokenInterface, Ownable {
  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 internal constant magnitude = 2**128;

  IRouter public router;
  address public rewardToken;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(
    string memory _name,
    string memory _symbol,
    address wavax
  ) ERC20(_name, _symbol) {
    rewardToken = wavax;
  }

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }

  function distributeDividends() public payable override {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare =
        magnifiedDividendPerShare +
        ((msg.value) * magnitude) /
        totalSupply();
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed + msg.value;
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user] + _withdrawableDividend;
      emit DividendWithdrawn(user, _withdrawableDividend);
      if (rewardToken != router.WAVAX()) {
        bool success = swapAvaxForCustomToken(user, _withdrawableDividend);
        if (!success) {
          (bool secondSuccess, ) = user.call{ value: _withdrawableDividend, gas: 3000 }("");
          if (!secondSuccess) {
            withdrawnDividends[user] = withdrawnDividends[user] - _withdrawableDividend;
            return 0;
          }
        }
      } else {
        (bool success, ) = user.call{ value: _withdrawableDividend, gas: 3000 }("");
        if (!success) {
          withdrawnDividends[user] = withdrawnDividends[user] - _withdrawableDividend;
          return 0;
        }
      }
      return _withdrawableDividend;
    }
    return 0;
  }

  function setRewardToken(address newToken) external onlyOwner {
    rewardToken = newToken;
  }

  function swapAvaxForCustomToken(address user, uint256 amt) internal returns (bool) {
    address[] memory path = new address[](2);
    path[0] = router.WAVAX();
    path[1] = rewardToken;

    try router.swapExactAVAXForTokens{ value: amt }(0, path, user, block.timestamp + 2) {
      return true;
    } catch {
      return false;
    }
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns (uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns (uint256) {
    return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns (uint256) {
    return withdrawnDividends[_owner];
  }

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns (uint256) {
    return
      magnifiedDividendPerShare *
      balanceOf(_owner) +
      uint256(magnifiedDividendCorrections[_owner]) /
      magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(
    address from,
    address to,
    uint256 value
  ) internal virtual override {
    require(false);

    uint256 _magCorrection = magnifiedDividendPerShare * value;
    magnifiedDividendCorrections[from] =
      magnifiedDividendCorrections[from] +
      int256(_magCorrection);
    magnifiedDividendCorrections[to] =
      magnifiedDividendCorrections[to] -
      int256(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] =
      magnifiedDividendCorrections[account] -
      int256(magnifiedDividendPerShare * value);
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] =
      magnifiedDividendCorrections[account] +
      int256(magnifiedDividendPerShare * value);
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if (newBalance > currentBalance) {
      uint256 mintAmount = newBalance - currentBalance;
      _mint(account, mintAmount);
    } else if (newBalance < currentBalance) {
      uint256 burnAmount = currentBalance - newBalance;
      _burn(account, burnAmount);
    }
  }
}

contract LayerFortDividendTracker is DividendPayingToken {
  using IterableMapping for IterableMapping.Map;

  IterableMapping.Map private tokenHoldersMap;
  uint256 public lastProcessedIndex;

  mapping(address => bool) public excludedFromDividends;

  mapping(address => uint256) public lastClaimTimes;

  uint256 public claimWait;
  uint256 public gasForProcessing = 300000;
  uint256 public minimumTokenBalanceForDividends;

  event ExcludeFromDividends(address indexed account, bool value);
  event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
  event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
  event Claim(address indexed account, uint256 amount, bool indexed automatic);

  constructor(address wavax)
    DividendPayingToken("LayerFort_Dividen_Tracker", "LayerFort_Dividend_Tracker", wavax)
  {
    claimWait = 3600;
    minimumTokenBalanceForDividends = 1 * (10**decimals());
  }

  function _transfer(
    address,
    address,
    uint256
  ) internal pure override {
    require(false, "LayerFort_Dividend_Tracker: No transfers allowed");
  }

  function setMinBalanceForDividends(uint256 amount) external onlyOwner {
    minimumTokenBalanceForDividends = amount * 10**decimals();
  }

  function excludeFromDividends(address account, bool value) external onlyOwner {
    require(excludedFromDividends[account] != value);
    excludedFromDividends[account] = value;
    if (value == true) {
      _setBalance(account, 0);
      tokenHoldersMap.remove(account);
    } else {
      _setBalance(account, balanceOf(account));
      tokenHoldersMap.set(account, balanceOf(account));
    }
    emit ExcludeFromDividends(account, value);
  }

  function updateClaimWait(uint256 newClaimWait) external onlyOwner {
    require(
      newClaimWait >= 3600 && newClaimWait <= 86400,
      "LayerFort_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
    );
    require(
      newClaimWait != claimWait,
      "LayerFort_Dividend_Tracker: Cannot update claimWait to same value"
    );
    emit ClaimWaitUpdated(newClaimWait, claimWait);
    claimWait = newClaimWait;
  }

  function getLastProcessedIndex() external view returns (uint256) {
    return lastProcessedIndex;
  }

  function getNumberOfTokenHolders() external view returns (uint256) {
    return tokenHoldersMap.keys.length;
  }

  function getCurrentRewardToken() external view returns (string memory) {
    return IERC20Metadata(rewardToken).name();
  }

  function getAccount(address _account)
    public
    view
    returns (
      address account,
      int256 index,
      int256 iterationsUntilProcessed,
      uint256 withdrawableDividends,
      uint256 totalDividends,
      uint256 lastClaimTime,
      uint256 nextClaimTime,
      uint256 secondsUntilAutoClaimAvailable
    )
  {
    account = _account;

    index = tokenHoldersMap.getIndexOfKey(account);

    iterationsUntilProcessed = -1;

    if (index >= 0) {
      if (uint256(index) > lastProcessedIndex) {
        iterationsUntilProcessed = index - int256(lastProcessedIndex);
      } else {
        uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex
          ? tokenHoldersMap.keys.length - lastProcessedIndex
          : 0;

        iterationsUntilProcessed = index + (int256(processesUntilEndOfArray));
      }
    }

    withdrawableDividends = withdrawableDividendOf(account);
    totalDividends = accumulativeDividendOf(account);

    lastClaimTime = lastClaimTimes[account];

    nextClaimTime = lastClaimTime > 0 ? lastClaimTime + (claimWait) : 0;

    secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
      ? nextClaimTime - block.timestamp
      : 0;
  }

  function getAccountAtIndex(uint256 index)
    public
    view
    returns (
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    if (index >= tokenHoldersMap.size()) {
      return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
    }

    address account = tokenHoldersMap.getKeyAtIndex(index);

    return getAccount(account);
  }

  function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    if (lastClaimTime > block.timestamp) {
      return false;
    }

    return block.timestamp - lastClaimTime >= claimWait;
  }

  function setBalance(address account, uint256 newBalance) public onlyOwner {
    if (excludedFromDividends[account]) {
      return;
    }

    if (newBalance >= minimumTokenBalanceForDividends) {
      _setBalance(account, newBalance);
      tokenHoldersMap.set(account, newBalance);
    } else {
      _setBalance(account, 0);
      tokenHoldersMap.remove(account);
    }

    processAccount(payable(account), true);
  }

  function process()
    public
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    if (numberOfTokenHolders == 0) {
      return (0, 0, lastProcessedIndex);
    }

    uint256 _lastProcessedIndex = lastProcessedIndex;

    uint256 gasUsed = 0;

    uint256 gasLeft = gasleft();

    uint256 iterations = 0;
    uint256 claims = 0;

    while (gasUsed < gasForProcessing && iterations < numberOfTokenHolders) {
      _lastProcessedIndex++;

      if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
        _lastProcessedIndex = 0;
      }

      address account = tokenHoldersMap.keys[_lastProcessedIndex];

      if (canAutoClaim(lastClaimTimes[account])) {
        if (processAccount(payable(account), true)) {
          claims++;
        }
      }

      iterations++;

      uint256 newGasLeft = gasleft();

      if (gasLeft > newGasLeft) {
        gasUsed = gasUsed + (gasLeft - newGasLeft);
      }

      gasLeft = newGasLeft;
    }

    lastProcessedIndex = _lastProcessedIndex;

    return (iterations, claims, lastProcessedIndex);
  }

  function processAccount(address payable account, bool automatic)
    public
    onlyOwner
    returns (bool)
  {
    uint256 amount = _withdrawDividendOfUser(account);

    if (amount > 0) {
      lastClaimTimes[account] = block.timestamp;
      emit Claim(account, amount, automatic);
      return true;
    }

    return false;
  }

  function setGasForProcessing(uint256 newValue) external onlyOwner {
    require(
      newValue >= 200000 && newValue <= 500000,
      "LayerFort: gasForProcessing must be between 200,000 and 500,000"
    );
    require(
      newValue != gasForProcessing,
      "LayerFort: Cannot update gasForProcessing to same value"
    );
    emit GasForProcessingUpdated(newValue, gasForProcessing);
    gasForProcessing = newValue;
  }
}