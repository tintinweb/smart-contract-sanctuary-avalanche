/**
 *Submitted for verification at snowtrace.io on 2022-03-25
*/

pragma solidity ^0.8.0;

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

interface IMansionManager {
  function getUserMultiplier(address from) external view returns (uint256);
}

interface IDistrictManager {
  struct District {
      string name;
      string metadata;
      uint256 id;
      uint64 mint;
      uint64 claim;
  }

  function ownerOf(uint256 tokenId) external view  returns (address owner);
  function getDistricts(uint256 _id) external view returns (District memory);
}

interface IMansionHelper {
  function getClaimFee (address sender) external view returns (uint256);
}

contract DistrictHelper is Ownable {
  IERC20 public PLAYMATES;
  IMansionManager public MANSION;
  IDistrictManager public DISTRICT;

  bool enableClaims = false;

  uint256 public claimTime = 1;
  uint256 public reward = 16320 * 5;
  uint256 public precision = 1410065408;

  uint256 public releaseTime;

  mapping(uint256 => IDistrictManager.District) private _nodes;

  constructor(address _mansion, address _playmates, address _district)  {
      PLAYMATES = IERC20(_playmates);
      MANSION = IMansionManager(_mansion);
      DISTRICT = IDistrictManager(_district);
      releaseTime = block.timestamp;
  }

  modifier onlyIfExists(uint256 _id) {
    require(DISTRICT.ownerOf(_id) != address(0), "ERC721: operator query for nonexistent token");
    _;
  }

  function claim(address account, uint256 _id) external onlyIfExists(_id) returns (uint) {
    require(enableClaims, "MANAGER: Claims are disabled");
    require(DISTRICT.ownerOf(_id) == account, "MANAGER: You are not the owner");
    IDistrictManager.District memory _node = DISTRICT.getDistricts(_id);
    if(_nodes[_id].id == _node.id) {
        _node = _nodes[_id];
    } 
    if (_node.claim < releaseTime) _node.claim = uint64(releaseTime);
    uint interval = (block.timestamp - _node.claim) / claimTime;
    require(interval > 1, "MANAGER: Not enough time has passed between claims");
    uint rewardNode = (interval * reward * 10 ** 18) / precision;
    require(rewardNode > 1, "MANAGER: You don't have enough reward");
    uint userMultiplier = MANSION.getUserMultiplier(account);
    _node.claim = uint64(block.timestamp);
    _nodes[_id] = _node;
    if(rewardNode > 0 && userMultiplier > 0 ) {
        rewardNode = rewardNode + (rewardNode * userMultiplier / 1000);
        return rewardNode;
    }
    if(rewardNode > 0) {
        return rewardNode;
    } else {
        return 0;
    }
  }

  function seeNode(uint256 _id) external view returns (string memory) {
      return _nodes[_id].name;
  }

  function seeNode2(uint256 _id) external view returns (uint256) {
      return _nodes[_id].claim;
  }

  function _changeEnableClaims(bool _newVal) onlyOwner external {
      enableClaims = _newVal;
  }

  function _changeRewards(uint64 newReward, uint64 newTime, uint32 newPrecision) onlyOwner external {
      reward = newReward;
      claimTime = newTime;
      precision = newPrecision;
  }

  function _changePlaymates(address _playmates) onlyOwner external {
      PLAYMATES = IERC20(_playmates);
  }

  function _changeMansions(address _mansion) onlyOwner external {
      MANSION = IMansionManager(_mansion);
  }

  function _changeDistricts(address _district) onlyOwner external {
      DISTRICT = IDistrictManager(_district);
  }
}