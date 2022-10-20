//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IVRF.sol";

interface ITicketReceiver {
    function trigger() external;
}

contract xGrapePrizePool is Ownable, VRFConsumerBaseV2 {

    // Constant Contracts
    address public constant xGrape = 0x95CED7c63eA990588F3fd01cdDe25247D04b8D98;

    // Lotto History
    struct History {
        address winner;
        uint256 amountWon;
        uint256 winningTicket;
        uint256 timestamp;
    }

    // Lotto ID => Lotto History
    mapping ( uint256 => History ) public lottoHistory;

    // User Info
    struct UserInfo {
        uint256 amountWon;
        uint256 amountSpent;
        uint256 numberOfWinningTickets;
    }

    // User => UserInfo
    mapping ( address => UserInfo ) public userInfo;

    // User => Lotto ID => Number of tickets purchased
    mapping ( address => mapping ( uint256 => uint256 )) public userTickets;

    // Current Lotto ID
    uint256 public currentLottoID;

    // Tracked Values
    uint256 public totalRewarded;
    uint256 public totalxGrapeUsedToBuyTickets;

    // Ticket Cost Collector
    address public ticketCostCollector;

    // Lotto Details
    uint256 public startingCostPerTicket = 1 * 10**18;
    uint256 public costIncreasePerTimePeriod = 1 * 10**17;
    uint256 public timePeriodForCostIncrease = 28800;
    uint256 public lottoDuration = 3 days;

    // When Last Lotto Began
    uint256 public lastLottoStartTime;

    // current ticket ID
    uint256 public currentTicketID;
    mapping ( uint256 => address ) public ticketToUser;

    // Roll Over Percentage
    uint256 public rollOverPercentage = 20;

    // VRF Coordinator
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 private s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 private keyHash;

    // gas limit to call function
    uint32 public gasToCallRandom = 500_000;

    // Events
    event WinnerChosen(address winner, uint256 pot, uint256 winningTicket);

    constructor(uint64 subscriptionID) VRFConsumerBaseV2(0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634) {
        // setup chainlink
        keyHash = 0x83250c5584ffa93feb6ee082981c5ebe484c865196750b39835ad4f13780435d;
        COORDINATOR = VRFCoordinatorV2Interface(0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634);
        s_subscriptionId = subscriptionID;
    }

    /**
        Sets Gas Limits for VRF Callback
     */
    function setGasLimits(uint32 gasToCallRandom_) external onlyOwner {
        gasToCallRandom = gasToCallRandom_;
    }

    /**
        Sets The Key Hash
     */
    function setKeyHash(bytes32 newHash) external onlyOwner {
        keyHash = newHash;
    }

    /**
        Sets Subscription ID for VRF Callback
     */
    function setSubscriptionId(uint64 subscriptionId_) external onlyOwner {
       s_subscriptionId = subscriptionId_;
    }

    function init() external onlyOwner {
        require(
            lastLottoStartTime == 0,
            'Already initialized'
        );
        lastLottoStartTime = block.timestamp;
    }

    function setStartingTicketCost(uint256 newCost) external onlyOwner {
        startingCostPerTicket = newCost;
    }

    function setLottoDuration(uint256 newDuration) external onlyOwner {
        lottoDuration = newDuration;
    }

    function setCostIncreasePerTimePeriod(uint256 increasePerPeriod) external onlyOwner {
        costIncreasePerTimePeriod = increasePerPeriod;
    }

    function setTimePeriodForCostIncrease(uint256 newTimePeriod) external onlyOwner {
        timePeriodForCostIncrease = newTimePeriod;
    }

    function setRollOverPercent(uint256 rollOverPercentage_) external onlyOwner {
        require(
            rollOverPercentage_ <= 80,
            'Roll Over Percentage Too Large'
        );
        rollOverPercentage = rollOverPercentage_;
    }

    function setCostReceiver(address newReceiver) external onlyOwner {
        ticketCostCollector = newReceiver;
    }



    function getTickets(uint256 numTickets) external {

        // get cost
        uint cost = numTickets * currentTicketCost();
        address user = msg.sender;

        // increment amount spent
        unchecked {
            userInfo[user].amountSpent += cost;   
        }

        // amount received
        uint256 received = _transferIn(xGrape, cost);
        require(
            received >= ( cost * 90 ) / 100,
            'Too Few Received'
        );

        unchecked {
            totalxGrapeUsedToBuyTickets += received;
        }

        // burn portion of received amount
        _giveToCollector();

        // increment the number of tickets purchased for the user at the current lotto ID
        unchecked {
            userTickets[user][currentLottoID] += numTickets;
        }
        
        // Assign Ticket IDs To User
        for (uint i = 0; i < numTickets;) {
            ticketToUser[currentTicketID] = user;
            unchecked { currentTicketID++; ++i; }
        }
    }

    function newLotto() external {
        require(
            lastLottoStartTime > 0,
            'Lotto Has Not Been Initialized'
        );
        require(
            timeUntilNewLotto() == 0,
            'Not Time For New Lotto'
        );

        // start a new lotto, request random words
        _newGame();        
    }


    /**
        Registers A New Game
        Changes The Day Timer
        Distributes Pot
     */
    function _newGame() internal {

        // reset day timer
        lastLottoStartTime = block.timestamp;

        // get random number and send rewards when callback is executed
        // the callback is called "fulfillRandomWords"
        // this will revert if VRF subscription is not set and funded.
        COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            3, // number of block confirmations before returning random value
            gasToCallRandom, // callback gas limit is dependent num of random values & gas used in callback
            1 // the number of random results to return
        );
    }

    function _transferIn(address token, uint256 amount) internal returns (uint256) {
        require(
            IERC20(token).allowance(msg.sender, address(this)) >= amount,
            'Insufficient Allowance'
        );
        uint256 before = IERC20(token).balanceOf(address(this));
        require(
            IERC20(token).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'FAIL TRANSFER FROM'
        );
        uint256 After = IERC20(token).balanceOf(address(this));
        require(
            After > before,
            'Zero Received'
        );
        return After - before;
    }

    function _giveToCollector() internal {
        _send(xGrape, ticketCostCollector, IERC20(xGrape).balanceOf(address(this)));
        ITicketReceiver(ticketCostCollector).trigger();
    }

    function _send(address token, address to, uint amount) internal {
        if (token == address(0) || to == address(0) || amount == 0) {
            return;
        }
        IERC20(token).transfer(to, amount);
    }


    /**
        Chainlink's callback to provide us with randomness
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {

        // reset current lotto timer if no tickets have been purchased
        if (currentTicketID == 0) {
            lastLottoStartTime = block.timestamp;
            return;
        }

        // select the winner based on the random number generated
        uint256 winningTicket = randomWords[0] % currentTicketID;
        address winner = ticketToUser[winningTicket];

        // size of the pot
        uint256 pot = amountToWin();

        // save history
        lottoHistory[currentLottoID].winner = winner;
        lottoHistory[currentLottoID].amountWon = pot;
        lottoHistory[currentLottoID].winningTicket = winningTicket;
        lottoHistory[currentLottoID].timestamp = block.timestamp;

        // reset lotto time again
        lastLottoStartTime = block.timestamp;
        
        // increment the current lotto ID
        currentLottoID++;
        
        // give winner
        if (winner != address(0)) {

            // increment total rewarded
            unchecked {
                totalRewarded += pot;
                userInfo[winner].amountWon += pot;
                userInfo[winner].numberOfWinningTickets++;
            }

            // Send winner the pot
            _send(xGrape, winner, pot);

            // Emit Winning Event
            emit WinnerChosen(winner, pot, winningTicket);

        }
        
        // reset ticket IDs back to 0
        delete currentTicketID;
    }

    function amountToWin() public view returns (uint256) {
        return ( balanceOf() * ( 100 - rollOverPercentage ) ) / 100;
    }

    function currentTicketCost() public view returns (uint256) {
        uint256 epochsSinceLastLotto = block.timestamp > lastLottoStartTime ? ( block.timestamp - lastLottoStartTime ) / timePeriodForCostIncrease : 0;
        return startingCostPerTicket + ( epochsSinceLastLotto * costIncreasePerTimePeriod );
    }

    function timeUntilNewLotto() public view returns (uint256) {
        uint endTime = lastLottoStartTime + lottoDuration;
        return block.timestamp >= endTime ? 0 : endTime - block.timestamp;
    }

    function getOdds(address user) public view returns (uint256, uint256) {
        return (userTickets[user][currentLottoID], currentTicketID);
    }

    function getPastWinners(uint256 numWinners) external view returns (address[] memory) {
        address[] memory winners = new address[](numWinners);
        if (currentLottoID < numWinners || numWinners == 0) {
            return winners;
        }
        uint count = 0;
        for (uint i = currentLottoID - 1; i > currentLottoID - ( 1 + numWinners);) {
            winners[count] = lottoHistory[i].winner;
            unchecked { --i; count++; }
        }
        return winners;
    }

    function getPastWinnersAndAmounts(uint256 numWinners) external view returns (address[] memory, uint256[] memory) {
        address[] memory winners = new address[](numWinners);
        uint256[] memory amounts = new uint256[](numWinners);
        if (currentLottoID < numWinners || numWinners == 0) {
            return (winners, amounts);
        }
        uint count = 0;
        for (uint i = currentLottoID - 1; i > currentLottoID - ( 1 + numWinners);) {
            winners[count] = lottoHistory[i].winner;
            amounts[count] = lottoHistory[i].amountWon;
            unchecked { --i; count++; }
        }
        return (winners, amounts);
    }

    function getPastWinnersAmountsAndTimes(uint256 numWinners) external view returns (address[] memory, uint256[] memory, uint256[] memory) {
        address[] memory winners = new address[](numWinners);
        uint256[] memory amounts = new uint256[](numWinners);
        uint256[] memory times = new uint256[](numWinners);
        if (currentLottoID < numWinners || numWinners == 0) {
            return (winners, amounts, times);
        }
        uint count = 0;
        for (uint i = currentLottoID - 1; i > currentLottoID - ( 1 + numWinners);) {
            winners[count] = lottoHistory[i].winner;
            amounts[count] = lottoHistory[i].amountWon;
            times[count] = lottoHistory[i].timestamp;
            unchecked { --i; count++; }
        }
        return (winners, amounts, times);
    }

    function balanceOf() public view returns (uint256) {
        return IERC20(xGrape).balanceOf(address(this));
    }

    receive() external payable{}
}