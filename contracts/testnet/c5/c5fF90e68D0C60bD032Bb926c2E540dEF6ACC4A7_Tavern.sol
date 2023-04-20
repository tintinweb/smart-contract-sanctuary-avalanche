// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

//**********************************************************//
//          _____  ___     _______ ____  _   _              //
//         |_   _|/ \ \   / / ____|  _ \| \ | |             //
//           | | / _ \ \ / /|  _| | |_) |  \| |             //
//           | |/ ___ \ V / | |___|  _ <| |\  |             //
//           |_/_/   \_\_/  |_____|_| \_\_| \_|             //
//                                                          //
//**********************************************************//

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}

interface AEPNFT is IERC721 {
    enum TIER {
        HUMAN,
        ZOMBIE,
        VAMPIRE
    }

    function tokenTierIndex(uint256 id) external view returns (uint256, TIER);
}

/**
 * @title Tavern for EgoVerse
 * @author PlusUltra#5117
 * @dev Contract to Tavern Game Integration
 * @notice This contract is not audited
 */
contract Tavern is VRFConsumerBaseV2, Ownable, Pausable, ReentrancyGuard {
    event Boosted(address indexed owner, uint256 indexed tokenId, uint256 indexed boostCount);
    event RewardPaid(address indexed user, uint256 indexed reward);
    event PausedStatusUpdated(bool indexed status);
    event GameResult(address indexed player, bool indexed boostSuccess);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    struct BoostedNFT {
        uint256 tokenBoostingCoolDown;
        uint256 rewardEarnedInBoost;
        uint256 rewardReleasedInBoost;
        uint256 boostCount;
        uint256 bribeEncash;
        uint256 bribeRequestId;
        uint256 totalRewardReleased;
    }

    IRewardToken public preyContract;
    AEPNFT public nftContract;

    uint256 private constant MAX_BOOST_COUNT = 5;

    uint256 public teamShare = 60;
    uint256 public totalBoosts;
    uint256 public boostStartTime;
    address public teamAddress;
    uint256 public preyPerBribe = 9000000000000000000;
    uint256 public boostInterval = 24 hours;
    uint256 public winPercentage = 25;
    uint256[] public boostedNFTList;
    uint256[] private rewardPerInterval = [2500e15, 3075e15, 4200e15];
    uint256[] private maxRewardPerBoost = [12500e15, 15375e15, 21000e15];
    bool public initialised;
    mapping(uint256 => BoostedNFT) public boostedNFTs;

    /**
     * @param _nftContract The AEP NFT contract
     * @param _preyContract The Prey token contract
     * @param _teamAddress The address of the team
     */
    constructor(
        AEPNFT _nftContract,
        IRewardToken _preyContract,
        address _teamAddress,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(0x2eD832Ba664535e5886b75D64C46EB9a228C2610) {
        nftContract = _nftContract;
        preyContract = _preyContract;
        teamAddress = _teamAddress;

        COORDINATOR = VRFCoordinatorV2Interface(0x2eD832Ba664535e5886b75D64C46EB9a228C2610);
        s_subscriptionId = _subscriptionId;
    }

    /**
     * @dev Initializes the Tavern Boosting System
     */
    function initBoosting() public onlyOwner {
        require(!initialised, "Already initialised");
        boostStartTime = block.timestamp;
        initialised = true;
    }

    /**
     * @dev Allows a user to bribe the contract to boost their NFT
     * @param _tokenId The ID of the NFT to boost
     * @notice By signing this transaction, you are agreeing to pay 9PREY tokens.
     */
    function bribe(uint256 _tokenId) public whenNotPaused nonReentrant {
        require(initialised, "Boosting System: the boosting has not started");
        require(nftContract.ownerOf(_tokenId) == msg.sender, "User must be the owner of the token");
        BoostedNFT storage boostedNFT = boostedNFTs[_tokenId];
        require(boostedNFT.boostCount < 5, "Max Boosts Reached");
        require(boostedNFT.bribeEncash == 0, "Attempt Boost before Next Bribe");
        preyContract.burn(msg.sender, preyPerBribe);
        preyContract.mint(teamAddress, (preyPerBribe * teamShare) / 100);
        boostedNFT.bribeEncash = 1;
        boostedNFT.bribeRequestId = requestRandomWords();
    }

    /**
     * @dev Boosts the specified token by increasing staking reward.
     * @param _tokenId The ID of the token to be boosted.
     * @return boostSuccess indicates whether the boost was successful or not.
     */
    function boost(uint256 _tokenId) public whenNotPaused nonReentrant returns (bool boostSuccess) {
        require(initialised, "Boosting System: the boosting has not started");
        require(nftContract.ownerOf(_tokenId) == msg.sender, "User must be the owner of the token");
        BoostedNFT storage boostedNFT = boostedNFTs[_tokenId];
        require(boostedNFT.boostCount < 5, "Max Boosts Reached");
        require(boostedNFT.bribeEncash == 1, "No Pending Bribes for Boost");
        if (boostedNFT.tokenBoostingCoolDown > 0) {
            require(
                boostedNFT.tokenBoostingCoolDown + 5 * boostInterval < block.timestamp,
                "Boost is Already Active"
            );
            // uint256[] memory tokenList = new uint[](1);
            // tokenList[0] = _tokenId;
            claimReward(_tokenId);
        }
        boostedNFT.bribeEncash = 0;
        if (!generateGameResult2(boostedNFT.bribeRequestId)) {
            emit GameResult(msg.sender, false);
            return false;
        } else {
            boostedNFT.rewardEarnedInBoost = 0;
            boostedNFT.rewardReleasedInBoost = 0;
            boostedNFT.tokenBoostingCoolDown = block.timestamp;
            boostedNFT.boostCount = boostedNFT.boostCount + 1;
            if (boostedNFT.boostCount == 1) {
                boostedNFTList.push(_tokenId);
            }
            totalBoosts = totalBoosts + 1;
            emit Boosted(msg.sender, _tokenId, boostedNFT.boostCount);
            emit GameResult(msg.sender, true);
            return true;
        }
    }

    function requestRandomWords() internal returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function _updateReward(uint256[] memory _tokenIds) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            BoostedNFT storage boostedNFT = boostedNFTs[_tokenIds[i]];
            if (
                boostedNFT.tokenBoostingCoolDown < block.timestamp + boostInterval &&
                boostedNFT.tokenBoostingCoolDown > 0
            ) {
                (, AEPNFT.TIER tokenTier) = getTokenTierIndex(_tokenIds[i]);
                uint256 tierIndex = uint256(tokenTier);
                uint256 tierReward = rewardPerInterval[tierIndex];
                uint256 maxTierReward = maxRewardPerBoost[tierIndex];

                uint256 boostedDays = ((block.timestamp - uint(boostedNFT.tokenBoostingCoolDown))) /
                    boostInterval;
                if (tierReward * boostedDays >= maxTierReward) {
                    boostedNFT.rewardEarnedInBoost = maxTierReward;
                } else {
                    boostedNFT.rewardEarnedInBoost = tierReward * boostedDays;
                }
            }
        }
    }

    /**
     * @dev Allows the owner of an NFT to claim their rewards.
     * @param _tokenId The ID of the NFT for which rewards are being claimed.
     * Requirements:
     * - The contract must not be paused.
     * - The caller must be the owner of the NFT.
     * Effects:
     * - Updates the reward for the NFT.
     * - Transfers the reward to the caller.
     * Emits: RewardPaid event with the address of the caller and the amount of reward transferred.
     */

    function claimReward(uint256 _tokenId) public whenNotPaused {
        require(
            nftContract.ownerOf(_tokenId) == msg.sender,
            "You can only claim rewards for NFTs you own!"
        );
        uint256[] memory tokenList = new uint[](1);
        tokenList[0] = _tokenId;
        _updateReward(tokenList);
        uint256 reward = 0;
        BoostedNFT storage boostedNFT = boostedNFTs[_tokenId];
        reward += boostedNFT.rewardEarnedInBoost - boostedNFT.rewardReleasedInBoost;
        boostedNFT.rewardReleasedInBoost = boostedNFT.rewardEarnedInBoost;
        boostedNFT.totalRewardReleased += reward;
        if (reward > 0) {
            preyContract.mint(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function generateGameResult2(uint256 _requestId) private view returns (bool) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        require(request.fulfilled, "request not fullfilled");
        uint256 score = (request.randomWords[0] % 100) + 1;
        return score < winPercentage;
    }

    //****************Admin Functions*********************//

    /**
     * @dev Toggles the pause state of the game.
     * @notice Only the owner of the contract can call this function.
     */
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @dev Updates the win percentage for the game.
     * @param _percentage The new win percentage to be set.
     * @notice Only the owner of the contract can call this function.
     * @notice The win percentage must be less than or equal to 100.
     */
    function updateWinPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Invalid Percentage Input");
        winPercentage = _percentage;
    }

    /**
     * @dev Updates the boost interval for the game.
     * @param _intervalInSeconds The new boost interval to be set.
     * @notice Only the owner of the contract can call this function.
     * @notice The interval must be greater than 0.
     */
    function updateBoostInterval(uint256 _intervalInSeconds) external onlyOwner {
        require(_intervalInSeconds > 0, "Invalid Interval");
        boostInterval = _intervalInSeconds;
    }

    /**
     * @dev Updates the prey amount per bribe for the game.
     * @param _newPreyAmount The new prey amount per bribe to be set.
     * @notice Only the owner of the contract can call this function.
     * @notice The prey amount must be greater than 0.
     */
    function updatePreyPerBribe(uint256 _newPreyAmount) external onlyOwner {
        require(_newPreyAmount > 0, "Invalid Prey Amount");
        preyPerBribe = _newPreyAmount;
    }

    /**
     * @dev Updates the percentage share to be transfered to team account on every bribe.
     * @param _newTeamShare The new team share to be set.
     * @notice Only the owner of the contract can call this function.
     * @notice The team share must be less than or equal to 100.
     */
    function updateTeamShare(uint256 _newTeamShare) external onlyOwner {
        require(_newTeamShare <= 100, "Invalid Tresury Share");
        teamShare = _newTeamShare;
    }

    /**
     * @dev Distributes emergency rewards to the owners of boosted NFTs.
     * This function can only be called by the contract owner.
     * It updates the reward earned by each boosted NFT and distributes the difference between the earned and released rewards to the NFT owner.
     * @notice Use only in case of emergency, Pause the contract for 5 days and then execute it.
     */
    function distributeRewardEmergency() external onlyOwner {
        uint256[] memory nftList = boostedNFTList;
        _updateReward(nftList);
        for (uint256 i = 0; i < nftList.length; i++) {
            address tokenOwner = nftContract.ownerOf(nftList[i]);
            uint256 reward = 0;
            BoostedNFT storage boostedNFT = boostedNFTs[nftList[i]];
            reward += boostedNFT.rewardEarnedInBoost - boostedNFT.rewardReleasedInBoost;
            boostedNFT.rewardReleasedInBoost = boostedNFT.rewardEarnedInBoost;
            boostedNFT.totalRewardReleased += reward;
            if (reward > 0) {
                preyContract.mint(tokenOwner, reward);
                emit RewardPaid(tokenOwner, reward);
            }
        }
    }

    //****************Read Only Functions*********************//

    /**
     * @dev Toggles the pause state of the game.
     * @notice Only the owner of the contract can call this function.
     */
    function getTokenTierIndex(
        uint256 _id
    ) public view returns (uint256 tokenIndex, AEPNFT.TIER tokenTier) {
        return (nftContract.tokenTierIndex(_id));
    }

    /**
     * @dev Total NFTs Boosted under Tavern Contract
     * @return count count of NFTs boosted.
     */
    function getBoostedNFTCount() public view returns (uint256 count) {
        return boostedNFTList.length;
    }

    /**
     * @dev Checks if the boost is active for the given token ID.
     * @param _tokenId The ID of the token.
     * @return boostIsActive True if the boost is active, false otherwise.
     */
    function isBoostActive(uint256 _tokenId) public view returns (bool boostIsActive) {
        BoostedNFT storage boostedNFT = boostedNFTs[_tokenId];
        uint256 duration = block.timestamp - boostedNFT.tokenBoostingCoolDown;

        if (boostedNFT.tokenBoostingCoolDown != 0 && duration / boostInterval < 5) {
            return true;
        }
    }

    /**
     * @dev Calculates the claimable reward for the given token ID.
     * @param _tokenId The ID of the token.
     * @return The claimable reward for the given token ID.
     */
    function calculateReward(uint256 _tokenId) public view returns (uint256) {
        uint256 claimableReward = 0;

        BoostedNFT storage boostedNFT = boostedNFTs[_tokenId];
        if (
            boostedNFT.tokenBoostingCoolDown < block.timestamp + boostInterval &&
            boostedNFT.tokenBoostingCoolDown > 0
        ) {
            (, AEPNFT.TIER tokenTier) = getTokenTierIndex(_tokenId);
            uint256 tierIndex = uint256(tokenTier);
            uint256 tierReward = rewardPerInterval[tierIndex]; // 2.5 Token
            uint256 maxTierReward = maxRewardPerBoost[tierIndex];
            uint256 totalReward = 0;

            uint256 boostedDays = ((block.timestamp - uint(boostedNFT.tokenBoostingCoolDown))) /
                boostInterval;
            if (tierReward * boostedDays >= maxTierReward) {
                totalReward = maxTierReward;
            } else {
                totalReward = tierReward * boostedDays;
            }
            claimableReward += totalReward - boostedNFT.rewardReleasedInBoost;
        }
        return claimableReward;
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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