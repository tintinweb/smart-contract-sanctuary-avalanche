// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../bases/ProxyData.sol";
import "./Whitelister.sol";
import "../interfaces/IDrawer.sol";

contract Data is ProxyData, Whitelister {
  uint256 public constant TRAIT_COUNTS = 0x0005000500050006000500050006;

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