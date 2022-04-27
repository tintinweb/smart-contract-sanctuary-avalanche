// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IDegisToken} from "../tokens/interfaces/IDegisToken.sol";
import {Math} from "../libraries/Math.sol";
import {IVeDEG} from "../governance/interfaces/IVeDEG.sol";

/**
 * @title  Farming Pool
 * @notice This contract is for LPToken mining on Degis
 * @dev    The pool id starts from 1 rather than 0
 *         The degis reward is calculated by timestamp rather than block number
 *
 *         VeDEG will boost the farming speed by having a extra reward type
 *         The extra reward is shared by those staking lptokens with veDEG balances
 *         Every time the veDEG balance change, the reward will be updated
 *
 *         The basic reward depends on the liquidity inside the pool
 *         Update with a piecewise function
 *         liquidity amount:   |---------------|------------------|----------------
 *                             0           threshold 1        threshold 2
 *          reward speed:            speed1          speed2             speed3
 *
 *         The speed update will be updated one tx after the last tx that triggers the threshold
 *         The reward update will be another one tx later
 */
contract FarmingPoolUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IDegisToken;
    using Math for uint256;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    string public constant name = "Degis LP Farming Pool";

    // The reward token is degis
    IDegisToken public degis;

    // The bonus reward depends on veDEG
    IVeDEG public veDEG;

    // SCALE/Precision used for calculating rewards
    uint256 public constant SCALE = 1e12;

    // PoolId starts from 1
    uint256 public _nextPoolId;

    // Farming starts from a certain block timestamp
    // To keep the same with naughty price pools, we change from block numbers to timestamps
    uint256 public startTimestamp;

    struct PoolInfo {
        address lpToken; // LPToken address
        uint256 basicDegisPerSecond; // Basic Reward speed
        uint256 bonusDegisPerSecond; // Bonus reward speed
        uint256 lastRewardTimestamp; // Last reward timestamp
        uint256 accDegisPerShare; // Accumulated degis per share (for those without veDEG boosting)
        uint256 accDegisPerBonusShare; // Accumulated degis per bonus share (for those with veDEG boosting)
        uint256 totalBonus; // Total bonus factors
    }
    PoolInfo[] public poolList;

    // lptoken address => poolId
    mapping(address => uint256) public poolMapping;

    // poolId => alreadyFarming
    mapping(uint256 => bool) public isFarming;

    struct UserInfo {
        uint256 rewardDebt; // degis reward debt
        uint256 stakingBalance; // the amount of a user's staking in the pool
        uint256 bonus; // user bonus point (by veDEG balance)
    }
    // poolId => userAddress => userInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Extra claimable balance when updating bonus from veDEG
    mapping(uint256 => mapping(address => uint256)) public extraClaimable;

    // Reward speed change with liquidity inside contract
    mapping(uint256 => uint256[]) public thresholdBasic;
    mapping(uint256 => uint256[]) public piecewiseBasic;
    uint256 public currentRewardLevel;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event StartTimestampChanged(uint256 startTimestamp);
    event Stake(address staker, uint256 poolId, uint256 amount);
    event Withdraw(address staker, uint256 poolId, uint256 amount);
    event Harvest(
        address staker,
        address rewardReceiver,
        uint256 poolId,
        uint256 pendingReward
    );
    event NewPoolAdded(
        address lpToken,
        uint256 basicDegisPerSecond,
        uint256 bonusDegisPerSecond
    );
    event FarmingPoolStarted(uint256 poolId, uint256 timestamp);
    event FarmingPoolStopped(uint256 poolId, uint256 timestamp);
    event DegisRewardChanged(
        uint256 poolId,
        uint256 basicDegisPerSecond,
        uint256 bonusDegisPerSecond
    );
    event PoolUpdated(
        uint256 poolId,
        uint256 accDegisPerShare,
        uint256 accDegisPerBonusShare
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(address _degis) public initializer {
        require(_degis != address(0), "Zero address");

        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        degis = IDegisToken(_degis);

        // Start from 1
        _nextPoolId = 1;

        poolList.push(
            PoolInfo({
                lpToken: address(0),
                basicDegisPerSecond: 0,
                bonusDegisPerSecond: 0,
                lastRewardTimestamp: 0,
                accDegisPerShare: 0,
                accDegisPerBonusShare: 0,
                totalBonus: 0
            })
        );
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice The address can not be zero
     */
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Zero address");
        _;
    }

    /**
     * @notice The pool is still in farming
     */
    modifier stillFarming(uint256 _poolId) {
        require(isFarming[_poolId], "Pool is not farming");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** View Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check the amount of pending degis reward
     * @param _poolId PoolId of this farming pool
     * @param _user User address
     * @return pendingDegisAmount Amount of pending degis
     */
    function pendingDegis(uint256 _poolId, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo memory poolInfo = poolList[_poolId];

        if (
            poolInfo.lastRewardTimestamp == 0 ||
            block.timestamp < poolInfo.lastRewardTimestamp ||
            block.timestamp < startTimestamp
        ) return 0;

        UserInfo memory user = userInfo[_poolId][_user];

        // Total lp token balance
        uint256 lp_balance = IERC20(poolInfo.lpToken).balanceOf(address(this));

        // Accumulated shares to be calculated
        uint256 accDegisPerShare = poolInfo.accDegisPerShare;
        uint256 accDegisPerBonusShare = poolInfo.accDegisPerBonusShare;

        if (lp_balance == 0) return 0;
        else {
            // If the pool is still farming, update the info
            if (isFarming[_poolId]) {
                // Deigs amount given to this pool
                uint256 timePassed = block.timestamp -
                    poolInfo.lastRewardTimestamp;
                uint256 basicReward = poolInfo.basicDegisPerSecond * timePassed;
                // Update accDegisPerShare
                // LPToken may have different decimals
                accDegisPerShare += (basicReward * SCALE) / lp_balance;

                // If there is any bonus reward
                if (poolInfo.totalBonus > 0) {
                    uint256 bonusReward = poolInfo.bonusDegisPerSecond *
                        timePassed;
                    accDegisPerBonusShare +=
                        (bonusReward * SCALE) /
                        poolInfo.totalBonus;
                }
            }

            // If the pool has stopped, not update the info
            uint256 pending = (user.stakingBalance *
                accDegisPerShare +
                user.bonus *
                accDegisPerBonusShare) /
                SCALE +
                extraClaimable[_poolId][_user] -
                user.rewardDebt;

            return pending;
        }
    }

    /**
     * @notice Get the total pool list
     * @return pooList Total pool list
     */
    function getPoolList() external view returns (PoolInfo[] memory) {
        return poolList;
    }

    /**
     * @notice Get a user's balance
     * @param _poolId Id of the pool
     * @param _user User address
     * @return balance User's balance (lpToken)
     */
    function getUserBalance(uint256 _poolId, address _user)
        external
        view
        returns (uint256)
    {
        return userInfo[_poolId][_user].stakingBalance;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Set Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setVeDEG(address _veDEG) external onlyOwner {
        veDEG = IVeDEG(_veDEG);
    }

    /**
     * @notice Set the start block timestamp
     * @param _startTimestamp New start block timestamp
     */
    function setStartTimestamp(uint256 _startTimestamp)
        external
        onlyOwner
        whenNotPaused
    {
        // Can only be set before any pool is added
        require(
            _nextPoolId == 1,
            "Can not set start timestamp after adding a pool"
        );

        startTimestamp = _startTimestamp;
        emit StartTimestampChanged(_startTimestamp);
    }

    /**
     * @notice Set piecewise reward and threshold
     * @param _poolId Id of the pool
     * @param _threshold Piecewise threshold
     * @param _reward Piecewise reward
     */
    function setPiecewise(
        uint256 _poolId,
        uint256[] calldata _threshold,
        uint256[] calldata _reward
    ) external onlyOwner {
        thresholdBasic[_poolId] = _threshold;
        piecewiseBasic[_poolId] = _reward;

        // If reward for mimimum level is > 0, update isFarming
        if (_reward[0] > 0) isFarming[_poolId] = true;
        else isFarming[_poolId] = false;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Main Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Add a new lp into the pool
     * @dev Can only be called by the owner
     *      The reward speed can be 0 and set later by setDegisReward function
     * @param _lpToken LP token address
     * @param _basicDegisPerSecond Basic reward speed(per second) for this new pool
     * @param _bonusDegisPerSecond Bonus reward speed(per second) for this new pool
     * @param _withUpdate Whether update all pools' status
     */
    function add(
        address _lpToken,
        uint256 _basicDegisPerSecond,
        uint256 _bonusDegisPerSecond,
        bool _withUpdate
    ) public notZeroAddress(_lpToken) onlyOwner whenNotPaused {
        // Check if already exists, if the poolId is 0, that means not in the pool
        require(!_alreadyInPool(_lpToken), "Already in the pool");

        if (_bonusDegisPerSecond > 0)
            require(_basicDegisPerSecond > 0, "Only bonus");

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardTimestamp = block.timestamp > startTimestamp
            ? block.timestamp
            : startTimestamp;

        // Push this new pool into the list
        poolList.push(
            PoolInfo({
                lpToken: _lpToken,
                basicDegisPerSecond: _basicDegisPerSecond,
                bonusDegisPerSecond: _bonusDegisPerSecond,
                lastRewardTimestamp: lastRewardTimestamp,
                accDegisPerShare: 0,
                accDegisPerBonusShare: 0,
                totalBonus: 0
            })
        );

        // Store the poolId and set the farming status to true
        if (_basicDegisPerSecond > 0) isFarming[_nextPoolId] = true;

        poolMapping[_lpToken] = _nextPoolId++;

        emit NewPoolAdded(_lpToken, _basicDegisPerSecond, _bonusDegisPerSecond);
    }

    /**
     * @notice Update the degisPerSecond for a specific pool (set to 0 to stop farming)
     * @param _poolId Id of the farming pool
     * @param _basicDegisPerSecond New basic reward amount per second
     * @param _bonusDegisPerSecond New bonus reward amount per second
     * @param _withUpdate Whether update all pools
     */
    function setDegisReward(
        uint256 _poolId,
        uint256 _basicDegisPerSecond,
        uint256 _bonusDegisPerSecond,
        bool _withUpdate
    ) public onlyOwner whenNotPaused {
        // Ensure there already exists this pool
        require(poolList[_poolId].lastRewardTimestamp != 0, "Pool not exists");

        if (_bonusDegisPerSecond > 0)
            require(_basicDegisPerSecond > 0, "Only bonus");

        if (_withUpdate) massUpdatePools();
        else updatePool(_poolId);

        // Not farming now + reward > 0 => Restart
        if (isFarming[_poolId] == false && _basicDegisPerSecond > 0) {
            isFarming[_poolId] = true;
            emit FarmingPoolStarted(_poolId, block.timestamp);
        }

        if (_basicDegisPerSecond == 0) {
            isFarming[_poolId] = false;
            emit FarmingPoolStopped(_poolId, block.timestamp);
        } else {
            poolList[_poolId].basicDegisPerSecond = _basicDegisPerSecond;
            poolList[_poolId].bonusDegisPerSecond = _bonusDegisPerSecond;
            emit DegisRewardChanged(
                _poolId,
                _basicDegisPerSecond,
                _bonusDegisPerSecond
            );
        }
    }

    /**
     * @notice Stake LP token into the farming pool
     * @dev Can only stake to the pools that are still farming
     * @param _poolId Id of the farming pool
     * @param _amount Staking amount
     */
    function stake(uint256 _poolId, uint256 _amount)
        public
        nonReentrant
        whenNotPaused
        stillFarming(_poolId)
    {
        require(_amount > 0, "Can not stake zero");

        PoolInfo storage pool = poolList[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        // Must update first
        updatePool(_poolId);

        // First distribute the reward if exists
        if (user.stakingBalance > 0) {
            uint256 pending = (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
                SCALE +
                extraClaimable[_poolId][msg.sender] -
                user.rewardDebt;

            // Clear the extra record (has been distributed)
            extraClaimable[_poolId][msg.sender] = 0;

            // Real reward amount by safe transfer
            uint256 reward = _safeDegisTransfer(msg.sender, pending);
            emit Harvest(msg.sender, msg.sender, _poolId, reward);
        }

        // Actual deposit amount
        uint256 actualAmount = _safeLPTransfer(
            false,
            pool.lpToken,
            msg.sender,
            _amount
        );

        user.stakingBalance += actualAmount;

        if (address(veDEG) != address(0)) {
            // Update the user's bonus if veDEG boosting is on
            uint256 oldBonus = user.bonus;
            user.bonus = (user.stakingBalance * veDEG.balanceOf(msg.sender))
                .sqrt();
            // Update the pool's total bonus
            pool.totalBonus = pool.totalBonus + user.bonus - oldBonus;
        }

        user.rewardDebt =
            (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
            SCALE;

        emit Stake(msg.sender, _poolId, actualAmount);
    }

    /**
     * @notice Withdraw lptoken from the pool
     * @param _poolId Id of the farming pool
     * @param _amount Amount of lp tokens to withdraw
     */
    function withdraw(uint256 _poolId, uint256 _amount)
        public
        nonReentrant
        whenNotPaused
    {
        require(_amount > 0, "Zero amount");

        PoolInfo storage pool = poolList[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        require(user.stakingBalance >= _amount, "Not enough stakingBalance");

        // Update if the pool is still farming
        // Users can withdraw even after the pool stopped
        if (isFarming[_poolId]) updatePool(_poolId);
        else {
            pool.lastRewardTimestamp = block.timestamp;
        }

        uint256 pending = (user.stakingBalance *
            pool.accDegisPerShare +
            user.bonus *
            pool.accDegisPerBonusShare) /
            SCALE +
            extraClaimable[_poolId][msg.sender] -
            user.rewardDebt;

        // Clear the extra record (has been distributed)
        extraClaimable[_poolId][msg.sender] = 0;

        // Real reward amount by safe transfer
        uint256 reward = _safeDegisTransfer(msg.sender, pending);
        emit Harvest(msg.sender, msg.sender, _poolId, reward);

        uint256 actualAmount = _safeLPTransfer(
            true,
            pool.lpToken,
            msg.sender,
            _amount
        );

        user.stakingBalance -= actualAmount;

        // Update the user's bonus when veDEG boosting is on
        if (address(veDEG) != address(0)) {
            uint256 oldBonus = user.bonus;
            user.bonus = (user.stakingBalance * veDEG.balanceOf(msg.sender))
                .sqrt();
            // Update the pool's total bonus
            pool.totalBonus = pool.totalBonus + user.bonus - oldBonus;
        }

        user.rewardDebt =
            (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
            SCALE;

        emit Withdraw(msg.sender, _poolId, actualAmount);
    }

    /**
     * @notice Harvest the degis reward and can be sent to another address
     * @param _poolId Id of the farming pool
     * @param _to Receiver of degis rewards
     */
    function harvest(uint256 _poolId, address _to)
        public
        nonReentrant
        whenNotPaused
    {
        // Only update the pool when it is still in farming
        if (isFarming[_poolId]) updatePool(_poolId);
        else {
            poolList[_poolId].lastRewardTimestamp = block.timestamp;
        }

        PoolInfo memory pool = poolList[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        uint256 pendingReward = (user.stakingBalance *
            pool.accDegisPerShare +
            user.bonus *
            pool.accDegisPerBonusShare) /
            SCALE +
            extraClaimable[_poolId][msg.sender] -
            user.rewardDebt;

        extraClaimable[_poolId][msg.sender] = 0;

        require(pendingReward > 0, "No pending reward");

        // Update the reward debt
        user.rewardDebt =
            (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
            SCALE;

        // Transfer the reward
        uint256 reward = _safeDegisTransfer(_to, pendingReward);

        emit Harvest(msg.sender, _to, _poolId, reward);
    }

    /**
     * @notice Update the pool's reward status
     * @param _poolId Id of the farming pool
     */
    function updatePool(uint256 _poolId) public {
        PoolInfo storage pool = poolList[_poolId];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }

        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));

        // No LP deposited, then just update the lastRewardTimestamp
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 timePassed = block.timestamp - pool.lastRewardTimestamp;

        uint256 basicReward = timePassed * pool.basicDegisPerSecond;
        uint256 bonusReward = timePassed * pool.bonusDegisPerSecond;

        pool.accDegisPerShare += (basicReward * SCALE) / lpSupply;

        if (pool.totalBonus == 0) {
            pool.accDegisPerBonusShare = 0;
        } else {
            pool.accDegisPerBonusShare +=
                (bonusReward * SCALE) /
                pool.totalBonus;
        }

        // Don't forget to set the farming pool as minter
        degis.mintDegis(address(this), basicReward + bonusReward);

        pool.lastRewardTimestamp = block.timestamp;

        // Update the new reward speed
        // Only if the threshold are already set
        if (thresholdBasic[_poolId].length > 0) {
            uint256 currentLiquidity = thresholdBasic[_poolId][
                currentRewardLevel
            ];
            if (
                currentRewardLevel < thresholdBasic[_poolId].length - 1 &&
                lpSupply >= thresholdBasic[_poolId][currentRewardLevel + 1]
            ) {
                _updateRewardSpeed(_poolId);
            } else if (lpSupply < currentLiquidity) {
                _updateRewardSpeed(_poolId);
            }
        }

        emit PoolUpdated(
            _poolId,
            pool.accDegisPerShare,
            pool.accDegisPerBonusShare
        );
    }

    /**
     * @notice Update all farming pools (except for those stopped ones)
     * @dev Can be called by anyone
     *      Only update those active pools
     */
    function massUpdatePools() public {
        uint256 length = poolList.length;
        for (uint256 poolId = 1; poolId < length; ++poolId) {
            if (isFarming[poolId] == false) {
                poolList[poolId].lastRewardTimestamp = block.timestamp;
                continue;
            } else updatePool(poolId);
        }
    }

    /**
     * @notice Update a user's bonus
     * @dev When veDEG has balance change
     *      Only called by veDEG contract
     * @param _user User address
     * @param _newVeDEGBalance New veDEG balance
     */
    function updateBonus(address _user, uint256 _newVeDEGBalance) external {
        require(msg.sender == address(veDEG), "Only veDEG contract");

        // loop over each pool : beware gas cost!
        uint256 length = poolList.length;

        for (uint256 poolId; poolId < length; ++poolId) {
            // Skip if the pool is not farming
            if (!isFarming[poolId]) continue;

            UserInfo storage user = userInfo[poolId][_user];
            // Skip if user doesn't have any deposit in the pool
            if (user.stakingBalance == 0) continue;

            PoolInfo storage pool = poolList[poolId];

            // first, update pool
            updatePool(poolId);

            // Update the extra claimable amount
            uint256 pending = (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
                SCALE -
                user.rewardDebt;
            extraClaimable[poolId][_user] += pending;

            // get oldFactor
            uint256 oldFactor = user.bonus; // get old factor
            // calculate newFactor
            uint256 newFactor = (_newVeDEGBalance * user.stakingBalance).sqrt();
            // update user factor
            user.bonus = newFactor;
            // update reward debt, take into account newFactor
            user.rewardDebt =
                (user.stakingBalance *
                    pool.accDegisPerShare +
                    newFactor *
                    pool.accDegisPerBonusShare) /
                SCALE;

            // Update the pool's total bonus
            pool.totalBonus = pool.totalBonus + newFactor - oldFactor;
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // ********************************** Internal Functions ********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check if a lptoken has been added into the pool before
     * @dev This can also be written as a modifier
     * @param _lpToken LP token address
     * @return _isInPool Wether this lp is already in pool
     */
    function _alreadyInPool(address _lpToken)
        internal
        view
        returns (bool _isInPool)
    {
        uint256 poolId = poolMapping[_lpToken];

        _isInPool = (poolId != 0) ? true : false;
    }

    /**
     * @notice Safe degis transfer (check if the pool has enough DEGIS token)
     * @param _to User's address
     * @param _amount Amount to transfer
     */
    function _safeDegisTransfer(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 poolDegisBalance = degis.balanceOf(address(this));
        require(poolDegisBalance > 0, "No Degis token in the pool");

        if (_amount > poolDegisBalance) {
            degis.safeTransfer(_to, poolDegisBalance);
            return (poolDegisBalance);
        } else {
            degis.safeTransfer(_to, _amount);
            return _amount;
        }
    }

    /**
     * @notice Finish the transfer of LP Token
     * @dev The lp token may have loss during transfer
     * @param _out Whether the lp token is out
     * @param _lpToken LP token address
     * @param _user User address
     * @param _amount Amount of lp tokens
     */
    function _safeLPTransfer(
        bool _out,
        address _lpToken,
        address _user,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 poolBalanceBefore = IERC20(_lpToken).balanceOf(address(this));

        if (_out) IERC20(_lpToken).safeTransfer(_user, _amount);
        else IERC20(_lpToken).safeTransferFrom(_user, address(this), _amount);

        uint256 poolBalanceAfter = IERC20(_lpToken).balanceOf(address(this));

        return
            _out
                ? poolBalanceBefore - poolBalanceAfter
                : poolBalanceAfter - poolBalanceBefore;
    }

    /**
     * @notice Update the reward speed
     * @param _poolId Pool ID
     */
    function _updateRewardSpeed(uint256 _poolId) internal {
        uint256 currentBasicBalance = IERC20(poolList[_poolId].lpToken)
            .balanceOf(address(this));

        uint256 basicRewardSpeed;

        for (uint256 i = thresholdBasic[_poolId].length - 1; i >= 0; --i) {
            if (currentBasicBalance >= thresholdBasic[_poolId][i]) {
                basicRewardSpeed = piecewiseBasic[_poolId][i];
                // record current reward level
                currentRewardLevel = i;
                break;
            } else continue;
        }

        poolList[_poolId].basicDegisPerSecond = basicRewardSpeed;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
     * @dev This empty reserved space is put in place to allow future versions to add new
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDegisToken is IERC20, IERC20Permit {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Functions ************************************** //
    // ---------------------------------------------------------------------------------------- //
    function CAP() external view returns (uint256);

    /**
     * @notice Mint degis tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be minted
     */
    function mintDegis(address _account, uint256 _amount) external;

    /**
     * @notice Burn degis tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be burned
     */
    function burnDegis(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Math {
    uint256 internal constant WAD = 10**18;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IVeERC20.sol";

/**
 * @dev Interface of the VePtp
 */
interface IVeDEG is IVeERC20 {
    function isUser(address _addr) external view returns (bool);

    function deposit(uint256 _amount) external;

    function claim() external;

    function withdraw(uint256 _amount) external;

    function getStakedPtp(address _addr) external view returns (uint256);

    function getVotes(address _account) external view returns (uint256);

    function lockVeDEG(address _to, uint256 _amount) external;

    function unlockVeDEG(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}