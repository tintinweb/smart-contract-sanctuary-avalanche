/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-28
*/

// SPDX-License-Identifier: BUSL-1.1
//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>
// - Elijah <[email protected]>
// - Snake <[email protected]>

// File: contracts/interfaces/IFarmManager.sol


pragma solidity >=0.8.0;

interface IFarmManager {
    event FarmFactorySet(address factoryAddress);
    event RewardsReceived(address farm);

    function setFarmFactory(address _factoryAddress) external;

    function startEmissionWithCoverage(
        address _farmAddress,
        uint256[] memory _rewards,
        uint256 _coverage,
        uint256 _duration
    ) external;

    function startEmission(
        address _farmAddress,
        uint256[] memory _rewards,
        uint256 _duration
    ) external;

    function stopEmission(address _farmAddress) external;

    function recoverERC20(
        address _farmAddress,
        address _tokenAddress,
        uint256 _amount
    ) external;

    function recoverLeftoverReward(
        address _farmAddress,
        address _tokenAddress
    ) external;

    function addRewardToken(
        address _farmAddress,
        address _tokenAddress
    ) external;

    function recoverLeftoverCoverage(address _farmAddress) external;

    function setFees(
        address _farmAddress,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    ) external;

    function recoverFees(address _farmAddress) external;

    function multiClaim(address[] memory _farms) external;
}

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

    function balanceOf(address _owner) external view returns (uint);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint);

    function approve(address _spender, uint _value) external returns (bool);

    function transfer(address _to, uint _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address _owner) external view returns (uint);

    function permit(
        address _owner,
        address _spender,
        uint _value,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
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

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address _to) external returns (uint liquidity);

    function burn(address _to) external returns (uint amount0, uint amount1);

    function swap(
        uint _amount0Out,
        uint _amount1Out,
        address _to,
        bytes calldata _data
    ) external;

    function skim(address _to) external;

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
    struct Observation {
        uint timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
    }

    function weth() external view returns (address);

    function factory() external view returns (address);

    function windowSize() external view returns (uint);

    function granularity() external view returns (uint8);

    function periodSize() external view returns (uint);

    function pairObservations(
        address _pair
    ) external view returns (Observation[] memory);

    function observationIndexOf(uint _timestamp) external view returns (uint);

    function update(address _tokenA, address _tokenB) external;

    function updateWeth(address _token) external;

    function consult(
        address _tokenIn,
        uint _amountIn,
        address _tokenOut
    ) external view returns (uint);

    function consultWeth(
        address _tokenIn,
        uint _amountIn
    ) external view returns (uint);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC20/IERC20.sol


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
    event FeeSet(uint256 _newFee);
    event FeesRecovered(uint256 _balanceRecovered);

    function getFarm(
        address _creator,
        address _lpTokenAddress
    ) external view returns (address);

    function getPermissionedFarm(
        address _creator,
        address _lpTokenAddress
    ) external view returns (address);

    function isFarm(address _farmAddress) external view returns (bool);

    function isPermissionedFarm(address _farmAddress) external view returns (bool);

    function allFarms(uint _index) external view returns (address);

    function allFarmsLength() external view returns (uint256);

    function farmManager() external view returns (address);

    function getCreator(address _farmAddress) external view returns (address);

    function feeToken() external view returns (IERC20);

    function fee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function oracleAddress() external view returns (address);

    function createNewRewards(
        address _lpTokenAddress,
        address _coverageTokenAddress,
        uint256 _coverageAmount,
        uint32 _coverageVestingDuration,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    ) external;

     function createNewPermissonedRewards(
        address _lpTokenAddress,
        address _coverageTokenAddress,
        uint256 _coverageAmount,
        uint32 _coverageVestingDuration,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    ) external;

    function setManager(address _managerAddress) external;

    function setFee(uint256 _newFee) external;

    function withdrawFees() external;

    function overrideOwnership(address _farmAddress) external;
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
    function stakingToken() external returns (IERC20);

    function totalSupply() external returns (uint256);

    function balances(address _account) external returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 _amount) external returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256);

    function exit() external;

    function recoverERC20(
        address _tokenAddress,
        address _recipient,
        uint256 _amount
    ) external;

    /* ========== EVENTS ========== */

    // Emitted on staking
    event Staked(address indexed account, uint256 amount);

    // Emitted on withdrawal (including exit)
    event Withdrawn(address indexed account, uint256 amount);

    // Emitted on token recovery
    event Recovered(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );
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
    function feesUnit() external returns (uint16);

    function maxFee() external returns (uint16);

    function withdrawalFeeSchedule(uint256) external returns (uint256);

    function withdrawalFeesBps(uint256) external returns (uint256);

    function depositFeeBps() external returns (uint256);

    function collectedFees() external returns (uint256);

    function userLastStakedTime(address _user) external view returns (uint32);

    /* ========== VIEWS ========== */

    function depositFee(uint256 _depositAmount) external view returns (uint256);

    function withdrawalFee(
        address _account,
        uint256 _withdrawalAmount
    ) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverFees(address _recipient) external;

    function setFees(
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    ) external;

    /* ========== EVENTS ========== */

    // Emitted when fees are (re)configured
    event FeesSet(
        uint16 _depositFeeBps,
        uint16[] _withdrawalFeesBps,
        uint32[] _feeSchedule
    );

    // Emitted when a deposit fee is collected
    event DepositFeesCollected(address indexed _user, uint256 _amount);

    // Emitted when a withdrawal fee is collected
    event WithdrawalFeesCollected(address indexed _user, uint256 _amount);

    // Emitted when fees are recovered by governance
    event FeesRecovered(uint256 _amount);
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

    function rewardTokens(uint256) external view returns (IERC20);

    function rewardTokenAddresses(
        address _rewardAddress
    ) external view returns (bool);

    function periodFinish() external view returns (uint256);

    function rewardsDuration() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function rewardRates(
        address _rewardAddress
    ) external view returns (uint256);

    function rewardPerTokenStored(
        address _rewardAddress
    ) external view returns (uint256);

    // wallet address => token address => amount
    function userRewardPerTokenPaid(
        address _walletAddress,
        address _tokenAddress
    ) external view returns (uint256);

    function rewards(
        address _walletAddress,
        address _tokenAddress
    ) external view returns (uint256);

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken(
        address _tokenAddress
    ) external view returns (uint256);

    function earned(
        address _tokenAddress,
        address _account
    ) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getReward(address _tokenAddress, address _recipient) external;

    function getRewards(address _recipient) external;

    // Must send reward before calling this!
    function startEmission(
        uint256[] memory _rewards,
        uint256 _duration
    ) external;

    function stopEmission(address _refundAddress) external;

    function recoverLeftoverReward(
        address _tokenAddress,
        address _recipient
    ) external;

    function addRewardToken(address _tokenAddress) external;

    function rewardTokenIndex(
        address _tokenAddress
    ) external view returns (int8);

    /* ========== EVENTS ========== */

    // Emitted when a reward is paid to an account
    event RewardPaid(
        address indexed _token,
        address indexed _account,
        uint256 _reward
    );

    // Emitted when a leftover reward is recovered
    event LeftoverRewardRecovered(address indexed _recipient, uint256 _amount);

    // Emitted when rewards emission is started
    event RewardsEmissionStarted(uint256[] _rewards, uint256 _duration);

    // Emitted when rewards emission ends
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
    /// @notice Represents a snapshot of an LP position at a given timestamp
    struct Position {
        uint112 amount0;
        uint112 amount1;
        uint32 blockTimestamp;
    }

    /* ========== STATE VARIABLES ========== */

    function oracle() external returns (IElkDexOracle);

    function lpToken() external returns (IElkPair);

    function coverageTokenAddress() external returns (address);

    function coverageAmount() external returns (uint256);

    function coverageVestingDuration() external returns (uint32);

    function coverageRate() external returns (uint256);

    function coveragePerTokenStored() external returns (uint256);

    function userCoveragePerTokenPaid(
        address _tokenPaid
    ) external returns (uint256);

    function coverage(address _token) external returns (uint256);

    function lastStakedPosition(
        address _user
    )
        external
        returns (uint112 amount0, uint112 amount1, uint32 blockTimeStamp);

    /* ========== VIEWS ========== */

    function coveragePerToken() external view returns (uint256);

    function coverageEarned(address _account) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getCoverage(address _recipient) external;

    

    function startEmission(
        uint256[] memory _rewards,
        uint256 _coverage,
        uint256 _duration
    ) external;

    function recoverLeftoverCoverage(address _recipient) external;

    /* ========== EVENTS ========== */

    // Emitted when the coverage is paid to an account
    event CoveragePaid(address indexed account, uint256 coverage);

    // Emitted when the leftover coverage is recovered
    event LeftoverCoverageRecovered(address indexed recipient, uint256 amount);
}

// File: contracts/interfaces/IFarmingRewardsPermissioned.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IFarmingRewardsPermissioned is IFarmingRewards {

    function setAddressPermission(address _walletAddress, bool _permission) external;

}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/access/Ownable.sol


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
// - Elijah <[email protected]>
// - Snake <[email protected]>

pragma solidity >=0.8.0;






/**
 * This contract serves as the main point of contact between any FarmingRewards creators and their farm contract.
 * It contains any function in FarmingRewards that would normally be restricted to the owner and allows access to its functionality as long as the caller is the known owner in the ElkFarmFactory contract.
 */
contract FarmManager is IFarmManager, Ownable {
    /* ========== STATE VARIABLES ========== */

    /// @notice Interface to the farm factory
    IElkFarmFactory public farmFactory;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param _factoryAddress The address of the ElkFarmFactory contract.
     */
    constructor(address _factoryAddress) {
        require(
            _factoryAddress != address(0),
            "factoryAddress is the zero address"
        );
        farmFactory = IElkFarmFactory(_factoryAddress);
    }

    /**
     * @notice Utility function for use by Elk in order to change the ElkFarmFactory if needed.
     * @param _factoryAddress The address of the ElkFarmFactory contract.
     */
    function setFarmFactory(address _factoryAddress) external onlyOwner {
        require(
            _factoryAddress != address(0),
            "factoryAddress is the zero address"
        );
        farmFactory = IElkFarmFactory(_factoryAddress);
        emit FarmFactorySet(_factoryAddress);
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice The check used by each function that interacts with the FarmingRewards contract. It reads from the owners stored in ElkFarmFactory to determine if the caller is the known owner of the FarmingRewards contract it is trying to interact with.
     * @param _farmAddress The address of the FarmingRewards contract.
     */
    modifier checkOwnership(address _farmAddress) {
        require(
            farmFactory.isFarm(_farmAddress) ||
                farmFactory.isPermissionedFarm(_farmAddress),
            "Given address is not a known farm."
        );

        IFarmingRewards rewardsContract = IFarmingRewards(_farmAddress);
        address lpTokenAddress = address(rewardsContract.stakingToken());

        if (farmFactory.isFarm(_farmAddress)) {
            require(
                farmFactory.getFarm(msg.sender, lpTokenAddress) == _farmAddress,
                "caller is not owner"
            );
        } else {
            require(
                farmFactory.getPermissionedFarm(msg.sender, lpTokenAddress) ==
                    _farmAddress,
                "caller is not owner"
            );
        }

        _;
    }

    /* ========== Farm Functions ========== */

    /**
     * @notice Starts the farm emission for the given FarmingRewards contract address. The amount of rewards per rewards token, ILP coverage amount, and duration of the
     * farm emissions must be supplied. Any reward or coverage tokens must be sent to the FarmingRewards contract before this function is called.
     * @param _farmAddress The address of the FarmingRewards contract.
     * @param _rewards An array of rewards indexed by reward token number.
     * @param _coverage The amount of coverage for the farm.
     * @param _duration How long the farm will emit rewards and provide coverage.
     */
    function startEmissionWithCoverage(
        address _farmAddress,
        uint256[] memory _rewards,
        uint256 _coverage,
        uint256 _duration
    ) external checkOwnership(_farmAddress) {
        IFarmingRewards(_farmAddress).startEmission(
            _rewards,
            _coverage,
            _duration
        );
    }

    /**
     * @notice Same utility as startEmissionWithCoverage, but coverage does not need to be supplied.
     * @param _farmAddress The address of the FarmingRewards contract.
     * @param _rewards The amount of rewards per rewards token.
     * @param _duration The duration of the farm emissions.
     */
    function startEmission(
        address _farmAddress,
        uint256[] memory _rewards,
        uint256 _duration
    ) external checkOwnership(_farmAddress) {
        IFarmingRewards(_farmAddress).startEmission(_rewards, _duration);
    }

    /**
     * @notice Stops the given farm's emissions and refunds any leftover reward token(s) to the msg.sender.
     * @param _farmAddress The address of the FarmingRewards contract.
     */
    function stopEmission(
        address _farmAddress
    ) external checkOwnership(_farmAddress) {
        IFarmingRewards(_farmAddress).stopEmission(msg.sender);
    }

    /**
     * @notice Recovers an ERC20 token to the owners wallet. The token cannot be the staking token or any of the rewards tokens for the farm.
     * @dev Ensures any unnecessary tokens are not lost if sent to the farm contract.
     * @param _farmAddress The address of the FarmingRewards contract.
     * @param _tokenAddress The address of the token to recover.
     * @param _amount The amount of the token to recover.
     */
    function recoverERC20(
        address _farmAddress,
        address _tokenAddress,
        uint256 _amount
    ) external checkOwnership(_farmAddress) {
        IFarmingRewards(_farmAddress).recoverERC20(
            _tokenAddress,
            msg.sender,
            _amount
        );
    }

    /**
     * @notice Recovers the given leftover reward token to the msg.sender. Cannot be called while the farm is active or if there are any LP tokens staked in the contract.
     * @param _farmAddress The address of the FarmingRewards contract.
     * @param _tokenAddress The address of the token to recover.
     */
    function recoverLeftoverReward(
        address _farmAddress,
        address _tokenAddress
    ) external checkOwnership(_farmAddress) {
        IFarmingRewards(_farmAddress).recoverLeftoverReward(
            _tokenAddress,
            msg.sender
        );
    }

    /**
     * @notice Utility function that allows the farm owner to add a new reward token to the contract. Cannot be called while the farm is active.
     * @param _farmAddress The address of the FarmingRewards contract.
     * @param _tokenAddress The address of the token to add.
     */
    function addRewardToken(
        address _farmAddress,
        address _tokenAddress
    ) external checkOwnership(_farmAddress) {
        IFarmingRewards(_farmAddress).addRewardToken(_tokenAddress);
    }

    /* ========== ILP ========== */

    /**
     * @notice Recovers the given leftover coverage token to the msg.sender. Cannot be called while the farm is active or if there are any LP tokens staked in the contract.
     * @param _farmAddress The address of the FarmingRewards contract.
     */
    function recoverLeftoverCoverage(
        address _farmAddress
    ) external checkOwnership(_farmAddress) {
        IFarmingRewards(_farmAddress).recoverLeftoverCoverage(msg.sender);
    }

    /* ========== FEES ========== */

    /**
     * @notice Allows the farm owner to set the withdrawal and deposit fees to be used in the farm.
     * @param _farmAddress The address of the FarmingRewards contract.
     * @param _depositFeeBps The deposit fee in basis points.
     * @param _withdrawalFeesBps The withdrawal fee in basis points.
     * @param _withdrawalFeeSchedule The schedule for the withdrawal fee to be applied.
     */
    function setFees(
        address _farmAddress,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    ) external checkOwnership(_farmAddress) {
        IFarmingRewards(_farmAddress).setFees(
            _depositFeeBps,
            _withdrawalFeesBps,
            _withdrawalFeeSchedule
        );
    }

    /**
     * @notice Withdraw fees collected from deposits/withdrawals in the FarmingRewards contract to msg.sender.
     * @param _farmAddress The address of the FarmingRewards contract.
     */
    function recoverFees(
        address _farmAddress
    ) external checkOwnership(_farmAddress) {
        IFarmingRewards(_farmAddress).recoverFees(msg.sender);
    }

    /**
     * @notice Withdraw fees collected from deposits/withdrawals in the FarmingRewards contract to msg.sender.
     * @param _walletAddress The wallet address to permit.
     * @param _permission true to allow, false to revoke permit.
     * @param _permissionedFarmAddress The address of the FarmingRewardsPermissioned contract.
     */
    function setAddressPermission(
        address _walletAddress,
        bool _permission,
        address _permissionedFarmAddress
    ) external checkOwnership(_permissionedFarmAddress) {
        IFarmingRewardsPermissioned(_permissionedFarmAddress)
            .setAddressPermission(_walletAddress, _permission);
    }

    /* ========== FARMER FUNCTIONS ========== */

    /**
     * @notice Function for farm users to claim rewards from multiple farms at once.
     * @param _farms The addresses of the FarmingRewards contracts.
     */
    function multiClaim(address[] memory _farms) external {
        require(_farms.length < 30, "Too many contracts, use less than 30");

        for (uint i = 0; i < _farms.length; i++) {
            address farmAddress = address(_farms[i]);
            IFarmingRewards(farmAddress).getRewards(msg.sender);

            emit RewardsReceived(_farms[i]);
        }
    }
}