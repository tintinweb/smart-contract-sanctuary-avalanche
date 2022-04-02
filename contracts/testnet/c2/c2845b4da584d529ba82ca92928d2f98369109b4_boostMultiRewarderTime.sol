/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-02
*/

// File: @boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: @boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol

pragma solidity 0.6.12;
library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// File: contracts/interfaces/IRewarder.sol



pragma solidity 0.6.12;

interface IRewarder {
    using BoringERC20 for IERC20;
    function onFlakeReward(uint256 pid, address user, address recipient, uint256 oldAmount, uint256 newLpAmount,bool bHarvest) external;
    function pendingTokens(uint256 pid, address user, uint256 flakeAmount) external view returns (IERC20[] memory, uint256[] memory);
}

// File: @boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol

pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }
    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }
    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

// File: @boringcrypto/boring-solidity/contracts/BoringOwnable.sol


// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract BoringOwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract BoringOwnable is BoringOwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        
        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// File: contracts/boostRewarder/IMiniChefPool.sol

pragma solidity 0.6.12;

interface IMiniChefPool {
    function lpToken(uint256 pid) external view returns (IERC20 _lpToken);
    function lpGauges(uint256 pid) external view returns (IERC20 _lpGauge);
}

// File: contracts/interfaces/IBoost.sol


pragma solidity 0.6.12;

interface IBoost {
    function getTotalBoostedAmount(uint256 _pid,address _user,uint256 _lpamount,uint256 _baseamount)external view returns(uint256,uint256);
    function boostDeposit(uint256 _pid,address _account,uint256 _amount) external;
    function boostApplyWithdraw(uint256 _pid,address _account,uint256 _amount) external;
    function cancelAllBoostApplyWithdraw(uint256 _pid,address _account) external;
    function boostWithdraw(uint256 _pid,address _account) external;
    function boostStakedFor(uint256 _pid,address _account) external view returns (uint256);
    function boostTotalStaked(uint256 _pid) external view returns (uint256);
    function getBoostToken(uint256 _pid) external view returns(address);
    function boostTotalWithdrawPendingFor(uint256 _pid,address _account) external view returns (uint256);
    function boostAvailableWithdrawPendingFor(uint256 _pid,address _account) external view returns (uint256,uint256);
}

// File: contracts/boostRewarder/boostMultiRewarderTime.sol


pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;






/// @author @0xKeno
contract boostMultiRewarderTime is IRewarder,  BoringOwnable{
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;

    uint256 public pid;
    IBoost public booster;
    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of Flake entitled to the user.
    struct UserInfo {
        uint256 rewardDebt;
        uint256 unpaidRewards;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of Flake to distribute per block.
    struct PoolInfo {
        uint128 accFlakePerShare;
        uint64 lastRewardTime;
        uint256 rewardPerSecond;
        IERC20 rewardToken;
    }

    /// @notice Info of each pool.

    PoolInfo[] public poolInfos;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    address private immutable MASTERCHEF_V2;
    uint256 private constant ACC_TOKEN_PRECISION = 1e12;
    uint256 internal unlocked;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }

    event LogOnReward(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event LogPoolAddition(uint256 indexed pid,address indexed rewardToken, uint256 rewardPerSecond);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardTime, uint256 lpSupply, uint256 accFlakePerShare);
    event LogRewardPerSecond(uint256 rewardPerSecond);
    event LogInit();

    event SetBooster(address indexed booster);

    constructor (address _MASTERCHEF_V2,uint256 _pid) public {
        MASTERCHEF_V2 = _MASTERCHEF_V2;
        pid = _pid;
        unlocked = 1;
    }


    function onFlakeReward (uint256 _pid, address _user, address to, uint256 oldAmount, uint256 lpToken,bool bHarvest) onlyMCV2 lock override external {

        _pid = _pid;
        uint nLen = poolInfos.length;
        for (uint i=0;i<nLen;i++){
            onPoolReward(i,_user,to,oldAmount,lpToken,bHarvest);
        }
    }
    function onPoolReward (uint256 index, address _user, address to, uint256 oldAmount,uint256 lpToken,bool bHarvest) internal {
        PoolInfo memory pool = updatePool(index);
        UserInfo storage user = userInfo[index][_user];
        uint256 pending;
        if (oldAmount > 0) {
            pending =
                (oldAmount.mul(pool.accFlakePerShare) / ACC_TOKEN_PRECISION).sub(
                    user.rewardDebt
                ).add(user.unpaidRewards);
                //for boost pending1
            (pending,,) = boostRewardAndGetTeamRoyalty(index,_user,oldAmount,pending);

            uint256 balance = pool.rewardToken.balanceOf(address(this));
            if (!bHarvest){
                user.unpaidRewards = pending;
            }else{
                if (pending > balance) {
                    pool.rewardToken.safeTransfer(to, balance);
                    user.unpaidRewards = pending - balance;
                } else {
                    pool.rewardToken.safeTransfer(to, pending);
                    user.unpaidRewards = 0;
                }
            }
        }
        user.rewardDebt = lpToken.mul(pool.accFlakePerShare) / ACC_TOKEN_PRECISION;
        emit LogOnReward(_user, index, pending - user.unpaidRewards, to);
    }
    function pendingTokens(uint256 _pid, address user, uint256) override external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
        _pid = _pid;
        uint nLen = poolInfos.length;
        IERC20[] memory _rewardTokens = new IERC20[](nLen);
        uint256[] memory _rewardAmounts = new uint256[](nLen);
        for (uint i=0;i<nLen;i++){
            
            _rewardTokens[i] = poolInfos[i].rewardToken;
            _rewardAmounts[i] = pendingToken(i, user);
        }
        return (_rewardTokens, _rewardAmounts);
    }
    
    /// @notice Sets the Flake per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of Flake to be distributed per second.
    function setRewardPerSecond(uint256 index,uint256 _rewardPerSecond) public onlyOwner {
        poolInfos[index].rewardPerSecond = _rewardPerSecond;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    modifier onlyMCV2 {
        require(
            msg.sender == MASTERCHEF_V2,
            "Only MCV2 can call this function."
        );
        _;
    }

    /// @notice Returns the number of MCV2 pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfos.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param rewardToken AP of the new pool.
    /// @param _rewardPerSecond Pid on MCV2
    function add(address rewardToken,uint256 _rewardPerSecond) public onlyOwner {
        uint256 lastRewardTime = block.timestamp;
        poolInfos.push(PoolInfo({
            rewardPerSecond: _rewardPerSecond,
            lastRewardTime: lastRewardTime.to64(),
            accFlakePerShare: 0,
            rewardToken:IERC20(rewardToken)
        }));
        
        emit LogPoolAddition(poolInfos.length-1, rewardToken,_rewardPerSecond);
    }

    /// @notice Update the given pool's Flake allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _rewardPerSecond New reward per second of the pool.
    function set(uint256 _pid, uint256 _rewardPerSecond) public onlyOwner {
        require(poolInfos.length>_pid,"rewarder : pid is not overflow!");
        poolInfos[_pid].rewardPerSecond = _rewardPerSecond;
        emit LogSetPool(_pid, _rewardPerSecond);
    }

    /// @notice Allows owner to reclaim/withdraw any tokens (including reward tokens) held by this contract
    /// @param token Token to reclaim, use 0x00 for Ethereum
    /// @param amount Amount of tokens to reclaim
    /// @param to Receiver of the tokens, first of his name, rightful heir to the lost tokens,
    /// reightful owner of the extra tokens, and ether, protector of mistaken transfers, mother of token reclaimers,
    /// the Khaleesi of the Great Token Sea, the Unburnt, the Breaker of blockchains.
    function reclaimTokens(address token, uint256 amount, address payable to) public onlyOwner {
        if (token == address(0)) {
            to.transfer(amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /// @notice View function to see pending Token
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending Flake reward for a given user.
    function pendingToken(uint256 _pid, address _user) public view returns (uint256 pending) {
        PoolInfo memory pool = poolInfos[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accFlakePerShare = pool.accFlakePerShare;
        uint256 lpSupply = totalSupply();
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTime);
            uint256 flakeReward = time.mul(pool.rewardPerSecond);
            accFlakePerShare = accFlakePerShare.add(flakeReward.mul(ACC_TOKEN_PRECISION) / lpSupply);
        }
        IERC20 lpGaugeToken = IMiniChefPool(MASTERCHEF_V2).lpGauges(pid);
        pending = (lpGaugeToken.balanceOf(_user).mul(accFlakePerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt).add(user.unpaidRewards);
        //for boost pending1
        (pending,,) = boostRewardAndGetTeamRoyalty(_pid,_user,lpGaugeToken.balanceOf(_user),pending);
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 _pid) public returns (PoolInfo memory pool) {
        pool = poolInfos[_pid];
        if (block.timestamp > pool.lastRewardTime) {
            uint256 lpSupply = totalSupply();

            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTime);
                uint256 flakeReward = time.mul(pool.rewardPerSecond);
                pool.accFlakePerShare = pool.accFlakePerShare.add((flakeReward.mul(ACC_TOKEN_PRECISION) / lpSupply).to128());
            }
            pool.lastRewardTime = block.timestamp.to64();
            poolInfos[_pid] = pool;
            emit LogUpdatePool(_pid, pool.lastRewardTime, lpSupply, pool.accFlakePerShare);
        }
    }

    function totalSupply()internal view returns (uint256){
        IMiniChefPool(MASTERCHEF_V2).lpGauges(pid).totalSupply();
    }
///////////////////////////////////////////////////////////////////////////////
    function setBooster(address _booster) public onlyOwner {
        booster = IBoost(_booster);
        emit SetBooster(_booster);
    }

    function boostRewardAndGetTeamRoyalty(uint256 _pid,address _user,uint256 _userLpAmount,uint256 _pendingFlake) view public returns(uint256,uint256,uint256) {
        if(address(booster)==address(0)) {
            return (_pendingFlake,0,0);
        }
        //record init reward
        uint256 incReward = _pendingFlake;
        uint256 teamRoyalty = 0;
        (_pendingFlake,teamRoyalty) = booster.getTotalBoostedAmount(_pid,_user,_userLpAmount,_pendingFlake);
        //(_pendingFlake+teamRoyalty) is total (boosted reward inclued baseAnount + init reward)
        incReward = _pendingFlake.add(teamRoyalty).sub(incReward);

        return (_pendingFlake,incReward,teamRoyalty);
    }
}