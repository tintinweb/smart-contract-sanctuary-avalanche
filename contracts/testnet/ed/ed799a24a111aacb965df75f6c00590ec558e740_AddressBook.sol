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

// Admin Multi-Sig Interface
interface AdminMultiSigInterface {
    // create Signatory proposal
    function createSignatoryProposal(
        address signatoryAddress_,
        string memory signatoryGroup_,
        string memory updateType_,
        uint256 expiration_
    ) external;

    // approve signatory proposal (adding or removing)
    function approveSignatoryProposal(uint256 adminProposalIndex_) external;

    // revoke signatory proposal (by Admin proposer)
    function revokeSignatoryProposal(uint256 adminProposalIndex_) external;

    // create min singatures requirement proposal
    function createMinSignaturesProposal(
        uint256 minSignatures_,
        string memory signatoryGroup_,
        uint256 expiration_
    ) external;

    // approve min signatures requirement proposal
    function approveMinSignaturesProposal(uint256 adminProposalIndex_) external;

    // revoke min signatures requirement proposal (by Admin proposer)
    function revokeMinSignaturesProposal(uint256 adminProposalIndex_) external;

    // create freeze management proposal
    function createFreezeManagementProposal(
        string memory managementGroup_,
        bool updateStatus_,
        uint256 expiration_
    ) external;

    // approve freeze management proposal
    function approveFreezeManagementProposal(uint256 adminProposalIndex_)
        external;

    // revoke freeze management proposal
    function revokeFreezeManagementProposal(uint256 adminProposalIndex_)
        external;

    // get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);

    // get signatories
    function getAdminSignatories() external view returns (address[] memory);

    // is admin signatory
    function IsAdminSignatory(address account_) external view returns (bool);

    // get admin proposal index
    function getAdminProposalIndex() external view returns (uint256);

    // get admin proposal detail
    // function getAdminProposalDetail(uint256 adminProposalIndex_)
    //     external
    //     view
    //     returns (SignatoryProposal memory);

    // is admin proposal approver
    function IsAdminProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) external view returns (bool);

    // get min signature
    function getMinAdminSignatures() external view returns (uint256);

    // get min signature proposal detail
    // function getMinSignatureProposalDetail(uint256 adminProposalIndex_)
    //     public
    //     view
    //     returns (MinSignatureProposal memory);

    // is min signature proposal approver?
    function IsMinSignatureProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) external view returns (bool);

    // get number of admin signatories
    function getNumberOfAdminSignatories() external view returns (uint256);

    // get Freeze Management proposal detail
    // function getFreezeManagementProposalDetail(uint256 adminProposalIndex_)
    //     public
    //     view
    //     returns (FreezeManagementProposal memory);

    // is freeze management proposal approver?
    function IsFreezeManagementProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) external view returns (bool);

    // get global freeze management status
    function getGlobalFreezeManagementStatus() external view returns (bool);

    // get Supply Management Freeze status
    function getSupplyManagementFreezeStatus() external view returns (bool);

    // get Fee Management Freeze status
    function getFeeManagementFreezeStatus() external view returns (bool);

    // get Asset Protection Freeze status
    function getAssetProtectionFreezeStatus() external view returns (bool);

    // get Supply Management Signatories
    function getSupplyManagementSignatories()
        external
        view
        returns (address[] memory);

    // Is Supply Management Signatory
    function IsSupplyManagementSignatory(address account_)
        external
        view
        returns (bool);

    // get Min Signature requirement for Supply Management
    function getSupplyManagementMinSignatures() external view returns (uint256);

    // get Fee Management Signatories
    function getFeeManagementSignatories()
        external
        view
        returns (address[] memory);

    // is Fee Managemetn Signatory
    function IsFeeManagementSignatory(address account_)
        external
        view
        returns (bool);

    // get Fee Management Min Singatures
    function getFeeManagementMinSignatures() external view returns (uint256);

    // get Asset Protection Signatories
    function getAssetProtectionSignatories()
        external
        view
        returns (address[] memory);

    // Is Asset Protection Signatory
    function IsAssetProtectionSignatory(address account_)
        external
        view
        returns (bool);

    // get Asset Protection Min Signature requirement
    function getAssetProtectionMinSignatures() external view returns (uint256);
}

// Supply Management Multi-Sig Interface
interface SupplyManagementMultiSigInterface {
    // update ERC20 Contract Address
    function updateERC20ContractAddress(address ERC20ContractAddress_) external;

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) external;

    // create supply management proposal
    function createSupplyManagementProposal(
        string memory orderType_,
        string memory paymentType_,
        uint256 orderSize_,
        address authorizedParticipant_,
        uint256 expiration_
    ) external;

    // approve Supply Management proposal
    function approveSupplyManagementProposal(
        uint256 supplyManagementProposalIndex_
    ) external;

    // revoke Supply Management proposal (by proposer)
    function revokeSupplyManagementProposal(
        uint256 supplyManagementProposalIndex_
    ) external;

    // get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);

    // get Max Supply Management Proposal Index
    function getMaxSupplyManagementProposalIndex()
        external
        view
        returns (uint256);

    // get Supply Management Proposal Detail
    // function getSupplyManagementProposalDetail(uint256 supplyManagementProposalIndex_) external view returns (SupplyManagementProposal memory);

    // IS Supply Management Proposal approver
    function IsSupplyManagementProposalApprover(
        uint256 supplyManagementProposalIndex_,
        address account_
    ) external view returns (bool);
}

// Fee Management Multi-Sig Interface
interface FeeManagementMultiSigInterface {
    // update ERC20 Contract Address
    function updateERC20ContractAddress(address ERC20ContractAddress_) external;

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) external;

    // update Fee Management Contract Address
    function updateFeeManagementContractAddress(
        address FeeManagementContractAddress_
    ) external;

    // create fee update proposal
    function createFeeUpdateProposal(
        string memory feeCategory_,
        uint256 feeAmount_,
        uint256 expiration_
    ) external;

    // approve fee update proposal
    function approveFeeUpdateProposal(uint256 feeManagementProposalIndex_)
        external;

    // revoke fee update proposal
    function revokeFeeUpdateProposal(uint256 feeManagementProposalIndex_)
        external;

    // create fee exemption proposal
    function createFeeExemptionProposal(
        string memory exemptionCategory_,
        string memory updateType_,
        address account_,
        uint256 expiration_
    ) external;

    // approve fee exemption proposal
    function approveFeeExemptionProposal(uint256 feeManagementProposalIndex_)
        external;

    // revoke fee exemption proposal
    function revokeFeeExemptionProposal(uint256 feeManagementProposalIndex_)
        external;

    // get admin multi sig contract address
    function getAdminMultiSigContractAddress() external view returns (address);

    // get max fee management proposal index
    function getMaxFeeManagementProposalIndex() external view returns (uint256);

    // get Fee Manager Proposal Detail
    // function getFeeManagerProposalDetail(uint256 feeManagementProposalIndex_) external view returns (FeeManagerProposal memory);

    // is Fee Manger proposal approver
    function IsFeeMangerProposalApprover(
        uint256 feeManagementProposalIndex_,
        address account_
    ) external view returns (bool);

    // get whitelist manager proposal detail
    // function getWhitelistMangerProposalDetail(uint256 feeManagementProposalIndex_) external view returns (WhitelistManagerProposal memory);

    // is whitelist manager proposal approvers
    function IsWhitelistManagerProposalApprovers(
        uint256 feeManagementProposalIndex_,
        address account_
    ) external view returns (bool);
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

// Address Book contract
contract AddressBook {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // ERC20 Contract Address
    address private _ERC20ContractAddress;

    // Admin Multi-Sig Contract Address
    address private _AdminMultiSigContractAddress;

    // Supply Management Multi-Sig Contract Address
    address private _SupplyManagementMultiSigContractAddress;

    // Fee Management Contract Address
    address private _FeeManagementContractAddress;

    // Fee Management Multi-Sig Contract Address
    address private _FeeManagementMultiSigContractAddress;

    // Asset Protection Multi-Sig Contract Address
    address private _AssetProtectionMultiSigContractAddress;

    // KYC Compliance Contract Address
    address private _KYCContractAddress;

    // KYC Compliance Multi-Sig Contract Address
    address private _KYCMultiSigContractAddress;

    ///   Update Contract Address   ///

    uint256 private _proposalIndex = 0;

    // Update Contract Address Proposal struct
    struct UpdateContractAddressProposal {
        uint256 ID;
        address PROPOSER;
        string CONTRACTCATEGORY;
        address CONTRACTADDRESS;
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of update contract address proposal info: admin proposal index => update contract address proposal detail
    mapping(uint256 => UpdateContractAddressProposal)
        private _updateContractAddressProposal;

    // update contract address proposal approvers: admin proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _updateContractAddressApprovers;

    ///////////////////////////
    ////    Constructor    ////
    ///////////////////////////

    // constructor
    constructor(address AdminMultiSigContractAddress_)
        notNullAddress(AdminMultiSigContractAddress_)
    {
        // update Admin Multi-Sig Contract Address
        _AdminMultiSigContractAddress = AdminMultiSigContractAddress_;

        // emit event
        emit updateAdminMultiSigConractAddressEvent(
            msg.sender,
            msg.sender,
            address(0),
            AdminMultiSigContractAddress_,
            block.timestamp
        );
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // update ERC20 Contract Address
    event updateERC20ContractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousERC20ContractAddress,
        address newERC20ContractAddress,
        uint256 indexed timestamp
    );

    // update Admin Multi-Sig Contract Address
    event updateAdminMultiSigConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousAdminMultiSigContractAddress,
        address newAdminMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // update Supply Management Multi-Sig Contract Address
    event updateSupplyManagementMultiSigConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousSupplyManagementMultiSigContractAddress,
        address newSupplyManagementMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // update Fee Management Contract Address
    event updateFeeManagementConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousFeeManagementContractAddress,
        address newFeeManagementContractAddress,
        uint256 indexed timestamp
    );

    // update Fee Management Multi-Sig Contract Address
    event updateFeeManagementMultiSigConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousFeeManagementMultiSigContractAddress,
        address newFeeManagementMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // update Asset Protection Multi-Sig Contract Address
    event updateAssetProtectionMultiSigConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousAssetProtectionMultiSigContractAddress,
        address newAssetProtectionMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // update KYC Contract Address
    event updateKYCConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousKYCContractAddress,
        address newKYCContractAddress,
        uint256 indexed timestamp
    );

    // update KYC Multi-Sig Contract Address
    event updateKYCMultiSigConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousKYCMulitSigContractAddress,
        address newKYCMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // create update contract address proposal
    event UpdateContractAddressProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string contractCategory,
        address contractAddress,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute updating contract address proposal
    event UpdateContractAddressProposalExecutedEvent(
        address indexed executor,
        uint256 indexed adminProposalIndex,
        address previousContractAddress,
        string contractCategory,
        address contractAddress,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve update contract address proposal
    event ApproveUpdateContractAddressProposalEvent(
        address indexed approver,
        uint256 indexed adminProposalIndex,
        string contractCategory,
        address contractAddress,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // revoke updating contract address proposal
    event revokeUpdateContractAddressProposalEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string contractCategory,
        address contractAddress,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Admin Multi-Sig
    modifier onlyAdmins() {
        // require sender be the Admin Multi-Sig Contract
        require(
            msg.sender == _AdminMultiSigContractAddress,
            "Address Book: Sender is not Admin Multi-Sig Contract!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Address Book: Account can not be zero address!"
        );
        _;
    }

    // only valid contract category
    modifier onlyValidContractCategory(string memory contractCategory_) {
        // require valid contract category
        _onlyValidContractCategory(contractCategory_);
        _;
    }

    // greater than zero value
    modifier onlyGreaterThanZero(uint256 value_) {
        // require value be greater than zero
        _onlyGreaterThanZero(value_);
        _;
    }

    // only valid adminProposalIndex
    modifier onlyValidAdminProposalIndex(uint256 adminProposalIndex_) {
        // require a valid admin proposal index ( != 0 and not more than max)
        _onlyValidAdminProposalIndex(adminProposalIndex_);
        _;
    }

    // only proposer
    modifier onlyProposer(uint256 adminProposalIndex_) {
        // require sender be the proposer of the proposal
        _onlyProposer(adminProposalIndex_);
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // Update ERC20 Contract Address
    function updateERC20ContractAddress(
        address ERC20ContractAddress_,
        address executor_
    )
        public
        notNullAddress(ERC20ContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous ERC20 Contract Address
        address previousERC20ContractAddress = _ERC20ContractAddress;

        // update ERC20 Contract Address
        _ERC20ContractAddress = ERC20ContractAddress_;

        // emit event
        emit updateERC20ContractAddressEvent(
            msg.sender,
            executor_,
            previousERC20ContractAddress,
            ERC20ContractAddress_,
            block.timestamp
        );
    }

    // Get ERC20 Contract Address
    function getERC20ContractAddress() public view returns (address) {
        return _ERC20ContractAddress;
    }

    // Update Admin Multi-Sig Contract Address
    function updateAdminMultiSigConractAddress(
        address AdminMultiSigContractAddress_,
        address executor_
    )
        public
        notNullAddress(AdminMultiSigContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous Admin Multi-Sig Contract Address
        address previousAdminMultiSigContractAddress = _AdminMultiSigContractAddress;

        // update Admin Multi-Sig Contract Address
        _AdminMultiSigContractAddress = AdminMultiSigContractAddress_;

        // emit event
        emit updateAdminMultiSigConractAddressEvent(
            msg.sender,
            executor_,
            previousAdminMultiSigContractAddress,
            AdminMultiSigContractAddress_,
            block.timestamp
        );
    }

    // Get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() public view returns (address) {
        return _AdminMultiSigContractAddress;
    }

    // Update Supply Management Multi-Sig Contract Address
    function updateSupplyManagementMultiSigConractAddress(
        address SupplyManagementMultiSigContractAddress_,
        address executor_
    )
        public
        notNullAddress(SupplyManagementMultiSigContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous SupplyManagement Multi-Sig Contract Address
        address previousSupplyManagementMultiSigContractAddress = _SupplyManagementMultiSigContractAddress;

        // update SupplyManagement Multi-Sig Contract Address
        _SupplyManagementMultiSigContractAddress = SupplyManagementMultiSigContractAddress_;

        // emit event
        emit updateSupplyManagementMultiSigConractAddressEvent(
            msg.sender,
            executor_,
            previousSupplyManagementMultiSigContractAddress,
            SupplyManagementMultiSigContractAddress_,
            block.timestamp
        );
    }

    // Get Supply Management Multi-Sig Contract Address
    function getSupplyManagementMultiSigContractAddress()
        public
        view
        returns (address)
    {
        return _SupplyManagementMultiSigContractAddress;
    }

    // Update Fee Management Contract Address
    function updateFeeManagementConractAddress(
        address FeeManagementContractAddress_,
        address executor_
    )
        public
        notNullAddress(FeeManagementContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous Fee Management Contract Address
        address previousFeeManagementContractAddress = _FeeManagementContractAddress;

        // update Fee Management Contract Address
        _FeeManagementContractAddress = FeeManagementContractAddress_;

        // emit event
        emit updateFeeManagementConractAddressEvent(
            msg.sender,
            executor_,
            previousFeeManagementContractAddress,
            FeeManagementContractAddress_,
            block.timestamp
        );
    }

    // Get Fee Management Contract Address
    function getFeeManagementContractAddress() public view returns (address) {
        return _FeeManagementContractAddress;
    }

    // Update Fee Management Multi-Sig Contract Address
    function updateFeeManagementMultiSigConractAddress(
        address FeeManagementMultiSigContractAddress_,
        address executor_
    )
        public
        notNullAddress(FeeManagementMultiSigContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous Fee Management Multi-Sig Contract Address
        address previousFeeManagementMultiSigContractAddress = _FeeManagementMultiSigContractAddress;

        // update Fee Management Multi-Sig Contract Address
        _FeeManagementMultiSigContractAddress = FeeManagementMultiSigContractAddress_;

        // emit event
        emit updateFeeManagementMultiSigConractAddressEvent(
            msg.sender,
            executor_,
            previousFeeManagementMultiSigContractAddress,
            FeeManagementMultiSigContractAddress_,
            block.timestamp
        );
    }

    // Get Fee Management Multi-Sig Contract Address
    function getFeeManagementMultiSigContractAddress()
        public
        view
        returns (address)
    {
        return _FeeManagementMultiSigContractAddress;
    }

    // Update Asset Protection Multi-Sig Contract Address
    function updateAssetProtectionMultiSigConractAddress(
        address AssetProtectionMultiSigContractAddress_,
        address executor_
    )
        public
        notNullAddress(AssetProtectionMultiSigContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous Asset Protectionn Multi-Sig Contract Address
        address previousAssetProtectionMultiSigContractAddress = _AssetProtectionMultiSigContractAddress;

        // update Asset Protection Multi-Sig Contract Address
        _AssetProtectionMultiSigContractAddress = AssetProtectionMultiSigContractAddress_;

        // emit event
        emit updateAssetProtectionMultiSigConractAddressEvent(
            msg.sender,
            executor_,
            previousAssetProtectionMultiSigContractAddress,
            AssetProtectionMultiSigContractAddress_,
            block.timestamp
        );
    }

    // Get Asset Protection Multi-Sig Contract Address
    function getAssetProtectionMultiSigContractAddress()
        public
        view
        returns (address)
    {
        return _AssetProtectionMultiSigContractAddress;
    }

    // Get Address Book Contract Address
    function getAddressBookContractAddress() public view returns (address) {
        return address(this);
    }

    // update KYC Contract Address
    function updateKYCContractAddress(address KYCContractAddress_, address executor_)
        public
        notNullAddress(KYCContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous KYC Contract Address
        address previousKYCContractAddress = _KYCContractAddress;

        // update KYC Contract Address
        _KYCContractAddress = KYCContractAddress_;

        // emit event
        emit updateKYCConractAddressEvent(
            msg.sender,
            executor_,
            previousKYCContractAddress,
            KYCContractAddress_,
            block.timestamp
        );
    }

    // get KYC Contract Address
    function getKYCContractAddress() public view returns (address) {
        return _KYCContractAddress;
    }

    // update KYC Multi-Sig Contract Address
    function updateKYCMultiSigContractAddress(address KYCMultiSigContractAddress_, address executor_)
        public
        notNullAddress(KYCMultiSigContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous KYC Multi-Sig Contract Address
        address previousKYCMulitSigContractAddress = _KYCMultiSigContractAddress;

        // update KYC Multi-Sig Contract Address
        _KYCMultiSigContractAddress = KYCMultiSigContractAddress_;

        // emit event
        emit updateKYCMultiSigConractAddressEvent(
            msg.sender,
            executor_,
            previousKYCMulitSigContractAddress,
            KYCMultiSigContractAddress_,
            block.timestamp
        );
    }

    // get KYC Multi-Sig Contract Address
    function getKYCMultiSigContractAddress() public view returns(address) {
        return _KYCMultiSigContractAddress;
    }

    ///    Update Contract Addresses Proposals    ///

    // create update contract address proposal
    function createUpdateContractAddressProposal(
        string memory contractCategory_,
        address contractAddress_,
        uint256 expiration_
    )
        public
        onlyAdmins
        onlyValidContractCategory(contractCategory_)
        notNullAddress(contractAddress_)
        onlyGreaterThanZero(expiration_)
    {
        // check contract category
        if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("ERC20"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _ERC20ContractAddress,
                "Admin Multi-Sig: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _ERC20ContractAddress;

                // update contract address
                // update in Address book
                updateERC20ContractAddress(contractAddress_, msg.sender);

                // update in Supply Management Multi-Sig
                SupplyManagementMultiSigInterface(
                    _SupplyManagementMultiSigContractAddress
                ).updateERC20ContractAddress(contractAddress_);

                // update in Fee Management Multi-Sig
                FeeManagementMultiSigInterface(
                    _FeeManagementMultiSigContractAddress
                ).updateERC20ContractAddress(contractAddress_);

                // update in Asset Protection Multi-Sig
                AssetProtectionMultiSigInterface(
                    _AssetProtectionMultiSigContractAddress
                ).updateERC20ContractAddress(contractAddress_);

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("FEEMANAGEMENT"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _FeeManagementContractAddress,
                "Admin Multi-Sig: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _FeeManagementContractAddress;

                // update contract address
                // update in Address book
                updateFeeManagementConractAddress(contractAddress_, msg.sender);

                // update in ERC20
                ERC20Interface(_ERC20ContractAddress)
                    .updateFeeManagementContractAddress(contractAddress_);

                // update in Fee Management Multi-Sig
                FeeManagementMultiSigInterface(
                    _FeeManagementMultiSigContractAddress
                ).updateFeeManagementContractAddress(contractAddress_);

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("ADDRESSBOOK"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != address(this),
                "Admin Multi-Sig: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = address(this);

                // update contract address
                // update in Address book
                // _AddressBook.updateAddressBookContractAddress(contractAddress_, msg.sender);

                // update in Fee Management
                FeeManagementInterface(_FeeManagementContractAddress)
                    .updateAddressBookContractAddress(contractAddress_);

                // update in Asset Protection Multi-Sig
                AssetProtectionMultiSigInterface(
                    _AssetProtectionMultiSigContractAddress
                ).updateAddressBookContractAddress(contractAddress_);

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("ADMINMULTISIG"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _AdminMultiSigContractAddress,
                "Admin Multi-Sig: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _AdminMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateAdminMultiSigConractAddress(contractAddress_, msg.sender);

                // update in Supply Management Multi-Sig
                SupplyManagementMultiSigInterface(
                    _SupplyManagementMultiSigContractAddress
                ).updateAdminMultiSigContractAddress(contractAddress_);

                // update in Fee Management Multi-Sig
                FeeManagementMultiSigInterface(
                    _FeeManagementMultiSigContractAddress
                ).updateAdminMultiSigContractAddress(contractAddress_);

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("SUPPLYMANAGEMENTMULTISIG"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _SupplyManagementMultiSigContractAddress,
                "Admin Multi-Sig: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _SupplyManagementMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateSupplyManagementMultiSigConractAddress(
                    contractAddress_,
                    msg.sender
                );

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("FEEMANAGEMENTMULTISIG"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _FeeManagementMultiSigContractAddress,
                "Admin Multi-Sig: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _FeeManagementMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateFeeManagementMultiSigConractAddress(
                    contractAddress_,
                    msg.sender
                );

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("ASSETPROTECTIONMULTISIG"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _AssetProtectionMultiSigContractAddress,
                "Admin Multi-Sig: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _AssetProtectionMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateAssetProtectionMultiSigConractAddress(
                    contractAddress_,
                    msg.sender
                );

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("KYCCONTRACTADDRESS"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _KYCContractAddress,
                "Admin Multi-Sig: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _KYCContractAddress;

                // update contract address
                // update in Address book
                updateKYCContractAddress(
                    contractAddress_,
                    msg.sender
                );

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("KYCMULTISIG"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _KYCMultiSigContractAddress,
                "Admin Multi-Sig: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _KYCMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateKYCMultiSigContractAddress(
                    contractAddress_,
                    msg.sender
                );

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve update contract address proposal
    function approveUpdateContractAddressProposal(uint256 proposalIndex_)
        public
        onlyAdmins
        onlyValidAdminProposalIndex(proposalIndex_)
    {
        // update contract address proposal info
        UpdateContractAddressProposal
            storage proposal = _updateContractAddressProposal[proposalIndex_];

        // require proposal not been EXECUTED, expired, revoked, or apprved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED ||
                _updateContractAddressApprovers[proposalIndex_][msg.sender]),
            "Admin Multi-Sig: Proposal should not be executed, expired, revoked or approved by sender!"
        );

        // update proposal approved by admin sender status
        _updateContractAddressApprovers[proposalIndex_][msg.sender] = true;

        // update proposal approval COUNT
        proposal.APPROVALCOUNT++;

        // emit approve update contract address proposal event
        emit ApproveUpdateContractAddressProposalEvent(
            msg.sender,
            _proposalIndex,
            proposal.CONTRACTCATEGORY,
            proposal.CONTRACTADDRESS,
            proposal.EXPIRATION,
            block.timestamp
        );

        // check if enough admin signatories have approved the proposal
        if (
            _updateContractAddressProposal[_proposalIndex].APPROVALCOUNT >=
            AdminMultiSigInterface(_AdminMultiSigContractAddress)
                .getNumberOfAdminSignatories()
        ) {
            // check contract category
            if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("ERC20"))
            ) {
                // previous contract address
                address previousContractAddress = _ERC20ContractAddress;

                // update contract address
                // update in Address book
                updateERC20ContractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update in Supply Management Multi-Sig
                SupplyManagementMultiSigInterface(
                    _SupplyManagementMultiSigContractAddress
                ).updateERC20ContractAddress(proposal.CONTRACTADDRESS);

                // update in Fee Management Multi-Sig
                FeeManagementMultiSigInterface(
                    _FeeManagementMultiSigContractAddress
                ).updateERC20ContractAddress(proposal.CONTRACTADDRESS);

                // update in Asset Protection Multi-Sig
                AssetProtectionMultiSigInterface(
                    _AssetProtectionMultiSigContractAddress
                ).updateERC20ContractAddress(proposal.CONTRACTADDRESS);

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // previous contract address
                address previousContractAddress = _FeeManagementContractAddress;

                // update contract address
                // update in Address book
                updateFeeManagementConractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update in ERC20
                ERC20Interface(_ERC20ContractAddress)
                    .updateFeeManagementContractAddress(
                        proposal.CONTRACTADDRESS
                    );

                // update in Fee Management Multi-Sig
                FeeManagementMultiSigInterface(
                    _FeeManagementMultiSigContractAddress
                ).updateFeeManagementContractAddress(proposal.CONTRACTADDRESS);

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("ADDRESSBOOK"))
            ) {
                // previous contract address
                address previousContractAddress = address(this);

                // update contract address
                // update in Address book
                // _AddressBook.updateAddressBookContractAddress(contractAddress_, msg.sender);

                // update in Fee Management
                FeeManagementInterface(_FeeManagementContractAddress)
                    .updateAddressBookContractAddress(proposal.CONTRACTADDRESS);

                // update in Asset Protection Multi-Sig
                AssetProtectionMultiSigInterface(
                    _AssetProtectionMultiSigContractAddress
                ).updateAddressBookContractAddress(proposal.CONTRACTADDRESS);

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("ADMINMULTISIG"))
            ) {
                // previous contract address
                address previousContractAddress = _AdminMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateAdminMultiSigConractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update in Supply Management Multi-Sig
                SupplyManagementMultiSigInterface(
                    _SupplyManagementMultiSigContractAddress
                ).updateAdminMultiSigContractAddress(proposal.CONTRACTADDRESS);

                // update in Fee Management Multi-Sig
                FeeManagementMultiSigInterface(
                    _FeeManagementMultiSigContractAddress
                ).updateAdminMultiSigContractAddress(proposal.CONTRACTADDRESS);

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENTMULTISIG"))
            ) {
                // previous contract address
                address previousContractAddress = _SupplyManagementMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateSupplyManagementMultiSigConractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENTMULTISIG"))
            ) {
                // previous contract address
                address previousContractAddress = _FeeManagementMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateFeeManagementMultiSigConractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("ASSETPROTECTIONMULTISIG"))
            ) {
                // previous contract address
                address previousContractAddress = _AssetProtectionMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateAssetProtectionMultiSigConractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("KYCCONTRACTADDRESS"))
            ) {
                // previous contract address
                address previousContractAddress = _KYCContractAddress;

                // update contract address
                // update in Address book
                updateKYCContractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("KYCMULTISIG"))
            ) {
                // previous contract address
                address previousContractAddress = _KYCMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateKYCMultiSigContractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke proposed update contract address
    function revokeUpdateContractAddressProposal(uint256 proposalIndex_)
        public
        onlyAdmins
        onlyProposer(proposalIndex_)
        onlyValidAdminProposalIndex(proposalIndex_)
    {
        // proposal info
        UpdateContractAddressProposal
            storage proposal = _updateContractAddressProposal[proposalIndex_];

        // require proposal not been executed already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal is already executed, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update revoked timestamp
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeUpdateContractAddressProposalEvent(
            msg.sender,
            proposalIndex_,
            proposal.CONTRACTCATEGORY,
            proposal.CONTRACTADDRESS,
            block.timestamp
        );
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // only valid contract category
    function _onlyValidContractCategory(string memory contractCategory_)
        internal
        view
        virtual
    {
        // require valid contract category
        require(
            keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("ERC20")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("ADDRESSBOOK")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("ADMINMULTISIG")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENTMULTISIG")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENTMULTISIG")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("ASSETPROTECTIONMULTISIG"))  ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("KYCCONTRACTADDRESS")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("KYCMULTISIG")),
            "Admin Multi-Sig: Contract category is not valid!"
        );
    }

    // greater than zero value
    function _onlyGreaterThanZero(uint256 value_) internal view virtual {
        // require value be greater than zero
        require(
            value_ > 0,
            "Admin Multi-Sig: Value should be greater than zero!"
        );
    }

    // only valid admin proposal index
    function _onlyValidAdminProposalIndex(uint256 proposalIndex_)
        internal
        view
        virtual
    {
        // require a valid admin proposal index ( != 0 and not more than max)
        require(
            (proposalIndex_ != 0 && proposalIndex_ <= _proposalIndex),
            "Admin Multi-Sig: Invalid admin proposal index!"
        );
    }

    // only proposer
    function _onlyProposer(uint256 proposalIndex_) internal view virtual {
        // require sender be the proposer of the proposal
        require(
            msg.sender ==
                _updateContractAddressProposal[proposalIndex_].PROPOSER,
            "Admin Multi-Sig: Sender is not the proposer!"
        );
    }
}