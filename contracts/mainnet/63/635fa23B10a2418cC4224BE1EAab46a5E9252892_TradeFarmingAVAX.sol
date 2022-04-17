/**
 *Submitted for verification at snowtrace.io on 2022-04-17
*/

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


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// File: contracts/interfaces/ITradeFarmingAVAX.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ITradeFarmingAVAX {
    
    /////////// Swap Functions ///////////

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory out);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory out);

    /////////// Reward Functions ///////////

    function claimAllRewards() external;
}

// File: contracts/interfaces/IPangolinRouter.sol

pragma solidity >=0.6.2;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

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
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
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
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
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
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: contracts/trade-farming/TradeFarmingAVAX.sol

pragma solidity ^0.8.2;






/// @author Ulaş Erdoğan
/// @title Trade Farming Contract for any ETH - Token Pool
/// @dev Can be integrated to any EVM - Uniswap V2 fork DEX' native coin - token pair
/// @dev Integradted version for Avalanche - Pangolin Pools
contract TradeFarmingAVAX is ITradeFarmingAVAX, Ownable {
    /////////// Interfaces & Libraries ///////////

    // DEX router interface
    IPangolinRouter routerContract;
    // Token of pair interface
    IERC20 tokenContract;
    // Rewarding token interface
    IERC20 rewardToken;

    // Using OpenZeppelin's EnumerableSet Util
    using EnumerableSet for EnumerableSet.UintSet;
    // Using OpenZeppelin's SafeERC20 Util
    using SafeERC20 for IERC20;

    /////////// Type Declarations ///////////

    // Track of days' previous volume average
    /// @dev It's the average of previous days and [0, specified day)
    // uint256 day - any day of competition -> uint256 volume - average volume
    mapping(uint256 => uint256) public previousVolumes;
    // Users daily volume records
    // address user -> uint256 day -> uint256 volume
    mapping(address => mapping(uint256 => uint256)) public volumeRecords;
    // Daily total volumes
    // uint256 day -> uint256 volume
    mapping(uint256 => uint256) public dailyVolumes;
    // Daily calculated total rewards
    mapping(uint256 => uint256) public dailyRewards;
    // Users unclaimed traded days
    // address user -> uint256[] days
    mapping(address => EnumerableSet.UintSet) private tradedDays;

    /////////// State Variables ///////////

    // Undistributed total rewards
    uint256 public totalRewardBalance = 0;
    // Total days of the competition
    uint256 public totalDays;

    // Considered previous volume of the pair
    uint256 private previousDay;
    // Last calculation time of the competition
    uint256 public lastAddedDay;
    // Deploying time of the competition
    uint256 public immutable deployTime;
    // Address of WAVAX token
    address private WAVAX;

    // Precision of reward calculations
    uint256 constant PRECISION = 1e18;
    // Limiting the daily volume changes between 90% - 110%
    uint256 immutable UP_VOLUME_CHANGE_LIMIT;
    uint256 immutable DOWN_VOLUME_CHANGE_LIMIT;

    /////////// Events ///////////

    // The event will be emitted when a user claims reward
    event RewardClaimed(address _user, uint256 _amount);

    /////////// Functions ///////////

    /**
     * @notice Constructor function - takes the parameters of the competition
     * @dev May need to be configurated for different chains
     * @dev Give parameters for up&down limits in base of 100. for exp: 110 for %10 up limit, 90 for %10 down limit
     * @param _routerAddress IUniswapV2Router01 - address of the DEX router contract
     * @param _tokenAddress IERC20 - address of the token of the pair
     * @param _rewardAddress IERC20 - address of the reward token
     * @param _previousVolume uint256 - average of previous days
     * @param _previousDay uint256 - previous considered days
     * @param _totalDays uint256 - total days of the competition
     * @param _upLimit uint256 - setter to up volume change limit
     * @param _downLimit uint256 - setter to down volume change limit
     */
    constructor(
        address _routerAddress,
        address _tokenAddress,
        address _rewardAddress,
        uint256 _previousVolume,
        uint256 _previousDay,
        uint256 _totalDays,
        uint256 _upLimit,
        uint256 _downLimit
    ) {
        require(
            _routerAddress != address(0) && _tokenAddress != address(0) && _rewardAddress != address(0),
            "[] Addresses can not be 0 address."
        );

        deployTime = block.timestamp;
        routerContract = IPangolinRouter(_routerAddress);
        tokenContract = IERC20(_tokenAddress);
        rewardToken = IERC20(_rewardAddress);
        previousVolumes[0] = _previousVolume;
        previousDay = _previousDay;
        totalDays = _totalDays;
        WAVAX = routerContract.WAVAX();
        UP_VOLUME_CHANGE_LIMIT = (PRECISION * _upLimit) / 100;
        DOWN_VOLUME_CHANGE_LIMIT = (PRECISION * _downLimit) / 100;
    }

    /////////// Contract Management Functions ///////////

    /**
     * @notice Increase the reward amount of the competition by Owner
     * @dev The token need to be approved to the contract by Owner
     * @param amount uint256 - amount of the reward token to be added
     */
    function depositRewardTokens(uint256 amount) external onlyOwner {
        totalRewardBalance += amount;
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Decrease and claim the "undistributed" reward amount of the competition by Owner
     * @param amount uint256 - amount of the reward token to be added
     */
    function withdrawRewardTokens(uint256 amount) external onlyOwner {
        require(
            totalRewardBalance >= amount,
            "[withdrawRewardTokens] Not enough balance!"
        );
        totalRewardBalance -= amount;
        rewardToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Change the total time of the competition
     * @param newTotalDays uint256 - new time of the competition
     */
    function changeTotalDays(uint256 newTotalDays) external onlyOwner {
        totalDays = newTotalDays;
    }

    /////////// Reward Viewing and Claiming Functions ///////////

    /**
     * @notice Claim the calculated rewards of the previous days
     * @notice The rewards until the current day can be claimed
     */
    function claimAllRewards() external virtual override {
        // Firstly calculates uncalculated days rewards if there are
        if (lastAddedDay + 1 <= calcDay() && lastAddedDay != totalDays) {
            addNextDaysToAverage();
        }

        uint256 totalRewardOfUser = 0;
        uint256 rewardRate = PRECISION;

        uint256 len = tradedDays[msg.sender].length();
        if(tradedDays[msg.sender].contains(lastAddedDay)) len -= 1;
        // Keep the claimed days to remove from the traded days set
        uint256[] memory _removeDays = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            if (tradedDays[msg.sender].at(i) < lastAddedDay) {
                // Calulates how much of the daily rewards the user can claim
                rewardRate = muldiv(
                    volumeRecords[msg.sender][tradedDays[msg.sender].at(i)],
                    PRECISION,
                    dailyVolumes[tradedDays[msg.sender].at(i)]
                );
                // Adds the daily progress payment to total rewards
                totalRewardOfUser += muldiv(
                    rewardRate,
                    dailyRewards[tradedDays[msg.sender].at(i)],
                    PRECISION
                );
                _removeDays[i] = tradedDays[msg.sender].at(i);
            }
        }

        // Remove the claimed days from the set
        for (uint256 i = 0; i < len; i++) {
            require(tradedDays[msg.sender].remove(_removeDays[i]), "[claimAllRewards] Unsuccessfull set operation");
        }

        require(totalRewardOfUser > 0, "[claimAllRewards] No reward!");
        rewardToken.safeTransfer(msg.sender, totalRewardOfUser);

        // User claimed rewards
        emit RewardClaimed(msg.sender, totalRewardOfUser);
    }

    /**
     * @notice Checks if the previous days rewards have been calculated
     * @dev If it is false there might be some rewards that can be claimedu unseen
     * @return bool - true if the previous days rewards have been calculated
     */
    function isCalculated() external view returns (bool) {
        return (!(lastAddedDay + 1 <= calcDay() && lastAddedDay != totalDays) ||
            lastAddedDay == totalDays);
    }

    /**
     * @notice Calculates the calculated rewards of the users
     * @dev If isCalculated function returns false, it might be bigger than the return of this function
     * @return uint256 - total reward of the user
     */
    function calculateUserRewards() external view returns (uint256) {
        uint256 totalRewardOfUser = 0;
        uint256 rewardRate = PRECISION;
        for (uint256 i = 0; i < tradedDays[msg.sender].length(); i++) {
            if (tradedDays[msg.sender].at(i) < lastAddedDay) {
                rewardRate = muldiv(
                    volumeRecords[msg.sender][tradedDays[msg.sender].at(i)],
                    PRECISION,
                    dailyVolumes[tradedDays[msg.sender].at(i)]
                );
                totalRewardOfUser += muldiv(
                    rewardRate,
                    dailyRewards[tradedDays[msg.sender].at(i)],
                    PRECISION
                );
            }
        }
        return totalRewardOfUser;
    }

    /**
     * @notice Calculates the daily reward of an user if its calculated
     * @param day uint256 - speciifed day of the competition
     * @dev It returns 0 if the day is not calculated or its on the future
     * @return uint256 - specified days daily reward of the user
     */
    function calculateDailyUserReward(uint256 day)
        external
        view
        returns (uint256)
    {
        uint256 rewardOfUser = 0;
        uint256 rewardRate = PRECISION;

        if (tradedDays[msg.sender].contains(day)) {
            rewardRate = muldiv(
                volumeRecords[msg.sender][day],
                PRECISION,
                dailyVolumes[day]
            );
            uint256 dailyReward;
            if (day < lastAddedDay) {
                dailyReward = dailyRewards[day];
            } else if (day == lastAddedDay) {
                uint256 volumeChange = calculateDayVolumeChange(lastAddedDay);
                if (volumeChange > UP_VOLUME_CHANGE_LIMIT) {
                    volumeChange = UP_VOLUME_CHANGE_LIMIT;
                } else if (volumeChange == 0) {
                    volumeChange = 0;
                } else if (volumeChange < DOWN_VOLUME_CHANGE_LIMIT) {
                    volumeChange = DOWN_VOLUME_CHANGE_LIMIT;
                }
                dailyReward = muldiv(
                    totalRewardBalance / (totalDays - lastAddedDay),
                    volumeChange,
                    PRECISION
                );
            }
            rewardOfUser += muldiv(rewardRate, dailyReward, PRECISION);
        }

        return rewardOfUser;
    }

    /////////// UI Helper Functions ///////////

    /**
     @dev Interacts with the router contract and allows reading in-out values without connecting to the router
     @dev @param @return See the details at: https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-01#getamountsout
     */
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts)
    {
        return routerContract.getAmountsOut(amountIn, path);
    }

    /**
     @dev Interacts with the router contract and allows reading in-out values without connecting to the router
     @dev @param @return See the details at: https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-01#getamountsin
     */
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts)
    {
        return routerContract.getAmountsIn(amountOut, path);
    }

    /////////// Swap Functions ///////////

    /**
     * @notice Swaps the specified amount of AVAX for some tokens by connecting to the DEX Router and records the trade volumes
     * @dev Exact amount of the value has to be sended as "value"
     * @dev @param @return Takes and returns the same parameters and values with router functions. 
                           See at: https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-01#swapexactethfortokens
     */
    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override returns (uint256[] memory out) {
        // Checking the pairs path
        require(path[0] == WAVAX, "[swapExactAVAXForTokens] Invalid path!");
        require(
            path[path.length - 1] == address(tokenContract),
            "[swapExactAVAXForTokens] Invalid path!"
        );
        // Checking exact swapping value
        require(msg.value > 0, "[swapExactAVAXForTokens] Not a msg.value!");

        // Add the current day if not exists on the traded days set
        if (
            !tradedDays[msg.sender].contains(calcDay()) && calcDay() < totalDays
        ) require(tradedDays[msg.sender].add(calcDay()), "[swapExactAVAXForTokens] Unsuccessfull set operation");

        // Interacting with the router contract and returning the in-out values
        out = routerContract.swapExactAVAXForTokens{value: msg.value}(
            amountOutMin,
            path,
            to,
            deadline
        );
        //Recording the volumes if the competition is not finished
        if (lastAddedDay != totalDays) tradeRecorder(out[out.length - 1]);
    }

    /**
     * @notice Swaps some amount of AVAX for specified amounts of tokens by connecting to the DEX Router and 
               records the trade volumes
     * @dev Equal or bigger amount of value -to be protected from slippage- has to be sended as "value", 
            unused part of the value will be returned.
     * @dev @param @return Takes and returns the same parameters and values with router functions. 
                           See at: https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-01#swapethforexacttokens
     */
    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override returns (uint256[] memory) {
        // Checking the pairs path
        require(path[0] == WAVAX, "[swapExactAVAXForTokens] Invalid path!");
        require(
            path[path.length - 1] == address(tokenContract),
            "[swapExactAVAXForTokens] Invalid path!"
        );

        // Calculating the exact AVAX input value
        uint256 volume = routerContract.getAmountsIn(amountOut, path)[0];
        require(
            msg.value >= volume,
            "[swapAVAXForExactTokens] Not enough msg.value!"
        );

        // Add the current day if not exists on the traded days set
        if (
            !tradedDays[msg.sender].contains(calcDay()) && calcDay() < totalDays
        ) require(tradedDays[msg.sender].add(calcDay()), "[swapAVAXForExactTokens] Unsuccessfull set operation");

        //Recording the volumes if the competition is not finished
        if (lastAddedDay != totalDays) tradeRecorder(amountOut);
        // Refunding the over-value
        if (msg.value > volume)
            payable(msg.sender).transfer(msg.value - volume);
        // Interacting with the router contract and returning the in-out values
        return
            routerContract.swapAVAXForExactTokens{value: volume}(
                amountOut,
                path,
                to,
                deadline
            );
    }

    /**
     * @notice Swaps the specified amount of tokens for some AVAX by connecting to the DEX Router and records the trade volumes
     * @dev The token in the pair need to be approved to the contract by the users
     * @dev @param @return Takes and returns the same parameters and values with router functions. 
                           See at: https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-01#swapexacttokensforeth
     */
    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override returns (uint256[] memory) {
        // Checking the pairs path
        require(
            path[path.length - 1] == WAVAX,
            "[swapExactAVAXForTokens] Invalid path!"
        );
        require(
            path[0] == address(tokenContract),
            "[swapExactAVAXForTokens] Invalid path!"
        );

        // Add the current day if not exists on the traded days set
        if (
            !tradedDays[msg.sender].contains(calcDay()) && calcDay() < totalDays
        ) require(tradedDays[msg.sender].add(calcDay()), "[swapExactTokensForAVAX] Unsuccessfull set operation");
        tokenContract.safeTransferFrom(msg.sender, address(this), amountIn);

        // Approve the pair token to the router
        tokenContract.safeIncreaseAllowance(address(routerContract), amountIn);

        //Recording the volumes if the competition is not finished
        if (lastAddedDay != totalDays) tradeRecorder(amountIn);
        // Interacting with the router contract and returning the in-out values
        return
            routerContract.swapExactTokensForAVAX(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    /**
     * @notice Swaps some amount of tokens for specified amounts of AVAX by connecting to the DEX Router
               and records the trade volumes
     * @dev The token in the pair need to be approved to the contract by the users
     * @dev @param @return Takes and returns the same parameters and values with router functions. 
                           See at: https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-01#swaptokensforexacteth
     */
    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override returns (uint256[] memory out) {
        // Checking the pairs path
        require(
            path[path.length - 1] == WAVAX,
            "[swapExactAVAXForTokens] Invalid path!"
        );
        require(
            path[0] == address(tokenContract),
            "[swapExactAVAXForTokens] Invalid path!"
        );

        // Add the current day if not exists on the traded days set
        if (
            !tradedDays[msg.sender].contains(calcDay()) && calcDay() < totalDays
        ) require(tradedDays[msg.sender].add(calcDay()), "[swapTokensForExactAVAX] Unsuccessfull set operation");
        tokenContract.safeTransferFrom(
            msg.sender,
            address(this),
            routerContract.getAmountsIn(amountOut, path)[0]
        );

        // Approve the pair token to the router
        tokenContract.safeIncreaseAllowance(
            address(routerContract),
            amountInMax
        );

        // Interacting with the router contract and returning the in-out values
        out = routerContract.swapTokensForExactAVAX(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
        //Recording the volumes if the competition is not finished
        if (lastAddedDay != totalDays) tradeRecorder(out[0]);

        // Resetting the approval amount the pair token to the router
        tokenContract.safeApprove(address(routerContract), 0);
    }

    /////////// Get Public Data ///////////

    /**
     * @notice Get the current day of the competition
     * @return uint256 - current day of the competition
     */
    function calcDay() public view returns (uint256) {
        return (block.timestamp - deployTime) / (1 days);
    }

    /////////// Volume Calculation Functions ///////////

    /**
     * @notice Records the trade volumes if the competition is not finished.
     * @notice If there are untraded or uncalculated days until the current days, calculate these days
     * @param volume uint256 - the volume of the trade
     */
    function tradeRecorder(uint256 volume) private {
        // Record the volume if the competition is not finished
        if (calcDay() < totalDays) {
            volumeRecords[msg.sender][calcDay()] += volume;
            dailyVolumes[calcDay()] += volume;
        }

        // Calculate the untraded or uncalculated days until the current day
        if (lastAddedDay + 1 <= calcDay() && lastAddedDay != totalDays) {
            addNextDaysToAverage();
        }
    }

    /**
     * @notice Calculates the average volume change of the specified day from the previous days
     * @param day uin256 - day to calculate the average volume change
     * @return uint256 - average volume change of the specified day over PRECISION
     * @dev Returns PRECISION +- (changed value)
     */
    function calculateDayVolumeChange(uint256 day)
        private
        view
        returns (uint256)
    {
        return muldiv(dailyVolumes[day], PRECISION, previousVolumes[day]);
    }

    /**
     * @notice Calculates the rewards for the untraded or uncalculated days until the current day
     */
    function addNextDaysToAverage() private {
        uint256 _cd = calcDay();
        // Previous day count of the calculating day
        uint256 _pd = previousDay + lastAddedDay + 1;
        assert(lastAddedDay + 1 <= _cd);
        // Recording the average of previous days and [0, _cd)
        previousVolumes[lastAddedDay + 1] =
            muldiv(previousVolumes[lastAddedDay], (_pd - 1), _pd) +
            dailyVolumes[lastAddedDay] /
            _pd;

        uint256 volumeChange = calculateDayVolumeChange(lastAddedDay);
        // Limiting the volume change between 90% - 110%
        if (volumeChange > UP_VOLUME_CHANGE_LIMIT) {
            volumeChange = UP_VOLUME_CHANGE_LIMIT;
        } else if (volumeChange == 0) {
            volumeChange = 0;
        } else if (volumeChange < DOWN_VOLUME_CHANGE_LIMIT) {
            volumeChange = DOWN_VOLUME_CHANGE_LIMIT;
        }

        // Calculating the daily rewards to be distributed - set to the remaining balance if there are an overflow for the last day
        if (lastAddedDay == totalDays - 1 && volumeChange > PRECISION) {
            dailyRewards[lastAddedDay] = totalRewardBalance;
        } else {
            dailyRewards[lastAddedDay] = muldiv(
                (totalRewardBalance / (totalDays - lastAddedDay)),
                volumeChange,
                PRECISION
            );
        }
        totalRewardBalance = totalRewardBalance - dailyRewards[lastAddedDay];

        // Moving up the calculated days
        lastAddedDay += 1;

        // Continue to calculating if still there are uncalculated or untraded days
        if (lastAddedDay + 1 <= _cd && lastAddedDay != totalDays)
            addNextDaysToAverage();
    }

    /**
     * @notice Used in the functions which have the risks of overflow on a * b / c situation
     * @notice Kindly thanks to Remco Bloemen for this muldiv function
     * @dev See the function details at: https://2π.com/21/muldiv/
     * @param a, @param b uint256 - the multipliying values
     * @param denominator uint256 - the divisor value
     */
    function muldiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) private pure returns (uint256 result) {
        require(denominator > 0);

        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }
        require(prod1 < denominator);
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        uint256 twos = denominator & (~denominator + 1);
        assembly {
            denominator := div(denominator, twos)
        }

        assembly {
            prod0 := div(prod0, twos)
        }

        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        uint256 inv = (3 * denominator) ^ 2;

        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;

        result = prod0 * inv;
        return result;
    }
}