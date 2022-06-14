/**
 *Submitted for verification at snowtrace.io on 2022-06-14
*/

// File: interfaces/IExchangeBridge.sol



pragma solidity 0.7.5;

interface IExchangeBridge {
    function exchangeExactTokensForTokens(uint256 amount, address sourceToken, address targetToken) external;
    function exchangeExactTokensForAVAX(uint256 amount, address sourceToken) external;
}

// File: contracts/prize/AAVELending/AAVEInterfaces.sol



pragma solidity 0.7.5;

interface AAVELendingPool {
    // balance is erc20
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

interface AAVERewards {
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external returns (uint256);
}


// File: contracts/prize/AAVELending/AAVELendingBridge.sol



/* *********************************
 * Owned and operated by defiprizes.com
 * ********************************* */

pragma solidity 0.7.5;


contract AAVELendingBridge {

    // must be called with delegated call
    function deposit(address lendingPool, address aaveAsset, uint256 amount) external {
        AAVELendingPool(lendingPool).supply(aaveAsset, amount, address(this), uint16(0));
    }

    function withdraw(address lendingPool, address aaveAsset, uint256 amount) external { 
        AAVELendingPool(lendingPool).withdraw(aaveAsset, amount, address(this));
    }
}
// File: contracts/extensions/Reentrancy.sol


// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity 0.7.5;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}
// File: contracts/extensions/AccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity 0.7.5;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl {
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct RoleData {
        mapping(address => bool) members;
    }

    mapping(bytes32 => RoleData) private _roles;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string("access denied")
                //     abi.encodePacked(
                //         "AccessControl: account ",
                //         Strings.toHexString(uint160(account), 20),
                //         " is missing role ",
                //         Strings.toHexString(uint256(role), 32)
                //     )
                // )
            );
        }
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(ADMIN_ROLE)  {
        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
        }
    }
}

// File: contracts/extensions/Pausable.sol



pragma solidity 0.7.5;


abstract contract Pausable is AccessControl {

    uint256 public paused = 0;

    function isPaused() internal view returns (bool) {
        return paused == 1;
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        paused = 1;
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        paused = 0;
    }
}
// File: interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity 0.7.5;

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

    function permit(address owner, address spender, uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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
    function mint(address account, uint rawAmount) external;
    function burn(address account, uint rawAmount) external;
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

// File: libraries/math/LowGasSafeMath.sol



pragma solidity 0.7.5;

library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "add uint256 overflow");
    }

    function add32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x + y) >= x, "add32 uint32 overflow");
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub uint256 overflow");
    }

    function sub32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x - y) <= x, "sub32 uint32 overflow");
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y, "mul uint256 overflow");
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0), "add int256 overflow");
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0), "sub int256 overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "division by 0");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
// File: contracts/prize/AAVELending/AAVERewardsBridge.sol



/* *********************************
 * Owned and operated by defiprizes.com
 * ********************************* */

pragma solidity 0.7.5;






contract AAVERewardsBridge is ReentrancyGuard {
    using LowGasSafeMath for uint256;

        IExchangeBridge private exchangeBridge = IExchangeBridge(0x2498d70E4a2ED018EEB092101A24827fdfCE7C13);
        AAVERewards private rewardsDistributor = AAVERewards(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
        IERC20 private wavax = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    //must be called with delegated call
    function claimRewardsInTargetToken(address aaveAsset, address targetToken) external nonReentrant returns (uint256) {

        uint256 balanceBefore = wavax.balanceOf(address(this));
        // atokens list
        address[] memory assets;
        assets[0] = aaveAsset;
        rewardsDistributor.claimRewards(assets, uint256(-1), address(this), address(wavax));
        uint256 balanceAfter = wavax.balanceOf(address(this));
        uint256 balanceTotalToConvert = balanceAfter.sub(balanceBefore);

        // very small amounts cause output errors from joe router
        if (balanceTotalToConvert < 1) {
            return 0;
        }

        wavax.transfer(address(exchangeBridge), balanceTotalToConvert);
        IERC20 targetTokenERC20 = IERC20(targetToken);
        uint256 targetTokenBalanceBefore = targetTokenERC20.balanceOf(address(this));
        exchangeBridge.exchangeExactTokensForTokens(balanceTotalToConvert, address(wavax), targetToken);
        uint256 targetTokenBalanceAfter = targetTokenERC20.balanceOf(address(this));

        return targetTokenBalanceAfter.sub(targetTokenBalanceBefore);
    }
}
// File: contracts/extensions/Referrals.sol



/* *********************************
 * Owned and operated by defiprizes.com
 * ********************************* */

pragma solidity 0.7.5;



// --------- Terminology --------
// referrer is the one who posted a link and enticed the referee to make a deposit. The referrer gets the referral reward
// referee is the person who got referred
// Notes
// referrers only get entered into the referal rewards pool when their referee qualifies. 
// They only get a share of the pool if the referee keeps their tokens in the contract for the following draw.
abstract contract Referrals is AccessControl {
    using LowGasSafeMath for uint256;

    event AllocateReferralRewardPool(uint256 indexed drawNumber, uint256 amount);
    struct ReferralRewardPool {
        uint256 rewardTokens;
        uint256 totalReferred;
    }
    struct RefereeReferrersBalances {
        address referrer;
        uint256 referredAmount;
    }
    mapping(uint256 => ReferralRewardPool) internal drawReferralRewardPools;
    mapping(address => mapping(uint256 => uint256)) private referrerBalances; // referrer => (drawNumber => balance)
    mapping(address => mapping(uint256 => RefereeReferrersBalances)) private refereeReferrers; // referee => (drawNumber => RefereeReferrersBalances)
    mapping(address => uint256[]) private referrerDraws; // referrer => [drawNumber] -- used for claiming rewards
    uint256 public referralsEnabled = 1;

    event ClaimReferralReward(address indexed account, uint256 amount, uint256[] draws, uint256 excluded);

    function setReferralsEnabled(uint256 value) external onlyRole(ADMIN_ROLE) {
        referralsEnabled = value;
    }

    function _referralRewardBalanceOf(address account, uint256 excludeDraw) internal view returns(uint256) {
        uint256 balance = 0;
        for (uint256 i; i < referrerDraws[account].length; i++) {
            if (referrerDraws[account][i] >= excludeDraw) {
                break;
            }
            (, uint256 referralPrize) = _calcReferralReward(account, referrerDraws[account][i]);
            balance = balance.add(referralPrize);
        }
        return balance;
    }

    function referralRewardForDrawBalanceOf(address account, uint256 drawNumber) external view returns(uint256) {
        (, uint256 referralPrize) = _calcReferralReward(account, drawNumber);
        return referralPrize;
    }

    function referralRewardedDrawsOf(address account) external view returns(uint256[] memory) {
        return referrerDraws[account];
    }

    function _referrerBalanceOf(address account, uint256 drawNumber) internal view returns (uint256) {
        return referrerBalances[account][drawNumber];
    }

    function _claimReferralReward(address account, uint256 excludeDrawNumber) internal returns(uint256) {
        uint256 rewardBalance = _referralRewardBalanceOf(account, excludeDrawNumber);
        emit ClaimReferralReward(account, rewardBalance, referrerDraws[account], excludeDrawNumber);
        delete referrerDraws[account];
        referrerDraws[account].push(excludeDrawNumber);
        return rewardBalance;
    }

    function _addReferralBalance(address referrer, address referee, uint256 balance, uint256 drawNumber) internal {
        if (referrer == address(0)) return;
        if (referralsEnabled == 0) return;
        drawReferralRewardPools[drawNumber].totalReferred = drawReferralRewardPools[drawNumber].totalReferred.add(balance);
        referrerBalances[referrer][drawNumber] = referrerBalances[referrer][drawNumber].add(balance);
        refereeReferrers[referee][drawNumber].referrer = referrer;
        refereeReferrers[referee][drawNumber].referredAmount = refereeReferrers[referee][drawNumber].referredAmount.add(balance);
        if (referrerDraws[referrer].length > 0) {
            if (referrerDraws[referrer][referrerDraws[referrer].length - 1] != drawNumber) {
                referrerDraws[referrer].push(drawNumber);
            }
        } else {
            referrerDraws[referrer].push(drawNumber);
        }
    }

    function _removeReferralBalance(address referee, uint256 amount, uint256 drawNumber) internal {    
        if (refereeReferrers[referee][drawNumber].referrer == address(0)) return; // no one has referred them
        if (referralsEnabled == 0) return;

        // remove from referrerBalances
        address referrerAccount = refereeReferrers[referee][drawNumber].referrer;
        uint256 referrerBalance = refereeReferrers[referee][drawNumber].referredAmount;

        // amount should be limited to referrerBalance
        uint256 referralAmount = amount;
        if (referralAmount > referrerBalance) {
            referralAmount = referrerBalance;
        }

        referrerBalances[referrerAccount][drawNumber] = referrerBalances[referrerAccount][drawNumber].sub(referralAmount);
        refereeReferrers[referee][drawNumber].referredAmount = refereeReferrers[referee][drawNumber].referredAmount.sub(referralAmount);
        drawReferralRewardPools[drawNumber].totalReferred = drawReferralRewardPools[drawNumber].totalReferred.sub(referralAmount);

        if (amount >= referrerBalance) {
            refereeReferrers[referee][drawNumber].referrer = address(0);
        }

        return;
    }

    function _calcReferralReward(address account, uint256 drawNumber) internal view returns(uint256, uint256) {
        uint256 accountReferredBalance = referrerBalances[account][drawNumber];
        if (accountReferredBalance == 0) return (0, 0);
        ReferralRewardPool storage drawReferralRewardPool = drawReferralRewardPools[drawNumber];
        if (drawReferralRewardPool.totalReferred == 0) return (0, 0);
        uint256 poolSharePercent = (accountReferredBalance.mul(10000)).div(drawReferralRewardPool.totalReferred); // 2dp
        uint256 referralPrize = (drawReferralRewardPool.rewardTokens.div(10000)).mul(poolSharePercent);
        return (poolSharePercent, referralPrize);
    }
}
// File: contracts/extensions/Prizes.sol



/* *********************************
 * Owned and operated by defiprizes.com
 * ********************************* */

pragma solidity 0.7.5;




abstract contract Prizes is AccessControl {
    using LowGasSafeMath for uint256;

    event AllocatePrize(address indexed account, uint256 amount);
    uint256 public protocolCut = 10;
    address public protocolWallet = msg.sender;
    uint256[3] public prizeCuts = [65, 25, 10];
    uint256 public prizeBoost = 0;

    function _boostPrize(uint256 amount) internal {
        prizeBoost = prizeBoost.add(amount);
    }

    function calculatePrizes(uint256 total) public view returns (uint256[4] memory, uint256) {
        uint256[4] memory results;
        if (total == 0) {
            results[0] = 0;
            results[1] = 0;
            results[2] = 0;
            results[3] = 0;
            return (results, 0);
        }

        uint256 preCalc = total.div(100);
        uint256 protocolAmount = preCalc.mul(protocolCut);

        results[0] = preCalc.mul(100 - protocolCut); // total prizepool to be allocated

        uint256 prizePreCalc = results[0].div(100);
        results[1] = prizePreCalc.mul(prizeCuts[0]); // gold
        results[2] = prizePreCalc.mul(prizeCuts[1]).div(5); // silver
        results[3] = prizePreCalc.mul(prizeCuts[2]); // referrals

        // add all together for the total (this circumvents rounding errors)
        results[0] = results[1].add(results[2].mul(5)).add(results[3]);

        return (results, protocolAmount);
    }

    function setPrizeCuts(uint256[3] calldata cuts) external onlyRole(ADMIN_ROLE) {
        require(cuts[0].add(cuts[1]).add(cuts[2]) == 100, "Cuts must add up to 100");
        prizeCuts[0] = cuts[0]; // gold
        prizeCuts[1] = cuts[1]; // silver
        prizeCuts[2] = cuts[2]; // referral
    }

    function setProtocolWallet(address _protocolWallet) external onlyRole(ADMIN_ROLE) {
        protocolWallet = _protocolWallet;
    }

    function setProtocolCut(uint256 cut, uint256 pool) external onlyRole(ADMIN_ROLE) {
        require(cut.add(pool) == 100, "cut + pool must = 100");
        protocolCut = cut;
    }
}
// File: contracts/extensions/Draws.sol



/* *********************************
 * Owned and operated by defiprizes.com
 * ********************************* */

pragma solidity 0.7.5;




abstract contract Draws is AccessControl, Prizes, Referrals {
    using LowGasSafeMath for uint256;

    uint256 public constant UINT256_MAX = uint256(-1);
    
    struct QualifiedBalance {
        uint256 qualifiedAddressesIndex;
        uint256 balance;
    }
    struct WarmupBalance {
        uint256 validFromDraw;
        uint256 balance;
        address referrer;
    }

    address[] public qualifiedAddresses = [address(0)];
    uint256 public nextDrawNumber = 1;
    uint256 public totalStakedBalance = 0;
    uint256 public totalWarmupBalance = 0;
    uint256 public totalQualifiedBalance = 0;
    mapping(address => QualifiedBalance) private qualifiedBalances;
    mapping(address => WarmupBalance) private warmupBalances;
    uint256 public marketCap = UINT256_MAX;
    uint256 public capPerWallet = UINT256_MAX;

    event Deposit(address indexed account, uint256 amount);
    event Qualify(address indexed account, uint256 amount);
    event CancelWarmup(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    // if non-indexed fields are added, draw.go will need to be updated to unmarshal correctly
    event Draw(uint256 indexed drawNumber, uint256 drawFundSize);

    function setMarketCap(uint256 _marketCap) external onlyRole(ADMIN_ROLE) {
        marketCap = _marketCap;
    }

    function setCapPerWallet(uint256 cap) external onlyRole(ADMIN_ROLE) {
        capPerWallet = cap;
    }

    function getTotalQualifiedAddresses() external view returns (uint256) {
        return qualifiedAddresses.length - 1;
    }

    function getQualifiedAddressAt(uint256 index) external view returns (address) {
        return qualifiedAddresses[index];
    }

    function getQualifiedAddresses() external view returns (address[] memory) {
        return qualifiedAddresses;
    }

    function getBulkQualifiedAddresses(uint256 count, uint256 index) external view returns (address[] memory, uint256) {
        address[] memory results = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            results[i] = qualifiedAddresses[index + i];
        }
        return (results, index + count);
    }

    function getWarmupBalanceOf(address account) public view returns (uint256) {
        return warmupBalances[account].balance;
    }

    function getQualifiedBalanceOf(address account) external view returns (uint256) {
        return qualifiedBalances[account].balance;
    }

    function getBulkQualifiedBalanceOf(address[] calldata accounts) external view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](accounts.length);
        for (uint i = 0; i < accounts.length; i++) {
            results[i] = qualifiedBalances[accounts[i]].balance;
        }
        return results;
    }

    function _deposit(address account, uint256 amount, address referrer) internal {
        require(totalStakedBalance.add(amount) <= marketCap, "Draw Cap Reached");
        require(amount > 0, "Amount must be greater than 0");
    
        warmupBalances[account].balance = warmupBalances[account].balance.add(amount);
        warmupBalances[account].validFromDraw = nextDrawNumber + 1;
        // first referrer takes presedence!
        if (warmupBalances[account].referrer == address(0)) {
            warmupBalances[account].referrer = referrer;
        }

        uint256 totalWalletSize = qualifiedBalances[account].balance + warmupBalances[account].balance;
        require(totalWalletSize <= capPerWallet, "Wallet Cap Reached");

        // transfer tokens from user wallet into contract wallet
        totalStakedBalance = totalStakedBalance.add(amount);
        totalWarmupBalance = totalWarmupBalance.add(amount);
        emit Deposit(account, amount);
    }

    function _cancelWarmup(address account) internal {
        uint256 amount = warmupBalances[account].balance;
        require(amount > 0, "No Warmup Balance");
        totalStakedBalance = totalStakedBalance.sub(amount);
        totalWarmupBalance = totalWarmupBalance.sub(amount);
        warmupBalances[account].balance = 0;
        warmupBalances[account].validFromDraw = 0;
        warmupBalances[account].referrer = address(0);
        emit CancelWarmup(account, amount);
    }

    // after warmup, users have to qualify the balance for the draw
    function _qualify(address account) internal {
        uint256 amount = warmupBalances[account].balance;
        uint256 validFromDraw = warmupBalances[account].validFromDraw;
        require(amount > 0, "No Warmup Balance");
        require(validFromDraw <= nextDrawNumber, "Warmup Balance not valid for this draw");

        // add to qualified wallet list and handle referrals
        _addQualifyingBalance(account, amount);
        _addReferralBalance(warmupBalances[account].referrer, account, amount, nextDrawNumber);
        warmupBalances[account].referrer = address(0);
        warmupBalances[account].balance = 0;
        warmupBalances[account].validFromDraw = 0;

        totalQualifiedBalance = totalQualifiedBalance.add(amount);
        totalWarmupBalance = totalWarmupBalance.sub(amount);
        emit Qualify(account, amount);
    }

    // ensure when a qualifying balance is added to, they're also added to the qialifying list
    function _addQualifyingBalance(address account, uint256 amount) private {
        if (qualifiedBalances[account].balance == 0) {
            qualifiedAddresses.push(account);
            qualifiedBalances[account].qualifiedAddressesIndex = qualifiedAddresses.length - 1;
        }
        qualifiedBalances[account].balance = qualifiedBalances[account].balance.add(amount);
    }

    // withdraw prize tickets
    function _withdraw(address account, uint256 amount) internal {
        uint256 accountBalance = qualifiedBalances[account].balance;
        require(accountBalance >= amount, "Invalid withdraw amount");
        
        uint256 newBalance = accountBalance.sub(amount);

        if (newBalance == 0 && qualifiedBalances[account].qualifiedAddressesIndex != 0) {
            qualifiedAddresses[qualifiedBalances[account].qualifiedAddressesIndex] = qualifiedAddresses[qualifiedAddresses.length - 1];
            qualifiedAddresses.pop();
            qualifiedBalances[account].qualifiedAddressesIndex = 0;
        }

        _removeReferralBalance(account, amount, nextDrawNumber);

        totalQualifiedBalance = totalQualifiedBalance.sub(amount);
        qualifiedBalances[account].balance = newBalance;
        totalStakedBalance = totalStakedBalance.sub(amount);
        emit Withdraw(account, amount);
    }

    // run draw
    function _runDraw(uint256 total, uint256 drawNumber, address[] memory winners) internal returns(uint256) {
        require(winners.length == 6, "Must select 6 winners"); // 1 for major, 5 for minor
        require(drawNumber == nextDrawNumber, "Only one call per draw");
        nextDrawNumber++;

        if (total == 0) {
            emit Draw(drawNumber, 0);
            return 0;
        }

        (uint256[4] memory calculatedPrizes, uint256 protocolAmount) = calculatePrizes(total);
        uint256 totalPrizePool = calculatedPrizes[0].add(protocolAmount);

        // allocate prizes
        _addQualifyingBalance(winners[0], calculatedPrizes[1]);
        _addQualifyingBalance(winners[1], calculatedPrizes[2]);
        _addQualifyingBalance(winners[2], calculatedPrizes[2]);
        _addQualifyingBalance(winners[3], calculatedPrizes[2]);
        _addQualifyingBalance(winners[4], calculatedPrizes[2]);
        _addQualifyingBalance(winners[5], calculatedPrizes[2]);
        emit AllocatePrize(winners[0], calculatedPrizes[1]);
        emit AllocatePrize(winners[1], calculatedPrizes[2]);
        emit AllocatePrize(winners[2], calculatedPrizes[2]);
        emit AllocatePrize(winners[3], calculatedPrizes[2]);
        emit AllocatePrize(winners[4], calculatedPrizes[2]);
        emit AllocatePrize(winners[5], calculatedPrizes[2]);

        warmupBalances[protocolWallet].balance = warmupBalances[protocolWallet].balance.add(protocolAmount);
        totalWarmupBalance = totalWarmupBalance.add(protocolAmount);
        emit AllocatePrize(protocolWallet, protocolAmount);

        // if nothing was referred, allocate reward pool to the protocol
        if (drawReferralRewardPools[drawNumber].totalReferred != 0) {
            drawReferralRewardPools[drawNumber].rewardTokens = calculatedPrizes[3];
            emit AllocateReferralRewardPool(drawNumber, calculatedPrizes[3]);
        } else {
            warmupBalances[protocolWallet].balance = warmupBalances[protocolWallet].balance.add(calculatedPrizes[3]);
            totalWarmupBalance = totalWarmupBalance.add(calculatedPrizes[3]);
            emit AllocatePrize(protocolWallet, calculatedPrizes[3]);
        }

        // total is now distributed to staked wallets
        totalStakedBalance = totalStakedBalance.add(totalPrizePool);
        totalQualifiedBalance = totalQualifiedBalance.add(calculatedPrizes[0]).sub(calculatedPrizes[3]);
        emit Draw(drawNumber, total);
        return total;
    }
}
// File: contracts/prize/AAVELending/AAVELending.sol



/* *********************************
 * Owned and operated by defiprizes.com
 * ********************************* */

pragma solidity 0.7.5;








contract AAVELending is Draws, ReentrancyGuard, Pausable {
    using LowGasSafeMath for uint256;

    IERC20 public depositToken;
    AAVELendingBridge public lendingBridge;
    address public aaveLendingPool;
    AAVERewardsBridge public rewardsBridge;
    uint256 public emergencyDisableRewards;
    IERC20 public aaveAsset;

    string public contractInterfaceVersion = "3.1";

    constructor(
        address _depositToken,
        address _lendingBridgeContract,
        address _aaveLendingPoolContract,
        address _rewardsBridgeContract,
        address _aaveAsset
    ) {
        _setupRole(ADMIN_ROLE, msg.sender);
        depositToken = IERC20(_depositToken);
        lendingBridge = AAVELendingBridge(_lendingBridgeContract);
        rewardsBridge = AAVERewardsBridge(_rewardsBridgeContract);
        aaveLendingPool = _aaveLendingPoolContract;
        aaveAsset = IERC20(_aaveAsset);
        depositToken.approve(aaveLendingPool, UINT256_MAX);
    }

    function reapprove() external onlyRole(ADMIN_ROLE) {
        depositToken.approve(address(aaveLendingPool), UINT256_MAX);
    }

    function boostPrize(uint256 amount) external onlyRole(ADMIN_ROLE) {
        depositToken.transferFrom(msg.sender, address(this), amount);
        _boostPrize(amount);
    }

    function setEmergencyDisableRewards(uint256 value) external onlyRole(ADMIN_ROLE) {
        emergencyDisableRewards = value;
    }

    function setrewardsBridge(address _rewardsBridgeContract) external onlyRole(ADMIN_ROLE) {
        rewardsBridge = AAVERewardsBridge(_rewardsBridgeContract);
    }

    function setLendingBridge(address _lendingBridgeContract) external onlyRole(ADMIN_ROLE) {
        lendingBridge = AAVELendingBridge(_lendingBridgeContract);
    }

    function setLendingPool(address _aaveLendingPoolContract) external onlyRole(ADMIN_ROLE) {
        aaveLendingPool = _aaveLendingPoolContract;
    }

    function setDepositToken(address _depositToken) external onlyRole(ADMIN_ROLE) {
        depositToken = IERC20(_depositToken);
    }

    function deposit(uint256 amount, address referrer) external {
        require(isPaused() == false, "Deposits Paused");
        _deposit(msg.sender, amount, referrer);
        depositToken.transferFrom(msg.sender, address(this), amount);
        depositToLending(amount);
    }

    function depositWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s, address referrer) nonReentrant external {
        require(isPaused() == false, "Deposits Paused");
        depositToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
        _deposit(msg.sender, amount, referrer);
        depositToken.transferFrom(msg.sender, address(this), amount);
        depositToLending(amount);
    }

    function cancelWarmup() nonReentrant external {
        uint256 amount = getWarmupBalanceOf(msg.sender);
        _cancelWarmup(msg.sender);
        withdrawFromLending(amount);
        depositToken.transfer(msg.sender, amount);
    }

    function qualify() external {
        _qualify(msg.sender);
    }

    function withdraw(uint256 amount) nonReentrant external  {
        _withdraw(msg.sender, amount);
        withdrawFromLending(amount);
        depositToken.transfer(msg.sender, amount);
    }

    function draw(uint256 drawNumber, address[] calldata winners) external nonReentrant onlyRole(ADMIN_ROLE) returns (uint256) {
        uint256 lendingBalance = aaveAsset.balanceOf(address(this));
        uint256 totalPrizeFund = lendingBalance.sub(totalStakedBalance);

        if (prizeBoost > 0) {
            // we have to add prizeboosts to the stakingcontract as prizes are reinvested
            depositToLending(prizeBoost);
            totalPrizeFund = totalPrizeFund.add(prizeBoost);
            prizeBoost = 0;
        }

        if (emergencyDisableRewards == 0) {
            (bool success, bytes memory returndata) = address(rewardsBridge).delegatecall(abi.encodeWithSignature("claimRewardsInTargetToken(address,address)", address(aaveAsset), address(depositToken)));
            if (success == false) {
                if (returndata.length == 0) revert();
                assembly {
                    revert(add(32, returndata), mload(returndata))
                }
            }
            // require(success, "Failed to claim rewards");
            uint256 rewards = abi.decode(returndata, (uint256));
            totalPrizeFund = totalPrizeFund.add(rewards); 
            depositToLending(rewards);
        }
        
        return _runDraw(totalPrizeFund, drawNumber, winners);
    }

    function getReferralRewardFigures(uint256 drawNumber, address account) external view returns (uint256, uint256, uint256) {
        (uint256 poolSharePercent, ) = _calcReferralReward(account, drawNumber);
        uint256 referrerBalance = _referrerBalanceOf(account, drawNumber);
        uint256 totalReferredCurrentDraw = drawReferralRewardPools[nextDrawNumber].totalReferred;
        return (poolSharePercent, referrerBalance, totalReferredCurrentDraw);
    }

    function claimReferralReward() nonReentrant external {
        uint256 amount = _claimReferralReward(msg.sender, nextDrawNumber);
        withdrawFromLending(amount);
        totalStakedBalance = totalStakedBalance.sub(amount);
        depositToken.transfer(msg.sender, amount);
    }

    function referralRewardBalanceOf(address account) external view returns (uint256) {
        return _referralRewardBalanceOf(account, nextDrawNumber);
    }

    function depositToLending(uint256 amount) private {
        (bool success, bytes memory returndata) = address(lendingBridge).delegatecall(abi.encodeWithSignature("deposit(address,address,uint256)", aaveLendingPool, address(aaveAsset), amount));
        if (success == false) {
            if (returndata.length == 0) revert("failed depositToLending");
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
        }
    }

    function withdrawFromLending(uint256 amount) private {
        (bool success, bytes memory returndata) = address(lendingBridge).delegatecall(abi.encodeWithSignature("withdraw(address,address,uint256)", aaveLendingPool, address(aaveAsset), amount));
        if (success == false) {
            if (returndata.length == 0) revert("failed withdrawFromLending");
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
        }
    }
}