// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20 as _IERC20} from "@openzeppelin/contracts-solc8/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 is _IERC20 {
    function nonces(address) external view returns (uint256); // Only tokens that support permit

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external; // Only tokens that support permit

    function mint(address to, uint256 amount) external; // only tokens that support minting
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import {Address} from "@openzeppelin/contracts-solc8/utils/Address.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;
pragma experimental ABIEncoderV2;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAdapter} from "./interfaces/IAdapter.sol";

import {IERC20} from "@synapseprotocol/sol-lib/contracts/solc8/erc20/IERC20.sol";
import {IWETH9} from "@synapseprotocol/sol-lib/contracts/universal/interfaces/IWETH9.sol";
import {SafeERC20} from "@synapseprotocol/sol-lib/contracts/solc8/erc20/SafeERC20.sol";

import {Ownable} from "@openzeppelin/contracts-4.4.2/access/Ownable.sol";

// solhint-disable reason-string

abstract contract Adapter is Ownable, IAdapter {
    using SafeERC20 for IERC20;

    string public name;
    uint256 public swapGasEstimate;

    uint256 internal constant UINT_MAX = type(uint256).max;

    constructor(string memory _name, uint256 _swapGasEstimate) {
        name = _name;
        setSwapGasEstimate(_swapGasEstimate);
    }

    /**
     * @notice Fallback function
     * @dev use recoverGAS() to recover GAS sent to this contract
     */
    receive() external payable {
        // silence the linter
        this;
    }

    /// @dev this is estimated amount of gas that's used by swap() implementation
    function setSwapGasEstimate(uint256 _swapGasEstimate) public onlyOwner {
        swapGasEstimate = _swapGasEstimate;
        emit UpdatedGasEstimate(address(this), _swapGasEstimate);
    }

    // -- RESTRICTED ALLOWANCE FUNCTIONS --

    function setInfiniteAllowance(IERC20 token, address spender)
        external
        onlyOwner
    {
        _setInfiniteAllowance(token, spender);
    }

    /**
     * @notice Revoke token allowance
     *
     * @param token address
     * @param spender address
     */
    function revokeTokenAllowance(IERC20 token, address spender)
        external
        onlyOwner
    {
        token.safeApprove(spender, 0);
    }

    // -- RESTRICTED RECOVER TOKEN FUNCTIONS --

    /**
     * @notice Recover ERC20 from contract
     * @param token token to recover
     */
    function recoverERC20(IERC20 token) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "Adapter: Nothing to recover");

        emit Recovered(address(token), amount);
        token.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Recover GAS from contract
     */
    function recoverGAS() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Adapter: Nothing to recover");

        emit Recovered(address(0), amount);
        //solhint-disable-next-line
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "GAS transfer failed");
    }

    /**
     * @return Address to transfer tokens in order for swap() to work
     */

    function depositAddress(address tokenIn, address tokenOut)
        external
        view
        returns (address)
    {
        return _depositAddress(tokenIn, tokenOut);
    }

    /**
     * @notice Get query for a swap through this adapter
     *
     * @param amountIn input amount in starting token
     * @param tokenIn ERC20 token being sold
     * @param tokenOut ERC20 token being bought
     */
    function query(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256) {
        if (
            amountIn == 0 ||
            tokenIn == tokenOut ||
            !_checkTokens(tokenIn, tokenOut)
        ) {
            return 0;
        }
        return _query(amountIn, tokenIn, tokenOut);
    }

    /**
     * @notice Execute a swap with given input amount of tokens from tokenIn to tokenOut,
     *         assuming input tokens were transferred to depositAddress(tokenIn, tokenOut)
     *
     * @param amountIn input amount in starting token
     * @param tokenIn ERC20 token being sold
     * @param tokenOut ERC20 token being bought
     * @param to address where swapped funds should be sent to
     *
     * @return amountOut amount of tokenOut tokens received in swap
     */
    function swap(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address to
    ) external returns (uint256 amountOut) {
        require(amountIn != 0, "Adapter: Insufficient input amount");
        require(to != address(0), "Adapter: to cannot be zero address");
        require(tokenIn != tokenOut, "Adapter: Tokens must differ");
        require(_checkTokens(tokenIn, tokenOut), "Adapter: unknown tokens");
        _approveIfNeeded(tokenIn, amountIn);
        amountOut = _swap(amountIn, tokenIn, tokenOut, to);
    }

    // -- INTERNAL FUNCTIONS

    /**
     * @notice Return expected funds to user
     *
     * @dev this will do nothing, if funds need to stay in this contract
     *
     * @param token address
     * @param amount tokens to return
     * @param to address where funds should be sent to
     */
    function _returnTo(
        address token,
        uint256 amount,
        address to
    ) internal {
        if (address(this) != to) {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /**
     * @notice Check allowance, and update if it is not big enough
     *
     * @param token token to check
     * @param amount minimum allowance that we need
     * @param spender address that will be given allowance
     */
    function _checkAllowance(
        IERC20 token,
        uint256 amount,
        address spender
    ) internal {
        uint256 _allowance = token.allowance(address(this), spender);
        if (_allowance < amount) {
            // safeApprove should only be called when setting an initial allowance,
            // or when resetting it to zero. (c) openzeppelin
            if (_allowance != 0) {
                token.safeApprove(spender, 0);
            }
            token.safeApprove(spender, UINT_MAX);
        }
    }

    function _setInfiniteAllowance(IERC20 token, address spender) internal {
        _checkAllowance(token, UINT_MAX, spender);
    }

    // -- INTERNAL VIRTUAL FUNCTIONS

    /**
     * @notice Approves token for the underneath swapper to use
     *
     * @dev Implement via _checkAllowance(tokenIn, amount, POOL)
     *      if actually needed
     */
    function _approveIfNeeded(address, uint256) internal virtual {
        this;
    }

    /**
     * @notice Checks if a swap between two tokens is supported by adapter
     */
    function _checkTokens(address, address)
        internal
        view
        virtual
        returns (bool)
    {
        return true;
    }

    /**
     * @notice Internal implementation for depositAddress
     *
     * @dev This aims to reduce the amount of extra token transfers:
     *      some (1) of underneath swappers will have the ability to receive tokens and then swap,
     *      while some (2) will only be able to pull tokens while swapping.
     *      Use swapper address for (1) and Adapter address for (2)
     */
    function _depositAddress(address tokenIn, address tokenOut)
        internal
        view
        virtual
        returns (address);

    /**
     * @notice Internal implementation of a swap
     *
     * @dev 1. All variables are already checked
     *      2. Use _returnTo(tokenOut, amountOut, to) to return tokens, only if
     *         underneath swapper can't send swapped tokens to arbitrary address.
     *      3. Wrapping is handled external to this function
     *
     * @param amountIn amount being sold
     * @param tokenIn ERC20 token being sold
     * @param tokenOut ERC20 token being bought
     * @param to Where received tokens are sent to
     *
     * @return Amount of tokenOut tokens received in swap
     */
    function _swap(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address to
    ) internal virtual returns (uint256);

    /**
     * @notice Internal implementation of query
     *
     * @dev All variables are already checked.
     *      This should ALWAYS return amountOut such as: the swapper underneath
     *      is able to produce AT LEAST amountOut in exchange for EXACTLY amountIn
     *      For efficiency reasons, returning the exact quote is preferable,
     *      however, if the swapper doesn't have a reliable quoting method,
     *      it's safe to underquote the swapped amount
     *
     * @param amountIn input amount in starting token
     * @param tokenIn ERC20 token being sold
     * @param tokenOut ERC20 token being bought
     */
    function _query(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@synapseprotocol/sol-lib/contracts/solc8/erc20/IERC20.sol";

interface ISynapse {
    // pool data view functions
    function getA() external view returns (uint256);

    function getAPrecise() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function paused() external view returns (bool);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    function swapStorage()
        external
        view
        returns (
            uint256 initialA,
            uint256 futureA,
            uint256 initialATime,
            uint256 futureATime,
            uint256 swapFee,
            uint256 adminFee,
            address lpToken
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISynapse} from "../interfaces/ISynapse.sol";
import {Adapter} from "../../Adapter.sol";
import {SwapCalculator} from "../../helper/SwapCalculator.sol";

import {IERC20} from "@synapseprotocol/sol-lib/contracts/solc8/erc20/IERC20.sol";

//solhint-disable not-rely-on-time

contract SynapseBaseAdapter is SwapCalculator, Adapter {
    mapping(address => bool) public isPoolToken;
    mapping(address => uint256) public tokenIndex;

    constructor(
        string memory _name,
        uint256 _swapGasEstimate,
        address _pool
    ) SwapCalculator(ISynapse(_pool)) Adapter(_name, _swapGasEstimate) {
        this;
    }

    function _addPoolToken(IERC20 token, uint256 index)
        internal
        virtual
        override
    {
        SwapCalculator._addPoolToken(token, index);
        _registerPoolToken(token, index);
    }

    function _registerPoolToken(IERC20 token, uint256 index) internal {
        isPoolToken[address(token)] = true;
        tokenIndex[address(token)] = index;
        _setInfiniteAllowance(token, address(pool));
    }

    function _checkTokens(address _tokenIn, address _tokenOut)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return isPoolToken[_tokenIn] && isPoolToken[_tokenOut];
    }

    function _depositAddress(address, address)
        internal
        view
        override
        returns (address)
    {
        return address(this);
    }

    function _swap(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        address _to
    ) internal virtual override returns (uint256 _amountOut) {
        _amountOut = pool.swap(
            uint8(tokenIndex[_tokenIn]),
            uint8(tokenIndex[_tokenOut]),
            _amountIn,
            0,
            block.timestamp
        );

        _returnTo(_tokenOut, _amountOut, _to);
    }

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) internal view virtual override returns (uint256 _amountOut) {
        if (pool.paused()) {
            return 0;
        }
        try
            pool.calculateSwap(
                uint8(tokenIndex[_tokenIn]),
                uint8(tokenIndex[_tokenOut]),
                _amountIn
            )
        returns (uint256 amountOut) {
            _amountOut = amountOut;
        } catch {
            return 0;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../adapters/interfaces/ISynapse.sol";

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

contract SwapCalculator {
    // Struct storing variables used in calculations in the
    // {add,remove}Liquidity functions to avoid stack too deep errors
    struct ManageLiquidityInfo {
        uint256 d0;
        uint256 d1;
        uint256 preciseA;
        uint256 totalSupply;
        uint256[] balances;
        uint256[] multipliers;
    }

    ISynapse public immutable pool;
    IERC20 public immutable lpToken;
    uint256 public immutable numTokens;
    uint256 public swapFee;
    uint256 private swapFeePerToken;

    IERC20[] public poolTokens;
    uint256[] private tokenPrecisionMultipliers;

    uint8 private constant POOL_PRECISION_DECIMALS = 18;
    uint256 private constant A_PRECISION = 100;
    uint256 private constant FEE_DENOMINATOR = 10**10;

    constructor(ISynapse _pool) {
        pool = _pool;
        (, , , , uint256 _swapFee, , address _lpToken) = _pool.swapStorage();
        lpToken = IERC20(_lpToken);
        // set numTokens prior to swapFee
        numTokens = _setPoolTokens(_pool);
        _setSwapFee(_swapFee);
    }

    function updateSwapFee() external {
        (, , , , uint256 _swapFee, , ) = pool.swapStorage();
        _setSwapFee(_swapFee);
    }

    function calculateAddLiquidity(uint256[] memory _amounts)
        public
        view
        returns (uint256)
    {
        require(
            _amounts.length == numTokens,
            "Amounts must match pooled tokens"
        );
        uint256 _numTokens = numTokens;

        ManageLiquidityInfo memory v = ManageLiquidityInfo(
            0,
            0,
            pool.getAPrecise(),
            lpToken.totalSupply(),
            new uint256[](_numTokens),
            tokenPrecisionMultipliers
        );

        uint256[] memory newBalances = new uint256[](_numTokens);

        for (uint8 _i = 0; _i < _numTokens; _i++) {
            v.balances[_i] = ISynapse(pool).getTokenBalance(_i);
            newBalances[_i] = v.balances[_i] + _amounts[_i];
        }

        if (v.totalSupply != 0) {
            v.d0 = _getD(_xp(v.balances, v.multipliers), v.preciseA);
        } else {
            // pool is empty => all amounts must be >0
            for (uint8 i = 0; i < _numTokens; i++) {
                require(_amounts[i] > 0, "Must supply all tokens in pool");
            }
        }

        // invariant after change
        v.d1 = _getD(_xp(newBalances, v.multipliers), v.preciseA);
        require(v.d1 > v.d0, "D should increase");

        if (v.totalSupply == 0) {
            return v.d1;
        } else {
            for (uint256 _i = 0; _i < _numTokens; _i++) {
                uint256 idealBalance = (v.d1 * v.balances[_i]) / v.d0;
                uint256 fees = (swapFeePerToken *
                    _diff(newBalances[_i], idealBalance)) / FEE_DENOMINATOR;
                newBalances[_i] = newBalances[_i] - fees;
            }
            v.d1 = _getD(_xp(newBalances, v.multipliers), v.preciseA);
            return ((v.d1 - v.d0) * v.totalSupply) / v.d0;
        }
    }

    function _setPoolTokens(ISynapse _pool) internal returns (uint256) {
        for (uint8 i = 0; true; i++) {
            try _pool.getToken(i) returns (IERC20 token) {
                _addPoolToken(token, i);
            } catch {
                break;
            }
        }
        return tokenPrecisionMultipliers.length;
    }

    function _addPoolToken(IERC20 token, uint256) internal virtual {
        IERC20Decimals _token = IERC20Decimals(address(token));
        tokenPrecisionMultipliers.push(
            10**uint256(POOL_PRECISION_DECIMALS - _token.decimals())
        );
        poolTokens.push(token);
    }

    function _setSwapFee(uint256 _swapFee) internal {
        swapFee = _swapFee;
        swapFeePerToken = (swapFee * numTokens) / ((numTokens - 1) * 4);
    }

    /**
     * @notice Get absolute difference between two values
     * @return abs(_a - _b)
     */
    function _diff(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a > _b) {
            return _a - _b;
        } else {
            return _b - _a;
        }
    }

    /**
     * @notice Get pool balances adjusted, as if all tokens had 18 decimals
     */
    function _xp(
        uint256[] memory balances,
        uint256[] memory precisionMultipliers
    ) internal pure returns (uint256[] memory) {
        uint256 _numTokens = balances.length;
        require(
            _numTokens == precisionMultipliers.length,
            "Balances must match multipliers"
        );
        uint256[] memory xp = new uint256[](_numTokens);
        for (uint256 i = 0; i < _numTokens; i++) {
            xp[i] = balances[i] * precisionMultipliers[i];
        }
        return xp;
    }

    /**
     * @notice Get D: pool invariant
     */
    function _getD(uint256[] memory xp, uint256 a)
        internal
        pure
        returns (uint256)
    {
        uint256 _numTokens = xp.length;
        uint256 s;
        for (uint256 _i = 0; _i < _numTokens; _i++) {
            s = s + xp[_i];
        }
        if (s == 0) {
            return 0;
        }

        uint256 prevD;
        uint256 d = s;
        uint256 nA = a * _numTokens;

        for (uint256 _i = 0; _i < 256; _i++) {
            uint256 dP = d;
            for (uint256 j = 0; j < _numTokens; j++) {
                dP = (dP * d) / (xp[j] * _numTokens);
                // If we were to protect the division loss we would have to keep the denominator separate
                // and divide at the end. However this leads to overflow with large numTokens or/and D.
                // dP = dP * D * D * D * ... overflow!
            }
            prevD = d;
            d =
                (((nA * s) / A_PRECISION + dP * _numTokens) * d) /
                (((nA - A_PRECISION) * d) /
                    A_PRECISION +
                    (_numTokens + 1) *
                    dP);

            if (_diff(d, prevD) <= 1) {
                return d;
            }
        }

        revert("D does not converge");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6;

interface IAdapter {
    event UpdatedGasEstimate(address indexed adapter, uint256 newEstimate);

    event Recovered(address indexed asset, uint256 amount);

    function name() external view returns (string memory);

    function swapGasEstimate() external view returns (uint256);

    function depositAddress(address tokenIn, address tokenOut)
        external
        view
        returns (address);

    function swap(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address to
    ) external returns (uint256);

    function query(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256);
}