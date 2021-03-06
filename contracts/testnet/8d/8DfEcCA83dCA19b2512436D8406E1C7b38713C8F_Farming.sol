/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

// SPDX-License-Identifier: MIT

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

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

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

// P1 - P3: OK
pragma solidity 0.6.12;
// solhint-disable avoid-low-level-calls
// T1 - T4: OK
contract BaseBoringBatchable {
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }    
    
    // F3 - F9: OK
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C1 - C21: OK
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns(bool[] memory successes, bytes[] memory results) {
        // Interactions
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

// T1 - T4: OK
contract BoringBatchable is BaseBoringBatchable {
    // F1 - F9: OK
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    // C1 - C21: OK
    function permitToken(IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        // Interactions
        // X1 - X5
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

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

pragma solidity 0.6.12;

library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }

    function toUInt256(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Integer < 0");
        return uint256(a);
    }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IMasterChef {
    using BoringERC20 for IERC20;
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. AVA to distribute per block.
        uint256 lastRewardBlock;  // Last block number that AVA distribution occurs.
        uint256 accAVAPerShare; // Accumulated AVA per share, times 1e12. See below.
    }

    function poolInfo(uint256 pid) external view returns (IMasterChef.PoolInfo memory);
    function totalAllocPoint() external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
}

pragma solidity 0.6.12;

interface IMigratorChef {
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    function migrate(IERC20 token) external returns (IERC20);
}

/// @notice The (older) MasterChef contract gives out a constant number of AVA tokens per block.
/// It is the only address with minting rights for AVA.
/// The idea for this MasterChef V2 (MCV2) contract is therefore to be the owner of a dummy token
/// that is deposited into the MasterChef V1 (MCV1) contract.
/// The allocation point for this pool on MCV1 is the total allocation point for all pools that receive double incentives.
contract Farming is BoringOwnable, BoringBatchable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using SignedSafeMath for int256;

    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of AVA entitled to the user.
    struct UserPeriodInfo {
        uint256 amount;
        int256 rewardDebt;
        uint256 depositTime;
        uint256 withdrawTime;
    }

    struct UserInfo { UserPeriodInfo[4] userPeriod; }
    
    // Info of each pool.
    struct FarmPeriod {
        IERC20 lpToken;          // Address of LP token contract.
        uint128 accAVAPerShare;   // Accumulated AVA per share, times 1e12. See below.
        uint256 lastRewardTime;  // Last block number that AVA distribution occurs.
        uint256 allocPoint;
        uint256 allocPointShare;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of AVA to distribute per block.
    struct PoolInfo { 
        FarmPeriod farmPeriod1; 
        FarmPeriod farmPeriod2; 
        FarmPeriod farmPeriod3; 
        FarmPeriod farmPeriod4; 
        uint256 allocPoint; 
    }
    
    // Dev address.
    address public devaddr;

    // Dev fund (10%, initially)
    uint256 public devFundDivRate = 10;

    /// @notice Address of AVA contract.
    IERC20 public immutable ava;

    /// @notice Address of xUSD contract.
    IERC20 public xusd;

    /// @notice Info of each MCV2 pool.
    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) private userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public avaPerSecond;
    uint256 private constant ACC_AVA_PRECISION = 1e12;

    uint256 public constant dayInSeconds = 86400;
    uint256[4] public periodInDays;
    uint256[4] public periodShares;
    uint256[4] public periodInSeconds;

    event Deposit(address indexed user, uint256 indexed pid, uint256 indexed mid, uint256 amount, uint256 depositBlock, uint256 withdrawBlock);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 indexed mid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 indexed mid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 indexed mid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardTime, uint256 lpSupply, uint256 accAVAPerShare);
    event LogAVAPerSecond(uint256 avaPerSecond);

    /// @param _ava The AVA token contract address.
    constructor(
        IERC20 _ava,
        IERC20 _xusd,
        address _devaddr,
        uint256 _avaPerSecond,
        uint256[4] memory _periodInDays,
        uint256[4] memory _periodShares
    ) public {
        require(address(_ava) != address(0)
                && address(_xusd) != address(0)
                && _devaddr != address(0),
                "Can not be address(0)");

        uint totalPeriodShares = 0;
        for(uint256 i=0; i<4; ++i){
            totalPeriodShares += _periodShares[i];    
        }
        require(totalPeriodShares == 100, "Total Period Shares must be 100");

        ava = _ava;
        xusd = _xusd;
        devaddr = _devaddr;
        avaPerSecond = _avaPerSecond;
        totalAllocPoint = 0;
        periodInDays = _periodInDays;
        periodShares = _periodShares;
        for(uint256 i=0; i<4; ++i){
            periodInSeconds[i] = periodInDays[i]*dayInSeconds;
        }
    }

    function getUserInfo(uint256 _pid) external view returns (UserInfo memory) {
        return userInfo[_pid][msg.sender];
    }

    /// @notice Returns the number of MCV2 pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param _allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    function add(uint256 _allocPoint, IERC20 _lpToken) public onlyOwner {
        uint256 len = poolInfo.length;
        for (uint256 pid = 0; pid < len; ++pid) {
            FarmPeriod memory farm = getFarmPeriod(pid, 0);
            require(address(farm.lpToken) != address(_lpToken), "LP Token has been added");
        }

        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        FarmPeriod[4] memory fps;
        for (uint256 periodId = 0; periodId < 4; ++periodId) {
            FarmPeriod memory fp = FarmPeriod({
                lpToken: _lpToken,
                allocPoint: _allocPoint*periodShares[periodId]/100,
                lastRewardTime: block.timestamp,
                accAVAPerShare: 0,
                allocPointShare: periodShares[periodId]
            });
            fps[periodId]=fp;
        }    
        poolInfo.push(PoolInfo({farmPeriod1:fps[0], farmPeriod2:fps[1], farmPeriod3:fps[2], farmPeriod4:fps[3], allocPoint: _allocPoint}));

        emit LogPoolAddition(poolInfo.length.sub(1), _allocPoint, _lpToken);
    }

    /// @notice Update the given pool's AVA allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        FarmPeriod[4] memory fps;
        for (uint256 fpid = 0; fpid < 4; ++fpid) {
            FarmPeriod memory fp = getFarmPeriod(_pid,fpid);
            fp.allocPoint = _allocPoint*fp.allocPointShare/100;
            fps[fpid]=fp;
        }
        poolInfo[_pid].farmPeriod1 = fps[0];
        poolInfo[_pid].farmPeriod2 = fps[1];
        poolInfo[_pid].farmPeriod3 = fps[2];
        poolInfo[_pid].farmPeriod4 = fps[3];
        poolInfo[_pid].allocPoint = _allocPoint;
        
        emit LogSetPool(_pid, _allocPoint);
    }

    /// @notice Sets the ava per second to be distributed. Can only be called by the owner.
    /// @param _avaPerSecond The amount of AVA to be distributed per second.
    function setAVAPerSecond(uint256 _avaPerSecond) public onlyOwner {
        require(_avaPerSecond <= 1e18);
        avaPerSecond = _avaPerSecond;
        emit LogAVAPerSecond(_avaPerSecond);
    }

    function setXusd(IERC20 _xusd) external onlyOwner{        
        require(address(_xusd) != address(0), "can not be address(0)");
        xusd = _xusd;
    }

    function getFarmPeriod(uint256 _poolId, uint256 _periodId) public view returns (FarmPeriod memory farm){
        require(_periodId<4, "getPeriod: wrong farmPeriod Index");
        
        PoolInfo memory pool = poolInfo[_poolId];
        if (_periodId == 0) {
            farm = pool.farmPeriod1;
        } else if (_periodId == 1) {
            farm = pool.farmPeriod2;
        } else if (_periodId == 2) {
            farm = pool.farmPeriod3;
        } else {
            farm = pool.farmPeriod4;
        }
    }

    /// @notice View function to see pending AVA on frontend.
    /// @param _pid The index of the pool.
    /// @param _fpid The index of the farming pool.
    /// @param _user Address of user.
    /// @return pending AVA reward for a given user.
    function pendingAVA(uint256 _pid, uint256 _fpid, address _user) external view returns (uint256 pending) {
        FarmPeriod memory farmPeriod = getFarmPeriod(_pid,_fpid);
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accAVAPerShare = farmPeriod.accAVAPerShare;
        uint256 lpSupply = farmPeriod.lpToken.balanceOf(address(this));
        if (block.timestamp > farmPeriod.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(farmPeriod.lastRewardTime);
            uint256 avaReward = time.mul(avaPerSecond).mul(farmPeriod.allocPoint) / totalAllocPoint;
            accAVAPerShare = accAVAPerShare.add(avaReward.mul(ACC_AVA_PRECISION) / lpSupply);
        }
        pending = int256(user.userPeriod[_fpid].amount.mul(accAVAPerShare) / ACC_AVA_PRECISION).sub(user.userPeriod[_fpid].rewardDebt).toUInt256();
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 len = poolInfo.length;
        for (uint256 pid = 0; pid < len; ++pid) {
            for (uint256 fpid = 0; fpid < 4; ++fpid) {
                updatePool(pid,fpid);
            } 
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param _pid The index of the pool.
    /// @param _fpid The index of the farming pool.
    /// @return farm Returns the pool that was updated.
    function updatePool(uint256 _pid, uint256 _fpid) public returns (FarmPeriod memory farm) {
        farm = getFarmPeriod(_pid, _fpid);
        if (block.timestamp > farm.lastRewardTime) {
            uint256 lpSupply = farm.lpToken.balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(farm.lastRewardTime);
                uint256 avaReward = time.mul(avaPerSecond).mul(farm.allocPoint) / totalAllocPoint;

                uint256 avaBal = ava.balanceOf(address(this));
                uint256 avaAmount = avaReward / devFundDivRate;
                
                if(avaBal >= avaAmount){
                    ava.safeTransfer(devaddr, avaAmount);
                } else{
                    // formula calculation based on AVABar contract enter function
                    uint256 totalAVA = ava.balanceOf(address(xusd));
                    uint256 totalShares = xusd.totalSupply();
                    if (totalShares == 0 || totalAVA == 0) {
                        xusd.mint(devaddr, avaAmount);
                    } else {
                        uint256 what = avaAmount.mul(totalShares) / totalAVA;
                        xusd.mint(devaddr, what);
                    }
                }

                farm.accAVAPerShare = farm.accAVAPerShare.add((avaReward.mul(ACC_AVA_PRECISION) / lpSupply).to128());
            }
            
            farm.lastRewardTime = block.timestamp;
            
            if (_fpid == 0) {
                poolInfo[_pid].farmPeriod1 = farm;
            } else if (_fpid == 1) {
                poolInfo[_pid].farmPeriod2 = farm;
            } else if (_fpid == 2) {
                poolInfo[_pid].farmPeriod3 = farm;
            } else {
                poolInfo[_pid].farmPeriod4 = farm;
            }
            
            emit LogUpdatePool(_pid, farm.lastRewardTime, lpSupply, farm.accAVAPerShare);
        }
    }

    /// @notice Deposit LP tokens to MCV2 for AVA allocation.
    /// @param _pid The index of the pool.
    /// @param _fpid The index of the farming pool.
    /// @param _amount LP token amount to deposit.
    function deposit(uint256 _pid, uint256 _fpid, uint256 _amount) public {
        FarmPeriod memory farmPeriod = updatePool(_pid, _fpid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        UserPeriodInfo memory upi;

        uint upLength = user.userPeriod.length;

        if (upLength > 0){
            upi = user.userPeriod[_fpid];
            upi.amount = upi.amount.add(_amount);
            upi.rewardDebt = upi.rewardDebt.add(int256(_amount.mul(farmPeriod.accAVAPerShare) / ACC_AVA_PRECISION));
            user.userPeriod[_fpid] = upi;
        } else{
            for (uint256 fpid = 0; fpid < 4; ++fpid) {
                user.userPeriod[fpid].amount = 0;
                user.userPeriod[fpid].rewardDebt = 0;
            }
            user.userPeriod[_fpid].amount = _amount;
            user.userPeriod[_fpid].rewardDebt = int256(_amount.mul(farmPeriod.accAVAPerShare) / ACC_AVA_PRECISION);
        }

        farmPeriod.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        user.userPeriod[_fpid].depositTime = block.timestamp;
        user.userPeriod[_fpid].withdrawTime = user.userPeriod[_fpid].depositTime.add(periodInSeconds[_fpid]);

        emit Deposit(msg.sender, _pid, _fpid, _amount, user.userPeriod[_fpid].depositTime, user.userPeriod[_fpid].withdrawTime);
    }
    
    /// @notice Harvest proceeds for transaction sender to sender.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _fpid The index of the farming pool.
    function harvest(uint256 _pid, uint256 _fpid) public {
        FarmPeriod memory farmPeriod = updatePool(_pid, _fpid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        int256 accumulatedAVA = int256(user.userPeriod[_fpid].amount.mul(farmPeriod.accAVAPerShare) / ACC_AVA_PRECISION);
        uint256 _pendingAVA = accumulatedAVA.sub(user.userPeriod[_fpid].rewardDebt).toUInt256();

        // Effects
        user.userPeriod[_fpid].rewardDebt = accumulatedAVA;

        // Interactions
        if (_pendingAVA != 0) {
            uint256 avaBal = ava.balanceOf(address(this));
        
            if(avaBal >= _pendingAVA){
                ava.safeTransfer(msg.sender, _pendingAVA);
            } else{
                // formula calculation based on AVABar contract enter function
                uint256 totalAVA = ava.balanceOf(address(xusd));
                uint256 totalShares = xusd.totalSupply();
                if (totalShares == 0 || totalAVA == 0) {
                    xusd.mint(msg.sender, _pendingAVA);
                } else {
                    uint256 what = _pendingAVA.mul(totalShares) / totalAVA;
                    xusd.mint(msg.sender, what);
                }
            }
        }

        emit Harvest(msg.sender, _pid, _fpid, _pendingAVA);
    }
    
    /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to sender.
    /// @param _pid The index of the pool.
    /// @param _fpid The index of the farming pool.
    /// @param _amount LP token amount to withdraw.
    function withdraw(uint256 _pid, uint256 _fpid, uint256 _amount) public {
        FarmPeriod memory farmPeriod = updatePool(_pid, _fpid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(block.timestamp > user.userPeriod[_fpid].withdrawTime, "withdraw: still in lock period");
        require(user.userPeriod[_fpid].amount >= _amount, "withdraw: insufficient balance");

        int256 accumulatedAVA = int256(user.userPeriod[_fpid].amount.mul(farmPeriod.accAVAPerShare) / ACC_AVA_PRECISION);
        uint256 _pendingAVA = accumulatedAVA.sub(user.userPeriod[_fpid].rewardDebt).toUInt256();

        // Effects
        user.userPeriod[_fpid].rewardDebt = accumulatedAVA.sub(int256(_amount.mul(farmPeriod.accAVAPerShare) / ACC_AVA_PRECISION));
        user.userPeriod[_fpid].amount = user.userPeriod[_fpid].amount.sub(_amount);
        
        // Interactions
        uint256 avaBal = ava.balanceOf(address(this));
        
        if(avaBal >= _pendingAVA){
            ava.safeTransfer(msg.sender, _pendingAVA);
        } else{
            // formula calculation based on AVABar contract enter function
            uint256 totalAVA = ava.balanceOf(address(xusd));
            uint256 totalShares = xusd.totalSupply();
            if (totalShares == 0 || totalAVA == 0) {
                xusd.mint(msg.sender, _pendingAVA);
            } else {
                uint256 what = _pendingAVA.mul(totalShares) / totalAVA;
                xusd.mint(msg.sender, what);
            }
        }

        farmPeriod.lpToken.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _pid, _fpid, _amount);
        emit Harvest(msg.sender, _pid, _fpid, _pendingAVA);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param _pid The index of the pool.
    /// @param _fpid The index of the farming pool.
    function emergencyWithdraw(uint256 _pid, uint256 _fpid) public {
        FarmPeriod memory farmPeriod = getFarmPeriod(_pid,_fpid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.userPeriod[_fpid].amount;
        user.userPeriod[_fpid].amount = 0;
        user.userPeriod[_fpid].rewardDebt = 0;

        // Note: transfer can fail or succeed if `amount` is zero.
        farmPeriod.lpToken.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, _fpid, amount);
    }

    function setDev(address _dev) public onlyOwner {
        require(devaddr != address(0), "setDev: invalid address");
        devaddr = _dev;
    }
    
    // * Additional functions separate from the original MC contract *
    function config(uint256[4] memory _periodInDays,  uint256[4] memory _periodShares) public onlyOwner {
        uint totalPeriodShares = 0;
        for(uint256 i=0; i<4; ++i){
            totalPeriodShares += _periodShares[i];    
        }
        require(totalPeriodShares == 100, "Total Period Shares must be 100");

        massUpdatePools();
        periodInDays = _periodInDays;
        periodShares = _periodShares;
        for(uint256 i=0; i<4; ++i){
            periodInSeconds[i] = periodInDays[i]*dayInSeconds;
        }
    }

    function setDevFundDivRate(uint256 _devFundDivRate) public onlyOwner {
        require(_devFundDivRate <= 100, "devFundDivRate must be less or equal to 100");
        devFundDivRate = _devFundDivRate;
    }
}