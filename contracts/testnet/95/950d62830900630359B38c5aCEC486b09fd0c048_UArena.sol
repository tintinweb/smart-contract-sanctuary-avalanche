// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IUArena.sol";
import "./interfaces/IUGame.sol";
import "./interfaces/IUNFT.sol";
import "./interfaces/IUBlood.sol";
import "./interfaces/IRandomizer.sol";

contract UArena is IUArena, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {

  constructor() {
    _pause();
  }
  
  /** CONTRACTS */
  IRandomizer public randomizer;
  IUNFT public uNFT;
  IUGame public uGame;
  IUBlood public uBlood;

  /** EVENTS */
  event TokenStaked(address indexed owner, uint256 indexed tokenId);
  event TokensStaked(address indexed owner, uint16[] tokenIds);
  event TokenClaimed(address indexed owner, uint256 indexed tokenId, bool unstaked, uint256 earned);
  event TokensClaimed(address indexed owner, uint16[] tokenIds);
  event BloodStolen(address indexed owner, uint256 indexed tokenId, uint256 indexed amount);

  /** PUBLIC VARS */
  // fighters & yakuza must be staked for minimum days before they can be unstaked
  uint256 public MINIMUM_DAYS_TO_EXIT = 1 days;
  // yakuza take a 20% tax on all $BLOOD claimed
  uint256 public YAKUZA_TAX_PERCENTAGE = 20;
  // amount of $BLOOD earned so far
  uint256 public totalBloodEarned;

  /** PRIVATE VARS */
  // total Fighters staked at this moment
  uint256 private _totalFightersStaked;
  // total Yakuza staked at this moment
  uint256 private _totalYakuzaStaked;
  // total sum of Yakuza rank staked
  uint256 private _totalRankStaked;
  // map all tokenIds to their original owners; ownerAddress => tokenIds
  mapping(address => uint256[]) private _ownersOfStakedTokens;
  // maps tokenId to stake
  mapping(uint256 => Stake) private _fighterArena;
  // maps rank to all Yakuza staked with that rank
  mapping(uint256 => Stake[]) private _yakuzaPatrol;
  // tracks location of each Yakuza in Patrol
  mapping(uint256 => uint256) private _yakuzaPatrolIndizes;
  // any rewards distributed when no Yakuza are staked
  uint256 private _unaccountedRewards = 0;
  // amount of $BLOOD due for each rank point staked
  uint256 private _bloodPerRank = 0;
  // admins
  mapping(address => bool) private _admins;

  /** MODIFIERS */
  modifier requireVariablesSet() {
    require(address(randomizer) != address(0), "Arena: Randomizer contract not set");
    require(address(uNFT) != address(0), "Arena: NFT contract not set");
    require(address(uGame) != address(0), "Arena: Game contract not set");
    require(address(uBlood) != address(0), "Arena: Blood contract not set");
    _;
  }

  modifier onlyAdmin() {
    require(_admins[_msgSender()], "Arena: Only admins can call this");
    _;
  }

  modifier onlyEOA() {
    require(tx.origin == _msgSender() || _msgSender() == address(uGame), "Arena: Only EOA");
    _;
  }

  /** STAKING */
  function getTotalFightersStaked() external view onlyEOA returns (uint256) {
    uint64 lastAddressWrite = uNFT.getAddressWriteBlock();
    require(lastAddressWrite < block.number, "Arena: Nope!");
    
    return _totalFightersStaked;
  }

  function getTotalYakuzaStaked() external view onlyEOA returns (uint256) {
    uint64 lastAddressWrite = uNFT.getAddressWriteBlock();
    require(lastAddressWrite < block.number, "Arena: Nope!");
    
    return _totalYakuzaStaked;
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

  function getStakedTokenIds(address owner) external view returns (uint256[] memory) {
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
    for (uint i = 0; i < tokenIds.length; i++) {
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
    IUNFT.FighterYakuza memory traits = uNFT.getTokenTraits(tokenId); // Fetching the rank from the NFT itself, not from the Game contract on purpose
    return traits.rank;
  }
  
  function _payYakuzaTax(uint256 amount) private {
    if (_totalRankStaked == 0) { // if there's no staked Yakuza
      _unaccountedRewards += amount; // keep track of $BLOOD that's due to all Yakuza
      return;
    }
    // makes sure to include any unaccounted $BLOOD
    _bloodPerRank += (amount + _unaccountedRewards) / _totalRankStaked;
    _unaccountedRewards = 0;
  }

  function stakeManyToArena(uint16[] calldata tokenIds) external override whenNotPaused onlyEOA nonReentrant {
    uint64 lastAddressWrite = uNFT.getAddressWriteBlock();
    require(lastAddressWrite < block.number, "Arena: Nope!");

    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(uGame)) { // Don't do this step if it's a mint + stake
        require(uNFT.ownerOf(tokenIds[i]) == _msgSender(), "Arena: You don't own this token (stakeManyToArena)");
        uNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // There may be gaps in the array for stolen tokens
      }

      if (uNFT.isFighter(tokenIds[i])) {
        _stakeFighter(_msgSender(), tokenIds[i]);
      } else {
        _stakeYakuza(_msgSender(), tokenIds[i]);
      }
    }

    emit TokensStaked(_msgSender(), tokenIds);
  }

  function _stakeFighter(address account, uint256 tokenId) private {
    Stake memory myStake = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      bloodPerRank: 0,
      stakeTimestamp: uint80(block.timestamp)
    });

    _fighterArena[tokenId] = myStake;
    _addStakeOwner(account, tokenId);
    _totalFightersStaked++;
    
    emit TokenStaked(account, tokenId);
  }

  function _stakeYakuza(address account, uint256 tokenId) private {
    Stake memory myStake = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      bloodPerRank: _bloodPerRank,
      stakeTimestamp: block.timestamp
    });

    uint8 rank = _getTokenRank(tokenId); //traits.rank;
    _totalRankStaked += rank; // Portion of earnings ranges from 5 to 8
    _totalYakuzaStaked++;
    _yakuzaPatrolIndizes[tokenId] = _yakuzaPatrol[rank].length; // Store the location of the Yakuza in the Patrol map
    _yakuzaPatrol[rank].push(myStake); // Add the Yakuza to Patrol
    _addStakeOwner(account, tokenId);

    emit TokenStaked(account, tokenId);
  }

  /** CLAIMING / UNSTAKING */
  function claimManyFromArena(uint16[] calldata tokenIds, bool unstake) external whenNotPaused onlyEOA nonReentrant {
    uint64 lastAddressWrite = uNFT.getAddressWriteBlock();
    require(lastAddressWrite < block.number, "Arena: Nope!");

    uint256 owed = 0;

    // Fetch the owner so we can give that address the $BLOOD.
    // If the same address does not own all tokenIds this transaction will fail.
    // This is especially relevant when the Game contract calls this function as the _msgSender() - it should NOT get the $BLOOD ofc.
    uint16 tokenId = tokenIds[0];
    Stake memory stake = _getStake(tokenId);

    for (uint i = 0; i < tokenIds.length; i++) {
      // The _admins[] check allows the Game contract to claim at level upgrades
      require(stake.owner == _msgSender() || _admins[_msgSender()], "Arena: You don't own this token (claimManyFromArena)");

      if (uNFT.isFighter(tokenIds[i])) {
        owed += _claimFighter(tokenIds[i], unstake);
      } else {
        owed += _claimYakuza(tokenIds[i], unstake);
      }
    }
    
    // Pay out earned $BLOOD
    if (owed > 0) {
      uint256 MAXIMUM_BLOOD_SUPPLY = uGame.MAXIMUM_BLOOD_SUPPLY();
      uint256 bloodTotalSupply = uBlood.totalSupply();

      // Pay out rewards as long as we did not reach max $BLOOD supply
      if (bloodTotalSupply < MAXIMUM_BLOOD_SUPPLY) {
        if (bloodTotalSupply + owed > MAXIMUM_BLOOD_SUPPLY) { // If totalSupply + owed exceeds the maximum supply then pay out only the remainder
          owed = MAXIMUM_BLOOD_SUPPLY - bloodTotalSupply; // Pay out the rest and that's it, we reached the maximum $BLOOD supply (for now)
        }
        
        // Pay $BLOOD to the owner
        totalBloodEarned += owed;
        uBlood.mint(stake.owner, owed);
        uBlood.updateOriginAccess();
      }
    }

    emit TokensClaimed(stake.owner, tokenIds);
  }

  function _claimFighter(uint256 tokenId, bool unstake) private returns (uint256 owed) {
    require(_isStaked(tokenId), "Arena: Token is not staked (_claimFighter)");
    Stake memory stake = _getStake(tokenId);
    require(stake.owner == _msgSender() || _admins[_msgSender()], "Arena: You don't own this token (_claimFighter)");
    require(!(unstake && block.timestamp - stake.stakeTimestamp < MINIMUM_DAYS_TO_EXIT), "Arena: Still fighting in the arena");

    owed = uGame.calculateStakingRewards(tokenId);

    // steal and pay tax logic
    if (unstake) {
      if (randomizer.random(tokenId) & 1 == 1) { // 50% chance of all $BLOOD stolen
        _payYakuzaTax(owed);
        emit BloodStolen(stake.owner, tokenId, owed);
        owed = 0; // Fighter lost all of his claimed $BLOOD right here
      }
      delete _fighterArena[tokenId];
      _removeStakeOwner(stake.owner, tokenId);
      _totalFightersStaked--;

      // Transfer back the token to the owner
      uNFT.safeTransferFrom(address(this), stake.owner, tokenId, ""); // send back Fighter
    } else {
      _payYakuzaTax(owed * YAKUZA_TAX_PERCENTAGE / 100); // percentage tax to staked Yakuza
      owed = owed * (100 - YAKUZA_TAX_PERCENTAGE) / 100; // remainder goes to Fighter owner

      // reset stake
      Stake memory newStake = Stake({
        owner: stake.owner,
        tokenId: stake.tokenId,
        bloodPerRank: 0,
        stakeTimestamp: block.timestamp
      });

      _fighterArena[tokenId] = newStake;
    }
    
    emit TokenClaimed(stake.owner, tokenId, unstake, owed);

    return owed;
  }

  function _claimYakuza(uint256 tokenId, bool unstake) private returns (uint256 owed) {
    require(_isStaked(tokenId), "Arena: Token is not staked (_claimYakuza)");
    require(uNFT.ownerOf(tokenId) == address(this), "Arena: Doesn't own token");
    uint8 rank = _getTokenRank(tokenId);
    Stake memory stake = _getStake(tokenId);
    require(stake.owner == _msgSender() || _admins[_msgSender()], "Arena: You don't own this token (_claimYakuza)");
    require(!(unstake && block.timestamp - stake.stakeTimestamp < MINIMUM_DAYS_TO_EXIT), "Arena: Still fighting in the arena");

    owed = uGame.calculateStakingRewards(tokenId);

    if (unstake) {
      _totalRankStaked -= rank; // Remove rank from total staked
      _totalYakuzaStaked--; // Decrease the number

      Stake memory lastStake = _yakuzaPatrol[rank][_yakuzaPatrol[rank].length - 1];

      // Shuffle last Yakuza to current position
      _yakuzaPatrol[rank][_yakuzaPatrolIndizes[tokenId]] = lastStake;
      _yakuzaPatrolIndizes[lastStake.tokenId] = _yakuzaPatrolIndizes[tokenId];
      _yakuzaPatrol[rank].pop(); // Remove duplicate (last one)
      delete _yakuzaPatrolIndizes[tokenId]; // Delete old mapping

      _removeStakeOwner(stake.owner, tokenId);

      // Transfer back the token to the owner
      uNFT.safeTransferFrom(address(this), stake.owner, tokenId, ""); // Send back Yakuza
    } else { // Just claim rewards
      Stake memory myStake = Stake({
        owner: stake.owner,
        tokenId: stake.tokenId,
        bloodPerRank: _bloodPerRank,
        stakeTimestamp: block.timestamp
      }); // Reset stake

      _yakuzaPatrol[rank][_yakuzaPatrolIndizes[tokenId]] = myStake; // Reset stake
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

    if (uNFT.isFighter(tokenId)) {
      myStake = _fighterArena[tokenId];
    } else {
      uint8 rank = _getTokenRank(tokenId); // Info: if we ever update the rank of the token, it can never be unstaked anymore, because it will not be found in this map
      myStake = _yakuzaPatrol[rank][_yakuzaPatrolIndizes[tokenId]];
    }

    // Only when you own the token or an admin is calling this function
    require(_msgSender() == myStake.owner || _admins[_msgSender()], "Arena: You don't own this token (_getStake)");

    return myStake;
  }

  /** ONLY ADMIN FUNCTIONS */
  function getBloodPerRank() external view onlyAdmin returns(uint256) {
    return _bloodPerRank;
  }

  // Choose the thief when a mint is stolen by a staked Yakuza
  function randomYakuzaOwner(uint256 seed) external view override onlyAdmin returns (address) {
    if (_totalRankStaked == 0) {
      return address(0x0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % _totalRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;

    uint8[4] memory yakuzaRanks = uNFT.getYakuzaRanks();
    uint8 minRank = yakuzaRanks[0]; // 5
    uint8 maxRank = yakuzaRanks[yakuzaRanks.length - 1]; // 8

    // loop through each bucket of Yakuza with the same rank score
    for (uint8 i = minRank; i <= maxRank; i++) {
      cumulative += _yakuzaPatrol[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Yakuza with that rank score
      return _yakuzaPatrol[i][seed % _yakuzaPatrol[i].length].owner;
    }
    return address(0x0);
  }

  /** ONLY OWNER FUNCTIONS */
  function setContracts(address _rand, address _uNFT, address _uBlood, address _uGame) external onlyOwner {
    randomizer = IRandomizer(_rand);
    uNFT = IUNFT(_uNFT);
    uBlood = IUBlood(_uBlood);
    uGame = IUGame(_uGame);
  }

  function setMinimumDaysToExit(uint256 number) external onlyOwner {
    MINIMUM_DAYS_TO_EXIT = number;
  }

  function setYakuzaTaxPercentage(uint256 number) external onlyOwner {
    YAKUZA_TAX_PERCENTAGE = number;
  }

  function setPaused(bool paused) external requireVariablesSet onlyOwner {
    if (paused) _pause();
    else _unpause();
  }

  function addAdmin(address addr) external onlyOwner {
    _admins[addr] = true;
  }

  function removeAdmin(address addr) external onlyOwner {
    delete _admins[addr];
  }

  /** READ ONLY */
  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
    require(from == address(0x0), "Arena: Cannot send to Arena directly");
    return IERC721Receiver.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IUNFT is IERC721Enumerable {

    struct FighterYakuza {
        bool isRevealed;
        bool isFighter;
        bool isGen0;
        uint16 level;
        uint256 lastLevelUpgradeTime;
        uint8 rank;
        uint256 lastRankUpgradeTime;
        uint8 courage;
        uint8 cunning;
        uint8 brutality;
        uint64 mintedBlockNumber;
    }

    function MAX_TOKENS() external returns (uint256);
    function tokensMinted() external returns (uint16);

    function isFighter(uint256 tokenId) external view returns(bool);

    function updateOriginAccess(uint16[] memory tokenIds) external; // onlyAdmin
    function mint(address recipient, bool isGen0) external; // onlyAdmin
    function burn(uint256 tokenId) external; // onlyAdmin
    function setTraitLevel(uint256 tokenId, uint16 level) external; // onlyAdmin
    function setTraitRank(uint256 tokenId, uint8 rank) external; // onlyAdmin
    function setTraitCourage(uint256 tokenId, uint8 courage) external; // onlyAdmin
    function setTraitCunning(uint256 tokenId, uint8 cunning) external; // onlyAdmin
    function setTraitBrutality(uint256 tokenId, uint8 brutality) external; // onlyAdmin
    function revealTokenTraits(uint256 tokenId, uint256 seed) external returns (FighterYakuza memory); // onlyAdmin
    function getTokenTraits(uint256 tokenId) external view returns (FighterYakuza memory); // onlyAdmin
    function getYakuzaRanks() external view returns(uint8[4] memory); // onlyAdmin
    function getAddressWriteBlock() external view returns(uint64); // onlyAdmin
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64); // onlyAdmin
    function getTokenMintBlock(uint256 tokenId) external view returns(uint64); // onlyAdmin
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.11;

import "./IUNFT.sol";

interface IUGame {
    function MAXIMUM_BLOOD_SUPPLY() external returns (uint256);

    function getFyTokenTraits(uint256 tokenId) external view returns (IUNFT.FighterYakuza memory);
    function calculateStakingRewards(uint256 tokenId) external view returns (uint256 owed);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.11;

interface IUBlood {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity 0.8.11;

interface IUArena {

  struct Stake {
    uint16 tokenId;
    uint256 bloodPerRank;
    uint256 stakeTimestamp;
    address owner;
  }
  
  function stakeManyToArena(uint16[] calldata tokenIds) external;
  function claimManyFromArena(uint16[] calldata tokenIds, bool unstake) external;
  function randomYakuzaOwner(uint256 seed) external view returns (address);
  function getStakedTokenIds(address owner) external view returns (uint256[] memory);
  function getStake(uint256 tokenId) external view returns (Stake memory);
  function isStaked(uint256 tokenId) external view returns (bool);
  function getBloodPerRank() external view returns(uint256);
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity 0.8.11;

interface IRandomizer {
    function random(uint256 tokenId) external returns (uint8);
    function randomSeed(uint256 tokenId) view external returns (uint256);
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