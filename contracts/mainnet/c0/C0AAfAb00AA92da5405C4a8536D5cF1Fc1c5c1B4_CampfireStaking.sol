// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CampfireStaking is Ownable, ReentrancyGuard {
  uint256 private _totalNftsStaked;
  uint256 private _totalBlockEntries;

  address private _wavaxAddress;
  address private _keeperAddress;
  uint256 private _maxStake;

  mapping (address => uint256) private _totalNftsStakedForAccount;
  mapping (address => bool) private _partners;
  mapping (address => bool) private _managers;
  mapping (address => uint256) private _blockEntries;

  mapping (address => mapping (uint256 => bool)) _staked;
  mapping (address => mapping (uint256 => address)) private _stakers;
  // mapping (address => StakedNFT[]) private _stakedNFTs;

  mapping (address => mapping (address => bool)) private _approvals;

  mapping (bytes32 => StakedNFT) private _stakedNFTs;
  mapping (address => bytes32[]) private _stakedNFTHashes;


  struct StakedNFT {
    address contractAddress;
    uint256 tokenId;
  }

  constructor() {
    _managers[msg.sender] = true;
    _maxStake = 250;
  }

  modifier onlyManager() {
    require(_managers[msg.sender], "Campfire Staking: Caller is not the manager");
    _;
  }

  function addManager(address _newManager) public onlyManager {
    _managers[_newManager] = true;
  }

  function removeManager(address _manager) public onlyManager {
    _managers[_manager] = false;
  }

  function addPartner(address _contractAddress) public onlyManager {
    _partners[_contractAddress] = true;
  }

  function isPartner(address _contractAddress) public view returns (bool) {
    if (_contractAddress == 0x5e4504663AB2a8060715A1D1f162873F39DF9abf) { // OUTLAWS
      return true;
    } else {
      return _partners[_contractAddress];
    }
  }

  function stakeSet(address _contractAddress, uint256[] memory _tokenIds) public nonReentrant {
    require(_tokenIds.length <= 15, "Campfire Staking: You can't stake more than 15 at a time.");
    // IMPORTANT: Rely on real value here, not cached!
    uint256 accountNftsStaked = getNumberStaked(msg.sender);
    for (uint256 index = 0; index < _tokenIds.length; index++) {
      uint256 _tokenId = _tokenIds[index];
      _stake(_contractAddress, _tokenId, (accountNftsStaked + index));
    }
  }

  function stake(address _contractAddress, uint256 _tokenId) public nonReentrant {
    // IMPORTANT: Rely on real value here, not cached!
    uint256 accountNftsStaked = getNumberStaked(msg.sender);
    _stake(_contractAddress, _tokenId, accountNftsStaked);
  }

  function _stake(address _contractAddress, uint256 _tokenId, uint256 accountNftsStaked) private {
    require(isPartner(_contractAddress), "Campfire Staking: This project is not a parter.");

    IERC721 nft = IERC721(_contractAddress);
    require(nft.ownerOf(_tokenId) == msg.sender, "Campfire Staking: You don't own that NFT.");

    if (isStaked(_contractAddress, _tokenId)) {
      if (_stakers[_contractAddress][_tokenId] == msg.sender) {
        require(false, "Campfire Staking: You cannot stake an NFT more than once.");
      } else {
        address originalOwner = _stakers[_contractAddress][_tokenId];
        uint256 currentForOriginal = getNumberStaked(originalOwner);

        resetTotalsFor(originalOwner, currentForOriginal);

        _stakers[_contractAddress][_tokenId] = msg.sender;
      }
    }
    
    if (_totalNftsStakedForAccount[msg.sender] > 0 && block.number < _blockEntries[msg.sender]) {
      if (_totalNftsStakedForAccount[msg.sender] > accountNftsStaked) {
        resetTotalsFor(msg.sender, accountNftsStaked);
      }

      uint256 avaxRewards = _availableAVAXRewards(msg.sender, accountNftsStaked);
      uint256 wavaxRewards = _availableWAVAXRewards(msg.sender, accountNftsStaked);

      _totalBlockEntries -= _blockEntries[msg.sender] * _totalNftsStakedForAccount[msg.sender];

      if (wavaxRewards > 0) {
        IERC20 wavax = IERC20(_wavaxAddress);
        wavax.transfer(msg.sender, wavaxRewards);
      }
      if (avaxRewards > 0) {
        payable(msg.sender).transfer(avaxRewards);
      }
    } else if (_totalNftsStakedForAccount[msg.sender] > 0) {
      _totalBlockEntries -= _blockEntries[msg.sender] * _totalNftsStakedForAccount[msg.sender];
    }

    _totalNftsStaked += 1;
    _totalNftsStakedForAccount[msg.sender] += 1;

    _blockEntries[msg.sender] = block.number;
    _totalBlockEntries += block.number * _totalNftsStakedForAccount[msg.sender];

    bytes32 nftHash = keccak256(abi.encodePacked(msg.sender, _contractAddress, _tokenId));

    _stakedNFTs[nftHash] = StakedNFT(_contractAddress, _tokenId);
    _stakedNFTHashes[msg.sender].push(nftHash);

    _stakers[_contractAddress][_tokenId] = msg.sender;

    require(_totalNftsStakedForAccount[msg.sender] <= _maxStake, "Campfire Staking: You have hit the max staked limit.");

    _staked[_contractAddress][_tokenId] = true;
  }

  function isStaked(address _contractAddress, uint256 _tokenId) public view returns (bool) {
    return _staked[_contractAddress][_tokenId];
  }

  function totalStaked() public view returns (uint256) {
    return _totalNftsStaked;
  }

  function totalStakedFor(address staker) public view returns (uint256) {
    return _totalNftsStakedForAccount[staker];
  }
  
  function totalBlockEntries() public view returns (uint256) {
    return _totalBlockEntries;
  }

  function blockEntriesFor(address staker) public view returns (uint256) {
    return _blockEntries[staker];
  }

  function unstake(address _contractAddress, uint256 _tokenId) public nonReentrant {
    IERC721 nft = IERC721(_contractAddress);

    address nftOwner = nft.ownerOf(_tokenId);
    require(msg.sender == nftOwner, "Campfire Staking: You don't own that NFT.");
    require(isStaked(_contractAddress, _tokenId), "Campfire Staking: That NFT is not currently staked.");

    // IMPORTANT: Rely on real value here, not cached!
    uint256 accountNftsStaked = getNumberStaked(msg.sender);

    if (_totalNftsStakedForAccount[msg.sender] > accountNftsStaked) {
      resetTotalsFor(msg.sender, accountNftsStaked);
    }

    uint256 avaxRewards = _availableAVAXRewards(msg.sender, accountNftsStaked);
    uint256 wavaxRewards = _availableWAVAXRewards(msg.sender, accountNftsStaked);

    _totalBlockEntries -= _blockEntries[msg.sender] * _totalNftsStakedForAccount[msg.sender];
    
    _totalNftsStaked -= 1;
    _totalNftsStakedForAccount[msg.sender] -= 1;
    
    _blockEntries[msg.sender] = block.number;
    _totalBlockEntries += block.number * _totalNftsStakedForAccount[msg.sender];

    _staked[_contractAddress][_tokenId] = false;

    IERC20 wavax = IERC20(_wavaxAddress);

    if (wavaxRewards > 0) {
      wavax.transfer(msg.sender, wavaxRewards);
    }
    if (avaxRewards > 0) {
      payable(msg.sender).transfer(avaxRewards);
    }
  }

  function unclaimedBlocks() public view returns (uint256) {
    uint256 totalUnclaimedBlocks = (block.number * _totalNftsStaked) - _totalBlockEntries;
    return totalUnclaimedBlocks;
  }

  function claim() public nonReentrant {
    _claim(msg.sender);
  }

  function claimFor(address account) public {
    require(msg.sender == _keeperAddress || _approvals[account][msg.sender], "Campfire Staking: You don't have permission to do that.");

    _claim(account);
  }

  function _claim(address account) private {
    require(_totalNftsStakedForAccount[account] > 0, "Campfire Staking: You are not staked.");

    // IMPORTANT: Rely on real value here, not cached!
    uint256 accountNftsStaked = getNumberStaked(account);

    if (_totalNftsStakedForAccount[account] > accountNftsStaked) {
      resetTotalsFor(account, accountNftsStaked);
    }

    uint256 avaxRewards = _availableAVAXRewards(account, accountNftsStaked);
    uint256 wavaxRewards = _availableWAVAXRewards(account, accountNftsStaked);

    _totalBlockEntries -= _blockEntries[account] * _totalNftsStakedForAccount[account];

    _blockEntries[account] = block.number;
    _totalBlockEntries += block.number * _totalNftsStakedForAccount[account];

    IERC20 wavax = IERC20(_wavaxAddress);

    if (wavaxRewards > 0) {
      wavax.transfer(account, wavaxRewards);
    }
    if (avaxRewards > 0) {
      payable(account).transfer(avaxRewards);
    }
  }

  function resetTotalsFor(address account, uint256 accountNftsStaked) private {
    _totalBlockEntries -= (_blockEntries[account] * _totalNftsStakedForAccount[account]);
    _totalNftsStaked -= _totalNftsStakedForAccount[account];
    _totalNftsStakedForAccount[account] = accountNftsStaked;
    _totalBlockEntries += (_blockEntries[account] * _totalNftsStakedForAccount[account]);
    _totalNftsStaked += _totalNftsStakedForAccount[account];
  }

  // NOTE: The next two methods are convenience methods for the UI --> not to be used internally
  function availableAVAXRewards(address account) public view returns (uint256) {
    uint256 accountNftsStaked = getNumberStaked(account);
    uint256 available = address(this).balance;
    return _rewardsCalc(account, available, accountNftsStaked);
  }

  function availableWAVAXRewards(address account) public view returns (uint256) {
    uint256 accountNftsStaked = getNumberStaked(account);
    IERC20 wavax = IERC20(_wavaxAddress);
    uint256 available = wavax.balanceOf(address(this));
    return _rewardsCalc(account, available, accountNftsStaked);
  }

  function _availableAVAXRewards(address account, uint256 accountNftsStaked) private view returns (uint256) {
    uint256 available = address(this).balance;
    return _rewardsCalc(account, available, accountNftsStaked);
  }

  function _availableWAVAXRewards(address account, uint256 accountNftsStaked) private view returns (uint256) {
    IERC20 wavax = IERC20(_wavaxAddress);
    uint256 available = wavax.balanceOf(address(this));
    return _rewardsCalc(account, available, accountNftsStaked);
  }


  function _rewardsCalc(address account, uint256 available, uint256 accountNftsStaked) private view returns (uint256) {
      uint256 totalUnclaimedBlocks = (block.number * _totalNftsStaked) - _totalBlockEntries;

     if (totalUnclaimedBlocks > 0) {
      uint256 accountUnclaimedBlocks = (block.number * accountNftsStaked) - (_blockEntries[account] * accountNftsStaked);
      uint256 reward = (available * accountUnclaimedBlocks) / totalUnclaimedBlocks;
      return reward;
    } else {
      return 0;
    }
  }

  function getNumberStaked(address staker) public view returns (uint256) {
    uint256 numberStaked = 0;
    for (uint256 index = 0; index < _stakedNFTHashes[staker].length; index++) {
      bytes32 nftHash = _stakedNFTHashes[staker][index];
      StakedNFT memory stakedNFT = _stakedNFTs[nftHash];

      if (isStaked(stakedNFT.contractAddress, stakedNFT.tokenId)) {
        IERC721 nft = IERC721(stakedNFT.contractAddress);
        if (nft.ownerOf(stakedNFT.tokenId) == staker) {
          numberStaked += 1;
        }
      }
    }
    return numberStaked;
  }

  function setWAVAX(address wavaxAddress_) public onlyOwner {
    _wavaxAddress = wavaxAddress_;
  }

  function setKeeper(address keeperAddress_) public onlyOwner {
    _keeperAddress = keeperAddress_;
  }

  function setMaxStake(uint256 maxStake_) public onlyOwner {
    _maxStake = maxStake_;
  }

  function approve(address manager, bool approved) public {
    _approvals[msg.sender][manager] = approved;
  }

  receive() external payable {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
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