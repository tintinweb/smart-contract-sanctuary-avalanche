/**
 *Submitted for verification at snowtrace.io on 2023-06-08
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org
// SPDX-License-Identifier: BUSL-1.1
// File contracts/elixir-core/interfaces/IElixirFactory.sol

pragma solidity >=0.5.0;

/// @title The interface for the Elixir Factory
/// @notice The Elixir Factory facilitates creation of Elixir pools and control over the protocol fees
interface IElixirFactory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the implementation contract of the pool
    /// @return The address of the pool implementation
    function implementation() external view returns (address);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}


// File contracts/elixir-core/interfaces/pool/IElixirPoolActions.sol

pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IElixirPoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IElixirMintCallback#elixirMintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IElixirSwapCallback#elixirSwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IElixirFlashCallback#elixirFlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}


// File contracts/elixir-core/interfaces/pool/IElixirPoolDerivedState.sol

pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IElixirPoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s,
            uint192[] memory rewardPerLiquidityCumulativeX64s
        );

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside,
            uint192 rewardPerLiquidityInsideX64
        );
}


// File contracts/elixir-core/interfaces/pool/IElixirPoolEvents.sol

pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IElixirPoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);

    /// @notice Emitted when the reward rate is changed by the owner
    /// @param rewardPerSecondX48 The new reward rate per second (in Q48)
    /// @param rewardRateEffectiveUntil The timestamp when the new reward rate will expire
    event SetRewardRate(uint144 rewardPerSecondX48, uint32 rewardRateEffectiveUntil);
}


// File contracts/elixir-core/interfaces/pool/IElixirPoolImmutables.sol

pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IElixirPoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IElixirFactory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}


// File contracts/elixir-core/interfaces/pool/IElixirPoolOwnerActions.sol

pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IElixirPoolOwnerActions {
    /// @notice Initialize the pool to set immutable parameters
    /// @param _token0 The first of the two tokens of the pool, sorted by address
    /// @param _token1 The second of the two tokens of the pool, sorted by address
    /// @param _fee The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @param _tickSpacing The pool tick spacing
    function initialize(address _token0, address _token1, uint24 _fee, int24 _tickSpacing) external;

    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Set the reward rate the active liquidity receives per second
    /// @param rewardPerSecondX48 The new reward rate per second (in Q48)
    /// @param rewardRateEffectiveUntil The timestamp when the new reward rate will expire
    function setRewardRate(uint144 rewardPerSecondX48, uint32 rewardRateEffectiveUntil) external;
}


// File contracts/elixir-core/interfaces/pool/IElixirPoolState.sol

pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IElixirPoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The rewardSlot storage slot in the pool stores variables necessary to update
    /// Oracle.Observation.rewardPerLiquidityCumulativeX64 accumulator.
    /// @dev Both of the variables can be set arbitrarily by the owner. The pool does not set any restrictions on the
    /// values other than their variable types. The factory owner should relegate the setting of these variables to a
    /// reward contract that will update these variables based on a proper reward distribution logic.
    /// @return rewardPerSecondX48 The rewards per second promised to be distributed to the pool as a Q96.48 value
    /// rewardRateEffectiveUntil The timestamp when the rewardPerSecondX48 is no longer effective
    function rewardSlot()
        external
        view
        returns (uint144 rewardPerSecondX48, uint32 rewardRateEffectiveUntil);

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees()
        external
        view
        returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(
        int24 tick
    )
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized,
            uint192 rewardPerLiquidityOutsideX64
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(
        bytes32 key
    )
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    /// Returns rewardPerLiquidityCumulativeX64 reward per liquidity
    function observations(
        uint256 index
    )
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized,
            uint192 rewardPerLiquidityCumulativeX64
        );
}


// File contracts/elixir-core/interfaces/IElixirPool.sol

pragma solidity >=0.5.0;






/// @title The interface for a Elixir Pool
/// @notice A Pangolin pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IElixirPool is
    IElixirPoolImmutables,
    IElixirPoolState,
    IElixirPoolDerivedState,
    IElixirPoolActions,
    IElixirPoolOwnerActions,
    IElixirPoolEvents
{

}


// File openzeppelin-contracts-solc-0.7/proxy/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}


// File contracts/elixir-core/ElixirFactory.sol

pragma solidity =0.7.6;


/// @title Canonical Elixir factory
/// @notice Deploys Elixir pools and manages ownership and control over pool protocol fees
contract ElixirFactory is IElixirFactory {
    /// @inheritdoc IElixirFactory
    address public immutable override implementation;

    /// @inheritdoc IElixirFactory
    address public override owner;

    /// @inheritdoc IElixirFactory
    mapping(uint24 => int24) public override feeAmountTickSpacing;
    /// @inheritdoc IElixirFactory
    mapping(address => mapping(address => mapping(uint24 => address)))
        public
        override getPool;

    constructor(address _implementation) {
        implementation = _implementation;

        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);
    }

    /// @inheritdoc IElixirFactory
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0);
        require(getPool[token0][token1][fee] == address(0));
        pool = Clones.cloneDeterministic(
            implementation,
            keccak256(abi.encode(token0, token1, fee))
        );
        IElixirPool(pool).initialize(token0, token1, fee, tickSpacing);
        getPool[token0][token1][fee] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][fee] = pool;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

    /// @inheritdoc IElixirFactory
    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc IElixirFactory
    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {
        require(msg.sender == owner);
        require(fee < 1000000);
        // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
        // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
        // 16384 ticks represents a >5x price change with ticks of 1 bips
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(feeAmountTickSpacing[fee] == 0);

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }
}