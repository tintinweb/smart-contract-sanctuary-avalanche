// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMain {
    function ownerOf(uint256 id) external view returns (address);
    function forcedTransfer(address from, address to, uint256 tokenId) external;
}

contract Harberger is Ownable {
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                                IMMUTABLES  
    //////////////////////////////////////////////////////////////*/

    IMain public immutable main;
    uint256 public immutable HARBERGER_CUTOFF = 3512479453921;
    uint256 public immutable MAX_BPS = 10000;

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice yearly tax in bps
    /// @dev initialized in constructor, can be changed by the contract owner
    uint256 public yearlyTaxBps;

    /// @notice minimum required remaining time after buy, mint or tax payment
    /// @dev initialized in constructor, can be changed by the contract owner
    uint256 public minimumPeriod;

    /// @notice token id to its harberger price determined by the token owner
    mapping(uint256 => uint256) public prices;

    /// @notice token id to its expiration date
    /// @dev token buy price starts decreasing after expiration date is less than 30 days
    mapping(uint256 => uint256) public expirationDates;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when a new harberger price is set for a token
    /// @param id token id
    /// @param price new harberger price of the token
    /// @param newExpirationDate expiration date of the token after setting new harberger price
    event SetPrice(uint256 id, uint256 price, uint256 newExpirationDate);

    /// @notice emitted when tax is paid for a token
    /// @param id token id
    /// @param newExpirationDate expiration date of the token after paying tax
    event PayTax(uint256 id, uint256 newExpirationDate);

    /// @notice emitted when a token is bought
    /// @param id token id
    /// @param newPrice new harberger price of the token set by the buyer
    /// @param newExpirationDate expiration date of the token after buy
    event Buy(uint256 id, uint256 newPrice, uint256 newExpirationDate);

    /// @notice emitted when a new yearly tax is set
    /// @param yearlyTaxBps new yearly tax in bps
    event SetYearlyTaxBps(uint256 yearlyTaxBps);

    /// @notice emitted when a new minimum period is set
    /// @param minimumPeriod new minimum required remaining time after buy, mint or tax payment
    event SetMinimumPeriod(uint256 minimumPeriod);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice sets initial values
    /// @param _yearlyTaxBps yearly tax in bps
    /// @param _minimumPeriod minimum required remaining time after buy, mint or tax payment
    constructor(address _mainAddress, uint256 _yearlyTaxBps, uint256 _minimumPeriod) Ownable() {
        yearlyTaxBps = _yearlyTaxBps;
        minimumPeriod = _minimumPeriod;
        main = IMain(_mainAddress);
    }

    /*//////////////////////////////////////////////////////////////
                             HARBERGER LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice sets a new harberger price for a token and updates its expiration date
    /// @dev reverts if not called by token owner
    /// @dev reverts if expiration date is less than minimumPeriod after setting new harberger price
    /// @param id id of the token
    /// @param newPrice new harberger price of the token
    function setPrice(uint256 id, uint256 newPrice) external {
        require(isHarberger(id), "Wrong type");
        require(ownerOf(id) == msg.sender, "Not owner");
        uint256 newExpirationDate = expirationDateAfterSetPrice(id, newPrice);
        require(newExpirationDate > block.timestamp + minimumPeriod, "Expiration date too soon");

        expirationDates[id] = newExpirationDate;
        prices[id] = newPrice;
        emit SetPrice(id, newPrice, newExpirationDate);
    }

    /// @notice pays the tax for a token and updates its expiration date
    /// @dev reverts if expiration date is less than minimumPeriod after paying tax
    /// @param id id of the token
    function payTax(uint256 id) external payable {
        require(isHarberger(id), "Wrong type");
        uint256 newExpirationDate = expirationDateAfterPayTax(id, msg.value);
        require(newExpirationDate > block.timestamp + minimumPeriod, "Insufficient payment");

        expirationDates[id] = newExpirationDate;
        emit PayTax(id, newExpirationDate);
    }

    /// @notice convenience function for setting harberger price and paying tax in one transaction
    /// @dev reverts if not called by token owner
    /// @dev reverts if time to new expiration date is less than minimumPeriod
    /// @param id id of the token
    /// @param newPrice new harberger price of the token
    function setPriceAndPayTax(uint256 id, uint256 newPrice) external payable {
        require(isHarberger(id), "Wrong token type");
        require(ownerOf(id) == msg.sender, "Not owner");
        uint256 newExpirationDate = expirationDateAfterSetPriceAndPayTax(id, newPrice, msg.value);
        require(newExpirationDate > block.timestamp + minimumPeriod, "Insufficient payment");

        expirationDates[id] = newExpirationDate;
        prices[id] = newPrice;
        emit SetPrice(id, newPrice, newExpirationDate);
    }

    /// @notice buys a token by paying its buy price and sets its new harberger price and expiration date
    /// @dev reverts if expiration date is less than minimumPeriod after buy
    /// @param id id of the token to buy
    /// @param newPrice new harberger price of the token
    function buy(uint256 id, uint256 newPrice) external payable {
        require(isHarberger(id), "Wrong token type");
        uint256 buyPrice = calculateBuyPrice(id);
        uint256 newExpirationDate = expirationDateAfterBuy(id, buyPrice, newPrice, msg.value);
        require(newExpirationDate >= block.timestamp + minimumPeriod, "Insufficient payment");

        address payable oldOwner = payable(ownerOf(id));

        expirationDates[id] = newExpirationDate;
        prices[id] = newPrice;

        main.forcedTransfer(oldOwner, msg.sender, id);
        (bool success,) = oldOwner.call{value: buyPrice}("");
        (success);
        emit Buy(id, newPrice, newExpirationDate);
    }

    function mintHook(uint256 id, uint256 newPrice, uint256 expirationDate) external {
        require(msg.sender == address(main), "Not main");
        prices[id] = newPrice;
        expirationDates[id] = expirationDate;
    }

    /*//////////////////////////////////////////////////////////////
                             OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice sets a new yearly tax bps
    /// @dev reverts if not called by contract owner
    /// @param _yearlyTaxBps new yearly tax bps
    function setYearlyTaxBps(uint256 _yearlyTaxBps) external onlyOwner {
        yearlyTaxBps = _yearlyTaxBps;
        emit SetYearlyTaxBps(_yearlyTaxBps);
    }

    /// @notice sets a new minimum period
    /// @dev reverts if not called by contract owner
    /// @param _minimumPeriod new minimum period
    function setMinimumPeriod(uint256 _minimumPeriod) external onlyOwner {
        minimumPeriod = _minimumPeriod;
        emit SetMinimumPeriod(_minimumPeriod);
    }

    /*//////////////////////////////////////////////////////////////
                          PUBLIC VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice calculates expiration date after setPrice with given new harberger price for given id
    /// @param id id of the token
    /// @param newPrice new harberger price of the token
    /// @return expirationDate expiration date after setPrice
    function expirationDateAfterSetPrice(uint256 id, uint256 newPrice) public view returns (uint256 expirationDate) {
        uint256 durationLeft = expirationDates[id] - block.timestamp;
        uint256 oldPrice = prices[id];
        expirationDate = block.timestamp + oldPrice.mulDiv(durationLeft, newPrice);
    }

    /// @notice calculates expiration date after payTax with given payment for given id
    /// @param id id of the token
    /// @param payment price paid for tax
    /// @return expirationDate expiration date after payTax
    function expirationDateAfterPayTax(uint256 id, uint256 payment) public view returns (uint256 expirationDate) {
        uint256 yearlyTax = prices[id].mulDiv(yearlyTaxBps, MAX_BPS);
        expirationDate = expirationDates[id] + (payment.mulDiv(365 days, yearlyTax));
    }

    /// @notice calculates expiration date after setPriceAndPayTax with given new harberger price and payment for given id
    /// @param id id of the token
    /// @param newPrice new harberger price of the token
    /// @param payment price paid for tax
    /// @return expirationDate expiration date after setPriceAndPayTax
    function expirationDateAfterSetPriceAndPayTax(uint256 id, uint256 newPrice, uint256 payment)
        public
        view
        returns (uint256 expirationDate)
    {
        uint256 durationLeft = expirationDates[id] - block.timestamp;
        uint256 durationLeftAfterNewPrice = durationLeft.mulDiv(prices[id], newPrice);
        uint256 yearlyTax = newPrice.mulDiv(yearlyTaxBps, MAX_BPS);
        expirationDate = block.timestamp + durationLeftAfterNewPrice + payment.mulDiv(365 days, yearlyTax);
    }

    /// @notice calculates expiration date after buy with given buy price, new harberger price and payment for given id
    /// @param id id of the token
    /// @param buyPrice buy price of the token
    /// @param newPrice new harberger price of the token
    /// @param payment price paid for buy
    function expirationDateAfterBuy(uint256 id, uint256 buyPrice, uint256 newPrice, uint256 payment)
        public
        view
        returns (uint256 expirationDate)
    {
        uint256 extensionPayment = payment - buyPrice;
        uint256 durationLeft;
        if (block.timestamp < expirationDates[id]) {
            durationLeft = expirationDates[id] - block.timestamp;
        }
        uint256 durationLeftAfterNewPrice = durationLeft.mulDiv(prices[id], newPrice);
        uint256 yearlyTax = newPrice.mulDiv(yearlyTaxBps, MAX_BPS);
        expirationDate = block.timestamp + durationLeftAfterNewPrice + extensionPayment.mulDiv(365 days, yearlyTax);
    }

    /// @notice calculates buy price for token
    /// @dev equals harberger price if expirationDate is more than 30 days away gradually decreases after that
    /// @param id id of the token
    /// @return buyPrice buy price of the token
    function calculateBuyPrice(uint256 id) public view returns (uint256 buyPrice) {
        if (expired(id)) {
            return 0;
        }

        uint256 durationLeft = expirationDates[id] - block.timestamp;
        uint256 fullPrice = prices[id];
        if (durationLeft > 30 days) {
            buyPrice = fullPrice;
        } else {
            buyPrice = fullPrice.mulDiv(durationLeft, 30 days);
        }
    }

    function expired(uint256 id) public view returns (bool) {
        require(isHarberger(id), "Wrong token type");
        return block.timestamp > expirationDates[id];
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice convenience function for calculating minimum payment for a non reverting buy
    /// @dev equals to harberger price if expiration date of token is farther than 3 months
    /// else equals to buying and setting expiration date to 3 months from now
    /// @param id id of the token
    /// @param newPrice new harberger price of the token
    /// @return minimumBuyPrice minimum payment for non reverting buy
    function calculateMinimumBuyPrice(uint256 id, uint256 newPrice) external view returns (uint256 minimumBuyPrice) {
        require(isHarberger(id), "Wrong token type");
        uint256 durationLeft = expired(id) ? 0 : expirationDates[id] - block.timestamp;
        uint256 durationLeftAfterNewPrice = durationLeft.mulDiv(prices[id], newPrice);
        uint256 buyPrice = calculateBuyPrice(id);

        if (durationLeftAfterNewPrice > minimumPeriod) {
            minimumBuyPrice = buyPrice;
        } else {
            uint256 requiredExtension = minimumPeriod - durationLeftAfterNewPrice;
            uint256 yearlyTax = newPrice.mulDiv(yearlyTaxBps, MAX_BPS);
            minimumBuyPrice = buyPrice + requiredExtension.mulDiv(yearlyTax, 365 days);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function isHarberger(uint256 id) internal pure returns (bool) {
        return id < HARBERGER_CUTOFF;
    }

    function ownerOf(uint256 id) internal view returns (address) {
        return main.ownerOf(id);
    }
}