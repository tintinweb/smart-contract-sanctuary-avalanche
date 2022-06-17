/**
 *Submitted for verification at snowtrace.io on 2022-06-16
*/

// File: contracts/libraries/SafeMath.sol

pragma solidity ^0.8.7;

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

// File: contracts/libraries/Math.sol

pragma solidity ^0.8.7;

// a library for performing various math operations

library Math {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @rytell/exchange-contracts/contracts/core/interfaces/IRytellFactory.sol

pragma solidity >=0.5.0;

interface IRytellFactory {
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

// File: @rytell/exchange-contracts/contracts/core/interfaces/IRytellPair.sol

pragma solidity >=0.5.0;

interface IRytellPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/CalculatePrice.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;






contract CalculatePrice {
  using SafeMath for uint256;

  address public avax;
  address public radi;
  address public usdc;
  address public factory;
  uint256 public baseUsdPrice;

  constructor(
    address _avax,
    address _usdc,
    address _radi,
    address _factory,
    uint256 _baseUsdPrice
  ) {
    avax = _avax;
    usdc = _usdc;
    radi = _radi;
    factory = _factory;
    baseUsdPrice = _baseUsdPrice;
  }

  function getPairAddress(address token1, address token2)
    public
    view
    returns (address)
  {
    address pair = IRytellFactory(factory).getPair(token1, token2);
    return pair;
  }

  function getLandPriceInTokens() public view returns (uint256, uint256) {
    address avaxUsdc = getPairAddress(avax, usdc);
    uint256 balanceAvax = IERC20(avax).balanceOf(avaxUsdc);
    uint256 balanceUsdc = IERC20(usdc).balanceOf(avaxUsdc);

    uint256 landPriceAvax = (baseUsdPrice * balanceAvax * 1000000000000000000) /
      (balanceUsdc * (1000000000000) * 2);

    address avaxRadi = getPairAddress(avax, radi);
    uint256 balanceAvaxInRadiPair = IERC20(avax).balanceOf(avaxRadi);
    uint256 balanceRadi = IERC20(radi).balanceOf(avaxRadi);

    uint256 amountRadi = (landPriceAvax * balanceRadi) / balanceAvaxInRadiPair;

    return (landPriceAvax, amountRadi);
  }

  function getPrice()
    external
    view
    returns (
      uint256,
      uint256,
      uint256 lpTokensAmount
    )
  {
    (uint256 avaxAmount, uint256 radiAmount) = getLandPriceInTokens();

    address avaxRadi = getPairAddress(avax, radi);
    uint256 lpTotalSupply = IRytellPair(avaxRadi).totalSupply();
    (uint112 _reserve0, uint112 _reserve1, ) = IRytellPair(avaxRadi)
      .getReserves();
    address token0 = IRytellPair(avaxRadi).token0();

    if (lpTotalSupply == 0) {
      lpTokensAmount = Math.sqrt(avaxAmount.mul(radiAmount));
    } else {
      if (token0 == avax) {
        lpTokensAmount = Math.min(
          avaxAmount.mul(lpTotalSupply) / _reserve0,
          radiAmount.mul(lpTotalSupply) / _reserve1
        );
      } else {
        lpTokensAmount = Math.min(
          avaxAmount.mul(lpTotalSupply) / _reserve1,
          radiAmount.mul(lpTotalSupply) / _reserve0
        );
      }
    }
    require(lpTokensAmount > 0, "Rytell: INSUFFICIENT_LIQUIDITY_MINTED");
    return (avaxAmount, radiAmount, lpTokensAmount);
  }
}