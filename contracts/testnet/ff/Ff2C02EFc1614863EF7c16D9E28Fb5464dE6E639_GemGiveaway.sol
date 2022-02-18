// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IERC721Burnable.sol";

contract GemGiveaway is Ownable, ReentrancyGuard {
  /// @notice Gem collection address
  IERC721Burnable public collection;
  /// @notice Weekly reward amount for each winner
  uint256 private rewardAmount;
  /// @notice Id for each type/color pair starting from 0. 0 ~ 329 for 6600 gems in 55 types/6 colors
  uint256[330] private uniqueIds;
  /// @notice Actual length of uniqueIds
  uint256 private pendingCount;
  /// @notice Unix timestamp for the start of current week
  uint256 public giveawayStartTimestamp;
  /// @notice Reserved amount for fees
  uint256 constant FEE = 3 ether;
  /// @notice Reward for diamond
  uint256 constant DIAMOND_REWARD = 5 ether;

  /// @notice Pairs chosen so far
  uint256[] public pairs;
  /// @notice Winner list for current week
  address[40] public winners;
  /// @notice Indicates wheater or not the winners claimed for current week
  bool[40] public claimed;

  constructor(address _collection, uint256 firstWeeklyGiveawayStart) {
    collection = IERC721Burnable(_collection);
    giveawayStartTimestamp = firstWeeklyGiveawayStart;
    pendingCount = 330;
  }

  function claimRewardForDiamond(uint256 tokenId) external nonReentrant {
    require(tokenId >= 6600 && collection.ownerOf(tokenId) == msg.sender, "Should own a diamond");
    collection.burn(tokenId);
    (bool sent, ) = msg.sender.call{value: DIAMOND_REWARD}("");
    require(sent, "Failed to send AVAX");
  }

  function claim() external nonReentrant {
    uint256 i;
    for (i = 0; i < 40; i++) {
      if (winners[i] == msg.sender && !claimed[i]) {
        break;
      }
    }
    require(i < 40, "Not winner for this week");

    uint256 tokenId = pairs[i / 20] * 20 + (i % 20);
    require(collection.ownerOf(tokenId) == msg.sender, "Ownership issue");

    // burn NFT
    claimed[i] = true;
    collection.burn(tokenId);
    (bool sent, ) = msg.sender.call{value: rewardAmount}("");
    require(sent, "Failed to send AVAX");
  }

  function setGiveawayStartTimestamp(uint256 _giveawayStartTimestamp) external onlyOwner {
    giveawayStartTimestamp = _giveawayStartTimestamp;
  }

  function setCollectionAddress(address _collection) external onlyOwner {
    collection = IERC721Burnable(_collection);
  }

  function chooseRandomPairs() external onlyOwner {
    require(
      giveawayStartTimestamp < block.timestamp && pendingCount >= 2,
      "Weekly giveaway not started yet"
    );
    giveawayStartTimestamp += 7 days; // next week
    rewardAmount = (address(this).balance - FEE) / 40; // 25% of the current treasury will be used as reward. Treasury will fund this contract every week. And it will be distributed equally among 40 winners

    // choose 2 random pairs
    getRandomNumber();
    getRandomNumber();
  }

  function getRandomNumber() private {
    uint256 id = uint256(
      keccak256(abi.encodePacked(block.difficulty, block.timestamp, rewardAmount, pendingCount))
    ) % pendingCount;
    uint256 newRandomNumber = _getTokenIdByIndex(id);
    // remove element from the array
    uniqueIds[id] = _getTokenIdByIndex(pendingCount - 1);
    pendingCount--;

    pairs.push(newRandomNumber - 1);

    if (pairs.length % 2 == 0) {
      // chose 2 winners
      for (uint256 i = 0; i < 20; i++) {
        winners[i] = collection.ownerOf(20 * pairs[pairs.length - 1] + i);
        winners[i + 20] = collection.ownerOf(20 * pairs[pairs.length - 2] + i);
        claimed[i] = claimed[i + 20] = false;
      }
    }
  }

  function _getTokenIdByIndex(uint256 index) internal view returns (uint256) {
    return uniqueIds[index] == 0 ? index + 1 : uniqueIds[index];
  }

  function getRewardAmount() external view onlyOwner returns (uint256) {
    return rewardAmount;
  }

  function getUniqueIds() external view onlyOwner returns (uint256[330] memory) {
    return uniqueIds;
  }

  function withdraw(address to, uint256 value) external onlyOwner {
    (bool sent, ) = to.call{value: value}("");
    require(sent, "Failed to send AVAX");
  }
}

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC721Burnable {
  function ownerOf(uint256 tokenId) external view returns (address owner);

  function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}