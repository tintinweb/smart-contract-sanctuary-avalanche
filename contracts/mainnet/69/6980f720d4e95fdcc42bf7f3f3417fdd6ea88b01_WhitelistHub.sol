/**
 *Submitted for verification at snowtrace.io on 2022-03-16
*/

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/WhitelistHub.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IBlood {
  function burn(address from, uint256 amount) external payable;
}

interface UNFT {
  function balanceOf(address owner) external view returns (uint256);
}

interface UArena {
  function getStakedTokenIds(address owner) external view returns (uint256[] memory);
}

contract WhitelistHub is Ownable {
  IBlood private blood;
  UNFT private nft;
  UArena private arena;

  mapping(address => bool) admins;

  struct EventData {
    uint32 spots;
    uint32 spotsTaken;
    uint256 cost;
    mapping(address => bool) whitelisted;
    bool open;
    bool hidden;
  }

  event CreateOrUpdateEvent(uint16 indexed id, string name, string logo, string url, string description, uint32 spots, uint256 cost);

  event AddressWhitelisted(uint16 indexed eventId, address sender, string discordTag);
  event SetOpen(uint16 indexed eventId, bool open);
  event SetHidden(uint16 indexed eventId, bool hidden);

  uint16 idCounter = 1;
  mapping(uint16 => EventData) events;

  constructor() {
    admins[msg.sender] = true;
  }

  // Public methods
  function join(uint16 id, string memory discordTag) public onlyEOA contractsSet {
    EventData storage data = events[id];
    require(data.spots > 0, "Event not found.");
    require(data.open, "Not open for registration right now.");
    require(data.spotsTaken < data.spots, "No spot available.");
    require(!data.whitelisted[_msgSender()], "Already whitelisted.");
    require(nftCount(_msgSender()) > 0, "You need to have our NFT to participate");

    blood.burn(_msgSender(), data.cost);

    data.whitelisted[_msgSender()] = true;
    data.spotsTaken++;

    emit AddressWhitelisted(id, _msgSender(), discordTag);
  }

  function hasJoined(address from, uint16 id) public view returns (bool) {
    EventData storage data = events[id];
    require(data.spots > 0, "Event not found.");
    return data.whitelisted[from];
  }

  function isAdmin(address from) public view returns (bool) {
    return admins[from];
  }

  function getEventData(uint16 id)
    public
    view
    returns (
      uint32 spots,
      uint32 spotsTaken,
      uint256 cost,
      bool open
    )
  {
    EventData storage data = events[id];
    require(data.spots > 0, "Event not found.");
    return (data.spots, data.spotsTaken, data.cost, data.open);
  }

  function nftCount(address owner) internal view returns (uint256) {
    return nft.balanceOf(owner) + arena.getStakedTokenIds(owner).length;
  }

  // Owner methods
  function setAdmin(address _address, bool value) public onlyOwner {
    admins[_address] = value;
  }

  function setContracts(
    address _blood,
    address _nft,
    address _arena
  ) public onlyOwner {
    blood = IBlood(_blood);
    nft = UNFT(_nft);
    arena = UArena(_arena);
  }

  // Admins methods
  function addEvent(
    string memory name,
    string memory logo,
    string memory url,
    string memory description,
    uint32 spots,
    uint256 cost
  ) public onlyAdmin {
    require(spots > 0, "Spots need to be > than 0");
    uint16 id = idCounter++;

    EventData storage newEvent = events[id];
    newEvent.spots = spots;
    newEvent.cost = cost;

    emit CreateOrUpdateEvent(id, name, logo, url, description, spots, cost);
  }

  function updateEventInfo(
    uint16 id,
    string memory name,
    string memory logo,
    string memory url,
    string memory description,
    uint32 spots,
    uint256 cost
  ) public onlyAdmin {
    EventData storage data = events[id];
    require(data.spots > 0, "Event not found.");

    data.spots = spots;
    data.cost = cost;

    emit CreateOrUpdateEvent(id, name, logo, url, description, spots, cost);
  }

  function setEventOpen(uint16 id, bool open) public onlyAdmin {
    EventData storage data = events[id];
    require(data.spots > 0, "Event not found.");
    require(data.open != open, "Event is already open/closed");

    data.open = open;

    emit SetOpen(id, open);
  }

  function setEventHidden(uint16 id, bool hidden) public onlyAdmin {
    EventData storage data = events[id];
    require(data.spots > 0, "Event not found.");
    require(data.hidden != hidden, "Event is already displayed/hidden");

    data.hidden = hidden;

    emit SetHidden(id, hidden);
  }

  // Modifiers
  modifier onlyEOA() {
    require(msg.sender == tx.origin, "Must use EOA");
    _;
  }

  modifier onlyAdmin() {
    require(admins[msg.sender], "Admin only.");
    _;
  }

  modifier contractsSet() {
    require(address(blood) != address(0), "Blood contract not set");
    require(address(nft) != address(0), "NFT contract not set");
    require(address(arena) != address(0), "Arena contract not set");
    _;
  }
}