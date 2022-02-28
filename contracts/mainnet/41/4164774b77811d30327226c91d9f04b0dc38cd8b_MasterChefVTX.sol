// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "SafeERC20.sol";
import "IERC20Metadata.sol";
import "Address.sol";

import "vtx.sol";
import "BaseRewardPool.sol";
import "IBaseRewardPool.sol";
import "ILocker.sol";

// MasterChefVTX is a boss. He says "go f your blocks lego boy, I'm gonna use timestamp instead".
// And to top it off, it takes no risks. Because the biggest risk is operator error.
// So we make it virtually impossible for the operator of this contract to cause a bug with people's harvests.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once VTX is sufficiently
// distributed and the community can show to govern itself.
//
// With thanks to the Lydia Finance team.
//
// Godspeed and may the 10x be with you.

/// @title A contract for managing all reward pools
/// @author Vector Team
/// @notice You can use this contract for depositing VTX,XPTP, and Liquidity Pool tokens.
/// @dev All the ___For() function are function which are supposed to be called by other contract designed by Vector's team

contract MasterChefVTX is Ownable {
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 available; // in case of locking
        //
        // We do some fancy math here. Basically, any point in time, the amount of VTXs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accVTXPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accVTXPerShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. VTXs to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that VTXs distribution occurs.
        uint256 accVTXPerShare; // Accumulated VTXs per share, times 1e12. See below.
        address rewarder;
        address helper;
        address locker;
    }

    // The VTX TOKEN!
    VTX public vtx;
    // Dev address.
    address public devAddr;
    // Treasury address.
    address public treasuryAddr;
    // Investor address
    address public investorAddr;
    // VTX tokens created per second.
    uint256 public vtxPerSec;
    // Percentage of pool rewards that goto the devs.
    uint256 public devPercent;
    // Percentage of pool rewards that goes to the treasury.
    uint256 public treasuryPercent;
    // Percentage of pool rewards that goes to the investor.
    uint256 public investorPercent;

    // Info of each pool.
    address[] public registeredToken;

    mapping(address => PoolInfo) public addressToPoolInfo;
    // Set of all LP tokens that have been added as pools
    mapping(address => bool) private lpTokens;
    // Info of each user that stakes LP tokens.
    mapping(address => mapping(address => UserInfo)) private userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The timestamp when VTX mining starts.
    uint256 public startTimestamp;

    mapping(address => bool) public PoolManagers;

    event Add(
        uint256 allocPoint,
        address indexed lpToken,
        IBaseRewardPool indexed rewarder
    );
    event Set(
        address indexed lpToken,
        uint256 allocPoint,
        IBaseRewardPool indexed rewarder,
        address indexed locker,
        bool overwrite
    );
    event Deposit(
        address indexed user,
        address indexed lpToken,
        uint256 amount
    );
    event Withdraw(
        address indexed user,
        address indexed lpToken,
        uint256 amount
    );
    event UpdatePool(
        address indexed lpToken,
        uint256 lastRewardTimestamp,
        uint256 lpSupply,
        uint256 accVTXPerShare
    );
    event Harvest(
        address indexed user,
        address indexed lpToken,
        uint256 amount
    );
    event EmergencyWithdraw(
        address indexed user,
        address indexed lpToken,
        uint256 amount
    );
    event SetDevAddress(address indexed oldAddress, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 _vtxPerSec);
    event Locked(address indexed user, address indexed lpToken, uint256 amount);
    event Unlocked(
        address indexed user,
        address indexed lpToken,
        uint256 amount
    );

    constructor(
        address _vtx,
        address _devAddr,
        address _treasuryAddr,
        address _investorAddr,
        uint256 _vtxPerSec,
        uint256 _startTimestamp,
        uint256 _devPercent,
        uint256 _treasuryPercent,
        uint256 _investorPercent
    ) {
        require(
            0 <= _devPercent && _devPercent <= 1000,
            "constructor: invalid dev percent value"
        );
        require(
            0 <= _treasuryPercent && _treasuryPercent <= 1000,
            "constructor: invalid treasury percent value"
        );
        require(
            0 <= _investorPercent && _investorPercent <= 1000,
            "constructor: invalid investor percent value"
        );
        require(
            _devPercent + _treasuryPercent + _investorPercent <= 1000,
            "constructor: total percent over max"
        );
        vtx = VTX(_vtx);
        devAddr = _devAddr;
        treasuryAddr = _treasuryAddr;
        investorAddr = _investorAddr;
        vtxPerSec = _vtxPerSec;
        startTimestamp = _startTimestamp;
        devPercent = _devPercent;
        treasuryPercent = _treasuryPercent;
        investorPercent = _investorPercent;
        totalAllocPoint = 0;
        PoolManagers[owner()] = true;
    }

    /// @notice Returns number of registered tokens, tokens having a registered pool.
    /// @return Returns number of registered tokens
    function poolLength() external view returns (uint256) {
        return registeredToken.length;
    }

    /// @notice Used to give edit rights to the pools in this contract to a Pool Manager
    /// @param _address Pool Manager Adress
    /// @param _bool True gives rights, False revokes them
    function setPoolManagerStatus(address _address, bool _bool)
        external
        onlyOwner
    {
        PoolManagers[_address] = _bool;
    }

    modifier onlyPoolManager() {
        require(PoolManagers[msg.sender], "Not a Pool Manager");
        _;
    }

    /// @notice Gives information about a Pool. Used for APR calculation and Front-End
    /// @param token Staking token of the pool we want to get information from
    /// @return emission - Emissions of VTX from the contract, allocpoint - Allocated emissions of VTX to the pool,sizeOfPool - size of Pool, totalPoint total allocation points
    function getPoolInfo(address token)
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        )
    {
        PoolInfo memory pool = addressToPoolInfo[token];
        return (
            vtxPerSec,
            pool.allocPoint,
            IERC20(token).balanceOf(address(this)),
            totalAllocPoint
        );
    }

    /// @notice Add a new lp to the pool. Can only be called by a PoolManager.
    /// @param _lpToken Staking token of the pool
    /// @param mainRewardToken Token that will be rewarded for staking in the pool
    /// @return address of the rewarder created
    function createRewarder(address _lpToken, address mainRewardToken)
        public
        onlyPoolManager
        returns (address)
    {
        BaseRewardPool _rewarder = new BaseRewardPool(
            _lpToken,
            mainRewardToken,
            address(this),
            msg.sender
        );
        return address(_rewarder);
    }

    /// @notice Add a new pool. Can only be called by a PoolManager.
    /// @param _allocPoint Allocation points of VTX to the pool
    /// @param _lpToken Staking token of the pool
    /// @param _rewarder Address of the rewarder for the pool
    /// @param _helper Address of the helper for the pool
    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder,
        address _helper
    ) external onlyPoolManager {
        require(
            Address.isContract(address(_lpToken)),
            "add: LP token must be a valid contract"
        );
        require(
            Address.isContract(address(_rewarder)) ||
                address(_rewarder) == address(0),
            "add: rewarder must be contract or zero"
        );
        require(!lpTokens[_lpToken], "add: LP already added");

        massUpdatePools();
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp
            ? block.timestamp
            : startTimestamp;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        registeredToken.push(_lpToken);
        addressToPoolInfo[_lpToken] = PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardTimestamp: lastRewardTimestamp,
            accVTXPerShare: 0,
            rewarder: _rewarder,
            helper: _helper,
            locker: address(0)
        });
        lpTokens[_lpToken] = true;
        emit Add(_allocPoint, _lpToken, IBaseRewardPool(_rewarder));
    }

    /// @notice Updates the given pool's VTX allocation point, rewarder address and locker address if overwritten. Can only be called by a Pool Manager.
    /// @param _lp Staking token of the pool
    /// @param _allocPoint Allocation points of VTX to the pool
    /// @param _rewarder Address of the rewarder for the pool
    /// @param _locker Address of the locker for the pool
    /// @param overwrite If true, the rewarder and locker are overwritten

    function set(
        address _lp,
        uint256 _allocPoint,
        address _rewarder,
        address _locker,
        bool overwrite
    ) external onlyPoolManager {
        require(
            Address.isContract(address(_rewarder)) ||
                address(_rewarder) == address(0),
            "set: rewarder must be contract or zero"
        );
        require(
            Address.isContract(address(_locker)) ||
                address(_locker) == address(0),
            "set: locker must be contract or zero"
        );
        massUpdatePools();
        totalAllocPoint =
            totalAllocPoint -
            addressToPoolInfo[_lp].allocPoint +
            _allocPoint;
        addressToPoolInfo[_lp].allocPoint = _allocPoint;
        if (overwrite) {
            addressToPoolInfo[_lp].rewarder = _rewarder;
            addressToPoolInfo[_lp].locker = _locker;
        }
        emit Set(
            _lp,
            _allocPoint,
            IBaseRewardPool(addressToPoolInfo[_lp].rewarder),
            addressToPoolInfo[_lp].locker,
            overwrite
        );
    }

    /// @notice Provides available amount for a specific user for a specific pool.
    /// @param _lp Staking token of the pool
    /// @param _user Address of the user
    /// @return availableAmount Amount available for the user to withdraw if needed

    function depositInfo(address _lp, address _user)
        public
        view
        returns (uint256 availableAmount)
    {
        return userInfo[_lp][_user].available;
    }

    /// @notice View function to see pending tokens on frontend.
    /// @param _lp Staking token of the pool
    /// @param _user Address of the user
    /// @param token Specific pending token, apart from VTX
    /// @return pendingVTX - Expected amount of VTX the user can claim, bonusTokenAddress - token, bonusTokenSymbol - token Symbol,  pendingBonusToken - Expected amount of token the user can claim
    function pendingTokens(
        address _lp,
        address _user,
        address token
    )
        external
        view
        returns (
            uint256 pendingVTX,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        )
    {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        UserInfo storage user = userInfo[_lp][_user];
        uint256 accVTXPerShare = pool.accVTXPerShare;
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;
            uint256 lpPercent = 1000 -
                devPercent -
                treasuryPercent -
                investorPercent;
            uint256 vtxReward = (((multiplier * vtxPerSec * pool.allocPoint) /
                totalAllocPoint) * lpPercent) / 1000;
            accVTXPerShare = accVTXPerShare + (vtxReward * 1e12) / lpSupply;
        }
        pendingVTX = (user.amount * accVTXPerShare) / 1e12 - user.rewardDebt;

        // If it's a double reward farm, we return info about the bonus token
        if (address(pool.rewarder) != address(0)) {
            (bonusTokenAddress, bonusTokenSymbol) = (
                token,
                IERC20Metadata(token).symbol()
            );
            pendingBonusToken = IBaseRewardPool(pool.rewarder).earned(
                _user,
                token
            );
        }
    }

    /// @notice Update reward variables for all pools. Be mindful of gas costs!
    function massUpdatePools() public {
        uint256 length = registeredToken.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(registeredToken[pid]);
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _lp Staking token of the pool
    function updatePool(address _lp) public {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;
        uint256 vtxReward = (multiplier * vtxPerSec * pool.allocPoint) /
            totalAllocPoint;
        uint256 lpPercent = 1000 -
            devPercent -
            treasuryPercent -
            investorPercent;
        vtx.mint(devAddr, (vtxReward * devPercent) / 1000);
        vtx.mint(treasuryAddr, (vtxReward * treasuryPercent) / 1000);
        vtx.mint(investorAddr, (vtxReward * investorPercent) / 1000);
        vtx.mint(address(this), (vtxReward * lpPercent) / 1000);
        pool.accVTXPerShare =
            pool.accVTXPerShare +
            (((vtxReward * 1e12) / lpSupply) * lpPercent) /
            1000;
        pool.lastRewardTimestamp = block.timestamp;
        emit UpdatePool(
            _lp,
            pool.lastRewardTimestamp,
            lpSupply,
            pool.accVTXPerShare
        );
    }

    /// @notice Deposits staking token to the pool, updates pool and distributes rewards
    /// @param _lp Staking token of the pool
    /// @param _amount Amount to deposit to the pool
    function deposit(address _lp, uint256 _amount) external {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        IERC20(pool.lpToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        UserInfo storage user = userInfo[_lp][msg.sender];
        updatePool(_lp);
        if (user.amount > 0) {
            // Harvest VTX
            uint256 pending = (user.amount * pool.accVTXPerShare) /
                1e12 -
                user.rewardDebt;
            safeVTXTransfer(msg.sender, pending);
            emit Harvest(msg.sender, _lp, pending);
        }
        user.amount = user.amount + _amount;
        user.available = user.available + _amount;
        user.rewardDebt = (user.amount * pool.accVTXPerShare) / 1e12;

        IBaseRewardPool rewarder = IBaseRewardPool(
            addressToPoolInfo[_lp].rewarder
        );
        if (_amount == 0 && address(rewarder) != address(0)) {
            rewarder.getReward(msg.sender);
        } else {
            if (address(rewarder) != address(0)) {
                rewarder.stakeFor(msg.sender, _amount);
                rewarder.getReward(msg.sender);
            }

            emit Deposit(msg.sender, _lp, _amount);
        }
    }

    /// @notice Claims rewards specifically for a locker pool, which has transferFrom overrided.
    /// @param _lp Staking token of the pool
    function claimLock(address _lp) external {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        UserInfo storage user = userInfo[_lp][msg.sender];
        updatePool(_lp);
        if (user.amount > 0) {
            // Harvest VTX
            uint256 pending = (user.amount * pool.accVTXPerShare) /
                1e12 -
                user.rewardDebt;
            safeVTXTransfer(msg.sender, pending);
            emit Harvest(msg.sender, _lp, pending);
        }
        user.rewardDebt = (user.amount * pool.accVTXPerShare) / 1e12;

        IBaseRewardPool rewarder = IBaseRewardPool(
            addressToPoolInfo[_lp].rewarder
        );
        rewarder.getReward(msg.sender);
    }

    /// @notice Deposit LP tokens to MasterChef for VTX allocation, and stakes them on rewarder as well. This function is only callable by a pool helper
    /// @param _lp Staking token of the pool
    /// @param _amount Amount to deposit
    /// @param sender Address of the user the pool helper is depositing for
    function depositFor(
        address _lp,
        uint256 _amount,
        address sender
    ) external {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        UserInfo storage user = userInfo[_lp][sender];
        require(msg.sender == pool.helper, "Only helper can call depositFor");
        IERC20(pool.lpToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        updatePool(_lp);
        if (user.amount > 0) {
            // Harvest VTX
            uint256 pending = (user.amount * pool.accVTXPerShare) /
                1e12 -
                user.rewardDebt;
            safeVTXTransfer(sender, pending);
            emit Harvest(sender, _lp, pending);
        }
        user.amount = user.amount + _amount;
        user.available = user.available + _amount;
        user.rewardDebt = (user.amount * pool.accVTXPerShare) / 1e12;

        IBaseRewardPool rewarder = IBaseRewardPool(
            addressToPoolInfo[_lp].rewarder
        );
        if (_amount == 0 && address(rewarder) != address(0)) {
            rewarder.getReward(sender);
        } else {
            if (address(rewarder) != address(0)) {
                rewarder.stakeFor(sender, _amount);
                rewarder.getReward(sender);
            }
            emit Deposit(sender, _lp, _amount);
        }
    }

    /// @notice Depositing locker tokens, which has transfer function overridden. Internal Function, only called by lock
    /// @param _lp Staking token of the pool
    /// @param _amount Amount to deposit
    /// @param sender Address of the user the pool helper is depositing for
    function lockDeposit(
        address _lp,
        uint256 _amount,
        address sender
    ) internal {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        UserInfo storage user = userInfo[_lp][sender];
        updatePool(_lp);
        if (user.amount > 0) {
            // Harvest VTX
            uint256 pending = (user.amount * pool.accVTXPerShare) /
                1e12 -
                user.rewardDebt;
            safeVTXTransfer(sender, pending);
            emit Harvest(sender, _lp, pending);
        }
        user.amount = user.amount + _amount;
        user.available = user.available + _amount;
        user.rewardDebt = (user.amount * pool.accVTXPerShare) / 1e12;

        IBaseRewardPool rewarder = IBaseRewardPool(
            addressToPoolInfo[_lp].rewarder
        );
        if (_amount == 0 && address(rewarder) != address(0)) {
            rewarder.getReward(sender);
        } else {
            if (address(rewarder) != address(0)) {
                rewarder.stakeFor(sender, _amount);
                rewarder.getReward(sender);
            }
            emit Deposit(sender, _lp, _amount);
        }
    }

    /// @notice Lock tokens in a deposit box, and prevents the user from withdrawing it for the lock time. Stakes the lock tokens in the relevant rewarder.
    /// @param _lp Staking token of the pool
    /// @param _amount Amount to deposit
    /// @param _index Index of the deposit box we want to lock.
    /// @param force If true, will refresh timer of the selected box, locking the current and the deposit for the lock time
    function lock(
        address _lp,
        uint256 _amount,
        uint256 _index,
        bool force
    ) external {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        UserInfo storage user = userInfo[_lp][msg.sender];
        require(user.available >= _amount, "lock exceeds staked");
        user.available = user.available - _amount;
        ILocker(pool.locker).depositFor(_amount, _index, msg.sender, force);
        lockDeposit(pool.locker, _amount, msg.sender);
        emit Locked(msg.sender, _lp, _amount);
    }

    /// @notice Unlocks tokens from a deposit box
    /// @param _lp Staking token of the pool
    /// @param _amount Amount to unlock
    /// @param _index Index of the deposit box we want to unlock.
    function unlock(
        address _lp,
        uint256 _amount,
        uint256 _index
    ) public {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        UserInfo storage user = userInfo[_lp][msg.sender];
        lockWithdraw(pool.locker, _amount, msg.sender);
        ILocker(pool.locker).withdrawFor(_amount, _index, msg.sender);
        user.available = user.available + _amount;
        emit Unlocked(msg.sender, _lp, _amount);
    }

    /// @notice Unlocks tokens from multiple deposit boxes
    /// @param _lp Staking token of the pool
    /// @param _amount List of amounts to unlock
    /// @param _index Index list of the deposit boxes we want to unlock.
    function multiUnlock(
        address _lp,
        uint256[] calldata _amount,
        uint256[] calldata _index
    ) external {
        require(_amount.length == _index.length);
        for (uint256 i = 0; i < _amount.length; ++i) {
            unlock(_lp, _amount[i], _index[i]);
        }
    }

    /// @notice Claims for each of the pools in the list
    /// @param _lps Staking tokens of the pools we want to claim from
    /// @param user_address address of user to claim for
    function multiclaim(address[] calldata _lps, address user_address)
        external
    {
        uint256 length = _lps.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            address _lp = _lps[pid];
            PoolInfo storage pool = addressToPoolInfo[_lp];
            UserInfo storage user = userInfo[_lp][user_address];
            updatePool(_lp);
            if (user.amount > 0) {
                // Harvest VTX
                uint256 pending = (user.amount * pool.accVTXPerShare) /
                    1e12 -
                    user.rewardDebt;
                safeVTXTransfer(user_address, pending);
                emit Harvest(user_address, _lp, pending);
            }
            user.amount = user.amount;
            user.rewardDebt = (user.amount * pool.accVTXPerShare) / 1e12;
            if (address(pool.rewarder) != address(0)) {
                IBaseRewardPool rewarder = IBaseRewardPool(pool.rewarder);
                rewarder.getReward(user_address);
            }
        }
    }

    /// @notice Withdraw LP tokens from MasterChef.
    /// @param _lp Staking token of the pool
    /// @param _amount amount to withdraw
    function withdraw(address _lp, uint256 _amount) external {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        UserInfo storage user = userInfo[_lp][msg.sender];
        require(user.available >= _amount, "withdraw: not good");

        updatePool(_lp);

        // Harvest VTX
        uint256 pending = (user.amount * pool.accVTXPerShare) /
            1e12 -
            user.rewardDebt;
        safeVTXTransfer(msg.sender, pending);
        emit Harvest(msg.sender, _lp, pending);

        user.amount = user.amount - _amount;
        user.available = user.available - _amount;
        user.rewardDebt = (user.amount * pool.accVTXPerShare) / 1e12;

        address rewarder = addressToPoolInfo[_lp].rewarder;
        if (address(rewarder) != address(0)) {
            IBaseRewardPool(rewarder).withdrawFor(msg.sender, _amount, true);
        }

        IERC20(pool.lpToken).safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _lp, _amount);
    }

    /// @notice Withdraw LP tokens from MasterChef for a specific user. Can only be called by pool helper
    /// @param _lp Staking token of the pool
    /// @param _amount amount to withdraw
    /// @param _sender address of the user to withdraw for
    function withdrawFor(
        address _lp,
        uint256 _amount,
        address _sender
    ) external {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        UserInfo storage user = userInfo[_lp][_sender];
        require(msg.sender == pool.helper, "Only Helper can WithdrawFor");
        require(user.available >= _amount, "withdraw: not good");

        updatePool(_lp);

        // Harvest VTX
        uint256 pending = (user.amount * pool.accVTXPerShare) /
            1e12 -
            user.rewardDebt;
        safeVTXTransfer(_sender, pending);
        emit Harvest(_sender, _lp, pending);

        user.amount = user.amount - _amount;
        user.available = user.available - _amount;
        user.rewardDebt = (user.amount * pool.accVTXPerShare) / 1e12;

        address rewarder = addressToPoolInfo[_lp].rewarder;
        if (address(rewarder) != address(0)) {
            IBaseRewardPool(rewarder).withdrawFor(_sender, _amount, true);
        }

        IERC20(pool.lpToken).safeTransfer(address(msg.sender), _amount);
        emit Withdraw(_sender, _lp, _amount);
    }

    /// @notice Withdraw locker tokens, which has transfer function overridden. Internal Function, only called by lock
    /// @param _lp Staking token of the pool
    /// @param _amount amount to withdraw
    /// @param _sender address of the user to withdraw for
    function lockWithdraw(
        address _lp,
        uint256 _amount,
        address _sender
    ) internal {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        UserInfo storage user = userInfo[_lp][_sender];
        require(user.available >= _amount, "withdraw: not good");

        updatePool(_lp);

        // Harvest VTX
        uint256 pending = (user.amount * pool.accVTXPerShare) /
            1e12 -
            user.rewardDebt;
        safeVTXTransfer(_sender, pending);
        emit Harvest(_sender, _lp, pending);

        user.amount = user.amount - _amount;
        user.available = user.available - _amount;
        user.rewardDebt = (user.amount * pool.accVTXPerShare) / 1e12;

        address rewarder = addressToPoolInfo[_lp].rewarder;
        if (address(rewarder) != address(0)) {
            IBaseRewardPool(rewarder).withdrawFor(_sender, _amount, true);
        }

        emit Withdraw(_sender, _lp, _amount);
    }

    /// @notice Withdraw all available tokens without caring about rewards. EMERGENCY ONLY.
    /// @param _lp Staking token of the pool
    function emergencyWithdraw(address _lp) external {
        PoolInfo storage pool = addressToPoolInfo[_lp];
        UserInfo storage user = userInfo[_lp][msg.sender];
        IERC20(pool.lpToken).safeTransfer(address(msg.sender), user.available);
        emit EmergencyWithdraw(msg.sender, _lp, user.available);
        user.amount = user.amount - user.available;
        user.available = 0;
        user.rewardDebt = (user.amount * pool.accVTXPerShare) / 1e12;
    }

    // Safe vtx transfer function, just in case if rounding error causes pool to not have enough VTXs.
    function safeVTXTransfer(address _to, uint256 _amount) internal {
        uint256 vtxBal = vtx.balanceOf(address(this));
        if (_amount > vtxBal) {
            vtx.transfer(_to, vtxBal);
        } else {
            vtx.transfer(_to, _amount);
        }
    }

    /// @notice Update dev address to a new dev
    /// @param _devAddr new dev address
    function dev(address _devAddr) public {
        require(msg.sender == devAddr, "dev: wut?");
        devAddr = _devAddr;
        emit SetDevAddress(msg.sender, _devAddr);
    }

    /// @notice Set dev percent. Only callable by Owner
    /// @param _newDevPercent new dev percent.
    function setDevPercent(uint256 _newDevPercent) public onlyOwner {
        require(
            0 <= _newDevPercent && _newDevPercent <= 1000,
            "setDevPercent: invalid percent value"
        );
        require(
            treasuryPercent + _newDevPercent + investorPercent <= 1000,
            "setDevPercent: total percent over max"
        );
        devPercent = _newDevPercent;
    }

    /// @notice Update treasury address to a new treasury
    /// @param _treasuryAddr new treasury address
    function setTreasuryAddr(address _treasuryAddr) public {
        require(msg.sender == treasuryAddr, "setTreasuryAddr: wut?");
        treasuryAddr = _treasuryAddr;
    }

    /// @notice Set treasury percent. Only callable by Owner
    /// @param _newTreasuryPercent new treasury percent.
    function setTreasuryPercent(uint256 _newTreasuryPercent) public onlyOwner {
        require(
            0 <= _newTreasuryPercent && _newTreasuryPercent <= 1000,
            "setTreasuryPercent: invalid percent value"
        );
        require(
            devPercent + _newTreasuryPercent + investorPercent <= 1000,
            "setTreasuryPercent: total percent over max"
        );
        treasuryPercent = _newTreasuryPercent;
    }

    /// @notice Update the investor address to a new address
    /// @param _investorAddr new investor address
    function setInvestorAddr(address _investorAddr) public {
        require(msg.sender == investorAddr, "setInvestorAddr: wut?");
        investorAddr = _investorAddr;
    }

    /// @notice Set investor percent. Only callable by Owner
    /// @param _newInvestorPercent new investor percent.
    function setInvestorPercent(uint256 _newInvestorPercent) public onlyOwner {
        require(
            0 <= _newInvestorPercent && _newInvestorPercent <= 1000,
            "setInvestorPercent: invalid percent value"
        );
        require(
            devPercent + _newInvestorPercent + treasuryPercent <= 1000,
            "setInvestorPercent: total percent over max"
        );
        investorPercent = _newInvestorPercent;
    }

    /// @notice Update the emission rate of VTX for MasterChef
    /// @param _vtxPerSec new emission per second
    function updateEmissionRate(uint256 _vtxPerSec) public onlyOwner {
        massUpdatePools();
        vtxPerSec = _vtxPerSec;
        emit UpdateEmissionRate(msg.sender, _vtxPerSec);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
pragma solidity ^0.8.0;

import "MintableERC20.sol";

/// @title Vtx
/// @author Vector Team
contract VTX is MintableERC20 {
    uint256 public immutable MAX_SUPPLY = 100 * 10**6 * 1 ether;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialMint,
        address _initialMintTo
    ) MintableERC20(_name, _symbol) {
        _mint(_initialMintTo, _initialMint);
    }

    
    // VTX is owned by the Masterchief of the protocol, forbidding misuse of this function
    function mint(address _to, uint256 _amount) public override onlyOwner {
        if (totalSupply() + _amount > MAX_SUPPLY) {
            _amount = MAX_SUPPLY - totalSupply();
        }
        _mint(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";

contract MintableERC20 is ERC20, Ownable {
    /*
    The ERC20 deployed will be owned by the others contracts of the protocol, specifically by
    Masterchief and MainStaking, forbidding the misuse of these functions for nefarious purposes
    */
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {} 

    function mint(address account, uint256 amount) external virtual onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external virtual onlyOwner {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
pragma solidity ^0.8.0;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/
* Synthetix: BaseRewardPool.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "SafeERC20.sol";
import "Ownable.sol";
import "IERC20Metadata.sol";


/// @title A contract for managing rewards for a pool
/// @author Vector Team
/// @notice You can use this contract for getting informations about rewards for a specific pools
contract BaseRewardPool is Ownable {
    using SafeERC20 for IERC20Metadata;

    address public mainRewardToken;
    address public immutable stakingToken;
    address public immutable operator;
    address public immutable rewardManager;

    address[] public rewardTokens;

    uint256 private _totalSupply;

    struct Reward {
        address rewardToken;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 historicalRewards;
    }

    mapping(address => uint256) private _balances;
    mapping(address => Reward) public rewards;
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public userRewards;
    mapping(address  => bool) public isRewardToken;

    event RewardAdded(uint256 reward, address indexed token);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(
        address indexed user,
        uint256 reward,
        address indexed token
    );

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _operator,
        address _rewardManager
    ) {
        stakingToken = _stakingToken;
        operator = _operator;
        rewards[_rewardToken] = Reward({
            rewardToken: _rewardToken,
            rewardPerTokenStored: 0,
            queuedRewards: 0,
            historicalRewards: 0
        });
        rewardTokens.push(_rewardToken);
        isRewardToken[_rewardToken] = true;
        rewardManager = _rewardManager;
    }

    /// @notice Returns decimals of reward token
    /// @param _rewardToken Address of reward token
    /// @return Returns decimals of reward token
    function rewardDecimals(address _rewardToken)
        public
        view
        returns (uint256)
    {
        return IERC20Metadata(_rewardToken).decimals();
    }

    /// @notice Returns address of staking token
    /// @return address of staking token
    function getStakingToken() external view returns (address) {
        return stakingToken;
    }

    /// @notice Returns decimals of staking token
    /// @return Returns decimals of staking token
    function stakingDecimals() public view returns (uint256) {
        return IERC20Metadata(stakingToken).decimals();
    }

    /// @notice Returns current supply of staked tokens
    /// @return Returns current supply of staked tokens
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns amount of staked tokens by account
    /// @param _account Address account
    /// @return Returns amount of staked tokens by account
    function balanceOf(address _account) external view returns (uint256) {
        return _balances[_account];
    }

    modifier updateReward(address _account) {
        uint256 rewardTokensLength = rewardTokens.length;
        for (uint256 index = 0; index < rewardTokensLength; ++index) {
            address rewardToken = rewardTokens[index];
            userRewards[rewardToken][_account] = earned(_account, rewardToken);
            userRewardPerTokenPaid[rewardToken][_account] = rewardPerToken(
                rewardToken
            );
        }
        _;
    }

    modifier onlyManager() {
        require(msg.sender == rewardManager, "Only Manager");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only Operator");
        _;
    }

    /// @notice Updates the reward information for one account
    /// @param _account Address account
    function updateFor(address _account) external {
        uint256 length = rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            userRewards[rewardToken][_account] = earned(_account, rewardToken);
            userRewardPerTokenPaid[rewardToken][_account] = rewardPerToken(
                rewardToken
            );
        }
    }

    /// @notice Returns amount of reward token per staking tokens in pool
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token per staking tokens in pool
    function rewardPerToken(address _rewardToken)
        public
        view
        returns (uint256)
    {
        return rewards[_rewardToken].rewardPerTokenStored;
    }

    /// @notice Returns amount of reward token earned by a user
    /// @param _account Address account
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token earned by a user
    function earned(address _account, address _rewardToken)
        public
        view
        returns (uint256)
    {
        return (
            (((_balances[_account] *
                (rewardPerToken(_rewardToken) -
                    userRewardPerTokenPaid[_rewardToken][_account])) /
                (10**stakingDecimals())) + userRewards[_rewardToken][_account])
        );
    }

    /// @notice Updates information for a user in case of staking. Can only be called by the Masterchief operator
    /// @param _for Address account
    /// @param _amount Amount of newly staked tokens by the user on masterchief
    /// @return Returns True
    function stakeFor(address _for, uint256 _amount)
        external
        onlyOperator
        updateReward(_for)
        returns (bool)
    {
        _totalSupply = _totalSupply + _amount;
        _balances[_for] = _balances[_for] + _amount;

        emit Staked(_for, _amount);

        return true;
    }

    /// @notice Updates informaiton for a user in case of a withdraw. Can only be called by the Masterchief operator
    /// @param _for Address account
    /// @param _amount Amount of withdrawed tokens by the user on masterchief
    /// @return Returns True
    function withdrawFor(
        address _for,
        uint256 _amount,
        bool claim
    ) external onlyOperator updateReward(_for) returns (bool) {
        _totalSupply = _totalSupply - _amount;
        _balances[_for] = _balances[_for] - _amount;

        emit Withdrawn(_for, _amount);

        if (claim) {
            getReward(_for);
        }

        return true;
    }

    /// @notice Calculates and sends reward to user. Only callable by masterchief
    /// @param _account Address account
    /// @return Returns True
    function getReward(address _account)
        public
        updateReward(_account)
        onlyOperator
        returns (bool)
    {
        uint256 length = rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            uint256 reward = earned(_account, rewardToken);
            if (reward > 0) {
                userRewards[rewardToken][_account] = 0;
                IERC20Metadata(rewardToken).safeTransfer(_account, reward);
                emit RewardPaid(_account, reward, rewardToken);
            }
        }
        return true;
    }

    /// @notice Sends new rewards to be distributed to the users staking. Only callable by MainStaking
    /// @param _amountReward Amount of reward token to be distributed
    /// @param _rewardToken Address reward token
    /// @return Returns True
    function queueNewRewards(uint256 _amountReward, address _rewardToken)
        external
        onlyManager
        returns (bool)
    {   
        if (!isRewardToken[_rewardToken]) {
            rewardTokens.push(_rewardToken);
            isRewardToken[_rewardToken] = true;
        }
        IERC20Metadata(_rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amountReward
        );
        Reward storage rewardInfo = rewards[_rewardToken];
        rewardInfo.historicalRewards =
            rewardInfo.historicalRewards +
            _amountReward;
        if (_totalSupply == 0) {
            rewardInfo.queuedRewards += _amountReward;
        } else {
            if (rewardInfo.queuedRewards > 0) {
                _amountReward += rewardInfo.queuedRewards;
                rewardInfo.queuedRewards = 0;
            }
            rewardInfo.rewardPerTokenStored =
                rewardInfo.rewardPerTokenStored +
                (_amountReward * 10**stakingDecimals()) /
                _totalSupply;
        }
        emit RewardAdded(_amountReward, _rewardToken);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseRewardPool {
    function rewardTokens() external view returns (address[] memory);

    function getStakingToken() external view returns (address);

    function getReward(address _account) external returns (bool);

    function rewardDecimals(address token) external view returns (uint256);

    function stakingDecimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function rewardPerToken(address token) external view returns (uint256);

    function updateFor(address account) external;

    function earned(address account, address token)
        external
        view
        returns (uint256);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function withdrawFor(
        address user,
        uint256 amount,
        bool claim
    ) external;

    function queueNewRewards(uint256 _rewards, address token)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILocker {
    function setLockTime(uint256 _newvalue) external;
    function maxDeposits() external returns (uint256 n);
    function getUserNthDeposit(address _user, uint256 n)
        external
        view
        returns (
            uint256 depositTime,
            uint256 endTime,
            uint256 amount
        );

    function getUserDepositLength(address _user)
        external
        view
        returns (uint256 nbDeposits);

    function depositFor(
        uint256 _amount,
        uint256 _index,
        address user,
        bool force
    ) external;

    function withdrawFor(
        uint256 _amount,
        uint256 _index,
        address user
    ) external;
}