// SPDX-License-Identifier: MIT
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Apothecary Errors
error InvalidDifficulty();
error InvalidVrfRequestID();
error InvalidStartTime();
error ClaimHasStarted();
error DoctorAlreadyClaimed();
error ClaimNotStarted();
error InvalidDoctorIdsLength();
error GameEnded();
error DoctorNotOwnedBySender();
error DoctorNotDead();
error DoctorAlreadyBrewed();
error NoPotionLeft();

// Plague Game Errors
error InvalidPlayerNumberToEndGame();
error InvalidInfectionPercentage();
error InvalidSuccessRatePercentage();
error InvalidEpochDuration();
error TooManyInitialized();
error InvalidCollection();
error GameAlreadyStarted();
error GameNotStarted();
error GameNotOver();
error GameIsClosed();
error InfectionNotComputed();
error NothingToCompute();
error EpochNotReadyToEnd();
error EpochAlreadyEnded();
error DoctorNotInfected();
error UpdateToSameStatus();
error InvalidRequestId();
error CantAddPrizeIfGameIsOver();
error NotAWinner();
error WithdrawalClosed();
error FundsTransferFailed();

// VRF Errors
error VRFResponseMissing();
error VRFAlreadyRequested();
error VRFUnknownRequest();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC721//extensions/IERC721Enumerable.sol";
import "./Errors.sol";

interface IPlagueGame {
    /// @dev Different statuses a doctor can have
    enum Status {
        Dead,
        Healthy,
        Infected
    }

    /// Game events
    event GameStartTimeUpdated(uint256 newStartTime);
    event GameStarted();
    event RandomWordsFulfilled(uint256 indexed epoch, uint256 requestId);
    event DoctorsInfectedThisEpoch(uint256 indexed epoch, uint256 infectedDoctors);
    event EpochEnded(uint256 indexed epoch);
    event GameOver();
    event PrizeWithdrawalAllowed(bool newValue);
    event PrizeWithdrawn(uint256 indexed doctorId, uint256 prize);
    event PrizePotIncreased(uint256 amount);
    event FundsEmergencyWithdraw(uint256 amount);

    /// Doctor event
    event DoctorCured(uint256 indexed doctorId, uint256 indexed epoch);

    function doctors() external view returns (IERC721Enumerable);
    function potions() external view returns (IERC721Enumerable);

    function startTime() external view returns (uint256);
    function playerNumberToEndGame() external view returns (uint256);
    function infectionPercentages(uint256 epoch) external view returns (uint256);
    function cureSuccessRates(uint256 epoch) external view returns (uint256);

    function currentEpoch() external view returns (uint256);
    function epochDuration() external view returns (uint256);
    function epochStartTime() external view returns (uint256);

    function healthyDoctorsNumber() external view returns (uint256);
    function doctorStatus(uint256 doctorId) external view returns (Status);
    function potionUsed(uint256 doctorId) external view returns (uint256);

    function infectedDoctorsPerEpoch(uint256 epoch) external view returns (uint256);
    function curedDoctorsPerEpoch(uint256 epoch) external view returns (uint256);
    function withdrewPrize(uint256 doctorId) external view returns (bool);

    function isGameOver() external view returns (bool);
    function isGameStarted() external view returns (bool);
    function prizePot() external view returns (uint256);
    function prizeWithdrawalAllowed() external view returns (bool);

    function initializeGame(uint256 _amount) external;
    function updateGameStartTime(uint256 _newStartTime) external;
    function allowPrizeWithdraw(bool _status) external;
    function computeInfectedDoctors(uint256 _amount) external;
    function startGame() external;
    function startEpoch() external;
    function endEpoch() external;
    function drinkPotion(uint256 _doctorId, uint256 _potionId) external;
    function withdrawPrize(uint256 _doctorId) external;
    function withdrawFunds() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/access/Ownable.sol";

import "chainlink/VRFConsumerBaseV2.sol";
import "chainlink/interfaces/VRFCoordinatorV2Interface.sol";

import "./IPlagueGame.sol";

contract PlagueGame is IPlagueGame, Ownable, VRFConsumerBaseV2 {
    /// @notice Address of the doctor collection contract
    IERC721Enumerable public immutable override doctors;
    /// @notice Address of the potion collection contract
    IERC721Enumerable public immutable override potions;
    /// @notice Start time of the game, timestamp in seconds
    uint256 public override startTime;
    /// @notice Number of doctors still alive triggering the end of the game
    uint256 public immutable override playerNumberToEndGame;
    /// @notice Percentage of doctors that will be infected each epoch
    uint256[] public override infectionPercentages;
    /// @notice Potions cure success rate, in basis points
    uint256[] public override cureSuccessRates;
    /// @dev Number of doctors in the collection
    uint256 private immutable _doctorNumber;

    /// @notice Number of healthy doctors
    uint256 public override healthyDoctorsNumber;
    /// @notice Number of potions a doctor already drank
    mapping(uint256 => uint256) public override potionUsed;

    /// @notice Current epoch. Epoch is incremented at the beginning of each epoch
    uint256 public override currentEpoch;
    /// @notice Duration of each epoch in seconds
    uint256 public immutable override epochDuration;
    /// @notice Start time of the latest epoch
    uint256 public override epochStartTime;

    /// @notice Stores the number of infected doctors at each epoch. This is purely for the front-end
    mapping(uint256 => uint256) public override infectedDoctorsPerEpoch;
    /// @notice Stores the number of cured doctors at each epoch. This is purely for the front-end
    mapping(uint256 => uint256) public override curedDoctorsPerEpoch;
    /// @notice Stores if a user already claimed his prize for a doctors he owns
    mapping(uint256 => bool) public override withdrewPrize;

    enum VRFRequestType {
        Unknown,
        Cure,
        Infection
    }

    /// @dev VRF request type
    mapping(uint256 => VRFRequestType) private _vrfRequestType;
    /// @dev VRF request IDs for each epoch
    mapping(uint256 => uint256) private _epochVRFRequest;
    /// @dev VRF response for each epoch
    mapping(uint256 => uint256) private _epochVRFNumber;
    /// @dev Doctor related to a VRF request
    mapping(uint256 => uint256) private _vrfRequestDoctor;
    /// @dev Blocks VRF requests from a doctor that already has one pending
    mapping(uint256 => bool) private _vrfRequestPending;
    /// @dev Stores if an epoch has ended
    mapping(uint256 => bool) private _epochEnded;

    /// @notice Whether the game is over (true), or not (false)
    bool public override isGameOver;
    /// @notice Whether the game has started (true), or not (false)
    bool public override isGameStarted;
    /// @notice Prize pot that will be distributed to the winners at the end of the game
    uint256 public override prizePot;
    /// @notice States if the withdrawal is open. Set by the contract owner
    bool public override prizeWithdrawalAllowed;

    /// @dev Array containing the Ids of all the healthy doctors
    /// A doctor ID is stored in a 16 bits integer.
    // 16 * 16 = 256 -> 16 doctors IDs per slot
    // 10k / 16 = 625 -> For 10k, need 625 slots
    uint256 private constant HEALTHY_DOCTOR_SET_SIZE = 625;
    uint256[HEALTHY_DOCTOR_SET_SIZE] private _healthyDoctorsSet;
    uint256 private constant DOCTOR_ID_MASK = 0xFFFF;
    uint256 private constant HEALTHY_DOCTOR_BASE_RANGE = 0xf000e000d000c000b000a0009000800070006000500040003000200010000;
    uint256 private constant HEALTHY_DOCTOR_OFFSET = 0x10001000100010001000100010001000100010001000100010001000100010;
    /// @dev Array containing the status of every doctor
    /// A doctor status is stored in a 2 bits integer.
    // 256 / 2 = 128 doctors per slot
    // 10k / 128 = 78.125 need 79 slots
    uint256 private constant DOCTORS_STATUS_SET_SIZE = 79;
    uint256[DOCTORS_STATUS_SET_SIZE] private _doctorsStatusSet;
    uint256 private constant DOCTOR_STATUS_MASK = 0x03;
    /// @dev Used on contract initialization
    uint256 private _lastDoctorAdded;
    /// @dev Initialize all doctor statuses to healthy
    /// Equivalent to 0b01 repeated 128 times
    uint256 private constant HEALTHY_DOCTOR_ARRAY_ITEM =
        0x5555555555555555555555555555555555555555555555555555555555555555;

    /// @dev Keeps track of the doctors already infected for an epoch
    /// Used to paginate startEpoch
    mapping(uint256 => uint256) private _computedInfections;

    /// @dev Address of the VRF coordinator
    VRFCoordinatorV2Interface private immutable _vrfCoordinator;
    /// @dev VRF subscription ID
    uint64 private immutable _subscriptionId;
    /// @dev VRF key hash
    bytes32 private immutable _keyHash;
    /// @dev Max gas used on the VRF callback
    uint32 private immutable _maxGas;

    /// @dev Basis point to calulate percentages
    uint256 private constant BASIS_POINT = 10_000;

    modifier gameOn() {
        if (isGameOver || !isGameStarted) {
            revert GameIsClosed();
        }
        _;
    }

    /// @dev Constructor
    /// @param _doctors Address of the doctor collection contract
    /// @param _potions Address of the potion collection contract
    /// @param _infectionPercentages Percentage of doctors that will  be infected each epoch
    /// @param _cureSuccessRates Percentage of success when drinking a potion
    /// @param _playerNumberToEndGame Number of doctors still alive triggering the end of the game
    /// @param _epochDuration Duration of each epoch in seconds
    /// @param vrfCoordinator_ Address of the VRF coordinator
    /// @param subscriptionId_ VRF subscription ID
    /// @param keyHash_ VRF key hash
    /// @param maxGas_ Max gas used on the VRF callback
    constructor(
        IERC721Enumerable _doctors,
        IERC721Enumerable _potions,
        uint256 _startTime,
        uint256 _playerNumberToEndGame,
        uint256[] memory _infectionPercentages,
        uint256[] memory _cureSuccessRates,
        uint256 _epochDuration,
        VRFCoordinatorV2Interface vrfCoordinator_,
        uint64 subscriptionId_,
        bytes32 keyHash_,
        uint32 maxGas_
    ) VRFConsumerBaseV2(address(vrfCoordinator_)) {
        if (_playerNumberToEndGame == 0) {
            revert InvalidPlayerNumberToEndGame();
        }

        if (_epochDuration == 0 || _epochDuration > 7 days) {
            revert InvalidEpochDuration();
        }

        if (_startTime < block.timestamp) {
            revert InvalidStartTime();
        }

        for (uint256 i = 0; i < _infectionPercentages.length; i++) {
            if (_infectionPercentages[i] > BASIS_POINT) {
                revert InvalidInfectionPercentage();
            }
        }

        for (uint256 i = 0; i < _cureSuccessRates.length; i++) {
            if (_cureSuccessRates[i] == 0 || _cureSuccessRates[i] > BASIS_POINT) {
                revert InvalidSuccessRatePercentage();
            }
        }

        doctors = _doctors;
        _vrfCoordinator = vrfCoordinator_;
        _doctorNumber = _doctors.totalSupply();

        if (_doctorNumber > 10_000 || _doctorNumber == 0) {
            revert InvalidCollection();
        }

        potions = _potions;
        startTime = _startTime;
        playerNumberToEndGame = _playerNumberToEndGame;
        infectionPercentages = _infectionPercentages;
        cureSuccessRates = _cureSuccessRates;
        epochDuration = _epochDuration;

        // VRF setup
        _subscriptionId = subscriptionId_;
        _keyHash = keyHash_;
        _maxGas = maxGas_;
    }

    /// @notice Initializes the game
    /// @dev This function is very expensive in gas, that's why it needs to be called several times
    /// @param _amount Amount of _healthyDoctorsSet items to initialize
    function initializeGame(uint256 _amount) external override {
        uint256 currentLastDoctorInSet = _lastDoctorAdded;
        uint256 lastDoctorIdToAdd = currentLastDoctorInSet + _amount;

        if (lastDoctorIdToAdd > (_doctorNumber + 15) / 16) {
            revert TooManyInitialized();
        }

        // Initialize the doctors status set on first call
        if (currentLastDoctorInSet == 0) {
            uint256 arrayLengthToInitialize = (_doctorNumber / 128);
            for (uint256 j = 0; j < arrayLengthToInitialize; ++j) {
                _doctorsStatusSet[j] = HEALTHY_DOCTOR_ARRAY_ITEM;
            }

            _doctorsStatusSet[arrayLengthToInitialize] = HEALTHY_DOCTOR_ARRAY_ITEM >> (128 - (_doctorNumber % 128)) * 2;
        }

        for (uint256 j = currentLastDoctorInSet; j < lastDoctorIdToAdd; j++) {
            uint256 doctorIds = HEALTHY_DOCTOR_BASE_RANGE + HEALTHY_DOCTOR_OFFSET * j;
            _healthyDoctorsSet[j] = doctorIds;
        }

        _lastDoctorAdded = lastDoctorIdToAdd;

        if (lastDoctorIdToAdd == (_doctorNumber + 15) / 16) {
            healthyDoctorsNumber = _doctorNumber;
        }
    }

    /// @notice Starts the game
    function startGame() external override {
        if (isGameStarted) {
            revert GameAlreadyStarted();
        }

        if (healthyDoctorsNumber < _doctorNumber || block.timestamp < startTime) {
            revert GameNotStarted();
        }

        _initiateNewEpoch(1);

        isGameStarted = true;
        emit GameStarted();
    }

    /// @notice Infects doctors prior to the start of the next epoch
    /// @dev This function is very expensive in gas, that's why it needs to be called several times
    /// @param _amount Amount of infected doctors to compute
    function computeInfectedDoctors(uint256 _amount) external override gameOn {
        uint256 nextEpoch = currentEpoch + 1;

        uint256 healthyDoctorsNumberCached = healthyDoctorsNumber;

        uint256 randomNumber = _epochVRFNumber[_epochVRFRequest[nextEpoch]];
        if (randomNumber == 0) {
            revert VRFResponseMissing();
        }

        uint256 infectedDoctorsNextEpoch = infectedDoctorsPerEpoch[nextEpoch];
        uint256 computedInfectionsForNextEpoch = _computedInfections[nextEpoch];

        // Only infect the necessary amount of doctors
        if (computedInfectionsForNextEpoch + _amount > infectedDoctorsNextEpoch) {
            _amount = infectedDoctorsNextEpoch - computedInfectionsForNextEpoch;
        }

        if (_amount == 0) {
            revert NothingToCompute();
        }

        // Infect from offset to offset + _amount
        _infectRandomDoctors(healthyDoctorsNumberCached, computedInfectionsForNextEpoch, _amount, randomNumber);
        healthyDoctorsNumber = healthyDoctorsNumberCached - _amount;

        _computedInfections[nextEpoch] = computedInfectionsForNextEpoch + _amount;
    }

    /// @notice Starts a new epoch if the conditions are met
    function startEpoch() external override gameOn {
        uint256 nextEpoch = currentEpoch + 1;

        if (_computedInfections[nextEpoch] == 0 || _computedInfections[nextEpoch] < infectedDoctorsPerEpoch[nextEpoch])
        {
            revert InfectionNotComputed();
        }

        currentEpoch = nextEpoch;
        epochStartTime = block.timestamp;

        emit DoctorsInfectedThisEpoch(nextEpoch, infectedDoctorsPerEpoch[nextEpoch]);
    }

    /// @notice Ends the current epoch if the conditions are met
    function endEpoch() external override gameOn {
        uint256 currentEpochCached = currentEpoch;

        if (_epochEnded[currentEpochCached] == true) {
            revert EpochAlreadyEnded();
        }

        if (block.timestamp < epochStartTime + epochDuration) {
            revert EpochNotReadyToEnd();
        }

        _epochEnded[currentEpochCached] = true;

        // Updates the infected doctors statuses to Dead
        // 0x5555...555 means 0b01010101...01, all doctors are healthy
        // For infected doctors that have a 0b10 status, this sets the status to 0b00 (dead)
        // For healthy doctors that have a 0b01 status, this doesn't change the status
        // For dead doctors that have a 0b00 status, this doesn't change the status
        for (uint256 i = 0; i < DOCTORS_STATUS_SET_SIZE; ++i) {
            _doctorsStatusSet[i] &= HEALTHY_DOCTOR_ARRAY_ITEM;
        }

        emit EpochEnded(currentEpochCached);

        if (healthyDoctorsNumber <= playerNumberToEndGame) {
            isGameOver = true;
            emit GameOver();
        } else {
            _initiateNewEpoch(currentEpochCached + 1);
        }
    }

    /// @notice Burns a potion to cure a doctor
    /// @dev User needs to have given approval to the contract
    /// @param _doctorId ID of the doctor to cure
    /// @param _potionId ID of the potion to use
    function drinkPotion(uint256 _doctorId, uint256 _potionId) external override {
        if (block.timestamp > epochStartTime + epochDuration) {
            revert EpochAlreadyEnded();
        }

        if (doctorStatus(_doctorId) != Status.Infected) {
            revert DoctorNotInfected();
        }

        uint256 potionUsedByDoctor = potionUsed[_doctorId]++;

        if (_getCureSuccessRate(potionUsedByDoctor) == BASIS_POINT) {
            uint256 currentEpochCached = currentEpoch;
            curedDoctorsPerEpoch[currentEpochCached] += 1;
            _updateDoctorStatusStorage(_doctorId, Status.Healthy);
            _addDoctorToHealthySet(_doctorId);

            emit DoctorCured(_doctorId, currentEpochCached);
        } else {
            if (_vrfRequestPending[_doctorId]) {
                revert VRFAlreadyRequested();
            }

            _vrfRequestPending[_doctorId] = true;

            uint256 requestID = _vrfCoordinator.requestRandomWords(_keyHash, _subscriptionId, 3, _maxGas, 1);
            _vrfRequestDoctor[requestID] = _doctorId;
            _vrfRequestType[requestID] = VRFRequestType.Cure;
        }

        _burnPotion(_potionId);
    }

    /// @notice Updates the game start time
    /// @param _newStartTime New game start time
    function updateGameStartTime(uint256 _newStartTime) external override onlyOwner {
        if (_newStartTime < block.timestamp) {
            revert InvalidStartTime();
        }

        startTime = _newStartTime;
        emit GameStartTimeUpdated(_newStartTime);
    }

    /// @notice Starts and pauses the prize withdrawal
    /// @param _status True to allow the withdrawal of the prize
    function allowPrizeWithdraw(bool _status) external override onlyOwner {
        if (!isGameOver) {
            revert GameNotOver();
        }

        if (_status == prizeWithdrawalAllowed) {
            revert UpdateToSameStatus();
        }

        prizeWithdrawalAllowed = _status;

        emit PrizeWithdrawalAllowed(_status);
    }

    /// @notice Withdraws the prize for a winning doctor
    /// @param _doctorId ID of the doctor to withdraw the prize for
    function withdrawPrize(uint256 _doctorId) external override {
        if (!prizeWithdrawalAllowed) {
            revert WithdrawalClosed();
        }

        if (
            doctorStatus(_doctorId) != Status.Healthy || doctors.ownerOf(_doctorId) != msg.sender
                || withdrewPrize[_doctorId]
        ) {
            revert NotAWinner();
        }

        withdrewPrize[_doctorId] = true;

        uint256 prize = prizePot / healthyDoctorsNumber;

        (bool success,) = payable(msg.sender).call{value: prize}("");

        if (!success) {
            revert FundsTransferFailed();
        }

        emit PrizeWithdrawn(_doctorId, prize);
    }

    ///@notice Allows the contract owner to withdraw the funds
    function withdrawFunds() external override onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");

        if (!success) {
            revert FundsTransferFailed();
        }

        emit FundsEmergencyWithdraw(address(this).balance);
    }

    /// @dev Send AVAX to the contract to increase the prize pot
    /// Only possible when the game is still on, to avoid uneven prize distribution
    receive() external payable {
        if (isGameOver) {
            revert CantAddPrizeIfGameIsOver();
        }
        prizePot += msg.value;
        emit PrizePotIncreased(msg.value);
    }

    function doctorStatus(uint256 _doctorId) public view override returns (Status) {
        uint256 statusSetItem = _doctorsStatusSet[_doctorId / 128];
        uint256 shift = (_doctorId % 128) * 2;
        uint256 doctorStatusUint = (statusSetItem >> shift) & DOCTOR_STATUS_MASK;

        if (doctorStatusUint == 2) {
            return Status.Infected;
        } else if (doctorStatusUint == 1) {
            return Status.Healthy;
        } else {
            return Status.Dead;
        }
    }

    /// @dev Requests a random number from Chainlink VRF and starts a new epoch
    /// Called on game start and endEpoch
    /// @param _nextEpoch Next epoch
    function _initiateNewEpoch(uint256 _nextEpoch) private {
        uint256 toMakeSick = healthyDoctorsNumber * _getinfectionRate(_nextEpoch) / BASIS_POINT;

        // Need at least one doctor to be infected, otherwise the game will never end
        if (toMakeSick == 0) {
            toMakeSick = 1;
        }

        // Need at least one doctor left healthy, otherwise the game could end up with no winners
        if (toMakeSick == healthyDoctorsNumber) {
            toMakeSick -= 1;
        }

        infectedDoctorsPerEpoch[_nextEpoch] = toMakeSick;

        // Extra safety check, but that shouldn't happen
        if (_epochVRFNumber[_epochVRFRequest[_nextEpoch]] != 0) {
            revert VRFAlreadyRequested();
        }

        uint256 requestID = _vrfCoordinator.requestRandomWords(_keyHash, _subscriptionId, 3, _maxGas, 1);
        _epochVRFRequest[_nextEpoch] = requestID;
        _vrfRequestType[requestID] = VRFRequestType.Infection;
    }

    /// @dev Updates the doctor status directly on storage
    /// @param _doctorId ID of the doctor to update
    /// @param _newStatus New status of the doctor
    function _updateDoctorStatusStorage(uint256 _doctorId, Status _newStatus) private {
        _doctorsStatusSet[_doctorId / 128] =
            _updateDoctorStatusArrayItem(_doctorsStatusSet[_doctorId / 128], _doctorId, _newStatus);
    }

    /// @dev Updates the doctor status in a cached array
    /// @param _doctorsStatusSetMemory Array of doctors statuses cached in memory
    /// @param _doctorId ID of the doctor to update
    /// @param _newStatus New status of the doctor
    function _updateDoctorStatusMemory(
        uint256[DOCTORS_STATUS_SET_SIZE] memory _doctorsStatusSetMemory,
        uint256 _doctorId,
        Status _newStatus
    ) private pure {
        _doctorsStatusSetMemory[_doctorId / 128] =
            _updateDoctorStatusArrayItem(_doctorsStatusSetMemory[_doctorId / 128], _doctorId, _newStatus);
    }

    /// @dev Updates the status of a doctor situated in the given array item
    /// @param _arrayItem The array item to update
    /// @param _doctorId The ID of the doctor to update
    /// @param _newStatus The new status of the doctor
    /// @return _arrayItem The updated array item
    function _updateDoctorStatusArrayItem(uint256 _arrayItem, uint256 _doctorId, Status _newStatus)
        private
        pure
        returns (uint256)
    {
        uint256 shift = (_doctorId % 128) * 2;

        // Mask the 2 bits of the doctor status
        _arrayItem &= ~(DOCTOR_STATUS_MASK << shift);
        // Sets the new status
        _arrayItem |= uint256(_newStatus) << shift;

        return _arrayItem;
    }

    /// @dev Removes a doctor from the set of healthy doctors cached in memory
    /// @param _healthyDoctorsSetMemory Array of doctors IDs cached in memory
    /// @param _healthyDoctorsNumber Total number of doctors in the array
    /// @param _index Index of the doctor to remove
    /// @return doctorId ID of the doctor removed
    function _removeDoctorFromSet(
        uint256[HEALTHY_DOCTOR_SET_SIZE] memory _healthyDoctorsSetMemory,
        uint256 _healthyDoctorsNumber,
        uint256 _index
    ) private pure returns (uint256) {
        // Get the last doctor ID
        uint256 lastDoctorId = _getDoctorIdFromSetMemory(_healthyDoctorsSetMemory, _healthyDoctorsNumber - 1);

        // Get the doctor ID at the index
        uint256 doctorSetItem = _healthyDoctorsSetMemory[_index / 16];
        uint256 doctorId = _getDoctorIdFromSetMemory(_healthyDoctorsSetMemory, _index);

        // Mask the doctor ID at the index
        uint256 offset = (_index % 16) * 16;
        doctorSetItem &= ~(DOCTOR_ID_MASK << offset);
        // Replaces it by the last doctor Id of the array
        doctorSetItem |= (lastDoctorId << offset);
        _healthyDoctorsSetMemory[_index / 16] = doctorSetItem;

        return doctorId;
    }

    /// @dev Adds back a doctor in the set of healthy doctors
    /// @param _doctorId ID of the doctor to add
    function _addDoctorToHealthySet(uint256 _doctorId) private {
        uint256 healthyDoctorsNumberCached = healthyDoctorsNumber;

        // Loads the array item containing the doctor Id
        uint256 lastDoctorSetItem = _healthyDoctorsSet[healthyDoctorsNumberCached / 16];
        // Mask the previous value located at the first unused index
        uint256 offset = (healthyDoctorsNumberCached % 16) * 16;
        lastDoctorSetItem &= ~(DOCTOR_ID_MASK << offset);
        // Add the new doctor Id
        lastDoctorSetItem |= (_doctorId << offset);
        //Update storage
        _healthyDoctorsSet[healthyDoctorsNumberCached / 16] = lastDoctorSetItem;

        healthyDoctorsNumber = healthyDoctorsNumberCached + 1;
    }

    /// @dev Gets the doctor Id from the set of healthy doctors cached in memory
    /// @param _healthyDoctorsSetMemory Array of doctors IDs cached in memory
    /// @param _index Index of the doctor to get from the array
    /// @return doctorId ID of the doctor
    function _getDoctorIdFromSetMemory(uint256[HEALTHY_DOCTOR_SET_SIZE] memory _healthyDoctorsSetMemory, uint256 _index)
        private
        pure
        returns (uint256)
    {
        uint256 doctorSetItem = _healthyDoctorsSetMemory[_index / 16];
        uint256 offset = (_index % 16) * 16;

        return ((doctorSetItem >> offset) & DOCTOR_ID_MASK);
    }

    /// @dev Fetches the right infection rate for the current epoch
    /// If we passed the last defined epoch, we use the last used rate
    /// @param _epoch Epoch
    /// @return infectionRate Infection rate for the considered epoch
    function _getinfectionRate(uint256 _epoch) private view returns (uint256 infectionRate) {
        uint256 infectionPercentagesLength = infectionPercentages.length;
        infectionRate = _epoch > infectionPercentagesLength
            ? infectionPercentages[infectionPercentagesLength - 1]
            : infectionPercentages[_epoch - 1];
    }

    /// @dev Fetches the right cure success rate for the amount of potion the doctor already drank
    /// If we passed the last defined amount of potions, we use the last used rate
    /// @param _potionsDrank Amount of potion the doctor already drank
    /// @return cureSuccessRate Cure success rate for the considered epoch
    function _getCureSuccessRate(uint256 _potionsDrank) private view returns (uint256 cureSuccessRate) {
        uint256 cureSuccessRatesLength = cureSuccessRates.length;
        cureSuccessRate = _potionsDrank >= cureSuccessRatesLength
            ? cureSuccessRates[cureSuccessRatesLength - 1]
            : cureSuccessRates[_potionsDrank];
    }

    /// @dev Loops through the healthy doctors and infects them until
    /// the number of infected doctors is equal to the requested number
    /// @dev Each VRF random number is used 8 times
    /// @param _healthyDoctorsNumber Number of healthy doctors
    /// @param _toMakeSick Number of doctors to infect
    /// @param _randomNumber Random number provided by VRF, used to infect doctors
    function _infectRandomDoctors(
        uint256 _healthyDoctorsNumber,
        uint256 _offset,
        uint256 _toMakeSick,
        uint256 _randomNumber
    ) private {
        uint256 madeSick = _offset;
        uint256 doctorId;
        uint256 healthyDoctorId;

        uint256[HEALTHY_DOCTOR_SET_SIZE] memory healthyDoctorsSetCached = _healthyDoctorsSet;
        uint256[DOCTORS_STATUS_SET_SIZE] memory doctorsStatusSetCached = _doctorsStatusSet;

        while (madeSick < _offset + _toMakeSick) {
            // Shuffles the random number to get a new one
            healthyDoctorId = uint256(keccak256(abi.encode(_randomNumber, madeSick))) % _healthyDoctorsNumber;
            // Removing the doctors from the healthy doctors list and infecting him
            doctorId = _removeDoctorFromSet(healthyDoctorsSetCached, _healthyDoctorsNumber, healthyDoctorId);
            _updateDoctorStatusMemory(doctorsStatusSetCached, doctorId, Status.Infected);

            --_healthyDoctorsNumber;
            ++madeSick;
        }

        _healthyDoctorsSet = healthyDoctorsSetCached;
        _doctorsStatusSet = doctorsStatusSetCached;
    }

    /// @dev Burns a potion NFT
    /// @param _potionId ID of the NFT to burn
    function _burnPotion(uint256 _potionId) private {
        potions.transferFrom(msg.sender, address(0xdead), _potionId);
    }

    /// @dev Callback function used by VRF Coordinator
    /// @param _requestId Request ID
    /// @param _randomWords Random numbers provided by VRF
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        VRFRequestType requestType = _vrfRequestType[_requestId];

        if (requestType == VRFRequestType.Cure) {
            uint256 doctorID = _vrfRequestDoctor[_requestId];
            uint256 potionDrank = potionUsed[doctorID];
            uint256 successRate = _getCureSuccessRate(potionDrank - 1);

            _vrfRequestPending[doctorID] = false;

            if (uint256(keccak256(abi.encode(_randomWords[0]))) % BASIS_POINT < successRate) {
                uint256 epoch = currentEpoch;
                curedDoctorsPerEpoch[epoch] += 1;

                _updateDoctorStatusStorage(doctorID, Status.Healthy);
                _addDoctorToHealthySet(doctorID);

                emit DoctorCured(doctorID, epoch);
            }
        } else if (requestType == VRFRequestType.Infection) {
            uint256 nextEpochCached = currentEpoch + 1;
            uint256 epochVRFRequestCached = _epochVRFRequest[nextEpochCached];

            if (_requestId != epochVRFRequestCached) {
                revert InvalidRequestId();
            }

            if (_epochVRFNumber[epochVRFRequestCached] != 0) {
                revert VRFAlreadyRequested();
            }

            _epochVRFNumber[_requestId] = _randomWords[0];

            emit RandomWordsFulfilled(nextEpochCached, _requestId);
        } else {
            revert VRFUnknownRequest();
        }
    }
}