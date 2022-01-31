/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-31
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Interfaces/ISquidToken.sol


pragma solidity >=0.8.0;


interface ISquidToken is IERC20 {
    
}
// File: contracts/SquidBets.sol


pragma solidity >=0.8.0;



contract SquidBets {
    //create and store bets
    //update bet maker and taker balances
    //handle payouts
    //return users bets data

    string public name = "SquidBets Contract";

    //chainlink interface
    AggregatorV3Interface internal priceFeed;

    event BetCreated (uint betValue, uint refPrice, uint readyTime, bool isHigher, address betMaker, address betTaker);
    event BetAccepted(uint betValue, uint refPrice, uint readyTime, bool isHigher, address betMaker, address betTaker);

    address public squidTokenAddr;

    constructor(address _squidTokenAddr) {
        squidTokenAddr = _squidTokenAddr;

        //kovan
        //priceFeed = AggregatorV3Interface(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e)

        //fuji
        priceFeed = AggregatorV3Interface(0x31CF013A08c6Ac228C94551d535d5BAfE19c602a);
    }

    struct Bet {
        uint    betValue;
        uint    refPrice;
        uint    readyTime;
        bool    isHigher;
        bool    isActive;
        bool    isClosed;
        address betMaker;
        address betTaker;
    }

    Bet[] public bets;

    mapping (address => uint) betcountOf;
    
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function makesBet(uint _betValue, uint _readyTime, bool _isHigher) external {
        //require sender has enough squid to make this bet
        require(_betValue <= ISquidToken(squidTokenAddr).balanceOf(msg.sender));

        //transfer tokens to SquidBets contract to be held in Escrow
        ISquidToken(squidTokenAddr).transferFrom(msg.sender, address(this), _betValue);

        //get current bitcoin price SECURELY
        uint _refPrice = uint(getLatestPrice());

        //add bet to bets arr
        bets.push(Bet(  _betValue, 
                        _refPrice, 
                        _readyTime,
                        _isHigher, 
                        false, 
                        false, 
                        msg.sender, 
                        address(0)));

        //increment bet count at 
        betcountOf[msg.sender]++;                                                                               //increment bets count for this account

        emit BetCreated(_betValue, _refPrice, _readyTime, _isHigher, msg.sender, address(0));                   //emit BetCreated() event
    }

    function takesBet(uint _atIndex) external {
        Bet storage bet = bets[_atIndex];                                   //get reference to Bet{} at given index
        require(bet.isActive == false);                                     //bet must be open (not yet active)
        require(bet.isClosed == false);                                     //bet must be open (not yet closed)
        require(bet.betValue <= ISquidToken(squidTokenAddr).balanceOf(msg.sender));          //bet value must be less than senders token balance  

        //approve tokens via front-end (requires betValue to be known)
        ISquidToken(squidTokenAddr).transferFrom(msg.sender, address(this), bet.betValue);   //transfer tokens to SquidBets to be held in Escrow

        bet.betValue +=bet.betValue;                                        //set new value
        bet.betTaker = msg.sender;                                          //set betTaker 
        bet.isActive = true;                                                //set bet status to active      //create and add bet to bets array
        betcountOf[msg.sender]++;
        
        emit BetAccepted(bet.betValue, bet.refPrice, bet.readyTime, bet.isHigher, bet.betMaker, bet.betTaker);  //emit BetAccepted() event
    }

    function cancelBet(uint _atIndex) external {
        Bet storage bet = bets[_atIndex];
        require(bet.betMaker == msg.sender);
        require(bet.isActive == false);
        require(bet.isClosed == false);

        //mark bet as closed
        bet.isClosed = true;

        //reimburse tokens to betmaker
        ISquidToken(squidTokenAddr).transfer(bet.betMaker, bet.betValue);
    }

    modifier isReady(uint _atIndex) {
        //get copy of bet{} held in storage
        Bet memory bet  = bets[_atIndex];

        //bet must be ready to resolve
        require(bet.readyTime <= block.timestamp);

        //continue
        _;
    }

    function checkWinner(uint _atIndex) isReady(_atIndex) external view returns (bool) {
        //get copy of bet{} held in storage
        Bet memory bet    = bets[_atIndex];

        //get current bitcoin price SECURELY
        uint currentPrice = uint(getLatestPrice());

        //get winner
        bool    isHigher  = currentPrice > bet.refPrice;
        address winner    = isHigher == bet.isHigher ? bet.betMaker : bet.betTaker;

        //get isWinner
        bool    isWinner  = winner == msg.sender ? true : false;

        //
        return  isWinner;
    }

    function claimBet(uint _atIndex) isReady(_atIndex) external {
        //get copy of bet{} held in storage
        Bet memory bet    = bets[_atIndex];
        require(bet.isActive == true);
        require(bet.isClosed == false);

        //get current bitcoin price SECURELY
        uint currentPrice = uint(getLatestPrice());

        //get winner
        bool    isHigher  = currentPrice > bet.refPrice;
        address winner    = isHigher == bet.isHigher ? bet.betMaker : bet.betTaker;
        
        //transfer tokens to winner
        payoutTo(winner, bet.betValue);

        //update bet{} in memory
        bet.isActive  = false;
        bet.isClosed  = true;

        //update bet{} in storage
        bets[_atIndex]= bet;
    }

    function payoutTo(address _payee, uint _amount) private {
        //transfer tokens to winner
        ISquidToken(squidTokenAddr).transfer(_payee, _amount);
    }

    function getBet(uint _atIndex) external view returns(Bet memory) {          //return Bet{} at given index
        return bets[_atIndex];
    }

    function getBets() external view returns(Bet[] memory) {                    //returns bets array
        return bets;
    }

    function getBetsFor(address _user) external view returns(Bet[] memory) { //returns bets array filtered by user's address
        Bet[] memory result = new Bet[](betcountOf[_user]);                  //declare new Bet[] w/ length of user's betcount

        uint index  = 0;                                                     //builds an array of bets made by this user
        for (uint i = 0; i < bets.length; i++) {
            if( bets[i].betMaker == _user || bets[i].betTaker == _user ) {
                result[index] = bets[i];
                index++;
            }
        }
        return result;                  
    }
}