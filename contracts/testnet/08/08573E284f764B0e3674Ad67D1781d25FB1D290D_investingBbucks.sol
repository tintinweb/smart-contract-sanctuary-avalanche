//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./bbucksToken.sol";
import "./bbbStaking.sol";
import "../Authorizable.sol";
import "./supplyToken.sol";
contract investingBbucks is Ownable, Authorizable, ReentrancyGuard{
    using SafeMath for uint256;

    uint256 public MAX_SUPPLY = 32000000000 * 1 ether;


    IERC721 public BADBIZBONES_CONTRACT;
    bbucks public BBUCKS_CONTRACT;
    supply public SUPPLY_CONTRACT;
    bbbStaking public STAKING_BBBS_CONTRACT;

    uint256 public FACTORY_PRICE= 250 ether;
    uint256 private stoneFactory = 1;
    uint256 private bronzeFactory = 2;
    uint256 private silverFactory = 3;
    uint256 private goldFactory = 4;
    uint256 private platinumFactory = 5;

    uint256 public BOOSTER_MULTIPLIER = 1;
    uint256 public BBUCKS_FARMING_FACTOR = 150; 
    uint256 public SUPPLY_SWAP_FACTOR = 20; 

    event Minted(address owner, uint256 numberOfSupply);
    event Burned(address owner, uint256 numberOfSupply);
    event BbucksSwap(address owner, uint256 numberOfSupply);

    event MintedBbucks(address owner, uint256 numberOfSupply);
    event BurnedBbucks(address owner, uint256 numberOfBbucks);
    event StakedBbucks(address owner, uint256 numberOfBbucks);
    event UnstakedBbucks(address owner, uint256 numberOfBbucks);


    struct BbucksStake {
        address user;
        uint32 since;
        uint256 amount;
    }

    mapping(address => BbucksStake) public BbucksStakeHolders;
    uint256 public totalBbucksStaked;
    address[] public _allBbucksStakeHolders;
    mapping(address => uint256) private _allBbucksStakeHoldersIndex;

    event BbucksStaked(address user, uint256 amount);
    event BbucksUnStaked(address user, uint256 amount);

    
    constructor(
        address _badbizbonesContract,
        address _bbucksContract,
        address _supplyContract,
        address stakingBadbizbonesContract
    ){
        BADBIZBONES_CONTRACT = IERC721(_badbizbonesContract);
        BBUCKS_CONTRACT = bbucks(_bbucksContract);
        SUPPLY_CONTRACT = supply(_supplyContract);
        STAKING_BBBS_CONTRACT = bbbStaking(stakingBadbizbonesContract);
    }


    function _upsertPieStaking(address user, uint256 amount) internal {

        require(user != address(0), "EMPTY ADDRESS");
        BbucksStake memory bucks = BbucksStakeHolders[user];


        if (bucks.user == address(0)) {

            _allBbucksStakeHoldersIndex[user] = _allBbucksStakeHolders.length;
            _allBbucksStakeHolders.push(user);
        }
        uint256 previousBbucks = bucks.amount;

        bucks.user = user;
        bucks.amount = amount;
        bucks.since = uint32(block.timestamp);

        BbucksStakeHolders[user] = bucks;
        totalBbucksStaked = totalBbucksStaked - previousBbucks + amount;
        emit BbucksStaked(user, amount);
    }

    function stakeBbucks(uint256 amount) external {
        require(amount > 0, "NEED BBUCKS");

        uint256 available = BBUCKS_CONTRACT.balanceOf(msg.sender);
        require(available >= amount, "NOT ENOUGH BBUCKS");
        BbucksStake memory existingBbucks = BbucksStakeHolders[msg.sender];
        if (existingBbucks.amount > 0) {

            uint256 projection = claimableView(msg.sender);

            BBUCKS_CONTRACT.mint(msg.sender, projection);
            emit MintedBbucks(msg.sender, amount);
            _upsertPieStaking(msg.sender, existingBbucks.amount + amount);
        } else {

            _upsertPieStaking(msg.sender, amount);
        }
        BBUCKS_CONTRACT.burn(msg.sender, amount);
        emit StakedBbucks(msg.sender, amount);
    }


    function claimableView(address user) public view returns (uint256) {
        BbucksStake memory bucks = BbucksStakeHolders[user];
        require(bucks.user != address(0), "NOT STAKED");
        return
            ((bucks.amount * BBUCKS_FARMING_FACTOR/100) *
                (((block.timestamp - bucks.since) * 1 ether) / 86400) *
                BOOSTER_MULTIPLIER) / 1 ether;
    }


    function withdrawBbucks(uint256 amount) external {
        require(amount > 0, "MUST BE MORE THAN 0");
        BbucksStake memory bucks = BbucksStakeHolders[msg.sender];
        require(bucks.user != address(0), "NOT STAKED");
        require(amount <= bucks.amount, "OVERDRAWN");

        _upsertPieStaking(msg.sender, bucks.amount - amount);

        uint256 afterBurned = (amount * 11) / 12;

        BBUCKS_CONTRACT.mint(msg.sender, afterBurned);
        emit UnstakedBbucks(msg.sender, afterBurned);
    }


    function claimBbucks() external {
        uint256 projection = claimableView(msg.sender);
        require(projection > 0, "NO BBUCKS TO CLAIM");

        BbucksStake memory bucks = BbucksStakeHolders[msg.sender];

       
        _upsertPieStaking(msg.sender, bucks.amount);


        _mintBbucks(msg.sender, projection);
    }


    function _removeUserFromBbucksEnumeration(address user) private {
        uint256 lastUserIndex = _allBbucksStakeHolders.length - 1;
        uint256 currentUserIndex = _allBbucksStakeHoldersIndex[user];

        address lastUser = _allBbucksStakeHolders[lastUserIndex];

        _allBbucksStakeHolders[currentUserIndex] = lastUser;
        _allBbucksStakeHoldersIndex[lastUser] = currentUserIndex; 

        delete _allBbucksStakeHoldersIndex[user];
        _allBbucksStakeHolders.pop();
    }


    function withdrawAllBbucksAndClaim() external {
        BbucksStake memory bucks = BbucksStakeHolders[msg.sender];


        require(bucks.user != address(0), "NOT STAKED");


        uint256 projection = claimableView(msg.sender);
        if (projection > 0) {

            _mintBbucks(msg.sender, projection);
        }

        if (bucks.amount > 0) {

            uint256 afterBurned = (bucks.amount * 11) / 12;
            bbucks bbucksContract = BBUCKS_CONTRACT;
            bbucksContract.mint(msg.sender, afterBurned);
            emit UnstakedBbucks(msg.sender, afterBurned);
        }
        _unstakingBbucks(msg.sender);
    }


    function _unstakingBbucks(address user) internal {
        BbucksStake memory bucks = BbucksStakeHolders[user];
        require(bucks.user != address(0), "EMPTY ADDRESS");
        totalBbucksStaked = totalBbucksStaked - bucks.amount;
        _removeUserFromBbucksEnumeration(user);
        delete BbucksStakeHolders[user];
        emit BbucksUnStaked(user, bucks.amount);
    }


    function supplyBiz(uint256 bbbId, uint256 amount) external {

        require(amount > 0, "MUST BE MORE THAN 0 SUPPLY");

        IERC721 instance = IERC721(BADBIZBONES_CONTRACT);

        require(instance.ownerOf(bbbId) == msg.sender, "NOT OWNER");


    
        require(
            SUPPLY_CONTRACT.balanceOf(msg.sender) >= amount,
            "NOT ENOUGH SUPPLIES"
        );


        (uint256 lvl, , , ) = STAKING_BBBS_CONTRACT.stakedBBBs(
            bbbId
        );
        require(lvl > 0, "NOT STAKED");


        SUPPLY_CONTRACT.burn(msg.sender, amount);
        emit Burned(msg.sender, amount);

        STAKING_BBBS_CONTRACT.levelUpBiz(bbbId, amount);
    }

    function swapBbucksForSupply(uint256 bbucksAmt) external {
        require(bbucksAmt > 0, "MUST BE MORE THAN 0 BBUCKS");
        bbucks bbucksContract = bbucks(BBUCKS_CONTRACT);
        bbucksContract.burn(msg.sender, bbucksAmt);

        SUPPLY_CONTRACT.mint(msg.sender, bbucksAmt * SUPPLY_SWAP_FACTOR);
        emit BbucksSwap(msg.sender, bbucksAmt * SUPPLY_SWAP_FACTOR);
    }


    function _mintBbucks(address sender, uint256 bbucksAmount) internal {

        BBUCKS_CONTRACT.mint(sender, bbucksAmount);
        emit Minted(sender, bbucksAmount);
    }

    // ADMIN FUNCTIONS


    function mintSupply(address sender, uint256 amount) external onlyOwner {
        SUPPLY_CONTRACT.mint(sender, amount);
    }

 
    function updateBoosterMultiplier(uint256 _value) external onlyOwner {
        BOOSTER_MULTIPLIER = _value;
    }


    function updateFarmingFactor(uint256 _valueMul100) external onlyOwner {
        BBUCKS_FARMING_FACTOR = _valueMul100;
    }

   
    function updateSupplySwapFactor(uint256 _value) external onlyOwner {
        SUPPLY_SWAP_FACTOR = _value;
    }


    function updateMaxSupply(uint256 _value) external onlyOwner {
        MAX_SUPPLY = _value;
    }


    function totalBbucksHolder() public view returns (uint256) {
        return _allBbucksStakeHolders.length;
    }


    function getBbucksHolderByIndex(uint256 index)
        internal
        view
        returns (address)
    {
        return _allBbucksStakeHolders[index];
    }


    function rebalanceStakingPool(uint256 from, uint256 to) external onlyOwner {

        for (uint256 i = from; i <= to; i++) {
            address holderAddress = getBbucksHolderByIndex(i);

            uint256 pendingClaim = claimableView(holderAddress);
            BbucksStake memory bucks = BbucksStakeHolders[holderAddress];


            BBUCKS_CONTRACT.mint(holderAddress, pendingClaim);
            emit MintedBbucks(holderAddress, pendingClaim);

            _upsertPieStaking(holderAddress, bucks.amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../Authorizable.sol";

contract bbucks is Ownable, Pausable, Authorizable, ERC20{
    constructor() ERC20("BoneBucks", "BBucks"){
        
    }
   

    function mint(address to, uint256 amount) public onlyAuthorized{
        _mint(to, amount);
    }
     function burn(address from, uint256 amount)public {
        _burn(from, amount);
     }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./bbucksToken.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract bbbStaking is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    //reminder
    // uint8 (0 - 255)
    // uint16 (0 - 65535)
    // uint24 (0 - 16,777,216)
    // uint32 (0 - 4,294,967,295)
    // uint40 (0 - 1,099,511,627,776)
    // unit48 (0 - 281,474,976,710,656)
    // uint256 (0 - 1.157920892e77)

    bbucks public immutable bbucksToken;
    IERC721 public immutable badbizbones;

    uint256 public totalLvl;
    uint16 public totalWorkingBBBs;

    uint256 public BASE_BBUCKS_RATE = 1 ether;
    uint256 public BBUCKS_PER_DAY_PER_LVL = 10 ether; 
    uint256 public COOLDOWN_BASE_SKIP = 100 ether;

    uint256 public BIZ_LVL_UP_COST = 100;
    uint256 public LVL_UP_RATE = 2;
    uint256 public COOLDOWN_RATE = 3600;

    struct stakedBBBStruct{
        uint256 level;
        uint32 clockInTs;
        uint256 suppliedAmount;
        uint32 lvlUpCooldown;
    }
    struct BBBDetails{
        uint16 tokenId;
        uint256 level;
    }
    stakedBBBStruct[3000] public stakedBBBs;
    mapping(uint256 => BBBDetails) public allBBBDetails;

    event Minted(address owner, uint256 bbucksAmount);
    event Burned(address owner, uint256 bbucksAmount);
    event Staked(uint256 tokenId, uint256 ts);
    event UnStaked(uint256 tokenId, uint256 ts);
    event LevelUp(uint256 bizId, uint256 newLvl);
    event NameChange(uint256 bbbNumber, string name);

    constructor(IERC721 _bbb, bbucks _bbucks){
        badbizbones = IERC721(_bbb);
        bbucksToken = bbucks(_bbucks);
    }

    function supplyLevelingRate(uint256 lvl) public view returns (uint256) {
        return BIZ_LVL_UP_COST * (lvl**LVL_UP_RATE);
    }

    function cooldownRate(uint256 lvl) public view returns (uint256) {
        return lvl * COOLDOWN_RATE;
    }

    function _setLvl(uint256 _tokenId, uint256 _newLvl) internal {
        BBBDetails memory bbb = allBBBDetails[_tokenId];
        bbb.level = _newLvl;
        allBBBDetails[_tokenId] = bbb;
    }
    function setLvl(uint256 _tokenId, uint256 _newLvl)
        external
        onlyOwner
    {
        _setLvl(_tokenId, _newLvl);
    }
    function _stake(uint256 tid) internal {

        // verify user is the owner of the pumpskin...
        require(badbizbones.ownerOf(tid) == msg.sender, "NOT OWNER");
        BBBDetails memory x = allBBBDetails[tid];

        if (x.level <= 0) {
            x.level = 1;
            allBBBDetails[tid] = x;
        }

        uint32 ts = uint32(block.timestamp);

        if (stakedBBBs[tid].level == 0) {
            // create staked pumpskin...
            stakedBBBs[tid] = stakedBBBStruct(
                uint24(x.level),
                ts,
                uint48(0),
                uint32(ts) + uint32(cooldownRate(0))
            );

            totalWorkingBBBs += 1;
            totalLvl += uint24(x.level);

            emit Staked(tid, block.timestamp);
        }
    }
   
    function stake(uint256[] calldata tids) external nonReentrant {
        for (uint256 i = 0; i < tids.length; i++) {
            _stake(tids[i]);
        }
    }

    function claimableView(uint256 tokenId) public view returns (uint256) {
        stakedBBBStruct memory b = stakedBBBs[tokenId];
        if (b.level > 0) {
            uint256 bbucksPerDay = ((BBUCKS_PER_DAY_PER_LVL * b.level ) +
                BASE_BBUCKS_RATE);
            uint256 deltaSeconds = block.timestamp - b.clockInTs;
            return deltaSeconds * (bbucksPerDay / 86400);
        } else {
            return 0;
        }
    }
    
    function getStakedTokens(address user)
        public
        view
        returns (uint256[] memory)
    {
        uint256 bbbCount = badbizbones.balanceOf(user);
        require(bbbCount > 0, "user doesn't own any badbizbones");

        uint256[] memory tokenIds = new uint256[](bbbCount);
        uint256 counter = 0;

        for (uint256 i = 0; i < stakedBBBs.length; i++) {
            stakedBBBStruct memory badbizbone = stakedBBBs[i];
            if (badbizbone.level > 0 && badbizbones.ownerOf(i) == user) {
                tokenIds[counter] = i;
                counter++;
            }
        }

        uint256[] memory returnTokenIds = new uint256[](counter);

        for (uint256 j = 0; j < counter; j++) {
            returnTokenIds[j] = tokenIds[j];
        }

        return returnTokenIds;
    }

    function myClaimableView(address user) public view returns (uint256) {


        uint256 bbbCount = badbizbones.balanceOf(user);
        require(bbbCount > 0, "you don't own any badbizbones");

        uint256 totalClaimable = 0;

        for (uint256 i = 0; i < stakedBBBs.length; i++) {

            stakedBBBStruct memory badbizbone = stakedBBBs[i];
            if (badbizbone.level > 0 && badbizbones.ownerOf(i) == user) {

                uint256 claimable = claimableView(i);
                if (claimable > 0) {
                    totalClaimable = totalClaimable + claimable;
                }
            }
        }

        return totalClaimable;
    }

    function _claimBbucks(uint256[] calldata tokenIds) internal {

        uint256 totalClaimableBbucks = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                badbizbones.ownerOf(tokenIds[i]) == msg.sender,
                "NOT OWNER"
            );
            stakedBBBStruct memory badbizbone = stakedBBBs[tokenIds[i]];

            if (badbizbone.level > 0) {
                uint256 claimableBbucks = claimableView(tokenIds[i]);
                if (claimableBbucks > 0) {
                    totalClaimableBbucks = totalClaimableBbucks + claimableBbucks;

                    badbizbone.clockInTs = uint32(block.timestamp);
                    stakedBBBs[tokenIds[i]] = badbizbone;
                }
            }
        }
        if (totalClaimableBbucks > 0) {
            bbucksToken.mint(msg.sender, totalClaimableBbucks);
            emit Minted(msg.sender, totalClaimableBbucks);
        }
    }
    function claimPies(uint256[] calldata tokenIds) external {
        _claimBbucks(tokenIds);
    }

    function _unstake(uint256 tokenId) internal {


        require(badbizbones.ownerOf(tokenId) == msg.sender, "NOT OWNER");
        stakedBBBStruct memory b = stakedBBBs[tokenId];

        if (b.level > 0) {

            totalLvl -= uint24(b.level);
            totalWorkingBBBs -= 1;

            b.level = 0;
            stakedBBBs[tokenId] = b;


            emit UnStaked(tokenId, block.timestamp);
        }
    }
    function _unstakeMultiple(uint256[] calldata tids) internal {
        for (uint256 i = 0; i < tids.length; i++) {
            _unstake(tids[i]);
        }
    }
    function unstake(uint256[] calldata tids) external nonReentrant {
        _unstakeMultiple(tids);
    }
    function withdrawAllBbbsAndClaim(uint256[] calldata tids) external {
        _claimBbucks(tids);
        _unstakeMultiple(tids);
    }
    function levelUp(uint256 tid) external {
        stakedBBBStruct memory b = stakedBBBs[tid];
        require(b.level > 0, "NOT STAKED");


        require(b.suppliedAmount >= supplyLevelingRate(b.level), "MORE SUPPLIES REQUIRED");
        require(block.timestamp >= b.lvlUpCooldown, "COOLDOWN NOT MET");

        b.level = b.level + 1;
        b.suppliedAmount = 0;
        b.lvlUpCooldown = uint32(block.timestamp + cooldownRate(b.level));
        stakedBBBs[tid] = b;

        totalLvl += uint24(1);


        _setLvl(tid, b.level);
    }

    function _burnBbucks(address sender, uint256 bbucksAmount) internal {
        // NOTE do we need to check this before burn?
        require(bbucksToken.balanceOf(sender) >= bbucksAmount, "NOT ENOUGH BBUCKS");
        bbucksToken.burn(sender, bbucksAmount);
        emit Burned(sender, bbucksAmount);
    }

    function burnBbucks(address sender, uint256 bbucksAmount)
        external
        onlyOwner
    {
        _burnBbucks(sender, bbucksAmount);
    }

    function skipCoolingOff(uint256 tokenId, uint256 bbucksAmt) external {
        stakedBBBStruct memory badbizbone = stakedBBBs[tokenId];
        require(badbizbone.level != 0, "NOT STAKED");

        uint32 ts = uint32(block.timestamp);

        uint256 walletBalance = bbucksToken.balanceOf(msg.sender);
        require(walletBalance >= bbucksAmt, "NOT ENOUGH BBUCKS IN WALLET");

        // check: provided pie amount is enough to skip this level
        require(
            bbucksAmt >= checkSkipCoolingOffAmt(badbizbone.level),
            "NOT ENOUGH bbucks TO SKIP"
        );

        // burn pies
        _burnBbucks(msg.sender, bbucksAmt);

        // disable cooldown
        badbizbone.lvlUpCooldown = ts;
        stakedBBBs[tokenId] = badbizbone;
    }

    function checkSkipCoolingOffAmt(uint256 lvl) public view returns (uint256) {
        return (lvl * COOLDOWN_RATE);
    }

    function levelUpBiz(uint256 tokenId, uint256 supplyAmount)
        external
        onlyOwner
    {
        stakedBBBStruct memory badbizbone = stakedBBBs[tokenId];
        require(badbizbone.level > 0, "NOT STAKED");
        require(supplyAmount > 0, "NOTHING TO SUPPLY");
        badbizbone.suppliedAmount=
            uint48(supplyAmount / 1 ether) +
            badbizbone.suppliedAmount;
        stakedBBBs[tokenId] = badbizbone;
    }

    function updateSkipCooldownValues(
        uint256 _COOLDOWN_BASE,
        uint256 _COOLDOWN_RATE,
        uint256 _BASE_BBUCKS_RATE,
        uint256 _BBUCKS_PER_DAY_PER_LVL
    ) external onlyOwner {
        COOLDOWN_BASE_SKIP = _COOLDOWN_BASE;
        COOLDOWN_RATE = _COOLDOWN_RATE;
        BASE_BBUCKS_RATE = _BASE_BBUCKS_RATE;
        BBUCKS_PER_DAY_PER_LVL = _BBUCKS_PER_DAY_PER_LVL;
    }

    function airdropToExistingHolder(
        uint256 from,
        uint256 to,
        uint256 amountOfBbucks
    ) external onlyOwner {
        IERC721 instance = badbizbones;
        for (uint256 i = from; i <= to; i++) {
            address currentOwner = instance.ownerOf(i);
            if (currentOwner != address(0)) {
                bbucksToken.mint(currentOwner, amountOfBbucks * 1 ether);
            }
        }
    }
    function rebalanceBbucksClaimableToUserWallet(uint256 from, uint256 to)
        external
        onlyOwner
    {
        IERC721 instance = badbizbones;
        for (uint256 i = from; i <= to; i++) {
            address currentOwner = instance.ownerOf(i);
            stakedBBBStruct memory badbizbone = stakedBBBs[i];
            // we only care about pumpskin that have been staked (i.e. kg > 0) ...
            if (badbizbone.level > 0) {
                bbucksToken.mint(currentOwner, claimableView(i));
                badbizbone.clockInTs = uint32(block.timestamp);
                stakedBBBs[i] = badbizbone;
            }
        }
    }

    // add pumpskin naming service
    mapping(uint256 => string) public bns;

    function changeName(uint256 _tokenId, string memory name)
        external
        onlyOwner
    {
        bns[_tokenId] = name;
        emit NameChange(_tokenId, name);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../Authorizable.sol";

contract supply is Ownable, Pausable, Authorizable, ERC20{
    uint256 MAX_SUPPLY= 320000000000 ether;

    constructor() ERC20("Biz Supplies", "supply"){
        
    }
    function setMaxSupply(uint256 max) public onlyOwner{
        MAX_SUPPLY = max * 1 ether;
    }

    function mint(address to, uint256 amount) public onlyAuthorized{
        _mint(to, amount);
    }
     function burn(address from, uint256 amount)public {
        _burn(from, amount);
     }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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