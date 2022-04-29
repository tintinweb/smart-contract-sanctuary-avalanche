// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./SafeDecimalMath.sol";
// import "hardhat/console.sol";

contract SmOracle {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    struct PriceInfo {
        uint256[] blockNumbers;
        bytes32[] transactionHashes;
        uint256[] tokenIds;
        uint256[] prices;
    }
    struct TokenInfo {
        bool isRare;
        uint256 priceLastUpdatedTimestamp;
    }
    mapping(bytes32 => uint256) public lastUpdatedBlocks;
    mapping(bytes32 => PriceInfo) private priceInfo;
    // tokenNameInBytes => tokenId => TokenInfo
    mapping(bytes32 => mapping(uint256 => TokenInfo)) public tokenInfo;

    function updatePriceInfo(
        bytes32 _currencyKey,
        uint256[] calldata _timestamp,
        uint256[] calldata _blockNumbers,
        bytes32[] calldata _transactionHashes,
        uint256[] calldata _tokenIds,
        uint256[] calldata _prices
    ) external 
    {
        require(
            _prices.length == _blockNumbers.length && 
            _prices.length == _tokenIds.length && 
            _prices.length == _transactionHashes.length &&
            _prices.length == _timestamp.length, "length of 5 input arrays not align"
        );
        for (uint256 i = 0; i < _prices.length; i++) {
            if (i > 0) {
                require(_blockNumbers[i] >= _blockNumbers[i-1], "block numbers should be in ascending order");
            } else {
                require(_blockNumbers[i] > lastUpdatedBlocks[_currencyKey], "new block must be larger than last updated block");
            }
            if (i == _prices.length - 1) {
                lastUpdatedBlocks[_currencyKey] = _blockNumbers[i];
            }
            // exclude rare token
            if (tokenInfo[_currencyKey][_tokenIds[i]].isRare == true) {
                continue;
            }
            // randomized cool down period
            if (_timestamp[i] - tokenInfo[_currencyKey][_tokenIds[i]].priceLastUpdatedTimestamp < 4 * 3600) {
                continue;
            } else if (_timestamp[i] - tokenInfo[_currencyKey][_tokenIds[i]].priceLastUpdatedTimestamp < 12 * 3600 && getRandomness() == 2) {
                continue;
            }
            priceInfo[_currencyKey].blockNumbers.push(_blockNumbers[i]);
            priceInfo[_currencyKey].transactionHashes.push(_transactionHashes[i]);
            priceInfo[_currencyKey].tokenIds.push(_tokenIds[i]);
            priceInfo[_currencyKey].prices.push(_prices[i]);
            tokenInfo[_currencyKey][_tokenIds[i]].priceLastUpdatedTimestamp = _timestamp[i];
        }
    }

    function setRareTokenId(
        bytes32 _currencyKey,
        uint256[] calldata _tokenIds, 
        bool[] calldata _isRare
    ) external 
    {
        require(_tokenIds.length == _isRare.length, "length of 2 input arrays not align");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenInfo[_currencyKey][_tokenIds[i]].isRare = _isRare[i];
        }
    }

    function getTwap(bytes32 _currencyKey) public view returns(uint256) {
        uint256 priceSum = 0;
        uint256 counter = 20;
        uint256 actualCounter = 0;
        (uint256 sd, uint256 mean) = getStandardDeviationAndMean(_currencyKey);
        for (uint256 i = priceInfo[_currencyKey].prices.length - counter; i < priceInfo[_currencyKey].prices.length; i++) {
            // only include data within 2 SD
            if (priceInfo[_currencyKey].prices[i] >= mean) {
                if (priceInfo[_currencyKey].prices[i] - mean <= sd.mul(2)) {
                    priceSum += priceInfo[_currencyKey].prices[i];
                    actualCounter++;
                } else {
                    continue;
                }
            } else {
                if (mean - priceInfo[_currencyKey].prices[i] <= sd.mul(2)) {
                    priceSum += priceInfo[_currencyKey].prices[i];
                    actualCounter++;
                } else {
                    continue;
                }
            }
        }
        require(actualCounter >= 10, "not enough price data for twap");
        return priceSum / actualCounter;
    }

    function getStandardDeviationAndMean(bytes32 _currencyKey) public view returns(uint256, uint256) {
        uint256 priceSum = 0;
        uint256 counter = 20;
        require(priceInfo[_currencyKey].prices.length >= counter, "not enough price data for calculation of standard deviation & mean");
        for (uint256 i = priceInfo[_currencyKey].prices.length - counter; i < priceInfo[_currencyKey].prices.length; i++) {
            priceSum += priceInfo[_currencyKey].prices[i];
        }
        uint256 mean = priceSum / counter;
        uint256 temp = 0;
        for (uint256 i = priceInfo[_currencyKey].prices.length - counter; i < priceInfo[_currencyKey].prices.length; i++) {
            if (priceInfo[_currencyKey].prices[i] >= mean) {
                temp += (priceInfo[_currencyKey].prices[i].sub(mean)) ** 2;
            } else {
                temp += (mean.sub(priceInfo[_currencyKey].prices[i])) ** 2;
            }
        }
        return (sqrt(temp / counter), mean);
    }

    function getPriceInfo(bytes32 _currencyKey, uint256 _index) public view returns(uint256, bytes32, uint256, uint256) {
        return ( 
            priceInfo[_currencyKey].blockNumbers[_index],
            priceInfo[_currencyKey].transactionHashes[_index],
            priceInfo[_currencyKey].tokenIds[_index], 
            priceInfo[_currencyKey].prices[_index]
        );
    }

    function getRandomness() public view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 3;
    }

    // https://github.com/Uniswap/v2-core/blob/v1.0.1/contracts/libraries/Math.sol
    function sqrt(uint y) public pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint;

    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    uint public constant UNIT = 10**uint(decimals);

    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    function unit() external pure returns (uint) {
        return UNIT;
    }

    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        return x.mul(y) / UNIT;
    }

    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        return x.mul(UNIT).div(y);
    }

    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}