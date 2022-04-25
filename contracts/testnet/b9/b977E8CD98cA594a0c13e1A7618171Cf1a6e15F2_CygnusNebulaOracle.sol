/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-23
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/cygnus-core/interfaces/ICygnusNebulaOracle.sol

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

/// @title ITwapNebulaOracle Interface for Oracle
// Simple implementation of Uniswap TWAP Oracle
interface ICygnusNebulaOracle {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when uint224 overflows
     */
    error CygnusNebulaOracle__Uint224Overflow();

    /**
     *  @custom:error Emitted when oracle already exists for LP Token
     */
    error CygnusNebulaOracle__PairIsInitialized(address lpTokenPair);

    /**
     *  @custom:error Emitted when pair hasn't been initialised for LP Token
     */
    error CygnusNebulaOracle__PairNotInitialized(address lpTokenPair);

    /**
     *  @custom:error Emitted when oracle is called before ready
     */
    error CygnusNebulaOracle__TimeWindowTooSmall(uint32 timeWindow);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param lpTokenPair The address of the LP Token
     *  @param priceCumulative The cumulative price of the LP Token in uint256
     *  @param blockTimestamp The timestamp of the last price update in uint32
     *  @param latestIsSlotA Bool value if it is latest price update
     *  @custom:event Emitted when LP Token price is updated
     */
    event UpdateLPTokenPrice(
        address indexed lpTokenPair,
        uint256 priceCumulative,
        uint32 blockTimestamp,
        bool latestIsSlotA
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS 
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @return The minimum amount of time for oracle to update, 10 mins
     */
    function minimumTimeWindow() external view returns (uint32);

    /**
     *  @param lpTokenPair The address of the LP Token
     *  @return priceCumulativeSlotA The cumulative price of Token A
     *  @return priceCumulativeSlotB The cumulative price of Token B
     *  @return lastUpdateSlotA The uint32 of last price update of Token A
     *  @return lastUpdateSlotB The uint32 of last price update of Token B
     *  @return latestIsSlotA Bool value represents if price is latest
     *  @return initialized Bool value represents if oracle for pair exists
     */
    function getCygnusNebulaPair(address lpTokenPair)
        external
        view
        returns (
            uint256 priceCumulativeSlotA,
            uint256 priceCumulativeSlotB,
            uint32 lastUpdateSlotA,
            uint32 lastUpdateSlotB,
            bool latestIsSlotA,
            bool initialized
        );

    /**
     *  @notice Helper function that returns the current block timestamp within the range of uint32
     *  @return uint32 block.timestamp
     */
    function getBlockTimestamp() external view returns (uint32);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS 
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @notice initialize oracle for LP Token
    /// @param lpTokenPair is address of LP Token
    function initializeCygnusNebula(address lpTokenPair) external;

    /// @notice Gets the LP Tokens price if time elapsed > time window
    /// @param lpTokenPair The address of the LP Token
    /// @return timeWeightedPrice112x112 The price of the LP Token
    /// @return timeWindow The time window of the price update
    function getResult(address lpTokenPair) external returns (uint224 timeWeightedPrice112x112, uint32 timeWindow);
}


// File contracts/cygnus-core/libraries/UQ112x112.sol

// ignore: GPL-3.0
pragma solidity >=0.8.4;

// Uniswap library
// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 public constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}


// File contracts/cygnus-core/libraries/PRBMath.sol

// ignore: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);
/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}


// File contracts/cygnus-core/interfaces/IErc20.sol

// ignore: Unlicense
pragma solidity >=0.8.4;

/// @title IErc20
/// @author Paul Razvan Berg
/// @notice Implementation for the Erc20 standard.
///
/// We have followed general OpenZeppelin guidelines: functions revert instead of returning
/// `false` on failure. This behavior is nonetheless conventional and does not conflict with
/// the with the expectations of Erc20 applications.
///
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}. This allows
/// applications to reconstruct the allowance for all accounts just by listening to said
/// events. Other implementations of the Erc may not emit these events, as it isn't
/// required by the specification.
///
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance} functions have been
/// added to mitigate the well-known issues around setting allowances.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol
interface IErc20 {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when the owner is the zero address.
    error Erc20__ApproveOwnerZeroAddress();

    /// @notice Emitted when the spender is the zero address.
    error Erc20__ApproveSpenderZeroAddress();

    /// @notice Emitted when burning more tokens than are in the account.
    error Erc20__BurnUnderflow(uint256 accountBalance, uint256 burnAmount);

    /// @notice Emitted when the holder is the zero address.
    error Erc20__BurnZeroAddress();

    /// @notice Emitted when the owner did not give the spender sufficient allowance.
    error Erc20__InsufficientAllowance(uint256 allowance, uint256 amount);

    /// @notice Emitted when tranferring more tokens than there are in the account.
    error Erc20__InsufficientBalance(uint256 senderBalance, uint256 amount);

    /// @notice Emitted when the beneficiary is the zero address.
    error Erc20__MintZeroAddress();

    /// @notice Emitted when the sender is the zero address.
    error Erc20__TransferSenderZeroAddress();

    /// @notice Emitted when the recipient is the zero address.
    error Erc20__TransferRecipientZeroAddress();

    /// EVENTS ///

    /// @notice Emitted when an approval happens.
    /// @param owner The address of the owner of the tokens.
    /// @param spender The address of the spender.
    /// @param amount The maximum amount that can be spent.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when a transfer happens.
    /// @param from The account sending the tokens.
    /// @param to The account receiving the tokens.
    /// @param amount The amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// @dev This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    function symbol() external view returns (string memory);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may
    /// use both the old and the new allowance by unfortunate transaction ordering. One possible solution
    /// to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired
    /// value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for problems described
    /// in {Erc20Interface-approve}.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least `subtractedAmount`.
    function decreaseAllowance(address spender, uint256 subtractedAmount) external returns (bool);

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems described above.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedAmount) external returns (bool);

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `recipient` cannot be the zero address.
    /// - The caller must have a balance of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount`
    /// `is then deducted from the caller's allowance.
    ///
    /// @dev Emits a {Transfer} event and an {Approval} event indicating the updated allowance. This is
    /// not required by the Erc. See the note at the beginning of {Erc20}.
    ///
    /// Requirements:
    ///
    /// - `sender` and `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    /// - The caller must have approed `sender` to spent at least `amount` tokens.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


// File contracts/cygnus-core/interfaces/IErc20Permit.sol

// ignore: Unlicense
// solhint-disable func-name-mixedcase
pragma solidity >=0.8.4;

/// @title IErc20Permit
/// @author Paul Razvan Berg
/// @notice Extension of Erc20 that allows token holders to use their tokens without sending any
/// transactions by setting the allowance with a signature using the `permit` method, and then spend
/// them via `transferFrom`.
/// @dev See https://eips.ethereum.org/EIPS/eip-2612.
interface IErc20Permit is IErc20 {
    /// @notice Emitted when the recovered owner does not match the actual owner.
    error Erc20Permit__InvalidSignature(uint8 v, bytes32 r, bytes32 s);

    /// @notice Emitted when the owner is the zero address.
    error Erc20Permit__OwnerZeroAddress();

    /// @notice Emitted when the permit expired.
    error Erc20Permit__PermitExpired(uint256 deadline);

    /// @notice Emitted when the recovered owner is the zero address.
    error Erc20Permit__RecoveredOwnerZeroAddress();

    /// @notice Emitted when the spender is the zero address.
    error Erc20Permit__SpenderZeroAddress();

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, assuming the latter's
    /// signed approval.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: The same issues Erc20 `approve` has related to transaction
    /// ordering also apply here.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    /// - `deadline` must be a timestamp in the future.
    /// - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the Eip712-formatted
    /// function arguments.
    /// - The signature must use `owner`'s current nonce.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The Eip712 domain's keccak256 hash.
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Provides replay protection.
    function nonces(address account) external view returns (uint256);

    /// @notice keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    function PERMIT_TYPEHASH() external view returns (bytes32);

    /// @notice Eip712 version of this implementation.
    function version() external view returns (string memory);

    function chainId() external view returns (uint256);
}


// File contracts/cygnus-core/interfaces/IDexPair.sol

//ignore: Unlicensed
pragma solidity >=0.8.4;

// only using relevant functions for CygnusNebula Oracle

/// @notice Interface for most DEX pairs (TraderJoe, Pangolin, Sushi, Uniswap, etc.)
interface IDexPair is IErc20Permit {
    /// DEX FUNCTIONS ///

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);
}


// File contracts/cygnus-core/CygnusNebulaOracle.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// dependencies

// libraries


// interfaces

/**
 *  @title CygnusNebula TWAP Oracle
 *  @notice Taken from uniswap/impermax's implementation
 */
contract CygnusNebulaOracle is ICygnusNebulaOracle {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES 
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library UQ112x112 Uniswap's fixed point library for uint112
     */
    using UQ112x112 for uint224;

    /**
     *  @custom:library PRBMathUD60x18 for fixed point math, also imports the main library `PRBMath`.
     */
    using PRBMath for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusNebulaOracle
     */
    uint32 public constant override minimumTimeWindow = 10 minutes;

    /**
     *  @notice LP Token pair info
     */
    struct CygnusNebulaPair {
        uint256 priceCumulativeSlotA;
        uint256 priceCumulativeSlotB;
        uint32 lastUpdateSlotA;
        uint32 lastUpdateSlotB;
        bool latestIsSlotA;
        bool initialized;
    }

    /**
     *  @inheritdoc ICygnusNebulaOracle
     */
    mapping(address => CygnusNebulaPair) public override getCygnusNebulaPair;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusNebulaOracle
     */
    function getBlockTimestamp() public view override returns (uint32) {
        return uint32(block.timestamp);
    }

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @param lpTokenPair The address of the LP Token pair.
     *  @return priceCumulative The uint256 current price cumulative.
     */
    function getCurrentCumulativePrice(address lpTokenPair) internal view returns (uint256 priceCumulative) {
        priceCumulative = IDexPair(lpTokenPair).price0CumulativeLast();

        // Get cached reserves
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IDexPair(lpTokenPair).getReserves();

        // Encodes a UQ112x112 number and decodes into a uint224
        uint224 priceLatest = UQ112x112.encode(reserve1).uqdiv(reserve0);

        // Get time elapsed since last recorded update
        uint32 timeElapsed = getBlockTimestamp() - blockTimestampLast;

        // Update price cumulative price with the time elapsed
        priceCumulative += uint256(priceLatest) * timeElapsed;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusNebulaOracle
     */
    function initializeCygnusNebula(address lpTokenPair) external override {
        CygnusNebulaPair storage cygnusNebulaStorage = getCygnusNebulaPair[lpTokenPair];

        /// @custom:error PairIsInitialized
        if (cygnusNebulaStorage.initialized) {
            revert CygnusNebulaOracle__PairIsInitialized(lpTokenPair);
        }

        // Get the price cumulative current
        uint256 priceCumulativeCurrent = getCurrentCumulativePrice(lpTokenPair);

        // Get the uint32 blocktimestamp
        uint32 blockTimestamp = getBlockTimestamp();

        // Update current price cumulative for Token A
        cygnusNebulaStorage.priceCumulativeSlotA = priceCumulativeCurrent;

        // Update current price cumulative for Token B
        cygnusNebulaStorage.priceCumulativeSlotB = priceCumulativeCurrent;

        // Udate last update slot for Token A
        cygnusNebulaStorage.lastUpdateSlotA = blockTimestamp;

        // Udate last update slot for Token B
        cygnusNebulaStorage.lastUpdateSlotB = blockTimestamp;

        // Latest and initialized
        cygnusNebulaStorage.latestIsSlotA = true;
        cygnusNebulaStorage.initialized = true;

        /// @custom:event UpdateLPTokenPrice
        emit UpdateLPTokenPrice(lpTokenPair, priceCumulativeCurrent, blockTimestamp, true);
    }

    /**
     *  @inheritdoc ICygnusNebulaOracle
     */
    function getResult(address lpTokenPair)
        external
        override
        returns (uint224 timeWeightedPrice112x112, uint32 timeWindow)
    {
        CygnusNebulaPair memory pair = getCygnusNebulaPair[lpTokenPair];

        /// @custom:error Avoid if pair is not initialized
        if (!pair.initialized) {
            revert CygnusNebulaOracle__PairNotInitialized(lpTokenPair);
        }

        // storage
        CygnusNebulaPair storage cygnusNebulaStorage = getCygnusNebulaPair[lpTokenPair];

        // Get the uint32 blocktimestamp
        uint32 blockTimestamp = getBlockTimestamp();

        // Get last update timestamp
        uint32 lastUpdateTimestamp = pair.latestIsSlotA ? pair.lastUpdateSlotA : pair.lastUpdateSlotB;

        uint256 priceCumulativeCurrent = getCurrentCumulativePrice(lpTokenPair);

        uint256 priceCumulativeLast;

        if (blockTimestamp - lastUpdateTimestamp >= minimumTimeWindow) {
            // Get latest price
            priceCumulativeLast = pair.latestIsSlotA ? pair.priceCumulativeSlotA : pair.priceCumulativeSlotB;

            if (pair.latestIsSlotA) {
                cygnusNebulaStorage.priceCumulativeSlotB = priceCumulativeCurrent;

                cygnusNebulaStorage.lastUpdateSlotB = blockTimestamp;
            } else {
                cygnusNebulaStorage.priceCumulativeSlotA = priceCumulativeCurrent;

                cygnusNebulaStorage.lastUpdateSlotA = blockTimestamp;
            }

            cygnusNebulaStorage.latestIsSlotA = !pair.latestIsSlotA;

            /// @custom:event UpdateLPTokenPrice
            emit UpdateLPTokenPrice(lpTokenPair, priceCumulativeCurrent, blockTimestamp, !pair.latestIsSlotA);
        } else {
            // Don't update
            lastUpdateTimestamp = pair.latestIsSlotA ? pair.lastUpdateSlotB : pair.lastUpdateSlotA;

            priceCumulativeLast = pair.latestIsSlotA ? pair.priceCumulativeSlotB : pair.priceCumulativeSlotA;
        }

        // This call's time window
        timeWindow = blockTimestamp - lastUpdateTimestamp;

        /// @custom:error Reverts only if the pair has been initialized
        if (timeWindow < minimumTimeWindow) {
            revert CygnusNebulaOracle__TimeWindowTooSmall(timeWindow);
        }

        // Update price
        timeWeightedPrice112x112 = uint224((priceCumulativeCurrent - priceCumulativeLast) / minimumTimeWindow);
    }
}