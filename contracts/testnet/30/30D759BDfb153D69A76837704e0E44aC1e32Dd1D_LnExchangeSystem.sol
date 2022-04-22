// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./LnAddressCache.sol";
import "./interfaces/ILnAsset.sol";
import "./interfaces/ILnAddressStorage.sol";
import "./interfaces/ILnPrices.sol";
import "./interfaces/ILnConfig.sol";
import "./upgradeable/LnAdminUpgradeable.sol";
import "./SafeDecimalMath.sol";

contract LnExchangeSystem is LnAdminUpgradeable, LnAddressCache {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    event ExchangeAsset(
        address fromAddr,
        bytes32 sourceKey,
        uint sourceAmount,
        address destAddr,
        bytes32 destKey,
        uint destRecived,
        uint feeForPool,
        uint feeForFoundation
    );
    event FoundationFeeHolderChanged(address oldHolder, address newHolder);
    event ExitPositionOnlyChanged(bool oldValue, bool newValue);
    event PendingExchangeAdded(
        uint256 id,
        address fromAddr,
        address destAddr,
        uint256 fromAmount,
        bytes32 fromCurrency,
        bytes32 toCurrency
    );
    event PendingExchangeSettled(
        uint256 id,
        address settler,
        uint256 destRecived,
        uint256 feeForPool,
        uint256 feeForFoundation
    );
    event PendingExchangeReverted(uint256 id);

    struct PendingExchangeEntry {
        uint64 id;
        uint64 timestamp;
        address fromAddr;
        address destAddr;
        uint256 fromAmount;
        bytes32 fromCurrency;
        bytes32 toCurrency;
    }

    ILnAddressStorage mAssets;
    ILnPrices mPrices;
    ILnConfig mConfig;
    address mRewardSys;
    address foundationFeeHolder;

    bool public exitPositionOnly;

    uint256 public lastPendingExchangeEntryId;
    mapping(uint256 => PendingExchangeEntry) public pendingExchangeEntries;

    bytes32 private constant ASSETS_KEY = "LnAssetSystem";
    bytes32 private constant PRICES_KEY = "LnPrices";
    bytes32 private constant CONFIG_KEY = "LnConfig";
    bytes32 private constant REWARD_SYS_KEY = "LnRewardSystem";
    bytes32 private constant CONFIG_FEE_SPLIT = "FoundationFeeSplit";
    bytes32 private constant CONFIG_TRADE_SETTLEMENT_DELAY = "TradeSettlementDelay";
    bytes32 private constant CONFIG_TRADE_REVERT_DELAY = "TradeRevertDelay";

    bytes32 private constant LUSD_KEY = "lUSD";

    function __LnExchangeSystem_init(address _admin) public initializer {
        __LnAdminUpgradeable_init(_admin);
    }

    function updateAddressCache(ILnAddressStorage _addressStorage) public override onlyAdmin {
        mAssets = ILnAddressStorage(_addressStorage.getAddressWithRequire(ASSETS_KEY, ""));
        mPrices = ILnPrices(_addressStorage.getAddressWithRequire(PRICES_KEY, ""));
        mConfig = ILnConfig(_addressStorage.getAddressWithRequire(CONFIG_KEY, ""));
        mRewardSys = _addressStorage.getAddressWithRequire(REWARD_SYS_KEY, "");

        emit CachedAddressUpdated(ASSETS_KEY, address(mAssets));
        emit CachedAddressUpdated(PRICES_KEY, address(mPrices));
        emit CachedAddressUpdated(CONFIG_KEY, address(mConfig));
        emit CachedAddressUpdated(REWARD_SYS_KEY, address(mRewardSys));
    }

    function setFoundationFeeHolder(address _foundationFeeHolder) public onlyAdmin {
        require(_foundationFeeHolder != address(0), "LnExchangeSystem: zero address");
        require(_foundationFeeHolder != foundationFeeHolder, "LnExchangeSystem: foundation fee holder not changed");

        address oldHolder = foundationFeeHolder;
        foundationFeeHolder = _foundationFeeHolder;

        emit FoundationFeeHolderChanged(oldHolder, foundationFeeHolder);
    }

    function setExitPositionOnly(bool newValue) public onlyAdmin {
        require(exitPositionOnly != newValue, "LnExchangeSystem: value not changed");

        bool oldValue = exitPositionOnly;
        exitPositionOnly = newValue;

        emit ExitPositionOnlyChanged(oldValue, newValue);
    }

    function exchange(
        bytes32 sourceKey,
        uint sourceAmount,
        address destAddr,
        bytes32 destKey
    ) external {
        return _exchange(msg.sender, sourceKey, sourceAmount, destAddr, destKey);
    }

    function settle(uint256 pendingExchangeEntryId) external {
        _settle(pendingExchangeEntryId, msg.sender);
    }

    function revert(uint256 pendingExchangeEntryId) external {
        _revert(pendingExchangeEntryId, msg.sender);
    }

    function _exchange(
        address fromAddr,
        bytes32 sourceKey,
        uint sourceAmount,
        address destAddr,
        bytes32 destKey
    ) private {
        if (exitPositionOnly) {
            require(destKey == LUSD_KEY, "LnExchangeSystem: can only exit position");
        }

        // We don't need the return value here. It's just for preventing entering invalid trades
        mAssets.getAddressWithRequire(destKey, "LnExchangeSystem: dest asset not found");

        ILnAsset source = ILnAsset(mAssets.getAddressWithRequire(sourceKey, "LnExchangeSystem: source asset not found"));

        // Only lock up the source amount here. Everything else will be performed in settlement.
        // The `move` method is a special variant of `transferForm` that doesn't require approval.
        source.move(fromAddr, address(this), sourceAmount);

        // Record the pending entry
        PendingExchangeEntry memory newPendingEntry =
            PendingExchangeEntry({
                id: uint64(++lastPendingExchangeEntryId),
                timestamp: uint64(block.timestamp),
                fromAddr: fromAddr,
                destAddr: destAddr,
                fromAmount: sourceAmount,
                fromCurrency: sourceKey,
                toCurrency: destKey
            });
        pendingExchangeEntries[uint256(newPendingEntry.id)] = newPendingEntry;

        // Emit event for off-chain indexing
        emit PendingExchangeAdded(newPendingEntry.id, fromAddr, destAddr, sourceAmount, sourceKey, destKey);
    }

    function _settle(uint256 pendingExchangeEntryId, address settler) private {
        PendingExchangeEntry memory exchangeEntry = pendingExchangeEntries[pendingExchangeEntryId];
        require(exchangeEntry.id > 0, "LnExchangeSystem: pending entry not found");

        uint settlementDelay = mConfig.getUint(CONFIG_TRADE_SETTLEMENT_DELAY);
        uint256 revertDelay = mConfig.getUint(CONFIG_TRADE_REVERT_DELAY);
        require(settlementDelay > 0, "LnExchangeSystem: settlement delay not set");
        require(revertDelay > 0, "LnExchangeSystem: revert delay not set");
        require(
            block.timestamp >= exchangeEntry.timestamp + settlementDelay,
            "LnExchangeSystem: settlement delay not passed"
        );
        require(
            block.timestamp <= exchangeEntry.timestamp + revertDelay,
            "LnExchangeSystem: trade can only be reverted now"
        );

        ILnAsset source =
            ILnAsset(mAssets.getAddressWithRequire(exchangeEntry.fromCurrency, "LnExchangeSystem: source asset not found"));
        ILnAsset dest =
            ILnAsset(mAssets.getAddressWithRequire(exchangeEntry.toCurrency, "LnExchangeSystem: dest asset not found"));
        uint destAmount = mPrices.exchange(exchangeEntry.fromCurrency, exchangeEntry.fromAmount, exchangeEntry.toCurrency);

        // This might cause a transaction to deadlock, but impact would be negligible
        require(destAmount > 0, "LnExchangeSystem: zero dest amount");

        uint feeRate = mConfig.getUint(exchangeEntry.toCurrency);
        uint destRecived = destAmount.multiplyDecimal(SafeDecimalMath.unit().sub(feeRate));
        uint fee = destAmount.sub(destRecived);

        // Fee going into the pool, to be adjusted based on foundation split
        uint feeForPoolInUsd = mPrices.exchange(exchangeEntry.toCurrency, fee, mPrices.LUSD());

        // Split the fee between pool and foundation when both holder and ratio are set
        uint256 foundationSplit;
        if (foundationFeeHolder == address(0)) {
            foundationSplit = 0;
        } else {
            uint256 splitRatio = mConfig.getUint(CONFIG_FEE_SPLIT);

            if (splitRatio == 0) {
                foundationSplit = 0;
            } else {
                foundationSplit = feeForPoolInUsd.multiplyDecimal(splitRatio);
                feeForPoolInUsd = feeForPoolInUsd.sub(foundationSplit);
            }
        }

        ILnAsset lusd =
            ILnAsset(mAssets.getAddressWithRequire(mPrices.LUSD(), "LnExchangeSystem: failed to get lUSD address"));

        if (feeForPoolInUsd > 0) lusd.mint(mRewardSys, feeForPoolInUsd);
        if (foundationSplit > 0) lusd.mint(foundationFeeHolder, foundationSplit);

        source.burn(address(this), exchangeEntry.fromAmount);
        dest.mint(exchangeEntry.destAddr, destRecived);

        delete pendingExchangeEntries[pendingExchangeEntryId];

        emit PendingExchangeSettled(exchangeEntry.id, settler, destRecived, feeForPoolInUsd, foundationSplit);
    }

    function _revert(uint256 pendingExchangeEntryId, address reverter) private {
        PendingExchangeEntry memory exchangeEntry = pendingExchangeEntries[pendingExchangeEntryId];
        require(exchangeEntry.id > 0, "LnExchangeSystem: pending entry not found");

        uint256 revertDelay = mConfig.getUint(CONFIG_TRADE_REVERT_DELAY);
        require(revertDelay > 0, "LnExchangeSystem: revert delay not set");
        require(block.timestamp > exchangeEntry.timestamp + revertDelay, "LnExchangeSystem: revert delay not passed");

        ILnAsset source =
            ILnAsset(mAssets.getAddressWithRequire(exchangeEntry.fromCurrency, "LnExchangeSystem: source asset not found"));

        // Refund the amount locked
        source.move(address(this), exchangeEntry.fromAddr, exchangeEntry.fromAmount);

        delete pendingExchangeEntries[pendingExchangeEntryId];

        emit PendingExchangeReverted(exchangeEntry.id);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[42] private __gap;
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILnAsset is IERC20 {
    function keyName() external view returns (bytes32);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function move(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ILnAddressStorage {
    function updateAll(bytes32[] calldata names, address[] calldata destinations) external;

    function update(bytes32 name, address dest) external;

    function getAddress(bytes32 name) external view returns (address);

    function getAddressWithRequire(bytes32 name, string calldata reason) external view returns (address);
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

interface ILnConfig {
    function BUILD_RATIO() external view returns (bytes32);

    function getUint(bytes32 key) external view returns (uint);
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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
        return !AddressUpgradeable.isContract(address(this));
    }
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