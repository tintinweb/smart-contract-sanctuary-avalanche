/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-07
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: contracts/interfaces/IElkPair.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.5.0;

interface IElkPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/interfaces/IElkDexOracle.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;

interface IElkDexOracle {

    function weth() external view returns(address);

    function factory() external view returns(address);

    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns(uint);

    function consultWeth(address tokenIn, uint amountIn) external view returns(uint);

    function update(address tokenA, address tokenB) external;

    function updateWeth(address token) external;

}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/interfaces/IStaking.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IStaking {

/* ========== STATE VARIABLES ========== */
function stakingToken() external pure returns(IERC20);
function totalSupply() external pure returns(uint256);
function balances(address account) external view returns(uint256);

/* ========== MUTATIVE FUNCTIONS ========== */
function stakeWithPermit(uint256 _amount, uint _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;
function stake(uint256 _amount) external;
function withdraw(uint256 _amount) external;
function exit() external;
function recoverERC20(address _tokenAddress, address _recipient, uint256 _amount) external;

/* ========== EVENTS ========== */

event Staked(address indexed account, uint256 amount);
event Withdrawn(address indexed account, uint256 amount);
event Recovered(address indexed token, address indexed recipient, uint256 amount);

}

// File: contracts/interfaces/IStakingFee.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;



interface IStakingFee is IStaking {

    /* ========== STATE VARIABLES ========== */
    function feesUnit() external pure returns(uint16);
    function maxFee() external pure returns(uint16);

    function withdrawalFeeSchedule() external pure returns(uint256[] memory);
    function withdrawalFeesBps() external pure returns(uint256[] memory);
    function depositFeeBps() external pure returns(uint256);
    function collectedFees() external pure returns(uint256);

    function userLastStakedTime(address user) external pure returns(uint32);

    /* ========== VIEWS ========== */

    function depositFee(uint256 _depositAmount) external view returns (uint256);
    function withdrawalFee(address _account, uint256 _withdrawalAmount) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverFees(address _recipient) external;
    function setFees(uint16 _depositFeeBps, uint16[] memory _withdrawalFeesBps, uint32[] memory _withdrawalFeeSchedule) external;

    /* ========== EVENTS ========== */
        
    event FeesSet(uint16 depositFeeBps, uint16[] withdrawalFeesBps, uint32[] feeSchedule);
    event DepositFeesCollected(address indexed user, uint256 amount);
    event WithdrawalFeesCollected(address indexed user, uint256 amount);
    event FeesRecovered(uint256 amount);

}

// File: contracts/interfaces/IStakingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;



interface IStakingRewards is IStakingFee {

    /* ========== STATE VARIABLES ========== */

    function rewardTokens() external pure returns(IERC20[] memory);
    function rewardTokenAddresses(address rewardAddress) external pure returns(bool);
    function periodFinish() external pure returns(uint256);
    function rewardsDuration() external pure returns(uint256);
    function lastUpdateTime() external pure returns(uint256);
    function rewardRates(address rewardAddress) external pure returns(uint256);
    function rewardPerTokenStored(address rewardAddress) external pure returns(uint256);

    // wallet address => token address => amount
    function userRewardPerTokenPaid(address walletAddress, address tokenAddress) external pure returns(uint256);
    function rewards(address walletAddress, address tokenAddress) external pure returns(uint256);


    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken(address _tokenAddress) external view returns (uint256);
    function earned(address _tokenAddress, address _account) external view returns (uint256);
    function emitting() external view returns(bool);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getReward(address _tokenAddress, address _recipient) external;
    function getRewards(address _recipient) external;

    // Must send reward before calling this!
    function startEmission(uint256[] memory _rewards, uint256 _duration) external;
    function stopEmission(address _refundAddress) external;
    function recoverLeftoverReward(address _tokenAddress, address _recipient) external;
    function addRewardToken(address _tokenAddress) external;

    /* ========== EVENTS ========== */

    event RewardPaid(address indexed token, address indexed account, uint256 reward);
    event LeftoverRewardRecovered(address indexed recipient, uint256 amount);
    event RewardsEmissionStarted(uint256[] rewards, uint256 duration);
    event RewardsEmissionEnded();

}

// File: contracts/interfaces/IFarmingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;





interface IFarmingRewards is IStakingRewards {

    struct Position {
            uint112 amount0;
            uint112 amount1;
            uint32 blockTimestamp;
        }

    /* ========== STATE VARIABLES ========== */

    function oracle() external pure returns(IElkDexOracle);
    function lpToken() external pure returns(IElkPair);
    function coverageTokenAddress() external pure returns(address);
    function coverageAmount() external pure returns(uint256);
    function coverageVestingDuration() external pure returns(uint32);
    function coverageRate() external pure returns(uint256);
    function coveragePerTokenStored() external pure returns(uint256);
    function userCoveragePerTokenPaid(address tokenPaid) external pure returns(uint256);
    function coverage(address token) external pure returns(uint256);
    function lastStakedPosition(address user) external pure returns(Position memory);

    /* ========== VIEWS ========== */

    function coveragePerToken() external view returns (uint256);
    function coverageEarned(address _account) external view returns(uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getCoverage(address _recipient) external;
    function startEmission(uint256[] memory _rewards, uint256 _duration) external override;
    function startEmission(uint256[] memory _rewards, uint256 _coverage, uint256 _duration) external;
    function recoverLeftoverCoverage(address _recipient) external;

    /* ========== OWNERSHIP FUNCTIONS ========== */

    function transferOwnership(address newOwner) external;

    /* ========== EVENTS ========== */

    event CoveragePaid(address indexed account, uint256 coverage);
    event LeftoverCoverageRecovered(address indexed recipient, uint256 amount);

}

// /* ========== STATE VARIABLES ========== */

    // function rewardsToken() external pure returns(IERC20);
    // function stakingToken() external pure returns(IERC20);
    // function periodFinish() external pure returns(uint256);
    // function rewardRate() external pure returns(uint256);
    // function rewardsDuration() external pure returns(uint256);
    // function lastUpdateTime() external pure returns(uint256);
    // function rewardPerTokenStored() external pure returns(uint256);
    // function userRewardPerTokenPaid(address user) external pure returns(uint256);
    // function rewards(address user) external pure returns(uint256);
    // function boosterToken() external pure returns(IERC20);
    // function boosterRewardRate() external pure returns(uint256);
    // function boosterRewardPerTokenStored() external pure returns(uint256);
    // function userBoosterRewardPerTokenPaid(address user) external pure returns(uint256);
    // function boosterRewards(address user) external pure returns(uint256);
    // function coverages(address user) external pure returns(uint256);
    // function totalCoverage() external pure returns(uint256);
    // function feeSchedule() external pure returns(uint256[] memory);
    // function withdrawalFeesPct() external pure returns(uint256[] memory);
    // function withdrawalFeesUnit() external pure returns(uint256);
    // function maxWithdrawalFee() external pure returns(uint256);
    // function lastStakedTime(address user) external pure returns(uint256);
    // function totalFees() external pure returns(uint256);

    // /* ========== VIEWS ========== */

    // function totalSupply() external view returns (uint256);
    // function balanceOf(address account) external view returns (uint256);
    // function lastTimeRewardApplicable() external view returns (uint256);
    // function rewardPerToken() external view returns (uint256);
    // function earned(address account) external view returns (uint256);
    // function getRewardForDuration() external view returns (uint256);
    // function boosterRewardPerToken() external view returns (uint256);
    // function boosterEarned(address account) external view returns (uint256);
    // function getBoosterRewardForDuration() external view returns (uint256);
    // function exitFee(address account) external view returns (uint256);
    // function fee(address account, uint256 withdrawalAmount) external view returns (uint256);

    // /* ========== MUTATIVE FUNCTIONS ========== */

    // function stake(uint256 amount) external;
    // function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    // function withdraw(uint256 amount) external;
    // function emergencyWithdraw(uint256 amount) external;
    // function getReward() external;
    // function getBoosterReward() external;
    // function getCoverage() external;
    // function exit() external;

    // /* ========== RESTRICTED FUNCTIONS ========== */

    // function sendRewardsAndStartEmission(uint256 reward, uint256 boosterReward, uint256 duration) external;
    // function startEmission(uint256 reward, uint256 boosterReward, uint256 duration) external;
    // function stopEmission() external;
    // function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
    // function recoverLeftoverReward() external;
    // function recoverLeftoverBooster() external;
    // function recoverFees() external;
    // function setRewardsDuration(uint256 duration) external;

    // // Booster Rewards

    // function setBoosterToken(address _boosterToken) external;

    // // ILP

    // function setCoverageAmount(address addr, uint256 amount) external;
    // function setCoverageAmounts(address[] memory addresses, uint256[] memory amounts) external;
    // function pause() external;
    // function unpause() external;

    // // Withdrawal Fees

    // function setWithdrawalFees(uint256[] memory _feeSchedule, uint256[] memory _withdrawalFees) external;

    // /* ========== EVENTS ========== */

    // event Staked(address indexed user, uint256 amount);
    // event Withdrawn(address indexed user, uint256 amount);
    // event CoveragePaid(address indexed user, uint256 amount);
    // event RewardPaid(address indexed user, uint256 reward);
    // event BoosterRewardPaid(address indexed user, uint256 reward);
    // event RewardsDurationUpdated(uint256 newDuration);
    // event Recovered(address token, uint256 amount);
    // event LeftoverRewardRecovered(uint256 amount);
    // event LeftoverBoosterRecovered(uint256 amount);
    // event RewardsEmissionStarted(uint256 reward, uint256 boosterReward, uint256 duration);
    // event RewardsEmissionEnded(uint256 amount);
    // event BoosterRewardSet(address token);
    // event WithdrawalFeesSet(uint256[] _feeSchedule, uint256[] _withdrawalFees);
    // event FeesCollected(address indexed user, uint256 amount);
    // event FeesRecovered(uint256 amount);

// File: contracts/interfaces/IElkFarmFactory.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IElkFarmFactory {

    event ContractCreated(address _newContract);
    event ManagerSet(address _farmManager);
    event FeeSet(uint256 newFee);
    event FeesRecovered(uint256 balanceRecovered);

    function factoryHelper() external view returns(address);
    function getFarm(address creator, address lpTokenAddress) external view returns(address);
    function allFarms(uint index) external view returns(address);
    function farmManager() external view returns(address);
    function getCreator(address farmAddress) external view returns(address);
    function fee() external view returns(uint256);
    function maxFee() external view returns(uint256);
    function feeToken() external view returns(IERC20);

    function createNewRewards(address _oracleAddress,
        address _lpTokenAddress,
        address _coverageTokenAddress,
        uint256 _coverageAmount,
        uint32 _coverageVestingDuration,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule) external;
    
    function setManager(address managerAddress) external;
    function overrideOwnership(address farmAddress) external;
    function setFee(uint256 newFee) external;
    function withdrawFees() external;

}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// File: contracts/Staking.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;





// Add support for multiple booster tokens

contract Staking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable stakingToken;
    
    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingTokenAddress
    ) {
        require(_stakingTokenAddress != address(0), "Staking token addr can't = 0");
        stakingToken = IERC20(_stakingTokenAddress);
    }

    function stakeWithPermit(uint256 _amount, uint _deadline, uint8 _v, bytes32 _r, bytes32 _s) external nonReentrant returns(uint256) {
        IERC20Permit(address(stakingToken)).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        return stake(_amount);
    }

    function stake(uint256 _amount) public nonReentrant returns(uint256) {
        require(_amount > 0, "Cannot stake 0");
        _amount = _beforeStake(msg.sender, _amount);
        totalSupply += _amount;
        balances[msg.sender] += _amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
        return _amount;
    }

    function withdraw(uint256 _amount) public nonReentrant returns(uint256) {
        // require(_amount > 0, "Cannot withdraw 0");
        require(_amount > 0 && _amount <= balances[msg.sender], "Can't withdraw more than acc bal");
        _amount = _beforeWithdraw(msg.sender, _amount);
        totalSupply -= _amount;
        balances[msg.sender] -= _amount;
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
        return _amount;
    }

    function exit() external nonReentrant {
        _beforeExit(msg.sender);
        withdraw(balances[msg.sender]);
    }

    function recoverERC20(address _tokenAddress, address _recipient, uint256 _amount) external nonReentrant onlyOwner {
        require(_tokenAddress != address(stakingToken), "Can't recover the staking token!");
        _beforeRecoverERC20(_tokenAddress, _recipient, _amount);
        IERC20 token = IERC20(_tokenAddress);
        token.safeTransfer(_recipient, _amount);
        emit Recovered(_tokenAddress, _recipient, _amount);
    }

    /* ========== HOOKS ========== */

    // New hooks
    function _beforeStake(address /*_account*/, uint256 _amount) internal virtual returns(uint256) { return _amount; }
    function _beforeWithdraw(address /*_account*/, uint256 _amount) internal virtual returns(uint256) { return _amount; }
    function _beforeExit(address _account) internal virtual {}
    function _beforeRecoverERC20(address _tokenAddress, address _recipient, uint256 _amount) internal virtual {}

    /* ========== EVENTS ========== */

    event Staked(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);
    event Recovered(address indexed token, address indexed recipient, uint256 amount);
}

// File: contracts/StakingFee.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


contract StakingFee is Staking {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    uint16 public constant feesUnit = 10000; // unit for fees
    uint16 public constant maxFee = 2000;    // max fee (20%)

    uint256[] public withdrawalFeeSchedule;
    uint256[] public withdrawalFeesBps;
    uint256 public depositFeeBps;
    uint256 public collectedFees;

    mapping(address => uint32) public userLastStakedTime;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingTokenAddress,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,     // aligned to fee schedule
        uint32[] memory _withdrawalFeeSchedule  // assumes a sorted array
    ) Staking(_stakingTokenAddress) {
        setFees(_depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule);
    }
    
    /* ========== VIEWS ========== */

    function depositFee(uint256 _depositAmount) public view returns (uint256) {
        if (depositFeeBps > 0) {
            return _depositAmount * depositFeeBps / feesUnit;
        } else {
            return 0;
        }
    }

    function withdrawalFee(address _account, uint256 _withdrawalAmount) public view returns (uint256) {
        for (uint i=0; i < withdrawalFeeSchedule.length; ++i) {
            if (block.timestamp - userLastStakedTime[_account] < withdrawalFeeSchedule[i]) {
                return _withdrawalAmount * withdrawalFeesBps[i] / feesUnit;
            }
        }
        return 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverFees(address _recipient) external onlyOwner nonReentrant {
        _beforeRecoverFees(_recipient);
        uint256 previousFees = collectedFees;
        collectedFees = 0;
        emit FeesRecovered(previousFees);
        stakingToken.safeTransfer(_recipient, previousFees);
    }

    function setFees(uint16 _depositFeeBps, uint16[] memory _withdrawalFeesBps, uint32[] memory _withdrawalFeeSchedule) public onlyOwner {
        require(_withdrawalFeeSchedule.length <= 10 && _withdrawalFeeSchedule.length == _withdrawalFeesBps.length, "schedule / withdrawal arrays must be < 10 and = length");
        // require(_withdrawalFeeSchedule.length <= 10, "Fee schedule and withdrawal fees arrays lengths cannot be larger than 10!");
        require(_depositFeeBps <  maxFee + 1, "Deposit fee > than maximum");
        uint32 lastFeeSchedule = 0;
        uint16 lastWithdrawalFee = maxFee + 1;
        for(uint i=0; i < _withdrawalFeeSchedule.length; ++i) {
           require(_withdrawalFeeSchedule[i] > lastFeeSchedule, "Fee schedule must be ascending!");
           require(_withdrawalFeesBps[i] < lastWithdrawalFee, "Withdrawal fees must be descending and < than max");
           lastFeeSchedule = _withdrawalFeeSchedule[i];
           lastWithdrawalFee = _withdrawalFeesBps[i];
        }
        withdrawalFeeSchedule = _withdrawalFeeSchedule;
        withdrawalFeesBps = _withdrawalFeesBps;
        depositFeeBps = _depositFeeBps;
        emit FeesSet(_depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule);
    }

    /* ========== HOOKS ========== */

    function _beforeStake(address _account, uint256 _amount) internal virtual override returns(uint256) {
        uint256 fee = depositFee(_amount);
        collectedFees += fee;
        userLastStakedTime[msg.sender] = uint32(block.timestamp);
        emit DepositFeesCollected(msg.sender, fee);
        return super._beforeStake(_account, _amount - fee);
    }
    
    function _beforeWithdraw(address _account, uint256 _amount) internal virtual override returns(uint256) {
        uint256 fee = withdrawalFee(msg.sender, _amount);
        collectedFees += fee;
        emit WithdrawalFeesCollected(msg.sender, fee);
        return super._beforeWithdraw(_account, _amount - fee);
    }

    // New hooks
    function _beforeRecoverFees(address _recipient) internal virtual {}

    /* ========== EVENTS ========== */
    
    event FeesSet(uint16 depositFeeBps, uint16[] withdrawalFeesBps, uint32[] feeSchedule);
    event DepositFeesCollected(address indexed user, uint256 amount);
    event WithdrawalFeesCollected(address indexed user, uint256 amount);
    event FeesRecovered(uint256 amount);
}

// File: contracts/StakingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;



// Add support for multiple booster tokens

contract StakingRewards is StakingFee {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20[] public rewardTokens;
    mapping(address => bool) public rewardTokenAddresses;
    uint256 public periodFinish;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    mapping(address => uint256) public rewardRates;
    mapping(address => uint256) public rewardPerTokenStored;

    // wallet address => token address => amount
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;
    
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingTokenAddress,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,     // aligned to fee schedule
        uint32[] memory _withdrawalFeeSchedule  // assumes a sorted array
    ) StakingFee(_stakingTokenAddress, _depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule) {
        
        require(_rewardTokenAddresses.length > 0, "There must be at least 1 reward token");

        for (uint i=0; i < _rewardTokenAddresses.length; ++i) {
            address tokenAddress = _rewardTokenAddresses[i];
            _addRewardToken(tokenAddress);
        }
        rewardsDuration = _rewardsDuration;
    }

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken(address _tokenAddress) public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored[_tokenAddress];
        }
        return
            rewardPerTokenStored[_tokenAddress] + (lastTimeRewardApplicable() - lastUpdateTime) * rewardRates[_tokenAddress] * 1e18 / totalSupply;
    }

    function earned(address _tokenAddress, address _account) public view returns (uint256) {
        return balances[_account] * (rewardPerToken(_tokenAddress) - userRewardPerTokenPaid[_tokenAddress][_account]) / 1e18 + rewards[_tokenAddress][_account];
    }

    function emitting() public view returns(bool) {
        return block.timestamp <= periodFinish;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // XXX: does this really need to be owner-only or check the msg.sender? If some idiot wants to pay for someone else to claim their rewards, why not let them?
    function getReward(address _tokenAddress, address _recipient) public nonReentrant updateRewards(msg.sender) {
        return _getReward(_tokenAddress, _recipient);
    }

    function getRewards(address _recipient) public nonReentrant updateRewards(msg.sender) {
        for (uint i=0; i < rewardTokens.length; ++i) {
            _getReward(address(rewardTokens[i]), _recipient);
        }
    }

    // Must send reward before calling this!
    function startEmission(uint256[] memory _rewards, uint256 _duration) public virtual nonReentrant onlyOwner whenNotEmitting updateRewards(address(0)) {
        require(_duration > 0, "Duration must be > 0");
        require(_rewards.length == rewardTokens.length, "Reward amounts array has too few or too many values");

        _beforeStartEmission(_rewards, _duration);

        rewardsDuration = _duration;

        for (uint i=0; i < rewardTokens.length; ++i) {
            IERC20 token = rewardTokens[i];
            address tokenAddress = address(token);
            rewardRates[tokenAddress] = _rewards[i] / rewardsDuration;

            // Ensure the provided reward amount is not more than the balance in the contract.
            // This keeps the reward rate in the right range, preventing overflows due to
            // very high values of rewardRate in the earned and rewardsPerToken functions;
            // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
            uint256 balance = rewardTokens[i].balanceOf(address(this));
            if (tokenAddress != address(stakingToken)) {
                require(rewardRates[tokenAddress] <= balance / rewardsDuration, "Provided reward too high");
            } else { // Handle carefully where rewardsToken is the same as stakingToken (need to subtract total supply)
                require(rewardRates[tokenAddress] <= (balance - totalSupply) / rewardsDuration, "Provided reward too high");
            }
        }
        
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        emit RewardsEmissionStarted(_rewards, _duration);
    }

    function stopEmission(address _refundAddress) external nonReentrant onlyOwner whenEmitting {
        _beforeStopEmission(_refundAddress);
        uint256 remaining = 0;
        if (periodFinish > block.timestamp) {
            remaining = periodFinish - block.timestamp;
        }

        for (uint i=0; i < rewardTokens.length; ++i) {
            IERC20 token = rewardTokens[i];
            address tokenAddress = address(token);
            uint256 refund = rewardRates[tokenAddress] * remaining;
            if (refund > 0) {
                token.safeTransfer(_refundAddress, refund);
            }
        }

        emit RewardsEmissionEnded();
    }

    function recoverLeftoverReward(address _tokenAddress, address _recipient) external onlyOwner whenNotEmitting {
        require(totalSupply == 0, "Can't recover leftover reward if tokens are staked");
        require(rewardTokenAddresses[_tokenAddress], "Not a reward token");
        _beforeRecoverLeftoverReward(_tokenAddress, _recipient);
        IERC20 token = IERC20(_tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            token.safeTransfer(_recipient, amount);
        }
        emit LeftoverRewardRecovered(_recipient, amount);
    }

    function addRewardToken(address _tokenAddress) external onlyOwner whenNotEmitting {
        _addRewardToken(_tokenAddress);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getReward(address _tokenAddress, address _recipient) private {
        require(rewardTokenAddresses[_tokenAddress], "Not a reward token!");
        uint256 reward = rewards[_tokenAddress][_recipient];
        if (reward > 0) {
            rewards[_tokenAddress][_recipient] = 0;
            IERC20(_tokenAddress).safeTransfer(_recipient, reward);
            emit RewardPaid(_tokenAddress, _recipient, reward);
        }
    }
    
    function _addRewardToken(address _tokenAddress) private {
        require(rewardTokens.length < 10, "Can't have more than 10 rewards tokens");
        require(_tokenAddress != address(0), "Reward token address can't be 0");
        require(!rewardTokenAddresses[_tokenAddress], "Reward tokens must all be different");
        rewardTokens.push(IERC20(_tokenAddress));
        rewardTokenAddresses[_tokenAddress];
    }

    /* ========== HOOKS ========== */

    // Ensure staking is only possible when rewards are emitting
    function _beforeStake(address _account, uint256 _amount) internal virtual override whenEmitting returns(uint256) {
        return super._beforeStake(_account, _amount);
    }

    function _beforeExit(address _account) internal virtual override {
        getRewards(msg.sender);
        super._beforeExit(_account);
    }

    // Prevent recovery a reward token
    function _beforeRecoverERC20(address _tokenAddress, address _recipient, uint256 _amount) internal virtual override {
        require(!rewardTokenAddresses[_tokenAddress], "Can't recover a reward token!");
        super._beforeRecoverERC20(_tokenAddress, _recipient, _amount);
    }

    // New hooks
    function _beforeStartEmission(uint256[] memory _rewards, uint256 _duration) internal virtual {}
    function _beforeStopEmission(address _refundAddress) internal virtual {}
    function _beforeRecoverLeftoverReward(address _tokenAddress, address _recipient) internal virtual {}
    
    /* ========== MODIFIERS ========== */
    
    modifier updateRewards(address _account) {
        for (uint i=0; i < rewardTokens.length; ++i) {
            address tokenAddress = address(rewardTokens[i]);
            rewardPerTokenStored[tokenAddress] = rewardPerToken(tokenAddress);
            lastUpdateTime = lastTimeRewardApplicable();
            if (_account != address(0)) {
                rewards[tokenAddress][_account] = earned(tokenAddress, _account);
                userRewardPerTokenPaid[tokenAddress][_account] = rewardPerTokenStored[tokenAddress];
            }
        }
        _;
    }

    modifier whenEmitting() {
        require(block.timestamp <= periodFinish, "Rewards are currently not emitting");
        _;
    }

    modifier whenNotEmitting() {
        require(block.timestamp > periodFinish, "Rewards are currently emitting");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardPaid(address indexed token, address indexed account, uint256 reward);
    event LeftoverRewardRecovered(address indexed recipient, uint256 amount);
    event RewardsEmissionStarted(uint256[] rewards, uint256 duration);
    event RewardsEmissionEnded();
}

// File: contracts/FarmingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;




// Add support for multiple booster tokens

contract FarmingRewards is StakingRewards {
    using SafeERC20 for IERC20;

    struct Position {
        uint112 amount0;
        uint112 amount1;
        uint32 blockTimestamp;
    }

    /* ========== STATE VARIABLES ========== */

    IElkDexOracle public immutable oracle;
    IElkPair public immutable lpToken;
    address public coverageTokenAddress;
    uint256 public coverageAmount;
    uint32 public coverageVestingDuration;

    uint256 public coverageRate;
    uint256 public coveragePerTokenStored;
    
    mapping(address => uint256) public userCoveragePerTokenPaid;
    mapping(address => uint256) public coverage;
    
    mapping(address => Position) public lastStakedPosition;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _oracleAddress,
        address _lpTokenAddress,
        address _coverageTokenAddress,
        uint256 _coverageAmount,
        uint32 _coverageVestingDuration,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,     // aligned to fee schedule
        uint32[] memory _withdrawalFeeSchedule  // assumes a sorted array
    ) StakingRewards(_lpTokenAddress, _rewardTokenAddresses, _rewardsDuration, _depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule) {
        oracle = IElkDexOracle(_oracleAddress);
        lpToken = IElkPair(_lpTokenAddress);
        require(lpToken.factory() == oracle.factory(), "Only Liquidity Pairs on ElkDex are supported");
        require(lpToken.token0() == _coverageTokenAddress || lpToken.token1() == _coverageTokenAddress, "Coverage token must be one of the tokens in the LP");
        coverageTokenAddress = _coverageTokenAddress;
        coverageAmount = _coverageAmount;
        require(_coverageVestingDuration >= 24 * 3600, "Coverage vesting duration must be at least one day");
        require(_coverageVestingDuration <= rewardsDuration, "Coverage vesting duration cannot be longer than rewards duration");
        coverageVestingDuration = _coverageVestingDuration;
    }
    
    /* ========== VIEWS ========== */

    function coveragePerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return coveragePerTokenStored;
        }
        return
            // does this work for non 18 dec tokens?  rate = _coverage / rewardsDuration, here rate is converted back to 18 dec
            coveragePerTokenStored + (lastTimeRewardApplicable() - lastUpdateTime) * coverageRate * 1e18 / totalSupply;
    }

    function coverageEarned(address _account) public view returns(uint256) {
        uint256 hodlValue = lpValueWeth(lastStakedPosition[_account]);
        if (hodlValue == 0) { // prevent division by zero below // equivalent check would be lastStakedPosition[_account].blockTimestamp > 0
            return coverage[_account];
        }
        uint256 outValue = lpValueWeth(position(balances[_account]));
        uint256 cappedCoverage = balances[_account] * (coveragePerToken() - userCoveragePerTokenPaid[_account]) / 1e18;
        uint256 vested = vestedCoverage(hodlValue, outValue, lastStakedPosition[_account].blockTimestamp);
        if (vested > cappedCoverage) {
            vested = cappedCoverage;
        }
        // amount * (hodl value - out value) / hodl value = amount * (1 - (out value / hodl value))
        uint256 newlyEarnedCoverage = vested - vested * outValue / hodlValue;
        return newlyEarnedCoverage + coverage[_account];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getCoverage(address _recipient) public nonReentrant updateCoverage(_recipient) {
        require(msg.sender == owner() || msg.sender == _recipient, "Only owner or recipient can claim the coverage");
        uint256 cov = coverage[_recipient];
        if (cov > 0) {
            coverage[_recipient] = 0;
            IERC20(coverageTokenAddress).safeTransfer(_recipient, cov);
            emit CoveragePaid(_recipient, cov);
        }
    }

    function startEmission(uint256[] memory _rewards, uint256 _duration) public override onlyOwner {
        return startEmission(_rewards, 0, _duration);
    }

    function startEmission(uint256[] memory _rewards, uint256 _coverage, uint256 _duration) public onlyOwner updateCoverage(address(0)) {
        super.startEmission(_rewards, _duration);
        require(coverageVestingDuration <= rewardsDuration, "Coverage vesting duration cannot be longer than rewards duration");  // must check again
        coverageRate = _coverage / rewardsDuration;  // rewardsDuration, not coverageVestingDuration which can be shorter!

        // Ensure the provided coverage amount is not more than the balance in the contract
        uint256 balance = IERC20(coverageTokenAddress).balanceOf(address(this));
        int8 tokenIndex = rewardTokenIndex(coverageTokenAddress);
        if (tokenIndex >= 0) {
            balance -= _rewards[uint256(int256(tokenIndex))];
        }
        require(coverageRate <= balance / rewardsDuration, "Provided coverage too high");
    }

    function recoverLeftoverCoverage(address _recipient) public virtual onlyOwner whenNotEmitting {
        require(totalSupply == 0, "Can't recover leftover coverage if there are still staked tokens");
        _beforeRecoverLeftoverCoverage(_recipient);
        IERC20 token = IERC20(coverageTokenAddress);
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            token.safeTransfer(_recipient, amount);
        }
        emit LeftoverCoverageRecovered(_recipient, amount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function position(uint256 _amount) private view returns(Position memory) {
        (uint112 reserve0, uint112 reserve1, uint32 timestamp) = lpToken.getReserves();
        uint256 totalAmount = lpToken.totalSupply();
        uint112 amount0 = uint112((_amount * reserve0) / totalAmount);
        uint112 amount1 = uint112((_amount * reserve1) / totalAmount);
        return Position(amount0, amount1, timestamp);
    }

    function lpValueWeth(Position memory _position) private view returns(uint256) {
        return oracle.consultWeth(lpToken.token0(), _position.amount0) + oracle.consultWeth(lpToken.token1(), _position.amount1);
    }

    function rewardTokenIndex(address _tokenAddress) private view returns(int8) {
        if (rewardTokenAddresses[_tokenAddress]) {
            for (uint i=0; i < rewardTokens.length; ++i) {
                if (address(rewardTokens[i]) == _tokenAddress) {
                    return int8(int256(i));
                }
            }
        }
        return -1;
    }

    function wethCoverage(uint256 hodlValue, uint256 outValue) private pure returns(uint256) {
        if (hodlValue > outValue) { // there is IL
            // hodl value - out value
            return hodlValue - outValue;
        } else {
            return 0;
        }
    }

    function tokenCoverage(uint256 hodlValue, uint256 outValue) private view returns(uint256) {
        uint256 wethCov = wethCoverage(hodlValue, outValue);
        if (wethCov == 0) {
            return 0;
        }
        return oracle.consult(oracle.weth(), wethCov, coverageTokenAddress);
    }

    function vestedCoverage(uint256 hodlValue, uint256 outValue, uint32 lastTimestamp) private view returns(uint256) {
        if (block.timestamp - lastTimestamp < coverageVestingDuration) {
            return tokenCoverage(hodlValue, outValue) * (block.timestamp - lastTimestamp) / coverageVestingDuration;
        } else {
            return tokenCoverage(hodlValue, outValue);
        }
    }

    /* ========== HOOKS ========== */

    function _beforeStake(address _account, uint256 _amount) internal virtual override updateCoverage(_account) returns(uint256) {
        return super._beforeStake(_account, _amount);
    }

    function _beforeWithdraw(address _account, uint256 _amount) internal virtual override updateCoverage(_account) returns(uint256) {
        return super._beforeWithdraw(_account, _amount);
    }

    function _beforeExit(address _account) internal virtual override {
        getCoverage(_account);
        super._beforeExit(_account);
    }

    function _beforeRecoverERC20(address _tokenAddress, address _recipient, uint256 _amount) internal virtual override {
        require(_tokenAddress != coverageTokenAddress, "Can't recover the coverage token!");
        super._beforeRecoverERC20(_tokenAddress, _recipient, _amount);
    }

    // New hooks
    function _beforeRecoverLeftoverCoverage(address _recipient) internal virtual {}

    /* ========== MODIFIERS ========== */
    
    modifier updateCoverage(address _account) {
        coveragePerTokenStored = coveragePerToken();
        lastUpdateTime = lastTimeRewardApplicable();  // it seems fine to reuse this here
        oracle.update(lpToken.token0(), oracle.weth());  // update oracle for first token
        oracle.update(lpToken.token1(), oracle.weth());  // ditto for the second token
        if (_account != address(0)) {
            coverage[_account] = coverageEarned(_account);
            userCoveragePerTokenPaid[_account] = coveragePerTokenStored;
            lastStakedPosition[_account] = position(balances[_account]); // don't forget to reset the last position info
        }
        _;
    }

    /* ========== EVENTS ========== */

    event CoveragePaid(address indexed account, uint256 coverage);
    event LeftoverCoverageRecovered(address indexed recipient, uint256 amount);

}

// File: contracts/ElkFactoryHelper.sol


pragma solidity >=0.8.0;


library ElkFactoryHelper {

    function createFarmContract(bytes memory _abi, bytes32 _salt, address _farmManager) external returns(address addr) {

        bytes memory bytecode = abi.encodePacked(type(FarmingRewards).creationCode, _abi);

        assembly {
        addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
        if iszero(extcodesize(addr)) {
            revert(0, 0)
            }
        }

        FarmingRewards(addr).transferOwnership(_farmManager);

    }

}
// File: contracts/ElkFarmFactory.sol


// 
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
// 
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;








contract ElkFarmFactory is IElkFarmFactory, Ownable {

    address public factoryHelper;
    mapping(address => mapping(address => address)) public getFarm;
    address[] public allFarms;
    address public farmManager;
    mapping(address => address) public getCreator;
    
    IERC20 public feeToken = IERC20(0xeEeEEb57642040bE42185f49C52F7E9B38f8eeeE);
    uint256 public fee = 1000 * 10 ** 18;
    uint256 public maxFee = 1000000 * 10 ** 18;
    
    constructor() {
    }

    function createNewRewards(
        address _oracleAddress,
        address _lpTokenAddress,
        address _coverageTokenAddress,
        uint256 _coverageAmount,
        uint32 _coverageVestingDuration,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule)
        public {

            require(getFarm[msg.sender][_lpTokenAddress] == address(0), 'Elk: FARM_EXISTS'); // single check is sufficient

            bytes memory abiCode = abi.encode(_oracleAddress, _lpTokenAddress, _coverageTokenAddress, _coverageAmount, _coverageVestingDuration, _rewardTokenAddresses, _rewardsDuration, _depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule);
            bytes32 salt = keccak256(abi.encodePacked(_lpTokenAddress, msg.sender));
            
            _takeFee();

            address addr = ElkFactoryHelper.createFarmContract(abiCode, salt, farmManager);

            getFarm[msg.sender][_lpTokenAddress] = addr;
            getCreator[addr] = msg.sender;
            allFarms.push(addr);

            emit ContractCreated(addr);

    }

    function setManager(address managerAddress) external override onlyOwner {
        require(managerAddress != address(0), "0 addr");
        farmManager = managerAddress;
        emit ManagerSet(managerAddress);
    }

    function _takeFee() private {
        require(feeToken.balanceOf(msg.sender) >= fee, "No fee");
        feeToken.transferFrom(msg.sender, address(this), fee);
    }

    function setFee(uint256 newFee) external onlyOwner {
        require(newFee < maxFee, "Fee > max");
        fee = newFee;
        emit FeeSet(newFee);
    }

    function withdrawFees() external onlyOwner {
        _withdrawFees();
    }

    function _withdrawFees() private {
        uint256 balance = feeToken.balanceOf(address(this));
        feeToken.transfer(msg.sender, balance);
        emit FeesRecovered(balance);
    }

    // Change ownership of a farm

    function overrideOwnership(address farmAddress) external onlyOwner {
        _overrideOwnership(farmAddress);
    }

    function _overrideOwnership(address farmAddress) private {
        address creatorAddress = getCreator[farmAddress];

        require(creatorAddress != msg.sender, "AO");
        require(creatorAddress != address(0), "NF");

        IFarmingRewards rewardsContract = IFarmingRewards(farmAddress);

        address lpTokenAddress = address(rewardsContract.stakingToken());
        // allows creator to make another farm with same staking token, should we prevent this somehow?
        getFarm[creatorAddress][lpTokenAddress] = address(0);


        getFarm[msg.sender][lpTokenAddress] = farmAddress;
        getCreator[farmAddress] = msg.sender;
    }

}



// whitelist lp factory for lp tokens
// liquidity locking possibly