// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IArableOracle.sol";
import "./interfaces/IArableSynth.sol";
import "./interfaces/IArableFarming.sol";
import "./interfaces/IArableCollateral.sol";
import "./interfaces/IArableAddressRegistry.sol";
import "./interfaces/IArableFeeCollector.sol";

// Generalized epoch basis staking contract (epoch = 1 day)
contract ArableFarming is
    Initializable,
    OwnableUpgradeable,
    IArableFarming,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    address public addressRegistry;
    uint256 public epochZeroTime;
    uint256 public epochDuration;

    // rewardRateSum[farmId][rewardToken][epoch]: rewardRateSum from epoch0 to epoch for stakingFarm's rewardToken
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public rewardRateSum;
    // lastClaimEpoch[farmId][rewardToken][address]: last claimed epoch by address
    mapping(uint256 => mapping(address => mapping(address => uint256))) public lastClaimEpoch;
    // farm start epoch
    mapping(uint256 => uint256) public farmStartEpoch;
    mapping(uint256 => mapping(address => uint256)) public lastRewardRateSumEpoch;

    address[] public stakingTokens;
    mapping(address => bool) public isStakingToken;
    mapping(uint256 => bool) public isDisabledFarm;

    // staking amount by farm and address
    mapping(uint256 => mapping(address => uint256)) public stakingAmount;

    // staking pools per address
    // user_address => staking_pools
    mapping(address => uint256[]) public usedFarmingPools;
    // user_address => staking_pool => bool
    mapping(address => mapping(uint256 => bool)) public isUsedFarmingPool;

    // reward tokens per staking pool, limit to 3 tokens to be simple
    mapping(uint256 => mapping(uint256 => address)) public rewardTokens;
    mapping(uint256 => uint256) public rewardTokenLengths;
    mapping(uint256 => mapping(address => bool)) public _isRewardToken;

    event RegisterStakingPool(uint256 farmId, address stakingToken);
    event Deposit(uint256 farmId, address stakingToken, uint256 amount, uint256 fees);
    event Withdraw(uint256 farmId, address stakingToken, uint256 amount, uint256 fees);
    event Claim(uint256 farmId, address rewardToken, uint256 amount);
    event Pause();
    event Unpause();

    modifier onlyValidFarmId(uint256 farmId) {
        require(farmId < stakingTokens.length, "not a valid farm id");
        _;
    }

    function initialize(address addressRegistry_, uint256 epochDuration_) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init();
        __Pausable_init_unchained();

        require(addressRegistry_ != address(0), "Invalid addressRegistry_");

        addressRegistry = addressRegistry_;
        epochZeroTime = block.timestamp;

        epochDuration = epochDuration_;
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpause();
    }

    function getStakingTokens() external view returns (address[] memory) {
        return stakingTokens;
    }

    function getStakingTokensCount() external view returns (uint256) {
        return stakingTokens.length;
    }

    function bulkRegisterFarm(address[] calldata farmToken_) external onlyOwner {
        for (uint256 i = 0; i < farmToken_.length; i++) {
            registerFarm(farmToken_[i]);
        }
    }

    function bulkSetRewardTokens(uint256[] calldata farmIds, address[][] calldata rewardTokens_) external onlyOwner {
        require(farmIds.length == rewardTokens_.length, "Please check your input data.");
        for (uint256 i = 0; i < farmIds.length; i++) {
            setRewardTokens(farmIds[i], rewardTokens_[i]);
        }
    }

    // run by bot or anyone per epoch
    function updateRewardRateSum(uint256 farmId, address rewardToken)
        external
        override
        nonReentrant
        onlyValidFarmId(farmId)
        whenNotPaused
    {
        uint256 lastEpoch = lastRewardRateSumEpoch[farmId][rewardToken];
        uint256 curEpoch = currentEpoch();
        require(curEpoch > lastEpoch, "Refresh already up-to-date");

        address oracle = IArableAddressRegistry(addressRegistry).getArableOracle();
        IArableOracle oracleContract = IArableOracle(oracle);
        uint256 dailyRewardRate = oracleContract.getDailyRewardRate(farmId, rewardToken);
        lastRewardRateSumEpoch[farmId][rewardToken] = curEpoch;
        uint256 lastEpochRewardSum = rewardRateSum[farmId][rewardToken][lastEpoch];

        // Note: ideally, this should run epoch basis and for loop depth should be 1
        // In case this isn't maintained for a while, this script should run several times
        // until it's synchronized with current epoch
        // This is due to prevent potential gas overflow issue
        uint256 windowEndEpoch = curEpoch;
        if (windowEndEpoch > lastEpoch + 10) {
            windowEndEpoch = lastEpoch + 10;
        }
        for (lastEpoch = lastEpoch + 1; lastEpoch <= windowEndEpoch; lastEpoch++) {
            rewardRateSum[farmId][rewardToken][lastEpoch] = lastEpochRewardSum + dailyRewardRate;
        }
    }

    function setIsDisabledFarm(uint256 farmId, bool isDisabled) external override onlyOwner onlyValidFarmId(farmId) {
        isDisabledFarm[farmId] = isDisabled;
    }

    function stake(uint256 farmId, uint256 amount)
        external
        override
        nonReentrant
        onlyValidFarmId(farmId)
        whenNotPaused
    {
        require(!isDisabledFarm[farmId], "the operation is not allowed on disabled farm");
        require(amount > 0, "should stake positive amount");
        uint256 tokenBalance = IERC20(stakingTokens[farmId]).balanceOf(msg.sender);
        require(tokenBalance >= amount, "not enough balance for staking");

        // claim all the rewards before staking
        _claimAllRewards(farmId);

        // collect farm enter fee
        IERC20(stakingTokens[farmId]).safeTransferFrom(msg.sender, address(this), amount);
        uint256 fees = payFeesFor(stakingTokens[farmId], amount, msg.sender, ArableFees.Model.SETUP_FARM);

        stakingAmount[farmId][msg.sender] += amount - fees;

        // register usedFarmingPools
        if (isUsedFarmingPool[msg.sender][farmId] == false) {
            usedFarmingPools[msg.sender].push(farmId);
            isUsedFarmingPool[msg.sender][farmId] = true;
        }

        emit Deposit(farmId, stakingTokens[farmId], amount, fees);
    }

    function unstake(uint256 farmId, uint256 amount)
        external
        override
        nonReentrant
        onlyValidFarmId(farmId)
        whenNotPaused
    {
        require(!isDisabledFarm[farmId], "the operation is not allowed on disabled farm");
        require(amount > 0, "should unstake positive amount");

        // claim all the rewards before unstaking
        _claimAllRewards(farmId);

        // collect farm exist fee
        address stakingToken = stakingTokens[farmId];
        uint256 fees = payFeesFor(stakingToken, amount, msg.sender, ArableFees.Model.EXIT_FARM);

        // TODO: we might need to add unstake notice period
        stakingAmount[farmId][msg.sender] -= amount;
        IERC20(stakingToken).safeTransfer(msg.sender, amount - fees);

        emit Withdraw(farmId, stakingToken, amount, fees);
    }

    function getRewardTokens(uint256 farmId) external view override returns (address[] memory) {
        address[] memory tokens = new address[](rewardTokenLengths[farmId]);
        for (uint256 i = 0; i < rewardTokenLengths[farmId]; i++) {
            tokens[i] = rewardTokens[farmId][i];
        }
        return tokens;
    }

    function isRewardToken(uint256 farmId, address rewardToken) external view override returns (bool) {
        return _isRewardToken[farmId][rewardToken];
    }

    // create a new farm
    function registerFarm(address stakingToken) public override onlyOwner returns (uint256 farmId) {
        require(stakingToken != address(0x0), "stakingToken should be set");
        require(!isStakingToken[stakingToken], "stakingToken already registered");
        stakingTokens.push(stakingToken);
        isStakingToken[stakingToken] = true;
        farmId = stakingTokens.length - 1;
        emit RegisterStakingPool(farmId, stakingToken);
        return farmId;
    }

    function setRewardTokens(uint256 farmId, address[] memory _rewardTokens)
        public
        override
        onlyOwner
        onlyValidFarmId(farmId)
    {
        deleteRewardTokens(farmId);
        uint256 curEpoch = currentEpoch();
        farmStartEpoch[farmId] = curEpoch;
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            address rewardToken = _rewardTokens[i];
            rewardTokens[farmId][i] = rewardToken;
            _isRewardToken[farmId][rewardToken] = true;
            uint256 lastEpoch = lastRewardRateSumEpoch[farmId][rewardToken];
            uint256 lastEpochRewardSum = rewardRateSum[farmId][rewardToken][lastEpoch];
            lastRewardRateSumEpoch[farmId][rewardToken] = curEpoch;
            rewardRateSum[farmId][rewardToken][curEpoch] = lastEpochRewardSum;
        }
        rewardTokenLengths[farmId] = _rewardTokens.length;
    }

    function currentEpoch() public view override returns (uint256) {
        return (block.timestamp - epochZeroTime) / epochDuration;
    }

    function deleteRewardTokens(uint256 farmId) public override onlyOwner onlyValidFarmId(farmId) {
        for (uint256 i = 0; i < rewardTokenLengths[farmId]; i++) {
            _isRewardToken[farmId][rewardTokens[farmId][i]] = false;
        }
        rewardTokenLengths[farmId] = 0;
    }

    function claimAllRewards(uint256 farmId) public override nonReentrant whenNotPaused {
        for (uint256 i = 0; i < rewardTokenLengths[farmId]; i++) {
            _claimReward(farmId, rewardTokens[farmId][i]);
        }
    }

    function claimReward(uint256 farmId, address rewardToken) public override nonReentrant whenNotPaused {
        _claimReward(farmId, rewardToken);
    }

    function estimatedReward(
        uint256 farmId,
        address rewardToken,
        address user
    ) public view override returns (uint256) {
        uint256 latestClaimableEpoch = lastRewardRateSumEpoch[farmId][rewardToken];
        uint256 claimedEpoch = lastClaimEpoch[farmId][rewardToken][user];
        if (claimedEpoch < farmStartEpoch[farmId]) {
            claimedEpoch = farmStartEpoch[farmId];
        }
        uint256 curRewardRateSum = rewardRateSum[farmId][rewardToken][latestClaimableEpoch];
        uint256 lastRewardRateSum = rewardRateSum[farmId][rewardToken][claimedEpoch];
        uint256 stakingAmt = stakingAmount[farmId][user];
        uint256 claimAmount = ((curRewardRateSum - lastRewardRateSum) * stakingAmt) / 1 ether;
        return claimAmount;
    }

    function _claimAllRewards(uint256 farmId) internal onlyValidFarmId(farmId) {
        for (uint256 i = 0; i < rewardTokenLengths[farmId]; i++) {
            _claimReward(farmId, rewardTokens[farmId][i]);
        }
    }

    function payFeesFor(
        address asset_,
        uint256 amount_,
        address account_,
        ArableFees.Model model_
    ) internal returns (uint256) {
        // collect fees for farm enter fee
        address feeCollectorAddress = IArableAddressRegistry(addressRegistry).getArableFeeCollector();
        IArableFeeCollector arableCollector = IArableFeeCollector(feeCollectorAddress);

        uint256 fees = arableCollector.calculateFees(asset_, amount_, account_, model_);
        IERC20(asset_).safeApprove(feeCollectorAddress, fees);
        arableCollector.payFeesFor(asset_, amount_, account_, model_);

        return fees;
    }

    function _claimReward(uint256 farmId, address rewardToken) internal onlyValidFarmId(farmId) {
        require(!isDisabledFarm[farmId], "the operation is not allowed on disabled farm");

        uint256 latestClaimableEpoch = lastRewardRateSumEpoch[farmId][rewardToken];
        uint256 claimAmount = estimatedReward(farmId, rewardToken, msg.sender);

        lastClaimEpoch[farmId][rewardToken][msg.sender] = latestClaimableEpoch;
        IArableSynth(rewardToken).safeMint(msg.sender, claimAmount);

        // update totalDebt for reward claim event
        IArableAddressRegistry _addressRegistry = IArableAddressRegistry(addressRegistry);
        IArableOracle oracle = IArableOracle(_addressRegistry.getArableOracle());
        IArableCollateral collateral = IArableCollateral(_addressRegistry.getArableCollateral());
        uint256 tokenPrice = oracle.getPrice(rewardToken);
        if (tokenPrice > 0) {
            collateral.addToDebt((claimAmount * tokenPrice) / 1 ether);
        }

        emit Claim(farmId, rewardToken, claimAmount);

        // TODO: handle the case someone mint after pretty long time which could make big system debt changes
        // - Possibly set maximum amount of tokens to be able to claim for specific token
        // - Too big rewards for long time stake should be cut
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

interface IArableOracle {
    function getPrice(address token) external view returns (uint256);
    function getDailyRewardRate(uint256 farmId, address rewardToken) external view returns (uint256);
    function registerPrice(address token_, uint256 price_) external;
    function registerRewardRate(
        uint256 farmId_,
        address token_,
        uint256 dailyRewardRate_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IArableSynth is IERC20 {
    function mint(address toAddress, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function safeMint(address toAddress, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableFarming {
    function isRewardToken(uint256 farmId, address rewardToken) external view returns (bool);
    function getRewardTokens(uint256 farmId) external view returns (address[] memory);
    function currentEpoch() external view returns (uint256);
    function updateRewardRateSum(uint256 farmId, address rewardToken) external;
    function registerFarm(address stakingToken) external returns (uint256);
    function setRewardTokens(uint256 farmId, address[] memory _rewardTokens) external;
    function deleteRewardTokens(uint256 farmId) external;
    function setIsDisabledFarm(uint256 farmId, bool isDisabled) external;
    function stake(uint256 farmId, uint256 amount) external;
    function unstake(uint256 farmId, uint256 amount) external;
    function claimReward(uint256 farmId, address rewardToken) external;
    function claimAllRewards(uint256 farmId) external;
    function estimatedReward(uint256 farmId, address rewardToken, address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableCollateral {
    function addToDebt(uint amount) external returns (bool);
    function removeFromDebt(uint256 amount) external returns (bool);
    function getTotalDebt() external returns (uint);
    function addSupportedCollateral(address token, uint allowedRate) external returns (bool);
    function removeSupportedCollateral(address token) external returns (bool);
    function changeAllowedRate(address token, uint newAllowedRate) external returns (bool);
    function userRiskRate(address user) external view returns (uint256);
    function maxIssuableArUSD(address user) external view returns (uint);
    function currentDebt(address user) external view returns (uint);
    function calculateCollateralValue(address user) external view returns (uint);
    function _liquidateCollateral(address user, address beneficiary, uint liquidationAmount) external;
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/**
 * @title Provider interface for Arable
 * @dev
 */
interface IArableAddressRegistry {
    function getAddress(bytes32 id) external view returns (address);

    function setAddress(bytes32 id, address address_) external;

    function getArableOracle() external view returns (address);

    function setArableOracle(address arableOracle_) external;

    function getArableExchange() external view returns (address);

    function setArableExchange(address arableExchange_) external;

    function getArableManager() external view returns (address);

    function setArableManager(address arableManager_) external;

    function getArableFarming() external view returns (address);

    function setArableFarming(address arableFarming_) external;

    function getArableCollateral() external view returns (address);

    function setArableCollateral(address arableCollateral_) external;

    function getArableLiquidation() external view returns (address);

    function setArableLiquidation(address arableLiquidation_) external;

    function getArableFeeCollector() external view returns (address);

    function setArableFeeCollector(address arableFeeCollector_) external;
}

// interfaces/IArableFeeCollector.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libs/ArableFees.sol"; 

interface IArableFeeCollector {
    function calculateFees(
        address asset_,
        uint256 amount_,
        address account_,
        ArableFees.Model model_
    ) external view returns (uint256 fees);

    function setAssetFeeModel(
        address asset_,
        uint256 fees_,
        ArableFees.Model model_
    ) external;

    function payFeesFor(
        address asset_,
        uint256 amount_,
        address account_,
        ArableFees.Model model_
    ) external returns (uint256[] memory collectorReceipt);

    function setRewardTokens(address[] memory _rewardTokens) external;

    function deleteRewardTokens() external;

    function startNewEpoch() external;

    function increaseMinterRewards(address minter, address rewardToken, uint256 amount) external;

    function bulkIncreaseMinterRewards(
        address rewardToken,
        address[] calldata minters,
        uint256[] calldata amounts
    ) external;

    function claimReward(address rewardToken) external;

    function estimatedReward(address minter, address rewardToken) external view returns (uint256);

    function getTotalDistributableRewards(address rewardToken) external view  returns (uint256);
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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

library ArableFees {
    enum Model {
        DEFAULT,           // default fees if asset is unknow (0)
        SETUP_FARM,        // new farm fees
        EXIT_FARM,         // exit farm fees
        REWARD,            // reward fees
        SYNTHS_X,          // synthetic asset exchange fees
        SYNTHS_MINT,       // synthetic asset mint fees
        SYNTHS_BURN,       // synthetic asset burn fees
        LIQUIDATE,         // liquidation fees
        MAX                // maximumn value (8)
    }
}