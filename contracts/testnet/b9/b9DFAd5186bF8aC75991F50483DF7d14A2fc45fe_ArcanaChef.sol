// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.15;

import "./ArcanaChefFunding.sol";
import "./ReentrancyGuard.sol";

import "./interfaces/IWAVAX.sol";
import "./interfaces/IArcanumFactory.sol";
import "./interfaces/IArcanumPair.sol";
import "./interfaces/IRewarder.sol";

/**
 * @title ArcanaChef
 * @author Shung for PangoChef
 * @notice ArcanaChef is a MiniChef alternative that utilizes the Sunshine and Rainbows algorithm of PangoChef
 *         for distributing rewards from pools to stakers.
 */
contract ArcanaChef is ArcanaChefFunding, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    enum PoolType {
        // UNSET_POOL is used to check if a pool is initialized.
        UNSET_POOL,
        // ERC20_POOL distributes its share of rewards to any number of ERC20 token stakers.
        ERC20_POOL,
        // RELAYER_POOL sends all its rewards to a single recipient address.
        RELAYER_POOL
    }

    enum StakeType {
        // In REGULAR staking, user supplies the amount of tokens to be staked.
        REGULAR,
        // In COMPOUND staking, rewards from the pool are paired with another reserve token
        // supplied by the user, and the created pool token is staked to the same pool as where
        // the rewards come from.
        COMPOUND,
        // In COMPOUND_TO_POOL_ZERO staking, rewards from any pool are paired with the native gas
        // token supplied by the user, to be staked to pool zero.
        COMPOUND_TO_POOL_ZERO
    }

    struct Slippage {
        // The minimum amount of paired tokens that has to be withdrawn from user.
        uint256 minPairAmount;
        // The maximum amount of paired tokens that can be withdrawn from user.
        uint256 maxPairAmount;
    }

    struct ValueVariables {
        // The amount of tokens staked by the user in the pool or total staked in the pool.
        uint104 balance;
        // The sum of each staked token multiplied by its update time.
        uint152 sumOfEntryTimes;
    }

    struct RewardSummations {
        // Imaginary rewards accrued by a position with `lastUpdate == 0 && balance == 1`. At the
        // end of each interval, the ideal position has a staking duration of `block.timestamp`.
        // Since its balance is one, its “value” equals its staking duration. So, its value
        // is also `block.timestamp` , and for a given reward at an interval, the ideal position
        // accrues `reward * block.timestamp / totalValue`. Refer to `Ideal Position` section of
        // the Proofs on why we need this variable.
        uint256 idealPosition;
        // The sum of `reward/totalValue` of each interval. `totalValue` is the sum of all staked
        // tokens multiplied by their respective staking durations.  On every update, the
        // `rewardPerValue` is incremented by rewards given during that interval divided by the
        // total value, which is average staking duration multiplied by total staked. See proofs.
        uint256 rewardPerValue;
    }

    struct User {
        // Two variables that specify the share of rewards a user must receive from the pool.
        ValueVariables valueVariables;
        // Summations snapshotted on the last update of the user.
        RewardSummations rewardSummationsPaid;
        // The sum of values (`balance * (block.timestamp - lastUpdate)`) of previous intervals.
        // It is only incremented accordingly when tokens are staked, and it is reset to zero
        // when tokens are withdrawn. Correctly updating this property allows for the staking
        // duration of the existing balance of the user to not restart when staking more tokens.
        // So it allows combining together tokens with differing staking durations. Refer to the
        // `Combined Positions` section of the Proofs on why this works.
        uint152 previousValues;
        // The last time the user info was updated.
        uint48 lastUpdate;
        // When a user uses the rewards of a pool to compound into pool zero, the pool zero gets
        // locked until that pool has its staking duration reset. Otherwise people can exploit
        // the `compoundToPoolZero()` function to harvest rewards of a pool without resetting its
        // staking duration, which would defeat the purpose of using SAR algorithm.
        bool isLockingPoolZero;
        // Rewards of the user gets stashed when user’s summations are updated without
        // harvesting the rewards or without utilizing the rewards in compounding.
        uint96 stashedRewards;
    }

    struct Pool {
        // The address of the token when poolType is ERC_20, or the recipient address when poolType
        // is RELAYER_POOL.
        address tokenOrRecipient;
        // The type of the pool, which determines which actions can be performed on it.
        PoolType poolType;
        // An external contract that distributes additional rewards.
        IRewarder rewarder;
        // The address that is paired with ARC. It is zero address if the pool token is not a
        // liquidity pool token, or if the liquidity pool do not have ARC as one of the reserves.
        address rewardPair;
        // Two variables that specify the total shares (i.e.: “value”) in the pool.
        ValueVariables valueVariables;
        // Summations incremented on every action on the pool.
        RewardSummations rewardSummationsStored;
        // The mapping from addresses of the users of the pool to their properties.
        mapping(address => User) users;
    }

    /** @notice The mapping from poolIds to the pool infos. */
    mapping(uint256 => Pool) public pools;

    /**
     * @notice The mapping from user addresses to the number of pools the user has that are locking
     *         the pool zero. User can only withdraw from pool zero if the lock count is zero.
     */
    mapping(address => uint256) public poolZeroLockCount;

    /** @notice Record latest timestamps of low-level call fails, so Rewarder can slash rewards. */
    mapping(uint256 => mapping(address => uint256))
        public lastTimeRewarderCallFailed;

    /** @notice The UNI-V2 factory that creates pair tokens. */
    IArcanumFactory public immutable factory;

    /** @notice The contract for wrapping and unwrapping the native gas token (e.g.: WETH). */
    address public immutable wrappedNativeToken;

    /** @notice The number of pools in the contract. */
    uint256 private _poolsLength = 0;

    /** @notice The maximum amount of tokens that can be staked in a pool. */
    uint256 private constant MAX_STAKED_AMOUNT_IN_POOL = type(uint104).max;

    /** @notice The fixed denominator used for storing summations. */
    uint256 private constant PRECISION = 2**128;

    /** @notice The event emitted when withdrawing or harvesting from a position. */
    event Withdrawn(
        uint256 indexed positionId,
        address indexed userId,
        uint256 indexed amount,
        uint256 reward
    );

    /** @notice The event emitted when staking to, minting, or compounding a position. */
    event Staked(
        uint256 indexed positionId,
        address indexed userId,
        uint256 indexed amount,
        uint256 reward
    );

    /** @notice The event emitted when a pool is created. */
    event PoolInitialized(
        uint256 indexed poolId,
        address indexed tokenOrRecipient
    );

    /** @notice The event emitted when the rewarder of a pool is changed. */
    event RewarderSet(uint256 indexed poolId, address indexed rewarder);

    /**
     * @notice Constructor to create and initialize ArcanaChef contract.
     * @param newRewardsToken The token distributed as reward (i.e.: ARC).
     * @param newAdmin The initial owner of the contract.
     * @param newFactory The Arcanum factory that creates and records AMM pairs.
     * @param newWrappedNativeToken The contract for wrapping and unwrapping the native gas token.
     */
    constructor(
        address newRewardsToken,
        address newAdmin,
        IArcanumFactory newFactory,
        address newWrappedNativeToken
    ) ArcanaChefFunding(newRewardsToken, newAdmin) {
        // Get WAVAX-ARC (or WETH-ARC, etc.) liquidity token.
        address poolZeroPair = newFactory.getPair(
            newRewardsToken,
            newWrappedNativeToken
        );

        // Check pair exists, which implies `newRewardsToken != 0 && newWrappedNativeToken != 0`.
        if (poolZeroPair == address(0)) revert NullInput();

        // Initialize pool zero with WAVAX-ARC liquidity token.
        _initializePool(poolZeroPair, PoolType.ERC20_POOL);
        pools[0].rewardPair = newWrappedNativeToken;

        // Initialize the immutable state variables.
        factory = newFactory;
        wrappedNativeToken = newWrappedNativeToken;
    }

    /**
     * @notice External restricted function to change the rewarder of a pool.
     * @param poolId The identifier of the pool to change the rewarder of.
     * @param rewarder The address of the new rewarder.
     */
    function setRewarder(uint256 poolId, address rewarder)
        external
        onlyRole(POOL_MANAGER_ROLE)
    {
        Pool storage pool = pools[poolId];
        _onlyERC20Pool(pool);
        pool.rewarder = IRewarder(rewarder);
        emit RewarderSet(poolId, rewarder);
    }

    /**
     * @notice External restricted function to initialize/create a pool.
     * @param tokenOrRecipient The token used in staking, or the sole recipient of the rewards.
     * @param poolType The pool type, which should either be ERC20_POOL, or RELAYER_POOL.
     *                 ERC20_POOL is a regular staking pool, in which anyone can stake the token
     *                 to receive rewards. In RELAYER_POOL, there is only one recipient of the
     *                 rewards. RELAYER_POOL is used for diverting token emissions.
     */
    function initializePool(address tokenOrRecipient, PoolType poolType)
        external
        onlyRole(POOL_MANAGER_ROLE)
    {
        _initializePool(tokenOrRecipient, poolType);
    }

    /**
     * @notice External function to stake to a pool.
     * @param poolId The identifier of the pool to stake to.
     * @param amount The amount of pool tokens to stake.
     */
    function stake(uint256 poolId, uint256 amount) external notEntered {
        _stake(poolId, msg.sender, amount, StakeType.REGULAR, Slippage(0, 0));
    }

    /**
     * @notice External function to stake to a pool on behalf of another user.
     * @param poolId The identifier of the pool to stake to.
     * @param userId The address of the pool to stake for.
     * @param amount The amount of pool tokens to stake.
     */
    function stakeTo(
        uint256 poolId,
        address userId,
        uint256 amount
    ) external notEntered {
        _stake(poolId, userId, amount, StakeType.REGULAR, Slippage(0, 0));
    }

    /**
     * @notice External function to stake to a pool using the rewards of the pool.
     * @dev This function only works if the staking token is a Arcanum liquidity token (ARL), and
     *      one of its reserves is the rewardsToken (ARC). The user must supply sufficient amount
     *      of the other reserve to be combined with ARC. The rewards and the user supplied pair
     *      token is then used to mint a liquidity pool token, which must be the same token as the
     *      staking token.
     * @param poolId The identifier of the pool to compound.
     * @param slippage A struct defining the minimum and maximum amounts of tokens that can be
     *                 paired with reward token.
     */
    function compound(uint256 poolId, Slippage calldata slippage)
        external
        payable
        nonReentrant
    {
        _stake(poolId, msg.sender, 0, StakeType.COMPOUND, slippage);
    }

    /**
     * @notice External function to withdraw and harvest from a pool.
     * @param poolId The identifier of the pool to withdraw and harvest from.
     * @param amount The amount of pool tokens to withdraw.
     */
    function withdraw(uint256 poolId, uint256 amount) external notEntered {
        _withdraw(poolId, amount);
    }

    /**
     * @notice External function to harvest rewards from a pool.
     * @param poolId The identifier of the pool to harvest from.
     */
    function harvest(uint256 poolId) external notEntered {
        _withdraw(poolId, 0);
    }

    /**
     * @notice External function to stake to pool zero (e.g.: ARC-WAVAX ARL) using the rewards of
     *         any other ERC20_POOL.
     * @dev The user must supply sufficient amount of the gas token (e.g.: AVAX/WAVAX) to be
     *      paired with the rewardsToken (e.g.:ARC).
     * @param poolId The identifier of the pool to harvest the rewards of to compound to pool zero.
     * @param slippage A struct defining the minimum and maximum amounts of tokens that can be
     *                 paired with reward token.
     */
    function compoundToPoolZero(uint256 poolId, Slippage calldata slippage)
        external
        payable
        nonReentrant
    {
        // Harvest rewards from the provided pool. This does not reset the staking duration, but
        // it will increment the lock on pool zero. The lock on pool zero will be decremented
        // whenever the provided pool has its staking duration reset (e.g.: through `_withdraw()`).
        uint256 reward = _harvestWithoutReset(poolId);

        // Stake to pool zero using special staking method, which will add liquidity using rewards
        // harvested from the provided pool.
        _stake(
            0,
            msg.sender,
            reward,
            StakeType.COMPOUND_TO_POOL_ZERO,
            slippage
        );
    }

    /**
     * @notice External function to exit from a pool by forgoing rewards.
     * @param poolId The identifier of the pool to exit from.
     */
    function emergencyExitLevel1(uint256 poolId) external nonReentrant {
        _emergencyExit(poolId, true);
    }

    /**
     * @notice External function to exit from a pool by forgoing the stake and rewards.
     * @dev This is an extreme emergency function, used only to save pool zero from perpetually
     *      remaining locked if there is a DOS on the staking token.
     * @param poolId The identifier of the pool to exit from.
     */
    function emergencyExitLevel2(uint256 poolId) external nonReentrant {
        _emergencyExit(poolId, false);
    }

    /**
     * @notice External function to claim/harvest the rewards from a RELAYER_POOL.
     * @param poolId The identifier of the pool to claim the rewards of.
     * @return reward The amount of rewards that was harvested.
     */
    function claim(uint256 poolId)
        external
        notEntered
        returns (uint256 reward)
    {
        // Create a storage pointer for the pool.
        Pool storage pool = pools[poolId];

        // Ensure pool is RELAYER type.
        _onlyRelayerPool(pool);

        // Ensure only relayer itself can claim the rewards.
        if (msg.sender != pool.tokenOrRecipient) revert UnprivilegedCaller();

        // Get the pool’s rewards.
        reward = _claim(poolId);

        // Transfer rewards from the contract to the user, and emit the associated event.
        if (reward != 0) rewardsToken.safeTransfer(msg.sender, reward);
        emit Withdrawn(poolId, msg.sender, 0, reward);
    }

    /**
     * @notice External view function to get the info about a user of a pool
     * @param poolId The identifier of the pool the user is in.
     * @param userId The address of the user in the pool.
     * @return The user struct that contains all the information of the user
     */
    function getUser(uint256 poolId, address userId)
        external
        view
        returns (User memory)
    {
        return pools[poolId].users[userId];
    }

    /**
     * @notice External view function to get the reward rate of a user of a pool.
     * @dev In SAR, users have different APRs, unlike other staking algorithms. This external
     *      function clearly demonstrates how the SAR algorithm is supposed to distribute the
     *      rewards based on “value”, which is balance times staking duration. This external
     *      function can be considered as a specification.
     * @param poolId The identifier of the pool the user is in.
     * @param userId The address of the user in the pool.
     * @return The rewards per second of the user.
     */
    function userRewardRate(uint256 poolId, address userId)
        external
        view
        returns (uint256)
    {
        // Get totalValue and positionValue.
        Pool storage pool = pools[poolId];
        uint256 poolValue = _getValue(pool.valueVariables);
        uint256 userValue = _getValue(pool.users[userId].valueVariables);

        // Return the rewardRate of the user. Do not revert if poolValue is zero.
        return
            userValue == 0
                ? 0
                : (poolRewardRate(poolId) * userValue) / poolValue;
    }

    /**
     * @notice External view function to get the accrued rewards of a user. It calculates all the
     *         pending rewards from user’s last update until the block timestamp.
     * @param poolId The identifier of the pool the user is in.
     * @param userId The address of the user in the pool.
     * @return The amount of rewards that have been accrued in the position.
     */
    function userPendingRewards(uint256 poolId, address userId)
        external
        view
        returns (uint256)
    {
        // Create a storage pointer for the position.
        Pool storage pool = pools[poolId];
        User storage user = pool.users[userId];

        // Get the delta of summations. Use incremented in-memory `rewardSummationsStored`
        // based on the pending rewards.
        RewardSummations
            memory deltaRewardSummations = _getDeltaRewardSummations(
                poolId,
                pool,
                user,
                true
            );

        // Return the pending rewards of the user based on the difference in rewardSummations.
        return _earned(deltaRewardSummations, user);
    }

    /** @inheritdoc ArcanaChefFunding*/
    function poolsLength() public view override returns (uint256) {
        return _poolsLength;
    }

    /**
     * @notice Private function to deposit tokens to a pool.
     * @param poolId The identifier of the pool to deposit to.
     * @param userId The address of the user to deposit for.
     * @param amount The amount of staking tokens to deposit when stakeType is REGULAR.
     *               It should be zero when the stakeType is COMPOUND.
     *               The reward to pair with gas token when stakeType is COMPOUND_TO_POOL_ZERO.
     * @param stakeType The staking method (i.e.: staking, compounding, compounding to pool zero).
     * @param slippage A struct defining the minimum and maximum amounts of tokens that can be
     *                 paired with reward token.
     */
    function _stake(
        uint256 poolId,
        address userId,
        uint256 amount,
        StakeType stakeType,
        Slippage memory slippage
    ) private {
        // Create a storage pointers for the pool and the user.
        Pool storage pool = pools[poolId];
        User storage user = pool.users[userId];

        // Ensure pool is ERC20 type.
        _onlyERC20Pool(pool);

        // Update the summations that govern the distribution from a pool to its stakers.
        ValueVariables storage poolValueVariables = pool.valueVariables;
        uint256 poolBalance = poolValueVariables.balance;
        if (poolBalance != 0) _updateRewardSummations(poolId, pool);

        // Before everything else, get the rewards accrued by the user. Rewards are not transferred
        // to the user in this function. Therefore they need to be either stashed or compounded.
        uint256 reward = _userPendingRewards(poolId, pool, user);

        uint256 transferAmount = 0;
        // Regular staking.
        if (stakeType == StakeType.REGULAR) {
            // Mark the input amount to be transferred from the caller to the contract.
            transferAmount = amount;

            // Rewards are not harvested. Therefore stash the rewards.
            user.stashedRewards = uint96(reward);
            reward = 0;
            // Staking into pool zero using harvested rewards from another pool.
        } else if (stakeType == StakeType.COMPOUND_TO_POOL_ZERO) {
            assert(poolId == 0);

            // Add liquidity using the rewards of another pool.
            amount = _addLiquidity(pool, amount, slippage);

            // Rewards used in compounding comes from other pools. Therefore stash the rewards of
            // this pool, which is neither harvested nor used in compounding.
            user.stashedRewards = uint96(reward);
            reward = 0;
            // Compounding.
        } else {
            assert(stakeType == StakeType.COMPOUND);
            assert(amount == 0);

            // Ensure the pool token is a Arcanum pair token containing ARC as one of the pairs.
            _setRewardPair(pool);

            // Add liquidity using the rewards of this pool.
            amount = _addLiquidity(pool, reward, slippage);

            // Rewards used in compounding comes from this pool. So clear stashed rewards.
            user.stashedRewards = 0;
        }

        // Ensure either user is adding more stake, or compounding.
        if (amount == 0) revert NoEffect();

        // Scope to prevent stack to deep errors.
        uint256 newBalance;
        {
            // Get the new total staked amount and ensure it fits MAX_STAKED_AMOUNT_IN_POOL.
            uint256 newTotalStaked = poolBalance + amount;
            if (newTotalStaked > MAX_STAKED_AMOUNT_IN_POOL) revert Overflow();
            unchecked {
                // Increment the pool info pertaining to pool’s total value calculation.
                uint152 addedEntryTimes = uint152(block.timestamp * amount);
                poolValueVariables.sumOfEntryTimes += addedEntryTimes;
                poolValueVariables.balance = uint104(newTotalStaked);

                // Increment the user info pertaining to user value calculation.
                ValueVariables storage userValueVariables = user.valueVariables;
                uint256 oldBalance = userValueVariables.balance;
                newBalance = oldBalance + amount;
                userValueVariables.balance = uint104(newBalance);
                userValueVariables.sumOfEntryTimes += addedEntryTimes;

                // Increment the previousValues. This allows staking duration to not reset when
                // reward summations are snapshotted.
                user.previousValues += uint152(
                    oldBalance * (block.timestamp - user.lastUpdate)
                );
            }
        }

        // Snapshot the lastUpdate and summations.
        _snapshotRewardSummations(pool, user);

        // Transfer amount tokens from caller to the contract, and emit the staking event.
        if (transferAmount != 0) {
            ERC20(pool.tokenOrRecipient).safeTransferFrom(
                msg.sender,
                address(this),
                transferAmount
            );
        }
        emit Staked(poolId, userId, amount, reward);

        // If rewarder exists, notify the reward amount.
        IRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onReward(poolId, userId, false, reward, newBalance);
        }
    }

    /**
     * @notice Private function to withdraw and harvest from a pool.
     * @param poolId The identifier of the pool to withdraw from.
     * @param amount The amount of tokens to withdraw. Zero amount only harvests rewards.
     */
    function _withdraw(uint256 poolId, uint256 amount) private {
        // Create a storage pointer for the pool and the user.
        Pool storage pool = pools[poolId];
        User storage user = pool.users[msg.sender];

        // Ensure pool is ERC20 type.
        _onlyERC20Pool(pool);

        // Update pool summations that govern the reward distribution from pool to users.
        _updateRewardSummations(poolId, pool);

        // Ensure pool zero is not locked.
        // Decrement lock count on pool zero if this pool was locking it.
        _decrementLockOnPoolZero(poolId, user);

        // Get position balance and ensure sufficient balance exists.
        ValueVariables storage userValueVariables = user.valueVariables;
        uint256 oldBalance = userValueVariables.balance;
        if (amount > oldBalance) revert InsufficientBalance();

        // Before everything else, get the rewards accrued by the user, then delete the user stash.
        uint256 reward = _userPendingRewards(poolId, pool, user);
        user.stashedRewards = 0;

        // Ensure we are either withdrawing something or claiming rewards.
        if (amount == 0 && reward == 0) revert NoEffect();

        uint256 remaining;
        unchecked {
            // Get the remaining balance in the position.
            remaining = oldBalance - amount;

            // Decrement the withdrawn amount from totalStaked.
            ValueVariables storage poolValueVariables = pool.valueVariables;
            poolValueVariables.balance -= uint104(amount);

            // Update sumOfEntryTimes.
            uint256 newEntryTimes = block.timestamp * remaining;
            poolValueVariables.sumOfEntryTimes = uint152(
                poolValueVariables.sumOfEntryTimes +
                    newEntryTimes -
                    userValueVariables.sumOfEntryTimes
            );

            // Decrement the withdrawn amount from user balance, and update the user entry times.
            userValueVariables.balance = uint104(remaining);
            userValueVariables.sumOfEntryTimes = uint152(newEntryTimes);
        }

        // Reset the previous values, as we have restarted the staking duration.
        user.previousValues = 0;

        // Snapshot the lastUpdate and summations.
        _snapshotRewardSummations(pool, user);

        // Transfer withdrawn tokens.
        if (reward != 0) rewardsToken.safeTransfer(msg.sender, reward);
        if (amount != 0)
            ERC20(pool.tokenOrRecipient).safeTransfer(msg.sender, amount);
        emit Withdrawn(poolId, msg.sender, amount, reward);

        // Get extra rewards from rewarder if it is not an emergency exit.
        IRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onReward(poolId, msg.sender, true, reward, remaining);
        }
    }

    /**
     * @notice Private function to harvest from a pool without resetting its staking duration.
     * @dev Harvested rewards must not leave the contract, so that they can be used in compounding.
     * @param poolId The identifier of the pool to harvest from.
     * @return reward The amount of harvested rewards.
     */
    function _harvestWithoutReset(uint256 poolId)
        private
        returns (uint256 reward)
    {
        // Create a storage pointer for the pool and the user.
        Pool storage pool = pools[poolId];
        User storage user = pool.users[msg.sender];

        // Ensure pool is ERC20 type.
        _onlyERC20Pool(pool);

        // Update pool summations that govern the reward distribution from pool to users.
        _updateRewardSummations(poolId, pool);

        // Pool zero should instead use `compound()`.
        if (poolId == 0) revert InvalidType();

        // Increment lock count on pool zero if this pool was not already locking it.
        _incrementLockOnPoolZero(user);

        // Get the rewards accrued by the user, then delete the user stash.
        reward = _userPendingRewards(poolId, pool, user);
        user.stashedRewards = 0;

        // Ensure there are sufficient rewards to use in compounding.
        if (reward == 0) revert NoEffect();

        // Increment the previousValues to not reset the staking duration. In the proofs,
        // previousValues was regarding combining positions, however we are not combining positions
        // here. Consider this trick as combining with a null position. This allows us to not reset
        // the staking duration but exclude any rewards before block time.
        uint256 userBalance = user.valueVariables.balance;
        user.previousValues += uint152(
            userBalance * (block.timestamp - user.lastUpdate)
        );

        // Snapshot the lastUpdate and summations.
        _snapshotRewardSummations(pool, user);

        // Emit the harvest event, even though it will not be transferred to the user.
        emit Withdrawn(poolId, msg.sender, 0, reward);

        // Get extra rewards from rewarder.
        IRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onReward(poolId, msg.sender, false, reward, userBalance);
        }
    }

    /**
     * @notice Private function to add liquidity to a Arcanum pair when compounding.
     * @param pool The properties of the pool that has the liquidity token to add liquidity to.
     * @param rewardAmount The amount of reward tokens that will be paired up. Requires that the
     *                     reward amount is already set aside for adding liquidity. That means,
     *                     user does not need to send the rewards, and it was set aside through
     *                     harvesting.
     * @param slippage A struct defining the minimum and maximum amounts of tokens that can be
     *                 paired with reward token.
     * @return poolTokenAmount The amount of liquidity tokens that gets minted.
     */
    function _addLiquidity(
        Pool storage pool,
        uint256 rewardAmount,
        Slippage memory slippage
    ) private returns (uint256 poolTokenAmount) {
        address poolToken = pool.tokenOrRecipient;
        address rewardPair = pool.rewardPair;

        // Get token amounts from the pool.
        (uint256 reserve0, uint256 reserve1, ) = IArcanumPair(poolToken)
            .getReserves();

        // Get the reward token’s pair’s amount from the reserves.
        uint256 pairAmount = address(rewardsToken) < rewardPair
            ? (reserve1 * rewardAmount) / reserve0
            : (reserve0 * rewardAmount) / reserve1;

        // Ensure slippage is not above the limit.
        if (pairAmount > slippage.maxPairAmount) revert HighSlippage();
        if (pairAmount < slippage.minPairAmount) revert HighSlippage();

        // Non-zero message value signals desire to pay with native token.
        if (msg.value > 0) {
            // Ensure reward pair is native token.
            if (rewardPair != wrappedNativeToken) revert InvalidToken();

            // Ensure consistent slippage control.
            if (msg.value != slippage.maxPairAmount) revert InvalidAmount();

            // Wrap the native token.
            IWAVAX(rewardPair).deposit{value: pairAmount}();

            // Transfer reward pair tokens from this contract to the pair contract.
            ERC20(rewardPair).safeTransfer(poolToken, pairAmount);

            // Refund user.
            unchecked {
                uint256 refundAmount = msg.value - pairAmount;
                if (refundAmount != 0)
                    SafeTransferLib.safeTransferETH(msg.sender, refundAmount);
            }
        } else {
            // Transfer reward pair tokens from the user to the pair contract.
            ERC20(rewardPair).safeTransferFrom(
                msg.sender,
                poolToken,
                pairAmount
            );
        }

        // Transfer reward tokens from the contract to the pair contract.
        rewardsToken.safeTransfer(poolToken, rewardAmount);

        // Mint liquidity tokens to the ArcanaChef and return the amount minted.
        poolTokenAmount = IArcanumPair(poolToken).mint(address(this));
    }

    /**
     * @notice Private function to exit from a pool by forgoing all rewards.
     * @param poolId The identifier of the pool to exit from.
     * @param withdrawStake An option to forgo stake along with the rewards.
     */
    function _emergencyExit(uint256 poolId, bool withdrawStake) private {
        // Create storage pointers for the pool and the user.
        Pool storage pool = pools[poolId];
        User storage user = pool.users[msg.sender];

        // Ensure pool is ERC20 type.
        _onlyERC20Pool(pool);

        // Decrement lock count on pool zero if this pool was locking it.
        _decrementLockOnPoolZero(poolId, user);

        // Create storage pointers for the value variables.
        ValueVariables storage poolValueVariables = pool.valueVariables;
        ValueVariables storage userValueVariables = user.valueVariables;

        // Decrement the state variables pertaining to total value calculation.
        uint104 balance = userValueVariables.balance;
        if (balance == 0) revert NoEffect();
        unchecked {
            poolValueVariables.balance -= balance;
            poolValueVariables.sumOfEntryTimes -= userValueVariables
                .sumOfEntryTimes;
        }

        // Simply delete the user information.
        delete pools[poolId].users[msg.sender];

        // Transfer stake from contract to user and emit the associated event.
        if (withdrawStake) {
            ERC20(pool.tokenOrRecipient).safeTransfer(msg.sender, balance);
            emit Withdrawn(poolId, msg.sender, balance, 0);
            // Still try withdrawing, but do a non-reverting low-level call.
        } else {
            (bool success, bytes memory returndata) = pool
                .tokenOrRecipient
                .call(
                    abi.encodeWithSelector(
                        ERC20.transfer.selector,
                        msg.sender,
                        balance
                    )
                );
            if (
                success &&
                returndata.length > 0 &&
                abi.decode(returndata, (bool))
            ) {
                emit Withdrawn(poolId, msg.sender, balance, 0);
            }
        }

        {
            // Do a low-level call for rewarder. If external function reverts, only the external
            // contract reverts. To prevent DOS, this function (_emergencyExit) must never revert
            // unless `balance == 0`. This can still return true if rewarder is not a contract.
            (bool success, ) = address(pool.rewarder).call(
                abi.encodeWithSelector(
                    IRewarder.onReward.selector,
                    poolId,
                    msg.sender,
                    true,
                    0,
                    0
                )
            );

            // Record last failed Rewarder calls. This can be used for slashing rewards by a
            // non-malicious Rewarder just in case it reverts due to some bug. If rewarder is
            // correctly written, this statement should never execute. We also do not care if
            // `success` is `true` due to rewarder not being a contract. A non-contract rewarder
            // only means that it is unset. So it does not matter if we record or not.
            if (!success)
                lastTimeRewarderCallFailed[poolId][msg.sender] = block
                    .timestamp;
        }
    }

    /**
     * @notice Private function increment the lock count on pool zero.
     * @param user The properties of a pool’s user that is incrementing the lock. The user
     *             properties of the pool must belong to the caller.
     */
    function _incrementLockOnPoolZero(User storage user) private {
        // Only increment lock if the user is not already locking pool zero.
        if (!user.isLockingPoolZero) {
            // Increment caller’s lock count on pool zero.
            unchecked {
                ++poolZeroLockCount[msg.sender];
            }

            // Mark user of the pool as locking the pool zero.
            user.isLockingPoolZero = true;
        }
    }

    /**
     * @notice Private function ensure pool zero is not locked and decrement the lock count.
     * @param poolId The identifier of the pool which the user properties belong to.
     * @param user The properties of a pool’s user that is decrementing the lock. The user
     *             properties of the pool must belong to the caller.
     */
    function _decrementLockOnPoolZero(uint256 poolId, User storage user)
        private
    {
        if (poolId == 0) {
            // Ensure pool zero is not locked.
            if (poolZeroLockCount[msg.sender] != 0) revert Locked();
        } else if (user.isLockingPoolZero) {
            // Decrement lock count on pool zero if this pool was locking it.
            unchecked {
                --poolZeroLockCount[msg.sender];
            }
            user.isLockingPoolZero = false;
        }
    }

    /**
     * @notice Private function to initialize a pool.
     * @param tokenOrRecipient The address of the token when poolType is ERC_20, or the recipient
     *                         address when poolType is RELAYER_POOL.
     * @param poolType The type of the pool, which determines which actions can be performed on it.
     */
    function _initializePool(address tokenOrRecipient, PoolType poolType)
        private
    {
        // Get the next `poolId` from `_poolsLength`, then increment `_poolsLength`.
        uint256 poolId = _poolsLength++;

        // Ensure address and pool type are not empty.
        if (tokenOrRecipient == address(0) || poolType == PoolType.UNSET_POOL)
            revert NullInput();

        // Ensure token is a contract.
        if (
            poolType == PoolType.ERC20_POOL && tokenOrRecipient.code.length == 0
        ) {
            revert InvalidToken();
        }

        // Assign the function arguments to the pool mapping then emit the associated event.
        Pool storage pool = pools[poolId];
        pool.tokenOrRecipient = tokenOrRecipient;
        pool.poolType = poolType;
        emit PoolInitialized(poolId, tokenOrRecipient);
    }

    /**
     * @notice Private function to ensure the pool token is a Arcanum liquidity token created by
     *         Arcanum Factory, and that the one of the pair tokens is the reward token. Reverts
     *         if not true. If true, it stores the pair of the ARC for future accesses.
     * @return rewardPair The address of the reward pair.
     */
    function _setRewardPair(Pool storage pool)
        private
        returns (address rewardPair)
    {
        // Get the currently stored pair of the reward token.
        rewardPair = pool.rewardPair;

        // Try to initialize the pair of the reward token if it is not already initialized.
        if (rewardPair == address(0)) {
            // Move pool token to memory for efficiency.
            address poolToken = pool.tokenOrRecipient;

            // Get the tokens of the liquidity pool.
            address token0 = IArcanumPair(poolToken).token0();
            address token1 = IArcanumPair(poolToken).token1();

            // Ensure the pool token was created by the pair factory.
            if (factory.getPair(token0, token1) != poolToken)
                revert InvalidToken();

            // Ensure one of the tokens in the pair is the rewards token. Revert otherwise.
            if (token0 == address(rewardsToken)) {
                rewardPair = token1;
            } else if (token1 == address(rewardsToken)) {
                rewardPair = token0;
            } else {
                revert InvalidType();
            }

            // Store the pair of the rewards token in storage.
            pool.rewardPair = rewardPair;
        }
    }

    /**
     * @notice Private view function to ensure pool is of ERC20_POOL type.
     * @param pool The properties of the pool.
     */
    function _onlyERC20Pool(Pool storage pool) private view {
        if (pool.poolType != PoolType.ERC20_POOL) revert InvalidType();
    }

    /**
     * @notice Private view function to ensure pool is of RELAYER_POOL type.
     * @param pool The properties of the pool.
     */
    function _onlyRelayerPool(Pool storage pool) private view {
        if (pool.poolType != PoolType.RELAYER_POOL) revert InvalidType();
    }

    /**
     * @notice Private function to claim the pool’s pending rewards, and based on the claimed
     *         amount update the two variables that govern the reward distribution.
     * @param poolId The identifier of the pool to update the rewards of.
     * @param pool The properties of the pool to update the rewards of.
     * @return The amount of rewards claimed by the pool.
     */
    function _updateRewardSummations(uint256 poolId, Pool storage pool)
        private
        returns (uint256)
    {
        // Get rewards, in the process updating the last update time.
        uint256 rewards = _claim(poolId);

        // Get incrementations based on the reward amount.
        (
            uint256 idealPositionIncrementation,
            uint256 rewardPerValueIncrementation
        ) = _getRewardSummationsIncrementations(pool, rewards);

        // Increment the summations.
        RewardSummations storage rewardSummationsStored = pool
            .rewardSummationsStored;
        rewardSummationsStored.idealPosition += idealPositionIncrementation;
        rewardSummationsStored.rewardPerValue += rewardPerValueIncrementation;

        // Return the pending rewards claimed by the pool.
        return rewards;
    }

    /**
     * @notice Private function to snapshot two rewards variables and record the timestamp.
     * @param pool The storage pointer to the pool to record the snapshot from.
     * @param user The storage pointer to the user to record the snapshot to.
     */
    function _snapshotRewardSummations(Pool storage pool, User storage user)
        private
    {
        user.lastUpdate = uint48(block.timestamp);
        user.rewardSummationsPaid = pool.rewardSummationsStored;
    }

    /**
     * @notice Private view function to get the accrued rewards of a user in a pool.
     * @dev The call to this function must only be made after the summations are updated
     *      through `_updateRewardSummations()`.
     * @param poolId The identifier of the pool.
     * @param pool The properties of the pool.
     * @param user The properties of the user.
     * @return The accrued rewards of the position.
     */
    function _userPendingRewards(
        uint256 poolId,
        Pool storage pool,
        User storage user
    ) private view returns (uint256) {
        // Get the change in summations since the position was last updated. When calculating
        // the delta, do not increment `rewardSummationsStored`, as they had to be updated right
        // before the execution of this function.
        RewardSummations
            memory deltaRewardSummations = _getDeltaRewardSummations(
                poolId,
                pool,
                user,
                false
            );

        // Return the pending rewards of the user.
        return _earned(deltaRewardSummations, user);
    }

    /**
     * @notice Private view function to get the difference between a user’s summations
     *         (‘paid’) and a pool’s summations (‘stored’).
     * @param poolId The identifier of the pool.
     * @param pool The pool to take the basis for stored summations.
     * @param user The user for which to calculate the delta of summations.
     * @param increment Whether to the incremented `rewardSummationsStored` based on the pending
     *                  rewards of the pool.
     * @return The difference between the `rewardSummationsStored` and `rewardSummationsPaid`.
     */
    function _getDeltaRewardSummations(
        uint256 poolId,
        Pool storage pool,
        User storage user,
        bool increment
    ) private view returns (RewardSummations memory) {
        // If user had no update to its summations yet, return zero.
        if (user.lastUpdate == 0) return RewardSummations(0, 0);

        // Create storage pointers to the user’s and pool’s summations.
        RewardSummations storage rewardSummationsPaid = user
            .rewardSummationsPaid;
        RewardSummations storage rewardSummationsStored = pool
            .rewardSummationsStored;

        // If requested, return the incremented `rewardSummationsStored`.
        if (increment) {
            // Get pending rewards of the pool, without updating any state variables.
            uint256 rewards = _poolPendingRewards(
                poolRewardInfos[poolId],
                increment
            );

            // Get incrementations based on the reward amount.
            (
                uint256 idealPositionIncrementation,
                uint256 rewardPerValueIncrementation
            ) = _getRewardSummationsIncrementations(pool, rewards);

            // Increment and return the incremented the summations.
            return
                RewardSummations(
                    rewardSummationsStored.idealPosition +
                        idealPositionIncrementation -
                        rewardSummationsPaid.idealPosition,
                    rewardSummationsStored.rewardPerValue +
                        rewardPerValueIncrementation -
                        rewardSummationsPaid.rewardPerValue
                );
        }

        // Otherwise just return the the delta, ignoring any incrementation from pending rewards.
        return
            RewardSummations(
                rewardSummationsStored.idealPosition -
                    rewardSummationsPaid.idealPosition,
                rewardSummationsStored.rewardPerValue -
                    rewardSummationsPaid.rewardPerValue
            );
    }

    /**
     * @notice Private view function to calculate the `rewardSummationsStored` incrementations based
     *         on the given reward amount.
     * @param pool The pool to get the incrementations for.
     * @param rewards The amount of rewards to use for calculating the incrementation.
     * @return idealPositionIncrementation The incrementation to make to the idealPosition.
     * @return rewardPerValueIncrementation The incrementation to make to the rewardPerValue.
     */
    function _getRewardSummationsIncrementations(
        Pool storage pool,
        uint256 rewards
    )
        private
        view
        returns (
            uint256 idealPositionIncrementation,
            uint256 rewardPerValueIncrementation
        )
    {
        // Calculate the totalValue, then get the incrementations only if value is non-zero.
        uint256 totalValue = _getValue(pool.valueVariables);
        if (totalValue != 0) {
            idealPositionIncrementation =
                (rewards * block.timestamp * PRECISION) /
                totalValue;
            rewardPerValueIncrementation = (rewards * PRECISION) / totalValue;
        }
    }

    /**
     * @notice Private view function to get the user or pool value.
     * @dev Value refers to the sum of each `wei` of tokens’ staking durations. So if there are
     *      10 tokens staked in the contract, and each one of them has been staked for 10 seconds,
     *      then the value is 100 (`10 * 10`). To calculate value we use sumOfEntryTimes, which is
     *      the sum of each `wei` of tokens’ staking-duration-starting timestamp. The formula
     *      below is intuitive and simple to derive. We will leave proving it to the reader.
     * @return The total value of a user or a pool.
     */
    function _getValue(ValueVariables storage valueVariables)
        private
        view
        returns (uint256)
    {
        return
            block.timestamp *
            valueVariables.balance -
            valueVariables.sumOfEntryTimes;
    }

    /**
     * @notice Low-level private view function to get the accrued rewards of a user.
     * @param deltaRewardSummations The difference between the ‘stored’ and ‘paid’ summations.
     * @param user The user of a pool to check the accrued rewards of.
     * @return The accrued rewards of the position.
     */
    function _earned(
        RewardSummations memory deltaRewardSummations,
        User storage user
    ) private view returns (uint256) {
        // Refer to the Combined Position section of the Proofs on why and how this formula works.
        return
            user.lastUpdate == 0
                ? 0
                : user.stashedRewards +
                    ((((deltaRewardSummations.idealPosition -
                        (deltaRewardSummations.rewardPerValue *
                            user.lastUpdate)) * user.valueVariables.balance) +
                        (deltaRewardSummations.rewardPerValue *
                            user.previousValues)) / PRECISION);
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "./GenericErrors.sol";

/**
 * @title ArcanaChef Funding
 * @author Shung for Arcanum
 * @notice A contract that is only the reward funding part of `ArcanaChef`.
 * @dev The pools of the inheriting contract must call `_claim()` to check their rewards since the
 *      last time they made the same call. Then, based on the reward amount, the pool shall
 *      determine the distribution to stakers. It uses the same algorithm as Synthetix’
 *      StakingRewards, but instead of distributing rewards to stakers based on their staked
 *      amount, it distributes rewards to pools based on arbitrary weights.
 */
abstract contract ArcanaChefFunding is AccessControlEnumerable, GenericErrors {
    using SafeTransferLib for ERC20;

    struct PoolRewardInfo {
        // Pool’s weight determines the proportion of the global rewards it will receive.
        uint32 weight;
        // Pool’s previous non-claimed rewards, stashed when its weight changes.
        uint96 stashedRewards;
        // `rewardPerWeightStored` snapshot as `rewardPerWeightPaid` when the pool gets updated.
        uint128 rewardPerWeightPaid;
    }

    /**
     * @notice The mapping from poolId to the struct that stores variables for determining pools’
     * shares of the global rewards.
     */
    mapping(uint256 => PoolRewardInfo) public poolRewardInfos;

    /** @notice The variable representing how much rewards are distributed per weight. It stores in fixed denominator. */
    uint128 public rewardPerWeightStored;

    /** @notice The timestamp when the last time the rewards were claimed by a pool. */
    uint48 public lastUpdate;

    /** @notice The rewards given out per second during a rewarding period. */
    uint80 private _rewardRate;

    /** @notice The timestamp when the current period will end or the latest period has ended. */
    uint48 public periodFinish;

    /** @notice The amount of total rewards added. */
    uint96 public totalRewardAdded;

    /** @notice The sum of all pools’ weights. */
    uint32 public totalWeight;

    /** @notice The duration of how long the rewards will last after `addReward` is called. */
    uint256 public periodDuration = 1 days;

    /** @notice The minimum duration a period can last. */
    uint256 private constant MIN_PERIOD_DURATION = 2**16 + 1;

    /** @notice The maximum duration a period can last. */
    uint256 private constant MAX_PERIOD_DURATION = type(uint32).max;

    /** @notice The fixed denominator used when storing `rewardPerWeight` variables. */
    uint256 private constant WEIGHT_PRECISION = 2**32;

    /** @notice The maximum amount for the sum of all pools’ weights. */
    uint256 private constant MAX_TOTAL_WEIGHT = type(uint32).max;

    /** @notice The maximum amount of rewards that can ever be distributed. */
    uint256 private constant MAX_TOTAL_REWARD = type(uint96).max;

    /** @notice The initial weight of pool zero, hence the initial total weight. */
    uint32 private constant INITIAL_WEIGHT = 1_000;

    /** @notice The privileged role that can call `addReward` function */
    bytes32 private constant FUNDER_ROLE = keccak256("FUNDER_ROLE");

    /** @notice The privileged role that can change pool weights. */
    bytes32 internal constant POOL_MANAGER_ROLE = keccak256("POOL_MANAGER_ROLE");

    /** @notice The reward token that is distributed to stakers. */
    ERC20 public immutable rewardsToken;

    /** @notice The event emitted when a period is manually cut short. */
    event PeriodEnded();

    /** @notice The event emitted when a period is started or extended through funding. */
    event RewardAdded(uint256 reward);

    /** @notice The event emitted when the period duration is changed. */
    event PeriodDurationUpdated(uint256 newDuration);

    /** @notice The event emitted when the weight of a pool changes. */
    event WeightSet(uint256 indexed poolId, uint256 newWeight);

    /**
     * @notice Constructor to create ArcanaChefFunding contract.
     * @param newRewardsToken The token that is distributed as reward.
     * @param newAdmin The initial owner of the contract.
     */
    constructor(address newRewardsToken, address newAdmin) {
        if (newAdmin == address(0)) revert NullInput();

        // Give roles to newAdmin.
        rewardsToken = ERC20(newRewardsToken);
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        _grantRole(FUNDER_ROLE, newAdmin);
        _grantRole(POOL_MANAGER_ROLE, newAdmin);

        // Give 10x (arbitrary scale) weight to pool zero. totalWeight must never be zero.
        poolRewardInfos[0].weight = INITIAL_WEIGHT;
        totalWeight = INITIAL_WEIGHT;
    }

    /**
     * @notice External restricted function to change the reward period duration.
     * @param newDuration The duration the feature periods will last.
     */
    function setPeriodDuration(uint256 newDuration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Ensure there is no ongoing period.
        if (periodFinish > block.timestamp) revert TooEarly();

        // Ensure the new period is within the bounds.
        if (newDuration < MIN_PERIOD_DURATION) revert OutOfBounds();
        if (newDuration > MAX_PERIOD_DURATION) revert OutOfBounds();

        // Assign the new duration to the state variable, and emit the associated event.
        periodDuration = newDuration;
        emit PeriodDurationUpdated(newDuration);
    }

    /** @notice External restricted function to end the period and withdraw leftover rewards. */
    function endPeriod() external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Ensure period has not already ended.
        if (block.timestamp >= periodFinish) revert TooLate();

        unchecked {
            // Get the rewards remaining to be distributed.
            uint256 leftover = (periodFinish - block.timestamp) * _rewardRate;

            // Decrement totalRewardAdded by the amount to be withdrawn.
            totalRewardAdded -= uint96(leftover);

            // Update periodFinish.
            periodFinish = uint48(block.timestamp);

            // Transfer leftover tokens from the contract to the caller.
            rewardsToken.safeTransfer(msg.sender, leftover);
            emit PeriodEnded();
        }
    }

    /**
     * @notice External restricted function to fund the contract.
     * @param amount The amount of reward tokens to add to the contract.
     */
    function addReward(uint256 amount) external onlyRole(FUNDER_ROLE) {
        _updateRewardPerWeightStored();

        // For efficiency, move the periodDuration to memory.
        uint256 tmpPeriodDuration = periodDuration;

        // Ensure amount fits 96 bits.
        if (amount > MAX_TOTAL_REWARD) revert Overflow();

        // Increment totalRewardAdded, reverting on overflow to ensure it fits 96 bits.
        totalRewardAdded += uint96(amount);

        // Update the _rewardRate, ensuring leftover rewards from the ongoing period are included.
        uint256 newRewardRate;
        if (block.timestamp >= periodFinish) {
            assembly {
                newRewardRate := div(amount, tmpPeriodDuration)
            }
        } else {
            unchecked {
                uint256 leftover = (periodFinish - block.timestamp) * _rewardRate;
                assembly {
                    newRewardRate := div(add(amount, leftover), tmpPeriodDuration)
                }
            }
        }

        // Ensure sufficient amount is supplied hence reward rate is non-zero.
        if (newRewardRate == 0) revert NoEffect();

        // Assign the newRewardRate back to storage.
        // MAX_TOTAL_REWARD / MIN_PERIOD_DURATION fits 80 bits.
        _rewardRate = uint80(newRewardRate);

        // Update periodFinish.
        periodFinish = uint48(block.timestamp + tmpPeriodDuration);

        // Transfer reward tokens from the caller to the contract.
        rewardsToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(amount);
    }

    /**
     * @notice External restricted function to change the weights of pools.
     * @dev It requires that pool is created by the parent contract.
     * @param poolIds The identifiers of the pools to change the weights of.
     * @param weights The new weights to set the respective pools to.
     */
    function setWeights(uint256[] calldata poolIds, uint32[] calldata weights)
        external
        onlyRole(POOL_MANAGER_ROLE)
    {
        _updateRewardPerWeightStored();

        // Get the supplied array lengths and ensure they are equal.
        uint256 length = poolIds.length;
        if (length != weights.length) revert MismatchedArrayLengths();

        // Get `poolsLength` to ensure in the loop that pools for a `poolId` exists.
        uint256 tmpPoolsLength = poolsLength();

        // Loop through all the supplied pools, and calculate total weight change.
        int256 weightChange;
        for (uint256 i = 0; i < length; ) {
            uint256 poolId = poolIds[i];
            uint256 weight = weights[i];

            // Ensure pool is initialized by the parent contract.
            if (poolId >= tmpPoolsLength) revert OutOfBounds();

            // Create storage pointer for the pool.
            PoolRewardInfo storage pool = poolRewardInfos[poolId];

            // Ensure weight is changed.
            uint256 oldWeight = pool.weight;
            if (weight == oldWeight) revert NoEffect();

            // Update the weightChange local variable.
            weightChange += (int256(weight) - int256(oldWeight));

            // Stash the rewards of the pool since last update, and update the pool weight.
            pool.stashedRewards = uint96(_updateRewardPerWeightPaid(pool));
            pool.weight = uint32(weight);
            emit WeightSet(poolId, weight);

            // Counter cannot realistically overflow.
            unchecked {
                ++i;
            }
        }

        // Ensure weight change is reasonable, then update the totalWeight state variable.
        int256 newTotalWeight = int256(uint256(totalWeight)) + weightChange;
        if (newTotalWeight <= 0) revert OutOfBounds();
        if (uint256(newTotalWeight) > MAX_TOTAL_WEIGHT) revert OutOfBounds();
        totalWeight = uint32(uint256(newTotalWeight));
    }

    /**
     * @notice External view function to get the reward rate of a pool
     * @param poolId The identifier of the pool to check the reward rate of.
     * @return The rewards per second of the pool.
     */
    function poolRewardRate(uint256 poolId) public view returns (uint256) {
        // Return the rewardRate of the pool.
        uint256 poolWeight = poolRewardInfos[poolId].weight;
        return poolWeight == 0 ? 0 : (rewardRate() * poolWeight) / totalWeight;
    }

    /**
     * @notice Public view function to get the global reward rate.
     * @return The rewards per second distributed to all pools combined.
     */
    function rewardRate() public view returns (uint256) {
        return periodFinish < block.timestamp ? 0 : _rewardRate;
    }

    /**
     * @notice Public view function to return the number of pools created by parent contract.
     * @dev This function must be overridden by the parent contract.
     * @return The number of pools created.
     */
    function poolsLength() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @notice Internal function to get the amount of reward tokens to distribute to a pool since
     *         the last call for the same pool was made to this function.
     * @param poolId The identifier of the pool to claim the rewards of.
     * @return reward The amount of reward tokens that is marked for distributing to the pool.
     */
    function _claim(uint256 poolId) internal returns (uint256 reward) {
        _updateRewardPerWeightStored();
        PoolRewardInfo storage pool = poolRewardInfos[poolId];
        reward = _updateRewardPerWeightPaid(pool);
        pool.stashedRewards = 0;
    }

    /**
     * @notice Internal view function to get the pending rewards of a pool.
     * @param pool The pool to get its pending rewards.
     * @param increment A flag to choose whether use incremented `rewardPerWeightStored` or not.
     * @return rewards The amount of rewards earned by the pool since the last update of the pool.
     */
    function _poolPendingRewards(PoolRewardInfo storage pool, bool increment)
        internal
        view
        returns (uint256 rewards)
    {
        unchecked {
            uint256 rewardPerWeight = increment
                ? rewardPerWeightStored + _getRewardPerWeightIncrementation()
                : rewardPerWeightStored;
            uint256 rewardPerWeightPayable = rewardPerWeight - pool.rewardPerWeightPaid;
            rewards =
                pool.stashedRewards + ((pool.weight * rewardPerWeightPayable) / WEIGHT_PRECISION);
            assert(rewards <= type(uint96).max);
        }
    }

    /**
     * @notice Private function to snapshot the `rewardPerWeightStored` for the pool.
     * @param pool The pool to update its `rewardPerWeightPaid`.
     * @return The amount of reward tokens that is marked for distributing to the pool.
     */
    function _updateRewardPerWeightPaid(PoolRewardInfo storage pool) private returns (uint256) {
        uint256 rewards = _poolPendingRewards(pool, false);
        pool.rewardPerWeightPaid = rewardPerWeightStored;
        return rewards;
    }

    /** @notice Private function to increment the `rewardPerWeightStored`. */
    function _updateRewardPerWeightStored() private {
        rewardPerWeightStored += _getRewardPerWeightIncrementation();
        lastUpdate = uint48(block.timestamp);
    }

    /**
     * @notice Internal view function to get how much to increment `rewardPerWeightStored`.
     * @return incrementation The incrementation amount for the `rewardPerWeightStored`.
     */
    function _getRewardPerWeightIncrementation() private view returns (uint128 incrementation) {
        uint256 globalPendingRewards = _globalPendingRewards();
        uint256 tmpTotalWeight = totalWeight;

        // totalWeight should not be null. But in the case it is, use assembly to return zero.
        assembly {
            incrementation := div(mul(globalPendingRewards, WEIGHT_PRECISION), tmpTotalWeight)
        }
    }

    /**
     * @notice Internal view function to get the amount of accumulated reward tokens since last
     *         update time.
     * @return The amount of reward tokens that has been accumulated since last update time.
     */
    function _globalPendingRewards() private view returns (uint256) {
        // For efficiency, move periodFinish timestamp to memory.
        uint256 tmpPeriodFinish = periodFinish;

        // Get end of the reward distribution period or block timestamp, whichever is less.
        // `lastTimeRewardApplicable` is the ending timestamp of the period we are calculating
        // the total rewards for.
        uint256 lastTimeRewardApplicable = tmpPeriodFinish < block.timestamp
            ? tmpPeriodFinish
            : block.timestamp;

        // For efficiency, stash lastUpdate timestamp in memory. `lastUpdate` is the beginning
        // timestamp of the period we are calculating the total rewards for.
        uint256 tmpLastUpdate = lastUpdate;

        // If the reward period is a positive range, return the rewards by multiplying the duration
        // by reward rate.
        if (lastTimeRewardApplicable > tmpLastUpdate) {
            unchecked {
                return (lastTimeRewardApplicable - tmpLastUpdate) * _rewardRate;
            }
        }

        // If the reward period is an invalid or a null range, return zero.
        return 0;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

/**
 * @title ReentrancyGuard
 * @author Shung for Arcanum
 * @author Modified from Solmate
 *         (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
 */
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    error Reentrancy();

    function _notEntered() internal view {
        if (locked == 2) revert Reentrancy();
    }

    modifier nonReentrant() {
        _notEntered();
        locked = 2;
        _;
        locked = 1;
    }

    modifier notEntered() {
        _notEntered();
        _;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

interface IWAVAX {
    function deposit() external payable;
}

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

interface IArcanumFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

interface IArcanumPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32);

    function mint(address to) external returns (uint256 liquidity);
}

// SPDX-License-Identifier: GPLv3
pragma solidity >=0.6.0;

interface IRewarder {
    function onReward(
        uint256 pid,
        address user,
        bool destructiveAction,
        uint256 rewardAmount,
        uint256 newLpAmount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface GenericErrors {
    error Locked();
    error TooLate();
    error TooEarly();
    error Overflow();
    error NoEffect();
    error NullInput();
    error Underflow();
    error InvalidType();
    error OutOfBounds();
    error InvalidToken();
    error HighSlippage();
    error InvalidAmount();
    error FailedTransfer();
    error NonExistentToken();
    error UnprivilegedCaller();
    error InsufficientBalance();
    error MismatchedArrayLengths();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}