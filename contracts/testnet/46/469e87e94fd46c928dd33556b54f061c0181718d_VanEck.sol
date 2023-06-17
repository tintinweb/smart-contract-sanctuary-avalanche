/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * Strings Library
 *
 * In summary this is a simple library of string functions which make simple
 * string operations less tedious in solidity.
 *
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 *
 * @author James Lockhart <[email protected]>
 */
library Strings {
    /**
     * Concat (High gas cost)
     *
     * Appends two strings together and returns a new value
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(
            _baseBytes.length + _valueBytes.length
        );
        bytes memory _newValue = bytes(_tmpValue);

        uint256 i;
        uint256 j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int256)
    {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(
        string memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return -1;
    }

    /**
     * Length
     *
     * Returns the length of the specified string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base) internal pure returns (uint256) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     *
     * Extracts the beginning part of a string based on the desired length
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int256 _length)
        internal
        pure
        returns (string memory)
    {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     *
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(
        string memory _base,
        int256 _length,
        int256 _offset
    ) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint256(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint256(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint256 j = 0;
        for (
            uint256 i = uint256(_offset);
            i < uint256(_offset + _length);
            i++
        ) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr)
    {
        bytes memory _baseBytes = bytes(_base);

        uint256 _offset = 0;
        uint256 _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) break;
            else {
                _splitsCount++;
                _offset = uint256(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int256(_baseBytes.length);
            }

            string memory _tmp = new string(uint256(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint256 j = 0;
            for (uint256 i = _offset; i < uint256(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint256(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     *
     * Compares the characters of two strings, to ensure that they have an
     * identical footprint
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     *
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < _baseBytes.length; i++) {
            if (
                _baseBytes[i] != _valueBytes[i] &&
                _upper(_baseBytes[i]) != _upper(_valueBytes[i])
            ) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     *
     * Converts all the values of a string to their corresponding upper case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string
     */
    function upper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     *
     * Converts all the values of a string to their corresponding lower case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string
     */
    function lower(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     *
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     *
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// KYC Interface
interface KYCInterface {
    // authorized account info
    struct AUTHORIZEDACCOUNTINFO {
        // KYC Manager
        address KYCManager;
        // account address
        address account;
        // is authorized
        bool isAuthorized;
        // authorized time
        uint256 authorizedTimestamp;
        // unauthorized time
        uint256 unauthorizeTimestamp;
    }

    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;

    // get global authorization status
    function getGlobalAuthorizationStatus() external view returns (bool);

    // is authorized address?
    function isAuthorizedAddress(address account_) external view returns (bool);

    // get authorized account info
    function getAuthorizedAccountInfo(address account_)
        external
        view
        returns (AUTHORIZEDACCOUNTINFO memory);

    // get batch authorized accounts info
    function getBatchAuthorizedAccountInfo(address[] memory accounts_)
        external
        view
        returns (AUTHORIZEDACCOUNTINFO[] memory);
}

// Admin Multi-Sig Interface
interface AdminMultiSigInterface {
    // get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);
}

// Fee Management Interface
interface FeeManagementInterface {
    // is global whitelisted
    function isGlobalWhitelisted(address account_) external view returns (bool);

    // is creation/redemption whitelisted
    function isCRWhitelisted(address account_) external view returns (bool);

    // is transfer whitelisted
    function isTransferWhitelisted(address account_)
        external
        view
        returns (bool);

    // get fee decimals
    function getFeeDecimals() external view returns (uint256);

    // get creation fee
    function getCreationFee() external view returns (uint256);

    // get redemption fee
    function getRedemptionFee() external view returns (uint256);

    // get transfer fee
    function getTransferFee() external view returns (uint256);

    // get min creation amount
    function getMinTransferAmount() external view returns (uint256);

    // get min creation amount
    function getMinCreationAmount() external view returns (uint256);

    // get min redemption amount
    function getMinRedemptionAmount() external view returns (uint256);
}

// Address Book Interface
interface AddressBookInterface {
    // Get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);

    // Get Supply Management Multi-Sig Contract Address
    function getSupplyManagementMultiSigContractAddress()
        external
        view
        returns (address);

    // Get Fee Management Contract Address
    function getFeeManagementContractAddress() external view returns (address);

    // Get Fee Management Multi-Sig Contract Address
    function getFeeManagementMultiSigContractAddress()
        external
        view
        returns (address);

    // Get Asset Protection Multi-Sig Contract Address
    function getAssetProtectionMultiSigContractAddress()
        external
        view
        returns (address);

    // Get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);

    // get KYC Contract Address
    function getKYCContractAddress() external view returns (address);
}

// ERC20 Interface
interface ERC20Interface {
    ////    Standard ERC20    ////

    // transfer
    function transfer(address to_, uint256 amount_) external returns (bool);

    // allowance
    function allowance(address owner_, address spender_)
        external
        view
        returns (uint256);

    // approve
    function approve(address spender_, uint256 amount_) external returns (bool);

    // transferFrom
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external returns (bool);

    // increaseAllowance
    function increaseAllowance(address spender_, uint256 addedValue_)
        external
        returns (bool);

    // decreaseAllowance
    function decreaseAllowance(address spender_, uint256 subtractedValue_)
        external
        returns (bool);

    // name
    function name() external view returns (string memory);

    // symbol
    function symbol() external view returns (string memory);

    // decimals
    function decimals() external view returns (uint8);

    // totalSupply
    function totalSupply() external view returns (uint256);

    // balanceOf
    function balanceOf(address account_) external returns (uint256);

    //// Commodity Token Public Functions   ////

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) external;

    // freeze all transactions
    function freezeAllTransactions() external;

    // un-freeze all transactions
    function unFreezeAllTransactions() external;

    // freeze an account
    function freezeAccount(address account_) external;

    // un-freeze and account
    function unFreezeAccount(address account_) external;

    // wipe freezed account
    function wipeFreezedAccount(address account_) external;

    // wipe specific amount freezed account
    function wipeSpecificAmountFreezedAccount(address account_, uint256 amount_)
        external;

    // freeze and wipe an account
    function freezeAndWipeAccount(address account_) external;

    // freeze and wipe specific amount from an account
    function freezeAndWipeSpecificAmountAccount(
        address account_,
        uint256 amount_
    ) external;

    // creation basket
    function creationBasket(
        uint256 amount_,
        address receiverAddress_,
        string memory basketType_
    ) external returns (bool);

    // authorize Supply Management Multi-Sig for redemption
    function authorizeRedemption(uint256 amount_) external;

    // revoke authorized redemption
    function revokeAuthorizedRedemption(uint256 amount_) external;

    // redemption basket
    function redemptionBasket(uint256 amount_, address senderAddress_)
        external
        returns (bool);

    // withdraw tokens from contract to Treasurer account
    function withdrawContractTokens() external;

    ////   Getters    ////

    // get Address Book
    function getAddressBook() external view returns (address);

    // get Admin Multi-Sign
    function getAdmin() external view returns (address);

    // get Asset Protection
    function getAssetProtection() external view returns (address);

    // get Fee Management Contract Address
    function getFeeManagementContractAddress() external view returns (address);

    // get Fee Management Multi-Sign Address
    function getFeeManager() external view returns (address);

    // get token supply manager
    function getTokenSupplyManager() external view returns (address);

    // get redemption approved amount
    function getRedemptionApprovedAmount(address account_)
        external
        view
        returns (uint256);

    // is freeze all transaction
    function isAllTransactionsFreezed() external view returns (bool);

    // is acount freezed
    function isFreezed(address account_) external view returns (bool);

    // get list of freezed accounts
    function getFreezedAccounts() external view returns (address[] memory);

    // get holders
    function getHolders() external view returns (address[] memory);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract VanEck is Context, IERC20, IERC20Metadata {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    using Strings for string;
    using SafeMath for uint256;

    //////////////////////
    ////    Fields    ////
    //////////////////////

    ////    Standard ERC20 Fields    ////

    // name of token
    string private _name;

    // symbol of token
    string private _symbol;

    // total supply of toekn
    uint256 private _totalSupply;

    // token allowance of addresses
    mapping(address => mapping(address => uint256)) private _allowances;

    // token balance of addresses
    mapping(address => uint256) private _balances;

    ////    Commodity Token Fields    ////

    // Admin Multi-Sig Contract Address
    address private _AdminMultiSigContractAddress;

    // Admin Multi-Sig Contract Interface
    AdminMultiSigInterface private _AdminMultiSig;

    // redemption approvals
    mapping(address => mapping(address => uint256))
        private _authorizedRedemptionAmount;

    /*  Freezing Transactions Fields   */

    // FreezAllTransactios
    bool private _freezAllTransactions = false;

    // freezing specific accounts transactions
    mapping(address => bool) private _freezedAccountsStatus;

    // list of account freezed
    address[] private _freezedAccounts;

    /*  Holders Field  */

    // holders status
    mapping(address => bool) private _holdersStatus;

    // list of addresses holding tokens
    address[] private _holders;

    ///////////////////////////
    ////    Constructor    ////
    ///////////////////////////

    // constructor
    constructor(
        string memory name_,
        string memory symbol_,
        address AdminMultiSigContractAddress_
    ) {
        // set name
        _name = name_;

        // set symbol
        _symbol = symbol_;

        // require account not be the zero address
        require(
            AdminMultiSigContractAddress_ != address(0),
            "Admin Multi-Sig can not be zero address!"
        );

        // update Admin Multi-Sig Contract Address
        _AdminMultiSigContractAddress = AdminMultiSigContractAddress_;

        // update Address Book Contract Interface
        _AdminMultiSig = AdminMultiSigInterface(AdminMultiSigContractAddress_);

        // emit event
        emit updateAdminMultiSigContractAddressEvent(
            msg.sender,
            address(0),
            AdminMultiSigContractAddress_,
            block.timestamp
        );
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    ////    Standard ERC20 Events    ////

    ////    Commodity Token Events    ////

    // update Admin Multi-Sig contract address
    event updateAdminMultiSigContractAddressEvent(
        address indexed Admin,
        address previousAdminMultiSigContractAddress,
        address indexed newAdminMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // freezing all transactions by owner
    event freezeAllTransactionsEvent(
        address indexed ownerAddress,
        uint256 indexed timestamp
    );

    // un-freeze all transactions by owner
    event unFreezeAllTransactionsEvent(
        address indexed ownerAddress,
        uint256 indexed timestamp
    );

    // freez an account event
    event freezeAccountEvent(
        address indexed AssetProtection,
        address indexed account,
        uint256 indexed timestamp
    );

    // un-freeze and account event
    event unFreezeAccountEvent(
        address indexed AssetProtection,
        address indexed account,
        uint256 indexed timestamp
    );

    // wipe freezed account event
    event wipeFreezedAccountEvent(
        address indexed AssetProtection,
        address indexed account,
        uint256 balance,
        uint256 indexed timestamp
    );

    // wipe specific amount from freezed account
    event wipeSpecificAmountFreezedAccountEvent(
        address indexed AssetProtection,
        address indexed account,
        uint256 balance,
        uint256 amount,
        uint256 indexed timestamp
    );

    // freeze and wipe an account event
    event freezeAndWipeAccountEvent(
        address indexed AssetProtection,
        address indexed account,
        uint256 balance,
        uint256 indexed timestamp
    );

    // freeze and wipe specific amount from an account
    event freezeAndWipeSpecificAmountAccountEvent(
        address indexed AssetProtection,
        address indexed account,
        uint256 balance,
        uint256 amount,
        uint256 indexed timestamp
    );

    // withdraw tokens send to contract address
    event withdrawContractTokensEvent(
        address indexed contractAddress,
        address indexed treasurerAddress,
        uint256 amount,
        uint256 indexed timestamp
    );

    // creation basket event
    event creationBasketEvent(
        address indexed tokenSupplyManager,
        address indexed receiverAddress,
        address treasurer,
        string creationType,
        uint256 receiverAmount,
        uint256 creationFeeAmount,
        bool isWhitelisted,
        uint256 indexed timestamp
    );

    // approve redemption order event
    event authorizeRedemptionEvent(
        address indexed Sender,
        address indexed SupplyManager,
        uint256 amount,
        uint256 indexed timestamp
    );

    // revoke redemption order event
    event revokeAuthorizedRedemptionEvent(
        address indexed Sender,
        address indexed SupplyManager,
        uint256 amount,
        uint256 indexed timestamp
    );

    // redemption basket event
    event redemptionBasketEvent(
        address indexed tokenSupplyManager,
        address indexed senderAddress,
        address treasurer,
        uint256 amountBurned,
        uint256 redemptionFeeAmount,
        bool isWhitelisted,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    ////    Standard ERC20 Modifiers    ////

    ////    Commodity Token Modifiers    ////

    // All Transactions Not Freezed
    modifier AllTransactionsNotFreezed() {
        _AllTransactionsNotFreezed();
        _;
    }

    // only Admin Multi-Sig
    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    // only Token Supply Manager
    modifier onlyTokenSupplyManager() {
        _onlyTokenSupplyManager();
        _;
    }

    // only Fee Management Multi-Sig
    modifier onlyFeeManager() {
        // require sender be the Fee Management Multi-Sig
        _onlyFeeManager();
        _;
    }

    // only Asset Protection
    modifier onlyAssetProtection() {
        _onlyAssetProtection();
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        _notNullAddress(account_);
        _;
    }

    // only KYC Authorized
    modifier onlyKYCAuthorized(address account_) {
        // require account to be KYC authorized
        _onlyKYCAuthorized(account_);
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    ////    Standard ERC20    ////

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to_, uint256 amount_)
        public
        virtual
        override
        AllTransactionsNotFreezed
        onlyKYCAuthorized(to_)
        returns (bool)
    {
        // require amount > 0
        require(amount_ > 0, "Amount should be greater than zero!");

        // sender account
        address owner_ = _msgSender();

        // require sender be not freezed
        _requireNotFreezed(owner_);

        // require to be not freezed
        _requireNotFreezed(to_);

        // transfer amount from sender to to address
        _transfer(owner_, to_, amount_);

        // return
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner_, address spender_)
        public
        view
        virtual
        override
        AllTransactionsNotFreezed
        onlyKYCAuthorized(owner_)
        onlyKYCAuthorized(spender_)
        returns (uint256)
    {
        // require sender be not freezed
        _requireNotFreezed(owner_);

        // require spender be not freezed
        _requireNotFreezed(spender_);

        return _allowances[owner_][spender_];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender_, uint256 amount_)
        public
        virtual
        override
        AllTransactionsNotFreezed
        onlyKYCAuthorized(spender_)
        returns (bool)
    {
        // require sender be not freezed
        _requireNotFreezed(msg.sender);

        // require spender be not freezed
        _requireNotFreezed(spender_);

        address owner_ = _msgSender();
        _approve(owner_, spender_, amount_);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    )
        public
        virtual
        override
        AllTransactionsNotFreezed
        onlyKYCAuthorized(from_)
        onlyKYCAuthorized(to_)
        returns (bool)
    {
        address spender_ = _msgSender();

        // require sender be not freezed
        _requireNotFreezed(msg.sender);

        // require from_ be not freezed
        _requireNotFreezed(from_);

        // require to_ be not freezed
        _requireNotFreezed(to_);

        _spendAllowance(from_, spender_, amount_);
        _transfer(from_, to_, amount_);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender_, uint256 addedValue_)
        public
        virtual
        AllTransactionsNotFreezed
        onlyKYCAuthorized(spender_)
        returns (bool)
    {
        // require sender be not freezed
        _requireNotFreezed(msg.sender);

        // require spender be not freezed
        _requireNotFreezed(spender_);

        address owner_ = _msgSender();
        _approve(
            owner_,
            spender_,
            allowance(owner_, spender_).add(addedValue_)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender_, uint256 subtractedValue_)
        public
        virtual
        AllTransactionsNotFreezed
        onlyKYCAuthorized(spender_)
        returns (bool)
    {
        // require sender be not freezed
        _requireNotFreezed(msg.sender);

        // require spender be not freezed
        _requireNotFreezed(spender_);

        address owner_ = _msgSender();
        uint256 currentAllowance = allowance(owner_, spender_);
        require(
            currentAllowance >= subtractedValue_,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner_, spender_, currentAllowance.sub(subtractedValue_));
        }

        return true;
    }

    /// Getters  ///

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account_];
    }

    //// Commodity Token Public Functions   ////

    /*   Only Owner Functions    */

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) public onlyAdmin notNullAddress(AdminMultiSigContractAddress_) {
        // previous Admin Multi-Sig Contract Address
        address previousAdminMultiSigContractAddress = _AdminMultiSigContractAddress;

        // update Admin Multi-Sig Contract Address
        _AdminMultiSigContractAddress = AdminMultiSigContractAddress_;

        // update Admin Multi-Sig Contract Interface
        _AdminMultiSig = AdminMultiSigInterface(AdminMultiSigContractAddress_);

        // emit event
        emit updateAdminMultiSigContractAddressEvent(
            msg.sender,
            previousAdminMultiSigContractAddress,
            AdminMultiSigContractAddress_,
            block.timestamp
        );
    }

    // freeze all transactions
    function freezeAllTransactions() public onlyAdmin {
        // require all transactions be already unfrozen
        require(
            !_freezAllTransactions,
            "All transactions are already freezed!"
        );

        // set value for freeze all transactions
        _freezAllTransactions = true;

        // emit freezing all transactions event
        emit freezeAllTransactionsEvent(msg.sender, block.timestamp);
    }

    // un-freeze all transactions
    function unFreezeAllTransactions() public onlyAdmin {
        // require all transactions be already freezed
        require(
            _freezAllTransactions,
            "All transactions are already unfreezed!"
        );

        // set value for freeze all transactions
        _freezAllTransactions = false;

        // emit un-freeze all transaction event
        emit unFreezeAllTransactionsEvent(msg.sender, block.timestamp);
    }

    /*    Only Asset Protection Functions    */

    // freeze an account
    function freezeAccount(address account_)
        public
        onlyAssetProtection
        notNullAddress(account_)
    {
        // require account not be already freezed
        _requireNotFreezed(account_);

        // add account to freezed account and update account freeze status
        _appendToFreezedAccounts(account_);

        // emit event
        emit freezeAccountEvent(msg.sender, account_, block.timestamp);
    }

    // un-freeze and account
    function unFreezeAccount(address account_)
        public
        onlyAssetProtection
        notNullAddress(account_)
    {
        // require account be already freezed
        _requireFreezed(account_);

        // remove account to freezed account and update account freeze status
        _removeFromFreezedAccounts(account_);

        // emit event
        emit unFreezeAccountEvent(msg.sender, account_, block.timestamp);
    }

    // wipe freezed account
    function wipeFreezedAccount(address account_)
        public
        onlyAssetProtection
        notNullAddress(account_)
    {
        // require account bre freezed
        _requireFreezed(account_);

        // get balance of the freezed account
        uint256 balance_ = _balances[account_];

        // burn account balance
        _burn(account_, balance_);

        // emit event for wipe freezed acount
        emit wipeFreezedAccountEvent(
            msg.sender,
            account_,
            balance_,
            block.timestamp
        );
    }

    // wipe specific amount freezed account
    function wipeSpecificAmountFreezedAccount(address account_, uint256 amount_)
        public
        onlyAssetProtection
        notNullAddress(account_)
    {
        // require account bre freezed
        _requireFreezed(account_);

        // get balance of the freezed account
        uint256 balance_ = _balances[account_];

        // require enough balance
        require(
            amount_ <= balance_,
            "Requested amount is more than the balance!"
        );

        // burn account balance
        _burn(account_, amount_);

        // emit event for wipe freezed acount
        emit wipeSpecificAmountFreezedAccountEvent(
            msg.sender,
            account_,
            balance_,
            amount_,
            block.timestamp
        );
    }

    // freeze and wipe an account
    function freezeAndWipeAccount(address account_)
        public
        onlyAssetProtection
        notNullAddress(account_)
    {
        // require account not be already freezed
        _requireNotFreezed(account_);

        // add account to freezed account and update account freeze status
        _appendToFreezedAccounts(account_);

        // get balance of the freezed account
        uint256 balance_ = _balances[account_];

        // burn account balance
        _burn(account_, balance_);

        // emit event freezing and wiping the account
        emit freezeAndWipeAccountEvent(
            msg.sender,
            account_,
            balance_,
            block.timestamp
        );
    }

    // freeze and wipe specific amount from an account
    function freezeAndWipeSpecificAmountAccount(
        address account_,
        uint256 amount_
    ) public onlyAssetProtection notNullAddress(account_) {
        // require account not be already freezed
        _requireNotFreezed(account_);

        // add account to freezed account and update account freeze status
        _appendToFreezedAccounts(account_);

        // get balance of the freezed account
        uint256 balance_ = _balances[account_];

        // burn account balance
        _burn(account_, balance_);

        // require enough balance
        require(
            amount_ <= balance_,
            "Requested amount is more than the balance!"
        );

        // emit event freezing and wiping the account
        emit freezeAndWipeSpecificAmountAccountEvent(
            msg.sender,
            account_,
            balance_,
            amount_,
            block.timestamp
        );
    }

    /*    Only Token Supply Manager Functions    */

    // creation basket
    function creationBasket(
        uint256 amount_,
        address receiverAddress_,
        string memory basketType_
    )
        public
        onlyTokenSupplyManager
        notNullAddress(receiverAddress_)
        returns (bool)
    {
        // only KYC Authorized
        _onlyKYCAuthorized(receiverAddress_);

        if (
            basketType_.upper().compareTo("CASH") ||
            (basketType_.upper().compareTo("TOKEN") &&
                _FeeManagementContract().isCRWhitelisted(receiverAddress_)) ||
            (basketType_.upper().compareTo("TOKEN") &&
                _FeeManagementContract().isGlobalWhitelisted(receiverAddress_))
        ) {
            _mint(receiverAddress_, amount_);
            // emit creation basket event
            emit creationBasketEvent(
                msg.sender,
                receiverAddress_,
                _AddressBook().getFeeManagementContractAddress(),
                basketType_,
                amount_,
                0,
                _FeeManagementContract().isCRWhitelisted(receiverAddress_),
                block.timestamp
            );

            // return
            return true;
        } else if (basketType_.upper().compareTo("TOKEN")) {
            // require amount > min creation amount
            require(
                amount_ > _FeeManagementContract().getMinCreationAmount(),
                "Amount should be greater than min creation amount!"
            );

            // creation fee amount
            uint256 creationFeeAmount = (
                amount_.mul(_FeeManagementContract().getCreationFee())
            ) / (10**_FeeManagementContract().getFeeDecimals());
            // received amount
            uint256 receivedAmount = amount_.sub(creationFeeAmount);

            // mint received amount to receiver address (deducting CR-fee)
            _mint(receiverAddress_, receivedAmount);

            // mint cR-fee to treasurer.
            _mint(
                _AddressBook().getFeeManagementContractAddress(),
                creationFeeAmount
            );

            // emit creation basket event
            emit creationBasketEvent(
                msg.sender,
                receiverAddress_,
                _AddressBook().getFeeManagementContractAddress(),
                basketType_,
                receivedAmount,
                creationFeeAmount,
                _FeeManagementContract().isCRWhitelisted(receiverAddress_),
                block.timestamp
            );

            // return
            return true;
        } else {
            require(false, "Creation type should either be CASH or TOKEN!");

            // return false
            return false;
        }
    }

    // authorize Supply Management Multi-Sig for redemption
    function authorizeRedemption(uint256 amount_)
        public
        AllTransactionsNotFreezed
    {
        // require sender be not freezed
        _requireNotFreezed(msg.sender);

        // balance of sender address
        uint256 balance = _balances[msg.sender];

        // require sender have enough balance
        require(amount_ <= balance, "Balance of the sender address is low!");

        // authorize redemption to Supply Management
        _authorizedRedemptionAmount[msg.sender][
            _AddressBook().getSupplyManagementMultiSigContractAddress()
        ] = amount_;

        // emit event
        emit authorizeRedemptionEvent(
            msg.sender,
            _AddressBook().getSupplyManagementMultiSigContractAddress(),
            amount_,
            block.timestamp
        );
    }

    // revoke authorized redemption
    function revokeAuthorizedRedemption(uint256 amount_)
        public
        AllTransactionsNotFreezed
    {
        // require sender be not freezed
        _requireNotFreezed(msg.sender);

        // revoke approved redemption to Supply Management
        _authorizedRedemptionAmount[msg.sender][
            _AddressBook().getSupplyManagementMultiSigContractAddress()
        ] = _authorizedRedemptionAmount[msg.sender][
            _AddressBook().getSupplyManagementMultiSigContractAddress()
        ].sub(amount_);

        // emit event
        emit revokeAuthorizedRedemptionEvent(
            msg.sender,
            _AddressBook().getSupplyManagementMultiSigContractAddress(),
            amount_,
            block.timestamp
        );
    }

    // redemption basket
    function redemptionBasket(uint256 amount_, address senderAddress_)
        public
        onlyTokenSupplyManager
        notNullAddress(senderAddress_)
        returns (bool)
    {
        // balance of sender address
        uint256 balance = _balances[senderAddress_];

        // require sender balance be greater than amount
        require(amount_ <= balance, "Balance of the sender address is low!");

        // require Supply Manager be approved for redemption
        require(
            _authorizedRedemptionAmount[senderAddress_][
                _AddressBook().getSupplyManagementMultiSigContractAddress()
            ] >= amount_,
            "Sender has not approved supply manager for the requested amount!"
        );

        // require amount > min redemption amount
        require(
            amount_ > _FeeManagementContract().getMinRedemptionAmount(),
            "Amount should be greater than min redemption amount!"
        );

        // removed approved amount for redemption
        _authorizedRedemptionAmount[msg.sender][
            _AddressBook().getSupplyManagementMultiSigContractAddress()
        ] = _authorizedRedemptionAmount[msg.sender][
            _AddressBook().getSupplyManagementMultiSigContractAddress()
        ].sub(amount_);

        // burn and handle fee
        if (
            _FeeManagementContract().isCRWhitelisted(senderAddress_) ||
            _FeeManagementContract().isGlobalWhitelisted(senderAddress_)
        ) {
            // burn tokens from senderAddress
            _burn(senderAddress_, amount_);

            // emit redemption event
            emit redemptionBasketEvent(
                msg.sender,
                senderAddress_,
                _AddressBook().getFeeManagementContractAddress(),
                amount_,
                0,
                _FeeManagementContract().isCRWhitelisted(senderAddress_),
                block.timestamp
            );

            // return
            return true;
        } else {
            // redemption fee amount
            uint256 redemptionFeeAmount = (
                amount_.mul(_FeeManagementContract().getRedemptionFee())
            ) / (10**_FeeManagementContract().getFeeDecimals());

            // transfer
            _transfer(
                senderAddress_,
                _AddressBook().getFeeManagementContractAddress(),
                redemptionFeeAmount
            );

            // burn
            _burn(senderAddress_, amount_.sub(redemptionFeeAmount));

            // emit redemption event
            emit redemptionBasketEvent(
                msg.sender,
                senderAddress_,
                _AddressBook().getFeeManagementContractAddress(),
                amount_.sub(redemptionFeeAmount),
                redemptionFeeAmount,
                _FeeManagementContract().isCRWhitelisted(senderAddress_),
                block.timestamp
            );

            // return
            return true;
        }
    }

    /*    Only Fee Manager Functions    */

    // withdraw tokens from contract to Treasurer account
    function withdrawContractTokens() external onlyFeeManager {
        // get balanche of the VE Token Contract
        uint256 balance_ = _balances[address(this)];

        if (balance_ > 0) {
            _transfer(
                address(this),
                _AddressBook().getFeeManagementContractAddress(),
                balance_
            );
        }

        // emit WidthrawContractTokens
        emit withdrawContractTokensEvent(
            address(this),
            msg.sender,
            balance_,
            block.timestamp
        );
    }

    ////   Getters    ////

    // get Address Book
    function getAddressBook() public view returns (address) {
        return _AddressBook().getAddressBookContractAddress();
    }

    // get Admin Multi-Sign
    function getAdmin() public view returns (address) {
        return _AddressBook().getAdminMultiSigContractAddress();
    }

    // get Asset Protection
    function getAssetProtection() public view returns (address) {
        return _AddressBook().getAssetProtectionMultiSigContractAddress();
    }

    // get Fee Management Multi-Sign Address
    function getFeeManager() public view returns (address) {
        return _AddressBook().getFeeManagementMultiSigContractAddress();
    }

    // get token supply manager
    function getTokenSupplyManager() public view returns (address) {
        return _AddressBook().getSupplyManagementMultiSigContractAddress();
    }

    // get redemption approved amount
    function getRedemptionApprovedAmount(address account_)
        public
        view
        returns (uint256)
    {
        return
            _authorizedRedemptionAmount[account_][
                _AddressBook().getSupplyManagementMultiSigContractAddress()
            ];
    }

    // is freeze all transaction
    function isAllTransactionsFreezed() public view returns (bool) {
        return _freezAllTransactions;
    }

    // is acount freezed
    function isFreezed(address account_) public view returns (bool) {
        return _freezedAccountsStatus[account_];
    }

    // get list of freezed accounts
    function getFreezedAccounts() public view returns (address[] memory) {
        // return freezed accounts
        return _freezedAccounts;
    }

    // get holders
    function getHolders() public view returns (address[] memory) {
        return _holders;
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    ////   Standard ERC20 Functions    ////

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {
        require(from_ != address(0), "ERC20: transfer from the zero address");
        require(to_ != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from_, to_, amount_);

        uint256 fromBalance = _balances[from_];

        require(
            fromBalance >= amount_,
            "ERC20: transfer amount exceeds balance"
        );

        // check if from address is in transfer whitelist
        if (
            !(_FeeManagementContract().isTransferWhitelisted(from_) ||
                _FeeManagementContract().isGlobalWhitelisted(from_))
        ) {
            // require fromBalance be greater that the min transfer amount
            require(
                fromBalance > _FeeManagementContract().getMinTransferAmount(),
                "Balance of sender should be greater than min transfer amount!"
            );

            // compute transfer fee amount
            uint256 transferFeeAmout = (
                amount_.mul(_FeeManagementContract().getTransferFee())
            ).div(10**_FeeManagementContract().getFeeDecimals());

            // udpate balances
            unchecked {
                // remove transfer amount from sender
                _balances[from_] = fromBalance.sub(amount_);

                // add transfer fee amount to Treasurer account
                _balances[
                    _AddressBook().getFeeManagementContractAddress()
                ] = _balances[_AddressBook().getFeeManagementContractAddress()]
                    .add(transferFeeAmout);

                // add the rest amount to receiver address
                _balances[to_] = _balances[to_].add(
                    amount_.sub(transferFeeAmout)
                );
            }

            // update holders
            // add treasuer as holder if not already in the list
            if (
                !_holdersStatus[
                    _AddressBook().getFeeManagementContractAddress()
                ]
            ) {
                _appendToHolders(
                    _AddressBook().getFeeManagementContractAddress()
                );
            }

            // add to_ to holders if not already in the list
            if (!_holdersStatus[to_]) {
                _appendToHolders(to_);
            }

            // remove from_ from holders if balance is zero.
            // _removeFromHolders(from_);
            if (_balances[from_] == 0) {
                _removeFromHolders(from_);
            }

            // emit transfer to Treasurer
            emit Transfer(
                from_,
                _AddressBook().getFeeManagementContractAddress(),
                transferFeeAmout
            );

            // emit transfer to receiver
            emit Transfer(from_, to_, amount_.sub(transferFeeAmout));

            _afterTokenTransfer(from_, to_, amount_);
        } else {
            unchecked {
                _balances[from_] = fromBalance.sub(amount_);
                // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
                // decrementing then incrementing.
                _balances[to_] = _balances[to_].add(amount_);
            }

            // update holders
            // add to_ to holders if not already in the list
            if (!_holdersStatus[to_]) {
                _appendToHolders(to_);
            }

            // remove from_ from holders if balance is zero.
            // _removeFromHolders(from_);
            if (_balances[from_] == 0) {
                _removeFromHolders(from_);
            }

            emit Transfer(from_, to_, amount_);

            _afterTokenTransfer(from_, to_, amount_);
        }
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account_, amount_);

        _totalSupply = _totalSupply.add(amount_);

        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account_] = _balances[account_].add(amount_);
        }

        // update holder
        if (!_holdersStatus[account_]) {
            _appendToHolders(account_);
        }

        emit Transfer(address(0), account_, amount_);

        _afterTokenTransfer(address(0), account_, amount_);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account_, address(0), amount_);

        uint256 accountBalance = _balances[account_];
        require(
            accountBalance >= amount_,
            "ERC20: burn amount exceeds balance"
        );
        unchecked {
            _balances[account_] = accountBalance.sub(amount_);
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply = _totalSupply.sub(amount_);
        }

        // update holders if balance is zero.
        // _removeFromHolders(account_);
        if (_balances[account_] == 0) {
            _removeFromHolders(account_);
        }

        emit Transfer(account_, address(0), amount_);

        _afterTokenTransfer(account_, address(0), amount_);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        uint256 currentAllowance = allowance(owner_, spender_);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount_,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner_, spender_, currentAllowance.sub(amount_));
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}

    ////    Commodity Token Functions    ////

    // add account to _holders if not already in the list
    function _appendToHolders(address account_) internal {
        if (!_holdersStatus[account_]) {
            // add to list
            _holders.push(account_);
            // update status
            _holdersStatus[account_] = true;
        }
    }

    // remove account from _holders if already in the list
    function _removeFromHolders(address account_) internal {
        if (_holdersStatus[account_]) {
            for (uint256 i = 0; i < _holders.length; i++) {
                if (_holders[i] == account_) {
                    _holders[i] = _holders[_holders.length - 1];
                    _holders.pop();
                    // update status
                    _holdersStatus[account_] = false;
                    break;
                }
            }
        }
    }

    // requireNotFreezed
    function _requireNotFreezed(address account_) internal view virtual {
        // require account not freezed
        require(!_freezedAccountsStatus[account_], "Account is freezed!");
    }

    // requireFreezed
    function _requireFreezed(address account_) internal view virtual {
        // require account not freezed
        require(_freezedAccountsStatus[account_], "Account is not freezed!");
    }

    // add account to freezed accounts if not already in the list
    function _appendToFreezedAccounts(address account_) internal {
        if (!_freezedAccountsStatus[account_]) {
            _freezedAccounts.push(account_);
            _freezedAccountsStatus[account_] = true;
        }
    }

    // remove account from freezed accounts if already in the list
    function _removeFromFreezedAccounts(address account_) internal {
        if (_freezedAccountsStatus[account_]) {
            for (uint256 i = 0; i < _freezedAccounts.length; i++) {
                if (_freezedAccounts[i] == account_) {
                    _freezedAccounts[i] = _freezedAccounts[
                        _freezedAccounts.length - 1
                    ];
                    _freezedAccounts.pop();
                    // update status
                    _freezedAccountsStatus[account_] = false;
                    break;
                }
            }
        }
    }

    // All Transactions Not Freezed
    function _AllTransactionsNotFreezed() internal view {
        require(!_freezAllTransactions, "All transactions are freezed!");
    }

    // only Admin Multi-Sig
    function _onlyAdmin() internal view {
        require(
            msg.sender == _AddressBook().getAdminMultiSigContractAddress(),
            "Sender is not the admin address!"
        );
    }

    // only Token Supply Manager
    function _onlyTokenSupplyManager() internal view {
        require(
            msg.sender ==
                _AddressBook().getSupplyManagementMultiSigContractAddress(),
            "Sender is not the token supply manager address!"
        );
    }

    // only Fee Management Multi-Sig
    function _onlyFeeManager() internal view {
        // require sender be the Fee Management Multi-Sig
        require(
            msg.sender ==
                _AddressBook().getFeeManagementMultiSigContractAddress(),
            "Sender is not fee manager!"
        );
    }

    // only Asset Protection
    function _onlyAssetProtection() internal view {
        require(
            msg.sender ==
                _AddressBook().getAssetProtectionMultiSigContractAddress(),
            "Sender is not the Asset Protection address!"
        );
    }

    // not Null Address
    function _notNullAddress(address account_) internal pure {
        // require account not be the zero address
        require(account_ != address(0), "Account can not be zero address!");
    }

    // only KYC Authorized
    function _onlyKYCAuthorized(address account_) internal view {
        // require account to be KYC authorized
        require(
            KYCInterface(_AddressBook().getKYCContractAddress())
                .isAuthorizedAddress(account_) ||
                KYCInterface(_AddressBook().getKYCContractAddress())
                    .getGlobalAuthorizationStatus(),
            "Account is not KYC authorized!"
        );
    }

    // get Fee Management Contract Interface
    function _FeeManagementContract()
        internal
        view
        returns (FeeManagementInterface)
    {
        return
            FeeManagementInterface(
                _AddressBook().getFeeManagementContractAddress()
            );
    }

    // only Address Book
    function _onlyAddressBook() internal view {
        // require sender be Address Book
        require(
            msg.sender ==
                AdminMultiSigInterface(
                    _AddressBook().getAdminMultiSigContractAddress()
                ).getAddressBookContractAddress(),
            "Fee Management: Sender is not Address Book!"
        );
    }

    // get Address Book Contract Interface
    function _AddressBook() internal view returns (AddressBookInterface) {
        return
            AddressBookInterface(
                _AdminMultiSig.getAddressBookContractAddress()
            );
    }
}