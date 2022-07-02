/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-02
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// MIT
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


// File @openzeppelin/contracts/utils/[email protected]

// MIT
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// MIT
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// MIT
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// MIT
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


// File @openzeppelin/contracts/utils/structs/[email protected]

// MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}


// File interfaces/IGasBank.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IGasBank {
    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, address indexed receiver, uint256 value);

    function depositFor(address account) external payable;

    function withdrawUnused(address account) external;

    function withdrawFrom(address account, uint256 amount) external;

    function withdrawFrom(
        address account,
        address payable to,
        uint256 amount
    ) external;

    function balanceOf(address account) external view returns (uint256);
}


// File interfaces/IPreparable.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IPreparable {
    event ConfigPreparedAddress(bytes32 indexed key, address value, uint256 delay);
    event ConfigPreparedNumber(bytes32 indexed key, uint256 value, uint256 delay);

    event ConfigUpdatedAddress(bytes32 indexed key, address oldValue, address newValue);
    event ConfigUpdatedNumber(bytes32 indexed key, uint256 oldValue, uint256 newValue);

    event ConfigReset(bytes32 indexed key);
}


// File interfaces/IStrategy.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IStrategy {
    function name() external view returns (string memory);

    function deposit() external payable returns (bool);

    function balance() external view returns (uint256);

    function withdraw(uint256 amount) external returns (bool);

    function withdrawAll() external returns (uint256);

    function harvestable() external view returns (uint256);

    function harvest() external returns (uint256);

    function strategist() external view returns (address);

    function shutdown() external returns (bool);

    function hasPendingFunds() external view returns (bool);
}


// File interfaces/IVault.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;


/**
 * @title Interface for a Vault
 */

interface IVault is IPreparable {
    event StrategyActivated(address indexed strategy);

    event StrategyDeactivated(address indexed strategy);

    /**
     * @dev 'netProfit' is the profit after all fees have been deducted
     */
    event Harvest(uint256 indexed netProfit, uint256 indexed loss);

    function initialize(
        address _pool,
        uint256 _debtLimit,
        uint256 _targetAllocation,
        uint256 _bound
    ) external;

    function withdrawFromStrategyWaitingForRemoval(address strategy) external returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 amount) external returns (bool);

    function initializeStrategy(address strategy_) external returns (bool);

    function withdrawAll() external;

    function withdrawFromReserve(uint256 amount) external;

    function executeNewStrategy() external returns (address);

    function prepareNewStrategy(address newStrategy) external returns (bool);

    function getStrategy() external view returns (IStrategy);

    function getStrategiesWaitingForRemoval() external view returns (address[] memory);

    function getAllocatedToStrategyWaitingForRemoval(address strategy)
        external
        view
        returns (uint256);

    function getTotalUnderlying() external view returns (uint256);

    function getUnderlying() external view returns (address);
}


// File interfaces/pool/ILiquidityPool.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;


interface ILiquidityPool is IPreparable {
    event Deposit(address indexed minter, uint256 depositAmount, uint256 mintedLpTokens);

    event DepositFor(
        address indexed minter,
        address indexed mintee,
        uint256 depositAmount,
        uint256 mintedLpTokens
    );

    event Redeem(address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens);

    event LpTokenSet(address indexed lpToken);

    event StakerVaultSet(address indexed stakerVault);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeem(uint256 redeemTokens, uint256 minRedeemAmount) external returns (uint256);

    function calcRedeem(address account, uint256 underlyingAmount) external returns (uint256);

    function deposit(uint256 mintAmount) external payable returns (uint256);

    function deposit(uint256 mintAmount, uint256 minTokenAmount) external payable returns (uint256);

    function depositAndStake(uint256 depositAmount, uint256 minTokenAmount)
        external
        payable
        returns (uint256);

    function depositFor(address account, uint256 depositAmount) external payable returns (uint256);

    function depositFor(
        address account,
        uint256 depositAmount,
        uint256 minTokenAmount
    ) external payable returns (uint256);

    function unstakeAndRedeem(uint256 redeemLpTokens, uint256 minRedeemAmount)
        external
        returns (uint256);

    function handleLpTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external;

    function prepareNewVault(address _vault) external returns (bool);

    function executeNewVault() external returns (address);

    function executeNewMaxWithdrawalFee() external returns (uint256);

    function executeNewRequiredReserves() external returns (uint256);

    function executeNewReserveDeviation() external returns (uint256);

    function setLpToken(address _lpToken) external returns (bool);

    function setStaker() external returns (bool);

    function isCapped() external returns (bool);

    function uncap() external returns (bool);

    function updateDepositCap(uint256 _depositCap) external returns (bool);

    function withdrawAll() external;

    function getUnderlying() external view returns (address);

    function getLpToken() external view returns (address);

    function getWithdrawalFee(address account, uint256 amount) external view returns (uint256);

    function getVault() external view returns (IVault);

    function exchangeRate() external view returns (uint256);

    function totalUnderlying() external view returns (uint256);
}


// File interfaces/ISwapperRegistry.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface ISwapperRegistry {
    function getSwapper(address fromToken, address toToken) external view returns (address);

    function swapperExists(address fromToken, address toToken) external view returns (bool);

    function getAllSwappableTokens(address token) external view returns (address[] memory);
}


// File interfaces/oracles/IOracleProvider.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IOracleProvider {
    /// @notice Quotes the USD price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the USD price of the asset
    function getPriceUSD(address baseAsset) external view returns (uint256);

    /// @notice Quotes the ETH price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the ETH price of the asset
    function getPriceETH(address baseAsset) external view returns (uint256);
}


// File libraries/AddressProviderMeta.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

library AddressProviderMeta {
    struct Meta {
        bool freezable;
        bool frozen;
    }

    function fromUInt(uint256 value) internal pure returns (Meta memory) {
        Meta memory meta;
        meta.freezable = (value & 1) == 1;
        meta.frozen = ((value >> 1) & 1) == 1;
        return meta;
    }

    function toUInt(Meta memory meta) internal pure returns (uint256) {
        uint256 value;
        value |= meta.freezable ? 1 : 0;
        value |= meta.frozen ? 1 << 1 : 0;
        return value;
    }
}


// File interfaces/IAddressProvider.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;





// solhint-disable ordering

interface IAddressProvider is IPreparable {
    event KnownAddressKeyAdded(bytes32 indexed key);
    event StakerVaultListed(address indexed stakerVault);
    event StakerVaultDelisted(address indexed stakerVault);
    event ActionListed(address indexed action);
    event PoolListed(address indexed pool);
    event PoolDelisted(address indexed pool);
    event VaultUpdated(address indexed previousVault, address indexed newVault);

    /** Key functions */
    function getKnownAddressKeys() external view returns (bytes32[] memory);

    function freezeAddress(bytes32 key) external;

    /** Pool functions */

    function allPools() external view returns (address[] memory);

    function addPool(address pool) external;

    function poolsCount() external view returns (uint256);

    function getPoolAtIndex(uint256 index) external view returns (address);

    function isPool(address pool) external view returns (bool);

    function removePool(address pool) external returns (bool);

    function getPoolForToken(address token) external view returns (ILiquidityPool);

    function safeGetPoolForToken(address token) external view returns (address);

    /** Vault functions  */

    function updateVault(address previousVault, address newVault) external;

    function allVaults() external view returns (address[] memory);

    function vaultsCount() external view returns (uint256);

    function getVaultAtIndex(uint256 index) external view returns (address);

    function isVault(address vault) external view returns (bool);

    /** Action functions */

    function allActions() external view returns (address[] memory);

    function addAction(address action) external returns (bool);

    function isAction(address action) external view returns (bool);

    /** Address functions */
    function initializeAddress(
        bytes32 key,
        address initialAddress,
        bool frezable
    ) external;

    function initializeAndFreezeAddress(bytes32 key, address initialAddress) external;

    function getAddress(bytes32 key) external view returns (address);

    function getAddress(bytes32 key, bool checkExists) external view returns (address);

    function getAddressMeta(bytes32 key) external view returns (AddressProviderMeta.Meta memory);

    function prepareAddress(bytes32 key, address newAddress) external returns (bool);

    function executeAddress(bytes32 key) external returns (address);

    function resetAddress(bytes32 key) external returns (bool);

    /** Staker vault functions */
    function allStakerVaults() external view returns (address[] memory);

    function tryGetStakerVault(address token) external view returns (bool, address);

    function getStakerVault(address token) external view returns (address);

    function addStakerVault(address stakerVault) external returns (bool);

    function isStakerVault(address stakerVault, address token) external view returns (bool);

    function isStakerVaultRegistered(address stakerVault) external view returns (bool);

    function isWhiteListedFeeHandler(address feeHandler) external view returns (bool);
}


// File interfaces/tokenomics/IInflationManager.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IInflationManager {
    event KeeperGaugeListed(address indexed pool, address indexed keeperGauge);
    event AmmGaugeListed(address indexed token, address indexed ammGauge);
    event KeeperGaugeDelisted(address indexed pool, address indexed keeperGauge);
    event AmmGaugeDelisted(address indexed token, address indexed ammGauge);

    /** Pool functions */

    function setKeeperGauge(address pool, address _keeperGauge) external returns (bool);

    function setAmmGauge(address token, address _ammGauge) external returns (bool);

    function getAllAmmGauges() external view returns (address[] memory);

    function getLpRateForStakerVault(address stakerVault) external view returns (uint256);

    function getKeeperRateForPool(address pool) external view returns (uint256);

    function getAmmRateForToken(address token) external view returns (uint256);

    function getKeeperWeightForPool(address pool) external view returns (uint256);

    function getAmmWeightForToken(address pool) external view returns (uint256);

    function getLpPoolWeight(address pool) external view returns (uint256);

    function getKeeperGaugeForPool(address pool) external view returns (address);

    function getAmmGaugeForToken(address token) external view returns (address);

    function isInflationWeightManager(address account) external view returns (bool);

    function removeStakerVaultFromInflation(address stakerVault, address lpToken) external;

    function addGaugeForVault(address lpToken) external returns (bool);

    function whitelistGauge(address gauge) external;

    function checkpointAllGauges() external returns (bool);

    function mintRewards(address beneficiary, uint256 amount) external;

    function addStrategyToDepositStakerVault(address depositStakerVault, address strategyPool)
        external
        returns (bool);

    /** Weight setter functions **/

    function prepareLpPoolWeight(address lpToken, uint256 newPoolWeight) external returns (bool);

    function prepareAmmTokenWeight(address token, uint256 newTokenWeight) external returns (bool);

    function prepareKeeperPoolWeight(address pool, uint256 newPoolWeight) external returns (bool);

    function executeLpPoolWeight(address lpToken) external returns (uint256);

    function executeAmmTokenWeight(address token) external returns (uint256);

    function executeKeeperPoolWeight(address pool) external returns (uint256);

    function batchPrepareLpPoolWeights(address[] calldata lpTokens, uint256[] calldata weights)
        external
        returns (bool);

    function batchPrepareAmmTokenWeights(address[] calldata tokens, uint256[] calldata weights)
        external
        returns (bool);

    function batchPrepareKeeperPoolWeights(address[] calldata pools, uint256[] calldata weights)
        external
        returns (bool);

    function batchExecuteLpPoolWeights(address[] calldata lpTokens) external returns (bool);

    function batchExecuteAmmTokenWeights(address[] calldata tokens) external returns (bool);

    function batchExecuteKeeperPoolWeights(address[] calldata pools) external returns (bool);
}


// File interfaces/IController.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;





// solhint-disable ordering

interface IController is IPreparable {
    function addressProvider() external view returns (IAddressProvider);

    function inflationManager() external view returns (IInflationManager);

    function addStakerVault(address stakerVault) external returns (bool);

    function removePool(address pool) external returns (bool);

    /** Keeper functions */
    function prepareKeeperRequiredStakedBKD(uint256 amount) external;

    function executeKeeperRequiredStakedBKD() external;

    function getKeeperRequiredStakedBKD() external view returns (uint256);

    function canKeeperExecuteAction(address keeper) external view returns (bool);

    /** Miscellaneous functions */

    function getTotalEthRequiredForGas(address payer) external view returns (uint256);
}


// File interfaces/IStakerVault.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IStakerVault {
    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function initialize(address _token) external;

    function initializeLpGauge(address _lpGauge) external returns (bool);

    function stake(uint256 amount) external returns (bool);

    function stakeFor(address account, uint256 amount) external returns (bool);

    function unstake(uint256 amount) external returns (bool);

    function unstakeFor(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address account, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function getToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function stakedAndActionLockedBalanceOf(address account) external view returns (uint256);

    function actionLockedBalanceOf(address account) external view returns (uint256);

    function increaseActionLockedBalance(address account, uint256 amount) external returns (bool);

    function decreaseActionLockedBalance(address account, uint256 amount) external returns (bool);

    function getStakedByActions() external view returns (uint256);

    function addStrategy(address strategy) external returns (bool);

    function getPoolTotalStaked() external view returns (uint256);

    function prepareLpGauge(address _lpGauge) external returns (bool);

    function executeLpGauge() external returns (bool);

    function getLpGauge() external view returns (address);

    function poolCheckpoint() external returns (bool);

    function isStrategy(address user) external view returns (bool);
}


// File interfaces/ISwapper.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface ISwapper {
    function swap(
        address fromToken,
        address toToken,
        uint256 swapAmount,
        uint256 minAmount
    ) external returns (uint256);

    function getRate(address fromToken, address toToken) external view returns (uint256);
}


// File interfaces/actions/topup/ITopUpHandler.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

/**
 * This interface should be implemented by protocols integrating with Backd
 * that require topping up a registered position
 */
interface ITopUpHandler {
    /**
     * @notice Tops up the account for the protocol associated with this handler
     * This is designed to be called using delegatecall and should therefore
     * not assume that storage will be available
     *
     * @param account account to be topped up
     * @param underlying underlying currency to be used for top up
     * @param amount amount to be topped up
     * @param extra arbitrary data that can be passed to the handler
     * @return true if the top up succeeded and false otherwise
     */
    function topUp(
        bytes32 account,
        address underlying,
        uint256 amount,
        bytes memory extra
    ) external returns (bool);

    /**
     * @notice Returns a factor for the user which should always be >= 1 for sufficiently
     *         colletaralized positions and should get closer to 1 when collaterization level decreases
     * This should be an aggregate value including all the collateral of the user
     * @param account account for which to get the factor
     */
    function getUserFactor(bytes32 account, bytes memory extra) external view returns (uint256);
}


// File interfaces/actions/IAction.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IAction {
    /**
     * @return the total amount of ETH (in wei) required to cover gas
     */
    function getEthRequiredForGas(address payer) external view returns (uint256);

    function addUsableToken(address token) external returns (bool);

    function getUsableTokens() external view returns (address[] memory);

    function isUsable(address token) external view returns (bool);

    function getActionFee() external view returns (uint256);

    function getFeeHandler() external view returns (address);

    function executeActionFee() external returns (uint256);

    function executeSwapperSlippage() external returns (uint256);

    function executeFeeHandler() external returns (address);
}


// File interfaces/actions/topup/ITopUpAction.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;


interface ITopUpAction is IAction, IPreparable {
    struct RecordKey {
        address payer;
        bytes32 account;
        bytes32 protocol;
    }

    struct RecordMeta {
        bytes32 account;
        bytes32 protocol;
    }

    struct Record {
        uint64 threshold;
        uint64 priorityFee;
        uint64 maxFee;
        address actionToken;
        address depositToken;
        uint128 singleTopUpAmount; // denominated in action token
        uint128 totalTopUpAmount; // denominated in action token
        uint128 depositTokenBalance;
        bytes extra;
    }

    struct RecordWithMeta {
        bytes32 account;
        bytes32 protocol;
        Record record;
    }

    event Register(
        bytes32 indexed account,
        bytes32 indexed protocol,
        uint256 indexed threshold,
        address payer,
        address depositToken,
        uint256 depositAmount,
        address actionToken,
        uint256 singleTopUpAmount,
        uint256 totalTopUpAmount,
        uint256 maxGasPrice,
        bytes extra
    );

    event Deregister(address indexed payer, bytes32 indexed account, bytes32 indexed protocol);

    event TopUp(
        bytes32 indexed account,
        bytes32 indexed protocol,
        address indexed payer,
        address depositToken,
        uint256 consumedDepositAmount,
        address actionToken,
        uint256 topupAmount
    );

    function register(
        bytes32 account,
        bytes32 protocol,
        uint128 depositAmount,
        Record memory record
    ) external payable returns (bool);

    function execute(
        address payer,
        bytes32 account,
        address keeper,
        bytes32 protocol
    ) external returns (bool);

    function execute(
        address payer,
        bytes32 account,
        address keeper,
        bytes32 protocol,
        uint256 maxWeiForGas
    ) external returns (bool);

    function resetPosition(
        bytes32 account,
        bytes32 protocol,
        bool unstake
    ) external returns (bool);

    function getSupportedProtocols() external view returns (bytes32[] memory);

    function getPosition(
        address payer,
        bytes32 account,
        bytes32 protocol
    ) external view returns (Record memory);

    function getUserPositions(address payer) external view returns (RecordMeta[] memory);

    function getHandler(bytes32 protocol) external view returns (address);

    function usersWithPositions(uint256 cursor, uint256 howMany)
        external
        view
        returns (address[] memory users, uint256 nextCursor);

    function getHealthFactor(
        bytes32 protocol,
        bytes32 account,
        bytes memory extra
    ) external view returns (uint256);

    function getTopUpHandler(bytes32 protocol) external view returns (address);

    function prepareTopUpHandler(bytes32 protocol, address newHandler) external returns (bool);

    function executeTopUpHandler(bytes32 protocol) external returns (address);

    function resetTopUpHandler(bytes32 protocol) external returns (bool);

    function getSwapperSlippage() external view returns (uint256);
}


// File interfaces/actions/IActionFeeHandler.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IActionFeeHandler is IPreparable {
    function payFees(
        address payer,
        address keeper,
        uint256 amount,
        address token
    ) external returns (bool);

    function claimKeeperFeesForPool(address keeper, address token) external returns (bool);

    function claimTreasuryFees(address token) external returns (bool);

    function setInitialKeeperGaugeForToken(address lpToken, address _keeperGauge)
        external
        returns (bool);
}


// File interfaces/IVaultReserve.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IVaultReserve {
    event Deposit(address indexed vault, address indexed token, uint256 amount);
    event Withdraw(address indexed vault, address indexed token, uint256 amount);
    event VaultListed(address indexed vault);

    function deposit(address token, uint256 amount) external payable returns (bool);

    function withdraw(address token, uint256 amount) external returns (bool);

    function getBalance(address vault, address token) external view returns (uint256);

    function canWithdraw(address vault) external view returns (bool);
}


// File interfaces/IRoleManager.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IRoleManager {
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function hasAnyRole(bytes32[] memory roles, address account) external view returns (bool);

    function hasAnyRole(
        bytes32 role1,
        bytes32 role2,
        address account
    ) external view returns (bool);

    function hasAnyRole(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        address account
    ) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
}


// File interfaces/tokenomics/IBkdToken.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IBkdToken is IERC20 {
    function mint(address account, uint256 amount) external;
}


// File libraries/AddressProviderKeys.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

library AddressProviderKeys {
    bytes32 internal constant _TREASURY_KEY = "treasury";
    bytes32 internal constant _GAS_BANK_KEY = "gasBank";
    bytes32 internal constant _VAULT_RESERVE_KEY = "vaultReserve";
    bytes32 internal constant _SWAPPER_REGISTRY_KEY = "swapperRegistry";
    bytes32 internal constant _ORACLE_PROVIDER_KEY = "oracleProvider";
    bytes32 internal constant _POOL_FACTORY_KEY = "poolFactory";
    bytes32 internal constant _CONTROLLER_KEY = "controller";
    bytes32 internal constant _BKD_LOCKER_KEY = "bkdLocker";
    bytes32 internal constant _ROLE_MANAGER_KEY = "roleManager";
}


// File libraries/AddressProviderHelpers.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;







library AddressProviderHelpers {
    /**
     * @return The address of the treasury.
     */
    function getTreasury(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._TREASURY_KEY);
    }

    /**
     * @return The gas bank.
     */
    function getGasBank(IAddressProvider provider) internal view returns (IGasBank) {
        return IGasBank(provider.getAddress(AddressProviderKeys._GAS_BANK_KEY));
    }

    /**
     * @return The address of the vault reserve.
     */
    function getVaultReserve(IAddressProvider provider) internal view returns (IVaultReserve) {
        return IVaultReserve(provider.getAddress(AddressProviderKeys._VAULT_RESERVE_KEY));
    }

    /**
     * @return The address of the swapperRegistry.
     */
    function getSwapperRegistry(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._SWAPPER_REGISTRY_KEY);
    }

    /**
     * @return The oracleProvider.
     */
    function getOracleProvider(IAddressProvider provider) internal view returns (IOracleProvider) {
        return IOracleProvider(provider.getAddress(AddressProviderKeys._ORACLE_PROVIDER_KEY));
    }

    /**
     * @return the address of the BKD locker
     */
    function getBKDLocker(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._BKD_LOCKER_KEY);
    }

    /**
     * @return the address of the BKD locker
     */
    function getRoleManager(IAddressProvider provider) internal view returns (IRoleManager) {
        return IRoleManager(provider.getAddress(AddressProviderKeys._ROLE_MANAGER_KEY));
    }

    /**
     * @return the controller
     */
    function getController(IAddressProvider provider) internal view returns (IController) {
        return IController(provider.getAddress(AddressProviderKeys._CONTROLLER_KEY));
    }
}


// File libraries/Errors.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

// solhint-disable private-vars-leading-underscore

library Error {
    string internal constant ADDRESS_WHITELISTED = "address already whitelisted";
    string internal constant ADMIN_ALREADY_SET = "admin has already been set once";
    string internal constant ADDRESS_NOT_WHITELISTED = "address not whitelisted";
    string internal constant ADDRESS_NOT_FOUND = "address not found";
    string internal constant CONTRACT_INITIALIZED = "contract can only be initialized once";
    string internal constant CONTRACT_PAUSED = "contract is paused";
    string internal constant UNAUTHORIZED_PAUSE = "not authorized to pause";
    string internal constant INVALID_AMOUNT = "invalid amount";
    string internal constant INVALID_INDEX = "invalid index";
    string internal constant INVALID_VALUE = "invalid msg.value";
    string internal constant INVALID_SENDER = "invalid msg.sender";
    string internal constant INVALID_TOKEN = "token address does not match pool's LP token address";
    string internal constant INVALID_DECIMALS = "incorrect number of decimals";
    string internal constant INVALID_ARGUMENT = "invalid argument";
    string internal constant INVALID_PARAMETER_VALUE = "invalid parameter value attempted";
    string internal constant INVALID_IMPLEMENTATION = "invalid pool implementation for given coin";
    string internal constant INVALID_POOL_IMPLEMENTATION =
        "invalid pool implementation for given coin";
    string internal constant INVALID_LP_TOKEN_IMPLEMENTATION =
        "invalid LP Token implementation for given coin";
    string internal constant INVALID_VAULT_IMPLEMENTATION =
        "invalid vault implementation for given coin";
    string internal constant INVALID_STAKER_VAULT_IMPLEMENTATION =
        "invalid stakerVault implementation for given coin";
    string internal constant INSUFFICIENT_BALANCE = "insufficient balance";
    string internal constant ADDRESS_ALREADY_SET = "Address is already set";
    string internal constant INSUFFICIENT_STRATEGY_BALANCE = "insufficient strategy balance";
    string internal constant INSUFFICIENT_FUNDS_RECEIVED = "insufficient funds received";
    string internal constant ADDRESS_DOES_NOT_EXIST = "address does not exist";
    string internal constant ADDRESS_FROZEN = "address is frozen";
    string internal constant ROLE_EXISTS = "role already exists";
    string internal constant CANNOT_REVOKE_ROLE = "cannot revoke role";
    string internal constant UNAUTHORIZED_ACCESS = "unauthorized access";
    string internal constant SAME_ADDRESS_NOT_ALLOWED = "same address not allowed";
    string internal constant SELF_TRANSFER_NOT_ALLOWED = "self-transfer not allowed";
    string internal constant ZERO_ADDRESS_NOT_ALLOWED = "zero address not allowed";
    string internal constant ZERO_TRANSFER_NOT_ALLOWED = "zero transfer not allowed";
    string internal constant THRESHOLD_TOO_HIGH = "threshold is too high, must be under 10";
    string internal constant INSUFFICIENT_THRESHOLD = "insufficient threshold";
    string internal constant NO_POSITION_EXISTS = "no position exists";
    string internal constant POSITION_ALREADY_EXISTS = "position already exists";
    string internal constant PROTOCOL_NOT_FOUND = "protocol not found";
    string internal constant TOP_UP_FAILED = "top up failed";
    string internal constant SWAP_PATH_NOT_FOUND = "swap path not found";
    string internal constant UNDERLYING_NOT_SUPPORTED = "underlying token not supported";
    string internal constant NOT_ENOUGH_FUNDS_WITHDRAWN =
        "not enough funds were withdrawn from the pool";
    string internal constant FAILED_TRANSFER = "transfer failed";
    string internal constant FAILED_MINT = "mint failed";
    string internal constant FAILED_REPAY_BORROW = "repay borrow failed";
    string internal constant FAILED_METHOD_CALL = "method call failed";
    string internal constant NOTHING_TO_CLAIM = "there is no claimable balance";
    string internal constant ERC20_BALANCE_EXCEEDED = "ERC20: transfer amount exceeds balance";
    string internal constant INVALID_MINTER =
        "the minter address of the LP token and the pool address do not match";
    string internal constant STAKER_VAULT_EXISTS = "a staker vault already exists for the token";
    string internal constant DEADLINE_NOT_ZERO = "deadline must be 0";
    string internal constant DEADLINE_NOT_SET = "deadline is 0";
    string internal constant DEADLINE_NOT_REACHED = "deadline has not been reached yet";
    string internal constant DELAY_TOO_SHORT = "delay be at least 3 days";
    string internal constant INSUFFICIENT_UPDATE_BALANCE =
        "insufficient funds for updating the position";
    string internal constant SAME_AS_CURRENT = "value must be different to existing value";
    string internal constant NOT_CAPPED = "the pool is not currently capped";
    string internal constant ALREADY_CAPPED = "the pool is already capped";
    string internal constant EXCEEDS_DEPOSIT_CAP = "deposit exceeds deposit cap";
    string internal constant VALUE_TOO_LOW_FOR_GAS = "value too low to cover gas";
    string internal constant NOT_ENOUGH_FUNDS = "not enough funds to withdraw";
    string internal constant ESTIMATED_GAS_TOO_HIGH = "too much ETH will be used for gas";
    string internal constant DEPOSIT_FAILED = "deposit failed";
    string internal constant GAS_TOO_HIGH = "too much ETH used for gas";
    string internal constant GAS_BANK_BALANCE_TOO_LOW = "not enough ETH in gas bank to cover gas";
    string internal constant INVALID_TOKEN_TO_ADD = "Invalid token to add";
    string internal constant INVALID_TOKEN_TO_REMOVE = "token can not be removed";
    string internal constant TIME_DELAY_NOT_EXPIRED = "time delay not expired yet";
    string internal constant UNDERLYING_NOT_WITHDRAWABLE =
        "pool does not support additional underlying coins to be withdrawn";
    string internal constant STRATEGY_SHUT_DOWN = "Strategy is shut down";
    string internal constant STRATEGY_DOES_NOT_EXIST = "Strategy does not exist";
    string internal constant UNSUPPORTED_UNDERLYING = "Underlying not supported";
    string internal constant NO_DEX_SET = "no dex has been set for token";
    string internal constant INVALID_TOKEN_PAIR = "invalid token pair";
    string internal constant TOKEN_NOT_USABLE = "token not usable for the specific action";
    string internal constant ADDRESS_NOT_ACTION = "address is not registered action";
    string internal constant INVALID_SLIPPAGE_TOLERANCE = "Invalid slippage tolerance";
    string internal constant POOL_NOT_PAUSED = "Pool must be paused to withdraw from reserve";
    string internal constant INTERACTION_LIMIT = "Max of one deposit and withdraw per block";
    string internal constant GAUGE_EXISTS = "Gauge already exists";
    string internal constant GAUGE_DOES_NOT_EXIST = "Gauge does not exist";
    string internal constant EXCEEDS_MAX_BOOST = "Not allowed to exceed maximum boost on Convex";
    string internal constant PREPARED_WITHDRAWAL =
        "Cannot relock funds when withdrawal is being prepared";
    string internal constant ASSET_NOT_SUPPORTED = "Asset not supported";
    string internal constant STALE_PRICE = "Price is stale";
    string internal constant NEGATIVE_PRICE = "Price is negative";
    string internal constant NOT_ENOUGH_BKD_STAKED = "Not enough BKD tokens staked";
    string internal constant RESERVE_ACCESS_EXCEEDED = "Reserve access exceeded";
}


// File libraries/ScaledMath.sol

// MIT
pragma solidity 0.8.9;

/*
 * @dev To use functions of this contract, at least one of the numbers must
 * be scaled to `DECIMAL_SCALE`. The result will scaled to `DECIMAL_SCALE`
 * if both numbers are scaled to `DECIMAL_SCALE`, otherwise to the scale
 * of the number not scaled by `DECIMAL_SCALE`
 */
library ScaledMath {
    // solhint-disable-next-line private-vars-leading-underscore
    uint256 internal constant DECIMAL_SCALE = 1e18;
    // solhint-disable-next-line private-vars-leading-underscore
    uint256 internal constant ONE = 1e18;

    /**
     * @notice Performs a multiplication between two scaled numbers
     */
    function scaledMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / DECIMAL_SCALE;
    }

    /**
     * @notice Performs a division between two scaled numbers
     */
    function scaledDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * DECIMAL_SCALE) / b;
    }

    /**
     * @notice Performs a division between two numbers, rounding up the result
     */
    function scaledDivRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * DECIMAL_SCALE + b - 1) / b;
    }

    /**
     * @notice Performs a division between two numbers, ignoring any scaling and rounding up the result
     */
    function divRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }
}


// File libraries/EnumerableMapping.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

library EnumerableMapping {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Code take from contracts/utils/structs/EnumerableMap.sol
    // because the helper functions are private

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    // AddressToAddressMap

    struct AddressToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(uint160(key))), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToAddressMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToAddressMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint160(uint256(key))), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool, address)
    {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToAddressMap storage map, address key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(uint256(uint160(key)))))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index)
        internal
        view
        returns (address, uint256)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToUintMap storage map, address key)
        internal
        view
        returns (bool, uint256)
    {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(uint160(key)))));
    }

    // Bytes32ToUIntMap

    struct Bytes32ToUIntMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUIntMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUIntMap storage map, bytes32 key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUIntMap storage map, bytes32 key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUIntMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUIntMap storage map, uint256 index)
        internal
        view
        returns (bytes32, uint256)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(Bytes32ToUIntMap storage map, bytes32 key)
        internal
        view
        returns (bool, uint256)
    {
        (bool success, bytes32 value) = _tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUIntMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(_get(map._inner, key));
    }
}


// File libraries/EnumerableExtensions.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;


library EnumerableExtensions {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableMapping for EnumerableMapping.AddressToAddressMap;
    using EnumerableMapping for EnumerableMapping.AddressToUintMap;
    using EnumerableMapping for EnumerableMapping.Bytes32ToUIntMap;

    function toArray(EnumerableSet.AddressSet storage addresses)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = addresses.length();
        address[] memory result = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = addresses.at(i);
        }
        return result;
    }

    function toArray(EnumerableSet.Bytes32Set storage values)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = values.length();
        bytes32[] memory result = new bytes32[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = values.at(i);
        }
        return result;
    }

    function keyAt(EnumerableMapping.AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address)
    {
        (address key, ) = map.at(index);
        return key;
    }

    function valueAt(EnumerableMapping.AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address)
    {
        (, address value) = map.at(index);
        return value;
    }

    function keyAt(EnumerableMapping.AddressToUintMap storage map, uint256 index)
        internal
        view
        returns (address)
    {
        (address key, ) = map.at(index);
        return key;
    }

    function keyAt(EnumerableMapping.Bytes32ToUIntMap storage map, uint256 index)
        internal
        view
        returns (bytes32)
    {
        (bytes32 key, ) = map.at(index);
        return key;
    }

    function valueAt(EnumerableMapping.AddressToUintMap storage map, uint256 index)
        internal
        view
        returns (uint256)
    {
        (, uint256 value) = map.at(index);
        return value;
    }

    function keysArray(EnumerableMapping.AddressToAddressMap storage map)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = map.length();
        address[] memory result = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = keyAt(map, i);
        }
        return result;
    }

    function valuesArray(EnumerableMapping.AddressToAddressMap storage map)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = map.length();
        address[] memory result = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = valueAt(map, i);
        }
        return result;
    }

    function keysArray(EnumerableMapping.AddressToUintMap storage map)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = map.length();
        address[] memory result = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = keyAt(map, i);
        }
        return result;
    }

    function keysArray(EnumerableMapping.Bytes32ToUIntMap storage map)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = map.length();
        bytes32[] memory result = new bytes32[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = keyAt(map, i);
        }
        return result;
    }
}


// File libraries/Roles.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

// solhint-disable private-vars-leading-underscore

library Roles {
    bytes32 internal constant GOVERNANCE = "governance";
    bytes32 internal constant ADDRESS_PROVIDER = "address_provider";
    bytes32 internal constant POOL_FACTORY = "pool_factory";
    bytes32 internal constant CONTROLLER = "controller";
    bytes32 internal constant GAUGE_ZAP = "gauge_zap";
    bytes32 internal constant MAINTENANCE = "maintenance";
    bytes32 internal constant INFLATION_MANAGER = "inflation_manager";
    bytes32 internal constant POOL = "pool";
    bytes32 internal constant VAULT = "vault";
}


// File contracts/access/AuthorizationBase.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;


/**
 * @notice Provides modifiers for authorization
 */
abstract contract AuthorizationBase {
    /**
     * @notice Only allows a sender with `role` to perform the given action
     */
    modifier onlyRole(bytes32 role) {
        require(_roleManager().hasRole(role, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with GOVERNANCE role to perform the given action
     */
    modifier onlyGovernance() {
        require(_roleManager().hasRole(Roles.GOVERNANCE, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with any of `roles` to perform the given action
     */
    modifier onlyRoles2(bytes32 role1, bytes32 role2) {
        require(_roleManager().hasAnyRole(role1, role2, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with any of `roles` to perform the given action
     */
    modifier onlyRoles3(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3
    ) {
        require(
            _roleManager().hasAnyRole(role1, role2, role3, msg.sender),
            Error.UNAUTHORIZED_ACCESS
        );
        _;
    }

    function roleManager() external view virtual returns (IRoleManager) {
        return _roleManager();
    }

    function _roleManager() internal view virtual returns (IRoleManager);
}


// File contracts/access/Authorization.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

contract Authorization is AuthorizationBase {
    IRoleManager internal immutable __roleManager;

    constructor(IRoleManager roleManager) {
        __roleManager = roleManager;
    }

    function _roleManager() internal view override returns (IRoleManager) {
        return __roleManager;
    }
}


// File contracts/utils/Preparable.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;


/**
 * @notice Implements the base logic for a two-phase commit
 * @dev This does not implements any access-control so publicly exposed
 * callers should make sure to have the proper checks in palce
 */
contract Preparable is IPreparable {
    uint256 private constant _MIN_DELAY = 3 days;

    mapping(bytes32 => address) public pendingAddresses;
    mapping(bytes32 => uint256) public pendingUInts256;

    mapping(bytes32 => address) public currentAddresses;
    mapping(bytes32 => uint256) public currentUInts256;

    /**
     * @dev Deadlines shares the same namespace regardless of the type
     * of the pending variable so this needs to be enforced in the caller
     */
    mapping(bytes32 => uint256) public deadlines;

    function _prepareDeadline(bytes32 key, uint256 delay) internal {
        require(deadlines[key] == 0, Error.DEADLINE_NOT_ZERO);
        require(delay >= _MIN_DELAY, Error.DELAY_TOO_SHORT);
        deadlines[key] = block.timestamp + delay;
    }

    /**
     * @notice Prepares an uint256 that should be commited to the contract
     * after `_MIN_DELAY` elapsed
     * @param value The value to prepare
     * @return `true` if success.
     */
    function _prepare(
        bytes32 key,
        uint256 value,
        uint256 delay
    ) internal returns (bool) {
        _prepareDeadline(key, delay);
        pendingUInts256[key] = value;
        emit ConfigPreparedNumber(key, value, delay);
        return true;
    }

    /**
     * @notice Same as `_prepare(bytes32,uint256,uint256)` but uses a default delay
     */
    function _prepare(bytes32 key, uint256 value) internal returns (bool) {
        return _prepare(key, value, _MIN_DELAY);
    }

    /**
     * @notice Prepares an address that should be commited to the contract
     * after `_MIN_DELAY` elapsed
     * @param value The value to prepare
     * @return `true` if success.
     */
    function _prepare(
        bytes32 key,
        address value,
        uint256 delay
    ) internal returns (bool) {
        _prepareDeadline(key, delay);
        pendingAddresses[key] = value;
        emit ConfigPreparedAddress(key, value, delay);
        return true;
    }

    /**
     * @notice Same as `_prepare(bytes32,address,uint256)` but uses a default delay
     */
    function _prepare(bytes32 key, address value) internal returns (bool) {
        return _prepare(key, value, _MIN_DELAY);
    }

    /**
     * @notice Reset a uint256 key
     * @return `true` if success.
     */
    function _resetUInt256Config(bytes32 key) internal returns (bool) {
        require(deadlines[key] != 0, Error.DEADLINE_NOT_ZERO);
        deadlines[key] = 0;
        pendingUInts256[key] = 0;
        emit ConfigReset(key);
        return true;
    }

    /**
     * @notice Reset an address key
     * @return `true` if success.
     */
    function _resetAddressConfig(bytes32 key) internal returns (bool) {
        require(deadlines[key] != 0, Error.DEADLINE_NOT_ZERO);
        deadlines[key] = 0;
        pendingAddresses[key] = address(0);
        emit ConfigReset(key);
        return true;
    }

    /**
     * @dev Checks the deadline of the key and reset it
     */
    function _executeDeadline(bytes32 key) internal {
        uint256 deadline = deadlines[key];
        require(block.timestamp >= deadline, Error.DEADLINE_NOT_REACHED);
        require(deadline != 0, Error.DEADLINE_NOT_SET);
        deadlines[key] = 0;
    }

    /**
     * @notice Execute uint256 config update (with time delay enforced).
     * @dev Needs to be called after the update was prepared. Fails if called before time delay is met.
     * @return New value.
     */
    function _executeUInt256(bytes32 key) internal returns (uint256) {
        _executeDeadline(key);
        uint256 newValue = pendingUInts256[key];
        _setConfig(key, newValue);
        return newValue;
    }

    /**
     * @notice Execute address config update (with time delay enforced).
     * @dev Needs to be called after the update was prepared. Fails if called before time delay is met.
     * @return New value.
     */
    function _executeAddress(bytes32 key) internal returns (address) {
        _executeDeadline(key);
        address newValue = pendingAddresses[key];
        _setConfig(key, newValue);
        return newValue;
    }

    function _setConfig(bytes32 key, address value) internal returns (address) {
        address oldValue = currentAddresses[key];
        currentAddresses[key] = value;
        pendingAddresses[key] = address(0);
        deadlines[key] = 0;
        emit ConfigUpdatedAddress(key, oldValue, value);
        return value;
    }

    function _setConfig(bytes32 key, uint256 value) internal returns (uint256) {
        uint256 oldValue = currentUInts256[key];
        currentUInts256[key] = value;
        pendingUInts256[key] = 0;
        deadlines[key] = 0;
        emit ConfigUpdatedNumber(key, oldValue, value);
        return value;
    }
}


// File contracts/actions/topup/TopUpAction.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;
















/**
 * @notice The logic here should really be part of the top-up action
 * but is split in a library to circumvent the byte-code size limit
 */
library TopUpActionLibrary {
    using SafeERC20 for IERC20;
    using ScaledMath for uint256;
    using AddressProviderHelpers for IAddressProvider;

    function lockFunds(
        address stakerVaultAddress,
        address payer,
        address token,
        uint256 lockAmount,
        uint256 depositAmount
    ) external {
        uint256 amountLeft = lockAmount;
        IStakerVault stakerVault = IStakerVault(stakerVaultAddress);

        // stake deposit amount
        if (depositAmount > 0) {
            depositAmount = depositAmount > amountLeft ? amountLeft : depositAmount;
            IERC20(token).safeTransferFrom(payer, address(this), depositAmount);
            IERC20(token).safeApprove(stakerVaultAddress, depositAmount);
            stakerVault.stake(depositAmount);
            stakerVault.increaseActionLockedBalance(payer, depositAmount);
            amountLeft -= depositAmount;
        }

        // use stake vault allowance if available and required
        if (amountLeft > 0) {
            uint256 balance = stakerVault.balanceOf(payer);
            uint256 allowance = stakerVault.allowance(payer, address(this));
            uint256 availableFunds = balance < allowance ? balance : allowance;
            if (availableFunds >= amountLeft) {
                stakerVault.transferFrom(payer, address(this), amountLeft);
                amountLeft = 0;
            }
        }

        require(amountLeft == 0, Error.INSUFFICIENT_UPDATE_BALANCE);
    }

    /**
     * @dev Computes and returns the amount of LP tokens of type `token` that will be received in exchange for an `amount` of the underlying.
     */
    function calcExchangeAmount(
        IAddressProvider addressProvider,
        address token,
        address actionToken,
        uint256 amount
    ) external view returns (uint256) {
        ILiquidityPool pool = addressProvider.getPoolForToken(token);
        uint256 rate = pool.exchangeRate();
        address underlying = pool.getUnderlying();
        if (underlying == actionToken) {
            return amount.scaledDivRoundUp(rate);
        }

        ISwapper swapper = getSwapper(addressProvider, underlying, actionToken);
        uint256 swapperRate = swapper.getRate(underlying, actionToken);
        return amount.scaledDivRoundUp(rate.scaledMul(swapperRate));
    }

    function getSwapper(
        IAddressProvider addressProvider,
        address underlying,
        address actionToken
    ) public view returns (ISwapper) {
        address swapperRegistry = addressProvider.getSwapperRegistry();
        address swapper = ISwapperRegistry(swapperRegistry).getSwapper(underlying, actionToken);
        require(swapper != address(0), Error.SWAP_PATH_NOT_FOUND);
        return ISwapper(swapper);
    }
}

contract TopUpAction is ITopUpAction, Authorization, Preparable, Initializable {
    using ScaledMath for uint256;
    using ScaledMath for uint128;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableExtensions for EnumerableSet.AddressSet;
    using AddressProviderHelpers for IAddressProvider;

    /**
     * @dev Temporary struct to hold local variables in execute
     * and avoid the stack being "too deep"
     */
    struct ExecuteLocalVars {
        uint256 minActionAmountToTopUp;
        uint256 actionTokenAmount;
        uint256 depositTotalFeesAmount;
        uint256 actionAmountWithFees;
        uint256 userFactor;
        uint256 rate;
        uint256 depositAmountWithFees;
        uint256 depositAmountWithoutFees;
        uint256 actionFee;
        uint256 totalActionTokenAmount;
        uint128 totalTopUpAmount;
        bool success;
        bytes topupResult;
        uint256 gasBankBalance;
        uint256 initialGas;
        uint256 gasConsumed;
        uint256 userGasPrice;
        uint256 estimatedRequiredGas;
        uint256 estimatedRequiredWeiForGas;
        uint256 requiredWeiForGas;
        uint256 reimbursedWeiForGas;
        address underlying;
        bool removePosition;
    }

    EnumerableSet.AddressSet private _usableTokens;

    uint256 internal constant _INITIAL_ESTIMATED_GAS_USAGE = 500_000;

    bytes32 internal constant _ACTION_FEE_KEY = "ActionFee";
    bytes32 internal constant _FEE_HANDLER_KEY = "FeeHandler";
    bytes32 internal constant _TOP_UP_HANDLER_KEY = "TopUpHandler";
    bytes32 internal constant _ESTIMATED_GAS_USAGE_KEY = "EstimatedGasUsage";
    bytes32 internal constant _MAX_SWAPPER_SLIPPAGE_KEY = "MaxSwapperSlippage";

    uint256 internal constant _MAX_ACTION_FEE = 0.5 * 1e18;
    uint256 internal constant _MIN_SWAPPER_SLIPPAGE = 0.6 * 1e18;
    uint256 internal constant _MAX_SWAPPER_SLIPPAGE = 0.95 * 1e18;

    IController public immutable controller;
    IAddressProvider public immutable addressProvider;

    EnumerableSet.Bytes32Set internal _supportedProtocols;

    /// @notice mapping of (payer -> account -> protocol -> Record)
    mapping(address => mapping(bytes32 => mapping(bytes32 => Record))) private _positions;

    mapping(address => RecordMeta[]) internal _userPositions;

    EnumerableSet.AddressSet internal _usersWithPositions;

    constructor(IController _controller)
        Authorization(_controller.addressProvider().getRoleManager())
    {
        controller = _controller;
        addressProvider = controller.addressProvider();
        _setConfig(_ESTIMATED_GAS_USAGE_KEY, _INITIAL_ESTIMATED_GAS_USAGE);
    }

    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    function initialize(
        address feeHandler,
        bytes32[] calldata protocols,
        address[] calldata handlers
    ) external initializer onlyGovernance {
        require(protocols.length == handlers.length, Error.INVALID_ARGUMENT);
        _setConfig(_FEE_HANDLER_KEY, feeHandler);
        _setConfig(_MAX_SWAPPER_SLIPPAGE_KEY, _MAX_SWAPPER_SLIPPAGE);
        for (uint256 i = 0; i < protocols.length; i++) {
            bytes32 protocolKey = _getProtocolKey(protocols[i]);
            _setConfig(protocolKey, handlers[i]);
            _updateTopUpHandler(protocols[i], address(0), handlers[i]);
        }
    }

    /**
     * @notice Register a top up action.
     * @dev The `depositAmount` must be greater or equal to the `totalTopUpAmount` (which is denominated in `actionToken`).
     * @param account Account to be topped up (first 20 bytes will typically be the address).
     * @param depositAmount Amount of `depositToken` that will be locked.
     * @param protocol Protocol which holds position to be topped up.
     * @param record containing the data for the position to register
     */
    function register(
        bytes32 account,
        bytes32 protocol,
        uint128 depositAmount,
        Record memory record
    ) external payable returns (bool) {
        require(_supportedProtocols.contains(protocol), Error.PROTOCOL_NOT_FOUND);
        require(record.singleTopUpAmount > 0, Error.INVALID_AMOUNT);
        require(record.threshold > ScaledMath.ONE, Error.INVALID_AMOUNT);
        require(record.singleTopUpAmount <= record.totalTopUpAmount, Error.INVALID_AMOUNT);
        require(
            _positions[msg.sender][account][protocol].threshold == 0,
            Error.POSITION_ALREADY_EXISTS
        );
        require(_isSwappable(record.depositToken, record.actionToken), Error.SWAP_PATH_NOT_FOUND);
        require(isUsable(record.depositToken), Error.TOKEN_NOT_USABLE);

        uint256 gasDeposit = (record.totalTopUpAmount.divRoundUp(record.singleTopUpAmount)) *
            record.maxFee *
            getEstimatedGasUsage();

        require(msg.value >= gasDeposit, Error.VALUE_TOO_LOW_FOR_GAS);

        uint256 totalLockAmount = _calcExchangeAmount(
            record.depositToken,
            record.actionToken,
            record.totalTopUpAmount
        );
        _lockFunds(msg.sender, record.depositToken, totalLockAmount, depositAmount);

        addressProvider.getGasBank().depositFor{value: msg.value}(msg.sender);

        record.depositTokenBalance = uint128(totalLockAmount);
        _positions[msg.sender][account][protocol] = record;
        _userPositions[msg.sender].push(RecordMeta(account, protocol));
        _usersWithPositions.add(msg.sender);

        emit Register(
            account,
            protocol,
            record.threshold,
            msg.sender,
            record.depositToken,
            totalLockAmount,
            record.actionToken,
            record.singleTopUpAmount,
            record.totalTopUpAmount,
            record.maxFee,
            record.extra
        );
        return true;
    }

    /**
     * @notice See overloaded version of `execute` for more details.
     */
    function execute(
        address payer,
        bytes32 account,
        address beneficiary,
        bytes32 protocol
    ) external override returns (bool) {
        return execute(payer, account, beneficiary, protocol, 0);
    }

    /**
     * @notice Delete a position to back on the given protocol for `account`.
     * @param account Account holding the position.
     * @param protocol Protocol the position is held on.
     * @param unstake If the tokens should be unstaked from vault.
     * @return `true` if successful.
     */
    function resetPosition(
        bytes32 account,
        bytes32 protocol,
        bool unstake
    ) external override returns (bool) {
        address payer = msg.sender;
        Record memory position = _positions[payer][account][protocol];
        require(position.threshold != 0, Error.NO_POSITION_EXISTS);

        address vault = addressProvider.getStakerVault(position.depositToken); // will revert if vault does not exist
        IStakerVault staker = IStakerVault(vault);
        staker.decreaseActionLockedBalance(payer, position.depositTokenBalance);
        if (unstake) {
            staker.unstake(position.depositTokenBalance);
            IERC20(position.depositToken).safeTransfer(payer, position.depositTokenBalance);
        } else {
            staker.transfer(payer, position.depositTokenBalance);
        }

        _removePosition(payer, account, protocol);
        addressProvider.getGasBank().withdrawUnused(payer);
        return true;
    }

    /**
     * @notice Execute top up handler update (with time delay enforced).
     * @dev Needs to be called after the update was prepared. Fails if called before time delay is met.
     * @param protocol Protocol for which a new handler should be executed.
     * @return Address of new handler.
     */
    function executeTopUpHandler(bytes32 protocol) external override returns (address) {
        address oldHandler = _getHandler(protocol, false);
        address newHandler = _executeAddress(_getProtocolKey(protocol));

        _updateTopUpHandler(protocol, oldHandler, newHandler);
        return newHandler;
    }

    /**
     * @notice Reset new top up handler deadline for a protocol.
     * @param protocol Protocol for which top up handler deadline should be reset.
     * @return `true` if successful.
     */
    function resetTopUpHandler(bytes32 protocol) external onlyGovernance returns (bool) {
        return _resetAddressConfig(_getProtocolKey(protocol));
    }

    /**
     * @notice Prepare action fee update.
     * @param newActionFee New fee to set.
     * @return `true` if success.
     */
    function prepareActionFee(uint256 newActionFee) external onlyGovernance returns (bool) {
        require(newActionFee <= _MAX_ACTION_FEE, Error.INVALID_AMOUNT);
        return _prepare(_ACTION_FEE_KEY, newActionFee);
    }

    /**
     * @notice Execute action fee update (with time delay enforced).
     * @dev Needs to be called after the update was prepared. Fails if called before time delay is met.
     * @return `true` if successful.
     */
    function executeActionFee() external override returns (uint256) {
        return _executeUInt256(_ACTION_FEE_KEY);
    }

    /**
     * @notice Reset action fee deadline.
     * @return `true` if successful.
     */
    function resetActionFee() external onlyGovernance returns (bool) {
        return _resetUInt256Config(_ACTION_FEE_KEY);
    }

    /**
     * @notice Prepare swapper slippage update.
     * @param newSwapperSlippage New slippage to set.
     * @return `true` if success.
     */
    function prepareSwapperSlippage(uint256 newSwapperSlippage)
        external
        onlyGovernance
        returns (bool)
    {
        require(
            newSwapperSlippage >= _MIN_SWAPPER_SLIPPAGE &&
                newSwapperSlippage <= _MAX_SWAPPER_SLIPPAGE,
            Error.INVALID_AMOUNT
        );
        return _prepare(_MAX_SWAPPER_SLIPPAGE_KEY, newSwapperSlippage);
    }

    /**
     * @notice Execute swapper slippage update (with time delay enforced).
     * @dev Needs to be called after the update was prepared. Fails if called before time delay is met.
     * @return `true` if successful.
     */
    function executeSwapperSlippage() external override returns (uint256) {
        return _executeUInt256(_MAX_SWAPPER_SLIPPAGE_KEY);
    }

    /**
     * @notice Reset action fee deadline.
     * @return `true` if successful.
     */
    function resetSwapperSlippage() external onlyGovernance returns (bool) {
        return _resetUInt256Config(_MAX_SWAPPER_SLIPPAGE_KEY);
    }

    /** Set fee handler */
    /**
     * @notice Prepare update of fee handler.
     * @param handler New fee handler.
     * @return `true` if success.
     */
    function prepareFeeHandler(address handler) external onlyGovernance returns (bool) {
        return _prepare(_FEE_HANDLER_KEY, handler);
    }

    /**
     * @notice Execute update of fee handler (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return `true` if successful.
     */
    function executeFeeHandler() external override returns (address) {
        return _executeAddress(_FEE_HANDLER_KEY);
    }

    /**
     * @notice Reset the handler deadline.
     * @return `true` if success.
     */
    function resetFeeHandler() external onlyGovernance returns (bool) {
        return _resetAddressConfig(_FEE_HANDLER_KEY);
    }

    /**
     * @notice Prepare update of estimated gas usage.
     * @param gasUsage New estimated gas usage.
     * @return `true` if success.
     */
    function prepareEstimatedGasUsage(uint256 gasUsage) external onlyGovernance returns (bool) {
        return _prepare(_ESTIMATED_GAS_USAGE_KEY, gasUsage);
    }

    /**
     * @notice Execute update of gas usage (with time delay enforced).
     * @return `true` if successful.
     */
    function executeEstimatedGasUsage() external returns (uint256) {
        return _executeUInt256(_ESTIMATED_GAS_USAGE_KEY);
    }

    /**
     * @notice Reset the gas usage deadline.
     * @return `true` if success.
     */
    function resetGasUsage() external onlyGovernance returns (bool) {
        return _resetUInt256Config(_ESTIMATED_GAS_USAGE_KEY);
    }

    /**
     * @notice Add a new deposit token that is supported by the action.
     * @dev There is a separate check for whether the usable token (i.e. deposit token)
     *      is swappable for some action token.
     * @param token Address of deposit token that can be used by the action.
     */
    function addUsableToken(address token) external override onlyGovernance returns (bool) {
        return _usableTokens.add(token);
    }

    /**
     * @notice Computes the total amount of ETH (as wei) required to pay for all
     * the top-ups assuming the maximum gas price and the current estimated gas
     * usage of a top-up
     */
    function getEthRequiredForGas(address payer) external view override returns (uint256) {
        uint256 totalEthRequired = 0;
        RecordMeta[] memory userRecordsMeta = _userPositions[payer];
        uint256 gasUsagePerCall = getEstimatedGasUsage();
        uint256 length = userRecordsMeta.length;
        for (uint256 i = 0; i < length; i++) {
            RecordMeta memory meta = userRecordsMeta[i];
            Record memory record = _positions[payer][meta.account][meta.protocol];
            uint256 totalCalls = record.totalTopUpAmount.divRoundUp(record.singleTopUpAmount);
            totalEthRequired += totalCalls * gasUsagePerCall * record.maxFee;
        }
        return totalEthRequired;
    }

    /**
     * @notice Returns a list of positions for the given payer
     */
    function getUserPositions(address payer) external view override returns (RecordMeta[] memory) {
        return _userPositions[payer];
    }

    /**
     * @notice Get a list supported protocols.
     * @return List of supported protocols.
     */
    function getSupportedProtocols() external view override returns (bytes32[] memory) {
        uint256 length = _supportedProtocols.length();
        bytes32[] memory protocols = new bytes32[](length);
        for (uint256 i = 0; i < length; i++) {
            protocols[i] = _supportedProtocols.at(i);
        }
        return protocols;
    }

    /*
     * @notice Gets a list of users that have an active position.
     * @dev Uses cursor pagination.
     * @param cursor The cursor for pagination (should start at 0 for first call).
     * @param howMany Maximum number of users to return in this pagination request.
     * @return users List of users that have an active position.
     * @return nextCursor The cursor to use for the next pagination request.
     */
    function usersWithPositions(uint256 cursor, uint256 howMany)
        external
        view
        override
        returns (address[] memory users, uint256 nextCursor)
    {
        uint256 length = _usersWithPositions.length();
        if (cursor >= length) return (new address[](0), 0);
        if (howMany >= length - cursor) {
            howMany = length - cursor;
        }

        address[] memory usersWithPositions_ = new address[](howMany);
        for (uint256 i = 0; i < howMany; i++) {
            usersWithPositions_[i] = _usersWithPositions.at(i + cursor);
        }

        return (usersWithPositions_, cursor + howMany);
    }

    /**
     * @notice Get a list of all tokens usable for this action.
     * @dev This refers to all tokens that can be used as deposit tokens.
     * @return Array of addresses of usable tokens.
     */
    function getUsableTokens() external view override returns (address[] memory) {
        return _usableTokens.toArray();
    }

    /**
     * @notice Retrieves the topup handler for the given `protocol`
     */
    function getTopUpHandler(bytes32 protocol) external view returns (address) {
        return _getHandler(protocol, false);
    }

    /**
     * @notice Successfully tops up a position if it's conditions are met.
     * @dev pool and vault funds are rebalanced after withdrawal for top up
     * @param payer Account that pays for the top up.
     * @param account Account owning the position for top up.
     * @param beneficiary Address of the keeper's wallet for fee accrual.
     * @param protocol Protocol of the top up position.
     * @param maxWeiForGas the maximum extra amount of wei that the keeper is willing to pay for the gas
     * @return `true` if successful.
     */
    function execute(
        address payer,
        bytes32 account,
        address beneficiary,
        bytes32 protocol,
        uint256 maxWeiForGas
    ) public override returns (bool) {
        require(controller.canKeeperExecuteAction(msg.sender), Error.NOT_ENOUGH_BKD_STAKED);

        ExecuteLocalVars memory vars;

        vars.initialGas = gasleft();

        Record storage position = _positions[payer][account][protocol];
        require(position.threshold != 0, Error.NO_POSITION_EXISTS);
        require(position.totalTopUpAmount > 0, Error.INSUFFICIENT_BALANCE);

        address topUpHandler = _getHandler(protocol, true);
        vars.userFactor = ITopUpHandler(topUpHandler).getUserFactor(account, position.extra);

        // ensure that the position is actually below its set user factor threshold
        require(vars.userFactor < position.threshold, Error.INSUFFICIENT_THRESHOLD);

        IGasBank gasBank = addressProvider.getGasBank();

        // fail early if the user does not have enough funds in the gas bank
        // to cover the cost of the transaction
        vars.estimatedRequiredGas = getEstimatedGasUsage();
        vars.estimatedRequiredWeiForGas = vars.estimatedRequiredGas * tx.gasprice;

        // compute the gas price that the user will be paying
        vars.userGasPrice = block.basefee + position.priorityFee;
        if (vars.userGasPrice > tx.gasprice) vars.userGasPrice = tx.gasprice;
        if (vars.userGasPrice > position.maxFee) vars.userGasPrice = position.maxFee;

        // ensure the current position allows for the gas to be paid
        require(
            vars.estimatedRequiredWeiForGas <=
                vars.estimatedRequiredGas * vars.userGasPrice + maxWeiForGas,
            Error.ESTIMATED_GAS_TOO_HIGH
        );

        vars.gasBankBalance = gasBank.balanceOf(payer);
        // ensure the user has enough funds in the gas bank to cover the gas
        require(
            vars.gasBankBalance + maxWeiForGas >= vars.estimatedRequiredWeiForGas,
            Error.GAS_BANK_BALANCE_TOO_LOW
        );

        vars.totalTopUpAmount = position.totalTopUpAmount;
        vars.actionFee = getActionFee();
        // add top-up fees to top-up amount
        vars.minActionAmountToTopUp = position.singleTopUpAmount;
        vars.actionAmountWithFees = vars.minActionAmountToTopUp.scaledMul(
            ScaledMath.ONE + vars.actionFee
        );

        // if the amount that we want to top-up (including fees) is higher than
        // the available topup amount, we lower this down to what is left of the position
        if (vars.actionAmountWithFees > vars.totalTopUpAmount) {
            vars.actionAmountWithFees = vars.totalTopUpAmount;
            vars.minActionAmountToTopUp = vars.actionAmountWithFees.scaledDiv(
                ScaledMath.ONE + vars.actionFee
            );
        }
        ILiquidityPool pool = addressProvider.getPoolForToken(position.depositToken);
        vars.underlying = pool.getUnderlying();
        vars.rate = pool.exchangeRate();

        ISwapper swapper;

        if (vars.underlying != position.actionToken) {
            swapper = _getSwapper(vars.underlying, position.actionToken);
            vars.rate = vars.rate.scaledMul(swapper.getRate(vars.underlying, position.actionToken));
        }

        // compute the deposit tokens amount with and without fees
        // we will need to unstake the amount with fees and to
        // swap the amount without fees into action tokens
        vars.depositAmountWithFees = vars.actionAmountWithFees.scaledDivRoundUp(vars.rate);
        if (position.depositTokenBalance < vars.depositAmountWithFees) {
            vars.depositAmountWithFees = position.depositTokenBalance;
            vars.minActionAmountToTopUp =
                (vars.depositAmountWithFees * vars.rate) /
                (ScaledMath.ONE + vars.actionFee);
        }

        // compute amount of LP tokens needed to pay for action
        // rate is expressed in actionToken per depositToken
        vars.depositAmountWithoutFees = vars.minActionAmountToTopUp.scaledDivRoundUp(vars.rate);
        vars.depositTotalFeesAmount = vars.depositAmountWithFees - vars.depositAmountWithoutFees;

        // will revert if vault does not exist
        address vault = addressProvider.getStakerVault(position.depositToken);

        // unstake deposit tokens including fees
        IStakerVault(vault).unstake(vars.depositAmountWithFees);
        IStakerVault(vault).decreaseActionLockedBalance(payer, vars.depositAmountWithFees);

        // swap the amount without the fees
        // as the fees are paid in deposit token, not in action token
        // Redeem first and use swapper only if the underlying tokens are not action tokens
        vars.actionTokenAmount = pool.redeem(vars.depositAmountWithoutFees);

        if (address(swapper) != address(0)) {
            vars.minActionAmountToTopUp = vars.minActionAmountToTopUp.scaledMul(
                getSwapperSlippage()
            );
            _approve(vars.underlying, address(swapper));
            vars.actionTokenAmount = swapper.swap(
                vars.underlying,
                position.actionToken,
                vars.actionTokenAmount,
                vars.minActionAmountToTopUp
            );
        }

        // compute how much of action token was actually redeemed and add fees to it
        // this is to ensure that no funds get locked inside the contract
        vars.totalActionTokenAmount =
            vars.actionTokenAmount +
            vars.depositTotalFeesAmount.scaledMul(vars.rate);

        // at this point, we have exactly `vars.actionTokenAmount`
        // (at least `position.singleTopUpAmount`) of action token
        // and exactly `vars.depositTotalFeesAmount` deposit tokens in the contract
        // solhint-disable-next-line avoid-low-level-calls
        (vars.success, vars.topupResult) = topUpHandler.delegatecall(
            abi.encodeWithSignature(
                "topUp(bytes32,address,uint256,bytes)",
                account,
                position.actionToken,
                vars.actionTokenAmount,
                position.extra
            )
        );

        require(vars.success && abi.decode(vars.topupResult, (bool)), Error.TOP_UP_FAILED);

        // totalTopUpAmount is updated to reflect the new "balance" of the position
        if (vars.totalTopUpAmount > vars.totalActionTokenAmount) {
            position.totalTopUpAmount -= uint128(vars.totalActionTokenAmount);
        } else {
            position.totalTopUpAmount = 0;
        }

        position.depositTokenBalance -= uint128(vars.depositAmountWithFees);

        vars.removePosition = position.totalTopUpAmount == 0 || position.depositTokenBalance == 0;
        _payFees(payer, beneficiary, vars.depositTotalFeesAmount, position.depositToken);
        if (vars.removePosition) {
            if (position.depositTokenBalance > 0) {
                // transfer any unused locked tokens to the payer
                IStakerVault(vault).transfer(payer, position.depositTokenBalance);
                IStakerVault(vault).decreaseActionLockedBalance(
                    payer,
                    position.depositTokenBalance
                );
            }
            _removePosition(payer, account, protocol);
        }

        emit TopUp(
            account,
            protocol,
            payer,
            position.depositToken,
            vars.depositAmountWithFees,
            position.actionToken,
            vars.actionTokenAmount
        );

        // compute gas used and reimburse the keeper by using the
        // funds of payer in the gas bank
        // TODO: add constant gas consumed for transfer and tx prologue
        vars.gasConsumed = vars.initialGas - gasleft();

        vars.reimbursedWeiForGas = vars.userGasPrice * vars.gasConsumed;
        if (vars.reimbursedWeiForGas > vars.gasBankBalance) {
            vars.reimbursedWeiForGas = vars.gasBankBalance;
        }

        // ensure that the keeper is not overpaying
        vars.requiredWeiForGas = tx.gasprice * vars.gasConsumed;
        require(
            vars.reimbursedWeiForGas + maxWeiForGas >= vars.requiredWeiForGas,
            Error.GAS_TOO_HIGH
        );
        gasBank.withdrawFrom(payer, payable(msg.sender), vars.reimbursedWeiForGas);
        if (vars.removePosition) {
            gasBank.withdrawUnused(payer);
        }

        return true;
    }

    /**
     * @notice Prepare new top up handler fee update.
     * @dev Setting the addres to 0 means that the protocol will no longer be supported.
     * @param protocol Protocol for which a new handler should be prepared.
     * @param newHandler Address of new handler.
     * @return `true` if success.
     */
    function prepareTopUpHandler(bytes32 protocol, address newHandler)
        public
        onlyGovernance
        returns (bool)
    {
        return _prepare(_getProtocolKey(protocol), newHandler);
    }

    /**
     * @notice Check if action can be executed.
     * @param protocol for which to get the health factor
     * @param account for which to get the health factor
     * @param extra data to be used by the topup handler
     * @return healthFactor of the position
     */
    function getHealthFactor(
        bytes32 protocol,
        bytes32 account,
        bytes memory extra
    ) public view override returns (uint256 healthFactor) {
        ITopUpHandler topUpHandler = ITopUpHandler(_getHandler(protocol, true));
        return topUpHandler.getUserFactor(account, extra);
    }

    function getHandler(bytes32 protocol) public view override returns (address) {
        return _getHandler(protocol, false);
    }

    /**
     * @notice returns the current estimated gas usage
     */
    function getEstimatedGasUsage() public view returns (uint256) {
        return currentUInts256[_ESTIMATED_GAS_USAGE_KEY];
    }

    /**
     * @notice Returns the current action fee
     */
    function getActionFee() public view override returns (uint256) {
        return currentUInts256[_ACTION_FEE_KEY];
    }

    /**
     * @notice Returns the current max swapper slippage
     */
    function getSwapperSlippage() public view override returns (uint256) {
        return currentUInts256[_MAX_SWAPPER_SLIPPAGE_KEY];
    }

    /**
     * @notice Returns the current fee handler
     */
    function getFeeHandler() public view override returns (address) {
        return currentAddresses[_FEE_HANDLER_KEY];
    }

    /**
     * @notice Get the record for a position.
     * @param payer Registered payer of the position.
     * @param account Address holding the position.
     * @param protocol Protocol where the position is held.
     */
    function getPosition(
        address payer,
        bytes32 account,
        bytes32 protocol
    ) public view override returns (Record memory) {
        return _positions[payer][account][protocol];
    }

    /**
     * @notice Check whether a token is usable as a deposit token.
     * @param token Address of token to check.
     * @return True if token is usable as a deposit token for this action.
     */
    function isUsable(address token) public view override returns (bool) {
        return _usableTokens.contains(token);
    }

    function _updateTopUpHandler(
        bytes32 protocol,
        address oldHandler,
        address newHandler
    ) internal {
        if (newHandler == address(0)) {
            _supportedProtocols.remove(protocol);
        } else if (oldHandler == address(0)) {
            _supportedProtocols.add(protocol);
        }
    }

    /**
     * @dev Pays fees to the feeHandler
     * @param payer The account who's position the fees are charged on
     * @param beneficiary The beneficiary of the fees paid (usually this will be the keeper)
     * @param feeAmount The amount in tokens to pay as fees
     * @param depositToken The LpToken used to pay the fees
     */
    function _payFees(
        address payer,
        address beneficiary,
        uint256 feeAmount,
        address depositToken
    ) internal {
        address feeHandler = getFeeHandler();
        IERC20(depositToken).safeApprove(feeHandler, feeAmount);
        IActionFeeHandler(feeHandler).payFees(payer, beneficiary, feeAmount, depositToken);
    }

    /**
     * @dev "Locks" an amount of tokens on behalf of the TopUpAction
     * Funds are taken from staker vault if allowance is sufficient, else direct transfer or a combination of both.
     * @param payer Owner of the funds to be locked
     * @param token Token to lock
     * @param lockAmount Minimum amount of `token` to lock
     * @param depositAmount Amount of `token` that was deposited.
     *                      If this is 0 then the staker vault allowance should be used.
     *                      If this is greater than `requiredAmount` more tokens will be locked.
     */
    function _lockFunds(
        address payer,
        address token,
        uint256 lockAmount,
        uint256 depositAmount
    ) internal {
        address stakerVaultAddress = addressProvider.getStakerVault(token);
        TopUpActionLibrary.lockFunds(stakerVaultAddress, payer, token, lockAmount, depositAmount);
    }

    function _removePosition(
        address payer,
        bytes32 account,
        bytes32 protocol
    ) internal {
        delete _positions[payer][account][protocol];
        _removeUserPosition(payer, account, protocol);
        if (_userPositions[payer].length == 0) {
            _usersWithPositions.remove(payer);
        }
        emit Deregister(payer, account, protocol);
    }

    function _removeUserPosition(
        address payer,
        bytes32 account,
        bytes32 protocol
    ) internal {
        RecordMeta[] storage positionsMeta = _userPositions[payer];
        uint256 length = positionsMeta.length;
        for (uint256 i = 0; i < length; i++) {
            RecordMeta storage positionMeta = positionsMeta[i];
            if (positionMeta.account == account && positionMeta.protocol == protocol) {
                positionsMeta[i] = positionsMeta[length - 1];
                positionsMeta.pop();
                return;
            }
        }
    }

    /**
     * @dev Approves infinite spending for the given spender.
     * @param token The token to approve for.
     * @param spender The spender to approve.
     */
    function _approve(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) > 0) return;
        IERC20(token).safeApprove(spender, type(uint256).max);
    }

    /**
     * @dev Computes and returns the amount of LP tokens of type `token` that will be received in exchange for an `amount` of the underlying.
     */
    function _calcExchangeAmount(
        address token,
        address actionToken,
        uint256 amount
    ) internal view returns (uint256) {
        return TopUpActionLibrary.calcExchangeAmount(addressProvider, token, actionToken, amount);
    }

    function _getSwapper(address underlying, address actionToken) internal view returns (ISwapper) {
        return TopUpActionLibrary.getSwapper(addressProvider, underlying, actionToken);
    }

    function _getHandler(bytes32 protocol, bool ensureExists) internal view returns (address) {
        address handler = currentAddresses[_getProtocolKey(protocol)];
        require(!ensureExists || handler != address(0), Error.PROTOCOL_NOT_FOUND);
        return handler;
    }

    function _isSwappable(address depositToken, address toToken) internal view returns (bool) {
        ILiquidityPool pool = addressProvider.getPoolForToken(depositToken);
        address underlying = pool.getUnderlying();
        if (underlying == toToken) {
            return true;
        }
        address swapperRegistry = addressProvider.getSwapperRegistry();
        return ISwapperRegistry(swapperRegistry).swapperExists(underlying, toToken);
    }

    function _getProtocolKey(bytes32 protocol) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_TOP_UP_HANDLER_KEY, protocol));
    }
}