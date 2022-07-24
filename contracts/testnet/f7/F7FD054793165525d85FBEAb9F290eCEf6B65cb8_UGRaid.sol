/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-23
*/

// File: contracts/interfaces/IRandomizer.sol



pragma solidity ^0.8.0;
interface IRandomizer{
    function getSeeds(uint256, uint256, uint256) external view returns (uint256[] memory);
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
// File: contracts/interfaces/IUGRaid.sol



pragma solidity 0.8.13;


interface IUGRaid {

  struct Raid {
    uint8 levelTier;
    uint8 sizeTier;
    uint16 fightClubId;
    uint16 maxScars;
    uint32 maxSweat;
    uint32 id;
    uint32 revenue;
    uint32 timestamp;
  }

  struct RaiderEntry{
      uint8 size;
      uint8 yakFamily;
      uint32 sweat;
  }

  struct RaidEntryTicket {
    uint8 sizeTier;
    uint8 fighterLevel;
    uint8 yakuzaFamily;
    uint8 courage;
    uint8 brutality;
    uint8 cunning;
    uint8 knuckles;
    uint8 chains;
    uint8 butterfly;
    uint8 machete;
    uint8 katana;
    uint16 scars;
    uint32 sweat;
    uint32 fighterId;
    uint32 entryFee;
    uint32 winnings;
  }
  
  function referee() external;
  function enterRaid(uint256[] calldata, RaiderEntry[] calldata) external  returns(uint256 ttlBloodEntryFee);
  function stakeFightclubs(uint256[] calldata) external;
  function unstakeFightclubs(uint256[] calldata) external;
  function claimRaiderBloodRewards() external;
  function claimFightClubBloodRewards() external ;
  function addFightClubToQueueAfterLevelSizeUp(uint256, uint8, uint8, IUGNFTs.ForgeFightClub calldata ) external;
  function getStakedFightClubIDsForUser(address) external view returns (uint256[] memory);
  //function getRaidCost(uint256, uint256) external view returns(uint256);
  function getRaiderQueueLength(uint8, uint8) external view returns(uint8);
  //function getFightClubIdInQueuePosition(uint8, uint8, uint) external view returns (uint256);
  //function getRaiderIdInQueuePosition(uint8, uint8, uint) external view returns (uint256);
  //function setUnstakeCoolDownPeriod(uint256) external;//onlyOwner
  function getValueInBin(uint256 , uint256 , uint256 )external pure returns (uint256);
  function viewIfRaiderIsInQueue( uint256 tokenId) external view returns(bool);
  function setWeaponsRound(bool) external;//onlyOwner
  function setYakuzaRound(bool) external;//onlyOwner
  function setSweatRound(bool) external;//onlyOwner
  function setBaseRaidFee(uint256 newBaseFee) external; //onlyOwner
  function setRefereeBasePct(uint256 pct) external; //onlyOwner
  function setDevWallet(address) external;//onlyOwner
  function setDevFightClubId(uint256) external;//onlyOwner
  function addAdmin(address) external;//onlyOwner
  function removeAdmin(address) external;//onlyOwner
//   function viewRaiderOwnerBloodRewards(address) external view returns (uint256);
//   function viewFightClubOwnerBloodRewards(address) external view returns (uint256);
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

// File: contracts/interfaces/IUBlood.sol



pragma solidity 0.8.13;

interface IUBlood {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
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
// File: contracts/UGRaid.sol



pragma solidity 0.8.13;









interface IUGWeapons {
  function burn(address _from, uint256 _id, uint256 _amount) external;    
}

contract UGRaid is IUGRaid, Ownable, ReentrancyGuard {

  struct Queue {
    uint128 start;
    uint128 end;
    mapping(uint256 => uint256) ids;
  }

  constructor(address _ugnft, address _blood, address _ugArena, address _ugWeapons, address _randomizer) {
    ierc1155 = IERC1155(_ugnft);
    ugNFT = IUGNFTs(_ugnft);
    uBlood = IUBlood(_blood);
    ugArena = IUGArena(_ugArena);
    ugWeapons = IUGWeapons(_ugWeapons);
    randomizer = IRandomizer(_randomizer);
  }

  //////////////////////////////////
  //          CONTRACTS          //
  /////////////////////////////////
  IERC1155 private ierc1155;
  IUGNFTs public ugNFT;
  IUGArena public ugArena;
  IUBlood private uBlood;
  IUGWeapons public ugWeapons;
  IRandomizer private randomizer;
 

  //////////////////////////////////
  //          EVENTS             //
  /////////////////////////////////
  event RaidCreated(uint256 indexed raidId, Raid raid);
  event RaidersAssignedToRaid(RaidEntryTicket[] raidTickets, uint256 indexed raidId);
  event RaidResults(uint256 indexed raidId, RaidEntryTicket[] raidTickets, uint256[] scores);
  event RefereeRewardsPaid(address indexed referee, uint256 rewards);
  event YakuzaTaxPaidFromRaids(uint256 amount, uint256 indexed timestamp);
  event YakuzaFamilyWinner(uint256 indexed raidId, uint256 yakFamily);
  event YakuzaRaidShareStolen(uint256 indexed fighterId, uint256 indexed raidId);
  event RaiderOwnerBloodRewardClaimed(address user);
  event FightClubOwnerBloodRewardClaimed(address user);

  //////////////////////////////////
  //          ERRORS             //
  /////////////////////////////////
  error MismatchArrays();
  //error InvalidTokens(uint256 tokenId);
  error InvalidOwner();
  error InvalidAddress();
  error InvalidTokenId();
  error StillUnstakeCoolDown();
  error Unauthorized();
  error OnlyEOA();
  error InvalidSize();
  error AlreadyInQueue();

  uint256 constant BASE_RAID_SIZE = 5;
  uint16 constant FIGHT_CLUB = 20000;
  uint32 constant FIGHTER = 100000;

  //weapons constants
  uint8 constant STEEL_DURABILITY_SCORE = 75;
  uint8 constant BRONZE_DURABILITY_SCORE = 80;
  uint8 constant GOLD_DURABILITY_SCORE = 85;
  uint8 constant PLATINUM_DURABILITY_SCORE = 90;
  uint8 constant TITANIUM_DURABILITY_SCORE = 95;
  uint8 constant DIAMOND_DURABILITY_SCORE = 100;

  uint8 constant STEEL_ATTACK_SCORE = 10;
  uint8 constant BRONZE_ATTACK_SCORE = 20;
  uint8 constant GOLD_ATTACK_SCORE = 40;
  uint8 constant PLATINUM_ATTACK_SCORE = 60;
  uint8 constant TITANIUM_ATTACK_SCORE = 80;
  uint8 constant DIAMOND_ATTACK_SCORE = 100;
  //Weapons only allowed starting at their respective tier
  //tier 1 = levels 1-3, tier 2 = levels 4-6, etc
  //tier = (level-1)/3  +  1  scrap the remainder
  //example tier for level 6 = (6-1)/3 (no remainder) + 1 = 2 (tier 2)
  //weapons start being used when knuckles are allowed at tier 4 (level 10)
  uint8 constant KNUCKLES_TIER = 4; //levels 10 and up
  uint8 constant CHAINS_TIER = 7; //levels 19 and up
  uint8 constant BUTTERFLY_TIER = 10;//levels 28 and up
  uint8 constant MACHETE_TIER = 14;//levels 40 and up
  uint8 constant KATANA_TIER = 18;//levels 52 and up
  uint256 constant MAX_SIZE_TIER = 4;

  uint256 constant BRUTALITY_WEIGHT = 40;
  uint256 constant WEAPONS_WEIGHT = 30;
  uint256 constant SWEAT_WEIGHT = 20;
  uint256 constant SCARS_WEIGHT = 5;
  uint256 constant YAKUZA_INTIMIDATION_WEIGHT = 5;

  uint256 private FIGHT_CLUB_BASE_CUT_PCT = 25;
  uint256 private YAKUZA_BASE_CUT_PCT = 5;
  uint256 private REFEREE_BASE_CUT_PCT = 10;
  uint256 private BASE_RAID_FEE = 100;
  uint256 private UNSTAKE_COOLDOWN = 48 hours;

  bool public yakuzaRoundActive;
  bool public weaponsRoundActive;
  bool public sweatRoundActive;
  
  uint8 private maxRaiderQueueLevelTier;
  uint8 private maxStakedFightClubRaidSizeTier;
  uint8 private maxStakedFightClubLevelTier;
  uint256 private ttlRaids;
  uint256 private _totalFightClubsStaked;
  uint256 private devFightClubId;
  address private devWallet;

  
  
  mapping(address => bool) private _admins;
  //maps level => size => fightclub queue
  mapping(uint256 => mapping(uint256 => Queue)) private fightClubQueue;
  //maps level => size => Raider token Ids queue
  mapping(uint256 => mapping(uint256 => Queue)) private RaiderQueue;
  
  //maps fightclub id => owner address
  mapping(uint256 => address) private stakedFightclubOwners;
  //maps owner => number of staked fightclubs
  mapping(address => uint256) private ownerTotalStakedFightClubs;
  //maps address => weapon => metal score => value
  mapping(address => mapping(uint256 => mapping(uint256 => uint256 ))) private weaponsToMint;
  //maps tokenId to packed uint (bools) is in raider que
  mapping(uint256 => uint256) private raiderInQue;
  //maps Raider owner => blood rewards
  mapping(address => uint256) public raiderOwnerBloodRewards;
  //maps FightClub owner => blood rewards
  mapping(address => uint256) public fightClubOwnerBloodRewards;
  

  //Modifiers//
  modifier onlyAdmin() {
    if(!_admins[msg.sender]) revert Unauthorized();
    _;
  }

  modifier onlyEOA() {
    if(tx.origin != msg.sender) revert OnlyEOA();
    _;
  }
  
  function referee() external nonReentrant onlyEOA {  
    //this function gathers all raiders and matches them with raids
    //first make sure we are at a valid block
    uint8 tempVal;
    uint8 raidSize;
    uint8 numRaiders;
    //uint8 queueLength;
    uint256 weaponsScore;
    uint256 yakuzaFamilyWinner;
    uint256 _yakRewards;
    uint256 refRewards;

    Raid memory raid;    
    RaidEntryTicket[] memory raidTickets ;
    uint256[] memory scores;
  //i = levelTier , j = sizeTier start from highest and we need to limit to 120 fighters
    for(uint8 i=maxRaiderQueueLevelTier; i >= 1; i--){
      for(uint8 j=maxStakedFightClubRaidSizeTier; j >= 1; j--){
        
        //BEGINNING OF EACH FIGHTER QUE
        raidSize = j*5;        
        tempVal = getRaiderQueueLength( i, j);//tempVal is queuelength here
        if(tempVal >= raidSize){                    
          tempVal = tempVal/raidSize;//tempval is now numRaids for this queue   
          //make sure we do not exceed 110 fighters per referee session
          while(tempVal*raidSize + numRaiders > 110) {
            tempVal--;    
          }   
          numRaiders += tempVal * raidSize;
          //loop through multiples of raidsize to create multiple raids at once
          for(uint8 k; k < tempVal; k++){
            //BEGINNING OF RAID
            //create raid
            raid = _createRaid(i, j);
            
            //get yakuza family for raid
            //yakuzaFamilyWinner is a random number between 0-2
            if(yakuzaRoundActive) yakuzaFamilyWinner = randomizer.getSeeds(tempVal, raid.id,1)[0]%3;
            emit YakuzaFamilyWinner(raid.id, yakuzaFamilyWinner);
            //fill with fighters and get raid tickets
            (raidTickets, raid) = _assignRaidersToRaid(raid, uint8(yakuzaFamilyWinner));
            //loop through to get scores/determine winner
            scores = new uint256[](raidSize);
            for(uint n=0; n<raidSize; n++){
             
              //only do following rounds if survive yakuza intimidation round   
              if(!yakuzaRoundActive || raidTickets[n].yakuzaFamily > 0){

                //weapons round
                if(weaponsRoundActive){
                  //get weapons scores
                  (weaponsScore, raidTickets[n] )= _getWeaponsScore(raid, raidTickets[n]);
                } else weaponsScore = 0;

                //sweat round
                if(!sweatRoundActive ){
                  raid.maxSweat = 1;
                  raidTickets[n].sweat = 0;                
                } 
                
                //safety check to make sure no division by 0
                if(raid.maxScars == 0) raid.maxScars = 1;
                if(raid.maxSweat == 0) raid.maxSweat = 1;
          
                //calculate scores
                scores[n] = BRUTALITY_WEIGHT * raidTickets[n].fighterLevel * raidTickets[n].brutality/(i*3) + 
                WEAPONS_WEIGHT * weaponsScore  +
                SWEAT_WEIGHT * 100 * raidTickets[n].sweat / raid.maxSweat +
                SCARS_WEIGHT * 100 * raidTickets[n].scars / raid.maxScars + 
                YAKUZA_INTIMIDATION_WEIGHT * raidTickets[n].yakuzaFamily;
              }
              
              //if lost in yakuza round set score to 0
              if(yakuzaRoundActive && raidTickets[n].yakuzaFamily == 0){
                scores[n] = 0;
              }
             
              raid.revenue += raidTickets[n].entryFee;
            }
            
            // sort raidTickets by score
            _quickSort(scores, raidTickets, int(0), int(raidTickets.length - 1));

            bool isYakShareStolen;
            (raidTickets,  isYakShareStolen) = _calculateRaiderRewards(scores, raidTickets, raid);
            if (isYakShareStolen) emit YakuzaRaidShareStolen(raidTickets[0].fighterId, raid.id);
            //tally yakuza rewards
            else _yakRewards += YAKUZA_BASE_CUT_PCT * raid.revenue / 100 ;

            //fight club owner rewards
            fightClubOwnerBloodRewards[stakedFightclubOwners[raid.fightClubId]] += FIGHT_CLUB_BASE_CUT_PCT * raid.revenue/100; 
  
            //referee rewards
            refRewards += REFEREE_BASE_CUT_PCT * raid.revenue / 100 ;

            //emit events
            emit RaidResults(raid.id, raidTickets, scores);  
          }            
        }
      }
    }
    ugArena.payRaidRevenueToYakuza( _yakRewards);
    //send ref rewards
    uBlood.mint(msg.sender,refRewards * 1 ether);

    emit RefereeRewardsPaid(msg.sender, refRewards);
    emit YakuzaTaxPaidFromRaids(_yakRewards, block.timestamp);
  }

  function getYakuzaRoundScore(uint8 yakuzaFamily, uint256 rand) private pure returns (uint8 _yakScore){
    //get Yakuza initimdation result
    if(rand == 0){
      if(yakuzaFamily == 0) return 1;//survive
      if(yakuzaFamily == 1) return 0;//lose
      if(yakuzaFamily == 2) return 100;//win
    }
    if(rand == 1){
      if(yakuzaFamily == 0) return 100;//win
      if(yakuzaFamily == 1) return 1;//survive
      if(yakuzaFamily == 2) return 0;//lose
    }
    if(rand == 2){
      if(yakuzaFamily == 0) return 0;//lose
      if(yakuzaFamily == 1) return 100;//win
      if(yakuzaFamily == 2) return 1;//survive
    }
    return 0;
  }

  function _weaponScore(uint8 attackScore, uint256 seed) private pure returns(uint score, bool _isBroken){
    if (attackScore == 0 || attackScore%10 != 0) return (0, false);
    //get metal if fighter is equipped with an unbroken weapon
    if (attackScore == 10){
      if ((seed <<= 8)%100 > 100 - STEEL_DURABILITY_SCORE) return (attackScore, false); 
      else return (0, true);
    }
    if (attackScore == 20){
      if ((seed <<= 8)%100 > 100 - BRONZE_DURABILITY_SCORE) return (attackScore, false); 
      else return (0, true);
    }
    if (attackScore == 40){
      if ((seed <<= 8)%100 > 100 - GOLD_DURABILITY_SCORE) return (attackScore, false); 
      else return (0, true);
    }
    if (attackScore == 60){
      if ((seed <<= 8)%100 > 100 - PLATINUM_DURABILITY_SCORE) return (attackScore, false); 
      else return (0, true);
    }
    if (attackScore == 80){
      if ((seed <<= 8)%100 > 100 - TITANIUM_DURABILITY_SCORE) return (attackScore, false); 
      else return (0, true);
    }
    if (attackScore == 100){
      return (attackScore, false); 
    }
  }

  function _getWeaponsScore(Raid memory raid, RaidEntryTicket memory ticket) private view returns (uint256 weaponsScore, RaidEntryTicket memory){
      uint256 _maxWeapons;
      //check if weapon breaks
      uint256[] memory seeds = randomizer.getSeeds(raid.maxScars, ticket.fighterId, 5);
      //calculate weapons score
      if(raid.levelTier >= KNUCKLES_TIER) {
        _maxWeapons++;
        (uint tempScore, bool _isBroken) = _weaponScore(ticket.knuckles, seeds[0]);
        weaponsScore += tempScore;
        //add 1 to score if broken -  memory instance will record to storage after raid calcs are made    
         if(_isBroken) ticket.knuckles += 1;
      }

      if(raid.levelTier >= CHAINS_TIER){
        _maxWeapons++;
        (uint tempScore, bool _isBroken) = _weaponScore(ticket.chains, seeds[1]);
        weaponsScore += tempScore;
        //add 1 to score if broken -  memory instance will record to storage after raid calcs are made    
         if(_isBroken) ticket.chains += 1;
      } 

      if(raid.levelTier >= BUTTERFLY_TIER){
        _maxWeapons++;
        (uint tempScore, bool _isBroken) = _weaponScore(ticket.butterfly, seeds[2]);
        weaponsScore += tempScore;
        //add 1 to score if broken -  memory instance will record to storage after raid calcs are made    
         if(_isBroken) ticket.butterfly += 1;
      } 

      if(raid.levelTier >= MACHETE_TIER){
        _maxWeapons++;
       (uint tempScore, bool _isBroken) = _weaponScore(ticket.machete, seeds[3]);
        weaponsScore += tempScore;
        //add 1 to score if broken -  memory instance will record to storage after raid calcs are made    
         if(_isBroken) ticket.machete += 1;
      } 

      if(raid.levelTier >= KATANA_TIER){
        _maxWeapons++;
        (uint tempScore, bool _isBroken) = _weaponScore(ticket.katana, seeds[4]);
        weaponsScore += tempScore;
        //add 1 to score if broken -  memory instance will record to storage after raid calcs are made    
         if(_isBroken) ticket.katana += 1;
      } 
      weaponsScore = _maxWeapons > 0 ? weaponsScore / _maxWeapons : 0;

      return (weaponsScore, ticket);
  }

  function _calculateRaiderRewards(uint256[] memory scores, RaidEntryTicket[] memory raidTickets, Raid memory raid) private returns (RaidEntryTicket[] memory, bool yakShareStolen) {
    address raiderOwner;
    //collect stats to permanently upgrade fighters
    uint256[] memory raidStatsPacked = new uint256[](raidTickets.length);
    //assign resulting scars and weapons scores to fighters and pay out blood rewards
    for(uint o; o<raidTickets.length;o++){
      raiderOwner = ugArena.getStakeOwner(raidTickets[o].fighterId);
      //1st
      if(o == 0){
        //1st place blood reward is raid revenue * 1st place base pct + size tier
        raidTickets[o].winnings = raid.revenue * 25 / 100;

        //cunning gives cunning/2 pct chance of taking yakuza cut
        if(randomizer.getSeeds(ttlRaids, raidTickets[o].fighterId, 1)[0]%100 <= raidTickets[o].cunning/2){
          raidTickets[o].winnings += uint32(raid.revenue * YAKUZA_BASE_CUT_PCT / 100);
          yakShareStolen = true;
         }
      }
        if(o == 0 || o == 1 || o == 2){
        //weapon rewards (if over a certain size tier)
        if(raid.sizeTier >= 2) {
          if(raid.levelTier >= KNUCKLES_TIER && raid.levelTier < CHAINS_TIER)
             if(o == 0) weaponsToMint[raiderOwner][0][20*(raid.sizeTier)]++;
             if(o == 1 && raid.sizeTier == 4) weaponsToMint[raiderOwner][0][60]++;
             if(o == 2 && raid.sizeTier == 4) weaponsToMint[raiderOwner][0][20]++;
          if(raid.levelTier >= CHAINS_TIER && raid.levelTier < BUTTERFLY_TIER)
             if(o == 0) weaponsToMint[raiderOwner][1][20*(raid.sizeTier)]++;
             if(o == 1 && raid.sizeTier == 4) weaponsToMint[raiderOwner][1][60]++;
             if(o == 2 && raid.sizeTier == 4) weaponsToMint[raiderOwner][1][20]++;
          if(raid.levelTier >= BUTTERFLY_TIER && raid.levelTier < MACHETE_TIER)
             if(o == 0) weaponsToMint[raiderOwner][2][20*(raid.sizeTier)]++;
             if(o == 1 && raid.sizeTier == 4) weaponsToMint[raiderOwner][2][60]++;
             if(o == 2 && raid.sizeTier == 4) weaponsToMint[raiderOwner][2][20]++;
          if(raid.levelTier >= MACHETE_TIER && raid.levelTier < KATANA_TIER)
             if(o == 0) weaponsToMint[raiderOwner][3][20*(raid.sizeTier)]++;
             if(o == 1 && raid.sizeTier == 4) weaponsToMint[raiderOwner][3][60]++;
             if(o == 2 && raid.sizeTier == 4) weaponsToMint[raiderOwner][3][20]++;
          if(raid.levelTier >= KATANA_TIER)
             if(o == 0) weaponsToMint[raiderOwner][4][20*(raid.sizeTier)]++;
             if(o == 1 && raid.sizeTier == 4) weaponsToMint[raiderOwner][4][60]++;
             if(o == 2 && raid.sizeTier == 4) weaponsToMint[raiderOwner][4][20]++;
        }
      }
      //2nd place blood reward is raid revenue * 2nd place base pct - size tier
      if(o == 1) raidTickets[o].winnings = raid.revenue * 15 / 100;
    
      //3rd place blood reward is raid revenue * 3rd place base pct
      if(o == 2 && raidTickets[o].sizeTier > 1) raidTickets[o].winnings = raid.revenue * 5 / 100;
    
      //4th place blood reward is raid revenue * 4th place base pct
      if(o == 3 && raidTickets[o].sizeTier > 2) raidTickets[o].winnings = raid.revenue * 3 / 100;
      
      //5th place blood reward is raid revenue * 5th place base pct
      if(o == 4 && raidTickets[o].sizeTier > 3) raidTickets[o].winnings = raid.revenue * 2 / 100;

      //scars if not kicked out of yakuzaa round
      if (scores[o] > 0) raidTickets[o].scars += uint16(o + 1);

      //pack ticket to prepare for sendoff to ugNFT contract for permanent write
      raidStatsPacked[o] = packTicket(raidTickets[o]);

      //pay out blood rewards
      raiderOwnerBloodRewards[raiderOwner] += raidTickets[o].winnings;
    }
    //WRITE RESULTS PERMANENTLY TO FIGHTERS
    ugNFT.setRaidTraitsFromPacked( raidStatsPacked);
    return (raidTickets, yakShareStolen);
  }

  function claimRaiderBloodRewards() external nonReentrant {
    uint256 payout =  raiderOwnerBloodRewards[msg.sender];
    delete raiderOwnerBloodRewards[msg.sender];
    uBlood.mint(msg.sender, payout * 1 ether);
    emit RaiderOwnerBloodRewardClaimed(msg.sender);
  }

  function claimFightClubBloodRewards() external nonReentrant {
    uint256 payout =  fightClubOwnerBloodRewards[msg.sender];
    delete fightClubOwnerBloodRewards[msg.sender];
    uBlood.mint(msg.sender, payout * 1 ether);
    emit FightClubOwnerBloodRewardClaimed(msg.sender);
  }

  function _assignRaidersToRaid(Raid memory raid, uint8 yakuzaFamilyWinner) private returns (RaidEntryTicket[] memory, Raid memory) {
    require(raid.sizeTier > 0, "raid error");
    uint8 _raidSize = raid.sizeTier * 5;
    RaidEntryTicket[] memory tickets = new RaidEntryTicket[](_raidSize);
    uint8 _yakScore;

    for(uint i; i < _raidSize; i++){
     tickets[i] = getTicketInQueue(raid.levelTier,raid.sizeTier);
      //mark that fighter has been removed from que if it hasnt already been marked as removed
      if(viewIfRaiderIsInQueue(tickets[i].fighterId)) _updateIfRaiderIsInQueue(tickets[i].fighterId, Operations.Sub);
      if(yakuzaRoundActive){
        //returns 0 if lost yakuza intimidation round, 1 if survived, 100 if gets boost
        _yakScore = getYakuzaRoundScore(tickets[i].yakuzaFamily, yakuzaFamilyWinner);
        if(_yakScore ==0){
          uint roll = randomizer.getSeeds(raid.id, tickets[i].fighterId, 1)[0]%100;
          if(roll < tickets[i].courage ) _yakScore = 1;
        }
       
      } else _yakScore = 0;
      //record yak result to the yakuzaFamily ticket memory slot
      tickets[i].yakuzaFamily = _yakScore;
      //if fighter survives yakuza round
      if(!yakuzaRoundActive || _yakScore > 0){
        //check if fighter has max sweat or max scars
        raid.maxScars = raid.maxScars >= tickets[i].scars ? raid.maxScars : tickets[i].scars;
        raid.maxSweat = raid.maxSweat >= tickets[i].sweat ? raid.maxSweat : tickets[i].sweat;              
      }
    }
    emit RaidersAssignedToRaid(tickets, raid.id);
    return (tickets, raid);
  }

  //this function creates a raid with next availble fightclub
  function _createRaid(uint8 levelTier, uint8 _raidSizeTier) private returns (Raid memory){
    Raid memory raid; 
    //get queue length for fightclubs
    uint16 queuelength = _getQueueLength(fightClubQueue[levelTier][_raidSizeTier]);
    uint256 fclubId;
    
    //loop through fight clubs to find next eligible
    for(uint i; i < queuelength; i++){
      //packed id with size 
      fclubId = getFightClubInQueueAndRecycle( levelTier, _raidSizeTier) ;
      //if we find an elible one, break out of for loop
      if(fclubId > 0) break;
    }

    //if no eligible fight clubs are in queue
    if(fclubId == 0) {
      //get house/dev fight club to hold raid
      fclubId = devFightClubId ;
    }
    
    raid.levelTier = levelTier;
    raid.sizeTier = _raidSizeTier; 
    raid.id = uint32(++ttlRaids);
    raid.fightClubId = uint16(fclubId );
    raid.timestamp = uint32(block.timestamp);
    emit RaidCreated(raid.id, raid);
  
    return raid;
  }

   //returns 0 if token is no longer eligible for que (did not level up/ maintain or not staked)
  function getFightClubInQueueAndRecycle( uint8 _levelTier, uint8 _raidSizeTier) private returns (uint256) {
    //get packed value: id with fightclub size
    uint256 id = removeFromQueue(fightClubQueue[_levelTier][_raidSizeTier], IDS_BITS_SIZE);
    //uint256 unpackedId = id%2 ** 11;
    //do not re-enter queue if has been unstaked since getting in queue
    if(stakedFightclubOwners[id] == address(0)) return 0;
    IUGNFTs.ForgeFightClub memory fightclub = ugNFT.getForgeFightClub(id);
    //and is right level and size, do not re-enter queue if fails this check
    if(fightclub.size < _raidSizeTier || (fightclub.level -1 )/3 + 1 < _levelTier) return 0;
    //if fight club has not been leveled up at least once in last week + 1 day auto unstake fightclub
    if(fightclub.lastLevelUpgradeTime + 8 days < block.timestamp) {
      //auto unstake if hasnt been already
      _autoUnstakeFightClub(id);
      return 0;
    }

    //add back to queue with current size
    //unpackedId |= fightclub.size<<11;
    addToQueue(fightClubQueue[_levelTier][_raidSizeTier], id, IDS_BITS_SIZE);
    //check to see fight club has been leveled up at least once in last week
    if(fightclub.lastLevelUpgradeTime + 7 days < block.timestamp) return 0;
    return id;
  }

  function getTicketInQueue( uint256 _levelTier, uint256 _raidSizeTier) private returns (RaidEntryTicket memory) {
    RaidEntryTicket memory ticket;
    //get queue length for raiders
    uint256 queuelength = _getQueueLength(RaiderQueue[_levelTier][_raidSizeTier]);
    //loop through raiders to find next eligible
    uint256 packedTicket;
    for(uint i; i < queuelength; i++){
      //get paked ticket
      packedTicket = removeFromQueueFullUint(RaiderQueue[_levelTier][_raidSizeTier]);
      //unpack ticket
      ticket = unpackTicket(packedTicket);
      //if we find an eligible one, return id
      if(ticket.fighterId > 0 && ierc1155.balanceOf(address(ugArena),ticket.fighterId) == 1) return ticket;
    }
    //if we fail to find one send an empty
    ticket = RaidEntryTicket(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
    return ticket;
  }

  function getRaiderIdFromFighterId(uint256 fighterId) private pure returns (uint16 raiderId){
    raiderId = uint16(fighterId - FIGHTER);
  }

  function getFighterIdFromRaiderId(uint256 raiderId) private pure returns (uint32 fighterId){
    fighterId = uint32(raiderId + FIGHTER);
  }

  //player function for entering Raids, enter fighter id, size raid to enter, sweat to allocate, yakuza pick
    function enterRaid(uint256[] calldata tokenIds, RaiderEntry[] calldata raiderEntries) external onlyEOA nonReentrant returns(uint256 ttlBloodEntryFee){
        uint256 ttlSweat;
        uint256 bloodEntryFee;
        //make sure tokens staked in arena by sender
        if(!ugArena.verifyAllStakedByUser(msg.sender, tokenIds)) revert InvalidTokenId();
        if(tokenIds.length != raiderEntries.length) revert MismatchArrays();
      
        //get fighters
        uint256[] memory packedFighters = ugNFT.getPackedFighters(tokenIds);
        uint256[] memory packedTickets = new uint256[](packedFighters.length);

        for(uint i; i<packedFighters.length;i++){
            //make sure its a fighter not yakuza
            if(!unPackFighter(packedFighters[i]).isFighter) continue;
            //make sure raider not already in queue
            if(viewIfRaiderIsInQueue(tokenIds[i])) revert AlreadyInQueue();
            //if raider is past due to raid, must be claimed to prevent getting paid extra
            if(unPackFighter(packedFighters[i]).lastRaidTime + 7 days < block.timestamp) 
              ugArena.claimManyFromArena(tokenIds,false);

            if(raiderEntries[i].size == 0 || raiderEntries[i].size > MAX_SIZE_TIER) revert InvalidSize();
            ttlSweat += raiderEntries[i].sweat;
            (packedTickets[i], bloodEntryFee) = packTicketForEntry(unPackFighter(packedFighters[i]), raiderEntries[i].size, raiderEntries[i].sweat, tokenIds[i], raiderEntries[i].yakFamily);
            _updateIfRaiderIsInQueue(tokenIds[i], Operations.Add);
            ttlBloodEntryFee += bloodEntryFee;

            
        }
        //burn sweat (ID = 55)
        if (sweatRoundActive) ugWeapons.burn(msg.sender, 55, ttlSweat);
        //burn blood entry fee
        burnBlood(msg.sender, ttlBloodEntryFee);
        //add raid tickets to Raid Que
        addTicketsToRaiderQueue(packedTickets);
        
        
    }

    function addTicketsToRaiderQueue(uint256[] memory packedTickets) private {
        uint8 levelTier;
        for(uint i; i < packedTickets.length; i++){
        levelTier = getLevelTier(uint8(packedTickets[i]>>8));
        //add to queue and convert fighterid to raider id to use a smaller storage slot
        addToQueueFullUint(RaiderQueue[levelTier][uint8(packedTickets[i])], packedTickets[i]);
        maxRaiderQueueLevelTier = levelTier  > maxRaiderQueueLevelTier ? levelTier  : maxRaiderQueueLevelTier;    
        }
    }

    function packTicketForEntry(
        IUGNFTs.FighterYakuza memory fighter, 
        uint256 sizeTier, 
        uint256 sweat, 
        uint256 tokenId,
        uint256 yakFamily
    ) private view returns (uint256, uint256 bloodEntryFee){
        uint256 ticket = sizeTier;
        uint256 nextVal = fighter.level;
        ticket |= nextVal<<8;
        nextVal = yakFamily;
        ticket |= nextVal<<16;
        nextVal = fighter.courage;
        ticket |= nextVal<<24;
        nextVal =  fighter.brutality;
        ticket |= nextVal<<32;
        nextVal =  fighter.cunning;
        ticket |= nextVal<<40;
        nextVal =  fighter.knuckles;
        ticket |= nextVal<<48;
        nextVal =  fighter.chains;
        ticket |= nextVal<<56;
        nextVal =  fighter.butterfly;
        ticket |= nextVal<<64;
        nextVal =  fighter.machete;
        ticket |= nextVal<<72;
        nextVal =  fighter.katana;
        ticket |= nextVal<<80;
        nextVal =  fighter.scars;
        ticket |= nextVal<<96;
        nextVal = sweat;
        ticket |= nextVal<<128;
        //fighterId
        nextVal = tokenId;
        ticket |= nextVal<<160;
        //entryFee
        nextVal = getRaidCost((fighter.level - 1) /3 + 1,  sizeTier);
        bloodEntryFee = nextVal;
        ticket |= nextVal<<192;

        return (ticket, bloodEntryFee) ;
  }

  function unPackFighter(uint256 packedFighter) private pure returns (IUGNFTs.FighterYakuza memory) {
    IUGNFTs.FighterYakuza memory fighter;   
    fighter.isFighter = uint8(packedFighter)%2 == 1 ? true : false;
    fighter.Gen = uint8(packedFighter>>1)%2 ;
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

  function packTicket(RaidEntryTicket memory _ticket) 
    private pure returns (uint256)
  {
      uint256 ticket = uint256(_ticket.sizeTier);
      uint256 nextVal = _ticket.fighterLevel;
      ticket |= nextVal<<8;
      nextVal = _ticket.yakuzaFamily;
      ticket |= nextVal<<16;
      nextVal = _ticket.courage;
      ticket |= nextVal<<24;
      nextVal = _ticket.brutality;
      ticket |= nextVal<<32;
      nextVal = _ticket.cunning;
      ticket |= nextVal<<40;
      nextVal = _ticket.knuckles;
      ticket |= nextVal<<48;
      nextVal = _ticket.chains;
      ticket |= nextVal<<56;
      nextVal = _ticket.butterfly;
      ticket |= nextVal<<64;
      nextVal = _ticket.machete;
      ticket |= nextVal<<72;
      nextVal = _ticket.katana;
      ticket |= nextVal<<80;
      nextVal = _ticket.scars;
      ticket |= nextVal<<96;
      nextVal = _ticket.sweat;
      ticket |= nextVal<<128;
      nextVal = _ticket.fighterId;
      ticket |= nextVal<<160;
      nextVal = _ticket.entryFee;
      ticket |= nextVal<<192;
      return ticket;
  }

  function unpackTicket(uint256 packedTicket) 
    private pure returns (RaidEntryTicket memory _ticket)
  {
      _ticket.sizeTier = uint8(packedTicket);
      _ticket.fighterLevel = uint8(packedTicket>>8);
      _ticket.yakuzaFamily = uint8(packedTicket>>16);
      _ticket.courage = uint8(packedTicket>>24);
      _ticket.brutality = uint8(packedTicket>>32);
      _ticket.cunning = uint8(packedTicket>>40);
      _ticket.knuckles = uint8(packedTicket>>48);
      _ticket.chains = uint8(packedTicket>>56);
      _ticket.butterfly = uint8(packedTicket>>64);
      _ticket.machete = uint8(packedTicket>>72);
      _ticket.katana = uint8(packedTicket>>80);
      _ticket.scars = uint16(packedTicket>>96);
      _ticket.sweat = uint32(packedTicket>>128);
      _ticket.fighterId = uint32(packedTicket>>160);
      _ticket.entryFee = uint32(packedTicket>>192);
      return _ticket;
  }
  
  function stakeFightclubs(uint256[] calldata tokenIds) external nonReentrant {
    //make sure is owned by sender
    if(!ugNFT.checkUserBatchBalance(msg.sender, tokenIds)) revert InvalidTokenId();    
    IUGNFTs.ForgeFightClub[] memory fightclubs = ugNFT.getForgeFightClubs(tokenIds);
    if(tokenIds.length != fightclubs.length) revert MismatchArrays();
    
    _stakeFightclubs(msg.sender, tokenIds, fightclubs);
  }

  function _stakeFightclubs(address account, uint256[] calldata tokenIds, IUGNFTs.ForgeFightClub[] memory fightclubs) private {
    uint256[] memory amounts = new uint256[](tokenIds.length);
    for(uint i; i < tokenIds.length; i++){
      //make sure it has been unstaked for 48 hours to clear the fightclub que 
      //so fclub owner cant game by continually staking and unstaking
      if(fightclubs[i].lastUnstakeTime > 0 && fightclubs[i].lastUnstakeTime + UNSTAKE_COOLDOWN > block.timestamp) revert StillUnstakeCoolDown();
      
      stakedFightclubOwners[tokenIds[i]] = account;
      amounts[i] = 1;
      //add fightclub to queue, use (1 , 1) for (startSizeTier, startlevelTier)
       _addFightClubToQueues(tokenIds[i], 1, 1, fightclubs[i]);
       //set unstake time to 0
      ugNFT.setFightClubUnstakeTime(tokenIds[i], false);
    }
    _totalFightClubsStaked += tokenIds.length;
    ownerTotalStakedFightClubs[account] += tokenIds.length;

    ierc1155.safeBatchTransferFrom(account, address(this), tokenIds, amounts, "");
    //emit TokenStaked(account, tokenId);
  }

  function addFightClubToQueueAfterLevelSizeUp(
    uint256 tokenId, 
    uint8 sizeTiersToUpgrade, 
    uint8 levelTiersToUpgrade, 
    IUGNFTs.ForgeFightClub calldata fightclub
  ) external onlyAdmin {

    if(levelTiersToUpgrade > 0){
      _addFightClubToQueues(tokenId,  1,  getLevelTier(fightclub.level), fightclub);
    }

    if(sizeTiersToUpgrade > 0){
      _addFightClubToQueues(tokenId,  fightclub.size,  1, fightclub);
    }
   
  }

  function _addFightClubToQueues(uint256 tokenId, uint8 startSizeTier, uint8 startLevelTier, IUGNFTs.ForgeFightClub memory fightclub) private {
    //check to see fight club has been leveled up at least once in last week
    if(fightclub.lastLevelUpgradeTime + 7 days > block.timestamp) 
    {
      uint8 maxLevelTier = getLevelTier(fightclub.level);  
      uint8 maxSizeTier = fightclub.size; 
     
      for(uint8 j=startLevelTier; j <= maxLevelTier; j++){
        for(uint8 k=startSizeTier; k <= maxSizeTier; k++){
          addToQueue(fightClubQueue[j][k], tokenId, IDS_BITS_SIZE);
          maxStakedFightClubRaidSizeTier = k  > maxStakedFightClubRaidSizeTier ? k  : maxStakedFightClubRaidSizeTier;
          maxStakedFightClubLevelTier = maxLevelTier  > maxStakedFightClubLevelTier ? maxLevelTier  : maxStakedFightClubLevelTier;
        }
      }
    }
  }

  function _autoUnstakeFightClub(uint256 tokenId) private {
    address account = stakedFightclubOwners[tokenId];
    delete stakedFightclubOwners[tokenId];
    ugNFT.setFightClubUnstakeTime(tokenId, true);
     _totalFightClubsStaked--;
    ownerTotalStakedFightClubs[account]--;
    ierc1155.safeTransferFrom(address(this), account, tokenId, 1, "");
  }

  function unstakeFightclubs(uint256[] calldata tokenIds) external nonReentrant {
    uint256[] memory amounts = new uint256[](tokenIds.length);
    for(uint i; i < tokenIds.length;i++){
      //make sure sender is ringowner
      if(stakedFightclubOwners[tokenIds[i]] != msg.sender) revert InvalidTokenId();
      //Update unstake time
      ugNFT.setFightClubUnstakeTime(tokenIds[i], true);
      delete stakedFightclubOwners[tokenIds[i]];
      amounts[i] = 1;
    }

    _totalFightClubsStaked -= tokenIds.length;
    ownerTotalStakedFightClubs[msg.sender] -= tokenIds.length;

    ierc1155.safeBatchTransferFrom(address(this), msg.sender, tokenIds, amounts, "");
    //emit TokenUnStaked(msg.sender, tokenIds);
  }
   
  function getStakedFightClubIDsForUser(address user) external view returns (uint256[] memory){
    //get balance of fight clubs
    uint256 numStakedFightClubs = ownerTotalStakedFightClubs[user];
    uint256[] memory _tokenIds = new uint256[](numStakedFightClubs);
    //loop through user balances until we find all the fighters
    uint count;
    uint ttl = ugNFT.ttlFightClubs();
    for(uint i = 1; count<numStakedFightClubs && i <= FIGHT_CLUB + ttl; i++){
      if(stakedFightclubOwners[FIGHT_CLUB + i] == user){
        _tokenIds[count] = FIGHT_CLUB + i;
        count++;
      }
    }
    return _tokenIds;
  }

  //levelTiers 1 = (1-3), 2 = (4-6), 3 = (7-9), maxLevel at each tier = levelTier * 3
  function getLevelTier(uint8 level) private pure returns (uint8) {
    if(level == 0) return 0;
    return (level-1)/3 + 1;
  }
  
  function getRaidCost(uint256 levelTier, uint256 sizeTier) public view returns (uint256 price) {
      return (BASE_RAID_FEE * (2 + sizeTier-1) * levelTier * 3);
  }

  function getRaiderQueueLength(uint8 level, uint8 sizeTier) public view returns (uint8){
   return _getQueueLength(RaiderQueue[level][sizeTier]);
  }

  function _getQueueLength(Queue storage queue) private view returns (uint8){
    return uint8(queue.end - queue.start);
  }

  function burnBlood(address account, uint256 amount) private {
    uBlood.burn(account , amount * 1 ether);
    //allocate 10% of all burned blood to dev wallet for continued development
    uBlood.mint(devWallet, amount * 1 ether /10);
  }

  function addToQueueFullUint(Queue storage queue, uint256 packedUint) private {
    queue.ids[queue.end++] = packedUint;
  }

  function removeFromQueueFullUint(Queue storage queue) private returns (uint256) {    
    //get first in line
    uint256 packedUint = queue.ids[queue.start];

    // remove first in line id from queue
    queue.ids[queue.start++] = 0;
    
    //return first in line
    return packedUint;
  }

  //queue functions
  function addToQueue(Queue storage queue, uint256 _id, uint256 bitsize) private {
    uint256 bin;
    uint256 index;

    // Get bin and index of end index, then increment end
    (bin, index) = getIDBinIndex(queue.end++);

    // Update id in bin/index
    queue.ids[bin] = _viewUpdateBinValue(queue.ids[bin], bitsize, index, _id, Operations.Add);

  }

  //get next in queue and remove
  function removeFromQueue(Queue storage queue, uint256 bitsize) private returns (uint256) {
    uint256 bin;
    uint256 index;
    // Get bin and index of start index, then increment start
    (bin, index) = getIDBinIndex(queue.start++);
    
    //get first in line
    uint256 _id = getValueInBin(queue.ids[bin], bitsize, index);

    // remove first in line id from bin/index
    queue.ids[bin] = _viewUpdateBinValue(queue.ids[bin], bitsize, index, _id, Operations.Sub);
    
    //return first in line
    return _id;
  }

  // function getSeeds(uint256 rand1, uint256 rand2, uint256 numRands) private view returns (uint256[] memory) {
  //     uint256[] memory randNums = new uint256[](numRands);
  //     for(uint i; i < numRands; i++){
  //       randNums[i] = uint256(
  //                       keccak256(
  //                           abi.encodePacked(
  //                               // solhint-disable-next-line
  //                               block.timestamp,
  //                               msg.sender,
  //                               blockhash(block.number-1),
  //                               rand1+i,
  //                               rand2+i
  //                           )
  //                       )
  //       );
  //     }
  //   return randNums;
  // }

  /** OWNER ONLY FUNCTIONS */

  function setContracts(address _ugArena, address _ugNFT, address _uBlood,address _ugWeapons, address _randomizer) external onlyOwner {
    ugNFT = IUGNFTs(_ugNFT);
    uBlood = IUBlood(_uBlood);
    ugArena = IUGArena(_ugArena);
    ugWeapons = IUGWeapons(_ugWeapons);
    randomizer = IRandomizer(_randomizer);
  }

//   function setUnstakeCoolDownPeriod(uint256 period) external onlyOwner {
//     UNSTAKE_COOLDOWN = period;
//   }

  function addAdmin(address addr) external onlyOwner {
    _admins[addr] = true;
  }

  function removeAdmin(address addr) external onlyOwner {
    delete _admins[addr];
  }

  function setWeaponsRound(bool active) external onlyOwner {
    weaponsRoundActive = active;
  }

  function setYakuzaRound(bool active) external onlyOwner {
    yakuzaRoundActive = active;
  }
  
  function setSweatRound(bool active) external onlyOwner {
    sweatRoundActive = active;
  }

  function setDevWallet(address newWallet) external onlyOwner {
    if(newWallet == address(0)) revert InvalidAddress();
    stakedFightclubOwners[devFightClubId] = newWallet;
    devWallet = newWallet;
  }

  function setDevFightClubId(uint256 id) external onlyOwner {
    address _devWallet = stakedFightclubOwners[devFightClubId];
    delete stakedFightclubOwners[devFightClubId];
    stakedFightclubOwners[id] = _devWallet;
    devFightClubId = id;
  }

//   function setFightClubBasePct(uint256 pct) external onlyOwner {
//     FIGHT_CLUB_BASE_CUT_PCT = pct;
//   }

//   function setYakuzaBasePct(uint256 pct) external onlyOwner {
//     YAKUZA_BASE_CUT_PCT = pct;
//   }

  function setRefereeBasePct(uint256 pct) external onlyOwner {
    REFEREE_BASE_CUT_PCT = pct;
  }
  
  function setBaseRaidFee(uint256 newBaseFee) external onlyOwner {
    require(newBaseFee >0);
    BASE_RAID_FEE = newBaseFee;
  }

  function _quickSort(uint256[] memory keyArr, RaidEntryTicket[] memory dataArr, int left, int right) private pure {
    int i = left;
    int j = right;
    if (i == j) return;
    uint pivot = keyArr[uint(left + (right - left) / 2)];
    while (i <= j) {
        while (keyArr[uint(i)] > pivot) i++;
        while (pivot > keyArr[uint(j)]) j--;
        if (i <= j) {
            (keyArr[uint(i)], keyArr[uint(j)]) = (keyArr[uint(j)], keyArr[uint(i)]);
            (dataArr[uint(i)], dataArr[uint(j)]) = (dataArr[uint(j)], dataArr[uint(i)]);
            i++;
            j--;
        }
    }
    if (left < j)
        _quickSort(keyArr, dataArr, left, j);
    if (i < right)
        _quickSort(keyArr, dataArr, i, right);
  }

  //////////////////////////////////////
  //     Packed Balance Functions     //
  //////////////////////////////////////
  // Operations for _updateIDBalance
  enum Operations { Add, Sub }
  //map raidId => raiders packed uint 16 bits
  mapping(uint256 => uint256) internal raiders;
  uint256 constant IDS_BITS_SIZE =16;
  uint256 constant IDS_PER_UINT256 = 16;
  uint256 constant RAID_IDS_BIT_SIZE = 32;

  function _viewUpdateBinValue(
    uint256 _binValues, 
    uint256 bitsize, 
    uint256 _index, 
    uint256 _amount, 
    Operations _operation
  ) internal pure returns (uint256 newBinValues) {

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

  function getIDBinIndex(uint256 _id) private pure returns (uint256 bin, uint256 index) {
    bin = _id / IDS_PER_UINT256;
    index = _id % IDS_PER_UINT256;
    return (bin, index);
  }

  function getValueInBin(uint256 _binValues, uint256 bitsize, uint256 _index)
    public pure returns (uint256)
  {
    // Mask to retrieve data for a given binData
    uint256 mask = (uint256(1) << bitsize) - 1;
    
    // Shift amount
    uint256 rightShift = bitsize * _index;
    return (_binValues >> rightShift) & mask;
  }

  function viewIfRaiderIsInQueue( uint256 tokenId) public view returns(bool) {
    uint id = tokenId;
    // Get bin and index of _id
    uint256 bin = id / 256;
    uint256 index = id % 256;
    uint256 _binValue = raiderInQue[bin];

    _binValue = _binValue & (1 << index);
    // return balance
    return _binValue > 0;
  }

  function _updateIfRaiderIsInQueue( uint256 tokenId, Operations _operation) internal {
    uint id = tokenId;
    // Get bin and index of _id
    uint256 bin = id / 256;
    uint256 index = id % 256;
    uint256 _binValue = raiderInQue[bin];

    if (_operation == Operations.Add){
      _binValue = _binValue | (1 << index);
    }

    if (_operation == Operations.Sub){
      _binValue = _binValue - (1 << index);
    }

    raiderInQue[bin] = _binValue;
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
}