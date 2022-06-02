/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-01
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
// File: contracts/interfaces/IAssetPricer.sol


pragma solidity ^0.8.14;

interface IAssetPricer {
    function valuation(
        address _asset,
        address _quote,
        uint256 _amount
    ) external view returns (uint256);
}

// File: contracts/pricers/WeightedPairPricer.sol



pragma solidity 0.8.14;




// solhint-disable  max-line-length

/**
 * Bonding calculator for weighted pairs
 */
contract WeightedPairPricer is IAssetPricer {

    constructor() {}

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
     * @param _pair general pair that has the RequiemSwap interface implemented
     *  - the value is calculated as the geometric average of input and output
     *  - is consistent with the uniswapV2-type case
     */
    function getTotalValue(address _pair, address _quote) public view returns (uint256 _value) {
        IWeightedPair.ReserveData memory pairData = IWeightedPair(_pair).getReserves();
        (uint32 weight0, uint32 weight1, , ) = IWeightedPair(_pair).getParameters();

        // In case of both weights being 50, it is equivalent to
        // the UniswapV2 variant. If the weights are different, we define the valuation by
        // scaling the reserve up or down dependent on the weights and the use the product as
        // adjusted constant product. We will use the conservative estimation of the price - we upscale
        // such that the reflected equivalent pool is a uniswapV2 with the higher liquidity that pruduces
        // the same price of the Requiem token as the weighted pool.
        if (_quote == IWeightedPair(_pair).token0()) {
            _value = pairData.reserve0 + (pairData.vReserve0 * weight1 * pairData.reserve1) / (weight0 * pairData.vReserve1);
        } else {
            _value = pairData.reserve1 + (pairData.vReserve1 * weight0 * pairData.reserve0) / (weight1 * pairData.vReserve0);
        }
        // standardize to 18 decimals
        _value *= 10**(18 - IERC20(_quote).decimals());
    }

    /**
     * - calculates the value in QUOTE that backs reqt 1:1 of the input LP amount provided
     * @param _pair general pair that has the RequiemSwap interface implemented
     * @param _amount the amount of LP to price for the backing
     *  - is consistent with the uniswapV2-type case
     */
    function valuation(
        address _pair,
        address _quote,
        uint256 _amount
    ) external view override returns (uint256 _value) {
        uint256 totalValue = getTotalValue(_pair, _quote);
        uint256 totalSupply = IWeightedPair(_pair).totalSupply();

        _value = (totalValue * _amount) / totalSupply;
    }

    // markdown function for bond valuation - no discounting fo regular pairs
    function markdown(address _pair, address _quote) external view returns (uint256) {
        return getTotalValue(_pair, _quote);
    }
}