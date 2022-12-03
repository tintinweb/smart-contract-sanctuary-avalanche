/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-02
*/

// Sources flattened with hardhat v2.12.3 https://hardhat.org

// File contracts/Authorization.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

contract Authorization {
    address public owner;
    address public newOwner;
    mapping(address => uint8) public isPermitted;
    event Authorize(address user);
    event Deauthorize(address user);
    event StartOwnershipTransfer(address user);
    event TransferOwnership(address user);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier auth {
        require(isPermitted[msg.sender] == 1, "Action performed by unauthorized address.");
        _;
    }
    function transferOwnership(address newOwner_) external onlyOwner {
        newOwner = newOwner_;
        emit StartOwnershipTransfer(newOwner_);
    }
    function takeOwnership() external {
        require(msg.sender == newOwner, "Action performed by unauthorized address.");
        owner = newOwner;
        newOwner = address(0);
        emit TransferOwnership(owner);
    }
    function permit(address user) external onlyOwner {
        isPermitted[user] = 1;
        emit Authorize(user);
    }
    function deny(address user) external onlyOwner {
        isPermitted[user] = 0;
        emit Deauthorize(user);
    }
}


// File contracts/interfaces/IAccountWithdrawal.sol


pragma solidity 0.8.17;

interface IAccountWithdrawal {
    struct DailyInfo {
        uint256 amount;
        uint256 lastTimestamp;
        uint16 numOfTimes;
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/cryptography/[email protected]


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


// File contracts/TriplayPolicy.sol


pragma solidity 0.8.17;



contract TriplayPolicy is Authorization {
    using ECDSA for bytes32;

    enum CriticalActionStatus {Inactive, Pending, Executed, Vetoed}

    struct CriticalAction {
        bytes32 name;
        bytes32 value;
        uint256 executionTime;
        CriticalActionStatus status;
    }

    uint32 public constant MAX_COOLDOWN_PERIOD = 604800; // 1 week

    uint256 public operatorReviewThreshold; //Amount which requires operator to sign
    uint256 public withdrawalDailyThreshold; //Maximum amount an account can withdraw in a day
    uint16 public withdrawalDailyRateLimit; //# of times an account can make a withdrawal request in a day
    bool public accountFreeze; //Only allow if account is not frozen
    uint8 public minBotSignatures;
    uint32 public cooldownPeriod; //Amount of time to wait for critical actions to take effect (treasury or cooldownPeriod change)
    uint256 public criticalActionCount;
    mapping(address => bool) public isSignerBot;
    mapping(bytes32 => bool) public usedNonce; //usedNonce[paramsHash] = bool
    mapping(address => bool) public isAccountFrozen;
    mapping(address => bool) public isTreasury;
    mapping(address => bool) public isOperator;
    mapping(uint256 => CriticalAction) public criticalActions; //criticalActions[id] = CriticalAction

    event SetSignerBots(address indexed sender, address[] signers, bool allowed);
    event FreezeAccount(address indexed sender, address account, bool frozen);
    event AddOperator(address indexed sender, address operator);
    event RemoveOperator(address indexed sender, address operator);
    event AddTreasury(address indexed sender, address treasury);
    event RemoveTreasury(address indexed sender, address treasury);
    event SetCooldownPeriod(address indexed sender, uint32 value);
    event SetOperatorReviewThreshold(address indexed sender, uint256 amount);
    event SetWithdrawalDailyThreshold(address indexed sender, uint256 amount);
    event SetWithdrawalDailyRateLimit(address indexed sender, uint16 amount);
    event RequestCriticalAction(address indexed sender, uint256 id, bytes32 name, bytes32 value);
    event VetoCriticalAction(address indexed sender, uint256 id);
    event ExecuteCriticalAction(address indexed sender, uint256 id);
    event SetMinBotSignatures(address indexed sender, uint8 value);

    constructor(
        address _operator,
        uint256 _operatorReviewThreshold,
        uint256 _withdrawalDailyThreshold,
        uint16 _withdrawalDailyRateLimit,
        bool _accountFreeze,
        uint8 _minBotSignatures,
        uint32 _cooldownPeriod,
        address _treasury
    ) {
        require(_operator != address(0), "zero address"); 
        require(_treasury != address(0), "zero address"); 
        require(_cooldownPeriod <= MAX_COOLDOWN_PERIOD, "Max cooldown period > 1 week!");
        operatorReviewThreshold = _operatorReviewThreshold;
        withdrawalDailyThreshold = _withdrawalDailyThreshold;
        withdrawalDailyRateLimit = _withdrawalDailyRateLimit;
        accountFreeze = _accountFreeze;
        minBotSignatures = _minBotSignatures;
        cooldownPeriod = _cooldownPeriod;
        isTreasury[_treasury] = true;
        isOperator[_operator] = true;
    }

    function getParams() 
        external 
        view 
        returns (
            uint256,
            uint256,
            uint16,
            uint8,
            bool
        ) 
    {
        return (
            operatorReviewThreshold, 
            withdrawalDailyThreshold, 
            withdrawalDailyRateLimit, 
            minBotSignatures,
            accountFreeze
        );
    }

    function freezeAccount(address account, bool frozen) external auth {
        isAccountFrozen[account] = frozen;
        emit FreezeAccount(msg.sender, account, frozen);
    }

    function requestCriticalAction(bytes32 name, bytes32 value) external auth {
        uint256 id = ++criticalActionCount;
        criticalActions[id] = CriticalAction({
            name: name,
            value: value,
            executionTime: block.timestamp + cooldownPeriod,
            status: CriticalActionStatus.Pending
        });
        emit RequestCriticalAction(msg.sender, id, name, value);
    }

    function vetoCriticalAction(uint256 id) external auth {
        CriticalAction storage criticalAction = criticalActions[id];
        require(criticalAction.status == CriticalActionStatus.Pending, "not a pending action");
        criticalAction.status = CriticalActionStatus.Vetoed;
        emit VetoCriticalAction(msg.sender, id);
    }

    function executeCriticalAction(uint256 id) external auth {
        CriticalAction storage criticalAction = criticalActions[id];
        require(criticalAction.status == CriticalActionStatus.Pending, "not a pending action");
        require(block.timestamp >= criticalAction.executionTime, "too early to execute");
        if (criticalAction.name == "addTreasury") {
            address _treasury = address(bytes20(criticalAction.value));
            addTreasury(_treasury);
        } else if (criticalAction.name == "removeTreasury") {
            removeTreasury(address(bytes20(criticalAction.value)));
        } else if (criticalAction.name == "updateCooldownPeriod") {
            cooldownPeriod = uint32(uint256(criticalAction.value));
            require(cooldownPeriod <= MAX_COOLDOWN_PERIOD, "Max cooldown period > 1 week!");
            emit SetCooldownPeriod(msg.sender, cooldownPeriod);
        } else {
            revert("Invalid Action");
        }
        criticalAction.status = CriticalActionStatus.Executed;
        emit ExecuteCriticalAction(msg.sender, id);
    }

    function setOperatorReviewThreshold(uint256 amount) external auth {
        operatorReviewThreshold = amount;
        emit SetOperatorReviewThreshold(msg.sender, amount);
    }

    function setWithdrawalDailyThreshold(uint256 amount) external auth {
        withdrawalDailyThreshold = amount;
        emit SetWithdrawalDailyThreshold(msg.sender, amount);
    }

    function setWithdrawalDailyRateLimit(uint16 amount) external auth {
        withdrawalDailyRateLimit = amount;
        emit SetWithdrawalDailyRateLimit(msg.sender, amount);
    }

    function addOperator(address _operator) external auth {
        isOperator[_operator] = true;
        emit AddOperator(msg.sender, _operator);
    }

    function removeOperator(address _operator) external auth {
        isOperator[_operator] = false;
        emit RemoveOperator(msg.sender, _operator);
    }

    function setMinBotSignatures(uint8 value) external onlyOwner {
        minBotSignatures = value;
        emit SetMinBotSignatures(msg.sender, value);
    }

    function setSignerBots(address[] memory signers, bool allowed) external onlyOwner {
        for (uint8 i = 0; i < signers.length; i++) {
            isSignerBot[signers[i]] = allowed;
        }    
        emit SetSignerBots(msg.sender, signers, allowed);
    }

    function isAdmin(address user) external view returns (bool) {
        return isPermitted[user] == 1;
    }

    function verifyTransferToTreasury(address user, address _treasury) external view {
        require(isOperator[user], "not an operator");
        require(isTreasury[_treasury], "not a treasury");
    }

    function verifyWithdrawERC20(
        address player,
        IAccountWithdrawal.DailyInfo calldata dailyWithdrawal,
        uint256 amount,
        bytes[] calldata signatures, 
        bytes32 paramsHash
    ) external returns (bool isOperatorSigned) {
        if (accountFreeze) {
            require(!isAccountFrozen[player], "Account frozen");
        }
        isOperatorSigned = _verify(signatures, paramsHash);
        if (!isOperatorSigned) {
            require(amount <= operatorReviewThreshold, "Operator review threshold exceeded");
            if (withdrawalDailyThreshold > 0) {
                require(dailyWithdrawal.amount <= withdrawalDailyThreshold, "Withdrawal daily threshold exceeded");
            }
            if (withdrawalDailyRateLimit > 0) {
                require(dailyWithdrawal.numOfTimes <= withdrawalDailyRateLimit, "Withdrawal daily rate limit exceeded");
            }
        }
    }

    function verifyCancelWithdrawal(
        bytes[] calldata signatures, 
        bytes32 paramsHash
    ) external {
        _verify(signatures, paramsHash);
    }

    function verifyUnstakeNFT(
        address player,
        bytes[] calldata signatures, 
        bytes32 paramsHash
    ) external {
        if (accountFreeze) {
            require(!isAccountFrozen[player], "Account frozen");
        }
        _verify(signatures, paramsHash);
    }

    function verifyCancelUnstake(
        bytes[] calldata signatures, 
        bytes32 paramsHash
    ) external {
        _verify(signatures, paramsHash);
    }

    function verifySetMerkleRoot(
        bytes[] calldata signatures, 
        bytes32 paramsHash
    ) external {
        _verify(signatures, paramsHash);
    }

    function verifyShutDown(
        bytes[] calldata signatures, 
        bytes32 paramsHash       
    ) external {
        _verify(signatures, paramsHash);
    }

    function verifyResume(
        bytes[] calldata signatures, 
        bytes32 paramsHash       
    ) external {
        _verify(signatures, paramsHash);
    }

    function _verify(
        bytes[] calldata signatures, 
        bytes32 paramsHash
    ) internal returns (bool isOperatorSigned) {
        require(!usedNonce[paramsHash], "nonce used");
        usedNonce[paramsHash] = true;
        uint256 length = signatures.length;
        uint8 botSignatureCount;
        address lastSigner;
        for (uint256 i = 0; i < length; i++) {
            address signer = ECDSA.recover(paramsHash, signatures[i]);
            require(signer != address(0), "Invalid signer");    
            if (signer > lastSigner) {   
                if (isOperator[signer]) isOperatorSigned = true;
                else {
                    require(isSignerBot[signer], "Not a signer bot");
                    botSignatureCount++;
                }
                lastSigner = signer;
            }
        }    
        require(botSignatureCount >= minBotSignatures, "Insufficient number of bot signatures");
    }

    function addTreasury(address _treasury) internal {
        isTreasury[_treasury] = true;
        emit AddTreasury(msg.sender, _treasury);
    }

    function removeTreasury(address _treasury) internal {
        isTreasury[_treasury] = false;
        emit RemoveTreasury(msg.sender, _treasury);
    }
}