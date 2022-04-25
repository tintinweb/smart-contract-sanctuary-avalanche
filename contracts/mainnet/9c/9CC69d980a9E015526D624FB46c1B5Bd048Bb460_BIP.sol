/**
 *Submitted for verification at snowtrace.io on 2022-04-22
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: contracts/BIP.sol

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.7;


abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface INFT {
  struct NFTInfo {
    uint256 value;
    uint256 mintTimestamp;
  }

  function _baseURI() external view returns (string memory);
  function lockedValues(uint256 id) external view returns (uint256);
  function exists(uint256 tokenId) external view returns (bool);
  function ownerOf(uint256 tokenId) external view returns (address);
  function balanceOf(address owner) external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
  function mint(address to, uint256 value) external;
  function updateValue(uint256 id, uint256 value) external;
}

interface IMansionsHelper {
  function getClaimFee (address sender) external view returns (uint256);
  function newTax () external view returns (uint256);
  function claimUtility(uint64[] calldata _nodes, address whereTo, uint256 neededAmount, address excessAmountReceiver, address nodesOwner) external;
}

interface IMansionManager {
    function getAddressRewards(address account) external view returns (uint);
    function getUserMultiplier(address from) external view returns (uint256);
}

interface ITaxManager {
  function execute(uint256 remainingRewards, address receiver) external;
}

contract BIP is Ownable, ReentrancyGuard {
  using Strings for uint256;
  
  IERC20 public PLAYMATES;
  INFT public NFT;
  IMansionsHelper public MANSIONSHEPLER;
  IMansionManager public MANSIONSMANAGER;
  ITaxManager public TAXMANAGER;

  uint256[] public tiersIncrease = [1500, 1200, 1000, 900, 800, 700, 600, 500, 400, 300, 0];
  uint256[] public tiers = [0, 500, 750, 1000, 1250, 1500, 1750, 2000, 2500, 3000, 5000];

  mapping(address => uint256) public fakeLockedValue;

  constructor(address _PLAYMATES, address _NFT, address _MANSIONSHEPLER, address _MANSIONSMANAGER, address _TAXMANAGER) {
    PLAYMATES = IERC20(_PLAYMATES);
    NFT = INFT(_NFT);
    MANSIONSHEPLER = IMansionsHelper(_MANSIONSHEPLER);
    MANSIONSMANAGER = IMansionManager(_MANSIONSMANAGER);
    TAXMANAGER = ITaxManager(_TAXMANAGER);
  }

  modifier tokenExists(uint256 tokenId) {
    require(NFT.exists(tokenId), "ERC721: owner query for nonexistent token");
    _;
  }

  function getTokenTierIncrease(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
    return tiersIncrease[getTokenTierIndex(tokenId) - 1] + (NFT.lockedValues(tokenId) / 1e18 / 100) * 100;
  }

  function getTokenTierIndex(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
    uint256[] memory tiers_ = tiers;
    uint256 value = NFT.lockedValues(tokenId) + fakeLockedValue[NFT.ownerOf(tokenId)];
    for (uint256 i = 0; i < tiers_.length; i++) {
      if (value < tiers_[i] * 1e18) return tiers_.length - i + 1;
    }
    return 1;
  }

  function tokenURI(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
    string memory baseURI = NFT._baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, getTokenTierIndex(tokenId).toString(), ".json")) : "";
  }

  function nextTokenURI(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
    string memory baseURI = NFT._baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, (getTokenTierIndex(tokenId) - 1 == 0 ? 11 : getTokenTierIndex(tokenId) - 1).toString(), ".json")) : "";
  }

  function getNextAmountStaked(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
    return getTokenTierIndex(tokenId) - 1 == 0 ? 0 : tiers[tiers.length - getTokenTierIndex(tokenId) + 1];
  }

  function giveaway(uint256 amount, address to) nonReentrant onlyOwner public {
    fakeLockedValue[to] += amount;
  }

  function stake(uint256 amount) nonReentrant public {
    require(PLAYMATES.balanceOf(_msgSender()) >= amount, "STAKE: PLAYMATES balance too low.");
    PLAYMATES.transferFrom(_msgSender(), address(this), amount);
    _stake(_msgSender(), amount);
  }

  function compoundAndStake(uint64[] memory userNodes, uint256 amount) nonReentrant public {
    uint256 addressRewards = MANSIONSMANAGER.getAddressRewards(_msgSender());
    uint256 availableRewards = addressRewards + addressRewards * MANSIONSMANAGER.getUserMultiplier(_msgSender()) / 1000;
    require(availableRewards >= amount, "STAKE: Not enough to compound");

    MANSIONSHEPLER.claimUtility(userNodes, address(this), amount, address(TAXMANAGER), _msgSender());
    TAXMANAGER.execute(availableRewards - amount, _msgSender());

    _stake(_msgSender(), amount);
  }

  function _stake(address user, uint256 amount) internal {
    if (NFT.balanceOf(user) != 0) {
      NFT.updateValue(NFT.tokenOfOwnerByIndex(user, 0), amount);
    } else {
      NFT.mint(user, amount);
    }
  }

  function withdrawPlaymates() public onlyOwner {
    PLAYMATES.transfer(owner(), PLAYMATES.balanceOf(address(this)));
  }

  function updateNft(address _NFT) public onlyOwner {
    NFT = INFT(_NFT);
  }

  function updateMansionsHelper(address _MANSIONSHEPLER) public onlyOwner {
    MANSIONSHEPLER = IMansionsHelper(_MANSIONSHEPLER);
  }

  function updateMansionsManager(address _MANSIONSMANAGER) public onlyOwner {
    MANSIONSMANAGER = IMansionManager(_MANSIONSMANAGER);
  }

  function updateTaxManager(address _TAXMANAGER) public onlyOwner {
    TAXMANAGER = ITaxManager(_TAXMANAGER);
  }

  function updateTiers(uint256[] memory tiers_) public onlyOwner {
    require(tiers_.length == tiers.length);
    tiers = tiers_;
  }

  function updateTiersIncrease(uint256[] memory tiersIncrease_) public onlyOwner {
    require(tiersIncrease_.length == tiersIncrease.length);
    tiersIncrease = tiersIncrease_;
  }
}