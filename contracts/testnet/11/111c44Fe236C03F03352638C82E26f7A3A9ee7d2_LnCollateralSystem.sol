// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/ILnBuildBurnSystem.sol";
import "./interfaces/ILnConfig.sol";
import "./interfaces/ILnDebtSystem.sol";
import "./interfaces/ILnPrices.sol";
import "./interfaces/ILnRewardLocker.sol";
import "./upgradeable/LnAdminUpgradeable.sol";
import "./utilities/TransferHelper.sol";
import "./LnAddressCache.sol";
import "./SafeDecimalMath.sol";

// 单纯抵押进来
// 赎回时需要 债务率良好才能赎回， 赎回部分能保持债务率高于目标债务率
contract LnCollateralSystem is LnAdminUpgradeable, PausableUpgradeable, LnAddressCache {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using AddressUpgradeable for address;

    // -------------------------------------------------------
    // need set before system running value.
    ILnPrices public priceGetter;
    ILnDebtSystem public debtSystem;
    ILnConfig public mConfig;
    ILnRewardLocker public mRewardLocker;

    bytes32 public constant Currency_ETH = "ETH";
    bytes32 public constant Currency_LINA = "LINA";

    // -------------------------------------------------------
    uint256 public uniqueId; // use log

    struct TokenInfo {
        address tokenAddr;
        uint256 minCollateral; // min collateral amount.
        uint256 totalCollateral;
        bool bClose; // TODO : 为了防止价格波动，另外再加个折扣价?
    }

    mapping(bytes32 => TokenInfo) public tokenInfos;
    bytes32[] public tokenSymbol; // keys of tokenInfos, use to iteration

    struct CollateralData {
        uint256 collateral; // total collateral
    }

    // [user] => ([token=> collateraldata])
    mapping(address => mapping(bytes32 => CollateralData)) public userCollateralData;

    // State variables added by upgrades
    ILnBuildBurnSystem public buildBurnSystem;
    address public liquidation;

    bytes32 private constant BUILD_RATIO_KEY = "BuildRatio";

    modifier onlyLiquidation() {
        require(msg.sender == liquidation, "LnCollateralSystem: not liquidation");
        _;
    }

    modifier onlyRewardLocker() {
        require(msg.sender == address(mRewardLocker), "LnCollateralSystem: not reward locker");
        _;
    }

    /**
     * @notice This function is deprecated as it doesn't do what its name suggests. Use
     * `getFreeCollateralInUsd()` instead. This function is not removed since it's still
     * used by `LnBuildBurnSystem`.
     */
    function MaxRedeemableInUsd(address _user) public view returns (uint256) {
        return getFreeCollateralInUsd(_user);
    }

    function getFreeCollateralInUsd(address user) public view returns (uint256) {
        uint256 totalCollateralInUsd = GetUserTotalCollateralInUsd(user);

        (uint256 debtBalance, ) = debtSystem.GetUserDebtBalanceInUsd(user);
        if (debtBalance == 0) {
            return totalCollateralInUsd;
        }

        uint256 buildRatio = mConfig.getUint(BUILD_RATIO_KEY);
        uint256 minCollateral = debtBalance.divideDecimal(buildRatio);
        if (totalCollateralInUsd < minCollateral) {
            return 0;
        }

        return totalCollateralInUsd.sub(minCollateral);
    }

    function maxRedeemableLina(address user) public view returns (uint256) {
        (uint256 debtBalance, ) = debtSystem.GetUserDebtBalanceInUsd(user);
        uint256 stakedLinaAmount = userCollateralData[user][Currency_LINA].collateral;

        if (debtBalance == 0) {
            // User doesn't have debt. All staked collateral is withdrawable
            return stakedLinaAmount;
        } else {
            // User has debt. Must keep a certain amount
            uint256 buildRatio = mConfig.getUint(BUILD_RATIO_KEY);
            uint256 minCollateralUsd = debtBalance.divideDecimal(buildRatio);
            uint256 minCollateralLina = minCollateralUsd.divideDecimal(priceGetter.getPrice(Currency_LINA));
            uint256 lockedLinaAmount = mRewardLocker.balanceOf(user);

            return MathUpgradeable.min(stakedLinaAmount, stakedLinaAmount.add(lockedLinaAmount).sub(minCollateralLina));
        }
    }

    // -------------------------------------------------------
    function __LnCollateralSystem_init(address _admin) public initializer {
        __LnAdminUpgradeable_init(_admin);
    }

    function setPaused(bool _paused) external onlyAdmin {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    // ------------------ system config ----------------------
    function updateAddressCache(ILnAddressStorage _addressStorage) public override onlyAdmin {
        priceGetter = ILnPrices(_addressStorage.getAddressWithRequire("LnPrices", "LnPrices address not valid"));
        debtSystem = ILnDebtSystem(_addressStorage.getAddressWithRequire("LnDebtSystem", "LnDebtSystem address not valid"));
        mConfig = ILnConfig(_addressStorage.getAddressWithRequire("LnConfig", "LnConfig address not valid"));
        mRewardLocker = ILnRewardLocker(
            _addressStorage.getAddressWithRequire("LnRewardLocker", "LnRewardLocker address not valid")
        );
        buildBurnSystem = ILnBuildBurnSystem(
            _addressStorage.getAddressWithRequire("LnBuildBurnSystem", "LnBuildBurnSystem address not valid")
        );
        liquidation = _addressStorage.getAddressWithRequire("LnLiquidation", "LnLiquidation address not valid");

        emit CachedAddressUpdated("LnPrices", address(priceGetter));
        emit CachedAddressUpdated("LnDebtSystem", address(debtSystem));
        emit CachedAddressUpdated("LnConfig", address(mConfig));
        emit CachedAddressUpdated("LnRewardLocker", address(mRewardLocker));
        emit CachedAddressUpdated("LnBuildBurnSystem", address(buildBurnSystem));
        emit CachedAddressUpdated("LnLiquidation", liquidation);
    }

    function updateTokenInfo(
        bytes32 _currency,
        address _tokenAddr,
        uint256 _minCollateral,
        bool _close
    ) private returns (bool) {
        require(_currency[0] != 0, "symbol cannot empty");
        require(_currency != Currency_ETH, "ETH is used by system");
        require(_tokenAddr != address(0), "token address cannot zero");
        require(_tokenAddr.isContract(), "token address is not a contract");

        if (tokenInfos[_currency].tokenAddr == address(0)) {
            // new token
            tokenSymbol.push(_currency);
        }

        uint256 totalCollateral = tokenInfos[_currency].totalCollateral;
        tokenInfos[_currency] = TokenInfo({
            tokenAddr: _tokenAddr,
            minCollateral: _minCollateral,
            totalCollateral: totalCollateral,
            bClose: _close
        });
        emit UpdateTokenSetting(_currency, _tokenAddr, _minCollateral, _close);
        return true;
    }

    // delete token info? need to handle it's staking data.

    function UpdateTokenInfo(
        bytes32 _currency,
        address _tokenAddr,
        uint256 _minCollateral,
        bool _close
    ) external onlyAdmin returns (bool) {
        return updateTokenInfo(_currency, _tokenAddr, _minCollateral, _close);
    }

    function UpdateTokenInfos(
        bytes32[] calldata _symbols,
        address[] calldata _tokenAddrs,
        uint256[] calldata _minCollateral,
        bool[] calldata _closes
    ) external onlyAdmin returns (bool) {
        require(_symbols.length == _tokenAddrs.length, "length of array not eq");
        require(_symbols.length == _minCollateral.length, "length of array not eq");
        require(_symbols.length == _closes.length, "length of array not eq");

        for (uint256 i = 0; i < _symbols.length; i++) {
            updateTokenInfo(_symbols[i], _tokenAddrs[i], _minCollateral[i], _closes[i]);
        }

        return true;
    }

    // ------------------------------------------------------------------------
    function GetSystemTotalCollateralInUsd() public view returns (uint256 rTotal) {
        for (uint256 i = 0; i < tokenSymbol.length; i++) {
            bytes32 currency = tokenSymbol[i];
            uint256 collateralAmount = tokenInfos[currency].totalCollateral;
            if (Currency_LINA == currency) {
                collateralAmount = collateralAmount.add(mRewardLocker.totalLockedAmount());
            }
            if (collateralAmount > 0) {
                rTotal = rTotal.add(collateralAmount.multiplyDecimal(priceGetter.getPrice(currency)));
            }
        }

        if (address(this).balance > 0) {
            rTotal = rTotal.add(address(this).balance.multiplyDecimal(priceGetter.getPrice(Currency_ETH)));
        }
    }

    function GetUserTotalCollateralInUsd(address _user) public view returns (uint256 rTotal) {
        for (uint256 i = 0; i < tokenSymbol.length; i++) {
            bytes32 currency = tokenSymbol[i];
            uint256 collateralAmount = userCollateralData[_user][currency].collateral;
            if (Currency_LINA == currency) {
                collateralAmount = collateralAmount.add(mRewardLocker.balanceOf(_user));
            }
            if (collateralAmount > 0) {
                rTotal = rTotal.add(collateralAmount.multiplyDecimal(priceGetter.getPrice(currency)));
            }
        }

        if (userCollateralData[_user][Currency_ETH].collateral > 0) {
            rTotal = rTotal.add(
                userCollateralData[_user][Currency_ETH].collateral.multiplyDecimal(priceGetter.getPrice(Currency_ETH))
            );
        }
    }

    function GetUserCollateral(address _user, bytes32 _currency) external view returns (uint256) {
        if (Currency_LINA != _currency) {
            return userCollateralData[_user][_currency].collateral;
        }
        return mRewardLocker.balanceOf(_user).add(userCollateralData[_user][_currency].collateral);
    }

    function getUserLinaCollateralBreakdown(address _user) external view returns (uint256 staked, uint256 locked) {
        return (userCollateralData[_user]["LINA"].collateral, mRewardLocker.balanceOf(_user));
    }

    // NOTE: LINA collateral not include reward in locker
    function GetUserCollaterals(address _user) external view returns (bytes32[] memory, uint256[] memory) {
        bytes32[] memory rCurrency = new bytes32[](tokenSymbol.length + 1);
        uint256[] memory rAmount = new uint256[](tokenSymbol.length + 1);
        uint256 retSize = 0;
        for (uint256 i = 0; i < tokenSymbol.length; i++) {
            bytes32 currency = tokenSymbol[i];
            if (userCollateralData[_user][currency].collateral > 0) {
                rCurrency[retSize] = currency;
                rAmount[retSize] = userCollateralData[_user][currency].collateral;
                retSize++;
            }
        }
        if (userCollateralData[_user][Currency_ETH].collateral > 0) {
            rCurrency[retSize] = Currency_ETH;
            rAmount[retSize] = userCollateralData[_user][Currency_ETH].collateral;
            retSize++;
        }

        return (rCurrency, rAmount);
    }

    /**
     * @dev A temporary method for migrating LINA tokens from LnSimpleStaking to LnCollateralSystem
     * without user intervention.
     */
    function migrateCollateral(
        bytes32 _currency,
        address[] calldata _users,
        uint256[] calldata _amounts
    ) external onlyAdmin returns (bool) {
        require(tokenInfos[_currency].tokenAddr.isContract(), "Invalid token symbol");
        TokenInfo storage tokeninfo = tokenInfos[_currency];
        require(tokeninfo.bClose == false, "This token is closed");
        require(_users.length == _amounts.length, "Length mismatch");

        for (uint256 ind = 0; ind < _amounts.length; ind++) {
            address user = _users[ind];
            uint256 amount = _amounts[ind];

            userCollateralData[user][_currency].collateral = userCollateralData[user][_currency].collateral.add(amount);
            tokeninfo.totalCollateral = tokeninfo.totalCollateral.add(amount);

            emit CollateralLog(user, _currency, amount, userCollateralData[user][_currency].collateral);
        }
    }

    /**
     * @dev A unified function for staking collateral and building lUSD atomically. Only up to one of
     * `stakeAmount` and `buildAmount` can be zero.
     *
     * @param stakeCurrency ID of the collateral currency
     * @param stakeAmount Amount of collateral currency to stake, can be zero
     * @param buildAmount Amount of lUSD to build, can be zero
     */
    function stakeAndBuild(
        bytes32 stakeCurrency,
        uint256 stakeAmount,
        uint256 buildAmount
    ) external whenNotPaused {
        require(stakeAmount > 0 || buildAmount > 0, "LnCollateralSystem: zero amount");

        if (stakeAmount > 0) {
            _collateral(msg.sender, stakeCurrency, stakeAmount);
        }

        if (buildAmount > 0) {
            buildBurnSystem.buildFromCollateralSys(msg.sender, buildAmount);
        }
    }

    /**
     * @dev A unified function for staking collateral and building the maximum amount of lUSD atomically.
     *
     * @param stakeCurrency ID of the collateral currency
     * @param stakeAmount Amount of collateral currency to stake
     */
    function stakeAndBuildMax(bytes32 stakeCurrency, uint256 stakeAmount) external whenNotPaused {
        require(stakeAmount > 0, "LnCollateralSystem: zero amount");

        _collateral(msg.sender, stakeCurrency, stakeAmount);
        buildBurnSystem.buildMaxFromCollateralSys(msg.sender);
    }

    /**
     * @dev A unified function for burning lUSD and unstaking collateral atomically. Only up to one of
     * `burnAmount` and `unstakeAmount` can be zero.
     *
     * @param burnAmount Amount of lUSD to burn, can be zero
     * @param unstakeCurrency ID of the collateral currency
     * @param unstakeAmount Amount of collateral currency to unstake, can be zero
     */
    function burnAndUnstake(
        uint256 burnAmount,
        bytes32 unstakeCurrency,
        uint256 unstakeAmount
    ) external whenNotPaused {
        require(burnAmount > 0 || unstakeAmount > 0, "LnCollateralSystem: zero amount");

        if (burnAmount > 0) {
            buildBurnSystem.burnFromCollateralSys(msg.sender, burnAmount);
        }

        if (unstakeAmount > 0) {
            _Redeem(msg.sender, unstakeCurrency, unstakeAmount);
        }
    }

    /**
     * @dev A unified function for burning lUSD and unstaking the maximum amount of collateral atomically.
     *
     * @param burnAmount Amount of lUSD to burn
     * @param unstakeCurrency ID of the collateral currency
     */
    function burnAndUnstakeMax(uint256 burnAmount, bytes32 unstakeCurrency) external whenNotPaused {
        require(burnAmount > 0, "LnCollateralSystem: zero amount");

        buildBurnSystem.burnFromCollateralSys(msg.sender, burnAmount);
        _redeemMax(msg.sender, unstakeCurrency);
    }

    // need approve
    function Collateral(bytes32 _currency, uint256 _amount) external whenNotPaused returns (bool) {
        address user = msg.sender;
        return _collateral(user, _currency, _amount);
    }

    function _collateral(
        address user,
        bytes32 _currency,
        uint256 _amount
    ) private whenNotPaused returns (bool) {
        require(tokenInfos[_currency].tokenAddr.isContract(), "Invalid token symbol");
        TokenInfo storage tokeninfo = tokenInfos[_currency];
        require(_amount > tokeninfo.minCollateral, "Collateral amount too small");
        require(tokeninfo.bClose == false, "This token is closed");

        IERC20 erc20 = IERC20(tokenInfos[_currency].tokenAddr);
        require(erc20.balanceOf(user) >= _amount, "insufficient balance");
        require(erc20.allowance(user, address(this)) >= _amount, "insufficient allowance, need approve more amount");

        erc20.transferFrom(user, address(this), _amount);

        userCollateralData[user][_currency].collateral = userCollateralData[user][_currency].collateral.add(_amount);
        tokeninfo.totalCollateral = tokeninfo.totalCollateral.add(_amount);

        emit CollateralLog(user, _currency, _amount, userCollateralData[user][_currency].collateral);
        return true;
    }

    function IsSatisfyTargetRatio(address _user) public view returns (bool) {
        (uint256 debtBalance, ) = debtSystem.GetUserDebtBalanceInUsd(_user);
        if (debtBalance == 0) {
            return true;
        }

        uint256 buildRatio = mConfig.getUint(mConfig.BUILD_RATIO());
        uint256 totalCollateralInUsd = GetUserTotalCollateralInUsd(_user);
        if (totalCollateralInUsd == 0) {
            return false;
        }
        uint256 myratio = debtBalance.divideDecimal(totalCollateralInUsd);
        return myratio <= buildRatio;
    }

    function RedeemMax(bytes32 _currency) external whenNotPaused {
        _redeemMax(msg.sender, _currency);
    }

    function _redeemMax(address user, bytes32 _currency) private {
        require(_currency == Currency_LINA, "LnCollateralSystem: only LINA is supported");
        _Redeem(user, Currency_LINA, maxRedeemableLina(user));
    }

    function _Redeem(
        address user,
        bytes32 _currency,
        uint256 _amount
    ) internal {
        require(_currency == Currency_LINA, "LnCollateralSystem: only LINA is supported");
        require(_amount > 0, "LnCollateralSystem: zero amount");

        uint256 maxRedeemableLinaAmount = maxRedeemableLina(user);
        require(_amount <= maxRedeemableLinaAmount, "LnCollateralSystem: insufficient collateral");

        userCollateralData[user][Currency_LINA].collateral = userCollateralData[user][Currency_LINA].collateral.sub(_amount);

        TokenInfo storage tokeninfo = tokenInfos[Currency_LINA];
        tokeninfo.totalCollateral = tokeninfo.totalCollateral.sub(_amount);

        IERC20(tokeninfo.tokenAddr).transfer(user, _amount);

        emit RedeemCollateral(user, Currency_LINA, _amount, userCollateralData[user][Currency_LINA].collateral);
    }

    // 1. After redeem, collateral ratio need bigger than target ratio.
    // 2. Cannot redeem more than collateral.
    function Redeem(bytes32 _currency, uint256 _amount) external whenNotPaused returns (bool) {
        address user = msg.sender;
        _Redeem(user, _currency, _amount);
        return true;
    }

    function moveCollateral(
        address fromUser,
        address toUser,
        bytes32 currency,
        uint256 amount
    ) external whenNotPaused onlyLiquidation {
        userCollateralData[fromUser][currency].collateral = userCollateralData[fromUser][currency].collateral.sub(amount);
        userCollateralData[toUser][currency].collateral = userCollateralData[toUser][currency].collateral.add(amount);
        emit CollateralMoved(fromUser, toUser, currency, amount);
    }

    function collateralFromUnlockReward(
        address user,
        address rewarder,
        bytes32 currency,
        uint256 amount
    ) external whenNotPaused onlyRewardLocker {
        require(user != address(0), "LnCollateralSystem: User address cannot be zero");
        require(amount > 0, "LnCollateralSystem: Collateral amount must be > 0");

        TokenInfo storage tokeninfo = tokenInfos[currency];
        require(tokeninfo.tokenAddr != address(0), "LnCollateralSystem: Invalid token symbol");

        TransferHelper.safeTransferFrom(tokeninfo.tokenAddr, rewarder, address(this), amount);

        userCollateralData[user][currency].collateral = userCollateralData[user][currency].collateral.add(amount);
        tokeninfo.totalCollateral = tokeninfo.totalCollateral.add(amount);

        emit CollateralUnlockReward(user, currency, amount, userCollateralData[user][currency].collateral);
    }

    event UpdateTokenSetting(bytes32 symbol, address tokenAddr, uint256 minCollateral, bool close);
    event CollateralLog(address user, bytes32 _currency, uint256 _amount, uint256 _userTotal);
    event RedeemCollateral(address user, bytes32 _currency, uint256 _amount, uint256 _userTotal);
    event CollateralMoved(address fromUser, address toUser, bytes32 currency, uint256 amount);
    event CollateralUnlockReward(address user, bytes32 _currency, uint256 _amount, uint256 _userTotal);

    // Reserved storage space to allow for layout changes in the future.
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity >=0.6.12 <0.8.0;

interface ILnBuildBurnSystem {
    function buildFromCollateralSys(address user, uint256 amount) external;

    function buildMaxFromCollateralSys(address user) external;

    function burnFromCollateralSys(address user, uint256 amount) external;

    function burnForLiquidation(
        address user,
        address liquidator,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

interface ILnConfig {
    function BUILD_RATIO() external view returns (bytes32);

    function getUint(bytes32 key) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

interface ILnDebtSystem {
    function GetUserDebtBalanceInUsd(address _user) external view returns (uint256, uint256);

    function UpdateDebt(
        address _user,
        uint256 _debtProportion,
        uint256 _factor
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

interface ILnPrices {
    function getPrice(bytes32 currencyKey) external view returns (uint);

    function exchange(
        bytes32 sourceKey,
        uint sourceAmount,
        bytes32 destKey
    ) external view returns (uint);

    function LUSD() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

interface ILnRewardLocker {
    function balanceOf(address user) external view returns (uint256);

    function totalLockedAmount() external view returns (uint256);

    function addReward(
        address user,
        uint256 amount,
        uint256 unlockTime
    ) external;

    function moveReward(
        address from,
        address recipient,
        uint256 amount,
        uint256[] calldata rewardEntryIds
    ) external;

    function moveRewardProRata(
        address from,
        address recipient1,
        uint256 amount1,
        address recipient2,
        uint256 amount2,
        uint256[] calldata rewardEntryIds
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @title LnAdminUpgradeable
 *
 * @dev This is an upgradeable version of `LnAdmin` by replacing the constructor with
 * an initializer and reserving storage slots.
 */
contract LnAdminUpgradeable is Initializable {
    event CandidateChanged(address oldCandidate, address newCandidate);
    event AdminChanged(address oldAdmin, address newAdmin);

    address public admin;
    address public candidate;

    function __LnAdminUpgradeable_init(address _admin) public initializer {
        require(_admin != address(0), "LnAdminUpgradeable: zero address");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    function setCandidate(address _candidate) external onlyAdmin {
        address old = candidate;
        candidate = _candidate;
        emit CandidateChanged(old, candidate);
    }

    function becomeAdmin() external {
        require(msg.sender == candidate, "LnAdminUpgradeable: only candidate can become admin");
        address old = admin;
        admin = candidate;
        emit AdminChanged(old, admin);
    }

    modifier onlyAdmin {
        require((msg.sender == admin), "LnAdminUpgradeable: only the contract admin can perform this action");
        _;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @title TransferHelper
 *
 * @dev A helper library for calling functions on ERC20 tokens with compatibility for
 * non-ERC20 compliant contracts like Tether.
 */
library TransferHelper {
    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));
    bytes4 private constant TRANSFERFROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    function safeTransfer(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: transfer failed");
    }

    function safeApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(APPROVE_SELECTOR, spender, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: approve failed");
    }

    function safeTransferFrom(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(TRANSFERFROM_SELECTOR, sender, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: transferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interfaces/ILnAddressStorage.sol";

abstract contract LnAddressCache {
    function updateAddressCache(ILnAddressStorage _addressStorage) external virtual;

    event CachedAddressUpdated(bytes32 name, address addr);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint;

    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    uint public constant UNIT = 10**uint(decimals);

    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    function unit() external pure returns (uint) {
        return UNIT;
    }

    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        return x.mul(y) / UNIT;
    }

    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        return x.mul(UNIT).div(y);
    }

    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ILnAddressStorage {
    function updateAll(bytes32[] calldata names, address[] calldata destinations) external;

    function update(bytes32 name, address dest) external;

    function getAddress(bytes32 name) external view returns (address);

    function getAddressWithRequire(bytes32 name, string calldata reason) external view returns (address);
}