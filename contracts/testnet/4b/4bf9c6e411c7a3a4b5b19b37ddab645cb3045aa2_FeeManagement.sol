/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-13
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

    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;

    // update Fee Management Contract Address
    function updateFeeManagementContractAddress(
        address FeeManagementContractAddress_
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

// Address Book Interface
interface AddressBookInterface {
    // Update ERC20 Contract Address
    function updateERC20ContractAddress(
        address ERC20ContractAddress_,
        address executor_
    ) external;

    // Get ERC20 Contract Address
    function getERC20ContractAddress() external view returns (address);

    // Update Admin Multi-Sig Contract Address
    function updateAdminMultiSigConractAddress(
        address AdminMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);

    // Update Supply Management Multi-Sig Contract Address
    function updateSupplyManagementMultiSigConractAddress(
        address SupplyManagementMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Supply Management Multi-Sig Contract Address
    function getSupplyManagementMultiSigContractAddress()
        external
        view
        returns (address);

    // Update Fee Management Contract Address
    function updateFeeManagementConractAddress(
        address FeeManagementContractAddress_,
        address executor_
    ) external;

    // Get Fee Management Contract Address
    function getFeeManagementContractAddress() external view returns (address);

    // Update Fee Management Multi-Sig Contract Address
    function updateFeeManagementMultiSigConractAddress(
        address FeeManagementMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Fee Management Multi-Sig Contract Address
    function getFeeManagementMultiSigContractAddress()
        external
        view
        returns (address);

    // Update Asset Protection Multi-Sig Contract Address
    function updateAssetProtectionMultiSigConractAddress(
        address AssetProtectionMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Asset Protection Multi-Sig Contract Address
    function getAssetProtectionMultiSigContractAddress()
        external
        view
        returns (address);

    // Get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);

    // update KYC Contract Address
    function updateKYCContractAddress(address KYCContractAddress_, address executor_) external;

    // get KYC Contract Address
    function getKYCContractAddress() external view returns (address);

    // update KYC Multi-Sig Contract Address
    function updateKYCMultiSigContractAddress(address KYCMultiSigContractAddress_, address executor_) external;

    // get KYC Multi-Sig Contract Address
    function getKYCMultiSigContractAddress() external view returns(address);
}

// Fee Management Interface
interface FeeManagementInterface {
    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;

    // authorize for redemption
    function authorizeRedemption(uint256 redemptionAmount_) external;

    // update whitelist manager
    function updateWhitelistManager(address whitelistManagerAddress_) external;

    // update fee manager
    function updateFeeManager(address feeManagerAddress_) external;

    // add account to global whitelist
    function appendToGlobalWhitelist(address account_) external;

    // remove account from global whitelist
    function removeFromGlobalWhitelist(address account_) external;

    // add account to creation/redemption whitelist
    function appendToCRWhitelist(address account_) external;

    // remove account from creation/redemption whitelist
    function removeFromCRWhitelist(address account_) external;

    // add account to transfer whitelist
    function appendToTransferWhitelist(address account_) external;

    // remove account from transfer whitelist
    function removeFromTransferWhitelist(address account_) external;

    // set fee decimals
    function setFeeDecimals(uint256 feeDecimals_) external;

    // set creation fee
    function setCreationFee(uint256 creationFee_) external;

    // set redemption fee
    function setRedemptionFee(uint256 redemptionFee_) external;

    // set transfer fee
    function setTransferFee(uint256 transferFee_) external;

    // set min transfer amount
    function setMinTransferAmount(uint256 amount_) external;

    // set min creation amount
    function setMinCreationAmount(uint256 amount_) external;

    // set min redemption amount
    function setMinRedemptionAmount(uint256 amount_) external;

    // get Admin
    function getAdmin() external view returns (address);

    // get fee manager
    function getFeeManager() external view returns (address);

    // is global whitelisted
    function isGlobalWhitelisted(address account_) external view returns (bool);

    // is creation/redemption whitelisted
    function isCRWhitelisted(address account_) external view returns (bool);

    // is transfer whitelisted
    function isTransferWhitelisted(address account_)
        external
        view
        returns (bool);

    // get list of accounts in global whitelist
    function getGlobalWhitelist() external view returns (address[] memory);

    // get list of accounts in creation/redemption whitelist
    function getCreationRedemptionWhitelist()
        external
        view
        returns (address[] memory);

    // get list of accounts in transfer whitelist
    function getTransferWhitelist() external view returns (address[] memory);

    // get fee decimals
    function getFeeDecimals() external view returns (uint256);

    // get creation fee
    function getCreationFee() external view returns (uint256);

    // get redemption fee
    function getRedemptionFee() external view returns (uint256);

    // get transfer fee
    function getTransferFee() external view returns (uint256);

    // get min transfer amount
    function getGlobalMinTransferAmount() external view returns (uint256);

    // get min creation amount
    function getMinTransferAmount() external view returns (uint256);

    // get global min creation amount
    function getGlobalMinCreationAmount() external view returns (uint256);

    // get min creation amount
    function getMinCreationAmount() external view returns (uint256);

    // get global min redemption amount
    function getGlobalMinRedemptionAmount() external view returns (uint256);

    // get min redemption amount
    function getMinRedemptionAmount() external view returns (uint256);
}

// Fee Management Contract
contract FeeManagement {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    using Strings for string;
    using SafeMath for uint256;

    //////////////////////
    ////    Fields    ////
    //////////////////////

    /*  ROLES   */

    // Address Book Contract Address
    address private _AddressBookContractAddress;

    // Address Book Contract Interface
    AddressBookInterface private _AddressBook;

    /*  WhiteLists Fields   */

    // global whitelist addresses status
    mapping(address => bool) private _globalWhitelistAddressesStatus;

    // global whitelist addresses
    address[] private _globalWhitelistAddresses;

    // creation/redemption whitelist addresses status
    mapping(address => bool) private _CRWhitelistAddressesStatus;

    // creation/redemption whitelist addresses
    address[] private _CRWhitelistAddresses;

    // transfer whitelist addresses Status
    mapping(address => bool) private _transferWhitelistAddressesStatus;

    // transfer whitelist addresses
    address[] private _transferWhitelistAddresses;

    /*  Fee Fields   */

    // fee decimals
    uint256 private _feeDecimals = 18;

    // createion fee
    uint256 private _creationFee = 25 * (10**14);

    // redemption fee
    uint256 private _redemptionFee = 25 * (10**14);

    // transfer fee
    uint256 private _transferFee = 10 * (10**14);

    // global Min transfer amount
    uint256 private _globalMinTransferAmount = 1000;

    // min transfer amount
    uint256 private _minTransferAmount = 1000;

    // global min creation amount
    uint256 private _globalMinCreationAmount = 4000;

    // min creation amount
    uint256 private _minCreationAmount = 4000 * (10**18);

    // global min redemption amount
    uint256 private _globalMinRedemptionAmount = 4000;

    // min redemption amount
    uint256 private _minRedemptionAmount = 4000 * (10**18);

    ///////////////////////////
    ////    Constructor    ////
    ///////////////////////////

    // constructor
    constructor(address AddressBookContractAddress_)
        notNullAddress(AddressBookContractAddress_)
    {
        // require non-zero address
        require(
            AddressBookContractAddress_ != address(0),
            "Address should not be zero-address!"
        );

        // set Address Book
        _AddressBookContractAddress = AddressBookContractAddress_;
        
        // update Address Book Contract Interface
        _AddressBook = AddressBookInterface(AddressBookContractAddress_);

        // emit event
        emit updateAddressBookContractAddressEvent(
            msg.sender,
            address(0),
            AddressBookContractAddress_,
            block.timestamp
        );
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // update Address Book contract address
    event updateAddressBookContractAddressEvent(
        address indexed Admin,
        address previousAddressBookContractAddress,
        address indexed newAddressBookContractAddress,
        uint256 indexed timestamp
    );

    // authorize redemption order for treasurer
    event authorizeRedemptionEvent(
        address indexed FeeManager,
        uint256 redemptionAmount,
        uint256 indexed timestamp
    );

    // append account to global whitelist addresses
    event appendToGlobalWhitelistEvent(
        address indexed whitelistManager,
        address indexed account,
        uint256 indexed timestamp
    );

    // remove account from global whitelist addresses
    event removeFromGlobalWhitelistEvent(
        address indexed whitelistManager,
        address indexed account,
        uint256 indexed timestamp
    );

    // append account to creation/redemption whitelist addresses
    event appendToCRWhitelistEvent(
        address indexed whitelistManager,
        address account,
        uint256 indexed timestamp
    );

    // remove account from creation/redemption whitelist addresses
    event removeFromCRWhitelistEvent(
        address indexed whitelistManager,
        address account,
        uint256 indexed timestamp
    );

    // append account to transfer whitelist addresses
    event appendToTransferWhitelistEvent(
        address indexed whitelistManager,
        address account,
        uint256 indexed timestamp
    );

    // remove account from transfer whitelist addresses
    event removeFromTransferWhitelistEvent(
        address indexed whitelistManager,
        address account,
        uint256 indexed timestamp
    );

    // set fee decimals
    event setFeeDecimalsEvent(
        address indexed sender,
        uint256 previousFeeDecimals,
        uint256 newFeeDecimals,
        uint256 indexed timestamp
    );

    // set creation fee
    event setCreationFeeEvent(
        address indexed sender,
        uint256 previousCreationFee,
        uint256 newCreationFee,
        uint256 indexed timestamp
    );

    // set redemption fee
    event setRedemptionFeeEvent(
        address indexed sender,
        uint256 previousRedemptionFee,
        uint256 newRedemptionFee,
        uint256 indexed timestamp
    );

    // set transfer fee
    event setTransferFeeEvent(
        address indexed sender,
        uint256 previousTransferFee,
        uint256 newTransferFee,
        uint256 indexed timestamp
    );

    // update global min transfer amount
    event globalMinTransferAmountEvent(
        address indexed FeeSuperviso,
        uint256 previousGlobalMinTransferAmount,
        uint256 newGlobalMinTransferAmount,
        uint256 indexed timestamp
    );

    // update min transfer amount
    event minTransferAmountEvent(
        address indexed FeeSuperviso,
        uint256 previousMinTransferAmount,
        uint256 newMinTransferAmount,
        uint256 indexed timestamp
    );

    // update global min creation amount
    event globalMinCreationAmountEvent(
        address indexed sender,
        uint256 previousGlobalMinCreationAmount,
        uint256 newGlobalMinCreationAmount,
        uint256 indexed timestamp
    );

    // update min creation amount
    event minCreationAmountEvent(
        address indexed sender,
        uint256 previousMinCreationAmount,
        uint256 newMinCreationAmount,
        uint256 indexed timestamp
    );

    // update global min redemption amount
    event globalMinRedemptionAmountEvent(
        address indexed sender,
        uint256 previousGlobalMinRedemptionAmount,
        uint256 newGlobalMinRedemptionAmount,
        uint256 indexed timestamp
    );

    // update min redemption amount
    event minRedemptionAmountEvent(
        address indexed sender,
        uint256 previousMinRedemptionAmount,
        uint256 newMinRedemptionAmount,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Admin Multi-Sig
    modifier onlyAdmin() {
        require(
            msg.sender == _AddressBook.getAdminMultiSigContractAddress(),
            "Sender is not the admin address!"
        );
        _;
    }

    // only fee manager
    modifier onlyFeeManager() {
        require(
            msg.sender ==
                _AddressBook.getFeeManagementMultiSigContractAddress(),
            "Sender is not the fee manager address!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        require(account_ != address(0), "Account can not be zero address!");
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    ///  Role Updating Functions

    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) public onlyAdmin notNullAddress(AddressBookContractAddress_) {
        // previous Address Book Contract Address
        address previousAddressBookContractAddress = _AddressBookContractAddress;

        // update Address Book Contract Address
        _AddressBookContractAddress = AddressBookContractAddress_;

        // update Address Book Contract Interface
        _AddressBook = AddressBookInterface(AddressBookContractAddress_);

        // emit event
        emit updateAddressBookContractAddressEvent(
            msg.sender,
            previousAddressBookContractAddress,
            AddressBookContractAddress_,
            block.timestamp
        );
    }

    /*    Treasurer Function    */

    // authorize for redemption
    function authorizeRedemption(uint256 redemptionAmount_)
        public
        onlyFeeManager
    {
        // require having enough balance
        require(
            redemptionAmount_ <=
                ERC20Interface(_AddressBook.getERC20ContractAddress())
                    .balanceOf(address(this)),
            "Fee Management: Treasure does not have requested balance!"
        );

        // authorize Supply Manager to redeem requested amount
        ERC20Interface(_AddressBook.getERC20ContractAddress())
            .authorizeRedemption(redemptionAmount_);

        // emit event
        emit authorizeRedemptionEvent(
            msg.sender,
            redemptionAmount_,
            block.timestamp
        );
    }

    /*    Setting Fees Functions    */

    // set fee decimals
    function setFeeDecimals(uint256 feeDecimals_) public onlyFeeManager {
        // previous fee decimals
        uint256 previousFeeDecimals = _feeDecimals;

        // update fee decimals
        _feeDecimals = feeDecimals_;

        // emit event
        emit setFeeDecimalsEvent(
            msg.sender,
            previousFeeDecimals,
            _feeDecimals,
            block.timestamp
        );

        // emit event
        emit globalMinTransferAmountEvent(
            msg.sender,
            (10**previousFeeDecimals).div(_transferFee),
            (10**_feeDecimals).div(_transferFee),
            block.timestamp
        );

        // emit event
        emit globalMinCreationAmountEvent(
            msg.sender,
            (10**previousFeeDecimals).div(_creationFee),
            (10**_feeDecimals).div(_creationFee),
            block.timestamp
        );

        // emit event
        emit globalMinRedemptionAmountEvent(
            msg.sender,
            (10**previousFeeDecimals).div(_redemptionFee),
            (10**_feeDecimals).div(_redemptionFee),
            block.timestamp
        );
    }

    // set creation fee
    function setCreationFee(uint256 creationFee_) public onlyFeeManager {
        // previous creation fee
        uint256 previousCreationFee = _creationFee;

        // update creation fee
        _creationFee = creationFee_;

        // emit event
        emit setCreationFeeEvent(
            msg.sender,
            previousCreationFee,
            _creationFee,
            block.timestamp
        );

        // emit event
        emit globalMinCreationAmountEvent(
            msg.sender,
            (10**_feeDecimals).div(previousCreationFee),
            (10**_feeDecimals).div(_creationFee),
            block.timestamp
        );
    }

    // set redemption fee
    function setRedemptionFee(uint256 redemptionFee_) public onlyFeeManager {
        // previous redemption fee
        uint256 previousRedemptionFee = _redemptionFee;

        // update redemption fee
        _redemptionFee = redemptionFee_;

        // emit event
        emit setRedemptionFeeEvent(
            msg.sender,
            previousRedemptionFee,
            _redemptionFee,
            block.timestamp
        );

        // emit event
        emit globalMinRedemptionAmountEvent(
            msg.sender,
            (10**_feeDecimals).div(previousRedemptionFee),
            (10**_feeDecimals).div(_redemptionFee),
            block.timestamp
        );
    }

    // set transfer fee
    function setTransferFee(uint256 transferFee_) public onlyFeeManager {
        // previous transfer fee
        uint256 previousTransferFee = _transferFee;

        // update transfer fee
        _transferFee = transferFee_;

        // emit event
        emit setTransferFeeEvent(
            msg.sender,
            previousTransferFee,
            _transferFee,
            block.timestamp
        );

        // emit event
        emit globalMinTransferAmountEvent(
            msg.sender,
            (10**_feeDecimals).div(previousTransferFee),
            (10**_feeDecimals).div(_transferFee),
            block.timestamp
        );
    }

    // set min transfer amount
    function setMinTransferAmount(uint256 amount_) public onlyFeeManager {
        // require amount be greater than global min transfer amount
        require(
            amount_ >= _globalMinTransferAmount,
            "Amount cannot be smaller than the global min transfer limit!"
        );

        // previous min transfer amount
        uint256 previousMinTransferAmount = _minTransferAmount;

        // update min transfer amount
        _minTransferAmount = amount_;

        // emit event
        emit minTransferAmountEvent(
            msg.sender,
            previousMinTransferAmount,
            amount_,
            block.timestamp
        );
    }

    // set min creation amount
    function setMinCreationAmount(uint256 amount_) public onlyFeeManager {
        // require amount be greater than global min creation amount
        require(
            amount_ >= _globalMinCreationAmount,
            "Amount cannot be smaller than the global min creation limit!"
        );

        // previous min creation amount
        uint256 previousMinCreationAmount = _minCreationAmount;

        // update min creation amount
        _minCreationAmount = amount_;

        // emit event
        emit minCreationAmountEvent(
            msg.sender,
            previousMinCreationAmount,
            amount_,
            block.timestamp
        );
    }

    // set min redemption amount
    function setMinRedemptionAmount(uint256 amount_) public onlyFeeManager {
        // require amount be greater than global min redemption amount
        require(
            amount_ >= _globalMinRedemptionAmount,
            "Amount cannot be smaller than the global min redemption limit!"
        );

        // previous min redemption amount
        uint256 previousMinRedemptionAmount = _minRedemptionAmount;

        // update min redemption amount
        _minRedemptionAmount = amount_;

        // emit event
        emit minRedemptionAmountEvent(
            msg.sender,
            previousMinRedemptionAmount,
            amount_,
            block.timestamp
        );
    }

    /*    Whitelist Addresses Functions    */

    // add account to global whitelist
    function appendToGlobalWhitelist(address account_)
        public
        onlyFeeManager
        notNullAddress(account_)
    {
        // require address not be whitelisted
        require(
            !_globalWhitelistAddressesStatus[account_],
            "This address is already in the global whitelist!"
        );

        // add account to global whitelist and update the status
        _appendToGlobalWhitelistAddresses(account_);

        // emit event
        emit appendToGlobalWhitelistEvent(
            msg.sender,
            account_,
            block.timestamp
        );
    }

    // remove account from global whitelist
    function removeFromGlobalWhitelist(address account_)
        public
        onlyFeeManager
        notNullAddress(account_)
    {
        // require account be already whitelisted
        require(
            _globalWhitelistAddressesStatus[account_],
            "This address is not in global whitelist!"
        );

        // remove account from global whitelist and update the status
        _removeFromGlobalWhitelistAddresses(account_);

        // emit event
        emit removeFromGlobalWhitelistEvent(
            msg.sender,
            account_,
            block.timestamp
        );
    }

    // add account to creation/redemption whitelist
    function appendToCRWhitelist(address account_)
        public
        onlyFeeManager
        notNullAddress(account_)
    {
        // require address not be in creation/redemption whitelist
        require(
            !_CRWhitelistAddressesStatus[account_],
            "This address is already in the creation/redemption whitelist!"
        );

        // add the address to CR whitelistAddresses and update status
        _appendToCRWhitelistAddresses(account_);

        // emit event
        emit appendToCRWhitelistEvent(msg.sender, account_, block.timestamp);
    }

    // remove account from creation/redemption whitelist
    function removeFromCRWhitelist(address account_)
        public
        onlyFeeManager
        notNullAddress(account_)
    {
        // require account be already whitelisted
        require(
            _CRWhitelistAddressesStatus[account_],
            "This address is not in creation/redemption whitelist!"
        );

        // remove address from creation/redemption whitelist and update status
        _removeFromCRWhitelistAddresses(account_);

        // emit event
        emit removeFromCRWhitelistEvent(msg.sender, account_, block.timestamp);
    }

    // add account to transfer whitelist
    function appendToTransferWhitelist(address account_)
        public
        onlyFeeManager
        notNullAddress(account_)
    {
        // require address not be in transfer whitelist
        require(
            !_transferWhitelistAddressesStatus[account_],
            "This address is already in the transfer whitelist!"
        );

        // add the address to transfer whitelistAddresses and update status
        _appendToTransferWhitelistAddresses(account_);

        // emit event
        emit appendToTransferWhitelistEvent(
            msg.sender,
            account_,
            block.timestamp
        );
    }

    // remove account from transfer whitelist
    function removeFromTransferWhitelist(address account_)
        public
        onlyFeeManager
        notNullAddress(account_)
    {
        // require account be already whitelisted
        require(
            _transferWhitelistAddressesStatus[account_],
            "This address is not in transfer whitelist!"
        );

        // remove address from transfer whitelist and update status
        _removeFromTransferWhitelistAddresses(account_);

        // emit event
        emit removeFromTransferWhitelistEvent(
            msg.sender,
            account_,
            block.timestamp
        );
    }

    ////   Getters    ////

    // get Admin Multi-Sig
    function getAdmin() public view returns (address) {
        return _AddressBook.getAdminMultiSigContractAddress();
    }

    // get Fee Manager Multi-Sig
    function getFeeManager() public view returns (address) {
        return _AddressBook.getFeeManagementMultiSigContractAddress();
    }

    // is global whitelisted
    function isGlobalWhitelisted(address account_) public view returns (bool) {
        // return
        return _globalWhitelistAddressesStatus[account_];
    }

    // is creation/redemption whitelisted
    function isCRWhitelisted(address account_) public view returns (bool) {
        // return
        return _CRWhitelistAddressesStatus[account_];
    }

    // is transfer whitelisted
    function isTransferWhitelisted(address account_)
        public
        view
        returns (bool)
    {
        // return
        return _transferWhitelistAddressesStatus[account_];
    }

    // get list of accounts in global whitelist
    function getGlobalWhitelist() public view returns (address[] memory) {
        // return global whitelist addresses
        return _globalWhitelistAddresses;
    }

    // get list of accounts in creation/redemption whitelist
    function getCreationRedemptionWhitelist()
        public
        view
        returns (address[] memory)
    {
        // return CR whitelist addresses
        return _CRWhitelistAddresses;
    }

    // get list of accounts in transfer whitelist
    function getTransferWhitelist() public view returns (address[] memory) {
        // return transfer whitelist addresses
        return _transferWhitelistAddresses;
    }

    // get fee decimals
    function getFeeDecimals() public view returns (uint256) {
        return _feeDecimals;
    }

    // get creation fee
    function getCreationFee() public view returns (uint256) {
        return _creationFee;
    }

    // get redemption fee
    function getRedemptionFee() public view returns (uint256) {
        return _redemptionFee;
    }

    // get transfer fee
    function getTransferFee() public view returns (uint256) {
        return _transferFee;
    }

    // get min transfer amount
    function getGlobalMinTransferAmount() public view returns (uint256) {
        return _globalMinTransferAmount;
    }

    // get min creation amount
    function getMinTransferAmount() public view returns (uint256) {
        return _minTransferAmount;
    }

    // get global min creation amount
    function getGlobalMinCreationAmount() public view returns (uint256) {
        return _globalMinCreationAmount;
    }

    // get min creation amount
    function getMinCreationAmount() public view returns (uint256) {
        return _minCreationAmount;
    }

    // get global min redemption amount
    function getGlobalMinRedemptionAmount() public view returns (uint256) {
        return _globalMinRedemptionAmount;
    }

    // get min redemption amount
    function getMinRedemptionAmount() public view returns (uint256) {
        return _minRedemptionAmount;
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // add account to _globalWhitelistAddresses if not already in the list
    function _appendToGlobalWhitelistAddresses(address account_) internal {
        if (!_globalWhitelistAddressesStatus[account_]) {
            _globalWhitelistAddresses.push(account_);
            _globalWhitelistAddressesStatus[account_] = true;
        }
    }

    // remove account from _globalWhitelistAddresses if already in the list
    function _removeFromGlobalWhitelistAddresses(address account_) internal {
        if (_globalWhitelistAddressesStatus[account_]) {
            for (uint256 i = 0; i < _globalWhitelistAddresses.length; i++) {
                if (_globalWhitelistAddresses[i] == account_) {
                    _globalWhitelistAddresses[i] = _globalWhitelistAddresses[
                        _globalWhitelistAddresses.length - 1
                    ];
                    _globalWhitelistAddresses.pop();
                    // update status
                    _globalWhitelistAddressesStatus[account_] = false;
                    break;
                }
            }
        }
    }

    // add account to _CRWhitelistAddresses if not already in the list
    function _appendToCRWhitelistAddresses(address account_) internal {
        if (!_CRWhitelistAddressesStatus[account_]) {
            _CRWhitelistAddresses.push(account_);
            _CRWhitelistAddressesStatus[account_] = true;
        }
    }

    // remove account from _CRWhitelistAddresses if already in the list
    function _removeFromCRWhitelistAddresses(address account_) internal {
        if (_CRWhitelistAddressesStatus[account_]) {
            for (uint256 i = 0; i < _CRWhitelistAddresses.length; i++) {
                if (_CRWhitelistAddresses[i] == account_) {
                    _CRWhitelistAddresses[i] = _CRWhitelistAddresses[
                        _CRWhitelistAddresses.length - 1
                    ];
                    _CRWhitelistAddresses.pop();
                    // update status
                    _CRWhitelistAddressesStatus[account_] = false;
                    break;
                }
            }
        }
    }

    // add account to _transferWhitelistAddresses if not already in the list
    function _appendToTransferWhitelistAddresses(address account_) internal {
        if (!_transferWhitelistAddressesStatus[account_]) {
            _transferWhitelistAddresses.push(account_);
            _transferWhitelistAddressesStatus[account_] = true;
        }
    }

    // remove account from _transferWhitelistAddresses if already in the list
    function _removeFromTransferWhitelistAddresses(address account_) internal {
        if (_transferWhitelistAddressesStatus[account_]) {
            for (uint256 i = 0; i < _transferWhitelistAddresses.length; i++) {
                if (_transferWhitelistAddresses[i] == account_) {
                    _transferWhitelistAddresses[
                        i
                    ] = _transferWhitelistAddresses[
                        _transferWhitelistAddresses.length - 1
                    ];
                    _transferWhitelistAddresses.pop();
                    // update status
                    _transferWhitelistAddressesStatus[account_] = false;
                    break;
                }
            }
        }
    }
}