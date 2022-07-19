// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILotteryGame.sol";
import "../interfaces/IKeeperRegistry.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "./ConvertAvax.sol";

/* solhint-disable var-name-mixedcase */
contract LotteryGame is
    ILotteryGame,
    Ownable,
    ConvertAvax,
    ReentrancyGuard,
    VRFConsumerBaseV2,
    KeeperCompatible
{
    uint256 public constant HUNDRED_PERCENT_WITH_PRECISONS = 10_000;
    uint256 public constant FIFTY_PERCENT_WITH_PRECISONS = 5_000;
    uint256 public constant WINNERS_LIMIT = 10;
    address public constant VRF_COORDINATOR =
        0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
    // address public constant LINK = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address public constant KEEPERS_REGISTRY =
        0x409CF388DaB66275dA3e44005D182c12EeAa12A0;

    uint256 private gameDuration;
    uint256 private countOfWinners;
    uint256 public participationFee;
    uint256 public callerFeePercents;

    uint32 private VRFGasLimit;
    bool private isDateTimeRequired;
    address private callerFeeCollector;
    uint256[] private winnersPercentages;
    bool private isGameStarted;
    bool private isWinnersRequired;

    ChainlinkParameters private chainlinkSettings;
    VRFCoordinatorV2Interface private immutable COORDINATOR;
    ContractsRegistry private contracts;
    /// @notice struct to pending params
    Pending public pending;

    mapping(uint256 => GameOptionsInfo) private gamesRoundInfo;

    modifier onlyKeepers() {
        require(msg.sender == KEEPERS_REGISTRY, "NOT_KEEPERS_REGISTRY");
        _;
    }

    constructor(
        uint256 participationFee_,
        uint256 callerFeePercents_,
        ChainlinkParameters memory chainlinkParam,
        IGovernance governance_,
        address link_
    ) VRFConsumerBaseV2(VRF_COORDINATOR) ConvertAvax(link_) {
        COORDINATOR = VRFCoordinatorV2Interface(VRF_COORDINATOR);
        chainlinkSettings.keyHash = chainlinkParam.keyHash;
        chainlinkSettings.requestConfirmations = chainlinkParam
            .requestConfirmations;
        _createSubscription();

        callerFeePercents = callerFeePercents_;
        participationFee = participationFee_;

        //TODO: add timelocks based on the requirements
        isDateTimeRequired = true;
        countOfWinners = 1;
        winnersPercentages.push(HUNDRED_PERCENT_WITH_PRECISONS);

        pending.participationFee = participationFee_;
        pending.countOfWinners = 1;
        pending.winnersPercentages = winnersPercentages;
        pending.callerFeePercents = callerFeePercents_;

        contracts.governance = governance_;
    }

    function getRoundInfo(uint256 lotteryId)
        external
        view
        returns (GameOptionsInfo memory)
    {
        return gamesRoundInfo[lotteryId];
    }

    function setKeeperId(uint256 id_) external onlyOwner{
        chainlinkSettings.keeperId = id_;
    }

    function setDateTimeAddress(address dateTime_) external onlyOwner {
        require(dateTime_ != address(0), "ZERO_ADDRESS");
        contracts.dateTime = DateTime(dateTime_);
    }

    function setTimelock(DateTime.TimelockForLotteryGame memory timelock)
        external
        onlyOwner
    {
        contracts.dateTime.setTimelock(address(this), timelock);
    }

    function setLotteryToken(address _lotteryToken) external onlyOwner {
        require(_lotteryToken != address(0), "ZERO_ADDRESS");
        contracts.lotteryToken = ILotteryToken(_lotteryToken);
    }

    function setParticipationFee(uint256 _participationFee) public onlyOwner {
        require(_participationFee != 0, "ZERO_AMOUNT");
        // Entry fee - limit the growth rate by 25 percent
        require(
            _participationFee <= participationFee + (participationFee * 2_500) / 10_000,
            "INVALID_ENTRY_FEE"
        );
        participationFee = _participationFee;
    }

    function setGameCallerFeePercents(uint256 _amount) public onlyOwner {
        require(
            _amount <= FIFTY_PERCENT_WITH_PRECISONS,
            "Marketing fee cannot be bigger than 50%"
        );
        pending.callerFeePercents = _amount;
    }

    function switchTimelockToDateDuration(uint256 _gameDuration)
        public
        onlyOwner
    {
        require(isDateTimeRequired, "TIMELOCK_IN_DURATION_IS_ACTIVE");
        isDateTimeRequired = !isDateTimeRequired;
        _setGameDuration(_gameDuration);
    }

    function setGameDuration(uint256 _gameDuration) public onlyOwner {
        require(!isDateTimeRequired, "DATE_TIME_TIMELOCK_IS_ACTIVE");
        _setGameDuration(_gameDuration);
    }

    function setWinnersNumber(
        uint256 countOfWinners_,
        uint256[] calldata winnersPercentages_
    ) external onlyOwner {
        require(
            countOfWinners_ != 0 && countOfWinners_ <= WINNERS_LIMIT,
            "LIMIT_UNDER"
        );
        require(
            winnersPercentages_.length == countOfWinners_,
            "INCORRECT_PERCENTS_LENGTH"
        );

        //check if sum of percentage is 100%
        uint256 totalPercentsSum;
        for (uint256 i = 0; i < countOfWinners_; i++) {
            totalPercentsSum += winnersPercentages_[i];
        }
        require(
            totalPercentsSum == HUNDRED_PERCENT_WITH_PRECISONS,
            "INCORRECT_PERCENTS_SUM"
        );
        pending.countOfWinners = countOfWinners_;
        pending.winnersPercentages = winnersPercentages_;
    }

    function setRewardPool(address _rewardPool) external onlyOwner {
        require(_rewardPool != address(0), "ZERO_ADDRESS");
        contracts.lotteryToken.setRewardPool(_rewardPool);
    }

    function lockTransfer() public override onlyOwner {
        contracts.lotteryToken.lockTransfer();
    }

    function unlockTransfer() public override onlyOwner {
        contracts.lotteryToken.unlockTransfer();
    }

    function startGame(uint32 VRFGasLimit_)
        external
        payable
        override
        nonReentrant
    {

        ILotteryToken.Lottery memory lastLotteryGame = contracts
            .lotteryToken
            .lastLottery();

        if (lastLotteryGame.id > 0) {
            if (isDateTimeRequired) {
                require(_isTimelockValid(), "The game is not ready to start!");
            } else {
                require(
                    block.timestamp >=
                        lastLotteryGame.finishedAt + gameDuration,
                    "The game is not ready to start!"
                );
            }
        }


        swapAvaxToLink();

        uint256 vrfRequired = 0.15 ether;
        uint96 keepersRequires = 5 ether;

        require(vrfRequired + keepersRequires<= IERC20(LINK).balanceOf(address(this)));
        
        LinkTokenInterface(LINK).transferAndCall(
            address(COORDINATOR),
            vrfRequired,
            abi.encode(chainlinkSettings.subscriptionId)
        );

        IKeeperRegistry(KEEPERS_REGISTRY).addFunds(chainlinkSettings.keeperId, keepersRequires);

        ILotteryToken.Lottery memory startedLotteryGame = contracts
            .lotteryToken
            .startLottery(participationFee);

        callerFeeCollector = msg.sender;
        VRFGasLimit = VRFGasLimit_;
        emit GameStarted(startedLotteryGame.id, block.timestamp);

        isGameStarted = true;
    }

    function checkUpkeep(
        bytes calldata /*checkData*/
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory checkedData)
    {
        uint256 ticketPrice = participationFee;
        uint256 countOfParticipants = contracts
            .lotteryToken
            .participantsCount();
        address[] memory eligibleParticipants = new address[](
            countOfParticipants
        );
        uint256 countOfEligibleUsers;
        (
            address[] memory participants,
            uint256[] memory participantsBalances
        ) = contracts.lotteryToken.participantsBalances(0, countOfParticipants);

        for (uint256 i; i < participants.length; i++) {
            bool isWhitelisted = contracts.lotteryToken.isWhitelisted(
                participants[i]
            );
            if (participantsBalances[i] >= ticketPrice && !isWhitelisted) {
                eligibleParticipants[countOfEligibleUsers] = participants[i];
                countOfEligibleUsers++;
            }
        }

        if (isGameStarted) {
            checkedData = abi.encode(countOfEligibleUsers);
        }
        if (isWinnersRequired) {
            address[] memory winners = new address[](countOfWinners);

            ILotteryToken.Lottery memory lastLotteryGame = contracts
                .lotteryToken
                .lastLottery();
            require(lastLotteryGame.isActive, "Game is not active");

            uint256 id = lastLotteryGame.id;

            // get winners addresses beased on winners indexes
            for (uint256 i; i < gamesRoundInfo[id].winnersIndexes.length; i++) {
                winners[i] = eligibleParticipants[
                    gamesRoundInfo[id].winnersIndexes[i]
                ];
            }

            checkedData = abi.encode(winners);
        }

        upkeepNeeded = isGameStarted || isWinnersRequired;
    }

    function performUpkeep(bytes calldata performData)
        external
        override
        onlyKeepers
    {
        if (isGameStarted) {
            isGameStarted = false;
            uint256 validParticipantsCount = abi.decode(performData, (uint256));
            ILotteryToken.Lottery memory lastLotteryGame = contracts
                .lotteryToken
                .lastLottery();

            require(lastLotteryGame.isActive, "Game is not active");

            gamesRoundInfo[lastLotteryGame.id]
                .countOfParticipants = validParticipantsCount;
            _callChainlinkVRFForWinnersIndexes();
        }
        if (isWinnersRequired) {
            isWinnersRequired = false;

            _handleChainlinkWinnersResponce(performData);
        }
    }

    function cancelSubscription(address to_) external onlyOwner {
        COORDINATOR.cancelSubscription(chainlinkSettings.subscriptionId, to_);
        chainlinkSettings.subscriptionId = 0;
    }

    // TODO: only for testing purpose, delete before release
    function topUpSubscription(uint256 amount) external onlyOwner {
        LinkTokenInterface(LINK).transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(chainlinkSettings.subscriptionId)
        );
    }

    // function restartChainlink(uint32 VRFGasLimit_)
    //     public
    //     payable
    //     override
    //     nonReentrant
    // {
    //     callerFeeCollector = msg.sender;
    //     VRFGasLimit = VRFGasLimit_;

    //     ILotteryToken.Lottery memory lastLotteryGame = contracts
    //         .lotteryToken
    //         .lastLottery();

    //     require(
    //         lastLotteryGame.finishedAt == 0,
    //         "Can be invoked only when the last game not finished"
    //     );
    //     // generate merkle root
    //     _callChainlinkForMerkleRoot();
    // }

    function _handleChainlinkWinnersResponce(bytes memory bytesData) private {
        ILotteryToken.Lottery memory lastLotteryGame = contracts
            .lotteryToken
            .lastLottery();

        require(lastLotteryGame.isActive, "Game is not active");
        uint256 id = lastLotteryGame.id;

        //decode
        address[] memory winners = abi.decode(bytesData, (address[]));
        uint256 eligibleParticipants = gamesRoundInfo[id].countOfParticipants;

        uint256 totalWinningPrize = lastLotteryGame.participationFee *
            eligibleParticipants;
        uint256 callerFee = _calculatePercents(
            callerFeePercents,
            totalWinningPrize
        );

        // reward and governance fee
        uint256 governanceFee = contracts.governance.governanceReward();
        uint256 communityFee = contracts.governance.communityReward();
        uint256 governanceReward = _calculatePercents(
            governanceFee,
            totalWinningPrize
        );

        uint256 communityReward = _calculatePercents(
            communityFee,
            totalWinningPrize
        );
        uint256 totalReward = governanceReward + communityReward;
        uint256 totalWinningPrizeExludingFees = totalWinningPrize -
            callerFee -
            totalReward;

        uint256[] memory winningPrizeExludingFees = new uint256[](
            countOfWinners
        );

        //calculate winning amount for each winner based on his percent portion
        for (uint256 i = 0; i < countOfWinners; i++) {
            winningPrizeExludingFees[i] = _calculatePercents(
                winnersPercentages[i],
                totalWinningPrizeExludingFees
            );
        }

        {
            ILotteryToken.Lottery memory finishedLotteryGame = contracts
                .lotteryToken
                .finishLottery(
                    eligibleParticipants,
                    winners,
                    callerFeeCollector,
                    winningPrizeExludingFees,
                    callerFee,
                    totalReward
                );

            _distributeReward(
                finishedLotteryGame.finishedAt,
                communityReward,
                governanceReward
            );
            contracts.lotteryToken.unlockTransfer();
            emit GameFinished(
                finishedLotteryGame.id,
                finishedLotteryGame.startedAt,
                finishedLotteryGame.finishedAt,
                finishedLotteryGame.participants,
                finishedLotteryGame.winners,
                finishedLotteryGame.participationFee,
                finishedLotteryGame.winningPrize,
                finishedLotteryGame.rewards,
                finishedLotteryGame.rewardPool
            );
        }

        // change pending info if required
        if (pending.participationFee != participationFee)
            participationFee = pending.participationFee;

        if (pending.countOfWinners != countOfWinners)
            countOfWinners = pending.countOfWinners;

        if (
            keccak256(abi.encodePacked(pending.winnersPercentages)) !=
            keccak256(abi.encodePacked(winnersPercentages))
        ) winnersPercentages = pending.winnersPercentages;

        if (pending.callerFeePercents != callerFeePercents)
            callerFeePercents = pending.callerFeePercents;
    }

    function _callChainlinkVRFForWinnersIndexes() private {
        COORDINATOR.requestRandomWords(
            chainlinkSettings.keyHash,
            chainlinkSettings.subscriptionId,
            chainlinkSettings.requestConfirmations,
            VRFGasLimit,
            uint32(countOfWinners)
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        ILotteryToken.Lottery memory lastLotteryGame = contracts
            .lotteryToken
            .lastLottery();

        require(lastLotteryGame.isActive, "Game is not active");
        uint256 id = lastLotteryGame.id;
        uint256 countOfParticipants = gamesRoundInfo[id].countOfParticipants;

        uint256[] memory indexes = new uint256[](countOfWinners);
        for (uint256 i = 0; i < countOfWinners; i++) {
            indexes[i] = randomWords[i] % countOfParticipants;
        }
        gamesRoundInfo[id].winnersIndexes = indexes;

        isWinnersRequired = true;
    }

    function _createSubscription() private {
        chainlinkSettings.subscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(
            chainlinkSettings.subscriptionId,
            address(this)
        );
    }

    function _fundSubscription(uint256 amount) private {
        LinkTokenInterface(LINK).transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(chainlinkSettings.subscriptionId)
        );
    }

    function _distributeReward(
        uint256 timeOfGameFinish,
        uint256 communityReward,
        uint256 governanceReward
    ) internal {
        address rewardPool = contracts.lotteryToken.rewardPool();
        // replenish governance pool
        IGovernancePool(rewardPool).replenishPool(governanceReward, 0);
        // add new community reward distribution
        IRewardDistribution.CommunityReward memory distributionInfo;
        distributionInfo.timeOfGameFinish = timeOfGameFinish;
        distributionInfo.totalUsersHoldings = IERC20(
            address(contracts.lotteryToken)
        ).totalSupply();
        distributionInfo.amountForDistribution = communityReward;
        distributionInfo.isMainLottoToken = true;
        IRewardDistribution(rewardPool).addDistribution(distributionInfo);
    }

    function _isTimelockValid() private view returns (bool) {
        uint16 dayOfWeek = contracts.dateTime.getWeekday(block.timestamp);
        DateTime.TimelockForLotteryGame memory timelock = contracts
            .dateTime
            .getTimelock(address(this));
        for (uint256 i; i < timelock.daysUnlocked.length; i++) {
            if (dayOfWeek == timelock.daysUnlocked[i]) {
                uint8 day = contracts.dateTime.getDay(block.timestamp) + 1;

                uint8 month = contracts.dateTime.getMonth(block.timestamp);
                uint16 year = contracts.dateTime.getYear(block.timestamp);
                uint256 startTimestamp = contracts.dateTime.toTimestamp(
                    year,
                    month,
                    day,
                    timelock.hoursStartUnlock[i]
                );
                if (
                    block.timestamp >= startTimestamp &&
                    block.timestamp <=
                    startTimestamp + timelock.unlockDurations[i] * 3600
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    function _setGameDuration(uint256 _gameDuration) private {
        gameDuration = _gameDuration;
    }

    function _calculatePercents(uint256 percent, uint256 amount)
        private
        pure
        returns (uint256)
    {
        return (amount * percent) / HUNDRED_PERCENT_WITH_PRECISONS;
    }

    function toAsciiString(address _addr)
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(
                uint8(uint256(uint160(_addr)) / (2**(8 * (19 - i))))
            );
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i + 2] = char(hi);
            s[2 * i + 3] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
pragma solidity 0.8.9;

import "../interfaces/ILotteryToken.sol";
import "../interfaces/IRewardDistribution.sol";
import "../interfaces/IGovernancePool.sol";
import "../lotteryGame/DateTime.sol";

interface IGovernance {
    function governanceReward() external returns (uint256);
    function communityReward() external returns (uint256);
}

/* solhint-disable var-name-mixedcase */
interface ILotteryGame {
    /// @notice Define struct of the timelock
    /// @param daysUnlocked number of day week
    /// @param hoursStartUnlock hour when the timelock unlocked
    /// @param unlockDurations duration of the timelock is unlocking
    struct TimelockForLotteryGame {
        uint256[] daysUnlocked;
        uint256[] hoursStartUnlock;
        uint256[] unlockDurations;
    }

    struct GameOptionsInfo {
        uint256 countOfParticipants;
        uint256[] winnersIndexes;
    }

    /// @notice store chainlink parameters info
    /// @param subscriptionId subscription id for VRF
    /// @param keeperId subscription id for VRF
    /// @param keyHash The gas lane to use, which specifies the maximum gas price to bump to while VRF
    /// @param requestConfirmations amount of confiramtions for VRF
    struct ChainlinkParameters {
        uint64 subscriptionId;
        uint256 keeperId;
        bytes32 keyHash;
        uint16 requestConfirmations;
    }

    struct ContractsRegistry {
        IGovernance governance;
        DateTime dateTime;
        ILotteryToken lotteryToken;
    }

    /// @notice store all chenging params for the game
    /// @dev this pending params are setted to the game from the next round
    /// @param participationFee  participation fee for the game
    /// @param countOfWinners count of winners
    /// @param callerFeePercents caller fee percntages
    /// @param winnersPercentages array of percenages for winners
    struct Pending {
        uint256 participationFee;
        uint256 countOfWinners;
        uint256 callerFeePercents;
        uint256[] winnersPercentages;
    }

    event MarketingFeePaid(address feeCollector, uint256 amount);
    event GameStarted(uint256 id, uint256 startedAt);
    event GameFinished(
        uint256 id,
        uint256 startedAt,
        uint256 finishedAt,
        uint256 participants,
        address[] winners,
        uint256 participationFee,
        uint256[] winningPrize,
        uint256 rewards,
        address rewardPool
    );
    event RequestFulfilled(bytes32 indexed requestId, bytes indexed data);

    /// @notice disable transfers
    function lockTransfer() external;

    /// @notice enable transfers
    function unlockTransfer() external;

    /// @dev start game
    /// @param VRFGasLimit_ gas limit for VRF request
    function startGame(uint32 VRFGasLimit_) external payable;

    /// @dev restart game in case callbcack was not returned
    /// @param VRFGasLimit_ gas limit for VRF request
    // function restartChainlink(uint32 VRFGasLimit_) external payable;
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

interface IKeeperRegistry {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (
      uint256 id
    );
  function performUpkeep(
    uint256 id,
    bytes calldata performData
  ) external returns (
      bool success
    );
  function cancelUpkeep(
    uint256 id
  ) external;
  function addFunds(
    uint256 id,
    uint96 amount
  ) external;

  function getUpkeep(uint256 id)
    external view returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber
    );
  function getUpkeepCount()
    external view returns (uint256);
  function getCanceledUpkeepList()
    external view returns (uint256[] memory);
  function getKeeperList()
    external view returns (address[] memory);
  function getKeeperInfo(address query)
    external view returns (
      address payee,
      bool active,
      uint96 balance
    );
  function getConfig()
    external view returns (
      uint32 paymentPremiumPPB,
      uint24 checkFrequencyBlocks,
      uint32 checkGasLimit,
      uint24 stalenessSeconds,
      uint16 gasCeilingMultiplier,
      uint256 fallbackGasPrice,
      uint256 fallbackLinkPrice
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/pangolin/IPangolinRouter.sol";

contract ConvertAvax{
    IPangolinRouter private constant PANGOLIN_ROUTER = IPangolinRouter(0x3705aBF712ccD4fc56Ee76f0BD3009FD4013ad75);
    address internal immutable LINK;
    address internal immutable WAVAX;

    event Swap(uint256 indexed amountIn, uint256 amountMin, address[] path);
    constructor(address link_){
        WAVAX = PANGOLIN_ROUTER.WAVAX();
        LINK = link_;
    }

    function swapAvaxToLink() internal{
        uint256 amountIn = msg.value;
        require(amountIn != 0, "ZERO_AMOUNT");
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = LINK;
        uint256 amountOutMin = getAmountOutMin(path, amountIn);
        PANGOLIN_ROUTER.swapExactAVAXForTokens{value: amountIn}(amountOutMin, path, address(this), block.timestamp + 1 hours);
    }


    function getAmountOutMin(address[] memory path_, uint256 amountIn_) private view returns (uint256) {        
        uint256[] memory amountOutMins = PANGOLIN_ROUTER.getAmountsOut(amountIn_, path_);
        return amountOutMins[path_.length - 1];  
    } 

}


/// WBTC = 0x5d870A421650C4f39aE3f5eCB10cBEEd36e6dF50
/// PartyROuter = 0x3705aBF712ccD4fc56Ee76f0BD3009FD4013ad75
/// PagolinRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

// SPDX-License-Identifier: MIT

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
pragma solidity 0.8.9;

/// @title Defined interface for LotteryToken contract
interface ILotteryToken {
    ///@notice struct to store detailed info about the lottery
    struct Lottery {
        uint256 id;
        uint256 participationFee;
        uint256 startedAt;
        uint256 finishedAt;
        uint256 participants;
        address[] winners;
        uint256 epochId;
        uint256[] winningPrize;
        uint256 rewards;
        address rewardPool;
        bool isActive;
    }

    ///@notice struct to store info about fees and participants in each epoch
    struct Epoch {
        uint256 totalFees;
        uint256 minParticipationFee;
        uint256 firstLotteryId;
        uint256 lastLotteryId;
    }

    ///@notice struct to store info about user balance based on the last game id interaction
    struct UserBalance {
        uint256 lastGameId;
        uint256 balance;
        uint256 at;
    }

    /// @notice A checkpoint for marking historical number of votes from a given block timestamp
    struct Snapshot {
        uint256 blockTimestamp;
        uint256 votes;
    }

    /// @dev store info about whitelisted address to dismiss auto-charge lotto tokens from this address
    /// @param isWhitelisted whitelisted account or not
    /// @param lastParticipatedGameId the last game in which user auto participate
    struct WhiteLlistedInfo {
        bool isWhitelisted;
        uint256 lastParticipatedGameId;
    }

    /// @notice Emit when voting power of 'account' is changed to 'newVotes'
    /// @param account address of user whose voting power is changed
    /// @param newVotes new amount of voting power for 'account'
    event VotingPowerChanged(address account, uint256 newVotes);

    /// @notice Emit when reward pool is changed
    /// @param rewardPool address of new reward pool
    event RewardPoolChanged(address rewardPool);

    /// @notice Emit when addresses added to the whitelist
    /// @param accounts address of wallets to store in whitelist
    /// @param lastExistedGameId last game id existed in lotteries array
    event AddedToWhitelist(address[] accounts, uint256 lastExistedGameId);

    /// @notice Emit when wallets deleted from the whitelist
    /// @param accounts address of wallets to delete from whitelist
    event DeletedFromWhiteList(address[] accounts);

    /// @notice Getter for address of reward pool
    /// @return address of reward distribution contract
    function rewardPool() external view returns (address);

    /// @notice disable transfers
    /// @dev can be called by lottery game contract only
    function lockTransfer() external;

    /// @notice enable transfers
    /// @dev can be called by lottery game contract only
    function unlockTransfer() external;

    /// @dev start new game
    /// @param _participationFee amount of tokens needed to participaint in the game
    function startLottery(uint256 _participationFee)
        external
        returns (Lottery memory startedLottery);

    /// @dev finish game
    /// @param _participants count of participants
    /// @param _winnerAddresses address of winner
    /// @param _marketingAddress marketing address
    /// @param _winningPrizeValues amount of winning prize in tokens
    /// @param _marketingFeeValue amount of marketing fee in tokens
    /// @param _rewards amount of community and governance rewards
    function finishLottery(
        uint256 _participants,
        address[] memory _winnerAddresses,
        address _marketingAddress,
        uint256[] memory _winningPrizeValues,
        uint256 _marketingFeeValue,
        uint256 _rewards
    ) external returns (Lottery memory finishedLotteryGame);

    /// @notice Set address of reward pool to accumulate governance and community rewards at
    /// @dev Can be called only by lottery game contract
    /// @param _rewardPool address of reward distribution contract
    function setRewardPool(address _rewardPool) external;

    /// @notice Force finish of game with id <lotteryId>
    /// @param lotteryId id of lottery game to be needed shut down
    function forceFinish(uint256 lotteryId) external;

    /// @dev Returns last lottery
    function lastLottery() external view returns (Lottery memory lottery);

    /// @dev Returns last epoch
    function lastEpoch() external view returns (Epoch memory epoch);

    /// @dev Return voting power of the 'account' at the specific period of time 'blockTimestamp'
    /// @param account address to check voting power for
    /// @param blockTimestamp timestamp in second to check voting power at
    function getVotingPowerAt(address account, uint256 blockTimestamp)
        external
        view
        returns (uint256);

    /// @notice added accounts to whitelist
    /// @dev owner should be a governance
    /// @param accounts addresses of accounts that will be added to wthitelist
    function addToWhitelist(address[] memory accounts) external;

    /// @notice delete accounts from whitelist
    /// @dev owner should be a governance
    /// @param accounts addresses of accounts that will be deleted from wthitelist
    function deleteFromWhitelist(address[] memory accounts) external;
    
    /// @dev Returns participants count
    function participantsCount() external view returns(uint256);

    /// @dev Returns participants balances  in interval starting `from` to `count`
    function participantsBalances(uint256 from, uint256 count)
        external
        view
        returns (
            address[] memory participantAddresses,
            uint256[] memory participantBalances
        );

    /// @notice Return if user is whitelisted or not
    /// @param user_ address to check info for
    /// @return return true or false to point if the address is whitelisted
    function isWhitelisted(address user_) external view returns(bool);

    /// @notice get totalSypply of tokens
    /// @dev used only in CustomLotteryGame
    function getTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

interface IRewardDistribution {
    /// @notice rewards types
    enum RewardTypes {
        COMMUNITY,
        GOVERNANCE
    }

    /// @notice Info needed to store community reward distribution
    struct CommunityReward {
        uint256 timeOfGameFinish;
        uint256 countOfHolders;
        uint256 totalUsersHoldings;
        uint256 amountForDistribution;
        bool isMainLottoToken;
    }

    /// @notice Voting power info
    struct VotingPowerInfo {
        uint256 lottoPower;
        uint256 gamePower;
        bool isUpdated;
    }

    /// @notice Info about last distribution index
    struct LastProposalIndexInfo {
        uint256 index;
        // need this to handle case when the prev index will be 0 and count of proposals will be 1
        uint256 prevCountOfProposals;
    }

    /// @notice Info about indexes of valid proposals for the governance reward distribution
    struct GovRewardIndexes {
        uint256 from;
        uint256 to;
    }

    /// @notice Info about indexes of valid proposals for the governance reward distribution
    struct ClaimedIndexes {
        uint256 communityReward;
        uint256 governanceReward;
        bool isCommNullIndexUsed;
        bool isGovNullIndexUsed;
    }

    /// @notice Info needed to store governance reward distribution
    struct GovernanceReward {
        uint256 startPeriod;
        uint256 endPeriod;
        uint256 totalLottoAmount;
        uint256 totalGameAmount;
        uint256 lottoPerProposal;
        uint256 gamePerProposal;
        uint256 totalUsersHoldings;
        uint256 countOfProposals;
        GovRewardIndexes validPropIndexes;
    }

    /// @param interval point interval needed within checks e.g. 7 days
    /// @param day day of the week (0(Sunday) - 6(Saturday))
    struct CheckGovParams {
        uint256 interval;
        uint8 day;
    }

    /// @notice Emit when new lottery game is added
    /// @param lotteryGame address of lotteryGame contract
    event LotteryGameAdded(address indexed lotteryGame);

    /// @notice Emit when new lottery game is removed
    /// @param lotteryGame address of lotteryGame contract
    event LotteryGameRemoved(address indexed lotteryGame);

    /// @notice Emit when new reward distribution is added
    /// @param fromGame address of lotteryGame contract who added a distribution
    /// @param rewardType type of reward
    /// @param amountForDistribution amount of tokens for distribution
    event RewardDistributionAdded(
        address indexed fromGame,
        RewardTypes rewardType,
        uint256 amountForDistribution
    );

    /// @notice Emit when new reward distribution is added
    /// @param user address of user who claim the tokens
    /// @param distributedToken address of token what is claimed
    /// @param amount amount of tokens are claimed
    event RewardClaimed(
        address indexed user,
        address indexed distributedToken,
        uint256 indexed amount
    );

    /// @notice Add new game to the list
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param game_ address of new game contract
    function addNewGame(address game_) external;

    /// @notice Remove registrated game from the list
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param game_ address of game to be removed
    function removeGame(address game_) external;

    /// @notice Add new community reward distribution portion
    /// @dev Allowed to be called only by authorized game contracts
    /// @param distributionInfo structure of <CommunityReward> type
    function addDistribution(CommunityReward calldata distributionInfo)
        external;

    /// @notice Claim available community reward for the fucntion caller
    /// @dev Do not claim all available reward for the user.
    /// To avoid potential exceeding of block gas limit there is  some top limit of index.
    function claimCommunityReward() external;

    /// @notice Claim available reward for the fucntion caller
    /// @dev Do not claim all available reward for the user.
    /// To avoid potential exceeding of block gas limit there is  some top limit of index.
    function claimGovernanceReward() external;

    /// @notice Return available community reward of user
    /// @param user address need check rewards for
    function availableCommunityReward(address user)
        external
        view
        returns (uint256 lottoRewards, uint256 gameRewards);

    /// @notice Return available community reward of user
    /// @param user address need check rewards for
    function availableGovernanceReward(address user)
        external
        view
        returns (uint256 lottoRewards, uint256 gameRewards);
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

interface IGovernancePool {
    /// @notice increase amount of tokens in the pool for governnace reward
    /// @dev Accumulate governnace pool in case of week number accumulation limit is up to 5
    /// in another case will accumulate Extra pool
    /// @param lottoAmount amount of lotto tokens to be added to the pool
    /// @param gameAmount amount of game tokens to be added to the pool
    function replenishPool(uint256 lottoAmount, uint256 gameAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// day of week
/**
   1 - monday
   2 - tuesday
   3 - wednesday
   4 - thursday
   5 - friday
   6 - saturday
   0 - sunday

   hour should be in unix - so if you would need 20:00 EST you should set 15 (- 5 hours)

 */
contract DateTime {
    /*
     *  Date and Time utilities for ethereum contracts
     *
     */
    struct DateTimeStruct {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    struct TimelockForLotteryGame {
        uint8[] daysUnlocked;
        uint8[] hoursStartUnlock;
        uint256[] unlockDurations;
    }

    mapping(address => TimelockForLotteryGame) private timelocks;

    constructor(address lotteryGame, TimelockForLotteryGame memory timelock) {
        timelocks[lotteryGame] = timelock;
    }

    function getTimelock(address lotteryGame)
        external
        view
        returns (TimelockForLotteryGame memory)
    {
        return timelocks[lotteryGame];
    }

    function setTimelock(
        address lotteryGame,
        TimelockForLotteryGame memory timelock
    ) external {
        timelocks[lotteryGame] = timelock;
    }

    uint256 private constant DAY_IN_SECONDS = 86400;
    uint256 private constant YEAR_IN_SECONDS = 31536000;
    uint256 private constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 private constant HOUR_IN_SECONDS = 3600;
    uint256 private constant MINUTE_IN_SECONDS = 60;

    uint16 private constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year)
        public
        pure
        returns (uint8)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTimestamp(uint256 timestamp)
        internal
        pure
        returns (DateTimeStruct memory dt)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint256 timestamp) public pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint256 timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) public pure returns (uint256 timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            } else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        } else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}