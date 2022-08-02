// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

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

library EnumerableSet {
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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function metadata(uint256 tokenId) external view returns (address creator);
}

contract PaymentToken is Ownable {
    event PaymentTokenNew(address indexed token);
    event PaymentTokenCancel(address indexed token);
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet internal _paymentTokenAddressSet;

    string internal constant REVERT_PAYMENT_ALREADY_ACCEPTED = "Payment: Token already accepted";
    string internal constant REVERT_PAYMENT_NOT_ACCEPTED = "Payment: Token not accepted";

    function _acceptPaymentToken(address _token) internal {
        _paymentTokenAddressSet.add(_token);
        emit PaymentTokenNew(_token);
    }

    function _cancelPaymentToken(address _token) internal {
        _paymentTokenAddressSet.remove(_token);
        emit PaymentTokenCancel(_token);
    }

    function acceptPaymentToken(address _token) external onlyOwner {
        require(!_paymentTokenAddressSet.contains(_token), REVERT_PAYMENT_ALREADY_ACCEPTED);
        _acceptPaymentToken(_token);
    }

    function cancelPaymentToken(address _token) external onlyOwner {
        require(_paymentTokenAddressSet.contains(_token), REVERT_PAYMENT_NOT_ACCEPTED);
        _cancelPaymentToken(_token);
    }

    function acceptedToken(address _token) public view returns(bool) {
        return _paymentTokenAddressSet.contains(_token);
    }

    function viewPaymenTokens(uint256 cursor, uint256 size) external view returns (address[] memory paymentTokenAddresses, uint256) {
        uint256 length = size;   
        if (length > _paymentTokenAddressSet.length() - cursor) length = _paymentTokenAddressSet.length() - cursor;
        for (uint256 i = 0; i < length; i++) {
            paymentTokenAddresses[i] = _paymentTokenAddressSet.at(cursor + i);
        }
        return (paymentTokenAddresses, cursor + length);
    }
}

contract CollectionToken is Ownable {
    event AddCollection(address indexed collection, uint256 businessFee, uint256 creatorFee);
    event UpdateCollection(address indexed collection, uint256 businessFee, uint256 creatorFee);
    event CloseCollection(address indexed collection);
    
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    struct Collection {
        uint256 businessFee; 
        uint256 creatorFee;
    }

    EnumerableSet.AddressSet private _collectionAddressSet;
    mapping(address => Collection) private _collections; 

    uint256 public constant TOTAL_MAX_FEE = 10000; // 100%
    string internal constant REVERT_COLLECTION_ALREADY_LISTED = "Collection: already listed";
    string internal constant REVERT_COLLECTION_NOT_LISTED = "Collection: not listed";
    string internal constant REVERT_NOT_ERC721 = "Operations: Not ERC721";
    string internal constant REVERT_EXCEED_MAX_FEE = "Fee: Sum of fee must inferior to TOTAL_MAX_FEE";
    

    function addCollection(
        address _collection,
        uint256 _businessFee,
        uint256 _creatorFee
    ) external onlyOwner {
        require(!_collectionAddressSet.contains(_collection), REVERT_COLLECTION_ALREADY_LISTED);
        require(IERC721(_collection).supportsInterface(0x80ac58cd), REVERT_NOT_ERC721);
        require(_businessFee.add(_creatorFee) <= TOTAL_MAX_FEE, REVERT_EXCEED_MAX_FEE);
        _collectionAddressSet.add(_collection);
        _collections[_collection] = Collection({
            businessFee: _businessFee, 
            creatorFee: _creatorFee
        });
        emit AddCollection(_collection, _businessFee, _creatorFee);
    }

    function modifyCollection(
        address _collection,
        uint256 _businessFee,
        uint256 _creatorFee
    ) external onlyOwner {
        require(_collectionAddressSet.contains(_collection), REVERT_COLLECTION_NOT_LISTED);
        require(_businessFee.add(_creatorFee) <= TOTAL_MAX_FEE, REVERT_EXCEED_MAX_FEE);
        _collections[_collection] = Collection({
            businessFee: _businessFee,
            creatorFee: _creatorFee
        });
        emit UpdateCollection(_collection, _businessFee, _creatorFee);
    }

    function closeCollection(address _collection) external onlyOwner {
        require(_collectionAddressSet.contains(_collection), REVERT_COLLECTION_NOT_LISTED);
        _collectionAddressSet.remove(_collection);
        emit CloseCollection(_collection);
    }

    function containCollection(address _collection) public view returns(bool) {
        return _collectionAddressSet.contains(_collection);
    }

    function viewCollections(uint256 cursor, uint256 size) external view returns (address[] memory collectionAddresses, Collection[] memory collectionDetails, uint256) {
        uint256 length = size;
        if (length > _collectionAddressSet.length() - cursor) length = _collectionAddressSet.length() - cursor;

        collectionAddresses = new address[](length);
        collectionDetails = new Collection[](length);

        for (uint256 i = 0; i < length; i++) {
            collectionAddresses[i] = _collectionAddressSet.at(cursor + i);
            collectionDetails[i] = _collections[collectionAddresses[i]];
        }
        return (collectionAddresses, collectionDetails, cursor + length);
    }

    function canTokensBeListed(address _collection, uint256[] calldata _tokenIds) external view returns (bool) {
        if (!_collectionAddressSet.contains(_collection)) return false;         
        return _canTokenBeListed(_collection, _tokenIds);
    }

    function _canTokenBeListed(address _collection, uint256[] memory _tokenIds) internal view returns (bool) {
        uint256 length = _tokenIds.length;
        IERC721 collection = IERC721(_collection);

        for (uint256 i = 0; i < length; i++) {
            if (collection.ownerOf(_tokenIds[i]) != msg.sender) {
                return false;
            }
        }
        return true;
    }
    
    function calculatePriceAndFeesForCollection(address collection, uint256 price) external view returns (uint256 netPrice, uint256 businessFee, uint256 creatorFee) {
        if (!_collectionAddressSet.contains(collection)) return (0, 0, 0);
        return (_calculatePriceAndFeesForCollection(collection, price));
    }

    function _calculatePriceAndFeesForCollection(address _collection, uint256 _price) internal view returns (uint256 netPrice, uint256 businessFee, uint256 creatorFee) {
        businessFee = _price.mul(_collections[_collection].businessFee).div(TOTAL_MAX_FEE);
        creatorFee = _price.mul(_collections[_collection].creatorFee).div(TOTAL_MAX_FEE);
        netPrice = _price.sub(businessFee).sub(creatorFee);
        return (netPrice, businessFee, creatorFee);
    }
}

contract TokenRecover is Ownable {
    event TokenRecovery(address indexed token, uint256 amount);
    event NonFungibleTokenRecovery(address indexed token, uint256 indexed tokenId);

    using SafeERC20 for IERC20;

    string internal constant REVERT_TRANSFER_FAILED = "Operations: AVAX_TRANSFER_FAILED";

    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        address account = _msgSender();
        if (_token == address(0)) {
            (bool success, ) = account.call{value: _amount}(new bytes(0));
            require(success, REVERT_TRANSFER_FAILED);
        } else {
            IERC20(_token).safeTransfer(account, _amount);
        }
        emit TokenRecovery(_token, _amount);
    }

    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyOwner {
        IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
        emit NonFungibleTokenRecovery(_token, _tokenId);
    }
}

contract CeoAddress {
    event NewCeoAddress(address indexed ceo);

    address public ceoAddress;

    string private constant REVERT_NOT_A_CEO = "Management: Not a ceo address";
    string internal constant REVERT_NULL_ADDRESS = "Operations: Can not be address 0";

    modifier onlyCeo() {
        require(msg.sender == ceoAddress, REVERT_NOT_A_CEO);
        _;
    }

    function _setCeoAddress(address _ceoAddress) internal {
        ceoAddress = _ceoAddress;
        emit NewCeoAddress(_ceoAddress);
    }
    function setCeoAddress(address _ceoAddress) external onlyCeo {
        require(_ceoAddress != address(0), REVERT_NULL_ADDRESS);
        _setCeoAddress(_ceoAddress);
    }
}

contract NFTMarketplace is Ownable, PaymentToken, CollectionToken, TokenRecover, CeoAddress, ReentrancyGuard {
    event CreateOrder(address indexed collection, uint256 indexed orderId, address seller, uint256[] tokenIds, address paymentToken, uint256 price);
    event UpdateOrder(address indexed collection, uint256 indexed orderId, address seller, address paymentToken, uint256 price);
    event CancelOrder(address indexed collection, uint256 indexed orderId, address seller);
    event Buy(address indexed collection, uint256 indexed orderId, address seller, address buyer, address paymentToken, uint256 price, uint256 netPrice);

    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Order {
        address seller;
        uint256[] tokenIds;
        address paymentToken;
        uint256 price;
        address buyer;
    }

    mapping(address => mapping(address => EnumerableSet.UintSet)) private _orderIdsOfSellerForCollection; 
    mapping(address => EnumerableSet.UintSet) private _orderIds; 
    mapping(address => mapping(uint256 => Order)) private _orderDetails;
    
    string private constant REVERT_CONTRACT_NOT_ALLOWED = "Management: Contract not allowed";
    string private constant REVERT_NOT_A_OWNER_NFTS = "Management: Caller is not the owner of NFTs";
    string private constant REVERT_APPROVE_NFTS = "Rental: owner is not approve this NFT";
    string private constant REVERT_ORDER_LISTED = "Order: OrderId already listed";
    string private constant REVERT_ORDER_NOT_OWNER = "Order: Caller is not the owner of order";
    string private constant REVERT_ORDER_SOLD = "Order: Already sold";
    string private constant REVERT_ORDER_NOT_LISTED = "Order: not listed";
    string private constant REVERT_ORDER_NOT_HAVE_POSSESSION = "Order: not the owner of order or already not existed";
    string private constant REVERT_SELLER_CAN_NOT_BUY = "Buy: Buyer cannot be seller";
    string private constant REVERT_INSUFFICIENT_BALANCE = "Buy: Insufficient balance";
        
    modifier notContract() {
        require(!_isContract(msg.sender), REVERT_CONTRACT_NOT_ALLOWED);
        require(msg.sender == tx.origin, REVERT_CONTRACT_NOT_ALLOWED);
        _;
    }

    constructor(address _ceoAddress) {
        _setCeoAddress(_ceoAddress);
        _acceptPaymentToken(address(0));
    }

    function createOrder(
        address _collection,
        uint256 _orderId,
        uint256[] memory _tokenIds,
        address _paymentToken,
        uint256 _price
    ) external notContract nonReentrant {
        require(containCollection(_collection), REVERT_COLLECTION_NOT_LISTED);
        require(acceptedToken(_paymentToken), REVERT_PAYMENT_NOT_ACCEPTED);
        require(_canTokenBeListed(_collection, _tokenIds), REVERT_NOT_A_OWNER_NFTS);
        require(!_orderIds[_collection].contains(_orderId), REVERT_ORDER_LISTED);

        _orderIds[_collection].add(_orderId);
        _orderIdsOfSellerForCollection[msg.sender][_collection].add(_orderId);
        _orderDetails[_collection][_orderId] = Order({seller: msg.sender, tokenIds: _tokenIds, paymentToken: _paymentToken, price: _price, buyer: address(0)});

        emit CreateOrder(_collection, _orderId, msg.sender, _tokenIds, _paymentToken, _price);
    }

    function updateOrder(
        address _collection,
        uint256 _orderId,
        address _newPaymentToken,
        uint256 _newPrice
    ) external nonReentrant {
        require(acceptedToken(_newPaymentToken), REVERT_PAYMENT_NOT_ACCEPTED);
        require(_orderDetails[_collection][_orderId].seller == msg.sender, REVERT_ORDER_NOT_OWNER);
        require(_orderDetails[_collection][_orderId].buyer == address(0), REVERT_ORDER_SOLD);
        _orderDetails[_collection][_orderId].paymentToken = _newPaymentToken;
        _orderDetails[_collection][_orderId].price = _newPrice;
        emit UpdateOrder(_collection, _orderId, msg.sender, _newPaymentToken, _newPrice);
    }

    function cancelOrder(address _collection, uint256 _orderId) external nonReentrant {
        require(_orderIdsOfSellerForCollection[msg.sender][_collection].contains(_orderId), REVERT_ORDER_NOT_HAVE_POSSESSION);
        _orderIds[_collection].remove(_orderId);
        _orderIdsOfSellerForCollection[msg.sender][_collection].remove(_orderId);
        delete _orderDetails[_collection][_orderId];
        emit CancelOrder(_collection, _orderId, msg.sender);
    }

    function viewOrderDetail(address _collection, uint256 _orderId) external view returns(Order memory orderDetail) {
        return(_orderDetails[_collection][_orderId]);
    }

    function _buy(
        address _collection,
        uint256 _orderId
    ) internal {
        Order storage order = _orderDetails[_collection][_orderId];
        require(msg.sender != order.seller, REVERT_SELLER_CAN_NOT_BUY);
        require(order.price > 0, REVERT_ORDER_NOT_LISTED);
        require(order.buyer == address(0), REVERT_ORDER_SOLD);
        require(IERC721(_collection).isApprovedForAll(order.seller, address(this)), REVERT_APPROVE_NFTS);

        (uint256 netPrice, uint256 businessFee, uint256 creatorFee) = _calculatePriceAndFeesForCollection(_collection, order.price);

        _orderIdsOfSellerForCollection[order.seller][_collection].remove(_orderId);
        _orderIds[_collection].remove(_orderId);

        (address creator) = IERC721(_collection).metadata(order.tokenIds[0]);

        // transfer money first
        if (order.paymentToken == address(0)) {
            require(msg.value >= order.price, REVERT_INSUFFICIENT_BALANCE);
            payable(order.seller).transfer(netPrice);
            if (businessFee != 0) payable(ceoAddress).transfer(businessFee);
            if (creatorFee != 0) payable(creator).transfer(creatorFee);
        } else {
            IERC20(order.paymentToken).safeTransferFrom(address(msg.sender), order.seller, netPrice);
            if (businessFee != 0) IERC20(order.paymentToken).safeTransferFrom(address(msg.sender), ceoAddress, businessFee);
            if (creatorFee != 0) IERC20(order.paymentToken).safeTransferFrom(address(msg.sender), creator, creatorFee);
        }

        // transfer NFTs after
        uint256 length = order.tokenIds.length;
        for(uint256 i = 0; i < length; i++) {
            IERC721(_collection).safeTransferFrom(order.seller, address(msg.sender), order.tokenIds[i]);
        }
        order.buyer = msg.sender;

        emit Buy(_collection, _orderId, order.seller, msg.sender, order.paymentToken, order.price, netPrice);
    }

    function buy(address _collection, uint256 _orderId) external payable notContract nonReentrant {
        _buy(_collection, _orderId);
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}