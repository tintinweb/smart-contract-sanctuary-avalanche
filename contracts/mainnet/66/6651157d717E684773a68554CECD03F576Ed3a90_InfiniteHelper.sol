/**
 *Submitted for verification at snowtrace.io on 2022-03-09
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: InfiniteHelper.sol



pragma solidity ^0.8.0;





interface IAscendMembershipManager {
  function getUserMultiplier(address from) external view returns (uint256);
}

interface IInfiniteManager {
  struct Infinite {
      string name;
      string metadata;
      uint256 id;
      uint64 mint;
      uint64 claim;
  }
  function ownerOf(uint256 tokenId) external view  returns (address owner);
  function getInfinites(uint256 _id) external view returns (Infinite memory);
  function getInfinitesOf(address _account) external view returns (uint256[] memory);
}

contract InfiniteHelper is Ownable {

  bool enableClaims = false; //upgradeable

  uint256 public claimTime = 86400; //upgradeable
  uint256 public reward = 190000; //upgradeable
  uint256 public precision = 1000; //upgradeable
  uint256 public metaMultiplier = 0; //upgradeable 10%

  uint256 public founderL1Booster = 19000; //upgradeable 10%
  uint256 public founderL2Booster = 28500; //upgradeable 15%
  uint256 public founderL3Booster = 38000; //upgradeable 20%
  uint256 public presaleBooster = 28500; //upgradeable 15%

  IERC721 public presaleNFT;
  IERC721 public founderL1NFT;
  IERC721 public founderL2NFT;
  IERC721 public founderL3NFT;

  IERC20 public ASCEND;
  IAscendMembershipManager public ASCEND_MEMBERSHIP;
  IInfiniteManager public INFINITE;
  IERC721 public meta_membership;

  mapping(uint256 => IInfiniteManager.Infinite) private _nodes;

  constructor( address _ASCEND_TOKEN, address _ascendMembership, address _infinite)  {
      ASCEND = IERC20(_ASCEND_TOKEN);
      ASCEND_MEMBERSHIP = IAscendMembershipManager(_ascendMembership);
      INFINITE = IInfiniteManager(_infinite);
  }

  function setMultipliers(uint256 _metaMultiplier) onlyOwner external {
    metaMultiplier = _metaMultiplier;
  }

  modifier onlyIfExists(uint256 _id) {
    require(INFINITE.ownerOf(_id) != address(0), "ERC721: operator query for nonexistent token");
    _;
  }

  function setBoosters(uint256 _founderL1Booster, uint256 _founderL2Booster,
    uint256 _founderL3Booster, uint256 _presaleBooster) onlyOwner external {
    founderL1Booster = _founderL1Booster;
    founderL2Booster = _founderL2Booster;
    founderL3Booster = _founderL3Booster;
    presaleBooster =  _presaleBooster;
  }

  function setNFTBoosters(address _presaleNFT, address _founderL1NFT,
    address _founderL2NFT, address _founderL3NFT ) external onlyOwner {
       presaleNFT = IERC721(_presaleNFT);
       founderL1NFT = IERC721(_founderL1NFT);
       founderL2NFT = IERC721(_founderL2NFT);
       founderL3NFT = IERC721(_founderL3NFT);
  }

  function getUserBooster(address from) public view returns (uint256) {
      uint256 booster = 0;
      if(presaleNFT.balanceOf(from) >= 1){
        booster += presaleBooster;
      }
      if (founderL3NFT.balanceOf(from) >= 1){
        booster += founderL3Booster;
      } else if (founderL2NFT.balanceOf(from) >= 1){
        booster += founderL2Booster;
      } else if (founderL1NFT.balanceOf(from) >= 1){
        booster += founderL1Booster;
      }
      return booster;
  }

  function getUserAdditionalRewardsInfinite(address from) public view returns (uint256) {
    if(meta_membership.balanceOf(from) >= 1){
      return metaMultiplier;
    }
    return 0;
  }


    function getAddressRewards(address account) external view returns (uint) {
        uint256 rewardAmount = 0;
        uint256[] memory userMemberships = INFINITE.getInfinitesOf(account);
        uint interval = 0;
        for (uint256 i = 0; i < userMemberships.length; i++) { 
            IInfiniteManager.Infinite memory _node = INFINITE.getInfinites(userMemberships[i]);
            interval = (block.timestamp - _nodes[_node.id].claim) / claimTime;
            rewardAmount +=  (interval * getReward(account) * 10 ** 18) / precision;
        }
        return rewardAmount;
    }

    function getReward(address from) public view returns(uint256) {
        uint rewardNode = reward + getUserAdditionalRewardsInfinite(from) + getUserBooster(from);
        return rewardNode;
    }


  function claim(address account, uint256 _id) external onlyIfExists(_id) returns (uint) {
    require(enableClaims, "MANAGER: Claims are disabled");
    require(INFINITE.ownerOf(_id) == account, "MANAGER: You are not the owner");
    IInfiniteManager.Infinite memory _node = INFINITE.getInfinites(_id);
    if(_nodes[_id].mint == _node.mint) {
        _node = _nodes[_id];
    }
    uint interval = (block.timestamp - _node.claim) / claimTime;
    require(interval >= 1, "MANAGER: Not enough time has passed between claims");
    uint rewardNode = (interval * getReward(account) * 10 ** 18) / precision;
    require(rewardNode >= 1, "MANAGER: You don't have enough reward");
    _node.claim = uint64(block.timestamp);
    _nodes[_id] = _node;
    if(rewardNode > 0) {
         _node.claim = uint64(block.timestamp);
        return rewardNode;
    } else {
        return 0;
    }
  }



  function seeNode(uint256 _id) external view returns (string memory) {
      return _nodes[_id].name;
  }

  function seeNodeClaim(uint256 _id) external view returns (uint256) {
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

  function setASCEND(address _ASCEND) onlyOwner external {
      ASCEND = IERC20(_ASCEND);
  }

  function setMetaMemberships(address _meta) onlyOwner external {
      meta_membership = IERC721(_meta);
  }

  function setAscendMemberships(address _ascendMembership) onlyOwner external {
      ASCEND_MEMBERSHIP = IAscendMembershipManager(_ascendMembership);
  }

  function setInfinite(address _infinite) onlyOwner external {
      INFINITE = IInfiniteManager(_infinite);
  }
}