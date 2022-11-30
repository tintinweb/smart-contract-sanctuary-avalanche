/**
 *Submitted for verification at snowtrace.io on 2022-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 *
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
    function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

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
        returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

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

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function getCureSuccessRate(uint256 potionDrank) external view returns (uint256);

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

interface ILaunchpeg is IERC721Enumerable {
    function devMint(uint256 amount) external;
}

interface IApothecary {
    struct BrewLog {
        uint256 timestamp;
        uint256 doctorID;
        bool brewPotion;
    }

    event PotionClaimed(uint256 indexed doctorID);
    event PotionBrewed(uint256 indexed doctorID);
    event PotionsAdded(uint256 amount);
    event PotionsRemoved(uint256 amount);

    event ClaimStartTimeSet(uint256 timestamp);
    event DifficultySet(uint256[] difficulty);
    event GameAddressSet(address plagueGame);

    // Contract addresses
    function plagueGame() external view returns (IPlagueGame);
    function potions() external view returns (ILaunchpeg);
    function doctors() external view returns (IERC721);

    // Contract settings
    function claimStartTime() external view returns (uint256);
    function getDifficulty(uint256 epoch) external view returns (uint256);
    function AMOUNT_OF_DEAD_DOCTORS_TO_BREW() external view returns (uint256);

    // Contract interractions
    function claimFirstPotions(uint256[] calldata doctorIDs) external;
    function makePotions(uint256[] calldata doctorIDs) external;
    function requestVRFforCurrentEpoch() external;

    // Doctor data
    function hasMintedFirstPotion(uint256 doctorID) external view returns (bool);
    function triedBrewInEpoch(uint256 epoch, uint256 doctorID) external view returns (bool);

    // Logs
    function totalPotionsBrewed() external view returns (uint256);
    function totalBrewsCount() external view returns (uint256);
    function getLatestBrewLogs() external view returns (BrewLog[] memory);
    function getBrewLogs(uint256 doctorId, uint256 count) external view returns (BrewLog[] memory);
    function getTotalBrewsCountForDoctor(uint256 doctorID) external view returns (uint256);

    // Admin
    function setClaimStartTime(uint256 newClaimStartTime) external;
    function setDifficulty(uint256[] calldata difficultyPerEpoch) external;
    function setGameAddress(IPlagueGame newGameAddress) external;
    function addPotions(uint256[] calldata potionIds) external;
    function removePotions(uint256 amount) external;
}

/// @author Trader Joe
/// @title Apothecary
/// @notice Contract used to distribute potions to doctors
contract Apothecary is IApothecary, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    /// @notice Contract address of the plague game
    IPlagueGame public override plagueGame;
    /// @notice Contract address of the potion NFTs
    ILaunchpeg public immutable override potions;
    /// @notice Contract address of the plague doctor NFTs
    IERC721 public immutable override doctors;

    /// @notice Timestamp for Apothecary to allow plague doctors to brew potions
    uint256 public override claimStartTime;
    /// @notice Amount of dead doctors necessary to try to brew a potion
    uint256 public constant override AMOUNT_OF_DEAD_DOCTORS_TO_BREW = 5;
    /// @dev Probability for a doctor to receive a potion when he tries to brew one.
    /// @dev difficulty decreases from 1 (100% probability) to 100,000 (0.001% probability)
    uint256[] private _difficultyPerEpoch;

    /// @notice Used to check if a doctor already minted its first potion
    mapping(uint256 => bool) public override hasMintedFirstPotion;
    /// @notice Keep track if a plague doctor has tried to brew in an epoch
    /// @dev Mapping from the epoch index to plague doctor ID to tried state
    mapping(uint256 => mapping(uint256 => bool)) public override triedBrewInEpoch;

    /// @notice Total number of plague doctors brew attempts
    uint256 public override totalBrewsCount;
    /// @notice Total number of succesful brews
    uint256 public override totalPotionsBrewed;
    /// @dev Ordered brew logs of all plague doctors
    BrewLog[] private _allBrewLogs;
    /// @dev Brew logs of the plague doctors
    mapping(uint256 => BrewLog[]) private _doctorBrewLogs;
    /// @dev Number of latest brew logs to keep track of
    uint256 private constant RECENT_BREW_LOGS_COUNT = 100;

    /// @dev Potions owned by the contract
    uint256[] private _potionsOwnedByContract;

    /// @notice VRF numbers generated for epochs
    mapping(uint256 => uint256) private _epochVRFNumber;
    /// @notice Epoch index to VRF request id
    mapping(uint256 => uint256) private _epochRequestID;
    /// @dev Address of the VRF coordinator
    VRFCoordinatorV2Interface private immutable _vrfCoordinator;
    /// @dev VRF subscription ID
    uint64 private immutable _subscriptionId;
    /// @dev VRF key hash
    bytes32 private immutable _keyHash;
    /// @dev Max gas used on the VRF callback
    uint32 private immutable _maxGas;

    /**
     * Constructor *
     */

    /// @dev constructor
    /// @param _plagueGame Address of the plague game contract
    /// @param _potions Address of the potions contract
    /// @param _doctors Address of the doctors contract
    /// @param _claimStartTime Start time for plague doctors to claim potions
    /// @param difficultyPerEpoch_ Probability for a group of 5 doctors to receive a potion on brew
    /// @param vrfCoordinator_ Address of the VRF coordinator contract
    /// @param subscriptionId_ VRF subscription ID
    /// @param keyHash_ VRF key hash
    /// @param maxGas_ Max gas used on the VRF callback
    constructor(
        IPlagueGame _plagueGame,
        ILaunchpeg _potions,
        IERC721Enumerable _doctors,
        uint256 _claimStartTime,
        uint256[] memory difficultyPerEpoch_,
        VRFCoordinatorV2Interface vrfCoordinator_,
        uint64 subscriptionId_,
        bytes32 keyHash_,
        uint32 maxGas_
    ) VRFConsumerBaseV2(address(vrfCoordinator_)) {
        setClaimStartTime(_claimStartTime);
        setDifficulty(difficultyPerEpoch_);
        setGameAddress(_plagueGame);

        potions = _potions;
        doctors = _doctors;

        // VRF setup
        _vrfCoordinator = vrfCoordinator_;
        _subscriptionId = subscriptionId_;
        _keyHash = keyHash_;
        _maxGas = maxGas_;
    }

    /**
     * External Functions *
     */

    /// @notice Claims the intial potion for an array of doctors
    /// @param _doctorIDs Array of doctor IDs
    function claimFirstPotions(uint256[] calldata _doctorIDs) external override nonReentrant {
        if (block.timestamp < claimStartTime) {
            revert ClaimNotStarted();
        }

        uint256 doctorIDsLength = _doctorIDs.length;
        uint256 potionTotalSupply = potions.totalSupply();

        for (uint256 i = 0; i < doctorIDsLength; ++i) {
            uint256 doctorID = _doctorIDs[i];

            if (hasMintedFirstPotion[doctorID]) {
                revert DoctorAlreadyClaimed();
            }

            hasMintedFirstPotion[doctorID] = true;

            potions.devMint(1);
            potions.transferFrom(address(this), doctors.ownerOf(doctorID), potionTotalSupply++);

            emit PotionClaimed(doctorID);
        }
    }

    /// @notice Tries to brew a potion using 5 dead doctors
    /// @dev Can be used with several batches of 5 dead doctors
    /// @param _doctorIDs Array of doctor IDs
    function makePotions(uint256[] calldata _doctorIDs) external override nonReentrant {
        if (!plagueGame.isGameStarted()) {
            revert GameNotStarted();
        }

        if (plagueGame.isGameOver()) {
            revert GameEnded();
        }

        uint256 currentEpoch = plagueGame.currentEpoch();
        uint256 randomNumber = _epochVRFNumber[currentEpoch];
        if (randomNumber == 0) {
            revert VRFResponseMissing();
        }

        uint256 doctorIDsLength = _doctorIDs.length;
        if (doctorIDsLength == 0 || doctorIDsLength % AMOUNT_OF_DEAD_DOCTORS_TO_BREW != 0) {
            revert InvalidDoctorIdsLength();
        }

        // Try brewing for every doctor
        for (uint256 i = 0; i < doctorIDsLength; ++i) {
            if (doctors.ownerOf(_doctorIDs[i]) != msg.sender) {
                revert DoctorNotOwnedBySender();
            }

            if (plagueGame.doctorStatus(_doctorIDs[i]) != IPlagueGame.Status.Dead) {
                revert DoctorNotDead();
            }

            if (triedBrewInEpoch[currentEpoch][_doctorIDs[i]]) {
                revert DoctorAlreadyBrewed();
            }

            _tryBrew(_doctorIDs[i], currentEpoch, randomNumber);
        }

        totalBrewsCount += doctorIDsLength / 5;
    }

    /// @notice Request a random number from VRF for the current epoch
    function requestVRFforCurrentEpoch() external override {
        uint256 currentEpoch = plagueGame.currentEpoch();

        if (_epochRequestID[currentEpoch] != 0) {
            revert VRFAlreadyRequested();
        }

        _epochRequestID[currentEpoch] = _vrfCoordinator.requestRandomWords(_keyHash, _subscriptionId, 3, _maxGas, 1);
    }

    /**
     * View Functions *
     */

    /// @notice Fetches the makePotion() difficulty for the epoch
    /// After reaching the end of the difficulty array, the last value is returned
    /// @param _epoch Epoch
    /// @return difficulty Difficulty for the considered epoch
    function getDifficulty(uint256 _epoch) public view override returns (uint256 difficulty) {
        if (_epoch == 0) {
            return difficulty = 0;
        }

        uint256 difficultyPerEpochLength = _difficultyPerEpoch.length;
        difficulty = _epoch > difficultyPerEpochLength - 1
            ? _difficultyPerEpoch[difficultyPerEpochLength - 1]
            : _difficultyPerEpoch[_epoch - 1];
    }

    /// @notice Returns the total number of brew attempts from a plague doctor
    /// @param _doctorID Token ID of plague doctor
    /// @return doctorBrewsCount Number of brew attempts from plague doctor
    function getTotalBrewsCountForDoctor(uint256 _doctorID) external view override returns (uint256 doctorBrewsCount) {
        doctorBrewsCount = _getTotalBrewsCount(_doctorID);
    }

    /// @notice Returns the latest brew logs
    /// @return lastBrewLogs Latest brew logs
    function getLatestBrewLogs() external view override returns (BrewLog[] memory lastBrewLogs) {
        uint256 allLogsCount = _allBrewLogs.length;
        uint256 length = allLogsCount > RECENT_BREW_LOGS_COUNT ? RECENT_BREW_LOGS_COUNT : allLogsCount;
        lastBrewLogs = new BrewLog[](length);

        for (uint256 i = 0; i < length; ++i) {
            lastBrewLogs[i] = _allBrewLogs[allLogsCount - i - 1];
        }
    }

    /// @notice Returns the [n] brew logs of a plague doctor
    /// @dev Returns [n] number of brew logs if plague doctor has brewed up to [n] times
    /// @param _doctorID Token ID of plague doctor
    /// @param _count Number of latest brew logs to return
    /// @return lastNBrewLogs Last [n] brew logs of plague doctor
    function getBrewLogs(uint256 _doctorID, uint256 _count) external view override returns (BrewLog[] memory) {
        uint256 totalDoctorBrews = _getTotalBrewsCount(_doctorID);
        uint256 checkedLength = _count < totalDoctorBrews ? _count : totalDoctorBrews;
        BrewLog[] memory lastNBrewLogs = new BrewLog[](checkedLength);

        uint256 j = totalDoctorBrews;
        for (uint256 i = checkedLength; i > 0;) {
            unchecked {
                --i;
                --j;
            }

            lastNBrewLogs[i] = _doctorBrewLogs[_doctorID][j];
        }

        return lastNBrewLogs;
    }

    /**
     * Owner Functions
     */

    /// @notice Sets the start timestamp for claiming potions
    /// @dev Start time can only be set in the future
    /// @param _startTime Start timestamp for claiming potions
    function setClaimStartTime(uint256 _startTime) public override onlyOwner {
        if (claimStartTime != 0 && block.timestamp >= claimStartTime) {
            revert ClaimHasStarted();
        }
        if (_startTime < block.timestamp) {
            revert InvalidStartTime();
        }

        claimStartTime = _startTime;

        emit ClaimStartTimeSet(_startTime);
    }

    /// @notice Sets the difficulty of brewing a free potion
    /// @dev Probability is calculated as inverse of difficulty. (1 / difficulty)
    /// @param difficultyPerEpoch_ Difficulty of brewing a free potion
    function setDifficulty(uint256[] memory difficultyPerEpoch_) public override onlyOwner {
        uint256 difficultyPerEpochLength = difficultyPerEpoch_.length;
        for (uint256 i = 1; i < difficultyPerEpochLength; ++i) {
            if (difficultyPerEpoch_[i] < 1 || difficultyPerEpoch_[i] > 100_000) {
                revert InvalidDifficulty();
            }
        }
        _difficultyPerEpoch = difficultyPerEpoch_;

        emit DifficultySet(difficultyPerEpoch_);
    }

    /// @notice Updates the game address
    /// @dev Can only be called before the game start, both the previous contract and the new one are checked
    /// @param _plagueGame New game contract
    function setGameAddress(IPlagueGame _plagueGame) public override onlyOwner {
        // On deployment plagueGame is not set yet so we only check the new contract
        if (_plagueGame.isGameStarted() || (address(plagueGame) != address(0) && plagueGame.isGameStarted())) {
            revert GameAlreadyStarted();
        }

        plagueGame = _plagueGame;

        emit GameAddressSet(address(_plagueGame));
    }

    /// @notice Transfer potions from owner to the Apothecary contract
    /// @dev Potion IDs should be approved before this function is called
    /// @param _potionIDs Potion IDs to be transferred from owner to Apothecary contract
    function addPotions(uint256[] calldata _potionIDs) external override onlyOwner {
        for (uint256 i = 0; i < _potionIDs.length; ++i) {
            potions.transferFrom(msg.sender, address(this), _potionIDs[i]);
            _potionsOwnedByContract.push(_potionIDs[i]);
        }
        emit PotionsAdded(_potionIDs.length);
    }

    /// @notice Transfers potions from the Apothecary contract to the owner
    /// @dev Potion IDs should be owned by the Apothecary contract
    /// @param _amount Number of potions to be transferred from the Apothecary contract to the owner
    function removePotions(uint256 _amount) external override onlyOwner {
        for (uint256 i = 0; i < _amount; ++i) {
            _sendPotion(msg.sender);
        }
        emit PotionsRemoved(_amount);
    }

    /**
     * Private and Internal Functions *
     */

    /// @notice Compute random chance for a plague doctor to win a free potion
    /// @dev doctor is alive and has not brewed in current epoch
    /// @param _doctorID Token ID of the plague doctor
    function _tryBrew(uint256 _doctorID, uint256 _currentEpoch, uint256 _randomNumber) private {
        BrewLog memory brewLog;
        brewLog.doctorID = _doctorID;
        brewLog.timestamp = block.timestamp;

        triedBrewInEpoch[_currentEpoch][_doctorID] = true;

        uint256 randomNumber = uint256(keccak256(abi.encode(_randomNumber, _doctorID)));

        // Difficulty is considered by batches of 5 doctors
        // So we multiply the difficulty by 5 to get the difficulty of a single doctor
        if (randomNumber % (getDifficulty(_currentEpoch) * AMOUNT_OF_DEAD_DOCTORS_TO_BREW) == 0) {
            brewLog.brewPotion = true;
            ++totalPotionsBrewed;

            _sendPotion(doctors.ownerOf(_doctorID));
            emit PotionBrewed(_doctorID);
        } else {
            brewLog.brewPotion = false;
        }

        _doctorBrewLogs[_doctorID].push(brewLog);
        _allBrewLogs.push(brewLog);
    }

    /// @dev Sends a potion to the designated recipient
    /// @param _recipient Address of the recipient
    function _sendPotion(address _recipient) private {
        uint256 potionID = _getPotionID();

        potions.transferFrom(address(this), _recipient, potionID);
        _potionsOwnedByContract.pop();
    }

    /// @notice Returns first token ID of potions owned by Apothecary contract
    /// @dev Reverts if no potions is owned by Apothecary contract
    /// @return potionID First potion ID owned by Apothecary contract
    function _getPotionID() private view returns (uint256 potionID) {
        uint256 potionsOwnedByContractLength = _potionsOwnedByContract.length;

        if (potionsOwnedByContractLength == 0) {
            revert NoPotionLeft();
        }

        potionID = _potionsOwnedByContract[potionsOwnedByContractLength - 1];
    }

    /// @notice Callback by VRFConsumerBaseV2 to pass VRF results
    /// @dev See Chainlink {VRFConsumerBaseV2-fulfillRandomWords}
    /// @param _requestID Request ID
    /// @param _randomWords Random numbers provided by VRF
    function fulfillRandomWords(uint256 _requestID, uint256[] memory _randomWords) internal override {
        uint256 currentEpoch = plagueGame.currentEpoch();

        if (_epochRequestID[currentEpoch] != _requestID) {
            revert InvalidVrfRequestID();
        }

        _epochVRFNumber[currentEpoch] = _randomWords[0];
    }

    /// @notice Returns the total number of brew attempts from a plague doctor
    /// @param _doctorID Token ID of plague doctor
    /// @return doctorBrewsCount Number of brew attempts from plague doctor
    function _getTotalBrewsCount(uint256 _doctorID) private view returns (uint256 doctorBrewsCount) {
        doctorBrewsCount = _doctorBrewLogs[_doctorID].length;
    }
}