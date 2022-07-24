/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-23
*/

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

// File: contracts/interfaces/IRandomizer.sol



pragma solidity ^0.8.0;
interface IRandomizer{
    function getSeeds(uint256, uint256, uint256) external view returns (uint256[] memory);
}

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
}
// File: contracts/interfaces/IUGArena.sol


pragma solidity 0.8.13;


interface IUGArena {

    struct Stake {
        uint32 tokenId;
        uint32 bloodPerRank;
        uint32 stakeTimestamp;
        address owner;
    }

    function numUserStakedFighters(address user) external view returns (uint256);
    function getStakeOwner(uint256 tokenId) external view returns (address);
    function verifyAllStakedByUser(address, uint256[] calldata) external view returns (bool);
    function getAmuletRingInfo(address user) external view returns(uint256, uint256, uint256);

    function stakeRing(uint256 tokenId) external;
    function stakeAmulet(uint256 tokenId) external;
    function unstakeRing(uint256 tokenId) external;
    function unstakeAmulet(uint256 tokenId) external;

    function stakeManyToArena(uint256[] calldata ) external ;
    function claimManyFromArena(uint256[] calldata , bool ) external;
    function calculateStakingRewards(uint256 tokenId) external view returns (uint256 owed);
    function calculateAllStakingRewards(uint256[] memory tokenIds) external view returns (uint256 owed);
    function getStakedYakuzaIDsForUser(address user) external view returns (uint256[] memory);
    function getStakedFighterIDsForUser(address user) external view returns (uint256[] memory);
    function getStakedRingIDForUser(address user) external view returns (uint256);
    function getStakedAmuletIDForUser(address user) external view returns (uint256);
    
    function addAdmin(address) external; // onlyOwner 
    function removeAdmin(address) external; // onlyOwner
    function payRaidRevenueToYakuza(uint256 amount) external; //onlyAdmin
    function getOwnerLastClaimAllTime(address user) external view returns (uint256);
    function setOwnerLastClaimAllTime(address user) external;
    function getBloodPerRank() external view returns (uint256);
    function getUnaccountedYakRewards() external view returns (uint256);
    
}

// File: contracts/ERC1155/interfaces/IERC165.sol


pragma solidity ^0.8.0;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// File: contracts/ERC1155/interfaces/IERC1155.sol


pragma solidity ^0.8.0;



interface IERC1155 is IERC165 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
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
// File: contracts/UGArena.sol



pragma solidity 0.8.13;










contract UGArena is IUGArena, Ownable, ReentrancyGuard, Pausable {

  /** CONTRACTS */
  IRandomizer public randomizer;
  IUGNFTs public ugNFT;
  IUBlood public uBlood;
  IERC1155 public ierc1155;

  //////////////////////////////////
  //          ERRORS             //
  /////////////////////////////////
  error InvalidTokens(uint256 tokenId);
  error InvalidToken();
  error AlreadyStaked();
  error NothingStaked();
  error MaximumAllowedActiveAmulets(uint256 tokenId);
  error MaximumAllowedActiveRings(uint256 tokenId);
  error MismatchArrays();
  error OnlyEOA(address txorigin, address sender);
  error InvalidOwner();
  error StakingCoolDown();

  //////////////////////////////////
  //          EVENTS             //
  /////////////////////////////////
  event TokenStaked(address indexed owner, uint256 indexed tokenId);
  event TokenUnStaked(address indexed owner, uint256 indexed tokenId);
  event TokensStaked(address indexed owner, uint256[] tokenIds, uint256 timestamp);
  event TokensClaimed(address indexed owner, uint256[] indexed tokenIds, bool unstaked, uint256 earned, uint256 timestamp);
  event BloodStolen(address indexed owner, uint256 indexed tokenId, uint256 indexed amount);

  // Operations for _updateIDBalance
  enum Operations { Add, Sub }

  //Daily Blood Rate
  uint256 private DAILY_BLOOD_RATE_PER_LEVEL = 100;
  //Daily Blood per Level
  uint256 private RING_DAILY_BLOOD_PER_LEVEL = 10;
  // fighters & yakuza must be staked for minimum days before they can be unstaked
  uint256 private MINIMUM_DAYS_TO_EXIT = 1 days;
  // yakuza take a 20% tax on all $BLOOD claimed
  uint256 private YAKUZA_TAX_PERCENTAGE = 20;
  // amount of $BLOOD earned so far
  uint256 public totalBloodEarned;

  uint32 constant FIGHTER = 100000;
  uint16 constant RING = 5000;
  uint16 constant AMULET = 10000;

  // Constants regarding bin sizes for balance packing
  // IDS_BITS_SIZE **MUST** be a power of 2 (e.g. 2, 4, 8, 16, 32, 64, 128)
  //using 1 bit for UG nfts
  uint256 internal constant IDS_BITS_SIZE   = 1;                  // Max balance amount in bits per token ID
  uint256 internal constant IDS_PER_UINT256 = 256 / IDS_BITS_SIZE; // Number of ids per uint256
  
  uint256 internal constant USER_TOTAL_BALANCES_BITS_SIZE   = 32;
  //user total balances bit indexes
  uint256 internal constant FIGHTER_INDEX  = 0;
  uint256 internal constant RING_INDEX  = 1;
  uint256 internal constant AMULET_INDEX  = 2;
  uint256 internal constant YAKUZA_INDEX  = 2;

  uint256 internal UNSTAKE_COOLDOWN = 48 hours;
  

  // Token IDs balances ; balances[address][id] => balance (using array instead of mapping for efficiency)
  mapping (address => mapping(uint256 => uint256)) internal stakedBalances;
  //map user address to packed uint256
  mapping (address => uint256) internal userTotalBalances;

  /** PRIVATE VARS */
  // total Fighters staked at this moment
  uint256 public totalFightersStaked;
  // total Yakuza staked at this moment
  uint256 public totalYakuzaStaked;
  // total sum of Yakuza rank staked
  uint256 public totalRankStaked;
  // map all tokenIds to their original owners; ownerAddress => fighter/yaks => tokenIds
  mapping(address => mapping(uint256 => uint256[])) private _ownersOfStakedTokens;
  mapping(address => uint256) private _ownersOfStakedRings;
  mapping(address => uint256) private _ownersOfStakedAmulets;
  mapping(address => uint256) private _ownerLastClaimAllTime;
  mapping(uint256 => uint256) private _ringAmuletUnstakeTimes;

  // total sum of Rings staked
  uint256 private _totalRingsStaked;
  // total sum of Amulets staked
  uint256 private _totalAmuletsStaked;
  
  // maps tokenId to Fighter
  mapping(uint256 => Stake) private _fighterArena;
  // maps to all Yakuza 
  mapping(uint256 => Stake) private _yakuzaPatrol;
  
  // any rewards distributed when no Yakuza are staked
  uint256 private _unaccountedRewards = 0;
  // amount of $BLOOD due for each rank point staked
  uint256 private _bloodPerRank = 0;

  function getBloodPerRank() external view returns (uint256) {
    return _bloodPerRank;
  }

  function getUnaccountedYakRewards() external view returns (uint256) {
    return _unaccountedRewards;
  }
  // admins
  mapping(address => bool) private _admins;

  constructor(address _ugnft, address _blood, address _randomizer) {
    ugNFT = IUGNFTs(_ugnft);
    ierc1155 = IERC1155(_ugnft);
    uBlood = IUBlood(_blood);
    randomizer = IRandomizer(_randomizer);
    //_pause();
  }
  

  function setContracts(address _ugnft, address _blood, address _randomizer) external onlyOwner {
    ugNFT = IUGNFTs(_ugnft);
    ierc1155 = IERC1155(_ugnft);
    uBlood = IUBlood(_blood);
    randomizer = IRandomizer(_randomizer);
  }

  modifier onlyAdmin() {
    require(_admins[_msgSender()], "Arena: Only admins can call this");
    _;
  }

  function stakeManyToArena(uint256[] calldata tokenIds) external whenNotPaused nonReentrant {
    //get batch balances to ensure rightful owner
    if(!ugNFT.checkUserBatchBalance(_msgSender(), tokenIds)) revert InvalidToken();//InvalidTokens({tokenId: tokenId});
    uint256[] memory _amounts = new uint256[](tokenIds.length);
    uint256[] memory FY = ugNFT.getPackedFighters(tokenIds);
    IUGNFTs.FighterYakuza memory fighter;
    Stake memory myStake;
    uint256 numFighters;
    uint256 numYaks;
    uint256 rankCnt;
    
    for (uint i = 0; i < tokenIds.length; i++) {   
      fighter = unPackFighter(FY[i]);

      myStake.tokenId = uint32(tokenIds[i]);
      myStake.stakeTimestamp = uint32(block.timestamp);
      myStake.owner = _msgSender();
      _amounts[i] = 1; //set amounts array for batch transfer

      if(fighter.isFighter){        
        myStake.bloodPerRank = 0;     
        _fighterArena[tokenIds[i]] = myStake;
        _updateIDStakedBalance(_msgSender(),tokenIds[i], _amounts[i], Operations.Add);
        numFighters++;
      } else{//stake yakuza
        myStake.bloodPerRank = uint32(_bloodPerRank);
        myStake.owner = _msgSender();       
        rankCnt+= fighter.rank;
        _yakuzaPatrol[tokenIds[i]] = myStake; // Add the Yakuza to Patrol
        _updateIDStakedBalance(_msgSender(),tokenIds[i], _amounts[i], Operations.Add);
        numYaks++;
      }     
    }

    totalFightersStaked += numFighters;
    totalYakuzaStaked += numYaks;
    totalRankStaked += rankCnt; // Portion of earnings ranges from 5 to 8

    _updateIDUserTotalBalance(_msgSender(),FIGHTER_INDEX, numFighters, Operations.Add);      
    _updateIDUserTotalBalance(_msgSender(),YAKUZA_INDEX, numYaks, Operations.Add);
  
    ierc1155.safeBatchTransferFrom(_msgSender(), address(this), tokenIds, _amounts, "");
    emit TokensStaked(_msgSender(), tokenIds, block.timestamp);
  }

  function payRaidRevenueToYakuza(uint256 amount) external onlyAdmin {
    _payYakuzaTax(amount);
  }
  
  function _payYakuzaTax(uint amount) private {
    if (totalRankStaked == 0) { // if there's no staked Yakuza
      _unaccountedRewards += amount; // keep track of $BLOOD that's due to all Yakuza
      return;
    }
    // makes sure to include any unaccounted $BLOOD
    _bloodPerRank += (amount + _unaccountedRewards) / totalRankStaked;
    _unaccountedRewards = 0;
  }

  function verifyAllStakedByUser(address user, uint256[] calldata _tokenIds) external view returns (bool) {
    for(uint i; i < _tokenIds.length; i++){  
       if(_fighterArena[_tokenIds[i]].owner != user) return false;
    }
    return true;
  }

  function getStakeOwner(uint256 tokenId) public view returns (address) {
    return _fighterArena[tokenId].owner;
  }

  function getStakedYakuzaOwner(uint256 tokenId) public view returns (address) {
    return _yakuzaPatrol[tokenId].owner;
  }

  function _getStake(uint256 tokenId) private view returns (Stake memory) {
    Stake memory myStake = _fighterArena[tokenId];
    if (myStake.owner == address(0)) {
      myStake = _yakuzaPatrol[tokenId];
    } 
    return myStake;
  }

  function claimManyFromArena(uint256[] calldata tokenIds, bool unstake) external whenNotPaused nonReentrant {
    uint256[] memory packedFighters = ugNFT.getPackedFighters(tokenIds);
    if(tokenIds.length != packedFighters.length) revert MismatchArrays();
    uint256[] memory _amounts = new uint256[](tokenIds.length);
    uint256 owed = 0;
    // Fetch the owner so we can give that address the $BLOOD.
    // If the same address does not own all tokenIds this transaction will fail.
    // This is especially relevant when the Game contract calls this function as the _msgSender() - it should NOT get the $BLOOD ofc.
    address account = getStakeOwner(tokenIds[0]);
    // The _admins[] check allows the Game contract to claim at level upgrades
    // and raid contract when raiding.
    if(account != _msgSender() && !_admins[_msgSender()]) revert InvalidToken();
    
    //get ring amulet info
    (uint256 ringLevel, uint256 ringExpireTime, uint256 extraAmuletDays) = getAmuletRingInfo(account);
    
    bool isYakuza;
    for (uint256 i; i < packedFighters.length; i++) {
      account = getStakeOwner(tokenIds[i]);
      if (unPackFighter(packedFighters[i]).isFighter) {
        owed += _claimFighter(tokenIds[i], unstake, ringLevel, ringExpireTime, extraAmuletDays, unPackFighter(packedFighters[i]));
      } else {
        if(!isYakuza){
          isYakuza = true;
        }
        owed += _claimYakuza(tokenIds[i], unstake, unPackFighter(packedFighters[i]));
      }
      //set amounts array for batch transfer
      _amounts[i] = 1;
    }
   
    // Pay out earned $BLOOD
    if (owed > 0) {
      uint256 MAXIMUM_BLOOD_SUPPLY = 2500000000 ether;//uGame.MAXIMUM_BLOOD_SUPPLY();
      uint256 bloodTotalSupply = uBlood.totalSupply();
      // Pay out rewards as long as we did not reach max $BLOOD supply
      if (bloodTotalSupply < MAXIMUM_BLOOD_SUPPLY) {
        if (bloodTotalSupply + owed * 1 ether > MAXIMUM_BLOOD_SUPPLY) { // If totalSupply + owed exceeds the maximum supply then pay out only the remainder
          owed = MAXIMUM_BLOOD_SUPPLY - bloodTotalSupply; // Pay out the rest and that's it, we reached the maximum $BLOOD supply (for now)
        }
        // Pay $BLOOD to the owner
        totalBloodEarned += owed;
        uBlood.mint(account, owed * 1 ether);
      }
    }

    if(unstake) {
      
      ugNFT.safeBatchTransferFrom(address(this), account, tokenIds, _amounts, ""); // send back Fighter
    }
    
    emit TokensClaimed(account, tokenIds, unstake, owed, block.timestamp);
  }

  function _claimFighter(uint256 tokenId, bool unstake, uint256 ringLevel, uint256 ringExpireTime, uint256 extraAmuletDays, IUGNFTs.FighterYakuza memory fighter) private returns (uint256 owed ) {
    Stake memory stake = _getStake(tokenId);
    if(stake.owner != _msgSender() && !_admins[_msgSender()]) revert InvalidOwner();
    if(unstake && block.timestamp - stake.stakeTimestamp < MINIMUM_DAYS_TO_EXIT) revert StakingCoolDown();

    owed += _calculateStakingRewards(tokenId, ringLevel, ringExpireTime, extraAmuletDays, fighter);
    
    // steal and pay tax logic
    if (unstake) {
      if (randomizer.getSeeds(tokenId, owed,1)[0]%2 == 1) { // 50% chance of all $BLOOD stolen
        _payYakuzaTax(owed);
        emit BloodStolen(stake.owner, tokenId, owed);
        owed = 0; // Fighter lost all of his claimed $BLOOD right here
      }
      delete _fighterArena[tokenId];
      totalFightersStaked--;
      _updateIDStakedBalance(stake.owner, tokenId, 1, Operations.Sub);
      _updateIDUserTotalBalance(stake.owner, FIGHTER_INDEX, 1, Operations.Sub);
    } else {
      _payYakuzaTax(owed * YAKUZA_TAX_PERCENTAGE / 100); // percentage tax to staked Yakuza
      owed = owed * (100 - YAKUZA_TAX_PERCENTAGE) / 100; // remainder goes to Fighter owner
      // reset stake
      Stake memory newStake;
      newStake.tokenId = uint32(tokenId);
      newStake.bloodPerRank = 0;
      newStake.stakeTimestamp = uint32(block.timestamp);
      newStake.owner = stake.owner;
      _fighterArena[tokenId] = newStake;
    }
    //emit TokenClaimed(stake.owner, tokenId, unstake, owed, block.timestamp);
    return owed;
  }

  function _claimYakuza(uint256 tokenId, bool unstake, IUGNFTs.FighterYakuza memory fighter) private returns (uint256 owed) { 
    Stake memory stake = _getStake(tokenId);
    uint8 rank = fighter.rank;
    if(stake.owner != _msgSender() && !_admins[_msgSender()]) revert InvalidOwner();
    if(unstake && block.timestamp - stake.stakeTimestamp < MINIMUM_DAYS_TO_EXIT) revert StakingCoolDown();

    owed = _calculateStakingRewards(tokenId,0,0,0, fighter);

    if (unstake) {
      totalRankStaked -= rank; // Remove rank from total staked
      totalYakuzaStaked--; // Decrease the number

      delete _yakuzaPatrol[tokenId]; // Delete old mapping
      _updateIDStakedBalance(stake.owner, tokenId, 1, Operations.Sub);
      _updateIDUserTotalBalance(stake.owner, YAKUZA_INDEX, 1, Operations.Sub);
    } else { // Just claim rewards
      Stake memory myStake;
      myStake.tokenId = uint32(tokenId);
      myStake.bloodPerRank = uint32(_bloodPerRank);
      myStake.stakeTimestamp = uint32(block.timestamp);
      myStake.owner = stake.owner;
      // Reset stake
      _yakuzaPatrol[tokenId] = myStake; 
    }
    //emit TokenClaimed(stake.owner, tokenId, unstake, owed, block.timestamp);
    return owed;
  }

  function calculateStakingRewards(uint256 tokenId) external view returns (uint256 owed) {
    uint256[] memory _ids = new uint256[](1);
    _ids[0] = tokenId;
    Stake memory myStake = _getStake(tokenId);
    uint256[] memory fighters = ugNFT.getPackedFighters(_ids);
    (uint256 ringLevel, uint256 ringExpireTime, uint256 extraAmuletDays) = getAmuletRingInfo(myStake.owner);
    return _calculateStakingRewards(tokenId, ringLevel, ringExpireTime, extraAmuletDays, unPackFighter(fighters[0]));
  }

 function calculateAllStakingRewards(uint256[] memory tokenIds) external view returns (uint256 owed) {
    Stake memory myStake = _getStake(tokenIds[0]);
    (uint256 ringLevel, uint256 ringExpireTime, uint256 extraAmuletDays) = getAmuletRingInfo(myStake.owner);

    uint256[] memory fighters = ugNFT.getPackedFighters(tokenIds);
    for (uint256 i; i < tokenIds.length; i++) {
      owed += _calculateStakingRewards(tokenIds[i], ringLevel, ringExpireTime, extraAmuletDays, unPackFighter(fighters[i]));
    }
    return owed;
  }

  function _calculateStakingRewards(uint256 tokenId, uint256 ringLevel, uint256 ringExpireTime, uint256 extraAmuletDays, IUGNFTs.FighterYakuza memory fighter) private view returns (uint256 owed) {
    Stake memory myStake = _getStake(tokenId);

    uint256 fighterExpireTime;
    if (fighter.isFighter) { // Fighter
      //calculate fighter expire time
      fighterExpireTime = fighter.lastLevelUpgradeTime + 7 days + extraAmuletDays;

      if(fighter.lastRaidTime + 7 days  < fighterExpireTime) fighterExpireTime = fighter.lastRaidTime + 7 days;

      if(fighterExpireTime >= block.timestamp ){//not expired
        //without rings
        if(block.timestamp >= myStake.stakeTimestamp) owed += (block.timestamp - myStake.stakeTimestamp) *fighter.level* DAILY_BLOOD_RATE_PER_LEVEL / 1 days;
        //calculate owed from Ring income
        if(ringExpireTime >= myStake.stakeTimestamp) owed += (ringExpireTime - myStake.stakeTimestamp) * (fighter.level * (ringLevel * RING_DAILY_BLOOD_PER_LEVEL)) / 1 days;
      
      } else {//expired Fighter
        //without rings calc up to fighter expire time
        if(fighterExpireTime >= myStake.stakeTimestamp) owed += (fighterExpireTime - myStake.stakeTimestamp) *fighter.level* DAILY_BLOOD_RATE_PER_LEVEL / 1 days;
        //calculate owed from Ring income up to fighter expire time
        if(ringExpireTime >= fighterExpireTime) ringExpireTime = fighterExpireTime;
        if(ringExpireTime >= myStake.stakeTimestamp) owed += (ringExpireTime - myStake.stakeTimestamp) * (fighter.level * (ringLevel * RING_DAILY_BLOOD_PER_LEVEL)) / 1 days;
      }
        
    } else { // Yakuza
      // Calculate portion of $BLOOD based on rank
      if(_bloodPerRank > myStake.bloodPerRank) owed = (fighter.rank) * (_bloodPerRank - myStake.bloodPerRank);
    }
    return (owed);
  }

  function getAmuletRingInfo(address user) public view returns(uint256 ringLevel, uint256 ringExpireTime, uint256 extrAmuletDays){
    IUGNFTs.RingAmulet memory stakedRing;
    IUGNFTs.RingAmulet memory stakedAmulet;
    uint256 ring = getStakedRingIDForUser(user);
    uint256 amulet = getStakedAmuletIDForUser(user);
    
    if (ring > 0) {
      stakedRing = ugNFT.getRingAmulet(ring);
      ringLevel = stakedRing.level;
    
      // ring expire time
      if(stakedRing.lastLevelUpgradeTime + 7 days < block.timestamp){
        ringExpireTime = stakedRing.lastLevelUpgradeTime + 7 days;
      } else ringExpireTime = block.timestamp;
    } else {
      ringLevel = 0;
      ringExpireTime = 0;
    }
      
    if(amulet > 0) stakedAmulet = ugNFT.getRingAmulet( amulet);
    //calculate extra amulet days
    if(amulet == 0 || stakedAmulet.lastLevelUpgradeTime + 7 days < block.timestamp){
      extrAmuletDays = 0;
    } else extrAmuletDays = stakedAmulet.level * 1 days;
  }

   function stakeRing(uint256 tokenId) external nonReentrant {
    address account = _msgSender();
    if(_ringAmuletUnstakeTimes[tokenId] + UNSTAKE_COOLDOWN > block.timestamp) revert InvalidToken();
    if(ierc1155.balanceOf(account, tokenId) == 0) revert InvalidTokens({tokenId: tokenId});
    //check if user has a staked ring already
    if(_ownersOfStakedRings[account] != 0) revert MaximumAllowedActiveRings({tokenId: tokenId});
    _stakeRing(account, tokenId);
  }

  function _stakeRing(address account, uint256 tokenId) private whenNotPaused {
    _totalRingsStaked++;
    _ownersOfStakedRings[account] = tokenId;   
    ierc1155.safeTransferFrom(account, address(this), tokenId, 1, "");
    delete _ringAmuletUnstakeTimes[tokenId];
    emit TokenStaked(account, tokenId);
  }

  function unstakeRing(uint256 tokenId) external nonReentrant {
    //make sure sender is ringowner
    if(_ownersOfStakedRings[_msgSender()] != tokenId) revert InvalidTokens({tokenId: tokenId});
    _unstakeRing(_msgSender(), tokenId);
  }

  function _unstakeRing(address account, uint256 tokenId) private  {
    _totalRingsStaked--;
    delete _ownersOfStakedRings[account];
    _ringAmuletUnstakeTimes[tokenId] = block.timestamp;
    ierc1155.safeTransferFrom(address(this), account, tokenId, 1, "");
    emit TokenUnStaked(account, tokenId);
  }

  function stakeAmulet(uint256 tokenId) external nonReentrant {
    address account = _msgSender();
    if(_ringAmuletUnstakeTimes[tokenId] + UNSTAKE_COOLDOWN > block.timestamp) revert InvalidToken();
    if(ierc1155.balanceOf(account, tokenId) == 0) revert InvalidTokens({tokenId: tokenId});
    //check if user has a staked amulet already
    if(_ownersOfStakedAmulets[account] != 0) revert MaximumAllowedActiveAmulets({tokenId: tokenId});
    _stakeAmulet(account, tokenId);
  }

  function _stakeAmulet(address account, uint256 tokenId) private whenNotPaused {
    _totalAmuletsStaked++;
    _ownersOfStakedAmulets[account] = tokenId;    
    ierc1155.safeTransferFrom(account, address(this), tokenId, 1, "");
    delete _ringAmuletUnstakeTimes[tokenId];
    emit TokenStaked(account, tokenId);
  }

  function unstakeAmulet(uint256 tokenId) external nonReentrant {
    //make sure sender is amulet owner
    if(_ownersOfStakedAmulets[_msgSender()] != tokenId) revert InvalidTokens({tokenId: tokenId});
    _unstakeAmulet(_msgSender(), tokenId);
  }

  function _unstakeAmulet(address account, uint256 tokenId) private  {
    _totalAmuletsStaked--;
    delete _ownersOfStakedAmulets[account];
    _ringAmuletUnstakeTimes[tokenId] = block.timestamp;
    ierc1155.safeTransferFrom(address(this), account, tokenId, 1, "");
    emit TokenUnStaked(account, tokenId);
  }

  function numUserStakedFighters(address user) external view returns (uint256){
    return getValueInBin(userTotalBalances[user], USER_TOTAL_BALANCES_BITS_SIZE, FIGHTER_INDEX);
  }
  function numUserStakedYakuza(address user) external view returns (uint256){
    return getValueInBin(userTotalBalances[user], USER_TOTAL_BALANCES_BITS_SIZE, YAKUZA_INDEX);
  }

 function getStakedFighterIDsForUser(address user) public view returns (uint256[] memory){
    //get balance of fighters
    uint256 numStakedFighters = getValueInBin(userTotalBalances[user], USER_TOTAL_BALANCES_BITS_SIZE, FIGHTER_INDEX);
    uint256[] memory _tokenIds = new uint256[](numStakedFighters);
    //loop through user balances until we find all the fighters
    uint count;
    uint ttlFYs = ugNFT.ttlFYakuzas();
    for(uint i=1; count<numStakedFighters && i <= ttlFYs; i++){
      if(
        _viewUserStakedIdBalance(user, FIGHTER + i) ==1 &&
        ugNFT.getFighter(FIGHTER + i).isFighter
      ){       
        _tokenIds[count] = FIGHTER + i;
        count++;          
      }
    }
    return _tokenIds;
  }

  function getStakedYakuzaIDsForUser(address user) public view returns (uint256[] memory){
    //get balance of fighters
    uint256 numStakedFighters = getValueInBin(userTotalBalances[user], USER_TOTAL_BALANCES_BITS_SIZE, YAKUZA_INDEX);
    uint256[] memory _tokenIds = new uint256[](numStakedFighters);
    //loop through user balances until we find all the yakuzas
    uint count;
    uint ttlFYs = ugNFT.ttlFYakuzas();
    for(uint i=1; count<numStakedFighters && i <= ttlFYs; i++){
      if(
        _viewUserStakedIdBalance(user, FIGHTER + i) ==1 &&
        !ugNFT.getFighter(FIGHTER + i).isFighter
      ){       
        _tokenIds[count] = FIGHTER + i;
        count++;          
      }
    }
    return _tokenIds;
  }

  function unPackFighter(uint256 packedFighter) private pure returns (IUGNFTs.FighterYakuza memory) {
    IUGNFTs.FighterYakuza memory fighter;   
    fighter.isFighter = uint8(packedFighter)%2 == 1 ? true : false;
    fighter.Gen = uint8(packedFighter>>1)%2;
    fighter.level = uint8(packedFighter>>2);
    fighter.rank = uint8(packedFighter>>10);
    fighter.courage = uint8(packedFighter>>18);
    fighter.cunning = uint8(packedFighter>>26);
    fighter.brutality = uint8(packedFighter>>34);
    fighter.knuckles = uint8(packedFighter>>42);
    fighter.chains = uint8(packedFighter>>50);
    fighter.butterfly = uint8(packedFighter>>58);
    fighter.machete = uint8(packedFighter>>66);
    fighter.katana = uint8(packedFighter>>74);
    fighter.scars = uint16(packedFighter>>90);
    fighter.imageId = uint16(packedFighter>>106);
    fighter.lastLevelUpgradeTime = uint32(packedFighter>>138);
    fighter.lastRankUpgradeTime = uint32(packedFighter>>170);
    fighter.lastRaidTime = uint32(packedFighter>>202);
    return fighter;
  }

  function getStakedRingIDForUser(address user) public view returns (uint256){
    //get balance of staked rings
    return _ownersOfStakedRings[user];
  }

  function getStakedAmuletIDForUser(address user) public view returns (uint256){
    //get balance of staked rings
    return _ownersOfStakedAmulets[user];
  }

  function getOwnerLastClaimAllTime(address user) external view returns (uint256){
    //get balance of staked rings
    return _ownerLastClaimAllTime[user];
  }

  function setOwnerLastClaimAllTime(address user) external onlyAdmin {
    _ownerLastClaimAllTime[user] = block.timestamp;
  }

  /////////////////////////////////////////
  //     Packed Balance Functions       //
  ///////////////////////////////////////
  
  /**
   * @notice Update the balance of a id for a given address
   * @param _address    Address to update id balance
   * @param _id         Id to update balance of
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to id balance
   *   Operations.Sub: Substract _amount from id balance
   */
  function _updateIDStakedBalance(address _address, uint256 _id, uint256 _amount, Operations _operation)
    internal
  {
    uint256 bin;
    uint256 index;

    // Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);

    // Update balance
    stakedBalances[_address][bin] = _viewUpdateBinValue(stakedBalances[_address][bin], IDS_BITS_SIZE, index, _amount, _operation);
  }

  function _updateIDUserTotalBalance(address _address, uint256 _index, uint256 _amount, Operations _operation)
    internal
  {
    // Update balance
    userTotalBalances[_address] = _viewUpdateBinValue(userTotalBalances[_address], USER_TOTAL_BALANCES_BITS_SIZE, _index, _amount, _operation);
  }

  /**
   * @notice Update a value in _binValues
   * @param _binValues  Uint256 containing values of size IDS_BITS_SIZE (the token balances)
   * @param _index      Index of the value in the provided bin
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to value in _binValues at _index
   *   Operations.Sub: Substract _amount from value in _binValues at _index
   */
  function _viewUpdateBinValue(uint256 _binValues, uint256 bitsize, uint256 _index, uint256 _amount, Operations _operation)
    internal pure returns (uint256 newBinValues)
  {
    uint256 shift = bitsize * _index;
    uint256 mask = (uint256(1) << bitsize) - 1;

    if (_operation == Operations.Add) {
      newBinValues = _binValues + (_amount << shift);
      require(newBinValues >= _binValues, " OVERFLOW2");
      require(
        ((_binValues >> shift) & mask) + _amount < 2**bitsize, // Checks that no other id changed
        "OVERFLOW1"
      );

    } else if (_operation == Operations.Sub) {
      newBinValues = _binValues - (_amount << shift);
      require(newBinValues <= _binValues, " UNDERFLOW");
      require(
        ((_binValues >> shift) & mask) >= _amount, // Checks that no other id changed
        "viewUpdtBinVal: UNDERFLOW"
      );

    } else {
      revert("viewUpdtBV: INVALID_WRITE"); // Bad operation
    }

    return newBinValues;
  }

  /**
  * @notice Return the bin number and index within that bin where ID is
  * @param _id  Token id
  * @return bin index (Bin number, ID"s index within that bin)
  */
  function getIDBinIndex(uint256 _id)
    public pure returns (uint256 bin, uint256 index)
  {
    bin = _id / IDS_PER_UINT256;
    index = _id % IDS_PER_UINT256;
    return (bin, index);
  }

  /**
   * @notice Return amount in _binValues at position _index
   * @param _binValues  uint256 containing the balances of IDS_PER_UINT256 ids
   * @param _index      Index at which to retrieve amount
   * @return amount at given _index in _bin
   */
  function getValueInBin(uint256 _binValues, uint256 bitsize, uint256 _index)
    public pure returns (uint256)
  {
    // Mask to retrieve data for a given binData
    uint256 mask = (uint256(1) << bitsize) - 1;

    // Shift amount
    uint256 rightShift = bitsize * _index;
    return (_binValues >> rightShift) & mask;
  }

  function _viewUserStakedIdBalance(address _address, uint256 _id)
    internal view returns(uint256)
  {
    uint256 bin;
    uint256 index;

    // Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);

    // return balance
    return getValueInBin(stakedBalances[_address][bin], IDS_BITS_SIZE, index);
  }

  /** ONLY ADMIN FUNCTIONS */
  function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
  

  /** ONLY OWNER FUNCTIONS */
  function setPaused(bool paused) external /*requireVariablesSet*/ onlyOwner {
    if (paused) _pause();
    else _unpause();
  }

  function addAdmin(address addr) external onlyOwner {
    _admins[addr] = true;
  }

  function removeAdmin(address addr) external onlyOwner {
    delete _admins[addr];
  }

}