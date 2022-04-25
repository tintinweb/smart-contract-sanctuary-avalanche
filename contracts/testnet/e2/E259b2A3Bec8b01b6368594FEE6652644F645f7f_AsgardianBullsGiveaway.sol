//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title AsgardianBulls Giveaway
/// @notice This contract handles selecting the AsgardianBulls NFT collection giveaway winners,
///         storing a history of giveaway details and everything else to do with the giveaway.
/// @dev Contract follows standard Solidity lang style guide utilizing OpenZeppelin contract interface
contract AsgardianBullsGiveaway is Ownable {

    uint256 public constant MAX_TOTAL_SUPPLY = 7812;
    uint256 public constant WIN_RATE_DENOMINATOR = 10000;

    // AsgardianBulls Mainnet AVAX C-Chain Contract: 0xf6aa5be7948da9db6287c60fcd5f82f7b8b05dcb
    IERC721Enumerable public asgardianBullsTokenContract;

    // totalWinNumber => BullWinner
    mapping(uint256 => BullWinner) public bullWinners;

    // tokenId => BullWinDetail
    mapping(uint256 => BullWinDetail) public bullWinDetails;

    // giveawayId => GiveawayDetail
    mapping(uint256 => GiveawayDetail) public giveawayDetails;

    // 1000/10000 (WIN_RATE_DENOMINATOR) is 10% drop per win, this number is modifiable by an admin
    uint256 public winRateDropPerWin = 1000;

    // 1000/10000 (WIN_RATE_DENOMINATOR) is 10% minimum win rate, this number is modifiable by an admin
    // The win rate can never go below this threshold no matter how many times a single bull has won
    uint256 public minimumWinRate = 1000;

    // Sum of total winners including inclusive of all giveaways
    uint256 private totalWinnerCount;

    // Block number of the last time the win rate was reset
    uint256 public latestWinResetBlock;

    uint256[] public legendaryBullTokenIds;
    uint256[] public blacklistedTokenIds;

    struct GiveawayDetail {
        uint256 id;
        uint256 randomNumber;
        uint256 numberOfWinners;
        uint256 timestamp;
    }

    GiveawayDetail giveawayDetail;

    struct BullWinner {
        uint256 id;
        uint256 giveawayId;
        uint256 tokenId;
        address bullWinnerAddress;
    }

    BullWinner bullWinner;

    struct BullWinDetail {
        uint256 tokenId;
        uint256 timesWonSinceLastReset;
        uint256[] winningGiveawayIds;
        uint256 latestWinResetBlock;
    }

    BullWinDetail bullWinDetail;

    uint256 private _giveawayCount;
    uint256 private _maxGiveawayDrawsPerTx = 50;
    uint256 private _currentWinnerCount;

    mapping(address => bool) private _adminAddresses;
    mapping(uint256 => uint256) private _winnerIndices;
    mapping(uint256 => uint256[]) private _winningTokenIdsByGiveaway;
    mapping(uint256 => BullWinner[]) private _winningBullsByGiveaway;
    mapping(uint256 => bool) private _legendaryBulls;
    mapping(uint256 => bool) private _blacklistedBulls;

    /// @dev Constructs the contract with the AsgardianBulls IERC721Enumerable contract
    /// @param _asgardianBullsTokenContract The address of the AsgardianBulls IERC721Enumerable contract
    constructor(address _asgardianBullsTokenContract, uint256[] memory legendaryTokenIds) {
        asgardianBullsTokenContract = IERC721Enumerable(_asgardianBullsTokenContract);

        for (uint256 i; i < legendaryTokenIds.length; i++) {
            legendaryBullTokenIds.push(legendaryTokenIds[i]);
            _legendaryBulls[legendaryTokenIds[i]] = true;
        }

        latestWinResetBlock = block.number;
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

    /// @notice Adds a legendary bull token ID
    /// @param tokenId The tokenId of the legendary bull
    function addLegendaryBull(uint256 tokenId) external onlyAdmin {
        require(!_legendaryBulls[tokenId], "tokenId already exists for legendary");
        require(tokenId > 0 && tokenId <= MAX_TOTAL_SUPPLY, "tokenId not valid");

        _legendaryBulls[tokenId] = true;
        legendaryBullTokenIds.push(tokenId);
    }

    /// @notice Removes a legendary bull token ID
    /// @param tokenId The tokenId of the legendary bull
    function removeLegendaryBull(uint256 tokenId) external onlyAdmin {
        require(_legendaryBulls[tokenId], "tokenId does not exist for legendary");
        require(tokenId > 0 && tokenId <= MAX_TOTAL_SUPPLY, "tokenId not valid");

        _legendaryBulls[tokenId] = false;

        for (uint256 i; i < legendaryBullTokenIds.length; i++) {
            if (legendaryBullTokenIds[i] == tokenId) {
                legendaryBullTokenIds[i] = 0;
                break;
            }
        }
    }

    /// @notice Adds a blacklisted bull token ID, mostly for the case of it being stolen as we don't want a thief to win any givesaways
    /// @param tokenId The tokenId of the legendary bull
    function addBlacklistBull(uint256 tokenId) external onlyAdmin {
        require(!_blacklistedBulls[tokenId], "tokenId already exists for blacklist");
        require(tokenId > 0 && tokenId < MAX_TOTAL_SUPPLY, "tokenId not valid");

        _blacklistedBulls[tokenId] = true;
        blacklistedTokenIds.push(tokenId);
    }

    /// @notice Removes a blacklisted bull token ID
    /// @param tokenId The tokenId of the legendary bull
    function removeBlacklistBull(uint256 tokenId) external onlyAdmin {
        require(_blacklistedBulls[tokenId], "tokenId does not exist for blacklist");
        require(tokenId > 0 && tokenId < MAX_TOTAL_SUPPLY, "tokenId not valid");

        _blacklistedBulls[tokenId] = false;

        for (uint256 i; i < blacklistedTokenIds.length; i++) {
            if (blacklistedTokenIds[i] == tokenId) {
                blacklistedTokenIds[i] = 0;
                break;
            }
        }
    }

    /// @notice Set the max draws allowed per giveaway selection
    /// @dev This can be lowered in case gas block limits are reached when drawing winners or bumped up if there are not gas issues
    /// @param maxGiveawayDrawsPerTx The max number of draws allowed per call to select random winners
    function setMaxGiveawayDrawsPerTx(uint256 maxGiveawayDrawsPerTx) external onlyAdmin {
        require(maxGiveawayDrawsPerTx >= 1, "Not enough draws per transaction");
        _maxGiveawayDrawsPerTx = maxGiveawayDrawsPerTx;
    }

    /// @notice Sets the win rate drop amount per win. Has to be a multiple of 100 and less than 10000 (so between 1% and 99%)
    /// @param _winRateDropPerWin The win rate drop per win to set
    function setWinRateDropPerWin(uint256 _winRateDropPerWin) external onlyAdmin {
        require(_winRateDropPerWin != WIN_RATE_DENOMINATOR, "Rate drop too high");
        require(_winRateDropPerWin % 100 == 0, "Rate drop not a multiple of 100");

        winRateDropPerWin = _winRateDropPerWin;
    }

    /// @notice Sets the minimum win rate. Has to be a multiple of 100 and greater than 0 (so between 1% and 100%)
    /// @param _minimumWinRate The minimum win rate possible
    function setMinimumWinRate(uint256 _minimumWinRate) external onlyAdmin {
        require(_minimumWinRate > 0, "Minimum win rate can not be 0");
        require(_minimumWinRate % 100 == 0, "Minimum win rate not a multiple of 100");

        minimumWinRate = _minimumWinRate;
    }

    /// @notice Essentially resets the win chance for all
    /// @dev To avoid work that isn't needed the reset isn't proactive in updating bullWinDetails but will update if the token is select as a winner
    ///      at the time of selection of winners.
    function resetWinChanceBlockForAll() external onlyAdmin {
        latestWinResetBlock = block.number;
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

    /// @notice Decrements the win count for a particular token. This is a failsafe in case a token was selected as a winner but for some reason
    ///         they weren't able to be rewarded anything. That way they aren't penalized in terms of win rate for that scenario.
    /// @param tokenId The ID of the token
    function decrementWinForTokenId(uint256 tokenId) external onlyAdmin {
        require(tokenId > 0 && tokenId < MAX_TOTAL_SUPPLY, "tokenId not valid");
        BullWinDetail storage detail = bullWinDetails[tokenId];
        if(detail.timesWonSinceLastReset > 0) {
            detail.timesWonSinceLastReset -= 1;
        }
    }

    /// @notice Initalizes a new giveaway.
    /// @dev This should always be executed before drawing winners
    /// @param numberOfWinners The number of winners for this giveaway
    /// @param randomNumber The randomNumber to use as entropy for randomly choosing winners. Should be a number generated by Chainlink VRF.
    function initializeGiveaway(uint256 numberOfWinners, uint256 randomNumber) external onlyAdmin {
        uint256 totalSupply = uint256(asgardianBullsTokenContract.totalSupply());

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
            block.timestamp
        );
    }

    /// @notice Selects random winners up to numberOfWinners
    /// @dev This uses the random number from when the giveaway was initialized which comes from Chainlink VRF. It will select an index
    ///      into the IERC721Enumberable AsgardianBulls contract and save the tokenID that won as well as other data. The same tokenID is not
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
        uint256 totalSupply = asgardianBullsTokenContract.totalSupply();
        uint256 localTotalWinnerCount = totalWinnerCount;
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

            // The same bull can't win twice in the same giveaway
            // Use the randomTokenIndex here instead of tokenId to avoid potential contract call to get tokenId
            if (_winnerIndices[randomTokenIndex] == giveawayId) {
                continue;
            }

            uint256 tokenId = asgardianBullsTokenContract.tokenByIndex(randomTokenIndex);

            // Legendary bulls are guaranteed to win so they aren't considered in the drawing
            // Blacklisted bulls aren't elligible to win
            if (_legendaryBulls[tokenId] || _blacklistedBulls[tokenId]) {
                continue;
            }

            bullWinDetail = bullWinDetails[tokenId];

            // If the bull has never won, add a new bull winner to storage
            // Otherwise, check for reset or perform win rate percentage calculation
            if (bullWinDetail.tokenId == 0) {
                addNewBullWinDetail(tokenId, giveawayId);
            } else {
                bool isReset = bullWinDetail.latestWinResetBlock < latestWinResetBlock;

                // If there was a reset that hasn't been applied, the bull automatically wins
                // otherwise perform win rate calculation
                // ex. 5 * 1000 = 5000 so 50% win rate assuming 5 wins and a winRateDropPerWin of 1000
                uint256 winRateDrop = bullWinDetail.timesWonSinceLastReset * winRateDropPerWin;

                // Avoid underflow by short circuiting if it would happen
                uint256 winRate = winRateDrop > WIN_RATE_DENOMINATOR ? 0 : WIN_RATE_DENOMINATOR - winRateDrop;

                // Win rate can't be below the minimum win rate, so there is always a chance of winning regardless of times won, albeit small
                if (winRate < minimumWinRate) {
                    winRate = minimumWinRate;
                }

                // Win rate covers a percentage of all possible numbers that could be the value of randomNumber % WIN_RATE_DENOMINATOR
                // The calculation randomNumber % WIN_RATE_DENOMINATOR is between 0 - 10000
                // ex. 1234567 % 10000 = 4567. If the win rate is 5000 (e.g. 50%), then 5000 >= 4567, they win
                bool won = isReset || winRate >= randomNumber % WIN_RATE_DENOMINATOR;
                if (won) {
                    updateBullWinDetail(tokenId, isReset, giveawayId);
                } else {
                    continue;
                }
            }

            address bullWinnerAddress = asgardianBullsTokenContract.ownerOf(tokenId);
            addBullWinner(localTotalWinnerCount, giveawayId, tokenId, bullWinnerAddress);

            localTotalWinnerCount++;
            winnerCount++;

            _winnerIndices[randomTokenIndex] = giveawayId;
            _winningTokenIdsByGiveaway[giveawayId].push(tokenId);
        }

        totalWinnerCount = localTotalWinnerCount;
        _currentWinnerCount = currentWinnerCount + winnerCount;
    }

    /// @notice Withdraw the contract funds to the owner of the contract. In case any funds are sent to the contract.
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @notice Returns all the token IDs that won for a particular giveaway
    /// @param giveawayId The ID of the giveaway to retrieve information about
    /// @return giveawayWinners Array of all the token IDs that won for a particular giveaway
    function getWinningTokenIdsForGiveaway(uint256 giveawayId) public view returns (uint256[] memory giveawayWinners) {
        GiveawayDetail memory giveaway = giveawayDetails[giveawayId];
        giveawayWinners = new uint256[](giveaway.numberOfWinners);
        giveawayWinners = _winningTokenIdsByGiveaway[giveawayId];
    }

    /// @notice Returns all the BullWinners that won for a particular giveaway
    /// @param giveawayId The ID of the giveaway to retrieve information about
    /// @return giveawayWinners Array of all the BullWinners that won for a particular giveaway
    function getWinningBullsForGiveaway(uint256 giveawayId) public view returns (BullWinner[] memory giveawayWinners) {
        GiveawayDetail memory giveaway = giveawayDetails[giveawayId];
        giveawayWinners = new BullWinner[](giveaway.numberOfWinners);
        giveawayWinners = _winningBullsByGiveaway[giveawayId];
    }

    /// @notice Returns the win rate for a specific bull token ID
    /// @param tokenId The tokenId of the bull to retrieve their win rate
    function getWinRateForToken(uint256 tokenId) public view returns (uint256) {
        require(tokenId > 0 && tokenId < MAX_TOTAL_SUPPLY, "tokenId not valid");

        BullWinDetail memory _bullWinDetail = bullWinDetails[tokenId];

        // Bull has never won before or there has been a reset since their last win
        if (_bullWinDetail.tokenId == 0 || _bullWinDetail.latestWinResetBlock < latestWinResetBlock) {
            return 100;
        }

        // ex. 5 * 1000 = 5000 so 50% win rate assuming 5 wins and a winRateDropPerWin of 1000
        uint256 winRateDrop = bullWinDetail.timesWonSinceLastReset * winRateDropPerWin;

        // Avoid underflow by short circuiting if it would happen
        uint256 winRate = winRateDrop > WIN_RATE_DENOMINATOR ? 0 : WIN_RATE_DENOMINATOR - winRateDrop;

        // If the win rate is calculated to be below the minimum, they always have at least the minimumWinRate
        if (winRate < minimumWinRate) {
            return minimumWinRate / 100;
        }

        return winRate / 100;
    }

    /// @dev Adds a single BullWinner to storage
    /// @param currentId The current winner ID
    /// @param giveawayId The current giveaway ID
    /// @param tokenId The tokenId of the winning token
    /// @param bullWinnerAddress The address of owner of the token ID that won
    function addBullWinner(
        uint256 currentId,
        uint256 giveawayId,
        uint256 tokenId,
        address bullWinnerAddress
    ) internal {
        bullWinner = BullWinner(currentId, giveawayId, tokenId, bullWinnerAddress);
        bullWinners[currentId] = bullWinner;
        _winningBullsByGiveaway[giveawayId].push(bullWinner);
    }

    /// @dev Adds a new bull winner with one time won
    /// @param tokenId The tokenId of the winning bull
    /// @param giveawayId The ID of the giveaway that the bull won
    function addNewBullWinDetail(uint256 tokenId, uint256 giveawayId) internal {
        BullWinDetail storage detail = bullWinDetails[tokenId];
        detail.tokenId = tokenId;
        detail.timesWonSinceLastReset = 1;
        detail.winningGiveawayIds.push(giveawayId);
        detail.latestWinResetBlock = latestWinResetBlock;
    }

    /// @dev Updates the win details for a particular bull
    /// @param tokenId The tokenId of the bull to update
    /// @param reset Indicates if the bull should be reset
    /// @param giveawayId The ID of the giveaway that the bull won
    function updateBullWinDetail(
        uint256 tokenId,
        bool reset,
        uint256 giveawayId
    ) internal {
        bullWinDetail = bullWinDetails[tokenId];

        // If reset, update latest win block and times won since last reset, otherwise increment times won
        if (reset) {
            bullWinDetail.latestWinResetBlock = latestWinResetBlock;
            bullWinDetail.timesWonSinceLastReset = 1;
        } else {
            bullWinDetail.timesWonSinceLastReset += 1;
        }
        bullWinDetail.winningGiveawayIds.push(giveawayId);
        bullWinDetails[tokenId] = bullWinDetail;
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