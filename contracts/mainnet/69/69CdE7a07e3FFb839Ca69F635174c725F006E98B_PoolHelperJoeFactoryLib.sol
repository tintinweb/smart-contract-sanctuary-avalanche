// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Initializable.sol";
import "OwnableUpgradeable.sol";
import "IJoeStaking.sol";
import "IBaseRewardPool.sol";
import "IPoolHelper.sol";
import "IMintableERC20.sol";
import "IMasterChefVTX.sol";
import "IxJoe.sol";
import "IMasterJoe.sol";
import "IWavax.sol";

import "PoolHelperJoeFactoryLib.sol";
import "ERC20FactoryLib.sol";

/// @title MainStaking
/// @author Vector Team
/// @notice Mainstaking is the contract that interacts with ALL Joe contract
/// @dev all functions except harvest are restricted either to owner or to other contracts from the vector protocol
/// @dev the owner of this contract holds a lot of power, and should be owned by a multisig
contract MainStakingJoe is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // Addresses
    address public stakingJoe;
    address public joe;
    address public xJoe;
    address public veJoe;
    address public masterJoe;
    address public masterVtx;
    address public router;

    // Fees
    uint256 constant FEE_DENOMINATOR = 10000;
    uint256 public constant MAX_FEE = 3000;
    uint256 public CALLER_FEE;
    uint256 public constant MAX_CALLER_FEE = 500;
    uint256 public totalFee;

    struct Fees {
        uint256 maxValue;
        uint256 minValue;
        uint256 value;
        address to;
        bool isJoe;
        bool isAddress;
        bool isActive;
    }

    Fees[] public feeInfos;

    struct Pool {
        uint256 pid;
        bool isActive;
        address token;
        address receiptToken;
        address rewarder;
        address helper;
    }
    mapping(address => Pool) public pools;
    mapping(address => address) public tokenToAvaxPool;

    bool public boostBufferActivated;
    bool public bypassBoostWait;

    mapping(address => address[]) public assetToBonusRewards;
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    event AddFee(address to, uint256 value, bool isJoe, bool isAddress);
    event SetFee(address to, uint256 value);
    event RemoveFee(address to);
    event veJoeClaimed(uint256 amount);
    event JoeHarvested(uint256 amount, uint256 callerFee);
    event RewardPaidTo(address to, address rewardToken, uint256 feeAmount);
    event NewJoeStaked(uint256 amount);
    event PoolAdded(address tokenAddress);
    event PoolRemoved(address _token);
    event PoolHelperSet(address _token);
    event PoolRewarderSet(address token, address _poolRewarder);
    event MasterChiefSet(address _token);
    event MasterJoeSet(address _token);

    function __MainStakingJoe_init(
        address _joe,
        address _boostedMasterChefJoe,
        address _masterVtx,
        address _veJoe,
        address _router,
        address _stakingJoe,
        uint256 _callerFee
    ) public initializer {
        __Ownable_init();
        // Address of the joe Token
        joe = _joe;
        // Address of the MasterChefJoe for depositing lp tokens
        masterJoe = _boostedMasterChefJoe;
        masterVtx = _masterVtx;
        CALLER_FEE = _callerFee;
        totalFee = _callerFee;
        veJoe = _veJoe;
        router = _router;
        stakingJoe = _stakingJoe;
    }

    /// @notice set the vJoe address
    /// @dev can only be called once
    /// @param _xJoe the vJoe address
    function setXJoe(address _xJoe) external onlyOwner {
        require(xJoe == address(0), "xJoe already set");
        xJoe = _xJoe;
    }

    function boosterThreshold() public view returns (uint256) {
        return IJoeStaking(stakingJoe).speedUpThreshold();
    }

    /// @notice This function adds a fee to the vector protocol
    /// @dev the value of the fee must match the max fee requirement
    /// @param max the maximum value for that fee
    /// @param min the minimum value for that fee
    /// @param value the initial value for that fee
    /// @param to the address or contract that receives the fee
    /// @param isJoe true if the fee is sent as Joe, otherwise it will be xJoe
    /// @param isAddress true if the receiver is an address, otherwise it's a BaseRewarder
    function addFee(
        uint256 max,
        uint256 min,
        uint256 value,
        address to,
        bool isJoe,
        bool isAddress
    ) external onlyOwner {
        require(to != address(0), "No fees to address 0");
        require(totalFee + value <= MAX_FEE, "Max fee reached");
        require(min <= value && value <= max, "Value not in range");
        feeInfos.push(
            Fees({
                maxValue: max,
                minValue: min,
                value: value,
                to: to,
                isJoe: isJoe,
                isAddress: isAddress,
                isActive: true
            })
        );
        totalFee += value;
        emit AddFee(to, value, isJoe, isAddress);
    }

    function setBufferStatus(bool status) public onlyOwner {
        boostBufferActivated = status;
    }

    function setBypassBoostWait(bool status) public onlyOwner {
        bypassBoostWait = status;
    }

    /// @notice change the value of some fee
    /// @dev the value must be between the min and the max specified when registering the fee
    /// @dev the value must match the max fee requirements
    /// @param index the index of the fee in the fee list
    /// @param value the new value of the fee
    function setFee(uint256 index, uint256 value) external onlyOwner {
        Fees storage fee = feeInfos[index];
        require(fee.isActive, "Cannot change an deactivated fee");
        require(fee.minValue <= value && value <= fee.maxValue, "Value not in range");
        require(totalFee + value - fee.value <= MAX_FEE, "Max fee reached");
        totalFee = totalFee - fee.value + value;
        fee.value = value;
        emit SetFee(fee.to, value);
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
        require(value <= MAX_CALLER_FEE, "Value too high");
        // Check if the fee delta does not make the total fee go over the limit
        totalFee = totalFee + value - CALLER_FEE;
        require(totalFee <= MAX_FEE, "MAX Fee reached");
        CALLER_FEE = value;
    }

    /// @notice deposit lp in a Joe pool
    /// @dev this function can only be called by a PoolHelper
    /// @param token the token to deposit
    /// @param amount the amount to deposit
    function deposit(address token, uint256 amount) external {
        // Get information of the pool of the token
        Pool storage poolInfo = pools[token];

        //Requirements
        require(poolInfo.isActive, "Pool not active");
        require(msg.sender == poolInfo.helper, "Only helper can deposit");
        IERC20(token).safeTransferFrom(poolInfo.helper, address(this), amount);

        // Deposit to masterJoe Contract
        _approveTokenIfNeeded(token, masterJoe, amount);
        IMasterJoe(masterJoe).deposit(poolInfo.pid, amount);
        IMintableERC20(poolInfo.receiptToken).mint(poolInfo.helper, amount);
    }

    /// @notice harvest a pool from MasterJoe
    /// @param token the address of the token to harvest
    /// @param isUser true if this function is not called by the vector Contracts. The caller gets the caller fee
    function harvest(address token, bool isUser) public {
        Pool storage poolInfo = pools[token];
        require(poolInfo.isActive, "Pool not active");
        address[] memory bonusTokens = assetToBonusRewards[token];
        uint256 bonusTokensLength = bonusTokens.length;
        uint256[] memory beforeBalances = new uint256[](bonusTokensLength);
        for (uint256 i; i < bonusTokensLength; i++) {
            beforeBalances[i] = IERC20(bonusTokens[i]).balanceOf(address(this));
        }
        uint256 beforeBalance = IERC20(joe).balanceOf(address(this));
        IMasterJoe(masterJoe).deposit(poolInfo.pid, 0);
        uint256 rewards = IERC20(joe).balanceOf(address(this)) - beforeBalance;
        uint256 afterFee = rewards;
        if (isUser && CALLER_FEE != 0) {
            uint256 feeAmount = (rewards * CALLER_FEE) / FEE_DENOMINATOR;
            _approveTokenIfNeeded(joe, xJoe, feeAmount);
            IxJoe(xJoe).depositFor(feeAmount, msg.sender);
            afterFee = afterFee - feeAmount;
        }
        sendRewards(poolInfo.token, poolInfo.rewarder, rewards, afterFee);
        for (uint256 i; i < bonusTokensLength; i++) {
            uint256 bonusBalanceDiff = IERC20(bonusTokens[i]).balanceOf(address(this)) -
                beforeBalances[i];
            if (bonusBalanceDiff > 0) {
                sendOtherRewards(bonusTokens[i], poolInfo.rewarder, bonusBalanceDiff);
            }
        }
        emit JoeHarvested(rewards, rewards - afterFee);
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

    /// @notice Send rewards to the rewarders
    /// @param token the address of the token to send rewards to
    /// @param rewarder the rewarder that will get the rewards
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
                address rewardToken = joe;
                uint256 feeAmount = (_amount * feeInfo.value) / FEE_DENOMINATOR;
                if (!feeInfo.isJoe) {
                    // _approveTokenIfNeeded(joe, xJoe, feeAmount);
                    IxJoe(xJoe).depositWithoutTransferFor(feeAmount, address(this));
                    rewardToken = xJoe;
                }
                if (!feeInfo.isAddress) {
                    _approveTokenIfNeeded(rewardToken, feeInfo.to, feeAmount);
                    IBaseRewardPool(feeInfo.to).donateRewards(feeAmount, rewardToken);
                } else {
                    IERC20(rewardToken).transfer(feeInfo.to, feeAmount);
                    emit RewardPaidTo(feeInfo.to, rewardToken, feeAmount);
                }
                afterFee -= feeAmount;
            }
        }
        _approveTokenIfNeeded(joe, rewarder, afterFee);
        IBaseRewardPool(rewarder).queueNewRewards(afterFee, joe);
    }

    /// @notice Send Unusual rewards to the rewarders, as airdrops
    /// @dev fees are not collected
    /// @param _token the address of the token to send
    /// @param _rewarder the rewarder that will get the rewards
    function sendTokenRewards(address _token, address _rewarder) external onlyOwner {
        // require(_token != joe, "not authorized");
        // require(!pools[_token].isActive, "Not authorized");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        _approveTokenIfNeeded(_token, _rewarder, amount);
        IBaseRewardPool(_rewarder).queueNewRewards(amount, _token);
    }

    /// @notice Send Unusual rewards to the rewarders, as airdrops
    /// @dev fees are not collected
    /// @param _token the address of the token to send
    /// @param _rewarder the rewarder that will get the rewards
    function donateTokenRewards(address _token, address _rewarder) external onlyOwner {
        // require(_token != joe, "not authorized");
        // require(!pools[_token].isActive, "Not authorized");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        _approveTokenIfNeeded(_token, _rewarder, amount);
        IBaseRewardPool(_rewarder).donateRewards(amount, _token);
    }

    /// @notice withdraw from a Joe pool
    /// @dev Only a PoolHelper can call this function
    /// @param token the address of the pool token from which to withdraw
    /// @param _amount the initial amount of tokens to withdraw
    function withdraw(address token, uint256 _amount) external {
        // _amount is the amount of stable
        Pool storage poolInfo = pools[token];
        require(msg.sender == poolInfo.helper, "Only helper can withdraw");
        IMintableERC20(poolInfo.receiptToken).burn(msg.sender, _amount);
        IMasterJoe(masterJoe).withdraw(poolInfo.pid, _amount);
        IERC20(token).safeTransfer(poolInfo.helper, _amount);
    }

    function stakeJoeOwner(uint256 _amount) external onlyOwner {
        _stakeJoe(_amount);
    }

    function boostEndDate() public view returns (uint256 date) {
        (, , , date) = IJoeStaking(stakingJoe).userInfos(address(this));
    }

    function joeBalance() public view returns (uint256) {
        return IERC20(joe).balanceOf(address(this));
    }

    function remainingForBoost() public view returns (uint256) {
        uint256 stakedJoe = getStakedJoe();
        uint256 balance = joeBalance();
        uint256 threshold = (stakedJoe * boosterThreshold()) / 100;
        if (balance >= threshold + 1 ether) {
            return 0;
        }
        return threshold + 1 ether - balance;
    }

    function stakeJoe(uint256 _amount) public {
        uint256 amount = _amount;
        if (boostBufferActivated == false) {
            _stakeJoe(amount);
            return;
        }
        uint256 neededForBoost = remainingForBoost();
        if (neededForBoost == 0) {
            uint256 balance = joeBalance();
            if ((block.timestamp > boostEndDate()) || bypassBoostWait) {
                _stakeJoe(balance);
            } else {
                uint256 stakedJoe = getStakedJoe();
                uint256 threshold = (stakedJoe * boosterThreshold()) / 100;
                _stakeJoe(((balance - threshold) * (100 - boosterThreshold())) / 100);
            }
        } else {
            claimVeJoe();
        }
    }

    /// @notice stake Joe
    /// @param amount the number of Joe to stake
    /// @dev the Joe must already be in the contract
    function _stakeJoe(uint256 amount) internal {
        if (amount > 0) {
            uint256 veJoeAmount = getPendingVeJoe();
            _approveTokenIfNeeded(joe, stakingJoe, amount);
            IJoeStaking(stakingJoe).deposit(amount);
            emit veJoeClaimed(veJoeAmount);
        }
        emit NewJoeStaked(amount);
    }

    /// @notice Claim the pending veJoe
    function claimVeJoe() public {
        uint256 amount = getPendingVeJoe();
        if (amount > 0) {
            IJoeStaking(stakingJoe).claim();
        }
        emit veJoeClaimed(amount);
    }

    /// @notice gets the pending veJoe
    function getPendingVeJoe() public view returns (uint256 pending) {
        pending = IJoeStaking(stakingJoe).getPendingVeJoe(address(this));
    }

    /// @notice gets the number of staked Joe by this contract
    function getStakedJoe() public view returns (uint256 stakedJoe) {
        (stakedJoe, , , ) = IJoeStaking(stakingJoe).userInfos(address(this));
    }

    /// @notice get the number of veJoe of this contract
    function getVeJoe() external view returns (uint256) {
        return IERC20(veJoe).balanceOf(address(this));
    }

    /// @notice Register a new pool of Joe
    /// @dev this function will deploy a new PoolHelper, and add the pool to the masterVTX
    /// @param _pid the pid of the pool
    /// @param _token the token to stake in the pool
    /// @param receiptName the name of the receipt Token
    /// @param receiptSymbol the symbol of the receipt Token
    /// @param allocPoints the weight of the VTX allocation
    function registerPool(
        uint256 _pid,
        address _token,
        string memory receiptName,
        string memory receiptSymbol,
        uint256 allocPoints
    ) external onlyOwner {
        require(pools[_token].isActive == false, "Pool is already registered and active");
        IERC20 newToken = IERC20(ERC20FactoryLib.createERC20(receiptName, receiptSymbol));
        address rewarder = IMasterChefVTX(masterVtx).createRewarder(
            address(newToken),
            address(joe)
        );
        IPoolHelper helper = IPoolHelper(
            PoolHelperJoeFactoryLib.createPoolHelper(
                _pid,
                address(newToken),
                address(_token),
                address(this),
                address(masterVtx),
                address(rewarder),
                address(xJoe),
                router
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
            receiptToken: address(newToken),
            rewarder: address(rewarder),
            helper: address(helper)
        });
        emit PoolAdded(_token);
    }

    /// @notice Get the information of a pool
    /// @param _address the address of the deposit token to fetch information for
    /// @return pid the pid of the pool
    /// @return isActive true if the pool is active
    /// @return token the deposit Token
    /// @return receipt - the address of the receipt token of this pool
    /// @return rewardsAddr the address of the rewarder
    /// @return helper the address of the poolHelper
    function getPoolInfo(address _address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address receipt,
            address rewardsAddr,
            address helper
        )
    {
        Pool storage tokenInfo = pools[_address];
        pid = tokenInfo.pid;
        isActive = tokenInfo.isActive;
        token = tokenInfo.token;
        receipt = tokenInfo.receiptToken;
        rewardsAddr = tokenInfo.rewarder;
        helper = tokenInfo.helper;
    }

    function removePool(address token) external onlyOwner {
        pools[token].isActive = false;
        emit PoolRemoved(token);
    }

    function setPoolHelper(address token, address _poolhelper) external onlyOwner {
        Pool storage poolInfo = pools[token];
        poolInfo.helper = _poolhelper;
        emit PoolHelperSet(token);
    }

    function setPoolRewarder(address token, address _poolRewarder) external onlyOwner {
        Pool storage poolInfo = pools[token];
        poolInfo.rewarder = _poolRewarder;
        emit PoolRewarderSet(token, _poolRewarder);
    }

    function setMasterChief(address _masterVtx) external onlyOwner {
        masterVtx = _masterVtx;
        emit MasterChiefSet(_masterVtx);
    }

    function setMasterJoe(address _masterJoe) external onlyOwner {
        masterJoe = _masterJoe;
        emit MasterJoeSet(_masterJoe);
    }

    function addBonusRewardForAsset(address _asset, address _bonusToken) external onlyOwner {
        assetToBonusRewards[_asset].push(_bonusToken);
    }

    receive() external payable {
        IWAVAX(WAVAX).deposit{value: address(this).balance}();
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

interface IJoeStaking {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function claim() external;

    function getPendingVeJoe(address _user) external view returns (uint256);

    function userInfos(address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function speedUpThreshold() external view returns(uint256);

    }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseRewardPool {
    struct Reward {
        address rewardToken;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 historicalRewards;
    }

    function rewards(address token)
        external
        view
        returns (Reward memory rewardInfo);

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

    function donateRewards(uint256 _amountReward, address _rewardToken)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolHelper {
    function totalSupply() external view returns (uint256);

    function balance(address _address) external view returns (uint256);

    function depositTokenBalance() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function harvest() external;

    function update() external;

    function earned()
        external
        view
        returns (uint256 vtxAmount, uint256 ptpAmount);

    function deposit(uint256 amount) external;

    function stake(uint256 amount) external;

    function withdraw(uint256 amount, uint256 minimumAmount) external;

    function getReward() external;

    function pendingPTP() external view returns (uint256 pendingTokens);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IMintableERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function mint(address, uint256) external;
    function faucet(uint256) external;

    function burn(address, uint256) external;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterChefVTX {
    function poolLength() external view returns (uint256);

    function setPoolManagerStatus(address _address, bool _bool) external;

    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder,
        address _helper
    ) external;

    function set(
        address _lp,
        uint256 _allocPoint,
        address _rewarder,
        address _locker,
        bool overwrite
    ) external;

    function createRewarder(address _lpToken, address mainRewardToken)
        external
        returns (address);

    // View function to see pending VTXs on frontend.
    function getPoolInfo(address token)
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

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

    function rewarderBonusTokenInfo(address _lp)
        external
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function massUpdatePools() external;

    function updatePool(address _lp) external;

    function deposit(address _lp, uint256 _amount) external;

    function depositFor(
        address _lp,
        uint256 _amount,
        address sender
    ) external;

    function lock(
        address _lp,
        uint256 _amount,
        uint256 _index,
        bool force
    ) external;

    function unlock(
        address _lp,
        uint256 _amount,
        uint256 _index
    ) external;

    function multiUnlock(
        address _lp,
        uint256[] calldata _amount,
        uint256[] calldata _index
    ) external;

    function withdraw(address _lp, uint256 _amount) external;

    function withdrawFor(
        address _lp,
        uint256 _amount,
        address _sender
    ) external;

    function multiclaim(address[] memory _lps, address user_address) external;

    function emergencyWithdraw(address _lp, address sender) external;

    function updateEmissionRate(uint256 _vtxPerSec) external;

    function depositInfo(address _lp, address _user)
        external
        view
        returns (uint256 depositAmount);

    function setPoolHelper(
        address _lp,
        address _helper
    ) external;

     function authorizeLocker(address _locker) external;
     function lockFor(
        address _lp,
        uint256 _amount,
        uint256 _index,
        address _for,
        bool force
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IxJoe {
    function mainContract() external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function symbol() external view returns (string memory);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function depositFor(uint256 amount, address to) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function depositWithoutTransferFor(uint256 _amount, address _for) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterJoe {
    function deposit(uint256 _pid, uint256 amount) external;

    function withdraw(uint256 _pid, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "poolHelperJoe.sol";

library PoolHelperJoeFactoryLib {
    function createPoolHelper(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _mainStaking,
        address _masterVtx,
        address _rewarder,
        address _xjoe,
        address _router
    ) public returns (address) {
        PoolHelperJoe pool = new PoolHelperJoe(
            _pid,
            _stakingToken,
            _depositToken,
            _mainStaking,
            _masterVtx,
            _rewarder,
            _xjoe,
            _router
        );
        return address(pool);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeERC20.sol";
import "IBaseRewardPool.sol";
import "IMainStakingJoe.sol";
import "IMasterChefVTX.sol";
import "IJoeRouter02.sol";
import "IJoePair.sol";
import "IWavax.sol";

/// @title Poolhelper
/// @author Vector Team
/// @notice This contract is the main contract that user will intreact with in order to stake stable in Vector protocol
contract PoolHelperJoe {
    using SafeERC20 for IERC20;
    address public depositToken;
    address public constant wavax = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public immutable stakingToken;
    address public immutable xJoe;
    address public immutable masterVtx;
    address public immutable joeRouter;
    address public immutable mainStakingJoe;
    address public immutable rewarder;
    uint256 public immutable pid;
    bool public immutable isWavaxPool;

    address public tokenA;
    address public tokenB;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = 1;

    event NewDeposit(address indexed user, uint256 amount);
    event NewWithdraw(address indexed user, uint256 amount);

    constructor(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _mainStakingJoe,
        address _masterVtx,
        address _rewarder,
        address _xJoe,
        address _joeRouter
    ) {
        pid = _pid;
        stakingToken = _stakingToken;
        depositToken = _depositToken;
        mainStakingJoe = _mainStakingJoe;
        masterVtx = _masterVtx;
        rewarder = _rewarder;
        xJoe = _xJoe;
        tokenA = IJoePair(depositToken).token0();
        tokenB = IJoePair(depositToken).token1();
        isWavaxPool = (tokenA == wavax || tokenB == wavax);
        joeRouter = _joeRouter;
    }

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
    function balanceOf(address _address) public view returns (uint256) {
        return IBaseRewardPool(rewarder).balanceOf(_address);
    }

    modifier _harvest() {
        IMainStakingJoe(mainStakingJoe).harvest(depositToken, false);
        _;
    }

    /// @notice harvest pending Joe and get the caller fee
    function harvest() public {
        IMainStakingJoe(mainStakingJoe).harvest(depositToken, true);
        IERC20(xJoe).safeTransfer(msg.sender, IERC20(xJoe).balanceOf(address(this)));
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
    function _stake(uint256 _amount) internal {
        _approveTokenIfNeeded(stakingToken, masterVtx, _amount);
        IMasterChefVTX(masterVtx).depositFor(stakingToken, _amount, msg.sender);
    }

    /// @notice unstake from the masterchief of VTX on behalf of the caller
    function _unstake(uint256 _amount) internal {
        IMasterChefVTX(masterVtx).withdrawFor(stakingToken, _amount, msg.sender);
    }

    function _deposit(uint256 _amount) internal {
        _approveTokenIfNeeded(depositToken, mainStakingJoe, _amount);
        IMainStakingJoe(mainStakingJoe).deposit(depositToken, _amount);
    }

    /// @notice deposit lp in mainStakingJoe, autostake in masterchief of VTX
    /// @dev performs a harvest of Joe just before depositing
    /// @param amount the amount of lp tokens to deposit
    function deposit(uint256 amount) external _harvest {
        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), amount);
        _deposit(amount);
        _stake(amount);
        emit NewDeposit(msg.sender, amount);
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

    /// @notice convert tokens to lp tokens
    /// @param amountA amount of the first token we want to convert
    /// @param amountB amount of the second token we want to convert
    /// @param amountAMin minimum amount of the first token we want to convert
    /// @param amountBMin minimum amount of the second token we want to convert
    /// @return amountAConverted amount of the first token converted during the operation of adding liquidity to the pool
    /// @return amountBConverted amount of the second token converted during the operation of adding liquidity to the pool
    /// @return liquidity amount of lp tokens minted during the operation of adding liquidity to the pool
    function _createLPTokens(
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin
    )
        internal
        returns (
            uint256 amountAConverted,
            uint256 amountBConverted,
            uint256 liquidity
        )
    {
        _approveTokenIfNeeded(tokenA, joeRouter, amountA);
        _approveTokenIfNeeded(tokenB, joeRouter, amountB);
        (amountAConverted, amountBConverted, liquidity) = IJoeRouter01(joeRouter).addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            amountAMin,
            amountBMin,
            address(this),
            block.timestamp
        );
    }

    /// @notice Add liquidity and then deposits lp in mainStakingJoe, autostake in masterchief of VTX
    /// @dev performs a harvest of Joe just before depositing
    /// @param amountA the desired amount of token A to deposit
    /// @param amountB the desired amount of token B to deposit
    /// @param amountAMin the minimum amount of token B to get back
    /// @param amountBMin the minimum amount of token B to get back
    /// @param isAvax is the token actually native ether ?
    /// @return amountAConverted the amount of token A actually converted
    /// @return amountBConverted the amount of token B actually converted
    /// @return liquidity the amount of LP obtained
    function addLiquidityAndDeposit(
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        bool isAvax
    )
        external
        payable
        nonReentrant
        _harvest
        returns (
            uint256 amountAConverted,
            uint256 amountBConverted,
            uint256 liquidity
        )
    {
        if (isAvax && isWavaxPool) {
            uint256 amountWavax = (tokenA == wavax) ? amountA : amountB;
            require(amountWavax <= msg.value, "Not enough AVAX");
            IWAVAX(wavax).deposit{value: msg.value}();
            (address token, uint256 amount) = (tokenA == wavax)
                ? (tokenB, amountB)
                : (tokenA, amountA);
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
            IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);
        }
        (amountAConverted, amountBConverted, liquidity) = _createLPTokens(
            amountA,
            amountB,
            amountAMin,
            amountBMin
        );
        _deposit(liquidity);
        _stake(liquidity);
        IERC20(tokenB).safeTransfer(msg.sender, amountB - amountBConverted);
        IERC20(tokenA).safeTransfer(msg.sender, amountA - amountAConverted);
        emit NewDeposit(msg.sender, liquidity);
    }

    /// @notice stake the receipt token in the masterchief of VTX on behalf of the caller
    function stake(uint256 _amount) external {
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
        _approveTokenIfNeeded(stakingToken, masterVtx, _amount);
        IMasterChefVTX(masterVtx).depositFor(stakingToken, _amount, msg.sender);
    }

    function _withdraw(uint256 amount) internal {
        _unstake(amount);
        IMainStakingJoe(mainStakingJoe).withdraw(depositToken, amount);
    }

    /// @notice withdraw stables from mainStakingJoe, auto unstake from masterchief of VTX
    /// @dev performs a harvest of Joe before withdrawing
    /// @param amount the amount of LP tokens to withdraw
    function withdraw(uint256 amount) external _harvest nonReentrant {
        _withdraw(amount);
        IERC20(depositToken).safeTransfer(msg.sender, amount);
        emit NewWithdraw(msg.sender, amount);
    }

    /// @notice withdraw stables from mainStakingJoe, auto unstake from masterchief of VTX
    /// @dev performs a harvest of Joe before withdrawing
    /// @param amount the amount of stables to deposit
    /// @param amountAMin the minimum amount of token A to get back
    /// @param amountBMin the minimum amount of token B to get back
    /// @param isAvax is the token actually native ether ?
    function withdrawAndRemoveLiquidity(
        uint256 amount,
        uint256 amountAMin,
        uint256 amountBMin,
        bool isAvax
    ) external _harvest nonReentrant {
        _withdraw(amount);
        _approveTokenIfNeeded(depositToken, joeRouter, amount);
        _approveTokenIfNeeded(depositToken, depositToken, amount);

        if (isAvax && isWavaxPool) {
            (address token, uint256 amountTokenMin, uint256 amountAVAXMin) = tokenA == wavax
                ? (tokenB, amountBMin, amountAMin)
                : (tokenA, amountAMin, amountBMin);
            IJoeRouter02(joeRouter).removeLiquidityAVAX(
                token,
                amount,
                amountTokenMin,
                amountAVAXMin,
                msg.sender,
                block.timestamp
            );
        } else {
            IJoeRouter02(joeRouter).removeLiquidity(
                tokenA,
                tokenB,
                amount,
                amountAMin,
                amountBMin,
                msg.sender,
                block.timestamp
            );
        }
        emit NewWithdraw(msg.sender, amount);
    }

    /// @notice Harvest VTX and Joe rewards
    function getReward() external _harvest {
        IMasterChefVTX(masterVtx).depositFor(stakingToken, 0, msg.sender);
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
pragma solidity ^0.8.0;

interface IMainStakingJoe {
    function setXJoe(address _xJoe) external;

    function addFee(
        uint256 max,
        uint256 min,
        uint256 value,
        address to,
        bool isJoe,
        bool isAddress
    ) external;

    function setFee(uint256 index, uint256 value) external;

    function removeFee(uint256 index) external;

    function setCallerFee(uint256 value) external;

    function deposit(address token, uint256 amount) external;

    function harvest(address token, bool isUser) external;

    function sendTokenRewards(address _token, address _rewarder) external;

    function donateTokenRewards(address _token, address _rewarder) external;

    function withdraw(address token, uint256 _amount) external;

    function stakeJoe(uint256 amount) external;

    function stakeOrBufferJoe(uint256 amount) external;

    function stakeAllJoe() external;

    function claimVeJoe() external;

    function getStakedJoe() external view returns (uint256 stakedJoe);

    function getVeJoe() external view returns (uint256);

    function registerPool(
        uint256 _pid,
        address _token,
        string memory receiptName,
        string memory receiptSymbol,
        uint256 allocPoints
    ) external;

    function getPoolInfo(address _address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address receipt,
            address rewards_addr,
            address helper
        );

    function removePool(address token) external;

    function setPoolHelper(address token, address _poolhelper) external;

    function setPoolRewarder(address token, address _poolRewarder) external;

    function setMasterChief(address _masterVtx) external;

    function setMasterJoe(address _masterJoe) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "MintableERC20.sol";

library ERC20FactoryLib {
    function createERC20(string memory name_, string memory symbol_) public returns (address) {
        ERC20 token = new MintableERC20(name_, symbol_);
        return address(token);
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