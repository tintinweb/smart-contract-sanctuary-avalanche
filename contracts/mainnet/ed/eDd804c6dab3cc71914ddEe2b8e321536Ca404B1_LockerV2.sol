// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeERC20.sol";
import "ERC20.sol";
import "Initializable.sol";
import "OwnableUpgradeable.sol";
import "PausableUpgradeable.sol";
import "ERC20Upgradeable.sol";

import "IBaseRewardPoolLocker.sol";
import "ILocker.sol";
import "IBribeManager.sol";
import "IMasterChefVTX.sol";

/// @title Locker
/// @author Vector Team
contract LockerV2 is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;
    address public masterchief;
    address public stakingToken; // staking token in masterchief
    address public previousLocker;
    uint256 public maxSlot;

    uint256 public totalUnlocking; // number of vtx in an unlocking slot
    uint256 public constant DENOMINATOR = 10000;

    address public bribeManager;

    IERC20 public VTX;

    IBaseRewardPoolLocker public rewarder;

    UnlockingStrategy[] public unlockingStrategies;

    struct UnlockingStrategy {
        uint256 unlockTime; // Time for full unlock
        uint256 forfeitPercent; // % of stake forfeited
        uint256 rewardPercent; // % of rewards
        uint256 instantUnstakePercent; // % to unstake immediately
        bool isLinear; // is linear unlock
        bool isActive;
    }

    struct UserUnlocking {
        uint256 startTime;
        uint256 endTime;
        uint256 amount; // total amount comitted to the unlock slot, never changes except when reseting slot
        uint256 unlockingStrategy;
        uint256 alreadyUnstaked;
        uint256 alreadyWithdrawn; // total amount already withdrawn from contract ( mainly for linear unlocks)
    }

    mapping(address => uint256) public userUnlocking; // vtx in an unlock slot
    mapping(address => UserUnlocking[]) public userUnlockings;

    mapping(address => uint256) private lastTimeRewardClaimed;

    mapping(address => bool) public migrated;

    mapping(address => bool) public transferWhitelist;

    event UnlockStarts(
        address indexed user,
        uint256 indexed timestamp,
        uint256 amount,
        uint256 strategyIndex
    );
    event ResetSlot(
        address indexed user,
        uint256 indexed timestamp,
        uint256 amount,
        uint256 slotIndex
    );
    event Unlock(address indexed user, uint256 indexed timestamp, uint256 amount);
    event NewDeposit(address indexed user, uint256 indexed timestamp, uint256 amount);
    event Claim(address indexed user, uint256 indexed timestamp);

    function __LockerV2_init_(
        address _masterchief,
        uint256 _maxSlots,
        address _previousLocker,
        address _rewarder,
        address _stakingToken
    ) public initializer {
        __ERC20_init("Locked VTX", "LVTXv2");
        __Ownable_init();
        __Pausable_init();
        require(_maxSlots > 0, "Max slots should not be null");
        maxSlot = _maxSlots;
        masterchief = _masterchief;
        previousLocker = _previousLocker;
        stakingToken = _stakingToken;
        rewarder = IBaseRewardPoolLocker(_rewarder);
        VTX = IERC20(IMasterChefVTX(masterchief).vtx());
    }

    modifier onlyMaster() {
        require(msg.sender == masterchief, "Only Masterchief");
        _;
    }

    function setStrategyStatus(uint256 strategyIndex, bool status) external onlyOwner {
        unlockingStrategies[strategyIndex].isActive = status;
    }

    function setWhitelistForTransfer(address _for, bool status) external onlyOwner {
        transferWhitelist[_for] = status;
    }

    modifier assertEnoughVtxInContract() {
        _;
        require(VTX.balanceOf(address(this)) >= totalLocked(), "CRITICAL FAULT");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBribeManager(address _address) external onlyOwner {
        bribeManager = _address;
    }

    function getAllUserUnlocking(address _user)
        external
        view
        returns (UserUnlocking[] memory slots)
    {
        uint256 length = getUserSlotLength(_user);
        slots = new UserUnlocking[](length);
        for (uint256 i; i < length; i++) {
            slots[i] = userUnlockings[_user][i];
        }
    }

    // total Vtx held in contract
    function totalLocked() public view returns (uint256) {
        return totalSupply() + totalUnlocking;
    }

    function stakeInMasterChief() external onlyOwner {
        IERC20(stakingToken).approve(masterchief, IERC20(stakingToken).balanceOf(address(this)));
        IMasterChefVTX(masterchief).deposit(
            stakingToken,
            IERC20(stakingToken).balanceOf(address(this))
        );
    }

    function _queueRewards(address token, uint256 amount) internal {
        IERC20(token).approve(address(rewarder), amount);
        rewarder.queueNewRewards(amount, token);
    }

    function _harvestVtx() internal whenNotPaused {
        (uint256 pendingVtx, , , ) = IMasterChefVTX(masterchief).pendingTokens(
            stakingToken,
            address(this),
            address(0)
        );
        IMasterChefVTX(masterchief).deposit(stakingToken, 0);
        _queueRewards(address(VTX), pendingVtx);
    }

    modifier harvestVtx() {
        _harvestVtx();
        _;
    }

    // @notice Harvest pending VTX for this contract from the masterchief
    // Queue Vtx in the locker rewarder
    function harvest() external {
        _harvestVtx();
    }

    /// @notice Change the max number of unlocking slots
    /// @param _maxDeposits the new max number
    function setMaxSlots(uint256 _maxDeposits) external onlyOwner {
        require(_maxDeposits > maxSlot, "Cannot decrease slot number");
        maxSlot = _maxDeposits;
    }

    function addNewStrategy(
        uint256 _lockTime,
        uint256 _rewardPercent,
        uint256 _forfeitPercent,
        uint256 _instantUnstakePercent,
        bool _isLinear
    ) external onlyOwner {
        require(_rewardPercent <= DENOMINATOR, "Invalid reward percent");
        require(_forfeitPercent + _instantUnstakePercent <= DENOMINATOR, "Invalid inputs");
        unlockingStrategies.push(
            UnlockingStrategy({
                unlockTime: _lockTime,
                forfeitPercent: _forfeitPercent,
                rewardPercent: _rewardPercent,
                instantUnstakePercent: _instantUnstakePercent,
                isLinear: _isLinear,
                isActive: true
            })
        );
    }

    /// @notice Get the n'th user slot info
    /// @param _user the user
    /// @param n the index of the deposit slot
    function getUserNthSlot(address _user, uint256 n)
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 amount,
            uint256 unlockingStrategy,
            uint256 alreadyUnstaked,
            uint256 alreadyWithdrawn
        )
    {
        UserUnlocking storage slot = userUnlockings[_user][n];
        startTime = slot.startTime;
        endTime = slot.endTime;
        amount = slot.amount;
        unlockingStrategy = slot.unlockingStrategy;
        alreadyUnstaked = slot.alreadyUnstaked;
        alreadyWithdrawn = slot.alreadyWithdrawn;
    }

    /// @notice Get the number of user deposits
    /// @param _user the user
    /// @return nbDeposits the user number of deposit
    function getUserSlotLength(address _user) public view returns (uint256) {
        return userUnlockings[_user].length;
    }

    /// @notice Get the total VTX held by contract for user
    /// @param _user the user
    /// @return the total number of VTX deposited
    function getUserTotalDeposit(address _user) public view returns (uint256) {
        return balanceOf(_user) + userUnlocking[_user];
    }

    // @notice deposit VTX in the contract
    // @param _amount the amount of VTX to deposit
    function deposit(uint256 _amount) external whenNotPaused harvestVtx assertEnoughVtxInContract {
        _deposit(msg.sender, msg.sender, _amount);
    }

    // @notice deposit VTX in the contract
    // @param _amount the amount of VTX to deposit
    // @param _for the address to deposit for
    // @dev the tokens will be taken from msg.sender
    function depositFor(address _for, uint256 _amount)
        external
        whenNotPaused
        harvestVtx
        assertEnoughVtxInContract
    {
        _deposit(msg.sender, _for, _amount);
    }

    function _deposit(
        address spender,
        address _for,
        uint256 _amount
    ) internal {
        VTX.safeTransferFrom(spender, address(this), _amount);
        rewarder.stakeFor(_for, _amount);
        _mint(_for, _amount);
        emit NewDeposit(_for, block.timestamp, _amount);
    }

    function resetSlot(address _for, uint256 slotIndex) internal {
        require(slotIndex < getUserSlotLength(_for), "Slot doesn't exist");
        UserUnlocking storage slot = userUnlockings[_for][slotIndex];
        UnlockingStrategy storage strategy = unlockingStrategies[slot.unlockingStrategy];
        require(
            strategy.instantUnstakePercent == 0 || slot.alreadyWithdrawn == slot.amount,
            "Cannot reset an unfinished slot with instant unlock"
        );
        uint256 remaining = slot.amount - slot.alreadyWithdrawn;
        if (remaining > 0) {
            userUnlocking[_for] -= remaining;
            totalUnlocking -= remaining;
            _mint(_for, remaining);
        }
        rewarder.stakeFor(msg.sender, slot.alreadyUnstaked - slot.alreadyWithdrawn);
        emit ResetSlot(_for, block.timestamp, slot.amount, slotIndex);
        slot.amount = 0;
    }

    // @notice for frontend
    function cancelUnlock(uint256 slotIndex)
        external
        whenNotPaused
        harvestVtx
        assertEnoughVtxInContract
    {
        startUnlock(1, 0, slotIndex);
    }

    // @notice for frontend
    function addToUnlock(uint256 amount, uint256 slotIndex)
        external
        whenNotPaused
        harvestVtx
        assertEnoughVtxInContract
    {
        uint256 userDepositLength = getUserSlotLength(msg.sender);
        require((slotIndex < userDepositLength), "Not in the range of allowed slots");
        UserUnlocking storage info = userUnlockings[msg.sender][slotIndex];
        startUnlock(info.unlockingStrategy, info.amount + amount, slotIndex);
    }

    // @notice starts an unlock slot
    // @notice this function can also be used to reset or change a slot
    // @param strategyIndex The choosen unlock strategy
    // @param amount the VTX amount for the slot
    // @param slotIndex the index of the slot to use
    function startUnlock(
        uint256 strategyIndex,
        uint256 amount,
        uint256 slotIndex
    ) public whenNotPaused harvestVtx assertEnoughVtxInContract {
        uint256 userDepositLength = getUserSlotLength(msg.sender);
        require(
            (slotIndex <= userDepositLength) && (slotIndex < maxSlot),
            "Not in the range of allowed slots"
        );
        if (userDepositLength > slotIndex && userUnlockings[msg.sender][slotIndex].amount != 0) {
            resetSlot(msg.sender, slotIndex);
        }
        require(amount <= balanceOf(msg.sender), "Not enough locked VTX to start unlock");
        require(strategyIndex != 0, "Strategy reserved for migration");
        UnlockingStrategy storage strategy = unlockingStrategies[strategyIndex];
        require(strategy.isActive, "Strategy not active");

        _burn(msg.sender, amount);

        uint256 amountToUnlock = (strategy.instantUnstakePercent * amount) / DENOMINATOR;
        VTX.safeTransfer(msg.sender, amountToUnlock);

        uint256 amountToForfeit = (strategy.forfeitPercent * amount) / DENOMINATOR;
        _approveTokenIfNeeded(address(VTX), address(rewarder), amountToForfeit);
        IBaseRewardPoolLocker(rewarder).donateRewards(amountToForfeit, address(VTX));

        uint256 forfeitedOrUnlocked = amountToUnlock + amountToForfeit;
        uint256 amountToUnstakeForRewards = ((DENOMINATOR - strategy.rewardPercent) *
            (amount - forfeitedOrUnlocked)) / DENOMINATOR;
        rewarder.withdrawFor(
            msg.sender,
            amountToUnstakeForRewards + forfeitedOrUnlocked,
            getUserRewardPercentage(msg.sender),
            true
        );

        userUnlocking[msg.sender] += amount - forfeitedOrUnlocked;
        totalUnlocking += amount - forfeitedOrUnlocked;

        require(
            IBribeManager(bribeManager).userTotalVote(msg.sender) <= balanceOf(msg.sender),
            "Too much vote cast"
        );
        if (slotIndex < userDepositLength) {
            userUnlockings[msg.sender][slotIndex] = UserUnlocking({
                startTime: block.timestamp,
                endTime: block.timestamp + strategy.unlockTime,
                unlockingStrategy: strategyIndex,
                amount: amount - forfeitedOrUnlocked,
                alreadyUnstaked: amountToUnstakeForRewards,
                alreadyWithdrawn: 0
            });
        } else {
            userUnlockings[msg.sender].push(
                UserUnlocking({
                    startTime: block.timestamp,
                    endTime: block.timestamp + strategy.unlockTime,
                    unlockingStrategy: strategyIndex,
                    amount: amount - forfeitedOrUnlocked,
                    alreadyUnstaked: amountToUnstakeForRewards,
                    alreadyWithdrawn: 0
                })
            );
        }
        emit UnlockStarts(msg.sender, block.timestamp, amount, strategyIndex);
    }

    // @notice unlock a finished slot
    // @param slotIndex the index of the slot to unlock
    function unlock(uint256 slotIndex) external whenNotPaused harvestVtx assertEnoughVtxInContract {
        UserUnlocking storage slot = userUnlockings[msg.sender][slotIndex];
        require(slot.amount > 0, "Inactive slot");
        uint256 remaining = slot.amount - slot.alreadyWithdrawn;
        require(remaining > 0, "Already fully withdrawn"); // should never happen

        UnlockingStrategy storage strategy = unlockingStrategies[slot.unlockingStrategy];
        uint256 amountToUnstake;
        uint256 amountToWithdraw;
        if (slot.endTime <= block.timestamp) {
            amountToUnstake = slot.amount - slot.alreadyUnstaked;
            amountToWithdraw = slot.amount - slot.alreadyWithdrawn;
        } else {
            require(strategy.isLinear, "Nothing to unlock");
            uint256 totalTime = slot.endTime - slot.startTime;
            uint256 passedTime = block.timestamp - slot.startTime;
            uint256 ratio = (passedTime * DENOMINATOR) / totalTime;
            if (ratio > DENOMINATOR) {
                ratio = DENOMINATOR;
            }
            uint256 linearAmount = (slot.amount * ratio) / DENOMINATOR;
            if (linearAmount > slot.alreadyWithdrawn) {
                amountToWithdraw = linearAmount - slot.alreadyWithdrawn;
            }
            amountToUnstake =
                (amountToWithdraw * unlockingStrategies[slot.unlockingStrategy].rewardPercent) /
                DENOMINATOR;
        }
        userUnlocking[msg.sender] -= amountToWithdraw;
        totalUnlocking -= amountToWithdraw;
        VTX.safeTransfer(msg.sender, amountToWithdraw);
        rewarder.withdrawFor(
            msg.sender,
            amountToUnstake,
            getUserRewardPercentage(msg.sender),
            true
        );
        slot.alreadyWithdrawn += amountToWithdraw;
        slot.alreadyUnstaked += amountToUnstake;
        emit Unlock(msg.sender, block.timestamp, slot.amount);
        if (slot.alreadyWithdrawn == slot.amount) {
            resetSlot(msg.sender, slotIndex);
        }
    }

    // @notice compute the percentage of rewards owed to the user
    // this function should always return 10000 if no slots is expired for the user
    function getUserRewardPercentage(address _user) public view returns (uint256 rewardPercentage) {
        // should return the percentage of rewards to send to the user ( in case of no interaction after a slot expire)
        // step 1 : get the  total user staked
        uint256 totalUserStaked = rewarder.balanceOf(_user);
        if (totalUserStaked == 0) return 0;
        uint256 totalUserStakedWithFullReward = totalUserStaked;
        // setp 2 : search for finished user slot
        uint256 length = getUserSlotLength(_user);
        for (uint256 i; i < length; i++) {
            UserUnlocking storage slot = userUnlockings[_user][i];
            if (slot.endTime < block.timestamp && slot.amount != 0) {
                uint256 slotStakedAmount = slot.amount - slot.alreadyUnstaked;

                if (slotStakedAmount > 0) {
                    // compute the percentage for this particular slot
                    uint256 lastInteractionTimestamp = lastTimeRewardClaimed[msg.sender] >
                        slot.startTime
                        ? lastTimeRewardClaimed[msg.sender]
                        : slot.startTime;
                    uint256 totalSlotTime = slot.endTime - lastInteractionTimestamp;
                    uint256 passedTime = block.timestamp - lastInteractionTimestamp;
                    uint256 slotRewardPercentage = (totalSlotTime * DENOMINATOR) / passedTime;
                    // get the staked amount for this slot
                    totalUserStakedWithFullReward -= slotStakedAmount;
                    // get the percentage of all stake for this slot
                    uint256 slotStakedPercentage = (slotStakedAmount * DENOMINATOR) /
                        totalUserStaked;
                    rewardPercentage += (slotStakedPercentage * slotRewardPercentage) / DENOMINATOR;
                }
            }
        }
        rewardPercentage += (totalUserStakedWithFullReward * DENOMINATOR) / totalUserStaked;
    }

    // @notice claim locker rewards
    // revert if a slot is expired & not withdrawn
    function claim() external whenNotPaused harvestVtx assertEnoughVtxInContract {
        _claim(msg.sender);
    }

    // @notice claim locker rewards for another user
    // revert if a slot is expired & not withdrawn
    function claimFor(address _for) external whenNotPaused harvestVtx assertEnoughVtxInContract {
        _claim(_for);
    }

    function _claim(address _for) internal whenNotPaused {
        uint256 length = getUserSlotLength(_for);
        for (uint256 i; i < length; i++) {
            UserUnlocking memory slot = userUnlockings[_for][i];
            if (
                slot.endTime <= block.timestamp &&
                slot.amount != 0 &&
                unlockingStrategies[slot.unlockingStrategy].rewardPercent != 0
            ) {
                revert("You need to withdraw all finished slots with rewards before claiming");
            } // may be more gas efficient than a require in a loop
        } // maybe also only write an error code that will be translated in FE to reduce revert msg length

        rewarder.getReward(_for, DENOMINATOR);
        lastTimeRewardClaimed[_for] = block.timestamp;
        emit Claim(_for, block.timestamp);
    }

    function _migrate(
        address _from,
        address _to,
        bool[] calldata onlyDeposit
    ) internal {
        require(!migrated[_from], "Already migrated");
        migrated[_from] = true;
        uint256 length = ILocker(previousLocker).getUserDepositLength(_from);
        require(onlyDeposit.length == length, "Incorrect input");
        uint256 totalAmountToStake;
        uint256 totalAmountToRefund;
        UnlockingStrategy storage strategy = unlockingStrategies[0];
        for (uint256 i; i < length; i++) {
            (, uint256 endTime, uint256 amount) = ILocker(previousLocker).getUserNthDeposit(
                _from,
                i
            );
            uint256 amountToStake;
            if (endTime < block.timestamp) {
                totalAmountToRefund += amount;
            } else {
                amountToStake = (amount * strategy.rewardPercent) / DENOMINATOR;
                if (onlyDeposit[i]) {
                    _mint(_to, amount);
                } else {
                    userUnlocking[_to] += amount;
                    totalUnlocking += amount;
                    userUnlockings[_to].push(
                        UserUnlocking({
                            startTime: block.timestamp,
                            endTime: endTime,
                            unlockingStrategy: 0,
                            amount: amount,
                            alreadyUnstaked: amount - amountToStake,
                            alreadyWithdrawn: 0
                        })
                    );
                }
            }
            totalAmountToStake += amountToStake;
        }
        uint256 actualLength = getUserSlotLength(_to);
        require(actualLength <= maxSlot, "Max slot reached");
        rewarder.stakeFor(_to, totalAmountToStake);
        VTX.safeTransfer(_to, totalAmountToRefund);
    }

    // @notice migrate from the previous locker
    function migrate(address user, bool[] calldata onlyDeposit) external whenNotPaused onlyMaster {
        _migrate(user, user, onlyDeposit);
    }

    // @notice migrate from the previous locker
    function migrateFor(
        address _from,
        address _to,
        bool[] calldata onlyDeposit
    ) external whenNotPaused onlyMaster {
        _migrate(_from, _to, onlyDeposit);
    }

    /// @notice increase allowance to a contract to the maximum amount for a specific token if it is needed
    /// @param token the token to increase the allowance of
    /// @param _to the contract to increase the allowance
    /// @param _amount the amount of allowance that the contract needs
    function _approveTokenIfNeeded(
        address token,
        address _to,
        uint256 _amount
    ) private {
        if (IERC20(token).allowance(address(this), _to) < _amount) {
            IERC20(token).approve(_to, type(uint256).max);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!(from == address(0) || to == address(0))) {
            require(transferWhitelist[from] || transferWhitelist[to], "Not whitelisted");
            rewarder.withdrawFor(from, amount, 0, false);
            rewarder.stakeFor(to, amount);
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from != address(0)) {
            require(
                IBribeManager(bribeManager).userTotalVote(from) <= balanceOf(from),
                "Too much vote cast"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "IERC20MetadataUpgradeable.sol";
import "ContextUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
pragma solidity ^0.8.0;

interface IBaseRewardPoolLocker {
    struct Reward {
        address rewardToken;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 historicalRewards;
    }

    function rewards(address token) external view returns (Reward memory rewardInfo);

    function rewardTokens() external view returns (address[] memory);

    function getStakingToken() external view returns (address);

    function getReward(address _account) external returns (bool);

    function getReward(address _account, uint256 percentage) external;

    function rewardDecimals(address token) external view returns (uint256);

    function stakingDecimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function rewardPerToken(address token) external view returns (uint256);

    function updateFor(address account) external;

    function earned(address account, address token) external view returns (uint256);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function withdrawFor(
        address user,
        uint256 amount,
        uint256 rewardPercent,
        bool claim
    ) external;

    function queueNewRewards(uint256 _rewards, address token) external returns (bool);

    function donateRewards(uint256 _amountReward, address _rewardToken) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILocker {
    function setLockTime(uint256 _newvalue) external;

    function maxDeposits() external returns (uint256 n);

    function getUserNthDeposit(address _user, uint256 n)
        external
        view
        returns (
            uint256 depositTime,
            uint256 endTime,
            uint256 amount
        );

    function getUserDepositLength(address _user) external view returns (uint256 nbDeposits);

    function depositFor(
        uint256 _amount,
        uint256 _index,
        address user,
        bool force
    ) external;

    function withdrawFor(
        uint256 _amount,
        uint256 _index,
        address user
    ) external;

    function migrate(address user, bool[] calldata onlyDeposit) external;

    function migrateFor(
        address _from,
        address _for,
        bool[] calldata onlyDeposit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBribeManager {
    function userTotalVote(address user) external view returns (uint256);

    function getUserMaxVote(address _user) external view returns (uint256 maxVote);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterChefVTX {
    function poolLength() external view returns (uint256);

    function setPoolManagerStatus(address _address, bool _bool) external;

    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder,
        address _helper
    ) external;

    function set(
        address _lp,
        uint256 _allocPoint,
        address _rewarder,
        address _locker,
        bool overwrite
    ) external;

    function vtxLocker() external view returns (address);

    function createRewarder(address _lpToken, address mainRewardToken) external returns (address);

    // View function to see pending VTXs on frontend.
    function getPoolInfo(address token)
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

    function pendingTokens(
        address _lp,
        address _user,
        address token
    )
        external
        view
        returns (
            uint256 pendingVTX,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function rewarderBonusTokenInfo(address _lp)
        external
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function massUpdatePools() external;

    function updatePool(address _lp) external;

    function deposit(address _lp, uint256 _amount) external;

    function depositFor(
        address _lp,
        uint256 _amount,
        address sender
    ) external;

    function lock(
        address _lp,
        uint256 _amount,
        uint256 _index,
        bool force
    ) external;

    function unlock(
        address _lp,
        uint256 _amount,
        uint256 _index
    ) external;

    function multiUnlock(
        address _lp,
        uint256[] calldata _amount,
        uint256[] calldata _index
    ) external;

    function withdraw(address _lp, uint256 _amount) external;

    function withdrawFor(
        address _lp,
        uint256 _amount,
        address _sender
    ) external;

    function multiclaim(address[] memory _lps, address user_address) external;

    function emergencyWithdraw(address _lp, address sender) external;

    function updateEmissionRate(uint256 _vtxPerSec) external;

    function depositInfo(address _lp, address _user) external view returns (uint256 depositAmount);

    function setPoolHelper(address _lp, address _helper) external;

    function authorizeLocker(address _locker) external;

    function lockFor(
        address _lp,
        uint256 _amount,
        uint256 _index,
        address _for,
        bool force
    ) external;

    function vtx() external view returns (address);
}