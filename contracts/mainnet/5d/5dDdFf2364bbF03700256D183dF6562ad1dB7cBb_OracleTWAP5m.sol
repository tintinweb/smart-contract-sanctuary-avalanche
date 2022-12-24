// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface ISicleFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToStake() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToStake(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface ISiclePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.16;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // decode a UQ112x112 as uint112
    function decode(uint224 y) internal pure returns (uint224 z) {
        z = y / Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./interface/ISicleFactory.sol";
import "./interface/ISiclePair.sol";
import "./libraries/UQ112x112.sol";

contract OracleTWAP5m {
    using UQ112x112 for uint224;

    using UQ112x112 for *;

    uint256 public constant PERIOD = uint32(5 minutes % 2 ** 32);

    address public pair;
    address public immutable token0;
    address public immutable token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;

    uint256 public price0Average;
    uint256 public price1Average;    

    constructor(address _factory, address _token0, address _token1) {
        pair = ISicleFactory(_factory).getPair(_token0, _token1);
        ISiclePair siclePair = ISiclePair(pair);
        token0 = siclePair.token0();
        token1 = siclePair.token1();
        price0CumulativeLast = siclePair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = siclePair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)

        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = siclePair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "Oracle: NO_RESERVES"); // ensure that there's liquidity in the pair
        blockTimestampLast = _currentBlockTimestamp();
    }

    function update() external returns (bool) {
        if (_currentBlockTimestamp() - blockTimestampLast < PERIOD)
            return false;
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = _currentCumulativePrices(address(pair));

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Time from the last time it was updated
        price0Average = uint224(
            (price0Cumulative - price0CumulativeLast) * 1e12 / timeElapsed // *1e12 -> POPS and USDC have different decimals 1e18/1e6
        );
        price1Average = uint224(
            (price1Cumulative - price1CumulativeLast) / timeElapsed
        );

        // Update state variables
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
        return true;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(
        address token,
        uint amountIn
    ) external view returns (uint256 amountOut) {
        if (token == token0) {
            // Token Out => div by 1e18 to put the decimals
            amountOut = uint256(
                UQ112x112.decode(uint224(price0Average * amountIn))
            );
        } else {
            require(token == token1, "Oracle: INVALID_TOKEN");
            // Token Out => div by 1e18 to put the decimals
            amountOut = uint256(
                UQ112x112.decode(uint224(price1Average * amountIn))
            );
        }
    }

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function _currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // helper function that produces the cumulative price
    function _currentCumulativePrices(
        address _pair
    )
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        ISiclePair siclePair = ISiclePair(_pair);
        blockTimestamp = _currentBlockTimestamp();

        price0Cumulative = siclePair.price0CumulativeLast();
        price1Cumulative = siclePair.price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        ) = siclePair.getReserves();

        if (blockTimestamp > _blockTimestampLast) {
            // Storing cumulative Price Data on-Chain
            uint32 timeElapsed = blockTimestamp - _blockTimestampLast;
            price0Cumulative +=
                uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                timeElapsed; 
            price1Cumulative +=
                uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                timeElapsed;
        }
    }
}