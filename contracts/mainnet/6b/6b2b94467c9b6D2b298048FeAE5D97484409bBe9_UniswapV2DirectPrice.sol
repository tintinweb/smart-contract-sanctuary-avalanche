//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {BasePriceOracle} from "BasePriceOracle.sol";
import "IUniswapV2Pair.sol";
import "IERC20.sol";

/**
 * @title On-chain Price Oracle for IUniswapV2Pair
 * @notice WARNING - this reads the immediate price from the trading pair and is subject to flash loan attack
 * only use this as an indicative price, DO NOT use the price for any trading decisions
 */
contract UniswapV2DirectPrice is BasePriceOracle {
    uint8 public constant override decimals = 18;
    string public override description;

    // Uniswap V2 token pair
    IUniswapV2Pair public uniswapV2Pair;
    IERC20 public token0; // pair token with the lower sort order
    IERC20 public token1; // pair token with the higher sort order

    // Uniswap token decimals
    uint8 private decimals0;
    uint8 private decimals1;

    constructor(address uniswapV2PairAddr) public {
        require(uniswapV2PairAddr != address(0), "Uniswap V2 pair address is 0");
        uniswapV2Pair = IUniswapV2Pair(uniswapV2PairAddr);
        address _baseAddr = uniswapV2Pair.token0();
        address _quoteAddr = uniswapV2Pair.token1();

        require(_baseAddr != address(0), "token0 address is 0");
        require(_quoteAddr != address(0), "token1 address is 0");
        token0 = IERC20(_baseAddr);
        token1 = IERC20(_quoteAddr);
        decimals0 = token0.decimals();
        decimals1 = token1.decimals();

        super.setSymbols(token0.symbol(), token1.symbol(), _baseAddr, _quoteAddr);
        description = string(abi.encodePacked(baseSymbol, " / ", quoteSymbol));
    }

    /**
     * @dev blockTimestampLast is the `block.timestamp` (mod 2**32) of the last block
     * during which an interaction occurred for the pair.
     * NOTE: 2**32 is about 136 years. It is safe to cast the timestamp to uint256.
     */
    function lastUpdate() external view override returns (uint256 updateAt) {
        (, , uint32 blockTimestampLast) = uniswapV2Pair.getReserves();
        updateAt = uint256(blockTimestampLast);
    }

    function priceInternal() internal view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = uniswapV2Pair.getReserves();
        // avoid mul and div by 0
        if (reserve0 > 0 && reserve1 > 0) {
            return (10**(decimals + decimals1 - decimals0) * uint256(reserve0)) / uint256(reserve1);
        }
        return type(uint256).max;
    }

    function price(address _baseAddr) external view override isValidSymbol(_baseAddr) returns (uint256) {
        uint256 priceFeed = priceInternal();
        if (priceFeed == type(uint256).max) return priceFeed;
        if (quoteAddr == _baseAddr) return priceFeed;
        return 1e36 / priceFeed;
    }

    /**
     * @return true if both reserves are positive, false otherwise
     * NOTE: this is to avoid multiplication and division by 0
     */
    function isValidUniswapReserve() external view returns (bool) {
        (uint112 reserve0, uint112 reserve1, ) = uniswapV2Pair.getReserves();
        return reserve0 > 0 && reserve1 > 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IPriceOracle} from "IPriceOracle.sol";

/**
 * @title BasePriceOracle Abstract Contract
 * @notice Abstract Contract to implement variables and modifiers in common
 */
abstract contract BasePriceOracle is IPriceOracle {
    string public override baseSymbol;
    string public override quoteSymbol;
    address public override baseAddr;
    address public override quoteAddr;

    function setSymbols(
        string memory _baseSymbol,
        string memory _quoteSymbol,
        address _baseAddr,
        address _quoteAddr
    ) internal {
        baseSymbol = _baseSymbol;
        quoteSymbol = _quoteSymbol;
        baseAddr = _baseAddr;
        quoteAddr = _quoteAddr;
    }

    modifier isValidSymbol(address addr) {
        require(addr == baseAddr || addr == quoteAddr, "Symbol not in this price oracle");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPriceOracle {
    /**
     * @return decimals of the "baseSymbol / quoteSymbol" rate
     */
    function decimals() external view returns (uint8);

    /**
     * @return name of the token pair, in the form of "baseSymbol / quoteSymbol"
     */
    function description() external view returns (string memory);

    /**
     * @return name of the base symbol
     */
    function baseSymbol() external view returns (string memory);

    /**
     * @return name of the quote symbol
     */
    function quoteSymbol() external view returns (string memory);

    /**
     * @return address of the base symbol, zero address if `baseSymbol` is USD
     */
    function baseAddr() external view returns (address);

    /**
     * @return address of the quote symbol, zero address if `baseSymbol` is USD
     */
    function quoteAddr() external view returns (address);

    /**
     * @return updateAt timestamp of the last update as seconds since unix epoch
     */
    function lastUpdate() external view returns (uint256 updateAt);

    /**
     * @param _baseAddr address of the base currency in the currency pair
     * @return "baseSymbol / quoteSymbol" rate, i.e. quantity of quote currency in exchange for 1 unit of base currency,
     * where the baseSymbol is specified in the input parameter, return type(uint256).max for invalid rate
     */
    function price(address _baseAddr) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

pragma solidity >=0.5.0;

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