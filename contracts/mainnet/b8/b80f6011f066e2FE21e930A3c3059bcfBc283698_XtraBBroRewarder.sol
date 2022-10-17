pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT


import { IERC20Mintable } from "./interfaces/IERC20Mintable.sol";
import { IStakingV1 } from "./interfaces/IStakingV1.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract XtraBBroRewarder is Ownable {
    IERC20Mintable public bBroToken;
    IStakingV1 public staking;

    uint256 public couldBeClaimedUntil;
    uint256 public minUnstakingPeriodForXtraReward;

    uint256 public bBroRewardsBaseIndex; // .0000 number
    uint16 public bBroRewardsXtraMultiplier;
    uint256 public amountOfEpochsForXtraReward;

    uint256 public terraMigratorExtraPerc; // .00 number

    mapping(address => bool) private claims;
    mapping(address => bool) private terraMigratorsWhitelist;

    constructor(
        address bBroToken_,
        address staking_,
        uint256 couldBeClaimedUntil_,
        uint256 minUnstakingPeriodForXtraReward_,
        uint256 bBroRewardsBaseIndex_,
        uint16 bBroRewardsXtraMultiplier_,
        uint256 amountOfEpochsForXtraReward_,
        uint256 terraMigratorExtraPerc_
    ) {
        bBroToken = IERC20Mintable(bBroToken_);
        staking = IStakingV1(staking_);
        couldBeClaimedUntil = couldBeClaimedUntil_;
        minUnstakingPeriodForXtraReward = minUnstakingPeriodForXtraReward_;
        bBroRewardsBaseIndex = bBroRewardsBaseIndex_;
        bBroRewardsXtraMultiplier = bBroRewardsXtraMultiplier_;
        amountOfEpochsForXtraReward = amountOfEpochsForXtraReward_;
        terraMigratorExtraPerc = 100 + terraMigratorExtraPerc_;
    }

    modifier onlyWhenEventIsNotOver() {
        require(
            // solhint-disable-next-line not-rely-on-time
            block.timestamp <= couldBeClaimedUntil,
            "Xtra rewards event is over"
        );
        _;
    }

    modifier onlyWhenNotClaimed() {
        require(!claims[_msgSender()], "Xtra reward already claimed");
        _;
    }

    function claim() external onlyWhenEventIsNotOver onlyWhenNotClaimed {
        uint256 xtraBBroReward = _calculateXtraBBroReward(_msgSender());
        require(xtraBBroReward > 0, "Nothing to claim");

        claims[_msgSender()] = true;
        bBroToken.mint(_msgSender(), xtraBBroReward);
    }

    function batchWhitelistTerraMigrators(address[] calldata _accounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            terraMigratorsWhitelist[_accounts[i]] = true;
        }
    }

    function _calculateXtraBBroReward(address _staker)
        private
        view
        returns (uint256)
    {
        IStakingV1.Staker memory staker = staking.getStakerInfo(_staker);

        uint256 bbroXtraReward = 0;
        for (uint256 i = 0; i < staker.unstakingPeriods.length; i++) {
            if (
                staker.unstakingPeriods[i].unstakingPeriod >=
                minUnstakingPeriodForXtraReward
            ) {
                bbroXtraReward += _computeBBroReward(
                    staker.unstakingPeriods[i].rewardsGeneratingAmount +
                        staker.unstakingPeriods[i].lockedAmount,
                    staker.unstakingPeriods[i].unstakingPeriod
                );
            }
        }

        for (uint256 i = 0; i < staker.withdrawals.length; i++) {
            if (
                staker.withdrawals[i].unstakingPeriod >=
                minUnstakingPeriodForXtraReward
            ) {
                bbroXtraReward += _computeBBroReward(
                    staker.withdrawals[i].rewardsGeneratingAmount +
                        staker.withdrawals[i].lockedAmount,
                    staker.withdrawals[i].unstakingPeriod
                );
            }
        }

        if (terraMigratorsWhitelist[_staker]) {
            bbroXtraReward = (bbroXtraReward * terraMigratorExtraPerc) / 100;
        }

        return bbroXtraReward;
    }

    function _computeBBroReward(uint256 _amount, uint256 _unstakingPeriod)
        private
        view
        returns (uint256)
    {
        uint256 bBroEmissionRate = bBroRewardsBaseIndex +
            bBroRewardsXtraMultiplier *
            (((_unstakingPeriod * _unstakingPeriod) * 1e18) / 1000000);
        uint256 bBroPerEpochReward = ((bBroEmissionRate * _amount) / 365) /
            1e18;

        return bBroPerEpochReward * amountOfEpochsForXtraReward;
    }

    function availableBBroAmountToClaim(address _account)
        public
        view
        returns (uint256)
    {
        return _calculateXtraBBroReward(_account);
    }

    function isClaimed(address _account) public view returns (bool) {
        return claims[_account];
    }

    function isWhitelisted(address _account) public view returns (bool) {
        return terraMigratorsWhitelist[_account];
    }
}

pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT


interface IERC20Mintable {
    function mint(address _account, uint256 _amount) external;

    function isWhitelisted(address _account) external view returns (bool);
}

pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT


/// @title The interface for the Staking V1 contract
/// @notice The Staking Contract contains the logic for BRO Token staking and reward distribution
interface IStakingV1 {
    /// @notice Emitted when compound amount is zero
    error NothingToCompound();

    /// @notice Emitted when withdraw amount is zero
    error NothingToWithdraw();

    /// @notice Emitted when rewards claim amount($BRO or $bBRO) is zero
    error NothingToClaim();

    /// @notice Emitted when configured limit for unstaking periods per staker was reached
    error UnstakingPeriodsLimitWasReached();

    /// @notice Emitted when unstaking period was not found
    /// @param unstakingPeriod specified unstaking period to search for
    error UnstakingPeriodNotFound(uint256 unstakingPeriod);

    /// @notice Emitted when configured limit for withdrawals per unstaking period was reached
    error WithdrawalsLimitWasReached();

    /// @notice Emitted when withdrawal was not found
    /// @param amount specified withdrawal amount
    /// @param unstakingPeriod specified unstaking period
    error WithdrawalNotFound(uint256 amount, uint256 unstakingPeriod);

    /// @notice Emitted when staker staked some amount by specified unstaking period
    /// @param staker staker's address
    /// @param amount staked amount
    /// @param unstakingPeriod selected unstaking period
    event Staked(
        address indexed staker,
        uint256 amount,
        uint256 unstakingPeriod
    );

    /// @notice Emitted when stake was performed via one of the protocol members
    /// @param staker staker's address
    /// @param amount staked amount
    /// @param unstakingPeriod selected unstaking period
    event ProtocolMemberStaked(
        address indexed staker,
        uint256 amount,
        uint256 unstakingPeriod
    );
    /// @notice Emitted when staker compunded his $BRO rewards
    /// @param staker staker's address
    /// @param compoundAmount compounded amount
    /// @param unstakingPeriod selected unstaking period where to deposit compounded tokens
    event Compounded(
        address indexed staker,
        uint256 compoundAmount,
        uint256 unstakingPeriod
    );

    /// @notice Emitted when staker unstaked some amount of tokens from selected unstaking period
    /// @param staker staker's address
    /// @param amount unstaked amount
    /// @param unstakingPeriod selected unstaking period from where to deduct specified amount
    event Unstaked(
        address indexed staker,
        uint256 amount,
        uint256 unstakingPeriod
    );

    /// @notice Emitted when staker withdrew his token after unstaking period was expired
    /// @param staker staker's address
    /// @param amount withdrawn amount
    event Withdrawn(address indexed staker, uint256 amount);

    /// @notice Emitted when staker cancelled withdrawal
    /// @param staker staker's address
    /// @param compoundAmount amount that was moved from withdrawal to unstaking period
    /// @param unstakingPeriod specified unstaking period to find withdrawal
    event WithdrawalCanceled(
        address indexed staker,
        uint256 compoundAmount,
        uint256 unstakingPeriod
    );

    /// @notice Emitted when staker claimed his $BRO rewards
    /// @param staker staker's address
    /// @param amount claimed $BRO amount
    event BroRewardsClaimed(address indexed staker, uint256 amount);

    /// @notice Emitted when staked claimed his $bBRO rewards
    /// @param staker staker's address
    /// @param amount claimed $bBRO amount
    event BBroRewardsClaimed(address indexed staker, uint256 amount);

    struct InitializeParams {
        // distributor address
        address distributor_;
        // epoch manager address
        address epochManager_;
        // $BRO token address
        address broToken_;
        // $bBRO token address
        address bBroToken_;
        // list of protocol members
        address[] protocolMembers_;
        // min amount of BRO that can be staked per tx
        uint256 minBroStakeAmount_;
        // min amount of epochs for unstaking period
        uint256 minUnstakingPeriod_;
        // max amount of epochs for unstaking period
        uint256 maxUnstakingPeriod_;
        // max amount of unstaking periods the staker can have
        // this check is omitted when staking via community bonding
        uint8 maxUnstakingPeriodsPerStaker_;
        // max amount of withdrawals per unstaking period the staker can have
        // 5 unstaking periods = 25 withdrawals max
        uint8 maxWithdrawalsPerUnstakingPeriod_;
        // variable for calculating rewards generating amount
        // that will generate $BRO staking rewards
        uint256 rewardGeneratingAmountBaseIndex_;
        // percentage that is used to decrease
        // withdrawal rewards generating $BRO amount
        uint256 withdrawalAmountReducePerc_;
        // percentage that is used to decrease
        // $bBRO rewards for unstaked amounts
        uint256 withdrawnBBroRewardReducePerc_;
        // variable for calculating $bBRO rewards
        uint256 bBroRewardsBaseIndex_;
        // variable for calculating $bBRO rewards
        uint16 bBroRewardsXtraMultiplier_;
    }

    struct Withdrawal {
        // $BRO rewards generating amount
        uint256 rewardsGeneratingAmount;
        // locked amount that doesn't generate $BRO rewards
        uint256 lockedAmount;
        // timestamp when unstaking period started
        uint256 withdrewAt;
        // unstaking period in epochs to wait before token release
        uint256 unstakingPeriod;
    }

    struct UnstakingPeriod {
        // $BRO rewards generating amount
        uint256 rewardsGeneratingAmount;
        // locked amount that doesn't generate $BRO rewards
        uint256 lockedAmount;
        // unstaking period in epochs to wait before token release
        uint256 unstakingPeriod;
    }

    struct Staker {
        // $BRO rewards index that is used to compute staker share
        uint256 broRewardIndex;
        // unclaimed $BRO rewards
        uint256 pendingBroReward;
        // unclaimed $bBRO rewards
        uint256 pendingBBroReward;
        // last timestamp when rewards was claimed
        uint256 lastRewardsClaimTimestamp;
        // stakers unstaking periods
        UnstakingPeriod[] unstakingPeriods;
        // stakers withdrawals
        Withdrawal[] withdrawals;
    }

    /// @notice Stakes specified amount of $BRO tokens
    /// @param _amount amount of $BRO tokens to stake
    /// @param _unstakingPeriod specified unstaking period
    function stake(uint256 _amount, uint256 _unstakingPeriod) external;

    /// @notice Stake specified amount of $BRO tokens via one of the protocol members
    /// @param _stakerAddress staker's address
    /// @param _amount bonded amount that will be staked
    /// @param _unstakingPeriod specified unstaking period
    function protocolMemberStake(
        address _stakerAddress,
        uint256 _amount,
        uint256 _unstakingPeriod
    ) external;

    /// @notice Compounds staker pending $BRO rewards and deposits them to specified unstaking period
    /// @param _unstakingPeriod specified unstaking period
    function compound(uint256 _unstakingPeriod) external;

    /// @notice Increases selected unstaking period
    /// @dev If increase version of unstaking period already exists the contract will
    /// move all the funds there and remove the old one
    /// @param _currentUnstakingPeriod unstaking period to increase
    /// @param _increasedUnstakingPeriod increased unstaking period
    function increaseUnstakingPeriod(
        uint256 _currentUnstakingPeriod,
        uint256 _increasedUnstakingPeriod
    ) external;

    /// @notice Unstakes specified amount of $BRO tokens.
    /// Unstaking period starts at this moment of time.
    /// @param _amount specified amount to unstake
    /// @param _unstakingPeriod specified unstaking period
    function unstake(uint256 _amount, uint256 _unstakingPeriod) external;

    /// @notice Unstakes specified amount of $BRO tokens via one of the protocol members.
    /// Unstaking period starts at this moment of time.
    /// @param _stakerAddress staker's address
    /// @param _amount specified amount to unstake
    /// @param _unstakingPeriod specified unstaking period
    function protocolMemberUnstake(
        address _stakerAddress,
        uint256 _amount,
        uint256 _unstakingPeriod
    ) external;

    /// @notice Removes all expired withdrawals and transferes unstaked amount to the staker
    function withdraw() external;

    /// @notice Cancels withdrawal. Moves withdrawn funds back to the unstaking period
    /// @param _amount specified amount to find withdrawal
    /// @param _unstakingPeriod specified unstaking period to find withdrawal
    function cancelUnstaking(uint256 _amount, uint256 _unstakingPeriod)
        external;

    /// @notice Claimes staker rewards and transferes them to the staker wallet
    /// @param _claimBro defines either to claim $BRO rewards or not
    /// @param _claimBBro defines either to claim $bBRO rewards or not
    /// @return amount of claimed $BRO and $bBRO tokens
    function claimRewards(bool _claimBro, bool _claimBBro)
        external
        returns (uint256, uint256);

    /// @notice Returns staker info
    /// @param _stakerAddress staker's address to look for
    function getStakerInfo(address _stakerAddress)
        external
        view
        returns (Staker memory);

    /// @notice Returns total amount of rewards generating $BRO by staker address
    /// @param _stakerAddress staker's address to look for
    function totalStakerRewardsGeneratingBro(address _stakerAddress)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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