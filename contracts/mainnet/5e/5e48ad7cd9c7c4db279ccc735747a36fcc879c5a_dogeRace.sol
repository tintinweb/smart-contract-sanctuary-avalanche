/**
 *Submitted for verification at snowtrace.io on 2022-11-27
*/

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


pragma solidity ^0.8.4;

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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: DogeMoon/AVAX-new/dogeRace.sol



//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;





/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface MoonDoge {

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function tokenTraits(uint256 tokenId) external view returns (bytes2);

}

interface TraitStorage {

    function traitValues(uint256 traitId, uint256 tokenId) external view returns (uint256 value);

}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

contract dogeRace is Ownable, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface private COORDINATOR;
    LinkTokenInterface private LINKTOKEN;

    using SafeMath for uint256;
    
    address public dogeAddress;
    bool public active = false;
    
    address payable public devWallet;
    address payable public biofiWallet;

    /*
        Testnet Chainlink VRF:
        LINK	0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
        VRF Coordinator	0x2eD832Ba664535e5886b75D64C46EB9a228C2610
        Key Hash	0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61
        Fee	0.0005 LINK

        
        Mainnet Chainlink VRF:
        LINK	0x5947BB275c521040051D82396192181b413227A3
        VRF Coordinator	0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634
        Key Hash	0x89630569c9567e43c4fe7b1633258df9f2531b62f2352fa721cf3162ee4ecb46
        Fee	0.005 LINK
    */
    
    uint64 s_subscriptionId;
    address internal linkAddress = 0x5947BB275c521040051D82396192181b413227A3;
    address internal vrfCoordinator = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
    bytes32 internal keyHash = 0x89630569c9567e43c4fe7b1633258df9f2531b62f2352fa721cf3162ee4ecb46;
    uint256 public linkThreshold = 5 ether;

    uint32 internal callbackGasLimit = 2500000;
    uint16 internal requestConfirmations = 1;

    uint256 public currentRequestId;

    uint256 public raceCounter;

    uint256 public cancelThreshold;

    uint256 public raceLimit;

    uint256 public validRaces;

    // requestId => race id
    mapping (uint256 => uint256) public raceIdByRequestId;
    
    // requestId => isFulfilled address
    mapping (uint256 => bool) public requestFulfilled;
    
    event Request(uint256 requestId);
    event RaceCreated(uint256 raceId);
    event RaceJoined(uint256 raceId, uint256 dogeId);
    event RaceStart(uint256 raceId, uint256 requestId);
    event RaceFinish(uint256 raceId);

    struct TraitSettings {
        bool exists;
        uint256 speedMin;
        uint256 speedMax;
        uint256 enduranceMin;
        uint256 enduranceMax;
        uint256 luckMin;
        uint256 luckMax;
    }

    struct DogeTraits {
        uint256 speed;
        uint256 endurance;
        uint256 luck;
    }

    struct Race {
        address initiator;
        uint256 creationTime;
        uint256 entryFee;
        bool isFinished;
        bool isCancelled;
        uint256 participantCount;
        mapping(uint256 => uint256) participants;
        mapping(uint256 => bool) isSlotTaken;
        mapping(uint256 => uint256) finishedPosition;
    }

    // 1 = shiba, 2 = doberman, 3 = husky, 4 = german shepard, 5 = golden retriever, 6 = jack russel, 7 = corgi
    mapping(uint256 => TraitSettings) public traitSettingsPerDoge;

    address public dogeTraitsAddress;
    uint256 private speedTraitId;
    uint256 private enduranceTraitId;
    uint256 private luckTraitId;

    mapping(uint256 => Race) public races;

    mapping(uint256 => bool) public isDogeBusy;

    mapping(uint256 => uint256) public combinedTraitsArray;

    uint256[] public allowedEntryFees;
    mapping(uint256 => bool) public isAllowedEntryFee;
    
    constructor(address _dogeAddress, address payable _devWallet, uint256[] memory entryFees, address _dogeTraitsAddress, uint256 _speedTraitId, uint256 _enduranceTraitId, uint256 _luckTraitId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(linkAddress);

        dogeAddress = _dogeAddress;
        devWallet = _devWallet;
        biofiWallet = payable(0x06E03ED37f7e83Df29900C994ED19b2956d40C39);

        allowedEntryFees = entryFees;

        for(uint256 i=0; i<entryFees.length; i++) {
            isAllowedEntryFee[entryFees[i]] = true;
        }

        dogeTraitsAddress = _dogeTraitsAddress;
        speedTraitId = _speedTraitId;
        enduranceTraitId = _enduranceTraitId;
        luckTraitId = _luckTraitId;

        cancelThreshold = 1 hours;
        raceLimit = 10;

        traitSettingsPerDoge[1] = TraitSettings(true, 40, 100, 40, 100, 10, 100);
        traitSettingsPerDoge[2] = TraitSettings(true, 35, 100, 30, 100, 15, 100);
        traitSettingsPerDoge[3] = TraitSettings(true, 30, 100, 35, 100, 10, 100);
        traitSettingsPerDoge[4] = TraitSettings(true, 25, 100, 25, 100, 15, 100);
        traitSettingsPerDoge[5] = TraitSettings(true, 20, 100, 20, 100, 20, 100);
        traitSettingsPerDoge[6] = TraitSettings(true, 15, 100, 15, 100, 25, 100);
        traitSettingsPerDoge[7] = TraitSettings(true, 10, 100, 10, 100, 35, 100);

        createNewSubscription();
    }
    
    function getFinishedPosition(uint256 raceId, uint256 position) public view returns(uint256) {
        return races[raceId].finishedPosition[position];
    }
    
    function getRaceParticipant(uint256 raceId, uint256 index) public view returns(uint256) {
        return races[raceId].participants[index];
    }
    
    function getIsSlotTaken(uint256 raceId, uint256 index) public view returns(bool) {
        return races[raceId].isSlotTaken[index];
    }

    function createRace(uint256 dogeId, uint256 entryFee) public payable returns(bool success) {
        require(active == true, "Racing disabled");
        require(isDogeBusy[dogeId] == false, "Doge is busy");
        require(MoonDoge(dogeAddress).ownerOf(dogeId) == msg.sender, "Not doge owner");
        require(isAllowedEntryFee[entryFee] == true && msg.value == entryFee, "Incorrect entry fee");
        require(validRaces < raceLimit, "Limit exceeded");
        
        raceCounter++;
        validRaces++;

        races[raceCounter].initiator = msg.sender;
        races[raceCounter].creationTime = block.timestamp;
        races[raceCounter].participants[0] = dogeId;
        races[raceCounter].isSlotTaken[0] = true;
        races[raceCounter].participantCount = 1;
        races[raceCounter].entryFee = entryFee;

        updateCombinedTraits(dogeId);

        isDogeBusy[dogeId] = true;

        emit RaceCreated(raceCounter);
        emit RaceJoined(raceCounter, dogeId);

        return true;
    }
    
    function enterRace(uint256 raceId, uint256 dogeId) public payable returns(bool success) {
        require(active == true, "Racing disabled");
        require(isDogeBusy[dogeId] == false, "Doge is busy");
        require(MoonDoge(dogeAddress).ownerOf(dogeId) == msg.sender, "Not doge owner");
        require(races[raceId].creationTime > 0, "Race does not exist");
        require(races[raceId].isFinished == false, "Race finished");
        require(races[raceId].isCancelled == false, "Race cancelled");
        require(msg.value == races[raceId].entryFee, "Incorrect entry fee");
        
        for(uint256 i = 0; i < 9; i++) {
            if(races[raceId].isSlotTaken[i] == false) {
                races[raceId].participants[i] = dogeId;
                races[raceId].isSlotTaken[i] = true;
                races[raceId].participantCount++;

                updateCombinedTraits(dogeId);

                isDogeBusy[dogeId] = true;
                
                emit RaceJoined(raceId, dogeId);
                
                // if this is the last doge joining, initiate race
                if(races[raceId].participantCount == 9) {
                    uint96 subscriptionBalance;
                    (subscriptionBalance,,,) = getSubscriptionDetails();
                    if(subscriptionBalance < linkThreshold) {
                        require(LINKTOKEN.balanceOf(address(this)) >= linkThreshold, "Not enough LINK");
                        topUpSubscription(linkThreshold);
                    }
                    
                    currentRequestId = COORDINATOR.requestRandomWords(
                        keyHash,
                        s_subscriptionId,
                        requestConfirmations,
                        callbackGasLimit,
                        9
                    );
                    
                    raceIdByRequestId[currentRequestId] = raceId;
                    
                    emit RaceStart(raceId, currentRequestId);
                }

                return true;
            }
        }

        return false;
    }

    function updateCombinedTraits(uint256 dogeId) internal returns (bool) {

        if(combinedTraitsArray[dogeId] == 0) {
            bytes2 traits = MoonDoge(dogeAddress).tokenTraits(dogeId);
            bytes1 breed = traits[0];

            uint256 speedSeed = TraitStorage(dogeTraitsAddress).traitValues(speedTraitId, dogeId);
            uint256 enduranceSeed = TraitStorage(dogeTraitsAddress).traitValues(enduranceTraitId, dogeId);
            uint256 luckSeed = TraitStorage(dogeTraitsAddress).traitValues(luckTraitId, dogeId);

            uint256 combinedTraits = getDogeTraitsCombined(uint8(breed), speedSeed, enduranceSeed, luckSeed);

            combinedTraitsArray[dogeId] = combinedTraits;
        }

        return true;
    }
    
    
    function leaveRace(uint256 raceId, uint256 dogeId) public returns(bool success) {
        require(MoonDoge(dogeAddress).ownerOf(dogeId) == msg.sender, "Not doge owner");
        require(races[raceId].creationTime > 0, "Race does not exist");
        require(races[raceId].isFinished == false, "Race finished");
        require(races[raceId].isCancelled == false, "Race cancelled");
        require(races[raceId].creationTime + cancelThreshold < block.timestamp, "Leaving the race will be enabled 1 hour from its creation.");

        // check if race initiator is trying to cancel a race 
        if(races[raceId].initiator == msg.sender) {
            cancelRace(raceId);
            return true;
        } else {
            for(uint256 i = 0; i < 9; i++) {
                if(races[raceId].participants[i] == dogeId && races[raceId].isSlotTaken[i] == true) {
                    isDogeBusy[dogeId] = false;
                    races[raceId].isSlotTaken[i] = false;
                    races[raceId].participants[i] = 0;
                    races[raceId].participantCount--;
                    
                    // refund avax
                    payable(msg.sender).transfer(races[raceId].entryFee);

                    return true;
                }
            }
        }
        return false;
    }

    function finishRace(uint256 requestId, uint256[] memory randomNumbers) private {
        
        uint256 raceId = raceIdByRequestId[requestId];

        // participant id => entry tickets
        uint256[9] memory entryTickets;
        bool[9] memory dogeFinished;
        uint256 totalTickets = 0;
        
        for(uint256 i = 0; i < 9; i++) {

            isDogeBusy[races[raceId].participants[i]] = false;

            uint256 combinedTraits = combinedTraitsArray[races[raceId].participants[i]];

            entryTickets[i] = combinedTraits;
            totalTickets += combinedTraits;
        }

        // i = finished places, j = participants
        for(uint256 i = 0; i < 9; i++) {

            uint256 sumOfTickets = 0;

            for(uint256 j = 0; j < 9; j++) {
                if(dogeFinished[j] == false) {
                    sumOfTickets += entryTickets[j];
                    uint256 winner = randomNumbers[i] % (totalTickets) + 1;

                    if(winner <= sumOfTickets) {
                        totalTickets -= entryTickets[j];
                        //entryTickets[j] = 0;
                        races[raceId].finishedPosition[i] = races[raceId].participants[j];
                        dogeFinished[j] = true;
                        break;
                    }
                }
            }
        }

        uint256 totalReward = races[raceId].entryFee.mul(9);
        uint256 reward1 = totalReward.mul(500).div(1000);
        uint256 reward2 = totalReward.mul(250).div(1000);
        uint256 reward3 = totalReward.mul(125).div(1000);
        uint256 devFee1 = totalReward.mul(625).div(10000);
        uint256 devFee2 = totalReward.sub(reward1).sub(reward2).sub(reward3).sub(devFee1);

        payable(MoonDoge(dogeAddress).ownerOf(races[raceId].finishedPosition[0])).transfer(reward1);
        payable(MoonDoge(dogeAddress).ownerOf(races[raceId].finishedPosition[1])).transfer(reward2);
        payable(MoonDoge(dogeAddress).ownerOf(races[raceId].finishedPosition[2])).transfer(reward3);
        payable(devWallet).transfer(devFee1);
        payable(biofiWallet).transfer(devFee2);
        
        emit RaceFinish(raceId);

        validRaces--;
        
        races[raceId].isFinished = true; 
        requestFulfilled[requestId] = true;
    }

    function getDogeTraits(uint256 dogeBreedId, uint256 speedSeed, uint256 enduranceSeed, uint256 luckSeed) public view returns(DogeTraits memory) {
        require(traitSettingsPerDoge[dogeBreedId].exists == true, "Incorrect breed");
        
        uint256 generatedSpeed = speedSeed % (traitSettingsPerDoge[dogeBreedId].speedMax - traitSettingsPerDoge[dogeBreedId].speedMin) + traitSettingsPerDoge[dogeBreedId].speedMin;
        uint256 generatedEndurance = enduranceSeed % (traitSettingsPerDoge[dogeBreedId].enduranceMax - traitSettingsPerDoge[dogeBreedId].enduranceMin) + traitSettingsPerDoge[dogeBreedId].enduranceMin;
        uint256 generatedLuck = luckSeed % (traitSettingsPerDoge[dogeBreedId].luckMax - traitSettingsPerDoge[dogeBreedId].luckMin) + traitSettingsPerDoge[dogeBreedId].luckMin;

        return DogeTraits(generatedSpeed, generatedEndurance, generatedLuck);
    }

    function getDogeTraitsCombined(uint256 dogeBreedId, uint256 speedSeed, uint256 enduranceSeed, uint256 luckSeed) public view returns(uint256) {
        
        uint256 generatedSpeed = speedSeed % (traitSettingsPerDoge[dogeBreedId].speedMax - traitSettingsPerDoge[dogeBreedId].speedMin) + traitSettingsPerDoge[dogeBreedId].speedMin;
        uint256 generatedEndurance = enduranceSeed % (traitSettingsPerDoge[dogeBreedId].enduranceMax - traitSettingsPerDoge[dogeBreedId].enduranceMin) + traitSettingsPerDoge[dogeBreedId].enduranceMin;
        uint256 generatedLuck = luckSeed % (traitSettingsPerDoge[dogeBreedId].luckMax - traitSettingsPerDoge[dogeBreedId].luckMin) + traitSettingsPerDoge[dogeBreedId].luckMin;

        uint256 combined = generatedSpeed + generatedEndurance + generatedLuck;

        return combined;
    }

    function setActive(bool isActive) public onlyOwner {
        active = isActive;
    }
    
    function updateRaceLimit(uint256 _raceLimit) public onlyOwner {
        raceLimit = _raceLimit;
    }
    
    function withdrawEther(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
    }

    function withdrawTokens(address token, address to, uint256 amount) public onlyOwner {
        IERC20 wToken = IERC20(token);
        wToken.transfer(to, amount);
    }
    
    // Create a new subscription
    function createNewSubscription() internal {
        require(s_subscriptionId == 0, 'A subscription already exist');
        // Create a subscription with a new subscription ID.
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumers[0]);
    }

    // get the details of the subscription
    function getSubscriptionDetails() public view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers) {
        return COORDINATOR.getSubscription(s_subscriptionId);
    }

    // Assumes this contract owns link. This function must be called to fund the subscription
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) internal {
        LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
    }

    function adminTopUpSubscription(uint256 amount) external onlyOwner {
        LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
    }

    // Create new subscription
    function adminCreateSubscription() external onlyOwner {
        createNewSubscription();
    }

    function adminUpdateLinkThreshold(uint256 _linkThreshold) external onlyOwner {
        linkThreshold = _linkThreshold;
    }

    /*
    function adminUpdateVRFSettings(uint32 _callbackGasLimit, uint16 _requestConfirmations, uint256 _linkThreshold) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        linkThreshold = _linkThreshold;
    }
    */

    function adminSetEntryFees(uint256[] memory entryFees) external onlyOwner {
        for(uint256 i=0; i<allowedEntryFees.length; i++) {
            isAllowedEntryFee[allowedEntryFees[i]] = false;
        }

        allowedEntryFees = entryFees;

        for(uint256 i=0; i<entryFees.length; i++) {
            isAllowedEntryFee[entryFees[i]] = true;
        }
    }

    function adminSetDevWallet(address payable newDevWallet) external onlyOwner {
        devWallet = newDevWallet;
    }

    function cancelRace(uint256 raceId) internal {
        for(uint256 i = 0; i < 9; i++) {
            if(races[raceId].isSlotTaken[i] == true) {
                isDogeBusy[races[raceId].participants[i]] = false;
                races[raceId].isSlotTaken[i] = false;
                races[raceId].participantCount = 0;
                races[raceId].isCancelled = true;

                // refund avax
                payable(MoonDoge(dogeAddress).ownerOf(races[raceId].participants[i])).transfer(races[raceId].entryFee);
            }
        }
        validRaces--;
    }
    
    function adminCancelRace(uint256 raceId) external onlyOwner {
        require(races[raceId].creationTime > 0, "Race does not exist");
        require(races[raceId].isFinished == false, "Race finished");
        require(races[raceId].isCancelled == false, "Race cancelled");
        
        cancelRace(raceId);
    }


    // Cancel the subscription and send the remaining LINK to a wallet address.
    function cancelSubscription(address receivingWallet) external onlyOwner {
        require(s_subscriptionId > 0, "Subscription does not exist");
        COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
        s_subscriptionId = 0;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(raceIdByRequestId[requestId] != 0, "Invalid requestId");
        require(requestFulfilled[requestId] == false, "Request already fulfilled");
        
        finishRace(requestId, randomWords);
    }

}