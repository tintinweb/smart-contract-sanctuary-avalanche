// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Decimal} from "./utils/Decimal.sol";
import {SignedDecimal, MixedDecimal} from "./utils/MixedDecimal.sol";
import {RewardsDistributionRecipient} from "./RewardsDistributionRecipient.sol";
import {DecimalERC20} from "./utils/DecimalERC20.sol";
import {BlockContext} from "./utils/BlockContext.sol";
import {SupplySchedule} from "./SupplySchedule.sol";
import {IMultiTokenRewardRecipient} from "./interface/IMultiTokenRewardRecipient.sol";

import {UUPSProxiable} from "./proxy/UUPSProxiable.sol";

contract StakingReserve is
    RewardsDistributionRecipient,
    IMultiTokenRewardRecipient,
    DecimalERC20,
    BlockContext,
    ReentrancyGuard,
    UUPSProxiable
{
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using MixedDecimal for SignedDecimal.signedDecimal;

    //
    // EVENTS
    //
    event RewardWithdrawn(address staker, uint256 amount);
    event FeeInEpoch(address token, uint256 fee, uint256 epoch);

    //
    // STRUCT
    //

    // TODO can improve if change to cumulative version
    struct EpochReward {
        Decimal.decimal perpReward;
        // key by Fee ERC20 token address
        mapping(address => Decimal.decimal) feeMap;
    }

    struct StakeBalance {
        bool exist;
        // denominated in ifnxToken
        Decimal.decimal totalBalance;
        uint256 rewardEpochCursor;
        uint256 feeEpochCursor;
        // key by epochReward index (the starting epoch index when staker stake take effect)
        mapping(uint256 => LockedBalance) lockedBalanceMap;
    }

    struct LockedBalance {
        bool exist;
        // locked staking amount
        Decimal.decimal locked;
        // timeWeightedLocked = locked * (how long has it been until endOfThisEpoch / epochPeriod)
        Decimal.decimal timeWeightedLocked;
    }

    struct FeeBalance {
        address token;
        Decimal.decimal balance;
    }

    //**********************************************************//
    //    Can not change the order of below state variables     //
    //**********************************************************//
    SignedDecimal.signedDecimal private totalPendingStakeBalance;

    // the unit of vestingPeriod is epoch, by default 52 epochs equals to 1 year
    uint256 public vestingPeriod;

    // key by staker address
    mapping(address => StakeBalance) public stakeBalanceMap;

    // key by epoch index
    mapping(uint256 => Decimal.decimal) private totalEffectiveStakeMap;

    EpochReward[] public epochRewardHistory;

    address[] public stakers;

    address public ifnxToken;
    SupplySchedule private supplySchedule;

    /* @dev
     * record all the fee tokens (not remove)
     */
    IERC20[] public feeTokens;
    // key by Fee ERC20 token address
    mapping(IERC20 => Decimal.decimal) public feeMap;

    // address who can call `notifyTokenAmount`, it's `clearingHouse` for now.
    address public feeNotifier;

    IERC20 public override token;

    //**********************************************************//
    //    Can not change the order of above state variables     //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // FUNCTIONS
    //

    function initialize(
        address _ifnxToken,
        SupplySchedule _supplySchedule,
        address _feeNotifier,
        uint256 _vestingPeriod
    ) public initializer {
        ifnxToken = _ifnxToken;
        supplySchedule = _supplySchedule;
        feeNotifier = _feeNotifier;
        vestingPeriod = _vestingPeriod;
    }

    function setVestingPeriod(uint256 _vestingPeriod) external onlyOwner {
        vestingPeriod = _vestingPeriod;
    }

    /**
     * @dev staker can increase staking any time,
     */
    function stake(Decimal.decimal memory _amount) public {
        require(_amount.toUint() > 0, "Input amount is zero");
        address sender = _msgSender();
        require(
            _amount.toUint() <= getUnlockedBalance(sender).toUint(),
            "Stake more than all balance"
        );
        require(supplySchedule.isStarted(), "IFNX reward has not started");

        uint256 epochDuration = supplySchedule.mintDuration();
        uint256 afterNextEpochIndex = nextEpochIndex() + 1;
        uint256 nextEndEpochTimestamp = supplySchedule.nextMintTime();

        // ignore this epoch if keeper didn't endEpoch in time
        Decimal.decimal memory timeWeightedLocked;
        if (nextEndEpochTimestamp > _blockTimestamp()) {
            // calculate timeWeightedLocked based on additional staking amount and the remain time during this epoch
            timeWeightedLocked = _amount
                .mulScalar(nextEndEpochTimestamp - _blockTimestamp())
                .divScalar(epochDuration);

            // update stakerBalance for next epoch
            increaseStake(sender, nextEpochIndex(), _amount, timeWeightedLocked);
        }

        // update stakerBalance for next + 1 epoch
        StakeBalance storage balance = stakeBalanceMap[sender];
        if (balance.lockedBalanceMap[afterNextEpochIndex].exist) {
            increaseStake(sender, afterNextEpochIndex, _amount, _amount);
        } else {
            LockedBalance memory currentBalance = balance.lockedBalanceMap[nextEpochIndex()];
            balance.lockedBalanceMap[afterNextEpochIndex] = LockedBalance(
                true,
                currentBalance.locked,
                currentBalance.locked
            );
        }

        // update global stake balance states
        totalEffectiveStakeMap[nextEpochIndex()] = totalEffectiveStakeMap[nextEpochIndex()].addD(
            timeWeightedLocked
        );
        totalPendingStakeBalance = totalPendingStakeBalance.addD(_amount).subD(timeWeightedLocked);
    }

    /**
     * @dev staker can decrease staking from stakeBalanceForNextEpoch
     */
    function unstake(Decimal.decimal calldata _amount) external {
        require(_amount.toUint() > 0, "Input amount is zero");
        address sender = _msgSender();
        require(
            _amount.toUint() <= getUnstakableBalance(sender).toUint(),
            "Unstake more than locked balance"
        );

        // decrease stake balance for after next epoch
        uint256 afterNextEpochIndex = nextEpochIndex() + 1;
        LockedBalance memory afterNextLockedBalance = getLockedBalance(sender, afterNextEpochIndex);
        stakeBalanceMap[sender].lockedBalanceMap[afterNextEpochIndex] = LockedBalance(
            true,
            afterNextLockedBalance.locked.subD(_amount),
            afterNextLockedBalance.timeWeightedLocked.subD(_amount)
        );

        // update global stake balance states
        totalPendingStakeBalance = totalPendingStakeBalance.subD(_amount);
    }

    function depositAndStake(Decimal.decimal calldata _amount) external nonReentrant {
        deposit(_msgSender(), _amount);
        stake(_amount);
    }

    function withdraw(Decimal.decimal calldata _amount) external nonReentrant {
        require(_amount.toUint() != 0, "Input amount is zero");
        address sender = _msgSender();
        require(_amount.toUint() <= getUnlockedBalance(sender).toUint(), "Not enough balance");
        stakeBalanceMap[sender].totalBalance = stakeBalanceMap[sender].totalBalance.subD(_amount);
        _transfer(IERC20(ifnxToken), sender, _amount);
    }

    /**
     * @dev add epoch reward, update totalEffectiveStakeMap
     */
    function notifyRewardAmount(Decimal.decimal calldata _amount)
        external
        override
        onlyRewardsDistribution
    {
        // record reward to epochRewardHistory
        Decimal.decimal memory totalBalanceBeforeEndEpoch = getTotalBalance();
        EpochReward storage tmp = epochRewardHistory.push();
        tmp.perpReward = _amount;
        // Note this is initialized AFTER a new entry is pushed to epochRewardHistory, hence the minus 1
        uint256 currentEpochIndex = nextEpochIndex() - 1;
        for (uint256 i; i < feeTokens.length; i++) {
            IERC20 token = feeTokens[i];
            emit FeeInEpoch(address(token), feeMap[token].toUint(), currentEpochIndex);
            epochRewardHistory[currentEpochIndex].feeMap[address(token)] = feeMap[token];
            feeMap[token] = Decimal.zero();
        }

        // update totalEffectiveStakeMap for coming epoch
        SignedDecimal.signedDecimal
            memory updatedTotalEffectiveStakeBalance = totalPendingStakeBalance.addD(
                totalBalanceBeforeEndEpoch
            );
        require(updatedTotalEffectiveStakeBalance.toInt() >= 0, "Unstake more than locked balance");
        totalEffectiveStakeMap[(nextEpochIndex())] = updatedTotalEffectiveStakeBalance.abs();
        totalPendingStakeBalance = SignedDecimal.zero();
    }

    function notifyTokenAmount(IERC20 _token, Decimal.decimal calldata _amount) external override {
        require(feeNotifier == _msgSender(), "!feeNotifier");
        require(_amount.toUint() > 0, "amount can't be 0");

        feeMap[_token] = feeMap[_token].addD(_amount);
        if (!isExistedFeeToken(_token)) {
            feeTokens.push(_token);
        }
    }

    /*
     * claim all fees and vested reward at once
     * update lastUpdatedEffectiveStake
     */
    function claimFeesAndVestedReward() external nonReentrant {
        // calculate fee and reward
        address staker = _msgSender();
        Decimal.decimal memory reward = getVestedReward(staker);
        FeeBalance[] memory fees = getFeeRevenue(staker);
        bool hasFees = fees.length > 0;
        bool hasReward = reward.toUint() > 0;
        require(hasReward || hasFees, "no vested reward or fee");

        // transfer fee reward
        stakeBalanceMap[staker].feeEpochCursor = epochRewardHistory.length;
        for (uint256 i = 0; i < fees.length; i++) {
            if (fees[i].balance.toUint() != 0) {
                _transfer(IERC20(fees[i].token), staker, fees[i].balance);
            }
        }

        // transfer perp reward
        if (hasReward && epochRewardHistory.length >= vestingPeriod) {
            // solhint-disable reentrancy
            stakeBalanceMap[staker].rewardEpochCursor = epochRewardHistory.length - vestingPeriod;
            _transfer(IERC20(ifnxToken), staker, reward);
            emit RewardWithdrawn(staker, reward.toUint());
        }
    }

    function setFeeNotifier(address _notifier) external onlyOwner {
        feeNotifier = _notifier;
    }

    //
    // VIEW FUNCTIONS
    //

    function isExistedFeeToken(IERC20 _token) public view returns (bool) {
        for (uint256 i = 0; i < feeTokens.length; i++) {
            if (feeTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function nextEpochIndex() public view returns (uint256) {
        return epochRewardHistory.length;
    }

    /**
     * everyone can query total balance to check current collateralization ratio.
     * TotalBalance of time weighted locked IFNX for coming epoch
     */
    function getTotalBalance() public view returns (Decimal.decimal memory) {
        return totalEffectiveStakeMap[nextEpochIndex()];
    }

    function getTotalEffectiveStake(uint256 _epochIndex)
        public
        view
        returns (Decimal.decimal memory)
    {
        return totalEffectiveStakeMap[_epochIndex];
    }

    function getFeeOfEpoch(uint256 _epoch, address _token)
        public
        view
        returns (Decimal.decimal memory)
    {
        return epochRewardHistory[_epoch].feeMap[_token];
    }

    function getFeeRevenue(address _staker) public view returns (FeeBalance[] memory feeBalance) {
        StakeBalance storage balance = stakeBalanceMap[_staker];
        if (balance.feeEpochCursor == nextEpochIndex()) {
            return feeBalance;
        }

        uint256 numberOfTokens = feeTokens.length;
        feeBalance = new FeeBalance[](numberOfTokens);
        Decimal.decimal memory latestLockedStake;
        // TODO enhancement, we can loop feeTokens first to save more gas if some feeToken was not used
        for (uint256 i = balance.feeEpochCursor; i < nextEpochIndex(); i++) {
            if (balance.lockedBalanceMap[i].timeWeightedLocked.toUint() != 0) {
                latestLockedStake = balance.lockedBalanceMap[i].timeWeightedLocked;
            }
            if (latestLockedStake.toUint() == 0) {
                continue;
            }
            Decimal.decimal memory effectiveStakePercentage = latestLockedStake.divD(
                totalEffectiveStakeMap[i]
            );

            for (uint256 j = 0; j < numberOfTokens; j++) {
                IERC20 token = feeTokens[j];
                Decimal.decimal memory feeInThisEpoch = getFeeOfEpoch(i, address(token));
                if (feeInThisEpoch.toUint() == 0) {
                    continue;
                }
                feeBalance[j].balance = feeBalance[j].balance.addD(
                    feeInThisEpoch.mulD(effectiveStakePercentage)
                );
                feeBalance[j].token = address(token);
            }
        }
    }

    function getVestedReward(address _staker) public view returns (Decimal.decimal memory reward) {
        if (nextEpochIndex() < vestingPeriod) {
            return Decimal.zero();
        }

        // Note that rewardableEpochEnd is exclusive. The last rewardable epoch index = rewardableEpochEnd - 1
        uint256 rewardableEpochEnd = nextEpochIndex() - vestingPeriod;
        StakeBalance storage balance = stakeBalanceMap[_staker];
        if (balance.rewardEpochCursor > rewardableEpochEnd) {
            return Decimal.zero();
        }

        Decimal.decimal memory latestLockedStake;
        for (uint256 i = balance.rewardEpochCursor; i < rewardableEpochEnd; i++) {
            if (balance.lockedBalanceMap[i].timeWeightedLocked.toUint() != 0) {
                latestLockedStake = balance.lockedBalanceMap[i].timeWeightedLocked;
            }
            if (latestLockedStake.toUint() == 0) {
                continue;
            }
            Decimal.decimal memory rewardInThisEpoch = epochRewardHistory[i]
                .perpReward
                .mulD(latestLockedStake)
                .divD(totalEffectiveStakeMap[i]);
            reward = reward.addD(rewardInThisEpoch);
        }
    }

    function getUnlockedBalance(address _staker) public view returns (Decimal.decimal memory) {
        Decimal.decimal memory lockedForNextEpoch = getLockedBalance(_staker, nextEpochIndex())
            .locked;
        return stakeBalanceMap[_staker].totalBalance.subD(lockedForNextEpoch);
    }

    // unstakable = [email protected]+1
    function getUnstakableBalance(address _staker) public view returns (Decimal.decimal memory) {
        return getLockedBalance(_staker, nextEpochIndex() + 1).locked;
    }

    // only store locked balance when there's changed, so if the target lockedBalance is not exist,
    // use the lockedBalance from the closest previous epoch
    function getLockedBalance(address _staker, uint256 _epochIndex)
        public
        view
        returns (LockedBalance memory)
    {
        while (_epochIndex >= 0) {
            LockedBalance memory lockedBalance = stakeBalanceMap[_staker].lockedBalanceMap[
                _epochIndex
            ];
            if (lockedBalance.exist) {
                return lockedBalance;
            }
            if (_epochIndex == 0) {
                break;
            }
            _epochIndex -= 1;
        }
        return LockedBalance(false, Decimal.zero(), Decimal.zero());
    }

    function getEpochRewardHistoryLength() external view returns (uint256) {
        return epochRewardHistory.length;
    }

    function getRewardEpochCursor(address _staker) public view returns (uint256) {
        return stakeBalanceMap[_staker].rewardEpochCursor;
    }

    function getFeeEpochCursor(address _staker) public view returns (uint256) {
        return stakeBalanceMap[_staker].feeEpochCursor;
    }

    //
    // Private
    //

    function increaseStake(
        address _sender,
        uint256 _epochIndex,
        Decimal.decimal memory _locked,
        Decimal.decimal memory _timeWeightedLocked
    ) private {
        LockedBalance memory lockedBalance = getLockedBalance(_sender, _epochIndex);
        stakeBalanceMap[_sender].lockedBalanceMap[_epochIndex] = LockedBalance(
            true,
            lockedBalance.locked.addD(_locked),
            lockedBalance.timeWeightedLocked.addD(_timeWeightedLocked)
        );
    }

    function deposit(address _sender, Decimal.decimal memory _amount) private {
        require(_amount.toUint() != 0, "Input amount is zero");
        StakeBalance storage balance = stakeBalanceMap[_sender];
        if (!balance.exist) {
            stakers.push(_sender);
            balance.exist = true;
            // set rewardEpochCursor for the first staking
            balance.rewardEpochCursor = nextEpochIndex();
        }
        balance.totalBalance = balance.totalBalance.addD(_amount);
        _transferFrom(IERC20(ifnxToken), _sender, address(this), _amount);
    }

    function proxiableUUID() public pure override returns (bytes32) {
        return keccak256("infinix-finance.StakingReserve");
    }

    function updateCode(address newAddress) external override onlyOwner {
        _updateCodeAddress(newAddress);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;

import {DecimalMath} from "./DecimalMath.sol";

library Decimal {
    using DecimalMath for uint256;

    struct decimal {
        uint256 d;
    }

    function zero() internal pure returns (decimal memory) {
        return decimal(0);
    }

    function one() internal pure returns (decimal memory) {
        return decimal(DecimalMath.unit(18));
    }

    function toUint(decimal memory x) internal pure returns (uint256) {
        return x.d;
    }

    function modD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        return decimal((x.d * DecimalMath.unit(18)) % y.d);
        // return decimal(x.d.mul(DecimalMath.unit(18)) % y.d);
    }

    function cmp(decimal memory x, decimal memory y) internal pure returns (int8) {
        if (x.d > y.d) {
            return 1;
        } else if (x.d < y.d) {
            return -1;
        }
        return 0;
    }

    /// @dev add two decimals
    function addD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d + y.d;
        return t;
    }

    /// @dev subtract two decimals
    function subD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d - y.d;
        return t;
    }

    /// @dev multiple two decimals
    function mulD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a decimal by a uint256
    function mulScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d * y;
        return t;
    }

    /// @dev divide two decimals
    function divD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a decimal by a uint256
    function divScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d / y;
        return t;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;

import {Decimal} from "./Decimal.sol";
import {SignedDecimal} from "./SignedDecimal.sol";

/// @dev To handle a signedDecimal add/sub/mul/div a decimal and provide convert decimal to signedDecimal helper
library MixedDecimal {
    using SignedDecimal for SignedDecimal.signedDecimal;

    uint256 private constant _INT256_MAX = 2**255 - 1;
    string private constant ERROR_NON_CONVERTIBLE =
        "MixedDecimal: uint value is bigger than _INT256_MAX";

    modifier convertible(Decimal.decimal memory x) {
        require(_INT256_MAX >= x.d, ERROR_NON_CONVERTIBLE);
        _;
    }

    function fromDecimal(Decimal.decimal memory x)
        internal
        pure
        convertible(x)
        returns (SignedDecimal.signedDecimal memory)
    {
        return SignedDecimal.signedDecimal(int256(x.d));
    }

    function toUint(SignedDecimal.signedDecimal memory x) internal pure returns (uint256) {
        return x.abs().d;
    }

    /// @dev add SignedDecimal.signedDecimal and Decimal.decimal, using SignedSafeMath directly
    function addD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d + int256(y.d);
        return t;
    }

    /// @dev subtract SignedDecimal.signedDecimal by Decimal.decimal, using SignedSafeMath directly
    function subD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d - int256(y.d);
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by Decimal.decimal
    function mulD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.mulD(fromDecimal(y));
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by a uint256
    function mulScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.mulScalar(int256(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a Decimal.decimal
    function divD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.divD(fromDecimal(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a uint256
    function divScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.divScalar(int256(y));
        return t;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;
pragma experimental ABIEncoderV2;

import {IfnxFiOwnableUpgrade} from "./utils/IfnxFiOwnableUpgrade.sol";
import {IRewardRecipient} from "./interface/IRewardRecipient.sol";
import {Decimal} from "./utils/Decimal.sol";

abstract contract RewardsDistributionRecipient is IfnxFiOwnableUpgrade, IRewardRecipient {
    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//
    address public rewardsDistribution;
    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // FUNCTIONS
    //

    function notifyRewardAmount(Decimal.decimal calldata _amount) external virtual override;

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }

    modifier onlyRewardsDistribution() {
        require(rewardsDistribution == _msgSender(), "only rewardsDistribution");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Decimal} from "./Decimal.sol";

abstract contract DecimalERC20 {
    using Decimal for Decimal.decimal;

    mapping(address => uint256) private decimalMap;

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // INTERNAL functions
    //

    // CAUTION: do not input _from == _to s.t. this function will always fail
    function _transfer(
        IERC20 _token,
        address _to,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        Decimal.decimal memory balanceBefore = _balanceOf(_token, _to);
        uint256 roundedDownValue = _toUint(_token, _value);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(_token.transfer.selector, _to, roundedDownValue)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "DecimalERC20: transfer failed"
        );
        _validateBalance(_token, _to, roundedDownValue, balanceBefore);
    }

    function _transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        Decimal.decimal memory balanceBefore = _balanceOf(_token, _to);
        uint256 roundedDownValue = _toUint(_token, _value);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(_token.transferFrom.selector, _from, _to, roundedDownValue)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "DecimalERC20: transferFrom failed"
        );
        _validateBalance(_token, _to, roundedDownValue, balanceBefore);
    }

    function _approve(
        IERC20 _token,
        address _spender,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        // to be compatible with some erc20 tokens like USDT
        __approve(_token, _spender, Decimal.zero());
        __approve(_token, _spender, _value);
    }

    //
    // VIEW
    //
    function _allowance(
        IERC20 _token,
        address _owner,
        address _spender
    ) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.allowance(_owner, _spender));
    }

    function _balanceOf(IERC20 _token, address _owner)
        internal
        view
        returns (Decimal.decimal memory)
    {
        return _toDecimal(_token, _token.balanceOf(_owner));
    }

    function _totalSupply(IERC20 _token) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.totalSupply());
    }

    function _toDecimal(IERC20 _token, uint256 _number)
        internal
        view
        returns (Decimal.decimal memory)
    {
        uint256 tokenDecimals = _getTokenDecimals(address(_token));
        if (tokenDecimals >= 18) {
            return Decimal.decimal(_number / 10**(tokenDecimals - 18));
        }

        return Decimal.decimal(_number * 10**(uint256(18) - tokenDecimals));
    }

    function _toUint(IERC20 _token, Decimal.decimal memory _decimal)
        internal
        view
        returns (uint256)
    {
        uint256 tokenDecimals = _getTokenDecimals(address(_token));
        if (tokenDecimals >= 18) {
            return _decimal.toUint() * 10**(tokenDecimals - 18);
        }
        return _decimal.toUint() * 10**(uint256(18) - tokenDecimals);
    }

    function _getTokenDecimals(address _token) internal view returns (uint256) {
        uint256 tokenDecimals = decimalMap[_token];
        if (tokenDecimals == 0) {
            (bool success, bytes memory data) = _token.staticcall(
                abi.encodeWithSignature("decimals()")
            );
            require(success && data.length != 0, "DecimalERC20: get decimals failed");
            tokenDecimals = abi.decode(data, (uint256));
        }
        return tokenDecimals;
    }

    //
    // PRIVATE
    //
    function _updateDecimal(address _token) private {
        uint256 tokenDecimals = _getTokenDecimals(_token);
        if (decimalMap[_token] != tokenDecimals) {
            decimalMap[_token] = tokenDecimals;
        }
    }

    function __approve(
        IERC20 _token,
        address _spender,
        Decimal.decimal memory _value
    ) private {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(_token.approve.selector, _spender, _toUint(_token, _value))
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "DecimalERC20: approve failed"
        );
    }

    // To prevent from deflationary token, check receiver's balance is as expectation.
    function _validateBalance(
        IERC20 _token,
        address _to,
        uint256 _roundedDownValue,
        Decimal.decimal memory _balanceBefore
    ) private view {
        require(
            _balanceOf(_token, _to).cmp(
                _balanceBefore.addD(_toDecimal(_token, _roundedDownValue))
            ) == 0,
            "DecimalERC20: balance inconsistent"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;

// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;
pragma experimental ABIEncoderV2;

import {IfnxFiOwnableUpgrade} from "./utils/IfnxFiOwnableUpgrade.sol";
import {Decimal} from "./utils/Decimal.sol";
import {BlockContext} from "./utils/BlockContext.sol";
import {IMinter} from "./interface/IMinter.sol";
import {UUPSProxiable} from "./proxy/UUPSProxiable.sol";

contract SupplySchedule is IfnxFiOwnableUpgrade, BlockContext, UUPSProxiable {
    using Decimal for Decimal.decimal;

    //
    // CONSTANTS
    //

    // 4 years is 365 * 4 + 1 = 1,461 days
    // 7 days * 52 weeks * 4 years = 1,456 days. if we add one more week, total days will be 1,463 days.
    // it's over 4 years and closest to 4 years. 209 weeks = 4 * 52 + 1 weeks
    uint256 private constant SUPPLY_DECAY_PERIOD = 209 weeks;

    // Percentage growth of terminal supply per annum
    uint256 private constant TERMINAL_SUPPLY_EPOCH_RATE = 474970697307300; // 2.5% annual ~= 0.04749% weekly

    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//
    Decimal.decimal public inflationRate;
    Decimal.decimal public decayRate;

    uint256 public mintDuration; // default is 1 week
    uint256 public nextMintTime;
    uint256 public supplyDecayEndTime; // startSchedule time + 4 years

    IMinter private minter;

    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // FUNCTIONS
    //

    function initialize(
        IMinter _minter,
        uint256 _inflationRate,
        uint256 _decayRate,
        uint256 _mintDuration
    ) public initializer {
        minter = _minter;
        inflationRate = Decimal.decimal(_inflationRate);
        mintDuration = _mintDuration;
        decayRate = Decimal.decimal(_decayRate);
    }

    //
    // PUBLIC FUNCTIONS
    //

    function startSchedule() external onlyOwner {
        require(mintDuration > 0, "mint duration is 0");
        nextMintTime = _blockTimestamp() + mintDuration;
        supplyDecayEndTime = _blockTimestamp() + SUPPLY_DECAY_PERIOD;
    }

    function setDecayRate(Decimal.decimal memory _decayRate) public onlyOwner {
        decayRate = _decayRate;
    }

    function recordMintEvent() external {
        require(_msgSender() == address(minter), "!minter");
        //@audit - inflationRate will continue to decay even after supplyDecayEndTime, but I guess that should be fine? (@detoo)
        inflationRate = inflationRate.mulD(Decimal.one().subD(decayRate));
        nextMintTime = nextMintTime + mintDuration;
    }

    //
    // VIEW functions
    //
    function mintableSupply() external view returns (Decimal.decimal memory) {
        if (!isMintable()) {
            return Decimal.zero();
        }
        uint256 totalSupply = minter.getIfnxToken().totalSupply();
        if (_blockTimestamp() >= supplyDecayEndTime) {
            return Decimal.decimal(totalSupply).mulD(Decimal.decimal(TERMINAL_SUPPLY_EPOCH_RATE));
        }
        return Decimal.decimal(totalSupply).mulD(inflationRate);
    }

    function isMintable() public view returns (bool) {
        if (nextMintTime == 0) {
            return false;
        }
        return _blockTimestamp() >= nextMintTime;
    }

    function isStarted() external view returns (bool) {
        return nextMintTime > 0;
    }

    function proxiableUUID() public pure override returns (bytes32) {
        return keccak256("infinix-finance.SupplySchedule");
    }

    function updateCode(address newAddress) external override onlyOwner {
        _updateCodeAddress(newAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Decimal} from "../utils/Decimal.sol";

interface IMultiTokenRewardRecipient {
    function notifyTokenAmount(IERC20 _token, Decimal.decimal calldata _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;

import {UUPSUtils} from "./UUPSUtils.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @dev UUPS (Universal Upgradeable Proxy Standard) Proxiable contract.
 */
abstract contract UUPSProxiable is Initializable {
    /**
     * @dev Get current implementation code address.
     */
    function getCodeAddress() public view returns (address codeAddress) {
        return UUPSUtils.implementation();
    }

    function updateCode(address newAddress) external virtual;

    /**
     * @dev Proxiable UUID marker function.
     *      This would help to avoid wrong logic contract to be used for upgrading.
     */
    function proxiableUUID() public view virtual returns (bytes32);

    /**
     * @dev Update code address function.
     *      It is internal, so the derived contract could setup its own permission logic.
     */
    function _updateCodeAddress(address newAddress) internal {
        require(UUPSUtils.implementation() != address(0), "UUPSProxiable: not upgradable");
        require(
            proxiableUUID() == UUPSProxiable(newAddress).proxiableUUID(),
            "UUPSProxiable: not compatible logic"
        );
        UUPSUtils.setImplementation(newAddress);
        emit CodeUpdated(proxiableUUID(), newAddress);
    }

    event CodeUpdated(bytes32 uuid, address codeAddress);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;

/// @dev Implements simple fixed point math add, sub, mul and div operations.
/// @author Alberto Cuesta Cañada
library DecimalMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x + y;
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x - y;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (x * y) / unit(decimals);
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (x * unit(decimals)) / y;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;

import {SignedDecimalMath} from "./SignedDecimalMath.sol";
import {Decimal} from "./Decimal.sol";

library SignedDecimal {
    using SignedDecimalMath for int256;

    struct signedDecimal {
        int256 d;
    }

    function zero() internal pure returns (signedDecimal memory) {
        return signedDecimal(0);
    }

    function toInt(signedDecimal memory x) internal pure returns (int256) {
        return x.d;
    }

    function isNegative(signedDecimal memory x) internal pure returns (bool) {
        if (x.d < 0) {
            return true;
        }
        return false;
    }

    function abs(signedDecimal memory x) internal pure returns (Decimal.decimal memory) {
        Decimal.decimal memory t;
        if (x.d < 0) {
            t.d = uint256(0 - x.d);
        } else {
            t.d = uint256(x.d);
        }
        return t;
    }

    /// @dev add two decimals
    function addD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d + y.d;
        return t;
    }

    /// @dev subtract two decimals
    function subD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d - y.d;
        return t;
    }

    /// @dev multiple two decimals
    function mulD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a signedDecimal by a int256
    function mulScalar(signedDecimal memory x, int256 y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d * y;
        return t;
    }

    /// @dev divide two decimals
    function divD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a signedDecimal by a int256
    function divScalar(signedDecimal memory x, int256 y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d / y;
        return t;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;

/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library SignedDecimalMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(int256 x, int256 y) internal pure returns (int256) {
        return x + y;
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(int256 x, int256 y) internal pure returns (int256) {
        return x - y;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(int256 x, int256 y) internal pure returns (int256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * y) / (unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(int256 x, int256 y) internal pure returns (int256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return x * unit(decimals) /y;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// copy from openzeppelin Ownable, only modify how the owner transfer
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
contract IfnxFiOwnableUpgrade is Initializable, Ownable {
    uint256[50] private __gap;

    constructor() {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;
pragma experimental ABIEncoderV2;

import {Decimal} from "../utils/Decimal.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardRecipient {
    function notifyRewardAmount(Decimal.decimal calldata _amount) external;

    function token() external returns (IERC20);
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <=0.9.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Decimal} from "../utils/Decimal.sol";

interface IMinter {
    function mintReward() external;

    function mintForLoss(Decimal.decimal memory _amount) external;

    function getIfnxToken() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;

/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Shared Library
 */
library UUPSUtils {
    /**
     * @dev Implementation slot constant.
     * Using https://eips.ethereum.org/EIPS/eip-1967 standard
     * Storage slot 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
     * (obtained as bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)).
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Get implementation address.
    function implementation() internal view returns (address impl) {
        assembly {
            // solium-disable-line
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /// @dev Set new implementation address.
    function setImplementation(address codeAddress) internal {
        assembly {
            // solium-disable-line
            sstore(_IMPLEMENTATION_SLOT, codeAddress)
        }
    }
}