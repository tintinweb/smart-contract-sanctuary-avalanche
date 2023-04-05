// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IStrategyYak {

    function deposit(address[] calldata path) external returns (uint256);

    function withdraw(uint256 _amountLP, address[] memory _path, address[] memory _nonUsed) external returns (uint256);

    function withdrawAll() external;

    ///@dev Emitted when deposit is called.
    event Deposited(uint256 amount);

    ///@dev Emtted when withdrawal is called.
    event Withdrawn(uint256 amountLP, uint256 amountBaseToken);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IYak{
function deposit(uint256 amount) external;
function withdraw(uint256 amount) external;
function getDepositTokensForShares(uint256 amount)
        external
        view
        returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./interfaces/ILBRouter.sol";
import "./interfaces/ILBFactory.sol";
import "./interfaces/IStrategyYak.sol";
import "./interfaces/IYak.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StrategyYak is Ownable, Pausable, IStrategyYak {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ///@notice Address of Leech's backend.
    address public controller;

    ///@notice Address of LeechRouter.
    address public router;

    ///@notice Address of JoeTrader Router V2
    ILBRouter public uniV2Router;

    address public constant BASE = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    address public constant WANT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;

    ///@notice Address of Yak's pool.
    address public constant YAK = 0xE005883f6c7Db66265d0B8eEaA7009645e0A9f76;

    address[] public pathWantToBase = [WANT, BASE];

    address[] zeroArray = [address(0)];

    modifier onlyOwnerOrController() {
        if (msg.sender != owner() && msg.sender != controller)
            revert("UnauthorizedCaller");
        _;
    }

    constructor(address _controller, address _router, address _uniV2Router) {
        controller = _controller;
        router = _router;
        uniV2Router =  ILBRouter(_uniV2Router);
        IERC20(WANT).safeApprove(YAK, type(uint256).max);
        IERC20(WANT).safeApprove(address(uniV2Router), type(uint256).max);
    }

    /**
     * @notice Depositing into the farm pool.
     */
    function deposit(
        address[] calldata pathTokenInToWant
    ) public whenNotPaused returns (uint256 wantBal) {
        if (msg.sender != router) revert("Unauthorized Caller");
        if (pathTokenInToWant[pathTokenInToWant.length - 1] != WANT) 
            revert ("Wrong token path");
        if (pathTokenInToWant[0] != WANT) {
            uint256 received = IERC20(pathTokenInToWant[0]).balanceOf(
                address(this)
            );
            if (received == 0) revert("Nothing to deposit");
            _approveTokenIfNeeded(pathTokenInToWant[0], address(uniV2Router));
            uniV2Router.swapExactTokensForTokens(
                received,
                0,
                _getBins(pathTokenInToWant),
                pathTokenInToWant,
                address(this),
                block.timestamp
            );
        }

        wantBal = IERC20(WANT).balanceOf(address(this));
       
        IYak(YAK).deposit(wantBal);
        emit Deposited(wantBal);
    }

    /**
     * @notice Withdrawing the staking token from the strategy.
     * @dev Can only be called by LeechRouter.
     * @param _amountLP Amount of the YAK LP token to be withdrawn.
     * @param _pathWantToTokenOut Token swap path.
     * @param _nonUsed Used only for interface unification.
     */
    function withdraw(
        uint256 _amountLP,
        address[] memory _pathWantToTokenOut,
        address[] memory _nonUsed
    ) public whenNotPaused returns (uint256 tokenOutAmount) {
        //For warning remove
        _nonUsed;

        if (msg.sender != router) revert("Unauthorized Caller");
        if (_amountLP == 0) revert ("Zero amount");
        IYak(YAK).withdraw(_amountLP);
        uint256 wantBal = IERC20(WANT).balanceOf(address(this));
        if (_pathWantToTokenOut.length > 1) {
            uniV2Router.swapExactTokensForTokens(
                wantBal,
                0,
                _getBins(_pathWantToTokenOut),
                _pathWantToTokenOut,
                address(this),
                block.timestamp
            );
        }
        address tokenOut = _pathWantToTokenOut[_pathWantToTokenOut.length - 1];
        tokenOutAmount = IERC20(tokenOut).balanceOf(address(this));
        IERC20(tokenOut).safeTransfer(router, tokenOutAmount);
        emit Withdrawn(_amountLP, tokenOutAmount);
    }

    function withdrawAll() external {
        uint256 amountAll = IERC20(YAK).balanceOf(address(this));
        withdraw(amountAll, pathWantToBase, zeroArray);
    }

    /**
     * @notice Pause the contract's activity
     * @dev Only the owner or the controller can pause the contract's activity.
     */
    function pause() external onlyOwnerOrController {
        _pause();
    }

    /**
     * @notice Unpause the contract's activity
     * @dev Only the owner can unpause the contract's activity.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets the controller address
     * @dev Only owner can set the controller address
     * @param _controller The address to be set.
     */
    function setController(address _controller) external onlyOwner {
        if (_controller == address(0)) revert("ZeroAddressAsInput");
        controller = _controller;
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
    ) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     *@dev Approves spender to spend tokens on behalf of the contract.
     *If the contract doesn't have enough allowance, this function approves spender.
     *@param token The address of the token to be approved
     *@param spender The address of the spender to be approved
     */
    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    /**
     * @notice Amount of USDT staked to Yak.
     */
    function balance() public view returns (uint256 amountWant) {
        uint256 amountYak = IERC20(YAK).balanceOf(address(this));
        amountWant = IYak(YAK).getDepositTokensForShares(amountYak);
    }

    /**
     *@dev Receive pair data from JoeTrader V2 for swap
     *@param path Path to out-token
     */
    function _getBins(address[] memory path) private returns (uint256[] memory bins) {
        address factory = ILBRouter(uniV2Router).factory();
        bins = new uint256[](path.length - 1);

        for (uint16 i = 0; i < bins.length; i++) {
            address _tokenX = path[i];
            address _tokenY = path[i + 1];
            ILBFactory.LBPairInformation[] memory response = ILBFactory(factory).getAllLBPairs(_tokenX, _tokenY);
            bins[i] = uint256(response[0].binStep);
        }
    }
}