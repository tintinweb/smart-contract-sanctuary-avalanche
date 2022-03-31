//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ShmoneyPanda Giveaway
/// @notice This contract handles selecting the ShmoneyPanda NFT collection giveaway winners,
///         storing a history of giveaway details and everything else to do with the giveaway.
/// @dev Contract follows standard Solidity lang style guide utilizing OpenZeppelin contract interface
contract ShmoneyPandaGiveaway is Ownable, ReentrancyGuard {
    // ShmoneyPanda Mainnet AVAX C-Chain Contract: 0x930C642464e6D5b5a6Ac4044ba89152B5271E786
    IERC721Enumerable public shmoneyPandaTokenContract;

    mapping(uint256 => PandaWinner) public pandaWinners;
    mapping(uint256 => GiveawayDetail) public giveawayDetails;

    uint256 public constant ONE_DAY_IN_SECONDS = 24 * 60 * 60;
    uint256 public claimDeadlineSeconds = ONE_DAY_IN_SECONDS * 10;

    struct GiveawayDetail {
        uint256 id;
        uint256 randomNumber;
        uint256 numberOfWinners;
        uint256 totalGiveawayAmount;
        uint256 giveawayAmountPerWinner;
        uint256 timestamp;
    }

    GiveawayDetail giveawayDetail;

    struct PandaWinner {
        uint256 id;
        uint256 giveawayId;
        uint256 tokenId;
        address pandaWinnerAddress;
    }

    PandaWinner pandaWinner;

    uint256 private _giveawayCount;
    uint256 private _maxGiveawayDrawsPerTx = 50;
    uint256 private _totalWinnerCount;
    uint256 private _currentWinnerCount;

    mapping(address => bool) private _adminAddresses;
    mapping(uint256 => uint256) private _winnerIndices;
    mapping(address => mapping(uint256 => uint256)) private _addressClaimCountByGiveawayId;
    mapping(uint256 => uint256[]) private _winnersByGiveaway;

    /// @dev Constructs the contract with the ShmoneyPanda IERC721Enumerable contract
    /// @param _shmoneyPandaTokenAddress The address of the ShmoneyPanda IERC721Enumerable contract
    constructor(address _shmoneyPandaTokenAddress) {
        shmoneyPandaTokenContract = IERC721Enumerable(_shmoneyPandaTokenAddress);
    }

    /// @dev Modifier to restrict certain contract functionality to the owner or approved admins.
    modifier onlyAdmin() {
        require(_msgSender() == owner() || _adminAddresses[_msgSender()], "Caller is not an admin or contract owner");
        _;
    }

    /// @notice Adds an address to the list of contract administrators
    /// @param adminAddress The address of an admin to add
    function addAdmin(address adminAddress) external onlyOwner {
        _adminAddresses[adminAddress] = true;
    }

    /// @notice Removes an address from the list of contract administrators
    /// @param adminAddress The address of an admin to remove
    function removeAdmin(address adminAddress) external onlyOwner {
        _adminAddresses[adminAddress] = false;
    }

    /// @notice Set the max draws allowed per giveaway selection
    /// @dev This can be lowered in case gas block limits are reached when drawing winners or bumped up if there are not gas issues
    function setMaxGiveawayDrawsPerTx(uint256 maxGiveawayDrawsPerTx) external onlyAdmin {
        require(maxGiveawayDrawsPerTx >= 1, "Not enough draws per transaction");
        _maxGiveawayDrawsPerTx = maxGiveawayDrawsPerTx;
    }

    /// @notice Sets the time in seconds for the deadline to claim
    /// @dev This will be compared with the timestamp for when the giveaway was initialized when someone attempts to claim a reward
    /// @param deadlineSeconds The amount of seconds past when the giveaway was started to allow reward claims
    function setClaimDeadline(uint256 deadlineSeconds) external onlyAdmin {
        require(deadlineSeconds >= ONE_DAY_IN_SECONDS, "Must allow at least one day to claim");
        claimDeadlineSeconds = deadlineSeconds;
    }

    /// @notice Sets a new random giveaway number for the giveaway ID
    /// @dev This is just a failsafe in case the randomNumber originally given in initializeGiveaway can't mathematically choose enough unique winners.
    /// @param giveawayId The ID of the giveaway to update the random number used
    /// @param randomNumber The random number to set for the giveaway
    function updateGiveawayRandomNumber(uint256 giveawayId, uint256 randomNumber) external onlyAdmin {
        require(giveawayId > 0 && giveawayId <= _giveawayCount, "Giveaway ID not valid");
        require(randomNumber > 1, "Random Number not valid");

        giveawayDetails[giveawayId].randomNumber = randomNumber;
    }

    /// @notice Initalizes a new giveaway by funding the contract with claimable winnings along with other giveaway initialization
    /// @dev This should always be executed before drawing winners
    /// @param numberOfWinners The number of winners for this giveaway
    /// @param randomNumber The randomNumber to use as entropy for randomly choosing winners. Should be a number generated by Chainlink VRF.
    function initializeGiveaway(uint256 numberOfWinners, uint256 randomNumber) external payable onlyAdmin {
        uint256 totalSupply = uint256(shmoneyPandaTokenContract.totalSupply());

        require(msg.value >= 1, "Giveaway amount too small");
        require(numberOfWinners >= 1, "Not enough winners");
        require(numberOfWinners <= totalSupply, "Too many winners");
        require(randomNumber >= 1, "Random number is invalid");

        // Giveaways will start at 1
        _giveawayCount += 1;
        _currentWinnerCount = 0;

        giveawayDetails[_giveawayCount] = GiveawayDetail(
            _giveawayCount,
            randomNumber,
            numberOfWinners,
            msg.value,
            msg.value / numberOfWinners,
            block.timestamp
        );
    }

    /// @notice Selects random winners up to numberOfWinners
    /// @dev This uses the random number from when the giveaway was initialized which comes from Chainlink VRF. It will select an index
    ///      into the IERC721Enumberable ShmoneyPanda contract and save the tokenID that won as well as other data. The same tokenID is not
    ///      allowed to win more than once in the same giveaway
    /// @param numberOfDraws The number of attempts to draw a winner. Allows for drawing a subset of winners in case gas limits are reached
    ///                      when drawing lots of winners.
    function selectRandomWinners(uint256 numberOfDraws) external onlyAdmin {
        require(numberOfDraws >= 1, "Not enough winner draws");
        require(numberOfDraws <= _maxGiveawayDrawsPerTx, "Too many winner draws in one transaction");

        uint256 currentWinnerCount = _currentWinnerCount;
        giveawayDetail = giveawayDetails[_giveawayCount];
        uint256 totalNumberOfWinners = giveawayDetail.numberOfWinners;

        require(currentWinnerCount <= totalNumberOfWinners, "All winners already selected for current giveaway");

        uint256 giveawayId = giveawayDetail.id;
        uint256 totalSupply = shmoneyPandaTokenContract.totalSupply();
        uint256 totalWinnerCount = _totalWinnerCount;
        uint256 randomNumber = giveawayDetail.randomNumber;

        uint256 winnerCount;
        for (uint256 i; i < numberOfDraws; i++) {
            // Already drew the max # of winners
            if (currentWinnerCount + winnerCount >= totalNumberOfWinners) {
                break;
            }

            uint256 randomTokenIndex = uint256(
                keccak256(abi.encode(randomNumber, i + currentWinnerCount + winnerCount))
            ) % totalSupply;

            // The same token can't win twice in the same giveaway
            if (_winnerIndices[randomTokenIndex] == giveawayId) {
                continue;
            }

            uint256 tokenId = shmoneyPandaTokenContract.tokenByIndex(randomTokenIndex);
            address pandaWinnerAddress = shmoneyPandaTokenContract.ownerOf(tokenId);

            addPandaWinner(totalWinnerCount, giveawayId, tokenId, pandaWinnerAddress);

            totalWinnerCount++;
            winnerCount++;

            _winnerIndices[randomTokenIndex] = giveawayId;
            _addressClaimCountByGiveawayId[pandaWinnerAddress][giveawayId] += 1;
            _winnersByGiveaway[giveawayId].push(tokenId);
        }

        _totalWinnerCount = totalWinnerCount;
        _currentWinnerCount = currentWinnerCount + winnerCount;
    }

    /// @notice Withdraw the contract funds to the owner of the contract. In case there are any unclaimed rewards or fractional funds leftover
    ///         or something else goes awry, the funds won't be stuck in the contract.
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @notice Claim any available winnings for the address executing the transaction, transfers the funds if any are claimable
    /// @dev Calculates the total claimable amount across all giveaways
    function claim() external nonReentrant {
        address addressForClaim = _msgSender();
        uint256 claimTotal;

        uint256 currentGiveawayId = _giveawayCount;
        uint256 currentTimestamp = uint256(block.timestamp);

        // Giveaway IDs start at 1 and not 0
        for (uint256 giveawayId = 1; giveawayId <= currentGiveawayId; giveawayId++) {
            uint256 claimsPerGiveaway = _addressClaimCountByGiveawayId[addressForClaim][giveawayId];

            if (claimsPerGiveaway > 0) {
                GiveawayDetail memory giveaway = giveawayDetails[giveawayId];

                // If the deadline to claim has not passed then add to the total claimable amount
                if (currentTimestamp <= giveaway.timestamp + claimDeadlineSeconds) {
                    claimTotal += claimsPerGiveaway * giveaway.giveawayAmountPerWinner;

                    // Zero out the claim amount to prevent multiple claims. Winners are still kept in the storage elsewhere
                    _addressClaimCountByGiveawayId[addressForClaim][giveawayId] = 0;
                }
            }
        }

        require(claimTotal > 0, "Nothing to claim");
        require(address(this).balance >= claimTotal, "Insufficient funds in contract");
        payable(addressForClaim).transfer(claimTotal);
    }

    /// @notice Calculates the total claimable amount for an address
    /// @dev This is the same logic as in the actual claim() but without transferring funds or zeroing the claims
    function claimableAmount(address claimAddress) public view returns (uint256 claimTotal) {
        uint256 currentGiveawayId = _giveawayCount;
        uint256 currentTimestamp = uint256(block.timestamp);

        for (uint256 giveawayId = 1; giveawayId <= currentGiveawayId; giveawayId++) {
            uint256 claimsPerGiveaway = _addressClaimCountByGiveawayId[claimAddress][giveawayId];

            if (claimsPerGiveaway > 0) {
                GiveawayDetail memory giveaway = giveawayDetails[giveawayId];

                // If the deadline to claim has not passed then add to the total claimable amount
                if (currentTimestamp <= giveaway.timestamp + claimDeadlineSeconds) {
                    claimTotal += claimsPerGiveaway * giveaway.giveawayAmountPerWinner;
                }
            }
        }
    }

    /// @notice Returns all the token IDs that won for a particular giveaway
    function getWinnersForGiveaway(uint256 giveawayId) public view returns (uint256[] memory giveawayWinners) {
        GiveawayDetail memory giveaway = giveawayDetails[giveawayId];
        giveawayWinners = new uint256[](giveaway.numberOfWinners);
        giveawayWinners = _winnersByGiveaway[giveawayId];
    }

    /// @dev Adds a single PandaWinner to storage
    /// @param currentId The current winner ID
    /// @param giveawayId The current giveaway ID
    /// @param tokenId The tokenId of the winning token
    /// @param pandaWinnerAddress The address of owner of the token ID that won
    function addPandaWinner(
        uint256 currentId,
        uint256 giveawayId,
        uint256 tokenId,
        address pandaWinnerAddress
    ) internal {
        pandaWinner = PandaWinner(currentId, giveawayId, tokenId, pandaWinnerAddress);
        pandaWinners[currentId] = pandaWinner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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