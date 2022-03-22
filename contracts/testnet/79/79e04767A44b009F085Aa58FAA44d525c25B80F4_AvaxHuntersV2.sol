// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./bases/ERC721EnumerableV2.sol";
import "./utils/Whitelister.sol";

import "./interfaces/ISeeder.sol";
import "./interfaces/IData.sol";
import "./interfaces/ITicket.sol";
import "./interfaces/IRenouncer.sol";
import "./interfaces/IToken.sol";

contract AvaxHunters is ERC721EnumerableV2, Whitelister {
  uint16 public constant MAX_PER_PRESALE = 5;
  uint16 public constant MAX_PER_MINT = 10;
  uint256 public constant ENERGY_PER_DAY = 3_000_000;
  uint256 public constant MAX_ENERGY = 20_000_000;
  uint256 public constant BREED_ENERGY = 10_000_000;

  bool public initialized;

  /**
   * @dev contract states
   * - 0: none
   * - 1: presale (whitelists & free mints)
   * - 2: public (users & free mints)
   * - 4: breed & hunt (hunters)
   * - 8: ...
   */
  uint8 public states;

  /**
   * @dev contract utilities
   * - 0: seeder
   * - 1: data
   * - 2: breeder
   * - 3: center
   * - 4: pool
   * - 5: shop
   */
  address[] public utils;

  /**
   * @dev contract tokens
   * - 0: ticket
   * - 1: orb
   * - 2: energy
   * - 3: crystal
   * - 4: ...
   */
  address[] public tokens;

  // Free Minters
  mapping(address => bool) public freeMinters;

  // Treasury of Hunters
  address public treasury;

  // Mint price & supply
  uint256 public mintPrice;
  uint256 public genesisSupply;
  uint256 mintTicker;

  // Hunter Holders

  /**
   * @dev hunter holders
   * -   0 ~ 127: last claimed timestamp
   * - 128 ~ 255: last remained energy
   */
  mapping(address => uint256) users;

  function initialize() external {
    require(msg.sender == admin);
    require(!initialized);
    initialized = true;

    name = "World of Hunters";
    symbol = "WOH";

    mintPrice = 1 ether;
    genesisSupply = 5_000;
  }

  modifier onlyState(uint8 flags) {
    require(states & flags > 0, "Invalid state");
    _;
  }

  function setState(uint8 newStates) external onlyOwner {
    states = newStates;
  }

  function seeds(uint256 updates, uint256 amount) internal returns (uint256[] memory) {
    return ISeeder(utils[0]).gets(updates, amount);
  }

  function data() internal view returns (IData) {
    return IData(utils[1]);
  }

  function ticket() internal view returns (ITicket) {
    return ITicket(tokens[0]);
  }

  function setUtils(address[] calldata newUtils) external onlyOwner {
    utils = newUtils;
  }

  function setTokens(address[] calldata newTokens) external onlyOwner {
    tokens = newTokens;
  }

  function setTreasury(address newTreasury) external onlyOwner {
    treasury = newTreasury;
  }

  function setMintPrice(uint256 newMintPrice) external onlyOwner {
    mintPrice = newMintPrice;
  }

  function setGenesisSupply(uint256 newGenesisSupply) external onlyOwner {
    genesisSupply = newGenesisSupply;
  }

  function setFreeMinters(address[] calldata newFreeMinters) public virtual {
    for (uint256 i = 0; i < newFreeMinters.length; i++) {
      freeMinters[newFreeMinters[i]] = true;
    }
  }

  function setWhitelists(address[] calldata newWhitelists, bool whitelisted) public virtual override onlyOwner {
    Whitelister.setWhitelists(newWhitelists, whitelisted);
  }

  function mintFree() external onlyState(3) {
    require(freeMinters[msg.sender], "Invalid free minter");
    delete freeMinters[msg.sender];
    mint(1);
  }

  function mintWithTicket() external onlyState(3) {
    uint256 amount = ticket().use(msg.sender);
    mint(amount);
  }

  function mintWhitelist(uint256 amount) external payable onlyState(1) withinWhitelist {
    require(amount <= MAX_PER_PRESALE);
    require(msg.value >= mintPrice * amount);
    mint(amount);
  }

  function mintPublic(uint256 amount) public payable onlyState(2) {
    require(amount <= MAX_PER_MINT);
    require(msg.value >= mintPrice * amount);
    mint(amount);
  }

  function mint(uint256 amount) internal {
    require(msg.sender == tx.origin, "Invalid sender");
    require(mintTicker + amount <= genesisSupply, "Insufficient supply");

    address to = msg.sender;

    uint256[] memory hashes = new uint256[](amount);
    hashes = seeds(mintTicker, amount);
    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = mintTicker + i + 1;
      data().registerHunter(tokenId, hashes[i]);
      _mint(to, tokenId);
    }
    mintTicker += amount;
  }

  function setNames(uint256[] calldata tokenIds, string[] calldata names) external {
    for (uint16 i = 0; i < tokenIds.length; i++) {
      require(msg.sender == ownerOf[tokenIds[i]]);
      data().nameHunter(tokenIds[i], names[i]);
    }
  }

  struct Hunter {
    string name;
    uint8 generation;
    uint16 tokenIdx;
    bool isMale;
    uint16[] pieces;
    uint32[] support;
  }

  function getHunters(address account) external view returns (Hunter[] memory hunters) {
    uint256 balance = balanceOf[account];
    hunters = new Hunter[](balance);

    IData hunterData = data();

    for (uint16 i = 0; i < balance; i++) {
      (
        string memory name,
        uint8 generation,
        uint16 tokenIdx,
        bool isMale,
        uint16[] memory pieces,
        uint32[] memory support
      ) = hunterData.info(tokenOfOwnerByIndex(account, i));
      hunters[i] = Hunter(name, generation, tokenIdx, isMale, pieces, support);
    }
  }

  function getEnergy(address account) external view returns (uint256 energy) {
    uint256 user = users[account];
    uint256 balance = balanceOf[account];

    uint128 timestamp = uint128(block.timestamp);

    if (uint128(user) > 0) {
      energy = (user >> 128) + ((timestamp - uint128(user)) * ENERGY_PER_DAY * balance) / 1 days;
      if (energy > MAX_ENERGY * balance) {
        energy = MAX_ENERGY * balance;
      }
    }
  }

  function fillEnergy(uint128 energy) external {
    address account = msg.sender;
    IToken(tokens[2]).burn(account, energy);
    uint256 user = users[account];
    users[account] = (((user >> 128) + energy) << 128) | uint128(user);
  }

  function useEnergy(address account, uint256 use) internal {
    uint256 user = users[account];
    uint256 balance = balanceOf[account];
    uint256 energy;

    uint128 timestamp = uint128(block.timestamp);

    if (timestamp == uint128(user)) {
      // same transaction
      return;
    }

    if (uint128(user) > 0) {
      energy = (user >> 128) + ((timestamp - uint128(user)) * ENERGY_PER_DAY * balance) / 1 days;
      if (energy > MAX_ENERGY * balance) {
        energy = MAX_ENERGY * balance;
      }

      require(energy >= use, "Insufficient energy");
      energy -= use;
      users[account] = (energy << 128) | timestamp;
    } else {
      users[account] = timestamp;
    }
  }

  function useEnergyBehalf(address account, uint256 uses) internal returns (uint256 usage) {
    uint256 user = users[account];
    uint256 balance = balanceOf[account];

    uint128 timestamp = uint128(block.timestamp);

    uint256 energy = (user >> 128) + ((timestamp - uint128(user)) * ENERGY_PER_DAY * balance) / 1 days;
    if (energy > MAX_ENERGY * balance) {
      energy = MAX_ENERGY * balance;
    }

    require(balance >= uses, "Insufficient energy");
    usage = uses * MAX_ENERGY;
    if (energy > usage) {
      energy -= usage;
      users[account] = (energy << 128) | timestamp;
    } else {
      usage = energy;
      users[account] = timestamp;
    }
  }

  function useBreed(
    address account,
    uint256 female,
    uint256 breeds,
    uint256 breedId,
    uint256 breedHash
  ) external onlyState(4) {
    require(msg.sender == utils[2], "Invalid breeder");
    if (breedId > 0) {
      useEnergy(account, BREED_ENERGY * 2);
      data().setBreed(female, uint32(breeds));
      data().registerHunter(breedId, breedHash);
      _mint(account, breedId);
    } else {
      useEnergy(account, BREED_ENERGY);
    }
  }

  function useTrain(
    address account,
    uint256[] calldata hunters,
    uint32[] memory rates,
    uint256 use
  ) external {
    require(msg.sender == utils[3], "Invalid center");
    useEnergy(account, use);
    for (uint16 i = 0; i < hunters.length; i++) {
      data().setRate(hunters[i], rates[i]);
    }
  }

  function useHunter(uint256 hunterId, uint32 hunterRate) external {
    require(msg.sender == utils[4], "Invalid pool");
    data().setRate(hunterId, hunterRate);
  }

  function useHunt(address account, uint256[] calldata hunters) external onlyState(4) returns (uint256 energy) {
    require(msg.sender == utils[4], "Invalid pool");
    for (uint16 i = 0; i < hunters.length; i++) {
      require(ownerOf[hunters[i]] == account, "Invalid owner");
    }
    energy = useEnergyBehalf(account, hunters.length);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(ownerOf[tokenId] != address(0));
    return data().draw(tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    if (msg.sender == tokens[3]) {
      _transfer(from, to, tokenId);
    } else {
      ERC721.transferFrom(from, to, tokenId);
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    require(to != address(0), "Not burnable");
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._afterTokenTransfer(from, to, tokenId);
    if (from != address(0)) {
      useEnergy(from, 0);
      useEnergy(to, 0);
    } else {
      useEnergy(to, 0);
    }
  }

  function withdraw() external onlyOwner {
    (bool succ, ) = treasury.call{ value: address(this).balance }("");
    require(succ);
  }

  function renounceUtility(uint16 index) external onlyOwner {
    IRenouncer(utils[index]).transferOwnership(admin);
  }

  function renounceToken(uint16 index) external onlyOwner {
    IRenouncer(tokens[index]).transferOwnership(admin);
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

contract Whitelister {
  mapping(address => bool) public whitelists;

  modifier withinWhitelist() {
    address sender = msg.sender;
    require(whitelists[sender]);
    _beforeUse(sender);
    _;
  }

  function setWhitelists(address[] calldata newWhitelists, bool whitelisted) public virtual {
    for (uint256 i = 0; i < newWhitelists.length; i++) {
      whitelists[newWhitelists[i]] = whitelisted;
    }
  }

  function _beforeUse(address whitelist) internal virtual {}
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

  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITicket {
  function balanceOf(address account) external view returns (uint256);

  function use(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRenouncer {
  function transferOwnership(address) external;
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
    bytes memory _data
  ) public {
    transferFrom(from, to, tokenId);

    if (to.code.length != 0) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IHunter.sol";
import "../interfaces/ISeeder.sol";
import "../interfaces/IData.sol";
import "../interfaces/IToken.sol";

contract Pool is Ownable {
  uint256 public constant PREMIUM_PRICE = 1_000_000;

  IHunter public token;
  ISeeder public seeder;
  IData public data;
  IToken public orb;
  IToken public crystal;

  uint256 public totalPackages;
  /**
   * @dev training information
   * -   0 ~  63: female hunts
   * -  64 ~ 127: male hunts
   * - 248 ~ 255: premium (0: no, 1: yes)
   */
  mapping(uint16 => uint256) public packages;

  function setHunter(address hunter) external {
    bool succ;
    bytes memory ret;

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("utils(uint256)", 0));
    require(succ);
    seeder = ISeeder(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("utils(uint256)", 1));
    require(succ);
    data = IData(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("tokens(uint256)", 1));
    require(succ);
    orb = IToken(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("tokens(uint256)", 3));
    require(succ);
    crystal = IToken(abi.decode(ret, (address)));

    token = IHunter(hunter);
  }

  function setPackage(
    uint8 packageId,
    uint8 isPremium,
    uint64 maleHunts,
    uint64 femaleHunts
  ) external onlyOwner {
    uint256 package = packages[packageId];
    if (package == 0) {
      totalPackages++;
    }
    packages[packageId] = (uint256(isPremium) << 248) | (uint128(maleHunts) << 64) | femaleHunts;
  }

  function getExpected(
    uint8 packageId,
    uint256 info,
    uint16 skip,
    uint256[] calldata hunters
  ) public view returns (uint256 expected) {
    uint256 hunter;
    uint256 prev;
    uint256 hunterId;

    for (uint16 i = 0; i < hunters.length; i++) {
      prev = hunterId;
      hunterId = hunters[i];
      require((i <= skip) || (prev < hunterId), "Invalid order");
      hunter = data.getData(hunterId);
      require(uint16(hunter >> (16 * 7)) / 3 == packageId / 3, "Invalid hunter specialty");
      if (uint16(hunter) > 0) {
        if (uint16(hunter >> (16 * 7)) == packageId) {
          expected += uint64(info >> 64);
        } else {
          expected += uint64(info >> 65);
        }
      } else {
        if (uint16(hunter >> (16 * 7)) == packageId) {
          expected += uint64(info);
        } else {
          expected += uint64(info) >> 1;
        }
      }
    }
  }

  function usePackage(
    uint8 packageId,
    uint256 lead,
    uint256 support,
    uint256[] calldata hunters
  ) external {
    address user = msg.sender;
    require(user == tx.origin, "Invalid sender");

    uint256 info = packages[packageId];
    uint256 count = hunters.length;

    if ((info >> 248) > 0) {
      crystal.burn(user, count * PREMIUM_PRICE);
    }

    uint256 hunter;
    uint256 expected;

    require(lead == hunters[0], "Invalid lead");
    hunter = data.getData(lead);
    require(uint16(hunter >> (16 * 7)) == packageId, "Invalid lead specialty");

    uint32 result = uint32(seed(lead) % 1000);
    bool success = result < uint32(hunter >> 128);
    uint256 multiplier = success ? (1000 + result) : 500;
    token.useHunter(lead, success ? (uint32(hunter >> 128) + 10) : (uint32(hunter >> 128) - 10));

    if (support > 0) {
      require(support == hunters[1], "Invalid support");
      hunter = data.getData(support);
      require(uint16(hunter >> (16 * 7)) == packageId, "Invalid support specialty");
      multiplier = (multiplier * (1000 + uint32(hunter >> 128))) / 1000;
      token.useHunter(support, success ? (uint32(hunter >> 128) + 10) : (uint32(hunter >> 128) - 10));
      expected = getExpected(packageId, info, 2, hunters);
    } else {
      expected = getExpected(packageId, info, 1, hunters);
    }

    uint256 usage = token.useHunt(user, hunters);
    multiplier = (multiplier * usage) / (count * 1_000_000);

    orb.transfer(user, (expected * multiplier) / 1000);
  }

  function seed(uint256 updates) internal returns (uint256) {
    return seeder.get(updates);
  }

  function sweepToken(IToken sweep, address to) external onlyOwner {
    sweep.transfer(to, sweep.balanceOf(address(this)));
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

  function useTrain(
    address account,
    uint256[] calldata hunters,
    uint32[] memory rates,
    uint256 use
  ) external;

  function useHunter(uint256 hunterId, uint32 hunterRate) external;

  function useHunt(address account, uint256[] calldata hunters) external returns (uint256 energy);
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

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IHunter.sol";
import "../interfaces/ISeeder.sol";
import "../interfaces/IData.sol";
import "../interfaces/IToken.sol";

contract Center is Ownable {
  struct Package {
    string name;
    uint256 priceEnergy; // $energy per training
    uint256 priceCrystal; // $crystal per training
    /**
     * @dev training information
     * -   0 ~  63: max support rate
     * -  64 ~ 127: min support rate
     * - 128 ~ 191: max success rate
     * - 192 ~ 255: min success rate
     */
    uint256 info;
  }

  IHunter public token;
  ISeeder public seeder;
  IData public data;
  IToken public crystal;

  Package[] packages;

  function setHunter(address hunter) external onlyOwner {
    bool succ;
    bytes memory ret;

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("utils(uint256)", 0));
    require(succ);
    seeder = ISeeder(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("utils(uint256)", 1));
    require(succ);
    data = IData(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("tokens(uint256)", 3));
    require(succ);
    crystal = IToken(abi.decode(ret, (address)));

    token = IHunter(hunter);
  }

  function addPackage(
    string calldata name,
    uint256 priceEnergy,
    uint256 priceCrystal,
    uint256[] calldata info
  ) external onlyOwner {
    packages.push(
      Package(name, priceEnergy, priceCrystal, (info[0] << 192) | (info[1] << 128) | (info[2] << 64) | info[3])
    );
  }

  function updatePackage(
    uint256 packageId,
    uint256 priceEnergy,
    uint256 priceCrystal,
    uint256[] calldata info
  ) external onlyOwner {
    Package storage package = packages[packageId];
    package.priceEnergy = priceEnergy;
    package.priceCrystal = priceCrystal;
    package.info = (info[0] << 192) | (info[1] << 128) | (info[2] << 64) | info[3];
  }

  function totalPackages() external view returns (uint256) {
    return packages.length;
  }

  function getPackage(uint8 packageId)
    public
    view
    returns (
      uint256 priceEnergy,
      uint256 priceCrystal,
      uint64 maleMin,
      uint64 maleOffset,
      uint64 femaleMin,
      uint64 femaleOffset
    )
  {
    Package memory package = packages[packageId];
    uint256 info = package.info;

    priceEnergy = package.priceEnergy;
    priceCrystal = package.priceCrystal;

    maleMin = uint64(info >> 192);
    maleOffset = uint64(info >> 128) - maleMin;
    femaleMin = uint64(info >> 64);
    femaleOffset = uint64(info) - femaleMin;
  }

  function usePackage(uint8 packageId, uint256[] calldata hunters) external {
    address user = msg.sender;
    require(user == tx.origin, "Invalid sender");

    (
      uint256 priceEnergy,
      uint256 priceCrystal,
      uint64 maleMin,
      uint64 maleOffset,
      uint64 femaleMin,
      uint64 femaleOffset
    ) = getPackage(packageId);

    uint16 count = uint16(hunters.length);
    uint32[] memory rates = new uint32[](count);

    crystal.burn(user, priceCrystal * count);

    for (uint16 i = 0; i < count; i++) {
      uint256 hunterId = hunters[i];
      require(token.ownerOf(hunterId) == user, "Invalid owner");

      (bool isMale, uint32 rate) = data.infoCenter(hunterId);
      uint256 result = seed(hunterId) % 100;

      if (isMale) {
        rate = rate + uint32(maleMin + ((maleOffset) * result) / 100);
      } else {
        rate = rate + uint32(femaleMin + ((femaleOffset) * result) / 100);
      }

      rates[i] = rate;
    }

    token.useTrain(user, hunters, rates, priceEnergy * count);
  }

  function seed(uint256 updates) internal returns (uint256) {
    return seeder.get(updates);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IHunter.sol";
import "../interfaces/ISeeder.sol";
import "../interfaces/IData.sol";
import "../interfaces/IToken.sol";

contract Breeder is Ownable {
  /**
   * @dev contract utilities
   * - 1: 1.0x = 10k $orbs
   * - 2: 1.5x = 15k
   * - 3: 2.5x = 25k
   * - 4: 5.0x = 50k
   * - 5: 10.0x = 100k
   */
  uint256 public constant BREED_MULTIPLIER = 0x006400320019000f000a;

  IHunter public token;
  ISeeder public seeder;
  IData public data;
  IToken public orb;
  address treasury;

  // Breed price & supply
  uint256 public breedPrice;
  uint256 public breedToken;
  uint256 public breedSupply;
  uint256 breedTicker;

  function setHunter(address hunter) external onlyOwner {
    bool succ;
    bytes memory ret;

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("utils(uint256)", 0));
    require(succ);
    seeder = ISeeder(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("utils(uint256)", 1));
    require(succ);
    data = IData(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("tokens(uint256)", 1));
    require(succ);
    orb = IToken(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("treasury()", ""));
    require(succ);
    treasury = abi.decode(ret, (address));

    token = IHunter(hunter);
  }

  function setGen(uint256[] calldata info) external onlyOwner {
    breedPrice = info[0];
    breedToken = info[1];
    breedSupply = info[2];
    breedTicker = info[3];
  }

  function breed(uint256 male, uint256 female) external payable returns (bool succeed) {
    address user = msg.sender;
    require(user == tx.origin, "Invalid sender");
    require(breedTicker < breedSupply, "Insufficient supply");

    require(token.ownerOf(male) == user, "Invalid owner");
    require(token.ownerOf(female) == user, "Invalid owner");

    (bool isMale, ) = data.infoBreed(male);
    (bool isNotFemale, uint32 breeds) = data.infoBreed(female);
    require(isMale && !isNotFemale, "Invalid pair");
    require(breeds < 5, "Invalid generation");

    require(msg.value >= breedPrice, "Insufficient fee");
    /**
     * @dev multiplier for each generation
     * - 0: 1x
     * - 1: 1.5x
     * - 2: 2.5x
     * - 3: 5x
     * - 4: 10x
     */
    orb.transferFrom(user, treasury, (breedToken * ((BREED_MULTIPLIER >> (16 * breeds)) & 0xFFFF)) / 10);

    uint256 seedHash = seed(male + female);
    uint256 breedHash = seedHash % 100;
    succeed = breedHash < 80; // 80% of success, 20% of fail
    if (succeed) {
      breedTicker++;
      token.useBreed(user, female, breeds + 1, breedTicker, seedHash);
    } else {
      token.useBreed(user, female, breeds, 0, 0);
    }
  }

  function seed(uint256 updates) internal returns (uint256) {
    return seeder.get(updates);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    if (balance > 0) {
      (bool succ, ) = payable(treasury).call{ value: balance }("");
      require(succ);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Whitelister.sol";

contract Seeder is Whitelister, Ownable {
  uint256 seed;

  function setWhitelists(address[] calldata newWhitelists, bool whitelisted) public virtual override onlyOwner {
    Whitelister.setWhitelists(newWhitelists, whitelisted);
  }

  function get(uint256 updates) external withinWhitelist returns (uint256) {
    seed = uint256(keccak256(abi.encodePacked(updates, block.timestamp, seed)));
    return seed;
  }

  function gets(uint256 updates, uint256 amount) external withinWhitelist returns (uint256[] memory seeds) {
    seeds = new uint256[](amount);
    uint256 current = seed;
    for (uint16 i = 0; i < amount; i++) {
      current = uint256(keccak256(abi.encodePacked(updates, block.timestamp, current)));
      seeds[i] = current;
    }
    seed = current;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../bases/ProxyData.sol";
import "./Whitelister.sol";
import "../interfaces/IDrawer.sol";

contract Data is ProxyData, Whitelister {
  uint256 public constant TRAIT_COUNTS = 0x0005000500050005000500050006;

  bool public initialized;

  IDrawer public drawer;

  mapping(uint256 => string) names;
  /**
   * @dev hunter traits
   * -   0 ~  15: gender (male: 1, female: 0)
   * -  16 ~  31: weapon
   * -  32 ~  37: gear
   * -  48 ~  63: hair
   * -  64 ~  79: face
   * -  80 ~  95: outfit
   * -  96 ~ 111: skintone
   * - 112 ~ 127: background
   * - 128 ~ 159: success/support rate
   * - 160 ~ 191: breed count
   */
  mapping(uint256 => uint256) hunters;

  function initialize() external {
    require(msg.sender == admin);
    require(!initialized);
    initialized = true;
  }

  function setDrawer(IDrawer newDrawer) external onlyAdmin {
    drawer = newDrawer;
  }

  function registerHunter(uint256 hunterId, uint256 seed) external withinWhitelist {
    require(hunters[hunterId] == 0);
    uint256 traitCounts = TRAIT_COUNTS;

    uint256 traits;

    /**
     * @dev hunter traits
     * - 0: background
     * - 1: skintone
     * - 2: outfit
     * - 3: face
     * - 4: hair
     * - 5: gear
     * - 6: weapon
     */
    for (uint16 i = 0; i < 7; i++) {
      traits = (traits << 16) | (seed % (traitCounts & 0xFFFF));
      seed = seed >> 16;
      traitCounts = traitCounts >> 16;
    }

    bool isMale = (seed % 100) < 70;
    seed = seed >> 16;

    uint256 rate = (seed % (isMale ? 250 : 100)) + (isMale ? 450 : 100);

    hunters[hunterId] = (rate << 128) | (traits << 16) | (isMale ? 1 : 0);
  }

  function nameHunter(uint256 hunterId, string calldata name) external withinWhitelist {
    names[hunterId] = name;
  }

  function getData(uint256 hunterId) external view returns (uint256 data) {
    data = hunters[hunterId];
  }

  function setRate(uint256 hunterId, uint32 rate) external withinWhitelist {
    uint256 hunter = hunters[hunterId];
    if (uint16(hunter) > 0) {
      rate = rate > 700 ? 700 : (rate < 450 ? 450 : rate);
    } else {
      rate = rate > 200 ? 200 : (rate < 100 ? 100 : rate);
    }
    hunters[hunterId] = ((((hunter >> 160) << 32) | rate) << 128) | (hunter & ((1 << 128) - 1));
  }

  function setBreed(uint256 hunterId, uint32 breeds) external withinWhitelist {
    uint256 hunter = hunters[hunterId];
    hunters[hunterId] = ((((hunter >> 192) << 32) | breeds) << 160) | (hunter & ((1 << 160) - 1));
  }

  function getHunter(uint256 hunterId) internal view returns (uint256 hunter) {
    hunter = hunters[hunterId];
    require(hunter > 0, "Invalid hunter");
  }

  function infoBreed(uint256 hunterId) external view returns (bool isMale, uint32 breed) {
    uint256 hunter = getHunter(hunterId);

    isMale = uint16(hunter) > 0;
    breed = uint32(hunter >> 160);
  }

  function infoCenter(uint256 hunterId) external view returns (bool isMale, uint32 rate) {
    uint256 hunter = getHunter(hunterId);

    isMale = uint16(hunter) > 0;
    rate = uint32(hunter >> 128);
  }

  function info(uint256 hunterId)
    public
    view
    returns (
      string memory name,
      uint8 generation,
      uint16 tokenIdx,
      bool isMale,
      uint16[] memory pieces,
      uint32[] memory support
    )
  {
    name = names[hunterId];
    generation = uint8(hunterId >> 248);
    tokenIdx = uint16(hunterId);

    uint256 hunter = getHunter(hunterId);

    isMale = uint16(hunter) > 0;
    hunter = hunter >> 16;

    pieces = new uint16[](7);
    for (uint16 i = 0; i < 7; i++) {
      pieces[i] = uint16(hunter);
      hunter = hunter >> 16;
    }

    support = new uint32[](2);
    support[0] = uint32(hunter >> 32); // breed
    support[1] = uint32(hunter); // rate
  }

  function draw(uint256 hunterId) external view returns (string memory) {
    (
      string memory name,
      uint8 generation,
      uint16 tokenIdx,
      bool isMale,
      uint16[] memory pieces,
      uint32[] memory support
    ) = info(hunterId);
    return drawer.draw(name, generation, tokenIdx, isMale, pieces, support);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProxyData {
  address implementation_;
  address public admin;

  constructor() {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function transferOwnership(address newOwner) external {
    require(msg.sender == admin);
    admin = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDrawer {
  function draw(
    string memory name,
    uint8 generation,
    uint16 tokenIdx,
    bool isMale,
    uint16[] memory pieces,
    uint32[] memory support
  ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyData.sol";

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
contract Proxy is ProxyData {
  constructor(address impl) {
    implementation_ = impl;
  }

  receive() external payable {}

  function setImplementation(address newImpl) public {
    require(msg.sender == admin);
    implementation_ = newImpl;
  }

  function implementation() public view returns (address impl) {
    impl = implementation_;
  }

  /**
   * @dev Delegates the current call to `implementation`.
   *
   * This function does not return to its internall call site, it will return directly to the external caller.
   */
  function _delegate(address implementation__) internal virtual {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation__, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
   * and {_fallback} should delegate.
   */
  function _implementation() internal view returns (address) {
    return implementation_;
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
   * function in the contract matches the call data.
   */
  fallback() external payable virtual {
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/Whitelister.sol";

contract Orb is ERC20, Ownable, Whitelister {
  constructor() ERC20("Orbs for World Of Hunters", "$woh_ORB") {
    _mint(owner(), 100_000_000_000_000);
  }

  function setWhitelists(address[] calldata newWhitelists, bool whitelisted) public virtual override onlyOwner {
    Whitelister.setWhitelists(newWhitelists, whitelisted);
  }

  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual override {
    if (!whitelists[spender]) {
      ERC20._spendAllowance(owner, spender, amount);
    }
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    if (whitelists[from] || whitelists[to]) {
      ERC20._transfer(from, to, amount);
    } else {
      uint256 fees = amount / 10;
      amount = amount - fees;
      (bool succ, bytes memory ret) = owner().staticcall(abi.encodeWithSignature("treasury()", ""));
      require(succ);
      ERC20._transfer(from, abi.decode(ret, (address)), fees);
      ERC20._transfer(from, to, amount);
    }
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    if (whitelists[spender]) {
      return type(uint256).max;
    } else {
      return ERC20.allowance(owner, spender);
    }
  }

  function decimals() public view virtual override returns (uint8) {
    return 6;
  }
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Ticket is ERC20, Ownable {
  constructor() ERC20("Tickets for World of Hunters", "$woh_TICKET") {}

  function mintPrice() public view returns (uint256) {
    (bool succ, bytes memory ret) = owner().staticcall(abi.encodeWithSignature("mintPrice()", ""));
    require(succ);
    return abi.decode(ret, (uint256));
  }

  function buy() external payable {
    uint256 amount = msg.value / mintPrice();
    if (amount > 0) {
      ERC20._mint(msg.sender, amount);
    }
  }

  function refund() external {
    address account = msg.sender;
    uint256 balance = balanceOf(account);
    ERC20._burn(account, balance);
    payable(account).transfer(mintPrice() * balance);
  }

  function use(address account) external onlyOwner returns (uint256 balance) {
    balance = balanceOf(account);
    ERC20._burn(account, balance);
  }

  function _afterTokenTransfer(
    address,
    address to,
    uint256
  ) internal virtual override {
    (bool succ, bytes memory ret) = owner().staticcall(abi.encodeWithSignature("MAX_PER_PRESALE()", ""));
    require(succ);
    require(balanceOf(to) <= abi.decode(ret, (uint16)), "Exceed presale amount");
  }

  function withdraw() external onlyOwner {
    (bool succ, bytes memory ret) = owner().staticcall(abi.encodeWithSignature("treasury()", ""));
    require(succ);
    address treasury = abi.decode(ret, (address));
    (succ, ) = payable(treasury).call{ value: (address(this).balance - (totalSupply() * mintPrice())) }("");
    require(succ);
  }

  function decimals() public view virtual override returns (uint8) {
    return 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/Whitelister.sol";

contract Energy is ERC20, Ownable, Whitelister {
  struct Pool {
    uint256 id;
    IERC20 token;
    uint256 emission;
    uint256 totalSupply;
    uint256 lastUnit;
    uint256 lastClaimedAt;
  }

  uint256 public totalEmission;
  Pool[] public pools;

  mapping(bytes32 => uint256) public staking;
  /**
   * @dev rewards
   * -   0 ~ 127: userRewardPerTokenPaid
   * - 128 ~ 255: rewards
   */
  mapping(bytes32 => uint256) public rewards;

  constructor() ERC20("Energies for World of Hunters", "$woh_ENERGY") {}

  function totalPools() external view returns (uint256) {
    return pools.length;
  }

  function addPool(IERC20 token, uint256 weight) external onlyOwner {
    pools.push(Pool(pools.length, token, weight, 0, 0, block.timestamp));
  }

  function updatePool(uint256 pId, uint256 newEmission) external onlyOwner {
    Pool storage pool = pools[pId];
    require(newEmission != pool.emission, "Invalid emission");
    pool.lastUnit = rewardPerToken(pId);
    pool.lastClaimedAt = block.timestamp;
    if (newEmission > pool.emission) {
      totalEmission += newEmission - pool.emission;
    } else {
      totalEmission -= pool.emission - newEmission;
    }
    pool.emission = newEmission;
  }

  function rewardPerToken(uint256 pId) public view returns (uint256) {
    Pool memory pool = pools[pId];
    if (pool.totalSupply == 0) {
      return pool.lastUnit;
    }
    return
      pool.lastUnit + ((((block.timestamp - pool.lastClaimedAt) * pool.emission * 1e24) / 1 days) / pool.totalSupply);
  }

  function getHash(uint256 pId, address account) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(pId, account));
  }

  function staked(uint256 pId, address account) public view returns (uint256) {
    return staking[getHash(pId, account)];
  }

  function earned(uint256 pId, address account) public view returns (uint256) {
    bytes32 userHash = getHash(pId, account);
    return
      ((staking[userHash] * (rewardPerToken(pId) - uint128(rewards[userHash]))) / 1e24) + (rewards[userHash] >> 128);
  }

  modifier updateReward(uint256 pId, address account) {
    Pool storage pool = pools[pId];
    pool.lastUnit = rewardPerToken(pId);
    pool.lastClaimedAt = block.timestamp;

    bytes32 userHash = getHash(pId, account);
    rewards[userHash] = (earned(pId, account) << 128) | pool.lastUnit;
    _;
  }

  function stake(uint256 pId, uint256 _amount) external updateReward(pId, msg.sender) {
    pools[pId].totalSupply += _amount;

    staking[getHash(pId, msg.sender)] += _amount;
    pools[pId].token.transferFrom(msg.sender, address(this), _amount);
  }

  function withdraw(uint256 pId, uint256 _amount) external updateReward(pId, msg.sender) {
    pools[pId].totalSupply -= _amount;

    bytes32 userHash = getHash(pId, msg.sender);
    staking[userHash] -= _amount;
    pools[pId].token.transfer(msg.sender, _amount);

    uint256 reward = rewards[userHash];
    if (reward >> 128 > 0) {
      ERC20._mint(msg.sender, reward >> 128);
      rewards[userHash] = uint128(reward);
    }
  }

  function claim(uint256 pId) external updateReward(pId, msg.sender) {
    bytes32 userHash = getHash(pId, msg.sender);
    uint256 reward = rewards[userHash];

    rewards[userHash] = uint128(reward);
    ERC20._mint(msg.sender, reward >> 128);
  }

  function setWhitelists(address[] calldata newWhitelists, bool whitelisted) public virtual override onlyOwner {
    Whitelister.setWhitelists(newWhitelists, whitelisted);
  }

  function burn(address account, uint256 amount) external withinWhitelist {
    ERC20._burn(account, amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return 6;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../utils/Whitelister.sol";

contract Crystal is ERC20, Ownable, Whitelister {
  mapping(address => uint256[]) public users;

  constructor() ERC20("Crystals for World of Hunters", "$woh_CRYSTAL") {}

  function getRewards(address account) public view returns (uint256 balance, uint256 rewards) {
    balance = users[account].length;
    if (balance > 0) {
      balance -= 1;
      uint256 lastClaimedAt = users[account][0];
      rewards = ((block.timestamp - lastClaimedAt) * balance * 1_000_000) / 1 days;
    }
  }

  function stake(uint256[] calldata hunters) external {
    address account = msg.sender;
    (uint256 balance, uint256 rewards) = getRewards(account);
    if (balance > 0) {
      users[account][0] = block.timestamp;
    } else {
      users[account].push(block.timestamp);
    }
    for (uint256 i = 0; i < hunters.length; i++) {
      uint256 hunterId = hunters[i];
      IERC721(owner()).transferFrom(account, address(this), hunterId);
      users[account].push(hunterId);
    }
    if (rewards > 0) {
      ERC20._mint(account, rewards);
    }
  }

  function withdraw() external {
    address account = msg.sender;
    (uint256 balance, uint256 rewards) = getRewards(account);
    for (uint256 i = 1; i <= balance; i++) {
      IERC721(owner()).transferFrom(address(this), account, users[account][i]);
    }
    delete users[account];
    ERC20._mint(account, rewards);
  }

  function claim() external {
    address account = msg.sender;
    (, uint256 rewards) = getRewards(account);
    users[account][0] = block.timestamp;
    ERC20._mint(account, rewards);
  }

  function setWhitelists(address[] calldata newWhitelists, bool whitelisted) public virtual override onlyOwner {
    Whitelister.setWhitelists(newWhitelists, whitelisted);
  }

  function burn(address account, uint256 amount) external withinWhitelist {
    ERC20._burn(account, amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return 6;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is ERC165, IERC1155, IERC1155MetadataURI {
  using Address for address;

  address implementation_;
  address public admin;

  // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) private _balances;

  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
  string private _uri;

  /**
   * @dev See {_setURI}.
   */
  // function init(string memory uri_) internal {
  // 	_setURI(uri_);
  // }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * This implementation returns the same URI for *all* token types. It relies
   * on the token type ID substitution mechanism
   * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   *
   * Clients calling this function must replace the `\{id\}` substring with the
   * actual token type ID.
   */
  function uri(uint256) public view virtual override returns (string memory) {
    return _uri;
  }

  /**
   * @dev See {IERC1155-balanceOf}.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
    require(account != address(0), "ERC1155: balance query for the zero address");
    return _balances[id][account];
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    override
    returns (uint256[] memory)
  {
    require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(msg.sender, operator, approved);
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   */
  function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[account][operator];
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override {
    require(from == msg.sender || isApprovedForAll(from, msg.sender), "ERC1155: caller is not owner nor approved");
    _safeTransferFrom(from, to, id, amount, data);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override {
    require(
      from == msg.sender || isApprovedForAll(from, msg.sender),
      "ERC1155: transfer caller is not owner nor approved"
    );
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }
    _balances[id][to] += amount;

    emit TransferSingle(operator, from, to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
      _balances[id][to] += amount;
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
   * substitution mechanism
   * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   *
   * By this mechanism, any occurrence of the `\{id\}` substring in either the
   * URI or any of the amounts in the JSON file at said URI will be replaced by
   * clients with the token type ID.
   *
   * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
   * interpreted by clients as
   * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
   * for token type ID 0x4cce0.
   *
   * See {uri}.
   *
   * Because these URIs cannot be meaningfully represented by the {URI} event,
   * this function emits no events.
   */
  function _setURI(string memory newuri) internal virtual {
    _uri = newuri;
  }

  /**
   * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

    _balances[id][to] += amount;
    emit TransferSingle(operator, address(0), to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _balances[ids[i]][to] += amounts[i];
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
  }

  /**
   * @dev Destroys `amount` tokens of token type `id` from `from`
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `from` must have at least `amount` tokens of token type `id`.
   */
  function _burn(
    address from,
    uint256 id,
    uint256 amount
  ) internal virtual {
    require(from != address(0), "ERC1155: burn from the zero address");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }

    emit TransferSingle(operator, from, address(0), id, amount);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   */
  function _burnBatch(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {
    require(from != address(0), "ERC1155: burn from the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
    }

    emit TransferBatch(operator, from, address(0), ids, amounts);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "ERC1155: setting approval status for self");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning, as well as batched variants.
   *
   * The same hook is called on both single and batched variants. For single
   * transfers, the length of the `id` and `amount` arrays will be 1.
   *
   * Calling conditions (for each `id` and `amount` pair):
   *
   * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * of token type `id` will be  transferred to `to`.
   * - When `from` is zero, `amount` tokens of token type `id` will be minted
   * for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
   * will be burned.
   * - `from` and `to` are never both zero.
   * - `ids` and `amounts` have the same, non-zero length.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155Received.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) public virtual {
    require(
      account == msg.sender || isApprovedForAll(account, msg.sender),
      "ERC1155: caller is not owner nor approved"
    );

    _burn(account, id, value);
  }

  // function burnBatch(
  // 	address account,
  // 	uint256[] memory ids,
  // 	uint256[] memory values
  // ) public virtual {
  // 	require(
  // 		account == msg.sender || isApprovedForAll(account, msg.sender),
  // 		"ERC1155: caller is not owner nor approved"
  // 	);

  // 	_burnBatch(account, ids, values);
  // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./bases/ERC721EnumerableV2.sol";
import "./utils/Whitelister.sol";

import "./interfaces/ISeeder.sol";
import "./interfaces/IData.sol";
import "./interfaces/ITicket.sol";
import "./interfaces/IRenouncer.sol";
import "./interfaces/IToken.sol";

contract AvaxHuntersV2 is ERC721EnumerableV2, Whitelister {
  uint16 public constant MAX_PER_PRESALE = 5;
  uint16 public constant MAX_PER_MINT = 10;
  uint16 public constant MIN_AIRDROP = 2;
  uint16 public constant GAME_START = 1_000;
  uint256 public constant ENERGY_PER_DAY = 3_000_000;
  uint256 public constant MAX_ENERGY = 20_000_000;
  uint256 public constant BREED_ENERGY = 10_000_000;

  bool public initialized;

  /**
   * @dev contract states
   * - 0: none
   * - 1: presale (whitelists & free mints)
   * - 2: public (users & free mints)
   * - 4: breed & hunt (hunters)
   * - 8: ...
   */
  uint8 public states;

  /**
   * @dev contract utilities
   * - 0: seeder
   * - 1: data
   * - 2: breeder
   * - 3: center
   * - 4: pool
   * - 5: shop
   */
  address[] public utils;

  /**
   * @dev contract tokens
   * - 0: ticket
   * - 1: orb
   * - 2: energy
   * - 3: crystal
   * - 4: ...
   */
  address[] public tokens;

  // Free Minters
  mapping(address => bool) public freeMinters;

  // Treasury of Hunters
  address public treasury;

  // Mint price & supply
  uint256 public mintPrice;
  uint256 public genesisSupply;
  uint256 public mintTicker;

  // Hunter Holders

  /**
   * @dev hunter holders
   * -   0 ~ 127: last claimed timestamp
   * - 128 ~ 255: last remained energy
   */
  mapping(address => uint256) users;

  function initialize() external {
    require(msg.sender == admin);
    require(!initialized);
    initialized = true;

    name = "World of Hunters";
    symbol = "WOH";

    mintPrice = 1 ether;
    genesisSupply = 5_000;
  }

  modifier onlyState(uint8 flags) {
    require(states & flags > 0, "Invalid state");
    _;
  }

  function setState(uint8 newStates) external onlyOwner {
    states = newStates;
  }

  function seeds(uint256 updates, uint256 amount) internal returns (uint256[] memory) {
    return ISeeder(utils[0]).gets(updates, amount);
  }

  function data() internal view returns (IData) {
    return IData(utils[1]);
  }

  function ticket() internal view returns (ITicket) {
    return ITicket(tokens[0]);
  }

  function setUtils(address[] calldata newUtils) external onlyOwner {
    utils = newUtils;
  }

  function setTokens(address[] calldata newTokens) external onlyOwner {
    tokens = newTokens;
  }

  function setTreasury(address newTreasury) external onlyOwner {
    treasury = newTreasury;
  }

  function setMintPrice(uint256 newMintPrice) external onlyOwner {
    mintPrice = newMintPrice;
  }

  function setGenesisSupply(uint256 newGenesisSupply) external onlyOwner {
    genesisSupply = newGenesisSupply;
  }

  function setFreeMinters(address[] calldata newFreeMinters) public virtual {
    for (uint256 i = 0; i < newFreeMinters.length; i++) {
      freeMinters[newFreeMinters[i]] = true;
    }
  }

  // function setWhitelists(address[] calldata newWhitelists, bool whitelisted) public virtual override onlyOwner {
  //   Whitelister.setWhitelists(newWhitelists, whitelisted);
  // }

  // function mintFree() external onlyState(3) {
  //   require(freeMinters[msg.sender], "Invalid free minter");
  //   delete freeMinters[msg.sender];
  //   mint(1);
  // }

  // function mintWithTicket() external onlyState(3) {
  //   uint256 amount = ticket().use(msg.sender);
  //   mint(amount);
  // }

  // function mintWhitelist(uint256 amount) external payable onlyState(1) withinWhitelist {
  //   require(amount <= MAX_PER_PRESALE);
  //   require(msg.value >= mintPrice * amount);
  //   mint(amount);
  // }

  function mintPublic(uint256 amount) public payable onlyState(2) {
    require(amount <= MAX_PER_MINT);
    require(msg.value >= mintPrice * amount);

    if (mintTicker < GAME_START && amount >= MIN_AIRDROP) {
      // before game started (1k mints)
      if (amount > MIN_AIRDROP) {
        // 3 mint + 1 airdrop
        amount += 1;
      } else if (balanceOf[msg.sender] >= 3) {
        // 3+ holding = 2 mint + 1 airdrop
        amount += 1;
      } else if (freeMinters[msg.sender]) {
        // OG minters = 2 mint + 1 airdrop
        delete freeMinters[msg.sender];
        amount += 1;
      }
    }
    mint(amount);
  }

  function mint(uint256 amount) internal {
    require(msg.sender == tx.origin, "Invalid sender");
    require(mintTicker + amount <= genesisSupply, "Insufficient supply");

    address to = msg.sender;

    uint256[] memory hashes = new uint256[](amount);
    hashes = seeds(mintTicker, amount);
    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = mintTicker + i + 1;
      data().registerHunter(tokenId, hashes[i]);
      _mint(to, tokenId);
    }
    mintTicker += amount;
  }

  function setNames(uint256[] calldata tokenIds, string[] calldata names) external {
    for (uint16 i = 0; i < tokenIds.length; i++) {
      require(msg.sender == ownerOf[tokenIds[i]]);
      data().nameHunter(tokenIds[i], names[i]);
    }
  }

  struct Hunter {
    string name;
    uint8 generation;
    uint16 tokenIdx;
    bool isMale;
    uint16[] pieces;
    uint32[] support;
  }

  function getHunters(address account) external view returns (Hunter[] memory hunters) {
    uint256 balance = balanceOf[account];
    hunters = new Hunter[](balance);

    IData hunterData = data();

    for (uint16 i = 0; i < balance; i++) {
      (
        string memory name,
        uint8 generation,
        uint16 tokenIdx,
        bool isMale,
        uint16[] memory pieces,
        uint32[] memory support
      ) = hunterData.info(tokenOfOwnerByIndex(account, i));
      hunters[i] = Hunter(name, generation, tokenIdx, isMale, pieces, support);
    }
  }

  function getEnergy(address account) external view returns (uint256 energy) {
    uint256 user = users[account];
    uint256 balance = balanceOf[account];

    uint128 timestamp = uint128(block.timestamp);

    if (uint128(user) > 0) {
      energy = (user >> 128) + ((timestamp - uint128(user)) * ENERGY_PER_DAY * balance) / 1 days;
      if (energy > MAX_ENERGY * balance) {
        energy = MAX_ENERGY * balance;
      }
    }
  }

  function fillEnergy(uint128 energy) external {
    address account = msg.sender;
    IToken(tokens[2]).burn(account, energy);
    uint256 user = users[account];
    users[account] = (((user >> 128) + energy) << 128) | uint128(user);
  }

  function useEnergy(address account, uint256 use) internal {
    uint256 user = users[account];
    uint256 balance = balanceOf[account];
    uint256 energy;

    uint128 timestamp = uint128(block.timestamp);

    if (timestamp == uint128(user)) {
      // same transaction
      return;
    }

    if (uint128(user) > 0) {
      energy = (user >> 128) + ((timestamp - uint128(user)) * ENERGY_PER_DAY * balance) / 1 days;
      if (energy > MAX_ENERGY * balance) {
        energy = MAX_ENERGY * balance;
      }

      require(energy >= use, "Insufficient energy");
      energy -= use;
      users[account] = (energy << 128) | timestamp;
    } else {
      users[account] = timestamp;
    }
  }

  function useEnergyBehalf(address account, uint256 uses) internal returns (uint256 usage) {
    uint256 user = users[account];
    uint256 balance = balanceOf[account];

    uint128 timestamp = uint128(block.timestamp);

    uint256 energy = (user >> 128) + ((timestamp - uint128(user)) * ENERGY_PER_DAY * balance) / 1 days;
    if (energy > MAX_ENERGY * balance) {
      energy = MAX_ENERGY * balance;
    }

    require(balance >= uses, "Insufficient energy");
    usage = uses * MAX_ENERGY;
    if (energy > usage) {
      energy -= usage;
      users[account] = (energy << 128) | timestamp;
    } else {
      usage = energy;
      users[account] = timestamp;
    }
  }

  function useBreed(
    address account,
    uint256 female,
    uint256 breeds,
    uint256 breedId,
    uint256 breedHash
  ) external onlyState(4) {
    require(msg.sender == utils[2], "Invalid breeder");
    if (breedId > 0) {
      useEnergy(account, BREED_ENERGY * 2);
      data().setBreed(female, uint32(breeds));
      data().registerHunter(breedId, breedHash);
      _mint(account, breedId);
    } else {
      useEnergy(account, BREED_ENERGY);
    }
  }

  function useTrain(
    address account,
    uint256[] calldata hunters,
    uint32[] memory rates,
    uint256 use
  ) external {
    require(msg.sender == utils[3], "Invalid center");
    useEnergy(account, use);
    for (uint16 i = 0; i < hunters.length; i++) {
      data().setRate(hunters[i], rates[i]);
    }
  }

  function useHunter(uint256 hunterId, uint32 hunterRate) external {
    require(msg.sender == utils[4], "Invalid pool");
    data().setRate(hunterId, hunterRate);
  }

  function useHunt(address account, uint256[] calldata hunters) external onlyState(4) returns (uint256 energy) {
    require(msg.sender == utils[4], "Invalid pool");
    for (uint16 i = 0; i < hunters.length; i++) {
      require(ownerOf[hunters[i]] == account, "Invalid owner");
    }
    energy = useEnergyBehalf(account, hunters.length);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(ownerOf[tokenId] != address(0));
    return data().draw(tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    if (msg.sender == tokens[3]) {
      _transfer(from, to, tokenId);
    } else {
      ERC721.transferFrom(from, to, tokenId);
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    require(to != address(0), "Not burnable");
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._afterTokenTransfer(from, to, tokenId);
    if (from != address(0)) {
      useEnergy(from, 0);
      useEnergy(to, 0);
    } else {
      useEnergy(to, 0);
    }
  }

  function withdraw() external onlyOwner {
    (bool succ, ) = treasury.call{ value: address(this).balance }("");
    require(succ);
  }

  function renounceUtility(uint16 index) external onlyOwner {
    IRenouncer(utils[index]).transferOwnership(admin);
  }

  function renounceToken(uint16 index) external onlyOwner {
    IRenouncer(tokens[index]).transferOwnership(admin);
  }

  event RoyaltyCalled(uint256);

  function royaltyInfo(uint256, uint256 value) external view returns (address receiver, uint256 royaltyAmount) {
    // 5% of royalty fee
    return (admin, (value * 500) / 10000);
  }

  function royaltiesReceived(
    address,
    address,
    uint256 amount
  ) external virtual {
    emit RoyaltyCalled(amount);
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
abstract contract ERC721Enumerable is ERC721 {
  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
    require(index < balanceOf[owner], "ERC721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view virtual returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view virtual returns (uint256) {
    require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
    return _allTokens[index];
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
      _addTokenToAllTokensEnumeration(tokenId);
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      _removeTokenFromAllTokensEnumeration(tokenId);
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
   * @dev Private function to add a token to this extension's token tracking data structures.
   * @param tokenId uint256 ID of the token to be added to the tokens list
   */
  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
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

  /**
   * @dev Private function to remove a token from this extension's token tracking data structures.
   * This has O(1) time complexity, but alters the order of the _allTokens array.
   * @param tokenId uint256 ID of the token to be removed from the tokens list
   */
  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
    // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
    // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    // This also deletes the contents at the last position of the array
    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITrait.sol";
import "../libs/Base64.sol";

contract Drawer is Ownable {
  using Base64 for *;

  ITrait[] public traits;

  function setTraits(ITrait[] calldata newTraits) external onlyOwner {
    traits = newTraits;
  }

  function draw(
    string memory name,
    uint8 generation,
    uint16 tokenIdx,
    bool isMale,
    uint16[] memory pieces,
    uint32[] memory support
  ) external view returns (string memory) {
    string memory attributes = string(
      abi.encodePacked('[{"display_type":"number","trait_type":"Gen","value":"', toString(generation))
    );

    for (uint256 i = 0; i < 7; i++) {
      attributes = string(
        abi.encodePacked(
          attributes,
          '"},{"trait_type":"',
          traits[i].name(),
          '","value":"',
          traits[i].getName(isMale, pieces[6 - i])
        )
      );
    }

    attributes = string(
      abi.encodePacked(
        attributes,
        '"},{"display_type":"number","trait_type":"Breed","value":"',
        toString(support[0]),
        '"},{"trait_type":"Gender","value":"',
        isMale ? "Male" : "Female",
        '"},{"trait_type":"',
        isMale ? "Success Rate" : "Support Rate",
        '","value":"',
        toString(support[1] / 10),
        '%"}]'
      )
    );

    string memory merged = Base64.encode(
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="woh" width="100%" height="100%" version="1.1" viewBox="0 0 64 64">',
        traits[0].getContent(isMale, pieces[6]),
        traits[1].getContent(isMale, pieces[5]),
        traits[2].getContent(isMale, pieces[4]),
        traits[3].getContent(isMale, pieces[3]),
        traits[4].getContent(isMale, pieces[2]),
        traits[5].getContent(isMale, pieces[1]),
        traits[6].getContent(isMale, pieces[0]),
        "<style>#woh{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>"
      )
    );

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              bytes(name).length > 0
                ? name
                : string(abi.encodePacked(isMale ? "Hunter" : "Hunteress", " #", toString(tokenIdx))),
              '","description":"World of Hunters - P2E & R2E game (100% on-chain)","image":"data:image/svg+xml;base64,',
              merged,
              '","attributes":',
              attributes,
              "}"
            )
          )
        )
      );
  }

  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrait {
  function name() external view returns (string memory);

  function itemCount() external view returns (uint16);

  function getName(bool isMale, uint16 traitId) external view returns (string memory data);

  function getContent(bool isMale, uint16 traitId) external view returns (string memory data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Base64 {
  string private constant base64stdchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    // load the table into memory
    string memory table = base64stdchars;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITrait.sol";

contract TraitBase is Ownable, ITrait {
  string public override name;
  uint16 public override itemCount;

  mapping(bytes32 => string) public extras;

  function getName(bool isMale, uint16 traitId) external view virtual override returns (string memory) {
    bool succ;
    bytes memory ret;
    string memory traitStr = toString(traitId);
    if (traitId > itemCount) {
      bytes32 key = keccak256(abi.encodePacked(isMale ? "male" : "female", "Name", traitStr));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature("extras(bytes32)", key));
    } else {
      string memory key = string(abi.encodePacked(isMale ? "male" : "female", "Name", traitStr, "()"));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature(key, ""));
    }
    require(succ);
    return abi.decode(ret, (string));
  }

  function getContent(bool isMale, uint16 traitId) external view virtual override returns (string memory) {
    bool succ;
    bytes memory ret;
    string memory traitStr = toString(traitId);
    if (traitId > itemCount) {
      bytes32 key = keccak256(abi.encodePacked(isMale ? "male" : "female", "Cont", traitStr));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature("extras(bytes32)", key));
    } else {
      string memory key = string(abi.encodePacked(isMale ? "male" : "female", "Cont", traitStr, "()"));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature(key, ""));
    }
    require(succ);
    return wrapTag(abi.decode(ret, (string)));
  }

  function wrapTag(string memory uri) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
          uri,
          '"/>'
        )
      );
  }

  function setExtras(string[] calldata keys, string[] calldata data) external onlyOwner {
    for (uint16 i = 0; i < keys.length; i++) {
      extras[keccak256(bytes(keys[i]))] = data[i];
    }
  }

  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "1";
    } else {
      value += 1;
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}

contract TraitSolid is TraitBase {
  function getName(bool, uint16 traitId) external view override returns (string memory) {
    bool succ;
    bytes memory ret;
    string memory traitStr = toString(traitId);
    if (traitId > itemCount) {
      bytes32 key = keccak256(abi.encodePacked("itemName", traitStr));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature("extras(bytes32)", key));
    } else {
      string memory key = string(abi.encodePacked("itemName", traitStr, "()"));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature(key, ""));
    }
    require(succ);
    return abi.decode(ret, (string));
  }

  function getContent(bool, uint16 traitId) external view override returns (string memory) {
    bool succ;
    bytes memory ret;
    string memory traitStr = toString(traitId);
    if (traitId > itemCount) {
      bytes32 key = keccak256(abi.encodePacked("itemCont", traitStr));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature("extras(bytes32)", key));
    } else {
      string memory key = string(abi.encodePacked("itemCont", traitStr, "()"));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature(key, ""));
    }
    require(succ);
    return wrapTag(abi.decode(ret, (string)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

contract Trait06_Weapon is TraitBase {
  string public constant maleName1 = "Axe";
  string public constant maleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAQlBMVEUAAAAAAAClpaW1tbXf39+/v7/m1mBORTX4+Pjq6upAOCn8/PxuY1BgVkTNzc28qjLMuTyqlhHYx0+xnyDx8fGciACIx8YIAAAAAXRSTlMAQObYZgAAAPFJREFUWMPtlEuOxCAMRHm2gRDS+fXM/a86SlpzgOAFUotaIFZPripwGBr6GgH4ACm9fRAkprS/HQgQiabiQ8Q6qbh8nNQfHyFhTTMA/1FSGggc2y83QONO1eeAq8H7opNt1McjsKfjA1hXtZOJhgzyxwM1HkwNKeSLgCmTldUaACwzV4arkVomCIAQi0YtGy1FgkZDBNGT5y0gyloUCGzJngMSJSLCDSsNBmxDgBvQlGCVg0C+mmz7jcB9EDDPb14IruVKXui73ANz9hLcgPnVPYUl4/TgbvLljpHuI7gB2U2g92sMLP4mg08QhoaGeugPZiwFY4bmQpIAAAAASUVORK5CYII=";
  string public constant femaleName1 = "Axe";
  string public constant femaleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAQlBMVEUAAAAAAAClpaW1tbXf39+/v7/m1mBORTX4+Pjq6upAOCn8/PxuY1BgVkTNzc28qjLMuTyqlhHYx0+xnyDx8fGciACIx8YIAAAAAXRSTlMAQObYZgAAAPFJREFUWMPtlEuOxCAMRHm2gRDS+fXM/a86SlpzgOAFUotaIFZPripwGBr6GgH4ACm9fRAkprS/HQgQiabiQ8Q6qbh8nNQfHyFhTTMA/1FSGggc2y83QONO1eeAq8H7opNt1McjsKfjA1hXtZOJhgzyxwM1HkwNKeSLgCmTldUaACwzV4arkVomCIAQi0YtGy1FgkZDBNGT5y0gyloUCGzJngMSJSLCDSsNBmxDgBvQlGCVg0C+mmz7jcB9EDDPb14IruVKXui73ANz9hLcgPnVPYUl4/TgbvLljpHuI7gB2U2g92sMLP4mg08QhoaGeugPZiwFY4bmQpIAAAAASUVORK5CYII=";

  string public constant maleName2 = "Bow";
  string public constant maleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAaVBMVEUAAAAAAABuSBSDXiq6nHN4VCBgAgLX1dTHwcC1tbWjo6ODg4Ozk2ajfkmcdT6OZzJuBQWjAwO6uLWqqKWfe0qiMTFxTBm2mGy3MzMtKyd0EREbEA6nhlmqiFiXcj+ObDyqMjKdJiaACAg5HdAAAAAAAXRSTlMAQObYZgAAARRJREFUWMPt18tugzAQhWH/YwhQ7mlC0qT393/IGgTtpqs5iyhSzoLx6pPF4LEIjzzyX7h7gBwRyFTgcHMgRxGAaAKAnQwUIDMo/QCvEHh2A9BMBPZ+oMlJz8ILwFs+l8oNfMJcntzAyFKq2iewg1T8W2A4r0DhBLiswN4JRFbA9yVhkXVV1rg20JGK/y1eib9AFRx5yf52EHyAOI5pEAE6ETgiAjtGUfg+I12QANu6cAHWGkE50PTZBtQ+IO/ZlqVzCxNBOtFdS1BmChDFqWaZEZS7ATuAvw0pMBxZ2+A+EheWBLcw0vJhCIOBqeEEymCA994LMFxJT6JwRzOXVmjkApgb+GKpQhtVgKCFm/+xJODe8gMvIwZWoSyV0gAAAABJRU5ErkJggg==";
  string public constant femaleName2 = "Bow";
  string public constant femaleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAaVBMVEUAAAAAAABuSBSDXiq6nHN4VCBgAgLX1dTHwcC1tbWjo6ODg4Ozk2ajfkmcdT6OZzJuBQWjAwO6uLWqqKWfe0qiMTFxTBm2mGy3MzMtKyd0EREbEA6nhlmqiFiXcj+ObDyqMjKdJiaACAg5HdAAAAAAAXRSTlMAQObYZgAAARRJREFUWMPt18tugzAQhWH/YwhQ7mlC0qT393/IGgTtpqs5iyhSzoLx6pPF4LEIjzzyX7h7gBwRyFTgcHMgRxGAaAKAnQwUIDMo/QCvEHh2A9BMBPZ+oMlJz8ILwFs+l8oNfMJcntzAyFKq2iewg1T8W2A4r0DhBLiswN4JRFbA9yVhkXVV1rg20JGK/y1eib9AFRx5yf52EHyAOI5pEAE6ETgiAjtGUfg+I12QANu6cAHWGkE50PTZBtQ+IO/ZlqVzCxNBOtFdS1BmChDFqWaZEZS7ATuAvw0pMBxZ2+A+EheWBLcw0vJhCIOBqeEEymCA994LMFxJT6JwRzOXVmjkApgb+GKpQhtVgKCFm/+xJODe8gMvIwZWoSyV0gAAAABJRU5ErkJggg==";

  string public constant maleName3 = "Dagger";
  string public constant maleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAMFBMVEUAAAAAAACkoaHw7OwfHx8SERHm3t7MycnFxcWVk5NJSUlHNA2vrKwkGgUsHwQ6KAIzYXVdAAAAAXRSTlMAQObYZgAAAGpJREFUSMftkbsNgDAMBc0GNhA+DVIq6qxBzQLsQ8MIjMAozEPDCFemeVef9E62CSHq4CQECY2TUEiYnSIOENqLNjoHYQ2KyBQxBmzkAsI5QeYQAZXphsy00Sl2/McDwvLRxktCjxFuQtgPncIIW8o4QtIAAAAASUVORK5CYII=";
  string public constant femaleName3 = "Dagger";
  string public constant femaleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAMFBMVEUAAAAAAACkoaHw7OwfHx8SERHm3t7MycnFxcWVk5NJSUlHNA2vrKwkGgUsHwQ6KAIzYXVdAAAAAXRSTlMAQObYZgAAAGpJREFUSMftkbsNgDAMBc0GNhA+DVIq6qxBzQLsQ8MIjMAozEPDCFemeVef9E62CSHq4CQECY2TUEiYnSIOENqLNjoHYQ2KyBQxBmzkAsI5QeYQAZXphsy00Sl2/McDwvLRxktCjxFuQtgPncIIW8o4QtIAAAAASUVORK5CYII=";

  string public constant maleName4 = "Spear";
  string public constant maleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAMFBMVEUAAAAAAABfX18hFgG6t7eZmZl4CAg6KQZiAwOUlJQvIAGAfX1bRhmrq6uHh4eDEBASceqDAAAAAXRSTlMAQObYZgAAAQRJREFUSMfN0zFuwkAQBdCZG8x3bDBREmnLiMpVpCiNUdoUTpcm0h7BR/AJoqRNRUUNN6CiR+IC3IAbwAX4v3CDJTfW08yf8a7dxhMKYDxQPR4VKEUPf04CFOvgoNqIENUMokWZOJgrUHSLoKDs9sFDtp88JdqOhyja79+gIQ8VKMBT+Z4Y+DrOEoKAhHk4P1D8Z7h5KsDn/PtfMOEfSGApAYcZA+ZZXD2vQ5zbkwITAWpw4D+1ABkNB8MgQM5LMWXuRYv8QlNOMOw4CH8L2sFsSkGY3VNwee/4Ki+gN7GqraiARgDvFViFAK8C6Dmnoys8NKqC2pTLTS11hZGb8vGL8Cvfz4rOIauId2AHAAAAAElFTkSuQmCC";
  string public constant femaleName4 = "Spear";
  string public constant femaleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAMFBMVEUAAAAAAABfX18hFgG6t7eZmZl4CAg6KQZiAwOUlJQvIAGAfX1bRhmrq6uHh4eDEBASceqDAAAAAXRSTlMAQObYZgAAAQRJREFUSMfN0zFuwkAQBdCZG8x3bDBREmnLiMpVpCiNUdoUTpcm0h7BR/AJoqRNRUUNN6CiR+IC3IAbwAX4v3CDJTfW08yf8a7dxhMKYDxQPR4VKEUPf04CFOvgoNqIENUMokWZOJgrUHSLoKDs9sFDtp88JdqOhyja79+gIQ8VKMBT+Z4Y+DrOEoKAhHk4P1D8Z7h5KsDn/PtfMOEfSGApAYcZA+ZZXD2vQ5zbkwITAWpw4D+1ABkNB8MgQM5LMWXuRYv8QlNOMOw4CH8L2sFsSkGY3VNwee/4Ki+gN7GqraiARgDvFViFAK8C6Dmnoys8NKqC2pTLTS11hZGb8vGL8Cvfz4rOIauId2AHAAAAAElFTkSuQmCC";

  string public constant maleName5 = "Sword";
  string public constant maleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAZlBMVEUAAADNW1vNW1vNW1sAAADk6fCzs7NSUlKlpaV8fHyMAAC+QkLESko+GQKIISFlLAaSkpK1ODhgAAChNjaDSRBVKgZJHQKzKyukISGkDw+VDw/JVFSpKytMISHQFRWDCwuvBgZxBATbbbcuAAAABHRSTlMAm1/A5JKyoAAAARlJREFUWMPt0klywzAMRFGA+hwlSp7tOPP9L5mScgMgu6j3fNUAKHv+IMENeAVVp/A6vviIiVUIHoBxVBcQoTmEOzHC0y5MpFjgZBYeCDEzmRc5kiiRpoMRmEmFmJjtQK6UaD+EjqRtC7MVaCtQE3c1N9i2wNEKDI1DJOWmNiEMI8SaivUvhXCmbl9hMt5BdZvBfsigEzWSsR/ySI7UzDiIscKTlGqlqXoqJDiptULjdwYVo7CtsdDMDd7IK3ACo3BGBIFgFfRBPuTCkQVbhRkqBeiY73CgFmsBIUxkthjfhzMZurkAQd+50hFbuAI3LiDGsHCB26XbBRB6vyKOAOAT+tIRT1huTgBwCt9fTuDzwz+D7Nmz55/mB1NlCntJoCq8AAAAAElFTkSuQmCC";
  string public constant femaleName5 = "Sword";
  string public constant femaleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAZlBMVEUAAADNW1vNW1vNW1sAAADk6fCzs7NSUlKlpaV8fHyMAAC+QkLESko+GQKIISFlLAaSkpK1ODhgAAChNjaDSRBVKgZJHQKzKyukISGkDw+VDw/JVFSpKytMISHQFRWDCwuvBgZxBATbbbcuAAAABHRSTlMAm1/A5JKyoAAAARlJREFUWMPt0klywzAMRFGA+hwlSp7tOPP9L5mScgMgu6j3fNUAKHv+IMENeAVVp/A6vviIiVUIHoBxVBcQoTmEOzHC0y5MpFjgZBYeCDEzmRc5kiiRpoMRmEmFmJjtQK6UaD+EjqRtC7MVaCtQE3c1N9i2wNEKDI1DJOWmNiEMI8SaivUvhXCmbl9hMt5BdZvBfsigEzWSsR/ySI7UzDiIscKTlGqlqXoqJDiptULjdwYVo7CtsdDMDd7IK3ACo3BGBIFgFfRBPuTCkQVbhRkqBeiY73CgFmsBIUxkthjfhzMZurkAQd+50hFbuAI3LiDGsHCB26XbBRB6vyKOAOAT+tIRT1huTgBwCt9fTuDzwz+D7Nmz55/mB1NlCntJoCq8AAAAAElFTkSuQmCC";

  constructor() {
    name = "Weapon";
    itemCount = 5;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

contract Trait05_Gear is TraitBase {
  string public constant maleName1 = "Ale";
  string public constant maleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAASFBMVEUAAAAAAADo3bVnZmVSUlLp2LTLsYemdBfWvZCJhoOyiUquhEHp4L/g2Lvfz63o1KiVj4jWtofJroNlYFq5kDysfSafbCOdZweOFAXmAAAAAXRSTlMAQObYZgAAAGhJREFUWMPt0ccNxEAMQ1F9T3LY6Nh/pw4laA4GDD6dSQigiYiIiIjchOv8aHmR8OdpPrxb3PnU8CdZ1QfHYVUFVBUE+FIwC/gKujWTl+Cekm4Y+zzjnyGWvgxb9BcQw2868n6cTOThdtPLAaw1ldxqAAAAAElFTkSuQmCC";
  string public constant femaleName1 = "Ale";
  string public constant femaleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAPFBMVEUAAACKqNEAAAAiKjRvdoB1FxdgZ3FvEBCJjpaTJSV1e4OKGBh8CQmTlZpucne9aGiePT2LHR16HBwPDg5/eSUOAAAAAnRSTlMAQABPjKgAAABZSURBVFjD7dK5DcBACETRNdeevvvv1esGHEDoecR8CYkEAAAAAPBX9Irs39xK40BAeAoFtPf9opSEfIGS61FVaKHkDOg4R2Vyn2BZ55g/QCbrZhR+BAD49gCSFQGSirzBgQAAAABJRU5ErkJggg==";

  string public constant maleName2 = "Arrow Bag";
  string public constant maleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJFBMVEUAAAAAAAD/58XexJ43JQAPDw8WCgMdDAFJGwA+LAc3FwRJMgI1pjTdAAAAAXRSTlMAQObYZgAAAI5JREFUSMdjGAWjYLAAZkUCCoyECBmgLIBfhZChEV4VrMzCigr4FEgkGgnhM4JRvJVRWVEZj4KFFQJGQga4FYhJAY3AZ0Bg4sKKAjwGiIgCjWjEY8BOR6AR+ILBZYqomCC+UGD0dhTEH9IiU4AG4DXCUYCAAkEGmgKWDQQUcE8hpMCRgAJOAYZRMAqGMQAALMoQhXsgT7MAAAAASUVORK5CYII=";
  string public constant femaleName2 = "Arrow Bag";
  string public constant femaleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJFBMVEUAAAAAAAAgHx//58XexJ4ZCwIPDw8nGhI3FwRAPj45ODguLCwBYIqvAAAAAXRSTlMAQObYZgAAAJZJREFUSMdjGAWjYJAAFkMCCpyFCRlgIoBfhbCjM14VbCwihgb4FIgHOgvjM4JRtIzRxNAEj4LGcAFnYQfcCkQlgEbgMyAxsDE8AI8BQmJAIwrxGLBaEWgEvmBQmiQmKogvFBg1FQXxh7TQJqABeI1QFCCgQJCy1LSIgDzTLAX8CrQ2EXDhTkUCVigJEFCgyDAKRsFQBgA2EBHAOGOlgwAAAABJRU5ErkJggg==";

  string public constant maleName3 = "Cloak";
  string public constant maleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEUAAAAoJiYAAABSUlJJRUU6OTlFQ0MbAF4rAAAAAXRSTlMAQObYZgAAAOpJREFUSMftkz0OgzAMhQ30AMSFPXHp3vBzAWj3oqoH4P6XKCUidHhR1KFSB97gJPIn+1lWaNeuXT9WmkcA07lTCc5LZd0lUxo2OObErlPGsMGdxOo5b2rKNCjAcziziBnnLAIu79CU/ODACC5axg7Xoqk5CYUAR4imoBKKSEXyifU3vJSjBzIDC7Tj6u+QwwLX0bN4V70HoNKijgGt+QJIkYcPIGEEVHabCAFFDOBu8o8CAs8NKCEw2A0QZPI2+Z0zqlD2C9AEAeWANmjSOGAIjUmmWUzWQUCU8iYV/pyyRGjSudii1vRPegHtKBWLmXqzbAAAAABJRU5ErkJggg==";
  string public constant femaleName3 = "Cloak";
  string public constant femaleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAAAZEgEAAAA6KAJDLwMvIABCMAwzJAQ6EjpFBQUaWSrGAAAAAXRSTlMAQObYZgAAARJJREFUSMftk8ttwzAQRCVWIC4t5Mql8jkvDeSuBC7ASQVxKnDSgGtwxSYpUb7M2lcfNAdhgX0aDjFgs2rVqseXCfnbBnXNXRmsxwDbOhE2sDIvwt5jA5JpMWCHYNhRsRpxBt+EUCw44ox595J25lu9JqegwZQEWDYFcc/k0wDVbrtEnH3T7joIuB1PUdwrQYN4kGnqB+hgOf7UCVchXzPgOgUYZD5MKZPe658K8CHNbeDzHiDx2gtqwo0LcILARsRXMwjY3229hYXAk12AEQL9EBPQ5qqPGNj8UQJEdXB0yMCohnRE+YijfgvqM5CrFvxw3haAMcD/GdirDkEKIPoRIhWwGCDyKSupGYz3tWkDAFUX9Tsd5khzsZsAAAAASUVORK5CYII=";

  string public constant maleName4 = "Parrot";
  string public constant maleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAANlBMVEUAAAAAAABtAACVAACoAAACRIcCM2bQuSDb29vIyMjXyLPbwRoEagQGXLPMvKYAgADbyVLiySJkoGzgAAAAAXRSTlMAQObYZgAAAIBJREFUWMPtk8kRwzAMxLxLSvIVJ+m/2aQBv/DweEz8gdFBTkVRFEVxbyQx32Ehf5mTFBSz1lXsBAcIyOlFBwlEWsQfI9IgMLbPCAv4360lCOzvHfqv1skN2t9HT9hbl9AUdriIqenxSGK6zQIO+IvhqwPQ54OooAFfHqhdLM75AfL1Ah2OA295AAAAAElFTkSuQmCC";
  string public constant femaleName4 = "Parrot";
  string public constant femaleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAS1BMVEUAAAAAAAA3kOpPnOoHRof42Q1qou7mzzQJW65/r/Hb29vIyMjXyLMOW6r031PMvKYIUZzcxCnQuSAAgwBGluYqe80QZbwUqhQSnBKB3rSFAAAAAXRSTlMAQObYZgAAAI5JREFUWMPtk0kOwzAMA03a8po4TdLt/y/tC3rioSiiuXMwEKDgOI7jOP8NAG2fzjek/eivE4Lg3rEsimAffRMESFYGNkHwqDahBJC1FEHAmGkTwr5FCgWILfNpQkDLkbYLAYysh3RCQvsDio9YES4PIM7zCkmQpliwmii4HWoBgligCqgK8s8L/Bed73wAt0kC805j9zAAAAAASUVORK5CYII=";

  string public constant maleName5 = "Shield";
  string public constant maleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJ1BMVEUAAAAAAAAqKCg8PDwYEQFAAgJtbW0lGgRnDQ0yJgt/FhYxJgxOAwPIUp62AAAAAXRSTlMAQObYZgAAAI5JREFUSMftkk0OgiEMROUGDJQg0U35TiAkXsWfnXgWN55aOUDLzrjo23aSvky7MwzD+DMcsJhXhj4/t6okUDtiZy8GQgchNjHgwoMSYUAMbMj7jMiiwkblfqMoSoQTpfeLIEp8FfL1QhheXnE4lrlClixJk3RTgtAgF/WcRQ2vV93Y68dirM69fBjj53wAgB8QNlJmYCEAAAAASUVORK5CYII=";
  string public constant femaleName5 = "Shield";
  string public constant femaleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJFBMVEUAAAAAAABuYACAcAkoHghAAgKjkiE4LBAsIQpnDQ1/FhZOAwMlNXvOAAAAAXRSTlMAQObYZgAAAI1JREFUSMftkksOQiEMRWUHXCgB46i8FQiJW/EzE9fkxNUqC2iZmTfomfYmPbntwTAMY2c4YDGvDH1+aVVJoHbEzl4MhA5CbGLAhSclwoAY2FCOBZFFhY3y40pRlAhnSp83QZT4KZT7jTC8suKU5wpZMidN0k0JQoNc1GsWNbxedWOvH4uxOvfyYYy/8wXGQBBQdnrRJgAAAABJRU5ErkJggg==";

  constructor() {
    name = "Gear";
    itemCount = 5;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

contract Trait04_Hair is TraitBase {
  string public constant maleName1 = "Blonde Hair";
  string public constant maleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEUAAAAAAADi15D47afTyo7p3IX47J4WDwD/3gARdHe1AAAAAXRSTlMAQObYZgAAAMRJREFUSMftkrEOwiAURdvJtRcodoXqB2BTnQ38gFU/wJg6+/+TDDYyXBxd5CYk5L3z7rsJVD9WDSCeL31rDbamyQGwPYSAQM5A9AjehmCQM3DzCRdgyiwRvX60VzkEuQPfoLwLRuB8OxoK2HHUtpGN2M9gO7DR7eAqVPWgLAOEu5s4GVvSSQZI5d/lWh4YoHycWwgKuGkprzqaQZvPnQJJdOqAZEw/6VskbhRIbDvukAFY9DX/MGQbCbGg3KKoqKjo7/QCkscUZMGbyTEAAAAASUVORK5CYII=";
  string public constant femaleName1 = "Blonde Buns";
  string public constant femaleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEUAAAAAAADb0pf47J7Xynfp3Y3m3J7QxX3i1HmjaRZSAAAAAXRSTlMAQObYZgAAATxJREFUSMftkT1vwjAQhm2Wrn7vHKnrOVBmJ4XdIe3uAlVX1A5dEb+gGz+74ivGwurcgWeIzucn7yk5VcSUmkhdHQr3usZQoiQQUunD7RhtzVWYh9GS31erYwMHFHzrdZNF2HXVGQ0svvfBGpbokAk6vMEG2n89zkFOuIp1K9eCbdtGnG3nP58e3MiEfN9lgsARiNvNon3uZ4Fqgc2EzsHJE78aMIhWsa6W2c+ghYw7+rBQSnst3NO6wdgkQTN6TDZy2gNtm64Wk81gG2hG8axPOTgonQmAe+d4Po12gFEZZKwsq3g5TuVm18rG+OKzzWXogxAGgaUghIgkDFUCgTC891AQdMfA30JtTEFIEKdPl5KgeZgw2u5MKcKGYftFASBzChgbLgla6f5YOKgk5ODypEwopt25c+fOP+AXou8qpKGHk5UAAAAASUVORK5CYII=";

  string public constant maleName2 = "Brown Hat";
  string public constant maleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEUAAAAAAAAuGANNMRYhFwEWEAI6IQeVMg86KAL1yot8AAAAAXRSTlMAQObYZgAAAMtJREFUSMft0k0OgjAQBWB6A5/BuGYqF2DUvaQQt1TKBVD2rFibeHAbCQhCL2D6bfvm9ScNpvCxCVwElHVxB5A3D20OcBaEOTf6JJ0VQjWcGHk7ugPMSSxThitw5YRf+lS79hD4Wls1oEG0jADGFBhRfMHPDTURqfyurKxUzPH8IMiYqGpq7hHVfJxVhFpqU9pp9IhsYFqBVPK5xCikGJjfgZif+64fEu02wlAwJtKq6IahPazFO+yKdhjarv4KIBrTIliFwPM8z/tPb2nHJk65G9LSAAAAAElFTkSuQmCC";
  string public constant femaleName2 = "Ginger Pony Tail";
  string public constant femaleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEUAAAAAAACvNAnMShziYzfeSBP/3gAkHAnXVikypdp3AAAAAXRSTlMAQObYZgAAARpJREFUSMftjz1SwzAQhSV+htZPa6dGlumzsumRDQcgkAO4oWY4AicHDYmdGWlWDaW/brXfvH1S/wh+qaT9kfEhSNpPuxlta1qbNxBpHw/8bbKGppHntmbPHY82J6DDVx8mcrU9mEwEsWNHU8092fcmE1Fbi44H30aaTASB4KbGIuLqNAITDAaPvz4OSUd+cOaNuDp9KaQCYJ7ZnsdUcOhBWAROOxAM4/48XiXfIBOrL8+3iaAxmidJUIR4QBDAl8WuMwnBygIC9ut0kwo6MK1TnREQdL8Kn6ngobCXBECp5QhUApkQrdPtuzRgiDsBgERBw0OJAh9LFwoBs1Ui2FWyQK/yXr/YgjBCFowpCECho9aqIKiNjY1LfgDBbCC5KMBdlgAAAABJRU5ErkJggg==";

  string public constant maleName3 = "Green Bandana";
  string public constant maleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEUAAAAAAAAIRAg6JwIyIw8AagAlFgFdNwIyOp9MAAAAAXRSTlMAQObYZgAAAJtJREFUSMft0rEKAyEMgOHkDZKLde/BPYBY6ByE7hV8gC7d+/5LOUG6mHMp3OI3/8Eowr8hMzCBhRtzOrzvzFFeZM1Hd1Pxahzio7I6pyGFfiCikoJPTpN1RKNGsOZ1t2Vjh2UrpdQkU/+WP9RfIe7b4wfECETqCxIg9lfgRxvsBxdmGAThMMDlqXAErzwIaBTUnzRIpmmapjN8AW9/EhrBenhbAAAAAElFTkSuQmCC";
  string public constant femaleName3 = "Black Bob";
  string public constant femaleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEUAAAAAAAAWExOAAADIDg7mFBTmAACZAwML6/c2AAAAAXRSTlMAQObYZgAAAM1JREFUSMfsklFOw0AMRJ2cYN9E4nvH7QUqwgFQywlAPQBcAe6PkKoqUpzwj5ivXftpPJYcf08DP2qbfUgnOWwRyDIgamKQxfR1PjmpDVKeL5fP6wdutYGfro/A/CoqIDW9PWMnD6cqBfaM5JRzqmZIEwaBDFQT7BaNFhBjATgX0cZ1CKxFbXQBuC/8SiB+ATJiL4NWGYo1FzhrQLLvHzlWkn33lajOyal+28Ft6yDb7RWlxvMh9jQe34+7wOGl932HHv/63igYBaOAmgAAnCcWBKbJIZ4AAAAASUVORK5CYII=";

  string public constant maleName4 = "White Hair";
  string public constant maleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEUAAAAAAAAWDwDQzMzp5eX09PTqVjmZAAAAAXRSTlMAQObYZgAAARJJREFUSMfskUGOhCAQRQtPwAfZS80JKrQHIOgBiPb9rzIFLDRx0otZ94ug4K9nBel/mEUnxzpfTMyWDBFgNcB98L2CI4iCRVorNL6Q6/WWOuAptpuXtEkRMo6jXj3YMMzcxH71Jc1S0F4zXESkDsepNYCXzIK8ba6tYmtz1DeXDrxz8Pt5eMSgvmipM3ITmpLPMJf1dDig26AbWq8R/ikiGVHeouJ4O4hJdaFk8LzjzBBvx6ZydRF8PbeYairzUWzXDkGXO0shhOKT39MWXnV4qQNmLHqUPgcxMCtEgqUL46DRHqiVDIFgW+D5+yCC8UzG0gNLRmq9Vn9g0g76hPFCn3l++dnHly+/GwWjYBQMRgAAj/oi6GDgs2kAAAAASUVORK5CYII=";
  string public constant femaleName4 = "White Long";
  string public constant femaleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEUAAAAAAADQzMzp5eX09PTb29uxOAjoAAAAAXRSTlMAQObYZgAAAcpJREFUSMft1V2S4iAQAGDj7L5DkxygG3w3QN4nP3MA1Nz/KtvZxEQbqrb2caqGKpSfj6YRNaf/KYprpbWuVHm+0lxhItJalee5gAvTwKIMgDSFgNpgMYTWZg4mkCGPpRAVrwyhDd0833irPATwMk8BiCgxwBy0nGPwS6JLg1QJgEce16ih9ShTgAevQ7U0rYbJSACXUU+e5xfwQJuDro8Wt3YBVNThNKgNOLS1BPZuRnx2zj3FDHzVXu37RXAZ6OphB2eHGaAUr+pIWQIeSvbz6GmqM/AwLwAgB3yK1y0yUI3/AhYPUFGepLYY9jGw5EiJy3R4J/UM0JO874om9BH3uwipE8CZ5OsbriAMJl0EwFvjzd2rv9HM0PSdBAODNQJYBnMG0peFpNZ8nG9mryS4W9zGNFCTJHCJEzgObTNw6Ud8u/1B/DCa8W0E0AsAI4pTiS1IrAAJrPwOOrFgCfDx7AWu9TvQuIxf186HvTIQnyT7323YAuB4Ov0SgGvnzdqJ5lOANXD/2AG/uAzEdgecwhklqCLG7RjLm1UqA7a+7r3zKOeXc5mjY2MBtPoIgCYHRlV7m1Tpr/ZlDcgUJdDl58kLPv2U71j+AM1VQ0qGzTkQAAAAAElFTkSuQmCC";

  string public constant maleName5 = "Wolf Hat";
  string public constant maleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAALVBMVEUAAAAAAAAZGRlbWlpiXU4kGQEdGA86KAI3NDQ+OzsdHR0vIwkdGxsvLCwdFQSn3NbeAAAAAXRSTlMAQObYZgAAAZpJREFUSMft0DFuE1EQxvHdUNDuf946Nk4oZizTpHopIki3aBtKB7mDwlaEoGOrHCCyFNFZSEiUtHQWJwhHQRwEeb3YlmcNOYC/bub9NPM0yUMD2XbVlJukUupWi9d37Ay4fVUWSwgsK6Tx6wmBvmWAmQJ+RdIB0Z4pocPSaLIL7glml2bx+EO4JC92QbiHMCxflgPgdlTSBuLsFGzwtQc/HeANRkc+j+XZxd1sPHafTAfnX3qz0+ffR5+uS0GCAyrX79+a2RV9U4sOJGEaxqIAfeTEoptA8WJi3FTADTryQOVCtFtVaZZ0Kx0NPJjotPuxKQQPjuM7qqbbzfs40JO5Vk3xOO+c+wkIf0F6tJg78C1Kd918tBAHiHED8oA7lGxPkEDiwKRgA1APtNBsc1YcSLeAqGQeGMp6HW1g/qtpHw3RxEf0abNDpk9awVnR7LBobSA9+y26otSjXPgRtJY5mrRFThYrYM1n/SW0Hk0kaQeWswRy1QAXVGog+0A6LP4DLK5A+x/XT6J7QboCJHtDzbLkkEMO+Wf+AEahQWf0dDSmAAAAAElFTkSuQmCC";
  string public constant femaleName5 = "Tight Curls";
  string public constant femaleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEUAAAAjGAEAAAASDQEZEwQ3JgEzIwD/3gDpywSB78kFAAAAAXRSTlMAQObYZgAAAXRJREFUSMftkzuSgzAMhjPcQH5QW85mklbY0Dv2bL1Akp5A9gA5Qk6+y+QBhjTbbMVfMKPhs35JtlZ/kv5V0n/Uu78q0QDANBhw7A2RMIRjYzjVwZYwBzSCl84HY6X0eZ3NE6SmOBjbeAonCMLNUiBPL0507tMY4oUQbAZ0AIYTtyb1gruO1MQBvOGNTS0H8BIs+CkgqOPAW8e05k1lgE88sCEykPO+P8wqRy2bOAjKyeZO94G+WuObyAOhLQ1H0ncc6WSjYSZJmQPYzTOtlofiHFvUF08f+Dq0cQAqBiTZrR4sq9JGVeKpTsVuAPTVhxgoa9etR8A5kFMjB2xclmZDXetKtIeoDSH2bDQ8nUG+jywCMcLzqAZBX1EXrcuuNHSmbyGP20ytXHtUz5DdJnPAlAeCrXqGEqeXhcXR8h17RN8k5g9GFrRHfU8gijmAJUF934cEO4IpsNIMZchAPRaMsdVU/c6p186pd6u1WrRo0aJ/1g9TfkPyTWeh3QAAAABJRU5ErkJggg==";

  constructor() {
    name = "Hair";
    itemCount = 5;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

contract Trait03_Face is TraitBase {
  string public constant maleName1 = "Black Mask";
  string public constant maleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEUAAAASEhIEAwMPDg4AAAA23o/EAAAAAXRSTlMAQObYZgAAAFhJREFUSMftzMENgDAMBMGDCriEAsilAscN8Ej/NZEGzBched6rRUofmxOR7ZwLOcOGItm4RAt3DZNEBKqR7sMuBPZepEa7EaFVpw6EttJGN7whDSml9BsP9YYJD9v5+1IAAAAASUVORK5CYII=";
  string public constant femaleName1 = "Black Mask";
  string public constant femaleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEUAAAAAAAAQEBAEAwMWFRUcGxurx/u0AAAAAXRSTlMAQObYZgAAAFhJREFUSMftz8ERwCAIBEDSAdiBkAYiSQViA4791xIbgLcP9n0zdwcpHe4iAhdthZn8TBG+X2WpbuDr1k0nuh2ydJjVYCGvrg2jDzJmhQi1ByFECCmldIofLBIIngcflcIAAAAASUVORK5CYII=";

  string public constant maleName2 = "Eye Paint";
  string public constant maleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAAAHBwchHhscGBMqKiodGBQfHRofGxcdGhcrIhkl65B/AAAABXRSTlMAM7F0MxDqGD0AAABQSURBVEjHYxgFIxUwCsIYOBSYZqSlpQWKp6WH4lDAVAokStMZGFhxWTG1lYEhoi0ApwIGwdKw0JC01I5QBpwqBAVBmJFhFIyCUTAKRsEgAgANAgqntddUXwAAAABJRU5ErkJggg==";
  string public constant femaleName2 = "Eye Paint";
  string public constant femaleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAASFBMVEUAAACyEwy+KSS4IBqsEgzJODLBLyq7KCOmGhfaSEHGMiu9Jh+4HBTWSULRQjuxFxakCgazKCSwJSK+KSfVS0OOEAqvDgbFOjJk6mCTAAAAFXRSTlMA/Pj4+Pf19Ov+/v39+vn27+7u4EAkM5BHAAAAUklEQVRYw+3PtxGAQBBD0T1/eLtL/50SUAFHxMx/uTSSAPgN/Zi0yxp7VMVmt+5drn5KJtq4PPSh9cFT4YdjaftwqpXR1U1idCVlUwEAAADwwg09bAKPSs6BvAAAAABJRU5ErkJggg==";

  string public constant maleName3 = "Skull Mask";
  string public constant maleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAMFBMVEUAAAAAAACzs7MLCwvFxcWoqKh8fHxJSUm6urqVk5NiYmK9vb2Ae3szMDAoJydiAAB1Bp8xAAAAAXRSTlMAQObYZgAAAGpJREFUSMdjGAWjYOAAIyF5MUEGBkFBQQGGjzhU3E0UFFQSFFIUFMOhgH2V2SQVGxPN5FW4LCkUnNR95Egn0BJcRhQGSmxxFBXH7c6LwRLGG00F8HgkTkhQ8Sken4K9yTAKRsEoGAVDBgAADzUQgezikD8AAAAASUVORK5CYII=";
  string public constant femaleName3 = "Hoops";
  string public constant femaleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAAAAAAD/8KH02zb/3gD353/365j35XD/6F7/5kv/4RwLnfuJAAAAAXRSTlMAQObYZgAAAFhJREFUSMdjGAWjYCgDRjhLALsCSZg4oyN2/YyJMLYQNiOEBRikBKBKJVAUIHSJQ8RFBbCawGgoCLVaRBBoGjYjlKHCjEGO2H0pCGMJCjCMglEwCkbBYAAAPAAD4DiyP9cAAAAASUVORK5CYII=";

  string public constant maleName4 = "Beard";
  string public constant maleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEUAAAAAAAAyIw8kFgQ+JgNGpbLUAAAAAXRSTlMAQObYZgAAAHxJREFUSMftz8ENAzEIRFGsbcADaQBIA9hpwP03FSWHPS12A7wTh6+RoFKetX5fSaCnheiHhfcp4Oj7QIduA5Iw/HESvMTVnMO906MrljOrLU3/nKx0jYksEGMF1DslAB3DWNKgMUxdglJAzM9clGtQEdAGpoO2ACqllJ8vKsYK78Vpol0AAAAASUVORK5CYII=";
  string public constant femaleName4 = "Makeup";
  string public constant femaleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEUAAAD46taUlJSUlJSUlJSUlJRwCQkWAwOBFRXAogFeAAAABnRSTlMAL6g8jWqr0/waAAAAOUlEQVRIx2MYBSMeCOCUUVAJZmAwdaLAbAMiLWfEqUAQqIaQEZSDjAT88mzlZYRNGAWjYBSMghEEADXyBBRVS8s9AAAAAElFTkSuQmCC";

  string public constant maleName5 = "Mystic Eyes";
  string public constant maleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAC5pb6kibmhhLRWkQHDAAAAAXRSTlMAQObYZgAAABZJREFUOMtjGAVkAhUGXoZRMApGNgAAmEwAMpldDoEAAAAASUVORK5CYII=";
  string public constant femaleName5 = "Mystic Eyes";
  string public constant femaleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAC5pb6kibmhhLRWkQHDAAAAAXRSTlMAQObYZgAAABZJREFUOMtjGAVkAhUGXoZRMApGNgAAmEwAMpldDoEAAAAASUVORK5CYII=";

  constructor() {
    name = "Face";
    itemCount = 5;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

contract Trait02_Outfit is TraitBase {
  string public constant maleName1 = "Original";
  string public constant maleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAKlBMVEUAAAAEAwCZi2TQyprFv449KQC2sYQoHAO6rIcWDwJCLgUzJQUSDABxTy9LqcSBAAAAAXRSTlMAQObYZgAAAXRJREFUSMdiGAWjYBQMB8AIIXABJiUhAZACRQUc2jWcFAOBtJCQEXYFAD7ooAVBIAjD8DjQXdc1ugQ6Uvdxt9hjtVN0lbC7WdH/UKKfXXc35/wwL3ylPq02TR019ZaCAfE663iW2YfrQ5FiwenlzvXscmRXhQp9gddjA2nTrnUfjwunA+A1M8mwUdG6Hb+IKAecG2/EVIC2y0eFBADTs+jB32Kg9wgsdz/Abn82uo0BdB5aGe8LL04rAGWCa+JLxLK9Ae4pPPbLivBTQVQmQYDp4IeOil8CwoDFvyuCv4dW+y3DBPDuY9QUqEoimgKkvhMUFFLEkyQVhaSkF0oVCOBUILVxa+GujUtxKmCPFg9nLK3aXYBTgfSqAgZ2KUHcCgKlC4CqduG2onwpUMHqcEGcjhQsF2AQrCoUwK1AUABE4FYwEaxgJm4FM+cAFZycg1vByTNABXPOEHTDAZLLB4QbDgJNkDyJ0wpBSUFBBkHBicgBBQDZH0G9FtV2pQAAAABJRU5ErkJggg==";
  string public constant femaleName1 = "Celtic";
  string public constant femaleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAtFBMVEUAAAAAAAA6EjpXIVc6KAICGQL54sHqz6j41KLiw5j/58Xt2LxsO2xXLFdUJlQHLwdNNgUjQyN4Whn46NLv06uMWoxfRQ8ONg4GBwb2693qx5V8RHwLPwv8+fP79ev68OLt0Kd+Un4FOgXz59bz48344sfx38bq1LPcvI5+XX4+HT4oSCgVRxV8WhNmShAZEgH/79nx2rrq1LaabZrkxZmGU4Z1PHVsRWxaPVpTLlMgTyAePh6IXJO8AAAAAXRSTlMAQObYZgAAAZlJREFUWMPtlMluq0AURH1um8aEyRhjPMV2nHl+8/j///VocIKyeDLdmygStaEadIq6F4lBr169evXq1etDCnskDFnyyn8mtOTPt5c+OQcezbcFNrwOv6BD/AZiwXl+4Qfd+VEO+uoq5BOG3xJcaC456Yhzg/YJoLLXDAiN8TVaT7sFLDfawHKLKIyUINX93ZJOCejFtbnKzwLU6utKwW1SP5luOyQsfWgcd7GCApKIw26C05tj/G6zeN0VrEShhPYLBnBsgKDddSEiCIV8f8FzRkf4YEN7iFCJID+QwwSn/jF+8OYNCVXEHTFJfTzJ/aqdjX4TESkTIIZnOrLjRfjFmcLsse4PdjyCagJMAXZ2/Z8RAUUkxFWAvRA4i5QSJasYp4AiRuJEiVFVwbbFM2/l8lfbU2br7G+aeh77gYNIH9a1STMPlwDvz7xsTPbguQTs595904D70mkEL8tqU6ZzpwZe6a0bs06dAmBOaxw0nE2GrXEQQGscNJuMDw0m45lTg6fHhhs/PbrtgJcGY95lB1SjD2nNf/QPmaYTDRu/NAsAAAAASUVORK5CYII=";

  string public constant maleName2 = "Tribal";
  string public constant maleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAOVBMVEUAAAAAAAAcFAEcGRkuKio0JgknGgA5AgJHQUEqJBQvJApADw9KCwv45s7x0qdhGhr/58eUlJQNCQGYjs6JAAAAAXRSTlMAQObYZgAAASVJREFUWMPtkMtuhDAQBKdmxg/em/z/xwY7IOWQy5grtVrUluiiQV5eXl5eXl6GwB+1i0iNdtRhuw4buAUdzMbOldnLsZTgBnCkb9gptax1tSIenHB2EdjcVrfjWGt8gkj/l3Vd6uJWqgcEaq38abHa2V6W80JAkFK7/atFKGU9ailIALIp2+c61OIGEgHFuQ8IvR41GPIEEv7QoLPBMwOuTw2mwLMNNjIC4P4OQy+B58zN0HRrj26gKiOoG26QUhozwGx6WhxAJe5QpZPNz59+xwU5ZUUTHR9YQE5kaJqckw0IVFEyXTMzKOhtRYgLeom5OZpAwvQK2ofIMHCvH1rQ2neIM3GP1xbiClWdVHuaWowLAH4FfVBcME33ghY03L/4k/7lByu8BaY4bJXqAAAAAElFTkSuQmCC";
  string public constant femaleName2 = "Gold";
  string public constant femaleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAMFBMVEUAAAAAAAB4TSFbPyODVSavmACOXCqHXjWlazHbwybBrSXQtxLXwSzTuxnLsQO9pgoVqm2xAAAAAXRSTlMAQObYZgAAAUxJREFUSMdiGAWjYBSMAjoBgAQFGRgYBfEoiD7KwMC6Fbc86/mZAQzRfwKwSjILABX82b2Vdc987ApMDUFuAAEB7AbEGoDsWCkqeAu7AZyLwY6YJRh4FaTAWADDBgMQyRglKghSwHzVAF2BMMQbooKBS4GaLRfj8CfjQ6CKQAbmSAMcCoTlBAPlhBkYjXEZYGT4UPAhULcADnlhJWfBiYIKQCYuAxRLDAWNG/AoEDFPUipMxqcAUAcdqzAIAwEAxT9oLiG43hmS+WLpbhDtZ7QR2tkU3A2F/nZXB29/0/vitsCDJXDTUzsWthLQ1RRzvTsvArJkqsnQXwSAE5loEnQSgFQgDSJoYvIR0zMPMggR85q8DLhC4Nl9WACOM/g44U8EtoSwBJzPgd6dpde4RxzPgYJh67xZ39QqIZJIVUAf9lPQcK9Ur7ValT6APzVWQIqGgyJgAAAAAElFTkSuQmCC";

  string public constant maleName3 = "Belt";
  string public constant maleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAMFBMVEUAAAAAAAAUDQB2clNXS0O0roKdmHeHg2ZiVk6rpn8kGQE6KAIlFgHQyprTz6vDv5lkXtKcAAAAAXRSTlMAQObYZgAAAXNJREFUSMftkrFOg0Acxg8uxvWOO6glGoGpqQsXQpuOGAZWQmLj2JDKAzRoOmoYWDvY7oxu7Rv4Ir6Bg2/gHR1MgGPQzfQb/pDcL9/3/XMHTjrppP+gc8SH4sqOoWZv+GfIJAT0mY25weMg6QamObvREdDZNMadBsYiMTECBsn0HHUAOIt908YYG/NJRjqAWY7O2B5jEq+9e91tJ8xToMTV1ScxVnC2a/c8wy6AiXn9QTIM4GvWtFCmG+6SavuvyZr/eTvUTBi6YhE2xrOFaNjaw1gJm6fEtP0tB7xtM2LjCptlzioSpwDepc0KST2NjJh7PwX+srVmHQnjB8wqPYGDleS6PC7NBvpCcp8KFkLyF6G+HcaHCvxBqlOrDwgiWlDLkgIjWjhR8CIHgvAWjEIqBRRaWEAtAyR1KCkHgqInouTAc9QDRBygpRygIQeinpLiTC0u5A5FIDqEciCsI3q2cBzrOH4r9fLdOg6JbEdzjuNH33AyQ/58tn85AAAAAElFTkSuQmCC";
  string public constant femaleName3 = "Combat";
  string public constant femaleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAM1BMVEUAAAAAAAApKCjBqojw17JJSEglGwQdFALexJ0PDg7ev5IiIiI6KALbxKJCPT07ODj/58X5kaftAAAAAXRSTlMAQObYZgAAAP5JREFUWMPtkcuugzAMRBnHDgmv9v+/9toNoau7YCq1mxyEMkLysXGmwWAwGAwGXwQf1gu6SLj+gnf6laBDCSBy+GviUIaoNUAOMYM7bv8J5CEOAHNVfPCB7l1ijO8Wi7PtxO6N8MIdh1zOm1twzCz6Upz9vV5Iw8PiHoKJQxwgNkkK8Gb6BQhWhx0ANVjXWlEpQSopQbU+FctE0eqrqiKRSyi6LEX9AZj69PT65GjaEyVYtLxSUaUEZe+CwgmS0wQRKMPZ2E9Q14guAHeP3jj1sDMC7IoWkgeCecbWArAxBuScr8AIMjJ6oCbYcp5bmLkJ4FyB2qFP4CPgDP/wB1eYBTXFIuvLAAAAAElFTkSuQmCC";

  string public constant maleName4 = "Shirt";
  string public constant maleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAAAAAAASDg4OCQAzAgIYEQEdFAJSBgZFAgI+BQUSDACFZg1+AAAAAXRSTlMAQObYZgAAAWFJREFUSMftUT1rwzAUfIpNZ8myyccU6xdEiGboZFNDm1EUdfBmjLMHAo63GgpNtg6BZu3Q/9nndimJ5EK7hRz4jHTHu5MEF1xwwTnAp0ihW2aLFQBpbqlDX/DwjcJwzx0z0jqSixVbp2psdfht06owHIa8HG4Si+G+WbVzxtJUyu1obUs4JJ6sJOOF3rI6sSRswNM5VxPNyK5+tpyRAjH5u/4oHsCvm9djw90BwGPmMVJRCZC1xxl+84SGKtJFda1xvaMnFZE8lfNqonl3pOQ4gSKRMtfYEzu8nFwVbnx1MJExBYwa+3N4xmhpltxv92AF4Td4DxLCNXUYWAf8J2CHn2XZOIPfQN3SIBYiiEWPIQhEIMR06jIQlGMRB9Q5QQhB8Zu6O6A2YIK6OzA0CCR3BBr6IliAhvgfE4jAfqQvIoj7SxLG6Dc54KnlDK46sgO1+Qxd5ezPEfOlKr2Ofux9AlEfP33vQp+OAAAAAElFTkSuQmCC";
  string public constant femaleName4 = "Silk";
  string public constant femaleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJ1BMVEUAAAAAAAA6AwNfAgIoAQF8BASVCAgVDwHBDQ0hGAKDCwszJgg6KgQ/Uuc4AAAAAXRSTlMAQObYZgAAAU5JREFUSMdiGAWjYBSMAiIAoPA55kkYCMMAfFcH49a3l9gQlvZqCSt3xRjHUv8Ah8bRAOlsJ0LihJHBrX9BQuLq6MZK/FNey0AC/eCWu+R77r334O52DgKYsBbck0HjvPOha+HFj3nT3BkEjrICsZF3Lw0gSpnzpELI54BFw4aAJGBOd6Lk7dge+sct4rTqt9SxCe1BqqOAaXXnEsDus/IQXCzqH/68+f6mmo+PKtaPXpUl2q82Lz/swLHbyq3fguX7gAP3W6JsMd4NCDBvb9tlwbiiAtACsGGcCog05n+FyzgVEC1XgLDXKSCmayP6igad0WrdV7l0SZDcf5qwq0gQZ9/vyr1enAKT1PWGJIgGS3MOjM6APJEup0vePOSJOgUyM0m+ABJ4A12BggY9YTIF36MAhDZZihkFeKQhbEJBAkD3hIRPAlkvf4aQ7dc/Pvo9KkKdZdEAAAAASUVORK5CYII=";

  string public constant maleName5 = "Tank";
  string public constant maleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAArlBMVEUAAAAgHR0RIAUAAADfy64jHhFfOQJDMAPjy6gyKx3/58Xg0r3s2b7u1K/UwaVAOzAYKwfdzrfm0bB0SAxCOAhqQAQWLgLu2Lnl0rj33bbozqvLu6Tv3sbm1r3n1LplQApVNwRJNANsQQD658r038Ll1sLw3L7r1rXPvKEyJhQsJBERFQsdMghOPwfp0rHezLHfyqrXxapWTD8zKBRLPw1JPg0yMQcvLwdBLgMGCwG9UWtHAAAAA3RSTlMAnF/cVk2tAAABbklEQVRYw+2SyXKDMBAFSVoWMgZswOB937fs6///WMC4TA4+IB1SlSr6NKJ4rdFIVkVFRUVFRcV/AcGNlQYgMBMUGYV5PgWcLZfySWA0hZ6CvHgxG6O3UQLSPJgJgnWIUuOer3MCKAQEwyG4D/0B5fOqwfUaO41GtxvS8Z5Lt0CoPJd8/8eOu0oN7jrwobzBVeQC8Pqr5TIINwtn65cfI5dDMPChMxqPuuGYPqr8FFT+M8J3g743dBzHWwDlBUCDTIA/UGIkcBwlhNZThNwz4EwaxsLSZg+87g77HdxZBvAbI4G0kVIiM4wENhGnVDCHVjv7oCvglBBHU+REpoZ7iX4HLeJJJOVcRh9M0RbwxjvzKUhkwszW7+BIMvkiU0VtWgaCGTFZ7Ds7TFtfQEIrgUxFzBH9DtrY0s4Fn8wMbuFgw1lAuojRFmCdw9fV30POtdIW1Or1Zr1WVMYNFKUWUKs3032hqPQEtQtcq9uCH/CiFErh0+hxAAAAAElFTkSuQmCC";
  string public constant femaleName5 = "Ripped";
  string public constant femaleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAANlBMVEUAAAAAAAC9vb3////34cH78/P08PA6KAPewpkYEQErHwczJAT/58X006TXtIIdHR2DBQWdAwPFejnhAAAAAXRSTlMAQObYZgAAAQpJREFUWMPtkt1uhCAQhfmGX0V32/d/2Y66RdKmUejF3vCRGJxwDgcGMxgMBoPBYHAP4VeJFr3Hww+9SMP+Plgr1HJCsHJfv6091gN7yYqo6T09qj9iyDch7Cbcy4B9beqtAlaRvcKtU3yUfdTCE4KXqnDpgPmkungb1MSWioXrByB1M/ZuhJLguhNSrxC2QYBieH2CeoUXDGdN8GKa8JRHXLrYAkJh+7Ot+sgc4/Opn5lyugaAeCboIBEjjsWtJNMFqk/LtLgEPfJ5Vr1bdZDSo8MANL5TDwX6EqTj8EltehJEoITpvINXgtU9TAdQJxj8n7d0YcpxOiddDtM56SDnGHPe5DrLf1p8ATZrBRPPyP9eAAAAAElFTkSuQmCC";

  constructor() {
    name = "Outfit";
    itemCount = 5;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

contract Trait01_Body is TraitBase {
  string public constant maleName1 = "Beige";
  string public constant maleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAMFBMVEUAAAAAAAC0iFyVb0nFlGKueEa6i12rqKjFwcG9kGK9t7fa2rtQNx0ZEgfBBweDMQBoNclXAAAAAXRSTlMAQObYZgAAAgBJREFUSMflkjGu00AURZMd+GUECIGQfMeOlHLmxZEQ3WQSiXYc/wVYSfpUsIQvOvI/RVYASodYAjtgK2yAme8GOX4uaLnFK+yj4zfjO/kfM6UU+T0RxxiRIK6aFM4Ev6qAAkBtBIBD4WMAASC7OINHAGWBqHC11dkwAKAMC2DBEmCJaJYTKQlo0KUeBmhWRQMgGgglvr8C3tEPAVDu4fEx18VF2uGtx/I9gT//HgamNTvtfkG/+SL8jGdYImVhBYCCPifgIZfq8hI2J0ISCIoouJyRR0BSXBAz2jloUDYCMBEZ+QukgmbLJHaSuZq3mllwKC4crzw3d4GGO7v3/li4EvPjYCHU0rHfHvfe+f3BDApqXu0P1hewfkAxXW2MChFwjlk7M1D6OlMBm7ZwWtnlbfMVm4kKdg9YTQqtuVlhnU1UzTZ9IJty0wdUYeII3gOIeqpMX7DJIsDYpiWjoewBtEwP0g4rr3Wmdr1zkiqzBOzWzAxNtn9MpeODBPitBbS6uajX6ICwba1vabfun4F+Zk9AXTBbmsNkN1XpgMY6i9lzsbXUJc8nQl58eMqMROB6H/PpdBKBb/cpVxm4Xr/Sx6gY2eHUjZFTdEOICoitmbdGBg4RKIMMzMtkOMiArkw3RAMiAIwATQLuZCC03ZL/eg/TdAWUdsgEgGMojb+APzJ+e8/P6yM0AAAAAElFTkSuQmCC";
  string public constant femaleName1 = "Beige";
  string public constant femaleCont1 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAMFBMVEUAAAAAAADClGaVb0m0iFy6i12ueEarqKjFwcG2il6geFDa2rtQNx2ogVqDBQWdAwM2rGOCAAAAAXRSTlMAQObYZgAAAepJREFUSMfllbGK20AQhqU32MneYbgLBE9k96uVXaSTNHEvO3t95Jx7V/YbnOpwjYo0wU3chTxCHiUvklkpEJA16+LK+zECo49vZodZFL3GxOAjvwewHCMSYD+0bfttZ5Xg1xmdCsR2awTAEqEPCQAsCbskAqC/FEjtM1EhNKEJAQBzAK0Ew5SIJUS5ADxT7ltEFAxwM/1XAgSAMP95n9A9/JIMaULEfdD7ceDuXGIH5H/Ggfj8FRMConelEkb5A1viJHkk5O5EnIK8QChyygEoD2zMGYlYECC+IwsC0YBTFQQs6BAQLx/dxgSWXrsH5zagJP/OpjhzaEEQ7NZoLf+cG1eAcwucY40P62pUsN7axRo5boljitu5AYA3KYC2OB0RZFs1aZq9OTZ7yFI1MiITTY7Nk4ciTdWFwPKexdBF8b+dGgoK4598EGe6a3gBzJV/1vhpU3nfagDEqemwFeJj5cHPgxnpleoL4QwrPlEyEOiyE/TARmkcCKK3ZPpZ4GyBGdQXNwd+9xVsOUM0H8lcbkIHQJ/bXFqIycFnn4trC4eGc7gBeeeOTfMEgaXMgCtQAFiWAHoeAngAQSDdMlCHevAGDAElA0UAsJYBe80QPKZvEq8c84VzKK8A/k6Evou6TgyvHXf6P38BocRvaYafL5QAAAAASUVORK5CYII=";

  string public constant maleName2 = "Black";
  string public constant maleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJ1BMVEUAAAAAAABfPyEzJBZmRCVxSSOrqKjFwcG9t7fa2rsyIw/BBweDMQDWjqduAAAAAXRSTlMAQObYZgAAAeNJREFUSMflkrGx2zAQRMUOcMK3ZzyOuAAL4J0YOBQENgCSBSixS/iuwFbqcQPuxY35ICYeiqfgp39neAHxuFiAe3iPaqjKXicSVW8SJMNSJc7w9wNizhlTbwBS4jguOcEAiPV7WeZiAZ6BRXXh4PaBAnSlAyAGACailzORt4AFQEzopn2AjoM6xGQ6EDr8+hTzF/ptAD5dgHOI2crAY2FQJ+e/+0AzyRLAmD6Pxs/4gBFVkQ2ASihQXVqrLi8YWiLwH7MQCRgTWncwLTJUTzuHAHJPACGi3t6BfAnCQmYnRQYgiBgeXuYkrKUrM+13ViuJnDoAk9uvpOSEmFOOXb9ngEk4dpzrs2PR8Nj7oospiYT0aOFPk/MFY4opeD4F9wBIr8XnCHAgjweLRi7u4DVF3cA1smwBH1sdJWcAak9Dv73F0SkgSDWkOmwPSic1uGfgOQTn5805yXeuAvNFRBCItxl90BcVyImB4B/u2mMFSgLnREX5TYTB3YEpijABvXuoygosnBjHo9laWtW2Vuc+fr3rSCZwe1V9v15N4Odr1c0Gbrcf9E0tnmS4ruPJKdZhyBdoa2LqbWBUoCs2EBXQYQNh6NdhOkAB4AmwVGC2gTmtId96D029AqrDGYCoqI7/gH99HXC4zvsjbwAAAABJRU5ErkJggg==";
  string public constant femaleName2 = "Black";
  string public constant femaleCont2 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAAAAAABfPyEzJBZmRCVxSSOrqKjFwcHa2ruDBQWdAwPpdhAYAAAAAXRSTlMAQObYZgAAAcdJREFUSMfllUGO4jAQReEGrjZCrdnlkxzAcXIAO5UDdBIfgA3coLMezRHmwlPuLEYKlFn0sr9QBMrTc6X4iMNPzJFy9PtEXuJUQm4noEneKH7boq0XxuwUwAOckhAKQD3GlBMVwE41o8lTKENYjEQ0VkRWAaaQsgTpQzOg4hTBrBjoLRBRrOSiAODq93vEO/3RDP2EOkzARZnBzwsgQPhrlE0uKYKAX4rhQC0vkEzVQYltI4AGRu2LbysiiEBvBAMiKBAdi6AQSxxMEfBkS8BRdnlxhdJbjHU9kNH8ybeoGZ4UQYrwXl7MyrcZuUODCWMMTwVx9l2EhPunilPjiOitJbKewxNBN5vzul7dfb1S15knK3KH8339zNDBPiqO/mJkEV8x8imZvSC6fGXuOL+h/gEYTb5O4CFk32h2J7Ruw4AlZPBjtyPbmO0g1AjyRPva2kEEG9AgGIudQIZz2y5Q96hoGsxDF7cT/FADjtk9NuELoC0ntXXnW841BLXTt1VyO5Heufu6flKhlB3JCVwA+oFkZyVANlgE2lmAqTRDNqAEDALEAuC9AP6VofiYeUi8eMxv7mF4AeTfROl/0U61k9rJpP/zD6XKYDaOKSORAAAAAElFTkSuQmCC";

  string public constant maleName3 = "Brown";
  string public constant maleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAMFBMVEUAAAAAAAB1QxRqOw6HThmYWh+OViGrqKjFwcGCSxi9t7eMUhxtPQ/a2rvBBweDMQBDnbLWAAAAAXRSTlMAQObYZgAAAgtJREFUSMflkjGOE0EQRXdu0OUWS4BAmt9tSxYimC6bA7TbK206Hh+AtTW5IzjCihA2sTgAyBmbkW5AtAniKFyAak+CxlMOSPdLU8H006+q7n/xFFVQln5OxKJKJYh/ttvUtmwUfztL0/3+DptKAXh7/eWu3X+CAlC4/rF/lCZRAezsNdJVmxbBmWFgG+EfJgBYARCI6MV3IqsBWwDTe/jFMECjmThM71UHgsevl9P0hn4rgI2fgdJNWm2GcHXzAJo8vvszDBQbbh0CNq8mymNcYoIsHxSAaldDtCi1uDzD25IIYqCIboCriFIFissWorOZgwOZMwATUaV3IFs7DkxqJpnngGNWPCw3kUPidb2m4cz6lJDiGMDKDL4VOEX4FJMfV0MGWHHw45DyN2BRhGVlazmMkdnFaiD0K2NrLKOPzoaZM6c7VBe2Dh4IjixOLAqWKFuZIjcwBa/7gPWllDolAGJP8x5Q2KXJbRDzkOLQX5RmYnCcITTOGdv09iQ7NhloFswMR6E/o3XyIwMpBsDZk7u26IA6IqQo4e3vQHNzBFaeORBQmZOodMA6SIvRSE0tdSpLLXPP3x81IhU43Io+7nYq8O0266ADh8NX+iAWZ2bYdeXMFl1RZGtIanysdGApwLjWAS+AFB1w86orqgMEAM4A6ww0OtDEbsj/vYciXwHlYhSARZTLP8BfdWp8pWnW1pYAAAAASUVORK5CYII=";
  string public constant femaleName3 = "Brown";
  string public constant femaleCont3 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJ1BMVEUAAAAAAABqOw51QxSHThmYWh+rqKjFwcGSVx95Rhfa2ruDBQWdAwM3zOhYAAAAAXRSTlMAQObYZgAAAd5JREFUSMfllbFu2zAQhu034DGBh6ALKQloR/mnh4wUz0AyxoqAdvRiv0H0Ai7g3Vk6to/QJ+yx6lLbRw8de7AJG/rw8Xj6Bc3+x5pTLv06kZdyKiGXB2A1eKP4bYVP7wf+tnEK4AE+Dq98UgBq8PT18/E4JAWwfWBeH+WrNGHxRESHSGQV4EscONfwohlOLcsGzIqB7sRO73lRAHD7/SGcHuiHZvjYJ7TPp7RUevD9AQKE+NMokzwcE+gxfVAMM6pYFI9I7UwpWz0DCDBqXnzVEkEEeiIYEEGBqFkEhbLE0RQBT7YEzJseS1cIvcU6hI6M5h98hcDwpAiGBO/lw6zczcQ1VuixTvGqIG18nSDFzVXF/coR0V1FZD3HK4J6YxbjuHX7cUt1ba6MyM0W+/EtQzN7qZj7pfnz9JORf4M5FySXV+aa8w9qLoC1yWsP7mL2rc+AeeUmDHiNGXw5m5ENZtoIAVFOdB5b24lgAlaIxuJMIM25aRYIDVrqO3ORxWkH3wXAMbvLJPwGaKp7NXWLXa5tjGqmd6PU7p70zO3H8Y0KoaxJduAC0HREdlUCZIJFoNoI0Jd6yAaUgE6AVAC8F8DfMhSPmZvEjWP+4xy6G0B+JkrvRZuCk9j9Fbhfl29m6uQIop4AAAAASUVORK5CYII=";

  string public constant maleName4 = "Pink";
  string public constant maleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAALVBMVEUAAAAAAAD4vpv4rH73xKX7t42rqKjFwcH7zK+9t7fa2rsyIw/00LrBBweDMQCWw/eAAAAAAXRSTlMAQObYZgAAAexJREFUSMflkzGOE0EQRdc3mHIJhJAI/LtHctpdMxLptssXaHskUidwhBWpxUp7ApBDxAUQx+AaXISanQR5poxEyg8qmTe/frd+3/2PWtEo/zuRmJJLkPSDqZfG8ece2ELLITmA1O0nVR3gAJS3j2oq1QE4Q01nfQzNMgBAy9bGzgWIaL0hYg+ImHRYBmg9OgCuAyHq19ctftI3B+DzTnXz7qiOwwt9QqdU9/e/loHVYXdG+YH2jR1z2SK+xajYOQBVszC1915dXik2RPH43S2EGQw1bmyDZ/EEBW52DgHU3ACEiJK/gbgGyUJuJ0V6IHTieLDEIlllKJWWOxtVEUsLYLH43BXRgqhFY0iLBgfJsbXPsD3NHMj7xNWAUkRCSQulPzRcsbcUgXM3bz5LuuOaI5ADMZBmEawlbCnGBc1KhmuAj8lGVQVg9tSn61s0A1uDki2kOeyvAMrJ5pghawgNd1dvh8zgec9ORBAoXx+Td2kKoiUDgWePj3UCakFWUJ5dNUkzOUSRTBmpmVVlAoZiK3jttpYmpeR17uX7ZzG5wOXB9PF0coEvD6MuPnC5fKYPZnEjw2kaN04xDUdcYa0Bkg+0BrTVB2CADR8IfZqG6/C3DBhGoN4IiSnkv97DavyZxtE4gJhoHH8AvwGvdHTalXd5GgAAAABJRU5ErkJggg==";
  string public constant femaleName4 = "Pink";
  string public constant femaleCont4 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAAAAAAD4vpv3xKX4rH77t42rqKjFwcHa2ruDBQWdAwPDRkYyAAAAAXRSTlMAQObYZgAAAb5JREFUSMfllc1t6zAQhOMOuDGfEbwbh3IB4soFkKIKiH8K8MXuIDo/4JWQgrOUggSQvfQhxwwMwYY/jUa7I+jpN2pFRfr/RFkUVYLyAKA5ZaP424S9Z8YxKkAGuAgKQAN4UlAAK/4o8koICyYidkTWKA4tMJk4zQGuRGRWHOi5/bwEKQDY/XsJeKH/mkMfgBZAp2TIDU+AezfKJD0HEPC3UZZBiVEUnLZOmyDyMGpfcnJEcJXGZAbEoEL0LAYVWeLWVIFMtgashj2aWCm9xRZoyGj+p9xzAGdSDE6ec5YPoK0biXd84K13dw38MSfPIgx8z+J5F4lo3RPZzO0dg/5oNuN4jtfxTKk3d0YUnzbX8a1A0l93u8jOyCAmGfl1MksDH8uRuefyhYYbYGfK8cDctcVvuwBWKc4Y86Et4OtiRnY+w7KoFTwsDP7MK5yBzli8LhOEOM+ihOxpv+j9V2ibO3GIQLxtwgTQrLXTCrG5FJ1btbZ0GUWXNemdu47jG1VKmUiugAowNER2VwNkpTowl0b2UMtQHLgGNAL4CpCzAPmRQ/U2S0h+cJs/nEPzACjPRO29aA8hrhJL0m99ADacXnD5N0KDAAAAAElFTkSuQmCC";

  string public constant maleName5 = "White";
  string public constant maleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAKlBMVEUAAAAAAADitYjToG3txJveqnfpvZGrqKjFwcG9t7fa2rsyIw/BBweDMQB3CR9ZAAAAAXRSTlMAQObYZgAAAe5JREFUSMflkjGSEzEQRe0bqC1cVFEk/tI4l9q+gCwTkCF7nK93rdwRHGE5ATikuADFVbgQLSah7GlTRbo/6GDmzddvzZ+8RE2pSX9PxKKgEsTrvomN4m/XgEc97oICcPHvaq09FICiT1V0LApgI6oo1a0z4wCqBPBAfVSA5ZGIZgsiqzk8YdBuHKBZFQdAdSA85W9vOryn7wpg0zbnxf5QtQw1Y5+pnB5+jQPT3WNC+onu7Un5GfPlCk3LgwJQEQvR6UGry6uKBdHy8EMtRAL6slyYiWqRUYG7nYMDmTsAE1HQTyBbHEcmtZPMa8CtWPGw7BPHzH0qNN5ZnzN86rRC2FXinOBzyr4LowY7jr6T14h5xGIat8EWAVJidimMlH5nbMFWUjgbV87c7hAmtkQPREcWCDcRNmZiJUU7wEy5vwasDzJKzgDEntbh+ha3RgBGihJSHK4XpVV70DLE7Jyx+6s9SQwasN8wMxzF6zXtRh40IKcIOHtz1/M8ACUhZlBxVwYS2gwOnjlSRDA3VRmAPqWI+UxtLQ36ECaKXn/8ozmpwOVZ9Pl8VoGvz00XHbhcvtAnsbiT4TyMO1sMQ5EtkNYAQQc6AbqiAxBAhg64dRiG6vCvDOgbUHSgYAj5v/cwbR9TG0YBWERt/AX8BojXea+9ngm4AAAAAElFTkSuQmCC";
  string public constant femaleName5 = "White";
  string public constant femaleCont5 =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJ1BMVEUAAAAAAADitYjToG3txJveqnerqKjFwcHa2rvFlGK6i12DBQWdAwOZbQrlAAAAAXRSTlMAQObYZgAAAcVJREFUSMfllT1u4zAQhe0bcMyFkWIbPlIHICkXW5oZF1vGPwdwY98gqhd7gj3CniEXzFAKEMDy0EXKPBgGBH36NBwOocV3zJJq9PtEWRJVQm4D8KdsFL9N2AdmHKICZIBroAC0AY8pCmDFj5qgFGHBRMSOyBrFsAVGidMMcLVEZsVAq+3HK0gBwO7PU8ET/dUMfQG2tZlKDdnzCLg3o3QycAEBPxXDghKjpriFEpsgCTDqvOTkiOAaE5MZEEGD6FkEjVjirWkCmWwLWG728LEx9BYd4Mlo/lPuuYAzKYJT4Jzll6BtNwrv+MhdcHcF4ZBTYAm63/cUq10koh89kc38744gHcx6GM7xOpwp/TJ3WhQX6+vwWiGZ3//zjXw20ogxRq5O5lYQ4jT5CXE8hjNgZ+r/keFd9XU3wLKPI9Yx710FX256ZKcnbODCTlZUbgR22sIJ8Mbyy+xYxqkXXBInOj6b2Syaj6NTmCMQ55MwAjRl5bSBWF9qzk4dW7oMksuK9Jm7DsMrNYYykbwBDWDjieyuBUgDmkB/EODYqqEauAV4AUIDyFmA/MjQXGYtkh8s84t98A+AeiZa30W7D3HZQyr9zDuYJF3ulnosKgAAAABJRU5ErkJggg==";

  constructor() {
    name = "Body";
    itemCount = 5;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

contract Trait00_Background is TraitSolid {
  string public constant itemName1 = "Lake";
  string public constant itemCont1 =
    "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";

  string public constant itemName2 = "River";
  string public constant itemCont2 =
    "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";

  string public constant itemName3 = "Sea";
  string public constant itemCont3 =
    "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";

  string public constant itemName4 = "Forest";
  string public constant itemCont4 =
    "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";

  string public constant itemName5 = "Desert";
  string public constant itemCont5 =
    "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";

  string public constant itemName6 = "Jungle";
  string public constant itemCont6 =
    "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";

  constructor() {
    name = "Background";
    itemCount = 6;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Shop is Ownable {
  //
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IToken.sol";

contract Treasury is Ownable {
  string public constant name = "AvaxHunters - Treasury";

  uint256 public totalFunds;
  uint256 public totalShares;
  mapping(address => uint256) public shares;

  uint256 shareUnit;
  mapping(address => uint256) lastUnits;
  uint256 thumbs;

  function addShare(address account, uint256 share) internal {
    require(account != address(0), "Invalid account");
    require(shares[account] == 0, "Invalid share");
    totalShares += share;
    shares[account] = share;
    lastUnits[account] = shareUnit;
  }

  function addShares(address[] calldata accounts, uint256[] calldata sharings) external onlyOwner {
    require(accounts.length == sharings.length, "Invalid input");
    for (uint8 i = 0; i < accounts.length; i++) {
      addShare(accounts[i], sharings[i]);
    }
  }

  function removeShare(address account) internal {
    require(shares[account] > 0, "Invalid share");
    uint256 share = shares[account];
    delete shares[account];
    totalShares -= share;
    if (shareUnit > lastUnits[account]) {
      uint256 refund = (shareUnit - lastUnits[account]) * share;
      addFund(refund, false);
    }
  }

  function removeShares(address[] calldata accounts) external onlyOwner {
    require(accounts.length < 256, "Invalid length");
    for (uint8 i = 0; i < accounts.length; i++) {
      removeShare(accounts[i]);
    }
  }

  function addFund(uint256 amount, bool isNew) internal {
    require(totalShares > 0, "No shares");
    if (isNew) {
      totalFunds += amount;
    }
    uint256 newFunds = amount + thumbs;
    uint256 newUnit = newFunds / totalShares;
    shareUnit += newUnit;
    thumbs = amount - (newUnit * totalShares);
  }

  function getAllocation(address account) public view returns (uint256 allocation) {
    allocation = (shareUnit - lastUnits[account]) * shares[account];
  }

  function withdraw() external {
    uint256 allocation = getAllocation(msg.sender);
    require(allocation > 0, "No funds");
    lastUnits[msg.sender] = shareUnit;
    payable(msg.sender).transfer(allocation);
  }

  function sweepToken(IToken token, address to) external onlyOwner {
    token.transfer(to, token.balanceOf(address(this)));
  }

  receive() external payable {
    addFund(msg.value, true);
  }
}