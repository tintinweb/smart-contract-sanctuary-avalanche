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