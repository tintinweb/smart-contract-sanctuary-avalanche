// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

// coefficients for sigmoids: α / (1 + e^( (β-x) / γ))
// alpha1 + alpha2 + baseFee must be <= type(uint16).max
struct AlgebraFeeConfiguration {
  uint16 alpha1; // max value of the first sigmoid
  uint16 alpha2; // max value of the second sigmoid
  uint32 beta1; // shift along the x-axis for the first sigmoid
  uint32 beta2; // shift along the x-axis for the second sigmoid
  uint16 gamma1; // horizontal stretch factor for the first sigmoid
  uint16 gamma2; // horizontal stretch factor for the second sigmoid
  uint16 baseFee; // minimum possible fee
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import '../base/AlgebraFeeConfiguration.sol';

/// @title The interface for the Algebra Factory
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraFactory {
  /// @notice Emitted when a process of ownership renounce is started
  /// @param timestamp The timestamp of event
  /// @param finishTimestamp The timestamp when ownership renounce will be possible to finish
  event RenounceOwnershipStart(uint256 timestamp, uint256 finishTimestamp);

  /// @notice Emitted when a process of ownership renounce cancelled
  /// @param timestamp The timestamp of event
  event RenounceOwnershipStop(uint256 timestamp);

  /// @notice Emitted when a process of ownership renounce finished
  /// @param timestamp The timestamp of ownership renouncement
  event RenounceOwnershipFinish(uint256 timestamp);

  /// @notice Emitted when a pool is created
  /// @param token0 The first token of the pool by address sort order
  /// @param token1 The second token of the pool by address sort order
  /// @param pool The address of the created pool
  event Pool(address indexed token0, address indexed token1, address pool);

  /// @notice Emitted when the farming address is changed
  /// @param newFarmingAddress The farming address after the address was changed
  event FarmingAddress(address indexed newFarmingAddress);

  /// @notice Emitted when the default fee configuration is changed
  /// @param newConfig The structure with dynamic fee parameters
  /// @dev See the AdaptiveFee library for more details
  event DefaultFeeConfiguration(AlgebraFeeConfiguration newConfig);

  /// @notice Emitted when the default community fee is changed
  /// @param newDefaultCommunityFee The new default community fee value
  event DefaultCommunityFee(uint8 newDefaultCommunityFee);

  /// @notice role that can change communityFee and tickspacing in pools
  function POOLS_ADMINISTRATOR_ROLE() external view returns (bytes32);

  /// @dev Returns `true` if `account` has been granted `role` or `account` is owner.
  function hasRoleOrOwner(bytes32 role, address account) external view returns (bool);

  /// @notice Returns the current owner of the factory
  /// @dev Can be changed by the current owner via transferOwnership(address newOwner)
  /// @return The address of the factory owner
  function owner() external view returns (address);

  /// @notice Returns the current poolDeployerAddress
  /// @return The address of the poolDeployer
  function poolDeployer() external view returns (address);

  /// @dev Is retrieved from the pools to restrict calling certain functions not by a tokenomics contract
  /// @return The tokenomics contract address
  function farmingAddress() external view returns (address);

  /// @notice Returns the current communityVaultAddress
  /// @return The address to which community fees are transferred
  function communityVault() external view returns (address);

  /// @notice Returns the default community fee
  /// @return Fee which will be set at the creation of the pool
  function defaultCommunityFee() external view returns (uint8);

  /// @notice Returns the pool address for a given pair of tokens, or address 0 if it does not exist
  /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
  /// @param tokenA The contract address of either token0 or token1
  /// @param tokenB The contract address of the other token
  /// @return pool The pool address
  function poolByPair(address tokenA, address tokenB) external view returns (address pool);

  /// @return timestamp The timestamp of the beginning of the renounceOwnership process
  function renounceOwnershipStartTimestamp() external view returns (uint256 timestamp);

  /// @notice Creates a pool for the given two tokens
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0.
  /// The call will revert if the pool already exists or the token arguments are invalid.
  /// @return pool The address of the newly created pool
  function createPool(address tokenA, address tokenB) external returns (address pool);

  /// @dev updates tokenomics address on the factory
  /// @param newFarmingAddress The new tokenomics contract address
  function setFarmingAddress(address newFarmingAddress) external;

  /// @dev updates default community fee for new pools
  /// @param newDefaultCommunityFee The new community fee, _must_ be <= MAX_COMMUNITY_FEE
  function setDefaultCommunityFee(uint8 newDefaultCommunityFee) external;

  /// @notice Changes initial fee configuration for new pools
  /// @dev changes coefficients for sigmoids: α / (1 + e^( (β-x) / γ))
  /// alpha1 + alpha2 + baseFee (max possible fee) must be <= type(uint16).max and gammas must be > 0
  /// @param newConfig new default fee configuration. See the #AdaptiveFee.sol library for details
  function setDefaultFeeConfiguration(AlgebraFeeConfiguration calldata newConfig) external;

  /// @notice Starts process of renounceOwnership. After that, a certain period
  /// of time must pass before the ownership renounce can be completed.
  function startRenounceOwnership() external;

  /// @notice Stops process of renounceOwnership and removes timer.
  function stopRenounceOwnership() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IAlgebraPoolImmutables.sol';
import './pool/IAlgebraPoolState.sol';
import './pool/IAlgebraPoolDerivedState.sol';
import './pool/IAlgebraPoolActions.sol';
import './pool/IAlgebraPoolPermissionedActions.sol';
import './pool/IAlgebraPoolEvents.sol';

/// @title The interface for a Algebra Pool
/// @dev The pool interface is broken up into many smaller pieces.
/// Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPool is
  IAlgebraPoolImmutables,
  IAlgebraPoolState,
  IAlgebraPoolDerivedState,
  IAlgebraPoolActions,
  IAlgebraPoolPermissionedActions,
  IAlgebraPoolEvents
{
  // used only for combining interfaces
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title An interface for a contract that is capable of deploying Algebra Pools
/// @notice A contract that constructs a pool must implement this to pass arguments to the pool
/// @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
/// of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain.
/// Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolDeployer {
  /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
  /// @dev Called by the pool constructor to fetch the parameters of the pool
  /// @return dataStorage The pools associated dataStorage
  /// @return factory The factory address
  /// @return communityVault The community vault address
  /// @return token0 The first token of the pool by address sort order
  /// @return token1 The second token of the pool by address sort order
  function getDeployParameters() external view returns (address dataStorage, address factory, address communityVault, address token0, address token1);

  /// @dev Deploys a pool with the given parameters by transiently setting the parameters in cache.
  /// @param dataStorage The pools associated dataStorage
  /// @param token0 The first token of the pool by address sort order
  /// @param token1 The second token of the pool by address sort order
  /// @return pool The deployed pool's address
  function deploy(address dataStorage, address token0, address token1) external returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

/// @title Errors emitted by a pool
/// @notice Contains custom errors emitted by the pool
interface IAlgebraPoolErrors {
  // ####  pool errors  ####

  /// @notice Emitted by the reentrancy guard
  error locked();

  /// @notice Emitted if arithmetic error occurred
  error arithmeticError();

  /// @notice Emitted if an attempt is made to initialize the pool twice
  error alreadyInitialized();

  /// @notice Emitted if 0 is passed as amountRequired to swap function
  error zeroAmountRequired();

  /// @notice Emitted if invalid amount is passed as amountRequired to swapSupportingFeeOnInputTokens function
  error invalidAmountRequired();

  /// @notice Emitted if the pool received fewer tokens than it should have
  error insufficientInputAmount();
  /// @notice Emitted if the pool received fewer tokens than it should have to mint calculated actual liquidity
  error insufficientAmountReceivedAtMint();

  /// @notice Emitted if there was an attempt to mint zero liquidity
  error zeroLiquidityDesired();
  /// @notice Emitted if actual amount of liquidity is zero (due to insufficient amount of tokens received)
  error zeroLiquidityActual();

  /// @notice Emitted if the pool received fewer tokens{0,1} after flash than it should have
  error flashInsufficientPaid0();
  error flashInsufficientPaid1();

  /// @notice Emitted if limitSqrtPrice param is incorrect
  error invalidLimitSqrtPrice();

  /// @notice Tick must be divisible by tickspacing
  error tickIsNotSpaced();

  /// @notice Emitted if a method is called that is accessible only to the factory owner or dedicated role
  error notAllowed();
  /// @notice Emitted if a method is called that is accessible only to the farming
  error onlyFarming();

  error invalidNewTickSpacing();
  error invalidNewCommunityFee();

  // ####  LimitOrder errors  ####
  /// @notice Emitted if tick is too low/high for limit order
  error invalidTickForLimitOrder();
  /// @notice Emitted if amount is too high for limit order
  error invalidAmountForLimitOrder();

  // ####  LiquidityMath errors  ####
  /// @notice Emitted if liquidity underflows
  error liquiditySub();
  /// @notice Emitted if liquidity overflows
  error liquidityAdd();

  // ####  TickManagement errors  ####
  error topTickLowerThanBottomTick();
  error bottomTickLowerThanMIN();
  error topTickAboveMAX();
  error liquidityOverflow();
  error tickIsNotInitialized();
  error tickInvalidLinks();

  // ####  SafeTransfer errors  ####
  error transferFailed();

  // ####  TickMath errors  ####
  error tickOutOfRange();
  error priceOutOfRange();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the virtual pool
/// @dev Used to calculate active liquidity in farmings
interface IAlgebraVirtualPool {
  /// @dev This function is called by the main pool if an initialized ticks are crossed by swap.
  /// If any one of crossed ticks is also initialized in a virtual pool it should be crossed too
  /// @param targetTick The target tick up to which we need to cross all active ticks
  /// @param zeroToOne The direction
  function crossTo(int24 targetTick, bool zeroToOne) external returns (bool success);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Algebra
/// @notice Contains a subset of the full ERC20 interface that is used in Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IERC20Minimal {
  /// @notice Returns the balance of a token
  /// @param account The account for which to look up the number of tokens it has, i.e. its balance
  /// @return The number of tokens held by the account
  function balanceOf(address account) external view returns (uint256);

  /// @notice Transfers the amount of token from the `msg.sender` to the recipient
  /// @param recipient The account that will receive the amount transferred
  /// @param amount The number of tokens to send from the sender to the recipient
  /// @return Returns true for a successful transfer, false for an unsuccessful transfer
  function transfer(address recipient, uint256 amount) external returns (bool);

  /// @notice Returns the current allowance given to a spender by an owner
  /// @param owner The account of the token owner
  /// @param spender The account of the token spender
  /// @return The current allowance granted by `owner` to `spender`
  function allowance(address owner, address spender) external view returns (uint256);

  /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
  /// @param spender The account which will be allowed to spend a given amount of the owners tokens
  /// @param amount The amount of tokens allowed to be used by `spender`
  /// @return Returns true for a successful approval, false for unsuccessful
  function approve(address spender, uint256 amount) external returns (bool);

  /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
  /// @param sender The account from which the transfer will be initiated
  /// @param recipient The recipient of the transfer
  /// @param amount The amount of the transfer
  /// @return Returns true for a successful transfer, false for unsuccessful
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
  /// @param from The account from which the tokens were sent, i.e. the balance decreased
  /// @param to The account to which the tokens were sent, i.e. the balance increased
  /// @param value The amount of tokens that were transferred
  event Transfer(address indexed from, address indexed to, uint256 value);

  /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
  /// @param owner The account that approved spending of its tokens
  /// @param spender The account for which the spending allowance was modified
  /// @param value The new allowance from the owner to the spender
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolActions {
  /// @notice Sets the initial price for the pool
  /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
  /// @dev Initialization should be done in one transaction with pool creation to avoid front-running
  /// @param price the initial sqrt price of the pool as a Q64.96
  function initialize(uint160 price) external;

  /// @notice Adds liquidity for the given recipient/bottomTick/topTick position
  /// @dev The caller of this method receives a callback in the form of IAlgebraMintCallback# AlgebraMintCallback
  /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
  /// on bottomTick, topTick, the amount of liquidity, and the current price. If bottomTick == topTick position is treated as a limit order
  /// @param sender The address which will receive potential surplus of paid tokens
  /// @param recipient The address for which the liquidity will be created
  /// @param bottomTick The lower tick of the position in which to add liquidity
  /// @param topTick The upper tick of the position in which to add liquidity
  /// @param amount The desired amount of liquidity to mint
  /// @param data Any data that should be passed through to the callback
  /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
  /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
  /// @return liquidityActual The actual minted amount of liquidity
  function mint(
    address sender,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount,
    bytes calldata data
  ) external returns (uint256 amount0, uint256 amount1, uint128 liquidityActual);

  /// @notice Collects tokens owed to a position
  /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
  /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
  /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
  /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
  /// @param recipient The address which should receive the fees collected
  /// @param bottomTick The lower tick of the position for which to collect fees
  /// @param topTick The upper tick of the position for which to collect fees
  /// @param amount0Requested How much token0 should be withdrawn from the fees owed
  /// @param amount1Requested How much token1 should be withdrawn from the fees owed
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function collect(
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
  /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
  /// @dev Fees must be collected separately via a call to #collect
  /// @param bottomTick The lower tick of the position for which to burn liquidity
  /// @param topTick The upper tick of the position for which to burn liquidity
  /// @param amount How much liquidity to burn
  /// @return amount0 The amount of token0 sent to the recipient
  /// @return amount1 The amount of token1 sent to the recipient
  function burn(int24 bottomTick, int24 topTick, uint128 amount) external returns (uint256 amount0, uint256 amount1);

  /// @notice Swap token0 for token1, or token1 for token0
  /// @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback#AlgebraSwapCallback
  /// @param recipient The address to receive the output of the swap
  /// @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountRequired The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
  /// @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
  /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
  /// @param data Any data to be passed through to the callback. If using the Router it should contain SwapRouter#SwapCallbackData
  /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
  /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
  function swap(
    address recipient,
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /// @notice Swap token0 for token1, or token1 for token0 (tokens that have fee on transfer)
  /// @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback#AlgebraSwapCallback
  /// @param sender The address called this function (Comes from the Router)
  /// @param recipient The address to receive the output of the swap
  /// @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountRequired The amount of the swap, which implicitly configures the swap as exact input
  /// @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
  /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
  /// @param data Any data to be passed through to the callback. If using the Router it should contain SwapRouter#SwapCallbackData
  /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
  /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
  function swapSupportingFeeOnInputTokens(
    address sender,
    address recipient,
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
  /// @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback#AlgebraFlashCallback
  /// @dev All excess tokens paid in the callback are distributed to currently in-range liquidity providers as an additional fee.
  /// If there are no in-range liquidity providers, the fee will be transferred to the first active provider in the future
  /// @param recipient The address which will receive the token0 and token1 amounts
  /// @param amount0 The amount of token0 to send
  /// @param amount1 The amount of token1 to send
  /// @param data Any data to be passed through to the callback
  function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolDerivedState {
  /// @notice Returns a snapshot of seconds per liquidity and seconds inside a tick range
  /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
  /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
  /// snapshot is taken and the second snapshot is taken.
  /// @param bottomTick The lower tick of the range
  /// @param topTick The upper tick of the range
  /// @return innerSecondsSpentPerLiquidity The snapshot of seconds per liquidity for the range
  /// @return innerSecondsSpent The snapshot of the number of seconds during which the price was in this range
  function getInnerCumulatives(
    int24 bottomTick,
    int24 topTick
  ) external view returns (uint160 innerSecondsSpentPerLiquidity, uint32 innerSecondsSpent);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolEvents {
  /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
  /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
  /// @param price The initial sqrt price of the pool, as a Q64.96
  /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
  event Initialize(uint160 price, int24 tick);

  /// @notice Emitted when liquidity is minted for a given position
  /// @dev If the top and bottom ticks match, this should be treated as a limit order
  /// @param sender The address that minted the liquidity
  /// @param owner The owner of the position and recipient of any minted liquidity
  /// @param bottomTick The lower tick of the position
  /// @param topTick The upper tick of the position
  /// @param liquidityAmount The amount of liquidity minted to the position range
  /// @param amount0 How much token0 was required for the minted liquidity
  /// @param amount1 How much token1 was required for the minted liquidity
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed bottomTick,
    int24 indexed topTick,
    uint128 liquidityAmount,
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Emitted when fees are collected by the owner of a position
  /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
  /// @param owner The owner of the position for which fees are collected
  /// @param recipient The address that received fees
  /// @param bottomTick The lower tick of the position
  /// @param topTick The upper tick of the position
  /// @param amount0 The amount of token0 fees collected
  /// @param amount1 The amount of token1 fees collected
  event Collect(address indexed owner, address recipient, int24 indexed bottomTick, int24 indexed topTick, uint128 amount0, uint128 amount1);

  /// @notice Emitted when a position's liquidity is removed
  /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
  /// @param owner The owner of the position for which liquidity is removed
  /// @param bottomTick The lower tick of the position
  /// @param topTick The upper tick of the position
  /// @param liquidityAmount The amount of liquidity to remove
  /// @param amount0 The amount of token0 withdrawn
  /// @param amount1 The amount of token1 withdrawn
  event Burn(address indexed owner, int24 indexed bottomTick, int24 indexed topTick, uint128 liquidityAmount, uint256 amount0, uint256 amount1);

  /// @notice Emitted by the pool for any swaps between token0 and token1
  /// @param sender The address that initiated the swap call, and that received the callback
  /// @param recipient The address that received the output of the swap
  /// @param amount0 The delta of the token0 balance of the pool
  /// @param amount1 The delta of the token1 balance of the pool
  /// @param price The sqrt(price) of the pool after the swap, as a Q64.96
  /// @param liquidity The liquidity of the pool after the swap
  /// @param tick The log base 1.0001 of price of the pool after the swap
  event Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 price, uint128 liquidity, int24 tick);

  /// @notice Emitted by the pool for any flashes of token0/token1
  /// @param sender The address that initiated the swap call, and that received the callback
  /// @param recipient The address that received the tokens from flash
  /// @param amount0 The amount of token0 that was flashed
  /// @param amount1 The amount of token1 that was flashed
  /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
  /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
  event Flash(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1);

  /// @notice Emitted when the community fee is changed by the pool
  /// @param communityFeeNew The updated value of the community fee in thousandths (1e-3)
  event CommunityFee(uint8 communityFeeNew);

  /// @notice Emitted when the tick spacing changes
  /// @param newTickSpacing The updated value of the new tick spacing
  /// @param newTickSpacingLimitOrders The updated value of the new tick spacing for limit orders
  event TickSpacing(int24 newTickSpacing, int24 newTickSpacingLimitOrders);

  /// @notice Emitted when new activeIncentive is set
  /// @param newIncentiveAddress The address of the new incentive
  event Incentive(address indexed newIncentiveAddress);

  /// @notice Emitted when the fee changes inside the pool
  /// @param fee The current fee in hundredths of a bip, i.e. 1e-6
  event Fee(uint16 fee);

  /// @notice Emitted in case of an error when trying to write to the DataStorage
  /// @dev This shouldn't happen
  event DataStorageFailure();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolImmutables {
  /// @notice The contract that stores all the timepoints and can perform actions with them
  /// @return The operator address
  function dataStorageOperator() external view returns (address);

  /// @notice The contract that deployed the pool, which must adhere to the IAlgebraFactory interface
  /// @return The contract address
  function factory() external view returns (address);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (address);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (address);

  /// @notice The contract to which community fees are transferred
  /// @return The communityVault address
  function communityVault() external view returns (address);

  /// @notice The maximum amount of position liquidity that can use any tick in the range
  /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by permissioned addresses
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolPermissionedActions {
  /// @notice Set the community's % share of the fees. Cannot exceed 25% (250). Only factory owner or POOLS_ADMINISTRATOR_ROLE role
  /// @param communityFee new community fee percent in thousandths (1e-3)
  function setCommunityFee(uint8 communityFee) external;

  /// @notice Set the new tick spacing values. Only factory owner or POOLS_ADMINISTRATOR_ROLE role
  /// @param newTickSpacing The new tick spacing value
  /// @param newTickSpacingLimitOrders The new tick spacing value for limit orders
  function setTickSpacing(int24 newTickSpacing, int24 newTickSpacingLimitOrders) external;

  /// @notice Sets an active incentive. Only farming
  /// @param newIncentiveAddress The address associated with the incentive
  function setIncentive(address newIncentiveAddress) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolState {
  /// @notice The globalState structure in the pool stores many values but requires only one slot
  /// and is exposed as a single method to save gas when accessed externally.
  /// @return price The current price of the pool as a sqrt(dToken1/dToken0) Q64.96 value;
  /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run;
  /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick boundary;
  /// @return prevInitializedTick The previous initialized tick
  /// @return fee The last pool fee value in hundredths of a bip, i.e. 1e-6
  /// @return timepointIndex The index of the last written timepoint
  /// @return communityFee The community fee percentage of the swap fee in thousandths (1e-3)
  /// @return unlocked Whether the pool is currently locked to reentrancy
  function globalState()
    external
    view
    returns (uint160 price, int24 tick, int24 prevInitializedTick, uint16 fee, uint16 timepointIndex, uint8 communityFee, bool unlocked);

  /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
  /// @dev This value can overflow the uint256
  function totalFeeGrowth0Token() external view returns (uint256);

  /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
  /// @dev This value can overflow the uint256
  function totalFeeGrowth1Token() external view returns (uint256);

  /// @notice The currently in range liquidity available to the pool
  /// @dev This value has no relationship to the total liquidity across all ticks.
  /// Returned value cannot exceed type(uint128).max
  function liquidity() external view returns (uint128);

  /// @notice The current tick spacing
  /// @dev Ticks can only be used at multiples of this value
  /// e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
  /// This value is an int24 to avoid casting even though it is always positive.
  /// @return The current tick spacing
  function tickSpacing() external view returns (int24);

  /// @notice The current tick spacing for limit orders
  /// @dev Ticks can only be used for limit orders at multiples of this value
  /// This value is an int24 to avoid casting even though it is always positive.
  /// @return The current tick spacing for limit orders
  function tickSpacingLimitOrders() external view returns (int24);

  /// @notice The timestamp of the last sending of tokens to community vault
  function communityFeeLastTimestamp() external view returns (uint32);

  /// @notice The amounts of token0 and token1 that will be sent to the vault
  /// @dev Will be sent COMMUNITY_FEE_TRANSFER_FREQUENCY after communityFeeLastTimestamp
  function getCommunityFeePending() external view returns (uint128 communityFeePending0, uint128 communityFeePending1);

  /// @notice The tracked token0 and token1 reserves of pool
  /// @dev If at any time the real balance is larger, the excess will be transferred to liquidity providers as additional fee.
  /// If the balance exceeds uint128, the excess will be sent to the communityVault.
  function getReserves() external view returns (uint128 reserve0, uint128 reserve1);

  /// @notice The accumulator of seconds per liquidity since the pool was first initialized
  function secondsPerLiquidityCumulative() external view returns (uint160);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityTotal The total amount of position liquidity that uses the pool either as tick lower or tick upper
  /// @return liquidityDelta How much liquidity changes when the pool price crosses the tick
  /// @return outerFeeGrowth0Token The fee growth on the other side of the tick from the current tick in token0
  /// @return outerFeeGrowth1Token The fee growth on the other side of the tick from the current tick in token1
  /// @return prevTick The previous tick in tick list
  /// @return nextTick The next tick in tick list
  /// @return outerSecondsPerLiquidity The seconds spent per liquidity on the other side of the tick from the current tick
  /// @return outerSecondsSpent The seconds spent on the other side of the tick from the current tick
  /// @return hasLimitOrders Whether there are limit orders on this tick or not
  /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
  /// a specific position.
  function ticks(
    int24 tick
  )
    external
    view
    returns (
      uint128 liquidityTotal,
      int128 liquidityDelta,
      uint256 outerFeeGrowth0Token,
      uint256 outerFeeGrowth1Token,
      int24 prevTick,
      int24 nextTick,
      uint160 outerSecondsPerLiquidity,
      uint32 outerSecondsSpent,
      bool hasLimitOrders
    );

  /// @notice Returns the summary information about a limit orders at tick
  /// @param tick The tick to look up
  /// @return amountToSell The amount of tokens to sell. Has only relative meaning
  /// @return soldAmount The amount of tokens already sold. Has only relative meaning
  /// @return boughtAmount0Cumulative The accumulator of bought tokens0 per amountToSell. Has only relative meaning
  /// @return boughtAmount1Cumulative The accumulator of bought tokens1 per amountToSell. Has only relative meaning
  /// @return initialized Will be true if a limit order was created at least once on this tick
  function limitOrders(
    int24 tick
  )
    external
    view
    returns (uint128 amountToSell, uint128 soldAmount, uint256 boughtAmount0Cumulative, uint256 boughtAmount1Cumulative, bool initialized);

  /// @notice Returns 256 packed tick initialized boolean values. See TickTree for more information
  function tickTable(int16 wordPosition) external view returns (uint256);

  /// @notice Returns the information about a position by the position's key
  /// @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
  /// @return liquidity The amount of liquidity in the position
  /// @return innerFeeGrowth0Token Fee growth of token0 inside the tick range as of the last mint/burn/poke
  /// @return innerFeeGrowth1Token Fee growth of token1 inside the tick range as of the last mint/burn/poke
  /// @return fees0 The computed amount of token0 owed to the position as of the last mint/burn/poke
  /// @return fees1 The computed amount of token1 owed to the position as of the last mint/burn/poke
  function positions(
    bytes32 key
  ) external view returns (uint256 liquidity, uint256 innerFeeGrowth0Token, uint256 innerFeeGrowth1Token, uint128 fees0, uint128 fees1);

  /// @notice Returns the information about active incentive
  /// @dev if there is no active incentive at the moment, incentiveAddress would be equal to address(0)
  /// @return incentiveAddress The address associated with the current active incentive
  function activeIncentive() external view returns (address incentiveAddress);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.17;

library Constants {
  uint8 internal constant RESOLUTION = 96;
  uint256 internal constant Q32 = 1 << 32;
  uint256 internal constant Q48 = 1 << 48;
  uint256 internal constant Q64 = 1 << 64;
  uint256 internal constant Q96 = 1 << 96;
  uint256 internal constant Q128 = 1 << 128;
  uint256 internal constant Q144 = 1 << 144;
  int256 internal constant Q160 = 1 << 160;

  uint16 internal constant BASE_FEE = 0.0001e6; // init minimum fee value in hundredths of a bip (0.01%)
  uint24 internal constant FEE_DENOMINATOR = 1e6;
  int24 internal constant INIT_TICK_SPACING = 60;
  int24 internal constant MAX_TICK_SPACING = 500;

  // Defines the maximum and minimum ticks allowed for limit orders. Corresponds to the range of possible
  // price values ​​in UniswapV2. Due to this limitation, sufficient accuracy is achieved even with the minimum allowable tick
  int24 constant MAX_LIMIT_ORDER_TICK = 776363;

  // the frequency with which the accumulated community fees are sent to the vault
  uint32 internal constant COMMUNITY_FEE_TRANSFER_FREQUENCY = 8 hours;

  // max(uint128) / ( (MAX_TICK - MIN_TICK) )
  uint128 internal constant MAX_LIQUIDITY_PER_TICK = 40564824043007195767232224305152;

  uint8 internal constant MAX_COMMUNITY_FEE = 0.25e3; // 25%
  uint256 internal constant COMMUNITY_FEE_DENOMINATOR = 1e3;
  // role that can change communityFee and tickspacing in pools
  bytes32 internal constant POOLS_ADMINISTRATOR_ROLE = keccak256('POOLS_ADMINISTRATOR');
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
    unchecked {
      // 512-bit multiply [prod1 prod0] = a * b
      // Compute the product mod 2**256 and mod 2**256 - 1
      // then use the Chinese Remainder Theorem to reconstruct
      // the 512 bit result. The result is stored in two 256
      // variables such that product = prod1 * 2**256 + prod0
      uint256 prod0 = a * b; // Least significant 256 bits of the product
      uint256 prod1; // Most significant 256 bits of the product
      assembly {
        let mm := mulmod(a, b, not(0))
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
      }

      // Make sure the result is less than 2**256.
      // Also prevents denominator == 0
      require(denominator > prod1);

      // Handle non-overflow cases, 256 by 256 division
      if (prod1 == 0) {
        assembly {
          result := div(prod0, denominator)
        }
        return result;
      }

      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [prod1 prod0]
      // Compute remainder using mulmod
      // Subtract 256 bit remainder from 512 bit number
      assembly {
        let remainder := mulmod(a, b, denominator)
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }

      // Factor powers of two out of denominator
      // Compute largest power of two divisor of denominator.
      // Always >= 1.
      uint256 twos = (0 - denominator) & denominator;
      // Divide denominator by power of two
      assembly {
        denominator := div(denominator, twos)
      }

      // Divide [prod1 prod0] by the factors of two
      assembly {
        prod0 := div(prod0, twos)
      }
      // Shift in bits from prod1 into prod0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;

      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      uint256 inv = (3 * denominator) ^ 2;
      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - denominator * inv; // inverse mod 2**8
      inv *= 2 - denominator * inv; // inverse mod 2**16
      inv *= 2 - denominator * inv; // inverse mod 2**32
      inv *= 2 - denominator * inv; // inverse mod 2**64
      inv *= 2 - denominator * inv; // inverse mod 2**128
      inv *= 2 - denominator * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the preconditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
      return result;
    }
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
    unchecked {
      if (a == 0 || ((result = a * b) / a == b)) {
        require(denominator > 0);
        assembly {
          result := add(div(result, denominator), gt(mod(result, denominator), 0))
        }
      } else {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
          require(result < type(uint256).max);
          result++;
        }
      }
    }
  }

  /// @notice Returns ceil(x / y)
  /// @dev division by 0 has unspecified behavior, and must be checked externally
  /// @param x The dividend
  /// @param y The divisor
  /// @return z The quotient, ceil(x / y)
  function unsafeDivRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
    assembly {
      z := add(div(x, y), gt(mod(x, y), 0))
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

import '../interfaces/IAlgebraPoolErrors.sol';
import './TickMath.sol';
import './TokenDeltaMath.sol';

/// @title Math library for liquidity
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library LiquidityMath {
  /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
  /// @param x The liquidity before change
  /// @param y The delta by which liquidity should be changed
  /// @return z The liquidity delta
  function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
    unchecked {
      if (y < 0) {
        if ((z = x - uint128(-y)) >= x) revert IAlgebraPoolErrors.liquiditySub();
      } else {
        if ((z = x + uint128(y)) < x) revert IAlgebraPoolErrors.liquidityAdd();
      }
    }
  }

  function getAmountsForLiquidity(
    int24 bottomTick,
    int24 topTick,
    int128 liquidityDelta,
    int24 currentTick,
    uint160 currentPrice
  ) internal pure returns (uint256 amount0, uint256 amount1, int128 globalLiquidityDelta) {
    uint160 priceAtBottomTick = TickMath.getSqrtRatioAtTick(bottomTick);
    uint160 priceAtTopTick = TickMath.getSqrtRatioAtTick(topTick);

    int256 amount0Int;
    int256 amount1Int;
    if (currentTick < bottomTick) {
      // If current tick is less than the provided bottom one then only the token0 has to be provided
      amount0Int = TokenDeltaMath.getToken0Delta(priceAtBottomTick, priceAtTopTick, liquidityDelta);
    } else if (currentTick < topTick) {
      amount0Int = TokenDeltaMath.getToken0Delta(currentPrice, priceAtTopTick, liquidityDelta);
      amount1Int = TokenDeltaMath.getToken1Delta(priceAtBottomTick, currentPrice, liquidityDelta);
      globalLiquidityDelta = liquidityDelta;
    } else {
      // If current tick is greater than the provided top one then only the token1 has to be provided
      amount1Int = TokenDeltaMath.getToken1Delta(priceAtBottomTick, priceAtTopTick, liquidityDelta);
    }

    unchecked {
      (amount0, amount1) = liquidityDelta < 0 ? (uint256(-amount0Int), uint256(-amount1Int)) : (uint256(amount0Int), uint256(amount1Int));
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library LowGasSafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x + y) >= x);
    }
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x - y) <= x);
    }
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require(x == 0 || (z = x * y) / x == y);
    }
  }

  /// @notice Returns x + y, reverts if overflows or underflows
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(int256 x, int256 y) internal pure returns (int256 z) {
    unchecked {
      require((z = x + y) >= x == (y >= 0));
    }
  }

  /// @notice Returns x - y, reverts if overflows or underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(int256 x, int256 y) internal pure returns (int256 z) {
    unchecked {
      require((z = x - y) <= x == (y >= 0));
    }
  }

  /// @notice Returns x + y, reverts if overflows or underflows
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add128(uint128 x, uint128 y) internal pure returns (uint128 z) {
    unchecked {
      require((z = x + y) >= x);
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0 || ^0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library SafeCast {
  /// @notice Cast a uint256 to a uint160, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint160(uint256 y) internal pure returns (uint160 z) {
    require((z = uint160(y)) == y);
  }

  /// @notice Cast a uint256 to a uint128, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint128
  function toUint128(uint256 y) internal pure returns (uint128 z) {
    require((z = uint128(y)) == y);
  }

  /// @notice Cast a int256 to a int128, revert on overflow or underflow
  /// @param y The int256 to be downcasted
  /// @return z The downcasted integer, now type int128
  function toInt128(int256 y) internal pure returns (int128 z) {
    require((z = int128(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require((z = int256(y)) >= 0);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

import '../interfaces/IAlgebraPoolErrors.sol';

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library TickMath {
  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  int24 internal constant MIN_TICK = -887272;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  int24 internal constant MAX_TICK = -MIN_TICK;

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

  /// @notice Calculates sqrt(1.0001^tick) * 2^96
  /// @dev Throws if |tick| > max tick
  /// @param tick The input tick for the above formula
  /// @return price A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 price) {
    unchecked {
      // get abs value
      int24 mask = tick >> (24 - 1);
      uint256 absTick = uint24((tick ^ mask) - mask);
      if (absTick > uint24(MAX_TICK)) revert IAlgebraPoolErrors.tickOutOfRange();

      uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
      if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
      if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
      if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
      if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
      if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
      if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
      if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
      if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
      if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
      if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
      if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
      if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
      if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
      if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
      if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
      if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
      if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
      if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
      if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

      if (tick > 0) ratio = type(uint256).max / ratio;

      // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
      // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
      // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
      price = uint160((ratio + 0xFFFFFFFF) >> 32);
    }
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case price < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param price The sqrt ratio for which to compute the tick as a Q64.96
  /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
  function getTickAtSqrtRatio(uint160 price) internal pure returns (int24 tick) {
    unchecked {
      // second inequality must be >= because the price can never reach the price at the max tick
      if (price < MIN_SQRT_RATIO || price >= MAX_SQRT_RATIO) revert IAlgebraPoolErrors.priceOutOfRange();
      uint256 ratio = uint256(price) << 32;

      uint256 r = ratio;
      uint256 msb = 0;

      assembly {
        let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(5, gt(r, 0xFFFFFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(4, gt(r, 0xFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(3, gt(r, 0xFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(2, gt(r, 0xF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(1, gt(r, 0x3))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := gt(r, 0x1)
        msb := or(msb, f)
      }

      if (msb >= 128) r = ratio >> (msb - 127);
      else r = ratio << (127 - msb);

      int256 log_2 = (int256(msb) - 128) << 64;

      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(63, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(62, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(61, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(60, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(59, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(58, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(57, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(56, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(55, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(54, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(53, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(52, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(51, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(50, f))
      }

      int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

      int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
      int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

      tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= price ? tickHi : tickLow;
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import './Constants.sol';
import './TickMath.sol';

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state and search tree
/// @dev The leafs mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickTree {
  int16 internal constant SECOND_LAYER_OFFSET = 3466; // ceil(MAX_TICK / 256)

  /// @notice Toggles the initialized state for a given tick from false to true, or vice versa
  /// @param leafs The mapping of words with ticks
  /// @param secondLayer The mapping of words with leafs
  /// @param tick The tick to toggle
  /// @param treeRoot The word with info about active subtrees
  function toggleTick(
    mapping(int16 => uint256) storage leafs,
    mapping(int16 => uint256) storage secondLayer,
    int24 tick,
    uint256 treeRoot
  ) internal returns (uint256 newTreeRoot) {
    newTreeRoot = treeRoot;
    (bool toggledNode, int16 nodeNumber) = _toggleTickInNode(leafs, tick);
    if (toggledNode) {
      unchecked {
        (toggledNode, nodeNumber) = _toggleTickInNode(secondLayer, nodeNumber + SECOND_LAYER_OFFSET);
      }
      if (toggledNode) {
        assembly {
          newTreeRoot := xor(newTreeRoot, shl(nodeNumber, 1))
        }
      }
    }
  }

  /// @notice Calculates the required node and toggles tick in it
  /// @param row The level of tree
  /// @param tick The tick to toggle
  /// @return toggledNode Toggled whole node or not
  /// @return nodeNumber Number of corresponding node
  function _toggleTickInNode(mapping(int16 => uint256) storage row, int24 tick) private returns (bool toggledNode, int16 nodeNumber) {
    assembly {
      nodeNumber := sar(8, tick)
    }
    uint256 node = row[nodeNumber];
    assembly {
      toggledNode := iszero(node)
      node := xor(node, shl(and(tick, 0xFF), 1))
      toggledNode := xor(toggledNode, iszero(node))
    }
    row[nodeNumber] = node;
  }

  /// @notice Returns the next initialized tick in tree to the right (gte) of the given tick or `MAX_TICK`
  /// @param leafs The words with ticks
  /// @param secondLayer The words with info about active leafs
  /// @param treeRoot The word with info about active subtrees
  /// @param tick The starting tick
  /// @return nextTick The next initialized tick or `MAX_TICK`
  function getNextTick(
    mapping(int16 => uint256) storage leafs,
    mapping(int16 => uint256) storage secondLayer,
    uint256 treeRoot,
    int24 tick
  ) internal view returns (int24 nextTick) {
    unchecked {
      tick++;
      int16 nodeNumber;
      bool initialized;
      assembly {
        // index in treeRoot
        nodeNumber := shr(8, add(sar(8, tick), SECOND_LAYER_OFFSET))
      }
      if (treeRoot & (1 << uint16(nodeNumber)) != 0) {
        // if subtree has active ticks
        // try to find initialized tick in the corresponding leaf of the tree
        (nodeNumber, nextTick, initialized) = _getNextActiveBitInSameNode(leafs, tick);
        if (initialized) return nextTick;

        // try to find next initialized leaf in the tree
        (nodeNumber, nextTick, initialized) = _getNextActiveBitInSameNode(secondLayer, nodeNumber + SECOND_LAYER_OFFSET + 1);
      }
      if (!initialized) {
        // try to find which subtree has an active leaf
        (nextTick, initialized) = _nextActiveBitInTheSameNode(treeRoot, ++nodeNumber);
        if (!initialized) return TickMath.MAX_TICK;
        nextTick = _getFirstActiveBitInNode(secondLayer, nextTick);
      }
      nextTick = _getFirstActiveBitInNode(leafs, nextTick - SECOND_LAYER_OFFSET);
    }
  }

  /// @notice Calculates node with given tick and returns next active tick
  /// @param row level of search tree
  /// @param tick The starting tick
  /// @return nodeNumber Number of corresponding node
  /// @return nextTick Number of next active tick or last tick in node
  /// @return initialized Is nextTick initialized or not
  function _getNextActiveBitInSameNode(
    mapping(int16 => uint256) storage row,
    int24 tick
  ) private view returns (int16 nodeNumber, int24 nextTick, bool initialized) {
    assembly {
      nodeNumber := sar(8, tick)
    }
    (nextTick, initialized) = _nextActiveBitInTheSameNode(row[nodeNumber], tick);
  }

  /// @notice Returns first active tick in given node
  /// @param row level of search tree
  /// @param nodeNumber Number of corresponding node
  /// @return nextTick Number of next active tick or last tick in node
  function _getFirstActiveBitInNode(mapping(int16 => uint256) storage row, int24 nodeNumber) private view returns (int24 nextTick) {
    assembly {
      nextTick := shl(8, nodeNumber)
    }
    (nextTick, ) = _nextActiveBitInTheSameNode(row[int16(nodeNumber)], nextTick);
  }

  /// @notice Returns the next initialized tick contained in the same word as the tick that is
  /// to the right or at (gte) of the given tick
  /// @param word The word in which to compute the next initialized tick
  /// @param tick The starting tick
  /// @return nextTick The next initialized or uninitialized tick up to 256 ticks away from the current tick
  /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
  function _nextActiveBitInTheSameNode(uint256 word, int24 tick) private pure returns (int24 nextTick, bool initialized) {
    uint256 bitNumber;
    assembly {
      bitNumber := and(tick, 0xFF)
    }
    unchecked {
      uint256 _row = word >> bitNumber; // all the 1s at or to the left of the bitNumber
      if (_row == 0) {
        nextTick = tick + int24(uint24(255 - bitNumber));
      } else {
        nextTick = tick + int24(uint24(getSingleSignificantBit((0 - _row) & _row))); // least significant bit
        initialized = true;
      }
    }
  }

  /// @notice get position of single 1-bit
  /// @dev it is assumed that word contains exactly one 1-bit, otherwise the result will be incorrect
  /// @param word The word containing only one 1-bit
  function getSingleSignificantBit(uint256 word) internal pure returns (uint8 singleBitPos) {
    assembly {
      singleBitPos := iszero(and(word, 0x5555555555555555555555555555555555555555555555555555555555555555))
      singleBitPos := or(singleBitPos, shl(7, iszero(and(word, 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))))
      singleBitPos := or(singleBitPos, shl(6, iszero(and(word, 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF))))
      singleBitPos := or(singleBitPos, shl(5, iszero(and(word, 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF))))
      singleBitPos := or(singleBitPos, shl(4, iszero(and(word, 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF))))
      singleBitPos := or(singleBitPos, shl(3, iszero(and(word, 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF))))
      singleBitPos := or(singleBitPos, shl(2, iszero(and(word, 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F))))
      singleBitPos := or(singleBitPos, shl(1, iszero(and(word, 0x3333333333333333333333333333333333333333333333333333333333333333))))
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import './SafeCast.sol';
import './FullMath.sol';
import './Constants.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library TokenDeltaMath {
  using SafeCast for uint256;

  /// @notice Gets the token0 delta between two prices
  /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper)
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The amount of usable liquidity
  /// @param roundUp Whether to round the amount up or down
  /// @return token0Delta Amount of token0 required to cover a position of size liquidity between the two passed prices
  function getToken0Delta(uint160 priceLower, uint160 priceUpper, uint128 liquidity, bool roundUp) internal pure returns (uint256 token0Delta) {
    unchecked {
      uint256 priceDelta = priceUpper - priceLower;
      require(priceDelta < priceUpper); // forbids underflow and 0 priceLower
      uint256 liquidityShifted = uint256(liquidity) << Constants.RESOLUTION;

      token0Delta = roundUp
        ? FullMath.unsafeDivRoundingUp(FullMath.mulDivRoundingUp(priceDelta, liquidityShifted, priceUpper), priceLower) // denominator always > 0
        : FullMath.mulDiv(priceDelta, liquidityShifted, priceUpper) / priceLower;
    }
  }

  /// @notice Gets the token1 delta between two prices
  /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The amount of usable liquidity
  /// @param roundUp Whether to round the amount up, or down
  /// @return token1Delta Amount of token1 required to cover a position of size liquidity between the two passed prices
  function getToken1Delta(uint160 priceLower, uint160 priceUpper, uint128 liquidity, bool roundUp) internal pure returns (uint256 token1Delta) {
    unchecked {
      require(priceUpper >= priceLower);
      uint256 priceDelta = priceUpper - priceLower;
      token1Delta = roundUp ? FullMath.mulDivRoundingUp(priceDelta, liquidity, Constants.Q96) : FullMath.mulDiv(priceDelta, liquidity, Constants.Q96);
    }
  }

  /// @notice Helper that gets signed token0 delta
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The change in liquidity for which to compute the token0 delta
  /// @return token0Delta Amount of token0 corresponding to the passed liquidityDelta between the two prices
  function getToken0Delta(uint160 priceLower, uint160 priceUpper, int128 liquidity) internal pure returns (int256 token0Delta) {
    unchecked {
      token0Delta = liquidity >= 0
        ? getToken0Delta(priceLower, priceUpper, uint128(liquidity), true).toInt256()
        : -getToken0Delta(priceLower, priceUpper, uint128(-liquidity), false).toInt256();
    }
  }

  /// @notice Helper that gets signed token1 delta
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The change in liquidity for which to compute the token1 delta
  /// @return token1Delta Amount of token1 corresponding to the passed liquidityDelta between the two prices
  function getToken1Delta(uint160 priceLower, uint160 priceUpper, int128 liquidity) internal pure returns (int256 token1Delta) {
    unchecked {
      token1Delta = liquidity >= 0
        ? getToken1Delta(priceLower, priceUpper, uint128(liquidity), true).toInt256()
        : -getToken1Delta(priceLower, priceUpper, uint128(-liquidity), false).toInt256();
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain separator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Algebra positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param actualLiquidity the actual liquidity that was added into a pool. Could differ from
    /// _liquidity_ when using FeeOnTransfer tokens
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint128 actualLiquidity,
        uint256 amount0,
        uint256 amount1,
        address pool
    );

    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Emitted if farming failed in call from NonfungiblePositionManager.
    /// @dev Should never be emitted
    /// @param tokenId The ID of corresponding token
    event FarmingFailed(uint256 indexed tokenId);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint88 nonce,
            address operator,
            address token0,
            address token1,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to achieve resulting liquidity
    /// @return amount1 The amount of token1 to achieve resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    /// @notice Changes approval of token ID for farming.
    /// @param tokenId The ID of the token that is being approved / unapproved
    /// @param approve New status of approval
    function approveForFarming(uint256 tokenId, bool approve) external payable;

    /// @notice Changes farming status of token to 'farmed' or 'not farmed'
    /// @dev can be called only by farmingCenter
    /// @param tokenId tokenId The ID of the token
    /// @param tokenId isFarmed The new status
    function switchFarmingStatus(uint256 tokenId, bool isFarmed) external;

    /// @notice Changes address of farmingCenter
    /// @dev can be called only by factory owner or NONFUNGIBLE_POSITION_MANAGER_ADMINISTRATOR_ROLE
    /// @param newFarmingCenter The new address of farmingCenter
    function setFarmingCenter(address newFarmingCenter) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IPeripheryImmutableState {
    /// @return Returns the address of the Algebra factory
    function factory() external view returns (address);

    /// @return Returns the address of the pool Deployer
    function poolDeployer() external view returns (address);

    /// @return Returns the address of WNativeToken
    function WNativeToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of NativeToken
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WNativeToken balance and sends it to recipient as NativeToken.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WNativeToken from users.
    /// @param amountMinimum The minimum amount of WNativeToken to unwrap
    /// @param recipient The address receiving NativeToken
    function unwrapWNativeToken(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any NativeToken balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundNativeToken() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes Algebra Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the poolDeployer and tokens
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0x15b69bf972c5c2df89dd7772b62e872d4048b3741a214df60be904ec5620d9df;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
    }

    /// @notice Returns PoolKey: the ordered tokens
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(address tokenA, address tokenB) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB});
    }

    /// @notice Deterministically computes the pool address given the poolDeployer and PoolKey
    /// @param poolDeployer The Algebra poolDeployer contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the Algebra pool
    function computeAddress(address poolDeployer, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1, 'Invalid order of tokens');
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            poolDeployer,
                            keccak256(abi.encode(key.token0, key.token1)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers NativeToken to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import '@cryptoalgebra/core/contracts/interfaces/IERC20Minimal.sol';
import '@cryptoalgebra/core/contracts/interfaces/IAlgebraPool.sol';

/// @param rewardToken The token being distributed as a reward
/// @param bonusRewardToken The bonus token being distributed as a reward
/// @param pool The Algebra pool
/// @param nonce The nonce of incentive
struct IncentiveKey {
  IERC20Minimal rewardToken;
  IERC20Minimal bonusRewardToken;
  IAlgebraPool pool;
  uint256 nonce;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import '@cryptoalgebra/core/contracts/libraries/TickTree.sol';

import '../libraries/VirtualTickManagement.sol';
import '../interfaces/IAlgebraEternalVirtualPool.sol';

/// @title Algebra tick structure abstract contract
/// @notice Encapsulates the logic of interaction with the data structure with ticks
/// @dev Ticks are stored as a doubly linked list. A two-layer bitmap tree is used to search through the list
abstract contract VirtualTickStructure is IAlgebraEternalVirtualPool {
  using VirtualTickManagement for mapping(int24 => VirtualTickManagement.Tick);
  using TickTree for mapping(int16 => uint256);

  mapping(int24 => VirtualTickManagement.Tick) public ticks;

  uint256 internal tickTreeRoot; // The root of bitmap search tree
  mapping(int16 => uint256) internal tickSecondLayer; // The second layer bitmap search tree
  mapping(int16 => uint256) internal tickTable; // the leaves of the tree

  constructor() {
    ticks.initTickState();
  }

  /**
   * @notice Used to add or remove a tick from a doubly linked list and search tree
   * @param tick The tick being removed or added now
   * @param currentTick The current global tick in the pool
   * @param prevInitializedTick Previous active tick before `currentTick`
   * @param remove Remove or add the tick
   * @return newPrevInitializedTick New previous active tick before `currentTick` if changed
   */
  function _insertOrRemoveTick(
    int24 tick,
    int24 currentTick,
    int24 prevInitializedTick,
    bool remove
  ) internal returns (int24 newPrevInitializedTick) {
    uint256 oldTickTreeRoot = tickTreeRoot;

    int24 prevTick;
    if (remove) {
      prevTick = ticks.removeTick(tick);
      if (prevInitializedTick == tick) prevInitializedTick = prevTick;
    } else {
      int24 nextTick;
      if (prevInitializedTick < tick && tick <= currentTick) {
        nextTick = ticks[prevInitializedTick].nextTick;
        prevTick = prevInitializedTick;
        prevInitializedTick = tick;
      } else {
        nextTick = tickTable.getNextTick(tickSecondLayer, oldTickTreeRoot, tick);
        prevTick = ticks[nextTick].prevTick;
      }
      ticks.insertTick(tick, prevTick, nextTick);
    }

    uint256 newTickTreeRoot = tickTable.toggleTick(tickSecondLayer, tick, oldTickTreeRoot);
    if (newTickTreeRoot != oldTickTreeRoot) tickTreeRoot = newTickTreeRoot;
    return prevInitializedTick;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.17;

import './EternalVirtualPool.sol';
import '../libraries/IncentiveId.sol';
import '../libraries/NFTPositionInfo.sol';
import '../interfaces/IAlgebraEternalFarming.sol';
import '../interfaces/IAlgebraEternalVirtualPool.sol';
import '../interfaces/IFarmingCenter.sol';

import '@cryptoalgebra/core/contracts/interfaces/IAlgebraPoolDeployer.sol';
import '@cryptoalgebra/core/contracts/interfaces/IAlgebraPool.sol';
import '@cryptoalgebra/core/contracts/interfaces/IAlgebraFactory.sol';
import '@cryptoalgebra/core/contracts/interfaces/IERC20Minimal.sol';
import '@cryptoalgebra/core/contracts/libraries/SafeCast.sol';
import '@cryptoalgebra/core/contracts/libraries/FullMath.sol';
import '@cryptoalgebra/core/contracts/libraries/Constants.sol';
import '@cryptoalgebra/core/contracts/libraries/TickMath.sol';
import '@cryptoalgebra/core/contracts/libraries/LowGasSafeMath.sol';

import '@cryptoalgebra/periphery/contracts/libraries/TransferHelper.sol';

/// @title Algebra eternal (v2-like) farming
contract AlgebraEternalFarming is IAlgebraEternalFarming {
  using SafeCast for int256;
  using LowGasSafeMath for uint256;
  using LowGasSafeMath for uint128;

  /// @notice Represents a farming incentive
  struct Incentive {
    uint128 totalReward;
    uint128 bonusReward;
    address virtualPoolAddress;
    uint24 minimalPositionWidth;
    bool deactivated;
  }

  /// @notice Represents the farm for nft
  struct Farm {
    uint128 liquidity;
    int24 tickLower;
    int24 tickUpper;
    uint256 innerRewardGrowth0;
    uint256 innerRewardGrowth1;
  }

  /// @inheritdoc IAlgebraEternalFarming
  INonfungiblePositionManager public immutable override nonfungiblePositionManager;

  IAlgebraPoolDeployer private immutable deployer;
  IAlgebraFactory private immutable factory;

  IFarmingCenter public farmingCenter;

  /// @dev bytes32 refers to the return value of IncentiveId.compute
  /// @inheritdoc IAlgebraEternalFarming
  mapping(bytes32 => Incentive) public override incentives;

  /// @dev farms[tokenId][incentiveHash] => Farm
  /// @inheritdoc IAlgebraEternalFarming
  mapping(uint256 => mapping(bytes32 => Farm)) public override farms;

  uint256 public numOfIncentives;

  bytes32 public constant INCENTIVE_MAKER_ROLE = keccak256('INCENTIVE_MAKER_ROLE');
  bytes32 public constant FARMINGS_ADMINISTRATOR_ROLE = keccak256('FARMINGS_ADMINISTRATOR_ROLE');

  /// @dev rewards[owner][rewardToken] => uint256
  /// @inheritdoc IAlgebraEternalFarming
  mapping(address => mapping(IERC20Minimal => uint256)) public override rewards;

  modifier onlyIncentiveMaker() {
    _checkHasRole(INCENTIVE_MAKER_ROLE);
    _;
  }

  modifier onlyAdministrator() {
    _checkHasRole(FARMINGS_ADMINISTRATOR_ROLE);
    _;
  }

  modifier onlyFarmingCenter() {
    _checkIsFarmingCenter();
    _;
  }

  /// @param _deployer pool deployer contract address
  /// @param _nonfungiblePositionManager the NFT position manager contract address
  constructor(IAlgebraPoolDeployer _deployer, INonfungiblePositionManager _nonfungiblePositionManager) {
    (deployer, nonfungiblePositionManager) = (_deployer, _nonfungiblePositionManager);
    factory = IAlgebraFactory(_nonfungiblePositionManager.factory());
  }

  /// @inheritdoc IAlgebraEternalFarming
  function isIncentiveActiveInPool(bytes32 incentiveId, IAlgebraPool pool) external view override returns (bool res) {
    Incentive storage incentive = incentives[incentiveId];
    if (incentive.deactivated) return false;

    IAlgebraEternalVirtualPool virtualPool = IAlgebraEternalVirtualPool(incentive.virtualPoolAddress);
    if (_getCurrentVirtualPool(pool) != address(virtualPool)) return false; // pool can "detach" by itself

    return true;
  }

  function _checkIsFarmingCenter() internal view {
    require(msg.sender == address(farmingCenter));
  }

  function _checkHasRole(bytes32 role) internal view {
    require(factory.hasRoleOrOwner(role, msg.sender));
  }

  /// @inheritdoc IAlgebraEternalFarming
  function createEternalFarming(
    IncentiveKey memory key,
    IncentiveParams memory params
  ) external override onlyIncentiveMaker returns (address virtualPool) {
    if (_getCurrentVirtualPool(key.pool) != address(0)) revert farmingAlreadyExists();

    virtualPool = address(new EternalVirtualPool(address(this), address(key.pool)));
    _connectPoolToVirtualPool(key.pool, virtualPool);

    key.nonce = numOfIncentives++;
    bytes32 incentiveId = IncentiveId.compute(key);
    Incentive storage newIncentive = incentives[incentiveId];

    (params.reward, params.bonusReward) = _receiveRewards(key, params.reward, params.bonusReward, newIncentive);
    if (params.reward == 0) revert zeroRewardAmount();

    unchecked {
      if (int256(uint256(params.minimalPositionWidth)) > (int256(TickMath.MAX_TICK) - int256(TickMath.MIN_TICK)))
        revert minimalPositionWidthTooWide();
    }
    (newIncentive.virtualPoolAddress, newIncentive.minimalPositionWidth) = (virtualPool, params.minimalPositionWidth);

    emit EternalFarmingCreated(
      key.rewardToken,
      key.bonusRewardToken,
      key.pool,
      virtualPool,
      key.nonce,
      params.reward,
      params.bonusReward,
      params.minimalPositionWidth
    );

    _addRewards(IAlgebraEternalVirtualPool(virtualPool), params.reward, params.bonusReward, incentiveId);
    _setRewardRates(IAlgebraEternalVirtualPool(virtualPool), params.rewardRate, params.bonusRewardRate, incentiveId);
  }

  /// @inheritdoc IAlgebraEternalFarming
  function deactivateIncentive(IncentiveKey memory key) external override onlyIncentiveMaker {
    (bytes32 incentiveId, Incentive storage incentive) = _getIncentiveByKey(key);
    if (incentive.deactivated) revert incentiveStopped();

    IAlgebraEternalVirtualPool virtualPool = IAlgebraEternalVirtualPool(incentive.virtualPoolAddress);
    if (address(virtualPool) == address(0)) revert incentiveNotExist();

    incentive.deactivated = true;

    (uint128 rewardRate0, uint128 rewardRate1) = virtualPool.rewardRates();
    if (rewardRate0 | rewardRate1 != 0) _setRewardRates(virtualPool, 0, 0, incentiveId);

    if (address(virtualPool) == _getCurrentVirtualPool(key.pool)) {
      _connectPoolToVirtualPool(key.pool, address(0));
    }
    emit IncentiveDeactivated(incentiveId);
  }

  /// @inheritdoc IAlgebraEternalFarming
  function decreaseRewardsAmount(IncentiveKey memory key, uint128 rewardAmount, uint128 bonusRewardAmount) external override onlyAdministrator {
    (bytes32 incentiveId, Incentive storage incentive) = _getIncentiveByKey(key);
    IAlgebraEternalVirtualPool virtualPool = IAlgebraEternalVirtualPool(incentive.virtualPoolAddress);

    virtualPool.distributeRewards();
    (uint128 rewardReserve0, uint128 rewardReserve1) = virtualPool.rewardReserves();
    if (rewardAmount > rewardReserve0) rewardAmount = rewardReserve0;
    if (rewardAmount >= incentive.totalReward) rewardAmount = incentive.totalReward - 1; // to not trigger 'non-existent incentive'
    incentive.totalReward = incentive.totalReward - rewardAmount;

    if (bonusRewardAmount > rewardReserve1) bonusRewardAmount = rewardReserve1;
    incentive.bonusReward = incentive.bonusReward - bonusRewardAmount;

    virtualPool.decreaseRewards(rewardAmount, bonusRewardAmount);

    if (rewardAmount > 0) TransferHelper.safeTransfer(address(key.rewardToken), msg.sender, rewardAmount);
    if (bonusRewardAmount > 0) TransferHelper.safeTransfer(address(key.bonusRewardToken), msg.sender, bonusRewardAmount);

    emit RewardAmountsDecreased(rewardAmount, bonusRewardAmount, incentiveId);
  }

  /// @inheritdoc IAlgebraEternalFarming
  function setFarmingCenterAddress(address _farmingCenter) external override onlyAdministrator {
    require(_farmingCenter != address(farmingCenter));
    farmingCenter = IFarmingCenter(_farmingCenter);
    emit FarmingCenter(_farmingCenter);
  }

  /// @inheritdoc IAlgebraEternalFarming
  function addRewards(IncentiveKey memory key, uint128 rewardAmount, uint128 bonusRewardAmount) external override {
    (bytes32 incentiveId, Incentive storage incentive) = _getIncentiveByKey(key);
    if (incentive.deactivated) revert incentiveStopped();

    IAlgebraEternalVirtualPool virtualPool = IAlgebraEternalVirtualPool(incentive.virtualPoolAddress);
    if (_getCurrentVirtualPool(key.pool) != address(virtualPool)) revert incentiveStopped(); // pool can "detach" by itself

    (rewardAmount, bonusRewardAmount) = _receiveRewards(key, rewardAmount, bonusRewardAmount, incentive);

    if (rewardAmount | bonusRewardAmount > 0) {
      _addRewards(virtualPool, rewardAmount, bonusRewardAmount, incentiveId);
    }
  }

  /// @inheritdoc IAlgebraEternalFarming
  function setRates(IncentiveKey memory key, uint128 rewardRate, uint128 bonusRewardRate) external override onlyIncentiveMaker {
    bytes32 incentiveId = IncentiveId.compute(key);
    IAlgebraEternalVirtualPool virtualPool = IAlgebraEternalVirtualPool(incentives[incentiveId].virtualPoolAddress);

    if ((incentives[incentiveId].deactivated || _getCurrentVirtualPool(key.pool) != address(virtualPool)) && (rewardRate | bonusRewardRate != 0))
      revert incentiveStopped();
    _setRewardRates(virtualPool, rewardRate, bonusRewardRate, incentiveId);
  }

  /// @inheritdoc IAlgebraEternalFarming
  function enterFarming(IncentiveKey memory key, uint256 tokenId) external override onlyFarmingCenter {
    (bytes32 incentiveId, int24 tickLower, int24 tickUpper, uint128 liquidity, address virtualPoolAddress) = _enterFarming(key, tokenId);

    IAlgebraEternalVirtualPool virtualPool = IAlgebraEternalVirtualPool(virtualPoolAddress);
    (uint256 innerRewardGrowth0, uint256 innerRewardGrowth1) = _getInnerRewardsGrowth(virtualPool, tickLower, tickUpper);

    farms[tokenId][incentiveId] = Farm(liquidity, tickLower, tickUpper, innerRewardGrowth0, innerRewardGrowth1);

    emit FarmEntered(tokenId, incentiveId, liquidity);
  }

  /// @inheritdoc IAlgebraEternalFarming
  function exitFarming(IncentiveKey memory key, uint256 tokenId, address _owner) external override onlyFarmingCenter {
    bytes32 incentiveId = IncentiveId.compute(key);
    Farm memory farm = farms[tokenId][incentiveId];
    if (farm.liquidity == 0) revert farmDoesNotExist();

    (uint256 reward, uint256 bonusReward) = _updatePosition(farm, key, incentiveId, _owner, -int256(uint256(farm.liquidity)).toInt128());

    delete farms[tokenId][incentiveId];

    emit FarmEnded(tokenId, incentiveId, address(key.rewardToken), address(key.bonusRewardToken), _owner, reward, bonusReward);
  }

  /// @inheritdoc IAlgebraEternalFarming
  function claimReward(IERC20Minimal rewardToken, address to, uint256 amountRequested) external override returns (uint256 reward) {
    return _claimReward(rewardToken, msg.sender, to, amountRequested);
  }

  /// @inheritdoc IAlgebraEternalFarming
  function claimRewardFrom(
    IERC20Minimal rewardToken,
    address from,
    address to,
    uint256 amountRequested
  ) external override onlyFarmingCenter returns (uint256 reward) {
    return _claimReward(rewardToken, from, to, amountRequested);
  }

  function _updatePosition(
    Farm memory farm,
    IncentiveKey memory key,
    bytes32 incentiveId,
    address _owner,
    int128 liquidityDelta
  ) internal returns (uint256 reward, uint256 bonusReward) {
    Incentive storage incentive = incentives[incentiveId];
    IAlgebraEternalVirtualPool virtualPool = IAlgebraEternalVirtualPool(incentive.virtualPoolAddress);

    if (_getCurrentVirtualPool(key.pool) != address(virtualPool)) incentive.deactivated = true; // pool can "detach" by itself
    int24 tick = incentive.deactivated ? virtualPool.globalTick() : _getTickInPool(key.pool);

    // update rewards, as ticks may be cleared when liquidity decreases
    virtualPool.distributeRewards();

    (reward, bonusReward, , ) = _getNewRewardsForFarm(virtualPool, farm);

    if (liquidityDelta != 0) {
      _updatePositionInVirtualPool(address(virtualPool), uint32(block.timestamp), farm.tickLower, farm.tickUpper, liquidityDelta, tick);
    }

    mapping(IERC20Minimal => uint256) storage rewardBalances = rewards[_owner];
    unchecked {
      if (reward != 0) rewardBalances[key.rewardToken] += reward; // user must claim before overflow
      if (bonusReward != 0) rewardBalances[key.bonusRewardToken] += bonusReward; // user must claim before overflow
    }
  }

  /// @notice reward amounts can be outdated, actual amounts could be obtained via static call of `collectRewards` in FarmingCenter
  /// @inheritdoc IAlgebraEternalFarming
  function getRewardInfo(IncentiveKey memory key, uint256 tokenId) external view override returns (uint256 reward, uint256 bonusReward) {
    bytes32 incentiveId = IncentiveId.compute(key);
    Farm memory farm = farms[tokenId][incentiveId];
    if (farm.liquidity == 0) revert farmDoesNotExist();

    IAlgebraEternalVirtualPool virtualPool = IAlgebraEternalVirtualPool(incentives[incentiveId].virtualPoolAddress);
    (reward, bonusReward, , ) = _getNewRewardsForFarm(virtualPool, farm);
  }

  /// @notice reward amounts should be updated before calling this method
  /// @inheritdoc IAlgebraEternalFarming
  function collectRewards(
    IncentiveKey memory key,
    uint256 tokenId,
    address _owner
  ) external override onlyFarmingCenter returns (uint256 reward, uint256 bonusReward) {
    (bytes32 incentiveId, Incentive storage incentive) = _getIncentiveByKey(key);
    Farm memory farm = farms[tokenId][incentiveId];
    if (farm.liquidity == 0) revert farmDoesNotExist();

    IAlgebraEternalVirtualPool virtualPool = IAlgebraEternalVirtualPool(incentive.virtualPoolAddress);
    virtualPool.distributeRewards();

    uint256 innerRewardGrowth0;
    uint256 innerRewardGrowth1;
    (reward, bonusReward, innerRewardGrowth0, innerRewardGrowth1) = _getNewRewardsForFarm(virtualPool, farm);

    farms[tokenId][incentiveId].innerRewardGrowth0 = innerRewardGrowth0;
    farms[tokenId][incentiveId].innerRewardGrowth1 = innerRewardGrowth1;

    mapping(IERC20Minimal => uint256) storage rewardBalances = rewards[_owner];
    unchecked {
      if (reward != 0) rewardBalances[key.rewardToken] += reward; // user must claim before overflow
      if (bonusReward != 0) rewardBalances[key.bonusRewardToken] += bonusReward; // user must claim before overflow
    }

    emit RewardsCollected(tokenId, incentiveId, reward, bonusReward);
  }

  function _getInnerRewardsGrowth(IAlgebraEternalVirtualPool virtualPool, int24 tickLower, int24 tickUpper) private view returns (uint256, uint256) {
    return virtualPool.getInnerRewardsGrowth(tickLower, tickUpper);
  }

  function _getNewRewardsForFarm(
    IAlgebraEternalVirtualPool virtualPool,
    Farm memory farm
  ) private view returns (uint256 reward, uint256 bonusReward, uint256 innerRewardGrowth0, uint256 innerRewardGrowth1) {
    (innerRewardGrowth0, innerRewardGrowth1) = _getInnerRewardsGrowth(virtualPool, farm.tickLower, farm.tickUpper);

    (reward, bonusReward) = (
      FullMath.mulDiv(innerRewardGrowth0 - farm.innerRewardGrowth0, farm.liquidity, Constants.Q128),
      FullMath.mulDiv(innerRewardGrowth1 - farm.innerRewardGrowth1, farm.liquidity, Constants.Q128)
    );
  }

  function _addRewards(IAlgebraEternalVirtualPool virtualPool, uint128 amount0, uint128 amount1, bytes32 incentiveId) private {
    virtualPool.addRewards(amount0, amount1);
    emit RewardsAdded(amount0, amount1, incentiveId);
  }

  function _setRewardRates(IAlgebraEternalVirtualPool virtualPool, uint128 rate0, uint128 rate1, bytes32 incentiveId) private {
    virtualPool.setRates(rate0, rate1);
    emit RewardsRatesChanged(rate0, rate1, incentiveId);
  }

  function _connectPoolToVirtualPool(IAlgebraPool pool, address virtualPool) private {
    farmingCenter.connectVirtualPool(pool, virtualPool);
  }

  function _getCurrentVirtualPool(IAlgebraPool pool) internal view returns (address virtualPool) {
    return pool.activeIncentive();
  }

  function _receiveRewards(
    IncentiveKey memory key,
    uint128 reward,
    uint128 bonusReward,
    Incentive storage incentive
  ) internal returns (uint128 receivedReward, uint128 receivedBonusReward) {
    if (reward > 0) receivedReward = _receiveToken(key.rewardToken, reward);
    if (bonusReward > 0) receivedBonusReward = _receiveToken(key.bonusRewardToken, bonusReward);

    incentive.totalReward = incentive.totalReward + receivedReward;
    incentive.bonusReward = incentive.bonusReward + receivedBonusReward;
  }

  function _receiveToken(IERC20Minimal token, uint128 amount) private returns (uint128) {
    uint256 balanceBefore = token.balanceOf(address(this));
    TransferHelper.safeTransferFrom(address(token), msg.sender, address(this), amount);
    uint256 balanceAfter = token.balanceOf(address(this));
    require(balanceAfter > balanceBefore);
    unchecked {
      uint256 received = uint128(balanceAfter - balanceBefore);
      require(received <= type(uint128).max, 'invalid token amount');
      return (uint128(received));
    }
  }

  function _enterFarming(
    IncentiveKey memory key,
    uint256 tokenId
  ) internal returns (bytes32 incentiveId, int24 tickLower, int24 tickUpper, uint128 liquidity, address virtualPool) {
    Incentive storage incentive;
    (incentiveId, incentive) = _getIncentiveByKey(key);
    virtualPool = incentive.virtualPoolAddress;

    if (farms[tokenId][incentiveId].liquidity != 0) revert tokenAlreadyFarmed();
    if (_getCurrentVirtualPool(key.pool) != address(virtualPool) || incentive.deactivated) revert incentiveStopped(); // pool can "detach" by itself

    IAlgebraPool pool;
    (pool, tickLower, tickUpper, liquidity) = NFTPositionInfo.getPositionInfo(deployer, nonfungiblePositionManager, tokenId);

    if (pool != key.pool) revert invalidPool();
    if (liquidity == 0) revert zeroLiquidity();

    uint24 minimalAllowedTickWidth = incentive.minimalPositionWidth;
    unchecked {
      if (int256(tickUpper) - int256(tickLower) < int256(uint256(minimalAllowedTickWidth))) revert positionIsTooNarrow();
    }

    int24 tick = _getTickInPool(pool);
    _updatePositionInVirtualPool(virtualPool, uint32(block.timestamp), tickLower, tickUpper, int256(uint256(liquidity)).toInt128(), tick);
  }

  function _claimReward(IERC20Minimal rewardToken, address from, address to, uint256 amountRequested) internal returns (uint256 reward) {
    if (to == address(0)) revert claimToZeroAddress();
    reward = rewards[from][rewardToken];

    if (amountRequested == 0 || amountRequested > reward) amountRequested = reward;

    if (amountRequested > 0) {
      unchecked {
        rewards[from][rewardToken] = reward - amountRequested;
      }
      TransferHelper.safeTransfer(address(rewardToken), to, amountRequested);
      emit RewardClaimed(to, amountRequested, address(rewardToken), from);
    }
  }

  function _getIncentiveByKey(IncentiveKey memory key) internal view returns (bytes32 incentiveId, Incentive storage incentive) {
    incentiveId = IncentiveId.compute(key);
    incentive = incentives[incentiveId];
    if (incentive.totalReward == 0) revert incentiveNotExist();
  }

  function _getTickInPool(IAlgebraPool pool) internal view returns (int24 tick) {
    (, tick, , , , , ) = pool.globalState();
  }

  function _updatePositionInVirtualPool(
    address virtualPool,
    uint32 timestamp,
    int24 tickLower,
    int24 tickUpper,
    int128 liquidityDelta,
    int24 currentTick
  ) internal {
    IAlgebraEternalVirtualPool(virtualPool).applyLiquidityDeltaToPosition(timestamp, tickLower, tickUpper, liquidityDelta, currentTick);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import '@cryptoalgebra/core/contracts/libraries/FullMath.sol';
import '@cryptoalgebra/core/contracts/libraries/Constants.sol';
import '@cryptoalgebra/core/contracts/libraries/TickMath.sol';
import '@cryptoalgebra/core/contracts/libraries/LiquidityMath.sol';

import '../libraries/VirtualTickManagement.sol';

import '../base/VirtualTickStructure.sol';

/// @title Algebra eternal virtual pool
/// @notice used to track active liquidity in farming and distribute rewards
contract EternalVirtualPool is VirtualTickStructure {
  using VirtualTickManagement for mapping(int24 => VirtualTickManagement.Tick);

  address public immutable farmingAddress;
  address public immutable pool;

  /// @inheritdoc IAlgebraEternalVirtualPool
  uint128 public override currentLiquidity;
  /// @inheritdoc IAlgebraEternalVirtualPool
  int24 public override globalTick;
  /// @inheritdoc IAlgebraEternalVirtualPool
  uint32 public override prevTimestamp;

  int24 internal globalPrevInitializedTick;

  uint128 internal rewardRate0;
  uint128 internal rewardRate1;

  uint128 internal rewardReserve0;
  uint128 internal rewardReserve1;

  uint256 public totalRewardGrowth0 = 1;
  uint256 public totalRewardGrowth1 = 1;

  modifier onlyFromFarming() {
    _checkIsFromFarming();
    _;
  }

  constructor(address _farmingAddress, address _pool) {
    globalPrevInitializedTick = TickMath.MIN_TICK;
    farmingAddress = _farmingAddress;
    pool = _pool;
    prevTimestamp = uint32(block.timestamp);
  }

  // @inheritdoc IAlgebraEternalVirtualPool
  function rewardReserves() external view override returns (uint128 reserve0, uint128 reserve1) {
    return (rewardReserve0, rewardReserve1);
  }

  // @inheritdoc IAlgebraEternalVirtualPool
  function rewardRates() external view override returns (uint128 rate0, uint128 rate1) {
    return (rewardRate0, rewardRate1);
  }

  // @inheritdoc IAlgebraEternalVirtualPool
  function getInnerRewardsGrowth(
    int24 bottomTick,
    int24 topTick
  ) external view override returns (uint256 rewardGrowthInside0, uint256 rewardGrowthInside1) {
    unchecked {
      // check if ticks are initialized
      if (ticks[bottomTick].prevTick == ticks[bottomTick].nextTick) revert IAlgebraPoolErrors.tickIsNotInitialized();
      if (ticks[topTick].prevTick == ticks[topTick].nextTick) revert IAlgebraPoolErrors.tickIsNotInitialized();

      uint32 timeDelta = uint32(block.timestamp) - prevTimestamp;
      (uint256 _totalRewardGrowth0, uint256 _totalRewardGrowth1) = (totalRewardGrowth0, totalRewardGrowth1);

      if (timeDelta > 0) {
        // update rewards
        uint128 _currentLiquidity = currentLiquidity;
        if (_currentLiquidity > 0) {
          (uint256 reward0, uint256 reward1) = (rewardRate0 * timeDelta, rewardRate1 * timeDelta);
          (uint256 _rewardReserve0, uint256 _rewardReserve1) = (rewardReserve0, rewardReserve1);

          if (reward0 > _rewardReserve0) reward0 = _rewardReserve0;
          if (reward1 > _rewardReserve1) reward1 = _rewardReserve1;

          if (reward0 > 0) _totalRewardGrowth0 += FullMath.mulDiv(reward0, Constants.Q128, _currentLiquidity);
          if (reward1 > 0) _totalRewardGrowth1 += FullMath.mulDiv(reward1, Constants.Q128, _currentLiquidity);
        }
      }

      return ticks.getInnerFeeGrowth(bottomTick, topTick, globalTick, _totalRewardGrowth0, _totalRewardGrowth1);
    }
  }

  // @inheritdoc IAlgebraEternalVirtualPool
  function addRewards(uint128 token0Amount, uint128 token1Amount) external override onlyFromFarming {
    _applyRewardsDelta(true, token0Amount, token1Amount);
  }

  // @inheritdoc IAlgebraEternalVirtualPool
  function decreaseRewards(uint128 token0Amount, uint128 token1Amount) external override onlyFromFarming {
    _applyRewardsDelta(false, token0Amount, token1Amount);
  }

  /// @inheritdoc IAlgebraVirtualPool
  function crossTo(int24 targetTick, bool zeroToOne) external override returns (bool) {
    if (msg.sender != pool) revert onlyPool();
    _distributeRewards();

    int24 previousTick = globalPrevInitializedTick;
    uint128 _currentLiquidity = currentLiquidity;
    int24 _globalTick = globalTick;

    (uint256 rewardGrowth0, uint256 rewardGrowth1) = (totalRewardGrowth0, totalRewardGrowth1);
    // The set of active ticks in the virtual pool must be a subset of the active ticks in the real pool
    // so this loop will cross no more ticks than the real pool
    if (zeroToOne) {
      while (_globalTick != TickMath.MIN_TICK) {
        if (targetTick >= previousTick) break;
        unchecked {
          _currentLiquidity = LiquidityMath.addDelta(_currentLiquidity, -ticks.cross(previousTick, rewardGrowth0, rewardGrowth1));
          _globalTick = previousTick - 1; // safe since tick index range is narrower than the data type
          previousTick = ticks[previousTick].prevTick;
          if (_globalTick < TickMath.MIN_TICK) _globalTick = TickMath.MIN_TICK;
        }
      }
    } else {
      while (_globalTick != TickMath.MAX_TICK - 1) {
        int24 nextTick = ticks[previousTick].nextTick;
        if (targetTick < nextTick) break;

        _currentLiquidity = LiquidityMath.addDelta(_currentLiquidity, ticks.cross(nextTick, rewardGrowth0, rewardGrowth1));
        (_globalTick, previousTick) = (nextTick, nextTick);
      }
    }

    globalTick = targetTick;
    currentLiquidity = _currentLiquidity;
    globalPrevInitializedTick = previousTick;
    return true;
  }

  /// @inheritdoc IAlgebraEternalVirtualPool
  function distributeRewards() external override onlyFromFarming {
    _distributeRewards();
  }

  /// @inheritdoc IAlgebraEternalVirtualPool
  function applyLiquidityDeltaToPosition(
    uint32 currentTimestamp,
    int24 bottomTick,
    int24 topTick,
    int128 liquidityDelta,
    int24 currentTick
  ) external override onlyFromFarming {
    globalTick = currentTick;

    if (currentTimestamp > prevTimestamp) {
      _distributeRewards();
    }

    if (liquidityDelta != 0) {
      // if we need to update the ticks, do it
      bool flippedBottom;
      bool flippedTop;

      if (_updateTick(bottomTick, currentTick, liquidityDelta, false)) {
        flippedBottom = true;
      }

      if (_updateTick(topTick, currentTick, liquidityDelta, true)) {
        flippedTop = true;
      }

      if (currentTick >= bottomTick && currentTick < topTick) {
        currentLiquidity = LiquidityMath.addDelta(currentLiquidity, liquidityDelta);
      }

      if (flippedBottom || flippedTop) {
        int24 previousTick = globalPrevInitializedTick;
        if (flippedBottom) {
          previousTick = _insertOrRemoveTick(bottomTick, currentTick, previousTick, liquidityDelta < 0);
        }
        if (flippedTop) {
          previousTick = _insertOrRemoveTick(topTick, currentTick, previousTick, liquidityDelta < 0);
        }
        globalPrevInitializedTick = previousTick;
      }
    }
  }

  // @inheritdoc IAlgebraEternalVirtualPool
  function setRates(uint128 rate0, uint128 rate1) external override onlyFromFarming {
    _distributeRewards();
    (rewardRate0, rewardRate1) = (rate0, rate1);
  }

  function _checkIsFromFarming() internal view {
    if (msg.sender != farmingAddress) revert onlyFarming();
  }

  function _applyRewardsDelta(bool add, uint128 token0Delta, uint128 token1Delta) private {
    _distributeRewards();
    if (token0Delta | token1Delta != 0) {
      (uint128 _rewardReserve0, uint128 _rewardReserve1) = (rewardReserve0, rewardReserve1);
      _rewardReserve0 = add ? _rewardReserve0 + token0Delta : _rewardReserve0 - token0Delta;
      _rewardReserve1 = add ? _rewardReserve1 + token1Delta : _rewardReserve1 - token1Delta;
      (rewardReserve0, rewardReserve1) = (_rewardReserve0, _rewardReserve1);
    }
  }

  function _distributeRewards() internal {
    unchecked {
      uint256 timeDelta = uint32(block.timestamp) - prevTimestamp; // safe until timedelta > 136 years
      if (timeDelta == 0) return; // only once per block

      uint256 _currentLiquidity = currentLiquidity; // currentLiquidity is uint128
      if (_currentLiquidity > 0) {
        (uint256 reward0, uint256 reward1) = (rewardRate0 * timeDelta, rewardRate1 * timeDelta);
        (uint128 _rewardReserve0, uint128 _rewardReserve1) = (rewardReserve0, rewardReserve1);

        if (reward0 > _rewardReserve0) reward0 = _rewardReserve0;
        if (reward1 > _rewardReserve1) reward1 = _rewardReserve1;

        if (reward0 | reward1 != 0) {
          _rewardReserve0 = uint128(_rewardReserve0 - reward0);
          _rewardReserve1 = uint128(_rewardReserve1 - reward1);

          if (reward0 > 0) totalRewardGrowth0 += FullMath.mulDiv(reward0, Constants.Q128, _currentLiquidity);
          if (reward1 > 0) totalRewardGrowth1 += FullMath.mulDiv(reward1, Constants.Q128, _currentLiquidity);

          (rewardReserve0, rewardReserve1) = (_rewardReserve0, _rewardReserve1);
        }
      }
    }

    prevTimestamp = uint32(block.timestamp);
    return;
  }

  function _updateTick(int24 tick, int24 currentTick, int128 liquidityDelta, bool isTopTick) internal returns (bool updated) {
    return ticks.update(tick, currentTick, liquidityDelta, totalRewardGrowth0, totalRewardGrowth1, isTopTick);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.17;

import '@cryptoalgebra/periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '../base/IncentiveKey.sol';

/// @title Algebra Eternal Farming Interface
/// @notice Allows farming nonfungible liquidity tokens in exchange for reward tokens without locking NFT for incentive time
interface IAlgebraEternalFarming {
  struct IncentiveParams {
    uint128 reward; // The amount of reward tokens to be distributed
    uint128 bonusReward; // The amount of bonus reward tokens to be distributed
    uint128 rewardRate; // The rate of reward distribution per second
    uint128 bonusRewardRate; // The rate of bonus reward distribution per second
    uint24 minimalPositionWidth; // The minimal allowed width of position (tickUpper - tickLower)
  }

  error farmingAlreadyExists();
  error farmDoesNotExist();
  error tokenAlreadyFarmed();
  error incentiveNotExist();
  error incentiveStopped();
  error anotherFarmingIsActive();

  error minimalPositionWidthTooWide();
  error zeroRewardAmount();

  error positionIsTooNarrow();
  error zeroLiquidity();
  error invalidPool();
  error claimToZeroAddress();

  /// @notice The nonfungible position manager with which this farming contract is compatible
  function nonfungiblePositionManager() external view returns (INonfungiblePositionManager);

  /// @notice Represents a farming incentive
  /// @param incentiveId The ID of the incentive computed from its parameters
  function incentives(
    bytes32 incentiveId
  ) external view returns (uint128 totalReward, uint128 bonusReward, address virtualPoolAddress, uint24 minimalPositionWidth, bool deactivated);

  /// @notice Check if incentive is active in Algebra pool
  /// @dev Does not check that the pool is indeed an Algebra pool
  /// @param incentiveId The ID of the incentive computed from its parameters
  /// @param pool Corresponding Algebra pool
  /// @return res True if incentive is active in Algebra pool
  function isIncentiveActiveInPool(bytes32 incentiveId, IAlgebraPool pool) external view returns (bool res);

  /// @notice Detach incentive from the pool and deactivate it
  /// @param key The key of the incentive
  function deactivateIncentive(IncentiveKey memory key) external;

  function addRewards(IncentiveKey memory key, uint128 rewardAmount, uint128 bonusRewardAmount) external;

  function decreaseRewardsAmount(IncentiveKey memory key, uint128 rewardAmount, uint128 bonusRewardAmount) external;

  /// @notice Returns amounts of reward tokens owed to a given address according to the last time all farms were updated
  /// @param owner The owner for which the rewards owed are checked
  /// @param rewardToken The token for which to check rewards
  /// @return rewardsOwed The amount of the reward token claimable by the owner
  function rewards(address owner, IERC20Minimal rewardToken) external view returns (uint256 rewardsOwed);

  /// @notice Updates farming center address
  /// @param _farmingCenter The new farming center contract address
  function setFarmingCenterAddress(address _farmingCenter) external;

  /// @notice enter farming for Algebra LP token
  /// @param key The key of the incentive for which to enterFarming the NFT
  /// @param tokenId The ID of the token to exitFarming
  function enterFarming(IncentiveKey memory key, uint256 tokenId) external;

  /// @notice exitFarmings for Algebra LP token
  /// @param key The key of the incentive for which to exitFarming the NFT
  /// @param tokenId The ID of the token to exitFarming
  /// @param _owner Owner of the token
  function exitFarming(IncentiveKey memory key, uint256 tokenId, address _owner) external;

  /// @notice Transfers `amountRequested` of accrued `rewardToken` rewards from the contract to the recipient `to`
  /// @param rewardToken The token being distributed as a reward
  /// @param to The address where claimed rewards will be sent to
  /// @param amountRequested The amount of reward tokens to claim. Claims entire reward amount if set to 0.
  /// @return reward The amount of reward tokens claimed
  function claimReward(IERC20Minimal rewardToken, address to, uint256 amountRequested) external returns (uint256 reward);

  /// @notice Transfers `amountRequested` of accrued `rewardToken` rewards from the contract to the recipient `to`
  /// @notice only for FarmingCenter
  /// @param rewardToken The token being distributed as a reward
  /// @param from The address of position owner
  /// @param to The address where claimed rewards will be sent to
  /// @param amountRequested The amount of reward tokens to claim. Claims entire reward amount if set to 0.
  /// @return reward The amount of reward tokens claimed
  function claimRewardFrom(IERC20Minimal rewardToken, address from, address to, uint256 amountRequested) external returns (uint256 reward);

  /// @notice Calculates the reward amount that will be received for the given farm
  /// @param key The key of the incentive
  /// @param tokenId The ID of the token
  /// @return reward The reward accrued to the NFT for the given incentive thus far
  /// @return bonusReward The bonus reward accrued to the NFT for the given incentive thus far
  function getRewardInfo(IncentiveKey memory key, uint256 tokenId) external returns (uint256 reward, uint256 bonusReward);

  /// @notice Returns information about a farmd liquidity NFT
  /// @param tokenId The ID of the farmd token
  /// @param incentiveId The ID of the incentive for which the token is farmd
  /// @return liquidity The amount of liquidity in the NFT as of the last time the rewards were computed,
  /// tickLower The lower tick of position,
  /// tickUpper The upper tick of position,
  /// innerRewardGrowth0 The last saved reward0 growth inside position,
  /// innerRewardGrowth1 The last saved reward1 growth inside position
  function farms(
    uint256 tokenId,
    bytes32 incentiveId
  ) external view returns (uint128 liquidity, int24 tickLower, int24 tickUpper, uint256 innerRewardGrowth0, uint256 innerRewardGrowth1);

  /// @notice Creates a new liquidity mining incentive program
  /// @param key Details of the incentive to create
  /// @param params Params of incentive
  /// @return virtualPool The virtual pool
  function createEternalFarming(IncentiveKey memory key, IncentiveParams memory params) external returns (address virtualPool);

  function setRates(IncentiveKey memory key, uint128 rewardRate, uint128 bonusRewardRate) external;

  function collectRewards(IncentiveKey memory key, uint256 tokenId, address _owner) external returns (uint256 reward, uint256 bonusReward);

  /// @notice Event emitted when a liquidity mining incentive has been stopped from the outside
  /// @param incentiveId The stopped incentive
  event IncentiveDeactivated(bytes32 indexed incentiveId);

  /// @notice Event emitted when a Algebra LP token has been farmd
  /// @param tokenId The unique identifier of an Algebra LP token
  /// @param incentiveId The incentive in which the token is farming
  /// @param liquidity The amount of liquidity farmd
  event FarmEntered(uint256 indexed tokenId, bytes32 indexed incentiveId, uint128 liquidity);

  /// @notice Event emitted when a Algebra LP token has been exitFarmingd
  /// @param tokenId The unique identifier of an Algebra LP token
  /// @param incentiveId The incentive in which the token is farming
  /// @param rewardAddress The token being distributed as a reward
  /// @param bonusRewardToken The token being distributed as a bonus reward
  /// @param owner The address where claimed rewards were sent to
  /// @param reward The amount of reward tokens to be distributed
  /// @param bonusReward The amount of bonus reward tokens to be distributed
  event FarmEnded(
    uint256 indexed tokenId,
    bytes32 indexed incentiveId,
    address indexed rewardAddress,
    address bonusRewardToken,
    address owner,
    uint256 reward,
    uint256 bonusReward
  );

  /// @notice Emitted when the incentive maker is changed
  /// @param incentiveMaker The incentive maker after the address was changed
  event IncentiveMaker(address indexed incentiveMaker);

  /// @notice Emitted when the farming center is changed
  /// @param farmingCenter The farming center after the address was changed
  event FarmingCenter(address indexed farmingCenter);

  /// @notice Event emitted when rewards were added
  /// @param rewardAmount The additional amount of main token
  /// @param bonusRewardAmount The additional amount of bonus token
  /// @param incentiveId The ID of the incentive for which rewards were added
  event RewardsAdded(uint256 rewardAmount, uint256 bonusRewardAmount, bytes32 incentiveId);

  event RewardAmountsDecreased(uint256 reward, uint256 bonusReward, bytes32 incentiveId);

  /// @notice Event emitted when a reward token has been claimed
  /// @param to The address where claimed rewards were sent to
  /// @param reward The amount of reward tokens claimed
  /// @param rewardAddress The token reward address
  /// @param owner The address where claimed rewards were sent to
  event RewardClaimed(address indexed to, uint256 reward, address indexed rewardAddress, address indexed owner);

  /// @notice Event emitted when reward rates were changed
  /// @param rewardRate The new rate of main token distribution per sec
  /// @param bonusRewardRate The new rate of bonus token distribution per sec
  /// @param incentiveId The ID of the incentive for which rates were changed
  event RewardsRatesChanged(uint128 rewardRate, uint128 bonusRewardRate, bytes32 incentiveId);

  /// @notice Event emitted when rewards were collected
  /// @param tokenId The ID of the token for which rewards were collected
  /// @param incentiveId The ID of the incentive for which rewards were collected
  /// @param rewardAmount Collected amount of reward
  /// @param bonusRewardAmount Collected amount of bonus reward
  event RewardsCollected(uint256 tokenId, bytes32 incentiveId, uint256 rewardAmount, uint256 bonusRewardAmount);

  /// @notice Event emitted when a liquidity mining incentive has been created
  /// @param rewardToken The token being distributed as a reward
  /// @param bonusRewardToken The token being distributed as a bonus reward
  /// @param pool The Algebra pool
  /// @param virtualPool The virtual pool address
  /// @param nonce The nonce of new farming
  /// @param reward The amount of reward tokens to be distributed
  /// @param bonusReward The amount of bonus reward tokens to be distributed
  /// @param minimalAllowedPositionWidth The minimal allowed position width (tickUpper - tickLower)
  event EternalFarmingCreated(
    IERC20Minimal indexed rewardToken,
    IERC20Minimal indexed bonusRewardToken,
    IAlgebraPool indexed pool,
    address virtualPool,
    uint256 nonce,
    uint256 reward,
    uint256 bonusReward,
    uint24 minimalAllowedPositionWidth
  );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.17;

import '@cryptoalgebra/core/contracts/interfaces/IAlgebraVirtualPool.sol';

interface IAlgebraEternalVirtualPool is IAlgebraVirtualPool {
  error onlyPool();
  error onlyFarming();

  // returns data associated with a tick
  function ticks(
    int24 tickId
  )
    external
    view
    returns (
      uint128 liquidityTotal,
      int128 liquidityDelta,
      uint256 outerFeeGrowth0Token,
      uint256 outerFeeGrowth1Token,
      int24 prevTick,
      int24 nextTick
    );

  // returns the current liquidity in virtual pool
  function currentLiquidity() external view returns (uint128);

  // returns the current tick in virtual pool
  function globalTick() external view returns (int24);

  // returns the timestamp after previous swap (like the last timepoint in a default pool)
  function prevTimestamp() external view returns (uint32);

  /// @dev This function is called when anyone farms their liquidity. The position in a virtual pool
  /// should be changed accordingly
  /// @param currentTimestamp The timestamp of current block
  /// @param bottomTick The bottom tick of a position
  /// @param topTick The top tick of a position
  /// @param liquidityDelta The amount of liquidity in a position
  /// @param currentTick The current tick in the main pool
  function applyLiquidityDeltaToPosition(uint32 currentTimestamp, int24 bottomTick, int24 topTick, int128 liquidityDelta, int24 currentTick) external;

  /// @dev This function is called from the main pool before every swap To increase rewards per liquidity
  /// cumulative considering previous liquidity. The liquidity is stored in a virtual pool
  function distributeRewards() external;

  /// @notice Change reward rates
  /// @param rate0 The new rate of main token distribution per sec
  /// @param rate1 The new rate of bonus token distribution per sec
  function setRates(uint128 rate0, uint128 rate1) external;

  /// @notice Top up rewards reserves
  /// @param token0Amount The amount of token0
  /// @param token1Amount The amount of token1
  function addRewards(uint128 token0Amount, uint128 token1Amount) external;

  /// @notice Withdraw rewards from reserves directly
  /// @param token0Amount The amount of token0
  /// @param token1Amount The amount of token1
  function decreaseRewards(uint128 token0Amount, uint128 token1Amount) external;

  function getInnerRewardsGrowth(int24 bottomTick, int24 topTick) external view returns (uint256 rewardGrowthInside0, uint256 rewardGrowthInside1);

  /// @notice Get reserves of rewards in one call
  /// @return reserve0 The reserve of token0
  /// @return reserve1 The reserve of token1
  function rewardReserves() external view returns (uint128 reserve0, uint128 reserve1);

  /// @notice Get rates of rewards in one call
  /// @return rate0 The rate of token0, rewards / sec
  /// @return rate1 The rate of token1, rewards / sec
  function rewardRates() external view returns (uint128 rate0, uint128 rate1);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import '@cryptoalgebra/core/contracts/interfaces/IAlgebraPool.sol';
import '@cryptoalgebra/core/contracts/interfaces/IERC20Minimal.sol';

import '@cryptoalgebra/periphery/contracts/interfaces/IMulticall.sol';
import '@cryptoalgebra/periphery/contracts/interfaces/INonfungiblePositionManager.sol';

import '../base/IncentiveKey.sol';
import '../interfaces/IAlgebraEternalFarming.sol';

interface IFarmingCenter is IMulticall {
  function virtualPoolAddresses(address) external view returns (address);

  /// @notice The nonfungible position manager with which this farming contract is compatible
  function nonfungiblePositionManager() external view returns (INonfungiblePositionManager);

  /// @notice The eternal farming contract
  function eternalFarming() external view returns (IAlgebraEternalFarming);

  /// @notice The Algebra poolDeployer contract
  function algebraPoolDeployer() external view returns (address);

  /// @notice Returns information about a deposited NFT
  /// @param tokenId The ID of the deposit (and token) that is being transferred
  /// @return eternalIncentiveId The id of eternal incentive that is active for this NFT
  function deposits(uint256 tokenId) external view returns (bytes32 eternalIncentiveId);

  /// @notice Updates activeIncentive in AlgebraPool
  /// @dev only farming can do it
  /// @param pool The AlgebraPool for which farming was created
  /// @param virtualPool The virtual pool to be connected
  function connectVirtualPool(IAlgebraPool pool, address virtualPool) external;

  /// @notice Enters in incentive (time-limited or eternal farming) with NFT-position token
  /// @dev token must be deposited in FarmingCenter
  /// @param key The incentive event key
  /// @param tokenId The id of position NFT
  function enterFarming(IncentiveKey memory key, uint256 tokenId) external;

  /// @notice Exits from incentive (time-limited or eternal farming) with NFT-position token
  /// @param key The incentive event key
  /// @param tokenId The id of position NFT
  function exitFarming(IncentiveKey memory key, uint256 tokenId) external;

  /// @notice Used to collect reward from eternal farming. Then reward can be claimed.
  /// @param key The incentive event key
  /// @param tokenId The id of position NFT
  /// @return reward The amount of collected reward
  /// @return bonusReward The amount of collected  bonus reward
  function collectRewards(IncentiveKey memory key, uint256 tokenId) external returns (uint256 reward, uint256 bonusReward);

  /// @notice Used to claim and send rewards from farming(s)
  /// @dev can be used via static call to get current rewards for user
  /// @param rewardToken The token that is a reward
  /// @param to The address to be rewarded
  /// @param amountRequested Amount to claim in eternal farming
  /// @return reward The summary amount of claimed rewards
  function claimReward(IERC20Minimal rewardToken, address to, uint256 amountRequested) external returns (uint256 reward);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.17;

import '../base/IncentiveKey.sol';

library IncentiveId {
  /// @notice Calculate the key for a staking incentive
  /// @param key The components used to compute the incentive identifier
  /// @return incentiveId The identifier for the incentive
  function compute(IncentiveKey memory key) internal pure returns (bytes32 incentiveId) {
    return keccak256(abi.encode(key));
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.17;

import '@cryptoalgebra/core/contracts/interfaces/IAlgebraPool.sol';
import '@cryptoalgebra/core/contracts/interfaces/IAlgebraPoolDeployer.sol';
import '@cryptoalgebra/periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@cryptoalgebra/periphery/contracts/libraries/PoolAddress.sol';

/// @notice Encapsulates the logic for getting info about a NFT token ID
library NFTPositionInfo {
  /// @param deployer The address of the Algebra Deployer used in computing the pool address
  /// @param nonfungiblePositionManager The address of the nonfungible position manager to query
  /// @param tokenId The unique identifier of an Algebra LP token
  /// @return pool The address of the Algebra pool
  /// @return tickLower The lower tick of the Algebra position
  /// @return tickUpper The upper tick of the Algebra position
  /// @return liquidity The amount of liquidity farmd
  function getPositionInfo(
    IAlgebraPoolDeployer deployer,
    INonfungiblePositionManager nonfungiblePositionManager,
    uint256 tokenId
  ) internal view returns (IAlgebraPool pool, int24 tickLower, int24 tickUpper, uint128 liquidity) {
    address token0;
    address token1;
    (, , token0, token1, tickLower, tickUpper, liquidity, , , , ) = nonfungiblePositionManager.positions(tokenId);

    pool = IAlgebraPool(PoolAddress.computeAddress(address(deployer), PoolAddress.PoolKey({token0: token0, token1: token1})));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import '@cryptoalgebra/core/contracts/interfaces/IAlgebraPoolErrors.sol';

import '@cryptoalgebra/core/contracts/libraries/TickMath.sol';
import '@cryptoalgebra/core/contracts/libraries/LiquidityMath.sol';
import '@cryptoalgebra/core/contracts/libraries/Constants.sol';

/// @title VirtualTickManagement
/// @notice Contains functions for managing tick processes and relevant calculations
library VirtualTickManagement {
  // info stored for each initialized individual tick
  struct Tick {
    uint128 liquidityTotal; // the total position liquidity that references this tick
    int128 liquidityDelta; // amount of net liquidity added (subtracted) when tick is crossed left-right (right-left),
    // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint256 outerFeeGrowth0Token;
    uint256 outerFeeGrowth1Token;
    int24 prevTick;
    int24 nextTick;
  }

  /// @notice Retrieves fee growth data
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param bottomTick The lower tick boundary of the position
  /// @param topTick The upper tick boundary of the position
  /// @param currentTick The current tick
  /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
  /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
  /// @return innerFeeGrowth0Token The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
  /// @return innerFeeGrowth1Token The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
  function getInnerFeeGrowth(
    mapping(int24 => Tick) storage self,
    int24 bottomTick,
    int24 topTick,
    int24 currentTick,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token
  ) internal view returns (uint256 innerFeeGrowth0Token, uint256 innerFeeGrowth1Token) {
    Tick storage lower = self[bottomTick];
    Tick storage upper = self[topTick];

    unchecked {
      if (currentTick < topTick) {
        if (currentTick >= bottomTick) {
          innerFeeGrowth0Token = totalFeeGrowth0Token - lower.outerFeeGrowth0Token;
          innerFeeGrowth1Token = totalFeeGrowth1Token - lower.outerFeeGrowth1Token;
        } else {
          innerFeeGrowth0Token = lower.outerFeeGrowth0Token;
          innerFeeGrowth1Token = lower.outerFeeGrowth1Token;
        }
        innerFeeGrowth0Token -= upper.outerFeeGrowth0Token;
        innerFeeGrowth1Token -= upper.outerFeeGrowth1Token;
      } else {
        innerFeeGrowth0Token = upper.outerFeeGrowth0Token - lower.outerFeeGrowth0Token;
        innerFeeGrowth1Token = upper.outerFeeGrowth1Token - lower.outerFeeGrowth1Token;
      }
    }
  }

  /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param tick The tick that will be updated
  /// @param currentTick The current tick
  /// @param liquidityDelta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
  /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
  /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
  /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
  /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
  function update(
    mapping(int24 => Tick) storage self,
    int24 tick,
    int24 currentTick,
    int128 liquidityDelta,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token,
    bool upper
  ) internal returns (bool flipped) {
    Tick storage data = self[tick];

    int128 liquidityDeltaBefore = data.liquidityDelta;
    uint128 liquidityTotalBefore = data.liquidityTotal;

    uint128 liquidityTotalAfter = LiquidityMath.addDelta(liquidityTotalBefore, liquidityDelta);
    if (liquidityTotalAfter > Constants.MAX_LIQUIDITY_PER_TICK) revert IAlgebraPoolErrors.liquidityOverflow();

    // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
    data.liquidityDelta = upper ? int128(int256(liquidityDeltaBefore) - liquidityDelta) : int128(int256(liquidityDeltaBefore) + liquidityDelta);

    data.liquidityTotal = liquidityTotalAfter;

    flipped = (liquidityTotalAfter == 0);
    if (liquidityTotalBefore == 0) {
      flipped = !flipped;
      // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
      if (tick <= currentTick) {
        data.outerFeeGrowth0Token = totalFeeGrowth0Token;
        data.outerFeeGrowth1Token = totalFeeGrowth1Token;
      }
    }
  }

  /// @notice Transitions to next tick as needed by price movement
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param tick The destination tick of the transition
  /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
  /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
  /// @return liquidityDelta The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
  function cross(
    mapping(int24 => Tick) storage self,
    int24 tick,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token
  ) internal returns (int128 liquidityDelta) {
    Tick storage data = self[tick];

    unchecked {
      data.outerFeeGrowth1Token = totalFeeGrowth1Token - data.outerFeeGrowth1Token;
      data.outerFeeGrowth0Token = totalFeeGrowth0Token - data.outerFeeGrowth0Token;
    }
    return data.liquidityDelta;
  }

  /// @notice Used for initial setup of ticks list
  /// @param self The mapping containing all tick information for initialized ticks
  function initTickState(mapping(int24 => Tick) storage self) internal {
    (self[TickMath.MIN_TICK].prevTick, self[TickMath.MIN_TICK].nextTick) = (TickMath.MIN_TICK, TickMath.MAX_TICK);
    (self[TickMath.MAX_TICK].prevTick, self[TickMath.MAX_TICK].nextTick) = (TickMath.MIN_TICK, TickMath.MAX_TICK);
  }

  /// @notice Removes tick from linked list
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param tick The tick that will be removed
  /// @return prevTick
  function removeTick(mapping(int24 => Tick) storage self, int24 tick) internal returns (int24) {
    (int24 prevTick, int24 nextTick) = (self[tick].prevTick, self[tick].nextTick);
    delete self[tick];

    if (tick == TickMath.MIN_TICK || tick == TickMath.MAX_TICK) {
      // MIN_TICK and MAX_TICK cannot be removed from tick list
      (self[tick].prevTick, self[tick].nextTick) = (prevTick, nextTick);
      return prevTick;
    } else {
      if (prevTick == nextTick) revert IAlgebraPoolErrors.tickIsNotInitialized();
      self[prevTick].nextTick = nextTick;
      self[nextTick].prevTick = prevTick;
      return prevTick;
    }
  }

  /// @notice Adds tick to linked list
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param tick The tick that will be inserted
  /// @param prevTick The previous active tick
  /// @param nextTick The next active tick
  function insertTick(mapping(int24 => Tick) storage self, int24 tick, int24 prevTick, int24 nextTick) internal {
    if (tick == TickMath.MIN_TICK || tick == TickMath.MAX_TICK) return;
    if (prevTick >= tick || nextTick <= tick) revert IAlgebraPoolErrors.tickInvalidLinks();
    (self[tick].prevTick, self[tick].nextTick) = (prevTick, nextTick);

    self[prevTick].nextTick = tick;
    self[nextTick].prevTick = tick;
  }
}