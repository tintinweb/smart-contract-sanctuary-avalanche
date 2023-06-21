// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
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

pragma solidity 0.8.12;

interface IPangolinRouter {
    function WAVAX() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] memory path)
    external
    view
    returns (uint[] memory amounts);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external virtual payable returns (uint amountToken, uint amountAVAX, uint liquidity);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IPangolinRouter} from "../interfaces/IPangolinRouter.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

library SwapTokenLib {

    address constant pangolinRouterAddress = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
    address constant usdcAddress = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    function swapUsdcToERC20WithSlippage(address erc20Address, uint256 usdcValue, address receiver) public {

        IPangolinRouter pangolinRouter = IPangolinRouter(pangolinRouterAddress);
        IERC20Metadata usdc = IERC20Metadata(usdcAddress);
        usdc.approve(address(pangolinRouter), usdcValue);

        address[] memory path = new address[](3);
        path[0] = address(usdc);
        path[1] = pangolinRouter.WAVAX();
        path[2] = erc20Address;

        pangolinRouter.swapExactTokensForTokens(usdcValue, 0, path, receiver, block.timestamp);

    }

    function swapERC20AllToUSDC(address erc20Address) public {
        IPangolinRouter pangolinRouter = IPangolinRouter(pangolinRouterAddress);
        IERC20Metadata usdc = IERC20Metadata(usdcAddress);

        IERC20Metadata(erc20Address).approve(address(pangolinRouter), IERC20Metadata(erc20Address).balanceOf(address(this)));
        address[] memory path = new address[](3);
        path[0] = erc20Address;
        path[1] = pangolinRouter.WAVAX();
        path[2] = address(usdc);

        pangolinRouter.swapExactTokensForTokens(IERC20Metadata(erc20Address).balanceOf(address(this)), 0, path, address(this), block.timestamp);
    }

    function swapERC20ToUSDC(address erc20Address, uint256 usdcValue, address priceFeedAddress, uint16 slippagePercentage, uint16 PERCENTAGE) public {
        IPangolinRouter pangolinRouter = IPangolinRouter(pangolinRouterAddress);
        IERC20Metadata usdc = IERC20Metadata(usdcAddress);

        uint256 tokenValue = _convertToken(priceFeedAddress, address(usdc), erc20Address, usdcValue);
        address[] memory path = new address[](3);
        path[0] = erc20Address;
        path[1] = pangolinRouter.WAVAX();
        path[2] = address(usdc);
        uint256[] memory amounts = pangolinRouter.getAmountsOut(tokenValue, path);
        uint256 receivedTokenAmount = amounts[2];


        while (receivedTokenAmount < (usdcValue - (usdcValue * slippagePercentage / PERCENTAGE))) {
            usdcValue = usdcValue / 2;
            tokenValue = tokenValue / 2;
            uint256[] memory amounts = pangolinRouter.getAmountsOut(tokenValue, path);
            receivedTokenAmount = amounts[2];
        }

        IERC20Metadata(erc20Address).approve(address(pangolinRouter), tokenValue);
        pangolinRouter.swapExactTokensForTokens(tokenValue, usdcValue - (usdcValue * slippagePercentage / PERCENTAGE), path, address(this), block.timestamp);
    }

    function swapUsdcToERC20(address erc20Address, uint256 usdcValue, address priceFeedAddress, uint16 slippagePercentage, uint16 PERCENTAGE) public {

        IPangolinRouter pangolinRouter = IPangolinRouter(pangolinRouterAddress);
        IERC20Metadata usdc = IERC20Metadata(usdcAddress);

        address[] memory path = new address[](3);
        path[0] = address(usdc);
        path[1] = pangolinRouter.WAVAX();
        path[2] = erc20Address;

        uint256[] memory amounts = pangolinRouter.getAmountsOut(usdcValue, path);
        uint256 tokenValue = _convertToken(priceFeedAddress, address(usdc), erc20Address, usdcValue);

        if (amounts[2] >= (tokenValue * slippagePercentage / PERCENTAGE)) {
            usdc.approve(address(pangolinRouter), usdcValue);
            pangolinRouter.swapExactTokensForTokens(usdcValue, tokenValue - (tokenValue * slippagePercentage / PERCENTAGE), path, address(this), block.timestamp);
        }
    }

    function _convertToken(address priceFeed, address token1, address token2, uint256 amount) view public returns (uint256) {
        (uint80 roundId, int256 price,,,uint80 answeredInRound) = AggregatorV2V3Interface(priceFeed).latestRoundData();
        require(answeredInRound >= roundId, "COA: Stale answer");
        if (token1 == usdcAddress) {
            return (amount * (10 ** AggregatorV2V3Interface(priceFeed).decimals()) / uint256(price) * 10 ** IERC20Metadata(token2).decimals() / 10 ** IERC20Metadata(token1).decimals());
        }
        return (amount * uint256(price) / (10 ** AggregatorV2V3Interface(priceFeed).decimals()) * 10 ** IERC20Metadata(token2).decimals() / 10 ** IERC20Metadata(token1).decimals());
    }


}