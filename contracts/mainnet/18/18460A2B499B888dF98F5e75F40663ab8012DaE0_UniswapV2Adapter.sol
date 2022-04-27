/**
 *Submitted for verification at snowtrace.io on 2022-04-27
*/

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title IAmmAdapter interface.
/// @notice Implementations of this interface have all the details needed to interact with a particular AMM.
/// This pattern allows Futureswap to be extended to use several AMMs like UniswapV2 (and forks like Trader Joe),
/// UniswapV3, Trident, etc while keeping the details to connect to them outside of our core system.
interface IAmmAdapter {
    /// @notice Swaps `token1Amount` of `token1` for `token0`. If `token1Amount` is positive, then the `recipient`
    /// will receive `token1`, and if negative, they receive `token0`.
    /// @param recipient The recipient to send tokens to.
    /// @param token0 Must be one of the tokens the adapter supports.
    /// @param token1 Must be one of the tokens the adapter supports.
    /// @param token1Amount Amount of `token1` to swap. This method will revert if token1Amount is zero.
    /// @return token0Amount The amount of `token0` paid (negative) or received (positive).
    function swap(
        address recipient,
        address token0,
        address token1,
        int256 token1Amount
    ) external returns (int256 token0Amount);

    /// @notice Returns the price of the specified token0 relatively to token1.
    /// @param token0 The token to return price for.
    /// @param token1 The token to return price relatively to.
    function getPrice(address token0, address token1) external view returns (int256 price);

    /// @notice Returns the tokens that this AMM adapter and underlying pool support. Order of the tokens should be the
    /// the same as the order defined by the AMM pool.
    function supportedTokens() external view returns (address[] memory tokens);
}


// File contracts/amm_adapter/IAmmAdapterCallback.sol




interface IAmmAdapterCallback {
    /// @notice Adapter callback for collecting payment. Only one of the two tokens, stable or asset, can be positive,
    /// which indicates a payment due. Negative indicates we'll receive that token as a result of the swap.
    /// Implementations of this method should protect against malicious calls, and ensure that payments are triggered
    /// only by authorized contracts or as part of a valid trade flow.
    /// @param recipient The address to send payment to.
    /// @param token0 Token corresponding to amount0Owed.
    /// @param token1 Token corresponding to amount1Owed.
    /// @param amount0Owed Token amount in underlying decimals we owe for token0.
    /// @param amount1Owed Token amount in underlying decimals we owe for token1.
    function sendPayment(
        address recipient,
        address token0,
        address token1,
        int256 amount0Owed,
        int256 amount1Owed
    ) external;
}


// File contracts/external/uniswap/IUniswapV2Pair.sol




interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function mint(address to) external returns (uint256 liquidity);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}


// File @openzeppelin/contracts/utils/math/[email protected]



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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


// File contracts/external/uniswap/UniswapV2Library.sol


/// @notice This is reproduced from UniswapV2 periphery code for calculations related to swapping with a pool.
/// Original code can be found at https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
library UniswapV2Library {
    /// @notice Use SafeMath to maintain the same code as original. We technically don't need safemath anymore as newer
    /// versions of Solidity already have overflow protection.
    using SafeMath for uint256;

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }
}


// File contracts/lib/FsMath.sol




/// @title Utility methods basic math operations.
///      NOTE In order for the fuzzing tests to be isolated, all functions in this library need to
///      be `internal`.  Otherwise a contract that uses this library has a dependency on the
///      library.
///
///      Our current Echidna setup requires contracts to be deployable in isolation, so make sure to
///      keep the functions `internal`, until we update our Echidna tests to support more complex
///      setups.
library FsMath {
    uint256 constant BITS_108 = (1 << 108) - 1;
    int256 constant BITS_108_MIN = -(1 << 107);
    uint256 constant BITS_108_MASKED = ~BITS_108;
    uint256 constant BITS_108_SIGN = 1 << 107;
    int256 constant FIXED_POINT_BASED = 1 ether;

    function abs(int256 value) internal pure returns (uint256) {
        if (value >= 0) {
            // slither-disable-next-line safe-cast
            return uint256(value);
        }
        // slither-disable-next-line safe-cast
        return uint256(-value);
    }

    function sabs(int256 value) internal pure returns (int256) {
        if (value >= 0) {
            return value;
        }
        return -value;
    }

    function sign(int256 value) internal pure returns (int256) {
        if (value < 0) {
            return -1;
        } else if (value > 0) {
            return 1;
        } else {
            return 0;
        }
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    // Clip val into interval [lower, upper]
    function clip(
        int256 val,
        int256 lower,
        int256 upper
    ) internal pure returns (int256) {
        return min(max(val, lower), upper);
    }

    function safeCastToSigned(uint256 x) internal pure returns (int256) {
        // slither-disable-next-line safe-cast
        int256 ret = int256(x);
        require(ret >= 0, "Cast overflow");
        return ret;
    }

    function safeCastToUnsigned(int256 x) internal pure returns (uint256) {
        require(x >= 0, "Cast underflow");
        // slither-disable-next-line safe-cast
        return uint256(x);
    }

    /// @notice Encode a int256 into a string hex value prepended with a magic identifier "stable0x"
    function encodeValue(int256 value) external pure returns (string memory) {
        return encodeValueStatic(value);
    }

    /// @notice Encode a int256 into a string hex value prepended with a magic identifier "stable0x"
    ///
    /// @dev This is a "static" version of `encodeValue`.  A contract using this method will not
    ///      have a dependency on the library.
    function encodeValueStatic(int256 value) internal pure returns (string memory) {
        // We are going to encode the two's complement representation.  To be consumed
        // by`decodeValue()`.
        // slither-disable-next-line safe-cast
        bytes32 y = bytes32(uint256(value));
        bytes memory bytesArray = new bytes(8 + 64);
        bytesArray[0] = "s";
        bytesArray[1] = "t";
        bytesArray[2] = "a";
        bytesArray[3] = "b";
        bytesArray[4] = "l";
        bytesArray[5] = "e";
        bytesArray[6] = "0";
        bytesArray[7] = "x";
        for (uint256 i = 0; i < 32; i++) {
            // slither-disable-next-line safe-cast
            uint8 x = uint8(y[i]);
            uint8 u = x >> 4;
            uint8 l = x & 0xF;
            bytesArray[8 + 2 * i] = u >= 10 ? bytes1(u + 65 - 10) : bytes1(u + 48);
            bytesArray[8 + 2 * i + 1] = l >= 10 ? bytes1(l + 65 - 10) : bytes1(l + 48);
        }
        // Bytes we generated above are valid UTF-8.
        // slither-disable-next-line safe-cast
        return string(bytesArray);
    }

    /// @notice Decode an encoded int256 value above.
    /// @return 0 if string is not of the right format.
    function decodeValue(bytes memory r) external pure returns (int256) {
        return decodeValueStatic(r);
    }

    /// @notice Decode an encoded int256 value above.
    /// @dev This is a "static" version of `encodeValue`.  A contract using this method will not
    ///      have a dependency on the library.
    /// @return 0 if string is not of the right format.
    function decodeValueStatic(bytes memory r) internal pure returns (int256) {
        if (
            r.length == 8 + 64 &&
            r[0] == "s" &&
            r[1] == "t" &&
            r[2] == "a" &&
            r[3] == "b" &&
            r[4] == "l" &&
            r[5] == "e" &&
            r[6] == "0" &&
            r[7] == "x"
        ) {
            uint256 y;
            for (uint256 i = 0; i < 64; i++) {
                // slither-disable-next-line safe-cast
                uint8 h = uint8(r[8 + i]);
                uint256 x;
                if (h >= 65) {
                    if (h >= 65 + 16) return 0;
                    x = (h + 10) - 65;
                } else {
                    if (!(h >= 48 && h < 48 + 10)) return 0;
                    x = h - 48;
                }
                y |= x << (256 - 4 - 4 * i);
            }
            // We were decoding a two's complement representation.  Produced by `encodeValue()`.
            // slither-disable-next-line safe-cast
            return int256(y);
        } else {
            return 0;
        }
    }

    /// @notice Returns the lower 108 bits of data as a positive int256
    function read108(uint256 data) internal pure returns (int256) {
        // slither-disable-next-line safe-cast
        return int256(data & BITS_108);
    }

    /// @notice Returns the lower 108 bits sign extended as a int256
    function readSigned108(uint256 data) internal pure returns (int256) {
        uint256 temp = data & BITS_108;

        if (temp & BITS_108_SIGN > 0) {
            temp = temp | BITS_108_MASKED;
        }
        // slither-disable-next-line safe-cast
        return int256(temp);
    }

    /// @notice Performs a range check and returns the lower 108 bits of the value
    function pack108(int256 value) internal pure returns (uint256) {
        if (value >= 0) {
            // slither-disable-next-line safe-cast
            require(value <= int256(BITS_108), "RE");
        } else {
            require(value >= BITS_108_MIN, "RE");
        }

        // Ranges were checked above.  And we expect negative values to be encoded in a two's
        // complement form, as this is how we decode them in `readSigned108()`.
        // slither-disable-next-line safe-cast
        return uint256(value) & BITS_108;
    }

    /// @notice Calculate the leverage amount given amounts of stable/asset and the asset price.
    function calculateLeverage(
        int256 assetAmount,
        int256 stableAmount,
        int256 assetPrice
    ) internal pure returns (uint256) {
        // Return early for gas saving.
        if (assetAmount == 0) {
            return 0;
        }
        int256 assetInStable = assetToStable(assetAmount, assetPrice);
        int256 collateral = assetInStable + stableAmount;
        // Avoid division by 0.
        require(collateral > 0, "Insufficient collateral");
        // slither-disable-next-line safe-cast
        return FsMath.abs(assetInStable * FIXED_POINT_BASED) / uint256(collateral);
    }

    /// @notice Returns the worth of the given asset amount in stable token.
    function assetToStable(int256 assetAmount, int256 assetPrice) internal pure returns (int256) {
        return (assetAmount * assetPrice) / FIXED_POINT_BASED;
    }

    /// @notice Returns the worth of the given stable amount in asset token.
    function stableToAsset(int256 stableAmount, int256 assetPrice) internal pure returns (int256) {
        return (stableAmount * FIXED_POINT_BASED) / assetPrice;
    }
}



// File contracts/lib/Utils.sol




// BEGIN STRIP
// Used in `FsUtils.Log` which is a debugging tool.

// END STRIP

library FsUtils {
    function nonNull(address _address) internal pure returns (address) {
        require(_address != address(0), "Zero address");
        return _address;
    }

    // Slither sees this function is not used, but it is convenient to have it around, as it
    // actually provides better error messages than `nonNull` above.
    // slither-disable-next-line dead-code
    function nonNull(address _address, string memory message) internal pure returns (address) {
        require(_address != address(0), message);
        return _address;
    }
}

contract ImmutableOwnable {
    address public immutable owner;

    constructor(address _owner) {
        // slither-disable-next-line missing-zero-check
        owner = FsUtils.nonNull(_owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
}

// Contracts deriving from this contract will have a public pure function
// that returns a gitCommitHash at the moment it was compiled.
contract GitCommitHash {
    // A purely random string that's being replaced in a prod build by
    // the git hash at build time.
    uint256 public immutable gitCommitHash =
        0xDEADBEEFCAFEBABEBEACBABEBA5EBA11B0A710ADB00BBABEDEFACA7EDEADFA11;
}


// File contracts/amm_adapter/UniswapV2Adapter.sol









/// @title The AMM adapter for UniswapV2 pools. This can also be used for UniswapV2 forks.
/// @dev This adapter is not meant to be used for general purposes. This remains public and has no access control in
/// case it might be shared by multiple components (e.g. multiple AMMs) in the system. It also does not have connection
/// to any contract in the Futureswap system.
contract UniswapV2Adapter is IAmmAdapter {
    /// @notice The UniswapV2 pool this adapter is for. We make this immutable to avoid needing a setter and an owner
    /// for this contract. If the underlying Uniswap pool needs to change, then we will do a new deployment of this
    /// contract and update the IAmm contract that's using it.
    IUniswapV2Pair public immutable uniswapV2Pool;

    /// @notice The underlying AMM's token0.
    address public immutable poolToken0;
    /// @notice The underlying AMM's token1.
    address public immutable poolToken1;

    constructor(address _uniswapV2Pool) {
        // We need to use a temp variable as functions cannot be invoked on immutable variable in the constructor.
        // slither-disable-next-line missing-zero-check
        IUniswapV2Pair tempUniswapV2Pool = IUniswapV2Pair(FsUtils.nonNull(_uniswapV2Pool));
        poolToken0 = tempUniswapV2Pool.token0();
        poolToken1 = tempUniswapV2Pool.token1();
        uniswapV2Pool = tempUniswapV2Pool;
    }

    /// @inheritdoc IAmmAdapter
    function swap(
        address recipient,
        address tokenA,
        address tokenB,
        int256 tokenBAmount
    ) external override returns (int256 tokenAAmount) {
        require(tokenBAmount != 0, "Token1 is zero");
        require(
            (tokenA == poolToken0 && tokenB == poolToken1) ||
                (tokenA == poolToken1 && tokenB == poolToken0),
            "Wrong tokens"
        );

        (uint256 reserve0, uint256 reserve1, ) = uniswapV2Pool.getReserves();
        int256 token0Amount;
        int256 token1Amount;
        // We need to map (tokenA, tokenB) and corresponding amounts to pool's (token0, token1) to avoid having to deal
        // with 4 different cases. UniswapV2 API is different from v3 and is not flexible with direction, i.e. it only
        // allows swaps from its token0 => token1.
        if (tokenA == poolToken0) {
            token1Amount = tokenBAmount;
            token0Amount = getAmountInOrOut(token1Amount, reserve0, reserve1);
            tokenAAmount = token0Amount;
        } else {
            token0Amount = tokenBAmount;
            token1Amount = getAmountInOrOut(token0Amount, reserve1, reserve0);
            tokenAAmount = token1Amount;
        }

        doSwapByPoolOrder(recipient, token0Amount, token1Amount);
    }

    /// @notice Swap using UniswapV2 pool's token0 and token1. Exactly one of the two amounts must be positive (output)
    /// and the other must be negative (input).
    function doSwapByPoolOrder(
        address recipient,
        int256 token0Amount,
        int256 token1Amount
    ) private {
        require(
            (token0Amount > 0 && token1Amount < 0) || (token1Amount > 0 && token0Amount < 0),
            "Incorrect amounts"
        );

        address token0 = uniswapV2Pool.token0();
        address token1 = uniswapV2Pool.token1();

        // Send payments upfront. UniswapV2#swap has a callback to pay later but it can't be used as it doesn't pass the
        // amount of tokens required for payment.
        int256 token0Owed = -token0Amount;
        int256 token1Owed = -token1Amount;
        IAmmAdapterCallback(msg.sender).sendPayment(
            address(uniswapV2Pool),
            token0,
            token1,
            token0Owed,
            token1Owed
        );

        // UniswapV2 swap requires passing the desired amount of pool's token0 or token1 and 0 for the other.
        if (token1Amount > 0) {
            uint256 amountOut = FsMath.safeCastToUnsigned(token1Amount);
            uniswapV2Pool.swap(0, amountOut, recipient, "");
        } else {
            uint256 amountOut = FsMath.safeCastToUnsigned(token0Amount);
            uniswapV2Pool.swap(amountOut, 0, recipient, "");
        }
    }

    /// @notice Returns the amount of token0 as required input or output given an amount of token1
    /// (positive is output, negative is input).
    function getAmountInOrOut(
        int256 amount1,
        uint256 reserve0,
        uint256 reserve1
    ) private pure returns (int256) {
        int256 amount0;
        if (amount1 > 0) {
            // token0 is input, token1 is output.
            uint256 amountOut = FsMath.safeCastToUnsigned(amount1);
            (uint256 reserveIn, uint256 reserveOut) = (reserve0, reserve1);
            uint256 amount0In = UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
            // Since token0 is input, amount1 required should be negative.
            amount0 = -FsMath.safeCastToSigned(amount0In);
        } else {
            // token1 is input, token0 is output.
            uint256 amountIn = FsMath.safeCastToUnsigned(-amount1);
            (uint256 reserveIn, uint256 reserveOut) = (reserve1, reserve0);
            uint256 amount0Out = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
            amount0 = FsMath.safeCastToSigned(amount0Out);
        }
        return amount0;
    }

    /// @dev Returns the marginal spot price from UniswapV2. This should never be used in the system as an oracle price
    /// as it can be manipulated by flashloans and should only be used for display purposes.
    /// @inheritdoc IAmmAdapter
    function getPrice(address token0, address token1) external view override returns (int256) {
        require(
            (token0 == poolToken0 && token1 == poolToken1) ||
                (token0 == poolToken1 && token1 == poolToken0),
            "Wrong tokens"
        );

        (uint256 reserve0_, uint256 reserve1_, ) = uniswapV2Pool.getReserves();
        // Cast to int256 for calculation consistency - we use int256 everywhere.
        int256 reserve0 = FsMath.safeCastToSigned(reserve0_);
        int256 reserve1 = FsMath.safeCastToSigned(reserve1_);
        if (token0 == poolToken0) {
            return (reserve1 * FsMath.FIXED_POINT_BASED) / reserve0;
        } else {
            return (reserve0 * FsMath.FIXED_POINT_BASED) / reserve1;
        }
    }

    /// @inheritdoc IAmmAdapter
    function supportedTokens() external view override returns (address[] memory tokens) {
        tokens = new address[](2);
        tokens[0] = poolToken0;
        tokens[1] = poolToken1;
    }
}