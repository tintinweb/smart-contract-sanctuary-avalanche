/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-16
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openswapdex/oracle-adaptor-core/contracts/interfaces/[email protected]

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.6.11;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// File @openswapdex/oracle-adaptor-core/contracts/interfaces/[email protected]


pragma solidity =0.6.11;

interface IFactory {

    function minLotSize(address token) external view returns (uint256);
    function getPair(address tokenA, address tokenB) external view returns (address pair);

}


// File @openswapdex/oracle-adaptor-core/contracts/interfaces/[email protected]


pragma solidity =0.6.11;

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


// File @openswapdex/oracle-adaptor-core/contracts/interfaces/[email protected]


pragma solidity =0.6.11;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// File @openswapdex/oracle-adaptor-core/contracts/interfaces/[email protected]


pragma solidity =0.6.11;

interface IOSWAP_OracleAdaptor {
    function isSupported(address from, address to) external view returns (bool supported);
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) external view returns (uint256 numerator, uint256 denominator);
    function getLatestPrice(address from, address to, bytes calldata payload) external view returns (uint256 price);
    function decimals() external view returns (uint8);
}


// File @openswapdex/oracle-adaptor-core/contracts/libraries/[email protected]



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


// File @openswapdex/oracle-adaptor-core/contracts/[email protected]


pragma solidity =0.6.11;
abstract contract OSWAP_OracleChainlinkBase is IOSWAP_OracleAdaptor {
	using SafeMath for uint256;

    uint8 constant _DECIMALS = 18;
    uint256 constant DECIMALS = uint256(_DECIMALS);
    uint256 constant WEI = 10**DECIMALS;
    uint256 constant WEI_SQ = 10**(DECIMALS*2);

    address public immutable WETH;

    constructor(address _weth) public {
        WETH = _weth;
    }
    mapping (address => address) public priceFeedAddresses;

    uint8 public chainlinkDeicmals = 18;

    function _getLatestPrice(address priceFeedAddress) internal view returns (uint256 price, uint8 decimals) {
        require(priceFeedAddress != address(0), "OSWAP: price feed not found");
        (,int256 price1,,,) = AggregatorV3Interface(priceFeedAddress).latestRoundData();
        decimals = chainlinkDeicmals;
        require(price1 > 0, "OSWAP_OracleChainlink: Negative or zero price");
        price = uint256(price1);
    }
    function getRatio(address from, address to, uint256 /*fromAmount*/, uint256 /*toAmount*/, bytes calldata /*payload*/) public view override virtual returns (uint256 numerator, uint256 denominator) {
        require(from != to, "OSWAP: from and to addresses are the same");
        if (from == WETH) {
            uint8 decimals;
            address fromEth = priceFeedAddresses[to];
            (denominator, decimals) = _getLatestPrice(fromEth);
            numerator = 10**uint256(decimals);
        } else if (to == WETH) {
            uint8 decimals;
            address toEth = priceFeedAddresses[from];
            (numerator, decimals) = _getLatestPrice(toEth);
            denominator = 10**uint256(decimals);
        } else {
            address toEth = priceFeedAddresses[from];
            uint8 decimals1;
            (numerator, decimals1) = _getLatestPrice(toEth);

            address fromEth = priceFeedAddresses[to];
            uint8 decimals2;
            (denominator, decimals2) = _getLatestPrice(fromEth);

            if (decimals2 > decimals1){
                numerator = uint256(numerator).mul(10**(uint256(decimals2).sub(decimals1)));
            } else {
                denominator = uint256(denominator).mul(10**(uint256(decimals1).sub(decimals2)));
            }
        }
    }
    function isSupported(address from, address to) public view override virtual returns (bool supported) {
        if (from == WETH) {
            address fromEth = priceFeedAddresses[to];
            supported = (fromEth != address(0));
        } else if (to == WETH) {
            address toEth = priceFeedAddresses[from];
            supported = (toEth != address(0));
        } else {
            address toEth = priceFeedAddresses[from];
            address fromEth = priceFeedAddresses[to];
            supported = (toEth != address(0) && fromEth != address(0));
        }
    }
    function getLatestPrice(address from, address to, bytes calldata payload) external view override returns (uint256 price) {
        (uint256 numerator, uint256 denominator) = getRatio(from, to, 0, 0, payload);
        price = numerator.mul(WEI).div(denominator);
    }
    function decimals() external view override returns (uint8) {
        return _DECIMALS;
    }
}


// File @openswapdex/oracle-adaptor-core/contracts/interfaces/[email protected]


pragma solidity =0.6.11;
interface IOSWAP_OracleAdaptorPriceGuard is IOSWAP_OracleAdaptor {
    function getPriceInfo(address from, address to, uint256 fromAmount, uint256 toAmount) external view returns (uint256 chainlinkPrice, uint256 ammPrice, uint256 usdAmount);
}


// File @openswapdex/oracle-adaptor-core/contracts/[email protected]


pragma solidity =0.6.11;
abstract contract OSWAP_OracleChainlinkPriceGuardBase is OSWAP_OracleChainlinkBase, IOSWAP_OracleAdaptorPriceGuard {
	using SafeMath for uint256;

    address public immutable wethPriceFeed;
    uint8 public wethDecimals = 8;

    address public immutable factory;
    uint256 public immutable maxValue;
    uint256 public immutable low;
    uint256 public immutable high;
    bool public immutable useAmmPrice;

    mapping (address => uint8) public decimals;

    
    constructor(address _wethPriceFeed, address _factory, uint256 _maxValue, uint256 _deviation, bool _useAmmPrice) public {
        require(_deviation <= WEI, "Invalid price range");
        wethPriceFeed = _wethPriceFeed;
        factory = _factory;
        maxValue = _maxValue;
        low = WEI.sub(_deviation);
        high = WEI.add(_deviation);
        useAmmPrice = _useAmmPrice;
    }

    function convertEthDecimals(uint256 amount, address token) internal view returns (uint256) {
        uint256 decimals2 = decimals[token];
        require(decimals2 > 0, "OracleAdaptor: token not supported");
        if (decimals2 > 18) {
            amount = amount.mul(10 ** uint256(decimals2-18));
        } else if (decimals2 < 18) {
            amount = amount.div(10 ** uint256(18-decimals2));
        }
        return amount;
    }

    function _getRatio(address from, address to, uint256 fromAmount, uint256 toAmount) internal view virtual returns (uint256 usdAmount, uint256 numerator, uint256 denominator, uint112 reserve0, uint112 reserve1) {
        require(from != to, "OSWAP: from and to addresses are the same");

        uint256 ethAmount;

        if (from == WETH) {
            // eth -> token
            ethAmount = fromAmount;
            uint8 _decimals;
            address fromEth = priceFeedAddresses[to];
            (denominator, _decimals) = _getLatestPrice(fromEth);
            numerator = 10**uint256(_decimals);

            if (ethAmount == 0) {
                // exact token out
                ethAmount = toAmount.mul(denominator).div(numerator);
                ethAmount = convertEthDecimals(ethAmount, to);
            }
        } else if (to == WETH) {
            // token -> eth
            ethAmount = toAmount;
            uint8 _decimals;
            address toEth = priceFeedAddresses[from];
            (numerator, _decimals) = _getLatestPrice(toEth);
            denominator = 10**uint256(_decimals);

            if (ethAmount == 0) {
                // exact token in
                ethAmount = fromAmount.mul(numerator).div(denominator);
                ethAmount = convertEthDecimals(ethAmount, from);
            }
        } else {
            address toEth = priceFeedAddresses[from];
            uint8 decimals1;
            (numerator, decimals1) = _getLatestPrice(toEth);

            address fromEth = priceFeedAddresses[to];
            uint8 decimals2;
            (denominator, decimals2) = _getLatestPrice(fromEth);

            if (fromAmount == 0) {
                // exact out: find equivalent ETH amount
                ethAmount = toAmount.mul(denominator).div(10**uint256(decimals2));
                ethAmount = convertEthDecimals(ethAmount, to);
            } else if (toAmount == 0) {
                // exact in: find equivalent ETH amount
                ethAmount = fromAmount.mul(numerator).div(10**uint256(decimals1));
                ethAmount = convertEthDecimals(ethAmount, from);
            } else {
                revert("OracleAdaptor: Invalid amount");
            }
        }

        (,int256 ethPrice,,,) =  AggregatorV3Interface(wethPriceFeed).latestRoundData();
        usdAmount = uint256(ethPrice).mul(ethAmount).div(10**uint256(wethDecimals));

        address pair = IFactory(factory).getPair(from, to);
        require(address(pair) != address(0), "pair not exists");

        // from < to: amountout = amountin * reserve1 / reserve0
        // to < from: amountout = amountin * reserve0 / reserve1
        (reserve0, reserve1, ) = IPair(pair).getReserves();
        if (to < from)
            (reserve0, reserve1) = (reserve1, reserve0);
    }
    function getPriceInfo(address from, address to, uint256 fromAmount, uint256 toAmount) public view override virtual returns (uint256 chainlinkPrice, uint256 ammPrice, uint256 usdAmount) {
        uint256 numerator;
        uint256 denominator;
        uint112 reserve0;
        uint112 reserve1;
        (usdAmount, numerator, denominator, reserve0, reserve1) = _getRatio(from, to, fromAmount, toAmount);

        chainlinkPrice = numerator.mul(WEI).div(denominator);

        if (reserve0 != 0) {
            uint8 decimals0 = decimals[from];
            uint8 decimals1 = decimals[to];

            ammPrice = uint256(reserve1).mul(WEI);
            if (decimals1 < decimals0) {
                ammPrice = ammPrice.mul(10**(uint256(decimals0-decimals1)));
            }
            ammPrice = ammPrice.div(reserve0);
            if (decimals0 < decimals1) {
                ammPrice = ammPrice.div(10**(uint256(decimals1-decimals0)));
            }
        }
    }
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata /*payload*/) public view override(IOSWAP_OracleAdaptor,OSWAP_OracleChainlinkBase) virtual returns (uint256 numerator, uint256 denominator) {
        uint256 usdAmount;
        uint112 reserve0;
        uint112 reserve1;
        (usdAmount, numerator, denominator, reserve0, reserve1) = _getRatio(from, to, fromAmount, toAmount);

        require(usdAmount <= maxValue, "OracleAdaptor: Exceessive amount");

        uint256 n1 = denominator.mul(reserve1);
        uint256 n2 = numerator.mul(reserve0);

        uint8 decimals0 = decimals[from];
        uint8 decimals1 = decimals[to];
        uint256 ratio;
        if (decimals1 < decimals0) {
            ratio = 10**(uint256(decimals0-decimals1));
            n1 = n1.mul(ratio);
        } else if (decimals0 < decimals1) {
            ratio = 10**(uint256(decimals1-decimals0));
            n2 = n2.mul(ratio);
        }

        if (useAmmPrice) {
            // low < (reserve1 / reserve0) / (numerator / denominator) < high
            // low < (reserve1*denominator) / (reserve0*numerator) < high
            // low < n1 / n2 < high
            require(n1.mul(low) <= n2.mul(WEI) && n2.mul(WEI) <= n1.mul(high), "OracleAdaptor: Price outside allowed range");
            numerator = reserve1;
            denominator = reserve0;
            if (decimals1 < decimals0) {
                numerator = numerator.mul(ratio);
            } else if (decimals0 < decimals1) {
                denominator = denominator.mul(ratio);
            }
        } else {
            // low < (numerator / denominator) / (reserve1 / reserve0) < high
            // low < (reserve0*numerator) / (denominator*reserve1) < high
            // low < n2 / n1 < high
            require(n2.mul(low) <= n1.mul(WEI) && n1.mul(WEI) <= n2.mul(high), "OracleAdaptor: Price outside allowed range");
        }
    }
}


// File @openswapdex/oracle-adaptor-core/contracts/[email protected]


pragma solidity =0.6.11;
abstract contract OSWAP_OracleChainlinkFiatBase is OSWAP_OracleChainlinkBase {
    constructor() 
        // OSWAP_OracleChainlinkBase(address(0)) 
        public 
    {
        chainlinkDeicmals = 8;
    }
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) public view override virtual returns (uint256 numerator, uint256 denominator) {
        require(from != address(0) && to != address(0), "OSWAP: Oracle: Invalid address");
        return super.getRatio(from, to, fromAmount, toAmount, payload);
    }
    function isSupported(address from, address to) public view override virtual returns (bool supported) {
        if (from == address(0) || to == address(0)) {
            return false;
        }
        return super.isSupported(from, to);
    }
}


// File @openswapdex/oracle-adaptor-core/contracts/[email protected]


pragma solidity =0.6.11;
abstract contract OSWAP_OracleChainlinkPriceGuardFiatBase is OSWAP_OracleChainlinkPriceGuardBase, OSWAP_OracleChainlinkFiatBase {
	using SafeMath for uint256;

    function _getRatio(address from, address to, uint256 fromAmount, uint256 toAmount) internal override view returns (uint256 usdAmount, uint256 numerator, uint256 denominator, uint112 reserve0, uint112 reserve1) {
        require(from != to, "OSWAP: from and to addresses are the same");
        require(from != address(0) && to != address(0), "OSWAP: Oracle: Invalid address");

        address toUsd = priceFeedAddresses[from];
        (numerator, ) = _getLatestPrice(toUsd);

        address fromUsd = priceFeedAddresses[to];
        (denominator, ) = _getLatestPrice(fromUsd);

        if (fromAmount == 0) {
            usdAmount = toAmount.mul(denominator).div(10**uint256(chainlinkDeicmals));
            usdAmount = convertEthDecimals(usdAmount, to);
        } else if (toAmount == 0) {
            usdAmount = fromAmount.mul(numerator).div(10**uint256(chainlinkDeicmals));
            usdAmount = convertEthDecimals(usdAmount, from);
        } else {
            revert("OracleAdaptor: Invalid amount");
        }

        address pair = IFactory(factory).getPair(from, to);
        require(address(pair) != address(0), "pair not exists");

        // from < to: amountout = amountin * reserve1 / reserve0
        // to < from: amountout = amountin * reserve0 / reserve1
        (reserve0, reserve1, ) = IPair(pair).getReserves();
        if (to < from)
            (reserve0, reserve1) = (reserve1, reserve0);
    }
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) public view override(OSWAP_OracleChainlinkPriceGuardBase, OSWAP_OracleChainlinkFiatBase) virtual returns (uint256 numerator, uint256 denominator) {
        return OSWAP_OracleChainlinkPriceGuardBase.getRatio(from, to, fromAmount, toAmount, payload);
    }
    function isSupported(address from, address to) public view override(OSWAP_OracleChainlinkBase, OSWAP_OracleChainlinkFiatBase) virtual returns (bool supported) {
        return OSWAP_OracleChainlinkFiatBase.isSupported(from, to);
    }
}


// File @openswapdex/oracle-adaptor-core/contracts/[email protected]


pragma solidity =0.6.11;
abstract contract OSWAP_OracleChainlinkV1Base is IOSWAP_OracleAdaptor {
	using SafeMath for uint256;

    uint8 constant _DECIMALS = 18;
    uint256 constant DECIMALS = uint256(_DECIMALS);
    uint256 constant WEI = 10**DECIMALS;
    uint256 constant WEI_SQ = 10**(DECIMALS*2);

    address WETH;

    mapping (address => address) public priceFeedAddresses;

    function _getLatestPrice(address priceFeedAddress, bytes calldata /*payload*/) internal view returns (uint256 price, uint8 decimals) {
        require(priceFeedAddress != address(0), "OSWAP: price feed not found");
        (,int256 price1,,,) = AggregatorV3Interface(priceFeedAddress).latestRoundData();
        decimals = AggregatorV3Interface(priceFeedAddress).decimals();
        require(price1 > 0, "OSWAP_OracleChainlink: Negative or zero price");
        price = uint256(price1);
    }
    function getRatio(address from, address to, uint256 /*fromAmount*/, uint256 /*toAmount*/, bytes calldata payload) public view override virtual returns (uint256 numerator, uint256 denominator) {
        require(from != to, "OSWAP: from and to addresses are the same");
        if (from == WETH) {
            uint8 decimals;
            address fromEth = priceFeedAddresses[to];
            (denominator, decimals) = _getLatestPrice(fromEth, payload);
            numerator = 10**uint256(decimals);
        } else if (to == WETH) {
            uint8 decimals;
            address toEth = priceFeedAddresses[from];
            (numerator, decimals) = _getLatestPrice(toEth, payload);
            denominator = 10**uint256(decimals);
        } else {
            address toEth = priceFeedAddresses[from];
            uint8 decimals1;
            (numerator, decimals1) = _getLatestPrice(toEth, payload);

            address fromEth = priceFeedAddresses[to];
            uint8 decimals2;
            (denominator, decimals2) = _getLatestPrice(fromEth,  payload);

            if (decimals2 > decimals1){
                numerator = uint256(numerator).mul(10**(uint256(decimals2).sub(decimals1)));
            } else {
                denominator = uint256(denominator).mul(10**(uint256(decimals1).sub(decimals2)));
            }
        }
    }
    function isSupported(address from, address to) public view override virtual returns (bool supported) {
        if (from == WETH) {
            address fromEth = priceFeedAddresses[to];
            supported = (fromEth != address(0));
        } else if (to == WETH) {
            address toEth = priceFeedAddresses[from];
            supported = (toEth != address(0));
        } else {
            address toEth = priceFeedAddresses[from];
            address fromEth = priceFeedAddresses[to];
            supported = (toEth != address(0) && fromEth != address(0));
        }
    }
    function getLatestPrice(address from, address to, bytes calldata payload) external view override returns (uint256 price) {
        (uint256 numerator, uint256 denominator) = getRatio(from, to, 0, 0, payload);
        price = numerator.mul(WEI).div(denominator);
    }
    function decimals() external view override returns (uint8) {
        return _DECIMALS;
    }
}


// File contracts-test/OSWAP_OracleChainlinkTestnet.sol


pragma solidity =0.6.11;
contract OSWAP_OracleChainlinkV1Testnet is OSWAP_OracleChainlinkV1Base {
    constructor(address _weth, address[] memory _tokens, address[] memory pricefeed) public {
        WETH = _weth;
        require(_tokens.length == pricefeed.length, "Array length not match");
        uint256 length = _tokens.length;
        for (uint256 i = 0 ; i < length ; i++ ) {
            address token = _tokens[i];
            require(priceFeedAddresses[token] == address(0), "price feed already exists");
            priceFeedAddresses[token] = pricefeed[i];
        }
    }
}
contract OSWAP_OracleChainlinkTestnet is OSWAP_OracleChainlinkBase {
    constructor(address _weth, address[] memory _tokens, address[] memory pricefeed) 
        OSWAP_OracleChainlinkBase(_weth) 
        public 
    {
        require(_tokens.length == pricefeed.length, "Array length not match");
        uint256 length = _tokens.length;
        for (uint256 i = 0 ; i < length ; i++ ) {
            address token = _tokens[i];
            require(priceFeedAddresses[token] == address(0), "price feed already exists");
            priceFeedAddresses[token] = pricefeed[i];
        }
    }
}

contract OSWAP_OracleChainlinkFiatTestnet is OSWAP_OracleChainlinkFiatBase {
    constructor(address[] memory _tokens, address[] memory pricefeed) 
        OSWAP_OracleChainlinkBase(address(0))
        public 
    {
        require(_tokens.length == pricefeed.length, "Array length not match");
        uint256 length = _tokens.length;
        for (uint256 i = 0 ; i < length ; i++ ) {
            address token = _tokens[i];
            require(priceFeedAddresses[token] == address(0), "price feed already exists");
            priceFeedAddresses[token] = pricefeed[i];
        }
    }
}

contract OSWAP_OracleChainlinkKovan is OSWAP_OracleChainlinkBase {
    address public constant _WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    constructor(address dai, address usdc, address usdt) 
        OSWAP_OracleChainlinkBase(_WETH) 
        public 
    {
        // priceFeedAddresses[ampl] = 0x562C092bEb3a6DF77aDf0BB604F52c018E4f2814; // AMPL
        // priceFeedAddresses[bat] = 0x0e4fcEC26c9f85c3D714370c98f43C4E02Fc35Ae; // BAT
        // priceFeedAddresses[btc] = 0xF7904a295A029a3aBDFFB6F12755974a958C7C25; // BTC
        // priceFeedAddresses[busd] = 0xbF7A18ea5DE0501f7559144e702b29c55b055CcB; // BUSD
        // priceFeedAddresses[bzrx] = 0x9aa9da35DC44F93D90436BfE256f465f720c3Ae5; // BZRX
        priceFeedAddresses[dai] = 0x22B58f1EbEDfCA50feF632bD73368b2FdA96D541; // DAI
        // priceFeedAddresses[enj] = 0xfaDbe2ee798889F02d1d39eDaD98Eff4c7fe95D4; // ENJ
        // priceFeedAddresses[knc] = 0xb8E8130d244CFd13a75D6B9Aee029B1C33c808A7; // KNC
        // priceFeedAddresses[link] = 0x3Af8C569ab77af5230596Acf0E8c2F9351d24C38; // LINK
        // priceFeedAddresses[mana] = 0x1b93D8E109cfeDcBb3Cc74eD761DE286d5771511; // MANA
        // priceFeedAddresses[mkr] = 0x0B156192e04bAD92B6C1C13cf8739d14D78D5701; // MKR
        // priceFeedAddresses[rep] = 0x3A7e6117F2979EFf81855de32819FBba48a63e9e; // REP
        // priceFeedAddresses[snx] = 0xF9A76ae7a1075Fe7d646b06fF05Bd48b9FA5582e; // SNX
        // priceFeedAddresses[tusd] = 0x7aeCF1c19661d12E962b69eBC8f6b2E63a55C660; // TUSD
        priceFeedAddresses[usdc] = 0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838; // USDC
        priceFeedAddresses[usdt] = 0x0bF499444525a23E7Bb61997539725cA2e928138; // USDT
        // priceFeedAddresses[zrx] = 0xBc3f28Ccc21E9b5856E81E6372aFf57307E2E883; // ZRX
    }
}

contract OSWAP_OracleChainlinkRinkeby is OSWAP_OracleChainlinkBase {
    address public constant _WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    constructor(address dai, address usdc)  
        OSWAP_OracleChainlinkBase(_WETH) 
        public 
    {
        priceFeedAddresses[dai] = 0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D; // DAI
        priceFeedAddresses[usdc] = 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf; // USDC
    }
}

contract OSWAP_OracleChainlinkRopsten is OSWAP_OracleChainlinkBase {
    address public constant _WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    constructor(address dai, address usdc, address usdt)  
        OSWAP_OracleChainlinkBase(_WETH) 
        public 
    {
        priceFeedAddresses[dai] = 0x24959556020AE5D39e5bAEC2bd6Bf12420C25aB5; // DAI
        priceFeedAddresses[usdc] = 0xB8784d2D77D3dbaa9cAC7d32D035A6d41e414e9c; // USDC
        priceFeedAddresses[usdt] = 0x14137fA0D2Cf232922840081166a6a05C957bA4c; // USDT
    }
}

contract OSWAP_OracleChainlinkBinanceTestnet is OSWAP_OracleChainlinkBase {
    constructor(address wbnb, address dai)  
        OSWAP_OracleChainlinkBase(wbnb) 
        public 
    {
        // WBNB
        // pancakeswap: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd (wbnb)
        // burgerswap: 0x2f8b72301c05c444585d24B93e1e06bE9D0c35b2 (weth)
        priceFeedAddresses[dai] = 0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c; // DAI
    }
}

contract OSWAP_OracleChainlinkFiatKovan is OSWAP_OracleChainlinkFiatBase {
    constructor(address eth, address dai, address usdc, address usdt) 
        OSWAP_OracleChainlinkBase(address(0)) 
        public 
    {
        // USD based
        // priceFeedAddresses[aud] = 0x5813A90f826e16dB392abd2aF7966313fc1fd5B8; // AUD
        // priceFeedAddresses[bat] = 0x8e67A0CFfbbF6A346ce87DFe06daE2dc782b3219; // BAT
        // priceFeedAddresses[bnb] = 0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16; // BNB
        // priceFeedAddresses[btc] = 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e; // BTC
        // priceFeedAddresses[chf] = 0xed0616BeF04D374969f302a34AE4A63882490A8C; // CHF
        // priceFeedAddresses[comp] = 0xECF93D14d25E02bA2C13698eeDca9aA98348EFb6; // COMP
        priceFeedAddresses[dai] = 0x777A68032a88E5A84678A77Af2CD65A7b3c0775a; // DAI
        priceFeedAddresses[eth] = 0x9326BFA02ADD2366b30bacB125260Af641031331; // ETH
        // priceFeedAddresses[eur] = 0x0c15Ab9A0DB086e062194c273CC79f41597Bbf13; // EUR
        // priceFeedAddresses[gbp] = 0x28b0061f44E6A9780224AA61BEc8C3Fcb0d37de9; // GBP
        // priceFeedAddresses[jpy] = 0xD627B1eF3AC23F1d3e576FA6206126F3c1Bd0942; // JPY
        // priceFeedAddresses[krw] = 0x9e465c5499023675051517E9Ee5f4C334D91e369; // KRW
        // priceFeedAddresses[link] = 0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0; // LINK
        // priceFeedAddresses[ltc] = 0xCeE03CF92C7fFC1Bad8EAA572d69a4b61b6D4640; // LTC
        // priceFeedAddresses[oil] = 0x48c9FF5bFD7D12e3C511022A6E54fB1c5b8DC3Ea; // Oil
        // priceFeedAddresses[php] = 0x84fdC8dD500F29902C99c928AF2A91970E7432b6; // PHP
        // priceFeedAddresses[rep] = 0x8f4e77806EFEC092A279AC6A49e129e560B4210E; // REP
        // priceFeedAddresses[snx] = 0x31f93DA9823d737b7E44bdee0DF389Fe62Fd1AcD; // SNX
        // priceFeedAddresses[trx] = 0x9477f0E5bfABaf253eacEE3beE3ccF08b46cc79c; // TRX
        // priceFeedAddresses[tsla] = 0xb31357d152638fd1ae0853d24b9Ea81dF29E3EF2; // TSLA
        // priceFeedAddresses[uni] = 0xDA5904BdBfB4EF12a3955aEcA103F51dc87c7C39; // UNI
        priceFeedAddresses[usdc] = 0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60; // USDC
        priceFeedAddresses[usdt] = 0x2ca5A90D34cA333661083F89D831f757A9A50148; // USDT
        // priceFeedAddresses[velo] = 0x6d393f929E213D2Ca67A7FA73108A42b884F5f74; // VELO
        // priceFeedAddresses[xag] = 0x4594051c018Ac096222b5077C3351d523F93a963; // XAG
        // priceFeedAddresses[xau] = 0xc8fb5684f2707C82f28595dEaC017Bfdf44EE9c5; // XAU
        // priceFeedAddresses[xrp] = 0x3eA2b7e3ed9EA9120c3d6699240d1ff2184AC8b3; // XRP
        // priceFeedAddresses[xtz] = 0xC6F39246494F25BbCb0A8018796890037Cb5980C; // XTZ
        // priceFeedAddresses[zrx] = 0x24D6B177CF20166cd8F55CaaFe1c745B44F6c203; // ZRX
        // priceFeedAddresses[scex] = 0xA85646318D20C684f6251097d24A6e74Fe1ED5eB; // sCEX
        // priceFeedAddresses[sdefi] = 0x70179FB2F3A0a5b7FfB36a235599De440B0922ea; // sDEFI
    }
}

contract OSWAP_OracleChainlinkFiatBinanceTestnet is OSWAP_OracleChainlinkFiatBase {
    constructor(address wbnb, address busd, address usdt) 
        OSWAP_OracleChainlinkBase(address(0)) 
        public 
    {
        // Using the list of Chainlink symbol to address from 
        // https://docs.chain.link/docs/binance-smart-chain-addresses
        // and token list from 
        // https://github.com/pancakeswap/pancake-swap-interface/blob/master/src/constants/token/pancakeswap.json

        // USD based
        // priceFeedAddresses[ada] = 0x5e66a1775BbC249b5D51C13d29245522582E671C; // ADA
        // priceFeedAddresses[bake] = 0xbe75E0725922D78769e3abF0bcb560d1E2675d5d; // BAKE
        // priceFeedAddresses[bch] = 0x887f177CBED2cf555a64e7bF125E1825EB69dB82; // BCH
        priceFeedAddresses[wbnb] = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526; // BNB
        // priceFeedAddresses[btc] = 0x5741306c21795FdCBb9b265Ea0255F499DFe515C; // BTC
        priceFeedAddresses[busd] = 0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa; // BUSD
        // priceFeedAddresses[cake] = 0x81faeDDfeBc2F8Ac524327d70Cf913001732224C; // CAKE
        // priceFeedAddresses[cream] = 0xB8eADfD8B78aDA4F85680eD96e0f50e1B5762b0a; // CREAM
        // priceFeedAddresses[dai] = 0xE4eE17114774713d2De0eC0f035d4F7665fc025D; // DAI
        // priceFeedAddresses[dodo] = 0x2939E0089e61C5c9493C2013139885444c73a398; // DODO
        // priceFeedAddresses[doge] = 0x963D5e7f285Cc84ed566C486c3c1bC911291be38; // DOGE
        // priceFeedAddresses[dot] = 0xEA8731FD0685DB8AeAde9EcAE90C4fdf1d8164ed; // DOT
        // priceFeedAddresses[eqz] = 0x6C2441920404835155f33d88faf0545B895871b1; // EQZ
        // priceFeedAddresses[eth] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7; // ETH
        // priceFeedAddresses[fil] = 0x17308A18d4a50377A4E1C37baaD424360025C74D; // FIL
        // priceFeedAddresses[front] = 0x101E51C0Bc2D2213a9b0c991A991958aAd3fF96A; // FRONT
        // priceFeedAddresses[inj] = 0x58b299Fa027E1d9514dBbEeBA7944FD744553d61; // INJ
        // priceFeedAddresses[link] = 0x1B329402Cb1825C6F30A0d92aB9E2862BE47333f; // LINK
        // priceFeedAddresses[ltc] = 0x9Dcf949BCA2F4A8a62350E0065d18902eE87Dca3; // LTC
        // priceFeedAddresses[matic] = 0x957Eb0316f02ba4a9De3D308742eefd44a3c1719; // MATIC
        // priceFeedAddresses[reef] = 0x902fA2495a8c5E89F7496F91678b8CBb53226D06; // REEF
        // priceFeedAddresses[sfp] = 0x4b531A318B0e44B549F3b2f824721b3D0d51930A; // SFP
        // priceFeedAddresses[sxp] = 0x678AC35ACbcE272651874E782DB5343F9B8a7D66; // SXP
        // priceFeedAddresses[twt] = 0x7671d7EDb66E4C10d5FFaA6a0d8842B5d880F0B3; // TWT
        // priceFeedAddresses[usdc] = 0x90c069C4538adAc136E051052E14c1cD799C41B7; // USDC
        priceFeedAddresses[usdt] = 0xEca2605f0BCF2BA5966372C99837b1F182d3D620; // USDT
        // priceFeedAddresses[vai] = 0xdb398f7B5927b92ec52C0Ae5D3090DB147eAedA5; // VAI
        // priceFeedAddresses[xrp] = 0x4046332373C24Aed1dC8bAd489A04E187833B28d; // XRP
        // priceFeedAddresses[xvs] = 0xCfA786C17d6739CBC702693F23cA4417B5945491; // XVS
    }
}

contract OSWAP_OracleChainlinkFiatAvalancheTestnet is OSWAP_OracleChainlinkFiatBase {
    constructor(address wavax, address usdt) 
        OSWAP_OracleChainlinkBase(address(0)) 
        public 
    {
        // Using the list of Chainlink symbol to address from 
        // https://docs.chain.link/docs/avalanche-price-feeds

        // USD based
        priceFeedAddresses[wavax] = 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD; // AVAX
        priceFeedAddresses[usdt] = 0x7898AcCC83587C3C55116c5230C17a6Cd9C71bad; // USDT
    }
}


// File contracts-test/OSWAP_OracleChainlinkPriceGuardTestnet.sol


pragma solidity =0.6.11;
contract MockPriceGuardFactory is IFactory {
    mapping(address => mapping(address => address)) public override getPair;
    function set(address token0, address token1, address _pair) public {
        getPair[token0][token1] = _pair;
        getPair[token1][token0] = _pair;
    }
    function minLotSize(address /*token*/) external override view returns (uint256) {}
}

contract MockPriceGuardPair is IPair {
    address public immutable token0;
    address public immutable token1;
    uint112 public __reserve0;
    uint112 public __reserve1;
    constructor(address _token0, address _token1) public {
        require(_token0 != address(0) && _token0 < _token1);
        token0 = _token0;
        token1 = _token1;
    }
    function setReserves(uint112 _reserve0, uint112 _reserve1) public {
        __reserve0 = _reserve0;
        __reserve1 = _reserve1;
    }
    function getReserves() external override view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        return (__reserve0, __reserve1, 0);
    }
}

contract OSWAP_OracleChainlinkPriceGuardTestnet is OSWAP_OracleChainlinkTestnet, OSWAP_OracleChainlinkPriceGuardBase {
    constructor(address _weth, address wethPriceFeed, address[] memory _tokens, address[] memory _pricefeeds, address _factory, uint256 _maxValue, uint256 _deviation, bool _useAmmPrice) 
        public 
        OSWAP_OracleChainlinkTestnet(_weth, _tokens, _pricefeeds)
        OSWAP_OracleChainlinkPriceGuardBase(wethPriceFeed, _factory, _maxValue, _deviation, _useAmmPrice)
    {
        decimals[_weth] = IERC20(_weth).decimals();
        uint256 length = _tokens.length;
        for (uint256 i = 0 ; i < length ; i++) {
            address token = _tokens[i];
            decimals[token] = IERC20(token).decimals();
        }
    }
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) public view override (OSWAP_OracleChainlinkBase, OSWAP_OracleChainlinkPriceGuardBase) returns (uint256 numerator, uint256 denominator) {
        return OSWAP_OracleChainlinkPriceGuardBase.getRatio(from, to, fromAmount, toAmount, payload);
    }
}
contract OSWAP_OracleChainlinkPriceGuardKovan is OSWAP_OracleChainlinkKovan, OSWAP_OracleChainlinkPriceGuardBase {
    address constant kovanWethPriceFeed = 0x9326BFA02ADD2366b30bacB125260Af641031331;
    constructor(address dai, address usdc, address usdt, address _factory, uint256 _maxValue, uint256 _deviation, bool _useAmmPrice) 
        public
        OSWAP_OracleChainlinkKovan(dai, usdc, usdt)
        OSWAP_OracleChainlinkPriceGuardBase(kovanWethPriceFeed, _factory, _maxValue, _deviation, _useAmmPrice)
    {}
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) public view override (OSWAP_OracleChainlinkBase, OSWAP_OracleChainlinkPriceGuardBase) returns (uint256 numerator, uint256 denominator) {
        return OSWAP_OracleChainlinkPriceGuardBase.getRatio(from, to, fromAmount, toAmount, payload);
    }
}
contract OSWAP_OracleChainlinkPriceGuardBinanceTestnet is OSWAP_OracleChainlinkBinanceTestnet, OSWAP_OracleChainlinkPriceGuardBase {
    address constant bscWethPriceFeed = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
    constructor(address wbnb, address dai, address _factory, uint256 _maxValue, uint256 _deviation, bool _useAmmPrice) 
        public
        OSWAP_OracleChainlinkBinanceTestnet(wbnb, dai)
        OSWAP_OracleChainlinkPriceGuardBase(bscWethPriceFeed, _factory, _maxValue, _deviation, _useAmmPrice)
    {}
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) public view override (OSWAP_OracleChainlinkBase, OSWAP_OracleChainlinkPriceGuardBase) returns (uint256 numerator, uint256 denominator) {
        return OSWAP_OracleChainlinkPriceGuardBase.getRatio(from, to, fromAmount, toAmount, payload);
    }
}

contract OSWAP_OracleChainlinkPriceGuardFiatTestnet is OSWAP_OracleChainlinkFiatTestnet, OSWAP_OracleChainlinkPriceGuardFiatBase {
    constructor(address[] memory _tokens, address[] memory _pricefeeds, address _factory, uint256 _maxValue, uint256 _deviation, bool _useAmmPrice) 
        public 
        OSWAP_OracleChainlinkFiatTestnet(_tokens, _pricefeeds)
        OSWAP_OracleChainlinkPriceGuardBase(address(0), _factory, _maxValue, _deviation, _useAmmPrice)
    {
        uint256 length = _tokens.length;
        for (uint256 i = 0 ; i < length ; i++) {
            address token = _tokens[i];
            decimals[token] = IERC20(token).decimals();
        }
    }
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) public view override (OSWAP_OracleChainlinkFiatBase, OSWAP_OracleChainlinkPriceGuardFiatBase) returns (uint256 numerator, uint256 denominator) {
        return OSWAP_OracleChainlinkPriceGuardFiatBase.getRatio(from, to, fromAmount, toAmount, payload);
    }
    function isSupported(address from, address to) public view override (OSWAP_OracleChainlinkFiatBase, OSWAP_OracleChainlinkPriceGuardFiatBase) returns (bool supported) {
        return OSWAP_OracleChainlinkFiatBase.isSupported(from, to);
    }
}
contract OSWAP_OracleChainlinkPriceGuardFiatKovan is OSWAP_OracleChainlinkFiatKovan, OSWAP_OracleChainlinkPriceGuardFiatBase {
    constructor(address eth, address dai, address usdc, address usdt, address _factory, uint256 _maxValue, uint256 _deviation, bool _useAmmPrice) 
        public 
        OSWAP_OracleChainlinkFiatKovan(eth, dai, usdt, usdc)
        OSWAP_OracleChainlinkPriceGuardBase(address(0), _factory, _maxValue, _deviation, _useAmmPrice)
    {
        decimals[eth] = 18;
        decimals[dai] = 18;
        decimals[usdc] = 6;
        decimals[usdt] = 6;

    }
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) public view override (OSWAP_OracleChainlinkFiatBase, OSWAP_OracleChainlinkPriceGuardFiatBase) returns (uint256 numerator, uint256 denominator) {
        return OSWAP_OracleChainlinkPriceGuardFiatBase.getRatio(from, to, fromAmount, toAmount, payload);
    }
    function isSupported(address from, address to) public view override (OSWAP_OracleChainlinkFiatBase, OSWAP_OracleChainlinkPriceGuardFiatBase) returns (bool supported) {
        return OSWAP_OracleChainlinkPriceGuardFiatBase.isSupported(from, to);
    }
}
contract OSWAP_OracleChainlinkPriceGuardFiatBinanceTestnet is OSWAP_OracleChainlinkFiatBinanceTestnet, OSWAP_OracleChainlinkPriceGuardFiatBase {
    constructor(address wbnb, address busd, address usdt, address _factory, uint256 _maxValue, uint256 _deviation, bool _useAmmPrice) 
        public 
        OSWAP_OracleChainlinkFiatBinanceTestnet(wbnb, busd, usdt)
        OSWAP_OracleChainlinkPriceGuardBase(address(0), _factory, _maxValue, _deviation, _useAmmPrice)
    {
        decimals[wbnb] = 18;
        decimals[busd] = 18;
        decimals[usdt] = 6;

    }
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) public view override (OSWAP_OracleChainlinkFiatBase, OSWAP_OracleChainlinkPriceGuardFiatBase) returns (uint256 numerator, uint256 denominator) {
        return OSWAP_OracleChainlinkPriceGuardFiatBase.getRatio(from, to, fromAmount, toAmount, payload);
    }
    function isSupported(address from, address to) public view override (OSWAP_OracleChainlinkFiatBase, OSWAP_OracleChainlinkPriceGuardFiatBase) returns (bool supported) {
        return OSWAP_OracleChainlinkPriceGuardFiatBase.isSupported(from, to);
    }
}

contract OSWAP_OracleChainlinkPriceGuardFiatAvalancheTestnet is OSWAP_OracleChainlinkFiatAvalancheTestnet, OSWAP_OracleChainlinkPriceGuardFiatBase {
    constructor(address wavax, address usdt, address _factory, uint256 _maxValue, uint256 _deviation, bool _useAmmPrice) 
        public 
        OSWAP_OracleChainlinkFiatAvalancheTestnet(wavax, usdt)
        OSWAP_OracleChainlinkPriceGuardBase(address(0), _factory, _maxValue, _deviation, _useAmmPrice)
    {
        decimals[wavax] = 18;
        decimals[usdt] = 6;
    }
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) public view override (OSWAP_OracleChainlinkFiatBase, OSWAP_OracleChainlinkPriceGuardFiatBase) returns (uint256 numerator, uint256 denominator) {
        return OSWAP_OracleChainlinkPriceGuardFiatBase.getRatio(from, to, fromAmount, toAmount, payload);
    }
    function isSupported(address from, address to) public view override (OSWAP_OracleChainlinkFiatBase, OSWAP_OracleChainlinkPriceGuardFiatBase) returns (bool supported) {
        return OSWAP_OracleChainlinkPriceGuardFiatBase.isSupported(from, to);
    }
}