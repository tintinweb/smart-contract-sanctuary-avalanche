// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./CustomLotteryGame.sol";

/// @title GenerateBytecode contract
/// @author Applicature
/// @dev Contract for creating CustomLottery bycode for deployment
contract GenerateBytecode { 
    function createLotteryBytecode(
        ICustomLotteryGame.Game memory game,
        address governance_,
        address rewardDistribution_,
        address dateTime_,
        address gameToken_
    ) external pure returns(bytes memory){
        bytes memory bytecode = type(CustomLotteryGame).creationCode;
        return bytecode;
        // return abi.encodePacked(bytecode, abi.encode(game, (governance_), (rewardDistribution_),dateTime_,gameToken_)); 
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "../interfaces/IRewardDistribution.sol";
import "../interfaces/IGovernancePool.sol";
import "../interfaces/ICustomLotteryGame.sol";
import "../interfaces/IERC677.sol";
import "./IDateTime.sol";
import "./Constants.sol";

interface IGovernance {
    function governanceReward() external returns (uint256);
    function communityReward() external returns (uint256);
}

/* solhint-disable var-name-mixedcase */
contract CustomLotteryGame is
    ICustomLotteryGame,
    Ownable,
    VRFConsumerBaseV2,
    KeeperCompatibleInterface
{
    using SafeERC20 for IERC20;

    bool private test;

    /// @notice address of Governance contract
    address private immutable governance;
    /// @notice address of DateTime contract
    IDateTime private immutable dateTime;
    /// @notice address of LotteryGameToken contract
    IERC20 private immutable gameToken;
    /// @notice address LINK token contract
    IERC677 private linkToken;
    /// @notice struct of info about the game
    Game public game;
    /// @notice struct info about chainlink parameters
    ChainlinkParameters public chainlinkSettings;
    /// @notice address-> game id -> true/false - is/is not
    mapping(address => mapping(uint256 => bool)) public isGameParticipant;
    /// @notice user subscription info
    mapping(address => Subscription) public subcriptors;
    /// @notice round id => info
    mapping(uint256 => GameOptionsInfo) public gamesRoundInfo;
    /// @notice address of RewardPool contract
    address private rewardPool;
    /// @notice address for _callChainlinkVRFForWinnersIndexes
    address private COORDINATOR;
    /// @notice time lock for lottery game
    IDateTime.TimelockForLotteryGame private timeLock;
    /// @notice struct to pending params
    Pending public pending;
    /// @notice array of info for created rounds
    Lottery[] public lotteries;
    /// @notice address KeeperRegistry contract
    address private keeperRegistry;

    bool private isGameStarted;
    bool private isWinnersRequired;

    function get() external view returns(bool){
        return test;
    }
    constructor(
        Game memory game_,
        address governance_,
        address rewardPool_,
        IDateTime dateTime_,
        IERC20 gameToken_
    ) VRFConsumerBaseV2(VRF_COORDINATOR) {
        test = true;
        game = game_;
        pending.participationFee = game_.participationFee;
        pending.winnersNumber = game_.countOfWinners;
        pending.winnersPercentages = game_.winnersPercentages;
        pending.limitOfPlayers = game_.participantsLimit;
        pending.callerFeePercents = game_.callerFeePercents;

        dateTime = dateTime_;
        gameToken = gameToken_;

        require(
            game_.countOfWinners == game_.winnersPercentages.length &&
                game_.benefeciaryPercentage.length ==
                game_.benefeciaries.length
        );

        require(
            _isPercentageCorrect(
                game_.countOfWinners,
                game_.winnersPercentages
            )
        );
        require(
            _isPercentageCorrect(
                game_.benefeciaryPercentage.length,
                game_.benefeciaryPercentage
            )
        );

        rewardPool = rewardPool_;
        governance = governance_;
        _addPendingLottery(0);
    }

    modifier isGameDeactivated() {
        require(!game.isDeactivated/*, ERROR_DEACTIVATED_GAME*/);
        _;
    }

    /// @notice get participation fee for LotteryGameFactory contract
    function getParticipationFee() public view override returns (uint256) {
        return game.participationFee;
    }

    /// @notice set KeeperRegistry contract address
    function setKeeperRegistry(address keeperRegistry_) external onlyOwner {
        keeperRegistry = keeperRegistry_;
    }

    /// @notice set LINKToken contract address
    /// @param linkToken_ Link token address
    function setLinkToken(address linkToken_) external onlyOwner {
        linkToken = IERC677(linkToken_);
    }

    /// @notice set participants limit (how much participants can enter the game)
    /// @param _participantsLimit amount of participants limit
    function setParticipantsLimit(uint256 _participantsLimit)
        external
        onlyOwner
    {
        pending.limitOfPlayers = _participantsLimit;
    }

    /// @notice set time lock if the game will be locked
    /// @param timelock time lock for the locked lottery game
    function setTimelock(IDateTime.TimelockForLotteryGame memory timelock)
        external
        onlyOwner
    {
        timeLock = timelock;
    }

    /// @notice set description ipfs fpr additional lottery
    /// @param _hash string of oracle ipfs hash
    function setDescriptionIPFS(string memory _hash) external onlyOwner {
        game.decriptionIPFS = _hash;
    }

    /// @notice set participants fee to enter game
    /// @param _participationFee fee to enter the game
    function setParticipationFee(uint256 _participationFee) external onlyOwner {
        pending.participationFee = _participationFee;
    }

    /// @notice set game caller fee percents
    /// @param _amount amount of percents for caller
    function setGameCallerFeePercents(uint256 _amount) external onlyOwner {
        require(
            _amount < HUNDRED_PERCENT_WITH_PRECISONS
        );
        pending.callerFeePercents = _amount;
    }

    /// @notice set another game duration from timelock
    /// @param _gameDuration timestamp of the game duration
    function switchTimelockToDateDuration(uint256 _gameDuration)
        external
        onlyOwner
    {
        game.isDateTimeRequired = false;
        game.gameDuration = _gameDuration;        
        emit ChangedGameDuration(_gameDuration);
    }

    /// @notice set game duration
    /// @param _gameDuration timestamp of the game duration
    function setGameDuration(uint256 _gameDuration) external onlyOwner {
        require(!game.isDateTimeRequired);
        game.gameDuration = _gameDuration;

        emit ChangedGameDuration(_gameDuration);
    }

    /// @notice set percentages for each winner for the current round
    /// @param countOfWinners_ number of winners in the round
    /// @param winnersPercentages_ array of percentages for each winner
    function setWinnersNumber(
        uint256 countOfWinners_,
        uint256[] calldata winnersPercentages_
    ) external onlyOwner {
        require(
            countOfWinners_ != 0 && countOfWinners_ <= WINNERS_LIMIT
        );
        require(
            winnersPercentages_.length == countOfWinners_
        );

        //check if sum of percentage is 100%
        require(
            _isPercentageCorrect(countOfWinners_, winnersPercentages_)
        );

        pending.winnersNumber = countOfWinners_;
        pending.winnersPercentages = winnersPercentages_;

        emit ChangedWinners(countOfWinners_, winnersPercentages_);
    }

    /// @notice set paddress of RewardPool contract
    /// @param rewardPool_ address of RewardPool contract
    function setRewardPool(address rewardPool_) external onlyOwner {
        require(rewardPool_ != address(0));
        rewardPool = rewardPool_;
    }

    function checkUpkeep(
        bytes calldata /*checkData*/
    ) external view override returns (bool, bytes memory checkedData) {
        uint256 countOfSubscriptorsAndParticipants;
        uint256 countOfSubscriptorsForNextRound;
        address[] memory subscriptorsAndParticipants;
        address[] memory winnersAddresses;

        for (uint256 i = 0; i < game.subcriptorsList.length; i++) {
            uint256 userBalance = subcriptors[game.subcriptorsList[i]].balance;
            if (userBalance >= game.participationFee) {
                subscriptorsAndParticipants[
                    countOfSubscriptorsAndParticipants
                ] = game.subcriptorsList[i];
                countOfSubscriptorsAndParticipants++;

                if (userBalance >= game.participationFee * 2)
                    countOfSubscriptorsForNextRound++;
            }
        }

        Lottery storage lastLotteryGame = lotteries[lotteries.length - 1];

        if (isGameStarted) {
            countOfSubscriptorsAndParticipants =
                subscriptorsAndParticipants.length +
                lastLotteryGame.participants.length;

            checkedData = abi.encode(
                countOfSubscriptorsAndParticipants,
                winnersAddresses
            );
        }
        if (isWinnersRequired) {
            // get winners addresses from winners indexes
            for (
                uint256 i = 0;
                i < gamesRoundInfo[lastLotteryGame.id].winnersIndexes.length;
                i++
            ) {
                winnersAddresses[i] = subscriptorsAndParticipants[
                    gamesRoundInfo[lastLotteryGame.id].winnersIndexes[i]
                ];
            }

            checkedData = abi.encode(
                countOfSubscriptorsForNextRound,
                winnersAddresses
            );
        }

        return (isGameStarted || isWinnersRequired, checkedData);
    }

    function performUpkeep(bytes calldata performData) external override {
        if (isGameStarted) {
            isGameStarted = false;
            (uint256 allParticipantsCount, ) = abi.decode(
                performData,
                (uint256, address[])
            );
            game.participantsCount = allParticipantsCount;
            _callChainlinkVRFForWinnersIndexes();
        }
        if (isWinnersRequired) {
            isWinnersRequired = false;

            _handleChainlinkWinnersResponce(performData);
        }
    }

    /// @notice start created game
    /// @param VRFGasLimit_ price for VRF
    function startGame(uint32 VRFGasLimit_)
        external
        virtual
        isGameDeactivated
    {
        Lottery storage lastLotteryGame = lotteries[lotteries.length - 1];

        require(lastLotteryGame.isActive/*, ERROR_NOT_ACTIVE*/);

        if(linkToken.balanceOf(address(this)) > MIN_LINK_TOKENS_NEEDDED) {
  // function addFunds(uint256 id,uint96 amount)
        }
        

        if (lastLotteryGame.id > 0) {
            if (game.isDateTimeRequired) {
                require(_isTimelockValid());
            } else {
                require(
                    block.timestamp >=
                        lastLotteryGame.finishedAt + game.gameDuration
                );
            }
        }

        lastLotteryGame.startedAt = block.timestamp;
        game.callerFeeCollector = msg.sender;
        game.VRFGasLimit = VRFGasLimit_;
        emit GameStarted(lastLotteryGame.id, block.timestamp);

        isGameStarted = true;
    }

    /// @notice Enter game for following one round
    /// @dev participatinonFee will be charged from msg.sender
    /// @param participant address of the participant
    function entryGame(address participant) external override {
        _entryGame(participant);
    }

    /// @notice Enter game for following one round
    /// @dev participant address is msg.sender
    function entryGame() external override isGameDeactivated {
        _entryGame(msg.sender);
    }

    /// @notice entry to the game for user
    /// @dev not active if the game is deactivated
    function _entryGame(address participant) private isGameDeactivated {
        Lottery memory lastLotteryGame = lotteries[lotteries.length - 1];
        uint256 id = lastLotteryGame.id;

        require(
            lastLotteryGame.isActive && lastLotteryGame.startedAt == 0
        );

        // check if the user is not enterred the game or don't have a subcription
        require(!isGameParticipant[participant][id]);
        require(
            subcriptors[participant].balance == 0
        );

        // check the limit
        game.participantsCount += 1;
        uint256 particLimit = game.participantsLimit;
        if (particLimit != 0) {
            require(game.participantsCount <= particLimit);
        }

        // send money to the lottery
        gameToken.safeTransferFrom(
            participant,
            address(this),
            game.participationFee
        );

        isGameParticipant[participant][id] = true;

        Lottery storage lottery = lotteries[id];

        lottery.participants.push(participant);
    }

    /// @notice subscribe for the game
    /// @dev not active if the game is deactivated
    /// @param amount amount of Game tokens
    function subcribe(uint256 amount) external isGameDeactivated {
        Lottery memory lastLotteryGame = lotteries[lotteries.length - 1];

        uint256 id = lastLotteryGame.id;
        require(!isGameParticipant[msg.sender][id]);

        if (subcriptors[msg.sender].balance == 0) {
            if (!subcriptors[msg.sender].isExist) {
                game.participantsCount += 1;
                if (game.participantsLimit != 0) {
                    require(
                        game.participantsCount <= game.participantsLimit,
                        ERROR_LIMIT_EXEED
                    );
                }
                subcriptors[msg.sender].isExist = true;
                game.subcriptorsList.push(msg.sender);
            }

            // if game was started set last id next game id
            subcriptors[msg.sender].lastCheckedGameId = lastLotteryGame
                .startedAt == 0
                ? id
                : id + 1;
        }

        subcriptors[msg.sender].balance += amount;

        // send money to the lottery
        gameToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice remove subscription from the game
    /// @dev can be called for deactivated games
    function removeSubcription() external {
        Lottery memory lastLotteryGame = lotteries[lotteries.length - 1];

        require(lastLotteryGame.startedAt == 0);

        Subscription storage info = subcriptors[msg.sender];

        require(info.isExist);
        uint256 withdrawAmount;
        if (info.balance != 0) {
            withdrawAmount = info.balance; // for event
            gameToken.safeTransfer(msg.sender, info.balance);
        }

        if (subcriptors[msg.sender].balance >= game.callerFeePercents) {
            delete subcriptors[msg.sender];
            game.participantsCount--;
        }
    }

    /// @notice deactivation game
    /// @dev if the game is deactivated cannot be called entryGame()  and subcribe()
    function deactivateGame() external override onlyOwner {
        pending.isDeactivated = true;
    }

    /// @notice get balance of subscription to the game
    /// @param account address of subscription
    function balanceOfSubscription(address account)
        external
        view
        returns (uint256)
    {
        return _balanceOfSubscription(account);
    }

    /// @notice get balances of subscription for limit of accounts
    /// @param from the first index
    /// @param count amount of accounts
    function getSubcriptorsBalances(uint256 from, uint256 count)
        external
        view
        returns (
            address[] memory subcriptorsAddresses,
            uint256[] memory subcriptorsBalances
        )
    {
        uint256 finalCount = from + count <= game.subcriptorsList.length
            ? count
            : game.subcriptorsList.length - from;

        subcriptorsAddresses = new address[](finalCount);
        subcriptorsBalances = new uint256[](finalCount);

        for (uint256 i = from; i < from + finalCount; i++) {
            subcriptorsAddresses[i - from] = game.subcriptorsList[i];
            subcriptorsBalances[i - from] = _balanceOfSubscription(
                game.subcriptorsList[i]
            );
        }
    }

    ///@dev Transfer jackpot to the winners and prize to the beneficiaries
    /// Pending data is changed if requested
    ///@param bytesData encoded params with count of participants and array addresses of winners
    function _handleChainlinkWinnersResponce(bytes memory bytesData) internal {
        Lottery memory lastLotteryGame = lotteries[lotteries.length - 1];

        require(
            lastLotteryGame.startedAt != 0 && lastLotteryGame.isActive
        );
        uint256 id = lastLotteryGame.id;

        //decode
        (uint256 countOfParticipants, address[] memory winners) = abi.decode(
            bytesData,
            (uint256, address[])
        );

        WinningPrize memory jackpot;
        uint256 eligibleParticipants = gamesRoundInfo[id].countOfParticipants;

        jackpot.totalWinningPrize =
            lastLotteryGame.participationFee *
            eligibleParticipants;
        jackpot.callerFee = _calculatePercents(
            game.callerFeePercents,
            jackpot.totalWinningPrize
        );

        // reward and governance fee
        jackpot.governanceFee = IGovernance(governance).governanceReward();
        jackpot.communityFee = IGovernance(governance).communityReward();
        jackpot.governanceReward = _calculatePercents(
            jackpot.governanceFee,
            jackpot.totalWinningPrize
        );

        jackpot.communityReward = _calculatePercents(
            jackpot.communityFee,
            jackpot.totalWinningPrize
        );

        jackpot.totalReward =
            jackpot.governanceReward +
            jackpot.communityReward;
        jackpot.totalWinningPrizeExludingFees =
            jackpot.totalWinningPrize -
            jackpot.callerFee -
            jackpot.totalReward;

        uint256[] memory beneficiariesPrize = new uint256[](
            game.benefeciaries.length
        );
        for (uint256 i = 0; i < game.benefeciaries.length; i++) {
            beneficiariesPrize[i] = _calculatePercents(
                game.benefeciaryPercentage[i],
                jackpot.totalWinningPrizeExludingFees
            );
            jackpot.beneficiariesPrize += beneficiariesPrize[i];
        }

        jackpot.totalWinningPrizeExludingFees -= jackpot.beneficiariesPrize;

        uint256[] memory winningPrizeExludingFees = new uint256[](
            countOfParticipants
        );

        //calculate winning amount for each winner based on his percent portion
        for (uint256 i = 0; i < countOfParticipants; i++) {
            winningPrizeExludingFees[i] = _calculatePercents(
                game.winnersPercentages[i],
                jackpot.totalWinningPrizeExludingFees
            );
        }

        _finishGame(
            Lottery(
                address(0), // address rewardPool;
                false, // bool isActive;
                id, // uint256 id;
                game.participationFee, // uint256 participationFee;
                lastLotteryGame.startedAt, // uint256 startedAt;
                block.timestamp, // uint256 finishedAt;
                jackpot.totalReward, // uint256 rewards;
                winningPrizeExludingFees, // uint256[] winningPrize;
                beneficiariesPrize, // uint256[] beneficiariesPrize;
                lastLotteryGame.participants, // address[] participants;
                winners, // address[] winners;
                game.benefeciaries // address[] beneficiaries;
            )
        );

        gameToken.safeTransfer(rewardPool, jackpot.totalReward);
        gameToken.safeTransfer(game.callerFeeCollector, jackpot.callerFee);
        _transferTokens(game.countOfWinners, winners, winningPrizeExludingFees);
        _transferTokens(
            game.benefeciaries.length,
            game.benefeciaries,
            beneficiariesPrize
        );

        _distributeReward(
            lastLotteryGame.finishedAt,
            jackpot.communityReward,
            jackpot.governanceReward
        );

        _addPendingLottery(id + 1);

        // change pending info if required
        if (pending.isDeactivated != game.isDeactivated)
            game.isDeactivated = pending.isDeactivated;

        if (pending.participationFee != game.participationFee)
            game.participationFee = pending.participationFee;

        if (pending.winnersNumber != game.countOfWinners)
            game.countOfWinners = pending.winnersNumber;

        if (
            keccak256(abi.encodePacked(pending.winnersPercentages)) !=
            keccak256(abi.encodePacked(game.winnersPercentages))
        ) game.winnersPercentages = pending.winnersPercentages;

        if (pending.limitOfPlayers != game.participantsLimit)
            game.participantsLimit = pending.limitOfPlayers;

        if (pending.callerFeePercents != game.callerFeePercents)
            game.callerFeePercents = pending.callerFeePercents;

        game.participantsCount = countOfParticipants;
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal virtual override {
        Lottery memory lastLotteryGame = lotteries[lotteries.length - 1];

        require(lastLotteryGame.isActive);
        uint256 id = lastLotteryGame.id;
        uint256 countOfParticipants = gamesRoundInfo[id].countOfParticipants;

        uint256 winnersCount = game.countOfWinners;
        uint256[] memory indexes = new uint256[](winnersCount);
        for (uint256 i = 0; i < winnersCount; i++) {
            indexes[i] = randomWords[i] % countOfParticipants;
        }
        gamesRoundInfo[id].winnersIndexes = indexes;

        isWinnersRequired = true;
    }

    //to get EST time = ETS time + 4 hourst ( will get UNIX == EST)
    // date time library works withunix time - it is 4 hours
    function _isTimelockValid() internal view returns (bool) {
        uint16 dayOfWeek = dateTime.getWeekday(block.timestamp);
        IDateTime.TimelockForLotteryGame memory timelock = dateTime.getTimelock(
            address(this)
        );
        for (uint256 i; i < timelock.daysUnlocked.length; i++) {
            if (dayOfWeek == timelock.daysUnlocked[i]) {
                uint8 day = dateTime.getDay(block.timestamp) + 1;
                uint8 month = dateTime.getMonth(block.timestamp);
                uint16 year = dateTime.getYear(block.timestamp);
                uint256 startTimestamp = dateTime.toTimestamp(
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

    function _finishGame(Lottery memory newLotteryGame) private {
        Lottery storage lastLotteryGame = lotteries[newLotteryGame.id];
        lastLotteryGame.finishedAt = newLotteryGame.finishedAt;
        lastLotteryGame.winners = newLotteryGame.winners;
        lastLotteryGame.beneficiaries = newLotteryGame.beneficiaries;
        lastLotteryGame.rewards = newLotteryGame.rewards;
        lastLotteryGame.rewardPool = rewardPool;
        lastLotteryGame.winningPrize = newLotteryGame.winningPrize;
        lastLotteryGame.beneficiariesPrize = newLotteryGame.beneficiariesPrize;
        lastLotteryGame.isActive = false;
    }

    function _transferTokens(
        uint256 count,
        address[] memory recipients,
        uint256[] memory amounts
    ) private {
        for (uint256 i = 0; i < count; i++) {
            gameToken.safeTransfer(recipients[i], amounts[i]);
        }
    }

    function _callChainlinkVRFForWinnersIndexes() private {
        VRFCoordinatorV2Interface(COORDINATOR).requestRandomWords(
            chainlinkSettings.keyHash,
            chainlinkSettings.s_subscriptionId,
            chainlinkSettings.requestConfirmations,
            game.VRFGasLimit,
            uint32(game.countOfWinners)
        );
    }

    function _distributeReward(
        uint256 timeOfGameFinish,
        uint256 communityReward,
        uint256 governanceReward
    ) private {
        IGovernancePool(rewardPool).replenishPool(0, governanceReward);

        // add new community reward distribution
        IRewardDistribution.CommunityReward memory distributionInfo;
        distributionInfo.timeOfGameFinish = timeOfGameFinish;
        distributionInfo.totalUsersHoldings = IERC20(address(gameToken))
            .totalSupply();
        distributionInfo.amountForDistribution = communityReward;
        distributionInfo.isMainLottoToken = false;
        IRewardDistribution(rewardPool).addDistribution(distributionInfo);
    }

    function _addPendingLottery(uint256 newGameId) private {
        EmptyTypes memory emptyData;
        lotteries.push(
            Lottery(
                address(0), // address rewardPool;
                true, // bool isActive;
                newGameId, // uint256 id;
                game.participationFee, // uint256 participationFee;
                0, // uint256 startedAt;
                0, // uint256 finishedAt;
                0, // uint256 rewards;
                emptyData.emptyUInt, // uint256[] winningPrize;
                emptyData.emptyUInt, // uint256[] beneficiariesPrize;
                emptyData.emptyAddr, // address[] participants;
                emptyData.emptyAddr, // address[] winners;
                emptyData.emptyAddr // address[] beneficiaries;
            )
        );
    }

    function _balanceOfSubscription(address account)
        private
        view
        returns (uint256)
    {
        Subscription memory info = subcriptors[account];
        uint256 subscriptorBalance = info.balance;
        if (subscriptorBalance == 0) {
            return 0;
        }
        uint256 gameId = lotteries.length - 1;
        return
            _calculateBalanceOfSubscription(
                info.balance,
                info.lastCheckedGameId,
                gameId
            );
    }

    function _calculateBalanceOfSubscription(
        uint256 _calculatedBalance,
        uint256 _fromGameId,
        uint256 _toGameId
    ) private view returns (uint256) {
        for (
            uint256 i = _fromGameId;
            i <= _toGameId && _calculatedBalance > 0;
            i++
        ) {
            Lottery storage lottery = lotteries[i];
            if (_calculatedBalance >= lottery.participationFee) {
                _calculatedBalance =
                    _calculatedBalance -
                    lottery.participationFee;
            }
        }

        return _calculatedBalance;
    }

    function _calculatePercents(uint256 percent, uint256 amount)
        private
        pure
        returns (uint256)
    {
        return (amount * percent) / HUNDRED_PERCENT_WITH_PRECISONS;
    }

    function _isPercentageCorrect(uint256 index, uint256[] memory percentages)
        private
        pure
        returns (bool)
    {
        uint256 totalPercentsSum;
        for (uint256 i = 0; i < index; i++) {
            totalPercentsSum += percentages[i];
        }
        return totalPercentsSum == HUNDRED_PERCENT_WITH_PRECISONS;
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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

/* solhint-disable var-name-mixedcase */
interface ICustomLotteryGame {
    /// @notice store more detailed info about the additional game
    /// @param VRFGasLimit amount of the gas limit for VRF
    /// @param countOfWinners number of winners
    /// @param participantsLimit limit of users that can be in game
    /// @param participantsCount number of user that are already in game
    /// @param participationFee amount of fee for user to enter the game
    /// @param callerFeePercents amount of fee percentage for caller of the game
    /// @param gameDuration timestamp how long the game should be going
    /// @param isDeactivated bool value is the game is deactibated (true) or not (false)
    /// @param callerFeeCollector address of the caller fee percentage
    /// @param lotteryName the name of the lottery game
    /// @param decriptionIPFS ipfs hash with lottery description
    /// @param winnersPercentages array of winners percentage
    /// @param benefeciaryPercentage array of beneficiary reward percentage
    /// @param subcriptorsList array of subscriptors
    /// @param benefeciaries array of lottery beneficiaries
    struct Game {
        uint32 VRFGasLimit;
        uint256 countOfWinners;
        uint256 participantsLimit;
        uint256 participantsCount;
        uint256 participationFee;
        uint256 callerFeePercents;
        uint256 gameDuration;
        bool isDateTimeRequired;
        bool isDeactivated;
        address callerFeeCollector;
        string lotteryName;
        string decriptionIPFS;
        uint256[] winnersPercentages;
        uint256[] benefeciaryPercentage;
        address[] subcriptorsList;
        address[] benefeciaries;
    }

    struct EmptyTypes {
        address[] emptyAddr;
        uint256[] emptyUInt;
    }

    /// @notice store lottery (rounds) info
    /// @param rewardPool address of the reward pool
    /// @param isActive is active
    /// @param id lottery id
    /// @param participationFee paricipation fee for user to enter lottery
    /// @param startedAt timestamp when the lottery is started
    /// @param finishedAt timestamp when the lottery is finished
    /// @param rewards amount of the rewards
    /// @param winningPrize array of amount for each winner
    /// @param beneficiariesPrize array of amount for each beneficiary
    /// @param participants array of lottery participants
    /// @param winners array of lottery winners
    /// @param beneficiaries array of lottery beneficiaries
    struct Lottery {
        address rewardPool;
        bool isActive;
        uint256 id;
        uint256 participationFee;
        uint256 startedAt;
        uint256 finishedAt;
        uint256 rewards;
        uint256[] winningPrize;
        uint256[] beneficiariesPrize;
        address[] participants;
        address[] winners;
        address[] beneficiaries;
    }

    /// @notice store subscription info
    /// @param balance user balance of withdrawn money in subscription after a round
    /// @param lastCheckedGameId the game (round) id from which will be active yser`s subscription
    /// @param isExist is user subscribe
    struct Subscription {
        bool isExist;
        uint256 balance;
        uint256 lastCheckedGameId;
    }

    /// @notice store game options info
    /// @param countOfParticipants number of participants in a round
    /// @param winnersIndexes array of winners indexes
    struct GameOptionsInfo {
        uint256 countOfParticipants;
        uint256[] winnersIndexes;
    }

    /// @notice store chainlink parameters info
    /// @param requestConfirmations amount of confiramtions
    /// @param s_subscriptionId subscription id is setted automatically
    /// @param keyHash key hash to connect to oracle
    struct ChainlinkParameters {
        uint16 requestConfirmations;
        uint64 s_subscriptionId;
        bytes32 keyHash;
    }

    /// @notice store winning prize info
    /// @param totalWinningPrize amount of total winning prize of jeckpot
    /// @param callerFee percentage of caller fee for jeckpot
    /// @param governanceFee percentage of game tokens as a governance rewatds from jeckpot
    /// @param communityFee percentage of game tokens as a community rewatds from jeckpot
    /// @param governanceReward amount of game tokens as a governance rewatds from jeckpot
    /// @param communityReward amount of game tokens as a community rewatds from jeckpot
    /// @param totalReward percentage of total rewards from jeckpot
    /// @param beneficiariesPrize percentage of beneficiary prize of jeckpot
    /// @param totalWinningPrizeExludingFees amount of total winning prize without fees of jeckpot
    struct WinningPrize {
        uint256 totalWinningPrize;
        uint256 callerFee;
        uint256 governanceFee;
        uint256 communityFee;
        uint256 governanceReward;
        uint256 communityReward;
        uint256 totalReward;
        uint256 beneficiariesPrize;
        uint256 totalWinningPrizeExludingFees;
    }

    /// @notice store all chenging params for the game
    /// @dev this pending params are setted to the game from the next round
    /// @param isDeactivated is game active or not
    /// @param participationFee  participation fee for the game
    /// @param winnersNumber count of winners
    /// @param winnersPercentages array of percenages for winners
    /// @param limitOfPlayers participants limit
    /// @param callerFeePercents caller fee percntages
    struct Pending {
        bool isDeactivated;
        uint256 participationFee ;
        uint256 winnersNumber;
        uint256 limitOfPlayers;
        uint256 callerFeePercents;
        uint256[] winnersPercentages;
    }

    /// @notice emitted when called fullfillBytes
    /// @param requestId encoded request id
    /// @param data encoded data
    event RequestFulfilled(bytes32 indexed requestId, bytes indexed data);

    /// @notice emitted when the game is started
    /// @param id the game id
    /// @param startedAt timestamp when game is started
    event GameStarted(uint256 indexed id, uint256 indexed startedAt);

    /// @notice emitted when the game is finished
    /// @param id the game id
    /// @param startedAt timestamp when game is started
    /// @param finishedAt timestamp when game is finished
    /// @param participants array of games participants
    /// @param winners array of winners
    /// @param participationFee participation fee for users to enter to the game
    /// @param winningPrize array of prizes for each winner
    /// @param rewards amount of jeckpot rewards
    /// @param rewardPool reward pool of the game
    event GameFinished(
        uint256 id,
        uint256 startedAt,
        uint256 finishedAt,
        address[] indexed participants,
        address[] indexed winners,
        uint256 participationFee,
        uint256[] winningPrize,
        uint256 rewards,
        address indexed rewardPool
    );

    /// @notice emitted when a game duration is change
    /// @param gameDuration timestamp of the game duration
    event ChangedGameDuration(uint256 gameDuration);

    /// @notice emitted when a game amount of winners is change
    /// @param winnersNumber new amount of winners
    /// @param winnersPercentages new percentage
    event ChangedWinners(uint256 winnersNumber, uint256[] winnersPercentages);

    /// @notice Enter game for following one round
    /// @dev participant address is msg.sender
    function entryGame() external;

    /// @notice Enter game for following one round
    /// @dev participatinonFee will be charged from msg.sender
    /// @param participant address of the participant
    function entryGame(address participant) external;

    /// @notice start created game
    /// @param VRFGasPrize_ price for VRF
    function startGame(uint32 VRFGasPrize_) external;

    /// @notice deactivation game
    /// @dev if the game is deactivated cannot be called entryGame()  and subcribe()
    function deactivateGame() external;

    /// @notice get participation fee for LotteryGameFactory contract
    function getParticipationFee() external view returns (uint256);
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IERC677 interface
/// @author Applicature
/// @dev interface for LINK tokens from ChainLinkKeepers to register CustomLotteryGame as a keeper
interface IERC677 is IERC20 {
    /// @dev transfer token to a contract address with additional data if the recipient is a contact
    /// @param to the address to transfer to.
    /// @param value the amount to be transferred.
    /// @param data the extra data to be passed to the receiving contract.
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
interface IDateTime {
    
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

    

    function getTimelock(address lotteryGame)
        external
        view
        returns (TimelockForLotteryGame memory);

    function isLeapYear(uint16 year) external pure returns (bool);

    function leapYearsBefore(uint256 year) external pure returns (uint256);

    function getDaysInMonth(uint8 month, uint16 year)
        external
        pure
        returns (uint8);

    function getYear(uint256 timestamp) external pure returns (uint16);
    function getMonth(uint256 timestamp) external pure returns (uint8);
    function getDay(uint256 timestamp) external pure returns (uint8);
    function getHour(uint256 timestamp) external pure returns (uint8);
    function getMinute(uint256 timestamp) external pure returns (uint8);
    function getSecond(uint256 timestamp) external pure returns (uint8);
    function getWeekday(uint256 timestamp) external pure returns (uint8);
    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour
    ) external pure returns (uint256 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint256 constant WINNERS_LIMIT = 10;
uint256 constant BENEFICIARY_LIMIT = 100;
address constant VRF_COORDINATOR =
    0x6168499c0cFfCaCD319c818142124B7A15E857ab;
uint256 constant HUNDRED_PERCENT_WITH_PRECISONS = 10_000;
uint256 constant MIN_LINK_TOKENS_NEEDDED = 5_000_000_000_000_000_000;

string constant ERROR_INCORRECT_LENGTH = "0x1";
string constant ERROR_INCORRECT_PERCENTS_SUM = "0x2";
string constant ERROR_DEACTIVATED_GAME = "0x3";
string constant ERROR_CALLER_FEE_CANNOT_BE_MORE_100 = "0x4";
string constant ERROR_TIMELOCK_IN_DURATION_IS_ACTIVE = "0x5";
string constant ERROR_DATE_TIME_TIMELOCK_IS_ACTIVE = "0x6";
string constant ERROR_LIMIT_UNDER = "0x7";
string constant ERROR_INCORRECT_PERCENTS_LENGTH = "0x8";
string constant ERROR_NOT_READY_TO_START = "0x9";
string constant ERROR_NOT_ACTIVE_OR_STARTED = "0xa";
string constant ERROR_PARTICIPATE_ALREADY = "0xb";
string constant ERROR_INVALID_PARTICIPATE = "0xc";
string constant ERROR_LIMIT_EXEED = "0xd";
string constant ERROR_ALREADY_DEACTIVATED = "0xe";
string constant ERROR_GAME_STARTED = "0xf";
string constant ERROR_NO_SUBSCRIPTION = "0x10";
string constant ERROR_NOT_ACTIVE = "0x11";
string constant ERROR_ZERO_ADDRESS = "0x12";

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