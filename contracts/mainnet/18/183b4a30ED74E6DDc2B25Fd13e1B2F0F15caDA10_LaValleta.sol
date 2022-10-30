// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;

// The following adapter allows the manager to invest in several stablecoins:
// USDC, USDC.e, USDT.e, DAI.e accross Alpha Homora V2.

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IDetailedERC20} from "./interfaces/IDetailedERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {ISafeBox} from "./interfaces/ISafeBox.sol";
import "./interfaces/IHomoraBank.sol";
import "./interfaces/IHomoraComptroller.sol";
import "./interfaces/IJoeRouter.sol";

contract LaValleta {

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IDetailedERC20;
    using SafeMath for uint256;

    uint256 public constant expScale = 1e18;

    struct AssetInfo {
        address ibAsset;
        address ironBank;
        uint256 decimals;
        uint256 capital;
        uint256 txCosts;
    }

    EnumerableSet.AddressSet internal _assets;
    mapping(address => AssetInfo) public assetInfo;

    address public Comptroller; // Address: 0x2eE80614Ccbc5e28654324a66A396458Fa5cD7Cc
    address public JoeRouter;

    address public manager; // Manager can allocate assets among different stablecoin pools.
    address public immutable caller; // Caller can deposit and withdraw externally.

    constructor(address _usdc, address _ibUSDC, address _usdcIronBank, address _comptroller, address _joeRouter, address _caller, address _manager) public {
        require(_usdc != address(0), "Error: Cannot be the null address");
        require(_ibUSDC != address(0), "Error: Cannot be the null address");
        require(_usdcIronBank != address(0), "Error: Cannot be the null address");
        require(_comptroller != address(0), "Error: Cannot be the null address");
        require(_joeRouter != address(0), "Error: Cannot be the null address");
        require(_caller != address(0), "Error: Cannot be the null address");
        require(_manager != address(0), "Error: Cannot be the null address");

        Comptroller = _comptroller;
        JoeRouter = _joeRouter;

        manager = _manager;
        caller = _caller;

        _addAssetAndEnterMarkets(_usdc, _ibUSDC, _usdcIronBank, IDetailedERC20(_usdc).decimals());
    }

    // Public methods.
    function token() external view returns (IDetailedERC20) {
        return IDetailedERC20(_assets.at(0));
    }

    function assetsLength() external view returns (uint256) {
        return _assets.length();
    }

    function getAssetAmount(address asset) public view returns (uint256 assetAmount, uint256 assetCapital, uint256 assetInterest) {
        require(_assets.contains(asset), "Error: Asset is not registered");

        address ibAsset = assetInfo[asset].ibAsset;
        address assetIronBank = assetInfo[asset].ironBank;
        //uint256 decimals = assetInfo[asset].decimals;

        uint256 ibBalance = IDetailedERC20(ibAsset).balanceOf(address(this));
        uint256 exchangeRate = IHomoraBank(assetIronBank).exchangeRateStored();
        
        assetAmount = _mulScalarTruncate(ibBalance, exchangeRate);
        assetCapital = assetInfo[asset].capital;

        if(assetAmount < assetCapital) {
            assetInterest = 0;
        } else {
            assetInterest = assetAmount.sub(assetCapital);
        }
    }

    function totalValue() external view returns (uint256) {
        uint256 totalAmount;
        uint256 totalAssets = _assets.length();

        address usdc = _assets.at(0);

        for (uint256 i = 0; i < totalAssets; i++) {
            address asset = _assets.at(i);
            (uint256 assetAmount,,) = getAssetAmount(asset); 
            uint256 decimals = assetInfo[asset].decimals;

            if(decimals > assetInfo[usdc].decimals) {
                assetAmount = assetAmount.div(10 ** (decimals.sub(assetInfo[usdc].decimals)));
            }
            
            totalAmount = totalAmount.add(assetAmount);
        }

        return totalAmount;
    }

    function portfolioShares() external view returns(address[] memory, uint256[] memory) {
        // Shares of total capital invested on each asset.
        uint256 totalAmount;
        uint256 totalAssets = _assets.length();

        address usdc = _assets.at(0);

        address[] memory assets = new address[](totalAssets);
        uint256[] memory shares = new uint256[](totalAssets);

        for(uint256 i = 0; i < totalAssets; i++) {
            address asset = _assets.at(i);
            uint256 assetAmount = assetInfo[asset].capital;
            uint256 assetDecimals = assetInfo[asset].decimals;

            if(assetDecimals > assetInfo[usdc].decimals) {
                assetAmount = assetAmount.div(10 ** (assetDecimals.sub(assetInfo[usdc].decimals)));
            }

            assets[i] = asset;
            shares[i] = assetAmount;

            totalAmount = totalAmount.add(assetAmount);
        }

        for(uint256 i = 0; i < totalAssets; i++) {
            shares[i] = (shares[i].mul(expScale)).div(totalAmount);
        }

        return (assets, shares);
    }







    // Caller methods
    function deposit(uint256 amount) external {
        require(msg.sender == caller, "Error: Msg sender is not allowed");

        address usdc = _assets.at(0);

        _adjustCapital(usdc);

        IDetailedERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        
        _deposit(usdc, amount, true);
    }

    function withdraw(address recipient, uint256 amount, bool isCapital) external {
        require(msg.sender == caller, "Error: Msg sender is not allowed");

        address usdc = _assets.at(0);

        _adjustCapital(usdc);
        _withdraw(usdc, recipient, amount, isCapital);
    }







    // Manager methods.
    function setManager(address _newManager) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(_newManager != address(0), "Error: Cannot be the null address");

        manager = _newManager;
    }

    function addAsset(address asset, address ibAsset, address assetIronBank) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(asset != address(0), "Error: Cannot be the null address");
        require(ibAsset != address(0), "Error: Cannot be the null address");
        require(assetIronBank != address(0), "Error: Cannot be the null address");

        require(assetInfo[asset].decimals == 0, "Error: Asset already registered");

        uint256 decimals = IDetailedERC20(asset).decimals();
        require(decimals >= assetInfo[_assets.at(0)].decimals, "Error: Less decimals than USDC");

        _addAssetAndEnterMarkets(asset, ibAsset, assetIronBank, decimals);
    }

    function allocate(address fromAsset, address toAsset, address[] memory path, uint256 amount) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");

        require(_assets.contains(fromAsset), "Error: Asset is not registered");
        require(_assets.contains(toAsset), "Error: Asset is not registered");
        require(path[path.length - 1] == toAsset, "Error: Asset is not swap output");

        uint256 amountBefore = IDetailedERC20(fromAsset).balanceOf(address(this));

        _adjustCapital(fromAsset);

        AssetInfo storage fromInfo =  assetInfo[fromAsset];
        AssetInfo storage toInfo =  assetInfo[toAsset];

        uint256 fromAssetCapitalBefore = fromInfo.capital;
        uint256 toAssetCapitalBefore = toInfo.capital;

        _withdraw(fromAsset, address(this), amount, true);
        uint256 amountAfter = IDetailedERC20(fromAsset).balanceOf(address(this));

        uint256 amountSwap = amountAfter.sub(amountBefore);

        IDetailedERC20(fromAsset).approve(JoeRouter, amountSwap);
        uint256[] memory _amounts = IJoeRouter(JoeRouter).swapExactTokensForTokens(amountSwap, 0, path, address(this), block.timestamp);

        _deposit(toAsset, _amounts[_amounts.length - 1], true);

        // Account tx costs.
        uint256 fromAssetCapitalAfter = fromInfo.capital;
        uint256 toAssetCapitalAfter = toInfo.capital;
    
        uint256 fromAssetDifference = fromAssetCapitalBefore.sub(fromAssetCapitalAfter);
        uint256 toAssetDifference = toAssetCapitalAfter.sub(toAssetCapitalBefore);

        if(fromInfo.decimals != toInfo.decimals) {
            fromAssetDifference = fromAssetDifference.mul(10 ** toInfo.decimals).div(10 ** fromInfo.decimals);
        }
        
        toInfo.txCosts = toInfo.txCosts.add(fromAssetDifference.sub(toAssetDifference));
    }

    function claimInterest(address asset, address[] memory path) external {
        // Collects interest amount from each pool and deposits it on the USDC pool.
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(_assets.contains(asset), "Error: Asset is not registered");

        uint256 totalAssets = _assets.length();

        uint256 usdcAmountBefore = IDetailedERC20(_assets.at(0)).balanceOf(address(this));

        for (uint256 i = 1; i < totalAssets; i++) {
            (uint256 assetCapital,) = _adjustCapital(_assets.at(i));

            // Quantify interest amount.
            address ibAsset = assetInfo[asset].ibAsset;
            address assetIronBank = assetInfo[asset].ironBank;

            uint256 cBalance = IDetailedERC20(ibAsset).balanceOf(address(this));
            uint256 exchangeRate = IHomoraBank(assetIronBank).exchangeRateCurrent();
            uint256 assetAmount = _mulScalarTruncate(cBalance, exchangeRate);

            uint256 interestAmount = assetAmount.sub(assetCapital);

            // Withdraw interest amount.
            _withdraw(asset, address(this), interestAmount, false);

            // Swap interest amount for USDC.
            IDetailedERC20(asset).approve(JoeRouter, interestAmount);
            IJoeRouter(JoeRouter).swapExactTokensForTokens(interestAmount, 0, path, address(this), block.timestamp);
        }

        // Deposit in USDC pool.
        uint256 usdcAmountAfter = IDetailedERC20(_assets.at(0)).balanceOf(address(this));
        _deposit(_assets.at(0), usdcAmountAfter.sub(usdcAmountBefore), false);
    }


    // Internal methods
    function _addAssetAndEnterMarkets(address _asset, address _ibAsset, address _ironBankAsset, uint256 _decimals) internal {
        _assets.add(_asset);
        assetInfo[_asset] = AssetInfo(_ibAsset, _ironBankAsset, _decimals, 0, 0);
        
        address[] memory assets = new address[](1);
        assets[0] = _ironBankAsset;

        //IHomoraComptroller(Comptroller).enterMarkets(assets);
        IDetailedERC20(_asset).approve(_ibAsset, type(uint256).max);
    }

    function _deposit(address _asset, uint256 _amount, bool isCapital) internal {
        require(_assets.contains(_asset), "Error: Asset is not registered");

        AssetInfo storage _info = assetInfo[_asset];

        address ibAsset = assetInfo[_asset].ibAsset;
        //uint256 status = IHomoraBank(assetBank).mint(_amount);
        ISafeBox(ibAsset).deposit(_amount);

        if(_info.capital > 0) {
            _adjustCapital(_asset);
        }

        if(isCapital) {
            _info.capital = _info.capital.add(_amount);
        }
    }
    
    function _withdraw(address _asset, address _recipient, uint256 _amount, bool isCapital) internal {
        require(_assets.contains(_asset), "Error: Asset is not registered");

        AssetInfo storage _info = assetInfo[_asset];

        address ibAsset = _info.ibAsset;
        uint256 exchangeRate = IHomoraBank(_info.ironBank).exchangeRateCurrent();
        uint256 ibAmount = _divScalarTruncate(_amount, exchangeRate);

        uint256 uBalanceBefore = IDetailedERC20(_asset).balanceOf(address(this));

        //IHomoraBank(assetBank).redeemUnderlying(_amount);
        ISafeBox(ibAsset).withdraw(ibAmount);

        uint256 uBalanceAfter = IDetailedERC20(_asset).balanceOf(address(this));

        uint256 uBalanceDiff = uBalanceAfter.sub(uBalanceBefore);

        if(isCapital) {
            _info.capital = _info.capital.sub(uBalanceDiff);
        } else {
            (, uint256 interestAmount,) = getAssetAmount(_asset); 
            
            if(_amount > interestAmount) {
                _amount = interestAmount;
            }
        }

        if(_recipient != address(this)) {
            IDetailedERC20(_asset).safeTransfer(_recipient, uBalanceDiff);
        }
    }
    
    function _divScalarTruncate(uint256 _uAmount, uint256 _exchangeRate) internal pure returns (uint256) {
        uint256 numerator = _uAmount.mul(expScale);
        uint256 fraction = numerator.div(_exchangeRate);

        return fraction;
    }
    
    function _mulScalarTruncate(uint256 _cAmount, uint256 _exchangeRate) internal pure returns (uint256) {
        uint256 product = _cAmount.mul(_exchangeRate);

        return product.div(expScale);
    }

    function _adjustCapital(address _asset) internal returns (uint256, uint256) {
        // Should return new capital amount + new tx costs amount.
        AssetInfo storage _info = assetInfo[_asset];

        if(_info.txCosts > 0) {
            // Here we should adjust amount.
            uint256 cBalance = IDetailedERC20(_info.ibAsset).balanceOf(address(this));
            uint256 exchangeRate = IHomoraBank(_info.ironBank).exchangeRateCurrent();
            uint256 assetAmount = _mulScalarTruncate(cBalance, exchangeRate);

            uint256 gains = 0;

            if (assetAmount > _info.capital) {
                gains = assetAmount.sub(_info.capital);
            }

            if(gains > _info.txCosts) {
                _info.capital = _info.capital.add(_info.txCosts);
                _info.txCosts = 0;

            } else if (gains > 0) {
                _info.capital = _info.capital.add(gains);
                _info.txCosts = _info.txCosts.sub(gains);

            }
        }

        return (_info.capital, _info.txCosts);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDetailedERC20 is IERC20 {
  function name() external returns (string memory);
  function symbol() external returns (string memory);
  function decimals() external returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;

import {IDetailedERC20} from "./IDetailedERC20.sol";

interface ISafeBox is IDetailedERC20 {
     function deposit(uint amount) external;
     function withdraw(uint amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;

interface IHomoraBank {
    function exchangeRateCurrent() external returns(uint256);
    function exchangeRateStored() external view returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;

interface IHomoraComptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IJoeRouter {
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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