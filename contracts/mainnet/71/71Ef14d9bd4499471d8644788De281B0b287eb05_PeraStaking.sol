/**
 *Submitted for verification at snowtrace.io on 2022-04-18
*/

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/PeraStaking.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;




/// @author Ulaş Erdoğan
/// @title Staking Contract with Weights for Multi Asset Gains
/// @dev Inspired by Synthetix by adding "multi asset rewards" and time weighting
contract PeraStaking is Ownable {
    /////////// Interfaces & Libraries ///////////

    // Using OpenZeppelin's EnumerableSet Util
    using EnumerableSet for EnumerableSet.UintSet;
    // Using OpenZeppelin's SafeERC20 Util
    using SafeERC20 for IERC20;

    /////////// Structs ///////////

    // Information of reward tokens
    struct TokenInfo {
        IERC20 tokenInstance; // ERC-20 interface of tokens
        uint256 rewardRate; // Distributing count per second
        uint256 rewardPerTokenStored; // Staking calculation helper
        uint256 deadline; // Deadline of reward distributing
        uint8 decimals; // Decimal count of token
    }

    // Information of users staking details
    struct UserInfo {
        uint256 userStaked; // Staked balance per user
        uint16 userWeights; // Staking coefficient per user
        uint48 stakedTimestamp; // Staking timestamp of the users
        uint48 userUnlockingTime; // Unlocking timestamp of the users
    }

    /////////// Type Declarations ///////////

    // All historical reward token data
    TokenInfo[] private tokenList;
    // List of actively distributing token data
    EnumerableSet.UintSet private activeRewards;

    // User Data

    // User data which contains personal variables
    mapping(address => UserInfo) public userData;
    // rewardPerTokenPaid data for each reward tokens
    mapping(uint256 => mapping(address => uint256))
        private userRewardsPerTokenPaid;
    // Reward data for each reward token
    mapping(uint256 => mapping(address => uint256)) private tokenRewards;

    /////////// State Variables ///////////

    // Deadline to locked stakings - after which date the token cannot be locked
    uint256 public lockLimit;
    // Last stake operations
    uint256 public lastUpdateTime;
    // Total staked token amount
    uint256 public totalStaked;
    // Total weighted staked amount
    uint256 public wTotalStaked;
    // Cutted tokens destination address
    address public penaltyAddress;
    // Staking - withdrawing availability
    bool public isStakeOpen;
    // Claiming availability
    bool public isClaimOpen;
    // Emergency withdraw availability
    bool public isEmergencyOpen;

    /////////// Events ///////////

    // User initially stakes token
    event Staked(address _user, uint256 _amount, uint256 _time);
    //User increases stake amount
    event IncreaseStaked(address _user, uint256 _amount);
    // User withdraws token before the unlock time
    event PunishedWithdraw(
        address _user,
        uint256 _burntAmount,
        uint256 _amount
    );
    // User withdraws token on time
    event Withdraw(address _user, uint256 _amount);
    // User claims rewards
    event Claimed(address _user);
    // New reward token added by owner
    event NewReward(address _tokenAddress, uint256 _id);
    // Staking status switched
    event StakeStatusChanged(bool _newStatus);
    // Claim status switched
    event ClaimStatusChanged(bool _newStatus);
    // Emergency status is active
    event EmergencyStatusChanged(bool _newStatus);
    // Lock deadline change
    event LockLimitChanged(uint256 _lockLimit);

    /////////// Functions ///////////

    /**
     * @notice Constructor function - takes the parameters of the competition
     * @param _mainTokenAddress address - Main staking asset of the contract
     * @param _penaltyAddress address - Destination address of the cutted tokens
     * @param _rewardRate uint256 - Main tokens distribution rate per second
     * @param _lockLimit uint256 - Deadline for stake locks
     */
    constructor(
        address _mainTokenAddress,
        address _penaltyAddress,
        uint256 _rewardRate,
        uint256 _lockLimit
    ) {
        require(
            _mainTokenAddress != address(0),
            "[] Address failure."
        );
        require(
            _penaltyAddress != address(0),
            "[] Address failure."
        );
        TokenInfo memory info = TokenInfo(
            IERC20(_mainTokenAddress),
            _rewardRate,
            0,
            0,
            18
        );
        tokenList.push(info);
        require(activeRewards.add(tokenList.length - 1));
        penaltyAddress = _penaltyAddress;
        lockLimit = _lockLimit;
    }

    /**
     * @notice Direct native coin transfers are closed
     */
    receive() external payable {
        revert();
    }

    /**
     * @notice Direct native coin transfers are closed
     */
    fallback() external {
        revert();
    }

    /**
     * @notice Initializing stake position for users
     * @dev The staking token need to be approved to the contract by the user
     * @dev Maximum staking duration is {lockLimit - block.timestamp}
     * @param _amount uint256 - initial staking amount
     * @param _time uint256 - staking duration of tokens
     */
    function initialStake(uint256 _amount, uint256 _time)
        external
        stakeOpen
        updateReward(msg.sender)
    {
        require(
            userData[msg.sender].userUnlockingTime == 0,
            "[initialStake] Already staked!"
        );
        require(_amount > 0, "[initialStake] Insufficient amount.");
        require(_time > 0, "[initialStake] Insufficient time.");
        require(
            block.timestamp + _time < lockLimit,
            "[initialStake] Lock limit exceeded!"
        );

        // Sets user data
        userData[msg.sender].userWeights = calcWeight(_time);
        userData[msg.sender].userUnlockingTime = uint48(
            block.timestamp + _time
        );
        userData[msg.sender].stakedTimestamp = uint48(block.timestamp);

        wTotalStaked += (userData[msg.sender].userWeights * _amount);
        emit Staked(msg.sender, _amount, _time);

        // Manages internal stake amounts
        _increase(_amount);
    }

    /**
     * @notice Increasing stake position for user
     * @dev The staking token need to be approved to the contract by the user
     * @param _amount uint256 - increasing stake amount
     */
    function additionalStake(uint256 _amount)
        external
        stakeOpen
        updateReward(msg.sender)
    {
        require(
            userData[msg.sender].userUnlockingTime != 0,
            "[additionalStake] Initial stake not found!"
        );
        require(_amount > 0, "[additionalStake] Insufficient amount.");
        require(
            userData[msg.sender].userUnlockingTime > block.timestamp,
            "[additionalStake] Reached unlocking time!"
        );

        // Re-calculating weights
        uint16 _additionWeight = calcWeight(
            uint256(userData[msg.sender].userUnlockingTime) - block.timestamp
        );
        userData[msg.sender].userWeights = uint16(
            (calcWeightedStake(msg.sender) +
                (_amount * uint256(_additionWeight))) /
                (userData[msg.sender].userStaked + _amount)
        );
        wTotalStaked += uint256(_additionWeight) * _amount;
        emit IncreaseStaked(msg.sender, _amount);

        // Manages internal stake amounts
        _increase(_amount);
    }

    /**
     * @notice Withdraws staked position w/wo penalties
     * @dev User gets less token from 75% to 25% if the unlocking time has not reached
     */
    function withdraw() external updateReward(msg.sender) {
        require(
            userData[msg.sender].userStaked > 0,
            "[withdraw] No staked balance."
        );

        uint256 _penaltyRate = 0;
        if (
            block.timestamp >= uint256(userData[msg.sender].userUnlockingTime)
        ) {
            // Staking time is over - free withdrawing
            emit Withdraw(msg.sender, userData[msg.sender].userStaked);
        } else {
            // Early withdrawing with penalties
            _penaltyRate =
                25 +
                ((uint256(userData[msg.sender].userUnlockingTime) -
                    block.timestamp) * 50) /
                uint256(
                    userData[msg.sender].userUnlockingTime -
                        userData[msg.sender].stakedTimestamp
                );
            emit PunishedWithdraw(
                msg.sender,
                (userData[msg.sender].userStaked * _penaltyRate) / 100,
                (userData[msg.sender].userStaked * (100 - _penaltyRate)) /
                    100
            );
        }
        wTotalStaked -=
            uint256(userData[msg.sender].userWeights) *
            userData[msg.sender].userStaked;

        // Manages internal stake amounts
        _decrease(userData[msg.sender].userStaked, _penaltyRate);
    }

    /**
     * @notice Withdraws all staked position without penalties if emergency status is active
     * @dev Emergency status can be activated by owner
     */
    function emergencyWithdraw() external updateReward(msg.sender) {
        require(
            isEmergencyOpen,
            "[emergencyWithdraw] Not emergency status."
        );
        require(
            userData[msg.sender].userStaked > 0,
            "[emergencyWithdraw] No staked balance."
        );

        wTotalStaked -=
            uint256(userData[msg.sender].userWeights) *
            userData[msg.sender].userStaked;

        // Manages internal stake amounts
        _decrease(userData[msg.sender].userStaked, 0);
    }

    /**
     * @notice Claims actively distributing token rewards
     */
    function claimAllRewards() external claimOpen updateReward(msg.sender) {
        emit Claimed(msg.sender);
        // Iterates all active reward tokens
        for (uint256 i = 0; i < activeRewards.length(); i++) {
            uint256 _reward = tokenRewards[activeRewards.at(i)][msg.sender];
            if (_reward > 0) {
                if (i == 0) {
                    require(
                        (tokenList[0].tokenInstance.balanceOf(address(this)) -
                            _reward) >= totalStaked,
                        "[claimAllRewards] No claimable balance."
                    );
                }
                tokenRewards[activeRewards.at(i)][msg.sender] = 0;
                tokenList[activeRewards.at(i)].tokenInstance.safeTransfer(
                    msg.sender,
                    _reward
                );
            }
        }
    }

    /**
     * @notice Claims specified token rewards
     * @dev The tokens removed from actively distributing list can only be claimed by this funciton
     * @param _id uint256 - reward token id
     */
    function claimSingleReward(uint256 _id) external updateReward(msg.sender) {
        require(
            activeRewards.contains(_id),
            "[claimSingleReward] Not an active reward."
        );
        uint256 _reward = tokenRewards[_id][msg.sender];
        emit Claimed(msg.sender);
        if (_reward > 0) {
            if (_id == 0) {
                require(
                    (tokenList[0].tokenInstance.balanceOf(address(this)) -
                        _reward) >= totalStaked,
                    "[claimSingleReward] No claimable balance."
                );
            }
            tokenRewards[_id][msg.sender] = 0;
            tokenList[_id].tokenInstance.safeTransfer(msg.sender, _reward);
        }
    }

    /**
     * @notice New reward token round can be created by owner
     * @param _tokenAddress address - Address of the reward token
     * @param _rewardRate uint256 - Tokens distribution rate per second
     * @param _deadline uint256 - Tokens last distribution timestamp
     * @param _decimals uint8 - Tokens decimal count
     */
    function addNewRewardToken(
        address _tokenAddress,
        uint256 _rewardRate,
        uint256 _deadline,
        uint8 _decimals
    ) external onlyOwner updateReward(address(0)) {
        require(
            _tokenAddress != address(0),
            "[addNewRewardToken] Address failure."
        );

        // Creating reward token data
        TokenInfo memory info = TokenInfo(
            IERC20(_tokenAddress),
            _rewardRate,
            0,
            _deadline,
            _decimals
        );

        tokenList.push(info);
        require(activeRewards.add(tokenList.length - 1));

        emit NewReward(_tokenAddress, tokenList.length - 1);
    }

    /**
     * @notice Removes reward token from the actively distributing list
     * @dev Can only be called after the distribution deadline is over
     * @dev After this removal, the tokens can not be claimed by [claimAllRewards]
     * @param _id uint256 - reward token id
     */
    function delistRewardToken(uint256 _id)
        external
        onlyOwner
        updateReward(address(0))
    {
        require(
            tokenList[_id].deadline < block.timestamp,
            "[delistRewardToken] Distr time has not over."
        );
        require(_id != 0, "[delistRewardToken] Can not delist main token.");
        require(
            activeRewards.remove(_id),
            "[delistRewardToken] Delisting unsuccessful"
        );
    }

    /**
     * @notice Sets emergency status
     * @dev Only owners can deposit rewards
     * @dev The depositing token need to be approved to the contract by the user
     * @param _id uint256 - Reward token id
     * @param _amount uint256 - Depositing reward token amount
     */
    function depositRewardTokens(uint256 _id, uint256 _amount)
        external
        onlyOwner
    {
        require(
            activeRewards.contains(_id),
            "[depositRewardTokens] Not active reward distr."
        );

        tokenList[_id].tokenInstance.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    /**
     * @notice Allows owner to claim all tokens in stuck
     * @notice The tokens staked by users can not be withdrawn
     * @notice It only will be used for the tokens for completed claim periods
     * @param _tokenAddress address - Address of the reward token
     * @param _amount uint256 - Withdrawing token amount
     */
    function withdrawStuckTokens(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
    {
        if (_tokenAddress == address(tokenList[0].tokenInstance)) {
            require(
                (tokenList[0].tokenInstance.balanceOf(address(this)) -
                    _amount) >= totalStaked,
                "[withdrawStuckTokens] Users stakings can not be withdrawn."
            );
        }
        IERC20(_tokenAddress).safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Stops staking by owner authorizaton
     */
    function changeStakeStatus() external onlyOwner {
        isStakeOpen = !isStakeOpen;
        emit StakeStatusChanged(isStakeOpen);
    }

    /**
     * @notice Stops staking by owner authorizaton
     */
    function changeClaimStatus() external onlyOwner {
        isClaimOpen = !isClaimOpen;
        emit ClaimStatusChanged(isClaimOpen);
    }

    /**
     * @notice Activates emergency status
     * @dev Allows users to withdraw all staked tokens wo penalties
     */
    function changeEmergencyStatus() external onlyOwner {
        isEmergencyOpen = !isEmergencyOpen;

        for (uint256 i = 0; i < activeRewards.length(); i++) {
            changeDeadline(activeRewards.at(i), block.timestamp);
        }

        emit EmergencyStatusChanged(isEmergencyOpen);
    }

    /**
     * @notice Changes the lock limit
     * @param _lockLimit uint256 - New lock limit timestamp
     */
    function setLockLimit(uint256 _lockLimit) external onlyOwner {
        lockLimit = _lockLimit;
        emit LockLimitChanged(_lockLimit);
    }

    /**
     * @notice Sets the penalty address
     * @param _newAddress address - Destination address of penalty tokens
     */
    function changePenaltyAddress(address _newAddress) external onlyOwner {
        require(
            _newAddress != address(0),
            "[changePenaltyAddress] Address failure."
        );
        penaltyAddress = _newAddress;
    }

    /**
     * @notice Calculates the APR of main token staking
     * @param _weight uint256 - User weight to observe APR
     * @dev Min-Max APR can be showed by giving [1000, 2000] as param
     */
    function calcMainAPR(uint256 _weight) external view returns (uint256) {
        return
            (tokenList[0].rewardRate * 31_556_926 * _weight * 1000) /
            wTotalStaked;
    }

    /**
     * @notice Allows owner to change the distribution deadline of the tokens
     * @param _id uint256 - Reward token id
     * @param _time uint256 - New deadline timestamp
     * @dev The deadline can only be set to a future timestamp or 0 for unlimited deadline
     * @dev If the distribution is over, it can not be advanced
     */
    function changeDeadline(uint256 _id, uint256 _time)
        public
        updateReward(address(0))
        onlyOwner
    {
        require(
            _time >= block.timestamp || _time == 0,
            "Inappropriate timestamp."
        );
        require(
            tokenList[_id].deadline > block.timestamp,
            "The distribution has over."
        );
        tokenList[_id].deadline = _time;
    }

    // This function returns staking coefficient in the base of 100 (equals 1 coefficient)
    /**
     * @notice Calculates user staking coefficient (weight) due to staking time
     * @param _time uint256 - Staking time in seconds
     * @dev The coefficient is calculated by the formula: [coefficient = (day-90)^2 / 275^2 + 1]
     * @dev The coefficient is returned by 1000 base (1000 for 1 .... 2000 for 2)
     */
    function calcWeight(uint256 _time) public pure returns (uint16) {
        uint256 _stakingDays = _time / 1 days;
        if (_stakingDays <= 90) {
            return 1000;
        } else if (_stakingDays >= 365) {
            return 2000;
        } else {
            return uint16(((1000 * (_stakingDays - 90)**2) / 75625) + 1000);
        }
    }

    /**
     * @notice Calculates users weighted stakin amounts
     * @param _user address - Stakers address
     */
    function calcWeightedStake(address _user) public view returns (uint256) {
        return (userData[_user].userWeights * userData[_user].userStaked);
    }

    /**
     * @notice Staking helper function
     * @param _rewardTokenIndex uint256 - Reward tokens id
     */
    function rewardPerToken(uint256 _rewardTokenIndex)
        public
        view
        returns (uint256)
    {
        if (wTotalStaked == 0) return 0;

        uint256 deadline = tokenList[_rewardTokenIndex].deadline;

        if (deadline == 0 || block.timestamp < deadline) {
            deadline = block.timestamp;
        }

        uint256 time;
        (deadline > lastUpdateTime)
            ? time = deadline - lastUpdateTime
            : time = 0;

        return
            tokenList[_rewardTokenIndex].rewardPerTokenStored +
            ((time *
                tokenList[_rewardTokenIndex].rewardRate *
                10**tokenList[_rewardTokenIndex].decimals) / wTotalStaked);
    }

    /**
     * @notice Staking helper function
     * @param _user address - Stakers address
     * @param _rewardTokenIndex uint256 - Reward tokens id
     */
    function earned(address _user, uint256 _rewardTokenIndex)
        public
        view
        returns (uint256)
    {
        if (rewardPerToken(_rewardTokenIndex) == 0)
            return tokenRewards[_rewardTokenIndex][_user];
        return
            ((calcWeightedStake(_user) *
                (rewardPerToken(_rewardTokenIndex) -
                    userRewardsPerTokenPaid[_rewardTokenIndex][_user])) /
                10**tokenList[_rewardTokenIndex].decimals) +
            tokenRewards[_rewardTokenIndex][_user];
    }

    // Increses staking positions of the users - actually "stake" function of general contracts
    /**
     * @notice Internally manages stake positions of the users - deposits actual token amounts
     * @param _amount address - Deposited token amount
     */
    function _increase(uint256 _amount) private {
        totalStaked += _amount;
        userData[msg.sender].userStaked += _amount;
        tokenList[0].tokenInstance.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    // Decreases staking positions of the users - actually "unstake/withdraw" function of general contracts
    /**
     * @notice Internally manages stake positions of the users - withdraws actual token amounts
     * @param _amount address - Withdrawed token amount
     * @param _penaltyRate uint256 - Percentage penalty rate to be cutted
     */
    function _decrease(uint256 _amount, uint256 _penaltyRate) private {
        if (userData[msg.sender].userStaked == _amount) {
            // If all balance is withdrawn, then the user data is removed
            delete (userData[msg.sender]);
        } else {
            userData[msg.sender].userStaked -= _amount;
        }
        totalStaked -= _amount;

        // User's early withdraw penalty is cutted
        if (_penaltyRate > 0) {
            uint256 _penalty = (_amount * _penaltyRate) / 100;
            _amount = _amount - _penalty;
            tokenList[0].tokenInstance.safeTransfer(
                penaltyAddress,
                _penalty
            );
        }
        tokenList[0].tokenInstance.safeTransfer(msg.sender, _amount);
    }

    /////////// Modifiers ///////////

    /**
     * @notice Updates staking positions
     * @param _user address - Staker address
     * @dev If the function is called by non-staker, {_user} can be setted to [address(0)]
     */
    modifier updateReward(address _user) {
        // Iterates all active reward tokens
        for (uint256 i = 0; i < activeRewards.length(); i++) {
            uint256 _lastUpdateTime = lastUpdateTime;
            tokenList[activeRewards.at(i)]
                .rewardPerTokenStored = rewardPerToken(activeRewards.at(i));
            lastUpdateTime = block.timestamp;

            if (_user != address(0)) {
                tokenRewards[activeRewards.at(i)][_user] = earned(
                    _user,
                    activeRewards.at(i)
                );
                userRewardsPerTokenPaid[activeRewards.at(i)][_user] = tokenList[
                    activeRewards.at(i)
                ].rewardPerTokenStored;
            }
            if (i != activeRewards.length() - 1)
                lastUpdateTime = _lastUpdateTime;
        }
        _;
    }

    /**
     * @notice Closes token initial and later token staking
     */
    modifier stakeOpen() {
        require(isStakeOpen, "Not an active staking period.");
        _;
    }

    /**
     * @notice Closes token claims
     */
    modifier claimOpen() {
        require(isClaimOpen, "Not an claiming period.");
        _;
    }
}