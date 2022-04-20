// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IArena.sol";
import "./interfaces/IGame.sol";
import "./interfaces/INFT.sol";
import "./interfaces/IWorld.sol";

contract Arena is IArena, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
    constructor() {
        // _pause();
    }

    /** CONTRACTS */
    INFT public uNFT;
    IGame public uGame;
    IWorld public uWorld;

    /** EVENTS */
    event TokenStaked(address indexed owner, uint256 indexed tokenId);
    event TokensStaked(address indexed owner, uint16[] tokenIds);
    event TokenClaimed(
        address indexed owner,
        uint256 indexed tokenId,
        bool unstaked,
        uint256 earned
    );
    event TokensClaimed(address indexed owner, uint16[] tokenIds);
    event WorldStolen(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed amount
    );

    /** PUBLIC VARS */
    // Heros & Villain must be staked for minimum days before they can be unstaked
    uint256 public MINIMUM_DAYS_TO_EXIT = 1; // days;
    // Villain take a 20% tax on all $World claimed
    uint256 public Villain_TAX_PERCENTAGE = 20;
    // amount of $World earned so far
    uint256 public totalWorldEarned;

    /** PRIVATE VARS */
    // total Heros staked at this moment
    uint256 private _totalHerosStaked;
    // total Villain staked at this moment
    uint256 private _totalVillainStaked;
    // total sum of Villain rank staked
    uint256 private _totalRankStaked;
    // map all tokenIds to their original owners; ownerAddress => tokenIds
    mapping(address => uint256[]) private _ownersOfStakedTokens;
    // maps tokenId to stake
    mapping(uint256 => Stake) private _HeroArena;
    // maps rank to all Villain staked with that rank
    mapping(uint256 => Stake[]) private _VillainPatrol;
    // tracks location of each Villain in Patrol
    mapping(uint256 => uint256) private _VillainPatrolIndizes;
    // any rewards distributed when no Villain are staked
    uint256 private _unaccountedRewards = 0;
    // amount of $World due for each rank point staked
    uint256 private _WorldPerRank = 0;
    // admins
    mapping(address => bool) private _admins;

    modifier onlyAdmin() {
        require(_admins[_msgSender()], "Arena: Only admins can call this");
        _;
    }

    modifier onlyEOA() {
        require(
            tx.origin == _msgSender() || _msgSender() == address(uGame),
            "Arena: Only EOA"
        );
        _;
    }

    /** STAKING */
    function getTotalHerosStaked() external view onlyEOA returns (uint256) {
        uint64 lastAddressWrite = uNFT.getAddressWriteBlock();
        require(lastAddressWrite < block.number, "Arena: Nope!");

        return _totalHerosStaked;
    }

    function getTotalVillainStaked() external view onlyEOA returns (uint256) {
        uint64 lastAddressWrite = uNFT.getAddressWriteBlock();
        require(lastAddressWrite < block.number, "Arena: Nope!");

        return _totalVillainStaked;
    }

    function getTotalRankStaked() external view onlyEOA returns (uint256) {
        uint64 lastAddressWrite = uNFT.getAddressWriteBlock();
        require(lastAddressWrite < block.number, "Arena: Nope!");

        return _totalRankStaked;
    }

    function isStaked(uint256 tokenId) external view returns (bool) {
        return _isStaked(tokenId);
    }

    function _isStaked(uint256 tokenId) private view returns (bool) {
        address owner = uNFT.ownerOf(tokenId);

        // if token belongs to the arena it means the token is staked
        if (owner == address(this)) {
            return true;
        }

        return false;
    }

    function getStakedTokenIds(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint64 lastAddressWrite = uNFT.getAddressWriteBlock();
        require(lastAddressWrite < block.number, "Arena: Nope!");

        return _ownersOfStakedTokens[owner];
    }

    function _addStakeOwner(address owner, uint256 tokenId) private {
        _ownersOfStakedTokens[owner].push(tokenId);
    }

    function _removeStakeOwner(address owner, uint256 tokenId) private {
        uint256[] memory tokenIds = _ownersOfStakedTokens[owner];
        uint256[] memory tokenIdsNew = new uint256[](tokenIds.length - 1);

        uint256 counter = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] != tokenId) {
                tokenIdsNew[counter] = tokenIds[i];
                counter++;
            } else {
                continue;
            }
        }

        _ownersOfStakedTokens[owner] = tokenIdsNew;
    }

    function _getTokenRank(uint256 tokenId) private view returns (uint8) {
        INFT.HeroVillain memory traits = uNFT.getTokenTraits(tokenId); // Fetching the rank from the NFT itself, not from the Game contract on purpose
        return traits.rank;
    }

    function _payVillainTax(uint256 amount) private {
        if (_totalRankStaked == 0) {
            // if there's no staked Villain
            _unaccountedRewards += amount; // keep track of $World that's due to all Villain
            return;
        }
        // makes sure to include any unaccounted $World
        _WorldPerRank += (amount + _unaccountedRewards) / _totalRankStaked;
        _unaccountedRewards = 0;
    }

    function stakeManyToArena(uint16[] calldata tokenIds)
        external
        override
        whenNotPaused
        onlyEOA
        nonReentrant
    {
        uint64 lastAddressWrite = uNFT.getAddressWriteBlock();
        require(lastAddressWrite < block.number, "Arena: Nope!");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(uGame)) {
                // Don't do this step if it's a mint + stake
                require(
                    uNFT.ownerOf(tokenIds[i]) == _msgSender(),
                    "Arena: You don't own this token (stakeManyToArena)"
                );
                uNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // There may be gaps in the array for stolen tokens
            }

            if (uNFT.isHero(tokenIds[i])) {
                _stakeHero(_msgSender(), tokenIds[i]);
            } else {
                _stakeVillain(_msgSender(), tokenIds[i]);
            }
        }

        emit TokensStaked(_msgSender(), tokenIds);
    }

    function _stakeHero(address account, uint256 tokenId) private {
        Stake memory myStake = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            WorldPerRank: 0,
            stakeTimestamp: uint80(block.timestamp)
        });

        _HeroArena[tokenId] = myStake;
        _addStakeOwner(account, tokenId);
        _totalHerosStaked++;

        emit TokenStaked(account, tokenId);
    }

    function _stakeVillain(address account, uint256 tokenId) private {
        Stake memory myStake = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            WorldPerRank: _WorldPerRank,
            stakeTimestamp: block.timestamp
        });

        uint8 rank = _getTokenRank(tokenId); //traits.rank;
        _totalRankStaked += rank; // Portion of earnings ranges from 5 to 8
        _totalVillainStaked++;
        _VillainPatrolIndizes[tokenId] = _VillainPatrol[rank].length; // Store the location of the Villain in the Patrol map
        _VillainPatrol[rank].push(myStake); // Add the Villain to Patrol
        _addStakeOwner(account, tokenId);

        emit TokenStaked(account, tokenId);
    }

    /** CLAIMING / UNSTAKING */
    function claimManyFromArena(uint16[] calldata tokenIds, bool unstake)
        external
        whenNotPaused
        onlyEOA
        nonReentrant
    {
        uint64 lastAddressWrite = uNFT.getAddressWriteBlock();
        require(lastAddressWrite < block.number, "Arena: Nope!");

        uint256 owed = 0;

        // Fetch the owner so we can give that address the $world.
        // If the same address does not own all tokenIds this transaction will fail.
        // This is especially relevant when the Game contract calls this function as the _msgSender() - it should NOT get the $World ofc.
        uint16 tokenId = tokenIds[0];
        Stake memory stake = _getStake(tokenId);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // The _admins[] check allows the Game contract to claim at level upgrades
            require(
                stake.owner == _msgSender() || _admins[_msgSender()],
                "Arena: You don't own this token (claimManyFromArena)"
            );

            if (uNFT.isHero(tokenIds[i])) {
                owed += _claimHero(tokenIds[i], unstake);
            } else {
                owed += _claimVillain(tokenIds[i], unstake);
            }
        }

        // Pay out earned $World
        if (owed > 0) {
            // Pay $World to the owner
            totalWorldEarned += owed;
            uWorld.mint(stake.owner, owed);
        }

        emit TokensClaimed(stake.owner, tokenIds);
    }

    function _claimHero(uint256 tokenId, bool unstake)
        private
        returns (uint256 owed)
    {
        require(_isStaked(tokenId), "Arena: Token is not staked (_claimHero)");
        Stake memory stake = _getStake(tokenId);
        require(
            stake.owner == _msgSender() || _admins[_msgSender()],
            "Arena: You don't own this token (_claimHero)"
        );
        require(
            !(unstake &&
                block.timestamp - stake.stakeTimestamp < MINIMUM_DAYS_TO_EXIT),
            "Arena: Still fighting in the arena"
        );

        owed = uGame.calculateStakingRewards(tokenId);

        // steal and pay tax logic
        if (unstake) {
            uint256 rand = uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, tokenId)
                )
            ) % 2;
            if (rand & 1 == 1) {
                // 50% chance of all $World stolen
                _payVillainTax(owed);
                emit WorldStolen(stake.owner, tokenId, owed);
                owed = 0; // Hero lost all of his claimed $World right here
            }
            delete _HeroArena[tokenId];
            _removeStakeOwner(stake.owner, tokenId);
            _totalHerosStaked--;

            // Transfer back the token to the owner
            uNFT.safeTransferFrom(address(this), stake.owner, tokenId, ""); // send back Hero
        } else {
            _payVillainTax((owed * Villain_TAX_PERCENTAGE) / 100); // percentage tax to staked Villain
            owed = (owed * (100 - Villain_TAX_PERCENTAGE)) / 100; // remainder goes to Hero owner

            // reset stake
            Stake memory newStake = Stake({
                owner: stake.owner,
                tokenId: stake.tokenId,
                WorldPerRank: 0,
                stakeTimestamp: block.timestamp
            });

            _HeroArena[tokenId] = newStake;
        }

        emit TokenClaimed(stake.owner, tokenId, unstake, owed);

        return owed;
    }

    function _claimVillain(uint256 tokenId, bool unstake)
        private
        returns (uint256 owed)
    {
        require(
            _isStaked(tokenId),
            "Arena: Token is not staked (_claimVillain)"
        );
        require(
            uNFT.ownerOf(tokenId) == address(this),
            "Arena: Doesn't own token"
        );
        uint8 rank = _getTokenRank(tokenId);
        Stake memory stake = _getStake(tokenId);
        require(
            stake.owner == _msgSender() || _admins[_msgSender()],
            "Arena: You don't own this token (_claimVillain)"
        );
        require(
            !(unstake &&
                block.timestamp - stake.stakeTimestamp < MINIMUM_DAYS_TO_EXIT),
            "Arena: Still fighting in the arena"
        );

        owed = uGame.calculateStakingRewards(tokenId);

        if (unstake) {
            _totalRankStaked -= rank; // Remove rank from total staked
            _totalVillainStaked--; // Decrease the number

            Stake memory lastStake = _VillainPatrol[rank][
                _VillainPatrol[rank].length - 1
            ];

            // Shuffle last Villain to current position
            _VillainPatrol[rank][_VillainPatrolIndizes[tokenId]] = lastStake;
            _VillainPatrolIndizes[lastStake.tokenId] = _VillainPatrolIndizes[
                tokenId
            ];
            _VillainPatrol[rank].pop(); // Remove duplicate (last one)
            delete _VillainPatrolIndizes[tokenId]; // Delete old mapping

            _removeStakeOwner(stake.owner, tokenId);

            // Transfer back the token to the owner
            uNFT.safeTransferFrom(address(this), stake.owner, tokenId, ""); // Send back Villain
        } else {
            // Just claim rewards
            Stake memory myStake = Stake({
                owner: stake.owner,
                tokenId: stake.tokenId,
                WorldPerRank: _WorldPerRank,
                stakeTimestamp: block.timestamp
            }); // Reset stake

            _VillainPatrol[rank][_VillainPatrolIndizes[tokenId]] = myStake; // Reset stake
        }

        emit TokenClaimed(stake.owner, tokenId, unstake, owed);

        return owed;
    }

    function getStake(uint256 tokenId) external view returns (Stake memory) {
        return _getStake(tokenId);
    }

    function _getStake(uint256 tokenId) private view returns (Stake memory) {
        require(_isStaked(tokenId), "Arena: Token is not staked (_getStake)");
        uint64 tokenMintBlock = uNFT.getTokenMintBlock(tokenId);
        require(tokenMintBlock < block.number, "Arena: Nope!");

        Stake memory myStake;

        if (uNFT.isHero(tokenId)) {
            myStake = _HeroArena[tokenId];
        } else {
            uint8 rank = _getTokenRank(tokenId); // Info: if we ever update the rank of the token, it can never be unstaked anymore, because it will not be found in this map
            myStake = _VillainPatrol[rank][_VillainPatrolIndizes[tokenId]];
        }

        // Only when you own the token or an admin is calling this function
        require(
            _msgSender() == myStake.owner || _admins[_msgSender()],
            "Arena: You don't own this token (_getStake)"
        );

        return myStake;
    }

    /** ONLY ADMIN FUNCTIONS */
    function getWorldPerRank() external view onlyAdmin returns (uint256) {
        return _WorldPerRank;
    }

    // Choose the thief when a mint is stolen by a staked Villain
    function randomVillainOwner(uint256 seed)
        external
        view
        override
        onlyAdmin
        returns (address)
    {
        if (_totalRankStaked == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % _totalRankStaked; // choose a value from 0 to total rank staked
        uint256 cumulative;
        seed >>= 32;

        uint8[4] memory VillainRanks = uNFT.getVillainRanks();
        uint8 minRank = VillainRanks[0]; // 5
        uint8 maxRank = VillainRanks[VillainRanks.length - 1]; // 8

        // loop through each bucket of Villain with the same rank score
        for (uint8 i = minRank; i <= maxRank; i++) {
            cumulative += _VillainPatrol[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Villain with that rank score
            return _VillainPatrol[i][seed % _VillainPatrol[i].length].owner;
        }
        return address(0x0);
    }

    /** ONLY OWNER FUNCTIONS */
    function setContracts(
        address _uNFT,
        address _uWorld,
        address _uGame
    ) external onlyOwner {
        uNFT = INFT(_uNFT);
        uWorld = IWorld(_uWorld);
        uGame = IGame(_uGame);
    }

    function setMinimumDaysToExit(uint256 number) external onlyOwner {
        MINIMUM_DAYS_TO_EXIT = number;
    }

    function setVillainTaxPercentage(uint256 number) external onlyOwner {
        Villain_TAX_PERCENTAGE = number;
    }

    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }

    /** READ ONLY */
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Arena: Cannot send to Arena directly");
        return IERC721Receiver.onERC721Received.selector;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity >=0.8.11;

interface IArena {

  struct Stake {
    uint16 tokenId;
    uint256 WorldPerRank;
    uint256 stakeTimestamp;
    address owner;
  }
  
  function stakeManyToArena(uint16[] calldata tokenIds) external;
  function claimManyFromArena(uint16[] calldata tokenIds, bool unstake) external;
  function randomVillainOwner(uint256 seed) external view returns (address);
  function getStakedTokenIds(address owner) external view returns (uint256[] memory);
  function getStake(uint256 tokenId) external view returns (Stake memory);
  function isStaked(uint256 tokenId) external view returns (bool);
  function getWorldPerRank() external view returns(uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;

import "./INFT.sol";

interface IGame {
    function getOwnerOfHVToken(uint256 tokenId) external view returns(address ownerOf);
    function getHVTokenTraits(uint256 tokenId) external view returns (INFT.HeroVillain memory);
    function calculateStakingRewards(uint256 tokenId) external view returns (uint256 owed);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INFT is IERC721Enumerable {

    struct HeroVillain {
        bool isRevealed;
        bool isHero;
        bool isGen0;
        uint16 level;
        uint256 lastLevelUpgradeTime;
        uint8 rank;
        uint256 lastRankUpgradeTime;
        // uint8 courage;
        // uint8 cunning;
        // uint8 brutality;
        uint64 mintedBlockNumber;
    }

    function MAX_TOKENS() external returns (uint256);
    function MAX_GEN0_TOKENS() external returns (uint256);
    function tokensMinted() external returns (uint16);

    function isHero(uint256 tokenId) external view returns(bool);

    function updateOriginAccess(uint16[] memory tokenIds) external; // onlyAdmin
    function mint(address recipient, bool isGen0) external; // onlyAdmin
    function burn(uint256 tokenId) external; // onlyAdmin
    function setTraitLevel(uint256 tokenId, uint16 level) external; // onlyAdmin
    function setTraitRank(uint256 tokenId, uint8 rank) external; // onlyAdmin
    function revealTokenId(uint16 tokenId, uint256 seed) external; // onlyAdmin
    function getTokenTraits(uint256 tokenId) external view returns (HeroVillain memory); // onlyAdmin
    function getVillainRanks() external view returns(uint8[4] memory); // onlyAdmin
    function getAddressWriteBlock() external view returns(uint64); // onlyAdmin
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64); // onlyAdmin
    function getTokenMintBlock(uint256 tokenId) external view returns(uint64); // onlyAdmin
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;

interface IWorld {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
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