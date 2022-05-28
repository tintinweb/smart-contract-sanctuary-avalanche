// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./SafeDecimalMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

contract SmOracleNew is Ownable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    struct TransactionData {
        uint256[] timestamp;
        uint256[] blockNumbers;
        bytes32[] transactionHashes;
        uint256[] tokenIds;
        uint256[] prices;
    }
    struct TokenInfo {
        bool isRare;
        uint256 priceLastUpdatedTimestamp;
        // cannot accept decimal !!!!!!!!!!!!!!!!!!
        int256[] attributeRarityScore; // input value = actual value * 1e9
    }
    struct RegressionStat {
        // cannot accept decimal !!!!!!!!!!!!!!!!!!
        int256[] coefficients; // input value = actual value * 1e4
        int256 intercept; // input value = actual value * 1e9 * 1e4
    }
    struct DeltaStat {
        uint256[] deltaAbsDiff;
        uint256[] timestamp;
    }
    mapping(bytes32 => uint256) public lastUpdatedBlocks;
    mapping(bytes32 => RegressionStat) private regressionStats;
    mapping(bytes32 => DeltaStat) private deltaStats;
    mapping(bytes32 => TransactionData) private transactionData;
    // tokenNameInBytes => tokenId => TokenInfo
    mapping(bytes32 => mapping(uint256 => TokenInfo)) private tokenInfo;
    mapping(bytes32 => uint256) public initialDailyAveragePrices;
    uint256 public counter = 20;
    uint256 public timeInterval = 1800;
    uint256 public totalNumOfInterval = 25;
    uint256 public twapIndex = 2;
    bool public isTraitFilter = false;

    function updateTransactionData(
        bytes32 _currencyKey,
        uint256[] memory _timestamp,
        uint256[] memory _blockNumbers,
        bytes32[] memory _transactionHashes,
        uint256[] memory _tokenIds,
        uint256[] memory _prices
    ) external onlyOwner
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
                require(_blockNumbers[i] >= lastUpdatedBlocks[_currencyKey], "new block must be larger than or equal to last updated block");
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
            // trait filter
            if (isTraitFilter == true) {
                int256 predictedDelta = getPredictedDelta(_currencyKey, _tokenIds[i]);
                int256 actualDelta = getActualDelta(_currencyKey, _prices[i]);
                uint256 deltaAbsDiff = sqrt(uint256((predictedDelta - actualDelta) * (predictedDelta - actualDelta)));
                deltaStats[_currencyKey].deltaAbsDiff.push(deltaAbsDiff);
                deltaStats[_currencyKey].timestamp.push(_timestamp[i]);
                if (transactionData[_currencyKey].prices.length >= counter) {
                    (uint256 deltaSd, uint256 deltaMean) = getStandardDeviationAndMeanWithin24hr(_currencyKey, 2);
                    if (deltaAbsDiff > deltaMean + 165 * deltaSd / 100) {
                        continue;
                    }
                }
            }
            
            transactionData[_currencyKey].blockNumbers.push(_blockNumbers[i]);
            transactionData[_currencyKey].timestamp.push(_timestamp[i]);
            transactionData[_currencyKey].transactionHashes.push(_transactionHashes[i]);
            transactionData[_currencyKey].tokenIds.push(_tokenIds[i]);
            transactionData[_currencyKey].prices.push(_prices[i]);
            tokenInfo[_currencyKey][_tokenIds[i]].priceLastUpdatedTimestamp = _timestamp[i];
        }
    }

    function setRareTokenId(
        bytes32 _currencyKey,
        uint256[] memory _tokenIds, 
        bool[] memory _isRare
    ) external onlyOwner
    {
        require(_tokenIds.length == _isRare.length, "length of 2 input arrays not align");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenInfo[_currencyKey][_tokenIds[i]].isRare = _isRare[i];
        }
    }

    function setIsTraitFilter(bool _isTraitFilter) external onlyOwner {
        isTraitFilter = _isTraitFilter;
    }

    function setTimeInterval(uint256 _timeInterval) external onlyOwner {
        timeInterval = _timeInterval;
    }

    function setTotalNumOfInterval(uint256 _totalNumOfInterval) external onlyOwner {
        totalNumOfInterval = _totalNumOfInterval;
    }

    function setCounter(uint256 _counter) external onlyOwner {
        counter = _counter;
    }

    function setInitialDailyAveragePrice(bytes32 _currencyKey, uint256 _initialDailyAveragePrice) external onlyOwner {
        initialDailyAveragePrices[_currencyKey] = _initialDailyAveragePrice;
    }

    function setRegressionStats(bytes32 _currencyKey, int256[] memory _coefficients, int256 _intercept) external onlyOwner {
        regressionStats[_currencyKey].coefficients = _coefficients;
        regressionStats[_currencyKey].intercept = _intercept;
    }

    function setAttributeRarityScore(bytes32 _currencyKey, int256[] memory _attributeRarityScore, uint256[] memory _tokenId) external onlyOwner {
        require(_attributeRarityScore.length == _tokenId.length * regressionStats[_currencyKey].coefficients.length, "length of 2 input arrays not align");
        uint256 j = 0;
        for (uint256 i = 0; i < _attributeRarityScore.length; i++){
            if ( i % regressionStats[_currencyKey].coefficients.length == 0) {
                if (i != 0) {
                    j++;
                }
                delete tokenInfo[_currencyKey][_tokenId[j]].attributeRarityScore;
            }
            tokenInfo[_currencyKey][_tokenId[j]].attributeRarityScore.push(_attributeRarityScore[i]);
        }
    }

    function getPredictedDelta(bytes32 _currencyKey, uint256 _tokenId) public view returns(int256) {
        int256 predictedDelta = 0;
        // regression formula: y = mx + c
        for (uint256 i = 0; i < regressionStats[_currencyKey].coefficients.length; i++) {
            predictedDelta += regressionStats[_currencyKey].coefficients[i] * tokenInfo[_currencyKey][_tokenId].attributeRarityScore[i];
        }
        return predictedDelta + regressionStats[_currencyKey].intercept;
    }

    function getActualDelta(bytes32 _currencyKey, uint256 _price) public view returns (int256) {
        uint256 dailyAveragePrice = getDailyAveragePrice(_currencyKey);
        return ( int256(_price) - int256(dailyAveragePrice) ) * 1e9 * 1e4 / int256(dailyAveragePrice);
    }

    function getTwap(bytes32 _currencyKey) public view returns(uint256) {
        if (twapIndex == 1) {
            uint256 priceSum = 0;
            uint256 actualCounter = 0;
            (uint256 sd, uint256 mean) = getStandardDeviationAndMeanWithinCounter(_currencyKey);
            for (uint256 i = transactionData[_currencyKey].prices.length - counter; i < transactionData[_currencyKey].prices.length; i++) {
                // only include data within 2 SD
                if (transactionData[_currencyKey].prices[i] >= mean) {
                    if (transactionData[_currencyKey].prices[i] - mean <= sd.mul(2)) {
                        priceSum += transactionData[_currencyKey].prices[i];
                        actualCounter++;
                    } else {
                        continue;
                    }
                } else {
                    if (mean - transactionData[_currencyKey].prices[i] <= sd.mul(2)) {
                        priceSum += transactionData[_currencyKey].prices[i];
                        actualCounter++;
                    } else {
                        continue;
                    }
                }
            }
            require(actualCounter >= counter - 10, "not enough price data for twap");
            return priceSum / actualCounter;
        } else if (twapIndex == 2) {
            require(transactionData[_currencyKey].prices.length >= totalNumOfInterval, "not enough price data for twap");
            uint256 each_interval_price_sum = 0;
            uint256 each_interval_price_counter = 0;
            uint256 average_price_sum = 0;
            uint256 average_price_counter = 0;
            uint256 intervalIndex = 0;
            uint256 i = transactionData[_currencyKey].prices.length - 1;
            while (i >= 0) {
                if (
                    block.timestamp - transactionData[_currencyKey].timestamp[i] >= intervalIndex * timeInterval && 
                    block.timestamp - transactionData[_currencyKey].timestamp[i] < (intervalIndex + 1) * timeInterval
                ) {
                    average_price_sum += transactionData[_currencyKey].prices[i];
                    average_price_counter++;
                    i--;
                } else {
                    if (average_price_sum > 0) {
                        each_interval_price_sum += average_price_sum / average_price_counter;
                        each_interval_price_counter++;
                        average_price_sum = 0;
                        average_price_counter = 0;
                    }
                    if (intervalIndex == totalNumOfInterval - 1) {
                        break;
                    }
                    intervalIndex++;
                }
            }
            return each_interval_price_sum / each_interval_price_counter;
        } else {
            require(twapIndex == 1 || twapIndex == 2, "twapIndex must be 1 or 2");
        }
    }

    function getDailyAveragePrice(bytes32 _currencyKey) public view returns(uint256) {
        if (transactionData[_currencyKey].prices.length < counter) {
            return initialDailyAveragePrices[_currencyKey];
        }
        uint256 priceSum = 0;
        uint256 actualCounter = 0;
        (uint256 sd, uint256 mean) = getStandardDeviationAndMeanWithin24hr(_currencyKey, 1);

        for (uint256 i = transactionData[_currencyKey].prices.length - 1; i >= 0; i--) {
            if (block.timestamp - transactionData[_currencyKey].timestamp[i] > 3600 * 24) {
                break;
            } else {
                // only include data within 2 SD
                if (transactionData[_currencyKey].prices[i] >= mean) {
                    if (transactionData[_currencyKey].prices[i] - mean <= sd.mul(2)) {
                        priceSum += transactionData[_currencyKey].prices[i];
                        actualCounter++;
                    } else {
                        continue;
                    }
                } else {
                    if (mean - transactionData[_currencyKey].prices[i] <= sd.mul(2)) {
                        priceSum += transactionData[_currencyKey].prices[i];
                        actualCounter++;
                    } else {
                        continue;
                    }
                }
            }
        }

        return priceSum / actualCounter;
    }

    function getStandardDeviationAndMeanWithin24hr(bytes32 _currencyKey, uint256 _index) public view returns(uint256, uint256) {
        uint256[] memory datasetArray;
        uint256[] memory timestampArray;
        if (_index == 1) {
            datasetArray = transactionData[_currencyKey].prices;
            timestampArray = transactionData[_currencyKey].timestamp;
        } else if (_index == 2) {
            datasetArray = deltaStats[_currencyKey].deltaAbsDiff;
            timestampArray = deltaStats[_currencyKey].timestamp;
        }
        uint256 actualCounter = 0;
        uint256 dataSum = 0;
        for (uint256 i = datasetArray.length - 1; i >= 0; i--) {
            if (block.timestamp - timestampArray[i] > 3600 * 24) {
                break;
            } else {
                dataSum += datasetArray[i];
                actualCounter++;
            }
        }
        uint256 mean = dataSum / actualCounter;
        uint256 temp = 0;
        for (uint256 i = datasetArray.length - 1; i >= 0; i--) {
            if (block.timestamp - timestampArray[i] > 3600 * 24) {
                break;
            } else {
                if (datasetArray[i] >= mean) {
                    temp += (datasetArray[i].sub(mean)) ** 2;
                } else {
                    temp += (mean.sub(datasetArray[i])) ** 2;
                }
            }
        }
        return (sqrt(temp / actualCounter), mean);
    }

    function getStandardDeviationAndMeanWithinCounter(bytes32 _currencyKey) public view returns(uint256, uint256) {
        uint256 priceSum = 0;
        require(transactionData[_currencyKey].prices.length >= counter, "not enough price data for calculation of standard deviation & mean");
        for (uint256 i = transactionData[_currencyKey].prices.length - counter; i < transactionData[_currencyKey].prices.length; i++) {
            priceSum += transactionData[_currencyKey].prices[i];
        }
        uint256 mean = priceSum / counter;
        uint256 temp = 0;
        for (uint256 i = transactionData[_currencyKey].prices.length - counter; i < transactionData[_currencyKey].prices.length; i++) {
            if (transactionData[_currencyKey].prices[i] >= mean) {
                temp += (transactionData[_currencyKey].prices[i].sub(mean)) ** 2;
            } else {
                temp += (mean.sub(transactionData[_currencyKey].prices[i])) ** 2;
            }
        }
        return (sqrt(temp / counter), mean);
    }

    function getTransactionData(bytes32 _currencyKey, uint256 _index) public view returns(uint256, uint256, bytes32, uint256, uint256) {
        return ( 
            transactionData[_currencyKey].timestamp[_index],
            transactionData[_currencyKey].blockNumbers[_index],
            transactionData[_currencyKey].transactionHashes[_index],
            transactionData[_currencyKey].tokenIds[_index], 
            transactionData[_currencyKey].prices[_index]
        );
    }

    function getTokenInfo(bytes32 _currencyKey, uint256 _tokenId, uint256 _index) public view returns(bool, uint256, int256) {
        return ( 
            tokenInfo[_currencyKey][_tokenId].isRare,
            tokenInfo[_currencyKey][_tokenId].priceLastUpdatedTimestamp,
            tokenInfo[_currencyKey][_tokenId].attributeRarityScore[_index]
        );
    }

    function getRegressionStat(bytes32 _currencyKey, uint256 _index) public view returns(int256, int256) {
        return ( 
            regressionStats[_currencyKey].coefficients[_index],
            regressionStats[_currencyKey].intercept
        );
    }

    function getDeltaStat(bytes32 _currencyKey, uint256 _index) public view returns(uint256, uint256) {
        return ( 
            deltaStats[_currencyKey].deltaAbsDiff[_index],
            transactionData[_currencyKey].timestamp[_index]
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}