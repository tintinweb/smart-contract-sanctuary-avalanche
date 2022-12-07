/**
 *Submitted for verification at snowtrace.io on 2022-12-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity 0.8.14;

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

pragma solidity 0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

pragma solidity 0.8.14;

interface ITicketReceiver {
    function trigger() external;
}

contract xCirclePrizePool is Ownable, VRFConsumerBaseV2 {

    // Constant Contracts
    address public constant xCircle = 0x6FC352270c3e15154F9AEBCE3e44c51524d1E0d8;
    address public constant circle = 0xaba658AB5FFA292e3DF464dE5cB141c7de83DB6D;
    address public constant cbond = 0x18C527B5c00F2Eb6a3fa929ae8689769d2ceC943;

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
    uint256 public totalCBond;
    uint256 public totalCircle;

    // Ticket Cost Collector
    address public ticketCostCollector;

    // Lotto Details
    uint256 public startingCostPerTicket = 1 * 10**18;
    uint256 public costIncreasePerTimePeriod = 1 * 10**17;
    uint256 public timePeriodForCostIncrease = 1 days;
    uint256 public lottoDuration = 7 days;

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

    constructor() VRFConsumerBaseV2(0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634) {
        // setup chainlink
        keyHash = 0x83250c5584ffa93feb6ee082981c5ebe484c865196750b39835ad4f13780435d;
        COORDINATOR = VRFCoordinatorV2Interface(0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634);
        s_subscriptionId = 77;
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



    function getTickets(address token, uint256 numTickets) external {

        // get cost
        uint cost = numTickets * currentTicketCost();
        address user = msg.sender;

        // increment amount spent
        unchecked {
            userInfo[user].amountSpent += cost;   
        }

        // amount received
        uint256 received = _transferIn(token, cost);
        require(
            received >= ( cost * 90 ) / 100,
            'Too Few Received'
        );

        if (token == circle) {
            unchecked { totalCircle += received; }
        } else if (token == cbond) {
            unchecked { totalCBond += received; }
        } else {
            revert('Invalid Token');
        }

        // burn portion of received amount
        _giveToCollector(token);

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

    function _giveToCollector(address token) internal {
        _send(token, ticketCostCollector, IERC20(token).balanceOf(address(this)));
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
            _send(xCircle, winner, pot);

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
        return IERC20(xCircle).balanceOf(address(this));
    }

    receive() external payable{}
}