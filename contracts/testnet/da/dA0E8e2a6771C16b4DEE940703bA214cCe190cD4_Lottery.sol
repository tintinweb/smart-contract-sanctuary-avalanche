// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IERC20Meta.sol";
import "./interfaces/INFT.sol";


contract Lottery is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20Meta;

    event LotteryAdded(uint indexed lid, uint indexed country, uint startTime, uint maxTokens);
    event LotteryRemoved(uint indexed lid);
    event LotteryRestarted(uint indexed lid);
    event LotteryFinished(uint indexed lid, uint indexed winner);

    event NFTStaked(address indexed owner, uint indexed lid, uint nftId);
    event NFTUnstaked(address indexed owner, uint nftId);
    event LockedNFTUnstaked(address indexed owner, uint indexed lid, uint nftId);
    event HybridStaked(address indexed owner, uint nftInd, uint amount);
    event EmergencyHybridUnstake(address indexed owner, uint nftId, uint amount);
    event TokensClaimed(uint indexed nftId, uint amount);
    event TokensBurned(uint indexed nftId, uint amount);

    INFT public immutable nft;
    IERC20Meta public immutable hybrid;
    address public treasury;

    struct Lot {
        uint country;           // between 1-5
        uint startTime;         // timestamp
        uint tokensBurned;      // 18 decimals
        uint maxTokens;         // 18 decimals
        uint winner;            // nft token id
        bool finished;
    }

    struct StakeInfo {
        address owner;
        uint nftId;
        uint lid;
        uint tokensBurned;      // 18 decimals
        uint hybridStaked;      // 18 decimals
        uint lastEarnTime;      // timestamp
    }

    struct Raffle {
        uint nftId;
        uint rarity;
        uint tokensBurned;
    }

    // index is lid
    Lot[] public lotteries;
    
    // nft token id -> stake data
    mapping(uint => StakeInfo) public nftStakeInfo;

    // lid -> staked nft token ids
    mapping(uint => uint[]) public nftStakedIds;
    // lid -> token id -> list index
    mapping(uint => mapping(uint => uint)) private nftStakedIndex;

    mapping(address => uint[]) public userNftStakedIds;
    mapping(address => mapping(uint => uint)) private userNftStakedIndex;


    uint public totalHybridStaked;
    uint public maxHybrid;
    uint public maxTokenBurn;

    uint private constant WHOLE = 1e18;
    uint private constant UNSTAKE_HYBRID_FEES = 1000;   // 4 decimals. 1000 = 10%. To avoid flash loan on claimTokens
    uint private constant EARN_DAILY = 1e18;         // 18 decimals. 1e18 = 1 token
    uint private constant HYBRID_EARN_DAILY = 1e4;    // division factor. 10000 hybrid = 1 token
    uint private constant COUNTRY_FACTOR = 150;      // 2 decimals. 150 = 1.5 times
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    modifier checkLid(uint _lid) {
        require(_lid < lotteries.length, "Invalid _lid");
        _;
    }

    modifier finished(uint _lid) {
        require(lotteries[_lid].finished, "Lottery Not Finished");
        _;
    }

    modifier ongoing(uint _lid) {
        require(block.timestamp >= lotteries[_lid].startTime, "Lottery Not Started");
        require(!lotteries[_lid].finished, "Lottery Finished");
        _;
    }

    constructor(address _nft, address _hybrid, address _treasury) {
        require(_nft != address(0), "Cannot be zero address");
        require(_hybrid != address(0), "Cannot be zero address");
        nft = INFT(_nft);
        hybrid = IERC20Meta(_hybrid);
        treasury = _treasury;

        maxHybrid = 10000e18;
        maxTokenBurn = 150e18;
    }

    /* OWNER FUNCTIONS */

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
    }

    function setMaxHybrid(uint _maxHybrid) external onlyOwner {
        maxHybrid = _maxHybrid;
    }

    function setMaxTokenBurn(uint _maxTokenBurn) external onlyOwner {
        require(_maxTokenBurn > 0, "Cannot be zero");
        require(_maxTokenBurn.mod(WHOLE) == 0, "Must be whole number");
        maxTokenBurn = _maxTokenBurn;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addLottery(uint _country, uint _startTime, uint _maxTokens) external onlyOwner {
        require(_country > 0 && _country < 6, "Country must be between 1-5");
        require(_maxTokens > 0, "Max tokens cannot be 0");
        require(_maxTokens.mod(WHOLE) == 0, "Must be whole number");
        lotteries.push(Lot({
            country: _country,
            startTime: _startTime,
            tokensBurned: 0,
            maxTokens: _maxTokens,
            winner: 0,
            finished: false
        }));
        emit LotteryAdded(lotteries.length - 1, _country, _startTime, _maxTokens);
    }

    function changeStartTime(uint _lid, uint _startTime) external onlyOwner checkLid(_lid) {
        lotteries[_lid].startTime = _startTime;
    }

    function changeMaxTokens(uint _lid, uint _maxTokens) external onlyOwner checkLid(_lid) {
        require(_maxTokens.mod(WHOLE) == 0, "Must be whole number");
        lotteries[_lid].maxTokens = _maxTokens;
    }

    function removeLottery(uint _lid) external onlyOwner checkLid(_lid) finished(_lid) {
        require(nftStakedIds[_lid].length == 0, "Nfts are staked");
        uint lastIndex = lotteries.length - 1;
        require(nftStakedIds[lastIndex].length == 0, "Nfts staked in swapped lottery");
        lotteries[_lid] = lotteries[lastIndex];
        lotteries.pop();
        emit LotteryRemoved(_lid);
    }

    function restartLottery(uint _lid) external onlyOwner checkLid(_lid) {
        lotteries[_lid].finished = false;
        emit LotteryRestarted(_lid);
    }

    function finishLottery(uint _lid, uint _winner) external onlyOwner checkLid(_lid) {
        lotteries[_lid].winner = _winner;
        lotteries[_lid].finished = true;
        emit LotteryFinished(_lid, _winner);
    }

    function burnExcessHybrid() external onlyOwner {
        _burnExcessHybrid();
    }

    /* USER FUNCTIONS */

    function stakeNft(uint _lid, uint _nftId) external checkLid(_lid) ongoing(_lid) whenNotPaused nonReentrant {
        nft.transferFrom(msg.sender, address(this), _nftId);
        nftStakeInfo[_nftId] = StakeInfo({
            owner: msg.sender,
            nftId: _nftId,
            lid: _lid,
            tokensBurned: 0,
            hybridStaked: 0,
            lastEarnTime: block.timestamp
        });
        uint index = nftStakedIds[_lid].length;
        nftStakedIds[_lid].push(_nftId);
        nftStakedIndex[_lid][_nftId] = index;

        uint userIndex = userNftStakedIds[msg.sender].length;
        userNftStakedIds[msg.sender].push(_nftId);
        userNftStakedIndex[msg.sender][_nftId] = userIndex;

        emit NFTStaked(msg.sender, _lid, _nftId);
    }

    function unstakeNft(uint _nftId) external whenNotPaused nonReentrant {
        StakeInfo memory nftInfo = nftStakeInfo[_nftId];
        require(msg.sender == nftInfo.owner, "Not the owner");
        require(nftInfo.tokensBurned == 0, "NFT Locked. Wait for lottery to finish");
        
        // Claim pending tokens
        (uint amount, uint factor) = _getClaimAmount(nftInfo);
        if (amount > 0) {
            _claim(_nftId, amount, factor);
        }

        _unstakeNft(msg.sender, nftInfo.lid, _nftId);
        emit NFTUnstaked(msg.sender, _nftId);
    }

    function stakeHybrid(uint _nftId, uint amount) external whenNotPaused nonReentrant {
        StakeInfo memory nftInfo = nftStakeInfo[_nftId];
        require(msg.sender == nftInfo.owner, "Not the owner");
        require(nftInfo.tokensBurned > 0, "No tokens burned");
        uint newStakedHybrid = nftInfo.hybridStaked.add(amount);
        require(newStakedHybrid <= maxHybrid, "Staked too much");

        hybrid.safeTransferFrom(msg.sender, address(this), amount);
        totalHybridStaked = totalHybridStaked.add(amount);
        nftStakeInfo[_nftId].hybridStaked = newStakedHybrid;
        emit HybridStaked(msg.sender, _nftId, amount);
    }

    function emergencyUnstakeHybrid(uint _nftId, uint amount) external nonReentrant {
        StakeInfo memory nftInfo = nftStakeInfo[_nftId];
        require(msg.sender == nftInfo.owner, "Not the owner");
        require(nftInfo.hybridStaked >= amount, "Cannot withdraw more than staked");
        uint fees = amount.mul(UNSTAKE_HYBRID_FEES).div(1e4);
        uint netAmount = amount.sub(fees);
        hybrid.safeTransfer(msg.sender, netAmount);
        totalHybridStaked = totalHybridStaked.sub(amount);
        nftStakeInfo[_nftId].hybridStaked = nftInfo.hybridStaked.sub(amount);
        _burnExcessHybrid();
        emit EmergencyHybridUnstake(msg.sender, _nftId, amount);
    }

    function multiClaim(uint[] memory _nftIds) external whenNotPaused nonReentrant {
        for (uint i = 0; i < _nftIds.length; i++) {
            uint _nftId = _nftIds[i];
            StakeInfo memory nftInfo = nftStakeInfo[_nftId];
            require(msg.sender == nftInfo.owner, "Not the owner");
            (uint amount, uint factor) = _getClaimAmount(nftInfo);
            if (factor > 0) {
                _claim(_nftId, amount, factor);
            }
        }
    }

    function burnTokens(uint _lid, uint _nftId, uint amount) external checkLid(_lid) whenNotPaused nonReentrant {
        require(amount.mod(WHOLE) == 0, "Can only burn whole numbers");
        Lot memory lot = lotteries[_lid];
        StakeInfo memory nftInfo = nftStakeInfo[_nftId];
        require(msg.sender == nftInfo.owner, "Not the owner");
        require(_lid == nftInfo.lid, "NFT not staked here");
        uint newLotTokensBurned = lot.tokensBurned.add(amount);
        uint newNftTokensBurned = nftInfo.tokensBurned.add(amount);
        require(newLotTokensBurned <= lot.maxTokens, "Lottery limit exceeded");
        require(newNftTokensBurned <= maxTokenBurn, "NFT limit exceeded");

        nft.burnTokens(_nftId, amount);
        nftStakeInfo[_nftId].tokensBurned = newNftTokensBurned;
        lotteries[_lid].tokensBurned = newLotTokensBurned;
        emit TokensBurned(_nftId, amount);
    }

    function unstakeLockedNft(uint _lid, uint _nftId) external checkLid(_lid) finished(_lid) whenNotPaused nonReentrant {
        StakeInfo memory nftInfo = nftStakeInfo[_nftId];
        require(msg.sender == nftInfo.owner, "Not the owner");
        require(_lid == nftInfo.lid, "NFT is not staked here");

        // Claim pending tokens
        (uint amount, uint factor) = _getClaimAmount(nftInfo);
        if (amount > 0) {
            _claim(_nftId, amount, factor);
        }

        // Unstake hybrid
        uint hybridAmount = nftInfo.hybridStaked;
        totalHybridStaked = totalHybridStaked.sub(hybridAmount);
        hybrid.safeTransfer(msg.sender, hybridAmount);

        _unstakeNft(msg.sender, _lid, _nftId);
        _burnExcessHybrid();
        emit LockedNFTUnstaked(msg.sender, _lid, _nftId);
    }

    /* INTERNAL FUNCTIONS */

    function _burnExcessHybrid() internal {
        uint amount = getExcessHybrid();
        hybrid.safeTransfer(DEAD, amount);
    }

    function _unstakeNft(address _user, uint _lid, uint _nftId) internal {
        nft.transferFrom(address(this), _user, _nftId);
        delete nftStakeInfo[_nftId];
        
        // Remove from lot
        uint nftIndex = nftStakedIndex[_lid][_nftId];
        uint lastIndex = nftStakedIds[_lid].length - 1;
        uint nftIdToSwap = nftStakedIds[_lid][lastIndex];
        nftStakedIds[_lid][nftIndex] = nftIdToSwap;
        nftStakedIds[_lid].pop();
        nftStakedIndex[_lid][nftIdToSwap] = nftIndex;
        delete nftStakedIndex[_lid][_nftId];

        // Remove from user
        nftIndex = userNftStakedIndex[_user][_nftId];
        lastIndex = userNftStakedIds[_user].length - 1;
        nftIdToSwap = userNftStakedIds[_user][lastIndex];
        userNftStakedIds[_user][nftIndex] = nftIdToSwap;
        userNftStakedIds[_user].pop();
        userNftStakedIndex[_user][nftIdToSwap] = nftIndex;
        delete userNftStakedIndex[_user][_nftId];
    }

    function _claim(uint _nftId, uint amount, uint factor) internal {
        nftStakeInfo[_nftId].lastEarnTime = nftStakeInfo[_nftId].lastEarnTime.add(factor.mul(1 days));
        nft.earnTokens(_nftId, amount);
        emit TokensClaimed(_nftId, amount);
    }

    function _getClaimAmount(StakeInfo memory nftInfo) internal view returns (uint claimAmount, uint factor) {
        uint lastEarnTime = nftInfo.lastEarnTime;
        uint _nftId = nftInfo.nftId;
        if (lastEarnTime > 0) {
            factor = block.timestamp.sub(lastEarnTime).div(1 days);
            if (factor > 0) {
                uint earnAmount = EARN_DAILY.add(nftInfo.hybridStaked.div(HYBRID_EARN_DAILY));
                uint nftCountry = nft.getNFTCountry(_nftId);
                uint lidCountry = lotteries[nftInfo.lid].country;
                if (nftCountry == lidCountry) {
                    earnAmount = earnAmount.mul(COUNTRY_FACTOR).div(100);
                }
                claimAmount = earnAmount.mul(factor);
            }
        }
    }

    /* VIEW FUNCTIONS */

    function getClaimAmount(uint _nftId) external view returns (uint amount) {
        StakeInfo memory nftInfo = nftStakeInfo[_nftId];
        (amount, ) = _getClaimAmount(nftInfo);
    }

    function getMultipleClaimAmounts(uint[] calldata _nftIds) external view returns (uint[] memory amounts) {
        uint numLength = _nftIds.length;
        amounts = new uint[](numLength);
        for (uint i = 0; i < numLength; i++) {
            StakeInfo memory nftInfo = nftStakeInfo[_nftIds[i]];
            (amounts[i], ) = _getClaimAmount(nftInfo);
        }
    }

    function getNumNftsStaked(uint _lid) external view checkLid(_lid) returns (uint) {
        return nftStakedIds[_lid].length;
    }

    function getNumNftsStakedMultiple(uint[] memory _lids) external view returns (uint[] memory numStaked) {
        numStaked = new uint[](_lids.length);
        for(uint i = 0; i < _lids.length; i++) {
            numStaked[i] = nftStakedIds[_lids[i]].length;
        }
    }

    function getAllStakedNftIds(uint _lid) external view checkLid(_lid) returns (uint[] memory) {
        return nftStakedIds[_lid];
    }

    function getRangeStakedNftIds(uint _lid, uint startIndex, uint endIndex) external view checkLid(_lid) returns (uint[] memory nftIds) {
        nftIds = new uint[](endIndex.sub(startIndex)+1);
        for (uint i = startIndex; i <= endIndex; i++) {
            uint index = i - startIndex;
            nftIds[index] = nftStakedIds[_lid][i];
        }
    }

    function getAllStakedNftInfo(uint _lid) external view checkLid(_lid) returns (StakeInfo[] memory stakedNfts) {
        uint[] memory nftIds = nftStakedIds[_lid];
        uint listLength = nftIds.length;
        stakedNfts = new StakeInfo[](listLength);
        for (uint i = 0; i < listLength; i++) {
            stakedNfts[i] = nftStakeInfo[nftIds[i]];
        }
    }

    function getRangeStakedNftInfo(uint _lid, uint startIndex, uint endIndex) external view checkLid(_lid) returns (StakeInfo[] memory stakedNfts) {
        stakedNfts = new StakeInfo[](endIndex.sub(startIndex)+1);
        for (uint i = startIndex; i <= endIndex; i++) {
            uint index = i - startIndex;
            stakedNfts[index] = nftStakeInfo[nftStakedIds[_lid][i]];
        }
    }

    function getStakedNftInfo(uint[] calldata nftIds) external view returns (StakeInfo[] memory stakedNfts) {
        uint listLength = nftIds.length;
        stakedNfts = new StakeInfo[](listLength);
        for (uint i = 0; i < listLength; i++) {
            stakedNfts[i] = nftStakeInfo[nftIds[i]];
        }
    }

    function getUserStakedNftInfo(address owner) external view returns (StakeInfo[] memory stakedNfts) {
        uint[] memory nftIds = userNftStakedIds[owner];
        uint listLength = nftIds.length;
        stakedNfts = new StakeInfo[](listLength);
        for (uint i = 0; i < listLength; i++) {
            stakedNfts[i] = nftStakeInfo[nftIds[i]];
        }
    }

    function getAllLotteryRaffles(uint _lid) external view returns (Raffle[] memory raffles) {
        uint[] memory nftIds = nftStakedIds[_lid];
        uint listLength = nftIds.length;
        raffles  = new Raffle[](listLength);
        for (uint i = 0; i < listLength; i++) {
            uint nftId = nftIds[i];
            uint tokensBurned = nftStakeInfo[nftId].tokensBurned;
            if (tokensBurned > 0) {
                raffles[i] = Raffle({
                    nftId: nftId,
                    rarity: nft.getNFTRarity(nftId),
                    tokensBurned: tokensBurned
                });
            }
        }
    }

    function getLotteryRaffles(uint _lid, uint startIndex, uint endIndex) external view returns (Raffle[] memory raffles) {
        raffles  = new Raffle[](endIndex.sub(startIndex)+1);
        for (uint i = startIndex; i <= endIndex; i++) {
            uint nftId = nftStakedIds[_lid][i];
            uint tokensBurned = nftStakeInfo[nftId].tokensBurned;
            uint index = i - startIndex;
            if (tokensBurned > 0) {
                raffles[index] = Raffle({
                    nftId: nftId,
                    rarity: nft.getNFTRarity(nftId),
                    tokensBurned: tokensBurned
                });
            }
        }
    }

    function getLotteries() external view returns (Lot[] memory) {
        return lotteries;
    }

    function getExcessHybrid() public view returns (uint) {
        return hybrid.balanceOf(address(this)).sub(totalHybridStaked);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Context.sol";

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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
pragma solidity 0.7.5;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Meta is IERC20 {
  function decimals() external view returns (uint8);

  function burnFrom(address account, uint256 amount) external;

  function mint(address receiver, uint256 amount) external;
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface INFT {
    function multiMint(address recipient, uint num) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function getNFTCountry(uint tokenId) external view returns (uint);

    function getNFTRarity(uint tokenId) external view returns (uint);

    function earnTokens(uint tokenId, uint amount) external;

    function burnTokens(uint tokenId, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}