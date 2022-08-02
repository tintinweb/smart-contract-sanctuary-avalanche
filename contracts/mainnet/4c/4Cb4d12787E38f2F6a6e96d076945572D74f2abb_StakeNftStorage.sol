/**
 *Submitted for verification at snowtrace.io on 2022-08-02
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: contracts/NftStakingWithStorage.sol



pragma solidity ^0.8.11;



interface NftInterface {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function balanceOf(address owner) external view returns (uint256 balance);
  function totalSupply() external view returns (uint256);
}

interface UserStorage {
  function getLastClaimed(uint256 _tokenId) external view returns (uint256);
  function setLastClaimed(uint256 _tokenId, uint256 _lastClaimed) external;
  function setRewardsClaimed(uint256 _tokenId, uint256 _rewardsClaimed) external;
  function allowAccess(address _address) external;
  function denyAccess(address _address) external;
  function transferRewardsClaimed(address _to, uint256 _rewardIn6) external;
}

/**
 * @title NftStakingWithStorage
 * @notice Contract used for claiming staking rewards with nft
 */
contract StakeNftStorage is Ownable, ReentrancyGuard {
  
  /// @notice rewards emission per second
  uint256 public rewardPerSecond;

  /// @notice startBlockTimestamp for rewards emission
  uint256 public startBlockTimestamp;

  /// @notice used to check the balance for Nft of the devAddress for rewards calculations
  address public devAddress;

  /// @notice sets the sale contract for only sale modifier
  address public saleContract;
  bool public saleContractSet;

  /// @notice interface for the Nft being used
  NftInterface public nftInterface;

  /// @notice sets the user storage contract
  UserStorage public userStorage;

  event RewardPerSecondSet(uint256 indexed _rewardPerSecond);
  event DevAddressSet(address indexed _devAddress);
  event ContractUpgraded(address indexed _address);
  event ReserveNftTransferred(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenID
  );
  event RewardsClaimed(
    uint256 indexed _tokenId,
    address indexed _owner,
    uint256 indexed _rewardIn6
  );

  /// @notice modifier to ensure that only the sale contract can call the method
  modifier onlySale {
    require(saleContractSet, "STAKING:Sale contract address has not been set");
    require(msg.sender == saleContract, "STAKING:Sender isn't the sale contract");
    _;
  }

  /// @notice for contract pause state
  bool public paused;

  /// @notice pause state modifier
  modifier whenNotPaused {
    require(!paused, "STAKE:Contract state is paused.");
    _;
  }

  /// @notice Contructor to set some values for the contract
  /// @param _rewardPerSecond sets the reward emission per second
  /// @param _startBlockTimestamp sets the start block for rewards claiming
  /// @param _nftAddress sets the nft address for nft being used
  /// @param _userStorage sets the user storage address for the staking
  constructor(
    uint256 _rewardPerSecond,
    uint256 _startBlockTimestamp,
    address _nftAddress,
    address _userStorage
  ) {
    rewardPerSecond = _rewardPerSecond;
    startBlockTimestamp = _startBlockTimestamp;
    if (block.timestamp > _startBlockTimestamp) {
      startBlockTimestamp = block.timestamp;
    }
    nftInterface = NftInterface(_nftAddress);
    userStorage = UserStorage(_userStorage);
    devAddress = msg.sender;
  }

  /// @notice pause contract state
  /// @param _state false for unpaused, true for paused
  function setContractState(bool _state) external onlyOwner {
    paused = _state;
  }

  /// @notice sets the NFT address for staking
  function setNftAddress(address _nftAddress) external onlyOwner {
    nftInterface = NftInterface(_nftAddress);
  }

  /// @notice sets the user storage address
  function setUserStorageAddress(address _storageAddress) external onlyOwner {
    userStorage = UserStorage(_storageAddress);
  } 

  /// @notice set the sale contract address
  function setSaleContract(address _saleContract) external onlyOwner {
    saleContract = address(_saleContract);
    saleContractSet = true;
  }

  /// @notice set the dev address
  function setDevAddress(address _devAddress) external onlyOwner {
    devAddress = _devAddress;
    emit DevAddressSet(_devAddress);
  }

  /// @notice sets rewardPerSecond
  function setRewardPerSecond(uint256 _rewardPerSecond) external onlyOwner {
    rewardPerSecond = _rewardPerSecond;
    emit RewardPerSecondSet(_rewardPerSecond);
  }

  /// @notice sets startBlockTimestamp for the claims
  function setStartBlockTimestamp(uint256 _startBlockTimestamp) external onlyOwner {
    startBlockTimestamp = _startBlockTimestamp;
  }

  /// @notice sets the last claimed from the user storage
  /// @param _tokenId tokenId to set last claimed from the sale address
  function setLastClaimed(uint256 _tokenId) external onlySale whenNotPaused returns (bool){
    userStorage.setLastClaimed(_tokenId, block.timestamp);
    return true;
  }

  /// @notice resets the last claimed for a particular nft to the current block.timestamp
  /// @param _tokenId takes an array of tokenId to have their rewards resetted
  function resetReward(uint256[] memory _tokenId) whenNotPaused external {
    require(ownsNft(_tokenId) == true, "STAKING:The caller does not own the nft");
    for (uint256 i = 0; i < _tokenId.length; i++) {
      userStorage.setLastClaimed(_tokenId[i], block.timestamp);
    }
  }

  /// @notice gets the reward balance for an array of tokenIds
  /// @param _tokenId takes an array of tokenIds to be checked
  function rewardBalance(uint256[] memory _tokenId) public view returns (uint256) {
    uint256 totalRewards = 0;

    for(uint256 i = 0; i < _tokenId.length; ++i){
      uint256 multiplier = 0;
      uint256 lastClaimed = userStorage.getLastClaimed(_tokenId[i]);

      if (lastClaimed <= 0) {
        multiplier = getMultiplier(startBlockTimestamp, block.timestamp);
      } else {
        multiplier = getMultiplier(lastClaimed, block.timestamp);
      }

      uint256 rewardsDividedIn18 = (rewardPerSecond * (10**(18 - 6))) /
        nftInterface.totalSupply() -
        nftInterface.balanceOf(devAddress);

      uint256 reward = multiplier * rewardsDividedIn18;
      uint256 rewardIn6 = reward / (10**(18 - 6));
      totalRewards += rewardIn6;
    }
    return totalRewards;
  }

  /// @notice user claims reward based on an array of tokenId passed based on which is owned
  /// @param _tokenId takes an array of tokenIds to be claimed
  function claimRewards(uint256[] memory _tokenId) external nonReentrant whenNotPaused returns (uint256) {
    require(ownsNft(_tokenId) == true, "STAKING:The caller does not own the nft");
    uint256 totalRewards = 0;

    for (uint256 i = 0; i < _tokenId.length; i++) {
      uint256 multiplier = 0;
      uint256 lastClaimed = userStorage.getLastClaimed(_tokenId[i]);

      if (lastClaimed <= 0) {
          multiplier = getMultiplier(startBlockTimestamp, block.timestamp);
      } else {
          multiplier = getMultiplier(lastClaimed, block.timestamp);
      }

      uint256 rewardsDividedIn18 = (rewardPerSecond * (10**(18 - 6))) /
          nftInterface.totalSupply() -
          nftInterface.balanceOf(devAddress);
      uint256 reward = multiplier * rewardsDividedIn18;
      uint256 rewardIn6 = reward / (10**(18 - 6));
      totalRewards += rewardIn6;

      userStorage.setLastClaimed(_tokenId[i], block.timestamp);
      userStorage.setRewardsClaimed(_tokenId[i], rewardIn6);
      userStorage.transferRewardsClaimed(msg.sender, rewardIn6);
      emit RewardsClaimed(_tokenId[i], msg.sender, rewardIn6);
    }
    return totalRewards;
  }

  /// @notice gets the multiplier based on the timestamp
  /// @param _to current block timestamp
  /// @param _from last reward timestamp
  function getMultiplier(uint256 _from, uint256 _to)
    internal
    view
    returns (uint256)
  {
    if (_from < startBlockTimestamp) {
      _from = startBlockTimestamp;
    }

    if (_to >= _from) {
      return _to - _from;
    } else {
      return 0;
    }
  }

  /// @notice checks if the user owns the specific nfts
  /// @param _tokenId inputs an array of tokenId to be checked to ensure that it is owned by msg.sender
  function ownsNft(uint256[] memory _tokenId) internal view returns (bool) {
    uint256 balance = nftInterface.balanceOf(msg.sender);
    if (balance < 1) {
      return false;
    }
    for (uint256 i = 0; i < _tokenId.length; i++) {
      address nftOwner = nftInterface.ownerOf(_tokenId[i]);
      
      if (msg.sender != nftOwner) {
        return false;
      }
    }
    return true;
  }

  /// @notice upgrades contract for where address is pointing, only for owner
  /// @param _address new address for the user storage
  function upgradeContract(address _address) public onlyOwner whenNotPaused {
    userStorage.allowAccess(_address);
    userStorage.denyAccess(address(this));
    emit ContractUpgraded(_address);
  }
}