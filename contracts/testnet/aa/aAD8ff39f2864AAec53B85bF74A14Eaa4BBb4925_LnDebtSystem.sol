// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./upgradeable/LnAdminUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SafeDecimalMath.sol";
import "./LnAddressCache.sol";
import "./interfaces/ILnAccessControl.sol";
import "./interfaces/ILnAssetSystem.sol";

contract LnDebtSystem is LnAdminUpgradeable, LnAddressCache {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    // -------------------------------------------------------
    // need set before system running value.
    ILnAccessControl private accessCtrl;
    ILnAssetSystem private assetSys;
    // -------------------------------------------------------
    struct DebtData {
        uint256 debtProportion;
        uint256 debtFactor; // PRECISE_UNIT
    }
    mapping(address => DebtData) public userDebtState;

    //use mapping to store array data
    mapping(uint256 => uint256) public lastDebtFactors; // PRECISE_UNIT Note: 能直接记 factor 的记 factor, 不能记的就用index查
    uint256 public debtCurrentIndex; // length of array. this index of array no value
    // follow var use to manage array size.
    uint256 public lastCloseAt; // close at array index
    uint256 public lastDeletTo; // delete to array index, lastDeletTo < lastCloseAt
    uint256 public constant MAX_DEL_PER_TIME = 50;

    //

    // -------------------------------------------------------
    function __LnDebtSystem_init(address _admin) public initializer {
        __LnAdminUpgradeable_init(_admin);
    }

    event UpdateAddressStorage(address oldAddr, address newAddr);
    event UpdateUserDebtLog(address addr, uint256 debtProportion, uint256 debtFactor, uint256 timestamp);
    event PushDebtLog(uint256 index, uint256 newFactor, uint256 timestamp);

    // ------------------ system config ----------------------
    function updateAddressCache(ILnAddressStorage _addressStorage) public override onlyAdmin {
        accessCtrl = ILnAccessControl(
            _addressStorage.getAddressWithRequire("LnAccessControl", "LnAccessControl address not valid")
        );
        assetSys = ILnAssetSystem(_addressStorage.getAddressWithRequire("LnAssetSystem", "LnAssetSystem address not valid"));

        emit CachedAddressUpdated("LnAccessControl", address(accessCtrl));
        emit CachedAddressUpdated("LnAssetSystem", address(assetSys));
    }

    // -----------------------------------------------
    modifier OnlyDebtSystemRole(address _address) {
        require(accessCtrl.hasRole(accessCtrl.DEBT_SYSTEM(), _address), "Need debt system access role");
        _;
    }

    function SetLastCloseFeePeriodAt(uint256 index) external OnlyDebtSystemRole(msg.sender) {
        require(index >= lastCloseAt, "Close index can not return to pass");
        require(index <= debtCurrentIndex, "Can not close at future index");
        lastCloseAt = index;
    }

    /**
     * @dev A temporary method for migrating debt records from Ethereum to Binance Smart Chain.
     */
    function importDebtData(
        address[] calldata users,
        uint256[] calldata debtProportions,
        uint256[] calldata debtFactors,
        uint256[] calldata timestamps
    ) external onlyAdmin {
        require(
            users.length == debtProportions.length &&
                debtProportions.length == debtFactors.length &&
                debtFactors.length == timestamps.length,
            "Length mismatch"
        );

        for (uint256 ind = 0; ind < users.length; ind++) {
            address user = users[ind];
            uint256 debtProportion = debtProportions[ind];
            uint256 debtFactor = debtFactors[ind];
            uint256 timestamp = timestamps[ind];

            uint256 currentIndex = debtCurrentIndex + ind;

            lastDebtFactors[currentIndex] = debtFactor;
            userDebtState[user] = DebtData({debtProportion: debtProportion, debtFactor: debtFactor});

            emit PushDebtLog(currentIndex, debtFactor, timestamp);
            emit UpdateUserDebtLog(user, debtProportion, debtFactor, timestamp);
        }

        debtCurrentIndex = debtCurrentIndex + users.length;
    }

    function _pushDebtFactor(uint256 _factor) private {
        if (debtCurrentIndex == 0 || lastDebtFactors[debtCurrentIndex - 1] == 0) {
            // init or all debt has be cleared, new set value will be one unit
            lastDebtFactors[debtCurrentIndex] = SafeDecimalMath.preciseUnit();
        } else {
            lastDebtFactors[debtCurrentIndex] = lastDebtFactors[debtCurrentIndex - 1].multiplyDecimalRoundPrecise(_factor);
        }
        emit PushDebtLog(debtCurrentIndex, lastDebtFactors[debtCurrentIndex], block.timestamp);

        debtCurrentIndex = debtCurrentIndex.add(1);

        // delete out of date data
        if (lastDeletTo < lastCloseAt) {
            // safe check
            uint256 delNum = lastCloseAt - lastDeletTo;
            delNum = (delNum > MAX_DEL_PER_TIME) ? MAX_DEL_PER_TIME : delNum; // not delete all in one call, for saving someone fee.
            for (uint256 i = lastDeletTo; i < delNum; i++) {
                delete lastDebtFactors[i];
            }
            lastDeletTo = lastDeletTo.add(delNum);
        }
    }

    function PushDebtFactor(uint256 _factor) external OnlyDebtSystemRole(msg.sender) {
        _pushDebtFactor(_factor);
    }

    function _updateUserDebt(address _user, uint256 _debtProportion) private {
        userDebtState[_user].debtProportion = _debtProportion;
        userDebtState[_user].debtFactor = _lastSystemDebtFactor();
        emit UpdateUserDebtLog(_user, _debtProportion, userDebtState[_user].debtFactor, block.timestamp);
    }

    // need update lastDebtFactors first
    function UpdateUserDebt(address _user, uint256 _debtProportion) external OnlyDebtSystemRole(msg.sender) {
        _updateUserDebt(_user, _debtProportion);
    }

    function UpdateDebt(
        address _user,
        uint256 _debtProportion,
        uint256 _factor
    ) external OnlyDebtSystemRole(msg.sender) {
        _pushDebtFactor(_factor);
        _updateUserDebt(_user, _debtProportion);
    }

    function GetUserDebtData(address _user) external view returns (uint256 debtProportion, uint256 debtFactor) {
        debtProportion = userDebtState[_user].debtProportion;
        debtFactor = userDebtState[_user].debtFactor;
    }

    function _lastSystemDebtFactor() private view returns (uint256) {
        if (debtCurrentIndex == 0) {
            return SafeDecimalMath.preciseUnit();
        }
        return lastDebtFactors[debtCurrentIndex - 1];
    }

    function LastSystemDebtFactor() external view returns (uint256) {
        return _lastSystemDebtFactor();
    }

    function GetUserCurrentDebtProportion(address _user) public view returns (uint256) {
        uint256 debtProportion = userDebtState[_user].debtProportion;
        uint256 debtFactor = userDebtState[_user].debtFactor;

        if (debtProportion == 0) {
            return 0;
        }

        uint256 currentUserDebtProportion =
            _lastSystemDebtFactor().divideDecimalRoundPrecise(debtFactor).multiplyDecimalRoundPrecise(debtProportion);
        return currentUserDebtProportion;
    }

    /**
     *
     *@return [0] the debt balance of user. [1] system total asset in usd.
     */
    function GetUserDebtBalanceInUsd(address _user) external view returns (uint256, uint256) {
        uint256 totalAssetSupplyInUsd = assetSys.totalAssetsInUsd();

        uint256 debtProportion = userDebtState[_user].debtProportion;
        uint256 debtFactor = userDebtState[_user].debtFactor;

        if (debtProportion == 0) {
            return (0, totalAssetSupplyInUsd);
        }

        uint256 currentUserDebtProportion =
            _lastSystemDebtFactor().divideDecimalRoundPrecise(debtFactor).multiplyDecimalRoundPrecise(debtProportion);
        uint256 userDebtBalance =
            totalAssetSupplyInUsd
                .decimalToPreciseDecimal()
                .multiplyDecimalRoundPrecise(currentUserDebtProportion)
                .preciseDecimalToDecimal();

        return (userDebtBalance, totalAssetSupplyInUsd);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[42] private __gap;
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
pragma solidity ^0.6.12;

import "./interfaces/ILnAddressStorage.sol";

abstract contract LnAddressCache {
    function updateAddressCache(ILnAddressStorage _addressStorage) external virtual;

    event CachedAddressUpdated(bytes32 name, address addr);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

interface ILnAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function ISSUE_ASSET_ROLE() external view returns (bytes32);

    function BURN_ASSET_ROLE() external view returns (bytes32);

    function DEBT_SYSTEM() external view returns (bytes32);

    function IsAdmin(address _address) external view returns (bool);

    function SetAdmin(address _address) external returns (bool);

    function SetRoles(
        bytes32 roleType,
        address[] calldata addresses,
        bool[] calldata setTo
    ) external;

    function SetIssueAssetRole(address[] calldata issuer, bool[] calldata setTo) external;

    function SetBurnAssetRole(address[] calldata burner, bool[] calldata setTo) external;

    function SetDebtSystemRole(address[] calldata _address, bool[] calldata _setTo) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

interface ILnAssetSystem {
    function perpAddresses(bytes32 symbol) external view returns (address);

    function perpSymbols(address perpAddress) external view returns (bytes32);

    function isPerpAddressRegistered(address perpAddress) external view returns (bool);

    function totalAssetsInUsd() external view returns (uint256 rTotal);
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