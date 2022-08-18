/**
 *Submitted for verification at snowtrace.io on 2022-08-18
*/

// File: contracts/interfaces/IUGForgeSmith.sol



pragma solidity 0.8.13;


interface IUGForgeSmith { 
    function addToTotalForgeLevelStaked (uint256) external;
    function stakeForges(uint256[] calldata tokenIds) external ;
    function unstakeFightclubs(uint256[] calldata tokenIds) external ;
    function calculateAllStakingRewards(uint256[] memory tokenIds) external view returns (uint256[] memory weapons, uint256[] memory amounts);
    function calculateStakingRewards(uint256 tokenId) external view returns (uint256 weapon, uint256 owed);
    function claimAllStakingRewards(address user) external ;
    function getStakedForgeIDsForUser(address user) external view returns (uint256[] memory);
}
// File: contracts/interfaces/IUGgame.sol


pragma solidity 0.8.13;


interface IUGgame{

    struct RaiderEntry{
        uint8 size;
        uint8 yakFamily;
        uint32 sweat;
    }
    function MAXIMUM_BLOOD_SUPPLY() external view returns (uint256);
    function getFighterLevelUpBloodCost(uint16, uint256) external view returns(uint256);
    function getRingLevelUpBloodCost(uint16, uint256, uint256) external view returns(uint256);
    function getAmuletLevelUpBloodCost(uint16, uint256, uint256) external view returns(uint256);
    function levelUpFighters(uint256[] calldata, uint256[] memory, bool) external returns(uint256);
    function levelUpRing(uint256, uint256) external returns(uint256);
    function levelUpAmulet(uint256, uint256) external returns(uint256);
    function levelUpFightClubs(uint256[] calldata, uint256[] memory, uint256[] memory) external returns(uint256);
    function levelUpForges(uint256[] calldata, uint256[] memory) external returns(uint256);
    function sizeUpForges(uint256[] calldata) external returns(uint256);
    function getFightClubLevelUpBloodCost(uint16, uint16, uint8, uint8) external view  returns(uint256);
    function setFightClubLevelCostAdjustmentPct(uint16 pct) external; //onlyOwner
    function setFighterLevelCostAdjustmentPct(uint16 pct) external; //onlyOwner
    function setRingLevelCostAdjustmentPct(uint16 pct) external;//onlyOwner
    function setAmuletLevelCostAdjustmentPct(uint16 pct) external;//onlyOwner
    function setMaximumBloodSupply(uint256) external;//onlyOwner
    function setRingBloodMintCost(uint256) external;//onlyOwner
    function setAmuletBloodMintCost(uint256) external;//onlyOwner
    function setFightClubBloodMintCost(uint256) external;//onlyOwner
    function setForgeBloodMintCost(uint256) external;//onlyOwner

}
// File: contracts/interfaces/IUGArena.sol


pragma solidity 0.8.13;


// import "./IUGNFT.sol";
// import "./IUGFYakuza.sol";

interface IUGArena {

    struct Stake {
        uint32 tokenId;
        uint32 bloodPerRank;
        uint32 stakeTimestamp;
        address owner;
    }
    function setGameContract(address _ugGame) external;
    function numUserStakedFighters(address user) external view returns (uint256);
    function getStake(uint256 tokenId) external view returns (Stake memory);
    function getStakeOwner(uint256 tokenId) external view returns (address);
    function getStakedYakuza(uint256 tokenId) external view returns (Stake memory);
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
    function setPaused(bool) external;
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
// File: contracts/interfaces/IUGFYakuza.sol


pragma solidity 0.8.13;

interface IUGFYakuza{
 
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
    function balanceOf(address) external view returns (uint256);
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    function getPackedFighters(uint256[] calldata tokenIds) external view returns (uint256[] memory);
    function setBaseURI(string calldata uri) external;//onlyOwner
    function tokenURI(uint256 tokenId) external view returns (string memory) ;
    function uri(uint256 tokenId) external view returns (string memory) ;
    function batchMigrateFYakuza(address _to, uint256[] calldata v1TokenIds, FighterYakuza[] calldata oldFighters) external;//onlyAdmin 
    function checkUserBatchBalance(address user, uint256[] calldata tokenIds) external view returns (bool);
    function getFighter(uint256 tokenId) external view returns (FighterYakuza memory);
    function getFighters(uint256[] calldata) external view returns (FighterYakuza[] memory);
    function levelUpFighters(uint256[] calldata, uint256[] calldata) external; // onlyAdmin
    function addAdmin(address) external; // onlyOwner 
    function removeAdmin(address) external; // onlyOwner
    function ttlFYakuzas() external view returns (uint256);
    function setRaidTraitsFromPacked( uint256[] calldata raidStats) external;    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function setFighter( uint256 tokenId, FighterYakuza memory FY) external;
}
// File: contracts/interfaces/IUGNFT.sol


pragma solidity 0.8.13;

interface IUGNFT {

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
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    function setBaseURI(string calldata uri) external;//onlyOwner
    function uri(uint256 tokenId) external view returns (string memory) ;
    function mintRingAmulet(address, uint256, bool ) external;//onlyAdmin  
    function mintFightClubForge(address _to, bytes memory _data, uint256 _size, uint256 _level, bool isFightClub) external;//onlyAdmin
    function checkUserBatchBalance(address user, uint256[] calldata tokenIds) external view returns (bool);
    function getNftIDsForUser(address , uint) external view returns (uint256[] memory);
    function getRingAmulet(uint256 ) external view returns (RingAmulet memory);
    function getForgeFightClub(uint256 tokenId) external view returns (ForgeFightClub memory);
    function getForgeFightClubs(uint256[] calldata tokenIds) external view returns (ForgeFightClub[] memory); 
    function levelUpRingAmulets(uint256, uint256 ) external;
    function levelUpFightClubsForges(uint256[] calldata tokenIds, uint256[] calldata newSizes, uint256[] calldata newLevels) external returns (ForgeFightClub[] memory); // onlyAdmin
    function addAdmin(address) external; // onlyOwner 
    function removeAdmin(address) external; // onlyOwner
    function ttlFightClubs() external view returns (uint256);
    function ttlRings() external view returns (uint256);
    function ttlAmulets() external view returns (uint256);
    function ttlForges() external view returns (uint256);
    function setFightClubUnstakeTime (uint256 , bool) external;
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
  function getUnclaimedWeaponsCount(address user) external view returns (uint256 numWeapons, uint256 numWeaponTypes);
  function addIfRaidersInQueue(uint256[] memory tokenIds) external;
  function addTicketsToRaiderQueue(uint256[] memory packedTickets) external;
  function yakuzaRoundActive() external view returns (bool);
  function sweatRoundActive() external view returns (bool);
  function weaponsRoundActive() external view returns (bool);
  function referee(uint256) external;
  function stakeFightclubs(uint256[] calldata) external;
  function unstakeFightclubs(uint256[] calldata) external;
  function claimRaiderBloodRewards() external;
  function claimFightClubBloodRewards() external ;
  function addFightClubToQueueAfterLevelSizeUp(uint256, uint8, uint8, IUGNFT.ForgeFightClub calldata ) external;
  function getStakedFightClubIDsForUser(address) external view returns (uint256[] memory);
  function getRaidCost(uint256, uint256) external view returns(uint256);
  function getRaiderQueueLength(uint8, uint8) external view returns(uint16);
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
// File: contracts/UGgame.sol



pragma solidity 0.8.13;












contract UGgame is IUGgame, Ownable, ReentrancyGuard, Pausable {

      //////////////////////////////////
     //          CONTRACTS           //
    //////////////////////////////////
    IUGNFT public ugNFT;
    IUGFYakuza public ugFYakuza;
    IUGRaid public ugRaid;
    IUBlood public uBlood;
    IUGArena public ugArena;
    IUGForgeSmith public ugForgeSmith;

      /////////////////////////////////
     //          EVENTS             //
    /////////////////////////////////
    event BloodBurned( uint256 indexed timestamp, uint256 amount);

      ////////////////////////////////
     //          ERRORS            //
    ////////////////////////////////
    error MismatchArrays();
    error InvalidAddress();
    error InvalidTokenId();
    error OnlyEOA(address txorigin, address sender);
    error InvalidSize(uint8 size, uint32 sweat, uint8 yak, uint i);
    error TooMany();
    error InvalidLevel();
    error InvalidSizes();
    error MaxSizeAllowed();
    error MaxLevelAllowed();
    error BloodError();
    error MustUpgradeLevel();
    error MustUpgradeSize();
    error MintNotActive();
    error NeedMoreFighters();

    //user total balances bit indexes
    uint256 internal constant FIGHTER_INDEX  = 1;
    uint256 internal constant RING_INDEX  = 2;
    uint256 internal constant AMULET_INDEX  = 3;
    uint256 internal constant FORGE_INDEX  = 4;
    uint256 internal constant FIGHT_CLUB_INDEX  = 5;

    uint32 constant RING = 5000;
    uint32 constant AMULET = 10000;
    uint32 constant FIGHTER = 100000;
    uint32 constant FORGE_MAX_SIZE = 5;
    uint32 constant FORGE_MAX_LEVEL = 35;
    uint32 constant FIGHT_CLUB_MAX_SIZE = 4;
    uint32 constant FIGHT_CLUB_MAX_LEVEL = 34;

    uint16 private FIGHTER_LEVEL_COST_ADJUSTMENT_PCT = 100;
    uint16 private RING_LEVEL_COST_ADJUSTMENT_PCT = 100;
    uint16 private AMULET_LEVEL_COST_ADJUSTMENT_PCT = 100;
    uint16 private FIGHTCLUB_LEVEL_COST_ADJUSTMENT_PCT = 100;
    uint16 private FORGE_LEVEL_COST_ADJUSTMENT_PCT = 100;
    uint16 private FORGE_SIZE_COST_ADJUSTMENT_PCT = 100;

    bool public FORGE_MINT_ACTIVE = false;
    bool public FIGHTCLUB_MINT_ACTIVE = false;
    bool public AMULET_MINT_ACTIVE = false;
    bool public RING_MINT_ACTIVE = false;

    uint256 public MIN_FIGHTERS_PER_RING = 4;
    uint256 public MIN_FIGHTERS_PER_AMULET =5;

    uint256 private FIGHTER_BASE_LEVEL_COST = 50;
    uint256 private RING_BASE_LEVEL_COST = 1000;
    uint256 private AMULET_BASE_LEVEL_COST = 2000;
    uint256 private FORGE_BASE_LEVEL_COST = 25000;
    uint256 private FORGE_BASE_SIZE_COST = 125000;  
    uint256 private FIGHT_CLUB_BASE_LEVEL_COST = 1000;

    uint256 private RING_BLOOD_MINT_COST = 2_000_000 ;
    uint256 private AMULET_BLOOD_MINT_COST = 2_000_000 ;
    uint256 private FORGE_BLOOD_MINT_COST = 2_000_000 ;
    uint256 private FIGHTCLUB_BLOOD_MINT_COST = 5_000_000 ;
    uint256 public MAXIMUM_BLOOD_SUPPLY = 2_500_000_000 ;

    uint256 private MAXIMUM_FIGHTCLUBS_PER_MINT = 5;
    uint256 private MAXIMUM_FIGHTCLUBS_PER_WALLET = 5;
    
    address private WITHDRAW_ADDRESS;
    address private devWallet;

    /** MODIFIERS */
    modifier onlyEOA() {
        if(tx.origin != _msgSender()) revert OnlyEOA({txorigin: tx.origin, sender: _msgSender()});
        _;
    }

    constructor(
        address _ugnft, 
        address _ugFYakuza, 
        address _ugArena, 
        address _ugRaid, 
        address _blood, 
        address _ugForgeSmith,
        address _devWallet
    ) {
        ugNFT = IUGNFT(_ugnft);
        ugFYakuza = IUGFYakuza(_ugFYakuza);
        ugArena = IUGArena(_ugArena);
        ugRaid = IUGRaid(_ugRaid);
        uBlood = IUBlood(_blood);
        ugForgeSmith = IUGForgeSmith(_ugForgeSmith);
        devWallet = _devWallet;
    }

    /** MINTING FUNCTIONS */
    function mintRing() external whenNotPaused  nonReentrant onlyEOA {
        if(!RING_MINT_ACTIVE) revert MintNotActive();
        uint256 totalCost = RING_BLOOD_MINT_COST;
        // This will fail if not enough $BLOOD is available
        burnBlood(_msgSender(), totalCost);
        ugNFT.mintRingAmulet(_msgSender(),  1, true);
    }

    function mintAmulet() external whenNotPaused  nonReentrant onlyEOA {
        if(!AMULET_MINT_ACTIVE) revert MintNotActive();
        uint256 totalCost = AMULET_BLOOD_MINT_COST;
        // This will fail if not enough $BLOOD is available
        burnBlood(_msgSender(), totalCost);
        ugNFT.mintRingAmulet(_msgSender(),  1, false);
    }

    function mintFightClubs(uint amount) external whenNotPaused nonReentrant onlyEOA {
        if(!FIGHTCLUB_MINT_ACTIVE) revert MintNotActive();
        if(amount > MAXIMUM_FIGHTCLUBS_PER_MINT) revert TooMany();
        if (MAXIMUM_FIGHTCLUBS_PER_WALLET > 0 && 
            amount + ugNFT.getNftIDsForUser(_msgSender(), FIGHT_CLUB_INDEX).length > MAXIMUM_FIGHTCLUBS_PER_WALLET) revert TooMany();
        uint256 totalCost = FIGHTCLUB_BLOOD_MINT_COST * amount;
        // This will fail if not enough $BLOOD is available
        burnBlood(_msgSender(), totalCost);
        for(uint i;i<amount;i++){
            ugNFT.mintFightClubForge(_msgSender(), "", 1, 1, true);
        }
    }

    function mintForges(uint amount) external whenNotPaused nonReentrant onlyEOA{
        if(!FORGE_MINT_ACTIVE) revert MintNotActive();
        uint256 totalCost = FORGE_BLOOD_MINT_COST * amount;
        // This will fail if not enough $BLOOD is available
        burnBlood(_msgSender(), totalCost);
        for(uint i;i<amount;i++){
            ugNFT.mintFightClubForge(_msgSender(), "", 1, 1, false);
        }
    }

    function levelUpFighters(
        uint256[] calldata _tokenIds, 
        uint256[] memory _levelsToUpgrade, 
        bool _isStaked
    ) external whenNotPaused nonReentrant onlyEOA returns (uint256 totalBloodCost) {
        //require both argument arrays to be same length
        if(_tokenIds.length != _levelsToUpgrade.length) revert MismatchArrays(); 
        
        //if not staked, must be owned by msgSender
        if(!_isStaked) {
            if(!ugFYakuza.checkUserBatchBalance(_msgSender(), _tokenIds)) revert InvalidTokenId();
        } else if(!ugArena.verifyAllStakedByUser(_msgSender(), _tokenIds) ) revert InvalidTokenId();
  
        uint256[] memory fighters = ugFYakuza.getPackedFighters(_tokenIds);

        // calc blood cost
        for(uint256 i = 0; i < _tokenIds.length; i++){  
            //check to make sure not Yakuza
            if(unPackFighter(fighters[i]).isFighter){
                totalBloodCost += getFighterLevelUpBloodCost(unPackFighter(fighters[i]).level, _levelsToUpgrade[i]);
                _levelsToUpgrade[i] += unPackFighter(fighters[i]).level ;
            }
        }
        burnBlood(_msgSender(), totalBloodCost);

        // Claim $BLOOD before level up to prevent issues where higher levels would improve the whole staking period instead of just future periods
        // This also resets the stake and staking period
        //skip claiming if claimall within last 24 hours
        if (_isStaked && block.timestamp >  ugArena.getOwnerLastClaimAllTime(_msgSender()) + 1 days) {
            ugArena.claimManyFromArena(_tokenIds, false);
        }
        //level up fighters
        ugFYakuza.levelUpFighters(_tokenIds, _levelsToUpgrade);
        
    }

    function levelUpRing(
        uint256 tokenId, 
        uint256 _levelsToUpgrade        
    ) external whenNotPaused nonReentrant onlyEOA returns (uint256 totalBloodCost) {
        IUGNFT.RingAmulet memory ring;
        address account = _msgSender();
        uint256 numStakedFighters = ugArena.numUserStakedFighters(account);
        uint256 userStakedRingId = ugArena.getStakedRingIDForUser(account); 
        uint256 userStakedAmuletId = ugArena.getStakedAmuletIDForUser(account);   
        //ring must be staked to ARENA
        if(userStakedRingId != tokenId) revert InvalidTokenId();
        //get ring and amulet
        ring = ugNFT.getRingAmulet(tokenId);
        if(ring.level + _levelsToUpgrade >= 10 && userStakedAmuletId == 0) revert InvalidLevel();
        
        //must have minimum number of staked fighters
        if(numStakedFighters < (ring.level + _levelsToUpgrade) * MIN_FIGHTERS_PER_RING) revert NeedMoreFighters(); 
           
        totalBloodCost = getRingLevelUpBloodCost(ring.level, _levelsToUpgrade, numStakedFighters);

        burnBlood(account, totalBloodCost);
        // Claim $BLOOD before level up to prevent issues where higher levels would improve the whole staking period instead of just future periods
        //claim if a claim all hasnt been made in 24 hours
        // This also resets the stake and staking period
        if (block.timestamp > ugArena.getOwnerLastClaimAllTime(account) + 1 days) {
            //get staked fighters
            uint256[] memory stakedFighterIdsToClaim = ugArena.getStakedFighterIDsForUser(account);
            ugArena.claimManyFromArena(stakedFighterIdsToClaim, false );
            ugArena.setOwnerLastClaimAllTime(account);
        }
        //level up rings
        ugNFT.levelUpRingAmulets(tokenId, ring.level + _levelsToUpgrade);
        
    }

    //required to send in id of all staked fighters to reduce gas. 
    //this array can be retrieved externally from ugArena contract
    //using function ugArena.getStakedFighterIDsForUser(account)
    function levelUpAmulet(
        uint256 tokenId, 
        uint256 _levelsToUpgrade
    ) external whenNotPaused nonReentrant onlyEOA returns (uint256 totalBloodCost) {
        IUGNFT.RingAmulet memory amulet;
        address account = _msgSender();
        uint256 numStakedFighters = ugArena.numUserStakedFighters(account);
        uint256 userStakedAmuletId = ugArena.getStakedAmuletIDForUser(account);        
        //ring must be staked to ARENA
        if(userStakedAmuletId != tokenId) revert InvalidTokenId();
        //get amulet
        amulet = ugNFT.getRingAmulet(tokenId);
        
        if(numStakedFighters < (amulet.level + _levelsToUpgrade) * MIN_FIGHTERS_PER_AMULET) revert NeedMoreFighters(); 
           
        totalBloodCost = getAmuletLevelUpBloodCost(amulet.level, _levelsToUpgrade, numStakedFighters);

        burnBlood(account, totalBloodCost);
        // Claim $BLOOD before level up to prevent issues where higher levels would improve the whole staking period instead of just future periods
        // claim if a claim all hasnt been made in 24 hours
        // This also resets the stake and staking period
        if (block.timestamp > ugArena.getOwnerLastClaimAllTime(account) + 1 days) {
            //get staked fighters
            uint256[] memory stakedFighterIdsToClaim = ugArena.getStakedFighterIDsForUser(account);
            ugArena.claimManyFromArena(stakedFighterIdsToClaim, false );
            ugArena.setOwnerLastClaimAllTime(account);
        }
        //level up amulet
        ugNFT.levelUpRingAmulets(tokenId, amulet.level + _levelsToUpgrade);
    }

    function levelUpFightClubs(
        uint256[] calldata tokenIds, 
        uint256[] memory _upgradeLevels, 
        uint256[] memory _upgradeSizes
    ) external whenNotPaused nonReentrant onlyEOA returns (uint256 totalBloodCost) {   
        if(tokenIds.length != _upgradeLevels.length) revert MismatchArrays(); 
        if(tokenIds.length != _upgradeSizes.length) revert MismatchArrays(); 
        IUGNFT.ForgeFightClub memory fclub;
        for(uint i; i< tokenIds.length; i++){
            fclub  = ugNFT.getForgeFightClub(tokenIds[i]);
            if(_upgradeSizes[i] > 1 || (_upgradeSizes[i] == 1 && fclub.size == FIGHT_CLUB_MAX_SIZE)) revert MaxSizeAllowed();
            if(_upgradeLevels[i] > 1 || (_upgradeLevels[i] == 1 && fclub.level == FIGHT_CLUB_MAX_LEVEL)) revert MaxLevelAllowed();
            totalBloodCost += getFightClubLevelUpBloodCost(fclub.level, fclub.size,  _upgradeLevels[i] == 1 ? 1 : 0, _upgradeSizes[i] == 1 ? 1 : 0);
            
            if(_upgradeLevels[i] == 1) fclub.level += 1;
            if(_upgradeSizes[i] == 1) fclub.size += 1;
            // add to fightclub ques for new levelTiers and sizeTiers if staked
            if(fclub.owner == address(ugRaid) && (_upgradeLevels[i] == 1|| _upgradeSizes[i] == 1)){
                
                ugRaid.addFightClubToQueueAfterLevelSizeUp(tokenIds[i],  _upgradeSizes[i] == 1 ? 1 : 0, _upgradeLevels[i] == 1 ? 1 : 0, fclub);
            }            
            _upgradeLevels[i] = fclub.level;
            _upgradeSizes[i] = fclub.size;
        }  
              
        burnBlood(_msgSender(), totalBloodCost);
        //level up fight clubs
        ugNFT.levelUpFightClubsForges(tokenIds,  _upgradeSizes, _upgradeLevels)[0];
         
    }

    function levelUpForges(uint256[] calldata tokenIds, uint256[] memory _levelsToUpgrade) 
        external whenNotPaused nonReentrant onlyEOA returns (uint256 totalBloodCost) 
    {   
        //forge size = weapon type, size 1 = knuckles
        if(tokenIds.length != _levelsToUpgrade.length) revert MismatchArrays(); 
        IUGNFT.ForgeFightClub[] memory forges = ugNFT.getForgeFightClubs(tokenIds);
        uint256[] memory sizes = new uint256[](tokenIds.length);
        uint newLevel;
        uint totalLevels;
        for(uint i; i< tokenIds.length; i++){
            newLevel = forges[i].level + _levelsToUpgrade[i];
            //check to make sure level does not violate size
            if(newLevel > FORGE_MAX_LEVEL) revert InvalidLevel();
            if(forges[i].size == 1 && newLevel > 7) revert MustUpgradeSize();
            if(forges[i].size == 2 && newLevel > 14) revert MustUpgradeSize();
            if(forges[i].size == 3 && newLevel > 21) revert MustUpgradeSize();
            if(forges[i].size == 4 && newLevel > 28) revert MustUpgradeSize();
            
            totalBloodCost += getForgeLevelUpBloodCost(forges[i].level, forges[i].size,  _levelsToUpgrade[i]);
           
            if(totalBloodCost == 0) revert BloodError();
            totalLevels += _levelsToUpgrade[i];
            //create size array of 0s
            sizes[i] = 0;
            _levelsToUpgrade[i] = newLevel;
            //tally total levels
            
           
        }        
        burnBlood(_msgSender(), totalBloodCost);
        //level up forges, returns upgraded forge
        ugForgeSmith.claimAllStakingRewards(_msgSender());
        ugForgeSmith.addToTotalForgeLevelStaked(totalLevels);
        ugNFT.levelUpFightClubsForges(tokenIds, sizes, _levelsToUpgrade);
    }

    function sizeUpForges(uint256[] calldata tokenIds) 
        external whenNotPaused nonReentrant onlyEOA returns (uint256 totalBloodCost) 
    {   
        //forge size = weapon type, size 1 = knuckles
        IUGNFT.ForgeFightClub[] memory forges = ugNFT.getForgeFightClubs(tokenIds);        
        uint256[] memory sizes = new uint256[](tokenIds.length);        
        uint256[] memory levels = new uint256[](tokenIds.length);
        for(uint i; i< tokenIds.length; i++){
            //make sure forge is required level for upgrade
            if(forges[i].size == 1 && forges[i].level < 7) revert MustUpgradeLevel();
            if(forges[i].size == 2 && forges[i].level < 14) revert MustUpgradeLevel();
            if(forges[i].size == 3 && forges[i].level < 21) revert MustUpgradeLevel();
            if(forges[i].size == 4 && forges[i].level < 28) revert MustUpgradeLevel();
            
            totalBloodCost += getForgeSizeUpBloodCost(forges[i].size);
            sizes[i] = forges[i].size + 1;
            levels[i] = 0;
            
        }        
        burnBlood(_msgSender(), totalBloodCost);
        //claim previous weapons
        ugForgeSmith.claimAllStakingRewards(_msgSender());
        //size up forge
        ugNFT.levelUpFightClubsForges(tokenIds, sizes, levels);
    }

    function getForgeLevelUpBloodCost(
        uint256 currentLevel, 
        uint256 currentSize, 
        uint256 levelsToUpgrade
    ) public view returns (uint256 totalBloodCost) {  

        //forge size = weapon type, size 1 = knuckles
        if(currentLevel == 0 && levelsToUpgrade == 0) revert InvalidLevel();
        totalBloodCost = 0;

        if (levelsToUpgrade == 0) totalBloodCost = _getForgeBloodCostPerLevel(currentLevel, currentSize);
            else if (levelsToUpgrade > 0){
                for (uint8 i = 1; i <= levelsToUpgrade; i++) {
                    totalBloodCost += _getForgeBloodCostPerLevel(currentLevel + i, currentSize);           
                }
            } 
        if(totalBloodCost == 0) revert BloodError();

        if(FORGE_LEVEL_COST_ADJUSTMENT_PCT != 100){
            //inflation adjustment logic
            return (totalBloodCost* FORGE_LEVEL_COST_ADJUSTMENT_PCT / 100  );
        }
        //inflation adjustment logic
        return totalBloodCost ;
    }

    function getForgeSizeUpBloodCost(uint16 currentSize) public view returns (uint256 totalBloodCost) {   
        //forge size = weapon type, size 1 = knuckles
        totalBloodCost = _getForgeBloodCostPerSize(currentSize + 1);
        if(totalBloodCost == 0) revert BloodError();
        if(FORGE_SIZE_COST_ADJUSTMENT_PCT != 100){
            //inflation adjustment logic
            return (totalBloodCost* FORGE_SIZE_COST_ADJUSTMENT_PCT / 100  );
        }
        return totalBloodCost ;
    }

    function _getForgeBloodCostPerLevel(uint256 level, uint256 size) private view returns (uint256 price) {
        //forge size = weapon type, size 1 = knuckles
        if (size == 0 || size > FORGE_MAX_SIZE) revert InvalidSizes();
        if (level == 0 || level > FORGE_MAX_LEVEL) revert InvalidLevel();
        if(level % 7 == 0){
            return (FORGE_BASE_LEVEL_COST*(2**(size-1)) * 7);
        }
        return (FORGE_BASE_LEVEL_COST*(2**(size-1)) * (level % 7));
    }

    function _getForgeBloodCostPerSize(uint256 size) private view returns (uint256 price) {
        if (size == 0 || size > FORGE_MAX_SIZE) revert InvalidSizes();
        return (FORGE_BASE_SIZE_COST*(2**(size-1)));
    }

    function getFightClubLevelUpBloodCost(uint16 currentLevel, uint16 currentSize, uint8 levelsToUpgrade, uint8 sizesToUpgrade) 
        public view returns (uint256 totalBloodCost) 
    {
        require(currentLevel >= 0, "Game: Invalid currentLevel");
        require(currentSize >= 0, "Game: Invalid currentSize");
        totalBloodCost = 0;

        if (levelsToUpgrade == 0 && sizesToUpgrade == 0) totalBloodCost = _getFightClubBloodCostPerLevel(currentLevel, currentSize);
        else if (levelsToUpgrade == 1){
            if(sizesToUpgrade == 1){
                totalBloodCost += _getFightClubBloodCostPerLevel(currentLevel + 1, currentSize + 1);
            } else{
                totalBloodCost += _getFightClubBloodCostPerLevel(currentLevel + 1, currentSize);
            }                   
            
        } else {//if only size is being upgraded  
            totalBloodCost += _getFightClubBloodCostPerLevel(currentLevel, currentSize + 1);                    
        }

        if(totalBloodCost == 0) revert BloodError();

        if(FIGHTCLUB_LEVEL_COST_ADJUSTMENT_PCT != 100){
            //inflation adjustment logic
            return (totalBloodCost* FIGHTCLUB_LEVEL_COST_ADJUSTMENT_PCT / 100 );
        }
        //inflation adjustment logic
        return totalBloodCost ;
    }

    function getSizeTier(uint8 size) private pure returns (uint8) {
        return size/5;
    }

    //levelTiers 1 = (1-3), 2 = (4-6), 3 = (7-9), maxLevel at each tier = levelTier * 3
    function getLevelTier(uint8 level) private pure returns (uint8) {
        if(level == 0) return 0;
        return (level-1)/3 + 1;
    }

    function _getFightClubBloodCostPerLevel(uint256 level, uint256 size) private view returns (uint256 price) {
        if (level == 0 || size == 0) return 0;
        return ((FIGHT_CLUB_BASE_LEVEL_COST + FIGHT_CLUB_BASE_LEVEL_COST*level)*5*(2**(size-1)));
    }

    function _getFighterBloodCostPerLevel(uint16 level) private view returns (uint256 price) {
        if (level == 0) return 0;        
        return (2*FIGHTER_BASE_LEVEL_COST + FIGHTER_BASE_LEVEL_COST*((level-1)**2));
    }

    function getFighterLevelUpBloodCost(uint16 currentLevel, uint256 levelsToUpgrade) public view  returns (uint256 totalBloodCost) {
        if(levelsToUpgrade == 0) revert InvalidLevel();

        totalBloodCost = 0;

        for (uint16 i = 1; i <= levelsToUpgrade; i++) {
        totalBloodCost += _getFighterBloodCostPerLevel(currentLevel + i);
        }
        if(totalBloodCost == 0) revert BloodError();

        if(FIGHTER_LEVEL_COST_ADJUSTMENT_PCT != 100){
            //inflation adjustment logic
            return (totalBloodCost * FIGHTER_LEVEL_COST_ADJUSTMENT_PCT / 100);
        }
        return totalBloodCost ;
    }

    function getRingLevelUpBloodCost(uint16 currentLevel, uint256 levelsToUpgrade, uint256 numFighters) public view  returns (uint256 totalBloodCost) {
        if(currentLevel == 0) revert InvalidLevel();
       
        totalBloodCost = 0;

        if (levelsToUpgrade == 0) totalBloodCost = _getRingBloodCostPerLevel(currentLevel, numFighters);
            else{
                for (uint16 i = 1; i <= levelsToUpgrade; i++) {
                    totalBloodCost += _getRingBloodCostPerLevel(currentLevel + i, numFighters);
                }
            }    
        if(totalBloodCost == 0) revert BloodError();

        if(RING_LEVEL_COST_ADJUSTMENT_PCT != 100){
            //inflation adjustment logic
            return (totalBloodCost* RING_LEVEL_COST_ADJUSTMENT_PCT / 100  );
        }
        //inflation adjustment logic
        return totalBloodCost ;
    }

    function _getRingBloodCostPerLevel(uint16 level, uint256 numFighters) private view returns (uint256 price) {
        if (level == 0) return 0;
        price = (RING_BASE_LEVEL_COST + RING_BASE_LEVEL_COST*((level - 1)**2)) ;
        //adjust based on number of fighters
        price += price * numFighters/200;
        return price;
    }
    
    function getAmuletLevelUpBloodCost(uint16 currentLevel, uint256 levelsToUpgrade, uint256 numFighters) public view  returns (uint256 totalBloodCost) {
        if(currentLevel == 0) revert InvalidLevel();
        
        totalBloodCost = 0;

        if (levelsToUpgrade == 0) totalBloodCost = _getAmuletBloodCostPerLevel(currentLevel, numFighters);
            else{
                for (uint16 i = 1; i <= levelsToUpgrade; i++) {
                    totalBloodCost += _getAmuletBloodCostPerLevel(currentLevel + i, numFighters);
                }
            }
        if(totalBloodCost == 0) revert BloodError();

        if(AMULET_LEVEL_COST_ADJUSTMENT_PCT != 100){
            //inflation adjustment logic
            return (totalBloodCost  * AMULET_LEVEL_COST_ADJUSTMENT_PCT / 100);
        }
        //inflation adjustment logic
        return totalBloodCost;
    }

    function _getAmuletBloodCostPerLevel(uint16 level, uint256 numFighters) private view returns (uint256 price) {
        if (level == 0) return 0;
        price = (AMULET_BASE_LEVEL_COST + AMULET_BASE_LEVEL_COST*((level - 1)**2)) ;
        price += price * numFighters/200;
    }

    function burnBlood(address account, uint256 amount) private {
        uBlood.burn(account, amount * 1 ether);
        //allocate 10% of all burned blood to dev wallet for continued development
        uBlood.mint(devWallet, amount * 1 ether /10 );
        emit BloodBurned(block.timestamp, amount*90/100);
    }

    function unPackFighter(uint256 packedFighter) private pure returns (IUGFYakuza.FighterYakuza memory) {
        IUGFYakuza.FighterYakuza memory fighter;   
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

    /** OWNER ONLY FUNCTIONS */
    function setContracts(address _uBlood, address _ugFYakuza, address _ugNFT, address _ugArena, address _ugForgeSmith) external onlyOwner {
        uBlood = IUBlood(_uBlood);
        ugFYakuza = IUGFYakuza(_ugFYakuza);
        ugNFT = IUGNFT(_ugNFT);
        ugArena = IUGArena(_ugArena);
        ugForgeSmith = IUGForgeSmith(_ugForgeSmith);
    }
    
    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    function setMaxFightClubsPerMint(uint256 amt) external onlyOwner {
        MAXIMUM_FIGHTCLUBS_PER_MINT = amt;
    }

    function setMaxFightClubsPerWallet(uint256 amt) external onlyOwner {
        MAXIMUM_FIGHTCLUBS_PER_WALLET = amt;
    }

    function setFighterBaseLevelCost(uint256 newCost) external onlyOwner {
        FIGHTER_BASE_LEVEL_COST = newCost;
    }

    function setRingBaseLevelCost(uint256 newCost) external onlyOwner {
        RING_BASE_LEVEL_COST = newCost;
    }

    function setAmuletBaseLevelCost(uint256 newCost) external onlyOwner {
        AMULET_BASE_LEVEL_COST = newCost;
    }

    function setFightClubBaseLevelCost(uint256 newCost) external onlyOwner {
        FIGHT_CLUB_BASE_LEVEL_COST = newCost;
    }

    function setForgeBaseLevelCost(uint256 newCost) external onlyOwner {
        FORGE_BASE_LEVEL_COST = newCost;
    }

    function setForgeBaseSizeCost(uint256 newCost) external onlyOwner {
        FORGE_BASE_SIZE_COST = newCost;
    }

    function setFighterLevelCostAdjustmentPct(uint16 pct) external onlyOwner {
        FIGHTER_LEVEL_COST_ADJUSTMENT_PCT = pct;
    }

    function setRingLevelCostAdjustmentPct(uint16 pct) external onlyOwner {
        RING_LEVEL_COST_ADJUSTMENT_PCT = pct;
    }

    function setAmuletLevelCostAdjustmentPct(uint16 pct) external onlyOwner {
        AMULET_LEVEL_COST_ADJUSTMENT_PCT = pct;
    }
    

    function setFightClubLevelCostAdjustmentPct(uint16 pct) external onlyOwner {
        FIGHTCLUB_LEVEL_COST_ADJUSTMENT_PCT = pct;
    }

    function setMaximumBloodSupply(uint256 number) external onlyOwner {
        MAXIMUM_BLOOD_SUPPLY = number;
    }

    function setForgeMintActive(bool active) external onlyOwner {
        FORGE_MINT_ACTIVE = active;
    }

    function setFightClubMintActive(bool active) external onlyOwner {
        FIGHTCLUB_MINT_ACTIVE = active;
    }

    function setRingMintActive(bool active) external onlyOwner {
        RING_MINT_ACTIVE = active;
    }

    function setAmuletMintActive(bool active) external onlyOwner {
        AMULET_MINT_ACTIVE = active;
    }

    function setRingBloodMintCost(uint256 number) external onlyOwner {
        RING_BLOOD_MINT_COST = number;
    }

    function setAmuletBloodMintCost(uint256 number) external onlyOwner {
        AMULET_BLOOD_MINT_COST = number;
    }

    function setFightClubBloodMintCost(uint256 number) external onlyOwner {
        FIGHTCLUB_BLOOD_MINT_COST = number;
    }

    function setForgeBloodMintCost(uint256 number) external onlyOwner {
        FORGE_BLOOD_MINT_COST = number;
    }

    function setDevWallet(address newWallet) external onlyOwner {
        devWallet = newWallet;
    }
    
    function setWithdrawAddress(address addr) external onlyOwner {
        if(addr == address(0)) revert InvalidAddress();
        WITHDRAW_ADDRESS = addr;
    }
    
    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = WITHDRAW_ADDRESS.call{value: amount}("");
        require(sent, "Game: Failed to send funds");
    }
}