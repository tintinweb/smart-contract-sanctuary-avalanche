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

  /**
   * @dev contract utilities
   * - 0: seeder
   * - 1: data
   * - 2: orb
   */
  ISeeder public seeder;
  IData public data;
  IToken public orb;

  // Breed price & supply
  uint256 public breedPrice;
  uint256 public breedToken;
  uint256 public breedSupply;
  uint256 breedTicker;

  function setOwner(address hunter) external onlyOwner {
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

    transferOwnership(hunter);
  }

  function setGen(uint256[] calldata info) external onlyOwner {
    breedPrice = info[0];
    breedToken = info[1];
    breedSupply = info[2];
    breedTicker = info[3];
  }

  modifier whenNotPaused() {
    (bool succ, bytes memory ret) = owner().staticcall(abi.encodeWithSignature("states()", ""));
    require(succ);
    require(abi.decode(ret, (uint8)) & 4 > 0, "Invalid state");
    _;
  }

  function getTreasury() internal view returns (address treasury) {
    (bool succ, bytes memory ret) = owner().staticcall(abi.encodeWithSignature("treasury()", ""));
    require(succ);
    treasury = abi.decode(ret, (address));
  }

  function breed(uint256 male, uint256 female) external payable whenNotPaused returns (bool succeed) {
    require(msg.sender == tx.origin, "Invalid sender");
    require(breedTicker < breedSupply, "Insufficient supply");

    IHunter token = IHunter(owner());
    address user = msg.sender;

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
    orb.transferFrom(user, getTreasury(), (breedToken * ((BREED_MULTIPLIER >> (16 * breeds)) & 0xFFFF)) / 10);

    uint256 seedHash = seed(male + female);
    uint256 breedHash = seedHash % 100;
    succeed = breedHash < 80;
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

  function funds(address treasury) external onlyOwner {
    uint256 balance = address(this).balance;
    if (balance > 0) {
      (bool succ, ) = payable(treasury).call{ value: balance }("");
      require(succ);
    }
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