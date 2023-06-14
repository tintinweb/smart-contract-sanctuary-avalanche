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

// Asset Protection Multi-Sig Interface
interface AssetProtectionMultiSigInterface {
    // update ERC20 Contract Address
    function updateERC20ContractAddress(address ERC20ContractAddress_) external;

    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) external;

    // create Asset Protection Proposal
    function createAssetProtectionProposal(
        address account_,
        string memory action_,
        uint256 expiration_
    ) external;

    // approve Asset Protection Proposal
    function approveAssetProtectionProposal(
        uint256 assetProtectionProposalIndex_
    ) external;

    // revoke Asset Protection Proposal
    function revokeAssetProtectionProposal(
        uint256 assetProtectionProposalIndex_
    ) external;

    // get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);

    // get max asset protection index
    function getMaxAssetProtectionIndex() external view returns (uint256);

    // get asset protection proposal detail
    // function getAssetProtectionProposalDetail(uint256 assetProtectionProposalIndex_) external view returns (AssetProtectionProposal memory);

    // is asset protection proposal apporver
    function IsAssetProtectionProposalApprover(
        uint256 assetProtectionProposalIndex_,
        address account_
    ) external view returns (bool);
}

// Asset Protection Multi-Sig
contract AssetProtectionMultiSig {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // ERC20 Contract Address
    address private _ERC20ContractAddress;

    // ERC20 Contract Interface
    ERC20Interface private _ERC20;

    // Address Book Contract Address
    address private _AddressBookContractAddress;

    // Address Book Contract Interface
    AddressBookInterface private _AddressBook;

    ///   Asset Protection Signatories   ///

    // list of Asset Protection Signatories
    address[] private _assetProtectionSignatories;

    // is an Asset Protection Signatory
    mapping(address => bool) private _isAssetProtectionSignatory;

    // Asset Protection proposal counter
    uint256 private _assetProtectionProposalIndex = 0;

    // Signatory Proposal struct for managing signatories
    struct SignatoryProposal {
        uint256 ID;
        address PROPOSER;
        address MODIFIEDSIGNER;
        string UPDATETYPE; // ADD or REMOVE
        bool ISEXECUTED;
        uint256 EXPIRATION; // expiration timestamp
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of signatory proposals info: admin proposal index => signatory proposal detail
    mapping(uint256 => SignatoryProposal) private _signatoryProposals;

    // signatory proposal approvers: admin proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _signatoryProposalApprovers;

    // minimum Asset Protection signature requirement
    uint256 private _minAssetProtectionSignatures;

    // Asset Protection Proposal struct
    struct AssetProtectionProposal {
        uint256 ID;
        address PROPOSER;
        address ACCOUNT;
        string ACTION;
        uint256 AMOUNT;
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of asset protection proposals info: Asset Protection proposal index => proposal detail
    mapping(uint256 => AssetProtectionProposal)
        private _assetProtectionProposals;

    // asset protection proposal approvers: Asset Protection proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _assetProtectionProposalApprovers;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // constructor
    constructor(
        address ERC20ContractAddress_,
        address AddressBookContractAddress_
    ) {

        // require account not be the zero address
        require(
            ERC20ContractAddress_ != address(0),
            "Admin Multi-Sig: ERC20 Address should not be zero address!"
        );

        // update ERC20 Contract Address
        _ERC20ContractAddress = ERC20ContractAddress_;

        // update ERC20 Contract Interface
        _ERC20 = ERC20Interface(ERC20ContractAddress_);

        // emit event
        emit updateERC20ContractAddressEvent(
            msg.sender,
            address(0),
            ERC20ContractAddress_,
            block.timestamp
        );

        // require account not be the zero address
        require(
            AddressBookContractAddress_ != address(0),
            "Admin Multi-Sig: Address Book should not be zero address!"
        );

        // update Address Book Contract Address
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

    // update ERC20 Contract Address
    event updateERC20ContractAddressEvent(
        address indexed AdminMultiSig,
        address previousERC20ContractAddress,
        address newERC20ContractAddress,
        uint256 indexed timestamp
    );

    // update Address Book contract address
    event updateAddressBookContractAddressEvent(
        address indexed Admin,
        address previousAddressBookContractAddress,
        address indexed newAddressBookContractAddress,
        uint256 indexed timestamp
    );

    // create signatory proposal
    event SignatoryProposalCreatedEvent(
        address indexed proposer,
        uint256 adminProposalIndex,
        address indexed proposedAdminSignatory,
        string updateType,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute signatory proposal
    event SingatoryProposalExecutedEvent(
        address indexed executor,
        uint256 adminProposalIndex,
        address indexed AdminSingatoryAdded,
        string updateType,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve signatory proposal
    event ApproveSignatoryProposalEvent(
        address indexed approver,
        uint256 adminProposalIndex,
        address indexed AdminSingatoryAdded,
        string UPDATETYPE,
        uint256 indexed timestamp
    );

    // revoke signatory proposal by proposer
    event revokeSignatoryProposalEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string updateType,
        uint256 indexed timestamp
    );

    // create asset protection proposal
    event AssetProtectionProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed assetProtectionProposalIndex,
        address account,
        uint256 amount,
        string action,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute freeze account proposal
    event AssetProtectionProposalExecutedEvent(
        address indexed executor,
        uint256 indexed assetProtectionProposalIndex,
        address account,
        string action,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve asset protection proposal
    event ApproveAssetProtectionProposalEvent(
        address indexed approver,
        uint256 indexed assetProtectionProposalIndex,
        address account,
        string action,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // revoke asset protection proposal
    event revokeAssetProtectionProposalEvent(
        address indexed proposer,
        uint256 indexed assetProtectionProposalIndex,
        address account,
        string action,
        uint256 expiration,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Asset Protection signatories
    modifier onlyAssetProtectors() {
        // require sender be an asset protector
        require(
            _isAssetProtectionSignatory[msg.sender],
            "Asset Protection Multi-Sig: Sender is not an Asset Protection Signatory!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Admin Multi-Sig: Address should not be zero address!"
        );
        _;
    }

    // only valid actions
    modifier onlyValidAction(string memory action_) {
        // require valid actions
        require(
            keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZE")) ||
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("UNFREEZE")) ||
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("WIPESPECIFICAMOUNTFREEZED")) ||
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("WIPEFREEZED")) ||
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPE")) ||
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPESPECIFICAMOUNT")),
            "Asset Protection Multi-Sig: Invalid Action!"
        );
        _;
    }

    // only valid adminProposalIndex
    modifier onlyValidAssetProtectionIndex(
        uint256 assetProtectionProposalIndex_
    ) {
        // require a valid admin proposal index ( != 0 and not more than max)
        require(
            (assetProtectionProposalIndex_ != 0 &&
                assetProtectionProposalIndex_ <= _assetProtectionProposalIndex),
            "Asset Protection Multi-Sig: Invalid proposal index!"
        );
        _;
    }

    // greater than zero value
    modifier onlyGreaterThanZero(uint256 value_) {
        // require value be greater than zero
        require(
            value_ > 0,
            "Admin Multi-Sig: Value should be greater than zero!"
        );
        _;
    }

    // only proposer
    modifier onlyProposer(uint256 assetProtectionProposalIndex_) {
        // require sender be the proposer of the proposal
        require(
            msg.sender ==
                _assetProtectionProposals[assetProtectionProposalIndex_]
                    .PROPOSER,
            "Asset Protection Multi-Sig: Sender is not the proposer!"
        );
        _;
    }

    // only Admin Multi-Sig
    modifier onlyAdmin() {
        // require sender be admin multisig contract address
        require(
            msg.sender == _AddressBook.getAdminMultiSigContractAddress(),
            "Sender is not admin!"
        );
        _;
    }

    // only valid signatory update type
    modifier onlyValidUpdateType(string memory updateType_) {
        // require valid update type
        require(
            keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("ADD")) ||
                keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("REMOVE")),
            "Admin Multi-Sig: Update type is not valid!"
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // update ERC20 Contract Address
    function updateERC20ContractAddress(address ERC20ContractAddress_)
        public
        notNullAddress(ERC20ContractAddress_)
        onlyAdmin
    {
        // previous ERC20 Contract Address
        address previousERC20ContractAddress = _ERC20ContractAddress;

        // update ERC20 Contract Address
        _ERC20ContractAddress = ERC20ContractAddress_;

        // update ERC20 Contract Interface
        _ERC20 = ERC20Interface(ERC20ContractAddress_);

        // emit event
        emit updateERC20ContractAddressEvent(
            msg.sender,
            previousERC20ContractAddress,
            ERC20ContractAddress_,
            block.timestamp
        );
    }

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

    ///   Signatory Proposal   ///

    // create Signatory proposal
    function createSignatoryProposal(
        address signatoryAddress_,
        string memory updateType_,
        uint256 expiration_
    )
        public
        onlyAssetProtectors
        notNullAddress(signatoryAddress_)
        onlyValidUpdateType(updateType_)
        onlyGreaterThanZero(expiration_)
    {
        // check update type
        if (
            keccak256(abi.encodePacked(updateType_)) ==
            keccak256(abi.encodePacked("ADD"))
        ) {
            // require account not be an Asset Protection signatory
            require(
                !_isAssetProtectionSignatory[signatoryAddress_],
                "Admin Multi-Sig: Account is already an Asset Protection signatory!"
            );

            // increment asset protection proposal index
            ++_assetProtectionProposalIndex;

            // add the admin proposal
            _signatoryProposals[
                _assetProtectionProposalIndex
            ] = SignatoryProposal({
                ID: _assetProtectionProposalIndex,
                PROPOSER: msg.sender,
                MODIFIEDSIGNER: signatoryAddress_,
                UPDATETYPE: updateType_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve proposal by admin sender
            _signatoryProposalApprovers[_assetProtectionProposalIndex][
                msg.sender
            ] = true;

            // emit add admin signatory proposal event
            emit SignatoryProposalCreatedEvent(
                msg.sender,
                _assetProtectionProposalIndex,
                signatoryAddress_,
                updateType_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only signatory.
            if (_assetProtectionSignatories.length == 1) {
                // add the new Asset Protection signatory directly: no need to create proposal
                // add to the Asset Protection signatories
                _assetProtectionSignatories.push(signatoryAddress_);

                // update Asset Protection signatory status
                _isAssetProtectionSignatory[signatoryAddress_] = true;

                // update proposal IS EXECUTED
                _signatoryProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update executed timestamp
                _signatoryProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit signatory added event
                emit SingatoryProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    signatoryAddress_,
                    updateType_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(updateType_)) ==
            keccak256(abi.encodePacked("REMOVE"))
        ) {
            // require address be an Asset Protection signatory
            // and min signature not less than new number of signatories
            require(
                (_isAssetProtectionSignatory[signatoryAddress_] &&
                    _minAssetProtectionSignatures <
                    _assetProtectionSignatories.length),
                "Admin Multi-Sig: Requested account is not an Asset Protection signatory!"
            );

            // increment asset protection proposal index
            ++_assetProtectionProposalIndex;

            // add proposal
            _signatoryProposals[
                _assetProtectionProposalIndex
            ] = SignatoryProposal({
                ID: _assetProtectionProposalIndex,
                PROPOSER: msg.sender,
                MODIFIEDSIGNER: signatoryAddress_,
                UPDATETYPE: updateType_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _signatoryProposalApprovers[_assetProtectionProposalIndex][
                msg.sender
            ] = true;

            // emit remove admin signatory proposal event
            emit SignatoryProposalCreatedEvent(
                msg.sender,
                _assetProtectionProposalIndex,
                signatoryAddress_,
                updateType_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only admin signatory.
            if (_assetProtectionSignatories.length == 1) {
                // update proposal IS EXECUTED
                _signatoryProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // remove Asset Protection signatory
                _isAssetProtectionSignatory[signatoryAddress_] = false;

                // update executed timestamp
                _signatoryProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                for (
                    uint256 i = 0;
                    i < _assetProtectionSignatories.length;
                    i++
                ) {
                    if (_assetProtectionSignatories[i] == signatoryAddress_) {
                        _assetProtectionSignatories[
                            i
                        ] = _assetProtectionSignatories[
                            _assetProtectionSignatories.length - 1
                        ];
                        break;
                    }
                }
                _assetProtectionSignatories.pop();

                // emit event
                emit SingatoryProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    signatoryAddress_,
                    updateType_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve signatory proposal (adding or removing)
    function approveSignatoryProposal(uint256 assetProtectionProposalIndex_)
        public
        onlyAssetProtectors
        onlyValidAssetProtectionIndex(assetProtectionProposalIndex_)
    {
        // admin proposal info
        SignatoryProposal storage proposal = _signatoryProposals[
            assetProtectionProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                _signatoryProposalApprovers[assetProtectionProposalIndex_][
                    msg.sender
                ] ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal should not be executed, expired, revoked or approved by sender!"
        );

        // if Removing a signatory, require min signatures is not violated (minSignatures > signatories.length)
        if (
            keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
            keccak256(abi.encodePacked("REMOVE"))
        ) {
            // require not violating min signature
            require(
                _assetProtectionSignatories.length >
                    _minAssetProtectionSignatures,
                "Admin Multi-Sig: Minimum Asset Protection signatories requirement not met!"
            );
        }

        // update proposal approved by admin sender status
        _signatoryProposalApprovers[assetProtectionProposalIndex_][
            msg.sender
        ] = true;

        // update proposal approval
        proposal.APPROVALCOUNT++;

        // emit admin signatory proposal approved event
        emit ApproveSignatoryProposalEvent(
            msg.sender,
            assetProtectionProposalIndex_,
            proposal.MODIFIEDSIGNER,
            proposal.UPDATETYPE,
            block.timestamp
        );

        // check if enough admin signatories have approved the proposal
        if (
            _signatoryProposals[assetProtectionProposalIndex_].APPROVALCOUNT >=
            _minAssetProtectionSignatures
        ) {
            // add the new signatory
            _assetProtectionSignatories.push(proposal.MODIFIEDSIGNER);

            // update role
            _isAssetProtectionSignatory[proposal.MODIFIEDSIGNER] = true;

            // update is executed
            proposal.ISEXECUTED = true;

            // udpate executed timestamp
            proposal.EXECUTEDTIMESTAMP = block.timestamp;

            // emit executing signatory proposal
            emit SingatoryProposalExecutedEvent(
                msg.sender,
                assetProtectionProposalIndex_,
                proposal.MODIFIEDSIGNER,
                proposal.UPDATETYPE,
                proposal.EXPIRATION,
                block.timestamp
            );
        }
    }

    // revoke signatory proposal (by Admin proposer)
    function revokeSignatoryProposal(uint256 assetProtectionProposalIndex_)
        public
        onlyAssetProtectors
        onlyProposer(assetProtectionProposalIndex_)
        onlyValidAssetProtectionIndex(assetProtectionProposalIndex_)
    {
        // admin proposal info
        SignatoryProposal storage proposal = _signatoryProposals[
            assetProtectionProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired or revoked
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal should not be executed, expired or revoked!"
        );

        // revoke the proposal
        _signatoryProposals[assetProtectionProposalIndex_].ISREVOKED = true;

        // UPDATE REVOKED TIMESTAMP
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeSignatoryProposalEvent(
            msg.sender,
            assetProtectionProposalIndex_,
            proposal.UPDATETYPE,
            block.timestamp
        );
    }

    ///   Asset Protection Proposal   ///

    // create Asset Protection Proposal
    function createAssetProtectionProposal(
        address account_,
        string memory action_,
        uint256 amount_,
        uint256 expiration_
    )
        public
        onlyAssetProtectors
        notNullAddress(account_)
        onlyValidAction(action_)
        onlyGreaterThanZero(expiration_)
    {
        // increment asset protection proposal index
        ++_assetProtectionProposalIndex;

        // create asset protection proposal
        _assetProtectionProposals[
            _assetProtectionProposalIndex
        ] = AssetProtectionProposal({
            ID: _assetProtectionProposalIndex,
            PROPOSER: msg.sender,
            ACCOUNT: account_,
            ACTION: action_,
            AMOUNT: amount_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve the porposal by asset protector sender
        _assetProtectionProposalApprovers[_assetProtectionProposalIndex][
            msg.sender
        ] = true;

        // emit creating asset protection proposal event
        emit AssetProtectionProposalCreatedEvent(
            msg.sender,
            _assetProtectionProposalIndex,
            account_,
            amount_,
            action_,
            expiration_,
            block.timestamp
        );

        if (_assetProtectionSignatories.length == 1) {
            // action
            if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZE"))
            ) {
                // execute freeze account proposal
                _ERC20.freezeAccount(account_);

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("UNFREEZE"))
            ) {
                // execute unfreeze account proposal
                _ERC20.unFreezeAccount(account_);

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing unfreeze account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("WIPEFREEZED"))
            ) {
                // execute wipe freezed account proposal
                _ERC20.wipeFreezedAccount(account_);

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing wipe freezed account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("WIPESPECIFICAMOUNTFREEZED"))
            ) {
                // execute wipe specific amount from freezed account proposal
                _ERC20.wipeSpecificAmountFreezedAccount(account_, amount_);

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing wipe freezed account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPE"))
            ) {
                // execute freeze and wipe account proposal
                _ERC20.freezeAndWipeAccount(account_);

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze and account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPESPECIFICAMOUNT"))
            ) {
                // execute freeze and wipe specific amount from an account proposal
                _ERC20.freezeAndWipeSpecificAmountAccount(account_, amount_);

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze and account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve Asset Protection Proposal
    function approveAssetProtectionProposal(
        uint256 assetProtectionProposalIndex_
    )
        public
        onlyAssetProtectors
        onlyValidAssetProtectionIndex(assetProtectionProposalIndex_)
    {
        // asset protection proposal info
        AssetProtectionProposal storage proposal = _assetProtectionProposals[
            assetProtectionProposalIndex_
        ];

        // require proposal not been EXECUTED, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION <= block.timestamp ||
                _assetProtectionProposalApprovers[
                    assetProtectionProposalIndex_
                ][msg.sender]),
            "Asset Protection Multi-Sig: Proposal should not be executed, expired, revoked, or approved by sender!"
        );

        // update proposal approved by asset protector sender
        _assetProtectionProposalApprovers[assetProtectionProposalIndex_][
            msg.sender
        ] = true;

        // update asset protection proposal approval count
        proposal.APPROVALCOUNT++;

        // emit asset protection proposal approved event
        emit ApproveAssetProtectionProposalEvent(
            msg.sender,
            assetProtectionProposalIndex_,
            proposal.ACCOUNT,
            proposal.ACTION,
            proposal.EXPIRATION,
            block.timestamp
        );

        // execute proposal if approval count reached min signature required
        if (
            _assetProtectionProposals[assetProtectionProposalIndex_]
                .APPROVALCOUNT >= _minAssetProtectionSignatures
        ) {
            // sender execute the proposal
            // action
            if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("FREEZE"))
            ) {
                // execute freeze account proposal
                _ERC20.freezeAccount(proposal.ACCOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("UNFREEZE"))
            ) {
                // execute unfreeze account proposal
                _ERC20.unFreezeAccount(proposal.ACCOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing unfreeze account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("WIPEFREEZED"))
            ) {
                // execute wipe freezed account proposal
                _ERC20.wipeFreezedAccount(proposal.ACCOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing wipe freezed account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("WIPESPECIFICAMOUNTFREEZED"))
            ) {
                // execute wipe specific amount from a freezed account proposal
                _ERC20.wipeSpecificAmountFreezedAccount(
                    proposal.ACCOUNT,
                    proposal.AMOUNT
                );

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing wipe freezed account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPE"))
            ) {
                // execute freeze and wipe account proposal
                _ERC20.freezeAndWipeAccount(proposal.ACCOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze and account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPESPECIFICAMOUNT"))
            ) {
                // execute freeze and wipe specific amount from an account proposal
                _ERC20.freezeAndWipeSpecificAmountAccount(
                    proposal.ACCOUNT,
                    proposal.AMOUNT
                );

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze and account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke Asset Protection Proposal
    function revokeAssetProtectionProposal(
        uint256 assetProtectionProposalIndex_
    ) public onlyAssetProtectors onlyProposer(assetProtectionProposalIndex_) {
        // asset protection proposal info
        AssetProtectionProposal storage proposal = _assetProtectionProposals[
            assetProtectionProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Asset Protection Multi-Sig: Proposal is already approved, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update EXECUTED TIMESTAMP
        proposal.EXECUTEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeAssetProtectionProposalEvent(
            msg.sender,
            assetProtectionProposalIndex_,
            proposal.ACCOUNT,
            proposal.ACTION,
            proposal.EXPIRATION,
            block.timestamp
        );
    }

    ///   GETTER FUNCTIONS   ///

    // get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() public view returns (address) {
        return _AddressBook.getAdminMultiSigContractAddress();
    }

    // get Addres Book Contract Address
    function getAddressBookContractAddress() public view returns (address) {
        return _AddressBookContractAddress;
    }

    // get max asset protection index
    function getMaxAssetProtectionIndex() public view returns (uint256) {
        return _assetProtectionProposalIndex;
    }

    // get asset protection proposal detail
    function getAssetProtectionProposalDetail(
        uint256 assetProtectionProposalIndex_
    ) public view returns (AssetProtectionProposal memory) {
        return _assetProtectionProposals[assetProtectionProposalIndex_];
    }

    // is asset protection proposal apporver
    function IsAssetProtectionProposalApprover(
        uint256 assetProtectionProposalIndex_,
        address account_
    ) public view returns (bool) {
        return
            _assetProtectionProposalApprovers[assetProtectionProposalIndex_][
                account_
            ];
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////
}