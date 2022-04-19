/**
 *Submitted for verification at snowtrace.io on 2022-04-19
*/

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

  function nftInfo(uint256 id) external view returns (NFTInfo memory);
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
  IERC20 public PLAYMATES;
  INFT public NFT;
  IMansionsHelper public MANSIONSHEPLER;
  IMansionManager public MANSIONSMANAGER;
  ITaxManager public TAXMANAGER;

  constructor(address _PLAYMATES, address _NFT) {
    PLAYMATES = IERC20(_PLAYMATES);
    NFT = INFT(_NFT);
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
}