// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';
import './libraries/SafeOwnableUpgradeable.sol';
import './interfaces/IAsset.sol';
import './interfaces/IVePtp.sol';
import './interfaces/IMasterPlatypusV4.sol';
import './interfaces/IBoostedMultiRewarder.sol';
import './interfaces/IPlatypusTreasure.sol';

interface IVoter {
    function distribute(address _lpToken) external;

    function pendingPtp(address _lpToken) external view returns (uint256);
}

/// MasterPlatypus is a boss. He says "go f your blocks maki boy, I'm gonna use timestamp instead"
/// In addition, he feeds himself from Venom. So, vePtp holders boost their (non-dialuting) emissions.
/// This contract rewards users in function of their amount of lp staked (dialuting pool) factor (non-dialuting pool)
/// Factor and sumOfFactors are updated by contract VePtp.sol after any vePtp minting/burning (veERC20Upgradeable hook).
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Platypus is sufficiently
/// distributed and the community can show to govern itself.
/// ## Updates
/// - V4 is an improved version of MasterPlatypus(V1), which packs storage variables in order to save gas.
/// - Compatible with gauge voting
contract MasterPlatypusV4 is
    Initializable,
    SafeOwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IMasterPlatypusV4
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // The strongest platypus out there (ptp token).
    IERC20 public ptp;
    // Venom does not seem to hurt the Platypus, it only makes it stronger.
    IVePtp public vePtp;
    // New Master Platypus address for future migrations
    IMasterPlatypusV4 public newMasterPlatypus;
    // Platypus Treasure. The address is initailized with 0 until we enable the Platypus Treasure contract
    IPlatypusTreasure public platypusTreasure;
    // Address of Voter
    address public voter;
    // Emissions: dialutingRepartition and non-dialutingRepartition must add to 1000 => 100%
    // Dialuting emissions repartition (e.g. 300 for 30%)
    uint16 public dialutingRepartition;
    // The maximum number of pools, in case updateFactor() exceeds block gas limit
    uint256 public maxPoolLength;
    // Set of all LP tokens that have been added as pools
    EnumerableSet.AddressSet private lpTokens;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Add(uint256 indexed pid, IAsset indexed lpToken, IBoostedMultiRewarder indexed rewarder);
    event SetRewarder(uint256 indexed pid, IBoostedMultiRewarder indexed rewarder);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositFor(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionRepartition(
        address indexed user,
        uint256 dialutingRepartition,
        uint256 nonDialutingRepartition
    );
    event UpdateVePTP(address indexed user, address oldVePTP, address newVePTP);

    /// @dev Modifier ensuring that certain function can only be called by VePtp
    modifier onlyVePtp() {
        require(address(vePtp) == msg.sender, 'notVePtp: wut?');
        _;
    }

    /// @dev Modifier ensuring that certain function can only be called by PlatypusTreasure
    modifier onlyPlatypusTreasure() {
        require(address(platypusTreasure) == msg.sender, 'not platypusTreasure');
        _;
    }

    function initialize(
        IERC20 _ptp,
        IVePtp _vePtp,
        address _voter,
        uint16 _dialutingRepartition
    ) public initializer {
        require(address(_ptp) != address(0), 'ptp address cannot be zero');
        require(address(_vePtp) != address(0), 'vePtp address cannot be zero');
        require(address(_voter) != address(0), 'voter address cannot be zero');
        require(_dialutingRepartition <= 1000, 'dialuting repartition must be in range 0, 1000');

        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        ptp = _ptp;
        vePtp = _vePtp;
        voter = _voter;
        dialutingRepartition = _dialutingRepartition;
        maxPoolLength = 50;
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setNewMasterPlatypus(IMasterPlatypusV4 _newMasterPlatypus) external onlyOwner {
        newMasterPlatypus = _newMasterPlatypus;
    }

    function setMaxPoolLength(uint256 _maxPoolLength) external onlyOwner {
        require(poolInfo.length <= _maxPoolLength);
        maxPoolLength = _maxPoolLength;
    }

    /**
     * @notice external function to set Platypus Treasure
     * @dev only owner can call this function
     * @param _platypusTreasure address of Platypus Treasure to set
     */
    function setPlatypusTreasure(address _platypusTreasure) external onlyOwner {
        require(address(_platypusTreasure) != address(0));
        platypusTreasure = IPlatypusTreasure(_platypusTreasure);
    }

    function nonDialutingRepartition() external view returns (uint256) {
        return 1000 - dialutingRepartition;
    }

    /// @notice returns pool length
    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    function getPoolId(address _lp) external view returns (uint256) {
        require(lpTokens.contains(address(_lp)), 'invalid lp');
        return lpTokens._inner._indexes[bytes32(uint256(uint160(_lp)))] - 1;
    }

    function getUserInfo(uint256 _pid, address _user) external view returns (UserInfo memory) {
        return userInfo[_pid][_user];
    }

    function getSumOfFactors(uint256 _pid) external view override returns (uint256) {
        return poolInfo[_pid].sumOfFactors;
    }

    /// @notice Add a new lp to the pool. Can only be called by the owner.
    /// @dev Reverts if the same LP token is added more than once.
    /// @param _lpToken the corresponding lp token
    /// @param _rewarder the rewarder
    function add(IAsset _lpToken, IBoostedMultiRewarder _rewarder) public onlyOwner {
        require(Address.isContract(address(_lpToken)), 'add: LP token must be a valid contract');
        require(
            Address.isContract(address(_rewarder)) || address(_rewarder) == address(0),
            'add: rewarder must be contract or zero'
        );
        require(!lpTokens.contains(address(_lpToken)), 'add: LP already added');
        require(poolInfo.length < maxPoolLength, 'add: exceed max pool');

        // update PoolInfo with the new LP
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                rewarder: _rewarder,
                sumOfFactors: 0,
                accPtpPerShare: 0,
                accPtpPerFactorShare: 0
            })
        );

        // add lpToken to the lpTokens enumerable set
        lpTokens.add(address(_lpToken));
        emit Add(poolInfo.length - 1, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's rewarder
    /// @param _pid the pool id
    /// @param _rewarder the rewarder
    function setRewarder(uint256 _pid, IBoostedMultiRewarder _rewarder) public onlyOwner {
        require(
            Address.isContract(address(_rewarder)) || address(_rewarder) == address(0),
            'set: rewarder must be contract or zero'
        );

        PoolInfo storage pool = poolInfo[_pid];

        pool.rewarder = _rewarder;
        emit SetRewarder(_pid, _rewarder);
    }

    /// @notice Get bonus token info from the rewarder contract for a given pool, if it is a double reward farm
    /// @param _pid the pool id
    function rewarderBonusTokenInfo(uint256 _pid)
        public
        view
        override
        returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols)
    {
        PoolInfo storage pool = poolInfo[_pid];
        if (address(pool.rewarder) == address(0)) {
            return (bonusTokenAddresses, bonusTokenSymbols);
        }

        bonusTokenAddresses = pool.rewarder.rewardTokens();

        uint256 len = bonusTokenAddresses.length;
        bonusTokenSymbols = new string[](len);
        for (uint256 i; i < len; ++i) {
            if (address(bonusTokenAddresses[i]) == address(0)) {
                bonusTokenSymbols[i] = 'AVAX';
            } else {
                bonusTokenSymbols[i] = IERC20Metadata(address(bonusTokenAddresses[i])).symbol();
            }
        }
    }

    /// @notice Update reward variables for all pools.
    /// @dev Be careful of gas spending!
    function massUpdatePools() external override {
        uint256 length = poolInfo.length;
        for (uint256 pid; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _pid the pool id
    function updatePool(uint256 _pid) external override {
        _updatePool(_pid);
    }

    function _updatePool(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];
        IVoter(voter).distribute(address(pool.lpToken));
    }

    /// @dev We might distribute PTP over a period of time to prevent front-running
    /// Refer to synthetix/StakingRewards.sol notifyRewardAmount
    /// Note: This looks safe from reentrancy.
    function notifyRewardAmount(address _lpToken, uint256 _amount) external override {
        require(_amount > 0, 'MasterPlatypus: zero amount');

        // this line reverts if asset is not in the list
        uint256 pid = lpTokens._inner._indexes[bytes32(uint256(uint160(_lpToken)))] - 1;
        PoolInfo storage pool = poolInfo[pid];

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            return;
        }

        // update accPtpPerShare to reflect dialuting rewards
        pool.accPtpPerShare += toUint128((_amount * 1e12 * dialutingRepartition) / (lpSupply * 1000));

        // update accPtpPerFactorShare to reflect non-dialuting rewards
        if (pool.sumOfFactors > 0) {
            pool.accPtpPerFactorShare += toUint128(
                (_amount * 1e12 * (1000 - dialutingRepartition)) / (pool.sumOfFactors * 1000)
            );
        }

        // Event is not emitted. as Voter should have already emitted it

        // SafeERC20 is not needed as PTP will revert if transfer fails
        ptp.transferFrom(msg.sender, address(this), _amount); // transfer the distro in
    }

    /// @notice Helper function to migrate fund from multiple pools to the new MasterPlatypus.
    /// @notice user must initiate transaction from masterchef
    /// @dev Assume the orginal MasterPlatypus has stopped emisions
    /// hence we skip IVoter(voter).distribute() to save gas cost
    function migrate(uint256[] calldata _pids) external override nonReentrant {
        require(address(newMasterPlatypus) != (address(0)), 'to where?');

        _multiClaim(_pids);
        for (uint256 i; i < _pids.length; ++i) {
            uint256 pid = _pids[i];
            UserInfo storage user = userInfo[pid][msg.sender];

            if (user.amount > 0) {
                PoolInfo storage pool = poolInfo[pid];
                pool.lpToken.approve(address(newMasterPlatypus), user.amount);
                newMasterPlatypus.depositFor(pid, user.amount, msg.sender);

                pool.sumOfFactors -= toUint128(user.factor);

                // remove user
                delete userInfo[pid][msg.sender];
            }
        }
    }

    /// @notice Deposit LP tokens to MasterChef for PTP allocation on behalf of user
    /// @dev user must initiate transaction from masterchef
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    /// @param _user the user being represented
    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external override nonReentrant whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // update pool in case user has deposited
        IVoter(voter).distribute(address(pool.lpToken));
        _updateFor(_pid, _user, user.amount + _amount);

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        emit DepositFor(_user, _pid, _amount);
    }

    /// @notice Deposit LP tokens to MasterChef for PTP allocation.
    /// @dev it is possible to call this function with _amount == 0 to claim current rewards
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    function deposit(uint256 _pid, uint256 _amount)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 reward, uint256[] memory additionalRewards)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        IVoter(voter).distribute(address(pool.lpToken));
        (reward, additionalRewards) = _updateFor(_pid, msg.sender, user.amount + _amount);

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice claims rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function multiClaim(uint256[] calldata _pids)
        external
        override
        nonReentrant
        whenNotPaused
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        )
    {
        return _multiClaim(_pids);
    }

    /// @notice private function to claim rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function _multiClaim(uint256[] memory _pids)
        private
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        )
    {
        // accumulate rewards for each one of the pids in pending
        amounts = new uint256[](_pids.length);
        additionalRewards = new uint256[][](_pids.length);
        for (uint256 i; i < _pids.length; ++i) {
            PoolInfo storage pool = poolInfo[_pids[i]];
            IVoter(voter).distribute(address(pool.lpToken));

            UserInfo storage user = userInfo[_pids[i]][msg.sender];
            if (user.amount > 0) {
                // increase pending to send all rewards once
                uint256 poolRewards = ((uint256(user.amount) *
                    pool.accPtpPerShare +
                    uint256(user.factor) *
                    pool.accPtpPerFactorShare) / 1e12) +
                    user.claimablePtp -
                    user.rewardDebt;

                user.claimablePtp = 0;

                // update reward debt
                user.rewardDebt = toUint128(
                    (uint256(user.amount) * pool.accPtpPerShare + uint256(user.factor) * pool.accPtpPerFactorShare) /
                        1e12
                );

                // increase reward
                reward += poolRewards;

                amounts[i] = poolRewards;
                emit Harvest(msg.sender, _pids[i], amounts[i]);

                // if exist, update external rewarder
                IBoostedMultiRewarder rewarder = pool.rewarder;
                if (address(rewarder) != address(0)) {
                    additionalRewards[i] = rewarder.onPtpReward(
                        msg.sender,
                        user.amount,
                        user.amount,
                        user.factor,
                        user.factor
                    );
                }
            }
        }
        // transfer all rewards
        // SafeERC20 is not needed as PTP will revert if transfer fails
        ptp.transfer(payable(msg.sender), reward);
    }

    /// @notice View function to see pending PTPs on frontend.
    /// @param _pid the pool id
    /// @param _user the user address
    function pendingTokens(uint256 _pid, address _user)
        external
        view
        override
        returns (
            uint256 pendingPtp,
            IERC20[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusTokens
        )
    {
        PoolInfo storage pool = poolInfo[_pid];

        // calculate accPtpPerShare and accPtpPerFactorShare
        uint256 pendingPtpForLp = IVoter(voter).pendingPtp(address(pool.lpToken));
        uint256 accPtpPerShare = pool.accPtpPerShare;
        uint256 accPtpPerFactorShare = pool.accPtpPerFactorShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply != 0) {
            accPtpPerShare += (pendingPtpForLp * 1e12 * dialutingRepartition) / (lpSupply * 1000);
        }
        if (pool.sumOfFactors > 0) {
            accPtpPerFactorShare +=
                (pendingPtpForLp * 1e12 * (1000 - dialutingRepartition)) /
                (pool.sumOfFactors * 1000);
        }

        // get pendingPtp
        UserInfo storage user = userInfo[_pid][_user];
        pendingPtp =
            ((uint256(user.amount) * accPtpPerShare + uint256(user.factor) * accPtpPerFactorShare) / 1e12) +
            user.claimablePtp -
            user.rewardDebt;

        (bonusTokenAddresses, bonusTokenSymbols) = rewarderBonusTokenInfo(_pid);

        // get pendingBonusToken
        IBoostedMultiRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            pendingBonusTokens = rewarder.pendingTokens(_user, user.amount, user.factor);
        }
    }

    /**
     * @notice internal function to withdraw lps on behalf of user
     * @dev pending rewards are transfered to user, lps are transfered to caller
     * @param _pid the pool id
     * @param _user the user being represented
     * @param _caller caller's address
     * @param _amount amount to withdraw
     */
    function _withdrawFor(
        uint256 _pid,
        address _user,
        address _caller,
        uint256 _amount
    ) internal returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        require(user.amount >= _amount, 'withdraw: not enough balance');

        IVoter(voter).distribute(address(pool.lpToken));
        (reward, additionalRewards) = _updateFor(_pid, _user, user.amount - _amount);

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transfer(_caller, _amount);
        emit Withdraw(_user, _pid, _amount);
    }

    /// @notice Distribute PTP rewards and Update user balance
    function _updateFor(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) internal returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // Harvest PTP
        if (user.amount > 0 || user.claimablePtp > 0) {
            reward =
                ((uint256(user.amount) * pool.accPtpPerShare + uint256(user.factor) * pool.accPtpPerFactorShare) /
                    1e12) +
                user.claimablePtp -
                user.rewardDebt;
            user.claimablePtp = 0;

            // SafeERC20 is not needed as PTP will revert if transfer fails
            ptp.transfer(payable(_user), reward);
            emit Harvest(_user, _pid, reward);
        }

        // update amount of lp staked
        uint256 oldAmount = user.amount;
        user.amount = toUint128(_amount);

        // update sumOfFactors
        uint128 oldFactor = user.factor;
        user.factor = toUint128(FixedPointMathLib.sqrt(user.amount * vePtp.balanceOf(_user)));

        // update reward debt
        user.rewardDebt = toUint128(
            (uint256(user.amount) * pool.accPtpPerShare + uint256(user.factor) * pool.accPtpPerFactorShare) / 1e12
        );

        // update rewarder before we update lpSupply and sumOfFactors
        IBoostedMultiRewarder rewarder = pool.rewarder;
        additionalRewards;
        if (address(rewarder) != address(0)) {
            additionalRewards = rewarder.onPtpReward(_user, oldAmount, _amount, oldFactor, user.factor);
        }

        pool.sumOfFactors = toUint128(pool.sumOfFactors + user.factor - oldFactor);
    }

    /// @notice Withdraw LP tokens from MasterPlatypus.
    /// @notice Automatically harvest pending rewards and sends to user
    /// @param _pid the pool id
    /// @param _amount the amount to withdraw
    function withdraw(uint256 _pid, uint256 _amount)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 reward, uint256[] memory additionalRewards)
    {
        (reward, additionalRewards) = _withdrawFor(_pid, msg.sender, msg.sender, _amount);

        if (address(platypusTreasure) != address(0x00)) {
            (bool isSolvent, ) = platypusTreasure.isSolvent(msg.sender, address(poolInfo[_pid].lpToken), true);
            require(isSolvent, 'remaining amount exceeds LTV');
        }
    }

    /// @notice Liquidate collateral LPs
    /// @dev only Platypus Treasure can call this function to liquidate
    /// @param _pid the pool id
    /// @param _user the user being represented
    /// @param _amount amount to withdraw
    function liquidate(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external nonReentrant onlyPlatypusTreasure {
        _withdrawFor(_pid, _user, msg.sender, _amount);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param _pid the pool id
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // reset rewarder before we update lpSupply and sumOfFactors
        IBoostedMultiRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onPtpReward(msg.sender, user.amount, 0, user.factor, 0);
        }

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transfer(address(msg.sender), user.amount);

        // update non-dialuting factor
        pool.sumOfFactors -= user.factor;

        user.amount = 0;
        user.factor = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    /// @notice updates emission repartition
    /// @param _dialutingRepartition the future dialuting repartition
    function updateEmissionRepartition(uint16 _dialutingRepartition) external onlyOwner {
        require(_dialutingRepartition <= 1000);
        dialutingRepartition = _dialutingRepartition;
        emit UpdateEmissionRepartition(msg.sender, _dialutingRepartition, 1000 - _dialutingRepartition);
    }

    /// @notice updates vePtp address
    /// @param _newVePtp the new VePtp address
    function setVePtp(IVePtp _newVePtp) external onlyOwner {
        require(address(_newVePtp) != address(0));
        IVePtp oldVePtp = vePtp;
        vePtp = _newVePtp;
        emit UpdateVePTP(msg.sender, address(oldVePtp), address(_newVePtp));
    }

    /// @notice updates factor after any vePtp token operation (minting/burning)
    /// @param _user the user to update
    /// @param _newVePtpBalance the amount of vePTP
    /// @dev can only be called by vePtp
    function updateFactor(address _user, uint256 _newVePtpBalance) external override onlyVePtp {
        // loop over each pool : beware gas cost!
        uint256 length = poolInfo.length;

        for (uint256 pid = 0; pid < length; ) {
            UserInfo storage user = userInfo[pid][_user];

            // skip if user doesn't have any deposit in the pool
            if (user.amount > 0) {
                PoolInfo storage pool = poolInfo[pid];

                // first, update pool
                IVoter(voter).distribute(address(pool.lpToken));

                // calculate pending
                uint256 pending = ((uint256(user.amount) *
                    pool.accPtpPerShare +
                    uint256(user.factor) *
                    pool.accPtpPerFactorShare) / 1e12) - user.rewardDebt;
                // increase claimablePtp
                user.claimablePtp += toUint128(pending);

                // update non-dialuting pool factor
                uint128 oldFactor = user.factor;
                user.factor = toUint128(FixedPointMathLib.sqrt(user.amount * _newVePtpBalance));

                // update reward debt, take into account newFactor
                user.rewardDebt = toUint128(
                    (uint256(user.amount) * pool.accPtpPerShare + uint256(user.factor) * pool.accPtpPerFactorShare) /
                        1e12
                );

                // update rewarder before we update sumOfFactors
                IBoostedMultiRewarder rewarder = pool.rewarder;
                if (address(rewarder) != address(0)) {
                    rewarder.onUpdateFactor(_user, user.amount, oldFactor, user.factor);
                }

                pool.sumOfFactors = pool.sumOfFactors + user.factor - oldFactor;
            }

            unchecked {
                ++pid;
            }
        }
    }

    /// @notice In case we need to manually migrate PTP funds from MasterChef
    /// Sends all remaining ptp from the contract to the owner
    function emergencyPtpWithdraw() external onlyOwner {
        // SafeERC20 is not needed as PTP will revert if transfer fails
        ptp.transfer(address(msg.sender), ptp.balanceOf(address(this)));
    }

    function version() external pure returns (uint256) {
        return 4;
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }
}

// SPDX-License-Identifier: MIT

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

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
 *
 * Note: This contract is backward compatible to OwnableUpgradeable of OZ except from that
 * transferOwnership is dropped.
 * __gap[0] is used as ownerCandidate, as changing storage is not supported yet
 * See https://forum.openzeppelin.com/t/storage-layout-upgrade-with-hardhat-upgrades/14567
 */
contract SafeOwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        _setOwner(address(0));
    }

    function ownerCandidate() public view returns (address) {
        return address(uint160(__gap[0]));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function proposeOwner(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0x0)) revert('ZeroAddress');
        // __gap[0] is used as ownerCandidate
        __gap[0] = uint256(uint160(newOwner));
    }

    function acceptOwnership() external {
        if (ownerCandidate() != msg.sender) revert('Unauthorized');
        _setOwner(msg.sender);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Interface of Asset
 */
interface IAsset is IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function underlyingToken() external view returns (address);

    function underlyingTokenBalance() external view returns (uint256);

    function cash() external view returns (uint256);

    function liability() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import './IVeERC20.sol';

/**
 * @dev Interface of the VePtp
 */
interface IVePtp is IVeERC20 {
    function isUser(address _addr) external view returns (bool);

    function deposit(uint256 _amount) external;

    function claim() external;

    function claimable(address _addr) external view returns (uint256);

    function claimableWithXp(address _addr) external view returns (uint256 amount, uint256 xp);

    function withdraw(uint256 _amount) external;

    function vePtpBurnedOnWithdraw(address _addr, uint256 _amount) external view returns (uint256);

    function stakeNft(uint256 _tokenId) external;

    function unstakeNft() external;

    function getStakedNft(address _addr) external view returns (uint256);

    function getStakedPtp(address _addr) external view returns (uint256);

    function levelUp(uint256[] memory platypusBurned) external;

    function levelDown() external;

    function getVotes(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IAsset.sol';
import './IBoostedMultiRewarder.sol';

/**
 * @dev Interface of the MasterPlatypusV4
 */
interface IMasterPlatypusV4 {
    // Info of each user.
    struct UserInfo {
        // 256 bit packed
        uint128 amount; // How many LP tokens the user has provided.
        uint128 factor; // non-dialuting factor = sqrt (lpAmount * vePtp.balanceOf())
        // 256 bit packed
        uint128 rewardDebt; // Reward debt. See explanation below.
        uint128 claimablePtp;
        //
        // We do some fancy math here. Basically, any point in time, the amount of PTPs
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accPtpPerShare + user.factor * pool.accPtpPerFactorShare) / 1e12) -
        //        user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPtpPerShare`, `accPtpPerFactorShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IAsset lpToken; // Address of LP token contract.
        IBoostedMultiRewarder rewarder;
        uint128 sumOfFactors; // 20.18 fixed point. The sum of all non dialuting factors by all of the users in the pool
        uint128 accPtpPerShare; // 26.12 fixed point. Accumulated PTPs per share, times 1e12.
        uint128 accPtpPerFactorShare; // 26.12 fixed point. Accumulated ptp per factor share
    }

    function getSumOfFactors(uint256) external view returns (uint256);

    function poolLength() external view returns (uint256);

    function getPoolId(address) external view returns (uint256);

    function getUserInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingPtp,
            IERC20[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusTokens
        );

    function rewarderBonusTokenInfo(uint256 _pid)
        external
        view
        returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        );

    function withdraw(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function liquidate(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external;

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function updateFactor(address _user, uint256 _newVePtpBalance) external;

    function notifyRewardAmount(address _lpToken, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IBoostedMultiRewarder {
    function onPtpReward(
        address _user,
        uint256 _lpAmount,
        uint256 _newLpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external returns (uint256[] memory rewards);

    function onUpdateFactor(
        address _user,
        uint256 _lpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external;

    function pendingTokens(
        address _user,
        uint256 _lpAmount,
        uint256 _factor
    ) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPlatypusTreasure {
    function isSolvent(
        address _user,
        address _token,
        bool _open
    ) external view returns (bool solvent, uint256 debtAmount);
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.9;

interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}