/**
 *Submitted for verification at snowtrace.io on 2022-12-20
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}


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


/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//ERC Token Standard #20 Interface

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BiofiStaking2 is Ownable {
    using SafeMath for uint256;

    address public BioFiTokenAddress;

    event CreateStake(address staker, uint256 stakeAmount, uint256 tierId, uint256 completionDate);
    event CloseStake(address staker, uint256 principal, uint256 interest);
    event TopUpStake(address staker, uint256 topUpAmount);
    event UpgradeStake(address staker, uint256 oldTier, uint256 newTier);

    struct StakeTier {
        bool    isActive;
        string  name;
        uint256 requiredActivities;
        uint256 aprNumerator;
        uint256 aprBonusNumerator;
        uint256 aprDenominator;
        uint256 minStake;
        uint256 maxStake;
        uint256 stakeDuration;
    }

    struct Stake {
        bool    exists;
        uint256 tierId;
        uint256 stakedAmount;
        uint256 startTimestamp;
        uint256 completionTimestamp;
        uint256 totalInterestWithdrawn;
        uint256 closedTimestamp;
    }

    struct Staker {
        bool    exists;
        uint256 id;
    }

    StakeTier [] public tiers;
    //tierId => totalInvestment
    mapping(uint256 => uint256) public totalInvestment;

    mapping(address => Stake) private userStake;

    bool public emergencyWithdrawalActive;

    //stores user's rewards generated by topping up and upgrading a stake
    mapping(address => uint256) public rewardsStorage;

    address [] public stakers;
    mapping(address => Staker) public stakerIds;

    uint256 private guardCounter;

    uint256[] public activityIDs;
    address private proofSigner;

    constructor(address _proofSigner) {
        require(_proofSigner != address(0), "Invalid proof signer");
        guardCounter = 1;
        activityIDs = [0,1,2,3,4,5,6,7,8,9,10];
        proofSigner = _proofSigner;
        emergencyWithdrawalActive = true;
    }

    function getTemplateCount() external view returns (uint256 count) {
        count = tiers.length;
    }

    function getStakerCount() external view returns (uint256 count) {
        count = stakers.length;
    }

    function readStake(address staker) external view returns (Stake memory stake) {
        stake = userStake[staker];
    }

    function calculateInterest(address staker, uint256 activityCount) private view returns (uint256 interestPayable) {
        interestPayable = 0;
        Stake memory stake = userStake[staker];
        StakeTier memory stakeTier = tiers[stake.tierId];
        require(stake.exists, "No staker contract found");
        uint256 periodEnd = block.timestamp > stake.completionTimestamp ?  stake.completionTimestamp : block.timestamp;
        uint256 annualSeconds = 3600 * 24 * 365;
        
        uint256 actualAprNumerator = 0;

        //if user got more than X bonus points, grant a bonus for the withdrawal
        if(activityCount >= stakeTier.requiredActivities) {
            actualAprNumerator = stakeTier.aprBonusNumerator;
        } else {
            actualAprNumerator = stakeTier.aprNumerator;
        }

        uint256 totalInterestEarned =
        (periodEnd - stake.startTimestamp) * stake.stakedAmount *
        (actualAprNumerator - stakeTier.aprDenominator) / stakeTier.aprDenominator / annualSeconds;
        interestPayable = totalInterestEarned - stake.totalInterestWithdrawn;

        return interestPayable;
    }

    function readPrincipalInterest(address staker, uint256 activityCount) external view returns (uint256 principal, uint256 interest, uint256 storedInterest) {
        Stake memory stake = userStake[staker];
        principal = stake.stakedAmount;
        interest = calculateInterest(staker, activityCount);
        storedInterest = rewardsStorage[staker];
    }

    //internal close stake function, doesn't process token transfers
    function _closeStake(address staker, uint256 activityPoints) private returns(uint256,uint256) {
        Stake storage stake = userStake[staker];
        require(stake.exists, "No open stake for this user");
        require(stake.closedTimestamp == 0, "Contract is already closed");
        uint256 interestPayable = calculateInterest(staker, activityPoints);
        stake.closedTimestamp = block.timestamp;
        stake.totalInterestWithdrawn += interestPayable;
        stake.exists = false;

        totalInvestment[stake.tierId] = totalInvestment[stake.tierId] - stake.stakedAmount;
        emit CloseStake(staker, stake.stakedAmount, interestPayable);

        return (stake.stakedAmount,interestPayable);
    }

    //internal create stake function that doesn't require customTimestamp
    function _createStake(address staker, uint256 tierId, uint256 BioFiTokenAmount) private returns(uint256 completionTimestamp) {
        return _createStake(staker, tierId, BioFiTokenAmount, 0);
    }

    //internal create stake function, doesn't process token transfers
    //customTimestamp applies only when topping up a stake. When set to 0, a regular stake is created
    function _createStake(address staker, uint256 tierId, uint256 BioFiTokenAmount, uint256 customTimestamp) private returns(uint256 completionTimestamp) {
        completionTimestamp = 0;
        require(BioFiTokenAddress != address(0), "Staking Token is Not Defined");
        require(tierId < tiers.length, "Illegal tierId");
        StakeTier memory tier = tiers[tierId];
        require(tier.isActive, "Tier is not active");
        Stake memory existingStake = userStake[staker];
        require(!existingStake.exists, "User already has a stake");
        require(BioFiTokenAmount >= tier.minStake, "Cannot stake below min limit");
        require(BioFiTokenAmount <= tier.maxStake, "Cannot stake above max limit");
        //require(tier.totalUtilInvestment >= totalInvestment[tierId] + BioFiTokenAmount, "Investment Would Exceed Limit");
        
        if(customTimestamp > 0) {
            require(customTimestamp > block.timestamp, "Custom timestamp cannot be in the past");
            completionTimestamp = customTimestamp;
        } else {
            uint256 duration = tier.stakeDuration;
            require(duration > 0, "Duration cannot be 0");
            completionTimestamp = block.timestamp + duration;
        }
        
        Stake memory stake = Stake(
            true, tierId, BioFiTokenAmount, block.timestamp,
            completionTimestamp, 0, 0
        );
        userStake[staker] = stake;

        totalInvestment[tierId] = totalInvestment[tierId] + BioFiTokenAmount;
        emit CreateStake(staker, BioFiTokenAmount, tierId, completionTimestamp);

        return completionTimestamp;
    }

    // Creates user's stake
    function createStake(uint256 tierId, uint256 BioFiTokenAmount) external returns (uint256 completionTimestamp) {
        ERC20Interface BioFiToken = ERC20Interface(BioFiTokenAddress);
        uint256 availableTokenBalance =  BioFiToken.balanceOf(msg.sender);
        require(availableTokenBalance >= BioFiTokenAmount, "Insufficient Token Balance");
        require(BioFiToken.transferFrom(msg.sender, address(this), BioFiTokenAmount), "Token transfer failed");

        Staker storage staker = stakerIds[msg.sender];
        if(!staker.exists) {
            stakers.push(msg.sender);
            staker.id = stakers.length-1;
            staker.exists = true;
        }

        completionTimestamp = _createStake(msg.sender,tierId,BioFiTokenAmount);
    }

    // Adds more tokens to an existing stake
    function topUpStake(uint256 BioFiTokenAmount, bytes [] memory activityProofs) external nonReentrant returns (uint256 completionTimestamp) {
        uint256 activityPoints = getActivityPoints(activityProofs);

        Stake memory stake = userStake[msg.sender];
        uint256 newCompletionTimestamp = stake.completionTimestamp;
        
        ERC20Interface BioFiToken = ERC20Interface(BioFiTokenAddress);
        uint256 availableTokenBalance = BioFiToken.balanceOf(msg.sender);
        require(block.timestamp < stake.completionTimestamp, "Cannot add tokens to a completed stake");
        require(availableTokenBalance >= BioFiTokenAmount, "Insufficient Token Balance");
        require(BioFiToken.transferFrom(msg.sender, address(this), BioFiTokenAmount), "Token transfer failed");

        (uint256 stakedAmount, uint256 interestPayable) = _closeStake(msg.sender, activityPoints);
        uint256 toStake = stakedAmount + BioFiTokenAmount;

        completionTimestamp = _createStake(msg.sender, stake.tierId, toStake, newCompletionTimestamp);
        rewardsStorage[msg.sender] += interestPayable;

        emit TopUpStake(msg.sender, BioFiTokenAmount);

        return completionTimestamp;
    }

    // Upgrades user's stake to a higher tier
    // Resets stake's timer
    function upgradeStake(uint256 newTier, bytes [] memory activityProofs) external nonReentrant returns (uint256 completionTimestamp) {
        require(newTier < tiers.length, "Incorrect tierId");

        Stake memory stake = userStake[msg.sender];
        StakeTier memory stakeTier = tiers[newTier];

        uint256 oldTier = stake.tierId;
        
        require(stake.tierId < newTier, "Cannot upgrade to lower tierId");
        require(stake.stakedAmount >= stakeTier.minStake, "Stake amount is less than min limit for this tier");
        require(stake.stakedAmount <= stakeTier.maxStake, "Stake amount is more than min limit for this tier");

        uint256 activityPoints = getActivityPoints(activityProofs);

        (uint256 stakedAmount, uint256 interestPayable) = _closeStake(msg.sender, activityPoints);
        completionTimestamp = _createStake(msg.sender, newTier, stakedAmount);

        rewardsStorage[msg.sender] += interestPayable;

        emit UpgradeStake(msg.sender, oldTier, newTier);

        return completionTimestamp;
    }

    // calculate activity points based on provided task proofs - internal use only
    function getActivityPoints(bytes [] memory activityProofs) private view returns(uint256 activityPoints) {
        activityPoints = 0;
        uint256 [] memory _activityIDs = activityIDs;

        for(uint256 i=0; i<activityProofs.length; i++) {
            for(uint256 j=0; j<_activityIDs.length; j++) {
                string memory taskString = Strings.toString(_activityIDs[j]);
                string memory taskMessage = string(abi.encodePacked(Strings.toHexString(msg.sender), ",", taskString));

                if(verifyMessage(taskMessage,activityProofs[i]) == proofSigner) {
                    _activityIDs[j] = _activityIDs[_activityIDs.length-1];
                    activityPoints++;
                    break;
                }
            }
        }
        return activityPoints;
    }

    // Closes user's stake
    function closeStake(bytes [] memory activityProofs) external nonReentrant {
        uint256 activityPoints = getActivityPoints(activityProofs);

        ERC20Interface BioFiToken = ERC20Interface(BioFiTokenAddress);

        Stake memory stake = userStake[msg.sender];
        require(block.timestamp >= stake.completionTimestamp, "Contract is not over yet");

        (uint256 stakedAmount, uint256 interestPayable) = _closeStake(msg.sender, activityPoints);
        uint256 totalPayable = stakedAmount + interestPayable + rewardsStorage[msg.sender];
        rewardsStorage[msg.sender] = 0;

        if(stakedAmount > 0) {
            BioFiToken.transfer(msg.sender, totalPayable);
        }
    }

    // ============= admin functions =============
    

    function createStakeTier(
        string calldata name,
        uint256 aprNumerator, uint256 aprBonusNumerator, uint256 aprDenominator,
        uint256 requiredActivities, uint256 minStake, uint256 maxStake, uint256 stakeDuration)
    external onlyOwner returns (uint256 index) {
        require(aprDenominator > 0, "aprDenominator is not > 0");
        
        StakeTier memory tier = StakeTier(
            true, name,
            requiredActivities,
            aprNumerator, aprBonusNumerator, aprDenominator,
            minStake, maxStake, stakeDuration
        );

        index = tiers.length;
        totalInvestment[index] = 0;
        tiers.push(tier);
    }

    function setActive(uint256 tierIndex, bool newState) external onlyOwner {
        require(tierIndex < tiers.length, "templateIndex out of range");
        StakeTier storage tier = tiers[tierIndex];
        tier.isActive = newState;
    }

    function setActivityIDs(uint256 [] memory newActivities) external onlyOwner {
        activityIDs = newActivities;
    }

    function setBioFiTokenAddress(address token) external onlyOwner {
        require(BioFiTokenAddress == address(0), "Utility Token Set");
        BioFiTokenAddress = token; //ERC20Interface(token);
    }

    function setProofSigner(address _proofSigner) external onlyOwner {
        require(proofSigner != _proofSigner, "No change");
        proofSigner = _proofSigner;
    }

    function withdrawTokens(address token, address to, uint256 amount) public onlyOwner {
        require(emergencyWithdrawalActive, "Emergency token withdrawals have been disabled");
        require(to != address(0), "Withdrawal address cannot be the burn address");
        require(amount > 0, "Withdrawal amount must be greater than 0");
        ERC20Interface wToken = ERC20Interface(token);
        wToken.transfer(to, amount);
    }

    function disableEmergencyTokenWithdrawals() public onlyOwner {
        require(emergencyWithdrawalActive, "Emergency token withdrawals have been disabled");
        emergencyWithdrawalActive = false;
    }
    

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * Calling a `nonReentrant` function from another `nonReentrant`
    * function is not supported. It is possible to prevent this from happening
    * by making the `nonReentrant` function external, and make it call a
    * `private` function that does the actual work.
    */
    modifier nonReentrant() {
        guardCounter += 1;
        uint256 localCounter = guardCounter;
        _;
        require(localCounter == guardCounter);
    }


    // ============= signature-related functions =============
    
    function verifyMessage(string memory message, bytes memory signature) public pure returns(address signer) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return verifyString(message, v, r, s);
    }

    // Returns the address that signed a given string message
    function verifyString(string memory message, uint8 v, bytes32 r, bytes32 s) private pure returns (address signer) {
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length := mload(message)
            lengthOffset := add(header, 57)
        }
        
        require(length <= 999999);
        uint256 lengthLength = 0;
        uint256 divisor = 100000;

        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;

            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        
        assembly {
            mstore(header, lengthLength)
        }
        
        bytes32 check = keccak256(abi.encodePacked(header,message));
        return ecrecover(check, v, r, s);
    }
    
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

}