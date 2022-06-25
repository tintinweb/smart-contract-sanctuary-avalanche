// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../mvp_v1/interfaces/IArableExchange.sol";
import "../mvp_v1/interfaces/IArableOracle.sol";

contract MevTest {
    IArableExchange public exchange;
    IArableOracle public oracle;

    constructor(IArableExchange _exchange, IArableOracle _oracle) {
        exchange = _exchange;
        oracle = _oracle;
    }

    function resetContracts(IArableExchange _exchange, IArableOracle _oracle) external {
        exchange = _exchange;
        oracle = _oracle;
    }

    function tryMev(
        IERC20 inToken,
        uint256 inAmount,
        IERC20 outToken
    ) external {
        inToken.transferFrom(msg.sender, address(this), inAmount);

        inToken.approve(address(exchange), inAmount);

        // buy outToken
        exchange.swapSynths(address(inToken), inAmount, address(outToken));

        // increase outToken price 1.2x
        uint256 originPrice = oracle.getPrice(address(outToken));
        oracle.registerPrice(address(outToken), (originPrice * 12) / 10);

        // sell outToken
        uint256 outAmount = outToken.balanceOf(address(this));
        outToken.approve(address(exchange), outAmount);
        exchange.swapSynths(address(outToken), outAmount, address(inToken));

        uint256 finalAmount = inToken.balanceOf(address(this));

        oracle.registerPrice(address(outToken), originPrice);

        inToken.transfer(msg.sender, finalAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface IArableExchange {
    function swapSynths(address inToken, uint256 inAmount, address outToken) external;
    function convertFeesToUsd(address inToken, uint256 inAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableOracle {
    function getPrice(address token) external view returns (uint256);
    function getDailyRewardRate(uint256 farmId, address rewardToken) external view returns (uint256);
    function registerPrice(address token_, uint256 price_) external;
    function registerRewardRate(
        uint256 farmId_,
        address token_,
        uint256 dailyRewardRate_
    ) external;
}