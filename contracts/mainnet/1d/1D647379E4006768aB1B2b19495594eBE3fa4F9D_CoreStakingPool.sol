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

import {Ownable} from "../utils/Ownable.sol";
import {BasePool} from "./abstracts/BasePool.sol";

contract CoreStakingPool is Ownable, BasePool {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(
        address _degisToken,
        address _poolToken,
        address _factory,
        uint256 _startTimestamp,
        uint256 _degisPerSecond
    )
        Ownable(msg.sender)
        BasePool(
            _degisToken,
            _poolToken,
            _factory,
            _startTimestamp,
            _degisPerSecond
        )
    {}

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Stake function, will call the stake in BasePool
     * @param _user User address
     * @param _amount Amount to stake
     * @param _lockUntil Lock until timestamp (0 means flexible staking)
     */
    function _stake(
        address _user,
        uint256 _amount,
        uint256 _lockUntil
    ) internal override {
        super._stake(_user, _amount, _lockUntil);
    }

    /**
     * @notice Unstake function, will check some conditions and call the unstake in BasePool
     * @param _user User address
     * @param _depositId Deposit id
     * @param _amount Amount to unstake
     */
    function _unstake(
        address _user,
        uint256 _depositId,
        uint256 _amount
    ) internal override {
        UserInfo storage user = users[_msgSender()];
        Deposit memory stakeDeposit = user.deposits[_depositId];
        require(
            stakeDeposit.lockedFrom == 0 ||
                block.timestamp >= stakeDeposit.lockedUntil,
            "Deposit not yet unlocked"
        );

        super._unstake(_user, _depositId, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "./Context.sol";

/**
 * @dev The owner can be set during deployment, not default to be msg.sender
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _initialOwner) {
        _transferOwnership(_initialOwner);
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Leaves the contract without owner. It will not be possible to call
     *         `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * @dev    Renouncing ownership will leave the contract without an owner,
     *         thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Can only be called by the current owner.
     * @param  newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Internal function without access restriction.
     * @param  newOwner Address of the new owner
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../interfaces/IPool.sol";
import "../interfaces/IStakingPoolFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract BasePool is IPool, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    struct UserInfo {
        uint256 tokenAmount;
        uint256 totalWeight;
        uint256 rewardDebt;
        // An array of holder's deposits
        Deposit[] deposits;
    }
    mapping(address => UserInfo) public users;

    // Token address staked in this pool
    address public poolToken;

    // Reward token: degis
    address public degisToken;

    // Reward start timestamp
    uint256 public startTimestamp;

    // Degis reward speed
    uint256 public degisPerSecond;

    // Last check point
    uint256 public lastRewardTimestamp;

    // Accumulated degis per weight till now
    uint256 public accDegisPerWeight;

    // Total weight in the pool
    uint256 public totalWeight;

    // Factory contract address
    address public factory;

    // Fees are paid to the previous stakers
    uint256 public constant fee = 2;

    // Weight multiplier constants
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

    uint256 internal constant YEAR_STAKE_WEIGHT_MULTIPLIER =
        2 * WEIGHT_MULTIPLIER;

    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event Stake(address user, uint256 amount, uint256 lockUntil);

    event Unstake(address user, uint256 amount);

    event Harvest(address user, uint256 amount);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Constructor
     */
    constructor(
        address _degisToken,
        address _poolToken,
        address _factory,
        uint256 _startTimestamp,
        uint256 _degisPerSecond
    ) {
        degisToken = _degisToken;
        poolToken = _poolToken;
        factory = _factory;

        degisPerSecond = _degisPerSecond;

        startTimestamp = _startTimestamp;

        lastRewardTimestamp = block.timestamp > _startTimestamp
            ? block.timestamp
            : _startTimestamp;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Only the factory can call some functions
     */
    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get a user's deposit info
     * @param _user User address
     * @return deposits[] User's deposit info
     */
    function getUserDeposits(address _user)
        external
        view
        returns (Deposit[] memory)
    {
        return users[_user].deposits;
    }

    /**
     * @notice Get pending rewards
     * @param _user User address
     * @return pendingReward User's pending rewards
     */
    function pendingReward(address _user) external view returns (uint256) {
        if (
            block.timestamp < lastRewardTimestamp ||
            block.timestamp < startTimestamp ||
            totalWeight == 0
        ) return 0;

        uint256 blocks = block.timestamp - lastRewardTimestamp;
        uint256 degisReward = blocks * degisPerSecond;

        // recalculated value for `yieldRewardsPerWeight`
        uint256 newDegisPerWeight = rewardToWeight(degisReward, totalWeight) +
            accDegisPerWeight;

        // based on the rewards per weight value, calculate pending rewards;
        UserInfo memory user = users[_user];

        uint256 pending = weightToReward(user.totalWeight, newDegisPerWeight) -
            user.rewardDebt;

        return pending;
    }

    function rewardToWeight(uint256 reward, uint256 rewardPerWeight)
        public
        pure
        returns (uint256)
    {
        return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
    }

    function weightToReward(uint256 weight, uint256 rewardPerWeight)
        public
        pure
        returns (uint256)
    {
        return (weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //
    function setDegisPerSecond(uint256 _degisPerSecond) external onlyFactory {
        degisPerSecond = _degisPerSecond;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Stake tokens
     * @param _amount Amount of tokens to stake
     * @param _lockUntil Lock until timestamp
     */
    function stake(uint256 _amount, uint256 _lockUntil) external {
        _stake(msg.sender, _amount, _lockUntil);
    }

    /**
     * @notice Unstake tokens
     * @param _depositId Deposit id to be unstaked
     * @param _amount Amount of tokens to unstake
     */
    function unstake(uint256 _depositId, uint256 _amount) external {
        _unstake(msg.sender, _depositId, _amount);
    }

    function harvest() external {
        // First update the pool
        updatePool();

        UserInfo storage user = users[msg.sender];

        // calculate pending yield rewards, this value will be returned
        uint256 pending = _pendingReward(msg.sender);

        if (pending == 0) return;

        _safeDegisTransfer(msg.sender, pending);

        user.rewardDebt = weightToReward(user.totalWeight, accDegisPerWeight);

        emit Harvest(msg.sender, pending);
    }

    function updatePool() public {
        _updatePoolWithFee(0);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Update pool status with fee (if any)
     * @param _fee Fee to be distributed
     */
    function _updatePoolWithFee(uint256 _fee) internal {
        if (block.timestamp <= lastRewardTimestamp) return;

        uint256 balance = IERC20(poolToken).balanceOf(address(this));

        if (balance == 0) {
            lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 timePassed = block.timestamp - lastRewardTimestamp;

        // There is _fee when staking
        uint256 degisReward = timePassed * degisPerSecond + _fee;

        // Mint reward to this staking pool
        IStakingPoolFactory(factory).mintReward(address(this), degisReward);

        accDegisPerWeight += rewardToWeight(degisReward, totalWeight);

        lastRewardTimestamp = block.timestamp;
    }

    /**
     * @notice Finish stake process
     * @param _user User address
     * @param _amount Amount of tokens to stake
     * @param _lockUntil Lock until timestamp
     */
    function _stake(
        address _user,
        uint256 _amount,
        uint256 _lockUntil
    ) internal virtual nonReentrant {
        require(block.timestamp > startTimestamp, "Pool not started yet");
        require(_amount > 0, "Zero amount");
        require(
            _lockUntil == 0 || (_lockUntil > block.timestamp),
            "Invalid lock interval"
        );
        if (_lockUntil >= block.timestamp + 365 days)
            _lockUntil = block.timestamp + 365 days;

        uint256 depositFee;
        if (IERC20(poolToken).balanceOf(address(this)) > 0) {
            // Charge deposit fee and distribute to previous stakers
            depositFee = (_amount * fee) / 100;
            _updatePoolWithFee(depositFee);
        } else updatePool();

        UserInfo storage user = users[_user];

        if (user.tokenAmount > 0) {
            _distributeReward(_user);
        }

        uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
        transferPoolTokenFrom(msg.sender, address(this), _amount);
        uint256 newBalance = IERC20(poolToken).balanceOf(address(this));

        // Actual amount is without the fee
        uint256 addedAmount = newBalance - previousBalance - depositFee;

        uint256 lockFrom = _lockUntil > 0 ? block.timestamp : 0;
        uint256 lockUntil = _lockUntil;

        uint256 stakeWeight = timeToWeight(lockUntil - lockFrom) * addedAmount;

        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);

        // create and save the deposit (append it to deposits array)
        Deposit memory deposit = Deposit({
            tokenAmount: addedAmount,
            weight: stakeWeight,
            lockedFrom: lockFrom,
            lockedUntil: lockUntil
        });
        // deposit ID is an index of the deposit in `deposits` array
        user.deposits.push(deposit);

        // update user record
        user.tokenAmount += addedAmount;
        user.totalWeight += stakeWeight;
        user.rewardDebt = weightToReward(user.totalWeight, accDegisPerWeight);

        // update global variable
        totalWeight += stakeWeight;

        // emit an event
        emit Stake(msg.sender, _amount, _lockUntil);
    }

    /**
     * @notice Finish unstake process
     * @param _user User address
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function _unstake(
        address _user,
        uint256 _depositId,
        uint256 _amount
    ) internal virtual nonReentrant {
        // verify an amount is set
        require(_amount > 0, "zero amount");

        UserInfo storage user = users[_user];

        Deposit storage stakeDeposit = user.deposits[_depositId];

        // verify available balance
        // if staker address ot deposit doesn't exist this check will fail as well
        require(stakeDeposit.tokenAmount >= _amount, "amount exceeds stake");

        // update smart contract state
        updatePool();
        // and process current pending rewards if any
        _distributeReward(_user);

        // recalculate deposit weight
        uint256 previousWeight = stakeDeposit.weight;

        uint256 newWeight = timeToWeight(
            stakeDeposit.lockedUntil - stakeDeposit.lockedFrom
        ) * (stakeDeposit.tokenAmount - _amount);

        // update the deposit, or delete it if its depleted
        if (stakeDeposit.tokenAmount - _amount == 0) {
            delete user.deposits[_depositId];
        } else {
            stakeDeposit.tokenAmount -= _amount;
            stakeDeposit.weight = newWeight;
        }

        // update user record
        user.tokenAmount -= _amount;
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        user.rewardDebt = weightToReward(user.totalWeight, accDegisPerWeight);

        // update global variable
        totalWeight -= (previousWeight - newWeight);

        // otherwise just return tokens back to holder
        transferPoolToken(msg.sender, _amount);

        // emit an event
        emit Unstake(msg.sender, _amount);
    }

    /**
     * @notice Lock time => Lock weight
     * @dev 1 year = 2e6
     *      1 week = 1e6
     *      2 weeks = 1e6 * ( 1 + 1 / 365)
     */
    function timeToWeight(uint256 _length)
        public
        pure
        returns (uint256 _weight)
    {
        _weight =
            ((_length * WEIGHT_MULTIPLIER) / 365 days) +
            WEIGHT_MULTIPLIER;
    }

    /**
     * @notice Check pending reward after update
     * @param _user User address
     */
    function _pendingReward(address _user)
        internal
        view
        returns (uint256 pending)
    {
        // read user data structure into memory
        UserInfo memory user = users[_user];

        // and perform the calculation using the values read
        return
            weightToReward(user.totalWeight, accDegisPerWeight) -
            user.rewardDebt;
    }

    /**
     * @notice Distribute reward to staker
     * @param _user User address
     */
    function _distributeReward(address _user) internal {
        uint256 pending = _pendingReward(_user);

        if (pending == 0) return;
        else {
            _safeDegisTransfer(_user, pending);
        }
    }

    /**
     * @notice Transfer pool token from pool to user
     */
    function transferPoolToken(address _to, uint256 _value) internal {
        // just delegate call to the target
        IERC20(poolToken).safeTransfer(_to, _value);
    }

    /**
     * @notice Transfer pool token from user to pool
     * @param _from User address
     * @param _to Pool address
     * @param _value Amount of tokens to transfer
     */
    function transferPoolTokenFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        IERC20(poolToken).safeTransferFrom(_from, _to, _value);
    }

    /**
     * @notice Safe degis transfer (check if the pool has enough DEGIS token)
     * @param _to User's address
     * @param _amount Amount to transfer
     */
    function _safeDegisTransfer(address _to, uint256 _amount) internal {
        uint256 totalDegis = IERC20(degisToken).balanceOf(address(this));
        if (_amount > totalDegis) {
            IERC20(degisToken).safeTransfer(_to, totalDegis);
        } else {
            IERC20(degisToken).safeTransfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

/**
 * @title Illuvium Pool
 *
 * @notice An abstraction representing a pool, see IlluviumPoolBase for details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
interface IPool {
    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of stake with its amount, weight and term (time interval)
     */
    struct Deposit {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev stake weight
        uint256 weight;
        // @dev locking period - from
        uint256 lockedFrom;
        // @dev locking period - until
        uint256 lockedUntil;
    }

    // for the rest of the functions see Soldoc in IlluviumPoolBase

    function degisToken() external view returns (address);

    function poolToken() external view returns (address);

    function startTimestamp() external view returns (uint256);

    function degisPerSecond() external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function accDegisPerWeight() external view returns (uint256);

    function pendingReward(address _user) external view returns (uint256);

    function setDegisPerSecond(uint256 _degisPerSecond) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IStakingPoolFactory {
    function createPool(
        address _poolToken,
        uint256 _startBlock,
        uint256 _degisPerBlock
    ) external;

    function mintReward(address _to, uint256 _amount) external;
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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