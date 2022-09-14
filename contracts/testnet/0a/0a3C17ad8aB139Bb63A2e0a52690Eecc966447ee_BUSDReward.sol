// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract BUSDReward is Ownable, ReentrancyGuard, Pausable {
    /**
     * @dev Struct contains all the details about Staker.
     * @param walletAddress: The wallet address of the staker.
     * @param stakedBalance: The total staked balance of the staker.
     * @param withdrawableBalance: The total withdrawable balance.
     * @param totalRewardsClaimed: The total reward claimed from staking.
     * @param maxReward: The maximum reward can be claimed.
     * @param lastStakedOn: The last staked timestamp.
     * @param previousRewardClaimedOn: The pervious reward claim timestamp.
     * @param nextRewardClaimedOn: The next reward claim timestamp.
     * @param referrals: The referral addresses array.
     */
    struct StakerDetails {
        address walletAddress;
        uint256 stakedBalance;
        uint256 withdrawableBalance;
        uint256 totalRewardsClaimed;
        uint256 maxReward;
        uint256 lastStakedOn;
        uint256 previousRewardClaimedOn;
        uint256 nextRewardClaimedOn;
        address[] referrals;
    }

    /**
     * @dev Tracking BUSD immutable token address means you cannot chage.
     */
    address immutable private _busdContractAddress;

    /**
     * @dev Tracking daily reward percentage.
     */
    uint256 public dailyRewardPercentage = 2;

    /**
     * @dev Tracking referral reward percentage.
     */
    uint256 public referralRewardPercentage = 2;

    /**
     * @dev Tracking minimum BUSD to stake.
     */
    uint256 public minimumAmountToStake = 1 ether;

    /**
     * @dev Tracking waiting period.
     */
    uint256 private _waitingPeriod = 1800;

    /**
     * @dev Mapping between staker address to `StakerDetails`.
     */
    mapping (address => StakerDetails) private _stakerAddressToDetails;

    /**
     * @dev Mapping between staker address to boolean to track whether he staked already.
     */
    mapping(address => bool) private _isStaker;

    /**
     * @dev Mapping between staker address to boolean to track whether he already referred.
     */
    mapping(address => bool) private _isReferred;

    /**
     * @dev Mapping between staker address(referee) to staker address(referrer).
     */
    mapping(address => address) private _refereeToReferrer;

    /**
     * @dev Modifier to check if the amount is greater than zero or not.
     * @param _amount: The amount which you want to check.
     */
    modifier moreThanZero(uint256 _amount) {
        require(
            _amount > 0,
            "MoreThanZero: The amount must be more than zero."
        ); _;
    }

    /**
     * @dev Modifier to check if the percentage is between 100.
     * @param _percentage: The percentage which you want to check.
     */
    modifier notMoreThan100(uint256 _percentage) {
        require(
            _percentage <= 100,
            "MoreThan100: The percentage should less than or equal to 100."
        ); _;
    }

    /**
     * @dev Modifier to check if the amount is more than minimum amount.
     * @param _amount: The amount which you want to check.
     */
    modifier moreThanMinimumAmountToStake(uint256 _amount) {
        require(
            _amount >= minimumAmountToStake,
            "MoreThanMinimumAmount: The amount should be more than minimum amount."
        ); _;
    }

    /**
     * @dev Modifier to check if the sender is staker.
     */
    modifier onlyStaker() {
        require(
            _stakerAddressToDetails[msg.sender].walletAddress == msg.sender,
            "OnlyStaker: This function only accessable who already staked."
        ); _;
    }

    /**
     * @dev Modifier to check if the referee is already a staker.
     * @param _referee: The address to whom is refereing.
     */
    modifier notStaker(address _referee) {
        require(
            !_isStaker[_referee],
            "AlreadyStaker: This address already a staker."
        ); _;
    }

    /**
     * @dev Modifier to check if the referee is already referred.
     * @param _referee: The address to whom is refereing.
     */
    modifier notReferred(address _referee) {
        require(
            !_isReferred[_referee],
            "AlreadyReferred: This address already referred."
        ); _;
    }

    /**
     * @dev Modifier to check if the referee and referrer address are not same.
     * @param _referee: The address to whom is refereing.
     * @param _referrer: The address who is refereing.
     */
    modifier botheAddressAreNotSame(address _referrer, address _referee) {
        require(
            _referrer != _referee,
            "AddressAreSame: You cannot refer yourself."
        ); _;
    }

    /**
     * @dev Modifier to check if the staker balance more than zero.
     */
    modifier balanceMoreThanZero() {
        require(
            _stakerAddressToDetails[msg.sender].stakedBalance > 0,
            "NoBalanceLeft: Your balance is zero."
        ); _;
    }

    /**
     * @dev Event to keep track of when liquidity provided.
     * @param providedBy: The contract owner address.
     * @param amount: The amount of BUSD given.
     * @param time: The block.timestamp.
     */
    event LiquidityProvided(
        address providedBy,
        uint256 amount,
        uint256 time
    );

    /**
     * @dev Event to keep track of when liquidity withdrawn.
     * @param withdrawBy: The contract owner address.
     * @param amount: The amount of BUSD given.
     * @param time: The block.timestamp.
     */
    event LiquidityWithdrawn(
        address withdrawBy,
        uint256 amount,
        uint256 time
    );

    /**
     * @dev Event to keep track of daily reward percentage updated.
     * @param oldPercentage: The old percentage.
     * @param newPercentage: The new percentage.
     * @param time: The block.timestamp.
     */
    event DailyRewardPercentageUpdated(
        uint256 oldPercentage,
        uint256 newPercentage,
        uint256 time
    );

    /**
     * @dev Event to keep track of referral reward percentage updated.
     * @param oldPercentage: The old percentage.
     * @param newPercentage: The new percentage.
     * @param time: The block.timestamp.
     */
    event ReferralRewardPercentageUpdated(
        uint256 oldPercentage,
        uint256 newPercentage,
        uint256 time
    );

    /**
     * @dev Event to keep track of minimum amount to stake updated.
     * @param oldAmount: The old amount.
     * @param newAmount: The new amount.
     * @param time: The block.timestamp.
     */
    event MinimumAmountToStakeUpdated(
        uint256 oldAmount,
        uint256 newAmount,
        uint256 time
    );

    /**
     * @dev Event to keep track of Staked amount.
     * @param walletAddress: The staker address.
     * @param amount: The amount staked.
     * @param time: The block.timestamp.
     */
    event Staked(
        address walletAddress,
        uint256 amount,
        uint256 time
    );

    /**
     * @dev Event to keep track of un-staked amount.
     * @param walletAddress: The staker address.
     * @param amount: The amount staked.
     * @param time: The block.timestamp.
     */
    event Unstaked(
        address walletAddress,
        uint256 amount,
        uint256 time
    );

    /**
     * @dev Event to keep track of Staked amount.
     * @param referrer: The referrer address.
     * @param referee: The referee staked.
     * @param time: The block.timestamp.
     */
    event Referred(
        address referrer,
        address referee,
        uint256 time
    );

    /**
     * @dev Event to keep track of Daily reward claimed.
     * @param walletAddress: The wallet address.
     * @param amount: The reward amount.
     * @param time: The block.timestamp.
     */
    event DailyRewardClaimed(
        address walletAddress,
        uint amount,
        uint256 time
    );

    /**
     * @dev Event to keep track of Daily reward withdrawn.
     * @param walletAddress: The wallet address.
     * @param amount: The reward amount.
     * @param time: The block.timestamp.
     */
    event DailyRewardsWithdrawn(
        address walletAddress,
        uint amount,
        uint256 time
    );

    /**
     * @dev initilizing BUSD contract address with constructor.
     * @param busdContractAddress_: The BUSD contract address.
     */
    constructor(address busdContractAddress_){
        _busdContractAddress = busdContractAddress_;
    }

    /**
     * @dev Pause the contract.
     * Only contract owner can call this function.
     */
    function pause() external onlyOwner nonReentrant {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     * Only contract owner can call this function.
     */
    function unpause() external onlyOwner nonReentrant {
        _unpause();
    }

    /**
     * @dev Getting staker details based on their address.
     * @param _stakerAddress: The staker wallet address.
     * @return StakerDetails: The Details of the staker.
     */
    function getStakerDetails(address _stakerAddress) external view returns(StakerDetails memory) {
        return _stakerAddressToDetails[_stakerAddress];
    }

    /**
     * @dev Updating the `dailyRewardPercentage`.
     * Only owner can set this.
     * @param _newDailyRewardPercentage: The percentage you want to set.
     */
    function updateDailyRewardPercentage(uint256 _newDailyRewardPercentage)
        external onlyOwner whenNotPaused nonReentrant notMoreThan100(_newDailyRewardPercentage) {
        uint256 oldPercentage = dailyRewardPercentage;
        dailyRewardPercentage = _newDailyRewardPercentage;

        emit DailyRewardPercentageUpdated(oldPercentage, _newDailyRewardPercentage, block.timestamp);
    }

    /**
     * @dev Updating the `referralRewardPercentage`.
     * Only owner can set this.
     * @param _newReferralRewardPercentage: The percentage you want to set.
     */
    function updateReferralRewardPercentage(uint256 _newReferralRewardPercentage)
        external onlyOwner whenNotPaused nonReentrant notMoreThan100(_newReferralRewardPercentage) {
        uint256 oldPercentage = referralRewardPercentage;
        referralRewardPercentage = _newReferralRewardPercentage;

        emit ReferralRewardPercentageUpdated(oldPercentage, _newReferralRewardPercentage, block.timestamp);
    }

    /**
     * @dev Updating the `minimumAmountToStake`.
     * Only owner can set this.
     * @param _newMinimumAmountToStake: The percentage you want to set.
     */
    function updateMinimumAmountToStake(uint256 _newMinimumAmountToStake)
        external onlyOwner whenNotPaused nonReentrant {
        require(
            _newMinimumAmountToStake >= 1 ether,
            "Shouldbe1: The new minimum stake amount should be more than 1"
        );

        uint256 oldAmount = minimumAmountToStake;
        minimumAmountToStake = _newMinimumAmountToStake;

        emit MinimumAmountToStakeUpdated(oldAmount, _newMinimumAmountToStake, block.timestamp);
    }

    /**
     * @dev Providing BUSD supply to contract for giving rewards.
     * @param _amount: The number of tokens as a supply.
     */
    function provideBusdToContract(uint256 _amount)
        external onlyOwner whenNotPaused nonReentrant moreThanZero(_amount) {
        require(IERC20(_busdContractAddress).transferFrom(msg.sender, address(this), _amount));
        emit LiquidityProvided(msg.sender, _amount, block.timestamp);
    }

    /**
     * @dev Withdrawing BUSD supply from contract.
     * @param _amount: The number of tokens as a supply.
     */
    function withdrawBusdFromContract(uint256 _amount)
        external onlyOwner whenNotPaused nonReentrant moreThanZero(_amount) {
        require(
            IERC20(_busdContractAddress).balanceOf(address(this)) >= _amount,
            "ContractHaveNoBalance: Contract do not have enough balance."
        );

        require(IERC20(_busdContractAddress).transfer(msg.sender, _amount));
        emit LiquidityWithdrawn(msg.sender, _amount, block.timestamp);
    }

    /**
     * @dev Staking BUSD to the contract. Updating staker details and giving referral bonus if
     * address referred by someone or not, and emits `Staked` event.
     * @param _amount: The BUSD amount staker wants to stake.
     */
    function stake(uint256 _amount)
        external whenNotPaused nonReentrant moreThanMinimumAmountToStake(_amount) {
        require(IERC20(_busdContractAddress).transferFrom(msg.sender, address(this), _amount));

        StakerDetails storage stakerDetails = _stakerAddressToDetails[msg.sender];
        stakerDetails.stakedBalance += _amount;
        stakerDetails.maxReward = stakerDetails.stakedBalance * 5;
        stakerDetails.lastStakedOn = block.timestamp;
        stakerDetails.nextRewardClaimedOn = block.timestamp + _waitingPeriod;

        if(!_isStaker[msg.sender]){
            stakerDetails.walletAddress = msg.sender;
            _isStaker[msg.sender] = true;
        }

        address referrer = _refereeToReferrer[msg.sender];

        if(referrer != address(0)){
            uint256 referralReward = (_amount * referralRewardPercentage) / 100;
            require(
                IERC20(_busdContractAddress).balanceOf(address(this)) >= referralReward,
                "ContractHaveNoBalance: Contract do not have enough balance."
            );
            require(IERC20(_busdContractAddress).transfer(referrer, referralReward));
        }
        emit Staked(msg.sender, _amount, block.timestamp);
    }

    /**
     * @dev Un-staking BUSD from the contract. Updating staker details.
     * Staker will get 50% of their staked balance. Rest of the balance are not accessable.
     * Means the balance will be 0.
     */
    function unstake()
        external whenNotPaused nonReentrant onlyStaker balanceMoreThanZero {
        StakerDetails storage stakerDetails = _stakerAddressToDetails[msg.sender];

        require(
            stakerDetails.totalRewardsClaimed < (stakerDetails.stakedBalance / 2),
            "AlreadyGot50PercentReward: You cannot withdraw amount anymore."
        );

        uint256 halfOfTheBalance = stakerDetails.stakedBalance / 2;

        stakerDetails.stakedBalance = 0;
        stakerDetails.maxReward = 0;
        stakerDetails.totalRewardsClaimed = 0;
        stakerDetails.withdrawableBalance = 0;

        require(
            IERC20(_busdContractAddress).balanceOf(address(this)) >= halfOfTheBalance,
            "ContractHaveNoBalance: Contract do not have enough balance."
        );

        require(IERC20(_busdContractAddress).transfer(msg.sender, halfOfTheBalance));

        emit Unstaked(msg.sender, halfOfTheBalance, block.timestamp);
    }

    /**
     * @dev Referring Someone and updating details.
     * @param _referee: The address to whom is referring.
     */
    function refer(address _referee)
        external whenNotPaused nonReentrant onlyStaker notReferred(_referee)
        notStaker(_referee) botheAddressAreNotSame(msg.sender, _referee) {
        
        _refereeToReferrer[_referee] = msg.sender;
        _isReferred[msg.sender] = true;
        _isReferred[_referee] = true;
        _stakerAddressToDetails[msg.sender].referrals.push(_referee);

        emit Referred(msg.sender, _referee, block.timestamp);
    }

    /**
     * @dev Claimming daily rewards after 24 hours. Updating user details.
     */
    function claimDailyReward()
        external whenNotPaused nonReentrant onlyStaker balanceMoreThanZero {
        StakerDetails storage stakerDetails = _stakerAddressToDetails[msg.sender];

        require(
            stakerDetails.nextRewardClaimedOn <= block.timestamp,
            "NoRewardsAvailableNow: You have to wait till next reward claim time."
        );

        require(
            stakerDetails.totalRewardsClaimed <= stakerDetails.maxReward,
            "AlreadyGotMaxReward: You cannot with anymore cause you already got 5x reward."
        );

        uint256 dailyReward = (stakerDetails.stakedBalance * dailyRewardPercentage) / 100;

        stakerDetails.withdrawableBalance += dailyReward;
        stakerDetails.totalRewardsClaimed += dailyReward;
        stakerDetails.previousRewardClaimedOn = block.timestamp;
        stakerDetails.nextRewardClaimedOn = block.timestamp + _waitingPeriod;

        emit DailyRewardClaimed(msg.sender, dailyReward, block.timestamp);
    }

    /**
     * @dev Withdrawing daily rewards. Updating staker details.
     */
    function withdrawDailyRewards()
        external whenNotPaused nonReentrant onlyStaker balanceMoreThanZero {
        StakerDetails storage stakerDetails = _stakerAddressToDetails[msg.sender];
        uint256 sevenTimesDailyRewards = (stakerDetails.stakedBalance * dailyRewardPercentage * 7) / 100;
        require(
            stakerDetails.withdrawableBalance >= sevenTimesDailyRewards,
            "SevenTimesDailyReward: You have to wait 7 days to withdraw rewards."
        );

        uint256 withdrawableAmount = stakerDetails.withdrawableBalance / 2;

        stakerDetails.withdrawableBalance = withdrawableAmount;

        require(
            IERC20(_busdContractAddress).balanceOf(address(this)) >= withdrawableAmount,
            "ContractHaveNoBalance: Contract do not have enough balance."
        );

        require(IERC20(_busdContractAddress).transfer(msg.sender, withdrawableAmount));

        emit DailyRewardsWithdrawn(msg.sender, withdrawableAmount, block.timestamp);
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