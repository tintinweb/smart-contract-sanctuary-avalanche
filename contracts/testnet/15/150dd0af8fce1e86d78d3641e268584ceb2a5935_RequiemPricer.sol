/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-03
*/

// File: contracts/interfaces/IWeightedPair.sol



pragma solidity ^0.8.14;

// solhint-disable func-name-mixedcase

interface IWeightedPair {
  struct ReserveData {
    uint256 reserve0;
    uint256 reserve1;
    uint256 vReserve0;
    uint256 vReserve1;
  }

  function totalSupply() external view returns (uint256);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (ReserveData calldata reserveData);

  function getParameters()
    external
    view
    returns (
      uint32 _tokenWeight0,
      uint32 _tokenWeight1,
      uint32 _swapFee,
      uint32 _amp
    );
}

// File: contracts/interfaces/ERC20/IERC20.sol


pragma solidity 0.8.14;

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
// File: contracts/interfaces/ISwap.sol



pragma solidity ^0.8.14;


interface ISwap {
  function calculateSwapGivenIn(
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) external view returns (uint256);

  function getTokenBalances() external view returns (uint256[] memory);

  function getPooledTokens() external view returns (IERC20[] memory);

  function getTokenMultipliers() external view returns (uint256[] memory);
}

// File: contracts/interfaces/IAssetPricer.sol


pragma solidity ^0.8.14;

interface IAssetPricer {
    function valuation(
        address _asset,
        address _quote,
        uint256 _amount
    ) external view returns (uint256);
}

// File: contracts/pricers/RequiemPricer.sol



pragma solidity 0.8.14;





/**
 * Bonding calculator for weighted pairs
 */
contract RequiemPricer is IAssetPricer {

    address public immutable REQ;

    constructor(address _REQ) {
        require(_REQ != address(0));
        REQ = _REQ;
    }

    /**
     * note for general pairs the price does not necessarily satisfy the conditon
     * that the lp value consists 50% of the one and the other token since the mid
     * price is the quotient of the reserves. That is not necessarily the case for
     * general pairs, therefore, we have to calculate the price separately and apply it
     * to the reserve amount for conversion
     * - calculates the total liquidity value denominated in the provided token
     * - uses the 1bps ouytput reserves for that calculation to avoid slippage to
     *   have a too large impact
     * - the sencond token input argument is ignored when using pools with only 2 tokens
     * @param _pair pair that includes requiem token
     *  - the value of the requiem reserve is assumed at 1 unit of quote
     *  - is consistent with the uniswapV2-type case
     */
    function getTotalValue(address _pair, address) public view returns (uint256 _value) {
        IWeightedPair.ReserveData memory pairData = IWeightedPair(_pair).getReserves();

        uint256 quoteMultiplier = 10**(18 - IERC20(IWeightedPair(_pair).token1()).decimals());

        if (REQ == IWeightedPair(_pair).token1()) {
            _value = pairData.reserve0 * quoteMultiplier + pairData.reserve1;
        } else {
            _value = pairData.reserve1 * quoteMultiplier + pairData.reserve0;
        }
    }

    /**
     * - calculates the value in reqt of the input LP amount provided
     * @param _pair general pair that has the RequiemSwap interface implemented
     * @param amount_ the amount of LP to price in REQ
     *  - is consistent with the uniswapV2-type case
     */
    function valuation(
        address _pair,
        address _quote,
        uint256 amount_
    ) external view override returns (uint256 _value) {
        uint256 totalValue = getTotalValue(_pair, _quote);
        uint256 totalSupply = IWeightedPair(_pair).totalSupply();

        _value = (totalValue * amount_) / totalSupply;
    }

    // markdown function for bond valuation
    function markdown(address _pair, address _quote) external view returns (uint256) {
        IWeightedPair.ReserveData memory pairData = IWeightedPair(_pair).getReserves();

        uint256 reservesOther = REQ == IWeightedPair(_pair).token0() ? pairData.reserve1 : pairData.reserve0;

        // adjusted markdown scaling up the reserve as the trading mechanism allows
        // for lower valuation for reqt reserve
        return (2 * reservesOther * (10**IERC20(REQ).decimals())) / getTotalValue(_pair, _quote);
    }
}