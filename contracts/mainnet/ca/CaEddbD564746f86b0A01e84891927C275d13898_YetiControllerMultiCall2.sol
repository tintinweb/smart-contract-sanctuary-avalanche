// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../Interfaces/IYetiController.sol";
import "./IVault.sol";
import "../Dependencies/SafeMath.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Dependencies/Ownable.sol";
import "../Other/ThreePieceWiseLinearFeeCurve.sol";

contract YetiControllerMultiCall2 is Ownable {
    
    using SafeMath for uint256;

    IYetiController public yetiController;
    address[] private additionalVaults;
    IPriceFeed[] private additionalVaultPriceFeeds;

    constructor(address yetiController_) public {
        yetiController = IYetiController(yetiController_);
    }

    function addAdditionalVaults(address vault_, IPriceFeed priceFeed_) external {
        additionalVaults.push(vault_);
        additionalVaultPriceFeeds.push(priceFeed_);
    }

    function getAdditionalVaults() external view returns (address[] memory) {
        return additionalVaults;
    }


    function getYetiControllerData() external view 
        returns (address[] memory oracles
                , uint256[] memory dollarCaps) {
        
        address[] memory whitelistedCollaterals = yetiController.getValidCollateral();


       
        oracles = new address[](whitelistedCollaterals.length);
        dollarCaps = new uint256[](whitelistedCollaterals.length);


        for (uint i = 0; i < whitelistedCollaterals.length; i++) {

            address collateral = whitelistedCollaterals[i];

            oracles[i] = yetiController.getOracle(collateral);

            dollarCaps[i] = ThreePieceWiseLinearFeeCurve(yetiController.getFeeCurve(collateral)).dollarCap();


           
    }
                }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;


interface IYetiController {

    // ======== Mutable Only Owner-Instantaneous ========
    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _borrowerOperationsAddress,
        address _yusdTokenAddress,
        address _YUSDFeeRecipientAddress,
        address _yetiFinanceTreasury,
        address _sortedTrovesAddress,
        address _veYETIAddress,
        address _troveManagerRedemptionsAddress,
        address _claimAddress,
        address _threeDayTimelock,
        address _twoWeekTimelock
    ) external;
    function endBootstrap() external;
    function deprecateAllCollateral() external;
    function deprecateCollateral(address _collateral) external;
    function setLeverUp(bool _enabled) external;
    function setFeeBootstrapPeriodEnabled(bool _enabled) external;
    function updateGlobalYUSDMinting(bool _canMint) external;
    function removeValidYUSDMinter(address _minter) external;
    function removeVeYetiCaller(address _contractAddress) external;
    function updateRedemptionsEnabled(bool _enabled) external;
    function changeFeeCurve(address _collateral, address _feeCurve) external;


    // ======== Mutable Only Owner-3 Day TimeLock ========
    function addCollateral(
        address _collateral,
        uint256 _safetyRatio,
        uint256 _recoveryRatio,
        address _oracle,
        uint256 _decimals,
        address _feeCurve,
        bool _isWrapped,
        address _routerAddress
    ) external;
    function unDeprecateCollateral(address _collateral) external;
    function updateMaxCollsInTrove(uint _newMax) external;
    function changeRatios(address _collateral, uint256 _newSafetyRatio, uint256 _newRecoveryRatio) external;
    function setDefaultRouter(address _collateral, address _router) external;
    function changeYetiFinanceTreasury(address _newTreasury) external;
    function changeClaimAddress(address _newClaimAddress) external;
    function changeYUSDFeeRecipient(address _newFeeRecipient) external;
    function changeYetiFinanceTreasurySplit(uint256 _newSplit) external;
    function changeRedemptionBorrowerFeeSplit(uint256 _newSplit) external;
    function updateAbsorptionColls(address[] memory _colls, uint[] memory _weights) external;
    function changeOracle(address _collateral, address _oracle) external;
    function changeInterestTimeWindow(uint256 _newInterestTimeWindow) external;
    function setTroveManager(address _tm) external;
    function setInterestRates(address[] calldata _colls, uint256[] calldata _newRates) external;
    function setBorrowingFeeFloor(uint256 _newBorrowingFeeFloor) external;


    // ======== Mutable Only Owner-2 Week TimeLock ========
    function addValidYUSDMinter(address _minter) external;
    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor) external;
    function changeGlobalBoostMultiplier(uint256 _newBoostMinuteDecayFactor) external;
    function addVeYetiCaller(address _contractAddress) external;
    function updateMaxSystemColls(uint _newMax) external;


    // ======= VIEW FUNCTIONS FOR COLLATERAL PARAMS =======
    function getValidCollateral() view external returns (address[] memory);
    function getOracle(address _collateral) view external returns (address);
    function getSafetyRatio(address _collateral) view external returns (uint256);
    function getRecoveryRatio(address _collateral) view external returns (uint256);
    function getIsActive(address _collateral) view external returns (bool);
    function getFeeCurve(address _collateral) external view returns (address);
    function getDecimals(address _collateral) external view returns (uint256);
    function getIndex(address _collateral) external view returns (uint256);
    function getIndices(address[] memory _colls) external view returns (uint256[] memory indices);
    function checkCollateralListSingle(address[] memory _colls, bool _deposit) external view;
    function checkCollateralListDouble(address[] memory _depositColls, address[] memory _withdrawColls) external view;
    function isWrapped(address _collateral) external view returns (bool);
    function isWrappedMany(address[] memory _collaterals) external view returns (bool[] memory wrapped);
    function getDefaultRouterAddress(address _collateral) external view returns (address);


    // ======= VIEW FUNCTIONS FOR VC / USD VALUE =======
    function getPrice(address _collateral) external view returns (uint256);
    function getValuesVC(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint);
    function getValuesRVC(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint);
    function getValuesVCAndRVC(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint VC, uint256 RVC);
    function getValuesUSD(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint256);
    function getValueVC(address _collateral, uint _amount) view external returns (uint);
    function getValueRVC(address _collateral, uint _amount) view external returns (uint);
    function getValueUSD(address _collateral, uint _amount) view external returns (uint256);
    function getValuesVCIndividual(address[] memory _collaterals, uint256[] memory _amounts) external view returns (uint256[] memory);


    // ======= VIEW FUNCTIONS FOR CONTRACT FUNCTIONALITY =======
    function getYetiFinanceTreasury() external view returns (address);
    function getYetiFinanceTreasurySplit() external view returns (uint256);
    function getRedemptionBorrowerFeeSplit() external view returns (uint256);
    function getYUSDFeeRecipient() external view returns (address);
    function leverUpEnabled() external view returns (bool);
    function getMaxCollsInTrove() external view returns (uint);
    function getFeeSplitInformation() external view returns (uint256, address, address);
    function getClaimAddress() external view returns (address);
    function getAbsorptionCollParams() external view returns (address[] memory, uint[] memory);
    function getVariableDepositFee(address _collateral, uint _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external view returns (uint256 fee);

    function isValidAdditionalMinter(address _minter) external view returns (bool);
    function getInterestRates(address[] memory _colls) external view returns (uint256[] memory);

    function getBorrowingFeeFloor() external view returns (uint256);

    // ======== Mutable Function For Fees ========
    function getTotalVariableDepositFeeAndUpdate(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256 _entireSystemCollVC,
        uint256 _VCin,
        uint256 _VCout
    ) external returns (uint256 YUSDFee, uint256 boostFactor);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;


interface IVault {
    function underlying() external view virtual returns (address);
    function underlyingDecimal() external view virtual returns (uint256);
    function underlyingPerReceipt() external view virtual returns (uint256);
    function receiptPerUnderlying() external view virtual returns (uint256);
    function totalSupply() external view virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "sub overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
        require(c / a == b, "mul overflow");

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "div by 0");
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "mod by 0");
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED


/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IPriceFeed {

    event LastGoodPriceUpdated(uint256 _lastGoodPrice);

    function fetchPrice_v() view external returns (uint);
    function fetchPrice() external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "CallerNotOwner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IFeeCurve.sol";
import "../Dependencies/SafeMath.sol";
import "../Dependencies/Ownable.sol";

/** 
 * This contract is used to calculate the variable fee for an input of tokens. 
 * Uses three linear piecewise functions to calculate the fee, and the average 
 * of the system collateralization by that asset before and after the tx. 
 */
contract ThreePieceWiseLinearFeeCurve is IFeeCurve, Ownable {
    using SafeMath for uint256;

    string public name;
    uint256 public m1;
    uint256 public b1;
    uint256 public cutoff1;
    uint256 public m2;
    uint256 public b2;
    bool public b2Negative;
    uint256 public cutoff2;
    uint256 public m3;
    uint256 public b3;
    bool public b3Negative;
    uint256 public decayTime;

    uint public lastFeeTime;
    uint public lastFeePercent;
    uint public dollarCap;
    address private controllerAddress;
    bool private addressesSet;
    bool private paramsInitialized;

    /** 
     * f1 = m1 * x + b1
     * f1 meets f2 at cutoff1, which is defined by that intersection point and slope m2
     * f2 meets f3 at cutoff2, which is defined by that intersection point and slope m3
     * Everything in terms of actual * 1e18, scaled by 1e18 because can't do percentages
     * Decimal precision = 1e18
     */

    /** 
     * Function for setting slopes and intercepts of linear functions used for fee calculations. 
     */
    function adjustParams(string memory _name, uint256 _m1, uint256 _b1, uint256 _m2, uint256 _cutoff1, uint256 _m3, uint256 _cutoff2, uint _dollarCap, uint _decayTime) external onlyOwner {
        require(_cutoff1 <= _cutoff2, "Cutoffs must be increasing");
        require(_m2 >= _m1, "slope cannot decrease");
        require(_m3 >= _m2, "slope cannot decrease");

        name = _name;
        m1 = _m1;
        b1 = _b1;
        m2 = _m2;
        uint256 m1Val = _m1.mul(_cutoff1).div(1e18).add(_b1);
        uint256 m2Val = _m2.mul(_cutoff1).div(1e18);
        if (m2Val > m1Val) {
            b2Negative = true;
            b2 = m2Val.sub(m1Val);
        } else {
            b2 = m1Val.sub(m2Val);
        }
        // b2 = _m1.mul(_cutoff1).div(1e18).add(_b1).sub(_m2.mul(_cutoff1).div(1e18));
        cutoff1 = _cutoff1;
        m3 = _m3;
        m2Val = _m2.mul(_cutoff2).div(1e18).add(b2);
        uint256 m3Val = _m3.mul(_cutoff2).div(1e18);
        if (m3Val > m2Val) {
            b3Negative = true;
            b3 = m3Val.sub(m2Val);
        } else {
            b3 = m2Val.sub(m3Val);
        }
        // b3 = _m2.mul(_cutoff2).div(1e18).add(b2).sub(_m3.mul(_cutoff2).div(1e18));
        cutoff2 = _cutoff2;
        dollarCap = _dollarCap; // Cap in VC terms of max of this asset. dollarCap = 0 means no cap.
        decayTime = _decayTime; // like 5 days = 432000 in unix time. 
        paramsInitialized = true;
    }

    // Set the controller address so that the fee can only be updated by controllerAddress
    function setAddresses(address _controllerAddress) external override onlyOwner {
        require(!addressesSet, "addresses already set");
        controllerAddress = _controllerAddress;
        addressesSet = true;
    }

    function initialized() external view override returns (bool) {
        return addressesSet && paramsInitialized;
    }

    // Set the decay time in seconds
    function setDecayTime(uint _decayTime) external override onlyOwner {
        decayTime = _decayTime;
    }

    // Set the dollar cap in VC terms
    function setDollarCap(uint _dollarCap) external override onlyOwner {
        dollarCap = _dollarCap;
    }

    // Gets the fee cap and time currently. Used for setting new values for next fee curve. 
    function getFeeCapAndTime() external override view returns (uint256, uint256) {
        return (lastFeePercent, lastFeeTime);
    }

    // Function for setting the old fee curve's last fee cap / value to the new fee cap / value. 
    // Called only by controller.
    function setFeeCapAndTime(uint256 _lastFeePercent, uint256 _lastFeeTime) external override {
        require(msg.sender == controllerAddress, "caller must be controller");
        lastFeePercent = _lastFeePercent;
        lastFeeTime = _lastFeeTime;
    }

    /** 
     * Function for getting the fee for a particular collateral type based on percent of YUSD backed
     * by this asset. 
     * @param _collateralVCInput is how much collateral is being input by the user into the system
     * @param _totalCollateralVCBalance is how much collateral is in the system
     * @param _totalVCBalancePost is how much VC the system for all collaterals after all adjustments (additions, subtractions)
     */
    function getFee(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) override external view returns (uint256 feeCalculated) {
        feeCalculated = _getFee(_collateralVCInput, _totalCollateralVCBalance, _totalVCBalancePre, _totalVCBalancePost);
    }

    // Called only by controller. Updates the last fee time and last fee percent
    function getFeeAndUpdate(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) override external returns (uint256 feeCalculated) {
        require(msg.sender == controllerAddress, "Only controller can update fee");
        feeCalculated = _getFee(_collateralVCInput, _totalCollateralVCBalance, _totalVCBalancePre, _totalVCBalancePost);
        lastFeeTime = block.timestamp;
        lastFeePercent = feeCalculated;
    }

    function _getFee(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) internal view returns (uint256 feeCalculated) {
        // If dollarCap == 0, then it is not capped. Otherwise, then the total + the total input must be less than the cap.
        uint256 cachedDollarCap = dollarCap;
        if (cachedDollarCap != 0) {
            require(_totalCollateralVCBalance.add(_collateralVCInput) <= cachedDollarCap, "Collateral input exceeds cap");
        }

        uint feePre = _getFeePoint(_totalCollateralVCBalance, _totalVCBalancePre);
        uint feePost = _getFeePoint(_totalCollateralVCBalance.add(_collateralVCInput), _totalVCBalancePost);

        uint decayedLastFee = calculateDecayedFee();
        // Cap fee at 100%, but also at least decayedLastFee
        feeCalculated = _min(1e18, _max((feePre.add(feePost)).div(2), decayedLastFee));
    }

    /** 
     * Function for getting the fee for a particular collateral type based on percent of YUSD backed
     * by this asset. 
     */
    function _getFeePoint(uint256 _collateralVCBalance, uint256 _totalVCBalance) internal view returns (uint256) {
        if (_totalVCBalance == 0) {
            return 0;
        }
        // percent of all VC backed by this collateral * 1e18
        uint256 percentBacked = _collateralVCBalance.mul(1e18).div(_totalVCBalance);
        require(percentBacked <= 1e18, "percent backed out of bounds");

        if (percentBacked <= cutoff1) { // use function 1
            return _min(m1.mul(percentBacked).div(1e18).add(b1), 1e18);
        } else if (percentBacked <= cutoff2) { // use function 2
            if (b2Negative) {
                return _min(m2.mul(percentBacked).div(1e18).sub(b2), 1e18);
            } else {
                return _min(m2.mul(percentBacked).div(1e18).add(b2), 1e18);
            }
        } else { // use function 3
            if (b3Negative) {
                return _min(m3.mul(percentBacked).div(1e18).sub(b3), 1e18);
            } else {
                return _min(m3.mul(percentBacked).div(1e18).add(b3), 1e18);
            }
        }
    }

    function calculateDecayedFee() public override view returns (uint256 fee) {
        uint256 timeSinceLastFee = block.timestamp.sub(lastFeeTime);
        // Decay within bounds of decay time
        uint256 cachedDecayTime = decayTime;
        if (timeSinceLastFee <= cachedDecayTime) {
            // Linearly decay based on time since last fee. 
            fee = lastFeePercent.sub(lastFeePercent.mul(timeSinceLastFee).div(cachedDecayTime));
        } else {
            // If it has been longer than decay time, then reset fee to 0.
            fee = 0;
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? b : a;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? b : a;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IFeeCurve {
    function setAddresses(address _controllerAddress) external;

    function setDecayTime(uint _decayTime) external;

    function setDollarCap(uint _dollarCap) external;

    function initialized() external view returns (bool);

    /** 
     * Returns fee based on inputted collateral VC balance and total VC balance of system. 
     * fee is in terms of percentage * 1e18. 
     * If the fee were 1%, this would be 0.01 * 1e18 = 1e16
     */
    function getFee(uint256 _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external view returns (uint256 fee);

    // Same function, updates the fee as well. Called only by controller.
    function getFeeAndUpdate(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external returns (uint256 fee);

    // Function for setting the old fee curve's last fee cap / value to the new fee cap / value. 
    // Called only by controller.
    function setFeeCapAndTime(uint256 _lastFeePercent, uint256 _lastFeeTime) external;

    // Gets the fee cap and time currently. Used for setting new values for next fee curve. 
    // returns lastFeePercent, lastFeeTime
    function getFeeCapAndTime() external view returns (uint256 _lastFeePercent, uint256 _lastFeeTime);

    /** 
     * Returns fee based on decay since last fee calculation, which we take to be 
     * a reasonable fee amount. If it has decayed a certain amount since then, we let
     * the new fee amount slide. 
     */
    function calculateDecayedFee() external view returns (uint256 fee);
}