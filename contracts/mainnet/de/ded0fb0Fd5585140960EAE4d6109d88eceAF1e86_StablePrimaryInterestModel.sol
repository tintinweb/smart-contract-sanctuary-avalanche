// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../library/SafeRatioMath.sol";

/**
 * @title dForce's lending InterestRateModelV2 Contract
 * @author dForce
 */
contract InterestRateModelV2 {
    using SafeMathUpgradeable for uint256;
    using SafeRatioMath for uint256;

    uint256 private constant ONE = 1e18;

    /**
     * @notice The approximate number of blocks produced each year for different blockchain.
     */
    uint256 public blocksPerYear;

    uint256 public base;
    uint256 public optimal;
    uint256 public slope_1;
    uint256 public slope_2;

    constructor(
        uint256 _base,
        uint256 _optimal,
        uint256 _slope_1,
        uint256 _slope_2,
        uint256 _blocksPerYear
    ) public {
        require(_base <= ONE, "interestRateModelV2: Base can not exceed 1!");
        require(_optimal > 0, "interestRateModelV2: Optimal can not be zero!");
        require(_optimal < ONE, "interestRateModelV2: Optimal should be less than 1!");
        require(_slope_1 <= ONE, "interestRateModelV2: Slope 1 can not exceed 1!");
        require(_blocksPerYear > 0, "interestRateModelV2: Blocks per year can not be zero!");
        base = _base;
        optimal = _optimal;
        slope_1 = _slope_1;
        slope_2 = _slope_2;
        blocksPerYear = _blocksPerYear;
    }

    /*********************************/
    /******** Security Check *********/
    /*********************************/

    /**
     * @notice Ensure this is an interest rate model contract.
     */
    function isInterestRateModel() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Calculate the utilization rate: `_borrows / (_cash + _borrows - _reserves)`
     * @param _cash Asset balance
     * @param _borrows Asset borrows
     * @param _reserves Asset reserves
     * @return Asset utilization [0, 1e18]
     */
    function utilizationRate(
        uint256 _cash,
        uint256 _borrows,
        uint256 _reserves
    ) internal pure returns (uint256) {
        // Utilization rate is 0 when there are no borrows
        if (_borrows == 0) return 0;

        // Utilization rate is 100% when _grossSupply is less than or equal to borrows
        uint256 _grossSupply = _cash.add(_borrows);
        if (_grossSupply <= _reserves) return ONE;

        // Utilization rate is 100% when _borrows is greater than _supply
        uint256 _supply = _grossSupply.sub(_reserves);
        if (_borrows > _supply) return ONE;

        return _borrows.rdiv(_supply);
    }

    /**
     * @notice Get the current borrow rate per block, 18 decimal places
     * @param _balance Asset balance
     * @param _borrows Asset borrows
     * @param _reserves Asset reserves
     * @return _borrowRate Current borrow rate APR
     */
    function getBorrowRate(
        uint256 _balance,
        uint256 _borrows,
        uint256 _reserves
    ) external view returns (uint256 _borrowRate) {
        uint256 _util = utilizationRate(_balance, _borrows, _reserves);
        uint256 _annualBorrowRateScaled = 0;

        // Borrow rate is:
        // 1). when Ur < Uoptimal, Rate = R0 + R1 * Ur / Uoptimal
        // 2). when Ur >= Uoptimal, Rate = R0 + R1 + R2 * (Ur-Uoptimal)/(1-Uoptimal)
        // R0: Base, R1: Slope1, R2: Slope2
        if (_util < optimal) {
            _annualBorrowRateScaled = base.add(slope_1.mul(_util).div(optimal));
        } else {
            _annualBorrowRateScaled = base.add(slope_1).add(slope_2.mul(_util.sub(optimal)).div(ONE.sub(optimal)));
        }

        // And then divide down by blocks per year.
        _borrowRate = _annualBorrowRateScaled.div(blocksPerYear);
    }
}

contract StablePrimaryInterestModel is InterestRateModelV2 {
    constructor(uint256 _blocksPerYear) public InterestRateModelV2(0, 0.9e18, 0.05e18, 0.6e18, _blocksPerYear) {}
}

contract StableSecondaryInterestModel is InterestRateModelV2 {
    constructor(uint256 _blocksPerYear) public InterestRateModelV2(0, 0.8e18, 0.07e18, 1e18, _blocksPerYear) {}
}

contract BNBLikeInterestModel is InterestRateModelV2 {
    constructor(uint256 _blocksPerYear) public InterestRateModelV2(0, 0.9e18, 0.09e18, 1e18, _blocksPerYear) {}
}

contract MainPrimaryInterestModel is InterestRateModelV2 {
    constructor(uint256 _blocksPerYear) public InterestRateModelV2(0, 0.7e18, 0.05e18, 1e18, _blocksPerYear) {}
}

contract MainSecondaryInterestModel is InterestRateModelV2 {
    constructor(uint256 _blocksPerYear) public InterestRateModelV2(0, 0.65e18, 0.07e18, 0.8e18, _blocksPerYear) {}
}

contract CakeLikeInterestModel is InterestRateModelV2 {
    constructor(uint256 _blocksPerYear) public InterestRateModelV2(0, 0.65e18, 0.07e18, 1.2e18, _blocksPerYear) {}
}

contract ETHLikeInterestModel is InterestRateModelV2 {
    constructor(uint256 _blocksPerYear) public InterestRateModelV2(0, 0.7e18, 0.03e18, 0.25e18, _blocksPerYear) {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

library SafeRatioMath {
    using SafeMathUpgradeable for uint256;

    uint256 private constant BASE = 10**18;
    uint256 private constant DOUBLE = 10**36;

    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.add(y.sub(1)).div(y);
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(y).div(BASE);
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(BASE).div(y);
    }

    function rdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(BASE).add(y.sub(1)).div(y);
    }

    function tmul(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256 result) {
        result = x.mul(y).mul(z).div(DOUBLE);
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 base
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
                case 0 {
                    switch n
                        case 0 {
                            z := base
                        }
                        default {
                            z := 0
                        }
                }
                default {
                    switch mod(n, 2)
                        case 0 {
                            z := base
                        }
                        default {
                            z := x
                        }
                    let half := div(base, 2) // for rounding.

                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, base)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(
                                iszero(iszero(x)),
                                iszero(eq(div(zx, x), z))
                            ) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, base)
                        }
                    }
                }
        }
    }
}