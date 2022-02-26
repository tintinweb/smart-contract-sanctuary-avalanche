// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDrawer.sol";

contract Data is Ownable {
  uint256 public constant TRAIT_COUNTS = 0x00050005000500050005000500050005000500050006;
  uint256 public constant ENERGY_PER_DAY = 3_000_000;
  uint256 public constant MAX_ENERGY = 20_000_000;

  struct Hunter {
    string name;
    uint256 traits;
    uint256 info;
  }

  IDrawer public drawer;

  mapping(uint256 => Hunter) hunters;

  function setDrawer(IDrawer newDrawer) external onlyOwner {
    drawer = newDrawer;
  }

  function registerHunter(uint256 hunterId, uint256 seed) external onlyOwner {
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
    }

    bool isMale = (uint16(seed) % 100) < 70;
    traits = (traits << 16) | (isMale ? 1 : 0);
    seed = seed >> 16;

    uint256 rate = ((seed & 0xFFFF) % (isMale ? 25 : 10)) + (isMale ? 45 : 10);

    hunters[hunterId] = Hunter("", traits, (rate << 64) | block.timestamp);
  }

  function nameHunter(uint256 hunterId, string memory name) external onlyOwner {
    hunters[hunterId].name = name;
  }

  function getHunter(uint256 hunterId) internal view returns (Hunter storage hunter) {
    hunter = hunters[hunterId];
    require(uint64(hunter.info) < block.timestamp);
  }

  function useEnergy(uint256 hunterId) external onlyOwner returns (uint256 energy) {
    Hunter storage hunter = getHunter(hunterId);
    energy = ((block.timestamp - uint64(hunter.info)) * ENERGY_PER_DAY) / 1 days;
    if (energy > MAX_ENERGY) {
      energy = MAX_ENERGY;
    }
    hunter.info = ((hunter.info >> 64) << 64) | block.timestamp;
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
    Hunter storage hunter = getHunter(hunterId);
    name = hunter.name;
    uint256 tokenTraits = hunter.traits;
    uint256 tokenInfo = hunter.info;

    generation = uint8(hunterId >> 240);
    tokenIdx = uint16(hunterId);
    isMale = uint16(tokenTraits) > 0;
    pieces = new uint16[](6);

    for (uint16 i = 0; i < 7; i++) {
      tokenTraits = tokenTraits >> 16;
      pieces[i] = uint16(tokenTraits);
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