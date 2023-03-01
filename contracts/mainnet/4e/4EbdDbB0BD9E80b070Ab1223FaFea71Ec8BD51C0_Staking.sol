// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.9;

interface IStaking {
    struct UserInfo {
        uint256 amount;
        uint256 baseClaimable;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 totalSupply;
        uint256 claimedRewards;
        uint256 lastRewardUpdateTime;
        uint256 accumulatedRewardsPerShare;
    }

    struct EmissionPoint {
        uint256 rewardTokensPerSecond;
        uint256 startTime;
        uint256 endTime;
    }

    function deposit(uint256 amount) external;

    function withdraw(uint256 stakingTokenAmount, bool claimRewards) external;

    function emergencyWithdraw(address recipient, uint256 amount) external;

    function claim() external;

    function getTotalStakedAmount()
        external
        view
        returns (uint256 totalStakedAmount);

    function getClaimableRewards(
        address stakerAddress
    ) external view returns (uint256);

    function getTotalAccruedRewards() external view returns (uint256);

    function getTotalClaimedRewards() external view returns (uint256);

    function getTotalUnclaimedRewards() external view returns (uint256);

    function getTotalUnclaimedRewardsForDate(
        uint256 date
    ) external view returns (uint256);

    function addEmissionsPoints(
        EmissionPoint[] memory emissionSchedulePart
    ) external;

    function editEmissionSchedule(
        uint256 fromEmissionPoint,
        EmissionPoint[] memory newEmissionSchedulePart
    ) external;

    function getIndexOfCurrentEmissionPoint()
        external
        view
        returns (uint256 emissionPointIndex);

    function getEmissionPoint()
        external
        view
        returns (EmissionPoint memory emissionPoint);

    function getEmissionPointsLength() external view returns (uint256);

    function getEmissionPoints(
        uint256 fromPoint,
        uint256 toPoint
    ) external view returns (EmissionPoint[] memory emissionPoints);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStaking.sol";

contract Staking is IStaking, Ownable {
    IERC20 public rewardToken;
    IERC20 public stakingToken;

    address public treasuryAddress;
    uint256 public poolStartTime;
    uint256 private REWARD_TOKEN_PRECISION;

    EmissionPoint[] public emissionSchedule;
    uint256 currentEmissionPoint;

    IStaking.PoolInfo pool;

    mapping(address => IStaking.UserInfo) public poolStakers;

    event Withdraw(address indexed staker, uint256 rewards, uint256 amount);
    event Claim(address indexed staker, uint256 rewards);
    event Deposit(address indexed staker, uint256 amount);
    event EmergencyWithdraw(address recipient, uint256 amount);
    event AddEmissionPoints();
    event EditEmissionPoints();

    constructor(
        address stakeTokenAddress,
        address rewardTokenAddress,
        address _treasuryAddress
    ) {
        treasuryAddress = _treasuryAddress;
        rewardToken = IERC20(rewardTokenAddress);
        stakingToken = IERC20(stakeTokenAddress);
        REWARD_TOKEN_PRECISION = 1e12;
    }

    function changeTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function updatePoolRewards() internal {
        if (
            block.timestamp <= pool.lastRewardUpdateTime ||
            emissionSchedule.length == 0
        ) {
            return;
        }

        if (pool.totalSupply == 0) {
            currentEmissionPoint = calculateEmissionPoint();
            if (
                block.timestamp > emissionSchedule[currentEmissionPoint].endTime
            ) {
                pool.lastRewardUpdateTime = emissionSchedule[
                    currentEmissionPoint
                ].endTime;
            } else {
                pool.lastRewardUpdateTime = block.timestamp;
            }

            return;
        }

        uint256 firstEmissionPoint = currentEmissionPoint;
        uint256 lastEmissionPoint = calculateEmissionPoint();

        if (
            firstEmissionPoint == 0 &&
            emissionSchedule[firstEmissionPoint].startTime > block.timestamp
        ) {
            pool.lastRewardUpdateTime = block.timestamp;
            return;
        }

        if (firstEmissionPoint == lastEmissionPoint) {
            EmissionPoint memory emissionPoint = emissionSchedule[
                currentEmissionPoint
            ];

            uint256 startTime = emissionPoint.startTime >
                pool.lastRewardUpdateTime
                ? emissionPoint.startTime
                : pool.lastRewardUpdateTime;
            uint256 endTime = emissionPoint.endTime > block.timestamp
                ? block.timestamp
                : emissionPoint.endTime;
            uint256 duration = endTime - startTime;
            uint256 reward = duration * emissionPoint.rewardTokensPerSecond;
            pool.accumulatedRewardsPerShare =
                pool.accumulatedRewardsPerShare +
                ((reward * REWARD_TOKEN_PRECISION) / pool.totalSupply);
            pool.lastRewardUpdateTime = endTime;
        } else {
            for (uint256 i = firstEmissionPoint; i <= lastEmissionPoint; i++) {
                EmissionPoint memory emissionPoint = emissionSchedule[i];
                uint256 startTime = emissionPoint.startTime >
                    pool.lastRewardUpdateTime
                    ? emissionPoint.startTime
                    : pool.lastRewardUpdateTime;

                uint256 endTime = emissionPoint.endTime > block.timestamp
                    ? block.timestamp
                    : emissionPoint.endTime;
                uint256 duration = endTime - startTime;
                uint256 reward = duration * emissionPoint.rewardTokensPerSecond;

                pool.accumulatedRewardsPerShare =
                    pool.accumulatedRewardsPerShare +
                    ((reward * REWARD_TOKEN_PRECISION) / pool.totalSupply);

                pool.lastRewardUpdateTime = endTime;
            }
            currentEmissionPoint = lastEmissionPoint;
        }
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount can't be zero");

        if (pool.totalSupply == 0 && poolStartTime == 0) {
            poolStartTime = block.timestamp;
        }

        stakingToken.transferFrom(msg.sender, address(this), amount);

        updatePoolRewards();

        IStaking.UserInfo storage staker = poolStakers[msg.sender];

        if (staker.amount > 0) {
            staker.baseClaimable +=
                ((staker.amount * pool.accumulatedRewardsPerShare) /
                    REWARD_TOKEN_PRECISION) -
                staker.rewardDebt;
        }

        staker.amount += amount;
        pool.totalSupply += amount;

        staker.rewardDebt =
            (staker.amount * pool.accumulatedRewardsPerShare) /
            REWARD_TOKEN_PRECISION;

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 stakedAmount, bool claimRewards) external {
        require(stakedAmount > 0, "Amount can't be a zero");

        IStaking.UserInfo storage staker = poolStakers[msg.sender];

        require(staker.amount >= stakedAmount, "Insufficient balance");

        updatePoolRewards();

        uint256 rewards = staker.baseClaimable +
            (((staker.amount * pool.accumulatedRewardsPerShare) /
                REWARD_TOKEN_PRECISION) - staker.rewardDebt);

        if (claimRewards) {
            staker.baseClaimable = 0;

            pool.claimedRewards += rewards;

            rewardToken.transferFrom(treasuryAddress, msg.sender, rewards);
        } else {
            staker.baseClaimable = rewards;
        }

        staker.amount -= stakedAmount;

        staker.rewardDebt =
            (staker.amount * pool.accumulatedRewardsPerShare) /
            REWARD_TOKEN_PRECISION;

        pool.totalSupply -= stakedAmount;

        stakingToken.transfer(msg.sender, stakedAmount);

        emit Withdraw(msg.sender, rewards, stakedAmount);
    }

    function emergencyWithdraw(
        address recipient,
        uint256 amount
    ) external onlyOwner {
        uint256 stakingBalance = stakingToken.balanceOf(address(this));
        uint256 emergencyWithdrawAmount = stakingBalance - pool.totalSupply;

        require(
            emergencyWithdrawAmount >= amount,
            "Isn't correct Emergency Withdraw Amount"
        );

        stakingToken.transfer(recipient, amount);

        emit EmergencyWithdraw(recipient, amount);
    }

    function claim() external {
        IStaking.UserInfo storage staker = poolStakers[msg.sender];

        updatePoolRewards();

        uint256 rewards = staker.baseClaimable +
            (((staker.amount * pool.accumulatedRewardsPerShare) /
                REWARD_TOKEN_PRECISION) - staker.rewardDebt);

        if (rewards == 0) {
            return;
        }

        staker.baseClaimable = 0;

        pool.claimedRewards += rewards;

        staker.rewardDebt =
            (staker.amount * pool.accumulatedRewardsPerShare) /
            REWARD_TOKEN_PRECISION;

        rewardToken.transferFrom(treasuryAddress, msg.sender, rewards);

        emit Claim(msg.sender, rewards);
    }

    function getTotalStakedAmount()
        external
        view
        returns (uint256 totalStakedAmount)
    {
        return pool.totalSupply;
    }

    function getClaimableRewards(
        address stakerAddress
    ) external view returns (uint256) {
        IStaking.UserInfo memory staker = poolStakers[stakerAddress];

        uint256 lastRewardUpdateTime = pool.lastRewardUpdateTime;
        uint256 accumulatedRewardsPerShare = pool.accumulatedRewardsPerShare;
        uint256 _currentEmissionPoint = currentEmissionPoint;

        if (emissionSchedule.length == 0) {
            return 0;
        }

        if (pool.totalSupply == 0) {
            return staker.baseClaimable;
        }

        uint256 firstEmissionPoint = _currentEmissionPoint;

        uint256 lastEmissionPoint = calculateEmissionPoint();

        if (
            firstEmissionPoint == 0 &&
            emissionSchedule[firstEmissionPoint].startTime > block.timestamp
        ) {
            lastRewardUpdateTime = block.timestamp;
            return 0;
        }

        if (firstEmissionPoint == lastEmissionPoint) {
            EmissionPoint memory emissionPoint = emissionSchedule[
                _currentEmissionPoint
            ];
            uint256 startTime = emissionPoint.startTime > lastRewardUpdateTime
                ? emissionPoint.startTime
                : lastRewardUpdateTime;
            uint256 endTime = emissionPoint.endTime > block.timestamp
                ? block.timestamp
                : emissionPoint.endTime;
            uint256 duration = endTime - startTime;
            uint256 reward = duration * emissionPoint.rewardTokensPerSecond;
            accumulatedRewardsPerShare =
                accumulatedRewardsPerShare +
                ((reward * REWARD_TOKEN_PRECISION) / pool.totalSupply);
            lastRewardUpdateTime = endTime;
        } else {
            for (uint256 i = firstEmissionPoint; i <= lastEmissionPoint; i++) {
                EmissionPoint memory emissionPoint = emissionSchedule[i];

                uint256 startTime = emissionPoint.startTime >
                    lastRewardUpdateTime
                    ? emissionPoint.startTime
                    : lastRewardUpdateTime;
                uint256 endTime = emissionPoint.endTime > block.timestamp
                    ? block.timestamp
                    : emissionPoint.endTime;
                uint256 duration = endTime - startTime;
                uint256 reward = duration * emissionPoint.rewardTokensPerSecond;
                accumulatedRewardsPerShare =
                    accumulatedRewardsPerShare +
                    ((reward * REWARD_TOKEN_PRECISION) / pool.totalSupply);
                lastRewardUpdateTime = endTime;
            }
        }

        uint256 rewards = ((staker.amount * accumulatedRewardsPerShare) /
            REWARD_TOKEN_PRECISION) - staker.rewardDebt;

        return staker.baseClaimable + rewards;
    }

    function getTotalUnclaimedRewards() public view returns (uint256) {
        return getTotalAccruedRewards() - pool.claimedRewards;
    }

    function getTotalClaimedRewards() external view returns (uint256) {
        return pool.claimedRewards;
    }

    function calculateAccruedRewardsFromTo(
        uint256 fromDate,
        uint256 toDate
    ) internal view returns (uint256) {
        uint256 totalAccruedRewards = 0;
        for (uint256 i = 0; i < emissionSchedule.length; i++) {
            uint256 startTime = emissionSchedule[i].startTime;
            uint256 endTime = emissionSchedule[i].endTime;

            if (endTime <= fromDate || startTime >= toDate) {
                continue;
            }

            if (startTime < fromDate) {
                startTime = fromDate;
            }

            if (toDate < endTime) {
                endTime = toDate;
            }

            totalAccruedRewards +=
                (endTime - startTime) *
                emissionSchedule[i].rewardTokensPerSecond;
        }

        return totalAccruedRewards;
    }

    function getTotalAccruedRewards() public view returns (uint256) {
        if (poolStartTime == 0) {
            return 0;
        }
        return calculateAccruedRewardsFromTo(poolStartTime, block.timestamp);
    }

    function getTotalUnclaimedRewardsForDate(
        uint256 date
    ) external view returns (uint256) {
        uint256 totalUnclaimedRewardsForNow = getTotalUnclaimedRewards();

        return
            totalUnclaimedRewardsForNow +
            calculateAccruedRewardsFromTo(block.timestamp, date);
    }

    function addEmissionsPoints(
        EmissionPoint[] memory emissionSchedulePart
    ) public onlyOwner {
        require(
            emissionSchedulePart.length > 0,
            "New emission schedule part must have at least one point"
        );

        require(
            emissionSchedulePart[0].startTime >= block.timestamp,
            "New emission schedule start time should be bigger than now time"
        );

        if (emissionSchedule.length > 0) {
            require(
                emissionSchedulePart[0].startTime >=
                    emissionSchedule[emissionSchedule.length - 1].endTime,
                "Emission points config should have correct start time"
            );
        }

        for (uint256 i = 0; i < emissionSchedulePart.length; i++) {
            require(
                emissionSchedulePart[i].startTime <
                    emissionSchedulePart[i].endTime,
                "Emission points config isn't correct"
            );

            if (i != emissionSchedulePart.length - 1) {
                require(
                    emissionSchedulePart[i].endTime <=
                        emissionSchedulePart[i + 1].startTime,
                    "Emission points config isn't correct"
                );
            }
            emissionSchedule.push(emissionSchedulePart[i]);
        }

        emit AddEmissionPoints();
    }

    function editEmissionSchedule(
        uint256 fromEmissionPoint,
        EmissionPoint[] memory newEmissionSchedulePart
    ) external onlyOwner {
        uint256 currentEmissionPointIndex = calculateEmissionPoint();

        require(
            fromEmissionPoint > currentEmissionPointIndex,
            "Can't edit from this emission point"
        );

        for (
            uint256 i = emissionSchedule.length - 1;
            i >= fromEmissionPoint;
            i--
        ) {
            emissionSchedule.pop();
        }

        addEmissionsPoints(newEmissionSchedulePart);

        emit EditEmissionPoints();
    }

    function calculateEmissionPoint()
        internal
        view
        returns (uint256 emissionPoint)
    {
        if (emissionSchedule.length == 0) {
            return 0;
        }

        if (
            block.timestamp >= emissionSchedule[currentEmissionPoint].startTime
        ) {
            for (
                uint256 i = currentEmissionPoint;
                i < emissionSchedule.length;
                i++
            ) {
                EmissionPoint memory e = emissionSchedule[i];

                if (
                    block.timestamp >= e.startTime &&
                    block.timestamp < e.endTime
                ) {
                    return i;
                }

                if (i == emissionSchedule.length - 1) {
                    return i;
                }

                EmissionPoint memory nextE = emissionSchedule[i + 1];

                if (
                    block.timestamp >= e.endTime &&
                    block.timestamp < nextE.startTime
                ) {
                    return i;
                }
            }
        }
    }

    function getEmissionPointsLength() external view returns (uint256) {
        return emissionSchedule.length;
    }

    function getEmissionPoints(
        uint256 fromPoint,
        uint256 toPoint
    ) external view returns (EmissionPoint[] memory emissionPoints) {
        require(
            fromPoint <= toPoint &&
                fromPoint >= 0 &&
                toPoint < emissionSchedule.length,
            "Params isn't correct"
        );

        uint256 len = toPoint - fromPoint + 1;

        emissionPoints = new EmissionPoint[](len);
        uint256 j = 0;

        for (uint256 i = fromPoint; i <= toPoint; i++) {
            emissionPoints[j] = emissionSchedule[i];
            j++;
        }

        return emissionPoints;
    }

    function getIndexOfCurrentEmissionPoint() external view returns (uint256) {
        return currentEmissionPoint;
    }

    function getEmissionPoint()
        external
        view
        override
        returns (EmissionPoint memory emissionPoint)
    {
        return emissionSchedule[calculateEmissionPoint()];
    }
}