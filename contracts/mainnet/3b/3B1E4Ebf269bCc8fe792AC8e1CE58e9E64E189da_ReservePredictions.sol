/**
 *Submitted for verification at snowtrace.io on 2022-12-13
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


pragma solidity ^0.7.3;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract ReservePredictions {

  using SafeMath for *;

  enum Option {
    Bullish,
    Neutral,
    Bearish
  }

  enum MarketStatus {
    Live,
    Closed
  }

  struct Market {
    MarketStatus state;
    uint startTime;
    uint expireTime;
    uint neutralMinValue;
    uint neutralMaxValue;
    uint settleTime;
    Option winningOption;
    mapping(address => User) users;
    mapping(Option => uint) totalBets;
    uint totalPool;
  }

  struct User {
    bool claimedWinnings;
    mapping(Option => uint) amountStaked;
    uint comission;
  }

  address payable public owner;
  address public operator;
  address public oracle;
  AggregatorV3Interface internal priceFeed;
  bool public marketCreationPaused;
  uint public commissionPercentage = 10;
  uint public optionRangePercentage = 30;
  uint public miniumValue;
  uint public commissionAmount;
  uint public marketCount;
  uint public marketDuration;

  address public dummytoken;

  mapping(uint => Market) public markets;

  event LogNewMarketCreated(uint indexed marketId, uint price);
  event LogBetPlaced(uint indexed marketId, address indexed user, Option option, uint value);
  event LogWinningsClaimed(uint indexed marketId, address indexed user, uint winnings);
  event LogResultPosted(uint indexed marketId, address indexed oracle, Option option);

  /**
  * @dev Modifier that only allows the authorized owner addresses to execute the function.
  */
  modifier onlyOwner() {
    require(msg.sender == owner, "=== Only the owner address can call this function ===");
    _;
  }

  /**
  * @dev Modifier that only allows the authorized operator addresses to execute the function.
  */
  modifier onlyOperator() {
    require(msg.sender == operator, "=== Only the operator address can call this function ===");
    _;
  }

  /**
  * @dev Deploys the smart contract and fires up the first prediction market.
  * @param _oracle Sets the address of the oracle used used as pricefeed. Fantom FTM/USD price oracle = 0xf4766552d15ae4d256ad41b6cf2933482b0680dc.
  * @param _duration Sets the duration of the prediction market cycles, i.e. duration = 15 minutes will make sure that all prediction markets started by this smart contract will be Live for 15 minutes.
  * @param _duration Sets the operator of this contract, i.e Start/Close/Restart Predictions Market
  */
  constructor(address _oracle, uint _duration, address _operator, uint _miniumvalue, address _dummytoken) {
    oracle = _oracle;
    priceFeed = AggregatorV3Interface(oracle);
    owner = msg.sender;
    marketDuration = _duration;
    marketCount = 0;
    operator = _operator;
    dummytoken = _dummytoken;
    miniumValue = _miniumvalue;

    uint _price = getLatestPrice(); //returns latest FTM/USD in the following format: 40345000000 (8 decimals)

    Market storage newMarket = markets[marketCount];
    newMarket.state = MarketStatus.Live;
    newMarket.startTime = block.timestamp;
    newMarket.expireTime = newMarket.startTime.add(marketDuration);
    newMarket.settleTime = newMarket.expireTime.sub(60);
    newMarket.neutralMinValue = _price.sub(_calculatePercentage(optionRangePercentage, _price, 10000));
    newMarket.neutralMaxValue = _price.add(_calculatePercentage(optionRangePercentage, _price, 10000));
  }

  /**
  * @dev Places a bet amount on a specific bet option in the prediction market that is currently Live.
  * @param _option The specific bet option for which this function is called, i.e. Bullish, Neutral, or Bearish.
  */
  function placeBet(Option _option, uint256 amount) external {
    require(getMarketStatus(marketCount) == MarketStatus.Live, "The Predection Market is not Live");
    
    Market storage m = markets[marketCount];
    require(block.timestamp < m.settleTime, "The Predection Market is not Live - InSettlement");
    require(amount > 0,"=== Your bet should be greater than 0 ===");
    require(amount > miniumValue, "Your bet should be greater than minium");


    IERC20(dummytoken).transferFrom(address(msg.sender), address(this), amount);

    uint _predictionStake = amount;
    uint _commissionStake = _calculatePercentage(commissionPercentage, _predictionStake, 1000);
    commissionAmount = commissionAmount.add(_commissionStake);
    _predictionStake = _predictionStake.sub(_commissionStake);
    m.users[msg.sender].comission = m.users[msg.sender].comission.add(commissionAmount);

    m.totalBets[_option] = m.totalBets[_option].add(_predictionStake);
    m.users[msg.sender].amountStaked[_option] = m.users[msg.sender].amountStaked[_option].add(_predictionStake);
    m.totalPool = m.totalPool.add(_predictionStake);

    emit LogBetPlaced(marketCount, msg.sender, _option, _predictionStake);
  }

  /**
  * @dev Closes the prediction market that is currently Opened.
  */
  function closeMarket() external onlyOperator {
    require(getMarketStatus(marketCount) == MarketStatus.Live, "The Predection Market is not Live");
    Market storage m = markets[marketCount];

    (uint _price, ) = getClosedPrice(m.expireTime);

    if(_price < m.neutralMinValue) {
      m.winningOption = Option.Bearish;
    } else if(_price > m.neutralMaxValue) {
      m.winningOption = Option.Bullish;
    } else {
      m.winningOption = Option.Neutral;
    }

    emit LogResultPosted(marketCount, msg.sender, m.winningOption);
    m.state = MarketStatus.Closed;
  }

  /**
  * @dev Restart - Close And Create - the prediction market that is currently Opened.
  */
  function restartMarket() external onlyOperator {
    require(getMarketStatus(marketCount) == MarketStatus.Live, "The Predection Market is not Live");
    Market storage m = markets[marketCount];

    (uint _price, ) = getClosedPrice(m.expireTime);

    if(_price < m.neutralMinValue) {
      m.winningOption = Option.Bearish;
    } else if(_price > m.neutralMaxValue) {
      m.winningOption = Option.Bullish;
    } else {
      m.winningOption = Option.Neutral;
    }

    emit LogResultPosted(marketCount, msg.sender, m.winningOption);
    m.state = MarketStatus.Closed;

    marketCount = marketCount.add(1);

    uint _pricenew = getLatestPrice(); //returns latest FTM/USD in the following format: 40345000000 (8 decimals)

    Market storage newMarket = markets[marketCount];
    newMarket.state = MarketStatus.Live;
    newMarket.startTime = block.timestamp;
    newMarket.expireTime = newMarket.startTime.add(marketDuration);
    newMarket.settleTime = newMarket.expireTime.sub(60);
    newMarket.neutralMinValue = _pricenew.sub(_calculatePercentage(optionRangePercentage, _pricenew, 10000));
    newMarket.neutralMaxValue = _pricenew.add(_calculatePercentage(optionRangePercentage, _pricenew, 10000));

    emit LogNewMarketCreated(marketCount, _pricenew);
  }


  /**
  * @dev Creates a new prediction market (after the previous one was closed).
  * @return success Returns whether the market creation was successful.
  */
  function createNewMarket() public onlyOperator returns(bool success) {
    require(getMarketStatus(marketCount) == MarketStatus.Closed, "The Predection Market is not Closed");
    require(!marketCreationPaused, "=== The owner has paused market creation ===");
    marketCount = marketCount.add(1);

    uint _price = getLatestPrice(); //returns latest FTM/USD in the following format: 40345000000 (8 decimals)

    Market storage newMarket = markets[marketCount];
    newMarket.state = MarketStatus.Live;
    newMarket.startTime = block.timestamp;
    newMarket.expireTime = newMarket.startTime.add(marketDuration);
    newMarket.settleTime = newMarket.expireTime.sub(60);
    newMarket.neutralMinValue = _price.sub(_calculatePercentage(optionRangePercentage, _price, 10000));
    newMarket.neutralMaxValue = _price.add(_calculatePercentage(optionRangePercentage, _price, 10000));

    emit LogNewMarketCreated(marketCount, _price);

    return true;
  }

  /**
  * @dev Calculates the winnings for a specific user in the prediction market.
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @param _user The specific user address for which this function is called.
  * @return winnings Returns the total amount that has been won by a specific user address in the prediction market.
  */
  function calculateWinnings(uint _marketId, address _user) public view returns(uint winnings) {
    Market storage m = markets[_marketId];
    uint winningBet = m.users[_user].amountStaked[m.winningOption];
    uint winningTotal = m.totalBets[m.winningOption];
    uint loserPool = m.totalPool.sub(winningTotal);
    if(winningTotal == 0) {
      winnings = 0;
    }else{
    winnings = loserPool.mul(winningBet).div(winningTotal);
    winnings = winnings.add(winningBet);
    }
    return winnings;
  }

  /**
  * @dev Allows the calling user address to withdraw his/her winnings in the prediction market, after this is closed.
  * @param _marketId The id of the prediction market instance on which this function is called.
  */
  function withdrawWinnings(uint _marketId) external {
    Market storage m = markets[_marketId];
    require(m.users[msg.sender].claimedWinnings == false, "=== You already claimed your winnings for this market :( ===");
    require(getMarketStatus(_marketId) == MarketStatus.Closed, "The Predection Market is not Closed");

    uint winningBet = m.users[msg.sender].amountStaked[m.winningOption];
    require(winningBet > 0, "=== You have no bets on the winning option :( ===");

    uint winnings = calculateWinnings(_marketId, msg.sender);
   
    if(winningBet != 0 && winnings == winningBet) {
      winnings = winningBet.add(m.users[msg.sender].comission);
    }

    m.users[msg.sender].claimedWinnings = true;
    IERC20(dummytoken).transferFrom(address(this), address(msg.sender), winnings);

    emit LogWinningsClaimed(_marketId, msg.sender, winnings);
  }

  /**
  * @dev Gets the latest/current asset price (e.g. FTM/USD) from the configured pricefeed oracle.
  * @return latestPrice Returns the latest/current asset price (e.g. FTM/USD) from the configured pricefeed oracle.
  */
  function getLatestPrice() public view returns (uint latestPrice) {
    (uint80 roundId, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
    // If the round is not complete yet, timestamp is 0
    require(timeStamp > 0, "Round not complete");
    return uint256(price);
  }

  /*
  * @dev Gets the historical asset price (e.g. FTM/USD) at prediction market screettlement time from the configured pricefeed oracle.
  * @param _expireTime The prediction market closed timestamp, for which an historical asset price should be returned.
  * @return closePrice Returns the historical asset price (e.g. FTM/USD) at prediction market closed time from the configured pricefeed oracle.
  * @return roundId Returns the matching roundId from the configured pricefeed oracle, for the historical asset price.
  */
  function getClosedPrice(uint _expireTime) public view returns(uint closedPrice, uint roundId) {
    uint80 currentRoundId;
    int currentRoundPrice;
    uint currentRoundTimeStamp;
    (currentRoundId, currentRoundPrice, , currentRoundTimeStamp, ) = priceFeed.latestRoundData();
      while(currentRoundTimeStamp > _expireTime) {
        currentRoundId--;
        (currentRoundId, currentRoundPrice, , currentRoundTimeStamp, ) = priceFeed.getRoundData(currentRoundId);
        if(currentRoundTimeStamp <= _expireTime) {
          break;
        }
      }
    return (uint(currentRoundPrice), currentRoundId);
  }

  /**
  * @dev Gets the status of the prediction market.
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @return status Returns the updated status of the prediction market.
  */
  function getMarketStatus(uint _marketId) public view returns(MarketStatus status){
    Market storage m = markets[_marketId];
      return m.state;
  }

  /**
  * @dev Gets the prediction market start timestamp (as seconds since unix epoch).
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @return startTime Returns the start time of the prediction market.
  */
  function getMarketStartTime(uint _marketId) public view returns(uint startTime) {
    Market storage m = markets[_marketId];
    return m.startTime;
  }

  /**
  * @dev Gets the prediction market expire timestamp (as seconds since unix epoch). After the expiry of the prediction market users can no longer place bets.
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @return expireTime Returns the expire time of the prediction market.
  */
  function getMarketExpireTime(uint _marketId) public view returns(uint expireTime) {
    Market storage m = markets[_marketId];
    return m.expireTime;
  }

  /*
  * @dev Gets the prediction market settletime timestamp (as seconds since unix epoch). After the expiry of the prediction market users can no longer place bets.
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @return settleTime Returns the settle time of the prediction market.
  */
  function getMarketSettleTime(uint _marketId) public view returns(uint expireTime) {
    Market storage m = markets[_marketId];
    return m.settleTime;
  }

  /**
  * @dev Gets the prediction market neutral minimum price value. The neutral minimum price value forms the lower bound of the Neutral betting option.
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @return minValue Returns the neutral minimum price value of the prediction market.
  */
  function getNeutralMinValue(uint _marketId) public view returns(uint minValue) {
    Market storage m = markets[_marketId];
    return m.neutralMinValue;
  }

  /**
  * @dev Gets the prediction market neutral maximum price value. The neutral maximum price value forms the upper bound of the Neutral betting option.
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @return maxValue Returns the neutral maximum price value of the prediction market.
  */
  function getNeutralMaxValue(uint _marketId) public view returns(uint maxValue) {
    Market storage m = markets[_marketId];
    return m.neutralMaxValue;
  }

  /**
  * @dev Gets the winning option after prediction market closed.
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @return winner Returns the winning option, i.e. Bullish, Neutral, or Bearish.
  */
  function getWinningOption(uint _marketId) public view returns(Option winner) {
    Market storage m = markets[_marketId];
    return m.winningOption;
  }

  /**
  * @dev Gets the total amount that has been staked on all bet options together in the prediction market.
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @return totalPool Returns the total amount that has been staked on all bet options together in the prediction market.
  */
  function getMarketTotalPool(uint _marketId) public view returns(uint totalPool) {
    Market storage m = markets[_marketId];
    return m.totalPool;
  }

  /**
  * @dev Gets the total amount that has been staked on a specific bet option in the prediction market.
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @param _option The specific bet option for which this function is called, i.e. Bullish, Neutral, or Bearish.
  * @return totalBets Returns the total amount that has been staked on a specific bet option in the prediction market.
  */
  function getMarketTotalBets(uint _marketId, Option _option) public view returns(uint totalBets) {
    Market storage m = markets[_marketId];
    return m.totalBets[_option];
  }

  /**
  * @dev Gets a boolean value returning whether a specific user address has already claimed his/her winnings in the predition market.
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @param _user The specific user address for which this function is called.
  * @return claimed Returns whether a specific user address has already claimed his/her winnings in the predition market.
  */
  function getUserClaimedWinnings(uint _marketId, address _user) public view returns(bool claimed) {
    Market storage m = markets[_marketId];
    return m.users[_user].claimedWinnings;
  }

  /**
  * @dev Gets the total amount that has been staked by a specific user address on a specific bet option in the prediction market.
  * @param _marketId The id of the prediction market instance on which this function is called.
  * @param _user The specific user address for which this function is called.
  * @param _option The specific bet option for which this function is called, i.e. Bullish, Neutral, or Bearish.
  * @return amountStaked Returns the total amount that has been staked by a specific user address on a specific bet option in the prediction market.
  */
  function getUserAmountStaked(uint _marketId, address _user, Option _option) public view returns(uint amountStaked) {
    Market storage m = markets[_marketId];
    return m.users[_user].amountStaked[_option];
  }

  /*
  * @dev Sets the marketDuration.
  * @return Only callable by the owner.
  */
  function setMarketDuration(uint _marketDuration) external onlyOwner {
    marketDuration = _marketDuration;
  }

  /*
  * @dev Sets the commissionPercentage.
  * @return Only callable by the owner.
  */
  function setComissionPercentage(uint _amount) external onlyOwner {
    commissionPercentage = _amount;
  }

  /*
  * @dev Sets the optionRangePercentage.
  * @return Only callable by the owner.
  */
  function setOptionPercentage(uint _amount) external onlyOwner {
    optionRangePercentage = _amount;
  }

  /*
  * @dev Sets the miniumValue.
  * @return Only callable by the owner.
  */
  function setMiniumValue(uint _amount) external onlyOwner {
    miniumValue = _amount;
  }

  /*
  * @dev Sets the commissionPercentage.
  * @return Only callable by the owner.
  */
  function setOperator(address _operator) external onlyOwner {
    operator = _operator;
  }
   
  /*
  * @dev Withdraw amount of comission in the contract
  */
  function withdrawComissionAmount(uint _amount) external onlyOwner {
    msg.sender.transfer(_amount);
    commissionAmount = commissionAmount.sub(_amount);
  }

  /*
  * @dev Withdraw all amount of comission in the contract
  */
  function withdrawComissionAmount() external onlyOwner {
    msg.sender.transfer(commissionAmount);
    commissionAmount = 0;
  }


  /*
  * @dev Gets the current balance of the smart contract.
  * @return balance Returns the current balance of the smart contract.
  */
  function getContractBalance() public view returns(uint balance) {
    return address(this).balance;
  }

  /*
  * @dev Helper function to get the percentage value for a given input value.
  * @param _percent The percentage value.
  * @param _value The input value.
  * @param _divisor The divisor value.
  * @return The percentage value for a given input value.
  */
  function _calculatePercentage(uint256 _percent, uint256 _value, uint256 _divisor) internal pure returns(uint256) {
    return _percent.mul(_value).div(_divisor);
  }

  /**
  * @dev Updates the address of the pricefeed oracle (e.g. the ChainLink FTM/USD pricefeed oracle).
  * @param _oracle The new address of the pricefeed oracle.
  */
  function updateOracleAddress(address _oracle) external onlyOwner {
    oracle = _oracle;
  }

  /**
  * @dev Updates the flag to pause market creation, in case of issues.
  */
  function pauseMarketCreation() external onlyOwner {
    require(!marketCreationPaused);
    marketCreationPaused = true;
  }

  /**
  * @dev Updates the flag to resume market creation, when issues are solved.
  */
  function resumeMarketCreation() external onlyOwner {
    require(marketCreationPaused);
    marketCreationPaused = false;
  }

  /**
  * @dev Destroys the smart contract instance and sends all remaining Ether stored in the smart contract to the owner address.
  */
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  fallback () external payable {
    revert("=== Please use the dedicated functions to place bets and/or transfer ether into this smart contract ===");
  }

  receive() external payable {
    revert("=== Please use the dedicated functions to place bets and/or transfer ether into this smart contract ===");
  }

}