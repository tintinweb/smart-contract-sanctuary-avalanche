// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IJoeTraderPair {
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
    function swapFee() external view returns (uint32);
    function devFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setSwapFee(uint32) external;
    function setDevFee(uint32) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IJoeTraderRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapFeeReward() external pure returns (address);

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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILBFactory {
    function LBPairImplementation() external view returns (address);

    function MAX_BIN_STEP() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function MAX_PROTOCOL_SHARE() external view returns (uint256);

    function MIN_BIN_STEP() external view returns (uint256);

    function addQuoteAsset(address _quoteAsset) external;

    function allLBPairs(uint256) external view returns (address);

    function becomeOwner() external;

    function createLBPair(
        address _tokenX,
        address _tokenY,
        uint24 _activeId,
        uint16 _binStep
    ) external returns (address _LBPair);

    function creationUnlocked() external view returns (bool);

    function feeRecipient() external view returns (address);

    function flashLoanFee() external view returns (uint256);

    function forceDecay(address _LBPair) external;

    function getAllBinSteps()
        external
        view
        returns (uint256[] memory presetsBinStep);

    function getAllLBPairs(
        address _tokenX,
        address _tokenY
    )
        external
        view
        returns (ILBFactory.LBPairInformation[] memory LBPairsAvailable);

    function getLBPairInformation(
        address _tokenA,
        address _tokenB,
        uint256 _binStep
    ) external view returns (ILBFactory.LBPairInformation memory);

    function getNumberOfLBPairs() external view returns (uint256);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getPreset(
        uint16 _binStep
    )
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxVolatilityAccumulated,
            uint256 sampleLifetime
        );

    function getQuoteAsset(uint256 _index) external view returns (address);

    function isQuoteAsset(address _token) external view returns (bool);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function removePreset(uint16 _binStep) external;

    function removeQuoteAsset(address _quoteAsset) external;

    function renounceOwnership() external;

    function revokePendingOwner() external;

    function setFactoryLockedState(bool _locked) external;

    function setFeeRecipient(address _feeRecipient) external;

    function setFeesParametersOnPair(
        address _tokenX,
        address _tokenY,
        uint16 _binStep,
        uint16 _baseFactor,
        uint16 _filterPeriod,
        uint16 _decayPeriod,
        uint16 _reductionFactor,
        uint24 _variableFeeControl,
        uint16 _protocolShare,
        uint24 _maxVolatilityAccumulated
    ) external;

    function setFlashLoanFee(uint256 _flashLoanFee) external;

    function setLBPairIgnored(
        address _tokenX,
        address _tokenY,
        uint256 _binStep,
        bool _ignored
    ) external;

    function setLBPairImplementation(address _LBPairImplementation) external;

    function setPendingOwner(address pendingOwner_) external;

    function setPreset(
        uint16 _binStep,
        uint16 _baseFactor,
        uint16 _filterPeriod,
        uint16 _decayPeriod,
        uint16 _reductionFactor,
        uint24 _variableFeeControl,
        uint16 _protocolShare,
        uint24 _maxVolatilityAccumulated,
        uint16 _sampleLifetime
    ) external;

    struct LBPairInformation {
        uint16 binStep;
        address LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ILBRouter {
    error BinHelper__BinStepOverflows(uint256 bp);
    error BinHelper__IdOverflows();
    error JoeLibrary__InsufficientAmount();
    error JoeLibrary__InsufficientLiquidity();
    error LBRouter__AmountSlippageCaught(
        uint256 amountXMin,
        uint256 amountX,
        uint256 amountYMin,
        uint256 amountY
    );
    error LBRouter__BinReserveOverflows(uint256 id);
    error LBRouter__BrokenSwapSafetyCheck();
    error LBRouter__DeadlineExceeded(
        uint256 deadline,
        uint256 currentTimestamp
    );
    error LBRouter__FailedToSendAVAX(address recipient, uint256 amount);
    error LBRouter__IdDesiredOverflows(uint256 idDesired, uint256 idSlippage);
    error LBRouter__IdOverflows(int256 id);
    error LBRouter__IdSlippageCaught(
        uint256 activeIdDesired,
        uint256 idSlippage,
        uint256 activeId
    );
    error LBRouter__InsufficientAmountOut(
        uint256 amountOutMin,
        uint256 amountOut
    );
    error LBRouter__InvalidTokenPath(address wrongToken);
    error LBRouter__LengthsMismatch();
    error LBRouter__MaxAmountInExceeded(uint256 amountInMax, uint256 amountIn);
    error LBRouter__NotFactoryOwner();
    error LBRouter__PairNotCreated(
        address tokenX,
        address tokenY,
        uint256 binStep
    );
    error LBRouter__SenderIsNotWAVAX();
    error LBRouter__SwapOverflows(uint256 id);
    error LBRouter__TooMuchTokensIn(uint256 excess);
    error LBRouter__WrongAmounts(uint256 amount, uint256 reserve);
    error LBRouter__WrongAvaxLiquidityParameters(
        address tokenX,
        address tokenY,
        uint256 amountX,
        uint256 amountY,
        uint256 msgValue
    );
    error LBRouter__WrongTokenOrder();
    error Math128x128__LogUnderflow();
    error Math128x128__PowerUnderflow(uint256 x, int256 y);
    error Math512Bits__MulDivOverflow(uint256 prod1, uint256 denominator);
    error Math512Bits__MulShiftOverflow(uint256 prod1, uint256 offset);
    error Math512Bits__OffsetOverflows(uint256 offset);
    error SafeCast__Exceeds128Bits(uint256 x);
    error SafeCast__Exceeds40Bits(uint256 x);
    error TokenHelper__CallFailed();
    error TokenHelper__NonContract();
    error TokenHelper__TransferFailed();

    function addLiquidity(
        ILBRouter.LiquidityParameters memory _liquidityParameters
    )
        external
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted);

    function addLiquidityAVAX(
        ILBRouter.LiquidityParameters memory _liquidityParameters
    )
        external
        payable
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted);

    function createLBPair(
        address _tokenX,
        address _tokenY,
        uint24 _activeId,
        uint16 _binStep
    ) external returns (address pair);

    function factory() external view returns (address);

    function getIdFromPrice(
        address _LBPair,
        uint256 _price
    ) external view returns (uint24);

    function getPriceFromId(
        address _LBPair,
        uint24 _id
    ) external view returns (uint256);

    function getSwapIn(
        address _LBPair,
        uint256 _amountOut,
        bool _swapForY
    ) external view returns (uint256 amountIn, uint256 feesIn);

    function getSwapOut(
        address _LBPair,
        uint256 _amountIn,
        bool _swapForY
    ) external view returns (uint256 amountOut, uint256 feesIn);

    function oldFactory() external view returns (address);

    function removeLiquidity(
        address _tokenX,
        address _tokenY,
        uint16 _binStep,
        uint256 _amountXMin,
        uint256 _amountYMin,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountX, uint256 amountY);

    function removeLiquidityAVAX(
        address _token,
        uint16 _binStep,
        uint256 _amountTokenMin,
        uint256 _amountAVAXMin,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapAVAXForExactTokens(
        uint256 _amountOut,
        uint256[] memory _pairBinSteps,
        address[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256[] memory amountsIn);

    function swapExactAVAXForTokens(
        uint256 _amountOutMin,
        uint256[] memory _pairBinSteps,
        address[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256 amountOut);

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 _amountOutMin,
        uint256[] memory _pairBinSteps,
        address[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256 amountOut);

    function swapExactTokensForAVAX(
        uint256 _amountIn,
        uint256 _amountOutMinAVAX,
        uint256[] memory _pairBinSteps,
        address[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 _amountIn,
        uint256 _amountOutMinAVAX,
        uint256[] memory _pairBinSteps,
        address[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256[] memory _pairBinSteps,
        address[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256[] memory _pairBinSteps,
        address[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountOut);

    function swapTokensForExactAVAX(
        uint256 _amountAVAXOut,
        uint256 _amountInMax,
        uint256[] memory _pairBinSteps,
        address[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory amountsIn);

    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        uint256[] memory _pairBinSteps,
        address[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory amountsIn);

    function sweep(address _token, address _to, uint256 _amount) external;

    function sweepLBToken(
        address _lbToken,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;

    function wavax() external view returns (address);

    struct LiquidityParameters {
        address tokenX;
        address tokenY;
        uint256 binStep;
        uint256 amountX;
        uint256 amountY;
        uint256 amountXMin;
        uint256 amountYMin;
        uint256 activeIdDesired;
        uint256 idSlippage;
        int256[] deltaIds;
        uint256[] distributionX;
        uint256[] distributionY;
        address to;
        uint256 deadline;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMasterchefJoeTrader {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingTokens(
        uint256 _pid,
        address _user
    )
        external
        view
        returns (
            uint256 pendingJoe,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function userInfo(
        uint256 _pid,
        address _user
    ) external view returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategyMasterchefFarmV2 {
    /// @dev Universal instalation params.
    struct InstallParams {
        address controller;
        address router; 
        address treasury;
        uint16 protocolFee;
        uint16 slippage;
    }

    /// @dev Emitted when reards get autocompounded.
    event Compounded(uint256 rewardAmount, uint256 fee, uint256 time);

    /// @dev Caller unauthorized.
    error Unauthorized();

    /// @dev Unexpected token address.
    error BadToken();

    /// @dev Strategy disabled.
    error NotActive();

    /// @dev Amount is zero.
    error ZeroAmount();

    /// @dev Address is zero.
    error ZeroAddress();

    /// @dev Protocol paused.
    error OnPause();

    /// @dev Slippage too big.
    error SlippageProtection();

    /// @dev Slippage percentage too big.
    error SlippageTooHigh();

    /// @dev Wrong amount.
    error BadAmount();

    /// @dev Deposits disabled (strategy deprecated).
    error WithdrawOnly();

    /// @dev Strategy disabled.
    error StrategyDisabled();

    /// @dev Different size of arrays.
    error ArrayDifferentLength();

    /// @dev No rewards to claim.
    error NoRewardsAvailable();

    /// @dev Reentrancy detected.
    error Reentrancy();
    
    function balance() external view returns (uint256);

    function claimable()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    function deposit(
        address user,
        IERC20 depositToken,
        bytes memory data
    ) external returns (uint256);

    function withdraw(
        address user,
        uint256 shares,
        IERC20 tokenOut,
        bytes memory data
    ) external returns (uint256);

    function migrate(uint16 slippage) external returns (uint256 amountOut);

    function autocompound(uint16 slippage) external;

    function quotePotentialWithdraw(
        uint256 shares,
        address[] calldata path1,
        address[] calldata path2,
        bytes calldata data,
        uint256 price1,
        uint256 price2
    ) external view returns (uint256 amountOut);

    function allocationOf(address user) external view returns (uint256);

    function totalAllocation() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *        __                   __
 *       / /   ___  ___  _____/ /_
 *      / /   / _ \/ _ \/ ___/ __ \
 *     / /___/  __/  __/ /__/ / / / v.0.2-beta
 *    /_____/\___/\___/\___/_/ /_/           __
 *    / __ \_________  / /_____  _________  / /
 *   / /_/ / ___/ __ \/ __/ __ \/ ___/ __ \/ /
 *  / ____/ /  / /_/ / /_/ /_/ / /__/ /_/ / /
 * /_/   /_/   \____/\__/\____/\___/\____/_/
 *
 * @title Leech Protocol helpers and utilities.
 * @author Leech Protocol (https://app.leechprotocol.com/).
 * @custom:version 0.2-beta.
 * @custom:security Found vulnerability? Get reward here [email protected]
 */
library Helpers {
    /// @dev SafeERC20 library from OpenZeppelin.
    using SafeERC20 for IERC20;

    /// @notice For decimals (1 = 0.01).
    uint16 public constant DENOMINATOR = 10000;

    /// @notice Leech Protocol fee is limited by 20%.
    uint16 public constant MAX_FEE = 2000;

    /// @notice Percent is more than denominator or max fee amount.
    error PercentExeedsMaximalValue();

    /**
     * @notice Calc protocol fee amount.
     * @param amount Full amount.
     * @param fees Slippage percent.
     * @return Fee amount.
     */
    function calcFee(
        uint256 amount,
        uint16 fees
    ) external pure returns (uint256) {
        if (fees == 0) return 0;
        if (fees > MAX_FEE) revert PercentExeedsMaximalValue();

        return (amount * fees) / DENOMINATOR;
    }

    /**
     * @notice Calc minAmount for tokens swap.
     * @param amount Full amount.
     * @param slippage Slippage tolerance percentage (1% = 100).
     * @return Minimal token amount after swap.
     */
    function withSlippage(
        uint256 amount,
        uint16 slippage
    ) external pure returns (uint256) {
        if (slippage == 0) return amount;
        if (slippage > DENOMINATOR) revert PercentExeedsMaximalValue();

        return amount - ((amount * slippage) / DENOMINATOR);
    }

    /**
     * @notice Converts "abi.encode(address)" string back to address.
     * @param b Bytes with address.
     * @return decoded Recovered address.
     */
    function toAddress(
        bytes calldata b
    ) external pure returns (address decoded) {
        decoded = abi.decode(b, (address));
    }

    /**
     * @notice Emergency withdraw for stuck tokens.
     * @param token Token instance.
     */
    function rescue(IERC20 token) external {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @notice Approve tokens for external contract.
     * @param token Token instance.
     * @param to Address to be approved.
     */
    function approveAll(IERC20 token, address to) external {
        if (token.allowance(address(this), to) != type(uint256).max) {
            token.safeApprove(address(to), type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStrategyMasterchefFarmV2.sol";
import "./ILeechRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *        __                   __
 *       / /   ___  ___  _____/ /_
 *      / /   / _ \/ _ \/ ___/ __ \
 *     / /___/  __/  __/ /__/ / / / v.0.2-beta
 *    /_____/\___/\___/\___/_/ /_/           __
 *    / __ \_________  / /_____  _________  / /
 *   / /_/ / ___/ __ \/ __/ __ \/ ___/ __ \/ /
 *  / ____/ /  / /_/ / /_/ /_/ / /__/ /_/ / /
 * /_/   /_/   \____/\__/\____/\___/\____/_/
 *
 * @title Base farming strategy.
 * @author Leech Protocol (https://app.leechprotocol.com/).
 * @custom:version 0.2-beta.
 * @custom:security Found vulnerability? Get reward ([email protected]).
 */
abstract contract BaseFarmStrategy is Ownable, IStrategyMasterchefFarmV2 {
    /// @dev SafeERC20 library from OpenZeppelin.
    using SafeERC20 for IERC20;

    /// @notice The protocol fee limit is 12%.
    uint16 public constant MAX_FEE = 1200;

    /// @notice Used for fractional part (1 = 0.01)
    uint16 public constant DENOMINATOR = 10000;

    /// @notice Address of Leech's backend.
    address public controller;

    /// @notice Address of LeechRouter.
    address public router;

    /// @notice Treasury address.
    address public treasury;

    /// @notice Leech's comission.
    uint16 public protocolFee;

    /// @notice Sum of all users shares.
    uint256 public totalAllocation;

    /// @notice Swap slippage.
    uint16 public slippage = 50; // 0.5% by default

    /// @notice For migration process.
    bool public isActive = true;

    /// @notice For migration process.
    bool public isWithdrawOnly;

    /// @dev Re-entrancy lock.
    bool private locked;

    /// @notice Share of user
    mapping(address => uint256) public allocationOf;

    /// @dev Limit access for the LeechRouter only.
    modifier onlyRouter() {
        if (msg.sender != router) revert Unauthorized();
        _;
    }

    /// @dev Unsigned integer should be great than zero.
    modifier notZeroAmount(uint256 amountToCheck) {
        if (amountToCheck == 0) revert ZeroAmount();
        _;
    }

    /// @dev Address shouldn't be empty.
    modifier notZeroAddress(address addressToCheck) {
        if (addressToCheck == address(0)) revert ZeroAddress();
        _;
    }

    /// @dev Strategy should be active.
    modifier enabled() {
        if (!isActive) revert StrategyDisabled();
        _;
    }

    /// @dev Re-entrancy lock
    modifier lock() {
        if (locked) revert Reentrancy();
        locked = true;
        _;
        locked = false;
    }

    /**
     * @notice Executes on contract deployment.
     * @param params General strategy parameters.
     */
    constructor(InstallParams memory params) {
        // Set params on deploy
        (controller, router, treasury, protocolFee, slippage) = (
            params.controller,
            params.router,
            params.treasury,
            params.protocolFee,
            params.slippage
        );
    }

    /**
     * @notice Take fees and re-invests rewards.
     */
    function autocompound(uint16) public virtual enabled {
        // Revert if protocol paused
        if (ILeechRouter(router).paused()) revert OnPause();
    }

    /**
     * @notice Depositing into the farm pool.
     * @dev Only LeechRouter can call this function.
     * @dev Re-entrancy lock on the LeechRouter side.
     * @param user User address.
     * @param depositToken Incoming token.
     * @param data Additional data.
     * @return share Deposit allocation.
     */
    function deposit(
        address user,
        IERC20 depositToken,
        bytes memory data
    ) public virtual onlyRouter enabled returns (uint256 share) {
        if (isWithdrawOnly) revert WithdrawOnly();
        // Get external LP amount
        share = _deposit(data, depositToken);
        // Balance of SSLP before deposit
        uint256 _initialBalance = balance() - share;
        // Second+ deposit
        if (totalAllocation != 0 && _initialBalance != 0) {
            // Calc deposit share
            share = (share * totalAllocation) / _initialBalance;
        }
        // Update user allocation
        allocationOf[user] += share;
        // Update total allcation
        totalAllocation += share;
        // Revert is nothing to deposit
        if (share == 0) revert ZeroAmount();
    }

    /**
     * @notice Withdrawing staking token (LP) from the strategy.
     * @dev Can only be called by LeechRouter.
     * @dev Re-entrancy lock on the LeechRouter side.
     * @param user User address.
     * @param shares Amount of the strategy shares to be withdrawn.
     * @param tokenOut Token to be swapped to.
     * @param data Output token encoded to bytes string.
     * @return tokenOutAmount Amount of the token returned to LeechRouter.
     */
    function withdraw(
        address user,
        uint256 shares,
        IERC20 tokenOut,
        bytes memory data
    )
        public
        virtual
        onlyRouter
        enabled
        notZeroAmount(shares)
        returns (uint256 tokenOutAmount)
    {
        // Is amount more than user have?
        if (shares > allocationOf[user]) revert BadAmount();
        // Calc amount in LP tokens
        uint256 _lpAmount = (balance() * shares) / totalAllocation;
        // Reduce shares if not migration
        if (user != address(this)) {
            allocationOf[user] -= shares;
            totalAllocation -= shares;
        }
        // Withdraw to, amount, path1...
        tokenOutAmount = _withdraw(router, _lpAmount, tokenOut, data, slippage);
    }

    function migrate(
        uint16 slippage_
    ) external virtual enabled onlyRouter returns (uint256) {
        isActive = false;
        return _withdraw(router, balance(), IERC20(base()), "", slippage_);
    }

    function panic(uint16 slippage_) external virtual enabled onlyOwner {
        isActive = false;
        _withdraw(owner(), balance(), IERC20(base()), "", slippage_);
    }

    /**
     * @notice Sets fee taken by the Leech protocol.
     * @dev Only owner can set the protocol fee.
     * @param _fee Fee value.
     */
    function setFee(uint16 _fee) external virtual onlyOwner {
        if (_fee > MAX_FEE) revert BadAmount();
        protocolFee = _fee;
    }

    /**
     * @notice Sets the tresury address.
     * @dev Only owner can set the treasury address.
     * @param _treasury The address to be set.
     */
    function setTreasury(address _treasury) external virtual onlyOwner {
        if (_treasury == address(0)) revert ZeroAddress();
        treasury = _treasury;
    }

    /**
     * @notice Sets the controller address.
     * @dev Only owner can set the controller address.
     * @param _controller The address to be set.
     */
    function setController(address _controller) external virtual onlyOwner {
        if (_controller == address(0)) revert ZeroAddress();
        controller = _controller;
    }

    /**
     * @notice Sets slippage tolerance.
     * @dev Only owner can set the slippage tolerance.
     * @param _slippage Slippage percent (1 == 0.01%).
     */
    function setSlippage(uint16 _slippage) external virtual onlyOwner {
        if (_slippage > DENOMINATOR) revert SlippageTooHigh();
        if (_slippage == 0) revert ZeroAmount();
        slippage = _slippage;
    }

    /**
     * @notice Allows the owner to withdraw stuck tokens from the contract's balance.
     * @dev Only owner can withdraw tokens.
     * @param _token Address of the token to be withdrawn.
     * @param _amount Amount to be withdrawn.
     */
    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount
    ) external virtual onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     * @dev Depositing into the farm pool.
     * @return share External pool deposit LP amount.
     */
    function _deposit(
        bytes memory,
        IERC20
    ) internal virtual returns (uint256 share) {}

    /**
     * @dev Withdrawing staking token (LP) from the strategy.
     * @return tokenOutAmount Amount of the token returned to LeechRouter.
     */
    function _withdraw(
        address,
        uint256,
        IERC20,
        bytes memory,
        uint16
    ) internal virtual returns (uint256 tokenOutAmount) {}

    /**
     * @notice Function returns estimated amount of token out from the LP withdrawn LP amount.
     * @param shares Amount of shares.
     * @param token0toTokenOut Path to output token.
     * @param token1toTokenOut Path to output token.
     * @param data Additional params.
     * @param price0 Price of token0.
     * @param price1 Price of token1.
     */
    function quotePotentialWithdraw(
        uint256 shares,
        address[] calldata token0toTokenOut,
        address[] calldata token1toTokenOut,
        bytes calldata data,
        uint256 price0,
        uint256 price1
    ) public view virtual returns (uint256 amountOut) {}

    /**
     * @notice Address of base token.
     * @return Base token address.
     */
    function base() public view virtual returns (address) {
        return ILeechRouter(router).base();
    }

    /**
     * @notice Amount of LPs staked into Masterchef.
     * @return amount LP amount.
     */
    function balance() public view virtual returns (uint256 amount) {}

    /**
     * @notice Amounts of pending rewards.
     * @return tokens Array of reward tokens.
     * @return amounts Array of reward amounts.
     */
    function claimable()
        public
        view
        virtual
        returns (address[] memory tokens, uint256[] memory amounts)
    {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface ILeechRouter {
    function base() external view returns (address);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../../interfaces/IJoeTraderRouter.sol";
import "../../interfaces/IJoeTraderPair.sol";
import "../../interfaces/ILBRouter.sol";
import "../../interfaces/ILBFactory.sol";
import "../../interfaces/IMasterchefJoeTrader.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../libraries/Helpers.sol";
import "./../BaseFarmStrategy.sol";


contract StrategyJoeTraderV2 is BaseFarmStrategy {
    using SafeERC20 for IERC20;

    /// @dev To extract address from bytes.
    using Helpers for bytes;

    /// @dev To calc slippage.
    using Helpers for uint256;

    /// @dev For max approve.
    using Helpers for IERC20;

     /// @notice Velodrome router
    IJoeTraderRouter public constant joeV1Router =
        IJoeTraderRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

    ILBRouter public constant joeV2Router = 
        ILBRouter(0xE3Ffc583dC176575eEA7FD9dF2A7c65F7E23f4C3);

    /// @notice Pool reward.
    IERC20 public constant rewardToken =
        IERC20(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd);

    /// @notice First token of the pair.
    IERC20 public immutable token0;

    /// @notice Second token of the pair.
    IERC20 public immutable token1;

    address public baseToken = ILeechRouter(router).base();

    /// @notice LP token.
    IJoeTraderPair public immutable lp;

    /// @notice Pair gauge.
    IMasterchefJoeTrader public immutable masterchef;

    /// @notice External pool id.
    uint16 public immutable poolId;

    /// @notice Route pathes
    /// @dev tokenIn => tokenOut => Velodrome routes array
    mapping(IERC20 => mapping(IERC20 => address[]))
        public routes;

    /**
     * @notice Executes on contract deployment.
     * @param params General strategy parameters.
     * @param _token0 First token of the pair.
     * @param _token1 Second token of the pair.
     * @param _lp LP token.
     * @param _poolId Sushi's pool id.
     */
    constructor(
        InstallParams memory params,
        IERC20 _token0,
        IERC20 _token1,
        IJoeTraderPair _lp,
        IMasterchefJoeTrader _masterchef,
        uint16 _poolId
    ) BaseFarmStrategy(params) {
        // Set params on deploy
        (token0, token1, lp, masterchef, poolId) = (
            _token0,
            _token1,
            _lp,
            _masterchef,
            _poolId
        );

        routes[rewardToken][token0] 
            = [0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd, 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E, 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7];
        routes[token0][IERC20(baseToken)] 
            = [0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7, 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E];
        routes[token0][token1] 
            = [0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7, 0xc7198437980c041c805A1EDcbA50c1Ce5db95118];
        routes[token1][token0] 
            = [0xc7198437980c041c805A1EDcbA50c1Ce5db95118, 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7];
        routes[token1][IERC20(baseToken)] 
            = [0xc7198437980c041c805A1EDcbA50c1Ce5db95118, 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7, 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E];
        routes[IERC20(baseToken)][token0] 
            = [0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E, 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7];



        // Approve ERC20 transfers
        IERC20(address(lp)).approveAll(address(masterchef));
        token0.approveAll(address(joeV2Router));
        token1.approveAll(address(joeV2Router));
        token0.approveAll(address(joeV1Router));
        token1.approveAll(address(joeV1Router));
        token1.approveAll(address(joeV1Router));
        rewardToken.approveAll(address(joeV2Router));
        IERC20(baseToken).approveAll(address(joeV2Router));
    }

    /**
     * @notice Re-invests rewards.
     */
    function autocompound(uint16) public override {
        // Execute parent
        super.autocompound(0);
        // Do we have something to claim?
        (address[] memory _tokens, uint256[] memory _claimable) = claimable();
        if (_claimable[0] == 0) revert ZeroAmount();
        // Get rewards
        IMasterchefJoeTrader(masterchef).deposit(
            poolId,
            0
        );
        // Get reward amount
        uint256 reward = rewardToken.balanceOf(address(this));
        // Calc fee
        uint256 fee = (reward * protocolFee) / DENOMINATOR;
        // Send fee to the treasure
        rewardToken.safeTransfer(treasury, fee);
        // Re-invest reward
         address[] memory rewardPath = new address[](1);
        rewardPath[0] = address(rewardToken);
        // Re-invest reward
        _deposit("", rewardToken);
        // Notify services
        emit Compounded(reward, fee, block.timestamp);
    }

    /**
     * @notice Sets pathes for tokens swap.
     * @dev Only owner can set a pathes.
     * @param tokenIn From token.
     * @param tokenOut To token.
     * @param routesList Router route array.
     */
    function setRoutes(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address[] calldata routesList
    ) external onlyOwner {
        routes[tokenIn][tokenOut] = routesList;
    }

    /**
     * @notice Depositing into the farm pool.
     * @param depositToken Token in.
     * @return shares Pool share of user.
     */
    function _deposit(
        bytes memory,
        IERC20 depositToken
    ) internal override returns (uint256 shares) {
        // Check depositToken
        if (
            depositToken != token0 && depositToken != token1 && depositToken != rewardToken && depositToken != IERC20(baseToken)
        ) revert BadToken();
        
        // Get balance of deposit token
        uint256 tokenBal =  depositToken.balanceOf(address(this));
        // Revert if zero amount
        if (tokenBal == 0) revert ZeroAmount();
        // Convert to token0
        if (address(depositToken) != address(token0)) {
        joeV2Router.swapExactTokensForTokens(
            tokenBal,
            0,
            _getBins(routes[depositToken][token0]),
            routes[depositToken][token0],
            address(this),
            block.timestamp
        );
        }
        // Get deposit amount
        uint256 fullInvestment = token0.balanceOf(address(this));
        // Swap half amount to second token
        uint256[] memory swapedAmounts = joeV1Router
            .swapExactTokensForTokens(
                fullInvestment / 2,
                0,
                routes[token0][token1],
                address(this),
                block.timestamp
            );
        // Stake tokens
        joeV1Router.addLiquidity(
            address(token0),
            address(token1),
            fullInvestment / 2,
            swapedAmounts[swapedAmounts.length - 1],
            1,
            1,
            address(this),
            block.timestamp
        );
        // Get deposit amount in LP
        shares = IERC20(address(lp)).balanceOf(address(this));
        // Deposit into farm
        masterchef.deposit(poolId, shares);
    }

    /**
     * @notice Withdrawing staking token (LP) from the strategy.
     * @dev Can only be called by LeechRouter.
     * @param shares Amount of the strategy shares to be withdrawn.
     * @return tokenOutAmount Amount of the token returned to LeechRouter.
     */
    function _withdraw(
        address,
        uint256 shares,
        IERC20 withdrawToken,
        bytes memory,
        uint16
    ) internal override returns (uint256 tokenOutAmount) {
        // Unstake LPs
        masterchef.withdraw(poolId, shares);
        // Disassembly LPs
        IERC20(address(lp)).safeTransfer(
            address(lp),
            IERC20(address(lp)).balanceOf(address(this))
        );
        lp.burn(address(this));
        // Swap token0 to base token if needed
        if (address(token0) != address(withdrawToken)) {
            joeV2Router.swapExactTokensForTokens(
                token0.balanceOf(address(this)),
                0,
                _getBins(routes[token0][withdrawToken]),
                routes[token0][withdrawToken],
                address(this),
                block.timestamp
            );
        }

        // Swap token1 to base token if needed
        if (address(token1) != address(withdrawToken)) {
            joeV2Router.swapExactTokensForTokens(
                token1.balanceOf(address(this)),
                0,
                _getBins(routes[token1][withdrawToken]),
                routes[token1][withdrawToken],
                address(this),
                block.timestamp
            );
        }
        // Get balance of the base token
        tokenOutAmount = withdrawToken.balanceOf(address(this));
        // Send to LeechRouter for withdraw
       withdrawToken.safeTransfer(router, tokenOutAmount);
    }

    /**
     * @notice Amount of LPs staked into Masterchef
     */
    function balance() public view override returns (uint256 amountWant) {
        (amountWant, ) = masterchef.userInfo(
            poolId,
            address(this)
        );
    }

    /**
     * @notice Function returns estimated amount of token out from the LP withdrawn LP amount.
     * @param shares Amount of shares.
     */
    function quotePotentialWithdraw(
        uint256 shares,
        address[] calldata,
        address[] calldata,
        bytes calldata,
        uint256,
        uint256
        ) public view override returns(uint256 amountOut) {
            // Convert shares to LP amount
            uint256 wantBalance = balance() * shares / totalAllocation;
            // Get pool reserves
            (uint256 reserve0, uint256 reserve1, ) = lp.getReserves();
            // Get pool total supply
            uint256 totalSupply = lp.totalSupply();
            // Amount of token0
            uint256 token0Amount = (wantBalance * reserve0) / totalSupply;
            // Amount of token1
            uint256 token1Amount = (wantBalance * reserve1) / totalSupply;
            
            amountOut = 0;

        if (address(token1) != baseToken) {
            amountOut += joeV1Router.getAmountsOut(token0Amount, routes[token0][IERC20(baseToken)])[routes[token0][IERC20(baseToken)].length - 1];
        } else {
            amountOut += token0Amount;
        }

        if (address(token1) != baseToken) {
            amountOut += joeV1Router.getAmountsOut(token1Amount, routes[token1][IERC20(baseToken)])[routes[token1][IERC20(baseToken)].length - 1];
        } else {
            amountOut += token1Amount;
        }
    }

    /**
     * @notice Amount of pending rewards
     * @return tokens Array of reward tokens.
     * @return amounts Array of reward amounts.
     */
    function claimable()
        public
        view
        override
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        tokens = new address[](1);
        amounts = new uint256[](1);
        tokens[0] = address(rewardToken);  
        (amounts[0], , , ) = masterchef.pendingTokens(poolId, address(this));
    }

    /**
     *@dev Receive pair data from JoeTrader V2 for swap
     *@param path Path to out-token
     */
    function _getBins(address[] memory path) private view returns (uint256[] memory bins) {
        address factory = ILBRouter(joeV2Router).factory();
        bins = new uint256[](path.length - 1);

        for (uint16 i = 0; i < bins.length; i++) {
            address _tokenX = path[i];
            address _tokenY = path[i + 1];
            ILBFactory.LBPairInformation[] memory response = ILBFactory(factory).getAllLBPairs(_tokenX, _tokenY);
            bins[i] = uint256(response[0].binStep);
        }
    }



}