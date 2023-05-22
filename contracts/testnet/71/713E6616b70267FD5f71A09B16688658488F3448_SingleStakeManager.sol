/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-21
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

// File: contracts/interfaces/ISingleStakeManager.sol


pragma solidity >=0.8.0;

interface ISingleStakeManager {
    event FarmFactorySet(address _factoryAddress);
    event RewardsReceived(address _farm);

    function setFarmFactory(address _factoryAddress) external;

    function startEmission(
        address _singleStakeAddress,
        uint256[] memory _rewards,
        uint256 _duration
    ) external;

    function stopEmission(address _singleStakeAddress) external;

    function recoverLeftoverReward(
        address _singleStakeAddress,
        address _tokenAddress
    ) external;

    function addRewardToken(
        address _singleStakeAddress,
        address _tokenAddress
    ) external;

    function recoverERC20(
        address _singleStakeAddress,
        address _tokenAddress,
        uint256 _amount
    ) external;
    
    function recoverFees(address _singleStakeAddress) external;

    function multiClaim(address[] memory _farms) external;
}

// File: contracts/interfaces/ISingleStakeFactory.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;

interface ISingleStakeFactory {
    event ContractCreated(address _newContract);
    event ManagerSet(address _farmManager);
    event FeeSet(uint256 _newFee);
    event FeesRecovered(uint256 _balanceRecovered);

    function getSingleStake(
        address _creator,
        address _stakingToken
    ) external view returns (address);

    function allFarms(uint _index) external view returns (address);

    function farmManager() external view returns (address);

    function getCreator(address _farmAddress) external view returns (address);

    function fee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function createNewSingleStake(
        address _stakingTokenAddress,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    ) external;

    function allFarmsLength() external view returns (uint);

    function setManager(address _managerAddress) external;

    function setFee(uint256 _newFee) external;

    function withdrawFees() external;

    function overrideOwnership(address _farmAddress) external;
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
    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

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
    function feesUnit() external returns (uint256);

    function maxFee() external returns (uint256);

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

// File: contracts/interfaces/ISingleStakingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface ISingleStakingRewards is IStakingRewards {
    event CompoundedReward(uint256 oldBalance, uint256 newBalance);

    function compoundSingleStakingRewards() external;
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

// File: contracts/SingleStakeManager.sol


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
 * This contract serves as the main point of contact between any SingleStakingRewards creators and their farm contract.
 * It contains any function in SingleStakingRewards that would normally be restricted to the owner and allows access to its functionality long as the caller is the known owner in the SingleStakeFactory contract.
 */
contract SingleStakeManager is ISingleStakeManager, Ownable {

    /* ========== STATE VARIABLES ========== */

    /// @notice Staking factory interface
    ISingleStakeFactory public stakeFactory;
    
    /* ========== CONSTRUCTOR ========== */

    /**
     * @param _factoryAddress The address of the SingleStakeFactory contract.
     */
    constructor(address _factoryAddress) {
        stakeFactory = ISingleStakeFactory(_factoryAddress);
    }

    /**
     * @notice Utility function for use by Elk in order to change the SingleStakingFactory if needed.
     * @param _factoryAddress The address of the SingleStakeFactory contract.
     */
    function setFarmFactory(address _factoryAddress) external onlyOwner {
        require(
            _factoryAddress != address(0),
            "factoryAddress is the zero address"
        );
        stakeFactory = ISingleStakeFactory(_factoryAddress);
        emit FarmFactorySet(_factoryAddress);
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice The check used by each function that interacts with the SingleStakingRewards contract. It reads from the owners stored in SingleStakingFactory to determine if the caller is the known owner of the SingleStakingRewards contract it is trying to interact with.
     * @param _singleStakeAddress The address of the SingleStakingRewards contract.
     */
    modifier checkOwnership(address _singleStakeAddress) {
        ISingleStakingRewards rewardsContract = ISingleStakingRewards(
            _singleStakeAddress
        );
        address lpTokenAddress = address(rewardsContract.stakingToken());
        require(
            stakeFactory.getSingleStake(msg.sender, lpTokenAddress) ==
                _singleStakeAddress,
            "caller is not owner"
        );
        _;
    }

    /* ========== Farm Functions ========== */

    /**
     * @dev Any reward tokens must be sent to the SingleStakingRewards contract before this function is called.
     * @notice Starts the farm emission for the given SingleStakingRewards contract address.
     * @param _singleStakeAddress The address of the SingleStakingRewards contract.
     * @param _rewards The amount of rewards per rewards token.
     * @param _duration The duration of the farm emissions.
     */
    function startEmission(
        address _singleStakeAddress,
        uint256[] memory _rewards,
        uint256 _duration
    ) external checkOwnership(_singleStakeAddress) {
        ISingleStakingRewards(_singleStakeAddress).startEmission(
            _rewards,
            _duration
        );
    }

    /**
     * @notice Stops the given farm's emissions and refunds any leftover reward token(s) to the msg.sender.
     * @param _singleStakeAddress The address of the SingleStakingRewards contract.
     */
    function stopEmission(
        address _singleStakeAddress
    ) external checkOwnership(_singleStakeAddress) {
        ISingleStakingRewards(_singleStakeAddress).stopEmission(msg.sender);
    }

    /**
     * @notice Recovers the given leftover reward token to the msg.sender.
     * @notice Cannot be called while the farm is active or if there are any LP tokens staked in the contract.
     * @param _singleStakeAddress The address of the SingleStakingRewards contract.
     * @param _tokenAddress The address of the token to recover.
     */
    function recoverLeftoverReward(
        address _singleStakeAddress,
        address _tokenAddress
    ) external checkOwnership(_singleStakeAddress) {
        ISingleStakingRewards(_singleStakeAddress).recoverLeftoverReward(
            _tokenAddress,
            msg.sender
        );
    }

    /**
     * @notice Utility function that allows the farm owner to add a new reward token to the contract.
     * @dev Cannot be called while the farm is active.
     * @param _singleStakeAddress The address of the SingleStakingRewards contract.
     * @param _tokenAddress The address of the token to add.
     */
    function addRewardToken(
        address _singleStakeAddress,
        address _tokenAddress
    ) external checkOwnership(_singleStakeAddress) {
        ISingleStakingRewards(_singleStakeAddress).addRewardToken(
            _tokenAddress
        );
    }

    /**
     * @notice Recovers an ERC20 token to the owners wallet. The token cannot be the staking token or any of the rewards tokens for the farm.
     * @dev Ensures any unnecessary tokens are not lost if sent to the farm contract.
     * @param _singleStakeAddress The address of the SingleStakingRewards contract.
     * @param _tokenAddress The address of the token to recover.
     * @param _amount The amount of the token to recover.
     */
    function recoverERC20(
        address _singleStakeAddress,
        address _tokenAddress,
        uint256 _amount
    ) external checkOwnership(_singleStakeAddress) {
        ISingleStakingRewards(_singleStakeAddress).recoverERC20(
            _tokenAddress,
            msg.sender,
            _amount
        );
    }

    /* ========== FEES ========== */
    
    /**
     * @notice Withdraw fees collected from deposits/withdrawals in the SingleStakingRewards contract to msg.sender.
     * @param _singleStakeAddress The address of the SingleStakingRewards contract.
     */
    function recoverFees(
        address _singleStakeAddress
    ) external checkOwnership(_singleStakeAddress) {
        ISingleStakingRewards(_singleStakeAddress).recoverFees(msg.sender);
    }

    /* ========== FARMER FUNCTIONS ========== */

    /**
     * @notice Function for farm users to claim rewards from multiple farms at once.
     * @param _farms The addresses of the SingleStakingRewards contracts.
     */
    function multiClaim(address[] memory _farms) external {
        require(_farms.length < 30, "Too many contracts, use less than 30");

        for (uint i = 0; i < _farms.length; i++) {
            address farmAddress = address(_farms[i]);
            ISingleStakingRewards(farmAddress).getRewards(msg.sender);

            emit RewardsReceived(_farms[i]);
        }
    }
}