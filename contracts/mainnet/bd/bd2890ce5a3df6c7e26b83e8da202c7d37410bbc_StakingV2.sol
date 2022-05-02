// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MerkleDistributor.sol";
import "./PrivilegedGroupUpgradeable.sol";
import "./AntToken.sol";
import "./Staking.sol";

/**
 * StakingV2
 * Main Staking Contract
 *
 * Implement algorithm for multitokens rewards distribution (inspired by the synthetix staking rewards approach).
 * Adds authorization requirements (amount and period) to the simple staking base with stake and unstake functionalities,
 * stores accounts balances and keeps track of stake total supply and corresponding registred values.
 */
// solhint-disable-next-line max-states-count
contract StakingV2 is PrivilegedGroupUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== DATA STRUCTURES ========== */

    // Struct used to store specific token distribution informations
    struct RewardsTokenData {
        uint256 periodFinish; // Timestamp when the distribution ends
        uint256 rewardRate; // Total tokens per second distribution rate (1e36 mantissa)
        uint256 rewardsDuration; // Reward distribution duration
        uint256 lastUpdateTime; // Timestamp of the last rewards update
        uint256 rewardPerTokenStored; // Reward for token

        // already claimed rewards
        mapping(address => uint256) accountRewardPerTokenPaid;
        // accounts rewards
        mapping(address => uint256) rewards;
    }

    // Struct used to store stake timestamp and current contract state
    // (authorizedStakeAmountRequirement and authorizedStakePeriodRequirement)
    struct StakeConditions {
       uint256 timestamp;
       uint256 authAmount;
       uint256 authPeriod;
    }

    // Struct used for holding migration data from Staking V1
    struct MigrationFromV1Data {
       bool migrationRegistered;
       uint256 remainingAuthPeriod;
       uint256 registrationTimestamp;
    }

    /* ========== STATE VARIABLES ========== */

     // Token used to stake, should be provided in the constructor.
    IERC20Upgradeable public stakeToken;

    // Provided with constructor, cannot be changed
    AntToken public antToken;

    // Stores accounts stake balances
    mapping(address => uint256) private stakeBalance;

    // Total accounts stakes kept under this contract
    uint256 public totalStake;

    // fees in mantissa format (1e18)
    uint256 public stakeFeeMantissa;
    uint256 public unstakeFeeMantissa;

    uint256 public feesRedistributionPeriod;

    /* ------ Rewards ------ */

    // Data about airdrop rewards for each token address
    mapping(address => RewardsTokenData) public rewardTokensData;

    // List of current enabled reward tokens
    address[] public rewardTokensList;

    /* ------ Authorization ------ */

    // Initialize account StakeConditions at the time of first stake
    mapping(address => StakeConditions) public initialStakeConditions;

    // Stores authorized and registered stake balances
    mapping(address => bool) public registered;

    // Total authorized stake of registered accounts
    uint256 public totalRegisteredStake;

    // Amount of stake required for the account to be authorized
    uint256 public authorizedStakeAmountRequirement;

    // The period of stake in seconds required for the account to be authorized
    uint256 public authorizedStakePeriodRequirement;

    /* ------ Migrations ------ */

    // Address of the contract privileged to move deposit and its longevity
    address public migrator;
    MerkleDistributor private bonusMerkleDistributor;

    // migrations from V1
    mapping(address => MigrationFromV1Data) public migrationsFromV1Data;
    mapping(address => bool ) public migratedFromV1;

    // Staking V1 contract
    Staking public stakingV1Contract;

    /* ========== EVENTS ========== */

    event StakeFeeSet(uint256 oldStakeFee, uint256 newStakeFee);
    event UnstakeFeeSet(uint256 oldUnstakeFee, uint256 newUnstakeFee);
    event FeesRedistributionPeriodSet(uint256 oldPeriod, uint256 newPeriod);

    event StakeFeeCollected(address indexed staker, uint256 value);
    event UnstakeFeeCollected(address indexed staker, uint256 value);

    /* ------ Rewarding ------ */

    event RewardAdded(address indexed token, uint256 amount);
    event RewardClaimed(address indexed token, address indexed staker, address indexed receiver, uint256 amount);
    event RewardsDurationUpdated(uint256 newDuration);
    event RewardRemoved(address indexed token, uint256 amount);

    /* ------ Authorization ------ */

    event Registered(address indexed account);
    event Unregistered(address indexed account);

    event AuthorizedStakeAmountRequirementChanged(uint256 newStakeValue);
    event AuthorizedStakePeriodRequirementChanged(uint256 newPeriod);

    /* ------ Migrations ------ */

    event MigrationFromV1Registered(address indexed account, uint256 reaminingAuthTime);
    event MigrationFromV1Completed(address indexed account, uint256 stake, uint256 remainingAuthTime);

    event MigratorSet(address migrator);
    event StakingV1Set(address stakingV1);
    event MigrationToV3Completed(address migrator, address indexed staker, uint256 amount);
    event StakingContractV1Set(Staking oldAddress, Staking newAddress);
    event BonusMerkleDistributorSet(address bonusMerkleDistributor);

    /* ------ Staking ------ */

    event StakeAdded(address indexed supplier, address indexed receiver, uint256 value);
    event StakeRemoved(address indexed staker, address indexed receiver, uint256 value);
    event StakeMoved(address indexed from, address indexed to, uint256 value);

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor/Initializer
     * @param stakeToken_ The address of stake token contract
     * @param authorizedStakeAmountRequirement_ Minimum stake amount in wei
     * @param authorizedStakePeriodRequirement_ Period in seconds needed to become authorized
     * @param feesRedistributionPeriod_ Period used to redistribute reward from fees
     */
    function initialize (
        address stakeToken_,
        address antTokenAddress_,
        uint256 authorizedStakeAmountRequirement_,
        uint256 authorizedStakePeriodRequirement_,
        uint256 feesRedistributionPeriod_
    ) public initializer {
        require(stakeToken_ != address(0), "stakeToken cannot be 0x0");
        require(antTokenAddress_ != address(0), "got 0x0 address");
        __PrivilegedGroupUpgradeable_init(); // also ownable
        __ReentrancyGuard_init();
        __Pausable_init();

        stakeToken = IERC20Upgradeable(stakeToken_);
        antToken = AntToken(antTokenAddress_);

        authorizedStakeAmountRequirement = authorizedStakeAmountRequirement_;
        authorizedStakePeriodRequirement = authorizedStakePeriodRequirement_;

        feesRedistributionPeriod = feesRedistributionPeriod_;
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Calculates fee for given stake amount
     */
    function calculateStakeFee(uint256 amount) public view returns(uint256) {
        return _calculateFee(stakeFeeMantissa, amount);
    }

    /**
     * @dev Calculates fee for given unstake amount
     */
    function calculateUnstakeFee(uint256 amount) public view returns(uint256) {
        return _calculateFee(unstakeFeeMantissa, amount);
    }

    /**
     * @dev Public function which gets account stake balance
     * @return Stake balance for given account
     */
    function stakeBalanceOf(address account) public view returns (uint256) {
        return stakeBalance[account];
    }

    /* ------ Rewards ------ */

    /**
     * @notice Returns a list of current distributed tokens
     */
    function getRewardTokensList() external view returns (address[] memory) {
        return rewardTokensList;
    }

    /**
     * @notice Helper to get the account reward for the given token
     */
    function accountReward(address account, address token) external view returns (uint256) {
        return rewardTokensData[token].rewards[account];
    }

    /**
     * @notice Helper to get the account reward paid for the given token
     */
    function accountRewardPerTokenPaid(address account, address token) external view returns (uint256) {
        return rewardTokensData[token].accountRewardPerTokenPaid[account];
    }

    /**
     * @notice Returns total reward amount for current or previous token distribution
     */
    function getRewardForDuration(address token) external view returns (uint256) {
        return rewardTokensData[token].rewardRate * rewardTokensData[token].rewardsDuration / 1e18;
    }

    /**
     * @notice Returns current timestamp within token distribution or distribution end date
     */
    function lastTimeRewardApplicable(address token) public view returns (uint256) {
        uint256 periodFinish = rewardTokensData[token].periodFinish;

        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
     * @notice Returns current amount of reward tokens per staked/registered token
     */
    function rewardPerToken(address token) public view returns (uint256) {
        RewardsTokenData storage tokenData = rewardTokensData[token];

        if (totalRegisteredStake == 0) {
            return tokenData.rewardPerTokenStored;
        }
        return
            tokenData.rewardPerTokenStored + (
                (
                    (lastTimeRewardApplicable(token) - tokenData.lastUpdateTime)
                    * tokenData.rewardRate
                ) / totalRegisteredStake
            );
    }

    /**
     * @notice Returns earned and available to claim by account tokens
     * @dev After withdrawal, earned value goes back to 0
     */
    function earned(address account, address token) public view returns (uint256) {
        RewardsTokenData storage tokenData = rewardTokensData[token];

        return
            registeredStakeBalanceOf(account) * (
                rewardPerToken(token) - tokenData.accountRewardPerTokenPaid[account]
            ) / 1e18
            + tokenData.rewards[account];
    }

    /**
     * @notice Simulate reward rate for given token
     * @dev Helper calculations shared by notifyRewardAmount and notifyStakeRewardAmount
     */
    function calculateNotifyRewardRate(
        address token,
        uint256 reward,
        uint256 rewardsDuration
    ) public view returns(uint256) {
        if (block.timestamp >= rewardTokensData[token].periodFinish) {
            return reward * 1e18 / rewardsDuration;
        }

        // ongoing reward distribution
        uint256 remaining = rewardTokensData[token].periodFinish - block.timestamp;
        uint256 leftover = remaining * rewardTokensData[token].rewardRate / 1e18;
        return (reward + leftover) * 1e18 / rewardsDuration;
    }

    /* ------ Authorization ------ */

    /**
     * @notice Public function which gets account registered stake balance
     * @dev 0 for unregistered accounts
     * @return Registered stake balance for given account
     */
    function registeredStakeBalanceOf(address account) public view returns (uint256) {
        if (isAccountRegistered(account)) {
            return stakeBalanceOf(account);
        }
        return 0;
    }

    /**
     * @notice Gets account specific authorized stake amount
     * @dev More favorable amount among the present or the time when the first stake was made
     * @return uint256 authorizedStakeAmountRequirement
     */
    function accountAuthorizedAmountRequirement(address account) public view returns (uint256) {
        // check if initialStakeConditions were set
        if (initialStakeConditions[account].timestamp != 0) {
            return initialStakeConditions[account].authAmount;
        }
        return authorizedStakeAmountRequirement;
    }

    /**
     * @notice Gets account specific authorized stake period
     * @dev More favorable period among the present or the time when the first stake was made
     * @return uint256 authorizedStakePeriodRequirement
     */
    function accountAuthorizedPeriodRequirement(address account) public view returns (uint256) {
        // check if initialStakeConditions were set
        if (initialStakeConditions[account].timestamp != 0) {
            return initialStakeConditions[account].authPeriod;
        }
        return authorizedStakePeriodRequirement;
    }

    /**
     * @notice Checks if the account pass authorized stake amount and period conditions and is authorized
     * @dev Stake amount in fact does not have to be checked becouse of the minimum stake that can be done
     * @return boolean
     */
    function isAccountAuthorized(address account) public view returns (bool) {
        // check if stake conditions were initialized first
        if (initialStakeConditions[account].timestamp == 0) {
            return false;
        }

        uint256 maxTimestamp = block.timestamp - accountAuthorizedPeriodRequirement(account);
        return maxTimestamp >= initialStakeConditions[account].timestamp;
    }

    /**
     * @notice check if the account is registered
     * @return boolean
     */
    function isAccountRegistered(address account) public view returns (bool) {
        return registered[account];
    }

    /**
     * @notice Calculates the time in seconds which must elapse for the account
               to be authorized (to meet authorizedStakePeriodRequirement)
     * @return boolean Will the account be authorized? false means that the account
     *                 will not be authorized because of insufficient stake
     * @return uint256 Estimated time in seconds
     */
    function timeRemainingAuthorization(address account) public view returns (bool, uint256) {
        uint256 initialTimestamp = initialStakeConditions[account].timestamp;

        if (initialTimestamp == 0) {
            return (false, 0);
        }

        // solhint-disable-next-line not-rely-on-time
        uint256 maxTimestamp = block.timestamp - accountAuthorizedPeriodRequirement(account);
        if (maxTimestamp >= initialTimestamp) {
            return (true, 0);
        }

        return (true, initialTimestamp - maxTimestamp);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Use implementation from AuthorizedStaking, add modifiers
     */
    function stake(uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateRewards(msg.sender)
    {
        _stakeForWithFees(msg.sender, msg.sender, amount);
    }

    /**
     * @dev Use implementation from AuthorizedStaking, add modifiers
     */
    function stakeFor(address receiver, uint256 amount)
        public
        nonReentrant
        whenNotPaused
        updateRewards(receiver)
    {
        _stakeForWithFees(msg.sender, receiver, amount);
    }

    /**
     * @notice Unstakes given amount
     * @dev Use implementation from AuthorizedStaking, add modifiers
     */
    function unstake(uint256 amount)
        public
        nonReentrant
        updateRewards(msg.sender)
    {
        require(antToken.balanceOf(msg.sender) >= amount, "Not enough ANT");
        _unstakeForWithFees(msg.sender, msg.sender, amount);
    }

    /**
     * @notice Unstakes all tokens
     * @dev Use implementation from AuthorizedStaking, add modifiers
     */
    function unstakeAll()
        public
        nonReentrant
        updateRewards(msg.sender)
    {
        require(antToken.balanceOf(msg.sender) >= stakeBalanceOf(msg.sender), "Not enough ANT");
        _unstakeForWithFees(msg.sender, msg.sender, stakeBalanceOf(msg.sender));
    }

    /**
     * @notice Make account registered
     *
     * Emits a {Registered} event
     */
    function register()
        external
        nonReentrant
        whenNotPaused
        updateRewards(msg.sender)
    {
        _registerAccount(msg.sender);
    }

    /* ------ Rewarding ------ */

    /**
     * @notice Claim reward for given token
     * @dev With nonReentrant
     */
    function getReward(address token, address claimer) external nonReentrant returns(uint256) {
        return _getReward(token, claimer, claimer);
    }

    /**
     * @notice Claim reward for all tokens
     * @dev With nonReentrant
     */
    function getAllRewards(address claimer) public nonReentrant {
        for (uint i = 0; i < rewardTokensList.length; i++) {
            _getReward(rewardTokensList[i], claimer, claimer);
        }
    }

    /**
     * @notice Uses stake token reward to increase account stake
     * @dev _getReward updates token reward
     */
    function compoundStakeToken()
        external
        nonReentrant
        whenNotPaused
    {
        // transfer tokens twice from this contract to this, the same contract..
        // it could be optimized, but at the cost of increasing code complexity
        uint256 reward = _getReward(address(stakeToken), msg.sender, address(this));

        require(reward != 0, "cannot compound zero reward");

        IERC20Upgradeable(address(stakeToken)).safeApprove(address(this), reward);
        _stakeForWithFees(address(this), msg.sender, reward);
    }

    /**
     * @notice Unstake all stake tokens and claim all rewards
     * @dev Without nonReentrant
     */
    function exit() external {
        unstakeAll();
        getAllRewards(msg.sender);
    }

    /* ------ Migrations ------ */

    /**
     * @notice Checks if the migration from V1 is allowed and registers user for it.
     * @dev Now ustake on V1 should be made and migrateFromV1() executed
     */
    function registerMigrationFromV1() external migrationV1Requirements {
        MigrationFromV1Data storage userMigrationData = migrationsFromV1Data[msg.sender];

        userMigrationData.migrationRegistered = true;
        userMigrationData.registrationTimestamp = block.timestamp;
        if (stakingV1Contract.isAccountAuthorized(msg.sender)){
            userMigrationData.remainingAuthPeriod = 0;
        } else {
            (bool canBeAuthorized, uint256 timeToBeAuthorized) = stakingV1Contract.timeRemainingAuthorization(msg.sender);
            // disallow if stake is not sufficient
            require(canBeAuthorized, "Insufficient stake in V1");
            userMigrationData.remainingAuthPeriod = timeToBeAuthorized;
        }

        emit MigrationFromV1Registered(msg.sender, userMigrationData.remainingAuthPeriod);
    }

    /**
     * @notice Performs a migration of authorization from V1 staking.
     * @dev Requires approval for transferFrom of tokens (stakeInternal)
     *
     * Emits a {MigrationFromV1Completed} event
     */
    function migrateFromV1(uint256 amount, uint256 bonusAmount, bytes32[] calldata merkleProof)
        external
        nonReentrant
        whenNotPaused
        updateRewards(msg.sender)
        migrationV1Requirements
    {
        MigrationFromV1Data storage userMigrationData = migrationsFromV1Data[msg.sender];

        require(userMigrationData.migrationRegistered, "Not registered for migration");
        require(block.timestamp - userMigrationData.registrationTimestamp < 1 days, "Registration expired");
        require(amount >= authorizedStakeAmountRequirement, "Not enough stake");

        // write values to V2 storage
        migratedFromV1[msg.sender] = true;
        _saveInitialConditions(msg.sender);

        // adjust stake timestamp, actual authorization
        initialStakeConditions[msg.sender].timestamp =  block.timestamp - (authorizedStakePeriodRequirement - userMigrationData.remainingAuthPeriod);

        _stakeForRaw(msg.sender, msg.sender, amount);
        antToken.mint(msg.sender, amount);

        // register account if possible
        if (isAccountAuthorized(msg.sender)) {
            _registerAccount(msg.sender);
        }

        if(bonusAmount > 0){
            bonusMerkleDistributor.claim(msg.sender, bonusAmount, merkleProof);
        }

        emit MigrationFromV1Completed(msg.sender, amount, userMigrationData.remainingAuthPeriod);
    }

    /**
     * @notice Can be called only by migrator
     * @dev Migrates staker to new version of staking contract defined as "migrator".
     * @param staker Address of user to migrate
     *
     * Emits a {MigrationToV3Completed} event
     */
    function migrateToV3(address staker)
        external
        nonReentrant
        whenNotPaused
        updateRewards(staker)
        returns (StakeConditions memory stakeData)
    {
        uint256 stakerBalanceOf = stakeBalanceOf(staker);
        require(msg.sender == migrator, "caller is not the migrator");
        require(stakerBalanceOf > 0, "no stake to migrate");

        stakeData = initialStakeConditions[staker];
        _unregisterAccount(staker);

        _unstakeForRaw(staker, migrator, stakerBalanceOf);
        antToken.burn(staker, stakerBalanceOf);

        emit MigrationToV3Completed(migrator, staker, stakerBalanceOf);
        return stakeData;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Internal function for staking. Also mints appropriate number of ANT tokens and distributes fee
     */
    function _stakeForWithFees(address supplier, address receiver, uint256 amount) internal {
        uint256 feeAmount = calculateStakeFee(amount);
        uint256 remainingStake = amount - feeAmount;

        if(feeAmount > 0){
            _notifyRewardAmount(supplier, address(stakeToken), feeAmount, feesRedistributionPeriod);
            emit StakeFeeCollected(supplier, feeAmount);
        }
        _stakeFor(supplier, receiver, remainingStake);
    }

    /**
     * @notice Internal function for unstaking. Also burns appropriate number of ANT tokens and distributes fee
     */
    function _unstakeForWithFees(address staker, address receiver, uint256 amount) internal {
        uint256 feeAmount = calculateUnstakeFee(amount);

        _unstakeFor(staker, address(this), amount);
        stakeToken.safeTransfer(receiver, amount - feeAmount);

        if(feeAmount > 0){
            IERC20Upgradeable(address(stakeToken)).safeApprove(address(this), feeAmount);
            _notifyRewardAmount(address(this), address(stakeToken), feeAmount, feesRedistributionPeriod);
            emit UnstakeFeeCollected(staker, feeAmount);
        }
    }

    /**
     * @notice Main function for staking tokens
     * @dev Runs StakingDeposit stakeFor with additional auth instructions
     */
    function _stakeFor(address supplier, address receiver, uint256 amount) internal {
        require(
            stakeBalanceOf(receiver) + amount >= accountAuthorizedAmountRequirement(receiver),
            "not enough for authorization"
        );

        // save conditions before actual stake,
        // expect: stakeBalance[account] == 0
        _saveInitialConditions(receiver);

        _stakeForRaw(supplier, receiver, amount);

        _increaseTotalRegisteredTokens(receiver, amount);

        antToken.mint(receiver, amount);
    }

    /**
     * @notice Allows to unstake tokens with the restriction that the staker remains authorized
               or unstake all tokens and breaks staker authorization
     * @dev Unregisters in case of breaking authorization
     */
    function _unstakeFor(address staker, address receiver, uint256 amount)
        internal
    {
        // unstake all
        if (amount == stakeBalanceOf(staker)) {
            _unregisterAccount(staker);
        } else {
            // unstake partial
            require(
                stakeBalanceOf(staker) >= amount + accountAuthorizedAmountRequirement(staker),
                "amount breaks authorization"
            );

            _decreaseTotalRegisteredTokens(staker, amount);
        }

        // unstake for staker only remaining tokens
        _unstakeForRaw(staker, receiver, amount);

        antToken.burn(staker, amount);
    }

    /**
     * @notice Restakes tokens with the authorization limitations
     * @dev This function allows to change any stake balance, should be used only by already
     *      deployed and safe contract with known logic.
     *      Updates both 'from' and 'to' rewards. Covers stake and both restake partial and restake all
     */
    function _restake(address from, address to, uint256 amount) internal {
        if (from == to) {
            // nothing to do
            return;
        }

        // stake conditions for accounts could be different
        require(
            stakeBalanceOf(to) + amount >= accountAuthorizedAmountRequirement(to),
            "not enough for authorization"
        );

        // restake all
        if (amount == stakeBalanceOf(from)) {
            _unregisterAccount(from);
        } else {
            // restake partial
            require(
                stakeBalanceOf(from) >= amount + accountAuthorizedAmountRequirement(from),
                "amount breaks authorization"
            );

            _decreaseTotalRegisteredTokens(from, amount);
        }

        // save conditions before actual stake,
        // expect: stakeBalance[account] == 0
        _saveInitialConditions(to);

        _restakeRaw(from, to, amount);

        _increaseTotalRegisteredTokens(to, amount);
    }

    /**
     * @notice Internal function that calculates fee amount
     * @return uint256 the calculated fee amount
     */
    function _calculateFee(uint256 fee, uint256 amount) internal pure returns(uint256) {
        uint256 feeAmount;

        if (fee == 0) {
            return 0;
        }

        feeAmount = amount * fee / 1e18;
        return feeAmount;
    }

    /* ------ Rewarding ------ */

    /**
     * @notice Sends token reward to the account
     * @dev Internal function without nonReentrant
     * @param token Reward tokens
     * @param receiver Account which will receive revards tokens
     *
     * Emits a {RewardClaimed} event
     */
    function _getReward(address token, address claimer, address receiver)
        internal
        updateTokenReward(token, claimer)
        returns(uint256)
    {
        RewardsTokenData storage tokenData = rewardTokensData[token];

        uint256 reward = tokenData.rewards[claimer];
        if (reward > 0) {
            tokenData.rewards[claimer] = 0;
            IERC20Upgradeable(token).safeTransfer(receiver, reward);
            emit RewardClaimed(token, claimer, receiver, reward);
        }
        return reward;
    }

    /**
     * @dev Internal common function for updating specified token reward
     */
    function _updateTokenReward(address token, address account) internal {
        RewardsTokenData storage tokenData = rewardTokensData[token];

        tokenData.rewardPerTokenStored = rewardPerToken(token);
        tokenData.lastUpdateTime = lastTimeRewardApplicable(token);
        if (account != address(0)) {
            tokenData.rewards[account] = earned(account, token);
            tokenData.accountRewardPerTokenPaid[account] = tokenData.rewardPerTokenStored;
        }
    }

    /**
     * @dev Internal function used for both notifying stake and external tokens rewards
     * @param rewardRate Calculated rate of tokens distribution
     */
    function _notifyRewardRate(address token, uint256 rewardRate, uint256 rewardsDuration)
        internal
        updateTokenReward(token, address(0))
    {
        RewardsTokenData storage tokenData = rewardTokensData[token];

        // add token to list if first notify
        if (tokenData.periodFinish == 0) {
            rewardTokensList.push(token);
        }

        tokenData.rewardRate = rewardRate;
        tokenData.rewardsDuration = rewardsDuration;

        tokenData.lastUpdateTime = block.timestamp;
        tokenData.periodFinish = block.timestamp + rewardsDuration;
    }

    /**
     * @dev internal notifyRewardAmount, same but without onlyPrivileged
     */
    function _notifyRewardAmount(address from, address token, uint256 reward, uint256 rewardsDuration)
        internal
    {
        uint256 rewardRate = calculateNotifyRewardRate(token, reward, rewardsDuration);

        // transfer exac amount 'from' address to this contract
        IERC20Upgradeable(token).safeTransferFrom(from, address(this), reward);

        _notifyRewardRate(token, rewardRate, rewardsDuration);
        emit RewardAdded(token, reward);
    }

    /* ------ Authorization ------ */

    /**
     * @notice Internal make account stake registered
     * @dev Allows to count account stake to the totalRegisteredSupply and get rewards
     *
     * Emits a {Registered} event
     */
    function _registerAccount(address account) internal {
        require(isAccountAuthorized(account), "account is not authorized");
        require(!isAccountRegistered(account), "account already registered");

        registered[account] = true;
        totalRegisteredStake += stakeBalanceOf(account);

        emit Registered(account);
    }

    /**
     * @notice Makes account unregistered and decreases registered tokens
     * @dev Also deletes account initialStakeConditions
     *
     * Emits a {Unregistered} event for authorized accounts
     */
    function _unregisterAccount(address account) internal {
        delete initialStakeConditions[account];

        if (isAccountRegistered(account)) {
            // decrease registered tokens by account's stake
            totalRegisteredStake -= stakeBalanceOf(account);

            registered[account] = false;
            emit Unregistered(account);
        }
    }

    /**
     * @notice Save account initial stake conditions, only for the first stake
     * @dev Only if account's deposit is empty (first stake or after unstakeAll)
     */
    function _saveInitialConditions(address account) internal {
        // save stake timestamp and initial conditions for the first stake
        if (stakeBalanceOf(account) == 0) {
            initialStakeConditions[account] = StakeConditions({
                timestamp: block.timestamp,
                authAmount: authorizedStakeAmountRequirement,
                authPeriod: authorizedStakePeriodRequirement
            });
        }
    }

    /**
     * @dev Increase registered tokens only for registered accounts
     */
    function _increaseTotalRegisteredTokens(address account, uint256 amount) internal {
        if (isAccountRegistered(account)) {
            totalRegisteredStake += amount;
        }
    }

    /**
     * @dev Decrease registered tokens only for registered accounts
     */
    function _decreaseTotalRegisteredTokens(address account, uint256 amount) internal {
        if (isAccountRegistered(account)) {
            totalRegisteredStake -= amount;
        }
    }

    /* ------ Staking Base ------ */

    /**
     * @notice Internal function for staking tokens
     * @dev Stake tokens from supplier for receiver address
     *
     * Emits a {StakeAdded} event
     */
    function _stakeForRaw(address supplier, address receiver, uint256 amount) internal {
        require(amount > 0, "cannot stake 0");

        // tokens transfer to this contract (require approve)
        stakeToken.safeTransferFrom(supplier, address(this), amount);
        stakeBalance[receiver] += amount;
        totalStake += amount;

        emit StakeAdded(supplier, receiver, amount);
    }

    /**
     * @notice Sends staked tokens back to the sender
     *
     * Emits a {StakeRemoved} event
     */
    function _unstakeForRaw(address staker, address receiver, uint256 amount) internal {
        require(amount > 0, "cannot unstake 0");

        stakeBalance[staker] -= amount;
        totalStake -= amount;

        stakeToken.safeTransfer(receiver, amount);

        emit StakeRemoved(staker, receiver, amount);
    }

    /**
     * @notice Restake tokens 'inplace' from one account to another
     * @dev Internal function, does not send any tokens
     *
     * Emits a {StakeMoved} event
     */
    function _restakeRaw(address from, address to, uint256 amount) internal {
        require(amount > 0, "cannot restake 0");

        stakeBalance[from] -= amount;
        stakeBalance[to] += amount;

        emit StakeMoved(from, to, amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Unstake account stake by ant token contract, used for later tokens distribution
     */
    function unstakeForDistributon(address account, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        updateRewards(account)
        onlyAntToken
    {
        _unstakeFor(account, address(antToken), amount);
    }

    /**
     * @dev Uses internal authorized restake function
     */
    function changeStakeOwnership(address from, address to, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        updateRewards(from)
        updateRewards(to)
        onlyAntToken
    {
        _restake(from, to, amount);
    }

    /**
     * @notice sets the staking fee. Has to be smaller than 100% = 1e18
     */
    function setStakeFeeMantissa(uint256 newFee) external onlyOwner {
        require(newFee < 1e18, "Wrong fee");
        uint256 oldFee = stakeFeeMantissa;
        stakeFeeMantissa = newFee;
        emit StakeFeeSet(oldFee, stakeFeeMantissa);
    }

    /**
     * @notice sets the unstaking fee. Has to be smaller than 100% = 1e18
     */
    function setUnstakeFeeMantissa(uint256 newFee) external onlyOwner {
        require(newFee < 1e18, "Wrong fee");
        uint256 oldFee = unstakeFeeMantissa;
        unstakeFeeMantissa = newFee;
        emit UnstakeFeeSet(oldFee, unstakeFeeMantissa);
    }

    /**
     * @param newPeriod In seconds
     */
    function setFeesRedistributionPeriod(uint256 newPeriod) external onlyOwner {
        uint256 oldPeriod = feesRedistributionPeriod;
        feesRedistributionPeriod = newPeriod;
        emit FeesRedistributionPeriodSet(oldPeriod, feesRedistributionPeriod);
    }

    /**
     * @notice Pauses stake functionalities
     */
    function pauseStaking() external onlyOwner whenNotPaused {
        super._pause();
    }

    /**
     * @notice Resumes stake functionalities
     */
    function unpauseStaking() external onlyOwner whenPaused {
        super._unpause();
    }

    /* ------ Rewards ------ */

    /**
     * @notice Notify about new or update previous token distribution
     * @dev Reward tokens should be already transfered to this contract
     * @param token Address of reward token
     * @param reward Amount of tokens
     * @param rewardsDuration Duration of distribution in seconds
     *
     * // synthetix comment:
     * // Ensure the provided reward amount is not more than the balance in the contract.
     * // This keeps the reward rate in the right range, preventing overflows due to
     * // very high values of rewardRate in the earned and rewardsPerToken functions;
     * // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
     *
     * Emits a {RewardAdded} event
     */
    function notifyRewardAmount(address from, address token, uint256 reward, uint256 rewardsDuration)
        external
        onlyPrivileged
    {
        _notifyRewardAmount(from, token, reward, rewardsDuration);
    }

    /**
     * @notice Function which allows the owner to recover and remove reward tokens
     * @dev Function can be also used to protect from malicious privileged distributor and clean up rewardTokensList
     *
     * Emits a {RewardRemoved} event
     */
    function removeReward(address receiver, address token) external onlyOwner {
        // balance in the contract
        uint256 amount = IERC20Upgradeable(token).balanceOf(address(this));

        // don't remove tokens coresponding to accounts stake
        if (token == address(stakeToken)) {
            amount -= totalStake;
        }

        // remove token from reward tokens list if present
        for (uint i = 0; i < rewardTokensList.length; i++) {
            if (rewardTokensList[i] == token) {
                // remove without preserving order
                rewardTokensList[i] = rewardTokensList[rewardTokensList.length - 1];
                rewardTokensList.pop();
            }
        }

        // delete tokens data
        delete rewardTokensData[token];

        IERC20Upgradeable(token).safeTransfer(receiver, amount);
        emit RewardRemoved(token, amount);
    }

    /* ------ Authorization ------ */

    /**
     * @notice Allows to set new authorizedStakeAmountRequirement value
     * @param amount New authorized stake amount
     *
     * Emits a {AuthorizedStakeAmountRequirementChanged} event
     */
    function setAuthorizedStakeAmountRequirement(uint256 amount) external onlyOwner {
        authorizedStakeAmountRequirement = amount;
        emit AuthorizedStakeAmountRequirementChanged(amount);
    }

    /**
     * @notice Allows to set new authorizedStakePeriodRequirement value
     * @param period New authorized period in seconds
     *
     * Emits a {AuthorizedStakePeriodRequirementChanged} event
     */
    function setAuthorizedStakePeriodRequirement(uint256 period) external onlyOwner {
        authorizedStakePeriodRequirement = period;
        emit AuthorizedStakePeriodRequirementChanged(period);
    }

    /* ------ Migrations ------ */

    /**
     * @notice Allows to set new migrator address
     * @dev Could be set only once
     * @param newMigrator Address of the migrator
     *
     * Emits a {MigratorSet} event
     */
    function setMigrator(address newMigrator) external onlyOwner {
        require(migrator == address(0), "migrator already set");
        migrator = newMigrator;
        emit MigratorSet(newMigrator);
    }

    /**
     * @notice Set a legacy staking contract address for migration purpose
     * @dev Could be set only once
     * @param newStakingV1Contract Address of the staking v1 contract
     *
     * Emits a {StakingV1Set} event
     */
    function setStakingV1Contract(Staking newStakingV1Contract) external onlyOwner{
        require(address(stakingV1Contract) == address(0), "staking v1 already set");
        stakingV1Contract = newStakingV1Contract;
        emit StakingV1Set(address(newStakingV1Contract));
    }

    function setBonusMerkleDistributor(MerkleDistributor newBonusMerkleDistributor) external onlyOwner{
        bonusMerkleDistributor = newBonusMerkleDistributor;
        emit BonusMerkleDistributorSet(address(newBonusMerkleDistributor));
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Requires signer to be AntToken contract
     */
    modifier onlyAntToken() {
        require(msg.sender == address(antToken), "Caller is not AntToken");
        _;
    }

    /**
     * @notice Updates reward for one token
     */
    modifier updateTokenReward(address token, address account) {
        _updateTokenReward(token, account);
        _;
    }

    /**
     * @notice Updates reward for all tokens in the rewardTokensList
     * @dev Used for stake and unstake, and can be gas consuming
     */
    modifier updateRewards(address account) {
        for (uint i = 0; i < rewardTokensList.length; i++) {
            _updateTokenReward(rewardTokensList[i], account);
        }
        _;
    }

    modifier migrationV1Requirements() {
        require(address(stakingV1Contract) != address(0), "Legacy contract missing");
        require(!migratedFromV1[msg.sender], "Already migrated");
        require(stakingV1Contract.authorizedStakePeriod() == authorizedStakePeriodRequirement, "Auth period mismatch");
        require(stakingV1Contract.authorizedStakeAmount() >= authorizedStakeAmountRequirement, "Auth amount mismatch");
        require(!isAccountAuthorized(msg.sender) && stakeBalanceOf(msg.sender) == 0, "Already staked");

        _;
    }
}