// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "SafeMath.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "Ownable.sol";

import "BountieHunterToken.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

// MasterChef is the master of Bountie. He can make Bountie and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Bountie is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 depositBlock;
        //
        // We do some fancy math here. Basically, any point in time, the amount of CAKEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBountiePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBountiePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint256 accBountiePerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }

    // The BOUNTIE TOKEN!
    BountieHunter public bountie;
    // Dev address.
    address public devaddr;
    // CAKE tokens created per block.
    uint256 public bountiePerBlock;
    // Bonus muliplier for early cake makers.
    uint256 public BONUS_MULTIPLIER = 1;
  
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CAKE mining starts.
    uint256 public startBlock;

    event PenaltyLog(uint256 penaltyBlock, uint256 userDepositBlock);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        BountieHunter _bountie,
        address _devaddr,
        uint256 _bountiePerBlock,
        uint256 _startBlock
    ) public {
        bountie = _bountie;
        devaddr = _devaddr;
        bountiePerBlock = _bountiePerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _bountie,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accBountiePerShare: 0
        }));

        totalAllocPoint = 1000;

    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accBountiePerShare: 0
        }));
        updateStakingPool();
    }

    // Update the given pool's BOUNTIE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending BOUNTIEs on frontend.
    function pendingBountie(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBountiePerShare = pool.accBountiePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 bountieReward = multiplier.mul(bountiePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accBountiePerShare = accBountiePerShare.add(bountieReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accBountiePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 bountieReward = multiplier.mul(bountiePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        
        pool.accBountiePerShare = pool.accBountiePerShare.add(bountieReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BOUNTIE allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'deposit BOUNTIE by Enter Staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accBountiePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                _safeBountieTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBountiePerShare).div(1e12);
        user.depositBlock = block.number;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'withdraw BOUNTIE by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accBountiePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            _safeBountieTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBountiePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function currentBlock() public view returns(uint256) {
        return block.number;
    }

    // Stake BOUNTIE tokens to MasterChef
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        // if (user.amount > 0) {
        //     uint256 pending = user.amount.mul(pool.accBountiePerShare).div(1e12).sub(user.rewardDebt);
        //     if(pending > 0) {
        //         _safeBountieTransfer(msg.sender, pending);
        //     }
        // }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBountiePerShare).div(1e12);
        user.depositBlock = block.number;
        // syrup.mint(msg.sender, _amount);
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw BOUNTIE tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: cannot withdraw more than staked amount");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accBountiePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            _safeBountieTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            uint256 penalty = _calculatePenalty(address(msg.sender), _amount);
            uint256 totalWithdraw = _amount.sub(penalty);
            // Send the penalty to bountie wallet
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(devaddr, penalty);
            pool.lpToken.safeTransfer(address(msg.sender), totalWithdraw);
        }
        user.rewardDebt = user.amount.mul(pool.accBountiePerShare).div(1e12);
        emit Withdraw(msg.sender, 0, _amount);
    }

    function calculatePenalty(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[0][_user];
        require(user.amount > 0, "Penalty: You need to stake some BOUNTIE");
        return _calculatePenalty(_user, user.amount);
    }

    function _calculatePenalty(address _user, uint256 _amount) internal view returns (uint256) {
        // Staking penalty
        // Less than 2 weeks - 25% 
        // Less than 4 weeks - 15%
        // Less than 6 weeks - 10%
        // Less than 8 weeks - 5%
        // 8 weeks or more - 0%
        UserInfo storage user = userInfo[0][_user];

        uint256 curBlock = block.number;
        uint256 durationDayBlock = curBlock.sub(user.depositBlock);
        
        if(durationDayBlock < 403200) {
            uint256 penalty = _amount.mul(25).div(100);
            return penalty;
        } else if (durationDayBlock < 806400) {
            uint256 penalty = _amount.mul(15).div(100);
            return penalty;
        } else if (durationDayBlock < 1209600) {
            uint256 penalty = _amount.mul(10).div(100);
            return penalty;
        } else if (durationDayBlock < 1612800) {
            uint256 penalty = _amount.mul(5).div(100);
            return penalty;
        } else {
            return 0;
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function _safeBountieTransfer(address _to, uint256 _amount) internal {
        uint256 bountieBal = bountie.balanceOf(address(this));
        if (_amount > bountieBal) {
            bountie.transfer(_to, bountieBal);
        } else {
            bountie.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}