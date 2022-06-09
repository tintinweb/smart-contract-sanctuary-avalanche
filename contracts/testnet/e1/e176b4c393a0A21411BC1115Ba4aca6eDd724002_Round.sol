// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../bases/ERC721EnumerableV2.sol";

import "../interfaces/ITeam.sol";
import "../interfaces/IToken.sol";

contract Round is ERC721EnumerableV2 {
  uint256 public constant EMISSION = 2_000_000_000; // 2k $orb

  uint256 public constant ENERGY_RATE = 10; // $energy exchange rate
  uint256 public constant CRYSTAL_RATE = 25; // $crystal exchange rate

  bool public initialized;

  ITeam public team;
  IToken public orb;

  mapping(uint256 => uint16) public roundSizes; // round_id -> size
  mapping(uint256 => uint256) public lastClaimed; // round_id -> timestamp

  IToken public energy;
  IToken public crystal;
  mapping(address => uint256) public botRewardsClaimed; // user -> claimed

  function initialize(ITeam _team) external {
    require(msg.sender == admin);
    require(!initialized);
    initialized = true;

    name = "Round of Hunters";
    symbol = "$woh_ROUND";
    team = _team;
  }

  function setOrb(IToken newOrb) external onlyOwner {
    orb = newOrb;
  }

  function setHunter(address hunter) external onlyOwner {
    bool succ;
    bytes memory ret;

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("tokens(uint256)", 2));
    require(succ);
    energy = IToken(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("tokens(uint256)", 3));
    require(succ);
    crystal = IToken(abi.decode(ret, (address)));
  }

  function claim(uint256 roundId, address account) external {
    (, uint256[7] memory winners, ) = team.getRoundResult(roundId);
    require(team.ownerOf(winners[6]) == account, "Invalid claim");
    roundSizes[roundId] = team.getRoundSize(roundId);
    lastClaimed[roundId] = block.timestamp;
    _mint(account, roundId);
  }

  function getReward(uint256 roundId, uint256 timestamp) public view returns (uint256 rewards) {
    rewards = ((timestamp - lastClaimed[roundId]) * roundSizes[roundId] * EMISSION) / 1 days;
  }

  function getRewards(address account) external view returns (uint256 rewards) {
    uint256 balance = balanceOf[account];
    uint256 timestamp = block.timestamp;
    for (uint256 i = 0; i < balance; i++) {
      uint256 roundId = tokenOfOwnerByIndex(account, i);
      rewards += getReward(roundId, timestamp);
    }
  }

  function claimRewards(address account) external returns (uint256 rewards) {
    uint256 balance = balanceOf[account];
    uint256 timestamp = block.timestamp;
    for (uint256 i = 0; i < balance; i++) {
      uint256 roundId = tokenOfOwnerByIndex(account, i);
      rewards += getReward(roundId, timestamp);
      lastClaimed[roundId] = timestamp;
    }
    orb.transfer(account, rewards);
  }

  function claimBotRewards(address account) external {
    uint256 botRewards = team.botRewards(account);
    uint256 rewards = botRewards - botRewardsClaimed[account];
    botRewardsClaimed[account] = rewards;
    orb.transfer(account, rewards);
  }

  function getBoostedValue(address account, uint256 balance) internal view returns (uint256) {
    uint256 rounds = balanceOf[account];
    if (rounds < 5) {
      return balance; // 1x
    } else if (rounds < 10) {
      return balance << 1; // 2x
    } else if (rounds < 15) {
      return balance << 2; // 4x
    } else {
      return balance << 4; // 8x
    }
  }

  function exchangeEnergy() external {
    address account = msg.sender;

    uint256 balance = energy.balanceOf(account);
    energy.burn(account, balance);

    balance = getBoostedValue(account, balance) * ENERGY_RATE;
    orb.transfer(account, balance);
  }

  function exchangeCrystal() external {
    address account = msg.sender;

    uint256 balance = crystal.balanceOf(account);
    crystal.burn(account, balance);

    balance = getBoostedValue(account, balance) * CRYSTAL_RATE;
    orb.transfer(account, balance);
  }

  function getRounds(address account) external view returns (uint256[] memory roundIds) {
    uint256 balance = balanceOf[account];
    roundIds = new uint256[](balance);
    for (uint256 i = 0; i < balance; i++) {
      roundIds[i] = tokenOfOwnerByIndex(account, i);
    }
  }

  function emergencyWithdraw() external onlyOwner {
    orb.transfer(admin, orb.balanceOf(address(this)));
  }

  function tokenURI(uint256 roundId) external view returns (string memory) {
    return team.roundURI(roundId);
  }

  function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address receiver, uint256 royaltyAmount) {
    // 5% of royalty fee
    return (admin, (value * 500) / 10000);
  }

  event RoyaltiesReceivedEvent(address, address, uint256);

  function royaltiesReceived(
    address _recipient,
    address _buyer,
    uint256 amount
  ) external virtual {
    emit RoyaltiesReceivedEvent(_recipient, _buyer, amount);
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

interface ITeam {
  function ownerOf(uint256 teamId) external view returns (address);

  function getRoundSize(uint256 roundId) external view returns (uint16 size);

  function getRoundResult(uint256 roundId)
    external
    view
    returns (
      uint256[8] memory roundTeams,
      uint256[7] memory winners,
      uint16[7] memory scores
    );

  function roundURI(uint256 roundId) external view returns (string memory);

  function botRewards(address user) external view returns (uint256 rewards);
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