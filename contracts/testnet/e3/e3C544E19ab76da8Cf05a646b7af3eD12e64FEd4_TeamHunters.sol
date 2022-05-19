// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./bases/ERC721EnumerableV2.sol";

import "./interfaces/IHunter.sol";
import "./interfaces/ISeeder.sol";
import "./interfaces/IData.sol";
import "./interfaces/IShop.sol";
import "./interfaces/IToken.sol";

contract TeamHunters is ERC721EnumerableV2 {
  uint256 constant TEAM_SIZE = 0x000700050003;
  uint256 constant ITEM_BLUE = 1;
  uint256 constant ITEM_GREEN = 2;
  uint256 constant ITEM_PURPLE = 3;

  // Team Create
  uint256 public constant CREATE_CRYSTAL = 1_000_000;
  uint256 public constant CREATE_ORB = 10_000_000_000;
  uint256 public constant CREATE_LOCK = 1 days;

  // PVP
  uint256 public constant SEASON_PERIOD = 7 days;
  uint256 public constant PVP_FEE = 5_000_000_000; // 12.5k $orb
  uint256 public constant ROUND_LOCK = 2 hours;

  struct Team {
    string name;
    uint16 size;
    uint256[] hunters;
    uint256 startsAt;
  }

  struct Round {
    uint16 size;
    uint256[] teams;
    uint8[8] places;
    uint256 roundHash;
    uint256 roundEndedAt;
  }

  event RoundStarted(uint256 roundId, Round round);

  bool public initialized;

  IHunter public token;
  ISeeder public seeder;
  IData public data;
  IShop public shop;
  IToken public orb;
  IToken public crystal;
  address treasury;

  uint256 public ticker;
  mapping(uint256 => Team) public teams;

  address public roundToken;
  uint256 public totalRounds; // Season rounds
  uint256 roundTicker; // Overall rounds
  mapping(uint256 => Round) rounds; // round_id -> Round
  mapping(uint16 => uint256) public currentRounds; // size -> round_id
  mapping(uint256 => uint256) public lastRounds; // team_id -> round_id

  function initialize() external {
    require(msg.sender == admin);
    require(!initialized);
    initialized = true;

    name = "Team of Hunters";
    symbol = "$woh_TEAM";
  }

  function setHunter(address hunter) external onlyOwner {
    bool succ;
    bytes memory ret;

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("utils(uint256)", 0));
    require(succ);
    seeder = ISeeder(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("utils(uint256)", 1));
    require(succ);
    data = IData(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("utils(uint256)", 5));
    require(succ);
    shop = IShop(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("tokens(uint256)", 1));
    require(succ);
    orb = IToken(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("tokens(uint256)", 3));
    require(succ);
    crystal = IToken(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("treasury()", ""));
    require(succ);
    treasury = abi.decode(ret, (address));

    token = IHunter(hunter);
  }

  function setRoundToken(address newRoundToken) external onlyOwner {
    roundToken = newRoundToken;
  }

  function registerTeam(
    uint8 size,
    string memory name,
    uint256[] memory hunters
  ) external {
    uint16 count = uint16(TEAM_SIZE >> (size * 16));
    require(count > 0, "Invalid size");
    require(count == hunters.length, "Invalid hunters");

    address account = msg.sender;

    token.useTeam(account, count); // 20 $energy per hunter
    crystal.burn(account, count * CREATE_CRYSTAL); // 1 $crystal per hunter
    orb.transferFrom(account, roundToken, CREATE_ORB); // 10k $orb

    for (uint256 i = 0; i < count; i++) {
      token.transferFrom(account, address(this), hunters[i]);
    }

    ticker++;
    teams[ticker] = Team(name, size, hunters, block.timestamp + CREATE_LOCK); // 1 day lock
    _mint(account, ticker);
  }

  function getTeams(address account) external view returns (uint256[] memory teamIds) {
    uint256 balance = balanceOf[account];
    teamIds = new uint256[](balance);
    for (uint256 i = 0; i < balance; i++) {
      teamIds[i] = tokenOfOwnerByIndex(account, i);
    }
  }

  function setTeamName(uint256 teamId, string memory name) external {
    require(ownerOf[teamId] == msg.sender, "Invalid onwer");
    teams[teamId].name = name;
  }

  function deregisterTeam(uint256 teamId) external {
    address account = msg.sender;
    require(ownerOf[teamId] == account, "Invalid owner");

    Team storage team = teams[teamId];
    uint256 count = team.hunters.length;

    for (uint256 i = 0; i < count; i++) {
      token.transferFrom(address(this), account, team.hunters[i]);
    }

    delete teams[teamId];
    _burn(teamId);
  }

  function enterRoundInternal(
    uint256 roundId,
    address account,
    uint256 teamId
  ) internal {
    Round storage round = rounds[roundId];

    uint256 seedHash = seed(roundId + teamId);
    uint256 timestamp = block.timestamp;

    uint8 remaining = 8 - uint8(round.teams.length);
    require(remaining > 0, "Invalid teams");

    uint16 count = uint16(TEAM_SIZE >> (round.size * 16));
    orb.transferFrom(account, roundToken, PVP_FEE * count);

    uint256 lastRound = lastRounds[teamId];
    require(lastRound < roundId, "Invalid enterance");
    require(rounds[lastRound].roundEndedAt < timestamp);
    uint8 hashIndex = uint8(seedHash % remaining);
    remaining--;
    uint8 place = round.places[hashIndex];
    if (place == 0) {
      place = hashIndex + 1;
    }
    round.places[remaining] = place;
    round.places[hashIndex] = remaining;
    round.teams.push(teamId);
    lastRounds[teamId] = roundId;

    if (remaining == 0) {
      round.roundHash = seedHash;
      round.roundEndedAt = timestamp + ROUND_LOCK;
      emit RoundStarted(roundId, round);
    }
  }

  function closeRound(uint256 roundId) external onlyOwner {
    Round storage round = rounds[roundId];
    require(round.teams.length == 8);
    require(round.roundEndedAt == 0);
    round.roundHash = seed(block.timestamp);
    round.roundEndedAt = block.timestamp;
  }

  function enterRound(uint16 size, uint256[] calldata teamIds) external {
    address account = msg.sender;
    require(size < 3, "Invalid size");

    for (uint256 i = 0; i < teamIds.length; i++) {
      uint256 teamId = teamIds[i];
      require(ownerOf[teamId] == account, "Invalid owner");
      uint256 currentRound = currentRounds[size];
      if (currentRound == 0 || rounds[currentRound].roundEndedAt > 0) {
        roundTicker++;
        currentRounds[size] = roundTicker;
        rounds[roundTicker].size = size;
        enterRoundInternal(roundTicker, account, teamId);
      } else {
        require(teams[teamId].size == rounds[currentRound].size, "Invalid size");
        enterRoundInternal(currentRound, account, teamId);
      }
    }
  }

  function getResult(
    uint256 teamAId,
    uint256 teamBId,
    uint16 matchHash
  ) internal view returns (uint256 winner, uint16 score) {
    Team memory teamA = teams[teamAId];
    Team memory teamB = teams[teamBId];
    uint16 count = uint16(TEAM_SIZE >> (teamA.size * 16));

    for (uint16 i = 0; i < count; i++) {
      uint256 dataA = data.getData(teamA.hunters[i]);
      uint256 dataB = data.getData(teamB.hunters[i]);

      uint16 specialA = uint16(dataA >> 16) % 3;
      uint16 specialB = uint16(dataB >> 16) % 3;

      if (specialA == specialB) {
        bool isMaleA = uint16(dataA) > 0;
        bool isMaleB = uint16(dataB) > 0;
        if (isMaleA == isMaleB) {
          // Same gender -> random
          // 0, 2: teamB wins
          // 1, 3: teamA wins
          score += matchHash & 0x1;
        } else {
          if (specialA == 2) {
            // Female Wins at Desert
            score += isMaleA ? 0 : 1;
          } else {
            // Male Wins at Forest/Jungle
            score += isMaleA ? 1 : 0;
          }
        }
      } else if (specialA > specialB) {
        // Desert -> Forest (lose)
        // Jungle -> Forest (win)
        // Jungle -> Desert (lose)
        score += (specialA - specialB) == 1 ? 0 : 1;
      } else {
        // Forest -> Desert (win)
        // Forest -> Jungle (lose)
        // Desert -> Jungle (win)
        score += (specialB - specialA) == 1 ? 1 : 0;
      }

      matchHash = matchHash >> 2;
    }

    // wins more than half
    if (score > (count >> 1)) {
      winner = teamAId;
    } else {
      winner = teamBId;
      score = count - score;
    }
  }

  function getRoundSize(uint256 roundId) external view returns (uint16 size) {
    size = uint16(TEAM_SIZE >> (rounds[roundId].size * 16));
  }

  function getRoundResult(uint256 roundId)
    public
    view
    returns (
      uint256[8] memory roundTeams,
      uint256[7] memory winners,
      uint16[7] memory scores
    )
  {
    Round memory round = rounds[roundId];
    require(round.roundEndedAt > 0, "Invalid round");

    uint256 base;
    uint256 matchHash = round.roundHash;
    uint256 i;

    for (i = 0; i < 8; i++) {
      roundTeams[i] = round.teams[round.places[i]];
    }

    // Round 1
    for (i = 0; i < 4; i++) {
      base = i * 2;
      (winners[i], scores[i]) = getResult(roundTeams[base], roundTeams[base + 1], uint16(matchHash));
      matchHash = matchHash >> 16;
    }

    // Round 2
    (winners[4], scores[4]) = getResult(winners[0], winners[1], uint16(matchHash));
    matchHash = matchHash >> 16;
    (winners[5], scores[5]) = getResult(winners[2], winners[3], uint16(matchHash));
    matchHash = matchHash >> 16;

    // Final
    (winners[6], scores[6]) = getResult(winners[4], winners[5], uint16(matchHash));
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(ownerOf[tokenId] != address(0));
    Team memory team = teams[tokenId];
    return data.drawTeam(team.name, team.hunters);
  }

  function roundURI(uint256 roundId) external view returns (string memory) {
    uint16 count = uint16(TEAM_SIZE >> (rounds[roundId].size * 16));
    (uint256[8] memory roundTeams, uint256[7] memory winners, uint16[7] memory scores) = getRoundResult(roundId);
    string[15] memory teamImages;
    uint16 i;
    Team memory team;
    for (; i < 8; i++) {
      team = teams[roundTeams[i]];
      teamImages[i] = data.getTeamSVG(team.name, count, team.hunters);
    }
    for (; i < 15; i++) {
      team = teams[winners[i]];
      teamImages[i] = data.getTeamSVG(team.name, count, team.hunters);
    }
    return data.drawRound(roundId, count, teams[winners[6]].name, teamImages, scores);
  }

  function seed(uint256 updates) internal returns (uint256) {
    return seeder.get(updates);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableV2 is ERC721 {
  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  uint256 public totalSupply;

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
    require(index < balanceOf[owner], "ERC721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from == address(0)) {
      totalSupply++;
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      totalSupply--;
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = balanceOf[to];
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = balanceOf[from] - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHunter {
  function ownerOf(uint256 hunterId) external view returns (address);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function useBreed(
    address account,
    uint256 female,
    uint256 breeds,
    uint256 breedId,
    uint256 breedHash
  ) external;

  function useBreedWithApple(
    address account,
    uint256 female,
    uint256 breeds,
    uint256 breedId,
    uint256 breedHash
  ) external;

  function useTrain(
    address account,
    uint256[] calldata hunters,
    uint32[] memory rates,
    uint256 use
  ) external;

  function useHunter(uint256 hunterId, uint32 hunterRate) external;

  function useHunt(address account, uint256[] calldata hunters) external returns (uint256 energy);

  function useTeam(address account, uint256 hunters) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISeeder {
  function get(uint256) external returns (uint256);

  function gets(uint256, uint256) external returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IData {
  function registerHunter(uint256 hunterId, uint256 seed) external;

  function nameHunter(uint256 hunterId, string calldata name) external;

  function getData(uint256 hunterId) external view returns (uint256);

  function setRate(uint256 hunterId, uint32 rate) external;

  function setBreed(uint256 hunterId, uint32 breeds) external;

  function infoBreed(uint256 hunterId) external view returns (bool isMale, uint32 breed);

  function infoCenter(uint256 hunterId) external view returns (bool isMale, uint32 rate);

  function infoPool(uint256 hunterId) external view returns (bool isMale, uint16 special);

  function info(uint256 hunterId)
    external
    view
    returns (
      string memory name,
      uint8 generation,
      uint16 tokenIdx,
      bool isMale,
      uint16[] memory pieces,
      uint32[] memory support
    );

  function draw(uint256 tokenId) external view returns (string memory);

  function getTeamSVG(
    string memory name,
    uint256 size,
    uint256[] memory hunterIds
  ) external view returns (string memory svg);

  function drawTeam(string memory name, uint256[] memory tokenIds) external view returns (string memory);

  function drawRound(
    uint256 roundId,
    uint16 size,
    string memory winner,
    string[15] memory teamImages,
    uint16[7] memory scores
  ) external view returns (string memory);

  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShop {
  function burn(
    address account,
    uint256 id,
    uint256 value
  ) external;

  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
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

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract ERC721 {
  /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

  address implementation_;
  address admin;

  string public name;
  string public symbol;

  /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

  mapping(address => uint256) public balanceOf;

  mapping(uint256 => address) public ownerOf;

  mapping(uint256 => address) public getApproved;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  function owner() external view returns (address) {
    return admin;
  }

  /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

  function transfer(address to, uint256 tokenId) external {
    require(msg.sender == ownerOf[tokenId], "NOT_OWNER");

    _transfer(msg.sender, to, tokenId);
  }

  /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
    // supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0x2a55205a;
    supported = true;
  }

  function approve(address spender, uint256 tokenId) external {
    address owner_ = ownerOf[tokenId];

    require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");

    getApproved[tokenId] = spender;

    emit Approval(owner_, spender, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) external {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    require(
      msg.sender == from || msg.sender == getApproved[tokenId] || isApprovedForAll[from][msg.sender],
      "NOT_APPROVED"
    );

    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public {
    transferFrom(from, to, tokenId);

    if (to.code.length != 0) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
        require(retval == IERC721Receiver.onERC721Received.selector);
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(ownerOf[tokenId] == from);
    _beforeTokenTransfer(from, to, tokenId);

    balanceOf[from]--;
    balanceOf[to]++;

    delete getApproved[tokenId];

    ownerOf[tokenId] = to;
    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  function _mint(address to, uint256 tokenId) internal {
    require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");
    _beforeTokenTransfer(address(0), to, tokenId);

    // This is safe because the sum of all user
    // balances can't exceed type(uint256).max!
    unchecked {
      balanceOf[to]++;
    }

    ownerOf[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal {
    address owner_ = ownerOf[tokenId];

    require(owner_ != address(0), "NOT_MINTED");
    _beforeTokenTransfer(owner_, address(0), tokenId);

    balanceOf[owner_]--;

    delete ownerOf[tokenId];

    emit Transfer(owner_, address(0), tokenId);

    _afterTokenTransfer(owner_, address(0), tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}