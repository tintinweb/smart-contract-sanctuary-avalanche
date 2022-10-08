/**
 *Submitted for verification at snowtrace.io on 2022-10-08
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.3/contracts/security/ReentrancyGuard.sol



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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: BeautyEggVotr.sol

/* ____ _     _ _            ___       ____                   _   _  __       _ 
  / ___| |__ (_) | ___ __   |_ _|___  | __ )  ___  __ _ _   _| |_(_)/ _|_   _| |
 | |   | '_ \| | |/ / '_ \   | |/ __| |  _ \ / _ \/ _` | | | | __| | |_| | | | |
 | |___| | | | |   <| | | |  | |\__ \ | |_) |  __/ (_| | |_| | |_| |  _| |_| | |
  \____|_| |_|_|_|\_\_| |_| |___|___/ |____/ \___|\__,_|\__,_|\__|_|_|  \__,_|_|
                                                                                */
//Octo's Chikn Beauty Pageant voting; Contract written by @0xJelle ; Bok bok!;

//Right after minting this Votr contract we have to set it's companion Postr contract to allow access with 12.setVoterContractAddress ; 
//and vice versa with votr contract. Approve all voters in $egg contract with dapp to 1000000000000000000000000000 eggWei or 1 billion egg for max approval, or let user customize too

pragma solidity ^0.8.0;






interface IeggContract {//Chikn's $Egg contract to move $egg for voting and prize wallet
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); //transfer users egg to prize wallet now
  function allowance(address owner, address spender) external returns (uint);//check allowance of egg we can ssend from user
}

//the testnet version of egg burn partner contract is different for both below btw
interface IeggBurnPartner { //Hen Solo contract to burn Chikn $egg from msg.sender
  function burnEgg(string calldata _name, uint256 _amount, string calldata _correlationId) external; //burn egg through egg burn partner contract
  function subscribe(string calldata _name) external; //subscribe contestant burnID
}

interface IVotrPostrMintr {//voters mint postrs with each new candidate voted for
  function voterMint(address recipient, uint _numberedContestantID) external;
}

interface Ierc20Token {//generic ability to transfer out funds accidentally sent into the contract
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transfer(address to, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

interface Ierc721Token {//generic ability to transfer out NFTs accidentally sent into the contract
  function transferFrom(address from, address to, uint256 tokenId) external; 
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function safeTransfer(address from, address to, uint256 tokenId) external;
  function transfer(address from, address to, uint256 tokenId) external;
}

//end of interfaces

contract BeautyPageantVotingMainnet is Ownable, ReentrancyGuard 
{
  using Counters for Counters.Counter;
  using SafeMath for uint; // 

  Counters.Counter private _tokenIds;

  address public EggContract = 0x7761E2338B35bCEB6BdA6ce477EF012bde7aE611; //Currently set to Mainnet
  //egg contract mainnet: 0x7761E2338B35bCEB6BdA6ce477EF012bde7aE611
  //egg contract testnet: 0x252e1137a18900C72fEC17B88825D32d08b2A4b4
  address public EggBurnPartner = 0x81ADaa2b115c4921f3Cc412A05F9Caa521b4e1AC; //Currently set to Mainnet
  //eggBurnPartner mainnet: 0x81ADaa2b115c4921f3Cc412A05F9Caa521b4e1AC
  //eggBurnPartner testnet: 0x676C7ddcEC36edf7c1290CeEed3AeE696a8f57c1
  address public prizeWalletAddress = 0xD5197D4031a6CCd16B4043260519323EBF6AD87a;//starts with this prize wallet address
  //address public noopAddress = 0x0000000000000000000000000000000000000001;//1 address for egg burn partner contract no callback needed
  address public votePostrsAddress = 0x58e628ccF9B4174f0C278BB898314cD002A36F31;//this is current testnet address//contract address of our external postr nft smart contract


  mapping (uint => string) public NumberedIDstoIDString;//can map 1-32 contestant to their subscriber ID
  mapping (string => uint) public IDStringToNumberedIDs;//can map subscriber ID to 1-32 contestant

/// Counting votes with these methods
  mapping (address => mapping (uint => uint)) public addressTotalVotesForIdNumber; // count votes from address of voter for a particular candidate by ID number, for postr first vote
  mapping (string => uint) public totalVotesForCandidateIDName;//count all votes for a candidate id name
  mapping (address => uint) public totalVotesFromVoterAddress; // count all votes from a voter address


  uint public eggBurntTotalWei;//total burned by everyone
  uint public prizeMoneyTotalWei;//total prize money sent by everyone
  uint public allVotesTotalBase;//total votes by everyone
///

  uint public startofVotingTime;
  uint public endofVotingTime;  
  uint public prizePercentage = 20;//starts with 20% of votes to prize wallet, 80% will be burned
  uint public maxNumberOfIDs = 32;//max number of contestants can vote on

  bool public noBotsCanVote = true;//not sure why we would want to let bots in, so seems safer to turn off bot voting for now
  bool public _pauseVotingBool = false;//pauses voting

  constructor() {}//No constructor needed

  event emitVoted(address indexed _from, string indexed _id, uint _value);

  string correlationIDVal = "OctoBeautyBurn";
////modifiers: 

  modifier timeNotStarted{
    require (startofVotingTime>0, "Start time is not yet set");
    require(block.timestamp>startofVotingTime, "Voting has not started yet.");
    _;
  }

  modifier timeIsOver{
    require (endofVotingTime>0, "End time is not yet set");
    require(block.timestamp<endofVotingTime,"Voting has ended");
    _;
  }



////public functions:

  function votingTimeLeftBlockTimestamp() public view timeNotStarted timeIsOver returns(uint){
    return(endofVotingTime-block.timestamp);
  }

  function checkMsgSenderEggVoteAllowance() public returns(uint){ //check how much of user egg this contract can spend
    return (IeggContract(EggContract).allowance(msg.sender,address(this)));
  }



////onlyOwner functions:
//Ownership could be transferred to a multisig wallet

  function testEggTransferFromMsgSenderWei(uint _testEggTotal) public onlyOwner {//if we are approved by dapp first we should be able to do this 
    uint _eggsAllowance = checkMsgSenderEggVoteAllowance();
    require (_eggsAllowance >= (_testEggTotal), "Must approve more egg first. Bgok");
    IeggContract(EggContract).transferFrom(msg.sender, prizeWalletAddress, _testEggTotal);
  }

  function testEggBurnWei(string memory _CandidateID, uint _testBurnTotal) public onlyOwner { //can only burn egg from the smart contract wallet or let dapp do it, can't burn from a user wallet using a contract directly since egg burn contract looks at msg.sender
    uint _eggsAllowance = checkMsgSenderEggVoteAllowance();
    require (_eggsAllowance >= (_testBurnTotal), "Must approve more egg first. Bgok");
    IeggContract(EggContract).transferFrom(msg.sender, address(this), _testBurnTotal); //so we first transfer to our contracts own wallet
    IeggBurnPartner(EggBurnPartner).burnEgg(_CandidateID,_testBurnTotal, correlationIDVal);//then we burn from our own contracts wallet since it checks msg.sender
  }


  function pauseVoting (bool _bool) public onlyOwner {
      _pauseVotingBool = _bool;
  }


  function setEggBurnPartner(address _newBurnPartnerAddress) public onlyOwner {
    EggBurnPartner = _newBurnPartnerAddress;
  }

  function setEggContract(address _newEggAddress) public onlyOwner {
    EggContract = _newEggAddress;
  }


  function setMaxNumberOfContestants(uint _maxIDs) public onlyOwner{
    maxNumberOfIDs = _maxIDs;
  }




  function subscribeBurnIDNOOP (uint _numberedID, string memory _contestantNewIDString) public onlyOwner {//set a number of 1-32 for candidate
    require (_numberedID <= maxNumberOfIDs, "Numbered ID too high");
    require (_numberedID > 0, "Numbered ID too low");
    NumberedIDstoIDString[_numberedID] = _contestantNewIDString;//mapping to lookup string ID by number ID
    IDStringToNumberedIDs[_contestantNewIDString]= _numberedID;//mapping to lookup number ID by string ID
    IeggBurnPartner(EggBurnPartner).subscribe(_contestantNewIDString);//subscribe the name ID to egg burn partner contract with noop address of 0x00..001
  }


  function setStartAndEndVoteTimes(uint _startTime, uint _endTime) public onlyOwner {//https://www.epochconverter.com/
    require(_startTime<_endTime);
    endofVotingTime = _endTime;
    startofVotingTime = _startTime;

  }

  function setStartVoteTime(uint _startTime) public onlyOwner {
    startofVotingTime = _startTime;
  }

  function startVotingImmediately() public onlyOwner {
    startofVotingTime = block.timestamp;
  }
   
  function setEndofVotingTime(uint _endTime) public onlyOwner{
    endofVotingTime = _endTime;
  }

  function endVotingImmediately() public onlyOwner {
    endofVotingTime = block.timestamp;
  }

  function VoteForOneMinuteNow() public onlyOwner {
    startofVotingTime = block.timestamp;
    endofVotingTime = block.timestamp+60;
  }

  function VoteForOnehourNow() public onlyOwner {
    startofVotingTime = block.timestamp;
    endofVotingTime = block.timestamp+3600;
  }



  
  function setPrizeWalletAddress (address _prizeWalletAddress) public onlyOwner{
    prizeWalletAddress=_prizeWalletAddress;
  }

  function setPrizeWalletPercentage(uint _prizePercentage) public onlyOwner { 
    prizePercentage = _prizePercentage;
  } //If it's 10% vote fee to prize wallet then enter 10 here




  function setNoBotsCanVote (bool _setBotBlock) public onlyOwner{
    noBotsCanVote = _setBotBlock;
  }

////main vote code:

  function voteOneEggForEachCandidate() public returns(bool){
    uint _eggsAllowance = checkMsgSenderEggVoteAllowance();
    require (_eggsAllowance >= (32000000000000000000), "Must approve more egg first. Bgok");
    for(uint i=1; i<=maxNumberOfIDs; i++){
      voteWithEggByCandidateNumber(i,1);
    }
    return true;
  }


  function voteWithEggByCandidateNumber (uint256 _candidateIDNumber, uint256 _amountOfEggVotesBase) 
  public timeNotStarted timeIsOver nonReentrant returns(bool) {
    require (_candidateIDNumber <= maxNumberOfIDs, "Numbered ID too high"); //must pick a candidate number less than or = to 32
    require (_candidateIDNumber > 0, "Numbered ID too low"); //candidate id numbers start at 1
    require (_amountOfEggVotesBase >= 1, "Requires at least 1 $EGG minimum vote");
    if (noBotsCanVote == true){
      require (msg.sender == tx.origin, "No Bots Allowed To Vote Currently");//anti smart contract bot code
    }
    string memory _candidateIDName = NumberedIDstoIDString[_candidateIDNumber];
    uint _amountOfEggVotesWei = _amountOfEggVotesBase * 1000000000000000000;
    uint EggVotesForPrizeWalletNowWei = ((_amountOfEggVotesWei * prizePercentage)/100);
    uint _eggsAllowance = checkMsgSenderEggVoteAllowance();
    require (_eggsAllowance >= (_amountOfEggVotesWei), "Must approve more egg first. Bgok");
    uint EggVotesToBurnNowWei = _amountOfEggVotesWei-EggVotesForPrizeWalletNowWei;
    bool prizeSent = IeggContract(EggContract).transferFrom(msg.sender, prizeWalletAddress, EggVotesForPrizeWalletNowWei);
    IeggContract(EggContract).transferFrom(msg.sender, address(this), EggVotesToBurnNowWei); //so we first transfer to our contracts own wallet
    IeggBurnPartner(EggBurnPartner).burnEgg(_candidateIDName, EggVotesToBurnNowWei, correlationIDVal);//then we burn from our own contracts wallet

    totalVotesForCandidateIDName[_candidateIDName] += _amountOfEggVotesBase;
    eggBurntTotalWei += EggVotesToBurnNowWei;
    prizeMoneyTotalWei += EggVotesForPrizeWalletNowWei;
    allVotesTotalBase += _amountOfEggVotesBase;
    totalVotesFromVoterAddress[msg.sender] += _amountOfEggVotesBase;
    if (addressTotalVotesForIdNumber[msg.sender][_candidateIDNumber] == 0){//if they are a new voter for that ID number then they get a sticker for voting
      IVotrPostrMintr(votePostrsAddress).voterMint(msg.sender, IDStringToNumberedIDs[_candidateIDName]);//send voter wallet and who they voted for of 1-32 contestants
    } 
    addressTotalVotesForIdNumber[msg.sender][_candidateIDNumber] += _amountOfEggVotesBase;
//    checkTopTenIDnumber(totalVotesForCandidateIDName[_candidateIDName], _candidateIDNumber);//update top ten candidate list
//    checkTopTenVoter(totalVotesFromVoterAddress[msg.sender], msg.sender);//update top ten voter list
 
    emit emitVoted(msg.sender, _candidateIDName, _amountOfEggVotesBase);
    return prizeSent;
  }


  function returnTotalVotesForCandidateIDNumber (uint _CandidateIDNumber) public view returns(uint){
    return totalVotesForCandidateIDName[NumberedIDstoIDString[_CandidateIDNumber]];
  }





  function setVotePostrsAddress(address _address) public onlyOwner{
    votePostrsAddress = _address;
  }

  function testMintVotePostrMsgSender(uint _ourNumberedContestantID) public onlyOwner{ //nft test mint
    IVotrPostrMintr(votePostrsAddress).voterMint(msg.sender, _ourNumberedContestantID);
  }







////fallback function and generic transfer functions on case of accidental deposit into contract wallet
  fallback() external payable {}

  receive() external payable {}


  function withdrawlsAvax(address payable _to, uint _amount) public payable onlyOwner {
    _to.transfer(_amount);//this can only send Avax from our own contract's wallet, user's wallet is safe
  }


  function Ierc20TokenTransferFrom(address _contract, address _recipient, uint256 _amount) external onlyOwner returns (bool){
    return Ierc20Token(_contract).transferFrom(address(this), _recipient, _amount);//can only transfer from our own contract's wallet
  }

  function Ierc20TokenTransfer(address _contract, address _to, uint256 _amount) external onlyOwner returns (bool){
    return Ierc20Token(_contract).transfer(_to, _amount);//since interfaced contract looks at msg.sender then this can only send from our own contract's wallet
  }

  function Ierc20TokenApprove(address _contract, address _spender, uint256 _amount) external onlyOwner returns (bool){
    return Ierc20Token(_contract).approve(_spender, _amount);//since interfaced contract looks at msg.sender then this can only send from our own contract's wallet
  }


  function Ierc721TokenGenericTransferFrom(address _contract, address _to, uint256 _tokenId) public onlyOwner{
    Ierc721Token(_contract).transferFrom(address(this), _to, _tokenId);//can only transfer from our own contract's wallet
  }

  function Ierc721TokenGenericSafeTransferFrom(address _contract, address _to, uint256 _tokenId) public onlyOwner{
    Ierc721Token(_contract).safeTransferFrom(address(this), _to, _tokenId);//can only transfer from our own contract's wallet
  }

  function Ierc721TokenGenericTransfer(address _contract, address _to, uint256 _tokenId) public onlyOwner{
    Ierc721Token(_contract).transfer( address(this), _to, _tokenId);//can only transfer from our own contract's wallet
  }

  function Ierc721TokenGenericSafeTransferData(address _contract, address _to, uint256 _tokenId) public onlyOwner{
    Ierc721Token(_contract).safeTransfer( address(this), _to, _tokenId);//can only transfer from our own contract's wallet
  }



/*
//was getting error with the below rank sorting tracker code
////top ranking

  function returnAllCandidatesVotesInIDOrder33Array() public view returns(uint[] memory){
    uint[] memory votesArrayOrderedByIDNumber;
    for(uint i=1; i<=maxNumberOfIDs; i++){
      votesArrayOrderedByIDNumber[i]=totalVotesForCandidateIDName[NumberedIDstoIDString[i]];//slot zero is left blank for readability
    }
    return votesArrayOrderedByIDNumber;
  }


  uint[10] public topTenVotersAmount; //slot [0] is first place, slot [1] is second place
  address[10] public topTenVotersAddresses;//same ""
  
  function seeTopTenVoters() external view returns(uint[10] memory, address[10] memory) {
  return (topTenVotersAmount, topTenVotersAddresses);
  }

  function checkTopTenVoter(uint _totalVotes, address _voter) internal //checks if there is a new top votr and if so changes ranks
  {   if (topTenVotersAmount[9] <= _totalVotes)//if total votes from votr are more than lowest rank 10 votes...
      {
        for(uint i=0; i<=9; i++)
        {
          if (topTenVotersAmount[i] <= _totalVotes)//check from rank 1 down and if find a rank with lower votes...
          {
            for(uint j=0; j<=9; j++)
            {
              if (j<=9-i)//count ranks left to swap
              {
              topTenVotersAmount[10-j] = topTenVotersAmount[9-j] ; //swap higher rank down to lower rank one space to make room on rankings for new winner
              topTenVotersAddresses[10-j] = topTenVotersAddresses[9-j];//same ""
              }
            }
          topTenVotersAmount[i] = _totalVotes;//now swap new winner into their ranking slot
          topTenVotersAddresses[i] = _voter;//same ""
          break;//exit the loop so don't overwrite every lower ranking slot
          }
        }
      }
  }

  uint[10] public topTenContestantsAmount; //slot [0] is first place, slot [1] is second place
  uint[10] public topTencontestantsIDnumbers; //same ""

  function seeTopTenContestantsBYIDNumber() external view returns(uint[10] memory, uint[10] memory) {//slot [0] is first place, slot [1] is second place
  return (topTenContestantsAmount, topTencontestantsIDnumbers);
  }

  function checkTopTenIDnumber(uint _totaledVotes, uint _IDnumber) internal //check if there is a new top ranking contestant. Arrays are in rank order so [0]=1stPlace, [1]=2ndPlace etc
  {   if (topTenContestantsAmount[9] <= _totaledVotes)//if total votes for contestant are more than lowest rank 10 votes...
      {
        for(uint i=0; i<=9; i++)
        {
          if (topTenContestantsAmount[i] <= _totaledVotes)//check from rank 1 down and if find a rank with lower votes...
          {
            for(uint j=0; j<=9; j++)
            {
              if (j<=9-i) //count ranks left to swap
              {
              topTenContestantsAmount[10-j] = topTenContestantsAmount[9-j] ; //swap higher rank down to lower rank one space
              topTencontestantsIDnumbers[10-j] = topTencontestantsIDnumbers[9-j]; //same ""
              }
            }
            topTenContestantsAmount[i] = _totaledVotes;//now swap new winner into their ranking slot
            topTencontestantsIDnumbers[i] = _IDnumber;//same ""
            break;//exit the loop so don't overwrite every lower ranking slot
          }
        }
      }
  }
*/
}