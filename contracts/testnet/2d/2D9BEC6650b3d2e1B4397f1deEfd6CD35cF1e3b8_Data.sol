// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../bases/ProxyData.sol";
import "../utils/Whitelister.sol";
import "../interfaces/IDrawer.sol";

contract Data is ProxyData, Whitelister {
  uint256 public constant TRAIT_COUNTS = 0x00050005000500050005000500050005000500050006;
  uint256 public constant ENERGY_PER_DAY = 3_000_000;
  uint256 public constant MAX_ENERGY = 20_000_000;

  struct Hunter {
    string name;
    uint256 traits;
    uint256 info;
  }

  bool public initialized;

  IDrawer public drawer;

  mapping(uint256 => Hunter) hunters;

  function initialize() external {
    require(msg.sender == admin);
    require(!initialized);
    initialized = true;
  }

  function setDrawer(IDrawer newDrawer) external onlyAdmin {
    drawer = newDrawer;
  }

  function registerHunter(uint256 hunterId, uint256 seed) external withinWhitelist {
    require(hunters[hunterId].traits == 0);
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
      traits = (traits << 16) | ((seed & 0xFFFF) % (traitCounts & 0xFFFF));
      seed = seed >> 16;
      traitCounts = traitCounts >> 16;
    }

    bool isMale = (uint16(seed) % 100) < 70;
    traits = (traits << 16) | (isMale ? 1 : 0);
    seed = seed >> 16;

    uint256 rate = ((seed & 0xFFFF) % (isMale ? 25 : 10)) + (isMale ? 45 : 10);

    hunters[hunterId] = Hunter("", traits, (rate << 64) | block.timestamp);
  }

  function nameHunter(uint256 hunterId, string memory name) external withinWhitelist {
    hunters[hunterId].name = name;
  }

  function useEnergy(uint256 hunterId) external withinWhitelist returns (uint256 energy) {
    Hunter storage hunter = hunters[hunterId];
    energy = ((block.timestamp - uint64(hunter.info)) * ENERGY_PER_DAY) / 1 days;
    if (energy > MAX_ENERGY) {
      energy = MAX_ENERGY;
    }
    if (energy > 0) {
      hunter.info = ((hunter.info >> 64) << 64) | block.timestamp;
    }
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
      uint32[] memory support,
      uint256 energy
    )
  {
    Hunter memory hunter = hunters[hunterId];
    require(uint64(hunter.info) < block.timestamp, "Not available");
    name = hunter.name;
    uint256 tokenTraits = hunter.traits;
    uint256 tokenInfo = hunter.info;

    generation = uint8(hunterId >> 240);
    tokenIdx = uint16(hunterId);
    isMale = uint16(tokenTraits) > 0;
    pieces = new uint16[](7);

    for (uint16 i = 0; i < 7; i++) {
      tokenTraits = tokenTraits >> 16;
      pieces[i] = uint16(tokenTraits) + 1;
    }

    support = new uint32[](2);
    support[0] = uint32(tokenInfo >> 96); // breed
    support[1] = uint32(tokenInfo >> 64); // rate

    energy = ((block.timestamp - uint64(tokenInfo)) * ENERGY_PER_DAY) / 1 days;
    if (energy > MAX_ENERGY) {
      energy = MAX_ENERGY;
    }
  }

  function draw(uint256 hunterId) external view returns (string memory) {
    (
      string memory name,
      uint8 generation,
      uint16 tokenIdx,
      bool isMale,
      uint16[] memory pieces,
      uint32[] memory support,

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

contract Whitelister {
  mapping(address => bool) public whitelists;

  modifier withinWhitelist() {
    address sender = msg.sender;
    require(whitelists[sender]);
    _beforeUse(sender);
    _;
  }

  function setWhitelists(address[] memory newWhitelists, bool whitelisted) public virtual {
    for (uint256 i = 0; i < newWhitelists.length; i++) {
      whitelists[newWhitelists[i]] = whitelisted;
    }
  }

  function _beforeUse(address whitelist) internal virtual {}
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