/**
 *Submitted for verification at snowtrace.io on 2022-05-24
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
    function onTokenReward(uint256 pid, address user, address recipient, uint256 oldAmount, uint256 newLpAmount,bool bHarvest) external;
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

    function boostWithdraw(uint256 _pid,address _account,uint256 _amount) external;
    function boostStakedFor(uint256 _pid,address _account) external view returns (uint256);
    function boostTotalStaked(uint256 _pid) external view returns (uint256);
    function getBoostToken(uint256 _pid) external view returns(address);

    function setBoostFunctionPara(uint256 _pid,uint256 _para0,uint256 _para1, uint256 _para2) external;
    function setBoostFarmFactorPara(uint256 _pid, bool  _enableTokenBoost, address _boostToken, uint256 _minBoostAmount, uint256 _maxIncRatio) external;
    function setWhiteListMemberStatus(uint256 _pid,address _user,bool _status)  external;

    function setFixedWhitelistPara(uint256 _pid,uint256 _incRatio,uint256 _whiteListfloorLimit) external;
    function setFixedTeamRatio(uint256 _pid,uint256 _ratio) external;
    //function setMulsigAndFarmChef ( address _multiSignature,  address _farmChef) external;

    function whiteListLpUserInfo(uint256 _pid,address _user) external view returns (bool);

}

// File: contracts/boostRewarder/boostMultiRewarderTime.sol


pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;






/// @author @0xKeno
contract boostMultiRewarderTime is IRewarder,  BoringOwnable{
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;

    uint256 public chefPid;
    IBoost public booster;

    IERC20 immutable public masterLpToken;

    /// @notice Info of each MCV2 user.
    /// `rewardDebt` The amount of Flake entitled to the user.
    struct UserInfo {
        uint256 rewardDebt;
        uint256 unpaidRewards;
    }

    /// @notice Info of each MCV2 pool.
    /// Also known as the amount of Flake to distribute per block.
    struct PoolInfo {
        uint128 accTokenPerShare;
        uint64 lastRewardTime;
        uint256 rewardPerSecond;
        IERC20 rewardToken;
    }

    /// @notice Info of each pool.

    PoolInfo[] public poolInfos;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    address public immutable MASTERCHEF_V2;
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

    constructor (address _MASTERCHEF_V2,uint256 _chefPid) public {
        MASTERCHEF_V2 = _MASTERCHEF_V2;
        chefPid = _chefPid;
        masterLpToken = IMiniChefPool(_MASTERCHEF_V2).lpToken(_chefPid);
        unlocked = 1;
    }


    function onTokenReward (uint256 _chefPid, address _user, address to, uint256 oldAmount, uint256 lpToken,bool bHarvest) onlyMCV2 lock override external {
        require(IMiniChefPool(MASTERCHEF_V2).lpToken(_chefPid) == masterLpToken,"lp token is not same");

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
            pending =(oldAmount.mul(pool.accTokenPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt);

            (pending,,) = boostRewardAndGetTeamRoyalty(index,_user,oldAmount,pending);
            pending =pending.add(user.unpaidRewards);

            uint256 balance = pool.rewardToken.balanceOf(address(this));
            if (!bHarvest){
                user.unpaidRewards = pending;
            }else{
                if (pending > balance) {
                    user.unpaidRewards = pending.sub(balance);
                    pool.rewardToken.safeTransfer(to, balance);
                } else {
                    pool.rewardToken.safeTransfer(to, pending);
                    user.unpaidRewards = 0;
                }
            }
        }
        user.rewardDebt = lpToken.mul(pool.accTokenPerShare) / ACC_TOKEN_PRECISION;
        emit LogOnReward(_user, index, pending - user.unpaidRewards, to);
    }

    function pendingTokens(uint256, address user, uint256) override external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {

        uint nLen = poolInfos.length;
        IERC20[] memory _rewardTokens = new IERC20[](nLen);
        uint256[] memory _rewardAmounts = new uint256[](nLen);
        for (uint i=0;i<nLen;i++){
            
            _rewardTokens[i] = poolInfos[i].rewardToken;
            _rewardAmounts[i] = pendingToken(i, user);
        }
        return (_rewardTokens, _rewardAmounts);
    }

    function rewardRates() external view returns (uint256[] memory) {
        uint nLen = poolInfos.length;
        uint256[] memory _rewardRates = new uint256[](nLen);

        for (uint i=0;i<nLen;i++){
          _rewardRates[i] =  poolInfos[i].rewardPerSecond;
        }

        return (_rewardRates);
    }

    
    /// @notice Sets the Token per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of Token to be distributed per second.
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
    function add(IERC20 rewardToken,uint256 _rewardPerSecond) public onlyOwner {
        uint256 lastRewardTime = block.timestamp;
        poolInfos.push(PoolInfo({
            rewardPerSecond: _rewardPerSecond,
            lastRewardTime: lastRewardTime.to64(),
            accTokenPerShare: 0,
            rewardToken: rewardToken
        }));
        
        emit LogPoolAddition(poolInfos.length-1, address(rewardToken),_rewardPerSecond);
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
    /// @param _index The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending Token reward for a given user.
    function pendingToken(uint256 _index, address _user) public view returns (uint256 pending) {
        PoolInfo memory pool = poolInfos[_index];
        UserInfo storage user = userInfo[_index][_user];

        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = totalSupply();
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTime);
            uint256 tokenReward = time.mul(pool.rewardPerSecond);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(ACC_TOKEN_PRECISION) / lpSupply);
        }

        IERC20 lpGaugeToken = IMiniChefPool(MASTERCHEF_V2).lpGauges(chefPid);
        pending = (lpGaugeToken.balanceOf(_user).mul(accTokenPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt).add(user.unpaidRewards);
        //for boost pending1
        (pending,,) = boostRewardAndGetTeamRoyalty(chefPid,_user,lpGaugeToken.balanceOf(_user),pending);
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param _idxs Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata _idxs) external {
        uint256 len = _idxs.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(_idxs[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param _index The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 _index) public returns (PoolInfo memory pool) {
        pool = poolInfos[_index];
        if (block.timestamp > pool.lastRewardTime) {
            uint256 lpSupply = totalSupply();

            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTime);
                uint256 tokenReward = time.mul(pool.rewardPerSecond);
                pool.accTokenPerShare = pool.accTokenPerShare.add((tokenReward.mul(ACC_TOKEN_PRECISION) / lpSupply).to128());
            }
            pool.lastRewardTime = block.timestamp.to64();
            poolInfos[_index] = pool;
            emit LogUpdatePool(_index, pool.lastRewardTime, lpSupply, pool.accTokenPerShare);
        }
    }

    function totalSupply()internal view returns (uint256){
        IMiniChefPool(MASTERCHEF_V2).lpGauges(chefPid).totalSupply();
    }
///////////////////////////////////////////////////////////////////////////////
    function setBooster(IBoost _booster) public onlyOwner {
        booster = _booster;
        emit SetBooster(address(_booster));
    }

    function boostRewardAndGetTeamRoyalty(uint256 _chefPid,address _user,uint256 _userLpAmount,uint256 _pendingToken) view public returns(uint256,uint256,uint256) {
        if(address(booster)==address(0)) {
            return (_pendingToken,0,0);
        }
        //record init reward
        uint256 incReward = _pendingToken;
        uint256 teamRoyalty = 0;
        (_pendingToken,teamRoyalty) = booster.getTotalBoostedAmount(_chefPid,_user,_userLpAmount,_pendingToken);
        //(_pendingToken+teamRoyalty) is total (boosted reward inclued baseAnount + init reward)
        incReward = _pendingToken.add(teamRoyalty).sub(incReward);

        return (_pendingToken,incReward,teamRoyalty);
    }
}