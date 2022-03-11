// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IHunter.sol";
import "../interfaces/ISeeder.sol";
import "../interfaces/IData.sol";
import "../interfaces/IToken.sol";

contract Pool is Ownable {
  uint256 public constant PREMIUM_PRICE = 1_000_000;

  /**
   * @dev contract utilities
   * - 0: seeder
   * - 1: data
   * - 2: orb
   * - 3: crystal
   */
  ISeeder public seeder;
  IData public data;
  IToken public orb;
  IToken public energy;
  IToken public crystal;

  uint256 public totalPackages;
  /**
   * @dev training information
   * -   0 ~  63: female hunts
   * -  64 ~ 127: male hunts
   * - 248 ~ 255: premium (0: no, 1: yes)
   */
  mapping(uint16 => uint256) public packages;

  function setOwner(address hunter) external {
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

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("tokens(uint256)", 2));
    require(succ);
    energy = IToken(abi.decode(ret, (address)));

    (succ, ret) = hunter.staticcall(abi.encodeWithSignature("tokens(uint256)", 3));
    require(succ);
    crystal = IToken(abi.decode(ret, (address)));

    transferOwnership(hunter);
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
    uint256[] calldata hunters,
    uint256 extra
  ) external {
    address user = msg.sender;
    require(user == tx.origin, "Invalid sender");

    IHunter token = IHunter(owner());

    uint256 info = packages[packageId];
    uint256 count = hunters.length;

    if ((info >> 248) > 0) {
      crystal.burn(user, count);
    }

    uint256 hunter;
    uint256 expected;

    require(lead == hunters[0], "Invalid lead");
    hunter = data.getData(lead);
    require(uint16(hunter >> (16 * 7)) == packageId, "Invalid lead specialty");

    uint32 result = uint32(seed(lead) % 1000);
    uint256 multiplier = result < uint32(hunter >> 128) ? (1000 + result) : 500;
    token.useHunter(lead, uint32(hunter >> 128) + 10);

    if (support > 0) {
      require(support == hunters[1], "Invalid support");
      hunter = data.getData(support);
      require(uint16(hunter >> (16 * 7)) == packageId, "Invalid support specialty");
      multiplier = (multiplier * (1000 + uint32(hunter >> 128))) / 1000;
      token.useHunter(lead, uint32(hunter >> 128) + 10);
      expected = getExpected(packageId, info, 2, hunters);
    } else {
      expected = getExpected(packageId, info, 1, hunters);
    }

    uint256 usage = token.useHunt(user, hunters);
    if (extra > 0) {
      require(extra <= count * 5_000_000, "Invalid extra energy");
      energy.burn(user, extra);
      usage += extra;
    }
    multiplier = (multiplier * usage) / (count * 1_000_000);

    orb.transfer(user, (expected * multiplier) / 1000);
  }

  function seed(uint256 updates) internal returns (uint256) {
    return seeder.get(updates);
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
pragma solidity ^0.8.0;

interface ISeeder {
  function get(uint256) external returns (uint256);
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