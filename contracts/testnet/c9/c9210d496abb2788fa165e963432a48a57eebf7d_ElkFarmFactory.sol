/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-01
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: @openzeppelin/contracts/utils/cryptography/EIP712.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;


/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
    function stakingToken() external returns(IERC20);
    function totalSupply() external returns(uint256);
    function balances(address account) external returns(uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stakeWithPermit(uint256 _amount, uint _deadline, uint8 _v, bytes32 _r, bytes32 _s) external returns (uint256);
    function stake(uint256 _amount) external returns (uint256);
    function withdraw(uint256 _amount) external returns (uint256);
    function exit() external;
    function recoverERC20(address _tokenAddress, address _recipient, uint256 _amount) external;

    /* ========== EVENTS ========== */

    // Emitted on staking
    event Staked(address indexed account, uint256 amount);

    // Emitted on withdrawal (including exit)
    event Withdrawn(address indexed account, uint256 amount);

    // Emitted on token recovery
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
    function feesUnit() external returns(uint16);
    function maxFee() external returns(uint16);

    function withdrawalFeeSchedule(uint256) external returns(uint256);
    function withdrawalFeesBps(uint256) external returns(uint256);
    function depositFeeBps() external returns(uint256);
    function collectedFees() external returns(uint256);

    function userLastStakedTime(address user) external view returns(uint32);

    /* ========== VIEWS ========== */

    function depositFee(uint256 _depositAmount) external view returns (uint256);
    function withdrawalFee(address _account, uint256 _withdrawalAmount) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverFees(address _recipient) external;
    function setFees(uint16 _depositFeeBps, uint16[] memory _withdrawalFeesBps, uint32[] memory _withdrawalFeeSchedule) external;

    /* ========== EVENTS ========== */

    // Emitted when fees are (re)configured    
    event FeesSet(uint16 depositFeeBps, uint16[] withdrawalFeesBps, uint32[] feeSchedule);

    // Emitted when a deposit fee is collected
    event DepositFeesCollected(address indexed user, uint256 amount);

    // Emitted when a withdrawal fee is collected
    event WithdrawalFeesCollected(address indexed user, uint256 amount);

    // Emitted when fees are recovered by governance
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

    function rewardTokens(uint256) external view returns(IERC20);
    function rewardTokenAddresses(address rewardAddress) external view returns(bool);
    function periodFinish() external view returns(uint256);
    function rewardsDuration() external view returns(uint256);
    function lastUpdateTime() external view returns(uint256);
    function rewardRates(address rewardAddress) external view returns(uint256);
    function rewardPerTokenStored(address rewardAddress) external view returns(uint256);

    // wallet address => token address => amount
    function userRewardPerTokenPaid(address walletAddress, address tokenAddress) external view returns(uint256);
    function rewards(address walletAddress, address tokenAddress) external view returns(uint256);


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
    function rewardTokenIndex(address _tokenAddress) external view returns(int8);

    /* ========== EVENTS ========== */

    // Emitted when a reward is paid to an account
    event RewardPaid(address indexed token, address indexed account, uint256 reward);

    // Emitted when a leftover reward is recovered
    event LeftoverRewardRecovered(address indexed recipient, uint256 amount);

    // Emitted when rewards emission is started
    event RewardsEmissionStarted(uint256[] rewards, uint256 duration);

    // Emitted when rewards emission ends
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

    /**
     * Represents a snapshot of an LP position at a given timestamp
     */
    struct Position {
            uint112 amount0;
            uint112 amount1;
            uint32 blockTimestamp;
        }

    /* ========== STATE VARIABLES ========== */

    function oracle() external returns(IElkDexOracle);
    function lpToken() external returns(IElkPair);
    function coverageTokenAddress() external returns(address);
    function coverageAmount() external returns(uint256);
    function coverageVestingDuration() external returns(uint32);
    function coverageRate() external returns(uint256);
    function coveragePerTokenStored() external returns(uint256);
    function userCoveragePerTokenPaid(address tokenPaid) external returns(uint256);
    function coverage(address token) external returns(uint256);
    function lastStakedPosition(address user) external returns(uint112 amount0, uint112 amount1, uint32 blockTimeStamp);

    /* ========== VIEWS ========== */

    function coveragePerToken() external view returns (uint256);
    function coverageEarned(address _account) external view returns(uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getCoverage(address _recipient) external;
    // function startEmission(uint256[] memory _rewards, uint256 _duration) external override;
    function startEmission(uint256[] memory _rewards, uint256 _coverage, uint256 _duration) external;
    function recoverLeftoverCoverage(address _recipient) external;
    // function setCoverage(address _tokenAddress, uint256 _coverageAmount, uint32 _coverageVestingDuration) external;

    /* ========== EVENTS ========== */

    // Emitted when the coverage is paid to an account
    event CoveragePaid(address indexed account, uint256 coverage);

    // Emitted when the leftover coverage is recovered
    event LeftoverCoverageRecovered(address indexed recipient, uint256 amount);

}

// File: contracts/interfaces/IElkPermissionedFarmingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IFarmingRewardsPermissioned is IFarmingRewards {

    function setAddressPermission(address _walletAddress, bool _permission) external;

}

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;






/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
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






/**
 * Base contract implementing simple ERC20 token staking functionality (no staking rewards).
 */
contract Staking is ReentrancyGuard, Ownable, IStaking {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // Staking token interface
    IERC20 public immutable stakingToken;
    
    // Total supply of the staking token
    uint256 public totalSupply;

    // Account balances
    mapping(address => uint256) public balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingTokenAddress  // address of the token used for staking (must be ERC20)
    ) {
        require(_stakingTokenAddress != address(0), "E1");
        stakingToken = IERC20(_stakingTokenAddress);
    }

    /**
     * @dev Stake tokens with gasless approval (permit).
     * @param _amount amount to stake
     * @param _deadline permit deadline parameter
     * @param _v permit v parameter
     * @param _r permit r parameter
     * @param _s permit s parameter
     * @return staked amount (may differ from input amount due to e.g., fees)
     */
    function stakeWithPermit(uint256 _amount, uint _deadline, uint8 _v, bytes32 _r, bytes32 _s) external nonReentrant returns(uint256) {
        IERC20Permit(address(stakingToken)).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        return stake(_amount);
    }

    /**
     * @dev Stake tokens.
     * Note: the contract must have sufficient allowance for the staking token.
     * @param _amount amount to stake
     * @return staked amount (may differ from input amount due to e.g., fees)
     */
    function stake(uint256 _amount) public nonReentrant returns(uint256) {
        _amount = _beforeStake(msg.sender, _amount);
        require(_amount > 0, "E2"); // Check after the hook
        totalSupply += _amount;
        balances[msg.sender] += _amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
        return _amount;
    }

    /**
     * @dev Withdraw previously stake tokens.
     * @param _amount amount to withdraw
     * @return withdrawn amount (may differ from input amount due to e.g., fees)
     */
    function withdraw(uint256 _amount) public nonReentrant returns(uint256) {
        _amount = _beforeWithdraw(msg.sender, _amount);
        require(_amount > 0 && _amount <= balances[msg.sender], "E3");  // Check after the hook
        totalSupply -= _amount;
        balances[msg.sender] -= _amount;
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
        return _amount;
    }

    /**
     * @dev Exit the farm, i.e., withdraw the entire token balance of the calling account
     */
    function exit() external nonReentrant {
        _beforeExit(msg.sender);
        withdraw(balances[msg.sender]);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Recover ERC20 tokens held in the contract.
     * Note: privileged governance function to recover tokens mistakenly sent to this contract address.
     * This function cannot be used to withdraw staking tokens.
     * @param _tokenAddress address of the token to recover
     * @param _recipient recovery address
     * @param _amount amount to withdraw
     * @ return withdrawn amount (may differ from input amount due to e.g., fees)
     */
    function recoverERC20(address _tokenAddress, address _recipient, uint256 _amount) external nonReentrant onlyOwner {
        require(_tokenAddress != address(stakingToken), "E4");
        _beforeRecoverERC20(_tokenAddress, _recipient, _amount);
        IERC20 token = IERC20(_tokenAddress);
        token.safeTransfer(_recipient, _amount);
        emit Recovered(_tokenAddress, _recipient, _amount);
    }

    /* ========== HOOKS ========== */

    /**
     * @dev Internal hook called before staking (in the stake() function).
     * @ param _account staker address
     * @param _amount amount being staken
     * @return amount to stake (may be changed by the hook)
     */
    function _beforeStake(address /*_account*/, uint256 _amount) internal virtual returns(uint256) { return _amount; }
    
    /**
     * @dev Internal hook called before withdrawing (in the withdraw() function).
     * @ param _account withdrawer address
     * @param _amount amount being withdrawn
     * @return amount to withdraw (may be changed by the hook)
     */
    function _beforeWithdraw(address /*_account*/, uint256 _amount) internal virtual returns(uint256) { return _amount; }
    
    /**
     * @dev Internal hook called before exiting (in the exit() function).
     * Note: since exit() calls withdraw() internally, the _beforeWithdraw() hook fill fire too. 
     * @param _account address exiting
     */
    function _beforeExit(address _account) internal virtual {}

    /**
     * @dev Internal hook called before recovering tokens (in the recoverERC20() function).
     * @param _tokenAddress address of the token being recovered
     * @param _recipient recovery address
     * @param _amount amount being withdrawn
     */
    function _beforeRecoverERC20(address _tokenAddress, address _recipient, uint256 _amount) internal virtual {}

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



/**
 * Contract implementing simple ERC20 token staking functionality and supporting deposit/withdrawal fees (no staking rewards).
 */
contract StakingFee is Staking, IStakingFee {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // Fee unit
    uint16 public constant feesUnit = 10000;

    // Maximum fee (20%)
    uint16 public constant maxFee = 2000;

    // Schedule of withdrawal fees represented as a sorted array of durations
    uint256[] public withdrawalFeeSchedule;

    // Withdrawal fees in basis points (fee unit) represented as an array of the same length as withdrawalFeeSchedule
    uint256[] public withdrawalFeesBps;

    // Withdrawal fees examples.
    // 
    // 1. 10% after 1 hour, 1% after a day, 0% after a week
    //     withdrawalFeeSchedule = [3600, 86400]
    //     withdrawalFeesBps     = [1000, 100]
    // 
    // 2. No withdrawal fee
    //    withdrawalFeeSchedule = []
    //    withdrawalFeesBps.    = []

    // Deposit (staking) fee in basis points (fee unit)
    uint256 public depositFeeBps;

    // Counter of collected fees
    uint256 public collectedFees;

    // Last staking time for each user
    mapping(address => uint32) public userLastStakedTime;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingTokenAddress,           // address of the token used for staking (must be ERC20)
        uint16 _depositFeeBps,                  // deposit fee in basis points
        uint16[] memory _withdrawalFeesBps,     // aligned to fee schedule
        uint32[] memory _withdrawalFeeSchedule  // assumes a sorted array
    ) Staking(_stakingTokenAddress) {
        setFees(_depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule);
    }
    
    /* ========== VIEWS ========== */

    /**
     * @dev Calculate the deposit fee for a given amount.
     * @param _depositAmount amount to stake
     * @return fee paid upon deposit
     */
    function depositFee(uint256 _depositAmount) public view returns (uint256) {
        if (depositFeeBps > 0) {
            return _depositAmount * depositFeeBps / feesUnit;
        } else {
            return 0;
        }
    }

    /**
     * @dev Calculate the withdrawal fee for a given amount.
     * @param _account user wallet address
     * @param _withdrawalAmount amount to withdraw
     * @return fee paid upon withdrawal
     */
    function withdrawalFee(address _account, uint256 _withdrawalAmount) public view returns (uint256) {
        for (uint i=0; i < withdrawalFeeSchedule.length; ++i) {
            if (block.timestamp - userLastStakedTime[_account] < withdrawalFeeSchedule[i]) {
                return _withdrawalAmount * withdrawalFeesBps[i] / feesUnit;
            }
        }
        return 0;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Recover collected fees held in the contract.
     * Note: privileged function for governance
     * @param _recipient fee recovery address
     */
    function recoverFees(address _recipient) external onlyOwner nonReentrant {
        _beforeRecoverFees(_recipient);
        uint256 previousFees = collectedFees;
        collectedFees = 0;
        emit FeesRecovered(previousFees);
        stakingToken.safeTransfer(_recipient, previousFees);
    }

    /**
     * @dev Configure the fees for this contract.
     * @param _depositFeeBps deposit fee in basis points
     * @param _withdrawalFeesBps withdrawal fees in basis points
     * @param _withdrawalFeeSchedule withdrawal fees schedule
     */
    function setFees(uint16 _depositFeeBps, uint16[] memory _withdrawalFeesBps, uint32[] memory _withdrawalFeeSchedule) public onlyOwner {
        _beforeSetFees();
        require(_withdrawalFeeSchedule.length <= 10 && _withdrawalFeeSchedule.length == _withdrawalFeesBps.length, "E5");
        require(_depositFeeBps <  maxFee + 1, "E6");
        uint32 lastFeeSchedule = 0;
        uint16 lastWithdrawalFee = maxFee + 1;
        for(uint i=0; i < _withdrawalFeeSchedule.length; ++i) {
           require(_withdrawalFeeSchedule[i] > lastFeeSchedule, "E7");
           require(_withdrawalFeesBps[i] < lastWithdrawalFee, "E8");
           lastFeeSchedule = _withdrawalFeeSchedule[i];
           lastWithdrawalFee = _withdrawalFeesBps[i];
        }
        withdrawalFeeSchedule = _withdrawalFeeSchedule;
        withdrawalFeesBps = _withdrawalFeesBps;
        depositFeeBps = _depositFeeBps;
        emit FeesSet(_depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule);
    }

    /* ========== HOOKS ========== */

    // Override _beforeStake() hook to collect the deposit fee and update associated state
    function _beforeStake(address _account, uint256 _amount) internal virtual override returns(uint256) {
        uint256 fee = depositFee(_amount);
        userLastStakedTime[msg.sender] = uint32(block.timestamp);
        if (fee > 0) {
            collectedFees += fee;
            emit DepositFeesCollected(msg.sender, fee);
        }
        return super._beforeStake(_account, _amount - fee);
    }
    

    // Override _beforeWithdrawl() hook to collect the withdrawal fee and update associated state
    function _beforeWithdraw(address _account, uint256 _amount) internal virtual override returns(uint256) {
        uint256 fee = withdrawalFee(msg.sender, _amount);
        if (fee > 0) {
            collectedFees += fee;
            emit WithdrawalFeesCollected(msg.sender, fee);
        }
        return super._beforeWithdraw(_account, _amount - fee);
    }

    /**
     * @dev Internal hook called before recovering fees (in the recoverFees() function).
     * @param _recipient recovery address
     */
    function _beforeRecoverFees(address _recipient) internal virtual {}

    /**
     * @dev Internal hook called before setting fees (in the setFees() function).
     */
    function _beforeSetFees() internal virtual {}

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




/**
 * Contract implementing simple ERC20 token staking functionality with staking rewards and deposit/withdrawal fees.
 */
contract StakingRewards is StakingFee, IStakingRewards {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // List of reward token interfaces
    IERC20[] public rewardTokens;

    // Reward token addresses (maps every reward token address to true, others to false)
    mapping(address => bool) public rewardTokenAddresses;

    // Timestamp when rewards stop emitting
    uint256 public periodFinish;

    // Duration for reward emission
    uint256 public rewardsDuration;

    // Last time the rewards were updated
    uint256 public lastUpdateTime;

    // Reward token rates (maps every reward token to an emission rate, i.e., how many tokens emitted per second)
    mapping(address => uint256) public rewardRates;

    // How many tokens are emitted per staked token
    mapping(address => uint256) public rewardPerTokenStored;

    // How many reward tokens were paid per user (wallet address => token address => amount)
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;

    // Accumulator of reward tokens per user (wallet address => token address => amount)
    mapping(address => mapping(address => uint256)) public rewards;
    
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingTokenAddress,           // address of the token used for staking (must be ERC20)
        address[] memory _rewardTokenAddresses, // addresses the reward tokens (must be ERC20)
        uint256 _rewardsDuration,               // reward emission duration
        uint16 _depositFeeBps,                  // deposit fee in basis points
        uint16[] memory _withdrawalFeesBps,     // aligned to fee schedule
        uint32[] memory _withdrawalFeeSchedule  // assumes a sorted array
    ) StakingFee(_stakingTokenAddress, _depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule) {
        require(_rewardTokenAddresses.length > 0, "E9");
        // update reward data structures
        for (uint i=0; i < _rewardTokenAddresses.length; ++i) {
            _addRewardToken(_rewardTokenAddresses[i]);
        }
        rewardsDuration = _rewardsDuration;
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Return the last time rewards are applicable (the lowest of the current timestamp and the rewards expiry timestamp).
     * @return timestamp
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * @dev Return the reward per staked token for a given reward token address.
     * @ _tokenAddress reward token address
     * @return amount of reward per staked token
     */
    function rewardPerToken(address _tokenAddress) public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored[_tokenAddress];
        }
        return rewardPerTokenStored[_tokenAddress] + (lastTimeRewardApplicable() - lastUpdateTime) * rewardRates[_tokenAddress] * 1e18 / totalSupply;
    }

    /**
     * @dev Return the total reward earned by a user for a given reward token address.
     * @ _tokenAddress reward token address
     * @ _account user wallet address
     * @return amount earned
     */
    function earned(address _tokenAddress, address _account) public view returns (uint256) {
        return balances[_account] * (rewardPerToken(_tokenAddress) - userRewardPerTokenPaid[_tokenAddress][_account]) / 1e18 + rewards[_tokenAddress][_account];
    }

    /**
     * @dev Indicate if the contract is currently emitting rewards
     * @return true iff the contract is currently emitting
     */
    function emitting() public view returns(bool) {
        return block.timestamp <= periodFinish;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev claim the specified token reward for a staker
     * @param _tokenAddress the address of the reward token
     * @param _recipient the address of the staker that should receive the reward
     * @ return amount of reward received
     */
    function getReward(address _tokenAddress, address _recipient) public nonReentrant updateRewards(msg.sender) {
        return _getReward(_tokenAddress, _recipient);
    }

    /**
     * @dev claim rewards for all the reward tokens for the staker
     * @param _recipient address of the recipient to receive the rewards
     */
    function getRewards(address _recipient) public nonReentrant updateRewards(msg.sender) {
        for (uint i=0; i < rewardTokens.length; ++i) {
            _getReward(address(rewardTokens[i]), _recipient);
        }
    }

    /**
     * @dev Start the emission of rewards to stakers. The owner must send reward tokens to the contract before calling this function.
     * Note: Can only be called by owner when the contract is not emitting rewards.
     * @param _rewards array of rewards amounts for each reward token
     * @param _duration duration in seconds for which rewards will be emitted
     */
    function startEmission(uint256[] memory _rewards, uint256 _duration) public virtual nonReentrant onlyOwner whenNotEmitting updateRewards(address(0)) {
        require(_duration > 0, "E10");
        require(_rewards.length == rewardTokens.length, "E11");

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
                require(rewardRates[tokenAddress] <= balance / rewardsDuration, "E3");
            } else { // Handle carefully where rewardsToken is the same as stakingToken (need to subtract total supply)
                require(rewardRates[tokenAddress] <= (balance - totalSupply) / rewardsDuration, "E3");
            }
        }
        
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        emit RewardsEmissionStarted(_rewards, _duration);
    }

    /**
     * @dev stop the reward emission process and transfer the remaining reward tokens to a specified address
     * Note: can only be called by owner when the contract is currently emitting rewards
     * @param _refundAddress the address to receive the remaining reward tokens
     */
    function stopEmission(address _refundAddress) external nonReentrant onlyOwner whenEmitting {
        _beforeStopEmission(_refundAddress);
        uint256 remaining = 0;
        if (periodFinish > block.timestamp) {
            remaining = periodFinish - block.timestamp;
        }

        periodFinish = block.timestamp;

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

    /**
     * @dev recover leftover reward tokens and transfer them to a specified recipient
     * Note: can only be called by owner when the contract is not emitting rewards
     * @param _tokenAddress address of the reward token to be recovered
     * @param _recipient address to receive the recovered reward tokens
     */
    function recoverLeftoverReward(address _tokenAddress, address _recipient) external onlyOwner whenNotEmitting {
        require(totalSupply == 0, "E12");
        if (rewardTokenAddresses[_tokenAddress]) {
            _beforeRecoverLeftoverReward(_tokenAddress, _recipient);
            IERC20 token = IERC20(_tokenAddress);
            uint256 amount = token.balanceOf(address(this));
            if (amount > 0) {
                token.safeTransfer(_recipient, amount);
            }
            emit LeftoverRewardRecovered(_recipient, amount);
        }
    }

    /**
     * @dev add a reward token to the contract
     * Note: can only be called by owner when the contract is not emitting rewards
     * @param _tokenAddress address of the new reward token
     */
    function addRewardToken(address _tokenAddress) external onlyOwner whenNotEmitting {
        _addRewardToken(_tokenAddress);
    }

    /**
     * @dev Return the array index of the provided token address (if applicable)
     * @param _tokenAddress address of the LP token
     * @return the array index for _tokenAddress or -1 if it is not a reward token
     */
    function rewardTokenIndex(address _tokenAddress) public view returns(int8) {
        if (rewardTokenAddresses[_tokenAddress]) {
            for (uint i=0; i < rewardTokens.length; ++i) {
                if (address(rewardTokens[i]) == _tokenAddress) {
                    return int8(int256(i));
                }
            }
        }
        return -1;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Get the reward amount of a token for a specific recipient
     * @param _tokenAddress address of the token
     * @param _recipient address of the recipient
     */
    function _getReward(address _tokenAddress, address _recipient) private {
        require(msg.sender == owner() || msg.sender == _recipient, "E14");
        require(rewardTokenAddresses[_tokenAddress], "E13");
        uint256 reward = rewards[_tokenAddress][_recipient];
        if (reward > 0) {
            rewards[_tokenAddress][_recipient] = 0;
            IERC20(_tokenAddress).safeTransfer(_recipient, reward);
            emit RewardPaid(_tokenAddress, _recipient, reward);
        }
    }
    
    /**
     * @dev Add a token as a reward token
     * @param _tokenAddress address of the token to be added as a reward token
     */
    function _addRewardToken(address _tokenAddress) private {
        require(rewardTokens.length <= 15, "E15");
        require(_tokenAddress != address(0), "E1");
        if (!rewardTokenAddresses[_tokenAddress]) {
            rewardTokens.push(IERC20(_tokenAddress));
            rewardTokenAddresses[_tokenAddress] = true;
        }
    }

    /* ========== HOOKS ========== */

    // Override _beforeStake() hook to ensure staking is only possible when rewards are emitting
    function _beforeStake(address _account, uint256 _amount) internal virtual override whenEmitting returns(uint256) {
        return super._beforeStake(_account, _amount);
    }

    // Override _beforeExit() hook to claim all rewards for the account exiting
    function _beforeExit(address _account) internal virtual override {
        getRewards(msg.sender);
        super._beforeExit(_account);
    }

    // Override _beforeRecoverERC20() hook to prevent recovery of a reward token
    function _beforeRecoverERC20(address _tokenAddress, address _recipient, uint256 _amount) internal virtual override {
        require(!rewardTokenAddresses[_tokenAddress], "E16");
        super._beforeRecoverERC20(_tokenAddress, _recipient, _amount);
    }

    // Override _beforeSetFees() hook to prevent settings fees when rewards are emitting
    function _beforeSetFees() internal virtual override {
        require(block.timestamp > periodFinish, "E17");
        super._beforeSetFees();
    }

    // New hooks

    /**
     * @dev Internal hook called before starting the emission process (in the startEmission() function).
     * @param _rewards array of rewards per token.
     * @param _duration emission duration.
     */
    function _beforeStartEmission(uint256[] memory _rewards, uint256 _duration) internal virtual {}

    /**
     * @dev Internal hook called before stopping the emission process (in the stopEmission() function).
     * @param _refundAddress address to refund the remaining reward to
     */
    function _beforeStopEmission(address _refundAddress) internal virtual {}

    /**
     * @dev Internal hook called before recovering leftover rewards (in the recoverLeftoverRewards() function).
     * @param _tokenAddress address of the token to recover
     * @param _recipient address to recover the leftover rewards to
     */
    function _beforeRecoverLeftoverReward(address _tokenAddress, address _recipient) internal virtual {}
    
    /* ========== MODIFIERS ========== */
    
    /**
     * @dev Modifier to update rewards of a given account.
     * @param _account account to update rewards for
     */
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

    /**
     * @dev Modifier to check if rewards are emitting.
     */
    modifier whenEmitting() {
        require(block.timestamp <= periodFinish, "E18");
        _;
    }

    /**
     * @dev Modifier to check if rewards are not emitting.
     */
    modifier whenNotEmitting() {
        require(block.timestamp > periodFinish, "E17");
        _;
    }
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






/**
 * Contract implementing simple ERC20 token staking functionality with staking rewards, impermanent loss coverage, and deposit/withdrawal fees.
 */
contract FarmingRewards is StakingRewards, IFarmingRewards {
    using SafeERC20 for IERC20;

    /**
     * Represents a snapshot of an LP position at a given timestamp
     */
    // struct Position {
    //     uint112 amount0;         // amount of token0
    //     uint112 amount1;         // amount of token1
    //     uint32 blockTimestamp;   // timestamp
    // }

    /* ========== STATE VARIABLES ========== */

    // Interface to the ElkDex pricing oracle on this blockchain
    IElkDexOracle public immutable oracle;

    // Interface to the LP token that is staked in this farm
    IElkPair public immutable lpToken;

    // Address of the coverage token
    address public coverageTokenAddress;

    // Total amount of coverage available (worst case max amount)
    uint256 public coverageAmount;

    // Time until a farmed position is fully covered against impermanent loss (100%)
    uint32 public coverageVestingDuration;

    // Rate of coverage vesting
    uint256 public coverageRate;

    // Coverage amount per token staked in the farm
    uint256 public coveragePerTokenStored;
    
    // How much coverage was paid per user (wallet address => amount)
    mapping(address => uint256) public userCoveragePerTokenPaid;

    // Accumulator of coverage tokens per user (wallet address => amount)
    mapping(address => uint256) public coverage;
    
    // Last farming position for a given user (wallet address => position)
    mapping(address => Position) public lastStakedPosition;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _oracleAddress,                 // address of the price oracle
        address _lpTokenAddress,                // address of the staking LP token (must be an ElkDex LP)
        address _coverageTokenAddress,          // address of the token that the coverage is paid in
        uint256 _coverageAmount,                // total amount of coverage
        uint32 _coverageVestingDuration,        // time it takes to vest 100% of the coverage (min. 1 day)
        address[] memory _rewardTokenAddresses, // addresses the reward tokens (must be ERC20)
        uint256 _rewardsDuration,               // reward emission duration
        uint16 _depositFeeBps,                  // deposit fee in basis points
        uint16[] memory _withdrawalFeesBps,     // aligned to fee schedule
        uint32[] memory _withdrawalFeeSchedule  // assumes a sorted array
    ) StakingRewards(_lpTokenAddress, _rewardTokenAddresses, _rewardsDuration, _depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule) {
        oracle = IElkDexOracle(_oracleAddress);
        lpToken = IElkPair(_lpTokenAddress);

        if (_coverageTokenAddress != address(0)) {
            require(lpToken.token0() == _coverageTokenAddress || lpToken.token1() == _coverageTokenAddress, "Coverage token not in LP");
        }
        
        require(lpToken.factory() == oracle.factory(), "Only supports LPs on ElkDex");
        require(_coverageVestingDuration >= 24 * 3600, "Coverage duration must be >= 1 day");
        require(_coverageVestingDuration <= rewardsDuration, "Coverage duration > rewards duration");
        coverageTokenAddress = _coverageTokenAddress;
        coverageAmount = _coverageAmount;
        coverageVestingDuration = _coverageVestingDuration;
    }
    
    /* ========== VIEWS ========== */

    /**
     * @dev Return the coverage per staked token (in coverage token amounts)
     * @return amount of coverage per staked token
     */
    function coveragePerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return coveragePerTokenStored;
        }
        return
            // does this work for non 18 dec tokens?  rate = _coverage / rewardsDuration, here rate is converted back to 18 dec
            coveragePerTokenStored + (lastTimeRewardApplicable() - lastUpdateTime) * coverageRate * 1e18 / totalSupply;
    }

    /**
     * @dev Return the total coverage earned by a user.
     * @param _account user wallet address
     * @return coverage amount earned
     */
    function coverageEarned(address _account) public view returns(uint256) {
        require(coverageTokenAddress != address(0), "No coverage");
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

    /**
     * @dev claim the coverage for a staker
     * @param _recipient the address of the staker that should receive the coverage
     * @ return the amount of reward received
     */
    function getCoverage(address _recipient) public nonReentrant updateCoverage(_recipient) {
        require(msg.sender == owner() || msg.sender == _recipient, "Only owner/recipient can call");
        require(coverageTokenAddress != address(0), "No coverage");
        uint256 cov = coverage[_recipient];
        if (cov > 0) {
            coverage[_recipient] = 0;
            IERC20(coverageTokenAddress).safeTransfer(_recipient, cov);
            emit CoveragePaid(_recipient, cov);
        }
    }

    // Override startEmission() so it calls the expanded function that includes the coverage amount
    /**
     * @dev Start the emission of rewards to stakers with no coverage. The owner must send reward tokens to the contract before calling this function.
     * Note: Can only be called by owner when the contract is not emitting rewards.
     * @param _rewards array of rewards amounts for each reward token
     * @param _duration duration in seconds for which rewards will be emitted
     */
    function startEmission(uint256[] memory _rewards, uint256 _duration) public override(StakingRewards, IStakingRewards) onlyOwner {
        return startEmission(_rewards, 0, _duration);
    }

    /**
     * @dev Start the emission of rewards to stakers. The owner must send reward and coverage tokens to the contract before calling this function.
     * Note: Can only be called by owner when the contract is not emitting rewards.
     * @param _rewards array of rewards amounts for each reward token
     * @param _coverage total amount of coverage provided to users (worst case max)
     * @param _duration duration in seconds for which rewards will be emitted (and coverage will be active)
     */
    function startEmission(uint256[] memory _rewards, uint256 _coverage, uint256 _duration) public onlyOwner updateCoverage(address(0)) {
        super.startEmission(_rewards, _duration);
        require(coverageVestingDuration <= rewardsDuration, "Coverage duration > rewards duration");  // must check again
        coverageRate = _coverage / rewardsDuration;  // rewardsDuration, not coverageVestingDuration which can be shorter!

        if (coverageTokenAddress != address(0) && _coverage > 0) {
            // Ensure the provided coverage amount is not more than the balance in the contract
            uint256 balance = IERC20(coverageTokenAddress).balanceOf(address(this));
            int8 tokenIndex = rewardTokenIndex(coverageTokenAddress);
            if (tokenIndex >= 0) {
                balance -= _rewards[uint256(int256(tokenIndex))];
            }
            require(coverageRate <= balance / rewardsDuration, "coverage > balance");
        }
    }

    /**
     * @dev recover leftover coverage tokens and transfer them to a specified recipient
     * Note: can only be called by owner when the contract is not emitting rewards
     * @param _recipient address to receive the recovered coverage tokens
     */
    function recoverLeftoverCoverage(address _recipient) public virtual onlyOwner whenNotEmitting {
        require(totalSupply == 0, "Can't recover if tokens are staked");
        require(coverageTokenAddress != address(0), "No coverage");
        _beforeRecoverLeftoverCoverage(_recipient);
        IERC20 token = IERC20(coverageTokenAddress);
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            token.safeTransfer(_recipient, amount);
        }
        emit LeftoverCoverageRecovered(_recipient, amount);
    }

    // function setCoverage(address _tokenAddress, uint256 _coverageAmount, uint32 _coverageVestingDuration) external onlyOwner whenNotEmitting {
    //     require(lpToken.token0() == _tokenAddress || lpToken.token1() == _tokenAddress, "Coverage token not in LP");
    //     require(coveragePerToken() == 0, "Can't set, if coverage was accumulated.");
    //     require(_coverageVestingDuration >= 24 * 3600, "Duration must be >= 1 day");
    //     require(_coverageVestingDuration <= rewardsDuration, "Coverage duration > rewards duration");
    //     coverageTokenAddress = _tokenAddress;
    //     coverageAmount = _coverageAmount;
    //     coverageVestingDuration = _coverageVestingDuration;
    // }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Return the LP position for a given amount of LP token.
     * @param _amount the amount of LP token
     * @return the corresponding LP position (amount0, amount1, timestamp)
     */
    function position(uint256 _amount) private view returns(Position memory) {
        (uint112 reserve0, uint112 reserve1, uint32 timestamp) = lpToken.getReserves();
        uint256 totalAmount = lpToken.totalSupply();
        uint112 amount0 = uint112((_amount * reserve0) / totalAmount);
        uint112 amount1 = uint112((_amount * reserve1) / totalAmount);
        return Position(amount0, amount1, timestamp);
    }

    /**
     * @dev Return the value in WETH of the given LP position.
     * @param _position LP position
     * @return the value in WETH
     */
    function lpValueWeth(Position memory _position) private view returns(uint256) {
        return oracle.consultWeth(lpToken.token0(), _position.amount0) + oracle.consultWeth(lpToken.token1(), _position.amount1);
    }

    /**
     * @dev Return the coverage in WETH for the given HODL and OUT values.
     * @param _hodlValue the value (in WETH) if the tokens making up the LP were kept unpaired
     * @param _outValue the value (in WETH) of the LP token position
     * @return coverage in WETH
     */
    function wethCoverage(uint256 _hodlValue, uint256 _outValue) private pure returns(uint256) {
        
        if (_hodlValue > _outValue) { // there is IL
            // hodl value - out value
            return _hodlValue - _outValue;
        } 

        return 0;
    }

    /**
     * @dev Return the coverage in coverage token amount for the given HODL and OUT values.
     * @param _hodlValue the value (in WETH) if the tokens making up the LP were kept unpaired
     * @param _outValue the value (in WETH) of the LP token position
     * @return coverage in coverage token amount
     */
    function tokenCoverage(uint256 _hodlValue, uint256 _outValue) private view returns(uint256) {
        uint256 wethCov = wethCoverage(_hodlValue, _outValue);
        if (wethCov == 0) {
            return 0;
        }
        return oracle.consult(oracle.weth(), wethCov, coverageTokenAddress);
    }

    /**
     * @dev Return the vested coverage in coverage token amount for the given HODL and OUT values since the provided timestamp.
     * @param _hodlValue the value (in WETH) if the tokens making up the LP were kept unpaired
     * @param _outValue the value (in WETH) of the LP token position
     * @param _lastTimestamp the start timestamp (when the LP token position was created)
     * @return vested coverage in coverage token amount
     */
    function vestedCoverage(uint256 _hodlValue, uint256 _outValue, uint32 _lastTimestamp) private view returns(uint256) {
        if (block.timestamp - _lastTimestamp < coverageVestingDuration) {
            return tokenCoverage(_hodlValue, _outValue) * (block.timestamp - _lastTimestamp) / coverageVestingDuration;
        } else {
            return tokenCoverage(_hodlValue, _outValue);
        }
    }

    /* ========== HOOKS ========== */

    // Override _beforeStake() hook to ensure staking updates the coverage
    function _beforeStake(address _account, uint256 _amount) internal virtual override updateCoverage(_account) returns(uint256) {
        return super._beforeStake(_account, _amount);
    }

    // Override _beforeWithdraw() hook to ensure withdrawing updates the coverage
    function _beforeWithdraw(address _account, uint256 _amount) internal virtual override updateCoverage(_account) returns(uint256) {
        return super._beforeWithdraw(_account, _amount);
    }

    // Override _beforeExit() hook to claim all coverage for the account exiting
    function _beforeExit(address _account) internal virtual override {
        getCoverage(_account);
        super._beforeExit(_account);
    }

    // Override _beforeRecoverERC20() hook to prevent recovery of a coverage token
    function _beforeRecoverERC20(address _tokenAddress, address _recipient, uint256 _amount) internal virtual override {
        require(_tokenAddress != coverageTokenAddress, "Can't recover coverage token!");
        super._beforeRecoverERC20(_tokenAddress, _recipient, _amount);
    }

    // New hooks

    /**
     * @dev Internal hook called before recovering leftover coverage (in the recoverLeftoverCoverage() function).
     * @param _recipient address to recover the leftover coverage to
     */
    function _beforeRecoverLeftoverCoverage(address _recipient) internal virtual {}

    /* ========== MODIFIERS ========== */
    
    /**
     * @dev Modifier to update the coverage of a given account.
     * @param _account account to update coverage for
     */
    modifier updateCoverage(address _account) {
        coveragePerTokenStored = coveragePerToken();
        lastUpdateTime = lastTimeRewardApplicable();     // it seems fine to reuse this here
        oracle.update(lpToken.token0(), oracle.weth());  // update oracle for first token
        oracle.update(lpToken.token1(), oracle.weth());  // ditto for the second token
        if (_account != address(0)) {
            coverage[_account] = coverageEarned(_account);
            userCoveragePerTokenPaid[_account] = coveragePerTokenStored;
            lastStakedPosition[_account] = position(balances[_account]); // don't forget to reset the last position info
        }
        _;
    }

}

// File: contracts/FarmingRewardsPermissoned.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;




/**
 * Contract enabling staking permissions for FarmingRewards.
 */
contract FarmingRewardsPermissioned is FarmingRewards, IFarmingRewardsPermissioned {
    
    mapping(address => bool) public permittedAddresses;

    constructor(
        address _oracleAddress,                 // address of the price oracle
        address _lpTokenAddress,                // address of the staking LP token (must be an ElkDex LP)
        address _coverageTokenAddress,          // address of the token that the coverage is paid in
        uint256 _coverageAmount,                // total amount of coverage
        uint32 _coverageVestingDuration,        // time it takes to vest 100% of the coverage (min. 1 day)
        address[] memory _rewardTokenAddresses, // addresses the reward tokens (must be ERC20)
        uint256 _rewardsDuration,               // reward emission duration
        uint16 _depositFeeBps,                  // deposit fee in basis points
        uint16[] memory _withdrawalFeesBps,     // aligned to fee schedule
        uint32[] memory _withdrawalFeeSchedule  // assumes a sorted array
    ) FarmingRewards(_oracleAddress, _lpTokenAddress, _coverageTokenAddress, _coverageAmount, _coverageVestingDuration, 
                    _rewardTokenAddresses, _rewardsDuration, _depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule) {

    }

    function setAddressPermission(address _walletAddress, bool _permission) external onlyOwner {
        permittedAddresses[_walletAddress] = _permission;
    }

    // Override _beforeStake() hook to ensure address is permitted to stake
    function _beforeStake(address _account, uint256 _amount) internal virtual override returns(uint256) {
        
        require(permittedAddresses[msg.sender], "E25");
        
        return super._beforeStake(_account, _amount);
    }

}

// File: contracts/ElkPermissionedFactoryHelper.sol


pragma solidity >=0.8.0;


/* Library containing a helper function that creates new FarmingRewards contracts in the ElkFarmFactory.  
It was separated out due to contract size limitations.  Farm manager address must be passed in so that the ownership
is always transfered to the FarmManager contract. */


library ElkFactoryHelper {

    function createFarmContract(bytes memory _abi, bytes32 _salt, address _farmManager) external returns(address addr) {
        
        bytes memory bytecode = abi.encodePacked(type(FarmingRewardsPermissioned).creationCode, _abi);
        
        assembly {
        addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
        if iszero(extcodesize(addr)) {
            revert(0, 0)
            }
        }

        FarmingRewardsPermissioned(addr).transferOwnership(_farmManager);

    }

}
// File: contracts/ElkPermissionedFarmFactory.sol


// 
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
// 
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;







/* Contract that is used by users to create FarmingRewards contracts. It stores each farm as it's created, as well as the current 
owner of each farm.  It also contains various uitlity functions for use by Elk. */

contract ElkFarmFactory is IElkFarmFactory, Ownable {

    mapping(address => mapping(address => address)) public getFarm;
    address[] public allFarms;
    address public farmManager;
    mapping(address => address) public getCreator;
    
    IERC20 public feeToken = IERC20(0xeEeEEb57642040bE42185f49C52F7E9B38f8eeeE);
    uint256 public fee = 1 * 10 ** 18;
    uint256 public maxFee = 1000000 * 10 ** 18;
    
    constructor() {
    }


    // Main function in the contract. Creates a new FarmingRewards contract, stores the farm address by creator and the given LP token, and also stores 
    // the creator of the contract by the new farm address.  This is where the fee is taken from the user.
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
            
            // each user is only able to create one FarmingRewards contract per LP token.
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

    // Utility function to be used by Elk.  Changes which manager contract will be assigned ownership of each farm on creation.
    // This is available in case any updates are made to the FarmManager contract.  Ownership is not changed retroactively, so any created
    // farms will always have the same manager contract.
    function setManager(address managerAddress) external override onlyOwner {
        require(managerAddress != address(0), "0 addr");
        farmManager = managerAddress;
        emit ManagerSet(managerAddress);
    }


    // Takes fee for contract creation. Factory must be approved to spend the feeToken before creating a new farm.
    function _takeFee() private {
        require(feeToken.balanceOf(msg.sender) >= fee, "No fee");
        feeToken.transferFrom(msg.sender, address(this), fee);
    }

    // Utility function used by Elk to change the fee amount charged on contract creation.  Can never be more than the maxFee set stored in the contract.
    function setFee(uint256 newFee) external onlyOwner {
        require(newFee < maxFee, "Fee > max");
        fee = newFee;
        emit FeeSet(newFee);
    }

    // Utility function used by Elk to recover the fees gathered by the factory.
    function withdrawFees() external onlyOwner {
        _withdrawFees();
    }

    function _withdrawFees() private {
        uint256 balance = feeToken.balanceOf(address(this));
        feeToken.transfer(msg.sender, balance);
        emit FeesRecovered(balance);
    }

    // Change ownership of a farm, only used by Elk.

    function overrideOwnership(address farmAddress) external onlyOwner {
        _overrideOwnership(farmAddress);
    }

        
    // This function is available to Elk in case any "Scam" or nefarious farms are created using the contract.
    // Elk will be able to stop the offending farm and allow users to recover funds.  
    function _overrideOwnership(address farmAddress) private {
        address creatorAddress = getCreator[farmAddress];

        require(creatorAddress != msg.sender, "Already Owned");
        require(creatorAddress != address(0), "NF");

        IFarmingRewards rewardsContract = IFarmingRewards(farmAddress);

        address lpTokenAddress = address(rewardsContract.stakingToken());
        // allows creator to make another farm with same staking token, should we prevent this somehow?
        getFarm[creatorAddress][lpTokenAddress] = address(0);


        getFarm[msg.sender][lpTokenAddress] = farmAddress;
        getCreator[farmAddress] = msg.sender;
    }

}