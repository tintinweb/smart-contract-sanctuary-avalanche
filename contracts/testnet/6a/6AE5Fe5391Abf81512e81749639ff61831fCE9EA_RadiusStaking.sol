// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface RadiusCoin {
    function reflectionFromToken(uint256 _amount, bool _deductFee)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function tokenFromReflection(uint256 _amount)
        external
        view
        returns (uint256);

    function balanceOf(address _address) external view returns (uint256);

    function mint(uint256 _amount) external;

    function setTimeDurationForExtraPenaltyTax(uint _duration) external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferOwnership(address _owner) external;

    function excludeAccount(address _address) external;

    function includeAccount(address _address) external;

    function setReservePool(address _address) external;

    function setLiquidityPoolAddress(address _address, bool _add) external;

    function lockedTill(address _address) external view returns (uint256);

    function lock(address _address, uint256 _days) external;

    function unlock(address _address) external;

    function setLimit(
        address _address,
        uint256 _period,
        uint256 _rule
    ) external;

    function removeLimit(address _address) external;

    function excludeFromFee(address account) external;

    function includeFromFee(address account) external;

    function setReflectionFee(uint256 fee) external;

    function setLiquidityFee(uint256 fee) external;

    function setCharityFee(uint256 fee) external;

    function setBurnPercent(uint256 fee) external;

    function setMarketingFee(uint256 fee) external;

    function setEarlySellFee(uint256 fee) external;

    function setCharityAddress(address _address) external;

    function setRouterAddress(address _address) external;

    function setLiquidityManager(address _address) external;

    function setMarketingAddress(address _Address) external;

    function PrepareForPreSale() external;

    function afterPreSale() external;

    function withdraw() external;

    function setMinter(address _minter) external;

    function removeMinter(address _minter) external;

    function setHaltPercentages(uint256[3] memory _percentages) external;

    function setHaltPeriods(uint256[3] memory _periods) external;

    function setExclusionFromHalt(address _account, bool _exclude) external;

    function executePriceDeclineHalt(
        uint256 currentPrice,
        uint256 referencePrice
    ) external returns (bool);
}

contract RadiusStaking is Ownable {
    using SafeMath for uint256;

    struct Stake {
        uint256 tAmount;
        uint256 rAmount;
        uint256 time;
        uint256 period;
        uint256 rate;
        bool isActive;
    }

    mapping(uint256 => uint256) public interestRate;
    mapping(address => Stake[]) public stakes;

    RadiusCoin private token;

    uint256 private constant DENOMINATOR = 10000;
    uint256 public rewardsDistributed;
    uint256 public rewardsPending;

    event TokenStaked(
        address account,
        uint256 stakeId,
        uint256 tokenAmount,
        uint256 timestamp,
        uint256 period
    );
    event TokenUnstaked(
        address account,
        uint256 tokenAmount,
        uint256 interest,
        uint256 timestamp
    );
    event StakingPeriodUpdated(uint256 period, uint256 rate);

    event RuleChanged(uint256 newRule);
    event ThresholdChanged(uint256 newThreshold);
    event RestrictionDurationChanged(uint256 newRestrictionDuration);
    event ForceEopToggle(bool forceEop);

    modifier isValidStakeId(address _address, uint256 _id) {
        require(_id < stakes[_address].length, "Id is not valid");
        _;
    }

    constructor(address _address) {
        token = RadiusCoin(_address);

        interestRate[6] = 750;
        interestRate[12] = 2500;
    }

    /// @notice used to stake Radius Coin
    /// @param _amount amount of Radius Coin to stake
    /// @param _period number of days or months?? to stake for
    function stakeToken(uint256 _amount, uint256 _period) external {
        require(interestRate[_period] != 0, "Staking period not valid");

        uint256 rAmount = token.reflectionFromToken(_amount, false);
        token.transferFrom(msg.sender, address(this), _amount);

        uint256 stakeId = stakes[msg.sender].length;
        rewardsPending = rewardsPending.add(
            _amount.mul(interestRate[_period]).div(DENOMINATOR)
        );
        stakes[msg.sender].push(
            Stake(
                _amount,
                rAmount,
                block.timestamp,
                _period,
                interestRate[_period],
                true
            )
        );

        emit TokenStaked(
            msg.sender,
            stakeId,
            _amount,
            block.timestamp,
            _period
        );
    }

    /// @notice used to unstake Radius Coin
    /// @param _id index of the stake to unstake from
    function unstakeToken(uint256 _id)
        external
        isValidStakeId(msg.sender, _id)
    {
        require(
            timeLeftToUnstake(msg.sender, _id) == 0,
            "Stake duration not over"
        );
        require(stakes[msg.sender][_id].isActive, "Tokens already unstaked");

        Stake storage stake = stakes[msg.sender][_id];

        uint256 tAmount = token.tokenFromReflection(stake.rAmount);
        uint256 interest = stakingReward(msg.sender, _id);

        uint256 balance = token.balanceOf(address(this));
        if (balance < tAmount.add(interest)) {
            token.mint(tAmount.add(interest).sub(balance));
        }
        rewardsPending = rewardsPending.sub(interest);
        rewardsDistributed = rewardsDistributed.add(interest);
        token.transfer(msg.sender, tAmount.add(interest));

        emit TokenUnstaked(msg.sender, tAmount, interest, block.timestamp);
    }

    /// @notice used to get the stake information of the staker
    /// @param _address the address of the staker
    /// @param _id the index of the stake
    function getStake(address _address, uint256 _id)
        external
        view
        isValidStakeId(_address, _id)
        returns (Stake memory)
    {
        return stakes[_address][_id];
    }

    /// @notice used to get the information of all of the stakes
    /// @param _address the address of the staker
    function getAllStakes(address _address)
        external
        view
        returns (Stake[] memory)
    {
        return stakes[_address];
    }

    /// @notice used to fetch the reflection earned by the staker
    /// @param _address the address of the staker
    /// @param _id the index of the stake
    function reflectionReceived(address _address, uint256 _id)
        external
        view
        isValidStakeId(_address, _id)
        returns (uint256)
    {
        require(stakes[_address][_id].isActive, "Tokens already unstaked");
        Stake memory stake = stakes[_address][_id];
        return (token.tokenFromReflection(stake.rAmount) - stake.tAmount);
    }

    /// @notice used to fetch the time left after which staker can unstake
    /// @param _address the address of the staker
    /// @param _id the index of the stake
    function timeLeftToUnstake(address _address, uint256 _id)
        public
        view
        isValidStakeId(_address, _id)
        returns (uint256)
    {
        require(stakes[_address][_id].isActive, "Tokens already unstaked");
        Stake memory stake = stakes[_address][_id];
        uint256 unstakeTime = stake.time + stake.period * 30 days;

        return (
            block.timestamp < unstakeTime ? unstakeTime - block.timestamp : 0
        );
    }

    /// @notice used to check whether staker can unstake or not
    /// @param _address the address of the staker
    /// @param _id the index of the stake
    function canUnstake(address _address, uint256 _id)
        public
        view
        isValidStakeId(_address, _id)
        returns (bool)
    {
        return (timeLeftToUnstake(_address, _id) == 0 &&
            stakes[_address][_id].isActive);
    }

    /// @notice used to get the reward earned on stake
    /// @param _address the address of the staker
    /// @param _id the index of the stake
    function stakingReward(address _address, uint256 _id)
        public
        view
        isValidStakeId(_address, _id)
        returns (uint256)
    {
        Stake memory stake = stakes[_address][_id];
        return stake.tAmount.mul(stake.rate).div(DENOMINATOR);
    }

    /// @notice used to add a staking period and the interest rate for that period
    /// @param _period number of days or months??
    /// @param _rate interest rate
    function addStakingPeriod(uint256 _period, uint256 _rate)
        external
        onlyOwner
    {
        interestRate[_period] = _rate;
        emit StakingPeriodUpdated(_period, _rate);
    }

    function changeTokenOwnership(address _owner) external onlyOwner {
        token.transferOwnership(_owner);
    }

    function excludeAccount(address account) external onlyOwner {
        token.excludeAccount(account);
    }

    function includeAccount(address account) external onlyOwner {
        token.includeAccount(account);
    }

    function setReservePool(address _address) external onlyOwner {
        token.setReservePool(_address);
    }

    function setLiquidityPoolAddress(address _address, bool _add)
        external
        onlyOwner
    {
        token.setLiquidityPoolAddress(_address, _add);
    }

    function lock(address _address, uint256 _days) external onlyOwner {
        require(token.lockedTill(_address) == 0, "Address is already locked");
        token.lock(_address, _days);
    }

    function unlock(address _address) external onlyOwner {
        token.unlock(_address);
    }

    function setLimit(
        address _address,
        uint256 _period,
        uint256 _rule
    ) external onlyOwner {
        token.setLimit(_address, _period, _rule);
    }

    function removeLimit(address _address) external onlyOwner {
        token.removeLimit(_address);
    }

    function setMinter(address _minter) external onlyOwner {
        token.setMinter(_minter);
    }

    function removeMinter(address _minter) external onlyOwner {
        token.removeMinter(_minter);
    }

    function setTimeDurationForExtraPenaltyTax(uint _duration)
        external
        onlyOwner
    {
        token.setTimeDurationForExtraPenaltyTax(_duration);
    }

    function excludeFromFee(address account) external onlyOwner {
        token.excludeFromFee(account);
    }

    function includeFromFee(address account) external onlyOwner {
        token.includeFromFee(account);
    }

    function setReflectionFee(uint256 fee) external onlyOwner {
        token.setReflectionFee(fee);
    }

    function setLiquidityFee(uint256 fee) external onlyOwner {
        token.setLiquidityFee(fee);
    }

    function setCharityFee(uint256 fee) external onlyOwner {
        token.setCharityFee(fee);
    }

    function setBurnPercent(uint256 fee) external onlyOwner {
        token.setBurnPercent(fee);
    }

    function setMarketingFee(uint256 fee) external onlyOwner {
        token.setMarketingFee(fee);
    }

    function setEarlySellFee(uint256 fee) external onlyOwner {
        token.setEarlySellFee(fee);
    }

    function setCharityAddress(address _Address) external onlyOwner {
        token.setCharityAddress(_Address);
    }

    function setRouterAddress(address _Address) external onlyOwner {
        token.setRouterAddress(_Address);
    }

    function setLiquidityManager(address _address) external onlyOwner {
        token.setLiquidityManager(_address);
    }

    function setMarketingAddress(address _Address) external onlyOwner {
        token.setMarketingAddress(_Address);
    }

    function PrepareForPreSale() external onlyOwner {
        token.PrepareForPreSale();
    }

    function afterPreSale() external onlyOwner {
        token.afterPreSale();
    }

    function setHaltPercentages(uint256[3] memory _percentages)
        external
        onlyOwner
    {
        token.setHaltPercentages(_percentages);
    }

    function setHaltPeriods(uint256[3] memory _periods) external onlyOwner {
        token.setHaltPeriods(_periods);
    }

    function setExclusionFromHalt(address _account, bool _exclude)
        external
        onlyOwner
    {
        token.setExclusionFromHalt(_account, _exclude);
    }

    function executePriceDeclineHalt(
        uint256 currentPrice,
        uint256 referencePrice
    ) external onlyOwner returns (bool) {
        return token.executePriceDeclineHalt(currentPrice, referencePrice);
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        token.withdraw();
        payable(msg.sender).transfer(address(this).balance);
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