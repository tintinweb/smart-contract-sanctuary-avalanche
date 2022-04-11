// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IHunter.sol";
import "../interfaces/ISeeder.sol";
import "../interfaces/IData.sol";
import "../interfaces/IShop.sol";
import "../interfaces/IToken.sol";

contract Monster is Ownable {
  uint256 constant MONSTER_LV1 = 3_000_000_000_000;
  uint256 constant MONSTER_LV2 = 5_000_000_000_000;
  uint256 constant MONSTER_LV3 = 10_000_000_000_000;
  // uint256 constant MONSTER_LM1 = 18_000_000_000_000;
  uint256 constant MONSTER_LM2 = 15_000_000_000_000;
  uint256 constant MONSTER_LM3 = 10_000_000_000_000;
  uint256 constant MONSTER_RW1 = 3 days;
  uint256 constant MONSTER_RW2 = 5 days;
  uint256 constant MONSTER_RW3 = 7 days;
  uint256 constant BONUS_RW3 = 7 days;

  uint8 constant LEADERBOARD_COUNT = 5;
  uint8 constant BONUS_POOL = 4;
  uint256 constant BONUS_RANK1 = 900_000_000_000; // 900k $orbs
  uint256 constant BONUS_RANK2 = 500_000_000_000; // 500k $orbs
  uint256 constant BONUS_RANK3 = 300_000_000_000; // 300k $orbs
  uint256 constant BONUS_RANK4 = 200_000_000_000; // 200k $orbs
  uint256 constant BONUS_RANK5 = 100_000_000_000; // 100k $orbs
  uint256 constant MAX_ENERGY = 20_000_000;

  uint256 public constant PREMIUM_PRICE = 1_000_000;

  uint256 public constant ITEM_BLUE = 1;
  uint256 public constant ITEM_PINK = 4;

  event MonsterAttacked(address user, uint256 damage, bool success);

  IHunter public token;
  ISeeder public seeder;
  IData public data;
  IShop public shop;
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

  uint256 totalHP = 18_000_000_000_000; // 18m = 3 + 5 + 10
  mapping(bytes32 => uint256) damages; // Damage per user & level
  mapping(bytes32 => uint256) claimes; // $orb claim time per user & level
  mapping(uint8 => uint256) public defeats; // Monster 1,2,3 defeat time + Bonus start time

  mapping(address => string) public names; // User Names
  mapping(address => uint256) public levels; // User Levels
  mapping(address => uint256) public successes; // Success count

  address[] public leaderboard; // Top ranks

  function setHunter(address hunter) external {
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

  function startBonus() external onlyOwner {
    require(defeats[BONUS_POOL - 1] > 0, "Invalid defeats");
    require(defeats[BONUS_POOL] == 0, "Invalid start");
    uint256[5] memory rewards = [BONUS_RANK1, BONUS_RANK2, BONUS_RANK3, BONUS_RANK4, BONUS_RANK5];
    for (uint256 i = 0; i < LEADERBOARD_COUNT; i++) {
      address user = leaderboard[i];
      require(user != address(0));
      bytes32 userHash = keccak256(abi.encodePacked(user, BONUS_POOL));
      damages[userHash] = rewards[i];
    }
    defeats[BONUS_POOL] = block.timestamp;
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

  /**
   * @dev withItem
   * - 1: Blue
   * - 2: Pink
   */
  function usePackage(
    uint8 packageId,
    uint256 lead,
    uint256 support,
    uint256[] calldata hunters,
    uint8 withItem
  ) external {
    address user = msg.sender;
    require(user == tx.origin, "Invalid sender");

    uint256 info = packages[packageId];

    if ((info >> 248) > 0) {
      if (withItem & 2 > 0) {
        shop.burn(user, ITEM_PINK, 1);
      } else {
        crystal.burn(user, hunters.length * PREMIUM_PRICE);
      }
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

    if (withItem & 1 > 0) {
      shop.burn(user, ITEM_BLUE, 1);
      multiplier = (multiplier * 1100) / 1000;
    }
    usePackageInternal(user, hunters, expected, multiplier, success);
  }

  function getMonster()
    public
    view
    returns (
      uint8 level,
      uint256 hpCurrent,
      uint256 hpMax
    )
  {
    if (totalHP <= MONSTER_LM3) {
      level = 3;
      hpCurrent = totalHP;
      hpMax = MONSTER_LV3;
    } else if (totalHP <= MONSTER_LM2) {
      level = 2;
      hpCurrent = totalHP - MONSTER_LM3;
      hpMax = MONSTER_LV2;
    } else {
      level = 1;
      hpCurrent = totalHP - MONSTER_LM2;
      hpMax = MONSTER_LV1;
    }
  }

  function usePackageInternal(
    address user,
    uint256[] calldata hunters,
    uint256 expected,
    uint256 multiplier,
    bool success
  ) internal {
    uint256 usage = token.useHunt(user, hunters);
    uint256 damage = (expected * usage * multiplier) / (hunters.length * 1_000_000) / 1000;

    (uint8 level, uint256 hpCurrent, ) = getMonster();
    require(hpCurrent > 0, "Invalid monster");

    bytes32 userHash = keccak256(abi.encodePacked(user, level));
    if (hpCurrent <= damage) {
      // Final Attendee
      levels[user] += 1;
      damage = hpCurrent;
      defeats[level] = block.timestamp;
    } else {
      if (success) {
        uint256 userSuccess = successes[user];
        if (userSuccess == 2) {
          levels[user] += 1;
        } else {
          successes[user] += 1;
        }
      } else {
        successes[user] = 0;
      }
    }
    damages[userHash] += damage;
    totalHP -= damage;
    emit MonsterAttacked(user, damage, success);
  }

  function setName(string memory name) public {
    names[msg.sender] = name;
  }

  function refreshRank(address user) public {
    require(defeats[BONUS_POOL] == 0, "Invalid time");
    uint256 level = levels[user];
    uint8 i;

    uint8 newRank = LEADERBOARD_COUNT;
    uint8 origin = LEADERBOARD_COUNT;
    address ranker;
    for (; i < LEADERBOARD_COUNT; i++) {
      ranker = leaderboard[i];
      uint256 rankLevel = levels[ranker];
      if (rankLevel < level && newRank == LEADERBOARD_COUNT) {
        newRank = i;
      }
      if (ranker == user) {
        origin = i;
      }
    }

    if (origin > newRank) {
      for (i = origin; i > newRank; i--) {
        leaderboard[i] = leaderboard[i - 1];
      }
      leaderboard[newRank] = user;
    }
  }

  function rewardPeriod(uint8 poolId) public pure returns (uint256) {
    if (poolId == 1) {
      return MONSTER_RW1;
    } else if (poolId == 2) {
      return MONSTER_RW2;
    } else if (poolId == 3) {
      return MONSTER_RW3;
    } else {
      return BONUS_RW3;
    }
  }

  function getUser(address account, uint8 poolId) public view returns (uint256 damage, uint256 claime) {
    uint256 defeat = defeats[poolId];
    bytes32 accountHash = keccak256(abi.encodePacked(account, poolId));
    if (defeat > 0) {
      damage = damages[accountHash];
      claime = claimes[accountHash];
    }
  }

  function getRewards(address account, uint8 poolId) public view returns (uint256 rewards, bytes32 accountHash) {
    uint256 defeat = defeats[poolId];
    accountHash = keccak256(abi.encodePacked(account, poolId));
    if (defeat > 0) {
      uint256 being = block.timestamp - defeat;
      uint256 period = rewardPeriod(poolId);
      if (being > period) {
        being = period;
      }
      uint256 damage = damages[accountHash];
      uint256 claime = claimes[accountHash];
      rewards = (being * damage) / period - claime;
    }
  }

  function claimRewards(address account) external {
    uint256 rewards;
    for (uint8 poolId = 1; poolId <= BONUS_POOL; poolId++) {
      (uint256 poolRewards, bytes32 accountHash) = getRewards(account, poolId);
      claimes[accountHash] += poolRewards;
    }
    orb.transfer(account, rewards);
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