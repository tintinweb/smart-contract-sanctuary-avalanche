// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./KindaRandom.sol";

interface ISausagers {
    function mint(address to, uint256 id) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

interface ICondimints {
    function burn(uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract SausageStand is Ownable, KindaRandom {
    // Address of the burnable token.
    address public condimintsAddress;

    // Address of the mintable token.
    address public sausagersAddress;

    // Time the exchange opens.
    uint256 public startTime = 1683219600;

    // Sausagers are indexed from 1, for future runs, this could be changed to 5001, 10001, etc.
    uint256 public startIndex = 1;

    // The amount that can be exchanged in this run.
    uint256 public totalSupply = 5000;

    // Number that have already been exchanged.
    uint256 public currentMinted;

    // Prevent contracts from minting, since we're only doing 'good enough' RNG.
    modifier isEOA() {
        require(tx.origin == msg.sender, "No contracts allowed");
        _;
    }

    struct ExchangeDetails {
        uint256 startTime;
        uint256 currentMinted;
        uint256 totalSupply;
        uint256 condimintsBalance;
        uint256 sausagersBalance;
        bool isApproved;
        uint256[] condimints;
    }

    // Helper function for fetching data about the exhange for a specific user.
    function exchangeDetails(address _user) public view returns (ExchangeDetails memory) {
        ICondimints condimints = ICondimints(condimintsAddress);
        ISausagers sausagers = ISausagers(sausagersAddress);

        uint256 curIdx = 0;
        uint256[] memory ownedTokens = new uint256[](10);
        for (uint32 i = 1; i <= totalSupply; ++i) {
            try condimints.ownerOf(i) returns (address tokenOwner) {
                if (tokenOwner == _user) {
                    ownedTokens[curIdx] = i;
                    ++curIdx;
                    if (curIdx == 10) {
                        break;
                    }
                }
            } catch {
                continue;
            }
        }

        return
            ExchangeDetails({
                startTime: startTime,
                currentMinted: currentMinted,
                totalSupply: totalSupply,
                condimintsBalance: condimints.balanceOf(_user),
                sausagersBalance: sausagers.balanceOf(_user),
                isApproved: condimints.isApprovedForAll(_user, address(this)),
                condimints: ownedTokens
            });
    }

    constructor(address condimintsAddress_, address sausagersAddress_) KindaRandom(totalSupply) {
        condimintsAddress = condimintsAddress_;
        sausagersAddress = sausagersAddress_;
    }

    // Burns a list of condimints, and mints an equivalent amount of sausagers.
    function mint(uint256[] calldata condimintTokenIds) external isEOA {
        uint256 quantity = condimintTokenIds.length;
        require(totalSupply >= currentMinted + quantity, "None left");
        require(block.timestamp >= startTime, "Can't mint yet!");

        ICondimints condimints = ICondimints(condimintsAddress);
        for (uint256 i = 0; i < quantity; ++i) {
            uint256 tokenId = condimintTokenIds[i];
            require(msg.sender == condimints.ownerOf(tokenId), "Not your token");
            condimints.burn(tokenId);
        }

        ISausagers sausagers = ISausagers(sausagersAddress);
        for (uint256 i = 0; i < quantity; ++i) {
            uint256 randomish = _randomInt(i) % (totalSupply - currentMinted - i);
            uint256 newItemId = generateKindaRandomID(randomish) + startIndex;
            sausagers.mint(msg.sender, newItemId);
        }
        currentMinted += quantity;
    }

    // The RNG is 'good enough' without using ChainLink and provides a better user
    // experience. To prevent sniping of uniques we will use a reveal server to hide unknown metadata.
    function _randomInt(uint256 seed) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, currentMinted, block.timestamp, blockhash(block.number))));
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract KindaRandom {
  uint256 private _index;
  uint256 private _supply;
  mapping(uint256 => uint256) _ids;

  constructor(uint256 supply_) {
    _supply = supply_;
  }

  function generateKindaRandomID(uint256 randomIndex) internal virtual returns (uint256) {
    uint256 remainder = _supply - _index;
    uint256 available;
    uint256 result;

    if (_ids[remainder - 1] == 0) {
      available = remainder - 1;
    } else {
      available = _ids[remainder - 1];
    }

    if (_ids[randomIndex] == 0) {
      result = randomIndex;
      _ids[randomIndex] = available;
    } else {
      result = _ids[randomIndex];
      _ids[randomIndex] = available;
    }

    _index++;

    return result;
  }
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