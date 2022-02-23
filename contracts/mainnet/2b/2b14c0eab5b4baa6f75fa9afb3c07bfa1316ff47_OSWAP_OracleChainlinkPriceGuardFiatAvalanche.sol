/**
 *Submitted for verification at snowtrace.io on 2022-02-23
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File contracts/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: GPL-3.0-only
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


// File contracts/interfaces/IOSWAP_OracleAdaptor.sol


pragma solidity =0.6.11;

interface IOSWAP_OracleAdaptor {
    function isSupported(address from, address to) external view returns (bool supported);
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) external view returns (uint256 numerator, uint256 denominator);
    function getLatestPrice(address from, address to, bytes calldata payload) external view returns (uint256 price);
    function decimals() external view returns (uint8);
}


// File contracts/libraries/SafeMath.sol



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


// File contracts/OSWAP_OracleChainlinkBase.sol


pragma solidity =0.6.11;
abstract contract OSWAP_OracleChainlinkBase is IOSWAP_OracleAdaptor {
	using SafeMath for uint256;

    uint8 constant _DECIMALS = 18;
    uint256 constant DECIMALS = uint256(_DECIMALS);
    uint256 constant WEI = 10**DECIMALS;
    uint256 constant WEI_SQ = 10**(DECIMALS*2);

    address public immutable WETH;

    mapping (address => address) public priceFeedAddresses;

    uint8 public chainlinkDeicmals = 18;

    constructor(address _weth) public {
        WETH = _weth;
    }

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


// File contracts/OSWAP_OracleChainlinkFiatBase.sol


pragma solidity =0.6.11;
abstract contract OSWAP_OracleChainlinkFiatBase is OSWAP_OracleChainlinkBase {
    constructor() OSWAP_OracleChainlinkBase(address(0)) public {
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


// File contracts/OSWAP_OracleChainlinkFiatAvalanche.sol


pragma solidity =0.6.11;
contract OSWAP_OracleChainlinkFiatAvalanche is OSWAP_OracleChainlinkFiatBase {
    constructor() OSWAP_OracleChainlinkFiatBase() public {

        // Using the list of Chainlink symbol to address from 
        // https://docs.chain.link/docs/avalanche-price-feeds
        // and token list from 
        // https://raw.githubusercontent.com/traderjoe-xyz/joe-tokenlists/main/joe.tokenlist.json
        // https://raw.githubusercontent.com/pangolindex/tokenlists/main/top15.tokenlist.json
        // https://raw.githubusercontent.com/pangolindex/tokenlists/main/aeb.tokenlist.json
        // https://raw.githubusercontent.com/pangolindex/tokenlists/main/stablecoin.tokenlist.json

        priceFeedAddresses[0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7] = 0x0A77230d17318075983913bC2145DB16C7366156; // AVAX
        priceFeedAddresses[0x63a72806098Bd3D9520cC43356dD78afe5D386D9] = 0x3CA13391E9fb38a75330fb28f8cc2eB3D9ceceED; // AAVE
        priceFeedAddresses[0x2147EFFF675e4A4eE1C2f918d181cDBd7a8E208f] = 0x7B0ca9A6D03FE0467A31Ca850f5bcA51e027B3aF; // ALPHA
        priceFeedAddresses[0x027dbcA046ca156De9622cD1e2D907d375e53aa7] = 0xcf667FB6Bd30c520A435391c50caDcDe15e5e12f; // AMPL
        priceFeedAddresses[0x50b7545627a5162F82A992c33b87aDc75187B218] = 0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743; // BTC
        priceFeedAddresses[0x19860CCB0A68fd4213aB9D8266F7bBf05A8dDe98] = 0x827f8a0dC5c943F7524Dda178E2e7F275AAd743f; // BUSD.e
        priceFeedAddresses[0xd586E7F844cEa2F87f50152665BCbc2C279D8d70] = 0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300; // DAI
        priceFeedAddresses[0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0; // ETH
        priceFeedAddresses[0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd] = 0x02D35d3a8aC3e1626d3eE09A78Dd87286F5E8e3a; // JOE
        priceFeedAddresses[0x5947BB275c521040051D82396192181b413227A3] = 0x49ccd9ca821EfEab2b98c60dC60F518E765EDe9a; // LINK
        priceFeedAddresses[0x130966628846BFd36ff31a822705796e8cb8C18D] = 0x54EdAB30a7134A16a54218AE64C73e1DAf48a8Fb; // MIM
        priceFeedAddresses[0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5] = 0x36E039e6391A5E7A7267650979fdf613f659be5D; // QI
        priceFeedAddresses[0xCE1bFFBD5374Dac86a2893119683F4911a2F7814] = 0x4F3ddF9378a4865cf4f28BE51E10AECb83B7daeE; // SPELL
        priceFeedAddresses[0x39cf1BD5f15fb22eC3D9Ff86b0727aFc203427cc] = 0x449A373A090d8A1e5F74c63Ef831Ceff39E94563; // SUSHI
        priceFeedAddresses[0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB] = 0x9Cf3Ef104A973b351B2c032AA6793c3A6F76b448; // TUSD
        priceFeedAddresses[0xf39f9671906d8630812f9d9863bBEf5D523c84Ab] = 0x9a1372f9b1B71B3A5a72E092AE67E172dBd7Daaa; // UNI
        priceFeedAddresses[0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664] = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9; // USDC.e
        priceFeedAddresses[0xc7198437980c041c805A1EDcbA50c1Ce5db95118] = 0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a; // USDT.e
        priceFeedAddresses[0x260Bbf5698121EB85e7a74f2E45E16Ce762EbE11] = 0xf58B78581c480caFf667C63feDd564eCF01Ef86b; // UST
   }
}


// File contracts/interfaces/IFactory.sol


pragma solidity =0.6.11;

interface IFactory {

    function minLotSize(address token) external view returns (uint256);
    function getPair(address tokenA, address tokenB) external view returns (address pair);

}


// File contracts/interfaces/IPair.sol


pragma solidity =0.6.11;

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


// File contracts/interfaces/IOSWAP_OracleAdaptorPriceGuard.sol


pragma solidity =0.6.11;
interface IOSWAP_OracleAdaptorPriceGuard is IOSWAP_OracleAdaptor {
    function getPriceInfo(address from, address to, uint256 fromAmount, uint256 toAmount) external view returns (uint256 chainlinkPrice, uint256 ammPrice, uint256 usdAmount);
}


// File contracts/OSWAP_OracleChainlinkPriceGuardBase.sol


pragma solidity =0.6.11;
abstract contract OSWAP_OracleChainlinkPriceGuardBase is OSWAP_OracleChainlinkBase, IOSWAP_OracleAdaptorPriceGuard {
	using SafeMath for uint256;

    address public immutable wethPriceFeed;
    uint8 public wethDecimals = 8;

    address public immutable factory;
    uint256 public immutable maxValue;
    uint256 public immutable low;
    uint256 public immutable high;
    bool public immutable returnAmmPrice;

    mapping (address => uint8) public decimals;

    constructor(address _wethPriceFeed, address _factory, uint256 _maxValue, uint256 _deviation, bool _returnAmmPrice) public {
        require(_deviation <= WEI, "Invalid price range");
        wethPriceFeed = _wethPriceFeed;
        factory = _factory;
        maxValue = _maxValue;
        low = WEI.sub(_deviation);
        high = WEI.add(_deviation);
        returnAmmPrice = _returnAmmPrice;
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

        if (returnAmmPrice) {
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


// File contracts/OSWAP_OracleChainlinkPriceGuardFiatBase.sol


pragma solidity =0.6.11;
abstract contract OSWAP_OracleChainlinkPriceGuardFiatBase is OSWAP_OracleChainlinkPriceGuardBase, OSWAP_OracleChainlinkFiatBase {
	using SafeMath for uint256;

    constructor(address _factory, uint256 _maxValue, uint256 _deviation, bool _returnAmmPrice) 
        public 
        OSWAP_OracleChainlinkPriceGuardBase(address(0), _factory, _maxValue, _deviation, _returnAmmPrice)
    {
    }

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


// File contracts/OSWAP_OracleChainlinkPriceGuardFiatAvalanche.sol


pragma solidity =0.6.11;
contract OSWAP_OracleChainlinkPriceGuardFiatAvalanche is OSWAP_OracleChainlinkFiatAvalanche, OSWAP_OracleChainlinkPriceGuardFiatBase {
    constructor(address _factory, uint256 _maxValue, uint256 _deviation, bool _returnAmmPrice)
        OSWAP_OracleChainlinkFiatAvalanche()
        OSWAP_OracleChainlinkPriceGuardFiatBase(_factory, _maxValue, _deviation, _returnAmmPrice)
        public 
    {
        decimals[0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7] = 18; // AVAX
        decimals[0x63a72806098Bd3D9520cC43356dD78afe5D386D9] = 18; // AAVE
        decimals[0x2147EFFF675e4A4eE1C2f918d181cDBd7a8E208f] = 18; // ALPHA
        decimals[0x027dbcA046ca156De9622cD1e2D907d375e53aa7] = 9; // AMPL
        decimals[0x50b7545627a5162F82A992c33b87aDc75187B218] = 8; // BTC
        decimals[0x19860CCB0A68fd4213aB9D8266F7bBf05A8dDe98] = 18; // BUSD.e
        decimals[0xd586E7F844cEa2F87f50152665BCbc2C279D8d70] = 18; // DAI
        decimals[0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB] = 18; // ETH
        decimals[0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd] = 18; // JOE
        decimals[0x5947BB275c521040051D82396192181b413227A3] = 18; // LINK
        decimals[0x130966628846BFd36ff31a822705796e8cb8C18D] = 18; // MIM
        decimals[0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5] = 18; // QI
        decimals[0xCE1bFFBD5374Dac86a2893119683F4911a2F7814] = 18; // SPELL
        decimals[0x39cf1BD5f15fb22eC3D9Ff86b0727aFc203427cc] = 18; // SUSHI
        decimals[0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB] = 18; // TUSD
        decimals[0xf39f9671906d8630812f9d9863bBEf5D523c84Ab] = 18; // UNI
        decimals[0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664] = 6; // USDC.e
        decimals[0xc7198437980c041c805A1EDcbA50c1Ce5db95118] = 6; // USDT.e
        decimals[0x260Bbf5698121EB85e7a74f2E45E16Ce762EbE11] = 6; // UST
    }
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) public view override (OSWAP_OracleChainlinkFiatBase, OSWAP_OracleChainlinkPriceGuardFiatBase) returns (uint256 numerator, uint256 denominator) {
        return OSWAP_OracleChainlinkPriceGuardFiatBase.getRatio(from, to, fromAmount, toAmount, payload);
    }
    function isSupported(address from, address to) public view override (OSWAP_OracleChainlinkFiatBase, OSWAP_OracleChainlinkPriceGuardFiatBase) returns (bool supported) {
        return OSWAP_OracleChainlinkPriceGuardFiatBase.isSupported(from, to);
    }
}