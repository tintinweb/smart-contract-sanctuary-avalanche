// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IRouter {
    struct Route {
        address from;
        address to;
        bool stable;
    }

    function factory() external view returns (address);

    function WMATIC() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    
    function addLiquidityAVAX(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountMATICMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountMATIC, uint liquidity);
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityMATIC(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountMATICMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountMATIC);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityMATICWithPermit(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountMATICMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountMATIC);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactMATICForTokens(
        uint amountOutMin,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactMATIC(
        uint amountOut,
        uint amountInMax,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForMATIC(
        uint amountIn,
        uint amountOutMin,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapMATICForExactTokens(
        uint amountOut,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity
    ) external view returns (uint amountA, uint amountB);

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    )
        external
        view
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function pairFor(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (address pair);

    function sortTokens(address tokenA, address tokenB)
        external
        pure
        returns (address token0, address token1);

    function quoteLiquidity(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint amount, bool stable);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn, bool stable);

    function getAmountsOut(uint amountIn, Route[] memory routes)
        external
        view
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, Route[] memory routes)
        external
        view
        returns (uint[] memory amounts);

    function getReserves(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (uint reserveA, uint reserveB);

    function getExactAmountOut(
        uint amountIn,
        address tokenIn,
        address tokenOut,
        bool stable
    ) external view returns (uint amount);

    function isPair(address pair) external view returns (bool);

    function swapExactTokensForTokensSimple(
        uint amountIn,
        uint amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForMATICSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external;

    function swapExactMATICForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external;

    function removeLiquidityMATICWithPermitSupportingFeeOnTransferTokens(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountFTM);

    function removeLiquidityMATICSupportingFeeOnTransferTokens(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountFTM);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IPair {

  // Structure to capture time period obervations every 30 minutes, used for local oracles
  struct Observation {
    uint timestamp;
    uint reserve0Cumulative;
    uint reserve1Cumulative;
  }

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function burn(address to) external returns (uint amount0, uint amount1);

  function mint(address to) external returns (uint liquidity);

  function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

  function getAmountOut(uint, address) external view returns (uint);

  function claimFees() external returns (uint, uint);

  function tokens() external view returns (address, address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function stable() external view returns (bool);

  function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IFactory {
  function treasury() external view returns (address);

  function treasuryFee() external view returns (uint);

  function partnerFee() external view returns (uint);

  function admin() external view returns (address);

  function partnerSetter() external view returns (address);

  function isPair(address pair) external view returns (bool);

  function getInitializable() external view returns (address, address, bool);

  function isPaused() external view returns (bool);

  function getFees(bool _stable) external view returns (uint);

  function pairCodeHash() external pure returns (bytes32);

  function getPair(address tokenA, address token, bool stable) external view returns (address);

  function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

library Math {

  function max(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function positiveInt128(int128 value) internal pure returns (int128) {
    return value < 0 ? int128(0) : value;
  }

  function closeTo(uint a, uint b, uint target) internal pure returns (bool) {
    if (a > b) {
      if (a - b <= target) {
        return true;
      }
    } else {
      if (b - a <= target) {
        return true;
      }
    }
    return false;
  }

  function sqrt(uint y) internal pure returns (uint z) {
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

pragma solidity 0.8.13;

import "../../interface/IFactory.sol";
import "../../interface/IPair.sol";
import "../../lib/Math.sol";
import "../../interface/IRouter.sol";

contract SwapLibrary {

    address  immutable public factory;
    IRouter immutable public router;
    bytes32 immutable pairCodeHash;

    constructor(address _router) {
        router = IRouter(_router);
        factory = IRouter(_router).factory();
        pairCodeHash = IFactory(IRouter(_router).factory()).pairCodeHash();
    }

    function _f(uint x0, uint y) internal pure returns (uint) {
        return x0 * (y * y / 1e18 * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18) * y / 1e18;
    }

    function _d(uint x0, uint y) internal pure returns (uint) {
        return 3 * x0 * (y * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18);
    }

    function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
        for (uint i = 0; i < 255; i++) {
            uint y_prev = y;
            uint k = _f(x0, y);
            if (k < xy) {
                uint dy = (xy - k) * 1e18 / _d(x0, y);
                y = y + dy;
            } else {
                uint dy = (k - xy) * 1e18 / _d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    function getTradeDiff(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample = tokenIn == t0 ? r0 * dec1 / r1 : r1 * dec0 / r0;
        a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function getTradeDiffSimple(uint amountIn, address tokenIn, address tokenOut, bool stable, uint sample) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        if (sample == 0) {
            sample = _calcSample(tokenIn, t0, dec0, dec1);
        }
        a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function getTradeDiff2(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample;
        if (!stable) {
            sample = tokenIn == t0 ? r0 * dec1 / r1 : r1 * dec0 / r0;
        } else {
            sample = _calcSample(tokenIn, t0, dec0, dec1);
        }
        a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function getTradeDiff3(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample;
        if (!stable) {
            a = amountIn * 1e18 / (tokenIn == t0 ? r0 * 1e18 / r1 : r1 * 1e18 / r0);
        } else {
            sample = _calcSample(tokenIn, t0, dec0, dec1);
            a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * amountIn / sample;
        }
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st);
    }

    function _calcSample(address tokenIn, address t0, uint dec0, uint dec1) internal pure returns (uint){
        uint tokenInDecimals = tokenIn == t0 ? dec0 : dec1;
        uint tokenOutDecimals = tokenIn == t0 ? dec1 : dec0;
        return 10 ** Math.max(
            (tokenInDecimals > tokenOutDecimals ?
        tokenInDecimals - tokenOutDecimals
        : tokenOutDecimals - tokenInDecimals)
        , 1) * 10_000;
    }

    function getTradeDiff(uint amountIn, address tokenIn, address pair) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(pair).metadata();
        uint sample = tokenIn == t0 ? r0 * dec1 / r1 : r1 * dec0 / r0;
        a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function getSample(address tokenIn, address tokenOut, bool stable) external view returns (uint) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample = tokenIn == t0 ? r0 * dec1 / r1 : r1 * dec0 / r0;
        return _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
    }

    function getMinimumValue(address tokenIn, address tokenOut, bool stable) external view returns (uint, uint, uint) {
        (uint dec0, uint dec1, uint r0, uint r1,, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample = tokenIn == t0 ? r0 * dec1 / r1 : r1 * dec0 / r0;
        return (sample, r0, r1);
    }

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        return _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function _getAmountOut(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1, address token0, uint decimals0, uint decimals1, bool stable) internal pure returns (uint) {
        if (stable) {
            uint xy = _k(_reserve0, _reserve1, stable, decimals0, decimals1);
            _reserve0 = _reserve0 * 1e18 / decimals0;
            _reserve1 = _reserve1 * 1e18 / decimals1;
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn = tokenIn == token0 ? amountIn * 1e18 / decimals0 : amountIn * 1e18 / decimals1;
            uint y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
            return y * (tokenIn == token0 ? decimals1 : decimals0) / 1e18;
        } else {
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            return amountIn * reserveB / (reserveA + amountIn);
        }
    }

    function _k(uint x, uint y, bool stable, uint decimals0, uint decimals1) internal pure returns (uint) {
        if (stable) {
            uint _x = x * 1e18 / decimals0;
            uint _y = y * 1e18 / decimals1;
            uint _a = (_x * _y) / 1e18;
            uint _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return _a * _b / 1e18;
            // x3y+y3x >= k
        } else {
            return x * y;
            // xy >= k
        }
    }

    function getNormalizedReserves(address tokenA, address tokenB, bool stable) external view returns (uint reserveA, uint reserveB){
        address pair = pairFor(tokenA, tokenB, stable);
        if (pair == address(0)) {
            return (0, 0);
        }
        (uint decimals0, uint decimals1, uint reserve0, uint reserve1,, address t0, address t1) = IPair(pair).metadata();

        reserveA = tokenA == t0 ? reserve0 : reserve1;
        reserveB = tokenA == t1 ? reserve0 : reserve1;
        uint decimalsA = tokenA == t0 ? decimals0 : decimals1;
        uint decimalsB = tokenA == t1 ? decimals0 : decimals1;
        reserveA = reserveA * 1e18 / decimalsA;
        reserveB = reserveB * 1e18 / decimalsB;
    }

    /// @dev Calculates the CREATE2 address for a pair without making any external calls.
    function pairFor(address tokenA, address tokenB, bool stable) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1, stable)),
                pairCodeHash // init code hash
            )))));
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../interface/IFactory.sol";
import "./FldxPair.sol";

contract FldxFactory is IFactory {

  bool public override isPaused;
  address public admin;
  address public pendingAdmin;
  address public partnerSetter;
  address public immutable override treasury;

  uint256 public stableFee;
  uint256 public volatileFee;
  uint256 public constant treasuryFee = 10;
  uint256 public constant partnerFee = 3;

  /// @dev 0.4% max volatile swap fees
  uint internal constant MAX_VOLATILE_SWAP_FEE = 40;
  /// @dev 0.1% max stable swap fee
  uint internal constant MAX_STABLE_SWAP_FEE = 10;

  mapping(address => mapping(address => mapping(bool => address))) public override getPair;
  address[] public allPairs;
  /// @dev Simplified check if its a pair, given that `stable` flag might not be available in peripherals
  mapping(address => bool) public override isPair;

  address internal _temp0;
  address internal _temp1;
  bool internal _temp;

  event PairCreated(
    address indexed token0,
    address indexed token1,
    bool stable,
    address pair,
    uint allPairsLength
  );

  constructor(address _treasury) {
    admin = msg.sender;
    isPaused = false;
    treasury = _treasury;
    partnerSetter = msg.sender;
    stableFee = 2;
    volatileFee = 20;
  }

  function allPairsLength() external view returns (uint) {
    return allPairs.length;
  }

  function setAdmin(address _admin) external {
    require(msg.sender == admin, "FldxFactory: Not Admin");
    pendingAdmin = _admin;
  }

  function acceptAdmin() external {
    require(msg.sender == pendingAdmin, "FldxFactory: Not pending admin");
    admin = pendingAdmin;
  }

  function setPartnerSetter(address _partnerSetter) external {
    require(msg.sender == admin, "FldxFactory: Not admin");
    partnerSetter = _partnerSetter;
  }

  function setPause(bool _state) external {
    require(msg.sender == admin, "FldxFactory: Not admin");
    isPaused = _state;
  }

  function setFee(bool _stable, uint256 _fee) external {
    require(msg.sender == admin, 'not admin');
    require(_fee != 0, 'fee must be nonzero');

    if (_stable) {
      require(_fee <= MAX_STABLE_SWAP_FEE, 'fee too high');
      stableFee = _fee;
    } else {
      require(_fee <= MAX_VOLATILE_SWAP_FEE, 'fee too high');
      volatileFee = _fee;
    }
  }

  function getFees(bool _stable) external view returns (uint) {
    if (_stable) {
      return stableFee;
    } else {
      return volatileFee;
    }
  }

  function pairCodeHash() external pure override returns (bytes32) {
    return keccak256(type(FldxPair).creationCode);
  }

  function getInitializable() external view override returns (address, address, bool) {
    return (_temp0, _temp1, _temp);
  }

  function createPair(address tokenA, address tokenB, bool stable)
  external override returns (address pair) {
    require(tokenA != tokenB, 'FldxFactory: IDENTICAL_ADDRESSES');
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'FldxFactory: ZERO_ADDRESS');
    require(getPair[token0][token1][stable] == address(0), 'FldxFactory: PAIR_EXISTS');
    // notice salt includes stable as well, 3 parameters
    bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable));
    (_temp0, _temp1, _temp) = (token0, token1, stable);
    pair = address(new FldxPair{salt : salt}());
    getPair[token0][token1][stable] = pair;
    // populate mapping in the reverse direction
    getPair[token1][token0][stable] = pair;
    allPairs.push(pair);
    isPair[pair] = true;
    emit PairCreated(token0, token1, stable, pair, allPairs.length);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../interface/IERC20.sol";
import "../../interface/IERC721Metadata.sol";
import "../../interface/IPair.sol";
import "../../interface/IFactory.sol";
import "../../interface/ICallee.sol";
import "../../interface/IUnderlying.sol";
import "./PairFees.sol";
import "../../lib/Math.sol";
import "../../lib/SafeERC20.sol";
import "../Reentrancy.sol";

// The base pair of pools, either stable or volatile
contract FldxPair is IERC20, IPair, Reentrancy {
  using SafeERC20 for IERC20;

  string public name;
  string public symbol;
  uint8 public constant decimals = 18;

  /// @dev Used to denote stable or volatile pair
  bool public immutable stable;

  uint public override totalSupply = 0;

  mapping(address => mapping(address => uint)) public override allowance;
  mapping(address => uint) public override balanceOf;

  bytes32 public immutable DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  uint internal constant _FEE_PRECISION = 1e32;
  mapping(address => uint) public nonces;
  uint public immutable chainId;

  uint internal constant MINIMUM_LIQUIDITY = 10 ** 3;
  /// @dev Capture oracle reading every 30 minutes
  uint internal constant PERIOD_SIZE = 1800;

  address public immutable override token0;
  address public immutable override token1;
  address public immutable fees;
  address public immutable factory;
  address public immutable treasury;
  address public partner;

  Observation[] public observations;

  uint internal immutable decimals0;
  uint internal immutable decimals1;

  uint public reserve0;
  uint public reserve1;
  uint public blockTimestampLast;

  uint public reserve0CumulativeLast;
  uint public reserve1CumulativeLast;

  // index0 and index1 are used to accumulate fees,
  // this is split out from normal trades to keep the swap "clean"
  // this further allows LP holders to easily claim fees for tokens they have/staked
  uint public index0 = 0;
  uint public index1 = 0;

  // position assigned to each LP to track their current index0 & index1 vs the global position
  mapping(address => uint) public supplyIndex0;
  mapping(address => uint) public supplyIndex1;

  // tracks the amount of unclaimed, but claimable tokens off of fees for token0 and token1
  mapping(address => uint) public claimable0;
  mapping(address => uint) public claimable1;

  event Treasury(address indexed sender, uint amount0, uint amount1);
  event Fees(address indexed sender, uint amount0, uint amount1);
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
  event Sync(uint reserve0, uint reserve1);
  event Claim(address indexed sender, address indexed recipient, uint amount0, uint amount1);

  constructor() {
    factory = msg.sender;
    treasury = IFactory(msg.sender).treasury();
    partner = treasury;
    (address _token0, address _token1, bool _stable) = IFactory(msg.sender).getInitializable();
    (token0, token1, stable) = (_token0, _token1, _stable);
    fees = address(new PairFees(_token0, _token1));
    if (_stable) {
      name = string(abi.encodePacked("StableV1 AMM - ", IERC721Metadata(_token0).symbol(), "/", IERC721Metadata(_token1).symbol()));
      symbol = string(abi.encodePacked("sAMM-", IERC721Metadata(_token0).symbol(), "/", IERC721Metadata(_token1).symbol()));
    } else {
      name = string(abi.encodePacked("VolatileV1 AMM - ", IERC721Metadata(_token0).symbol(), "/", IERC721Metadata(_token1).symbol()));
      symbol = string(abi.encodePacked("vAMM-", IERC721Metadata(_token0).symbol(), "/", IERC721Metadata(_token1).symbol()));
    }

    decimals0 = 10 ** IUnderlying(_token0).decimals();
    decimals1 = 10 ** IUnderlying(_token1).decimals();

    observations.push(Observation(block.timestamp, 0, 0));

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(name)),
        keccak256('1'),
        block.chainid,
        address(this)
      )
    );
    chainId = block.chainid;
  }

  function setPartner(address _partner) external {
    require(msg.sender == IFactory(factory).partnerSetter(), 'not partnerSetter');
    partner = _partner;
  }

  function observationLength() external view returns (uint) {
    return observations.length;
  }

  function lastObservation() public view returns (Observation memory) {
    return observations[observations.length - 1];
  }

  function metadata() external view returns (
    uint dec0,
    uint dec1,
    uint r0,
    uint r1,
    bool st,
    address t0,
    address t1
  ) {
    return (decimals0, decimals1, reserve0, reserve1, stable, token0, token1);
  }

  function tokens() external view override returns (address, address) {
    return (token0, token1);
  }

  /// @dev Claim accumulated but unclaimed fees (viewable via claimable0 and claimable1)
  function claimFees() external override returns (uint claimed0, uint claimed1) {
    _updateFor(msg.sender);

    claimed0 = claimable0[msg.sender];
    claimed1 = claimable1[msg.sender];

    if (claimed0 > 0 || claimed1 > 0) {
      claimable0[msg.sender] = 0;
      claimable1[msg.sender] = 0;

      PairFees(fees).claimFeesFor(msg.sender, claimed0, claimed1);

      emit Claim(msg.sender, msg.sender, claimed0, claimed1);
    }
  }

  /// @dev Accrue fees on token0
  function _update0(uint amount) internal {
    uint toTreasury = (amount * IFactory(factory).treasuryFee()) / 100;
    uint toPartner = (amount * IFactory(factory).partnerFee()) / 100;
    uint toFees = amount - toTreasury - toPartner;

    // transfer the fees out to PairFees and Treasury
    IERC20(token0).safeTransfer(treasury, toTreasury);
    IERC20(token0).safeTransfer(partner, toPartner);
    IERC20(token0).safeTransfer(fees, toFees);
    // 1e32 adjustment is removed during claim
    uint _ratio = toFees * _FEE_PRECISION / totalSupply;
    if (_ratio > 0) {
      index0 += _ratio;
    }
    // keep the same structure of events for compatability
    emit Treasury(msg.sender, toTreasury, 0);
    emit Fees(msg.sender, toFees, 0);
  }

  /// @dev Accrue fees on token1
  function _update1(uint amount) internal {
    uint toTreasury = (amount * IFactory(factory).treasuryFee()) / 100;
    uint toPartner = (amount * IFactory(factory).partnerFee()) / 100;
    uint toFees = amount - toTreasury - toPartner;

    IERC20(token1).safeTransfer(treasury, toTreasury);
    IERC20(token1).safeTransfer(partner, toPartner);
    IERC20(token1).safeTransfer(fees, toFees);
    uint _ratio = toFees * _FEE_PRECISION / totalSupply;
    if (_ratio > 0) {
      index1 += _ratio;
    }
    // keep the same structure of events for compatability
    emit Treasury(msg.sender, 0, toTreasury);
    emit Fees(msg.sender, 0, toFees);
  }

  /// @dev This function MUST be called on any balance changes,
  ///      otherwise can be used to infinitely claim fees
  //       Fees are segregated from core funds, so fees can never put liquidity at risk
  function _updateFor(address recipient) internal {
    uint _supplied = balanceOf[recipient];
    // get LP balance of `recipient`
    if (_supplied > 0) {
      uint _supplyIndex0 = supplyIndex0[recipient];
      // get last adjusted index0 for recipient
      uint _supplyIndex1 = supplyIndex1[recipient];
      uint _index0 = index0;
      // get global index0 for accumulated fees
      uint _index1 = index1;
      supplyIndex0[recipient] = _index0;
      // update user current position to global position
      supplyIndex1[recipient] = _index1;
      uint _delta0 = _index0 - _supplyIndex0;
      // see if there is any difference that need to be accrued
      uint _delta1 = _index1 - _supplyIndex1;
      if (_delta0 > 0) {
        uint _share = _supplied * _delta0 / _FEE_PRECISION;
        // add accrued difference for each supplied token
        claimable0[recipient] += _share;
      }
      if (_delta1 > 0) {
        uint _share = _supplied * _delta1 / _FEE_PRECISION;
        claimable1[recipient] += _share;
      }
    } else {
      supplyIndex0[recipient] = index0;
      // new users are set to the default global state
      supplyIndex1[recipient] = index1;
    }
  }

  function getReserves() public view override returns (
    uint112 _reserve0,
    uint112 _reserve1,
    uint32 _blockTimestampLast
  ) {
    _reserve0 = uint112(reserve0);
    _reserve1 = uint112(reserve1);
    _blockTimestampLast = uint32(blockTimestampLast);
  }

  /// @dev Update reserves and, on the first call per block, price accumulators
  function _update(uint balance0, uint balance1, uint _reserve0, uint _reserve1) internal {
    uint blockTimestamp = block.timestamp;
    uint timeElapsed = blockTimestamp - blockTimestampLast;
    // overflow is desired
    if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
    unchecked {
      reserve0CumulativeLast += _reserve0 * timeElapsed;
      reserve1CumulativeLast += _reserve1 * timeElapsed;
    }
    }

    Observation memory _point = lastObservation();
    timeElapsed = blockTimestamp - _point.timestamp;
    // compare the last observation with current timestamp,
    // if greater than 30 minutes, record a new event
    if (timeElapsed > PERIOD_SIZE) {
      observations.push(Observation(blockTimestamp, reserve0CumulativeLast, reserve1CumulativeLast));
    }
    reserve0 = balance0;
    reserve1 = balance1;
    blockTimestampLast = blockTimestamp;
    emit Sync(reserve0, reserve1);
  }

  /// @dev Produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
  function currentCumulativePrices() public view returns (
    uint reserve0Cumulative,
    uint reserve1Cumulative,
    uint blockTimestamp
  ) {
    blockTimestamp = block.timestamp;
    reserve0Cumulative = reserve0CumulativeLast;
    reserve1Cumulative = reserve1CumulativeLast;

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (uint _reserve0, uint _reserve1, uint _blockTimestampLast) = getReserves();
    if (_blockTimestampLast != blockTimestamp) {
      // subtraction overflow is desired
      uint timeElapsed = blockTimestamp - _blockTimestampLast;
    unchecked {
      reserve0Cumulative += _reserve0 * timeElapsed;
      reserve1Cumulative += _reserve1 * timeElapsed;
    }
    }
  }

  /// @dev Gives the current twap price measured from amountIn * tokenIn gives amountOut
  function current(address tokenIn, uint amountIn) external view returns (uint amountOut) {
    Observation memory _observation = lastObservation();
    (uint reserve0Cumulative, uint reserve1Cumulative,) = currentCumulativePrices();
    if (block.timestamp == _observation.timestamp) {
      _observation = observations[observations.length - 2];
    }

    uint timeElapsed = block.timestamp - _observation.timestamp;
    uint _reserve0 = (reserve0Cumulative - _observation.reserve0Cumulative) / timeElapsed;
    uint _reserve1 = (reserve1Cumulative - _observation.reserve1Cumulative) / timeElapsed;
    amountOut = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
  }

  /// @dev As per `current`, however allows user configured granularity, up to the full window size
  function quote(address tokenIn, uint amountIn, uint granularity)
  external view returns (uint amountOut) {
    uint [] memory _prices = sample(tokenIn, amountIn, granularity, 1);
    uint priceAverageCumulative;
    for (uint i = 0; i < _prices.length; i++) {
      priceAverageCumulative += _prices[i];
    }
    return priceAverageCumulative / granularity;
  }

  /// @dev Returns a memory set of twap prices
  function prices(address tokenIn, uint amountIn, uint points)
  external view returns (uint[] memory) {
    return sample(tokenIn, amountIn, points, 1);
  }

  function sample(address tokenIn, uint amountIn, uint points, uint window)
  public view returns (uint[] memory) {
    uint[] memory _prices = new uint[](points);

    uint length = observations.length - 1;
    uint i = length - (points * window);
    uint nextIndex = 0;
    uint index = 0;

    for (; i < length; i += window) {
      nextIndex = i + window;
      uint timeElapsed = observations[nextIndex].timestamp - observations[i].timestamp;
      uint _reserve0 = (observations[nextIndex].reserve0Cumulative - observations[i].reserve0Cumulative) / timeElapsed;
      uint _reserve1 = (observations[nextIndex].reserve1Cumulative - observations[i].reserve1Cumulative) / timeElapsed;
      _prices[index] = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
      index = index + 1;
    }
    return _prices;
  }

  /// @dev This low-level function should be called from a contract which performs important safety checks
  ///      standard uniswap v2 implementation
  function mint(address to) external lock override returns (uint liquidity) {
    (uint _reserve0, uint _reserve1) = (reserve0, reserve1);
    uint _balance0 = IERC20(token0).balanceOf(address(this));
    uint _balance1 = IERC20(token1).balanceOf(address(this));
    uint _amount0 = _balance0 - _reserve0;
    uint _amount1 = _balance1 - _reserve1;

    uint _totalSupply = totalSupply;
    // gas savings, must be defined here since totalSupply can update in _mintFee
    if (_totalSupply == 0) {
      liquidity = Math.sqrt(_amount0 * _amount1) - MINIMUM_LIQUIDITY;
      // permanently lock the first MINIMUM_LIQUIDITY tokens
      _mint(address(0), MINIMUM_LIQUIDITY);
    } else {
      liquidity = Math.min(_amount0 * _totalSupply / _reserve0, _amount1 * _totalSupply / _reserve1);
    }
    require(liquidity > 0, 'FldxPair: INSUFFICIENT_LIQUIDITY_MINTED');
    _mint(to, liquidity);

    _update(_balance0, _balance1, _reserve0, _reserve1);
    emit Mint(msg.sender, _amount0, _amount1);
  }

  /// @dev This low-level function should be called from a contract which performs important safety checks
  ///      standard uniswap v2 implementation
  function burn(address to) external lock override returns (uint amount0, uint amount1) {
    (uint _reserve0, uint _reserve1) = (reserve0, reserve1);
    (address _token0, address _token1) = (token0, token1);
    uint _balance0 = IERC20(_token0).balanceOf(address(this));
    uint _balance1 = IERC20(_token1).balanceOf(address(this));
    uint _liquidity = balanceOf[address(this)];

    // gas savings, must be defined here since totalSupply can update in _mintFee
    uint _totalSupply = totalSupply;
    // using balances ensures pro-rata distribution
    amount0 = _liquidity * _balance0 / _totalSupply;
    // using balances ensures pro-rata distribution
    amount1 = _liquidity * _balance1 / _totalSupply;
    require(amount0 > 0 && amount1 > 0, 'FldxPair: INSUFFICIENT_LIQUIDITY_BURNED');
    _burn(address(this), _liquidity);
    IERC20(_token0).safeTransfer(to, amount0);
    IERC20(_token1).safeTransfer(to, amount1);
    _balance0 = IERC20(_token0).balanceOf(address(this));
    _balance1 = IERC20(_token1).balanceOf(address(this));

    _update(_balance0, _balance1, _reserve0, _reserve1);
    emit Burn(msg.sender, amount0, amount1, to);
  }

  /// @dev This low-level function should be called from a contract which performs important safety checks
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external override lock {
    require(!IFactory(factory).isPaused(), "FldxPair: PAUSE");
    require(amount0Out > 0 || amount1Out > 0, 'FldxPair: INSUFFICIENT_OUTPUT_AMOUNT');
    (uint _reserve0, uint _reserve1) = (reserve0, reserve1);
    require(amount0Out < _reserve0 && amount1Out < _reserve1, 'FldxPair: INSUFFICIENT_LIQUIDITY');
    uint _balance0;
    uint _balance1;
    {// scope for _token{0,1}, avoids stack too deep errors
      (address _token0, address _token1) = (token0, token1);
      require(to != _token0 && to != _token1, 'FldxPair: INVALID_TO');
      // optimistically transfer tokens
      if (amount0Out > 0) IERC20(_token0).safeTransfer(to, amount0Out);
      // optimistically transfer tokens
      if (amount1Out > 0) IERC20(_token1).safeTransfer(to, amount1Out);
      // callback, used for flash loans
      if (data.length > 0) ICallee(to).hook(msg.sender, amount0Out, amount1Out, data);
      _balance0 = IERC20(_token0).balanceOf(address(this));
      _balance1 = IERC20(_token1).balanceOf(address(this));
    }
    uint amount0In = _balance0 > _reserve0 - amount0Out ? _balance0 - (_reserve0 - amount0Out) : 0;
    uint amount1In = _balance1 > _reserve1 - amount1Out ? _balance1 - (_reserve1 - amount1Out) : 0;
    require(amount0In > 0 || amount1In > 0, 'FldxPair: INSUFFICIENT_INPUT_AMOUNT');
    {// scope for reserve{0,1}Adjusted, avoids stack too deep errors
      (address _token0, address _token1) = (token0, token1);
      // accrue fees for token0 and move them out of pool
      if (amount0In > 0) _update0(amount0In * getFee() / 10000);
      // accrue fees for token1 and move them out of pool
      if (amount1In > 0) _update1(amount1In * getFee() / 10000);
      // since we removed tokens, we need to reconfirm balances,
      // can also simply use previous balance - amountIn/ SWAP_FEE,
      // but doing balanceOf again as safety check
      _balance0 = IERC20(_token0).balanceOf(address(this));
      _balance1 = IERC20(_token1).balanceOf(address(this));
      // The curve, either x3y+y3x for stable pools, or x*y for volatile pools
      require(_k(_balance0, _balance1) >= _k(_reserve0, _reserve1), 'FldxPair: K');
    }

    _update(_balance0, _balance1, _reserve0, _reserve1);
    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
  }

  function getFee() public view returns (uint) {
      return IFactory(factory).getFees(stable);
  }

  /// @dev Force balances to match reserves
  function skim(address to) external lock {
    (address _token0, address _token1) = (token0, token1);
    IERC20(_token0).safeTransfer(to, IERC20(_token0).balanceOf(address(this)) - (reserve0));
    IERC20(_token1).safeTransfer(to, IERC20(_token1).balanceOf(address(this)) - (reserve1));
  }

  // force reserves to match balances
  function sync() external lock {
    _update(
      IERC20(token0).balanceOf(address(this)),
      IERC20(token1).balanceOf(address(this)),
      reserve0,
      reserve1
    );
  }

  function _f(uint x0, uint y) internal pure returns (uint) {
    return x0 * (y * y / 1e18 * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18) * y / 1e18;
  }

  function _d(uint x0, uint y) internal pure returns (uint) {
    return 3 * x0 * (y * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18);
  }

  function _getY(uint x0, uint xy, uint y) internal pure returns (uint) {
    for (uint i = 0; i < 255; i++) {
      uint yPrev = y;
      uint k = _f(x0, y);
      if (k < xy) {
        uint dy = (xy - k) * 1e18 / _d(x0, y);
        y = y + dy;
      } else {
        uint dy = (k - xy) * 1e18 / _d(x0, y);
        y = y - dy;
      }
      if (Math.closeTo(y, yPrev, 1)) {
        break;
      }
    }
    return y;
  }

  function getAmountOut(uint amountIn, address tokenIn) external view override returns (uint) {
    (uint _reserve0, uint _reserve1) = (reserve0, reserve1);
    // remove fee from amount received
    amountIn -= amountIn * getFee() / 10000;
    return _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
  }

  function _getAmountOut(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1) internal view returns (uint) {
    if (stable) {
      uint xy = _k(_reserve0, _reserve1);
      _reserve0 = _reserve0 * 1e18 / decimals0;
      _reserve1 = _reserve1 * 1e18 / decimals1;
      (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
      amountIn = tokenIn == token0 ? amountIn * 1e18 / decimals0 : amountIn * 1e18 / decimals1;
      uint y = reserveB - _getY(amountIn + reserveA, xy, reserveB);
      return y * (tokenIn == token0 ? decimals1 : decimals0) / 1e18;
    } else {
      (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
      return amountIn * reserveB / (reserveA + amountIn);
    }
  }

  function _k(uint x, uint y) internal view returns (uint) {
    if (stable) {
      uint _x = x * 1e18 / decimals0;
      uint _y = y * 1e18 / decimals1;
      uint _a = (_x * _y) / 1e18;
      uint _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
      // x3y+y3x >= k
      return _a * _b / 1e18;
    } else {
      // xy >= k
      return x * y;
    }
  }

  //****************************************************************************
  //**************************** ERC20 *****************************************
  //****************************************************************************

  function _mint(address dst, uint amount) internal {
    // balances must be updated on mint/burn/transfer
    _updateFor(dst);
    totalSupply += amount;
    balanceOf[dst] += amount;
    emit Transfer(address(0), dst, amount);
  }

  function _burn(address dst, uint amount) internal {
    _updateFor(dst);
    totalSupply -= amount;
    balanceOf[dst] -= amount;
    emit Transfer(dst, address(0), amount);
  }

  function approve(address spender, uint amount) external override returns (bool) {
    require(spender != address(0), "FldxPair: Approve to the zero address");
    allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    require(deadline >= block.timestamp, 'FldxPair: EXPIRED');
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
      )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, 'FldxPair: INVALID_SIGNATURE');
    allowance[owner][spender] = value;

    emit Approval(owner, spender, value);
  }

  function transfer(address dst, uint amount) external override returns (bool) {
    _transferTokens(msg.sender, dst, amount);
    return true;
  }

  function transferFrom(address src, address dst, uint amount) external override returns (bool) {
    address spender = msg.sender;
    uint spenderAllowance = allowance[src][spender];

    if (spender != src && spenderAllowance != type(uint).max) {
      require(spenderAllowance >= amount, "FldxPair: Insufficient allowance");
    unchecked {
      uint newAllowance = spenderAllowance - amount;
      allowance[src][spender] = newAllowance;
      emit Approval(src, spender, newAllowance);
    }
    }

    _transferTokens(src, dst, amount);
    return true;
  }

  function _transferTokens(address src, address dst, uint amount) internal {
    require(dst != address(0), "FldxPair: Transfer to the zero address");

    // update fee position for src
    _updateFor(src);
    // update fee position for dst
    _updateFor(dst);

    uint srcBalance = balanceOf[src];
    require(srcBalance >= amount, "FldxPair: Transfer amount exceeds balance");
  unchecked {
    balanceOf[src] = srcBalance - amount;
  }

    balanceOf[dst] += amount;

    emit Transfer(src, dst, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../interface/IERC20.sol";
import "../../lib/SafeERC20.sol";

contract GovernanceTreasury {
  using SafeERC20 for IERC20;

  address public owner;
  address public pendingOwner;

  event Claimed(address receipent, address token, uint amount);

  constructor() {
    owner = msg.sender;
  }

  function setOwner(address _owner) external {
    require(msg.sender == owner, "Not owner");
    pendingOwner = _owner;
  }

  function acceptOwner() external {
    require(msg.sender == pendingOwner, "Not pending owner");
    owner = pendingOwner;
  }

  function claim(address[] memory tokens) external {
    require(msg.sender == owner, "Not owner");
    for (uint i; i < tokens.length; i++) {
      address token = tokens[i];
      uint balance = IERC20(token).balanceOf(address(this));
      require(balance != 0, "Zero balance");
      IERC20(token).safeTransfer(msg.sender, balance);
      emit Claimed(msg.sender, token, balance);
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../interface/IERC20.sol";
import "../../lib/SafeERC20.sol";

/// @title Base V1 Fees contract is used as a 1:1 pair relationship to split out fees,
///        this ensures that the curve does not need to be modified for LP shares
contract PairFees {
  using SafeERC20 for IERC20;

  /// @dev The pair it is bonded to
  address internal immutable pair;
  /// @dev Token0 of pair, saved localy and statically for gas optimization
  address internal immutable token0;
  /// @dev Token1 of pair, saved localy and statically for gas optimization
  address internal immutable token1;

  constructor(address _token0, address _token1) {
    pair = msg.sender;
    token0 = _token0;
    token1 = _token1;
  }

  // Allow the pair to transfer fees to users
  function claimFeesFor(address recipient, uint amount0, uint amount1) external {
    require(msg.sender == pair, "Not pair");
    if (amount0 > 0) {
      IERC20(token0).safeTransfer(recipient, amount0);
    }
    if (amount1 > 0) {
      IERC20(token1).safeTransfer(recipient, amount1);
    }
  }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/// ============ Imports ============

import {IFLDX} from "../../interface/IFLDX.sol";
import {MerkleProof} from "./MerkleProof.sol";


/// @title MerkleClaim
/// @notice Claims FLDX for members of a merkle tree
/// @author Modified from Merkle Airdrop Starter (https://github.com/Anish-Agnihotri/merkle-airdrop-starter/blob/master/contracts/src/MerkleClaimERC20.sol)
contract MerkleClaim {
    /// ============ Immutable storage ============
    IFLDX public immutable fldx;
    bytes32 public immutable merkleRoot;

    /// ============ Mutable storage ============

    /// @notice Mapping of addresses who have claimed tokens
    mapping(address => bool) public hasClaimed;
    address internal admin;
    bool public claimEnabled;

    /// ============ Constructor ============

    /// @notice Creates a new MerkleClaim contract
    /// @param _fldx address
    /// @param _merkleRoot of claimees
    constructor(address _fldx, bytes32 _merkleRoot) {
        fldx = IFLDX(_fldx);
        merkleRoot = _merkleRoot;
        admin = msg.sender;
    }

    /// ============ Events ============

    /// @notice Emitted after a successful token claim
    /// @param to recipient of claim
    /// @param amount of tokens claimed
    event Claim(address indexed to, uint256 amount);

    /// ============ Functions ============

    function setClaimEnabled() external {
        require(msg.sender == admin, 'NOT_ADMIN');
        claimEnabled = true;
        admin = address(0);
    }

    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param to address of claimee
    /// @param amount of tokens owed to claimee
    /// @param proof merkle proof to prove address and amount are in tree
    function claim(
        address to,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        require(claimEnabled == true, 'CLAIM_NOT_ENABLED');
        // Throw if address has already claimed tokens
        require(!hasClaimed[to], "ALREADY_CLAIMED");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        require(isValidLeaf, "NOT_IN_MERKLE");

        // Set address to claimed
        hasClaimed[to] = true;

        // Claim tokens for address
        require(fldx.claim(to, amount), "CLAIM_FAILED");

        // Emit claim event
        emit Claim(to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity 0.8.13;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
            ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
            : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
        unchecked {
            return hashes[totalHashes - 1];
        }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
            ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
            : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
        unchecked {
            return hashes[totalHashes - 1];
        }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/// ============ Imports ============

import {IFLDX} from "../../interface/IFLDX.sol";
import {IVe} from "../../interface/IVe.sol";
import {MerkleProof} from "./MerkleProof.sol";


/// @title MerkleClaim
/// @notice Claims FLDX for members of a merkle tree
/// @author Modified from Merkle Airdrop Starter (https://github.com/Anish-Agnihotri/merkle-airdrop-starter/blob/master/contracts/src/MerkleClaimERC20.sol)
contract MerkleVeNFTClaim {
    /// ============ Immutable storage ============
    IFLDX public immutable fldx;
    IVe public immutable ve;
    bytes32 public immutable merkleRoot;

    /// ============ Mutable storage ============

    /// @notice Mapping of addresses who have claimed tokens
    mapping(address => bool) public hasClaimed;
    address internal admin;
    bool public claimEnabled;

    /// ============ Constructor ============

    /// @notice Creates a new MerkleClaim contract
    /// @param _fldx address
    /// @param _merkleRoot of claimees
    constructor(address _fldx, address _ve, bytes32 _merkleRoot) {
        fldx = IFLDX(_fldx);
        merkleRoot = _merkleRoot;
        ve = IVe(_ve);
        admin = msg.sender;
    }

    /// ============ Functions ============

    function setClaimEnabled() external {
        require(msg.sender == admin, 'NOT_ADMIN');
        claimEnabled = true;
        admin = address(0);
    }

    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param to address of claimee
    /// @param lockedAmount amount of lock owed to claimee
    /// @param lockedDuration duration of lock in seconds
    /// @param proof merkle proof to prove address and amount are in tree
    function claim(
        address to,
        uint256 lockedAmount,
        uint256 lockedDuration,
        bytes32[] calldata proof
    ) external {
        require(claimEnabled == true, 'CLAIM_NOT_ENABLED');
        // Throw if address has already claimed tokens
        require(!hasClaimed[to], "ALREADY_CLAIMED");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, lockedAmount, lockedDuration));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        require(isValidLeaf, "NOT_IN_MERKLE");

        // Set address to claimed
        hasClaimed[to] = true;

        // Claim veNFT
        fldx.claim(address(this), lockedAmount);
        fldx.approve(address(ve), type(uint).max);
        ve.createLockFor(lockedAmount, lockedDuration, to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../lib/Math.sol";
import "../../lib/SafeERC20.sol";
import "../../interface/IERC20.sol";
import "../../interface/IWAVAX.sol";
import "../../interface/IPair.sol";
import "../../interface/IFactory.sol";

contract FldxRouter01 {
  using SafeERC20 for IERC20;

  struct Route {
    address from;
    address to;
    bool stable;
  }

  address public immutable factory;
  IWAVAX public immutable wavax;
  uint internal constant MINIMUM_LIQUIDITY = 10 ** 3;
  bytes32 immutable pairCodeHash;

  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'FldxRouter: EXPIRED');
    _;
  }

  constructor(address _factory, address _wavax) {
    factory = _factory;
    pairCodeHash = IFactory(_factory).pairCodeHash();
    wavax = IWAVAX(_wavax);
  }

  receive() external payable {
    // only accept AVAX via fallback from the WAVAX contract
    require(msg.sender == address(wavax), "FldxRouter: NOT_WAVAX");
  }

  function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1) {
    return _sortTokens(tokenA, tokenB);
  }

  function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'FldxRouter: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'FldxRouter: ZERO_ADDRESS');
  }

  function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair) {
    return _pairFor(tokenA, tokenB, stable);
  }

  /// @dev Calculates the CREATE2 address for a pair without making any external calls.
  function _pairFor(address tokenA, address tokenB, bool stable) internal view returns (address pair) {
    (address token0, address token1) = _sortTokens(tokenA, tokenB);
    pair = address(uint160(uint(keccak256(abi.encodePacked(
        hex'ff',
        factory,
        keccak256(abi.encodePacked(token0, token1, stable)),
        pairCodeHash // init code hash
      )))));
  }

  function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB) {
    return _quoteLiquidity(amountA, reserveA, reserveB);
  }

  /// @dev Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset.
  function _quoteLiquidity(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(amountA > 0, 'FldxRouter: INSUFFICIENT_AMOUNT');
    require(reserveA > 0 && reserveB > 0, 'FldxRouter: INSUFFICIENT_LIQUIDITY');
    amountB = amountA * reserveB / reserveA;
  }

  function getReserves(address tokenA, address tokenB, bool stable) external view returns (uint reserveA, uint reserveB) {
    return _getReserves(tokenA, tokenB, stable);
  }

  /// @dev Fetches and sorts the reserves for a pair.
  function _getReserves(address tokenA, address tokenB, bool stable) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = _sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IPair(_pairFor(tokenA, tokenB, stable)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  /// @dev Performs chained getAmountOut calculations on any number of pairs.
  function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable) {
    address pair = _pairFor(tokenIn, tokenOut, true);
    uint amountStable;
    uint amountVolatile;
    if (IFactory(factory).isPair(pair)) {
      amountStable = IPair(pair).getAmountOut(amountIn, tokenIn);
    }
    pair = _pairFor(tokenIn, tokenOut, false);
    if (IFactory(factory).isPair(pair)) {
      amountVolatile = IPair(pair).getAmountOut(amountIn, tokenIn);
    }
    return amountStable > amountVolatile ? (amountStable, true) : (amountVolatile, false);
  }

  function getExactAmountOut(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint) {
    address pair = _pairFor(tokenIn, tokenOut, stable);
    if (IFactory(factory).isPair(pair)) {
      return IPair(pair).getAmountOut(amountIn, tokenIn);
    }
    return 0;
  }

  /// @dev Performs chained getAmountOut calculations on any number of pairs.
  function getAmountsOut(uint amountIn, Route[] memory routes) external view returns (uint[] memory amounts) {
    return _getAmountsOut(amountIn, routes);
  }

  function _getAmountsOut(uint amountIn, Route[] memory routes) internal view returns (uint[] memory amounts) {
    require(routes.length >= 1, 'FldxRouter: INVALID_PATH');
    amounts = new uint[](routes.length + 1);
    amounts[0] = amountIn;
    for (uint i = 0; i < routes.length; i++) {
      address pair = _pairFor(routes[i].from, routes[i].to, routes[i].stable);
      if (IFactory(factory).isPair(pair)) {
        amounts[i + 1] = IPair(pair).getAmountOut(amounts[i], routes[i].from);
      }
    }
  }

  function isPair(address pair) external view returns (bool) {
    return IFactory(factory).isPair(pair);
  }

  function quoteAddLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired
  ) external view returns (uint amountA, uint amountB, uint liquidity) {
    // create the pair if it doesn't exist yet
    address _pair = IFactory(factory).getPair(tokenA, tokenB, stable);
    (uint reserveA, uint reserveB) = (0, 0);
    uint _totalSupply = 0;
    if (_pair != address(0)) {
      _totalSupply = IERC20(_pair).totalSupply();
      (reserveA, reserveB) = _getReserves(tokenA, tokenB, stable);
    }
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
      liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
    } else {

      uint amountBOptimal = _quoteLiquidity(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        (amountA, amountB) = (amountADesired, amountBOptimal);
        liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
      } else {
        uint amountAOptimal = _quoteLiquidity(amountBDesired, reserveB, reserveA);
        (amountA, amountB) = (amountAOptimal, amountBDesired);
        liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
      }
    }
  }

  function quoteRemoveLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity
  ) external view returns (uint amountA, uint amountB) {
    // create the pair if it doesn't exist yet
    address _pair = IFactory(factory).getPair(tokenA, tokenB, stable);

    if (_pair == address(0)) {
      return (0, 0);
    }

    (uint reserveA, uint reserveB) = _getReserves(tokenA, tokenB, stable);
    uint _totalSupply = IERC20(_pair).totalSupply();
    // using balances ensures pro-rata distribution
    amountA = liquidity * reserveA / _totalSupply;
    // using balances ensures pro-rata distribution
    amountB = liquidity * reserveB / _totalSupply;

  }

  function _addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin
  ) internal returns (uint amountA, uint amountB) {
    require(amountADesired >= amountAMin, "FldxRouter: DESIRED_A_AMOUNT");
    require(amountBDesired >= amountBMin, "FldxRouter: DESIRED_B_AMOUNT");
    // create the pair if it doesn't exist yet
    address _pair = IFactory(factory).getPair(tokenA, tokenB, stable);
    if (_pair == address(0)) {
      _pair = IFactory(factory).createPair(tokenA, tokenB, stable);
    }
    (uint reserveA, uint reserveB) = _getReserves(tokenA, tokenB, stable);
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint amountBOptimal = _quoteLiquidity(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        require(amountBOptimal >= amountBMin, 'FldxRouter: INSUFFICIENT_B_AMOUNT');
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint amountAOptimal = _quoteLiquidity(amountBDesired, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        require(amountAOptimal >= amountAMin, 'FldxRouter: INSUFFICIENT_A_AMOUNT');
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
    (amountA, amountB) = _addLiquidity(
      tokenA,
      tokenB,
      stable,
      amountADesired,
      amountBDesired,
      amountAMin,
      amountBMin
    );
    address pair = _pairFor(tokenA, tokenB, stable);
    SafeERC20.safeTransferFrom(IERC20(tokenA), msg.sender, pair, amountA);
    SafeERC20.safeTransferFrom(IERC20(tokenB), msg.sender, pair, amountB);
    liquidity = IPair(pair).mint(to);
  }

  function addLiquidityAVAX(
    address token,
    bool stable,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountAVAXMin,
    address to,
    uint deadline
  ) external payable ensure(deadline) returns (uint amountToken, uint amountAVAX, uint liquidity) {
    (amountToken, amountAVAX) = _addLiquidity(
      token,
      address(wavax),
      stable,
      amountTokenDesired,
      msg.value,
      amountTokenMin,
      amountAVAXMin
    );
    address pair = _pairFor(token, address(wavax), stable);
    IERC20(token).safeTransferFrom(msg.sender, pair, amountToken);
    wavax.deposit{value : amountAVAX}();
    assert(wavax.transfer(pair, amountAVAX));
    liquidity = IPair(pair).mint(to);
    // refund dust avax, if any
    if (msg.value > amountAVAX) _safeTransferAVAX(msg.sender, msg.value - amountAVAX);
  }

  // **** REMOVE LIQUIDITY ****

  function removeLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB) {
    return _removeLiquidity(
      tokenA,
      tokenB,
      stable,
      liquidity,
      amountAMin,
      amountBMin,
      to,
      deadline
    );
  }

  function _removeLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) internal ensure(deadline) returns (uint amountA, uint amountB) {
    address pair = _pairFor(tokenA, tokenB, stable);
    IERC20(pair).safeTransferFrom(msg.sender, pair, liquidity);
    // send liquidity to pair
    (uint amount0, uint amount1) = IPair(pair).burn(to);
    (address token0,) = _sortTokens(tokenA, tokenB);
    (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    require(amountA >= amountAMin, 'FldxRouter: INSUFFICIENT_A_AMOUNT');
    require(amountB >= amountBMin, 'FldxRouter: INSUFFICIENT_B_AMOUNT');
  }

  function removeLiquidityAVAX(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountAVAXMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountAVAX) {
    return _removeLiquidityAVAX(
      token,
      stable,
      liquidity,
      amountTokenMin,
      amountAVAXMin,
      to,
      deadline
    );
  }

  function _removeLiquidityAVAX(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountAVAXMin,
    address to,
    uint deadline
  ) internal ensure(deadline) returns (uint amountToken, uint amountAVAX) {
    (amountToken, amountAVAX) = _removeLiquidity(
      token,
      address(wavax),
      stable,
      liquidity,
      amountTokenMin,
      amountAVAXMin,
      address(this),
      deadline
    );
    IERC20(token).safeTransfer(to, amountToken);
    wavax.withdraw(amountAVAX);
    _safeTransferAVAX(to, amountAVAX);
  }

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB) {
    address pair = _pairFor(tokenA, tokenB, stable);
    {
      uint value = approveMax ? type(uint).max : liquidity;
      IPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    (amountA, amountB) = _removeLiquidity(tokenA, tokenB, stable, liquidity, amountAMin, amountBMin, to, deadline);
  }

  function removeLiquidityAVAXWithPermit(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountAVAXMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountAVAX) {
    address pair = _pairFor(token, address(wavax), stable);
    uint value = approveMax ? type(uint).max : liquidity;
    IPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountToken, amountAVAX) = _removeLiquidityAVAX(token, stable, liquidity, amountTokenMin, amountAVAXMin, to, deadline);
  }

  function removeLiquidityAVAXSupportingFeeOnTransferTokens(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountAVAXMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountFTM) {
    return _removeLiquidityAVAXSupportingFeeOnTransferTokens(
      token,
      stable,
      liquidity,
      amountTokenMin,
      amountAVAXMin,
      to,
      deadline
    );
  }

  function _removeLiquidityAVAXSupportingFeeOnTransferTokens(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountAVAXMin,
    address to,
    uint deadline
  ) internal ensure(deadline) returns (uint amountToken, uint amountFTM) {
    (amountToken, amountFTM) = _removeLiquidity(
      token,
      address(wavax),
      stable,
      liquidity,
      amountTokenMin,
      amountAVAXMin,
      address(this),
      deadline
    );
    IERC20(token).safeTransfer(to, IERC20(token).balanceOf(address(this)));
    wavax.withdraw(amountFTM);
    _safeTransferAVAX(to, amountFTM);
  }

  function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountAVAXMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountFTM) {
    address pair = _pairFor(token, address(wavax), stable);
    uint value = approveMax ? type(uint).max : liquidity;
    IPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountToken, amountFTM) = _removeLiquidityAVAXSupportingFeeOnTransferTokens(
      token, stable, liquidity, amountTokenMin, amountAVAXMin, to, deadline
    );
  }

  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, Route[] memory routes, address _to) internal virtual {
    for (uint i = 0; i < routes.length; i++) {
      (address token0,) = _sortTokens(routes[i].from, routes[i].to);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = routes[i].from == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < routes.length - 1 ? _pairFor(routes[i + 1].from, routes[i + 1].to, routes[i + 1].stable) : _to;
      IPair(_pairFor(routes[i].from, routes[i].to, routes[i].stable)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  function _swapSupportingFeeOnTransferTokens(Route[] memory routes, address _to) internal virtual {
    for (uint i; i < routes.length; i++) {
      (address input, address output) = (routes[i].from, routes[i].to);
      (address token0,) = _sortTokens(input, output);
      IPair pair = IPair(_pairFor(routes[i].from, routes[i].to, routes[i].stable));
      uint amountInput;
      uint amountOutput;
      {// scope to avoid stack too deep errors
        (uint reserve0, uint reserve1,) = pair.getReserves();
        uint reserveInput = input == token0 ? reserve0 : reserve1;
        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        //(amountOutput,) = getAmountOut(amountInput, input, output, stable);
        amountOutput = pair.getAmountOut(amountInput, input);
      }
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
      address to = i < routes.length - 1 ? _pairFor(routes[i + 1].from, routes[i + 1].to, routes[i + 1].stable) : _to;
      pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokensSimple(
    uint amountIn,
    uint amountOutMin,
    address tokenFrom,
    address tokenTo,
    bool stable,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint[] memory amounts) {
    Route[] memory routes = new Route[](1);
    routes[0].from = tokenFrom;
    routes[0].to = tokenTo;
    routes[0].stable = stable;
    amounts = _getAmountsOut(amountIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, 'FldxRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    IERC20(routes[0].from).safeTransferFrom(
      msg.sender, _pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]
    );
    _swap(amounts, routes, to);
  }

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    Route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint[] memory amounts) {
    amounts = _getAmountsOut(amountIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, 'FldxRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    IERC20(routes[0].from).safeTransferFrom(
      msg.sender, _pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]
    );
    _swap(amounts, routes, to);
  }

  function swapExactAVAXForTokens(uint amountOutMin, Route[] calldata routes, address to, uint deadline)
  external
  payable
  ensure(deadline)
  returns (uint[] memory amounts)
  {
    require(routes[0].from == address(wavax), 'FldxRouter: INVALID_PATH');
    amounts = _getAmountsOut(msg.value, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, 'FldxRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    wavax.deposit{value : amounts[0]}();
    assert(wavax.transfer(_pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]));
    _swap(amounts, routes, to);
  }

  function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, Route[] calldata routes, address to, uint deadline)
  external
  ensure(deadline)
  returns (uint[] memory amounts)
  {
    require(routes[routes.length - 1].to == address(wavax), 'FldxRouter: INVALID_PATH');
    amounts = _getAmountsOut(amountIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, 'FldxRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    IERC20(routes[0].from).safeTransferFrom(
      msg.sender, _pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]
    );
    _swap(amounts, routes, address(this));
    wavax.withdraw(amounts[amounts.length - 1]);
    _safeTransferAVAX(to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    Route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) {
    IERC20(routes[0].from).safeTransferFrom(
      msg.sender,
      _pairFor(routes[0].from, routes[0].to, routes[0].stable),
      amountIn
    );
    uint balanceBefore = IERC20(routes[routes.length - 1].to).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(routes, to);
    require(
      IERC20(routes[routes.length - 1].to).balanceOf(to) - balanceBefore >= amountOutMin,
      'FldxRouter: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    Route[] calldata routes,
    address to,
    uint deadline
  )
  external
  payable
  ensure(deadline)
  {
    require(routes[0].from == address(wavax), 'FldxRouter: INVALID_PATH');
    uint amountIn = msg.value;
    wavax.deposit{value : amountIn}();
    assert(wavax.transfer(_pairFor(routes[0].from, routes[0].to, routes[0].stable), amountIn));
    uint balanceBefore = IERC20(routes[routes.length - 1].to).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(routes, to);
    require(
      IERC20(routes[routes.length - 1].to).balanceOf(to) - balanceBefore >= amountOutMin,
      'FldxRouter: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    Route[] calldata routes,
    address to,
    uint deadline
  )
  external
  ensure(deadline)
  {
    require(routes[routes.length - 1].to == address(wavax), 'FldxRouter: INVALID_PATH');
    IERC20(routes[0].from).safeTransferFrom(
      msg.sender, _pairFor(routes[0].from, routes[0].to, routes[0].stable), amountIn
    );
    _swapSupportingFeeOnTransferTokens(routes, address(this));
    uint amountOut = IERC20(address(wavax)).balanceOf(address(this));
    require(amountOut >= amountOutMin, 'FldxRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    wavax.withdraw(amountOut);
    _safeTransferAVAX(to, amountOut);
  }

  function UNSAFE_swapExactTokensForTokens(
    uint[] memory amounts,
    Route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint[] memory) {
    IERC20(routes[0].from).safeTransferFrom(msg.sender, _pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]);
    _swap(amounts, routes, to);
    return amounts;
  }

  function _safeTransferAVAX(address to, uint value) internal {
    (bool success,) = to.call{value : value}(new bytes(0));
    require(success, 'FldxRouter: AVAX_TRANSFER_FAILED');
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

abstract contract Reentrancy {

  /// @dev simple re-entrancy check
  uint internal _unlocked = 1;

  modifier lock() {
    require(_unlocked == 1, "Reentrant call");
    _unlocked = 2;
    _;
    _unlocked = 1;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../interface/IBribe.sol";
import "../../interface/IERC721.sol";
import "../../interface/IVoter.sol";
import "../../interface/IVe.sol";
import "./MultiRewardsPoolBase.sol";

/// @title Bribes pay out rewards for a given pool based on the votes
///        that were received from the user (goes hand in hand with Gauges.vote())
contract Bribe is IBribe, MultiRewardsPoolBase {

  /// @dev Only voter can modify balances (since it only happens on vote())
  address public immutable voter;
  address public immutable ve;

  // Assume that will be created from voter contract through factory
  constructor(
    address _voter,
    address[] memory _allowedRewardTokens
  ) MultiRewardsPoolBase(address(0), _voter, _allowedRewardTokens) {
    voter = _voter;
    ve = IVoter(_voter).ve();
  }

  function getReward(uint tokenId, address[] memory tokens) external {
    require(IVe(ve).isApprovedOrOwner(msg.sender, tokenId), "Not token owner");
    _getReward(_tokenIdToAddress(tokenId), tokens, msg.sender);
  }

  /// @dev Used by Voter to allow batched reward claims
  function getRewardForOwner(uint tokenId, address[] memory tokens) external override {
    require(msg.sender == voter, "Not voter");
    address owner = IERC721(ve).ownerOf(tokenId);
    _getReward(_tokenIdToAddress(tokenId), tokens, owner);
  }

  /// @dev This is an external function, but internal notation is used
  ///      since it can only be called "internally" from Gauges
  function _deposit(uint amount, uint tokenId) external override {
    require(msg.sender == voter, "Not voter");
    require(amount > 0, "Zero amount");

    address adr = _tokenIdToAddress(tokenId);
    _increaseBalance(adr, amount);
    emit Deposit(adr, amount);
  }

  function _withdraw(uint amount, uint tokenId) external override {
    require(msg.sender == voter, "Not voter");
    require(amount > 0, "Zero amount");

    address adr = _tokenIdToAddress(tokenId);
    _decreaseBalance(adr, amount);
    emit Withdraw(adr, amount);
  }

  /// @dev Used to notify a gauge/bribe of a given reward,
  ///      this can create griefing attacks by extending rewards
  function notifyRewardAmount(address token, uint amount) external override {
    _notifyRewardAmount(token, amount);
  }

  // use tokenId instead of address for

  function tokenIdToAddress(uint tokenId) external pure returns (address) {
    return _tokenIdToAddress(tokenId);
  }

  function _tokenIdToAddress(uint tokenId) internal pure returns (address) {
    address adr = address(uint160(tokenId));
    require(_addressToTokenId(adr) == tokenId, "Wrong convert");
    return adr;
  }

  function addressToTokenId(address adr) external pure returns (uint) {
    return _addressToTokenId(adr);
  }

  function _addressToTokenId(address adr) internal pure returns (uint) {
    return uint(uint160(adr));
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./Bribe.sol";
import "../../interface/IBribeFactory.sol";

contract BribeFactory is IBribeFactory {
  address public lastGauge;

  event BribeCreated(address value);

  function createBribe(address[] memory _allowedRewardTokens) external override returns (address) {
    address _lastGauge = address(new Bribe(
        msg.sender,
        _allowedRewardTokens
      ));
    lastGauge = _lastGauge;
    emit BribeCreated(_lastGauge);
    return _lastGauge;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../interface/IGauge.sol";
import "../../interface/IPair.sol";
import "../../interface/IVoter.sol";
import "../../interface/IBribe.sol";
import "../../interface/IERC721.sol";
import "../../interface/IVe.sol";
import "./MultiRewardsPoolBase.sol";

/// @title Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract Gauge is IGauge, MultiRewardsPoolBase {
  using SafeERC20 for IERC20;

  /// @dev The ve token used for gauges
  address public immutable ve;
  address public immutable bribe;
  address public immutable voter;

  mapping(address => uint) public tokenIds;

  uint public fees0;
  uint public fees1;

  event ClaimFees(address indexed from, uint claimed0, uint claimed1);
  event VeTokenLocked(address indexed account, uint tokenId);
  event VeTokenUnlocked(address indexed account, uint tokenId);

  constructor(
    address _stake,
    address _bribe,
    address _ve,
    address _voter,
    address[] memory _allowedRewardTokens
  ) MultiRewardsPoolBase(
    _stake,
    _voter,
    _allowedRewardTokens
  ) {
    bribe = _bribe;
    ve = _ve;
    voter = _voter;
  }

  function claimFees() external lock override returns (uint claimed0, uint claimed1) {
    return _claimFees();
  }

  function _claimFees() internal returns (uint claimed0, uint claimed1) {
    address _underlying = underlying;
    (claimed0, claimed1) = IPair(_underlying).claimFees();
    if (claimed0 > 0 || claimed1 > 0) {
      uint _fees0 = fees0 + claimed0;
      uint _fees1 = fees1 + claimed1;
      (address _token0, address _token1) = IPair(_underlying).tokens();
      if (_fees0 > IMultiRewardsPool(bribe).left(_token0)) {
        fees0 = 0;
        IERC20(_token0).safeIncreaseAllowance(bribe, _fees0);
        IBribe(bribe).notifyRewardAmount(_token0, _fees0);
      } else {
        fees0 = _fees0;
      }
      if (_fees1 > IMultiRewardsPool(bribe).left(_token1)) {
        fees1 = 0;
        IERC20(_token1).safeIncreaseAllowance(bribe, _fees1);
        IBribe(bribe).notifyRewardAmount(_token1, _fees1);
      } else {
        fees1 = _fees1;
      }

      emit ClaimFees(msg.sender, claimed0, claimed1);
    }
  }

  function getReward(address account, address[] memory tokens) external override {
    require(msg.sender == account || msg.sender == voter, "Forbidden");
    IVoter(voter).distribute(address(this));
    _getReward(account, tokens, account);
  }

  function depositAll(uint tokenId) external {
    deposit(IERC20(underlying).balanceOf(msg.sender), tokenId);
  }

  function deposit(uint amount, uint tokenId) public {
    if (tokenId > 0) {
      _lockVeToken(msg.sender, tokenId);
    }
    _deposit(amount);
    IVoter(voter).emitDeposit(tokenId, msg.sender, amount);
  }

  function withdrawAll() external {
    withdraw(balanceOf[msg.sender]);
  }

  function withdraw(uint amount) public {
    uint tokenId = 0;
    if (amount == balanceOf[msg.sender]) {
      tokenId = tokenIds[msg.sender];
    }
    withdrawToken(amount, tokenId);
    IVoter(voter).emitWithdraw(tokenId, msg.sender, amount);
  }

  function withdrawToken(uint amount, uint tokenId) public {
    if (tokenId > 0) {
      _unlockVeToken(msg.sender, tokenId);
    }
    _withdraw(amount);
  }

  /// @dev Balance should be recalculated after the lock
  ///      For locking a new ve token withdraw all funds and deposit again
  function _lockVeToken(address account, uint tokenId) internal {
    require(IERC721(ve).ownerOf(tokenId) == account, "Not ve token owner");
    if (tokenIds[account] == 0) {
      tokenIds[account] = tokenId;
      IVoter(voter).attachTokenToGauge(tokenId, account);
    }
    require(tokenIds[account] == tokenId, "Wrong token");
    emit VeTokenLocked(account, tokenId);
  }

  /// @dev Balance should be recalculated after the unlock
  function _unlockVeToken(address account, uint tokenId) internal {
    require(tokenId == tokenIds[account], "Wrong token");
    tokenIds[account] = 0;
    IVoter(voter).detachTokenFromGauge(tokenId, account);
    emit VeTokenUnlocked(account, tokenId);
  }

  /// @dev Similar to Curve https://resources.curve.fi/reward-gauges/boosting-your-crv-rewards#formula
  function _derivedBalance(address account) internal override view returns (uint) {
    uint _tokenId = tokenIds[account];
    uint _balance = balanceOf[account];
    uint _derived = _balance * 40 / 100;
    uint _adjusted = 0;
    uint _supply = IERC20(ve).totalSupply();
    if (account == IERC721(ve).ownerOf(_tokenId) && _supply > 0) {
      _adjusted = (totalSupply * IVe(ve).balanceOfNFT(_tokenId) / _supply) * 60 / 100;
    }
    return Math.min((_derived + _adjusted), _balance);
  }

  function notifyRewardAmount(address token, uint amount) external {
    // claim rewards should not ruin distribution process
    try Gauge(address(this)).claimFees() {} catch {}
    _notifyRewardAmount(token, amount);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../interface/IGaugeFactory.sol";
import "./Gauge.sol";

contract GaugeFactory is IGaugeFactory {
  address public lastGauge;

  event GaugeCreated(address value);

  function createGauge(
    address _pool,
    address _bribe,
    address _ve,
    address[] memory _allowedRewardTokens
  ) external override returns (address) {
    address _lastGauge = address(new Gauge(_pool, _bribe, _ve, msg.sender, _allowedRewardTokens));
    lastGauge = _lastGauge;
    emit GaugeCreated(_lastGauge);
    return _lastGauge;
  }

  function createGaugeSingle(
    address _pool,
    address _bribe,
    address _ve,
    address _voter,
    address[] memory _allowedRewardTokens
  ) external override returns (address) {
    address _lastGauge = address(new Gauge(_pool, _bribe, _ve, _voter, _allowedRewardTokens));
    lastGauge = _lastGauge;
    emit GaugeCreated(_lastGauge);
    return _lastGauge;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../interface/IERC20.sol";
import "../../interface/IMultiRewardsPool.sol";
import "../../lib/Math.sol";
import "../../lib/SafeERC20.sol";
import "../../lib/CheckpointLib.sol";
import "../Reentrancy.sol";

abstract contract MultiRewardsPoolBase is Reentrancy, IMultiRewardsPool {
  using SafeERC20 for IERC20;
  using CheckpointLib for mapping(uint => CheckpointLib.Checkpoint);

  /// @dev Operator can add/remove reward tokens
  address public operator;

  /// @dev The LP token that needs to be staked for rewards
  address public immutable override underlying;

  uint public override derivedSupply;
  mapping(address => uint) public override derivedBalances;

  /// @dev Rewards are released over 7 days
  uint internal constant DURATION = 7 days;
  uint internal constant PRECISION = 10 ** 18;
  uint internal constant MAX_REWARD_TOKENS = 10;

  /// Default snx staking contract implementation
  /// https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol

  /// @dev Reward rate with precision 1e18
  mapping(address => uint) public rewardRate;
  mapping(address => uint) public periodFinish;
  mapping(address => uint) public lastUpdateTime;
  mapping(address => uint) public rewardPerTokenStored;

  mapping(address => mapping(address => uint)) public lastEarn;
  mapping(address => mapping(address => uint)) public userRewardPerTokenStored;

  uint public override totalSupply;
  mapping(address => uint) public override balanceOf;

  address[] public override rewardTokens;
  mapping(address => bool) public override isRewardToken;

  /// @notice A record of balance checkpoints for each account, by index
  mapping(address => mapping(uint => CheckpointLib.Checkpoint)) public checkpoints;
  /// @notice The number of checkpoints for each account
  mapping(address => uint) public numCheckpoints;
  /// @notice A record of balance checkpoints for each token, by index
  mapping(uint => CheckpointLib.Checkpoint) public supplyCheckpoints;
  /// @notice The number of checkpoints
  uint public supplyNumCheckpoints;
  /// @notice A record of balance checkpoints for each token, by index
  mapping(address => mapping(uint => CheckpointLib.Checkpoint)) public rewardPerTokenCheckpoints;
  /// @notice The number of checkpoints for each token
  mapping(address => uint) public rewardPerTokenNumCheckpoints;

  event Deposit(address indexed from, uint amount);
  event Withdraw(address indexed from, uint amount);
  event NotifyReward(address indexed from, address indexed reward, uint amount);
  event ClaimRewards(address indexed from, address indexed reward, uint amount, address recepient);

  constructor(address _stake, address _operator, address[] memory _allowedRewardTokens) {
    underlying = _stake;
    operator = _operator;
    for (uint i; i < _allowedRewardTokens.length; i++) {
      if (_allowedRewardTokens[i] != address(0)) {
        _registerRewardToken(_allowedRewardTokens[i]);
      }
    }
  }

  modifier onlyOperator() {
    require(msg.sender == operator, "Not operator");
    _;
  }

  //**************************************************************************
  //************************ VIEWS *******************************************
  //**************************************************************************

  function rewardTokensLength() external view override returns (uint) {
    return rewardTokens.length;
  }

  function rewardPerToken(address token) external view returns (uint) {
    return _rewardPerToken(token);
  }

  function _rewardPerToken(address token) internal view returns (uint) {
    if (derivedSupply == 0) {
      return rewardPerTokenStored[token];
    }
    return rewardPerTokenStored[token]
    + (
    (_lastTimeRewardApplicable(token) - Math.min(lastUpdateTime[token], periodFinish[token]))
    * rewardRate[token]
    / derivedSupply
    );
  }

  function derivedBalance(address account) external view override returns (uint) {
    return _derivedBalance(account);
  }

  function left(address token) external view override returns (uint) {
    if (block.timestamp >= periodFinish[token]) return 0;
    uint _remaining = periodFinish[token] - block.timestamp;
    return _remaining * rewardRate[token] / PRECISION;
  }

  function earned(address token, address account) external view override returns (uint) {
    return _earned(token, account);
  }

  //**************************************************************************
  //************************ OPERATOR ACTIONS ********************************
  //**************************************************************************

  function registerRewardToken(address token) external onlyOperator {
    _registerRewardToken(token);
  }

  function _registerRewardToken(address token) internal {
    require(rewardTokens.length < MAX_REWARD_TOKENS, "Too many reward tokens");
    require(!isRewardToken[token], "Already registered");
    isRewardToken[token] = true;
    rewardTokens.push(token);
  }

  function removeRewardToken(address token) external onlyOperator {
    require(periodFinish[token] < block.timestamp, "Rewards not ended");
    require(isRewardToken[token], "Not reward token");

    isRewardToken[token] = false;
    uint length = rewardTokens.length;
    require(length > 3, "First 3 tokens should not be removed");
    // keep 3 tokens as guarantee against malicious actions
    // assume it will be FLDX + pool tokens
    uint i = 3;
    bool found = false;
    for (; i < length; i++) {
      address t = rewardTokens[i];
      if (t == token) {
        found = true;
        break;
      }
    }
    require(found, "First tokens forbidden to remove");
    rewardTokens[i] = rewardTokens[length - 1];
    rewardTokens.pop();
  }

  //**************************************************************************
  //************************ USER ACTIONS ************************************
  //**************************************************************************

  function _deposit(uint amount) internal virtual lock {
    require(amount > 0, "Zero amount");
    _increaseBalance(msg.sender, amount);
    IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
    emit Deposit(msg.sender, amount);
  }

  function _increaseBalance(address account, uint amount) internal virtual {
    _updateRewardForAllTokens();

    totalSupply += amount;
    balanceOf[account] += amount;

    _updateDerivedBalanceAndWriteCheckpoints(account);
  }

  function _withdraw(uint amount) internal lock virtual {
    _decreaseBalance(msg.sender, amount);
    IERC20(underlying).safeTransfer(msg.sender, amount);
    emit Withdraw(msg.sender, amount);
  }

  function _decreaseBalance(address account, uint amount) internal virtual {
    _updateRewardForAllTokens();

    totalSupply -= amount;
    balanceOf[account] -= amount;

    _updateDerivedBalanceAndWriteCheckpoints(account);
  }

  /// @dev Implement restriction checks!
  function _getReward(address account, address[] memory tokens, address recipient) internal lock virtual {

    for (uint i = 0; i < tokens.length; i++) {
      (rewardPerTokenStored[tokens[i]], lastUpdateTime[tokens[i]]) = _updateRewardPerToken(tokens[i], type(uint).max, true);

      uint _reward = _earned(tokens[i], account);
      lastEarn[tokens[i]][account] = block.timestamp;
      userRewardPerTokenStored[tokens[i]][account] = rewardPerTokenStored[tokens[i]];
      if (_reward > 0) {
        IERC20(tokens[i]).safeTransfer(recipient, _reward);
      }

      emit ClaimRewards(msg.sender, tokens[i], _reward, recipient);
    }

    _updateDerivedBalanceAndWriteCheckpoints(account);
  }

  function _updateDerivedBalanceAndWriteCheckpoints(address account) internal {
    uint __derivedBalance = derivedBalances[account];
    derivedSupply -= __derivedBalance;
    __derivedBalance = _derivedBalance(account);
    derivedBalances[account] = __derivedBalance;
    derivedSupply += __derivedBalance;

    _writeCheckpoint(account, __derivedBalance);
    _writeSupplyCheckpoint();
  }

  //**************************************************************************
  //************************ REWARDS CALCULATIONS ****************************
  //**************************************************************************

  // earned is an estimation, it won't be exact till the supply > rewardPerToken calculations have run
  function _earned(address token, address account) internal view returns (uint) {
    // zero checkpoints means zero deposits
    if (numCheckpoints[account] == 0) {
      return 0;
    }
    // last claim rewards time
    uint _startTimestamp = Math.max(lastEarn[token][account], rewardPerTokenCheckpoints[token][0].timestamp);

    // find an index of the balance that the user had on the last claim
    uint _startIndex = _getPriorBalanceIndex(account, _startTimestamp);
    uint _endIndex = numCheckpoints[account] - 1;

    uint reward = 0;

    // calculate previous snapshots if exist
    if (_endIndex > 0) {
      for (uint i = _startIndex; i <= _endIndex - 1; i++) {
        CheckpointLib.Checkpoint memory cp0 = checkpoints[account][i];
        CheckpointLib.Checkpoint memory cp1 = checkpoints[account][i + 1];
        (uint _rewardPerTokenStored0,) = _getPriorRewardPerToken(token, cp0.timestamp);
        (uint _rewardPerTokenStored1,) = _getPriorRewardPerToken(token, cp1.timestamp);
        reward += cp0.value * (_rewardPerTokenStored1 - _rewardPerTokenStored0) / PRECISION;
      }
    }

    CheckpointLib.Checkpoint memory cp = checkpoints[account][_endIndex];
    (uint _rewardPerTokenStored,) = _getPriorRewardPerToken(token, cp.timestamp);
    reward += cp.value * (_rewardPerToken(token) - Math.max(_rewardPerTokenStored, userRewardPerTokenStored[token][account])) / PRECISION;
    return reward;
  }

  function _derivedBalance(address account) internal virtual view returns (uint) {
    // supposed to be implemented in a parent contract
    return balanceOf[account];
  }

  /// @dev Update stored rewardPerToken values without the last one snapshot
  ///      If the contract will get "out of gas" error on users actions this will be helpful
  function batchUpdateRewardPerToken(address token, uint maxRuns) external {
    (rewardPerTokenStored[token], lastUpdateTime[token]) = _updateRewardPerToken(token, maxRuns, false);
  }

  function _updateRewardForAllTokens() internal {
    uint length = rewardTokens.length;
    for (uint i; i < length; i++) {
      address token = rewardTokens[i];
      (rewardPerTokenStored[token], lastUpdateTime[token]) = _updateRewardPerToken(token, type(uint).max, true);
    }
  }

  /// @dev Should be called only with properly updated snapshots, or with actualLast=false
  function _updateRewardPerToken(address token, uint maxRuns, bool actualLast) internal returns (uint, uint) {
    uint _startTimestamp = lastUpdateTime[token];
    uint reward = rewardPerTokenStored[token];

    if (supplyNumCheckpoints == 0) {
      return (reward, _startTimestamp);
    }

    if (rewardRate[token] == 0) {
      return (reward, block.timestamp);
    }
    uint _startIndex = _getPriorSupplyIndex(_startTimestamp);
    uint _endIndex = Math.min(supplyNumCheckpoints - 1, maxRuns);

    if (_endIndex > 0) {
      for (uint i = _startIndex; i <= _endIndex - 1; i++) {
        CheckpointLib.Checkpoint memory sp0 = supplyCheckpoints[i];
        if (sp0.value > 0) {
          CheckpointLib.Checkpoint memory sp1 = supplyCheckpoints[i + 1];
          (uint _reward, uint _endTime) = _calcRewardPerToken(
            token,
            sp1.timestamp,
            sp0.timestamp,
            sp0.value,
            _startTimestamp
          );
          reward += _reward;
          _writeRewardPerTokenCheckpoint(token, reward, _endTime);
          _startTimestamp = _endTime;
        }
      }
    }

    // need to override the last value with actual numbers only on deposit/withdraw/claim/notify actions
    if (actualLast) {
      CheckpointLib.Checkpoint memory sp = supplyCheckpoints[_endIndex];
      if (sp.value > 0) {
        (uint _reward,) = _calcRewardPerToken(token, _lastTimeRewardApplicable(token), Math.max(sp.timestamp, _startTimestamp), sp.value, _startTimestamp);
        reward += _reward;
        _writeRewardPerTokenCheckpoint(token, reward, block.timestamp);
        _startTimestamp = block.timestamp;
      }
    }

    return (reward, _startTimestamp);
  }

  function _calcRewardPerToken(
    address token,
    uint lastSupplyTs1,
    uint lastSupplyTs0,
    uint supply,
    uint startTimestamp
  ) internal view returns (uint, uint) {
    uint endTime = Math.max(lastSupplyTs1, startTimestamp);
    uint _periodFinish = periodFinish[token];
    return (
    (Math.min(endTime, _periodFinish) - Math.min(Math.max(lastSupplyTs0, startTimestamp), _periodFinish))
    * rewardRate[token] / supply
    , endTime);
  }

  /// @dev Returns the last time the reward was modified or periodFinish if the reward has ended
  function _lastTimeRewardApplicable(address token) internal view returns (uint) {
    return Math.min(block.timestamp, periodFinish[token]);
  }

  //**************************************************************************
  //************************ NOTIFY ******************************************
  //**************************************************************************

  function _notifyRewardAmount(address token, uint amount) internal lock virtual {
    require(token != underlying, "Wrong token for rewards");
    require(amount > 0, "Zero amount");
    require(isRewardToken[token], "Token not allowed");
    if (rewardRate[token] == 0) {
      _writeRewardPerTokenCheckpoint(token, 0, block.timestamp);
    }
    (rewardPerTokenStored[token], lastUpdateTime[token]) = _updateRewardPerToken(token, type(uint).max, true);

    if (block.timestamp >= periodFinish[token]) {
      IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
      rewardRate[token] = amount * PRECISION / DURATION;
    } else {
      uint _remaining = periodFinish[token] - block.timestamp;
      uint _left = _remaining * rewardRate[token];
      // not sure what the reason was in the original solidly implementation for this restriction
      // however, by design probably it is a good idea against human errors
      require(amount > _left / PRECISION, "Amount should be higher than remaining rewards");
      IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
      rewardRate[token] = (amount * PRECISION + _left) / DURATION;
    }

    periodFinish[token] = block.timestamp + DURATION;
    emit NotifyReward(msg.sender, token, amount);
  }

  //**************************************************************************
  //************************ CHECKPOINTS *************************************
  //**************************************************************************

  function getPriorBalanceIndex(address account, uint timestamp) external view returns (uint) {
    return _getPriorBalanceIndex(account, timestamp);
  }

  /// @notice Determine the prior balance for an account as of a block number
  /// @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
  /// @param account The address of the account to check
  /// @param timestamp The timestamp to get the balance at
  /// @return The balance the account had as of the given block
  function _getPriorBalanceIndex(address account, uint timestamp) internal view returns (uint) {
    uint nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }
    return checkpoints[account].findLowerIndex(nCheckpoints, timestamp);
  }

  function getPriorSupplyIndex(uint timestamp) external view returns (uint) {
    return _getPriorSupplyIndex(timestamp);
  }

  function _getPriorSupplyIndex(uint timestamp) internal view returns (uint) {
    uint nCheckpoints = supplyNumCheckpoints;
    if (nCheckpoints == 0) {
      return 0;
    }
    return supplyCheckpoints.findLowerIndex(nCheckpoints, timestamp);
  }

  function getPriorRewardPerToken(address token, uint timestamp) external view returns (uint, uint) {
    return _getPriorRewardPerToken(token, timestamp);
  }

  function _getPriorRewardPerToken(address token, uint timestamp) internal view returns (uint, uint) {
    uint nCheckpoints = rewardPerTokenNumCheckpoints[token];
    if (nCheckpoints == 0) {
      return (0, 0);
    }
    mapping(uint => CheckpointLib.Checkpoint) storage cps = rewardPerTokenCheckpoints[token];
    uint lower = cps.findLowerIndex(nCheckpoints, timestamp);
    CheckpointLib.Checkpoint memory cp = cps[lower];
    return (cp.value, cp.timestamp);
  }

  function _writeCheckpoint(address account, uint balance) internal {
    uint _timestamp = block.timestamp;
    uint _nCheckPoints = numCheckpoints[account];

    if (_nCheckPoints > 0 && checkpoints[account][_nCheckPoints - 1].timestamp == _timestamp) {
      checkpoints[account][_nCheckPoints - 1].value = balance;
    } else {
      checkpoints[account][_nCheckPoints] = CheckpointLib.Checkpoint(_timestamp, balance);
      numCheckpoints[account] = _nCheckPoints + 1;
    }
  }

  function _writeRewardPerTokenCheckpoint(address token, uint reward, uint timestamp) internal {
    uint _nCheckPoints = rewardPerTokenNumCheckpoints[token];

    if (_nCheckPoints > 0 && rewardPerTokenCheckpoints[token][_nCheckPoints - 1].timestamp == timestamp) {
      rewardPerTokenCheckpoints[token][_nCheckPoints - 1].value = reward;
    } else {
      rewardPerTokenCheckpoints[token][_nCheckPoints] = CheckpointLib.Checkpoint(timestamp, reward);
      rewardPerTokenNumCheckpoints[token] = _nCheckPoints + 1;
    }
  }

  function _writeSupplyCheckpoint() internal {
    uint _nCheckPoints = supplyNumCheckpoints;
    uint _timestamp = block.timestamp;

    if (_nCheckPoints > 0 && supplyCheckpoints[_nCheckPoints - 1].timestamp == _timestamp) {
      supplyCheckpoints[_nCheckPoints - 1].value = derivedSupply;
    } else {
      supplyCheckpoints[_nCheckPoints] = CheckpointLib.Checkpoint(_timestamp, derivedSupply);
      supplyNumCheckpoints = _nCheckPoints + 1;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../interface/IERC20.sol";

contract Fldx is IERC20 {

  string public constant symbol = "FLDX";
  string public constant name = "Flair Dex Token";
  uint8 public constant decimals = 18;
  uint public override totalSupply = 0;

  mapping(address => uint) public override balanceOf;
  mapping(address => mapping(address => uint)) public override allowance;

  address public minter;
  address public merkleClaim;
  address public merkleNFTClaim;

  constructor() {
    minter = msg.sender;
  }

  // No checks as its meant to be once off to set minting rights to Minter
  function setMinter(address _minter) external {
    require(msg.sender == minter, "FLDX: Not minter");
    minter = _minter;
  }

  // Can only be set during deployment phase
  function setMerkleClaim(address _merkleClaim) external {
    require(msg.sender == minter, 'FLDX: Not Minter');
    merkleClaim = _merkleClaim;
  }

  // Can only be set during deployment phase
  function setMerkleNFTClaim(address _merkleNFTClaim) external {
    require(msg.sender == minter, 'FLDX: Not Minter');
    merkleNFTClaim = _merkleNFTClaim;
  }

  function approve(address _spender, uint _value) external override returns (bool) {
    require(_spender != address(0), "FLDX: Approve to the zero address");
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function _mint(address _to, uint _amount) internal returns (bool) {
    require(_to != address(0), "FLDX: Mint to the zero address");
    balanceOf[_to] += _amount;
    totalSupply += _amount;
    emit Transfer(address(0x0), _to, _amount);
    return true;
  }

  function _transfer(address _from, address _to, uint _value) internal returns (bool) {
    require(_to != address(0), "FLDX: Transfer to the zero address");

    uint fromBalance = balanceOf[_from];
    require(fromBalance >= _value, "FLDX: Transfer amount exceeds balance");
  unchecked {
    balanceOf[_from] = fromBalance - _value;
  }

    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function transfer(address _to, uint _value) external override returns (bool) {
    return _transfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) external override returns (bool) {
    address spender = msg.sender;
    uint spenderAllowance = allowance[_from][spender];
    if (spenderAllowance != type(uint).max) {
      require(spenderAllowance >= _value, "FLDX: Insufficient allowance");
    unchecked {
      uint newAllowance = spenderAllowance - _value;
      allowance[_from][spender] = newAllowance;
      emit Approval(_from, spender, newAllowance);
    }
    }
    return _transfer(_from, _to, _value);
  }

  function mint(address account, uint amount) external returns (bool) {
    require(msg.sender == minter, "FLDX: Not minter");
    _mint(account, amount);
    return true;
  }

  function claim(address account, uint amount) external returns (bool) {
    require(msg.sender == merkleClaim || msg.sender == merkleNFTClaim, 'not authorized claimant');
    _mint(account, amount);
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../lib/Math.sol";
import "../../lib/SafeERC20.sol";
import "../../interface/IUnderlying.sol";
import "../../interface/IVoter.sol";
import "../../interface/IVe.sol";
import "../../interface/IVeDist.sol";
import "../../interface/IMinter.sol";
import "../../interface/IERC20.sol";
import "../../interface/IController.sol";

/// @title Codifies the minting rules as per ve(3,3),
///        abstracted from the token to support any token that allows minting
contract FldxMinter is IMinter {
  using SafeERC20 for IERC20;

  /// @dev Allows minting once per week (reset every Thursday 00:00 UTC)
  uint internal constant _WEEK = 86400 * 7;
  uint internal constant _LOCK_PERIOD = 86400 * 7 * 52 * 4;
  uint internal constant PRECISION = 10000;

  /// @dev Weekly emission threshold for the end game. 2% of circulation supply.
  uint internal constant _TAIL_EMISSION = 200;

  /// @dev Treasury Emission. 3% of emissions
  uint internal constant _TREASURY_EMISSION = 300;

  /// @dev NFT Stakers Emission. 2% of emissions
  uint internal constant _NFT_STAKERS_EMISSION = 200;

  /// @dev The core parameter for determinate the whole emission dynamic.
  ///       Will be decreased every week.
  uint internal constant _START_BASE_WEEKLY_EMISSION = 5_000_000e18;

  // 15% of weekly emission
  uint internal constant _MAX_REBASE_EMISSION_PERCENTAGE = 1500;

  IUnderlying public immutable token;
  IVe public immutable ve;
  address public immutable controller;
  uint public weeklyEmissionDecrease;
  uint public baseWeeklyEmission;
  uint internal numEpoch;
  uint public activePeriod;

  address public treasury;
  address public pendingTreasury;
  address public nftStakingContract;

  event Mint(
    address indexed sender,
    uint weekly,
    uint growth,
    uint circulatingSupply,
    uint circulatingEmission
  );

  constructor(
    address ve_, // the ve(3,3) system that will be locked into
    address controller_ // controller with veDist and voter addresses
  ) {
    token = IUnderlying(IVe(ve_).token());
    ve = IVe(ve_);
    controller = controller_;
    treasury = msg.sender;
    nftStakingContract = msg.sender;
    weeklyEmissionDecrease = 9900;
    baseWeeklyEmission = _START_BASE_WEEKLY_EMISSION;
    activePeriod = (block.timestamp / _WEEK) * _WEEK;
  }

  function setTreasury(address _treasury) external {
    require(msg.sender == treasury, "Not treasury");
    pendingTreasury = _treasury;
  }

  function acceptTreasury() external {
    require(msg.sender == pendingTreasury, "Not pending treasury");
    treasury = pendingTreasury;
  }

  function setNftStakingContract(address _nftStakingContract) external {
    require(msg.sender == treasury, "Not treasury");
    nftStakingContract = _nftStakingContract;
  }

  function _veDist() internal view returns (IVeDist) {
    return IVeDist(IController(controller).veDist());
  }

  function _voter() internal view returns (IVoter) {
    return IVoter(IController(controller).voter());
  }

  /// @dev Calculate circulating supply as total token supply - locked supply - veDist balance - minter balance
  function circulatingSupply() external view returns (uint) {
    return _circulatingSupply();
  }

  function _circulatingSupply() internal view returns (uint) {
    return token.totalSupply() - IUnderlying(address(ve)).totalSupply()
    // exclude veDist token balance from circulation - users unable to claim them without lock
    // late claim will lead to wrong circulation supply calculation
    - token.balanceOf(address(_veDist()))
    // exclude balance on minter, it is obviously locked
    - token.balanceOf(address(this));
  }

  /// @dev Weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
  function weeklyEmission() external view returns (uint) {
    return _weeklyEmission();
  }

  function _weeklyEmission() internal view returns (uint) {
    return Math.max(baseWeeklyEmission, _circulatingEmission());
  }

  /// @dev Calculates tail end (infinity) emissions as 0.2% of total supply
  function circulatingEmission() external view returns (uint) {
    return _circulatingEmission();
  }

  function _circulatingEmission() internal view returns (uint) {
    return _circulatingSupply() * _TAIL_EMISSION / PRECISION;
  }

  /// @dev Calculate inflation and adjust ve balances accordingly
  function calculateGrowth(uint _minted) external view returns (uint) {
    return _calculateGrowth(_minted);
  }

  /// @dev calculate inflation and adjust ve balances accordingly
  function _calculateGrowth(uint _minted) internal view returns (uint) {
    uint _veTotal = IUnderlying(address(ve)).totalSupply();
    uint _fldxTotal = token.totalSupply();
    uint rebase = (((((_minted * _veTotal) / _fldxTotal) * _veTotal) / _fldxTotal) *
    _veTotal) /
    _fldxTotal /
    2;

    if (rebase > _minted * _MAX_REBASE_EMISSION_PERCENTAGE / PRECISION) {
      return _minted * _MAX_REBASE_EMISSION_PERCENTAGE / PRECISION;
    } else {
      return rebase;
    }
  }

  /// @dev Update period can only be called once per cycle (1 week)
  function updatePeriod() external override returns (uint) {
    // only trigger if new week
    if (block.timestamp >= activePeriod + _WEEK) {
      activePeriod = (block.timestamp / _WEEK) * _WEEK;
      uint _weekly = _weeklyEmission();
      // slightly decrease weekly emission
      baseWeeklyEmission = baseWeeklyEmission
      * weeklyEmissionDecrease
      / PRECISION;

      uint _growth = _calculateGrowth(_weekly);
      uint _treasury = (_weekly + _growth) * _TREASURY_EMISSION / PRECISION;
      uint _nftstakers = (_weekly + _growth) * _NFT_STAKERS_EMISSION / PRECISION;
      uint _required = _growth + _weekly + _treasury + _nftstakers;

      unchecked {
        ++numEpoch;
      }

      // decrease emission decrease to 0.5% after a year
      if (numEpoch == 52) {
        weeklyEmissionDecrease = 9950;
      }

      // decrease emission decrease to 0.25% after two year
      if (numEpoch == 104) {
        weeklyEmissionDecrease = 9975;
      }

      uint _balanceOf = token.balanceOf(address(this));
      if (_balanceOf < _required) {
        token.mint(address(this), _required - _balanceOf);
      }

      IERC20(address(token)).safeTransfer(treasury, _treasury);
      IERC20(address(token)).safeTransfer(nftStakingContract, _nftstakers);
      IERC20(address(token)).safeTransfer(address(_veDist()), _growth);
      // checkpoint token balance that was just minted in veDist
      _veDist().checkpointToken();
      // checkpoint supply
      _veDist().checkpointTotalSupply();

      token.approve(address(_voter()), _weekly);
      _voter().notifyRewardAmount(_weekly);

      emit Mint(msg.sender, _weekly, _growth, _circulatingSupply(), _circulatingEmission());
    }
    return activePeriod;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../interface/IVe.sol";
import "../../interface/IVoter.sol";
import "../../interface/IERC20.sol";
import "../../interface/IERC721.sol";
import "../../interface/IGauge.sol";
import "../../interface/IFactory.sol";
import "../../interface/IPair.sol";
import "../../interface/IBribeFactory.sol";
import "../../interface/IGaugeFactory.sol";
import "../../interface/IMinter.sol";
import "../../interface/IBribe.sol";
import "../../interface/IMultiRewardsPool.sol";
import "../Reentrancy.sol";
import "../../lib/SafeERC20.sol";

contract FldxVoter is IVoter, Reentrancy {
  using SafeERC20 for IERC20;

  /// @dev The ve token that governs these contracts
  address public immutable override ve;
  /// @dev FldxFactory
  address public immutable factory;
  address public immutable token;
  address public immutable gaugeFactory;
  address public immutable bribeFactory;
  /// @dev Rewards are released over 7 days
  uint internal constant DURATION = 7 days;
  address public minter;
  address public governor;

  /// @dev Total voting weight
  uint public totalWeight;

  /// @dev All pools viable for incentives
  address[] public pools;
  /// @dev pool => gauge
  mapping(address => address) public gauges;
  /// @dev gauge => pool
  mapping(address => address) public poolForGauge;
  /// @dev gauge => bribe
  mapping(address => address) public bribes;
  /// @dev pool => weight
  mapping(address => int256) public weights;
  /// @dev nft => pool => votes
  mapping(uint => mapping(address => int256)) public votes;
  /// @dev nft => pools
  mapping(uint => address[]) public poolVote;
  /// @dev nft => total voting weight of user
  mapping(uint => uint) public usedWeights;
  mapping(address => bool) public isGauge;
  mapping(address => bool) public isWhitelisted;

  uint public index;
  mapping(address => uint) public supplyIndex;
  mapping(address => uint) public claimable;
  mapping(uint => uint) public lastVoted;

  event GaugeCreated(address indexed gauge, address creator, address indexed bribe, address indexed pool);
  event Voted(address indexed voter, uint tokenId, int256 weight);
  event Abstained(uint tokenId, int256 weight);
  event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
  event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
  event NotifyReward(address indexed sender, address indexed reward, uint amount);
  event DistributeReward(address indexed sender, address indexed gauge, uint amount);
  event Attach(address indexed owner, address indexed gauge, uint tokenId);
  event Detach(address indexed owner, address indexed gauge, uint tokenId);
  event Whitelisted(address indexed whitelister, address indexed token);

  modifier onlyNewEpoch(uint _tokenId) {
    // ensure new epoch since last vote
    require((block.timestamp / DURATION) * DURATION > lastVoted[_tokenId], "TOKEN_ALREADY_VOTED_THIS_EPOCH");
    _;
  }

  constructor(address _ve, address _factory, address _gaugeFactory, address _bribeFactory) {
    ve = _ve;
    factory = _factory;
    token = IVe(_ve).token();
    gaugeFactory = _gaugeFactory;
    bribeFactory = _bribeFactory;
    minter = msg.sender;
    governor = msg.sender;
  }

  function initialize(address[] memory _tokens, address _minter) external {
    require(msg.sender == minter, "!minter");
    for (uint i = 0; i < _tokens.length; i++) {
      _whitelist(_tokens[i]);
    }
    minter = _minter;
  }

  function setGovernor(address _governor) public {
    require(msg.sender == governor);
    governor = _governor;
  }

  /// @dev Remove all votes for given tokenId.
  function reset(uint _tokenId) external onlyNewEpoch(_tokenId) {
    require(IVe(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owner");
    lastVoted[_tokenId] = block.timestamp;
    _reset(_tokenId);
    IVe(ve).abstain(_tokenId);
  }

  function _reset(uint _tokenId) internal {
    address[] storage _poolVote = poolVote[_tokenId];
    uint _poolVoteCnt = _poolVote.length;
    int256 _totalWeight = 0;

    for (uint i = 0; i < _poolVoteCnt; i ++) {
      address _pool = _poolVote[i];
      int256 _votes = votes[_tokenId][_pool];
      _updateFor(gauges[_pool]);
      weights[_pool] -= _votes;
      votes[_tokenId][_pool] -= _votes;
      if (_votes > 0) {
        IBribe(bribes[gauges[_pool]])._withdraw(uint(_votes), _tokenId);
        _totalWeight += _votes;
      } else {
        _totalWeight -= _votes;
      }
      emit Abstained(_tokenId, _votes);
    }
    totalWeight -= uint(_totalWeight);
    usedWeights[_tokenId] = 0;
    delete poolVote[_tokenId];
  }

  /// @dev Resubmit exist votes for given token. For internal purposes.
  function poke(uint _tokenId) external {
    address[] memory _poolVote = poolVote[_tokenId];
    uint _poolCnt = _poolVote.length;
    int256[] memory _weights = new int256[](_poolCnt);

    for (uint i = 0; i < _poolCnt; i ++) {
      _weights[i] = votes[_tokenId][_poolVote[i]];
    }

    _vote(_tokenId, _poolVote, _weights);
  }

  function _vote(uint _tokenId, address[] memory _poolVote, int256[] memory _weights) internal {
    _reset(_tokenId);
    uint _poolCnt = _poolVote.length;
    int256 _weight = int256(IVe(ve).balanceOfNFT(_tokenId));
    int256 _totalVoteWeight = 0;
    int256 _totalWeight = 0;
    int256 _usedWeight = 0;

    for (uint i = 0; i < _poolCnt; i++) {
      _totalVoteWeight += _weights[i] > 0 ? _weights[i] : - _weights[i];
    }

    for (uint i = 0; i < _poolCnt; i++) {
      address _pool = _poolVote[i];
      address _gauge = gauges[_pool];

      int256 _poolWeight = _weights[i] * _weight / _totalVoteWeight;
      require(votes[_tokenId][_pool] == 0, "duplicate pool");
      require(_poolWeight != 0, "zero power");
      _updateFor(_gauge);

      poolVote[_tokenId].push(_pool);

      weights[_pool] += _poolWeight;
      votes[_tokenId][_pool] += _poolWeight;
      if (_poolWeight > 0) {
        IBribe(bribes[_gauge])._deposit(uint(_poolWeight), _tokenId);
      } else {
        _poolWeight = - _poolWeight;
      }
      _usedWeight += _poolWeight;
      _totalWeight += _poolWeight;
      emit Voted(msg.sender, _tokenId, _poolWeight);
    }
    if (_usedWeight > 0) IVe(ve).voting(_tokenId);
    totalWeight += uint(_totalWeight);
    usedWeights[_tokenId] = uint(_usedWeight);
  }

  /// @dev Vote for given pools using a vote power of given tokenId. Reset previous votes.
  function vote(uint tokenId, address[] calldata _poolVote, int256[] calldata _weights) external onlyNewEpoch(tokenId) {
    require(IVe(ve).isApprovedOrOwner(msg.sender, tokenId), "!owner");
    require(_poolVote.length == _weights.length, "!arrays");
    lastVoted[tokenId] = block.timestamp;
    _vote(tokenId, _poolVote, _weights);
  }

  /// @dev Add token to whitelist. Only pools with whitelisted tokens can be added to gauge.
  function whitelist(address _token) external {
    require(msg.sender == governor, "!power");
    _whitelist(_token);
  }

  function _whitelist(address _token) internal {
    require(!isWhitelisted[_token], "already whitelisted");
    isWhitelisted[_token] = true;
    emit Whitelisted(msg.sender, _token);
  }

  /// @dev Add a token to a gauge/bribe as possible reward.
  function registerRewardToken(address _token, address _gaugeOrBribe) external {
    require(msg.sender == governor, "!power");
    IMultiRewardsPool(_gaugeOrBribe).registerRewardToken(_token);
  }

  /// @dev Remove a token from a gauge/bribe allowed rewards list.
  function removeRewardToken(address _token, address _gaugeOrBribe) external {
    require(msg.sender == governor, "!power");
    IMultiRewardsPool(_gaugeOrBribe).removeRewardToken(_token);
  }

  /// @dev Create gauge for given pool. Only for a pool with whitelisted tokens.
  function createGauge(address _pool) external returns (address) {
    require(gauges[_pool] == address(0x0), "exists");
    require(IFactory(factory).isPair(_pool), "!pool");
    (address tokenA, address tokenB) = IPair(_pool).tokens();
    require(isWhitelisted[tokenA] && isWhitelisted[tokenB], "!whitelisted");

    address[] memory allowedRewards = new address[](3);
    allowedRewards[0] = tokenA;
    allowedRewards[1] = tokenB;
    if (token != tokenA && token != tokenB) {
      allowedRewards[2] = token;
    }

    address _bribe = IBribeFactory(bribeFactory).createBribe(allowedRewards);
    address _gauge = IGaugeFactory(gaugeFactory).createGauge(_pool, _bribe, ve, allowedRewards);
    IERC20(token).safeIncreaseAllowance(_gauge, type(uint).max);
    bribes[_gauge] = _bribe;
    gauges[_pool] = _gauge;
    poolForGauge[_gauge] = _pool;
    isGauge[_gauge] = true;
    _updateFor(_gauge);
    pools.push(_pool);
    emit GaugeCreated(_gauge, msg.sender, _bribe, _pool);
    return _gauge;
  }

  /// @dev A gauge should be able to attach a token for preventing transfers/withdraws.
  function attachTokenToGauge(uint tokenId, address account) external override {
    require(isGauge[msg.sender], "!gauge");
    if (tokenId > 0) {
      IVe(ve).attachToken(tokenId);
    }
    emit Attach(account, msg.sender, tokenId);
  }

  /// @dev Emit deposit event for easily handling external actions.
  function emitDeposit(uint tokenId, address account, uint amount) external override {
    require(isGauge[msg.sender], "!gauge");
    emit Deposit(account, msg.sender, tokenId, amount);
  }

  /// @dev Detach given token.
  function detachTokenFromGauge(uint tokenId, address account) external override {
    require(isGauge[msg.sender], "!gauge");
    if (tokenId > 0) {
      IVe(ve).detachToken(tokenId);
    }
    emit Detach(account, msg.sender, tokenId);
  }

  /// @dev Emit withdraw event for easily handling external actions.
  function emitWithdraw(uint tokenId, address account, uint amount) external override {
    require(isGauge[msg.sender], "!gauge");
    emit Withdraw(account, msg.sender, tokenId, amount);
  }

  /// @dev Length of pools
  function poolsLength() external view returns (uint) {
    return pools.length;
  }

  /// @dev Add rewards to this contract. Usually it is FldxMinter.
  function notifyRewardAmount(uint amount) external override {
    require(amount != 0, "zero amount");
    uint _totalWeight = totalWeight;
    // without votes rewards can not be added
    require(_totalWeight != 0, "!weights");
    // transfer the distro in
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    // 1e18 adjustment is removed during claim
    uint _ratio = amount * 1e18 / _totalWeight;
    if (_ratio > 0) {
      index += _ratio;
    }
    emit NotifyReward(msg.sender, token, amount);
  }

  /// @dev Update given gauges.
  function updateFor(address[] memory _gauges) external {
    for (uint i = 0; i < _gauges.length; i++) {
      _updateFor(_gauges[i]);
    }
  }

  /// @dev Update gauges by indexes in a range.
  function updateForRange(uint start, uint end) public {
    for (uint i = start; i < end; i++) {
      _updateFor(gauges[pools[i]]);
    }
  }

  /// @dev Update all gauges.
  function updateAll() external {
    updateForRange(0, pools.length);
  }

  /// @dev Update reward info for given gauge.
  function updateGauge(address _gauge) external {
    _updateFor(_gauge);
  }

  function _updateFor(address _gauge) internal {
    address _pool = poolForGauge[_gauge];
    int256 _supplied = weights[_pool];
    if (_supplied > 0) {
      uint _supplyIndex = supplyIndex[_gauge];
      // get global index for accumulated distro
      uint _index = index;
      // update _gauge current position to global position
      supplyIndex[_gauge] = _index;
      // see if there is any difference that need to be accrued
      uint _delta = _index - _supplyIndex;
      if (_delta > 0) {
        // add accrued difference for each supplied token
        uint _share = uint(_supplied) * _delta / 1e18;
        claimable[_gauge] += _share;
      }
    } else {
      // new users are set to the default global state
      supplyIndex[_gauge] = index;
    }
  }

  /// @dev Batch claim rewards from given gauges.
  function claimRewards(address[] memory _gauges, address[][] memory _tokens) external {
    for (uint i = 0; i < _gauges.length; i++) {
      IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
    }
  }

  /// @dev Batch claim rewards from given bribe contracts for given tokenId.
  function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external {
    require(IVe(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owner");
    for (uint i = 0; i < _bribes.length; i++) {
      IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
    }
  }

  /// @dev Claim fees from given bribes.
  function claimFees(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external {
    require(IVe(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owner");
    for (uint i = 0; i < _bribes.length; i++) {
      IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
    }
  }

  /// @dev Move fees from deposited pools to bribes for given gauges.
  function distributeFees(address[] memory _gauges) external {
    for (uint i = 0; i < _gauges.length; i++) {
      IGauge(_gauges[i]).claimFees();
    }
  }

  /// @dev Get emission from minter and notify rewards for given gauge.
  function distribute(address _gauge) external override {
    _distribute(_gauge);
  }

  function _distribute(address _gauge) internal lock {
    IMinter(minter).updatePeriod();
    _updateFor(_gauge);
    uint _claimable = claimable[_gauge];
    if (_claimable > IMultiRewardsPool(_gauge).left(token) && _claimable / DURATION > 0) {
      claimable[_gauge] = 0;
      IGauge(_gauge).notifyRewardAmount(token, _claimable);
      emit DistributeReward(msg.sender, _gauge, _claimable);
    }
  }

  /// @dev Distribute rewards for all pools.
  function distributeAll() external {
    uint length = pools.length;
    for (uint x; x < length; x++) {
      _distribute(gauges[pools[x]]);
    }
  }

  function distributeForPoolsInRange(uint start, uint finish) external {
    for (uint x = start; x < finish; x++) {
      _distribute(gauges[pools[x]]);
    }
  }

  function distributeForGauges(address[] memory _gauges) external {
    for (uint x = 0; x < _gauges.length; x++) {
      _distribute(_gauges[x]);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../lib/Base64.sol";
import "../../interface/IERC20.sol";
import "../../interface/IERC721.sol";
import "../../interface/IERC721Metadata.sol";
import "../../interface/IVe.sol";
import "../../interface/IERC721Receiver.sol";
import "../../interface/IController.sol";
import "../Reentrancy.sol";
import "../../lib/SafeERC20.sol";
import "../../lib/Math.sol";

contract Ve is IERC721, IERC721Metadata, IVe, Reentrancy {
  using SafeERC20 for IERC20;

  uint internal constant WEEK = 1 weeks;
  uint internal constant MAX_TIME = 4 * 365 * 86400;
  int128 internal constant I_MAX_TIME = 4 * 365 * 86400;
  uint internal constant MULTIPLIER = 1 ether;

  address immutable public override token;
  uint public supply;
  mapping(uint => LockedBalance) public locked;

  mapping(uint => uint) public ownershipChange;

  uint public override epoch;
  /// @dev epoch -> unsigned point
  mapping(uint => Point) internal _pointHistory;
  /// @dev user -> Point[userEpoch]
  mapping(uint => Point[1000000000]) internal _userPointHistory;

  mapping(uint => uint) public override userPointEpoch;
  mapping(uint => int128) public slopeChanges; // time -> signed slope change

  mapping(uint => uint) public attachments;
  mapping(uint => bool) public voted;
  address public controller;

  string constant public override name = "veFLDX";
  string constant public override symbol = "veFLDX";
  string constant public version = "1.0.0";
  uint8 constant public decimals = 18;

  /// @dev Current count of token
  uint internal tokenId;

  /// @dev Mapping from NFT ID to the address that owns it.
  mapping(uint => address) internal idToOwner;

  /// @dev Mapping from NFT ID to approved address.
  mapping(uint => address) internal idToApprovals;

  /// @dev Mapping from owner address to count of his tokens.
  mapping(address => uint) internal ownerToNFTokenCount;

  /// @dev Mapping from owner address to mapping of index to tokenIds
  mapping(address => mapping(uint => uint)) internal ownerToNFTokenIdList;

  /// @dev Mapping from NFT ID to index of owner
  mapping(uint => uint) internal tokenToOwnerIndex;

  /// @dev Mapping from owner address to mapping of operator addresses.
  mapping(address => mapping(address => bool)) internal ownerToOperators;

  /// @dev Mapping of interface id to bool about whether or not it's supported
  mapping(bytes4 => bool) internal supportedInterfaces;

  /// @dev ERC165 interface ID of ERC165
  bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;

  /// @dev ERC165 interface ID of ERC721
  bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

  /// @dev ERC165 interface ID of ERC721Metadata
  bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

  event Deposit(
    address indexed provider,
    uint tokenId,
    uint value,
    uint indexed locktime,
    DepositType depositType,
    uint ts
  );
  event Withdraw(address indexed provider, uint tokenId, uint value, uint ts);
  event Supply(uint prevSupply, uint supply);

  /// @notice Contract constructor
  /// @param token_ `ERC20CRV` token address
  constructor(address token_, address controller_) {
    token = token_;
    controller = controller_;
    _pointHistory[0].blk = block.number;
    _pointHistory[0].ts = block.timestamp;

    supportedInterfaces[ERC165_INTERFACE_ID] = true;
    supportedInterfaces[ERC721_INTERFACE_ID] = true;
    supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = true;

    // mint-ish
    emit Transfer(address(0), address(this), tokenId);
    // burn-ish
    emit Transfer(address(this), address(0), tokenId);
  }

  function _voter() internal view returns (address) {
    return IController(controller).voter();
  }

  /// @dev Interface identification is specified in ERC-165.
  /// @param _interfaceID Id of the interface
  function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
    return supportedInterfaces[_interfaceID];
  }

  /// @notice Get the most recently recorded rate of voting power decrease for `_tokenId`
  /// @param _tokenId token of the NFT
  /// @return Value of the slope
  function getLastUserSlope(uint _tokenId) external view returns (int128) {
    uint uEpoch = userPointEpoch[_tokenId];
    return _userPointHistory[_tokenId][uEpoch].slope;
  }

  /// @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
  /// @param _tokenId token of the NFT
  /// @param _idx User epoch number
  /// @return Epoch time of the checkpoint
  function userPointHistoryTs(uint _tokenId, uint _idx) external view returns (uint) {
    return _userPointHistory[_tokenId][_idx].ts;
  }

  /// @notice Get timestamp when `_tokenId`'s lock finishes
  /// @param _tokenId User NFT
  /// @return Epoch time of the lock end
  function lockedEnd(uint _tokenId) external view returns (uint) {
    return locked[_tokenId].end;
  }

  /// @dev Returns the number of NFTs owned by `_owner`.
  ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
  /// @param _owner Address for whom to query the balance.
  function _balance(address _owner) internal view returns (uint) {
    return ownerToNFTokenCount[_owner];
  }

  /// @dev Returns the number of NFTs owned by `_owner`.
  ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
  /// @param _owner Address for whom to query the balance.
  function balanceOf(address _owner) external view override returns (uint) {
    return _balance(_owner);
  }

  /// @dev Returns the address of the owner of the NFT.
  /// @param _tokenId The identifier for an NFT.
  function ownerOf(uint _tokenId) public view override returns (address) {
    return idToOwner[_tokenId];
  }

  /// @dev Get the approved address for a single NFT.
  /// @param _tokenId ID of the NFT to query the approval of.
  function getApproved(uint _tokenId) external view override returns (address) {
    return idToApprovals[_tokenId];
  }

  /// @dev Checks if `_operator` is an approved operator for `_owner`.
  /// @param _owner The address that owns the NFTs.
  /// @param _operator The address that acts on behalf of the owner.
  function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
    return (ownerToOperators[_owner])[_operator];
  }

  /// @dev  Get token by index
  function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint) {
    return ownerToNFTokenIdList[_owner][_tokenIndex];
  }

  /// @dev Returns whether the given spender can transfer a given token ID
  /// @param _spender address of the spender to query
  /// @param _tokenId uint ID of the token to be transferred
  /// @return bool whether the msg.sender is approved for the given token ID, is an operator of the owner, or is the owner of the token
  function _isApprovedOrOwner(address _spender, uint _tokenId) internal view returns (bool) {
    address owner = idToOwner[_tokenId];
    bool spenderIsOwner = owner == _spender;
    bool spenderIsApproved = _spender == idToApprovals[_tokenId];
    bool spenderIsApprovedForAll = (ownerToOperators[owner])[_spender];
    return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
  }

  function isApprovedOrOwner(address _spender, uint _tokenId) external view override returns (bool) {
    return _isApprovedOrOwner(_spender, _tokenId);
  }

  /// @dev Add a NFT to an index mapping to a given address
  /// @param _to address of the receiver
  /// @param _tokenId uint ID Of the token to be added
  function _addTokenToOwnerList(address _to, uint _tokenId) internal {
    uint currentCount = _balance(_to);

    ownerToNFTokenIdList[_to][currentCount] = _tokenId;
    tokenToOwnerIndex[_tokenId] = currentCount;
  }

  /// @dev Remove a NFT from an index mapping to a given address
  /// @param _from address of the sender
  /// @param _tokenId uint ID Of the token to be removed
  function _removeTokenFromOwnerList(address _from, uint _tokenId) internal {
    // Delete
    uint currentCount = _balance(_from) - 1;
    uint currentIndex = tokenToOwnerIndex[_tokenId];

    if (currentCount == currentIndex) {
      // update ownerToNFTokenIdList
      ownerToNFTokenIdList[_from][currentCount] = 0;
      // update tokenToOwnerIndex
      tokenToOwnerIndex[_tokenId] = 0;
    } else {
      uint lastTokenId = ownerToNFTokenIdList[_from][currentCount];

      // Add
      // update ownerToNFTokenIdList
      ownerToNFTokenIdList[_from][currentIndex] = lastTokenId;
      // update tokenToOwnerIndex
      tokenToOwnerIndex[lastTokenId] = currentIndex;

      // Delete
      // update ownerToNFTokenIdList
      ownerToNFTokenIdList[_from][currentCount] = 0;
      // update tokenToOwnerIndex
      tokenToOwnerIndex[_tokenId] = 0;
    }
  }

  /// @dev Add a NFT to a given address
  ///      Throws if `_tokenId` is owned by someone.
  function _addTokenTo(address _to, uint _tokenId) internal {
    // assume always call on new tokenId or after _removeTokenFrom() call
    // Change the owner
    idToOwner[_tokenId] = _to;
    // Update owner token index tracking
    _addTokenToOwnerList(_to, _tokenId);
    // Change count tracking
    ownerToNFTokenCount[_to] += 1;
  }

  /// @dev Remove a NFT from a given address
  ///      Throws if `_from` is not the current owner.
  function _removeTokenFrom(address _from, uint _tokenId) internal {
    require(idToOwner[_tokenId] == _from, "!owner remove");
    // Change the owner
    idToOwner[_tokenId] = address(0);
    // Update owner token index tracking
    _removeTokenFromOwnerList(_from, _tokenId);
    // Change count tracking
    ownerToNFTokenCount[_from] -= 1;
  }

  /// @dev Execute transfer of a NFT.
  ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
  ///      address for this NFT. (NOTE: `msg.sender` not allowed in internal function so pass `_sender`.)
  ///      Throws if `_to` is the zero address.
  ///      Throws if `_from` is not the current owner.
  ///      Throws if `_tokenId` is not a valid NFT.
  function _transferFrom(
    address _from,
    address _to,
    uint _tokenId,
    address _sender
  ) internal {
    require(attachments[_tokenId] == 0 && !voted[_tokenId], "attached");
    require(_isApprovedOrOwner(_sender, _tokenId), "!owner sender");
    require(_to != address(0), "dst is zero");
    // from address will be checked in _removeTokenFrom()

    if (idToApprovals[_tokenId] != address(0)) {
      // Reset approvals
      idToApprovals[_tokenId] = address(0);
    }
    _removeTokenFrom(_from, _tokenId);
    _addTokenTo(_to, _tokenId);
    // Set the block of ownership transfer (for Flash NFT protection)
    ownershipChange[_tokenId] = block.number;
    // Log the transfer
    emit Transfer(_from, _to, _tokenId);
  }

  /* TRANSFER FUNCTIONS */
  /// @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
  ///      Throws if `_from` is not the current owner.
  ///      Throws if `_to` is the zero address.
  ///      Throws if `_tokenId` is not a valid NFT.
  /// @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
  ///        they maybe be permanently lost.
  /// @param _from The current owner of the NFT.
  /// @param _to The new owner.
  /// @param _tokenId The NFT to transfer.
  function transferFrom(
    address _from,
    address _to,
    uint _tokenId
  ) external override {
    _transferFrom(_from, _to, _tokenId, msg.sender);
  }

  function _isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.
    uint size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /// @dev Transfers the ownership of an NFT from one address to another address.
  ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
  ///      approved address for this NFT.
  ///      Throws if `_from` is not the current owner.
  ///      Throws if `_to` is the zero address.
  ///      Throws if `_tokenId` is not a valid NFT.
  ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
  ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
  /// @param _from The current owner of the NFT.
  /// @param _to The new owner.
  /// @param _tokenId The NFT to transfer.
  /// @param _data Additional data with no specified format, sent in call to `_to`.
  function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId,
    bytes memory _data
  ) public override {
    _transferFrom(_from, _to, _tokenId, msg.sender);

    if (_isContract(_to)) {
      // Throws if transfer destination is a contract which does not implement 'onERC721Received'
      try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4) {} catch (
        bytes memory reason
      ) {
        if (reason.length == 0) {
          revert('ERC721: transfer to non ERC721Receiver implementer');
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  /// @dev Transfers the ownership of an NFT from one address to another address.
  ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
  ///      approved address for this NFT.
  ///      Throws if `_from` is not the current owner.
  ///      Throws if `_to` is the zero address.
  ///      Throws if `_tokenId` is not a valid NFT.
  ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
  ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
  /// @param _from The current owner of the NFT.
  /// @param _to The new owner.
  /// @param _tokenId The NFT to transfer.
  function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId
  ) external override {
    safeTransferFrom(_from, _to, _tokenId, '');
  }

  /// @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
  ///      Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
  ///      Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
  ///      Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
  /// @param _approved Address to be approved for the given NFT ID.
  /// @param _tokenId ID of the token to be approved.
  function approve(address _approved, uint _tokenId) public override {
    address owner = idToOwner[_tokenId];
    // Throws if `_tokenId` is not a valid NFT
    require(owner != address(0), "invalid id");
    // Throws if `_approved` is the current owner
    require(_approved != owner, "self approve");
    // Check requirements
    bool senderIsOwner = (idToOwner[_tokenId] == msg.sender);
    bool senderIsApprovedForAll = (ownerToOperators[owner])[msg.sender];
    require(senderIsOwner || senderIsApprovedForAll, "!owner");
    // Set the approval
    idToApprovals[_tokenId] = _approved;
    emit Approval(owner, _approved, _tokenId);
  }

  /// @dev Enables or disables approval for a third party ("operator") to manage all of
  ///      `msg.sender`'s assets. It also emits the ApprovalForAll event.
  ///      Throws if `_operator` is the `msg.sender`. (NOTE: This is not written the EIP)
  /// @notice This works even if sender doesn't own any tokens at the time.
  /// @param _operator Address to add to the set of authorized operators.
  /// @param _approved True if the operators is approved, false to revoke approval.
  function setApprovalForAll(address _operator, bool _approved) external override {
    // Throws if `_operator` is the `msg.sender`
    require(_operator != msg.sender, "operator is sender");
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /// @dev Function to mint tokens
  ///      Throws if `_to` is zero address.
  ///      Throws if `_tokenId` is owned by someone.
  /// @param _to The address that will receive the minted tokens.
  /// @param _tokenId The token id to mint.
  /// @return A boolean that indicates if the operation was successful.
  function _mint(address _to, uint _tokenId) internal returns (bool) {
    // Throws if `_to` is zero address
    require(_to != address(0), "zero dst");
    // Add NFT. Throws if `_tokenId` is owned by someone
    _addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
    return true;
  }

  /// @notice Record global and per-user data to checkpoint
  /// @param _tokenId NFT token ID. No user checkpoint if 0
  /// @param oldLocked Pevious locked amount / end lock time for the user
  /// @param newLocked New locked amount / end lock time for the user
  function _checkpoint(
    uint _tokenId,
    LockedBalance memory oldLocked,
    LockedBalance memory newLocked
  ) internal {
    Point memory uOld;
    Point memory uNew;
    int128 oldDSlope = 0;
    int128 newDSlope = 0;
    uint _epoch = epoch;

    if (_tokenId != 0) {
      // Calculate slopes and biases
      // Kept at zero when they have to
      if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
        uOld.slope = oldLocked.amount / I_MAX_TIME;
        uOld.bias = uOld.slope * int128(int256(oldLocked.end - block.timestamp));
      }
      if (newLocked.end > block.timestamp && newLocked.amount > 0) {
        uNew.slope = newLocked.amount / I_MAX_TIME;
        uNew.bias = uNew.slope * int128(int256(newLocked.end - block.timestamp));
      }

      // Read values of scheduled changes in the slope
      // oldLocked.end can be in the past and in the future
      // newLocked.end can ONLY by in the FUTURE unless everything expired: than zeros
      oldDSlope = slopeChanges[oldLocked.end];
      if (newLocked.end != 0) {
        if (newLocked.end == oldLocked.end) {
          newDSlope = oldDSlope;
        } else {
          newDSlope = slopeChanges[newLocked.end];
        }
      }
    }

    Point memory lastPoint = Point({bias : 0, slope : 0, ts : block.timestamp, blk : block.number});
    if (_epoch > 0) {
      lastPoint = _pointHistory[_epoch];
    }
    uint lastCheckpoint = lastPoint.ts;
    // initialLastPoint is used for extrapolation to calculate block number
    // (approximately, for *At methods) and save them
    // as we cannot figure that out exactly from inside the contract
    Point memory initialLastPoint = lastPoint;
    uint blockSlope = 0;
    // dblock/dt
    if (block.timestamp > lastPoint.ts) {
      blockSlope = (MULTIPLIER * (block.number - lastPoint.blk)) / (block.timestamp - lastPoint.ts);
    }
    // If last point is already recorded in this block, slope=0
    // But that's ok b/c we know the block in such case

    // Go over weeks to fill history and calculate what the current point is
    {
      uint ti = (lastCheckpoint / WEEK) * WEEK;
      // Hopefully it won't happen that this won't get used in 5 years!
      // If it does, users will be able to withdraw but vote weight will be broken
      for (uint i = 0; i < 255; ++i) {
        ti += WEEK;
        int128 dSlope = 0;
        if (ti > block.timestamp) {
          ti = block.timestamp;
        } else {
          dSlope = slopeChanges[ti];
        }
        lastPoint.bias = Math.positiveInt128(lastPoint.bias - lastPoint.slope * int128(int256(ti - lastCheckpoint)));
        lastPoint.slope = Math.positiveInt128(lastPoint.slope + dSlope);
        lastCheckpoint = ti;
        lastPoint.ts = ti;
        lastPoint.blk = initialLastPoint.blk + (blockSlope * (ti - initialLastPoint.ts)) / MULTIPLIER;
        _epoch += 1;
        if (ti == block.timestamp) {
          lastPoint.blk = block.number;
          break;
        } else {
          _pointHistory[_epoch] = lastPoint;
        }
      }
    }

    epoch = _epoch;
    // Now pointHistory is filled until t=now

    if (_tokenId != 0) {
      // If last point was in this block, the slope change has been applied already
      // But in such case we have 0 slope(s)
      lastPoint.slope = Math.positiveInt128(lastPoint.slope + (uNew.slope - uOld.slope));
      lastPoint.bias = Math.positiveInt128(lastPoint.bias + (uNew.bias - uOld.bias));
    }

    // Record the changed point into history
    _pointHistory[_epoch] = lastPoint;

    if (_tokenId != 0) {
      // Schedule the slope changes (slope is going down)
      // We subtract newUserSlope from [newLocked.end]
      // and add old_user_slope to [old_locked.end]
      if (oldLocked.end > block.timestamp) {
        // old_dslope was <something> - u_old.slope, so we cancel that
        oldDSlope += uOld.slope;
        if (newLocked.end == oldLocked.end) {
          oldDSlope -= uNew.slope;
          // It was a new deposit, not extension
        }
        slopeChanges[oldLocked.end] = oldDSlope;
      }

      if (newLocked.end > block.timestamp) {
        if (newLocked.end > oldLocked.end) {
          newDSlope -= uNew.slope;
          // old slope disappeared at this point
          slopeChanges[newLocked.end] = newDSlope;
        }
        // else: we recorded it already in oldDSlope
      }
      // Now handle user history
      uint userEpoch = userPointEpoch[_tokenId] + 1;

      userPointEpoch[_tokenId] = userEpoch;
      uNew.ts = block.timestamp;
      uNew.blk = block.number;
      _userPointHistory[_tokenId][userEpoch] = uNew;
    }
  }

  /// @notice Deposit and lock tokens for a user
  /// @param _tokenId NFT that holds lock
  /// @param _value Amount to deposit
  /// @param unlockTime New time when to unlock the tokens, or 0 if unchanged
  /// @param lockedBalance Previous locked amount / timestamp
  /// @param depositType The type of deposit
  function _depositFor(
    uint _tokenId,
    uint _value,
    uint unlockTime,
    LockedBalance memory lockedBalance,
    DepositType depositType
  ) internal {
    LockedBalance memory _locked = lockedBalance;
    uint supplyBefore = supply;

    supply = supplyBefore + _value;
    LockedBalance memory oldLocked;
    (oldLocked.amount, oldLocked.end) = (_locked.amount, _locked.end);
    // Adding to existing lock, or if a lock is expired - creating a new one
    _locked.amount += int128(int256(_value));
    if (unlockTime != 0) {
      _locked.end = unlockTime;
    }
    locked[_tokenId] = _locked;

    // Possibilities:
    // Both old_locked.end could be current or expired (>/< block.timestamp)
    // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
    // _locked.end > block.timestamp (always)
    _checkpoint(_tokenId, oldLocked, _locked);

    address from = msg.sender;
    if (_value != 0 && depositType != DepositType.MERGE_TYPE) {
      IERC20(token).safeTransferFrom(from, address(this), _value);
    }

    emit Deposit(from, _tokenId, _value, _locked.end, depositType, block.timestamp);
    emit Supply(supplyBefore, supplyBefore + _value);
  }

  function voting(uint _tokenId) external override {
    require(msg.sender == _voter(), "!voter");
    voted[_tokenId] = true;
  }

  function abstain(uint _tokenId) external override {
    require(msg.sender == _voter(), "!voter");
    voted[_tokenId] = false;
  }

  function attachToken(uint _tokenId) external override {
    require(msg.sender == _voter(), "!voter");
    attachments[_tokenId] = attachments[_tokenId] + 1;
  }

  function detachToken(uint _tokenId) external override {
    require(msg.sender == _voter(), "!voter");
    attachments[_tokenId] = attachments[_tokenId] - 1;
  }

  function merge(uint _from, uint _to) external {
    require(attachments[_from] == 0 && !voted[_from], "attached");
    require(!voted[_to], "attached");
    require(_from != _to, "the same");
    require(_isApprovedOrOwner(msg.sender, _from), "!owner from");
    require(_isApprovedOrOwner(msg.sender, _to), "!owner to");

    LockedBalance memory _locked0 = locked[_from];
    LockedBalance memory _locked1 = locked[_to];
    uint value0 = uint(int256(_locked0.amount));
    uint end = _locked0.end >= _locked1.end ? _locked0.end : _locked1.end;

    locked[_from] = LockedBalance(0, 0);
    _checkpoint(_from, _locked0, LockedBalance(0, 0));
    _burn(_from);
    _depositFor(_to, value0, end, _locked1, DepositType.MERGE_TYPE);
  }

  function block_number() external view returns (uint) {
    return block.number;
  }

  /// @notice Record global data to checkpoint
  function checkpoint() external override {
    _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
  }

  /// @notice Deposit `_value` tokens for `_tokenId` and add to the lock
  /// @dev Anyone (even a smart contract) can deposit for someone else, but
  ///      cannot extend their locktime and deposit for a brand new user
  /// @param _tokenId lock NFT
  /// @param _value Amount to add to user's lock
  function depositFor(uint _tokenId, uint _value) external lock override {
    require(_value > 0, "zero value");
    LockedBalance memory _locked = locked[_tokenId];
    require(_locked.amount > 0, 'No existing lock found');
    require(_locked.end > block.timestamp, 'Cannot add to expired lock. Withdraw');
    _depositFor(_tokenId, _value, 0, _locked, DepositType.DEPOSIT_FOR_TYPE);
  }

  /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
  /// @param _value Amount to deposit
  /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
  /// @param _to Address to deposit
  function _createLock(uint _value, uint _lockDuration, address _to) internal returns (uint) {
    require(_value > 0, "zero value");
    // Lock time is rounded down to weeks
    uint unlockTime = (block.timestamp + _lockDuration) / WEEK * WEEK;
    require(unlockTime > block.timestamp, 'Can only lock until time in the future');
    require(unlockTime <= block.timestamp + MAX_TIME, 'Voting lock can be 4 years max');

    ++tokenId;
    uint _tokenId = tokenId;
    _mint(_to, _tokenId);

    _depositFor(_tokenId, _value, unlockTime, locked[_tokenId], DepositType.CREATE_LOCK_TYPE);
    return _tokenId;
  }

  /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
  /// @param _value Amount to deposit
  /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
  /// @param _to Address to deposit
  function createLockFor(uint _value, uint _lockDuration, address _to)
  external lock override returns (uint) {
    return _createLock(_value, _lockDuration, _to);
  }

  /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lock_duration`
  /// @param _value Amount to deposit
  /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
  function createLock(uint _value, uint _lockDuration) external lock returns (uint) {
    return _createLock(_value, _lockDuration, msg.sender);
  }

  /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
  /// @param _value Amount of tokens to deposit and add to the lock
  function increaseAmount(uint _tokenId, uint _value) external lock {
    LockedBalance memory _locked = locked[_tokenId];
    require(_locked.amount > 0, 'No existing lock found');
    require(_locked.end > block.timestamp, 'Cannot add to expired lock. Withdraw');
    require(_isApprovedOrOwner(msg.sender, _tokenId), "!owner");
    require(_value > 0, "zero value");

    _depositFor(_tokenId, _value, 0, _locked, DepositType.INCREASE_LOCK_AMOUNT);
  }

  /// @notice Extend the unlock time for `_tokenId`
  /// @param _lockDuration New number of seconds until tokens unlock
  function increaseUnlockTime(uint _tokenId, uint _lockDuration) external lock {
    LockedBalance memory _locked = locked[_tokenId];
    // Lock time is rounded down to weeks
    uint unlockTime = (block.timestamp + _lockDuration) / WEEK * WEEK;
    require(_locked.amount > 0, 'Nothing is locked');
    require(_locked.end > block.timestamp, 'Lock expired');
    require(unlockTime > _locked.end, 'Can only increase lock duration');
    require(unlockTime <= block.timestamp + MAX_TIME, 'Voting lock can be 4 years max');
    require(_isApprovedOrOwner(msg.sender, _tokenId), "!owner");

    _depositFor(_tokenId, 0, unlockTime, _locked, DepositType.INCREASE_UNLOCK_TIME);
  }

  /// @notice Withdraw all tokens for `_tokenId`
  /// @dev Only possible if the lock has expired
  function withdraw(uint _tokenId) external lock {
    require(_isApprovedOrOwner(msg.sender, _tokenId), "!owner");
    require(attachments[_tokenId] == 0 && !voted[_tokenId], "attached");
    LockedBalance memory _locked = locked[_tokenId];
    require(block.timestamp >= _locked.end, "The lock did not expire");

    uint value = uint(int256(_locked.amount));
    locked[_tokenId] = LockedBalance(0, 0);
    uint supplyBefore = supply;
    supply = supplyBefore - value;

    // old_locked can have either expired <= timestamp or zero end
    // _locked has only 0 end
    // Both can have >= 0 amount
    _checkpoint(_tokenId, _locked, LockedBalance(0, 0));

    IERC20(token).safeTransfer(msg.sender, value);

    // Burn the NFT
    _burn(_tokenId);

    emit Withdraw(msg.sender, _tokenId, value, block.timestamp);
    emit Supply(supplyBefore, supplyBefore - value);
  }

  // The following ERC20/minime-compatible methods are not real balanceOf and supply!
  // They measure the weights for the purpose of voting, so they don't represent
  // real coins.

  /// @notice Binary search to estimate timestamp for block number
  /// @param _block Block to find
  /// @param maxEpoch Don't go beyond this epoch
  /// @return Approximate timestamp for block
  function _findBlockEpoch(uint _block, uint maxEpoch) internal view returns (uint) {
    // Binary search
    uint _min = 0;
    uint _max = maxEpoch;
    for (uint i = 0; i < 128; ++i) {
      // Will be always enough for 128-bit numbers
      if (_min >= _max) {
        break;
      }
      uint _mid = (_min + _max + 1) / 2;
      if (_pointHistory[_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    return _min;
  }

  /// @notice Get the current voting power for `_tokenId`
  /// @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
  /// @param _tokenId NFT for lock
  /// @param _t Epoch time to return voting power at
  /// @return User voting power
  function _balanceOfNFT(uint _tokenId, uint _t) internal view returns (uint) {
    uint _epoch = userPointEpoch[_tokenId];
    if (_epoch == 0) {
      return 0;
    } else {
      Point memory lastPoint = _userPointHistory[_tokenId][_epoch];
      lastPoint.bias -= lastPoint.slope * int128(int256(_t) - int256(lastPoint.ts));
      if (lastPoint.bias < 0) {
        lastPoint.bias = 0;
      }
      return uint(int256(lastPoint.bias));
    }
  }

  /// @dev Returns current token URI metadata
  /// @param _tokenId Token ID to fetch URI for.
  function tokenURI(uint _tokenId) external view override returns (string memory) {
    require(idToOwner[_tokenId] != address(0), "Query for nonexistent token");
    LockedBalance memory _locked = locked[_tokenId];
    return
    _tokenURI(
      _tokenId,
      _balanceOfNFT(_tokenId, block.timestamp),
      _locked.end,
      uint(int256(_locked.amount))
    );
  }

  function balanceOfNFT(uint _tokenId) external view override returns (uint) {
    // flash NFT protection
    if (ownershipChange[_tokenId] == block.number) {
      return 0;
    }
    return _balanceOfNFT(_tokenId, block.timestamp);
  }

  function balanceOfNFTAt(uint _tokenId, uint _t) external view returns (uint) {
    return _balanceOfNFT(_tokenId, _t);
  }

  /// @notice Measure voting power of `_tokenId` at block height `_block`
  /// @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
  /// @param _tokenId User's wallet NFT
  /// @param _block Block to calculate the voting power at
  /// @return Voting power
  function _balanceOfAtNFT(uint _tokenId, uint _block) internal view returns (uint) {
    // Copying and pasting totalSupply code because Vyper cannot pass by
    // reference yet
    require(_block <= block.number, "only old block");

    // Binary search
    uint _min = 0;
    uint _max = userPointEpoch[_tokenId];
    for (uint i = 0; i < 128; ++i) {
      // Will be always enough for 128-bit numbers
      if (_min >= _max) {
        break;
      }
      uint _mid = (_min + _max + 1) / 2;
      if (_userPointHistory[_tokenId][_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }

    Point memory uPoint = _userPointHistory[_tokenId][_min];

    uint maxEpoch = epoch;
    uint _epoch = _findBlockEpoch(_block, maxEpoch);
    Point memory point0 = _pointHistory[_epoch];
    uint dBlock = 0;
    uint dt = 0;
    if (_epoch < maxEpoch) {
      Point memory point1 = _pointHistory[_epoch + 1];
      dBlock = point1.blk - point0.blk;
      dt = point1.ts - point0.ts;
    } else {
      dBlock = block.number - point0.blk;
      dt = block.timestamp - point0.ts;
    }
    uint blockTime = point0.ts;
    if (dBlock != 0 && _block > point0.blk) {
      blockTime += (dt * (_block - point0.blk)) / dBlock;
    }

    uPoint.bias -= uPoint.slope * int128(int256(blockTime - uPoint.ts));
    return uint(uint128(Math.positiveInt128(uPoint.bias)));
  }

  function balanceOfAtNFT(uint _tokenId, uint _block) external view returns (uint) {
    return _balanceOfAtNFT(_tokenId, _block);
  }

  /// @notice Calculate total voting power at some point in the past
  /// @param point The point (bias/slope) to start search from
  /// @param t Time to calculate the total voting power at
  /// @return Total voting power at that time
  function _supplyAt(Point memory point, uint t) internal view returns (uint) {
    Point memory lastPoint = point;
    uint ti = (lastPoint.ts / WEEK) * WEEK;
    for (uint i = 0; i < 255; ++i) {
      ti += WEEK;
      int128 dSlope = 0;
      if (ti > t) {
        ti = t;
      } else {
        dSlope = slopeChanges[ti];
      }
      lastPoint.bias -= lastPoint.slope * int128(int256(ti - lastPoint.ts));
      if (ti == t) {
        break;
      }
      lastPoint.slope += dSlope;
      lastPoint.ts = ti;
    }
    return uint(uint128(Math.positiveInt128(lastPoint.bias)));
  }

  /// @notice Calculate total voting power
  /// @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
  /// @return Total voting power
  function totalSupplyAtT(uint t) public view returns (uint) {
    uint _epoch = epoch;
    Point memory lastPoint = _pointHistory[_epoch];
    return _supplyAt(lastPoint, t);
  }

  function totalSupply() external view returns (uint) {
    return totalSupplyAtT(block.timestamp);
  }

  /// @notice Calculate total voting power at some point in the past
  /// @param _block Block to calculate the total voting power at
  /// @return Total voting power at `_block`
  function totalSupplyAt(uint _block) external view returns (uint) {
    require(_block <= block.number, "only old blocks");
    uint _epoch = epoch;
    uint targetEpoch = _findBlockEpoch(_block, _epoch);

    Point memory point = _pointHistory[targetEpoch];
    // it is possible only for a block before the launch
    // return 0 as more clear answer than revert
    if (point.blk > _block) {
      return 0;
    }
    uint dt = 0;
    if (targetEpoch < _epoch) {
      Point memory point_next = _pointHistory[targetEpoch + 1];
      // next point block can not be the same or lower
      dt = ((_block - point.blk) * (point_next.ts - point.ts)) / (point_next.blk - point.blk);
    } else {
      if (point.blk != block.number) {
        dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
      }
    }
    // Now dt contains info on how far are we beyond point
    return _supplyAt(point, point.ts + dt);
  }

  function _tokenURI(uint _tokenId, uint _balanceOf, uint _locked_end, uint _value) internal pure returns (string memory output) {
    output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: black; font-family: Impact; font-size: 50px; }</style><rect width="100%" height="100%" fill="#aaaaff" /><text x="10" y="60" class="base">';
    output = string(abi.encodePacked(output, "token ", _toString(_tokenId), '</text><text x="10" y="150" class="base">'));
    output = string(abi.encodePacked(output, "balanceOf ", _toString(_balanceOf), '</text><text x="10" y="230" class="base">'));
    output = string(abi.encodePacked(output, "locked_end ", _toString(_locked_end), '</text><text x="10" y="310" class="base">'));
    output = string(abi.encodePacked(output, "value ", _toString(_value), '</text></svg>'));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "lock #', _toString(_tokenId), '", "description": "Flair Dex locks, can be used to boost gauge yields, vote on token emission, and receive bribes", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    output = string(abi.encodePacked('data:application/json;base64,', json));
  }

  function _toString(uint value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint temp = value;
    uint digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function _burn(uint _tokenId) internal {
    address owner = ownerOf(_tokenId);
    // Clear approval
    approve(address(0), _tokenId);
    // Remove token
    _removeTokenFrom(msg.sender, _tokenId);
    emit Transfer(owner, address(0), _tokenId);
  }

  function userPointHistory(uint _tokenId, uint _loc) external view override returns (Point memory) {
    return _userPointHistory[_tokenId][_loc];
  }

  function pointHistory(uint _loc) external view override returns (Point memory) {
    return _pointHistory[_loc];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../lib/Math.sol";
import "../../interface/IERC20.sol";
import "../../interface/IVeDist.sol";
import "../../interface/IVe.sol";
import "../../lib/SafeERC20.sol";

contract VeDist is IVeDist {
  using SafeERC20 for IERC20;

  event CheckpointToken(
    uint time,
    uint tokens
  );

  event Claimed(
    uint tokenId,
    uint amount,
    uint claimEpoch,
    uint maxEpoch
  );

  struct ClaimCalculationResult {
    uint toDistribute;
    uint userEpoch;
    uint weekCursor;
    uint maxUserEpoch;
    bool success;
  }


  uint constant WEEK = 7 * 86400;

  uint public startTime;
  uint public timeCursor;
  mapping(uint => uint) public timeCursorOf;
  mapping(uint => uint) public userEpochOf;

  uint public lastTokenTime;
  uint[1000000000000000] public tokensPerWeek;

  address public votingEscrow;
  address public token;
  uint public tokenLastBalance;

  uint[1000000000000000] public veSupply;

  address public depositor;

  constructor(address _votingEscrow) {
    uint _t = block.timestamp / WEEK * WEEK;
    startTime = _t;
    lastTokenTime = _t;
    timeCursor = _t;
    address _token = IVe(_votingEscrow).token();
    token = _token;
    votingEscrow = _votingEscrow;
    depositor = msg.sender;
    IERC20(_token).safeIncreaseAllowance(_votingEscrow, type(uint).max);
  }

  function timestamp() external view returns (uint) {
    return block.timestamp / WEEK * WEEK;
  }

  function _checkpointToken() internal {
    uint tokenBalance = IERC20(token).balanceOf(address(this));
    uint toDistribute = tokenBalance - tokenLastBalance;
    tokenLastBalance = tokenBalance;

    uint t = lastTokenTime;
    uint sinceLast = block.timestamp - t;
    lastTokenTime = block.timestamp;
    uint thisWeek = t / WEEK * WEEK;
    uint nextWeek = 0;

    for (uint i = 0; i < 20; i++) {
      nextWeek = thisWeek + WEEK;
      if (block.timestamp < nextWeek) {
        tokensPerWeek[thisWeek] += _adjustToDistribute(toDistribute, block.timestamp, t, sinceLast);
        break;
      } else {
        tokensPerWeek[thisWeek] += _adjustToDistribute(toDistribute, nextWeek, t, sinceLast);
      }
      t = nextWeek;
      thisWeek = nextWeek;
    }
    emit CheckpointToken(block.timestamp, toDistribute);
  }

  /// @dev For testing purposes.
  function adjustToDistribute(
    uint toDistribute,
    uint t0,
    uint t1,
    uint sinceLastCall
  ) external pure returns (uint) {
    return _adjustToDistribute(
      toDistribute,
      t0,
      t1,
      sinceLastCall
    );
  }

  function _adjustToDistribute(
    uint toDistribute,
    uint t0,
    uint t1,
    uint sinceLast
  ) internal pure returns (uint) {
    if (t0 <= t1 || t0 - t1 == 0 || sinceLast == 0) {
      return toDistribute;
    }
    return toDistribute * (t0 - t1) / sinceLast;
  }

  function checkpointToken() external override {
    require(msg.sender == depositor, "!depositor");
    _checkpointToken();
  }

  function _findTimestampEpoch(address ve, uint _timestamp) internal view returns (uint) {
    uint _min = 0;
    uint _max = IVe(ve).epoch();
    for (uint i = 0; i < 128; i++) {
      if (_min >= _max) break;
      uint _mid = (_min + _max + 2) / 2;
      IVe.Point memory pt = IVe(ve).pointHistory(_mid);
      if (pt.ts <= _timestamp) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    return _min;
  }

  function findTimestampUserEpoch(address ve, uint tokenId, uint _timestamp, uint maxUserEpoch) external view returns (uint) {
    return _findTimestampUserEpoch(ve, tokenId, _timestamp, maxUserEpoch);
  }

  function _findTimestampUserEpoch(address ve, uint tokenId, uint _timestamp, uint maxUserEpoch) internal view returns (uint) {
    uint _min = 0;
    uint _max = maxUserEpoch;
    for (uint i = 0; i < 128; i++) {
      if (_min >= _max) break;
      uint _mid = (_min + _max + 2) / 2;
      IVe.Point memory pt = IVe(ve).userPointHistory(tokenId, _mid);
      if (pt.ts <= _timestamp) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    return _min;
  }

  function veForAt(uint _tokenId, uint _timestamp) external view returns (uint) {
    address ve = votingEscrow;
    uint maxUserEpoch = IVe(ve).userPointEpoch(_tokenId);
    uint epoch = _findTimestampUserEpoch(ve, _tokenId, _timestamp, maxUserEpoch);
    IVe.Point memory pt = IVe(ve).userPointHistory(_tokenId, epoch);
    return uint(int256(Math.positiveInt128(pt.bias - pt.slope * (int128(int256(_timestamp - pt.ts))))));
  }

  function _checkpointTotalSupply() internal {
    address ve = votingEscrow;
    uint t = timeCursor;
    uint roundedTimestamp = block.timestamp / WEEK * WEEK;
    IVe(ve).checkpoint();

    // assume will be called more frequently than 20 weeks
    for (uint i = 0; i < 20; i++) {
      if (t > roundedTimestamp) {
        break;
      } else {
        uint epoch = _findTimestampEpoch(ve, t);
        IVe.Point memory pt = IVe(ve).pointHistory(epoch);
        veSupply[t] = _adjustVeSupply(t, pt.ts, pt.bias, pt.slope);
      }
      t += WEEK;
    }
    timeCursor = t;
  }

  function adjustVeSupply(uint t, uint ptTs, int128 ptBias, int128 ptSlope) external pure returns (uint) {
    return _adjustVeSupply(t, ptTs, ptBias, ptSlope);
  }

  function _adjustVeSupply(uint t, uint ptTs, int128 ptBias, int128 ptSlope) internal pure returns (uint) {
    if (t < ptTs) {
      return 0;
    }
    int128 dt = int128(int256(t - ptTs));
    if (ptBias < ptSlope * dt) {
      return 0;
    }
    return uint(int256(Math.positiveInt128(ptBias - ptSlope * dt)));
  }

  function checkpointTotalSupply() external override {
    _checkpointTotalSupply();
  }

  function _claim(uint _tokenId, address ve, uint _lastTokenTime) internal returns (uint) {
    ClaimCalculationResult memory result = _calculateClaim(_tokenId, ve, _lastTokenTime);
    if (result.success) {
      userEpochOf[_tokenId] = result.userEpoch;
      timeCursorOf[_tokenId] = result.weekCursor;
      emit Claimed(_tokenId, result.toDistribute, result.userEpoch, result.maxUserEpoch);
    }
    return result.toDistribute;
  }

  function _calculateClaim(uint _tokenId, address ve, uint _lastTokenTime) internal view returns (ClaimCalculationResult memory) {
    uint userEpoch;
    uint toDistribute;
    uint maxUserEpoch = IVe(ve).userPointEpoch(_tokenId);
    uint _startTime = startTime;

    if (maxUserEpoch == 0) {
      return ClaimCalculationResult(0, 0, 0, 0, false);
    }

    uint weekCursor = timeCursorOf[_tokenId];

    if (weekCursor == 0) {
      userEpoch = _findTimestampUserEpoch(ve, _tokenId, _startTime, maxUserEpoch);
    } else {
      userEpoch = userEpochOf[_tokenId];
    }

    if (userEpoch == 0) userEpoch = 1;

    IVe.Point memory userPoint = IVe(ve).userPointHistory(_tokenId, userEpoch);
    if (weekCursor == 0) {
      weekCursor = (userPoint.ts + WEEK - 1) / WEEK * WEEK;
    }
    if (weekCursor >= lastTokenTime) {
      return ClaimCalculationResult(0, 0, 0, 0, false);
    }
    if (weekCursor < _startTime) {
      weekCursor = _startTime;
    }

    IVe.Point memory oldUserPoint;
    {
      for (uint i = 0; i < 50; i++) {
        if (weekCursor >= _lastTokenTime) {
          break;
        }
        if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
          userEpoch += 1;
          oldUserPoint = userPoint;
          if (userEpoch > maxUserEpoch) {
            userPoint = IVe.Point(0, 0, 0, 0);
          } else {
            userPoint = IVe(ve).userPointHistory(_tokenId, userEpoch);
          }
        } else {
          int128 dt = int128(int256(weekCursor - oldUserPoint.ts));
          uint balanceOf = uint(int256(Math.positiveInt128(oldUserPoint.bias - dt * oldUserPoint.slope)));
          if (balanceOf == 0 && userEpoch > maxUserEpoch) {
            break;
          }
          toDistribute += balanceOf * tokensPerWeek[weekCursor] / veSupply[weekCursor];
          weekCursor += WEEK;
        }
      }
    }
    return ClaimCalculationResult(
      toDistribute,
      Math.min(maxUserEpoch, userEpoch - 1),
      weekCursor,
      maxUserEpoch,
      true
    );
  }

  function claimable(uint _tokenId) external view returns (uint) {
    uint _lastTokenTime = lastTokenTime / WEEK * WEEK;
    ClaimCalculationResult memory result = _calculateClaim(_tokenId, votingEscrow, _lastTokenTime);
    return result.toDistribute;
  }

  function claim(uint _tokenId) external returns (uint) {
    if (block.timestamp >= timeCursor) _checkpointTotalSupply();
    uint _lastTokenTime = lastTokenTime;
    _lastTokenTime = _lastTokenTime / WEEK * WEEK;
    uint amount = _claim(_tokenId, votingEscrow, _lastTokenTime);
    if (amount != 0) {
      IVe(votingEscrow).depositFor(_tokenId, amount);
      tokenLastBalance -= amount;
    }
    return amount;
  }

  function claimMany(uint[] memory _tokenIds) external returns (bool) {
    if (block.timestamp >= timeCursor) _checkpointTotalSupply();
    uint _lastTokenTime = lastTokenTime;
    _lastTokenTime = _lastTokenTime / WEEK * WEEK;
    address _votingEscrow = votingEscrow;
    uint total = 0;

    for (uint i = 0; i < _tokenIds.length; i++) {
      uint _tokenId = _tokenIds[i];
      if (_tokenId == 0) break;
      uint amount = _claim(_tokenId, _votingEscrow, _lastTokenTime);
      if (amount != 0) {
        IVe(_votingEscrow).depositFor(_tokenId, amount);
        total += amount;
      }
    }
    if (total != 0) {
      tokenLastBalance -= total;
    }

    return true;
  }

  // Once off event on contract initialize
  function setDepositor(address _depositor) external {
    require(msg.sender == depositor, "!depositor");
    depositor = _depositor;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./interface/IController.sol";

contract Controller is IController {

  address public governance;
  address public pendingGovernance;

  address public veDist;
  address public voter;

  event SetGovernance(address value);
  event SetVeDist(address value);
  event SetVoter(address value);

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGov() {
    require(msg.sender == governance, "Not gov");
    _;
  }

  function setGovernance(address _value) external onlyGov {
    pendingGovernance = _value;
    emit SetGovernance(_value);
  }

  function acceptGovernance() external {
    require(msg.sender == pendingGovernance, "Not pending gov");
    governance = pendingGovernance;
  }

  function setVeDist(address _value) external onlyGov {
    veDist = _value;
    emit SetVeDist(_value);
  }

  function setVoter(address _value) external onlyGov {
    voter = _value;
    emit SetVoter(_value);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IBribe {

  function notifyRewardAmount(address token, uint amount) external;

  function _deposit(uint amount, uint tokenId) external;

  function _withdraw(uint amount, uint tokenId) external;

  function getRewardForOwner(uint tokenId, address[] memory tokens) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IBribeFactory {
  function createBribe(address[] memory _allowedRewardTokens) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ICallee {
  function hook(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IController {

  function veDist() external view returns (address);

  function voter() external view returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC721.sol";

/**
* @title ERC-721 Non-Fungible Token Standard, optional metadata extension
* @dev See https://eips.ethereum.org/EIPS/eip-721
*/
interface IERC721Metadata is IERC721 {
  /**
  * @dev Returns the token collection name.
  */
  function name() external view returns (string memory);

  /**
  * @dev Returns the token collection symbol.
  */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
  */
  function tokenURI(uint tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
  /**
   * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
   * by `operator` from `from`, this function is called.
   *
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   *
   * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC20.sol";

interface IFLDX is IERC20 {

    function claim(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IGauge {

  function notifyRewardAmount(address token, uint amount) external;

  function getReward(address account, address[] memory tokens) external;

  function claimFees() external returns (uint claimed0, uint claimed1);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IGaugeFactory {
  function createGauge(
    address _pool,
    address _bribe,
    address _ve,
    address[] memory _allowedRewardTokens
  ) external returns (address);

  function createGaugeSingle(
    address _pool,
    address _bribe,
    address _ve,
    address _voter,
    address[] memory _allowedRewardTokens
  ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IMinter {

  function updatePeriod() external returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IMultiRewardsPool {

  function underlying() external view returns (address);

  function derivedSupply() external view returns (uint);

  function derivedBalances(address account) external view returns (uint);

  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function rewardTokens(uint id) external view returns (address);

  function isRewardToken(address token) external view returns (bool);

  function rewardTokensLength() external view returns (uint);

  function derivedBalance(address account) external view returns (uint);

  function left(address token) external view returns (uint);

  function earned(address token, address account) external view returns (uint);

  function registerRewardToken(address token) external;

  function removeRewardToken(address token) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IRouterOld {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IUnderlying {
  function approve(address spender, uint value) external returns (bool);

  function mint(address, uint) external;

  function totalSupply() external view returns (uint);

  function balanceOf(address) external view returns (uint);

  function transfer(address, uint) external returns (bool);

  function decimals() external returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVe {

  enum DepositType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME,
    MERGE_TYPE
  }

  struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint ts;
    uint blk; // block
  }
  /* We cannot really do block numbers per se b/c slope is per time, not per block
  * and per block could be fairly bad b/c Ethereum changes blocktimes.
  * What we can do is to extrapolate ***At functions */

  struct LockedBalance {
    int128 amount;
    uint end;
  }

  function token() external view returns (address);

  function balanceOfNFT(uint) external view returns (uint);

  function isApprovedOrOwner(address, uint) external view returns (bool);

  function createLockFor(uint, uint, address) external returns (uint);

  function userPointEpoch(uint tokenId) external view returns (uint);

  function epoch() external view returns (uint);

  function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);

  function pointHistory(uint loc) external view returns (Point memory);

  function checkpoint() external;

  function depositFor(uint tokenId, uint value) external;

  function attachToken(uint tokenId) external;

  function detachToken(uint tokenId) external;

  function voting(uint tokenId) external;

  function abstain(uint tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVeDist {

  function checkpointToken() external;

  function checkpointTotalSupply() external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVoter {

  function ve() external view returns (address);

  function attachTokenToGauge(uint _tokenId, address account) external;

  function detachTokenFromGauge(uint _tokenId, address account) external;

  function emitDeposit(uint _tokenId, address account, uint amount) external;

  function emitWithdraw(uint _tokenId, address account, uint amount) external;

  function distribute(address _gauge) external;

  function notifyRewardAmount(uint amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IWAVAX {
  function name() external view returns (string memory);

  function approve(address guy, uint256 wad) external returns (bool);

  function totalSupply() external view returns (uint256);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);

  function withdraw(uint256 wad) external;

  function decimals() external view returns (uint8);

  function balanceOf(address) external view returns (uint256);

  function symbol() external view returns (string memory);

  function transfer(address dst, uint256 wad) external returns (bool);

  function deposit() external payable;

  function allowance(address, address) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.13;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

library CheckpointLib {

  /// @notice A checkpoint for uint value
  struct Checkpoint {
    uint timestamp;
    uint value;
  }

  function findLowerIndex(mapping(uint => Checkpoint) storage checkpoints, uint size, uint timestamp) internal view returns (uint) {
    require(size != 0, "Empty checkpoints");

    // First check most recent value
    if (checkpoints[size - 1].timestamp <= timestamp) {
      return (size - 1);
    }

    // Next check implicit zero value
    if (checkpoints[0].timestamp > timestamp) {
      return 0;
    }

    uint lower = 0;
    uint upper = size - 1;
    while (upper > lower) {
      // ceil, avoiding overflow
      uint center = upper - (upper - lower) / 2;
      Checkpoint memory cp = checkpoints[center];
      if (cp.timestamp == timestamp) {
        return center;
      } else if (cp.timestamp < timestamp) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return lower;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.13;

import "../interface/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint value
  ) internal {
    uint newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../interface/IPair.sol";
import "../interface/IRouter.sol";
import "../interface/IRouterOld.sol";
import "../interface/IFactory.sol";
import "../interface/IERC20.sol";
import "../interface/IUniswapV2Factory.sol";
import "../lib/SafeERC20.sol";

contract Migrator {
  using SafeERC20 for IERC20;

  IUniswapV2Factory public oldFactory;
  IRouter public router;

  constructor(IUniswapV2Factory _oldFactory, IRouter _router) {
    oldFactory = _oldFactory;
    router = _router;
  }

  function getOldPair(address tokenA, address tokenB) external view returns (address) {
    return oldFactory.getPair(tokenA, tokenB);
  }

  function migrateWithPermit(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    IPair pair = IPair(oldFactory.getPair(tokenA, tokenB));
    pair.permit(msg.sender, address(this), liquidity, deadline, v, r, s);

    migrate(tokenA, tokenB, stable, liquidity, amountAMin, amountBMin, deadline);
  }

  // msg.sender should have approved "liquidity" amount of LP token of "tokenA" and "tokenB"
  function migrate(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    uint deadline
  ) public {
    require(deadline >= block.timestamp, "Migrator: EXPIRED");

    // Remove liquidity from the old router with permit
    (uint amountA, uint amountB) = removeLiquidity(
      tokenA,
      tokenB,
      liquidity,
      amountAMin,
      amountBMin
    );

    // Add liquidity to the new router
    (uint pooledAmountA, uint pooledAmountB) = addLiquidity(tokenA, tokenB, stable, amountA, amountB);

    // Send remaining tokens to msg.sender
    if (amountA > pooledAmountA) {
      IERC20(tokenA).safeTransfer(msg.sender, amountA - pooledAmountA);
    }
    if (amountB > pooledAmountB) {
      IERC20(tokenB).safeTransfer(msg.sender, amountB - pooledAmountB);
    }
  }

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin
  ) public returns (uint amountA, uint amountB) {
    IPair pair = IPair(oldFactory.getPair(tokenA, tokenB));
    IERC20(address(pair)).safeTransferFrom(msg.sender, address(pair), liquidity);
    (uint amount0, uint amount1) = pair.burn(address(this));
    (address token0,) = sortTokens(tokenA, tokenB);
    (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    require(amountA >= amountAMin, "Migrator: INSUFFICIENT_A_AMOUNT");
    require(amountB >= amountBMin, "Migrator: INSUFFICIENT_B_AMOUNT");
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired
  ) internal returns (uint amountA, uint amountB) {
    (amountA, amountB) = _addLiquidity(tokenA, tokenB, stable, amountADesired, amountBDesired);
    address pair = router.pairFor(tokenA, tokenB, stable);
    IERC20(tokenA).safeTransfer(pair, amountA);
    IERC20(tokenB).safeTransfer(pair, amountB);
    IPair(pair).mint(msg.sender);
  }

  function _addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired
  ) internal returns (uint amountA, uint amountB) {
    // create the pair if it doesn"t exist yet
    IFactory factory = IFactory(router.factory());
    if (factory.getPair(tokenA, tokenB, stable) == address(0)) {
      factory.createPair(tokenA, tokenB, stable);
    }
    (uint reserveA, uint reserveB) = _getReserves(router.factory(), tokenA, tokenB, stable);
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
    require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "ZERO_ADDRESS");
  }

  // fetches and sorts the reserves for a pair
  function _getReserves(address factory, address tokenA, address tokenB, bool stable) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IPair(IFactory(factory).getPair(tokenA, tokenB, stable)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) public pure returns (uint amountB) {
    require(amountA > 0, "INSUFFICIENT_AMOUNT");
    require(reserveA > 0 && reserveB > 0, "INSUFFICIENT_LIQUIDITY");
    amountB = amountA * (reserveB) / reserveA;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../lib/SafeERC20.sol";

contract BrokenToken {

  function transfer(address _to, uint256 _value) external pure {
  }

  function testBrokenTransfer() external {
    SafeERC20.safeTransfer(IERC20(address(this)), address(this), 1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract BrokenWAVAX {

  uint public i;

  string public symbol;
  string public name;
  uint256 public decimals;
  uint256 public totalSupply = 0;

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  event Transfer(address from, address to, uint256 value);
  event Approval(address owner, address spender, uint256 value);
  event LogChangeVault(address indexed oldVault, address indexed newVault, uint indexed effectiveTime);

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint) public nonces;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _decimals,
    address
  ) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    uint chainId;
    assembly {
      chainId := chainid()
    }
    {
      DOMAIN_SEPARATOR = keccak256(
        abi.encode(
          keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
          keccak256(bytes(name)),
          keccak256(bytes('1')),
          chainId,
          address(this)
        )
      );
      _mint(msg.sender, 0);
    }
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(deadline >= block.timestamp, 'StableV1: EXPIRED');
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
      )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, 'StableV1: INVALID_SIGNATURE');
    allowance[owner][spender] = value;

    emit Approval(owner, spender, value);
  }

  function token() external view returns (address) {
    return address(this);
  }

  function balance(address account) external view returns (uint) {
    return balanceOf[account];
  }

  function claimFees() external pure returns (uint, uint) {
    return (0, 0);
  }

  function _mint(address _to, uint _amount) internal returns (bool) {
    balanceOf[_to] += _amount;
    totalSupply += _amount;
    emit Transfer(address(0x0), _to, _amount);
    return true;
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _value
  ) internal returns (bool) {
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    return _transfer(msg.sender, _to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) {
    uint256 allowed_from = allowance[_from][msg.sender];
    require(allowance[_from][msg.sender] >= _value, "Not enough allowance");
    if (allowed_from != type(uint).max) {
      allowance[_from][msg.sender] -= _value;
    }
    return _transfer(_from, _to, _value);
  }

  function mint(address account, uint256 amount) external returns (bool) {
    _mint(account, amount);
    return true;
  }

  function burn(address account, uint256 amount) public returns (bool) {
    totalSupply -= amount;
    balanceOf[account] -= amount;

    emit Transfer(account, address(0), amount);
    return true;
  }

  // Error Code: No error.
  uint256 public constant ERR_NO_ERROR = 0x0;

  // Error Code: Non-zero value expected to perform the function.
  uint256 public constant ERR_INVALID_ZERO_VALUE = 0x01;

  // deposit wraps received FTM tokens as wFTM in 1:1 ratio by minting
  // the received amount of FTMs in wFTM on the sender's address.
  function deposit() public payable returns (uint256) {
    // there has to be some value to be converted
    if (msg.value == 0) {
      return ERR_INVALID_ZERO_VALUE;
    }

    // we already received FTMs, mint the appropriate amount of wFTM
    _mint(msg.sender, msg.value);

    // all went well here
    return ERR_NO_ERROR;
  }

  // withdraw unwraps FTM tokens by burning specified amount
  // of wFTM from the caller address and sending the same amount
  // of FTMs back in exchange.
  function withdraw(uint256 amount) public returns (uint256) {
    // there has to be some value to be converted
    if (amount == 0) {
      return ERR_INVALID_ZERO_VALUE;
    }

    // burn wFTM from the sender first to prevent re-entrance issue
    burn(msg.sender, amount);

    // if wFTM were burned, transfer native tokens back to the sender
//    payable(msg.sender).transfer(amount);

    // all went well here
    return ERR_INVALID_ZERO_VALUE;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../base/core/FldxPair.sol";
import "../base/vote/Ve.sol";
import "../interface/IVeDist.sol";

contract ContractTestHelper is IERC721Receiver {
  using SafeERC20 for IERC20;
  using Math for uint;

  function pairCurrentTwice(address pair, address tokenIn, uint amountIn) external returns (uint, uint){
    uint c0 = FldxPair(pair).current(tokenIn, amountIn);
    FldxPair(pair).sync();
    uint c1 = FldxPair(pair).current(tokenIn, amountIn);
    return (c0, c1);
  }

  function hook(address, uint amount0, uint amount1, bytes calldata data) external {
    address pair = abi.decode(data, (address));
    (address token0, address token1) = FldxPair(pair).tokens();
    if (amount0 != 0) {
      IERC20(token0).safeTransfer(pair, amount0);
    }
    if (amount1 != 0) {
      IERC20(token1).safeTransfer(pair, amount1);
    }
  }

  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
    // without fee
    uint amountInWithFee = amountIn * 1000;
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = reserveIn * 1000 + amountInWithFee;
    amountOut = numerator / denominator;
  }

  function veFlashTransfer(address ve, uint tokenId) external {
    Ve(ve).safeTransferFrom(msg.sender, address(this), tokenId);
    require(Ve(ve).balanceOfNFT(tokenId) == 0, "not zero balance");
    Ve(ve).tokenURI(tokenId);
    Ve(ve).totalSupplyAt(block.number);
    Ve(ve).checkpoint();
    Ve(ve).checkpoint();
    Ve(ve).checkpoint();
    Ve(ve).checkpoint();
    Ve(ve).totalSupplyAt(block.number);
    Ve(ve).totalSupplyAt(block.number - 1);
    Ve(ve).safeTransferFrom(address(this), msg.sender, tokenId);
  }

  function multipleVeDistCheckpoints(address veDist) external {
    IVeDist(veDist).checkpointToken();
    IVeDist(veDist).checkpointToken();
    IVeDist(veDist).checkpointTotalSupply();
    IVeDist(veDist).checkpointTotalSupply();
  }

  function closeTo(uint a, uint b, uint target) external pure returns (bool){
    return a.closeTo(b, target);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../base/core/FldxPair.sol";
import "../base/vote/Ve.sol";

contract ContractTestHelper2 is IERC721Receiver {
  using SafeERC20 for IERC20;

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    revert("stub revert");
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/// @title Multicall2 - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

contract Multicall2 {
  struct Call {
    address target;
    bytes callData;
  }
  struct Result {
    bool success;
    bytes returnData;
  }

  function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
    blockNumber = block.number;
    returnData = new bytes[](calls.length);
    for(uint256 i = 0; i < calls.length; i++) {
      (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
      require(success, "Multicall aggregate: call failed");
      returnData[i] = ret;
    }
  }
  function blockAndAggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
    (blockNumber, blockHash, returnData) = tryBlockAndAggregate(true, calls);
  }
  function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
    blockHash = blockhash(blockNumber);
  }
  function getBlockNumber() public view returns (uint256 blockNumber) {
    blockNumber = block.number;
  }
  function getCurrentBlockCoinbase() public view returns (address coinbase) {
    coinbase = block.coinbase;
  }
  function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
    difficulty = block.difficulty;
  }
  function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
    gaslimit = block.gaslimit;
  }
  function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
    timestamp = block.timestamp;
  }
  function getEthBalance(address addr) public view returns (uint256 balance) {
    balance = addr.balance;
  }
  function getLastBlockHash() public view returns (bytes32 blockHash) {
    blockHash = blockhash(block.number - 1);
  }
  function tryAggregate(bool requireSuccess, Call[] memory calls) public returns (Result[] memory returnData) {
    returnData = new Result[](calls.length);
    for(uint256 i = 0; i < calls.length; i++) {
      (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);

      if (requireSuccess) {
        require(success, "Multicall2 aggregate: call failed");
      }

      returnData[i] = Result(success, ret);
    }
  }
  function tryBlockAndAggregate(bool requireSuccess, Call[] memory calls) public returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
    blockNumber = block.number;
    blockHash = blockhash(block.number);
    returnData = tryAggregate(requireSuccess, calls);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../base/reward/MultiRewardsPoolBase.sol";


contract MultiRewardsPoolMock is MultiRewardsPoolBase {

  constructor(
    address _stake,
    address _operator,
    address[] memory _rewards
  ) MultiRewardsPoolBase(_stake, _operator, _rewards) {}

  // for test 2 deposits in one tx
  function testDoubleDeposit(uint amount) external {
    uint amount0 = amount / 2;
    uint amount1 = amount - amount0;
    _deposit(amount0);
    _deposit(amount1);
  }

  // for test 2 withdraws in one tx
  function testDoubleWithdraw(uint amount) external {
    uint amount0 = amount / 2;
    uint amount1 = amount - amount0;
    _withdraw(amount0);
    _withdraw(amount1);
  }

  function deposit(uint amount) external {
    _deposit(amount);
  }

  function withdraw(uint amount) external {
    _withdraw(amount);
  }

  function getReward(address account, address[] memory tokens) external {
    require(msg.sender == account, "Forbidden");
    _getReward(account, tokens, account);
  }

  function notifyRewardAmount(address token, uint amount) external {
    _notifyRewardAmount(token, amount);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, 'ds-math-add-overflow');
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, 'ds-math-sub-underflow');
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../interface/IERC20.sol";

contract StakingRewards {

  IERC20 public rewardsToken;
  IERC20 public stakingToken;

  uint public rewardRate = 100;
  uint public lastUpdateTime;
  uint public rewardPerTokenStored;
  uint256 public periodFinish = 0;
  uint256 public rewardsDuration = 7 days;

  mapping(address => uint) public userRewardPerTokenPaid;
  mapping(address => uint) public rewards;

  uint private _totalSupply;
  mapping(address => uint) public _balances;

  constructor(address _stakingToken, address _rewardsToken) {
    stakingToken = IERC20(_stakingToken);
    rewardsToken = IERC20(_rewardsToken);
  }

  function totalSupply() external view returns (uint) {
    return _totalSupply;
  }

  function rewardPerToken() public view returns (uint) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }
    return
    rewardPerTokenStored +
    (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return block.timestamp < periodFinish ? block.timestamp : periodFinish;
  }

  function earned(address account) public view returns (uint) {
    return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
  }

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();

    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  function stake(uint _amount) external updateReward(msg.sender) {
    _totalSupply += _amount;
    _balances[msg.sender] += _amount;
    require(stakingToken.transferFrom(msg.sender, address(this), _amount));
  }

  function withdraw(uint _amount) external updateReward(msg.sender) {
    _totalSupply -= _amount;
    _balances[msg.sender] -= _amount;
    require(stakingToken.transfer(msg.sender, _amount));
  }

  function getReward() external updateReward(msg.sender) {
    uint reward = rewards[msg.sender];
    rewards[msg.sender] = 0;
    require(rewardsToken.transfer(msg.sender, reward));
  }

  function notifyRewardAmount(uint256 reward) external updateReward(address(0)) {
    require(rewardsToken.transferFrom(msg.sender, address(this), reward));
    if (block.timestamp >= periodFinish) {
      rewardRate = reward / rewardsDuration;
    } else {
      uint256 remaining = periodFinish - block.timestamp;
      uint256 leftover = remaining * rewardRate;
      rewardRate = (reward + leftover) / (rewardsDuration);
    }

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp + rewardsDuration;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../lib/Address.sol";
import "../lib/Base64.sol";
import "../lib/CheckpointLib.sol";
import "../lib/Math.sol";
import "../base/core/FldxPair.sol";

contract Token {
  using Address for address;
  using CheckpointLib for mapping(uint => CheckpointLib.Checkpoint);

  string public symbol;
  string public name;
  uint256 public decimals;
  uint256 public totalSupply = 0;

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;
  mapping(uint => CheckpointLib.Checkpoint) private _checkpoints;

  event Transfer(address from, address to, uint256 value);
  event Approval(address owner, address spender, uint256 value);
  event LogChangeVault(address indexed oldVault, address indexed newVault, uint indexed effectiveTime);

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint) public nonces;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _decimals,
    address
  ) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    uint chainId;
    assembly {
      chainId := chainid()
    }
    {
      DOMAIN_SEPARATOR = keccak256(
        abi.encode(
          keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
          keccak256(bytes(name)),
          keccak256(bytes('1')),
          chainId,
          address(this)
        )
      );
      _mint(msg.sender, 0);
    }
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(deadline >= block.timestamp, 'StableV1: EXPIRED');
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
      )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, 'StableV1: INVALID_SIGNATURE');
    allowance[owner][spender] = value;

    emit Approval(owner, spender, value);
  }

  function token() external view returns (address) {
    return address(this);
  }

  function balance(address account) external view returns (uint) {
    return balanceOf[account];
  }

  function claimFees() external pure returns (uint, uint) {
    return (0, 0);
  }

  function _mint(address _to, uint _amount) internal returns (bool) {
    balanceOf[_to] += _amount;
    totalSupply += _amount;
    emit Transfer(address(0x0), _to, _amount);
    return true;
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _value
  ) internal returns (bool) {
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    return _transfer(msg.sender, _to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) {
    uint256 allowed_from = allowance[_from][msg.sender];
    require(allowance[_from][msg.sender] >= _value, "Not enough allowance");
    if (allowed_from != type(uint).max) {
      allowance[_from][msg.sender] -= _value;
    }
    return _transfer(_from, _to, _value);
  }

  function mint(address account, uint256 amount) external returns (bool) {
    _mint(account, amount);
    return true;
  }

  function burn(address account, uint256 amount) public returns (bool) {
    totalSupply -= amount;
    balanceOf[account] -= amount;

    emit Transfer(account, address(0), amount);
    return true;
  }

  function testWrongCall() external {
    (address(0)).functionCall("", "");
  }

  function testWrongCall2() external {
    address(this).functionCall(abi.encodeWithSelector(Token(this).transfer.selector, address(this), type(uint).max), "wrong");
  }

  function encode64(bytes memory data) external pure returns (string memory){
    return Base64.encode(data);
  }

  function sqrt(uint value) external pure returns (uint){
    return Math.sqrt(value);
  }

  function testWrongCheckpoint() external view {
    _checkpoints.findLowerIndex(0, 0);
  }

  function hook(address, uint, uint, bytes calldata data) external {
    address pair = abi.decode(data, (address));
    FldxPair(pair).swap(0, 0, address(this), "");
  }

  // --------------------- WMATIC

  function deposit() public payable {
    balanceOf[msg.sender] += msg.value;
  }

  function withdraw(uint wad) public {
    require(balanceOf[msg.sender] >= wad);
    balanceOf[msg.sender] -= wad;
    payable(msg.sender).transfer(wad);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract TokenWithFee {

  string public symbol;
  string public name;
  uint256 public decimals;
  uint256 public totalSupply = 0;

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  event Transfer(address from, address to, uint256 value);
  event Approval(address owner, address spender, uint256 value);
  event LogChangeVault(address indexed oldVault, address indexed newVault, uint indexed effectiveTime);

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint) public nonces;

  address public anyswapRouter;
  address public pendingAnyswapRouter;
  uint256 public pendingRouterDelay;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _decimals,
    address _anyswapRouter
  ) {
    anyswapRouter = _anyswapRouter;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    uint chainId;
    assembly {
      chainId := chainid()
    }
    {
      DOMAIN_SEPARATOR = keccak256(
        abi.encode(
          keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
          keccak256(bytes(name)),
          keccak256(bytes('1')),
          chainId,
          address(this)
        )
      );
      _mint(msg.sender, 0);
    }
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(deadline >= block.timestamp, 'StableV1: EXPIRED');
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
      )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, 'StableV1: INVALID_SIGNATURE');
    allowance[owner][spender] = value;

    emit Approval(owner, spender, value);
  }

  function token() external view returns (address) {
    return address(this);
  }

  function balance(address account) external view returns (uint) {
    return balanceOf[account];
  }

  function claimFees() external pure returns (uint, uint) {
    return (0, 0);
  }

  function _mint(address _to, uint _amount) internal returns (bool) {
    balanceOf[_to] += _amount;
    totalSupply += _amount;
    emit Transfer(address(0x0), _to, _amount);
    return true;
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _value
  ) internal returns (bool) {
    balanceOf[_from] -= _value;
    // 10% fee burn
    balanceOf[_to] += _value * 9 / 10;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    return _transfer(msg.sender, _to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) {
    uint256 allowed_from = allowance[_from][msg.sender];
    if (allowed_from != type(uint).max) {
      allowance[_from][msg.sender] -= _value;
    }
    return _transfer(_from, _to, _value);
  }

  function _getRouter() internal returns (address) {
    if (pendingRouterDelay != 0 && pendingRouterDelay < block.timestamp) {
      anyswapRouter = pendingAnyswapRouter;
      pendingRouterDelay = 0;
    }
    return anyswapRouter;
  }

  function mint(address account, uint256 amount) external returns (bool) {
    _mint(account, amount);
    return true;
  }

  function burn(address account, uint256 amount) external returns (bool) {
    require(msg.sender == _getRouter());
    totalSupply -= amount;
    balanceOf[account] -= amount;

    emit Transfer(account, address(0), amount);
    return true;
  }

  function changeVault(address _pendingRouter) external returns (bool) {
    require(msg.sender == _getRouter());
    require(_pendingRouter != address(0), "AnyswapV3ERC20: address(0x0)");
    pendingAnyswapRouter = _pendingRouter;
    pendingRouterDelay = block.timestamp + 86400;
    emit LogChangeVault(anyswapRouter, _pendingRouter, pendingRouterDelay);
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

// a library for performing various math operations

library UniswapMath {
  function min(uint x, uint y) internal pure returns (uint z) {
    z = x < y ? x : y;
  }

  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint y) internal pure returns (uint z) {
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

pragma solidity 0.8.13;

import "./SafeMath.sol";

contract UniswapV2ERC20 {
  using SafeMath for uint;

  string public constant name = 'Uniswap V2';
  string public constant symbol = 'UNI-V2';
  uint8 public constant decimals = 18;
  uint  public totalSupply;
  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint) public nonces;
  uint public chainId;

  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  constructor() {
    uint _chainId;
    assembly {
      _chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(name)),
        keccak256(bytes('1')),
          _chainId,
        address(this)
      )
    );
    chainId = _chainId;
  }

  function _mint(address to, uint value) internal {
    totalSupply = totalSupply.add(value);
    balanceOf[to] = balanceOf[to].add(value);
    emit Transfer(address(0), to, value);
  }

  function _burn(address from, uint value) internal {
    balanceOf[from] = balanceOf[from].sub(value);
    totalSupply = totalSupply.sub(value);
    emit Transfer(from, address(0), value);
  }

  function _approve(address owner, address spender, uint value) private {
    allowance[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _transfer(address from, address to, uint value) private {
    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    emit Transfer(from, to, value);
  }

  function approve(address spender, uint value) external returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  function transfer(address to, uint value) external returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint value) external returns (bool) {
    if (allowance[from][msg.sender] != type(uint).max) {
      allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
    }
    _transfer(from, to, value);
    return true;
  }

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
      )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
    _approve(owner, spender, value);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import './UniswapV2Pair.sol';

contract UniswapV2Factory {
  address public feeTo;
  address public feeToSetter;

  mapping(address => mapping(address => address)) public getPair;
  address[] public allPairs;

  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  constructor(address _feeToSetter) {
    feeToSetter = _feeToSetter;
  }

  function allPairsLength() external view returns (uint) {
    return allPairs.length;
  }

  function createPair(address tokenA, address tokenB) external returns (address pair) {
    require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
    require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS');
    // single check is sufficient
    bytes memory bytecode = type(UniswapV2Pair).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    assembly {
      pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    UniswapV2Pair(pair).initialize(token0, token1);
    getPair[token0][token1] = pair;
    getPair[token1][token0] = pair;
    // populate mapping in the reverse direction
    allPairs.push(pair);
    emit PairCreated(token0, token1, pair, allPairs.length);
  }

  function setFeeTo(address _feeTo) external {
    require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
    feeTo = _feeTo;
  }

  function setFeeToSetter(address _feeToSetter) external {
    require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
    feeToSetter = _feeToSetter;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./UniswapV2ERC20.sol";
import "./UQ112x112.sol";
import "./UniswapMath.sol";
import "../interface/IERC20.sol";

contract UniswapV2Pair is UniswapV2ERC20 {
  using SafeMath  for uint;
  using UQ112x112 for uint224;

  uint public constant MINIMUM_LIQUIDITY = 10**3;
  bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

  address public factory;
  address public token0;
  address public token1;

  uint112 private reserve0;           // uses single storage slot, accessible via getReserves
  uint112 private reserve1;           // uses single storage slot, accessible via getReserves
  uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

  uint public price0CumulativeLast;
  uint public price1CumulativeLast;
  uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

  uint private unlocked = 1;
  modifier lock() {
    require(unlocked == 1, 'UniswapV2: LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
    _reserve0 = reserve0;
    _reserve1 = reserve1;
    _blockTimestampLast = blockTimestampLast;
  }

  function _safeTransfer(address token, address to, uint value) private {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
  }

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

  constructor() {
    factory = msg.sender;
  }

  // called once by the factory at time of deployment
  function initialize(address _token0, address _token1) external {
    require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
    token0 = _token0;
    token1 = _token1;
  }

  // update reserves and, on the first call per block, price accumulators
  function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
    require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'UniswapV2: OVERFLOW');
    uint32 blockTimestamp = uint32(block.timestamp % 2**32);
    uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
    if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
      // * never overflows, and + overflow is desired
      price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
      price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
    }
    reserve0 = uint112(balance0);
    reserve1 = uint112(balance1);
    blockTimestampLast = blockTimestamp;
    emit Sync(reserve0, reserve1);
  }

  // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
  function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
    address feeTo = address(0);
    feeOn = feeTo != address(0);
    uint _kLast = kLast; // gas savings
    if (feeOn) {
      if (_kLast != 0) {
        uint rootK = UniswapMath.sqrt(uint(_reserve0).mul(_reserve1));
        uint rootKLast = UniswapMath.sqrt(_kLast);
        if (rootK > rootKLast) {
          uint numerator = totalSupply.mul(rootK.sub(rootKLast));
          uint denominator = rootK.mul(5).add(rootKLast);
          uint liquidity = numerator / denominator;
          if (liquidity > 0) _mint(feeTo, liquidity);
        }
      }
    } else if (_kLast != 0) {
      kLast = 0;
    }
  }

  // this low-level function should be called from a contract which performs important safety checks
  function mint(address to) external lock returns (uint liquidity) {
    (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));
    uint amount0 = balance0.sub(_reserve0);
    uint amount1 = balance1.sub(_reserve1);

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    if (_totalSupply == 0) {
      liquidity = UniswapMath.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
      _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
    } else {
      liquidity = UniswapMath.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
    }
    require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
    _mint(to, liquidity);

    _update(balance0, balance1, _reserve0, _reserve1);
    if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
    emit Mint(msg.sender, amount0, amount1);
  }

  // this low-level function should be called from a contract which performs important safety checks
  function burn(address to) external lock returns (uint amount0, uint amount1) {
    (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
    address _token0 = token0;                                // gas savings
    address _token1 = token1;                                // gas savings
    uint balance0 = IERC20(_token0).balanceOf(address(this));
    uint balance1 = IERC20(_token1).balanceOf(address(this));
    uint liquidity = balanceOf[address(this)];

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
    amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
    require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
    _burn(address(this), liquidity);
    _safeTransfer(_token0, to, amount0);
    _safeTransfer(_token1, to, amount1);
    balance0 = IERC20(_token0).balanceOf(address(this));
    balance1 = IERC20(_token1).balanceOf(address(this));

    _update(balance0, balance1, _reserve0, _reserve1);
    if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
    emit Burn(msg.sender, amount0, amount1, to);
  }

  // this low-level function should be called from a contract which performs important safety checks
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata) external lock {
    require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
    (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
    require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

    uint balance0;
    uint balance1;
    { // scope for _token{0,1}, avoids stack too deep errors
      address _token0 = token0;
      address _token1 = token1;
      require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
      if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
      if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
//      if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
      balance0 = IERC20(_token0).balanceOf(address(this));
      balance1 = IERC20(_token1).balanceOf(address(this));
    }
    uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
    uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
    require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
    { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
      uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
      uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
      require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
    }

    _update(balance0, balance1, _reserve0, _reserve1);
    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
  }

  // force balances to match reserves
  function skim(address to) external lock {
    address _token0 = token0; // gas savings
    address _token1 = token1; // gas savings
    _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
    _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
  }

  // force reserves to match balances
  function sync() external lock {
    _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
  uint224 constant Q112 = 2**112;

  // encode a uint112 as a UQ112x112
  function encode(uint112 y) internal pure returns (uint224 z) {
    z = uint224(y) * Q112; // never overflows
  }

  // divide a UQ112x112 by a uint112, returning a UQ112x112
  function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
    z = x / uint224(y);
  }
}