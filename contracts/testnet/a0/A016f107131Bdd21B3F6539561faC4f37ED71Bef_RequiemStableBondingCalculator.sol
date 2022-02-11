/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-10
*/

// File: contracts/libraries/math/FullMath.sol



pragma solidity >=0.8.11;

// solhint-disable no-inline-assembly, reason-string, max-line-length

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
            // EDIT for 0.8 compatibility:
            // see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
            uint256 twos = denominator & (~denominator + 1);

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
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}
// File: contracts/libraries/math/FixedPoint.sol


pragma solidity 0.8.11;


library FixedPoint {
  struct uq112x112 {
    uint224 _x;
  }

  struct uq144x112 {
    uint256 _x;
  }

  uint8 private constant RESOLUTION = 112;
  uint256 private constant Q112 = 0x10000000000000000000000000000;
  uint256 private constant Q224 =
    0x100000000000000000000000000000000000000000000000000000000;
  uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  function decode112with18(uq112x112 memory self)
    internal
    pure
    returns (uint256)
  {
    return uint256(self._x) / 5192296858534827;
  }

  function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(denominator > 0, "FixedPoint::fraction: division by zero");
    if (numerator == 0) return FixedPoint.uq112x112(0);

    if (numerator <= type(uint144).max) {
      uint256 result = (numerator << RESOLUTION) / denominator;
      require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    } else {
      uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
      require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    }
  }
}

// File: contracts/interfaces/IRequiemSwap.sol



pragma solidity ^0.8.11;

interface IRequiemSwap {
  function calculateSwapGivenIn(
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) external view returns (uint256);

  function calculateSwapGivenOut(
    address tokenIn,
    address tokenOut,
    uint256 amountOut
  ) external view returns (uint256);
}

// File: contracts/interfaces/ERC20/IERC20.sol


pragma solidity 0.8.11;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/interfaces/IRequiemStableSwap.sol



pragma solidity 0.8.11;


// solhint-disable var-name-mixedcase

interface IRequiemStableSwap {

  // pool data view functions
  function getLpToken() external view returns (IERC20 lpToken);

  function getA() external view returns (uint256);

  function getAPrecise() external view returns (uint256);

  function getToken(uint8 index) external view returns (IERC20);

  function getTokens() external view returns (IERC20[] memory);

  function getTokenIndex(address tokenAddress) external view returns (uint8);

  function getTokenBalance(uint8 index) external view returns (uint256);

  function getTokenBalances() external view returns (uint256[] memory);

  function getNumberOfTokens() external view returns (uint256);

  function getVirtualPrice() external view returns (uint256);

  function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
    external
    view
    returns (uint256);

  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256);

  function calculateRemoveLiquidity(address account, uint256 amount)
    external
    view
    returns (uint256[] memory);

  function calculateRemoveLiquidityOneToken(
    address account,
    uint256 tokenAmount,
    uint8 tokenIndex
  ) external view returns (uint256 availableTokenAmount);

  function getAdminBalances()
    external
    view
    returns (uint256[] memory adminBalances);

  function getAdminBalance(uint8 index) external view returns (uint256);

  function calculateCurrentWithdrawFee(address account)
    external
    view
    returns (uint256);

  // state modifying functions
  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    address to,
    uint256 deadline
  ) external returns (uint256);

  function addLiquidity(
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidity(
    uint256 amount,
    uint256[] calldata minAmounts,
    uint256 deadline
  ) external returns (uint256[] memory);

  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidityImbalance(
    uint256[] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external returns (uint256);

  function updateUserWithdrawFee(address recipient, uint256 transferAmount)
    external;
}

// File: contracts/interfaces/IStableLPToken.sol



pragma solidity ^0.8.11;


interface IStableLPToken {
  function swap() external view returns (IRequiemStableSwap);

  function totalSupply() external view returns (uint256);
}

// File: contracts/interfaces/IBondingCalculator.sol


pragma solidity 0.8.11;

interface IBondingCalculator {
  function valuation(address pair_, uint256 amount_)
    external
    view
    returns (uint256 _value);
}

// File: contracts/RequiemStableBondingCalculator.sol



pragma solidity 0.8.11;







/**
 * Bonding calculator for stable pool
 */
contract RequiemStableBondingCalculator is IBondingCalculator {
  using FixedPoint for *;

  address public immutable QUOTE;

  constructor(address _QUOTE) {
    require(_QUOTE != address(0));
    QUOTE = _QUOTE;
  }

  // calculates the liquidity value denominated in the provided token
  // uses the 0.01% inputAmount for that calculation
  // note that we never use the actual LP as input as the swap contains the LP address
  // and is also used to extract the balances
  function getTotalValue(address _lpAddress) public view returns (uint256 _value) {
    IRequiemStableSwap swap = IStableLPToken(_lpAddress).swap();
    uint256[] memory reserves = swap.getTokenBalances();
    uint8 quoteIndex = swap.getTokenIndex(QUOTE);
    for (uint8 i = 0; i < reserves.length; i++) {
      if (i != quoteIndex) {
        _value +=
          swap.calculateSwap(
            i,
            quoteIndex,
            reserves[i] / 10000
          ) *
          10000;
      }
    }
  }

  function valuation(address _lpAddress, uint256 amount_)
    external
    view
    override
    returns (uint256 _value)
  {
    uint256 totalValue = getTotalValue(_lpAddress);
    uint256 totalSupply = IStableLPToken(_lpAddress).totalSupply();

    _value =
      (totalValue *
        FixedPoint.fraction(amount_, totalSupply).decode112with18()) /
      1e18;
  }

  function markdown(address _lpAddress) external view returns (uint256) {
    return getTotalValue(_lpAddress);
  }
}