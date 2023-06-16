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
    // balanceOf
    function balanceOf(address account_) external returns (uint256);

    // authorize Supply Management Multi-Sig for redemption
    function authorizeRedemption(uint256 amount_) external;
}

// Admin Multi-Sig Interface
interface AdminMultiSigInterface {
    // get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);
}

// Address Book Interface
interface AddressBookInterface {
    // Get ERC20 Contract Address
    function getERC20ContractAddress() external view returns (address);

    // Get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);

    // Get Fee Management Multi-Sig Contract Address
    function getFeeManagementMultiSigContractAddress()
        external 
        view
        returns (address);
}

// Fee Management Interface
interface FeeManagementInterface {
    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;

    // authorize for redemption
    function authorizeRedemption(uint256 redemptionAmount_) external;

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
contract FeeManagement is FeeManagementInterface {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    // Strings
    using Strings for string;

    // SafeMath
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
    {
        // require non-zero address
        require(
            AddressBookContractAddress_ != address(0),
            "Fee Management: Address should not be zero-address!"
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

    // only fee manager
    modifier onlyFeeManager() {
        _onlyFeeManager();
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        _notNullAddress(account_);
        _;
    }

    // only Address Book
    modifier onlyAddressBook() {
        // require sender be Address Book
        _onlyAddressBook();
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    ///  Role Updating Functions

    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) public onlyAddressBook notNullAddress(AddressBookContractAddress_) {
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
            "Fee Management: Amount cannot be smaller than the global min transfer limit!"
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
            "Fee Management: Amount cannot be smaller than the global min creation limit!"
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
            "Fee Management: Amount cannot be smaller than the global min redemption limit!"
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
            "Fee Management: This address is already in the global whitelist!"
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
            "Fee Management: This address is not in global whitelist!"
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
            "Fee Management: This address is already in the creation/redemption whitelist!"
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
            "Fee Management: This address is not in creation/redemption whitelist!"
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
            "Fee Management: This address is already in the transfer whitelist!"
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
            "Fee Management: This address is not in transfer whitelist!"
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

    // only fee manager
    function _onlyFeeManager() internal view {
        require(
            msg.sender ==
                _AddressBook.getFeeManagementMultiSigContractAddress(),
            "Fee Management: Sender is not the fee manager address!"
        );
    }

    // not Null Address
    function _notNullAddress(address account_) internal pure {
        // require account not be the zero address
        require(account_ != address(0), "Fee Management: Account can not be zero address!");
    }

    // only Address Book
    function _onlyAddressBook() internal view {
        // require sender be Address Book
        require(
            msg.sender == AdminMultiSigInterface(_AddressBook.getAdminMultiSigContractAddress()).getAddressBookContractAddress(),
            "Fee Management: Sender is not Address Book!"
        );
    }
}