// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRandomizer.sol";
import "./interfaces/IUNFT.sol";
import "./interfaces/IUBlood.sol";
import "./interfaces/IUGold.sol";
import "./interfaces/IUArena.sol";
import "./interfaces/IUGame.sol";
import "./interfaces/IURaid.sol";

contract URaid is IURaid, Ownable, ReentrancyGuard, Pausable {

   constructor() {
    _pause();
    // Add raidM(0) to block this position with an inactive raidM, which will never be used
    addRaid(false, 0, 0, 0, 0, 0, 0, 0, 0);
  }

  /** CONTRACTS */
  IUGame public uGame;
  IUArena public uArena;
  IUBlood public uBlood;
  IUGold public uGold;
  IUNFT public uNFT;

  /** EVENTS */
  event RaidEntered(address indexed owner, uint16 raidId, uint256 tokenId);
  event RaidEnteredMany(address indexed owner, uint16 raidId, uint256[] tokenIds);
  event RaidAdded(uint16 raidId);
  event RaidWon(address indexed owner, uint16 raidId, uint256 tokenId, uint256 bloodWon, uint256 goldWon);
  event RaidLost(address indexed owner, uint16 raidId, uint256 tokenId);
  event RaidRoundFinished(uint16 raidId);

  /** CONSTANT VARS */
  uint32 constant weightLevel = 75/100 * 1_000_000; // 75%
  uint32 constant weightBrutality = 25/100 * 1_000_000; // 25%
  uint32 constant gen0RankBonus = 10/100 * 1_000_000; // 10%

  /** PUBLIC VARS */
  Raid[] public raids;
  // raidId => RaidParticipants
  mapping(uint16 => RaidParticipant[]) public raidParticipants;
  // tokenId => raidId
  mapping(uint256 => uint16) public tokenInRaid;
  // store all tax that has been collected so far
  uint256 public bloodTaxCollected = 0;

  /** PRIVATE VARS */
  mapping(address => bool) private _admins;

  /** MODIFIERS */
  modifier onlyEOA() {
    require(tx.origin == _msgSender(), "Raid: Only EOA");
    _;
  }

  modifier onlyAdmin() {
    require(_admins[_msgSender()], "Raid: Only admins can call this");
    _;
  }

  modifier requireVariablesSet() {
    require(address(uGame) != address(0), "Raid: Game contract not set");
    require(address(uBlood) != address(0), "Raid: Blood contract not set");
    require(address(uNFT) != address(0), "Raid: Nft contract not set");
    _;
  }

  /** PUBLIC & EXTERNAL FUNCTIONS */
  function enterManyToRaid(uint16 raidId, uint256[] memory tokenIds, uint16 rounds) external whenNotPaused nonReentrant onlyEOA {
    for (uint16 i = 0; i < tokenIds.length; i++) {
      _enterRaid(raidId, tokenIds[i], rounds);
    }
    emit RaidEnteredMany(_msgSender(), raidId, tokenIds);
  }

  // Add your NFT to the raidM
  function _enterRaid(uint16 raidId, uint256 tokenId, uint16 rounds) private {
    // Checks
    require(raidId != 0, "Raid: Raid 0 does not exist");

    Raid memory raidM = raids[raidId];
    require(raidM.active, "Raid: Raid is not active");

    require(raidParticipants[raidId].length + 1 <= raidM.maxParticipants, "Raid: Max participants reached for this Raid");
    require((raidM.maxRounds - raidM.roundsPlayed) >= rounds, "Raid: You cannot purchase more rounds than are left to play");

    address tokenOwner = uGame.getOwnerOfFYToken(tokenId);
    require(_msgSender() == tokenOwner, "Raid: You don't own this token");
    require(!isOwnerInRaid(raidId, tokenOwner), "Raid: Owner already has an NFT in this Raid");

    // Check if this NFT is in any Raid already
    require(tokenInRaid[tokenId] == 0, "Raid: Your NFT is already in a Raid");
    
    IUNFT.FighterYakuza memory tokenTraitsM = uGame.getFyTokenTraits(tokenId);
    require(tokenTraitsM.isRevealed, "Raid: This NFT is not revealed yet");
    require(tokenTraitsM.isFighter, "Raid: Only Fighters can enter Raids");
    require(tokenTraitsM.level >= raidM.levelMin, "Raid: Your NFT level does not match (levelMin)");
    require(tokenTraitsM.level <= raidM.levelMax, "Raid: Your NFT level does not match (levelMax)");
    require(uArena.isStaked(tokenId), "Raid: NFT must be staked to enter");
    require(tokenTraitsM.courage/10 >= rounds, "Raid: Not enough courage to enter so many rounds");

    // Burn BLOOD to enter
    uBlood.burn(_msgSender(), raidM.bloodToEnter * rounds);

    // Add the nft to the raidM
    RaidParticipant memory participant = RaidParticipant({
      tokenId: tokenId,
      roundsLeft: rounds
    });
    _addToRaid(raidId, participant);

    // Raid is full - now reset the nextRoundTime (storage)
    if (raidParticipants[raidId].length >= raidM.maxParticipants) {
      raids[raidId].nextRoundTime = block.timestamp + raidM.roundsIntervalTime;
    }

    emit RaidEntered(tokenOwner, raidId, tokenId);
  }

  function _addToRaid(uint16 raidId, RaidParticipant memory participant) private {
    require(raidId != 0, "Raid: Raid 0 does not exist");
    require(participant.tokenId != 0, "Raid: Token 0 does not exist");
    require(tokenInRaid[participant.tokenId] == 0, "Raid: Token is already in a Raid");
    require(_msgSender() == uGame.getOwnerOfFYToken(participant.tokenId), "Raid: You don't own this token");

    raidParticipants[raidId].push(participant);
    tokenInRaid[participant.tokenId] = raidId;
  }

  function getActiveRaids() public view returns(Raid[] memory) {
    uint16 activeRaidsCount = 0;

    for (uint16 k = 0; k < raids.length; k++) {
      if (raids[k].active) activeRaidsCount++;
    }

    Raid[] memory activeRaids = new Raid[](activeRaidsCount);
    uint16 count = 0;

    for (uint16 i = 0; i < raids.length; i++) {
      if (raids[i].active) {
        activeRaids[count] = raids[i];
        count++;
      }
    }

    return activeRaids;
  }

  function isTokenInRaid(uint16 raidId, uint256 tokenId) public view returns(bool) {
    return (tokenInRaid[tokenId] == raidId);
  }

  function isOwnerInRaid(uint16 raidId, address owner) public view returns(bool) {
    RaidParticipant[] memory participantsM = raidParticipants[raidId];
    for (uint16 i = 0; i < participantsM.length; i++) {
      if (owner == uGame.getOwnerOfFYToken(participantsM[i].tokenId)) {
        return true;
      }
    }
    return false;
  }

  function getRaidParticipantsSize(uint16 raidId) public view returns (uint256) {
    return raidParticipants[raidId].length;
  }

  function getRaidParticipation(uint16 raidId, uint256 tokenId) public view returns(RaidParticipant memory participant) {
    RaidParticipant[] memory participantsM = raidParticipants[raidId];
    for (uint16 i = 0; i < participantsM.length; i++) {
      if (participantsM[i].tokenId == tokenId) {
        return participantsM[i];
      }
    }
  }

  function removeManyFromRaid(uint16 raidId, uint256[] memory tokenIds) external whenNotPaused nonReentrant onlyEOA {
    for (uint16 i = 0; i < tokenIds.length; i++) {
      require(_msgSender() == uGame.getOwnerOfFYToken(tokenIds[i]), "Raid: You don't own this token");
      _removeFromRaidUnsafe(raidId, tokenIds[i]);
    }
  }

  /** ADMIN ONLY FUNCTIONS */
  /*
   * There is only 1 winner per Raid round - only that NFTs owner gets the raidRewards minted to him
   * If the token.level is now LOWER than the raidM.levelMin, the token is deleted from the raidM
   * If the token.level is now HIGHER than the raidM.levelMax, we use the raidM.levelMax for our winner calculations
   * GEN0 shall have a slight advantage in Raids
   * Raids get decided by the Level & Brutality
   * Higher Cunning wins higher rewards (so basically 0-50 Cunning get's you the Raid reward as is. But Cunning from 51 wins you linearly more).
   */
  function decideRaid(uint16 raidId, uint256 seed) external whenNotPaused onlyAdmin {
    require(raidId != 0, "Raid: Raid 0 does not exist");

    // Copy to a memory variable to save gas fees
    Raid memory raidM = raids[raidId];
    require(raidM.active, "Raid: Raid is not active");
    require(raidM.roundsPlayed < raidM.maxRounds, "Raid: All Rounds played already");
    
    // Copy to a memory variable to save gas fees
    RaidParticipant[] memory participantsM = raidParticipants[raidId];
    require(participantsM.length > 1, "Raid: Nobody to fight with");
    require(participantsM.length >= raidM.maxParticipants, "Raid: Raid is not filled up yet");

    uint256[] memory tokenIdsRemovedM = new uint256[](participantsM.length);
    uint256 tokenIdsRemovedIndex = 0;

    uint8 raidMinBrutality = 255;
    uint8 raidMaxBrutality = 0;

    // loop once through the raid and remove invalid/inactive tokens
    // also use the opportunity to compute some raid-wide values
    for (uint16 i = 0; i < participantsM.length; i++) {
      uint256 tokenId = participantsM[i].tokenId;

      // Jump over any empty record that was not removed properly
      if (tokenId == 0) continue;

      IUNFT.FighterYakuza memory tokenTraitsM = uGame.getFyTokenTraits(tokenId);
      address tokenOwner = uGame.getOwnerOfFYToken(tokenId);

      // Attention: NFT levels drop over time! So we need to take that into account here.
      // Also the token owner must be known.
      // Also remove token from Raid if roundsLeft is 0, ensuring that roundsLeft cannot go below 0.
      if (
        tokenTraitsM.level < raidM.levelMin
        || !uArena.isStaked(tokenId)
        || tokenOwner == address(0)
      ) {
        // This tokenId should not be in this Raid!
        tokenIdsRemovedM[tokenIdsRemovedIndex] = tokenId;
        tokenIdsRemovedIndex++;
      } else {
        // this token is valid, so it contributes to finding min/max brutality for the whole raid
        if (tokenTraitsM.brutality < raidMinBrutality) raidMinBrutality = tokenTraitsM.brutality;
        if (tokenTraitsM.brutality > raidMaxBrutality) raidMaxBrutality = tokenTraitsM.brutality;
      }
    }

    // Now remove the empty Raid entries (storage)
    for (uint16 k = 0; k < tokenIdsRemovedIndex; k++) {
      _removeFromRaidUnsafe(raidId, tokenIdsRemovedM[k]);
    }
    tokenIdsRemovedIndex = 0; // reset queue now

    // refresh the memory participants array after modification
    // copy to a memory variable to save gas fees
    participantsM = raidParticipants[raidId];
    require(participantsM.length > 1, "Raid: Nobody to fight with");
    require(participantsM.length >= raidM.maxParticipants, "Raid: Raid is not filled up yet");

    // compute a large random number based on the seed and other volatile data
    // use this number as the basis for modulo-based pseudo-random numbers
    uint randomNr = uint(keccak256(abi.encodePacked(seed)));

    // loop a second time through the raid and run the actual raid logic
    // the ranking list is sorted ascending, the strongest guy is last!
    uint256 winnerTokenId = _computeRaidWinner(raidId, raidMinBrutality, raidMaxBrutality, randomNr);

    // reward and log winner, log losers, decrease rounds left for everyone
    for (uint16 i = 0; i < participantsM.length; i++) {
      address tokenOwner = uGame.getOwnerOfFYToken(participantsM[i].tokenId);
      if (participantsM[i].tokenId == winnerTokenId) {
        // WON - give blood & gold, emit event
        (uint256 bloodRewardNew, uint256 goldRewardNew) = _calculateRewards(winnerTokenId, raidM);
        bloodRewardNew = bloodRewardNew - _collectTax(bloodRewardNew);

        uBlood.mint(tokenOwner, bloodRewardNew);
        uGold.mint(tokenOwner, goldRewardNew);
        emit RaidWon(tokenOwner, raidId, participantsM[i].tokenId, bloodRewardNew, goldRewardNew);
      } else {
        // LOST - emit RaidLost for all losers
        emit RaidLost(tokenOwner, raidId, participantsM[i].tokenId);
      }

      // Reduce roundsLeft per participant - if it reaches 0, remove it from this Raid (storage)
      raidParticipants[raidId][i].roundsLeft--;
      if (raidParticipants[raidId][i].roundsLeft == 0) {
        tokenIdsRemovedM[tokenIdsRemovedIndex] = participantsM[i].tokenId;
        tokenIdsRemovedIndex++;
      }
    }

    // now remove the empty Raid entries (storage)
    for (uint16 k = 0; k < tokenIdsRemovedIndex; k++) {
      _removeFromRaidUnsafe(raidId, tokenIdsRemovedM[k]);
    }
    tokenIdsRemovedIndex = 0; // reset queue now

    // run this raidM again in roundsIntervalTime (storage)
    raids[raidId].nextRoundTime = block.timestamp + raids[raidId].roundsIntervalTime;
    raids[raidId].roundsPlayed++;
    // set Raid to inactive when all rounds have been played
    if (raids[raidId].roundsPlayed >= raidM.maxRounds) {
      raids[raidId].active = false;
    }

    emit RaidRoundFinished(raidId);
  }

  function _calculateRewards(uint256 tokenId, Raid memory raidM) private view returns(uint256, uint256) {
    IUNFT.FighterYakuza memory tokenTraitsM = uGame.getFyTokenTraits(tokenId);
        
      uint256 bloodRewardNew = raidM.bloodReward;
      if (tokenTraitsM.cunning > 50) {
        bloodRewardNew = raidM.bloodReward + raidM.bloodReward * (tokenTraitsM.cunning - 50)/100;
      }

      uint256 goldRewardNew = raidM.goldReward;
      if (tokenTraitsM.cunning > 50) {
        goldRewardNew = raidM.goldReward + raidM.goldReward * (tokenTraitsM.cunning - 50)/100;
      }

      return (bloodRewardNew, goldRewardNew);
  }

  function _collectTax(uint256 bloodEarned) private returns(uint256) {
    uint256 tax = bloodEarned * 10/100;
    bloodTaxCollected += tax;
    return tax;
  }

  // computes a ranking per participant, and sorts participants by this ranking
  function _computeRaidWinner(uint16 raidId, uint8 raidMinBrutality, uint8 raidMaxBrutality, uint256 randomNr) private view returns(uint256) {
    Raid memory raidM = raids[raidId];
    RaidParticipant[] memory participantsM = raidParticipants[raidId];
    uint32[] memory ranksM = new uint32[](participantsM.length);

    // compute ranks of participants
    for (uint16 i = 0; i < participantsM.length; i++) {
      uint256 tokenId = participantsM[i].tokenId;

      // Jump over any empty record that was not removed properly
      if (tokenId == 0) continue;

      IUNFT.FighterYakuza memory tokenTraitsM = uGame.getFyTokenTraits(tokenId);

      // Token levels can change. If owners upgrade levels, and suddenly they exceed the
      // raidM.levelMax then we take raidM.levelMax as their level to calculate with
      // (per token ofc).
      uint16 actualTokenLevel = (tokenTraitsM.level > raidM.levelMax)? raidM.levelMax : tokenTraitsM.level;

      // compute rank via normalizing and weighting level and brutality, and adding possible bonuses
      uint32 weightedLevel = ((actualTokenLevel - raidM.levelMin) * weightLevel / (raidM.levelMax - raidM.levelMin + 1));
      uint32 weightedBrutality = ((tokenTraitsM.brutality - raidMinBrutality) * weightBrutality / (raidMaxBrutality - raidMinBrutality + 1));
      uint32 gen0Bonus = (tokenTraitsM.isGen0 ? gen0RankBonus : 0); // add a rank bonus for GEN0
      ranksM[i] = weightedLevel + weightedBrutality + gen0Bonus;
    }

    // sort participants by rank
    _quickSort(ranksM, participantsM, int(0), int(participantsM.length - 1));

    // choose randomly a participant, using rank as weight
    // see: https://zliu.org/post/weighted-random/ (solution 2)
    uint256 cumulantedRanks = 0;
    for (uint16 i = 0; i < participantsM.length; i++) {
      uint256 tokenId = participantsM[i].tokenId;

      // Jump over any empty record that was not removed properly
      if (tokenId == 0) continue;

      cumulantedRanks += ranksM[i];
    }
    uint256 randomCumulatedRank = (randomNr >> 8) % cumulantedRanks;
    for (uint16 i = 0; i < participantsM.length; i++) {
      uint256 tokenId = participantsM[i].tokenId;

      // Jump over any empty record that was not removed properly
      if (tokenId == 0) continue;

      if (ranksM[i] <= randomCumulatedRank) {
        randomCumulatedRank -= ranksM[i];
      } else {
        // this will happen eventually, as randomCumulatedRank < cumulantedRanks
        return participantsM[i].tokenId;
      }
    }

    // this will never happen, but as a fallback, we use the strongest guy
    return participantsM[participantsM.length - 1].tokenId;
  }

  // ATTENTION: This function does NOT check for ownership as it can also be called from an Admin address!
  function _removeFromRaidUnsafe(uint16 raidId, uint256 tokenId) private {
    // Don't revert here, just ignore these invalid inputs and continue
    if (raidId != 0 && tokenId != 0) {
      // Copy to a memory variable to save gas fees
      RaidParticipant[] memory participantsM = raidParticipants[raidId];

      for (uint256 i = 0; i < participantsM.length; i++) {
        if (participantsM[i].tokenId == tokenId) {

          // delete the the participantion (storage)
          delete(raidParticipants[raidId][i]);

          // move the last item to current position (storage)
          raidParticipants[raidId][i] = raidParticipants[raidId][raidParticipants[raidId].length - 1];
          // remove last element from array (storage)
          raidParticipants[raidId].pop();

          // remove token from raid (storage)
          tokenInRaid[tokenId] = 0;

          break;
        }
      }
    }
  }

  // quick sort implementation, see: https://ethereum.stackexchange.com/a/1518
  // enhancement: sort a data array in sync with sorting the actual array (called array of keys)
  function _quickSort(uint32[] memory keyArr, RaidParticipant[] memory dataArr, int left, int right) private pure {
      int i = left;
      int j = right;
      if (i == j) return;
      uint pivot = keyArr[uint(left + (right - left) / 2)];
      while (i <= j) {
          while (keyArr[uint(i)] < pivot) i++;
          while (pivot < keyArr[uint(j)]) j--;
          if (i <= j) {
              (keyArr[uint(i)], keyArr[uint(j)]) = (keyArr[uint(j)], keyArr[uint(i)]);
              (dataArr[uint(i)], dataArr[uint(j)]) = (dataArr[uint(j)], dataArr[uint(i)]);
              i++;
              j--;
          }
      }
      if (left < j)
          _quickSort(keyArr, dataArr, left, j);
      if (i < right)
          _quickSort(keyArr, dataArr, i, right);
  }

  /** OWNER ONLY FUNCTIONS */
  function addRaid(bool active, uint16 maxRounds, uint256 roundsIntervalTime, uint256 maxParticipants, uint16 levelMin, uint16 levelMax, uint256 bloodReward, uint256 goldReward, uint256 bloodToEnter) public onlyOwner {
    Raid memory raidM = Raid({
      id: uint16(raids.length), // equals the index in the mapping
      active: active,
      roundsPlayed: 0,
      maxRounds: maxRounds,
      nextRoundTime: block.timestamp + roundsIntervalTime,
      roundsIntervalTime: roundsIntervalTime,
      maxParticipants: maxParticipants,
      levelMin: levelMin,
      levelMax: levelMax,
      bloodReward: bloodReward, 
      goldReward: goldReward,
      bloodToEnter: bloodToEnter
    });

    raids.push(raidM);

    emit RaidAdded(raidM.id);
  }

  function setRaidActive(uint16 raidId, bool raidActive) external onlyOwner {
    raids[raidId].active = raidActive;
  }

  function setContracts(address _uGame, address _uArena, address _uNFT, address _uBlood, address _uGold) external onlyOwner {
    uNFT = IUNFT(_uNFT);
    uBlood = IUBlood(_uBlood);
    uGame = IUGame(_uGame);
    uGold = IUGold(_uGold);
    uArena = IUArena(_uArena);
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
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity 0.8.11;

interface IURaid {

  struct Raid {
    uint16 id;
    bool active;
    uint16 roundsPlayed;
    uint16 maxRounds;
    uint256 nextRoundTime;
    uint256 roundsIntervalTime;
    uint256 maxParticipants;
    uint16 levelMin;
    uint16 levelMax;
    uint256 bloodReward;
    uint256 goldReward;
    uint256 bloodToEnter;
  }

  struct RaidParticipant {
    uint256 tokenId;
    uint16 roundsLeft;
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
    function revealTokenId(uint16 tokenId, uint256 seed) external; // onlyAdmin
    function getTokenTraits(uint256 tokenId) external view returns (FighterYakuza memory); // onlyAdmin
    function getYakuzaRanks() external view returns(uint8[4] memory); // onlyAdmin
    function getAddressWriteBlock() external view returns(uint64); // onlyAdmin
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64); // onlyAdmin
    function getTokenMintBlock(uint256 tokenId) external view returns(uint64); // onlyAdmin
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUGold is IERC20 {
    function MAX_TOKENS() external returns (uint256);
    function tokensMinted() external returns (uint256);

    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.11;

import "./IUNFT.sol";

interface IUGame {
    function MAXIMUM_BLOOD_SUPPLY() external returns (uint256);

    function getOwnerOfFYToken(uint256 tokenId) external view returns(address ownerOf);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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