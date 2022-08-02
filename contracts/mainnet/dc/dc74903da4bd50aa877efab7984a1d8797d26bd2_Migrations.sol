/**
 *Submitted for verification at snowtrace.io on 2022-08-02
*/

// File: contracts/interfaces/IUBlood.sol



pragma solidity 0.8.13;

interface IUBlood {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
}
// File: contracts/interfaces/IUGNFTs.sol


pragma solidity 0.8.13;

interface IUGNFTs {
 
    struct FighterYakuza {
        bool isFighter;
        uint8 Gen;
        uint8 level;
        uint8 rank;
        uint8 courage;
        uint8 cunning;
        uint8 brutality;
        uint8 knuckles;
        uint8 chains;
        uint8 butterfly;
        uint8 machete;
        uint8 katana;
        uint16 scars;
        uint16 imageId;
        uint32 lastLevelUpgradeTime;
        uint32 lastRankUpgradeTime;
        uint32 lastRaidTime;
    }  
    //weapons scores used to identify "metal"
    // steel = 10, bronze = 20, gold = 30, platinum = 50 , titanium = 80, diamond = 100
    struct RaidStats {
        uint8 knuckles;
        uint8 chains;
        uint8 butterfly;
        uint8 machete;
        uint8 katana;
        uint16 scars;
        uint32 fighterId;
    }

    struct ForgeFightClub {
        uint8 size;
        uint8 level;
        uint16 id;
        uint32 lastLevelUpgradeTime;
        uint32 lastUnstakeTime;
        address owner;
    }

    struct RingAmulet {
        uint8 level;
        uint32 lastLevelUpgradeTime;
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    function getPackedFighters(uint256[] calldata tokenIds) external view returns (uint256[] memory);
    function setBaseURI(string calldata uri) external;//onlyOwner
    function tokenURIs(uint256[] calldata tokenId) external view returns (string[] memory) ;
    function mintRingAmulet(address, uint256, bool ) external;//onlyAdmin  
    function mintFightClubForge(address _to, bytes memory _data, uint256 _size, uint256 _level, bool isFightClub) external;//onlyAdmin
    function batchMigrateFYakuza(address _to, uint256[] calldata v1TokenIds, FighterYakuza[] calldata oldFighters) external;//onlyAdmin 
    function checkUserBatchBalance(address user, uint256[] calldata tokenIds) external view returns (bool);
    function getNftIDsForUser(address , uint) external view returns (uint256[] memory);
    function getRingAmulet(uint256 ) external view returns (RingAmulet memory);
    function getFighter(uint256 tokenId) external view returns (FighterYakuza memory);
    function getFighters(uint256[] calldata) external view returns (FighterYakuza[] memory);
    function getForgeFightClub(uint256 tokenId) external view returns (ForgeFightClub memory);
    function getForgeFightClubs(uint256[] calldata tokenIds) external view returns (ForgeFightClub[] memory); 
    function levelUpFighters(uint256[] calldata, uint256[] calldata) external; // onlyAdmin
    function levelUpRingAmulets(uint256, uint256 ) external;
    function levelUpFightClubsForges(uint256[] calldata tokenIds, uint256[] calldata newSizes, uint256[] calldata newLevels) external returns (ForgeFightClub[] memory); // onlyAdmin
    function addAdmin(address) external; // onlyOwner 
    function removeAdmin(address) external; // onlyOwner
    function ttlFYakuzas() external view returns (uint256);
    function ttlFightClubs() external view returns (uint256);
    function ttlRings() external view returns (uint256);
    function ttlAmulets() external view returns (uint256);
    function ttlForges() external view returns (uint256);
    function setFightClubUnstakeTime (uint256 , bool) external;
    function setRaidTraitsFromPacked( uint256[] calldata raidStats) external;    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function setFighter( uint256 tokenId, FighterYakuza memory FY) external;
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/ERC1155/utils/Ownable.sol


pragma solidity ^0.8.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner_;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () {
    _owner_ = msg.sender;
    emit OwnershipTransferred(address(0), _owner_);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == _owner_, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  /**
   * @notice Transfers the ownership of the contract to new address
   * @param _newOwner Address of the new owner
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    emit OwnershipTransferred(_owner_, _newOwner);
    _owner_ = _newOwner;
  }

  /**
   * @notice Returns the address of the owner.
   */
  function owner() public view returns (address) {
    return _owner_;
  }
}
// File: contracts/UGMigration.sol


pragma solidity 0.8.13;







interface IUArena {

  struct Stake {
    uint256 tokenId;
    uint256 bloodPerRank;
    uint256 stakeTimestamp;
    address owner;
  }

  function getStake(uint256 tokenId) external view returns (Stake memory);
  }

  interface IUGame {
      function getFyTokenTraits(uint256 tokenId) external view returns (IUNFT.FighterYakuza memory);
  }


interface IUNFT is IERC721Enumerable {
    struct FighterYakuza {
        bool isRevealed;
        bool isFighter;
        bool isGen0;
        uint16 level;
        uint256 lastLevelUpgradeTime;
        uint8 rank;
        uint256 lastRankUpgradeTime;
        uint8 courage;
        uint8 cunning;
        uint8 brutality;
        uint64 mintedBlockNumber;
    }
    function burn(uint256 tokenId) external; // onlyAdmin
    function getTokenTraits(uint256 tokenId) external view returns (FighterYakuza memory); // onlyAdmin  
}

interface IURing is IERC721Enumerable {
    struct Ring {
        uint256 mintedTimestamp;
        uint256 mintedBlockNumber;
        uint256 lastTransferTimestamp;
    }
    function burn(uint256 tokenId) external; // onlyAdmin
    function getTokenTraits(uint256 tokenId) external view returns (Ring memory); // onlyAdmin
}

interface IUAmulet is IERC721Enumerable {
    struct Amulet {
        uint256 mintedTimestamp;
        uint256 mintedBlockNumber;
        uint256 lastTransferTimestamp;
    }    
    function burn(uint256 tokenId) external; // onlyAdmin
    function getTokenTraits(uint256 tokenId) external view returns (Amulet memory); // onlyAdmin
}


contract Migrations is ReentrancyGuard, Ownable, Pausable {

  uint256 constant FIGHTER = 100000;
  uint256 public mergePrice = 5000000;
  address private devWallet;
  

  /** CONTRACTS */
  IUNFT private uNft;
  IUGNFTs private ugNFT;
  IUBlood private uBlood;
  IURing private uRing;
  IUAmulet private uAmulet;
  IUArena private uArena;
  IUGame private uGame;

  constructor(
    address _ugNFT, 
    address _unft, 
    address _ublood, 
    address _uring, 
    address _uamulet,
    address _uArena,
    address _uGame
  ){
    ugNFT = IUGNFTs(_ugNFT);
    uBlood = IUBlood(_ublood);
    uRing = IURing(_uring);
    uAmulet = IUAmulet(_uamulet);
    uNft = IUNFT(_unft);
    uArena = IUArena(_uArena);
    uGame = IUGame(_uGame);
    //_pause();
  }

  error InvalidOwner();
  error InvalidAmount();
  error InvalidAccount();
  error NotEnough();

  //send in old fighter ids, maybe include gold stat upgrades here
  function migrateFighters(uint256[] calldata v1TokenIds) external nonReentrant whenNotPaused {
    //format v1Fighter to v2 format
    IUNFT.FighterYakuza memory _oldFighter;
    IUGNFTs.FighterYakuza[] memory v1Fighters = new IUGNFTs.FighterYakuza[](v1TokenIds.length);
    
    for(uint i = 0; i< v1TokenIds.length; i++){
      //verify ownership of oldfighter to msgSender
      if(uNft.ownerOf(v1TokenIds[i]) != _msgSender() && uArena.getStake(v1TokenIds[i]).owner != _msgSender()) revert InvalidOwner();
        _oldFighter = uGame.getFyTokenTraits(v1TokenIds[i]);
        v1Fighters[i].isFighter = _oldFighter.isFighter;
        //change gen0 from bool to uint which can only hold 0 or 1
        v1Fighters[i].Gen = _oldFighter.isGen0 ? 0: 1;
        v1Fighters[i].level = uint8(_oldFighter.level);
        v1Fighters[i].rank = _oldFighter.rank;
        v1Fighters[i].courage = _oldFighter.courage;
        v1Fighters[i].cunning = _oldFighter.cunning;
        v1Fighters[i].brutality = _oldFighter.brutality;
        v1Fighters[i].knuckles = 0;
        v1Fighters[i].chains = 0;
        v1Fighters[i].butterfly = 0;
        v1Fighters[i].machete = 0;
        v1Fighters[i].katana = 0;
        v1Fighters[i].scars = 0;
        v1Fighters[i].imageId = 0;
        v1Fighters[i].lastLevelUpgradeTime = 0;
        v1Fighters[i].lastRankUpgradeTime = 0;
        v1Fighters[i].lastRaidTime = 0;

        uNft.burn(v1TokenIds[i]);
    }
    
    ugNFT.batchMigrateFYakuza(_msgSender(), v1TokenIds, v1Fighters);
    
  }

   function mergeFighters(uint256 v1TokenId1, uint256 v1TokenId2) external whenNotPaused nonReentrant {
    //format v1Fighter to v2 format
    IUNFT.FighterYakuza memory _oldFighter1;
    IUNFT.FighterYakuza memory _oldFighter2;
    IUGNFTs.FighterYakuza[] memory v1Fighter = new IUGNFTs.FighterYakuza[](1);
    
      //verify ownership of oldfighter to msgSender
      if((uNft.ownerOf(v1TokenId1) != _msgSender() && uArena.getStake(v1TokenId1).owner != _msgSender()) ||
         (uNft.ownerOf(v1TokenId2) != _msgSender() && uArena.getStake(v1TokenId2).owner != _msgSender())) revert InvalidOwner();
        _oldFighter1 = uGame.getFyTokenTraits(v1TokenId1);
        _oldFighter2 = uGame.getFyTokenTraits(v1TokenId2);
        v1Fighter[0].isFighter = true;
        //change gen0 from bool to uint which can only hold 0 or 1
        v1Fighter[0].Gen = 0;
        v1Fighter[0].level = 1;
        v1Fighter[0].rank = 0;
        v1Fighter[0].courage = _oldFighter1.courage > _oldFighter2.courage ? _oldFighter1.courage : _oldFighter2.courage;
        v1Fighter[0].cunning = _oldFighter1.cunning > _oldFighter2.cunning ? _oldFighter1.cunning : _oldFighter2.cunning;
        v1Fighter[0].brutality = _oldFighter1.brutality > _oldFighter2.brutality ? _oldFighter1.brutality : _oldFighter2.brutality;
        v1Fighter[0].knuckles = 0;
        v1Fighter[0].chains = 0;
        v1Fighter[0].butterfly = 0;
        v1Fighter[0].machete = 0;
        v1Fighter[0].katana = 0;
        v1Fighter[0].scars = 0;
        v1Fighter[0].imageId = uint16(v1TokenId1);
        v1Fighter[0].lastLevelUpgradeTime = 0;
        v1Fighter[0].lastRankUpgradeTime = 0;
        v1Fighter[0].lastRaidTime = 0;

        burnBlood(_msgSender(), mergePrice);
        uNft.burn(v1TokenId1);
        uNft.burn(v1TokenId2);

        uint256[] memory _ids = new uint256[](1);
        _ids[0] = v1TokenId1;
    
    
    ugNFT.batchMigrateFYakuza(_msgSender(), _ids, v1Fighter);
    
  }

  function migrateRingAmulet(uint256[] calldata tokenIds, bool isRing) public whenNotPaused {
    if(tokenIds.length < 10) revert NotEnough();
    //conversion from v1 rings to v2 rings
    uint256 level = tokenIds.length/10;
    uint256 v1RingsToBurn = level*10;
    
    for(uint i; i<v1RingsToBurn; i++){
      if(isRing){      
        if(uRing.ownerOf(tokenIds[i]) != _msgSender()) revert InvalidOwner();   
        uRing.burn(tokenIds[i]); 
      } else {// if amulet     
        if(uAmulet.ownerOf(tokenIds[i]) != _msgSender()) revert InvalidOwner();
        uAmulet.burn(tokenIds[i]);
      }    
    }
     
    ugNFT.mintRingAmulet(_msgSender(), level, isRing );
  }  

  function setMergePrice(uint256 amount) external onlyOwner {
    mergePrice = amount;
  }

  function burnBlood(address account, uint256 amount) private {
    if(account == address(0x00)) revert InvalidAccount();
    if(amount == 0) revert InvalidAmount();
        uBlood.burn(account , amount * 1 ether);
        uBlood.mint(devWallet, amount * 1 ether /10);
    }

  function setDevWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0x00), "Must not be 0 address");
        devWallet = newWallet;
    }
  
}