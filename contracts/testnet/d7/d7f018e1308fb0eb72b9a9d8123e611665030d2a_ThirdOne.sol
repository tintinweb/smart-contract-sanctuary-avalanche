/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-08
*/

// SPDX-License-Identifier: MIT

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-28
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol


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
            require(denominator > prod1, "Math: mulDiv overflow");

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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// File: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint _len) private pure {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (_len > 0) {
            mask = 256 ** (32 - _len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.3/contracts/security/ReentrancyGuard.sol



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
     * by making the `nonReentrant` function external, and make it call a
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
//
//
//
// File: Third1g.sol
//
//
//
//
//
//
//
//
/*
░█████╗░██╗░░██╗░█████╗░██████╗░  ██████╗░░█████╗░░██████╗░███████╗
██╔══██╗██║░░██║██╔══██╗██╔══██╗  ██╔══██╗██╔══██╗██╔════╝░██╔════╝
██║░░╚═╝███████║███████║██║░░██║  ██║░░██║██║░░██║██║░░██╗░█████╗░░
██║░░██╗██╔══██║██╔══██║██║░░██║  ██║░░██║██║░░██║██║░░╚██╗██╔══╝░░
╚█████╔╝██║░░██║██║░░██║██████╔╝  ██████╔╝╚█████╔╝╚██████╔╝███████╗
░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░  ╚═════╝░░╚════╝░░╚═════╝░╚══════╝

░██████╗██╗░░░██╗██████╗░███████╗██████╗░░██████╗  ██╗░░░██╗██████╗░░██████╗░██████╗░░█████╗░██████╗░███████╗██████╗░
██╔════╝██║░░░██║██╔══██╗██╔════╝██╔══██╗██╔════╝  ██║░░░██║██╔══██╗██╔════╝░██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
╚█████╗░██║░░░██║██████╔╝█████╗░░██████╔╝╚█████╗░  ██║░░░██║██████╔╝██║░░██╗░██████╔╝███████║██║░░██║█████╗░░██████╔╝
░╚═══██╗██║░░░██║██╔═══╝░██╔══╝░░██╔══██╗░╚═══██╗  ██║░░░██║██╔═══╝░██║░░╚██╗██╔══██╗██╔══██║██║░░██║██╔══╝░░██╔══██╗
██████╔╝╚██████╔╝██║░░░░░███████╗██║░░██║██████╔╝  ╚██████╔╝██║░░░░░╚██████╔╝██║░░██║██║░░██║██████╔╝███████╗██║░░██║
╚═════╝░░╚═════╝░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═════╝░  ░╚═════╝░╚═╝░░░░░░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝╚═╝░░╚═╝
*/
//
//
//
// Static NFT to dynamic NFT custom upgrader contract
//
//  Created by 0xJelle '22
//
//
//
//
//@Dev make sure to set all the addresses, also set the six F vials Array after vials are shuffle revealed.
//@Dev set approval using the gnosis safe writing to the supers contract to set this Third contract address as operator for the safe's supers 0-3249
//@Dev dapp to let user set approval for all set using this Third contract address as operator, writing to vials and upgradeTokens contracts.
//@Dev dapp to call read functions to unshuffle id number found in our server url subdomain called from supers tokenURI after we switch supers baseURI to our server url
//
pragma solidity >=0.8.17;




//////////////////////////////////added interface to check Chad etc contracts//////////////////////////////////
interface IflatLaunchPeg {
    function ownerOf(uint256) external view returns(address); //read the ownerOf function from the Chad and vial and supers contracts and return the owner address
    function safeTransferFrom(address sender, address recipient, uint256 amount) external; //transfer existing nft to  burn it
    function isApprovedForAll(address, address) external view returns(bool); //check approval for transfer
    function tokenURI(uint) external view returns(string memory);//read tokenuri to get shuffled ID number for supers 3250-5000
    function lastTokenRevealed() external view returns(uint);//check for ID of last token revealed
}
/////////////////////////////////////////////////end of interface/////////////////////////////////////////////////

contract ThirdOne is Ownable, ReentrancyGuard {
    using Strings for uint256; //for custom uri
    using strings for *;//for parser                                            

    bool public blockUnmintedURI = true;//true if we want supersTokenURI() to return error if asking for uri of a lower token that has not been minted with a chad a vial yet
    bool public botsCanMint;//true if smart contract bots are allowed to mint or upgrade Supers
    bool public fVialsSet;//true if the six f vial token ID numbers have been set by hand after the vials are shuffle revealed in their flatlaunchpeg contract.
    uint public preminted;//amount of vials minted, is also amount of supers we premint to our gnosis safe wallet
    uint public vialsBurned;//count total vials burned
    uint public nVialsBurned;//count type N Normal vials burned
    uint public fVialsBurned;//count type F Freak vials burned
    uint public upgradesBurned;//count total upgradeTokens burned
    uint public nextMint; //tracks Supers ID to send next when minting via Vial burning
    string public baseURISupers3250N;//baseURI for supers 0-3249 matches original doge 1:1 (type N)
    string public baseURISupers3250F;//baseURI for supers 0-3249 , type F so does not match, file #s 1-6 for six total possible type Fs in the first 3250 nfts
    string public baseURISupers1750;//baseURI for supers 3250-4999 taken from super contract original baseuri before overwrite supers baseuri with our website url
    string public baseExtension = ""; //base extention, use ".json" for pinata ipfs style folder of json files
    address public zeroAddress = 0x0000000000000000000000000000000000000069;//burn transfers to this zero+X address (can't use the actual zero address)
    address public superSafe; //address of our gnosis safe multisig wallet holding the first 3250 super doge to be upgraded later, we preminted these 3250 from supers contract (flatLaunchPeg)
    address public chadContract; //address of old Chad Doge contract to read ownerOf using interface
    address public vialContract; //address of vial contract to read ownerOf and do transfer using interface and dapp transfer approval
    address public upgradeContract; //address of upgradeToken contract for website to read json file edit instructions
    address public superContract; //address of super contract to transfer super to vial minter, read shuffled id of supers 3250-4999 through interface tokenURI 
    //supers contract tokenURI returns like this:    string :  ipfs://bafybeiha5fn33qi3zlp4zemrqidcp3l3qt4pxayb6uuj24qziyghgpupbu/61 so extract shuffled id at end
    mapping (uint=> bool) public vialToF;//map vial id number to bool true if it's a type F (six type F total)
    mapping (uint=> bool) public chadToMinted;//map ID to see if a super has been minted with a vial and chad
    mapping (uint=> bool) public superToMinted;//map ID to see if a super has been minted with a vial and chad
    mapping (uint=> bool) public upgradesToBurned;//map upgradeToken id to bool true if it's burned 
    mapping (uint=> uint) public superToVial;//map super ID to vial ID used to mint it. All will show 0 at first so make sure super id was minted 
    mapping (uint=> uint) public supersToChad;//map super tokenID to vial ID used to mint a Super. All will show 0 at first so make sure super id was minted 
    mapping (uint=> uint) public chadToSupers;//map chad tokenID to supers ID for 1:1. All will show 0 at first so make sure super id was minted 
    mapping (uint=> uint) public upgradesToSupers;//map upgradeToken ID to upgraded super ID, all 0 issue again watch out, just for public reference
    mapping (uint=> uint) public idToTypeFLink;//map supers id to type F shuffled ipfs metadata file number
    mapping (uint=> bool) public typeFLinkToBool;//maps if a type F uri file id is used or not
    mapping (uint=> uint[]) public superToUpgradeArray;//map super id to array of upgrade token ids burned on it https://solidity-by-example.org/array/ , 

    //this way our API can see all upgrade tokens burned on the super nft and ask that upgradeToken contract for those tokenURIs
    //
    //
    //
    constructor () {
        baseURISupers3250N = "ipfs://superTypeN/";// stand in uri // set baseURI, doesn't exist yet but will be standard like Chad Doge uri
        baseURISupers3250F = "ipfs://superTypeF/";// stand in uri // set baseURI, doesn't exist yet but will be standard like Chad Doge uri
        baseURISupers1750 =  "ipfs://supersPublic/";// stand in uri // set baseURI, doesn't exist yet but will be standard like Chad Doge uri
        chadContract = 0xEb404d0B8BA0a26936b599E7248DAb7715599c96;//Mainnet 0x357928B721890Ed007142e45502A323827caF812 chad doge nft contract; 0xEb404d0B8BA0a26936b599E7248DAb7715599c96 testnet fuji
        superContract = 0xf9b286830c48e535396B54ea42E7F043b713fb3E;//set super contract does not exist yet, it uses the same code as chad doge flatlaunchpeg contract; 0xf9b286830c48e535396B54ea42E7F043b713fb3E  testnet fuji
        vialContract = 0xb9a8915657610daa0064CbBC8F1f6538f03c1902;//set vial contract does not exist yet, it uses the same code as chad doge flatlaunchpeg contract; 0xb9a8915657610daa0064CbBC8F1f6538f03c1902  testnet fuji
        upgradeContract = 0x7f08d48599109289325B4cdeC8F797274f7Ce959;//set upgradeToken contract does not exist yet, we will read tokenURI, do approve and transfer just like vial
        superSafe = 0xc7952F9e71F8866FBb5D57B0cBdA3eCefEAB8F60;//change to a gnosis wallet, holding the 3250 supers we pre-minted

        preminted = 2500; //some dummy test data
        setTypeFVials(701,702,703,704,705,706);//test: some dummy test data, this should only be set after shuffle reveal
    }
    
    receive() external payable {}
    
    event VialBurn(address indexed burner, uint vialsBurned, uint fVialsBurned, uint nVialsBurned, uint _chadID, uint _vialID);//emit when burn vial and upgrade chad doge

    event UpgradesBurn(address indexed burner, uint upgradesBurned, uint _superID, uint _upgradeID);
 
    function setPreminted(uint _amt) public onlyOwner {//set amount of supers preminted
        preminted = _amt;
    }

    function setBlockUnmintedURI(bool status) public onlyOwner {
        blockUnmintedURI = status;
    }

    function setBotsCanMint(bool status) public onlyOwner {
        botsCanMint = status;
    }

    function setChadContract(address _newAddress) public onlyOwner {//set external contract address
        chadContract = _newAddress;
    }

    function setSupersContract(address _newAddress) public onlyOwner {//set external contract address
        superContract = _newAddress;
    }

    function setVialsContract(address _newAddress) public onlyOwner {//set external contract address
        vialContract = _newAddress;
    }

    function setUpgradesContract(address _newAddress) public onlyOwner {//set external contract address
        upgradeContract = _newAddress;
    }

    function setSuperSafe(address _newAddress) public onlyOwner {//set gnosis safe address holding the 3250 preminted supers
        superSafe = _newAddress;
    }

    function setZeroAddress(address _newAddress) public onlyOwner {//set zero address
        zeroAddress = _newAddress;
    }

    function setBaseURISupers3250N(string memory _baseURISupers3250N) public onlyOwner {// set base uri ipfs link to supers that match original chad doge 1:1
        baseURISupers3250N = _baseURISupers3250N;
    }

    function setBaseURISupers3250F(string memory _baseURISupers3250F) public onlyOwner {// set base uri ipfs link to supers that match original chad doge 1:1
        baseURISupers3250F = _baseURISupers3250F;
    }

    function setBaseURISupers1750(string memory _baseURISupers1750) public onlyOwner { // set base uri to mirror original baseuri from supers contract
        baseURISupers1750 = _baseURISupers1750;
    }

    function setBaseExtention(string memory _baseExtention) public onlyOwner { // set base base extention
        baseExtension = _baseExtention;
    }    



    function upgradeChad(uint _vialID, uint _chadID) public nonReentrant{
        if (botsCanMint == false){
            require(msg.sender == tx.origin, "No smart contract bots allowed.");//no smart contract bots allowed
        }
        require (IflatLaunchPeg(chadContract).ownerOf(_chadID) == msg.sender, "You are not the owner of that Chad Doge ID number");//user must own chad
        require (IflatLaunchPeg(vialContract).ownerOf(_vialID) == msg.sender, "You are not the owner of that Vial ID number");//user must own chad
        require (fVialsSet, "Type F Vials must be set first by dev after vials shuffle revealed");//F vials must be set by dev first
        require (IflatLaunchPeg(vialContract).isApprovedForAll(msg.sender, address(this)), "User must first approve vial for transfer first, use dapp");//user must have approved for transfer
        require (IflatLaunchPeg(superContract).isApprovedForAll(superSafe, address(this)), "Dev must first approve supers held in gnosis wallet");//user must have approved for transfer
        _burnVial(_vialID);//burn vial
        _chadMint(_chadID);//"mint" them a Super by transferring one held by our gnosis wallet that holds the first 3250 Supers
    }


    function _burnVial(uint _vialID) internal {//approve transfer of vial first in dapp
        IflatLaunchPeg(vialContract).safeTransferFrom(msg.sender, zeroAddress, _vialID);//burn the upgradeToken by sending it to the zero address
        vialsBurned++;
        if (vialToF[_vialID] == true) {//if vial was a type F
            fVialsBurned++;
            idToTypeFLink[nextMint] = randomizeNewF();//map supers ID to type F ipfs file number 1-6 randomized
            typeFLinkToBool[idToTypeFLink[nextMint]] = true;//mark F link ID as being used, we check this later for random shuffle
        } else {//else vial was type N, and we use implied mapping of chad doge id to supers metadata id 1:1 match
            nVialsBurned++;
        }
        superToVial[nextMint] = _vialID;
        emit VialBurn(tx.origin, vialsBurned, fVialsBurned, nVialsBurned, nextMint, _vialID);
    }

    function _chadMint(uint _chadID) internal { //when user burns a vial with a doge then we send them a supers nft from our preapproved multisig wallet
        require (chadToMinted[_chadID] == false, "Error, chad has already minted a super with a vial");
        chadToMinted[_chadID] = true;
        superToMinted[nextMint] = true;
        IflatLaunchPeg(superContract).safeTransferFrom(superSafe, msg.sender, nextMint);//transfer nextMint ID starting at 0 and going up to as many vials as were minted potentially, these 0-x supers IDs we have preminted to our gnosis safe  wallet
        supersToChad[nextMint] = _chadID;//map the super tokenID minted via vial burning and the chad tokenID it matches
        chadToSupers[_chadID] = nextMint;
        nextMint++;//set to next ID to transfer for next mint
        //transfer super id (same as chad id) to msg sender from the our gnosis multisig wallet that has already approved transfers (we will have preminted 3250 super tokens into our gnosis wallet)
    }


//this function is expensive but is for dapps to read, not intended to be used with a write function currently. Have to unshuffle url subdomain IDs using read functions, then write with unshuffled ID
    function superTokenURI (uint _superID) public view returns(string memory) {//set supers contract to our url and have API read this after supers have been shuffle revealed. Then need to unchuffle subdomain name, have included function for dapps to use to unshuffle
        require (_superID<5000, "Highest super token allowed is ID# 4999");//doublecheck the 4999 vs 5000 alignment
        //require (_superID>=0, "Lowest super token allowed is ID# 0");//doublecheck the 0 vs 1 alignment, comment this line out if 0
        if (_superID<preminted){
            return lowerSuperURI(_superID);
        } else {
            return upperSuperURI(getShuffledTokenID(_superID));
        }
    }

//this function is cheaper but you have to know the shuffled and unshuffled ID pairing already
    function superTokenURI2 (uint _superID, uint _superIdShuffled) public view returns(string memory) {//set supers contract to our url and have API read this after supers have been shuffle revealed. Then need to unchuffle subdomain name, have included function for dapps to use to unshuffle
        require (_superID<5000, "Highest super token allowed is ID# 4999");//doublecheck the 4999 vs 5000 alignment
        require (_superID>=0, "Lowest super token allowed is ID# 0");//doublecheck the 0 vs 1 alignment
        if (_superID<preminted){
            return lowerSuperURI(_superID);
        } else {
            return upperSuperURI(_superIdShuffled);
        }
    }



    function upperSuperURI(uint _shuffledTokenId) private view returns (string memory){
        string memory currentBaseURI = baseURISupers1750;//same baseuri as original supers contract
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(_shuffledTokenId), baseExtension)) : "";//uri ends up being the same as the original supers after shuffle revealed
    }


    function getShuffledTokenID(uint _tokenId) public view returns (uint){//ask supers contract for shuffled ID via tokenURI
        return parseUriID(IflatLaunchPeg(superContract).tokenURI(_tokenId));//call string parser to get shuffled id number
    }
    

    function parseUriID(string memory _parseMe) public pure returns(uint){  //parse token uri to get id number at the end of the string                                            
        strings.slice memory s = _parseMe.toSlice(); //using input string
        strings.slice memory delim = "/".toSlice(); // we look for "/" to show where to slice up the string
        uint _count = s.count(delim);
        require (_count>0,"Error: '/' not found");                                       
        for (uint i = 0; i < _count; i++) {                              
           s.split(delim).toString(); //slice away everything except the last piece                   
        }     
        return (string2num(s.toString())); //return last piece of string as a uint number                                                              
    }


    function string2num(string memory _numString) public pure returns(uint) {//turns a string into a uint
        uint _val=0;
        bytes memory _stringBytes = bytes(_numString);
        for (uint  i =  0; i<_stringBytes.length; i++) {
            uint _exp = _stringBytes.length - i;
            bytes1 _ival = _stringBytes[i];
            uint8 _uval = uint8(_ival);
           uint _jval = _uval - uint(0x30);
   
           _val +=  (uint(_jval) * (10**(_exp-1))); 
        }
      return _val;
    }



    function lowerSuperURI(uint _superID) private view returns (string memory){
        if (blockUnmintedURI == true){
            require (superToMinted[_superID] == true, "Super ID has not been created with a vial yet");
        }
        if (vialToF[superToVial[_superID]] == true) {//use super id to see vial type used in supers mint
            return fVialSuperURI(_superID);//if type F was used then return shuffled F link ID at type F baseuri
        } else {
            return nVialSuperURI(_superID);//else type N with 1:1 mapping implied at type N baseuri, ipfs folder in order, supers ipfs file 1 matches metadata of chad token ID 1 (aka mainnet chad token ID #1 is shuffled id #62 in our case)
        }
    }


    function fVialSuperURI(uint _superId) private view returns (string memory){
        string memory currentBaseURI = baseURISupers3250F;
        uint shuffledTokenIdF = idToTypeFLink[_superId];//get type F uri ID number
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(shuffledTokenIdF), baseExtension)) : "";
    }


    function nVialSuperURI(uint _superId) private view returns (string memory){
        string memory currentBaseURI = baseURISupers3250N;
        uint _chadMatch = supersToChad[_superId]; //get chad id for 1:1 matching, ipfs file numbers match chad ID number
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(_chadMatch), baseExtension)) : "";
    }

    function randomizeNewF() private view returns (uint){//input token id of chad/super being upgraded with F vial
        uint _randMod = (random(6)+1);//get pseudorandom number from block timestamp, use 6 for the six F vials
        uint _randLoops = 0;//track when to exit while loop, should never take more than 6 loops
        while( _randLoops <= 6) {//loop: check if that new number is used already, if so go to next number and repeat loop
            if (typeFLinkToBool[_randMod] == true){//if shuffled id is already used then try next number
                _randMod = (((_randMod +1)%6)+1);//loop through the 1-6 shuffled F uri id numbers
                _randLoops++;//count how many while loops we have donw so far
            }
            else {_randLoops = 100;}//if f link id has not been used yet then set to large number to exit our while loop
            require (_randLoops !=7, "@Dev we encountered error looping through randomizeNewF() function");//if we looped six times and still no empty spots than there is some error
        }
        return _randMod;  //this returns a number 1-6 not already being used
    }

    function random(uint num) private view returns(uint){// num 50 here would return a pseudorandom number between 0-49
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender))) % num;
 }

    function setTypeFVials(uint _F1, uint _F2, uint _F3, uint _F4, uint _F5, uint _F6) public onlyOwner {//Once the IDs are shuffled and revealed in the Vials contract we can set them here. Possible to release before mint out if use <5000 numbers for unrevealed and then set again later after all revealed 
        vialToF[_F1] = true;//token ID number of type F vial revealed after shuffle
        vialToF[_F2] = true;//token ID number of type F vial revealed after shuffle
        vialToF[_F3] = true;//token ID number of type F vial revealed after shuffle
        vialToF[_F4] = true;//token ID number of type F vial revealed after shuffle
        vialToF[_F5] = true;//token ID number of type F vial revealed after shuffle
        vialToF[_F6] = true;//token ID number of type F vial revealed after shuffle
        fVialsSet = true;//mark as having been set
    }



    
        //anything related to UpgradeToken is for later when we make the upgradeTokens, which are different from the vials and supers and chads.

    function upgradeSuper(uint _upgradeId, uint _superId) public nonReentrant{ //burn upgrade token and track which super gets it. Our dapp can read this tracking later to return the upgraded tokenURI in the correlated website subdomains
        if (botsCanMint == false){
            require(msg.sender == tx.origin, "No smart contract bots allowed.");//no smart contract bots allowed
        }
        require (IflatLaunchPeg(superContract).ownerOf(_superId) == msg.sender, "You are not the owner of that Supers ID number");//user must own chad
        require (IflatLaunchPeg(upgradeContract).isApprovedForAll(msg.sender, address(this)), "User must approve upgradeToken for transfer first by contract");//user must have approved for transfer
        _burnUpgradeToken(_upgradeId, _superId);//burn upgradeToken
    }

    function _burnUpgradeToken(uint _upgradeID, uint _supersID) internal {//must approve transfer of upgradeToken first in dapp
        IflatLaunchPeg(upgradeContract).safeTransferFrom(msg.sender, zeroAddress, _upgradeID);//burn the upgradeToken by sending it to the zero address
        upgradesToSupers[_upgradeID] = _supersID; //map upgradeToken id to supers id
        superToUpgradeArray[_supersID].push(_upgradeID);//supers token maps to all upgradeTokens used on it, push adds upgradeToken ID burned to end of array. This is what dapp reads for website subdomains.
        require (upgradesToBurned[_upgradeID] != true, "upgradeToken already marked as burned");
        upgradesToBurned[_upgradeID] = true;//mark upgradeToken id as having been burned
        upgradesBurned++;//increment upgradeTokens burned
        emit UpgradesBurn(tx.origin, upgradesBurned, _supersID, _upgradeID);
    }

    function id2UpgradeArray(uint _ID) public view returns (uint[] memory){
        return superToUpgradeArray[_ID];//returns array of upgrade tokens burned on that supers token id 
    }

}