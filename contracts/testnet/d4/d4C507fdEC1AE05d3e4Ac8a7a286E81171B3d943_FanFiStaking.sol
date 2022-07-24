// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FanFiStaking is Ownable {
    struct APYScheme {
        uint256 stakingYield;
        uint256 lockingPeriod;
        uint256 maxUserStake;
        uint256 maxTotalStake;
        uint256 maxYield;
        uint256 currentStake;
        uint256 currentYield;
        bool exist;
    }

    struct StakeInfo {
        uint256 schemeID;
        uint256 stakeAmount;
        uint256 stakeTimestamp;
        uint256 rewards;
        uint256 unstakeTimestamp;
        StakeStatus status;
    }

    struct User {
        uint256 totalStake;
        uint256 totalRedeemed;
        StakeInfo[] stakes;
        mapping(uint256 => uint256) totalStakePerScheme;
    }

    enum StakeStatus {
        ACTIVE,
        UNSTAKED,
        IN_REDEMPTION,
        REDEEMED
    }

    uint256 public constant PERCENTAGE_DENOMINATOR = 10000;

    IERC20 public token;
    uint256 public totalStake;

    uint256[] private apySchemeList;
    mapping(uint256 => APYScheme) private apySchemes;
    mapping(address => User) private users;

    event SetAPYScheme(uint256 schemeID);
    event Stake(
        address indexed userAddress,
        uint256 stakeAmount,
        uint256 schemeID
    );
    event Unstake(
        address indexed userAddress,
        uint256 unstakeAmount,
        uint256 rewardAmount,
        uint256 schemeID
    );
    event Redeem(
        address indexed userAddress,
        uint256 redeemAmount,
        uint256 schemeID
    );

    constructor(address _tokenAddress) Ownable() {
        token = IERC20(_tokenAddress);
        _setApyScheme(
            1, // scheme ID
            2500, // staking Yield 2 decimal places
            5, // locking Period
            1000000000, // max tokens per user 4 decimal places
            3333333330000, // max tokens per scheme 4 decimal places
            69444444440 // max yield 4 decimal places
        );
        _setApyScheme(2, 3500, 10, 500000000, 1428571430000, 41666666670);
        _setApyScheme(3, 6500, 15, 100000000, 512820510000, 27777777780);
    }

    function _setApyScheme(
        uint256 _schemeID,
        uint256 _stakingYield,
        uint256 _lockingPeriod,
        uint256 _maxUserStake,
        uint256 _maxTotalStake,
        uint256 _maxYield
    ) internal {
        if (!apySchemes[_schemeID].exist) {
            APYScheme memory scheme = APYScheme(
                _stakingYield,
                _lockingPeriod * 1 minutes, // change to hours in production
                _maxUserStake,
                _maxTotalStake,
                _maxYield,
                0,
                0,
                true
            );
            apySchemes[_schemeID] = scheme;
            apySchemeList.push(_schemeID);
        } else {
            apySchemes[_schemeID].stakingYield = _stakingYield;
            apySchemes[_schemeID].lockingPeriod = _lockingPeriod * 1 minutes; // change to hours in production
            apySchemes[_schemeID].maxUserStake = _maxUserStake;
            apySchemes[_schemeID].maxTotalStake = _maxTotalStake;
            apySchemes[_schemeID].maxYield = _maxYield;
        }
        emit SetAPYScheme(_schemeID);
    }

    function setAPYScheme(
        uint256 _schemeID,
        uint256 _stakingYield,
        uint256 _lockingPeriod,
        uint256 _maxUserStake,
        uint256 _maxTotalStake,
        uint256 _maxYield
    ) external onlyOwner {
        _setApyScheme(
            _schemeID,
            _stakingYield,
            _lockingPeriod,
            _maxUserStake,
            _maxTotalStake,
            _maxYield
        );
    }

    function stake(uint256 _amount, uint256 _schemeID) external {
        require(_amount > 0, "FanFiStake: amount zero");
        APYScheme memory scheme = apySchemes[_schemeID];
        require(scheme.exist, "FanFiStake: scheme doesn't exist");
        require(
            users[msg.sender].totalStakePerScheme[_schemeID] + _amount <
                scheme.maxUserStake,
            "FanFiStake: exceeded max stake for user per scheme"
        );
        require(
            scheme.currentStake + _amount < scheme.maxTotalStake,
            "FanFiStake: exceeded max stake per scheme"
        );
        StakeInfo memory newStake = StakeInfo(
            _schemeID,
            _amount,
            block.timestamp,
            0,
            0,
            StakeStatus.ACTIVE
        );
        users[msg.sender].totalStake += _amount;
        users[msg.sender].totalStakePerScheme[_schemeID] += _amount;
        users[msg.sender].stakes.push(newStake);

        apySchemes[_schemeID].currentStake += _amount;
        totalStake += _amount;

        token.transferFrom(msg.sender, address(this), _amount);
        emit Stake(msg.sender, _amount, _schemeID);
    }

    function unstake(uint256 _stakeIndex) external {
        StakeInfo[] memory stakes = users[msg.sender].stakes;
        require(
            stakes.length > _stakeIndex,
            "FanFiStake: stake index doesn't exist"
        );

        StakeInfo memory stakeInfo = stakes[_stakeIndex];
        APYScheme memory scheme = apySchemes[stakeInfo.schemeID];
        require(
            stakeInfo.status == StakeStatus.ACTIVE,
            "FanFiStake: staking is not ACTIVE"
        );
        if (
            (block.timestamp - stakeInfo.stakeTimestamp) > scheme.lockingPeriod
        ) {
            stakeInfo.status = StakeStatus.IN_REDEMPTION;
            stakeInfo.unstakeTimestamp = block.timestamp;
            uint256 stakedDays = (block.timestamp - stakeInfo.stakeTimestamp) /
                2 minutes; // change to 1 days in production
            uint256 userRewards = (stakeInfo.stakeAmount *
                scheme.stakingYield *
                stakedDays) / (PERCENTAGE_DENOMINATOR * 365);
            stakeInfo.rewards = userRewards;
        } else stakeInfo.status = StakeStatus.UNSTAKED;

        users[msg.sender].totalStakePerScheme[stakeInfo.schemeID] -= stakeInfo
            .stakeAmount;
        users[msg.sender].stakes[_stakeIndex] = stakeInfo;

        apySchemes[stakeInfo.schemeID].currentStake -= stakeInfo.stakeAmount;
        totalStake -= stakeInfo.stakeAmount;

        require(
            token.balanceOf(address(this)) >= stakeInfo.stakeAmount,
            "FanFiStake: not enough liquidity"
        );
        token.transfer(msg.sender, stakeInfo.stakeAmount);
        emit Unstake(
            msg.sender,
            stakeInfo.stakeAmount,
            stakeInfo.rewards,
            stakeInfo.schemeID
        );
    }

    function redeem(uint256 _stakeIndex) external {
        StakeInfo[] memory stakes = users[msg.sender].stakes;
        require(
            stakes.length > _stakeIndex,
            "FanFiStake: stake index doesn't exist"
        );

        StakeInfo memory stakeInfo = stakes[_stakeIndex];
        APYScheme memory scheme = apySchemes[stakeInfo.schemeID];
        require(
            stakeInfo.status == StakeStatus.IN_REDEMPTION,
            "FanFiStake: staking is not IN_REDEMPTION"
        );
        require(
            block.timestamp - stakeInfo.unstakeTimestamp >= 5 minutes, // change to 48 hours in production
            "FanFiStake: wait 5 minutes after unstake"
        );
        require(
            scheme.currentYield + stakeInfo.rewards <= scheme.maxYield,
            "FanFiStake: reward exceeds max yield for the scheme"
        );

        stakeInfo.status = StakeStatus.REDEEMED;
        users[msg.sender].totalRedeemed += stakeInfo.rewards;
        users[msg.sender].stakes[_stakeIndex] = stakeInfo;

        apySchemes[stakeInfo.schemeID].currentYield += stakeInfo.rewards;

        require(
            token.balanceOf(address(this)) >= stakeInfo.rewards,
            "FanFiStake: not enough liquidity"
        );
        token.transfer(msg.sender, stakeInfo.rewards);
        emit Redeem(msg.sender, stakeInfo.rewards, stakeInfo.schemeID);
    }

    function getUserInfo(address _userAddress)
        external
        view
        returns (uint256, uint256)
    {
        return (
            users[_userAddress].totalStake,
            users[_userAddress].totalRedeemed
        );
    }

    function getUserStakesCount(address _userAddress)
        external
        view
        returns (uint256)
    {
        return users[_userAddress].stakes.length;
    }

    function getUserStakes(address _userAddress)
        external
        view
        returns (uint256, StakeInfo[] memory)
    {
        return (users[_userAddress].stakes.length, users[_userAddress].stakes);
    }

    function getUserStakeInfo(address _userAddress, uint256 _stakeIndex)
        external
        view
        returns (StakeInfo memory)
    {
        require(
            users[_userAddress].stakes.length > _stakeIndex,
            "FanFiStake: stake index doesn't exist"
        );

        return users[_userAddress].stakes[_stakeIndex];
    }

    function getAPYSchemeList() external view returns (uint256[] memory) {
        return apySchemeList;
    }

    function getAPYSchemeInfo(uint256 _schemeID)
        external
        view
        returns (APYScheme memory)
    {
        require(
            apySchemes[_schemeID].exist,
            "FanFiStake: scheme doesn't exist"
        );

        return (apySchemes[_schemeID]);
    }

    function getUserRewards(address _userAddress, uint256 _stakeIndex)
        external
        view
        returns (uint256 userRewards)
    {
        StakeInfo[] memory stakes = users[_userAddress].stakes;
        require(
            stakes.length > _stakeIndex,
            "FanFiStake: stake index doesn't exist"
        );
        StakeInfo memory stakeInfo = stakes[_stakeIndex];
        APYScheme memory scheme = apySchemes[stakeInfo.schemeID];

        if (stakeInfo.status == StakeStatus.ACTIVE) {
            uint256 stakedDays = (block.timestamp - stakeInfo.stakeTimestamp) /
                2 minutes; // change to 1 days in production
            userRewards =
                (stakeInfo.stakeAmount * scheme.stakingYield * stakedDays) /
                (PERCENTAGE_DENOMINATOR * 365);
        } else if (stakeInfo.status == StakeStatus.IN_REDEMPTION)
            userRewards = stakeInfo.rewards;
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