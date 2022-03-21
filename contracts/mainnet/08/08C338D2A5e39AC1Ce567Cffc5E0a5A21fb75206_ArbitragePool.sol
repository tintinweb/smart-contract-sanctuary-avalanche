/**
 *Submitted for verification at snowtrace.io on 2022-03-20
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



interface IPair is IERC20 {
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

    function mint(address to) external returns (uint256 liquidity);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

/// @title Arbitrage Pool
/// @author Trader Joe
/// @notice Arbitrage a pool and add liquidity to the desired amounts. Useful when a pair has low liquidity
/// but a price different than the one intended to be.
contract ArbitragePool is Ownable {
    using SafeERC20 for IERC20Metadata;

    /* ========== STRUCTURES ========== */

    struct ArbitrageInfo {
        uint256 amount;
        IERC20Metadata tokenFrom;
        uint256 targetPrice;
        bool collateralIsToken0;
        IERC20Metadata token0;
        IERC20Metadata token1;
        uint256 decimals0;
        uint256 decimals1;
        uint256 reserve0;
        uint256 reserve1;
    }

    /* ========== EVENTS ========== */

    event PoolArbitraged(
        address indexed sender,
        IPair indexed pair,
        IERC20Metadata collateral,
        uint256 _targetAvaxPrice
    );
    event LiquidityAdded(
        address indexed sender,
        address indexed pair,
        uint256 amount0,
        uint256 amount1
    );
    event EmergencyWithdraw(
        address indexed sender,
        address indexed pair,
        uint256 amount
    );

    /* ========== EXTERNAL FUNCTIONS ========== */

    /// @notice Arbitrage a pair to the desired target price, accurate at at least 0.1%.
    /// @param _pair The address of the pair, collateral needs to be one of the 2 tokens
    /// @param _collateral The address of the collateral, the one we want to take price from
    /// @param _targetPrice The targeted derivative collateral price of the token, scaled to 1e18
    function arbitrageTo(
        IPair _pair,
        IERC20Metadata _collateral,
        uint256 _targetPrice
    ) external onlyOwner {
        ArbitrageInfo memory arbitrageInfo = _getArbitrageInfo(
            _pair,
            _collateral,
            _targetPrice
        );
        _arbitrageTo(_pair, _collateral, arbitrageInfo);
    }

    /// @notice Arbitrage a pair to the desired _targetAvaxPrice, and add liquidity to the desired
    /// target. Exactly one reserve target need to be set
    /// @param _pair The address of the pair
    /// @param _collateral The address of the collateral, the one we want to take price from
    /// @param _targetPrice The targeted derivative collateral price of the token, scaled to 1e18
    /// @param _targetReserveToken The targeted token reserve, needs to be greater than its current reserve, or equal to 0
    /// @param _targetReserveCollateral The targeted collateral reserve, needs to be greater than its current reserve, or equal to 0
    function arbitrageToAndAddLiquidity(
        IPair _pair,
        IERC20Metadata _collateral,
        uint256 _targetPrice,
        uint256 _targetReserveToken,
        uint256 _targetReserveCollateral
    ) external onlyOwner {
        // Prevents reentrancy
        require(tx.origin == _msgSender(), "ArbitragePool: Only EOA");
        // At least one target needs to be not set
        require(
            _targetReserveToken == 0 || _targetReserveCollateral == 0,
            "ArbitragePool: only one target is allowed"
        );
        ArbitrageInfo memory arbitrageInfo = _getArbitrageInfo(
            _pair,
            _collateral,
            _targetPrice
        );
        _arbitrageTo(_pair, _collateral, arbitrageInfo);

        (uint256 reserve0, uint256 reserve1, ) = _pair.getReserves();
        (
            uint256 _targetReserveToken0,
            uint256 _targetReserveToken1
        ) = arbitrageInfo.collateralIsToken0
                ? (_targetReserveCollateral, _targetReserveToken)
                : (_targetReserveToken, _targetReserveCollateral);
        // At least one target is set and is greater than current reserve (we only add liquidity),
        // with the previous check, we unsure that only one target is set
        require(
            _targetReserveToken0 > reserve0 || _targetReserveToken1 > reserve1,
            "ArbitragePool: unreachable target"
        );
        uint256 amount0;
        uint256 amount1;
        if (_targetReserveToken0 != 0) {
            amount0 = _targetReserveToken0 - reserve0;
            amount1 = (amount0 * reserve1) / reserve0;
        } else {
            amount1 = _targetReserveToken1 - reserve1;
            amount0 = (amount1 * reserve0) / reserve1;
        }
        // Add liquidity, by sendinf the right amounts and minting LPs to _msgSender()
        arbitrageInfo.token0.safeTransferFrom(
            _msgSender(),
            address(_pair),
            amount0
        ); // Reentrancy vector
        arbitrageInfo.token1.safeTransferFrom(
            _msgSender(),
            address(_pair),
            amount1
        ); // Reentrancy vector
        _pair.mint(_msgSender());

        // Check that target was hit, doesn't work with transfer tax tokens
        (reserve0, reserve1, ) = _pair.getReserves();
        require(
            reserve0 == _targetReserveToken0 ||
                reserve1 == _targetReserveToken1,
            "ArbitragePool: target wasn't hit"
        );
        emit LiquidityAdded(_msgSender(), address(_pair), amount0, amount1);
    }

    /// @notice View function to get the amount of token to arbitrage a pair to the target price, accurate at at least 0.1%
    /// @param _pair The address of the pair, collateral needs to be one of the 2 tokens
    /// @param _collateral The address of the collateral, the one we want to take price from
    /// @param _targetPrice The targeted derivative collateral price of the token, scaled to 1e18
    /// @return tokenFrom The address of the token that will be swapped from
    /// @return amountFrom The amount of token that will be swapped from
    function getArbitageTo(
        IPair _pair,
        IERC20Metadata _collateral,
        uint256 _targetPrice
    ) external view returns (IERC20, uint256) {
        ArbitrageInfo memory arbitrageInfo = _getArbitrageInfo(
            _pair,
            _collateral,
            _targetPrice
        );
        return (arbitrageInfo.tokenFrom, arbitrageInfo.amount);
    }

    /// @notice View function to get the amount of token to arbitrage a pair to the target price, accurate at at least 0.1%
    /// And then add liquidity to hit the target reserves, One of them needs to be equal to 0. If the target is set
    /// to low, will return 0 liquidity to add.
    /// @param _pair The address of the pair
    /// @param _collateral The address of the collateral, the one we want to take price from
    /// @param _targetPrice The targeted derivative collateral price of the token, scaled to 1e18
    /// @param _targetReserveToken The targeted token reserve
    /// @param _targetReserveCollateral The targeted collateral reserve
    /// @return tokenFrom The address of the token that will be swapped from
    /// @return amountFrom The amount of token that will be swapped from
    /// @return token0amount The amount of token0 added to the pair
    /// @return token1amount The amount of token1 added to the pair
    function getArbitageToAndAddLiquidity(
        IPair _pair,
        IERC20Metadata _collateral,
        uint256 _targetPrice,
        uint256 _targetReserveToken,
        uint256 _targetReserveCollateral
    )
        external
        view
        returns (
            IERC20,
            uint256,
            uint256,
            uint256
        )
    {
        require(
            _targetReserveToken == 0 || _targetReserveCollateral == 0,
            "ArbitragePool: only one target is allowed"
        );
        ArbitrageInfo memory arbitrageInfo = _getArbitrageInfo(
            _pair,
            _collateral,
            _targetPrice
        );
        uint256 newReserve0;
        uint256 newReserve1;
        if (arbitrageInfo.tokenFrom == arbitrageInfo.token0) {
            newReserve0 += arbitrageInfo.amount;
            uint256 amountOut = _getAmountOut(
                arbitrageInfo.amount,
                arbitrageInfo.reserve0,
                arbitrageInfo.reserve1
            );
            newReserve1 = arbitrageInfo.reserve1 - amountOut;
        } else {
            newReserve1 += arbitrageInfo.amount;
            uint256 amountOut = _getAmountOut(
                arbitrageInfo.amount,
                arbitrageInfo.reserve1,
                arbitrageInfo.reserve0
            );
            newReserve0 = arbitrageInfo.reserve0 - amountOut;
        }

        if (arbitrageInfo.collateralIsToken0) {
            (newReserve0, newReserve1) = (newReserve1, newReserve0);
        }

        uint256 amount0;
        uint256 amount1;
        if (_targetReserveToken > newReserve0) {
            amount0 = _targetReserveToken - newReserve0;
            amount1 = (amount0 * newReserve1) / newReserve0;
        } else if (_targetReserveCollateral > newReserve1) {
            amount1 = _targetReserveCollateral - newReserve1;
            amount0 = (amount1 * newReserve0) / newReserve1;
        }

        return (
            arbitrageInfo.tokenFrom,
            arbitrageInfo.amount,
            arbitrageInfo.collateralIsToken0 ? amount1 : amount0,
            arbitrageInfo.collateralIsToken0 ? amount0 : amount1
        );
    }

    /// @notice Emergency withdraw funds. Address(0) is native AVAX.
    /// @param token Address of the token
    function emergencyWithdraw(IERC20Metadata token) external onlyOwner {
        if (address(token) == address(0)) {
            uint256 amount = address(this).balance;
            require(amount != 0, "ArbitragePool: Insufficient balance");
            (bool success, ) = _msgSender().call{value: amount}(""); // Reentrancy vector
            require(success, "ArbitragePool: Avax Transfer failed");
            emit EmergencyWithdraw(_msgSender(), address(0), amount);
        } else {
            uint256 amount = token.balanceOf(_msgSender());
            require(amount != 0, "ArbitragePool: Insufficient balance");
            token.safeTransfer(_msgSender(), amount); // Reentrancy vector
            emit EmergencyWithdraw(_msgSender(), address(token), amount);
        }
    }

    /* ========== Private Functions ========== */

    /// @notice Arbitrage a pair to the desired target price, accurate at 0.1%.
    /// @param _pair The address of the pair, collateral needs to be one of the 2 tokens
    /// @param _collateral The address of the collateral, the one we want to take price from
    /// @param _arbitrageInfo The required information to arbitrage
    function _arbitrageTo(
        IPair _pair,
        IERC20Metadata _collateral,
        ArbitrageInfo memory _arbitrageInfo
    ) private onlyOwner {
        _arbitrageInfo.tokenFrom.safeTransferFrom(
            _msgSender(),
            address(_pair),
            _arbitrageInfo.amount
        ); // Reentrancy vector

        if (_arbitrageInfo.token0 == _arbitrageInfo.tokenFrom) {
            uint256 amountOut = _getAmountOut(
                _arbitrageInfo.amount,
                _arbitrageInfo.reserve0,
                _arbitrageInfo.reserve1
            );
            _pair.swap(0, amountOut, _msgSender(), new bytes(0)); // Reentrancy vector
        } else {
            uint256 amountOut = _getAmountOut(
                _arbitrageInfo.amount,
                _arbitrageInfo.reserve1,
                _arbitrageInfo.reserve0
            );
            _pair.swap(amountOut, 0, _msgSender(), new bytes(0)); // Reentrancy vector
        }

        (uint256 reserve0, uint256 reserve1, ) = _pair.getReserves();

        uint256 currentPrice = _arbitrageInfo.collateralIsToken0
            ? (reserve0 * 10**_arbitrageInfo.decimals1) / reserve1
            : (reserve1 * 10**_arbitrageInfo.decimals0) / reserve0;
        // Check that we hit 0.1% of target
        uint256 delta = (_arbitrageInfo.targetPrice * 999) / 1_000;
        require(
            _arbitrageInfo.targetPrice - delta <= currentPrice &&
                currentPrice <= _arbitrageInfo.targetPrice + delta,
            "ArbitragePool: SlippageCaught"
        );

        emit PoolArbitraged(
            _msgSender(),
            _pair,
            _collateral,
            _arbitrageInfo.targetPrice
        );
    }

    /// @notice Gets the information required to arbitrage a pair to the desired target price, accurate at 0.1%.
    /// @param _pair The address of the pair, collateral needs to be one of the 2 tokens
    /// @param _collateral The address of the collateral, the one we want to take price from
    /// @param _targetPrice The targeted derivative collateral price of the token, scaled to 1e18
    /// @return arbitrageInfo The required information
    function _getArbitrageInfo(
        IPair _pair,
        IERC20Metadata _collateral,
        uint256 _targetPrice
    ) private view returns (ArbitrageInfo memory arbitrageInfo) {
        // Prevents reentrancy
        require(tx.origin == _msgSender(), "ArbitragePool: Only EOA");
        (IERC20Metadata token0, IERC20Metadata token1) = (
            IERC20Metadata(_pair.token0()),
            IERC20Metadata(_pair.token1())
        );
        arbitrageInfo.token0 = token0;
        arbitrageInfo.token1 = token1;
        // Assert that one of the token is collateral, and order them so that collateral == _collateral
        if (token0 == _collateral) {
            arbitrageInfo.collateralIsToken0 = true;
        } else if (token1 != _collateral) {
            revert("ArbitragePool: Collateral not in pair");
        }
        arbitrageInfo.decimals0 = token0.decimals();
        arbitrageInfo.decimals1 = token1.decimals();
        {
            uint256 decimalsCollateral = arbitrageInfo.collateralIsToken0
                ? arbitrageInfo.decimals0
                : arbitrageInfo.decimals1;
            if (decimalsCollateral < 18) {
                arbitrageInfo.targetPrice =
                    _targetPrice /
                    10**(18 - decimalsCollateral);
            } else if (decimalsCollateral > 18) {
                arbitrageInfo.targetPrice =
                    _targetPrice *
                    10**(decimalsCollateral - 18);
            } else {
                arbitrageInfo.targetPrice = _targetPrice;
            }
        }
        require(
            arbitrageInfo.targetPrice != 0,
            "ArbitragePool: target can't be 0"
        );
        // Gas opt
        (arbitrageInfo.reserve0, arbitrageInfo.reserve1, ) = _pair
            .getReserves();
        // Get amount and tokenFrom to do arbitrage
        (
            arbitrageInfo.amount,
            arbitrageInfo.tokenFrom
        ) = _getAmountToSwapToHitTarget(
            token0,
            token1,
            arbitrageInfo.reserve0,
            arbitrageInfo.reserve1,
            arbitrageInfo.collateralIsToken0
                ? arbitrageInfo.decimals1
                : arbitrageInfo.decimals0,
            arbitrageInfo.targetPrice,
            arbitrageInfo.collateralIsToken0
        );
    }

    /// @notice Get the amount of tokenFrom to swap to reach the target price
    /// @param _token0 The address of token0
    /// @param _token1 The address of token1
    /// @param _reserve0 The reserve of token0
    /// @param _reserve1 The reserve of token1
    /// @param _decimalsToken The number of decimals of token
    /// @param _targetPrice The targeted derived collateral price
    /// @param _collIsToken0 Boolean value, true is token is token0 and collateral is token1, false orelse
    /// @return amount The amount that needs to be swapped
    /// @return tokenFrom The token that needs to be swapped
    function _getAmountToSwapToHitTarget(
        IERC20Metadata _token0,
        IERC20Metadata _token1,
        uint256 _reserve0,
        uint256 _reserve1,
        uint256 _decimalsToken,
        uint256 _targetPrice,
        bool _collIsToken0
    ) private pure returns (uint256, IERC20Metadata) {
        uint256 k = _reserve0 * _reserve1;

        // reserve0 is reverveToken and reserve1 is reserveCollateral
        if (_collIsToken0) {
            (_reserve0, _reserve1) = (_reserve1, _reserve0);
        }

        // k = reserveCollateral * reserveToken
        // => reserveCollateral = k / reserveToken
        // target = reserveCollateral / reserveToken
        // => reserveCollateral = target * reserveToken
        // => k = target * reserveToken^2
        // => reserveToken = _sqrt(k / target)
        uint256 newReserveToken = _sqrt(
            (k * 10**_decimalsToken) / _targetPrice
        );

        // Get the actual values to return, we take into account TJ's LP fees, 0.3%, so 0.15% more.
        if (newReserveToken > _reserve0) {
            return (
                ((newReserveToken - _reserve0) * 10015) / 10000,
                _collIsToken0 ? _token1 : _token0
            );
        } else {
            return (
                ((k / newReserveToken - _reserve1) * 10015) / 10000,
                _collIsToken0 ? _token0 : _token1
            );
        }
    }

    /// @notice Returns the square root of x, using Babylonian Method
    /// @param x Uint256
    /// @return y Which is equal to |_sqrt(x)|
    function _sqrt(uint256 x) private pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Returns the amount of token that will be sent if amountIn was sent to a pair with (reserveIn, reserveOut)
    /// @param amountIn The amount of token to swap in
    /// @param reserveIn The reserve of the token to swap in
    /// @param reserveOut The reserve of the token to swap out
    /// @return amountOut The amount that will be sent
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) private pure returns (uint256 amountOut) {
        require(amountIn != 0, "ArbitragePool: Insufficient input amount");
        require(
            reserveIn != 0 && reserveOut != 0,
            "ArbitragePool: Insufficient liquidity"
        );
        // Trader Joe has a 0.3% fee on swap
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}