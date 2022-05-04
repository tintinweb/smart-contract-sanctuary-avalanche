/**
 *Submitted for verification at snowtrace.io on 2022-05-04
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}


// File contracts/libraries/Config.sol

/**
 *  @title  Constant
 *
 *  @author 420 DAO Team
 *
 *  @notice This library provides most of constants used in smart contracts among the project.
 */
library Constant {
    /**
     *  @notice Refer to how divisible one token 420 or s420 can be.
     */
    uint8   internal constant TOKEN_DECIMALS = 18;
    uint256 internal constant TOKEN_SCALE = 10**TOKEN_DECIMALS;

    /**
     *  @notice Once total supply surpassed this threshold, auction will stop permanently.
     *          The threshold is 420 million tokens.
     */
    uint256 internal constant TOKEN_MAX_SUPPLY_THRESHOLD = 420000000 * TOKEN_SCALE;

    /**
     *  @notice Cash come to the Treasury are split as following:
     *          - Asset Fund:     50%
     *          - Insurance Fund: 30%
     *          - Operation Fund: 20%
     */
    uint256 internal constant TREASURY_PERCENTAGE_ASSET     = 50;
    uint256 internal constant TREASURY_PERCENTAGE_INSURANCE = 30;

    /**
     *  @notice Tokens come to the Mirror Pool are split as following:
     *          - Development & Marketing: 30%
     *          - Early Supporters:        10%
     *          - Reservation:             60%
     */
    uint256 internal constant MIRROR_PERCENTAGE_EARLY_SUPPORTERS = 10;
    uint256 internal constant MIRROR_PERCENTAGE_RESERVATION      = 60;

    /**
     *  @notice Formula of the staking fee: (1 - i / 787) * 42%
     */
    uint256 internal constant STAKING_FEE_CONVERGENCE_DAY = 787;
    uint256 internal constant STAKING_FEE_BASE_PERCENTAGE = 42;

    /**
     *  @notice Formula of the soft floor price in auctions: 2 * A / Q / 80%
     *          80% is sum of asset fund percentage and insurance fund percentage in the Treasury.
     */
    uint256 internal constant AUCTION_SOFT_FLOOR_PRICE_COEFFICIENT = 200;

    /**
     *  @notice The maximum tokens sold and the maximum cash a member of the whitelist can pay to buy during the
     *          whitelist campaign.
     */
    uint256 public constant WHITELIST_TOKEN_AMOUNT = 50000;
    uint256 public constant WHITELIST_MAX_CASH = 500;
}

/**
 *  @title  Double Halving
 *
 *  @author 420 DAO Team
 *
 *  @notice This library defines the mechanism of each token inflation phase of the DAO. There are 5 phases. The first
 *          phase lasts 420 days, emits at most 100,000 tokens in each auction and rewards at most 220,000 tokens (not
 *          including fee) for stakeholders each day. The next 3 phases sequentially remains half in duration, auction
 *          emission and staking reward, compared to each previous one. The fifth phase has the same auction emission
 *          and staking reward as the fourth but lasts as long as the total supply has never surpassed the maximum
 *          threshold.
 *  @notice Despite having a difference in staking fee, the fourth phase and the fifth phases can be considered the same
 *          for the implementation here.
 */
library DoubleHalving {
    /**
     *  @notice The last date of each phase.
     *          Phase   Duration    Last date
     *          1       420         420
     *          2       210         630
     *          3       105         735
     */
    uint256 internal constant PHASE_1 =  420;
    uint256 internal constant PHASE_2 =  630;
    uint256 internal constant PHASE_3 =  735;

    /**
     *  @notice The maximum token amount emitted to each auction.
     */
    uint256 internal constant AUCTION_EMISSION_1 = 100000;
    uint256 internal constant AUCTION_EMISSION_2 =  50000;
    uint256 internal constant AUCTION_EMISSION_3 =  25000;
    uint256 internal constant AUCTION_EMISSION_4 =  12500;

    /**
     *  @notice The maximum amount of staking reward each day.
     */
    uint256 internal constant STAKING_REWARD_1 = 220000;
    uint256 internal constant STAKING_REWARD_2 = 110000;
    uint256 internal constant STAKING_REWARD_3 =  55000;
    uint256 internal constant STAKING_REWARD_4 =  27000;

    /**
     *  @notice Get the maximum auction emission and the staking reward of a certain day.
     *          Type: tuple(int, int)
     *          Usage: DaoManager
     *
     *          Name    Meaning
     *  @param  _day    The day to query with
     */
    function tokenInflationOf(uint256 _day) internal pure returns (uint256, uint256) {
        if (_day <= PHASE_1) return (AUCTION_EMISSION_1 * Constant.TOKEN_SCALE, STAKING_REWARD_1 * Constant.TOKEN_SCALE);
        if (_day <= PHASE_2) return (AUCTION_EMISSION_2 * Constant.TOKEN_SCALE, STAKING_REWARD_2 * Constant.TOKEN_SCALE);
        if (_day <= PHASE_3) return (AUCTION_EMISSION_3 * Constant.TOKEN_SCALE, STAKING_REWARD_3 * Constant.TOKEN_SCALE);
        return (AUCTION_EMISSION_4 * Constant.TOKEN_SCALE, STAKING_REWARD_4 * Constant.TOKEN_SCALE);
    }
}


// File contracts/libraries/MulDiv.sol

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library MulDiv {
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
            uint256 twos = (~denominator + 1) & denominator;
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
            // correct result modulo 2**256. Since the preconditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        }
        return result;
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
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}


// File contracts/libraries/Fixed.sol

/**
 *  @title  Fixed
 *
 *  @author 420 DAO Team
 *
 *  @notice This struct displays a unsigned fixed-point decimal number.
 */
struct Fixed {
    /**
     *  @dev    The property `value` has 256 bits whose 128 first bits contain the integer part and 128 last bits contain
     *          the fractional part. In other words, `value` will be the truncation of the original decimal times 2^128.

     */
    uint256 value;
}

/**
 *  @title  Fixed Math
 *
 *  @author 420 DAO Team
 *
 *  @notice This library provides basic operators of `Fixed` utilizing the library `MulDiv`.
 *
 *  @dev    Any of these function can cause revert if the result exceeds `Fixed` boundary.
 */
library FixedMath {
    /**
     *  @notice Quotient of `Fixed`.
     *
     *  @dev    Q = 2^128.
     */
    uint256 private constant Q = 0x100000000000000000000000000000000;

    /**
     *  @notice Get number 1 as `Fixed`.
     *
     *  @dev    Its `value` is equal to `Q`.
     */
    function one() internal pure returns (Fixed memory) {
        return Fixed(Q);
    }

    /**
     *  @notice Get `Fixed` instance of an `uint256`.
     */
    function intToFixed(uint256 _x) internal pure returns (Fixed memory) {
        return Fixed(_x * Q);
    }

    /**
     *  @notice Get truncated value from a `Fixed`.
     */
    function fixedToInt(Fixed memory _x) internal pure returns (uint256) {
        return _x.value / Q;
    }

    /**
     *  @notice Comparison
     *
     *  @dev    Comparison  Result
     *          x < y       -1
     *          x = y       0
     *          x > y       1
     */
    function compare(Fixed memory _x, Fixed memory _y) internal pure returns (int256) {
        if (_x.value < _y.value) return -1;
        if (_x.value > _y.value) return 1;
        return 0;
    }

    /**
     *  @notice Addition
     */
    function add(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(_a.value + _b.value);
    }

    /**
     *  @notice Subtraction
     */
    function subtract(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(_a.value - _b.value);
    }

    /**
     *  @notice Multiplication
     */
    function multiply(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(MulDiv.mulDiv(_a.value, _b.value, Q));
    }

    function multiply(Fixed memory _a, uint256 _b) internal pure returns (Fixed memory) {
        return Fixed(_a.value * _b);
    }

    function multiply(uint256 _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(_a * _b.value);
    }

    function multiplyTruncating(Fixed memory _a, uint256 _b) internal pure returns (uint256) {
        return MulDiv.mulDiv(_a.value, _b, Q);
    }

    function multiplyTruncating(uint256 _a, Fixed memory _b) internal pure returns (uint256) {
        return MulDiv.mulDiv(_a, _b.value, Q);
    }

    /**
     *  @notice Division
     */
    function divide(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        require(_b.value != 0, "FixedMath: Division by zero.");
        return Fixed(MulDiv.mulDiv(_a.value, Q, _b.value));
    }

    function divide(uint256 _a, uint256 _b) internal pure returns (Fixed memory) {
        require(_b != 0, "FixedMath: Division by zero.");
        return Fixed(MulDiv.mulDiv(_a, Q, _b));
    }

    function divide(Fixed memory _a, uint256 _b) internal pure returns (Fixed memory) {
        require(_b != 0, "FixedMath: Division by zero.");
        return Fixed(_a.value / _b);
    }
}


// File contracts/libraries/Formula.sol

/**
 *  @title  Formula
 *
 *  @author 420 DAO Team
 *
 *  @notice Each function of this library is the implementation of a featured mathematical formula used in the system.
 */
library Formula {
    using FixedMath for Fixed;
    using FixedMath for uint256;

    /**
     *  @notice Calculate the truncated value of a certain portion of an integer amount.
     *          Formula:    truncate(x / y * a)
     *          Type:       int
     *          Usage:      AuctionManager, MirrorPool, TreasuryManager
     *
     *  @dev    The proportion (x / y) must be less than or equal to 1.
     *
     *          Name    Symbol  Type    Meaning
     *  @param  _x      x       int     Numerator of the proportion
     *  @param  _y      y       int     Denominator of the proportion
     *  @param  _a      a       int     Whole amount
     */
    function portion(uint256 _x, uint256 _y, uint256 _a) internal pure returns (uint256 res) {
        require(_x <= _y, "Formula: The proportion must be less than or equal to 1.");
        Fixed memory proportion = _x.divide(_y);
        res = _a.multiplyTruncating(proportion);
    }

    /**
     *  @notice Calculate the staking fee rate of a certain day before the fee converges and becomes unchangeable.
     *          Formula:    (1 - i / 787) * 42%
     *          Type:       dec
     *          Usage:      StakingPool
     *
     *  @dev    The day (i) must be less than or equal to the convergent day.
     *  @dev    Constant: STAKING_FEE_CONVERGENCE_DAY = 787
     *  @dev    Constant: STAKING_FEE_BASE_PERCENTAGE = 42
     *
     *          Name    Symbol  Type    Meaning
     *  @param  _day    i       int     integer Day to calculate fee
     */
    function earlyFeeRate(uint256 _day) internal pure returns (Fixed memory res) {
        require(
            _day <= Constant.STAKING_FEE_CONVERGENCE_DAY,
            "Formula: The day is greater than the convergent day."
        );
        // (1 - i / 787) * 42% = (787 - i) * 42 / 78700
        res = FixedMath.divide(
            (Constant.STAKING_FEE_CONVERGENCE_DAY - _day) * Constant.STAKING_FEE_BASE_PERCENTAGE,
            Constant.STAKING_FEE_CONVERGENCE_DAY * 100
        );
    }

    /**
     *  @notice Calculate the accumulated interest rate in the staking pool when an amount of staking reward is emitted.
     *          Formula:    P * (1 + r / a)
     *          Type:       dec
     *          Usage:      StakingPool
     *
     *          Name                    Symbol  Type    Meaning
     *  @param  _productOfInterestRate  P       dec     Accumulated interest rate in the staking pool
     *  @param  _reward                 r       int     Staking reward
     *  @param  _totalCapital           a       int     Total staked capital
     */
    function newProductOfInterestRate(
        Fixed memory _productOfInterestRate,
        uint256 _reward,
        uint256 _totalCapital
    ) internal pure returns (Fixed memory res) {
        Fixed memory interestRate = FixedMath.one().add(_reward.divide(_totalCapital));
        res = _productOfInterestRate.multiply(interestRate);
    }

    /**
     *  @notice Calculate the minimum price of token that the auction must surpass to emit maximum token of the day.
     *          Formula:    2 * A / Q / 80%
     *          Type:       int
     *          Usage:      StakingPool
     *
     *  @dev    Constant: AUCTION_SOFT_FLOOR_PRICE_COEFFICIENT = 200
     *  @dev    Constant: TREASURY_PERCENTAGE_ASSET = 50
     *  @dev    Constant: TREASURY_PERCENTAGE_INSURANCE = 30
     *
     *          Name            Symbol  Type    Meaning
     *  @param  _communityAsset A       int     Total value of the asset fund and the insurance fund in the treasury
     *  @param  _totalSupply    Q       int     Total circulating supply of the token
     */
    function softFloorPrice(
        uint256 _communityAsset,
        uint256 _totalSupply
    ) internal pure returns (Fixed memory res) {
        if (_totalSupply == 0) return Fixed(0);
        // 2 * A / Q / 80% = (200 * A) / (80 * Q)
        res = FixedMath.divide(
            Constant.AUCTION_SOFT_FLOOR_PRICE_COEFFICIENT * _communityAsset,
            (Constant.TREASURY_PERCENTAGE_ASSET + Constant.TREASURY_PERCENTAGE_INSURANCE) * _totalSupply
        );
    }
}


// File contracts/operational/MultiSend.sol

/**
 *  @title  Multi Send
 *
 *  @author 420 DAO Team
 *
 *  @notice Multi Send contract provide facilities to send to multi wallets
 *          in a single transaction. It can send native coin or any ERC-20
 *          compatible token.  Typically it can be used for airdrop event.
 *
 *          For token send, user can send with token 420 or s420 with no fee
 *          With sending other tokens, if user hold the minimum token 420 or s420,
 *          If not, the fee will be calculated base on fee percentage and total
 */
contract MultiSend is Ownable {
    using SafeERC20 for IERC20;

    /**
     *  @notice token store the address of the 420DAO token
     */
    address public immutable token;

    /**
     *  @notice token store the address of the s420DAO token
     */
    address public immutable sToken;

    /**
     *  @notice minimum of sum of 420 and s420 token balance that the user have
     *          If user balance > minFeeFree, sending is free
     */
    uint256 public minFeeFree;

    /**
     *  @notice fee percentage in case charge fee from sending tokens
     */
    uint256 public feePercent;

    /**
     *  @notice fee decimal define the decimal for fee unit. It convert from uint to
     *          percentage unit. For example
     *              1000000 -->     1 %
     *               123000 --> 0.123 %
     *          100*1000000 -->   100 %
     */
    uint8  public constant FEE_PERCENTAGE_DECIMALS = 6;

    event SetMinFeeFree(uint256 indexed minFeeFree);
    event SetFeePercent(uint256 indexed feePercent);
    event MultisentToken(address sender, address token, uint256 total, uint256 fee);
    event MultisentNative(address sender, uint256 total, uint256 fee);
    event ClaimedToken(address owner, address token, uint256 balance);
    event ClaimedNative(address owner, uint256 balance);

    /**
     *  @notice constructor require MultiSend to know the 420DAO token and s420DAO token addresses
     */
    constructor(address _token, address _sToken) {
        token = _token;
        sToken = _sToken;
    }

    /**
     *  @notice Set minimum of 420 + s420 user balance to send token with free fee.
     *
     *  @dev    Only owner can call this function.
     */
    function setMinFeeFree(uint256 _minFeeFree) external onlyOwner {
        minFeeFree = _minFeeFree;
        emit SetMinFeeFree(_minFeeFree);
    }

    /**
     *  @notice Set fee percentage for charging fee from sending tokens.
     *
     *  @dev    Only owner can call this function.
     */
    function setFeePercent(uint256 _feePercent) external onlyOwner {
        require(_feePercent <= 100 * (10**FEE_PERCENTAGE_DECIMALS), "MultiSend: Invalid fee percentage");
        feePercent = _feePercent;
        emit SetFeePercent(_feePercent);
    }

    /**
     *  @notice Send ERC-20 tokens to the list of receiver addresses.
     *          This method charge fee from fee calculating
     *
     *          Name           Meaning
     *  @param  _tokenERC20    Address of token
     *  @param  _receivers     Address of receivers
     *  @param  _balances      Amount of token that each receiver can be received
     *
     *  @dev    Everyone can call this function.
     */
    function multisendTokenERC20(IERC20 _tokenERC20, address[] calldata _receivers, uint256[] calldata _balances) external {
        require(_receivers.length > 0, "MultiSend: The receiver list is empty");
        require(_receivers.length == _balances.length, "MultiSend: Inconsistent lengths");

        uint256 total = 0;
        for (uint256 i = 0; i < _receivers.length; i++) {
            total += _balances[i];
        }

        uint256 fee = calFee(_msgSender(), address(_tokenERC20), total);
        _tokenERC20.safeTransferFrom(_msgSender(), address(this), total + fee);

        for (uint256 i = 0; i < _receivers.length; i++) {
            _tokenERC20.safeTransfer(_receivers[i], _balances[i]);
        }

        emit MultisentToken(_msgSender(), address(_tokenERC20), total, fee);
    }

    /**
     *  @notice Send native tokens to the list of receiver addresses.
     *          This method charge fee from fee calculating
     *
     *          Name           Meaning
     *  @param  _receivers     Address of receivers
     *  @param  _balances      Amount of native token that each receiver can be received
     *
     *  @dev    Everyone can call this function.
     */
    function multisendNative(address[] calldata _receivers, uint256[] calldata _balances) external payable {
        require(_receivers.length > 0, "MultiSend: The receiver list is empty");
        require(_receivers.length == _balances.length, "MultiSend: Inconsistent lengths");

        uint256 total = 0;
        for (uint256 i = 0; i < _receivers.length; i++) {
            total += _balances[i];
            payable(_receivers[i]).transfer(_balances[i]);
        }

        uint256 fee = calFee(_msgSender(), address(0), total);
        require(msg.value >= total + fee, "MultiSend: Insufficient funds");

        emit MultisentNative(_msgSender(), total, fee);
    }

    /**
     *  @notice Claim ERC-20 token that is charged from multisendTokenERC20 transactions.
     *
     *          Name           Meaning
     *  @param  _tokenERC20    Address of token
     *
     *  @dev    Everyone can call this function.
     */
    function claimFeeTokenERC20(IERC20 _tokenERC20) external {
        uint256 claimable = _tokenERC20.balanceOf(address(this));

        if (claimable > 0)
            _tokenERC20.safeTransfer(owner(), claimable);

        emit ClaimedToken(owner(), address(_tokenERC20), claimable);
    }

    /**
     *  @notice Claim native token that is charged from multisendTokenERC20 transactions.
     *
     *  @dev    Everyone can call this function.
     */
    function claimNative() external {
        uint256 claimable = address(this).balance;
        if (claimable > 0)
            payable(owner()).transfer(claimable);

        emit ClaimedNative(owner(), claimable);
    }

    /**
     *  @notice Calculate fee of a multisend transaction.
     *
     *            If sending token is 420 or s420                     => free
     *            If total balance of 420 and s420 >= minimun fee fee => free
     *            If not:
     *              fee = (total send * feePercent) / 100
     *
     *          Name         Meaning
     *  @param  _sender      Wallet address of sender
     *  @param  _tokenERC20  Address of sending ERC-20token. If send native token, address must be zero address
     *  @param  _sendTotal   Total amount of tokens that sender will send for receivers
     */
    function calFee(address _sender, address _tokenERC20, uint256 _sendTotal) public view returns (uint256) {
        if (_tokenERC20 == token || _tokenERC20 == sToken)
            return 0;

        uint256 tokenBalance = IERC20(token).balanceOf(_sender);
        uint256 sTokenBalance = IERC20(sToken).balanceOf(_sender);
        if (tokenBalance + sTokenBalance >= minFeeFree)
            return 0;

        return Formula.portion(feePercent, 100 * (10**FEE_PERCENTAGE_DECIMALS), _sendTotal);
    }
}