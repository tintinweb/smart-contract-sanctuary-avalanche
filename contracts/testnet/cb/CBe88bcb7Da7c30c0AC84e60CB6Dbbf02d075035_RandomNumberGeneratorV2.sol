// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../miserable-flight/interfaces/IPolicyFlow.sol";
import "../utils/Ownable.sol";

/**
 * @title  Flight Oracle Mock
 * @notice Mock oracle contract for test.
 */
contract FlightOracleMock is Ownable {
    IPolicyFlow public policyFlow;

    uint256 public delayResult; // For test

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event PolicyFlowChanged(address newPolicyFlow);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Need the address of LINK token on specific network
     */
    constructor(address _policyFlow) Ownable(msg.sender) {
        policyFlow = IPolicyFlow(_policyFlow);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Only the policyFlow can call some functions
    modifier onlyPolicyFlow() {
        require(
            msg.sender == address(policyFlow),
            "Only the policyflow can call this function"
        );
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Change the policy flow contract address
     */
    function setPolicyFlow(address _policyFlow) external onlyOwner {
        policyFlow = IPolicyFlow(_policyFlow);
        emit PolicyFlowChanged(_policyFlow);
    }

    function setResult(uint256 _delayResult) external {
        delayResult = _delayResult;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Creates a request to the specified Oracle contract address
     * @dev This function ignores the stored Oracle contract address and
     *      will instead send the request to the address specified
     * @param _payment Payment to the oracle
     * @param _url The URL to fetch data from
     * @param _path The dot-delimited path to parse of the response
     * @param _times The number to multiply the result by
     */
    function newOracleRequest(
        uint256 _payment,
        string memory _url,
        string memory _path,
        int256 _times
    ) public view onlyPolicyFlow returns (bytes32 requestId) {
        requestId = keccak256(abi.encodePacked(_payment, _url, _path, _times));

        // fulfill(test_hash, delayResult);
        return requestId;
    }

    /**
     * @notice The fulfill method from requests created by this contract
     * @dev The recordChainlinkFulfillment protects this function from being called
     *      by anyone other than the oracle address that the request was sent to
     * @param _requestId The ID that was generated for the request
     */
    function fulfill(bytes32 _requestId) public {
        policyFlow.finalSettlement(_requestId, delayResult);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "./IPolicyStruct.sol";

/**
 * @title  IPolicyFlow
 * @notice This is the interface of PolicyFlow contract.
 *         Contains some type definations, event list and function declarations.
 */
interface IPolicyFlow is IPolicyStruct {
    /// @notice Function declarations

    /// @notice Apply for a new policy
    function newApplication(
        uint256 _productId,
        string memory _flightNumber,
        uint256 _premium,
        uint256 _departureTimestamp,
        uint256 _landingTimestamp,
        uint256 _deadline,
        bytes calldata signature
    ) external returns (uint256 policyId);

    /// @notice Start a new claim request
    function newClaimRequest(
        uint256 _policyId,
        string memory _flightNumber,
        string memory _timestamp,
        string memory _path,
        bool _forceUpdate
    ) external;

    /// @notice View a user's policy info
    function viewUserPolicy(address)
        external
        view
        returns (PolicyInfo[] memory);

    /// @notice Get the policy info by its policyId
    function getPolicyInfoById(uint256)
        external
        view
        returns (PolicyInfo memory);

    /// @notice Update when the policy token is transferred to another owner
    function policyOwnerTransfer(
        uint256,
        address,
        address
    ) external;

    /// @notice Do the final settlement when receiving the oracle result
    function finalSettlement(bytes32 _requestId, uint256 _result) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "./Context.sol";

/**
 * @dev The owner can be set during deployment, not default to be msg.sender
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _initialOwner) {
        _transferOwnership(_initialOwner);
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Leaves the contract without owner. It will not be possible to call
     *         `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * @dev    Renouncing ownership will leave the contract without an owner,
     *         thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Can only be called by the current owner.
     * @param  newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Internal function without access restriction.
     * @param  newOwner Address of the new owner
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IPolicyStruct {
    enum PolicyStatus {
        INI,
        SOLD,
        EXPIRED,
        CLAIMED
    }

    struct PolicyInfo {
        uint256 productId;
        address buyerAddress;
        uint256 policyId;
        string flightNumber;
        uint256 premium;
        uint256 payoff;
        uint256 purchaseTimestamp;
        uint256 departureTimestamp;
        uint256 landingTimestamp;
        PolicyStatus status;
        bool alreadySettled;
        uint256 delayResult;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.10;

import {Ownable} from "../utils/Ownable.sol";
import {IPool} from "./interfaces/IPool.sol";
import {BasePool, CoreStakingPool} from "./CoreStakingPool.sol";
import {IDegisToken} from "../tokens/interfaces/IDegisToken.sol";

contract StakingPoolFactory is Ownable {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Pool data info
    struct PoolData {
        address poolToken; // pool token address (Degis / Degis LP Token)
        address poolAddress; // pool address (deployed by factory)
        uint256 startTimestamp; // pool start timestamp
        uint256 degisPerSecond; // reward speed
    }

    address public degisToken;

    // Pool token address  => pool address
    mapping(address => address) public pools;

    // Pool address -> whether exists
    mapping(address => bool) public poolExists;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event PoolRegistered(
        address indexed by,
        address indexed poolToken,
        address indexed poolAddress,
        uint256 degisPerSecond
    );

    event DegisPerSecondChanged(address pool, uint256 degisPerSecond);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(address _degisToken) Ownable(msg.sender) {
        degisToken = _degisToken;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get the pool address from pool token address
     * @param _poolToken Pool token address
     */
    function getPoolAddress(address _poolToken)
        external
        view
        returns (address)
    {
        return pools[_poolToken];
    }

    /**
     * @notice Get pool data from pool token address
     * @param _poolToken Pool token address
     * @return poolData Pool data struct
     */
    function getPoolData(address _poolToken)
        public
        view
        returns (PoolData memory)
    {
        // get the pool address from the mapping
        address poolAddr = pools[_poolToken];

        // throw if there is no pool registered for the token specified
        require(poolAddr != address(0), "pool not found");

        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        uint256 startTimestamp = IPool(poolAddr).startTimestamp();
        uint256 degisPerSecond = IPool(poolAddr).degisPerSecond();

        // create the in-memory structure and return it
        return
            PoolData({
                poolToken: poolToken,
                poolAddress: poolAddr,
                startTimestamp: startTimestamp,
                degisPerSecond: degisPerSecond
            });
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set degis per second for a pool
     * @param _pool Address of the staking pool
     * @param _degisPerSecond Degis reward per second
     */
    function setDegisPerSecond(address _pool, uint256 _degisPerSecond)
        external
        onlyOwner
    {
        BasePool(_pool).setDegisPerSecond(_degisPerSecond);

        emit DegisPerSecondChanged(_pool, _degisPerSecond);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Creates a staking pool and registers it within the factory
     * @dev Only called by the owner
     * @param _poolToken Pool token address
     * @param _startTimestamp Start timestamp for reward
     * @param _degisPerSecond Reward speed
     */
    function createPool(
        address _poolToken,
        uint256 _startTimestamp,
        uint256 _degisPerSecond
    ) external onlyOwner {
        // create/deploy new core pool instance
        IPool pool = new CoreStakingPool(
            degisToken,
            _poolToken,
            address(this),
            _startTimestamp,
            _degisPerSecond
        );

        // register it within a factory
        _registerPool(address(pool));
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Register a deployed pool instance within the factory
     * @param _poolAddr Address of the already deployed pool instance
     */
    function _registerPool(address _poolAddr) internal {
        // Read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(_poolAddr).poolToken();
        uint256 degisPerSecond = IPool(_poolAddr).degisPerSecond();

        // Ensure that the pool is not already registered within the factory
        require(
            pools[poolToken] == address(0),
            "This pool is already registered"
        );

        // Record
        pools[poolToken] = _poolAddr;
        poolExists[_poolAddr] = true;

        emit PoolRegistered(
            msg.sender,
            poolToken,
            _poolAddr,
            degisPerSecond
        );
    }

    /**
     * @notice Mint degis tokens as reward
     * @dev With this function, we only need to add factory contract into minterList
     * @param _to The address to mint tokens to
     * @param _amount Amount of degis tokens to mint
     */
    function mintReward(address _to, uint256 _amount) external {
        // Verify that sender is a pool registered withing the factory
        require(poolExists[msg.sender], "Only called from pool");

        // Mint degis tokens as required
        IDegisToken(degisToken).mintDegis(_to, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

/**
 * @title Illuvium Pool
 *
 * @notice An abstraction representing a pool, see IlluviumPoolBase for details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
interface IPool {
    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of stake with its amount, weight and term (time interval)
     */
    struct Deposit {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev stake weight
        uint256 weight;
        // @dev locking period - from
        uint256 lockedFrom;
        // @dev locking period - until
        uint256 lockedUntil;
    }

    // for the rest of the functions see Soldoc in IlluviumPoolBase

    function degisToken() external view returns (address);

    function poolToken() external view returns (address);

    function startTimestamp() external view returns (uint256);

    function degisPerSecond() external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function accDegisPerWeight() external view returns (uint256);

    function pendingReward(address _user) external view returns (uint256);

    function setDegisPerSecond(uint256 _degisPerSecond) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.10;

import {Ownable} from "../utils/Ownable.sol";
import {BasePool} from "./abstracts/BasePool.sol";

contract CoreStakingPool is Ownable, BasePool {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(
        address _degisToken,
        address _poolToken,
        address _factory,
        uint256 _startTimestamp,
        uint256 _degisPerSecond
    )
        Ownable(msg.sender)
        BasePool(
            _degisToken,
            _poolToken,
            _factory,
            _startTimestamp,
            _degisPerSecond
        )
    {}

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Stake function, will call the stake in BasePool
     * @param _user User address
     * @param _amount Amount to stake
     * @param _lockUntil Lock until timestamp (0 means flexible staking)
     */
    function _stake(
        address _user,
        uint256 _amount,
        uint256 _lockUntil
    ) internal override {
        super._stake(_user, _amount, _lockUntil);
    }

    /**
     * @notice Unstake function, will check some conditions and call the unstake in BasePool
     * @param _user User address
     * @param _depositId Deposit id
     * @param _amount Amount to unstake
     */
    function _unstake(
        address _user,
        uint256 _depositId,
        uint256 _amount
    ) internal override {
        UserInfo storage user = users[_msgSender()];
        Deposit memory stakeDeposit = user.deposits[_depositId];
        require(
            stakeDeposit.lockedFrom == 0 ||
                block.timestamp >= stakeDeposit.lockedUntil,
            "Deposit not yet unlocked"
        );

        super._unstake(_user, _depositId, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDegisToken is IERC20, IERC20Permit {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Functions ************************************** //
    // ---------------------------------------------------------------------------------------- //
    function CAP() external view returns (uint256);

    /**
     * @notice Mint degis tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be minted
     */
    function mintDegis(address _account, uint256 _amount) external;

    /**
     * @notice Burn degis tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be burned
     */
    function burnDegis(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../interfaces/IPool.sol";
import "../interfaces/IStakingPoolFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract BasePool is IPool, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    struct UserInfo {
        uint256 tokenAmount;
        uint256 totalWeight;
        uint256 rewardDebt;
        // An array of holder's deposits
        Deposit[] deposits;
    }
    mapping(address => UserInfo) public users;

    // Token address staked in this pool
    address public poolToken;

    // Reward token: degis
    address public degisToken;

    // Reward start timestamp
    uint256 public startTimestamp;

    // Degis reward speed
    uint256 public degisPerSecond;

    // Last check point
    uint256 public lastRewardTimestamp;

    // Accumulated degis per weight till now
    uint256 public accDegisPerWeight;

    // Total weight in the pool
    uint256 public totalWeight;

    // Factory contract address
    address public factory;

    // Fees are paid to the previous stakers
    uint256 public constant fee = 2;

    // Weight multiplier constants
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

    uint256 internal constant YEAR_STAKE_WEIGHT_MULTIPLIER =
        2 * WEIGHT_MULTIPLIER;

    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event Stake(address user, uint256 amount, uint256 lockUntil);

    event Unstake(address user, uint256 amount);

    event Harvest(address user, uint256 amount);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Constructor
     */
    constructor(
        address _degisToken,
        address _poolToken,
        address _factory,
        uint256 _startTimestamp,
        uint256 _degisPerSecond
    ) {
        degisToken = _degisToken;
        poolToken = _poolToken;
        factory = _factory;

        degisPerSecond = _degisPerSecond;

        startTimestamp = _startTimestamp;

        lastRewardTimestamp = block.timestamp > _startTimestamp
            ? block.timestamp
            : _startTimestamp;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Only the factory can call some functions
     */
    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get a user's deposit info
     * @param _user User address
     * @return deposits[] User's deposit info
     */
    function getUserDeposits(address _user)
        external
        view
        returns (Deposit[] memory)
    {
        return users[_user].deposits;
    }

    /**
     * @notice Get pending rewards
     * @param _user User address
     * @return pendingReward User's pending rewards
     */
    function pendingReward(address _user) external view returns (uint256) {
        if (
            block.timestamp < lastRewardTimestamp ||
            block.timestamp < startTimestamp ||
            totalWeight == 0
        ) return 0;

        uint256 blocks = block.timestamp - lastRewardTimestamp;
        uint256 degisReward = blocks * degisPerSecond;

        // recalculated value for `yieldRewardsPerWeight`
        uint256 newDegisPerWeight = rewardToWeight(degisReward, totalWeight) +
            accDegisPerWeight;

        // based on the rewards per weight value, calculate pending rewards;
        UserInfo memory user = users[_user];

        uint256 pending = weightToReward(user.totalWeight, newDegisPerWeight) -
            user.rewardDebt;

        return pending;
    }

    function rewardToWeight(uint256 reward, uint256 rewardPerWeight)
        public
        pure
        returns (uint256)
    {
        return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
    }

    function weightToReward(uint256 weight, uint256 rewardPerWeight)
        public
        pure
        returns (uint256)
    {
        return (weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //
    function setDegisPerSecond(uint256 _degisPerSecond) external onlyFactory {
        degisPerSecond = _degisPerSecond;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Stake tokens
     * @param _amount Amount of tokens to stake
     * @param _lockUntil Lock until timestamp
     */
    function stake(uint256 _amount, uint256 _lockUntil) external {
        _stake(msg.sender, _amount, _lockUntil);
    }

    /**
     * @notice Unstake tokens
     * @param _depositId Deposit id to be unstaked
     * @param _amount Amount of tokens to unstake
     */
    function unstake(uint256 _depositId, uint256 _amount) external {
        _unstake(msg.sender, _depositId, _amount);
    }

    /**
     * @notice Harvest your staking rewards
     */
    function harvest() external {
        // First update the pool
        updatePool();

        UserInfo storage user = users[msg.sender];

        // calculate pending yield rewards, this value will be returned
        uint256 pending = _pendingReward(msg.sender);

        if (pending == 0) return;

        _safeDegisTransfer(msg.sender, pending);

        user.rewardDebt = weightToReward(user.totalWeight, accDegisPerWeight);

        emit Harvest(msg.sender, pending);
    }

    /**
     * @notice Update the pool without fee
     */
    function updatePool() public {
        _updatePoolWithFee(0);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Update pool status with fee (if any)
     * @param _fee Fee to be distributed
     */
    function _updatePoolWithFee(uint256 _fee) internal {
        if (block.timestamp <= lastRewardTimestamp) return;

        uint256 balance = IERC20(poolToken).balanceOf(address(this));

        if (balance == 0) {
            lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 timePassed = block.timestamp - lastRewardTimestamp;

        // There is _fee when staking
        uint256 degisReward = timePassed * degisPerSecond + _fee;

        // Mint reward to this staking pool
        IStakingPoolFactory(factory).mintReward(address(this), degisReward);

        accDegisPerWeight += rewardToWeight(degisReward, totalWeight);

        lastRewardTimestamp = block.timestamp;
    }

    /**
     * @notice Finish stake process
     * @param _user User address
     * @param _amount Amount of tokens to stake
     * @param _lockUntil Lock until timestamp
     */
    function _stake(
        address _user,
        uint256 _amount,
        uint256 _lockUntil
    ) internal virtual nonReentrant {
        require(block.timestamp > startTimestamp, "Pool not started yet");
        require(_amount > 0, "Zero amount");
        require(
            _lockUntil == 0 || (_lockUntil > block.timestamp),
            "Invalid lock interval"
        );
        if (_lockUntil >= block.timestamp + 365 days)
            _lockUntil = block.timestamp + 365 days;

        uint256 depositFee;
        if (IERC20(poolToken).balanceOf(address(this)) > 0) {
            // Charge deposit fee and distribute to previous stakers
            depositFee = (_amount * fee) / 100;
            _updatePoolWithFee(depositFee);
        } else updatePool();

        UserInfo storage user = users[_user];

        if (user.tokenAmount > 0) {
            _distributeReward(_user);
        }

        uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
        transferPoolTokenFrom(msg.sender, address(this), _amount);
        uint256 newBalance = IERC20(poolToken).balanceOf(address(this));

        // Actual amount is without the fee
        uint256 addedAmount = newBalance - previousBalance - depositFee;

        uint256 lockFrom = _lockUntil > 0 ? block.timestamp : 0;
        uint256 lockUntil = _lockUntil;

        uint256 stakeWeight = timeToWeight(lockUntil - lockFrom) * addedAmount;

        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);

        // create and save the deposit (append it to deposits array)
        Deposit memory deposit = Deposit({
            tokenAmount: addedAmount,
            weight: stakeWeight,
            lockedFrom: lockFrom,
            lockedUntil: lockUntil
        });
        // deposit ID is an index of the deposit in `deposits` array
        user.deposits.push(deposit);

        // update user record
        user.tokenAmount += addedAmount;
        user.totalWeight += stakeWeight;
        user.rewardDebt = weightToReward(user.totalWeight, accDegisPerWeight);

        // update global variable
        totalWeight += stakeWeight;

        // emit an event
        emit Stake(msg.sender, _amount, _lockUntil);
    }

    /**
     * @notice Finish unstake process
     * @param _user User address
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function _unstake(
        address _user,
        uint256 _depositId,
        uint256 _amount
    ) internal virtual nonReentrant {
        // verify an amount is set
        require(_amount > 0, "zero amount");

        UserInfo storage user = users[_user];

        Deposit storage stakeDeposit = user.deposits[_depositId];

        // verify available balance
        // if staker address ot deposit doesn't exist this check will fail as well
        require(stakeDeposit.tokenAmount >= _amount, "amount exceeds stake");

        // update smart contract state
        updatePool();
        // and process current pending rewards if any
        _distributeReward(_user);

        // recalculate deposit weight
        uint256 previousWeight = stakeDeposit.weight;

        uint256 newWeight = timeToWeight(
            stakeDeposit.lockedUntil - stakeDeposit.lockedFrom
        ) * (stakeDeposit.tokenAmount - _amount);

        // update the deposit, or delete it if its depleted
        if (stakeDeposit.tokenAmount - _amount == 0) {
            delete user.deposits[_depositId];
        } else {
            stakeDeposit.tokenAmount -= _amount;
            stakeDeposit.weight = newWeight;
        }

        // update user record
        user.tokenAmount -= _amount;
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        user.rewardDebt = weightToReward(user.totalWeight, accDegisPerWeight);

        // update global variable
        totalWeight -= (previousWeight - newWeight);

        // otherwise just return tokens back to holder
        transferPoolToken(msg.sender, _amount);

        // emit an event
        emit Unstake(msg.sender, _amount);
    }

    /**
     * @notice Lock time => Lock weight
     * @dev 1 year = 2e6
     *      1 week = 1e6
     *      2 weeks = 1e6 * ( 1 + 1 / 365)
     */
    function timeToWeight(uint256 _length)
        public
        pure
        returns (uint256 _weight)
    {
        _weight =
            ((_length * WEIGHT_MULTIPLIER) / 365 days) +
            WEIGHT_MULTIPLIER;
    }

    /**
     * @notice Check pending reward after update
     * @param _user User address
     */
    function _pendingReward(address _user)
        internal
        view
        returns (uint256 pending)
    {
        // read user data structure into memory
        UserInfo memory user = users[_user];

        // and perform the calculation using the values read
        return
            weightToReward(user.totalWeight, accDegisPerWeight) -
            user.rewardDebt;
    }

    /**
     * @notice Distribute reward to staker
     * @param _user User address
     */
    function _distributeReward(address _user) internal {
        uint256 pending = _pendingReward(_user);

        if (pending == 0) return;
        else {
            _safeDegisTransfer(_user, pending);
        }
    }

    /**
     * @notice Transfer pool token from pool to user
     */
    function transferPoolToken(address _to, uint256 _value) internal {
        // just delegate call to the target
        IERC20(poolToken).safeTransfer(_to, _value);
    }

    /**
     * @notice Transfer pool token from user to pool
     * @param _from User address
     * @param _to Pool address
     * @param _value Amount of tokens to transfer
     */
    function transferPoolTokenFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        IERC20(poolToken).safeTransferFrom(_from, _to, _value);
    }

    /**
     * @notice Safe degis transfer (check if the pool has enough DEGIS token)
     * @param _to User's address
     * @param _amount Amount to transfer
     */
    function _safeDegisTransfer(address _to, uint256 _amount) internal {
        uint256 totalDegis = IERC20(degisToken).balanceOf(address(this));
        if (_amount > totalDegis) {
            IERC20(degisToken).safeTransfer(_to, totalDegis);
        } else {
            IERC20(degisToken).safeTransfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IStakingPoolFactory {
    function createPool(
        address _poolToken,
        uint256 _startBlock,
        uint256 _degisPerBlock
    ) external;

    function mintReward(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "./interfaces/IDegisToken.sol";
import "../utils/ERC20PermitWithMultipleMinters.sol";

/**@title  Degis Token
 * @notice DegisToken inherits from ERC20 Permit which contains the basic ERC20 implementation.
 *         DegisToken can use the permit function rather than approve + transferFrom.
 *
 *         DegisToken has an owner, a minterList and a burnerList.
 *         When lauched on mainnet, the owner may be removed or tranferred to a multisig.
 *         By default, the owner & the first minter will be the one that deploys the contract.
 *         The minterList should contain FarmingPool and PurchaseIncentiveVault.
 *         The burnerList should contain EmergencyPool.
 */
contract DegisToken is ERC20PermitWithMultipleMinters {
    // Degis has a total supply of 100 million
    uint256 public constant CAP = 1e8 ether;

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Constructor *************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor() ERC20PermitWithMultipleMinters("DegisToken", "DEG") {}

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Modifiers **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Degis token has a hard cap of 100 million
    modifier notExceedCap(uint256 _amount) {
        require(
            totalSupply() + _amount <= CAP,
            "Exceeds the DEG cap (100 million)"
        );
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Main Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Mint degis tokens
     * @param  _account Receiver's address
     * @param  _amount  Amount to be minted
     */
    function mintDegis(address _account, uint256 _amount)
        external
        notExceedCap(_amount)
    {
        mint(_account, _amount);
    }

    /**
     * @notice Burn degis tokens
     * @param  _account Receiver's address
     * @param  _amount  Amount to be burned
     */
    function burnDegis(address _account, uint256 _amount) external {
        burn(_account, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./OwnableWithoutContext.sol";

/**
 * @title  ERC20 with Multiple Minters and Burners
 * @notice This is contract used for ERC20 tokens that has multiple minters and burners.
 * @dev    The minters and burners are some contracts in Degis that need to issue DEG.
 *         It has basic implementations for ERC20 and also the owner control.
 *         Even if the owner is renounced to zero address, the token can still be minted/burned.
 *         DegisToken and BuyerToken are both this kind ERC20 token.
 */
contract ERC20PermitWithMultipleMinters is ERC20Permit, OwnableWithoutContext {
    // List of all minters
    mapping(address => bool) public isMinter;

    // List of all burners
    mapping(address => bool) public isBurner;

    event MinterAdded(address newMinter);
    event MinterRemoved(address oldMinter);

    event BurnerAdded(address newBurner);
    event BurnerRemoved(address oldBurner);

    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        ERC20Permit(name)
        OwnableWithoutContext(msg.sender)
    {
        // After the owner is transferred to multisig governance
        // This initial minter should be removed
        isMinter[_msgSender()] = true;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Modifiers ****************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     *@notice Check if the msg.sender is in the minter list
     */
    modifier validMinter(address _sender) {
        require(isMinter[_sender], "Invalid minter");
        _;
    }

    /**
     * @notice Check if the msg.sender is in the burner list
     */
    modifier validBurner(address _sender) {
        require(isBurner[_sender], "Invalid burner");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Admin Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Add a new minter into the minterList
     * @param _newMinter Address of the new minter
     */
    function addMinter(address _newMinter) external onlyOwner {
        require(!isMinter[_newMinter], "Already a minter");

        isMinter[_newMinter] = true;

        emit MinterAdded(_newMinter);
    }

    /**
     * @notice Remove a minter from the minterList
     * @param _oldMinter Address of the minter to be removed
     */
    function removeMinter(address _oldMinter) external onlyOwner {
        require(isMinter[_oldMinter], "Not a minter");

        isMinter[_oldMinter] = false;

        emit MinterRemoved(_oldMinter);
    }

    /**
     * @notice Add a new burner into the burnerList
     * @param _newBurner Address of the new burner
     */
    function addBurner(address _newBurner) external onlyOwner {
        require(!isBurner[_newBurner], "Already a burner");

        isBurner[_newBurner] = true;

        emit BurnerAdded(_newBurner);
    }

    /**
     * @notice Remove a minter from the minterList
     * @param _oldBurner Address of the minter to be removed
     */
    function removeBurner(address _oldBurner) external onlyOwner {
        require(isMinter[_oldBurner], "Not a burner");

        isBurner[_oldBurner] = false;

        emit BurnerRemoved(_oldBurner);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Mint tokens
     * @param _account Receiver's address
     * @param _amount Amount to be minted
     */
    function mint(address _account, uint256 _amount)
        internal
        validMinter(_msgSender())
    {
        _mint(_account, _amount); // ERC20 method with an event
        emit Mint(_account, _amount);
    }

    /**
     * @notice Burn tokens
     * @param _account address
     * @param _amount amount to be burned
     */
    function burn(address _account, uint256 _amount)
        internal
        validBurner(_msgSender())
    {
        _burn(_account, _amount);
        emit Burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

/**
 * @dev The owner can be set during deployment, not default to be msg.sender
 */
abstract contract OwnableWithoutContext {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _initialOwner) {
        _transferOwnership(_initialOwner);
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Leaves the contract without owner. It will not be possible to call
     *         `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * @dev    Renouncing ownership will leave the contract without an owner,
     *         thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Can only be called by the current owner.
     * @param  newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Internal function without access restriction.
     * @param  newOwner Address of the new owner
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/SafePRBMath.sol";
import "../lucky-box/interfaces/IDegisLottery.sol";
import "../utils/OwnableWithoutContext.sol";
import "./abstracts/InsurancePoolStore.sol";

/**
 * @title  Insurance Pool
 * @notice Insurance pool is the reserved risk pool for flight delay product.
 *         For simplicity, some state variables are in the InsurancePoolStore contract.
 */
contract InsurancePool is
    ERC20("Degis FlightDelay LPToken", "DLP"),
    InsurancePoolStore,
    OwnableWithoutContext,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using SafePRBMath for uint256;

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Other Contracts ************************************ //
    // ---------------------------------------------------------------------------------------- //

    IERC20 public USDToken;
    IDegisLottery public degisLottery;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Constructor function
     * @param _emergencyPool Emergency pool address
     * @param _degisLottery Lottery address
     * @param _usdAddress USDToken address
     */
    constructor(
        address _emergencyPool,
        address _degisLottery,
        address _usdAddress
    ) OwnableWithoutContext(msg.sender) {
        // Initialize some factors
        collateralFactor = 1e18;
        lockedRatio = 1e18;
        LPValue = 1e18;

        emergencyPool = _emergencyPool;

        USDToken = IERC20(_usdAddress);

        degisLottery = IDegisLottery(_degisLottery);

        // Initial distribution, 0: LP 1: Lottery 2: Emergency
        rewardDistribution[0] = 50;
        rewardDistribution[1] = 40;
        rewardDistribution[2] = 10;

        frozenTime = 7 days;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Only the policyFlow contract can call some functions
     */
    modifier onlyPolicyFlow() {
        require(
            _msgSender() == policyFlow,
            "Only the policyFlow contract can call this function"
        );
        _;
    }

    /**
     * @notice The address can not be zero
     */
    modifier notZeroAddress(address _address) {
        assert(_address != address(0));
        _;
    }

    /**
     * @notice There is a frozen time for unstaking
     */
    modifier afterFrozenTime(address _user) {
        require(
            block.timestamp >= userInfo[_user].depositTime + frozenTime,
            "Can not withdraw until the fronzen time"
        );
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get the real balance: LPValue * LP_Num
     * @dev Used in many places so give it a seperate function
     * @param _user User's address
     * @return _userBalance Real balance of this user
     */
    function getUserBalance(address _user)
        public
        view
        returns (uint256 _userBalance)
    {
        uint256 lp_num = balanceOf(_user);
        _userBalance = lp_num.mul(LPValue);
    }

    /**
     * @notice Get the balance that one user(LP) can unlock
     * @param _user User's address
     * @return _unlockedAmount Unlocked amount of the user
     */
    function getUnlockedFor(address _user)
        public
        view
        returns (uint256 _unlockedAmount)
    {
        uint256 userBalance = getUserBalance(_user);
        _unlockedAmount = availableCapacity >= userBalance
            ? userBalance
            : availableCapacity;
    }

    /**
     * @notice Check the conditions when receive new buying request
     * @param _payoff Payoff of the policy to be bought
     * @return Whether there is enough capacity in the pool for this payoff
     */
    function checkCapacity(uint256 _payoff) external view returns (bool) {
        return availableCapacity >= _payoff;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Owner Functions *********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set a new frozen time
     * @param _newFrozenTime New frozen time, in timestamp(s)
     */
    function setFrozenTime(uint256 _newFrozenTime) external onlyOwner {
        frozenTime = _newFrozenTime;
        emit FrozenTimeChanged(_newFrozenTime);
    }

    /**
     * @notice Set the address of policyFlow
     */
    function setPolicyFlow(address _policyFlowAddress)
        public
        onlyOwner
        notZeroAddress(_policyFlowAddress)
    {
        policyFlow = _policyFlowAddress;
        emit PolicyFlowChanged(_policyFlowAddress);
    }

    /**
     * @notice Set the premium reward distribution
     * @param _newDistribution New distribution [LP, Lottery, Emergency]
     */
    function setRewardDistribution(uint256[3] memory _newDistribution)
        public
        onlyOwner
    {
        uint256 sum = _newDistribution[0] +
            _newDistribution[1] +
            _newDistribution[2];
        require(sum == 100, "Reward distribution must sum to 100");

        for (uint256 i = 0; i < 3; i++) {
            rewardDistribution[i] = _newDistribution[i];
        }
        emit RewardDistributionChanged(
            _newDistribution[0],
            _newDistribution[1],
            _newDistribution[2]
        );
    }

    /**
     * @notice Change the collateral factor
     * @param _factor The new collateral factor
     */
    function setCollateralFactor(uint256 _factor) public onlyOwner {
        require(_factor > 0, "Collateral Factor should be larger than 0");
        uint256 oldFactor = collateralFactor;
        collateralFactor = _factor.div(100);
        emit CollateralFactorChanged(oldFactor, _factor);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice LPs stake assets into the pool
     * @param _amount The amount that the user want to stake
     */
    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Zero Amount");
        require(
            IERC20(USDToken).balanceOf(_msgSender()) >= _amount,
            "Not enough USD"
        );

        _updateLPValue();

        _deposit(_msgSender(), _amount);
    }

    /**
     * @notice Unstake from the pool (May fail if a claim happens before this operation)
     * @dev Only unstake by yourself
     * @param _amount The amount that the user want to unstake
     */
    function unstake(uint256 _amount)
        external
        afterFrozenTime(_msgSender())
        nonReentrant
    {
        require(totalStakingBalance - lockedBalance > 0, "All locked");

        address _user = _msgSender();

        _updateLPValue();

        uint256 userBalance = getUserBalance(_user);
        require(
            _amount <= userBalance && _amount > 0,
            "Not enough balance to be unlocked or your withdraw amount is 0"
        );

        uint256 unlocked = totalStakingBalance - lockedBalance;
        uint256 unstakeAmount = _amount;

        // Will jump this part when the pool has enough liquidity
        if (_amount > unlocked) unstakeAmount = unlocked; // only withdraw the unlocked value

        if (unstakeAmount > 0) _withdraw(_user, unstakeAmount);
    }

    /**
     * @notice Unstake the max amount of a user
     */
    function unstakeMax() external afterFrozenTime(_msgSender()) nonReentrant {
        require(totalStakingBalance - lockedBalance > 0, "All locked");

        address _user = _msgSender();

        _updateLPValue();

        uint256 userBalance = getUserBalance(_user);

        uint256 unlocked = totalStakingBalance - lockedBalance;
        uint256 unstakeAmount = userBalance;

        // Will jump this part when the pool has enough liquidity
        if (userBalance > unlocked) unstakeAmount = unlocked; // only withdraw the unlocked value

        _withdraw(_user, unstakeAmount);
    }

    /**
     * @notice Update the pool variables when buying policies
     * @dev Capacity check is done before calling this function
     * @param _premium Policy's premium
     * @param _payoff Policy's payoff (max payoff)
     * @param _user Address of the buyer
     */
    function updateWhenBuy(
        uint256 _premium,
        uint256 _payoff,
        address _user
    ) external onlyPolicyFlow {
        // Update pool status
        lockedBalance += _payoff;
        activePremiums += _premium;
        availableCapacity -= _payoff;

        // Update lockedRatio
        _updateLockedRatio();

        // Remember approval
        USDToken.safeTransferFrom(_user, address(this), _premium);

        emit NewPolicyBought(_user, _premium, _payoff);
    }

    /**
     * @notice Update the status when a policy expires
     * @param _premium Policy's premium
     * @param _payoff Policy's payoff (max payoff)
     */
    function updateWhenExpire(uint256 _premium, uint256 _payoff)
        external
        onlyPolicyFlow
    {
        // Distribute the premium
        uint256 remainingPremium = _distributePremium(_premium);

        // Update pool status
        activePremiums -= _premium;
        lockedBalance -= _payoff;

        availableCapacity += _payoff + remainingPremium;
        totalStakingBalance += remainingPremium;

        _updateLPValue();
    }

    /**
     * @notice Pay a claim
     * @param _premium Premium of the policy
     * @param _payoff Max payoff of the policy
     * @param _realPayoff Real payoff of the policy
     * @param _user Address of the policy claimer
     */
    function payClaim(
        uint256 _premium,
        uint256 _payoff,
        uint256 _realPayoff,
        address _user
    ) external onlyPolicyFlow notZeroAddress(_user) {
        // Distribute the premium
        uint256 remainingPremium = _distributePremium(_premium);

        // Update the pool status
        lockedBalance -= _payoff;

        totalStakingBalance =
            totalStakingBalance -
            _realPayoff +
            remainingPremium;

        availableCapacity += (_payoff - _realPayoff + remainingPremium);

        activePremiums -= _premium;

        // Pay the claim
        USDToken.safeTransfer(_user, _realPayoff);

        _updateLPValue();
    }

    // ---------------------------------------------------------------------------------------- //
    // ********************************** Internal Functions ********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Finish the deposit process
     * @dev LPValue will not change during deposit
     * @param _user Address of the user who deposits
     * @param _amount Amount he deposits
     */
    function _deposit(address _user, uint256 _amount) internal {
        uint256 amountWithFactor = _amount.mul(collateralFactor);

        // Update the pool's status
        totalStakingBalance += _amount;
        availableCapacity += amountWithFactor;

        _updateLockedRatio();

        // msg.sender always pays
        USDToken.safeTransferFrom(_user, address(this), _amount);

        // LP Token number need to be newly minted
        uint256 lp_num = _amount.div(LPValue);
        _mint(_user, lp_num);

        userInfo[_user].depositTime = block.timestamp;

        emit Stake(_user, _amount);
    }

    /**
     * @notice _withdraw: finish the withdraw action, only when meeting the conditions
     * @dev LPValue will not change during withdraw
     * @param _user address of the user who withdraws
     * @param _amount the amount he withdraws
     */
    function _withdraw(address _user, uint256 _amount) internal {
        uint256 amountWithFactor = _amount.mul(collateralFactor);
        // Update the pool's status
        totalStakingBalance -= _amount;
        availableCapacity -= amountWithFactor;

        _updateLockedRatio();

        USDToken.safeTransfer(_user, _amount);

        uint256 lp_num = _amount.div(LPValue);
        _burn(_user, lp_num);

        emit Unstake(_user, _amount);
    }

    /**
     * @notice Distribute the premium to lottery and emergency pool
     * @param _premium Premium amount to be distributed
     */
    function _distributePremium(uint256 _premium) internal returns (uint256) {
        uint256 premiumToLottery = _premium.mul(rewardDistribution[1].div(100));

        uint256 premiumToEmergency = _premium.mul(
            rewardDistribution[2].div(100)
        );

        // Transfer some reward to emergency pool
        USDToken.safeTransfer(emergencyPool, premiumToEmergency);

        // Transfer some reward to lottery
        USDToken.safeTransfer(address(degisLottery), premiumToLottery);

        emit PremiumDistributed(premiumToEmergency, premiumToLottery);

        return _premium - premiumToEmergency - premiumToLottery;
    }

    /**
     * @notice Update the value of each lp token
     * @dev Normally it will update when claim or expire
     */
    function _updateLPValue() internal {
        uint256 totalLP = totalSupply();

        if (totalLP == 0) return;
        else {
            uint256 totalBalance = IERC20(USDToken).balanceOf(address(this));

            LPValue = (totalBalance - activePremiums).div(totalLP);
        }
    }

    /**
     * @notice Update the pool's locked ratio
     */
    function _updateLockedRatio() internal {
        if (lockedBalance == 0) lockedRatio = 0;
        else lockedRatio = lockedBalance.div(totalStakingBalance);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "prb-math/contracts/PRBMath.sol";

/**
 * @notice This prb-math version is 2.4.1
 *         https://github.com/hifi-finance/prb-math
 */

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library SafePRBMath {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IDegisLottery {
    /**
     * @notice Inject funds
     * @param _amount amount to inject in USD
     * @dev Callable by operator
     */
    function injectFunds(uint256 _amount) external;

    /**
     * @notice View current lottery id
     */
    function currentLotteryId() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

abstract contract InsurancePoolStore {
    address public policyFlow;
    address public emergencyPool;

    uint256 public frozenTime; // default as 7 days

    struct UserInfo {
        uint256 depositTime;
        uint256 pendingBalance; // the amount in the unstake queue
    }
    mapping(address => UserInfo) public userInfo;

    // 1 LP = LPValue(USD)
    uint256 public LPValue;

    // Total staking balance of the pool
    uint256 public totalStakingBalance;

    // Locked balance is for potiential payoff
    uint256 public lockedBalance;

    // locked relation = locked balance / totalStakingBalance
    uint256 public lockedRatio; //  1e18 = 1  1e17 = 0.1  1e19 = 10
    uint256 public collateralFactor; //  1e18 = 1  1e17 = 0.1  1e19 = 10

    // Available capacity for taking new
    uint256 public availableCapacity;

    // Premiums have been paid but the policies haven't expired
    uint256 public activePremiums;

    // [0]: LP, [1]: Lottery, [2]: Emergency
    uint256[3] public rewardDistribution;

    // events
    event Stake(address indexed userAddress, uint256 amount);
    event Unstake(address indexed userAddress, uint256 amount);

    event CollateralFactorChanged(uint256 oldFactor, uint256 newFactor);

    event PolicyFlowChanged(address policyFlowAddress);

    event NewPolicyBought(
        address indexed userAddress,
        uint256 premium,
        uint256 payout
    );
    event RewardDistributionChanged(
        uint256 toLP,
        uint256 toLottery,
        uint256 toEmergency
    );

    event FrozenTimeChanged(uint256 _newFrozenTime);

    event PremiumDistributed(
        uint256 _premiumToEmergency,
        uint256 _premiumToLottery
    );
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./interfaces/IDegisLottery.sol";

contract RandomNumberGeneratorV2 is VRFConsumerBaseV2 {
    // Coordinator address based on networks
    // Fuji: 0x2eD832Ba664535e5886b75D64C46EB9a228C2610
    // Mainnet: 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634
    VRFCoordinatorV2Interface coordinator;

    // Subscription id, created on chainlink website
    // Fuji: 130
    // Mainnet:
    uint64 subscriptionId;

    // Different networks and gas prices have different keyHash
    // Fuji: 300gwei 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61
    // Mainnet: 500gwei 0x89630569c9567e43c4fe7b1633258df9f2531b62f2352fa721cf3162ee4ecb46
    bytes32 public keyHash;

    // Gas limit for callback
    uint32 callbackGasLimit = 100000;

    // Confirmations for each request
    uint16 requestConfirmations = 3;

    // Request 1 random number each time
    uint32 public wordsPerTime = 1;

    // Store the latest result
    uint256[] public s_randomWords;

    // Store the latest request id
    uint256 public s_requestId;

    // Owner address
    address public owner;

    // Latest lottery id
    uint256 public latestLotteryId;

    address public degisLottery;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event RequestRandomWords(uint256 requestId);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        // Set coordinator address depends on networks
        coordinator = VRFCoordinatorV2Interface(_vrfCoordinator);

        // Set keyhash depends on networks and gas price
        keyHash = _keyHash;

        // Subscription id depends on networks
        subscriptionId = _subscriptionId;

        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    function setCoordinator(address _coordinator) external onlyOwner {
        coordinator = VRFCoordinatorV2Interface(_coordinator);
    }

    function setWordsPerTime(uint32 _wordsPerTime) external onlyOwner {
        wordsPerTime = _wordsPerTime;
    }

    function setRequestConfirmations(uint16 _requestConfirmations)
        external
        onlyOwner
    {
        requestConfirmations = _requestConfirmations;
    }

    function setDegisLottery(address _lottery) external onlyOwner {
        degisLottery = _lottery;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function requestRandomWords() external onlyOwner {
        s_requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            wordsPerTime
        );

        emit RequestRandomWords(s_requestId);
    }

    function fulfillRandomWords(uint256, uint256[] memory _randomWords)
        internal
        override
    {
        s_randomWords = _randomWords;

        // Update latest lottery id
        // Before this update, lottery can not make that round claimable
        latestLotteryId = IDegisLottery(degisLottery).currentLotteryId();
    }

    /**
     * @notice Random result function for lottery
     */
    function randomResult() external view returns (uint256) {
        return s_randomWords[0];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../utils/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../libraries/StringsUtils.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "./interfaces/IDegisLottery.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RandomNumberGenerator is VRFConsumerBase, Ownable {
    using StringsUtils for uint256;
    using SafeERC20 for IERC20;

    IDegisLottery public DegisLottery;

    bytes32 public keyHash;
    bytes32 public latestRequestId;
    uint256 public randomResult;
    uint256 public fee;

    uint256 public latestLotteryId;

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed before the lottery.
     * Once the lottery contract is deployed, setLotteryAddress must be called.
     * https://docs.chain.link/docs/vrf-contracts/
     * @param _vrfCoordinator address of the VRF coordinator
     * @param _linkToken address of the LINK token
     */
    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash
    ) Ownable(msg.sender) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        fee = 0.1 * 10e18;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Change the fee
     * @param _fee new fee (in LINK)
     */
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     * @notice Change the keyHash
     * @param _keyHash new keyHash
     */
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    /**
     * @notice Set the address for the DegisLottery
     * @param _degisLottery address of the PancakeSwap lottery
     */
    function setLotteryAddress(address _degisLottery) external onlyOwner {
        DegisLottery = IDegisLottery(_degisLottery);
    }

    /**
     * @notice It allows the admin to withdraw tokens sent to the contract
     * @param _tokenAddress the address of the token to withdraw
     * @param _tokenAmount the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function withdrawTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).safeTransfer(_msgSender(), _tokenAmount);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Request randomness from Chainlink VRF
     */
    function getRandomNumber() external {
        require(_msgSender() == address(DegisLottery), "Only DegisLottery");

        require(keyHash != bytes32(0), "Must have valid key hash");
        // require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens");

        //*********************************//
        // TODO: This part is only for test on Fuji Testnet because there is no VRF currently
        string memory randInput = string(
            abi.encodePacked(
                block.timestamp.uintToString(),
                blockhash(block.number - (block.timestamp % 64)),
                address(this)
            )
        );
        randomResult = _rand(randInput) % 10000;

        latestLotteryId = IDegisLottery(DegisLottery).currentLotteryId();
        //*********************************//

        // latestRequestId = requestRandomness(keyHash, fee);
    }

    /**
     * @notice Get the random number
     * @return randomNumber the random result
     */
    function _rand(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Callback function used by ChainLink's VRF Coordinator
     */
    // TODO: On Fuji testnet, we use fake random numbers
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        require(latestRequestId == requestId, "Wrong requestId");
        randomResult = randomness % 10000;

        latestLotteryId = IDegisLottery(DegisLottery).currentLotteryId();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

/**
 * @dev String operations.
 */
library StringsUtils {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @notice Bytes to string (not human-readable form)
     * @param _bytes Input bytes
     * @return stringBytes String form of the bytes
     */
    function byToString(bytes32 _bytes) internal pure returns (string memory) {
        return uintToHexString(uint256(_bytes), 32);
    }

    /**
     * @notice Transfer address to string (not change the content)
     * @param _addr Input address
     * @return stringAddress String form of the address
     */
    function addressToString(address _addr)
        internal
        pure
        returns (string memory)
    {
        return uintToHexString(uint256(uint160(_addr)), 20);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function uintToString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function uintToHexString(uint256 value)
        internal
        pure
        returns (string memory)
    {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return uintToHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function uintToHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IVeDEG } from "../governance/interfaces/IVeDEG.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title  Shield Token (Derived Stablecoin on Degis)
 * @author Eric Lee ([email protected])
 * @dev    Users can swap other stablecoins to Shield
 *         Shield can be used in NaughtyPrice and future products
 *
 *         When users want to withdraw, their shield tokens will be burned
 *         and USDC will be sent back to them
 *
 *         Currently, the swap is done inside Platypus
 */
contract Shield is ERC20Upgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // PTP USD Pool to be used for swapping stablecoins
    address public PTPPOOL = 0x66357dCaCe80431aee0A7507e2E361B7e2402370;
    address public YUSDCTPOOL = 0x1da20Ac34187b2d9c74F729B85acB225D3341b25;
    address public USDCeUSDCPOOL = 0x3a43A5851A3e3E0e25A3c1089670269786be1577;
    address public aTRICURVEPOOL = 0xB755B949C126C04e0348DD881a5cF55d424742B2;
    // Constant stablecoin addresses
    address public constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address public constant USDCe = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address public constant USDTe = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public constant DAIe = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address public constant YUSD = 0x111111111111ed1D73f860F57b2798b683f2d325;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    IVeDEG public veDEG;

    struct Stablecoin {
        bool isSupported;
        uint256 collateralRatio;
    }

    // stablecoin => whether supported
    mapping(address => bool) public supportedStablecoin;

    mapping(address => uint256) public users;

    // ------------------------------------------------------------------------- --------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event AddStablecoin(address stablecoin);
    event SetPTPPool(address oldPool, address newPool);
    event Deposit(
        address indexed user,
        address indexed stablecoin,
        uint256 inAmount,
        uint256 outAmount
    );
    event Withdraw(address indexed user, uint256 amount);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(address _veDEG) public initializer {
        __ERC20_init("Shield Token", "SHD");
        __Ownable_init();

        veDEG = IVeDEG(_veDEG);

        // USDT.e
        supportedStablecoin[USDTe] = true;
        // USDT
        supportedStablecoin[USDT] = true;
        // USDC.e
        supportedStablecoin[USDCe] = true;
        // USDC
        supportedStablecoin[USDC] = true;
        // DAI.e
        supportedStablecoin[DAIe] = true;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Add new supported stablecoin
     *
     * @dev Set the token address and collateral ratio at the same time
     *      The collateral ratio need to be less than 100
     *      Only callable by the owner
     *
     * @param _stablecoin Stablecoin address
     */
    function addSupportedStablecoin(address _stablecoin)
        external
        onlyOwner
    {
        supportedStablecoin[_stablecoin] = true;
     
        emit AddStablecoin(_stablecoin);
    }

    function setPTPPool(address _ptpPool) external onlyOwner {
        emit SetPTPPool(PTPPOOL, _ptpPool);
        PTPPOOL = _ptpPool;
    }

    /**
     * @notice Get discount by veDEG
     * @dev The discount depends on veDEG
     * @return discount The discount for the user
     */
    function _getDiscount() internal view returns (uint256) {
        uint256 balance = veDEG.balanceOf(msg.sender);
        return balance;
    }

    function approveStablecoin(address _token) external {
        IERC20(_token).approve(PTPPOOL, type(uint256).max);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Deposit tokens and mint Shield
     * @param _stablecoin Stablecoin address
     * @param _amount     Input stablecoin amount
     * @param _minAmount  Minimum amount output (if need swap)
     */
    function deposit(
        address _stablecoin,
        uint256 _amount,
        uint256 _minAmount
    ) external {
        require(supportedStablecoin[_stablecoin], "Stablecoin not supported");

        // Actual shield amount
        uint256 outAmount;

        // Collateral ratio
        uint256 inAmount = _amount;

        // Transfer stablecoin to this contract
        // Transfer to this, no need for safeTransferFrom
        IERC20(_stablecoin).safeTransferFrom(msg.sender, address(this), _amount);

        if (_stablecoin != USDC) {
            // Swap stablecoin to USDC and directly goes to this contract
            outAmount = _swap(
                _stablecoin,
                USDC,
                inAmount,
                _minAmount,
                address(this),
                block.timestamp + 60
            );
        } else {
            outAmount = inAmount;
        }

        // Record user balance
        users[msg.sender] += outAmount;

        // Mint shield
        _mint(msg.sender, outAmount);

        emit Deposit(msg.sender, _stablecoin, _amount, outAmount);
    }

    /**
     * @notice Withdraw stablecoins
     * @param _amount Amount of Shield to be burned
     */
    function withdraw(uint256 _amount) public {
        require(users[msg.sender] >= _amount, "Insufficient balance");
        users[msg.sender] -= _amount;

        // Transfer USDC back
        uint256 realAmount = _safeTokenTransfer(USDC, _amount);

        // Burn shield token
        _burn(msg.sender, realAmount);

        // Transfer USDC back
        IERC20(USDC).safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, realAmount);
    }

    /**
     * @notice Withdraw all stablecoins
     */
    function withdrawAll() external {
        require(users[msg.sender] > 0, "Insufficient balance");
        withdraw(users[msg.sender]);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Swap stablecoin to USDC in PTP
     * @param _fromToken   From token address
     * @param _toToken     To token address
     * @param _fromAmount  Amount of from token
     * @param _minToAmount Minimun output amount
     * @param _to          Address that will receive the output token
     * @param _deadline    Deadline for this transaction
     */
    function _swap(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        uint256 _minToAmount,
        address _to,
        uint256 _deadline
    ) internal returns (uint256) {
        bytes memory data = abi.encodeWithSignature(
            "swap(address,address,uint256,uint256,address,uint256)",
            _fromToken,
            _toToken,
            _fromAmount,
            _minToAmount,
            _to,
            _deadline
        );

        (bool success, bytes memory res) = PTPPOOL.call(data);

        require(success, "PTP swap failed");

        (uint256 actualAmount, ) = abi.decode(res, (uint256, uint256));

        return actualAmount;
    }

    /**
     * @notice Safe token transfer
     * @dev Not allowed to transfer more tokens than the current balance
     * @param _token  Token address to be transferred
     * @param _amount Amount of token to be transferred
     * @return realAmount Real amount that has been transferred
     */
    function _safeTokenTransfer(address _token, uint256 _amount)
        internal
        returns (uint256 realAmount)
    {
        uint256 balance = IERC20(_token).balanceOf(address(this));

        if (balance > _amount) {
            realAmount = _amount;
        } else {
            realAmount = balance;
        }
        IERC20(_token).safeTransfer(msg.sender, realAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IVeERC20.sol";

/**
 * @dev Interface of the VePtp
 */
interface IVeDEG is IVeERC20 {
    function isUser(address _addr) external view returns (bool);

    function deposit(uint256 _amount) external;

    function claim() external;

    function withdraw(uint256 _amount) external;

    function getStakedPtp(address _addr) external view returns (uint256);

    function getVotes(address _account) external view returns (uint256);

    function lockVeDEG(address _to, uint256 _amount) external;

    function unlockVeDEG(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.10;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {StringsUtils} from "../libraries/StringsUtils.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20Decimals} from "../utils/interfaces/IERC20Decimals.sol";
import {IPriceGetter} from "./interfaces/IPriceGetter.sol";
import {INaughtyFactory} from "./interfaces/INaughtyFactory.sol";
import {INPPolicyToken} from "./interfaces/INPPolicyToken.sol";

/**
 * @title  PolicyCore
 * @notice Core logic of Naughty Price Product
 *         Preset:
 *              (Done in the naughtyFactory contract)
 *              1. Deploy policyToken contract
 *              2. Deploy policyToken-Stablecoin pool contract
 *         User Interaction:
 *              1. Deposit Stablecoin and mint PolicyTokens
 *              2. Redeem their Stablecoin and burn the PolicyTokens (before settlement)
 *              3. Claim for payout with PolicyTokens (after settlement)
 *         PolicyTokens are minted with the ratio 1:1 to Stablecoin
 *         The PolicyTokens are traded in the pool with CFMM (xy=k)
 *         When the event happens, a PolicyToken can be burned for claiming 1 Stablecoin.
 *         When the event does not happen, the PolicyToken depositors can
 *         redeem their 1 deposited Stablecoin
 *
 * @dev    Most of the functions to be called from outside will use the name of policyToken
 *         rather than the address (easy to read).
 *         Other variables or functions still use address to index.
 *         The rule of policyToken naming is:
 *              Original Token Name(with decimals) + Strike Price + Lower or Higher + Date
 *         E.g.  AVAX_30.0_L_2101, BTC_30000.0_L_2102, ETH_8000.0_H_2109
 *         (the original name need to be the same as in the chainlink oracle)
 *         There are three decimals for a policy token:
 *              1. Name decimals: Only for generating the name of policyToken
 *              2. Token decimals: The decimals of the policyToken
 *                 (should be the same as the paired stablecoin)
 *              3. Price decimals: Always 18. The oracle result will be transferred for settlement
 */

contract PolicyCore is OwnableUpgradeable {
    using StringsUtils for uint256;
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Factory contract, responsible for deploying new contracts
    INaughtyFactory public factory;

    // Oracle contract, responsible for getting the final price
    IPriceGetter public priceGetter;

    // Lottery address
    address public lottery;

    // Income sharing contract address
    address public incomeSharing;

    // Naughty Router contract address
    address public naughtyRouter;

    // Contract for initial liquidity matching
    address public ILMContract;

    // Income to lottery ratio (max 10)
    uint256 public toLotteryPart;

    struct PolicyTokenInfo {
        address policyTokenAddress;
        bool isCall;
        uint256 nameDecimals; // decimals of the name generation
        uint256 tokenDecimals; // decimals of the policy token
        uint256 strikePrice;
        uint256 deadline;
        uint256 settleTimestamp;
    }
    // Policy token name => Policy token information
    mapping(string => PolicyTokenInfo) public policyTokenInfoMapping;

    // Policy token address => Policy token name
    mapping(address => string) public policyTokenAddressToName;

    // Policy token name list
    string[] public allPolicyTokens;

    // Stablecoin address => Supported or not
    mapping(address => bool) public supportedStablecoin;

    // Policy token address => Stablecoin address
    mapping(address => address) public whichStablecoin;

    // PolicyToken => Strike Token (e.g. AVAX30L202101 address => AVAX address)
    mapping(address => string) policyTokenToOriginal;

    // User Address => Token Address => User Quota Amount
    mapping(address => mapping(address => uint256)) userQuota;

    // Policy token address => All the depositors for this round
    // (store all the depositors in an array)
    mapping(address => address[]) public allDepositors;

    struct SettlementInfo {
        uint256 price;
        bool isHappened;
        bool alreadySettled;
        uint256 currentDistributionIndex;
    }
    // Policy token address => Settlement result information
    mapping(address => SettlementInfo) public settleResult;

    mapping(address => uint256) public pendingIncomeToLottery;
    mapping(address => uint256) public pendingIncomeToSharing;

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Events ******************************************** //
    // ---------------------------------------------------------------------------------------- //

    event LotteryChanged(address oldLotteryAddress, address newLotteryAddress);
    event IncomeSharingChanged(
        address oldIncomeSharing,
        address newIncomeSharing
    );
    event NaughtyRouterChanged(address oldRouter, address newRouter);
    event ILMChanged(address oldILM, address newILM);
    event IncomeToLotteryChanged(uint256 oldToLottery, uint256 newToLottery);
    event PolicyTokenDeployed(
        string tokenName,
        address tokenAddress,
        uint256 tokenDecimals,
        uint256 deadline,
        uint256 settleTimestamp
    );
    event PoolDeployed(
        address poolAddress,
        address policyTokenAddress,
        address stablecoin
    );
    event PoolDeployedWithInitialLiquidity(
        address poolAddress,
        address policyTokenAddress,
        address stablecoin,
        uint256 initLiquidityA,
        uint256 initLiquidityB
    );
    event Deposit(
        address indexed userAddress,
        string indexed policyTokenName,
        address indexed stablecoin,
        uint256 amount
    );
    event DelegateDeposit(
        address payerAddress,
        address userAddress,
        string policyTokenName,
        address stablecoin,
        uint256 amount
    );
    event Redeem(
        address indexed userAddress,
        string indexed policyTokenName,
        address indexed stablecoin,
        uint256 amount
    );
    event RedeemAfterSettlement(
        address indexed userAddress,
        string indexed policyTokenName,
        address indexed stablecoin,
        uint256 amount
    );
    event FinalResultSettled(
        string _policyTokenName,
        uint256 price,
        bool isHappened
    );
    event NewStablecoinAdded(address _newStablecoin);
    event PolicyTokensSettledForUsers(
        string policyTokenName,
        address stablecoin,
        uint256 startIndex,
        uint256 stopIndex
    );
    event UpdateUserQuota(
        address user,
        address policyTokenAddress,
        uint256 amount
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Constructor, for some addresses
     * @param _usdc        USDC.e is the first stablecoin supported in the pool
     * @param _factory     Address of naughty factory
     * @param _priceGetter Address of the oracle contract
     */
    function initialize(
        address _usdc,
        address _factory,
        address _priceGetter
    ) public initializer {
        __Ownable_init();

        // Add the first stablecoin supported
        supportedStablecoin[_usdc] = true;

        // Initialize the interfaces
        factory = INaughtyFactory(_factory);
        priceGetter = IPriceGetter(_priceGetter);

        // 20% to lottery, 80% to income sharing
        toLotteryPart = 2;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check if this stablecoin is supported
     * @param _stablecoin Stablecoin address
     */
    modifier validStablecoin(address _stablecoin) {
        require(
            supportedStablecoin[_stablecoin] == true,
            "Do not support this stablecoin currently"
        );
        _;
    }

    /**
     * @notice Check whether the policy token is paired with this stablecoin
     * @param _policyTokenName Policy token name
     * @param _stablecoin      Stablecoin address
     */
    modifier validPolicyTokenWithStablecoin(
        string memory _policyTokenName,
        address _stablecoin
    ) {
        address policyTokenAddress = findAddressbyName(_policyTokenName);
        require(
            whichStablecoin[policyTokenAddress] == _stablecoin,
            "Invalid policytoken with stablecoin"
        );
        _;
    }

    /**
     * @notice Check if the policy token has been deployed, used when deploying pools
     * @param _policyTokenName Name of the policy token inside the pair
     */
    modifier deployedPolicy(string memory _policyTokenName) {
        require(
            policyTokenInfoMapping[_policyTokenName].policyTokenAddress !=
                address(0),
            "This policy token has not been deployed, please deploy it first"
        );
        _;
    }

    /**
     * @notice Deposit/Redeem/Swap only before deadline
     * @dev Each pool will also have this deadline
     *      That needs to be set inside naughtyFactory
     * @param _policyTokenName Name of the policy token
     */
    modifier beforeDeadline(string memory _policyTokenName) {
        uint256 deadline = policyTokenInfoMapping[_policyTokenName].deadline;
        require(
            block.timestamp <= deadline,
            "Can not deposit/redeem, has passed the deadline"
        );
        _;
    }

    /**
     * @notice Can only settle the result after the "_settleTimestamp"
     * @param _policyTokenName Name of the policy token
     */
    modifier afterSettlement(string memory _policyTokenName) {
        uint256 settleTimestamp = policyTokenInfoMapping[_policyTokenName]
            .settleTimestamp;
        require(
            block.timestamp >= settleTimestamp,
            "Can not settle/claim, have not reached settleTimestamp"
        );
        _;
    }

    /**
     * @notice Avoid multiple settlements
     * @param _policyTokenName Name of the policy token
     */
    modifier notAlreadySettled(string memory _policyTokenName) {
        address policyTokenAddress = findAddressbyName(_policyTokenName);
        require(
            settleResult[policyTokenAddress].alreadySettled == false,
            "This policy has already been settled"
        );
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Find the token address by its name
     * @param _policyTokenName Name of the policy token (e.g. "AVAX_30_L_2103")
     * @return policyTokenAddress Address of the policy token
     */
    function findAddressbyName(string memory _policyTokenName)
        public
        view
        returns (address policyTokenAddress)
    {
        policyTokenAddress = policyTokenInfoMapping[_policyTokenName]
            .policyTokenAddress;

        require(policyTokenAddress != address(0), "Policy token not found");
    }

    /**
     * @notice Find the token name by its address
     * @param _policyTokenAddress Address of the policy token
     * @return policyTokenName Name of the policy token
     */
    function findNamebyAddress(address _policyTokenAddress)
        public
        view
        returns (string memory policyTokenName)
    {
        policyTokenName = policyTokenAddressToName[_policyTokenAddress];

        require(bytes(policyTokenName).length > 0, "Policy name not found");
    }

    /**
     * @notice Find the token information by its name
     * @param _policyTokenName Name of the policy token (e.g. "AVAX30L202103")
     * @return policyTokenInfo PolicyToken detail information
     */
    function getPolicyTokenInfo(string memory _policyTokenName)
        public
        view
        returns (PolicyTokenInfo memory)
    {
        return policyTokenInfoMapping[_policyTokenName];
    }

    /**
     * @notice Get a user's quota for a certain policy token
     * @param _user               Address of the user to be checked
     * @param _policyTokenAddress Address of the policy token
     * @return _quota User's quota result
     */
    function getUserQuota(address _user, address _policyTokenAddress)
        external
        view
        returns (uint256 _quota)
    {
        _quota = userQuota[_user][_policyTokenAddress];
    }

    /**
     * @notice Get the information about all the tokens
     * @dev Include all active&expired tokens
     * @return tokensInfo Token information list
     */
    function getAllTokens() external view returns (PolicyTokenInfo[] memory) {
        uint256 length = allPolicyTokens.length;
        PolicyTokenInfo[] memory tokensInfo = new PolicyTokenInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            tokensInfo[i] = policyTokenInfoMapping[allPolicyTokens[i]];
        }

        return tokensInfo;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Add a new supported stablecoin
     * @param _newStablecoin Address of the new stablecoin
     */
    function addStablecoin(address _newStablecoin) external onlyOwner {
        supportedStablecoin[_newStablecoin] = true;
        emit NewStablecoinAdded(_newStablecoin);
    }

    /**
     * @notice Change the address of lottery
     * @param _lotteryAddress Address of the new lottery
     */
    function setLottery(address _lotteryAddress) external onlyOwner {
        emit LotteryChanged(lottery, _lotteryAddress);
        lottery = _lotteryAddress;
    }

    /**
     * @notice Change the address of emergency pool
     * @param _incomeSharing Address of the new incomeSharing
     */
    function setIncomeSharing(address _incomeSharing) external onlyOwner {
        emit IncomeSharingChanged(incomeSharing, _incomeSharing);
        incomeSharing = _incomeSharing;
    }

    /**
     * @notice Change the address of naughty router
     * @param _router Address of the new naughty router
     */
    function setNaughtyRouter(address _router) external onlyOwner {
        emit NaughtyRouterChanged(naughtyRouter, _router);
        naughtyRouter = _router;
    }

    /**
     * @notice Change the address of ILM
     * @param _ILM Address of the new ILM
     */
    function setILMContract(address _ILM) external onlyOwner {
        emit ILMChanged(ILMContract, _ILM);
        ILMContract = _ILM;
    }

    /**
     * @notice Change the income part to lottery
     * @dev The remaining part will be distributed to incomeSharing
     * @param _toLottery Proportion to lottery
     */
    function setIncomeToLottery(uint256 _toLottery) external onlyOwner {
        require(_toLottery <= 10, "Max 10");
        emit IncomeToLotteryChanged(toLotteryPart, _toLottery);
        toLotteryPart = _toLottery;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Deploy a new policy token and return the token address
     * @dev Only the owner can deploy new policy tokens
     *      The name form is like "AVAX_50_L_2203" and is built inside the contract
     *      Name decimals and token decimals are different here
     *      The original token name should be the same in Chainlink PriceFeeds
     *      Those tokens that are not listed on Chainlink are not supported
     * @param _tokenName       Name of the original token (e.g. AVAX, BTC, ETH...)
     * @param _stablecoin      Address of the stablecoin (Just for check decimals here)
     * @param _isCall          The policy is for higher or lower than the strike price (call / put)
     * @param _nameDecimals    Decimals of this token's name (0~18)
     * @param _tokenDecimals   Decimals of this token's value (0~18) (same as paired stablecoin)
     * @param _strikePrice     Strike price of the policy (have already been transferred with 1e18)
     * @param _round           Round of the token (e.g. 2203 -> expired at 22 March)
     * @param _deadline        Deadline of this policy token (deposit / redeem / swap)
     * @param _settleTimestamp Can settle after this timestamp (for oracle)
     */
    function deployPolicyToken(
        string memory _tokenName,
        address _stablecoin,
        bool _isCall,
        uint256 _nameDecimals,
        uint256 _tokenDecimals,
        uint256 _strikePrice,
        string memory _round,
        uint256 _deadline,
        uint256 _settleTimestamp
    ) external onlyOwner {
        require(
            _nameDecimals <= 18 && _tokenDecimals <= 18,
            "Too many decimals"
        );
        require(
            IERC20Decimals(_stablecoin).decimals() == _tokenDecimals,
            "Decimals not paired"
        );

        require(_deadline > block.timestamp, "Wrong deadline");
        require(_settleTimestamp >= _deadline, "Wrong settleTimestamp");

        // Generate the policy token name
        string memory policyTokenName = _generateName(
            _tokenName,
            _nameDecimals,
            _strikePrice,
            _isCall,
            _round
        );
        // Deploy a new policy token by the factory contract
        address policyTokenAddress = factory.deployPolicyToken(
            policyTokenName,
            _tokenDecimals
        );

        // Store the policyToken information in the mapping
        policyTokenInfoMapping[policyTokenName] = PolicyTokenInfo(
            policyTokenAddress,
            _isCall,
            _nameDecimals,
            _tokenDecimals,
            _strikePrice,
            _deadline,
            _settleTimestamp
        );

        // Keep the record from policy token to original token
        policyTokenToOriginal[policyTokenAddress] = _tokenName;

        // Record the address to name mapping
        policyTokenAddressToName[policyTokenAddress] = policyTokenName;

        // Push the policytokenName into the list
        allPolicyTokens.push(policyTokenName);

        emit PolicyTokenDeployed(
            policyTokenName,
            policyTokenAddress,
            _tokenDecimals,
            _deadline,
            _settleTimestamp
        );
    }

    /**
     * @notice Deploy a new pair (pool)
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin      Address of the stable coin
     * @param _poolDeadline    Swapping deadline of the pool (normally the same as the token's deadline)
     * @param _feeRate         Fee rate given to LP holders
     */
    function deployPool(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _poolDeadline,
        uint256 _feeRate
    )
        external
        validStablecoin(_stablecoin)
        deployedPolicy(_policyTokenName)
        returns (address)
    {
        require(
            msg.sender == owner() || msg.sender == ILMContract,
            "Only owner or ILM"
        );

        require(_poolDeadline > block.timestamp, "Wrong deadline");
        require(
            _poolDeadline == policyTokenInfoMapping[_policyTokenName].deadline,
            "Policy token and pool deadline not the same"
        );
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        address poolAddress = _deployPool(
            policyTokenAddress,
            _stablecoin,
            _poolDeadline,
            _feeRate
        );

        emit PoolDeployed(poolAddress, policyTokenAddress, _stablecoin);

        return poolAddress;
    }

    /**
     * @notice Deposit stablecoins and get policy tokens
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin      Address of the stable coin
     * @param _amount          Amount of stablecoin
     */
    function deposit(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _amount
    )
        public
        beforeDeadline(_policyTokenName)
        validPolicyTokenWithStablecoin(_policyTokenName, _stablecoin)
    {
        require(_amount > 0, "Zero Amount");
        _deposit(_policyTokenName, _stablecoin, _amount, msg.sender);
    }

    /**
     * @notice Delegate deposit (deposit and mint for other addresses)
     * @dev Only called by the router contract
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin      Address of the sable coin
     * @param _amount          Amount of stablecoin
     * @param _user            Address to receive the policy tokens
     */
    function delegateDeposit(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _amount,
        address _user
    )
        external
        beforeDeadline(_policyTokenName)
        validPolicyTokenWithStablecoin(_policyTokenName, _stablecoin)
    {
        require(
            msg.sender == naughtyRouter,
            "Only the router contract can delegate"
        );
        require(_amount > 0, "Zero Amount");

        _deposit(_policyTokenName, _stablecoin, _amount, _user);

        emit DelegateDeposit(
            msg.sender,
            _user,
            _policyTokenName,
            _stablecoin,
            _amount
        );
    }

    /**
     * @notice Burn policy tokens and redeem stablecoins
     * @dev Redeem happens before the deadline and is different from claim/settle
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin      Address of the stablecoin
     * @param _amount          Amount to redeem
     */
    function redeem(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _amount
    )
        public
        beforeDeadline(_policyTokenName)
        validPolicyTokenWithStablecoin(_policyTokenName, _stablecoin)
    {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        // Check if the user has enough quota (quota is only for those who mint policy tokens)
        require(
            userQuota[msg.sender][policyTokenAddress] >= _amount,
            "User's quota not sufficient"
        );

        // Update quota
        userQuota[msg.sender][policyTokenAddress] -= _amount;

        // Charge 1% Fee when redeem / claim
        uint256 amountWithFee = _chargeFee(_stablecoin, _amount);

        // Transfer back the stablecoin
        IERC20(_stablecoin).safeTransfer(msg.sender, amountWithFee);

        // Burn the policy tokens
        INPPolicyToken policyToken = INPPolicyToken(policyTokenAddress);
        policyToken.burn(msg.sender, _amount);

        emit Redeem(msg.sender, _policyTokenName, _stablecoin, _amount);
    }

    /**
     * @notice Redeem policy tokens and get stablecoins by the user himeself
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin      Address of the stablecoin
     */
    function redeemAfterSettlement(
        string memory _policyTokenName,
        address _stablecoin
    )
        public
        afterSettlement(_policyTokenName)
        validPolicyTokenWithStablecoin(_policyTokenName, _stablecoin)
    {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        // Copy to memory (will not change the result)
        SettlementInfo memory result = settleResult[policyTokenAddress];

        // Must have got the final price
        require(
            result.price != 0 && result.alreadySettled,
            "Have not got the oracle result"
        );

        // The event must be "not happend"
        require(
            result.isHappened == false,
            "Only call this function when the event does not happen"
        );

        uint256 quota = userQuota[msg.sender][policyTokenAddress];
        // User must have quota because this is for depositors when event not happens
        require(
            quota > 0,
            "No quota, you did not deposit and mint policy tokens before"
        );

        // Charge 1% Fee when redeem / claim
        uint256 amountWithFee = _chargeFee(_stablecoin, quota);

        // Send back stablecoins directly
        IERC20(_stablecoin).safeTransfer(msg.sender, amountWithFee);

        // Delete the userQuota storage
        delete userQuota[msg.sender][policyTokenAddress];

        emit RedeemAfterSettlement(
            msg.sender,
            _policyTokenName,
            _stablecoin,
            amountWithFee
        );
    }

    /**
     * @notice Claim a payoff based on policy tokens
     * @dev It is done after result settlement and only if the result is true
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin      Address of the stable coin
     * @param _amount          Amount of stablecoin
     */
    function claim(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _amount
    )
        public
        afterSettlement(_policyTokenName)
        validPolicyTokenWithStablecoin(_policyTokenName, _stablecoin)
    {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        // Copy to memory (will not change the result)
        SettlementInfo memory result = settleResult[policyTokenAddress];

        // Check if we have already settle the final price
        require(
            result.price != 0 && result.alreadySettled,
            "Have not got the oracle result"
        );

        // Check if the event happens
        require(
            result.isHappened,
            "The result does not happen, you can not claim"
        );

        // Charge 1% fee
        uint256 amountWithFee = _chargeFee(_stablecoin, _amount);

        IERC20(_stablecoin).safeTransfer(msg.sender, amountWithFee);

        // Users must have enough policy tokens to claim
        INPPolicyToken policyToken = INPPolicyToken(policyTokenAddress);

        // Burn the policy tokens
        policyToken.burn(msg.sender, _amount);
    }

    /**
     * @notice Get the final price from the PriceGetter contract
     * @param _policyTokenName Name of the policy token
     */
    function settleFinalResult(string memory _policyTokenName)
        public
        afterSettlement(_policyTokenName)
        notAlreadySettled(_policyTokenName)
    {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        SettlementInfo storage result = settleResult[policyTokenAddress];

        // Get the strike token name
        string memory originalTokenName = policyTokenToOriginal[
            policyTokenAddress
        ];

        // Get the final price from oracle
        uint256 price = priceGetter.getLatestPrice(originalTokenName);

        // Record the price
        result.alreadySettled = true;
        result.price = price;

        PolicyTokenInfo memory policyTokenInfo = policyTokenInfoMapping[
            _policyTokenName
        ];

        // Get the final result
        bool situationT1 = (price >= policyTokenInfo.strikePrice) &&
            policyTokenInfo.isCall;
        bool situationT2 = (price <= policyTokenInfo.strikePrice) &&
            !policyTokenInfo.isCall;

        bool isHappened = (situationT1 || situationT2) ? true : false;

        // Record the result
        result.isHappened = isHappened;

        emit FinalResultSettled(_policyTokenName, price, isHappened);
    }

    /**
     * @notice Settle the policies for the users when insurance events do not happen
     *         Funds are automatically distributed back to the depositors
     * @dev    Take care of the gas cost and can use the _startIndex and _stopIndex to control the size
     * @param _policyTokenName Name of policy token
     * @param _stablecoin      Address of stablecoin
     * @param _startIndex      Settlement start index
     * @param _stopIndex       Settlement stop index
     */
    function settleAllPolicyTokens(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _startIndex,
        uint256 _stopIndex
    ) public onlyOwner {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        // Copy to memory (will not change the result)
        SettlementInfo memory result = settleResult[policyTokenAddress];

        // Must have got the final price
        require(
            result.price != 0 && result.alreadySettled == true,
            "Have not got the oracle result"
        );

        // The event must be "not happend"
        require(
            result.isHappened == false,
            "Only call this function when the event does not happen"
        );

        // Store the amount to collect to lottery and emergency pool
        uint256 amountToCollect = 0;

        // Length of all depositors for this policy token
        uint256 length = allDepositors[policyTokenAddress].length;

        require(
            result.currentDistributionIndex <= length,
            "Have distributed all"
        );

        // Settle the policies in [_startIndex, _stopIndex)
        if (_startIndex == 0 && _stopIndex == 0) {
            amountToCollect += _settlePolicy(
                policyTokenAddress,
                _stablecoin,
                0,
                length
            );

            // Update the distribution index for this policy token
            settleResult[policyTokenAddress].currentDistributionIndex = length;

            emit PolicyTokensSettledForUsers(
                _policyTokenName,
                _stablecoin,
                0,
                length
            );
        } else {
            require(
                result.currentDistributionIndex == _startIndex,
                "You need to start from the last distribution point"
            );
            require(_stopIndex < length, "Invalid stop index");

            amountToCollect += _settlePolicy(
                policyTokenAddress,
                _stablecoin,
                _startIndex,
                _stopIndex
            );

            // Update the distribution index for this policy token
            settleResult[policyTokenAddress]
                .currentDistributionIndex = _stopIndex;

            emit PolicyTokensSettledForUsers(
                _policyTokenName,
                _stablecoin,
                _startIndex,
                _stopIndex
            );
        }
    }

    /**
     * @notice Collect the income
     * @dev Can be done by anyone, only when there is some income to be distributed
     * @param _stablecoin Address of stablecoin
     */
    function collectIncome(address _stablecoin) public {
        require(
            lottery != address(0) && incomeSharing != address(0),
            "Please set the lottery & incomeSharing address"
        );

        uint256 amountToLottery = pendingIncomeToLottery[_stablecoin];
        uint256 amountToSharing = pendingIncomeToSharing[_stablecoin];
        require(
            amountToLottery > 0 || amountToSharing > 0,
            "No pending income"
        );

        IERC20(_stablecoin).safeTransfer(lottery, amountToLottery);
        IERC20(_stablecoin).safeTransfer(incomeSharing, amountToSharing);

        pendingIncomeToLottery[_stablecoin] = 0;
        pendingIncomeToSharing[_stablecoin] = 0;
    }

    /**
     * @notice Update user quota from ILM when claim
     *
     * @dev When you claim your liquidity from ILM, you will get normal quota as you are using policyCore
     * @param _user        User address
     * @param _policyToken PolicyToken address
     * @param _amount      Quota amount
     */
    function updateUserQuota(
        address _user,
        address _policyToken,
        uint256 _amount
    ) external {
        require(msg.sender == ILMContract, "Only ILM");

        userQuota[_user][_policyToken] += _amount;

        emit UpdateUserQuota(_user, _policyToken, _amount);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Finish deploying a pool
     *
     * @param _policyTokenAddress Address of the policy token
     * @param _stablecoin         Address of the stable coin
     * @param _poolDeadline       Swapping deadline of the pool (normally the same as the token's deadline)
     * @param _feeRate            Fee rate given to LP holders
     *
     * @return poolAddress Address of the pool
     */
    function _deployPool(
        address _policyTokenAddress,
        address _stablecoin,
        uint256 _poolDeadline,
        uint256 _feeRate
    ) internal returns (address) {
        // Deploy a new pool (policyToken <=> stablecoin)
        address poolAddress = factory.deployPool(
            _policyTokenAddress,
            _stablecoin,
            _poolDeadline,
            _feeRate
        );

        // Record the mapping
        whichStablecoin[_policyTokenAddress] = _stablecoin;

        return poolAddress;
    }

    /**
     * @notice Finish Deposit
     *
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin Address of the sable coin
     * @param _amount Amount of stablecoin
     * @param _user Address to receive the policy tokens
     */
    function _deposit(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _amount,
        address _user
    ) internal {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        // If this is the first deposit, store the user address
        if (userQuota[_user][policyTokenAddress] == 0) {
            allDepositors[policyTokenAddress].push(_user);
        }

        // Update the user quota
        userQuota[_user][policyTokenAddress] += _amount;

        // Transfer stablecoins to this contract
        IERC20(_stablecoin).safeTransferFrom(_user, address(this), _amount);

        INPPolicyToken policyToken = INPPolicyToken(policyTokenAddress);

        // Mint new policy tokens
        policyToken.mint(_user, _amount);

        emit Deposit(_user, _policyTokenName, _stablecoin, _amount);
    }

    /**
     * @notice Settle the policy when the event does not happen
     *
     * @param _policyTokenAddress Address of policy token
     * @param _stablecoin Address of stable coin
     * @param _start Start index
     * @param _stop Stop index
     */
    function _settlePolicy(
        address _policyTokenAddress,
        address _stablecoin,
        uint256 _start,
        uint256 _stop
    ) internal returns (uint256 amountRemaining) {
        for (uint256 i = _start; i < _stop; i++) {
            address user = allDepositors[_policyTokenAddress][i];
            uint256 amount = userQuota[user][_policyTokenAddress];
            // Charge fee
            uint256 amountWithFee = _chargeFee(_stablecoin, amount);

            if (amountWithFee > 0) {
                IERC20(_stablecoin).safeTransfer(user, amountWithFee);
                delete userQuota[user][_policyTokenAddress];

                // Accumulate the remaining part that will be collected later
                amountRemaining += amount - amountWithFee;
            } else continue;
        }
    }

    /**
     * @notice Charge fee when redeem / claim
     *
     * @param _stablecoin Stablecoin address
     * @param _amount     Amount to redeem / claim
     *
     * @return amountWithFee Amount with fee
     */
    function _chargeFee(address _stablecoin, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 amountWithFee = (_amount * 990) / 1000;
        uint256 amountToCollect = _amount - amountWithFee;

        uint256 amountToLottery = (amountToCollect * toLotteryPart) / 10;

        pendingIncomeToLottery[_stablecoin] += amountToLottery;
        pendingIncomeToSharing[_stablecoin] +=
            amountToCollect -
            amountToLottery;

        return amountWithFee;
    }

    /**
     * @notice Generate the policy token name
     *
     * @param _tokenName   Name of the stike token (BTC, ETH, AVAX...)
     * @param _decimals    Decimals of the name generation (0,1=>1, 2=>2)
     * @param _strikePrice Strike price of the policy (18 decimals)
     * @param _isCall      The policy's payoff is triggered when higher(true) or lower(false)
     * @param _round       Round of the policy, named by <month><day> (e.g. 0320, 1215)
     */
    function _generateName(
        string memory _tokenName,
        uint256 _decimals,
        uint256 _strikePrice,
        bool _isCall,
        string memory _round
    ) public pure returns (string memory) {
        // The direction is "H"(Call) or "L"(Put)
        string memory direction = _isCall ? "H" : "L";

        // Integer part of the strike price (12e18 => 12)
        uint256 intPart = _strikePrice / 1e18;
        require(intPart > 0, "Invalid int part");

        // Decimal part of the strike price (1234e16 => 34)
        // Can not start with 0 (e.g. 1204e16 => 0 this is incorrect, will revert in next step)
        uint256 decimalPart = _frac(_strikePrice) / (10**(18 - _decimals));
        if (_decimals >= 2)
            require(decimalPart > 10**(_decimals - 1), "Invalid decimal part");

        // Combine the string
        string memory name = string(
            abi.encodePacked(
                _tokenName,
                "_",
                intPart.uintToString(),
                ".",
                decimalPart.uintToString(),
                "_",
                direction,
                "_",
                _round
            )
        );
        return name;
    }

    /**
     * @notice Calculate the fraction part of a number
     *
     * @dev The scale is fixed as 1e18 (decimal fraction)
     *      
     * @param x Number to calculate
     *
     * @return result Fraction result
     */
    function _frac(uint256 x) internal pure returns (uint256 result) {
        uint256 SCALE = 1e18;
        assembly {
            result := mod(x, SCALE)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.10;

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IPriceGetter {
    function getPriceFeedAddress(string memory _tokenName)
        external
        view
        returns (address);

    function setPriceFeed(string memory _tokenName, address _feedAddress)
        external;

    function getLatestPrice(string memory _tokenName)
        external
        returns (uint256 _price);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface INaughtyFactory {
    function getPairAddress(address _tokenAddress1, address _tokenAddress2)
        external
        view
        returns (address);

    function deployPolicyToken(
        string memory _policyTokenName,
        uint256 _decimals
    ) external returns (address);

    function deployPool(
        address _policyTokenAddress,
        address _stablecoin,
        uint256 _deadline,
        uint256 _feeRate
    ) external returns (address);

    function incomeMaker() external view returns (address);

    function incomeMakerProportion() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INPPolicyToken is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC20PermitWithMultipleMinters is IERC20, IERC20Permit {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Functions ************************************** //
    // ---------------------------------------------------------------------------------------- //
    /**
     * @notice Add a new minter into the minterList
     * @param _newMinter Address of the new minter
     */
    function addMinter(address _newMinter) external;

    /**
     * @notice Remove a minter from the minterList
     * @param _oldMinter Address of the minter to be removed
     */
    function removeMinter(address _oldMinter) external;

    /**
     * @notice Add a new burner into the burnerList
     * @param _newBurner Address of the new burner
     */
    function addBurner(address _newBurner) external;

    /**
     * @notice Remove a minter from the minterList
     * @param _oldBurner Address of the minter to be removed
     */
    function removeBurner(address _oldBurner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IFDPolicyToken is IERC721Enumerable {
    function mintPolicyToken(address _receiver) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function getTokenURI(uint256 _tokenId)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;
import "../proxy/OwnableUpgradeable.sol";
import "../tokens/interfaces/IBuyerToken.sol";
import "./interfaces/ISigManager.sol";
import "./interfaces/IFDPolicyToken.sol";
import "./interfaces/IFlightOracle.sol";
import "./interfaces/IInsurancePool.sol";
import "./interfaces/IPolicyStruct.sol";
import "./abstracts/PolicyParameters.sol";
import "../libraries/StringsUtils.sol";
import "../libraries/StablecoinDecimal.sol";

contract PolicyFlow is IPolicyStruct, PolicyParameters, OwnableUpgradeable {
    using StringsUtils for uint256;
    using StablecoinDecimal for uint256;

    // Other contracts
    IBuyerToken public buyerToken;
    ISigManager public sigManager;
    IFDPolicyToken public policyToken;
    IFlightOracle public flightOracle;
    IInsurancePool public insurancePool;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    string public FLIGHT_STATUS_URL = "https://degis.io:3207/flight_status?";

    uint256 public totalPolicies;

    uint256 public fee;

    mapping(uint256 => PolicyInfo) public policyList;

    mapping(address => uint256[]) userPolicyList;

    mapping(bytes32 => uint256) requestList;

    mapping(uint256 => uint256) delayResultList;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //
    event FeeChanged(uint256 newFee);
    event MaxPayoffChanged(uint256 newMaxPayoff);
    event MinTimeBeforeDepartureChanged(uint256 newMinTime);
    event FlightOracleChanged(address newOracle);
    event OracleUrlChanged(string newUrl);
    event DelayThresholdChanged(uint256 thresholdMin, uint256 thresholdMax);

    event NewPolicyApplication(uint256 policyId, address indexed user);
    event NewClaimRequest(
        uint256 policyId,
        string flightNumber,
        bytes32 requestId
    );
    event PolicySold(uint256 policyId, address indexed user);
    event PolicyDeclined(uint256 policyId, address indexed user);
    event PolicyClaimed(uint256 policyId, address indexed user);
    event PolicyExpired(uint256 policyId, address indexed user);
    event FulfilledOracleRequest(uint256 policyId, bytes32 requestId);
    event PolicyOwnerTransfer(uint256 indexed tokenId, address newOwner);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Initializer ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Initializer of the PolicyFlow contract
     * @dev Upgradeable contracts do not have a constrcutor
     * @param _insurancePool The InsurancePool contract address
     * @param _policyToken The PolicyToken contract address
     * @param _sigManager The SigManager contract address
     * @param _buyerToken The BuyerToken contract address
     */
    function initialize(
        address _insurancePool,
        address _policyToken,
        address _sigManager,
        address _buyerToken
    ) public initializer {
        __Ownable_init(msg.sender);
        __PolicyFlow_init(
            _insurancePool,
            _policyToken,
            _sigManager,
            _buyerToken
        );
    }

    function __PolicyFlow_init(
        address _insurancePool,
        address _policyToken,
        address _sigManager,
        address _buyerToken
    ) internal onlyInitializing {
        insurancePool = IInsurancePool(_insurancePool);
        policyToken = IFDPolicyToken(_policyToken);
        sigManager = ISigManager(_sigManager);
        buyerToken = IBuyerToken(_buyerToken);

        // Set the oracle fee
        fee = 0.1 * 10**18;
    }

    // ----------------------------------------------------------------------------------- //
    // ********************************* View Functions ********************************** //
    // ----------------------------------------------------------------------------------- //

    /**
     * @notice Show a user's policies (all)
     * @dev Should only be checked for frontend
     * @param _user User's address
     * @return userPolicies User's all policy details
     */
    function viewUserPolicy(address _user)
        external
        view
        returns (PolicyInfo[] memory)
    {
        uint256 userPolicyAmount = userPolicyList[_user].length;
        require(userPolicyAmount > 0, "No policy for this user");

        PolicyInfo[] memory result = new PolicyInfo[](userPolicyAmount);

        for (uint256 i = 0; i < userPolicyAmount; i++) {
            uint256 policyId = userPolicyList[_user][i];

            result[i] = policyList[policyId];
        }
        return result;
    }

    /**
     * @notice Get the policyInfo from its count/order
     * @param _policyId Total count/order of the policy = NFT tokenId
     * @return policy A struct of information about this policy
     */
    // TODO: If still need this function
    function getPolicyInfoById(uint256 _policyId)
        public
        view
        returns (PolicyInfo memory policy)
    {
        policy = policyList[_policyId];
    }

    /**
     * @notice Get the policy buyer by policyId
     * @param _policyId Unique policy Id (uint256)
     * @return buyerAddress The buyer of this policy
     */
    // TODO: If still need this function
    function findPolicyBuyerById(uint256 _policyId)
        public
        view
        returns (address buyerAddress)
    {
        buyerAddress = policyList[_policyId].buyerAddress;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Change the oracle fee
     * @param _fee New oracle fee
     */
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit FeeChanged(_fee);
    }

    /**
     * @notice Change the max payoff
     * @param _newMaxPayoff New maxpayoff amount
     */
    function setMaxPayoff(uint256 _newMaxPayoff) external onlyOwner {
        MAX_PAYOFF = _newMaxPayoff;
        emit MaxPayoffChanged(_newMaxPayoff);
    }

    /**
     * @notice How long before departure when users can not buy new policies
     * @param _newMinTime New time set
     */
    function setMinTimeBeforeDeparture(uint256 _newMinTime) external onlyOwner {
        MIN_TIME_BEFORE_DEPARTURE = _newMinTime;
        emit MinTimeBeforeDepartureChanged(_newMinTime);
    }

    /**
     * @notice Change the oracle address
     * @param _oracleAddress New oracle address
     */
    function setFlightOracle(address _oracleAddress) external onlyOwner {
        flightOracle = IFlightOracle(_oracleAddress);
        emit FlightOracleChanged(_oracleAddress);
    }

    /**
     * @notice Set a new url
     */
    function setURL(string memory _url) external onlyOwner {
        FLIGHT_STATUS_URL = _url;
        emit OracleUrlChanged(_url);
    }

    /**
     * @notice Set the new delay threshold used for calculating payoff
     * @param _thresholdMin New minimum threshold
     * @param _thresholdMax New maximum threshold
     */
    function setDelayThreshold(uint256 _thresholdMin, uint256 _thresholdMax)
        external
        onlyOwner
    {
        DELAY_THRESHOLD_MIN = _thresholdMin;
        DELAY_THRESHOLD_MAX = _thresholdMax;
        emit DelayThresholdChanged(_thresholdMin, _thresholdMax);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Buy a new flight delay policy
     * @dev The transaction should have the signature from the backend server
     * @dev Premium is in stablecoin, so it is 6 decimals
     * @param _productId ID of the purchased product (0: flightdelay; 1,2,3...: others)
     * @param _flightNumber Flight number in string (e.g. "AQ1299")
     * @param _premium Premium of this policy (decimals: 6)
     * @param _departureTimestamp Departure date of this flight (unix timestamp in s, not ms!)
     * @param _landingDate Landing date of this flight (uinx timestamp in s, not ms!)
     * @param _deadline Deadline for this purchase request
     * @param signature Use web3.eth.sign(hash(data), account) to generate the signature
     */
    function newApplication(
        uint256 _productId,
        string memory _flightNumber,
        uint256 _premium,
        uint256 _departureTimestamp,
        uint256 _landingDate,
        uint256 _deadline,
        bytes calldata signature
    ) public returns (uint256 _policyId) {
        uint256 currentTimestamp = block.timestamp;
        require(
            currentTimestamp <= _deadline,
            "Expired deadline, please resubmit a transaction"
        );

        require(
            _productId == PRODUCT_ID,
            "You are calling the wrong product contract"
        );

        require(
            _departureTimestamp >= currentTimestamp + MIN_TIME_BEFORE_DEPARTURE,
            "It's too close to the departure time, you cannot buy this policy"
        );

        // Should be signed by operators
        _checkSignature(
            signature,
            _flightNumber,
            _departureTimestamp,
            _landingDate,
            _msgSender(),
            _premium,
            _deadline
        );

        // Generate the policy
        // Use ++totalPolicies to keep the policyId the same as ERC721 tokenId
        // Policy Id starts from 1
        uint256 currentPolicyId = ++totalPolicies;

        policyList[currentPolicyId] = PolicyInfo(
            PRODUCT_ID,
            _msgSender(),
            currentPolicyId,
            _flightNumber,
            _premium,
            MAX_PAYOFF,
            currentTimestamp,
            _departureTimestamp,
            _landingDate,
            PolicyStatus.INI,
            false,
            404
        );

        // Check the policy with the insurance pool status
        // May be accepted or rejected, if accepted then update the status of insurancePool
        _policyCheck(_premium, MAX_PAYOFF, msg.sender, currentPolicyId);

        // Give buyer tokens depending on the usd value they spent
        buyerToken.mintBuyerToken(msg.sender, _premium.toNormal());

        // Store the policy's total order with userAddress
        userPolicyList[msg.sender].push(totalPolicies);

        emit NewPolicyApplication(currentPolicyId, msg.sender);

        return currentPolicyId;
    }

    /**
     * @notice Make a claim request
     * @dev Anyone can make a new claim
     * @param _policyId The total order/id of the policy
     * @param _flightNumber The flight number
     * @param _timestamp The flight departure timestamp
     * @param _path Which data in json needs to get
     * @param _forceUpdate Owner can force to update
     */
    function newClaimRequest(
        uint256 _policyId,
        string memory _flightNumber,
        string memory _timestamp,
        string memory _path,
        bool _forceUpdate
    ) public {
        PolicyInfo memory policy = policyList[_policyId];

        // Can not get the result before landing date
        // Landing date may not be true, may be a fixed interval (4hours)
        require(
            block.timestamp >= policy.landingTimestamp,
            "Can only claim a policy after its expected landing timestamp"
        );

        // Check if the policy has been settled
        require(
            (!policy.alreadySettled) ||
                (_forceUpdate && (_msgSender() == owner())),
            "Already settled"
        );

        // Check if the flight number is correct
        require(
            keccak256(abi.encodePacked(_flightNumber)) ==
                keccak256(abi.encodePacked(policy.flightNumber)),
            "Wrong flight number provided"
        );

        // Check if the departure date is correct
        require(
            keccak256(abi.encodePacked(_timestamp)) ==
                keccak256(
                    abi.encodePacked(policy.departureTimestamp.uintToString())
                ),
            "Wrong departure timestamp provided"
        );

        // Construct the url for oracle
        string memory _url = string(
            abi.encodePacked(
                FLIGHT_STATUS_URL,
                "flight_no=",
                _flightNumber,
                "&timestamp=",
                _timestamp
            )
        );

        // Start a new oracle request
        bytes32 requestId = flightOracle.newOracleRequest(fee, _url, _path, 1);

        // Record this request
        requestList[requestId] = _policyId;
        policyList[_policyId].alreadySettled = true;

        emit NewClaimRequest(_policyId, _flightNumber, requestId);
    }

    /**
     * @notice Update information when a policy token's ownership has been transferred
     * @dev This function is called by the ERC721 contract of PolicyToken
     * @param _tokenId Token Id of the policy token
     * @param _oldOwner The initial owner
     * @param _newOwner The new owner
     */
    function policyOwnerTransfer(
        uint256 _tokenId,
        address _oldOwner,
        address _newOwner
    ) external {
        // Check the call is from policy token contract
        require(
            _msgSender() == address(policyToken),
            "only called from the flight delay policy token contract"
        );

        // Check the previous owner record
        uint256 policyId = _tokenId;
        require(
            _oldOwner == policyList[policyId].buyerAddress,
            "The previous owner is wrong"
        );

        // Update the new buyer address
        policyList[policyId].buyerAddress = _newOwner;
        emit PolicyOwnerTransfer(_tokenId, _newOwner);
    }

    // ----------------------------------------------------------------------------------- //
    // ********************************* Oracle Functions ******************************** //
    // ----------------------------------------------------------------------------------- //

    /**
     * @notice Do the final settlement, called by FlightOracle contract
     * @param _requestId Chainlink request id
     * @param _result Delay result (minutes) given by oracle
     */
    function finalSettlement(bytes32 _requestId, uint256 _result) public {
        // Check if the call is from flight oracle
        require(
            msg.sender == address(flightOracle),
            "this function should be called by FlightOracle contract"
        );

        uint256 policyId = requestList[_requestId];

        PolicyInfo storage policy = policyList[policyId];
        policy.delayResult = _result;

        uint256 premium = policy.premium;
        address buyerAddress = policy.buyerAddress;

        require(
            _result <= DELAY_THRESHOLD_MAX || _result == 400,
            "Abnormal oracle result, result should be [0 - 240] or 400"
        );

        if (_result == 0) {
            // 0: on time
            _policyExpired(premium, MAX_PAYOFF, buyerAddress, policyId);
        } else if (_result <= DELAY_THRESHOLD_MAX) {
            uint256 real_payoff = calcPayoff(_result);
            _policyClaimed(premium, real_payoff, buyerAddress, policyId);
        } else if (_result == 400) {
            // 400: cancelled
            _policyClaimed(premium, MAX_PAYOFF, buyerAddress, policyId);
        }

        emit FulfilledOracleRequest(policyId, _requestId);
    }

    // ----------------------------------------------------------------------------------- //
    // ******************************** Internal Functions ******************************* //
    // ----------------------------------------------------------------------------------- //

    /**
     * @notice check the policy and then determine whether we can afford it
     * @param _payoff the payoff of the policy sold
     * @param _user user's address
     * @param _policyId the unique policy ID
     */
    function _policyCheck(
        uint256 _premium,
        uint256 _payoff,
        address _user,
        uint256 _policyId
    ) internal {
        // Whether there are enough capacity in the pool
        bool _isAccepted = insurancePool.checkCapacity(_payoff);

        if (_isAccepted) {
            insurancePool.updateWhenBuy(_premium, _payoff, _user);
            policyList[_policyId].status = PolicyStatus.SOLD;
            emit PolicySold(_policyId, _user);

            policyToken.mintPolicyToken(_user);
        } else {
            emit PolicyDeclined(_policyId, _user);
            revert("not sufficient capacity in the insurance pool");
        }
    }

    /**
     * @notice update the policy when it is expired
     * @param _premium the premium of the policy sold
     * @param _payoff the payoff of the policy sold
     * @param _user user's address
     * @param _policyId the unique policy ID
     */
    function _policyExpired(
        uint256 _premium,
        uint256 _payoff,
        address _user,
        uint256 _policyId
    ) internal {
        insurancePool.updateWhenExpire(_premium, _payoff);
        policyList[_policyId].status = PolicyStatus.EXPIRED;
        emit PolicyExpired(_policyId, _user);
    }

    /**
     * @notice Update the policy when it is claimed
     * @param _premium Premium of the policy sold
     * @param _payoff Payoff of the policy sold
     * @param _user User's address
     * @param _policyId The unique policy ID
     */
    function _policyClaimed(
        uint256 _premium,
        uint256 _payoff,
        address _user,
        uint256 _policyId
    ) internal {
        insurancePool.payClaim(_premium, MAX_PAYOFF, _payoff, _user);
        policyList[_policyId].status = PolicyStatus.CLAIMED;
        emit PolicyClaimed(_policyId, _user);
    }

    /**
     * @notice The payoff formula
     * @param _delay Delay in minutes
     * @return the final payoff volume
     */
    function calcPayoff(uint256 _delay) internal view returns (uint256) {
        uint256 payoff = 0;

        // payoff model 1 - linear
        if (_delay <= DELAY_THRESHOLD_MIN) {
            payoff = 0;
        } else if (
            _delay > DELAY_THRESHOLD_MIN && _delay <= DELAY_THRESHOLD_MAX
        ) {
            payoff = (_delay * _delay) / 480;
        } else if (_delay > DELAY_THRESHOLD_MAX) {
            payoff = MAX_PAYOFF;
        }

        payoff = payoff * 1e6;
        return payoff;
    }

    /**
     * @notice Check whether the signature is valid
     * @param signature 65 byte array: [[v (1)], [r (32)], [s (32)]]
     * @param _flightNumber Flight number
     * @param _address userAddress
     * @param _premium Premium of the policy
     * @param _deadline Deadline of the application
     */
    function _checkSignature(
        bytes calldata signature,
        string memory _flightNumber,
        uint256 _departureTimestamp,
        uint256 _landingDate,
        address _address,
        uint256 _premium,
        uint256 _deadline
    ) internal view {
        sigManager.checkSignature(
            signature,
            _flightNumber,
            _departureTimestamp,
            _landingDate,
            _address,
            _premium,
            _deadline
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address _initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(_initialOwner);
    }

    function __Ownable_init_unchained(address _initialOwner) internal onlyInitializing {
        _transferOwnership( _initialOwner);
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBuyerToken is IERC20 {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Functions ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Mint buyer tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be minted
     */
    function mintBuyerToken(address _account, uint256 _amount) external;

    /**
     * @notice Burn buyer tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be burned
     */
    function burnBuyerToken(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface ISigManager {
    event SignerAdded(address indexed _newSigner);
    event SignerRemoved(address indexed _oldSigner);

    function addSigner(address) external;

    function removeSigner(address) external;

    function isValidSigner(address) external view returns (bool);

    function checkSignature(
        bytes calldata signature,
        string memory _flightNumber,
        uint256 _departureTimestamp,
        uint256 _landingDate,
        address _address,
        uint256 _premium,
        uint256 _deadline
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IFlightOracle {
    function newOracleRequest(
        uint256 _payment,
        string memory _url,
        string memory _path,
        int256 times
    ) external returns (bytes32);

    // Set a new url
    function setURL(string memory _url) external;

    // Set the oracle address
    function setOracleAddress(address _newOracle) external;

    // Set a new job id
    function setJobId(bytes32 _newJobId) external;

    // Set a new policy flow
    function setPolicyFlow(address _policyFlow) external;

    function getChainlinkTokenAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IInsurancePool {
    // view functions

    function getUserBalance(address) external view returns (uint256);

    function getPoolUnlocked() external view returns (uint256);

    function getUnlockedFor(address _user) external view returns (uint256);

    function getLockedFor(address _user) external view returns (uint256);

    function checkCapacity(uint256 _payoff) external view returns (bool);

    // set functions

    function setPurchaseIncentive(uint256 _newIncentive) external;

    function setFrozenTime(uint256 _newFrozenTime) external;

    function setPolicyFlow(address _policyFlowAddress) external;

    function setIncomeDistribution(uint256[3] memory _newDistribution) external;

    function setCollateralFactor(uint256 _factor) external;

    function transferOwnership(address _newOwner) external;

    // main functions

    function stake(address _user, uint256 _amount) external;

    function unstake(uint256 _amount) external;

    function unstakeMax() external;

    function updateWhenBuy(
        uint256 _premium,
        uint256 _payoff,
        address _user
    ) external;

    function updateWhenExpire(uint256 _premium, uint256 _payoff) external;

    function payClaim(
        uint256 _premium,
        uint256 _payoff,
        uint256 _realPayoff,
        address _user
    ) external;

    function revertUnstakeRequest(address _user) external;

    function revertAllUnstakeRequest(address _user) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

abstract contract PolicyParameters {
    // Product parameter
    uint256 public constant PRODUCT_ID = 0;

    // Parameters about the claim curve
    uint256 public MAX_PAYOFF = 180 * 10**6;
    uint256 public DELAY_THRESHOLD_MIN = 30;
    uint256 public DELAY_THRESHOLD_MAX = 240;

    // Minimum time before departure for applying
    uint256 public MIN_TIME_BEFORE_DEPARTURE = 24 hours;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library StablecoinDecimal {
    function toNormal(uint256 _value) internal pure returns (uint256) {
        uint256 decimal_difference = 1e12;
        return _value / decimal_difference;
    }

    function toStablecoin(uint256 _value) internal pure returns (uint256) {
        uint256 decimal_difference = 1e12;
        return _value * decimal_difference;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../utils/OwnableWithoutContext.sol";
import "../libraries/StringsUtils.sol";
import "./interfaces/IPolicyFlow.sol";
import "./interfaces/IPolicyStruct.sol";

/**
 * @title  Policy Token for flight delay
 * @notice ERC721 policy token
 *         Can get a long string form of the tokenURI
 *         When the ownership is transferred, it will update the status in policyFlow
 */
contract FDPolicyToken is
    ERC721Enumerable,
    IPolicyStruct,
    OwnableWithoutContext
{
    using StringsUtils for uint256;
    using StringsUtils for address;

    // PolicyFlow contract interface
    IPolicyFlow public policyFlow;

    uint256 public _nextId;

    struct PolicyTokenURIParam {
        string flightNumber;
        address owner;
        uint256 premium;
        uint256 payoff;
        uint256 purchaseTimestamp;
        uint256 departureTimestamp;
        uint256 landingTimestamp;
        uint256 status;
    }

    event PolicyFlowUpdated(address newPolicyFlow);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor()
        ERC721("Degis FlightDelay PolicyToken", "DEGIS_FD_PT")
        OwnableWithoutContext(msg.sender)
    {
        _nextId = 1;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get the tokenURI of a policy
     * @param _tokenId Token Id of the policy token
     * @return The tokenURI in string form
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_tokenId < _nextId, "TokenId is too large!");
        return _getTokenURI(_tokenId);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Set Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
       @notice Update the policyFlow address if it has been updated
       @param _policyFlow New policyFlow contract address
     */
    function updatePolicyFlow(address _policyFlow) external onlyOwner {
        policyFlow = IPolicyFlow(_policyFlow);
        emit PolicyFlowUpdated(_policyFlow);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Main Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Mint a new policy token to an address
     * @param _to The receiver address
     */
    function mintPolicyToken(address _to) public {
        require(
            _msgSender() == address(policyFlow),
            "Only the policyflow contract can mint fd policy token"
        );
        uint256 tokenId = _nextId++;
        _safeMint(_to, tokenId);
    }

    /**
     * @notice Transfer the owner of a policy token and update the information in policyFlow
     * @dev Need approval and is prepared for secondary market
     * @dev If you just transfer the policy token, you will not transfer the right for claiming payoff
     * @param _from The original owner of the policy
     * @param _to The new owner of the policy
     * @param _tokenId Token id of the policy
     */
    function transferOwner(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId);
        policyFlow.policyOwnerTransfer(_tokenId, _from, _to);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get the tokenURI, the metadata is from policyFlow contract
     * @param _tokenId Token Id of the policy token
     */
    function _getTokenURI(uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        PolicyInfo memory info = policyFlow.getPolicyInfoById(_tokenId);

        return
            _constructTokenURI(
                PolicyTokenURIParam(
                    info.flightNumber,
                    info.buyerAddress,
                    info.premium,
                    info.payoff,
                    info.purchaseTimestamp,
                    info.departureTimestamp,
                    info.landingTimestamp,
                    uint256(info.status)
                )
            );
    }

    /**
     * @notice Construct the metadata of a specific policy token
     * @param _params The parameters of the policy token
     */
    function _constructTokenURI(PolicyTokenURIParam memory _params)
        internal
        pure
        returns (string memory)
    {
        string[9] memory parts;

        parts[0] = "ProductId: 0, ";
        parts[1] = string(
            abi.encodePacked("FlightNumber: ", _params.flightNumber, ", ")
        );
        parts[2] = string(
            abi.encodePacked(
                "BuyerAddress: ",
                (_params.owner).addressToString(),
                ", "
            )
        );

        parts[3] = string(
            abi.encodePacked(
                "Premium: ",
                (_params.premium / 1e18).uintToString(),
                ", "
            )
        );

        parts[4] = string(
            abi.encodePacked(
                "Payoff: ",
                (_params.payoff / 1e18).uintToString(),
                ", "
            )
        );

        parts[5] = string(
            abi.encodePacked(
                "PurchaseTimestamp: ",
                _params.purchaseTimestamp.uintToString(),
                ", "
            )
        );

        parts[6] = string(
            abi.encodePacked(
                "DepartureTimestamp:",
                _params.departureTimestamp.uintToString(),
                ", "
            )
        );

        parts[7] = string(
            abi.encodePacked(
                "LandingTimestamp: ",
                (_params.landingTimestamp).uintToString(),
                ", "
            )
        );

        parts[8] = string(
            abi.encodePacked(
                "PolicyStatus: ",
                _params.status.uintToString(),
                "."
            )
        );

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        return output;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./interfaces/IPolicyFlow.sol";
import "../utils/Ownable.sol";

/**
 * @title  Flight Oracle
 * @notice This is the flight oracle contract.
 *         Called by policyFlow contract and send the request to chainlink node.
 *         After receiving the result, call the policyFlow contract to do the settlement.
 * @dev    Remember to set the url, oracleAddress and jobId
 *         If there are multiple oracle providers in the future, this contract may need to be updated.
 */
contract FlightOracle is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    IPolicyFlow public policyFlow;

    address public oracleAddress;
    bytes32 public jobId;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event OracleAddressChanged(address newOracle);
    event JobIdChanged(bytes32 newJobId);
    event PolicyFlowChanged(address newPolicyFlow);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Need the address of LINK token on specific network
     */
    constructor(address _policyFlow, address _link) Ownable(msg.sender) {
        policyFlow = IPolicyFlow(_policyFlow);

        setChainlinkToken(_link);

        oracleAddress = 0x7D9398979267a6E050FbFDFff953Fc612A5aD4C9;
        jobId = "bcc0a699531940479bc93cf9fa5afb3f";
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Only the policyFlow can call some functions
    modifier onlyPolicyFlow() {
        require(
            msg.sender == address(policyFlow),
            "Only the policyflow can call this function"
        );
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Returns the address of the LINK token
     * @dev This is the public implementation for chainlinkTokenAddress, which is
     *      an internal method of the ChainlinkClient contract
     */
    function getChainlinkTokenAddress() external view returns (address) {
        return chainlinkTokenAddress();
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set the oracle address
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        oracleAddress = _newOracle;
        emit OracleAddressChanged(_newOracle);
    }

    /**
     * @notice Set a new job id
     */
    function setJobId(bytes32 _newJobId) external onlyOwner {
        jobId = _newJobId;
        emit JobIdChanged(_newJobId);
    }

    /**
     * @notice Change the policy flow contract address
     */
    function setPolicyFlow(address _policyFlow) external onlyOwner {
        policyFlow = IPolicyFlow(_policyFlow);
        emit PolicyFlowChanged(_policyFlow);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Creates a request to the specified Oracle contract address
     * @dev This function ignores the stored Oracle contract address and
     *      will instead send the request to the address specified
     * @param _payment Payment to the oracle
     * @param _url The URL to fetch data from
     * @param _path The dot-delimited path to parse of the response
     * @param _times The number to multiply the result by
     */
    function newOracleRequest(
        uint256 _payment,
        string memory _url,
        string memory _path,
        int256 _times
    ) public onlyPolicyFlow returns (bytes32) {
        require(
            oracleAddress != address(0) && jobId != 0,
            "Set the oracle address & jobId"
        );

        // Enough LINK token for payment
        require(
            LinkTokenInterface(chainlinkTokenAddress()).balanceOf(
                address(this)
            ) >= _payment,
            "Insufficient LINK balance"
        );

        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        req.add("url", _url);
        req.add("path", _path);
        req.addInt("times", _times);
        return sendChainlinkRequestTo(oracleAddress, req, _payment);
    }

    /**
     * @notice The fulfill method from requests created by this contract
     * @dev The recordChainlinkFulfillment protects this function from being called
     *      by anyone other than the oracle address that the request was sent to
     * @param _requestId The ID that was generated for the request
     * @param _data The answer provided by the oracle
     */
    function fulfill(bytes32 _requestId, uint256 _data)
        public
        recordChainlinkFulfillment(_requestId)
    {
        policyFlow.finalSettlement(_requestId, _data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "./StringsUtils.sol";

contract StringsUtilsTester {
    function byToString(bytes32 _bytes) public pure returns (string memory) {
        return StringsUtils.byToString(_bytes);
    }

    function addressToString(address _addr)
        public
        pure
        returns (string memory)
    {
        return StringsUtils.addressToString(_addr);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function uintToString(uint256 value) public pure returns (string memory) {
        return StringsUtils.uintToString(value);
    }

    function uintToHexString(uint256 value)
        public
        pure
        returns (string memory)
    {
        return StringsUtils.uintToHexString(value);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function uintToHexString(uint256 value, uint256 length)
        public
        pure
        returns (string memory)
    {
        return StringsUtils.uintToHexString(value, length);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../utils/Ownable.sol";
import "../lucky-box/interfaces/IDegisLottery.sol";
import "../libraries/StringsUtils.sol";

contract VRFMock is Ownable {
    using StringsUtils for uint256;

    IDegisLottery public DegisLottery;

    uint256 public seed;

    uint256 public randomResult;

    uint256 public latestLotteryId;

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Set the address for the DegisLottery
     * @param _degisLottery address of the PancakeSwap lottery
     */
    function setLotteryAddress(address _degisLottery) external onlyOwner {
        DegisLottery = IDegisLottery(_degisLottery);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Request randomness from Chainlink VRF
     */
    function getRandomNumber() external {
        require(
            _msgSender() == address(DegisLottery) || _msgSender() == owner(),
            "Only DegisLottery"
        );

        randomResult = (_rand(++seed) % 10000) + 10000;

        latestLotteryId = IDegisLottery(DegisLottery).currentLotteryId();
    }

    function _rand(uint256 _input) internal pure returns (uint256) {
        return _input * 12345;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../utils/Ownable.sol";
import "../libraries/StringsUtils.sol";

contract PriceFeedMock is Ownable {
    using StringsUtils for uint256;

    struct PriceFeedInfo {
        address priceFeedAddress;
        uint256 decimals;
    }
    // Use token name (string) as the mapping key
    mapping(string => PriceFeedInfo) public priceFeedInfo;

    uint256 public roundId;

    uint256 public result;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //
    event PriceFeedChanged(
        string tokenName,
        address feedAddress,
        uint256 decimals
    );

    event LatestPriceGet(uint256 roundID, uint256 price);

    constructor() Ownable(msg.sender) {}

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Main Functions *********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @dev For test, you can set the result you want
     */
    function setResult(uint256 _result) public {
        result = _result;
    }

    /**
     * @notice Get latest price of a token
     * @param _tokenName Address of the token
     * @return price The latest price
     */
    function getLatestPrice(string memory _tokenName) public returns (uint256) {
        uint256 price = result;

        // require(price > 0, "Only accept price that > 0");
        if (price < 0) price = 0;

        emit LatestPriceGet(roundId, price);

        roundId += 1;

        uint256 finalPrice = uint256(price);

        return finalPrice;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBuyerToken} from "../tokens/interfaces/IBuyerToken.sol";
import {INaughtyPair} from "./interfaces/INaughtyPair.sol";
import {INaughtyFactory} from "./interfaces/INaughtyFactory.sol";
import {IPolicyCore} from "./interfaces/IPolicyCore.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20Decimals} from "../utils/interfaces/IERC20Decimals.sol";

/**
 * @title  NaughtyRouter
 * @notice Router for the pool, you can add/remove liquidity or swap A for B.
 *         Swapping fee rate is 2% and all of them are given to LP.
 *         Very similar logic with Uniswap V2.
 *
 */
contract NaughtyRouter is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeERC20 for INaughtyPair;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Some other contracts
    address public factory;
    address public policyCore;
    address public buyerToken;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event PolicyCoreChanged(address oldPolicyCore, address newPolicyCore);

    event BuyerTokenChanged(address oldBuyerToken, address newBuyerToken);

    event LiquidityAdded(
        address indexed pairAddress,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event LiquidityRemoved(
        address indexed pairAddress,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(address _factory, address _buyerToken)
        public
        initializer
    {
        __Ownable_init();

        factory = _factory;
        buyerToken = _buyerToken;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Transactions are available only before the deadline
     * @param _deadLine Deadline of the pool
     */
    modifier beforeDeadline(uint256 _deadLine) {
        if (msg.sender != INaughtyFactory(factory).incomeMaker()) {
            require(block.timestamp < _deadLine, "expired transaction");
        }
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set the address of policyCore
     * @param _coreAddress Address of new policyCore
     */
    function setPolicyCore(address _coreAddress) external onlyOwner {
        emit PolicyCoreChanged(policyCore, _coreAddress);
        policyCore = _coreAddress;
    }

    /**
     * @notice Set the address of buyer token
     * @param _buyerToken Address of new buyer token
     */
    function setBuyerToken(address _buyerToken) external onlyOwner {
        emit BuyerTokenChanged(buyerToken, _buyerToken);
        buyerToken = _buyerToken;
    }

    /**
     * @notice Set the address of factory
     * @param _naughtyFactory Address of new naughty factory
     */
    function setNaughtyFactory(address _naughtyFactory) external onlyOwner {
        emit BuyerTokenChanged(factory, _naughtyFactory);
        factory = _naughtyFactory;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Helper Functions *********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Add liquidity but only provide stablecoins
     * @dev Only difference with addLiquidity is that mintPolicyTokenForUser
     * @param _tokenA Address of policyToken
     * @param _tokenB Address of stablecoin
     * @param _amountADesired Amount of policyToken desired
     * @param _amountBDesired Amount of stablecoin desired
     * @param _amountAMin Minimum amount of policy token
     * @param _amountBMin Minimum amount of stablecoin
     * @param _to Address that receive the lp token, normally the user himself
     * @param _deadline Transaction will revert after this deadline
     */
    function addLiquidityWithUSD(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        external
        beforeDeadline(_deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        require(_checkStablecoin(_tokenB), "Token B should be stablecoin");

        // Mint _amountADesired policy tokens for users
        _mintPolicyTokensForUser(
            _tokenA,
            _tokenB,
            _amountADesired,
            _msgSender()
        );

        // Add liquidity
        {
            (amountA, amountB, liquidity) = addLiquidity(
                _tokenA,
                _tokenB,
                _amountADesired,
                _amountBDesired,
                _amountAMin,
                _amountBMin,
                _to,
                _deadline
            );
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Add liquidity function
     * @param _tokenA Address of policyToken
     * @param _tokenB Address of stablecoin
     * @param _amountADesired Amount of policyToken desired
     * @param _amountBDesired Amount of stablecoin desired
     * @param _amountAMin Minimum amoutn of policy token
     * @param _amountBMin Minimum amount of stablecoin
     * @param _to Address that receive the lp token, normally the user himself
     * @param _deadline Transaction will revert after this deadline
     * @return amountA Amount of tokenA to be input
     * @return amountB Amount of tokenB to be input
     * @return liquidity LP token to be mint
     */
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        public
        beforeDeadline(_deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        {
            (amountA, amountB) = _addLiquidity(
                _tokenA,
                _tokenB,
                _amountADesired,
                _amountBDesired,
                _amountAMin,
                _amountBMin
            );
        }

        address pair = INaughtyFactory(factory).getPairAddress(
            _tokenA,
            _tokenB
        );

        _transferHelper(_tokenA, _msgSender(), pair, amountA);
        _transferHelper(_tokenB, _msgSender(), pair, amountB);

        liquidity = INaughtyPair(pair).mint(_to);

        emit LiquidityAdded(pair, amountA, amountB, liquidity);
    }

    /**
     * @notice Remove liquidity from the pool
     * @param _tokenA Address of policy token
     * @param _tokenB Address of stablecoin
     * @param _liquidity The lptoken amount to be removed
     * @param _amountAMin Minimum amount of tokenA given out
     * @param _amountBMin Minimum amount of tokenB given out
     * @param _to User address
     * @param _deadline Deadline of this transaction
     * @return amountA Amount of token0 given out
     * @return amountB Amount of token1 given out
     */
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        public
        beforeDeadline(_deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        address pair = INaughtyFactory(factory).getPairAddress(
            _tokenA,
            _tokenB
        );

        INaughtyPair(pair).safeTransferFrom(_msgSender(), pair, _liquidity); // send liquidity to pair

        // Amount0: insurance token
        (amountA, amountB) = INaughtyPair(pair).burn(_to);

        require(amountA >= _amountAMin, "Insufficient insurance token amount");
        require(amountB >= _amountBMin, "Insufficient USDT token");

        emit LiquidityRemoved(pair, amountA, amountB, _liquidity);
    }

    /**
     * @notice Amount out is fixed
     * @param _amountInMax Maximum token input
     * @param _amountOut Fixed token output
     * @param _tokenIn Address of input token
     * @param _tokenOut Address of output token
     * @param _to User address
     * @param _deadline Deadline for this specific swap
     * @return amountIn Amounts to be really put in
     */
    function swapTokensforExactTokens(
        uint256 _amountInMax,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        address _to,
        uint256 _deadline
    ) external beforeDeadline(_deadline) returns (uint256 amountIn) {
        address pair = INaughtyFactory(factory).getPairAddress(
            _tokenIn,
            _tokenOut
        );
        require(
            block.timestamp <= INaughtyPair(pair).deadline(),
            "This pool has been frozen for swapping"
        );

        bool isBuying = _checkStablecoin(_tokenIn);

        uint256 feeRate = INaughtyPair(pair).feeRate();

        // Get how many tokens should be put in (the order depends on isBuying)
        amountIn = _getAmountIn(
            isBuying,
            _amountOut,
            _tokenIn,
            _tokenOut,
            feeRate
        );

        require(amountIn <= _amountInMax, "excessive input amount");

        _transferHelper(_tokenIn, _msgSender(), pair, amountIn);

        _swap(pair, _tokenIn, amountIn, _amountOut, isBuying, _to);
    }

    /**
     * @notice Amount in is fixed
     * @param _amountIn Fixed token input
     * @param _amountOutMin Minimum token output
     * @param _tokenIn Address of input token
     * @param _tokenOut Address of output token
     * @param _to User address
     * @param _deadline Deadline for this specific swap
     * @return amountOut Amounts to be really given out
     */
    function swapExactTokensforTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _tokenIn,
        address _tokenOut,
        address _to,
        uint256 _deadline
    ) external beforeDeadline(_deadline) returns (uint256 amountOut) {
        address pair = INaughtyFactory(factory).getPairAddress(
            _tokenIn,
            _tokenOut
        );
        require(
            block.timestamp <= INaughtyPair(pair).deadline(),
            "This pool has been frozen for swapping"
        );

        // Check if the tokenIn is stablecoin
        bool isBuying = _checkStablecoin(_tokenIn);

        uint256 feeRate = INaughtyPair(pair).feeRate();

        // Get how many tokens should be given out (the order depends on isBuying)
        amountOut = _getAmountOut(
            isBuying,
            _amountIn,
            _tokenIn,
            _tokenOut,
            feeRate
        );
        require(amountOut >= _amountOutMin, "excessive output amount");

        _transferHelper(_tokenIn, _msgSender(), pair, _amountIn);

        _swap(pair, _tokenIn, _amountIn, amountOut, isBuying, _to);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Internal function to finish adding liquidity
     * @param _tokenA Address of tokenA
     * @param _tokenB Address of tokenB
     * @param _amountADesired Amount of tokenA to be added
     * @param _amountBDesired Amount of tokenB to be added
     * @param _amountAMin Minimum amount of tokenA
     * @param _amountBMin Minimum amount of tokenB
     * @return amountA Real amount of tokenA
     * @return amountB Real amount of tokenB
     */
    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) private view returns (uint256 amountA, uint256 amountB) {
        require(_checkStablecoin(_tokenB), "Please put stablecoin as tokenB");

        (uint256 reserveA, uint256 reserveB) = _getReserves(_tokenA, _tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (_amountADesired, _amountBDesired);
        } else {
            uint256 amountBOptimal = _quote(
                _amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= _amountBDesired) {
                require(amountBOptimal >= _amountBMin, "INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (_amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = _quote(
                    _amountBDesired,
                    reserveB,
                    reserveA
                );
                require(amountAOptimal <= _amountADesired, "nonono");
                require(amountAOptimal >= _amountAMin, "INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, _amountBDesired);
            }
        }
    }

    /**
     * @notice Finish the erc20 transfer operation
     * @param _token ERC20 token address
     * @param _from Address to give out the token
     * @param _to Pair address to receive the token
     * @param _amount Transfer amount
     */
    function _transferHelper(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }

    /**
     * @notice Finish swap process
     * @param _pair Address of the pair
     * @param _tokenIn Address of the input token
     * @param _amountIn Amount of tokens put in
     * @param _amountOut Amount of tokens get out
     * @param _isBuying Whether this is a purchase or a sell
     * @param _to Address of the user
     */
    function _swap(
        address _pair,
        address _tokenIn,
        uint256 _amountIn,
        uint256 _amountOut,
        bool _isBuying,
        address _to
    ) internal {
        // Only give buyer tokens when this is a purchase
        if (_isBuying) {
            // Check the decimals
            uint256 decimals = IERC20Decimals(_tokenIn).decimals();
            uint256 buyerTokenAmount = _amountIn * 10**(18 - decimals);
            IBuyerToken(buyerToken).mintBuyerToken(
                _msgSender(),
                buyerTokenAmount
            );
        }

        // If the user is buying policies => amount1Out = 0
        // One of these two variables will be 0
        uint256 amountAOut = _isBuying ? _amountOut : 0;
        uint256 amountBOut = _isBuying ? 0 : _amountOut;

        INaughtyPair(_pair).swap(amountAOut, amountBOut, _to);
    }

    /**
     * @notice Used when users only provide stablecoins and want to mint & add liquidity in one step
     * @dev Need have approval before (done by the user himself)
     * @param _policyTokenAddress Address of the policy token
     * @param _stablecoin Address of the stablecoin
     * @param _amount Amount to be used for minting policy tokens
     * @param _user The user's address
     */
    function _mintPolicyTokensForUser(
        address _policyTokenAddress,
        address _stablecoin,
        uint256 _amount,
        address _user
    ) internal {
        // Find the policy token name
        string memory policyTokenName = IPolicyCore(policyCore)
            .findNamebyAddress(_policyTokenAddress);

        IPolicyCore(policyCore).delegateDeposit(
            policyTokenName,
            _stablecoin,
            _amount,
            _user
        );
    }

    function _checkStablecoin(address _tokenAddress)
        internal
        view
        returns (bool)
    {
        return IPolicyCore(policyCore).supportedStablecoin(_tokenAddress);
    }

    /**
     * @notice Fetche the reserves for a pair
     * @dev You need to sort the token order by yourself!
     *      No matter your input order, the return value will always start with policy token reserve.
     */
    function _getReserves(address tokenA, address tokenB)
        internal
        view
        returns (uint112 reserveA, uint112 reserveB)
    {
        address pairAddress = INaughtyFactory(factory).getPairAddress(
            tokenA,
            tokenB
        );

        // (Policy token reserve, stablecoin reserve)
        (reserveA, reserveB) = INaughtyPair(pairAddress).getReserves();
    }

    /**
     * @notice Used when swap exact tokens for tokens (in is fixed)
     * @param isBuying Whether the user is buying policy tokens
     * @param _amountIn Amount of tokens put in
     * @param _tokenIn Address of the input token
     * @param _tokenOut Address of the output token
     */
    function _getAmountOut(
        bool isBuying,
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _feeRate
    ) internal view returns (uint256 amountOut) {
        (uint256 reserveA, uint256 reserveB) = _getReserves(
            _tokenIn,
            _tokenOut
        );

        // If tokenIn is stablecoin (isBuying), then tokeIn should be tokenB
        // Get the right order
        (uint256 reserveIn, uint256 reserveOut) = isBuying
            ? (reserveB, reserveA)
            : (reserveA, reserveB);

        require(_amountIn > 0, "insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "insufficient liquidity");

        uint256 amountInWithFee = _amountIn * (1000 - _feeRate);
        uint256 numerator = amountInWithFee * (reserveOut);
        uint256 denominator = reserveIn * 1000 + amountInWithFee;

        amountOut = numerator / denominator;
    }

    /**
     * @notice Used when swap tokens for exact tokens (out is fixed)
     * @param isBuying Whether the user is buying policy tokens
     * @param _amountOut Amount of tokens given out
     * @param _tokenIn Address of the input token
     * @param _tokenOut Address of the output token
     */
    function _getAmountIn(
        bool isBuying,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        uint256 _feeRate
    ) internal view returns (uint256 amountIn) {
        (uint256 reserveA, uint256 reserveB) = _getReserves(
            _tokenIn,
            _tokenOut
        );
        // If tokenIn is stablecoin (isBuying), then tokeIn should be tokenB
        // Get the right order
        (uint256 reserveIn, uint256 reserveOut) = isBuying
            ? (reserveB, reserveA)
            : (reserveA, reserveB);

        require(_amountOut > 0, "insufficient output amount");
        require(reserveIn > 0 && reserveOut > 0, "insufficient liquidity");

        uint256 numerator = reserveIn * (_amountOut) * 1000;
        uint256 denominator = (reserveOut - _amountOut) * (1000 - _feeRate);

        amountIn = numerator / denominator + 1;
    }

    /**
     * @notice Given some amount of an asset and pair reserves
     *         returns an equivalent amount of the other asset
     * @dev Used when add or remove liquidity
     * @param _amountA Amount of tokenA ( can be policytoken or stablecoin)
     * @param _reserveA Reserve of tokenA
     * @param _reserveB Reserve of tokenB
     */
    function _quote(
        uint256 _amountA,
        uint256 _reserveA,
        uint256 _reserveB
    ) internal pure returns (uint256 amountB) {
        require(_amountA > 0, "insufficient amount");
        require(_reserveA > 0 && _reserveB > 0, "insufficient liquidity");

        amountB = (_amountA * _reserveB) / _reserveA;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INaughtyPair is IERC20 {
    function initialize(
        address _token0,
        address _token1,
        uint256 _deadline,
        uint256 _feeRate
    ) external;

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function feeRate() external view returns (uint256);

    function deadline() external view returns (uint256);

    function getReserves()
        external
        view
        returns (uint112 _reserve0, uint112 _reserve1);

    function swap(
        uint256,
        uint256,
        address
    ) external;

    function burn(address) external returns (uint256, uint256);

    function mint(address) external returns (uint256);

    function sync() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IPolicyCore {
    struct PolicyTokenInfo {
        address policyTokenAddress;
        bool isCall;
        uint256 nameDecimals; // decimals of the name generation
        uint256 tokenDecimals; // decimals of the policy token
        uint256 strikePrice;
        uint256 deadline;
        uint256 settleTimestamp;
    }

    /**
     * @notice Find the address by its name
     */
    function findAddressbyName(string memory _policyTokenName)
        external
        view
        returns (address _policyTokenAddress);

    /**
     * @notice Find the name by address
     */
    function findNamebyAddress(address _policyTokenAddress)
        external
        view
        returns (string memory);

    /**
     * @notice Check whether the stablecoin is supported
     */
    function supportedStablecoin(address _coinAddress)
        external
        view
        returns (bool);

    function delegateDeposit(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _amount,
        address _user
    ) external;

    function deployPool(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _poolDeadline,
        uint256 _feeRate
    ) external returns (address);

    function getPolicyTokenInfo(string memory _policyTokenName)
        external
        view
        returns (PolicyTokenInfo memory);

    function updateUserQuota(
        address _user,
        address _policyToken,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Decimals} from "../utils/interfaces/IERC20Decimals.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IPolicyCore} from "../naughty-price/interfaces/IPolicyCore.sol";
import {INaughtyRouter} from "../naughty-price/interfaces/INaughtyRouter.sol";
import {INaughtyPair} from "../naughty-price/interfaces/INaughtyPair.sol";
import {ILMToken as LPToken} from "./ILMToken.sol";

/**
 * @title Naughty Price Initial Liquidity Matching
 * @notice Naughty Price timeline: 1 -- 14 -- 5
 *         The first day of each round would be the time for liquidity matching
 *         User
 *           - Select the naughty token
 *           - Provide stablecoins into this contract & Select your price choice
 *           - Change the amountA and amountB of this pair
 *         When reach deadline
 *           - Final price of ILM = Initial price of naughty price pair = amountA/amountB
 */
contract NaughtyPriceILM is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Scale when calculating fee
    uint256 public constant SCALE = 1e12;

    // Degis entrance fee = 1 / 100 deposit amount
    uint256 public constant FEE_DENOMINATOR = 100;

    // Minimum deposit amount
    uint256 public constant MINIMUM_AMOUNT = 1e6;

    // Uint256 maximum value
    uint256 public constant MAX_UINT256 = type(uint256).max;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Degis token address
    address public degis;

    // PolicyCore, Router and EmergencyPool contract address
    address public policyCore;
    address public router;
    address public emergencyPool;

    struct UserInfo {
        uint256 amountA;
        uint256 amountB;
        uint256 degisDebt;
    }
    // user address => policy token address => user info
    mapping(address => mapping(address => UserInfo)) public users;

    // Status of an ILM round
    enum Status {
        BeforeStart,
        Active,
        Finished,
        Stopped
    }

    struct PairInfo {
        Status status; // 0: before start 1: active 2: finished 3: stopped
        address lptoken; // lptoken address
        uint256 ILMDeadline; // deadline for initial liquidity matching
        address stablecoin; // stablecoin address
        uint256 amountA; // Amount of policy tokens
        uint256 amountB; // Amount of stablecoins
        address naughtyPairAddress; // Naughty pair address deployed when finished ILM
        // degis paid as fee
        uint256 degisAmount;
        uint256 accDegisPerShare;
    }
    // Policy Token Address => Pair Info
    mapping(address => PairInfo) public pairs;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event Deposit(
        address indexed policyToken,
        address indexed stablecoin,
        uint256 amountA,
        uint256 amountB
    );
    event Withdraw(
        address indexed policyToken,
        address indexed stablecoin,
        address indexed user,
        uint256 amountA,
        uint256 amountB
    );
    event EmergencyWithdraw(address owner, uint256 amount);
    event ILMFinish(
        address policyToken,
        address stablecoin,
        address poolAddress,
        uint256 amountA,
        uint256 amountB
    );
    event ILMStart(
        address policyToken,
        address stablecoin,
        uint256 deadline,
        address lptokenAddress
    );
    event Harvest(address user, uint256 reward);
    event Claim(address user, uint256 amountA, uint256 amountB);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error ILM__WrongILMDeadline();
    error ILM__ZeroAddress();
    error ILM__RoundOver();
    error ILM__PairNotActive();
    error ILM__RoundNotOver();
    error ILM__ZeroAmount();
    error ILM__NotActiveILM();
    error ILM__StablecoinNotPaired();
    error ILM__StablecoinNotSupport();
    error ILM__NoDeposit();
    error ILM__NotEnoughDeposit();

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Initialze function for proxy
     * @dev Called only when deploying proxy contract
     * @param _degis Degis token address
     * @param _policyCore PolicyCore contract address
     * @param _router NaughtyRouter contract address
     * @param _emergencyPool EmergencyPool contract address
     */
    function initialize(
        address _degis,
        address _policyCore,
        address _router,
        address _emergencyPool
    ) public initializer {
        if (_policyCore == address(0) || _router == address(0))
            revert ILM__ZeroAddress();

        __Ownable_init();

        degis = _degis;
        policyCore = _policyCore;
        router = _router;

        emergencyPool = _emergencyPool;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check whether a pair is active
     * @param _policyToken Policy token address
     */
    modifier activePair(address _policyToken) {
        if (pairs[_policyToken].status != Status.Active)
            revert ILM__PairNotActive();
        _;
    }

    /**
     * @notice Check whether is during ILM
     * @param _policyToken Policy token address
     */
    modifier duringILM(address _policyToken) {
        if (block.timestamp > pairs[_policyToken].ILMDeadline)
            revert ILM__RoundOver();
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get the current price
     * @dev Price has a scale of 1e12
     * @param _policyToken Policy token address
     * @return price Price of the token pair
     */
    function getPrice(address _policyToken) external view returns (uint256) {
        uint256 amountA = pairs[_policyToken].amountA;
        uint256 amountB = pairs[_policyToken].amountB;
        return (amountB * SCALE) / amountA;
    }

    /**
     * @notice Get the total amount of a pair
     * @param _policyToken Policy token address
     * @return totalAmount Total amount of a pair
     */
    function getPairTotalAmount(address _policyToken)
        external
        view
        returns (uint256 totalAmount)
    {
        totalAmount = pairs[_policyToken].amountA + pairs[_policyToken].amountB;
    }

    /**
     * @notice Get the amount of user's deposit
     * @param _user User address
     * @param _policyToken Policy token address
     */
    function getUserDeposit(address _user, address _policyToken)
        external
        view
        returns (uint256 amountA, uint256 amountB)
    {
        amountA = users[_user][_policyToken].amountA;
        amountB = users[_user][_policyToken].amountB;
    }

    /**
     * @notice Emergency stop ILM
     * @param _policyToken Policy token address to be stopped
     */
    function emergencyStop(address _policyToken) external onlyOwner {
        pairs[_policyToken].status = Status.Stopped;
    }

    /**
     * @notice Emergency restart ILM
     * @param _policyToken Policy token address to be restarted
     */
    function emergencyRestart(address _policyToken) external onlyOwner {
        pairs[_policyToken].status = Status.Active;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Start a new ILM round
     * @dev A new lp token will be deployed when starting a new ILM round
     *      It will have a special farming reward pool
     * @param _policyToken Policy token address
     * @param _stablecoin Stablecoin address
     * @param _ILMDeadline Deadline of ILM period
     */
    function startILM(
        address _policyToken,
        address _stablecoin,
        uint256 _ILMDeadline
    ) external onlyOwner {
        // Get policy token name & Check if this policy token exists
        // The check is inside policy core contract
        string memory policyTokenName = IPolicyCore(policyCore)
            .findNamebyAddress(_policyToken);

        // Check if the stablecoin is supported
        bool isSupported = IPolicyCore(policyCore).supportedStablecoin(
            _stablecoin
        );
        if (!isSupported) revert ILM__StablecoinNotSupport();

        // The deadline for ILM can not be later than the policy token deadline
        uint256 policyTokenDeadline = (
            IPolicyCore(policyCore).getPolicyTokenInfo(policyTokenName)
        ).deadline;
        if (_ILMDeadline >= policyTokenDeadline) revert ILM__WrongILMDeadline();

        PairInfo storage pair = pairs[_policyToken];
        // Update the status
        pair.status = Status.Active;
        pair.stablecoin = _stablecoin;
        pair.ILMDeadline = _ILMDeadline;

        // Deploy a new ERC20 LP Token
        string memory LPTokenName = string(
            abi.encodePacked("ILM-", policyTokenName)
        );
        address lpTokenAddress = _deployLPToken(LPTokenName);

        // Record the lptoken address
        pair.lptoken = lpTokenAddress;

        // Pre-approve the stablecoin for later deposit
        IERC20(_policyToken).approve(router, MAX_UINT256);

        emit ILMStart(_policyToken, _stablecoin, _ILMDeadline, lpTokenAddress);
    }

    /**
     * @notice Finish a round of ILM
     * @dev The swap pool for the protection token will be deployed with inital liquidity\
     *      The amount of initial liquidity will be the total amount of the pair
     *      Can be called by any address
     * @param _policyToken Policy token address
     * @param _deadlineForSwap Pool deadline
     * @param _feeRate Fee rate of the swap pool
     */
    function finishILM(
        address _policyToken,
        uint256 _deadlineForSwap,
        uint256 _feeRate
    ) external activePair(_policyToken) {
        PairInfo memory pair = pairs[_policyToken];

        // Pair status is 1 and passed deadline => can finish ILM
        if (block.timestamp <= pair.ILMDeadline) revert ILM__RoundNotOver();
        if (pair.amountA + pair.amountB == 0) revert ILM__NoDeposit();

        // Update the status of this pair
        pairs[_policyToken].status = Status.Finished;

        // Get policy token name
        string memory policyTokenName = IPolicyCore(policyCore)
            .findNamebyAddress(_policyToken);

        // Deploy a new pool and return the pool address
        address poolAddress = IPolicyCore(policyCore).deployPool(
            policyTokenName,
            pair.stablecoin,
            _deadlineForSwap,
            _feeRate // maximum = 1000 = 100%
        );
        pairs[_policyToken].naughtyPairAddress = poolAddress;

        // Approval prepration for withdraw liquidity
        INaughtyPair(poolAddress).approve(router, MAX_UINT256);

        // Add initial liquidity to the pool
        // Zero slippage
        INaughtyRouter(router).addLiquidityWithUSD(
            _policyToken,
            pair.stablecoin,
            pair.amountA,
            pair.amountB,
            pair.amountA,
            pair.amountB,
            address(this),
            block.timestamp + 60
        );

        emit ILMFinish(
            _policyToken,
            pair.stablecoin,
            poolAddress,
            pair.amountA,
            pair.amountB
        );
    }

    /**
     * @notice Deposit stablecoin and choose the price
     * @dev Deposit only check the pair status not the deadline
     *      There may be a zero ILM and we still need to deposit some asset to make it start
     *      Anyone wants to enter ILM need to pay some DEG as entrance fee
     *      The ratio is 100:1(usd:deg) and your fee is distributed to the users prior to you
     * @param _policyToken Policy token address
     * @param _stablecoin Stablecoin address
     * @param _amountA Amount of policy token (virtual)
     * @param _amountB Amount of stablecoin (virtual)
     */
    function deposit(
        address _policyToken,
        address _stablecoin,
        uint256 _amountA,
        uint256 _amountB
    ) external activePair(_policyToken) {
        if (_amountA + _amountB < MINIMUM_AMOUNT) revert ILM__ZeroAmount();
        if (_stablecoin != pairs[_policyToken].stablecoin)
            revert ILM__StablecoinNotPaired();

        uint256 amountToDeposit = _amountA + _amountB;

        // Every 100usd pay 1 degis
        uint256 decimalDiff = 18 - IERC20Decimals(_stablecoin).decimals();
        uint256 degisToPay = (amountToDeposit * 10**decimalDiff) /
            FEE_DENOMINATOR;

        // Update the info about deg entrance fee when deposit
        _updateWhenDeposit(
            _policyToken,
            amountToDeposit,
            degisToPay,
            decimalDiff
        );

        PairInfo storage pair = pairs[_policyToken];
        UserInfo storage user = users[msg.sender][_policyToken];

        // Update deg record and transfer degis token
        pair.degisAmount += degisToPay;
        IERC20(degis).safeTransferFrom(msg.sender, address(this), degisToPay);

        // Update the status
        pair.amountA += _amountA;
        pair.amountB += _amountB;
        user.amountA += _amountA;
        user.amountB += _amountB;

        // Transfer tokens
        IERC20(_stablecoin).safeTransferFrom(
            msg.sender,
            address(this),
            amountToDeposit
        );

        // Distribute the lptoken
        address lpToken = pairs[_policyToken].lptoken;
        LPToken(lpToken).mint(msg.sender, amountToDeposit);

        emit Deposit(_policyToken, _stablecoin, _amountA, _amountB);
    }

    /**
     * @notice Withdraw stablecoins
     * @dev Only checks the status not the deadline
     * @param _policyToken Policy token address
     * @param _stablecoin Stablecoin address
     * @param _amountA Amount of policy token (virtual)
     * @param _amountB Amount of stablecoin (virtual)
     */
    function withdraw(
        address _policyToken,
        address _stablecoin,
        uint256 _amountA,
        uint256 _amountB
    ) public activePair(_policyToken) {
        UserInfo memory currentUserInfo = users[msg.sender][_policyToken];

        // Check if the user has enough tokens to withdraw
        if (currentUserInfo.amountA + currentUserInfo.amountB == 0)
            revert ILM__NoDeposit();
        if (
            _amountA > currentUserInfo.amountA ||
            _amountB > currentUserInfo.amountB
        ) revert ILM__NotEnoughDeposit();

        PairInfo storage pair = pairs[_policyToken];
        UserInfo storage user = users[msg.sender][_policyToken];

        // Update status when withdraw
        uint256 degisToWithdraw = (pair.accDegisPerShare *
            (currentUserInfo.amountA + currentUserInfo.amountB)) /
            SCALE -
            currentUserInfo.degisDebt;

        if (degisToWithdraw > 0) {
            // Degis will be withdrawed to emergency pool, not the user
            uint256 reward = _safeTokenTransfer(
                degis,
                emergencyPool,
                degisToWithdraw
            );
            emit Harvest(emergencyPool, reward);
        }

        // Update the user's amount and pool's amount
        pair.amountA -= _amountA;
        pair.amountB -= _amountB;
        user.amountA -= _amountA;
        user.amountB -= _amountB;

        uint256 amountToWithdraw = _amountA + _amountB;

        // Withdraw stablecoins to the user
        _safeTokenTransfer(_stablecoin, msg.sender, amountToWithdraw);

        // Burn the lptokens
        LPToken(pair.lptoken).burn(msg.sender, amountToWithdraw);

        // Update the user debt
        user.degisDebt =
            ((user.amountA + user.amountB) * pair.accDegisPerShare) /
            SCALE;

        emit Withdraw(
            _policyToken,
            _stablecoin,
            msg.sender,
            _amountA,
            _amountB
        );
    }

    /**
     * @notice Withdraw all stablecoins of a certain policy token
     * @param _policyToken Policy token address
     * @param _stablecoin Stablecoin address
     */
    function withdrawAll(address _policyToken, address _stablecoin) external {
        uint256 amounAMax = users[msg.sender][_policyToken].amountA;
        uint256 amounBMax = users[msg.sender][_policyToken].amountB;

        withdraw(_policyToken, _stablecoin, amounAMax, amounBMax);
    }

    /**
     * @notice Claim liquidity back
     * @dev You will get back some DEG (depending on how many users deposit after you)
     *      The claim amount is determined by the LP Token balance of you (you can buy from others)
     *      But the DEG reward would only be got once
     *      Your LP token will be burnt and you can not join ILM farming pool again
     * @param _policyToken Policy token address
     * @param _stablecoin Stablecoin address
     * @param _amountAMin Minimum amount of policy token (slippage)
     * @param _amountBMin Minimum amount of stablecoin (slippage)
     */
    function claim(
        address _policyToken,
        address _stablecoin,
        uint256 _amount,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) external {
        if (_amount == 0) revert ILM__ZeroAmount();

        address naughtyPair = pairs[_policyToken].naughtyPairAddress;
        address lptoken = pairs[_policyToken].lptoken;

        uint256 lpBalance = LPToken(lptoken).balanceOf(msg.sender);
        uint256 lpToClaim = _amount > lpBalance ? lpBalance : _amount;

        // Total liquidity owned by the pool
        uint256 totalLiquidity = INaughtyPair(naughtyPair).balanceOf(
            address(this)
        );

        // User's liquidity amount
        uint256 userLiquidity = (lpToClaim * totalLiquidity) /
            LPToken(lptoken).totalSupply();

        _updateWhenClaim(_policyToken);

        // Remove liquidity
        (uint256 policyTokenAmount, uint256 stablecoinAmount) = INaughtyRouter(
            router
        ).removeLiquidity(
                _policyToken,
                _stablecoin,
                userLiquidity,
                _amountAMin,
                _amountBMin,
                msg.sender,
                block.timestamp + 60
            );

        // Update user quota
        IPolicyCore(policyCore).updateUserQuota(
            msg.sender,
            _policyToken,
            policyTokenAmount
        );

        // Burn the user's lp tokens
        LPToken(lptoken).burn(msg.sender, lpToClaim);

        emit Claim(msg.sender, policyTokenAmount, stablecoinAmount);
    }

    /**
     * @notice Emergency withdraw a certain token
     * @param _token Token address
     * @param _amount Token amount
     */
    function emergencyWithdraw(address _token, uint256 _amount) external {
        IERC20(_token).safeTransfer(owner(), _amount);

        emit EmergencyWithdraw(owner(), _amount);
    }

    /**
     * @notice Approve stablecoins for naughty price contracts
     * @param _stablecoin Stablecoin address
     */
    function approveStablecoin(address _stablecoin) external {
        IERC20(_stablecoin).approve(router, MAX_UINT256);
        IERC20(_stablecoin).approve(policyCore, MAX_UINT256);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Deploy the new lp token for a round
     * @param _name Name of the lp token
     * @return lpTokenAddress Address of the lp token
     */
    function _deployLPToken(string memory _name) internal returns (address) {
        address lpTokenAddress = address(
            new LPToken(address(this), _name, _name)
        );
        return lpTokenAddress;
    }

    /**
     * @notice Safely transfer tokens
     * @param _token Token address
     * @param _receiver Receiver address
     * @param _amount Amount of tokens
     * @return realAmount Real amount that is transferred
     */
    function _safeTokenTransfer(
        address _token,
        address _receiver,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 balance = IERC20(_token).balanceOf(address(this));

        if (_amount > balance) {
            IERC20(_token).safeTransfer(_receiver, balance);
            return balance;
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
            return _amount;
        }
    }

    /**
     * @notice Update debt & fee distribution
     * @param _policyToken Policy token address
     * @param _usdAmount Amount of stablecoins input
     * @param _degAmount Amount of degis input
     */
    function _updateWhenDeposit(
        address _policyToken,
        uint256 _usdAmount,
        uint256 _degAmount,
        uint256 _decimalDiff
    ) internal {
        PairInfo storage pair = pairs[_policyToken];

        // If this is the first user, accDegisPerShare = 1e16
        // No debt
        if (pair.degisAmount == 0) {
            pair.accDegisPerShare =
                (SCALE * 10**_decimalDiff) /
                FEE_DENOMINATOR;
            return;
        }

        UserInfo storage user = users[msg.sender][_policyToken];

        // Update accDegisPerShare first
        pair.accDegisPerShare +=
            (_degAmount * SCALE) /
            ((pair.amountA + pair.amountB));

        uint256 currentUserDeposit = user.amountA + user.amountB;
        // If user has deposited before, distribute the deg reward first
        // Pending reward is calculated with the new degisPerShare value
        if (currentUserDeposit > 0) {
            uint256 pendingReward = (currentUserDeposit *
                pair.accDegisPerShare) /
                SCALE -
                user.degisDebt;

            uint256 reward = _safeTokenTransfer(
                degis,
                msg.sender,
                pendingReward
            );
            emit Harvest(msg.sender, reward);
        }

        // Update user debt
        user.degisDebt =
            (pair.accDegisPerShare * (currentUserDeposit + _usdAmount)) /
            SCALE;
    }

    /**
     * @notice Update degis reward when claim
     * @param _policyToken Policy token address
     */
    function _updateWhenClaim(address _policyToken) internal {
        uint256 accDegisPerShare = pairs[_policyToken].accDegisPerShare;

        UserInfo storage user = users[msg.sender][_policyToken];

        uint256 userTotalDeposit = user.amountA + user.amountB;

        uint256 pendingReward = (userTotalDeposit * accDegisPerShare) /
            SCALE -
            user.degisDebt;

        if (pendingReward > 0) {
            // Update debt
            // Only get deg back when first time claim
            user.degisDebt = (userTotalDeposit * accDegisPerShare) / SCALE;

            uint256 reward = _safeTokenTransfer(
                degis,
                msg.sender,
                pendingReward
            );
            emit Harvest(msg.sender, reward);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

interface INaughtyRouter {
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityWithUSD(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensforTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _tokenIn,
        address _tokenOut,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ILMToken is ERC20 {
    address public ILMContract;

    constructor(
        address _ILM,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        ILMContract = _ILM;
    }

    modifier onlyILM() {
        require(msg.sender == ILMContract, "Only ILM");
        _;
    }

    function mint(address _to, uint256 _amount) public onlyILM {
        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) public onlyILM {
        _burn(_to, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.10;

import {Math} from "../libraries/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import {INaughtyFactory} from "./interfaces/INaughtyFactory.sol";

/**
 * @title  Naughty Pair
 * @notice This is the contract for the naughtyPrice swapping pair.
 *         Every time a new naughtyPrice product is online you need to deploy this contract.
 *         The contract will be initialized with two tokens and a deadline.
 *         Token0 will be policy tokens and token1 will be stablecoins.
 *         The swaps are only availale before the deadline.
 */
contract NaughtyPair is ERC20("Naughty Pool LP", "NLP"), ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Minimum liquidity locked
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    // naughtyFactory contract address
    address public factory;

    // Token addresses in the pool
    address public token0; // Insurance Token
    address public token1; // USDT

    uint112 private reserve0; // Amount of Insurance Token
    uint112 private reserve1; // Amount of USDT

    // Used for modifiers
    bool public unlocked = true;

    // Every pool will have a deadline
    uint256 public deadline;

    // Fee Rate, given to LP holders (0 ~ 1000)
    uint256 public feeRate;

    // reserve0 * reserve1
    uint256 public kLast;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event ReserveUpdated(uint256 reserve0, uint256 reserve1);
    event Swap(
        address indexed sender,
        uint256 amountAIn,
        uint256 amountBIn,
        uint256 amountAOut,
        uint256 amountBOut,
        address indexed to
    );

    event Mint(address indexed sender, uint256 amountA, uint256 amountB);
    event Burn(
        address indexed sender,
        uint256 amountA,
        uint256 amountB,
        address indexed to
    );

    constructor() {
        factory = msg.sender; // deployed by factory contract
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Can not swap after the deadline
     * @dev Each pool will have a deadline and it was set when deployed
     *      Does not apply to income maker contract
     */
    modifier beforeDeadline() {
        if (msg.sender != INaughtyFactory(factory).incomeMaker()) {
            require(block.timestamp <= deadline, "Can not swap after deadline");
        }
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Init Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Initialize the contract status after the deployment by factory
     * @param _token0 Token0 address (policy token address)
     * @param _token1 Token1 address (stablecoin address)
     * @param _deadline Deadline for this pool
     * @param _feeRate Fee rate to LP holders (1000 <=> 100%)
     */
    function initialize(
        address _token0,
        address _token1,
        uint256 _deadline,
        uint256 _feeRate
    ) external {
        require(
            msg.sender == factory,
            "can only be initialized by the factory contract"
        );
        require(_feeRate <= 1000, "feeRate over 1.0");

        token0 = _token0;
        token1 = _token1;

        // deadline for the whole pool after which no swap will be allowed
        deadline = _deadline;

        feeRate = _feeRate;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get reserve0 (Policy token) and reserve1 (stablecoin).
     * @dev This function always put policy token at the first place!
     * @return _reserve0 Reserve of token0
     * @return _reserve1 Reserve of token1
     */
    function getReserves()
        public
        view
        returns (uint112 _reserve0, uint112 _reserve1)
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Mint LP Token to liquidity providers
     *         Called when adding liquidity.
     * @param to The user address
     * @return liquidity The LP token amount
     */
    function mint(address to)
        external
        nonReentrant
        returns (uint256 liquidity)
    {
        (uint112 _reserve0, uint112 _reserve1) = getReserves(); // gas savings

        uint256 balance0 = IERC20(token0).balanceOf(address(this)); // policy token balance after deposit
        uint256 balance1 = IERC20(token1).balanceOf(address(this)); // stablecoin balance after deposit

        uint256 amount0 = balance0 - _reserve0; // just deposit
        uint256 amount1 = balance1 - _reserve1;

        // Distribute part of the fee to income maker
        bool feeOn = _mintFee(_reserve0, _reserve1);

        uint256 _totalSupply = totalSupply(); // gas savings
        if (_totalSupply == 0) {
            // No liquidity = First add liquidity
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // Keep minimum liquidity to this contract
            _mint(factory, MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = min(
                (amount0 * _totalSupply) / _reserve0,
                (amount1 * _totalSupply) / _reserve1
            );
        }

        require(liquidity > 0, "insufficient liquidity minted");
        _mint(to, liquidity);

        _update(balance0, balance1);

        if (feeOn) kLast = reserve0 * reserve1;

        emit Mint(msg.sender, amount0, amount1);
    }

    /**
     * @notice Burn LP tokens give back the original tokens
     * @param _to User address
     * @return amount0 Amount of token0 to be sent back
     * @return amount1 Amount of token1 to be sent back
     */
    function burn(address _to)
        external
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        // gas savings
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        address _token0 = token0;
        address _token1 = token1;

        uint256 balance0 = IERC20(_token0).balanceOf(address(this)); // policy token balance
        uint256 balance1 = IERC20(_token1).balanceOf(address(this)); // stablecoin balance

        uint256 liquidity = balanceOf(address(this));

        bool feeOn = _mintFee(_reserve0, _reserve1);

        uint256 _totalSupply = totalSupply(); // gas savings

        // How many tokens to be sent back
        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;

        require(amount0 > 0 && amount1 > 0, "Insufficient liquidity burned");

        // Currently all the liquidity in the pool was just sent by the user, so burn all
        _burn(address(this), liquidity);

        // Transfer tokens out and update the balance
        IERC20(_token0).safeTransfer(_to, amount0);
        IERC20(_token1).safeTransfer(_to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);

        if (feeOn) kLast = reserve0 * reserve1;

        emit Burn(msg.sender, amount0, amount1, _to);
    }

    /**
     * @notice Finish the swap process
     * @param _amount0Out Amount of token0 to be given out (may be 0)
     * @param _amount1Out Amount of token1 to be given out (may be 0)
     * @param _to Address to receive the swap result
     */
    function swap(
        uint256 _amount0Out,
        uint256 _amount1Out,
        address _to
    ) external beforeDeadline nonReentrant {
        require(
            _amount0Out > 0 || _amount1Out > 0,
            "Output amount need to be > 0"
        );

        (uint112 _reserve0, uint112 _reserve1) = getReserves(); // gas savings
        require(
            _amount0Out < _reserve0 && _amount1Out < _reserve1,
            "Not enough liquidity"
        );

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(_to != _token0 && _to != _token1, "INVALID_TO");

            if (_amount0Out > 0) IERC20(_token0).safeTransfer(_to, _amount0Out);
            if (_amount1Out > 0) IERC20(_token1).safeTransfer(_to, _amount1Out);

            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - _amount0Out
            ? balance0 - (_reserve0 - _amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - _amount1Out
            ? balance1 - (_reserve1 - _amount1Out)
            : 0;

        require(amount0In > 0 || amount1In > 0, "INSUFFICIENT_INPUT_AMOUNT");

        {
            uint256 balance0Adjusted = balance0 * 1000 - amount0In * feeRate;
            uint256 balance1Adjusted = balance1 * 1000 - amount1In * feeRate;

            require(
                balance0Adjusted * balance1Adjusted >=
                    _reserve0 * _reserve1 * (1000**2),
                "The remaining x*y is less than K"
            );
        }

        _update(balance0, balance1);

        emit Swap(
            msg.sender,
            amount0In,
            amount1In,
            _amount0Out,
            _amount1Out,
            _to
        );
    }

    /**
     * @notice Syncrinize the status of this pool
     */
    function sync() external nonReentrant {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
    }

    // ---------------------------------------------------------------------------------------- //
    // ********************************** Internal Functions ********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Update the reserves of the pool
     * @param balance0 Balance of token0
     * @param balance1 Balance of token1
     */
    function _update(uint256 balance0, uint256 balance1) private {
        uint112 MAX_NUM = type(uint112).max;
        require(balance0 <= MAX_NUM && balance1 <= MAX_NUM, "Uint112 OVERFLOW");

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);

        emit ReserveUpdated(reserve0, reserve1);
    }

    /**
     * @notice Get the smaller one of two numbers
     * @param x The first number
     * @param y The second number
     * @return z The smaller one
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1)
        private
        returns (bool feeOn)
    {
        address incomeMaker = INaughtyFactory(factory).incomeMaker();

        // If incomeMaker is not zero address, fee is on
        feeOn = incomeMaker != address(0);

        uint256 _k = kLast;

        if (feeOn) {
            if (_k != 0) {
                uint256 rootK = Math.sqrt(_reserve0 * _reserve1);
                uint256 rootKLast = Math.sqrt(_k);

                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply() *
                        (rootK - rootKLast) *
                        10;

                    // (1 / φ) - 1
                    // Proportion got from factory is based on 100
                    // Use 1000/proportion to make it divided (donominator and numerator both * 10)
                    // p = 40 (2/5) => 1000/40 = 25
                    uint256 incomeMakerProportion = INaughtyFactory(factory)
                        .incomeMakerProportion();
                    uint256 denominator = rootK *
                        (1000 / incomeMakerProportion - 10) +
                        rootKLast *
                        10;

                    uint256 liquidity = numerator / denominator;

                    // Mint the liquidity to income maker contract
                    if (liquidity > 0) _mint(incomeMaker, liquidity);
                }
            }
        } else if (_k != 0) {
            kLast = 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Math {
    uint256 internal constant WAD = 10**18;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: GPL-3.0-or-Later

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../naughty-price/interfaces/INaughtyRouter.sol";
import "../naughty-price/interfaces/INaughtyFactory.sol";
import "../naughty-price/interfaces/INaughtyPair.sol";

/**
 * @title Degis Maker Contract
 * @dev This contract will receive the transaction fee from swap pool
 *      Then it will transfer
 */
contract IncomeMaker is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    uint256 public constant UINT256_MAX = type(uint256).max;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    INaughtyRouter public router;

    INaughtyFactory public factory;

    address public incomeSharingVault;

    uint256 public PRICE_SCALE = 1e6;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event IncomeToUSD(
        address policyTokenAddress,
        address stablecoin,
        uint256 amountOut
    );
    event ConvertIncome(
        address caller,
        address policyTokenAddress,
        address stablecoin,
        uint256 policyTokenAmount, // Amount of policy token by burning lp tokens
        uint256 stablecoinAmount, // Amount of stablecoin by burning lp tokens
        uint256 stablecoinBackAmount // Amount of stablecoin by swapping policy tokens
    );
    event EmergencyWithdraw(address token, uint256 amount);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Initialize function
     * @param _router Address of the naughty router
     * @param _factory Address of the naughty factory
     * @param _vault Address of the income sharing vault
     */
    function initialize(
        address _router,
        address _factory,
        address _vault
    ) public initializer {
        __Ownable_init();

        router = INaughtyRouter(_router);
        factory = INaughtyFactory(_factory);

        incomeSharingVault = _vault;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Convert the income to stablecoin and transfer to the incomeSharingVault
     * @param _policyToken Address of the policy token
     * @param _stablecoin Address of the stablecoi
     */
    function convertIncome(address _policyToken, address _stablecoin) external {
        // Get the pair
        INaughtyPair pair = INaughtyPair(
            factory.getPairAddress(_policyToken, _stablecoin)
        );
        require(address(pair) != address(0), "Pair not exist");

        // Transfer lp token to the pool and get two tokens
        IERC20(address(pair)).safeTransfer(
            address(pair),
            pair.balanceOf(address(this))
        );

        // Directly call the pair to burn lp tokens
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));

        // Finish swap
        uint256 amountOut = _swap(
            _policyToken,
            _stablecoin,
            amount0,
            address(this)
        );

        // Transfer all stablecoins to income sharing vault
        IERC20(_stablecoin).safeTransfer(
            incomeSharingVault,
            IERC20(_stablecoin).balanceOf(address(this))
        );

        emit ConvertIncome(
            msg.sender,
            _policyToken,
            _stablecoin,
            amount0,
            amount1,
            amountOut
        );
    }

    /**
     * @notice Emergency withdraw by the owner
     * @param _token Address of the token
     * @param _amount Amount of the token
     */
    function emergencyWithdraw(address _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(_token, _amount);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Swap policy tokens to stablecoins
     * @param _policyToken Address of policy token
     * @param _stablecoin Address of stablecoin
     * @param _amount Amount of policy token
     * @param _to Address of the receiver
     */
    function _swap(
        address _policyToken,
        address _stablecoin,
        uint256 _amount,
        address _to
    ) internal returns (uint256 amountOut) {
        // Get the pair
        INaughtyPair pair = INaughtyPair(
            factory.getPairAddress(_policyToken, _stablecoin)
        );
        require(address(pair) != address(0), "Pair not exist");

        (uint256 reserve0, uint256 reserve1) = pair.getReserves();

        uint256 feeRate = pair.feeRate();

        // Calculate amountIn - fee
        uint256 amountInWithFee = _amount * (1000 - feeRate);

        // Calculate amountOut
        amountOut =
            (amountInWithFee * reserve1) /
            (reserve0 * 1000 + amountInWithFee);

        // Transfer policy token and swap
        IERC20(_policyToken).safeTransfer(address(pair), _amount);
        pair.swap(0, amountOut, _to);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.10;
import "./NPPolicyToken.sol";
import "./NaughtyPair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INaughtyPair} from "./interfaces/INaughtyPair.sol";
import {IPolicyCore} from "./interfaces/IPolicyCore.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Naughty Factory
 * @dev Factory contract to deploy new pools periodically
 *      Each pool(product) will have a unique naughtyId
 *      Each pool will have its pool token
 *      PolicyToken - Stablecoin
 *      Token 0 may change but Token 1 is always stablecoin.
 */

contract NaughtyFactory is OwnableUpgradeable {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // INIT_CODE_HASH for NaughtyPair, may be used in frontend
    bytes32 public constant PAIR_INIT_CODE_HASH =
        keccak256(abi.encodePacked(type(NaughtyPair).creationCode));

    // PolicyToken Address => StableCoin Address => Pool Address
    mapping(address => mapping(address => address)) getPair;

    // Store all the pairs' addresses
    address[] public allPairs;

    // Store all policy tokens' addresses
    address[] public allTokens;

    // Next pool id to be deployed
    uint256 public _nextId;

    // Address of policyCore
    address public policyCore;

    // Address of income maker, part of the transaction fee will be distributed to this address
    address public incomeMaker;

    // Swap fee proportion to income maker
    uint256 public incomeMakerProportion;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event PolicyCoreAddressChanged(
        address oldPolicyCore,
        address newPolicyCore
    );
    event IncomeMakerProportionChanged(
        uint256 oldProportion,
        uint256 newProportion
    );
    event IncomeMakerAddressChanged(
        address oldIncomeMaker,
        address newIncomeMaker
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize() public initializer {
        __Ownable_init();
        // 40% of swap fee is distributed to income maker contract
        // Can be set later
        incomeMakerProportion = 40;
    }

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Modifiers ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Only called by policyCore contract
     */
    modifier onlyPolicyCore() {
        require(msg.sender == policyCore, "Only called by policyCore contract");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get the all tokens that have been deployed
     * @return tokens All tokens
     */
    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }

    /**
     * @notice Get the INIT_CODE_HASH for policy tokens with parameters
     * @dev For test/task convinience, pre-compute the address
     *      Ethers.js:
     *      Address = ethers.utils.getCreate2Address(factory address, salt, INIT_CODE_HASH)
     *      salt = keccak256(abi.encodePacked(_policyTokenName))
     * @param _tokenName Name of the policy token to be deployed
     * @param _decimals Token decimals of this policy token
     */
    function getInitCodeHashForPolicyToken(
        string memory _tokenName,
        uint256 _decimals
    ) public view returns (bytes32) {
        bytes memory bytecode = _getPolicyTokenBytecode(_tokenName, _decimals);
        return keccak256(bytecode);
    }

    /**
     * @notice Get the pair address deployed by the factory
     *         PolicyToken address first, and then stablecoin address
     *         The order of the tokens will be sorted inside the function
     * @param _tokenAddress1 Address of token1
     * @param _tokenAddress2 Address of toekn2
     * @return Pool address of the two tokens
     */
    function getPairAddress(address _tokenAddress1, address _tokenAddress2)
        public
        view
        returns (address)
    {
        // Policy token address at the first place
        (address token0, address token1) = IPolicyCore(policyCore)
            .supportedStablecoin(_tokenAddress2)
            ? (_tokenAddress1, _tokenAddress2)
            : (_tokenAddress2, _tokenAddress1);

        address _pairAddress = getPair[token0][token1];

        return _pairAddress;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Set Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Remember to call this function to set the policyCore address
     * @dev    Only callable by the owner
     *         < PolicyCore should be the minter of policyToken >
     *         < This process is done inside constructor >
     * @param _policyCore Address of policyCore contract
     */
    function setPolicyCoreAddress(address _policyCore) external onlyOwner {
        emit PolicyCoreAddressChanged(policyCore, _policyCore);
        policyCore = _policyCore;
    }

    /**
     * @notice Set income maker proportion
     * @dev    Only callable by the owner
     * @param _proportion New proportion to income maker contract
     */
    function setIncomeMakerProportion(uint256 _proportion) external onlyOwner {
        emit IncomeMakerProportionChanged(incomeMakerProportion, _proportion);
        incomeMakerProportion = _proportion;
    }

    /**
     * @notice Set income maker address
     * @dev Only callable by the owner
     * @param _incomeMaker New income maker address
     */
    function setIncomeMakerAddress(address _incomeMaker) external onlyOwner {
        emit IncomeMakerAddressChanged(incomeMaker, _incomeMaker);
        incomeMaker = _incomeMaker;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Main Functions *********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice For each round we need to first create the policytoken(ERC20)
     * @param _policyTokenName Name of the policyToken
     * @param _decimals Decimals of the policyToken
     * @return tokenAddress PolicyToken address
     */
    function deployPolicyToken(
        string memory _policyTokenName,
        uint256 _decimals
    ) external onlyPolicyCore returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_policyTokenName));

        bytes memory bytecode = _getPolicyTokenBytecode(
            _policyTokenName,
            _decimals
        );

        address _policTokenAddress = _deploy(bytecode, salt);

        allTokens.push(_policTokenAddress);

        _nextId++;

        return _policTokenAddress;
    }

    /**
     * @notice After deploy the policytoken and get the address,
     *         we deploy the policyToken - stablecoin pool contract
     * @param _policyTokenAddress Address of policy token
     * @param _stablecoin Address of the stable coin
     * @param _deadline Deadline of the pool
     * @param _feeRate Fee rate given to LP holders
     * @return poolAddress Address of the pool
     */
    function deployPool(
        address _policyTokenAddress,
        address _stablecoin,
        uint256 _deadline,
        uint256 _feeRate
    ) public onlyPolicyCore returns (address) {
        bytes memory bytecode = type(NaughtyPair).creationCode;

        bytes32 salt = keccak256(
            abi.encodePacked(_policyTokenAddress, _stablecoin)
        );

        address _poolAddress = _deploy(bytecode, salt);

        INaughtyPair(_poolAddress).initialize(
            _policyTokenAddress,
            _stablecoin,
            _deadline,
            _feeRate
        );

        getPair[_policyTokenAddress][_stablecoin] = _poolAddress;

        allPairs.push(_poolAddress);

        return _poolAddress;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Deploy function with create2
     * @param code Byte code of the contract (creation code)
     * @param salt Salt for the deployment
     * @return addr The deployed contract address
     */
    function _deploy(bytes memory code, bytes32 salt)
        internal
        returns (address addr)
    {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }

    /**
     * @notice Get the policyToken bytecode (with constructor parameters)
     * @param _tokenName Name of policyToken
     * @param _decimals Decimals of policyToken
     */
    function _getPolicyTokenBytecode(
        string memory _tokenName,
        uint256 _decimals
    ) internal view returns (bytes memory) {
        bytes memory bytecode = type(NPPolicyToken).creationCode;

        // Encodepacked the parameters
        // The minter is set to be the policyCore address
        return
            abi.encodePacked(
                bytecode,
                abi.encode(_tokenName, _tokenName, policyCore, _decimals)
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.10;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title  Policy Token for Naughty Price
 * @notice This is the contract for token price policy token.
 *         It is a ERC20 token with an owner and a minter.
 *         The owner should be the deployer at first.
 *         The minter should be the policyCore contract.
 * @dev    It is different from the flight delay token.
 *         That is an ERC721 NFT and this is an ERC20 token.
 */
contract NPPolicyToken is ERC20 {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    address public minter;

    uint256 private tokenDecimals;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event Mint(address account, uint256 amount);
    event Burn(address account, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _minter,
        uint256 _decimals
    ) ERC20(_name, _symbol) {
        minter = _minter;
        tokenDecimals = _decimals;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Modifiers **************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Only the minter can mint
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "only minter can call this function");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Main Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Mint some policy tokens
     * @param _account Address to receive the tokens
     * @param _amount Amount to be minted
     */
    function mint(address _account, uint256 _amount) public onlyMinter {
        _mint(_account, _amount);
        emit Mint(_account, _amount);
    }

    /**
     * @notice Burn some policy tokens
     * @param _account Address to burn tokens
     * @param _amount Amount to be burned
     */
    function burn(address _account, uint256 _amount) public onlyMinter {
        _burn(_account, _amount);
        emit Burn(_account, _amount);
    }

    /**
     * @notice Get the decimals of this token
     * @dev It should be the same as its paired stablecoin
     */
    function decimals() public view override returns (uint8) {
        return uint8(tokenDecimals);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { VeERC20Upgradeable } from "./VeERC20Upgradeable.sol";
import { Math } from "../libraries/Math.sol";

import { IFarmingPool } from "../farming/interfaces/IFarmingPool.sol";

/**
 * @title Vote Escrowed Degis
 * @notice The staking contract for DEG -> veDEG
 *         veDEG:
 *            - Boosting the farming reward
 *            - Governance
 *            - Participate in Initial Liquidity Matching (naughty price)
 *            - etc.
 *         If you stake degis, you generate veDEG at the current `generationRate` until you reach `maxCap`
 *         If you unstake any amount of degis, you will lose all of your veDEG tokens
 *
 *         There is also an option that you lock your DEG for the max time
 *         and get the maximum veDEG balance immediately.
 *         !! Attention !!
 *         If you stake DEG for the max time for more than once, the lockUntil timestamp will
 *         be updated to the latest one.
 */
contract VoteEscrowedDegis is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    VeERC20Upgradeable
{
    using SafeERC20 for IERC20;

    struct UserInfo {
        // degis staked by user
        uint256 amount;
        // time of last veDEG claim or first deposit if user has not claimed yet
        uint256 lastRelease;
        // Amount locked for max time
        uint256 amountLocked;
        // Lock until timestamp
        uint256 lockUntil;
    }

    // User info
    mapping(address => UserInfo) public users;

    // Degis token
    // IERC20 public constant degis =
    //     IERC20(0x9f285507Ea5B4F33822CA7aBb5EC8953ce37A645);
    IERC20 public degis;

    // Farming pool
    IFarmingPool public farmingPool;

    // Max veDEG to staked degis ratio
    // Max veDEG amount = maxCap * degis staked
    uint256 public maxCapRatio;

    // Rate of veDEG generated per second, per degis staked
    uint256 public generationRate;

    // Calculation scale
    uint256 public constant SCALE = 1e18;

    // Whitelist contract checker
    // Contract addresses are by default unable to stake degis, they must be whitelisted
    mapping(address => bool) whitelist;

    // Locked amount
    mapping(address => uint256) public locked;

    // NFT Staking contract
    address public nftStaking;

    mapping(address => uint256) public boosted;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //
    event GenerationRateChanged(uint256 oldRate, uint256 newRate);
    event MaxCapRatioChanged(uint256 oldMaxCapRatio, uint256 newMaxCapRatio);
    event WhiteListAdded(address newWhiteList);
    event WhiteListRemoved(address oldWhiteList);

    event Deposit(address indexed user, uint256 amount);
    event DepositMaxTime(
        address indexed user,
        uint256 amount,
        uint256 lockUntil
    );
    event Withdraw(address indexed user, uint256 amount);

    event Claimed(address indexed user, uint256 amount);

    event BurnVeDEG(
        address indexed caller,
        address indexed user,
        uint256 amount
    );

    event LockVeDEG(
        address indexed caller,
        address indexed user,
        uint256 amount
    );

    event UnlockVeDEG(
        address indexed caller,
        address indexed user,
        uint256 amount
    );

    event NFTStakingChanged(address oldNFTStaking, address newNFTStaking);
    event BoostVeDEG(address user, uint256 boostType);
    event UnBoostVeDEG(address user);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error VED__NotWhiteListed();
    error VED__StillLocked();
    error VED__ZeroAddress();
    error VED__ZeroAmount();
    error VED__NotEnoughBalance();

    error VED__TimeNotPassed();
    error VED__OverLocked();

    error VED__NotNftStaking();

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(address _degis, address _farmingPool)
        public
        initializer
    {
        if (_degis == address(0) || _farmingPool == address(0))
            revert VED__ZeroAddress();

        // Initialize veDEG
        __ERC20_init("Vote Escrowed Degis", "veDEG");
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        // Set generationRate (veDEG per sec per degis staked)
        generationRate = 10**18;

        // Set maxCap ratio
        maxCapRatio = 100;

        // Set degis
        degis = IERC20(_degis);

        // Set farming pool
        farmingPool = IFarmingPool(_farmingPool);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Not callable by smart contract
     * @dev Checked first by msg.sender == tx.origin
     *      Then if the contract is whitelisted, it will still pass the check
     */
    modifier notContract(address _addr) {
        if (_addr != tx.origin) {
            if (!whitelist[_addr]) revert VED__NotWhiteListed();
        }
        _;
    }

    /**
     * @notice No locked veDEG
     * @dev Check the locked balance of a user
     */
    modifier noLocked(address _user) {
        if (locked[_user] > 0) revert VED__StillLocked();
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Calculate the amount of veDEG that can be claimed by user
     * @param _user User address
     * @return claimableAmount Claimable amount of the user
     */
    function claimable(address _user) public view returns (uint256) {
        if (_user == address(0)) revert VED__ZeroAddress();

        UserInfo memory user = users[_user];

        // Seconds passed since last claim
        uint256 timePassed = block.timestamp - user.lastRelease;

        uint256 realCapRatio = _getCapRatio(_user);

        uint256 pending;
        // Calculate pending amount
        uint256 boostType = boosted[_user];
        // If no boost
        if (boostType == 0) {
            pending = Math.wmul(user.amount, timePassed * generationRate);
        }
        // Normal nft boost
        else if (boostType == 1) {
            pending = Math.wmul(
                user.amount,
                (timePassed * generationRate * 120) / 100
            );
        }
        // Rare nft boost
        else if (boostType == 2) {
            pending = Math.wmul(
                user.amount,
                (timePassed * generationRate * 150) / 100
            );
        }

        // get user's veDEG balance
        uint256 userVeDEGBalance = balanceOf(_user) -
            user.amountLocked *
            realCapRatio;

        // user veDEG balance cannot go above user.amount * maxCap
        uint256 veDEGCap = user.amount * realCapRatio;

        // first, check that user hasn't reached the max limit yet
        if (userVeDEGBalance < veDEGCap) {
            // then, check if pending amount will make user balance overpass maximum amount
            if (userVeDEGBalance + pending > veDEGCap) {
                return veDEGCap - userVeDEGBalance;
            } else {
                return pending;
            }
        }
        return 0;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Add a new whitelist address
     * @dev Only callable by the owner
     * @param _account Address to add
     */
    function addWhitelist(address _account) external onlyOwner {
        whitelist[_account] = true;
        emit WhiteListAdded(_account);
    }

    /**
     * @notice Remove a new whitelist address
     * @dev Only callable by the owner
     * @param _account Address to remove
     */
    function removeWhitelist(address _account) external onlyOwner {
        whitelist[_account] = false;
        emit WhiteListRemoved(_account);
    }

    /**
     * @notice Set maxCap ratio
     * @param _maxCapRatio the new max ratio
     */
    function setMaxCapRatio(uint256 _maxCapRatio) external onlyOwner {
        if (_maxCapRatio == 0) revert VED__ZeroAmount();
        emit MaxCapRatioChanged(maxCapRatio, _maxCapRatio);
        maxCapRatio = _maxCapRatio;
    }

    /**
     * @notice Set generationRate
     * @param _generationRate New generation rate
     */
    function setGenerationRate(uint256 _generationRate) external onlyOwner {
        if (_generationRate == 0) revert VED__ZeroAmount();
        emit GenerationRateChanged(generationRate, _generationRate);
        generationRate = _generationRate;
    }

    function setNFTStaking(address _nftStaking) external onlyOwner {
        emit NFTStakingChanged(nftStaking, _nftStaking);
        nftStaking = _nftStaking;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Depisit degis for veDEG
     * @dev Only EOA or whitelisted contract address
     * @param _amount Amount to deposit
     */
    function deposit(uint256 _amount)
        external
        nonReentrant
        whenNotPaused
        notContract(msg.sender)
    {
        if (_amount == 0) revert VED__ZeroAmount();

        if (users[msg.sender].amount > 0) {
            // If the user has amount deposited, claim veDEG
            _claim(msg.sender);

            // Update the amount
            users[msg.sender].amount += _amount;
        } else {
            // add new user to mapping
            users[msg.sender].lastRelease = block.timestamp;
            users[msg.sender].amount = _amount;
        }

        // Request degis from user
        degis.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Deposit for the max time
     * @dev Release the max amount one time
     */
    function depositMaxTime(uint256 _amount)
        external
        nonReentrant
        whenNotPaused
    {
        if (_amount == 0) revert VED__ZeroAmount();

        uint256 currentMaxTime = (maxCapRatio * SCALE) / generationRate;
        uint256 lockUntil = block.timestamp + currentMaxTime * 2;

        users[msg.sender].amountLocked += _amount;
        users[msg.sender].lockUntil = lockUntil;

        // Request degis from user
        degis.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 realCapRatio = _getCapRatio(msg.sender);

        _mint(msg.sender, realCapRatio * _amount);

        emit DepositMaxTime(msg.sender, _amount, lockUntil);
    }

    /**
     * @notice Claims accumulated veDEG for flex deposit
     */
    function claim() public nonReentrant whenNotPaused {
        if (users[msg.sender].amount == 0) revert VED__ZeroAmount();

        _claim(msg.sender);
    }

    /**
     * @notice Withdraw degis token
     * @dev User will lose all veDEG once he withdrawed
     * @param _amount Amount to withdraw
     */
    function withdraw(uint256 _amount)
        external
        nonReentrant
        whenNotPaused
        noLocked(msg.sender)
    {
        if (_amount == 0) revert VED__ZeroAmount();

        UserInfo storage user = users[msg.sender];
        if (user.amount < _amount) revert VED__NotEnoughBalance();

        // reset last Release timestamp
        user.lastRelease = block.timestamp;

        // update his balance before burning or sending back degis
        user.amount -= _amount;

        // get user veDEG balance that must be burned
        // those locked amount will not be calculated

        uint256 realCapRatio = _getCapRatio(msg.sender);

        uint256 userVeDEGBalance = balanceOf(msg.sender) -
            user.amountLocked *
            realCapRatio;

        _burn(msg.sender, userVeDEGBalance);

        // send back the staked degis
        degis.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice Withdraw all the locked veDEG
     */
    function withdrawLocked()
        external
        nonReentrant
        whenNotPaused
        noLocked(msg.sender)
    {
        UserInfo memory user = users[msg.sender];

        if (user.amountLocked == 0) revert VED__ZeroAmount();
        if (block.timestamp < user.lockUntil) revert VED__TimeNotPassed();

        uint256 realCapRatio = _getCapRatio(msg.sender);

        _burn(msg.sender, user.amountLocked * realCapRatio);

        // update his balance before burning or sending back degis
        users[msg.sender].amountLocked = 0;
        users[msg.sender].lockUntil = 0;

        // send back the staked degis
        degis.safeTransfer(msg.sender, user.amountLocked);
    }

    /**
     * @notice Lock veDEG token
     * @dev Only whitelisted contract
     *      Income sharing contract will lock veDEG as entrance
     * @param _to User address
     * @param _amount Amount to lock
     */
    function lockVeDEG(address _to, uint256 _amount) external {
        // Only whitelisted contract can lock veDEG
        if (!whitelist[msg.sender]) revert VED__NotWhiteListed();

        if (locked[_to] + _amount > balanceOf(_to)) revert VED__OverLocked();

        _lock(_to, _amount);
        emit LockVeDEG(msg.sender, _to, _amount);
    }

    /**
     * @notice Unlock veDEG token
     * @param _to User address
     * @param _amount Amount to unlock
     */
    function unlockVeDEG(address _to, uint256 _amount) external {
        // Only whitelisted contract can unlock veDEG
        if (!whitelist[msg.sender]) revert VED__NotWhiteListed();

        if (locked[_to] < _amount) revert VED__OverLocked();

        _unlock(_to, _amount);
        emit UnlockVeDEG(msg.sender, _to, _amount);
    }

    /**
     * @notice Burn veDEG
     * @dev Only whitelisted contract
     *      For future use, some contracts may need veDEG for entrance
     * @param _to Address to burn
     * @param _amount Amount to burn
     */
    function burnVeDEG(address _to, uint256 _amount) public {
        // Only whitelisted contract can burn veDEG
        if (!whitelist[msg.sender]) revert VED__NotWhiteListed();

        _burn(_to, _amount);
        emit BurnVeDEG(msg.sender, _to, _amount);
    }

    /**
     * @notice Boost veDEG
     *
     * @dev Only called by nftStaking contract
     *
     * @param _user User address
     * @param _type Boost type (1 = 120%, 2 = 150%)
     */
    function boostVeDEG(address _user, uint256 _type) external {
        if (msg.sender != nftStaking) revert VED__NotNftStaking();

        require(_type == 1 || _type == 2);

        boosted[_user] = _type;

        uint256 boostRatio;

        if (_type == 1) boostRatio = 20;
        else if (_type == 2) boostRatio = 50;

        uint256 userBalance = balanceOf(_user);

        if (userBalance > 0) {
            _mint(_user, (userBalance * boostRatio) / 100);
        }

        emit BoostVeDEG(_user, _type);
    }

    /**
     * @notice UnBoost veDEG
     *
     * @dev Only called by nftStaking contract
     *
     * @param _user User address
     */
    function unBoostVeDEG(address _user) external {
        if (msg.sender != nftStaking) revert VED__NotNftStaking();

        uint256 currentBoostStatus = boosted[_user];

        if (currentBoostStatus == 0) return;

        uint256 userBalance = balanceOf(_user);
        uint256 userLocked = locked[_user];

        if (currentBoostStatus == 1) {
            if (userLocked > 0) revert VED__StillLocked();
            _burn(_user, (userBalance * 20) / 120);
        } else if (currentBoostStatus == 2) {
            if (userLocked > 0) revert VED__StillLocked();
            _burn(_user, (userBalance * 50) / 150);
        }

        boosted[_user] = 0;

        emit UnBoostVeDEG(_user);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Finish claiming veDEG
     * @param _user User address
     */
    function _claim(address _user) internal {
        uint256 amount = claimable(_user);

        // update last release time
        users[_user].lastRelease = block.timestamp;

        if (amount > 0) {
            emit Claimed(_user, amount);
            _mint(_user, amount);
        }
    }

    /**
     * @notice Update the bonus in farming pool
     * @dev Every time when token is transferred (balance change)
     * @param _user User address
     * @param _newBalance New veDEG balance
     */
    function _afterTokenOperation(address _user, uint256 _newBalance)
        internal
        override
    {
        farmingPool.updateBonus(_user, _newBalance);
    }

    /**
     * @notice Lock veDEG token
     * @param _to User address
     * @param _amount Amount to lock
     */
    function _lock(address _to, uint256 _amount) internal {
        locked[_to] += _amount;
    }

    /**
     * @notice Unlock veDEG token
     * @param _to User address
     * @param _amount Amount to unlock
     */
    function _unlock(address _to, uint256 _amount) internal {
        if (locked[_to] < _amount) revert VED__NotEnoughBalance();
        locked[_to] -= _amount;
    }

    /**
     * @notice Get real cap ratio for a user
     *         The ratio depends on the boost type
     *
     * @param _user User address
     *
     * @return realCapRatio Real cap ratio
     */
    function _getCapRatio(address _user)
        internal
        view
        returns (uint256 realCapRatio)
    {
        uint256 boostType = boosted[_user];
        if (boostType == 0) {
            realCapRatio = maxCapRatio;
        } else if (boostType == 1) {
            realCapRatio = (maxCapRatio * 120) / 100;
        } else if (boostType == 2) {
            realCapRatio = (maxCapRatio * 150) / 100;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IVeERC20.sol";

/// @title VeERC20Upgradeable
/// @notice Modified version of ERC20Upgradeable where transfers and allowances are disabled.
/// @dev only minting and burning are allowed. The hook _afterTokenOperation is called after Minting and Burning.
contract VeERC20Upgradeable is Initializable, ContextUpgradeable, IVeERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Emitted when `value` tokens are burned and minted
     */
    event Burn(address indexed account, uint256 value);
    event Mint(address indexed beneficiary, uint256 value);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
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
        emit Mint(account, amount);

        _afterTokenOperation(account, _balances[account]);
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

        emit Burn(account, amount);

        _afterTokenOperation(account, _balances[account]);
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
     * @dev Hook that is called after any minting and burning.
     * @param account the account being affected
     * @param newBalance newBalance after operation
     */
    function _afterTokenOperation(address account, uint256 newBalance)
        internal
        virtual
    {}

    uint256[45] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IFarmingPool {
    function pendingDegis(uint256 _poolId, address _user)
        external
        returns (uint256);

    function setStartBlock(uint256 _startBlock) external;

    function add(
        address _lpToken,
        uint256 _poolId,
        bool _withUpdate
    ) external;

    function setDegisReward(
        uint256 _poolId,
        uint256 _basicDegisPerBlock,
        uint256 _bonusDegisPerBlock,
        bool _withUpdate
    ) external;

    function stake(uint256 _poolId, uint256 _amount) external;

    function withdraw(uint256 _poolId, uint256 _amount) external;

    function updatePool(uint256 _poolId) external;

    function massUpdatePools() external;

    function harvest(uint256 _poolId, address _to) external;

    function updateBonus(address _user, uint256 _newBalance) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IVeDEG} from "../governance/interfaces/IVeDEG.sol";

import "hardhat/console.sol";

/**
 * @title Degis Income Sharing Contract
 * @notice This contract will receive part of the income from Degis products
 *         And the income will be shared by DEG holders (in the form of veDEG)
 *
 *         It is designed to be an ever-lasting reward
 *
 *         At first the reward is USDC.e and later may be transferred to Shield
 *         To enter the income sharing vault, you need to lock some veDEG
 *             - When your veDEG is locked, it can not be withdrawed
 *
 *         The reward is distributed per second like a farming pool
 *         The income will come from (to be updated)
 *             - IncomeMaker: Collect swap fee in naughty price pool
 *             - PolicyCore: Collect deposit/redeem fee in policy core
 */
contract IncomeSharingVault is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    uint256 public constant SCALE = 1e30;

    uint256 public roundTime;

    IVeDEG public veDEG;

    struct PoolInfo {
        bool available;
        address rewardToken;
        uint256 totalAmount;
        uint256 rewardPerSecond;
        uint256 accRewardPerShare;
        uint256 lastRewardTimestamp;
    }
    // Pool Id
    // 1: USDC.e as reward
    // 2: Shield as reward
    mapping(uint256 => PoolInfo) public pools;

    struct UserInfo {
        uint256 totalAmount;
        uint256 rewardDebt;
    }
    mapping(uint256 => mapping(address => UserInfo)) public users;

    uint256 public nextPool;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event RoundTimeChanged(uint256 oldRoundTime, uint256 newRoundTime);
    event NewRewardPoolStart(uint256 poolId, address rewardToken);
    event RewardSpeedSet(uint256 poolId, uint256 rewardPerSecond);
    event PoolUpdated(uint256 poolId, uint256 accRewardPerSecond);
    event Harvest(address user, uint256 poolId, uint256 amount);
    event Deposit(address user, uint256 poolId, uint256 amount);
    event Withdraw(address user, uint256 poolId, uint256 amount);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Errors start with DIS(Degis Income Sharing)
    error DIS__PoolNotAvailable();
    error DIS__ZeroAmount();
    error DIS__NotEnoughVeDEG();
    error DIS__WrongSpeed();

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(address _veDEG) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        veDEG = IVeDEG(_veDEG);

        nextPool = 1;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Pending reward
     * @param _poolId Pool Id
     * @param _user   User address
     * @return pendingReward Amount of pending reward
     */
    function pendingReward(uint256 _poolId, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = pools[_poolId];

        if (
            pool.lastRewardTimestamp == 0 ||
            block.timestamp < pool.lastRewardTimestamp
        ) return 0;

        uint256 accRewardPerShare = pool.accRewardPerShare;

        if (pool.totalAmount == 0) return 0;
        else {
            UserInfo memory user = users[_poolId][_user];

            uint256 timePassed = block.timestamp - pool.lastRewardTimestamp;
            uint256 reward = timePassed * pool.rewardPerSecond;

            // Remainging reward inside the pool
            uint256 remainingReward = IERC20(pool.rewardToken).balanceOf(
                address(this)
            );

            uint256 finalReward = reward > remainingReward
                ? remainingReward
                : reward;

            accRewardPerShare += (finalReward * SCALE) / pool.totalAmount;

            uint256 pending = (user.totalAmount * accRewardPerShare) /
                SCALE -
                user.rewardDebt;

            return pending;
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set round time
     * @dev Round time is only used for checking reward speed
     * @param _roundTime Round time in seconds
     */
    function setRoundTime(uint256 _roundTime) external onlyOwner {
        emit RoundTimeChanged(roundTime, _roundTime);
        roundTime = _roundTime;
    }

    /**
     * @notice Start a new income sharing pool
     * @dev Normally there will be two pools
     *          - USDC.e as reward (1)
     *          - Shield as reward (2)
     * @param _rewardToken Reward token address
     */
    function startPool(address _rewardToken) external onlyOwner {
        PoolInfo storage pool = pools[nextPool++];

        pool.available = true;
        pool.rewardToken = _rewardToken;

        emit NewRewardPoolStart(nextPool - 1, _rewardToken);
    }

    /**
     * @notice Set reward speed for a pool
     * @param _poolId Pool id
     * @param _rewardPerSecond Reward speed
     */
    function setRewardSpeed(uint256 _poolId, uint256 _rewardPerSecond)
        external
    {
        updatePool(_poolId);

        PoolInfo memory pool = pools[_poolId];

        // Ensure there is enough reward for this round
        if (
            roundTime * _rewardPerSecond >
            IERC20(pool.rewardToken).balanceOf(address(this))
        ) revert DIS__WrongSpeed();

        pools[_poolId].rewardPerSecond = _rewardPerSecond;

        emit RewardSpeedSet(_poolId, _rewardPerSecond);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Deposit
     * @param _poolId Pool Id
     * @param _amount Amount of tokens to deposit
     */
    function deposit(uint256 _poolId, uint256 _amount) external nonReentrant {
        if (!pools[_poolId].available) revert DIS__PoolNotAvailable();
        if (_amount == 0) revert DIS__ZeroAmount();
        if (veDEG.balanceOf(msg.sender) < _amount) revert DIS__NotEnoughVeDEG();

        updatePool(_poolId);

        // Lock some veDEG to participate
        veDEG.lockVeDEG(msg.sender, _amount);

        PoolInfo storage pool = pools[_poolId];
        UserInfo storage user = users[_poolId][msg.sender];

        if (user.totalAmount > 0) {
            uint256 pending = (pool.accRewardPerShare * user.totalAmount) /
                SCALE -
                user.rewardDebt;

            uint256 reward = _safeRewardTransfer(
                pool.rewardToken,
                msg.sender,
                pending
            );
            emit Harvest(msg.sender, _poolId, reward);
        }

        // Update pool amount
        pool.totalAmount += _amount;

        // Update user amount
        user.totalAmount += _amount;

        user.rewardDebt = (pool.accRewardPerShare * user.totalAmount) / SCALE;

        emit Deposit(msg.sender, _poolId, _amount);
    }

    /**
     * @notice Withdraw all veDEG
     * @param _poolId Pool Id
     */
    function withdrawAll(uint256 _poolId) external {
        withdraw(_poolId, users[_poolId][msg.sender].totalAmount);
    }

    /**
     * @notice Withdraw the reward from the pool
     * @param _poolId Pool Id
     * @param _amount Amount to withdraw
     */
    function withdraw(uint256 _poolId, uint256 _amount) public nonReentrant {
        if (_amount == 0) revert DIS__ZeroAmount();

        PoolInfo storage pool = pools[_poolId];
        UserInfo storage user = users[_poolId][msg.sender];

        if (user.totalAmount < _amount) revert DIS__NotEnoughVeDEG();

        updatePool(_poolId);

        uint256 pending = (pool.accRewardPerShare * user.totalAmount) /
            SCALE -
            user.rewardDebt;

        uint256 reward = _safeRewardTransfer(
            pool.rewardToken,
            msg.sender,
            pending
        );
        emit Harvest(msg.sender, _poolId, reward);

        // Update user info
        pool.totalAmount -= _amount;

        user.totalAmount -= _amount;
        user.rewardDebt = (user.totalAmount * pool.accRewardPerShare) / SCALE;

        // Unlock veDEG
        veDEG.unlockVeDEG(msg.sender, _amount);

        emit Withdraw(msg.sender, _poolId, _amount);
    }

    /**
     * @notice Harvest income reward
     * @param _poolId Pool Id
     * @param _to Reward receiver address
     */
    function harvest(uint256 _poolId, address _to)
        public
        nonReentrant
        whenNotPaused
    {
        updatePool(_poolId);

        PoolInfo memory pool = pools[_poolId];
        UserInfo storage user = users[_poolId][msg.sender];

        // pending reward
        uint256 pending = (user.totalAmount * pool.accRewardPerShare) /
            SCALE -
            user.rewardDebt;

        user.rewardDebt = (user.totalAmount * pool.accRewardPerShare) / SCALE;

        uint256 reward = _safeRewardTransfer(pool.rewardToken, _to, pending);

        emit Harvest(msg.sender, _poolId, reward);
    }

    /**
     * @notice Update pool
     * @param _poolId Pool id
     */
    function updatePool(uint256 _poolId) public {
        PoolInfo storage pool = pools[_poolId];

        if (block.timestamp <= pool.lastRewardTimestamp) return;

        uint256 totalAmount = pool.totalAmount;
        uint256 rewardPerSecond = pool.rewardPerSecond;

        if (totalAmount == 0 || rewardPerSecond == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }

        // Time passed in seconds and total rewards
        uint256 timePassed = block.timestamp - pool.lastRewardTimestamp;
        uint256 reward = timePassed * rewardPerSecond;

        // Remainging reward inside the pool
        uint256 remainingReward = IERC20(pool.rewardToken).balanceOf(
            address(this)
        );

        // Can not exceed the max balance of the pool
        uint256 finalReward = reward > remainingReward
            ? remainingReward
            : reward;

        pool.accRewardPerShare += (finalReward * SCALE) / totalAmount;

        pool.lastRewardTimestamp = block.timestamp;

        emit PoolUpdated(_poolId, pool.accRewardPerShare);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Finish the reward token transfer
     * @dev Safe means not transfer exceeds the balance of contract
     *      Manually change the reward speed
     * @param _to Address to transfer
     * @param _amount Amount to transfer
     * @return realAmount Real amount transferred
     */
    function _safeRewardTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 balance = IERC20(_token).balanceOf(address(this));

        if (_amount > balance) {
            IERC20(_token).safeTransfer(_to, balance);
            return balance;
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
            return _amount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRandomNumberGenerator.sol";
import "./MathLib.sol";

import "hardhat/console.sol";

/**
 * @title DegisLotteryV2
 *
 * @dev
 */

contract DegisLotteryV2 is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using MathLib for uint256;
    using MathLib for int128;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Treasury fee
    uint256 public constant MAX_TREASURY_FEE = 3000; // 30%

    // Ticket numbers
    uint32 public constant MIN_TICKET_NUMBER = 10000;
    uint32 public constant MAX_TICKET_NUMBER = 19999;

    // Default ticket price
    uint256 public constant DEFAULT_PRICE = 10 ether;

    // 98% for each extra ticket
    uint256 public constant DISCOUNT_DIVISOR = 98;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    IERC20 public DegisToken;
    IRandomNumberGenerator public randomGenerator;

    address public treasury;

    uint256 public currentLotteryId; // Total Rounds

    uint256 public currentTicketId; // Total Tickets

    uint256 public maxNumberTicketsEachTime;

    uint256 public pendingInjectionNextLottery;

    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }

    struct Lottery {
        // Slot 1
        Status status; // uint8
        uint8 treasuryFee; // 500: 5% // 200: 2% // 50: 0.5%
        uint32 startTime;
        uint32 endTime;
        uint32 finalNumber;
        // Slot 2,3...
        uint256 ticketPrice; // 10
        uint256[4] rewardsBreakdown; // 0: 1 matching number // 3: 4 matching numbers
        uint256[4] rewardPerTicketInBracket;
        uint256[4] countWinnersPerBracket;
        uint256 firstTicketId;
        uint256 firstTicketIdNextRound;
        uint256 amountCollected; // Total prize pool
        uint256 pendingRewards; // Rewards that are not yet claimed
    }
    // lotteryId => Lottery Info
    mapping(uint256 => Lottery) public lotteries;

    struct Ticket {
        uint32 number;
        address owner;
    }
    // Ticket Id => Ticket Info
    mapping(uint256 => Ticket) public tickets;

    // lotteryId => (Lucky Number => Total Amount of this number)
    // e.g. In lottery round 3, 10 Tickets are sold with "11234": 3 => (11234 => 10)
    mapping(uint256 => mapping(uint32 => uint256))
        public _numberTicketsPerLotteryId;

    // Keep track of user ticket ids for a given lotteryId
    // User Address => Lottery Round => Tickets
    mapping(address => mapping(uint256 => uint256[])) public _userTicketIds;

    mapping(uint32 => uint32) public _bracketCalculator;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event MaxNumberTicketsEachTimeChanged(
        uint256 oldMaxNumber,
        uint256 newMaxNumber
    );
    event TreasuryChanged(address oldTreasury, address newTreasury);
    event AdminTokenRecovery(address token, uint256 amount);
    event LotteryClose(uint256 indexed lotteryId);
    event LotteryInjection(uint256 indexed lotteryId, uint256 injectedAmount);
    event LotteryOpen(
        uint256 indexed lotteryId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceTicketInDegis,
        uint256[4] rewardsBreakdown,
        uint256 injectedAmount
    );
    event LotteryNumberDrawn(
        uint256 indexed lotteryId,
        uint256 finalNumber,
        uint256 countWinningTickets
    );

    event NewRandomGenerator(address indexed randomGenerator);
    event TicketsPurchased(
        address indexed buyer,
        uint256 indexed lotteryId,
        uint256 number,
        uint256 totalPrice
    );
    event TicketsClaim(
        address indexed claimer,
        uint256 amount,
        uint256 indexed lotteryId
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Initialize function
     *
     * @dev RandomNumberGenerator must be deployed prior to this contract
     *
     * @param _degis           Address of DEG
     * @param _randomGenerator Address of the RandomGenerator contract used to work with ChainLink VRF
     */
    function initialize(address _degis, address _randomGenerator)
        public
        initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();

        DegisToken = IERC20(_degis);
        randomGenerator = IRandomNumberGenerator(_randomGenerator);

        maxNumberTicketsEachTime = 10;

        _bracketCalculator[0] = 1;
        _bracketCalculator[1] = 11;
        _bracketCalculator[2] = 111;
        _bracketCalculator[3] = 1111;
        currentTicketId = 1;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Only EOA accounts to participate
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get the reward per ticket in 4 brackets
     *
     * @param _wallet address to check owned tickets
     *
     * @return _lotteryId lottery id to verify ownership
     */
    function viewWalletTicketIds(address _wallet, uint256 _lotteryId)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = _userTicketIds[_wallet][_lotteryId];
        return result;
    }

    /**
     * @notice View lottery information
     *
     * @param _startId Start lottery id
     * @param _endId End lottery id
     *
     * @return Array of lottery information
     */
    function viewAllLottery(uint256 _startId, uint256 _endId)
        external
        view
        returns (Lottery[] memory)
    {
        Lottery[] memory allLottery = new Lottery[](_endId - _startId + 1);
        for (uint256 i = _startId; i <= _endId; i++) {
            allLottery[i - 1] = lotteries[i];
        }
        return allLottery;
    }

    /**
     * @notice View ticker statuses and numbers for an array of ticket ids
     * @param _ticketIds: array of _ticketId
     */
    function viewNumbersPerTicketId(uint256[] calldata _ticketIds)
        external
        view
        returns (
            /// ticketIdsNumbersAndStatuses
            uint32[] memory
        )
    {
        uint256 length = _ticketIds.length;
        uint32[] memory ticketNumbers = new uint32[](length);

        for (uint256 i = 0; i < length; i++) {
            ticketNumbers[i] = tickets[_ticketIds[i]].number;
        }

        return (ticketNumbers);
    }

    /**
     * @notice View rewards for a given ticket in a given lottery round
     *
     * @dev This function will help to find the highest prize bracket
     *      But this computation is encouraged to be done off-chain
     *      Better to get bracket first and then call "_calculateRewardsForTicketId()"
     *
     * @param _lotteryId Lottery round
     * @param _ticketId  Ticket id
     *
     * @return reward Ticket reward
     */
    function viewRewardsForTicketId(uint256 _lotteryId, uint256 _ticketId)
        public
        view
        returns (uint256)
    {
        // Check lottery is in claimable status
        if (lotteries[_lotteryId].status != Status.Claimable) {
            return 0;
        }

        // Check ticketId is within range
        if (
            lotteries[_lotteryId].firstTicketIdNextRound < _ticketId ||
            lotteries[_lotteryId].firstTicketId > _ticketId
        ) {
            return 0;
        }

        // Only calculate prize for the highest bracket
        uint32 highestBracket = _getBracket(_lotteryId, _ticketId);

        return
            _calculateRewardsForTicketId(_lotteryId, _ticketId, highestBracket);
    }

    function viewUserRewards(
        address _user,
        uint256 _startRound,
        uint256 _endRound
    ) external view returns (uint256[] memory userRewards) {
        userRewards = new uint256[](_endRound - _startRound + 1);

        for (uint256 i = _startRound; i <= _endRound; ) {
            uint256 ticketAmount = _userTicketIds[_user][i].length;

            console.log("ticket amount: ", ticketAmount);
            console.log("gas used: ", gasleft());

            if (ticketAmount > 0) {
                uint256[] memory ticketIds = _userTicketIds[_user][i];

                for (uint256 j; j < ticketAmount; ) {
                    uint256 reward = viewRewardsForTicketId(i, ticketIds[j]);
                    userRewards[i - 1] += reward;

                    console.log("reward:", reward);

                    unchecked {
                        ++j;
                    }
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function viewRewardPerTicketInBracket(uint256 _lotteryId)
        external
        view
        returns (uint256[4] memory)
    {
        return lotteries[_lotteryId].rewardPerTicketInBracket;
    }

    function viewWinnerAmount(uint256 _lotteryId)
        external
        view
        returns (uint256[4] memory)
    {
        return lotteries[_lotteryId].countWinnersPerBracket;
    }

    function viewRewardsBreakdown(uint256 _lotteryId)
        external
        view
        returns (uint256[4] memory)
    {
        return lotteries[_lotteryId].rewardsBreakdown;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set max number can buy/claim each time
     *
     * @param _maxNumber Max number each time
     */
    function setMaxNumberTicketsEachTime(uint256 _maxNumber)
        external
        onlyOwner
    {
        emit MaxNumberTicketsEachTimeChanged(
            maxNumberTicketsEachTime,
            _maxNumber
        );
        maxNumberTicketsEachTime = _maxNumber;
    }

    /**
     * @notice Set treasury wallet address
     *
     * @param _treasury Treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        emit TreasuryChanged(treasury, _treasury);
        treasury = _treasury;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Buy tickets for the current lottery round
     *
     * @dev Need to transfer the 4-digit number to a 5-digit number to be used here (+10000)
     *      Can not be called by a smart contract
     *      Can only purchase in the current round
     *      E.g. You are selecting the number of 1-2-3-4 (lowest to highest)
     *           You will need to pass a number "14321"
     *
     * @param _ticketNumbers Array of ticket numbers between 10,000 and 19,999
     */
    function buyTickets(uint32[] calldata _ticketNumbers)
        external
        notContract
        nonReentrant
    {
        uint256 amountToBuy = _ticketNumbers.length;
        require(amountToBuy > 0, "No tickets are being bought");
        require(amountToBuy <= maxNumberTicketsEachTime, "Too many tickets");

        // Gas savings
        Lottery storage lottery = lotteries[currentLotteryId];
        uint256 currentRound = currentLotteryId;
        require(lottery.status == Status.Open, "Round not open");

        // Calculate the number of DEG to pay
        uint256 degToPay = _calculateTotalPrice(
            lottery.ticketPrice,
            amountToBuy
        );

        // Transfer degis tokens to this contract
        DegisToken.transferFrom(msg.sender, address(this), degToPay);

        // Increase prize pool amount
        lotteries[currentRound].amountCollected += degToPay;

        // Record the tickets bought
        for (uint256 i; i < amountToBuy; ) {
            // uint32 currentTicketNumber = _reverseTicketNumber(
            //     _ticketNumbers[i]
            // );

            uint32 currentTicketNumber = _ticketNumbers[i];

            require(
                (currentTicketNumber >= MIN_TICKET_NUMBER) &&
                    (currentTicketNumber <= MAX_TICKET_NUMBER),
                "Ticket number is outside range"
            );

            // Used when drawing the prize
            ++_numberTicketsPerLotteryId[currentRound][
                1 + (currentTicketNumber % 10)
            ];
            ++_numberTicketsPerLotteryId[currentRound][
                11 + (currentTicketNumber % 100)
            ];
            ++_numberTicketsPerLotteryId[currentRound][
                111 + (currentTicketNumber % 1000)
            ];
            ++_numberTicketsPerLotteryId[currentRound][
                1111 + (currentTicketNumber % 10000)
            ];

            // Gas savings
            uint256 ticketId = currentTicketId;

            // Store this ticket number to the user's record
            _userTicketIds[msg.sender][currentRound].push(ticketId);

            // Store this ticket number to global ticket state
            Ticket storage newTicket = tickets[ticketId];
            newTicket.number = currentTicketNumber;
            newTicket.owner = msg.sender;

            // Increase total lottery ticket number
            unchecked {
                ++currentTicketId;
                ++i;
            }
        }

        emit TicketsPurchased(msg.sender, currentRound, amountToBuy, degToPay);
    }

    /**
     * @notice Claim winning tickets
     *
     * @dev Callable by users only, not contract
     *
     * @param _lotteryId Lottery id
     * @param _ticketIds Array of ticket ids
     * @param _brackets  Bracket / prize level of each ticket
     */
    function claimTickets(
        uint256 _lotteryId,
        uint256[] calldata _ticketIds,
        uint32[] calldata _brackets
    ) external notContract nonReentrant {
        require(
            lotteries[_lotteryId].status == Status.Claimable,
            "Round not claimable"
        );

        uint256 ticketAmount = _ticketIds.length;
        require(ticketAmount == _brackets.length, "Not same length");
        require(ticketAmount > 0, "No tickets");
        require(
            ticketAmount <= maxNumberTicketsEachTime,
            "Too many tickets to claim"
        );

        uint256 rewardToTransfer;

        Lottery storage lottery = lotteries[_lotteryId];

        for (uint256 i; i < ticketAmount; ) {
            uint256 thisTicketId = _ticketIds[i];

            // Check the ticket id is inside the range
            require(
                thisTicketId >= lottery.firstTicketId,
                "Ticket id too small"
            );
            require(
                thisTicketId < lottery.firstTicketIdNextRound,
                "Ticket id too large"
            );

            // Check the ticket is owned by the user and reset this ticket
            // If the owner is zero address, then it has been claimed
            require(
                msg.sender == tickets[thisTicketId].owner,
                "Not the ticket owner or already claimed"
            );
            tickets[thisTicketId].owner = address(0);

            // Can not pass tickets with no prize
            uint256 rewardForTicketId = _calculateRewardsForTicketId(
                _lotteryId,
                thisTicketId,
                _brackets[i]
            );
            require(rewardForTicketId > 0, "No prize");

            // If not claiming the highest prize, check if the user has a higher prize
            if (_brackets[i] < 3) {
                require(
                    _calculateRewardsForTicketId(
                        _lotteryId,
                        thisTicketId,
                        _brackets[i] + 1
                    ) == 0,
                    "Only highest prize"
                );
            }

            // Increase the reward to transfer
            rewardToTransfer += rewardForTicketId;

            unchecked {
                ++i;
            }
        }

        lotteries[_lotteryId].pendingRewards -= rewardToTransfer;

        // Transfer the prize to the user
        DegisToken.transfer(msg.sender, rewardToTransfer);

        emit TicketsClaim(msg.sender, rewardToTransfer, _lotteryId);
    }

    /**
     * @notice Claim all winning tickets for a lottery round
     *
     * @dev Callable by users only, not contract
     *      Gas cost may be oversized, recommended to get brackets offchain first
     *      Get brackets offchain and call function "claimTickets"
     *
     * @param _lotteryId Lottery id
     */
    function claimAllTickets(uint256 _lotteryId)
        external
        notContract
        nonReentrant
    {
        require(
            lotteries[_lotteryId].status == Status.Claimable,
            "Round not claimable"
        );

        uint256 rewardToTransfer;

        // Gas savings
        uint256 ticketAmount = _userTicketIds[msg.sender][_lotteryId].length;

        for (uint256 i; i < ticketAmount; ) {
            uint256 thisTicketId = _userTicketIds[msg.sender][_lotteryId][i];

            Ticket memory thisTicket = tickets[thisTicketId];

            require(msg.sender == thisTicket.owner, "Not the ticket owner");

            uint32 highestBracket = _getBracket(_lotteryId, thisTicketId);
            if (highestBracket < 4) {
                uint256 rewardForTicketId = _calculateRewardsForTicketId(
                    _lotteryId,
                    thisTicketId,
                    highestBracket
                );
                rewardToTransfer += rewardForTicketId;
            }

            unchecked {
                ++i;
            }
        }

        // Transfer the prize to winner
        DegisToken.transfer(msg.sender, rewardToTransfer);

        lotteries[_lotteryId].pendingRewards -= rewardToTransfer;

        emit TicketsClaim(msg.sender, rewardToTransfer, _lotteryId);
    }

    /**
     * @notice Start a new lottery round
     *
     * @param _endTime          EndTime of the lottery
     * @param _ticketPrice      Price of each ticket without discount
     * @param _rewardsBreakdown Breakdown of rewards per bracket (must sum to 10,000)(100 <=> 1)
     * @param _fee              Treasury fee (10,000 = 100%, 100 = 1%)
     */
    function startLottery(
        uint256 _endTime,
        uint256 _ticketPrice,
        uint256[4] calldata _rewardsBreakdown,
        uint256 _fee
    ) external onlyOwner {
        require(
            (currentLotteryId == 0) ||
                (lotteries[currentLotteryId].status == Status.Claimable),
            "Wrong status"
        );

        require(_fee <= MAX_TREASURY_FEE, "Treasury fee too high");

        require(
            (_rewardsBreakdown[0] +
                _rewardsBreakdown[1] +
                _rewardsBreakdown[2] +
                _rewardsBreakdown[3]) <= 10000,
            "Rewards breakdown too high"
        );

        // If price is provided, use it
        // Or use the default price
        uint256 price = _ticketPrice > 0 ? _ticketPrice : DEFAULT_PRICE;

        // Gas savings
        uint256 currentId = ++currentLotteryId;

        Lottery storage newLottery = lotteries[currentId];

        newLottery.status = Status.Open;
        newLottery.startTime = uint32(block.timestamp);
        newLottery.endTime = uint32(_endTime);
        newLottery.ticketPrice = price;
        newLottery.rewardsBreakdown = _rewardsBreakdown;
        newLottery.treasuryFee = uint8(_fee);
        newLottery.amountCollected = pendingInjectionNextLottery;
        newLottery.firstTicketId = currentTicketId;

        emit LotteryOpen(
            currentId,
            block.timestamp,
            _endTime,
            price,
            _rewardsBreakdown,
            pendingInjectionNextLottery
        );

        // Clear record for pending injection
        pendingInjectionNextLottery = 0;
    }

    /**
     * @notice Close a lottery
     * @param _lotteryId lottery round
     * @dev Callable only by the owner
     */
    function closeLottery(uint256 _lotteryId) external onlyOwner nonReentrant {
        require(
            lotteries[_lotteryId].status == Status.Open,
            "this lottery is not open currently"
        );

        // require(
        //     block.timestamp > lotteries[_lotteryId].endTime,
        //     "this lottery has not reached the end time, only can be closed after the end time"
        // );

        // Request a random number from the generator
        randomGenerator.getRandomNumber();

        // Update the lottery status to "Close"
        lotteries[_lotteryId].status = Status.Close;

        emit LotteryClose(_lotteryId);
    }

    /**
     * @notice Draw the final number, calculate reward in Degis for each group,
               and make this lottery claimable (need to wait for the random generator)
     *
     * @param _lotteryId     Lottery round
     * @param _autoInjection Auto inject funds into next lottery
     */
    function drawFinalNumberAndMakeLotteryClaimable(
        uint256 _lotteryId,
        bool _autoInjection
    ) external onlyOwner nonReentrant {
        require(
            lotteries[_lotteryId].status == Status.Close,
            "Lottery not closed"
        );
        require(
            _lotteryId == randomGenerator.latestLotteryId(),
            "Final number not drawn"
        );
        require(treasury != address(0), "Treasury is not set");

        // Get the final lucky numbers from randomGenerator
        uint32 finalNumber = randomGenerator.randomResult();

        Lottery storage lottery = lotteries[_lotteryId];

        // Gas savings
        uint256 totalPrize = lottery.amountCollected;

        // Prize distributed to users
        uint256 amountToWinners = (totalPrize * 8000) / 10000;

        // (20% - treasuryFee) will go to next round
        uint256 amountToNextLottery = (totalPrize *
            (2000 - lottery.treasuryFee)) / 10000;

        // Remaining part goes to treasury
        uint256 amountToTreasury = totalPrize -
            amountToWinners -
            amountToNextLottery;

        // Initialize a number to count addresses in all the previous bracket
        // Ensure that a ticket is not counted several times in different brackets
        uint256 numberAddressesInPreviousBracket;

        // Calculate prizes for each bracket, starting from the highest one
        for (uint32 i; i < 4; ) {
            uint32 j = 3 - i;

            // Get transformed winning number
            uint32 transformedWinningNumber = _bracketCalculator[j] +
                (finalNumber % (uint32(10)**(j + 1)));

            // Amount of winning tickets for this number
            uint256 winningAmount = _numberTicketsPerLotteryId[_lotteryId][
                transformedWinningNumber
            ];

            // Amount of winners for this bracket
            // Remove those already have higher bracket reward
            lottery.countWinnersPerBracket[j] =
                winningAmount -
                numberAddressesInPreviousBracket;

            // Check if there are winners for this bracket
            if (winningAmount != numberAddressesInPreviousBracket) {
                // B. If rewards at this bracket are > 0, calculate, else, report the numberAddresses from previous bracket
                if (lottery.rewardsBreakdown[j] != 0) {
                    lottery.rewardPerTicketInBracket[j] =
                        ((lottery.rewardsBreakdown[j] * amountToWinners) /
                            (winningAmount -
                                numberAddressesInPreviousBracket)) /
                        10000;

                    lottery.pendingRewards +=
                        (lottery.rewardsBreakdown[j] * amountToWinners) /
                        10000;
                }
                // No winners, prize added to the amount to withdraw to treasury
            } else {
                lottery.rewardPerTicketInBracket[j] = 0;
                amountToTreasury +=
                    (lottery.rewardsBreakdown[j] * amountToWinners) /
                    10000;
            }

            // Update numberAddressesInPreviousBracket
            numberAddressesInPreviousBracket = winningAmount;

            unchecked {
                ++i;
            }
        }

        // Update internal statuses for this lottery round
        lottery.finalNumber = finalNumber;
        lottery.status = Status.Claimable;
        lottery.firstTicketIdNextRound = currentTicketId;

        // If auto injection is on, reinject funds into next lottery
        if (_autoInjection) {
            pendingInjectionNextLottery = amountToNextLottery;
        }

        // Transfer prize to treasury address
        if (amountToTreasury > 0) {
            DegisToken.transfer(treasury, amountToTreasury);
        }

        emit LotteryNumberDrawn(
            currentLotteryId,
            finalNumber, // final result for this round
            numberAddressesInPreviousBracket // total winners
        );
    }

    /**
     * @notice Change the random generator contract address
     *
     * @dev The calls to functions are used to verify the new generator implements them properly.
     *      It is necessary to wait for the VRF response before starting a round.
     *
     * @param _randomGeneratorAddress address of the random generator
     */
    function changeRandomGenerator(address _randomGeneratorAddress)
        external
        onlyOwner
    {
        // We do not change the generator when a round has not been claimable
        require(
            lotteries[currentLotteryId].status == Status.Claimable,
            "Round not claimable"
        );

        // Request a random number from the new generator
        IRandomNumberGenerator(_randomGeneratorAddress).getRandomNumber();

        // Get the finalNumber based on the randomResult
        IRandomNumberGenerator(_randomGeneratorAddress).randomResult();

        // Set the new address
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

        emit NewRandomGenerator(_randomGeneratorAddress);
    }

    /**
     * @notice Inject funds
     *
     * @dev Those DEG transferred to this contract but not by this function
     *      will not be counted for prize pools
     *
     * @param _amount DEG amount to inject
     */
    function injectFunds(uint256 _amount) external {
        uint256 currentRound = currentLotteryId;

        // Only inject when current round is open
        require(
            lotteries[currentRound].status == Status.Open,
            "Round not open"
        );

        // Update the amount collected for this round
        lotteries[currentRound].amountCollected += _amount;

        // Transfer DEG
        DegisToken.transferFrom(msg.sender, address(this), _amount);

        emit LotteryInjection(currentRound, _amount);
    }

    /**
     * @notice Recover wrong tokens sent to the contract, only by the owner
     *          All tokens except Degis are wrong tokens
     *
     * @param _tokenAddress Address of the token to withdraw
     * @param _tokenAmount  Token amount to withdraw
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(_tokenAddress != address(DegisToken), "Cannot be DEGIS token");

        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Calculate total price when buying many tickets
     *         1 ticket = 100%  2 tickets = 98%  3 tickets = 98% * 98 % ...
     *         Maximum discount: 98% ^ 10 ≈ 82%
     *
     * @param _price Ticket price in DEG
     * @param _num   Number of tickets to be bought
     *
     * @return totalPrice Total price in DEG
     */
    function _calculateTotalPrice(uint256 _price, uint256 _num)
        internal
        pure
        returns (uint256 totalPrice)
    {
        totalPrice = (_price * _num * (DISCOUNT_DIVISOR**_num)) / 100**_num;
    }

    /**
     * @notice returns highest bracket a ticket number falls into
     *
     * @param _lotteryId Lottery round
     * @param _ticketId  Ticket id
     */
    function _getBracket(uint256 _lotteryId, uint256 _ticketId)
        internal
        view
        returns (uint32 highestBracket)
    {
        uint32 userNumber = tickets[_ticketId].number;

        // Retrieve the winning number combination
        uint32 finalNumber = lotteries[_lotteryId].finalNumber;

        // 3 => highest prize
        // 4 => no prize
        highestBracket = 4;
        for (uint32 i = 1; i <= 4; ++i) {
            if (finalNumber % (uint32(10)**i) == userNumber % (uint32(10)**i)) {
                highestBracket = i - 1;
            } else {
                break;
            }
        }
    }

    /**
     * @notice Calculate rewards for a given ticket
     *
     * @param _lotteryId Lottery id
     * @param _ticketId  Ticket id
     * @param _bracket   Bracket for the ticketId to verify the claim and calculate rewards
     */
    function _calculateRewardsForTicketId(
        uint256 _lotteryId,
        uint256 _ticketId,
        uint32 _bracket
    ) internal view returns (uint256) {
        // Retrieve the user number combination from the ticketId
        uint32 userNumber = tickets[_ticketId].number;

        // Retrieve the winning number combination
        uint32 finalNumber = lotteries[_lotteryId].finalNumber;

        // Apply transformation to verify the claim provided by the user is true
        uint32 ts = uint32(10)**(_bracket + 1);

        uint32 transformedWinningNumber = _bracketCalculator[_bracket] +
            (finalNumber % ts);
        uint32 transformedUserNumber = _bracketCalculator[_bracket] +
            (userNumber % ts);

        // Confirm that the two transformed numbers are the same
        if (transformedWinningNumber == transformedUserNumber) {
            return lotteries[_lotteryId].rewardPerTicketInBracket[_bracket];
        } else {
            return 0;
        }
    }

    /**
     * @notice Reverse the ticket number
     *         E.g. User want to buy "1234"
     *              The input number will be 11234
     *              The reversed output will be 14321
     *
     * @param _number Input ticket number
     *
     * @return reversedNumber Reversed number + 10000
     */
    function _reverseTicketNumber(uint256 _number)
        public
        pure
        returns (uint32)
    {
        uint256 initNumber = _number - 10**4;
        uint256 singleNumber;
        uint256 reversedNumber;

        for (uint256 i; i < 4; ) {
            singleNumber = initNumber % 10;

            reversedNumber = reversedNumber * 10 + singleNumber;

            initNumber /= 10;

            unchecked {
                ++i;
            }
        }
        return uint32(reversedNumber + 10000);
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IRandomNumberGenerator {
    /**
     * @notice Views random result
     */
    function getRandomNumber() external;

    function randomResult() external view returns (uint32);

    function latestLotteryId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library MathLib {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return
                int128(
                    int256(
                        (uint256(int256(log_2(x))) *
                            0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128
                    )
                );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../utils/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRandomNumberGenerator.sol";

contract DegisLottery is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    IERC20 public DEGToken;
    IERC20 public USDToken;
    IRandomNumberGenerator public randomGenerator;

    address public operatorAddress;

    uint256 public constant TICKET_PRICE = 10 ether;

    struct Tickets {
        mapping(uint256 => uint256) ticketsWeight;
        mapping(uint256 => uint256) ticketsAmount;
    }
    Tickets poolTickets;
    mapping(address => Tickets) usersTickets;

    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }
    struct LotteryInfo {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256[4] stageProportion;
        uint256[4] stageReward;
        uint256[4] stageAmount;
        uint256[4] stageWeight;
        uint256 totalRewards;
        uint256 pendingRewards;
        uint256 finalNumber;
    }
    mapping(uint256 => LotteryInfo) public lotteries;

    uint256 public rewardsToNextLottery;

    uint256 public allPendingRewards;

    uint256 public rewardBalance;

    uint256 public currentLotteryId; // Total Rounds

    mapping(address => uint256) public checkPoint;
    mapping(address => uint256) public usersTotalRewards;

    mapping(address => mapping(uint256 => uint256)) public usersRewards;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event TicketsPurchase(
        address indexed buyer,
        uint256 indexed lotteryId,
        uint256 totalAmount
    );
    event TicketsRedeem(
        address indexed redeemer,
        uint256 indexed lotteryId,
        uint256 totalAmount
    );
    event LotteryOpen(
        uint256 indexed lotteryId,
        uint256 startTime,
        uint256 endTime,
        uint256 totalRewards
    );
    event LotteryNumberDrawn(
        uint256 indexed lotteryId,
        uint256 finalNumber,
        uint256 pendingRewards
    );

    event ReceiveRewards(
        address indexed claimer,
        uint256 amount,
        uint256 indexed lotteryId
    );

    event LotteryClose(uint256 indexed lotteryId, uint256 timestamp);

    event LotteryFundInjection(
        uint256 indexed lotteryId,
        uint256 injectedAmount
    );
    event RandomNumberGeneratorChanged(
        address oldGenerator,
        address newGenerator
    );
    event OperatorAddressChanged(address oldOperator, address newOperator);
    event AdminTokenRecovery(address indexed token, uint256 amount);

    event UpdateBalance(
        uint256 lotteryId,
        uint256 oldBalance,
        uint256 newBalance
    );

    /**
     * @notice Constructor function
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _DEGTokenAddress Address of the DEG token (for buying tickets)
     * @param _USDTokenAddress Address of the USD token (for prize distribution)
     * @param _randomGeneratorAddress Address of the RandomGenerator contract used to work with ChainLink VRF
     */
    constructor(
        address _DEGTokenAddress,
        address _USDTokenAddress,
        address _randomGeneratorAddress
    ) Ownable(msg.sender) {
        DEGToken = IERC20(_DEGTokenAddress);
        USDToken = IERC20(_USDTokenAddress);
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Not contract address
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     * @notice Only the operator or owner
     */
    modifier onlyOperator() {
        require(
            msg.sender == operatorAddress || msg.sender == owner(),
            "Not operator or owner"
        );
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function getCurrentRoundWeight() public view returns (uint256) {
        return ((currentLotteryId + 24) * 1000000) / (currentLotteryId + 12);
    }

    /**
     * @notice Get pool tickets info
     * @dev May be a huge number, avoid reading this frequently
     * @param _startIndex Start number
     * @param _stopIndex Stop number
     * @param _position Which level to check (0, 1, 2, 3), use 0 to check the 4-digit number
     */
    function getPoolTicketsInfo(
        uint256 _startIndex,
        uint256 _stopIndex,
        uint256 _position
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 length = _stopIndex - _startIndex + 1;

        uint256[] memory ticketsNumber = new uint256[](length);
        uint256[] memory ticketsAmount = new uint256[](length);
        uint256[] memory ticketsWeight = new uint256[](length);

        for (uint256 i = _startIndex; i <= _stopIndex; i++) {
            uint256 encodedNumber = _encodeNumber(i, _position);

            ticketsNumber[i - _startIndex] = i;
            ticketsAmount[i - _startIndex] = poolTickets.ticketsAmount[
                encodedNumber
            ];
            ticketsWeight[i - _startIndex] = poolTickets.ticketsWeight[
                encodedNumber
            ];
        }
        return (ticketsNumber, ticketsAmount, ticketsWeight);
    }

    /**
     * @notice Get user tickets info
     */
    function getUserTicketsInfo(
        address user,
        uint256 _startIndex,
        uint256 _stopIndex,
        uint256 position
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 length = _stopIndex - _startIndex + 1;

        uint256[] memory ticketsNumber = new uint256[](length);
        uint256[] memory ticketsAmount = new uint256[](length);
        uint256[] memory ticketsWeight = new uint256[](length);

        for (uint256 i = _startIndex; i <= _stopIndex; i++) {
            uint256 encodedNumber = _encodeNumber(i, position);
            ticketsNumber[i - _startIndex] = i;
            ticketsAmount[i - _startIndex] = usersTickets[user].ticketsAmount[
                encodedNumber
            ];
            ticketsWeight[i - _startIndex] = usersTickets[user].ticketsWeight[
                encodedNumber
            ];
        }
        return (ticketsNumber, ticketsAmount, ticketsWeight);
    }

    /**
     * @notice Get lottery stage info
     */
    function getLotteriesStageInfo(uint256 _lotteryId)
        external
        view
        returns (
            uint256[] memory stageProportion,
            uint256[] memory stageReward,
            uint256[] memory stageAmount,
            uint256[] memory stageWeight
        )
    {
        stageProportion = new uint256[](4);
        stageReward = new uint256[](4);
        stageAmount = new uint256[](4);
        stageWeight = new uint256[](4);

        for (uint256 i = 0; i < 4; i++) {
            stageProportion[i] = lotteries[_lotteryId].stageProportion[i];
            stageReward[i] = lotteries[_lotteryId].stageReward[i];
            stageAmount[i] = lotteries[_lotteryId].stageAmount[i];
            stageWeight[i] = lotteries[_lotteryId].stageWeight[i];
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set operator address
     * @dev Only callable by the owner
     * @param _operatorAddress address of the operator
     */
    function setOperatorAddress(address _operatorAddress) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");

        emit OperatorAddressChanged(operatorAddress, _operatorAddress);
        operatorAddress = _operatorAddress;
    }

    /**
     * @notice Set Random Number Generator contract address
     * @dev Only callable by the owner
     * @param _randomNumberGenerator Address of the Random Number Generator contract
     */
    function setRandomNumberGenerator(address _randomNumberGenerator)
        external
        onlyOwner
    {
        require(
            _randomNumberGenerator != address(0),
            "Can not be zero address"
        );
        emit RandomNumberGeneratorChanged(
            address(randomGenerator),
            _randomNumberGenerator
        );

        randomGenerator = IRandomNumberGenerator(_randomNumberGenerator);
    }

    /**
     * @notice Change the end time of current round (only if it was set a wrong number)
     * @dev Normally this function is not needed
     * @param _endTime New end time
     */
    function setEndTime(uint256 _endTime) external onlyOwner {
        uint256 currentId = currentLotteryId;
        require(
            lotteries[currentId].status == Status.Open,
            "Only change endtime when Lottery open"
        );

        lotteries[currentId].endTime = _endTime;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Start the lottery
     * @dev Callable only by operator
     * @param _endTime EndTime of the lottery (UNIX timestamp in s)
     * @param _stageProportion Breakdown of rewards per bracket
     * @dev Stage proportion must sum to 10,000(100 <=> 1)
     */
    function startLottery(
        uint256 _endTime,
        uint256[4] calldata _stageProportion
    ) external onlyOperator {
        require(
            (currentLotteryId == 0) ||
                (lotteries[currentLotteryId].status == Status.Claimable),
            "Not time to start lottery"
        );

        require(
            (_stageProportion[0] +
                _stageProportion[1] +
                _stageProportion[2] +
                _stageProportion[3]) <= 10000,
            "Total rewards of each bracket should <= 10000"
        );

        updateBalance();

        // gas saving
        uint256 id = ++currentLotteryId;

        // Do not init those have default values at first
        LotteryInfo storage newLottery = lotteries[id];
        newLottery.status = Status.Open;
        newLottery.startTime = block.timestamp;
        newLottery.endTime = _endTime;
        newLottery.stageProportion = _stageProportion;
        newLottery.totalRewards = rewardsToNextLottery;

        // First emit the event
        emit LotteryOpen(id, block.timestamp, _endTime, rewardsToNextLottery);

        // Clear rewards to next lottery
        rewardsToNextLottery = 0;
    }

    /**
     * @notice Close a lottery
     * @dev Callable by any address and need to meet the endtime condition
     * @dev Normally it's automatically called by our contract
     */
    function closeLottery() external nonReentrant {
        updateBalance();

        // gas saving
        uint256 currentId = currentLotteryId;

        require(
            lotteries[currentId].status == Status.Open,
            "Current lottery is not open"
        );

        require(
            block.timestamp >= lotteries[currentId].endTime,
            "Not time to close lottery"
        );

        lotteries[currentId].endTime = block.timestamp;

        // Request a random number from the generator
        // With VRF, the response may need some time to be generated
        randomGenerator.getRandomNumber();

        // Update the lottery status
        lotteries[currentId].status = Status.Close;

        emit LotteryClose(currentId, block.timestamp);
    }

    /**
     * @notice Buy tickets for the current lottery round
     * @dev Can not be called by a smart contract
     * @param _ticketNumbers array of ticket numbers between 0 and 9999
     * @param _ticketAmounts array of ticket amount
     */
    function buyTickets(
        uint256[] calldata _ticketNumbers,
        uint256[] calldata _ticketAmounts
    ) external notContract nonReentrant {
        require(_ticketNumbers.length != 0, "No tickets are being bought");
        require(
            _ticketNumbers.length == _ticketAmounts.length,
            "Different lengths"
        );

        // gas saving
        uint256 currentId = currentLotteryId;

        require(
            lotteries[currentId].status == Status.Open,
            "Current lottery is not open"
        );

        if (checkPoint[msg.sender] == 0) {
            checkPoint[msg.sender] = currentId;
        }

        if (checkPoint[msg.sender] < currentId) {
            receiveRewards(currentId - 1);
        }

        // Get the weight of current round (round is a global content)
        uint256 roundWeight = getCurrentRoundWeight();

        // Total amount of tickets will be bought
        uint256 totalAmount;

        for (uint256 i = 0; i < _ticketNumbers.length; i++) {
            _buyTicket(
                poolTickets,
                _ticketNumbers[i],
                _ticketAmounts[i],
                roundWeight * _ticketAmounts[i]
            );
            _buyTicket(
                usersTickets[msg.sender],
                _ticketNumbers[i],
                _ticketAmounts[i],
                roundWeight * _ticketAmounts[i]
            );
            totalAmount += _ticketAmounts[i];
        }

        // Transfer degis
        DEGToken.safeTransferFrom(
            msg.sender,
            address(this),
            totalAmount * TICKET_PRICE
        );

        emit TicketsPurchase(msg.sender, currentId, totalAmount);
    }

    /**
     * @notice Redeem tickets for all lottery
     * @param _ticketNumbers Array of ticket numbers
     * @dev Callable by users
     */
    function redeemTickets(uint256[] calldata _ticketNumbers)
        external
        notContract
        nonReentrant
    {
        require(_ticketNumbers.length != 0, "No tickets are being redeem");

        uint256 currentId = currentLotteryId;

        require(
            lotteries[currentId].status == Status.Open,
            "Sorry, current lottery is not open"
        );

        if (checkPoint[msg.sender] < currentId) {
            receiveRewards(currentId - 1);
        }

        uint256 totalAmount;
        for (uint256 i; i < _ticketNumbers.length; i++) {
            uint256 encodedNumber = _encodeNumber(_ticketNumbers[i], 3);

            uint256 ticketAmount = usersTickets[msg.sender].ticketsAmount[
                encodedNumber
            ];
            uint256 ticketWeight = usersTickets[msg.sender].ticketsWeight[
                encodedNumber
            ];
            _redeemTicket(
                poolTickets,
                _ticketNumbers[i],
                ticketAmount,
                ticketWeight
            );
            _redeemTicket(
                usersTickets[msg.sender],
                _ticketNumbers[i],
                ticketAmount,
                ticketWeight
            );
            totalAmount += ticketAmount;
        }

        require(totalAmount != 0, "No tickets are being redeemed");

        DEGToken.safeTransfer(msg.sender, totalAmount * TICKET_PRICE);

        emit TicketsRedeem(msg.sender, currentId, totalAmount);
    }

    function updateBalance() public {
        uint256 curBalance = USDToken.balanceOf(address(this));
        uint256 preBalance = rewardBalance;

        uint256 currentId = currentLotteryId;

        Status currentStatus = lotteries[currentId].status;

        if (currentStatus == Status.Open) {
            lotteries[currentId].totalRewards =
                lotteries[currentId].totalRewards +
                curBalance -
                preBalance;
        } else {
            rewardsToNextLottery =
                rewardsToNextLottery +
                curBalance -
                preBalance;
        }

        rewardBalance = curBalance;

        emit UpdateBalance(currentId, preBalance, curBalance);
    }

    /**
     * @notice Draw the final number, calculate reward in DEG for each group,
     *         and make this lottery claimable (need to wait for the random generator)
     * @dev Callable by any address
     */
    function drawLottery() external nonReentrant {
        uint256 currentId = currentLotteryId;
        require(
            lotteries[currentId].status == Status.Close,
            "this lottery has not closed, you should first close it"
        );
        require(
            currentId == randomGenerator.latestLotteryId(),
            "the final number has not been drawn"
        );

        updateBalance();

        // Get the final lucky numbers from randomGenerator
        uint256 finalNumber = randomGenerator.randomResult();

        uint256 lastAmount;
        uint256 lastWeight;

        LotteryInfo storage currentLottery = lotteries[currentId];

        uint256 tempPendingRewards;

        for (uint256 j = 0; j < 4; j++) {
            uint256 i = 3 - j;

            uint256 encodedNumber = _encodeNumber(finalNumber, i);

            currentLottery.stageAmount[i] =
                poolTickets.ticketsAmount[encodedNumber] -
                lastAmount;
            lastAmount = poolTickets.ticketsAmount[encodedNumber];

            currentLottery.stageWeight[i] =
                poolTickets.ticketsWeight[encodedNumber] -
                lastWeight;
            lastWeight = poolTickets.ticketsWeight[encodedNumber];

            if (currentLottery.stageAmount[i] == 0)
                currentLottery.stageReward[i] = 0;
            else
                currentLottery.stageReward[i] =
                    (currentLottery.stageProportion[i] *
                        currentLottery.totalRewards) /
                    10000;

            tempPendingRewards += currentLottery.stageReward[i];
        }
        currentLottery.pendingRewards += tempPendingRewards;

        rewardsToNextLottery =
            currentLottery.totalRewards -
            currentLottery.pendingRewards;

        require(
            allPendingRewards + currentLottery.totalRewards <=
                USDToken.balanceOf(address(this)),
            "Wrong USD amount"
        );

        // Update internal statuses for this lottery round
        currentLottery.finalNumber = finalNumber;
        currentLottery.status = Status.Claimable;

        // Update all pending rewards
        allPendingRewards += currentLottery.pendingRewards;

        emit LotteryNumberDrawn(
            currentLotteryId,
            finalNumber, // final result for this round
            lotteries[currentLotteryId].pendingRewards
        );
    }

    /**
     * @notice Receive award from a lottery
     * @param _lotteryId lottery id
     * @param user user address
     */
    function pendingReward(uint256 _lotteryId, address user)
        public
        view
        returns (uint256 reward)
    {
        uint256 lastWeight;
        uint256 finalNumber = lotteries[_lotteryId].finalNumber;

        for (uint256 j; j < 4; j++) {
            uint256 i = 3 - j;

            uint256 encodedNumber = _encodeNumber(finalNumber, i);

            uint256 weight = usersTickets[user].ticketsWeight[encodedNumber] -
                lastWeight;

            lastWeight += weight;

            if (lotteries[_lotteryId].stageWeight[i] != 0) {
                reward +=
                    (lotteries[_lotteryId].stageReward[i] * weight) /
                    lotteries[_lotteryId].stageWeight[i];
            }
        }
    }

    /**
     * @notice Receive all awards from lottery before lottery id
     * @param _lotteryId lottery id
     * @dev Callable by users only, not contract!
     */
    function receiveRewards(uint256 _lotteryId) public notContract {
        require(
            lotteries[_lotteryId].status == Status.Claimable,
            "This round not claimable"
        );

        require(
            checkPoint[msg.sender] <= _lotteryId,
            "All rewards have been received"
        );

        uint256 reward;

        for (
            uint256 round = checkPoint[msg.sender];
            round <= _lotteryId;
            round++
        ) {
            uint256 roundReward = pendingReward(round, msg.sender);
            reward += roundReward;

            lotteries[round].pendingRewards -= roundReward;

            usersRewards[msg.sender][round] = roundReward;
            usersTotalRewards[msg.sender] += roundReward;
        }
        checkPoint[msg.sender] = _lotteryId + 1;

        allPendingRewards -= reward;

        // Transfer the prize to winner
        if (reward != 0) {
            USDToken.safeTransfer(msg.sender, reward);
        }
        emit ReceiveRewards(msg.sender, reward, _lotteryId);
    }

    /**
     * @notice Recover wrong tokens sent to the contract
     * @dev    Only callable by the owner
     * @dev    All tokens except DEG and USD are wrong tokens
     * @param _tokenAddress the address of the token to withdraw
     * @param _tokenAmount token amount to withdraw
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(_tokenAddress != address(DEGToken), "Cannot recover DEG token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Update the status to finish buying a ticket
     * @param tickets Tickets to update
     * @param _ticketNumber Original number of the ticket
     * @param _ticketAmount Amount of this number are being bought
     * @param _ticketWeight Weight of this ticket, depends on round
     */
    function _buyTicket(
        Tickets storage tickets,
        uint256 _ticketNumber,
        uint256 _ticketAmount,
        uint256 _ticketWeight
    ) internal {
        for (uint256 i; i < 4; i++) {
            uint256 encodedNumber = _encodeNumber(_ticketNumber, i);
            tickets.ticketsWeight[encodedNumber] += _ticketWeight;
            tickets.ticketsAmount[encodedNumber] += _ticketAmount;
        }
    }

    /**
     * @notice Update the status to finish redeeming a ticket
     * @param tickets Tickets to update
     * @param _ticketNumber Original number of the ticket
     * @param _ticketAmount Amount of this number are being redeemed
     * @param _ticketWeight Weight of this ticket, depends on round
     */
    function _redeemTicket(
        Tickets storage tickets,
        uint256 _ticketNumber,
        uint256 _ticketAmount,
        uint256 _ticketWeight
    ) internal {
        for (uint256 i = 0; i < 4; i++) {
            uint256 encodedNumber = _encodeNumber(_ticketNumber, i);
            tickets.ticketsWeight[encodedNumber] -= _ticketWeight;
            tickets.ticketsAmount[encodedNumber] -= _ticketAmount;
        }
    }

    /**
     * @notice Get the encoded number form
     * @param _number The original number
     * @param _position The number's position/level (0, 1, 2, 3)
     */
    function _encodeNumber(uint256 _number, uint256 _position)
        internal
        pure
        returns (uint256)
    {
        return (_number % (10**(_position + 1))) + _position * 10000;
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function _viewUserTicketAmount(address user, uint256 encodedNumber)
        internal
        view
        returns (uint256)
    {
        return usersTickets[user].ticketsAmount[encodedNumber];
    }

    function _viewUserTicketWeight(address user, uint256 encodedNumber)
        internal
        view
        returns (uint256)
    {
        return usersTickets[user].ticketsWeight[encodedNumber];
    }

    function viewUserAllTicketsInfo(address user, uint256 maxAmount)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256
        )
    {
        uint256[] memory ticketsNumber = new uint256[](maxAmount);
        uint256[] memory ticketsAmount = new uint256[](maxAmount);
        uint256[] memory ticketsWeight = new uint256[](maxAmount);

        uint256 amount;
        uint256 number;
        uint256 i0;
        uint256 i1;
        uint256 i2;
        uint256 i3;

        for (i0; i0 <= 9; i0++) {
            number = i0;
            if (_viewUserTicketAmount(user, _encodeNumber(number, 0)) == 0)
                continue;
            for (i1 = 0; i1 <= 9; i1++) {
                number = i0 + i1 * 10;
                if (_viewUserTicketAmount(user, _encodeNumber(number, 1)) == 0)
                    continue;
                for (i2 = 0; i2 <= 9; i2++) {
                    number = i0 + i1 * 10 + i2 * 100;
                    if (
                        _viewUserTicketAmount(user, _encodeNumber(number, 2)) ==
                        0
                    ) continue;
                    for (i3 = 0; i3 <= 9; i3++) {
                        number = i0 + i1 * 10 + i2 * 100 + i3 * 1000;
                        if (
                            _viewUserTicketAmount(
                                user,
                                _encodeNumber(number, 3)
                            ) == 0
                        ) continue;
                        ticketsNumber[amount] = number;
                        ticketsAmount[amount] = _viewUserTicketAmount(
                            user,
                            _encodeNumber(number, 3)
                        );
                        ticketsWeight[amount] = _viewUserTicketWeight(
                            user,
                            _encodeNumber(number, 3)
                        );
                        amount++;
                        if (amount >= maxAmount)
                            return (
                                ticketsNumber,
                                ticketsAmount,
                                ticketsWeight,
                                amount
                            );
                    }
                }
            }
        }
        return (ticketsNumber, ticketsAmount, ticketsWeight, amount);
    }

    function viewUserRewardsInfo(
        address user,
        uint256 _startRound,
        uint256 _endRound
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        require(
            _startRound <= _endRound,
            "End lottery smaller than start lottery"
        );
        require(_endRound <= currentLotteryId, "End lottery round not open");

        require(
            lotteries[_endRound].status == Status.Claimable,
            "this round of lottery are not ready for claiming"
        );

        uint256[] memory lotteryIds = new uint256[](
            _endRound - _startRound + 1
        );
        uint256[] memory userRewards = new uint256[](
            _endRound - _startRound + 1
        );
        uint256[] memory userDrawed = new uint256[](
            _endRound - _startRound + 1
        );
        uint256 userStartLotteryId = checkPoint[user];
        for (uint256 i = _startRound; i <= _endRound; i++) {
            lotteryIds[i - _startRound] = i;
            if (i < userStartLotteryId) {
                userDrawed[i - _startRound] = 1;
                userRewards[i - _startRound] = usersRewards[user][i];
            } else {
                userDrawed[i - _startRound] = 0;
                userRewards[i - _startRound] = pendingReward(i, user);
            }
        }
        return (lotteryIds, userRewards, userDrawed);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(
            _ADMIN_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
        );
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation()
        external
        ifAdmin
        returns (address implementation_)
    {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        ifAdmin
    {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(
            msg.sender != _getAdmin(),
            "TransparentUpgradeableProxy: admin cannot fallback to proxy target"
        );
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.10;

import "./TransparentUpgradeableProxy.sol";
import "../utils/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"5c60da1b"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"f851a440"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(
        TransparentUpgradeableProxy proxy,
        address newAdmin
    ) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation)
        public
        virtual
        onlyOwner
    {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {OwnableWithoutContext} from "../utils/OwnableWithoutContext.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IDegisToken} from "../tokens/interfaces/IDegisToken.sol";
import {Math} from "../libraries/Math.sol";
import {IVeDEG} from "../governance/interfaces/IVeDEG.sol";

/**
 * @title  Farming Pool
 * @notice This contract is for LPToken mining on Degis
 * @dev    The pool id starts from 1 rather than 0
 *         The degis reward is calculated by timestamp rather than block number
 *
 *         VeDEG will boost the farming speed by having a extra reward type
 *         The extra reward is shared by those staking lptokens with veDEG balances
 *         Every time the veDEG balance change, the reward will be updated
 */
contract FarmingPool is OwnableWithoutContext, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IDegisToken;
    using Math for uint256;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    string public constant name = "Degis LP Farming Pool";

    // The reward token is degis
    IDegisToken public degis;

    // The bonus reward depends on veDEG
    IVeDEG public veDEG;

    // SCALE/Precision used for calculating rewards
    uint256 public constant SCALE = 1e12;

    // PoolId starts from 1
    uint256 public _nextPoolId;

    // Farming starts from a certain block timestamp
    // To keep the same with naughty price pools, we change from block numbers to timestamps
    uint256 public startTimestamp;

    struct PoolInfo {
        address lpToken; // LPToken address
        uint256 basicDegisPerSecond; // Basic Reward speed
        uint256 bonusDegisPerSecond; // Bonus reward speed
        uint256 lastRewardTimestamp; // Last reward timestamp
        uint256 accDegisPerShare; // Accumulated degis per share (for those without veDEG boosting)
        uint256 accDegisPerBonusShare; // Accumulated degis per bonus share (for those with veDEG boosting)
        uint256 totalBonus; // Total bonus factors
    }
    PoolInfo[] public poolList;

    // lptoken address => poolId
    mapping(address => uint256) public poolMapping;

    // poolId => alreadyFarming
    mapping(uint256 => bool) public isFarming;

    struct UserInfo {
        uint256 rewardDebt; // degis reward debt
        uint256 stakingBalance; // the amount of a user's staking in the pool
        uint256 bonus; // user bonus point (by veDEG balance)
    }
    // poolId => userAddress => userInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event StartTimestampChanged(uint256 startTimestamp);
    event Stake(address staker, uint256 poolId, uint256 amount);
    event Withdraw(address staker, uint256 poolId, uint256 amount);
    event Harvest(
        address staker,
        address rewardReceiver,
        uint256 poolId,
        uint256 pendingReward
    );
    event NewPoolAdded(
        address lpToken,
        uint256 basicDegisPerSecond,
        uint256 bonusDegisPerSecond
    );
    event FarmingPoolStarted(uint256 poolId, uint256 timestamp);
    event FarmingPoolStopped(uint256 poolId, uint256 timestamp);
    event DegisRewardChanged(
        uint256 poolId,
        uint256 basicDegisPerSecond,
        uint256 bonusDegisPerSecond
    );
    event PoolUpdated(
        uint256 poolId,
        uint256 accDegisPerShare,
        uint256 accDegisPerBonusShare
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(address _degis) OwnableWithoutContext(msg.sender) {
        degis = IDegisToken(_degis);

        // Start from 1
        _nextPoolId = 1;

        poolList.push(
            PoolInfo({
                lpToken: address(0),
                basicDegisPerSecond: 0,
                bonusDegisPerSecond: 0,
                lastRewardTimestamp: 0,
                accDegisPerShare: 0,
                accDegisPerBonusShare: 0,
                totalBonus: 0
            })
        );
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice The address can not be zero
     */
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Zero address");
        _;
    }

    /**
     * @notice The pool is still in farming
     */
    modifier stillFarming(uint256 _poolId) {
        require(isFarming[_poolId], "Pool is not farming");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** View Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check the amount of pending degis reward
     * @param _poolId PoolId of this farming pool
     * @param _user User address
     * @return pendingDegisAmount Amount of pending degis
     */
    function pendingDegis(uint256 _poolId, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo memory poolInfo = poolList[_poolId];

        if (
            poolInfo.lastRewardTimestamp == 0 ||
            block.timestamp < poolInfo.lastRewardTimestamp ||
            block.timestamp < startTimestamp
        ) return 0;

        UserInfo memory user = userInfo[_poolId][_user];

        // Total lp token balance
        uint256 lp_balance = IERC20(poolInfo.lpToken).balanceOf(address(this));

        // Accumulated shares to be calculated
        uint256 accDegisPerShare = poolInfo.accDegisPerShare;
        uint256 accDegisPerBonusShare = poolInfo.accDegisPerBonusShare;

        if (lp_balance == 0) return 0;
        else {
            // If the pool is still farming, update the info
            if (isFarming[_poolId]) {
                // Deigs amount given to this pool
                uint256 timePassed = block.timestamp -
                    poolInfo.lastRewardTimestamp;
                uint256 basicReward = poolInfo.basicDegisPerSecond * timePassed;
                // Update accDegisPerShare
                // LPToken may have different decimals
                accDegisPerShare += (basicReward * SCALE) / lp_balance;

                // If there is any bonus reward
                if (poolInfo.totalBonus > 0) {
                    uint256 bonusReward = poolInfo.bonusDegisPerSecond *
                        timePassed;
                    accDegisPerBonusShare +=
                        (bonusReward * SCALE) /
                        poolInfo.totalBonus;
                }
            }

            // If the pool has stopped, not update the info
            uint256 pending = (user.stakingBalance *
                accDegisPerShare +
                user.bonus *
                accDegisPerBonusShare) /
                SCALE -
                user.rewardDebt;

            return pending;
        }
    }

    /**
     * @notice Get the total pool list
     * @return pooList Total pool list
     */
    function getPoolList() external view returns (PoolInfo[] memory) {
        return poolList;
    }

    /**
     * @notice Get a user's balance
     * @param _poolId Id of the pool
     * @param _user User address
     * @return balance User's balance (lpToken)
     */
    function getUserBalance(uint256 _poolId, address _user)
        external
        view
        returns (uint256)
    {
        return userInfo[_poolId][_user].stakingBalance;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Set Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setVeDEG(address _veDEG) external onlyOwner {
        veDEG = IVeDEG(_veDEG);
    }

    /**
     * @notice Set the start block timestamp
     * @param _startTimestamp New start block timestamp
     */
    function setStartTimestamp(uint256 _startTimestamp)
        external
        onlyOwner
        whenNotPaused
    {
        // Can only be set before any pool is added
        require(
            _nextPoolId == 1,
            "Can not set start timestamp after adding a pool"
        );

        startTimestamp = _startTimestamp;
        emit StartTimestampChanged(_startTimestamp);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Main Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Add a new lp into the pool
     * @dev Can only be called by the owner
     *      The reward speed can be 0 and set later by setDegisReward function
     * @param _lpToken LP token address
     * @param _basicDegisPerSecond Basic reward speed(per second) for this new pool
     * @param _bonusDegisPerSecond Bonus reward speed(per second) for this new pool
     * @param _withUpdate Whether update all pools' status
     */
    function add(
        address _lpToken,
        uint256 _basicDegisPerSecond,
        uint256 _bonusDegisPerSecond,
        bool _withUpdate
    ) public notZeroAddress(_lpToken) onlyOwner whenNotPaused {
        // Check if already exists, if the poolId is 0, that means not in the pool
        require(!_alreadyInPool(_lpToken), "Already in the pool");

        if (_bonusDegisPerSecond > 0)
            require(_basicDegisPerSecond > 0, "Only bonus");

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardTimestamp = block.timestamp > startTimestamp
            ? block.timestamp
            : startTimestamp;

        // Push this new pool into the list
        poolList.push(
            PoolInfo({
                lpToken: _lpToken,
                basicDegisPerSecond: _basicDegisPerSecond,
                bonusDegisPerSecond: _bonusDegisPerSecond,
                lastRewardTimestamp: lastRewardTimestamp,
                accDegisPerShare: 0,
                accDegisPerBonusShare: 0,
                totalBonus: 0
            })
        );

        // Store the poolId and set the farming status to true
        if (_basicDegisPerSecond > 0) isFarming[_nextPoolId] = true;

        poolMapping[_lpToken] = _nextPoolId++;

        emit NewPoolAdded(_lpToken, _basicDegisPerSecond, _bonusDegisPerSecond);
    }

    /**
     * @notice Update the degisPerSecond for a specific pool (set to 0 to stop farming)
     * @param _poolId Id of the farming pool
     * @param _basicDegisPerSecond New basic reward amount per second
     * @param _bonusDegisPerSecond New bonus reward amount per second
     * @param _withUpdate Whether update all pools
     */
    function setDegisReward(
        uint256 _poolId,
        uint256 _basicDegisPerSecond,
        uint256 _bonusDegisPerSecond,
        bool _withUpdate
    ) public onlyOwner whenNotPaused {
        // Ensure there already exists this pool
        require(poolList[_poolId].lastRewardTimestamp != 0, "Pool not exists");

        if (_bonusDegisPerSecond > 0)
            require(_basicDegisPerSecond > 0, "Only bonus");

        if (_withUpdate) massUpdatePools();
        else updatePool(_poolId);

        // Not farming now + reward > 0 => Restart
        if (isFarming[_poolId] == false && _basicDegisPerSecond > 0) {
            isFarming[_poolId] = true;
            emit FarmingPoolStarted(_poolId, block.timestamp);
        }

        if (_basicDegisPerSecond == 0) {
            isFarming[_poolId] = false;
            emit FarmingPoolStopped(_poolId, block.timestamp);
        } else {
            poolList[_poolId].basicDegisPerSecond = _basicDegisPerSecond;
            poolList[_poolId].bonusDegisPerSecond = _bonusDegisPerSecond;
            emit DegisRewardChanged(
                _poolId,
                _basicDegisPerSecond,
                _bonusDegisPerSecond
            );
        }
    }

    /**
     * @notice Stake LP token into the farming pool
     * @dev Can only stake to the pools that are still farming
     * @param _poolId Id of the farming pool
     * @param _amount Staking amount
     */
    function stake(uint256 _poolId, uint256 _amount)
        public
        nonReentrant
        whenNotPaused
        stillFarming(_poolId)
    {
        require(_amount > 0, "Can not stake zero");

        PoolInfo storage pool = poolList[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        // Must update first
        updatePool(_poolId);

        // First distribute the reward if exists
        if (user.stakingBalance > 0) {
            uint256 pending = (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
                SCALE -
                user.rewardDebt;

            // Real reward amount
            uint256 reward = _safeDegisTransfer(msg.sender, pending);
            emit Harvest(msg.sender, msg.sender, _poolId, reward);
        }

        // Actual deposit amount
        uint256 actualAmount = _safeLPTransfer(
            false,
            pool.lpToken,
            msg.sender,
            _amount
        );

        user.stakingBalance += actualAmount;

        if (address(veDEG) != address(0)) {
            // Update the user's bonus if veDEG boosting is on
            uint256 oldBonus = user.bonus;
            user.bonus = (user.stakingBalance * veDEG.balanceOf(msg.sender))
                .sqrt();
            // Update the pool's total bonus
            pool.totalBonus = pool.totalBonus + user.bonus - oldBonus;
        }

        user.rewardDebt =
            (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
            SCALE;

        emit Stake(msg.sender, _poolId, actualAmount);
    }

    /**
     * @notice Withdraw lptoken from the pool
     * @param _poolId Id of the farming pool
     * @param _amount Amount of lp tokens to withdraw
     */
    function withdraw(uint256 _poolId, uint256 _amount)
        public
        nonReentrant
        whenNotPaused
    {
        require(_amount > 0, "Zero amount");

        PoolInfo storage pool = poolList[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        require(user.stakingBalance >= _amount, "Not enough stakingBalance");

        // Update if the pool is still farming
        // Users can withdraw even after the pool stopped
        if (isFarming[_poolId]) updatePool(_poolId);

        uint256 pending = (user.stakingBalance *
            pool.accDegisPerShare +
            user.bonus *
            pool.accDegisPerBonusShare) /
            SCALE -
            user.rewardDebt;

        uint256 reward = _safeDegisTransfer(msg.sender, pending);
        emit Harvest(msg.sender, msg.sender, _poolId, reward);

        uint256 actualAmount = _safeLPTransfer(
            true,
            pool.lpToken,
            msg.sender,
            _amount
        );

        user.stakingBalance -= actualAmount;

        // Update the user's bonus when veDEG boosting is on
        if (address(veDEG) != address(0)) {
            uint256 oldBonus = user.bonus;
            user.bonus = (user.stakingBalance * veDEG.balanceOf(msg.sender))
                .sqrt();
            // Update the pool's total bonus
            pool.totalBonus = pool.totalBonus + user.bonus - oldBonus;
        }

        user.rewardDebt =
            (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
            SCALE;

        emit Withdraw(msg.sender, _poolId, actualAmount);
    }

    /**
     * @notice Harvest the degis reward and can be sent to another address
     * @param _poolId Id of the farming pool
     * @param _to Receiver of degis rewards
     */
    function harvest(uint256 _poolId, address _to)
        public
        nonReentrant
        whenNotPaused
    {
        // Only update the pool when it is still in farming
        if (isFarming[_poolId]) updatePool(_poolId);

        PoolInfo memory pool = poolList[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        uint256 pendingReward = (user.stakingBalance *
            pool.accDegisPerShare +
            user.bonus *
            pool.accDegisPerBonusShare) /
            SCALE -
            user.rewardDebt;

        require(pendingReward > 0, "No pending reward");

        // Update the reward debt
        user.rewardDebt =
            (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
            SCALE;

        // Transfer the reward
        uint256 reward = _safeDegisTransfer(_to, pendingReward);

        emit Harvest(msg.sender, _to, _poolId, reward);
    }

    /**
     * @notice Update the pool's reward status
     * @param _poolId Id of the farming pool
     */
    function updatePool(uint256 _poolId) public {
        PoolInfo storage pool = poolList[_poolId];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }

        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));

        // No LP deposited, then just update the lastRewardTimestamp
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 timePassed = block.timestamp - pool.lastRewardTimestamp;

        uint256 basicReward = timePassed * pool.basicDegisPerSecond;
        uint256 bonusReward = timePassed * pool.bonusDegisPerSecond;

        pool.accDegisPerShare += (basicReward * SCALE) / lpSupply;

        if (pool.totalBonus == 0) {
            pool.accDegisPerBonusShare = 0;
        } else {
            pool.accDegisPerBonusShare +=
                (bonusReward * SCALE) /
                pool.totalBonus;
        }

        // Don't forget to set the farming pool as minter
        degis.mintDegis(address(this), basicReward + bonusReward);

        pool.lastRewardTimestamp = block.timestamp;

        emit PoolUpdated(
            _poolId,
            pool.accDegisPerShare,
            pool.accDegisPerBonusShare
        );
    }

    /**
     * @notice Update all farming pools (except for those stopped ones)
     * @dev Can be called by anyone
     *      Only update those active pools
     */
    function massUpdatePools() public {
        uint256 length = poolList.length;
        for (uint256 poolId; poolId < length; poolId++) {
            if (isFarming[poolId] == false) continue;
            else updatePool(poolId);
        }
    }

    /**
     * @notice Update a user's bonus
     * @dev When veDEG has balance change
     *      Only called by veDEG contract
     * @param _user User address
     * @param _newVeDEGBalance New veDEG balance
     */
    function updateBonus(address _user, uint256 _newVeDEGBalance) external {
        require(msg.sender == address(veDEG), "Only veDEG contract");

        // loop over each pool : beware gas cost!
        uint256 length = poolList.length;

        for (uint256 poolId; poolId < length; ++poolId) {
            // Skip if the pool is not farming
            if (!isFarming[poolId]) continue;

            UserInfo storage user = userInfo[poolId][_user];
            // Skip if user doesn't have any deposit in the pool
            if (user.stakingBalance == 0) continue;

            PoolInfo storage pool = poolList[poolId];

            // first, update pool
            updatePool(poolId);

            // get oldFactor
            uint256 oldFactor = user.bonus; // get old factor
            // calculate newFactor
            uint256 newFactor = (_newVeDEGBalance * user.stakingBalance).sqrt();
            // update user factor
            user.bonus = newFactor;
            // update reward debt, take into account newFactor
            user.rewardDebt =
                (user.stakingBalance *
                    pool.accDegisPerShare +
                    newFactor *
                    pool.accDegisPerBonusShare) /
                SCALE;

            // Update the pool's total bonus
            pool.totalBonus = pool.totalBonus + newFactor - oldFactor;
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // ********************************** Internal Functions ********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check if a lptoken has been added into the pool before
     * @dev This can also be written as a modifier
     * @param _lpToken LP token address
     * @return _isInPool Wether this lp is already in pool
     */
    function _alreadyInPool(address _lpToken)
        internal
        view
        returns (bool _isInPool)
    {
        uint256 poolId = poolMapping[_lpToken];

        _isInPool = (poolId != 0) ? true : false;
    }

    /**
     * @notice Safe degis transfer (check if the pool has enough DEGIS token)
     * @param _to User's address
     * @param _amount Amount to transfer
     */
    function _safeDegisTransfer(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 poolDegisBalance = degis.balanceOf(address(this));
        require(poolDegisBalance > 0, "No Degis token in the pool");

        if (_amount > poolDegisBalance) {
            degis.safeTransfer(_to, poolDegisBalance);
            return (poolDegisBalance);
        } else {
            degis.safeTransfer(_to, _amount);
            return _amount;
        }
    }

    /**
     * @notice Finish the transfer of LP Token
     * @dev The lp token may have loss during transfer
     * @param _out Whether the lp token is out
     * @param _lpToken LP token address
     * @param _user User address
     * @param _amount Amount of lp tokens
     */
    function _safeLPTransfer(
        bool _out,
        address _lpToken,
        address _user,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 poolBalanceBefore = IERC20(_lpToken).balanceOf(address(this));

        if (_out) IERC20(_lpToken).safeTransfer(_user, _amount);
        else IERC20(_lpToken).safeTransferFrom(_user, address(this), _amount);

        uint256 poolBalanceAfter = IERC20(_lpToken).balanceOf(address(this));

        return
            _out
                ? poolBalanceBefore - poolBalanceAfter
                : poolBalanceAfter - poolBalanceBefore;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/
pragma solidity ^0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../tokens/interfaces/IDegisToken.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "hardhat/console.sol";
/**
 * @title  Purchase Incentive Vault
 * @notice This is the purchase incentive vault for staking buyer tokens
 *         Users first stake their buyer tokens and wait for distribution
 *         About every 24 hours, the reward will be calculated to users' account
 *         After disrtribution, reward will be updated
 *              but it still need to be manually claimed.
 *
 *         Buyer tokens can only be used once
 *         You can withdraw your buyer token within the same round (current round)
 *         They can not be withdrawed if the round was settled
 */
contract PurchaseIncentiveVault is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    string public constant name = "Degis Purchase Incentive Vault";

    // Buyer Token & Degis Token SCALE = 1e18
    uint256 public constant SCALE = 1e18;

    // Other contracts
    IERC20 buyerToken;
    IDegisToken degis;

    // Current round number
    uint256 public currentRound;

    // Degis reward per round
    uint256 public degisPerRound;

    // The interval will only limit the distribution (not the staking)
    uint256 public distributionInterval;

    // Last distribution block
    uint256 public lastDistribution;

    // Max round for one claim
    // When upgrade this parameter, redeploy the contract
    uint256 public constant MAX_ROUND = 50;

    struct RoundInfo {
        uint256 shares;
        address[] users;
        bool hasDistributed;
        uint256 degisPerShare;
    }
    mapping(uint256 => RoundInfo) public rounds;

    struct UserInfo {
        uint256 lastRewardRoundIndex;
        uint256[] pendingRounds;
    }
    mapping(address => UserInfo) public users;

    // User address => Round number => User shares
    mapping(address => mapping(uint256 => uint256)) public userSharesInRound;

    uint256[] threshold;
    uint256[] piecewise;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event DegisRewardChanged(
        uint256 oldRewardPerRound,
        uint256 newRewardPerRound
    );
    event DistributionIntervalChanged(uint256 oldInterval, uint256 newInterval);
    event Stake(
        address userAddress,
        uint256 currentRound,
        uint256 actualAmount
    );
    event Redeem(address userAddress, uint256 currentRound, uint256 amount);
    event RewardClaimed(address userAddress, uint256 userReward);
    event RoundSettled(uint256 currentRound, uint256 blockNumber);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error PIV__NotPassedInterval();
    error PIV__ZeroAmount();
    error PIV__NotEnoughBuyerTokens();
    error PIV__AlreadyDistributed();
    error PIV__NoPendingRound();
    error PIV__ClaimedAll();

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(address _buyerToken, address _degisToken)
        public
        initializer
    {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        // Initialize two tokens
        buyerToken = IERC20(_buyerToken);
        degis = IDegisToken(_degisToken);

        // Initialize the last distribution time
        lastDistribution = block.timestamp;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check if admins can distribute now
     * @dev Should pass the distribution interval
     */
    modifier hasPassedInterval() {
        if (block.timestamp - lastDistribution <= distributionInterval)
            revert PIV__NotPassedInterval();

        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get the amount of users in _round, used for distribution
     * @param _round Round number to check
     * @return totalUsers Total amount of users in _round
     */
    function getTotalUsersInRound(uint256 _round)
        external
        view
        returns (uint256)
    {
        return rounds[_round].users.length;
    }

    /**
     * @notice Get the user addresses in _round
     * @param _round Round number to check
     * @return users All user addresses in this round
     */
    function getUsersInRound(uint256 _round)
        external
        view
        returns (address[] memory)
    {
        return rounds[_round].users;
    }

    /**
     * @notice Get user's pending rounds
     * @param _user User address to check
     * @return pendingRounds User's pending rounds
     */
    function getUserPendingRounds(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return users[_user].pendingRounds;
    }

    /**
     * @notice Get your shares in the current round
     * @param _user Address of the user
     * @param _round Round number
     * @return userShares User's shares in the current round
     */
    function getUserShares(address _user, uint256 _round)
        external
        view
        returns (uint256)
    {
        return userSharesInRound[_user][_round];
    }

    /**
     * @notice Get a user's pending reward
     * @param _user User address
     * @return userPendingReward User's pending reward
     */
    function pendingReward(address _user)
        external
        view
        returns (uint256 userPendingReward)
    {
        UserInfo memory user = users[_user];

        // Total rounds that need to be distributed
        uint256 length = user.pendingRounds.length - user.lastRewardRoundIndex;

        // Start from last reward round index
        uint256 startIndex = user.lastRewardRoundIndex;

        for (uint256 i = startIndex; i < startIndex + length; i++) {
            uint256 round = user.pendingRounds[i];

            userPendingReward +=
                (rounds[round].degisPerShare *
                    userSharesInRound[_user][round]) /
                SCALE;
        }
    }

    /**
     * @notice Get degis reward per round
     * @dev Depends on the total shares in this round
     * @return rewardPerRound Degis reward per round
     */
    function getRewardPerRound() public view returns (uint256 rewardPerRound) {
        uint256 buyerBalance = rounds[currentRound].shares;

        uint256[] memory thresholdM = threshold;

        // If no piecewise is set, use the default degisPerRound
        if (thresholdM.length == 0) rewardPerRound = degisPerRound;
        else {
            for (uint256 i = thresholdM.length - 1; i >= 0; ) {
                if (buyerBalance >= thresholdM[i]) {
                    rewardPerRound = piecewise[i];
                    break;
                }
                unchecked {
                    --i;
                }
            }
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    /**
     * @notice Set degis distribution per round
     * @param _degisPerRound Degis distribution per round
     */
    function setDegisPerRound(uint256 _degisPerRound) external onlyOwner {
        emit DegisRewardChanged(degisPerRound, _degisPerRound);
        degisPerRound = _degisPerRound;
    }

    /**
     * @notice Set a new distribution interval
     * @param _newInterval The new interval
     */
    function setDistributionInterval(uint256 _newInterval) external onlyOwner {
        emit DistributionIntervalChanged(distributionInterval, _newInterval);
        distributionInterval = _newInterval;
    }

    /**
     * @notice Set the threshold and piecewise reward
     * @param _threshold The threshold
     * @param _reward The piecewise reward
     */
    function setPiecewise(
        uint256[] calldata _threshold,
        uint256[] calldata _reward
    ) external onlyOwner {
        threshold = _threshold;
        piecewise = _reward;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Stake buyer tokens into this contract
     * @param _amount Amount of buyer tokens to stake
     */
    function stake(uint256 _amount) external nonReentrant whenNotPaused {
        if (_amount == 0) revert PIV__ZeroAmount();

        // Save gas
        uint256 round = currentRound;

        // User info of msg.sender
        UserInfo storage user = users[msg.sender];

        // If the user has not staked in this round, record this new user to the users array
        if (userSharesInRound[msg.sender][round] == 0) {
            rounds[round].users.push(msg.sender);
        }

        userSharesInRound[msg.sender][round] += _amount;

        uint256 length = user.pendingRounds.length;
        // Only add the round if it's not in the array
        // Condition 1: length == 0 => no pending rounds => add this round
        // Condition 2: length != 0 && last pending round is not the current round => add this round
        if (
            length == 0 ||
            (length != 0 && user.pendingRounds[length - 1] != round)
        ) user.pendingRounds.push(round);

        // Update the total shares
        rounds[round].shares += _amount;

        // Finish the token transfer (need approval)
        buyerToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Stake(msg.sender, round, _amount);
    }

    /**
     * @notice Redeem buyer token from the vault
     * @param _amount Amount to redeem
     */
    function redeem(uint256 _amount) external nonReentrant whenNotPaused {
        if (_amount == 0) revert PIV__ZeroAmount();

        uint256 round = currentRound;

        uint256 userBalance = userSharesInRound[msg.sender][round];
        if (userBalance < _amount) revert PIV__NotEnoughBuyerTokens();

        userSharesInRound[msg.sender][round] -= _amount;

        // If redeem all buyer tokens, remove this round from the user's pending rounds
        if (userSharesInRound[msg.sender][round] == 0) {
            users[msg.sender].pendingRounds.pop();
        }

        rounds[round].shares -= _amount;

        // Finish the buyer token transfer
        buyerToken.safeTransfer(msg.sender, _amount);

        emit Redeem(msg.sender, round, _amount);
    }

    /**
     * @notice Setttle the current round
     * @dev Callable by any address, must pass the distribution interval
     */
    function settleCurrentRound() external hasPassedInterval whenNotPaused {
        RoundInfo storage info = rounds[currentRound];
        if (info.hasDistributed) revert PIV__AlreadyDistributed();

        uint256 totalShares = info.shares;
        uint256 totalReward = getRewardPerRound();

        // If no one staked, no reward
        if (totalShares == 0) info.degisPerShare = 0;
        else info.degisPerShare = (totalReward * SCALE) / totalShares;

        info.hasDistributed = true;

        emit RoundSettled(currentRound, block.timestamp);

        // Update current round, ++ save little gas
        ++currentRound;

        // Update last distribution time
        lastDistribution = block.timestamp;
    }

    /**
     * @notice User can claim his own reward
     */
    function claim() external nonReentrant whenNotPaused {
        UserInfo memory user = users[msg.sender];

        if (user.pendingRounds.length == 0) revert PIV__NoPendingRound();

        uint256 roundsToClaim = user.pendingRounds.length -
            user.lastRewardRoundIndex;

        if (roundsToClaim == 0) revert PIV__ClaimedAll();

        if (user.pendingRounds[user.pendingRounds.length - 1] == currentRound) {
            roundsToClaim -= 1;
        }

        uint256 startIndex = user.lastRewardRoundIndex;

        // MAX_ROUND to claim each time
        if (roundsToClaim > MAX_ROUND) {
            roundsToClaim = MAX_ROUND;
            users[msg.sender].lastRewardRoundIndex += MAX_ROUND;
        } else users[msg.sender].lastRewardRoundIndex += roundsToClaim;

        uint256 userPendingReward;
        

        for (uint256 i = startIndex; i < startIndex + roundsToClaim;) {
            uint256 round = user.pendingRounds[i];

            userPendingReward +=
                (rounds[round].degisPerShare *
                    userSharesInRound[msg.sender][round]) /
                SCALE;

            unchecked {
                ++i;
            }
        }

        // Mint reward to user
        degis.mintDegis(msg.sender, userPendingReward);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            _initializing ? _isConstructor() : !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/
pragma solidity ^0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IDegisToken } from "../tokens/interfaces/IDegisToken.sol";
import { Math } from "../libraries/Math.sol";
import { IVeDEG } from "../governance/interfaces/IVeDEG.sol";

/**
 * @title  Farming Pool
 * @notice This contract is for LPToken mining on Degis
 * @dev    The pool id starts from 1 rather than 0
 *         The degis reward is calculated by timestamp rather than block number
 *
 *         VeDEG will boost the farming speed by having a extra reward type
 *         The extra reward is shared by those staking lptokens with veDEG balances
 *         Every time the veDEG balance change, the reward will be updated
 *
 *         The basic reward depends on the liquidity inside the pool
 *         Update with a piecewise function
 *         liquidity amount:   |---------------|------------------|----------------
 *                             0           threshold 1        threshold 2
 *          reward speed:            speed1          speed2             speed3
 *
 *         The speed update will be updated one tx after the last tx that triggers the threshold
 *         The reward update will be another one tx later
 */
contract FarmingPoolUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IDegisToken;
    using Math for uint256;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    string public constant name = "Degis LP Farming Pool";

    // The reward token is degis
    IDegisToken public degis;

    // The bonus reward depends on veDEG
    IVeDEG public veDEG;

    // SCALE/Precision used for calculating rewards
    uint256 public constant SCALE = 1e12;

    // PoolId starts from 1
    uint256 public _nextPoolId;

    // Farming starts from a certain block timestamp
    // To keep the same with naughty price pools, we change from block numbers to timestamps
    uint256 public startTimestamp;

    struct PoolInfo {
        address lpToken; // LPToken address
        uint256 basicDegisPerSecond; // Basic Reward speed
        uint256 bonusDegisPerSecond; // Bonus reward speed
        uint256 lastRewardTimestamp; // Last reward timestamp
        uint256 accDegisPerShare; // Accumulated degis per share (for those without veDEG boosting)
        uint256 accDegisPerBonusShare; // Accumulated degis per bonus share (for those with veDEG boosting)
        uint256 totalBonus; // Total bonus factors
    }
    PoolInfo[] public poolList;

    // lptoken address => poolId
    mapping(address => uint256) public poolMapping;

    // poolId => alreadyFarming
    mapping(uint256 => bool) public isFarming;

    struct UserInfo {
        uint256 rewardDebt; // degis reward debt
        uint256 stakingBalance; // the amount of a user's staking in the pool
        uint256 bonus; // user bonus point (by veDEG balance)
    }
    // poolId => userAddress => userInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Extra claimable balance when updating bonus from veDEG
    mapping(uint256 => mapping(address => uint256)) public extraClaimable;

    // Reward speed change with liquidity inside contract
    mapping(uint256 => uint256[]) public thresholdBasic;
    mapping(uint256 => uint256[]) public piecewiseBasic;

    // This state variable is collapased
    uint256 public currentRewardLevel;

    mapping(uint256 => uint256) public poolRewardLevel;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event StartTimestampChanged(uint256 startTimestamp);
    event Stake(address staker, uint256 poolId, uint256 amount);
    event Withdraw(address staker, uint256 poolId, uint256 amount);
    event Harvest(
        address staker,
        address rewardReceiver,
        uint256 poolId,
        uint256 pendingReward
    );
    event NewPoolAdded(
        address lpToken,
        uint256 basicDegisPerSecond,
        uint256 bonusDegisPerSecond
    );
    event FarmingPoolStarted(uint256 poolId, uint256 timestamp);
    event FarmingPoolStopped(uint256 poolId, uint256 timestamp);
    event DegisRewardChanged(
        uint256 poolId,
        uint256 basicDegisPerSecond,
        uint256 bonusDegisPerSecond
    );
    event PoolUpdated(
        uint256 poolId,
        uint256 accDegisPerShare,
        uint256 accDegisPerBonusShare
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(address _degis) public initializer {
        require(_degis != address(0), "Zero address");

        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        degis = IDegisToken(_degis);

        // Start from 1
        _nextPoolId = 1;

        poolList.push(
            PoolInfo({
                lpToken: address(0),
                basicDegisPerSecond: 0,
                bonusDegisPerSecond: 0,
                lastRewardTimestamp: 0,
                accDegisPerShare: 0,
                accDegisPerBonusShare: 0,
                totalBonus: 0
            })
        );
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice The address can not be zero
     */
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Zero address");
        _;
    }

    /**
     * @notice The pool is still in farming
     */
    modifier stillFarming(uint256 _poolId) {
        require(isFarming[_poolId], "Pool is not farming");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** View Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check the amount of pending degis reward
     * @param _poolId PoolId of this farming pool
     * @param _user User address
     * @return pendingDegisAmount Amount of pending degis
     */
    function pendingDegis(uint256 _poolId, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo memory poolInfo = poolList[_poolId];

        if (
            poolInfo.lastRewardTimestamp == 0 ||
            block.timestamp < poolInfo.lastRewardTimestamp ||
            block.timestamp < startTimestamp
        ) return 0;

        UserInfo memory user = userInfo[_poolId][_user];

        // Total lp token balance
        uint256 lp_balance = IERC20(poolInfo.lpToken).balanceOf(address(this));

        // Accumulated shares to be calculated
        uint256 accDegisPerShare = poolInfo.accDegisPerShare;
        uint256 accDegisPerBonusShare = poolInfo.accDegisPerBonusShare;

        if (lp_balance == 0) return 0;
        else {
            // If the pool is still farming, update the info
            if (isFarming[_poolId]) {
                // Deigs amount given to this pool
                uint256 timePassed = block.timestamp -
                    poolInfo.lastRewardTimestamp;
                uint256 basicReward = poolInfo.basicDegisPerSecond * timePassed;
                // Update accDegisPerShare
                // LPToken may have different decimals
                accDegisPerShare += (basicReward * SCALE) / lp_balance;

                // If there is any bonus reward
                if (poolInfo.totalBonus > 0) {
                    uint256 bonusReward = poolInfo.bonusDegisPerSecond *
                        timePassed;
                    accDegisPerBonusShare +=
                        (bonusReward * SCALE) /
                        poolInfo.totalBonus;
                }
            }

            // If the pool has stopped, not update the info
            uint256 pending = (user.stakingBalance *
                accDegisPerShare +
                user.bonus *
                accDegisPerBonusShare) /
                SCALE +
                extraClaimable[_poolId][_user] -
                user.rewardDebt;

            return pending;
        }
    }

    /**
     * @notice Get the total pool list
     * @return pooList Total pool list
     */
    function getPoolList() external view returns (PoolInfo[] memory) {
        return poolList;
    }

    /**
     * @notice Get a user's balance
     * @param _poolId Id of the pool
     * @param _user User address
     * @return balance User's balance (lpToken)
     */
    function getUserBalance(uint256 _poolId, address _user)
        external
        view
        returns (uint256)
    {
        return userInfo[_poolId][_user].stakingBalance;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Set Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setVeDEG(address _veDEG) external onlyOwner {
        veDEG = IVeDEG(_veDEG);
    }

    /**
     * @notice Set the start block timestamp
     * @param _startTimestamp New start block timestamp
     */
    function setStartTimestamp(uint256 _startTimestamp)
        external
        onlyOwner
        whenNotPaused
    {
        // Can only be set before any pool is added
        require(
            _nextPoolId == 1,
            "Can not set start timestamp after adding a pool"
        );

        startTimestamp = _startTimestamp;
        emit StartTimestampChanged(_startTimestamp);
    }

    /**
     * @notice Set piecewise reward and threshold
     * @param _poolId Id of the pool
     * @param _threshold Piecewise threshold
     * @param _reward Piecewise reward
     */
    function setPiecewise(
        uint256 _poolId,
        uint256[] calldata _threshold,
        uint256[] calldata _reward
    ) external onlyOwner {
        thresholdBasic[_poolId] = _threshold;
        piecewiseBasic[_poolId] = _reward;

        // If reward for mimimum level is > 0, update isFarming
        if (_reward[0] > 0) isFarming[_poolId] = true;
        else isFarming[_poolId] = false;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Main Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Add a new lp into the pool
     * @dev Can only be called by the owner
     *      The reward speed can be 0 and set later by setDegisReward function
     * @param _lpToken LP token address
     * @param _basicDegisPerSecond Basic reward speed(per second) for this new pool
     * @param _bonusDegisPerSecond Bonus reward speed(per second) for this new pool
     * @param _withUpdate Whether update all pools' status
     */
    function add(
        address _lpToken,
        uint256 _basicDegisPerSecond,
        uint256 _bonusDegisPerSecond,
        bool _withUpdate
    ) public notZeroAddress(_lpToken) onlyOwner whenNotPaused {
        // Check if already exists, if the poolId is 0, that means not in the pool
        require(!_alreadyInPool(_lpToken), "Already in the pool");

        if (_bonusDegisPerSecond > 0)
            require(_basicDegisPerSecond > 0, "Only bonus");

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardTimestamp = block.timestamp > startTimestamp
            ? block.timestamp
            : startTimestamp;

        // Push this new pool into the list
        poolList.push(
            PoolInfo({
                lpToken: _lpToken,
                basicDegisPerSecond: _basicDegisPerSecond,
                bonusDegisPerSecond: _bonusDegisPerSecond,
                lastRewardTimestamp: lastRewardTimestamp,
                accDegisPerShare: 0,
                accDegisPerBonusShare: 0,
                totalBonus: 0
            })
        );

        // Store the poolId and set the farming status to true
        if (_basicDegisPerSecond > 0) isFarming[_nextPoolId] = true;

        poolMapping[_lpToken] = _nextPoolId++;

        emit NewPoolAdded(_lpToken, _basicDegisPerSecond, _bonusDegisPerSecond);
    }

    /**
     * @notice Update the degisPerSecond for a specific pool (set to 0 to stop farming)
     * @param _poolId Id of the farming pool
     * @param _basicDegisPerSecond New basic reward amount per second
     * @param _bonusDegisPerSecond New bonus reward amount per second
     * @param _withUpdate Whether update all pools
     */
    function setDegisReward(
        uint256 _poolId,
        uint256 _basicDegisPerSecond,
        uint256 _bonusDegisPerSecond,
        bool _withUpdate
    ) public onlyOwner whenNotPaused {
        // Ensure there already exists this pool
        require(poolList[_poolId].lastRewardTimestamp != 0, "Pool not exists");

        if (_bonusDegisPerSecond > 0)
            require(_basicDegisPerSecond > 0, "Only bonus");

        if (_withUpdate) massUpdatePools();
        else updatePool(_poolId);

        // Not farming now + reward > 0 => Restart
        if (isFarming[_poolId] == false && _basicDegisPerSecond > 0) {
            isFarming[_poolId] = true;
            emit FarmingPoolStarted(_poolId, block.timestamp);
        }

        if (_basicDegisPerSecond == 0) {
            isFarming[_poolId] = false;
            poolList[_poolId].basicDegisPerSecond = 0;
            poolList[_poolId].bonusDegisPerSecond = 0;
            emit FarmingPoolStopped(_poolId, block.timestamp);
        } else {
            poolList[_poolId].basicDegisPerSecond = _basicDegisPerSecond;
            poolList[_poolId].bonusDegisPerSecond = _bonusDegisPerSecond;
            emit DegisRewardChanged(
                _poolId,
                _basicDegisPerSecond,
                _bonusDegisPerSecond
            );
        }
    }

    /**
     * @notice Stake LP token into the farming pool
     * @dev Can only stake to the pools that are still farming
     * @param _poolId Id of the farming pool
     * @param _amount Staking amount
     */
    function stake(uint256 _poolId, uint256 _amount)
        public
        nonReentrant
        whenNotPaused
        stillFarming(_poolId)
    {
        require(_amount > 0, "Can not stake zero");

        PoolInfo storage pool = poolList[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        // Must update first
        updatePool(_poolId);

        // First distribute the reward if exists
        if (user.stakingBalance > 0) {
            uint256 pending = (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
                SCALE +
                extraClaimable[_poolId][msg.sender] -
                user.rewardDebt;

            // Clear the extra record (has been distributed)
            extraClaimable[_poolId][msg.sender] = 0;

            // Real reward amount by safe transfer
            uint256 reward = _safeDegisTransfer(msg.sender, pending);
            emit Harvest(msg.sender, msg.sender, _poolId, reward);
        }

        // Actual deposit amount
        uint256 actualAmount = _safeLPTransfer(
            false,
            pool.lpToken,
            msg.sender,
            _amount
        );

        user.stakingBalance += actualAmount;

        if (address(veDEG) != address(0)) {
            // Update the user's bonus if veDEG boosting is on
            uint256 oldBonus = user.bonus;
            user.bonus = (user.stakingBalance * veDEG.balanceOf(msg.sender))
                .sqrt();
            // Update the pool's total bonus
            pool.totalBonus = pool.totalBonus + user.bonus - oldBonus;
        }

        user.rewardDebt =
            (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
            SCALE;

        emit Stake(msg.sender, _poolId, actualAmount);
    }

    /**
     * @notice Withdraw lptoken from the pool
     * @param _poolId Id of the farming pool
     * @param _amount Amount of lp tokens to withdraw
     */
    function withdraw(uint256 _poolId, uint256 _amount)
        public
        nonReentrant
        whenNotPaused
    {
        require(_amount > 0, "Zero amount");

        PoolInfo storage pool = poolList[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        require(user.stakingBalance >= _amount, "Not enough stakingBalance");

        // Update if the pool is still farming
        // Users can withdraw even after the pool stopped
        if (isFarming[_poolId]) updatePool(_poolId);
        else {
            pool.lastRewardTimestamp = block.timestamp;
        }

        uint256 pending = (user.stakingBalance *
            pool.accDegisPerShare +
            user.bonus *
            pool.accDegisPerBonusShare) /
            SCALE +
            extraClaimable[_poolId][msg.sender] -
            user.rewardDebt;

        // Clear the extra record (has been distributed)
        extraClaimable[_poolId][msg.sender] = 0;

        // Real reward amount by safe transfer
        uint256 reward = _safeDegisTransfer(msg.sender, pending);
        emit Harvest(msg.sender, msg.sender, _poolId, reward);

        uint256 actualAmount = _safeLPTransfer(
            true,
            pool.lpToken,
            msg.sender,
            _amount
        );

        user.stakingBalance -= actualAmount;

        // Update the user's bonus when veDEG boosting is on
        if (address(veDEG) != address(0)) {
            uint256 oldBonus = user.bonus;
            user.bonus = (user.stakingBalance * veDEG.balanceOf(msg.sender))
                .sqrt();
            // Update the pool's total bonus
            pool.totalBonus = pool.totalBonus + user.bonus - oldBonus;
        }

        user.rewardDebt =
            (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
            SCALE;

        emit Withdraw(msg.sender, _poolId, actualAmount);
    }

    /**
     * @notice Harvest the degis reward and can be sent to another address
     * @param _poolId Id of the farming pool
     * @param _to Receiver of degis rewards
     */
    function harvest(uint256 _poolId, address _to)
        public
        nonReentrant
        whenNotPaused
    {
        // Only update the pool when it is still in farming
        if (isFarming[_poolId]) updatePool(_poolId);
        else {
            poolList[_poolId].lastRewardTimestamp = block.timestamp;
        }

        PoolInfo memory pool = poolList[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        uint256 pendingReward = (user.stakingBalance *
            pool.accDegisPerShare +
            user.bonus *
            pool.accDegisPerBonusShare) /
            SCALE +
            extraClaimable[_poolId][msg.sender] -
            user.rewardDebt;

        extraClaimable[_poolId][msg.sender] = 0;

        require(pendingReward > 0, "No pending reward");

        // Update the reward debt
        user.rewardDebt =
            (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
            SCALE;

        // Transfer the reward
        uint256 reward = _safeDegisTransfer(_to, pendingReward);

        emit Harvest(msg.sender, _to, _poolId, reward);
    }

    /**
     * @notice Update the pool's reward status
     * @param _poolId Id of the farming pool
     */
    function updatePool(uint256 _poolId) public {
        PoolInfo storage pool = poolList[_poolId];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }

        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));

        // No LP deposited, then just update the lastRewardTimestamp
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 timePassed = block.timestamp - pool.lastRewardTimestamp;

        uint256 basicReward = timePassed * pool.basicDegisPerSecond;
        uint256 bonusReward = timePassed * pool.bonusDegisPerSecond;

        pool.accDegisPerShare += (basicReward * SCALE) / lpSupply;

        if (pool.totalBonus == 0) {
            pool.accDegisPerBonusShare = 0;
        } else {
            pool.accDegisPerBonusShare +=
                (bonusReward * SCALE) /
                pool.totalBonus;
        }

        // Don't forget to set the farming pool as minter
        degis.mintDegis(address(this), basicReward + bonusReward);

        pool.lastRewardTimestamp = block.timestamp;

        uint256 currentPoolLevel = poolRewardLevel[_poolId];

        // Update the new reward speed
        // Only if the threshold are already set
        if (thresholdBasic[_poolId].length > 0) {
            uint256 currentLiquidity = thresholdBasic[_poolId][
                currentPoolLevel
            ];
            if (
                currentPoolLevel < thresholdBasic[_poolId].length - 1 &&
                lpSupply >= thresholdBasic[_poolId][currentPoolLevel + 1]
            ) {
                _updateRewardSpeed(_poolId);
            } else if (lpSupply < currentLiquidity) {
                _updateRewardSpeed(_poolId);
            }
        }

        emit PoolUpdated(
            _poolId,
            pool.accDegisPerShare,
            pool.accDegisPerBonusShare
        );
    }

    /**
     * @notice Update all farming pools (except for those stopped ones)
     * @dev Can be called by anyone
     *      Only update those active pools
     */
    function massUpdatePools() public {
        uint256 length = poolList.length;
        for (uint256 poolId = 1; poolId < length; ++poolId) {
            if (isFarming[poolId] == false) {
                poolList[poolId].lastRewardTimestamp = block.timestamp;
                continue;
            } else updatePool(poolId);
        }
    }

    /**
     * @notice Update a user's bonus
     * @dev When veDEG has balance change
     *      Only called by veDEG contract
     * @param _user User address
     * @param _newVeDEGBalance New veDEG balance
     */
    function updateBonus(address _user, uint256 _newVeDEGBalance) external {
        require(msg.sender == address(veDEG), "Only veDEG contract");

        // loop over each pool : beware gas cost!
        uint256 length = poolList.length;

        for (uint256 poolId; poolId < length; ++poolId) {
            // Skip if the pool is not farming
            if (!isFarming[poolId]) continue;

            UserInfo storage user = userInfo[poolId][_user];
            // Skip if user doesn't have any deposit in the pool
            if (user.stakingBalance == 0) continue;

            PoolInfo storage pool = poolList[poolId];

            // first, update pool
            updatePool(poolId);

            // Update the extra claimable amount
            uint256 pending = (user.stakingBalance *
                pool.accDegisPerShare +
                user.bonus *
                pool.accDegisPerBonusShare) /
                SCALE -
                user.rewardDebt;
            extraClaimable[poolId][_user] += pending;

            // get oldFactor
            uint256 oldFactor = user.bonus; // get old factor
            // calculate newFactor
            uint256 newFactor = (_newVeDEGBalance * user.stakingBalance).sqrt();
            // update user factor
            user.bonus = newFactor;
            // update reward debt, take into account newFactor
            user.rewardDebt =
                (user.stakingBalance *
                    pool.accDegisPerShare +
                    newFactor *
                    pool.accDegisPerBonusShare) /
                SCALE;

            // Update the pool's total bonus
            pool.totalBonus = pool.totalBonus + newFactor - oldFactor;
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // ********************************** Internal Functions ********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check if a lptoken has been added into the pool before
     * @dev This can also be written as a modifier
     * @param _lpToken LP token address
     * @return _isInPool Wether this lp is already in pool
     */
    function _alreadyInPool(address _lpToken)
        internal
        view
        returns (bool _isInPool)
    {
        uint256 poolId = poolMapping[_lpToken];

        _isInPool = (poolId != 0) ? true : false;
    }

    /**
     * @notice Safe degis transfer (check if the pool has enough DEGIS token)
     * @param _to User's address
     * @param _amount Amount to transfer
     */
    function _safeDegisTransfer(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 poolDegisBalance = degis.balanceOf(address(this));
        require(poolDegisBalance > 0, "No Degis token in the pool");

        if (_amount > poolDegisBalance) {
            degis.safeTransfer(_to, poolDegisBalance);
            return (poolDegisBalance);
        } else {
            degis.safeTransfer(_to, _amount);
            return _amount;
        }
    }

    /**
     * @notice Finish the transfer of LP Token
     * @dev The lp token may have loss during transfer
     * @param _out Whether the lp token is out
     * @param _lpToken LP token address
     * @param _user User address
     * @param _amount Amount of lp tokens
     */
    function _safeLPTransfer(
        bool _out,
        address _lpToken,
        address _user,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 poolBalanceBefore = IERC20(_lpToken).balanceOf(address(this));

        if (_out) IERC20(_lpToken).safeTransfer(_user, _amount);
        else IERC20(_lpToken).safeTransferFrom(_user, address(this), _amount);

        uint256 poolBalanceAfter = IERC20(_lpToken).balanceOf(address(this));

        return
            _out
                ? poolBalanceBefore - poolBalanceAfter
                : poolBalanceAfter - poolBalanceBefore;
    }

    /**
     * @notice Update the reward speed
     * @param _poolId Pool ID
     */
    function _updateRewardSpeed(uint256 _poolId) internal {
        uint256 currentBasicBalance = IERC20(poolList[_poolId].lpToken)
            .balanceOf(address(this));

        uint256 basicRewardSpeed;

        for (uint256 i = thresholdBasic[_poolId].length - 1; i >= 0; --i) {
            if (currentBasicBalance >= thresholdBasic[_poolId][i]) {
                basicRewardSpeed = piecewiseBasic[_poolId][i];
                // record current reward level
                poolRewardLevel[_poolId] = i;
                break;
            } else continue;
        }

        poolList[_poolId].basicDegisPerSecond = basicRewardSpeed;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice This is the MockUSD used in testnet
 *         Maximum mint amount is 500k for each user.
 *         Maximum mint amount for every single tx is 100k.
 */
contract MockUSD is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 100000 * 1e6;

    constructor() ERC20("MOCKUSD", "USDC") {
        // When first deployed, give the owner some coins
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    // Everyone can mint, have fun for test
    function mint(address _account, uint256 _amount) public {
        _mint(_account, _amount);
    }

    // 6 decimals to mock stablecoins
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice MockERC20 for test
 * @dev MockUSD has 6 decimals, this contract is 18 decimals
 */
contract MockERC20 is ERC20 {
    constructor() ERC20("MockERC20", "ERC20") {}

    // Everyone can mint, have fun for test
    function mint(address _account, uint256 _amount) public {
        _mint(_account, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "../utils/Ownable.sol";

/**
 * @title  Signature Manager
 * @notice Signature is used when submitting new applications.
 *         The premium should be decided by the pricing model and be signed by a private key.
 *         Other submissions will not be accepted.
 *         Please keep the signer key safe.
 */
contract SigManager is Ownable {
    using ECDSA for bytes32;

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Variables *************************************** //
    // ---------------------------------------------------------------------------------------- //

    mapping(address => bool) public isValidSigner;

    bytes32 public _SUBMIT_APPLICATION_TYPEHASH;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event SignerAdded(address _newSigner);
    event SignerRemoved(address _oldSigner);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor() Ownable(msg.sender) {
        _SUBMIT_APPLICATION_TYPEHASH = keccak256(
            "5G is great, physical lab is difficult to find"
        );
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @dev This modifier uses assert which means this error should never happens
     */
    modifier validAddress(address _address) {
        assert(_address != address(0));
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Add a signer into valid signer list
     * @param _newSigner The new signer address
     */
    function addSigner(address _newSigner)
        external
        validAddress(_newSigner)
        onlyOwner
    {
        require(!isValidSigner[_newSigner], "Already a signer");

        isValidSigner[_newSigner] = true;

        emit SignerAdded(_newSigner);
    }

    /**
     * @notice Remove a signer from the valid signer list
     * @param _oldSigner The old signer address to be removed
     */
    function removeSigner(address _oldSigner)
        external
        validAddress(_oldSigner)
        onlyOwner
    {
        require(isValidSigner[_oldSigner], "Not a signer");

        isValidSigner[_oldSigner] = false;

        emit SignerRemoved(_oldSigner);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check signature when buying a new policy (avoid arbitrary premium amount)
     * @param signature 65 bytes array: [[v (1)], [r (32)], [s (32)]]
     * @param _flightNumber Flight number
     * @param _departureTimestamp Flight departure timestamp
     * @param _landingDate Flight landing date
     * @param _user User address
     * @param _premium Policy premium
     * @param _deadline Deadline of a this signature
     */
    function checkSignature(
        bytes calldata signature,
        string memory _flightNumber,
        uint256 _departureTimestamp,
        uint256 _landingDate,
        address _user,
        uint256 _premium,
        uint256 _deadline
    ) external view {
        bytes32 hashedFlightNumber = keccak256(bytes(_flightNumber));

        bytes32 hashData = keccak256(
            abi.encodePacked(
                _SUBMIT_APPLICATION_TYPEHASH,
                hashedFlightNumber,
                _departureTimestamp,
                _landingDate,
                _user,
                _premium,
                _deadline
            )
        );
        address signer = hashData.toEthSignedMessageHash().recover(signature);

        require(isValidSigner[signer], "Only submitted by authorized signers");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockPTP {
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut) {
        require(block.timestamp < deadline, "Deadline has passed");
        require(fromToken != address(0), "ZERO");
        require(toToken != address(0), "ZERO");
        require(fromToken != toToken, "SAME_ADDRESS");
        require(fromAmount > 0, "ZERO_FROM_AMOUNT");
        require(to != address(0), "ZERO");

        IERC20 fromERC20 = IERC20(fromToken);
        // Asset fromAsset = _assetOf(fromToken);
        // Asset toAsset = _assetOf(toToken);

        // // Intrapool swapping only
        // require(
        //     toAsset.aggregateAccount() == fromAsset.aggregateAccount(),
        //     "DIFF_AGG_ACC"
        // );

        // (actualToAmount, haircut) = _quoteFrom(fromAsset, toAsset, fromAmount);

        fromERC20.transferFrom(msg.sender, fromToken, fromAmount);

        actualToAmount = fromAmount;
        haircut = 0;

        require(minimumToAmount <= actualToAmount, "AMOUNT_TOO_LOW");
        // fromAsset.addCash(fromAmount);
        // toAsset.removeCash(actualToAmount);
        // toAsset.addLiability(_dividend(haircut, _retentionRatio));
        // toAsset.transferUnderlyingToken(to, actualToAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./utils/Ownable.sol";

/**
 * @title  Emergency Pool
 * @notice Emergency pool in degis will keep a reserve vault for emergency usage.
 *         The asset comes from part of the product's income (currently 10%).
 *         Users can also stake funds into this contract manually.
 *         The owner has the right to withdraw funds from emergency pool and it would be passed to community governance.
 */
contract EmergencyPool is Ownable {
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    string public name = "Degis Emergency Pool";

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event Deposit(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 amount
    );
    event Withdraw(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 amount
    );
    event UseFund(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 amount
    );

    constructor() Ownable(msg.sender) {}

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Manually stake into the pool
     * @param _tokenAddress Address of the ERC20 token
     * @param _amount The amount that the user want to stake
     */
    function deposit(address _tokenAddress, uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");

        IERC20(_tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );

        emit Deposit(_tokenAddress, _msgSender(), _amount);
    }

    /**
     * @notice Withdraw the asset when emergency (only by the owner)
     * @dev The ownership need to be transferred to another contract in the future
     * @param _tokenAddress Address of the ERC20 token
     * @param _amount The amount that the user want to unstake
     */
    function emergencyWithdraw(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
    {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(_amount <= balance, "Insufficient funds");

        IERC20(_tokenAddress).safeTransfer(owner(), _amount);
        emit Withdraw(_tokenAddress, owner(), _amount);
    }

    /**
     * @notice Use emergency pool fund
     * @param _tokenAddress Address of the ERC20 token
     * @param _receiver Address of the receiver
     * @param _amount The amount to use    
     */
    function useFund(
        address _tokenAddress,
        address _receiver,
        uint256 _amount
    ) external onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(_amount <= balance, "Insufficient funds");

        IERC20(_tokenAddress).safeTransfer(_receiver, _amount);
        emit UseFund(_tokenAddress, _receiver, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "./SafePRBMath.sol";

contract SafePRBMathTester {
    function avg(uint256 x, uint256 y) public pure returns (uint256 result) {
        return SafePRBMath.avg(x, y);
    }

    function ceil(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.ceil(x);
    }

    function div(uint256 x, uint256 y) public pure returns (uint256 result) {
        return SafePRBMath.div(x, y);
    }

    function e() public pure returns (uint256 result) {
        return SafePRBMath.e();
    }

    function exp(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.exp(x);
    }

    function exp2(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.exp2(x);
    }

    function floor(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.floor(x);
    }

    function frac(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.frac(x);
    }

    function fromUint(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.fromUint(x);
    }

    function gm(uint256 x, uint256 y) public pure returns (uint256 result) {
        return SafePRBMath.gm(x, y);
    }

    function inv(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.inv(x);
    }

    function ln(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.ln(x);
    }

    function log10(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.log10(x);
    }

    function log2(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.log2(x);
    }

    function mul(uint256 x, uint256 y) public pure returns (uint256 result) {
        return SafePRBMath.mul(x, y);
    }

    function pi() public pure returns (uint256 result) {
        return SafePRBMath.pi();
    }

    function pow(uint256 x, uint256 y) public pure returns (uint256 result) {
        return SafePRBMath.pow(x, y);
    }

    function powu(uint256 x, uint256 y) public pure returns (uint256 result) {
        return SafePRBMath.powu(x, y);
    }

    function scale() public pure returns (uint256 result) {
        return SafePRBMath.scale();
    }

    function sqrt(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.sqrt(x);
    }

    function toUint(uint256 x) public pure returns (uint256 result) {
        return SafePRBMath.toUint(x);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../utils/ERC20PermitWithMultipleMinters.sol";

/**
 * @title  Buyer Token
 * @notice Buyer tokens are distributed to buyers corresponding to the usd value they spend.
 *         Users can deposit their buyer tokens into PurchaseIncentiveVault.
 *         Periodical reward will be given to the participants in PurchaseIncentiveVault.
 *         When distributing purchase incentive reward, the buyer tokens will be burned.
 * @dev    Need to set the correct minters and burners when reploying this contract.
 */
contract BuyerToken is ERC20PermitWithMultipleMinters {
    // ---------------------------------------------------------------------------------------- //
    // ************************************ Constructor *************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor() ERC20PermitWithMultipleMinters("DegisBuyerToken", "DBT") {}

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Main Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Mint buyer tokens
     * @param  _account Receiver's address
     * @param  _amount  Amount to be minted
     */
    function mintBuyerToken(address _account, uint256 _amount) external {
        mint(_account, _amount);
    }

    /**
     * @notice Burn buyer tokens
     * @param  _account Receiver's address
     * @param  _amount  Amount to be burned
     */
    function burnBuyerToken(address _account, uint256 _amount) external {
        burn(_account, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "../utils/Ownable.sol";

/**
 * @title  Price Getter
 * @notice This is the contract for getting price feed from chainlink.
 *         The contract will keep a record from tokenName => priceFeed Address.
 *         Got the sponsorship and collaboration with Chainlink.
 * @dev    The price from chainlink priceFeed has different decimals, be careful.
 */
contract PriceGetter is Ownable {
    struct PriceFeedInfo {
        address priceFeedAddress;
        uint256 decimals;
    }
    // Use token name (string) as the mapping key
    // Should set the correct orginal token name
    mapping(string => PriceFeedInfo) public priceFeedInfo;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //
    event PriceFeedChanged(
        string tokenName,
        address feedAddress,
        uint256 decimals
    );

    event LatestPriceGet(
        uint80 roundID,
        int256 price,
        uint256 startedAt,
        uint256 timeStamp,
        uint80 answeredInRound
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Constructor function, initialize some price feeds
     *         The first supported tokens are AVAX, BTC and ETH
     */
    constructor() Ownable(msg.sender) {
        // Avalanche data feed addresses and decimals
        priceFeedInfo["AVAX"] = PriceFeedInfo(
            0x0A77230d17318075983913bC2145DB16C7366156,
            8
        );

        priceFeedInfo["ETH"] = PriceFeedInfo(
            0x976B3D034E162d8bD72D6b9C989d545b839003b0,
            8
        );

        priceFeedInfo["BTC"] = PriceFeedInfo(
            0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743,
            8
        );
    }

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Modifiers ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Can not give zero address
     */
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Zero address");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set a price feed oracle address for a token
     * @dev Only callable by the owner
     *      The price result decimal should be less than 18
     * @param _tokenName   Address of the token
     * @param _feedAddress Price feed oracle address
     * @param _decimals    Decimals of this price feed service
     */
    function setPriceFeed(
        string memory _tokenName,
        address _feedAddress,
        uint256 _decimals
    ) public onlyOwner notZeroAddress(_feedAddress) {
        require(_decimals <= 18, "Too many decimals");
        priceFeedInfo[_tokenName] = PriceFeedInfo(_feedAddress, _decimals);

        emit PriceFeedChanged(_tokenName, _feedAddress, _decimals);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Main Functions *********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get latest price of a token
     * @param _tokenName Address of the token
     * @return price The latest price
     */
    function getLatestPrice(string memory _tokenName) public returns (uint256) {
        PriceFeedInfo memory priceFeed = priceFeedInfo[_tokenName];

        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(priceFeed.priceFeedAddress).latestRoundData();

        // require(price > 0, "Only accept price that > 0");
        if (price < 0) price = 0;

        emit LatestPriceGet(
            roundID,
            price,
            startedAt,
            timeStamp,
            answeredInRound
        );
        // Transfer the result decimals
        uint256 finalPrice = uint256(price) * (10**(18 - priceFeed.decimals));

        return finalPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}