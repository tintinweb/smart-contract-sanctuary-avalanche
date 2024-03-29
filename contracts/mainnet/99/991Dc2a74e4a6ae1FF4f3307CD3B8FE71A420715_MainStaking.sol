// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Initializable.sol";
import "OwnableUpgradeable.sol";

import "IPTPStaking.sol";
import "IStableStaking.sol";
import "IMasterPlatypus.sol";
import "IBaseRewardPool.sol";
import "IPoolHelper.sol";
import "IMintableERC20.sol";
import "IMasterChefVTX.sol";
import "IxPTP.sol";
import "xTokenConvertor.sol";
import "IComputeAPR.sol";
import "IPTPNft.sol";

import "poolHelper.sol";
import "poolHelper2.sol";

library PoolHelperFactoryLib {
    function createPoolHelper(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _mainStaking,
        address _masterVtx,
        address _rewarder,
        address _xptp
    ) public returns (address) {
        PoolHelper pool = new PoolHelper(
            _pid,
            _stakingToken,
            _depositToken,
            _mainStaking,
            _masterVtx,
            _rewarder,
            _xptp
        );
        return address(pool);
    }

    function createPoolHelper2(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _assetToken,
        address _mainStaking,
        address _masterVtx,
        address _rewarder,
        address _xptp
    ) public returns (address) {
        PoolHelper2 pool = new PoolHelper2(
            _pid,
            _stakingToken,
            _depositToken,
            _assetToken,
            _mainStaking,
            _masterVtx,
            _rewarder,
            _xptp
        );
        return address(pool);
    }
}

import "MintableERC20.sol";

library ERC20FactoryLib {
    function createERC20(string memory name_, string memory symbol_) public returns (address) {
        ERC20 token = new MintableERC20(name_, symbol_);
        return address(token);
    }
}

import "IWavax.sol";
import "IVoter.sol";
import "IBribe.sol";

/// @title MainStaking
/// @author Vector Team
/// @notice Mainstaking is the contract that interacts with ALL PTP contract
/// @dev all functions except harvest are restricted either to owner or to other contracts from the vector protocol
/// @dev the owner of this contract holds a lot of power, and should be owned by a multisig
contract MainStaking is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // Addresses
    address public staking_ptp;
    address public ptp;
    address public xPTP;
    address public stakingStable;
    address public masterPlatypus;
    address public masterVtx;
    // APR Compute
    address public computeAPR;
    // Fees
    uint256 constant FEE_DENOMINATOR = 10000;
    uint256 public constant MAX_FEE = 2000;
    uint256 public CALLER_FEE;
    uint256 public constant MAX_CALLER_FEE = 500;
    uint256 public totalFee;

    struct Pair {
        uint256 tokenAmount0;
        uint256 tokenAmount1;
        uint256 ratio;
    }

    struct Fees {
        uint256 max_value;
        uint256 min_value;
        uint256 value;
        address to;
        bool isPTP;
        bool isAddress;
        bool isActive;
    }

    Fees[] public feeInfos;

    struct Pool {
        uint256 pid;
        bool isActive;
        address token;
        address lpAddress;
        uint256 sizeLp;
        uint256 size;
        address receiptToken;
        address rewarder;
        address helper;
    }
    mapping(address => Pool) public pools;
    mapping(address => address) public tokenToAvaxPool;

    mapping(address => address[]) public assetToBonusRewards;
    mapping(address => address) public tokenToPool;

    uint256 public percentPTPStored;
    address public storagePTP;

    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    address public smartConvertor;

    IVoter public voter;
    address public bribeManager;
    uint256 public bribeCallerFee;
    uint256 public bribeProtocolFee;
    address public bribeFeeCollector;

    event AddFee(address to, uint256 value, bool isPTP, bool isAddress);
    event SetFee(address to, uint256 value);
    event RemoveFee(address to);
    event NewDeposit(address indexed user, address indexed token, uint256 amount);
    event PtpClaimed(uint256 amount);
    event PtpHarvested(uint256 amount, uint256 callerFee);
    event RewardPaidTo(address to, address rewardToken, uint256 feeAmount);
    event NewWithdraw(address indexed user, address indexed token, uint256 amount);
    event NewPtpStaked(uint256 amount);
    event PoolAdded(address tokenAddress);

    /// @notice set the smartConvertor address
    /// @param _smartConvertor the smartConvertor address
    function setSmartConvertor(address _smartConvertor) external onlyOwner {
        smartConvertor = _smartConvertor;
    }

    function setBribeCallerFee(uint256 newValue) external onlyOwner {
        bribeCallerFee = newValue;
    }

    function setBribeProtocolFee(uint256 newValue) external onlyOwner {
        bribeProtocolFee = newValue;
    }

    function setBribeFeeCollector(address _collector) external onlyOwner {
        bribeFeeCollector = _collector;
    }

    /// @notice This function adds a fee to the vector protocol
    /// @dev the value of the fee must match the max fee requirement
    /// @param max the maximum value for that fee
    /// @param min the minimum value for that fee
    /// @param value the initial value for that fee
    /// @param to the address or contract that receives the fee
    /// @param isPTP true if the fee is sent as PTP, otherwise it will be xPTP
    /// @param isAddress true if the receiver is an address, otherwise it's a BaseRewarder
    function addFee(
        uint256 max,
        uint256 min,
        uint256 value,
        address to,
        bool isPTP,
        bool isAddress
    ) external onlyOwner {
        require(totalFee + value <= MAX_FEE, "Max fee reached");
        feeInfos.push(
            Fees({
                max_value: max,
                min_value: min,
                value: value,
                to: to,
                isPTP: isPTP,
                isAddress: isAddress,
                isActive: true
            })
        );
        totalFee += value;
        emit AddFee(to, value, isPTP, isAddress);
    }

    /// @notice change the value of some fee
    /// @dev the value must be between the min and the max specified when registering the fee
    /// @dev the value must match the max fee requirements
    /// @param index the index of the fee in the fee list
    /// @param value the new value of the fee
    function setFee(uint256 index, uint256 value) external onlyOwner {
        Fees storage fee = feeInfos[index];
        require(totalFee + value - fee.value <= MAX_FEE, "Max fee reached");
        totalFee = totalFee - fee.value + value;
        fee.value = value;
        emit SetFee(fee.to, value);
    }

    function setFeeRecipient(
        uint256 index,
        address _to,
        bool _isPtp,
        bool _isAddress
    ) external onlyOwner {
        Fees storage fee = feeInfos[index];
        fee.to = _to;
        fee.isPTP = _isPtp;
        fee.isAddress = _isAddress;
    }

    /// @notice remove some fee
    /// @param index the index of the fee in the fee list
    function removeFee(uint256 index) external onlyOwner {
        Fees storage fee = feeInfos[index];
        totalFee -= fee.value;
        fee.isActive = false;
        emit RemoveFee(fee.to);
    }

    /// @notice set the caller fee
    /// @param value the value of the caller fee
    function setCallerFee(uint256 value) external onlyOwner {
        // Check if the fee delta does not make the total fee go over the limit
        totalFee = totalFee + value - CALLER_FEE;
        require(totalFee <= MAX_FEE, "MAX Fee reached");
        CALLER_FEE = value;
    }

    function setVoter(address _voter) external onlyOwner {
        voter = IVoter(_voter);
    }

    function setBribeManager(address _manager) external onlyOwner {
        bribeManager = _manager;
    }

    /// @notice deposit stables in a platypus pool
    /// @dev this function can only be called by a PoolHelper
    /// @param token the token to deposit
    /// @param amount the amount to deposit
    /// @param sender the user to deposit for
    function deposit(
        address token,
        uint256 amount,
        address sender
    ) external {
        depositWithDifferentAsset(token, token, amount, sender);
    }

    /// @notice deposit in pools where the "asset" is different from the "token"
    /// @dev this function can only be called by a PoolHelper
    /// @param token the token to deposit
    /// @param amount the amount to deposit
    /// @param sender the user to deposit for
    function depositWithDifferentAsset(
        address token,
        address asset,
        uint256 amount,
        address sender
    ) public {
        // Get information of the pool of the token
        Pool storage poolInfo = pools[asset];
        //Requirements
        require(poolInfo.isActive, "Pool not active");
        require(msg.sender == poolInfo.helper, "Only helper can deposit");
        address staking = tokenToPool[asset];
        IERC20(token).safeTransferFrom(sender, address(this), amount);
        // Deposit to StableStaking Contract
        IERC20(token).approve(staking, amount);
        IStableStaking(staking).deposit(token, amount, address(this), block.timestamp);
        // Approve Transfer to Master Platypus for Staking
        uint256 lpReceived = IERC20(poolInfo.lpAddress).balanceOf(address(this));
        IERC20(poolInfo.lpAddress).approve(masterPlatypus, lpReceived);
        IMasterPlatypus(masterPlatypus).deposit(poolInfo.pid, lpReceived);
        // update variables
        uint256 amountTokenReceipt = getSharesForDepositTokens(amount, token);
        IMintableERC20(poolInfo.receiptToken).mint(msg.sender, amountTokenReceipt);
        poolInfo.size += amount;
        poolInfo.sizeLp += lpReceived;
        emit NewDeposit(sender, token, amount);
    }

    /// @notice harvest a pool from PTP
    /// @param token the address of the token to harvest
    /// @param isUser true if this function is not called by the vector Contracts. The caller gets the caller fee
    function harvest(address token, bool isUser) public {
        multiHarvest(token, isUser);
    }

    /// @notice harvest a pool with multiple rewards from PTP
    /// @param token the address of the token to harvest
    /// @param isUser true if this function is not called by the vector Contracts. The caller gets the caller fee
    function multiHarvest(address token, bool isUser) public {
        Pool storage poolInfo = pools[token];
        require(poolInfo.isActive, "Pool not active");
        address[] memory bonusTokens = assetToBonusRewards[token];
        uint256 bonusTokensLength = bonusTokens.length;
        uint256[] memory beforeBalances = new uint256[](bonusTokensLength);

        for (uint256 i; i < bonusTokensLength; i++) {
            beforeBalances[i] = IERC20(bonusTokens[i]).balanceOf(address(this));
        }
        uint256 beforeBalance = IERC20(ptp).balanceOf(address(this));
        IMasterPlatypus(masterPlatypus).deposit(poolInfo.pid, 0); //stock pour la pool chaque reward, vue ?
        uint256 rewards = IERC20(ptp).balanceOf(address(this)) - beforeBalance;
        uint256 afterFee = rewards;
        if (isUser && CALLER_FEE != 0) {
            uint256 feeAmount = (rewards * CALLER_FEE) / FEE_DENOMINATOR;
            IERC20(ptp).approve(smartConvertor, feeAmount);
            afterFee = afterFee - feeAmount;
            feeAmount = xTokenConvertor(smartConvertor).deposit(feeAmount);
            IERC20(xPTP).safeTransfer(msg.sender, feeAmount);
        }
        sendRewards(ptp, poolInfo.rewarder, rewards, afterFee);

        for (uint256 i; i < bonusTokensLength; i++) {
            uint256 bonusBalanceDiff = IERC20(bonusTokens[i]).balanceOf(address(this)) -
                beforeBalances[i];
            if (bonusBalanceDiff > 0) {
                sendRewards(bonusTokens[i], poolInfo.rewarder, bonusBalanceDiff, bonusBalanceDiff);
            }
        }
        emit PtpHarvested(rewards, rewards - afterFee);
    }

    /// @notice Send rewards to the rewarders
    /// @param token the address of the token to send rewards to
    /// @param rewarder the rewarder that will get tthe rewards
    /// @param _amount the initial amount of rewards after harvest
    /// @param afterFee the amount to send to the rewarder after fees are collected
    function sendRewards(
        address token,
        address rewarder,
        uint256 _amount,
        uint256 afterFee
    ) internal {
        for (uint256 i = 0; i < feeInfos.length; i++) {
            Fees storage feeInfo = feeInfos[i];
            if (feeInfo.isActive) {
                address rewardToken = token;
                uint256 feeAmount = (_amount * feeInfo.value) / FEE_DENOMINATOR;
                afterFee -= feeAmount;
                if (!feeInfo.isPTP && rewardToken == ptp) {
                    IERC20(ptp).approve(smartConvertor, feeAmount);
                    feeAmount = xTokenConvertor(smartConvertor).deposit(feeAmount);
                    rewardToken = xPTP;
                }
                if (!feeInfo.isAddress) {
                    IERC20(rewardToken).approve(feeInfo.to, feeAmount);
                    IBaseRewardPool(feeInfo.to).queueNewRewards(feeAmount, rewardToken);
                } else {
                    ERC20(rewardToken).transfer(feeInfo.to, feeAmount);
                    emit RewardPaidTo(feeInfo.to, rewardToken, feeAmount);
                }
            }
        }
        IERC20(token).approve(rewarder, afterFee);
        IBaseRewardPool(rewarder).queueNewRewards(afterFee, token);
    }

    /// @notice Send bonus rewards to the rewarders, don't apply platform fees
    /// @param token the address of the token to send rewards to
    /// @param rewarder the rewarder that will get tthe rewards
    /// @param _amount the initial amount of rewards after harvest
    function sendOtherRewards(
        address token,
        address rewarder,
        uint256 _amount
    ) internal {
        IERC20(token).approve(rewarder, _amount);
        IBaseRewardPool(rewarder).queueNewRewards(_amount, token);
        emit RewardPaidTo(rewarder, token, _amount);
    }

    /// @notice Send Unusual rewards to the rewarders, as airdrops
    /// @dev fees are not collected
    /// @param _token the address of the token to send
    /// @param _rewarder the rewarder that will get the rewards
    function sendTokenRewards(address _token, address _rewarder) external onlyOwner {
        require(_token != ptp, "not authorized");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).approve(_rewarder, amount);
        IBaseRewardPool(_rewarder).queueNewRewards(amount, _token);
    }

    /// @notice withdraw from a PTP pool
    /// @dev Only a PoolHelper can call this function
    /// @param token the address of the pool token from which to withdraw
    /// @param _amount the initial amount of tokens to withdraw
    /// @param minAmount The minimal amount the user accepts because of slippage
    /// @param sender the address of the user
    function withdrawWithDifferentAsset(
        address token,
        address asset,
        uint256 _amount,
        uint256 minAmount,
        address sender
    ) public {
        // _amount is the amount of stable
        Pool storage poolInfo = pools[asset];
        require(msg.sender == poolInfo.helper, "Only helper can withdraw");
        uint256 sharesAmount = getSharesForDepositTokens(_amount, asset);
        uint256 lpAmount = getLPTokensForShares(sharesAmount, asset);
        address staking = tokenToPool[asset];
        IMintableERC20(poolInfo.receiptToken).burn(msg.sender, sharesAmount);
        IERC20(poolInfo.lpAddress).approve(staking, lpAmount);
        IMasterPlatypus(masterPlatypus).withdraw(poolInfo.pid, lpAmount);
        uint256 beforeWithdraw = IERC20(token).balanceOf(address(this));
        IStableStaking(staking).withdraw(
            token,
            lpAmount,
            minAmount,
            address(this),
            block.timestamp
        );

        poolInfo.size -= _amount;
        poolInfo.sizeLp -= lpAmount;

        IERC20(token).safeTransfer(sender, IERC20(token).balanceOf(address(this)) - beforeWithdraw);
        emit NewWithdraw(sender, token, _amount);
    }

    /// @notice withdraw from a PTP pool and send the LP to caller
    /// @dev Only a PoolHelper can call this function
    /// @dev Only used in special case
    /// @param token the address of the pool token from which to withdraw
    /// @param _amount the initial amount of tokens to withdraw
    /// @param sender the address of the user
    function withdrawLP(
        address token,
        uint256 _amount,
        address sender
    ) external {
        // _amount is the amount of stable
        Pool storage poolInfo = pools[token];
        require(msg.sender == poolInfo.helper, "Only helper can withdraw");
        uint256 sharesAmount = getSharesForDepositTokens(_amount, token);
        uint256 lpAmount = getLPTokensForShares(sharesAmount, token);
        IMintableERC20(poolInfo.receiptToken).burn(msg.sender, sharesAmount);
        IMasterPlatypus(masterPlatypus).withdraw(poolInfo.pid, lpAmount);
        poolInfo.size -= _amount;
        poolInfo.sizeLp -= lpAmount;
        IERC20(poolInfo.lpAddress).safeTransfer(sender, lpAmount);
        emit NewWithdraw(sender, token, _amount);
    }

    /// @notice withdraw from a PTP pool
    /// @dev Only a PoolHelper can call this function
    /// @param token the address of the pool token from which to withdraw
    /// @param _amount the initial amount of tokens to withdraw
    /// @param minAmount The minimal amount the user accepts because of slippage
    /// @param sender the address of the user
    function withdraw(
        address token,
        uint256 _amount,
        uint256 minAmount,
        address sender
    ) external {
        withdrawWithDifferentAsset(token, token, _amount, minAmount, sender);
    }

    /// @notice stake PTP
    /// @param amount the number of PTP to stake
    /// @dev the PTP must already be in the contract
    function stakePTP(uint256 amount) public {
        uint256 stored_amount;
        if (amount > 0) {
            if (storagePTP != address(0)) {
                stored_amount = (amount * percentPTPStored) / FEE_DENOMINATOR;
                amount = amount - stored_amount;
            }
            IERC20(ptp).approve(staking_ptp, amount);
            IPTPStaking(staking_ptp).deposit(amount);
            if (stored_amount > 0) {
                IERC20(ptp).safeTransfer(storagePTP, stored_amount);
            }
        }
        emit NewPtpStaked(amount);
    }

    /// @notice Claim the pending vePTP
    function claimVePTP() public {
        uint256 amount = IPTPStaking(staking_ptp).getStakedPtp(address(this));
        if (amount > 0) {
            IPTPStaking(staking_ptp).claim();
        }
        emit PtpClaimed(amount);
    }

    /**
     * @notice Calculate LP tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getLPTokensForShares(uint256 amount, address token) public view returns (uint256) {
        Pool storage poolInfo = pools[token];
        uint256 totalDeposits = poolInfo.sizeLp;
        uint256 totalSupply = IERC20(poolInfo.receiptToken).totalSupply();
        if (totalSupply * totalDeposits == 0) {
            return 0;
        }
        return (amount * totalDeposits) / totalSupply;
    }

    /**
     * @notice Calculate shares amount for a given amount of depositToken
     * @param amount deposit token amount
     * @return number of shares
     */
    function getSharesForDepositTokens(uint256 amount, address token)
        public
        view
        returns (uint256)
    {
        Pool storage poolInfo = pools[token];
        uint256 totalDeposits = poolInfo.size;
        uint256 totalSupply = IERC20(poolInfo.receiptToken).totalSupply();

        if (totalSupply * totalDeposits == 0) {
            return amount;
        }
        return (amount * totalSupply) / totalDeposits;
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint256 amount, address token)
        public
        view
        returns (uint256)
    {
        Pool storage poolInfo = pools[token];
        uint256 totalDeposits = poolInfo.size;
        uint256 totalSupply = IERC20(poolInfo.receiptToken).totalSupply();
        if (totalSupply * totalDeposits == 0) {
            return 0;
        }
        return (amount * totalDeposits) / totalSupply;
    }

    /// @notice Register a new pool of PTP
    /// @dev this function will deploy a new PoolHelper, and add the pool to the masterVTX
    /// @param _pid the pid of the pool
    /// @param _token the token to stake in the pool
    /// @param _lpAddress the address of the pool's recepit token
    /// @param receiptName the name of the receipt Token
    /// @param receiptSymbol the symbol of the receipt Token
    /// @param allocPoints the weight of the VTX allocation
    function registerPool(
        uint256 _pid,
        address _token,
        address _lpAddress,
        address _staking,
        string memory receiptName,
        string memory receiptSymbol,
        uint256 allocPoints
    ) external onlyOwner {
        require(pools[_token].isActive == false, "Pool is already registered or active");
        IERC20 newToken = IERC20(ERC20FactoryLib.createERC20(receiptName, receiptSymbol));
        address rewarder = IMasterChefVTX(masterVtx).createRewarder(
            address(newToken),
            address(ptp)
        );
        IPoolHelper helper = IPoolHelper(
            PoolHelperFactoryLib.createPoolHelper(
                _pid,
                address(newToken),
                address(_token),
                address(this),
                address(masterVtx),
                address(rewarder),
                address(xPTP)
            )
        );
        IMasterChefVTX(masterVtx).add(
            allocPoints,
            address(newToken),
            address(rewarder),
            address(helper)
        );
        pools[_token] = Pool({
            pid: _pid,
            isActive: true,
            token: _token,
            lpAddress: _lpAddress,
            sizeLp: 0,
            size: 0,
            receiptToken: address(newToken),
            rewarder: address(rewarder),
            helper: address(helper)
        });
        tokenToPool[_token] = _staking;
        emit PoolAdded(_token);
    }

    /// @notice Register a new pool of PTP
    /// @dev this function will deploy a new PoolHelper, and add the pool to the masterVTX
    /// @param _pid the pid of the pool
    /// @param _token the token to stake in the pool
    /// @param _lpAddress the address of the pool's recepit token
    /// @param receiptName the name of the receipt Token
    /// @param receiptSymbol the symbol of the receipt Token
    /// @param allocPoints the weight of the VTX allocation
    function registerPoolWithDifferentAsset(
        uint256 _pid,
        address _token,
        address _lpAddress,
        address _assetToken,
        address _staking,
        string memory receiptName,
        string memory receiptSymbol,
        uint256 allocPoints
    ) external onlyOwner returns (address, address) {
        require(pools[_assetToken].isActive == false, "Pool is already registered or active");
        IERC20 newToken = IERC20(ERC20FactoryLib.createERC20(receiptName, receiptSymbol));
        address rewarder = IMasterChefVTX(masterVtx).createRewarder(
            address(newToken),
            address(ptp)
        );
        IPoolHelper helper = IPoolHelper(
            PoolHelperFactoryLib.createPoolHelper2(
                _pid,
                address(newToken),
                address(_token),
                address(_assetToken),
                address(this),
                address(masterVtx),
                address(rewarder),
                address(xPTP)
            )
        );
        IMasterChefVTX(masterVtx).add(
            allocPoints,
            address(newToken),
            address(rewarder),
            address(helper)
        );
        pools[_assetToken] = Pool({
            pid: _pid,
            isActive: true,
            token: _token,
            lpAddress: _lpAddress,
            sizeLp: 0,
            size: 0,
            receiptToken: address(newToken),
            rewarder: address(rewarder),
            helper: address(helper)
        });
        tokenToPool[_assetToken] = _staking;
        emit PoolAdded(_token);
        return (address(helper), address(newToken));
    }

    /// @notice Get the information of a pool
    /// @param _address the address of the deposit token to fetch information for
    /// @return pid the pid of the pool
    /// @return isActive true if the pool is active
    /// @return token the deposit Token
    /// @return lp the address of the PTP Lp token
    /// @return sizeLp the total number of LP tokens of this pool
    /// @return receipt - the address of the receipt token of this pool
    /// @return size the total number of stable staked by this pool
    /// @return rewards_addr the address of the rewarder
    /// @return helper the address of the poolHelper
    function getPoolInfo(address _address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address lp,
            uint256 sizeLp,
            address receipt,
            uint256 size,
            address rewards_addr,
            address helper
        )
    {
        Pool storage tokenInfo = pools[_address];
        pid = tokenInfo.pid;
        isActive = tokenInfo.isActive;
        token = tokenInfo.token;
        lp = tokenInfo.lpAddress;
        sizeLp = tokenInfo.sizeLp;
        receipt = tokenInfo.receiptToken;
        size = tokenInfo.size;
        rewards_addr = tokenInfo.rewarder;
        helper = tokenInfo.helper;
    }

    function removePool(address token) external onlyOwner {
        pools[token].isActive = false;
    }

    function setPoolHelper(address token, address _poolhelper) external onlyOwner {
        Pool storage poolInfo = pools[token];
        poolInfo.helper = _poolhelper;
    }

    function setMasterPlatypus(address _masterPtp) external onlyOwner {
        masterPlatypus = _masterPtp;
    }

    function ptpMigration(uint256[] calldata _pids) external onlyOwner {
        IMasterPlatypus(masterPlatypus).migrate(_pids);
    }

    function setPoolToken(address _token, address pool) external onlyOwner {
        require(pools[_token].isActive, "Not active");
        tokenToPool[_token] = pool;
    }

    function addBonusRewardForAsset(address _asset, address _bonusToken) external onlyOwner {
        assetToBonusRewards[_asset].push(_bonusToken);
    }

    receive() external payable {
        IWAVAX(WAVAX).deposit{value: address(this).balance}();
    }

    /// @notice increase allowance to a contract to the maximum amount for a specific token if it is needed
    /// @param token the token to increase the allowance of
    /// @param _to the contract to increase the allowance
    /// @param _amount the amount of allowance that the contract needs
    function _approveTokenIfNeeded(
        address token,
        address _to,
        uint256 _amount
    ) private {
        if (IERC20(token).allowance(address(this), _to) < _amount) {
            IERC20(token).approve(_to, type(uint256).max);
        }
    }

    /// @notice Vote on PTP gauges
    /// @dev voting harvest the pools, even if the pool has no changing vote,
    /// so we have to ensure that each reward token goes to the good rewarder
    /// @dev this function can cost a lot of gas, so maybe we will not launch it at every interaction
    function vote(
        address[] calldata _lpVote,
        int256[] calldata _deltas,
        address[] calldata _rewarders,
        address caller
    ) external returns (address[] memory rewardTokens, uint256[] memory feeAmounts) {
        require(msg.sender == bribeManager, "Not approved");
        uint256 length = _lpVote.length;
        require(length == _rewarders.length, "Not good rewarder length");
        uint256[] memory rewardAmounts = voter.vote(_lpVote, _deltas);

        rewardTokens = new address[](length);
        feeAmounts = new uint256[](length);

        for (uint256 i; i < length; i++) {
            uint256 rewardAmount = rewardAmounts[i];
            address bribesContract = voter.bribes(_lpVote[i]);
            uint256 feeAmount;
            if (bribesContract != address(0)) {
                rewardTokens[i] = address(IBribe(bribesContract).rewardToken());
                if (rewardAmount > 0) {
                    uint256 protocolFee = (rewardAmount * bribeProtocolFee) / FEE_DENOMINATOR;
                    if (protocolFee > 0) {
                        IERC20(rewardTokens[i]).safeTransfer(bribeFeeCollector, protocolFee);
                    }
                    if (caller != address(0) && bribeCallerFee != 0) {
                        feeAmount = (rewardAmount * bribeCallerFee) / FEE_DENOMINATOR;
                        IERC20(rewardTokens[i]).safeTransfer(bribeManager, feeAmount);
                        rewardAmount -= feeAmount;
                    }
                    rewardAmount -= protocolFee;
                    _approveTokenIfNeeded(rewardTokens[i], _rewarders[i], rewardAmount);
                    IBaseRewardPool(_rewarders[i]).queueNewRewards(rewardAmount, rewardTokens[i]);
                }
            }
            feeAmounts[i] = feeAmount;
        }
    }

    function pendingBribeCallerFee(address[] calldata pendingPools)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory callerFeeAmount)
    {
        // Warning: Arguments do not take into account repeated elements in the pendingPools list
        uint256[] memory pending = voter.pendingBribes(pendingPools, address(this));
        uint256 length = pending.length;
        callerFeeAmount = new uint256[](length);
        rewardTokens = new address[](length);
        for (uint256 i; i < length; i++) {
            if (pending[i] > 0) {
                callerFeeAmount[i] = (pending[i] * bribeCallerFee) / FEE_DENOMINATOR;
                rewardTokens[i] = address(IBribe(voter.bribes(pendingPools[i])).rewardToken());
            }
        }
    }

    uint256[40] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "AddressUpgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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

interface IPTPStaking {
    function deposit(uint256 _amount) external;

    function claim() external;

    function setWhitelist(address _user) external;

    function ptp() external view returns (address);

    function getStakedPtp(address _addr) external view returns (uint256);

    function withdraw(uint256 stakedPTP) external;

    function stakeNft(uint256 _tokenId) external;

    function unstakeNft() external;

    function nft() external view returns (address);

    function getStakedNft(address) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function usedVote(address) external view returns (uint256);

    function voter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStableStaking {
    function deposit(
        address token,
        uint256 _amount,
        address to,
        uint256 deadline
    ) external;

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external;

    function withdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external;

    function quotePotentialWithdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function quoteMaxInitialAssetWithdrawable(address initialToken, address wantedToken)
        external
        view
        returns (uint256 maxInitialAssetAmount);

    function quotePotentialWithdraw(address token, uint256 liquidity)
        external
        view
        returns (
            uint256 amount,
            uint256 fee,
            bool enoughCash
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMasterPlatypus {
    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder
    ) external;

    function claimablePtp(uint256, address) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function dialutingRepartition() external view returns (uint256);

    function emergencyPtpWithdraw() external;

    function emergencyWithdraw(uint256 _pid) external;

    function initialize(
        address _ptp,
        address _vePtp,
        uint256 _ptpPerSec,
        uint256 _dialutingRepartition,
        uint256 _startTimestamp
    ) external;

    function massUpdatePools() external;

    function migrate(uint256[] calldata _pids) external;

    function multiClaim(uint256[] calldata _pids)
        external
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        );

    function nonDialutingRepartition() external view returns (uint256);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingPtp,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardTimestamp,
            uint256 accPtpPerShare,
            address rewarder,
            uint256 sumOfFactors,
            uint256 accPtpPerFactorShare
        );

    function poolLength() external view returns (uint256);

    function ptp() external view returns (address);

    function ptpPerSec() external view returns (uint256);

    function renounceOwnership() external;

    function rewarderBonusTokenInfo(uint256 _pid)
        external
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _rewarder,
        bool overwrite
    ) external;

    function setNewMasterPlatypus(address _newMasterPlatypus) external;

    function setVePtp(address _newVePtp) external;

    function startTimestamp() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function updateEmissionRate(uint256 _ptpPerSec) external;

    function updateEmissionRepartition(uint256 _dialutingRepartition) external;

    function updateFactor(address _user, uint256 _newVePtpBalance) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 factor
        );

    function vePtp() external view returns (address);

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBaseRewardPool {
    function balanceOf(address _account) external view returns (uint256);

    function donateRewards(uint256 _amountReward, address _rewardToken) external returns (bool);

    function earned(address _account, address _rewardToken) external view returns (uint256);

    function getReward(address _account) external returns (bool);

    function getRewardUser() external returns (bool);

    function getStakingToken() external view returns (address);

    function isRewardToken(address) external view returns (bool);

    function mainRewardToken() external view returns (address);

    function operator() external view returns (address);

    function owner() external view returns (address);

    function queueNewRewards(uint256 _amountReward, address _rewardToken) external returns (bool);

    function renounceOwnership() external;

    function rewardDecimals(address _rewardToken) external view returns (uint256);

    function rewardManager() external view returns (address);

    function rewardPerToken(address _rewardToken) external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewards(address)
        external
        view
        returns (
            address rewardToken,
            uint256 rewardPerTokenStored,
            uint256 queuedRewards,
            uint256 historicalRewards
        );

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function stakingDecimals() external view returns (uint256);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateFor(address _account) external;

    function userRewardPerTokenPaid(address, address) external view returns (uint256);

    function userRewards(address, address) external view returns (uint256);

    function withdrawFor(
        address _for,
        uint256 _amount,
        bool claim
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IPoolHelper {
    function balance(address _address) external view returns (uint256);

    function deposit(uint256 amount) external;

    function depositToken() external view returns (address);

    function depositTokenBalance() external view returns (uint256);

    function earned(address token) external view returns (uint256 vtxAmount, uint256 tokenAmount);

    function getReward() external;

    function harvest() external;

    function mainStaking() external view returns (address);

    function masterVtx() external view returns (address);

    function pendingPTP() external view returns (uint256 pendingTokens);

    function pid() external view returns (uint256);

    function rewardPerToken(address token) external view returns (uint256);

    function rewarder() external view returns (address);

    function stake(uint256 _amount) external;

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function update() external;

    function withdraw(uint256 amount, uint256 minAmount) external;

    function xptp() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMintableERC20 {
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burn(address account, uint256 amount) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function mint(address account, uint256 amount) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMasterChefVTX {
    function PoolManagers(address) external view returns (bool);

    function __MasterChefVTX_init(
        address _vtx,
        uint256 _vtxPerSec,
        uint256 _startTimestamp
    ) external;

    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder,
        address _helper
    ) external;

    function addressToPoolInfo(address)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardTimestamp,
            uint256 accVTXPerShare,
            address rewarder,
            address helper,
            address locker
        );

    function allowEmergency() external;

    function authorizeForLock(address _address) external;

    function createRewarder(address _lpToken, address mainRewardToken) external returns (address);

    function deposit(address _lp, uint256 _amount) external;

    function depositFor(
        address _lp,
        uint256 _amount,
        address sender
    ) external;

    function depositInfo(address _lp, address _user)
        external
        view
        returns (uint256 availableAmount);

    function emergencyWithdraw(address _lp) external;

    function emergencyWithdrawWithReward(address _lp) external;

    function getPoolInfo(address token)
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

    function isAuthorizedForLock(address) external view returns (bool);

    function massUpdatePools() external;

    function migrateEmergency(
        address _from,
        address _to,
        bool[] calldata onlyDeposit
    ) external;

    function migrateToNewLocker(bool[] calldata onlyDeposit) external;

    function multiclaim(address[] calldata _lps, address user_address) external;

    function owner() external view returns (address);

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
        );

    function poolLength() external view returns (uint256);

    function realEmergencyWithdraw(address _lp) external;

    function registeredToken(uint256) external view returns (address);

    function renounceOwnership() external;

    function set(
        address _lp,
        uint256 _allocPoint,
        address _rewarder,
        address _locker,
        bool overwrite
    ) external;

    function setPoolHelper(address _lp, address _helper) external;

    function setPoolManagerStatus(address _address, bool _bool) external;

    function setVtxLocker(address newLocker) external;

    function startTimestamp() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateEmissionRate(uint256 _vtxPerSec) external;

    function updatePool(address _lp) external;

    function vtx() external view returns (address);

    function vtxLocker() external view returns (address);

    function vtxPerSec() external view returns (uint256);

    function withdraw(address _lp, uint256 _amount) external;

    function withdrawFor(
        address _lp,
        uint256 _amount,
        address _sender
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IxPTP {
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 _amount) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function mainContract() external view returns (address);

    function name() external view returns (string memory);

    function ptp() external view returns (address);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Smart Convertor
/// @author Vector Team
/// @notice Smart Convertor is a convertor to manage conversion or buying on trader Joe
interface xTokenConvertor {
    /// @notice deposit joe in vector protocol and get xjoe
    /// @dev if xjoeRatio < buyThreshold, will buy in open market a % of the deposit
    /// @dev this % is determined by buyPercent
    /// @param _amount the amount of joe
    function deposit(uint256 _amount) external returns (uint256 obtainedxJoeAmount);

    /// @notice deposit joe in vector protocol and get xJoe
    /// @dev if xJoeRatio < buyThreshold, will buy in open market a % of the deposit
    /// @dev this % is determined by buyPercent
    /// @param _amount the amount of Joe
    function depositFor(uint256 _amount, address _for)
        external
        returns (uint256 obtainedxJoeAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IComputeAPR {
    function computeAPR(
        address fromPool,
        address token,
        address rewardToken,
        uint256 amountReward,
        uint256 sizeOfPool
    ) external;

    function computeAPRForVTX(address token, bool isStable)
        external
        view
        returns (uint256, uint256);

    function computeAPRStable(
        address token,
        address rewardToken,
        uint256 amountReward,
        uint256 sizeOfPool
    ) external;

    function getAvaxLatestPrice() external view returns (uint256);

    function getRatio(
        address numerator,
        address denominator,
        uint256 decimals
    ) external view returns (uint256 ratio);

    function getValueLP(address token) external view returns (uint256 valueOfLP);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setTokenToWavaxPool(
        address token,
        address wavaxPool,
        bool isLP
    ) external;

    function tokenIsLP(address) external view returns (bool);

    function tokenToWavaxPool(address) external view returns (address);

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC721.sol";

interface IPTPNft is IERC721 {
    function getPlatypusDetails(uint256 tokenId)
        external
        view
        returns (
            uint32 speedo,
            uint32 pudgy,
            uint32 diligent,
            uint32 gifted,
            uint32 hibernate
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
pragma solidity ^0.8.0;

import "SafeERC20.sol";

import "IBaseRewardPool.sol";
import "IMainStaking.sol";
import "IMasterChefVTX.sol";
import "IMasterPlatypus.sol";

/// @title Poolhelper
/// @author Vector Team
/// @notice This contract is the main contract that user will intreact with in order to stake stable in Vector protocol
contract PoolHelper {
    using SafeERC20 for IERC20;
    address public immutable depositToken;
    address public immutable stakingToken;
    address public immutable xptp;
    address public immutable masterVtx;

    address public immutable mainStaking;
    address public immutable rewarder;

    uint256 public immutable pid;

    event NewDeposit(address indexed user, uint256 amount);
    event NewWithdraw(address indexed user, uint256 amount);

    constructor(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _mainStaking,
        address _masterVtx,
        address _rewarder,
        address _xptp
    ) {
        pid = _pid;
        stakingToken = _stakingToken;
        depositToken = _depositToken;
        mainStaking = _mainStaking;
        masterVtx = _masterVtx;
        rewarder = _rewarder;
        xptp = _xptp;
    }

    function totalSupply() public view returns (uint256) {
        return IBaseRewardPool(rewarder).totalSupply();
    }

    /// @notice get the amount of reward per token deposited by a user
    /// @param token the token to get the number of rewards
    /// @return the amount of claimable tokens
    function rewardPerToken(address token) public view returns (uint256) {
        return IBaseRewardPool(rewarder).rewardPerToken(token);
    }

    /// @notice get the total amount of shares of a user
    /// @param _address the user
    /// @return the amount of shares
    function balance(address _address) public view returns (uint256) {
        return IBaseRewardPool(rewarder).balanceOf(_address);
    }

    /// @notice get the total amount of stables deposited by a user
    /// @return the amount of stables deposited
    function depositTokenBalance() public view returns (uint256) {
        return
            IMainStaking(mainStaking).getDepositTokensForShares(balance(msg.sender), depositToken);
    }

    modifier _harvest() {
        IMainStaking(mainStaking).harvest(depositToken, false);
        _;
    }

    /// @notice harvest pending PTP and get the caller fee
    function harvest() public {
        IMainStaking(mainStaking).harvest(depositToken, true);
        IERC20(xptp).safeTransfer(msg.sender, IERC20(xptp).balanceOf(address(this)));
    }

    /// @notice update the rewards for the caller
    function update() public {
        IBaseRewardPool(rewarder).updateFor(msg.sender);
    }

    /// @notice get the total amount of rewards for a given token for a user
    /// @param token the address of the token to get the number of rewards for
    /// @return vtxAmount the amount of VTX ready for harvest
    /// @return tokenAmount the amount of token inputted
    function earned(address token) public view returns (uint256 vtxAmount, uint256 tokenAmount) {
        (vtxAmount, , , tokenAmount) = IMasterChefVTX(masterVtx).pendingTokens(
            stakingToken,
            msg.sender,
            token
        );
    }

    /// @notice stake the receipt token in the masterchief of VTX on behalf of the caller
    function _stake(uint256 _amount, address sender) internal {
        IERC20(stakingToken).approve(masterVtx, _amount);
        IMasterChefVTX(masterVtx).depositFor(stakingToken, _amount, sender);
    }

    /// @notice unstake from the masterchief of VTX on behalf of the caller
    function _unstake(uint256 _amount, address sender) internal {
        IMasterChefVTX(masterVtx).withdrawFor(stakingToken, _amount, sender);
    }

    /// @notice deposit stables in mainStaking, autostake in masterchief of VTX
    /// @dev performs a harvest of PTP just before depositing
    /// @param amount the amount of stables to deposit
    function deposit(uint256 amount) external _harvest {
        uint256 beforeDeposit = IERC20(stakingToken).balanceOf(address(this));
        IMainStaking(mainStaking).deposit(depositToken, amount, msg.sender);
        uint256 afterDeposit = IERC20(stakingToken).balanceOf(address(this));
        _stake(afterDeposit - beforeDeposit, msg.sender);
        emit NewDeposit(msg.sender, amount);
    }

    /// @notice stake the receipt token in the masterchief of VTX on behalf of the caller
    function stake(uint256 _amount) external {
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(stakingToken).approve(masterVtx, _amount);
        IMasterChefVTX(masterVtx).depositFor(stakingToken, _amount, msg.sender);
    }

    /// @notice withdraw stables from mainStaking, auto unstake from masterchief of VTX
    /// @dev performs a harvest of PTP before withdrawing
    /// @param amount the amount of stables to deposit
    function withdraw(uint256 amount, uint256 minAmount) external _harvest {
        _unstake(amount, msg.sender);
        IMainStaking(mainStaking).withdraw(depositToken, amount, minAmount, msg.sender);
        emit NewWithdraw(msg.sender, amount);
    }

    /// @notice Harvest VTX and PTP rewards
    function getReward() external _harvest {
        IMasterChefVTX(masterVtx).depositFor(stakingToken, 0, msg.sender);
    }

    /// @notice returns the number of pending PTP of the contract for the given pool
    /// returns pendingTokens the number of pending PTP
    function pendingPTP() external view returns (uint256 pendingTokens) {
        (pendingTokens, , , ) = IMasterPlatypus(IMainStaking(mainStaking).masterPlatypus())
            .pendingTokens(pid, mainStaking);
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
pragma solidity 0.8.7;

interface IMainStaking {
    function CALLER_FEE() external view returns (uint256);

    function MAX_CALLER_FEE() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function WAVAX() external view returns (address);

    function addBonusRewardForAsset(address _asset, address _bonusToken) external;

    function addFee(
        uint256 max,
        uint256 min,
        uint256 value,
        address to,
        bool isPTP,
        bool isAddress
    ) external;

    function assetToBonusRewards(address, uint256) external view returns (address);

    function bribeCallerFee() external view returns (uint256);

    function bribeFeeCollector() external view returns (address);

    function bribeManager() external view returns (address);

    function bribeProtocolFee() external view returns (uint256);

    function claimVePTP() external;

    function computeAPR() external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        address sender
    ) external;

    function depositWithDifferentAsset(
        address token,
        address asset,
        uint256 amount,
        address sender
    ) external;

    function feeInfos(uint256)
        external
        view
        returns (
            uint256 max_value,
            uint256 min_value,
            uint256 value,
            address to,
            bool isPTP,
            bool isAddress,
            bool isActive
        );

    function getDepositTokensForShares(uint256 amount, address token)
        external
        view
        returns (uint256);

    function getLPTokensForShares(uint256 amount, address token) external view returns (uint256);

    function getPoolInfo(address _address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address lp,
            uint256 sizeLp,
            address receipt,
            uint256 size,
            address rewards_addr,
            address helper
        );

    function getSharesForDepositTokens(uint256 amount, address token)
        external
        view
        returns (uint256);

    function harvest(address token, bool isUser) external;

    function masterPlatypus() external view returns (address);

    function masterVtx() external view returns (address);

    function multiHarvest(address token, bool isUser) external;

    function owner() external view returns (address);

    function pendingBribeCallerFee(address[] calldata pendingPools)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory callerFeeAmount);

    function percentPTPStored() external view returns (uint256);

    function pools(address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address lpAddress,
            uint256 sizeLp,
            uint256 size,
            address receiptToken,
            address rewarder,
            address helper
        );

    function ptp() external view returns (address);

    function ptpMigration(uint256[] calldata _pids) external;

    function registerPool(
        uint256 _pid,
        address _token,
        address _lpAddress,
        address _staking,
        string calldata receiptName,
        string calldata receiptSymbol,
        uint256 allocPoints
    ) external;

    function registerPoolWithDifferentAsset(
        uint256 _pid,
        address _token,
        address _lpAddress,
        address _assetToken,
        address _staking,
        string calldata receiptName,
        string calldata receiptSymbol,
        uint256 allocPoints
    ) external returns (address, address);

    function removeFee(uint256 index) external;

    function removePool(address token) external;

    function renounceOwnership() external;

    function sendTokenRewards(address _token, address _rewarder) external;

    function setBribeCallerFee(uint256 newValue) external;

    function setBribeFeeCollector(address _collector) external;

    function setBribeManager(address _manager) external;

    function setBribeProtocolFee(uint256 newValue) external;

    function setCallerFee(uint256 value) external;

    function setFee(uint256 index, uint256 value) external;

    function setFeeRecipient(
        uint256 index,
        address _to,
        bool _isPtp,
        bool _isAddress
    ) external;

    function setMasterPlatypus(address _masterPtp) external;

    function setPoolHelper(address token, address _poolhelper) external;

    function setPoolToken(address _token, address pool) external;

    function setSmartConvertor(address _smartConvertor) external;

    function setVoter(address _voter) external;

    function smartConvertor() external view returns (address);

    function stakePTP(uint256 amount) external;

    function stakingStable() external view returns (address);

    function staking_ptp() external view returns (address);

    function storagePTP() external view returns (address);

    function tokenToAvaxPool(address) external view returns (address);

    function tokenToPool(address) external view returns (address);

    function totalFee() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function vote(
        address[] calldata _lpVote,
        int256[] calldata _deltas,
        address[] calldata _rewarders,
        address caller
    ) external returns (address[] memory rewardTokens, uint256[] memory feeAmounts);

    function voter() external view returns (address);

    function withdraw(
        address token,
        uint256 _amount,
        uint256 minAmount,
        address sender
    ) external;

    function withdrawLP(
        address token,
        uint256 _amount,
        address sender
    ) external;

    function withdrawWithDifferentAsset(
        address token,
        address asset,
        uint256 _amount,
        uint256 minAmount,
        address sender
    ) external;

    function xPTP() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeERC20.sol";

import "IBaseRewardPool.sol";
import "IMainStaking.sol";
import "IMasterChefVTX.sol";
import "IMasterPlatypus.sol";

/// @title Poolhelper
/// @author Vector Team
/// @notice This contract is the main contract that user will intreact with in order to stake stable in Vector protocol
contract PoolHelper2 {
    using SafeERC20 for IERC20;
    address public immutable depositToken;
    address public immutable stakingToken;
    address public immutable xptp;
    address public immutable masterVtx;
    address public immutable assetToken;

    address public immutable mainStaking;
    address public immutable rewarder;

    uint256 public immutable pid;

    event NewDeposit(address indexed user, uint256 amount);
    event NewWithdraw(address indexed user, uint256 amount);

    constructor(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _assetToken,
        address _mainStaking,
        address _masterVtx,
        address _rewarder,
        address _xptp
    ) {
        pid = _pid;
        stakingToken = _stakingToken;
        depositToken = _depositToken;
        mainStaking = _mainStaking;
        masterVtx = _masterVtx;
        rewarder = _rewarder;
        xptp = _xptp;
        assetToken = _assetToken;
    }

    function totalSupply() public view returns (uint256) {
        return IBaseRewardPool(rewarder).totalSupply();
    }

    /// @notice get the amount of reward per token deposited by a user
    /// @param token the token to get the number of rewards
    /// @return the amount of claimable tokens
    function rewardPerToken(address token) public view returns (uint256) {
        return IBaseRewardPool(rewarder).rewardPerToken(token);
    }

    /// @notice get the total amount of shares of a user
    /// @param _address the user
    /// @return the amount of shares
    function balance(address _address) public view returns (uint256) {
        return IBaseRewardPool(rewarder).balanceOf(_address);
    }

    /// @notice get the total amount of stables deposited by a user
    /// @return the amount of stables deposited
    function depositTokenBalance(address _user) public view returns (uint256) {
        return IMainStaking(mainStaking).getDepositTokensForShares(balance(_user), assetToken);
    }

    modifier _harvest() {
        IMainStaking(mainStaking).multiHarvest(assetToken, false);
        _;
    }

    /// @notice harvest pending PTP and get the caller fee
    function harvest() public {
        IMainStaking(mainStaking).multiHarvest(assetToken, true);
        IERC20(xptp).safeTransfer(msg.sender, IERC20(xptp).balanceOf(address(this)));
    }

    /// @notice update the rewards for the caller
    function update() public {
        IBaseRewardPool(rewarder).updateFor(msg.sender);
    }

    /// @notice get the total amount of rewards for a given token for a user
    /// @param token the address of the token to get the number of rewards for
    /// @return vtxAmount the amount of VTX ready for harvest
    /// @return tokenAmount the amount of token inputted
    function earned(address token) public view returns (uint256 vtxAmount, uint256 tokenAmount) {
        (vtxAmount, , , tokenAmount) = IMasterChefVTX(masterVtx).pendingTokens(
            stakingToken,
            msg.sender,
            token
        );
    }

    /// @notice stake the receipt token in the masterchief of VTX on behalf of the caller
    function _stake(uint256 _amount, address sender) internal {
        IERC20(stakingToken).approve(masterVtx, _amount);
        IMasterChefVTX(masterVtx).depositFor(stakingToken, _amount, sender);
    }

    /// @notice unstake from the masterchief of VTX on behalf of the caller
    function _unstake(uint256 _amount, address sender) internal {
        IMasterChefVTX(masterVtx).withdrawFor(stakingToken, _amount, sender);
    }

    /// @notice deposit stables in mainStaking, autostake in masterchief of VTX
    /// @dev performs a harvest of PTP just before depositing
    /// @param amount the amount of stables to deposit
    function deposit(uint256 amount) external _harvest {
        uint256 beforeDeposit = IERC20(stakingToken).balanceOf(address(this));
        IMainStaking(mainStaking).depositWithDifferentAsset(
            depositToken,
            assetToken,
            amount,
            msg.sender
        );
        uint256 afterDeposit = IERC20(stakingToken).balanceOf(address(this));
        _stake(afterDeposit - beforeDeposit, msg.sender);
        emit NewDeposit(msg.sender, amount);
    }

    /// @notice stake the receipt token in the masterchief of VTX on behalf of the caller
    function stake(uint256 _amount) external {
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(stakingToken).approve(masterVtx, _amount);
        IMasterChefVTX(masterVtx).depositFor(stakingToken, _amount, msg.sender);
    }

    /// @notice withdraw stables from mainStaking, auto unstake from masterchief of VTX
    /// @dev performs a harvest of PTP before withdrawing
    /// @param amount the amount of stables to deposit
    function withdraw(uint256 amount, uint256 minAmount) external _harvest {
        _unstake(amount, msg.sender);
        IMainStaking(mainStaking).withdrawWithDifferentAsset(
            depositToken,
            assetToken,
            amount,
            minAmount,
            msg.sender
        );
        emit NewWithdraw(msg.sender, amount);
    }

    /// @notice Harvest VTX and PTP rewards
    function getReward() external _harvest {
        IMasterChefVTX(masterVtx).depositFor(stakingToken, 0, msg.sender);
    }

    /// @notice returns the number of pending PTP of the contract for the given pool
    /// returns pendingTokens the number of pending PTP
    function pendingPTP() external view returns (uint256 pendingTokens) {
        (pendingTokens, , , ) = IMasterPlatypus(IMainStaking(mainStaking).masterPlatypus())
            .pendingTokens(pid, mainStaking);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVoter {
    function add(
        address _gauge,
        address _lpToken,
        address _bribe
    ) external;

    function bribes(address) external view returns (address);

    function claimBribes(address[] calldata _lpTokens)
        external
        returns (uint256[] memory bribeRewards);

    function distribute(address _lpToken) external;

    function emergencyPtpWithdraw() external;

    function getUserVotes(address _user, address _lpToken) external view returns (uint256);

    function index() external view returns (uint128);

    function initialize(
        address _ptp,
        address _vePtp,
        uint88 _ptpPerSec,
        uint256 _startTimestamp
    ) external;

    function lastRewardTimestamp() external view returns (uint40);

    function lpTokenLength() external view returns (uint256);

    function lpTokens(uint256) external view returns (address);

    function owner() external view returns (address);

    function pause(address _lpToken) external;

    function pendingBribes(address[] calldata _lpTokens, address _user)
        external
        view
        returns (uint256[] memory bribeRewards);

    function pendingPtp(address _lpToken) external view returns (uint256);

    function ptp() external view returns (address);

    function ptpPerSec() external view returns (uint88);

    function renounceOwnership() external;

    function resume(address _lpToken) external;

    function setBribe(address _lpToken, address _bribe) external;

    function setGauge(address _lpToken, address _gauge) external;

    function setPtpPerSec(uint88 _ptpPerSec) external;

    function totalWeight() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function vePtp() external view returns (address);

    function vote(address[] calldata _lpVote, int256[] calldata _deltas)
        external
        returns (uint256[] memory bribeRewards);

    function votes(address, address) external view returns (uint256);

    function weights(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBribe {
    function balance() external view returns (uint256);

    function emergencyWithdraw() external;

    function isNative() external view returns (bool);

    function lpToken() external view returns (address);

    function onVote(
        address _user,
        uint256 _lpAmount,
        uint256 originalTotalVotes
    ) external returns (uint256);

    function operator() external view returns (address);

    function owner() external view returns (address);

    function pendingTokens(address _user) external view returns (uint256 pending);

    function poolInfo()
        external
        view
        returns (uint128 accTokenPerShare, uint48 lastRewardTimestamp);

    function renounceOwnership() external;

    function rewardToken() external view returns (address);

    function setOperator(address _operator) external;

    function setRewardRate(uint256 _tokenPerSec) external;

    function tokenPerSec() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool() external;

    function userInfo(address)
        external
        view
        returns (
            uint128 amount,
            uint128 rewardDebt,
            uint256 unpaidRewards
        );

    function voter() external view returns (address);
}