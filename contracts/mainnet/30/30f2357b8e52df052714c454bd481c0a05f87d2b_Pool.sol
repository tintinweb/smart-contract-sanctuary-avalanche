/**
 *Submitted for verification at snowtrace.io on 2022-05-12
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/pool/libraries/SafeCast.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
 * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}


// File contracts/pool/interfaces/IPoolFactory.sol


pragma solidity ^0.8.7;

interface IPoolFactory {

    function imePerSecond() external view returns (uint256);

    function endTime() external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function yieldImeTo(address to, uint256 amount) external;

    function yieldImcTo(address to, uint256 amount) external;

    function getPoolAddress(address poolToken) external view returns (address);

    function poolExists(address poolAddress) external view returns (bool);

    function factoryOwner() external view returns (address);

    function vault() external view returns (address);

}


// File contracts/pool/interfaces/IPool.sol


pragma solidity ^0.8.7;

interface IPool {

    function poolToken() external view returns (address);

    function weight() external view returns (uint256);

    function stakeAsPool(address staker, uint256 amount) external;

    function setWeight(uint256 weight) external;

}


// File contracts/pool/interfaces/IMarketPlace.sol


pragma solidity ^0.8.7;

interface IMarketPlace {

    function buyItem(address nftAddress, uint256 tokenId, uint256 price, address to) external;

}


// File contracts/pool/Pool.sol


pragma solidity ^0.8.7;









contract Pool is IPool, ReentrancyGuardUpgradeable, PausableUpgradeable {

    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;

    struct UnstakeParameter {
        uint256 stakeId;
        uint256 amount;
    }

    struct StakeData {
        uint120 amount;
        uint64 lockedFrom;
        uint64 lockedUntil;
        bool isYield;
    }

    struct User {
        uint128 pendingYield;
        uint128 pendingRevDis;
        uint256 totalWeight;
        uint256 yieldRewardsPerWeightPaid;
        uint256 vaultRewardsPerWeightPaid;
        StakeData[] stakes;
    }

    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant BASE_WEIGHT = 1e6;
    uint256 internal constant YIELD_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER; // assuming yieldLockUp is 365 days

    uint256 public minStakePeriod;
    uint256 public maxStakePeriod;
    uint256 public yieldLockUpPeriod;
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e20;
    address internal ime;
    address internal imc;

    IPoolFactory public factory;
    address public override poolToken;
    uint256 public globalTotalWeight;
    uint256 public lastYieldDistribution;
    uint256 public override weight;
    uint256 public yieldRewardsPerWeight;
    uint256 public vaultRewardsPerWeight;
    mapping(address => User) public users;
    mapping(address => mapping(bytes4 => bool)) public allowedUseStakedTokenTo;
    uint256 public poolTokenReserve;

    event Staked(address by, address staker, uint256 stakeId, uint256 amount, uint256 lockDuration, bool isYield);
    event Unstaked(address staker, uint256 stakeId, uint256 amount, bool isYield);
    event UseStakedTokenTo(address staker, uint256 stakeId, uint256 amount, address target, bytes4 functionSignature, bytes parameters);
    event AllowedStakedTokenToChanged(address target, bytes4 functionSignature, bool enabled);

    event VaultRewardsClaimed(address staker, uint256 revDis);
    event VaultRewardsReceived(address vault, uint256 amount);
    event YieldRewardsClaimed(address staker, bool useIMC, uint256 pendingYieldToClaim);
    event WeightChanged(uint256 newWeight);

    modifier poolRegistered {
        require(factory.poolExists(address(this)), "Pool: not registered");
        _;
    }

    modifier onlyFactoryOwner {
        require(msg.sender == factory.factoryOwner(), "Pool: not factory owner");
        _;
    }

    function initialize(
        address _factory,
        address _ime,
        address _poolToken,
        uint256 _initTime,
        uint256 _weight,
        uint256 _minStakePeriod,
        uint256 _maxStakePeriod,
        uint256 _yieldLockUpPeriod
    ) external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        ime = _ime;
        factory = IPoolFactory(_factory);
        poolToken = _poolToken;
        lastYieldDistribution = _initTime;
        weight = _weight;
        minStakePeriod = _minStakePeriod;
        maxStakePeriod = _maxStakePeriod;
        yieldLockUpPeriod = _yieldLockUpPeriod;
    }

    function _getStakeWeight(uint256 lockDuration, uint256 amount) private view returns (uint256) {
        return lockDuration.mul(WEIGHT_MULTIPLIER).div(maxStakePeriod).add(BASE_WEIGHT).mul(amount);
    }

    function _updateUserReward(address staker) private {
        User storage user = users[staker];
        uint256 userTotalWeight = user.totalWeight;

        uint256 pendingYieldToAdd = yieldRewardsPerWeight.sub(user.yieldRewardsPerWeightPaid)
        .mul(userTotalWeight)
        .div(REWARD_PER_WEIGHT_MULTIPLIER);

        user.pendingYield = pendingYieldToAdd.add(user.pendingYield).toUint128();

        uint256 pendingRevDisToAdd = vaultRewardsPerWeight.sub(user.vaultRewardsPerWeightPaid)
        .mul(userTotalWeight)
        .div(REWARD_PER_WEIGHT_MULTIPLIER);

        user.pendingRevDis = pendingRevDisToAdd.add(user.pendingRevDis).toUint128();

        user.yieldRewardsPerWeightPaid = yieldRewardsPerWeight;
        user.vaultRewardsPerWeightPaid = vaultRewardsPerWeight;
    }

    function sync() nonReentrant poolRegistered whenNotPaused external {
        _sync();
    }

    function _sync() private {

        uint256 endTime = factory.endTime();
        if (lastYieldDistribution >= endTime) {
            return;
        }
        if (block.timestamp <= lastYieldDistribution) {
            return;
        }
        if (globalTotalWeight == 0) {
            lastYieldDistribution = block.timestamp;
            return;
        }

        uint256 currentTimestamp = block.timestamp > endTime ? endTime : block.timestamp;
        uint256 secondsPassed = currentTimestamp - lastYieldDistribution;
        uint256 imePerSecond = factory.imePerSecond();

        uint256 imeReward = secondsPassed.mul(imePerSecond).mul(weight).div(factory.totalWeight());

        yieldRewardsPerWeight = imeReward.mul(REWARD_PER_WEIGHT_MULTIPLIER).div(globalTotalWeight).add(yieldRewardsPerWeight);
        lastYieldDistribution = currentTimestamp;
    }

    function stake(uint256 amount, uint256 lockDuration) nonReentrant poolRegistered whenNotPaused external {
        _stake(msg.sender, amount, lockDuration);
    }

    function _stake(address staker, uint256 amount, uint256 lockDuration) private {

        require(amount > 0, "Pool: invalid amount");
        require(lockDuration >= minStakePeriod && lockDuration <= maxStakePeriod, "Pool: invalid lockDuration");

        _sync();
        User storage user = users[staker];
        _updateUserReward(staker);

        uint256 lockUntil = block.timestamp + lockDuration;
        uint256 stakeWeight = _getStakeWeight(lockDuration, amount);
        assert(stakeWeight > 0);

        StakeData memory userStake = StakeData({
        amount : amount.toUint120(),
        lockedFrom : block.timestamp.toUint64(),
        lockedUntil : lockUntil.toUint64(),
        isYield : false
        });

        user.stakes.push(userStake);

        user.totalWeight = stakeWeight.add(user.totalWeight);
        globalTotalWeight = stakeWeight.add(globalTotalWeight);
        poolTokenReserve += amount;

        IERC20Upgradeable(poolToken).safeTransferFrom(staker, address(this), amount);

        emit Staked(msg.sender, staker, (user.stakes.length - 1), amount, lockDuration, false);
    }

    function unstake(uint256 stakeId, uint256 amount) nonReentrant poolRegistered whenNotPaused external {
        address staker = msg.sender;
        User storage user = users[staker];
        StakeData storage userStake = user.stakes[stakeId];
        require(block.timestamp > userStake.lockedUntil, "Pool: still locking");
        _unstake(msg.sender, stakeId, amount);
    }

    function _unstake(address staker, uint256 stakeId, uint256 amount) private {
        User storage user = users[staker];
        StakeData storage userStake = user.stakes[stakeId];

        require(amount > 0, "Pool: invalid amount");
        require(userStake.amount >= amount, "Pool: amount exceeds stake");
        _sync();
        _updateUserReward(staker);

        (uint120 stakeAmount,
        uint64 stakeLockedFrom,
        uint64 stakeLockedUntil,
        bool isYield) =
        (userStake.amount, userStake.lockedFrom, userStake.lockedUntil, userStake.isYield);
        uint256 duration = stakeLockedUntil - stakeLockedFrom;

        uint256 previousWeight = _getStakeWeight(duration, stakeAmount);
        uint256 newWeight;

        uint256 remaining = stakeAmount - amount;
        if (remaining == 0) {
            delete user.stakes[stakeId];
        } else {
            userStake.amount = remaining.toUint120();
            newWeight = _getStakeWeight(duration, remaining);
        }

        user.totalWeight = user.totalWeight.sub(previousWeight).add(newWeight);
        globalTotalWeight = globalTotalWeight.sub(previousWeight).add(newWeight);
        poolTokenReserve -= amount;

        if (isYield) {
            factory.yieldImeTo(staker, amount);
        } else {
            IERC20Upgradeable(poolToken).safeTransfer(staker, amount);
        }

        emit Unstaked(staker, stakeId, amount, isYield);

    }

    function unstakeMultiple(UnstakeParameter[] calldata _stakes, bool _unstakingYield) whenNotPaused poolRegistered nonReentrant external {
        _unstakeMultiple(msg.sender, _stakes, _unstakingYield);
    }

    function _unstakeMultiple(address staker, UnstakeParameter[] calldata _stakes, bool _unstakingYield) private {
        require(_stakes.length > 0, "Pool: empty stakes");
        User storage user = users[staker];
        _sync();
        _updateUserReward(staker);

        uint256 weightToRemove;
        uint256 amountToUnstake;

        for (uint256 i = 0; i < _stakes.length; i++) {
            (uint256 stakeId, uint256 amount) = (_stakes[i].stakeId, _stakes[i].amount);
            StakeData storage userStake = user.stakes[stakeId];
            address _staker = staker;

            (uint120 stakeAmount,
            uint64 stakeLockedFrom,
            uint64 stakeLockedUntil,
            bool isYield) =
            (userStake.amount, userStake.lockedFrom, userStake.lockedUntil, userStake.isYield);

            uint256 duration = stakeLockedUntil - stakeLockedFrom;

            require(block.timestamp > stakeLockedUntil, "Pool: still locking");
            require(amount > 0, "Pool: invalid amount");
            require(isYield == _unstakingYield, "Pool: isYield not match");
            require(stakeAmount >= amount, "Pool: amount exceeds stake");

            uint256 previousWeight = _getStakeWeight(duration, stakeAmount);
            uint256 newWeight;

            uint256 remaining = stakeAmount - amount;
            if (remaining == 0) {
                delete user.stakes[stakeId];
            } else {
                userStake.amount = remaining.toUint120();
                newWeight = _getStakeWeight(duration, remaining);
            }

            weightToRemove += previousWeight.sub(newWeight);
            amountToUnstake += amount;

            emit Unstaked(_staker, stakeId, amount, isYield);
        }

        user.totalWeight -= weightToRemove;
        globalTotalWeight -= weightToRemove;
        poolTokenReserve -= amountToUnstake;

        if (_unstakingYield) {
            factory.yieldImeTo(staker, amountToUnstake);
        } else {
            IERC20Upgradeable(poolToken).safeTransfer(staker, amountToUnstake);
        }
    }

    function _claimVaultRewards(address staker) private {
        User storage user = users[staker];
        _sync();
        _updateUserReward(staker);
        uint256 pendingRevDis = user.pendingRevDis;
        if (pendingRevDis == 0) return;
        user.pendingRevDis = 0;
        IERC20Upgradeable(ime).safeTransfer(staker, pendingRevDis);
        emit VaultRewardsClaimed(staker, pendingRevDis);
    }

    function receiveVaultRewards(uint256 amount) external {
        _receiveVaultRewards(amount);
    }

    function _receiveVaultRewards(uint256 amount) private {
        address vault = factory.vault();
        require(vault != address(0), "Pool: vault not set");
        require(msg.sender == vault, "Pool: not from vault");
        _sync();
        // return silently if there is no reward to receive
        if (amount == 0) {
            return;
        }
        require(globalTotalWeight > 0, "Pool: cannot receive vault reward when no one stakes");

        vaultRewardsPerWeight = amount.mul(REWARD_PER_WEIGHT_MULTIPLIER).div(globalTotalWeight).add(vaultRewardsPerWeight);
        IERC20Upgradeable(ime).safeTransferFrom(msg.sender, address(this), amount);
        emit VaultRewardsReceived(vault, amount);
    }

    function useStakedTokenTo(UnstakeParameter[] calldata _stakes, address target, bytes4 functionSignature, bytes calldata parameters) whenNotPaused poolRegistered nonReentrant external {
        _useStakedTokenTo(msg.sender, _stakes, target, functionSignature, parameters);
    }

    function _useStakedTokenTo(
        address staker,
        UnstakeParameter[] calldata _stakes,
        address target,
        bytes4 functionSignature,
        bytes calldata parameters) private {

        require(allowedUseStakedTokenTo[target][functionSignature], "Pool: Not allow use staked token to");

        require(poolToken == ime, "Pool: not using ime pool");

        require(_stakes.length > 0, "Pool: empty stakes");
        User storage user = users[staker];
        _sync();
        _updateUserReward(staker);

        uint256 weightToRemove;
        uint256 amountToUnstake;

        for (uint256 i = 0; i < _stakes.length; i++) {

            (uint256 stakeId, uint256 amount) = (_stakes[i].stakeId, _stakes[i].amount);
            emit UseStakedTokenTo(staker, stakeId, amount, target, functionSignature, parameters);
            StakeData storage userStake = user.stakes[stakeId];
            require(amount > 0, "Pool: invalid amount");

            (uint120 stakeAmount,
            uint64 stakeLockedFrom,
            uint64 stakeLockedUntil,
            bool isYield) =
            (userStake.amount, userStake.lockedFrom, userStake.lockedUntil, userStake.isYield);
            require(!isYield, "Pool: only isYield can be used");
            require(stakeAmount >= amount, "Pool: amount exceeds stake");

            uint256 duration = stakeLockedUntil - stakeLockedFrom;

            uint256 previousWeight = _getStakeWeight(duration, stakeAmount);
            uint256 newWeight;

            uint256 remaining = stakeAmount - amount;
            if (remaining == 0) {
                delete user.stakes[stakeId];
            } else {
                userStake.amount = remaining.toUint120();
                newWeight = _getStakeWeight(duration, remaining);
            }

            weightToRemove += previousWeight.sub(newWeight);
            amountToUnstake += amount;
        }

        user.totalWeight -= weightToRemove;
        globalTotalWeight -= weightToRemove;
        poolTokenReserve -= amountToUnstake;

        IERC20Upgradeable(ime).safeApprove(target, amountToUnstake);
        uint256 balanceBefore = IERC20Upgradeable(ime).balanceOf(address(this));

        (bool success, ) = target.call(abi.encodePacked(functionSignature, parameters));
        require(success, "Pools: use staked token to call failed");

        uint256 balanceAfter = IERC20Upgradeable(ime).balanceOf(address(this));
        require(balanceBefore.sub(balanceAfter) == amountToUnstake, "Pool: amount spent not match with unstaked");

        IERC20Upgradeable(ime).safeApprove(target, 0);
    }

    function pendingRewards(address _staker) external view returns (uint256 pendingYield, uint256 pendingRevDis){
        uint256 newYieldRewardsPerWeight;
        uint256 _lastYieldDistribution = lastYieldDistribution;

        User storage user = users[_staker];

        if (block.timestamp > _lastYieldDistribution && globalTotalWeight != 0) {
            uint256 endTime = factory.endTime();
            uint256 multiplier = block.timestamp > endTime
            ? endTime - _lastYieldDistribution
            : block.timestamp - _lastYieldDistribution;
            uint256 imeRewards = multiplier.mul(weight).mul(factory.imePerSecond()).div(factory.totalWeight());

            newYieldRewardsPerWeight = imeRewards.mul(REWARD_PER_WEIGHT_MULTIPLIER).div(globalTotalWeight).add(yieldRewardsPerWeight);

        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }

        pendingYield = newYieldRewardsPerWeight.sub(user.yieldRewardsPerWeightPaid)
        .mul(user.totalWeight).div(REWARD_PER_WEIGHT_MULTIPLIER).add(user.pendingYield);

        pendingRevDis = vaultRewardsPerWeight.sub(user.vaultRewardsPerWeightPaid)
        .mul(user.totalWeight).div(REWARD_PER_WEIGHT_MULTIPLIER).add(user.pendingRevDis);

    }

    function claimYieldRewards(bool useIMC) whenNotPaused poolRegistered nonReentrant external {
        _claimYieldRewards(msg.sender, useIMC);
    }

    function _claimYieldRewards(address staker, bool useIMC) private {
        User storage user = users[staker];
        _sync();
        _updateUserReward(staker);
        uint256 pendingYieldToClaim = uint256(user.pendingYield);
        if (pendingYieldToClaim == 0) return;
        user.pendingYield = 0;

        if (useIMC) {
            factory.yieldImcTo(staker, pendingYieldToClaim);
        } else if (poolToken == ime) {
            uint256 stakeWeight = pendingYieldToClaim * YIELD_STAKE_WEIGHT_MULTIPLIER;

            StakeData memory newStake = StakeData({
            amount : pendingYieldToClaim.toUint120(),
            lockedFrom : block.timestamp.toUint64(),
            lockedUntil : (block.timestamp + yieldLockUpPeriod).toUint64(),
            isYield : true
            });

            user.totalWeight += stakeWeight;
            user.stakes.push(newStake);
            globalTotalWeight += stakeWeight;
            poolTokenReserve += pendingYieldToClaim;

        } else {
            address imePool = factory.getPoolAddress(ime);
            IPool(imePool).stakeAsPool(staker, pendingYieldToClaim);
        }
        emit YieldRewardsClaimed(staker, useIMC, pendingYieldToClaim);
    }

    function stakeAsPool(address staker, uint256 amount) external override {
        require(factory.poolExists(msg.sender), "Pool: stakeAsPool not from pool");
        _sync();
        _updateUserReward(staker);
        uint256 stakeWeight = amount * YIELD_STAKE_WEIGHT_MULTIPLIER;

        StakeData memory newStake = StakeData({
        amount : amount.toUint120(),
        lockedFrom : block.timestamp.toUint64(),
        lockedUntil : (block.timestamp + yieldLockUpPeriod).toUint64(),
        isYield : true
        });

        User storage user = users[staker];
        user.totalWeight += stakeWeight;
        user.stakes.push(newStake);
        globalTotalWeight += stakeWeight;
        poolTokenReserve += amount;
        emit Staked(msg.sender, staker, (user.stakes.length - 1), amount, maxStakePeriod, true);
    }

    function getStakeLength(address staker) external view returns (uint256) {
        return users[staker].stakes.length;
    }

    function getStake(address staker, uint256 stakeId) external view returns (StakeData memory) {
        return users[staker].stakes[stakeId];
    }

    function getStakes(address staker) external view returns (StakeData[] memory) {
        return users[staker].stakes;
    }

    function setWeight(uint256 newWeight) external override {
        require(msg.sender == address(factory), "Pool: setWeight not from factory");
        weight = newWeight;
        emit WeightChanged(newWeight);
    }

    function setAllowStakedTokenTo(address target, bytes4 functionSignature, bool enabled) external onlyFactoryOwner {
        allowedUseStakedTokenTo[target][functionSignature] = enabled;
        emit AllowedStakedTokenToChanged(target, functionSignature, enabled);
    }

}