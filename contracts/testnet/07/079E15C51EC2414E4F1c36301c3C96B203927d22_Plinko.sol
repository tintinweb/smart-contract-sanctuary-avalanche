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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract GameBase is Ownable {
    /// @notice global switch to disallow play
    bool public paused = false;

    /// @notice address of the rake distributor
    address public rakeDistributorAddress;

    /// @notice address of the treasury
    address public treasuryAddress;

    /// @notice addresses that have blacklisted themselves
    mapping(address => bool) public blacklist;

    /// @dev contracts are not allowed to flip
    modifier isEOA() {
        require(tx.origin == msg.sender, "No contracts allowed");
        _;
    }

    /// @dev users who have paused themselves cannot play
    modifier isNotPaused() {
        require(!paused, "Game is paused");
        _;
    }

    /// @dev users who have paused themselves cannot play
    modifier isNotBlacklist() {
        require(blacklist[msg.sender] != true, "You're on time out!");
        _;
    }

    /// @notice withdraws AVAX to contract owner in case of emergency
    function rescueAvax(uint256 amount) external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success);
    }

    function setPaused(bool paused_) public onlyOwner {
        paused = paused_;
    }

    function setRakeDistributorAddress(address rakeAddress) external onlyOwner {
        rakeDistributorAddress = rakeAddress;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function blacklistSelf(bool toBlacklist) external {
        blacklist[msg.sender] = toBlacklist;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract GameBet is Ownable {
    /// @notice minimum allowed bet
    uint256 public minBet = .5 ether;

    /// @notice maximum single bet amount is treasury divided by this
    uint256 public maxBetDivisor = 20;

    /// @notice maxmimum number of rounds that can be played in a single game
    /// @dev the total amount bet is the limiting factor, so this is just a reasonable-ness limit
    /// @dev on the number of rounds allowed
    uint256 public maxConsecutiveRounds = 10;

    /// @notice bet amounts per round must be a multiple of this
    uint256 public betMultiplePerRound = .01 ether;

    struct BetDetails {
        uint256 bet;
        uint256 rake;
        uint256 betPerRound;
        uint256 rakePerRound;
    }

    function validateBet(uint256 treasuryBalance, uint256 totalRake, uint numGames) internal returns(BetDetails memory) {
        // TODO: this is retarded, pass the bet in instead?
        uint256 bet = (msg.value * 10000 / (totalRake + 10000));
        uint256 rake = msg.value - bet;

        require(bet >= minBet, "Gamble more, pleb");
        // TODO: This should probably apply to the potentialWin instead of the bet amount
        // Currently this assumes 2x win values?
        require(bet <= (treasuryBalance / maxBetDivisor), "Gamble less, king");

        require(numGames > 0, "Gamble at least once, pleb");
        require(numGames <= maxConsecutiveRounds, "Gamble fewer times, king");

        uint256 betPerRound = bet / numGames;
        require(bet % numGames == 0, "Gamble an amount divisible by your bets, pleb");
        require(betPerRound % betMultiplePerRound == 0, "Gamble the right amount per bet, pleb");

        uint256 rakePerRound = rake / numGames;
        require(rake % numGames == 0, "Internal error; wrong rake amount");

        return BetDetails({
            bet: bet,
            rake: rake,
            betPerRound: betPerRound,
            rakePerRound: rakePerRound
        });
    }

    function setMinBet(uint256 minBet_) external onlyOwner {
        minBet = minBet_;
    }

    function setMaxBetDivisor(uint256 maxBetDivisor_) external onlyOwner {
        maxBetDivisor = maxBetDivisor_;
    }

    function setMaxConsecutiveRounds(uint256 maxConsecutiveRounds_) external onlyOwner {
        maxConsecutiveRounds = maxConsecutiveRounds_;
    }

    function setBetMultiple(uint256 betMultiplePerRound_) external onlyOwner {
        betMultiplePerRound = betMultiplePerRound_;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract GameChainlink is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface private vrfCoordinator;
    uint16 private _requestConfirmations = 3;
    uint32 private constant NUM_WORDS = 1;
    uint32 private _callbackGasLimit;
    bytes32 private _gasLane;
    uint64 private _subscriptionId;

    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        _gasLane = gasLane;
        _subscriptionId = subscriptionId;
        _callbackGasLimit = callbackGasLimit;
    }

    function _requestRandomWords() internal returns (uint256) {
        uint256 requestId = vrfCoordinator.requestRandomWords(
            _gasLane,
            _subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            NUM_WORDS
        );
        return requestId;
    }

    function _requestRandomWordsCount(uint32 count) internal returns (uint256) {
        uint256 requestId = vrfCoordinator.requestRandomWords(
            _gasLane,
            _subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            count
        );
        return requestId;
    }

    function getGasLane() public view returns (bytes32) {
        return _gasLane;
    }

    function setGasLane(bytes32 gasLane) public onlyOwner {
        _gasLane = gasLane;
    }

    function getSubscriptionId() public view returns (uint64) {
        return _subscriptionId;
    }

    function setSubscriptionId(uint64 subscriptionId) public onlyOwner {
        _subscriptionId = subscriptionId;
    }

    function getRequestConfirmations() public view returns (uint16) {
        return _requestConfirmations;
    }

    function setRequestConfirmations(uint16 requestConfirmations) public onlyOwner {
        _requestConfirmations = requestConfirmations;
    }

    function getCallbackGasLimit() public view returns (uint32) {
        return _callbackGasLimit;
    }

    function setCallbackGasLimit(uint32 callbackGasLimit) public onlyOwner {
        _callbackGasLimit = callbackGasLimit;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./GameBase.sol";
import "./GameBet.sol";
import "./GameChainlink.sol";


interface IRakeDistributor {
    function getTotalRake() external view returns (uint256);
    function distributeRake() external payable;
}

interface ITreasury {
    function sendPayout(address gamer, uint256 amount) external;
}

/// @title Plinko!
/// @notice Plink contract using a global treasury and multiple balls
contract Plinko is GameBase, GameBet, GameChainlink {
    enum GameState {
        CALCULATING,
        CLOSED
    }

    struct GameInfo {
        uint8 roundCount;
        GameState state;
        address creator;
        address referrer;
        uint256 betPerRound;
        uint256 rakePerRound;
        uint256 gameId;
    }

    event GameStarted(address indexed creator, uint256 indexed gameId, uint8 roundCount, address referrer, uint256 betPerRound, uint256 rakePerRound);
    event RequestedGameWinner(uint256 indexed requestId, uint256 indexed gameToClose);
    event WinnerPicked(uint256 indexed gameId, uint8[] results, uint256 sent);

    /// @notice incrementing counter for the current gameId
    uint256 public currentGameId;

    /// @notice game info structs mapped by gameId
    mapping(uint256 => GameInfo) public gameById;

    /// @notice game ids mapped by VRF request ID
    /// @dev keeps track of which request was for which game, so they can be fulfilled
    mapping(uint256 => uint256) public gameByRequestId;

    uint256 fixedBucketCount = 11;
    uint256[] private multipliers = [
        4700,
        800,
        200,
        90,
        60,
        40,
        60,
        90,
        200,
        800,
        4700
    ];
    uint256[] private probabilities = [
        2161473995576543,
        21982640842095859,
        90820964448496003,
        203697939773048819,
        373013402759878035,
        626986597240121843,
        796302060226951059,
        909179035551503875,
        978017359157904019,
        997838526004423335,
        1000000000000000000
    ];
    uint256 private divisor = 1000000000000000000;

    /// @notice so the contract can be funded
    receive() external payable {}

    /// @dev constructor
    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) GameChainlink(vrfCoordinatorV2, gasLane, subscriptionId, callbackGasLimit) {
        // TODO: REMOVE
        maxBetDivisor = 1;

        // More than the standard number of bets, here.
        maxConsecutiveRounds = 100;
        require(probabilities[probabilities.length - 1] == divisor, "Final probability is not max value");
    }

    function _createGame(
        uint8 roundCount,
        uint8 bucketCount,
        address referrer
    ) internal returns (uint256) {
        IRakeDistributor rakeDistributor = IRakeDistributor(rakeDistributorAddress);
        BetDetails memory details = validateBet(
            treasuryAddress.balance, rakeDistributor.getTotalRake(), roundCount);

        require(roundCount <= 100, "No more than 100 balls, king");
        require(bucketCount == fixedBucketCount);
        uint256 maxPayout = details.betPerRound * 47;
        require(maxPayout <= (treasuryAddress.balance / maxBetDivisor), "Gamble less, king");

        (bool success, ) = payable(treasuryAddress).call{value: details.bet}("");
        require(success);
        rakeDistributor.distributeRake{value:details.rake}();

        currentGameId++;

        GameInfo memory fi;
        fi.roundCount = roundCount;
        fi.creator = msg.sender;
        fi.referrer = referrer;
        fi.gameId = currentGameId;
        fi.state = GameState.CALCULATING;
        fi.betPerRound = details.betPerRound;
        fi.rakePerRound = details.rakePerRound;

        gameById[fi.gameId] = fi;

        uint256 requestId = _requestRandomWordsCount(roundCount);
        gameByRequestId[requestId] = fi.gameId;
        emit RequestedGameWinner(requestId, fi.gameId);

        // Synthetically adjust the game counter forward by the number of rounds.
        // This leaves gaps in the mapping, but it's useful for the offline storage.
        currentGameId += roundCount - 1;

        emit GameStarted(msg.sender, fi.gameId, roundCount, fi.referrer, fi.betPerRound, fi.rakePerRound);
        return fi.gameId;
    }

    /// @notice creates a new game
    function playGame(
        uint8 roundCount,
        uint8 bucketCount
    ) external payable isEOA isNotPaused isNotBlacklist {
        _createGame(roundCount, bucketCount, address(0));
    }
    /// @notice creates a new game
    function playReferredGame(
        uint8 roundCount,
        uint8 bucketCount,
        address referrer
    ) external payable isEOA isNotPaused isNotBlacklist {
        _createGame(roundCount, bucketCount, referrer);
    }

    /// @notice receives the random number from VRF and sees if the game was won
    /// @dev Transfers AVAX to the player if chosen correctly
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 gameId = gameByRequestId[requestId];
        GameInfo storage fi = gameById[gameId];
        ITreasury treasury = ITreasury(treasuryAddress);

        uint8[] memory results = new uint8[](fi.roundCount);
        // Instead of computing the full sent amount at each round, just increase
        // the multiplier by the bucket value. We can later multiply by the betPerRound
        // to get the full amount to send to the user (gas optimization).
        uint256 betMultiplier;

        // uint256 roundRandom = randomWords[0];
        for (uint i=0; i<fi.roundCount; i++) {
            // roundRandom  >>= 2;
            uint256 roundValue = randomWords[i] % divisor;

            for (uint8 j=0; j<fixedBucketCount; j++) {
                if (roundValue < probabilities[j]) {
                    results[i] = j;
                    betMultiplier += multipliers[j];
                    break;
                }
            }
        }

        uint256 amountToUser = fi.betPerRound * betMultiplier / 100;
        if (amountToUser > 0) {
            treasury.sendPayout(fi.creator, amountToUser);
        }

        fi.state = GameState.CLOSED;
        emit WinnerPicked(gameId, results, amountToUser);
    }

    /// @notice triggers VRF process for a given flip in case of emergency
    function forceRequestWinner(uint256 gameId) external onlyOwner {
        GameInfo storage fi = gameById[gameId];
        require(fi.state != GameState.CLOSED, "already closed");
        uint256 requestId = _requestRandomWords();
        gameByRequestId[requestId] = gameId;
        emit RequestedGameWinner(requestId, gameId);
    }

    function getGameInfo(uint256 gameId) public view returns (GameInfo memory) {
        return gameById[gameId];
    }

    function getManyGameInfo(uint256[] memory gameIds) public view returns (GameInfo[] memory) {
        uint gameIdLength = gameIds.length;
        GameInfo[] memory ret = new GameInfo[](gameIdLength);
        for( uint i = 0; i < gameIdLength; ++i ) {
            ret[i] = gameById[gameIds[i]];
        }

        return ret;
    }

    function setCurrentGameId(uint256 gameId_) external onlyOwner {
        currentGameId = gameId_;
    }
}