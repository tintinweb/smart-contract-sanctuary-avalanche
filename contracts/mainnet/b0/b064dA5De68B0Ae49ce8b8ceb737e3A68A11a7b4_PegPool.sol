// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./@oz/OwnableUpgradeable.sol";
import "./@oz/ReentrancyGuardUpgradeable.sol";
import "./@oz/IERC20Upgradeable.sol";
import "./@oz/SafeERC20Upgradeable.sol";

import "./interfaces/IBoardroomTreasury.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IVault.sol";

import "./PegPoolView.sol";
import "./GrapePegToken.sol";

/// @dev Contract acts as a pool and an ERC20 token
/// @dev Contract uses an upgradeable proxy pattern to patch an issues if needed
/// @dev The associated master chef has a farm created just for this contracts token
/// @dev Minting of the token is not exposed externally
/// @dev So the contract is able to mint a single token of itself and deposit/withdraw as the only depositor in its own farm
contract PegPool is PegPoolView, GrapePegToken, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        /**
         * Prevents later initialization attempts after deployment.
         * If a base contract was left uninitialized, the implementation contracts
         * could potentially be compromised in some way.
         */
        _disableInitializers();
    }

    /// @dev Acts the constructor in an upgradeable pattern
    function initialize(
        address _depositToken,
        address[] memory _rewardTokenAddresses,
        uint256[] memory _rewardsPerBlock,
        address _boardroomTreasury,
        address[] memory _swapPath,
        address _router,
        address _rewardPool,
        address _pairAddress,
        address _treasury
    ) public initializer {
        // View contract inherits from state contract but centralizing some initializtion
        // at the entry point for clarity/simplicity
        __PegPoolState__init(
            _depositToken,
            _rewardTokenAddresses,
            _rewardsPerBlock,
            _boardroomTreasury,
            _swapPath,
            _router,
            _rewardPool,
            _pairAddress,
            _treasury
        );

        // All base contracts require manual initialization
        __ReentrancyGuard_init();
        __PegPoolView__init();
        __AmesPegToken__init();

        // Checks in base contract have passed at this point

        // Approvals
        depositToken.safeApprove(_router, type(uint256).max);
        depositToken.safeApprove(pairAddress, type(uint256).max);

        IERC20Upgradeable(AMES).safeApprove(_router, type(uint256).max);
        IERC20Upgradeable(AMES).safeApprove(pairAddress, type(uint256).max);

        // Mint to have a deposit amount for reward pool
        // Pool is the only one with ability to mint itself one time
        // So we only need one token to have 100% share of farm allocations
        _mint(address(this), 1 ether);
    }

    // =========================== STATE TRANSITIONS ============================= //

    /// @dev User entry point into the system.
    /// @dev Deposits are only enabled when peg token is below the target TWAP.
    /// @dev Reward distribution/accumulation is also only possible below target TWAP.
    function deposit(uint256 _amountIn) external nonReentrant {
        // First update reward amounts and last reward block
        updatePool();

        // Stash read
        address caller = _msgSender();

        // Pool has a blacklisting component if needed
        require(!_blackList[caller], "Can not deposit");
        require(_amountIn > 0, "Can not deposit zero");
        require(depositsEnabled(), "Above deposit TWAP");

        UserInfo storage user = userInfo[caller];

        // Stash storage reads
        uint256 userAmountBeforeDeposit = user.totalDepositAmount;

        if (userAmountBeforeDeposit > 0) {
            // Handle rewards for current deposit amount
            _handleUserPendingRewards(caller, userAmountBeforeDeposit);
        }

        uint256 userAmountAfterDeposit = userAmountBeforeDeposit + _amountIn;
        // Update user infos
        user.totalDepositAmount = userAmountAfterDeposit;

        // Update reward debts for user deposit weight
        _updateUserRewardDebt(caller, userAmountAfterDeposit);

        // Update pools total amount
        totalDepositTokenAmount += _amountIn;

        // Pull tokens from caller to setup swap
        depositToken.safeTransferFrom(caller, address(this), _amountIn);

        // After pulling callers tokens, swap for peg support
        _swapDeposit(_amountIn);

        emit Deposit(caller, _amountIn);
    }

    /// @dev Update pools accumulated reward for each reward token
    function updatePool() public {
        if (totalDepositTokenAmount == 0) {
            lastRewardBlock = block.number;
            return;
        }

        // If above TWAP push reward block forward
        if (!depositsEnabled()) {
            lastRewardBlock = block.number;
            return;
        }

        // Limit repeated memory allocations inside of loops(gas)
        uint256 count = rewardTokens.length;
        uint256 totalDeposits = totalDepositTokenAmount;
        RewardToken memory token;

        for (uint256 i = 0; i < count; i = _increment(i)) {
            token = rewardTokens[i];
            poolAccForToken[token.tokenAddress] += getAccumulatedReward(
                token.rewardPerBlock,
                totalDeposits
            );
        }

        // After adding to pools amounts, set new block
        lastRewardBlock = block.number;
    }

    /// @dev Update a users reward debt for each reward token
    /// @dev Broken out to be reused as needed
    function _updateUserRewardDebt(address _user, uint256 _userDepositAmount) internal {
        // Gas read stash on length
        uint256 count = rewardTokens.length;
        for (uint256 i = 0; i < count; i = _increment(i)) {
            _updateDebtForToken(rewardTokens[i].tokenAddress, _user, _userDepositAmount);
        }
    }

    /// @dev Utility to allow individual token debt updates.
    /// @dev It is possible for reward compounds to not include all tokens.
    /// @dev So we may not be able to always iterate over all tokens.
    /// @dev This way a single funtion can be used as/where needed.
    function _updateDebtForToken(
        address _token,
        address _user,
        uint256 _userDepositAmount
    ) internal {
        userTokenDebt[_user][_token] = (_userDepositAmount * poolAccForToken[_token]) / PRECISION;
    }

    /// @dev Handles distributing any pending rewards to a user
    /// @dev Placed in single function to be reused for deposit, withdraw, etc.
    function _handleUserPendingRewards(address _user, uint256 _userDepositAmount) internal {
        // Stashes
        uint256 count = rewardTokens.length;
        uint256 userRewardForToken;
        address userAddress = _user;
        address tokenAddress;
        uint256 poolsAccAmountForToken;

        for (uint256 i = 0; i < count; i = _increment(i)) {
            tokenAddress = rewardTokens[i].tokenAddress;
            poolsAccAmountForToken = poolAccForToken[tokenAddress];

            userRewardForToken =
                ((_userDepositAmount * poolsAccAmountForToken) / PRECISION) -
                userTokenDebt[userAddress][tokenAddress];

            if (userRewardForToken > 0) {
                IERC20Upgradeable(tokenAddress).safeTransfer(userAddress, userRewardForToken);

                emit Harvest(userAddress, tokenAddress, userRewardForToken);
            }
        }
    }

    /// @dev Swaps half of deposit amount into peg token.
    /// @dev Uses amountOutMin of zero. Handle accounting accordingly if needed.
    function _swapDeposit(uint256 _depositAmount) internal {
        router.swapExactTokensForTokens(
            _depositAmount / 2,
            0,
            swapPath,
            address(this),
            block.timestamp
        );
    }

    /// @dev Allows a user to claim any pending rewards
    function claim() external nonReentrant {
        // Running updates before next calcs
        updatePool();

        // Stash read off msg.sender
        address caller = _msgSender();

        UserInfo storage user = userInfo[caller];

        // Read storage amount once here instead of repeating in loop
        uint256 userDepositAmount = user.totalDepositAmount;
        require(userDepositAmount > 0, "Nothing to claim");

        uint256 count = rewardTokens.length;
        uint256 rewardAmount;
        uint256 poolsAccAmountForToken;
        RewardToken memory token;

        for (uint256 i = 0; i < count; i = _increment(i)) {
            token = rewardTokens[i];
            poolsAccAmountForToken = poolAccForToken[token.tokenAddress];

            rewardAmount =
                ((user.totalDepositAmount * poolsAccAmountForToken) / PRECISION) -
                userTokenDebt[caller][token.tokenAddress];

            // nonReentrant but checks anyway. Update reward debt before transfer
            _updateDebtForToken(token.tokenAddress, caller, userDepositAmount);

            if (rewardAmount > 0) {
                IERC20Upgradeable(token.tokenAddress).safeTransfer(caller, rewardAmount);

                emit Harvest(caller, token.tokenAddress, rewardAmount);
            }
        }
    }

    /// @dev Compounds pending rewards into a larger deposit token amount for user.
    /// @dev Goes the long route of back to deposit token before swap into peg for simplicity.
    /// @dev Allows users to provide easier support for peg instead of manual process.
    function compound() external nonReentrant {
        // Update calcs first
        updatePool();

        require(depositsEnabled(), "Can not compound above peg");

        address caller = _msgSender();
        require(!_blackList[caller], "Can not deposit");

        // Get pending reward amounts
        // No checks for user deposit since process depends on having pending rewards
        // Pending rewards are flushed out at withdraw
        (address[] memory tokens, uint256[] memory amounts) = pendingRewards(caller);

        UserInfo storage user = userInfo[caller];

        // Stash current deposit amount to tally up new total based on swap amounts
        uint256 newUserTotalDeposit = user.totalDepositAmount;

        uint256 swapAmountIn;
        uint256 count = amounts.length;
        uint256 depositTokenOut;
        address token;
        address[] memory tokenSwapPath;

        for (uint256 i = 0; i < count; i = _increment(i)) {
            swapAmountIn = amounts[i];
            token = tokens[i];
            tokenSwapPath = rewardCompoundPaths[token];

            if (swapAmountIn > 0) {
                // Possible to not be able to compound all tokens
                // Lack of a swap path
                if (tokenSwapPath.length > 0) {
                    // Get resulting deposit token amount out from swap
                    depositTokenOut = _handleCompoundSwap(swapAmountIn, tokenSwapPath);

                    // Increment deposit amounts according to deposit token amount received
                    newUserTotalDeposit += depositTokenOut;
                    totalDepositTokenAmount += depositTokenOut;

                    // Swap half of the amount into peg token so contract amounts for withdraw LP's are updated
                    _swapDeposit(depositTokenOut);
                } else {
                    // Distribute reward so reward debt can be updated after compound process completes
                    // Relying on nonRentrant here to simplify needed accounting and updating debt after
                    // Could tally up tokens and do after
                    IERC20Upgradeable(token).safeTransfer(caller, swapAmountIn);
                }
            }
        }

        // Update totals after compounds complete
        // Saving some storage writes in the loop
        user.totalDepositAmount = newUserTotalDeposit;

        // Update reward debts for new deposit weight
        // pool was updated at start of compound process
        _updateUserRewardDebt(caller, newUserTotalDeposit);
    }

    /// @dev Uses a reward tokens compound swap path to sell into deposit token.
    /// @dev It is possible to set swap paths straight to peg token,
    /// @dev but this made management/accouting easier at the expense of maybe extra gas.
    function _handleCompoundSwap(uint256 _amountIn, address[] memory _path)
        internal
        returns (uint256)
    {
        uint256[] memory amountsOut = router.swapExactTokensForTokens(
            _amountIn,
            0,
            _path,
            address(this),
            block.timestamp
        );

        return amountsOut[amountsOut.length - 1];
    }

    /// @dev Allows a user to withdraw from the pool
    /// @dev Withdraw fees are taken as needed according to current TWAP
    function withdraw(uint256 _amountOut) external nonReentrant {
        updatePool();

        require(_amountOut > 0, "Can not withdraw zero");

        UserInfo storage user = userInfo[msg.sender];

        // Stashing storage reads
        uint256 userCurrentAmount = user.totalDepositAmount;
        require(userCurrentAmount >= _amountOut, "Withdraw is more than user deposits");

        // Relying on nonReentrant. Give any rewards due for current weight
        _handleUserPendingRewards(msg.sender, userCurrentAmount);

        // Get fee reductions if applicable
        (uint256 depositTokenToUser, uint256 feeAmount) = _getWithdrawAmounts(_amountOut);

        // feeAmount to wherever its going
        _handleWithdrawFeeDistribution(feeAmount);

        uint256 userNewAmount = userCurrentAmount - _amountOut;
        user.totalDepositAmount = userNewAmount;

        totalDepositTokenAmount -= _amountOut;

        // Update base on new deposit weight. Previous pending rewards were already handle
        _updateUserRewardDebt(msg.sender, userNewAmount);

        // Provide the LP tokens due to the user
        _addWithdrawLiquidity(depositTokenToUser);

        emit Withdraw(msg.sender, _amountOut);
    }

    function _handleWithdrawFeeDistribution(uint256 _amountDepositToken) internal {
        if (_amountDepositToken == 0) {
            return;
        }

        depositToken.safeTransfer(treasuryAddress, _amountDepositToken);
    }

    /// @dev Does the work of adding the LP tokens given to the user withdrawing
    /// @dev We know that AMES in token0 in the pair so this token order works without checks
    function _addWithdrawLiquidity(uint256 _depositTokenToUser) internal {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        // Need reserves for quote
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        uint256 depositTokenIn = _depositTokenToUser / 2;

        // Get the current equivalant amount of peg needed to add liquidity
        // deposit token in, peg out
        uint256 quotedAmesAmount = router.quote(depositTokenIn, reserve1, reserve0);

        // AMES is token0/A in current pair
        // Send LP tokens to the caller
        router.addLiquidity(
            pair.token0(),
            pair.token1(),
            quotedAmesAmount,
            depositTokenIn,
            0,
            0,
            msg.sender,
            block.timestamp
        );
    }

    /// @dev TWAP based withdraw fee. Fee is target twap - current twap, as a percentage
    function _getWithdrawAmounts(uint256 _withdrawAmount)
        internal
        view
        returns (uint256 depositTokenToUser, uint256 feeAmount)
    {
        // [.9 to .99 = 10%, .8 to .89 = 20%, etc.]
        uint256 twap = getUpdatedTWAP();

        // No fee at 1.0
        if (twap >= 1e18) {
            return (_withdrawAmount, 0);
        }

        uint256 count = withdrawFeeBrackets.length;
        // We know we are below TWAP now and into fees
        // So checking from top/highest down for correct bracket
        for (uint256 i = 0; i < count; i = _increment(i)) {
            uint256 bracketFee = withdrawFeeBrackets[i];
            if (twap >= bracketFee) {
                depositTokenToUser = (_withdrawAmount * bracketFee) / 1e18;
                feeAmount = _withdrawAmount - depositTokenToUser;
                break;
            }
        }
    }

    // =========================== ADMIN STATE TRANSITIONS ============================= //

    function updateToken(uint256 _tokenIndex, uint256 _rewardPerBlock) external onlyOwner {
        // Skipping checks here
        rewardTokens[_tokenIndex].rewardPerBlock = _rewardPerBlock;
    }

    function updateBlacklist(address _who, bool _is) external onlyOwner {
        _blackList[_who] = _is;
    }

    function setRewardCompoundPathForToken(address _token, address[] calldata _swapPath)
        external
        onlyOwner
    {
        // Going this route for simplified accounting for compounding, at the expense of gas
        require(
            _swapPath[_swapPath.length - 1] == address(depositToken),
            "Path output not deposit token"
        );

        IERC20Upgradeable(_token).safeApprove(address(router), type(uint256).max);
        rewardCompoundPaths[_token] = _swapPath;
    }

    /// @dev Deposit into the pools farm.
    /// @dev poolId = 0 used as check value assuming we are not the first farm ever
    function depositToPool(uint256 _poolId) external onlyOwner {
        require(poolId == 0, "Pool already set");

        poolId = _poolId;
        // Approve reward pool to pull tokens from this contract for the deposit
        IERC20Upgradeable(address(this)).safeApprove(address(rewardPool), type(uint256).max);

        // Deposit the one token we minted to be sole depositor in farm
        rewardPool.deposit(_poolId, 1 ether);
    }

    /// @dev Withdraws from farm
    function withdrawFromPool() external onlyOwner {
        // Amount check in case we decide to do something different later
        RewardPoolUserInfo memory info = rewardPool.userInfo(poolId, address(this));
        rewardPool.withdraw(poolId, info.amount);
    }

    /// @dev Harvest pending rewards and updates pools accumulated value for token.
    function harvestRewards() external onlyOwner {
        IERC20Upgradeable token = IERC20Upgradeable(ASHARE);
        uint256 balanceBefore = token.balanceOf(address(this));

        // This harvests in current master chef setup
        rewardPool.deposit(poolId, 0);

        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 currentRewardAmount = balanceAfter - balanceBefore;

        emit FarmHarvest(currentRewardAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "./Initializable.sol";

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IBoardroomTreasury {
    // oracle
    // function getUnitePrice() public view returns (uint256 kittyPrice) {
    //     try IOracle(kittyOracle).consult(kitty, 1e18) returns (uint144 price) {
    //         return uint256(price);
    //     } catch {
    //         revert("Treasury: failed to consult QUARTZ price from the oracle");
    //     }
    // }

    // function getUniteUpdatedPrice() public view returns (uint256 _kittyPrice) {
    //     try IOracle(kittyOracle).twap(kitty, 1e18) returns (uint144 price) {
    //         return uint256(price);
    //     } catch {
    //         revert("Treasury: failed to consult QUARTZ price from the oracle");
    //     }
    // }

    // Calls consult() on the oracle
    function getGrapePrice() external view returns (uint256);

    // Calls twap() on the oracle
    function getGrapeUpdatedPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapV2Router {
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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getReserves(
        address _factory,
        address tokenA,
        address tokenB
    ) external view returns (uint256 reserveA, uint256 reserveB);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function pairFor(
        address _factory,
        address tokenA,
        address tokenB
    ) external pure returns (address pair);

    function factory() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IVault {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;

    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./PegPoolState.sol";

/// @dev Contract to hold view related functions to keep things easy to manage
/// @dev Contracts are state -> view -> pool
contract PegPoolView is PegPoolState {
    function __PegPoolView__init() internal initializer {}

    /// @dev Deposits for the pool are only possible when we are BELOW TWAP of 1
    function depositsEnabled() public view returns (bool) {
        return getUpdatedTWAP() < 1e18;
    }

    /// @dev Uses the Boardroom oracle's consult() function
    function getTWAP() public view returns (uint256) {
        return twapSource.getGrapePrice();
    }

    /// @dev Uses the Boardroom oracle's twap() function
    function getUpdatedTWAP() public view returns (uint256) {
        return twapSource.getGrapeUpdatedPrice();
    }

    /// @dev Provides the full path used for the swap into the peg token
    function viewSwapPath() external view returns (address[] memory) {
        return swapPath;
    }

    /// @dev Provides UI with reward token info
    function getRewardTokens() external view returns (RewardToken[] memory tokens) {
        tokens = new RewardToken[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            tokens[i] = RewardToken({
                rewardPerBlock: rewardTokens[i].rewardPerBlock,
                tokenAddress: rewardTokens[i].tokenAddress
            });
        }
    }

    /// @dev Util to get the multiplier for reward calculations
    function getAccumulatedReward(uint256 _tokensRewardPerBlock, uint256 _totalDeposits)
        public
        view
        returns (uint256 tokenRewardAmount)
    {
        if (lastRewardBlock >= block.number) {
            return 0;
        }

        tokenRewardAmount =
            ((_tokensRewardPerBlock * (block.number - lastRewardBlock)) * PRECISION) /
            _totalDeposits;
    }

    /// @dev Get pending rewards for current reward tokens for `_user`
    function pendingRewards(address _user)
        public
        view
        returns (address[] memory tokenAddresses, uint256[] memory rewardAmounts)
    {
        tokenAddresses = new address[](rewardTokens.length);
        rewardAmounts = new uint256[](rewardTokens.length);

        UserInfo storage user = userInfo[_user];
        RewardToken memory token;
        uint256 count = rewardTokens.length;
        for (uint256 i = 0; i < count; i = _increment(i)) {
            token = rewardTokens[i];
            tokenAddresses[i] = token.tokenAddress;
            uint256 poolsAccAmount = poolAccForToken[token.tokenAddress];

            if (block.number > lastRewardBlock && totalDepositTokenAmount != 0) {
                uint256 poolsCurrentAmount = getAccumulatedReward(
                    token.rewardPerBlock,
                    totalDepositTokenAmount
                );

                poolsAccAmount += (poolsCurrentAmount * PRECISION) / totalDepositTokenAmount;
            }

            rewardAmounts[i] =
                ((user.totalDepositAmount * poolsAccAmount) / PRECISION) -
                userTokenDebt[_user][token.tokenAddress];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./@oz/ERC20Upgradeable.sol";

/// @dev Generic ERC20 to be used as the "LP token" deposited to farm
/// @dev This "pool" is itself also a pool/farm in the master chef
contract GrapePegToken is ERC20Upgradeable {
    function __AmesPegToken__init() internal initializer {
        // Base contracts require manual initialization with upgrade systems
        __ERC20_init("Grape Peg Token", "pGrape");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "./Initializable.sol";

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
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
pragma solidity 0.8.4;

import "./@oz/OwnableUpgradeable.sol";
import "./@oz/IERC20Upgradeable.sol";
import "./@oz/SafeERC20Upgradeable.sol";

import "./interfaces/IBoardroomTreasury.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IRewardPool.sol";

/// @dev Base contract to manage state items for child contract.
/// @dev Separating concerns between contracts for readability.
/// @dev Contracts are state -> view -> pool
contract PegPoolState is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Info for each reward token
    struct RewardToken {
        address tokenAddress;
        uint256 rewardPerBlock;
    }

    struct UserInfo {
        uint256 totalDepositAmount;
    }

    struct UserDeposit {
        uint256 id;
        uint256 amountCredited; // half for swap
    }

    // Running count of the amount of deposit token collected
    uint256 public totalDepositTokenAmount;

    // Last block number reward amounts were calculated
    // Used as the base for the amount to multiply the pools reward amounts by
    uint256 public lastRewardBlock;

    uint256 constant PRECISION = 1e18;

    // TWAP value use to check against withdraw fees
    uint256 public targetTWAP;

    // Pool id for this contracts token in the reward pool farms
    uint256 public poolId;

    // Token that can be used to deposit into pool
    IERC20Upgradeable public depositToken;

    address public constant AMES = 0x5541D83EFaD1f281571B343977648B75d95cdAC2;

    address public constant ASHARE = 0xC55036B5348CfB45a932481744645985010d3A44;

    // LP token address for deposit/peg token pair
    address public pairAddress;

    address public treasuryAddress;

    // The master chef
    IRewardPool public rewardPool;

    // Contract used to provide TWAP
    IBoardroomTreasury public twapSource;

    // Uni router
    IUniswapV2Router public router;

    // Tokens to distribute for rewards (only when below peg)
    RewardToken[] public rewardTokens;

    // Path used for swapping deposit token into peg token
    address[] public swapPath;

    // Indexed fee brackets aligned to TWAP ranges
    uint256[] public withdrawFeeBrackets;

    // Info for user deposits
    mapping(address => UserInfo) public userInfo;

    // token => accumulated amount
    // We can provide any number of reward tokens with different reward rates
    // So all accumulated amounts are tracked individually
    mapping(address => uint256) public poolAccForToken;

    mapping(address => bool) internal _blackList;

    mapping(address => address[]) public rewardCompoundPaths;

    // @note May be a better structure/design for this
    // But tokens have different reward weights can be added/removed
    // user => token => debt amount
    mapping(address => mapping(address => uint256)) public userTokenDebt;

    event Deposit(address who, uint256 amount);
    event Withdraw(address who, uint256 amount);
    event Harvest(address who, address token, uint256 amount);
    event UpdateRouter(address old, address newRouter);
    event FarmHarvest(uint256 amount);

    /**
     * Acts as the constructor
     * @dev `_rewardTokenAddresses` and `_rewardsPerBlock` indexes need to align
     */
    function __PegPoolState__init(
        address _depositToken,
        address[] memory _rewardTokenAddresses,
        uint256[] memory _rewardsPerBlock,
        address _boardroomTreasury,
        address[] memory _swapPath,
        address _router,
        address _rewardPool,
        address _pairAddress,
        address _treasury
    ) internal initializer {
        // save reads
        uint256 rewardTokenCount = _rewardTokenAddresses.length;

        require(_depositToken != address(0), "Deposit token not set");
        require(rewardTokenCount > 0, "Rewards not set");
        require(rewardTokenCount == _rewardsPerBlock.length, "Reward brackets not matching");
        require(_boardroomTreasury != address(0), "TWAP source not set");
        require(_swapPath.length >= 2, "Swap path too short");
        require(_router != address(0), "Router not set");
        require(_rewardPool != address(0), "Reward pool not set");
        require(_pairAddress != address(0), "Pair not set");
        require(_treasury != address(0), "Treasury not set");

        // Base contracts must be manually initialized
        __Ownable_init();

        depositToken = IERC20Upgradeable(_depositToken);
        twapSource = IBoardroomTreasury(_boardroomTreasury);

        swapPath = _swapPath;
        router = IUniswapV2Router(_router);
        rewardPool = IRewardPool(_rewardPool);

        RewardToken memory token;
        for (uint256 i = 0; i < rewardTokenCount; i = _increment(i)) {
            token = RewardToken({
                tokenAddress: _rewardTokenAddresses[i],
                rewardPerBlock: _rewardsPerBlock[i]
            });
            rewardTokens.push(token);
        }

        lastRewardBlock = block.number;

        targetTWAP = 10 * 1e18;

        pairAddress = _pairAddress;
        treasuryAddress = _treasury;

        // Withdraw fees scale with current TWAP
        withdrawFeeBrackets = [
            9 * 1e17,
            8 * 1e17,
            7 * 1e17,
            6 * 1e17,
            5 * 1e17,
            4 * 1e17,
            3 * 1e17,
            2 * 1e17,
            1 * 1e17
        ];
    }

    // ============================== ADMIN STATE TRANSITIONS ================================= //

    /// @dev Update the path used to swap deposit token into peg token
    function setSwapPath(address[] calldata _path) external onlyOwner {
        require(_path.length >= 2, "Swap path too short");

        swapPath = _path;
    }

    /// @dev Update the router used if needed
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "Router not set");

        address oldRouter = address(router);
        router = IUniswapV2Router(_router);

        emit UpdateRouter(oldRouter, _router);
    }

    /// @dev Update the target TWAP value used to determine deposits opened/closed
    function setTargetTWAP(uint256 _price) external onlyOwner {
        targetTWAP = _price;
    }

    /// @dev Update chef contract and pool id if needed
    function setRewardPoolInfo(IRewardPool _rewardPool, uint256 _poold) external onlyOwner {
        require(address(_rewardPool) != address(0), "Reward pool not set");

        rewardPool = _rewardPool;
        poolId = _poold;
    }

    /// @dev Update pair address to allow for DEX migration
    function setPairAddress(address _pair) external onlyOwner {
        require(_pair != address(0), "Pair not set");

        pairAddress = _pair;
        depositToken.safeApprove(pairAddress, type(uint256).max);
    }

    /// @dev Add a new reward token. Check for token already added is skipped
    function addRewardToken(address _token, uint256 _rewardPerBlock) external onlyOwner {
        require(_token != address(0), "Token address not set");
        // @note Not checking if token is already added
        rewardTokens.push(RewardToken({tokenAddress: _token, rewardPerBlock: _rewardPerBlock}));
    }

    function setTreasuryFeeReceiver(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Treasury not set");

        treasuryAddress = _treasury;
    }

    // ================================ UTILS =================================== //

    /// @dev Tiny gas saver for loop iterations since we're using loops all around
    function _increment(uint256 i) internal pure returns (uint256) {
        unchecked {
            i = i + 1;
            return i;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

struct RewardPoolUserInfo {
    uint256 amount;
    uint256 rewardDebt;
}

interface IRewardPool {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _poolId, address _user) external returns (RewardPoolUserInfo memory);

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";

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
contract ERC20Upgradeable is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable
{
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
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

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