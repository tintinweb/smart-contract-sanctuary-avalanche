// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.12;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.12;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = "33"; // 'The caller must be the pool admin'
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = "59"; // User borrows on behalf, but allowance are too small

  //contract specific errors
  string public constant VL_INVALID_AMOUNT = "1"; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = "2"; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = "3"; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = "4"; // 'The current liquidity is not enough'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "5"; // 'User cannot withdraw more than the available balance'
  string public constant VL_TRANSFER_NOT_ALLOWED = "6"; // 'Transfer cannot be allowed.'
  string public constant VL_BORROWING_NOT_ENABLED = "7"; // 'Borrowing is not enabled'
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = "8"; // 'Invalid interest rate mode selected'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = "9"; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "10"; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "11"; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = "12"; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = "13"; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "14"; // 'The requested amount is greater than the max loan size in stable rate mode
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "15"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "16"; // 'To repay on behalf of an user an explicit amount to repay is needed'
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = "17"; // 'User does not have a stable rate loan in progress on this reserve'
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = "18"; // 'User does not have a variable rate loan in progress on this reserve'
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = "19"; // 'The underlying balance needs to be greater than 0'
  string public constant VL_DEPOSIT_ALREADY_IN_USE = "20"; // 'User deposit is already being used as collateral'
  string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = "21"; // 'User does not have any stable rate loan for this reserve'
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "22"; // 'Interest rate rebalance conditions were not met'
  string public constant LP_LIQUIDATION_CALL_FAILED = "23"; // 'Liquidation call failed'
  string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = "24"; // 'There is not enough liquidity available to borrow'
  string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = "25"; // 'The requested amount is too small for a FlashLoan.'
  string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = "26"; // 'The actual balance of the protocol is inconsistent'
  string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = "27"; // 'The caller of the function is not the lending pool configurator'
  string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = "28";
  string public constant CT_CALLER_MUST_BE_LENDING_POOL = "29"; // 'The caller of this function must be a lending pool'
  string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = "30"; // 'User cannot give allowance to himself'
  string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = "31"; // 'Transferred amount needs to be greater than zero'
  string public constant RL_RESERVE_ALREADY_INITIALIZED = "32"; // 'Reserve has already been initialized'
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "34"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = "35"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = "36"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = "37"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "38"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "39"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = "40"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_CONFIGURATION = "75"; // 'Invalid risk parameters for the reserve'
  string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "76"; // 'The caller must be the emergency admin'
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = "41"; // 'Provider is not registered'
  string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "42"; // 'Health factor is not below the threshold'
  string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = "43"; // 'The collateral chosen cannot be liquidated'
  string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "44"; // 'User did not borrow the specified currency'
  string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = "45"; // "There isn't enough liquidity available to liquidate"
  string public constant LPCM_NO_ERRORS = "46"; // 'No errors'
  string public constant LP_INVALID_FLASHLOAN_MODE = "47"; //Invalid flashloan mode selected
  string public constant MATH_MULTIPLICATION_OVERFLOW = "48";
  string public constant MATH_ADDITION_OVERFLOW = "49";
  string public constant MATH_DIVISION_BY_ZERO = "50";
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "51"; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "52"; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = "53"; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "54"; //  Variable borrow rate overflows uint128
  string public constant RL_STABLE_BORROW_RATE_OVERFLOW = "55"; //  Stable borrow rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = "56"; //invalid amount to mint
  string public constant LP_FAILED_REPAY_WITH_COLLATERAL = "57";
  string public constant CT_INVALID_BURN_AMOUNT = "58"; //invalid amount to burn
  string public constant LP_FAILED_COLLATERAL_SWAP = "60";
  string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = "61";
  string public constant LP_REENTRANCY_NOT_ALLOWED = "62";
  string public constant LP_CALLER_MUST_BE_AN_ATOKEN = "63";
  string public constant LP_IS_PAUSED = "64"; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = "65";
  string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = "66";
  string public constant RC_INVALID_LTV = "67";
  string public constant RC_INVALID_LIQ_THRESHOLD = "68";
  string public constant RC_INVALID_LIQ_BONUS = "69";
  string public constant RC_INVALID_DECIMALS = "70";
  string public constant RC_INVALID_RESERVE_FACTOR = "71";
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "72";
  string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = "73";
  string public constant LP_INCONSISTENT_PARAMS_LENGTH = "74";
  string public constant UL_INVALID_INDEX = "77";
  string public constant LP_NOT_CONTRACT = "78";
  string public constant SDT_STABLE_DEBT_OVERFLOW = "79";
  string public constant SDT_BURN_EXCEEDS_BALANCE = "80";

  enum CollateralManagerErrors {
    NO_ERROR,
    NO_COLLATERAL_AVAILABLE,
    COLLATERAL_CANNOT_BE_LIQUIDATED,
    CURRRENCY_NOT_BORROWED,
    HEALTH_FACTOR_ABOVE_THRESHOLD,
    NOT_ENOUGH_LIQUIDITY,
    NO_ACTIVE_RESERVE,
    HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
    INVALID_EQUAL_ASSETS_TO_SWAP,
    FROZEN_RESERVE
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.12;

interface IAToken {

  /**
   * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.12;

import {DataTypes} from "./DataTypes.sol";

/**
 * @dev refer to https://github.com/aave/protocol-v2
 **/
interface ILendingPool {
  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
  
  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.12;

import {Errors} from "./Errors.sol";

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
    return result;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/// @dev refer to https://github.com/compound-finance/compound-protocol
interface CTokenInterface {
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
}

interface CErc20Interface {
    /**
     * @notice Underlying asset for this CToken
     */
    function underlying() external returns (address);
    function redeem(uint redeemTokens) external returns (uint);
    function mint(uint mintAmount) external returns (uint);
}

interface CEtherInterface {
    function mint() external payable;
}

abstract contract CErc20 is CTokenInterface, CErc20Interface {
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface ICurveExchange {
    // function exchange_with_best_rate(
    //     address _from,
    //     address _to,
    //     uint256 _amount,
    //     uint256 _expected,
    //     address _receiver
    // ) external payable returns (uint256);

    // function exchange_multiple(
    //     address[9] memory _route,
    //     uint256[3][4] memory _swap_params,
    //     uint256 _amount,
    //     uint256 _expected
    // ) external payable returns (uint256);

    function exchange(
        address _pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);
}

interface ICurveAddressProvider {
    function get_address(uint256 _id) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @dev refer to https://github.com/Uniswap/v3-core/tree/0.8 & https://github.com/Uniswap/v3-periphery/tree/0.8
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);
}

interface INonfungiblePositionManager is IPeripheryImmutableState {
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

interface IUniswapV3Pool is IUniswapV3PoolState {
}

interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./FullMath.sol";
import "./FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                FullMath.mulDiv(
                    uint256(liquidity) << FixedPoint96.RESOLUTION,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    sqrtRatioBX96
                ) / sqrtRatioAX96;
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../interfaces/ILiquidationProtocol.sol";

interface IInfinityPool {

	/*

	action types
	public static final int SOURCE_WEB = 1;
	public static final int SOURCE_ETHERERUM = 2;
	
	public static final int TYPE_DEPOSIT = 1;
	public static final int TYPE_WITHDRAWL = 2;
	public static final int TYPE_WITHDRAWL_FAST = 3;
	public static final int TYPE_TRANSFER = 4;
	
	public static final int TYPE_BORROW = 10;
	public static final int TYPE_PAYBACK = 11;
	
	public static final int TYPE_CREATE_EXCHANGE_LIQUIDITY_POSITION = 20;
	public static final int TYPE_UPDATE_EXCHANGE_LIQUIDITY_POSITION = 21;
	public static final int TYPE_REMOVE_EXCHANGE_LIQUIDITY_POSITION = 22;
	public static final int TYPE_EXCHANGE = 23;
	public static final int TYPE_EXCHANGE_LARGE_ORDER = 24;

	*/

	struct TokenTransfer {
		address token;
		uint256 amount;
	}
	struct TokenUpdate {
		uint256 tokenId; // might be prepended with wallet type (e.g. interest bearing wallets)
		uint256 amount; // absolute value - should always be unsigned
		bool isERC721; // to avoid high gas usage from checking erc721 
		uint64 priceIndex;
	}

	struct Action {
		uint256 action;
		uint256[] parameters;
	}

	struct ProductVariable {
		uint64 key;
		int64 value;
	}

	struct PriceIndex {
		uint256 key;
		uint64 value;
	}



	event WithdrawalRequested(
		address indexed sender,
		TokenTransfer[] transfers
	);

	event ProductVariablesUpdated(
		ProductVariable[] variables
	);
	event PriceIndexesUpdated(
		PriceIndex[] priceIndexes
	);

	event LiquidationProtocolRegistered(
		address indexed protocolAddress
	);


	
	event ServerLiquidateSuccess(
		address indexed clientAddress,
		address tokenFrom,
		uint256 amountIn,
		ILiquidationProtocol.LiquidatedAmount[] amounts
	);
	
	function version() external pure returns(uint v);

	function deposit(
		TokenTransfer[] memory tokenTranfers,
		Action[] calldata actions
	) external payable;

	function requestWithdraw(TokenTransfer[] calldata tokenTranfers) external;

	function action(Action[] calldata actions) external;

	// function balanceOf(address clientAddress, uint tokenId) external view returns (uint);

	// function productVariable(uint64 id) external view returns (int64);

	event DepositsOrActionsTriggered(
		address indexed sender,
		TokenTransfer[] transfers, 
		Action[] actions
	);


	function priceIndex(uint256 tokenId) external view returns (uint64);

	function serverTransferFunds(address clientAddress, TokenTransfer[] calldata tokenTranfers) external;

	function serverUpdateBalances(
		address[] calldata clientAddresses, TokenUpdate[][] calldata tokenUpdates, 
		PriceIndex[] calldata priceIndexes
	) external;

	// function serverUpdateProductVariables(
	// 	ProductVariable[] calldata productVariables
	// ) external;

	function serverLiquidate(
		address _clientAddress,
		uint64[] memory _protocolIds,
		address[] memory _paths,
		uint256 _amountIn,
		uint256[] memory _amountOutMins,
		uint24[] memory _uniswapPoolFees,
		address[] memory _curvePoolAddresses
	) external;


	//TODO: add interface
	//Emergency functions
	event EmergencyWithdrew(
		address indexed clientAddress,
		TokenTransfer[]
	);

	event Withdrawal(
		address indexed clientAddress,
		TokenTransfer tokenTranfer,
		bool isCompleted
	);
	
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface ILiquidationProtocol {

	struct LiquidateParams {
		address clientAddress;
		address tokenFrom;
		address tokenTo;
		uint256 amountIn; // for ERC721: amountIn is tokenId
		uint256 amountOutMin;
		uint24 poolFee;
		address curvePoolAddress;
	}

	struct LiquidatedAmount {
		address token;
		uint256 amount;
	}
	
	function swap(
		LiquidateParams calldata lparams
	) external returns (LiquidatedAmount[] memory amounts);
	
	// function getApproveAmount(
	// 	LiquidateParams calldata lparams
	// ) external returns (uint256 amountOut,address approveFrom);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IPoolAddressesProvider {

    function wethAddress() external view returns(address);
    function aclManagerAddress() external view returns(address);
    function infinityTokenAddress() external view returns(address);
    function liquidationProtocolAddresses(uint64 protocolId) external view returns(address);
    function getInfinitySupportedTokens() external view returns (address[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library TransferHelper {
    function safeApprove( address token, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("approve(address,uint256)", to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "approve failed" );
    }

    function safeTransferFrom( address token, address from, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "transferFrom failed" );
    }

    function safeTransfer( address token, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "transfer failed" );
    }

    function safeTransferFromERC721( address token, address from, address to, uint256 tokenId ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", from, to, tokenId));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "ERC721 safeTransferFrom failed" );
    }

    function balanceOf( address token, address account ) public returns (uint256 balance){
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("balanceOf(address)", account));
        require(success,"balanceOf failed");
        balance = abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import { ILendingPool } from "../dependencies/aave-v2/ILendingPool.sol";
import { DataTypes } from "../dependencies/aave-v2/DataTypes.sol";
import { WadRayMath } from "../dependencies/aave-v2/WadRayMath.sol";
import { IAToken } from "../dependencies/aave-v2/IAToken.sol";
import { ILiquidationProtocol } from "../interfaces/ILiquidationProtocol.sol";
// import "hardhat/console.sol";

library LiquidationAaveV2 {
    using WadRayMath for uint256;

    ILendingPool public constant lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    /// @notice swap swaps token on aave v2.
    /// @dev check https://docs.aave.com/developers/v/2.0/guides/troubleshooting-errors#reference-guide for error codes from lendingPool.withdraw()
    /// @param lparams check ILiquidationProtocol.LiquidateParams for params struct.
    /// @return amounts The amount of target token received.
	function swap(
		ILiquidationProtocol.LiquidateParams calldata lparams
	) external returns (ILiquidationProtocol.LiquidatedAmount[] memory amounts){

        require(lparams.tokenTo == IAToken(lparams.tokenFrom).UNDERLYING_ASSET_ADDRESS(), "tokenTo is not underlying asset");
        uint amountOut = lendingPool.withdraw(IAToken(lparams.tokenFrom).UNDERLYING_ASSET_ADDRESS(), lparams.amountIn, address(this));
        amounts = new ILiquidationProtocol.LiquidatedAmount[](1);
        amounts[0] = ILiquidationProtocol.LiquidatedAmount(lparams.tokenTo, amountOut);

	}

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../dependencies/compound-v2/ICompound.sol";
import "../interfaces/ILiquidationProtocol.sol";
import "../interfaces/IWETH.sol";
// openzeppelin contracts v4.7.3
import "../dependencies/openzeppelin/contracts/utils/Strings.sol";
// import "hardhat/console.sol";

library LiquidationCompoundV2 {
    IWETH public constant weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice swap swaps token on compound
    /// @param lparams check ILiquidationProtocol.LiquidateParams for params struct.
    /// @return amounts The amount of target token received.
	function swap(
		ILiquidationProtocol.LiquidateParams memory lparams
	) external returns (ILiquidationProtocol.LiquidatedAmount[] memory amounts){

        CErc20 cToken = CErc20(lparams.tokenFrom);
        if (lparams.tokenTo != address(weth)) {
            require(lparams.tokenTo == cToken.underlying(), "tokenTo is not underlying");
            require(cToken.underlying() != address(0) ,"tokenFrom is not cToken");
        }

        uint errorCode = cToken.redeem(lparams.amountIn); // ref: https://compound.finance/docs/ctokens#error-codes
        require(errorCode == 0,Strings.toString(errorCode));

        uint amountOut = lparams.amountIn * cToken.exchangeRateStored() / 1e18; // refer to CToken.balanceOfUnderlying(address)
        require(amountOut >= lparams.amountOutMin, "not enough amountOutMin");
        if (lparams.tokenTo == address(weth)) {
            weth.deposit{value: amountOut}();
        }

        amounts = new ILiquidationProtocol.LiquidatedAmount[](1);
        amounts[0] = ILiquidationProtocol.LiquidatedAmount(lparams.tokenTo, amountOut);
	}

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../interfaces/ILiquidationProtocol.sol";
// import "hardhat/console.sol";

library LiquidationCurveLP {


    address public constant _addrProvider = 0x0000000022D53366457F9d5E68Ec105046FC4383;
    
    /// @notice swap token on curve
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
    /// @param lparams check ILiquidationProtocol.LiquidateParams for params struct
    /// @return amounts The amount of target token received.
	function swap(
		ILiquidationProtocol.LiquidateParams memory lparams
	) external returns (ILiquidationProtocol.LiquidatedAmount[] memory amounts){
        (bool success,bytes memory data) = _addrProvider.call(abi.encodeWithSelector(0xa262904b)); // bytes4(keccak256(bytes("get_registry()")))
        address registry = abi.decode(data,(address));
        require(success&&registry!=address(0x00),"registry not found");
        (success,data) = registry.call(abi.encodeWithSelector(0xbdf475c3,lparams.tokenFrom)); // bytes4(keccak256(bytes("get_pool_from_lp_token(address)")))
        address pool = abi.decode(data,(address));
        require(success&&pool!=address(0x00),"LP token pool not found");
        // console.log("pool");
        // console.log(pool);
        (success,data) = registry.call(abi.encodeWithSelector(0x940494f1,pool)); // bytes4(keccak256(bytes("get_n_coins(address)")))
        uint256[] memory minAmounts = new uint256[](abi.decode(data,(uint256[2]))[1]); for(uint256 i=0;i<minAmounts.length;i++){minAmounts[i]=0;}
        // console.log("coinCounts");
        // console.log(coinCounts[0]);
        // console.log(coinCounts[1]);
        require(success,"get_n_coins(address) failed");
        (success,data) = registry.call(abi.encodeWithSelector(0xa77576ef,pool)); // bytes4(keccak256(bytes("get_underlying_coins(address)")))
        address[8] memory coins = abi.decode(data,(address[8]));
        require(success&&coins.length>0,"pool coins not found");
        int256 coinIdx = -1;
        for(uint256 i=0;i<coins.length;i++){
            // console.log(coins[i]);
            if(coins[i]==lparams.tokenTo){
                coinIdx = int256(i);
            }
        }
        require(coinIdx!=-1,"tokenTo is not underlying asset");
        (success,data) = pool.call(abi.encodeWithSelector(bytes4(keccak256(bytes("calc_withdraw_one_coin(uint256,uint256)"))),lparams.amountIn,uint256(coinIdx))); // bytes4(keccak256(bytes("calc_withdraw_one_coin(uint256,uint256)")))
        if(!(success&&data.length>0)){ // retry with different signature cause curve can't keep their signatures straight
            (success,data) = pool.call(abi.encodeWithSelector(bytes4(keccak256(bytes("calc_withdraw_one_coin(uint256,int128)"))),lparams.amountIn,int128(coinIdx))); // bytes4(keccak256(bytes("calc_withdraw_one_coin(uint256,int128)")))
        }
        // console.logBytes(data);
        require(success&&data.length>0,"pool withdraw calc failed");
        (uint256 amountOut) = abi.decode(data,(uint256));
        // console.log("calc_withdraw_one_coin: amountOut");
        // console.log(amountOut);

        
        (success,data) = pool.call(abi.encodeWithSelector(bytes4(keccak256(bytes("remove_liquidity_one_coin(uint256,uint256,uint256)"))),lparams.amountIn,coinIdx,amountOut)); // bytes4(keccak256(bytes("remove_liquidity_one_coin(uint256,int128,uint256)")))
        if(!success){ // retry with different signature cause curve can't keep their signatures straight
            // uint128 call DOESNT throw error and cannot be checked by success==false
            (success,data) = pool.call(abi.encodeWithSelector(bytes4(keccak256(bytes("remove_liquidity_one_coin(uint256,int128,uint256)"))),lparams.amountIn,coinIdx,amountOut));
        }
        require(success,"pool withdraw failed");
        // NOTE: remove_liquidity fails - 3pool doesnt even return amount withdrawn so it's very inefficient to use anyways
        // (success,data) = pool.call(abi.encodeWithSelector(bytes4(keccak256(bytes(string.concat("remove_liquidity(uint256,uint256[",Strings.toString(minAmounts.length),"])")))),lparams.amountIn,minAmounts)); // bytes4(keccak256(bytes("remove_liquidity(uint256,uint256[])")))
        // require(success,"remove_liquidity failed");
        // for(uint256 i=0;i<coins.length;i++){
        //     if(coins[i]!=address(0x00)){
        //         uint256 balance = TransferHelper.balanceOf(lparams.tokenTo, coins[i]);
        //         console.log("remove_liquidity: coin balance");
        //         console.log(coins[i]);
        //         console.log(balance);
        //         TransferHelper.safeApprove(coins[i], address(msg.sender), balance);
        //         TransferHelper.safeTransfer(coins[i], address(msg.sender), balance);
        //     }
        // }

        amounts = new ILiquidationProtocol.LiquidatedAmount[](1);
        amounts[0] = ILiquidationProtocol.LiquidatedAmount(lparams.tokenTo,amountOut);
	}

	// function getApproveAmount(LiquidateParams memory lparams) pure external override returns (uint256 amountOut, address approveFrom) { amountOut = lparams.amountIn; approveFrom = lparams.tokenFrom; }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../libraries/TransferHelper.sol";
import "../interfaces/ILiquidationProtocol.sol";
import "../dependencies/curve/ICurve.sol";
import "../dependencies/uniswap-v3/IUniswap.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IInfinityPool.sol";

// import "hardhat/console.sol";

library LiquidationCurveSwap {

    address public constant curveAddrProvider = 0x0000000022D53366457F9d5E68Ec105046FC4383;
    IWETH public constant weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    /// @notice swap token on curve
    /// @param lparams check ILiquidationProtocol.LiquidateParams for params struct
    /// @return amounts The amount of target token received.
	function swap(
		ILiquidationProtocol.LiquidateParams memory lparams
	) external returns (ILiquidationProtocol.LiquidatedAmount[] memory amounts){
        require(lparams.curvePoolAddress != address(0x0), "curvePoolAddress 0x0");
        address curveExchangeAddress = ICurveAddressProvider(curveAddrProvider).get_address(2);
        TransferHelper.safeApprove(lparams.tokenFrom, curveExchangeAddress, lparams.amountIn);
        
        address tokenTo;
        if (lparams.tokenTo == address(weth)) {
            tokenTo = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        } else {
            tokenTo = lparams.tokenTo;
        }

        uint256 amountOut = ICurveExchange(curveExchangeAddress).exchange(
            lparams.curvePoolAddress,
            lparams.tokenFrom,
            tokenTo,
            lparams.amountIn, 
            lparams.amountOutMin,
            address(this)
        );
        require(amountOut >= lparams.amountOutMin, "not enough amountOutMin");

        if (lparams.tokenTo == address(weth)) {
            weth.deposit{value: amountOut}();
        }

        amounts = new ILiquidationProtocol.LiquidatedAmount[](1);
        amounts[0] = ILiquidationProtocol.LiquidatedAmount(lparams.tokenTo, amountOut);
    }
        
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../interfaces/ILiquidationProtocol.sol";
import "../interfaces/IPoolAddressesProvider.sol";
import "./LiquidationUniswapV3.sol";
import "./LiquidationAaveV2.sol";
import "./LiquidationUniswapLP.sol";
import "./LiquidationCompoundV2.sol";
import "./LiquidationCurveLP.sol";
import "./LiquidationCurveSwap.sol";
// import "hardhat/console.sol";

library LiquidationHelper {
	function liquidate(
		uint64[] memory _protocolIds,
		address[] memory _paths,
		uint256 _amountIn,
		uint256[] memory _amountOutMins,
		uint24[] memory _uniswapPoolFees,
		address[] memory _curvePoolAddresses
	) public returns (ILiquidationProtocol.LiquidatedAmount[] memory amounts) {
		uint256 amountIn;
		uint256 amountOut;
		for (uint256 i = 0; i < _protocolIds.length; i++) {
			require(_paths[i] != address(0x0), "path cannot be 0x0");
			if (i == 0) {
				amountIn = _amountIn;
			} else {
				amountIn = amountOut;
			}

			ILiquidationProtocol.LiquidateParams memory lparams;
			lparams.tokenFrom = _paths[i];
			lparams.tokenTo = _paths[i+1];
			lparams.amountIn = amountIn;
			lparams.amountOutMin = _amountOutMins[i];
			lparams.poolFee = _uniswapPoolFees[i];
			lparams.curvePoolAddress = _curvePoolAddresses[i];
			
			if (_protocolIds[i] == 0) {
				amounts = LiquidationUniswapV3.swap(lparams);
			} else if (_protocolIds[i] == 1) {
				amounts = LiquidationAaveV2.swap(lparams);
			} else if (_protocolIds[i] == 2) {
				amounts = LiquidationUniswapLP.swap(lparams);
			} else if (_protocolIds[i] == 3) {
				amounts = LiquidationCompoundV2.swap(lparams);
			} else if (_protocolIds[i] == 4) {
				amounts = LiquidationCurveLP.swap(lparams);
			} else if (_protocolIds[i] == 5) {
				amounts = LiquidationCurveSwap.swap(lparams);
			}
			// it ignores amounts[1].amount which may not be able to swap furter after liquidating UniswapV3 LP NFT 
			amountOut = amounts[0].amount;
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../interfaces/ILiquidationProtocol.sol";
import "../dependencies/uniswap-v3/LiquidityAmounts.sol";
import "../dependencies/uniswap-v3/TickMath.sol";
import "../dependencies/uniswap-v3/IUniswap.sol";
// import "./dependencies/uniswap/IUniswapV3Pool.sol";
// import "./dependencies/uniswap/IUniswapV3Factory.sol";
// import "./libraries/TransferHelper.sol";
// import "hardhat/console.sol";
// import "./interfaces/IERC20.sol";

library LiquidationUniswapLP{

    address public constant addrNonfungiblePositionManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    // local struct for storing variables to avoid "stack too deep" error
    struct TempStruct {
        uint160 sqrtPriceX96;
        uint160 sqrtRatioAX96;
        uint160 sqrtRatioBX96;
        uint256 amount0;
        uint256 amount1;
    }
    /// @notice swap remove liquidity from uniswap lp. only supports removal of full liquidity
    /// calls `DecreaseLiquidityParams` in the INonfungiblePositionManager.
    /// @param lparams check ILiquidationProtocol.LiquidateParams for params struct.
    /// @return amounts LiquidatedAmount[] The amount of target token received.
	function swap(
		ILiquidationProtocol.LiquidateParams memory lparams
	) external returns (ILiquidationProtocol.LiquidatedAmount[] memory amounts){
        (address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity) = _getPositions(lparams.amountIn);
        require(liquidity>0,"liquidity is 0");

        // amount0Min and amount1Min are price slippage checks
        // if the amount received after burning is not greater than these minimums, transaction will fail
        TempStruct memory t;
        (t.sqrtPriceX96, , , , , , ) = IUniswapV3Pool(
            IUniswapV3Factory(INonfungiblePositionManager(addrNonfungiblePositionManager).factory()).getPool(token0, token1, fee)
        ).slot0();
        t.sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        t.sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        (t.amount0, t.amount1) = LiquidityAmounts.getAmountsForLiquidity(t.sqrtPriceX96, t.sqrtRatioAX96, t.sqrtRatioBX96, liquidity);
        DecreaseLiquidityParams memory params =
            DecreaseLiquidityParams({
                tokenId: lparams.amountIn,
                liquidity: liquidity, // always remove all liquidity
                amount0Min: t.amount0 * 95 / 100,
                amount1Min: t.amount1 * 95 / 100,
                deadline: block.timestamp
            });
        
        (bool success,bytes memory data) = addrNonfungiblePositionManager.call(abi.encodeWithSelector(0x0c49ccbe,params)); // bytes4(keccak256(bytes("decreaseLiquidity((uint256,uint128,uint256,uint256,uint256))")))
        require(success&&data.length>0,string(data)); //"npm.decreaseLiquidity failed"
        // (uint256 amount0, uint256 amount1) = abi.decode(data,(uint256,uint256));

        // collect all and send to pool
        CollectParams memory params2 =
            CollectParams({
                tokenId: lparams.amountIn,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
        (success,data) = addrNonfungiblePositionManager.call(abi.encodeWithSelector(0xfc6f7865,params2)); // bytes4(keccak256(bytes("collect((uint256,address,uint128,uint128))")))
        require(success&&data.length>0,string(data)); //"npm.collectAllFees failed"
        (uint256 amount0, uint256 amount1) = abi.decode(data,(uint256,uint256));

        amounts = new ILiquidationProtocol.LiquidatedAmount[](2);
        amounts[0] = ILiquidationProtocol.LiquidatedAmount(token0,amount0);
        amounts[1] = ILiquidationProtocol.LiquidatedAmount(token1,amount1);
	}

	// function getApproveAmount(LiquidateParams memory lparams) pure external override returns (uint256 amountOut, address approveFrom) { 
    //     amountOut = lparams.amountIn; // tokenId
    //     approveFrom = lparams.tokenFrom;
    //     // (bool success,bytes memory data) = addrNonfungiblePositionManager.call(abi.encodeWithSelector(0x99fbab88,lparams.amountIn)); // bytes4(keccak256(bytes("positions(uint256)")))
    //     // require(success&&data.length>0,"npm.positions failed");
    //     // ( , , , , , , , uint128 liquidity) =  abi.decode(data,(uint96, address, address, address, uint24, int24, int24, uint128));
    //     // amountOut = liquidity; //lparams.amountIn; 
    // }

    function _getPositions(uint256 tokenId) private returns(address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity){
        (bool success,bytes memory data) = addrNonfungiblePositionManager.call(abi.encodeWithSelector(0x99fbab88,tokenId)); // bytes4(keccak256(bytes("positions(uint256)")))
        require(success&&data.length>0,"npm.positions failed");
        ( ,, token0, token1, fee, tickLower, tickUpper, liquidity) =  abi.decode(data,(uint96, address, address, address, uint24, int24, int24, uint128));
    }

    // TODO check if remove liquidity already calculates fees
    // /// @notice Collects the fees associated with provided liquidity
    // /// @dev The contract must hold the erc721 token before it can collect fees
    // /// @param tokenId The id of the erc721 token
    // /// @return amount0 The amount of fees collected in token0
    // /// @return amount1 The amount of fees collected in token1
    // function collectAllFees(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
    //     // Caller must own the ERC721 position, meaning it must be a deposit

    //     // set amount0Max and amount1Max to uint256.max to collect all fees
    //     // alternatively can set recipient to msg.sender and avoid another transaction in `sendToOwner`
    //     INonfungiblePositionManager.CollectParams memory params =
    //         INonfungiblePositionManager.CollectParams({
    //             tokenId: tokenId,
    //             recipient: address(this),
    //             amount0Max: type(uint128).max,
    //             amount1Max: type(uint128).max
    //         });

    //     (amount0, amount1) = nonfungiblePositionManager.collect(params);

    //     // send collected feed back to owner
    //     _sendToOwner(tokenId, amount0, amount1);
    // }


    // /// @notice Transfers the NFT to the owner
    // /// @param tokenId The id of the erc721
    // function retrieveNFT(uint256 tokenId) external {
    //     // must be the owner of the NFT
    //     require(msg.sender == deposits[tokenId].owner, "Not the owner");
    //     // transfer ownership to original owner
    //     nonfungiblePositionManager.safeTransferFrom(address(this), msg.sender, tokenId);
    //     //remove information related to tokenId
    //     delete deposits[tokenId];
    // }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../dependencies/uniswap-v3/IUniswap.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/ILiquidationProtocol.sol";
// import "hardhat/console.sol";

library LiquidationUniswapV3 {

	// @dev swap router address: refer https://docs.uniswap.org/protocol/reference/deployments
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    
    /// @notice swap swaps token on uniswap v3.
    /// calls `exactInputSingle` in the swap router.
    /// @param lparams check ILiquidationProtocol.LiquidateParams for params struct.
    /// @return amounts The amount of target token received.
	function swap(
		ILiquidationProtocol.LiquidateParams memory lparams
	) external returns (ILiquidationProtocol.LiquidatedAmount[] memory amounts){
        require(lparams.poolFee != 0, "poolFee is 0");
        TransferHelper.safeApprove(lparams.tokenFrom, address(swapRouter), lparams.amountIn);

        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: lparams.tokenFrom,
                tokenOut: lparams.tokenTo,
                fee: lparams.poolFee,
                recipient: address(this),
                deadline: block.timestamp*2,
                amountIn: lparams.amountIn,
                amountOutMinimum: lparams.amountOutMin,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = swapRouter.exactInputSingle(params);
        amounts = new ILiquidationProtocol.LiquidatedAmount[](1);
        amounts[0] = ILiquidationProtocol.LiquidatedAmount(lparams.tokenTo,amountOut);
	}
    
}