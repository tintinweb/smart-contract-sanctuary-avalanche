// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Katana.sol";

contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP katanas the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. KATANAS to distribute per second.
        uint256 lastRewardTimestamp;  // Last timestamp that KATANAS distribution occurs.
        uint256 accKatanasPerShare;   // Accumulated KATANAS per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 lpSupply;
    }

    // The KATANA!
    KatanaToken public katanas;
    // Dev address.
    address public devaddr;
    // KATANAS katanas created per second.
    uint256 public katanasPerSec;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP katanas.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The timestamp when Katanas mining starts.
    uint256 public startTimestamp;
    // The maximum supply for KATANA
    uint256 public maxSupply = 120 ether;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 katanasPerSec);
    event addPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint16 depositFeeBP);
    event setPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint16 depositFeeBP);
    event UpdateMaxSupply(uint256 newMaxSupply);
    event UpdateStartTimestamp(uint256 newStartTimestamp);

    constructor (
        KatanaToken _katanas,
        address _devaddr,
        address _feeAddress,
        uint256 _katanasPerSec,
        uint256 _startTimestamp
    ) public {
        katanas = _katanas;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        katanasPerSec = _katanasPerSec;
        startTimestamp = _startTimestamp;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        // valid ERC20 token
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 400, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTimestamp  = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardTimestamp: lastRewardTimestamp,
            accKatanasPerShare : 0,
            depositFeeBP : _depositFeeBP,
            lpSupply: 0
        }));

        emit addPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _depositFeeBP);
    }

    // Update the given pool's KATANAS allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 400, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;

        emit setPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, _depositFeeBP);
    }

    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (katanas.totalSupply() >= maxSupply) {
            return 0;
        }
        return _to.sub(_from);
    }

    // View function to see pending KATANAS on frontend.
    function pendingKatanas(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accKatanasPerShare = pool.accKatanasPerShare;
        if (block.timestamp  > pool.lastRewardTimestamp  && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
            uint256 katanasReward = multiplier.mul(katanasPerSec).mul(pool.allocPoint).div(totalAllocPoint);
            accKatanasPerShare = accKatanasPerShare.add(katanasReward.mul(1e12).div(pool.lpSupply));
        }
        return user.amount.mul(accKatanasPerShare).div(1e12).sub(user.rewardDebt);
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
        if (block.timestamp  <= pool.lastRewardTimestamp) {
            return;
        }
        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTimestamp  = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
        uint256 katanasReward = multiplier.mul(katanasPerSec).mul(pool.allocPoint).div(totalAllocPoint);
        // add condition for max supply
        if (katanas.totalSupply().add(katanasReward) > maxSupply) {
            katanasReward = maxSupply.sub(katanas.totalSupply());
        }
        // katanas.mint(devaddr, katanasReward.div(10));
        katanas.mint(address(this), katanasReward);
        pool.accKatanasPerShare = pool.accKatanasPerShare.add(katanasReward.mul(1e12).div(pool.lpSupply));
        pool.lastRewardTimestamp = block.timestamp;
    }

    // Deposit LP katanas to MasterChef for KATANAS allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accKatanasPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeTokensTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)) - balanceBefore;
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                pool.lpSupply = pool.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accKatanasPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP katanas from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accKatanasPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeTokensTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accKatanasPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        if (pool.lpSupply >=  amount) {
            pool.lpSupply = pool.lpSupply.sub(amount);
        } else {
            pool.lpSupply = 0;
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe katanas transfer function, just in case if rounding error causes pool to not have enough KATANAS.
    function safeTokensTransfer(address _to, uint256 _amount) internal {
        uint256 katanasBal = katanas.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > katanasBal) {
            transferSuccess = katanas.transfer(_to, katanasBal);
        } else {
            transferSuccess = katanas.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokensTransfer: transfer failed");
    }

    // Update dev address.
    function setDevAddress(address _devaddr) external {
        require(msg.sender == devaddr, "setDevAddress: FORBIDDEN");
        require(_devaddr != address(0), "!nonzero");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "!nonzero");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _katanasPerSec) external onlyOwner {
        massUpdatePools();
        katanasPerSec = _katanasPerSec;
        emit UpdateEmissionRate(msg.sender, _katanasPerSec);
    }

    function updateMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(katanas.totalSupply() < maxSupply, "cannot change max supply if max supply has already been reached");
        maxSupply = _newMaxSupply;
        emit UpdateMaxSupply(maxSupply);
    }

    // Only update before start of farm
    function updateStartTimestamp(uint256 _newStartTimestamp) external onlyOwner {
        require(block.timestamp < startTimestamp, "cannot change start timestamp if farm has already started");
        require(block.timestamp < _newStartTimestamp, "cannot set start timestamp in the past");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardTimestamp = _newStartTimestamp;
        }
        startTimestamp = _newStartTimestamp;

        emit UpdateStartTimestamp(startTimestamp);
    }

    function lazyAdd() external onlyOwner {
        require(poolInfo.length == 0, "addInitialPools: Initial Pools has already been added");

        add(700, IBEP20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7), 400, false); // WAVAX
        add(700, IBEP20(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB), 400, false); // WETH.e
        add(700, IBEP20(0x50b7545627a5162F82A992c33b87aDc75187B218), 400, false); // WBTC.e
        add(700, IBEP20(0x60781C2586D68229fde47564546784ab3fACA982), 400, false); // PNG
        add(700, IBEP20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118), 400, false); // USDT.e
        add(700, IBEP20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664), 400, false); // USDC.e        
        add(700, IBEP20(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70), 400, false); // DAI.e

        add(1000, IBEP20(0xbd918Ed441767fe7924e99F6a0E0B568ac1970D9), 400, false); // WAVAX-USDC.e
        add(1000, IBEP20(0x7c05d54fc5CB6e4Ad87c6f5db3b807C94bB89c52), 400, false); // WAVAX-WETH.e
        add(1000, IBEP20(0xc13E562d92F7527c4389Cd29C67DaBb0667863eA), 400, false); // USDC.e-USDT.e

        add(4300, katanas, 0, false); // KATANA
        add(7000, IBEP20(0x6D5b65b5DAF7dcDa475d98eCa50403ab32922189), 0, false); // KATANA-USDC.e
    }
}