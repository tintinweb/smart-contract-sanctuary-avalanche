/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-07
*/

// File: contracts/interfaces/IElkPair.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.5.0;

interface IElkPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/interfaces/IElkDexOracle.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;

interface IElkDexOracle {

    function weth() external view returns(address);

    function factory() external view returns(address);

    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns(uint);

    function consultWeth(address tokenIn, uint amountIn) external view returns(uint);

    function update(address tokenA, address tokenB) external;

    function updateWeth(address token) external;

}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/interfaces/IElkFarmFactory.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IElkFarmFactory {

    event ContractCreated(address _newContract);
    event ManagerSet(address _farmManager);
    event FeeSet(uint256 newFee);
    event FeesRecovered(uint256 balanceRecovered);

    function factoryHelper() external view returns(address);
    function getFarm(address creator, address lpTokenAddress) external view returns(address);
    function allFarms(uint index) external view returns(address);
    function farmManager() external view returns(address);
    function getCreator(address farmAddress) external view returns(address);
    function fee() external view returns(uint256);
    function maxFee() external view returns(uint256);
    function feeToken() external view returns(IERC20);

    function createNewRewards(address _oracleAddress,
        address _lpTokenAddress,
        address _coverageTokenAddress,
        uint256 _coverageAmount,
        uint32 _coverageVestingDuration,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule) external;
    
    function setManager(address managerAddress) external;
    function overrideOwnership(address farmAddress) external;
    function setFee(uint256 newFee) external;
    function withdrawFees() external;

}

// File: contracts/interfaces/IStaking.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IStaking {

/* ========== STATE VARIABLES ========== */
function stakingToken() external pure returns(IERC20);
function totalSupply() external pure returns(uint256);
function balances(address account) external view returns(uint256);

/* ========== MUTATIVE FUNCTIONS ========== */
function stakeWithPermit(uint256 _amount, uint _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;
function stake(uint256 _amount) external;
function withdraw(uint256 _amount) external;
function exit() external;
function recoverERC20(address _tokenAddress, address _recipient, uint256 _amount) external;

/* ========== EVENTS ========== */

event Staked(address indexed account, uint256 amount);
event Withdrawn(address indexed account, uint256 amount);
event Recovered(address indexed token, address indexed recipient, uint256 amount);

}

// File: contracts/interfaces/IStakingFee.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;



interface IStakingFee is IStaking {

    /* ========== STATE VARIABLES ========== */
    function feesUnit() external pure returns(uint16);
    function maxFee() external pure returns(uint16);

    function withdrawalFeeSchedule() external pure returns(uint256[] memory);
    function withdrawalFeesBps() external pure returns(uint256[] memory);
    function depositFeeBps() external pure returns(uint256);
    function collectedFees() external pure returns(uint256);

    function userLastStakedTime(address user) external pure returns(uint32);

    /* ========== VIEWS ========== */

    function depositFee(uint256 _depositAmount) external view returns (uint256);
    function withdrawalFee(address _account, uint256 _withdrawalAmount) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverFees(address _recipient) external;
    function setFees(uint16 _depositFeeBps, uint16[] memory _withdrawalFeesBps, uint32[] memory _withdrawalFeeSchedule) external;

    /* ========== EVENTS ========== */
        
    event FeesSet(uint16 depositFeeBps, uint16[] withdrawalFeesBps, uint32[] feeSchedule);
    event DepositFeesCollected(address indexed user, uint256 amount);
    event WithdrawalFeesCollected(address indexed user, uint256 amount);
    event FeesRecovered(uint256 amount);

}

// File: contracts/interfaces/IStakingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;



interface IStakingRewards is IStakingFee {

    /* ========== STATE VARIABLES ========== */

    function rewardTokens() external pure returns(IERC20[] memory);
    function rewardTokenAddresses(address rewardAddress) external pure returns(bool);
    function periodFinish() external pure returns(uint256);
    function rewardsDuration() external pure returns(uint256);
    function lastUpdateTime() external pure returns(uint256);
    function rewardRates(address rewardAddress) external pure returns(uint256);
    function rewardPerTokenStored(address rewardAddress) external pure returns(uint256);

    // wallet address => token address => amount
    function userRewardPerTokenPaid(address walletAddress, address tokenAddress) external pure returns(uint256);
    function rewards(address walletAddress, address tokenAddress) external pure returns(uint256);


    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken(address _tokenAddress) external view returns (uint256);
    function earned(address _tokenAddress, address _account) external view returns (uint256);
    function emitting() external view returns(bool);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getReward(address _tokenAddress, address _recipient) external;
    function getRewards(address _recipient) external;

    // Must send reward before calling this!
    function startEmission(uint256[] memory _rewards, uint256 _duration) external;
    function stopEmission(address _refundAddress) external;
    function recoverLeftoverReward(address _tokenAddress, address _recipient) external;
    function addRewardToken(address _tokenAddress) external;

    /* ========== EVENTS ========== */

    event RewardPaid(address indexed token, address indexed account, uint256 reward);
    event LeftoverRewardRecovered(address indexed recipient, uint256 amount);
    event RewardsEmissionStarted(uint256[] rewards, uint256 duration);
    event RewardsEmissionEnded();

}

// File: contracts/interfaces/IFarmingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;





interface IFarmingRewards is IStakingRewards {

    struct Position {
            uint112 amount0;
            uint112 amount1;
            uint32 blockTimestamp;
        }

    /* ========== STATE VARIABLES ========== */

    function oracle() external pure returns(IElkDexOracle);
    function lpToken() external pure returns(IElkPair);
    function coverageTokenAddress() external pure returns(address);
    function coverageAmount() external pure returns(uint256);
    function coverageVestingDuration() external pure returns(uint32);
    function coverageRate() external pure returns(uint256);
    function coveragePerTokenStored() external pure returns(uint256);
    function userCoveragePerTokenPaid(address tokenPaid) external pure returns(uint256);
    function coverage(address token) external pure returns(uint256);
    function lastStakedPosition(address user) external pure returns(Position memory);

    /* ========== VIEWS ========== */

    function coveragePerToken() external view returns (uint256);
    function coverageEarned(address _account) external view returns(uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getCoverage(address _recipient) external;
    function startEmission(uint256[] memory _rewards, uint256 _duration) external override;
    function startEmission(uint256[] memory _rewards, uint256 _coverage, uint256 _duration) external;
    function recoverLeftoverCoverage(address _recipient) external;

    /* ========== OWNERSHIP FUNCTIONS ========== */

    function transferOwnership(address newOwner) external;

    /* ========== EVENTS ========== */

    event CoveragePaid(address indexed account, uint256 coverage);
    event LeftoverCoverageRecovered(address indexed recipient, uint256 amount);

}

// /* ========== STATE VARIABLES ========== */

    // function rewardsToken() external pure returns(IERC20);
    // function stakingToken() external pure returns(IERC20);
    // function periodFinish() external pure returns(uint256);
    // function rewardRate() external pure returns(uint256);
    // function rewardsDuration() external pure returns(uint256);
    // function lastUpdateTime() external pure returns(uint256);
    // function rewardPerTokenStored() external pure returns(uint256);
    // function userRewardPerTokenPaid(address user) external pure returns(uint256);
    // function rewards(address user) external pure returns(uint256);
    // function boosterToken() external pure returns(IERC20);
    // function boosterRewardRate() external pure returns(uint256);
    // function boosterRewardPerTokenStored() external pure returns(uint256);
    // function userBoosterRewardPerTokenPaid(address user) external pure returns(uint256);
    // function boosterRewards(address user) external pure returns(uint256);
    // function coverages(address user) external pure returns(uint256);
    // function totalCoverage() external pure returns(uint256);
    // function feeSchedule() external pure returns(uint256[] memory);
    // function withdrawalFeesPct() external pure returns(uint256[] memory);
    // function withdrawalFeesUnit() external pure returns(uint256);
    // function maxWithdrawalFee() external pure returns(uint256);
    // function lastStakedTime(address user) external pure returns(uint256);
    // function totalFees() external pure returns(uint256);

    // /* ========== VIEWS ========== */

    // function totalSupply() external view returns (uint256);
    // function balanceOf(address account) external view returns (uint256);
    // function lastTimeRewardApplicable() external view returns (uint256);
    // function rewardPerToken() external view returns (uint256);
    // function earned(address account) external view returns (uint256);
    // function getRewardForDuration() external view returns (uint256);
    // function boosterRewardPerToken() external view returns (uint256);
    // function boosterEarned(address account) external view returns (uint256);
    // function getBoosterRewardForDuration() external view returns (uint256);
    // function exitFee(address account) external view returns (uint256);
    // function fee(address account, uint256 withdrawalAmount) external view returns (uint256);

    // /* ========== MUTATIVE FUNCTIONS ========== */

    // function stake(uint256 amount) external;
    // function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    // function withdraw(uint256 amount) external;
    // function emergencyWithdraw(uint256 amount) external;
    // function getReward() external;
    // function getBoosterReward() external;
    // function getCoverage() external;
    // function exit() external;

    // /* ========== RESTRICTED FUNCTIONS ========== */

    // function sendRewardsAndStartEmission(uint256 reward, uint256 boosterReward, uint256 duration) external;
    // function startEmission(uint256 reward, uint256 boosterReward, uint256 duration) external;
    // function stopEmission() external;
    // function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
    // function recoverLeftoverReward() external;
    // function recoverLeftoverBooster() external;
    // function recoverFees() external;
    // function setRewardsDuration(uint256 duration) external;

    // // Booster Rewards

    // function setBoosterToken(address _boosterToken) external;

    // // ILP

    // function setCoverageAmount(address addr, uint256 amount) external;
    // function setCoverageAmounts(address[] memory addresses, uint256[] memory amounts) external;
    // function pause() external;
    // function unpause() external;

    // // Withdrawal Fees

    // function setWithdrawalFees(uint256[] memory _feeSchedule, uint256[] memory _withdrawalFees) external;

    // /* ========== EVENTS ========== */

    // event Staked(address indexed user, uint256 amount);
    // event Withdrawn(address indexed user, uint256 amount);
    // event CoveragePaid(address indexed user, uint256 amount);
    // event RewardPaid(address indexed user, uint256 reward);
    // event BoosterRewardPaid(address indexed user, uint256 reward);
    // event RewardsDurationUpdated(uint256 newDuration);
    // event Recovered(address token, uint256 amount);
    // event LeftoverRewardRecovered(uint256 amount);
    // event LeftoverBoosterRecovered(uint256 amount);
    // event RewardsEmissionStarted(uint256 reward, uint256 boosterReward, uint256 duration);
    // event RewardsEmissionEnded(uint256 amount);
    // event BoosterRewardSet(address token);
    // event WithdrawalFeesSet(uint256[] _feeSchedule, uint256[] _withdrawalFees);
    // event FeesCollected(address indexed user, uint256 amount);
    // event FeesRecovered(uint256 amount);

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/FarmManager.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;




contract FarmManager is Ownable {

    IElkFarmFactory public farmFactory;
    event farmFactorySet(address _factoryAddress);
    event RewardsReceived(address _farm);

    constructor (address factoryAddress) {
        farmFactory = IElkFarmFactory(factoryAddress);
    }

    function setFarmFactory(address factoryAddress) external onlyOwner {
        require(factoryAddress != address(0), "factoryAddress is the zero address");
        farmFactory = IElkFarmFactory(factoryAddress);
        emit farmFactorySet(factoryAddress);
    }

    /* ========== MODIFIERS ========== */

    modifier checkOwnership(address farmAddress) {
        IFarmingRewards rewardsContract = IFarmingRewards(farmAddress);
        address lpTokenAddress = address(rewardsContract.stakingToken());
        require(farmFactory.getFarm(msg.sender, lpTokenAddress) == farmAddress, "caller is not owner");
        _;
    }

    /* ========== Farm Functions ========== */

    // must send rewards before calling
    function startEmissionWithCoverage(address farmAddress, uint256[] memory _rewards, uint256 _coverage, uint256 _duration) external checkOwnership(farmAddress) {
        IFarmingRewards(farmAddress).startEmission(_rewards, _coverage, _duration);
    }

    function startEmission(address farmAddress, uint256[] memory _rewards, uint256 _duration) external checkOwnership(farmAddress) {
        IFarmingRewards(farmAddress).startEmission(_rewards, _duration);
    }

    // refunds reward token(s) to msg.sender
    function stopEmission(address farmAddress) external checkOwnership(farmAddress) {
        IFarmingRewards(farmAddress).stopEmission(msg.sender);
    }

    // recovers ERC20 to msg.sender
    function recoverERC20(address farmAddress, address _tokenAddress, uint256 _amount) external checkOwnership(farmAddress) {
        IFarmingRewards(farmAddress).recoverERC20(_tokenAddress, msg.sender, _amount);
    } 

    // recovers given leftover reward to msg.sender
    function recoverLeftoverReward(address farmAddress, address _tokenAddress) external checkOwnership(farmAddress) {
        IFarmingRewards(farmAddress).recoverLeftoverReward(_tokenAddress, msg.sender);
    }

    function addRewardToken(address farmAddress, address _tokenAddress) external checkOwnership(farmAddress) {
        IFarmingRewards(farmAddress).addRewardToken(_tokenAddress);
    }

    //check: can no longer set rewards duration?

        // function setRewardsDuration(address farmAddress, uint256 duration) external {
        //     _checkOwnership(farmAddress);
        //     IFarmingRewards(farmAddress).setRewardsDuration(duration);
        // }


    /* ========== ILP ========== */

    function recoverLeftoverCoverage(address farmAddress) external checkOwnership(farmAddress) {
        IFarmingRewards(farmAddress).recoverLeftoverCoverage(msg.sender);

    }

    // check: No longer need to set coverage amounts?

        // function setCoverageAmount(address farmAddress, address addr, uint256 amount) public {
        //     _checkOwnership(farmAddress);
        //     IFarmingRewards(farmAddress).setCoverageAmount(addr, amount);
        // }

        // function setCoverageAmounts(address farmAddress, address[] memory addresses, uint256[] memory amounts) external {
        //     _checkOwnership(farmAddress);
        //     IFarmingRewards(farmAddress).setCoverageAmounts(addresses, amounts);
        // }

    // check: Can't pause / unpause?

        // function unpause(address farmAddress) external  {
        //     _checkOwnership(farmAddress);
        //     IFarmingRewards(farmAddress).unpause();
        // }

        // function pause(address farmAddress) external {
        //     _checkOwnership(farmAddress);
        //     IFarmingRewards(farmAddress).pause();
        // }

    /* ========== FEES ========== */

    function setFees(address farmAddress, uint16 _depositFeeBps, uint16[] memory _withdrawalFeesBps, uint32[] memory _withdrawalFeeSchedule) external checkOwnership(farmAddress) {
        IFarmingRewards(farmAddress).setFees(_depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule);
    }

    // withdraw fees to msg.sender
    function recoverFees(address farmAddress) external checkOwnership(farmAddress) {
        IFarmingRewards(farmAddress).recoverFees(msg.sender);
    }

    /* ========== FARMER FUNCTIONS ========== */


    // can't get coverage due to msg.sender == _recipient

    function multiClaim(address[] memory _farms) external {

        require(_farms.length < 30, "Too many contracts, use less than 30");

        for (uint i = 0; i < _farms.length; i++) {
            address farmAddress = address(_farms[i]);
            IFarmingRewards(farmAddress).getRewards(msg.sender);

            emit RewardsReceived(_farms[i]);

        }

    }

    


    // function multiExit(address[] memory farms) external {

    //     require(farms.length < 30, "Too many contracts, use less than 30");
    //     for (uint i = 0; i < farms.length; i++) {
    //         address farmAddress = address(farms[i]);
    //         IFarmingRewardsAdj(farmAddress).exitExternal(msg.sender);
    //     }

    // }


}