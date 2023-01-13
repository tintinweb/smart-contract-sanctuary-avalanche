// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Initializable.sol";
import "OwnableUpgradeable.sol";
import "ERC20Upgradeable.sol";
import "SafeERC20.sol";
import "IMasterChefVTX.sol";
import "IBaseRewardPool.sol";
import "ISwapHelper.sol";
import "ISimplePoolHelper.sol";
import "IAvaxHelper.sol";
import "IxTokenConvertor.sol";
import "ILVTXAutoCompound.sol";
import "ISimplePoolHelper.sol";
import "IJoeRouter02.sol";

/// @title Compounder
/// @author Vector Team
contract xCoreLpCompounder is Initializable, OwnableUpgradeable, ERC20Upgradeable {
    using SafeERC20 for IERC20;

    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant VTX = 0x5817D4F0b62A59b17f75207DA1848C2cE75e7AF4;
    IJoeRouter02 public constant ROUTER = IJoeRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    IERC20 public TOKEN;
    IERC20 public LP;
    IERC20 public XTOKEN;
    IMasterChefVTX public masterchef;

    address public swapHelper;
    address public avaxHelper;
    address public poolHelper;
    address public rewarder;
    address public tokenConvertor;
    address public protocolFeeRecipient;
    address public rewarderForLvtxReceipts;
    address public vtxCompounder;
    address public lvtxRewarder;

    uint256 public callerFee;
    uint256 public protocolFee;
    uint256 public lastCompoundTime;
    uint256 public maxRewardPending;
    uint256 public lvtxFee;
    uint256 public constant DELAY_BETWEEN_COMPOUNDS = 60;
    uint256 public constant DENOMINATOR = 10000;

    address[] public rewardTokens;
    mapping(address => bool) public isRewardToken;
    mapping(address => uint256) public depositTracking;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvested(address indexed token, uint256 amount);
    event Compound(uint256 wavaxAmount);

    function __xCoreLpCompounder_init_(
        string memory _name,
        string memory _symbol,
        address _stakingToken,
        address _xStakingToken,
        address _lp,
        address _protocolFeeRecipient,
        address _masterchef,
        address _swapHelper,
        address _tokenConvertor
    ) public initializer {
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        TOKEN = IERC20(_stakingToken);
        XTOKEN = IERC20(_xStakingToken);
        LP = IERC20(_lp);
        protocolFeeRecipient = _protocolFeeRecipient;
        swapHelper = _swapHelper;
        masterchef = IMasterChefVTX(_masterchef);
        tokenConvertor = _tokenConvertor;
    }

    /// @notice Add a reward token to be compounded.
    /// @dev Be careful about adding temporary tokens. VTX is NOT to be treated as one
    /// @param rewardToken to be added
    function addRewardToken(address rewardToken) external onlyOwner {
        require(rewardToken != address(0) && rewardToken != VTX, "Forbidden tokens");
        if (!isRewardToken[rewardToken]) {
            rewardTokens.push(rewardToken);
            isRewardToken[rewardToken] = true;
        }
    }

    /// @notice Set the caller fee, rewarding caller for autocompounding. Is distributed in Wavax
    /// @param newValue the caller fee
    function setTokenConvertor(address newValue) external onlyOwner {
        tokenConvertor = newValue;
    }

    function setRewarderLVTXReceipts(address newValue) external onlyOwner {
        rewarderForLvtxReceipts = newValue;
    }

    function setLVTXCompounder(address newValue) external onlyOwner {
        vtxCompounder = newValue;
    }

    /// @notice Set the protocol fee.Is distributed in Wavax
    /// @param newValue the protocol fee
    function setLvtxFee(uint256 newValue) external onlyOwner {
        lvtxFee = newValue;
    }

    /// @notice Set the rewarder for lvtx
    /// @param _rewarder address of the fee collector
    function setLVTXRewarder(address _rewarder) external onlyOwner {
        lvtxRewarder = _rewarder;
    }

    /// @notice Set the caller fee, rewarding caller for autocompounding. Is distributed in Wavax
    /// @param newValue the caller fee
    function setCallerFee(uint256 newValue) external onlyOwner {
        callerFee = newValue;
    }

    /// @notice Set the protocol fee.Is distributed in Wavax
    /// @param newValue the protocol fee
    function setProtocolFee(uint256 newValue) external onlyOwner {
        protocolFee = newValue;
    }

    /// @notice Set the swap helper which takes care of all swaps
    /// @dev Important to always make sure this new swap helper has the correct routes
    /// @param _swapHelper address of the swap helper
    function setSwapHelper(address _swapHelper) external onlyOwner {
        swapHelper = _swapHelper;
    }

    /// @notice Set the swap helper which takes care withdrawing WAVAX
    /// @param _avaxHelper address of the avax helper
    function setAvaxHelper(address _avaxHelper) external onlyOwner {
        avaxHelper = _avaxHelper;
    }

    /// @notice Fetch the helper
    function updateDepositsInfo() external onlyOwner {
        (, , , , rewarder, poolHelper, ) = masterchef.addressToPoolInfo(address(LP));
    }

    /// @notice Set the recipient
    /// @param _recipient address of the fee collector
    function setProtocolFeeRecipient(address _recipient) external onlyOwner {
        protocolFeeRecipient = _recipient;
    }

    /// @notice Set the max pending reward parameter
    /// @param _maxRewardPending max reward pending before compounding on deposit
    function setMaximumPendingReward(uint256 _maxRewardPending) external onlyOwner {
        maxRewardPending = _maxRewardPending;
    }

    /// @notice Best practice to always be able to query the length of any array
    /// @return length of the reward
    function getRewardLength() external view returns (uint256 length) {
        length = rewardTokens.length;
    }

    /// @notice Returns the current deposits in the pool
    /// @return total deposits in the pool
    function totalDeposits() public view returns (uint256) {
        return masterchef.depositInfo(address(LP), address(this));
    }

    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint256 amount) public view returns (uint256) {
        if (totalSupply() * totalDeposits() == 0) {
            return amount;
        }
        return (amount * totalSupply()) / totalDeposits();
    }

    function userInitialDepositToken(address user) external view returns (uint256) {
        return depositTracking[user];
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint256 amount) public view returns (uint256) {
        if (totalSupply() * totalDeposits() == 0) {
            return 0;
        }
        return (amount * totalDeposits()) / totalSupply();
    }

    function userDeposits(address user) external view returns (uint256 userDeposit) {
        userDeposit = getDepositTokensForShares(balanceOf(user));
    }

    function previewRewardsForHarvest()
        external
        view
        returns (uint256 avaxAmount, uint256 vtxAmount)
    {
        if (totalDeposits() == 0) {
            return (0, 0);
        }
        (
            address[] memory rewardTokensList,
            uint256[] memory earnedRewards
        ) = pendingTokensToHarvest();
        if (rewardTokensList.length == 0) {
            return (0, pendingTokens());
        }
        avaxAmount = ISwapHelper(swapHelper).previewTotalAmountToAvax(
            rewardTokensList,
            earnedRewards
        );
        vtxAmount = pendingTokens();
    }

    function pendingTokensToHarvest()
        public
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        uint256 length = rewardTokens.length;
        tokens = new address[](length);
        amounts = new uint256[](length);
        (, , , , address rewarder, , ) = masterchef.addressToPoolInfo(address(LP));
        for (uint256 i; i < length; i++) {
            tokens[i] = rewardTokens[i];
            if (rewarder != address(0)) {
                amounts[i] =
                    IBaseRewardPool(rewarder).earned(address(this), rewardTokens[i]) +
                    IERC20(rewardTokens[i]).balanceOf(address(this));
            }
        }
    }

    function pendingTokens() public view returns (uint256 vtxAmount) {
        (vtxAmount, , , ) = IMasterChefVTX(masterchef).pendingTokens(
            address(LP),
            address(this),
            address(LP)
        );
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

    /// @notice DepositsLP in the pool
    /// @param _amount amount in LP to be deposited
    function _depositLp(uint256 _amount) internal {
        _approveTokenIfNeeded(address(LP), poolHelper, _amount);
        ISimplePoolHelper(poolHelper).depositFor(_amount, address(this));
    }

    /// @notice Withdraws all previous balance from the pool helper, and deposits into the compounder.
    function migrateAllUserDepositsFromManual() external {
        uint256 amount = masterchef.depositInfo(address(LP), msg.sender);
        _migrateFromManual(amount);
    }

    /// @notice Withdraws previous balance from the pool helper, and deposits into the compounder.
    function migrateFromManual(uint256 amount) external {
        _migrateFromManual(amount);
    }

    /// @notice Withdraws all previous balance from the pool helper, and deposits into the compounder.
    function _migrateFromManual(uint256 amount) internal {
        uint256 shares = getSharesForDepositTokens(amount);
        ISimplePoolHelper(poolHelper).swapToCompoundFor(msg.sender, amount);
        _mint(msg.sender, shares);
        depositTracking[msg.sender] += amount;
    }

    /// @notice Withdraws all previous balance from the compounder
    function migrateAllUserDepositsToManual() external {
        uint256 amount = getDepositTokensForShares(balanceOf(msg.sender));
        _migrateToManual(amount);
    }

    /// @notice Withdraws previous balance from the compounder
    function migrateToManual(uint256 amount) external {
        _migrateToManual(amount);
    }

    function getReward(address _for) external returns (bool) {
        IBaseRewardPool(rewarderForLvtxReceipts).getReward(_for);
        return true;
    }

    /// @notice Withdraws all previous balance from the compounder
    function _migrateToManual(uint256 amount) internal {
        uint256 sharesToBurn = getSharesForDepositTokens(amount);
        depositTracking[msg.sender] -=
            (depositTracking[msg.sender] * sharesToBurn) /
            balanceOf(msg.sender);
        require(balanceOf(msg.sender) >= sharesToBurn, "Not enough shares");
        _burn(msg.sender, sharesToBurn);
        ISimplePoolHelper(poolHelper).swapBackToManualFor(msg.sender, amount);
    }

    function _compoundIfNeeded() internal {
        if (maxRewardPending > 0 && pendingTokens() > maxRewardPending) {
            safeCompound();
        }
    }

    /// @notice DepositsLP in the pool and mints the correct amount of receipt shares to the holder
    /// @param amount amount in LP to be deposited
    function _deposit(uint256 amount) internal {
        uint256 shares = getSharesForDepositTokens(amount);
        _mint(msg.sender, shares);
        _depositLp(amount);
        depositTracking[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function deposit(uint256 amount) external {
        _compoundIfNeeded();
        LP.safeTransferFrom(msg.sender, address(this), amount);
        _deposit(amount);
    }

    /// @notice Withdraw the lp from the pool
    /// @param _amount amount in LP to be withdraw
    function _withdraw(uint256 _amount) internal {
        masterchef.withdraw(address(LP), _amount);
    }

    /// @notice Withdraw the lp from the pool, and burns the receipt
    /// @param amount amount in LP to be withdraw
    function withdraw(uint256 amount) external {
        uint256 shares = getSharesForDepositTokens(amount);
        depositTracking[msg.sender] -=
            (depositTracking[msg.sender] * shares) /
            balanceOf(msg.sender);
        _burn(msg.sender, shares);
        _withdraw(amount);
        LP.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @notice Convert WAVAX to the tokens and deposits liquidity, increasing the totalDeposits.
    /// @dev no need to track the increment.
    function _addLiquidityAndDepositLp() internal {
        uint256 amount = IERC20(WAVAX).balanceOf(address(this));
        if (amount > 0) {
            if (address(XTOKEN) == address(0)) {
                _getLpForTokenWithWavax(amount);
            } else {
                _getLpForXToken(amount);
            }
            _depositLp(LP.balanceOf(address(this)));
        }
    }

    function _getLpForXToken(uint256 wavaxAmount) internal {
        _swapWavaxToToken(address(TOKEN), wavaxAmount);
        _convertToLp();
    }

    function _getLpForTokenWithWavax(uint256 wavaxAmount) internal {
        _swapWavaxToToken(address(TOKEN), wavaxAmount / 2);
        _convertToLpWithWavax();
    }

    function _convertToLpWithWavax() internal {
        uint256 wavaxAmount = IERC20(WAVAX).balanceOf(address(this));
        uint256 tokenAmount = IERC20(TOKEN).balanceOf(address(this));
        _approveTokenIfNeeded(address(TOKEN), address(ROUTER), tokenAmount);
        _approveTokenIfNeeded(address(WAVAX), address(ROUTER), wavaxAmount);
        ROUTER.addLiquidity(
            address(TOKEN),
            address(WAVAX),
            tokenAmount,
            wavaxAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function _convertToLp() internal {
        uint256 amount = IERC20(TOKEN).balanceOf(address(this));
        _approveTokenIfNeeded(address(TOKEN), tokenConvertor, amount / 2);
        IxTokenConvertor(tokenConvertor).deposit(amount / 2);
        uint256 xTokenBalance = XTOKEN.balanceOf(address(this));
        _approveTokenIfNeeded(address(TOKEN), address(ROUTER), amount);
        _approveTokenIfNeeded(address(XTOKEN), address(ROUTER), xTokenBalance);
        ROUTER.addLiquidity(
            address(TOKEN),
            address(XTOKEN),
            amount - amount / 2,
            xTokenBalance,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function _harvestPool() public {
        masterchef.deposit(address(LP), 0);
    }

    /// @notice Swap the token to wavax
    /// @dev ISwapHelper needs to have the appropriate route.
    function _swapToWavax(address token, uint256 balance) internal {
        if (token != WAVAX) {
            _approveTokenIfNeeded(token, swapHelper, balance);
            ISwapHelper(swapHelper).swapTokenForWAVAX(token, balance, address(this), 0);
        }
    }

    /// @notice Swap token to Wavax but checks if possible before
    /// @dev To prevent end of rewards.
    function _safeSwapToWavax(address token, uint256 balance) internal {
        if (token != WAVAX && ISwapHelper(swapHelper).previewAmountToAvax(token, balance) > 0) {
            _approveTokenIfNeeded(token, swapHelper, balance);
            ISwapHelper(swapHelper).safeSwapTokenForWAVAX(token, balance, address(this), 0);
        }
    }

    /// @notice Swap wavax to token
    /// @dev ISwapHelper needs to have the appropriate route.
    function _swapWavaxToToken(address token, uint256 balance) internal {
        if (token != WAVAX) {
            address[] memory tokens = new address[](1);
            uint256[] memory amounts = new uint256[](1);
            tokens[0] = WAVAX;
            amounts[0] = balance;
            _approveTokenIfNeeded(WAVAX, swapHelper, balance);
            ISwapHelper(swapHelper).swapTokensForToken(tokens, amounts, token, address(this), 0);
        }
    }

    function compound() external {
        _compound(false);
    }

    function safeCompound() public {
        _compound(true);
    }

    /// @notice Compounds the rewards (sell into Avax, deposit LP) and sends fees
    /// @dev Always receive AVAX for the caller, and WAVAX for the protocol fee.
    function _compound(bool safeSwap) internal {
        require(block.timestamp > lastCompoundTime + DELAY_BETWEEN_COMPOUNDS, "Already compounded");
        lastCompoundTime = block.timestamp;
        _harvestPool();
        uint256 wavaxBalance = IERC20(WAVAX).balanceOf(address(this));
        uint256 length = rewardTokens.length;
        for (uint256 i; i < length; i++) {
            address token = rewardTokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                if (safeSwap) {
                    _safeSwapToWavax(token, balance);
                } else {
                    _swapToWavax(token, balance);
                }
            }
            if (token == WAVAX) {
                emit Harvested(token, wavaxBalance);
            } else {
                emit Harvested(token, balance);
            }
        }
        uint256 vtxBalance = IERC20(VTX).balanceOf(address(this));
        emit Harvested(VTX, vtxBalance);
        wavaxBalance = IERC20(WAVAX).balanceOf(address(this));
        uint256 _lvtxFee = (wavaxBalance * lvtxFee) / DENOMINATOR;
        uint256 _callerFee = (wavaxBalance * callerFee) / DENOMINATOR;
        uint256 _protocolFee = (wavaxBalance * protocolFee) / DENOMINATOR;
        uint256 _vtxCallerFee = (vtxBalance * callerFee) / DENOMINATOR;
        uint256 _vtxProtocolFee = (vtxBalance * protocolFee) / DENOMINATOR;
        uint256 _vtxLvtxFee = (vtxBalance * lvtxFee) / DENOMINATOR;

        if (_callerFee > 0) {
            _approveTokenIfNeeded(WAVAX, avaxHelper, _callerFee);
            IAvaxHelper(avaxHelper).withdrawTo(msg.sender, _callerFee);
        }
        if (_protocolFee > 0) {
            IERC20(WAVAX).safeTransfer(protocolFeeRecipient, _protocolFee);
        }
        if (_lvtxFee > 0) {
            _approveTokenIfNeeded(WAVAX, lvtxRewarder, _lvtxFee);
            IBaseRewardPool(lvtxRewarder).donateRewards(_lvtxFee, WAVAX);
        }

        if (_vtxCallerFee > 0) {
            IERC20(VTX).safeTransfer(msg.sender, _vtxCallerFee);
        }
        if (_vtxProtocolFee > 0) {
            IERC20(VTX).safeTransfer(protocolFeeRecipient, _vtxProtocolFee);
        }
        if (_vtxLvtxFee > 0) {
            _approveTokenIfNeeded(VTX, lvtxRewarder, _vtxLvtxFee);
            IBaseRewardPool(lvtxRewarder).donateRewards(_vtxLvtxFee, VTX);
        }
        _addLiquidityAndDepositLp();
        _lockVtx(IERC20(VTX).balanceOf(address(this)));

        emit Compound(wavaxBalance);
    }

    function _lockVtx(uint256 vtxBalance) internal {
        if (vtxBalance > 0) {
            _approveTokenIfNeeded(VTX, vtxCompounder, vtxBalance);
            ILVTXAutoCompound(vtxCompounder).depositVTX(vtxBalance);
            uint256 receiptAmount = IERC20(vtxCompounder).balanceOf(address(this));
            _approveTokenIfNeeded(vtxCompounder, rewarderForLvtxReceipts, receiptAmount);
            IBaseRewardPool(rewarderForLvtxReceipts).queueNewRewards(receiptAmount, vtxCompounder);
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0)) {
            IBaseRewardPool(rewarderForLvtxReceipts).withdrawFor(from, amount, true);
        }
        if (to != address(0)) {
            IBaseRewardPool(rewarderForLvtxReceipts).stakeFor(to, amount);
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "IERC20MetadataUpgradeable.sol";
import "ContextUpgradeable.sol";
import "Initializable.sol";

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
        __Context_init_unchained();
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";

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
pragma solidity 0.8.7;

interface IMasterChefVTX {
    event Add(uint256 allocPoint, address indexed lpToken, address indexed rewarder);
    event Deposit(address indexed user, address indexed lpToken, uint256 amount);
    event EmergencyWithdraw(address indexed user, address indexed lpToken, uint256 amount);
    event Harvest(address indexed user, address indexed lpToken, uint256 amount);
    event Locked(address indexed user, address indexed lpToken, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Set(
        address indexed lpToken,
        uint256 allocPoint,
        address indexed rewarder,
        address indexed locker,
        bool overwrite
    );
    event Unlocked(address indexed user, address indexed lpToken, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 _vtxPerSec);
    event UpdatePool(
        address indexed lpToken,
        uint256 lastRewardTimestamp,
        uint256 lpSupply,
        uint256 accVTXPerShare
    );
    event Withdraw(address indexed user, address indexed lpToken, uint256 amount);

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

interface IBaseRewardPool {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RewardAdded(uint256 reward, address indexed token);
    event RewardPaid(address indexed user, uint256 reward, address indexed token);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

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

interface ISwapHelper {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function PNG_ROUTER() external view returns (address);

    function ROUTER() external view returns (address);

    function VTX() external view returns (address);

    function WAVAX() external view returns (address);

    function __SwapHelper_init() external;

    function avaxHelper() external view returns (address);

    function findPathFromAvax(address token) external view returns (address[] memory);

    function findPathToAvax(address token) external view returns (address[] memory);

    function getRouter(address token) external view returns (address router);

    function owner() external view returns (address);

    function previewAmountFromAvax(address token, uint256 amount) external view returns (uint256);

    function previewAmountToAvax(address token, uint256 amount)
        external
        view
        returns (uint256 avaxAmount);

    function previewTotalAmountFromAvax(address[] calldata inTokens, uint256[] calldata amounts)
        external
        view
        returns (uint256 tokenAmount);

    function previewTotalAmountToAvax(address[] calldata inTokens, uint256[] calldata amounts)
        external
        view
        returns (uint256 avaxAmount);

    function previewTotalAmountToToken(
        address[] calldata inTokens,
        uint256[] calldata amounts,
        address to
    ) external view returns (uint256 tokenAmount);

    function renounceOwnership() external;

    function routeToAvax(address) external view returns (address);

    function routeToAvaxOnPlatypus(address) external view returns (address);

    function safeSwapTokenForAvax(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function safeSwapTokenForWAVAX(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function safeSwapTokensForAvax(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function safeSwapTokensForToken(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address token,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 tokenAmount);

    function safeSwapTokensForVTX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 vtxAmount);

    function safeSwapTokensForWAVAX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function setAvaxHelper(address helper) external;

    function setCustomRoute(
        address token,
        address[] calldata pools,
        address[] calldata inTokens,
        address[] calldata outTokens
    ) external;

    function setRouteToAvax(address asset, address route) external;

    function setRouteToAvaxOnPlatypus(address asset, address route) external;

    function setUsePng(address asset, bool use) external;

    function swapTokenForAvax(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function swapTokenForWAVAX(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function swapTokensForAvax(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function swapTokensForToken(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address token,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 tokenAmount);

    function swapTokensForVTX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 vtxAmount);

    function swapTokensForWAVAX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function sweep(address[] calldata tokens) external;

    function transferOwnership(address newOwner) external;

    function usePng(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISimplePoolHelper {
    event NewDeposit(address indexed user, uint256 amount);
    event NewWithdraw(address indexed user, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function authorize(address _for) external;

    function compounder() external view returns (address);

    function depositFor(uint256 _amount, address _for) external;

    function depositToken() external view returns (address);

    function masterVtx() external view returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setCompounder(address _compounder) external;

    function swapBackToManualFor(address user, uint256 amount) external;

    function swapToCompoundFor(address user, uint256 amount) external;

    function transferOwnership(address newOwner) external;

    function unauthorize(address _for) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAvaxHelper {
    function WAVAX() external view returns (address);

    function withdrawTo(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Smart Convertor
/// @author Vector Team
/// @notice Smart Convertor is a convertor to manage conversion or buying on trader Joe
interface IxTokenConvertor {
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

interface ILVTXAutoCompound {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Compounded(address indexed caller, uint256 vtxCompounded);
    event Deposited(address indexed user, uint256 amount, bool isVtx);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdrawal(address indexed user, uint256 amount);

    function DENOMINATOR() external view returns (uint256);

    function LVTX() external view returns (address);

    function MAX_TOKEN_TO_REINVEST() external view returns (uint256);

    function WAVAX() external view returns (address);

    function __LVTXAutoCompound_init_(
        address locker,
        address _delegatedPool,
        address _swapHelper,
        address _bribeManager,
        address _vtx
    ) external;

    function addRewardToken(address rewardToken) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function bribeManager() external view returns (address);

    function callerFee() external view returns (uint256);

    function compound() external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function delegatedPool() external view returns (address);

    function deleteRewardToken(uint256 index) external;

    function deposit(uint256 amount) external;

    function depositVTX(uint256 amount) external;

    function fixInitialDeposit(address user, uint256 value) external;

    function getDepositTokensForShares(uint256 amount) external view returns (uint256);

    function getRewardLength() external view returns (uint256 length);

    function getSharesForDepositTokens(uint256 amount) external view returns (uint256);

    function getTotalDepositToken() external view returns (uint256 totalDepositToken);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function initialDeposits(address) external view returns (uint256);

    function isRewardToken(address) external view returns (bool);

    function lastCompoundTime() external view returns (uint256);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pendingTokensToHarvest()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    function previewRewardsForHarvest()
        external
        view
        returns (uint256 avaxAmount, uint256 vtxAmount);

    function protocolFee() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address);

    function renounceOwnership() external;

    function rewardTokens(uint256) external view returns (address);

    function setCallerFee(uint256 newValue) external;

    function setFeeCollector(address _collector) external;

    function setMaxTokenToReinvest(uint256 value) external;

    function setProtocolFee(uint256 newValue) external;

    function setSwapHelper(address _swapHelper) external;

    function setWhitelistForTransfer(address _for, bool status) external;

    function swapHelper() external view returns (address);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function transferWhitelist(address) external view returns (bool);

    function userDepositToken(address user) external view returns (uint256 userDeposit);

    function userInitialDepositToken(address user) external view returns (uint256);

    function vtx() external view returns (address);

    function withdraw(uint256 amount) external;
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