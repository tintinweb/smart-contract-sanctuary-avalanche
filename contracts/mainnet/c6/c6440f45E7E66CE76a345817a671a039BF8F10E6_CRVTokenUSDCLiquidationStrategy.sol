//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/ITokenLiquidationStrategy.sol";
import "../interfaces/IAave3CrvPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CRVTokenUSDCLiquidationStrategy is ITokenLiquidationStrategy {
    // AAVE 3CRV POOL
    address private constant AAVE_POOL_3CRV =
        0x7f90122BF0700F9E7e1F688fe926940E8839F353;

    address private constant usdcToken = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    int128 private constant usdcIndex = int128(1);

    function applyStrategy(
        address token,
        uint256 amount,
        address backReceiver
    ) external override returns (address[] memory, uint256[] memory) {
        require(
            token != address(0),
            "CRVTokenLiquidationStrategy: specified token address should not be zero."
        );
        require(
            amount > 0,
            "CRVTokenLiquidationStrategy: specified token amount should be more than zero."
        );

        // Approve tokens to be used by pool to remove liquidity
        IERC20(token).approve(AAVE_POOL_3CRV, amount);

        address[] memory claimedTokens = new address[](1);
        claimedTokens[0] = usdcToken;

        uint256 removedLiquidityAmount = IAave3CrvPool(AAVE_POOL_3CRV).remove_liquidity_one_coin(amount, usdcIndex, uint256(0), true);

        // transfer removed from liquidity pool tokens with it's received amount from pool
        IERC20(usdcToken).transfer(backReceiver, removedLiquidityAmount);

        uint256[] memory amountsResult = new uint256[](1);
        amountsResult[0] = removedLiquidityAmount;
        return (claimedTokens, amountsResult);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITokenLiquidationStrategy {
    /// @notice  Applies liquidation strategy for token
    /// @param token - token to handle
    /// @param amount - amount of tokens to handle
    /// @param backReceiver - address to send tokens back
    /// @return tokens tokens received after strategy applied
    /// @return amounts amount of each token received after strategy applied
    function applyStrategy(
        address token,
        uint256 amount,
        address backReceiver
    ) external returns (address[] memory tokens, uint256[] memory amounts);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAave3CrvPool {
    function remove_liquidity(
        uint256 amount,
        uint256[3] memory minAmounts,
        bool useUnderlying
    ) external returns (uint256[3] memory);

    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount,
        bool useUnderlying
    ) external returns (uint256);
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